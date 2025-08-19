//
//  MenuScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Main menu scene with simplified, modular structure
final class MenuScene: BaseScene {
    
    private var playButton: SKNode!
    private var settingsButton: SKNode!
    
    override func setupScene() {
        setupBackground()
        setupTitle()
        setupButtons()
    }
    
    private func setupBackground() {
        setupStandardBackground()
        setupDecorativeElements()
        setupAmbientParticles()
    }
    
    private func setupTitle() {
        let titleLabel = createTitle("Nurikabe", fontSize: max(48, min(64, size.width * 0.085)))
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.22)
        addChild(titleLabel)
        
        let subtitleLabel = SKLabelNode(fontNamed: FontUtils.preferredSubtitleFont())
        subtitleLabel.text = "Logic Islands"
        subtitleLabel.fontSize = max(18, min(26, size.width * 0.035))
        subtitleLabel.fontColor = AppColors.subtitleText
        subtitleLabel.position = CGPoint(x: 0, y: titleLabel.position.y - (titleLabel.fontSize * 0.85))
        subtitleLabel.alpha = 1
        subtitleLabel.zPosition = 9
        addChild(subtitleLabel)
    }
    
    private func setupButtons() {
        let spacing: CGFloat = 74
        
        playButton = GameButton.create(
            title: "Play",
            style: GameButton.Style.menu,
            icon: "▶︎",
            actionName: "playButton"
        )
        playButton.position = CGPoint(x: 0, y: -spacing * 0.5)
        addChild(playButton)
        
        settingsButton = GameButton.create(
            title: "Settings",
            style: GameButton.Style.menu,
            icon: "☰",
            actionName: "settingsButton"
        )
        settingsButton.position = CGPoint(x: 0, y: playButton.position.y - spacing)
        addChild(settingsButton)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        handleButtonTouch(touch: touch, buttonNames: ["playButton", "settingsButton"], onPress: { button in
            GameButton.animatePress(button)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        handleButtonTouch(touch: touch, buttonNames: ["playButton", "settingsButton"], onRelease: { button, buttonName in
            GameButton.animateRelease(button) {
                switch buttonName {
                case "playButton":
                    self.startGame()
                case "settingsButton":
                    self.showSettings()
                default:
                    break
                }
            }
        })
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        [playButton, settingsButton].compactMap { $0 }.forEach { button in
            button.run(.group([.scale(to: 1.0, duration: 0.1), .fadeAlpha(to: 1.0, duration: 0.1)]))
        }
    }
    
    // MARK: - Navigation
    
    private func startGame() {
        guard let view = view else { return }
        let gridSizeScene = GridSizeScene(size: view.bounds.size)
        gridSizeScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(gridSizeScene, transition: transition)
    }
    
    private func showSettings() {
        let pop = SKLabelNode(fontNamed: FontUtils.preferredRegularFont())
        pop.text = "Settings coming soon"
        pop.fontSize = 18
        pop.alpha = 0
        pop.zPosition = 999
        addChild(pop)
        pop.run(.sequence([.fadeIn(withDuration: 0.15),
                          .wait(forDuration: 1.0),
                          .fadeOut(withDuration: 0.25),
                          .removeFromParent()]))
    }
    
    // MARK: - Visual Effects (kept from original but simplified)
    
    private func setupDecorativeElements() {
        let decorativeLayer = SKNode()
        decorativeLayer.zPosition = -40
        decorativeLayer.alpha = 0.15
        addChild(decorativeLayer)
        
        // Large circle in top-right
        let circle1 = SKShapeNode(circleOfRadius: size.width * 0.25)
        circle1.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.95, alpha: 0.12)
        circle1.strokeColor = UIColor(red: 0.95, green: 0.75, blue: 0.88, alpha: 0.15)
        circle1.lineWidth = 2.0
        circle1.position = CGPoint(x: size.width * 0.35, y: size.height * 0.3)
        decorativeLayer.addChild(circle1)
        
        // Medium circle in bottom-left
        let circle2 = SKShapeNode(circleOfRadius: size.width * 0.15)
        circle2.fillColor = UIColor(red: 0.98, green: 0.82, blue: 0.92, alpha: 0.08)
        circle2.strokeColor = UIColor(red: 0.92, green: 0.65, blue: 0.82, alpha: 0.2)
        circle2.lineWidth = 1.5
        circle2.position = CGPoint(x: -size.width * 0.3, y: -size.height * 0.25)
        decorativeLayer.addChild(circle2)
        
        // Breathing animations
        let breathe = SKAction.sequence([
            .scale(to: 1.05, duration: 4.0),
            .scale(to: 0.95, duration: 4.0)
        ])
        circle1.run(.repeatForever(breathe).withTimingMode(.easeInEaseOut))
        
        let breathe2 = SKAction.sequence([
            .scale(to: 0.95, duration: 3.5),
            .scale(to: 1.05, duration: 3.5)
        ])
        circle2.run(.repeatForever(breathe2).withTimingMode(.easeInEaseOut))
    }
    
    private func setupAmbientParticles() {
        guard let view = view else { return }
        
        for number in 1...8 {
            let sparkleTexture = view.texture(from: createNumberedSquare(size: 15, number: number))
            
            let sparkleEmitter = SKEmitterNode()
            sparkleEmitter.particleTexture = sparkleTexture
            sparkleEmitter.particleBirthRate = 0.8
            sparkleEmitter.particleLifetime = 8
            sparkleEmitter.particleLifetimeRange = 3
            sparkleEmitter.particleSpeed = 15
            sparkleEmitter.particleSpeedRange = 10
            sparkleEmitter.particleAlpha = 0.6
            sparkleEmitter.particleAlphaRange = 0.3
            sparkleEmitter.particleAlphaSpeed = -0.05
            sparkleEmitter.particleScale = 1.2
            sparkleEmitter.particleScaleRange = 0.6
            sparkleEmitter.particleScaleSpeed = -0.08
            sparkleEmitter.particleColor = UIColor.white
            sparkleEmitter.particlePositionRange = CGVector(dx: size.width, dy: size.height * 0.2)
            sparkleEmitter.emissionAngle = CGFloat.pi / 2.0
            sparkleEmitter.emissionAngleRange = .pi / 6
            sparkleEmitter.particleZPosition = -45
            sparkleEmitter.position = CGPoint(x: 0, y: -size.height * 0.3)
            sparkleEmitter.xAcceleration = 1
            sparkleEmitter.yAcceleration = 3
            
            addChild(sparkleEmitter)
        }
    }
    
    private func createNumberedSquare(size: CGFloat, number: Int) -> SKNode {
        let container = SKNode()
        
        let square = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 2)
        square.fillColor = UIColor.white
        square.strokeColor = UIColor.white
        square.lineWidth = 1.0
        container.addChild(square)
        
        let numberLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        numberLabel.text = "\(number)"
        numberLabel.fontSize = size * 0.6
        numberLabel.fontColor = AppColors.primary
        numberLabel.verticalAlignmentMode = .center
        numberLabel.horizontalAlignmentMode = .center
        numberLabel.position = CGPoint.zero
        container.addChild(numberLabel)
        
        return container
    }
}
