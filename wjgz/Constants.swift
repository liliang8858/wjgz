import Foundation
import CoreGraphics
import UIKit

// MARK: - Sword Types (4 levels like demo)
enum SwordType: Int, CaseIterable {
    case fan = 1    // 凡剑 - Mortal (Base)
    case ling = 2   // 灵剑 - Spirit (Directional clear)
    case xian = 3   // 仙剑 - Immortal (Area clear)
    case shen = 4   // 神剑 - Divine (Ultimate)
    
    var name: String {
        switch self {
        case .fan: return "凡"
        case .ling: return "灵"
        case .xian: return "仙"
        case .shen: return "神"
        }
    }
    
    var fullName: String {
        switch self {
        case .fan: return "凡剑"
        case .ling: return "灵剑"
        case .xian: return "仙剑"
        case .shen: return "神剑"
        }
    }
    
    var color: UIColor {
        switch self {
        case .fan: return UIColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1.0)
        case .ling: return UIColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0)
        case .xian: return UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0)
        case .shen: return UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        }
    }
    
    var glowColor: UIColor {
        switch self {
        case .fan: return UIColor(white: 0.8, alpha: 0.5)
        case .ling: return UIColor(red: 0.2, green: 1.0, blue: 0.8, alpha: 0.7)
        case .xian: return UIColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 0.8)
        case .shen: return UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        }
    }
    
    var baseScore: Int {
        switch self {
        case .fan: return 20
        case .ling: return 50
        case .xian: return 150
        case .shen: return 500
        }
    }
    
    var energyGain: CGFloat {
        switch self {
        case .fan: return 10
        case .ling: return 20
        case .xian: return 35
        case .shen: return 50
        }
    }
}

// MARK: - Game Configuration
struct GameConfig {
    static let tileRadius: CGFloat = 35.0
    static let gridSpacing: CGFloat = 5.0
    static let maxEnergy: CGFloat = 100
    static let comboTimeout: TimeInterval = 3.0
    static let ultimateClearPercent: Double = 0.7
}

// MARK: - Achievement System
struct Achievement: Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    var unlocked: Bool
    var progress: Int?
    var maxProgress: Int?
}

// MARK: - Sword Collection Data
struct SwordData: Codable {
    let id: String
    let name: String
    let type: String
    let description: String
    var unlocked: Bool
}

// MARK: - Game State Manager
class GameStateManager {
    static let shared = GameStateManager()
    
    private let storageKey = "sword_game_state"
    
    var totalCultivation: Int = 0
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
    
    private init() {
        loadState()
    }
    
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
            saveState()
        }
    }
    
    func unlockAchievement(_ id: String) {
        if let index = achievements.firstIndex(where: { $0.id == id && !$0.unlocked }) {
            achievements[index].unlocked = true
            saveState()
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
        saveState()
    }
    
    func recordCultivation(_ points: Int) {
        totalCultivation += points
        saveState()
    }
    
    func recordUltimate() {
        ultimateCount += 1
        unlockAchievement("ultimate_1")
        saveState()
    }
    
    func recordChainClear() {
        unlockAchievement("chain_clear")
        saveState()
    }
    
    private func saveState() {
        let state: [String: Any] = [
            "totalCultivation": totalCultivation,
            "ultimateCount": ultimateCount,
            "maxCombo": maxCombo,
            "tutorialCompleted": tutorialCompleted
        ]
        UserDefaults.standard.set(state, forKey: storageKey)
        
        if let swordData = try? JSONEncoder().encode(swordCollection) {
            UserDefaults.standard.set(swordData, forKey: "\(storageKey)_swords")
        }
        if let achievementData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(achievementData, forKey: "\(storageKey)_achievements")
        }
    }
    
    private func loadState() {
        if let state = UserDefaults.standard.dictionary(forKey: storageKey) {
            totalCultivation = state["totalCultivation"] as? Int ?? 0
            ultimateCount = state["ultimateCount"] as? Int ?? 0
            maxCombo = state["maxCombo"] as? Int ?? 0
            tutorialCompleted = state["tutorialCompleted"] as? Bool ?? false
        }
        
        if let swordData = UserDefaults.standard.data(forKey: "\(storageKey)_swords"),
           let swords = try? JSONDecoder().decode([SwordData].self, from: swordData) {
            swordCollection = swords
        }
        if let achievementData = UserDefaults.standard.data(forKey: "\(storageKey)_achievements"),
           let achs = try? JSONDecoder().decode([Achievement].self, from: achievementData) {
            achievements = achs
        }
    }
}
