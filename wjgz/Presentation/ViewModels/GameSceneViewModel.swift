import Foundation
import Combine
import SpriteKit

/// 游戏场景视图模型 - 连接UI和业务逻辑
public final class GameSceneViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var gameState: GameState = .idle
    @Published public private(set) var score: Int = 0
    @Published public private(set) var energy: CGFloat = 0
    @Published public private(set) var moveCount: Int = 0
    @Published public private(set) var timeRemaining: TimeInterval = 0
    @Published public private(set) var comboCount: Int = 0
    @Published public private(set) var isInComboPhase: Bool = false
    @Published public private(set) var cultivation: Int = 0
    @Published public private(set) var currentLevel: Level
    @Published public private(set) var isUltimateAvailable: Bool = false
    @Published public private(set) var feedbackText: String = ""
    @Published public private(set) var showFeedback: Bool = false
    
    // MARK: - Dependencies
    
    private let gamePlayUseCase: GamePlayUseCase
    private let gameStateManager: GameStateManager
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private weak var gameScene: SKScene?
    
    // MARK: - Initialization
    
    public init(
        gamePlayUseCase: GamePlayUseCase,
        gameStateManager: GameStateManager,
        level: Level
    ) {
        self.gamePlayUseCase = gamePlayUseCase
        self.gameStateManager = gameStateManager
        self.currentLevel = level
        
        setupBindings()
        loadInitialState()
    }
    
    // MARK: - Public Methods
    
    /// 设置游戏场景引用
    public func setGameScene(_ scene: SKScene) {
        self.gameScene = scene
    }
    
    /// 开始游戏
    public func startGame() {
        gamePlayUseCase.startGame()
        showFeedbackText("开始游戏!", style: .good)
    }
    
    /// 暂停游戏
    public func pauseGame() {
        gamePlayUseCase.pauseGame()
    }
    
    /// 恢复游戏
    public func resumeGame() {
        gamePlayUseCase.resumeGame()
    }
    
    /// 重新开始游戏
    public func restartGame() {
        gamePlayUseCase.startGame()
        showFeedbackText("重新开始!", style: .good)
    }
    
    /// 处理剑的拖拽
    public func handleSwordDrag(from: HexPosition, to: HexPosition) {
        gamePlayUseCase.handleSwordDrop(from: from, to: to)
    }
    
    /// 触发终极技能
    public func triggerUltimate() {
        guard isUltimateAvailable else { return }
        
        gamePlayUseCase.triggerUltimateSkill()
        showFeedbackText("终极奥义!", style: .ultimate)
    }
    
    /// 触发自动连消
    public func triggerAutoCombo() {
        gamePlayUseCase.triggerAutoCombo()
        showFeedbackText("自动连消!", style: .excellent)
    }
    
    /// 显示反馈文字
    public func showFeedbackText(_ text: String, style: FeedbackStyle) {
        feedbackText = text
        showFeedback = true
        
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showFeedback = false
        }
    }
    
    // MARK: - Computed Properties
    
    /// 格式化的时间显示
    public var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 格式化的分数显示
    public var formattedScore: String {
        return NumberFormatter.localizedString(from: NSNumber(value: score), number: .decimal)
    }
    
    /// 能量百分比
    public var energyPercentage: Double {
        return Double(energy) / 100.0
    }
    
    /// 修为境界名称
    public var cultivationRealm: String {
        return CultivationRealm.getRealm(for: cultivation).name
    }
    
    /// 关卡进度文本
    public var levelProgressText: String {
        return "第\(currentLevel.id)关 - \(currentLevel.name)"
    }
    
    /// 关卡描述
    public var levelDescription: String {
        return currentLevel.subtitle
    }
    
    /// 是否显示时间限制
    public var hasTimeLimit: Bool {
        return currentLevel.rules.timeLimit != nil
    }
    
    /// 是否显示步数限制
    public var hasMoveLimit: Bool {
        return currentLevel.rules.moveLimit != nil
    }
    
    /// 剩余步数
    public var remainingMoves: Int? {
        guard let moveLimit = currentLevel.rules.moveLimit else { return nil }
        return max(0, moveLimit - moveCount)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 绑定游戏用例的状态变化
        gamePlayUseCase.$gameState
            .receive(on: DispatchQueue.main)
            .assign(to: \.gameState, on: self)
            .store(in: &cancellables)
        
        gamePlayUseCase.$score
            .receive(on: DispatchQueue.main)
            .assign(to: \.score, on: self)
            .store(in: &cancellables)
        
        gamePlayUseCase.$energy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] energy in
                self?.energy = energy
                self?.isUltimateAvailable = energy >= 100
            }
            .store(in: &cancellables)
        
        gamePlayUseCase.$moveCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.moveCount, on: self)
            .store(in: &cancellables)
        
        gamePlayUseCase.$timeRemaining
            .receive(on: DispatchQueue.main)
            .assign(to: \.timeRemaining, on: self)
            .store(in: &cancellables)
        
        gamePlayUseCase.$comboCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] comboCount in
                self?.comboCount = comboCount
                if comboCount > 0 {
                    self?.showFeedbackText("连击 x\(comboCount)", style: .combo(comboCount))
                }
            }
            .store(in: &cancellables)
        
        gamePlayUseCase.$isInComboPhase
            .receive(on: DispatchQueue.main)
            .assign(to: \.isInComboPhase, on: self)
            .store(in: &cancellables)
        
        // 监听游戏状态变化
        $gameState
            .sink { [weak self] state in
                self?.handleGameStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        cultivation = gameStateManager.cultivation
    }
    
    private func handleGameStateChange(_ state: GameState) {
        switch state {
        case .idle:
            break
            
        case .playing:
            break
            
        case .paused:
            showFeedbackText("游戏暂停", style: .good)
            
        case .gameOver(let reason):
            handleGameOver(reason: reason)
        }
    }
    
    private func handleGameOver(reason: GameEndReason) {
        switch reason {
        case .victory:
            handleLevelComplete()
            
        case .timeUp:
            showFeedbackText("时间到!", style: .good)
            
        case .movesExhausted:
            showFeedbackText("步数用完!", style: .good)
        }
    }
    
    private func handleLevelComplete() {
        // 计算星级和修为增长
        let stars = calculateStars()
        _ = calculateCultivationGrowth(stars: stars)
        
        // 更新游戏状态
        gameStateManager.completeLevel(
            currentLevel.id,
            stars: stars,
            score: score
        )
        
        // 更新本地状态
        cultivation = gameStateManager.cultivation
        
        // 显示完成信息
        let starText = String(repeating: "⭐", count: stars)
        showFeedbackText("关卡完成! \(starText)", style: .perfect)
    }
    
    private func calculateStars() -> Int {
        let scoreCalculator = DIContainer.shared.resolve(ScoreCalculator.self)
        let targetScore = scoreCalculator.calculateTargetScore(for: currentLevel)
        let perfectScore = scoreCalculator.calculatePerfectScore(targetScore: targetScore)
        
        return scoreCalculator.calculateStars(
            score: score,
            targetScore: targetScore,
            perfectScore: perfectScore
        )
    }
    
    private func calculateCultivationGrowth(stars: Int) -> Int {
        let scoreCalculator = DIContainer.shared.resolve(ScoreCalculator.self)
        
        return scoreCalculator.calculateCultivationGrowth(
            levelID: currentLevel.id,
            stars: stars,
            score: score
        )
    }
}

// MARK: - Supporting Types

/// 修为境界
public enum CultivationRealm: String, CaseIterable {
    case lianQi = "练气期"
    case zhuJi = "筑基期"
    case jinDan = "金丹期"
    case yuanYing = "元婴期"
    case huaShen = "化神期"
    case lianXu = "炼虚期"
    case heTi = "合体期"
    case daCheng = "大乘期"
    case duJie = "渡劫期"
    case feiSheng = "飞升仙人"
    
    public var name: String {
        return rawValue
    }
    
    public var range: ClosedRange<Int> {
        switch self {
        case .lianQi: return 0...99
        case .zhuJi: return 100...299
        case .jinDan: return 300...599
        case .yuanYing: return 600...999
        case .huaShen: return 1000...1499
        case .lianXu: return 1500...2099
        case .heTi: return 2100...2799
        case .daCheng: return 2800...3599
        case .duJie: return 3600...4499
        case .feiSheng: return 4500...Int.max
        }
    }
    
    public static func getRealm(for cultivation: Int) -> CultivationRealm {
        for realm in CultivationRealm.allCases {
            if realm.range.contains(cultivation) {
                return realm
            }
        }
        return .feiSheng
    }
}