//
//  AppColors.swift
//  Nurikabe
//
//  Created by Assistant on 8/12/25.
//

import UIKit

struct AppColors {
    private static let primaryKey = "AppColors.primary.hex"
    private static let defaultPrimary = UIColor(red: 0.945, green: 0.537, blue: 0.722, alpha: 1.0)
    
    // MARK: - Primary Colors (dynamic, persisted)
    static var primary: UIColor {
        get {
            if let hex = UserDefaults.standard.string(forKey: primaryKey), let color = ColorUtils.color(fromHex: hex) {
                return color
            }
            return defaultPrimary
        }
        set {
            let hex = ColorUtils.hexString(from: newValue)
            UserDefaults.standard.set(hex, forKey: primaryKey)
        }
    }
    
    static var secondary: UIColor { UIColor(white: 1.0, alpha: 1.0) }
    
    // MARK: - Derived Colors (computed from primary)
    static var primaryLight: UIColor { primary.withAlphaComponent(0.3) }
    static var primaryDark: UIColor { primary.withAlphaComponent(0.8) }
    
    // MARK: - UI Colors
    static var background: UIColor { primary }
    static var buttonBackground: UIColor { UIColor(white: 1.0, alpha: 1.0) }
    static var buttonText: UIColor { primary }
    static var titleText: UIColor { UIColor(white: 1.0, alpha: 1.0) }
    static var subtitleText: UIColor { UIColor(white: 1.0, alpha: 0.8) }
}
