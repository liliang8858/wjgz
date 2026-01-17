//
//  AudioTestHelper.swift
//  wjgz
//
//  音效测试辅助工具 - 用于诊断音效问题
//

import Foundation
import AVFoundation

class AudioTestHelper {
    static let shared = AudioTestHelper()
    
    private init() {}
    
    /// 测试所有音效文件是否存在
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
            "combo",
            "combo_low",
            "combo_high",
            "success",
            "power_up",
            "ultimate_release",
            "level_complete",
            "game_over",
            "error",
            "sparkle"
        ]
        
        var foundCount = 0
        let totalCount = testSounds.count
        
        for soundName in testSounds {
            if let foundPath = findSoundFile(soundName) {
                print("✅ \(soundName) -> \(foundPath)")
                foundCount += 1
            } else {
                print("❌ \(soundName) -> 未找到")
            }
        }
        
        print("🧪 音效文件测试完成: \(foundCount)/\(totalCount) 个文件找到")
        
        if foundCount == 0 {
            print("⚠️ 没有找到任何音效文件，将使用系统音效")
        }
    }
    
    /// 查找音效文件
    private func findSoundFile(_ name: String) -> String? {
        let possiblePaths = [
            name,  // 首先尝试根目录（Xcode自动同步时的位置）
            "Sounds/SFX/UI/\(name)",
            "Sounds/SFX/Sword/\(name)",
            "Sounds/SFX/Merge/\(name)",
            "Sounds/SFX/Effects/\(name)",
            "Sounds/SFX/Ultimate/\(name)",
            "Sounds/SFX/\(name)",
            "Sounds/\(name)"
        ]
        
        let extensions = ["mp3", "wav", "m4a"]
        
        for basePath in possiblePaths {
            for ext in extensions {
                if Bundle.main.url(forResource: basePath, withExtension: ext) != nil {
                    return "\(basePath).\(ext)"
                }
            }
        }
        
        return nil
    }
    
    /// 测试系统音效
    func testSystemSounds() {
        print("🧪 测试系统音效...")
        
        SystemSoundHelper.shared.playTap()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SystemSoundHelper.shared.playSelect()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            SystemSoundHelper.shared.playSuccess()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SystemSoundHelper.shared.playError()
        }
        
        print("🧪 系统音效测试完成")
    }
    
    /// 列出Bundle中的所有音频文件
    func listBundleAudioFiles() {
        print("🧪 列出Bundle中的音频文件...")
        
        guard let bundlePath = Bundle.main.resourcePath else {
            print("❌ 无法获取Bundle路径")
            return
        }
        
        let fileManager = FileManager.default
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "caf"]
        
        func searchDirectory(_ path: String, prefix: String = "") {
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: path)
                for item in contents {
                    let itemPath = "\(path)/\(item)"
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
                        if isDirectory.boolValue {
                            searchDirectory(itemPath, prefix: "\(prefix)\(item)/")
                        } else {
                            let ext = (item as NSString).pathExtension.lowercased()
                            if audioExtensions.contains(ext) {
                                print("🎵 \(prefix)\(item)")
                            }
                        }
                    }
                }
            } catch {
                print("❌ 搜索目录失败: \(path) - \(error)")
            }
        }
        
        searchDirectory(bundlePath)
        print("🧪 Bundle音频文件列表完成")
    }
}