import Foundation

/// 匹配引擎 - 负责检测和处理剑的匹配逻辑
public final class MatchEngine {
    
    // MARK: - Types
    
    /// 匹配结果
    public struct MatchResult {
        let matches: [MatchGroup]
        let hasMatches: Bool
        
        public init(matches: [MatchGroup]) {
            self.matches = matches
            self.hasMatches = !matches.isEmpty
        }
    }
    
    /// 匹配组
    public struct MatchGroup {
        let swords: [Sword]
        let positions: [HexPosition]
        let swordType: SwordType
        let centerPosition: HexPosition
        
        public init(swords: [Sword], positions: [HexPosition], swordType: SwordType, centerPosition: HexPosition) {
            self.swords = swords
            self.positions = positions
            self.swordType = swordType
            self.centerPosition = centerPosition
        }
    }
    
    // MARK: - Properties
    
    private let gameGrid: GameGrid
    private let minMatchCount: Int
    
    // MARK: - Initialization
    
    public init(gameGrid: GameGrid, minMatchCount: Int = 3) {
        self.gameGrid = gameGrid
        self.minMatchCount = minMatchCount
    }
    
    // MARK: - Public Methods
    
    /// 检测所有匹配
    public func findAllMatches() -> MatchResult {
        var allMatches: [MatchGroup] = []
        var processedPositions: Set<HexPosition> = []
        
        for position in gameGrid.getAllSwordPositions() {
            if processedPositions.contains(position) { continue }
            
            guard let sword = gameGrid.sword(at: position) else { continue }
            
            let matchGroup = findMatchGroup(startingFrom: position, swordType: sword.type)
            
            if matchGroup.swords.count >= minMatchCount {
                allMatches.append(matchGroup)
                processedPositions.formUnion(matchGroup.positions)
            }
        }
        
        return MatchResult(matches: allMatches)
    }
    
    /// 检测指定位置开始的匹配
    public func findMatchesFrom(position: HexPosition) -> MatchResult {
        guard let sword = gameGrid.sword(at: position) else {
            return MatchResult(matches: [])
        }
        
        let matchGroup = findMatchGroup(startingFrom: position, swordType: sword.type)
        
        if matchGroup.swords.count >= minMatchCount {
            return MatchResult(matches: [matchGroup])
        } else {
            return MatchResult(matches: [])
        }
    }
    
    /// 检查是否还有可能的匹配
    public func hasPossibleMatches() -> Bool {
        let allPositions = gameGrid.getAllSwordPositions()
        
        for position in allPositions {
            guard let sword = gameGrid.sword(at: position) else { continue }
            
            // 检查相邻位置是否有相同类型的剑
            let neighbors = gameGrid.getNeighbors(of: position)
            let sameTypeNeighbors = neighbors.compactMap { neighborPos in
                gameGrid.sword(at: neighborPos)
            }.filter { $0.type == sword.type }
            
            if sameTypeNeighbors.count >= minMatchCount - 1 {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    /// 使用BFS算法找到匹配组
    private func findMatchGroup(startingFrom startPosition: HexPosition, swordType: SwordType) -> MatchGroup {
        var visited: Set<HexPosition> = []
        var queue: [HexPosition] = [startPosition]
        var matchedSwords: [Sword] = []
        var matchedPositions: [HexPosition] = []
        
        while !queue.isEmpty {
            let currentPosition = queue.removeFirst()
            
            if visited.contains(currentPosition) { continue }
            visited.insert(currentPosition)
            
            guard let sword = gameGrid.sword(at: currentPosition),
                  sword.type == swordType else { continue }
            
            matchedSwords.append(sword)
            matchedPositions.append(currentPosition)
            
            // 添加相邻的相同类型剑到队列
            let neighbors = gameGrid.getNeighbors(of: currentPosition)
            for neighborPosition in neighbors {
                if !visited.contains(neighborPosition),
                   let neighborSword = gameGrid.sword(at: neighborPosition),
                   neighborSword.type == swordType {
                    queue.append(neighborPosition)
                }
            }
        }
        
        return MatchGroup(
            swords: matchedSwords,
            positions: matchedPositions,
            swordType: swordType,
            centerPosition: calculateCenterPosition(positions: matchedPositions)
        )
    }
    
    /// 计算匹配组的中心位置
    private func calculateCenterPosition(positions: [HexPosition]) -> HexPosition {
        guard !positions.isEmpty else { return HexPosition(q: 0, r: 0) }
        
        let totalQ = positions.reduce(0) { $0 + $1.q }
        let totalR = positions.reduce(0) { $0 + $1.r }
        
        let avgQ = CGFloat(totalQ) / CGFloat(positions.count)
        let avgR = CGFloat(totalR) / CGFloat(positions.count)
        
        return HexPosition.round(q: avgQ, r: avgR)
    }
}

// MARK: - Extensions

extension MatchEngine.MatchGroup {
    /// 获取升级后的剑类型
    public var upgradedSwordType: SwordType? {
        return swordType.upgraded
    }
    
    /// 是否触发特殊效果
    public var triggersSpecialEffect: Bool {
        switch swordType {
        case .ling, .xian, .shen:
            return true
        case .fan:
            return false
        }
    }
}