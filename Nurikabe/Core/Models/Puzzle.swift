//
//  Puzzle.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import Foundation

/// Represents a single Nurikabe puzzle
struct Puzzle {
    let index: Int
    let gridSize: Int
    let puzzleData: [[Int]]
    let solutionData: [String]
    
    init(index: Int, puzzleString: String, solutionString: String) {
        self.index = index
        
        let components = puzzleString.components(separatedBy: ":")
        guard components.count == 2 else {
            self.gridSize = 5
            self.puzzleData = []
            self.solutionData = []
            return
        }
        
        // Parse size from "5x5"
        let sizeComponents = components[0].components(separatedBy: "x")
        guard sizeComponents.count == 2,
              let width = Int(sizeComponents[0]),
              let height = Int(sizeComponents[1]) else {
            self.gridSize = 5
            self.puzzleData = []
            self.solutionData = []
            return
        }
        
        self.gridSize = width
        
        // Parse puzzle data
        let dataString = components[1]
        let cellStrings = dataString.components(separatedBy: ",")
        
        var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: width), count: height)
        
        for (index, cellString) in cellStrings.enumerated() {
            let row = index / width
            let col = index % width
            
            if row < height && col < width {
                if cellString == "-" {
                    grid[row][col] = 0
                } else if let number = Int(cellString) {
                    grid[row][col] = number
                }
            }
        }
        
        self.puzzleData = grid
        self.solutionData = solutionString.components(separatedBy: ",").filter { !$0.isEmpty }
    }
}
