import Foundation

/// 存储服务协议
public protocol StorageServiceProtocol {
    
    // MARK: - Basic Operations
    
    /// 保存数据
    func save<T: Codable>(_ value: T, forKey key: String)
    
    /// 读取数据
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    
    /// 删除数据
    func remove(forKey key: String)
    
    /// 检查键是否存在
    func exists(forKey key: String) -> Bool
    
    /// 清除所有数据
    func clearAll()
    
    // MARK: - Batch Operations
    
    /// 批量保存
    func saveBatch(_ values: [String: Any])
    
    /// 批量读取
    func loadBatch(keys: [String]) -> [String: Any]
    
    /// 批量删除
    func removeBatch(keys: [String])
    
    // MARK: - Synchronization
    
    /// 同步到云端（如果支持）
    func synchronize() async throws
    
    /// 从云端恢复（如果支持）
    func restore() async throws
}

/// UserDefaults 存储服务实现
public final class UserDefaultsStorageService: StorageServiceProtocol {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Basic Operations
    
    public func save<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save \(key): \(error)")
        }
    }
    
    public func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Failed to load \(key): \(error)")
            return nil
        }
    }
    
    public func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    public func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
    
    public func clearAll() {
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
    }
    
    // MARK: - Batch Operations
    
    public func saveBatch(_ values: [String: Any]) {
        for (key, value) in values {
            userDefaults.set(value, forKey: key)
        }
    }
    
    public func loadBatch(keys: [String]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for key in keys {
            if let value = userDefaults.object(forKey: key) {
                result[key] = value
            }
        }
        
        return result
    }
    
    public func removeBatch(keys: [String]) {
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    // MARK: - Synchronization
    
    public func synchronize() async throws {
        // UserDefaults 不支持云同步，这里可以实现 iCloud 或其他云服务
        userDefaults.synchronize()
    }
    
    public func restore() async throws {
        // 从云端恢复数据的实现
        // 这里可以添加 iCloud 或其他云服务的恢复逻辑
    }
}

// MARK: - Storage Keys

/// 存储键常量
public struct StorageKeys {
    
    // MARK: - Game State
    public static let gameState = "game_state"
    public static let currentLevel = "current_level"
    public static let unlockedLevels = "unlocked_levels"
    public static let cultivation = "cultivation"
    public static let totalScore = "total_score"
    
    // MARK: - Level Progress
    public static let levelScores = "level_scores"
    public static let levelStars = "level_stars"
    public static let levelBestTimes = "level_best_times"
    public static let levelBestMoves = "level_best_moves"
    
    // MARK: - Statistics
    public static let totalPlayTime = "total_play_time"
    public static let totalMatches = "total_matches"
    public static let totalCombos = "total_combos"
    public static let maxCombo = "max_combo"
    public static let ultimateCount = "ultimate_count"
    
    // MARK: - Achievements
    public static let achievements = "achievements"
    public static let achievementProgress = "achievement_progress"
    
    // MARK: - Settings
    public static let audioSettings = "audio_settings"
    public static let effectsSettings = "effects_settings"
    public static let gameSettings = "game_settings"
    
    // MARK: - Tutorial
    public static let tutorialCompleted = "tutorial_completed"
    public static let tutorialSteps = "tutorial_steps"
    
    // MARK: - Analytics
    public static let sessionCount = "session_count"
    public static let lastPlayDate = "last_play_date"
    public static let installDate = "install_date"
}

// MARK: - Codable Models

/// 游戏状态数据模型
public struct GameStateData: Codable {
    let currentLevel: Int
    let cultivation: Int
    let unlockedLevels: Set<Int>
    let totalScore: Int
    let ultimateCount: Int
    let maxCombo: Int
    let tutorialCompleted: Bool
    let achievements: [String: Bool]
    let achievementProgress: [String: Int]
    
    public init(
        currentLevel: Int = 1,
        cultivation: Int = 0,
        unlockedLevels: Set<Int> = [1],
        totalScore: Int = 0,
        ultimateCount: Int = 0,
        maxCombo: Int = 0,
        tutorialCompleted: Bool = false,
        achievements: [String: Bool] = [:],
        achievementProgress: [String: Int] = [:]
    ) {
        self.currentLevel = currentLevel
        self.cultivation = cultivation
        self.unlockedLevels = unlockedLevels
        self.totalScore = totalScore
        self.ultimateCount = ultimateCount
        self.maxCombo = maxCombo
        self.tutorialCompleted = tutorialCompleted
        self.achievements = achievements
        self.achievementProgress = achievementProgress
    }
}

/// 关卡进度数据模型
public struct LevelProgressData: Codable {
    let levelID: Int
    let bestScore: Int
    let stars: Int
    let bestTime: TimeInterval?
    let bestMoves: Int?
    let completionCount: Int
    let firstCompletionDate: Date
    let lastCompletionDate: Date
    
    public init(
        levelID: Int,
        bestScore: Int = 0,
        stars: Int = 0,
        bestTime: TimeInterval? = nil,
        bestMoves: Int? = nil,
        completionCount: Int = 0,
        firstCompletionDate: Date = Date(),
        lastCompletionDate: Date = Date()
    ) {
        self.levelID = levelID
        self.bestScore = bestScore
        self.stars = stars
        self.bestTime = bestTime
        self.bestMoves = bestMoves
        self.completionCount = completionCount
        self.firstCompletionDate = firstCompletionDate
        self.lastCompletionDate = lastCompletionDate
    }
}

/// 设置数据模型
public struct SettingsData: Codable {
    let masterVolume: Float
    let musicVolume: Float
    let sfxVolume: Float
    let effectsIntensity: Float
    let isSoundEnabled: Bool
    let isMusicEnabled: Bool
    let isEffectsEnabled: Bool
    let isHapticsEnabled: Bool
    
    public init(
        masterVolume: Float = 0.8,
        musicVolume: Float = 0.6,
        sfxVolume: Float = 0.8,
        effectsIntensity: Float = 0.8,
        isSoundEnabled: Bool = true,
        isMusicEnabled: Bool = true,
        isEffectsEnabled: Bool = true,
        isHapticsEnabled: Bool = true
    ) {
        self.masterVolume = masterVolume
        self.musicVolume = musicVolume
        self.sfxVolume = sfxVolume
        self.effectsIntensity = effectsIntensity
        self.isSoundEnabled = isSoundEnabled
        self.isMusicEnabled = isMusicEnabled
        self.isEffectsEnabled = isEffectsEnabled
        self.isHapticsEnabled = isHapticsEnabled
    }
}