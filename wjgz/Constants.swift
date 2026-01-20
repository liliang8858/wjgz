import Foundation
import CoreGraphics
import UIKit

// MARK: - Sword Types (4 levels like demo)
public enum SwordType: Int, CaseIterable, Codable {
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
        case .fan: return UIColor(red: 0.545, green: 0.271, blue: 0.075, alpha: 1.0) // #8b4513
        case .ling: return UIColor(red: 0.118, green: 0.565, blue: 1.0, alpha: 1.0) // #1e90ff
        case .xian: return UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0) // #ffd700
        case .shen: return UIColor(red: 1.0, green: 0.549, blue: 0.0, alpha: 1.0) // #ff8c00
        }
    }
    
    var glowColor: UIColor {
        switch self {
        case .fan: return UIColor(red: 1.0, green: 0.271, blue: 0.0, alpha: 0.5) // #ff4500
        case .ling: return UIColor(red: 0.0, green: 0.749, blue: 1.0, alpha: 0.7) // #00bfff
        case .xian: return UIColor(red: 0.576, green: 0.2, blue: 0.918, alpha: 0.8) // #9333ea
        case .shen: return UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0) // #ffd700
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
    
    var upgraded: SwordType? {
        switch self {
        case .fan: return .ling
        case .ling: return .xian
        case .xian: return .shen
        case .shen: return nil // 神剑已是最高级
        }
    }
    
    static func random() -> SwordType {
        return SwordType.allCases.randomElement() ?? .fan
    }
}

// MARK: - Game Configuration
struct GameConfig {
    static let tileRadius: CGFloat = 35.0
    static let gridSpacing: CGFloat = 5.0
    static let baseMaxEnergy: CGFloat = 100  // 基础能量池
    static let energyGrowthPerLevel: CGFloat = 15  // 每关增长的能量
    static let comboTimeout: TimeInterval = 3.0
    static let ultimateClearPercent: Double = 0.7
    
    // 根据关卡计算最大能量
    static func maxEnergy(for level: Int) -> CGFloat {
        return baseMaxEnergy + CGFloat(level - 1) * energyGrowthPerLevel
    }
}
