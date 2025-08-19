//
//  SKActionExtensions.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Extension for SKAction convenience methods
extension SKAction {
    
    /// Applies a timing mode to the action and returns self for chaining
    func withTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
