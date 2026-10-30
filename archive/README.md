# 历史归档：完整保留，退出主线

[返回首页](../README.md)

主线只保留当前方案、唯一状态表、正式工程和精简摘要。没有丢弃原始成果：上次已发布的 **632 个文件**按原目录完整封存，Git 历史也仍可在线查看。

## 1. 完整快照

| 项目 | 值 |
|---|---|
| 来源提交 | [0fedb2552d888398e2152193e681bfe5b8f170b2](https://github.com/zhangbeacon/Qw9-Apache/tree/0fedb2552d888398e2152193e681bfe5b8f170b2) |
| 文件包 | [完整发布快照](published-snapshot-20261030.zip) |
| 文件数 | 632 个普通文件，不包含 Git 元数据、凭据或未跟踪文件 |
| 大小 | 1,091,734 字节，约 1.04 MiB |
| 校验 | [SHA256SUMS](SHA256SUMS) |

```text
SHA256 067d3460c843f4db0319ee98e10b1d18146eb2e0d0940b2161260260cd85e4c4
```

归档在移除散件前完成，并逐一核对归档 CRC、来源提交、632 项源文件及保留/迁移内容。归档记录的是上次发布版本；原实验工作区中未发布的缓存、运行时文件、其它软件工程不在这个包内。

## 2. 原材料去哪了

以下路径是**包内原路径**，不是本轮主目录布局：

| 材料 | 包内位置 | 为什么退出主线 |
|---|---|---|
| 全部原始证据 | cve/apache/evidence/ | 日志和报文不应淹没项目入口；现役只留各项 verdict 摘要 |
| 构建日志与一次性诊断 | cve/apache/build/ | inspect / diag / exp / test / show 等为过程材料，不是正式接口 |
| 完整 fuzz 候选与回放 | Apache项目/漏洞挖掘/fuzz/ | 保留失败样本及误报，不能只留成功结果 |
| NVD JSON、上游公告与索引 | Apache项目/CVE原文-Apache/ | 作为可追溯研究来源，不与项目方案平铺 |
| 旧挖掘报告、差分与索引 | Apache项目/漏洞挖掘/ | 旧表包含早期状态，当前结论以新矩阵为准 |
| 完整旧设计稿及 Word/PDF | 00_赛题与方案/ | 是历史版本，不与当前协作源平行维护 |
| 已完结选型与评审 | 01_选型/、cve/_audit/ | 保留决策依据，不继续指导当前任务 |
| 共享下载、资料生成和 fuzz 工具 | cve/_shared/ | 不被现役规范入口直接调用，按需独立查阅 |
| 原目录地图 | docs/原工作区说明.md | 描述原实验机布局，不能当现役仓库地图 |

想在线阅读而不下载，可打开[完整旧目录](https://github.com/zhangbeacon/Qw9-Apache/tree/0fedb2552d888398e2152193e681bfe5b8f170b2)，或者直接查看[原始证据](https://github.com/zhangbeacon/Qw9-Apache/tree/0fedb2552d888398e2152193e681bfe5b8f170b2/cve/apache/evidence)。这些是固定历史记录，不代表本轮重新验证。

## 3. 校验与独立解包

在仓库根目录执行。先核对 SHA256，并确认目标目录不存在；**不要覆盖当前仓库或原实验工作区**。

```powershell
$archive = '.\archive\published-snapshot-20261030.zip'
$expected = '067d3460c843f4db0319ee98e10b1d18146eb2e0d0940b2161260260cd85e4c4'
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
    throw '归档校验失败，停止解包'
}
$destination = '..\Qw9-Apache-snapshot-review'
if (Test-Path -LiteralPath $destination) {
    throw '目标目录已存在，请改用新的空目录'
}
Expand-Archive -LiteralPath $archive -DestinationPath $destination
```

解包恢复的是旧发布目录，不会使绝对路径脚本自动便携化。旧方案、旧“运行中”描述及旧进度应按历史语境阅读；当前进度只看[唯一漏洞矩阵](../docs/02-漏洞矩阵.md)。

## 4. 今后怎么归档

- 每份快照写清来源提交、本轮范围、原路径、日期和 SHA256。
- 原始成功、失败和资源受限证据一并保存，不筛掉不利数据。
- 当前正文与精简索引留在主线，重复文件、过程输出和历史版本退出主线。
- 不把未审查的密钥、登录信息或私密原始数据打进归档。
