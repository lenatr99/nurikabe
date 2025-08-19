//
//  GameScene.swift (Legacy - Large Monolithic Version)
//  Nurikabe
//
//  Created by Lena Trnovec on 8/12/25.
//  Refactored by Assistant on 8/16/25.
//

// This file has been replaced by the modular GameSceneRefactored.swift
// Keeping this for reference but it should not be used

/*
import SpriteKit
import GameplayKit
import Foundation
import UIKit

// MARK: - Grid Cell Helper Classes
enum CellState {
    case empty
    case filled
    case dot
    case blocked
}

class GridCell {
    var node: SKShapeNode!
    var row: Int = 0
    var col: Int = 0
    var state: CellState = .empty
    var isClue: Bool = false
    var clueNumber: Int = 0
}

class GameScene: SKScene {
    
    // MARK: - Properties
    private var backButton: SKNode!
    private var submitButton: SKNode!
    private var clearButton: SKNode!
    private var isSubmitEnabled = true
    private var titleLabel: SKLabelNode!
    private var gridContainer: SKNode!
    private var gameGrid: [[GridCell]] = []
    
    private var gridSize = 5  // Will be set based on puzzle data
    private var cellSize: CGFloat = 0
    private var puzzleData: [[Int]] = []
    private var solutionData: [String] = []
    private var allPuzzles: [[String: Any]] = []
    private var currentPuzzleIndex = 0
    private var currentGridFilename = "nurikabes_5x5_easy"
    
    // MARK: - Drag-to-fill properties
    private var isDragging = false
    private var dragFillState: CellState = .empty
    private var lastDraggedCell: (row: Int, col: Int)? = nil
    
    // MARK: - Progress tracking
    private var currentGridConfig: GameConfig.GridSizeConfig = GameConfig.gridSizes[0]
    private var isNavigatingFromNext = false
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Use same background color as menu
        backgroundColor = AppColors.background
        
        // Initialize submit button state
        isSubmitEnabled = true
        
        // Load puzzle data first
        loadPuzzleData()
        
        setupTitle()
        setupBackButton()
        setupSubmitButton()
        setupNurikabeGrid()
        setupClearButton()
    }
    
    // MARK: - Public Methods
    func setStartingPuzzleIndex(_ index: Int) {
        currentPuzzleIndex = index
        NSLog("🎯 GameScene initialized with puzzle index: %d", index)
    }
    
    func setGridFilename(_ filename: String) {
        currentGridFilename = filename
        if let config = GameConfig.getConfig(for: filename) {
            currentGridConfig = config
        }
        NSLog("🎯 GameScene will load data from: %@ (solved key: %@)", filename, currentGridConfig.solvedPuzzlesKey)
    }
    
    private func loadPuzzleData() {
        // Load puzzle data from JSON file
        guard let path = Bundle(for: GameScene.self).path(forResource: currentGridFilename, ofType: "json") else {
            NSLog("❌ ERROR: json file not found in bundle: \(currentGridFilename).json")
            showErrorAndReturnToMenu("JSON file not found")
            return
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            NSLog("❌ ERROR: Could not readjson file")
            showErrorAndReturnToMenu("Could not read JSON file")
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            NSLog("❌ ERROR: Invalid JSON format in json")
            showErrorAndReturnToMenu("Invalid JSON format")
            return
        }
        
        guard let items = json["items"] as? [[String: Any]] else {
            NSLog("❌ ERROR: No 'items' array found in JSON")
            showErrorAndReturnToMenu("No puzzles found in JSON")
            return
        }
        
        guard !items.isEmpty else {
            NSLog("❌ ERROR: No puzzles found in JSON items array")
            showErrorAndReturnToMenu("No puzzles available")
            return
        }
        
        // Store all puzzles for navigation
        allPuzzles = items
        
        // Load the current puzzle (or first puzzle if starting)
        loadPuzzleAtIndex(currentPuzzleIndex)
        
        // Try to load saved progress after initial grid setup
        // Load progress for both solved and unsolved puzzles to preserve visual state
        DispatchQueue.main.async {
            let hasProgress = self.loadPuzzleProgress()
            if hasProgress {
                NSLog("📁 Restored initial saved progress for puzzle %d (solved: %@)", self.currentPuzzleIndex, self.isPuzzleSolved(self.currentPuzzleIndex) ? "YES" : "NO")
            } else {
                NSLog("📁 No initial saved progress for puzzle %d (solved: %@)", self.currentPuzzleIndex, self.isPuzzleSolved(self.currentPuzzleIndex) ? "YES" : "NO")
            }
        }
    }
    
    private func loadPuzzleAtIndex(_ index: Int) {
        guard index >= 0 && index < allPuzzles.count else {
            NSLog("❌ ERROR: Invalid puzzle index: %d (total: %d)", index, allPuzzles.count)
            showErrorAndReturnToMenu("Invalid puzzle index")
            return
        }
        
        let puzzleItem = allPuzzles[index]
        guard let puzzleString = puzzleItem["puzzle"] as? String,
              let solutionString = puzzleItem["solutionFlat"] as? String else {
            NSLog("❌ ERROR: Invalid puzzle format at index %d", index)
            showErrorAndReturnToMenu("Invalid puzzle format")
            return
        }
        
        // Parse the puzzle string format: "5x5:3,-,-,-,2,..."
        puzzleData = parsePuzzleString(puzzleString)
        // Split and filter out empty strings (in case of trailing commas)
        solutionData = solutionString.components(separatedBy: ",").filter { !$0.isEmpty }
        
        NSLog("✅ Successfully loaded puzzle %d of %d", index + 1, allPuzzles.count)
        NSLog("📝 Puzzle: %@", puzzleString)
        NSLog("🎯 Solution: %@", solutionString)
        NSLog("📏 Parsed grid size: %dx%d", gridSize, gridSize)
        NSLog("🧩 Parsed puzzle data: %@", String(describing: puzzleData))
        NSLog("🔑 Solution data (%d items): %@", solutionData.count, solutionData.joined(separator: ","))
        
        // Update the title and rebuild grid if this is not the initial load
        if gridContainer != nil {
            updateTitle()
            rebuildGrid()
            
            // Check if this puzzle is already solved
            if isPuzzleSolved(currentPuzzleIndex) {
                isSubmitEnabled = false
                updateSubmitButtonAppearance()
                // Hide Clear button for solved puzzles
                clearButton?.isHidden = true
                // Only show solved screen if not navigating from Next button
                if !isNavigatingFromNext {
                    showSolvedMessage()  // Show solved screen for already solved puzzles
                }
                NSLog("📋 Loaded already solved puzzle %d", currentPuzzleIndex)
            } else {
                isSubmitEnabled = true
                updateSubmitButtonAppearance()
                NSLog("📋 Loaded unsolved puzzle %d", currentPuzzleIndex)
                
                // Show Clear button for unsolved puzzles
                clearButton?.isHidden = false
            }
            
            // Load saved progress for both solved and unsolved puzzles (after grid is fully built)
            DispatchQueue.main.async {
                let hasProgress = self.loadPuzzleProgress()
                if hasProgress {
                    NSLog("📁 Restored saved progress for puzzle %d (solved: %@)", self.currentPuzzleIndex, self.isPuzzleSolved(self.currentPuzzleIndex) ? "YES" : "NO")
                } else {
                    NSLog("📁 No saved progress for puzzle %d (solved: %@)", self.currentPuzzleIndex, self.isPuzzleSolved(self.currentPuzzleIndex) ? "YES" : "NO")
                }
            }
            
            // Reset the navigation flag
            isNavigatingFromNext = false
        }
    }
    
    private func showErrorAndReturnToMenu(_ message: String) {
        let errorLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        errorLabel.text = "Error: \(message)"
        errorLabel.fontSize = 24
        errorLabel.fontColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        errorLabel.position = CGPoint.zero
        errorLabel.zPosition = 200
        addChild(errorLabel)
        
        // Return to menu after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.returnToMenu()
        }
    }
    
    private func parsePuzzleString(_ puzzleString: String) -> [[Int]] {
        let components = puzzleString.components(separatedBy: ":")
        guard components.count == 2 else { return [] }
        
        // Parse size from "5x5"
        let sizeComponents = components[0].components(separatedBy: "x")
        guard sizeComponents.count == 2,
              let width = Int(sizeComponents[0]),
              let height = Int(sizeComponents[1]) else { return [] }
        
        gridSize = width
        
        // Parse puzzle data
        let dataString = components[1]
        let cellStrings = dataString.components(separatedBy: ",")
        
        var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: width), count: height)
        
        for (index, cellString) in cellStrings.enumerated() {
            let row = index / width
            let col = index % width
            
            if row < height && col < width {
                if cellString == "-" {
                    grid[row][col] = 0
                } else if let number = Int(cellString) {
                    grid[row][col] = number
                }
            }
        }
        
        return grid
    }
    
    private func setupTitle() {
        titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        titleLabel.text = "Nurikabe Puzzle"  // Will be updated after loading puzzles
        titleLabel.fontSize = max(24, min(32, size.width * 0.05))
        titleLabel.fontColor = AppColors.titleText
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.4)
        titleLabel.zPosition = 10
        addChild(titleLabel)
    }
    
    private func setupBackButton() {
        let container = SKNode()
        container.name = "backButton"
        container.zPosition = 100
        
        // Create glass-morphism button matching menu style
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 50
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        bg.name = "bg"
        bg.fillColor = AppColors.buttonBackground
        bg.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Back"
        label.fontSize = 28
        label.fontColor = AppColors.buttonText
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        label.position = CGPoint.zero
        label.zPosition = 1
        label.name = "backLabel"  // Add name for better touch detection
        container.addChild(label)
        
        // Add invisible larger touch area
        let touchArea = SKShapeNode(rectOf: CGSize(width: buttonWidth + 20, height: buttonHeight + 20))
        touchArea.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        touchArea.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        touchArea.name = "backTouchArea"
        touchArea.zPosition = 0
        container.addChild(touchArea)
        
        // Position to the left of center at bottom
        container.position = CGPoint(
            x: -130,
            y: -size.height * 0.4
        )
        
        backButton = container
        addChild(container)
    }
    
    private func setupSubmitButton() {
        updateSubmitButton()
    }
    
    private func setupClearButton() {
        let container = SKNode()
        container.name = "clearButton"
        container.zPosition = 100
        
        let buttonWidth: CGFloat = 45
        let buttonHeight: CGFloat = 35
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        bg.name = "bg"
        bg.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        // bg.strokeColor = UIColor.white
        bg.lineWidth = 0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Clear"
        label.fontSize = 15
        label.fontColor = UIColor.white 
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        label.zPosition = 1
        label.name = "clearLabel"
        container.addChild(label)
        
        // Add invisible larger touch area
        let touchArea = SKShapeNode(rectOf: CGSize(width: buttonWidth + 20, height: buttonHeight + 20))
        touchArea.fillColor = UIColor.clear
        touchArea.strokeColor = UIColor.clear
        touchArea.zPosition = 0
        touchArea.name = "clearTouchArea"
        container.addChild(touchArea)
        
        container.position = CGPoint(
            x: (min(size.width * 0.8, size.height * 0.6) - buttonWidth)/2,
            y: -(min(size.width * 0.8, size.height * 0.6) + buttonHeight)/2 - 10
        )
        
        clearButton = container
        addChild(container)
    }
    
    private func updateSubmitButton() {
        // Remove existing button if it exists
        submitButton?.removeFromParent()
        
        let container = SKNode()
        container.zPosition = 100
        
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 50
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        bg.name = "bg"
        bg.fillColor = AppColors.buttonBackground
        bg.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.fontSize = 28
        label.fontColor = AppColors.buttonText
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        label.position = CGPoint.zero
        label.zPosition = 1
        container.addChild(label)
        
        // Add invisible larger touch area
        let touchArea = SKShapeNode(rectOf: CGSize(width: buttonWidth + 20, height: buttonHeight + 20))
        touchArea.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        touchArea.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        touchArea.zPosition = 0
        container.addChild(touchArea)
        
        // Check if solved overlay is showing to determine button type
        if isSolvedOverlayShowing() && currentPuzzleIndex < allPuzzles.count - 1 {
            // Show Next button when solved overlay is visible
            container.name = "nextButton"
            label.text = "Next"
            label.name = "nextLabel"
            touchArea.name = "nextTouchArea"
        } else if !isSolvedOverlayShowing() {
            // Show Submit button when solved overlay is not showing
            container.name = "submitButton"
            label.text = "Submit"
            label.name = "submitLabel"
            touchArea.name = "submitTouchArea"
        } else {
            // Last puzzle and solved overlay showing - hide button
            submitButton = nil
            return
        }
        
        // Position to the right of center at bottom
        container.position = CGPoint(
            x: 130,
            y: -size.height * 0.4
        )
        
        submitButton = container
        addChild(container)
    }
    
    private func setupNurikabeGrid() {
        gridContainer = SKNode()
        gridContainer.zPosition = 50
        addChild(gridContainer)
        
        rebuildGrid()
        updateTitle()
    }
    
    private func rebuildGrid() {
        // Remove existing grid cells
        gridContainer.removeAllChildren()
        
        // Calculate cell size based on available space
        let maxGridSize = min(size.width * 0.8, size.height * 0.6)
        cellSize = maxGridSize / CGFloat(gridSize)
        
        // Initialize the grid
        gameGrid = Array(repeating: Array(repeating: GridCell(), count: gridSize), count: gridSize)
        
        // Create grid cells
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = createGridCell(row: row, col: col)
                gameGrid[row][col] = cell
                gridContainer.addChild(cell.node)
            }
        }
    }
    
    private func createGridCell(row: Int, col: Int) -> GridCell {
        let cell = GridCell()
        
        // Create cell background
        let cellNode = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        cellNode.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        cellNode.strokeColor = AppColors.primary
        cellNode.lineWidth = 2.0
        cellNode.name = "cell_\(row)_\(col)"
        
        // Position the cell
        let startX = -CGFloat(gridSize - 1) * cellSize / 2
        let startY = CGFloat(gridSize - 1) * cellSize / 2
        cellNode.position = CGPoint(
            x: startX + CGFloat(col) * cellSize,
            y: startY - CGFloat(row) * cellSize
        )
        
        // Add number if it's a clue cell
        let clueNumber = puzzleData[row][col]
        if clueNumber > 0 {
            let numberLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            numberLabel.text = "\(clueNumber)"
            numberLabel.fontSize = cellSize * 0.5
            numberLabel.fontColor = AppColors.primary
            numberLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
            numberLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
            numberLabel.position = CGPoint.zero
            numberLabel.zPosition = 1
            cellNode.addChild(numberLabel)
            
            cell.isClue = true
            cell.clueNumber = clueNumber
        }
        
        cell.node = cellNode
        cell.row = row
        cell.col = col
        cell.state = .empty
        
        return cell
    }
    
    private func addDotToCell(_ cell: GridCell) {
        // Remove any existing dot first
        removeDotFromCell(cell)
        
        // Create a primary color dot in the center
        let dotRadius = cellSize * 0.15
        let dot = SKShapeNode(circleOfRadius: dotRadius)
        dot.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        dot.strokeColor = AppColors.primary
        dot.name = "dot"
        dot.position = CGPoint.zero
        dot.zPosition = 2
        
        cell.node.addChild(dot)
    }
    
    private func removeDotFromCell(_ cell: GridCell) {
        // Remove any existing dot
        cell.node.childNode(withName: "dot")?.removeFromParent()
    }
    
    private func printCurrentGrid() {
        print("\n=== CURRENT GRID STATE ===")
        for row in 0..<gridSize {
            var rowString = ""
            for col in 0..<gridSize {
                let cell = gameGrid[row][col]
                if cell.isClue {
                    rowString += "\(cell.clueNumber) "
                } else {
                    switch cell.state {
                    case .empty:
                        rowString += "⬜ "
                    case .filled:
                        rowString += "⬛ "
                    case .dot:
                        rowString += "🔘 "
                    case .blocked:
                        rowString += "❌ "
                    }
                }
            }
            print("Row \(row): \(rowString)")
        }
        print("==========================\n")
    }
    
    private func printExpectedSolution() {
        print("\n=== EXPECTED SOLUTION ===")
        for row in 0..<gridSize {
            var rowString = ""
            for col in 0..<gridSize {
                let index = row * gridSize + col
                if index < solutionData.count {
                    let symbol = solutionData[index]
                    switch symbol {
                    case "#":
                        rowString += "⬛ "  // Water (should be filled)
                    case "*":
                        rowString += "⬜ "  // Island (empty or dot OK)
                    default:
                        if let num = Int(symbol) {
                            rowString += "\(num) "  // Clue number
                        } else {
                            rowString += "? "
                        }
                    }
                } else {
                    rowString += "? "
                }
            }
            print("Row \(row): \(rowString)")
        }
        print("=========================\n")
    }
    
    private func checkSolution() -> Bool {
        NSLog("🔍 CHECKING SOLUTION...")
        NSLog("Grid size: %dx%d", gridSize, gridSize)
        NSLog("Solution data count: %d", solutionData.count)
        NSLog("Expected count: %d", gridSize * gridSize)
        
        // Print both grids for comparison
        printCurrentGrid()
        printExpectedSolution()
        
        guard solutionData.count == gridSize * gridSize else {
            print("❌ Solution data size mismatch: expected \(gridSize * gridSize), got \(solutionData.count)")
            return false
        }
        
        var correctCells = 0
        var totalNonClueCells = 0
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let index = row * gridSize + col
                let cell = gameGrid[row][col]
                let expectedSymbol = solutionData[index]
                
                print("Cell (\(row),\(col)): current=\(cell.state), expected='\(expectedSymbol)', isClue=\(cell.isClue)")
                
                // Skip clue cells (numbers) - they are always correct
                if cell.isClue {
                    print("  ✅ Clue cell - always correct")
                    continue
                }
                
                totalNonClueCells += 1
                
                // Check if water positions match
                if expectedSymbol == "#" {
                    // Should be water (filled/black)
                    if cell.state == .filled {
                        print("  ✅ Water cell correct")
                        correctCells += 1
                    } else {
                        print("  ❌ Water mismatch: expected water (filled), got \(cell.state)")
                        return false
                    }
                } else if expectedSymbol == "*" {
                    // Should be island (empty or dot)
                    if cell.state == .empty || cell.state == .dot {
                        print("  ✅ Island cell correct")
                        correctCells += 1
                    } else {
                        print("  ❌ Island mismatch: expected island (empty/dot), got \(cell.state)")
                        return false
                    }
                } else {
                    print("  ⚠️  Unexpected symbol in solution: '\(expectedSymbol)'")
                }
            }
        }
        
        print("\n📊 SUMMARY:")
        print("Correct cells: \(correctCells)/\(totalNonClueCells)")
        print("Result: \(correctCells == totalNonClueCells ? "✅ SOLVED!" : "❌ Not solved")")
        
        return correctCells == totalNonClueCells
    }
    
    private func showSolvedMessage() {
        // Hide the Clear button when solved overlay is shown
        clearButton?.isHidden = true
        
        // Create solved message overlay
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
        congratsLabel.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        congratsLabel.verticalAlignmentMode = .center
        congratsLabel.horizontalAlignmentMode = .center
        congratsLabel.position = CGPoint(x: 0, y: -20)
        congratsLabel.zPosition = 1
        
        overlay.addChild(solvedLabel)
        overlay.addChild(congratsLabel)
        
        addChild(overlay)
        
        // Update submit button to show "Next" now that solved overlay is showing
        updateSubmitButton()
        
        // Animate in
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        
        overlay.run(SKAction.group([fadeIn]))
    }
    
    private func createNextPuzzleButton() -> SKNode {
        let container = SKNode()
        container.name = "nextPuzzleButton"
        container.zPosition = 2
        
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 50
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        bg.name = "bg"
        bg.fillColor = AppColors.primary
        bg.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Next"
        label.fontSize = 28
        label.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        label.zPosition = 1
        label.name = "nextLabel"
        container.addChild(label)
        
        return container
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle back button tap - improved detection
        if let nodeName = touchedNode.name {
            if nodeName.contains("back") || touchedNode.parent?.name == "backButton" {
                NSLog("🏠 Back button touched! Node: %@", nodeName)
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
        
        // Handle button taps - improved detection
        if let nodeName = touchedNode.name {
            if nodeName.contains("submit") || touchedNode.parent?.name == "submitButton" ||
               nodeName.contains("next") || touchedNode.parent?.name == "nextButton" ||
               nodeName.contains("clear") || touchedNode.parent?.name == "clearButton" {
                
                if nodeName.contains("submit") || touchedNode.parent?.name == "submitButton" {
                    if !isSubmitEnabled {
                        NSLog("⚠️ Submit button disabled - puzzle already solved")
                        return
                    }
                    NSLog("🔘 Submit button touched! Node: %@", nodeName)
                } else if nodeName.contains("clear") || touchedNode.parent?.name == "clearButton" {
                    NSLog("🗑️ Clear button touched! Node: %@", nodeName)
                } else {
                    NSLog("➡️ Next button touched! Node: %@", nodeName)
                }
                
                // Add visual feedback for the appropriate button
                if nodeName.contains("clear") || touchedNode.parent?.name == "clearButton" {
                    if let bg = clearButton?.childNode(withName: "bg") as? SKShapeNode {
                        let press = SKAction.group([
                            .scale(to: 0.95, duration: 0.12),
                            .fadeAlpha(to: 0.85, duration: 0.12)
                        ])
                        bg.run(press)
                    }
                } else {
                    if let bg = submitButton?.childNode(withName: "bg") as? SKShapeNode {
                        let press = SKAction.group([
                            .scale(to: 0.95, duration: 0.12),
                            .fadeAlpha(to: 0.85, duration: 0.12)
                        ])
                        bg.run(press)
                    }
                }
                return
            }
            
            // Handle Next Puzzle button tap
            if nodeName.contains("nextPuzzle") || touchedNode.parent?.name == "nextPuzzleButton" {
                NSLog("➡️ Next Puzzle button touched!")
                animateButtonPress(buttonName: "nextPuzzleButton")
                return
            }
            
            // Handle Menu button from solved overlay
            if nodeName.contains("menuFromSolved") || touchedNode.parent?.name == "menuFromSolvedButton" {
                NSLog("🏠 Menu button (from solved) touched!")
                animateButtonPress(buttonName: "menuFromSolvedButton")
                return
            }
        }
        
        // Handle grid cell taps
        if let nodeName = touchedNode.name {
            if nodeName.hasPrefix("cell_") {
                NSLog("🔘 Direct cell tap: %@", nodeName)
                handleCellTap(nodeName: nodeName)
            } else if nodeName == "dot" {
                // If we tapped on a dot, find the parent cell
                if let parentCell = touchedNode.parent,
                   let parentName = parentCell.name,
                   parentName.hasPrefix("cell_") {
                    NSLog("🔘 Dot tap (parent cell): %@", parentName)
                    handleCellTap(nodeName: parentName)
                } else {
                    NSLog("❌ Dot tap but no valid parent cell found")
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        // Get the cell at the current touch location
        guard let cellCoordinates = getCellAt(location: location) else { return }
        
        // Skip if we're still on the same cell
        if let lastCell = lastDraggedCell,
           lastCell.row == cellCoordinates.row && lastCell.col == cellCoordinates.col {
            return
        }
        
        let cell = gameGrid[cellCoordinates.row][cellCoordinates.col]
        
        // Don't fill clue cells
        if cell.isClue {
            NSLog("⚠️ Skipping clue cell at (%d,%d) during drag", cellCoordinates.row, cellCoordinates.col)
            return
        }
        
        NSLog("🖱️ Dragging to cell (%d,%d), applying state: %@", cellCoordinates.row, cellCoordinates.col, String(describing: dragFillState))
        
        // Apply the drag fill state to this cell
        applyCellState(dragFillState, to: cell)
        
        // Update last dragged cell
        lastDraggedCell = cellCoordinates
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Reset drag state
        isDragging = false
        lastDraggedCell = nil
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle back button release - improved detection
        if let nodeName = touchedNode.name {
            if nodeName.contains("back") || touchedNode.parent?.name == "backButton" {
                NSLog("🏠 Back button released! Node: %@", nodeName)
                if let bg = backButton.childNode(withName: "bg") as? SKShapeNode {
                    let release = SKAction.group([
                        .scale(to: 1.0, duration: 0.15),
                        .fadeAlpha(to: 1.0, duration: 0.15)
                    ])
                    bg.run(release) {
                        self.returnToMenu()
                    }
                } else {
                    // If bg animation fails, still call returnToMenu
                    returnToMenu()
                }
                return
            }
        }
        
        // Handle button releases - improved detection
        if let nodeName = touchedNode.name {
            if nodeName.contains("submit") || touchedNode.parent?.name == "submitButton" ||
               nodeName.contains("next") || touchedNode.parent?.name == "nextButton" ||
               nodeName.contains("clear") || touchedNode.parent?.name == "clearButton" {
                
                var isNextButton = false
                var isClearButton = false
                if nodeName.contains("submit") || touchedNode.parent?.name == "submitButton" {
                    if !isSubmitEnabled {
                        NSLog("⚠️ Submit button disabled - ignoring release")
                        return
                    }
                    NSLog("🔘 Submit button released! Node: %@", nodeName)
                } else if nodeName.contains("clear") || touchedNode.parent?.name == "clearButton" {
                    NSLog("🗑️ Clear button released! Node: %@", nodeName)
                    isClearButton = true
                } else {
                    NSLog("➡️ Next button released! Node: %@", nodeName)
                    isNextButton = true
                }
                
                // Handle visual feedback and actions based on button type
                if isClearButton {
                    if let bg = clearButton?.childNode(withName: "bg") as? SKShapeNode {
                        let release = SKAction.group([
                            .scale(to: 1.0, duration: 0.15),
                            .fadeAlpha(to: 1.0, duration: 0.15)
                        ])
                        bg.run(release) {
                            self.clearPuzzle()
                        }
                    } else {
                        clearPuzzle()
                    }
                } else if let bg = submitButton?.childNode(withName: "bg") as? SKShapeNode {
                    let release = SKAction.group([
                        .scale(to: 1.0, duration: 0.15),
                        .fadeAlpha(to: 1.0, duration: 0.15)
                    ])
                    bg.run(release) {
                        if isNextButton {
                            self.loadNextPuzzle()
                        } else {
                            self.handleSubmit()
                        }
                    }
                } else {
                    // If bg animation fails, still call the appropriate method
                    if isNextButton {
                        loadNextPuzzle()
                    } else {
                        handleSubmit()
                    }
                }
                return
            }
            
            // Handle Next Puzzle button release
            if nodeName.contains("nextPuzzle") || touchedNode.parent?.name == "nextPuzzleButton" {
                NSLog("➡️ Next Puzzle button released!")
                animateButtonRelease(buttonName: "nextPuzzleButton") {
                    self.loadNextPuzzle()
                }
                return
            }
            
            // Handle Menu button from solved overlay release
            if nodeName.contains("menuFromSolved") || touchedNode.parent?.name == "menuFromSolvedButton" {
                NSLog("🏠 Menu button (from solved) released!")
                animateButtonRelease(buttonName: "menuFromSolvedButton") {
                    self.returnToMenu()
                }
                return
            }
        }
    }
    
    private func animateButtonPress(buttonName: String) {
        if let button = childNode(withName: "//\(buttonName)"),
           let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let press = SKAction.group([
                .scale(to: 0.95, duration: 0.12),
                .fadeAlpha(to: 0.85, duration: 0.12)
            ])
            bg.run(press)
        }
    }
    
    private func animateButtonRelease(buttonName: String, completion: @escaping () -> Void) {
        if let button = childNode(withName: "//\(buttonName)"),
           let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let release = SKAction.group([
                .scale(to: 1.0, duration: 0.15),
                .fadeAlpha(to: 1.0, duration: 0.15)
            ])
            bg.run(release) {
                completion()
            }
        } else {
            completion()
        }
    }
    
    private func loadNextPuzzle() {
        NSLog("🎮 Loading next puzzle...")
        
        // Remove solved overlay
        childNode(withName: "solvedOverlay")?.removeFromParent()
        
        // Show the Clear button again when overlay is removed
        clearButton?.isHidden = false
        
        // Move to next puzzle
        currentPuzzleIndex += 1
        
        // Wrap around if we've reached the end
        if currentPuzzleIndex >= allPuzzles.count {
            currentPuzzleIndex = 0
            NSLog("🔄 Wrapped around to first puzzle")
        }
        
        // Set flag to indicate we're navigating from Next button
        isNavigatingFromNext = true
        
        // Load the new puzzle
        loadPuzzleAtIndex(currentPuzzleIndex)
        
        // Reset the grid
        resetGrid()
        
        // Update the title to show current puzzle number
        updateTitle()
        
        // Enable submit for new puzzle and update button
        isSubmitEnabled = true
        updateSubmitButton()
    }
    
    private func resetGrid() {
        // Reset all cells to empty state
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = gameGrid[row][col]
                if !cell.isClue {
                    cell.state = .empty
                    cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    removeDotFromCell(cell)
                }
            }
        }
    }
    
    private func updateTitle() {
        titleLabel.text = "Nurikabe"
    }
    
    private func updateSubmitButtonAppearance() {
        updateSubmitButton()
    }
    
    private func isSolvedOverlayShowing() -> Bool {
        return childNode(withName: "solvedOverlay") != nil
    }
    
    private func handleSubmit() {
        NSLog("🔘 Submit button pressed")
        if checkSolution() {
            NSLog("🎉 Puzzle solved correctly!")
            
            // Mark puzzle as solved
            markPuzzleAsSolved(currentPuzzleIndex)
            
            // Disable submit button to prevent multiple submissions
            isSubmitEnabled = false
            updateSubmitButtonAppearance()
            
            // Update title to show solved status
            updateTitle()
            
            showSolvedMessage()
        } else {
            NSLog("❌ Puzzle not solved yet")
            // Optionally show a "not solved" message
            showNotSolvedMessage()
        }
    }
    
    private func showNotSolvedMessage() {
        // Create a temporary message for incorrect solution
        let messageLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        messageLabel.text = "Not quite right... Keep trying!"
        messageLabel.fontSize = 24
        messageLabel.fontColor = UIColor(red: 1.0, green: 1, blue: 1, alpha: 1.0)
        messageLabel.position = CGPoint(x: 0, y: size.height * 0.3)
        messageLabel.zPosition = 150
        messageLabel.alpha = 0
        addChild(messageLabel)
        
        // Animate the message
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        messageLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    private func applyCellState(_ state: CellState, to cell: GridCell) {
        // Don't apply state to clue cells
        if cell.isClue { return }
        
        cell.state = state
        switch state {
        case .empty:
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            removeDotFromCell(cell)
        case .filled:
            cell.node.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            removeDotFromCell(cell)
        case .dot:
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            addDotToCell(cell)
        case .blocked:
            // This case should not be reached in normal gameplay
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            removeDotFromCell(cell)
        }
        
        // Save progress whenever a cell state changes
        savePuzzleProgress()
    }
    
    private func getNextCellState(from currentState: CellState) -> CellState {
        // Cycle through states: empty -> filled -> dot -> empty
        switch currentState {
        case .empty:
            return .filled
        case .filled:
            return .dot
        case .dot:
            return .empty
        case .blocked:
            return .empty
        }
    }
    
    private func getCellCoordinates(from nodeName: String) -> (row: Int, col: Int)? {
        let components = nodeName.components(separatedBy: "_")
        guard components.count == 3,
              let row = Int(components[1]),
              let col = Int(components[2]),
              row < gridSize, col < gridSize else {
            return nil
        }
        return (row, col)
    }
    
    private func getCellAt(location: CGPoint) -> (row: Int, col: Int)? {
        // Convert touch location to grid coordinates
        let gridLocation = convert(location, to: gridContainer)
        
        // Calculate which cell was touched based on position
        let startX = -CGFloat(gridSize - 1) * cellSize / 2
        let startY = CGFloat(gridSize - 1) * cellSize / 2
        
        let col = Int((gridLocation.x - startX + cellSize / 2) / cellSize)
        let row = Int((startY - gridLocation.y + cellSize / 2) / cellSize)
        
        // Check bounds
        if row >= 0 && row < gridSize && col >= 0 && col < gridSize {
            return (row, col)
        }
        return nil
    }
    
    private func handleCellTap(nodeName: String) {
        guard let coordinates = getCellCoordinates(from: nodeName) else {
            NSLog("❌ Invalid cell tap: %@", nodeName)
            return
        }
        
        let cell = gameGrid[coordinates.row][coordinates.col]
        
        // Don't allow tapping clue cells
        if cell.isClue { 
            NSLog("⚠️ Attempted to tap clue cell at (%d,%d)", coordinates.row, coordinates.col)
            return 
        }
        
        let oldState = cell.state
        let newState = getNextCellState(from: oldState)
        
        NSLog("🔘 Cell tap at (%d,%d): %@ → %@", coordinates.row, coordinates.col, String(describing: oldState), String(describing: newState))
        
        applyCellState(newState, to: cell)
        
        // Set up drag state for potential dragging
        isDragging = true
        dragFillState = newState
        lastDraggedCell = coordinates
        
        NSLog("✅ Final state: %@", String(describing: cell.state))
    }
    
    private func returnToMenu() {
        guard let view = view else { return }
        
        let levelSelectScene = LevelSelectScene(size: view.bounds.size)
        levelSelectScene.scaleMode = .aspectFill
        levelSelectScene.setGridSize(filename: currentGridFilename)
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(levelSelectScene, transition: transition)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Reset drag state when touches are cancelled
        isDragging = false
        lastDraggedCell = nil
    }
    
    // MARK: - Progress Tracking Methods
    
    private func getSolvedPuzzles() -> Set<Int> {
        let solved = UserDefaults.standard.array(forKey: currentGridConfig.solvedPuzzlesKey) as? [Int] ?? []
        return Set(solved)
    }
    
    private func markPuzzleAsSolved(_ puzzleIndex: Int) {
        var solvedPuzzles = getSolvedPuzzles()
        solvedPuzzles.insert(puzzleIndex)
        UserDefaults.standard.set(Array(solvedPuzzles), forKey: currentGridConfig.solvedPuzzlesKey)
        
        // Keep the saved progress so solved puzzles retain their visual state
        // Don't call clearPuzzleProgress(puzzleIndex) here anymore
        
        UserDefaults.standard.synchronize()
        NSLog("✅ Marked puzzle %d as solved. Total solved: %d (keeping progress for visual state)", puzzleIndex, solvedPuzzles.count)
    }
    
    private func isPuzzleSolved(_ puzzleIndex: Int) -> Bool {
        return getSolvedPuzzles().contains(puzzleIndex)
    }
    
    private func getSolvedPuzzleCount() -> Int {
        return getSolvedPuzzles().count
    }
    
    private func resetAllProgress() {
        UserDefaults.standard.removeObject(forKey: currentGridConfig.solvedPuzzlesKey)
        UserDefaults.standard.removeObject(forKey: currentGridConfig.puzzleProgressKey)
        UserDefaults.standard.synchronize()
        NSLog("🔄 Reset all puzzle progress")
    }
    
    // MARK: - Clear Puzzle
    
    private func clearPuzzle() {
        NSLog("🗑️ Clearing puzzle progress")
        
        // Reset all non-clue cells to empty
        for row in gameGrid {
            for cell in row {
                if !cell.isClue {
                    cell.state = .empty
                    cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    // Remove any dots from the cell
                    cell.node.children.forEach { child in
                        if child.name == "dot" {
                            child.removeFromParent()
                        }
                    }
                }
            }
        }
        
        // Clear the saved progress for this puzzle
        clearPuzzleProgress(currentPuzzleIndex)
        
        NSLog("✅ Puzzle cleared successfully")
    }
    
    // MARK: - Puzzle Progress Saving/Loading
    
    private func savePuzzleProgress() {
        // Convert current grid state to a saveable format
        var gridState: [[String]] = []
        for row in gameGrid {
            var rowState: [String] = []
            for cell in row {
                switch cell.state {
                case .empty:
                    rowState.append("empty")
                case .filled:
                    rowState.append("filled")
                case .dot:
                    rowState.append("dot")
                case .blocked:
                    rowState.append("blocked")
                }
            }
            gridState.append(rowState)
        }
        
        // Get existing progress dictionary or create new one
        var allProgress = UserDefaults.standard.dictionary(forKey: currentGridConfig.puzzleProgressKey) as? [String: [[String]]] ?? [:]
        
        // Save current puzzle's progress (for both solved and unsolved puzzles)
        let puzzleKey = "\(currentPuzzleIndex)"
        allProgress[puzzleKey] = gridState
        
        UserDefaults.standard.set(allProgress, forKey: currentGridConfig.puzzleProgressKey)
        UserDefaults.standard.synchronize()
        
        let isSolved = isPuzzleSolved(currentPuzzleIndex)
        NSLog("💾 Saved progress for puzzle %d (solved: %@) using key '%@' and puzzleKey '%@'", currentPuzzleIndex, isSolved ? "YES" : "NO", currentGridConfig.puzzleProgressKey, puzzleKey)
        NSLog("💾 Total saved puzzles in progress: %@", allProgress.keys.sorted().joined(separator: ", "))
    }
    
    private func loadPuzzleProgress() -> Bool {
        guard let allProgress = UserDefaults.standard.dictionary(forKey: currentGridConfig.puzzleProgressKey) as? [String: [[String]]] else {
            NSLog("📁 No saved progress found using key '%@'", currentGridConfig.puzzleProgressKey)
            return false
        }
        
        let puzzleKey = "\(currentPuzzleIndex)"
        NSLog("📁 Looking for saved progress for puzzle %d using key '%@' and puzzleKey '%@'", currentPuzzleIndex, currentGridConfig.puzzleProgressKey, puzzleKey)
        NSLog("📁 Available saved puzzles in progress: %@", allProgress.keys.sorted().joined(separator: ", "))
        
        guard let savedGridState = allProgress[puzzleKey] else {
            NSLog("📁 No saved progress for puzzle %d", currentPuzzleIndex)
            return false
        }
        
        // Restore grid state
        guard savedGridState.count == gameGrid.count else {
            NSLog("⚠️ Saved grid size mismatch, ignoring saved progress")
            return false
        }
        
        for (rowIndex, row) in savedGridState.enumerated() {
            guard row.count == gameGrid[rowIndex].count else {
                NSLog("⚠️ Saved row size mismatch, ignoring saved progress")
                return false
            }
            
            for (colIndex, cellStateString) in row.enumerated() {
                let cell = gameGrid[rowIndex][colIndex]
                
                // Don't overwrite clue cells
                if cell.isClue { continue }
                
                switch cellStateString {
                case "empty":
                    cell.state = .empty
                case "filled":
                    cell.state = .filled
                case "dot":
                    cell.state = .dot
                case "blocked":
                    cell.state = .blocked
                default:
                    cell.state = .empty
                }
                
                // Update cell visuals without saving progress (to avoid infinite loop)
                switch cell.state {
                case .empty:
                    cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    removeDotFromCell(cell)
                case .filled:
                    cell.node.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                    removeDotFromCell(cell)
                case .dot:
                    cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    addDotToCell(cell)
                case .blocked:
                    cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    removeDotFromCell(cell)
                }
            }
        }
        
        NSLog("📁 Loaded saved progress for puzzle %d", currentPuzzleIndex)
        return true
    }
    
    private func clearPuzzleProgress(_ puzzleIndex: Int) {
        var allProgress = UserDefaults.standard.dictionary(forKey: currentGridConfig.puzzleProgressKey) as? [String: [[String]]] ?? [:]
        let puzzleKey = "\(puzzleIndex)"
        let hadProgress = allProgress[puzzleKey] != nil
        allProgress.removeValue(forKey: puzzleKey)
        UserDefaults.standard.set(allProgress, forKey: currentGridConfig.puzzleProgressKey)
        NSLog("🗑️ Cleared saved progress for puzzle %d using key '%@' and puzzleKey '%@' (had progress: %@)", puzzleIndex, currentGridConfig.puzzleProgressKey, puzzleKey, hadProgress ? "YES" : "NO")
        NSLog("🗑️ Remaining saved puzzles in progress: %@", allProgress.keys.sorted().joined(separator: ", "))
    }
    
    private func getProgressStats() -> (solved: Int, total: Int, percentage: Double) {
        let solvedCount = getSolvedPuzzleCount()
        let totalCount = allPuzzles.count
        let percentage = totalCount > 0 ? Double(solvedCount) / Double(totalCount) * 100.0 : 0.0
        return (solved: solvedCount, total: totalCount, percentage: percentage)
    }
}
*/
