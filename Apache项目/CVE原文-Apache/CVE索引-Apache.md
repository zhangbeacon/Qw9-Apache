# Apache CVE 原文索引（中英双语，11 条）

> 元数据来源：NVD API 2.0 官方 JSON（本目录 `nvd_json/`）；Apache 官方公告见 `advisory/`。
> 本索引为 Apache-only 子集（V1 = Apache httpd 2.4.49）；完整 18 条全集见 `E:\强网拟态\CVE原文\`。
> **中文译文说明**：译文由 AI 模型翻译生成，仅供快速阅读；技术口径与法律效力以英文原文为准。
> 生成时间：2026-10-29T20:23:35

## CVE-2021-41773（CVSS 9.8，CWE-22）

**中文译文**：Apache HTTP Server 2.4.49 中对路径规范化的改动存在缺陷。攻击者可利用路径穿越攻击，把 URL 映射到 Alias 类指令所配置目录之外的文件。若这些目录外的文件未受到默认配置 "require all denied" 的保护，此类请求即可成功。若这些别名路径同时启用了 CGI 脚本，则可能导致远程代码执行。该问题已知被在野利用。仅影响 Apache 2.4.49，不影响更早版本。2.4.50 中的修复后被发现不完整，参见 CVE-2021-42013。

**英文原文**：

> A flaw was found in a change made to path normalization in Apache HTTP Server 2.4.49. An attacker could use a path traversal attack to map URLs to files outside the directories configured by Alias-like directives. If files outside of these directories are not protected by the usual default configuration "require all denied", these requests can succeed. If CGI scripts are also enabled for these aliased pathes, this could allow for remote code execution. This issue is known to be exploited in the wild. This issue only affects Apache 2.4.49 and not earlier versions. The fix in Apache HTTP Server 2.4.50 was found to be incomplete, see CVE-2021-42013.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- 参考：
  - http://packetstormsecurity.com/files/164418/Apache-HTTP-Server-2.4.49-Path-Traversal-Remote-Code-Execution.html
  - http://packetstormsecurity.com/files/164418/Apache-HTTP-Server-2.4.49-Path-Traversal.html
  - http://packetstormsecurity.com/files/164629/Apache-2.4.49-2.4.50-Traversal-Remote-Code-Execution.html
  - http://packetstormsecurity.com/files/164941/Apache-HTTP-Server-2.4.50-Remote-Code-Execution.html
  - http://www.openwall.com/lists/oss-security/2021/10/05/2
- 本地文件：`nvd_json/CVE-2021-41773.json`

## CVE-2021-42013（CVSS 9.8，CWE-22）

**中文译文**：Apache HTTP Server 2.4.50 中对 CVE-2021-41773 的修复不充分。攻击者仍可利用路径穿越攻击，把 URL 映射到 Alias 类指令所配置目录之外的文件。若这些目录外的文件未受到默认配置 "require all denied" 的保护，此类请求即可成功。若这些别名路径同时启用了 CGI 脚本，则可能导致远程代码执行。该问题仅影响 Apache 2.4.49 与 2.4.50，不影响更早版本。

**英文原文**：

> It was found that the fix for CVE-2021-41773 in Apache HTTP Server 2.4.50 was insufficient. An attacker could use a path traversal attack to map URLs to files outside the directories configured by Alias-like directives. If files outside of these directories are not protected by the usual default configuration "require all denied", these requests can succeed. If CGI scripts are also enabled for these aliased pathes, this could allow for remote code execution. This issue only affects Apache 2.4.49 and Apache 2.4.50 and not earlier versions.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- 参考：
  - http://jvn.jp/en/jp/JVN51106450/index.html
  - http://packetstormsecurity.com/files/164501/Apache-HTTP-Server-2.4.50-Path-Traversal-Code-Execution.html
  - http://packetstormsecurity.com/files/164609/Apache-HTTP-Server-2.4.50-Remote-Code-Execution.html
  - http://packetstormsecurity.com/files/164629/Apache-2.4.49-2.4.50-Traversal-Remote-Code-Execution.html
  - http://packetstormsecurity.com/files/164941/Apache-HTTP-Server-2.4.50-Remote-Code-Execution.html
- 本地文件：`nvd_json/CVE-2021-42013.json`

## CVE-2021-44224（CVSS 8.2，CWE-476）

**中文译文**：向配置为正向代理（ProxyRequests on）的 httpd 发送构造的 URI，可导致崩溃（空指针解引用）；或在混用正向与反向代理声明的配置下，请求可被导向某个已声明的 Unix 域套接字端点（服务器端请求伪造，SSRF）。影响 Apache HTTP Server 2.4.7 至 2.4.51（含）。

**英文原文**：

> A crafted URI sent to httpd configured as a forward proxy (ProxyRequests on) can cause a crash (NULL pointer dereference) or, for configurations mixing forward and reverse proxy declarations, can allow for requests to be directed to a declared Unix Domain Socket endpoint (Server Side Request Forgery). This issue affects Apache HTTP Server 2.4.7 up to 2.4.51 (included).

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:H`
- 参考：
  - http://httpd.apache.org/security/vulnerabilities_24.html
  - http://seclists.org/fulldisclosure/2022/May/33
  - http://seclists.org/fulldisclosure/2022/May/35
  - http://seclists.org/fulldisclosure/2022/May/38
  - http://www.openwall.com/lists/oss-security/2021/12/20/3
