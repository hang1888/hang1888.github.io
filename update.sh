#!/bin/bash
cd /Users/hang/Documents/hang.github || exit 1
export LANG=en_US.UTF-8

# 1. 扫描插件
dpkg-scanpackages -m debs > Packages

# 2. 修正路径和架构
sed -i '' 's|Filename: .*/debs/|Filename: debs/|g' Packages
sed -i '' 's/Architecture: iphoneos-arm64e/Architecture: iphoneos-arm64/g' Packages

# 3. 按包块重写分类
python3 - <<'PY'
from pathlib import Path

path = Path("Packages")
text = path.read_text(encoding="utf-8", errors="ignore")
blocks = [b for b in text.split("\n\n") if b.strip()]

def section_for(block: str) -> str:
    lower = block.lower()
    # 广告优先
    if any(k in lower for k in [
        "去广告", "ktc", "com.hang.365", "icam365", "fastword", "teleprompter", "adblock", "noad"
    ]):
        return "广告"
    # 补丁（放在通用插件规则之前）
    if any(k in lower for k in [
        "补丁", "patch", "ios17fix", "tweakinject"
    ]):
        return "补丁"
    # 指定工具插件
    if any(k in lower for k in [
        "com.lclrc.hammerit", "hammer it",
        "com.wkk.lookinloader", "lookinloader",
        "com.be-huge.floating-view", "floatingview"
    ]):
        return "插件"
    # 微信插件
    if any(k in lower for k in [
        "wechat", "weixin", "微信", "wcextract", "未读消息", "助手栏"
    ]):
        return "微信插件"
    # 配置备份
    if any(k in lower for k in [
        "data", "back", "备份"
    ]):
        return "配置备份"
    return "自用"

out = []
for block in blocks:
    lines = block.splitlines()
    replaced = False
    new_lines = []
    for line in lines:
        if line.startswith("Section:"):
            new_lines.append(f"Section: {section_for(block)}")
            replaced = True
        else:
            new_lines.append(line)
    if not replaced:
        new_lines.append(f"Section: {section_for(block)}")
    out.append("\n".join(new_lines))

path.write_text("\n\n".join(out) + "\n", encoding="utf-8")
print(f"packages={len(out)}")
PY

# 4. 压缩
bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz

echo "✅ 分类完成：广告 / 补丁 / 插件 / 微信插件 / 配置备份 / 自用"
