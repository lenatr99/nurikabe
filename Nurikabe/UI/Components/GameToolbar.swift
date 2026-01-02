//
//  GameToolbar.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import SpriteKit

/// Modern toolbar component for game actions
class GameToolbar {
    
    struct Style {
        let width: CGFloat
        let height: CGFloat = 50
        let backgroundColor: UIColor
        let buttonSize: CGFloat = 44
        let buttonSpacing: CGFloat = 7
        let horizontalPadding: CGFloat = 0
        
        static let `default` = Style(
            width: 300,
            backgroundColor: UIColor.white
        )
    }
    
    /// Create a modern toolbar with action buttons
    static func create(style: Style, actions: [ToolbarAction]) -> SKNode {
        let toolbar = SKNode()
        toolbar.name = "gameToolbar"
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: style.width, height: style.height))
        background.fillColor = AppColors.primary
        background.strokeColor = UIColor(white: 1.0, alpha: 0.15)
        background.lineWidth = 0
        background.zPosition = 0
        toolbar.addChild(background)
        
        // Calculate button positions (left-aligned within toolbar)
        let startX = -style.width / 2 + style.horizontalPadding + style.buttonSize / 2
        
        // Create buttons
        for (index, action) in actions.enumerated() {
            let button = createToolbarButton(action: action, style: style)
            let xPosition = startX + CGFloat(index) * (style.buttonSize + style.buttonSpacing)
            button.position = CGPoint(x: xPosition, y: 0)
            button.zPosition = 1
            toolbar.addChild(button)
        }
        
        return toolbar
    }
    
    /// Create an individual toolbar button
    private static func createToolbarButton(action: ToolbarAction, style: Style) -> SKNode {
        let button = SKNode()
        button.name = action.name
        
        // Button background (invisible but tappable)
        let buttonBg = SKShapeNode(rectOf: CGSize(width: style.buttonSize, height: style.buttonSize), cornerRadius: 8)
        buttonBg.fillColor = AppColors.secondary.withAlphaComponent(1)
        buttonBg.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        buttonBg.zPosition = 0
        button.addChild(buttonBg)
        
        // Icon
        let iconSize: CGFloat = style.buttonSize * 0.6
        var iconNode: SKNode
        
        // Prefer loading from asset catalog if available
        if let uiImage = UIImage(named: action.iconName) {
            let texture = SKTexture(image: uiImage)
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: iconSize, height: iconSize)
            // Tint if desired (works best with template images)
            sprite.color = action.color
            sprite.colorBlendFactor = 1.0
            iconNode = sprite
        } else if let png = loadPNGFromResources(name: action.iconName) {
            let texture = SKTexture(image: png)
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: iconSize, height: iconSize)
            sprite.color = action.color
            sprite.colorBlendFactor = 1.0
            iconNode = sprite
        } else if let icon = SVGIcon.createIcon(named: action.iconName, size: iconSize, color: action.color) {
            // Fallback to basic SVG renderer
            iconNode = icon
        } else {
            // Fallback to text
            iconNode = SVGIcon.createFallbackIcon(text: action.fallbackText, size: iconSize, color: action.color)
        }
        
        iconNode.zPosition = 1
        button.addChild(iconNode)
        
        return button
    }
    
    /// Update button states (enabled/disabled)
    static func updateButtonState(toolbar: SKNode, buttonName: String, enabled: Bool) {
        guard let button = toolbar.childNode(withName: buttonName) else { return }
        
        button.alpha = enabled ? 1.0 : 0.35
        
        // Add subtle visual feedback for disabled state
        if let icon = button.children.first(where: { $0.zPosition == 1 }) {
            icon.removeAllActions()
        }
    }
    
    /// Add press animation to button
    static func animateButtonPress(_ button: SKNode, completion: @escaping () -> Void) {
        // Do not animate or act if disabled
        if button.alpha < 0.9 { return }
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        button.run(sequence) { completion() }
    }
}

/// Toolbar action definition
struct ToolbarAction {
    let name: String
    let iconName: String
    let fallbackText: String
    let color: UIColor
    
    static let undo = ToolbarAction(
        name: "undoButton",
        iconName: "undo",
        fallbackText: "↶",
        color: AppColors.primary
    )
    
    static let redo = ToolbarAction(
        name: "redoButton", 
        iconName: "redo",
        fallbackText: "↷",
        color: AppColors.primary
    )
    
    static let clear = ToolbarAction(
        name: "clearButton",
        iconName: "clear",
        fallbackText: "✕",
        color: AppColors.primary
    )

    static let flood = ToolbarAction(
        name: "floodButton",
        iconName: "flood",
        fallbackText: "~",
        color: AppColors.primary
    )
    
    static let hint = ToolbarAction(
        name: "hintButton",
        iconName: "hint",
        fallbackText: "💡",
        color: AppColors.primary
    )
}

// MARK: - Private helpers
private func loadPNGFromResources(name: String) -> UIImage? {
    if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Resources/Icons"),
       let data = NSData(contentsOfFile: path) as Data?,
       let image = UIImage(data: data) {
        return image
    }
    return nil
}
