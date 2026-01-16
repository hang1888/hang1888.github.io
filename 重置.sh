#!/bin/bash
cd /Users/hang/Documents/hang.github

echo "--- ⚠️ 正在彻底重置并重新扫描所有插件 ---"

# 1. 删除旧的 Packages 索引
rm -f Packages Packages.bz2 Packages.gz

# 2. 全量扫描
# 使用 -m 确保它能记录同一个包名下的多个版本/文件
dpkg-scanpackages -m debs > Packages

# 3. 统一架构名 (arm64e -> arm64)
sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages

# 4. 权限设置
sudo chown -R hang:staff .

echo "✅ 重置完成！"
echo "--- 接下来请执行以下步骤 ---"
echo "1. 手动打开 Packages 文件进行你想要的修改（分类、描述、名字）。"
echo "2. 修改好并保存后，直接运行 ./更新.sh 进行打包同步。"
