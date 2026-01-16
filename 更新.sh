#!/bin/bash
cd /Users/hang/Documents/hang.github
export LANG=en_US.UTF-8

echo "--- 正在检查变更 (含 about.png 检查) ---"

# 1. 提取包名列表（忽略大小写）
existing_packages=$(grep "^Package: " Packages | awk '{print $2}' | tr '[:upper:]' '[:lower:]' | xargs)

NEED_SYNC=false

# 2. 遍历并增量追加新 deb
for deb in debs/*.deb; do
    [ -e "$deb" ] || continue
    real_pkg_name=$(dpkg-deb -f "$deb" Package 2>/dev/null | xargs)
    check_name=$(echo "$real_pkg_name" | tr '[:upper:]' '[:lower:]')

    if [[ ! " $existing_packages " =~ " $check_name " ]]; then
        echo "------------------------------------------------"
        echo "🆕 发现新插件: $real_pkg_name"
        new_info=$(dpkg-scanpackages -m "$deb" 2>/dev/null | sed "s|Filename: .*/debs/|Filename: debs/|g")
        
        if [ -n "$new_info" ]; then
            echo "$new_info" >> Packages
            echo "" >> Packages
            NEED_SYNC=true
            existing_packages="$existing_packages $check_name"
        fi
    fi
done

# 3. 检查所有文件变更（包括 Packages 手动修改和 about.png 图片更新）
# git status --porcelain 会列出所有有变动的文件
changed_files=$(git status --porcelain)

if [ "$NEED_SYNC" = true ] || [ -n "$changed_files" ]; then
    echo "发现变更，正在处理并同步..."
    
    # 修正 Packages 的路径和架构
    if [ -f Packages ]; then
        sed -i '' 's|Filename: .*/debs/|Filename: debs/|g' Packages
        sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
        
        # 重新生成压缩索引
        bzip2 -c9 Packages > Packages.bz2
        gzip -c9 Packages > Packages.gz
    fi
    
    # 修正权限
    sudo chown -R hang:staff .
    
    # Git 同步
    git add .
    git commit -m "Update packages and assets: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 全部同步完成！(含 Packages 和图片等资源)"
else
    echo "👌 没有任何新插件、文字修改或图片变动。"
fi
