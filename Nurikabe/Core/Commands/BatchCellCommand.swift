//
//  BatchCellCommand.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import Foundation

/// Command for changing multiple cells' states in a single undoable action
class BatchCellCommand: GameCommand, NoOpAware {
    private let gameGrid: GameGrid
    private var cellCommands: [CellStateCommand] = []
    
    init(gameGrid: GameGrid) {
        self.gameGrid = gameGrid
    }
    
    /// Add a cell state change to this batch
    func addCellChange(row: Int, col: Int, newState: CellState) {
        let command = CellStateCommand(gameGrid: gameGrid, row: row, col: col, newState: newState)
        cellCommands.append(command)
    }
    
    /// Check if this batch is empty
    var isEmpty: Bool {
        return cellCommands.isEmpty
    }

    // MARK: - NoOpAware
    var isNoOp: Bool { return cellCommands.isEmpty }
    
    func execute() {
        for command in cellCommands {
            command.execute()
        }
    }
    
    func undo() {
        // Undo in reverse order
        for command in cellCommands.reversed() {
            command.undo()
        }
    }
    
    var description: String {
        return "BatchCommand: \(cellCommands.count) cell changes"
    }
}
