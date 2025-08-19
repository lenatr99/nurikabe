//
//  FontUtils.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import UIKit

/// Utility class for font management across the app
struct FontUtils {
    
    static func preferredTitleFont() -> String {
        let candidates = ["Georgia-Bold", "TimesNewRomanPS-BoldMT", "AvenirNext-Heavy", "HelveticaNeue-Bold"]
        for name in candidates where UIFont(name: name, size: 20) != nil { return name }
        return UIFont.boldSystemFont(ofSize: 20).fontName
    }
    
    static func preferredSubtitleFont() -> String {
        let candidates = ["AvenirNext-Medium", "HelveticaNeue-Light", "HelveticaNeue-Thin"]
        for name in candidates where UIFont(name: name, size: 18) != nil { return name }
        return UIFont.systemFont(ofSize: 18, weight: .light).fontName
    }
    
    static func preferredButtonFont() -> String {
        let candidates = ["AvenirNext-DemiBold", "HelveticaNeue-Medium", "AvenirNext-Medium"]
        for name in candidates where UIFont(name: name, size: 20) != nil { return name }
        return UIFont.systemFont(ofSize: 20, weight: .medium).fontName
    }
    
    static func preferredBoldFont() -> String {
        let candidates = ["AvenirNext-Heavy", "AvenirNext-Bold", "HelveticaNeue-Bold"]
        for name in candidates where UIFont(name: name, size: 20) != nil { return name }
        return UIFont.boldSystemFont(ofSize: 20).fontName
    }
    
    static func preferredRegularFont() -> String {
        let candidates = ["AvenirNext-Medium", "HelveticaNeue-Medium", "HelveticaNeue"]
        for name in candidates where UIFont(name: name, size: 18) != nil { return name }
        return UIFont.systemFont(ofSize: 18).fontName
    }
}
