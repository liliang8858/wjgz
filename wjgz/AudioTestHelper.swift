//
//  AudioTestHelper.swift
//  wjgz
//
//  音效测试辅助工具
//

import Foundation
import AVFoundation

class AudioTestHelper {
    
    /// 测试所有音效文件是否存在
    static func testAllSoundFiles() {
        print("\n🎵 ========== 音效文件测试 ==========")
        
        let soundFiles: [(category: String, files: [(name: String, path: String)])] = [
            ("背景音乐", [
                ("主游戏音乐", "Sounds/BGM/background_main"),
                ("史诗音乐", "Sounds/BGM/background_epic"),
                ("菜单音乐", "Sounds/BGM/background_menu")
            ]),
            ("剑类音效", [
                ("挥剑", "Sounds/SFX/Sword/sword_whoosh"),
                ("碰撞", "Sounds/SFX/Sword/sword_clash"),
                ("拔剑", "Sounds/SFX/Sword/sword_draw"),
                ("收剑", "Sounds/SFX/Sword/sword_sheath")
            ]),
            ("合成音效", [
                ("凡剑", "Sounds/SFX/Merge/merge_small"),
                ("灵剑", "Sounds/SFX/Merge/merge_medium"),
                ("仙剑", "Sounds/SFX/Merge/merge_large"),
                ("神剑", "Sounds/SFX/Merge/merge_epic")
            ]),
            ("特效音效", [
                ("连击", "Sounds/SFX/Effects/combo"),
                ("低连击", "Sounds/SFX/Effects/combo_low"),
                ("高连击", "Sounds/SFX/Effects/combo_high"),
                ("爆炸", "Sounds/SFX/Effects/explosion"),
                ("能量", "Sounds/SFX/Effects/power_up"),
                ("成功", "Sounds/SFX/Effects/success"),
                ("快速移动", "Sounds/SFX/Effects/whoosh"),
                ("闪光", "Sounds/SFX/Effects/sparkle"),
                ("错误", "Sounds/SFX/Effects/error")
            ]),
            ("UI音效", [
                ("按钮", "Sounds/SFX/UI/button_click"),
                ("完成", "Sounds/SFX/UI/level_complete"),
                ("结束", "Sounds/SFX/UI/game_over"),
                ("星星", "Sounds/SFX/UI/star_collect")
            ]),
            ("终极技音效", [
                ("蓄力", "Sounds/SFX/Ultimate/ultimate_charge"),
                ("释放", "Sounds/SFX/Ultimate/ultimate_release"),
                ("冲击", "Sounds/SFX/Ultimate/ultimate_impact")
            ])
        ]
        
        let extensions = ["mp3", "wav", "m4a"]
        var totalFiles = 0
        var foundFiles = 0
        var missingFiles: [(category: String, name: String, path: String)] = []
        
        for category in soundFiles {
            print("\n📁 \(category.category):")
            for file in category.files {
                totalFiles += 1
                var found = false
                var foundExt = ""
                
                for ext in extensions {
                    if let url = Bundle.main.url(forResource: file.path, withExtension: ext) {
                        found = true
                        foundExt = ext
                        foundFiles += 1
                        
                        // 获取文件大小
                        if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int {
                            let sizeKB = Double(fileSize) / 1024.0
                            print("  ✅ \(file.name) (\(String(format: "%.1f", sizeKB))KB, .\(ext))")
                        } else {
                            print("  ✅ \(file.name) (.\(ext))")
                        }
                        break
                    }
                }
                
                if !found {
                    print("  ❌ \(file.name) - 未找到")
                    missingFiles.append((category.category, file.name, file.path))
                }
            }
        }
        
        print("\n📊 统计:")
        print("  总文件数: \(totalFiles)")
        print("  找到: \(foundFiles) ✅")
        print("  缺失: \(totalFiles - foundFiles) ❌")
        print("  完成度: \(String(format: "%.1f", Double(foundFiles) / Double(totalFiles) * 100))%")
        
        if !missingFiles.isEmpty {
            print("\n⚠️  缺失的文件:")
            for file in missingFiles {
                print("  - [\(file.category)] \(file.name)")
                print("    路径: \(file.path)")
            }
            print("\n💡 提示: 请确保音效文件已添加到 Xcode 项目的 'Copy Bundle Resources' 中")
        } else {
            print("\n🎉 所有音效文件都已正确加载！")
        }
        
        print("\n====================================\n")
    }
    
    /// 测试音效播放
    static func testSoundPlayback() {
        print("\n🔊 ========== 音效播放测试 ==========")
        
        // 测试背景音乐
        print("测试背景音乐...")
        SoundManager.shared.playBackgroundMusic("background_main")
        
        // 延迟测试音效
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("测试剑音效...")
            SoundManager.shared.playSelect()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("测试合成音效...")
            SoundManager.shared.playMergeXian()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("测试连击音效...")
            SoundManager.shared.playCombo(5)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            print("测试完成音效...")
            SoundManager.shared.playLevelComplete()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            print("✅ 音效播放测试完成")
            print("====================================\n")
        }
    }
    
    /// 快速测试（在 GameViewController 中调用）
    static func quickTest() {
        testAllSoundFiles()
        
        // 如果需要测试播放，取消下面的注释
        // testSoundPlayback()
    }
}
