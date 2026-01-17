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
    private var ultimatePatternHintShown: Bool = false  // 是否已显示终极奥义提示
    
    // MARK: - Achievement Tracking
    private var maxCombo: Int = 0
    private var totalChainClears: Int = 0
    private var ultimateUsed: Int = 0
    private var perfectMerges: Int = 0  // 5个或以上的合成
    private var shenSwordsMerged: Int = 0  // 合成出的神剑数量
    
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
        
        // 获取当前关卡（使用新的游戏状态管理）
        currentLevel = LevelConfig.shared.getCurrentLevel()
        
        setupLayers()
        effectsManager = EffectsManager(scene: self, effectLayer: effectLayer)
        
        createBackground()
        createGrid()
        spawnInitialSwords()
        setupUI()
        setupLevelRules()
        
        // 🎵 初始化音效系统
        setupAudio()
        
        // 开始背景粒子
        effectsManager.startBackgroundParticles()
        
        // 关卡开始特效
        effectsManager.playLevelStartEffect(levelName: currentLevel.name)
        
        // 显示终极奥义提示
        showUltimatePatternHint()
        
        if !GameStateManager.shared.tutorialCompleted {
            showTutorial()
        }
    }
    
    // MARK: - Audio Setup
    
    /// 初始化音效系统
    private func setupAudio() {
        // 设置音量
        SoundManager.shared.setMusicVolume(0.05)  // 背景音乐 5%
        SoundManager.shared.setSFXVolume(0.7)     // 音效 70%
        
        // 播放背景音乐 (已关闭)
        // SoundManager.shared.playBackgroundMusic("background_main")
        
        print("🎵 音效系统已初始化")
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
        // 八卦阵型 - 阴阳配色
        case .qian, .li, .zhen, .dui:  // 阳卦
            topColor = SKColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 0.15)
            leftColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.1)
            rightColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.1)
        case .kun, .kan, .gen, .xun:  // 阴卦
            topColor = SKColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.15)
            leftColor = SKColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.1)
            rightColor = SKColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 0.1)
        // 高级阵型
        case .bagua:
            topColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 0.15)
            leftColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.1)
            rightColor = SKColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 0.1)
        case .wuxing:
            topColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.15)
            leftColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.1)
            rightColor = SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.1)
        case .jiugong:
            topColor = SKColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 0.15)
            leftColor = SKColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 0.1)
            rightColor = SKColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 0.1)
        case .tiangang:
            topColor = SKColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 0.15)
            leftColor = SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.1)
            rightColor = SKColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 0.1)
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
        // 八卦阵型
        case .qian:  // 乾 - 三阳爻，全满
            return true
        case .kun:  // 坤 - 三阴爻，中空
            return distance >= 1
        case .zhen:  // 震 - 下阳上阴
            return r <= 0 || distance <= 1
        case .xun:  // 巽 - 下阴上阳
            return r >= 0 || distance <= 1
        case .kan:  // 坎 - 中阳外阴
            return distance == 1 || distance == 0
        case .li:  // 离 - 中阴外阳
            return distance != 1
        case .gen:  // 艮 - 上阳下阴
            return q >= 0 || distance <= 1
        case .dui:  // 兑 - 上阴下阳
            return q <= 0 || distance <= 1
        // 高级阵型
        case .bagua:  // 八卦 - 八方位
            return true
        case .wuxing:  // 五行 - 五方位
            return distance <= 1 || q == 0 || r == 0 || s == 0
        case .jiugong:  // 九宫 - 九个位置
            return distance <= 1 || (abs(q) == radius && abs(r) <= 1) || (abs(r) == radius && abs(q) <= 1)
        case .tiangang:  // 天罡 - 大型阵
            return true
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 优先处理 UI 按钮（即使游戏结束也要响应）
        let nodes = nodes(at: location)
        for node in nodes {
            // 处理关卡完成界面按钮
            if node.name == "nextLevelBtn" {
                goToNextLevel()
                return
            }
            if node.name == "restartBtn" {
                restartGame()
                return
            }
            if node.name == "skipTutorial" {
                skipTutorial()
                return
            }
            if node.name == "closeUltimateHint" {
                closeUltimateHint()
                return
            }
        }
        
        // 如果游戏结束，不处理游戏内交互
        guard !isGameOver else { return }
        
        // 点击涟漪特效
        effectsManager.playTapRipple(at: location)
        
        for node in nodes {
            if node.name == "ultimateBtn" || node.parent?.name == "ultimateBtn" {
                if !ultimateButton.isHidden {
                    triggerUltimate()
                }
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
            
            // 检查终极奥义触发
            checkUltimatePattern()
            
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
        
        // 追踪最大连击
        if comboCount > maxCombo {
            maxCombo = comboCount
        }
        
        // 追踪完美合成（5个或以上）
        if swords.count >= 5 {
            perfectMerges += 1
        }
        
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
        
        // 追踪神剑合成
        if centerSword.type == .shen && oldType != .shen {
            shenSwordsMerged += 1
        }
        
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
        
        totalChainClears += 1
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
        
        totalChainClears += 1
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
        
        ultimateUsed += 1
        GameStateManager.shared.recordUltimate()
        
        // 🌟 新功能：万剑归宗强化 - 自动连续消除3次
        triggerAutoCombo(times: 3, reason: "万剑归宗")
    }
    
    // MARK: - Ultimate Pattern System (终极奥义系统)
    
    private func showUltimatePatternHint() {
        guard let pattern = currentLevel.rules.ultimatePattern, !ultimatePatternHintShown else { return }
        
        ultimatePatternHintShown = true
        
        // 延迟3秒显示提示
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run { [weak self] in
                self?.displayUltimatePatternHint(pattern: pattern)
            }
        ]))
    }
    
    private func displayUltimatePatternHint(pattern: UltimatePattern) {
        let hintOverlay = SKNode()
        hintOverlay.zPosition = 300
        hintOverlay.name = "ultimateHint"
        addChild(hintOverlay)
        
        // 半透明背景
        let bg = SKShapeNode(rectOf: size)
        bg.fillColor = SKColor(white: 0, alpha: 0.7)
        bg.strokeColor = .clear
        hintOverlay.addChild(bg)
        
        // 提示面板
        let panel = createGlassPanel(size: CGSize(width: 320, height: 200))
        panel.position = CGPoint(x: 0, y: 0)
        hintOverlay.addChild(panel)
        
        // 标题
        let titleLabel = SKLabelNode(text: "🗡️ 终极奥义 🗡️")
        titleLabel.fontSize = 24
        titleLabel.fontName = "PingFangSC-Heavy"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 60)
        panel.addChild(titleLabel)
        
        // 奥义名称
        let nameLabel = SKLabelNode(text: pattern.name)
        nameLabel.fontSize = 20
        nameLabel.fontName = "PingFangSC-Semibold"
        nameLabel.fontColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        nameLabel.position = CGPoint(x: 0, y: 30)
        panel.addChild(nameLabel)
        
        // 描述
        let descLabel = SKLabelNode(text: pattern.description)
        descLabel.fontSize = 16
        descLabel.fontName = "PingFangSC-Regular"
        descLabel.fontColor = .white
        descLabel.position = CGPoint(x: 0, y: 0)
        panel.addChild(descLabel)
        
        // 效果说明
        let effectLabel = SKLabelNode(text: "触发后自动连续消除3次！")
        effectLabel.fontSize = 14
        effectLabel.fontName = "PingFangSC-Regular"
        effectLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        effectLabel.position = CGPoint(x: 0, y: -30)
        panel.addChild(effectLabel)
        
        // 关闭按钮
        let closeBtn = SKLabelNode(text: "知道了")
        closeBtn.fontSize = 18
        closeBtn.fontName = "PingFangSC-Semibold"
        closeBtn.fontColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        closeBtn.position = CGPoint(x: 0, y: -70)
        closeBtn.name = "closeUltimateHint"
        panel.addChild(closeBtn)
        
        // 动画效果
        hintOverlay.alpha = 0
        hintOverlay.run(SKAction.fadeIn(withDuration: 0.3))
        
        // 自动关闭
        run(SKAction.sequence([
            SKAction.wait(forDuration: 8.0),
            SKAction.run { [weak self] in
                self?.closeUltimateHint()
            }
        ]), withKey: "autoCloseHint")
    }
    
    private func closeUltimateHint() {
        removeAction(forKey: "autoCloseHint")
        childNode(withName: "ultimateHint")?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    private func checkUltimatePattern() {
        guard let pattern = currentLevel.rules.ultimatePattern else { return }
        
        switch pattern.triggerCondition {
        case .specificPattern:
            if checkSpecificPattern(pattern: pattern) {
                triggerUltimatePattern(pattern: pattern)
            }
        case .swordTypeCount:
            // 根据关卡ID调整检测条件
            let requiredCount = currentLevel.id <= 5 ? 5 : 8
            let shenCount = grid.values.filter { $0.type == .shen }.count
            if currentLevel.id <= 5 {
                // 前期关卡：场上有5把剑以上
                if grid.count >= requiredCount {
                    triggerUltimatePattern(pattern: pattern)
                }
            } else {
                // 后期关卡：需要特定数量的神剑
                if shenCount >= requiredCount {
                    triggerUltimatePattern(pattern: pattern)
                }
            }
        case .comboCount:
            let requiredCombo = currentLevel.id <= 5 ? 3 : 5
            if comboCount >= requiredCombo {
                triggerUltimatePattern(pattern: pattern)
            }
        case .timeWindow:
            // 时间窗口触发逻辑
            break
        }
    }
    
    private func checkSpecificPattern(pattern: UltimatePattern) -> Bool {
        guard pattern.positions.count == pattern.swordTypes.count else { return false }
        
        for (index, position) in pattern.positions.enumerated() {
            let key = "\(position.q)_\(position.r)"
            guard let sword = grid[key] else { return false }
            if sword.type != pattern.swordTypes[index] {
                return false
            }
        }
        return true
    }
    
    private func triggerUltimatePattern(pattern: UltimatePattern) {
        // 史诗特效
        effectsManager.playUltimateEffect()
        effectsManager.showFeedbackText(pattern.effectDescription, at: .zero, style: .legendary)
        
        // 🌟 自动连续消除3次
        triggerAutoCombo(times: 3, reason: pattern.name)
    }
    
    // MARK: - Auto Combo System (自动连续消除系统)
    
    private func triggerAutoCombo(times: Int, reason: String) {
        // 显示简洁的触发提示，不遮挡游戏画面
        showAutoComboTrigger(times: times, reason: reason)
    }
    
    private func showAutoComboTrigger(times: Int, reason: String) {
        // 在顶部显示简洁的触发提示
        let triggerLabel = SKLabelNode(text: "🌟 \(reason) - 自动连消\(times)次 🌟")
        triggerLabel.fontSize = 24
        triggerLabel.fontName = "PingFangSC-Heavy"
        triggerLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        triggerLabel.position = CGPoint(x: 0, y: size.height/2 - 50)
        triggerLabel.zPosition = 300
        triggerLabel.name = "autoComboTrigger"
        addChild(triggerLabel)
        
        // 添加发光效果
        triggerLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ]),
            SKAction.wait(forDuration: 1.0),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // 播放触发特效
        effectsManager.playUltimateEffect()
        
        // 延迟0.5秒开始自动连续消除
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.startAutoComboSequence(times: times)
            }
        ]))
    }
    
    private func startAutoComboSequence(times: Int) {
        executeAutoComboStep(remainingTimes: times, currentStep: 1)
    }
    
    private func executeAutoComboStep(remainingTimes: Int, currentStep: Int) {
        guard remainingTimes > 0 else {
            // 完成所有自动消除
            finishAutoCombo()
            return
        }
        
        // 在右上角显示当前进度，不遮挡主要游戏区域
        showComboProgress(currentStep: currentStep, totalSteps: 3)
        
        // 执行一次自动消除
        performAutoComboMove { [weak self] in
            // 等待消除动画完成后继续下一次
            self?.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.2),
                SKAction.run {
                    self?.executeAutoComboStep(remainingTimes: remainingTimes - 1, currentStep: currentStep + 1)
                }
            ]))
        }
    }
    
    private func showComboProgress(currentStep: Int, totalSteps: Int) {
        // 移除之前的进度显示
        childNode(withName: "comboProgress")?.removeFromParent()
        
        // 在右上角显示进度
        let progressLabel = SKLabelNode(text: "连消 \(currentStep)/\(totalSteps)")
        progressLabel.fontSize = 18
        progressLabel.fontName = "PingFangSC-Semibold"
        progressLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        progressLabel.position = CGPoint(x: size.width/2 - 80, y: size.height/2 - 80)
        progressLabel.zPosition = 250
        progressLabel.name = "comboProgress"
        addChild(progressLabel)
        
        // 添加背景
        let progressBg = SKShapeNode(rectOf: CGSize(width: 100, height: 30), cornerRadius: 15)
        progressBg.fillColor = SKColor(white: 0.1, alpha: 0.8)
        progressBg.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.6)
        progressBg.lineWidth = 1
        progressBg.zPosition = -1
        progressLabel.addChild(progressBg)
        
        // 进度动画
        progressLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))
    }
    
    private func performAutoComboMove(completion: @escaping () -> Void) {
        // 寻找最佳的移动和消除机会
        if let bestMove = findBestAutoMove() {
            // 执行移动
            executeAutoMove(bestMove) { [weak self] in
                // 检查并执行消除
                self?.checkForMatches()
                completion()
            }
        } else {
            // 如果没有找到好的移动，随机移动一些剑来创造机会
            createAutoComboOpportunity {
                completion()
            }
        }
    }
    
    private func findBestAutoMove() -> AutoMove? {
        // 寻找能产生最多消除的移动
        var bestMove: AutoMove?
        var bestScore = 0
        
        let allSwords = Array(grid.values)
        
        for sword in allSwords {
            let currentPos = sword.gridPosition
            let neighbors = getNeighbors(q: currentPos.q, r: currentPos.r)
            
            for neighborPos in neighbors {
                let neighborKey = "\(neighborPos.q)_\(neighborPos.r)"
                
                // 检查是否可以移动到这个位置
                if grid[neighborKey] == nil && !blockedCells.contains(neighborKey) {
                    // 模拟移动并计算得分
                    let score = simulateMove(sword: sword, to: neighborPos)
                    if score > bestScore {
                        bestScore = score
                        bestMove = AutoMove(sword: sword, from: currentPos, to: neighborPos, score: score)
                    }
                }
            }
        }
        
        return bestMove
    }
    
    private func simulateMove(sword: Sword, to position: (q: Int, r: Int)) -> Int {
        // 临时移动剑并计算可能的消除数量
        let originalPos = sword.gridPosition
        let originalKey = "\(originalPos.q)_\(originalPos.r)"
        let newKey = "\(position.q)_\(position.r)"
        
        // 临时移动
        grid.removeValue(forKey: originalKey)
        grid[newKey] = sword
        sword.gridPosition = position
        
        // 计算消除数量
        let matches = findMatches(startNode: sword)
        let score = matches.count >= currentLevel.rules.minMergeCount ? matches.count : 0
        
        // 恢复原位置
        grid.removeValue(forKey: newKey)
        grid[originalKey] = sword
        sword.gridPosition = originalPos
        
        return score
    }
    
    private func executeAutoMove(_ move: AutoMove, completion: @escaping () -> Void) {
        let sword = move.sword
        let fromKey = "\(move.from.q)_\(move.from.r)"
        let toKey = "\(move.to.q)_\(move.to.r)"
        
        // 更新网格
        grid.removeValue(forKey: fromKey)
        grid[toKey] = sword
        sword.gridPosition = move.to
        
        // 播放移动动画 - 更加华丽和明显
        let targetPoint = hexToPixel(q: move.to.q, r: move.to.r)
        
        // 创建移动轨迹特效
        createMoveTrail(from: sword.position, to: targetPoint)
        
        // 高亮显示移动的剑 - 更加醒目
        sword.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.3),
                SKAction.colorize(with: .yellow, colorBlendFactor: 0.8, duration: 0.3)
            ]),
            SKAction.group([
                SKAction.move(to: targetPoint, duration: 0.6),
                SKAction.scale(to: 1.2, duration: 0.4)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.2),
                SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.2)
            ]),
            SKAction.run {
                completion()
            }
        ]))
        
        // 播放移动特效
        effectsManager.playTapRipple(at: targetPoint)
    }
    
    private func createMoveTrail(from startPoint: CGPoint, to endPoint: CGPoint) {
        // 创建移动轨迹粒子效果
        let trail = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        trail.path = path
        trail.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8)
        trail.lineWidth = 4
        trail.glowWidth = 8
        trail.zPosition = 150
        addChild(trail)
        
        // 轨迹动画
        trail.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    private func createAutoComboOpportunity(completion: @escaping () -> Void) {
        // 如果没有明显的消除机会，创造一些
        let allSwords = Array(grid.values).shuffled()
        
        if allSwords.count >= 2 {
            let sword1 = allSwords[0]
            let sword2 = allSwords[1]
            
            // 交换两把剑的位置
            _ = sword1.gridPosition
            _ = sword2.gridPosition
            
            swapSwords(sword1, sword2)
            
            // 等待交换动画完成
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run {
                    completion()
                }
            ]))
        } else {
            completion()
        }
    }
    
    private func finishAutoCombo() {
        // 移除进度显示
        childNode(withName: "comboProgress")?.removeFromParent()
        
        // 在中央显示完成提示，但很快消失
        let successLabel = SKLabelNode(text: "🎉 连续消除完成！🎉")
        successLabel.fontSize = 28
        successLabel.fontName = "PingFangSC-Heavy"
        successLabel.fontColor = SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0)
        successLabel.position = CGPoint(x: 0, y: 0)
        successLabel.zPosition = 300
        addChild(successLabel)
        
        // 快速显示和消失，不影响游戏体验
        successLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ]),
            SKAction.wait(forDuration: 0.8),
            SKAction.group([
                SKAction.scale(to: 0.8, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // 播放完成特效
        effectsManager.playUltimateEffect()
        
        // 延迟后补充剑阵
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.replenishSwords()
            }
        ]))
    }
    
    // 辅助结构体
    private struct AutoMove {
        let sword: Sword
        let from: (q: Int, r: Int)
        let to: (q: Int, r: Int)
        let score: Int
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
        
        // 使用新的游戏状态管理系统
        GameStateManager.shared.completeLevel(currentLevel.id, stars: stars, score: score)
        
        // 延迟显示结算界面
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.showLevelCompleteUI(stars: stars)
            }
        ]))
    }
    
    private func showLevelCompleteUI(stars: Int) {
        // 创建半透明背景
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.85)
        overlay.strokeColor = .clear
        overlay.zPosition = 400
        overlay.name = "levelCompleteOverlay"
        overlay.alpha = 0
        overlay.isUserInteractionEnabled = false
        addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.3))
        
        // 标题
        let titleLabel = SKLabelNode(text: "⚔️ 关卡完成 ⚔️")
        titleLabel.fontSize = 44
        titleLabel.fontName = "PingFangSC-Heavy"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 200)
        titleLabel.zPosition = 1
        overlay.addChild(titleLabel)
        
        // 修为称号显示
        let cultivationTitle = GameStateManager.shared.getCultivationTitle()
        let cultivationLabel = SKLabelNode(text: "修为境界: \(cultivationTitle)")
        cultivationLabel.fontSize = 20
        cultivationLabel.fontName = "PingFangSC-Semibold"
        cultivationLabel.fontColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        cultivationLabel.position = CGPoint(x: 0, y: 165)
        cultivationLabel.zPosition = 1
        overlay.addChild(cultivationLabel)
        
        // 星星显示
        let starContainer = SKNode()
        starContainer.position = CGPoint(x: 0, y: 130)
        starContainer.zPosition = 1
        for i in 0..<3 {
            let star = SKLabelNode(text: i < stars ? "⭐️" : "☆")
            star.fontSize = 50
            star.position = CGPoint(x: CGFloat(i - 1) * 70, y: 0)
            starContainer.addChild(star)
            
            // 星星动画
            if i < stars {
                star.setScale(0)
                star.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.3 + Double(i) * 0.2),
                    SKAction.group([
                        SKAction.scale(to: 1.2, duration: 0.2),
                        SKAction.rotate(byAngle: .pi * 2, duration: 0.4)
                    ]),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
            }
        }
        overlay.addChild(starContainer)
        
        // 分数信息
        let scoreInfo = SKLabelNode(text: "修为: \(score) / \(currentLevel.targetScore)")
        scoreInfo.fontSize = 22
        scoreInfo.fontName = "PingFangSC-Regular"
        scoreInfo.fontColor = .white
        scoreInfo.position = CGPoint(x: 0, y: 70)
        scoreInfo.zPosition = 1
        overlay.addChild(scoreInfo)
        
        let mergeInfo = SKLabelNode(text: "合成: \(mergeCount) / \(currentLevel.targetMerges)")
        mergeInfo.fontSize = 22
        mergeInfo.fontName = "PingFangSC-Regular"
        mergeInfo.fontColor = .white
        mergeInfo.position = CGPoint(x: 0, y: 45)
        mergeInfo.zPosition = 1
        overlay.addChild(mergeInfo)
        
        // 成就展示区域
        let achievementsTitle = SKLabelNode(text: "✨ 本关成就 ✨")
        achievementsTitle.fontSize = 20
        achievementsTitle.fontName = "PingFangSC-Semibold"
        achievementsTitle.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        achievementsTitle.position = CGPoint(x: 0, y: 10)
        achievementsTitle.zPosition = 1
        overlay.addChild(achievementsTitle)
        
        // 收集成就数据
        let achievements = collectAchievements()
        
        // 显示成就（最多显示4个）
        let displayAchievements = Array(achievements.prefix(4))
        let startY: CGFloat = -20
        let spacing: CGFloat = 35
        
        for (index, achievement) in displayAchievements.enumerated() {
            let achievementNode = createAchievementBadge(
                icon: achievement.icon,
                text: achievement.text,
                position: CGPoint(x: 0, y: startY - CGFloat(index) * spacing)
            )
            achievementNode.alpha = 0
            overlay.addChild(achievementNode)
            
            // 成就动画
            achievementNode.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.8 + Double(index) * 0.15),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.3),
                    SKAction.moveBy(x: 0, y: 5, duration: 0.3)
                ])
            ]))
        }
        
        // 按钮容器
        let buttonY: CGFloat = -170
        
        // 判断是否有下一关
        let hasNextLevel = GameStateManager.shared.unlockedLevels.contains(currentLevel.id + 1) || 
                          currentLevel.id < LevelConfig.shared.levels.count
        
        if hasNextLevel {
            // 下一关按钮
            let nextBtn = createStyledButton(
                text: "下一关 ➡️",
                position: CGPoint(x: 0, y: buttonY),
                color: SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0),
                name: "nextLevelBtn"
            )
            overlay.addChild(nextBtn)
            
            // 重新挑战按钮（小一点，放在下面）
            let restartBtn = createStyledButton(
                text: "重新挑战",
                position: CGPoint(x: 0, y: buttonY - 60),
                color: SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
                name: "restartBtn",
                fontSize: 18
            )
            overlay.addChild(restartBtn)
        } else {
            // 所有关卡完成
            let completeLabel = SKLabelNode(text: "🎉 所有关卡已完成 🎉")
            completeLabel.fontSize = 28
            completeLabel.fontName = "PingFangSC-Bold"
            completeLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            completeLabel.position = CGPoint(x: 0, y: buttonY + 20)
            completeLabel.zPosition = 1
            overlay.addChild(completeLabel)
            
            // 重新挑战按钮
            let restartBtn = createStyledButton(
                text: "重新挑战",
                position: CGPoint(x: 0, y: buttonY - 30),
                color: SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0),
                name: "restartBtn"
            )
            overlay.addChild(restartBtn)
        }
    }
    
    // 收集本关成就
    private func collectAchievements() -> [(icon: String, text: String)] {
        var achievements: [(icon: String, text: String)] = []
        
        // 最大连击
        if maxCombo >= 5 {
            achievements.append(("🔥", "连击大师 x\(maxCombo)"))
        } else if maxCombo >= 3 {
            achievements.append(("⚡️", "连击达人 x\(maxCombo)"))
        }
        
        // 完美合成
        if perfectMerges >= 3 {
            achievements.append(("💎", "完美合成 x\(perfectMerges)"))
        } else if perfectMerges >= 1 {
            achievements.append(("✨", "精准合成 x\(perfectMerges)"))
        }
        
        // 神剑合成
        if shenSwordsMerged >= 2 {
            achievements.append(("🗡️", "神剑宗师 x\(shenSwordsMerged)"))
        } else if shenSwordsMerged >= 1 {
            achievements.append(("⚔️", "神剑初成 x\(shenSwordsMerged)"))
        }
        
        // 连锁消除
        if totalChainClears >= 5 {
            achievements.append(("💥", "连锁大师 x\(totalChainClears)"))
        } else if totalChainClears >= 2 {
            achievements.append(("🌟", "连锁高手 x\(totalChainClears)"))
        }
        
        // 大招使用
        if ultimateUsed >= 3 {
            achievements.append(("⚡️", "万剑归宗 x\(ultimateUsed)"))
        } else if ultimateUsed >= 1 {
            achievements.append(("✨", "剑意爆发 x\(ultimateUsed)"))
        }
        
        // 步数效率
        if let moveLimit = currentLevel.rules.moveLimit {
            let efficiency = Double(moveCount) / Double(moveLimit)
            if efficiency <= 0.7 {
                achievements.append(("🎯", "步步为营"))
            }
        }
        
        // 时间效率
        if let timeLimit = currentLevel.rules.timeLimit {
            let timeUsed = timeLimit - timeRemaining
            let efficiency = timeUsed / timeLimit
            if efficiency <= 0.7 {
                achievements.append(("⏱️", "速战速决"))
            }
        }
        
        // 高分成就
        let scoreRatio = Double(score) / Double(currentLevel.targetScore)
        if scoreRatio >= 2.0 {
            achievements.append(("👑", "修为超凡"))
        } else if scoreRatio >= 1.5 {
            achievements.append(("🏆", "修为精进"))
        }
        
        // 如果没有特殊成就，至少显示一个基础成就
        if achievements.isEmpty {
            achievements.append(("✅", "关卡完成"))
        }
        
        return achievements
    }
    
    // 创建成就徽章
    private func createAchievementBadge(icon: String, text: String, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 1
        
        // 背景
        let background = SKShapeNode(rectOf: CGSize(width: 280, height: 28), cornerRadius: 14)
        background.fillColor = SKColor(white: 0.2, alpha: 0.8)
        background.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.5)
        background.lineWidth = 1
        container.addChild(background)
        
        // 图标
        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = 20
        iconLabel.position = CGPoint(x: -120, y: -7)
        iconLabel.horizontalAlignmentMode = .left
        container.addChild(iconLabel)
        
        // 文字
        let textLabel = SKLabelNode(text: text)
        textLabel.fontSize = 16
        textLabel.fontName = "PingFangSC-Regular"
        textLabel.fontColor = .white
        textLabel.position = CGPoint(x: -90, y: -6)
        textLabel.horizontalAlignmentMode = .left
        container.addChild(textLabel)
        
        return container
    }
    
    // 创建样式化按钮
    private func createStyledButton(text: String, position: CGPoint, color: SKColor, name: String, fontSize: CGFloat = 26) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = name
        container.zPosition = 1
        
        // 按钮背景
        let background = SKShapeNode(rectOf: CGSize(width: 240, height: 55), cornerRadius: 12)
        background.fillColor = color
        background.strokeColor = .white
        background.lineWidth = 2
        background.name = name
        container.addChild(background)
        
        // 按钮文字
        let label = SKLabelNode(text: text)
        label.fontSize = fontSize
        label.fontName = "PingFangSC-Semibold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)
        
        // 添加脉冲动画
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.6),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        container.run(SKAction.repeatForever(pulse))
        
        return container
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
        
        // 使用新的失败处理机制
        GameStateManager.shared.failLevel(currentLevel.id)
        
        let label = SKLabelNode(text: "剑道未成")
        label.fontSize = 45
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 80)
        overlay.addChild(label)
        
        let subLabel = SKLabelNode(text: "修为保留，再接再厉")
        subLabel.fontSize = 18
        subLabel.fontName = "PingFangSC-Regular"
        subLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        subLabel.position = CGPoint(x: 0, y: 40)
        overlay.addChild(subLabel)
        
        // 显示修为保留信息
        let cultivationLabel = SKLabelNode(text: "修为: \(GameStateManager.shared.cultivation) (已保留)")
        cultivationLabel.fontSize = 24
        cultivationLabel.fontName = "PingFangSC-Bold"
        cultivationLabel.fontColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        cultivationLabel.position = CGPoint(x: 0, y: 0)
        overlay.addChild(cultivationLabel)
        
        let scoreLabel = SKLabelNode(text: "本次得分: \(score)")
        scoreLabel.fontSize = 20
        scoreLabel.fontName = "PingFangSC-Regular"
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        scoreLabel.position = CGPoint(x: 0, y: -30)
        overlay.addChild(scoreLabel)
        
        let restartBtn = createButton(text: "再修一局", position: CGPoint(x: 0, y: -100))
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
        ultimatePatternHintShown = false  // 重置终极奥义提示状态
        
        // 重置成就追踪
        maxCombo = 0
        totalChainClears = 0
        ultimateUsed = 0
        perfectMerges = 0
        shenSwordsMerged = 0
        
        gameTimer?.invalidate()
        removeAction(forKey: "autoShuffle")
        
        // 清理关卡完成特效
        effectsManager.clearLevelCompleteEffects()
        
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
        
        // 显示新关卡的终极奥义提示
        showUltimatePatternHint()
        
        effectsManager.playLevelStartEffect(levelName: currentLevel.name)
    }
    
    private func goToNextLevel() {
        // 使用新的游戏状态管理系统进入下一关
        restartGame()
    }
    
    private func createButton(text: String, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        
        // 按钮背景
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 12)
        background.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        background.strokeColor = .white
        background.lineWidth = 2
        container.addChild(background)
        
        // 按钮文字
        let label = SKLabelNode(text: text)
        label.fontSize = 24
        label.fontName = "PingFangSC-Semibold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
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
        if allSwords.count >= 3 {
            // 随机选择3把剑，将它们改为相同类型
            let selectedSwords = allSwords.shuffled().prefix(3)
            let targetType = selectedSwords.first?.type ?? .fan
            
            for sword in selectedSwords.dropFirst() {
                sword.changeType(to: targetType)
            }
            
            effectsManager.showFeedbackText("剑阵重组!", at: .zero, style: .good)
        }
    }
}
