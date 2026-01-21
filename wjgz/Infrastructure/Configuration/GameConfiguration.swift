import Foundation
import CoreGraphics
import UIKit

/// 游戏配置协议
public protocol GameConfigurationProtocol {
    
    // MARK: - Grid Configuration
    var gridRadius: Int { get }
    var hexSize: CGFloat { get }
    var gridCenter: CGPoint { get }
    
    // MARK: - Game Rules
    var defaultMinMatchCount: Int { get }
    var maxEnergy: CGFloat { get }
    var energyPerMatch: CGFloat { get }
    
    // MARK: - Animation Timings
    var swordMoveAnimationDuration: TimeInterval { get }
    var mergeAnimationDuration: TimeInterval { get }
    var comboDelayDuration: TimeInterval { get }
    var replenishAnimationDuration: TimeInterval { get }
    
    // MARK: - Audio Settings
    var defaultMasterVolume: Float { get }
    var defaultMusicVolume: Float { get }
    var defaultSFXVolume: Float { get }
    
    // MARK: - Effects Settings
    var defaultEffectsIntensity: Float { get }
    var particleMaxCount: Int { get }
    
    // MARK: - Performance Settings
    var targetFPS: Int { get }
    var enableVSync: Bool { get }
    var maxConcurrentAnimations: Int { get }
    
    // MARK: - Debug Settings
    var isDebugMode: Bool { get }
    var showFPS: Bool { get }
    var showGridCoordinates: Bool { get }
    var enablePerformanceMetrics: Bool { get }
}

/// 游戏配置实现
public final class GameConfiguration: GameConfigurationProtocol {
    
    // MARK: - Singleton
    
    public static let shared = GameConfiguration()
    
    // MARK: - Grid Configuration
    
    public let gridRadius: Int = 3
    public let hexSize: CGFloat = 40.0
    public let gridCenter: CGPoint = CGPoint(x: 0, y: 0)
    
    // MARK: - Game Rules
    
    public let defaultMinMatchCount: Int = 3
    public let maxEnergy: CGFloat = 100.0
    public let energyPerMatch: CGFloat = 5.0
    
    // MARK: - Animation Timings
    
    public let swordMoveAnimationDuration: TimeInterval = 0.3
    public let mergeAnimationDuration: TimeInterval = 0.5
    public let comboDelayDuration: TimeInterval = 0.3
    public let replenishAnimationDuration: TimeInterval = 0.4
    
    // MARK: - Audio Settings
    
    public let defaultMasterVolume: Float = 0.8
    public let defaultMusicVolume: Float = 0.6
    public let defaultSFXVolume: Float = 0.8
    
    // MARK: - Effects Settings
    
    public let defaultEffectsIntensity: Float = 0.8
    public let particleMaxCount: Int = 1000
    
    // MARK: - Performance Settings
    
    public let targetFPS: Int = 60
    public let enableVSync: Bool = true
    public let maxConcurrentAnimations: Int = 20
    
    // MARK: - Debug Settings
    
    #if DEBUG
    public let isDebugMode: Bool = true
    public let showFPS: Bool = false
    public let showGridCoordinates: Bool = false
    public let enablePerformanceMetrics: Bool = true
    #else
    public let isDebugMode: Bool = false
    public let showFPS: Bool = false
    public let showGridCoordinates: Bool = false
    public let enablePerformanceMetrics: Bool = false
    #endif
    
    // MARK: - Initialization
    
    public init() {}
}

// MARK: - Game Constants

/// 游戏常量
public struct GameConstants {
    
    // MARK: - Sword Types
    
    public static let swordTypeCount = 4
    public static let maxSwordLevel = 4
    
    // MARK: - Score Multipliers
    
    public static let baseScorePerSword = 10
    public static let comboMultiplierBase = 1.2
    public static let perfectMatchBonus = 2.0
    
    // MARK: - Level Progression
    
    public static let totalLevels = 48
    public static let chaptersCount = 12
    public static let levelsPerChapter = 4
    
    // MARK: - Star Requirements
    
    public static let oneStarThreshold = 0.3  // 30% of target score
    public static let twoStarThreshold = 0.7  // 70% of target score
    public static let threeStarThreshold = 1.0 // 100% of target score
    
    // MARK: - Cultivation System
    
    public static let cultivationLevels = 10
    public static let baseCultivationPerLevel = 10
    public static let starBonusPerStar = 5
    public static let scoreBonusDivisor = 100
    
    // MARK: - Ultimate Skills
    
    public static let ultimateEnergyRequirement: CGFloat = 100.0
    public static let ultimateSkillCooldown: TimeInterval = 5.0
    
    // MARK: - Combo System
    
    public static let comboTimeWindow: TimeInterval = 3.0
    public static let maxComboCount = 99
    public static let comboScoreMultiplier = 0.1
    
    // MARK: - Grid Limits
    
    public static let minGridRadius = 2
    public static let maxGridRadius = 5
    public static let defaultGridRadius = 3
    
    // MARK: - Animation Constants
    
    public static let defaultAnimationDuration: TimeInterval = 0.3
    public static let fastAnimationDuration: TimeInterval = 0.15
    public static let slowAnimationDuration: TimeInterval = 0.6
    
    // MARK: - Effect Constants
    
    public static let screenShakeDuration: TimeInterval = 0.2
    public static let flashEffectDuration: TimeInterval = 0.1
    public static let slowMotionScale: Float = 0.3
    
    // MARK: - Audio Constants
    
    public static let fadeInDuration: TimeInterval = 1.0
    public static let fadeOutDuration: TimeInterval = 0.5
    public static let maxSimultaneousSounds = 8
    
    // MARK: - Performance Constants
    
    public static let maxParticlesPerEffect = 50
    public static let particleLifetime: TimeInterval = 2.0
    public static let memoryWarningThreshold = 100 * 1024 * 1024 // 100MB
}

// MARK: - Device Configuration

/// 设备相关配置
public struct DeviceConfiguration {
    
    // MARK: - Screen Properties
    
    public static var screenScale: CGFloat {
        return UIScreen.main.scale
    }
    
    public static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    public static var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public static var isIPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Performance Tier
    
    public enum PerformanceTier {
        case low
        case medium
        case high
        case ultra
    }
    
    public static var performanceTier: PerformanceTier {
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        if processorCount >= 8 && physicalMemory >= 6 * 1024 * 1024 * 1024 {
            return .ultra
        } else if processorCount >= 6 && physicalMemory >= 4 * 1024 * 1024 * 1024 {
            return .high
        } else if processorCount >= 4 && physicalMemory >= 2 * 1024 * 1024 * 1024 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Adaptive Settings
    
    public static var adaptiveParticleCount: Int {
        switch performanceTier {
        case .ultra: return 1000
        case .high: return 750
        case .medium: return 500
        case .low: return 250
        }
    }
    
    public static var adaptiveEffectsIntensity: Float {
        switch performanceTier {
        case .ultra: return 1.0
        case .high: return 0.8
        case .medium: return 0.6
        case .low: return 0.4
        }
    }
    
    public static var adaptiveAnimationDuration: TimeInterval {
        switch performanceTier {
        case .ultra, .high: return 0.3
        case .medium: return 0.25
        case .low: return 0.2
        }
    }
}