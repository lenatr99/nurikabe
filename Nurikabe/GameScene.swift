//
//  GameScene.swift
//  Nurikabe
//
//  Created by Lena Trnovec on 8/12/25.
//

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
    }
    
    private func loadPuzzleData() {
        // Load puzzle data from JSON file
        guard let path = Bundle(for: GameScene.self).path(forResource: "nurikabes", ofType: "json") else {
            NSLog("❌ ERROR: nurikabes.json file not found in bundle")
            showErrorAndReturnToMenu("JSON file not found")
            return
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            NSLog("❌ ERROR: Could not read nurikabes.json file")
            showErrorAndReturnToMenu("Could not read JSON file")
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            NSLog("❌ ERROR: Invalid JSON format in nurikabes.json")
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
        let buttonWidth: CGFloat = 120
        let buttonHeight: CGFloat = 44
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        bg.name = "bg"
        bg.fillColor = AppColors.buttonBackground
        bg.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Menu"
        label.fontSize = 18
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
        let container = SKNode()
        container.name = "submitButton"
        container.zPosition = 100
        
        // Create submit button matching back button style
        let buttonWidth: CGFloat = 120
        let buttonHeight: CGFloat = 44
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        bg.name = "bg"
        bg.fillColor = AppColors.buttonBackground
        bg.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Submit"
        label.fontSize = 18
        label.fontColor = AppColors.buttonText
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        label.position = CGPoint.zero
        label.zPosition = 1
        label.name = "submitLabel"  // Add name for better touch detection
        container.addChild(label)
        
        // Add invisible larger touch area
        let touchArea = SKShapeNode(rectOf: CGSize(width: buttonWidth + 20, height: buttonHeight + 20))
        touchArea.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        touchArea.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        touchArea.name = "submitTouchArea"
        touchArea.zPosition = 0
        container.addChild(touchArea)
        
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
        // Create solved message overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: size.height * 0.45))
        overlay.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        overlay.strokeColor = AppColors.primary
        overlay.lineWidth = 3.0
        overlay.position = CGPoint.zero
        overlay.zPosition = 200
        overlay.alpha = 0
        overlay.name = "solvedOverlay"
        
        let solvedLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        solvedLabel.text = "SOLVED!"
        solvedLabel.fontSize = 48
        solvedLabel.fontColor = AppColors.primary
        solvedLabel.verticalAlignmentMode = .center
        solvedLabel.horizontalAlignmentMode = .center
        solvedLabel.position = CGPoint(x: 0, y: 40)
        solvedLabel.zPosition = 1
        
        let congratsLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        congratsLabel.text = "Congratulations!"
        congratsLabel.fontSize = 24
        congratsLabel.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        congratsLabel.verticalAlignmentMode = .center
        congratsLabel.horizontalAlignmentMode = .center
        congratsLabel.position = CGPoint(x: 0, y: 5)
        congratsLabel.zPosition = 1
        
        // Show puzzle progress
        let progressLabel = SKLabelNode(fontNamed: "HelveticaNeue-Light")
        progressLabel.text = "Puzzle \(currentPuzzleIndex + 1) of \(allPuzzles.count)"
        progressLabel.fontSize = 18
        progressLabel.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        progressLabel.verticalAlignmentMode = .center
        progressLabel.horizontalAlignmentMode = .center
        progressLabel.position = CGPoint(x: 0, y: -25)
        progressLabel.zPosition = 1
        
        overlay.addChild(solvedLabel)
        overlay.addChild(congratsLabel)
        overlay.addChild(progressLabel)
        
        // Add Next Puzzle button (if not the last puzzle)
        if currentPuzzleIndex < allPuzzles.count - 1 {
            let nextButton = createNextPuzzleButton()
            nextButton.position = CGPoint(x: 0, y: -65)
            overlay.addChild(nextButton)
        }
        
        addChild(overlay)
        
        // Animate in
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        
        overlay.run(SKAction.group([fadeIn]))
    }
    
    private func createNextPuzzleButton() -> SKNode {
        let container = SKNode()
        container.name = "nextPuzzleButton"
        container.zPosition = 2
        
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 40
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        bg.name = "bg"
        bg.fillColor = AppColors.primary
        bg.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Next"
        label.fontSize = 16
        label.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        label.zPosition = 1
        label.name = "nextLabel"
        container.addChild(label)
        
        return container
    }
    
    private func createMenuButton() -> SKNode {
        let container = SKNode()
        container.name = "menuFromSolvedButton"
        container.zPosition = 2
        
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 40
        
        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        bg.name = "bg"
        bg.fillColor = AppColors.buttonBackground
        bg.strokeColor = AppColors.primary
        bg.lineWidth = 1.0
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = "Menu"
        label.fontSize = 16
        label.fontColor = AppColors.primary
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        label.zPosition = 1
        label.name = "menuLabel"
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
        
        // Handle submit button tap - improved detection
        if let nodeName = touchedNode.name {
            if nodeName.contains("submit") || touchedNode.parent?.name == "submitButton" {
                if !isSubmitEnabled {
                    NSLog("⚠️ Submit button disabled - puzzle already solved")
                    return
                }
                NSLog("🔘 Submit button touched! Node: %@", nodeName)
                if let bg = submitButton.childNode(withName: "bg") as? SKShapeNode {
                    let press = SKAction.group([
                        .scale(to: 0.95, duration: 0.12),
                        .fadeAlpha(to: 0.85, duration: 0.12)
                    ])
                    bg.run(press)
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
        
        // Handle submit button release - improved detection
        if let nodeName = touchedNode.name {
            if nodeName.contains("submit") || touchedNode.parent?.name == "submitButton" {
                if !isSubmitEnabled {
                    NSLog("⚠️ Submit button disabled - ignoring release")
                    return
                }
                NSLog("🔘 Submit button released! Node: %@", nodeName)
                if let bg = submitButton.childNode(withName: "bg") as? SKShapeNode {
                    let release = SKAction.group([
                        .scale(to: 1.0, duration: 0.15),
                        .fadeAlpha(to: 1.0, duration: 0.15)
                    ])
                    bg.run(release) {
                        self.handleSubmit()
                    }
                } else {
                    // If bg animation fails, still call handleSubmit
                    handleSubmit()
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
        if let button = childNode(withName: "//\(buttonName)") as? SKNode,
           let bg = button.childNode(withName: "bg") as? SKShapeNode {
            let press = SKAction.group([
                .scale(to: 0.95, duration: 0.12),
                .fadeAlpha(to: 0.85, duration: 0.12)
            ])
            bg.run(press)
        }
    }
    
    private func animateButtonRelease(buttonName: String, completion: @escaping () -> Void) {
        if let button = childNode(withName: "//\(buttonName)") as? SKNode,
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
        
        // Re-enable submit button for new puzzle
        isSubmitEnabled = true
        updateSubmitButtonAppearance()
        
        // Move to next puzzle
        currentPuzzleIndex += 1
        
        // Wrap around if we've reached the end
        if currentPuzzleIndex >= allPuzzles.count {
            currentPuzzleIndex = 0
            NSLog("🔄 Wrapped around to first puzzle")
        }
        
        // Load the new puzzle
        loadPuzzleAtIndex(currentPuzzleIndex)
        
        // Reset the grid
        resetGrid()
        
        // Update the title to show current puzzle number
        updateTitle()
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
        titleLabel.text = "Nurikabe \(currentPuzzleIndex + 1)/\(allPuzzles.count)"
    }
    
    private func updateSubmitButtonAppearance() {
        if isSubmitEnabled {
            // Enabled state - show the button
            submitButton.isHidden = false
            NSLog("✅ Submit button shown")
        } else {
            // Disabled state - hide the button completely
            submitButton.isHidden = true
            NSLog("🙈 Submit button hidden")
        }
    }
    
    private func handleSubmit() {
        NSLog("🔘 Submit button pressed")
        if checkSolution() {
            NSLog("🎉 Puzzle solved correctly!")
            // Disable submit button to prevent multiple submissions
            isSubmitEnabled = false
            updateSubmitButtonAppearance()
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
    
    private func handleCellTap(nodeName: String) {
        // Parse cell coordinates from node name "cell_row_col"
        let components = nodeName.components(separatedBy: "_")
        guard components.count == 3,
              let row = Int(components[1]),
              let col = Int(components[2]),
              row < gridSize, col < gridSize else { 
            NSLog("❌ Invalid cell tap: %@", nodeName)
            return 
        }
        
        let cell = gameGrid[row][col]
        
        // Don't allow tapping clue cells
        if cell.isClue { 
            NSLog("⚠️ Attempted to tap clue cell at (%d,%d)", row, col)
            return 
        }
        
        let oldState = cell.state
        NSLog("🔘 Cell tap at (%d,%d): %@ → ", row, col, String(describing: oldState))
        
        // Cycle through states: empty -> filled -> dot -> empty
        switch cell.state {
        case .empty:
            cell.state = .filled
            cell.node.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            removeDotFromCell(cell)
            NSLog("   → filled")
        case .filled:
            cell.state = .dot
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            addDotToCell(cell)
            NSLog("   → dot")
        case .dot:
            cell.state = .empty
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            removeDotFromCell(cell)
            NSLog("   → empty")
        case .blocked:
            // This case should not be reached in normal gameplay, but handle it just in case
            cell.state = .empty
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            removeDotFromCell(cell)
            NSLog("   → empty (from blocked)")
        }
        
        // Verify the state change actually happened
        NSLog("✅ Final state: %@", String(describing: cell.state))
    }
    
    private func returnToMenu() {
        guard let view = view else { return }
        
        let menuScene = MenuScene(size: view.bounds.size)
        menuScene.scaleMode = .aspectFill
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(menuScene, transition: transition)
    }
}
