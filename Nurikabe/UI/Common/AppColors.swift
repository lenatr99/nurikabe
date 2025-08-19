//
//  AppColors.swift
//  Nurikabe
//
//  Created by Assistant on 8/12/25.
//

import UIKit

struct AppColors {
    // MARK: - Primary Colors
    static let primary = UIColor(red: 0.945, green: 0.537, blue: 0.722, alpha: 1.0)
    
    // MARK: - Derived Colors
    static let primaryLight = primary.withAlphaComponent(0.3)
    static let primaryDark = UIColor(red: 0.756, green: 0.429, blue: 0.578, alpha: 1.0)
    
    // MARK: - UI Colors
    static let background = primary
    static let buttonBackground = UIColor(red: 1.0, green: 1, blue: 1, alpha: 1)
    static let buttonText = UIColor(red: 0.945, green: 0.537, blue: 0.722, alpha: 1.0)
    static let titleText = UIColor(red: 1.0, green: 1, blue: 1, alpha: 1.0)
    static let subtitleText = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
}
