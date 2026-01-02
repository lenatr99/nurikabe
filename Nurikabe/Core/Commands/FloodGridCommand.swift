//
//  FloodGridCommand.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import Foundation

/// Command for filling the entire grid with ocean (.filled) excluding clue cells
class FloodGridCommand: GameCommand, NoOpAware {
    private let gameGrid: GameGrid
    private var previousStates: [(row: Int, col: Int, state: CellState)] = []
    private var hasAnyChange: Bool = false
    
    init(gameGrid: GameGrid) {
        self.gameGrid = gameGrid
        
        // Snapshot current states of all non-clue cells
        for row in 0..<gameGrid.size {
            for col in 0..<gameGrid.size {
                if let cell = gameGrid.getCell(row: row, col: col), !cell.isClue {
                    previousStates.append((row: row, col: col, state: cell.state))
                    if cell.state != .filled { hasAnyChange = true }
                }
            }
        }
    }
    
    func execute() {
        for row in 0..<gameGrid.size {
            for col in 0..<gameGrid.size {
                gameGrid.setCellState(row: row, col: col, state: .filled)
            }
        }
    }
    
    func undo() {
        for cellState in previousStates {
            gameGrid.setCellState(row: cellState.row, col: cellState.col, state: cellState.state)
        }
    }
    
    var description: String { "Flood Grid to ocean (.filled)" }

    // MARK: - NoOpAware
    var isNoOp: Bool { return hasAnyChange == false }
}


