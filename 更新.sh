#!/bin/bash
cd /Users/hang/Documents/hang.github
export LANG=en_US.UTF-8

echo "--- 正在检查变更 ---"

# 1. 提取包名列表（忽略大小写）
existing_packages=$(grep "^Package: " Packages | awk '{print $2}' | tr '[:upper:]' '[:lower:]' | xargs)

NEED_SYNC=false
UPDATED_PLUGINS=""

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
            UPDATED_PLUGINS="$UPDATED_PLUGINS $real_pkg_name"
        fi
    fi
done

# 3. 检查所有文件变更（含图片、HTML、Packages 手动修改）
# 获取简短的状态列表
changed_files=$(git status --porcelain)

if [ "$NEED_SYNC" = true ] || [ -n "$changed_files" ]; then
    echo "------------------------------------------------"
    echo "📢 检测到以下内容更新："
    
    # 如果有手动修改的文件，直接打印出来
    if [ -n "$changed_files" ]; then
        echo "修改的文件清单："
        git status -s
    fi
    
    # 如果有新插件，打印插件名
    if [ "$NEED_SYNC" = true ]; then
        echo "新增插件清单：$UPDATED_PLUGINS"
    fi
    echo "------------------------------------------------"

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
    # 动态 commit 信息，包含时间
    git commit -m "Update: $(date +'%Y-%m-%d %H:%M:%S') $UPDATED_PLUGINS"
    git push
    echo "✅ 全部同步完成！"
else
    echo "👌 没有任何新插件、文字修改或图片变动。"
fi