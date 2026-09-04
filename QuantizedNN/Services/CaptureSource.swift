import SwiftUI
import AVFoundation
import Accelerate
import CoreVideo
import UIKit

protocol CaptureSource {
    var qualityChecks: AsyncStream<CaptureQuality> { get }
    func capture() async throws -> UIImage
}

// MARK: - Optical Evaluator (Accelerate Framework Optimization)
struct OpticalEvaluator {
    static let minLaplacianVariance: Float = 120.0 // Focus threshold
    static let minLuminance: Float = 65.0          // Under-exposure threshold
    static let maxLuminance: Float = 210.0         // Over-exposure threshold
    
    // 3x3 Laplacian Kernel for edge/blur detection
    static var kernel: [Int16] = [
         0,  1,  0,
         1, -4,  1,
         0,  1,  0
    ]

    static func evaluate(pixelBuffer: CVPixelBuffer) -> (isFocused: Bool, isWellLit: Bool) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0 else { return (false, false) }
        
        let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        
        // OPTIMIZATION: Center crop (512x512) to minimize CPU load and thermal throttling
        let cropSize = 512
        let startX = max(0, (width - cropSize) / 2)
        let startY = max(0, (height - cropSize) / 2)
        let actualCropWidth = min(cropSize, width)
        let actualCropHeight = min(cropSize, height)
        
        let cropOffset = (startY * bytesPerRow) + startX
        guard let cropAddress = lumaBaseAddress?.advanced(by: cropOffset) else { return (false, false) }
        
        var sourceBuffer = vImage_Buffer(
            data: cropAddress,
            height: vImagePixelCount(actualCropHeight),
            width: vImagePixelCount(actualCropWidth),
            rowBytes: bytesPerRow
        )
        
        let destBytesPerRow = actualCropWidth
        let destData = UnsafeMutableRawPointer.allocate(byteCount: actualCropHeight * destBytesPerRow, alignment: 64)
        defer { destData.deallocate() }
        
        var destBuffer = vImage_Buffer(
            data: destData,
            height: vImagePixelCount(actualCropHeight),
            width: vImagePixelCount(actualCropWidth),
            rowBytes: destBytesPerRow
        )
        
        // 1. Calculate Laplacian convolution for sharpness/focus
        vImageConvolve_Planar8(
            &sourceBuffer,
            &destBuffer,
            nil,
            0,
            0,
            &kernel,
            3,
            3,
            0,
            0,
            vImage_Flags(kvImageEdgeExtend)
        )
        
        let pixelCount = actualCropWidth * actualCropHeight
        var floatPixels = [Float](repeating: 0, count: pixelCount)
        vDSP_vfltu8(destBuffer.data.assumingMemoryBound(to: UInt8.self), 1, &floatPixels, 1, vDSP_Length(pixelCount))
        
        var mean: Float = 0
        var stdDev: Float = 0
        vDSP_normalize(&floatPixels, 1, nil, 1, &mean, &stdDev, vDSP_Length(pixelCount))
        let laplacianVariance = stdDev * stdDev
        
        // 2. Calculate Luma mean for lighting validation
        var originalFloatPixels = [Float](repeating: 0, count: pixelCount)
        vDSP_vfltu8(sourceBuffer.data.assumingMemoryBound(to: UInt8.self), 1, &originalFloatPixels, 1, vDSP_Length(pixelCount))
        
        var lumaMean: Float = 0
        vDSP_meanv(&originalFloatPixels, 1, &lumaMean, vDSP_Length(pixelCount))
        
        let isFocused = laplacianVariance >= minLaplacianVariance
        let isWellLit = lumaMean >= minLuminance && lumaMean <= maxLuminance
        
        return (isFocused, isWellLit)
    }
}

// MARK: - Hardware Capture Implementation (Hard Shutter Lock Enforced)
class HardwareCaptureSource: NSObject, CaptureSource, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "my.QuantizedNN.captureSessionQueue")
    
    private var qualityContinuation: AsyncStream<CaptureQuality>.Continuation?
    private(set) var qualityChecks: AsyncStream<CaptureQuality>
    
    private var currentFocusOk = false
    private var currentLightOk = false
    private var frameCounter = 0
    
    // Storage for high-res photo capture continuation
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    
    override init() {
        var continuation: AsyncStream<CaptureQuality>.Continuation?
        self.qualityChecks = AsyncStream { cont in
            continuation = cont
            cont.yield(.framing(true))
        }
        self.qualityContinuation = continuation
        super.init()
        
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // Setup Back Camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) { captureSession.addInput(input) }
        if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }
        
        // Setup Video Data Output for real-time optical checks
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.QuantizedNN.opticalAnalysis", qos: .userInteractive))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    // MARK: - Frame Delegate (10fps downsampled evaluation)
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCounter += 1
        guard frameCounter % 3 == 0, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let metrics = OpticalEvaluator.evaluate(pixelBuffer: pixelBuffer)
        
        if currentFocusOk != metrics.isFocused {
            currentFocusOk = metrics.isFocused
            qualityContinuation?.yield(.focus(currentFocusOk))
        }
        
        if currentLightOk != metrics.isWellLit {
            currentLightOk = metrics.isWellLit
            qualityContinuation?.yield(.lighting(currentLightOk))
        }
    }
    
    // MARK: - Hard Shutter Lock Enforcement
    func capture() async throws -> UIImage {
        guard currentFocusOk && currentLightOk else {
            throw NSError(domain: "my.QuantizedNN.CaptureError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Hard Shutter Lock Active: Optical parameters (focus/lighting) are outside clinical tolerances."])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - Photo Capture Delegate
extension HardwareCaptureSource: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            photoContionError: do {
                let conversionError = NSError(domain: "my.QuantizedNN.CaptureError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode captured image representation."])
                photoContinuation?.resume(throwing: conversionError)
                photoContinuation = nil
            }
            return
        }
        
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}

// MARK: - Dependency Injection Extension
struct CaptureSourceKey: EnvironmentKey {
    static let defaultValue: any CaptureSource = HardwareCaptureSource()
}

extension EnvironmentValues {
    var captureSource: any CaptureSource {
        get { self[CaptureSourceKey.self] }
        set { self[CaptureSourceKey.self] = newValue }
    }
}
