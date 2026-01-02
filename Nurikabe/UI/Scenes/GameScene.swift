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
    private var commandManager: CommandManager!
    private var allPuzzles: [Puzzle] = []
    private var currentPuzzle: Puzzle!
    private var currentPuzzleIndex = 0
    private var currentGridConfig: GameConfig.GridSizeConfig = GameConfig.gridSizes[0]
    
    // MARK: - UI Elements
    private var titleLabel: SKLabelNode!
    private var backButton: SKNode!
    private var submitButton: SKNode!
    private var gameToolbar: SKNode!
    private var gridContainer: SKNode!
    
    // MARK: - Game State
    private var cellSize: CGFloat = 0
    private var isSubmitEnabled = true
    private var isNavigatingFromNext = false
    private var pendingHint: HintProvider.Hint?
    
    // MARK: - Drag State
    private var isDragging = false
    private var dragFillState: CellState = .empty
    private var lastDraggedCell: (row: Int, col: Int)? = nil
    private var currentBatchCommand: BatchCellCommand?
    
    override func setupScene() {
        progressManager = ProgressManager(config: currentGridConfig)
        commandManager = CommandManager()
        setupCommandManagerCallbacks()
        loadPuzzleData()
        setupTitle()
        setupGrid()
        setupButtons()
        setupToolbar()
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
    
    private func setupCommandManagerCallbacks() {
        commandManager.onHistoryChanged = { [weak self] in
            self?.updateToolbarButtons()
        }
    }
    
    private func loadPuzzleData() {
        allPuzzles = PuzzleLoader.loadPuzzles(from: currentGridConfig.filename)
        guard currentPuzzleIndex < allPuzzles.count else {
            NSLog("❌ Invalid puzzle index")
            return
        }
        currentPuzzle = allPuzzles[currentPuzzleIndex]
    }
    
    private func setupTitle() {
        titleLabel = createTitle("Nurikabe")
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.4)
        addChild(titleLabel)
    }
    
    private func setupButtons() {
        // Back button
        backButton = createBackButton()
        backButton.position = CGPoint(x: -(CGFloat(currentPuzzle.gridSize) * cellSize - GameButton.Style.small.width)/2, y: -size.height * 0.4)
        backButton.zPosition = 100  // Ensure it's above the grid
        addChild(backButton)
        
        // Submit button
        updateSubmitButton()
    }
    
    private func setupToolbar() {
        let gridSize = min(size.width * 0.9, size.height * 0.7)
        
        // Create toolbar with proper width matching the grid
        let toolbarStyle = GameToolbar.Style(
            width: gridSize,
            backgroundColor: UIColor.white
        )
        
        let actions = [
            ToolbarAction.undo,
            ToolbarAction.redo,
            ToolbarAction.clear,
            ToolbarAction.flood,
            ToolbarAction.hint,
        ]
        
        gameToolbar = GameToolbar.create(style: toolbarStyle, actions: actions)
        gameToolbar.position = CGPoint(x: 0, y: gridSize/2 + 30) // Above the grid
        gameToolbar.zPosition = 100
        addChild(gameToolbar)
        
        // Initial state update
        updateToolbarButtons()
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
        
        let maxGridSize = min(size.width * 0.9, size.height * 0.7)
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
                self.updateToolbarButtons() // keep visible but disabled
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
            submitButton.position = CGPoint(x: (CGFloat(currentPuzzle.gridSize) * cellSize - GameButton.Style.small.width)/2, y: -size.height * 0.4)
            submitButton.zPosition = 100  // Ensure it's above the grid
            addChild(submitButton)
        }
    }
    
    private func createSubmitButton() -> SKNode {
        return GameButton.create(
            title: "Submit",
            style: .small,
            actionName: "submitButton",
        )
    }
    
    private func createNextButton() -> SKNode {
        return GameButton.create(
            title: "Next",
            style: .small,
            actionName: "nextButton",
        )
    }
    
    private func updateToolbarButtons() {
        guard let toolbar = gameToolbar else { return }
        
        // Update button states
        let isSolved = progressManager.isPuzzleSolved(currentPuzzleIndex)
        
        // When solved: keep toolbar visible but disable all actions
        let allowActions = !isSolved
        
        GameToolbar.updateButtonState(toolbar: toolbar, buttonName: "undoButton", enabled: allowActions && commandManager.canUndo)
        GameToolbar.updateButtonState(toolbar: toolbar, buttonName: "redoButton", enabled: allowActions && commandManager.canRedo)
        GameToolbar.updateButtonState(toolbar: toolbar, buttonName: "clearButton", enabled: allowActions)
        GameToolbar.updateButtonState(toolbar: toolbar, buttonName: "floodButton", enabled: allowActions)
        GameToolbar.updateButtonState(toolbar: toolbar, buttonName: "hintButton", enabled: allowActions)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle hint popup buttons first (if visible)
        if childNode(withName: "hintOverlay") != nil {
            handleHintPopupTouch(touchedNode: touchedNode)
            return // Don't process other touches while popup is visible
        }
        
        // Handle button touches
        let buttonNames = ["backButton", "submitButton", "nextButton"]
        handleButtonTouch(touch: touch, buttonNames: buttonNames, onPress: { button in
            GameButton.animatePress(button)
        })
        
        // Handle toolbar button touches
        let toolbarButtonNames = ["undoButton", "redoButton", "clearButton", "floodButton", "hintButton"]
        handleToolbarTouch(touch: touch, buttonNames: toolbarButtonNames)
        
        // Handle grid cell taps
        handleCellTouch(touch: touch, location: location, touchedNode: touchedNode)
    }
    
    private func handleHintPopupTouch(touchedNode: SKNode) {
        let buttonNames = ["watchAdButton", "cancelHintButton"]
        
        guard let tappedButton = PopupDialog.findTappedButton(touchedNode: touchedNode, buttonNames: buttonNames) else {
            return
        }
        
        // Find the actual button node for animation
        var node: SKNode? = touchedNode
        while let current = node {
            if current.name == tappedButton {
                PopupDialog.animateButtonPress(current) { [weak self] in
                    switch tappedButton {
                    case "watchAdButton":
                        self?.confirmWatchAd()
                    case "cancelHintButton":
                        self?.dismissHintConfirmation()
                        self?.pendingHint = nil
                    default:
                        break
                    }
                }
                return
            }
            node = current.parent
        }
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
               !cell.isClue && cell.state != dragFillState {
                
                // Add to batch command
                currentBatchCommand?.addCellChange(row: cellCoordinates.row, col: cellCoordinates.col, newState: dragFillState)
                
                cell.state = dragFillState
                GridRenderer.updateCellVisual(cell, cellSize: cellSize)
                progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
                lastDraggedCell = cellCoordinates
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Finalize batch command if we were dragging
        if isDragging, let batchCommand = currentBatchCommand, !batchCommand.isEmpty {
            commandManager.executeCommand(batchCommand)
        }
        
        isDragging = false
        lastDraggedCell = nil
        currentBatchCommand = nil
        
        guard let touch = touches.first else { return }
        
        let buttonNames = ["backButton", "submitButton", "nextButton"]
        handleButtonTouch(touch: touch, buttonNames: buttonNames, onRelease: { button, buttonName in
            GameButton.animateRelease(button) {
                self.handleButtonAction(buttonName)
            }
        })
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastDraggedCell = nil
        currentBatchCommand = nil
    }
    
    // MARK: - Game Logic
    
    private func handleToolbarTouch(touch: UITouch, buttonNames: [String]) {
        guard let toolbar = gameToolbar else { return }
        let location = touch.location(in: toolbar)
        let _ = toolbar.atPoint(location)
        
        // Determine which button node (by ancestry) was touched; make whole button clickable
        let nodeAtPoint = toolbar.atPoint(location)
        if let buttonNode = nodeAtPoint.closestAncestor(namedIn: buttonNames) {
            // Skip disabled buttons
            if buttonNode.alpha < 0.9 { return }
            GameToolbar.animateButtonPress(buttonNode) {
                if let name = buttonNode.name { self.handleButtonAction(name) }
            }
        }
    }
    
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
        
        // Create and execute command
        let command = CellStateCommand(gameGrid: gameGrid, row: coordinates.row, col: coordinates.col, newState: newState)
        commandManager.executeCommand(command)
        
        GridRenderer.updateCellVisual(cell, cellSize: cellSize)
        progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
        
        // Setup drag state with batch command
        isDragging = true
        dragFillState = newState
        lastDraggedCell = coordinates
        currentBatchCommand = BatchCellCommand(gameGrid: gameGrid)
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
        case "floodButton":
            floodPuzzle()
        case "undoButton":
            if commandManager.canUndo {
                commandManager.undo()
                updateGridVisuals()
                progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
            }
        case "redoButton":
            if commandManager.canRedo {
                commandManager.redo()
                updateGridVisuals()
                progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
            }
        case "hintButton":
            requestHint()
        default:
            break
        }
    }
    
    // MARK: - Hint System
    
    private func requestHint() {
        // First check if there's a hint available
        guard let hint = HintProvider.getHint(grid: gameGrid, puzzle: currentPuzzle) else {
            showMessage("No hints needed - puzzle looks correct!")
            return
        }
        
        // Store hint for later use
        pendingHint = hint
        
        // Show confirmation popup using reusable component
        let overlay = PopupDialog.create(config: .hint(), sceneSize: size)
        overlay.name = "hintOverlay"
        addChild(overlay)
        PopupDialog.show(overlay)
    }
    
    private func dismissHintConfirmation() {
        if let overlay = childNode(withName: "hintOverlay") {
            PopupDialog.dismiss(overlay)
        }
    }
    
    private func confirmWatchAd() {
        dismissHintConfirmation()
        
        guard let hint = pendingHint else { return }
        
        // Show rewarded ad
        showRewardedAd { [weak self] earnedReward in
            guard let self = self, earnedReward else {
                self?.showMessage("Ad not available, try again later")
                return
            }
            
            // User earned the reward - apply the hint
            self.applyHint(hint)
            self.pendingHint = nil
        }
    }
    
    private func applyHint(_ hint: HintProvider.Hint) {
        guard let cell = gameGrid.getCell(row: hint.row, col: hint.col) else { return }
        
        // Create and execute command for undo support
        let command = CellStateCommand(
            gameGrid: gameGrid,
            row: hint.row,
            col: hint.col,
            newState: hint.correctState
        )
        commandManager.executeCommand(command)
        
        // Update visuals
        GridRenderer.updateCellVisual(cell, cellSize: cellSize)
        progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
        
        // Show hint animation
        showHintAnimation(at: hint.row, col: hint.col)
        showMessage(hint.message)
    }
    
    private func showHintAnimation(at row: Int, col: Int) {
        guard let cell = gameGrid.getCell(row: row, col: col),
              let cellNode = cell.node else { return }
        
        // Crop node to clip shine within cell bounds
        let cropNode = SKCropNode()
        cropNode.position = cellNode.position
        cropNode.zPosition = 50
        gridContainer.addChild(cropNode)
        
        // Mask = cell shape
        let mask = SKShapeNode(rectOf: CGSize(width: cellSize - 2, height: cellSize - 2))
        mask.fillColor = .white
        cropNode.maskNode = mask
        
        // Diagonal white shine bar
        let shineWidth: CGFloat = cellSize * 0.35
        let shine = SKShapeNode(rectOf: CGSize(width: shineWidth, height: cellSize * 2))
        shine.fillColor = UIColor.white.withAlphaComponent(0.7)
        shine.strokeColor = .clear
        shine.zRotation = .pi / 5  // ~36° angle
        shine.position = CGPoint(x: -cellSize * 1.2, y: 0)
        cropNode.addChild(shine)
        
        // Sweep animation: 3 passes over ~2.5 seconds
        let sweepDuration: TimeInterval = 0.8
        let pauseBetween: TimeInterval = 0.5
        
        let sweepAcross = SKAction.moveTo(x: cellSize * 1.2, duration: sweepDuration)
        sweepAcross.timingMode = .easeInEaseOut
        let reset = SKAction.moveTo(x: -cellSize * 1.2, duration: 0)
        let pause = SKAction.wait(forDuration: pauseBetween)
        
        let singleSweep = SKAction.sequence([sweepAcross, reset, pause])
        let allSweeps = SKAction.repeat(singleSweep, count: 4)
        
        shine.run(.sequence([allSweeps, .removeFromParent()])) {
            cropNode.removeFromParent()
        }
    }
    
    private func showMessage(_ text: String) {
        let messageLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        messageLabel.text = text
        messageLabel.fontSize = 20
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
    
    private func handleSubmit() {
        if SolutionChecker.checkSolution(grid: gameGrid, puzzle: currentPuzzle) {
            progressManager.markPuzzleAsSolved(currentPuzzleIndex)
            isSubmitEnabled = false
            gameToolbar.isHidden = true
            showSolvedMessage()
            updateSubmitButton()
        } else {
            showNotSolvedMessage()
        }
    }
    
    private func clearPuzzle() {
        let clearCommand = ClearGridCommand(gameGrid: gameGrid)
        commandManager.executeCommand(clearCommand)
        updateGridVisuals()
        progressManager.clearPuzzleProgress(currentPuzzleIndex)
    }
    
    private func floodPuzzle() {
        let floodCommand = FloodGridCommand(gameGrid: gameGrid)
        commandManager.executeCommand(floodCommand)
        updateGridVisuals()
        progressManager.savePuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
    }
    
    private func loadNextPuzzle() {
        // Remove solved overlay
        childNode(withName: "solvedOverlay")?.removeFromParent()
        gameToolbar.isHidden = false
        
        currentPuzzleIndex = (currentPuzzleIndex + 1) % allPuzzles.count
        currentPuzzle = allPuzzles[currentPuzzleIndex]
        
        // Clear command history for new puzzle
        commandManager.clearHistory()
        
        isNavigatingFromNext = true
        gameGrid.setupPuzzle(currentPuzzle)
        rebuildGrid()
        
        if progressManager.isPuzzleSolved(currentPuzzleIndex) {
            isSubmitEnabled = false
            updateToolbarButtons() // keep visible but disabled
        } else {
            isSubmitEnabled = true
            _ = progressManager.loadPuzzleProgress(gameGrid, puzzleIndex: currentPuzzleIndex)
            updateGridVisuals()
        }
        
        updateSubmitButton()
    }
    
    // MARK: - UI Feedback
    
    private func showSolvedMessage() {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: min(size.width * 0.9, size.height * 0.7)))
        overlay.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        overlay.strokeColor = AppColors.primary
        overlay.lineWidth = 3.0
        overlay.position = CGPoint.zero
        overlay.zPosition = 200
        overlay.alpha = 0
        overlay.name = "solvedOverlay"
        
        let solvedLabel = createStrokedLabel(
            text: "SOLVED",
            fontName: "HelveticaNeue-Bold",
            fontSize: 48,
            fillColor: AppColors.primary,
            strokeColor: UIColor.white,
            strokeWidth: 2
        )
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
