//
//  NewLevelConfig.swift
//  wjgz
//
//  重新设计的关卡系统 - 挑战失败修为保留，关数打回三关
//

import Foundation
import UIKit

// MARK: - 重新设计的关卡配置
extension LevelConfig {
    
    /// 重新加载优化后的关卡
    func loadOptimizedLevels() {
        levels = [
            // ═══════════════════════════════════════════════════════════════
            // 第一章：新手引导 - 轻松上手，建立信心
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 1,
                name: "初入剑门",
                subtitle: "🌟 轻松入门，感受合成乐趣",
                targetScore: 50,
                targetMerges: 3,
                starThresholds: [50, 80, 120],
                formationType: .hexagon,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "三才归一",
                        description: "在中心及两侧放置三把相同的剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 0, r: 0), Position(q: -1, r: 0), Position(q: 1, r: 0)],
                        swordTypes: [.fan, .fan, .fan],
                        effectDescription: "三剑合一，自动连消三次！"
                    )
                ),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan],
                spawnWeights: [.fan: 1.0]
            ),
            Level(
                id: 2,
                name: "剑意初现",
                subtitle: "🔥 学会连击，体验爽感",
                targetScore: 100,
                targetMerges: 5,
                starThresholds: [100, 150, 200],
                formationType: .hexagon,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "双龙戏珠",
                        description: "同时拥有5把以上的剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "双龙出海，连续消除！"
                    )
                ),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .fan, .fan],
                spawnWeights: [.fan: 0.9, .ling: 0.1]
            ),
            Level(
                id: 3,
                name: "灵剑觉醒",
                subtitle: "⚡ 解锁新剑种，探索变化",
                targetScore: 200,
                targetMerges: 8,
                starThresholds: [200, 300, 400],
                formationType: .diamond,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "灵剑三连",
                        description: "达成3连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "灵剑觉醒，自动连消！"
                    )
                ),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .ling, .ling],
                spawnWeights: [.fan: 0.7, .ling: 0.3]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第二章：基础挑战 - 引入新机制，保持简单
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 4,
                name: "十字剑阵",
                subtitle: "🎯 新阵型挑战，策略升级",
                targetScore: 300,
                targetMerges: 12,
                starThresholds: [300, 450, 600],
                formationType: .cross,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "十字斩",
                        description: "在十字形位置放置4把仙剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 0, r: 0), Position(q: 1, r: 0), Position(q: -1, r: 0), Position(q: 0, r: 1), Position(q: 0, r: -1)],
                        swordTypes: [.xian, .xian, .xian, .xian, .xian],
                        effectDescription: "十字斩破，连续消除！"
                    )
                ),
                gridRadius: 2,
                initialSwordTypes: [.fan, .fan, .ling, .ling],
                spawnWeights: [.fan: 0.6, .ling: 0.4]
            ),
            Level(
                id: 5,
                name: "环形聚气",
                subtitle: "🌀 中空阵型，考验布局",
                targetScore: 400,
                targetMerges: 15,
                starThresholds: [400, 600, 800],
                formationType: .ring,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "聚气环爆",
                        description: "达成5连击",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "聚气成环，自动连消！"
                    )
                ),
                gridRadius: 2,
                initialSwordTypes: [.fan, .ling, .ling],
                spawnWeights: [.fan: 0.5, .ling: 0.45, .xian: 0.05]
            ),
            Level(
                id: 6,
                name: "三才归元",
                subtitle: "🔺 三角阵型，天地人合",
                targetScore: 500,
                targetMerges: 18,
                starThresholds: [500, 750, 1000],
                formationType: .triangle,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "三才合一",
                        description: "达成4连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "三才合一，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.fan, .ling, .ling, .xian],
                spawnWeights: [.fan: 0.4, .ling: 0.5, .xian: 0.1]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第三章：进阶玩法 - 引入限制，增加策略性
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 7,
                name: "七星北斗",
                subtitle: "⭐ 星形阵法，指引方向",
                targetScore: 700,
                targetMerges: 22,
                starThresholds: [700, 1050, 1400],
                formationType: .star,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "北斗七星",
                        description: "同时拥有7把仙剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "北斗七星，自动连消！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.ling, .ling, .xian],
                spawnWeights: [.fan: 0.3, .ling: 0.5, .xian: 0.2]
            ),
            Level(
                id: 8,
                name: "时间考验",
                subtitle: "⏰ 限时挑战，速度与策略",
                targetScore: 800,
                targetMerges: 25,
                starThresholds: [800, 1200, 1600],
                formationType: .spiral,
                rules: LevelRules(
                    timeLimit: 120,
                    ultimatePattern: UltimatePattern(
                        name: "时空斩",
                        description: "在60秒内达成5连击",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "时空斩破，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .xian],
                spawnWeights: [.fan: 0.25, .ling: 0.5, .xian: 0.25]
            ),
            Level(
                id: 9,
                name: "步数限制",
                subtitle: "🎯 精准操作，每步都重要",
                targetScore: 900,
                targetMerges: 28,
                starThresholds: [900, 1350, 1800],
                formationType: .random,
                rules: LevelRules(
                    moveLimit: 35,
                    ultimatePattern: UltimatePattern(
                        name: "精准一击",
                        description: "在20步内完成关卡",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "精准一击，自动连消！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .xian],
                spawnWeights: [.fan: 0.2, .ling: 0.5, .xian: 0.3]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第四章：八卦入门 - 引入传统文化，增加仪式感
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 10,
                name: "乾天刚健",
                subtitle: "☰ 天行健，自强不息",
                targetScore: 1200,
                targetMerges: 30,
                starThresholds: [1200, 1800, 2400],
                formationType: .qian,
                rules: LevelRules(
                    ultimatePattern: UltimatePattern(
                        name: "乾坤大挪移",
                        description: "在八个方向各放置一把神剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 1, r: 0), Position(q: 1, r: -1), Position(q: 0, r: -1), Position(q: -1, r: 0), Position(q: -1, r: 1), Position(q: 0, r: 1), Position(q: 1, r: 1), Position(q: -1, r: -1)],
                        swordTypes: [.shen, .shen, .shen, .shen, .shen, .shen, .shen, .shen],
                        effectDescription: "乾坤大挪移，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.ling, .xian, .xian],
                spawnWeights: [.fan: 0.15, .ling: 0.45, .xian: 0.35, .shen: 0.05]
            ),
            Level(
                id: 11,
                name: "坤地厚德",
                subtitle: "☷ 地势坤，厚德载物",
                targetScore: 1400,
                targetMerges: 32,
                starThresholds: [1400, 2100, 2800],
                formationType: .kun,
                rules: LevelRules(
                    hasBlockedCells: true, 
                    blockedCellCount: 1,
                    ultimatePattern: UltimatePattern(
                        name: "厚德载物",
                        description: "同时拥有6把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "厚德载物，自动连消！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.xian, .xian, .shen],
                spawnWeights: [.fan: 0.1, .ling: 0.4, .xian: 0.4, .shen: 0.1]
            ),
            Level(
                id: 12,
                name: "震雷奋发",
                subtitle: "☳ 震惊百里，雷动九天",
                targetScore: 1600,
                targetMerges: 35,
                starThresholds: [1600, 2400, 3200],
                formationType: .zhen,
                rules: LevelRules(
                    gravityDirection: .down,
                    ultimatePattern: UltimatePattern(
                        name: "雷动九天",
                        description: "达成6连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "雷动九天，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.xian, .xian, .shen],
                spawnWeights: [.fan: 0.1, .ling: 0.35, .xian: 0.4, .shen: 0.15]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第五章：八卦进阶 - 组合机制，增加复杂度
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 13,
                name: "巽风无孔",
                subtitle: "☴ 随风巽，无孔不入",
                targetScore: 1800,
                targetMerges: 38,
                starThresholds: [1800, 2700, 3600],
                formationType: .xun,
                rules: LevelRules(
                    shuffleInterval: 30,
                    ultimatePattern: UltimatePattern(
                        name: "无孔不入",
                        description: "在洗牌后立即达成合成",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "无孔不入，自动连消！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.xian, .shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.3, .xian: 0.45, .shen: 0.2]
            ),
            Level(
                id: 14,
                name: "坎水险阻",
                subtitle: "☵ 习坎，险中求胜",
                targetScore: 2000,
                targetMerges: 40,
                starThresholds: [2000, 3000, 4000],
                formationType: .kan,
                rules: LevelRules(
                    hasBlockedCells: true, 
                    blockedCellCount: 2, 
                    timeLimit: 100,
                    ultimatePattern: UltimatePattern(
                        name: "险中求胜",
                        description: "在时间剩余30秒时达成合成",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "险中求胜，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.xian, .shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.25, .xian: 0.45, .shen: 0.25]
            ),
            Level(
                id: 15,
                name: "离火光明",
                subtitle: "☲ 离火照耀，光明磊落",
                targetScore: 2200,
                targetMerges: 42,
                starThresholds: [2200, 3300, 4400],
                formationType: .li,
                rules: LevelRules(
                    moveLimit: 40,
                    ultimatePattern: UltimatePattern(
                        name: "光明磊落",
                        description: "在15步内达成7连击",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "光明磊落，自动连消！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen],
                spawnWeights: [.fan: 0.05, .ling: 0.2, .xian: 0.45, .shen: 0.3]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第六章：高级挑战 - 多重限制，考验综合能力
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 16,
                name: "艮山静止",
                subtitle: "☶ 艮为山，静止不动",
                targetScore: 2500,
                targetMerges: 45,
                starThresholds: [2500, 3750, 5000],
                formationType: .gen,
                rules: LevelRules(
                    hasBlockedCells: true, 
                    blockedCellCount: 2, 
                    moveLimit: 35,
                    ultimatePattern: UltimatePattern(
                        name: "静止不动",
                        description: "同时拥有8把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "静止不动，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.15, .xian: 0.5, .shen: 0.35]
            ),
            Level(
                id: 17,
                name: "兑泽和悦",
                subtitle: "☱ 兑为泽，和悦相济",
                targetScore: 2800,
                targetMerges: 48,
                starThresholds: [2800, 4200, 5600],
                formationType: .dui,
                rules: LevelRules(
                    timeLimit: 90, 
                    shuffleInterval: 25,
                    ultimatePattern: UltimatePattern(
                        name: "和悦相济",
                        description: "在洗牌干扰下达成8连击",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "和悦相济，自动连消！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.1, .xian: 0.5, .shen: 0.4]
            ),
            Level(
                id: 18,
                name: "八卦归一",
                subtitle: "☯ 八卦合璧，万法归宗",
                targetScore: 3200,
                targetMerges: 50,
                starThresholds: [3200, 4800, 6400],
                formationType: .bagua,
                rules: LevelRules(
                    hasBlockedCells: true, 
                    blockedCellCount: 3,
                    ultimatePattern: UltimatePattern(
                        name: "八卦归一阵",
                        description: "同时拥有8把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "八卦归一，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.1, .xian: 0.4, .shen: 0.5]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第七章：终极试炼 - 最高难度，但仍可通过
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 19,
                name: "五行相生",
                subtitle: "🌟 金木水火土，循环不息",
                targetScore: 3600,
                targetMerges: 52,
                starThresholds: [3600, 5400, 7200],
                formationType: .wuxing,
                rules: LevelRules(
                    timeLimit: 80, 
                    moveLimit: 45,
                    ultimatePattern: UltimatePattern(
                        name: "五行相生",
                        description: "在五个不同位置各放置一把神剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 0, r: 0), Position(q: 1, r: 0), Position(q: 0, r: 1), Position(q: -1, r: 0), Position(q: 0, r: -1)],
                        swordTypes: [.shen, .shen, .shen, .shen, .shen],
                        effectDescription: "五行相生，自动连消！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.05, .xian: 0.4, .shen: 0.55]
            ),
            Level(
                id: 20,
                name: "九宫飞星",
                subtitle: "✨ 九宫变化，星移斗转",
                targetScore: 4000,
                targetMerges: 55,
                starThresholds: [4000, 6000, 8000],
                formationType: .jiugong,
                rules: LevelRules(
                    hasBlockedCells: true, 
                    blockedCellCount: 3, 
                    shuffleInterval: 20,
                    ultimatePattern: UltimatePattern(
                        name: "九宫飞星",
                        description: "在九个位置各放置一把神剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 0, r: 0), Position(q: 1, r: 0), Position(q: 1, r: -1), Position(q: 0, r: -1), Position(q: -1, r: 0), Position(q: -1, r: 1), Position(q: 0, r: 1), Position(q: 2, r: -1), Position(q: -1, r: -1)],
                        swordTypes: Array(repeating: .shen, count: 9),
                        effectDescription: "九宫飞星，连续消除！"
                    )
                ),
                gridRadius: 3,
                initialSwordTypes: [.shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.05, .xian: 0.35, .shen: 0.6]
            ),
            Level(
                id: 21,
                name: "天罡北斗",
                subtitle: "🌌 三十六天罡，镇压四方",
                targetScore: 4500,
                targetMerges: 58,
                starThresholds: [4500, 6750, 9000],
                formationType: .tiangang,
                rules: LevelRules(
                    hasBossSword: true, 
                    timeLimit: 75,
                    ultimatePattern: UltimatePattern(
                        name: "天罡北斗",
                        description: "同时拥有10把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "天罡北斗，自动连消！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.3, .shen: 0.7]
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // 第八章：万剑归宗 - 终极挑战，但给予足够资源
            // ═══════════════════════════════════════════════════════════════
            Level(
                id: 22,
                name: "剑道至尊",
                subtitle: "⚔️ 剑意通天，道法自然",
                targetScore: 5000,
                targetMerges: 60,
                starThresholds: [5000, 7500, 10000],
                formationType: .bagua,
                rules: LevelRules(
                    moveLimit: 50, 
                    gravityDirection: .center,
                    ultimatePattern: UltimatePattern(
                        name: "剑道至尊",
                        description: "达成10连击以上",
                        triggerCondition: .comboCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "剑道至尊，连续消除！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.25, .shen: 0.75]
            ),
            Level(
                id: 23,
                name: "飞升在即",
                subtitle: "🌟 修为圆满，即将飞升",
                targetScore: 5500,
                targetMerges: 62,
                starThresholds: [5500, 8250, 11000],
                formationType: .tiangang,
                rules: LevelRules(
                    hasBossSword: true, 
                    timeLimit: 70, 
                    moveLimit: 45,
                    ultimatePattern: UltimatePattern(
                        name: "飞升在即",
                        description: "同时拥有12把神剑在场",
                        triggerCondition: .swordTypeCount,
                        positions: [],
                        swordTypes: [],
                        effectDescription: "飞升在即，自动连消！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.2, .shen: 0.8]
            ),
            Level(
                id: 24,
                name: "万剑归宗",
                subtitle: "🏆 万法归一，剑道圆满",
                targetScore: 6000,
                targetMerges: 65,
                starThresholds: [6000, 9000, 12000],
                formationType: .bagua,
                rules: LevelRules(
                    hasBossSword: true, 
                    timeLimit: 90, 
                    moveLimit: 60,
                    ultimatePattern: UltimatePattern(
                        name: "万剑归宗大阵",
                        description: "在所有位置都放置神剑",
                        triggerCondition: .specificPattern,
                        positions: [Position(q: 0, r: 0), Position(q: 1, r: 0), Position(q: 1, r: -1), Position(q: 0, r: -1), Position(q: -1, r: 0), Position(q: -1, r: 1), Position(q: 0, r: 1), Position(q: 2, r: 0), Position(q: 2, r: -1), Position(q: 2, r: -2), Position(q: 1, r: -2), Position(q: 0, r: -2), Position(q: -1, r: -1), Position(q: -2, r: 0), Position(q: -2, r: 1), Position(q: -2, r: 2), Position(q: -1, r: 2), Position(q: 0, r: 2), Position(q: 1, r: 1)],
                        swordTypes: Array(repeating: .shen, count: 19),
                        effectDescription: "万剑归宗！自动连消三次！"
                    )
                ),
                gridRadius: 4,
                initialSwordTypes: [.shen, .shen, .shen, .shen, .shen, .shen],
                spawnWeights: [.fan: 0.0, .ling: 0.0, .xian: 0.15, .shen: 0.85]
            ),
        ]
    }
}

// MARK: - 关卡设计原则说明
/*
 🎯 关卡设计原则：
 
 1. 渐进式难度：
    - 前3关：纯新手引导，必定能过
    - 4-9关：基础挑战，引入新机制
    - 10-18关：八卦系统，文化内涵
    - 19-24关：终极挑战，但仍可通过
 
 2. 多巴胺设计：
    - 每关都有新元素（新阵型、新规则、新剑种）
    - 即时反馈（分数、星级、修为）
    - 成就感递增（称号系统）
    - 失败不惩罚（修为保留）
 
 3. 可通过性保证：
    - 所有关卡都经过平衡测试
    - 给予足够的初始资源
    - 限制条件合理（时间/步数不过分）
    - 失败后退3关，降低挫败感
 
 4. 探索欲维持：
    - 每关都有独特的副标题和文化内涵
    - 阵型变化带来视觉新鲜感
    - 规则组合创造策略深度
    - 修为系统提供长期目标
 
 5. 即时反馈机制：
    - 每次合成都有音效和特效
    - 连击系统提供爽感
    - 分数实时显示
    - 星级评价即时反馈
    - 修为增长可视化
 */