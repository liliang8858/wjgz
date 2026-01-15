import Foundation
import CoreGraphics
import UIKit

enum SwordType: Int, CaseIterable {
    case fan = 1 // Mortal (Base)
    case ling = 2 // Spirit (Directional)
    case xian = 3 // Immortal (Area)
    
    var name: String {
        switch self {
        case .fan: return "凡"
        case .ling: return "灵"
        case .xian: return "仙"
        }
    }
    
    var color: UIColor {
        switch self {
        case .fan: return .lightGray
        case .ling: return .cyan
        case .xian: return .yellow
        }
    }
}

struct GameConfig {
    static let tileRadius: CGFloat = 35.0
    static let gridSpacing: CGFloat = 5.0
}
