# Apache httpd 2.4.49 —— CVE 复现（强网拟态第九届）

本目录负责 **Apache HTTP Server 2.4.49** 的 **11 个历史 CVE** 复现（3 个原有 + 8 个新增）。所有结论均可用
`build/` + `conf/` + `poc/` + `evidence/` 从零重跑，证据均为本机原始输出，未编造。

> 状态：**10/11 已复现**；CVE-2022-23943 静态定位完成、动态受内存限制（>2GiB 单行需 ~9–10GiB），如实标注。
> 每个 CVE 的 `poc/<CVE>/verify.sh` 退出码 0 = 命中（23943 未复现返回 3）。

## 1. 版本与环境

| 项 | 值 |
|---|---|
| 软件 | Apache httpd **2.4.49**（`httpd -v`：`Apache/2.4.49 (Unix)`） |
| 源码 | `_downloads/httpd-2.4.49.tar.gz`，sha256 `345d3b9b218b1974d1cebd5ae72f6a661d83b52d839310222ff9ec94abb62205` |
| 上游源码 | <https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.gz> |
| 平台 | WSL1 `Ubuntu-CTF`（Ubuntu 22.04，gcc 11.4，root） |
| 端口 | 主 8082；新增复现用 8090–8096（各 CVE 独立端口，脚本自管） |
| 普通构建 | `/opt/httpd`，`bin/httpd` sha256 `2b0bcb3fa5a4a069c83857a3ee84640d91b5b4a71aede60b5f1d42ad9c6f2c30` |
| ASAN 构建 | `/opt/httpd-asan`，`bin/httpd` sha256 `37fd22c5ecd636983fce2bca8a11203076924fb800a36f8c64e76425dea0b688` |
| 修复版对照 | Ubuntu 22.04 `apache2-bin 2.4.52-1ubuntu4.25`，`/usr/sbin/apache2` sha256 `ace7ae371f972f041e1bf43386ce30c9cdb18a98c679e84764381b198c8965c5` |
| 构建日志 | `build/build-normal.log`、`build/build-asan.log`、`build/build-2450.log` |

## 2. 11 个 CVE 状态表

| CVE | 类型 | 判定条件 | 状态 | 复跑 |
|---|---|---|---|---|
| CVE-2021-41773 | 路径穿越 → 文件读 + CGI RCE | `/etc/passwd` 出现 `root:x:0:0`；CGI 输出 `uid=0(root)` | ✅ 成功 | `poc/CVE-2021-41773/verify.sh` |
| CVE-2021-44224 | forward proxy + UDS SSRF | 声明/任意 UDS 均收到 `GET /secret`；2.4.52 500 且零请求 | ✅ 成功（SSRF A+B） | `poc/CVE-2021-44224/verify.sh` |
| CVE-2021-44790 | mod_lua 整数下溢 → 崩溃/DoS | SIGSEGV(11)/Abort(6) + `memcpy n=SIZE_MAX` | ✅ 成功 | `poc/CVE-2021-44790/verify.sh` |
| CVE-2021-42013 | 路径穿越（41773 补丁绕过） | 2.4.49 单层+双重均 200；2.4.50 单层 400/双重 200；2.4.52 全 400 | ✅ 成功 | `poc/CVE-2021-42013/verify.sh` |
| CVE-2022-22719 | mod_lua 未初始化值 | Valgrind `Use of uninitialised value` @ `lua_request.c:401`（来源 `:373`）；阴性 0 | ✅ 成功（Valgrind） | `poc/CVE-2022-22719/verify.sh` |
| CVE-2022-22720 | 请求走私（连接未关闭） | 同 socket 第二请求被处理；2.4.52 408+close | ✅ 成功 | `poc/CVE-2022-22720/verify.sh` |
| CVE-2022-37436 | 响应头截断/响应走私 | 安全头进 body；2.4.52 502 | ✅ 成功 | `poc/CVE-2022-37436/verify.sh` |
| CVE-2022-23943 | mod_sed 越界写 | 静态定位；动态需 >2GiB 单行（~9–10GiB 峰值） | ⚠️ 静态定位（未复现） | `poc/CVE-2022-23943/verify.sh`（exit 3） |
| CVE-2023-25690 | RewriteRule 回注请求走私 | 后端同连接收到两行请求；2.4.52 403 | ✅ 成功 | `poc/CVE-2023-25690/verify.sh` |
| CVE-2023-27522 | uwsgi 响应走私 | 安全头进 body；2.4.52 502 | ✅ 成功 | `poc/CVE-2023-27522/verify.sh` |
| CVE-2024-38474 | mod_rewrite `%3f` 替换编码 | 越权读 secret 3/3、源码泄露、handler 执行；对照 404；2.4.52 403 | ✅ 成功 | `poc/CVE-2024-38474/verify.sh` |

