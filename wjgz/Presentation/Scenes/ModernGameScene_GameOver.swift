import SpriteKit

// MARK: - Game Over and Level Complete UI Extension
extension ModernGameScene {
    
    // MARK: - Game Over UI
    
    func showGameOverUI() {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.85)
        overlay.zPosition = 400
        addChild(overlay)
        
        // 音效
        SoundManager.shared.playGameOver()
        SystemSoundHelper.shared.playError() // 备用系统音效
        
        // 使用新的失败处理机制
        GameStateManager.shared.failLevel(currentLevel.id)
        
        let label = SKLabelNode(text: "修行未成")
        label.fontSize = 45
        label.fontName = "PingFangSC-Heavy"
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 80)
        overlay.addChild(label)
        
        let subLabel = SKLabelNode(text: "修为保留，再接再厉")
        subLabel.fontSize = 18
        subLabel.fontName = "PingFangSC-Regular"
        subLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        subLabel.position = CGPoint(x: 0, y: 40)
        overlay.addChild(subLabel)
        
        // 显示修为保留信息
        let cultivationLabel = SKLabelNode(text: "修为: \(GameStateManager.shared.cultivation) (已保留)")
        cultivationLabel.fontSize = 24
        cultivationLabel.fontName = "PingFangSC-Bold"
        cultivationLabel.fontColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        cultivationLabel.position = CGPoint(x: 0, y: 0)
        overlay.addChild(cultivationLabel)
        
        let scoreLabel = SKLabelNode(text: "本次得分: \(score)")
        scoreLabel.fontSize = 20
        scoreLabel.fontName = "PingFangSC-Regular"
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        scoreLabel.position = CGPoint(x: 0, y: -30)
        overlay.addChild(scoreLabel)
        
        let restartBtn = createButton(text: "再修一局", position: CGPoint(x: 0, y: -100))
        restartBtn.name = "restartBtn"
        overlay.addChild(restartBtn)
    }
    
    private func createButton(text: String, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        
        // 按钮背景
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 12)
        background.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        background.strokeColor = .white
        background.lineWidth = 2
        container.addChild(background)
        
        // 按钮文字
        let label = SKLabelNode(text: text)
        label.fontSize = 24
        label.fontName = "PingFangSC-Semibold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
    }
}