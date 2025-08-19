//
//  SolutionChecker.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import Foundation

/// Handles checking if a puzzle solution is correct
class SolutionChecker {
    
    static func checkSolution(grid: GameGrid, puzzle: Puzzle) -> Bool {
        NSLog("🔍 CHECKING SOLUTION...")
        NSLog("Grid size: \(grid.size)x\(grid.size)")
        NSLog("Solution data count: \(puzzle.solutionData.count)")
        NSLog("Expected count: \(grid.size * grid.size)")
        
        guard puzzle.solutionData.count == grid.size * grid.size else {
            NSLog("❌ Solution data size mismatch: expected \(grid.size * grid.size), got \(puzzle.solutionData.count)")
            return false
        }
        
        var correctCells = 0
        var totalNonClueCells = 0
        
        for row in 0..<grid.size {
            for col in 0..<grid.size {
                let index = row * grid.size + col
                let cell = grid.cells[row][col]
                let expectedSymbol = puzzle.solutionData[index]
                
                NSLog("Cell (\(row),\(col)): current=\(cell.state), expected='\(expectedSymbol)', isClue=\(cell.isClue)")
                
                // Skip clue cells - they are always correct
                if cell.isClue {
                    NSLog("  ✅ Clue cell - always correct")
                    continue
                }
                
                totalNonClueCells += 1
                
                // Check if water positions match
                if expectedSymbol == "#" {
                    // Should be water (filled/black)
                    if cell.state == .filled {
                        NSLog("  ✅ Water cell correct")
                        correctCells += 1
                    } else {
                        NSLog("  ❌ Water mismatch: expected water (filled), got \(cell.state)")
                        return false
                    }
                } else if expectedSymbol == "*" {
                    // Should be island (empty or dot)
                    if cell.state == .empty || cell.state == .dot {
                        NSLog("  ✅ Island cell correct")
                        correctCells += 1
                    } else {
                        NSLog("  ❌ Island mismatch: expected island (empty/dot), got \(cell.state)")
                        return false
                    }
                } else {
                    NSLog("  ⚠️  Unexpected symbol in solution: '\(expectedSymbol)'")
                }
            }
        }
        
        NSLog("\n📊 SUMMARY:")
        NSLog("Correct cells: \(correctCells)/\(totalNonClueCells)")
        NSLog("Result: \(correctCells == totalNonClueCells ? "✅ SOLVED!" : "❌ Not solved")")
        
        return correctCells == totalNonClueCells
    }
}
