#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""对 fuzz 命中样本做触发距离分布统计：验证命中是否落在 44790 的 <=8 字节窗口
   request.bin 是 multipart body 本身：
   --B CRLF headers CRLFCRLF + pad + B -- CRLF
   距离 = 下一个 B 的位置 - CRLFCRLF 的位置
"""
import os, glob, collections, json

F = "/mnt/e/强网拟态/Apache项目/漏洞挖掘/fuzz"
buckets = collections.Counter()
rows = []
for d in sorted(glob.glob(os.path.join(F, "hit-*"))):
    p = os.path.join(d, "request.bin")
    if not os.path.exists(p):
        continue
    data = open(p, "rb").read()
    j = data.find(b"\r\n")
    if not data.startswith(b"--") or j < 0:
        buckets["bad-start"] += 1
        continue
    bnd = data[2:j]                     # 边界名
    k = data.find(b"\r\n\r\n")          # header 结束
    if k < 0:
        buckets["no-header-end"] += 1
        continue
    nxt = data.find(bnd, k + 4)         # 下一个 boundary
    if nxt < 0:
        buckets["no-next-boundary"] += 1
        continue
    dist = nxt - k                      # end - crlf
    buckets[dist] += 1
    rows.append({"hit": os.path.basename(d), "dist": dist})

out = {
    "hits": sum(buckets.values()),
    "dist_histogram": dict(sorted(((str(k), v) for k, v in buckets.items()), key=lambda x: x[0])),
    "in_window_le_8": sum(v for k, v in buckets.items() if isinstance(k, int) and k <= 8),
    "examples": rows[:12],
}
open(os.path.join(F, "hit-analysis.json"), "w", encoding="utf-8").write(json.dumps(out, ensure_ascii=False, indent=1))
print(json.dumps(out, ensure_ascii=False, indent=1))
