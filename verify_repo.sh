#!/bin/bash
# 校验 Packages 索引与 debs/ 里真实 deb 是否一致（架构/大小/SHA256/文件名）
export LANG=en_US.UTF-8
cd /Users/hang/Documents/hang.github || exit 1
python3 - <<'PY'
import hashlib, os, re
txt=open("Packages",encoding="utf-8",errors="ignore").read()
blocks=[b for b in txt.split("\n\n") if b.strip()]
bad=0
for b in blocks:
    d=dict()
    for line in b.splitlines():
        if ": " in line:
            k,v=line.split(": ",1); d[k]=v
    fn=d.get("Filename","")
    pkg=d.get("Package"); ver=d.get("Version")
    if not os.path.exists(fn):
        print(f"[缺文件] {pkg} {ver} -> {fn}"); bad+=1; continue
    real_arch=os.popen(f'dpkg-deb -f "{fn}" Architecture').read().strip()
    idx_arch=d.get("Architecture")
    size=str(os.path.getsize(fn))
    sha=hashlib.sha256(open(fn,'rb').read()).hexdigest()
    probs=[]
    if real_arch!=idx_arch: probs.append(f"架构 索引={idx_arch} 实际={real_arch}")
    if d.get("Size")!=size: probs.append(f"Size 索引={d.get('Size')} 实际={size}")
    if d.get("SHA256")!=sha: probs.append("SHA256 不匹配")
    if probs:
        print(f"[✗] {pkg} {ver}: "+"; ".join(probs)); bad+=1
    else:
        print(f"[✓] {pkg:42} {ver:12} {idx_arch}")
print("\n索引条目:",len(blocks),"问题:",bad)
PY
