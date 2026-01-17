import SpriteKit

/// 特效服务实现
public final class EffectsService: EffectsServiceProtocol {
    
    // MARK: - Properties
    
    private weak var scene: SKScene?
    private var backgroundParticles: SKEmitterNode?
    
    // MARK: - Settings
    
    public var isEffectsEnabled: Bool = true
    public var effectsIntensity: Float = 0.8
    
    // MARK: - Initialization
    
    public init() {}
    
    /// 设置场景引用
    public func setScene(_ scene: SKScene) {
        self.scene = scene
    }
    
    // MARK: - Micro Effects
    
    public func playTapRipple(at position: CGPoint) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let ripple = SKShapeNode(circleOfRadius: 5)
        ripple.fillColor = .clear
        ripple.strokeColor = UIColor.white.withAlphaComponent(0.8)
        ripple.lineWidth = 2
        ripple.position = position
        ripple.zPosition = 150
        
        scene.addChild(ripple)
        
        let expand = SKAction.scale(to: 3.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        ripple.run(SKAction.sequence([SKAction.group([expand, fade]), remove]))
    }
    
    public func playSelectPulse(at position: CGPoint) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let pulse = SKShapeNode(circleOfRadius: 30)
        pulse.fillColor = UIColor.cyan.withAlphaComponent(0.3)
        pulse.strokeColor = .cyan
        pulse.lineWidth = 2
        pulse.position = position
        pulse.zPosition = 150
        
