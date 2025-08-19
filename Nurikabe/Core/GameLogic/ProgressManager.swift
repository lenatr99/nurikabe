//
//  ProgressManager.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import Foundation

/// Manages saving and loading of puzzle progress and solved states
class ProgressManager {
    private let config: GameConfig.GridSizeConfig
    
    init(config: GameConfig.GridSizeConfig) {
        self.config = config
    }
    
    // MARK: - Solved Puzzles Management
    
    func getSolvedPuzzles() -> Set<Int> {
        let solved = UserDefaults.standard.array(forKey: config.solvedPuzzlesKey) as? [Int] ?? []
        return Set(solved)
    }
    
    func markPuzzleAsSolved(_ puzzleIndex: Int) {
        var solvedPuzzles = getSolvedPuzzles()
        solvedPuzzles.insert(puzzleIndex)
        UserDefaults.standard.set(Array(solvedPuzzles), forKey: config.solvedPuzzlesKey)
        UserDefaults.standard.synchronize()
        NSLog("✅ Marked puzzle \(puzzleIndex) as solved. Total solved: \(solvedPuzzles.count)")
    }
    
    func isPuzzleSolved(_ puzzleIndex: Int) -> Bool {
        return getSolvedPuzzles().contains(puzzleIndex)
    }
    
    func getSolvedPuzzleCount() -> Int {
        return getSolvedPuzzles().count
    }
    
    // MARK: - Progress Saving/Loading
    
    func savePuzzleProgress(_ grid: GameGrid, puzzleIndex: Int) {
        var gridState: [[String]] = []
        for row in grid.cells {
            var rowState: [String] = []
            for cell in row {
                switch cell.state {
                case .empty:
                    rowState.append("empty")
                case .filled:
                    rowState.append("filled")
                case .dot:
                    rowState.append("dot")
                case .blocked:
                    rowState.append("blocked")
                }
            }
            gridState.append(rowState)
        }
        
        var allProgress = UserDefaults.standard.dictionary(forKey: config.puzzleProgressKey) as? [String: [[String]]] ?? [:]
        let puzzleKey = "\(puzzleIndex)"
        allProgress[puzzleKey] = gridState
        
        UserDefaults.standard.set(allProgress, forKey: config.puzzleProgressKey)
        UserDefaults.standard.synchronize()
        
        NSLog("💾 Saved progress for puzzle \(puzzleIndex)")
    }
    
    func loadPuzzleProgress(_ grid: GameGrid, puzzleIndex: Int) -> Bool {
        guard let allProgress = UserDefaults.standard.dictionary(forKey: config.puzzleProgressKey) as? [String: [[String]]] else {
            return false
        }
        
        let puzzleKey = "\(puzzleIndex)"
        guard let savedGridState = allProgress[puzzleKey] else {
            return false
        }
        
        guard savedGridState.count == grid.cells.count else {
            NSLog("⚠️ Saved grid size mismatch, ignoring saved progress")
            return false
        }
        
        for (rowIndex, row) in savedGridState.enumerated() {
            guard row.count == grid.cells[rowIndex].count else {
                NSLog("⚠️ Saved row size mismatch, ignoring saved progress")
                return false
            }
            
            for (colIndex, cellStateString) in row.enumerated() {
                let cell = grid.cells[rowIndex][colIndex]
                
                if cell.isClue { continue }
                
                switch cellStateString {
                case "empty":
                    cell.state = .empty
                case "filled":
                    cell.state = .filled
                case "dot":
                    cell.state = .dot
                case "blocked":
                    cell.state = .blocked
                default:
                    cell.state = .empty
                }
            }
        }
        
        NSLog("📁 Loaded saved progress for puzzle \(puzzleIndex)")
        return true
    }
    
    func clearPuzzleProgress(_ puzzleIndex: Int) {
        var allProgress = UserDefaults.standard.dictionary(forKey: config.puzzleProgressKey) as? [String: [[String]]] ?? [:]
        let puzzleKey = "\(puzzleIndex)"
        allProgress.removeValue(forKey: puzzleKey)
        UserDefaults.standard.set(allProgress, forKey: config.puzzleProgressKey)
        NSLog("🗑️ Cleared saved progress for puzzle \(puzzleIndex)")
    }
    
    func resetAllProgress() {
        UserDefaults.standard.removeObject(forKey: config.solvedPuzzlesKey)
        UserDefaults.standard.removeObject(forKey: config.puzzleProgressKey)
        UserDefaults.standard.synchronize()
        NSLog("🔄 Reset all puzzle progress")
    }
    
    // MARK: - Level Unlocking
    
    func getHighestUnlockedLevel(totalPuzzles: Int) -> Int {
        let solvedPuzzles = getSolvedPuzzles()
        
        for level in 0..<totalPuzzles {
            if level == 0 {
                continue // First level always unlocked
            }
            if !solvedPuzzles.contains(level - 1) {
                return level - 1 // Previous level not solved
            }
        }
        return totalPuzzles - 1 // All levels unlocked
    }
}
