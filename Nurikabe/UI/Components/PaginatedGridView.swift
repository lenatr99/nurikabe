//
//  PaginatedGridView.swift
//  Nurikabe
//
//  Created by Assistant on 8/16/25.
//

import SpriteKit

/// A modular and reusable paginated grid view component for SpriteKit
/// Inspired by Unity UI Extensions Horizontal Scroll Snap pattern
class PaginatedGridView: SKNode {
    
    // MARK: - Configuration
    
    struct Configuration {
        let itemsPerPage: Int
        let itemSize: CGSize
        let itemSpacing: CGFloat
        let pageSpacing: CGFloat
        let showArrows: Bool
        let animationDuration: TimeInterval
        
        static let defaultConfig = Configuration(
            itemsPerPage: 20, // 4x5 grid
            itemSize: CGSize(width: 80, height: 80),
            itemSpacing: 12,
            pageSpacing: 40,
            showArrows: true,
            animationDuration: 0.3
        )
    }
    
    // MARK: - Properties
    
    private let config: Configuration
    private var pages: [SKNode] = []
    private var currentPageIndex: Int = 0
    private var totalPages: Int = 0
    private var viewSize: CGSize = CGSize.zero
    
    // UI Components
    private var containerNode: SKNode!
    private var pagesContainer: SKNode!
    private var leftArrow: SKNode?
    private var rightArrow: SKNode?
    
    // Touch handling
    private var initialTouchX: CGFloat = 0
    private var isDragging = false
    private var dragThreshold: CGFloat = 20
    private var snapThreshold: CGFloat = 0.1 // 10% of page width

    private var paginationSize: CGSize {
        return CGSize(width: 50, height: 50)
    }
    
    // Callbacks
    var onItemTapped: ((Int) -> Void)?
    var onPageChanged: ((Int) -> Void)?
    
    // MARK: - Initialization
    
    init(configuration: Configuration = Configuration.defaultConfig) {
        self.config = configuration
        super.init()
        setupContainer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupContainer() {
        containerNode = SKNode()
        addChild(containerNode)
        
        pagesContainer = SKNode()
        containerNode.addChild(pagesContainer)
    }
    
    private func setupArrows() {
        // Left arrow - positioned to the left side
        leftArrow = createArrowButton(direction: .left)
        leftArrow?.position = CGPoint(x: -50, y: -(2.5 * config.itemSize.height + 3 * config.itemSpacing + paginationSize.height/2))
        leftArrow?.name = "leftArrow"
        containerNode.addChild(leftArrow!)
        
        // Right arrow - positioned to the right side
        rightArrow = createArrowButton(direction: .right)
        rightArrow?.position = CGPoint(x: 50, y: -(2.5 * config.itemSize.height + 3 * config.itemSpacing + paginationSize.height/2))
        rightArrow?.name = "rightArrow"
        containerNode.addChild(rightArrow!)
        
        updateArrowStates()
    }
    
    private func createArrowButton(direction: ArrowDirection) -> SKNode {
        let button = SKNode()
        
        // Background circle
        let background = SKShapeNode(rectOf: paginationSize)
        background.fillColor = AppColors.primary
        background.strokeColor = .clear
        button.addChild(background)
        
        // Arrow symbol
        let arrow = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        arrow.text = direction == .left ? "‹" : "›"
        arrow.fontSize = 60
        arrow.fontColor = AppColors.secondary
        arrow.verticalAlignmentMode = .center
        arrow.horizontalAlignmentMode = .center
        button.addChild(arrow)
        
        return button
    }
    
    private enum ArrowDirection {
        case left, right
    }
    
    // MARK: - Public Interface
    
    func setViewSize(_ size: CGSize) {
        viewSize = size
        
        // Setup arrows now that we have the view size
        if config.showArrows {
            setupArrows()
        }
    }
    
    func loadItems<T>(_ items: [T], itemBuilder: (T, Int, CGPoint) -> SKNode) {
        clearPages()
        
        let itemsPerPage = config.itemsPerPage
        totalPages = (items.count + itemsPerPage - 1) / itemsPerPage
        
        for pageIndex in 0..<totalPages {
            let page = createPage(
                items,
                pageIndex: pageIndex,
                itemsPerPage: itemsPerPage,
                itemBuilder: itemBuilder
            )
            pages.append(page)
            pagesContainer.addChild(page)
        }
        
        layoutPages()
        updateArrowStates()
        setCurrentPage(0, animated: false)
    }
    
    private func createPage<T>(_ items: [T], pageIndex: Int, itemsPerPage: Int, itemBuilder: (T, Int, CGPoint) -> SKNode) -> SKNode {
        let page = SKNode()
        page.name = "page_\(pageIndex)"
        
        let startIndex = pageIndex * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, items.count)
        
        let itemsInPage = endIndex - startIndex
        let rows = 5 // 4x5 grid means 5 rows
        let cols = 4 // 4x5 grid means 4 columns
        
        for i in 0..<itemsInPage {
            let itemIndex = startIndex + i
            let row = i / cols
            let col = i % cols
            
            // Calculate position for 4x5 grid
            let totalWidth = CGFloat(cols - 1) * (config.itemSize.width + config.itemSpacing)
            let totalHeight = CGFloat(rows - 1) * (config.itemSize.height + config.itemSpacing)
            
            let x = -totalWidth / 2 + CGFloat(col) * (config.itemSize.width + config.itemSpacing)
            let y = totalHeight / 2 - CGFloat(row) * (config.itemSize.height + config.itemSpacing)
            
            let position = CGPoint(x: x, y: y)
            let itemNode = itemBuilder(items[itemIndex], itemIndex, position)
            // Don't override the name here - let the itemBuilder set the proper name
            // This allows level tiles to use "levelTile_" naming and other items to use "item_"
            if itemNode.name == nil {
                itemNode.name = "item_\(itemIndex)"
            }
            
            page.addChild(itemNode)
        }
        
        return page
    }
    
