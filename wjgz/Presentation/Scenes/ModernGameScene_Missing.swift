import SpriteKit

// MARK: - Missing Methods Extension
extension ModernGameScene {
    
    // MARK: - Ultimate Pattern Display
    
    func setupUltimatePatternDisplay() {
        // 终极奥义显示现在融合在右面板中，这里只需要更新内容
        if let rightPanel = uiLayer.childNode(withName: "rightPanel") {
            setupUltimatePatternInPanel(rightPanel)
        }
    }
    
    func setupUltimatePatternInPanel(_ panel: SKNode) {
        // 移除之前的终极奥义显示
        panel.childNode(withName: "ultimatePatternContainer")?.removeFromParent()
        
        guard let pattern = currentLevel.rules.ultimatePattern else { return }
        
        // 创建终极奥义容器
        let patternContainer = SKNode()
        patternContainer.name = "ultimatePatternContainer"
        patternContainer.position = CGPoint(x: 0, y: -20)  // 在合成信息下方
        panel.addChild(patternContainer)
        
        // 奥义标题（小字）
        let titleLabel = SKLabelNode(text: "奥义")
        titleLabel.fontSize = 10
        titleLabel.fontName = "PingFangSC-Semibold"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8)
        titleLabel.position = CGPoint(x: 0, y: 8)
        patternContainer.addChild(titleLabel)
        
        // 奥义名称（紧凑显示）
        let nameLabel = SKLabelNode(text: pattern.name)
        nameLabel.fontSize = 12
        nameLabel.fontName = "PingFangSC-Bold"
        nameLabel.fontColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        nameLabel.position = CGPoint(x: 0, y: -5)
        patternContainer.addChild(nameLabel)
        
        // 触发条件图标（小图标）
        let iconContainer = createCompactUltimatePatternIcon(pattern: pattern)
        iconContainer.position = CGPoint(x: 0, y: -18)
        patternContainer.addChild(iconContainer)
    }
    
    private func createCompactUltimatePatternIcon(pattern: UltimatePattern) -> SKNode {
        let container = SKNode()
        
        switch pattern.triggerCondition {
        case .specificPattern:
            let icon = SKLabelNode(text: "🗡️")
            icon.fontSize = 12
            container.addChild(icon)
            
        case .swordTypeCount:
            let requiredCount = currentLevel.id <= 5 ? 5 : 8
            let icon = SKLabelNode(text: currentLevel.id <= 5 ? "⚔️\(requiredCount)" : "🌟\(requiredCount)")
            icon.fontSize = 10
            icon.fontName = "PingFangSC-Regular"
            icon.fontColor = SKColor(white: 0.9, alpha: 1.0)
            container.addChild(icon)
            
        case .comboCount:
            let requiredCombo = currentLevel.id <= 5 ? 3 : 5
            let icon = SKLabelNode(text: "⚡️\(requiredCombo)")
            icon.fontSize = 10
            icon.fontName = "PingFangSC-Regular"
            icon.fontColor = SKColor(white: 0.9, alpha: 1.0)
            container.addChild(icon)
            
        case .timeWindow:
            let icon = SKLabelNode(text: "⏰")
            icon.fontSize = 12
            container.addChild(icon)
        }
        
        return container
    }
}