> 负向对照：`poc/fixed_2.4.52/verify_negative_{response,A,38474_22719}.sh` 全部 `NEGATIVE CONTROL PASS`。
> 说明：42013 与 41773 同根因（不计第二个分），详细报告见 `report/CVE-2021-42013.md`。


## 3. 目录结构

```
apache/
├── README.md                     # 本文件
├── build/
│   ├── build.sh                  # 从 tarball 到可运行 httpd（normal / asan）
│   ├── install_deps.sh           # 依赖安装（含 dpkg 锁等待）
│   ├── build-normal.log          # 普通构建完整日志
│   ├── build-asan.log            # ASAN 构建完整日志
│   ├── check_env.sh              # 环境自检
│   └── *.sh                      # 复现过程中的诊断/辅助脚本（保留备查）
├── conf/
│   ├── httpd.conf                # 主配置：41773（Alias /icons/、ScriptAlias /cgi-bin/、Require all granted）
│   ├── httpd-44224.conf          # ProxyRequests On + ProxyPass unix:...（混合正/反向代理）
│   ├── httpd-44790.conf          # LuaMapHandler /parsebody -> parsebody.lua
│   └── lua/parsebody.lua         # 调用 r:parsebody() 的漏洞入口
├── poc/
│   ├── CVE-2021-41773/ {poc.sh, verify.sh}
│   ├── CVE-2021-44224/ {poc.py, uds_backend.py, verify.sh}
│   ├── CVE-2021-44790/ {poc.py, verify.sh}
│   └── fixed_2.4.52/verify_negative_ubuntu.sh   # 修复版负向对照（Ubuntu 2.4.52）
├── evidence/
│   ├── CVE-2021-41773/
│   ├── CVE-2021-44224/
│   ├── CVE-2021-44790/
│   └── fixed_2.4.52_build.txt                   # 修复版版本/sha256
└── report/
    ├── CVE-2021-41773.md
    ├── CVE-2021-44224.md
    └── CVE-2021-44790.md
```

## 4. 一键复跑

WSL 内执行（每个脚本自己负责部署配置、起服务、打 PoC、判定、收日志）：

```bash
ROOT=/mnt/e/强网拟态/cve/apache

# 0) 依赖（首次；会自动等待 dpkg 锁）
bash $ROOT/build/install_deps.sh

# 1) 构建（按需）
bash $ROOT/build/build.sh normal     # -> /opt/httpd      (41773 / 44224)
bash $ROOT/build/build.sh asan       # -> /opt/httpd-asan (44790)

# 2) 三个 CVE 判定（退出码 0 = 命中）
bash $ROOT/poc/CVE-2021-41773/verify.sh
bash $ROOT/poc/CVE-2021-44224/verify.sh
bash $ROOT/poc/CVE-2021-44790/verify.sh

# 3) 修复版负向对照（Ubuntu Apache/2.4.52；退出码 0 = 三个 CVE 均不再命中）
bash $ROOT/poc/fixed_2.4.52/verify_negative_ubuntu.sh
```

实测结果：

```
CVE-2021-41773 -> RESULT: PASS
CVE-2021-44224 -> RESULT: PASS (SSRF: declared UDS + arbitrary UDS)
CVE-2021-44790 -> RESULT: PASS (crash/DoS)
fixed 2.4.52   -> RESULT: NEGATIVE CONTROL PASS (41773/44224/44790 all fixed)
```

