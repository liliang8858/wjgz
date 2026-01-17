//
//  SystemSoundHelper.swift
//  wjgz
//
//  系统音效辅助工具 - 确保音效正常工作
//

import AudioToolbox
import UIKit

class SystemSoundHelper {
    static let shared = SystemSoundHelper()
    
    private var isEnabled: Bool = true
    
    private init() {}
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        print("🔊 SystemSoundHelper 启用状态: \(enabled)")
    }
    
    // MARK: - 基础音效
    
    func playTap() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104)
        vibrate(.light)
        print("🔔 播放点击音效")
    }
    
    func playSelect() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1105)
        vibrate(.light)
        print("🔔 播放选择音效")
    }
    
    func playSuccess() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1054)
        vibrate(.medium)
        print("🔔 播放成功音效")
    }
    
    func playError() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1053)
        vibrate(.medium)
        print("🔔 播放错误音效")
    }
    
    // MARK: - 游戏音效
    
    func playMerge() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1054) // 成功音效
        vibrate(.medium)
        print("🔔 播放合成音效")
    }
    
    func playCombo() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1105) // 选择音效
        vibrate(.heavy)
        print("🔔 播放连击音效")
    }
    
    func playUltimate() {
        guard isEnabled else { return }
        // 播放一系列音效模拟终极技能
        AudioServicesPlaySystemSound(1054)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(1105)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            AudioServicesPlaySystemSound(1054)
        }
        
        vibrate(.heavy)
        print("🔔 播放终极技音效")
    }
    
    func playLevelComplete() {
        guard isEnabled else { return }
        // 播放胜利音效序列
        AudioServicesPlaySystemSound(1054)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1054)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AudioServicesPlaySystemSound(1054)
        }
        
        vibrate(.heavy)
        print("🔔 播放关卡完成音效")
    }
    
    // MARK: - 触觉反馈
    
    enum VibrateStyle {
        case light, medium, heavy
    }
    
    private func vibrate(_ style: VibrateStyle) {
        #if os(iOS)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator.impactOccurred()
        #endif
    }
}