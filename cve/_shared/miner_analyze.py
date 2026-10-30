#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Apache httpd 补丁差分挖掘：CHANGES 解析 + 定点 diff + hunk 提取"""
import os, re, subprocess, glob, json, csv, sys

SRC = "/root/work/miner/src"
OUT = "/mnt/e/强网拟态/Apache项目/漏洞挖掘"
os.makedirs(os.path.join(OUT, "diffs"), exist_ok=True)

# 修复版本 -> 前一版本（用于精确定位"这次发布引入的修复"）
VPAIR = {"2.4.50": "2.4.49", "2.4.51": "2.4.50", "2.4.52": "2.4.51",
         "2.4.53": "2.4.52", "2.4.54": "2.4.53", "2.4.55": "2.4.54",
         "2.4.56": "2.4.55", "2.4.59": "2.4.56", "2.4.60": "2.4.59"}

# 11 个目标 CVE -> 修复版本
FIX = {
    "CVE-2021-41773": "2.4.50",
    "CVE-2021-42013": "2.4.51",
    "CVE-2021-44224": "2.4.52",
    "CVE-2021-44790": "2.4.52",
    "CVE-2022-22719": "2.4.53",
    "CVE-2022-22720": "2.4.53",
    "CVE-2022-23943": "2.4.53",
    "CVE-2022-37436": "2.4.55",
    "CVE-2023-25690": "2.4.56",
    "CVE-2023-27522": "2.4.56",
    "CVE-2024-38474": "2.4.60",
}

# 兜底文件映射（CHANGES 未写文件名时使用）
FILES = {
    "CVE-2021-41773": ["server/util.c", "server/request.c"],
    "CVE-2021-42013": ["server/util.c"],
    "CVE-2021-44224": ["modules/proxy/proxy_util.c", "modules/proxy/mod_proxy.c"],
    "CVE-2021-44790": ["modules/lua/lua_request.c"],
    "CVE-2022-22719": ["modules/lua/lua_request.c"],
    "CVE-2022-22720": ["modules/http/http_filters.c"],
    "CVE-2022-23943": ["modules/filters/mod_sed.c"],
    "CVE-2022-37436": ["modules/proxy/mod_proxy_http.c"],
    "CVE-2023-25690": ["modules/mappers/mod_rewrite.c", "modules/proxy/mod_proxy.c", "modules/proxy/mod_proxy_http.c"],
    "CVE-2023-27522": ["modules/proxy/mod_proxy_uwsgi.c"],
    "CVE-2024-38474": ["modules/mappers/mod_rewrite.c"],
}

def read_changes(ver):
    p = os.path.join(SRC, "httpd-" + ver, "CHANGES")
    if not os.path.exists(p):
        return []
    txt = open(p, encoding="utf-8", errors="replace").read()
    blocks = re.split(r"\n(?=  \*\) )", txt)
    return blocks

def security_entries(ver):
    out = []
    for b in read_changes(ver):
        if "SECURITY:" not in b:
            continue
        m = re.search(r"SECURITY:\s*(CVE-\d{4}-\d+)", b)
        if m:
            out.append((m.group(1), " ".join(b.split())[:600]))
    return out

# 1) 汇总 CHANGES 安全条目
allsec = {}
for ver in sorted(VPAIR.keys()):
    for cve, text in security_entries(ver):
        allsec.setdefault(cve, []).append((ver, text))

lines = ["# Apache httpd 2.4.50–2.4.60 官方 CHANGES 安全条目", "",
         "> 自动提取自各版本源码包 `CHANGES` 文件，供补丁差分索引使用。", ""]
for ver in sorted(VPAIR.keys()):
    ents = security_entries(ver)
    lines.append("## " + ver + "（%d 条）" % len(ents))
    for cve, text in ents:
        lines.append("- **%s**：%s" % (cve, text))
    lines.append("")
open(os.path.join(OUT, "CHANGES-security.md"), "w", encoding="utf-8").write("\n".join(lines))

# 2) 定点 diff + hunk 提取
rows = []
details = []
for cve, fixver in FIX.items():
    prev = VPAIR[fixver]
    files = FILES[cve]
    # CHANGES 里出现过的文件名优先
    seen = []
    for ver, text in allsec.get(cve, []):
        for f in re.findall(r"\b(?:server|modules|include|os)/[\w/.\-]+\.(?:c|h)\b", text):
            if f not in seen:
                seen.append(f)
    use_files = seen or files
    cve_diff_path = os.path.join(OUT, "diffs", cve + ".diff")
    hunks = []
    total_add = total_del = 0
    with open(cve_diff_path, "w", encoding="utf-8") as df:
        df.write("# %s : %s -> %s\n" % (cve, prev, fixver))
        for rel in use_files:
            a = os.path.join(SRC, "httpd-" + prev, rel)
            b = os.path.join(SRC, "httpd-" + fixver, rel)
            if not (os.path.exists(a) and os.path.exists(b)):
                df.write("\n## %s\n(文件不存在于 %s 或 %s)\n" % (rel, prev, fixver))
                continue
            r = subprocess.run(["diff", "-u", "-U5", a, b], capture_output=True, text=True)
            if not r.stdout.strip():
                continue
            df.write("\n## %s\n" % rel)
            df.write(r.stdout)
            adds = sum(1 for l in r.stdout.splitlines() if l.startswith("+") and not l.startswith("+++"))
            dels = sum(1 for l in r.stdout.splitlines() if l.startswith("-") and not l.startswith("---"))
            total_add += adds; total_del += dels
            for h in re.finditer(r"^@@[^\n]*@@([^\n]*)\n", r.stdout, re.M):
                pass
            hs = re.findall(r"^(@@[^\n]*@@[^\n]*)$", r.stdout, re.M)
            hunks += [(rel, x) for x in hs]
    rows.append([cve, fixver, prev, ";".join(use_files), len(hunks), total_add, total_del])
    details.append({"cve": cve, "fix": fixver, "prev": prev, "files": use_files,
                    "hunks": [{"file": f, "header": h} for f, h in hunks]})

with open(os.path.join(OUT, "挖掘索引.csv"), "w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f)
    w.writerow(["CVE", "修复版本", "对比版本", "涉及文件", "hunk数", "新增行", "删除行"])
    w.writerows(rows)
json.dump(details, open(os.path.join(OUT, "hunks.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

print("CVEs:", len(rows))
for r in rows:
    print("  %-16s %s->%s  files=%d hunks=%d +%d/-%d" % (r[0], r[2], r[1], len(r[3].split(";")) if r[3] else 0, r[4], r[5], r[6]))
print("OUT:", OUT)
