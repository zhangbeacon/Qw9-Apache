# -*- coding: utf-8 -*-
# 生成中英双语 CVE 索引：元数据取自 NVD JSON，中文译文内置（模型翻译，以英文原文为准）
import json, glob, os, datetime, sys

ROOT = r"E:\强网拟态\CVE原文"

ZH = {
"CVE-2017-13704": "在 2.78 之前的 dnsmasq 中，若 DNS 报文大小与预期不符，memset 调用的 size 参数会得到负值。由于该参数为无符号类型，memset 最终最多写入 0xffffffff 个（64 位平台上为 0xffffffffffffffff 个）零，导致 dnsmasq 崩溃。",
"CVE-2017-14491": "2.78 之前的 dnsmasq 存在基于堆的缓冲区溢出，远程攻击者可通过构造的 DNS 响应造成拒绝服务（崩溃）或执行任意代码。",
"CVE-2017-14496": "当指定 --add-mac、--add-cpe-id 或 --add-subnet 选项时，2.78 之前 dnsmasq 的 add_pseudoheader 函数存在整数下溢，远程攻击者可通过构造的 DNS 请求造成拒绝服务。",
"CVE-2017-7529": "自 0.5.6 起（含）至 1.13.2（含）的 nginx 版本，其 range 过滤模块存在整数溢出漏洞，可由特制请求触发潜在敏感信息泄露。",
"CVE-2021-23017": "nginx 的解析器（resolver）中发现一个安全问题：能够伪造来自 DNS 服务器的 UDP 报文的攻击者，可造成 1 字节内存越界写，导致 worker 进程崩溃或潜在其他影响。",
"CVE-2021-41773": "Apache HTTP Server 2.4.49 中对路径规范化的改动存在缺陷。攻击者可利用路径穿越攻击，把 URL 映射到 Alias 类指令所配置目录之外的文件。若这些目录外的文件未受到默认配置 \"require all denied\" 的保护，此类请求即可成功。若这些别名路径同时启用了 CGI 脚本，则可能导致远程代码执行。该问题已知被在野利用。仅影响 Apache 2.4.49，不影响更早版本。2.4.50 中的修复后被发现不完整，参见 CVE-2021-42013。",
"CVE-2021-42013": "Apache HTTP Server 2.4.50 中对 CVE-2021-41773 的修复不充分。攻击者仍可利用路径穿越攻击，把 URL 映射到 Alias 类指令所配置目录之外的文件。若这些目录外的文件未受到默认配置 \"require all denied\" 的保护，此类请求即可成功。若这些别名路径同时启用了 CGI 脚本，则可能导致远程代码执行。该问题仅影响 Apache 2.4.49 与 2.4.50，不影响更早版本。",
"CVE-2021-44224": "向配置为正向代理（ProxyRequests on）的 httpd 发送构造的 URI，可导致崩溃（空指针解引用）；或在混用正向与反向代理声明的配置下，请求可被导向某个已声明的 Unix 域套接字端点（服务器端请求伪造，SSRF）。影响 Apache HTTP Server 2.4.7 至 2.4.51（含）。",
"CVE-2021-44790": "精心构造的请求体可使 mod_lua 的 multipart 解析器（由 Lua 脚本调用的 r:parsebody()）发生缓冲区溢出。Apache httpd 团队目前不知悉针对该漏洞的实际利用，但不排除可被构造。影响 Apache HTTP Server 2.4.51 及更早版本。",
"CVE-2022-22719": "精心构造的请求体可导致读取随机内存区域，从而可能导致进程崩溃。影响 Apache HTTP Server 2.4.52 及更早版本。",
"CVE-2022-22720": "Apache HTTP Server 2.4.52 及更早版本在丢弃请求体遇到错误时未能关闭入站连接，使服务器暴露于 HTTP 请求走私（Request Smuggling）攻击。",
"CVE-2022-23943": "Apache HTTP Server 的 mod_sed 存在越界写漏洞，攻击者可用可能由攻击者提供的数据覆写堆内存。影响 Apache HTTP Server 2.4.52 及更早版本。",
"CVE-2022-37436": "在 Apache HTTP Server 2.4.55 之前，恶意后端可使响应头被提前截断，导致部分响应头被并入响应体。若这些（被并入响应体的）头具有安全作用，客户端将不会对其解释。",
"CVE-2022-41741": "NGINX 开源版 1.23.2/1.22.1 之前、订阅版 R2 P1/R1 P1 之前以及 NGINX Plus R27 P1/R26 P1 之前的版本中，ngx_http_mp4_module 模块存在漏洞：本地攻击者可使用特制音频或视频文件破坏 NGINX worker 内存，导致其终止或潜在其他影响。该问题仅影响编译了 ngx_http_mp4_module 且配置文件中使用了 mp4 指令的 NGINX 产品，且只有攻击者能够触发该模块处理特制音视频文件时攻击才可能发生。",
"CVE-2022-41742": "NGINX 开源版 1.23.2/1.22.1 之前、订阅版 R2 P1/R1 P1 之前以及 NGINX Plus R27 P1/R26 P1 之前的版本中，ngx_http_mp4_module 模块存在漏洞：本地攻击者可使用特制音频或视频文件导致 worker 进程崩溃，或造成 worker 进程内存泄露。该问题仅影响编译了 ngx_http_mp4_module 且配置文件中使用了 mp4 指令的 NGINX 产品，且只有攻击者能够触发该模块处理特制音视频文件时攻击才可能发生。",
"CVE-2023-25690": "Apache HTTP Server 2.4.0 至 2.4.55 的部分 mod_proxy 配置可被 HTTP 请求走私攻击。当 mod_proxy 与某种 RewriteRule 或 ProxyPassMatch 一起启用，且其中非特定的模式匹配了用户提供的请求目标（URL）数据的某一部分、随后又通过变量替换将其重新插入被代理的请求目标时，配置即受影响。例如：RewriteEngine on；RewriteRule \"^/here/(.*)\" \"http://example.com:8080/elsewhere?$1\"; [P]；ProxyPassReverse /here/ http://example.com:8080/。请求拆分/走私可导致绕过代理服务器上的访问控制、把非预期 URL 代理到已有源站，以及缓存投毒。建议至少升级到 2.4.56。",
"CVE-2023-27522": "Apache HTTP Server 经 mod_proxy_uwsgi 的 HTTP 响应走私漏洞。源站响应头中的特殊字符可截断/拆分转发给客户端的响应。影响 Apache HTTP Server 2.4.30 至 2.4.55。",
"CVE-2024-38474": "Apache HTTP Server 2.4.59 及更早版本中 mod_rewrite 的替换编码问题，允许攻击者在配置允许、但无法通过任何 URL 直接访问的目录中执行脚本，或泄露原本仅打算作为 CGI 执行的脚本源码。建议升级到 2.4.60（该版本修复此问题）。部分对用户数据进行不安全捕获与替换的 RewriteRule 此后会失败，除非指定 rewrite 标志 \"UnsafeAllow3F\"。",
}

