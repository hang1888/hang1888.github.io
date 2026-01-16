#!/bin/bash
cd /Users/hang/Documents/hang.github

echo "--- 正在检查变更 ---"

# 1. 提取 Packages 里的包名
existing_packages=$(grep "^Package: " Packages | awk '{print $2}')

NEED_SYNC=false

# 2. 检查是否有新 deb (只追加新内容，不覆盖旧的)
for deb in debs/*.deb; do
    [ -e "$deb" ] || continue
    pkg_name=$(dpkg-deb -f "$deb" Package)
    
    if ! echo "$existing_packages" | grep -q "^$pkg_name$"; then
        echo "🆕 发现新插件: $pkg_name，正在追加..."
        dpkg-scanpackages -m "$deb" >> Packages
        echo "" >> Packages
        NEED_SYNC=true
    fi
done

# 3. 检查 Packages 或 Release 文字是否被你手动修改过
text_changed=$(git status --porcelain Packages)
release_changed=$(git status --porcelain Release)

if [ "$NEED_SYNC" = true ] || [ -n "$text_changed" ] || [ -n "$release_changed" ]; then
    echo "正在修正架构并处理索引..."
    # 统一 arm64e -> arm64 (防止 RootHide 分组)
    sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
    
    # 打包压缩
    bzip2 -c9 Packages > Packages.bz2
    gzip -c9 Packages > Packages.gz
    
    # 修正权限并同步
    sudo chown -R hang:staff .
    git add .
    git commit -m "Auto Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 全部同步完成！手动修改已保留，新插件已追加。"
else
    echo "👌 没有任何变化，无需同步。"
fi
