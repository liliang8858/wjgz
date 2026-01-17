import Foundation

/// 分数计算器 - 负责游戏中所有分数相关的计算
public final class ScoreCalculator {
    
    // MARK: - Properties
    
    private let baseScorePerSword: Int
    private let comboMultiplierBase: Double
    private let perfectMatchBonus: Double
    
    // MARK: - Initialization
    
    public init(
        baseScorePerSword: Int = GameConstants.baseScorePerSword,
        comboMultiplierBase: Double = GameConstants.comboMultiplierBase,
        perfectMatchBonus: Double = GameConstants.perfectMatchBonus
    ) {
        self.baseScorePerSword = baseScorePerSword
        self.comboMultiplierBase = comboMultiplierBase
        self.perfectMatchBonus = perfectMatchBonus
    }
    
    // MARK: - Match Score Calculation
    
    /// 计算匹配分数
    public func calculateMatchScore(
        swordType: SwordType,
        count: Int,
        comboMultiplier: Int = 1,
        isPerfectMatch: Bool = false
    ) -> Int {
        // 基础分数 = 剑类型分数 × 数量
        let baseScore = swordType.baseScore * count
        
        // 连击倍数
        let comboBonus = pow(comboMultiplierBase, Double(comboMultiplier - 1))
        
        // 完美匹配奖励
        let perfectBonus = isPerfectMatch ? perfectMatchBonus : 1.0
        
        // 数量奖励（超过最小匹配数的额外奖励）
        let countBonus = count > 3 ? Double(count - 3) * 0.5 + 1.0 : 1.0
        
        let finalScore = Double(baseScore) * comboBonus * perfectBonus * countBonus
        
        return Int(finalScore.rounded())
    }
    
    /// 计算连击奖励分数
    public func calculateComboBonus(comboCount: Int, baseScore: Int) -> Int {
        guard comboCount > 1 else { return 0 }
        
        let comboMultiplier = pow(comboMultiplierBase, Double(comboCount - 1))
        let bonusScore = Double(baseScore) * (comboMultiplier - 1.0)
        
        return Int(bonusScore.rounded())
    }
    
    /// 计算特殊效果分数
    public func calculateSpecialEffectScore(effectType: SpecialEffectType, affectedCount: Int) -> Int {
        let baseScore = effectType.baseScore * affectedCount
        let multiplier = effectType.scoreMultiplier
        
        return Int(Double(baseScore) * multiplier)
    }
    
    // MARK: - Level Completion Calculation
    
    /// 计算关卡星级
    public func calculateStars(score: Int, targetScore: Int, perfectScore: Int) -> Int {
        let percentage = Double(score) / Double(targetScore)
        
        if score >= perfectScore {
            return 3
        } else if percentage >= GameConstants.twoStarThreshold {
            return 2
        } else if percentage >= GameConstants.oneStarThreshold {
            return 1
        } else {
            return 0
        }
    }
    
    /// 计算修为增长
    public func calculateCultivationGrowth(
        levelID: Int,
        stars: Int,
        score: Int,
        bonusMultiplier: Double = 1.0
    ) -> Int {
        // 基础修为 = 关卡ID × 10
        let baseCultivation = levelID * GameConstants.baseCultivationPerLevel
        
        // 星级奖励 = 星数 × 5
        let starBonus = stars * GameConstants.starBonusPerStar
        
        // 分数奖励 = 分数 ÷ 100
        let scoreBonus = score / GameConstants.scoreBonusDivisor
        
        let totalCultivation = Double(baseCultivation + starBonus + scoreBonus) * bonusMultiplier
        
        return Int(totalCultivation.rounded())
    }
    
    /// 计算关卡目标分数
    public func calculateTargetScore(for level: Level) -> Int {
        // 基础目标分数根据关卡ID计算
        let baseDifficulty = (level.id - 1) / 6 + 1 // 每6关增加一个难度等级
        let levelMultiplier = Double(level.id) * 0.1 + 1.0
        let difficultyMultiplier = Double(baseDifficulty) * 0.5 + 1.0
        
        let baseTarget = 1000
        let targetScore = Double(baseTarget) * levelMultiplier * difficultyMultiplier
        
        return Int(targetScore.rounded())
    }
    
