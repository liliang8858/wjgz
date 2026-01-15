import SpriteKit

class Sword: SKSpriteNode {
    var type: SwordType
    // Axial coordinates (q, r)
    var gridPosition: (q: Int, r: Int)
    
    init(type: SwordType, gridPosition: (q: Int, r: Int)) {
        self.type = type
        self.gridPosition = gridPosition
        
        // Placeholder visuals
        super.init(texture: nil, color: type.color, size: CGSize(width: GameConfig.tileRadius * 1.6, height: GameConfig.tileRadius * 1.6))
        
        // Visual polish
        self.name = "sword"
        
        // Add label for MVP visualization
        let label = SKLabelNode(text: type.name)
        label.fontSize = 24
        label.fontName = "PingFangSC-Semibold"
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
        
        // Add a simple shape to look more like a token/sword base
        let shape = SKShapeNode(circleOfRadius: GameConfig.tileRadius * 0.8)
        shape.strokeColor = .white
        shape.lineWidth = 2
        shape.fillColor = .clear
        addChild(shape)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func upgrade() {
        if let newType = SwordType(rawValue: self.type.rawValue + 1) {
            self.type = newType
            self.color = newType.color
            if let label = self.children.first(where: { $0 is SKLabelNode }) as? SKLabelNode {
                label.text = newType.name
            }
            
            // Animation for upgrade
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            self.run(SKAction.sequence([scaleUp, scaleDown]))
        }
    }
}