    private func layoutPages() {
        let pageWidth = viewSize.width
        
        for (index, page) in pages.enumerated() {
            page.position.x = CGFloat(index) * pageWidth
        }
    }
    
    // MARK: - Navigation
    
    func setCurrentPage(_ pageIndex: Int, animated: Bool = true) {
        guard pageIndex >= 0 && pageIndex < totalPages else { return }
        
        let previousPage = currentPageIndex
        currentPageIndex = pageIndex
        
        let targetX = -CGFloat(currentPageIndex) * (viewSize.width)
        
        if animated {
            let moveAction = SKAction.moveTo(x: targetX, duration: config.animationDuration)
            moveAction.timingMode = .easeInEaseOut
            pagesContainer.run(moveAction)
        } else {
            pagesContainer.position.x = targetX
        }
        
        updateArrowStates()
        
        if previousPage != currentPageIndex {
            onPageChanged?(currentPageIndex)
        }
    }
    
    func nextPage() {
        if currentPageIndex < totalPages - 1 {
            setCurrentPage(currentPageIndex + 1)
        }
    }
    
    func previousPage() {
        if currentPageIndex > 0 {
            setCurrentPage(currentPageIndex - 1)
        }
    }
    
    private func updateArrowStates() {
        leftArrow?.alpha = currentPageIndex > 0 ? 0.8 : 0.3
        rightArrow?.alpha = currentPageIndex < totalPages - 1 ? 0.8 : 0.3
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check arrow touches
        if let leftArrow = leftArrow, leftArrow.contains(location) {
            animateButtonPress(leftArrow)
            return
        }
        
        if let rightArrow = rightArrow, rightArrow.contains(location) {
            animateButtonPress(rightArrow)
            return
        }
        
        // Start drag tracking
        initialTouchX = location.x
        isDragging = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let deltaX = location.x - initialTouchX
        
        if abs(deltaX) > dragThreshold {
            isDragging = true
        }
        
        if isDragging {
            // Apply drag directly - reduced resistance for better responsiveness
            let baseX = -CGFloat(currentPageIndex) * viewSize.width
            let targetX = baseX + deltaX * 0.8
            pagesContainer.position.x = targetX
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Handle arrow touches
        if let leftArrow = leftArrow, leftArrow.contains(location) {
            animateButtonRelease(leftArrow) {
                self.previousPage()
            }
            return
        }
        
        if let rightArrow = rightArrow, rightArrow.contains(location) {
            animateButtonRelease(rightArrow) {
                self.nextPage()
            }
            return
        }
        
        if isDragging {
            handleDragEnd()
        } else {
            handleItemTap(at: location)
        }
        
        isDragging = false
    }
    
    private func handleDragEnd() {
        let currentExpectedX = -CGFloat(currentPageIndex) * viewSize.width
        let actualX = pagesContainer.position.x
        let deltaX = actualX - currentExpectedX
        let pageWidth = viewSize.width
        
        let dragRatio = deltaX / pageWidth
        
        // If dragged more than threshold to the right and not on first page, go to previous page
        if dragRatio > snapThreshold && currentPageIndex > 0 {
            previousPage()
        }
        // If dragged more than threshold to the left and not on last page, go to next page  
        else if dragRatio < -snapThreshold && currentPageIndex < totalPages - 1 {
            nextPage()
        } 
        // Otherwise snap back to current page
        else {
            setCurrentPage(currentPageIndex, animated: true)
        }
    }
    
    private func handleItemTap(at location: CGPoint) {
        let currentPage = pages[currentPageIndex]
        let localLocation = convert(location, to: currentPage)
        let tappedNode = currentPage.atPoint(localLocation)
        
        NSLog("🔍 Touch at location: \(location), localLocation: \(localLocation), currentPage: \(currentPageIndex)")
        NSLog("🎯 Page \(currentPageIndex): tappedNode: \(tappedNode.name ?? "nil")")
        
        // Look up the node hierarchy to find the correct item container
        var currentNode: SKNode? = tappedNode
        while currentNode != nil {
            NSLog("🔍 Checking node: \(currentNode?.name ?? "nil")")
            if let nodeName = currentNode?.name,
               nodeName.hasPrefix("levelTile_"),
               let itemIndex = Int(String(nodeName.dropFirst("levelTile_".count))) {
                NSLog("✅ Found level tile: \(itemIndex)")
                onItemTapped?(itemIndex)
                return
            }
            // Also check for the old item_ naming convention for compatibility
            if let nodeName = currentNode?.name,
               nodeName.hasPrefix("item_"),
               let itemIndex = Int(String(nodeName.dropFirst("item_".count))) {
                NSLog("✅ Found item: \(itemIndex)")
                onItemTapped?(itemIndex)
                return
            }
            currentNode = currentNode?.parent
        }
        NSLog("❌ No valid item found")
    }
    
    // MARK: - Animation Helpers
    
    private func animateButtonPress(_ button: SKNode) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        button.run(scaleDown)
    }
    
    private func animateButtonRelease(_ button: SKNode, completion: @escaping () -> Void) {
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let action = SKAction.sequence([scaleUp, SKAction.run(completion)])
        button.run(action)
    }
    
    // MARK: - Cleanup
    
    private func clearPages() {
        pages.forEach { $0.removeFromParent() }
        pages.removeAll()
        currentPageIndex = 0
        totalPages = 0
    }
    
    // MARK: - Computed Properties
    
    var currentPage: Int {
        return currentPageIndex
    }
    
    var configuration: Configuration {
        return config
    }
    
    var pageCount: Int {
        return totalPages
    }
}
