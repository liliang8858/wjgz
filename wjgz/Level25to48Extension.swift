//
//  Level25to48Extension.swift
//  wjgz
//
//  扩展关卡25-48关配置
//

import Foundation

// MARK: - 扩展关卡配置 (25-48关)
extension LevelConfig {
    
    /// 加载48关完整配置
    func loadExtended48Levels() {
        // 先加载原始的24关
        loadOptimizedLevels()
        
        // 然后添加扩展的24关 (25-48)
        levels.append(contentsOf: loadExtended24Levels())
    }
    
    /// 获取扩展的24关 (25-48)
    private func loadExtended24Levels() -> [Level] {
        return [
            // ═══════════════════════════════════════════════════════════════
            // 第九章：超越极限 - 突破原有框架，探索新的可能性 (25-30关)
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 25,
                name: "六合无敌",
                subtitle: "🌌 六合之内，唯我独尊",
                targetScore: 6500,
                targetMerges: 68,
                starThresholds: [6500, 9750, 13000],
                formationType: .liuhe,
                rules: LevelRules(
                    hasBossSword: true,
                    timeLimit: 100,
                    moveLimit: 65,
                    ultimatePattern: UltimatePattern(
                        name: "六合无敌阵",
                        description: "在六个方向各放置一把神剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 1, r: 0), Position(q: 0, r: 1), Position(q: -1, r: 1), Position(q: -1, r: 0), Position(q: 0, r: -1), Position(q: 1, r: -1)],
                        swordTypes: Array(repeating: .shen, count: 6),
                        effectDescription: "六合无敌，横扫千军！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.1, .shen: 0.9]
            ),
            Level(
                id: 26,
                name: "北斗指路",
                subtitle: "⭐ 北斗七星，指引前路",
                targetScore: 7000,
                targetMerges: 70,
                starThresholds: [7000, 10500, 14000],
                formationType: .beidou,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 4,
                    shuffleInterval: 30,
                    ultimatePattern: UltimatePattern(
                        name: "北斗七星阵",
                        description: "达成12连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "北斗指路，破除迷障！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.05, .shen: 0.95]
            ),
            Level(
                id: 27,
                name: "三才合璧",
                subtitle: "🔺 天地人三才，合而为一",
                targetScore: 7500,
                targetMerges: 72,
                starThresholds: [7500, 11250, 15000],
                formationType: .sancai,
                rules: LevelRules(
                    timeLimit: 95,
                    moveLimit: 60,
                    gravityDirection: .center,
                    ultimatePattern: UltimatePattern(
                        name: "三才合璧阵",
                        description: "同时拥有15把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "三才合璧，天地同寿！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 28,
                name: "四象护法",
                subtitle: "🐉 青龙白虎，朱雀玄武",
                targetScore: 8000,
                targetMerges: 75,
                starThresholds: [8000, 12000, 16000],
                formationType: .sixiang,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 5,
                    hasBossSword: true,
                    shuffleInterval: 25,
                    ultimatePattern: UltimatePattern(
                        name: "四象护法阵",
                        description: "在四个角落各放置神剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 2, r: -2), Position(q: -2, r: 2), Position(q: 2, r: 0), Position(q: -2, r: 0)],
                        swordTypes: Array(repeating: .shen, count: 4),
                        effectDescription: "四象护法，镇守四方！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 29,
                name: "无极生太极",
                subtitle: "⚫ 无极而太极，太极生两仪",
                targetScore: 8500,
                targetMerges: 78,
                starThresholds: [8500, 12750, 17000],
                formationType: .wuji,
                rules: LevelRules(
                    timeLimit: 90,
                    moveLimit: 55,
                    gravityDirection: .outward,
                    ultimatePattern: UltimatePattern(
                        name: "无极太极阵",
                        description: "达成15连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "无极生太极，道法自然！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 30,
                name: "太极阴阳",
                subtitle: "☯ 太极生两仪，阴阳调和",
                targetScore: 9000,
                targetMerges: 80,
                starThresholds: [9000, 13500, 18000],
                formationType: .taiji,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 6,
                    hasBossSword: true,
                    timeLimit: 85,
                    ultimatePattern: UltimatePattern(
                        name: "太极阴阳阵",
                        description: "同时拥有18把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "太极阴阳，万物生长！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第十章：仙人境界 - 超凡脱俗，仙人手段 (31-36关)
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 31,
                name: "两仪四象",
                subtitle: "🔄 两仪生四象，四象生八卦",
                targetScore: 9500,
                targetMerges: 82,
                starThresholds: [9500, 14250, 19000],
                formationType: .liangyi,
                rules: LevelRules(
                    moveLimit: 50,
                    gravityDirection: .center,
                    shuffleInterval: 20,
                    ultimatePattern: UltimatePattern(
                        name: "两仪四象阵",
                        description: "达成18连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "两仪四象，生生不息！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 32,
                name: "七星连珠",
                subtitle: "🌟 七星连珠现，天象大变",
                targetScore: 10000,
                targetMerges: 85,
                starThresholds: [10000, 15000, 20000],
                formationType: .qixing,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 7,
                    hasBossSword: true,
                    timeLimit: 80,
                    ultimatePattern: UltimatePattern(
                        name: "七星连珠阵",
                        description: "在七个特定位置放置神剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 0, r: 0), Position(q: 1, r: 0), Position(q: 2, r: 0), Position(q: -1, r: 0), Position(q: -2, r: 0), Position(q: 0, r: 1), Position(q: 0, r: -1)],
                        swordTypes: Array(repeating: .shen, count: 7),
                        effectDescription: "七星连珠，天象异变！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 33,
                name: "九龙朝天",
                subtitle: "🐲 九龙齐飞，朝拜天帝",
                targetScore: 10500,
                targetMerges: 88,
                starThresholds: [10500, 15750, 21000],
                formationType: .jiulong,
                rules: LevelRules(
                    timeLimit: 75,
                    moveLimit: 45,
                    shuffleInterval: 15,
                    ultimatePattern: UltimatePattern(
                        name: "九龙朝天阵",
                        description: "同时拥有21把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "九龙朝天，威震九霄！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 34,
                name: "十二元辰",
                subtitle: "🕐 十二时辰，元辰轮转",
                targetScore: 11000,
                targetMerges: 90,
                starThresholds: [11000, 16500, 22000],
                formationType: .shier,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 8,
                    hasBossSword: true,
                    gravityDirection: .outward,
                    ultimatePattern: UltimatePattern(
                        name: "十二元辰阵",
                        description: "达成20连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "十二元辰，时空轮转！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 35,
                name: "二十八宿",
                subtitle: "✨ 二十八星宿，星辰大海",
                targetScore: 11500,
                targetMerges: 92,
                starThresholds: [11500, 17250, 23000],
                formationType: .ershiba,
                rules: LevelRules(
                    timeLimit: 70,
                    moveLimit: 40,
                    shuffleInterval: 12,
                    ultimatePattern: UltimatePattern(
                        name: "二十八宿阵",
                        description: "在28个位置放置神剑",
                        triggerCondition: .specificPattern,
                        positions: Array(0..<28).map { i in
                            let angle = Double(i) * 2.0 * Double.pi / 28.0
                            let radius = 3.0
                            let q = Int(radius * cos(angle))
                            let r = Int(radius * sin(angle))
                            return Position(q: q, r: r)
                        },
                        swordTypes: Array(repeating: .shen, count: 28),
                        effectDescription: "二十八宿，星辰大海！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 36,
                name: "三十六计",
                subtitle: "🎯 兵法三十六计，计计精妙",
                targetScore: 12000,
                targetMerges: 95,
                starThresholds: [12000, 18000, 24000],
                formationType: .sanshiliu,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 9,
                    hasBossSword: true,
                    timeLimit: 65,
                    ultimatePattern: UltimatePattern(
                        name: "三十六计阵",
                        description: "同时拥有24把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "三十六计，兵法无双！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第十一章：神魔之战 - 神魔大战，天地震动 (37-42关)
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 37,
                name: "七十二变",
                subtitle: "🌀 七十二般变化，神通广大",
                targetScore: 12500,
                targetMerges: 98,
                starThresholds: [12500, 18750, 25000],
                formationType: .qishier,
                rules: LevelRules(
                    moveLimit: 35,
                    gravityDirection: .center,
                    shuffleInterval: 10,
                    ultimatePattern: UltimatePattern(
                        name: "七十二变阵",
                        description: "达成25连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "七十二变，神通广大！"
                    )
                ),
                gridRadius: 5,
                initialSwordTypes: Array(repeating: .shen, count: 15),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 38,
                name: "一百零八将",
                subtitle: "⚔️ 梁山好汉，英雄聚义",
                targetScore: 13000,
                targetMerges: 100,
                starThresholds: [13000, 19500, 26000],
                formationType: .yibai,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 10,
                    hasBossSword: true,
                    timeLimit: 60,
                    ultimatePattern: UltimatePattern(
                        name: "一百零八将阵",
                        description: "同时拥有27把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "一百零八将，英雄聚义！"
                    )
                ),
                gridRadius: 6,
                initialSwordTypes: Array(repeating: .shen, count: 15),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 39,
                name: "周天星斗",
                subtitle: "🌌 周天星斗大阵，宇宙洪荒",
                targetScore: 13500,
                targetMerges: 102,
                starThresholds: [13500, 20250, 27000],
                formationType: .zhoutian,
                rules: LevelRules(
                    timeLimit: 55,
                    moveLimit: 30,
                    shuffleInterval: 8,
                    ultimatePattern: UltimatePattern(
                        name: "周天星斗阵",
                        description: "达成30连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "周天星斗，宇宙洪荒！"
                    )
                ),
                gridRadius: 6,
                initialSwordTypes: Array(repeating: .shen, count: 18),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 40,
                name: "先天八卦",
                subtitle: "☰ 先天八卦，混沌初分",
                targetScore: 14000,
                targetMerges: 105,
                starThresholds: [14000, 21000, 28000],
                formationType: .xiantian,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 12,
                    hasBossSword: true,
                    gravityDirection: .outward,
                    ultimatePattern: UltimatePattern(
                        name: "先天八卦阵",
                        description: "同时拥有30把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "先天八卦，混沌初分！"
                    )
                ),
                gridRadius: 6,
                initialSwordTypes: Array(repeating: .shen, count: 18),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 41,
                name: "后天八卦",
                subtitle: "☷ 后天八卦，造化玄机",
                targetScore: 14500,
                targetMerges: 108,
                starThresholds: [14500, 21750, 29000],
                formationType: .houtian,
                rules: LevelRules(
                    timeLimit: 50,
                    moveLimit: 25,
                    shuffleInterval: 6,
                    ultimatePattern: UltimatePattern(
                        name: "后天八卦阵",
                        description: "达成35连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "后天八卦，造化玄机！"
                    )
                ),
                gridRadius: 6,
                initialSwordTypes: Array(repeating: .shen, count: 20),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 42,
                name: "万法归宗",
                subtitle: "🏆 万法归宗，至高无上",
                targetScore: 15000,
                targetMerges: 110,
                starThresholds: [15000, 22500, 30000],
                formationType: .wanfa,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 15,
                    hasBossSword: true,
                    timeLimit: 45,
                    ultimatePattern: UltimatePattern(
                        name: "万法归宗大阵",
                        description: "同时拥有33把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "万法归宗，至高无上！"
                    )
                ),
                gridRadius: 6,
                initialSwordTypes: Array(repeating: .shen, count: 20),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第十二章：混沌至尊 - 超越一切，混沌至尊 (43-48关)
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 43,
                name: "无极至尊",
                subtitle: "⚫ 无极至尊，超越一切",
                targetScore: 15500,
                targetMerges: 112,
                starThresholds: [15500, 23250, 31000],
                formationType: .wuji_ultimate,
                rules: LevelRules(
                    moveLimit: 20,
                    gravityDirection: .center,
                    shuffleInterval: 5,
                    ultimatePattern: UltimatePattern(
                        name: "无极至尊阵",
                        description: "达成40连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "无极至尊，超越一切！"
                    )
                ),
                gridRadius: 6,
                initialSwordTypes: Array(repeating: .shen, count: 25),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 44,
                name: "混沌初开",
                subtitle: "🌀 混沌初开，天地未分",
                targetScore: 16000,
                targetMerges: 115,
                starThresholds: [16000, 24000, 32000],
                formationType: .chaos,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 18,
                    hasBossSword: true,
                    timeLimit: 40,
                    ultimatePattern: UltimatePattern(
                        name: "混沌初开阵",
                        description: "同时拥有36把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "混沌初开，天地未分！"
                    )
                ),
                gridRadius: 7,
                initialSwordTypes: Array(repeating: .shen, count: 25),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 45,
                name: "开天辟地",
                subtitle: "⚡ 开天辟地，创世神威",
                targetScore: 16500,
                targetMerges: 118,
                starThresholds: [16500, 24750, 33000],
                formationType: .creation,
                rules: LevelRules(
                    timeLimit: 35,
                    moveLimit: 15,
                    shuffleInterval: 3,
                    ultimatePattern: UltimatePattern(
                        name: "开天辟地阵",
                        description: "达成45连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "开天辟地，创世神威！"
                    )
                ),
                gridRadius: 7,
                initialSwordTypes: Array(repeating: .shen, count: 30),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 46,
                name: "无穷无尽",
                subtitle: "♾️ 无穷无尽，永恒循环",
                targetScore: 17000,
                targetMerges: 120,
                starThresholds: [17000, 25500, 34000],
                formationType: .infinity,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 20,
                    hasBossSword: true,
                    gravityDirection: .outward,
                    ultimatePattern: UltimatePattern(
                        name: "无穷无尽阵",
                        description: "同时拥有39把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "无穷无尽，永恒循环！"
                    )
                ),
                gridRadius: 7,
                initialSwordTypes: Array(repeating: .shen, count: 30),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 47,
                name: "超凡入圣",
                subtitle: "🌟 超凡入圣，脱胎换骨",
                targetScore: 17500,
                targetMerges: 122,
                starThresholds: [17500, 26250, 35000],
                formationType: .transcendence,
                rules: LevelRules(
                    timeLimit: 30,
                    moveLimit: 10,
                    shuffleInterval: 2,
                    ultimatePattern: UltimatePattern(
                        name: "超凡入圣阵",
                        description: "达成50连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "超凡入圣，脱胎换骨！"
                    )
                ),
                gridRadius: 7,
                initialSwordTypes: Array(repeating: .shen, count: 35),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            ),
            Level(
                id: 48,
                name: "神魔乱舞",
                subtitle: "👹 神魔乱舞，天地同寿",
                targetScore: 18000,
                targetMerges: 125,
                starThresholds: [18000, 27000, 36000],
                formationType: .divine,
                rules: LevelRules(
                    hasBlockedCells: true,
                    blockedCellCount: 25,
                    hasBossSword: true,
                    timeLimit: 25,
                    moveLimit: 5,
                    ultimatePattern: UltimatePattern(
                        name: "神魔乱舞终极阵",
                        description: "同时拥有42把神剑在场并达成55连击",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "神魔乱舞，天地同寿！万剑归宗，至高无上！"
                    )
                ),
                gridRadius: 8,
                initialSwordTypes: Array(repeating: .shen, count: 40),
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.0, .shen: 1.0]
            )
        ]
    }
}