//
//  HintProvider.swift
//  Nurikabe
//
//  Created by Assistant on 1/2/26.
//

import Foundation

/// Provides hints for Nurikabe puzzles by comparing current state with solution
class HintProvider {
    
    /// Represents a single hint for the player
    struct Hint {
        let row: Int
        let col: Int
        let correctState: CellState
        let message: String
    }
    
    /// Find a cell that is incorrectly filled and return a hint
    /// Prioritizes cells that are wrong over cells that are empty
    /// - Parameters:
    ///   - grid: Current game grid state
    ///   - puzzle: The puzzle with solution data
    /// - Returns: A hint for an incorrect cell, or nil if puzzle is solved
    static func getHint(grid: GameGrid, puzzle: Puzzle) -> Hint? {
        guard puzzle.solutionData.count == grid.size * grid.size else {
            NSLog("❌ HintProvider: Solution data size mismatch")
            return nil
        }
        
        var wrongCells: [(row: Int, col: Int, correctState: CellState)] = []
        var emptyCells: [(row: Int, col: Int, correctState: CellState)] = []
        
        for row in 0..<grid.size {
            for col in 0..<grid.size {
                let index = row * grid.size + col
                let cell = grid.cells[row][col]
                let expectedSymbol = puzzle.solutionData[index]
                
                // Skip clue cells
                if cell.isClue { continue }
                
                // Check if cell is wrong
                if expectedSymbol == "#" {
                    // Should be water (filled)
                    if cell.state == .empty || cell.state == .dot {
                        emptyCells.append((row, col, .filled))
                    } else if cell.state != .filled {
                        wrongCells.append((row, col, .filled))
                    }
                } else if expectedSymbol == "*" {
                    // Should be island (empty/dot)
                    if cell.state == .filled {
                        wrongCells.append((row, col, .dot))
                    }
                    // empty or dot is correct for islands
                }
            }
        }
        
        // Prioritize wrong cells over empty cells
        if let wrongCell = wrongCells.randomElement() {
            let message = wrongCell.correctState == .filled
                ? "This cell should be water (filled)"
                : "This cell should be part of an island"
            
            return Hint(
                row: wrongCell.row,
                col: wrongCell.col,
                correctState: wrongCell.correctState,
                message: message
            )
        }
        
        if let emptyCell = emptyCells.randomElement() {
            let message = emptyCell.correctState == .filled
                ? "Try filling this cell with water"
                : "This cell is part of an island"
            
            return Hint(
                row: emptyCell.row,
                col: emptyCell.col,
                correctState: emptyCell.correctState,
                message: message
            )
        }
        
        // No hints needed - puzzle is likely solved
        return nil
    }
    
}