## 5. 复现要点与前提（报告里均有展开）

1. **41773**
   - `<Directory /> Require all granted` 是文件读取/穿越成立的必要配置；默认 `Require all denied` 会 403。
   - 文件读取必须经 **Alias-like 前缀**：本机直穿 DocumentRoot 会被 `AH00127 above the root path` 拦成 403；
     `ScriptAlias` 前缀会走 CGI 执行，读 `/etc/passwd` 得 500。因此配置里同时保留
     `Alias /icons/`（读文件）与 `ScriptAlias /cgi-bin/`（RCE exec `/bin/sh`）。
   - RCE 命令以 root 执行，是实验配置**故意不写 `User`** 的结果；真实环境权限等于 CGI 运行用户。
2. **44224**
   - 前提是管理员**同时**开启 `ProxyRequests On` 且配置里存在可被匹配的 ProxyPass worker（CVE 原文 “mixing forward and reverse proxy declarations”）。
   - 变体 A：worker 以 `unix:` 声明时，`worker->s->uds_path` 优先，请求被导向**声明的 UDS**（advisory 表述）。
   - 变体 B：worker 是普通 TCP（无 uds_path）时，`proxy_util.c:2610` 回退到请求 note 中的 attacker path，
     攻击者可用 `unix:<任意路径>|http://<该 worker 的 host>/...` 打到**任意 UDS**；本实验用未声明的 evil socket 验证。
   - 判定用“两个 UDS 后端各自收到请求 + 客户端拿到 UDS secret + error_log 两条 UDS 路径”，不依赖崩溃。
3. **44790**
   - 前提：`--enable-lua` 且站点有 Lua 脚本调用 `r:parsebody()`（本实验用 `LuaMapHandler`）。
   - `vlen = end - crlf - 8` 是 `size_t`，boundary 距 `\r\n\r\n` 小于 8 字节时下溢；
     `pad=3`（差 7）→ `vlen=SIZE_MAX` → `memcpy(..., SIZE_MAX)`；`pad=0`（差 4）→ 巨量 `apr_pcalloc` → abort。
   - ASAN 构建可稳定得到 SIGSEGV；WSL1 下 ASAN 完整符号化报告受 “nested bug in the same thread” 限制，
     报告文件只有分隔线，判定以 error_log 的子进程信号为准（详见 `report/CVE-2021-44790.md` §7）。

## 6. 原始证据索引（一句话结论）

- `evidence/CVE-2021-41773/file_read_passwd.txt`：`root:x:0:0:root:/root:/bin/bash`（1487 字节，HTTP 200）。
- `evidence/CVE-2021-41773/rce_id.txt`：`uid=0(root) gid=0(root)` + `uname -a`。
- `evidence/CVE-2021-41773/verdict.txt`：`file_read=1 file_read_secret=1 rce_root=1`。
- `evidence/CVE-2021-44224/ssrf_declared.txt`：`SECRET_FROM_UDS_DECLARED`（声明的 UDS worker）。
- `evidence/CVE-2021-44224/ssrf_arbitrary.txt`：`SECRET_FROM_UDS_ARBITRARY`（攻击者任意 UDS 路径）。
- `evidence/CVE-2021-44224/evil_backend.log`：未声明的 evil UDS 收到 `GET /secret HTTP/1.1`。
- `evidence/CVE-2021-44224/error_log.txt`：两条 `AH02545: ... determined UDS as ...`（分别指向声明/attacker 路径）。
- `evidence/CVE-2021-44790/error_log.txt`：`AH00051: child pid ... exit signal Segmentation fault (11)` 与 `Abort (6)`。
- `evidence/CVE-2021-44790/plain_build_abort_evidence.txt`：普通构建 `[crit] Memory allocation failed, aborting process.`。
- `evidence/CVE-2021-44790/logmemcpy_huge_call.txt`：`memcpy n=SIZE_MAX`，调用点 `mod_lua.so+0x13625`。
- `evidence/fixed_2.4.52_build.txt`：`Apache/2.4.52 (Ubuntu)` + sha256；三个 `fixed_2.4.52_negative.txt` 为修复版负向对照。
- 每个 CVE 的 `00_version_build.txt`：`httpd -v`、`sha256sum`、`file`/`ldd`。

