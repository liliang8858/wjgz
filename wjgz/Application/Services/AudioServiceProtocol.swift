import Foundation

/// 音效服务协议
public protocol AudioServiceProtocol {
    
    // MARK: - Background Music
    
    /// 播放背景音乐
    func playBackgroundMusic()
    
    /// 暂停背景音乐
    func pauseBackgroundMusic()
    
    /// 恢复背景音乐
    func resumeBackgroundMusic()
    
    /// 停止背景音乐
    func stopBackgroundMusic()
    
    /// 设置背景音乐音量
    func setBackgroundMusicVolume(_ volume: Float)
    
    // MARK: - Sound Effects
    
    /// 播放音效
    func playSound(_ soundType: SoundType)
    
    /// 播放音效（带音量控制）
    func playSound(_ soundType: SoundType, volume: Float)
    
    /// 设置音效音量
    func setSoundEffectsVolume(_ volume: Float)
    
    // MARK: - Settings
    
    /// 是否启用音效
    var isSoundEnabled: Bool { get set }
    
    /// 是否启用背景音乐
    var isMusicEnabled: Bool { get set }
    
    /// 主音量
    var masterVolume: Float { get set }
}

/// 音效类型枚举
public enum SoundType: String, CaseIterable {
    
    // MARK: - UI Sounds
    case tap = "tap"
    case select = "select"
    case button = "button"
    case error = "error"
    
    // MARK: - Game Sounds
    case drag = "drag"
    case drop = "drop"
    case shuffle = "shuffle"
    
    // MARK: - Merge Sounds
    case mergeFan = "merge_fan"
    case mergeLing = "merge_ling"
    case mergeXian = "merge_xian"
    case mergeShen = "merge_shen"
    
    // MARK: - Combo Sounds
    case combo1 = "combo_1"
    case combo2 = "combo_2"
    case combo3 = "combo_3"
    
    // MARK: - Special Effects
    case chainClear = "chain_clear"
    case explosion = "explosion"
    case levelUp = "level_up"
    case ultimate = "ultimate"
    case levelComplete = "level_complete"
    case gameOver = "game_over"
    
    // MARK: - Properties
    
    /// 音效文件名
    public var fileName: String {
        return rawValue
    }
    
    /// 音效文件扩展名
    public var fileExtension: String {
        return "mp3"
    }
    
    /// 完整文件名
    public var fullFileName: String {
        return "\(fileName).\(fileExtension)"
    }
    
    /// 系统音效ID（备用）
    public var systemSoundID: UInt32? {
        switch self {
        case .tap, .select, .button:
            return 1104 // 点击音
        case .error:
            return 1053 // 错误音
        case .levelComplete:
            return 1054 // 成功音
        case .drop:
            return 1105 // 选择音
        default:
            return nil
        }
    }
}