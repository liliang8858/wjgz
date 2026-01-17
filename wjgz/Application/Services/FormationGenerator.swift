import Foundation

/// 阵型生成器 - 根据关卡配置生成初始剑的位置
public final class FormationGenerator {
    
    /// 根据阵型类型生成位置数组
    public static func generatePositions(for formation: FormationType, in gameGrid: GameGrid) -> [HexPosition] {
        switch formation {
        case .hexagon:
            return generateHexagonFormation()
        case .diamond:
            return generateDiamondFormation()
        case .cross:
            return generateCrossFormation()
        case .ring:
            return generateRingFormation()
        case .triangle:
            return generateTriangleFormation()
        case .star:
            return generateStarFormation()
        case .spiral:
            return generateSpiralFormation()
        case .random:
            return generateRandomFormation()
        case .qian, .kun, .zhen, .xun, .kan, .li, .gen, .dui:
            return generateBaguaFormation(formation)
        case .bagua:
            return generateFullBaguaFormation()
        case .wuxing:
            return generateWuxingFormation()
        case .jiugong:
            return generateJiugongFormation()
        case .tiangang:
            return generateTiangangFormation()
        }
    }
    
    // MARK: - Basic Formations
    
    private static func generateTriangleFormation() -> [HexPosition] {
        return [
            HexPosition(q: 0, r: -2),
            HexPosition(q: -1, r: -1), HexPosition(q: 1, r: -1),
            HexPosition(q: -2, r: 0), HexPosition(q: 0, r: 0), HexPosition(q: 2, r: 0),
            HexPosition(q: -1, r: 1), HexPosition(q: 1, r: 1)
        ]
    }
    
    private static func generateStarFormation() -> [HexPosition] {
        return [
            HexPosition(q: 0, r: 0), // 中心
            HexPosition(q: 0, r: -2), HexPosition(q: 2, r: -2), HexPosition(q: 2, r: 0),
            HexPosition(q: 0, r: 2), HexPosition(q: -2, r: 2), HexPosition(q: -2, r: 0)
        ]
    }
    
    private static func generateSpiralFormation() -> [HexPosition] {
        let spiral = [
            HexPosition(q: 0, r: 0),
            HexPosition(q: 1, r: 0), HexPosition(q: 1, r: -1), HexPosition(q: 0, r: -1),
            HexPosition(q: -1, r: 0), HexPosition(q: -1, r: 1), HexPosition(q: 0, r: 1),
            HexPosition(q: 2, r: -1), HexPosition(q: 2, r: -2), HexPosition(q: 1, r: -2),
            HexPosition(q: 0, r: -2), HexPosition(q: -1, r: -1), HexPosition(q: -2, r: 0),
            HexPosition(q: -2, r: 1), HexPosition(q: -2, r: 2), HexPosition(q: -1, r: 2),
            HexPosition(q: 0, r: 2), HexPosition(q: 1, r: 1), HexPosition(q: 2, r: 0)
        ]
        return spiral
    }
    
    private static func generateRandomFormation() -> [HexPosition] {
        var allPositions: [HexPosition] = []
        
        for q in -2...2 {
            for r in max(-2, -q - 2)...min(2, -q + 2) {
                allPositions.append(HexPosition(q: q, r: r))
            }
        }
        
        // 随机选择 60% 的位置
        let count = Int(Double(allPositions.count) * 0.6)
        return Array(allPositions.shuffled().prefix(count))
    }
    
    // MARK: - Bagua Formations
    
    private static func generateBaguaFormation(_ type: FormationType) -> [HexPosition] {
        switch type {
        case .qian: // 乾卦 ☰
            return [
                HexPosition(q: -1, r: -1), HexPosition(q: 0, r: -1), HexPosition(q: 1, r: -1),
                HexPosition(q: -1, r: 0), HexPosition(q: 0, r: 0), HexPosition(q: 1, r: 0),
                HexPosition(q: -1, r: 1), HexPosition(q: 0, r: 1), HexPosition(q: 1, r: 1)
            ]
        case .kun: // 坤卦 ☷
            return [
                HexPosition(q: -2, r: -1), HexPosition(q: 2, r: -1),
                HexPosition(q: -2, r: 0), HexPosition(q: 2, r: 0),
                HexPosition(q: -2, r: 1), HexPosition(q: 2, r: 1)
            ]
        case .zhen: // 震卦 ☳
            return [
                HexPosition(q: 0, r: -2),
                HexPosition(q: -1, r: -1), HexPosition(q: 1, r: -1),
                HexPosition(q: 0, r: 0),
                HexPosition(q: -1, r: 1), HexPosition(q: 1, r: 1)
            ]
        case .xun: // 巽卦 ☴
            return [
                HexPosition(q: -1, r: -1), HexPosition(q: 1, r: -1),
                HexPosition(q: 0, r: 0),
                HexPosition(q: -1, r: 1), HexPosition(q: 0, r: 1), HexPosition(q: 1, r: 1)
            ]
        case .kan: // 坎卦 ☵
            return [
                HexPosition(q: -1, r: -1), HexPosition(q: 1, r: -1),
                HexPosition(q: 0, r: 0),
                HexPosition(q: -1, r: 1), HexPosition(q: 1, r: 1)
            ]
        case .li: // 离卦 ☲
            return [
                HexPosition(q: -1, r: -1), HexPosition(q: 0, r: -1), HexPosition(q: 1, r: -1),
                HexPosition(q: 0, r: 0),
                HexPosition(q: -1, r: 1), HexPosition(q: 0, r: 1), HexPosition(q: 1, r: 1)
            ]
        case .gen: // 艮卦 ☶
            return [
                HexPosition(q: 0, r: -1),
                HexPosition(q: -1, r: 0), HexPosition(q: 1, r: 0),
                HexPosition(q: -1, r: 1), HexPosition(q: 0, r: 1), HexPosition(q: 1, r: 1)
            ]
        case .dui: // 兑卦 ☱
            return [
                HexPosition(q: -1, r: -1), HexPosition(q: 0, r: -1), HexPosition(q: 1, r: -1),
                HexPosition(q: -1, r: 0), HexPosition(q: 1, r: 0),
                HexPosition(q: 0, r: 1)
            ]
        default:
            return generateHexagonFormation()
        }
    }
    
