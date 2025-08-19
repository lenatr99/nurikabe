//
//  GridSizeScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/15/25.
//

import SpriteKit
import GameplayKit
import UIKit

final class GridSizeScene: SKScene {
    
    // MARK: - Nodes
    private var titleLabel: SKLabelNode!
    private var backButton: SKNode!
    private var gridSizeButtons: [SKNode] = []
    
    // MARK: - Grid Size Configuration
    private let gridConfigs = GameConfig.gridSizes
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // center-based layout
        backgroundColor = AppColors.background
        
        setupBackground()
        setupTitle()
        setupBackButton()
        setupGridSizeButtons()
    }
    
    // MARK: - Background
    private func setupBackground() {
        // Elegant radial overlay for depth
        let overlay = SKShapeNode(rectOf: size, cornerRadius: 0)
        overlay.fillColor = UIColor(red: 0.92, green: 0.65, blue: 0.82, alpha: 0.12)
        overlay.alpha = 1.0
        overlay.zPosition = -95
        overlay.blendMode = .screen
        addChild(overlay)
        
        // Subtle animated shimmer
        let shimmer = SKShapeNode(rectOf: size, cornerRadius: 0)
        shimmer.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.95, alpha: 0.08)
        shimmer.alpha = 0.0
        shimmer.zPosition = -90
        shimmer.blendMode = .screen
        addChild(shimmer)
        
        let shimmerPulse = SKAction.sequence([
            .fadeAlpha(to: 0.6, duration: 3.5),
            .fadeAlpha(to: 0.0, duration: 3.5)
        ])
        shimmer.run(.repeatForever(shimmerPulse))
    }
    
    // MARK: - Title
    private func setupTitle() {
        titleLabel = SKLabelNode(fontNamed: preferredTitleFont())
        titleLabel.text = "Choose Grid Size"
        titleLabel.fontSize = max(36, min(48, size.width * 0.065))
        titleLabel.fontColor = AppColors.titleText
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.25)
        titleLabel.alpha = 1
        titleLabel.zPosition = 10
        addChild(titleLabel)
    }
    
    // MARK: - Back Button
    private func setupBackButton() {
        let container = SKNode()
        container.name = "backButton"
        container.zPosition = 100
        
        let buttonWidth: CGFloat = 120
        let buttonHeight: CGFloat = 45
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        bg.name = "bg"
        bg.fillColor = AppColors.buttonBackground
        bg.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Menu"
        label.fontSize = 24
        label.fontColor = AppColors.buttonText
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        label.zPosition = 1
        container.addChild(label)
        
        container.position = CGPoint(x: 0, y: -size.height * 0.4)
        
        backButton = container
        addChild(container)
    }
    
    // MARK: - Grid Size Buttons
    private func setupGridSizeButtons() {
        let spacing: CGFloat = 72
        let buttonWidth = max(220, min(size.width * 0.7, 320))
        let startY: CGFloat = 30 // Starting position relative to center
        
        for (index, gridConfig) in gridConfigs.enumerated() {
            let y = startY - CGFloat(index) * spacing
            let button = makeGridSizeButton(
                title: gridConfig.displayName,
                width: buttonWidth,
                isAvailable: gridConfig.isAvailable,
                actionName: "gridButton_\(index)"
            )
            button.position = CGPoint(x: 0, y: y)
            gridSizeButtons.append(button)
            addChild(button)
        }
    }
    
    // MARK: - Button Creation
    private func makeGridSizeButton(title: String, width: CGFloat, isAvailable: Bool, actionName: String) -> SKNode {
        let container = SKNode()
        container.name = actionName
        container.userData = ["isAvailable": isAvailable]
        container.zPosition = 50
        
        // Button background - same style as MenuScene
        let height: CGFloat = 64
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 20)
        bg.name = "bg"
        
        if isAvailable {
            bg.fillColor = AppColors.buttonBackground
            bg.lineWidth = 1.5
        } else {
            bg.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
            bg.strokeColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
            bg.lineWidth = 1.0
        }
        
        container.addChild(bg)
        
        // Main title text - same style as MenuScene
        let label = SKLabelNode(fontNamed: preferredButtonFont())
        label.text = title
        label.fontSize = 22
        label.fontColor = isAvailable ? AppColors.buttonText : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        label.position = CGPoint(x: 8, y: 0)
        label.zPosition = 4
        container.addChild(label)
        
        // Lock icon for unavailable options (small, in corner)
        if !isAvailable {
            let lockIcon = createLockIcon(size: 12)
            lockIcon.position = CGPoint(x: width/2 - 16, y: height/2 - 16)
            lockIcon.zPosition = 5
            lockIcon.alpha = 0.7
            container.addChild(lockIcon)
        }
        
        return container
    }
    
    private func createLockIcon(size: CGFloat) -> SKNode {
        let container = SKNode()
        
        // Create lock body (main rectangle)
        let bodyHeight = size * 0.6
        let bodyWidth = size * 0.8
        let body = SKShapeNode(rectOf: CGSize(width: bodyWidth, height: bodyHeight), cornerRadius: size * 0.1)
        body.fillColor = UIColor.gray
        body.strokeColor = UIColor.gray
        body.lineWidth = 0
        body.position = CGPoint(x: 0, y: -size * 0.1)
        container.addChild(body)
        
        // Create lock shackle (top curved part)
        let shackleWidth = size * 0.5
        let shackleHeight = size * 0.4
        let shackle = SKShapeNode(rectOf: CGSize(width: shackleWidth, height: shackleHeight), cornerRadius: shackleWidth/2)
        shackle.fillColor = UIColor.clear
        shackle.strokeColor = UIColor.gray
        shackle.lineWidth = size * 0.15
        shackle.position = CGPoint(x: 0, y: size * 0.25)
        container.addChild(shackle)
        
        return container
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        guard let button = nodeButtonAncestor(node) else { return }
        
        // Only allow interaction for available buttons
        if let isAvailable = button.userData?["isAvailable"] as? Bool, !isAvailable {
            return
        }
        
        // Elegant press feedback with bounce
        if let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let press = SKAction.group([
                .scale(to: 0.95, duration: 0.12),
                .fadeAlpha(to: 0.85, duration: 0.12)
            ]).withTimingMode(.easeOut)
            bg.run(press)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        guard let button = nodeButtonAncestor(node) else { return }
        
        // Elegant release animation with spring back
        if let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let release = SKAction.group([
                .scale(to: 1.0, duration: 0.15),
                .fadeAlpha(to: 1.0, duration: 0.15)
            ]).withTimingMode(.easeOut)
            
            // Add a subtle bounce effect
            let bounce = SKAction.sequence([
                .scale(to: 1.03, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]).withTimingMode(.easeInEaseOut)
            
            bg.run(.sequence([release, bounce]))
        }
        
        if button.name == "backButton" {
            returnToMenu()
        } else if let buttonName = button.name, buttonName.hasPrefix("gridButton_") {
            let indexString = String(buttonName.dropFirst("gridButton_".count))
            if let index = Int(indexString), index < gridConfigs.count {
                handleGridSizeSelection(index: index)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Reset visual state if touch cancels
        for button in [backButton] + gridSizeButtons {
            if let bg = button?.childNode(withName: "bg") as? SKShapeNode {
                bg.run(.group([.scale(to: 1.0, duration: 0.1), .fadeAlpha(to: 1.0, duration: 0.1)]))
            }
        }
    }
    
    // MARK: - Navigation
    private func handleGridSizeSelection(index: Int) {
        let gridConfig = gridConfigs[index]
        
        if !gridConfig.isAvailable {
            // Show "coming soon" message
            let comingSoonLabel = SKLabelNode(fontNamed: preferredRegularFont())
            comingSoonLabel.text = "\(gridConfig.displayName) puzzles coming soon!"
            comingSoonLabel.fontSize = 18
            comingSoonLabel.fontColor = AppColors.subtitleText
            comingSoonLabel.alpha = 0
            comingSoonLabel.zPosition = 999
            addChild(comingSoonLabel)
            comingSoonLabel.run(.sequence([
                .fadeIn(withDuration: 0.15),
                .wait(forDuration: 1.5),
                .fadeOut(withDuration: 0.25),
                .removeFromParent()
            ]))
            return
        }
        
        // Navigate to level select with the selected grid size
        guard let view = view else { return }
        
        let levelSelectScene = LevelSelectScene(size: view.bounds.size)
        levelSelectScene.scaleMode = .aspectFill
        levelSelectScene.setGridSize(filename: gridConfig.filename)
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(levelSelectScene, transition: transition)
    }
    
    private func returnToMenu() {
        guard let view = view else { return }
        
        let menuScene = MenuScene(size: view.bounds.size)
        menuScene.scaleMode = .aspectFill
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(menuScene, transition: transition)
    }
    
    // MARK: - Helpers
    private func nodeButtonAncestor(_ node: SKNode) -> SKNode? {
        if node.name == "backButton" || node.name?.hasPrefix("gridButton_") == true {
            return node
        }
        return node.parent.flatMap { nodeButtonAncestor($0) }
    }
    
    // MARK: - Font Utilities
    private func preferredTitleFont() -> String {
        let candidates = ["Georgia-Bold", "TimesNewRomanPS-BoldMT", "AvenirNext-Heavy", "HelveticaNeue-Bold"]
        for name in candidates where UIFont(name: name, size: 20) != nil { return name }
        return UIFont.boldSystemFont(ofSize: 20).fontName
    }
    
    private func preferredSubtitleFont() -> String {
        let candidates = ["AvenirNext-Medium", "HelveticaNeue-Light", "HelveticaNeue-Thin"]
        for name in candidates where UIFont(name: name, size: 18) != nil { return name }
        return UIFont.systemFont(ofSize: 18, weight: .light).fontName
    }
    
    private func preferredButtonFont() -> String {
        let candidates = ["AvenirNext-DemiBold", "HelveticaNeue-Medium", "AvenirNext-Medium"]
        for name in candidates where UIFont(name: name, size: 20) != nil { return name }
        return UIFont.systemFont(ofSize: 20, weight: .medium).fontName
    }
    
    private func preferredBoldFont() -> String {
        // AvenirNext is widely available; falls back to system
        let candidates = ["AvenirNext-Heavy", "AvenirNext-Bold", "HelveticaNeue-Bold"]
        for name in candidates where UIFont(name: name, size: 20) != nil { return name }
        return UIFont.boldSystemFont(ofSize: 20).fontName
    }
    
    private func preferredRegularFont() -> String {
        let candidates = ["AvenirNext-Medium", "HelveticaNeue-Medium", "HelveticaNeue"]
        for name in candidates where UIFont(name: name, size: 18) != nil { return name }
        return UIFont.systemFont(ofSize: 18).fontName
    }
}

// MARK: - Small SKAction convenience
private extension SKAction {
    func withTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
