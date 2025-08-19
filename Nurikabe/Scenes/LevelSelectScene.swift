//
//  LevelSelectScene.swift
//  Nurikabe
//
//  Created by AI Assistant on 8/15/25.
//

import SpriteKit
import GameplayKit

class LevelSelectScene: SKScene {
    
    // MARK: - Properties
    private var backButton: SKNode!
    private var scrollContainer: SKNode!
    private var cropNode: SKCropNode!
    private var allPuzzles: [[String: Any]] = []
    private var currentGridConfig: GameConfig.GridSizeConfig = GameConfig.gridSizes[0]
    
    // Layout properties
    private let tilesPerRow = 4
    private let tileSize: CGFloat = 80
    private let tileSpacing: CGFloat = 12
    private let topMargin: CGFloat = 120
    private let sideMargin: CGFloat = 40
    
    // Scroll properties
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var minScrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false
    private var scrollVelocity: CGFloat = 0
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = AppColors.background
        
        loadPuzzleData()
        setupBackButton()
        setupLevelGrid()
    }
    
    // MARK: - Public Methods
    func setGridSize(filename: String) {
        if let config = GameConfig.getConfig(for: filename) {
            currentGridConfig = config
        }
    }
    
    private func loadPuzzleData() {
        guard let path = Bundle.main.path(forResource: currentGridConfig.filename, ofType: "json") else {
            NSLog("❌ ERROR: json file not found in bundle: \(currentGridConfig.filename).json")
            return
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            NSLog("❌ ERROR: Could not read json file")
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            NSLog("❌ ERROR: Invalid JSON format in json")
            return
        }
        
        guard let items = json["items"] as? [[String: Any]] else {
            NSLog("❌ ERROR: No 'items' array found in JSON")
            return
        }
        
        allPuzzles = items
        NSLog("✅ Loaded %d puzzles for level select", allPuzzles.count)
    }
    
    private func setupBackButton() {
        backButton = ButtonFactory.createButton(
            title: "Back",
            width: 120,
            height: 45,
            actionName: "backButton"
        )
        backButton.position = CGPoint(x: 0, y: -size.height * 0.4)
        addChild(backButton)
    }
    
    private func setupLevelGrid() {
        
        let availableHeight = size.height * 0.6
        
        // Create a crop node for clipping overflow
        cropNode = SKCropNode()
        cropNode.zPosition = 50
        addChild(cropNode)
        
        // Create a mask for the scroll area
        let maskNode = SKShapeNode(rectOf: CGSize(width: size.width, height: availableHeight))
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        maskNode.position = CGPoint(x: 0, y: 0)
        cropNode.maskNode = maskNode
        
        // Create the scroll container inside the crop node
        scrollContainer = SKNode()
        cropNode.addChild(scrollContainer)
        
        let solvedPuzzles = getSolvedPuzzles()
        let highestUnlocked = getHighestUnlockedLevel(solvedPuzzles: solvedPuzzles)
        
        let rows = (allPuzzles.count + tilesPerRow - 1) / tilesPerRow
        let totalHeight = CGFloat(rows) * (tileSize + tileSpacing) - tileSpacing
        NSLog("totalHeight: \(totalHeight)")
        
        // Calculate scroll limits (inverted for natural scrolling)
        minScrollOffset = 0
        maxScrollOffset = max(0, totalHeight - availableHeight)
        NSLog("minScrollOffset: \(minScrollOffset)")
        NSLog("maxScrollOffset: \(maxScrollOffset)")
        
        // Start at the top (show levels 1-16 first)
        scrollOffset = 0
        
        // Position tiles from top to bottom
        for (index, _) in allPuzzles.enumerated() {
            let row = index / tilesPerRow
            let col = index % tilesPerRow
            
            // Calculate available width for tiles (screen width minus side margins)
            let availableWidth = size.width - (sideMargin * 2)
            let totalTileWidth = CGFloat(tilesPerRow) * tileSize + CGFloat(tilesPerRow - 1) * tileSpacing
            let startX = -totalTileWidth / 2
            
            let x = startX + CGFloat(col) * (tileSize + tileSpacing) + tileSize / 2
            // Position tiles starting from the top of available area
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
        
        // Apply initial scroll position
        updateScrollPosition()
    }
    
    private func createLevelTile(levelIndex: Int, isSolved: Bool, isUnlocked: Bool, position: CGPoint) -> SKNode {
        return ButtonFactory.createLevelTile(
            levelIndex: levelIndex,
            isSolved: isSolved,
            isUnlocked: isUnlocked,
            position: position,
            tileSize: tileSize
        )
    }
    

    
    private func updateScrollPosition() {
        // Clamp scroll offset to valid range
        scrollOffset = max(minScrollOffset, min(maxScrollOffset, scrollOffset))
        NSLog("scrollOffset: \(scrollOffset)")
        
        // Apply the scroll offset to the container
        scrollContainer.position.y = scrollOffset
    }
    
    private func getSolvedPuzzles() -> Set<Int> {
        let solved = UserDefaults.standard.array(forKey: currentGridConfig.solvedPuzzlesKey) as? [Int] ?? []
        return Set(solved)
    }
    
    private func getHighestUnlockedLevel(solvedPuzzles: Set<Int>) -> Int {
        // Level 0 is always unlocked
        // Each subsequent level is unlocked only if the previous level is solved
        for level in 0..<allPuzzles.count {
            if level == 0 {
                continue // First level always unlocked
            }
            if !solvedPuzzles.contains(level - 1) {
                return level - 1 // Previous level not solved, so this is the highest unlocked
            }
        }
        return allPuzzles.count - 1 // All levels unlocked
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle back button
        if let nodeName = touchedNode.name {
            if nodeName.contains("back") || touchedNode.parent?.name == "backButton" {
                NSLog("🏠 Back button touched!")
                if let bg = backButton.childNode(withName: "bg") as? SKShapeNode {
                    let press = SKAction.group([
                        .scale(to: 0.95, duration: 0.12),
                        .fadeAlpha(to: 0.85, duration: 0.12)
                    ])
                    bg.run(press)
                }
                return
            }
        }
        
        // Start tracking for scroll or tile tap
        lastTouchY = location.y
        isDragging = false
        scrollVelocity = 0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let deltaY = location.y - lastTouchY
        
        // If we've moved enough, start dragging
        if abs(deltaY) > 3 {
            isDragging = true
        }
        
        if isDragging {
            // Update scroll offset for natural scrolling
            scrollOffset += deltaY
            updateScrollPosition()
            
            // Track velocity for momentum (smoother tracking)
            scrollVelocity = deltaY * 0.8
        }
        
        lastTouchY = location.y
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle back button release
        if let nodeName = touchedNode.name {
            if nodeName.contains("back") || touchedNode.parent?.name == "backButton" {
                NSLog("🏠 Back button released!")
                if let bg = backButton.childNode(withName: "bg") as? SKShapeNode {
                    let release = SKAction.group([
                        .scale(to: 1.0, duration: 0.15),
                        .fadeAlpha(to: 1.0, duration: 0.15)
                    ])
                    bg.run(release) {
                        self.returnToGridSizeScene()
                    }
                } else {
                    returnToGridSizeScene()
                }
                return
            }
        }
        
        // If we were dragging, apply momentum and don't handle tile taps
        if isDragging {
            // Apply momentum scrolling with smooth deceleration
            if abs(scrollVelocity) > 1 {
                let momentum = scrollVelocity * 15
                let targetOffset = scrollOffset + momentum
                let clampedTarget = max(minScrollOffset, min(maxScrollOffset, targetOffset))
                
                // Smooth momentum animation
                let duration = min(0.8, abs(momentum) / 200)
                let moveAction = SKAction.customAction(withDuration: duration) { _, elapsedTime in
                    let progress = elapsedTime / duration
                    let easedProgress = 1 - pow(1 - progress, 3) // Ease out cubic
                    let currentOffset = self.scrollOffset + (clampedTarget - self.scrollOffset) * easedProgress
                    
                    self.scrollOffset = currentOffset
                    self.updateScrollPosition()
                }
                
                run(moveAction)
            }
            
            isDragging = false
            return
        }
        
        // Handle level tile taps (only if we weren't dragging)
        if let nodeName = touchedNode.name {
            if nodeName.hasPrefix("levelTile_") {
                let levelIndex = Int(String(nodeName.dropFirst("levelTile_".count))) ?? -1
                handleLevelTileTap(levelIndex: levelIndex, touchedNode: touchedNode)
            } else if let parentName = touchedNode.parent?.name, parentName.hasPrefix("levelTile_") {
                let levelIndex = Int(String(parentName.dropFirst("levelTile_".count))) ?? -1
                handleLevelTileTap(levelIndex: levelIndex, touchedNode: touchedNode.parent!)
            }
        }
    }
    
    private func handleLevelTileTap(levelIndex: Int, touchedNode: SKNode) {
        guard levelIndex >= 0 && levelIndex < allPuzzles.count else { return }
        
        let solvedPuzzles = getSolvedPuzzles()
        let highestUnlocked = getHighestUnlockedLevel(solvedPuzzles: solvedPuzzles)
        
        if levelIndex <= highestUnlocked {
            NSLog("🎯 Level \(levelIndex + 1) tapped - starting game")
            
            // Animate tile press
            if let bg = touchedNode.childNode(withName: "tileBg") as? SKShapeNode {
                let press = SKAction.sequence([
                    .group([
                        .scale(to: 0.9, duration: 0.1),
                        .fadeAlpha(to: 0.8, duration: 0.1)
                    ]),
                    .group([
                        .scale(to: 1.0, duration: 0.1),
                        .fadeAlpha(to: 1.0, duration: 0.1)
                    ])
                ])
                bg.run(press) {
                    self.startGame(levelIndex: levelIndex)
                }
            } else {
                startGame(levelIndex: levelIndex)
            }
        } else {
            NSLog("🔒 Level \(levelIndex + 1) is locked")
            // Could add a shake animation or sound here
        }
    }
    
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
