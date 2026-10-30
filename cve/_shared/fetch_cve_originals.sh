#!/bin/bash
# 爬取 CVE 原文：NVD 官方 JSON（逐个） + 上游官方公告，输出到 /mnt/e/强网拟态/CVE原文/
set -u
bash /mnt/e/强网拟态/cve/_shared/netfix.sh >/dev/null 2>&1
ROOT=/mnt/e/强网拟态/CVE原文
mkdir -p "$ROOT/nvd_json" "$ROOT/advisory"

CVES="CVE-2017-7529 CVE-2021-23017 CVE-2022-41741 CVE-2022-41742 \
CVE-2017-13704 CVE-2017-14491 CVE-2017-14496 \
CVE-2021-41773 CVE-2021-44224 CVE-2021-44790 CVE-2021-42013 \
CVE-2022-22720 CVE-2022-23943 CVE-2023-25690 CVE-2024-38474 \
CVE-2022-37436 CVE-2023-27522 CVE-2022-22719"

ok=0; fail=""
for id in $CVES; do
  out="$ROOT/nvd_json/$id.json"
  if [ -s "$out" ]; then echo "skip $id (exists)"; ok=$((ok+1)); continue; fi
  if curl -sS -m 45 "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=$id" -o "$out" && \
     python3 -c "import json,sys; json.load(open('$out'))" 2>/dev/null && \
     grep -q '"totalResults":1' "$out"; then
    echo "OK   $id"; ok=$((ok+1))
  else
    echo "FAIL $id"; rm -f "$out"; fail="$fail $id"
  fi
  sleep 7
done
echo "nvd_json done: $ok ok, failed:$fail"

# 上游官方公告
fetch_page() {
  local url=$1 out=$2
  if curl -sSL -m 60 "$url" -o "$out" && [ -s "$out" ]; then echo "OK   $out"; else echo "FAIL $out"; fi
}
fetch_page https://httpd.apache.org/security/vulnerabilities_24.html "$ROOT/advisory/apache_httpd_vulnerabilities_24.html"
fetch_page https://nginx.org/en/security_advisories.html       "$ROOT/advisory/nginx_security_advisories.html"
fetch_page http://thekelleys.org.uk/dnsmasq/CHANGELOG          "$ROOT/advisory/dnsmasq_CHANGELOG"
fetch_page http://nginx.org/download/patch.2021.resolver.txt   "$ROOT/advisory/nginx_patch_2021_resolver.txt"
fetch_page http://nginx.org/download/patch.2022.mp4.txt        "$ROOT/advisory/nginx_patch_2022_mp4.txt"

# 生成索引（python 解析 JSON）
python3 - "$ROOT" <<'PY'
import json, glob, os, sys
root = sys.argv[1]
rows = []
for p in sorted(glob.glob(os.path.join(root, "nvd_json", "*.json"))):
    try:
        v = json.load(open(p, encoding="utf-8"))["vulnerabilities"][0]["cve"]
    except Exception:
        continue
    cid = v["id"]
    desc = next((d["value"] for d in v["descriptions"] if d["lang"] == "en"), "")
    m31 = v.get("metrics", {}).get("cvssMetricV31", [])
    score = m31[0]["cvssData"]["baseScore"] if m31 else "-"
    vec = m31[0]["cvssData"]["vectorString"] if m31 else "-"
    cwe = "-"
    for w in v.get("weaknesses", []):
        for d in w.get("description", []):
            if d["value"].startswith("CWE-"):
                cwe = d["value"]; break
    refs = [r["url"] for r in v.get("references", [])][:6]
    rows.append((cid, score, cwe, vec, desc, refs))

lines = ["# CVE 原文索引", "",
         "> 来源：NVD API 2.0 官方 JSON（`nvd_json/`）+ 上游官方公告（`advisory/`）。",
         "> 抓取时间：%s" % __import__("datetime").datetime.now().isoformat(timespec="seconds"), ""]
for cid, score, cwe, vec, desc, refs in rows:
    lines += ["## %s（CVSS %s，%s）" % (cid, score, cwe),
              "- 向量：`%s`" % vec,
              "- 原文（EN）：%s" % desc,
              "- 参考："]
    lines += ["  - %s" % r for r in refs] or ["  - (无)"]
    lines += ["", "本地文件：`nvd_json/%s.json`" % cid, ""]
lines += ["", "## 上游官方公告（advisory/）", "",
          "- `apache_httpd_vulnerabilities_24.html`：Apache httpd 2.4.x 官方漏洞总表（含 41773/44224/44790/22720/23943/25690/38474 等）",
          "- `nginx_security_advisories.html`：nginx 官方安全公告页（含 7529/23017/41741-42）",
          "- `nginx_patch_2021_resolver.txt` / `nginx_patch_2022_mp4.txt`：官方修复补丁原文",
          "- `dnsmasq_CHANGELOG`：dnsmasq 官方变更日志（13704/14491/14496 修复说明）", ""]
open(os.path.join(root, "CVE索引.md"), "w", encoding="utf-8").write("\n".join(lines))
print("index written:", os.path.join(root, "CVE索引.md"), "entries:", len(rows))
PY
echo ALL_DONE
