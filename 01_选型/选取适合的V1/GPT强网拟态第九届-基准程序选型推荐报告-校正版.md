# 第九届强网拟态防御国际精英挑战赛
## Linux 基准程序 V1 选型推荐报告（校正版）

> 编制日期：2026-10-29  
> 目标：选择一个 Linux x86-64 开源基准程序 V1，生成异构变体 V2/V3，并在三个变体上复现至少 3 个历史 CVE。  
> 说明：本文将“当前上游版本”和“漏洞复现基线”严格分开。旧版本只用于隔离靶场，不应部署生产。

---

## 1. 结论先行

| 优先级 | 推荐 | 推荐复现基线 | 适合原因 | 主要风险 |
|---|---|---|---|---|
| 1 | **dnsmasq** | **2.76** | 源码小、网络面明确、Google/Exploit-DB 有一组公开 PoC | 多个 PoC 需要 IPv6、DHCPv6 或特定启动参数；公开代码多数是 DoS/ASAN，不是稳定 RCE |
| 2 | **ImageMagick** | **6.9.3-3** | ImageTragick 同版本覆盖命令注入、SSRF、文件读写/删除，PoC 最完整 | 依赖 `policy.xml`、delegate、Ghostscript 和 coder 配置；并非自带网络服务 |
| 3 | **NGINX** | **1.13.2** | HTTP 自动化测试方便，代码量适中，包含 Range、resolver、MP4 三类输入面 | 每个漏洞对模块和配置有明确要求 |
| 4 | **Samba** | **4.6.3** | SMB/AD 网络面复杂，漏洞类型丰富 | 构建和角色配置较重，CVE-2020-1472 仅适用于 AD DC |
| 5 | **OpenSSL** | **1.0.1f** | Heartbleed、CCS、DTLS 等公开 PoC 质量高 | 本身是协议库，需要额外搭建 `s_server`/DTLS 服务，源码规模偏大 |

**最推荐的竞赛组合：**

- 只选一个：`dnsmasq 2.76`；
- 偏重漏洞类型：`ImageMagick 6.9.3-3`；
- 偏重网络接口：`NGINX 1.13.2`；
- 偏重复杂协议和展示效果：`Samba 4.6.3`。

---

## 2. 统计口径和版本纪律

本文中的 CVE 数量采用 2026-10-29 查询的 NVD 2.0 精确 CPE 命中结果，仅用于横向比较，不代表全部漏洞都具备稳定 PoC，也不代表一定满足漏洞触发条件。

| 基线 | NVD 精确 CPE 命中数 | 备注 |
|---|---:|---|
| dnsmasq 2.76 | 22 | 可包含不同配置和发行版范围记录 |
| ImageMagick 6.9.3 | 431 | 属于版本范围匹配上限，不能直接当作实际可利用数量；第三方数据库对 6.9.3-3 约列出 27 条、6 个公开 exploit，可作交叉参考 |
| NGINX 1.13.2 | 15 | 按 `f5:nginx` CPE 查询 |
| Samba 4.6.3 | 75 | 不同角色和配置的交集并不等于所有漏洞都可触发 |
| OpenSSL 1.0.1f | 81 | 包含协议、密码学、DoS 和内存安全类记录 |

必须固定：

1. 完整补丁号，例如 `6.9.3-3`、`6.9.10-36`，不能只写 `6.9.10`；
2. Git commit/tag、源码包 SHA-256、编译器版本和完整编译命令；
3. 运行配置、模块/coder、`policy.xml`、delegate、环境变量和依赖库；
4. 发行版是否回移安全补丁。软件 banner 不能代替源码和包校验。

---

## 3. 五款候选详细评估

### 3.1 dnsmasq

