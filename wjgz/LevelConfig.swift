import Foundation
import UIKit

// MARK: - Formation Types (剑阵形态)
public enum FormationType: String, CaseIterable, Codable {
    // 基础阵型
    case hexagon = "六合阵"      // 标准六边形
    case diamond = "菱形阵"      // 菱形
    case cross = "十字阵"        // 十字形
    case ring = "环形阵"         // 环形（中空）
    case triangle = "三才阵"     // 三角形
    case star = "七星阵"         // 星形
    case spiral = "太极阵"       // 螺旋形
    case random = "乱剑阵"       // 随机形态
    
    // 八卦阵型
    case qian = "乾卦阵"         // 天 - 刚健
    case kun = "坤卦阵"          // 地 - 柔顺
    case zhen = "震卦阵"         // 雷 - 动
    case xun = "巽卦阵"          // 风 - 入
    case kan = "坎卦阵"          // 水 - 险
    case li = "离卦阵"           // 火 - 丽
    case gen = "艮卦阵"          // 山 - 止
    case dui = "兑卦阵"          // 泽 - 悦
    
    // 高级阵型
    case bagua = "八卦阵"        // 完整八卦
    case wuxing = "五行阵"       // 金木水火土
    case jiugong = "九宫阵"      // 九宫格
    case tiangang = "天罡阵"     // 三十六天罡
    
    var description: String {
        switch self {
        case .hexagon: return "经典六边形剑阵"
        case .diamond: return "菱形剑阵，中心聚气"
        case .cross: return "十字剑阵，四方镇守"
        case .ring: return "环形剑阵，中空蓄力"
        case .triangle: return "三才剑阵，天地人合"
        case .star: return "七星剑阵，北斗引路"
        case .spiral: return "太极剑阵，阴阳流转"
        case .random: return "乱剑阵，变幻莫测"
        case .qian: return "乾为天，刚健中正"
        case .kun: return "坤为地，厚德载物"
        case .zhen: return "震为雷，动而生阳"
        case .xun: return "巽为风，无孔不入"
        case .kan: return "坎为水，险中求胜"
        case .li: return "离为火，光明磊落"
        case .gen: return "艮为山，静止不动"
        case .dui: return "兑为泽，和悦相济"
        case .bagua: return "八卦归一，万法归宗"
        case .wuxing: return "五行相生，循环不息"
        case .jiugong: return "九宫飞星，变化无穷"
        case .tiangang: return "天罡北斗，镇压四方"
        }
    }
}

// MARK: - Special Rules (特殊规则)
struct LevelRules: Codable {
    var allowDiagonalMerge: Bool = true      // 允许斜向合成
    var minMergeCount: Int = 3               // 最少合成数量
    var hasBlockedCells: Bool = false        // 是否有封锁格子
    var blockedCellCount: Int = 0            // 封锁格子数量
    var hasBossSword: Bool = false           // 是否有Boss剑
    var timeLimit: TimeInterval? = nil       // 时间限制
    var moveLimit: Int? = nil                // 步数限制
    var mustUseSwordType: SwordType? = nil   // 必须使用的剑型
    var forbiddenSwordType: SwordType? = nil // 禁止使用的剑型
    var gravityDirection: GravityDirection = .none // 重力方向
    var shuffleInterval: TimeInterval? = nil // 自动洗牌间隔
    var ultimatePattern: UltimatePattern? = nil // 终极奥义阵法
}

enum GravityDirection: String, Codable {
    case none = "无"
    case down = "下"
    case up = "上"
    case center = "中心"
    case outward = "外散"
}

// MARK: - Ultimate Pattern (终极奥义阵法)
struct Position: Codable {
    let q: Int
    let r: Int
}

struct UltimatePattern: Codable {
    let name: String              // 奥义名称
    let description: String       // 奥义描述
    let triggerCondition: TriggerCondition // 触发条件
    let positions: [Position]     // 需要放置剑的位置
    let swordTypes: [SwordType]   // 对应位置需要的剑类型
    let effectDescription: String // 效果描述
    
    enum TriggerCondition: String, Codable {
        case specificPattern = "特定阵法"    // 需要在特定位置放置特定剑
        case swordTypeCount = "剑种数量"     // 需要特定数量的某种剑
        case comboCount = "连击数量"         // 需要达到特定连击数
        case timeWindow = "时间窗口"         // 在特定时间内完成
    }
}

