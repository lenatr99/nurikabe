//
//  LevelSelectScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Level selection scene with simplified structure
class LevelSelectScene: BaseScene {
    
    private var backButton: SKNode!
    private var scrollContainer: SKNode!
    private var cropNode: SKCropNode!
    private var allPuzzles: [Puzzle] = []
    private var currentGridConfig: GameConfig.GridSizeConfig = GameConfig.gridSizes[0]
    private var progressManager: ProgressManager!
    
    // Layout properties
    private let tilesPerRow = 4
    private let tileSize: CGFloat = 80
    private let tileSpacing: CGFloat = 12
    
    // Scroll properties
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var minScrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false
    private var scrollVelocity: CGFloat = 0
    
    override func setupScene() {
        progressManager = ProgressManager(config: currentGridConfig)
        loadPuzzleData()
        setupBackButton()
        setupLevelGrid()
    }
    
    func setGridSize(filename: String) {
        if let config = GameConfig.getConfig(for: filename) {
            currentGridConfig = config
            progressManager = ProgressManager(config: config)
        }
    }
    
    private func loadPuzzleData() {
        allPuzzles = PuzzleLoader.loadPuzzles(from: currentGridConfig.filename)
    }
    
    private func setupBackButton() {
        backButton = createBackButton()
        backButton.position = CGPoint(x: 0, y: -size.height * 0.4)
        backButton.zPosition = 100  // Ensure it's above the scroll container
        addChild(backButton)
    }
    
    private func setupLevelGrid() {
        let availableHeight = size.height * 0.6
        
        // Create crop node for clipping
        cropNode = SKCropNode()
        cropNode.zPosition = 50
        addChild(cropNode)
        
        let maskNode = SKShapeNode(rectOf: CGSize(width: size.width, height: availableHeight))
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        maskNode.position = CGPoint(x: 0, y: 0)
        cropNode.maskNode = maskNode
        
        scrollContainer = SKNode()
        cropNode.addChild(scrollContainer)
        
        setupLevelTiles(availableHeight: availableHeight)
        updateScrollPosition()
    }
    
    private func setupLevelTiles(availableHeight: CGFloat) {
        let solvedPuzzles = progressManager.getSolvedPuzzles()
        let highestUnlocked = progressManager.getHighestUnlockedLevel(totalPuzzles: allPuzzles.count)
        
        let rows = (allPuzzles.count + tilesPerRow - 1) / tilesPerRow
        let totalHeight = CGFloat(rows) * (tileSize + tileSpacing) - tileSpacing
        
        maxScrollOffset = max(0, totalHeight - availableHeight)
        scrollOffset = 0
        
        for (index, _) in allPuzzles.enumerated() {
            let row = index / tilesPerRow
            let col = index % tilesPerRow
            
            let totalTileWidth = CGFloat(tilesPerRow) * tileSize + CGFloat(tilesPerRow - 1) * tileSpacing
            let startX = -totalTileWidth / 2
            
            let x = startX + CGFloat(col) * (tileSize + tileSpacing) + tileSize / 2
            let topY = availableHeight * 0.5 - tileSize / 2
            let y = topY - CGFloat(row) * (tileSize + tileSpacing)
            
            let tile = createLevelTile(
                levelIndex: index,
                isSolved: solvedPuzzles.contains(index),
                isUnlocked: index <= highestUnlocked,
                position: CGPoint(x: x, y: y)
            )
            
            scrollContainer.addChild(tile)
        }
    }
    
