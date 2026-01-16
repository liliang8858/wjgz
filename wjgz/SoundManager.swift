//
//  SoundManager.swift
//  wjgz
//
//  多巴胺音效系统 - 让每个动作都令人兴奋
//

import AVFoundation
import AudioToolbox

class SoundManager {
    static let shared = SoundManager()
    
    private var audioEngine: AVAudioEngine!
    private var players: [String: AVAudioPlayerNode] = [:]
    private var isEnabled: Bool = true
    
    // 音效强度
    private let masterVolume: Float = 0.6
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    // MARK: - 基础音效
    
    /// 点击音效 - 清脆的"叮"
    func playTap() {
        guard isEnabled else { return }
        playTone(frequency: 1200, duration: 0.05, volume: 0.15)
        vibrate(.light)
    }
    
    /// 选中音效 - 上升音调
    func playSelect() {
        guard isEnabled else { return }
        playSweep(startFreq: 800, endFreq: 1400, duration: 0.1, volume: 0.2)
        vibrate(.light)
    }
    
    /// 拖拽音效 - 柔和的滑动声
    func playDrag() {
        guard isEnabled else { return }
        playTone(frequency: 600, duration: 0.03, volume: 0.08)
    }
    
    /// 放下音效 - 低沉的"咚"
    func playDrop() {
        guard isEnabled else { return }
        playSweep(startFreq: 400, endFreq: 200, duration: 0.15, volume: 0.25)
        vibrate(.medium)
    }
    
    // MARK: - 合成音效
    
    /// 凡剑合成 - 简单的叮当声
    func playMergeFan() {
        guard isEnabled else { return }
        playChord(frequencies: [600, 800, 1000], duration: 0.2, volume: 0.25)
        vibrate(.medium)
    }
    
    /// 灵剑合成 - 清脆的剑鸣
    func playMergeLing() {
        guard isEnabled else { return }
        playChord(frequencies: [800, 1200, 1600], duration: 0.3, volume: 0.3)
        playReverb(frequency: 1200, duration: 0.5, volume: 0.15)
        vibrate(.heavy)
    }
    
