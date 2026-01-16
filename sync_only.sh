#!/bin/bash
cd /Users/hang/Documents/hang.github

echo "--- 正在打包并上传（不扫描新插件） ---"

# 1. 压缩你手动改好的 Packages 文件
echo "正在生成压缩包..."
bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz

# 2. 修正权限
sudo chown -R hang:staff ./*.sh ./Packages* ./Release ./debs

# 3. 推送到 GitHub
echo "正在同步到 GitHub..."
git add .
git commit -m "Manual update: $(date +'%Y-%m-%d %H:%M:%S')"
git push

echo "✅ 同步完成！手动修改的内容已生效。"
