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
        // 新增高级阵型 (25-48关专用)
        case .liuhe:
            return generateLiuheFormation()
        case .beidou:
            return generateBeidouFormation()
        case .sancai:
            return generateSancaiFormation()
        case .sixiang:
            return generateSixiangFormation()
        case .wuji:
            return generateWujiFormation()
        case .taiji:
            return generateTaijiFormation()
        case .liangyi:
            return generateLiangyiFormation()
        case .qixing:
            return generateQixingFormation()
        case .jiulong:
            return generateJiulongFormation()
        case .shier:
            return generateShierFormation()
        case .ershiba:
            return generateErshibaFormation()
        case .sanshiliu:
            return generateSanshiliuFormation()
        case .qishier:
            return generateQishierFormation()
        case .yibai:
            return generateYibaiFormation()
        case .zhoutian:
            return generateZhoutianFormation()
        case .xiantian:
            return generateXiantianFormation()
        case .houtian:
            return generateHoutianFormation()
        case .wanfa:
            return generateWanfaFormation()
        case .wuji_ultimate:
            return generateWujiUltimateFormation()
        case .chaos:
            return generateChaosFormation()
        case .creation:
            return generateCreationFormation()
        case .infinity:
            return generateInfinityFormation()
        case .transcendence:
            return generateTranscendenceFormation()
        case .immortal:
            return generateImmortalFormation()
        case .divine:
            return generateDivineFormation()
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
    
    // MARK: - Advanced Formations (25-48关专用)
    
    private static func generateLiuheFormation() -> [HexPosition] {
        // 六合阵：六个方向各一把剑
        return [
            HexPosition(q: 0, r: 0),   // 中心
            HexPosition(q: 1, r: 0),   // 东
            HexPosition(q: 0, r: 1),   // 东南
            HexPosition(q: -1, r: 1),  // 西南
            HexPosition(q: -1, r: 0),  // 西
            HexPosition(q: 0, r: -1),  // 西北
            HexPosition(q: 1, r: -1)   // 东北
        ]
    }
    
    private static func generateBeidouFormation() -> [HexPosition] {
        // 北斗七星阵
        return [
            HexPosition(q: -2, r: -1), // 天枢
            HexPosition(q: -1, r: -1), // 天璇
            HexPosition(q: 0, r: -1),  // 天玑
            HexPosition(q: 1, r: -1),  // 天权
            HexPosition(q: 1, r: 0),   // 玉衡
            HexPosition(q: 0, r: 1),   // 开阳
            HexPosition(q: -1, r: 1)   // 摇光
        ]
    }
    
    private static func generateSancaiFormation() -> [HexPosition] {
        // 三才阵：天地人
        return [
            HexPosition(q: 0, r: -2),  // 天
            HexPosition(q: 0, r: 0),   // 人
            HexPosition(q: 0, r: 2),   // 地
            HexPosition(q: -1, r: -1), HexPosition(q: 1, r: -1),
            HexPosition(q: -1, r: 1), HexPosition(q: 1, r: 1)
        ]
    }
    
    private static func generateSixiangFormation() -> [HexPosition] {
        // 四象阵：青龙白虎朱雀玄武
        return [
            HexPosition(q: 0, r: 0),   // 中心
            HexPosition(q: 2, r: -2),  // 青龙（东）
            HexPosition(q: -2, r: 2),  // 白虎（西）
            HexPosition(q: 0, r: -2),  // 朱雀（南）
            HexPosition(q: 0, r: 2),   // 玄武（北）
            HexPosition(q: 1, r: -1), HexPosition(q: -1, r: 1),
            HexPosition(q: 1, r: 1), HexPosition(q: -1, r: -1)
        ]
    }
    
    private static func generateWujiFormation() -> [HexPosition] {
        // 无极阵：圆形扩散
        var positions: [HexPosition] = []
        for radius in 0...3 {
            if radius == 0 {
                positions.append(HexPosition(q: 0, r: 0))
            } else {
                for i in 0..<(radius * 6) {
                    let angle = Double(i) * 2.0 * Double.pi / Double(radius * 6)
                    let q = Int(Double(radius) * cos(angle))
                    let r = Int(Double(radius) * sin(angle))
                    positions.append(HexPosition(q: q, r: r))
                }
            }
        }
        return Array(positions.prefix(15))
    }
    
    private static func generateTaijiFormation() -> [HexPosition] {
        // 太极阵：阴阳鱼形状
        return [
            HexPosition(q: 0, r: 0),   // 中心
            HexPosition(q: 1, r: 0), HexPosition(q: 2, r: 0),
            HexPosition(q: -1, r: 0), HexPosition(q: -2, r: 0),
            HexPosition(q: 0, r: 1), HexPosition(q: 0, r: 2),
            HexPosition(q: 0, r: -1), HexPosition(q: 0, r: -2),
            HexPosition(q: 1, r: 1), HexPosition(q: -1, r: -1)
        ]
    }
    
    private static func generateLiangyiFormation() -> [HexPosition] {
        // 两仪阵：阴阳两极
        return [
            // 阳极
            HexPosition(q: 1, r: -1), HexPosition(q: 2, r: -1), HexPosition(q: 1, r: 0),
            // 阴极
            HexPosition(q: -1, r: 1), HexPosition(q: -2, r: 1), HexPosition(q: -1, r: 0),
            // 中心连接
            HexPosition(q: 0, r: 0)
        ]
    }
    
    private static func generateQixingFormation() -> [HexPosition] {
        // 七星连珠：一条直线
        return [
            HexPosition(q: -3, r: 0), HexPosition(q: -2, r: 0), HexPosition(q: -1, r: 0),
            HexPosition(q: 0, r: 0),
            HexPosition(q: 1, r: 0), HexPosition(q: 2, r: 0), HexPosition(q: 3, r: 0)
        ]
    }
    
    private static func generateJiulongFormation() -> [HexPosition] {
        // 九龙朝天：九个龙形排列
        return [
            HexPosition(q: 0, r: 0),   // 中心龙
            HexPosition(q: 1, r: 0), HexPosition(q: 2, r: 0),   // 东龙
            HexPosition(q: -1, r: 0), HexPosition(q: -2, r: 0), // 西龙
            HexPosition(q: 0, r: 1), HexPosition(q: 0, r: 2),   // 南龙
            HexPosition(q: 0, r: -1), HexPosition(q: 0, r: -2), // 北龙
            HexPosition(q: 1, r: 1), HexPosition(q: -1, r: -1)  // 对角龙
        ]
    }
    
    private static func generateShierFormation() -> [HexPosition] {
        // 十二元辰：十二时辰方位
        var positions: [HexPosition] = []
        for i in 0..<12 {
            let angle = Double(i) * 2.0 * Double.pi / 12.0
            let radius = 2.0
            let q = Int(radius * cos(angle))
            let r = Int(radius * sin(angle))
            positions.append(HexPosition(q: q, r: r))
        }
        positions.append(HexPosition(q: 0, r: 0)) // 中心
        return positions
    }
    
    private static func generateErshibaFormation() -> [HexPosition] {
        // 二十八宿：简化版星宿排列
        var positions: [HexPosition] = []
        for i in 0..<28 {
            let angle = Double(i) * 2.0 * Double.pi / 28.0
            let radius = Double(2 + i % 3) // 变化半径
            let q = Int(radius * cos(angle))
            let r = Int(radius * sin(angle))
            positions.append(HexPosition(q: q, r: r))
        }
        return Array(positions.prefix(15)) // 限制数量
    }
    
    private static func generateSanshiliuFormation() -> [HexPosition] {
        // 三十六计：复杂战术排列
        return generateComplexFormation(count: 12)
    }
    
    private static func generateQishierFormation() -> [HexPosition] {
        // 七十二变：变化多端
        return generateComplexFormation(count: 15)
    }
    
    private static func generateYibaiFormation() -> [HexPosition] {
        // 一百零八将：英雄聚义
        return generateComplexFormation(count: 18)
    }
    
    private static func generateZhoutianFormation() -> [HexPosition] {
        // 周天星斗：满天星斗
        return generateComplexFormation(count: 20)
    }
    
    private static func generateXiantianFormation() -> [HexPosition] {
        // 先天八卦：原始八卦排列
        return generateFullBaguaFormation()
    }
    
    private static func generateHoutianFormation() -> [HexPosition] {
        // 后天八卦：后天八卦排列
        return generateFullBaguaFormation()
    }
    
    private static func generateWanfaFormation() -> [HexPosition] {
        // 万法归宗：所有法门汇聚
        return generateComplexFormation(count: 25)
    }
    
    private static func generateWujiUltimateFormation() -> [HexPosition] {
        // 无极至尊：终极无极阵
        return generateComplexFormation(count: 30)
    }
    
    private static func generateChaosFormation() -> [HexPosition] {
        // 混沌初开：混沌状态
        return generateComplexFormation(count: 35)
    }
    
    private static func generateCreationFormation() -> [HexPosition] {
        // 开天辟地：创世排列
        return generateComplexFormation(count: 40)
    }
    
    private static func generateInfinityFormation() -> [HexPosition] {
        // 无穷无尽：无限循环
        return generateComplexFormation(count: 45)
    }
    
    private static func generateTranscendenceFormation() -> [HexPosition] {
        // 超凡入圣：超越凡俗
        return generateComplexFormation(count: 50)
    }
    
    private static func generateImmortalFormation() -> [HexPosition] {
        // 仙人指路：仙人引导
        return generateComplexFormation(count: 55)
    }
    
    private static func generateDivineFormation() -> [HexPosition] {
        // 神魔乱舞：终极神魔阵
        return generateComplexFormation(count: 60)
    }
    
    // MARK: - Helper Methods
    
    private static func generateComplexFormation(count: Int) -> [HexPosition] {
        var positions: [HexPosition] = []
        
        // 生成复杂的多层阵型
        for radius in 0...4 {
            if radius == 0 {
                positions.append(HexPosition(q: 0, r: 0))
            } else {
                let pointsInRing = radius * 6
                for i in 0..<pointsInRing {
                    let angle = Double(i) * 2.0 * Double.pi / Double(pointsInRing)
                    let q = Int(Double(radius) * cos(angle))
                    let r = Int(Double(radius) * sin(angle))
                    positions.append(HexPosition(q: q, r: r))
                    
                    if positions.count >= count {
                        return positions
                    }
                }
            }
        }
        
        return positions
    }
}