import SpriteKit

// MARK: - Level Complete and Playability Extension
extension ModernGameScene {
    
    // MARK: - Playability Check
    
    func performPlayabilityCheck() {
        if !hasAnyPossibleMatches() {
            fixBoardState()
        }
    }
    
    func hasAnyPossibleMatches() -> Bool {
        var visited = Set<String>()
        
        for (key, sword) in grid {
            if visited.contains(key) { continue }
            
            let matches = findMatches(startNode: sword)
            if matches.count >= currentLevel.rules.minMergeCount { return true }
            
            for m in matches {
                visited.insert("\(m.gridPosition.q)_\(m.gridPosition.r)")
            }
        }
        return false
    }
    
    private func fixBoardState() {
        let allSwords = Array(grid.values)
        if allSwords.count >= 3 {
            // 随机选择3把剑，将它们改为相同类型
            let selectedSwords = allSwords.shuffled().prefix(3)
            let targetType = selectedSwords.first?.type ?? .fan
            
            for sword in selectedSwords.dropFirst() {
                sword.changeType(to: targetType)
            }
            
            effectsManager.showFeedbackText("剑阵重组!", at: .zero, style: .good)
        }
    }
    
    // MARK: - Level Complete UI (Simplified)
    
    func showLevelCompleteUI(stars: Int, completedLevelId: Int) {
        // 创建半透明背景
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.9)
        overlay.strokeColor = .clear
        overlay.zPosition = 400
        overlay.name = "levelCompleteOverlay"
        overlay.alpha = 0
        overlay.isUserInteractionEnabled = false
        addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.3))
        
        // 主容器
        let mainContainer = SKNode()
        mainContainer.position = CGPoint(x: 0, y: 0)
        mainContainer.zPosition = 1
        overlay.addChild(mainContainer)
        
        // 🎉 更醒目的标题
        let titleLabel = SKLabelNode(text: "🎉 关卡完成！🎉")
        titleLabel.fontSize = 42
        titleLabel.fontName = "PingFangSC-Heavy"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 180)
        mainContainer.addChild(titleLabel)
        
        // 添加脉冲动画
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        titleLabel.run(SKAction.repeatForever(pulse))
        
        // 关卡信息
        let levelInfo = SKLabelNode(text: "第\(completedLevelId)关 - \(currentLevel.name)")
        levelInfo.fontSize = 24
        levelInfo.fontName = "PingFangSC-Semibold"
        levelInfo.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0)
        levelInfo.position = CGPoint(x: 0, y: 130)
        mainContainer.addChild(levelInfo)
        
        // 星星显示
        for i in 0..<3 {
            let star = SKLabelNode(text: i < stars ? "⭐️" : "☆")
            star.fontSize = 40
            star.position = CGPoint(x: CGFloat(i - 1) * 60, y: 80)
            mainContainer.addChild(star)
            
            if i < stars {
                star.setScale(0)
                star.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.3 + Double(i) * 0.2),
                    SKAction.group([
                        SKAction.scale(to: 1.2, duration: 0.2),
                        SKAction.rotate(byAngle: .pi * 2, duration: 0.4)
                    ]),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
            }
        }
        
        // 分数信息
        let scoreInfo = SKLabelNode(text: "本关得分: \(score)")
        scoreInfo.fontSize = 20
        scoreInfo.fontName = "PingFangSC-Regular"
        scoreInfo.fontColor = .white
        scoreInfo.position = CGPoint(x: 0, y: 20)
        mainContainer.addChild(scoreInfo)
        
        // 修为信息
        let cultivationInfo = SKLabelNode(text: "总修为: \(GameStateManager.shared.cultivation + score)")
        cultivationInfo.fontSize = 18
        cultivationInfo.fontName = "PingFangSC-Regular"
        cultivationInfo.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        cultivationInfo.position = CGPoint(x: 0, y: -10)
        mainContainer.addChild(cultivationInfo)
        
        // 按钮区域
        let nextLevelId = completedLevelId + 1
        let hasNextLevel = nextLevelId <= LevelConfig.shared.levels.count
        
        if hasNextLevel {
            // 🚀 更醒目的下一关按钮
            let nextBtn = createStyledButton(
                text: "🚀 进入第\(nextLevelId)关 🚀",
                position: CGPoint(x: 0, y: -70),
                color: SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0),
                name: "nextLevelBtn",
                fontSize: 28
            )
            mainContainer.addChild(nextBtn)
            
            // 添加按钮脉冲动画
            let buttonPulse = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.6),
                SKAction.scale(to: 1.0, duration: 0.6)
            ])
            nextBtn.run(SKAction.repeatForever(buttonPulse))
            
            // 重新挑战按钮
            let restartBtn = createStyledButton(
                text: "重新挑战",
                position: CGPoint(x: 0, y: -140),
                color: SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
                name: "restartBtn",
                fontSize: 18
            )
            mainContainer.addChild(restartBtn)
        } else {
            // 重新挑战按钮
            let restartBtn = createStyledButton(
                text: "重新挑战",
                position: CGPoint(x: 0, y: -70),
                color: SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0),
                name: "restartBtn"
            )
            mainContainer.addChild(restartBtn)
        }
        

    }
    
    // 创建样式化按钮
    private func createStyledButton(text: String, position: CGPoint, color: SKColor, name: String, fontSize: CGFloat = 26) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = name
        container.zPosition = 1
        
        // 按钮背景
        let background = SKShapeNode(rectOf: CGSize(width: 240, height: 55), cornerRadius: 12)
        background.fillColor = color
        background.strokeColor = .white
        background.lineWidth = 2
        background.name = name
        container.addChild(background)
        
        // 按钮文字
        let label = SKLabelNode(text: text)
        label.fontSize = fontSize
        label.fontName = "PingFangSC-Semibold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)
        
        return container
    }
}