//
//  GridSizeScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Grid size selection scene with simplified structure
final class GridSizeScene: BaseScene {
    
    private var backButton: SKNode!
    private var gridSizeButtons: [SKNode] = []
    private let gridConfigs = GameConfig.gridSizes
    
    override func setupScene() {
        setupStandardBackground()
        setupTitle()
        setupBackButton()
        setupGridSizeButtons()
    }
    
    private func setupTitle() {
        let titleLabel = createTitle("Choose Grid Size")
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.25)
        addChild(titleLabel)
    }
    
    private func setupBackButton() {
        backButton = createBackButton(text: "Menu")
        backButton.position = CGPoint(x: 0, y: -size.height * 0.4)
        backButton.zPosition = 100  // Ensure it's above other UI elements
        addChild(backButton)
    }
    
    private func setupGridSizeButtons() {
        let spacing: CGFloat = 72
        let buttonWidth = max(220, min(size.width * 0.7, 320))
        let startY: CGFloat = 30
        
        for (index, gridConfig) in gridConfigs.enumerated() {
            let y = startY - CGFloat(index) * spacing
            let button = createGridSizeButton(
                config: gridConfig,
                width: buttonWidth,
                actionName: "gridButton_\(index)"
            )
            button.position = CGPoint(x: 0, y: y)
            gridSizeButtons.append(button)
            addChild(button)
        }
    }
    
    private func createGridSizeButton(
        config: GameConfig.GridSizeConfig,
        width: CGFloat,
        actionName: String
    ) -> SKNode {
        let style: GameButton.Style
        
        if !config.isAvailable {
            style = GameButton.Style(
                width: width,
                height: 64,
                cornerRadius: 20,
                backgroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.4),
                strokeColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.4),
                lineWidth: 1.0,
                textColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0),
                fontSize: 22,
                fontName: "HelveticaNeue-Medium"
            )
        } else {
            style = GameButton.Style(
                width: width,
                height: 64,
                cornerRadius: 20,
                backgroundColor: AppColors.buttonBackground,
                strokeColor: UIColor.clear,
                lineWidth: 1.5,
                textColor: AppColors.buttonText,
                fontSize: 22,
                fontName: "HelveticaNeue-Medium"
            )
        }
        
        let button = GameButton.create(
            title: config.displayName,
            style: style,
            actionName: actionName
        )
        
        button.userData = ["isAvailable": config.isAvailable]
        
        if !config.isAvailable {
            let lockIcon = LockIcon.create(size: 12, color: UIColor.gray)
            lockIcon.position = CGPoint(x: width/2 - 16, y: style.height/2 - 16)
            lockIcon.zPosition = 5
            lockIcon.alpha = 0.7
            button.addChild(lockIcon)
        }
        
        return button
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let buttonNames = ["backButton"] + gridConfigs.enumerated().map { "gridButton_\($0.offset)" }
        
        handleButtonTouch(touch: touch, buttonNames: buttonNames, onPress: { button in
            if let isAvailable = button.userData?["isAvailable"] as? Bool, !isAvailable {
                return
            }
            GameButton.animatePress(button)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let buttonNames = ["backButton"] + gridConfigs.enumerated().map { "gridButton_\($0.offset)" }
        
        handleButtonTouch(touch: touch, buttonNames: buttonNames, onRelease: { button, buttonName in
            GameButton.animateRelease(button) {
                if buttonName == "backButton" {
                    self.returnToMenu()
                } else if buttonName.hasPrefix("gridButton_") {
                    let indexString = String(buttonName.dropFirst("gridButton_".count))
                    if let index = Int(indexString), index < self.gridConfigs.count {
                        self.handleGridSizeSelection(index: index)
                    }
                }
            }
        })
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        ([backButton] + gridSizeButtons).forEach { button in
            if let bg = button?.childNode(withName: "bg") as? SKShapeNode {
                bg.run(.group([.scale(to: 1.0, duration: 0.1), .fadeAlpha(to: 1.0, duration: 0.1)]))
            }
        }
    }
    
    // MARK: - Navigation
    
    private func handleGridSizeSelection(index: Int) {
        let gridConfig = gridConfigs[index]
        
        if !gridConfig.isAvailable {
            showComingSoonMessage(for: gridConfig)
            return
        }
        
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
    
    private func showComingSoonMessage(for config: GameConfig.GridSizeConfig) {
        let comingSoonLabel = SKLabelNode(fontNamed: FontUtils.preferredRegularFont())
        comingSoonLabel.text = "\(config.displayName) puzzles coming soon!"
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
    }
}
