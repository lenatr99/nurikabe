//
//  GameConfig.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import Foundation

struct GameConfig {
    
    // MARK: - Grid Size Configuration
    
    struct GridSizeConfig {
        let displayName: String
        let filename: String
        let isAvailable: Bool
        let solvedPuzzlesKey: String
        let puzzleProgressKey: String
        
        init(displayName: String, filename: String, isAvailable: Bool = true) {
            self.displayName = displayName
            self.filename = filename
            self.isAvailable = isAvailable
            self.solvedPuzzlesKey = "NurikabeSolvedPuzzles_\(displayName)"
            self.puzzleProgressKey = "NurikabePuzzleProgress_\(displayName)"
        }
    }
    
    // MARK: - Available Grid Sizes
    
    static let gridSizes: [GridSizeConfig] = [
        GridSizeConfig(displayName: "5x5", filename: "nurikabes_5x5_easy"),
        GridSizeConfig(displayName: "10x10", filename: "nurikabes_10x10_easy"),
        GridSizeConfig(displayName: "15x15", filename: "nurikabes_15x15_medium")
    ]
    
    // MARK: - Helper Methods
    
    static func getConfig(for filename: String) -> GridSizeConfig? {
        return gridSizes.first { $0.filename == filename }
    }
    
    static func getConfigByDisplayName(_ displayName: String) -> GridSizeConfig? {
        return gridSizes.first { $0.displayName == displayName }
    }
    
    static func getConfigByIndex(_ index: Int) -> GridSizeConfig? {
        guard index >= 0 && index < gridSizes.count else { return nil }
        return gridSizes[index]
    }
}