    private static func generateFullBaguaFormation() -> [HexPosition] {
        // 完整八卦阵，包含所有八个方位
        return [
            // 中心
            HexPosition(q: 0, r: 0),
            // 八个方向
            HexPosition(q: 0, r: -2), // 北
            HexPosition(q: 2, r: -2), // 东北
            HexPosition(q: 2, r: 0),  // 东
            HexPosition(q: 0, r: 2),  // 东南
            HexPosition(q: -2, r: 2), // 南
            HexPosition(q: -2, r: 0), // 西南
            HexPosition(q: -2, r: -2), // 西
            HexPosition(q: 0, r: -2)  // 西北
        ]
    }
    
    private static func generateWuxingFormation() -> [HexPosition] {
        // 五行阵：金木水火土
        return [
            HexPosition(q: 0, r: 0),   // 土（中心）
            HexPosition(q: 0, r: -2),  // 水（北）
            HexPosition(q: 2, r: 0),   // 金（西）
            HexPosition(q: 0, r: 2),   // 火（南）
            HexPosition(q: -2, r: 0),  // 木（东）
            // 辅助位置
            HexPosition(q: 1, r: -1), HexPosition(q: -1, r: -1),
            HexPosition(q: 1, r: 1), HexPosition(q: -1, r: 1)
        ]
    }
    
    private static func generateJiugongFormation() -> [HexPosition] {
        // 九宫格阵
        return [
            HexPosition(q: -1, r: -1), HexPosition(q: 0, r: -1), HexPosition(q: 1, r: -1),
            HexPosition(q: -1, r: 0),  HexPosition(q: 0, r: 0),  HexPosition(q: 1, r: 0),
            HexPosition(q: -1, r: 1),  HexPosition(q: 0, r: 1),  HexPosition(q: 1, r: 1)
        ]
    }
    
    private static func generateTiangangFormation() -> [HexPosition] {
        // 天罡阵 - 复杂的星象阵型
        return [
            // 内圈
            HexPosition(q: 0, r: 0),
            HexPosition(q: 1, r: 0), HexPosition(q: 0, r: -1), HexPosition(q: -1, r: 0),
            HexPosition(q: -1, r: 1), HexPosition(q: 0, r: 1), HexPosition(q: 1, r: -1),
            // 外圈
            HexPosition(q: 2, r: -1), HexPosition(q: 1, r: -2), HexPosition(q: -1, r: -1),
            HexPosition(q: -2, r: 1), HexPosition(q: -1, r: 2), HexPosition(q: 1, r: 1),
            // 特殊位置
            HexPosition(q: 2, r: 0), HexPosition(q: 0, r: -2), HexPosition(q: -2, r: 0), HexPosition(q: 0, r: 2)
        ]
    }
    
    private static func generateHexagonFormation() -> [HexPosition] {
        var positions: [HexPosition] = []
        
        for q in -2...2 {
            for r in max(-2, -q - 2)...min(2, -q + 2) {
                positions.append(HexPosition(q: q, r: r))
            }
        }
        
        return positions
    }
    
    private static func generateDiamondFormation() -> [HexPosition] {
        return [
            HexPosition(q: 0, r: -2),
            HexPosition(q: -1, r: -1), HexPosition(q: 1, r: -1),
            HexPosition(q: -2, r: 0), HexPosition(q: 0, r: 0), HexPosition(q: 2, r: 0),
            HexPosition(q: -1, r: 1), HexPosition(q: 1, r: 1),
            HexPosition(q: 0, r: 2)
        ]
    }
    
    private static func generateCrossFormation() -> [HexPosition] {
        return [
            HexPosition(q: 0, r: -2),
            HexPosition(q: 0, r: -1),
            HexPosition(q: -2, r: 0), HexPosition(q: -1, r: 0), HexPosition(q: 0, r: 0), HexPosition(q: 1, r: 0), HexPosition(q: 2, r: 0),
            HexPosition(q: 0, r: 1),
            HexPosition(q: 0, r: 2)
        ]
    }
    
    private static func generateRingFormation() -> [HexPosition] {
        var positions: [HexPosition] = []
        
        // 外环
        for q in -2...2 {
            for r in max(-2, -q - 2)...min(2, -q + 2) {
                if abs(q) == 2 || abs(r) == 2 || abs(q + r) == 2 {
                    positions.append(HexPosition(q: q, r: r))
                }
            }
        }
        
        return positions
    }
}