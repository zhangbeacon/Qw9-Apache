# "第九届强网拟态防御国际精英挑战赛" 基准程序选型推荐报告

> 编制日期：2026-10-29
> 适用场景：选择 Linux 开源软件作为基准程序 V1，生成异构变体 V2/V3，并在三个变体上复现 ≥3 个历史漏洞（CVE）以获取漏洞验证环节高分。
> 赛题参考：[第九届"强网"拟态防御国际精英挑战赛官方文件](https://nest.pmlabs.com.cn/events/qiangwang-9/design-competition/files/qw9-design-challenge-zh.pdf) / [官方报名说明](http://mp.weixin.qq.com/s?__biz=Mzk0NTU0ODc0Nw==&mid=2247499457&idx=2&sn=6ca60bd10f01d79a63dce8a999c2587c)

---

## 0. 先说本题最大的"坑"：V1 必须钉在**含洞的历史版本**上

赛题要求在 V1/V2/V3 上**复现历史漏洞**——这意味着基准版本绝不能选最新 Release：最新版的历史 CVE 全部已修补，复现环节直接 0 分。

正确做法：

1. 按 NVD 的 **Affected Versions** 区间，把 V1 钉在一个"漏洞密度最高"的历史版本；
2. 在该版本上做异构变换（编译选项 / 源码级 / 运行时环境）；
3. 每个候选 CVE 先对照版本区间确认"未修补"，再投入复现。

下文每个目标都给出了具体的"钉版本"建议。

**选型五项硬指标**（与赛题对齐）：

| 维度 | 要求 |
|---|---|
| 平台与源码 | Linux x86-64 可编译，开源（C/C++ 优先，便于编译器级异构） |
| 漏洞丰富度 | CVE 数量多、CWE 类型覆盖广（内存安全 / 信息泄露 / RCE / DoS / 注入） |
| POC 可获取性 | GitHub / Exploit-DB / Metasploit / Vulhub 有公开可稳定复现的 POC（硬性指标） |
| 攻击面 | 网络服务接口（HTTP/FTP/DNS/TCP）或复杂外部输入解析（图像/压缩） |
| 体量适中 | 排除 Linux Kernel / Chrome 级巨型项目，也排除玩具程序 |

---

## 1. 五款推荐软件总表

| 软件名称与当前版本 | 软件简介与攻击面 | 已知 CVE 数量及主要漏洞类型 | 推荐复现的具体 CVE 及 POC 来源（重点） | 异构化潜力建议 |
|---|---|---|---|---|
| **nginx**<br>当前 stable 1.28.x / mainline 1.29.x（[官方 news](https://nginx.org/news.html)）<br>**建议 V1 钉版本：1.13.2** | HTTP/反向代理服务器，C 语言约 15 万行。攻击面：HTTP 请求行/头解析、Range 过滤、resolver、HTTP/2、mp4 流处理。纯 HTTP 打包攻击，自动化脚本最易写 | 约 70+（主服务口径）。类型覆盖广：**整数溢出信息泄露、堆溢出、off-by-one、UAF、HTTP/2 DoS** | ① CVE-2017-7529（Range 整数溢出→堆信息泄露）— [Vulhub 现成环境](https://github.com/CyberCTF/vulhub-nginx-cve-2017-7529)、[POC 仓库](https://github.com/youngmin0104/CVE-2017-7529-)<br>② CVE-2021-23017（resolver off-by-one → RCE，需 `resolver` 指令）— [z3usx01/CVE-2021-23017-POC](https://github.com/z3usx01/CVE-2021-23017-POC)、[EVIL-2025 增强版](https://github.com/6lj/EVIL-CVE-2021-23017-Update-2025)<br>③ CVE-2022-41741（mp4 模块 UAF 信息泄露）— [dumbbutt0/evilMP4](https://github.com/dumbbutt0/evilMP4)、[moften 检测 PoC](https://github.com/moften/CVE-2022-4174_CVE-2022-41742)<br>④ CVE-2019-9512/9514（HTTP/2 DoS，触发脚本极简单）<br>⑤ CVE-2019-20372（请求行 UAF DoS） | 三变体用 GCC/Clang/musl 三工具链；堆类漏洞换分配器（ptmalloc/jemalloc/tcmalloc）即出差分；resolver 类靠 `--with-cc-opt` 差异 + 不同 glibc；模块静态/DSO 编译方式本身也是异构维度 |
| **ProFTPD**<br>当前 1.3.9（[官网](http://www.proftpd.org/)）<br>**建议 V1 钉版本：1.3.5（拿 RCE 类型）或 1.3.6a（拿内存安全类×3）** | 老牌 FTP 服务端，C 语言约 10 万行，模块化架构（mod_copy/mod_ls/mod_memcache…）。攻击面：FTP 控制通道命令解析（含 pre-auth）、数据通道、SITE 扩展命令 | 约 55–60（[SOCRadar 统计](https://socradar.io/free-tools/cve-radar/vendors/proftpd)）。类型极全：**pre-auth 栈溢出 RCE、堆溢出、UAF、任意文件写入→RCE、空指针 DoS** | ① CVE-2015-3306（mod_copy 任意文件拷贝→webshell RCE，**pre-auth**）— Metasploit 模块 `linux/http/proftpd_modcopy_exec`，Exploit-DB 36842<br>② CVE-2010-4261（Telnet IAC 处理栈溢出，**pre-auth RCE**）— 官方 [Bug 3521](http://master.proftpd.org/show_bug.cgi?id=3521) 附分析，Exploit-DB 有现成利用<br>③ CVE-2020-9272/9273（pool 分配器 UAF）— [Gentoo Bug 710730](https://bugs.gentoo.org/show_bug.cgi?id=710730)<br>④ CVE-2019-18227（pool 堆溢出）— [CVE 详情](https://cve.komodosec.com/cve.php?id=CVE-2019-18227)，NVD 引用含触发样本 | **五款中最适合做异构**：自带内存池分配器，改池 chunk 尺寸即是源码级异构点；模块可按变体裁剪/重排；FTP 目录布局（chroot/docroot 路径）差异化可让 webshell 落地失效；编译器+分配器矩阵同 nginx |
| **dnsmasq**<br>当前 2.92（2026-01，[Buildroot 记录](https://lore.kernel.org/all/20260122191151.78D3F86967@busybox.osuosl.org/T/#u)）<br>**建议 V1 钉版本：2.77** | DNS+DHCP 轻量服务端，C 语言约 3 万行，单进程。攻击面：UDP 53/67 报文解析（DNS 名字解压缩、TXT 记录、DHCP 选项） | 约 30+。类型：**堆溢出/栈溢出、OOB 读写、缓存投毒、信息泄露、DoS**（2.78 前批量漏洞见 [OSSN-0082](https://docs.openstack.org/security-notes/OSSN-0082.html)） | 钉 2.77 一个版本可同时吃到两波：<br>① 2017 年 Google 审计批：CVE-2017-14491~14496 等 7 个（堆/栈溢出、OOB、信息泄露）<br>② 2021 年 DNSpooq 批：CVE-2020-25681~25687（缓存投毒+堆溢出，[CERT VU#434904](https://www.kb.cert.org/vuls/id/434904)）— [istoliving 的 DNSpooq PoC](https://github.com/istoliving/Vulnerability/blob/main/DNSpooq%20PoC%20-%20dnsmasq%20cache%20poisoning%20(CVE-2020-25686%2c%20CVE-2020-25684%2c%20CVE-2020-25685).md)、[knqyf263/dnspooq 分析套件](https://relatedrepos.com/gh/knqyf263/dnspooq) | 单一 C 文件入口（`src/dnsmasq.c`），源码级改写快；scapy 脚本打 UDP 即可全自动攻击；变体用不同编译器 + `-D_FORTIFY_SOURCE=2/3` + 换分配器，OOB 类行为即出现差分 |
| **memcached**<br>当前 1.6.42+（[Debian 跟踪](https://tracker.debian.org/pkg/memcached/news/?page=1)，2026-05 进入 testing）<br>**建议 V1 钉版本：1.4.31** | 高性能缓存服务端，C 语言约 2.5 万行。攻击面：裸 TCP 文本/二进制协议解析、item 头部长度字段、SASL | 约 12–15。数量少但**质量极高**：整数溢出→堆 OOB 写→**pre-auth RCE**、SASL 整数溢出、DoS | 钉 1.4.31 一次覆盖三连（均修复于 1.4.33，见 [DevGuard](https://docs.devguard.org/vulnerability-database/DEBIAN-CVE-2016-8704/)）：<br>① CVE-2016-8704（item 头整数溢出→堆溢出 RCE，CVSS 9.8）<br>② CVE-2016-8705（SASL 命令整数溢出）<br>③ CVE-2016-8706（lru_crawler 整数溢出）<br>GitHub 搜 "CVE-2016-8704" 有多个复现仓库；二进制协议触发逻辑极简单，按 NVD 描述半小时可自写稳定 POC | 自带 slab 分配器，`-f`（增长因子）`-n`（chunk 对齐）参数即天然堆布局异构点；再叠加 jemalloc/tcmalloc 三种分配器，同一溢出 POC 在三变体上表现出"RCE/崩溃/无恙"三态——**差分效果演示性最强** |
| **libtiff**<br>当前 4.7.1（[Release Notes](https://libtiff.gitlab.io/libtiff/_sources/releases/v4.7.1.rst.txt)）<br>**建议 V1 钉版本：4.5.0** | TIFF 图像解析库 + `tiffcp/tiffsplit/tiff2pdf` 等工具链，C 语言约 8 万行。攻击面：IFD 目录、条带/瓦片解码、压缩算法（LZW/PackBits/Thunder）等复杂外部输入解析 | **200+，五款之最**。类型：堆 OOB 读/写、UAF、空指针 DoS、整数溢出、越界读信息泄露 | 钉 4.5.0 覆盖 2023 年 OSS-Fuzz 批量披露：<br>① CVE-2023-0795~0801（8 连发：堆越界读/写、空指针 DoS，NVD 引用/GitLab issue 均附 oss-fuzz 触发样本）<br>② CVE-2023-26965（[官方修复记录](https://patchwork.yoctoproject.org/project/oe-core/patch/20230628172552.2122139-1-nat.bailey@windriver.com/)）<br>③ CVE-2023-25433/26966/2798 同版本可复现 | 工具链入口即"输入→崩溃"单命令，自动化最简单；变体差分靠编译器矩阵 + FORTIFY + 分配器；若赛制需要网络面，给它包一层 10 行的 HTTP 上传→tiffcp 微服务即可 |

---

## 2. 分目标 CVE 复现清单（含钉版本与触发前提）

### 2.1 nginx（V1 = 1.13.2）

| CVE | 类型（CWE 方向） | 触发前提 | 判定条件 | POC 来源 |
|---|---|---|---|---|
| CVE-2017-7529 | 整数溢出→堆信息泄露 | 构造恶意 Range 头（负数起点） | 响应体中出现非预期内存内容 | [Vulhub](https://github.com/CyberCTF/vulhub-nginx-cve-2017-7529)、[POC](https://github.com/youngmin0104/CVE-2017-7529-) |
| CVE-2021-23017 | resolver off-by-one → 堆溢出→RCE | 配置 `resolver` 指令 + 自建恶意 DNS 回复（UDP 伪造） | worker 崩溃 / 内存破坏 | [z3usx01 POC](https://github.com/z3usx01/CVE-2021-23017-POC)、[EVIL 增强版](https://github.com/6lj/EVIL-CVE-2021-23017-Update-2025) |
| CVE-2022-41741/41742 | mp4 模块 UAF→信息泄露 | 编译含 `--with-http_mp4_module`，上传恶意 mp4 | 响应泄露/崩溃 | [dumbbutt0/evilMP4](https://github.com/dumbbutt0/evilMP4)、[moften PoC](https://github.com/moften/CVE-2022-4174_CVE-2022-41742) |
| CVE-2019-9512/9514 | HTTP/2 DoS | 编译含 http_v2 模块，h2c 连接 | CPU/内存耗尽 | 公开触发脚本极多 |
| CVE-2019-20372 | 请求行 UAF→DoS | 特制超长/畸形请求行 + `Content-Length` 组合 | worker 崩溃 | NVD 引用附样本 |

### 2.2 ProFTPD（V1 = 1.3.5 或 1.3.6a，二选一）

| 钉版本 | CVE | 类型 | 触发前提 | POC 来源 |
|---|---|---|---|---|
| 1.3.5 | CVE-2015-3306 | 任意文件写入→RCE（pre-auth） | 加载 mod_copy，SITE CPFR/CPTO 拷 webshell | Metasploit `linux/http/proftpd_modcopy_exec`、Exploit-DB 36842 |
| 1.3.5 | CVE-2017-7418 | 空指针 DoS | 特定命令序列 | NVD 引用 |
| 1.3.6a | CVE-2019-18227 | pool 堆溢出 | 特制 FTP 命令（部分需有效账号，自建环境可控） | [CVE 详情](https://cve.komodosec.com/cve.php?id=CVE-2019-18227)、NVD 引用 |
| 1.3.6a | CVE-2020-9272/9273 | pool 分配器 UAF | 触发 pool 释放重用路径 | [Gentoo Bug 710730](https://bugs.gentoo.org/show_bug.cgi?id=710730) |
| （备选老钉 1.3.3b） | CVE-2010-4261 | Telnet IAC 栈溢出（pre-auth RCE） | 控制通道发送 IAC 字节序列 | 官方 [Bug 3521](http://master.proftpd.org/show_bug.cgi?id=3521)、Exploit-DB |

> 取舍说明：单一版本无法同时覆盖 3306（修复于 1.3.6）与 9272（修复于 1.3.6c）。要"RCE 类型分"钉 1.3.5；要"内存安全类×3"钉 1.3.6a。按赛题评分权重定夺。

### 2.3 dnsmasq（V1 = 2.77）

| CVE 批次 | 类型 | 触发前提 | POC 来源 |
|---|---|---|---|
| CVE-2017-14491~14496（7 个） | 堆/栈溢出、OOB 读写、信息泄露 | UDP 53 特制 DNS 报文（名字解压缩路径） | [OSSN-0082 分析](https://docs.openstack.org/security-notes/OSSN-0082.html)、Arch [ASA-201710-1](https://security.archlinux.org/ASA-201710-1/raw) |
| CVE-2020-25681~25687（DNSpooq） | DNS 缓存投毒 + 堆溢出 | 伪造 DNS 回复竞速/特制记录 | [CERT VU#434904](https://www.kb.cert.org/vuls/id/434904)、[istoliving PoC](https://github.com/istoliving/Vulnerability/blob/main/DNSpooq%20PoC%20-%20dnsmasq%20cache%20poisoning%20(CVE-2020-25686%2c%20CVE-2020-25684%2c%20CVE-2020-25685).md)、[knqyf263/dnspooq](https://relatedrepos.com/gh/knqyf263/dnspooq) |

### 2.4 memcached（V1 = 1.4.31）

| CVE | 类型 | 触发前提 | POC 来源 |
|---|---|---|---|
| CVE-2016-8704 | 整数溢出→堆 OOB 写→RCE（CVSS 9.8） | 二进制协议 item 头超长 key/size 字段 | GitHub 搜 "CVE-2016-8704" 多个复现仓库；[DevGuard 详情](https://docs.devguard.org/vulnerability-database/DEBIAN-CVE-2016-8704/) |
| CVE-2016-8705 | SASL 整数溢出 | 启用 SASL + 特制认证包 | 同上 |
| CVE-2016-8706 | lru_crawler 整数溢出 | 特制命令 | 同上 |

### 2.5 libtiff（V1 = 4.5.0）

| CVE | 类型 | 触发前提 | POC 来源 |
|---|---|---|---|
| CVE-2023-0795~0801（8 连发） | 堆 OOB 读/写、空指针 DoS | `tiffcp`/`tiffinfo` 等工具 + 恶意 tif 样本 | NVD 引用 / GitLab issue 附 oss-fuzz 触发样本 |
| CVE-2023-26965 | 崩溃类 | 特制 tif | [官方修复记录](https://patchwork.yoctoproject.org/project/oe-core/patch/20230628172552.2122139-1-nat.bailey@windriver.com/) |
| CVE-2023-25433/26966/2798 | 堆越界/崩溃 | 特制 tif | 同批 oss-fuzz 样本 |

---

## 3. 综合得分潜力排序与点评

结合赛题三要素——**网络接口→攻击自动化难度、外部输入处理→类型覆盖度、异构变体自动生成→变换速度与差分效果**：

| 排名 | 软件 | 一句话定位 |
|---|---|---|
| 🥇 1 | **nginx** | 均衡性之王：5 个 CVE 横跨四类 CWE，全部"发 HTTP 请求"级自动化；Vulhub/Metasploit/GitHub POC 生态最成熟，复现确定性最高。注意 CVE-2021-23017 需 `resolver` 指令 + 恶意 DNS 环境 |
| 🥈 2 | **ProFTPD** | 拟态差分教科书：pre-auth RCE + 内存破坏搭配类型最全；FTP 目录/模块级异构让 mod_copy webshell 直接失效，演示差分价值最直观；单一钉版本无法同时吃下 3306 与 9272，需取舍 |
| 🥉 3 | **dnsmasq** | 单版本漏洞密度之王：钉 2.77 白嫖 12+ CVE（两波审计叠加）；代码最小、变体生成最快、scapy 全自动。扣分：缓存投毒判定链路略繁琐，OOB 读类"是否算失效"需与裁判对齐口径 |
| 4 | **memcached** | 最快出分但天花板低：一条 TCP 连接触发 8704，slab 参数差分演示效果拉满；但 CVE 总量少、类型集中，"类型丰富度"加分吃不满。适合保底或第二赛道 |
| 5 | **libtiff** | CVE 池最深但形态吃亏：200+ CVE 且 oss-fuzz 样本密度极高；本质是解析库非网络服务，需自建 wrapper 才贴合"网络接口"加分；类型偏内存类 |

**决策建议**：只能选一个 → **nginx 钉 1.13.2**；评委看重"同一版本复现数量" → **dnsmasq 钉 2.77**。

---

## 4. 落地建议

### 4.1 推荐异构矩阵（功能等价前提下最大化差分）

| 变体 | 工具链 | 分配器 | 加固 | 差分来源 |
|---|---|---|---|---|
| V1 基准 | GCC（老版本） | glibc ptmalloc | 无加固 | POC 全部成功 |
| V2 | Clang `-O2 -flto` | jemalloc | `-fstack-protector-strong -D_FORTIFY_SOURCE=2` + PIE + full RELRO | 堆布局/栈结构改变 → 溢出/UAF 类 POC 大概率失效或仅崩溃 |
| V3 | musl（Alpine 基础镜像）或不同代 GCC | tcmalloc/mimalloc | `-fno-omit-frame-pointer` + `MALLOC_PERTURB_` + 不同 glibc（有无 tcache） | UAF/整数溢出类差分 + 运行时环境差分 |

### 4.2 执行层三条经验

1. **每 CVE 写成"触发脚本 + 机器可判定条件"**（退出码 / core dump / 响应差异 / 文件落地），打包成 YAML 矩阵，验证环节直接跑。示例：

   ```yaml
   - target: nginx-1.13.2
     cve: CVE-2017-7529
     trigger: python3 poc_7529.py http://$TARGET/
     verdict:
       - condition: response_contains_memory_leak
         expect: { V1: hit, V2: miss, V3: miss }
   ```

2. **老版本 × 新工具链有编译坑**（`-Werror`、隐式函数声明等）：直接用 ubuntu:16.04 / centos:7 老基础镜像或加 `-Wno-error` 补丁，别硬扛。
3. **变体完成后先跑功能等价测试**（正常流量回放比对三变体输出一致），再跑 CVE 矩阵——功能不等价会被扣分，比复现失败更冤。

### 4.3 落选候选说明

| 候选 | 落选原因 |
|---|---|
| Exim（[CVE-2019-10149 RCE POC](https://github.com/CybersRMUTL/CVE-2019-10149-Exim4-RCE/blob/main/raptor.sh)、[PoC 仓库](https://github.com/uyerr/PoC_CVE-2019-10149--rce) 极成熟） | 邮件协议栈环境搭建重，比赛时间内自动化不划算 |
| Samba | CVE 数量碾压但代码量约 150 万行，异构编译与源码变换时间预算撑不住 |
| vsftpd | 体量合适但 CVE 总数不到 5 个，密度不够 |
| lighttpd | CVE 数量与类型丰富度均不及 nginx，POC 生态弱一档 |

---

## 5. 参考资料索引

- 赛题：[第九届"强网"拟态防御大赛官方文件](https://nest.pmlabs.com.cn/events/qiangwang-9/design-competition/files/qw9-design-challenge-zh.pdf) / [官方报名推文](http://mp.weixin.qq.com/s?__biz=Mzk0NTU0ODc0Nw==&mid=2247499457&idx=2&sn=6ca60bd10f01d79a63dce8a999c2587c)
- nginx：[官方 news](https://nginx.org/news.html) / [CVE-2017-7529 Vulhub](https://github.com/CyberCTF/vulhub-nginx-cve-2017-7529) / [CVE-2017-7529 POC](https://github.com/youngmin0104/CVE-2017-7529-) / [CVE-2021-23017 POC](https://github.com/z3usx01/CVE-2021-23017-POC) / [CVE-2021-23017 EVIL 增强版](https://github.com/6lj/EVIL-CVE-2021-23017-Update-2025) / [evilMP4（CVE-2022-41741）](https://github.com/dumbbutt0/evilMP4) / [moften PoC](https://github.com/moften/CVE-2022-4174_CVE-2022-41742)
- ProFTPD：[官网](http://www.proftpd.org/) / [SOCRadar CVE 统计](https://socradar.io/free-tools/cve-radar/vendors/proftpd) / [Telnet IAC Bug 3521](http://master.proftpd.org/show_bug.cgi?id=3521) / [Gentoo Bug 710730（CVE-2020-9272/9273）](https://bugs.gentoo.org/show_bug.cgi?id=710730) / [CVE-2019-18227 详情](https://cve.komodosec.com/cve.php?id=CVE-2019-18227)
- dnsmasq：[Buildroot 2.92 记录](https://lore.kernel.org/all/20260122191151.78D3F86967@busybox.osuosl.org/T/#u) / [OSSN-0082（2.78 前溢出批）](https://docs.openstack.org/security-notes/OSSN-0082.html) / [CERT VU#434904（DNSpooq）](https://www.kb.cert.org/vuls/id/434904) / [istoliving DNSpooq PoC](https://github.com/istoliving/Vulnerability/blob/main/DNSpooq%20PoC%20-%20dnsmasq%20cache%20poisoning%20(CVE-2020-25686%2c%20CVE-2020-25684%2c%20CVE-2020-25685).md) / [knqyf263/dnspooq](https://relatedrepos.com/gh/knqyf263/dnspooq)
- memcached：[Debian 跟踪（1.6.42）](https://tracker.debian.org/pkg/memcached/news/?page=1) / [DevGuard CVE-2016-8704](https://docs.devguard.org/vulnerability-database/DEBIAN-CVE-2016-8704/)
- libtiff：[4.7.1 Release Notes](https://libtiff.gitlab.io/libtiff/_sources/releases/v4.7.1.rst.txt) / [CVE-2023-26965 修复记录](https://patchwork.yoctoproject.org/project/oe-core/patch/20230628172552.2122139-1-nat.bailey@windriver.com/)
- Exim：[raptor.sh（CVE-2019-10149）](https://github.com/CybersRMUTL/CVE-2019-10149-Exim4-RCE/blob/main/raptor.sh) / [PoC 仓库](https://github.com/uyerr/PoC_CVE-2019-10149--rce)

> 备注：文中"当前版本"以 2026-10 检索结果为准；所有 POC 仓库均已在撰写时核验可访问。POC 仅限本地/比赛隔离环境复现使用，注意合规。
