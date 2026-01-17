//
//  SoundManager.swift
//  wjgz
//
//  多巴胺音效系统 - 让每个动作都令人兴奋
//  支持背景音乐和音效播放，配合触觉反馈
//

import AVFoundation
import AudioToolbox
#if os(iOS)
import UIKit
#endif

class SoundManager {
    static let shared = SoundManager()
    
    private(set) var isEnabled: Bool = true  // 改为可读属性
    private var musicVolume: Float = 0.4
    private var sfxVolume: Float = 0.7
    
    // 背景音乐播放器
    private var bgmPlayer: AVAudioPlayer?
    
    // 音效播放器池（支持同时播放多个音效）
    private var sfxPlayers: [String: [AVAudioPlayer]] = [:]
    private let maxPlayersPerSound = 3
    
    // 系统音效 ID（作为备用）
    private let tapSoundID: SystemSoundID = 1104
    private let selectSoundID: SystemSoundID = 1105
    private let successSoundID: SystemSoundID = 1054
    private let errorSoundID: SystemSoundID = 1053
    
    private init() {
        setupAudioSession()
        preloadSounds()
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
    
    // MARK: - Sound Loading
    
    /// 预加载音效
    private func preloadSounds() {
        // 预加载常用音效
        let commonSounds = [
            "sword_whoosh", "sword_clash", "sword_draw",
            "merge_small", "merge_medium", "merge_large", "merge_epic",
            "button_click", "success", "combo"
        ]
        
        for soundName in commonSounds {
            _ = loadSound(soundName)
        }
        
        print("SoundManager: Preloaded \(commonSounds.count) sounds")
    }
    
    /// 加载音效文件
    private func loadSound(_ name: String) -> AVAudioPlayer? {
        // 尝试从不同路径加载，包括子文件夹
        let possiblePaths = [
            "Sounds/SFX/UI/\(name)",
            "Sounds/SFX/Sword/\(name)",
            "Sounds/SFX/Merge/\(name)",
            "Sounds/SFX/Effects/\(name)",
            "Sounds/SFX/Ultimate/\(name)",
            "Sounds/SFX/\(name)",
            "Sounds/\(name)",
            name
        ]
        
        // 支持多种音频格式
        let extensions = ["mp3", "wav", "m4a"]
        
        for basePath in possiblePaths {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: basePath, withExtension: ext) {
                    do {
                        let player = try AVAudioPlayer(contentsOf: url)
                        player.prepareToPlay()
                        player.volume = sfxVolume
                        print("✅ 成功加载音效: \(basePath).\(ext)")
                        return player
                    } catch {
                        print("❌ 加载音效失败: \(basePath).\(ext) - \(error)")
                        continue
                    }
                }
            }
        }
        
