#!/bin/bash
cd /Users/hang/Documents/hang.github || exit 1
export LANG=en_US.UTF-8

# 1. 扫描插件
dpkg-scanpackages -m debs > Packages

# 2. 修正路径（架构必须保留 deb 内的真实值，否则 arm64e/roothide 装不上）
sed -i '' 's|Filename: .*/debs/|Filename: debs/|g' Packages

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
        "com.be-huge.insulation", "insulation"
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

    # 航の开关使用独立 Sileo depiction，避免重新扫描时恢复旧图片链接。
    if any(line.startswith("Package: com.hang.kaiguan") for line in new_lines):
        new_lines = [line for line in new_lines if not line.startswith("Depiction:")]
        new_lines.append("Depiction: https://hang1888.github.io/debs/com.hang.kaiguan.json")

    # Kayoko 使用独立 Sileo depiction，展示当前版本和更新内容。
    if any(line.startswith("Package: com.hang.kayoko") for line in new_lines):
        new_lines = [line for line in new_lines if not line.startswith("Icon:") and not line.startswith("Depiction:") and not line.startswith("Native-Depiction:") and not line.startswith("Sileodepiction:")]
        new_lines.append("Icon: https://hang1888.github.io/Icon/Kayoko.png?v=4.6.6-assets-2")
        new_lines.append("Sileodepiction: https://hang1888.github.io/depictions/com.hang.kayoko/depiction.json?v=4.6.8")

    out.append("\n".join(new_lines))

path.write_text("\n\n".join(out) + "\n", encoding="utf-8")
print(f"packages={len(out)}")
PY

# 4. 压缩
bzip2 -c9 Packages > Packages.bz2
gzip -c9 Packages > Packages.gz
xz -c9 Packages > Packages.xz

echo "✅ 分类完成：广告 / 补丁 / 插件 / 微信插件 / 配置备份 / 自用"