// MARK: - Level Definition
public struct Level: Codable {
    let id: Int
    let name: String
    let subtitle: String
    let targetScore: Int
    let targetMerges: Int
    let starThresholds: [Int]
    let formationType: FormationType
    let rules: LevelRules
    let gridRadius: Int
    let initialSwordTypes: [SwordType]
    let spawnWeights: [SwordType: Double]
    
    // 计算星级
    func calculateStars(score: Int) -> Int {
        if score >= starThresholds[2] { return 3 }
        if score >= starThresholds[1] { return 2 }
        if score >= starThresholds[0] { return 1 }
        return 0
    }
    
    // 检查是否保证可过关
    var guaranteedWinnable: Bool {
        return rules.timeLimit == nil && rules.moveLimit == nil
    }
}

// MARK: - Supporting Data Structures
struct SwordData: Codable {
    let id: String
    let name: String
    let type: String
    let description: String
    var unlocked: Bool
}

struct Achievement: Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    var unlocked: Bool
}

// MARK: - Game State Manager
public class GameStateManager {
    static let shared = GameStateManager()
    private let storageKey = "sword_game_state"
    
    // Progression
    private(set) var currentLevel: Int = 1
    private(set) var cultivation: Int = 0  // 修为值
    private(set) var unlockedLevels: Set<Int> = [1]
    
    // Achievements & Stats
    var ultimateCount: Int = 0
    var maxCombo: Int = 0
    var tutorialCompleted: Bool = false
    
    var swordCollection: [SwordData] = [
        SwordData(id: "mortal_1", name: "铁剑", type: "fan", description: "最基础的凡铁之剑", unlocked: true),
        SwordData(id: "mortal_2", name: "青铜剑", type: "fan", description: "铸于青铜的普通之剑", unlocked: false),
        SwordData(id: "mortal_3", name: "玄铁剑", type: "fan", description: "以玄铁打造的利器", unlocked: false),
        SwordData(id: "spirit_1", name: "青锋剑", type: "ling", description: "蕴含灵气的青色利剑", unlocked: false),
        SwordData(id: "spirit_2", name: "碧落剑", type: "ling", description: "传承千年的灵剑", unlocked: false),
        SwordData(id: "immortal_1", name: "紫霄剑", type: "xian", description: "仙气缭绕的紫色神兵", unlocked: false),
        SwordData(id: "immortal_2", name: "太虚剑", type: "xian", description: "蕴含太虚之力的仙剑", unlocked: false),
        SwordData(id: "divine_1", name: "天罡剑", type: "shen", description: "天罡正气凝聚的神剑", unlocked: false),
        SwordData(id: "divine_2", name: "万剑之宗", type: "shen", description: "万剑归一，至高无上", unlocked: false),
    ]
    
    var achievements: [Achievement] = [
        Achievement(id: "first_merge", name: "初入剑道", description: "完成首次三剑合一", icon: "⚔️", unlocked: false),
        Achievement(id: "spirit_sword", name: "灵剑初成", description: "首次合成灵剑", icon: "🗡️", unlocked: false),
        Achievement(id: "immortal_sword", name: "仙剑问世", description: "首次合成仙剑", icon: "✨", unlocked: false),
        Achievement(id: "divine_sword", name: "神剑出鞘", description: "首次合成神剑", icon: "🌟", unlocked: false),
        Achievement(id: "ultimate_1", name: "剑意初现", description: "首次释放万剑归宗", icon: "💫", unlocked: false),
        Achievement(id: "combo_5", name: "连击新秀", description: "达成5连击", icon: "⚡", unlocked: false),
        Achievement(id: "combo_10", name: "连击大师", description: "达成10连击", icon: "💥", unlocked: false),
        Achievement(id: "chain_clear", name: "剑气纵横", description: "触发剑气连锁消除", icon: "🌊", unlocked: false),
    ]
    
    public init() {
        loadGameState()
        
        // 🔧 确保关卡进度系统正常工作的额外保障
        ensureLevelProgressionWorks()
    }
    
    // MARK: - Level Management
    
