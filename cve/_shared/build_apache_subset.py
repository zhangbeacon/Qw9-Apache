import re, os, sys

SRC = r"E:\强网拟态\CVE原文\CVE索引.md"
DST_DIR = r"E:\强网拟态\Apache项目\CVE原文-Apache"
APACHE = {"CVE-2021-41773","CVE-2021-42013","CVE-2021-44224","CVE-2021-44790",
          "CVE-2022-22719","CVE-2022-22720","CVE-2022-23943","CVE-2022-37436",
          "CVE-2023-25690","CVE-2023-27522","CVE-2024-38474"}
JSON_SRC = r"E:\强网拟态\CVE原文\nvd_json"
ADV_SRC = r"E:\强网拟态\CVE原文\advisory"

os.makedirs(os.path.join(DST_DIR, "nvd_json"), exist_ok=True)
os.makedirs(os.path.join(DST_DIR, "advisory"), exist_ok=True)

# 1) 拷贝 Apache 相关 JSON 与官方公告
import shutil
copied = 0
for c in sorted(APACHE):
    s = os.path.join(JSON_SRC, c + ".json")
    if os.path.exists(s):
        shutil.copy2(s, os.path.join(DST_DIR, "nvd_json", c + ".json")); copied += 1
for f in ("apache_httpd_vulnerabilities_24.html",):
    s = os.path.join(ADV_SRC, f)
    if os.path.exists(s):
        shutil.copy2(s, os.path.join(DST_DIR, "advisory", f))
print("json copied:", copied)

# 2) 从双语索引中切出 Apache 段落
text = open(SRC, encoding="utf-8").read()
parts = re.split(r"\n(?=## )", text)
header = parts[0].replace("# CVE 原文索引（中英双语）", "# Apache CVE 原文索引（中英双语，11 条）")
header = header.replace("> 元数据来源：NVD API 2.0 官方 JSON（`nvd_json/`）；上游公告见 `advisory/`。",
    "> 元数据来源：NVD API 2.0 官方 JSON（本目录 `nvd_json/`）；Apache 官方公告见 `advisory/`。\n> 本索引为 Apache-only 子集（V1 = Apache httpd 2.4.49）；完整 18 条全集见 `E:\\强网拟态\\CVE原文\\`。")
keep = [header]
for p in parts[1:]:
    m = re.match(r"## (CVE-\d{4}-\d+)", p)
    if m and m.group(1) in APACHE:
        keep.append(p.rstrip() + "\n")
keep.append("""---

## 上游官方公告（advisory/）

- `apache_httpd_vulnerabilities_24.html`：Apache httpd 2.4.x 官方漏洞总表（覆盖本索引全部 11 条）

> nginx / dnsmasq 官方公告在全集包 `E:\\强网拟态\\CVE原文\\advisory\\`。
""")
out = os.path.join(DST_DIR, "CVE索引-Apache.md")
open(out, "w", encoding="utf-8").write("\n".join(keep))
print("index written:", out, "sections:", len(keep) - 2)
