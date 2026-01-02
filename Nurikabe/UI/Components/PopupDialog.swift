//
//  PopupDialog.swift
//  Nurikabe
//
//  Created by Assistant on 1/2/26.
//

import SpriteKit

/// A reusable popup dialog component for in-game confirmations
class PopupDialog {
    
    // MARK: - Configuration
    
    struct Config {
        let title: String
        let message: String
        let messageLine2: String?
        let primaryButtonText: String
        let secondaryButtonText: String
        let primaryAction: String   // Node name for identification
        let secondaryAction: String // Node name for identification
        
        static func hint() -> Config {
            Config(
                title: "Get a Hint?",
                message: "Watch a short video to reveal",
                messageLine2: "one correct cell",
                primaryButtonText: "Watch Ad",
                secondaryButtonText: "Cancel",
                primaryAction: "watchAdButton",
                secondaryAction: "cancelHintButton"
            )
        }
    }
    
    // MARK: - Creation
    
    /// Create a popup dialog overlay
    /// - Parameters:
    ///   - config: The dialog configuration
    ///   - sceneSize: The size of the scene to fill
    /// - Returns: The overlay node to add to the scene
    static func create(config: Config, sceneSize: CGSize) -> SKNode {
        // Create overlay background
        let overlay = SKShapeNode(rectOf: sceneSize)
        overlay.fillColor = UIColor.black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint.zero
        overlay.zPosition = 300
        overlay.name = "popupOverlay"
        overlay.alpha = 0
        
        // Create popup box
        let popupWidth: CGFloat = min(sceneSize.width * 0.85, 320)
        let popupHeight: CGFloat = 200
        let popup = SKShapeNode(rectOf: CGSize(width: popupWidth, height: popupHeight), cornerRadius: 16)
        popup.fillColor = UIColor.white
        popup.strokeColor = AppColors.primary
        popup.lineWidth = 3
        popup.position = CGPoint.zero
        popup.zPosition = 1
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        titleLabel.text = config.title
        titleLabel.fontSize = 24
        titleLabel.fontColor = AppColors.primary
        titleLabel.position = CGPoint(x: 0, y: 50)
        titleLabel.zPosition = 2
        popup.addChild(titleLabel)
        
        // Message line 1
        let messageLabel = SKLabelNode(fontNamed: "HelveticaNeue")
        messageLabel.text = config.message
        messageLabel.fontSize = 16
        messageLabel.fontColor = UIColor.darkGray
        messageLabel.position = CGPoint(x: 0, y: config.messageLine2 != nil ? 15 : 5)
        messageLabel.zPosition = 2
        popup.addChild(messageLabel)
        
        // Message line 2 (optional)
        if let line2 = config.messageLine2 {
            let messageLabel2 = SKLabelNode(fontNamed: "HelveticaNeue")
            messageLabel2.text = line2
            messageLabel2.fontSize = 16
            messageLabel2.fontColor = UIColor.darkGray
            messageLabel2.position = CGPoint(x: 0, y: -5)
            messageLabel2.zPosition = 2
            popup.addChild(messageLabel2)
        }
        
        // Primary button (e.g., "Watch Ad")
        let primaryButton = createButton(text: config.primaryButtonText, isPrimary: true)
        primaryButton.position = CGPoint(x: -65, y: -55)
        primaryButton.name = config.primaryAction
        popup.addChild(primaryButton)
        
        // Secondary button (e.g., "Cancel")
        let secondaryButton = createButton(text: config.secondaryButtonText, isPrimary: false)
        secondaryButton.position = CGPoint(x: 65, y: -55)
        secondaryButton.name = config.secondaryAction
        popup.addChild(secondaryButton)
        
        overlay.addChild(popup)
        return overlay
    }
    
    // MARK: - Button Creation
    
    private static func createButton(text: String, isPrimary: Bool) -> SKNode {
        let button = SKNode()
        
        let bg = SKShapeNode(rectOf: CGSize(width: 110, height: 40), cornerRadius: 8)
        bg.fillColor = isPrimary ? AppColors.primary : UIColor.lightGray.withAlphaComponent(0.3)
        bg.strokeColor = isPrimary ? AppColors.primary : UIColor.gray
        bg.lineWidth = 1
        button.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = text
        label.fontSize = 16
        label.fontColor = isPrimary ? UIColor.white : UIColor.darkGray
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        label.zPosition = 1
        button.addChild(label)
        
        return button
    }
    
    // MARK: - Animations
    
    /// Animate the popup appearing
    static func show(_ overlay: SKNode) {
        overlay.run(.fadeIn(withDuration: 0.2))
    }
    
    /// Animate the popup dismissing and remove it
    static func dismiss(_ overlay: SKNode) {
        overlay.run(.sequence([
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
    }
    
    /// Animate a button press
    static func animateButtonPress(_ button: SKNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.08)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.08)
        button.run(.sequence([scaleDown, scaleUp])) {
            completion()
        }
    }
    
    /// Find which button was tapped (if any) by traversing node hierarchy
    /// - Parameters:
    ///   - touchedNode: The node that was touched
    ///   - buttonNames: Array of button names to look for
    /// - Returns: The name of the button that was tapped, or nil
    static func findTappedButton(touchedNode: SKNode, buttonNames: [String]) -> String? {
        var node: SKNode? = touchedNode
        while let current = node {
            if let name = current.name, buttonNames.contains(name) {
                return name
            }
            node = current.parent
        }
        return nil
    }
}

