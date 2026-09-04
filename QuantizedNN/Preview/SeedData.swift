// 📄 SeedData.swift

import SwiftUI
import SwiftData

@MainActor
class SeedData {
    static let shared = SeedData()
    
    // Generates a solid color image data to represent Fitzpatrick scale I-VI thumbnails
    private func createDummyImageData(hex: UInt) -> Data {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        
        let color = Color(hex: hex)
        context.setFillColor(UIColor(color).cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image.pngData() ?? Data()
    }
    
    private func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
    
    var mockRecords: [ScanRecord] {
        [
            // Fitzpatrick II — common benign mole, high confidence
            ScanRecord(
                id: UUID(),
                scanCode: "SCN-0047",
                capturedAt: date(year: 2026, month: 7, day: 7),
                bodySite: .leftForearm,
                signal: .lowConcern,
                certainty: .high,
                confidence: 0.78,
                predictedClass: .melanocyticNevi,
                fitzpatrickType: .II,
                abcdAssessment: ABCDAssessment(),
                imageData: createDummyImageData(hex: 0xF0D9C8)
            ),
            // Fitzpatrick IV — high-concern lesion with multiple ABCD flags
            ScanRecord(
                id: UUID(),
                scanCode: "SCN-0046",
                capturedAt: date(year: 2026, month: 7, day: 2),
                bodySite: .lowerBack,
                signal: .getChecked,
                certainty: .moderate,
                confidence: 0.52,
                predictedClass: .melanoma,
                fitzpatrickType: .IV,
                abcdAssessment: ABCDAssessment(asymmetry: true, borderIrregularity: true, colorVariation: true, diameterOver6mm: false),
                imageData: createDummyImageData(hex: 0x8D5A3B)
            ),
            // Fitzpatrick VI — ambiguous result, border irregularity noted
            ScanRecord(
                id: UUID(),
                scanCode: "SCN-0045",
                capturedAt: date(year: 2026, month: 6, day: 25),
                bodySite: .rightUpperArm,
                signal: .noClearSignal,
                certainty: .low,
                confidence: 0.31,
                predictedClass: .benignKeratosis,
                fitzpatrickType: .VI,
                abcdAssessment: ABCDAssessment(asymmetry: false, borderIrregularity: true, colorVariation: false, diameterOver6mm: false),
                imageData: createDummyImageData(hex: 0x4A2C1D)
            ),
            // Fitzpatrick III — benign growth, very high confidence, no flags
            ScanRecord(
                id: UUID(),
                scanCode: "SCN-0044",
                capturedAt: date(year: 2026, month: 6, day: 18),
                bodySite: .leftCheek,
                signal: .lowConcern,
                certainty: .veryHigh,
                confidence: 0.91,
                predictedClass: .dermatofibroma,
                fitzpatrickType: .III,
                abcdAssessment: ABCDAssessment(),
                imageData: createDummyImageData(hex: 0xC89078)
            ),
            // Fitzpatrick V — pre-malignant, warrants monitoring, color variation present
            ScanRecord(
                id: UUID(),
                scanCode: "SCN-0043",
                capturedAt: date(year: 2026, month: 6, day: 11),
                bodySite: .rightCalf,
                signal: .watch,
                certainty: .moderate,
                confidence: 0.48,
                predictedClass: .actinicKeratosis,
                fitzpatrickType: .V,
                abcdAssessment: ABCDAssessment(asymmetry: false, borderIrregularity: true, colorVariation: true, diameterOver6mm: false),
                imageData: createDummyImageData(hex: 0x6B4030)
            ),
            // Fitzpatrick I — 6 months prior, benign, no flags
            ScanRecord(
                id: UUID(),
                scanCode: "SCN-0012",
                capturedAt: date(year: 2026, month: 1, day: 15),
                bodySite: .leftForearm,
                signal: .lowConcern,
                certainty: .high,
                confidence: 0.74,
                predictedClass: .melanocyticNevi,
                fitzpatrickType: .I,
                abcdAssessment: ABCDAssessment(),
                imageData: createDummyImageData(hex: 0xFDF1E8)
            )
        ]
    }
    
    func insertSeedData(into context: ModelContext) {
        for record in mockRecords {
            context.insert(record)
        }
        try? context.save()
    }
}
