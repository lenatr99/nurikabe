//
//  GameSceneRefactored.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit
import GameplayKit
import Foundation
import UIKit

class GameScene: SKScene {
    
    // MARK: - Properties
    private var backButton: SKNode!
    private var submitButton: SKNode!
    private var clearButton: SKNode!
    private var titleLabel: SKLabelNode!
    
    private var gameState: GameState!
    private var progressManager: ProgressManager!
    private var gameRenderer: GameRenderer!
    
    private var isSubmitEnabled = true
    private var isNavigatingFromNext = false
    
    // MARK: - Drag Properties
    private var isDragging = false
    private var dragFillState: CellState = .empty
    private var lastDraggedCell: (row: Int, col: Int)? = nil
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = AppColors.background
        
        setupComponents()
        setupUI()
        loadInitialPuzzle()
    }
    
    // MARK: - Setup
    private func setupComponents() {
        // Default to first grid config if not set
        let defaultConfig = GameConfig.gridSizes[0]
        gameState = GameState(gridConfig: defaultConfig)
        progressManager = ProgressManager(gridConfig: defaultConfig)
        gameRenderer = GameRenderer(scene: self)
    }
    
    private func setupUI() {
        setupTitle()
        setupBackButton()
        setupSubmitButton()
        setupClearButton()
    }
    
    private func loadInitialPuzzle() {
        guard gameState.loadPuzzleData() else {
            showErrorAndReturnToMenu("Failed to load puzzle data")
            return
        }
        
        gameRenderer.renderGrid(gameState: gameState)
        updateTitle()
        
        // Load saved progress
        DispatchQueue.main.async {
            var grid = self.gameState.gameGrid
            let hasProgress = self.progressManager.loadPuzzleProgress(gameGrid: &grid, puzzleIndex: self.gameState.currentPuzzleIndex)
            if hasProgress {
                // Update visuals for loaded progress
                for row in grid {
                    for cell in row {
                        self.gameRenderer.updateCellVisual(cell: cell)
                    }
                }
            }
        }
        
        updateButtonStates()
    }
    
    // MARK: - Public Interface
    func setStartingPuzzleIndex(_ index: Int) {
        gameState.setStartingPuzzleIndex(index)
        NSLog("🎯 GameScene initialized with puzzle index: %d", index)
    }
    
    func setGridFilename(_ filename: String) {
        if let config = GameConfig.getConfig(for: filename) {
            gameState.setGridConfig(config)
            progressManager = ProgressManager(gridConfig: config)
        }
        NSLog("🎯 GameScene will load data from: %@", filename)
    }
    
    // MARK: - UI Setup
    private func setupTitle() {
        titleLabel = SKLabelNode(fontNamed: UIConstants.preferredBoldFont())
        titleLabel.text = "Nurikabe"
        titleLabel.fontSize = max(24, min(32, size.width * 0.05))
        titleLabel.fontColor = AppColors.titleText
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.4)
        titleLabel.zPosition = 10
        addChild(titleLabel)
    }
    
    private func setupBackButton() {
        backButton = ButtonFactory.createButton(
            title: "Back",
            width: 150,
            actionName: "backButton"
        )
        backButton.position = CGPoint(x: -130, y: -size.height * 0.4)
        addChild(backButton)
    }
    
    private func setupSubmitButton() {
        updateSubmitButton()
    }
    
    private func setupClearButton() {
        clearButton = ButtonFactory.createButton(
            title: "Clear",
            width: 45,
            height: 35,
            actionName: "clearButton"
        )
        clearButton.position = CGPoint(
            x: (min(size.width * 0.8, size.height * 0.6) - 45)/2,
            y: -(min(size.width * 0.8, size.height * 0.6) + 35)/2 - 10
        )
        addChild(clearButton)
    }
    
    private func updateSubmitButton() {
        submitButton?.removeFromParent()
        
        let buttonTitle: String
        let buttonName: String
        
        if gameRenderer.isSolvedOverlayShowing() && gameState.currentPuzzleIndex < gameState.allPuzzles.count - 1 {
            buttonTitle = "Next"
            buttonName = "nextButton"
        } else if !gameRenderer.isSolvedOverlayShowing() {
            buttonTitle = "Submit"
            buttonName = "submitButton"
        } else {
            // Last puzzle and solved - hide button
            return
        }
        
        submitButton = ButtonFactory.createButton(
            title: buttonTitle,
            width: 150,
            actionName: buttonName,
            isEnabled: isSubmitEnabled
        )
        submitButton.position = CGPoint(x: 130, y: -size.height * 0.4)
        addChild(submitButton)
    }
    
    // MARK: - Game Logic
    private func handleSubmit() {
        NSLog("🔘 Submit button pressed")
        if gameState.checkSolution() {
            NSLog("🎉 Puzzle solved correctly!")
            
            progressManager.markPuzzleAsSolved(gameState.currentPuzzleIndex)
            isSubmitEnabled = false
            updateButtonStates()
            gameRenderer.showSolvedOverlay()
            updateSubmitButton()
        } else {
            NSLog("❌ Puzzle not solved yet")
            gameRenderer.showNotSolvedMessage()
        }
    }
    
    private func loadNextPuzzle() {
        NSLog("🎮 Loading next puzzle...")
        
        gameRenderer.removeSolvedOverlay()
        clearButton?.isHidden = false
        
        let nextIndex = (gameState.currentPuzzleIndex + 1) % gameState.allPuzzles.count
        isNavigatingFromNext = true
        
        guard gameState.loadPuzzleAtIndex(nextIndex) else {
            showErrorAndReturnToMenu("Failed to load next puzzle")
            return
        }
        
        gameRenderer.renderGrid(gameState: gameState)
        updateTitle()
        
        isSubmitEnabled = true
        updateButtonStates()
        updateSubmitButton()
        
        isNavigatingFromNext = false
    }
    
    private func clearPuzzle() {
        NSLog("🗑️ Clearing puzzle progress")
        gameState.resetGrid()
        
        // Update visuals
        for row in gameState.gameGrid {
            for cell in row {
                gameRenderer.updateCellVisual(cell: cell)
            }
        }
        
        progressManager.clearPuzzleProgress(gameState.currentPuzzleIndex)
        NSLog("✅ Puzzle cleared successfully")
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle button taps
        if let nodeName = touchedNode.name ?? touchedNode.parent?.name {
            if nodeName.contains("back") {
                backButton.animatePress()
                return
            } else if nodeName.contains("submit") || nodeName.contains("next") {
                if isSubmitEnabled {
                    submitButton.animatePress()
                }
                return
            } else if nodeName.contains("clear") {
                clearButton.animatePress()
                return
            }
        }
        
        // Handle grid cell taps
        handleGridCellTouch(location: location, touchedNode: touchedNode)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        guard let cellCoordinates = gameRenderer.getCellAt(location: location, gridSize: gameState.gridSize) else { return }
        
        if let lastCell = lastDraggedCell,
           lastCell.row == cellCoordinates.row && lastCell.col == cellCoordinates.col {
            return
        }
        
        let cell = gameState.gameGrid[cellCoordinates.row][cellCoordinates.col]
        if cell.isClue { return }
        
        gameState.applyCellState(dragFillState, to: cell)
        gameRenderer.updateCellVisual(cell: cell)
        progressManager.savePuzzleProgress(gameGrid: gameState.gameGrid, puzzleIndex: gameState.currentPuzzleIndex)
        
        lastDraggedCell = cellCoordinates
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastDraggedCell = nil
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle button releases
        if let nodeName = touchedNode.name ?? touchedNode.parent?.name {
            if nodeName.contains("back") {
                returnToMenu()
            } else if nodeName.contains("submit") && isSubmitEnabled {
                handleSubmit()
            } else if nodeName.contains("next") {
                loadNextPuzzle()
            } else if nodeName.contains("clear") {
                clearPuzzle()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleGridCellTouch(location: CGPoint, touchedNode: SKNode) {
        var cellName: String?
        
        if let nodeName = touchedNode.name, nodeName.hasPrefix("cell_") {
            cellName = nodeName
        } else if nodeName == "dot", let parentName = touchedNode.parent?.name, parentName.hasPrefix("cell_") {
            cellName = parentName
        }
        
        guard let name = cellName,
              let coordinates = gameRenderer.getCellCoordinates(from: name, gridSize: gameState.gridSize) else {
            return
        }
        
        let cell = gameState.gameGrid[coordinates.row][coordinates.col]
        if cell.isClue { return }
        
        let newState = gameState.getNextCellState(from: cell.state)
        gameState.applyCellState(newState, to: cell)
        gameRenderer.updateCellVisual(cell: cell)
        progressManager.savePuzzleProgress(gameGrid: gameState.gameGrid, puzzleIndex: gameState.currentPuzzleIndex)
        
        // Setup drag state
        isDragging = true
        dragFillState = newState
        lastDraggedCell = coordinates
    }
    
    private func updateTitle() {
        titleLabel.text = "Nurikabe"
    }
    
    private func updateButtonStates() {
        let isSolved = progressManager.isPuzzleSolved(gameState.currentPuzzleIndex)
        isSubmitEnabled = !isSolved
        clearButton?.isHidden = isSolved
        updateSubmitButton()
    }
    
    private func showErrorAndReturnToMenu(_ message: String) {
        let errorLabel = SKLabelNode(fontNamed: UIConstants.preferredButtonFont())
        errorLabel.text = "Error: \(message)"
        errorLabel.fontSize = 24
        errorLabel.fontColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        errorLabel.position = CGPoint.zero
        errorLabel.zPosition = 200
        addChild(errorLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.returnToMenu()
        }
    }
    
    private func returnToMenu() {
        guard let view = view else { return }
        
        let levelSelectScene = LevelSelectScene(size: view.bounds.size)
        levelSelectScene.scaleMode = .aspectFill
        levelSelectScene.setGridSize(filename: gameState.currentGridConfig.filename)
        
        let transition = SKTransition.fade(withDuration: UIConstants.Animation.sceneTransitionDuration)
        view.presentScene(levelSelectScene, transition: transition)
    }
}
