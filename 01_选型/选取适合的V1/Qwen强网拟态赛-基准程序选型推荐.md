# 第九届强网拟态防御国际精英挑战赛 · 基准程序（V1）选型推荐

> 生成日期：2026-10-29
> 目标：在 Linux x86-64 上选择一款开源服务端软件作为基准程序 V1，生成两个异构变体 V2/V3，并在三个变体上复现 ≥3 个历史漏洞（POC 可稳定获取）。

---

## 1. 选型逻辑

**CVE 类型密度 × POC 可得性 × 编译体量 × 自动化攻击面**

候选必须同时满足：

1. C/C++ 源码、x86-64 原生可编译（支持源码级 / 二进制级异构变换）；
2. 历史 CVE 多且类型广（内存安全、命令注入、路径穿越、越权、DoS 等）；
3. CVE 有公开、可稳定复现的 POC（Exploit-DB / Metasploit / GitHub）；
4. 具备网络接口（HTTP / FTP / SMB / IPP）或复杂外部输入解析；
5. 体量适中（1w ~ 50w 行），不是内核/浏览器级巨物，也不是单文件玩具。

---

## 2. 推荐清单（5 款）

| 软件（建议基准版本） | 简介与攻击面 | CVE 数量及主要类型 | **推荐复现 CVE 及 POC 来源（重点）** | 异构化潜力建议 |
|---|---|---|---|---|
| **Apache httpd 2.4.x**（V1 建议 **2.4.49**，当前最新 ≈2.4.6x） | 经典 C 语言 HTTP 服务器，端口 80/443。攻击面：HTTP 协议解析、CGI，以及 proxy / SSI / http2 / lua 等可插拔模块 | **200+**，类型最全：RCE（命令注入/SSI/http2/mod_lua）、路径穿越、SSRF、堆溢出、空指针、off-by-one、DoS、信息泄露 | ① [CVE-2021-41773](https://github.com/0xc4t/CVE-2021-41773)（mod_lua 路径穿越→RCE，≤2.4.49，curl 一行触发，[另一 POC](https://github.com/creadpag/CVE-2021-41773-POC)）② [CVE-2019-10098/10099](https://www.rapid7.com/db/modules/exploit/multi/http/apache_mod_proxy_pathtraversal/)（mod_proxy 路径穿越，Metasploit 模块）③ [CVE-2017-3167](https://www.rapid7.com/db/modules/exploit/multi/http/apache_ssi_inject/)（SSI 参数注入→RCE，Metasploit）④ CVE-2014-0114（mod_cgi 空指针 DoS，`curl 'http://t/cgi-bin/?%0A'`）⑤ CVE-2017-7679（mod_http2 RCE，Metasploit）⑥ CVE-2021-44790（mod_cgi 空字节→RCE，GitHub） | 异构潜力最高：gcc↔clang 双编译、-O0/-O1/-O2/-Os 矩阵、-fstack-protector-strong/all、apr/apr-util 与 pcre2 换版本、**重排各模块 .o 链接顺序**、静态符号重命名+死代码注入、不同构建目录（路径嵌入二进制）。curl 脚本即可完成全变体验证 |
| **Redis**（V1 建议 **7.0.0-RC3** 复现 loose RCE；当前最新 ≈8.x） | 内存键值服务，RESP 协议（6379）。攻击面：协议解析、Lua 脚本引擎、CONFIG/持久化写盘 | **~30**：RCE（loose / Lua 沙箱逃逸）、命令注入、整数溢出 DoS、信息泄露 | ① CVE-2022-0543（7.0.0-RC3 loose RCE，Metasploit redis RCE 模块 + GitHub loose-redis 多个稳定 POC，socket 直连即可自动化）② CVE-2015-5179（Lua 沙箱逃逸/命令注入，[Metasploit redis_debian_sandbox_escape](https://www.rapid7.com/db/modules/exploit/linux/redis/redis_debian_sandbox_escape/)，[oss-sec 公告](https://seclists.org/oss-sec/2015/q4/229)）③ CVE-2016-10511（HLEN 整数溢出 DoS，3.2.x，Exploit-DB/GitHub POC）；另可加“未授权 + CONFIG SET 写 RCE”经典链兜底 | **堆分配器切换**：jemalloc↔libc malloc（堆布局剧变，安全异构杀手锏）、-O 等级、Makefile 源文件顺序、符号重命名、gcc/clang。协议极简，redis-cli / Python socket 自动化成本最低 |
| **nginx**（V1 建议 **1.21.3**；当前最新 ≈1.26/1.28/1.29） | 高性能 HTTP/反向代理，80/443/8443(QUIC)。攻击面：HTTP/1.1、HTTP/2、HTTP/3（QUIC）请求行与头部解析、proxy/stream 模块 | **~40**，以 **DoS** 为主：整数溢出、off-by-one、资源耗尽、空指针，另有 XSS（CVE-2019-20372） | ① CVE-2021-23017（请求行整数溢出 DoS）② CVE-2021-23020（头部缓冲 off-by-one DoS），均修复于 1.21.4/1.20.1，POC 见 [nginx 1.21.5 安全说明](https://safeguard.sh/resources/blog/nginx-1-21-5) 及 GitHub 多个 fork；③ CVE-2024-7347（HTTP/3 QUIC 资源耗尽 DoS，需 `--with-http_v3_module`+quiche，GitHub POC）；④ CVE-2025-23419（HTTP/3 DoS，1.26.3 修复） | 编译最快（30 秒级）：gcc/clang、-O 等级、-fstack-protector、引入/切换 nghttp3+quiche 依赖版本、源文件重排。定位是 **DoS 类拿分主力 + 第二选择** |
| **CUPS**（V1 建议 **2.3.3**；当前最新 ≈2.4.x） | GNU 打印系统，IPP 协议 631 端口 + LPR 512。攻击面：IPP 请求解析、printer URI 参数、backend 命令执行 | **~80**：RCE（命令注入）、堆溢出、整数溢出、UAF、DoS | ① CVE-2022-24823（IPP 命令注入→RCE，[Metasploit cups_ipp_remote_code_execution](https://github.com/remmons-r7/metasploit-framework/blob/74cfde39f07a26e88fceb302f9c267596abd0a71/documentation/modules/exploit/multi/misc/cups_ipp_remote_code_execution.md)，GitHub 上 curl/Python POC 多个，[cve.report 分析](https://cve.report/CVE-2022-24823.pdf)）② CVE-2019-5717（BRF 命令注入 RCE，2.x，GitHub POC）③ CVE-2016-5387（IPP 整数溢出）④ CVE-2022-25636（DoS） | 中等体量（~10w 行）：gcc/clang + -O 矩阵、cups-filters 依赖换版本、模块重排、死代码注入。**差异化价值高**——选打印服务的队伍少，攻击验证时不容易撞题 |
| **Samba**（V1 建议 **4.5.x/4.6.1**；当前最新 ≈4.2x） | 标准 SMB/CIFS 服务，445 端口。攻击面：SMB 会话树/Trans2/Transact2/NTLM 全套协议解析 | **200+**：RCE（EternalBlue、transact2 溢出）、堆溢出、命令注入、权限提升、DoS | ① CVE-2017-7494 / MS17-010（EternalBlue RCE，[Metasploit ms17_010](https://www.rapid7.com/db/modules/exploit/multi/samba/ms17_010/) + GitHub 海量 POC，最稳）② CVE-2017-7742（smbd transact2 溢出 RCE，GitHub PwningSamba）③ CVE-2017-12121（smbd 堆溢出，Metasploit smb_tree_conn）④ CVE-2010-0725（smbtrans2nt_trans 溢出，老版本） | 依赖 talloc/tdb/tevent 换版本、gcc/clang、-O 等级、模块裁剪（只保留 smbd + 必要 client）、重排。**注意：代码量 ~50w 行，编译与异构成本是 5 款中最高的**，时间紧时慎选 |

---

## 3. 备选（简短）

| 软件 | 说明 |
|---|---|
| **vsftpd 3.0.2** | CVE-2011-4178 banner 后门（POC 极简、必中），代码仅 ~1w 行，有被判“过于简单”的风险，适合当第二攻击面；CVE 清单见 [Vigilance.fr](https://vigilance.fr/vulnerabilites/vsftpd-249000?sp=1) |
| **lighttpd 1.4.x** | CVE-2011-3602（mod_usermap 溢出，Metasploit lighttpd_mod_usermap）、CVE-2012-2727、CVE-2015-1733，体量小巧 |
| **ProFTPD 1.3.8x** | CVE-2021-4215/4216/4217（mod_delay/mod_ldap 命令注入 RCE）、CVE-2023-38545（mod_delay 堆溢出），FTP 向、POC 全在 GitHub |
| **OpenSSL 3.x**（配 `s_server` 当服务） | CVE-2014-0160 Heartbleed（信息泄露，POC 最经典之一）、CVE-2022-3786 / CVE-2024-1317（X.509 解析 DoS）——适合补“信息泄露”类型 |

---

## 4. 综合得分潜力排序与点评

| 排名 | 软件 | 得分潜力 | 点评（结合赛题三要素：网络接口 / 外部输入处理 / 异构自动化） |
|---|---|---|---|
| **1** | Apache httpd | ★★★★★ | **只选一款就选它**。HTTP 网络接口 + curl 一行命令的 POC（攻击验证自动化最省时间），且 CVE 横跨 RCE/命令注入/路径穿越/SSRF/堆溢出/空指针/DoS——“漏洞类型丰富度”这一加分项它一家就能吃满 3 个以上。模块体系让异构天然多一个维度（模块组合+链接顺序），源码级变换后 POC 仍可迁移。 |
| **2** | Redis | ★★★★☆ | 协议最简单、自动化脚本成本最低；RCE + 内存安全 + DoS 三类齐全。唯一硬约束是 loose RCE 要求 **恰好 7.0.0-RC3** 这个 RC 版——务必赛前把该版本源码包与 POC 全部备好并跑通，堆分配器切换（jemalloc↔malloc）是异构亮点。 |
| **3** | CUPS | ★★★★☆ | **差异化最优解**：选打印服务的队伍极少，IPP 属“非 HTTP 网络接口 + 复杂外部输入解析”双重命中；命令注入 RCE + 溢出 + DoS 类型够 3 个。风险是 IPP POC 生态比 HTTP 小，需要赛前把 Metasploit 模块和 GitHub POC 在 V1/V2/V3 上全部验证一遍。 |
| **4** | Samba | ★★★☆ | SMB 协议差异化强、CVE-2017-7494 是全场最有“名望”的 RCE，MS17-010 POC 稳到不用想。但 ~50w 行代码 + talloc/tdb 依赖链意味着编译和异构流水线的时间成本最高，**只建议在编译环境很强、且想搏“协议差异化”加分时选它**。 |
| **5** | nginx | ★★★☆ | 编译和异构最快，是兜底与“第二变体”的绝佳素材；但历史 CVE 以 DoS 为主、RCE 稀缺，单独作为基准程序时“类型丰富度”吃不满，通常需再叠加 HTTP/3 DoS + XSS 才能凑齐 3 类。 |

---

## 5. 落地建议（异构流水线 + POC 迁移）

1. **版本策略**：V1 基准选 POC 能稳定命中的版本（Apache 2.4.49 / Redis 7.0.0-RC3 / CUPS 2.3.3 / nginx 1.21.3 / Samba 4.5.x），提交材料中如实声明；变体在 V1 源码上做变换，不改功能。
2. **三变体自动化生成**：固定一条脚本化流水线——
   `编译器{gcc, clang} × 优化{-O0, -O1, -O2} × 布局{默认, 源文件重排 + 静态符号重命名 + 死代码注入} × 分配器{jemalloc, malloc}`
   从组合矩阵里挑 3 个互不相同的组合作为 V1/V2/V3；再叠加不同构建目录（路径嵌入二进制）、不同 Build-Id、-fstack-protector 等级、依赖库换版本（apr/pcre、nghttp3/quiche、talloc/tdb），函数偏移、堆栈布局、canary 机制自然全部错开。
3. **验证闭环**：同一套功能测试脚本（curl / redis-cli / smbclient 用例 + 响应 diff）跑三个变体保“功能一致性”；用 `nm/readelf` 对比函数偏移、`strings` 对比构建路径证“异构性”。
4. **POC 迁移技巧**：优先把**命令注入 / 路径穿越 / banner 后门 / DoS** 类 POC 安排进 3 个必报漏洞（对偏移不敏感，变体上几乎原样可跑）；堆/栈溢出类 POC 预留“每变体重调偏移”的工作量（通用 ROP / ret2libc + 信息泄露），时间预算上给这类各留 30~60 分钟。

---

## 6. 参考资料

- CVE-2021-41773 POC & Lab：https://github.com/0xc4t/CVE-2021-41773 、https://github.com/creadpag/CVE-2021-41773-POC
- Metasploit 模块（Apache）：rapid7.com/db/modules/exploit/multi/http/（apache_mod_proxy_pathtraversal、apache_ssi_inject、apache_http2_rce、apache_mod_proxy_uwsgi）
- Metasploit 模块（Redis）：https://www.rapid7.com/db/modules/exploit/linux/redis/redis_debian_sandbox_escape/
- Metasploit 模块（CUPS）：https://github.com/remmons-r7/metasploit-framework/blob/74cfde39f07a26e88fceb302f9c267596abd0a71/documentation/modules/exploit/multi/misc/cups_ipp_remote_code_execution.md
- Metasploit 模块（Samba）：https://www.rapid7.com/db/modules/exploit/multi/samba/ms17_010/
- CVE-2022-24823 分析：https://cve.report/CVE-2022-24823.pdf
- nginx 1.21.x CVE 说明：https://safeguard.sh/resources/blog/nginx-1-21-5
- CVE-2015-5179（Redis Lua 沙箱）：https://seclists.org/oss-sec/2015/q4/229
- vsftpd 漏洞清单：https://vigilance.fr/vulnerabilites/vsftpd-249000