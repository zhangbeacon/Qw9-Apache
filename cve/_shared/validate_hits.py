#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""逐发回放验证 fuzz 命中样本：每个 request.bin 单独打一次，确认是否真的触发崩溃"""
import os, glob, socket, subprocess, time, json

PREFIX = "/opt/httpd-asan"
CONF = PREFIX + "/conf/httpd-44790.conf"
OUT = "/mnt/e/强网拟态/Apache项目/漏洞挖掘/fuzz"
ERRLOG = PREFIX + "/logs/error_log"
HOST = ("127.0.0.1", 8082)

def sh(c):
    return subprocess.run(c, shell=True, capture_output=True, text=True)

def start():
    sh("pkill -9 -f httpd-asan"); time.sleep(0.3)
    subprocess.Popen([PREFIX + "/bin/httpd", "-f", CONF, "-DFOREGROUND"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    for _ in range(100):
        try:
            s = socket.create_connection(HOST, 0.2); s.close(); return True
        except OSError:
            time.sleep(0.1)
    return False

def send(body):
    j = body.find(b"\r\n")
    bnd = body[2:j]
    req = (b"POST /parsebody HTTP/1.1\r\nHost: 127.0.0.1\r\n"
           b"Content-Type: multipart/form-data; boundary=" + bnd + b"\r\n"
           b"Content-Length: " + str(len(body)).encode() + b"\r\nConnection: close\r\n\r\n" + body)
    try:
        s = socket.create_connection(HOST, 2); s.settimeout(2)
        s.sendall(req)
        while True:
            c = s.recv(4096)
            if not c: break
        s.close()
    except Exception:
        pass

def crashed():
    try:
        t = open(ERRLOG, "rb").read()[-200000:]
        return (b"AddressSanitizer" in t) or (b"exit signal" in t)
    except Exception:
        return False

def main():
    sh(": > %s" % ERRLOG)
    if not start():
        print("server start failed"); return
    results = []
    for d in sorted(glob.glob(os.path.join(OUT, "hit-*"))):
        p = os.path.join(d, "request.bin")
        if not os.path.exists(p): continue
        body = open(p, "rb").read()
        sh(": > %s" % ERRLOG)
        send(body)
        time.sleep(0.15)
        ok = crashed()
        results.append({"hit": os.path.basename(d), "reproduced": ok})
        if ok:
            start()
        else:
            # 确保服务器仍在
            try:
                s = socket.create_connection(HOST, 0.3); s.close()
            except OSError:
                start()
    total = len(results); rep = sum(1 for r in results if r["reproduced"])
    out = {"total": total, "reproduced": rep, "failed": total - rep,
           "details": results}
    open(os.path.join(OUT, "hit-validation.json"), "w", encoding="utf-8").write(json.dumps(out, ensure_ascii=False, indent=1))
    print(json.dumps({"total": total, "reproduced": rep, "failed": total - rep}, ensure_ascii=False))

main()
