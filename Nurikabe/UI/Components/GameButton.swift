//
//  GameButton.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Reusable button component for the game
class GameButton {
    
    struct Style {
        let width: CGFloat
        let height: CGFloat
        let cornerRadius: CGFloat
        let backgroundColor: UIColor
        let strokeColor: UIColor
        let lineWidth: CGFloat
        let textColor: UIColor
        let fontSize: CGFloat
        let fontName: String
        
        static let `default` = Style(
            width: 150,
            height: 50,
            cornerRadius: 12,
            backgroundColor: AppColors.buttonBackground,
            strokeColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3),
            lineWidth: 1.0,
            textColor: AppColors.buttonText,
            fontSize: 28,
            fontName: "HelveticaNeue-Medium"
        )
        
        static let menu = Style(
            width: 260,
            height: 64,
            cornerRadius: 20,
            backgroundColor: AppColors.buttonBackground,
            strokeColor: UIColor.clear,
            lineWidth: 1.0,
            textColor: AppColors.buttonText,
            fontSize: 22,
            fontName: "HelveticaNeue-Medium"
        )
        
        static let small = Style(
            width: 120,
            height: 45,
            cornerRadius: 12,
            backgroundColor: AppColors.buttonBackground,
            strokeColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3),
            lineWidth: 1.0,
            textColor: AppColors.buttonText,
            fontSize: 24,
            fontName: "HelveticaNeue-Medium"
        )
    }
    
    static func create(
        title: String,
        style: Style = .default,
        icon: String? = nil,
        actionName: String
    ) -> SKNode {
        let container = SKNode()
        container.name = actionName
        container.zPosition = 50
        
        // Background - this will be the main touch target
        let bg = SKShapeNode(rectOf: CGSize(width: style.width, height: style.height), cornerRadius: style.cornerRadius)
        bg.name = "bg"
        bg.fillColor = style.backgroundColor
        bg.strokeColor = style.strokeColor
        bg.lineWidth = style.lineWidth
        bg.zPosition = 1
        container.addChild(bg)
        
        // Icon (if provided)
        if let icon = icon {
            let iconLabel = SKLabelNode(fontNamed: style.fontName)
            iconLabel.text = icon
            iconLabel.fontSize = style.fontSize * 0.8
            iconLabel.fontColor = style.textColor
            iconLabel.verticalAlignmentMode = .center
            iconLabel.horizontalAlignmentMode = .center
            iconLabel.position = CGPoint(x: -style.width * 0.34, y: 0)
            iconLabel.zPosition = 2
            container.addChild(iconLabel)
        }
        
        // Title text
        let label = SKLabelNode(fontNamed: style.fontName)
        label.text = title
        label.fontSize = style.fontSize
        label.fontColor = style.textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: icon != nil ? 8 : 0, y: 0)
        label.zPosition = 2
        container.addChild(label)
        
        return container
    }
    
    static func animatePress(_ button: SKNode) {
        if let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let press = SKAction.group([
                .scale(to: 0.95, duration: 0.12),
                .fadeAlpha(to: 0.85, duration: 0.12)
            ])
            bg.run(press)
        }
    }
    
    static func animateRelease(_ button: SKNode, completion: @escaping () -> Void = {}) {
        if let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let release = SKAction.group([
                .scale(to: 1.0, duration: 0.15),
                .fadeAlpha(to: 1.0, duration: 0.15)
            ])
            bg.run(release) {
                completion()
            }
        } else {
            completion()
        }
    }
}
