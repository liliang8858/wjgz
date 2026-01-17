//
//  AudioTestHelper.swift
//  wjgz
//
//  音效测试辅助工具
//

import Foundation
import AVFoundation

class AudioTestHelper {
    static let shared = AudioTestHelper()
    
    private init() {}
    
    /// 测试所有音效文件是否可以正常加载
    func testAllSoundFiles() {
        print("🧪 开始音效文件测试...")
        
        let testSounds = [
            "button_click",
            "sword_whoosh", 
            "sword_clash",
            "sword_draw",
            "sword_sheath",
            "merge_small",
            "merge_medium", 
            "merge_large",
            "merge_epic",
            "success",
            "combo",
            "game_over",
            "level_complete",
            "star_collect"
        ]
        
        var foundCount = 0
        var missingCount = 0
        
        for soundName in testSounds {
            if testSoundFile(soundName) {
                foundCount += 1
            } else {
                missingCount += 1
            }
        }
        
        print("📊 音效测试结果:")
        print("   ✅ 找到: \(foundCount) 个")
        print("   ❌ 缺失: \(missingCount) 个")
        
        if missingCount > 0 {
            print("💡 提示: 请确保音效文件已添加到 Xcode 项目的 'Copy Bundle Resources' 中")
        } else {
            print("🎉 所有音效文件都已正确加载！")
        }
    }
    
    private func testSoundFile(_ name: String) -> Bool {
        let possiblePaths = [
            "Sounds/SFX/UI/\(name)",
            "Sounds/SFX/Sword/\(name)",
            "Sounds/SFX/Merge/\(name)",
            "Sounds/SFX/Effects/\(name)",
            "Sounds/SFX/Ultimate/\(name)",
            "Sounds/SFX/\(name)",
            "Sounds/\(name)",
            name
        ]
        
        let extensions = ["mp3", "wav", "m4a"]
        
        for basePath in possiblePaths {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: basePath, withExtension: ext) {
                    print("   ✅ \(name) -> \(basePath).\(ext)")
                    return true
                }
            }
        }
        
        print("   ❌ \(name) -> 未找到")
        return false
    }
    
    /// 测试音效播放
    func testSoundPlayback() {
        print("🔊 测试音效播放...")
        
        // 测试系统音效
        print("播放系统音效...")
        AudioServicesPlaySystemSound(1104) // 点击音效
        
        // 等待一秒后测试SoundManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("播放SoundManager音效...")
            SoundManager.shared.playTap()
        }
    }
}