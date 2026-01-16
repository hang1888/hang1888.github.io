#!/bin/bash
cd /Users/hang/Documents/hang.github

echo "--- 正在检查变更 ---"

# 1. 获取现有 Packages 里的所有包名（用于对比）
existing_packages=$(grep "^Package: " Packages | awk '{print $2}')

NEED_SYNC=false

# 2. 遍历 debs 文件夹
for deb in debs/*.deb; do
    [ -e "$deb" ] || continue
    # 提取当前 deb 的包名
    pkg_name=$(dpkg-deb -f "$deb" Package)
    
    # 如果 Packages 里没有这个包名，说明是新加的
    if ! echo "$existing_packages" | grep -q "^$pkg_name$"; then
        echo "🆕 发现新插件: $pkg_name，正在追加信息..."
        dpkg-scanpackages -m "$deb" >> Packages
        echo "" >> Packages
        NEED_SYNC=true
    fi
done

# 3. 检查 Packages 是否有手动文字修改（git 状态）
text_changed=$(git status --porcelain Packages)

if [ "$NEED_SYNC" = true ] || [ -n "$text_changed" ]; then
    echo "正在统一修正架构并清理格式..."
    # 修正 arm64e -> arm64 (防止 RootHide 分组)，并清理重复空行
    sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
    
    echo "正在生成压缩包并同步到 GitHub..."
    bzip2 -c9 Packages > Packages.bz2
    gzip -c9 Packages > Packages.gz
    
    git add .
    git commit -m "Incremental Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 同步已完成！新插件已追加，原有手动修改已保留。"
else
    echo "👌 没有发现新插件或文字修改，无需同步。"
fi
