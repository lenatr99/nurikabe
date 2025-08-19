//
//  GridCell.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Represents a single cell in the game grid
class GridCell {
    var node: SKShapeNode!
    var row: Int = 0
    var col: Int = 0
    var state: CellState = .empty
    var isClue: Bool = false
    var clueNumber: Int = 0
    
    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}
