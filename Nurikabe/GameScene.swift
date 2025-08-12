//
//  GameScene.swift
//  Nurikabe
//
//  Created by Lena Trnovec on 8/12/25.
//

import SpriteKit
import GameplayKit

// MARK: - Grid Cell Helper Classes
enum CellState {
    case empty
    case filled
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
    private var titleLabel: SKLabelNode!
    private var gridContainer: SKNode!
    private var gameGrid: [[GridCell]] = []
    
    private let gridSize = 7  // 7x7 Nurikabe grid
    private var cellSize: CGFloat = 0
    
    // Sample Nurikabe puzzle data (0 = empty, 1-9 = numbered clue)
    private let puzzleData: [[Int]] = [
        [0, 0, 0, 3, 0, 0, 0],
        [0, 0, 0, 0, 0, 2, 0],
        [0, 0, 0, 0, 0, 0, 0],
        [4, 0, 0, 0, 0, 0, 1],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 3, 0, 0, 0, 0, 0],
        [0, 0, 0, 2, 0, 0, 0]
    ]
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Use same background color as menu
        backgroundColor = AppColors.background
        
        setupTitle()
        setupBackButton()
        setupNurikabeGrid()
    }
    
    private func setupTitle() {
        titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        titleLabel.text = "Nurikabe Puzzle"
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
        bg.strokeColor = UIColor.white.withAlphaComponent(0.3)
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
        container.addChild(label)
        
        // Position in bottom center
        container.position = CGPoint(
            x: 0,
            y: -size.height * 0.4
        )
        
        backButton = container
        addChild(container)
    }
    
    private func setupNurikabeGrid() {
        gridContainer = SKNode()
        gridContainer.zPosition = 50
        addChild(gridContainer)
        
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
        cellNode.fillColor = UIColor.white
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle back button tap
        if let nodeName = touchedNode.name, nodeName.contains("backButton") || nodeName == "bg" {
            if let bg = backButton.childNode(withName: "bg") as? SKShapeNode {
                let press = SKAction.group([
                    .scale(to: 0.95, duration: 0.12),
                    .fadeAlpha(to: 0.85, duration: 0.12)
                ])
                bg.run(press)
            }
            return
        }
        
        // Handle grid cell taps
        if let nodeName = touchedNode.name, nodeName.hasPrefix("cell_") {
            handleCellTap(nodeName: nodeName)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle back button release
        if let nodeName = touchedNode.name, nodeName.contains("backButton") || nodeName == "bg" {
            if let bg = backButton.childNode(withName: "bg") as? SKShapeNode {
                let release = SKAction.group([
                    .scale(to: 1.0, duration: 0.15),
                    .fadeAlpha(to: 1.0, duration: 0.15)
                ])
                bg.run(release) {
                    self.returnToMenu()
                }
            }
        }
    }
    
    private func handleCellTap(nodeName: String) {
        // Parse cell coordinates from node name "cell_row_col"
        let components = nodeName.components(separatedBy: "_")
        guard components.count == 3,
              let row = Int(components[1]),
              let col = Int(components[2]),
              row < gridSize, col < gridSize else { return }
        
        let cell = gameGrid[row][col]
        
        // Don't allow tapping clue cells
        if cell.isClue { return }
        
        // Cycle through states: empty -> filled -> blocked -> empty
        switch cell.state {
        case .empty:
            cell.state = .filled
            cell.node.fillColor = AppColors.primary
        case .filled:
            cell.state = .blocked
            cell.node.fillColor = UIColor.black
        case .blocked:
            cell.state = .empty
            cell.node.fillColor = UIColor.white
        }
    }
    
    private func returnToMenu() {
        guard let view = view else { return }
        
        let menuScene = MenuScene(size: view.bounds.size)
        menuScene.scaleMode = .aspectFill
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(menuScene, transition: transition)
    }
}
