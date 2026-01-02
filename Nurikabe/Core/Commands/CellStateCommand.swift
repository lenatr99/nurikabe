//
//  CellStateCommand.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import Foundation

/// Command for changing a single cell's state
class CellStateCommand: GameCommand {
    private let gameGrid: GameGrid
    private let row: Int
    private let col: Int
    private let newState: CellState
    private let oldState: CellState
    
    init(gameGrid: GameGrid, row: Int, col: Int, newState: CellState) {
        self.gameGrid = gameGrid
        self.row = row
        self.col = col
        self.newState = newState
        
        // Store the current state as the old state
        if let cell = gameGrid.getCell(row: row, col: col) {
            self.oldState = cell.state
        } else {
            self.oldState = .empty
        }
    }
    
    func execute() {
        gameGrid.setCellState(row: row, col: col, state: newState)
    }
    
    func undo() {
        gameGrid.setCellState(row: row, col: col, state: oldState)
    }
    
    var description: String {
        return "Cell(\(row),\(col)): \(oldState) -> \(newState)"
    }
}