    /// 仙剑合成 - 华丽的音阶
    func playMergeXian() {
        guard isEnabled else { return }
        let frequencies: [Double] = [1000, 1200, 1500, 1800, 2200]
        for (index, freq) in frequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                self.playTone(frequency: freq, duration: 0.15, volume: 0.25)
            }
        }
        vibrate(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.vibrate(.heavy)
        }
    }
    
    /// 神剑合成 - 史诗级音效
    func playMergeShen() {
        guard isEnabled else { return }
        // 低音轰鸣
        playTone(frequency: 100, duration: 0.8, volume: 0.4)
        
        // 上升音阶
        let frequencies: [Double] = [400, 600, 800, 1200, 1600, 2000, 2400]
        for (index, freq) in frequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                self.playTone(frequency: freq, duration: 0.3, volume: 0.3)
            }
        }
        
        // 高潮爆发
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.playChord(frequencies: [2000, 2400, 2800, 3200], duration: 0.5, volume: 0.35)
        }
        
        // 强烈震动
        vibrate(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.vibrate(.heavy)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.vibrate(.heavy)
        }
    }
    
    // MARK: - 连击音效
    
    /// 连击音效 - 根据连击数递增音调
    func playCombo(_ count: Int) {
        guard isEnabled else { return }
        let baseFreq = 800.0
        let freq = baseFreq + Double(min(count, 10)) * 100
        
        // 主音
        playChord(frequencies: [freq, freq * 1.5, freq * 2], duration: 0.25, volume: 0.35)
        
        // 回声
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playTone(frequency: freq * 2, duration: 0.15, volume: 0.2)
        }
        
        if count >= 5 {
            // 5连击以上额外音效
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playChord(frequencies: [freq * 1.5, freq * 2, freq * 2.5], duration: 0.2, volume: 0.3)
            }
            vibrate(.heavy)
        } else {
            vibrate(.medium)
        }
    }
    
    // MARK: - 特殊效果音效
    
    /// 连锁消除 - 快速音阶
    func playChainClear() {
        guard isEnabled else { return }
        let frequencies: [Double] = [600, 800, 1000, 1200, 1400, 1600, 1800, 2000]
        for (index, freq) in frequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                self.playTone(frequency: freq, duration: 0.1, volume: 0.25)
            }
        }
        
        // 震动序列
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                self.vibrate(.light)
            }
        }
    }
    
    /// 区域爆炸 - 爆炸音效
    func playExplosion() {
        guard isEnabled else { return }
        // 低频爆炸
        playNoise(duration: 0.15, volume: 0.3)
        
        // 高频碎片
        for _ in 0..<8 {
            let freq = Double.random(in: 1000...3000)
            let delay = Double.random(in: 0...0.2)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTone(frequency: freq, duration: 0.08, volume: 0.15)
            }
        }
        
        vibrate(.heavy)
    }
    
    /// 升级光柱 - 上升音效
    func playLevelUp() {
        guard isEnabled else { return }
        playSweep(startFreq: 400, endFreq: 2000, duration: 0.4, volume: 0.3)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playChord(frequencies: [1500, 2000, 2500], duration: 0.3, volume: 0.25)
        }
        
        vibrate(.medium)
    }
    
    // MARK: - 终极技音效
    
    /// 万剑归宗 - 史诗音效
    func playUltimate() {
        guard isEnabled else { return }
        
        // 1. 蓄力音效
        playSweep(startFreq: 200, endFreq: 100, duration: 0.5, volume: 0.4)
        
        // 2. 剑气升腾
        for i in 0..<20 {
            let delay = Double(i) * 0.05
            let freq = 400.0 + Double(i) * 80
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + delay) {
                self.playTone(frequency: freq, duration: 0.2, volume: 0.2)
            }
        }
        
        // 3. 高潮爆发
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.playChord(frequencies: [2000, 2500, 3000, 3500], duration: 0.6, volume: 0.4)
            self.playNoise(duration: 0.3, volume: 0.25)
        }
        
        // 4. 余韵
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.playReverb(frequency: 2000, duration: 1.0, volume: 0.2)
        }
        
        // 5. 震动序列
        let vibratePattern: [Double] = [0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.5]
        for delay in vibratePattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.vibrate(.heavy)
            }
        }
    }
    
    // MARK: - UI音效
    
    /// 能量满音效
    func playEnergyFull() {
        guard isEnabled else { return }
        playChord(frequencies: [1000, 1500, 2000], duration: 0.4, volume: 0.3)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playChord(frequencies: [1200, 1800, 2400], duration: 0.3, volume: 0.25)
        }
        
        vibrate(.medium)
    }
    
    /// 关卡完成音效
    func playLevelComplete() {
        guard isEnabled else { return }
        // 胜利音阶
        let frequencies: [Double] = [800, 1000, 1200, 1600, 2000]
        for (index, freq) in frequencies.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                self.playChord(frequencies: [freq, freq * 1.5], duration: 0.3, volume: 0.3)
            }
        }
        
        // 烟花音效
        for i in 0..<10 {
            let delay = Double(i) * 0.1 + 0.8
            let freq = Double.random(in: 1500...3000)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTone(frequency: freq, duration: 0.15, volume: 0.2)
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
        guard isEnabled else { return }
        playSweep(startFreq: 800, endFreq: 200, duration: 0.8, volume: 0.3)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.playTone(frequency: 150, duration: 0.5, volume: 0.25)
        }
        
        vibrate(.heavy)
    }
    
    /// 星星出现音效
    func playStar() {
        guard isEnabled else { return }
        playChord(frequencies: [1500, 2000, 2500], duration: 0.2, volume: 0.25)
        vibrate(.light)
    }
    
    /// 按钮点击音效
    func playButton() {
        guard isEnabled else { return }
        playTone(frequency: 1000, duration: 0.08, volume: 0.2)
        vibrate(.light)
    }
    
    /// 错误音效
    func playError() {
        guard isEnabled else { return }
        playTone(frequency: 200, duration: 0.15, volume: 0.25)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 150, duration: 0.15, volume: 0.25)
        }
        
        vibrate(.medium)
    }
    
    // MARK: - 反馈音效
    
    /// 根据消除数量播放反馈音效
    func playFeedback(for count: Int) {
        guard isEnabled else { return }
        
        switch count {
        case 3:
            playTone(frequency: 1000, duration: 0.15, volume: 0.2)
        case 4:
            playChord(frequencies: [1000, 1500], duration: 0.2, volume: 0.25)
        case 5:
            playChord(frequencies: [1200, 1600, 2000], duration: 0.25, volume: 0.3)
        case 6...7:
            playChord(frequencies: [1400, 1800, 2200, 2600], duration: 0.3, volume: 0.35)
            vibrate(.medium)
        case 8...10:
            playChord(frequencies: [1600, 2000, 2400, 2800, 3200], duration: 0.35, volume: 0.4)
            vibrate(.heavy)
        default:
            // 传说级
            playUltimate()
        }
    }
    
    // MARK: - 底层音频生成
    
    private func playTone(frequency: Double, duration: TimeInterval, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData else { return }
        let data = channelData[0]
        
        let angularFrequency = 2.0 * .pi * frequency / sampleRate
        
        for frame in 0..<Int(frameCount) {
            let value = sin(angularFrequency * Double(frame))
            let envelope = min(1.0, Double(frame) / (sampleRate * 0.01)) * // Attack
                          min(1.0, Double(frameCount - frame) / (sampleRate * 0.05)) // Release
            data[frame] = Float(value * envelope) * volume * masterVolume
        }
        
        let player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        
        player.scheduleBuffer(buffer) {
            self.audioEngine.detach(player)
        }
        
        player.play()
    }
    
    private func playSweep(startFreq: Double, endFreq: Double, duration: TimeInterval, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData else { return }
        let data = channelData[0]
        
        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            let frequency = startFreq + (endFreq - startFreq) * progress
            let angularFrequency = 2.0 * .pi * frequency / sampleRate
            
            let value = sin(angularFrequency * Double(frame))
            let envelope = min(1.0, Double(frame) / (sampleRate * 0.01)) *
                          min(1.0, Double(frameCount - frame) / (sampleRate * 0.05))
            data[frame] = Float(value * envelope) * volume * masterVolume
        }
        
        let player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        
        player.scheduleBuffer(buffer) {
            self.audioEngine.detach(player)
        }
        
        player.play()
    }
    
    private func playChord(frequencies: [Double], duration: TimeInterval, volume: Float) {
        for freq in frequencies {
            playTone(frequency: freq, duration: duration, volume: volume / Float(frequencies.count))
        }
    }
    
    private func playReverb(frequency: Double, duration: TimeInterval, volume: Float) {
        for i in 0..<5 {
            let delay = Double(i) * 0.1
            let decayVolume = volume * pow(0.6, Double(i))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTone(frequency: frequency, duration: duration * 0.5, volume: Float(decayVolume))
            }
        }
    }
    
    private func playNoise(duration: TimeInterval, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData else { return }
        let data = channelData[0]
        
        for frame in 0..<Int(frameCount) {
            let value = Float.random(in: -1...1)
            let envelope = min(1.0, Double(frame) / (sampleRate * 0.01)) *
                          min(1.0, Double(frameCount - frame) / (sampleRate * 0.02))
            data[frame] = value * Float(envelope) * volume * masterVolume
        }
        
        let player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        
        player.scheduleBuffer(buffer) {
            self.audioEngine.detach(player)
        }
        
        player.play()
    }
    
    // MARK: - 触觉反馈
    
    enum VibrateStyle {
        case light, medium, heavy
    }
    
    private func vibrate(_ style: VibrateStyle) {
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
    }
}