- 当前上游版本：**2.93**，见[官方下载目录](https://thekelleys.org.uk/dnsmasq/)；
- 推荐复现版本：**2.76**；
- 攻击面：DNS UDP/TCP 53、DHCPv4/v6、IPv6 Router Advertisement、PXE/TFTP；
- 规模：五个候选中最小，适合快速源码级异构。

#### 推荐 CVE 和 PoC

| CVE | 类型和可靠复现目标 | 公开来源 | 重要前置条件 |
|---|---|---|---|
| CVE-2017-13704 | DNS 长度处理错误，负长度 `memset`，稳定目标为崩溃/DoS | [Google PoC 镜像](https://github.com/moperon/security-research-pocs/tree/dnsmasq/vulnerabilities/dnsmasq)、[Google 分析](https://security.googleblog.com/2017/10/behind-masq-yet-more-dns-and-dhcp.html) | 相对少依赖配置，适合作为首个自动化 DoS |
| CVE-2017-14491 | DNS heap overflow；公开 PoC 主要为 ASAN/崩溃，不应承诺通用 RCE | [Google PoC 目录](https://github.com/google/security-research-pocs/tree/master/vulnerabilities/dnsmasq)、[EDB 42941](https://www.exploit-db.com/exploits/42941) | 上游 DNS、缓存命中顺序不确定，可能需重启重试 |
| CVE-2017-14492 | DHCPv6/RA heap overflow；公开目标主要为崩溃 | [EDB 42942](https://www.exploit-db.com/exploits/42942) | IPv6、DHCPv6、RA/raw packet、UDP 547 |
| CVE-2017-14493 | DHCPv6 stack overflow；公开目标主要为崩溃 | [EDB 42943](https://www.exploit-db.com/exploits/42943) | DHCPv6 relay/UDP 547 |
| CVE-2017-14494 | DHCPv6 relay 信息泄露 | [EDB 42944](https://www.exploit-db.com/exploits/42944) | 真实 DHCPv6 relay、服务器 DUID，非一键复现 |
| CVE-2017-14495 | 内存泄漏/OOM DoS | [EDB 42945](https://www.exploit-db.com/exploits/42945) | 需要 `--add-mac`、`--add-cpe-id` 或 `--add-subnet`；必须限速 |
| CVE-2017-14496 | 整数下溢/超大 memcpy，DoS | [EDB 42946](https://www.exploit-db.com/exploits/42946) | 需要上述 `--add-*` 选项，适合单包 DoS 验证 |

官方二级交叉材料：[CERT-EU 2017-020](https://www.cert.europa.eu/publications/security-advisories/2017-020/)。该材料将 7 个漏洞归类为潜在 RCE、信息泄露和 DoS；但 **Exploit-DB/Google 公开 PoC 主要验证崩溃、ASAN、泄露或资源耗尽**，不能把“潜在 RCE”写成稳定 RCE。

DNSSEC 相关的 `CVE-2020-25681~25687`、`CVE-2023-50387`、`CVE-2023-50868` 只有在编译并启用 DNSSEC validation 时才有意义；DNSpooq 可参考 [CERT/CC VU#434904](https://www.kb.cert.org/vuls/id/434904) 和 [JSOF 白皮书](https://www.jsof-tech.com/wp-content/uploads/2021/01/DNSpooq_Technical-Whitepaper.pdf)，但不建议作为第一批稳定 PoC。

#### 异构化建议

- V1：GCC `-O2`、动态链接；
- V2：Clang `-O2 -flto`；
- V3：GCC `-Os`、无 LTO、不同链接顺序；
- 保持 DHCPv6、IPv6、DNSSEC 等 PoC 所需功能一致；
- 对 DNS/DHCP 包解析、长度检查外围封装、内存分配封装做等价源码改写；
- Google PoC 的 Dockerfile 未锁定源码 commit，且旧 Debian/LLVM 与路径说明存在问题，必须自行 checkout 2.76 后验证，不能宣称一键复现。

---

### 3.2 ImageMagick

- 当前上游版本：**7.1.2-34**，见[官方下载页](https://imagemagick.org/download/)；
- 推荐复现版本：**6.9.3-3**；
- 攻击面：`convert`、`identify`、SVG/MVG/MSL、URL delegate、Ghostscript 和图片上传处理链；
- 规模：中等偏大，但漏洞类型最丰富。

#### ImageTragick 五连

| CVE | 类型 | 公开来源 |
|---|---|---|
| CVE-2016-3714 | shell injection；PoC 需要目标处理恶意文件，EDB 标为 LOCAL，不是无条件远程 RCE | [ImageTragick PoC 仓库](https://github.com/ImageTragick/PoCs)、[EDB 39767](https://www.exploit-db.com/exploits/39767)、[Metasploit EDB 39791](https://www.exploit-db.com/exploits/39791) |
| CVE-2016-3715 | `EPHEMERAL` 任意文件删除 | [ImageTragick](https://imagetragick.com/) |
| CVE-2016-3716 | `MSL` 任意文件移动/写入 | [ImageTragick](https://imagetragick.com/) |
| CVE-2016-3717 | `LABEL` 任意文件读取 | [ImageTragick](https://imagetragick.com/) |
| CVE-2016-3718 | HTTP/FTP SSRF | [ImageTragick](https://imagetragick.com/) |

关键前置条件：

- 固定并记录 `policy.xml`、delegate、coder 和 Ghostscript 版本；
- 使用 ImageMagick 自带 SVG/MVG 解析器，不能把 `rsvg` 的结果混入；
- 记录 wget/curl、Ghostscript 是否安装；
- 不要只看扩展名，`identify` 自身也可能进入漏洞路径；
- `6.9.3-9` 的修复曾不完整，`6.9.3-3` 更适合固定为竞赛基线。

可增加的崩溃/内存安全样本：

- `CVE-2016-5687/5688/5689/5690/5691`：DDS、WPG、DCM/DICOM parser；
- 样本见 [Fuzzing Project 公告](https://blog.fuzzing-project.org/46-Various-invalid-memory-reads-in-ImageMagick-WPG%2C-DDS%2C-DCM.html)。

如果选择 6.9.10 分支，应完整锁定 `6.9.10-1/-23/-36` 等补丁号。`CVE-2018-20467` 可用于 `<6.9.10-16` 的 BMP 无限循环 DoS，参考[官方 Issue 1408](https://github.com/ImageMagick/ImageMagick/issues/1408)和[样本](https://github.com/ImageMagick/ImageMagick/files/2652794/POC1.zip)。`CVE-2019-10714`、`CVE-2019-17541` 也可作为受控崩溃样本，但都应标为 DoS/UAF/ASAN，不要直接宣称 RCE。

`CVE-2020-29599` 在 ImageMagick 6.x 仅是 NVD 范围内的理论影响，研究者未完成稳定 IM6 PoC；Vulhub 的 7.0.10-36 MSL PoC 不应直接套用。`CVE-2023-34152` 还要求显式启用 `--enable-pipes`，不能视为默认漏洞。

#### 异构化建议

- 保持 coder、delegate、policy 配置相同；
- 使用 Q8/Q16、HDRI/非 HDRI、GCC/Clang、静态/动态模块、不同优化级别；
- 对 coder dispatch、路径处理封装和 delegate 调用做语义等价重构；
- DoS 测试必须设置 CPU/内存限制、超时和每队独立容器。

---

### 3.3 NGINX

- 当前版本：Stable **1.30.6** / Mainline **1.31.8**，见[官网](https://nginx.org/en/download.html)；
- 推荐复现版本：**1.13.2**；
- 攻击面：HTTP 80/443、Range/缓存、resolver、MP4 模块。

| CVE | 类型 | 公开来源 | 触发条件 |
|---|---|---|---|
| CVE-2017-7529 | Range 整数溢出，主要表现为缓存文件头/内存信息泄露 | [官方公告](https://mailman.nginx.org/pipermail/nginx-announce/2017/000200.html)、[PoC](https://github.com/cyberharsh/nginx-CVE-2017-7529) | Range + cache |
| CVE-2021-23017 | resolver 单字节内存破坏，官方描述可达 DoS/潜在 RCE | [官方公告](https://mailman.nginx.org/pipermail/nginx-announce/2021/000300.html)、[PoC](https://github.com/M507/CVE-2021-23017-PoC) | `resolver` 配置，需构造/伪造 DNS UDP 响应 |
| CVE-2022-41741 | MP4 解析内存破坏/崩溃 | [官方公告](https://mailman.nginx.org/pipermail/nginx-announce/2022/RBRRON6PYBJJM2XIAPQBFBVLR4Q6IHRA.html)、[evilMP4](https://github.com/dumbbutt0/evilMP4) | 编译并配置 `ngx_http_mp4_module` |
| CVE-2022-41742 | MP4 解析信息泄露 | 同上 | 同上 |

1.13.2 默认不一定包含 MP4 模块，也不一定启用 resolver/cache；因此版本命中不等于可利用。

#### 异构化建议

保持 `mp4`、resolver、缓存和 HTTP/2 模块完全一致，再改变 GCC/Clang、LTO、优化、函数封装、链接布局和动态模块组织。不要用错误的第三方 README 版本说明覆盖 NGINX 官方公告。

---

### 3.4 Samba

- 当前稳定版本：**4.25.1**，见[Samba Release History](https://www.samba.org/samba/history/)；
- 推荐复现版本：**4.6.3**；
- 攻击面：SMB TCP 445/139；AD DC 还包括 DNS、Kerberos、LDAP、RPC 等。

| CVE | 类型 | 公开来源 | 角色/配置条件 |
|---|---|---|---|
| CVE-2017-7494 | 可写 share 上传共享库并触发加载，RCE | [官方公告](https://www.samba.org/samba/security/CVE-2017-7494.html)、[Metasploit](https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/linux/samba/is_known_pipename.rb)、[EDB 42084](https://www.exploit-db.com/exploits/42084) | 文件服务器、可写 share、路径和权限条件 |
| CVE-2020-1472 | Zerologon，域接管/机器账户密码修改 | [官方公告](https://www.samba.org/samba/security/CVE-2020-1472.html)、[Metasploit](https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/admin/dcerpc/cve_2020_1472_zerologon.rb) | **仅 AD DC 场景**，需准备恢复动作 |
| CVE-2021-44142 | `vfs_fruit` 堆越界读写，可能 RCE/崩溃 | [官方公告](https://www.samba.org/samba/security/CVE-2021-44142.html)、[检测器/PoC](https://github.com/horizon3ai/CVE-2021-44142) | 启用 `vfs_fruit` 和相应扩展属性配置 |

#### 异构化建议

使用同一角色配置构建 V1/V2/V3，再改变编译器、优化级别、VFS 模块链接顺序和内存封装。建议把 AD DC、普通文件服务器、`vfs_fruit` 文件服务器分别作为独立测试角色，不能把所有 CVE 当作任意 Samba 服务通用漏洞。

---

### 3.5 OpenSSL

- 当前最新版本：**4.1.0**；LTS：**3.5.9**，见[官方下载页](https://openssl-library.org/source/index.html)；
- 推荐复现版本：**1.0.1f**，官方 tag：[OpenSSL_1_0_1f](https://github.com/openssl/openssl/tree/OpenSSL_1_0_1f)；
- 攻击面：TLS/DTLS/STARTTLS；需配合 `s_server` 或具体协议服务。

| CVE | 类型 | 公开来源 | 条件 |
|---|---|---|---|
| CVE-2014-0160 | Heartbleed，TLS heartbeat 越界读取 | [官方公告](https://openssl-library.org/news/secadv/20140407.txt)、[Metasploit](https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/scanner/ssl/openssl_heartbleed.rb)、[EDB 32764](https://www.exploit-db.com/exploits/32764) | 需要启用 TLS heartbeat |
| CVE-2014-0224 | CCS injection，协议状态机错误 | [官方公告](https://openssl-library.org/news/secadv/20140605.txt)、[Tripwire检测脚本](https://github.com/Tripwire/OpenSSL-CCS-Inject-Test) | 需 MITM，且 client/server 组合满足条件 |
| CVE-2014-0195 | DTLS fragment heap/buffer overflow | [Metasploit提交](https://github.com/rapid7/metasploit-framework/commit/8637a1fff176b3053c844ba70371de5aa6d39444)、[GitHub PoC](https://github.com/ricedu/CVE-2014-0195) | 仅 DTLS UDP 端点 |

#### 异构化建议

保持 Heartbeat、DTLS、CCS 功能不变，使用 `enable-asm/no-asm`、GCC/Clang、`shared/no-shared`、不同优化和链接布局。OpenSSL 1.0.1f 源码规模明显大于 dnsmasq，适合做第五候选而不是首选。

---

## 4. V1/V2/V3 实施方案

### 4.1 推荐编译矩阵

| 变体 | 编译器 | 优化/链接 | 源码策略 |
|---|---|---|---|
| V1 | GCC | `-O2`，动态链接 | 原始源码，仅做必要兼容修复 |
| V2 | Clang | `-O2 -flto`，不同链接顺序 | 增加等价 wrapper、改变 dispatch 组织 |
| V3 | GCC 或 Clang | `-Os`/无 LTO，保持相同安全缓解级别 | 改变状态机辅助函数、表顺序和内存封装 |

不要只改版本 banner。每个变体都应通过同一功能回归测试，并记录：

- `gcc/clang --version`；
- 完整编译命令；
- 依赖库和系统版本；
- 二进制 SHA-256、动态依赖、导出符号；
- 配置文件和启动参数哈希；
- CVE 复现日志、ASAN/GDB backtrace、崩溃信号或预期响应。

### 4.2 复现矩阵模板

| 软件/版本 | CVE | 前置条件 | POC 来源 | 预期结果 | V1 | V2 | V3 | 证据文件 |
|---|---|---|---|---|---|---|---|---|
| dnsmasq 2.76 | CVE-2017-13704 | DNS UDP 53 | Google PoC | 崩溃/ASAN | 待测 | 待测 | 待测 | `logs/dnsmasq-13704/` |
| ImageMagick 6.9.3-3 | CVE-2016-3717 | LABEL coder/policy | ImageTragick | 文件读取 | 待测 | 待测 | 待测 | `logs/im-3717/` |
| NGINX 1.13.2 | CVE-2017-7529 | Range + cache | GitHub PoC | 信息泄露/异常响应 | 待测 | 待测 | 待测 | `logs/nginx-7529/` |

只有当三套变体均有可重复证据时，才能在最终报告中写“已复现”。

---

## 5. 隔离与安全要求

- 旧版本仅运行于无公网隔离网络或独立容器/虚拟机；
- 禁止使用真实凭据、真实文件和生产 DNS/SMB/HTTP 数据；
- 使用非 root 用户、只读文件系统、快照回滚；
- DoS/ASAN 样本设置 CPU、内存、进程数和执行时间上限；
- Samba Zerologon 实验必须准备恢复流程；
- ImageMagick 的命令注入、文件读写和 delegate 测试必须使用合成目录；
- dnsmasq PoC 的 Dockerfile 必须自行 pin 源码版本，不能直接相信仓库现状是一键可复现。

---

## 6. 不列入主榜的候选

- **vsftpd 2.3.4**：`CVE-2011-2523` 只针对当年被植入后门的污染发行包，不能泛化到所有 2.3.4；
- **lighttpd、ProFTPD**：目前已核实的同一版本、三个独立且稳定公开 PoC 证据不足；
- **libtiff**：存在多个公开崩溃样本，但已核实的同版稳定 PoC 和独立根因数量不足；
- **ImageMagick 6.9.10**：适合做补丁号识别和 DoS/UAF 验证，不应把 `CVE-2020-29599` 或默认构建下的 `CVE-2023-34152` 直接当作稳定 RCE。

---

## 7. 最终推荐

如果比赛时间有限，建议采用：

> **V1：dnsmasq 2.76** 作为网络服务主线，配套 **ImageMagick 6.9.3-3** 作为解析器/命令处理备线。

第一批优先验证：

1. dnsmasq `CVE-2017-13704`：单 DNS 报文、崩溃/ASAN；
2. dnsmasq `CVE-2017-14496`：配置 `--add-subnet` 后的 DoS；
3. ImageMagick `CVE-2016-3717`：任意文件读取；
4. ImageMagick `CVE-2016-3718`：SSRF；
5. ImageMagick `CVE-2016-3714`：受控恶意文件处理链验证，明确其 LOCAL/输入处理前提。

这套组合同时覆盖网络协议解析、图片解析、内存安全、信息泄露、SSRF、文件操作和 DoS，且源码级异构化难度相对可控。
