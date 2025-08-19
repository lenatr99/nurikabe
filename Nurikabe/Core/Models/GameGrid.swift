//
//  GameGrid.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import Foundation

/// Manages the game grid state and operations
class GameGrid {
    private(set) var cells: [[GridCell]]
    private(set) var size: Int
    
    init(size: Int) {
        self.size = size
        self.cells = []
        initializeGrid()
    }
    
    private func initializeGrid() {
        cells = Array(repeating: Array(repeating: GridCell(row: 0, col: 0), count: size), count: size)
        
        for row in 0..<size {
            for col in 0..<size {
                cells[row][col] = GridCell(row: row, col: col)
            }
        }
    }
    
    func getCell(row: Int, col: Int) -> GridCell? {
        guard row >= 0, row < size, col >= 0, col < size else { return nil }
        return cells[row][col]
    }
    
    func setCellState(row: Int, col: Int, state: CellState) {
        guard let cell = getCell(row: row, col: col), !cell.isClue else { return }
        cell.state = state
    }
    
    func resetNonClueCell(row: Int, col: Int) {
        guard let cell = getCell(row: row, col: col), !cell.isClue else { return }
        cell.state = .empty
    }
    
    func resetAllNonClueCells() {
        for row in 0..<size {
            for col in 0..<size {
                resetNonClueCell(row: row, col: col)
            }
        }
    }
    
    func setupPuzzle(_ puzzle: Puzzle) {
        self.size = puzzle.gridSize
        initializeGrid()
        
        for row in 0..<size {
            for col in 0..<size {
                let cell = cells[row][col]
                let clueNumber = puzzle.puzzleData[row][col]
                
                if clueNumber > 0 {
                    cell.isClue = true
                    cell.clueNumber = clueNumber
                }
            }
        }
    }
}