        // 如果找不到音效文件，返回 nil（将使用系统音效）
        print("⚠️ 音效文件未找到: \(name)")
        return nil
    }
    
    /// 播放音效
    private func playSoundEffect(_ name: String, fallbackSystemSound: SystemSoundID? = nil) {
        print("🔊 尝试播放音效: \(name), 启用状态: \(isEnabled)")
        
        guard isEnabled else { 
            print("❌ 音效系统已禁用")
            return 
        }
        
        // 尝试播放自定义音效
        if let player = getAvailablePlayer(for: name) {
            player.currentTime = 0
            player.volume = sfxVolume
            let success = player.play()
            print("🎵 播放自定义音效 \(name): \(success ? "成功" : "失败")")
            return
        }
        
        // 如果没有自定义音效，使用系统音效
        if let systemSound = fallbackSystemSound {
            AudioServicesPlaySystemSound(systemSound)
            print("🔔 播放系统音效: \(systemSound)")
        } else {
            print("⚠️ 音效文件未找到: \(name)")
        }
    }
    
    /// 播放合成音效（音量较低）
    private func playMergeSoundEffect(_ name: String, fallbackSystemSound: SystemSoundID? = nil) {
        guard isEnabled else { return }
        
        // 尝试播放自定义音效
        if let player = getAvailablePlayer(for: name) {
            player.currentTime = 0
            player.volume = sfxVolume * 0.3  // 合成音效降低到 30%
            player.play()
            return
        }
        
        // 如果没有自定义音效，使用系统音效
        if let systemSound = fallbackSystemSound {
            AudioServicesPlaySystemSound(systemSound)
        }
    }
    
    /// 获取可用的播放器（支持同时播放多个相同音效）
    private func getAvailablePlayer(for soundName: String) -> AVAudioPlayer? {
        // 如果还没有这个音效的播放器池，创建它
        if sfxPlayers[soundName] == nil {
            sfxPlayers[soundName] = []
        }
        
        // 查找空闲的播放器
        if let player = sfxPlayers[soundName]?.first(where: { !$0.isPlaying }) {
            return player
        }
        
        // 如果没有空闲的，且数量未达上限，创建新的
        if let players = sfxPlayers[soundName], players.count < maxPlayersPerSound {
            if let newPlayer = loadSound(soundName) {
                sfxPlayers[soundName]?.append(newPlayer)
                return newPlayer
            }
        }
        
        // 如果都在播放，返回第一个（会被打断）
        return sfxPlayers[soundName]?.first
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopBackgroundMusic()
        }
    }
    
    func setMusicVolume(_ volume: Float) {
        musicVolume = max(0, min(1, volume))
        bgmPlayer?.volume = musicVolume
    }
    
    func setSFXVolume(_ volume: Float) {
        sfxVolume = max(0, min(1, volume))
    }
    
    // MARK: - Background Music
    
    /// 播放背景音乐
    func playBackgroundMusic(_ name: String = "background_main", loop: Bool = true) {
        guard isEnabled else { return }
        
        // 停止当前音乐
        stopBackgroundMusic()
        
        // 尝试加载新音乐
        let possiblePaths = [
            "Sounds/BGM/\(name)",
            "Sounds/\(name)",
            name
        ]
        
        // 支持多种音频格式
        let extensions = ["mp3", "wav", "m4a"]
        
        for basePath in possiblePaths {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: basePath, withExtension: ext) {
                    do {
                        bgmPlayer = try AVAudioPlayer(contentsOf: url)
                        bgmPlayer?.numberOfLoops = loop ? -1 : 0
                        bgmPlayer?.volume = musicVolume
                        bgmPlayer?.prepareToPlay()
                        bgmPlayer?.play()
                        print("SoundManager: Playing background music: \(name)")
                        return
                    } catch {
                        print("SoundManager: Failed to load music \(name): \(error)")
                    }
                }
            }
        }
        
        print("SoundManager: Background music '\(name)' not found")
    }
    
    /// 停止背景音乐
    func stopBackgroundMusic() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }
    
    /// 暂停背景音乐
    func pauseBackgroundMusic() {
        bgmPlayer?.pause()
    }
    
    /// 恢复背景音乐
    func resumeBackgroundMusic() {
        guard isEnabled else { return }
        bgmPlayer?.play()
    }
    
    /// 淡出背景音乐
    func fadeOutBackgroundMusic(duration: TimeInterval = 1.0) {
        guard let player = bgmPlayer else { return }
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)
        
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume -= volumeStep
            
            if currentStep >= steps {
                timer.invalidate()
                self.stopBackgroundMusic()
            }
        }
    }
    
    /// 淡入背景音乐
    func fadeInBackgroundMusic(_ name: String = "background_main", duration: TimeInterval = 1.0) {
        playBackgroundMusic(name, loop: true)
        
        guard let player = bgmPlayer else { return }
        player.volume = 0
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = musicVolume / Float(steps)
        
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume = min(player.volume + volumeStep, self.musicVolume)
            
            if currentStep >= steps {
                timer.invalidate()
            }
        }
    }
    
    // MARK: - 系统音效播放（备用）
    
    private func playSystemSound(_ soundID: SystemSoundID) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - 基础音效
    
    /// 点击音效
    func playTap() {
        print("🔊 playTap() 被调用")
        playSoundEffect("button_click", fallbackSystemSound: tapSoundID)
        vibrate(.light)
    }
    
    /// 选中音效
    func playSelect() {
        playSoundEffect("sword_draw", fallbackSystemSound: selectSoundID)
        vibrate(.light)
    }
    
    /// 拖拽音效
    func playDrag() {
        playSoundEffect("sword_whoosh", fallbackSystemSound: tapSoundID)
    }
    
    /// 放下音效
    func playDrop() {
        playSoundEffect("sword_sheath", fallbackSystemSound: selectSoundID)
        vibrate(.medium)
    }
    
    // MARK: - 合成音效
    
    /// 通用合成音效（已关闭）
    func playMerge() {
        // 合成音效已关闭，只保留震动反馈
        vibrate(.light)
    }
    
    /// 凡剑合成
    func playMergeFan() {
        playMerge()
    }
    
    /// 灵剑合成
    func playMergeLing() {
        playMerge()
    }
    
    /// 仙剑合成
    func playMergeXian() {
        playMerge()
    }
    
    /// 神剑合成
    func playMergeShen() {
        playMerge()
    }
    
    // MARK: - 连击音效
    
    /// 连击音效
    func playCombo(_ count: Int) {
        if count >= 5 {
            playSoundEffect("combo_high", fallbackSystemSound: successSoundID)
            vibrate(.heavy)
        } else if count >= 3 {
            playSoundEffect("combo", fallbackSystemSound: selectSoundID)
            vibrate(.medium)
        } else {
            playSoundEffect("combo_low", fallbackSystemSound: tapSoundID)
            vibrate(.light)
        }
    }
    
    // MARK: - 特殊效果音效
    
    /// 连锁消除
    func playChainClear() {
        playSoundEffect("sword_clash")
        
        // 连续音效
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
                self.playSoundEffect("whoosh")
                self.vibrate(.light)
            }
        }
    }
    
    /// 区域爆炸
    func playExplosion() {
        playSoundEffect("explosion", fallbackSystemSound: successSoundID)
        vibrate(.heavy)
    }
    
    /// 升级光柱（短音效，音量降低）
    func playLevelUp() {
        playMergeSoundEffect("power_up", fallbackSystemSound: successSoundID)
        vibrate(.medium)
    }
    
    // MARK: - 终极技音效
    
    /// 万剑归宗（简化版，只播放一个音效）
    func playUltimate() {
        // 播放一个简短的终极技音效
        playMergeSoundEffect("ultimate_release", fallbackSystemSound: successSoundID)
        
        // 震动反馈
        let vibratePattern: [Double] = [0, 0.2, 0.4]
        for delay in vibratePattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.vibrate(.heavy)
            }
        }
    }
    
    // MARK: - UI音效
    
    /// 能量满音效（短音效，音量降低）
    func playEnergyFull() {
        playMergeSoundEffect("power_up", fallbackSystemSound: successSoundID)
        vibrate(.medium)
    }
    
    /// 关卡完成音效（保留）
    func playLevelComplete() {
        playSoundEffect("level_complete")
        vibrate(.medium)
    }
    
    /// 游戏失败音效
    func playGameOver() {
        playSoundEffect("game_over", fallbackSystemSound: errorSoundID)
        vibrate(.heavy)
    }
    
    /// 星星出现音效（短音效，音量降低）
    func playStar() {
        playMergeSoundEffect("sparkle", fallbackSystemSound: successSoundID)
        vibrate(.light)
    }
    
    /// 按钮点击音效
    func playButton() {
        playSoundEffect("button_click", fallbackSystemSound: tapSoundID)
        vibrate(.light)
    }
    
    /// 错误音效
    func playError() {
        playSoundEffect("error", fallbackSystemSound: errorSoundID)
        vibrate(.medium)
    }
    
    // MARK: - 反馈音效
    
    /// 根据消除数量播放反馈音效（短音效，音量降低）
    func playFeedback(for count: Int) {
        switch count {
        case 3...4:
            vibrate(.light)
        case 5:
            playMergeSoundEffect("success", fallbackSystemSound: successSoundID)
            vibrate(.medium)
        case 6...7:
            playMergeSoundEffect("success", fallbackSystemSound: successSoundID)
            vibrate(.heavy)
        case 8...10:
            playMergeSoundEffect("power_up", fallbackSystemSound: successSoundID)
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
