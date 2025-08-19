//
//  TouchUtils.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// Utility functions for touch handling
struct TouchUtils {
    
    /// Finds the button ancestor of a touched node
    static func findButtonAncestor(_ node: SKNode, validButtonNames: [String]) -> SKNode? {
        // Check if this node itself is a button container
        if let nodeName = node.name, validButtonNames.contains(nodeName) {
            return node
        }
        
        // Check if this node is a child of a button (like "bg" background)
        if let parent = node.parent, let parentName = parent.name, validButtonNames.contains(parentName) {
            return parent
        }
        
        // Check for partial matches (for buttons that contain the name)
        if let nodeName = node.name {
            for buttonName in validButtonNames {
                if nodeName.contains(buttonName) {
                    return node
                }
            }
        }
        
        // Check parent nodes recursively
        return node.parent.flatMap { findButtonAncestor($0, validButtonNames: validButtonNames) }
    }
    
    /// Checks if a touched node is part of a specific button
    static func isTouchOnButton(_ node: SKNode, buttonName: String) -> Bool {
        if let nodeName = node.name {
            return nodeName.contains(buttonName) || node.parent?.name == buttonName
        }
        return false
    }
    
    /// Extracts coordinates from a cell node name (e.g., "cell_2_3" -> (2, 3))
    static func getCellCoordinates(from nodeName: String) -> (row: Int, col: Int)? {
        let components = nodeName.components(separatedBy: "_")
        guard components.count == 3,
              let row = Int(components[1]),
              let col = Int(components[2]) else {
            return nil
        }
        return (row, col)
    }
    
    /// Converts a touch location to grid coordinates
    static func getGridCoordinates(
        location: CGPoint,
        gridContainer: SKNode,
        gridSize: Int,
        cellSize: CGFloat
    ) -> (row: Int, col: Int)? {
        let gridLocation = gridContainer.convert(location, from: gridContainer.parent!)
        
        let startX = -CGFloat(gridSize - 1) * cellSize / 2
        let startY = CGFloat(gridSize - 1) * cellSize / 2
        
        let col = Int((gridLocation.x - startX + cellSize / 2) / cellSize)
        let row = Int((startY - gridLocation.y + cellSize / 2) / cellSize)
        
        if row >= 0 && row < gridSize && col >= 0 && col < gridSize {
            return (row, col)
        }
        return nil
    }
}
