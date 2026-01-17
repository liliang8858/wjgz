import Foundation
import CoreGraphics

/// 六边形坐标位置值对象
public struct HexPosition: Hashable, Equatable {
    
    // MARK: - Properties
    
    /// 轴向坐标 q
    public let q: Int
    
    /// 轴向坐标 r
    public let r: Int
    
    /// 计算得出的 s 坐标 (q + r + s = 0)
    public var s: Int {
        return -q - r
    }
    
    /// 用于字典键的字符串表示
    public var key: String {
        return "\(q)_\(r)"
    }
    
    // MARK: - Initialization
    
    public init(q: Int, r: Int) {
        self.q = q
        self.r = r
    }
    
    /// 从字符串键创建位置
    public init?(key: String) {
        let components = key.split(separator: "_")
        guard components.count == 2,
              let q = Int(components[0]),
              let r = Int(components[1]) else {
            return nil
        }
        self.q = q
        self.r = r
    }
    
    // MARK: - Coordinate Conversion
    
    /// 转换为屏幕坐标
    public func toPixel(hexSize: CGFloat, center: CGPoint) -> CGPoint {
        let x = hexSize * (3.0/2.0 * CGFloat(q))
        let y = hexSize * (sqrt(3.0)/2.0 * CGFloat(q) + sqrt(3.0) * CGFloat(r))
        return CGPoint(x: center.x + x, y: center.y + y)
    }
    
    /// 从屏幕坐标创建六边形位置
    public static func fromPixel(point: CGPoint, hexSize: CGFloat, center: CGPoint) -> HexPosition {
        let relativePoint = CGPoint(x: point.x - center.x, y: point.y - center.y)
        
        let q = (2.0/3.0 * relativePoint.x) / hexSize
        let r = (-1.0/3.0 * relativePoint.x + sqrt(3.0)/3.0 * relativePoint.y) / hexSize
        
        return HexPosition.round(q: q, r: r)
    }
    
    /// 浮点坐标四舍五入
    public static func round(q: CGFloat, r: CGFloat) -> HexPosition {
        let s = -q - r
        
        var rq = q.rounded()
        var rr = r.rounded()
        let rs = s.rounded()
        
        let qDiff = abs(rq - q)
        let rDiff = abs(rr - r)
        let sDiff = abs(rs - s)
        
        if qDiff > rDiff && qDiff > sDiff {
            rq = -rr - rs
        } else if rDiff > sDiff {
            rr = -rq - rs
        }
        
        return HexPosition(q: Int(rq), r: Int(rr))
    }
    
    // MARK: - Neighbor Operations
    
    /// 六边形的6个方向向量
    private static let directions: [HexPosition] = [
        HexPosition(q: 1, r: 0),   // 右
        HexPosition(q: 1, r: -1),  // 右上
        HexPosition(q: 0, r: -1),  // 左上
        HexPosition(q: -1, r: 0),  // 左
        HexPosition(q: -1, r: 1),  // 左下
        HexPosition(q: 0, r: 1)    // 右下
    ]
    
    /// 获取相邻的6个位置
    public static func getNeighbors(of position: HexPosition) -> [HexPosition] {
        return directions.map { direction in
            HexPosition(q: position.q + direction.q, r: position.r + direction.r)
        }
    }
    
    /// 获取指定方向的邻居
    public func neighbor(in direction: Int) -> HexPosition {
        guard direction >= 0 && direction < 6 else {
            return self
        }
        let dir = HexPosition.directions[direction]
        return HexPosition(q: q + dir.q, r: r + dir.r)
    }
    
    // MARK: - Distance
    
    /// 计算到另一个位置的距离
    public func distance(to other: HexPosition) -> Int {
        return (abs(q - other.q) + abs(q + r - other.q - other.r) + abs(r - other.r)) / 2
    }
    
    // MARK: - Hashable & Equatable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(q)
        hasher.combine(r)
    }
    
    public static func == (lhs: HexPosition, rhs: HexPosition) -> Bool {
        return lhs.q == rhs.q && lhs.r == rhs.r
    }
}

// MARK: - Extensions

extension HexPosition: CustomStringConvertible {
    public var description: String {
        return "HexPosition(q: \(q), r: \(r), s: \(s))"
    }
}