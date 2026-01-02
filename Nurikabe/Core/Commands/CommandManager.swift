//
//  CommandManager.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import Foundation

/// Optional protocol for commands that can signal they are no-ops
protocol NoOpAware {
    var isNoOp: Bool { get }
}

/// Manages command execution and undo/redo history
class CommandManager {
    private var undoStack: [GameCommand] = []
    private var redoStack: [GameCommand] = []
    private let maxHistorySize: Int
    
    /// Callback for when undo/redo availability changes
    var onHistoryChanged: (() -> Void)?
    
    init(maxHistorySize: Int = 50) {
        self.maxHistorySize = maxHistorySize
    }
    
    /// Execute a command and add it to the undo stack
    func executeCommand(_ command: GameCommand) {
        // Skip commands that would not change state
        if let noOp = command as? NoOpAware, noOp.isNoOp {
            return
        }
        command.execute()
        
        // Add to undo stack
        undoStack.append(command)
        
        // Clear redo stack since we've performed a new action
        redoStack.removeAll()
        
        // Limit history size
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
        
        notifyHistoryChanged()
    }
    
    /// Undo the last command
    func undo() {
        guard let command = undoStack.popLast() else { return }
        
        command.undo()
        redoStack.append(command)
        
        // Limit redo stack size
        if redoStack.count > maxHistorySize {
            redoStack.removeFirst()
        }
        
        notifyHistoryChanged()
    }
    
    /// Redo the last undone command
    func redo() {
        guard let command = redoStack.popLast() else { return }
        
        command.execute()
        undoStack.append(command)
        
        // Limit undo stack size
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
        
        notifyHistoryChanged()
    }
    
    /// Clear all command history
    func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        notifyHistoryChanged()
    }
    
    /// Check if undo is available
    var canUndo: Bool {
        return !undoStack.isEmpty
    }
    
    /// Check if redo is available
    var canRedo: Bool {
        return !redoStack.isEmpty
    }
    
    /// Get the number of commands in undo history
    var undoCount: Int {
        return undoStack.count
    }
    
    /// Get the number of commands in redo history
    var redoCount: Int {
        return redoStack.count
    }
    
    private func notifyHistoryChanged() {
        onHistoryChanged?()
    }
}