- 本地文件：`nvd_json/CVE-2021-44224.json`

## CVE-2021-44790（CVSS 9.8，CWE-787）

**中文译文**：精心构造的请求体可使 mod_lua 的 multipart 解析器（由 Lua 脚本调用的 r:parsebody()）发生缓冲区溢出。Apache httpd 团队目前不知悉针对该漏洞的实际利用，但不排除可被构造。影响 Apache HTTP Server 2.4.51 及更早版本。

**英文原文**：

> A carefully crafted request body can cause a buffer overflow in the mod_lua multipart parser (r:parsebody() called from Lua scripts). The Apache httpd team is not aware of an exploit for the vulnerabilty though it might be possible to craft one. This issue affects Apache HTTP Server 2.4.51 and earlier.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- 参考：
  - http://httpd.apache.org/security/vulnerabilities_24.html
  - http://packetstormsecurity.com/files/171631/Apache-2.4.x-Buffer-Overflow.html
  - http://seclists.org/fulldisclosure/2022/May/33
  - http://seclists.org/fulldisclosure/2022/May/35
  - http://seclists.org/fulldisclosure/2022/May/38
- 本地文件：`nvd_json/CVE-2021-44790.json`

## CVE-2022-22719（CVSS 7.5，CWE-665）

**中文译文**：精心构造的请求体可导致读取随机内存区域，从而可能导致进程崩溃。影响 Apache HTTP Server 2.4.52 及更早版本。

**英文原文**：

> A carefully crafted request body can cause a read to a random memory area which could cause the process to crash. This issue affects Apache HTTP Server 2.4.52 and earlier.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H`
- 参考：
  - http://seclists.org/fulldisclosure/2022/May/33
  - http://seclists.org/fulldisclosure/2022/May/35
  - http://seclists.org/fulldisclosure/2022/May/38
  - http://www.openwall.com/lists/oss-security/2022/03/14/4
  - https://httpd.apache.org/security/vulnerabilities_24.html
- 本地文件：`nvd_json/CVE-2022-22719.json`

## CVE-2022-22720（CVSS 9.8，CWE-444）

**中文译文**：Apache HTTP Server 2.4.52 及更早版本在丢弃请求体遇到错误时未能关闭入站连接，使服务器暴露于 HTTP 请求走私（Request Smuggling）攻击。

**英文原文**：

> Apache HTTP Server 2.4.52 and earlier fails to close inbound connection when errors are encountered discarding the request body, exposing the server to HTTP Request Smuggling

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- 参考：
  - http://seclists.org/fulldisclosure/2022/May/33
  - http://seclists.org/fulldisclosure/2022/May/35
  - http://seclists.org/fulldisclosure/2022/May/38
  - http://www.openwall.com/lists/oss-security/2022/03/14/3
  - https://httpd.apache.org/security/vulnerabilities_24.html
- 本地文件：`nvd_json/CVE-2022-22720.json`

## CVE-2022-23943（CVSS 9.8，CWE-787）

**中文译文**：Apache HTTP Server 的 mod_sed 存在越界写漏洞，攻击者可用可能由攻击者提供的数据覆写堆内存。影响 Apache HTTP Server 2.4.52 及更早版本。

**英文原文**：

> Out-of-bounds Write vulnerability in mod_sed of Apache HTTP Server allows an attacker to overwrite heap memory with possibly attacker provided data. This issue affects Apache HTTP Server 2.4 version 2.4.52 and prior versions.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- 参考：
  - http://www.openwall.com/lists/oss-security/2022/03/14/1
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://lists.debian.org/debian-lts-announce/2022/03/msg00033.html
  - https://lists.fedoraproject.org/archives/list/package-announce%40lists.fedoraproject.org/message/RGWILBORT67SHMSLYSQZG2NMXGCMPUZO/
  - https://lists.fedoraproject.org/archives/list/package-announce%40lists.fedoraproject.org/message/X73C35MMMZGBVPQQCH7LQZUMYZNQA5FO/
- 本地文件：`nvd_json/CVE-2022-23943.json`

## CVE-2022-37436（CVSS 5.3，CWE-113）

**中文译文**：在 Apache HTTP Server 2.4.55 之前，恶意后端可使响应头被提前截断，导致部分响应头被并入响应体。若这些（被并入响应体的）头具有安全作用，客户端将不会对其解释。

**英文原文**：

> Prior to Apache HTTP Server 2.4.55, a malicious backend can cause the response headers to be truncated early, resulting in some headers being incorporated into the response body. If the later headers have any security purpose, they will not be interpreted by the client.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:N`
- 参考：
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://security.gentoo.org/glsa/202309-01
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://security.gentoo.org/glsa/202309-01
- 本地文件：`nvd_json/CVE-2022-37436.json`

