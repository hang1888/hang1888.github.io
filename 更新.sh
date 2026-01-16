#!/bin/bash
cd /Users/hang/Documents/hang.github
export LANG=en_US.UTF-8

echo "--- 正在检查变更 ---"

# 1. 提取包名
existing_packages=$(grep "^Package: " Packages | awk '{print $2}')
NEED_SYNC=false

# 2. 遍历并增量追加
for deb in debs/*.deb; do
    [ -e "$deb" ] || continue
    pkg_name=$(dpkg-deb -f "$deb" Package 2>/dev/null)
    display_name=${pkg_name:-$(basename "$deb")}

    if ! echo "$existing_packages" | grep -q "^$pkg_name$"; then
        echo "------------------------------------------------"
        echo "🆕 发现新插件: $display_name"
        
        # 核心修正：使用相对路径扫描，防止生成绝对路径
        new_info=$(dpkg-scanpackages -m "$deb" 2>/dev/null | sed "s|Filename: .*/debs/|Filename: debs/|g")
        
        if [ -n "$new_info" ]; then
            echo "$new_info" >> Packages
            echo "" >> Packages
            NEED_SYNC=true
        fi
    fi
done

# 3. 检查变更并修正 Packages 全文中的路径错误
text_changed=$(git status --porcelain Packages)

if [ "$NEED_SYNC" = true ] || [ -n "$text_changed" ]; then
    echo "正在修正路径与架构并同步..."
    # 强制把所有绝对路径转回相对路径 (debs/)
    sed -i '' 's|Filename: .*/debs/|Filename: debs/|g' Packages
    # 统一架构
    sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages
    
    bzip2 -c9 Packages > Packages.bz2
    gzip -c9 Packages > Packages.gz
    
    sudo chown -R hang:staff .
    git add .
    git commit -m "Fix Paths and Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    git push
    echo "✅ 同步完成！路径已修复，手动修改已保留。"
else
    echo "👌 没有任何变动。"
fi
