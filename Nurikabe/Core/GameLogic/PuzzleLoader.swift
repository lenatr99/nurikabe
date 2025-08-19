//
//  PuzzleLoader.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import Foundation

/// Handles loading and parsing of puzzle data from JSON files
class PuzzleLoader {
    
    static func loadPuzzles(from filename: String) -> [Puzzle] {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
            NSLog("❌ ERROR: json file not found in bundle: \(filename).json")
            return []
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            NSLog("❌ ERROR: Could not read json file")
            return []
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            NSLog("❌ ERROR: Invalid JSON format in json")
            return []
        }
        
        guard let items = json["items"] as? [[String: Any]] else {
            NSLog("❌ ERROR: No 'items' array found in JSON")
            return []
        }
        
        var puzzles: [Puzzle] = []
        for (index, item) in items.enumerated() {
            guard let puzzleString = item["puzzle"] as? String,
                  let solutionString = item["solutionFlat"] as? String else {
                NSLog("❌ ERROR: Invalid puzzle format at index \(index)")
                continue
            }
            
            let puzzle = Puzzle(index: index, puzzleString: puzzleString, solutionString: solutionString)
            puzzles.append(puzzle)
        }
        
        NSLog("✅ Loaded \(puzzles.count) puzzles from \(filename)")
        return puzzles
    }
}
