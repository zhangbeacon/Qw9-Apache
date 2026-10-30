#!/bin/bash
# 查询候选 CVE 对 httpd 2.4.49 的适用区间
bash /mnt/e/强网拟态/cve/_shared/netfix.sh >/dev/null 2>&1
for id in CVE-2022-22720 CVE-2022-22721 CVE-2022-23943 CVE-2021-42013; do
  echo "===== $id ====="
  curl -sS -m 40 "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=$id" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    v=d["vulnerabilities"][0]["cve"]
    desc=[x["value"] for x in v["descriptions"] if x["lang"]=="en"][0]
    print("desc:", desc[:220])
    for cpe in v.get("configurations",[]):
        for node in cpe.get("nodes",[]):
            for m in node.get("cpeMatch",[]):
                cr=m.get("criteria","")
                if "http_server" in cr or "httpd" in cr:
                    print("  range:", cr.split(":")[5], "| start:", m.get("versionStartIncluding") or m.get("versionStartExcluding") or "-", "| endIncl:", m.get("versionEndIncluding") or "-", "| endExcl:", m.get("versionEndExcluding") or "-")
except Exception as e:
    print("parse fail:", e)
'
done
