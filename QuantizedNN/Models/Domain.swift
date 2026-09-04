// 📄 Domain.swift

import SwiftUI
import SwiftData

// MARK: - Provenance & Signal Models

enum Provenance: String, Codable {
    case model, user, guidance
}

enum ScreeningSignal: String, Codable, CaseIterable {
    case lowConcern = "Low concern"
    case watch = "Watch this spot"
    case getChecked = "Get this checked"
    case noClearSignal = "No clear signal"
}

enum CertaintyBand: Int, Codable {
    case veryLow = 1, low, moderate, high, veryHigh
    
    static func from(confidence: Double) -> CertaintyBand {
        switch confidence {
        case ..<0.2: return .veryLow
        case 0.2..<0.4: return .low
        case 0.4..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default: return .veryHigh
        }
    }
}

enum BodySite: String, Codable, CaseIterable {
    // Head & Neck
    case forehead     = "Forehead"
    case leftCheek    = "Left cheek"
    case rightCheek   = "Right cheek"
    case neck         = "Neck"
    // Torso
    case chest        = "Chest"
    case abdomen      = "Abdomen"
    case upperBack    = "Upper back"
    case lowerBack    = "Lower back"
    // Arms
    case leftUpperArm  = "Left upper arm"
    case leftForearm   = "Left forearm"
    case rightUpperArm = "Right upper arm"
    case rightForearm  = "Right forearm"
    // Legs
    case leftThigh    = "Left thigh"
    case leftCalf     = "Left calf"
    case rightThigh   = "Right thigh"
    case rightCalf    = "Right calf"
}

enum CaptureQuality {
    case focus(Bool)
    case lighting(Bool)
    case framing(Bool)
}

// MARK: - Clinical Metadata

enum FitzpatrickType: Int, Codable, CaseIterable, Hashable {
    case I = 1, II, III, IV, V, VI

    var romanNumeral: String {
        switch self {
        case .I: return "I"; case .II: return "II"; case .III: return "III"
        case .IV: return "IV"; case .V: return "V"; case .VI: return "VI"
        }
    }

    var description: String { "\(skinTone). \(reaction)" }

    var skinTone: String {
        switch self {
        case .I:   return "Very fair or porcelain skin"
        case .II:  return "Fair skin with light features"
        case .III: return "Light brown skin"
        case .IV:  return "Moderate brown or olive skin"
        case .V:   return "Dark brown skin"
        case .VI:  return "Deeply pigmented, dark brown to black skin"
        }
    }

    var reaction: String {
        switch self {
        case .I:   return "Always burns, never tans."
        case .II:  return "Usually burns easily, tans minimally."
        case .III: return "Burns moderately, tans gradually to a light brown."
        case .IV:  return "Burns rarely, tans easily."
        case .V:   return "Burns very rarely, tans very easily."
        case .VI:  return "Never burns, tans very deeply."
        }
    }
}

struct ABCDAssessment: Codable, Hashable {
    var asymmetry: Bool = false
    var borderIrregularity: Bool = false
    var colorVariation: Bool = false
    var diameterOver6mm: Bool = false
}

enum LesionClass: String, Codable, CaseIterable {
    case actinicKeratosis   = "Actinic Keratosis / Bowen's Disease"
    case basalCellCarcinoma = "Basal Cell Carcinoma"
    case benignKeratosis    = "Benign Keratosis-like Lesions"
    case dermatofibroma     = "Dermatofibroma"
    case melanoma           = "Melanoma"
    case melanocyticNevi    = "Melanocytic Nevi"
    case vascularLesion     = "Vascular Lesions"
}

struct ScreeningOutput: Hashable {
    let signal: ScreeningSignal
    let confidence: Double
    let predictedClass: LesionClass
}

// MARK: - SwiftData Schema

@Model final class ScanRecord {
    var id: UUID
    var scanCode: String
    var capturedAt: Date
    var bodySite: BodySite
    var signal: ScreeningSignal
    var certainty: CertaintyBand
    var confidence: Double = 0.0
    var predictedClass: LesionClass = LesionClass.melanocyticNevi
    var fitzpatrickType: FitzpatrickType = FitzpatrickType.III
    var abcdAssessment: ABCDAssessment = ABCDAssessment()
    var userNotes: String
    @Attribute(.externalStorage) var imageData: Data

    init(id: UUID = UUID(), scanCode: String, capturedAt: Date = Date(), bodySite: BodySite, signal: ScreeningSignal, certainty: CertaintyBand, confidence: Double, predictedClass: LesionClass, fitzpatrickType: FitzpatrickType = .III, abcdAssessment: ABCDAssessment = ABCDAssessment(), userNotes: String = "", imageData: Data) {
        self.id = id
        self.scanCode = scanCode
        self.capturedAt = capturedAt
        self.bodySite = bodySite
        self.signal = signal
        self.certainty = certainty
        self.confidence = confidence
        self.predictedClass = predictedClass
        self.fitzpatrickType = fitzpatrickType
        self.abcdAssessment = abcdAssessment
        self.userNotes = userNotes
        self.imageData = imageData
    }
}
