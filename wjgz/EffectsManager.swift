//
//  EffectsManager.swift
//  wjgz
//
//  多巴胺特效管理器 - 让每个动作都有即时反馈
//

import SpriteKit
import AudioToolbox

// MARK: - Effect Types
enum EffectIntensity {
    case micro      // 微特效：点击、选中
    case small      // 小特效：单次合成
    case medium     // 中特效：连击、升级
    case large      // 大特效：连锁消除
    case epic       // 史诗特效：万剑归宗
    case legendary  // 传说特效：神剑出世
}

// MARK: - Particle Colors
struct ParticleColors {
    static let gold = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
    static let jade = UIColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0)
    static let purple = UIColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
    static let red = UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)
    static let white = UIColor.white
    static let blue = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
}

// MARK: - Effects Manager
class EffectsManager {
    
    weak var scene: SKScene?
    weak var effectLayer: SKNode?
    
    init(scene: SKScene, effectLayer: SKNode) {
        self.scene = scene
        self.effectLayer = effectLayer
    }
    
    // MARK: - Micro Effects (微特效)
    
    /// 点击涟漪效果
    func playTapRipple(at position: CGPoint) {
        guard let layer = effectLayer else { return }
        
        let ripple = SKShapeNode(circleOfRadius: 10)
        ripple.strokeColor = ParticleColors.gold.withAlphaComponent(0.8)
        ripple.fillColor = .clear
        ripple.lineWidth = 2
        ripple.position = position
        ripple.zPosition = 50
        layer.addChild(ripple)
        
        let expand = SKAction.scale(to: 3.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        ripple.run(SKAction.sequence([
            SKAction.group([expand, fade]),
            SKAction.removeFromParent()
        ]))
        
        // 音效
        SoundManager.shared.playTap()
    }
    
    /// 选中光环脉冲
    func playSelectPulse(on node: SKNode) {
        let pulse = SKShapeNode(circleOfRadius: 40)
        pulse.strokeColor = ParticleColors.gold.withAlphaComponent(0.6)
        pulse.fillColor = .clear
        pulse.lineWidth = 3
        pulse.glowWidth = 5
        pulse.position = .zero
        pulse.zPosition = -1
        pulse.name = "selectPulse"
        node.addChild(pulse)
        
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.4)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.4)
        let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.4)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.4)
        
        pulse.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([scaleUp, fadeIn]),
            SKAction.group([scaleDown, fadeOut])
        ])))
        
        // 音效
        SoundManager.shared.playSelect()
    }
    
    /// 拖拽轨迹
    func playDragTrail(at position: CGPoint, color: UIColor) {
        guard let layer = effectLayer else { return }
        
        let trail = SKShapeNode(circleOfRadius: 5)
        trail.fillColor = color.withAlphaComponent(0.6)
        trail.strokeColor = .clear
        trail.position = position
        trail.zPosition = 45
        layer.addChild(trail)
        
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let shrink = SKAction.scale(to: 0.1, duration: 0.3)
        trail.run(SKAction.sequence([
            SKAction.group([fade, shrink]),
            SKAction.removeFromParent()
        ]))
        
        // 音效
        SoundManager.shared.playDrag()
    }
    
    // MARK: - Small Effects (小特效)
    
    /// 合成爆发粒子
    func playMergeBurst(at position: CGPoint, color: UIColor, count: Int = 12, swordType: SwordType? = nil) {
        guard let layer = effectLayer else { return }
        
        for i in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            particle.fillColor = color
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.position = position
            particle.zPosition = 60
            layer.addChild(particle)
            
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2
            let distance = CGFloat.random(in: 50...80)
            let endPoint = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPoint, duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let scale = SKAction.scale(to: 0.2, duration: 0.4)
            
            particle.run(SKAction.sequence([
                SKAction.group([move, fade, scale]),
                SKAction.removeFromParent()
            ]))
        }
        
        // 中心闪光
        let flash = SKShapeNode(circleOfRadius: 20)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.position = position
        flash.zPosition = 65
        flash.blendMode = .add
        layer.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
        
        // 音效
        if let type = swordType {
            switch type {
            case .fan:
                SoundManager.shared.playMergeFan()
            case .ling:
                SoundManager.shared.playMergeLing()
            case .xian:
                SoundManager.shared.playMergeXian()
            case .shen:
                SoundManager.shared.playMergeShen()
            }
        }
    }
    
    /// 分数飘字
    func playScorePopup(at position: CGPoint, score: Int, isCombo: Bool = false) {
        guard let layer = effectLayer else { return }
        
        let text = isCombo ? "+\(score) 🔥" : "+\(score)"
        let label = SKLabelNode(text: text)
        label.fontSize = isCombo ? 28 : 22
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = isCombo ? ParticleColors.red : ParticleColors.gold
        label.position = position
        label.zPosition = 100
        label.setScale(0.5)
        layer.addChild(label)
        
        let moveUp = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: 60, duration: 0.8)
        let scaleUp = SKAction.scale(to: isCombo ? 1.3 : 1.0, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        
        label.run(SKAction.sequence([
            scaleUp, scaleDown,
            SKAction.group([moveUp, SKAction.sequence([SKAction.wait(forDuration: 0.5), fade])]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Medium Effects (中特效)
    
    /// 连击特效
    func playComboEffect(combo: Int, at position: CGPoint) {
        guard let layer = effectLayer, let scene = scene else { return }
        
        // 连击数字
        let comboLabel = SKLabelNode(text: "\(combo)连击!")
        comboLabel.fontSize = 40 + CGFloat(min(combo, 10)) * 2
        comboLabel.fontName = "PingFangSC-Heavy"
        comboLabel.fontColor = combo >= 5 ? ParticleColors.red : ParticleColors.gold
        comboLabel.position = CGPoint(x: 0, y: scene.size.height / 2 - 180)
        comboLabel.zPosition = 150
        comboLabel.setScale(0.3)
        layer.addChild(comboLabel)
        
        // 震动效果
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        ])
        
        comboLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            shake,
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        // 环形波纹
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: 30)
            ring.strokeColor = (combo >= 5 ? ParticleColors.red : ParticleColors.gold).withAlphaComponent(0.6)
            ring.fillColor = .clear
            ring.lineWidth = 3
            ring.position = position
            ring.zPosition = 55
            layer.addChild(ring)
            
            let delay = Double(i) * 0.1
            ring.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 4.0, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // 音效
        SoundManager.shared.playCombo(combo)
    }
    
    /// 升级光柱
    func playUpgradeBeam(at position: CGPoint, toType: SwordType) {
        guard let layer = effectLayer else { return }
        
        let beamHeight: CGFloat = 300
        let beam = SKShapeNode(rectOf: CGSize(width: 20, height: beamHeight))
        beam.fillColor = toType.glowColor.withAlphaComponent(0.8)
        beam.strokeColor = .white
        beam.lineWidth = 2
        beam.position = CGPoint(x: position.x, y: position.y + beamHeight / 2)
        beam.zPosition = 70
        beam.blendMode = .add
        beam.setScale(0)
        layer.addChild(beam)
        
        // 光柱动画
        beam.run(SKAction.sequence([
            SKAction.scaleX(to: 1.0, y: 0.1, duration: 0.1),
            SKAction.scaleY(to: 1.0, duration: 0.3),
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        // 底部光环
        let glow = SKShapeNode(circleOfRadius: 40)
        glow.fillColor = toType.glowColor.withAlphaComponent(0.5)
        glow.strokeColor = .clear
        glow.position = position
        glow.zPosition = 68
        glow.blendMode = .add
        layer.addChild(glow)
        
        glow.run(SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.4),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        // 音效
        SoundManager.shared.playLevelUp()
    }

    
    // MARK: - Large Effects (大特效)
    
    /// 连锁消除波
    func playChainWave(direction: ChainWaveDirection, at position: CGPoint) {
        guard let layer = effectLayer, let scene = scene else { return }
        
        let waveWidth: CGFloat = scene.size.width * 1.5
        let waveHeight: CGFloat = 30
        
        let wave: SKShapeNode
        switch direction {
        case .horizontal:
            wave = SKShapeNode(rectOf: CGSize(width: waveWidth, height: waveHeight))
            wave.position = position
        case .vertical:
            wave = SKShapeNode(rectOf: CGSize(width: waveHeight, height: scene.size.height))
            wave.position = position
        case .radial:
            wave = SKShapeNode(circleOfRadius: 20)
            wave.position = position
        case .cross:
            // 十字波
            playChainWave(direction: .horizontal, at: position)
            playChainWave(direction: .vertical, at: position)
            return
        }
        
        wave.fillColor = ParticleColors.jade.withAlphaComponent(0.7)
        wave.strokeColor = .white
        wave.lineWidth = 2
        wave.zPosition = 80
        wave.blendMode = .add
        layer.addChild(wave)
        
        let expand: SKAction
        switch direction {
        case .horizontal:
            expand = SKAction.scaleY(to: 3.0, duration: 0.4)
        case .vertical:
            expand = SKAction.scaleX(to: 3.0, duration: 0.4)
        case .radial:
            expand = SKAction.scale(to: 8.0, duration: 0.5)
        case .cross:
            expand = SKAction.scale(to: 1.0, duration: 0.1)
        }
        
        wave.run(SKAction.sequence([
            SKAction.group([expand, SKAction.fadeOut(withDuration: 0.4)]),
            SKAction.removeFromParent()
        ]))
        
        // 剑气粒子
        for _ in 0..<20 {
            let particle = createSwordParticle()
            particle.position = position
            layer.addChild(particle)
            
            var endPoint: CGPoint
            switch direction {
            case .horizontal:
                endPoint = CGPoint(
                    x: position.x + CGFloat.random(in: -200...200),
                    y: position.y + CGFloat.random(in: -30...30)
                )
            case .vertical:
                endPoint = CGPoint(
                    x: position.x + CGFloat.random(in: -30...30),
                    y: position.y + CGFloat.random(in: -200...200)
                )
            case .radial, .cross:
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let dist = CGFloat.random(in: 80...150)
                endPoint = CGPoint(
                    x: position.x + cos(angle) * dist,
                    y: position.y + sin(angle) * dist
                )
            }
            
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: endPoint, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // 屏幕震动
        shakeScreen(intensity: .medium)
        
        // 音效
        SoundManager.shared.playChainClear()
    }
    
    enum ChainWaveDirection {
        case horizontal, vertical, radial, cross
    }
    
    /// 创建剑气粒子
    private func createSwordParticle() -> SKNode {
        let particle = SKShapeNode(rectOf: CGSize(width: 4, height: 15))
        particle.fillColor = ParticleColors.jade
        particle.strokeColor = .white
        particle.lineWidth = 1
        particle.zPosition = 75
        particle.zRotation = CGFloat.random(in: 0...(2 * .pi))
        return particle
    }
    
    /// 区域清除爆炸
    func playAreaClearExplosion(at position: CGPoint) {
        guard let layer = effectLayer else { return }
        
        // 中心爆炸
        let explosion = SKShapeNode(circleOfRadius: 10)
        explosion.fillColor = ParticleColors.purple
        explosion.strokeColor = .white
        explosion.lineWidth = 3
        explosion.position = position
        explosion.zPosition = 85
        explosion.blendMode = .add
        layer.addChild(explosion)
        
        explosion.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 6.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // 六边形碎片
        for i in 0..<6 {
            let shard = createHexShard()
            shard.position = position
            layer.addChild(shard)
            
            let angle = CGFloat(i) / 6.0 * .pi * 2
            let distance: CGFloat = 100
            let endPoint = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            shard.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: endPoint, duration: 0.5),
                    SKAction.rotate(byAngle: .pi * 2, duration: 0.5),
                    SKAction.sequence([
                        SKAction.wait(forDuration: 0.3),
                        SKAction.fadeOut(withDuration: 0.2)
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        shakeScreen(intensity: .large)
        
        // 音效
        SoundManager.shared.playExplosion()
    }
    
    private func createHexShard() -> SKNode {
        let path = CGMutablePath()
        let radius: CGFloat = 15
        for i in 0..<6 {
            let angle = CGFloat(i) / 6.0 * .pi * 2 - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        
        let shard = SKShapeNode(path: path)
        shard.fillColor = ParticleColors.purple.withAlphaComponent(0.8)
        shard.strokeColor = .white
        shard.lineWidth = 2
        shard.zPosition = 82
        return shard
    }
    
    // MARK: - Epic Effects (史诗特效)
    
    /// 万剑归宗特效
    func playUltimateEffect() {
        guard let layer = effectLayer, let scene = scene else { return }
        
        // 音效先行
        SoundManager.shared.playUltimate()
        
        // 1. 全屏闪白
        let flash = SKShapeNode(rectOf: scene.size)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.position = .zero
        flash.zPosition = 200
        flash.alpha = 0
        layer.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // 2. 飞剑雨
        for i in 0..<50 {
            let sword = createFlyingSword()
            sword.position = CGPoint(
                x: CGFloat.random(in: -scene.size.width/2...scene.size.width/2),
                y: scene.size.height/2 + 50
            )
            layer.addChild(sword)
            
            let delay = Double(i) * 0.02
            let duration = 0.5 + Double.random(in: 0...0.3)
            let endY = -scene.size.height/2 - 50
            
            sword.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.moveTo(y: endY, duration: duration),
                    SKAction.sequence([
                        SKAction.wait(forDuration: duration * 0.7),
                        SKAction.fadeOut(withDuration: duration * 0.3)
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // 3. 中心能量球
        let energyBall = SKShapeNode(circleOfRadius: 30)
        energyBall.fillColor = ParticleColors.gold
        energyBall.strokeColor = .white
        energyBall.lineWidth = 3
        energyBall.glowWidth = 20
        energyBall.position = .zero
        energyBall.zPosition = 180
        energyBall.setScale(0)
        layer.addChild(energyBall)
        
        energyBall.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.wait(forDuration: 0.3),
            SKAction.group([
                SKAction.scale(to: 10.0, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // 4. 文字
        let textLabel = SKLabelNode(text: "万剑归宗!")
        textLabel.fontSize = 60
        textLabel.fontName = "PingFangSC-Heavy"
        textLabel.fontColor = ParticleColors.gold
        textLabel.position = .zero
        textLabel.zPosition = 250
        textLabel.setScale(0.1)
        layer.addChild(textLabel)
        
        textLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // 5. 持续震动
        shakeScreen(intensity: .epic, duration: 2.0)
    }
    
    private func createFlyingSword() -> SKNode {
        let sword = SKShapeNode(rectOf: CGSize(width: 6, height: 30))
        sword.fillColor = ParticleColors.gold
        sword.strokeColor = .white
        sword.lineWidth = 1
        sword.zPosition = 190
        sword.zRotation = .pi
        
        // 剑尾光效
        let trail = SKShapeNode(rectOf: CGSize(width: 4, height: 20))
        trail.fillColor = ParticleColors.gold.withAlphaComponent(0.5)
        trail.strokeColor = .clear
        trail.position = CGPoint(x: 0, y: -25)
        sword.addChild(trail)
        
        return sword
    }
    
    // MARK: - Legendary Effects (传说特效)
    
    /// 神剑出世特效
    func playDivineSwordEffect(at position: CGPoint) {
        guard let layer = effectLayer, let scene = scene else { return }
        
        // 音效
        SoundManager.shared.playMergeShen()
        
        // 1. 天降神光
        let lightBeam = SKShapeNode(rectOf: CGSize(width: 60, height: scene.size.height * 2))
        lightBeam.fillColor = ParticleColors.gold.withAlphaComponent(0.6)
        lightBeam.strokeColor = .clear
        lightBeam.position = CGPoint(x: position.x, y: 0)
        lightBeam.zPosition = 170
        lightBeam.blendMode = .add
        lightBeam.alpha = 0
        layer.addChild(lightBeam)
        
        lightBeam.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // 2. 金色粒子环绕
        for i in 0..<30 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
            particle.fillColor = ParticleColors.gold
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.zPosition = 175
            
            let startAngle = CGFloat(i) / 30.0 * .pi * 2
            let radius: CGFloat = 100
            particle.position = CGPoint(
                x: position.x + cos(startAngle) * radius,
                y: position.y + sin(startAngle) * radius
            )
            layer.addChild(particle)
            
            // 螺旋向中心
            let path = UIBezierPath()
            path.move(to: particle.position)
            
            var currentRadius = radius
            var currentAngle = startAngle
            for _ in 0..<20 {
                currentRadius -= 5
                currentAngle += 0.3
                let point = CGPoint(
                    x: position.x + cos(currentAngle) * currentRadius,
                    y: position.y + sin(currentAngle) * currentRadius
                )
                path.addLine(to: point)
            }
            
            let follow = SKAction.follow(path.cgPath, asOffset: false, orientToPath: false, duration: 1.0)
            particle.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.02),
                SKAction.group([follow, SKAction.fadeOut(withDuration: 1.0)]),
                SKAction.removeFromParent()
            ]))
        }
        
        // 3. 神剑文字
        let text = SKLabelNode(text: "「神剑出世」")
        text.fontSize = 45
        text.fontName = "PingFangSC-Heavy"
        text.fontColor = ParticleColors.gold
        text.position = CGPoint(x: 0, y: position.y + 100)
        text.zPosition = 200
        text.setScale(0.5)
        text.alpha = 0
        layer.addChild(text)
        
        text.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.scale(to: 1.2, duration: 0.2)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        shakeScreen(intensity: .legendary, duration: 1.5)
    }

    
    // MARK: - Screen Effects
    
    enum ShakeIntensity {
        case light, medium, large, epic, legendary
        
        var offset: CGFloat {
            switch self {
            case .light: return 3
            case .medium: return 6
            case .large: return 10
            case .epic: return 15
            case .legendary: return 20
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .light: return 0.2
            case .medium: return 0.3
            case .large: return 0.4
            case .epic: return 0.6
            case .legendary: return 0.8
            }
        }
    }
    
    /// 屏幕震动
    func shakeScreen(intensity: ShakeIntensity, duration: TimeInterval? = nil) {
        guard let scene = scene else { return }
        
        let offset = intensity.offset
        let shakeDuration = duration ?? intensity.duration
        let shakeCount = Int(shakeDuration / 0.05)
        
        var actions: [SKAction] = []
        for i in 0..<shakeCount {
            let factor = 1.0 - (Double(i) / Double(shakeCount)) // 衰减
            let dx = CGFloat.random(in: -offset...offset) * CGFloat(factor)
            let dy = CGFloat.random(in: -offset...offset) * CGFloat(factor)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.05))
        }
        actions.append(SKAction.move(to: .zero, duration: 0.05))
        
        scene.run(SKAction.sequence(actions))
    }
    
    /// 屏幕闪烁
    func flashScreen(color: UIColor, duration: TimeInterval = 0.3) {
        guard let layer = effectLayer, let scene = scene else { return }
        
        let flash = SKShapeNode(rectOf: scene.size)
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.position = .zero
        flash.zPosition = 300
        flash.alpha = 0
        layer.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: duration * 0.3),
            SKAction.fadeOut(withDuration: duration * 0.7),
            SKAction.removeFromParent()
        ]))
    }
    
    /// 慢动作效果
    func playSlowMotion(duration: TimeInterval = 1.0, slowFactor: CGFloat = 0.3) {
        guard let scene = scene else { return }
        
        scene.speed = slowFactor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(slowFactor)) {
            let restore = SKAction.customAction(withDuration: 0.3) { node, elapsed in
                let progress = elapsed / 0.3
                scene.speed = slowFactor + (1.0 - slowFactor) * progress
            }
            scene.run(restore)
        }
    }
    
    // MARK: - Feedback Text Effects
    
    /// 浮动反馈文字
    func showFeedbackText(_ text: String, at position: CGPoint, style: FeedbackStyle) {
        guard let layer = effectLayer else { return }
        
        let label = SKLabelNode(text: "「\(text)」")
        label.fontSize = style.fontSize
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = style.color
        label.position = position
        label.zPosition = 150
        label.setScale(0.3)
        layer.addChild(label)
        
        // 光晕背景
        if style.hasGlow {
            let glow = SKShapeNode(rectOf: CGSize(width: label.frame.width + 40, height: label.frame.height + 20), cornerRadius: 10)
            glow.fillColor = style.color.withAlphaComponent(0.2)
            glow.strokeColor = .clear
            glow.position = .zero
            glow.zPosition = -1
            glow.blendMode = .add
            label.addChild(glow)
        }
        
        let scaleUp = SKAction.scale(to: style.maxScale, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: style.floatDistance, duration: style.duration)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        
        label.run(SKAction.sequence([
            scaleUp, scaleDown,
            SKAction.group([moveUp, SKAction.sequence([SKAction.wait(forDuration: style.duration - 0.4), fade])]),
            SKAction.removeFromParent()
        ]))
    }
    
    enum FeedbackStyle {
        case normal      // 普通
        case good        // 不错
        case great       // 很好
        case excellent   // 极好
        case perfect     // 完美
        case legendary   // 传说
        
        var fontSize: CGFloat {
            switch self {
            case .normal: return 24
            case .good: return 28
            case .great: return 32
            case .excellent: return 38
            case .perfect: return 44
            case .legendary: return 52
            }
        }
        
        var color: UIColor {
            switch self {
            case .normal: return .white
            case .good: return ParticleColors.jade
            case .great: return ParticleColors.blue
            case .excellent: return ParticleColors.purple
            case .perfect: return ParticleColors.gold
            case .legendary: return ParticleColors.red
            }
        }
        
        var maxScale: CGFloat {
            switch self {
            case .normal: return 1.0
            case .good: return 1.1
            case .great: return 1.2
            case .excellent: return 1.3
            case .perfect: return 1.4
            case .legendary: return 1.5
            }
        }
        
        var floatDistance: CGFloat {
            switch self {
            case .normal: return 50
            case .good: return 60
            case .great: return 70
            case .excellent: return 80
            case .perfect: return 90
            case .legendary: return 100
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .normal: return 1.0
            case .good: return 1.2
            case .great: return 1.4
            case .excellent: return 1.6
            case .perfect: return 1.8
            case .legendary: return 2.0
            }
        }
        
        var hasGlow: Bool {
            switch self {
            case .normal, .good: return false
            default: return true
            }
        }
    }
    
    // MARK: - Continuous Effects
    
    /// 能量充满脉冲
    func startEnergyFullPulse(around node: SKNode) {
        let pulse = SKShapeNode(circleOfRadius: 50)
        pulse.strokeColor = ParticleColors.gold.withAlphaComponent(0.6)
        pulse.fillColor = .clear
        pulse.lineWidth = 3
        pulse.glowWidth = 10
        pulse.position = .zero
        pulse.zPosition = -1
        pulse.name = "energyPulse"
        node.addChild(pulse)
        
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.6)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.6)
        let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.6)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.6)
        
        pulse.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([scaleUp, fadeIn]),
            SKAction.group([scaleDown, fadeOut])
        ])), withKey: "pulse")
    }
    
    func stopEnergyFullPulse(on node: SKNode) {
        node.childNode(withName: "energyPulse")?.removeFromParent()
    }
    
    /// 背景粒子流
    func startBackgroundParticles() {
        guard let layer = effectLayer, let _ = scene else { return }
        
        let emitAction = SKAction.run { [weak self] in
            self?.emitBackgroundParticle()
        }
        let wait = SKAction.wait(forDuration: 0.5)
        layer.run(SKAction.repeatForever(SKAction.sequence([emitAction, wait])), withKey: "bgParticles")
    }
    
    private func emitBackgroundParticle() {
        guard let layer = effectLayer, let scene = scene else { return }
        
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
        particle.fillColor = ParticleColors.gold.withAlphaComponent(0.3)
        particle.strokeColor = .clear
        particle.position = CGPoint(
            x: CGFloat.random(in: -scene.size.width/2...scene.size.width/2),
            y: -scene.size.height/2 - 20
        )
        particle.zPosition = 5
        layer.addChild(particle)
        
        let endY = scene.size.height/2 + 20
        let duration = Double.random(in: 4...8)
        let drift = CGFloat.random(in: -50...50)
        
        particle.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveTo(y: endY, duration: duration),
                SKAction.moveBy(x: drift, y: 0, duration: duration),
                SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.6, duration: duration * 0.3),
                    SKAction.wait(forDuration: duration * 0.4),
                    SKAction.fadeOut(withDuration: duration * 0.3)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    func stopBackgroundParticles() {
        effectLayer?.removeAction(forKey: "bgParticles")
    }
    
    // MARK: - Level Specific Effects
    
    /// 关卡开始特效
    func playLevelStartEffect(levelName: String) {
        guard let layer = effectLayer, let scene = scene else { return }
        
        // 背景渐变
        let overlay = SKShapeNode(rectOf: scene.size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.position = .zero
        overlay.zPosition = 400
        layer.addChild(overlay)
        
        // 关卡名称
        let nameLabel = SKLabelNode(text: levelName)
        nameLabel.fontSize = 50
        nameLabel.fontName = "PingFangSC-Heavy"
        nameLabel.fontColor = ParticleColors.gold
        nameLabel.position = .zero
        nameLabel.zPosition = 410
        nameLabel.alpha = 0
        layer.addChild(nameLabel)
        
        // 动画序列
        nameLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.6),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    /// 关卡完成庆祝
    func playLevelCompleteEffect(stars: Int) {
        guard let layer = effectLayer, let _ = scene else { return }
        
        // 音效
        SoundManager.shared.playLevelComplete()
        
        // 彩色粒子爆发
        for _ in 0..<50 {
            let colors: [UIColor] = [ParticleColors.gold, ParticleColors.jade, ParticleColors.purple, ParticleColors.red]
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...10))
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.position = CGPoint(x: 0, y: -50)
            particle.zPosition = 450
            layer.addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 100...250)
            let endPoint = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance - 50
            )
            
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: endPoint, duration: 1.0),
                    SKAction.sequence([
                        SKAction.wait(forDuration: 0.6),
                        SKAction.fadeOut(withDuration: 0.4)
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // 星星动画
        for i in 0..<stars {
            let star = SKLabelNode(text: "⭐️")
            star.fontSize = 60
            star.position = CGPoint(x: CGFloat(i - 1) * 80, y: 100)
            star.zPosition = 460
            star.setScale(0)
            layer.addChild(star)
            
            star.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5 + Double(i) * 0.3),
                SKAction.group([
                    SKAction.scale(to: 1.3, duration: 0.2),
                    SKAction.fadeIn(withDuration: 0.2)
                ]),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            
            // 每颗星星的音效
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.3) {
                SoundManager.shared.playStar()
            }
        }
        
        shakeScreen(intensity: .large)
    }
}