    /// 计算完美分数
    public func calculatePerfectScore(targetScore: Int) -> Int {
        return Int(Double(targetScore) * 1.5) // 完美分数是目标分数的1.5倍
    }
    
    // MARK: - Time and Move Bonuses
    
    /// 计算时间奖励
    public func calculateTimeBonus(remainingTime: TimeInterval, totalTime: TimeInterval) -> Int {
        guard totalTime > 0 else { return 0 }
        
        let timePercentage = remainingTime / totalTime
        let maxTimeBonus = 500
        
        return Int(Double(maxTimeBonus) * timePercentage)
    }
    
    /// 计算步数奖励
    public func calculateMoveBonus(usedMoves: Int, totalMoves: Int) -> Int {
        guard totalMoves > 0 else { return 0 }
        
        let remainingMoves = max(0, totalMoves - usedMoves)
        let movePercentage = Double(remainingMoves) / Double(totalMoves)
        let maxMoveBonus = 300
        
        return Int(Double(maxMoveBonus) * movePercentage)
    }
    
    // MARK: - Achievement Calculation
    
    /// 计算成就进度
    public func calculateAchievementProgress(
        achievementType: AchievementType,
        currentValue: Int,
        targetValue: Int
    ) -> Double {
        guard targetValue > 0 else { return 1.0 }
        
        let progress = Double(currentValue) / Double(targetValue)
        return min(1.0, max(0.0, progress))
    }
    
    /// 计算成就奖励
    public func calculateAchievementReward(achievementType: AchievementType) -> Int {
        return achievementType.rewardCultivation
    }
}

// MARK: - Supporting Types

/// 特殊效果类型
public enum SpecialEffectType {
    case rowClear
    case areaClear
    case divineSword
    case ultimate
    
    public var baseScore: Int {
        switch self {
        case .rowClear: return 50
        case .areaClear: return 100
        case .divineSword: return 200
        case .ultimate: return 500
        }
    }
    
    public var scoreMultiplier: Double {
        switch self {
        case .rowClear: return 1.5
        case .areaClear: return 2.0
        case .divineSword: return 3.0
        case .ultimate: return 5.0
        }
    }
}

/// 成就类型
public enum AchievementType: String, CaseIterable {
    case firstMerge = "first_merge"
    case spiritSword = "spirit_sword"
    case immortalSword = "immortal_sword"
    case divineSword = "divine_sword"
    case ultimate1 = "ultimate_1"
    case combo5 = "combo_5"
    case combo10 = "combo_10"
    case chainClear = "chain_clear"
    case perfectLevel = "perfect_level"
    
    public var title: String {
        switch self {
        case .firstMerge: return "初入剑道"
        case .spiritSword: return "灵剑初成"
        case .immortalSword: return "仙剑问世"
        case .divineSword: return "神剑出鞘"
        case .ultimate1: return "剑意初现"
        case .combo5: return "连击新秀"
        case .combo10: return "连击大师"
        case .chainClear: return "剑气纵横"
        case .perfectLevel: return "完美无瑕"
        }
    }
    
    public var description: String {
        switch self {
        case .firstMerge: return "完成第一次剑的合成"
        case .spiritSword: return "合成灵剑"
        case .immortalSword: return "合成仙剑"
        case .divineSword: return "合成神剑"
        case .ultimate1: return "使用终极技能"
        case .combo5: return "达成5连击"
        case .combo10: return "达成10连击"
        case .chainClear: return "触发连锁清除"
        case .perfectLevel: return "完美通关一个关卡"
        }
    }
    
    public var targetValue: Int {
        switch self {
        case .firstMerge: return 1
        case .spiritSword: return 1
        case .immortalSword: return 1
        case .divineSword: return 1
        case .ultimate1: return 1
        case .combo5: return 5
        case .combo10: return 10
        case .chainClear: return 1
        case .perfectLevel: return 1
        }
    }
    
    public var rewardCultivation: Int {
        switch self {
        case .firstMerge: return 10
        case .spiritSword: return 20
        case .immortalSword: return 50
        case .divineSword: return 100
        case .ultimate1: return 30
        case .combo5: return 40
        case .combo10: return 80
        case .chainClear: return 60
        case .perfectLevel: return 100
        }
    }
}