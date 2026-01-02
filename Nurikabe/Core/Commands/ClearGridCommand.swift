//
//  ClearGridCommand.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import Foundation

/// Command for clearing the entire grid (excluding clue cells)
class ClearGridCommand: GameCommand, NoOpAware {
    private let gameGrid: GameGrid
    private var previousStates: [(row: Int, col: Int, state: CellState)] = []
    private var hadAnyNonEmpty: Bool = false
    
    init(gameGrid: GameGrid) {
        self.gameGrid = gameGrid
        
        // Store current states of all non-clue cells
        for row in 0..<gameGrid.size {
            for col in 0..<gameGrid.size {
                if let cell = gameGrid.getCell(row: row, col: col), !cell.isClue {
                    previousStates.append((row: row, col: col, state: cell.state))
                    if cell.state != .empty { hadAnyNonEmpty = true }
                }
            }
        }
    }
    
    func execute() {
        gameGrid.resetAllNonClueCells()
    }
    
    func undo() {
        // Restore all previous states
        for cellState in previousStates {
            gameGrid.setCellState(row: cellState.row, col: cellState.col, state: cellState.state)
        }
    }
    
    var description: String {
        return "Clear Grid: \(previousStates.count) cells cleared"
    }

    // MARK: - NoOpAware
    var isNoOp: Bool { return hadAnyNonEmpty == false }
}