## CVE-2023-25690（CVSS 9.8，CWE-444）

**中文译文**：Apache HTTP Server 2.4.0 至 2.4.55 的部分 mod_proxy 配置可被 HTTP 请求走私攻击。当 mod_proxy 与某种 RewriteRule 或 ProxyPassMatch 一起启用，且其中非特定的模式匹配了用户提供的请求目标（URL）数据的某一部分、随后又通过变量替换将其重新插入被代理的请求目标时，配置即受影响。例如：RewriteEngine on；RewriteRule "^/here/(.*)" "http://example.com:8080/elsewhere?$1"; [P]；ProxyPassReverse /here/ http://example.com:8080/。请求拆分/走私可导致绕过代理服务器上的访问控制、把非预期 URL 代理到已有源站，以及缓存投毒。建议至少升级到 2.4.56。

**英文原文**：

> Some mod_proxy configurations on Apache HTTP Server versions 2.4.0 through 2.4.55 allow a HTTP Request Smuggling attack.     Configurations are affected when mod_proxy is enabled along with some form of RewriteRule  or ProxyPassMatch in which a non-specific pattern matches  some portion of the user-supplied request-target (URL) data and is then  re-inserted into the proxied request-target using variable  substitution. For example, something like:     RewriteEngine on RewriteRule "^/here/(.*)" "http://example.com:8080/elsewhere?$1"; [P] ProxyPassReverse /here/ http://example.com:8080/   Request splitting/smuggling could result in bypass of access controls in the proxy server, proxying unintended URLs to existing origin servers, and cache poisoning. Users are recommended to update to at least version 2.4.56 of Apache HTTP Server.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- 参考：
  - http://packetstormsecurity.com/files/176334/Apache-2.4.55-mod_proxy-HTTP-Request-Smuggling.html
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://lists.debian.org/debian-lts-announce/2023/04/msg00028.html
  - https://security.gentoo.org/glsa/202309-01
  - http://packetstormsecurity.com/files/176334/Apache-2.4.55-mod_proxy-HTTP-Request-Smuggling.html
- 本地文件：`nvd_json/CVE-2023-25690.json`

## CVE-2023-27522（CVSS 7.5，CWE-444）

**中文译文**：Apache HTTP Server 经 mod_proxy_uwsgi 的 HTTP 响应走私漏洞。源站响应头中的特殊字符可截断/拆分转发给客户端的响应。影响 Apache HTTP Server 2.4.30 至 2.4.55。

**英文原文**：

> HTTP Response Smuggling vulnerability in Apache HTTP Server via mod_proxy_uwsgi. This issue affects Apache HTTP Server: from 2.4.30 through 2.4.55.  Special characters in the origin response header can truncate/split the response forwarded to the client.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:H/A:N`
- 参考：
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://lists.debian.org/debian-lts-announce/2023/04/msg00028.html
  - https://security.gentoo.org/glsa/202309-01
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://lists.debian.org/debian-lts-announce/2023/04/msg00028.html
- 本地文件：`nvd_json/CVE-2023-27522.json`

## CVE-2024-38474（CVSS 9.8，CWE-116）

**中文译文**：Apache HTTP Server 2.4.59 及更早版本中 mod_rewrite 的替换编码问题，允许攻击者在配置允许、但无法通过任何 URL 直接访问的目录中执行脚本，或泄露原本仅打算作为 CGI 执行的脚本源码。建议升级到 2.4.60（该版本修复此问题）。部分对用户数据进行不安全捕获与替换的 RewriteRule 此后会失败，除非指定 rewrite 标志 "UnsafeAllow3F"。

**英文原文**：

> Substitution encoding issue in mod_rewrite in Apache HTTP Server 2.4.59 and earlier allows attacker to execute scripts in directories permitted by the configuration but not directly reachable by any URL or source disclosure of scripts meant to only to be executed as CGI.  Users are recommended to upgrade to version 2.4.60, which fixes this issue.  Some RewriteRules that capture and substitute unsafely will now fail unless rewrite flag "UnsafeAllow3F" is specified.

- CVSS 向量：`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- 参考：
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://security.netapp.com/advisory/ntap-20240712-0001/
  - http://www.openwall.com/lists/oss-security/2024/07/01/7
  - https://httpd.apache.org/security/vulnerabilities_24.html
  - https://security.netapp.com/advisory/ntap-20240712-0001/
- 本地文件：`nvd_json/CVE-2024-38474.json`

---

---

## 上游官方公告（advisory/）

- `apache_httpd_vulnerabilities_24.html`：Apache httpd 2.4.x 官方漏洞总表（覆盖本索引全部 11 条）

> nginx / dnsmasq 官方公告在全集包 `E:\强网拟态\CVE原文\advisory\`。
