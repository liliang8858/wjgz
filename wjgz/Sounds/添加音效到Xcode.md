# 如何将音效添加到 Xcode 项目

## 方法 1：拖拽添加（推荐）

### 步骤：

1. **打开 Xcode 项目**
   - 打开 `wjgz.xcodeproj`

2. **在项目导航器中找到 wjgz 文件夹**
   - 左侧项目导航器中找到 `wjgz` 文件夹

3. **拖拽 Sounds 文件夹**
   - 从 Finder 中拖拽整个 `wjgz/Sounds` 文件夹到 Xcode 的 `wjgz` 文件夹下
   
4. **配置导入选项**
   弹出对话框时，确保勾选：
   - ✅ **Copy items if needed** （复制文件到项目）
   - ✅ **Create folder references** （创建文件夹引用，保持目录结构）
   - ✅ **Add to targets: wjgz** （添加到 wjgz 目标）

5. **验证**
   - 在项目导航器中应该能看到蓝色的 Sounds 文件夹
   - 点击项目 → wjgz target → Build Phases → Copy Bundle Resources
   - 确认所有音效文件都在列表中

## 方法 2：手动添加

### 步骤：

1. **选择项目目标**
   - 点击项目名称 `wjgz`
   - 选择 `wjgz` target

2. **打开 Build Phases**
   - 点击顶部的 "Build Phases" 标签

3. **展开 Copy Bundle Resources**
   - 找到 "Copy Bundle Resources" 部分
   - 点击 "+" 按钮

4. **添加音效文件**
   - 点击 "Add Other..."
   - 浏览到 `wjgz/Sounds` 目录
   - 选择所有音效文件
   - 点击 "Add"

## 验证音效文件

### 在代码中测试：

```swift
// 在 GameViewController 的 viewDidLoad 中添加测试代码
override func viewDidLoad() {
    super.viewDidLoad()
    
    // 测试音效加载
    testSoundFiles()
    
    // ... 其他代码
}

func testSoundFiles() {
    let soundFiles = [
        // BGM
        "Sounds/BGM/background_main",
        "Sounds/BGM/background_epic",
        "Sounds/BGM/background_menu",
        
        // Sword
        "Sounds/SFX/Sword/sword_whoosh",
        "Sounds/SFX/Sword/sword_clash",
        "Sounds/SFX/Sword/sword_draw",
        "Sounds/SFX/Sword/sword_sheath",
        
        // Merge
        "Sounds/SFX/Merge/merge_small",
        "Sounds/SFX/Merge/merge_medium",
        "Sounds/SFX/Merge/merge_large",
        "Sounds/SFX/Merge/merge_epic",
        
        // Effects
        "Sounds/SFX/Effects/combo",
        "Sounds/SFX/Effects/explosion",
        "Sounds/SFX/Effects/power_up",
        "Sounds/SFX/Effects/success",
        "Sounds/SFX/Effects/whoosh",
        "Sounds/SFX/Effects/sparkle",
        
        // UI
        "Sounds/SFX/UI/button_click",
        "Sounds/SFX/UI/level_complete",
        "Sounds/SFX/UI/game_over",
        "Sounds/SFX/UI/star_collect",
        
        // Ultimate
        "Sounds/SFX/Ultimate/ultimate_charge",
        "Sounds/SFX/Ultimate/ultimate_release",
        "Sounds/SFX/Ultimate/ultimate_impact"
    ]
    
    let extensions = ["mp3", "wav", "m4a"]
    var foundCount = 0
    var missingFiles: [String] = []
    
    for soundFile in soundFiles {
        var found = false
        for ext in extensions {
            if Bundle.main.url(forResource: soundFile, withExtension: ext) != nil {
                found = true
                foundCount += 1
                break
            }
        }
        if !found {
            missingFiles.append(soundFile)
        }
    }
    
    print("✅ 找到 \(foundCount) 个音效文件")
    if !missingFiles.isEmpty {
        print("❌ 缺失的音效文件:")
        missingFiles.forEach { print("   - \($0)") }
    }
}
```

## 常见问题

### Q1: 音效文件不播放？
**A:** 检查以下几点：
1. 文件是否在 "Copy Bundle Resources" 中
2. 文件名和扩展名是否正确
3. 音频格式是否支持（MP3, WAV, M4A）
4. 设备音量是否打开

### Q2: 找不到音效文件？
**A:** 
1. 确保使用 "Create folder references"（蓝色文件夹）而不是 "Create groups"（黄色文件夹）
2. 检查文件路径是否正确
3. Clean Build Folder (Cmd + Shift + K) 然后重新编译

### Q3: WAV 文件太大？
**A:** 
1. 可以使用在线工具转换为 MP3
2. 或者使用 ffmpeg 命令：
```bash
ffmpeg -i input.wav -codec:a libmp3lame -qscale:a 2 output.mp3
```

### Q4: 如何批量转换 WAV 到 MP3？
**A:** 在 Sounds 目录下运行：
```bash
for file in **/*.wav; do
    ffmpeg -i "$file" -codec:a libmp3lame -qscale:a 2 "${file%.wav}.mp3"
done
```

## 音效文件大小优化

当前音效文件总大小约：**~10MB**

如果需要减小包体积：

1. **降低比特率**
   ```bash
   ffmpeg -i input.mp3 -b:a 96k output.mp3
   ```

2. **使用 M4A 格式**（iOS 原生支持，压缩率更好）
   ```bash
   ffmpeg -i input.mp3 -c:a aac -b:a 96k output.m4a
   ```

3. **裁剪音效长度**
   - 音效尽量控制在 1-3 秒
   - 背景音乐可以适当长一些

## 启动背景音乐

在 `GameScene.swift` 的 `didMove(to:)` 方法中添加：

```swift
override func didMove(to view: SKView) {
    // ... 其他初始化代码
    
    // 启动背景音乐
    SoundManager.shared.playBackgroundMusic("background_main")
    
    // 设置音量
    SoundManager.shared.setMusicVolume(0.4)
    SoundManager.shared.setSFXVolume(0.7)
}
```

## 🎉 完成！

添加完成后，游戏中的每个动作都会有对应的音效反馈，大大提升游戏的多巴胺体验！
