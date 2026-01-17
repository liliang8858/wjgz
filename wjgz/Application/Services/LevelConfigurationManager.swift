import Foundation

/// 关卡配置管理器 - 管理所有关卡的配置和进度
public final class LevelConfigurationManager {
    
    // MARK: - Properties
    
    private let storageService: StorageServiceProtocol
    private var levelConfigs: [Int: Level] = [:]
    
    // MARK: - Initialization
    
    public init(storageService: StorageServiceProtocol = DIContainer.shared.resolve(StorageServiceProtocol.self)) {
        self.storageService = storageService
        loadLevelConfigurations()
    }
    
    // MARK: - Public Methods
    
    /// 获取指定关卡配置
    public func getLevel(_ levelID: Int) -> Level? {
        return levelConfigs[levelID]
    }
    
    /// 获取所有关卡
    public func getAllLevels() -> [Level] {
        return Array(levelConfigs.values).sorted { $0.id < $1.id }
    }
    
    /// 获取指定章节的关卡
    public func getLevelsForChapter(_ chapter: Int) -> [Level] {
        let startLevel = (chapter - 1) * 3 + 1
        let endLevel = chapter * 3
        
        return getAllLevels().filter { level in
            level.id >= startLevel && level.id <= endLevel
        }
    }
    
    /// 检查关卡是否已解锁
    public func isLevelUnlocked(_ levelID: Int) -> Bool {
        let gameStateManager = DIContainer.shared.resolve(GameStateManager.self)
        return gameStateManager.unlockedLevels.contains(levelID)
    }
    
    /// 获取关卡进度
    public func getLevelProgress(_ levelID: Int) -> LevelProgressData? {
        return storageService.load(LevelProgressData.self, forKey: "\(StorageKeys.levelScores)_\(levelID)")
    }
    
    /// 保存关卡进度
    public func saveLevelProgress(_ progress: LevelProgressData) {
        storageService.save(progress, forKey: "\(StorageKeys.levelScores)_\(progress.levelID)")
    }
    
    // MARK: - Private Methods
    
    private func loadLevelConfigurations() {
        // 加载所有24个关卡的配置
        for levelID in 1...24 {
            let level = createLevelConfiguration(levelID: levelID)
            levelConfigs[levelID] = level
        }
    }
    
    private func createLevelConfiguration(levelID: Int) -> Level {
        let chapter = (levelID - 1) / 3 + 1
        let levelInChapter = (levelID - 1) % 3 + 1
        
        return Level(
            id: levelID,
            name: getLevelName(chapter: chapter, level: levelInChapter),
            subtitle: getLevelDescription(chapter: chapter, level: levelInChapter),
            targetScore: calculateTargetScore(levelID: levelID, chapter: chapter),
            targetMerges: calculateTargetMerges(levelID: levelID, chapter: chapter),
            starThresholds: calculateStarThresholds(levelID: levelID, chapter: chapter),
            formationType: getLevelFormation(chapter: chapter, level: levelInChapter),
            rules: getLevelRules(chapter: chapter, level: levelInChapter),
            gridRadius: getGridRadius(chapter: chapter),
            initialSwordTypes: getInitialSwordTypes(chapter: chapter, level: levelInChapter),
            spawnWeights: getSpawnWeights(chapter: chapter, level: levelInChapter)
        )
    }
    
    private func getLevelName(chapter: Int, level: Int) -> String {
        let chapterNames = [
            1: ["初入剑道", "剑气初现", "剑心通明"],
            2: ["基础剑法", "剑意凝聚", "剑势如虹"],
            3: ["进阶剑术", "剑气纵横", "剑意如海"],
            4: ["八卦入门", "乾坤初定", "阴阳调和"],
            5: ["八卦进阶", "五行相生", "天地人和"],
            6: ["高级挑战", "剑道大成", "剑心如镜"],
            7: ["终极试炼", "剑意通天", "剑道无极"],
            8: ["万剑归宗", "剑神降世", "剑道至尊"]
        ]
        
        return chapterNames[chapter]?[level - 1] ?? "未知关卡"
    }
    
    private func getLevelDescription(chapter: Int, level: Int) -> String {
        let descriptions = [
            1: ["学习基本的剑道合成", "掌握剑气的运用", "领悟剑心的奥秘"],
            2: ["练习基础剑法技巧", "凝聚内在剑意", "展现剑势威力"],
            3: ["掌握进阶剑术", "运用剑气攻击", "感悟剑意境界"],
            4: ["学习八卦阵法", "理解乾坤变化", "平衡阴阳之力"],
            5: ["深入八卦奥义", "掌握五行循环", "达成天地人和"],
            6: ["面对高难挑战", "剑道修为大成", "心境如明镜"],
            7: ["接受终极考验", "剑意直达天际", "剑道境界无极"],
            8: ["万剑归于一宗", "剑神威临人间", "登临剑道至尊"]
        ]
        
        return descriptions[chapter]?[level - 1] ?? "挑战这个神秘关卡"
    }
    
    private func getLevelDifficulty(chapter: Int) -> Difficulty {
        switch chapter {
        case 1...2: return .easy
        case 3...4: return .normal
        case 5...6: return .hard
        case 7...8: return .expert
        default: return .normal
        }
    }
    
    private func calculateTargetScore(levelID: Int, chapter: Int) -> Int {
        let baseScore = 1000
        let chapterMultiplier = Double(chapter) * 0.5 + 1.0
        let levelMultiplier = Double(levelID) * 0.1 + 1.0
        
        return Int(Double(baseScore) * chapterMultiplier * levelMultiplier)
    }
    
