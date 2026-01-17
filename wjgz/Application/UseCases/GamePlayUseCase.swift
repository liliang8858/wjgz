import Foundation
import Combine

/// 游戏玩法用例 - 协调游戏核心逻辑
public final class GamePlayUseCase: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var gameState: GameState = .idle
    @Published public private(set) var score: Int = 0
    @Published public private(set) var energy: CGFloat = 0
    @Published public private(set) var moveCount: Int = 0
    @Published public private(set) var timeRemaining: TimeInterval = 0
    @Published public private(set) var comboCount: Int = 0
    @Published public private(set) var isInComboPhase: Bool = false
    
    // MARK: - Dependencies
    
    private let gameGrid: GameGrid
    private let matchEngine: MatchEngine
    private let scoreCalculator: ScoreCalculator
    private let audioService: AudioServiceProtocol
    private let effectsService: EffectsServiceProtocol
    private let levelConfig: Level
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var gameTimer: Timer?
    private var comboTimer: Timer?
    
    // MARK: - Initialization
    
    public init(
        gameGrid: GameGrid,
        matchEngine: MatchEngine,
        scoreCalculator: ScoreCalculator,
        audioService: AudioServiceProtocol,
        effectsService: EffectsServiceProtocol,
        levelConfig: Level
    ) {
        self.gameGrid = gameGrid
        self.matchEngine = matchEngine
        self.scoreCalculator = scoreCalculator
        self.audioService = audioService
        self.effectsService = effectsService
        self.levelConfig = levelConfig
        
        setupInitialState()
    }
    
    // MARK: - Public Methods
    
    /// 开始游戏
    public func startGame() {
        gameState = .playing
        setupGameTimer()
        spawnInitialSwords()
        audioService.playBackgroundMusic()
    }
    
    /// 暂停游戏
    public func pauseGame() {
        gameState = .paused
        gameTimer?.invalidate()
        audioService.pauseBackgroundMusic()
    }
    
    /// 恢复游戏
    public func resumeGame() {
        gameState = .playing
        setupGameTimer()
        audioService.resumeBackgroundMusic()
    }
    
    /// 处理剑的拖拽放下
    public func handleSwordDrop(from fromPosition: HexPosition, to toPosition: HexPosition) {
        guard gameState == .playing && !isInComboPhase else { return }
        
        // 检查移动是否有效
        guard canMoveSword(from: fromPosition, to: toPosition) else {
            audioService.playSound(.error)
            return
        }
        
        // 执行移动
        if gameGrid.swapSwords(from: fromPosition, to: toPosition) {
            audioService.playSound(.drop)
            incrementMoveCount()
            
            // 检查匹配
            checkAndProcessMatches()
        }
    }
    
    /// 触发终极技能
    public func triggerUltimateSkill() {
        guard energy >= 100 else { return }
        
        energy = 0
        audioService.playSound(.ultimate)
        effectsService.playUltimateEffect()
        
        // 执行终极技能逻辑
        executeUltimateSkill()
    }
    
    /// 触发自动连消
    public func triggerAutoCombo() {
        guard !isInComboPhase else { return }
        
        startComboPhase()
        processAutoCombo()
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        score = 0
        energy = 0
        moveCount = 0
        timeRemaining = levelConfig.rules.timeLimit ?? 0
        comboCount = 0
        isInComboPhase = false
    }
    
    private func setupGameTimer() {
        guard let timeLimit = levelConfig.rules.timeLimit else { return }
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateGameTime()
        }
    }
    
    private func updateGameTime() {
        guard timeRemaining > 0 else {
            endGame(reason: .timeUp)
            return
        }
        
        if !isInComboPhase {
            timeRemaining -= 1
        }
    }
    
    private func spawnInitialSwords() {
        // 根据关卡配置生成初始剑
        let formation = levelConfig.formationType
        let positions = FormationGenerator.generatePositions(for: formation, in: gameGrid)
        
        for position in positions {
            let swordType = SwordType.random()
            let sword = Sword(type: swordType, position: position)
            gameGrid.setSword(sword, at: position)
        }
    }
    
    private func canMoveSword(from: HexPosition, to: HexPosition) -> Bool {
        // 检查位置有效性
        guard gameGrid.isValidPosition(from) && gameGrid.isValidPosition(to) else {
            return false
        }
        
        // 检查是否相邻
        let neighbors = gameGrid.getNeighbors(of: from)
        guard neighbors.contains(to) else { return false }
        
        // 检查目标位置是否可用
        return gameGrid.canPlaceSword(at: to) || gameGrid.sword(at: to) != nil
    }
    
    private func checkAndProcessMatches() {
        let matchResult = matchEngine.findAllMatches()
        
        if matchResult.hasMatches {
            processMatches(matchResult.matches)
        } else {
            // 检查是否还有可能的匹配
            if !matchEngine.hasPossibleMatches() {
                shuffleGrid()
            }
        }
    }
    
    private func processMatches(_ matches: [MatchEngine.MatchGroup]) {
        for matchGroup in matches {
            // 播放音效和特效
            playMatchEffects(for: matchGroup)
            
            // 计算分数
            let matchScore = scoreCalculator.calculateMatchScore(
                swordType: matchGroup.swordType,
                count: matchGroup.swords.count,
                comboMultiplier: comboCount + 1
            )
            score += matchScore
            
            // 增加能量
            energy = min(100, energy + CGFloat(matchGroup.swords.count * 5))
            
            // 移除匹配的剑
            for position in matchGroup.positions {
                gameGrid.setSword(nil, at: position)
            }
            
            // 生成升级剑
            if let upgradedType = matchGroup.upgradedSwordType {
                let upgradedSword = Sword(type: upgradedType, position: matchGroup.centerPosition)
                gameGrid.setSword(upgradedSword, at: matchGroup.centerPosition)
                
                // 触发特殊效果
                if matchGroup.triggersSpecialEffect {
                    triggerSpecialEffect(for: upgradedType, at: matchGroup.centerPosition)
                }
            }
        }
        
        // 补充新剑
        replenishSwords()
        
        // 检查连消
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkForContinuousMatches()
        }
    }
    
    private func playMatchEffects(for matchGroup: MatchEngine.MatchGroup) {
        switch matchGroup.swordType {
        case .fan:
            audioService.playSound(.mergeFan)
            effectsService.playMergeBurst(at: matchGroup.centerPosition, intensity: .small)
        case .ling:
            audioService.playSound(.mergeLing)
            effectsService.playMergeBurst(at: matchGroup.centerPosition, intensity: .medium)
        case .xian:
            audioService.playSound(.mergeXian)
            effectsService.playMergeBurst(at: matchGroup.centerPosition, intensity: .large)
        case .shen:
            audioService.playSound(.mergeShen)
            effectsService.playMergeBurst(at: matchGroup.centerPosition, intensity: .epic)
        }
    }
    
    private func triggerSpecialEffect(for swordType: SwordType, at position: HexPosition) {
        switch swordType {
        case .ling:
            // 清除同行
            clearRow(at: position)
        case .xian:
            // 清除周围区域
            clearArea(around: position)
        case .shen:
            // 触发神剑特效
            triggerDivineSwordEffect(at: position)
        case .fan:
            break
        }
    }
    
    private func clearRow(at position: HexPosition) {
        let allPositions = gameGrid.getAllSwordPositions()
        let sameRowPositions = allPositions.filter { $0.r == position.r }
        
        for pos in sameRowPositions {
            gameGrid.setSword(nil, at: pos)
        }
        
        effectsService.playRowClearEffect(row: position.r)
        audioService.playSound(.chainClear)
    }
    
    private func clearArea(around position: HexPosition) {
        let neighbors = gameGrid.getNeighbors(of: position)
        
        for neighborPos in neighbors {
            gameGrid.setSword(nil, at: neighborPos)
        }
        
        effectsService.playAreaClearExplosion(at: position)
        audioService.playSound(.explosion)
    }
    
    private func triggerDivineSwordEffect(at position: HexPosition) {
        // 神剑出世 - 清除大范围区域
        let allPositions = gameGrid.getAllSwordPositions()
        let nearbyPositions = allPositions.filter { pos in
            position.distance(to: pos) <= 2
        }
        
        for pos in nearbyPositions {
            gameGrid.setSword(nil, at: pos)
        }
        
        effectsService.playDivineSwordEffect(at: position)
        audioService.playSound(.ultimate)
    }
    
    private func replenishSwords() {
        let emptyPositions = gameGrid.getAllSwordPositions().filter { pos in
            gameGrid.sword(at: pos) == nil
        }
        
        for position in emptyPositions {
            let swordType = SwordType.random()
            let sword = Sword(type: swordType, position: position)
            gameGrid.setSword(sword, at: position)
        }
    }
    
    private func checkForContinuousMatches() {
        let matchResult = matchEngine.findAllMatches()
        
        if matchResult.hasMatches {
            comboCount += 1
            startComboPhase()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.processMatches(matchResult.matches)
            }
        } else {
            endComboPhase()
        }
    }
    
    private func startComboPhase() {
        isInComboPhase = true
        comboTimer?.invalidate()
        
        comboTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.endComboPhase()
        }
    }
    
    private func endComboPhase() {
        isInComboPhase = false
        comboTimer?.invalidate()
        
        if comboCount > 0 {
            effectsService.playComboEndEffect(comboCount: comboCount)
            comboCount = 0
        }
    }
    
    private func executeUltimateSkill() {
        // 根据关卡配置执行不同的终极技能
        if let ultimatePattern = levelConfig.rules.ultimatePattern {
            executeUltimatePattern(ultimatePattern)
        } else {
            // 默认终极技能：清除所有最低级剑
            clearLowestTypeSwords()
        }
    }
    
    private func executeUltimatePattern(_ pattern: UltimatePattern) {
        switch pattern.name {
        case "万剑归宗":
            // 万剑归宗 - 所有剑向中心聚集并升级
            executeWanJianGuiZong()
        case "乾坤大挪移":
            // 乾坤大挪移 - 重新排列所有剑
            executeQianKunDaNuoYi()
        case "九阴真经":
            // 九阴真经 - 时间倒流效果
            executeJiuYinZhenJing()
        default:
            executeWanJianGuiZong()
        }
    }
    
    private func executeWanJianGuiZong() {
        let allSwords = gameGrid.getAllSwords()
        let centerPosition = HexPosition(q: 0, r: 0)
        
        // 清空网格
        gameGrid.clear()
        
        // 在中心创建高级剑
        let upgradedSword = Sword(type: .shen, position: centerPosition)
        gameGrid.setSword(upgradedSword, at: centerPosition)
        
        // 播放特效
        effectsService.playWanJianGuiZongEffect()
        
        // 重新填充网格
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.spawnInitialSwords()
        }
    }
    
    private func executeQianKunDaNuoYi() {
        let allSwords = gameGrid.getAllSwords()
        let allPositions = gameGrid.getAllSwordPositions()
        
        // 随机重排
        let shuffledSwords = allSwords.shuffled()
        
        gameGrid.clear()
        
        for (index, position) in allPositions.enumerated() {
            if index < shuffledSwords.count {
                var sword = shuffledSwords[index]
                sword.hexPosition = position
                gameGrid.setSword(sword, at: position)
            }
        }
        
        effectsService.playQianKunDaNuoYiEffect()
    }
    
    private func executeJiuYinZhenJing() {
        // 恢复时间和步数
        if let timeLimit = levelConfig.rules.timeLimit {
            timeRemaining = min(timeRemaining + 30, timeLimit)
        }
        
        if let moveLimit = levelConfig.rules.moveLimit {
            moveCount = max(0, moveCount - 10)
        }
        
        effectsService.playJiuYinZhenJingEffect()
    }
    
    private func clearLowestTypeSwords() {
        let allPositions = gameGrid.getAllSwordPositions()
        let fanSwordPositions = allPositions.filter { pos in
            gameGrid.sword(at: pos)?.type == .fan
        }
        
        for position in fanSwordPositions {
            gameGrid.setSword(nil, at: position)
        }
        
        replenishSwords()
    }
    
    private func processAutoCombo() {
        let matchResult = matchEngine.findAllMatches()
        
        if matchResult.hasMatches {
            processMatches(matchResult.matches)
        } else {
            endComboPhase()
        }
    }
    
    private func shuffleGrid() {
        let allSwords = gameGrid.getAllSwords()
        let allPositions = gameGrid.getAllSwordPositions()
        
        gameGrid.clear()
        
        let shuffledSwords = allSwords.shuffled()
        
        for (index, position) in allPositions.enumerated() {
            if index < shuffledSwords.count {
                var sword = shuffledSwords[index]
                sword.hexPosition = position
                gameGrid.setSword(sword, at: position)
            }
        }
        
        effectsService.playShuffleEffect()
        audioService.playSound(.shuffle)
    }
    
    private func incrementMoveCount() {
        moveCount += 1
        
        if let moveLimit = levelConfig.rules.moveLimit, moveCount >= moveLimit {
            endGame(reason: .movesExhausted)
        }
    }
    
    private func endGame(reason: GameEndReason) {
        gameState = .gameOver(reason)
        gameTimer?.invalidate()
        comboTimer?.invalidate()
        audioService.stopBackgroundMusic()
        
        // 计算最终分数和星级
        let finalResult = calculateFinalResult()
        
        // 播放结束音效
        switch reason {
        case .victory:
            audioService.playSound(.levelComplete)
            effectsService.playVictoryEffect()
        case .timeUp, .movesExhausted:
            audioService.playSound(.gameOver)
        }
    }
    
    private func calculateFinalResult() -> GameResult {
        let targetScore = scoreCalculator.calculateTargetScore(for: levelConfig)
        let perfectScore = scoreCalculator.calculatePerfectScore(targetScore: targetScore)
        
        let stars = scoreCalculator.calculateStars(
            score: score,
            targetScore: targetScore,
            perfectScore: perfectScore
        )
        
        return GameResult(
            score: score,
            stars: stars,
            comboCount: comboCount,
            timeRemaining: timeRemaining,
            movesUsed: moveCount
        )
    }
}

// MARK: - Supporting Types

public enum GameState: Equatable {
    case idle
    case playing
    case paused
    case gameOver(GameEndReason)
}

public enum GameEndReason {
    case victory
    case timeUp
    case movesExhausted
}

public struct GameResult {
    let score: Int
    let stars: Int
    let comboCount: Int
    let timeRemaining: TimeInterval
    let movesUsed: Int
}