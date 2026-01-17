import Foundation
import CoreGraphics
import UIKit

// MARK: - Sword Types (4 levels like demo)
enum SwordType: Int, CaseIterable, Codable {
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
    static let baseMaxEnergy: CGFloat = 100  // 基础能量池
    static let energyGrowthPerLevel: CGFloat = 15  // 每关增长的能量
    static let comboTimeout: TimeInterval = 3.0
    static let ultimateClearPercent: Double = 0.7
    
    // 根据关卡计算最大能量
    static func maxEnergy(for level: Int) -> CGFloat {
        return baseMaxEnergy + CGFloat(level - 1) * energyGrowthPerLevel
    }
}
