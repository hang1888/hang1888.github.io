#!/bin/bash
cd /Users/hang/Documents/hang.github

# 解决终端中文显示可能存在的环境问题
export LANG=en_US.UTF-8

echo "--- 正在检查变更 ---"

# 1. 提取现有 Packages 里的包名列表
existing_packages=$(grep "^Package: " Packages | awk '{print $2}')

NEED_SYNC=false

# 2. 遍历 debs 文件夹
for deb in debs/*.deb; do
    [ -e "$deb" ] || continue
    
    # 提取包名（增加错误过滤）
    pkg_name=$(dpkg-deb -f "$deb" Package 2>/dev/null)
    
    # 如果包名读取失败（可能是文件名乱码），尝试用文件名提示
    display_name=${pkg_name:-$(basename "$deb")}

    # 对比是否已存在
    if ! echo "$existing_packages" | grep -q "^$pkg_name$"; then
        echo "------------------------------------------------"
        echo "🆕 发现新插件: $display_name"
        
        # 提取新信息并打印到屏幕
        new_info=$(dpkg-scanpackages -m "$deb" 2>/dev/null)
        
        if [ -n "$new_info" ]; then
            echo "🔍 追加信息如下:"
            echo "$new_info"
            echo "------------------------------------------------"
            
            # 真正追加
            echo "$new_info" >> Packages
            echo "" >> Packages
            NEED_SYNC=true
        else
            echo "⚠️ 警告: 无法扫描该文件 ($display_name)，请检查 deb 格式。"
        fi
    fi
done

# 3. 检查变更（手动修改或新加插件）
text_changed=$(git status --porcelain Packages)
release_changed=$(git status --porcelain Release)

if [ "$NEED_SYNC" = true ] || [ -n "$text_changed" ] || [ -n "$release_changed" ]; then
    echo "正在修正架构 (arm64e -> arm64) 并同步..."
    sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
    
    # 生成压缩包
    bzip2 -c9 Packages > Packages.bz2
    gzip -c9 Packages > Packages.gz
    
    # 权限与推送
    sudo chown -R hang:staff .
    git add .
    git commit -m "Incremental Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 同步完成！手动修改已保留。"
else
    echo "👌 没有任何变动。"
fi
