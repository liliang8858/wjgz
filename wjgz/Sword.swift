import SpriteKit

public class Sword: SKSpriteNode {
    public var type: SwordType
    public var hexPosition: HexPosition
    
    // Legacy compatibility property for grid position
    public var gridPosition: (q: Int, r: Int) {
        get {
            return (q: hexPosition.q, r: hexPosition.r)
        }
        set {
            hexPosition = HexPosition(q: newValue.q, r: newValue.r)
        }
    }
    
    private var glowNode: SKShapeNode?
    private var floatAction: SKAction?
    
    init(type: SwordType, position: HexPosition) {
        self.type = type
        self.hexPosition = position
        
        let size = CGSize(width: GameConfig.tileRadius * 1.8, height: GameConfig.tileRadius * 2.0)
        super.init(texture: nil, color: .clear, size: size)
        
        self.name = "sword"
        setupVisuals()
        startFloatingAnimation()
    }
    
    // Legacy compatibility initializer
    convenience init(type: SwordType, gridPosition: (q: Int, r: Int)) {
        let hexPos = HexPosition(q: gridPosition.q, r: gridPosition.r)
        self.init(type: type, position: hexPos)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals() {
        // Remove old children
        self.removeAllChildren()
        
        // Hexagonal sword shape
        let hexPath = createHexPath(radius: GameConfig.tileRadius * 0.85)
        let hexShape = SKShapeNode(path: hexPath)
        hexShape.fillColor = type.color
        hexShape.strokeColor = .white
        hexShape.lineWidth = 1.5
        hexShape.name = "hexShape"
        addChild(hexShape)
        
        // Glow effect (Volume glow)
        let glow = SKShapeNode(path: hexPath)
        glow.fillColor = .clear
        glow.strokeColor = type.glowColor
        glow.lineWidth = 3
        glow.alpha = 0.6
        glow.glowWidth = 12
        glow.name = "glow"
        glowNode = glow
        addChild(glow)
        
        // Sword type label
        let label = SKLabelNode(text: type.name)
        label.fontSize = 28
        label.fontName = "Ma Shan Zheng" // 使用设计要求的书法字体
        if label.fontName == nil { label.fontName = "PingFangSC-Heavy" }
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 5
        label.name = "label"
        addChild(label)
        
        // Add Specific VFX layers based on type
        addTierSpecificVFX()
    }
    
    private func addTierSpecificVFX() {
        switch type {
        case .fan:
            // 凡剑：剑尖红热效果
            let hotTip = SKShapeNode(circleOfRadius: 10)
            hotTip.fillColor = UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 0.6)
            hotTip.strokeColor = .clear
            hotTip.position = CGPoint(x: 0, y: -GameConfig.tileRadius * 0.5)
            hotTip.zPosition = 1
            hotTip.glowWidth = 10
            addChild(hotTip)
            
            hotTip.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 1.0),
                SKAction.fadeAlpha(to: 0.8, duration: 1.0)
            ])))
            
        case .ling:
            // 灵剑：蓝色流光效果
            let stream = SKShapeNode(rectOf: CGSize(width: 40, height: 4))
            stream.fillColor = UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 0.4)
            stream.strokeColor = .clear
            stream.zPosition = 2
            stream.glowWidth = 5
            addChild(stream)
            
            stream.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 30, duration: 1.5),
                    SKAction.fadeOut(withDuration: 1.5)
                ]),
                SKAction.run { stream.position = CGPoint(x: 0, y: -30); stream.alpha = 0.4 }
            ])))
            
            // 气泡
            for i in 0..<3 {
                let bubble = SKShapeNode(circleOfRadius: 3)
                bubble.fillColor = .white
                bubble.alpha = 0.5
                bubble.position = CGPoint(x: CGFloat.random(in: -15...15), y: -20)
                bubble.zPosition = 3
                addChild(bubble)
                
                bubble.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.wait(forDuration: Double(i) * 0.4),
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 40, duration: 1.2),
                        SKAction.fadeOut(withDuration: 1.2)
                    ]),
                    SKAction.run { bubble.position = CGPoint(x: CGFloat.random(in: -15...15), y: -20); bubble.alpha = 0.5 }
                ])))
            }
            
        case .xian:
            // 仙剑：紫色光晕和符文环
            let aura = SKShapeNode(circleOfRadius: 45)
            aura.fillColor = .clear
            aura.strokeColor = UIColor(red: 0.58, green: 0.2, blue: 0.92, alpha: 0.4)
            aura.lineWidth = 2
            aura.glowWidth = 15
            aura.zPosition = -1
            addChild(aura)
            aura.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 2.0),
                SKAction.scale(to: 0.9, duration: 2.0)
            ])))
            
            // 符文环 (使用虚线模拟)
            let runeCircle = SKShapeNode(circleOfRadius: 40)
            runeCircle.fillColor = .clear
            runeCircle.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.6)
            runeCircle.lineWidth = 1
            // 注意：SpriteKit的SKShapeNode不支持lineDashPattern，我们使用实线代替
            runeCircle.zPosition = 4
            addChild(runeCircle)
            runeCircle.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 8.0)))
            
        case .shen:
            // 神剑：强烈金光和闪烁
            let divineGlow = SKShapeNode(circleOfRadius: 50)
            divineGlow.fillColor = .clear
            divineGlow.strokeColor = .orange
            divineGlow.lineWidth = 3
            divineGlow.glowWidth = 20
            divineGlow.zPosition = -1
            addChild(divineGlow)
            
            for _ in 0..<5 {
                let spark = SKShapeNode(rectOf: CGSize(width: 2, height: 2))
                spark.fillColor = .white
                spark.position = .zero
                spark.zPosition = 6
                addChild(spark)
                
                let angle = CGFloat.random(in: 0...(.pi * 2))
                let dist = CGFloat.random(in: 20...50)
                spark.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.wait(forDuration: Double.random(in: 0...1.0)),
                    SKAction.group([
                        SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.5),
                        SKAction.fadeOut(withDuration: 0.5),
                        SKAction.scale(to: 2.0, duration: 0.5)
                    ]),
                    SKAction.run { spark.position = .zero; spark.alpha = 1.0; spark.setScale(1.0) }
                ])))
            }
        }
    }
    
    private func createHexPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func startFloatingAnimation() {
        let floatUp = SKAction.moveBy(x: 0, y: 4, duration: 1.0)
        let floatDown = SKAction.moveBy(x: 0, y: -4, duration: 1.0)
        floatUp.timingMode = .easeInEaseOut
        floatDown.timingMode = .easeInEaseOut
        
        let delay = Double.random(in: 0...0.5)
        let wait = SKAction.wait(forDuration: delay)
        let float = SKAction.repeatForever(SKAction.sequence([floatUp, floatDown]))
        
        floatAction = SKAction.sequence([wait, float])
        self.run(floatAction!, withKey: "float")
    }
    
    func upgrade() {
        // 如果已经是神剑，触发特殊效果而不是升级
        if self.type == .shen {
            triggerDivineSwordMerge()
            return
        }
        
        guard let newType = SwordType(rawValue: self.type.rawValue + 1) else { return }
        
        self.type = newType
        
        // Upgrade animation
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let flash = SKAction.run { [weak self] in
            self?.setupVisuals()
        }
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        
        // Particle burst
        let burst = SKAction.run { [weak self] in
            self?.createUpgradeParticles()
        }
        
        self.run(SKAction.sequence([scaleUp, flash, burst, scaleDown]))
    }
    
    private func triggerDivineSwordMerge() {
        // 神剑合成触发特殊效果
        let flash = SKAction.run { [weak self] in
            self?.createDivineFlash()
        }
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        
        self.run(SKAction.sequence([scaleUp, flash, scaleDown]))
        
        // 通知场景触发特殊奖励
        NotificationCenter.default.post(
            name: NSNotification.Name("DivineSwordMerged"),
            object: self
        )
    }
    
    private func createDivineFlash() {
        // 创建神剑合成的特殊光效
        let flash = SKShapeNode(circleOfRadius: 60)
        flash.fillColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8)
        flash.strokeColor = .white
        flash.lineWidth = 3
        flash.position = .zero
        flash.zPosition = 10
        flash.blendMode = .add
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.3),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    private func createUpgradeParticles() {
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: 4)
            particle.fillColor = type.glowColor
            particle.strokeColor = .clear
            particle.position = .zero
            particle.zPosition = 10
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance: CGFloat = 60
            let endPoint = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            
            let move = SKAction.move(to: endPoint, duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([SKAction.group([move, fade]), remove]))
        }
    }
    
    func playSelectAnimation() {
        glowNode?.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.fadeAlpha(to: 0.4, duration: 0.3)
        ])), withKey: "selectPulse")
    }
    
    func stopSelectAnimation() {
        glowNode?.removeAction(forKey: "selectPulse")
        glowNode?.alpha = 0.6
    }
    
    func changeType(to newType: SwordType) {
        self.type = newType
        setupVisuals()
        
        // Change animation
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        self.run(flash)
    }
}
