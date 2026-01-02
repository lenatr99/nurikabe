//
//  LevelSelectScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Level selection scene with paginated grid view
class LevelSelectScene: BaseScene {
    
    private var backButton: SKNode!
    private var paginatedGridView: PaginatedGridView!
    private var allPuzzles: [Puzzle] = []
    private var currentGridConfig: GameConfig.GridSizeConfig = GameConfig.gridSizes[0]
    private var progressManager: ProgressManager!
    
    override func setupScene() {
        progressManager = ProgressManager(config: currentGridConfig)
        loadPuzzleData()
        setupBackButton()
        setupPaginatedGrid()
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
    
    private func setupPaginatedGrid() {
        // Configure the paginated grid view
        let config = PaginatedGridView.Configuration(
            itemsPerPage: 20, // 4x5 grid
            itemSize: CGSize(width: 80, height: 80),
            itemSpacing: 8,
            pageSpacing: 0, // No extra spacing between pages
            showArrows: true,
            animationDuration: 0.3
        )
        
        paginatedGridView = PaginatedGridView(configuration: config)
        paginatedGridView.setViewSize(size)
        paginatedGridView.position = CGPoint(x: 0, y: 0)
        paginatedGridView.zPosition = 10  // Lower than back button (100) but sufficient for level tiles
        addChild(paginatedGridView)
        
        // Set up callbacks
        paginatedGridView.onItemTapped = { [weak self] levelIndex in
            self?.handleLevelTileTap(levelIndex: levelIndex)
        }
        
        paginatedGridView.onPageChanged = { pageIndex in
            NSLog("📄 Switched to page \(pageIndex + 1)")
        }
        
        // Load puzzle data into the grid
        loadPuzzlesIntoGrid()
    }
    
    private func loadPuzzlesIntoGrid() {
        let solvedPuzzles = progressManager.getSolvedPuzzles()
        let highestUnlocked = progressManager.getHighestUnlockedLevel(totalPuzzles: allPuzzles.count)
        
        // Create puzzle data with solve/unlock status
        struct PuzzleData {
            let puzzle: Puzzle
            let index: Int
            let isSolved: Bool
            let isUnlocked: Bool
        }
        
        let puzzleData = allPuzzles.enumerated().map { index, puzzle in
            PuzzleData(
                puzzle: puzzle,
                index: index,
                isSolved: solvedPuzzles.contains(index),
                isUnlocked: index <= highestUnlocked
            )
        }
        
        // Load into paginated grid view
        paginatedGridView.loadItems(puzzleData) { [weak self] data, index, position in
            return self?.createLevelTile(
                levelIndex: data.index,
                isSolved: data.isSolved,
                isUnlocked: data.isUnlocked,
                position: position
            ) ?? SKNode()
        }
        
        // Navigate to the page containing the highest unlocked level
        let itemsPerPage = paginatedGridView.configuration.itemsPerPage
        let targetPage = highestUnlocked / itemsPerPage
        paginatedGridView.setCurrentPage(targetPage, animated: false)
    }
    
    private func createLevelTile(levelIndex: Int, isSolved: Bool, isUnlocked: Bool, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.name = "levelTile_\(levelIndex)"
        container.position = position
        container.zPosition = 1  // Relative to paginated grid container
        
        let tileSize: CGFloat = 80
        
        // Tile background - this is the main touch target
        let tile = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize), cornerRadius: 12)
        tile.name = "tileBg"
        tile.zPosition = 0  // Base layer
        
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
        
        // Level number - positioned above background but should not interfere with touch
        let numberLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        numberLabel.text = "\(levelIndex + 1)"
        numberLabel.fontSize = 24
        numberLabel.fontColor = AppColors.primary
        numberLabel.verticalAlignmentMode = .center
        numberLabel.horizontalAlignmentMode = .center
        numberLabel.zPosition = 1
        // Disable user interaction for text so it doesn't interfere with touch
        numberLabel.isUserInteractionEnabled = false
        container.addChild(numberLabel)
        
        // Solved indicator
        if isSolved {
            let checkmark = SKShapeNode(circleOfRadius: 6)
            checkmark.fillColor = AppColors.primary
            checkmark.position = CGPoint(x: 25, y: -25)
            checkmark.zPosition = 2
            checkmark.isUserInteractionEnabled = false
            container.addChild(checkmark)
        }
        
        // Lock indicator
        if !isUnlocked {
            let lockIcon = LockIcon.create(size: 12)
            lockIcon.position = CGPoint(x: 25, y: -25)
            lockIcon.zPosition = 2
            lockIcon.isUserInteractionEnabled = false
            container.addChild(lockIcon)
        }
        
        return container
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        handleButtonTouch(touch: touch, buttonNames: ["backButton"], onPress: { button in
            GameButton.animatePress(button)
        })
        
        // Pass touch to paginated grid view
        paginatedGridView.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Pass touch to paginated grid view
        paginatedGridView.touchesMoved(touches, with: event)
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
        
        // Pass touch to paginated grid view
        paginatedGridView.touchesEnded(touches, with: event)
    }
    
    private func handleLevelTileTap(levelIndex: Int) {
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
