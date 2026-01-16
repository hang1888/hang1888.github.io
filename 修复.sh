#!/bin/bash
cd /Users/hang/Documents/hang.github

echo "--- 正在深度清理并重构 Packages ---"

# 1. 彻底重新全量扫描，解决绝对路径和重复问题
dpkg-scanpackages -m debs > Packages

# 2. 修正架构 (arm64e -> arm64)
sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages

# 3. 自动匹配你之前的分类规则 (防止被重置为 Tweak)
echo "正在恢复分类信息..."
# 微信类
sed -i '' '/Package: com.h.chajian/,/Section:/ s/Section: .*/Section: 微信插件/' Packages
sed -i '' '/Package: com.h.juju/,/Section:/ s/Section: .*/Section: 微信插件/' Packages
sed -i '' '/Package: com.huami.WCExtractRes/,/Section:/ s/Section: .*/Section: 微信插件/' Packages
sed -i '' '/Package: com.mingzi/,/Section:/ s/Section: .*/Section: 微信插件/' Packages
sed -i '' '/Package: com.yourcompany.color/,/Section:/ s/Section: .*/Section: 微信插件/' Packages

# 自用类
sed -i '' '/Package: com.be-huge.floating-view/,/Section:/ s/Section: .*/Section: 自用插件/' Packages
sed -i '' '/Package: com.lclrc.hammerit/,/Section:/ s/Section: .*/Section: 自用插件/' Packages
sed -i '' '/Package: ovh.exerhythm.cardculator/,/Section:/ s/Section: .*/Section: 自用插件/' Packages
sed -i '' '/Package: com.wkk.lookinloader/,/Section:/ s/Section: .*/Section: 自用插件/' Packages

# 4. 再次检查并删除可能存在的绝对路径 (双重保险)
sed -i '' 's|Filename: /Users/hang/Documents/hang.github/|Filename: |g' Packages

# 5. 生成压缩包
bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz

echo "✅ 修复完成！Packages 已恢复整洁。"
echo "现在你可以打开 Packages 看看，如果满意，直接运行 git 推送即可。"