## 7. 遗留问题

1. **CVE-2021-44224 的 NULL deref 崩溃分支未复现**：`GET unix:/tmp/does-not-exist.sock` 返回 500（无协议 handler），子进程未崩溃；
   已复现并判定 SSRF 两个变体。若赛题 V2/V3 需要崩溃差分，需进一步构造（例如与 `ProxyPass` 的 UDS worker 组合）。
2. **CVE-2021-44790 的 ASAN 完整堆栈未落盘**：WSL1 下巨大 memcpy 触发 ASAN 二次异常（`nested bug in the same thread`），
   `log_path` 仅 66 字节分隔线；已用 error_log 的 SIGSEGV/SIGABRT + `LD_PRELOAD` memcpy 观察器
   （`n=18446744073709551615`，`mod_lua.so+0x13625`）确认根因。完整 Linux VM 上重跑可获符号化报告。
3. 普通构建（非 ASAN）上 `pad=3` 未崩溃而是 Lua 报 `memory allocation error: block too big`，`pad=0` 稳定 abort；
   ASAN 构建 `pad=3` 稳定 SIGSEGV。PoC 已同时支持两个 pad，verify 两个都打。
4. 本实验 httpd 以 root 运行（未写 `User`），仅用于靶场让 `id` 输出 root；生产部署应使用低权限用户。
5. 端口 8082 与其他子智能体隔离（A:8081/8053，B:5353）；脚本结束会清理自己的进程（`/opt/httpd*/bin/httpd`、`httpd252-root`）。
6. 修复版对照使用 Ubuntu 发行版构建（`2.4.52-1ubuntu4.25`，含 Debian/Ubuntu 补丁），不是自编译 pristine 2.4.52；
   结论（三个 CVE 均不再命中）与上游修复 commit 一致。若要求 pristine 上游 2.4.52，可另下源码编译后重跑同一负向脚本。

## 8. 响应侧补充：CVE-2022-37436 / CVE-2023-27522（子智能体 B，端口 8092–8094）

两个“响应侧”漏洞复用 2.4.49 普通构建 `/opt/httpd`，独立端口：

* httpd 主实例 **8092**；恶意 HTTP 后端 **8093**；uwsgi 协议假后端 **8094**；
* 配置不写入 `/opt/httpd/conf/`，直接用 `httpd -f conf/httpd-37436.conf`
  （或 `conf/httpd-27522.conf`）启动；
* 脚本只按自己记录的 PID 清理，不做全局 `pkill httpd`。

| CVE | 类型 | 判定 | 状态 | 证据 | 复跑 |
|---|---|---|---|---|---|
| **CVE-2022-37436** | mod_proxy_http 响应头截断 → 响应走私 | 后端头值含 NUL → 客户端 200，`Set-Cookie`/`X-Frame-Options` 出现在 body；9000 字节头被截为 8183 后仍 200（`AH10124`）；修复版 `/nul` 502 + `AH10404` | **成功** | `evidence/CVE-2022-37436/` | `bash poc/CVE-2022-37436/verify.sh` |
| **CVE-2023-27522** | mod_proxy_uwsgi 响应走私 | uwsgi 后端头值含 NUL → 200，安全头进 body；头行 >8192 被截断后仍 200；修复版 `/nul`、`/oversize`、`/cr`、`/badname` 全 502 | **成功** | `evidence/CVE-2023-27522/` | `bash poc/CVE-2023-27522/verify.sh` |

修复版负向对照（两个 CVE 一次跑完）：

```bash
bash poc/fixed_2.4.52/verify_negative_response.sh
# 实测 RESULT: NEGATIVE CONTROL PASS
```

要点（详见 `report/CVE-2022-37436.md`、`report/CVE-2023-27522.md`）：

1. 两者根因都是“后端响应头解析错误被忽略，后续头被当作 body”。2.4.49 中
   `ap_proxygetline()` 把 `APR_EINVAL` 映射为 `len=-1`，`ap_proxy_read_headers()`
   仅凭 `len<=0` 静默 break；uwsgi 侧 `ap_getline()` 返回 -1 后 `while (...>0)`
   正常退出。后续 `Set-Cookie`/`X-Frame-Options` 因此进入 body。
