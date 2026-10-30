#!/usr/bin/env python3
"""修复版（Ubuntu apache2 2.4.52-1ubuntu4.25，已回填两个 CVE 补丁）负向探针。

对固定端口发送与正面 PoC 相同的请求，断言修复后的行为：
  CVE-2022-37436: /nul -> 502, /oversize -> 502, /control -> 200 且安全头在头里
  CVE-2023-27522: /nul -> 502, /oversize -> 502, /control -> 200 且安全头在头里
"""
import os
import socket
import sys

HOST = "127.0.0.1"


def recv_all(sock):
    data = b""
    while True:
        chunk = sock.recv(65536)
        if not chunk:
            break
        data += chunk
    return data


def dechunk(body):
    out = b""
    rest = body
    while True:
        if b"\r\n" not in rest:
            return out
        line, rest = rest.split(b"\r\n", 1)
        try:
            size = int(line.split(b";")[0].strip(), 16)
        except ValueError:
            return out
        if size == 0:
            return out
        out += rest[:size]
        rest = rest[size + 2:]


def probe(port, path):
    req = ("GET %s HTTP/1.1\r\nHost: 127.0.0.1\r\n"
           "Connection: close\r\n\r\n" % path).encode()
    s = socket.create_connection((HOST, port), timeout=10)
    s.sendall(req)
    raw = recv_all(s)
    s.close()
    sep = raw.find(b"\r\n\r\n")
    head, body = (raw, b"") if sep < 0 else (raw[:sep], raw[sep + 4:])
    try:
        status = int(head.split(b"\r\n")[0].split(b" ")[1])
    except (IndexError, ValueError):
        status = 0
    if b"transfer-encoding" in head.lower() and b"chunked" in head.lower():
        body = dechunk(body)
    return {"raw": raw, "head": head, "body": body, "status": status}


def test_37436(port, evid):
    ctl = probe(port, "/control")
    nul = probe(port, "/nul")
    over = probe(port, "/oversize")
    for tag, res in (("control", ctl), ("nul", nul), ("oversize", over)):
        with open(os.path.join(evid, "fixed_37436_%s.raw" % tag), "wb") as fh:
            fh.write(res["raw"])
        print("37436 %-8s status=%d head_set_cookie=%s body_set_cookie=%s"
              % (tag, res["status"], b"Set-Cookie" in res["head"],
                 b"Set-Cookie: SECRET=1" in res["body"]))
    ok = (
        ctl["status"] == 200
        and b"Set-Cookie: SECRET=1" in ctl["head"]
        and nul["status"] == 502
        and b"Set-Cookie: SECRET=1" not in nul["body"]
        and over["status"] == 502
    )
    print("37436_fixed_ok=%d" % ok)
    return ok


def test_27522(port, evid):
    ctl = probe(port, "/control")
    nul = probe(port, "/nul")
    over = probe(port, "/oversize")
    cr = probe(port, "/cr")
    bad = probe(port, "/badname")
    for tag, res in (("control", ctl), ("nul", nul), ("oversize", over),
                     ("cr", cr), ("badname", bad)):
        with open(os.path.join(evid, "fixed_27522_%s.raw" % tag), "wb") as fh:
            fh.write(res["raw"])
        print("27522 %-8s status=%d" % (tag, res["status"]))
    # 修复版：模块层直接 502（而不是 2.4.49 的 200/500）
    ok = (
        ctl["status"] == 200
        and b"Set-Cookie: SECRET=1" in ctl["head"]
        and nul["status"] == 502
        and b"Set-Cookie: SECRET=1" not in nul["body"]
        and over["status"] == 502
        and cr["status"] == 502
        and bad["status"] == 502
    )
    print("27522_fixed_ok=%d" % ok)
    return ok


def main():
    if len(sys.argv) < 3:
        print("usage: negative_probe.py <which: 37436|27522> <port> <evidence_dir>",
              file=sys.stderr)
        return 2
    which, port, evid = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    os.makedirs(evid, exist_ok=True)
    ok = test_37436(port, evid) if which == "37436" else test_27522(port, evid)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
