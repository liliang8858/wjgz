import Foundation
import SpriteKit

/// 游戏网格实体 - 管理六边形网格的核心逻辑
public final class GameGrid {
    
    // MARK: - Properties
    
    /// 网格数据存储 (q_r -> Sword)
    private var grid: [String: Sword] = [:]
    
    /// 封锁的格子
    private var blockedCells: Set<String> = []
    
    /// 网格配置
    private let config: GridConfiguration
    
    // MARK: - Initialization
    
    public init(config: GridConfiguration) {
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// 获取指定位置的剑
    public func sword(at position: HexPosition) -> Sword? {
        return grid[position.key]
    }
    
    /// 设置指定位置的剑
    public func setSword(_ sword: Sword?, at position: HexPosition) {
        if let sword = sword {
            grid[position.key] = sword
        } else {
            grid.removeValue(forKey: position.key)
        }
    }
    
    /// 检查位置是否有效
    public func isValidPosition(_ position: HexPosition) -> Bool {
        return config.isValidPosition(position)
    }
    
    /// 检查位置是否被封锁
    public func isBlocked(_ position: HexPosition) -> Bool {
        return blockedCells.contains(position.key)
    }
    
    /// 封锁指定位置
    public func blockPosition(_ position: HexPosition) {
        blockedCells.insert(position.key)
    }
    
    /// 解除封锁
    public func unblockPosition(_ position: HexPosition) {
        blockedCells.remove(position.key)
    }
    
    /// 获取所有剑的位置
    public func getAllSwordPositions() -> [HexPosition] {
        return grid.keys.compactMap { HexPosition(key: $0) }
    }
    
    /// 获取所有剑
    public func getAllSwords() -> [Sword] {
        return Array(grid.values)
    }
    
    /// 清空网格
    public func clear() {
        grid.removeAll()
        blockedCells.removeAll()
    }
    
    /// 获取相邻位置
    public func getNeighbors(of position: HexPosition) -> [HexPosition] {
        return HexPosition.getNeighbors(of: position)
    }
    
    /// 检查是否可以放置剑
    public func canPlaceSword(at position: HexPosition) -> Bool {
        return isValidPosition(position) && 
               !isBlocked(position) && 
               sword(at: position) == nil
    }
    
    /// 交换两个位置的剑
    public func swapSwords(from: HexPosition, to: HexPosition) -> Bool {
        guard isValidPosition(from) && isValidPosition(to) else { return false }
        
        let swordFrom = sword(at: from)
        let swordTo = sword(at: to)
        
        setSword(swordTo, at: from)
        setSword(swordFrom, at: to)
        
        return true
    }
}

// MARK: - GridConfiguration

/// 网格配置
public struct GridConfiguration {
    let radius: Int
    let hexSize: CGFloat
    let center: CGPoint
    
    public init(radius: Int, hexSize: CGFloat, center: CGPoint) {
        self.radius = radius
        self.hexSize = hexSize
        self.center = center
    }
    
    /// 检查位置是否在网格范围内
    func isValidPosition(_ position: HexPosition) -> Bool {
        return abs(position.q) <= radius && 
               abs(position.r) <= radius && 
               abs(position.q + position.r) <= radius
    }
}