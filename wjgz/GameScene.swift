//
//  GameScene.swift
//  wjgz
//
//  Created by VincentXie on 2026/1/15.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var gridLayer: SKNode!
    private var swordLayer: SKNode!
    private var uiLayer: SKNode!
    
    // Grid Data: Map coordinate (q, r) to Sword Node
    private var grid: [String: Sword] = [:]
    
    // Dragging state
    private var draggedSword: Sword?
    private var originalPosition: CGPoint?
    private var originalGridIndex: (q: Int, r: Int)?
    
    // Game State
    private var energy: CGFloat = 0
    private var maxEnergy: CGFloat = 100
    private var score: Int = 0
    private var mergeCount: Int = 0
    private var comboCount: Int = 0
    private var currentLevel: Level!

    // UI Elements
    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var goalLabel: SKLabelNode!
    private var energyBar: SKShapeNode!
    private var ultimateButton: SKLabelNode!
    private var comboLabel: SKLabelNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)

        // Initialize level
        currentLevel = LevelConfig.shared.getCurrentLevel()

        setupLayers()
        createGrid()
        spawnInitialSwords()
        setupUI()
    }
    
    private func setupLayers() {
        gridLayer = SKNode()
        swordLayer = SKNode()
        uiLayer = SKNode()
        
        addChild(gridLayer)
        addChild(swordLayer)
        addChild(uiLayer)
        
        gridLayer.position = CGPoint(x: 0, y: 0) // Center is (0,0) in SpriteKit scene usually if configured right, but default template might be (0,0) at bottom-left.
        // We will adjust positions based on scene size.
    }
    
    private func createGrid() {
        // Hexagonal Grid Layout (Axial Coordinates)
        // Center is (0,0)
        // Radius 2 (19 cells)
        let mapRadius = 2
        
        for q in -mapRadius...mapRadius {
            let r1 = max(-mapRadius, -q - mapRadius)
            let r2 = min(mapRadius, -q + mapRadius)
            
            for r in r1...r2 {
                createTile(q: q, r: r)
            }
        }
    }
    
    private func createTile(q: Int, r: Int) {
        let pos = hexToPixel(q: q, r: r)
        
        let tile = SKShapeNode(circleOfRadius: GameConfig.tileRadius)
        tile.fillColor = SKColor(white: 0.2, alpha: 0.5)
        tile.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        tile.position = pos
        tile.name = "tile_\(q)_\(r)"
        gridLayer.addChild(tile)
    }
    
    private func hexToPixel(q: Int, r: Int) -> CGPoint {
        let size = GameConfig.tileRadius + GameConfig.gridSpacing
        let sqrt3 = sqrt(3.0)
        let qFloat = CGFloat(q)
        let rFloat = CGFloat(r)
        
        let xPart1 = sqrt3 * qFloat
        let xPart2 = (sqrt3 / 2.0) * rFloat
        let x = size * (xPart1 + xPart2)
        
        let y = size * (3.0 / 2.0 * rFloat)
        
        return CGPoint(x: x, y: y)
    }
    
    private func pixelToHex(point: CGPoint) -> (q: Int, r: Int) {
        let size = GameConfig.tileRadius + GameConfig.gridSpacing
        let q = (sqrt(3)/3 * point.x - 1.0/3 * point.y) / size
        let r = (2.0/3 * point.y) / size
        return hexRound(q: q, r: r)
    }
    
    private func hexRound(q: CGFloat, r: CGFloat) -> (Int, Int) {
        var rq = round(q)
        var rr = round(r)
        let rs = round(-q - r)
        
        let q_diff = abs(rq - q)
        let r_diff = abs(rr - r)
        let s_val = -q - r
        let s_diff = abs(rs - s_val)
        
        if q_diff > r_diff && q_diff > s_diff {
            rq = -rr - rs
        } else if r_diff > s_diff {
            rr = -rq - rs
        }
        
        return (Int(rq), Int(rr))
    }
    
    private func spawnInitialSwords() {
        // Fill more swords at start to ensure playability
        replenishSwords(fillAll: true)
    }
    
    private func replenishSwords(fillAll: Bool = false) {
        var emptySlots: [(Int, Int)] = []
        let mapRadius = 2
        for q in -mapRadius...mapRadius {
            let r1 = max(-mapRadius, -q - mapRadius)
            let r2 = min(mapRadius, -q + mapRadius)
            for r in r1...r2 {
                if grid["\(q)_\(r)"] == nil {
                    emptySlots.append((q, r))
                }
            }
        }

        let totalSlots = 19

        if !emptySlots.isEmpty {
            // If fillAll is true (like after ultimate), fill many slots. Otherwise fill 3.
            let count = fillAll ? min(emptySlots.count, 9) : min(emptySlots.count, 3)
            let slots = emptySlots.shuffled().prefix(count)

            // Ensure we spawn at least one group of 3 identical swords to avoid deadlock
            var swordTypes: [SwordType] = []
            if fillAll && count >= 3 {
                // Guarantee at least 3 fan swords
                swordTypes = [.fan, .fan, .fan]
                // Fill the rest randomly
                for _ in 3..<count {
                    let type: SwordType = Double.random(in: 0...1) < 0.8 ? .fan : .ling
                    swordTypes.append(type)
                }
                swordTypes.shuffle()
            } else {
                // Normal replenish: Mostly Fan (80%), some Ling (20%)
                for _ in 0..<count {
                    let type: SwordType = Double.random(in: 0...1) < 0.8 ? .fan : .ling
                    swordTypes.append(type)
                }
            }

            for (index, slot) in slots.enumerated() {
                spawnSword(at: slot, type: swordTypes[index])

                // Spawn animation
                if let sword = grid["\(slot.0)_\(slot.1)"] {
                    sword.setScale(0)
                    sword.run(SKAction.scale(to: 1.0, duration: 0.3))
                }
            }

            // Playability check after spawning
            performPlayabilityCheck()
        } else if grid.count >= totalSlots {
            triggerGameOver()
        }
    }
    
    private func triggerGameOver() {
        let overlay = SKShapeNode(rectOf: self.size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.8)
        overlay.zPosition = 400
        addChild(overlay)
        
        let label = SKLabelNode(text: "剑道未成")
        label.fontSize = 50
        label.fontName = "PingFangSC-Bold"
        label.position = CGPoint(x: 0, y: 50)
        label.fontColor = .white
        overlay.addChild(label)
        
        let subLabel = SKLabelNode(text: "修为: \(score)")
        subLabel.fontSize = 30
        subLabel.fontName = "PingFangSC-Regular"
        subLabel.position = CGPoint(x: 0, y: -20)
        subLabel.fontColor = .yellow
        overlay.addChild(subLabel)
        
        let restartBtn = SKLabelNode(text: "再修一局")
        restartBtn.fontSize = 40
        restartBtn.fontName = "PingFangSC-Bold"
        restartBtn.position = CGPoint(x: 0, y: -100)
        restartBtn.fontColor = .green
        restartBtn.name = "restartBtn"
        overlay.addChild(restartBtn)
    }
    
    private func restartGame() {
        // Clear grid
        grid.values.forEach { $0.removeFromParent() }
        grid.removeAll()

        // Reset stats
        score = 0
        energy = 0
        mergeCount = 0
        comboCount = 0

        // Remove overlay
        self.children.filter { $0.zPosition == 400 }.forEach { $0.removeFromParent() }

        // Reload level
        currentLevel = LevelConfig.shared.getCurrentLevel()

        // Update UI labels
        levelLabel.text = "第\(currentLevel.id)关 - \(currentLevel.name)"
        goalLabel.text = "目标: \(currentLevel.targetScore)分"
        if let mergeLabel = uiLayer.childNode(withName: "mergeLabel") as? SKLabelNode {
            mergeLabel.text = "合成: 0/\(currentLevel.targetMerges)"
        }

        updateUI()
        spawnInitialSwords()
    }

    private func restartCurrentLevel() {
        LevelConfig.shared.restartLevel()
        restartGame()
    }

    private func goToNextLevel() {
        LevelConfig.shared.goToNextLevel()
        restartGame()
    }
    
    private func spawnSword(at gridPos: (Int, Int), type: SwordType) {
        let namedPos = (q: gridPos.0, r: gridPos.1)
        let sword = Sword(type: type, gridPosition: namedPos)
        sword.position = hexToPixel(q: gridPos.0, r: gridPos.1)
        swordLayer.addChild(sword)
        
        let key = "\(gridPos.0)_\(gridPos.1)"
        grid[key] = sword
    }
    
    private func setupUI() {
        // Title Label
        let titleLabel = SKLabelNode(text: "万剑归宗")
        titleLabel.fontSize = 40
        titleLabel.fontName = "PingFangSC-Bold"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: self.size.height/2 - 80)
        uiLayer.addChild(titleLabel)

        // Level Label
        levelLabel = SKLabelNode(text: "第\(currentLevel.id)关 - \(currentLevel.name)")
        levelLabel.fontSize = 28
        levelLabel.fontName = "PingFangSC-Semibold"
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: 0, y: self.size.height/2 - 130)
        uiLayer.addChild(levelLabel)

        // Goal Label
        goalLabel = SKLabelNode(text: "目标: \(currentLevel.targetScore)分")
        goalLabel.fontSize = 20
        goalLabel.fontName = "PingFangSC-Regular"
        goalLabel.fontColor = SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        goalLabel.position = CGPoint(x: 0, y: self.size.height/2 - 165)
        uiLayer.addChild(goalLabel)

        // Score Label (Left side)
        scoreLabel = SKLabelNode(text: "修为: 0")
        scoreLabel.fontSize = 22
        scoreLabel.fontName = "PingFangSC-Regular"
        scoreLabel.fontColor = .yellow
        scoreLabel.position = CGPoint(x: -self.size.width/2 + 80, y: -self.size.height/2 + 150)
        scoreLabel.horizontalAlignmentMode = .left
        uiLayer.addChild(scoreLabel)

        // Merge Count Label (Right side)
        let mergeLabel = SKLabelNode(text: "合成: 0/\(currentLevel.targetMerges)")
        mergeLabel.fontSize = 22
        mergeLabel.fontName = "PingFangSC-Regular"
        mergeLabel.fontColor = .cyan
        mergeLabel.name = "mergeLabel"
        mergeLabel.position = CGPoint(x: self.size.width/2 - 80, y: -self.size.height/2 + 150)
        mergeLabel.horizontalAlignmentMode = .right
        uiLayer.addChild(mergeLabel)

        // Energy Bar Background
        let energyBg = SKShapeNode(rectOf: CGSize(width: 200, height: 20), cornerRadius: 10)
        energyBg.fillColor = SKColor(white: 0.2, alpha: 0.8)
        energyBg.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        energyBg.lineWidth = 2
        energyBg.position = CGPoint(x: 0, y: -self.size.height/2 + 200)
        uiLayer.addChild(energyBg)

        // Energy Bar Fill
        energyBar = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: -10, width: 0, height: 20))
        energyBar.path = path
        energyBar.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        energyBar.strokeColor = .clear
        energyBar.position = CGPoint(x: -100, y: -self.size.height/2 + 200)
        uiLayer.addChild(energyBar)

        // Ultimate Button
        ultimateButton = SKLabelNode(text: "⚔️ 万剑归宗 ⚔️")
        ultimateButton.fontSize = 32
        ultimateButton.fontName = "PingFangSC-Bold"
        ultimateButton.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        ultimateButton.position = CGPoint(x: 0, y: -self.size.height/2 + 100)
        ultimateButton.name = "ultimateBtn"
        ultimateButton.isHidden = true
        uiLayer.addChild(ultimateButton)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "ultimateBtn" {
                triggerUltimate()
                return
            }
            if node.name == "restartBtn" {
                restartGame()
                return
            }
            if node.name == "nextLevelBtn" {
                goToNextLevel()
                return
            }
            if node.name == "restartLevelBtn" {
                restartCurrentLevel()
                return
            }
            if let sword = node as? Sword {
                draggedSword = sword
                originalPosition = sword.position
                originalGridIndex = sword.gridPosition
                sword.zPosition = 100 // Bring to front
                sword.run(SKAction.scale(to: 1.2, duration: 0.1))
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        let location = touch.location(in: self)
        sword.position = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        let location = touch.location(in: self) // Location in scene (which is centered at 0,0 for now? No, need to check AnchorPoint)
        
        // Convert scene location to grid coordinates (relative to gridLayer center if gridLayer was offset, but here gridLayer is at 0,0)
        // Note: The hexToPixel logic assumes (0,0) is center of grid.
        // We need to ensure the scene anchor point is (0.5, 0.5) or adjust the location.
        // By default, SpriteKit Scene anchorPoint is (0, 0).
        // Let's adjust for that in didMove or here.
        
        // For now, let's assume we fix the Scene AnchorPoint to (0.5, 0.5) in didMove.
        
        let gridIndex = pixelToHex(point: location)
        handleDrop(sword: sword, at: gridIndex)
        
        draggedSword = nil
        originalPosition = nil
        originalGridIndex = nil
    }
    
    private func handleDrop(sword: Sword, at targetIndex: (q: Int, r: Int)) {
        let targetKey = "\(targetIndex.q)_\(targetIndex.r)"
        _ = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
        
        // Check if valid tile
        // Check bounds (Radius 2)
        let absQ = abs(targetIndex.q)
        let absR = abs(targetIndex.r)
        let absQR = abs(targetIndex.q + targetIndex.r)
        let distance = (absQ + absQR + absR) / 2
        if distance > 2 {
            returnToOriginalPosition(sword)
            return
        }
        
        if let targetSword = grid[targetKey] {
            // Merge Logic
            if targetSword != sword && targetSword.type == sword.type && targetSword.type != .xian {
                // Merge!
                // For MVP: Simple merge 2 for test, but requirement is 3.
                // Requirement: "Drag flying sword... merge"
                // Usually merge games: Drag A to B -> If A==B, they might merge or wait for a 3rd?
                // PRD says: "Drag 3 swords... auto trigger".
                // "Drag 3 low level swords -> Auto trigger" implies we place them next to each other?
                // OR "2048 style" or "Merge Dragons style"?
                // "Drag flying sword, help it return to sect"
                // "Drag 3 swords -> Auto trigger"
                // Wait, "Drag 3 swords" is ambiguous. Does it mean "Arrange 3 swords"?
                // "User drags 3 low level swords... Auto trigger: Sword array rotates... Three swords into one"
                // This sounds like Match-3 logic (Swap or Place).
                // "Drag and Drop + Place"
                
                // Let's implement: Drag sword to an empty spot. If it creates a match of 3 adjacent identical swords, they merge.
                // If dragged ONTOP of another sword?
                // Usually: Swap? Or Invalid?
                
                // PRD: "Drag flying sword" -> "Let user drag randomly"
                // "Drag 3 swords" -> Maybe "Collect 3 swords"?
                // Let's assume standard Match-3 or Merge-3 mechanics.
                // Interpretation: You can drag swords to any empty slot.
                // If you drag onto another sword, maybe swap?
                
                // Let's try SWAP first.
                swapSwords(sword, targetSword)
                
                // Check matches after swap
                checkForMatches()
                
            } else {
                 // Different types or Max level -> Swap
                 swapSwords(sword, targetSword)
                 checkForMatches()
            }
        } else {
            // Move to empty slot
            moveSword(sword, to: targetIndex)
            checkForMatches()
        }
    }
    
    private func swapSwords(_ sword1: Sword, _ sword2: Sword) {
        let pos1 = sword1.gridPosition
        let pos2 = sword2.gridPosition
        
        let key1 = "\(pos1.q)_\(pos1.r)"
        let key2 = "\(pos2.q)_\(pos2.r)"
        
        grid[key1] = sword2
        grid[key2] = sword1
        
        sword1.gridPosition = pos2
        sword2.gridPosition = pos1
        
        let action1 = SKAction.move(to: hexToPixel(q: pos2.q, r: pos2.r), duration: 0.2)
        let action2 = SKAction.move(to: hexToPixel(q: pos1.q, r: pos1.r), duration: 0.2)
        
        sword1.run(action1)
        sword2.run(action2)
        
        sword1.run(SKAction.scale(to: 1.0, duration: 0.1))
    }
    
    private func moveSword(_ sword: Sword, to index: (Int, Int)) {
        let oldKey = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
        let newKey = "\(index.0)_\(index.1)"
        
        grid.removeValue(forKey: oldKey)
        grid[newKey] = sword
        
        sword.gridPosition = (q: index.0, r: index.1)
        let action = SKAction.move(to: hexToPixel(q: index.0, r: index.1), duration: 0.2)
        sword.run(action)
        sword.run(SKAction.scale(to: 1.0, duration: 0.1))
    }
    
    private func returnToOriginalPosition(_ sword: Sword) {
        if let pos = originalPosition {
            sword.run(SKAction.move(to: pos, duration: 0.2))
            sword.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }
    
    private func checkForMatches() {
        // Find connected components of 3 or more same swords
        // For MVP, just scan the whole grid or the moved sword's neighbors

        // Simple BFS/FloodFill for each sword
        var visited = Set<String>()
        var hadMatches = false

        for (key, sword) in grid {
            if visited.contains(key) { continue }

            let matches = findMatches(startNode: sword)
            if matches.count >= 3 {
                // Merge!
                mergeSwords(matches)
                hadMatches = true
                // Mark all as visited
                for m in matches {
                    visited.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
                }
            }
        }

        // After all merges, replenish swords
        if hadMatches {
            // Delay replenish to let merge animations complete
            let wait = SKAction.wait(forDuration: 0.3)
            let replenish = SKAction.run { [weak self] in
                self?.replenishSwords()
            }
            self.run(SKAction.sequence([wait, replenish]))
        } else {
            // Reset combo if no matches
            comboCount = 0
        }
    }
    
    private func findMatches(startNode: Sword) -> [Sword] {
        var matches = [startNode]
        var queue = [startNode]
        var visited = Set<String>()
        visited.insert("\(startNode.gridPosition.q)_\(startNode.gridPosition.r)")
        
        let type = startNode.type
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let neighbors = getNeighbors(q: current.gridPosition.q, r: current.gridPosition.r)
            
            for neighborPos in neighbors {
                let key = "\(neighborPos.q)_\(neighborPos.r)"
                if !visited.contains(key), let neighborSword = grid[key], neighborSword.type == type {
                    visited.insert(key)
                    matches.append(neighborSword)
                    queue.append(neighborSword)
                }
            }
        }
        
        return matches
    }
    
    private func getNeighbors(q: Int, r: Int) -> [(q: Int, r: Int)] {
        let directions: [(Int, Int)] = [
            (1, 0), (1, -1), (0, -1),
            (-1, 0), (-1, 1), (0, 1)
        ]
        return directions.map { (q: q + $0.0, r: r + $0.1) }
    }
    
    private func mergeSwords(_ swords: [Sword]) {
        guard let first = swords.first else { return }
        let targetType = first.type

        // Center of mass or the last moved one?
        let centerSword = swords[0]

        // Increment merge count
        mergeCount += 1

        // Trigger Special Effects based on type being merged
        if targetType == .ling {
            triggerLineClear(at: centerSword.gridPosition)
        } else if targetType == .xian {
            triggerAreaClear(at: centerSword.gridPosition)
        }

        // Remove others
        for i in 1..<swords.count {
            let sword = swords[i]
            removeSword(sword, moveTo: centerSword.position)
        }

        // Upgrade center sword
        centerSword.upgrade()

        // Show combo count if applicable
        comboCount += 1
        let comboText = comboCount > 1 ? "Combo x\(comboCount)!" : "剑意+1"

        // Trigger Effects
        triggerMergeEffect(at: centerSword.position, text: comboText)

        // Score & Energy (bonus for combos)
        let baseScore = 10 * Int(targetType.rawValue)
        let comboBonus = comboCount > 1 ? baseScore * (comboCount - 1) / 2 : 0
        addScore(baseScore + comboBonus)
        addEnergy(10)

        updateUI()
    }
    
    private func removeSword(_ sword: Sword, moveTo targetPos: CGPoint? = nil) {
        let key = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
        if grid[key] == sword {
            grid.removeValue(forKey: key)
        }
        
        if let targetPos = targetPos {
            let moveAction = SKAction.move(to: targetPos, duration: 0.2)
            let fadeAction = SKAction.fadeOut(withDuration: 0.2)
            let removeAction = SKAction.removeFromParent()
            sword.run(SKAction.sequence([SKAction.group([moveAction, fadeAction]), removeAction]))
        } else {
            // Just explode
            let scaleAction = SKAction.scale(to: 0.1, duration: 0.2)
            let fadeAction = SKAction.fadeOut(withDuration: 0.2)
            sword.run(SKAction.sequence([SKAction.group([scaleAction, fadeAction]), SKAction.removeFromParent()]))
        }
    }
    
    private func triggerLineClear(at pos: (q: Int, r: Int)) {
        // Clear row r
        let r = pos.r
        // Find all swords with same r
        let targets = grid.values.filter { $0.gridPosition.r == r && $0.gridPosition != pos }
        
        for sword in targets {
            removeSword(sword)
            addScore(5)
        }
        
        triggerMergeEffect(at: hexToPixel(q: pos.q, r: pos.r), text: "剑气纵横!")
    }
    
    private func triggerAreaClear(at pos: (q: Int, r: Int)) {
        let neighbors = getNeighbors(q: pos.q, r: pos.r)
        for nPos in neighbors {
            let key = "\(nPos.q)_\(nPos.r)"
            if let sword = grid[key] {
                removeSword(sword)
                addScore(5)
            }
        }
        triggerMergeEffect(at: hexToPixel(q: pos.q, r: pos.r), text: "一剑开天!")
    }
    
    private func triggerMergeEffect(at pos: CGPoint, text: String) {
        let label = SKLabelNode(text: text)
        label.position = pos
        label.fontSize = 24
        label.fontName = "PingFangSC-Bold"
        label.fontColor = .yellow
        label.zPosition = 200
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 1.0)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        label.run(SKAction.sequence([SKAction.group([moveUp, fade]), SKAction.removeFromParent()]))
    }
    
    private func addScore(_ value: Int) {
        score += value
    }
    
    private func addEnergy(_ value: CGFloat) {
        energy = min(energy + value, maxEnergy)
    }
    
    private func updateUI() {
        scoreLabel.text = "修为: \(score)"

        // Update merge count label
        if let mergeLabel = uiLayer.childNode(withName: "mergeLabel") as? SKLabelNode {
            mergeLabel.text = "合成: \(mergeCount)/\(currentLevel.targetMerges)"
        }

        // Update Energy Bar
        let percentage = energy / maxEnergy
        let width = 200.0 * percentage
        // Recreate path to anchor left
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: -10, width: width, height: 20))
        energyBar.path = path
        energyBar.position = CGPoint(x: -100, y: -self.size.height/2 + 200)

        if energy >= maxEnergy {
            ultimateButton.isHidden = false
            // Pulse animation
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.3)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
            ultimateButton.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
        } else {
            ultimateButton.isHidden = true
            ultimateButton.removeAllActions()
        }

        // Check level completion
        checkLevelCompletion()
    }

    private func checkLevelCompletion() {
        if score >= currentLevel.targetScore && mergeCount >= currentLevel.targetMerges {
            triggerLevelComplete()
        }
    }
    
    private func triggerUltimate() {
        // Wan Jian Gui Zong
        energy = 0
        updateUI()

        // Visuals
        let flash = SKShapeNode(rectOf: self.size)
        flash.fillColor = .white
        flash.alpha = 0
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.8, duration: 0.1), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))

        // Clear 70% of swords randomly
        let allSwords = Array(grid.values)
        let countToRemove = Int(Double(allSwords.count) * 0.7)
        let shuffled = allSwords.shuffled()
        let toRemove = shuffled.prefix(countToRemove)

        for sword in toRemove {
            removeSword(sword)
            addScore(20)
        }

        // Text
        let label = SKLabelNode(text: "万剑归宗!")
        label.fontSize = 60
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = .red
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 300
        label.setScale(0.1)
        addChild(label)

        let action = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        label.run(action)

        // Replenish swords after ultimate animation
        let waitAction = SKAction.wait(forDuration: 1.3)
        let replenishAction = SKAction.run { [weak self] in
            self?.replenishSwords(fillAll: true)
        }
        self.run(SKAction.sequence([waitAction, replenishAction]))
    }

    // MARK: - Level Completion

    private func triggerLevelComplete() {
        // Prevent multiple triggers
        if let _ = self.childNode(withName: "levelCompleteOverlay") {
            return
        }

        let stars = currentLevel.calculateStars(score: score)

        // Create overlay
        let overlay = SKShapeNode(rectOf: self.size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.9)
        overlay.zPosition = 400
        overlay.name = "levelCompleteOverlay"
        overlay.alpha = 0
        addChild(overlay)

        // Fade in overlay
        overlay.run(SKAction.fadeIn(withDuration: 0.3))

        // Success particles effect
        let emitterNode = SKEmitterNode()
        emitterNode.particleTexture = SKTexture(imageNamed: "spark")
        emitterNode.particleBirthRate = 100
        emitterNode.particleLifetime = 2.0
        emitterNode.particleSpeed = 200
        emitterNode.particleSpeedRange = 100
        emitterNode.emissionAngleRange = .pi * 2
        emitterNode.particleAlpha = 0.8
        emitterNode.particleAlphaSpeed = -0.4
        emitterNode.particleScale = 0.5
        emitterNode.particleScaleSpeed = -0.2
        emitterNode.particleColorBlendFactor = 1.0
        emitterNode.particleColor = .yellow
        emitterNode.position = CGPoint(x: 0, y: 100)
        emitterNode.zPosition = 401
        overlay.addChild(emitterNode)

        // Stop particles after 2 seconds
        let stopAction = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { emitterNode.particleBirthRate = 0 }
        ])
        emitterNode.run(stopAction)

        // Title
        let titleLabel = SKLabelNode(text: "⚔️ 关卡完成 ⚔️")
        titleLabel.fontSize = 50
        titleLabel.fontName = "PingFangSC-Heavy"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 150)
        titleLabel.setScale(0.5)
        overlay.addChild(titleLabel)

        titleLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))

        // Stars display
        let starY: CGFloat = 60
        let starSpacing: CGFloat = 80
        for i in 0..<3 {
            let starLabel = SKLabelNode(text: i < stars ? "⭐️" : "☆")
            starLabel.fontSize = 60
            starLabel.position = CGPoint(x: CGFloat(i - 1) * starSpacing, y: starY)
            starLabel.alpha = 0
            overlay.addChild(starLabel)

            // Animate stars appearing
            let delay = SKAction.wait(forDuration: 0.3 + Double(i) * 0.2)
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            starLabel.run(SKAction.sequence([delay, SKAction.group([fadeIn, scaleUp]), scaleDown]))
        }

        // Score info
        let scoreInfo = SKLabelNode(text: "修为: \(score) / \(currentLevel.targetScore)")
        scoreInfo.fontSize = 24
        scoreInfo.fontName = "PingFangSC-Regular"
        scoreInfo.fontColor = .white
        scoreInfo.position = CGPoint(x: 0, y: -20)
        overlay.addChild(scoreInfo)

        let mergeInfo = SKLabelNode(text: "合成: \(mergeCount) / \(currentLevel.targetMerges)")
        mergeInfo.fontSize = 24
        mergeInfo.fontName = "PingFangSC-Regular"
        mergeInfo.fontColor = .white
        mergeInfo.position = CGPoint(x: 0, y: -55)
        overlay.addChild(mergeInfo)

        // Buttons
        let buttonY: CGFloat = -140

        // Next Level button
        if LevelConfig.shared.currentLevelIndex < LevelConfig.shared.levels.count - 1 {
            let nextBtn = createButton(text: "下一关 ➡️", position: CGPoint(x: 0, y: buttonY))
            nextBtn.name = "nextLevelBtn"
            overlay.addChild(nextBtn)
        } else {
            // All levels complete
            let completeLabel = SKLabelNode(text: "🎉 所有关卡已完成 🎉")
            completeLabel.fontSize = 28
            completeLabel.fontName = "PingFangSC-Bold"
            completeLabel.fontColor = .green
            completeLabel.position = CGPoint(x: 0, y: buttonY)
            overlay.addChild(completeLabel)
        }

        // Restart button
        let restartBtn = createButton(text: "重新挑战", position: CGPoint(x: 0, y: buttonY - 60))
        restartBtn.name = "restartLevelBtn"
        restartBtn.fontColor = .lightGray
        restartBtn.fontSize = 24
        overlay.addChild(restartBtn)

        // Save progress
        LevelConfig.shared.completeLevel(stars: stars)
    }

    // MARK: - Playability Check

    private func performPlayabilityCheck() {
        // Check if there are any possible matches (3+ connected swords of same type)
        if !hasAnyPossibleMatches() {
            print("⚠️ Playability check failed - fixing board state")
            fixBoardState()
        }
    }

    private func hasAnyPossibleMatches() -> Bool {
        var visited = Set<String>()

        for (key, sword) in grid {
            if visited.contains(key) { continue }

            let matches = findMatches(startNode: sword)
            if matches.count >= 3 {
                return true
            }

            // Mark as visited
            for m in matches {
                visited.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
            }
        }

        return false
    }

    private func fixBoardState() {
        // Strategy: Find swords and change some to create a valid match
        let allSwords = Array(grid.values)

        if allSwords.count < 3 {
            return // Not enough swords to fix
        }

        // Count sword types
        var typeCounts: [SwordType: Int] = [:]
        for sword in allSwords {
            typeCounts[sword.type, default: 0] += 1
        }

        // Find the most common type
        let mostCommonType = typeCounts.max(by: { $0.value < $1.value })?.key ?? .fan

        // Change random swords to the most common type until we have at least 3
        var needToChange = max(0, 3 - (typeCounts[mostCommonType] ?? 0))
        let shuffledSwords = allSwords.shuffled()

        for sword in shuffledSwords {
            if needToChange <= 0 { break }
            if sword.type != mostCommonType {
                // Change this sword's type
                sword.type = mostCommonType
                sword.color = mostCommonType.color
                if let label = sword.children.first(where: { $0 is SKLabelNode }) as? SKLabelNode {
                    label.text = mostCommonType.name
                }
                needToChange -= 1
            }
        }

        print("✅ Board state fixed - ensured at least 3 \(mostCommonType.name) swords")
    }

    private func createButton(text: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(text: text)
        button.fontSize = 32
        button.fontName = "PingFangSC-Bold"
        button.fontColor = SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0)
        button.position = position
        return button
    }
}
