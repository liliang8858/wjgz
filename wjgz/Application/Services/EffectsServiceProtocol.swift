import Foundation
import CoreGraphics

/// 特效服务协议
public protocol EffectsServiceProtocol {
    
    // MARK: - Micro Effects (微特效)
    
    /// 播放点击涟漪效果
    func playTapRipple(at position: CGPoint)
    
    /// 播放选中脉冲效果
    func playSelectPulse(at position: CGPoint)
    
    /// 播放拖拽轨迹效果
    func playDragTrail(from: CGPoint, to: CGPoint)
    
    // MARK: - Small Effects (小特效)
    
    /// 播放合成爆发效果
    func playMergeBurst(at position: HexPosition, intensity: EffectIntensity)
    
    /// 播放分数飘字效果
    func playScorePopup(score: Int, at position: CGPoint, style: ScoreStyle)
    
    /// 播放反馈文字效果
    func playFeedbackText(_ text: String, at position: CGPoint, style: FeedbackStyle)
    
    // MARK: - Medium Effects (中特效)
    
    /// 播放连击特效
    func playComboEffect(comboCount: Int, at position: CGPoint)
    
    /// 播放升级光柱效果
    func playUpgradeBeam(at position: HexPosition, swordType: SwordType)
    
    /// 播放连击结束特效
    func playComboEndEffect(comboCount: Int)
    
    // MARK: - Large Effects (大特效)
    
    /// 播放连锁波效果
    func playChainWave(from center: HexPosition, radius: Int)
    
    /// 播放区域爆炸效果
    func playAreaClearExplosion(at position: HexPosition)
    
    /// 播放行清除效果
    func playRowClearEffect(row: Int)
    
    // MARK: - Epic Effects (史诗特效)
    
    /// 播放终极技能效果
    func playUltimateEffect()
    
    /// 播放万剑归宗效果
    func playWanJianGuiZongEffect()
    
    /// 播放乾坤大挪移效果
    func playQianKunDaNuoYiEffect()
    
    /// 播放九阴真经效果
    func playJiuYinZhenJingEffect()
    
    // MARK: - Legendary Effects (传说特效)
    
    /// 播放神剑出世效果
    func playDivineSwordEffect(at position: HexPosition)
    
    /// 播放胜利庆祝效果
    func playVictoryEffect()
    
    // MARK: - Screen Effects (屏幕效果)
    
    /// 屏幕震动
    func shakeScreen(intensity: ShakeIntensity)
    
    /// 屏幕闪烁
    func flashScreen(color: ScreenFlashColor, duration: TimeInterval)
    
    /// 慢动作效果
    func playSlowMotion(duration: TimeInterval, scale: Float)
    
    // MARK: - Background Effects (背景效果)
    
    /// 开始背景粒子效果
    func startBackgroundParticles()
    
    /// 停止背景粒子效果
    func stopBackgroundParticles()
    
    /// 播放洗牌效果
    func playShuffleEffect()
    
    // MARK: - Settings
    
    /// 是否启用特效
    var isEffectsEnabled: Bool { get set }
    
    /// 特效强度
    var effectsIntensity: Float { get set }
}

// MARK: - Supporting Types

/// 特效强度
public enum EffectIntensity: Float, CaseIterable {
    case micro = 0.3
    case small = 0.5
    case medium = 0.7
    case large = 0.9
    case epic = 1.0
    case legendary = 1.2
}

/// 分数样式
public enum ScoreStyle {
    case normal
    case good
    case great
    case excellent
    case perfect
    case legendary
    
    public var fontSize: CGFloat {
        switch self {
        case .normal: return 24
        case .good: return 28
        case .great: return 32
        case .excellent: return 38
        case .perfect: return 44
        case .legendary: return 52
        }
    }
    
    public var color: String {
        switch self {
        case .normal: return "white"
        case .good: return "cyan"
        case .great: return "blue"
        case .excellent: return "purple"
        case .perfect: return "gold"
        case .legendary: return "red"
        }
    }
    
    public var floatDistance: CGFloat {
        switch self {
        case .normal: return 50
        case .good: return 60
        case .great: return 70
        case .excellent: return 80
        case .perfect: return 90
        case .legendary: return 100
        }
    }
}

/// 反馈文字样式
public enum FeedbackStyle {
    case combo(Int)
    case perfect
    case excellent
    case good
    case ultimate
    case divine
    
    public var text: String {
        switch self {
        case .combo(let count):
            return "连击 x\(count)"
        case .perfect:
            return "完美!"
        case .excellent:
            return "卓越!"
        case .good:
            return "不错!"
        case .ultimate:
            return "终极奥义!"
        case .divine:
            return "神剑出世!"
        }
    }
    
    public var style: ScoreStyle {
        switch self {
        case .combo(let count):
            if count >= 10 { return .legendary }
            else if count >= 5 { return .perfect }
            else { return .excellent }
        case .perfect:
            return .perfect
        case .excellent:
            return .excellent
        case .good:
            return .good
        case .ultimate, .divine:
            return .legendary
        }
    }
}

/// 震动强度
public enum ShakeIntensity: Float, CaseIterable {
    case light = 0.2
    case medium = 0.4
    case strong = 0.6
    case intense = 0.8
    case extreme = 1.0
}

/// 屏幕闪烁颜色
public enum ScreenFlashColor {
    case white
    case gold
    case red
    case blue
    case purple
    
    public var colorName: String {
        switch self {
        case .white: return "white"
        case .gold: return "gold"
        case .red: return "red"
        case .blue: return "blue"
        case .purple: return "purple"
        }
    }
}