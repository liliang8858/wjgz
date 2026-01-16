//
//  GameScene.swift
//  wjgz
//
//  Created by VincentXie on 2026/1/15.
//

import SpriteKit
import GameplayKit
import AudioToolbox

class GameScene: SKScene {
    
    // MARK: - Layers
    private var backgroundLayer: SKNode!
    private var gridLayer: SKNode!
    private var swordLayer: SKNode!
    private var effectLayer: SKNode!
    private var uiLayer: SKNode!
    
    // MARK: - Grid Data
    private var grid: [String: Sword] = [:]
    
    // MARK: - Drag State
    private var draggedSword: Sword?
    private var originalPosition: CGPoint?
    private var originalGridIndex: (q: Int, r: Int)?
    
    // MARK: - Game State
    private var energy: CGFloat = 0
    private var score: Int = 0
    private var mergeCount: Int = 0
    private var comboCount: Int = 0
    private var comboTimer: Timer?
    private var currentLevel: Level!
    
    // MARK: - UI Elements
    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var goalLabel: SKLabelNode!
    private var energyBarBg: SKShapeNode!
    private var energyBarFill: SKShapeNode!
    private var ultimateButton: SKNode!
    private var comboLabel: SKLabelNode?
    
    // MARK: - Tutorial
    private var tutorialStep: Int = 0
    private var tutorialOverlay: SKNode?
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0)
        currentLevel = LevelConfig.shared.getCurrentLevel()
        
        setupLayers()
        createBackground()
        createGrid()
        spawnInitialSwords()
        setupUI()
        
        if !GameStateManager.shared.tutorialCompleted {
            showTutorial()
        }
    }
    
    // MARK: - Setup
    
    private func setupLayers() {
        backgroundLayer = SKNode()
        gridLayer = SKNode()
        swordLayer = SKNode()
        effectLayer = SKNode()
        uiLayer = SKNode()
        
        backgroundLayer.zPosition = 0
        gridLayer.zPosition = 10
        swordLayer.zPosition = 20
        effectLayer.zPosition = 100
        uiLayer.zPosition = 200
        
        addChild(backgroundLayer)
        addChild(gridLayer)
        addChild(swordLayer)
        addChild(effectLayer)
        addChild(uiLayer)
    }
    
    private func createBackground() {
        // Radial gradient effect
        let gradientSize = max(size.width, size.height) * 1.5
        
        // Golden glow at top
        let topGlow = SKShapeNode(circleOfRadius: gradientSize * 0.4)
        topGlow.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.15)
        topGlow.strokeColor = .clear
        topGlow.position = CGPoint(x: 0, y: size.height * 0.3)
        topGlow.blendMode = .add
        backgroundLayer.addChild(topGlow)
        
        // Jade glow at bottom left
        let leftGlow = SKShapeNode(circleOfRadius: gradientSize * 0.3)
        leftGlow.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 0.1)
        leftGlow.strokeColor = .clear
        leftGlow.position = CGPoint(x: -size.width * 0.3, y: -size.height * 0.3)
        leftGlow.blendMode = .add
        backgroundLayer.addChild(leftGlow)
        
        // Purple glow at bottom right
        let rightGlow = SKShapeNode(circleOfRadius: gradientSize * 0.25)
        rightGlow.fillColor = SKColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.1)
        rightGlow.strokeColor = .clear
        rightGlow.position = CGPoint(x: size.width * 0.3, y: -size.height * 0.2)
        rightGlow.blendMode = .add
        backgroundLayer.addChild(rightGlow)
    }
    
    private func createGrid() {
        let mapRadius = 2
        
        for q in -mapRadius...mapRadius {
            let r1 = max(-mapRadius, -q - mapRadius)
            let r2 = min(mapRadius, -q + mapRadius)
            
            for r in r1...r2 {
                createTile(q: q, r: r)
            }
        }
        
        // Formation ring decoration
        createFormationRing()
    }
    
    private func createTile(q: Int, r: Int) {
        let pos = hexToPixel(q: q, r: r)
        
        let hexPath = createHexPath(radius: GameConfig.tileRadius)
        let tile = SKShapeNode(path: hexPath)
        tile.fillColor = SKColor(white: 0.15, alpha: 0.6)
        tile.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.3)
        tile.lineWidth = 1
        tile.position = pos
        tile.name = "tile_\(q)_\(r)"
        gridLayer.addChild(tile)
    }
    
    private func createHexPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func createFormationRing() {
        let ringRadius = GameConfig.tileRadius * 5.5
        
        // Outer ring
        let outerRing = SKShapeNode(circleOfRadius: ringRadius)
        outerRing.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.4)
        outerRing.lineWidth = 2
        outerRing.fillColor = .clear
        outerRing.glowWidth = 3
        gridLayer.addChild(outerRing)
        
        // Inner rotating ring
        let innerRing = SKShapeNode(circleOfRadius: ringRadius - 10)
        innerRing.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.2)
        innerRing.lineWidth = 1
        innerRing.fillColor = .clear
        innerRing.name = "innerRing"
        gridLayer.addChild(innerRing)
        
        // Rotate animation
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 30)
        innerRing.run(SKAction.repeatForever(rotate))
    }

    
    // MARK: - Coordinate Conversion
    
    private func hexToPixel(q: Int, r: Int) -> CGPoint {
        let size = GameConfig.tileRadius + GameConfig.gridSpacing
        let sqrt3 = sqrt(3.0)
        let x = size * (sqrt3 * CGFloat(q) + sqrt3 / 2.0 * CGFloat(r))
        let y = size * (3.0 / 2.0 * CGFloat(r))
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
        let s_diff = abs(rs - (-q - r))
        
        if q_diff > r_diff && q_diff > s_diff {
            rq = -rr - rs
        } else if r_diff > s_diff {
            rr = -rq - rs
        }
        
        return (Int(rq), Int(rr))
    }
    
    private func getNeighbors(q: Int, r: Int) -> [(q: Int, r: Int)] {
        let directions = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
        return directions.map { (q: q + $0.0, r: r + $0.1) }
    }
    
    // MARK: - Sword Spawning
    
    private func spawnInitialSwords() {
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
        
        if emptySlots.isEmpty && grid.count >= 19 {
            triggerGameOver()
            return
        }
        
        let count = fillAll ? min(emptySlots.count, 9) : min(emptySlots.count, 3)
        let slots = emptySlots.shuffled().prefix(count)
        
        // Ensure at least 3 matching swords for playability
        var swordTypes: [SwordType] = []
        if fillAll && count >= 3 {
            swordTypes = [.fan, .fan, .fan]
            for _ in 3..<count {
                swordTypes.append(Double.random(in: 0...1) < 0.8 ? .fan : .ling)
            }
            swordTypes.shuffle()
        } else {
            for _ in 0..<count {
                swordTypes.append(Double.random(in: 0...1) < 0.8 ? .fan : .ling)
            }
        }
        
        for (index, slot) in slots.enumerated() {
            spawnSword(at: slot, type: swordTypes[index])
            
            if let sword = grid["\(slot.0)_\(slot.1)"] {
                sword.setScale(0)
                sword.alpha = 0
                let spawn = SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.3),
                    SKAction.fadeIn(withDuration: 0.3)
                ])
                spawn.timingMode = .easeOut
                sword.run(spawn)
            }
        }
        
        performPlayabilityCheck()
    }
    
    private func spawnSword(at gridPos: (Int, Int), type: SwordType) {
        let sword = Sword(type: type, gridPosition: (q: gridPos.0, r: gridPos.1))
        sword.position = hexToPixel(q: gridPos.0, r: gridPos.1)
        swordLayer.addChild(sword)
        grid["\(gridPos.0)_\(gridPos.1)"] = sword
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(text: "万剑归宗")
        titleLabel.fontSize = 36
        titleLabel.fontName = "PingFangSC-Heavy"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 70)
        uiLayer.addChild(titleLabel)
        
        // Subtitle
        let subtitleLabel = SKLabelNode(text: "拖动飞剑，助其归宗")
        subtitleLabel.fontSize = 14
        subtitleLabel.fontName = "PingFangSC-Regular"
        subtitleLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: 0, y: size.height/2 - 95)
        uiLayer.addChild(subtitleLabel)
        
        // Level info
        levelLabel = SKLabelNode(text: "第\(currentLevel.id)关 - \(currentLevel.name)")
        levelLabel.fontSize = 22
        levelLabel.fontName = "PingFangSC-Semibold"
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: 0, y: size.height/2 - 125)
        uiLayer.addChild(levelLabel)
        
        // Goal
        goalLabel = SKLabelNode(text: "目标: \(currentLevel.targetScore)分")
        goalLabel.fontSize = 16
        goalLabel.fontName = "PingFangSC-Regular"
        goalLabel.fontColor = SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        goalLabel.position = CGPoint(x: 0, y: size.height/2 - 150)
        uiLayer.addChild(goalLabel)
        
        setupScorePanel()
        setupEnergyBar()
        setupUltimateButton()
    }
    
    private func setupScorePanel() {
        // Left panel - Score
        let leftPanel = createGlassPanel(size: CGSize(width: 120, height: 60))
        leftPanel.position = CGPoint(x: -size.width/2 + 75, y: -size.height/2 + 130)
        uiLayer.addChild(leftPanel)
        
        let scoreIcon = SKLabelNode(text: "修")
        scoreIcon.fontSize = 18
        scoreIcon.fontName = "PingFangSC-Bold"
        scoreIcon.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        scoreIcon.position = CGPoint(x: -40, y: -5)
        leftPanel.addChild(scoreIcon)
        
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontSize = 22
        scoreLabel.fontName = "PingFangSC-Bold"
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: -20, y: -8)
        leftPanel.addChild(scoreLabel)
        
        // Right panel - Merge count
        let rightPanel = createGlassPanel(size: CGSize(width: 120, height: 60))
        rightPanel.position = CGPoint(x: size.width/2 - 75, y: -size.height/2 + 130)
        uiLayer.addChild(rightPanel)
        
        let mergeIcon = SKLabelNode(text: "阵")
        mergeIcon.fontSize = 18
        mergeIcon.fontName = "PingFangSC-Bold"
        mergeIcon.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0)
        mergeIcon.position = CGPoint(x: -40, y: -5)
        rightPanel.addChild(mergeIcon)
        
        let mergeLabel = SKLabelNode(text: "0/\(currentLevel.targetMerges)")
        mergeLabel.fontSize = 20
        mergeLabel.fontName = "PingFangSC-Bold"
        mergeLabel.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0)
        mergeLabel.horizontalAlignmentMode = .left
        mergeLabel.position = CGPoint(x: -20, y: -8)
        mergeLabel.name = "mergeLabel"
        rightPanel.addChild(mergeLabel)
    }
    
    private func createGlassPanel(size: CGSize) -> SKShapeNode {
        let panel = SKShapeNode(rectOf: size, cornerRadius: 15)
        panel.fillColor = SKColor(white: 0.1, alpha: 0.8)
        panel.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        panel.lineWidth = 1
        return panel
    }
    
    private func setupEnergyBar() {
        let barWidth: CGFloat = 200
        let barHeight: CGFloat = 16
        let barY = -size.height/2 + 185
        
        // Label
        let energyLabel = SKLabelNode(text: "剑意")
        energyLabel.fontSize = 12
        energyLabel.fontName = "PingFangSC-Regular"
        energyLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        energyLabel.position = CGPoint(x: -barWidth/2 - 30, y: barY - 5)
        uiLayer.addChild(energyLabel)
        
        // Background
        energyBarBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 8)
        energyBarBg.fillColor = SKColor(white: 0.15, alpha: 0.9)
        energyBarBg.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.6)
        energyBarBg.lineWidth = 1.5
        energyBarBg.position = CGPoint(x: 20, y: barY)
        uiLayer.addChild(energyBarBg)
        
        // Fill
        energyBarFill = SKShapeNode(rectOf: CGSize(width: 0, height: barHeight - 4), cornerRadius: 6)
        energyBarFill.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        energyBarFill.strokeColor = .clear
        energyBarFill.position = CGPoint(x: 20 - barWidth/2 + 2, y: barY)
        uiLayer.addChild(energyBarFill)
    }

    
    private func setupUltimateButton() {
        ultimateButton = SKNode()
        ultimateButton.position = CGPoint(x: 0, y: -size.height/2 + 80)
        ultimateButton.name = "ultimateBtn"
        ultimateButton.isHidden = true
        uiLayer.addChild(ultimateButton)
        
        // Button background
        let btnBg = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 25)
        btnBg.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.9)
        btnBg.strokeColor = .white
        btnBg.lineWidth = 2
        btnBg.glowWidth = 5
        ultimateButton.addChild(btnBg)
        
        // Button text
        let btnLabel = SKLabelNode(text: "⚔️ 万剑归宗 ⚔️")
        btnLabel.fontSize = 20
        btnLabel.fontName = "PingFangSC-Heavy"
        btnLabel.fontColor = SKColor(red: 0.2, green: 0.1, blue: 0.0, alpha: 1.0)
        btnLabel.verticalAlignmentMode = .center
        ultimateButton.addChild(btnLabel)
        
        // Hint text
        let hintLabel = SKLabelNode(text: "积蓄剑意中...")
        hintLabel.fontSize = 12
        hintLabel.fontName = "PingFangSC-Regular"
        hintLabel.fontColor = SKColor(white: 0.5, alpha: 1.0)
        hintLabel.position = CGPoint(x: 0, y: -35)
        hintLabel.name = "ultimateHint"
        uiLayer.addChild(hintLabel)
        hintLabel.position = CGPoint(x: 0, y: -size.height/2 + 45)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "ultimateBtn" || node.parent?.name == "ultimateBtn" {
                if !ultimateButton.isHidden {
                    triggerUltimate()
                }
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
            if node.name == "skipTutorial" {
                skipTutorial()
                return
            }
            if let sword = node as? Sword {
                draggedSword = sword
                originalPosition = sword.position
                originalGridIndex = sword.gridPosition
                sword.zPosition = 100
                sword.run(SKAction.scale(to: 1.2, duration: 0.1))
                sword.playSelectAnimation()
                playClickSound()
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        sword.position = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        sword.stopSelectAnimation()
        let gridIndex = pixelToHex(point: location)
        handleDrop(sword: sword, at: gridIndex)
        
        draggedSword = nil
        originalPosition = nil
        originalGridIndex = nil
    }
    
    private func handleDrop(sword: Sword, at targetIndex: (q: Int, r: Int)) {
        let targetKey = "\(targetIndex.q)_\(targetIndex.r)"
        
        // Check bounds
        let distance = (abs(targetIndex.q) + abs(targetIndex.q + targetIndex.r) + abs(targetIndex.r)) / 2
        if distance > 2 {
            returnToOriginalPosition(sword)
            return
        }
        
        if let targetSword = grid[targetKey] {
            if targetSword != sword {
                swapSwords(sword, targetSword)
                checkForMatches()
            } else {
                returnToOriginalPosition(sword)
            }
        } else {
            moveSword(sword, to: targetIndex)
            checkForMatches()
        }
    }
    
    private func swapSwords(_ sword1: Sword, _ sword2: Sword) {
        let pos1 = sword1.gridPosition
        let pos2 = sword2.gridPosition
        
        grid["\(pos1.q)_\(pos1.r)"] = sword2
        grid["\(pos2.q)_\(pos2.r)"] = sword1
        
        sword1.gridPosition = pos2
        sword2.gridPosition = pos1
        
        sword1.run(SKAction.group([
            SKAction.move(to: hexToPixel(q: pos2.q, r: pos2.r), duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        sword2.run(SKAction.move(to: hexToPixel(q: pos1.q, r: pos1.r), duration: 0.2))
    }
    
    private func moveSword(_ sword: Sword, to index: (Int, Int)) {
        let oldKey = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
        let newKey = "\(index.0)_\(index.1)"
        
        grid.removeValue(forKey: oldKey)
        grid[newKey] = sword
        
        sword.gridPosition = (q: index.0, r: index.1)
        sword.run(SKAction.group([
            SKAction.move(to: hexToPixel(q: index.0, r: index.1), duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }
    
    private func returnToOriginalPosition(_ sword: Sword) {
        if let pos = originalPosition {
            sword.run(SKAction.group([
                SKAction.move(to: pos, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
    }
    
    // MARK: - Match Logic
    
    private func checkForMatches() {
        var visited = Set<String>()
        var hadMatches = false
        
        for (key, sword) in grid {
            if visited.contains(key) { continue }
            
            let matches = findMatches(startNode: sword)
            if matches.count >= 3 {
                mergeSwords(matches)
                hadMatches = true
                for m in matches {
                    visited.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
                }
            }
        }
        
        if hadMatches {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.run { [weak self] in self?.replenishSwords() }
            ]))
        } else {
            resetCombo()
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
    
    private func mergeSwords(_ swords: [Sword]) {
        guard let first = swords.first else { return }
        let targetType = first.type
        let centerSword = swords[0]
        
        mergeCount += 1
        comboCount += 1
        resetComboTimer()
        
        // Special effects based on type
        if targetType == .ling {
            triggerLineClear(at: centerSword.gridPosition)
        } else if targetType == .xian {
            triggerAreaClear(at: centerSword.gridPosition)
        }
        
        // Remove other swords with animation
        for i in 1..<swords.count {
            removeSword(swords[i], moveTo: centerSword.position)
        }
        
        // Upgrade center sword
        centerSword.upgrade()
        
        // Calculate score with combo bonus
        let comboMultiplier = 1.0 + Double(comboCount - 1) * 0.2
        let baseScore = targetType.baseScore
        let points = Int(Double(baseScore) * comboMultiplier)
        
        addScore(points)
        addEnergy(targetType.energyGain)
        
        // Record to game state
        GameStateManager.shared.recordMerge(type: targetType, combo: comboCount)
        GameStateManager.shared.recordCultivation(points)
        
        // Show floating text
        let mergeText = getMergeText(for: targetType)
        showFloatingText(mergeText, at: centerSword.position, color: targetType.glowColor)
        
        // Show combo if > 1
        if comboCount > 1 {
            showComboLabel()
        }
        
        playMergeSound(level: targetType)
        updateUI()
    }
    
    private func getMergeText(for type: SwordType) -> String {
        switch type {
        case .fan: return "三剑归一"
        case .ling: return "剑气纵横！"
        case .xian: return "一剑开天！"
        case .shen: return "神剑出世！"
        }
    }

    
    // MARK: - Special Effects
    
    private func triggerLineClear(at pos: (q: Int, r: Int)) {
        let targets = grid.values.filter { $0.gridPosition.r == pos.r && $0.gridPosition != pos }
        
        for sword in targets {
            removeSword(sword)
            addScore(5)
        }
        
        GameStateManager.shared.recordChainClear()
        createChainEffect(direction: .horizontal)
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
        
        GameStateManager.shared.recordChainClear()
        createChainEffect(direction: .radial)
    }
    
    private func createChainEffect(direction: ChainDirection) {
        let effect = SKShapeNode(rectOf: direction == .horizontal ? CGSize(width: 400, height: 20) : CGSize(width: 200, height: 200))
        effect.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 0.6)
        effect.strokeColor = .clear
        effect.position = .zero
        effect.zPosition = 50
        effect.blendMode = .add
        effectLayer.addChild(effect)
        
        let expand = SKAction.scale(to: 2.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        effect.run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))
    }
    
    enum ChainDirection {
        case horizontal, vertical, radial
    }
    
    private func removeSword(_ sword: Sword, moveTo targetPos: CGPoint? = nil) {
        let key = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
        if grid[key] == sword {
            grid.removeValue(forKey: key)
        }
        
        if let targetPos = targetPos {
            let move = SKAction.move(to: targetPos, duration: 0.2)
            let fade = SKAction.fadeOut(withDuration: 0.2)
            sword.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        } else {
            let scale = SKAction.scale(to: 0.1, duration: 0.2)
            let fade = SKAction.fadeOut(withDuration: 0.2)
            sword.run(SKAction.sequence([SKAction.group([scale, fade]), SKAction.removeFromParent()]))
        }
    }
    
    private func showFloatingText(_ text: String, at position: CGPoint, color: UIColor) {
        let label = SKLabelNode(text: "「\(text)」")
        label.fontSize = 28
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = color
        label.position = position
        label.zPosition = 150
        label.setScale(0.5)
        effectLayer.addChild(label)
        
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 80, duration: 1.2)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        
        label.run(SKAction.sequence([
            scaleUp, scaleDown,
            SKAction.group([moveUp, SKAction.sequence([SKAction.wait(forDuration: 0.7), fade])]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Combo System
    
    private func showComboLabel() {
        comboLabel?.removeFromParent()
        
        let label = SKLabelNode(text: "\(comboCount)连击！")
        label.fontSize = 36
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        label.position = CGPoint(x: 0, y: size.height/2 - 180)
        label.zPosition = 200
        label.setScale(0.5)
        uiLayer.addChild(label)
        comboLabel = label
        
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        label.run(SKAction.sequence([scaleUp, scaleDown]))
    }
    
    private func resetComboTimer() {
        comboTimer?.invalidate()
        comboTimer = Timer.scheduledTimer(withTimeInterval: GameConfig.comboTimeout, repeats: false) { [weak self] _ in
            self?.resetCombo()
        }
    }
    
    private func resetCombo() {
        comboTimer?.invalidate()
        comboTimer = nil
        comboCount = 0
        comboLabel?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        comboLabel = nil
    }
    
    // MARK: - Ultimate Skill
    
    private func triggerUltimate() {
        energy = 0
        updateUI()
        
        GameStateManager.shared.recordUltimate()
        playUltimateSound()
        
        // Screen flash
        let flash = SKShapeNode(rectOf: size)
        flash.fillColor = .white
        flash.alpha = 0
        flash.zPosition = 300
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Flying swords rain effect
        createSwordRainEffect()
        
        // Clear 70% of swords
        let allSwords = Array(grid.values)
        let countToRemove = Int(Double(allSwords.count) * GameConfig.ultimateClearPercent)
        let toRemove = allSwords.shuffled().prefix(countToRemove)
        
        for sword in toRemove {
            removeSword(sword)
            addScore(20)
        }
        
        // Big floating text
        let label = SKLabelNode(text: "万剑归宗！")
        label.fontSize = 60
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        label.position = .zero
        label.zPosition = 350
        label.setScale(0.1)
        addChild(label)
        
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Replenish after animation
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in self?.replenishSwords(fillAll: true) }
        ]))
    }
    
    private func createSwordRainEffect() {
        for i in 0..<30 {
            let sword = SKShapeNode(rectOf: CGSize(width: 6, height: 30))
            sword.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            sword.strokeColor = .clear
            sword.position = CGPoint(
                x: CGFloat.random(in: -size.width/2...size.width/2),
                y: size.height/2 + 50
            )
            sword.zPosition = 280
            sword.zRotation = .pi
            effectLayer.addChild(sword)
            
            let delay = Double(i) * 0.03
            let duration = 0.6 + Double.random(in: 0...0.3)
            let endY = -size.height/2 - 50
            
            sword.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.moveTo(y: endY, duration: duration),
                    SKAction.sequence([
                        SKAction.wait(forDuration: duration * 0.7),
                        SKAction.fadeOut(withDuration: duration * 0.3)
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    // MARK: - Score & Energy
    
    private func addScore(_ value: Int) {
        score += value
    }
    
    private func addEnergy(_ value: CGFloat) {
        energy = min(energy + value, GameConfig.maxEnergy)
    }
    
    private func updateUI() {
        // Score with animation
        let oldText = scoreLabel.text ?? "0"
        scoreLabel.text = "\(score)"
        if scoreLabel.text != oldText {
            scoreLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
        
        // Merge count
        if let mergeLabel = uiLayer.childNode(withName: "//mergeLabel") as? SKLabelNode {
            mergeLabel.text = "\(mergeCount)/\(currentLevel.targetMerges)"
        }
        
        // Energy bar
        let percentage = energy / GameConfig.maxEnergy
        let barWidth: CGFloat = 200
        let fillWidth = barWidth * percentage - 4
        
        let newPath = CGPath(roundedRect: CGRect(x: 0, y: -6, width: max(0, fillWidth), height: 12),
                             cornerWidth: 6, cornerHeight: 6, transform: nil)
        energyBarFill.path = newPath
        
        // Ultimate button visibility
        if energy >= GameConfig.maxEnergy {
            ultimateButton.isHidden = false
            if let hint = uiLayer.childNode(withName: "ultimateHint") as? SKLabelNode {
                hint.text = "剑意已满，可释放！"
                hint.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            }
            
            // Pulse animation
            if ultimateButton.action(forKey: "pulse") == nil {
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.1, duration: 0.4),
                    SKAction.scale(to: 1.0, duration: 0.4)
                ])
                ultimateButton.run(SKAction.repeatForever(pulse), withKey: "pulse")
            }
        } else {
            ultimateButton.isHidden = true
            ultimateButton.removeAction(forKey: "pulse")
            if let hint = uiLayer.childNode(withName: "ultimateHint") as? SKLabelNode {
                hint.text = "积蓄剑意中..."
                hint.fontColor = SKColor(white: 0.5, alpha: 1.0)
            }
        }
        
        checkLevelCompletion()
    }

    
    // MARK: - Level Completion
    
    private func checkLevelCompletion() {
        if score >= currentLevel.targetScore && mergeCount >= currentLevel.targetMerges {
            triggerLevelComplete()
        }
    }
    
    private func triggerLevelComplete() {
        if childNode(withName: "levelCompleteOverlay") != nil { return }
        
        let stars = currentLevel.calculateStars(score: score)
        
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.9)
        overlay.zPosition = 400
        overlay.name = "levelCompleteOverlay"
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.3))
        
        // Title
        let titleLabel = SKLabelNode(text: "⚔️ 关卡完成 ⚔️")
        titleLabel.fontSize = 40
        titleLabel.fontName = "PingFangSC-Heavy"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 120)
        overlay.addChild(titleLabel)
        
        // Stars
        for i in 0..<3 {
            let star = SKLabelNode(text: i < stars ? "⭐️" : "☆")
            star.fontSize = 50
            star.position = CGPoint(x: CGFloat(i - 1) * 70, y: 50)
            star.alpha = 0
            overlay.addChild(star)
            
            star.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3 + Double(i) * 0.2),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.2),
                    SKAction.scale(to: 1.2, duration: 0.2)
                ]),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
        
        // Score info
        let scoreInfo = SKLabelNode(text: "修为: \(score) / \(currentLevel.targetScore)")
        scoreInfo.fontSize = 22
        scoreInfo.fontName = "PingFangSC-Regular"
        scoreInfo.fontColor = .white
        scoreInfo.position = CGPoint(x: 0, y: -20)
        overlay.addChild(scoreInfo)
        
        // Buttons
        if LevelConfig.shared.currentLevelIndex < LevelConfig.shared.levels.count - 1 {
            let nextBtn = createButton(text: "下一关 ➡️", position: CGPoint(x: 0, y: -100))
            nextBtn.name = "nextLevelBtn"
            overlay.addChild(nextBtn)
        }
        
        let restartBtn = createButton(text: "重新挑战", position: CGPoint(x: 0, y: -160))
        restartBtn.name = "restartBtn"
        restartBtn.fontColor = .lightGray
        restartBtn.fontSize = 24
        overlay.addChild(restartBtn)
        
        LevelConfig.shared.completeLevel(stars: stars)
    }
    
    // MARK: - Game Over
    
    private func triggerGameOver() {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.85)
        overlay.zPosition = 400
        addChild(overlay)
        
        let label = SKLabelNode(text: "剑道未成")
        label.fontSize = 45
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 60)
        overlay.addChild(label)
        
        let subLabel = SKLabelNode(text: "但你已更近一步")
        subLabel.fontSize = 18
        subLabel.fontName = "PingFangSC-Regular"
        subLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        subLabel.position = CGPoint(x: 0, y: 20)
        overlay.addChild(subLabel)
        
        let scoreLabel = SKLabelNode(text: "修为: \(score)")
        scoreLabel.fontSize = 28
        scoreLabel.fontName = "PingFangSC-Bold"
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        scoreLabel.position = CGPoint(x: 0, y: -40)
        overlay.addChild(scoreLabel)
        
        let restartBtn = createButton(text: "再修一局", position: CGPoint(x: 0, y: -120))
        restartBtn.name = "restartBtn"
        overlay.addChild(restartBtn)
    }
    
    // MARK: - Tutorial
    
    private func showTutorial() {
        let messages = [
            ("欢迎来到剑阵", "点击相同的飞剑进行合成"),
            ("三剑归一", "选择3把相同的剑，它们将合成更强的剑"),
            ("积蓄剑意", "每次合成都会积累剑意能量"),
            ("万剑归宗", "能量满时可释放终极技"),
        ]
        
        guard tutorialStep < messages.count else {
            GameStateManager.shared.tutorialCompleted = true
            return
        }
        
        tutorialOverlay?.removeFromParent()
        
        let overlay = SKNode()
        overlay.zPosition = 500
        overlay.name = "tutorialOverlay"
        addChild(overlay)
        tutorialOverlay = overlay
        
        let bg = SKShapeNode(rectOf: size)
        bg.fillColor = SKColor(white: 0, alpha: 0.6)
        overlay.addChild(bg)
        
        let panel = createGlassPanel(size: CGSize(width: 280, height: 120))
        panel.position = CGPoint(x: 0, y: -size.height/2 + 200)
        overlay.addChild(panel)
        
        let (title, desc) = messages[tutorialStep]
        
        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontSize = 22
        titleLabel.fontName = "PingFangSC-Heavy"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 20)
        panel.addChild(titleLabel)
        
        let descLabel = SKLabelNode(text: desc)
        descLabel.fontSize = 14
        descLabel.fontName = "PingFangSC-Regular"
        descLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        descLabel.position = CGPoint(x: 0, y: -10)
        panel.addChild(descLabel)
        
        let skipBtn = SKLabelNode(text: "跳过 >")
        skipBtn.fontSize = 14
        skipBtn.fontName = "PingFangSC-Regular"
        skipBtn.fontColor = SKColor(white: 0.5, alpha: 1.0)
        skipBtn.position = CGPoint(x: 100, y: -40)
        skipBtn.name = "skipTutorial"
        panel.addChild(skipBtn)
        
        // Progress dots
        for i in 0..<messages.count {
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor = i <= tutorialStep ? SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) : SKColor(white: 0.3, alpha: 1.0)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i - messages.count/2) * 15, y: -size.height/2 + 130)
            overlay.addChild(dot)
        }
        
        // Auto advance
        run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.run { [weak self] in
                self?.tutorialStep += 1
                self?.showTutorial()
            }
        ]), withKey: "tutorialAdvance")
    }
    
    private func skipTutorial() {
        removeAction(forKey: "tutorialAdvance")
        tutorialOverlay?.removeFromParent()
        tutorialOverlay = nil
        GameStateManager.shared.tutorialCompleted = true
    }
    
    // MARK: - Game Control
    
    private func restartGame() {
        grid.values.forEach { $0.removeFromParent() }
        grid.removeAll()
        
        score = 0
        energy = 0
        mergeCount = 0
        comboCount = 0
        
        children.filter { $0.zPosition == 400 }.forEach { $0.removeFromParent() }
        
        currentLevel = LevelConfig.shared.getCurrentLevel()
        levelLabel.text = "第\(currentLevel.id)关 - \(currentLevel.name)"
        goalLabel.text = "目标: \(currentLevel.targetScore)分"
        
        updateUI()
        spawnInitialSwords()
    }
    
    private func goToNextLevel() {
        LevelConfig.shared.goToNextLevel()
        restartGame()
    }
    
    // MARK: - Playability
    
    private func performPlayabilityCheck() {
        if !hasAnyPossibleMatches() {
            fixBoardState()
        }
    }
    
    private func hasAnyPossibleMatches() -> Bool {
        var visited = Set<String>()
        
        for (key, sword) in grid {
            if visited.contains(key) { continue }
            
            let matches = findMatches(startNode: sword)
            if matches.count >= 3 { return true }
            
            for m in matches {
                visited.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
            }
        }
        return false
    }
    
    private func fixBoardState() {
        let allSwords = Array(grid.values)
        if allSwords.count < 3 { return }
        
        var typeCounts: [SwordType: Int] = [:]
        for sword in allSwords {
            typeCounts[sword.type, default: 0] += 1
        }
        
        let mostCommonType = typeCounts.max(by: { $0.value < $1.value })?.key ?? .fan
        var needToChange = max(0, 3 - (typeCounts[mostCommonType] ?? 0))
        
        for sword in allSwords.shuffled() {
            if needToChange <= 0 { break }
            if sword.type != mostCommonType {
                sword.type = mostCommonType
                if let label = sword.childNode(withName: "label") as? SKLabelNode {
                    label.text = mostCommonType.name
                }
                if let hex = sword.childNode(withName: "hexShape") as? SKShapeNode {
                    hex.fillColor = mostCommonType.color
                }
                needToChange -= 1
            }
        }
    }
    
    // MARK: - Sound & Haptics
    
    private func playClickSound() {
        AudioServicesPlaySystemSound(1104)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func playMergeSound(level: SwordType) {
        AudioServicesPlaySystemSound(1103)
        let style: UIImpactFeedbackGenerator.FeedbackStyle = level.rawValue >= 3 ? .heavy : .medium
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func playUltimateSound() {
        AudioServicesPlaySystemSound(1520)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Helpers
    
    private func createButton(text: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(text: text)
        button.fontSize = 28
        button.fontName = "PingFangSC-Bold"
        button.fontColor = SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0)
        button.position = position
        return button
    }
}
