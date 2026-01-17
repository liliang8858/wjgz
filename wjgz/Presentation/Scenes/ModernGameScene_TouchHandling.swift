import SpriteKit

// MARK: - Touch Handling Extension
extension ModernGameScene {
    
    // MARK: - Touch Handling Methods (完全迁移老代码)
    
    func handleDrop(sword: Sword, at targetIndex: (q: Int, r: Int)) {
        let targetKey = "\(targetIndex.q)_\(targetIndex.r)"
        
        // 检查是否是封锁格子
        if blockedCells.contains(targetKey) {
            effectsManager.showFeedbackText("此处封印!", at: sword.position, style: .normal)
            returnToOriginalPosition(sword)
            return
        }
        
        // 检查边界
        let distance = (abs(targetIndex.q) + abs(targetIndex.q + targetIndex.r) + abs(targetIndex.r)) / 2
        if distance > currentLevel.gridRadius {
            returnToOriginalPosition(sword)
            return
        }
        
        // 检查是否是有效格子
        if !shouldCreateTile(q: targetIndex.q, r: targetIndex.r, formation: currentLevel.formationType, radius: currentLevel.gridRadius) {
            returnToOriginalPosition(sword)
            return
        }
        
        if let targetSword = grid[targetKey] {
            if targetSword != sword {
                swapSwords(sword, targetSword)
                incrementMove()
                checkForMatches()
            } else {
                returnToOriginalPosition(sword)
            }
        } else {
            moveSword(sword, to: targetIndex)
            incrementMove()
            checkForMatches()
        }
    }
    
    private func incrementMove() {
        // 如果在连消阶段，不消耗步数
        if isInComboPhase {
            return
        }
        
        moveCount += 1
        
        if let moveLimit = currentLevel.rules.moveLimit {
            let remaining = moveLimit - moveCount
            updateMoveDisplay()
            
            if remaining <= 5 {
                effectsManager.flashScreen(color: .red, duration: 0.1)
            }
            
            if remaining <= 0 {
                triggerGameOver()
            }
        }
    }
    
    internal func swapSwords(_ sword1: Sword, _ sword2: Sword) {
        let pos1 = sword1.gridPosition
        let pos2 = sword2.gridPosition
        
        // 记录交换操作，用于可能的回退
        pendingSwap = SwapOperation(
            sword1: sword1,
            sword2: sword2,
            originalPos1: pos1,
            originalPos2: pos2
        )
        
        grid["\(pos1.q)_\(pos1.r)"] = sword2
        grid["\(pos2.q)_\(pos2.r)"] = sword1
        
        sword1.gridPosition = pos2
        sword2.gridPosition = pos1
        
        sword1.run(SKAction.group([
            SKAction.move(to: hexToPixel(q: pos2.q, r: pos2.r), duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        sword2.run(SKAction.move(to: hexToPixel(q: pos1.q, r: pos1.r), duration: 0.2))
        
        // 重置zPosition
        sword1.zPosition = 20
        sword2.zPosition = 20
    }
    
    private func moveSword(_ sword: Sword, to index: (Int, Int)) {
        let oldKey = "\(sword.gridPosition.q)_\(sword.gridPosition.r)"
        let newKey = "\(index.0)_\(index.1)"
        
        grid.removeValue(forKey: oldKey)
        grid[newKey] = sword
        
        sword.gridPosition = (q: index.0, r: index.1)
        sword.run(SKAction.group([
            SKAction.move(to: hexToPixel(q: index.0, r: index.1), duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        // 重置zPosition
        sword.zPosition = 20
        
        // 清除待处理的交换操作
        pendingSwap = nil
    }
    
    private func returnToOriginalPosition(_ sword: Sword) {
        if let pos = originalPosition {
            sword.run(SKAction.group([
                SKAction.move(to: pos, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            // 重置zPosition
            sword.zPosition = 20
            effectsManager.shakeScreen(intensity: .light)
        }
    }
    
    // MARK: - Touch Handling Override Methods
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 优先处理 UI 按钮（即使游戏结束也要响应）
        let nodes = nodes(at: location)
        
        // 按优先级顺序检查按钮，确保下一关按钮优先于重新挑战按钮
        for node in nodes {
            if node.name == "nextLevelBtn" {
                goToNextLevel()
                return
            }
        }
        
        for node in nodes {
            if node.name == "restartBtn" {
                restartGame()
                return
            }
        }
        
        for node in nodes {
            if node.name == "skipTutorial" {
                skipTutorial()
                return
            }
            if node.name == "closeUltimateHint" {
                closeUltimateHint()
                return
            }
        }
        
        // 如果游戏结束，不处理游戏内交互
        guard !isGameOver else { return }
        
        // 点击涟漪特效
        effectsManager.playTapRipple(at: location)
        // 播放触摸音效
        SystemSoundHelper.shared.playTap()
        SoundManager.shared.playTap()
        
        for node in nodes {
            if node.name == "ultimateBtn" || node.parent?.name == "ultimateBtn" {
                if !ultimateButton.isHidden {
                    triggerUltimate()
                }
                return
            }
            if let sword = node as? Sword {
                draggedSword = sword
                originalPosition = sword.position
                originalGridIndex = sword.gridPosition
                lastDragPosition = location
                sword.zPosition = 100
                sword.run(SKAction.scale(to: 1.2, duration: 0.1))
                effectsManager.playSelectPulse(on: sword)
                break
            }
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        let location = touch.location(in: self)
        sword.position = location
        
        // 拖拽轨迹特效
        if let lastPos = lastDragPosition {
            let distance = hypot(location.x - lastPos.x, location.y - lastPos.y)
            if distance > 15 {
                effectsManager.playDragTrail(at: lastPos, color: sword.type.glowColor)
                lastDragPosition = location
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sword = draggedSword, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        sword.childNode(withName: "selectPulse")?.removeFromParent()
        let gridIndex = pixelToHex(point: location)
        handleDrop(sword: sword, at: gridIndex)
        
        // 重置zPosition
        sword.zPosition = 20
        
        draggedSword = nil
        originalPosition = nil
        originalGridIndex = nil
        lastDragPosition = nil
    }
}