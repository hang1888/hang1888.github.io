#!/bin/bash

# 1. 扫描插件
dpkg-scanpackages -m debs > Packages

# 2. 自动化分类逻辑 (根据文件名关键词自动分)
# 如果文件名包含 wechat，分到微信插件；如果包含 cc，分到美化...
sed -i '' '/wechat/s/Section: .*/Section: 微信插件/' Packages
sed -i '' '/cc\|theme\|alipay\|scan/s/Section: .*/Section: 美化插件/' Packages
sed -i '' '/back\|data/s/Section: .*/Section: 配置备份/' Packages
# 其余默认没匹配上的，可以统一设为自用插件
sed -i '' '/Section: Tweaks/s/Section: .*/Section: 自用插件/' Packages

# 3. 压缩
bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz

echo "分类索引已自动更新完成！"
