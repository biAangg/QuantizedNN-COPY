// 📄 DesignSystem.swift

import SwiftUI

enum DesignSystem {
    enum Colors {
        static let ink = Color(hex: 0x1B1830)
        static let ink2 = Color(hex: 0x4A4566)
        static let ink3 = Color(hex: 0x7C769A)
        
        static let brand = Color(hex: 0x5B21B6)
        static let brand2 = Color(hex: 0x7C3AED)
        static let brandWash = Color(hex: 0xF1EDFB)
        
        static let bg = Color(hex: 0xF5F3FA)
        static let surface = Color(hex: 0xFFFFFF)
        static let line = Color(hex: 0xE4E0F0)
        
        static let low = Color(hex: 0x0F766E)
        static let lowWash = Color(hex: 0xE6F4F2)
        
        static let watch = Color(hex: 0xA65B00)
        static let watchWash = Color(hex: 0xFBF0E2)
        
        static let getChecked = Color(hex: 0xB01717)
        static let getCheckedWash = Color(hex: 0xFBEBEB)
        
        static let noClearSignal = Color(hex: 0x475569)
        static let noClearSignalWash = Color(hex: 0xEEF1F5)
    }
    
    enum Radii {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
    }
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
