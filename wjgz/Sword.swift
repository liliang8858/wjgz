import SpriteKit

class Sword: SKSpriteNode {
    var type: SwordType
    var gridPosition: (q: Int, r: Int)
    
    private var glowNode: SKShapeNode?
    private var floatAction: SKAction?
    
    init(type: SwordType, gridPosition: (q: Int, r: Int)) {
        self.type = type
        self.gridPosition = gridPosition
        
        let size = CGSize(width: GameConfig.tileRadius * 1.8, height: GameConfig.tileRadius * 2.0)
        super.init(texture: nil, color: .clear, size: size)
        
        self.name = "sword"
        setupVisuals()
        startFloatingAnimation()
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
        hexShape.lineWidth = 2
        hexShape.name = "hexShape"
        addChild(hexShape)
        
        // Glow effect
        let glow = SKShapeNode(path: hexPath)
        glow.fillColor = .clear
        glow.strokeColor = type.glowColor
        glow.lineWidth = 4
        glow.alpha = 0.6
        glow.glowWidth = 8
        glow.name = "glow"
        glowNode = glow
        addChild(glow)
        
        // Sword type label
        let label = SKLabelNode(text: type.name)
        label.fontSize = 26
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = type == .fan ? .darkGray : .white
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        label.name = "label"
        addChild(label)
        
        // Inner shine for higher tier swords
        if type.rawValue >= 2 {
            let shine = SKShapeNode(circleOfRadius: GameConfig.tileRadius * 0.3)
            shine.fillColor = UIColor.white.withAlphaComponent(0.3)
            shine.strokeColor = .clear
            shine.position = CGPoint(x: -8, y: 8)
            shine.zPosition = 1
            addChild(shine)
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
