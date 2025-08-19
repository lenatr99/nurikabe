//
//  GameScene.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Main game scene with simplified, modular structure
class GameScene: BaseScene {
    
    // MARK: - Components
    private var gameGrid: GameGrid!
    private var progressManager: ProgressManager!
    private var allPuzzles: [Puzzle] = []
    private var currentPuzzle: Puzzle!
    private var currentPuzzleIndex = 0
    private var currentGridConfig: GameConfig.GridSizeConfig = GameConfig.gridSizes[0]
    
    // MARK: - UI Elements
    private var titleLabel: SKLabelNode!
    private var backButton: SKNode!
    private var submitButton: SKNode!
    private var clearButton: SKNode!
    private var gridContainer: SKNode!
    
    // MARK: - Game State
    private var cellSize: CGFloat = 0
    private var isSubmitEnabled = true
    private var isNavigatingFromNext = false
    
    // MARK: - Drag State
    private var isDragging = false
    private var dragFillState: CellState = .empty
    private var lastDraggedCell: (row: Int, col: Int)? = nil
    
    override func setupScene() {
        progressManager = ProgressManager(config: currentGridConfig)
        loadPuzzleData()
        setupUI()
        setupGrid()
        loadInitialProgress()
    }
    
    // MARK: - Public Methods
    
    func setStartingPuzzleIndex(_ index: Int) {
        currentPuzzleIndex = index
        NSLog("🎯 GameScene initialized with puzzle index: \(index)")
    }
    
    func setGridFilename(_ filename: String) {
        currentGridConfig = GameConfig.getConfig(for: filename) ?? GameConfig.gridSizes[0]
        progressManager = ProgressManager(config: currentGridConfig)
        NSLog("🎯 GameScene will load data from: \(filename)")
    }
    
    // MARK: - Setup Methods
    
    private func loadPuzzleData() {
        allPuzzles = PuzzleLoader.loadPuzzles(from: currentGridConfig.filename)
        guard currentPuzzleIndex < allPuzzles.count else {
            NSLog("❌ Invalid puzzle index")
            return
        }
        currentPuzzle = allPuzzles[currentPuzzleIndex]
    }
    
    private func setupUI() {
        setupTitle()
        setupButtons()
    }
    