2. 任务最初设想的“纯 >8KB 头 + Set-Cookie 进 body”在 2.4.49 默认
   `ProxyBadHeader IsError` 下没有出现：超长头分支只表现为“截断后仍 200 转发”
   （`AH10124`），后续头仍是正常头。实际“后续头进 body”用 NUL 头复现；两者
   由同一个修复 hunk（检查返回值/长度）覆盖，报告已如实写明差异。
3. 2.4.49 核心输出过滤器会以 500（`AH02429`/`AH02430`）拦下非法头名/头值，
   所以 27522 的裸 CR、非法 token 只作为修复 hunk 的旁证，走私判定用 NUL 与
   超长头两条路径。

## 9. 子智能体 C 第二批：CVE-2024-38474 / CVE-2022-22719 / CVE-2022-23943（端口 8095，辅助 8096）

同一 2.4.49 构建（`/opt/httpd`，内存型未用新构建）；配置在 `conf/<CVE>.conf`，
不改 `/opt/httpd/conf/`；脚本只按自己记录的 PID 清理。

| CVE | 类型 | 判定 | 状态 | 复跑 |
|---|---|---|---|---|
| **CVE-2024-38474** | mod_rewrite `%3f` 解码进替换串 → 路径截断（任意读/源码泄露/handler 误导执行） | 与对照请求相比返回不同文件；`secret.txt%3F` 读到 secret（对照 404）；`.sh` 源码泄露；`.gif` 被 `[H=cgi-script]` 执行；`%253F` 阴性 404；修复版（Ubuntu backport）全 403 + `Unsafe URL with %3f` 日志 | **成功（PASS）** | `bash poc/CVE-2024-38474/verify.sh`（exit 0） |
| **CVE-2022-22719** | mod_lua `r:parsebody()` multipart 分支读未初始化 `data`/`size` | Valgrind：阳性阶段 2 个 `strstr ← req_parsebody (lua_request.c:401)`，来源 `stack allocation at req_parsebody:373`；阴性与带 body 对照 0；修复版反汇编见 `*rbuf=NULL/*size=0`，同请求 0 告警 | **成功（PASS）** | `bash poc/CVE-2022-22719/verify.sh`（exit 0） |
| **CVE-2022-23943** | mod_sed 行长 `int` 截断 → 负尺寸 `memcpy`（堆越界写） | 静态定位（libsed `wline(int)` → `sed_write_output(int sz)` → `memcpy(...,sz)`）；64/256 MiB 单行实测峰值 RSS ≈ **4.87×** 行长；>2 GiB 行需 ~9–10 GiB，本机 `MemFree` 1.6–3.7 GiB → **动态不可行，如实标注**；`verify.sh` 退出码 3 | **未复现（静态+资源评估）** | `bash poc/CVE-2022-23943/verify.sh`（exit 3） |

补充：

* 修复版负向对照（38474/22719）：`bash poc/fixed_2.4.52/verify_negative_38474_22719.sh`
  → `RESULT: NEGATIVE CONTROL PASS`（Ubuntu `2.4.52-1ubuntu4.25` 已 backport 两个修复：
  `mod_rewrite.so` 含 `UnsafeAllow3F` 字符串；`mod_lua.so` 的 `lua_read_body` 反汇编有
  `*rbuf=NULL; *size=0`）。
* 22719 的关键前提：**Content-Type 必须是 `multipart/form-data; boundary=...`** 且无 body；
  此前“GET 无 body 试不出”是因为走了 `ap_parse_form_data()` 安全分支（报告 §8 已更正）。
* 23943 在大内存主机上可强制实测：`CVE_23943_FORCE_FULL=1 bash poc/CVE-2022-23943/verify.sh`
  （要求 >12 GiB free）。
* 详细根因/证据/局限见 `report/CVE-2024-38474.md`、`report/CVE-2022-22719.md`、
  `report/CVE-2022-23943.md`。
