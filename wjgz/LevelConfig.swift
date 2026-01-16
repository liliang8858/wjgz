import Foundation
import UIKit

// MARK: - Formation Types (剑阵形态)
enum FormationType: String, CaseIterable {
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
struct LevelRules {
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
}

enum GravityDirection: String {
    case none = "无"
    case down = "下"
    case up = "上"
    case center = "中心"
    case outward = "外散"
}

// MARK: - Level Definition
struct Level {
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

// MARK: - Level Config Manager
class LevelConfig {
    static let shared = LevelConfig()
    
    private(set) var levels: [Level] = []
    private(set) var currentLevelIndex: Int = 0
    
    private init() {
        loadLevels()
        loadProgress()
    }
    
    private func loadLevels() {
        levels = [
            // ═══════════════════════════════════════════════════════════════
            // 第一章：始计篇 - "兵者，国之大事"
            // 孙子兵法开篇，讲述战争的重要性，对应游戏入门
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 1,
                name: "初入剑门",
                subtitle: "兵者，国之大事",
                targetScore: 100,
                targetMerges: 5,
                starThresholds: [100, 150, 200],
                formationType: .hexagon,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan],
                spawnWeights: [.fan: 0.9, .ling: 0.1]
            ),
            Level(
                id: 2,
                name: "知己知彼",
                subtitle: "知己知彼，百战不殆",
                targetScore: 200,
                targetMerges: 8,
                starThresholds: [200, 300, 400],
                formationType: .hexagon,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan, .ling],
                spawnWeights: [.fan: 0.75, .ling: 0.25]
            ),
            Level(
                id: 3,
                name: "庙算多寡",
                subtitle: "多算胜，少算不胜",
                targetScore: 300,
                targetMerges: 12,
                starThresholds: [300, 450, 600],
                formationType: .diamond,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan, .ling, .ling],
                spawnWeights: [.fan: 0.7, .ling: 0.3]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第二章：作战篇 - "兵贵胜，不贵久"
            // 讲述速战速决的重要性，引入时间概念
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 4,
                name: "速战速决",
                subtitle: "兵贵胜，不贵久",
                targetScore: 500,
                targetMerges: 15,
                starThresholds: [500, 750, 1000],
                formationType: .cross,
                rules: LevelRules(timeLimit: 180),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .ling, .ling, .ling],
                spawnWeights: [.fan: 0.6, .ling: 0.35, .xian: 0.05]
            ),
            Level(
                id: 5,
                name: "因粮于敌",
                subtitle: "智将务食于敌",
                targetScore: 600,
                targetMerges: 18,
                starThresholds: [600, 900, 1200],
                formationType: .ring,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 1),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .ling, .ling],
                spawnWeights: [.fan: 0.55, .ling: 0.4, .xian: 0.05]
            ),
            Level(
                id: 6,
                name: "三才归元",
                subtitle: "天地人三才合一",
                targetScore: 800,
                targetMerges: 20,
                starThresholds: [800, 1200, 1600],
                formationType: .triangle,
                rules: LevelRules(),
                gridRadius: 3,
                initialSwordTypes: [.fan, .fan, .fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.5, .ling: 0.4, .xian: 0.1]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第三章：谋攻篇 - "不战而屈人之兵"
            // 讲述谋略的重要性，引入策略性玩法
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 7,
                name: "上兵伐谋",
                subtitle: "不战而屈人之兵",
                targetScore: 1000,
                targetMerges: 25,
                starThresholds: [1000, 1500, 2000],
                formationType: .star,
                rules: LevelRules(moveLimit: 40),
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.45, .ling: 0.4, .xian: 0.15]
            ),
            Level(
                id: 8,
                name: "太极流转",
                subtitle: "阴阳相生，刚柔并济",
                targetScore: 1200,
                targetMerges: 28,
                starThresholds: [1200, 1800, 2400],
                formationType: .spiral,
                rules: LevelRules(gravityDirection: .center),
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .xian],
                spawnWeights: [.fan: 0.4, .ling: 0.4, .xian: 0.2]
            ),
            Level(
                id: 9,
                name: "全胜之道",
                subtitle: "必以全争于天下",
                targetScore: 1500,
                targetMerges: 30,
                starThresholds: [1500, 2250, 3000],
                formationType: .random,
                rules: LevelRules(shuffleInterval: 30),
                gridRadius: 3,
                initialSwordTypes: [.ling, .ling, .xian, .xian],
                spawnWeights: [.fan: 0.35, .ling: 0.4, .xian: 0.2, .shen: 0.05]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第四章：军形篇 - "先为不可胜"
            // 讲述防守与进攻的平衡，引入八卦阵型
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 10,
                name: "乾天刚健",
                subtitle: "☰ 天行健，君子以自强不息",
                targetScore: 2000,
                targetMerges: 35,
                starThresholds: [2000, 3000, 4000],
                formationType: .qian,
                rules: LevelRules(timeLimit: 120),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .xian],
                spawnWeights: [.fan: 0.3, .ling: 0.4, .xian: 0.25, .shen: 0.05]
            ),
            Level(
                id: 11,
                name: "坤地厚德",
                subtitle: "☷ 地势坤，君子以厚德载物",
                targetScore: 2500,
                targetMerges: 40,
                starThresholds: [2500, 3750, 5000],
                formationType: .kun,
                rules: LevelRules(moveLimit: 50),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .shen],
                spawnWeights: [.fan: 0.25, .ling: 0.4, .xian: 0.3, .shen: 0.05]
            ),
            Level(
                id: 12,
                name: "先胜后战",
                subtitle: "先为不可胜，以待敌之可胜",
                targetScore: 3000,
                targetMerges: 45,
                starThresholds: [3000, 4500, 6000],
                formationType: .bagua,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 2),
                gridRadius: 3,
                initialSwordTypes: [.xian, .xian, .shen],
                spawnWeights: [.fan: 0.2, .ling: 0.35, .xian: 0.35, .shen: 0.1]
            ),

            // ═══════════════════════════════════════════════════════════════
            // 第五章：兵势篇 - "势如彍弩"
            // 讲述气势与节奏，引入更多八卦元素
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 13,
                name: "震雷奋发",
                subtitle: "☳ 震惊百里，不丧匕鬯",
                targetScore: 3500,
                targetMerges: 48,
                starThresholds: [3500, 5250, 7000],
                formationType: .zhen,
                rules: LevelRules(timeLimit: 100, gravityDirection: .down),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .xian, .shen],
                spawnWeights: [.fan: 0.2, .ling: 0.35, .xian: 0.35, .shen: 0.1]
            ),
            Level(
                id: 14,
                name: "巽风无孔",
                subtitle: "☴ 随风巽，君子以申命行事",
                targetScore: 4000,
                targetMerges: 50,
                starThresholds: [4000, 6000, 8000],
                formationType: .xun,
                rules: LevelRules(shuffleInterval: 25),
                gridRadius: 3,
                initialSwordTypes: [.xian, .xian, .shen],
                spawnWeights: [.fan: 0.15, .ling: 0.35, .xian: 0.4, .shen: 0.1]
            ),
            Level(
                id: 15,
                name: "奇正相生",
                subtitle: "以正合，以奇胜",
                targetScore: 4500,
                targetMerges: 52,
                starThresholds: [4500, 6750, 9000],
                formationType: .wuxing,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 2, moveLimit: 45),
                gridRadius: 3,
                initialSwordTypes: [.xian, .shen, .shen],
                spawnWeights: [.fan: 0.15, .ling: 0.3, .xian: 0.4, .shen: 0.15]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第六章：虚实篇 - "避实而击虚"
            // 讲述虚实变化，引入更复杂的规则组合
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 16,
                name: "坎水险阻",
                subtitle: "☵ 习坎，有孚维心亨",
                targetScore: 5000,
                targetMerges: 55,
                starThresholds: [5000, 7500, 10000],
                formationType: .kan,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 4, gravityDirection: .center),
                gridRadius: 3,
                initialSwordTypes: [.xian, .xian, .shen],
                spawnWeights: [.fan: 0.1, .ling: 0.3, .xian: 0.45, .shen: 0.15]
            ),
            Level(
                id: 17,
                name: "离火光明",
                subtitle: "☲ 离，利贞亨，畜牝牛吉",
                targetScore: 5500,
                targetMerges: 58,
                starThresholds: [5500, 8250, 11000],
                formationType: .li,
                rules: LevelRules(timeLimit: 90, shuffleInterval: 20),
                gridRadius: 3,
                initialSwordTypes: [.xian, .shen, .shen],
                spawnWeights: [.fan: 0.1, .ling: 0.25, .xian: 0.45, .shen: 0.2]
            ),
            Level(
                id: 18,
                name: "避实击虚",
                subtitle: "兵之形，避实而击虚",
                targetScore: 6000,
                targetMerges: 60,
                starThresholds: [6000, 9000, 12000],
                formationType: .jiugong,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 3, moveLimit: 40),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen],
                spawnWeights: [.fan: 0.1, .ling: 0.2, .xian: 0.5, .shen: 0.2]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第七章：军争篇 - "以迂为直"
            // 讲述争夺先机，引入极限挑战
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 19,
                name: "艮山静止",
                subtitle: "☶ 兼山艮，君子以思不出其位",
                targetScore: 6500,
                targetMerges: 62,
                starThresholds: [6500, 9750, 13000],
                formationType: .gen,
                rules: LevelRules(moveLimit: 35),
                gridRadius: 3,
                initialSwordTypes: [.xian, .shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.2, .xian: 0.5, .shen: 0.25]
            ),
            Level(
                id: 20,
                name: "兑泽和悦",
                subtitle: "☱ 丽泽兑，君子以朋友讲习",
                targetScore: 7000,
                targetMerges: 65,
                starThresholds: [7000, 10500, 14000],
                formationType: .dui,
                rules: LevelRules(timeLimit: 80),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.15, .xian: 0.5, .shen: 0.3]
            ),
            Level(
                id: 21,
                name: "以迂为直",
                subtitle: "迂其途而诱之以利",
                targetScore: 7500,
                targetMerges: 68,
                starThresholds: [7500, 11250, 15000],
                formationType: .bagua,
                rules: LevelRules(hasBlockedCells: true, blockedCellCount: 3, timeLimit: 75, moveLimit: 50),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.15, .xian: 0.45, .shen: 0.35]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第八章：九变篇 - "将通于九变之利"
            // 讲述灵活应变，终极挑战
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 22,
                name: "九变之道",
                subtitle: "将通于九变之利者，知用兵矣",
                targetScore: 8000,
                targetMerges: 70,
                starThresholds: [8000, 12000, 16000],
                formationType: .jiugong,
                rules: LevelRules(timeLimit: 70, shuffleInterval: 15),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.1, .xian: 0.45, .shen: 0.4]
            ),
            Level(
                id: 23,
                name: "天罡北斗",
                subtitle: "三十六天罡，镇压四方",
                targetScore: 9000,
                targetMerges: 75,
                starThresholds: [9000, 13500, 18000],
                formationType: .tiangang,
                rules: LevelRules(hasBossSword: true, moveLimit: 36),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.1, .xian: 0.4, .shen: 0.45]
            ),
            Level(
                id: 24,
                name: "万剑归宗",
                subtitle: "万法归一，剑道至尊",
                targetScore: 10000,
                targetMerges: 80,
                starThresholds: [10000, 15000, 20000],
                formationType: .bagua,
                rules: LevelRules(hasBossSword: true, timeLimit: 60, moveLimit: 40, gravityDirection: .center),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.1, .xian: 0.4, .shen: 0.5]
            ),
        ]
    }
    
    func getCurrentLevel() -> Level {
        return levels[min(currentLevelIndex, levels.count - 1)]
    }
    
    func getLevel(at index: Int) -> Level? {
        guard index >= 0 && index < levels.count else { return nil }
        return levels[index]
    }
    
    func completeLevel(stars: Int) {
        if stars > 0 && currentLevelIndex < levels.count - 1 {
            currentLevelIndex += 1
            saveProgress()
        }
    }
    
    func restartLevel() {
        // Current level stays the same
    }
    
    func goToNextLevel() {
        if currentLevelIndex < levels.count - 1 {
            currentLevelIndex += 1
            saveProgress()
        }
    }
    
    func goToLevel(_ index: Int) {
        if index >= 0 && index < levels.count {
            currentLevelIndex = index
            saveProgress()
        }
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(currentLevelIndex, forKey: "currentLevel")
    }
    
    private func loadProgress() {
        // 如果是第一次启动，UserDefaults 会返回 0，这正好是第一关
        let savedLevel = UserDefaults.standard.integer(forKey: "currentLevel")
        currentLevelIndex = max(0, min(savedLevel, levels.count - 1))
    }
    
    func resetProgress() {
        currentLevelIndex = 0
        saveProgress()
    }
}
