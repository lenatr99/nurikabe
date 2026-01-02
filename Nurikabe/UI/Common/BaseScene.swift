//
//  BaseScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Base scene class with common functionality
class BaseScene: SKScene {
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = AppColors.background
        setupScene()
    }
    
    /// Override this method in subclasses to setup scene-specific content
    func setupScene() {
        // Override in subclasses
    }
    
    /// Creates a standard background with overlays and effects
    func setupStandardBackground() {
        // Elegant overlay for depth (slightly oversize to avoid edge halos)
        let oversize = CGSize(width: size.width + 4, height: size.height + 4)
        let overlay = SKShapeNode(rectOf: oversize, cornerRadius: 0)
        overlay.fillColor = UIColor(red: 0.92, green: 0.65, blue: 0.82, alpha: 0.12)
        overlay.strokeColor = .clear
        overlay.lineWidth = 0
        overlay.isAntialiased = false
        overlay.alpha = 1.0
        overlay.zPosition = -95
        overlay.blendMode = .alpha
        addChild(overlay)
        
        // Subtle animated shimmer
        let shimmer = SKShapeNode(rectOf: oversize, cornerRadius: 0)
        shimmer.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.95, alpha: 0.08)
        shimmer.strokeColor = .clear
        shimmer.lineWidth = 0
        shimmer.isAntialiased = false
        shimmer.alpha = 0.0
        shimmer.zPosition = -90
        shimmer.blendMode = .alpha
        addChild(shimmer)
        
        let shimmerPulse = SKAction.sequence([
            .fadeAlpha(to: 0.6, duration: 3.5),
            .fadeAlpha(to: 0.0, duration: 3.5)
        ])
        shimmer.run(.repeatForever(shimmerPulse))
    }
    
    /// Creates a standard title label
    func createTitle(_ text: String, fontSize: CGFloat? = nil) -> SKLabelNode {
        let titleLabel = SKLabelNode(fontNamed: FontUtils.preferredTitleFont())
        titleLabel.text = text
        titleLabel.fontSize = fontSize ?? max(36, min(48, size.width * 0.065))
        titleLabel.fontColor = AppColors.titleText
        titleLabel.alpha = 1
        titleLabel.zPosition = 10
        return titleLabel
    }

    /// Creates an outlined label by layering two labels
    func createStrokedLabel(
        text: String,
        fontName: String,
        fontSize: CGFloat,
        fillColor: UIColor,
        strokeColor: UIColor,
        strokeWidth: CGFloat
    ) -> SKNode {
        let container = SKNode()
        
        let fill = SKLabelNode(fontNamed: fontName)
        fill.text = text
        fill.fontSize = fontSize
        fill.fontColor = fillColor
        fill.verticalAlignmentMode = .center
        fill.horizontalAlignmentMode = .center
        
        // Create stroke by duplicating label several times around
        let angles: [CGFloat] = [
            0,
            .pi / 4,
            .pi / 2,
            3 * .pi / 4,
            .pi,
            5 * .pi / 4,
            3 * .pi / 2,
            7 * .pi / 4
        ]
        for angle in angles {
            let dx = cos(angle) * strokeWidth
            let dy = sin(angle) * strokeWidth
            let stroke = SKLabelNode(fontNamed: fontName)
            stroke.text = text
            stroke.fontSize = fontSize
            stroke.fontColor = strokeColor
            stroke.verticalAlignmentMode = .center
            stroke.horizontalAlignmentMode = .center
            stroke.position = CGPoint(x: dx, y: dy)
            stroke.zPosition = -1
            container.addChild(stroke)
        }
        
        container.addChild(fill)
        return container
    }
    
    /// Creates a standard back button
    func createBackButton(text: String = "Back", action: String = "backButton") -> SKNode {
        return GameButton.create(
            title: text,
            style: .small,
            actionName: action
        )
    }
    
    /// Generic method to handle button touch detection for press events
    func handleButtonTouch(
        touch: UITouch,
        buttonNames: [String],
        onPress: @escaping (SKNode) -> Void
    ) {
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if let button = TouchUtils.findButtonAncestor(touchedNode, validButtonNames: buttonNames) {
            onPress(button)
        }
    }
    
    /// Generic method to handle button touch detection for release events
    func handleButtonTouch(
        touch: UITouch,
        buttonNames: [String],
        onRelease: @escaping (SKNode, String) -> Void
    ) {
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if let button = TouchUtils.findButtonAncestor(touchedNode, validButtonNames: buttonNames),
           let buttonName = button.name {
            onRelease(button, buttonName)
        }
    }
}
