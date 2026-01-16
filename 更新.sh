#!/bin/bash

# 进入项目根目录，防止路径找不到
cd /Users/hang/Documents/hang.github

echo "--- 正在开始更新流程 ---"

# 1. 检查 debs 目录是否存在
if [ ! -d "debs" ]; then
    echo "❌ 错误: 找不到 debs 文件夹，请确保你在 /Users/hang/Documents/hang.github 下运行脚本。"
    exit 1
fi

# 2. 扫描新插件
echo "正在扫描新插件..."
dpkg-scanpackages -m debs > Packages

# 3. 统一架构名 (把 arm64e 改成 arm64，防止 RootHide 分组)
echo "正在统一架构信息..."
sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages

# 4. 生成压缩索引
echo "正在生成压缩包..."
bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz

# 5. 权限修正 (仅针对当前目录下的文件)
echo "正在修正权限..."
sudo chown -R hang:staff ./*.sh ./Packages* ./Release ./debs

# 6. 推送到 GitHub
echo "正在同步到 GitHub..."
git add .
git commit -m "Update tweaks: $(date +'%Y-%m-%d %H:%M:%S')"
git push

echo "✅ 全部完成！请去 Sileo 刷新查看。"