    func completeLevel(_ levelId: Int, stars: Int, score: Int) {
        print("🎯 completeLevel: levelId=\(levelId), stars=\(stars), score=\(score)")
        print("🎯 当前状态: currentLevel=\(currentLevel), unlockedLevels=\(unlockedLevels)")
        
        // 增加修为
        let cultivationGain = calculateCultivationGain(levelId: levelId, stars: stars, score: score)
        cultivation += cultivationGain
        
        // 解锁下一关
        let nextLevel = levelId + 1
        if nextLevel <= LevelConfig.shared.levels.count {
            unlockedLevels.insert(nextLevel)
            print("🔓 解锁关卡: \(nextLevel)")
        }
        
        // 更新当前关卡
        if levelId >= currentLevel {
            currentLevel = nextLevel
            print("⬆️ 更新当前关卡: \(currentLevel)")
        }
        
        print("🎯 完成后状态: currentLevel=\(currentLevel), unlockedLevels=\(unlockedLevels)")
        saveGameState()
        print("🎉 关卡 \(levelId) 完成！获得修为: \(cultivationGain)，总修为: \(cultivation)")
    }
    
    func failLevel(_ levelId: Int) {
        // 修为保留，不减少
        // 关数打回机制暂时移除，改为无限重试当前关卡，降低挫败感
        print("💔 挑战失败！修为保留(\(cultivation))")
        saveGameState()
    }
    
    private func calculateCultivationGain(levelId: Int, stars: Int, score: Int) -> Int {
        let baseGain = levelId * 10  // 基础修为
        let starBonus = stars * 5    // 星级奖励
        let scoreBonus = score / 100 // 分数奖励
        return baseGain + starBonus + scoreBonus
    }
    
    func getCultivationTitle() -> String {
        switch cultivation {
        case 0..<100: return "练气期"
        case 100..<300: return "筑基期"
        case 300..<600: return "金丹期"
        case 600..<1000: return "元婴期"
        case 1000..<1500: return "化神期"
        case 1500..<2100: return "炼虚期"
        case 2100..<2800: return "合体期"
        case 2800..<3600: return "大乘期"
        case 3600..<4500: return "渡劫期"
        default: return "飞升仙人"
        }
    }
    
    // MARK: - Collection & Achievements
    
    func unlockSword(type: SwordType) {
        let typeStr: String
        switch type {
        case .fan: typeStr = "fan"
        case .ling: typeStr = "ling"
        case .xian: typeStr = "xian"
        case .shen: typeStr = "shen"
        }
        
        if let index = swordCollection.firstIndex(where: { $0.type == typeStr && !$0.unlocked }) {
            swordCollection[index].unlocked = true
            saveGameState()
        }
    }
    
    func unlockAchievement(_ id: String) {
        if let index = achievements.firstIndex(where: { $0.id == id && !$0.unlocked }) {
            achievements[index].unlocked = true
            saveGameState()
        }
    }
    
    func recordMerge(type: SwordType, combo: Int) {
        unlockSword(type: type)
        unlockAchievement("first_merge")
        
        switch type {
        case .ling: unlockAchievement("spirit_sword")
        case .xian: unlockAchievement("immortal_sword")
        case .shen: unlockAchievement("divine_sword")
        default: break
        }
        
        if combo >= 5 { unlockAchievement("combo_5") }
        if combo >= 10 { unlockAchievement("combo_10") }
        
        maxCombo = max(maxCombo, combo)
        saveGameState()
    }
    
    func recordCultivation(_ points: Int) {
        cultivation += points
        saveGameState()
    }
    
    func recordUltimate() {
        ultimateCount += 1
        unlockAchievement("ultimate_1")
        saveGameState()
    }
    
    func recordChainClear() {
        unlockAchievement("chain_clear")
        saveGameState()
    }
    
    // MARK: - Save/Load
    
