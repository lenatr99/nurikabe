//
//  MenuScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/12/25.
//

import SpriteKit
import GameplayKit
import UIKit

final class MenuScene: SKScene {

    // MARK: - Nodes
    private var titleLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var playButton: SKNode!
    private var settingsButton: SKNode!
    private var backgroundGradient: SKSpriteNode!
    private var particleLayer: SKEmitterNode!

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // center-based layout

        setupBackgroundGradient()
        setupAmbientParticles()
        setupDecorativeElements()
        setupTitleStack()
        setupButtons()
        // runIntroAnimation()
    }

    // MARK: - Background
    private func setupBackgroundGradient() {
        // Solid pink background
        backgroundColor = AppColors.background

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

    private func setupAmbientParticles() {
        guard let view = view else { return }

        // Create elegant soft particle textures
        let circle = SKShapeNode(circleOfRadius: 3)
        circle.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.95, alpha: 0.8)
        // circle.strokeColor = .clear
        circle.glowWidth = 1.0
        // let circleTex = view.texture(from: circle)

        // Add multiple emitters for different numbers (1-4)
        for number in 1...8 {
            let sparkleTexture = view.texture(from: createNumberedSquare(size: 15, number: number))
            
            let sparkleEmitter = SKEmitterNode()
            sparkleEmitter.particleTexture = sparkleTexture
            sparkleEmitter.particleBirthRate = 0.8  // Lower rate since we have 4 emitters
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
            sparkleEmitter.particleColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            sparkleEmitter.particlePositionRange = CGVector(dx: size.width, dy: size.height * 0.2)
            sparkleEmitter.emissionAngle = CGFloat.pi / 2.0
            sparkleEmitter.emissionAngleRange = .pi / 6
            sparkleEmitter.particleZPosition = -45
            sparkleEmitter.position = CGPoint(x: 0, y: -size.height * 0.3)
            sparkleEmitter.xAcceleration = 1
            sparkleEmitter.yAcceleration = 3
            
            if number == 1 {
                particleLayer = sparkleEmitter  // Keep reference to first one
            }
            addChild(sparkleEmitter)
        }
    }

    private func setupDecorativeElements() {
        // Elegant geometric accent shapes
        let decorativeLayer = SKNode()
        decorativeLayer.zPosition = -40
        decorativeLayer.alpha = 0.15
        addChild(decorativeLayer)

        // Large subtle circle in top-right
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

        // Small decorative diamonds
        for i in 0..<3 {
            let diamond = createDiamond(size: CGSize(width: 8, height: 8))
            diamond.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.96, alpha: 0.4)
            diamond.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            let x = CGFloat.random(in: -size.width * 0.4...size.width * 0.4)
            let y = CGFloat.random(in: -size.height * 0.1...size.height * 0.4)
            diamond.position = CGPoint(x: x, y: y)
            decorativeLayer.addChild(diamond)

            // Gentle rotation animation
            let rotate = SKAction.repeatForever(.rotate(byAngle: .pi * 2, duration: 20 + Double(i) * 5))
            diamond.run(rotate)
        }

        // Subtle breathing animation for circles
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

    private func createDiamond(size: CGSize) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -size.height / 2))
        path.addLine(to: CGPoint(x: -size.width / 2, y: 0))
        path.closeSubpath()
        return SKShapeNode(path: path)
    }

    private func createNumberedSquare(size: CGFloat, number: Int) -> SKNode {
        let container = SKNode()
        
        // White square with border
        let square = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 2)
        square.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        square.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        square.lineWidth = 1.0
        container.addChild(square)
        
        // Number label
        let numberLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        numberLabel.text = "\(number)"
        numberLabel.fontSize = size * 0.6
        numberLabel.fontColor = AppColors.primary
        numberLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        numberLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        numberLabel.position = CGPoint.zero
        container.addChild(numberLabel)
        
        return container
    }

    // MARK: - Title
    private func setupTitleStack() {
        // Elegant title with enhanced typography
        titleLabel = SKLabelNode(fontNamed: UIConstants.preferredTitleFont())
        titleLabel.text = "Nurikabe"
        titleLabel.fontSize = max(48, min(64, size.width * 0.085))
        titleLabel.fontColor = AppColors.titleText
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.22)
        titleLabel.alpha = 1
        titleLabel.zPosition = 10

        addChild(titleLabel)

        // Refined subtitle with better styling
        subtitleLabel = SKLabelNode(fontNamed: UIConstants.preferredSubtitleFont())
        subtitleLabel.text = "Logic Islands"
        subtitleLabel.fontSize = max(18, min(26, size.width * 0.035))
        subtitleLabel.fontColor = AppColors.subtitleText
        subtitleLabel.position = CGPoint(x: 0, y: titleLabel.position.y - (titleLabel.fontSize * 0.85))
        subtitleLabel.alpha = 1
        subtitleLabel.zPosition = 9
        addChild(subtitleLabel)

        // Add subtle letter spacing effect (commented out for now)
        // let letterSpacing: CGFloat = 2.0
        // if let attributedText = NSMutableAttributedString(string: subtitleLabel.text ?? "") {
        //     attributedText.addAttribute(.kern, value: letterSpacing, range: NSRange(location: 0, length: attributedText.length))
        // }
    }

    // MARK: - Buttons
    private func setupButtons() {
        let spacing: CGFloat = 72
        playButton = makeButton(
            title: "Play",
            icon: "▶︎",
            width: max(220, min(size.width * 0.7, 320)),
            actionName: "playButton"
        )
        playButton.position = CGPoint(x: 0, y: -spacing * 0.5)
        addChild(playButton)

        settingsButton = makeButton(
            title: "Settings",
            icon: "☰",
            width: max(220, min(size.width * 0.7, 320)),
            actionName: "settingsButton"
        )
        settingsButton.position = CGPoint(x: 0, y: playButton.position.y - spacing)
        addChild(settingsButton)
    }

    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        guard let button = nodeButtonAncestor(node) else { return }

        // Elegant press feedback with bounce
        if let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let press = SKAction.group([
                .scale(to: 0.95, duration: 0.12),
                .fadeAlpha(to: 0.85, duration: 0.12)
            ]).withTimingMode(.easeOut)
            bg.run(press)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        run(.playSoundFileNamed("tap.caf", waitForCompletion: false)) // optional if file exists
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

        if button.name == "playButton" {
            startGame()
        } else if button.name == "settingsButton" {
            showSettings()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // reset visual state if touch cancels
        for b in [playButton, settingsButton].compactMap({ $0 }) {
            b.run(.group([.scale(to: 1.0, duration: 0.1), .fadeAlpha(to: 1.0, duration: 0.1)]))
        }
    }

    // MARK: - Navigation
    private func startGame() {
        // Transition to grid size selection scene
        guard let view = view else { return }
        
        let gridSizeScene = GridSizeScene(size: view.bounds.size)
        gridSizeScene.scaleMode = .aspectFill
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(gridSizeScene, transition: transition)
    }

    private func showSettings() {
        // TODO: replace with real settings scene when ready
        let pop = SKLabelNode(fontNamed: UIConstants.preferredRegularFont())
        pop.text = "Settings coming soon"
        pop.fontSize = 18
        pop.alpha = 0
        pop.zPosition = 999
        addChild(pop)
        pop.run(.sequence([.fadeIn(withDuration: 0.15),
                           .wait(forDuration: 1.0),
                           .fadeOut(withDuration: 0.25),
                           .removeFromParent()]))
        print("Settings button tapped - implement settings scene")
    }

    // MARK: - Helpers (UI)
    private func makeButton(title: String, icon: String, width: CGFloat, actionName: String) -> SKNode {
        // Container
        let container = SKNode()
        container.name = actionName
        container.zPosition = 50

        // Button background
        let height: CGFloat = 64
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 20)
        bg.name = "bg"
        bg.fillColor = AppColors.buttonBackground
        bg.lineWidth = 1.5
        container.addChild(bg)

        // Button icon
        let iconLabel = SKLabelNode(fontNamed: UIConstants.preferredBoldFont())
        iconLabel.text = icon
        iconLabel.fontSize = 22
        iconLabel.fontColor = AppColors.buttonText
        iconLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        iconLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        iconLabel.position = CGPoint(x: -width * 0.34, y: 0)
        iconLabel.zPosition = 4
        container.addChild(iconLabel)

        // Enhanced title text
        let label = SKLabelNode(fontNamed: UIConstants.preferredButtonFont())
        label.text = title
        label.fontSize = 22
        label.fontColor = AppColors.buttonText
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        label.position = CGPoint(x: 8, y: 0)
        label.zPosition = 4
        container.addChild(label)

        return container
    }

    private func nodeButtonAncestor(_ node: SKNode) -> SKNode? {
        if node.name == "playButton" || node.name == "settingsButton" { return node }
        return node.parent.flatMap { nodeButtonAncestor($0) }
    }



    // Commented out due to cgColor compatibility issues
    /*
    private func makeVerticalGradientTexture(size: CGSize, colors: [UIColor]) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            guard let cg = CGColorSpace(name: CGColorSpace.sRGB),
                  let grad = CGGradient(colorsSpace: cg,
                                        colors: colors.map { $0.cgColor } as CFArray,
                                        locations: (0..<colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }) else { return }
            ctx.cgContext.drawLinearGradient(
                grad,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height),
                options: []
            )
        }
        return SKTexture(image: image)
    }
    */
}

// MARK: - Small SKAction convenience
private extension SKAction {
    func withTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
