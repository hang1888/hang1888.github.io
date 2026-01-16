#!/bin/bash
cd /Users/hang/Documents/hang.github
export LANG=en_US.UTF-8

echo "--- 正在检查变更 ---"

# 1. 提取包名列表，全部转为小写并清理多余空格
existing_packages=$(grep "^Package: " Packages | awk '{print $2}' | tr '[:upper:]' '[:lower:]' | xargs)

NEED_SYNC=false

# 2. 遍历 debs 文件夹
for deb in debs/*.deb; do
    [ -e "$deb" ] || continue
    
    # 提取真实包名，转为小写进行对比
    real_pkg_name=$(dpkg-deb -f "$deb" Package 2>/dev/null | xargs)
    check_name=$(echo "$real_pkg_name" | tr '[:upper:]' '[:lower:]')

    # 使用逻辑匹配，确保不会因为大小写不同而重复追加
    if [[ ! " $existing_packages " =~ " $check_name " ]]; then
        echo "------------------------------------------------"
        echo "🆕 发现新插件: $real_pkg_name"
        
        # 扫描并清理路径，确保是相对路径 debs/
        new_info=$(dpkg-scanpackages -m "$deb" 2>/dev/null | sed "s|Filename: .*/debs/|Filename: debs/|g")
        
        if [ -n "$new_info" ]; then
            echo "$new_info" >> Packages
            echo "" >> Packages
            NEED_SYNC=true
            # 更新列表，防止同一次运行扫描到多个同包名的 deb
            existing_packages="$existing_packages $check_name"
        fi
    fi
done

# 3. 检查是否有手动文字修改（git status）
text_changed=$(git status --porcelain Packages)

if [ "$NEED_SYNC" = true ] || [ -n "$text_changed" ]; then
    echo "正在修正索引并同步到 GitHub..."
    # 修正路径、架构
    sed -i '' 's|Filename: .*/debs/|Filename: debs/|g' Packages
    sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
    
    # 生成索引压缩包
    bzip2 -c9 Packages > Packages.bz2
    gzip -c9 Packages > Packages.gz
    
    # 同步推送
    sudo chown -R hang:staff .
    git add .
    git commit -m "Safe Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 同步完成！手动修改已保留。"
else
    echo "👌 没有任何新插件或文字变动。"
fi