    private func saveGameState() {
        let state: [String: Any] = [
            "currentLevel": currentLevel,
            "cultivation": cultivation,
            "tutorialCompleted": tutorialCompleted,
            "unlockedLevels": Array(unlockedLevels),
            "ultimateCount": ultimateCount,
            "maxCombo": maxCombo
        ]
        
        UserDefaults.standard.set(state, forKey: storageKey)
        
        if let swordData = try? JSONEncoder().encode(swordCollection) {
            UserDefaults.standard.set(swordData, forKey: "\(storageKey)_swords")
        }
        if let achievementData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(achievementData, forKey: "\(storageKey)_achievements")
        }
    }
    
    private func loadGameState() {
        print("🔍 loadGameState: 开始加载游戏状态")
        if let state = UserDefaults.standard.dictionary(forKey: storageKey) {
            currentLevel = state["currentLevel"] as? Int ?? 1
            cultivation = state["cultivation"] as? Int ?? 0
            tutorialCompleted = state["tutorialCompleted"] as? Bool ?? false
            if let unlockedArray = state["unlockedLevels"] as? [Int] {
                unlockedLevels = Set(unlockedArray)
            }
            ultimateCount = state["ultimateCount"] as? Int ?? 0
            maxCombo = state["maxCombo"] as? Int ?? 0
            print("🔍 加载的状态: currentLevel=\(currentLevel), cultivation=\(cultivation), unlockedLevels=\(unlockedLevels)")
        } else {
            print("🔍 没有找到保存的状态，使用默认值")
        }
        
        // Ensure current level is unlocked
        unlockedLevels.insert(currentLevel)
        print("🔍 确保当前关卡解锁: unlockedLevels=\(unlockedLevels)")
        
        if let swordData = UserDefaults.standard.data(forKey: "\(storageKey)_swords"),
           let swords = try? JSONDecoder().decode([SwordData].self, from: swordData) {
            swordCollection = swords
        }
        if let achievementData = UserDefaults.standard.data(forKey: "\(storageKey)_achievements"),
           let achs = try? JSONDecoder().decode([Achievement].self, from: achievementData) {
            achievements = achs
        }
    }
    
    func resetProgress() {
        print("🔄 resetProgress: 重置游戏进度")
        currentLevel = 1
        cultivation = 0
        tutorialCompleted = false
        unlockedLevels = [1]
        ultimateCount = 0
        maxCombo = 0
        // 重置成就和剑图鉴需要遍历重置，此处略
        saveGameState()
        print("🔄 重置完成: currentLevel=\(currentLevel), unlockedLevels=\(unlockedLevels)")
    }
    
    // 临时调试方法
    func debugCurrentState() {
        print("🐛 DEBUG - 当前游戏状态:")
        print("🐛 currentLevel: \(currentLevel)")
        print("🐛 cultivation: \(cultivation)")
        print("🐛 unlockedLevels: \(unlockedLevels)")
        print("🐛 tutorialCompleted: \(tutorialCompleted)")
    }
    
    // 强制解锁关卡（用于调试）
    func forceUnlockLevel(_ levelId: Int) {
        unlockedLevels.insert(levelId)
        saveGameState()
        print("🔧 强制解锁关卡: \(levelId)")
    }
    
    // 🔧 确保关卡进度系统正常工作
    private func ensureLevelProgressionWorks() {
        // 确保至少前3关都是解锁的，避免进度卡死
        for level in 1...min(3, LevelConfig.shared.levels.count) {
            unlockedLevels.insert(level)
        }
        
        // 如果当前关卡大于解锁关卡，重置到第一关
        if currentLevel > unlockedLevels.max() ?? 1 {
            currentLevel = 1
        }
        
        saveGameState()
        print("🔧 关卡进度系统保障完成: currentLevel=\(currentLevel), unlockedLevels=\(unlockedLevels)")
    }
}
    
// MARK: - Level Config Manager
class LevelConfig {
    static let shared = LevelConfig()
    
    var levels: [Level] = []  // Changed from private(set) to var
    
    private init() {
        loadLevels()  // 使用标准关卡配置
    }
    
    func getCurrentLevel() -> Level {
        let levelIndex = GameStateManager.shared.currentLevel - 1
        print("🔍 getCurrentLevel: currentLevel=\(GameStateManager.shared.currentLevel), levelIndex=\(levelIndex), levels.count=\(levels.count)")
        if levelIndex >= 0 && levelIndex < levels.count {
            print("✅ 返回关卡: \(levels[levelIndex].name)")
            return levels[levelIndex]
        }
        print("⚠️ 使用fallback关卡: \(levels[0].name)")
        return levels[0] // Fallback
    }
    
    func getLevel(at index: Int) -> Level? {
        guard index >= 0 && index < levels.count else { return nil }
        return levels[index]
    }
    
