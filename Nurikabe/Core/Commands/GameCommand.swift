//
//  GameCommand.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import Foundation

/// Protocol for all undoable game actions
protocol GameCommand {
    /// Execute the command
    func execute()
    
    /// Undo the command, reverting its effects
    func undo()
    
    /// Description of the command for debugging
    var description: String { get }
}
