//
//  SoundManager.swift
//  wjgz
//
//  多巴胺音效系统 - 让每个动作都令人兴奋
//  使用系统音效和触觉反馈，简单可靠
//

import AVFoundation
import AudioToolbox
#if os(iOS)
import UIKit
#endif

class SoundManager {
    static let shared = SoundManager()
    
    private var isEnabled: Bool = true
    
    // 系统音效 ID
    private let tapSoundID: SystemSoundID = 1104  // 键盘点击音
    private let selectSoundID: SystemSoundID = 1105  // 选择音
    private let successSoundID: SystemSoundID = 1054  // 成功音
    private let errorSoundID: SystemSoundID = 1053  // 错误音
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            print("SoundManager: Audio session configured successfully")
        } catch {
            print("SoundManager: Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    // MARK: - 系统音效播放
    
    private func playSystemSound(_ soundID: SystemSoundID) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - 基础音效
    
    /// 点击音效
    func playTap() {
        playSystemSound(tapSoundID)
        vibrate(.light)
    }
    
    /// 选中音效
    func playSelect() {
        playSystemSound(selectSoundID)
        vibrate(.light)
    }
    
    /// 拖拽音效
    func playDrag() {
        playSystemSound(tapSoundID)
    }
    
    /// 放下音效
    func playDrop() {
        playSystemSound(selectSoundID)
        vibrate(.medium)
    }
    
    // MARK: - 合成音效
    
    /// 凡剑合成
    func playMergeFan() {
        playSystemSound(tapSoundID)
        vibrate(.medium)
    }
    
    /// 灵剑合成
    func playMergeLing() {
        playSystemSound(selectSoundID)
        vibrate(.medium)
    }
    
    /// 仙剑合成
    func playMergeXian() {
        playSystemSound(successSoundID)
        vibrate(.heavy)
    }
    
    /// 神剑合成
    func playMergeShen() {
        playSystemSound(successSoundID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AudioServicesPlaySystemSound(self.successSoundID)
        }
        vibrate(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.vibrate(.heavy)
        }
    }
    
    // MARK: - 连击音效
    
    /// 连击音效
    func playCombo(_ count: Int) {
        if count >= 5 {
            playSystemSound(successSoundID)
            vibrate(.heavy)
        } else if count >= 3 {
            playSystemSound(selectSoundID)
            vibrate(.medium)
        } else {
            playSystemSound(tapSoundID)
            vibrate(.light)
        }
    }
    
    // MARK: - 特殊效果音效
    
    /// 连锁消除
    func playChainClear() {
        playSystemSound(successSoundID)
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                self.vibrate(.light)
            }
        }
    }
    
    /// 区域爆炸
    func playExplosion() {
        playSystemSound(successSoundID)
        vibrate(.heavy)
    }
    
    /// 升级光柱
    func playLevelUp() {
        playSystemSound(successSoundID)
        vibrate(.medium)
    }
    
    // MARK: - 终极技音效
    
    /// 万剑归宗
    func playUltimate() {
        // 连续播放音效
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                AudioServicesPlaySystemSound(self.successSoundID)
            }
        }
        
        // 震动序列
        let vibratePattern: [Double] = [0, 0.2, 0.4, 0.6, 0.8]
        for delay in vibratePattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.vibrate(.heavy)
            }
        }
    }
    
    // MARK: - UI音效
    
    /// 能量满音效
    func playEnergyFull() {
        playSystemSound(successSoundID)
        vibrate(.medium)
    }
    
    /// 关卡完成音效
    func playLevelComplete() {
        // 胜利音阶
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                AudioServicesPlaySystemSound(self.successSoundID)
            }
        }
        
        // 庆祝震动
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                self.vibrate(.medium)
            }
        }
    }
    
    /// 游戏失败音效
    func playGameOver() {
        playSystemSound(errorSoundID)
        vibrate(.heavy)
    }
    
    /// 星星出现音效
    func playStar() {
        playSystemSound(successSoundID)
        vibrate(.light)
    }
    
    /// 按钮点击音效
    func playButton() {
        playSystemSound(tapSoundID)
        vibrate(.light)
    }
    
    /// 错误音效
    func playError() {
        playSystemSound(errorSoundID)
        vibrate(.medium)
    }
    
    // MARK: - 反馈音效
    
    /// 根据消除数量播放反馈音效
    func playFeedback(for count: Int) {
        switch count {
        case 3:
            playSystemSound(tapSoundID)
        case 4:
            playSystemSound(selectSoundID)
        case 5:
            playSystemSound(successSoundID)
            vibrate(.medium)
        case 6...7:
            playSystemSound(successSoundID)
            vibrate(.heavy)
        case 8...10:
            playSystemSound(successSoundID)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AudioServicesPlaySystemSound(self.successSoundID)
            }
            vibrate(.heavy)
        default:
            playUltimate()
        }
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