    private func loadLevels() {
        levels = [
            // ═══════════════════════════════════════════════════════════════
            // 第一阶段：炼气期 (Qi Refining) - "无脑爽"
            // 目标：建立自信，体验合成快感
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 1,
                name: "炼气一层",
                subtitle: "引气入体，剑道初显",
                targetScore: 30,  // 进一步降低目标分数从50到30
                targetMerges: 1,  // 进一步降低目标合成次数从2到1
                starThresholds: [30, 60, 90],  // 相应调整星级阈值
                formationType: .hexagon,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan],
                spawnWeights: [.fan: 1.0] // 100% 凡剑，保证极易合成
            ),
            Level(
                id: 2,
                name: "炼气三层",
                subtitle: "初识剑气，锋芒毕露",
                targetScore: 200,
                targetMerges: 5,
                starThresholds: [200, 300, 400],
                formationType: .hexagon,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan, .ling],
                spawnWeights: [.fan: 0.85, .ling: 0.15] // 引入灵剑
            ),
            Level(
                id: 3,
                name: "炼气圆满",
                subtitle: "剑意纵横，势不可挡",
                targetScore: 300,
                targetMerges: 8,
                starThresholds: [300, 500, 700],
                formationType: .diamond,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .ling, .ling],
                spawnWeights: [.fan: 0.75, .ling: 0.25]
            ),
            Level(
                id: 4,
                name: "筑基雷劫",
                subtitle: "雷劫将至，速战速决",
                targetScore: 500,
                targetMerges: 10,
                starThresholds: [500, 800, 1000],
                formationType: .triangle,
                rules: LevelRules(timeLimit: 120), // 引入时间限制
                gridRadius: 3,
                initialSwordTypes: [.fan, .fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.7, .ling: 0.25, .xian: 0.05]
            ),
            Level(
                id: 5,
                name: "半步筑基",
                subtitle: "打破桎梏，逆天而行",
                targetScore: 600,
                targetMerges: 12,
                starThresholds: [600, 900, 1200],
                formationType: .ring,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 2), // 引入障碍
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.65, .ling: 0.3, .xian: 0.05]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第二阶段：筑基期 (Foundation) - "微策略"
            // 目标：策略觉醒，引入方向和障碍
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 6,
                name: "筑基初期",
                subtitle: "道基初成，稳扎稳打",
                targetScore: 800,
                targetMerges: 15,
                starThresholds: [800, 1200, 1600],
                formationType: .diamond,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 3),
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .xian],
                spawnWeights: [.fan: 0.6, .ling: 0.35, .xian: 0.05]
            ),
            Level(
                id: 7,
                name: "剑气化形",
                subtitle: "以气御剑，无远弗届",
                targetScore: 1000,
                targetMerges: 18,
                starThresholds: [1000, 1500, 2000],
                formationType: .star,
                rules: LevelRules(moveLimit: 30), // 引入步数限制
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.55, .ling: 0.35, .xian: 0.1]
            ),
            Level(
                id: 8,
                name: "阴阳调和",
                subtitle: "太极生两仪，两仪生四象",
                targetScore: 1200,
                targetMerges: 20,
                starThresholds: [1200, 1800, 2400],
                formationType: .spiral,
                rules: LevelRules(gravityDirection: .center), // 引入重力
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .xian],
                spawnWeights: [.fan: 0.5, .ling: 0.4, .xian: 0.1]
            ),
            Level(
                id: 9,
                name: "心魔入侵",
                subtitle: "守住道心，斩断虚妄",
                targetScore: 1500,
                targetMerges: 25,
                starThresholds: [1500, 2250, 3000],
                formationType: .random,
                rules: LevelRules(shuffleInterval: 40), // 引入自动干扰
                gridRadius: 3,
                initialSwordTypes: [.ling, .ling, .xian, .xian],
                spawnWeights: [.fan: 0.45, .ling: 0.4, .xian: 0.15]
            ),
            Level(
                id: 10,
                name: "结丹",
                subtitle: "金丹大成，万剑归宗",
                targetScore: 2000,
                targetMerges: 30,
                starThresholds: [2000, 3000, 4000],
                formationType: .bagua,
                rules: LevelRules(hasBossSword: true), // 引入 Boss 概念 (需代码支持)
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .xian, .shen],
                spawnWeights: [.fan: 0.4, .ling: 0.35, .xian: 0.2, .shen: 0.05]
            )
        ]
    }
}