        scene.addChild(pulse)
        
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        
        pulse.run(SKAction.repeat(pulseAction, count: 3)) {
            pulse.removeFromParent()
        }
    }
    
    public func playDragTrail(from: CGPoint, to: CGPoint) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let trail = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        trail.path = path
        trail.strokeColor = UIColor.white.withAlphaComponent(0.6)
        trail.lineWidth = 3
        trail.zPosition = 140
        
        scene.addChild(trail)
        
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        trail.run(SKAction.sequence([fade, remove]))
    }
    
    // MARK: - Small Effects
    
    public func playMergeBurst(at position: HexPosition, intensity: EffectIntensity) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let pixelPosition = position.toPixel(hexSize: 40, center: CGPoint(x: scene.size.width/2, y: scene.size.height/2))
        
        // 创建爆发粒子
        let particleCount = Int(intensity.rawValue * 20)
        
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
            particle.fillColor = getIntensityColor(intensity)
            particle.strokeColor = .clear
            particle.position = pixelPosition
            particle.zPosition = 160
            
            scene.addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...80) * CGFloat(intensity.rawValue)
            let endPoint = CGPoint(
                x: pixelPosition.x + cos(angle) * distance,
                y: pixelPosition.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPoint, duration: 0.6)
            let fade = SKAction.fadeOut(withDuration: 0.6)
            let scale = SKAction.scale(to: 0.1, duration: 0.6)
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([
                SKAction.group([move, fade, scale]),
                remove
            ]))
        }
    }
    
    public func playScorePopup(score: Int, at position: CGPoint, style: ScoreStyle) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let label = SKLabelNode(text: "+\(score)")
        label.fontSize = style.fontSize
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = getStyleColor(style)
        label.position = position
        label.zPosition = 180
        
        scene.addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: style.floatDistance, duration: 1.0)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([
            scale,
            SKAction.group([moveUp, fade]),
            remove
        ]))
    }
    
    public func playFeedbackText(_ text: String, at position: CGPoint, style: FeedbackStyle) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let label = SKLabelNode(text: text)
        label.fontSize = style.style.fontSize
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = getStyleColor(style.style)
        label.position = position
        label.zPosition = 180
        
        scene.addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: style.style.floatDistance, duration: 1.0)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([SKAction.group([moveUp, fade]), remove]))
    }
    
    // MARK: - Medium Effects
    
    public func playComboEffect(comboCount: Int, at position: CGPoint) {
        // 简化实现
        playScorePopup(score: comboCount, at: position, style: .excellent)
    }
    
    public func playUpgradeBeam(at position: HexPosition, swordType: SwordType) {
        // 简化实现
        guard let scene = scene else { return }
        let pixelPosition = position.toPixel(hexSize: 40, center: CGPoint(x: scene.size.width/2, y: scene.size.height/2))
        playTapRipple(at: pixelPosition)
    }
    
    public func playComboEndEffect(comboCount: Int) {
        // 简化实现
    }
    
    // MARK: - Large Effects
    
    public func playChainWave(from center: HexPosition, radius: Int) {
        // 简化实现
    }
    
    public func playAreaClearExplosion(at position: HexPosition) {
        guard let scene = scene else { return }
        let pixelPosition = position.toPixel(hexSize: 40, center: CGPoint(x: scene.size.width/2, y: scene.size.height/2))
        playTapRipple(at: pixelPosition)
        shakeScreen(intensity: .strong)
    }
    
    public func playRowClearEffect(row: Int) {
        // 简化实现
    }
    
    // MARK: - Epic Effects
    
    public func playUltimateEffect() {
        flashScreen(color: .purple, duration: 0.3)
        shakeScreen(intensity: .intense)
    }
    
    public func playWanJianGuiZongEffect() {
        flashScreen(color: .gold, duration: 1.0)
    }
    
    public func playQianKunDaNuoYiEffect() {
        // 简化实现
    }
    
    public func playJiuYinZhenJingEffect() {
        playSlowMotion(duration: 2.0, scale: 0.3)
        flashScreen(color: .blue, duration: 2.0)
    }
    
    // MARK: - Legendary Effects
    
    public func playDivineSwordEffect(at position: HexPosition) {
        flashScreen(color: .gold, duration: 0.5)
        shakeScreen(intensity: .extreme)
    }
    
    public func playVictoryEffect() {
        // 简化实现
    }
    
    // MARK: - Screen Effects
    
    public func shakeScreen(intensity: ShakeIntensity) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let shakeDistance = CGFloat(intensity.rawValue * 20)
        let shakeDuration = 0.1
        let shakeCount = 5
        
        var shakeActions: [SKAction] = []
        
        for _ in 0..<shakeCount {
            let randomX = CGFloat.random(in: -shakeDistance...shakeDistance)
            let randomY = CGFloat.random(in: -shakeDistance...shakeDistance)
            let move = SKAction.moveBy(x: randomX, y: randomY, duration: shakeDuration)
            shakeActions.append(move)
        }
        
        let returnToCenter = SKAction.move(to: CGPoint.zero, duration: shakeDuration)
        shakeActions.append(returnToCenter)
        
        let shakeSequence = SKAction.sequence(shakeActions)
        scene.run(shakeSequence)
    }
    
    public func flashScreen(color: ScreenFlashColor, duration: TimeInterval) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let flash = SKSpriteNode(color: getFlashColor(color), size: scene.size)
        flash.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        flash.zPosition = 300
        flash.alpha = 0.8
        
        scene.addChild(flash)
        
        let fade = SKAction.fadeOut(withDuration: duration)
        let remove = SKAction.removeFromParent()
        
        flash.run(SKAction.sequence([fade, remove]))
    }
    
    public func playSlowMotion(duration: TimeInterval, scale: Float) {
        guard isEffectsEnabled, let scene = scene else { return }
        
        scene.speed = CGFloat(scale)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            scene.speed = 1.0
        }
    }
    
    // MARK: - Background Effects
    
    public func startBackgroundParticles() {
        // 简化实现
    }
    
    public func stopBackgroundParticles() {
        backgroundParticles?.removeFromParent()
        backgroundParticles = nil
    }
    
    public func playShuffleEffect() {
        guard isEffectsEnabled, let scene = scene else { return }
        
        let rotation = SKAction.rotate(byAngle: .pi * 2, duration: 1.0)
        scene.run(rotation)
    }
    
    // MARK: - Helper Methods
    
    private func getIntensityColor(_ intensity: EffectIntensity) -> UIColor {
        switch intensity {
        case .micro: return .white
        case .small: return .cyan
        case .medium: return .blue
        case .large: return .purple
        case .epic: return .red
        case .legendary: return .systemYellow
        }
    }
    
    private func getStyleColor(_ style: ScoreStyle) -> UIColor {
        switch style.color {
        case "white": return .white
        case "cyan": return .cyan
        case "blue": return .blue
        case "purple": return .purple
        case "gold": return .systemYellow
        case "red": return .red
        default: return .white
        }
    }
    
    private func getFlashColor(_ color: ScreenFlashColor) -> UIColor {
        switch color {
        case .white: return .white
        case .gold: return .systemYellow
        case .red: return .red
        case .blue: return .blue
        case .purple: return .purple
        }
    }
}