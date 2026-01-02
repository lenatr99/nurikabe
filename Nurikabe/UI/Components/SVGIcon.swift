//
//  SVGIcon.swift
//  Nurikabe
//
//  Created by Assistant on 9/19/25.
//

import SpriteKit
import UIKit

/// Utility for rendering SVG icons as SpriteKit nodes
class SVGIcon {
    
    /// Create an SKNode from an SVG file
    static func createIcon(named iconName: String, size: CGFloat, color: UIColor = .white) -> SKNode? {
        guard let svgPath = Bundle.main.path(forResource: iconName, ofType: "svg", inDirectory: "Resources/Icons") else {
            print("❌ SVG icon not found: \(iconName)")
            return nil
        }
        
        guard let svgData = NSData(contentsOfFile: svgPath) else {
            print("❌ Could not read SVG data for: \(iconName)")
            return nil
        }
        
        // Convert SVG to UIImage
        guard let image = svgToUIImage(data: svgData as Data, size: CGSize(width: size, height: size), color: color) else {
            print("❌ Could not convert SVG to image: \(iconName)")
            return nil
        }
        
        // Create texture and sprite
        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: size, height: size)
        
        return sprite
    }
    
    /// Convert SVG data to UIImage
    private static func svgToUIImage(data: Data, size: CGSize, color: UIColor) -> UIImage? {
        // Simple SVG to UIImage conversion
        // This is a basic implementation - for production, consider using a dedicated SVG library
        
        guard let svgString = String(data: data, encoding: .utf8) else { return nil }
        
        // Extract path data from SVG
        guard let pathData = extractPathFromSVG(svgString) else { return nil }
        
        // Create UIImage from path
        return createImageFromPath(pathData, size: size, color: color)
    }
    
    /// Extract path data from SVG string
    private static func extractPathFromSVG(_ svgString: String) -> String? {
        // Find path element
        guard let pathStart = svgString.range(of: "<path d=\"") else { return nil }
        let pathContentStart = pathStart.upperBound
        
        guard let pathEnd = svgString.range(of: "\"", range: pathContentStart..<svgString.endIndex) else { return nil }
        
        return String(svgString[pathContentStart..<pathEnd.lowerBound])
    }
    
    /// Create UIImage from SVG path data
    private static func createImageFromPath(_ pathData: String, size: CGSize, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Create path from SVG path data
        guard let path = createBezierPath(from: pathData, size: size) else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // Fill with color
        context.setFillColor(color.cgColor)
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /// Create UIBezierPath from SVG path data (simplified implementation)
    private static func createBezierPath(from pathData: String, size: CGSize) -> UIBezierPath? {
        let path = UIBezierPath()
        
        // This is a simplified parser for basic SVG paths
        // For production, use a proper SVG parsing library
        let commands = parsePathCommands(pathData)
        
        for command in commands {
            switch command.type {
            case "M":
                if let point = command.points.first {
                    let scaledPoint = scalePoint(point, from: CGSize(width: 18, height: 18), to: size)
                    path.move(to: scaledPoint)
                }
            case "L":
                if let point = command.points.first {
                    let scaledPoint = scalePoint(point, from: CGSize(width: 18, height: 18), to: size)
                    path.addLine(to: scaledPoint)
                }
            case "Z":
                path.close()
            default:
                break
            }
        }
        
        return path
    }
    
    /// Scale point from source size to target size
    private static func scalePoint(_ point: CGPoint, from sourceSize: CGSize, to targetSize: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * (targetSize.width / sourceSize.width),
            y: point.y * (targetSize.height / sourceSize.height)
        )
    }
    
    /// Parse SVG path commands (simplified)
    private static func parsePathCommands(_ pathData: String) -> [PathCommand] {
        // This is a very basic implementation
        // For better SVG support, use a dedicated library
        var commands: [PathCommand] = []
        
        let scanner = Scanner(string: pathData)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
        
        while !scanner.isAtEnd {
            if let commandChar = scanner.scanCharacter(),
               let command = parseCommand(commandChar, scanner: scanner) {
                commands.append(command)
            }
        }
        
        return commands
    }
    
    /// Parse individual path command
    private static func parseCommand(_ char: Character, scanner: Scanner) -> PathCommand? {
        let type = String(char).uppercased()
        var points: [CGPoint] = []
        
        switch type {
        case "M", "L":
            if let x = scanner.scanDouble(), let y = scanner.scanDouble() {
                points.append(CGPoint(x: x, y: y))
            }
        case "Z":
            break
        default:
            // Skip unknown commands
        // Skip unknown commands by consuming characters until next letter
        while !scanner.isAtEnd {
            if let char = scanner.scanCharacter() {
                if char.isLetter {
                    // Put the letter back for next command
                    scanner.currentIndex = scanner.string.index(before: scanner.currentIndex)
                    break
                }
            }
        }
        }
        
        return PathCommand(type: type, points: points)
    }
}

/// Helper struct for SVG path commands
private struct PathCommand {
    let type: String
    let points: [CGPoint]
}

/// Fallback icon creation for when SVG parsing fails
extension SVGIcon {
    
    /// Create a fallback text-based icon
    static func createFallbackIcon(text: String, size: CGFloat, color: UIColor = .white) -> SKNode {
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        label.text = text
        label.fontSize = size * 0.6
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        return label
    }
}
