#!/bin/bash

echo "🎵 ========== 音效系统验证 =========="
echo ""

# 检查音效文件
echo "📁 检查音效文件..."
SOUND_COUNT=$(find wjgz/Sounds -type f \( -name "*.mp3" -o -name "*.wav" \) ! -path "*/download/*" | wc -l | tr -d ' ')
echo "   找到 $SOUND_COUNT 个音效文件"

if [ "$SOUND_COUNT" -eq 27 ]; then
    echo "   ✅ 音效文件完整 (27/27)"
else
    echo "   ⚠️  音效文件不完整 ($SOUND_COUNT/27)"
fi

echo ""

# 检查代码文件
echo "📝 检查代码文件..."
FILES=(
    "wjgz/SoundManager.swift"
    "wjgz/AudioTestHelper.swift"
    "wjgz/GameScene.swift"
    "wjgz/GameViewController.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file 缺失"
    fi
done

echo ""

# 检查文档
echo "📚 检查文档..."
DOC_COUNT=$(find . -name "*音效*" -type f -name "*.md" | wc -l | tr -d ' ')
echo "   找到 $DOC_COUNT 个音效相关文档"

echo ""

# 检查目录结构
echo "📂 检查目录结构..."
DIRS=(
    "wjgz/Sounds/BGM"
    "wjgz/Sounds/SFX/Sword"
    "wjgz/Sounds/SFX/Merge"
    "wjgz/Sounds/SFX/Effects"
    "wjgz/Sounds/SFX/UI"
    "wjgz/Sounds/SFX/Ultimate"
)

for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        COUNT=$(ls -1 "$dir" | grep -E "\.(mp3|wav)$" | wc -l | tr -d ' ')
        echo "   ✅ $dir ($COUNT 个文件)"
    else
        echo "   ❌ $dir 不存在"
    fi
done

echo ""
echo "🎉 验证完成！"
echo ""
echo "下一步:"
echo "1. 运行: open wjgz.xcodeproj"
echo "2. 按 Cmd + R 运行游戏"
echo "3. 查看控制台输出"
echo ""
echo "===================================="