    private func setupTitle() {
        titleLabel = createTitle("Nurikabe")
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.4)
        addChild(titleLabel)
    }
    
    private func setupButtons() {
        // Back button
        backButton = createBackButton()
        backButton.position = CGPoint(x: -130, y: -size.height * 0.4)
        backButton.zPosition = 100  // Ensure it's above the grid
        addChild(backButton)
        
        // Submit button
        updateSubmitButton()
        
        // Clear button
        clearButton = GameButton.create(
            title: "Clear",
            style: GameButton.Style(
                width: 45, height: 35, cornerRadius: 12,
                backgroundColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.2),
                strokeColor: UIColor.clear, lineWidth: 0,
                textColor: UIColor.white, fontSize: 15,
                fontName: "HelveticaNeue-Medium"
            ),
            actionName: "clearButton"
        )
        
        let gridSize = min(size.width * 0.8, size.height * 0.6)
        clearButton.position = CGPoint(
            x: (gridSize - 45)/2,
            y: -(gridSize + 35)/2 - 10
        )
        clearButton.zPosition = 100  // Ensure it's above the grid
        addChild(clearButton)
    }
    
    private func setupGrid() {
        gridContainer = SKNode()
        gridContainer.zPosition = 50
        addChild(gridContainer)
        
        gameGrid = GameGrid(size: currentPuzzle.gridSize)
        gameGrid.setupPuzzle(currentPuzzle)
        
        rebuildGrid()
    }
    
    private func rebuildGrid() {
        gridContainer.removeAllChildren()
        
        let maxGridSize = min(size.width * 0.8, size.height * 0.6)
        cellSize = maxGridSize / CGFloat(currentPuzzle.gridSize)
        
        for row in 0..<currentPuzzle.gridSize {
            for col in 0..<currentPuzzle.gridSize {
                let cell = gameGrid.getCell(row: row, col: col)!
                let cellNode = GridRenderer.createCell(
                    for: cell,
                    cellSize: cellSize,
                    gridSize: currentPuzzle.gridSize,
                    puzzle: currentPuzzle
                )
                gridContainer.addChild(cellNode)
            }
        }
    }
    
    private func loadInitialProgress() {
        DispatchQueue.main.async {
            let hasProgress = self.progressManager.loadPuzzleProgress(self.gameGrid, puzzleIndex: self.currentPuzzleIndex)
            if hasProgress {
                self.updateGridVisuals()
            }
            
            if self.progressManager.isPuzzleSolved(self.currentPuzzleIndex) {
                self.isSubmitEnabled = false
                self.updateSubmitButton()
                self.clearButton.isHidden = true
            }
        }
    }
    
    private func updateGridVisuals() {
        for row in 0..<currentPuzzle.gridSize {
            for col in 0..<currentPuzzle.gridSize {
                if let cell = gameGrid.getCell(row: row, col: col) {
                    GridRenderer.updateCellVisual(cell, cellSize: cellSize)
                }
            }
        }
    }
    
    private func updateSubmitButton() {
        submitButton?.removeFromParent()
        
        let isSolvedOverlayShowing = childNode(withName: "solvedOverlay") != nil
        
        if isSolvedOverlayShowing && currentPuzzleIndex < allPuzzles.count - 1 {
            submitButton = createNextButton()
        } else if !isSolvedOverlayShowing {
            submitButton = createSubmitButton()
        }
        
        if let submitButton = submitButton {
            submitButton.position = CGPoint(x: 130, y: -size.height * 0.4)
            submitButton.zPosition = 100  // Ensure it's above the grid
            addChild(submitButton)
        }
    }
    
    private func createSubmitButton() -> SKNode {
        return GameButton.create(
            title: "Submit",
            actionName: "submitButton"
        )
    }
    
    private func createNextButton() -> SKNode {
        return GameButton.create(
            title: "Next",
            actionName: "nextButton"
        )
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle button touches
        let buttonNames = ["backButton", "submitButton", "nextButton", "clearButton"]
        handleButtonTouch(touch: touch, buttonNames: buttonNames, onPress: { button in
            GameButton.animatePress(button)
        })
        
        // Handle grid cell taps
        handleCellTouch(touch: touch, location: location, touchedNode: touchedNode)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        if let cellCoordinates = TouchUtils.getGridCoordinates(
            location: location,
            gridContainer: gridContainer,
            gridSize: currentPuzzle.gridSize,
            cellSize: cellSize
        ) {
            
            if let lastCell = lastDraggedCell,
               lastCell.row == cellCoordinates.row && lastCell.col == cellCoordinates.col {
                return
            }
            
            if let cell = gameGrid.getCell(row: cellCoordinates.row, col: cellCoordinates.col),
               !cell.isClue {
                cell.state = dragFillState
                GridRenderer.updateCellVisual(cell, cellSize: cellSize)
                progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
                lastDraggedCell = cellCoordinates
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastDraggedCell = nil
        
        guard let touch = touches.first else { return }
        
        let buttonNames = ["backButton", "submitButton", "nextButton", "clearButton"]
        handleButtonTouch(touch: touch, buttonNames: buttonNames, onRelease: { button, buttonName in
            GameButton.animateRelease(button) {
                self.handleButtonAction(buttonName)
            }
        })
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastDraggedCell = nil
    }
    
    // MARK: - Game Logic
    
    private func handleCellTouch(touch: UITouch, location: CGPoint, touchedNode: SKNode) {
        var cellCoordinates: (row: Int, col: Int)?
        
        if let nodeName = touchedNode.name, nodeName.hasPrefix("cell_") {
            cellCoordinates = TouchUtils.getCellCoordinates(from: nodeName)
        } else if touchedNode.name == "dot", let parentName = touchedNode.parent?.name {
            cellCoordinates = TouchUtils.getCellCoordinates(from: parentName)
        }
        
        guard let coordinates = cellCoordinates,
              let cell = gameGrid.getCell(row: coordinates.row, col: coordinates.col),
              !cell.isClue else { return }
        
        let newState = getNextCellState(from: cell.state)
        cell.state = newState
        GridRenderer.updateCellVisual(cell, cellSize: cellSize)
        progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
        
        // Setup drag state
        isDragging = true
        dragFillState = newState
        lastDraggedCell = coordinates
    }
    
    private func getNextCellState(from currentState: CellState) -> CellState {
        switch currentState {
        case .empty: return .filled
        case .filled: return .dot
        case .dot: return .empty
        case .blocked: return .empty
        }
    }
    
    private func handleButtonAction(_ buttonName: String) {
        switch buttonName {
        case "backButton":
            returnToLevelSelect()
        case "submitButton":
            handleSubmit()
        case "nextButton":
            loadNextPuzzle()
        case "clearButton":
            clearPuzzle()
        default:
            break
        }
    }
    
    private func handleSubmit() {
        if SolutionChecker.checkSolution(grid: gameGrid, puzzle: currentPuzzle) {
            progressManager.markPuzzleAsSolved(currentPuzzleIndex)
            isSubmitEnabled = false
            clearButton.isHidden = true
            showSolvedMessage()
            updateSubmitButton()
        } else {
            showNotSolvedMessage()
        }
    }
    
    private func clearPuzzle() {
        gameGrid.resetAllNonClueCells()
        updateGridVisuals()
        progressManager.clearPuzzleProgress(currentPuzzleIndex)
    }
    
    private func loadNextPuzzle() {
        // Remove solved overlay
        childNode(withName: "solvedOverlay")?.removeFromParent()
        clearButton.isHidden = false
        
        currentPuzzleIndex = (currentPuzzleIndex + 1) % allPuzzles.count
        currentPuzzle = allPuzzles[currentPuzzleIndex]
        
        isNavigatingFromNext = true
        gameGrid.setupPuzzle(currentPuzzle)
        rebuildGrid()
        
        if progressManager.isPuzzleSolved(currentPuzzleIndex) {
            isSubmitEnabled = false
            clearButton.isHidden = true
        } else {
            isSubmitEnabled = true
            _ = progressManager.loadPuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
            updateGridVisuals()
        }
        
        updateSubmitButton()
    }
    
    // MARK: - UI Feedback
    
    private func showSolvedMessage() {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: min(size.width * 0.8, size.height * 0.6)))
        overlay.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        overlay.strokeColor = AppColors.primary
        overlay.lineWidth = 3.0
        overlay.position = CGPoint.zero
        overlay.zPosition = 200
        overlay.alpha = 0
        overlay.name = "solvedOverlay"
        
        let solvedLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        solvedLabel.text = "SOLVED"
        solvedLabel.fontSize = 48
        solvedLabel.fontColor = AppColors.primary
        solvedLabel.verticalAlignmentMode = .center
        solvedLabel.horizontalAlignmentMode = .center
        solvedLabel.position = CGPoint(x: 0, y: 15)
        solvedLabel.zPosition = 1
        
        let congratsLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        congratsLabel.text = "Congratulations!"
        congratsLabel.fontSize = 24
        congratsLabel.fontColor = UIColor.white
        congratsLabel.verticalAlignmentMode = .center
        congratsLabel.horizontalAlignmentMode = .center
        congratsLabel.position = CGPoint(x: 0, y: -20)
        congratsLabel.zPosition = 1
        
        overlay.addChild(solvedLabel)
        overlay.addChild(congratsLabel)
        addChild(overlay)
        
        overlay.run(.fadeIn(withDuration: 0.5))
        updateSubmitButton()
    }
    
    private func showNotSolvedMessage() {
        let messageLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        messageLabel.text = "Not quite right... Keep trying!"
        messageLabel.fontSize = 24
        messageLabel.fontColor = UIColor.white
        messageLabel.position = CGPoint(x: 0, y: size.height * 0.3)
        messageLabel.zPosition = 150
        messageLabel.alpha = 0
        addChild(messageLabel)
        
        messageLabel.run(.sequence([
            .fadeIn(withDuration: 0.3),
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }
    
    // MARK: - Navigation
    
    private func returnToLevelSelect() {
        guard let view = view else { return }
        
        let levelSelectScene = LevelSelectScene(size: view.bounds.size)
        levelSelectScene.scaleMode = .aspectFill
        levelSelectScene.setGridSize(filename: currentGridConfig.filename)
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(levelSelectScene, transition: transition)
    }
}
