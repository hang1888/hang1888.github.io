#!/bin/bash

# 1. 扫描插件
dpkg-scanpackages -m debs > Packages

# 2. 重新洗牌分类
# 先把所有分类统一设为“自用插件”（这样分屏和计算器默认就在这里了）
sed -i '' 's/^Section: .*/Section: 自用插件/' Packages

# --- 微信插件分类 ---
# 匹配关键词：wechat, weixin, 微信, WCExtract, 未读消息, 助手栏
sed -i '' '/wechat\|weixin\|微信\|WCExtract\|未读消息\|助手栏/s/Section: .*/Section: 微信插件/' Packages

# --- 美化插件分类 ---
# 匹配关键词：cc, scan, alipay, theme, 美化, 净化
sed -i '' '/cc\|scan\|alipay\|theme\|美化\|净化/s/Section: .*/Section: 美化插件/' Packages

# --- 配置备份分类 ---
# 匹配关键词：data, back, 备份
sed -i '' '/data\|back\|备份/s/Section: .*/Section: 配置备份/' Packages

# 3. 压缩
bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz

echo "✅ 分类已按最新要求调整：助手栏归类至微信，分屏/计算器归类至自用。"
