import AVFoundation
import AudioToolbox

/// 音效服务实现
public final class AudioService: AudioServiceProtocol {
    
    // MARK: - Properties
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundPlayers: [String: [AVAudioPlayer]] = [:]
    private let maxPlayersPerSound = 3
    
    // MARK: - Settings
    
    public var isSoundEnabled: Bool = true {
        didSet {
            if !isSoundEnabled {
                stopAllSounds()
            }
        }
    }
    
    public var isMusicEnabled: Bool = true {
        didSet {
            if isMusicEnabled {
                resumeBackgroundMusic()
            } else {
                pauseBackgroundMusic()
            }
        }
    }
    
    public var masterVolume: Float = 0.8 {
        didSet {
            updateAllVolumes()
        }
    }
    
    private var musicVolume: Float = 0.6
    private var sfxVolume: Float = 0.8
    
    // MARK: - Initialization
    
    public init() {
        setupAudioSession()
        preloadSounds()
    }
    
    // MARK: - Background Music
    
    public func playBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        if backgroundMusicPlayer == nil {
            setupBackgroundMusic()
        }
        
        backgroundMusicPlayer?.play()
    }
    
    public func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    public func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        backgroundMusicPlayer?.play()
    }
    
    public func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    public func setBackgroundMusicVolume(_ volume: Float) {
        musicVolume = volume
        backgroundMusicPlayer?.volume = volume * masterVolume
    }
    
    // MARK: - Sound Effects
    
    public func playSound(_ soundType: SoundType) {
        playSound(soundType, volume: sfxVolume)
    }
    
    public func playSound(_ soundType: SoundType, volume: Float) {
        guard isSoundEnabled else { return }
        
        // 尝试播放自定义音效
        if playCustomSound(soundType, volume: volume) {
            return
        }
        
        // 回退到系统音效
        if let systemSoundID = soundType.systemSoundID {
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }
    
    public func setSoundEffectsVolume(_ volume: Float) {
        sfxVolume = volume
        updateSoundPlayersVolume()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "background_main", withExtension: "mp3") else {
            print("Background music file not found")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // 无限循环
            backgroundMusicPlayer?.volume = musicVolume * masterVolume
            backgroundMusicPlayer?.prepareToPlay()
        } catch {
            print("Failed to setup background music: \(error)")
        }
    }
    
    private func preloadSounds() {
        for soundType in SoundType.allCases {
            preloadSound(soundType)
        }
    }
    
    private func preloadSound(_ soundType: SoundType) {
        guard let url = Bundle.main.url(forResource: soundType.fileName, withExtension: soundType.fileExtension) else {
            return
        }
        
        var players: [AVAudioPlayer] = []
        
        for _ in 0..<maxPlayersPerSound {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = sfxVolume * masterVolume
                player.prepareToPlay()
                players.append(player)
            } catch {
                print("Failed to preload sound \(soundType.fileName): \(error)")
                break
            }
        }
        
        if !players.isEmpty {
            soundPlayers[soundType.rawValue] = players
        }
    }
    
    private func playCustomSound(_ soundType: SoundType, volume: Float) -> Bool {
        guard let players = soundPlayers[soundType.rawValue] else {
            return false
        }
        
        // 找到一个空闲的播放器
        for player in players {
            if !player.isPlaying {
                player.volume = volume * masterVolume
                player.currentTime = 0
                player.play()
                return true
            }
        }
        
        // 如果所有播放器都在使用，使用第一个
        let player = players[0]
        player.volume = volume * masterVolume
        player.currentTime = 0
        player.play()
        return true
    }
    
    private func stopAllSounds() {
        for players in soundPlayers.values {
            for player in players {
                player.stop()
            }
        }
    }
    
    private func updateAllVolumes() {
        backgroundMusicPlayer?.volume = musicVolume * masterVolume
        updateSoundPlayersVolume()
    }
    
    private func updateSoundPlayersVolume() {
        for players in soundPlayers.values {
            for player in players {
                player.volume = sfxVolume * masterVolume
            }
        }
    }
}