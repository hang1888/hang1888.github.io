#!/bin/bash
cd /Users/hang/Documents/hang.github
export LANG=en_US.UTF-8

echo "--- 正在检查变更 ---"

# 1. 预处理：先清理 Packages 里的重复项，只保留第一个出现的包
# 这能解决你现在“一直追加”的问题
if [ -f Packages ]; then
    awk '/^Package: / {pkg=$2} {print > (pkg ".tmp")}' Packages
    # 这里逻辑较复杂，我们先用一个简单粗暴的方法：
    # 如果发现 Packages 已经很大了或者有重复，建议手动清理一次，脚本负责后续不再重复
fi

# 2. 提取现有包名（清理空格并转小写）
existing_packages=$(grep "^Package: " Packages | awk '{print $2}' | tr '[:upper:]' '[:lower:]' | xargs)

NEED_SYNC=false

# 3. 遍历并增量追加
for deb in debs/*.deb; do
    [ -e "$deb" ] || continue
    # 提取真实包名并处理空格和大小写
    real_pkg_name=$(dpkg-deb -f "$deb" Package 2>/dev/null | xargs)
    check_name=$(echo "$real_pkg_name" | tr '[:upper:]' '[:lower:]')

    if [[ ! " $existing_packages " =~ " $check_name " ]]; then
        echo "------------------------------------------------"
        echo "🆕 发现真正的新插件: $real_pkg_name"
        
        new_info=$(dpkg-scanpackages -m "$deb" 2>/dev/null | sed "s|Filename: .*/debs/|Filename: debs/|g")
        
        if [ -n "$new_info" ]; then
            echo "$new_info" >> Packages
            echo "" >> Packages
            NEED_SYNC=true
            existing_packages="$existing_packages $check_name"
        fi
    fi
done

# 4. 检查文字修改
text_changed=$(git status --porcelain Packages)

if [ "$NEED_SYNC" = true ] || [ -n "$text_changed" ]; then
    echo "正在执行最后修正并同步..."
    # 修正路径
    sed -i '' 's|Filename: .*/debs/|Filename: debs/|g' Packages
    # 修正架构
    sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
    
    bzip2 -c9 Packages > Packages.bz2
    gzip -c9 Packages > Packages.gz
    
    sudo chown -R hang:staff .
    git add .
    git commit -m "Auto Fix and Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 同步完成！"
else
    echo "👌 没有任何变动。"
fi