rows = []
for p in sorted(glob.glob(os.path.join(ROOT, "nvd_json", "*.json"))):
    try:
        v = json.load(open(p, encoding="utf-8"))["vulnerabilities"][0]["cve"]
    except Exception:
        continue
    cid = v["id"]
    en = next((d["value"] for d in v["descriptions"] if d["lang"] == "en"), "")
    m = v.get("metrics", {})
    m31 = m.get("cvssMetricV31") or m.get("cvssMetricV30") or []
    score = m31[0]["cvssData"]["baseScore"] if m31 else "-"
    vec = m31[0]["cvssData"]["vectorString"] if m31 else "-"
    cwe = "-"
    for w in v.get("weaknesses", []):
        for d in w.get("description", []):
            if d["value"].startswith("CWE-"):
                cwe = d["value"]; break
    refs = [r["url"] for r in v.get("references", [])][:5]
    rows.append((cid, score, cwe, vec, en, refs))

lines = ["# CVE 原文索引（中英双语）", "",
         "> 元数据来源：NVD API 2.0 官方 JSON（`nvd_json/`）；上游公告见 `advisory/`。",
         "> **中文译文说明**：译文由 AI 模型翻译生成，仅供快速阅读；技术口径与法律效力以英文原文为准。",
         "> 生成时间：%s" % datetime.datetime.now().isoformat(timespec="seconds"), ""]

for cid, score, cwe, vec, en, refs in rows:
    zh = ZH.get(cid, "（待补译）")
    lines += ["## %s（CVSS %s，%s）" % (cid, score, cwe),
              "",
              "**中文译文**：%s" % zh,
              "",
              "**英文原文**：",
              "",
              "> %s" % en.replace("\n", " "),
              "",
              "- CVSS 向量：`%s`" % vec,
              "- 参考："]
    lines += ["  - %s" % r for r in refs]
    lines += ["- 本地文件：`nvd_json/%s.json`" % cid, ""]

lines += ["---", "", "## 上游官方公告（advisory/，原文为英文）", "",
          "- `apache_httpd_vulnerabilities_24.html`：Apache httpd 2.4.x 官方漏洞总表（41773/42013/44224/44790/22719/22720/23943/37436/25690/27522/38474）",
          "- `nginx_security_advisories.html`：nginx 官方安全公告页（7529/23017/41741/41742）",
          "- `nginx_patch_2021_resolver.txt` / `nginx_patch_2022_mp4.txt`：nginx 官方修复补丁原文",
          "- `dnsmasq_CHANGELOG`：dnsmasq 官方变更日志（13704/14491/14496 修复记录）", ""]

out = os.path.join(ROOT, "CVE索引.md")
open(out, "w", encoding="utf-8").write("\n".join(lines))
print("written:", out, "entries:", len(rows), "translated:", sum(1 for c, *_ in rows if c in ZH))
