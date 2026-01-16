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
    
    // MARK: - Managers
    private var effectsManager: EffectsManager!
    
    // MARK: - Grid Data
    private var grid: [String: Sword] = [:]
    private var blockedCells: Set<String> = []
    
    // MARK: - Drag State
    private var draggedSword: Sword?
    private var originalPosition: CGPoint?
    private var originalGridIndex: (q: Int, r: Int)?
    private var lastDragPosition: CGPoint?
    
    // MARK: - Game State
    private var energy: CGFloat = 0
    private var score: Int = 0
    private var mergeCount: Int = 0
    private var comboCount: Int = 0
    private var comboTimer: Timer?
    private var moveCount: Int = 0
    private var timeRemaining: TimeInterval = 0
    private var gameTimer: Timer?
    private var currentLevel: Level!
    private var isGameOver: Bool = false
    
    // MARK: - UI Elements
    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var goalLabel: SKLabelNode!
    private var energyBarBg: SKShapeNode!
    private var energyBarFill: SKShapeNode!
    private var ultimateButton: SKNode!
    private var comboLabel: SKLabelNode?
    private var timerLabel: SKLabelNode?
    private var moveLabel: SKLabelNode?
    
    // MARK: - Tutorial
    private var tutorialStep: Int = 0
    private var tutorialOverlay: SKNode?
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0)
        
        // 如果需要重置进度，取消下面的注释
        // LevelConfig.shared.resetProgress()
        
        currentLevel = LevelConfig.shared.getCurrentLevel()
        
        setupLayers()
        effectsManager = EffectsManager(scene: self, effectLayer: effectLayer)
        
        createBackground()
        createGrid()
        spawnInitialSwords()
        setupUI()
        setupLevelRules()
        
        // 开始背景粒子
        effectsManager.startBackgroundParticles()
        
        // 关卡开始特效
        effectsManager.playLevelStartEffect(levelName: currentLevel.name)
        
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
    
    private func setupLevelRules() {
        let rules = currentLevel.rules
        
        // 时间限制
        if let timeLimit = rules.timeLimit {
            timeRemaining = timeLimit
            startTimer()
        }
        
        // 封锁格子
        if rules.hasBlockedCells {
            setupBlockedCells(count: rules.blockedCellCount)
        }
        
        // 自动洗牌
        if let interval = rules.shuffleInterval {
            startAutoShuffle(interval: interval)
        }
    }
    
    private func startTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 1
            self.updateTimerDisplay()
            
            if self.timeRemaining <= 10 {
                // 紧迫感特效
                self.effectsManager.flashScreen(color: .red, duration: 0.2)
            }
            
            if self.timeRemaining <= 0 {
                self.gameTimer?.invalidate()
                self.triggerGameOver()
            }
        }
    }
    
    private func setupBlockedCells(count: Int) {
        let mapRadius = currentLevel.gridRadius
        var allCells: [(Int, Int)] = []
        
        for q in -mapRadius...mapRadius {
            let r1 = max(-mapRadius, -q - mapRadius)
            let r2 = min(mapRadius, -q + mapRadius)
            for r in r1...r2 {
                if q != 0 || r != 0 { // 不封锁中心
                    allCells.append((q, r))
                }
            }
        }
        
        let blocked = allCells.shuffled().prefix(count)
        for (q, r) in blocked {
            blockedCells.insert("\(q)_\(r)")
            
            // 添加封锁视觉效果
            if let tile = gridLayer.childNode(withName: "tile_\(q)_\(r)") as? SKShapeNode {
                tile.fillColor = SKColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 0.8)
                
                let lock = SKLabelNode(text: "🔒")
                lock.fontSize = 20
                lock.position = .zero
                tile.addChild(lock)
            }
        }
    }
    
    private func startAutoShuffle(interval: TimeInterval) {
        let shuffleAction = SKAction.sequence([
            SKAction.wait(forDuration: interval),
            SKAction.run { [weak self] in
                self?.shuffleBoard()
            }
        ])
        run(SKAction.repeatForever(shuffleAction), withKey: "autoShuffle")
    }
    
    private func shuffleBoard() {
        effectsManager.showFeedbackText("剑阵重组!", at: .zero, style: .great)
        effectsManager.shakeScreen(intensity: .medium)
        
        let allSwords = Array(grid.values)
        var positions = allSwords.map { $0.gridPosition }
        positions.shuffle()
        
        for (index, sword) in allSwords.enumerated() {
            let newPos = positions[index]
            let oldKey = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
            let newKey = "\(newPos.q)_\(newPos.r)"
            
            grid.removeValue(forKey: oldKey)
            grid[newKey] = sword
            sword.gridPosition = newPos
            
            let targetPoint = hexToPixel(q: newPos.q, r: newPos.r)
            sword.run(SKAction.move(to: targetPoint, duration: 0.5))
        }
    }
    
    private func createBackground() {
        let gradientSize = max(size.width, size.height) * 1.5
        
        // 根据关卡类型调整背景颜色
        let topColor: UIColor
        let leftColor: UIColor
        let rightColor: UIColor
        
        switch currentLevel.formationType {
        case .hexagon, .diamond:
            topColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.15)
            leftColor = SKColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 0.1)
            rightColor = SKColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.1)
        case .cross, .star:
            topColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.15)
            leftColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.1)
            rightColor = SKColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 0.1)
        case .ring, .spiral:
            topColor = SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.15)
            leftColor = SKColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 0.1)
            rightColor = SKColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 0.1)
        case .triangle, .random:
            topColor = SKColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 0.15)
            leftColor = SKColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 0.1)
            rightColor = SKColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 0.1)
        }
        
        let topGlow = SKShapeNode(circleOfRadius: gradientSize * 0.4)
        topGlow.fillColor = topColor
        topGlow.strokeColor = .clear
        topGlow.position = CGPoint(x: 0, y: size.height * 0.3)
        topGlow.blendMode = .add
        backgroundLayer.addChild(topGlow)
        
        let leftGlow = SKShapeNode(circleOfRadius: gradientSize * 0.3)
        leftGlow.fillColor = leftColor
        leftGlow.strokeColor = .clear
        leftGlow.position = CGPoint(x: -size.width * 0.3, y: -size.height * 0.3)
        leftGlow.blendMode = .add
        backgroundLayer.addChild(leftGlow)
        
        let rightGlow = SKShapeNode(circleOfRadius: gradientSize * 0.25)
        rightGlow.fillColor = rightColor
        rightGlow.strokeColor = .clear
        rightGlow.position = CGPoint(x: size.width * 0.3, y: -size.height * 0.2)
        rightGlow.blendMode = .add
        backgroundLayer.addChild(rightGlow)
    }
    
    private func createGrid() {
        let mapRadius = currentLevel.gridRadius
        let formation = currentLevel.formationType
        
        for q in -mapRadius...mapRadius {
            let r1 = max(-mapRadius, -q - mapRadius)
            let r2 = min(mapRadius, -q + mapRadius)
            
            for r in r1...r2 {
                if shouldCreateTile(q: q, r: r, formation: formation, radius: mapRadius) {
                    createTile(q: q, r: r)
                }
            }
        }
        
        createFormationRing()
    }
    
    private func shouldCreateTile(q: Int, r: Int, formation: FormationType, radius: Int) -> Bool {
        let s = -q - r
        let distance = (abs(q) + abs(r) + abs(s)) / 2
        
        switch formation {
        case .hexagon:
            return true
        case .diamond:
            return abs(q) + abs(r) <= radius + 1
        case .cross:
            return q == 0 || r == 0 || s == 0
        case .ring:
            return distance >= 1
        case .triangle:
            return r >= 0 && q >= -r
        case .star:
            return distance <= 1 || q == 0 || r == 0 || s == 0
        case .spiral:
            return true // 全部显示，但有特殊重力
        case .random:
            return Double.random(in: 0...1) > 0.2
        }
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
        let ringRadius = GameConfig.tileRadius * CGFloat(currentLevel.gridRadius + 3)
        
        let outerRing = SKShapeNode(circleOfRadius: ringRadius)
        outerRing.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.4)
        outerRing.lineWidth = 2
        outerRing.fillColor = .clear
        outerRing.glowWidth = 3
        gridLayer.addChild(outerRing)
        
        let innerRing = SKShapeNode(circleOfRadius: ringRadius - 10)
        innerRing.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.2)
        innerRing.lineWidth = 1
        innerRing.fillColor = .clear
        innerRing.name = "innerRing"
        gridLayer.addChild(innerRing)
        
        innerRing.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 30)))
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
        let mapRadius = currentLevel.gridRadius
        
        for q in -mapRadius...mapRadius {
            let r1 = max(-mapRadius, -q - mapRadius)
            let r2 = min(mapRadius, -q + mapRadius)
            for r in r1...r2 {
                let key = "\(q)_\(r)"
                if grid[key] == nil && !blockedCells.contains(key) {
                    if shouldCreateTile(q: q, r: r, formation: currentLevel.formationType, radius: mapRadius) {
                        emptySlots.append((q, r))
                    }
                }
            }
        }
        
        if emptySlots.isEmpty && !grid.isEmpty {
            if !hasAnyPossibleMatches() {
                triggerGameOver()
            }
            return
        }
        
        let count = fillAll ? min(emptySlots.count, 9) : min(emptySlots.count, 3)
        let slots = emptySlots.shuffled().prefix(count)
        
        // 根据关卡权重生成剑
        var swordTypes: [SwordType] = []
        let weights = currentLevel.spawnWeights
        
        // 确保至少有3把相同的剑
        if fillAll && count >= 3 {
            let guaranteedType = currentLevel.initialSwordTypes.randomElement() ?? .fan
            swordTypes = [guaranteedType, guaranteedType, guaranteedType]
            for _ in 3..<count {
                swordTypes.append(weightedRandomSword(weights: weights))
            }
            swordTypes.shuffle()
        } else {
            for _ in 0..<count {
                swordTypes.append(weightedRandomSword(weights: weights))
            }
        }
        
        for (index, slot) in slots.enumerated() {
            spawnSword(at: slot, type: swordTypes[index])
            
            if let sword = grid["\(slot.0)_\(slot.1)"] {
                sword.setScale(0)
                sword.alpha = 0
                
                let delay = Double(index) * 0.05
                sword.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.group([
                        SKAction.scale(to: 1.0, duration: 0.3),
                        SKAction.fadeIn(withDuration: 0.3)
                    ])
                ]))
                
                // 生成时的小特效
                effectsManager.playTapRipple(at: hexToPixel(q: slot.0, r: slot.1))
            }
        }
        
        performPlayabilityCheck()
    }
    
    private func weightedRandomSword(weights: [SwordType: Double]) -> SwordType {
        let total = weights.values.reduce(0, +)
        var random = Double.random(in: 0..<total)
        
        for (type, weight) in weights {
            random -= weight
            if random <= 0 {
                return type
            }
        }
        return .fan
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
        
        // Level info
        levelLabel = SKLabelNode(text: "第\(currentLevel.id)关 - \(currentLevel.name)")
        levelLabel.fontSize = 22
        levelLabel.fontName = "PingFangSC-Semibold"
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: 0, y: size.height/2 - 100)
        uiLayer.addChild(levelLabel)
        
        // Subtitle
        let subtitleLabel = SKLabelNode(text: currentLevel.subtitle)
        subtitleLabel.fontSize = 14
        subtitleLabel.fontName = "PingFangSC-Regular"
        subtitleLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: 0, y: size.height/2 - 125)
        uiLayer.addChild(subtitleLabel)
        
        // Goal
        goalLabel = SKLabelNode(text: "目标: \(currentLevel.targetScore)分 | \(currentLevel.targetMerges)次合成")
        goalLabel.fontSize = 14
        goalLabel.fontName = "PingFangSC-Regular"
        goalLabel.fontColor = SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        goalLabel.position = CGPoint(x: 0, y: size.height/2 - 148)
        uiLayer.addChild(goalLabel)
        
        setupScorePanel()
        setupEnergyBar()
        setupUltimateButton()
        setupLevelConstraints()
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
    
    private func setupLevelConstraints() {
        let rules = currentLevel.rules
        
        // 时间限制显示
        if rules.timeLimit != nil {
            timerLabel = SKLabelNode(text: "⏱ \(Int(timeRemaining))s")
            timerLabel?.fontSize = 24
            timerLabel?.fontName = "PingFangSC-Bold"
            timerLabel?.fontColor = .white
            timerLabel?.position = CGPoint(x: 0, y: size.height/2 - 175)
            uiLayer.addChild(timerLabel!)
        }
        
        // 步数限制显示
        if let moveLimit = rules.moveLimit {
            moveLabel = SKLabelNode(text: "👆 \(moveLimit - moveCount)步")
            moveLabel?.fontSize = 24
            moveLabel?.fontName = "PingFangSC-Bold"
            moveLabel?.fontColor = .white
            moveLabel?.position = CGPoint(x: 0, y: size.height/2 - 175)
            uiLayer.addChild(moveLabel!)
        }
    }
    
    private func updateTimerDisplay() {
        timerLabel?.text = "⏱ \(Int(timeRemaining))s"
        if timeRemaining <= 10 {
            timerLabel?.fontColor = .red
        }
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
        
        let energyLabel = SKLabelNode(text: "剑意")
        energyLabel.fontSize = 12
        energyLabel.fontName = "PingFangSC-Regular"
        energyLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        energyLabel.position = CGPoint(x: -barWidth/2 - 30, y: barY - 5)
        uiLayer.addChild(energyLabel)
        
        energyBarBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 8)
        energyBarBg.fillColor = SKColor(white: 0.15, alpha: 0.9)
        energyBarBg.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.6)
        energyBarBg.lineWidth = 1.5
        energyBarBg.position = CGPoint(x: 20, y: barY)
        uiLayer.addChild(energyBarBg)
        
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
        
        let btnBg = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 25)
        btnBg.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.9)
        btnBg.strokeColor = .white
        btnBg.lineWidth = 2
        btnBg.glowWidth = 5
        ultimateButton.addChild(btnBg)
        
        let btnLabel = SKLabelNode(text: "⚔️ 万剑归宗 ⚔️")
        btnLabel.fontSize = 20
        btnLabel.fontName = "PingFangSC-Heavy"
        btnLabel.fontColor = SKColor(red: 0.2, green: 0.1, blue: 0.0, alpha: 1.0)
        btnLabel.verticalAlignmentMode = .center
        ultimateButton.addChild(btnLabel)
        
        let hintLabel = SKLabelNode(text: "积蓄剑意中...")
        hintLabel.fontSize = 12
        hintLabel.fontName = "PingFangSC-Regular"
        hintLabel.fontColor = SKColor(white: 0.5, alpha: 1.0)
        hintLabel.position = CGPoint(x: 0, y: -size.height/2 + 45)
        hintLabel.name = "ultimateHint"
        uiLayer.addChild(hintLabel)
    }

    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isGameOver else { return }
        let location = touch.location(in: self)
        
        // 点击涟漪特效
        effectsManager.playTapRipple(at: location)
        
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
                lastDragPosition = location
                sword.zPosition = 100
                sword.run(SKAction.scale(to: 1.2, duration: 0.1))
                effectsManager.playSelectPulse(on: sword)
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        let location = touch.location(in: self)
        sword.position = location
        
        // 拖拽轨迹特效
        if let lastPos = lastDragPosition {
            let distance = hypot(location.x - lastPos.x, location.y - lastPos.y)
            if distance > 15 {
                effectsManager.playDragTrail(at: lastPos, color: sword.type.glowColor)
                lastDragPosition = location
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        sword.childNode(withName: "selectPulse")?.removeFromParent()
        let gridIndex = pixelToHex(point: location)
        handleDrop(sword: sword, at: gridIndex)
        
        draggedSword = nil
        originalPosition = nil
        originalGridIndex = nil
        lastDragPosition = nil
    }
    
    private func handleDrop(sword: Sword, at targetIndex: (q: Int, r: Int)) {
        let targetKey = "\(targetIndex.q)_\(targetIndex.r)"
        
        // 检查是否是封锁格子
        if blockedCells.contains(targetKey) {
            effectsManager.showFeedbackText("此处封印!", at: sword.position, style: .normal)
            returnToOriginalPosition(sword)
            return
        }
        
        // 检查边界
        let distance = (abs(targetIndex.q) + abs(targetIndex.q + targetIndex.r) + abs(targetIndex.r)) / 2
        if distance > currentLevel.gridRadius {
            returnToOriginalPosition(sword)
            return
        }
        
        // 检查是否是有效格子
        if !shouldCreateTile(q: targetIndex.q, r: targetIndex.r, formation: currentLevel.formationType, radius: currentLevel.gridRadius) {
            returnToOriginalPosition(sword)
            return
        }
        
        if let targetSword = grid[targetKey] {
            if targetSword != sword {
                swapSwords(sword, targetSword)
                incrementMove()
                checkForMatches()
            } else {
                returnToOriginalPosition(sword)
            }
        } else {
            moveSword(sword, to: targetIndex)
            incrementMove()
            checkForMatches()
        }
    }
    
    private func incrementMove() {
        moveCount += 1
        
        if let moveLimit = currentLevel.rules.moveLimit {
            let remaining = moveLimit - moveCount
            moveLabel?.text = "👆 \(remaining)步"
            
            if remaining <= 5 {
                moveLabel?.fontColor = .red
                effectsManager.flashScreen(color: .red, duration: 0.1)
            }
            
            if remaining <= 0 {
                triggerGameOver()
            }
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
            effectsManager.shakeScreen(intensity: .light)
        }
    }
    
    // MARK: - Match Logic
    
    private func checkForMatches() {
        var visited = Set<String>()
        var hadMatches = false
        var totalMatchCount = 0
        
        for (key, sword) in grid {
            if visited.contains(key) { continue }
            
            let matches = findMatches(startNode: sword)
            if matches.count >= currentLevel.rules.minMergeCount {
                mergeSwords(matches)
                hadMatches = true
                totalMatchCount += matches.count
                for m in matches {
                    visited.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
                }
            }
        }
        
        if hadMatches {
            // 根据消除数量给予不同反馈
            giveFeedbackForMatchCount(totalMatchCount)
            
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.run { [weak self] in self?.replenishSwords() }
            ]))
        } else {
            resetCombo()
        }
    }
    
    private func giveFeedbackForMatchCount(_ count: Int) {
        let style: EffectsManager.FeedbackStyle
        let text: String
        
        switch count {
        case 3:
            style = .normal
            text = "不错"
        case 4:
            style = .good
            text = "很好"
        case 5:
            style = .great
            text = "太棒了"
        case 6...7:
            style = .excellent
            text = "极好!"
        case 8...10:
            style = .perfect
            text = "完美!!"
        default:
            style = .legendary
            text = "传说!!!"
        }
        
        if count >= 4 {
            effectsManager.showFeedbackText(text, at: CGPoint(x: 0, y: 50), style: style)
        }
        
        // 音效反馈
        SoundManager.shared.playFeedback(for: count)
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
        let centerPos = hexToPixel(q: centerSword.gridPosition.q, r: centerSword.gridPosition.r)
        
        mergeCount += 1
        comboCount += 1
        resetComboTimer()
        
        // 合成爆发特效
        effectsManager.playMergeBurst(at: centerPos, color: targetType.glowColor, count: swords.count * 4, swordType: targetType)
        
        // 特殊效果
        if targetType == .ling {
            effectsManager.playChainWave(direction: .horizontal, at: centerPos)
            triggerLineClear(at: centerSword.gridPosition)
        } else if targetType == .xian {
            effectsManager.playAreaClearExplosion(at: centerPos)
            triggerAreaClear(at: centerSword.gridPosition)
        } else if targetType == .shen {
            effectsManager.playDivineSwordEffect(at: centerPos)
        }
        
        // 移除其他剑
        for i in 1..<swords.count {
            removeSword(swords[i], moveTo: centerPos)
        }
        
        // 升级中心剑
        let oldType = centerSword.type
        centerSword.upgrade()
        
        // 升级光柱特效
        if centerSword.type != oldType {
            effectsManager.playUpgradeBeam(at: centerPos, toType: centerSword.type)
        }
        
        // 计算分数
        let comboMultiplier = 1.0 + Double(comboCount - 1) * 0.2
        let baseScore = targetType.baseScore * swords.count
        let points = Int(Double(baseScore) * comboMultiplier)
        
        addScore(points)
        addEnergy(targetType.energyGain * CGFloat(swords.count) / 3.0)
        
        // 分数飘字
        effectsManager.playScorePopup(at: centerPos, score: points, isCombo: comboCount > 1)
        
        // 连击特效
        if comboCount > 1 {
            effectsManager.playComboEffect(combo: comboCount, at: centerPos)
        }
        
        // 记录状态
        GameStateManager.shared.recordMerge(type: targetType, combo: comboCount)
        GameStateManager.shared.recordCultivation(points)
        
        updateUI()
    }
    
    private func triggerLineClear(at pos: (q: Int, r: Int)) {
        let targets = grid.values.filter { $0.gridPosition.r == pos.r && $0.gridPosition != pos }
        
        for sword in targets {
            removeSword(sword)
            addScore(5)
        }
        
        GameStateManager.shared.recordChainClear()
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
    }
    
    private func removeSword(_ sword: Sword, moveTo targetPos: CGPoint? = nil) {
        let key = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
        if grid[key] == sword {
            grid.removeValue(forKey: key)
        }
        
        if let targetPos = targetPos {
            sword.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: targetPos, duration: 0.2),
                    SKAction.fadeOut(withDuration: 0.2)
                ]),
                SKAction.removeFromParent()
            ]))
        } else {
            sword.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 0.1, duration: 0.2),
                    SKAction.fadeOut(withDuration: 0.2)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    
    // MARK: - Combo System
    
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
    }
    
    // MARK: - Ultimate Skill
    
    private func triggerUltimate() {
        energy = 0
        updateUI()
        
        GameStateManager.shared.recordUltimate()
        
        // 史诗特效
        effectsManager.playUltimateEffect()
        effectsManager.playSlowMotion(duration: 0.5, slowFactor: 0.3)
        
        // 清除70%的剑
        let allSwords = Array(grid.values)
        let countToRemove = Int(Double(allSwords.count) * GameConfig.ultimateClearPercent)
        let toRemove = allSwords.shuffled().prefix(countToRemove)
        
        for sword in toRemove {
            removeSword(sword)
            addScore(20)
        }
        
        // 延迟补充
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in self?.replenishSwords(fillAll: true) }
        ]))
    }
    
    // MARK: - Score & Energy
    
    private func addScore(_ value: Int) {
        score += value
    }
    
    private func addEnergy(_ value: CGFloat) {
        let oldEnergy = energy
        energy = min(energy + value, GameConfig.maxEnergy)
        
        // 能量满时开始脉冲
        if energy >= GameConfig.maxEnergy && oldEnergy < GameConfig.maxEnergy {
            effectsManager.startEnergyFullPulse(around: ultimateButton)
            effectsManager.showFeedbackText("剑意已满!", at: CGPoint(x: 0, y: -100), style: .perfect)
            SoundManager.shared.playEnergyFull()
        }
    }
    
    private func updateUI() {
        // Score animation
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
            
            // 接近目标时变色
            if mergeCount >= currentLevel.targetMerges {
                mergeLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            }
        }
        
        // Energy bar
        let percentage = energy / GameConfig.maxEnergy
        let barWidth: CGFloat = 200
        let fillWidth = barWidth * percentage - 4
        
        let newPath = CGPath(roundedRect: CGRect(x: 0, y: -6, width: max(0, fillWidth), height: 12),
                             cornerWidth: 6, cornerHeight: 6, transform: nil)
        energyBarFill.path = newPath
        
        // Ultimate button
        if energy >= GameConfig.maxEnergy {
            ultimateButton.isHidden = false
            if let hint = uiLayer.childNode(withName: "ultimateHint") as? SKLabelNode {
                hint.text = "剑意已满，可释放！"
                hint.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            }
            
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
            effectsManager.stopEnergyFullPulse(on: ultimateButton)
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
        isGameOver = true
        gameTimer?.invalidate()
        removeAction(forKey: "autoShuffle")
        
        let stars = currentLevel.calculateStars(score: score)
        
        // 庆祝特效
        effectsManager.playLevelCompleteEffect(stars: stars)
        
        // 先保存当前关卡索引
        let currentLevelIdx = LevelConfig.shared.currentLevelIndex
        
        // 延迟显示结算界面
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.showLevelCompleteUI(stars: stars, currentLevelIdx: currentLevelIdx)
            }
        ]))
        
        // 完成关卡（这会更新索引）
        LevelConfig.shared.completeLevel(stars: stars)
    }
    
    private func showLevelCompleteUI(stars: Int, currentLevelIdx: Int) {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.9)
        overlay.zPosition = 400
        overlay.name = "levelCompleteOverlay"
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.3))
        
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
            overlay.addChild(star)
        }
        
        let scoreInfo = SKLabelNode(text: "修为: \(score) / \(currentLevel.targetScore)")
        scoreInfo.fontSize = 22
        scoreInfo.fontName = "PingFangSC-Regular"
        scoreInfo.fontColor = .white
        scoreInfo.position = CGPoint(x: 0, y: -20)
        overlay.addChild(scoreInfo)
        
        // 使用保存的索引来判断
        if currentLevelIdx < LevelConfig.shared.levels.count - 1 {
            let nextBtn = createButton(text: "下一关 ➡️", position: CGPoint(x: 0, y: -100))
            nextBtn.name = "nextLevelBtn"
            overlay.addChild(nextBtn)
        } else {
            let completeLabel = SKLabelNode(text: "🎉 所有关卡已完成 🎉")
            completeLabel.fontSize = 28
            completeLabel.fontName = "PingFangSC-Bold"
            completeLabel.fontColor = .green
            completeLabel.position = CGPoint(x: 0, y: -100)
            overlay.addChild(completeLabel)
        }
        
        let restartBtn = createButton(text: "重新挑战", position: CGPoint(x: 0, y: -160))
        restartBtn.name = "restartBtn"
        restartBtn.fontColor = .lightGray
        restartBtn.fontSize = 24
        overlay.addChild(restartBtn)
    }
    
    // MARK: - Game Over
    
    private func triggerGameOver() {
        if isGameOver { return }
        isGameOver = true
        gameTimer?.invalidate()
        removeAction(forKey: "autoShuffle")
        
        effectsManager.flashScreen(color: .red, duration: 0.5)
        effectsManager.shakeScreen(intensity: .large)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.showGameOverUI()
            }
        ]))
    }
    
    private func showGameOverUI() {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.85)
        overlay.zPosition = 400
        addChild(overlay)
        
        // 音效
        SoundManager.shared.playGameOver()
        
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
        blockedCells.removeAll()
        
        score = 0
        energy = 0
        mergeCount = 0
        comboCount = 0
        moveCount = 0
        isGameOver = false
        
        gameTimer?.invalidate()
        removeAction(forKey: "autoShuffle")
        
        children.filter { $0.zPosition == 400 }.forEach { $0.removeFromParent() }
        gridLayer.removeAllChildren()
        
        currentLevel = LevelConfig.shared.getCurrentLevel()
        timeRemaining = currentLevel.rules.timeLimit ?? 0
        
        levelLabel.text = "第\(currentLevel.id)关 - \(currentLevel.name)"
        goalLabel.text = "目标: \(currentLevel.targetScore)分 | \(currentLevel.targetMerges)次合成"
        
        createGrid()
        setupLevelRules()
        updateUI()
        spawnInitialSwords()
        
        effectsManager.playLevelStartEffect(levelName: currentLevel.name)
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
            if matches.count >= currentLevel.rules.minMergeCount { return true }
            
            for m in matches {
                visited.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
            }
        }
        return false
    }
    
    private func fixBoardState() {
        let allSwords = Array(grid.values)
        if allSwords.count < currentLevel.rules.minMergeCount { return }
        
        var typeCounts: [SwordType: Int] = [:]
        for sword in allSwords {
            typeCounts[sword.type, default: 0] += 1
        }
        
        let mostCommonType = typeCounts.max(by: { $0.value < $1.value })?.key ?? .fan
        var needToChange = max(0, currentLevel.rules.minMergeCount - (typeCounts[mostCommonType] ?? 0))
        
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
        
        effectsManager.showFeedbackText("剑阵调整", at: .zero, style: .normal)
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
