//
//  SettingsScene.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import SpriteKit

final class SettingsScene: BaseScene {
    private var backButton: SKNode!
    private var swatches: [SKNode] = []
    
    override func setupScene() {
        setupTitle()
        setupColorSwatches()
        setupBack()
    }
    
    private func setupTitle() {
        let title = createTitle("Settings", fontSize: max(36, min(44, size.width * 0.07)))
        title.position = CGPoint(x: 0, y: size.height * 0.35)
        addChild(title)
    }
    
    private func setupBack() {
        backButton = createBackButton()
        backButton.position = CGPoint(x: 0, y: -size.height * 0.4)
        addChild(backButton)
    }
    
    private func setupColorSwatches() {
        // Preset primary colors
        let presets: [UIColor] = [
            UIColor(red: 0.945, green: 0.537, blue: 0.722, alpha: 1.0),
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.25, green: 0.52, blue: 0.96, alpha: 1.0),
            UIColor(red: 0.12, green: 0.74, blue: 0.48, alpha: 1.0),
            UIColor(red: 0.98, green: 0.76, blue: 0.18, alpha: 1.0)
        ]
        
        let gridWidth = min(size.width * 0.9, size.height * 0.6)
        let swatchSize: CGFloat = 54
        let spacing: CGFloat = 16
        let totalWidth = CGFloat(presets.count) * swatchSize + CGFloat(presets.count - 1) * spacing
        let startX = -totalWidth / 2 + swatchSize / 2
        
        for (idx, color) in presets.enumerated() {
            let node = SKNode()
            node.name = "swatch_\(idx)"
            let bg = SKShapeNode(rectOf: CGSize(width: swatchSize, height: swatchSize), cornerRadius: 12)
            bg.fillColor = color
            bg.strokeColor = UIColor.white
            bg.lineWidth = 2
            node.addChild(bg)
            node.position = CGPoint(x: startX + CGFloat(idx) * (swatchSize + spacing), y: 0)
            node.zPosition = 20
            addChild(node)
            swatches.append(node)
        }
        
        let subtitle = SKLabelNode(fontNamed: FontUtils.preferredRegularFont())
        subtitle.text = "Pick a theme color"
        subtitle.fontSize = 18
        subtitle.fontColor = UIColor.white
        subtitle.position = CGPoint(x: 0, y: 80)
        addChild(subtitle)
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleButtonTouch(touch: touch, buttonNames: ["backButton"], onPress: { GameButton.animatePress($0) })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Back
        handleButtonTouch(touch: touch, buttonNames: ["backButton"], onRelease: { button, _ in
            GameButton.animateRelease(button) { self.returnToMenu() }
        })
        
        // Swatches
        let location = touch.location(in: self)
        let node = atPoint(location)
        if let swatch = TouchUtils.findAncestor(node, prefix: "swatch_") {
            applySwatch(swatch)
        }
    }
    
    private func applySwatch(_ swatch: SKNode) {
        guard let bg = swatch.children.first as? SKShapeNode else { return }
        let picked = bg.fillColor
        AppColors.primary = picked
        // Soft feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Refresh background immediately
        backgroundColor = AppColors.background

        // Live-retint back button label/icon if present
        if let label = backButton.childNode(withName: "label") as? SKLabelNode {
            label.fontColor = AppColors.primary
        }
        if let icon = backButton.childNode(withName: "icon") as? SKLabelNode {
            icon.fontColor = AppColors.primary
        }
    }
    
    private func returnToMenu() {
        guard let view = view else { return }
        let menu = MenuScene(size: view.bounds.size)
        menu.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(menu, transition: transition)
    }
}


