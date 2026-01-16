import Foundation
import UIKit

// MARK: - Formation Types (剑阵形态)
enum FormationType: String, CaseIterable {
    case hexagon = "六合阵"      // 标准六边形
    case diamond = "菱形阵"      // 菱形
    case cross = "十字阵"        // 十字形
    case ring = "环形阵"         // 环形（中空）
    case triangle = "三才阵"     // 三角形
    case star = "七星阵"         // 星形
    case spiral = "太极阵"       // 螺旋形
    case random = "乱剑阵"       // 随机形态
    
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
            // ===== 第一章：入门篇 =====
            Level(
                id: 1,
                name: "初入剑门",
                subtitle: "熟悉剑阵基础",
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
                name: "剑意初萌",
                subtitle: "感受剑气流动",
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
                name: "三剑合一",
                subtitle: "掌握合成精髓",
                targetScore: 300,
                targetMerges: 12,
                starThresholds: [300, 450, 600],
                formationType: .diamond,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan, .ling, .ling],
                spawnWeights: [.fan: 0.7, .ling: 0.3]
            ),
            
            // ===== 第二章：进阶篇 =====
            Level(
                id: 4,
                name: "剑气纵横",
                subtitle: "体验连锁消除",
                targetScore: 500,
                targetMerges: 15,
                starThresholds: [500, 750, 1000],
                formationType: .cross,
                rules: LevelRules(),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .ling, .ling, .ling],
                spawnWeights: [.fan: 0.6, .ling: 0.35, .xian: 0.05]
            ),
            Level(
                id: 5,
                name: "环阵蓄力",
                subtitle: "中空剑阵的奥秘",
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
                subtitle: "天地人三才阵",
                targetScore: 800,
                targetMerges: 20,
                starThresholds: [800, 1200, 1600],
                formationType: .triangle,
                rules: LevelRules(),
                gridRadius: 3,
                initialSwordTypes: [.fan, .fan, .fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.5, .ling: 0.4, .xian: 0.1]
            ),
            
            // ===== 第三章：挑战篇 =====
            Level(
                id: 7,
                name: "七星引路",
                subtitle: "北斗七星剑阵",
                targetScore: 1000,
                targetMerges: 25,
                starThresholds: [1000, 1500, 2000],
                formationType: .star,
                rules: LevelRules(),
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.45, .ling: 0.4, .xian: 0.15]
            ),
            Level(
                id: 8,
                name: "太极流转",
                subtitle: "阴阳相生剑阵",
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
                name: "乱剑无形",
                subtitle: "变幻莫测的剑阵",
                targetScore: 1500,
                targetMerges: 30,
                starThresholds: [1500, 2250, 3000],
                formationType: .random,
                rules: LevelRules(shuffleInterval: 30),
                gridRadius: 3,
                initialSwordTypes: [.ling, .ling, .xian, .xian],
                spawnWeights: [.fan: 0.35, .ling: 0.4, .xian: 0.2, .shen: 0.05]
            ),
            
            // ===== 第四章：大师篇 =====
            Level(
                id: 10,
                name: "剑道小成",
                subtitle: "限时挑战",
                targetScore: 2000,
                targetMerges: 35,
                starThresholds: [2000, 3000, 4000],
                formationType: .hexagon,
                rules: LevelRules(timeLimit: 120),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .xian],
                spawnWeights: [.fan: 0.3, .ling: 0.4, .xian: 0.25, .shen: 0.05]
            ),
            Level(
                id: 11,
                name: "步步为营",
                subtitle: "限步挑战",
                targetScore: 2500,
                targetMerges: 40,
                starThresholds: [2500, 3750, 5000],
                formationType: .diamond,
                rules: LevelRules(moveLimit: 50),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .shen],
                spawnWeights: [.fan: 0.25, .ling: 0.4, .xian: 0.3, .shen: 0.05]
            ),
            Level(
                id: 12,
                name: "万剑归宗",
                subtitle: "终极剑道",
                targetScore: 5000,
                targetMerges: 50,
                starThresholds: [5000, 7500, 10000],
                formationType: .star,
                rules: LevelRules(hasBossSword: true),
                gridRadius: 3,
                initialSwordTypes: [.xian, .xian, .shen],
                spawnWeights: [.fan: 0.2, .ling: 0.35, .xian: 0.35, .shen: 0.1]
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
