import SpriteKit
import Combine

/// 现代化的游戏场景 - 使用 MVVM 架构，完全迁移老代码UI和特效
public final class ModernGameScene: SKScene {
    
    // MARK: - Dependencies
    
    private var viewModel: GameSceneViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Managers
    internal var effectsManager: EffectsManager!
    
    // MARK: - Scene Layers (完全按老代码结构)
    
    internal var backgroundLayer: SKNode!
    internal var gridLayer: SKNode!
    internal var swordLayer: SKNode!
    internal var effectLayer: SKNode!
    internal var uiLayer: SKNode!
    
    // MARK: - Grid Data (迁移老代码网格系统)
    internal var grid: [String: Sword] = [:]
    internal var blockedCells: Set<String> = []
    
    // MARK: - Drag State (迁移老代码拖拽系统)
    internal var draggedSword: Sword?
    internal var originalPosition: CGPoint?
    internal var originalGridIndex: (q: Int, r: Int)?
    internal var lastDragPosition: CGPoint?
    
    // MARK: - Swap State (迁移老代码交换系统)
    internal var pendingSwap: SwapOperation?
    
    struct SwapOperation {
        let sword1: Sword
        let sword2: Sword
        let originalPos1: (q: Int, r: Int)
        let originalPos2: (q: Int, r: Int)
    }
    
    // MARK: - Game State (迁移老代码游戏状态)
    internal var energy: CGFloat = 0
    internal var maxEnergyForCurrentLevel: CGFloat = 100
    internal var score: Int = 0
    internal var mergeCount: Int = 0
    internal var comboCount: Int = 0
    internal var comboTimer: Timer?
    internal var moveCount: Int = 0
    internal var timeRemaining: TimeInterval = 0
    internal var gameTimer: Timer?
    internal var currentLevel: Level!
    internal var isGameOver: Bool = false
    internal var ultimatePatternHintShown: Bool = false
    
    // MARK: - Combo State Management (迁移老代码连消系统)
    internal var isInComboPhase: Bool = false
    internal var comboPhaseStartTime: TimeInterval = 0
    
    // MARK: - Performance Optimization
    internal var visitedCache = Set<String>()
    
    // MARK: - Achievement Tracking (迁移老代码成就系统)
    internal var maxCombo: Int = 0
    internal var totalChainClears: Int = 0
    internal var ultimateUsed: Int = 0
    internal var perfectMerges: Int = 0
    internal var shenSwordsMerged: Int = 0
    
    // MARK: - UI Elements (完全按老代码UI结构)
    internal var scoreLabel: SKLabelNode!
    internal var levelLabel: SKLabelNode!
    internal var goalLabel: SKLabelNode!
    internal var energyBarBg: SKShapeNode!
    internal var energyBarFill: SKShapeNode!
    internal var ultimateButton: SKNode!
    internal var comboLabel: SKLabelNode?
    internal var timerLabel: SKLabelNode?
    internal var moveLabel: SKLabelNode?
    
    // MARK: - Tutorial
    internal var tutorialStep: Int = 0
    internal var tutorialOverlay: SKNode?
    
    // MARK: - Grid Configuration
    private let gridConfig: GridConfiguration
    private let hexSize: CGFloat = 40
    private let gridRadius: Int = 3
    
    // MARK: - Initialization
    
    public init(viewModel: GameSceneViewModel, size: CGSize) {
        self.gridConfig = GridConfiguration(
            radius: gridRadius,
            hexSize: hexSize,
            center: CGPoint(x: 0, y: 0)  // 老代码使用中心为原点
        )
        
        super.init(size: size)
        
        // 确保场景初始化时的坐标系统正确
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.position = CGPoint.zero
        self.setScale(1.0)
        
        self.viewModel = viewModel
        self.viewModel.setGameScene(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Scene Lifecycle
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // 调试当前游戏状态
        GameStateManager.shared.debugCurrentState()
        
        // 临时修复：确保第二关总是解锁的
        GameStateManager.shared.forceUnlockLevel(2)
        

        
        // 设置场景的锚点为中心，确保坐标系统正确
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // 强制设置场景位置为中心
        position = CGPoint.zero
        
        // 确保场景缩放正确
        setScale(1.0)
        
        // 完全按老代码的初始化顺序
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0)
        
        // 获取当前关卡
        currentLevel = LevelConfig.shared.getCurrentLevel()
        maxEnergyForCurrentLevel = GameConfig.maxEnergy(for: currentLevel.id)
        
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
        
        if !GameStateManager.shared.tutorialCompleted {
            showTutorial()
        }
        
        // 监听神剑合成通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDivineSwordMerge),
            name: NSNotification.Name("DivineSwordMerged"),
            object: nil
        )
        
