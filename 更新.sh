#!/bin/bash

REPO_PATH="/var/mobile/Documents/tellmyfriends-master"
cd "$REPO_PATH" || { echo "仓库路径不存在！"; exit 1; }

git config --global --add safe.directory "$REPO_PATH"

echo "📥 拉取最新代码..."
git pull

# 添加所有改动
git add .

# 判断是否有改动
if git diff --cached --quiet; then
    echo "⚡ 没有新的改动，跳过提交。"
else
    echo "📄 本地改动如下："
    git diff --cached --stat        # 显示修改的文件和行数统计
    echo "-------------------------------"
    git commit -m "更新"
    echo "✅ 本地改动已提交。"
fi

# 推送到远程（手动输入用户名和密码）
git push

echo "🚀 操作完成！"