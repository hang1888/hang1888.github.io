#!/bin/bash
cd /Users/hang/Documents/hang.github

echo "--- 正在检查变更 ---"

# 1. 检测是否有新 DEB 文件 (通过数量对比)
deb_count=$(ls debs/*.deb 2>/dev/null | wc -l)
pkg_count=$(grep -c "^Package: " Packages 2>/dev/null)

# 2. 检测 Packages 里的文字是否有手动改动 (通过 git 状态)
text_changed=$(git status --porcelain Packages)
release_changed=$(git status --porcelain Release)

if [ "$deb_count" -ne "$pkg_count" ]; then
    echo "🆕 检测到新 DEB，正在重新扫描并修正架构..."
    dpkg-scanpackages -m debs > Packages
    sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
    # 扫描后需要重新压缩
    NEED_SYNC=true
elif [ -n "$text_changed" ] || [ -n "$release_changed" ]; then
    echo "✍️ 检测到手动修改了 Packages 或 Release 文字，准备同步..."
    NEED_SYNC=true
else
    # 检查是否有 Packages.bz2/gz 还没生成的情况
    if [ ! -f "Packages.bz2" ] || [ ! -f "Packages.gz" ]; then
        NEED_SYNC=true
    else
        NEED_SYNC=false
    fi
fi

if [ "$NEED_SYNC" = true ]; then
    echo "正在生成压缩包..."
    bzip2 -c9 Packages > Packages.bz2
    gzip -c9 Packages > Packages.gz

    echo "正在同步到 GitHub..."
    sudo chown -R hang:staff ./*.sh ./Packages* ./Release ./debs
    git add .
    git commit -m "Auto/Manual Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 同步已完成！"
else
    echo "👌 没有任何新文件或文字修改，无需操作。"
fi
