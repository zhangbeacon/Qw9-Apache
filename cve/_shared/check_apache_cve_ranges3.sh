#!/bin/bash
# 批量核查候选 CVE 是否覆盖 httpd 2.4.49
bash /mnt/e/强网拟态/cve/_shared/netfix.sh >/dev/null 2>&1
for id in CVE-2023-25690 CVE-2023-27522 CVE-2022-28614 CVE-2022-30556 CVE-2022-26371 CVE-2023-31122 CVE-2022-37436 CVE-2024-38475 CVE-2024-38474 CVE-2021-36160 CVE-2021-34798; do
  echo "===== $id ====="
  curl -sS -m 40 "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=$id" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    v=d["vulnerabilities"][0]["cve"]
    desc=[x["value"] for x in v["descriptions"] if x["lang"]=="en"][0]
    m=[x for x in v.get("metrics",{}).get("cvssMetricV31",[])]
    score=m[0]["cvssData"]["baseScore"] if m else "-"
    print("cvss:", score, "| desc:", desc[:170])
    for cpe in v.get("configurations",[]):
        for node in cpe.get("nodes",[]):
            for mm in node.get("cpeMatch",[]):
                cr=mm.get("criteria","")
                if "http_server" in cr and cr.split(":")[5]=="*":
                    print("  range: startIncl:", mm.get("versionStartIncluding") or "-", "| endIncl:", mm.get("versionEndIncluding") or "-", "| endExcl:", mm.get("versionEndExcluding") or "-")
except Exception as e:
    print("parse fail:", e)
'
done
