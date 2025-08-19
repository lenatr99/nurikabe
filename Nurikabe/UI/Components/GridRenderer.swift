//
//  GridRenderer.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Handles rendering of the game grid
class GridRenderer {
    
    static func createCell(
        for gridCell: GridCell,
        cellSize: CGFloat,
        gridSize: Int,
        puzzle: Puzzle
    ) -> SKShapeNode {
        let cellNode = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        cellNode.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        cellNode.strokeColor = AppColors.primary
        cellNode.lineWidth = 2.0
        cellNode.name = "cell_\(gridCell.row)_\(gridCell.col)"
        
        // Position the cell
        let startX = -CGFloat(gridSize - 1) * cellSize / 2
        let startY = CGFloat(gridSize - 1) * cellSize / 2
        cellNode.position = CGPoint(
            x: startX + CGFloat(gridCell.col) * cellSize,
            y: startY - CGFloat(gridCell.row) * cellSize
        )
        
        // Add number if it's a clue cell
        let clueNumber = puzzle.puzzleData[gridCell.row][gridCell.col]
        if clueNumber > 0 {
            let numberLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            numberLabel.text = "\(clueNumber)"
            numberLabel.fontSize = cellSize * 0.5
            numberLabel.fontColor = AppColors.primary
            numberLabel.verticalAlignmentMode = .center
            numberLabel.horizontalAlignmentMode = .center
            numberLabel.position = CGPoint.zero
            numberLabel.zPosition = 1
            cellNode.addChild(numberLabel)
            
            gridCell.isClue = true
            gridCell.clueNumber = clueNumber
        }
        
        gridCell.node = cellNode
        return cellNode
    }
    
    static func updateCellVisual(_ cell: GridCell, cellSize: CGFloat) {
        switch cell.state {
        case .empty:
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            removeDotFromCell(cell)
        case .filled:
            cell.node.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            removeDotFromCell(cell)
        case .dot:
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            addDotToCell(cell, cellSize: cellSize)
        case .blocked:
            cell.node.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            removeDotFromCell(cell)
        }
    }
    
    private static func addDotToCell(_ cell: GridCell, cellSize: CGFloat) {
        removeDotFromCell(cell)
        
        let dotRadius = cellSize * 0.15
        let dot = SKShapeNode(circleOfRadius: dotRadius)
        dot.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        dot.strokeColor = AppColors.primary
        dot.name = "dot"
        dot.position = CGPoint.zero
        dot.zPosition = 2
        
        cell.node.addChild(dot)
    }
    
    private static func removeDotFromCell(_ cell: GridCell) {
        cell.node.childNode(withName: "dot")?.removeFromParent()
    }
}