        setupBindings()
    }
    

    
    // MARK: - Audio Setup (迁移老代码音效系统)
    
    /// 初始化音效系统
    private func setupAudio() {
        // 启用系统音效辅助工具
        SystemSoundHelper.shared.setEnabled(true)
        
        // 确保音效系统启用
        SoundManager.shared.setEnabled(true)
        
        // 设置音量
        SoundManager.shared.setMusicVolume(0.05)  // 背景音乐 5%
        SoundManager.shared.setSFXVolume(0.7)     // 音效 70%
        
        print("🎵 音效系统已初始化")
    }
    
    // MARK: - Setup (完全迁移老代码设置方法)
    
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
    
    // MARK: - Match Logic (完全迁移老代码匹配逻辑)
    
    internal func checkForMatches() {
        visitedCache.removeAll(keepingCapacity: true)
        var hadMatches = false
        var totalMatchCount = 0
        
        for (key, sword) in grid {
            if visitedCache.contains(key) { continue }
            
            let matches = findMatches(startNode: sword)
            if matches.count >= currentLevel.rules.minMergeCount {
                mergeSwords(matches)
                hadMatches = true
                totalMatchCount += matches.count
                for m in matches {
                    visitedCache.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
                }
            }
        }
        
        if hadMatches {
            // 进入连消阶段，暂停时间和步数消耗
            enterComboPhase()
            
            // 根据消除数量给予不同反馈
            giveFeedbackForMatchCount(totalMatchCount)
            
            // 检查终极奥义触发
            checkUltimatePattern()
            
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.run { [weak self] in 
                    self?.replenishSwords()
                    // 补充完成后，检查是否还有连消
                    self?.run(SKAction.sequence([
                        SKAction.wait(forDuration: 0.2),
                        SKAction.run { [weak self] in
                            self?.checkForContinuousMatches()
                        }
                    ]))
                }
            ]))
        } else {
            // 退出连消阶段
            exitComboPhase()
            resetCombo()
        }
    }
    
    internal func findMatches(startNode: Sword) -> [Sword] {
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
    
    // MARK: - UI Update Methods (完全迁移老代码UI更新)
    
    internal func updateUI() {
        // 显示累积修为积分而不是当前关卡分数
        let oldText = scoreLabel.text ?? "0"
        let totalCultivation = GameStateManager.shared.cultivation + score  // 当前修为 + 本关得分
        scoreLabel.text = "\(totalCultivation)"
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
        
        // 更新时间和步数显示（考虑连消状态）
        updateTimerDisplay()
        updateMoveDisplay()
        
        // Energy bar and value display
        let percentage = energy / maxEnergyForCurrentLevel
        let barWidth: CGFloat = 200
        let fillWidth = barWidth * percentage - 4
        
        let newPath = CGPath(roundedRect: CGRect(x: 0, y: -6, width: max(0, fillWidth), height: 12),
                             cornerWidth: 6, cornerHeight: 6, transform: nil)
        energyBarFill.path = newPath
        
        // Update energy value display
        if let energyValueLabel = uiLayer.childNode(withName: "energyValueLabel") as? SKLabelNode {
            energyValueLabel.text = "\(Int(energy))/\(Int(maxEnergyForCurrentLevel))"
            
            // 能量满时变色
            if energy >= maxEnergyForCurrentLevel {
                energyValueLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            } else {
                energyValueLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
            }
        }
        
        // Ultimate button
        if energy >= maxEnergyForCurrentLevel {
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
    
    // MARK: - Placeholder Methods (需要实现的方法)
    
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
            
            // 如果在连消阶段，暂停时间消耗
            if self.isInComboPhase {
                return
            }
            
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
    
    internal func shouldCreateTile(q: Int, r: Int, formation: FormationType, radius: Int) -> Bool {
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
        setupUltimatePatternDisplay()  // 添加终极奥义显示
        
        // 验证UI元素位置是否正确
        verifyUIPositioning()
    }
    
    /// 验证UI元素位置是否正确，并在需要时进行修正
    private func verifyUIPositioning() {
        // 检查标题位置
        if let titleLabel = uiLayer.children.first(where: { $0 is SKLabelNode && ($0 as! SKLabelNode).text == "万剑归宗" }) as? SKLabelNode {
            let expectedY = size.height/2 - 70
            
            // 如果位置明显不对，重新设置
            if abs(titleLabel.position.y - expectedY) > 50 {
                titleLabel.position.y = expectedY
            }
        }
        
        // 检查能量条位置
        if let energyBar = energyBarBg {
            let expectedY = -size.height/2 + 165
            
            if abs(energyBar.position.y - expectedY) > 50 {
                energyBar.position.y = expectedY
                energyBarFill.position.y = expectedY
            }
        }
        
        // 检查面板位置
        if let leftPanel = uiLayer.children.first(where: { $0.position.x < 0 && abs($0.position.x + size.width/2 - 85) < 10 }) {
            let expectedY = -size.height/2 + 110
            
            if abs(leftPanel.position.y - expectedY) > 50 {
                leftPanel.position.y = expectedY
            }
        }
        
        if let rightPanel = uiLayer.childNode(withName: "rightPanel") {
            let expectedY = -size.height/2 + 110
            
            if abs(rightPanel.position.y - expectedY) > 50 {
                rightPanel.position.y = expectedY
            }
        }
    }
    
    private func setupScorePanel() {
        // Left panel - Score (修为面板) - 作为基准位置
        let baseY = -size.height/2 + 110  // 基准Y坐标
        let panelHeight: CGFloat = 90     // 统一面板高度
        
        let leftPanel = createGlassPanel(size: CGSize(width: 140, height: panelHeight))
        leftPanel.position = CGPoint(x: -size.width/2 + 85, y: baseY)
        uiLayer.addChild(leftPanel)
        
        let scoreIcon = SKLabelNode(text: "修")
        scoreIcon.fontSize = 18
        scoreIcon.fontName = "PingFangSC-Bold"
        scoreIcon.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        scoreIcon.position = CGPoint(x: -50, y: 15)  // 调整到面板上部
        leftPanel.addChild(scoreIcon)
        
        scoreLabel = SKLabelNode(text: "\(GameStateManager.shared.cultivation)")
        scoreLabel.fontSize = 22
        scoreLabel.fontName = "PingFangSC-Bold"
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: -25, y: 12)  // 调整到面板上部
        leftPanel.addChild(scoreLabel)
        
        // Right panel - Merge count with Ultimate Pattern (阵法面板) - 与左面板对齐
        let rightPanel = createGlassPanel(size: CGSize(width: 140, height: panelHeight))  // 相同高度
        rightPanel.position = CGPoint(x: size.width/2 - 85, y: baseY)  // 相同Y坐标
        rightPanel.name = "rightPanel"
        uiLayer.addChild(rightPanel)
        
        let mergeIcon = SKLabelNode(text: "阵")
        mergeIcon.fontSize = 18
        mergeIcon.fontName = "PingFangSC-Bold"
        mergeIcon.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0)
        mergeIcon.position = CGPoint(x: -50, y: 15)  // 与左面板图标对齐
        rightPanel.addChild(mergeIcon)
        
        let mergeLabel = SKLabelNode(text: "0/\(currentLevel.targetMerges)")
        mergeLabel.fontSize = 20
        mergeLabel.fontName = "PingFangSC-Bold"
        mergeLabel.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0)
        mergeLabel.horizontalAlignmentMode = .left
        mergeLabel.position = CGPoint(x: -25, y: 12)  // 与左面板数值对齐
        mergeLabel.name = "mergeLabel"
        rightPanel.addChild(mergeLabel)
        
        // 在右面板中添加终极奥义显示
        setupUltimatePatternInPanel(rightPanel)
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
        let barY = -size.height/2 + 165  // 向上移动20像素，避免与面板重叠
        
        let energyLabel = SKLabelNode(text: "剑意")
        energyLabel.fontSize = 12
        energyLabel.fontName = "PingFangSC-Regular"
        energyLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        energyLabel.position = CGPoint(x: -barWidth/2 - 30, y: barY - 5)
        uiLayer.addChild(energyLabel)
        
        // 添加能量数值显示
        let energyValueLabel = SKLabelNode(text: "0/\(Int(maxEnergyForCurrentLevel))")
        energyValueLabel.fontSize = 11
        energyValueLabel.fontName = "PingFangSC-Regular"
        energyValueLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        energyValueLabel.position = CGPoint(x: barWidth/2 + 40, y: barY - 5)
        energyValueLabel.name = "energyValueLabel"
        uiLayer.addChild(energyValueLabel)
        
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
        
        let btnBg = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 12)
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
    
    private func setupBindings() {
        // 设置ViewModel绑定
        viewModel.$gameState
            .sink { [weak self] state in
                self?.handleGameStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleGameStateChange(_ state: GameState) {
        // 处理游戏状态变化
        switch state {
        case .playing:
            break
        case .paused:
            break
        case .gameOver(let reason):
            if reason == .victory {
                checkLevelCompletion()
            } else {
                triggerGameOver()
            }
        case .idle:
            break
        }
    }
    
    @objc private func handleDivineSwordMerge(_ notification: Notification) {
        guard let sword = notification.object as? Sword else { return }
        
        // 神剑合成触发特殊奖励
        let bonusScore = 1000
        addScore(bonusScore)
        
        // 特殊效果：清除周围所有剑
        let neighbors = getNeighbors(q: sword.gridPosition.q, r: sword.gridPosition.r)
        for nPos in neighbors {
            let key = "\(nPos.q)_\(nPos.r)"
            if let neighborSword = grid[key] {
                removeSword(neighborSword)
                addScore(50)
            }
        }
        
        // 播放特殊特效
        let swordPos = hexToPixel(q: sword.gridPosition.q, r: sword.gridPosition.r)
        effectsManager.playDivineSwordEffect(at: swordPos)
        effectsManager.showFeedbackText("神剑归宗！+\(bonusScore)", at: swordPos, style: .legendary)
        
        // 增加大量能量
        addEnergy(50)
        
        // 记录成就
        GameStateManager.shared.recordMerge(type: .shen, combo: comboCount)
        
        updateUI()
        
        // 延迟补充剑阵
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.replenishSwords()
            }
        ]))
    }
    
    // MARK: - Coordinate Conversion (完全迁移老代码坐标转换)
    
    internal func hexToPixel(q: Int, r: Int) -> CGPoint {
        let size = GameConfig.tileRadius + GameConfig.gridSpacing
        let sqrt3 = sqrt(3.0)
        let x = size * (sqrt3 * CGFloat(q) + sqrt3 / 2.0 * CGFloat(r))
        let y = size * (3.0 / 2.0 * CGFloat(r))
        return CGPoint(x: x, y: y)
    }
    
    internal func pixelToHex(point: CGPoint) -> (q: Int, r: Int) {
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
    
    private func enterComboPhase() {
        if !isInComboPhase {
            isInComboPhase = true
            comboPhaseStartTime = CACurrentMediaTime()
            
            // 显示连消状态指示
            showComboPhaseIndicator(true)
            
            print("🔥 进入连消阶段 - 时间和步数暂停消耗")
        }
    }
    
    private func exitComboPhase() {
        if isInComboPhase {
            isInComboPhase = false
            let comboDuration = CACurrentMediaTime() - comboPhaseStartTime
            
            // 隐藏连消状态指示
            showComboPhaseIndicator(false)
            
            print("✅ 退出连消阶段 - 连消持续了 \(String(format: "%.1f", comboDuration)) 秒")
        }
    }
    
    private func showComboPhaseIndicator(_ show: Bool) {
        // 移除之前的指示器
        childNode(withName: "comboPhaseIndicator")?.removeFromParent()
        
        if show {
            // 创建连消阶段指示器
            let indicator = SKLabelNode(text: "🔥 连消中...")
            indicator.fontSize = 16
            indicator.fontName = "PingFangSC-Semibold"
            indicator.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
            indicator.position = CGPoint(x: 0, y: size.height/2 - 50)
            indicator.zPosition = 250
            indicator.name = "comboPhaseIndicator"
            addChild(indicator)
            
            // 添加脉冲动画
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            indicator.run(SKAction.repeatForever(pulse))
            
            // 添加背景高亮
            let background = SKShapeNode(rectOf: CGSize(width: 120, height: 25), cornerRadius: 12)
            background.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.2)
            background.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.6)
            background.lineWidth = 1
            background.position = .zero
            background.zPosition = -1
            indicator.addChild(background)
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
        
        // 备用系统音效
        if count >= 5 {
            SystemSoundHelper.shared.playCombo()
        } else if count >= 3 {
            SystemSoundHelper.shared.playSuccess()
        }
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
    
    private func addScore(_ points: Int) {
        score += points
    }
    
    private func addEnergy(_ value: CGFloat) {
        let oldEnergy = energy
        energy = min(energy + value, maxEnergyForCurrentLevel)
        
        // 能量满时开始脉冲
        if energy >= maxEnergyForCurrentLevel && oldEnergy < maxEnergyForCurrentLevel {
            effectsManager.startEnergyFullPulse(around: ultimateButton)
            effectsManager.showFeedbackText("剑意已满!", at: CGPoint(x: 0, y: -100), style: .perfect)
            SoundManager.shared.playEnergyFull()
            SystemSoundHelper.shared.playSuccess() // 备用系统音效
        }
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
    }
    
    private func checkForContinuousMatches() {
        // 检查是否还有可能的连消
        visitedCache.removeAll(keepingCapacity: true)
        var hasMatches = false
        
        for (key, sword) in grid {
            if visitedCache.contains(key) { continue }
            
            let matches = findMatches(startNode: sword)
            if matches.count >= currentLevel.rules.minMergeCount {
                hasMatches = true
                break
            }
        }
        
        if hasMatches {
            // 还有连消，继续处理
            checkForMatches()
        } else {
            // 没有更多连消，退出连消阶段
            exitComboPhase()
        }
    }
    
    private func setupLevelConstraints() {
        let rules = currentLevel.rules
        
        // 清理之前的约束UI
        timerLabel?.removeFromParent()
        moveLabel?.removeFromParent()
        timerLabel = nil
        moveLabel = nil
        
        let constraintY: CGFloat = size.height/2 - 175
        
        // 时间限制显示
        if let timeLimit = rules.timeLimit {
            timeRemaining = timeLimit
            timerLabel = SKLabelNode(text: "⏱ \(Int(timeRemaining))s")
            timerLabel?.fontSize = 20
            timerLabel?.fontName = "PingFangSC-Bold"
            timerLabel?.fontColor = .white
            timerLabel?.position = CGPoint(x: -80, y: constraintY)
            uiLayer.addChild(timerLabel!)
        }
        
        // 步数限制显示
        if let moveLimit = rules.moveLimit {
            let xPosition: CGFloat = rules.timeLimit != nil ? 80 : 0  // 如果有时间限制，放右边
            moveLabel = SKLabelNode(text: "👆 \(moveLimit - moveCount)步")
            moveLabel?.fontSize = 20
            moveLabel?.fontName = "PingFangSC-Bold"
            moveLabel?.fontColor = .white
            moveLabel?.position = CGPoint(x: xPosition, y: constraintY)
            uiLayer.addChild(moveLabel!)
        }
    }
    
    private func updateTimerDisplay() {
        if isInComboPhase {
            timerLabel?.text = "⏱ \(Int(timeRemaining))s ⏸️"
            timerLabel?.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        } else {
            timerLabel?.text = "⏱ \(Int(timeRemaining))s"
            if timeRemaining <= 10 {
                timerLabel?.fontColor = .red
            } else {
                timerLabel?.fontColor = .white
            }
        }
    }
    
    internal func updateMoveDisplay() {
        if let moveLimit = currentLevel.rules.moveLimit {
            let remaining = moveLimit - moveCount
            
            if isInComboPhase {
                moveLabel?.text = "👆 \(remaining)步 ⏸️"
                moveLabel?.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
            } else {
                moveLabel?.text = "👆 \(remaining)步"
                if remaining <= 5 {
                    moveLabel?.fontColor = .red
                } else {
                    moveLabel?.fontColor = .white
                }
            }
        }
    }
    
    internal func checkLevelCompletion() {
        print("🎯 checkLevelCompletion: score=\(score), targetScore=\(currentLevel.targetScore), mergeCount=\(mergeCount), targetMerges=\(currentLevel.targetMerges)")
        
        // 🔧 更宽松的完成条件检查
        let scoreCompleted = score >= currentLevel.targetScore
        let mergeCompleted = mergeCount >= currentLevel.targetMerges
        
        if scoreCompleted && mergeCompleted {
            print("✅ 关卡完成条件满足！触发关卡完成")
            triggerLevelComplete()
        } else {
            print("❌ 关卡完成条件未满足 - 分数完成:\(scoreCompleted), 合成完成:\(mergeCompleted)")
            
            // 🔧 如果接近完成，给予提示
            if scoreCompleted || mergeCompleted {
                let message = scoreCompleted ? "还需要\(currentLevel.targetMerges - mergeCount)次合成!" : "还需要\(currentLevel.targetScore - score)分!"
                effectsManager.showFeedbackText(message, at: CGPoint(x: 0, y: 100), style: .good)
            }
        }
    }
    
    private func triggerLevelComplete() {
        if childNode(withName: "levelCompleteOverlay") != nil { return }
        isGameOver = true
        gameTimer?.invalidate()
        removeAction(forKey: "autoShuffle")
        
        let stars = currentLevel.calculateStars(score: score)
        let completedLevelId = currentLevel.id  // 保存完成的关卡ID
        
        // 庆祝特效
        effectsManager.playLevelCompleteEffect(stars: stars)
        
        // 使用新的游戏状态管理系统
        GameStateManager.shared.completeLevel(completedLevelId, stars: stars, score: score)
        
        // 延迟显示结算界面
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.showLevelCompleteUI(stars: stars, completedLevelId: completedLevelId)
            }
        ]))
    }
    
    private func updateComboDisplay(comboCount: Int) {
        // 更新连击显示
        if comboCount > 1 {
            comboLabel?.text = "连击 x\(comboCount)"
            comboLabel?.isHidden = false
        } else {
            comboLabel?.isHidden = true
        }
    }
    
    private func updateFeedbackDisplay(show: Bool) {
        // 更新反馈显示
        if show {
            // 显示反馈
        } else {
            // 隐藏反馈
        }
    }
    
    internal func triggerUltimate() {
        energy = 0
        updateUI()
        
        ultimateUsed += 1
        GameStateManager.shared.recordUltimate()
        
        // 🌟 新功能：万剑归宗强化 - 自动连续消除3次
        triggerAutoCombo(times: 3, reason: "万剑归宗")
    }
    
    internal func triggerGameOver() {
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
    
    internal func goToNextLevel() {
        print("🚀 goToNextLevel: 开始进入下一关")
        print("🚀 当前GameStateManager.currentLevel: \(GameStateManager.shared.currentLevel)")
        
        // 进入下一关，保留修为积分
        // 只重置游戏状态，不重置修为积分
        grid.values.forEach { $0.removeFromParent() }
        grid.removeAll()
        blockedCells.removeAll()
        
        // 重置当前关卡状态，但保留修为积分显示
        score = 0  // 重置当前关卡分数
        energy = 0
        mergeCount = 0
        comboCount = 0
        moveCount = 0
        isGameOver = false
        ultimatePatternHintShown = false
        
        // 重置成就追踪
        maxCombo = 0
        totalChainClears = 0
        ultimateUsed = 0
        perfectMerges = 0
        shenSwordsMerged = 0
        
        // 清理交换状态
        pendingSwap = nil
        visitedCache.removeAll()
        
        gameTimer?.invalidate()
        removeAction(forKey: "autoShuffle")
        
        // 清理关卡完成特效
        effectsManager.clearLevelCompleteEffects()
        
        children.filter { $0.zPosition == 400 }.forEach { $0.removeFromParent() }
        gridLayer.removeAllChildren()
        
        // 清理约束UI
        timerLabel?.removeFromParent()
        moveLabel?.removeFromParent()
        timerLabel = nil
        moveLabel = nil
        
        // 获取新的当前关卡
        currentLevel = LevelConfig.shared.getCurrentLevel()
        print("🚀 新的currentLevel: \(currentLevel.name) (id: \(currentLevel.id))")
        maxEnergyForCurrentLevel = GameConfig.maxEnergy(for: currentLevel.id)  // 更新最大能量
        timeRemaining = currentLevel.rules.timeLimit ?? 0
        
        levelLabel.text = "第\(currentLevel.id)关 - \(currentLevel.name)"
        goalLabel.text = "目标: \(currentLevel.targetScore)分 | \(currentLevel.targetMerges)次合成"
        
        createGrid()
        setupLevelRules()
        setupLevelConstraints()  // 重新设置时间和步数限制显示
        setupUltimatePatternDisplay()  // 重新设置终极奥义显示
        updateUI()  // 这里会显示累积的修为积分
        spawnInitialSwords()
        
        effectsManager.playLevelStartEffect(levelName: currentLevel.name)
    }
    
    internal func restartGame() {
        grid.values.forEach { $0.removeFromParent() }
        grid.removeAll()
        blockedCells.removeAll()
        
        // 重置当前关卡状态，但保留修为积分显示
        score = 0  // 重置当前关卡分数
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
        
        // 清理交换状态
        pendingSwap = nil
        visitedCache.removeAll()
        
        gameTimer?.invalidate()
        removeAction(forKey: "autoShuffle")
        
        // 清理关卡完成特效
        effectsManager.clearLevelCompleteEffects()
        
        children.filter { $0.zPosition == 400 }.forEach { $0.removeFromParent() }
        gridLayer.removeAllChildren()
        
        // 清理约束UI
        timerLabel?.removeFromParent()
        moveLabel?.removeFromParent()
        timerLabel = nil
        moveLabel = nil
        
        currentLevel = LevelConfig.shared.getCurrentLevel()
        maxEnergyForCurrentLevel = GameConfig.maxEnergy(for: currentLevel.id)  // 更新最大能量
        timeRemaining = currentLevel.rules.timeLimit ?? 0
        
        levelLabel.text = "第\(currentLevel.id)关 - \(currentLevel.name)"
        goalLabel.text = "目标: \(currentLevel.targetScore)分 | \(currentLevel.targetMerges)次合成"
        
        createGrid()
        setupLevelRules()
        setupLevelConstraints()  // 重新设置时间和步数限制显示
        setupUltimatePatternDisplay()  // 重新设置终极奥义显示
        updateUI()  // 这里会显示累积的修为积分
        spawnInitialSwords()
        
        effectsManager.playLevelStartEffect(levelName: currentLevel.name)
    }
    
    internal func skipTutorial() {
        removeAction(forKey: "tutorialAdvance")
        tutorialOverlay?.removeFromParent()
        tutorialOverlay = nil
        GameStateManager.shared.tutorialCompleted = true
    }
    
    internal func closeUltimateHint() {
        removeAction(forKey: "autoCloseHint")
        childNode(withName: "ultimateHint")?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
}