    private func createLevelTile(levelIndex: Int, isSolved: Bool, isUnlocked: Bool, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.name = "levelTile_\(levelIndex)"
        container.position = position
        container.zPosition = 1
        
        // Tile background
        let tile = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize), cornerRadius: 12)
        tile.name = "tileBg"
        
        if isUnlocked {
            tile.fillColor = UIColor.white
            tile.strokeColor = AppColors.primary
            tile.lineWidth = 2.0
        } else {
            tile.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
            tile.strokeColor = AppColors.primary
            tile.lineWidth = 2.0
        }
        
        container.addChild(tile)
        
        // Level number
        let numberLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        numberLabel.text = "\(levelIndex + 1)"
        numberLabel.fontSize = 24
        numberLabel.fontColor = AppColors.primary
        numberLabel.verticalAlignmentMode = .center
        numberLabel.horizontalAlignmentMode = .center
        numberLabel.zPosition = 1
        container.addChild(numberLabel)
        
        // Solved indicator
        if isSolved {
            let checkmark = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            checkmark.text = "✓"
            checkmark.fontSize = 14
            checkmark.fontColor = AppColors.primary
            checkmark.position = CGPoint(x: tileSize/2 - 15, y: -tileSize/2 + 10)
            checkmark.zPosition = 2
            container.addChild(checkmark)
        }
        
        // Lock indicator
        if !isUnlocked {
            let lockIcon = LockIcon.create(size: 12)
            lockIcon.position = CGPoint(x: tileSize/2 - 15, y: -tileSize/2 + 15)
            lockIcon.zPosition = 2
            container.addChild(lockIcon)
        }
        
        return container
    }
    
    private func updateScrollPosition() {
        scrollOffset = max(minScrollOffset, min(maxScrollOffset, scrollOffset))
        scrollContainer.position.y = scrollOffset
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        handleButtonTouch(touch: touch, buttonNames: ["backButton"], onPress: { button in
            GameButton.animatePress(button)
        })
        
        lastTouchY = location.y
        isDragging = false
        scrollVelocity = 0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let deltaY = location.y - lastTouchY
        
        if abs(deltaY) > 3 {
            isDragging = true
        }
        
        if isDragging {
            scrollOffset += deltaY
            updateScrollPosition()
            scrollVelocity = deltaY * 0.8
        }
        
        lastTouchY = location.y
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        handleButtonTouch(touch: touch, buttonNames: ["backButton"], onRelease: { button, buttonName in
            if buttonName == "backButton" {
                GameButton.animateRelease(button) {
                    self.returnToGridSizeScene()
                }
            }
        })
        
        if isDragging {
            applyMomentumScrolling()
            isDragging = false
            return
        }
        
        // Handle level tile taps
        handleLevelTileTap(touch: touch)
    }
    
    private func applyMomentumScrolling() {
        if abs(scrollVelocity) > 1 {
            let momentum = scrollVelocity * 15
            let targetOffset = scrollOffset + momentum
            let clampedTarget = max(minScrollOffset, min(maxScrollOffset, targetOffset))
            
            let duration = min(0.8, abs(momentum) / 200)
            let moveAction = SKAction.customAction(withDuration: duration) { _, elapsedTime in
                let progress = elapsedTime / duration
                let easedProgress = 1 - pow(1 - progress, 3)
                let currentOffset = self.scrollOffset + (clampedTarget - self.scrollOffset) * easedProgress
                
                self.scrollOffset = currentOffset
                self.updateScrollPosition()
            }
            
            run(moveAction)
        }
    }
    
    private func handleLevelTileTap(touch: UITouch) {
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        var levelIndex = -1
        
        if let nodeName = touchedNode.name, nodeName.hasPrefix("levelTile_") {
            levelIndex = Int(String(nodeName.dropFirst("levelTile_".count))) ?? -1
        } else if let parentName = touchedNode.parent?.name, parentName.hasPrefix("levelTile_") {
            levelIndex = Int(String(parentName.dropFirst("levelTile_".count))) ?? -1
        }
        
        guard levelIndex >= 0 && levelIndex < allPuzzles.count else { return }
        
        let highestUnlocked = progressManager.getHighestUnlockedLevel(totalPuzzles: allPuzzles.count)
        
        if levelIndex <= highestUnlocked {
            startGame(levelIndex: levelIndex)
        } else {
            NSLog("🔒 Level \(levelIndex + 1) is locked")
        }
    }
    
    // MARK: - Navigation
    
    private func startGame(levelIndex: Int) {
        guard let view = view else { return }
        
        let gameScene = GameScene(size: view.bounds.size)
        gameScene.scaleMode = .aspectFill
        gameScene.setGridFilename(currentGridConfig.filename)
        gameScene.setStartingPuzzleIndex(levelIndex)
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(gameScene, transition: transition)
    }
    
    private func returnToGridSizeScene() {
        guard let view = view else { return }
        
        let gridSizeScene = GridSizeScene(size: view.bounds.size)
        gridSizeScene.scaleMode = .aspectFill
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(gridSizeScene, transition: transition)
    }
}
