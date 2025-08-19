//
//  LockIcon.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Reusable lock icon component
class LockIcon {
    
    static func create(size: CGFloat, color: UIColor = UIColor.white) -> SKNode {
        let container = SKNode()
        
        // Create lock body (main rectangle)
        let bodyHeight = size * 0.6
        let bodyWidth = size * 0.8
        let body = SKShapeNode(rectOf: CGSize(width: bodyWidth, height: bodyHeight), cornerRadius: size * 0.1)
        body.fillColor = color
        body.strokeColor = color
        body.lineWidth = 0
        body.position = CGPoint(x: 0, y: -size * 0.1)
        container.addChild(body)
        
        // Create lock shackle (top curved part)
        let shackleWidth = size * 0.5
        let shackleHeight = size * 0.4
        let shackle = SKShapeNode(rectOf: CGSize(width: shackleWidth, height: shackleHeight), cornerRadius: shackleWidth/2)
        shackle.fillColor = UIColor.clear
        shackle.strokeColor = color
        shackle.lineWidth = size * 0.15
        shackle.position = CGPoint(x: 0, y: size * 0.25)
        container.addChild(shackle)
        
        // Create keyhole
        let keyhole = SKShapeNode(circleOfRadius: size * 0.1)
        keyhole.fillColor = color
        keyhole.strokeColor = UIColor.clear
        keyhole.position = CGPoint(x: 0, y: -size * 0.05)
        container.addChild(keyhole)
        
        // Add small rectangle below keyhole
        let keyholeSlot = SKShapeNode(rectOf: CGSize(width: size * 0.08, height: size * 0.15))
        keyholeSlot.fillColor = color
        keyholeSlot.strokeColor = UIColor.clear
        keyholeSlot.position = CGPoint(x: 0, y: -size * 0.15)
        container.addChild(keyholeSlot)
        
        return container
    }
}