    private func calculatePerfectScore(levelID: Int, chapter: Int) -> Int {
        let targetScore = calculateTargetScore(levelID: levelID, chapter: chapter)
        return Int(Double(targetScore) * 1.5)
    }
    
    private func calculateTargetMerges(levelID: Int, chapter: Int) -> Int {
        return 3 + levelID
    }
    
    private func calculateStarThresholds(levelID: Int, chapter: Int) -> [Int] {
        let targetScore = calculateTargetScore(levelID: levelID, chapter: chapter)
        return [
            targetScore,
            Int(Double(targetScore) * 1.5),
            targetScore * 2
        ]
    }
    
    private func getGridRadius(chapter: Int) -> Int {
        return min(2 + chapter / 3, 3)
    }
    
    private func getInitialSwordTypes(chapter: Int, level: Int) -> [SwordType] {
        switch chapter {
        case 1: return [.fan, .fan, .fan]
        case 2: return [.fan, .fan, .ling]
        case 3: return [.fan, .ling, .ling]
        case 4: return [.fan, .ling, .xian]
        default: return [.ling, .xian, .shen]
        }
    }
    
    private func getSpawnWeights(chapter: Int, level: Int) -> [SwordType: Double] {
        switch chapter {
        case 1: return [.fan: 1.0]
        case 2: return [.fan: 0.8, .ling: 0.2]
        case 3: return [.fan: 0.6, .ling: 0.4]
        case 4: return [.fan: 0.5, .ling: 0.4, .xian: 0.1]
        default: return [.fan: 0.3, .ling: 0.4, .xian: 0.25, .shen: 0.05]
        }
    }
    
    private func getLevelFormation(chapter: Int, level: Int) -> FormationType {
        switch chapter {
        case 1:
            return [.hexagon, .diamond, .cross][level - 1]
        case 2:
            return [.ring, .triangle, .star][level - 1]
        case 3:
            return [.spiral, .random, .hexagon][level - 1]
        case 4:
            return [.qian, .kun, .zhen][level - 1]
        case 5:
            return [.xun, .kan, .li][level - 1]
        case 6:
            return [.gen, .dui, .bagua][level - 1]
        case 7:
            return [.wuxing, .jiugong, .tiangang][level - 1]
        case 8:
            return [.bagua, .tiangang, .wuxing][level - 1]
        default:
            return .hexagon
        }
    }
    
    private func getLevelRules(chapter: Int, level: Int) -> LevelRules {
        var rules = LevelRules()
        
        // 基础规则
        rules.allowDiagonalMerge = true
        rules.minMergeCount = 3
        
        // 根据章节设置特殊规则
        switch chapter {
        case 1...2:
            // 新手关卡，无特殊限制
            break
            
        case 3:
            // 开始有时间限制
            rules.timeLimit = TimeInterval(300 - level * 30) // 270, 240, 210秒
            
        case 4:
            // 八卦关卡，有封锁格子
            rules.hasBlockedCells = true
            rules.blockedCellCount = level * 2
            
        case 5:
            // 五行关卡，有步数限制
            rules.moveLimit = 50 - level * 5 // 45, 40, 35步
            
        case 6:
            // 高级关卡，时间和步数双重限制
            rules.timeLimit = TimeInterval(180 - level * 20)
            rules.moveLimit = 40 - level * 5
            
        case 7:
            // 终极关卡，增加重力和洗牌
            rules.timeLimit = TimeInterval(150 - level * 10)
            rules.moveLimit = 35 - level * 5
            rules.gravityDirection = GravityDirection.down
            rules.shuffleInterval = TimeInterval(60)
            
        case 8:
            // 万剑归宗，最高难度
            rules.timeLimit = TimeInterval(120)
            rules.moveLimit = 25
            rules.gravityDirection = GravityDirection.down
            rules.shuffleInterval = TimeInterval(45)
            rules.ultimatePattern = getUltimatePattern(level: level)
            
        default:
            break
        }
        
        return rules
    }
    
    private func getUltimatePattern(level: Int) -> UltimatePattern {
        switch level {
        case 1: 
            return UltimatePattern(
                name: "万剑归宗",
                description: "万剑齐发，归于一宗",
                triggerCondition: .specificPattern,
                positions: [Position(q: 0, r: 0)],
                swordTypes: [.shen],
                effectDescription: "清除全屏剑"
            )
        case 2: 
            return UltimatePattern(
                name: "乾坤大挪移",
                description: "乾坤颠倒，大挪移术",
                triggerCondition: .swordTypeCount,
                positions: [Position(q: 0, r: 0)],
                swordTypes: [.xian],
                effectDescription: "重新排列所有剑"
            )
        case 3: 
            return UltimatePattern(
                name: "九阴真经",
                description: "九阴真经，至阴至柔",
                triggerCondition: .comboCount,
                positions: [Position(q: 0, r: 0)],
                swordTypes: [.ling],
                effectDescription: "连击倍数翻倍"
            )
        default: 
            return UltimatePattern(
                name: "万剑归宗",
                description: "万剑齐发，归于一宗",
                triggerCondition: .specificPattern,
                positions: [Position(q: 0, r: 0)],
                swordTypes: [.shen],
                effectDescription: "清除全屏剑"
            )
        }
    }
}

// MARK: - Supporting Types

/// 关卡难度
public enum Difficulty: Int, CaseIterable {
    case easy = 1
    case normal = 2
    case hard = 3
    case expert = 4
    
    public var name: String {
        switch self {
        case .easy: return "简单"
        case .normal: return "普通"
        case .hard: return "困难"
        case .expert: return "专家"
        }
    }
    
    public var color: String {
        switch self {
        case .easy: return "green"
        case .normal: return "blue"
        case .hard: return "orange"
        case .expert: return "red"
        }
    }
}