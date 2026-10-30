# Qw9-Apache

第九届强网拟态 Apache 主线阶段成果快照（2026-10-30）。V1 基准程序为 **Apache httpd 2.4.49**。

> 原工作区记录：11 个 CVE 中 **10 个已复现**；CVE-2022-23943 已完成静态定位，动态验证因内存限制未完成。本次操作仅整理和发布已有成果，没有重新运行 PoC 或重新验证这些结论。

## 从这里开始

- [Apache CVE 总览](Apache项目/CVE总览-Apache.md)：CVE 清单、状态及证据入口，当前进展以此文档为准。
- [漏洞挖掘报告](Apache项目/漏洞挖掘/漏洞挖掘报告.md)：补丁差分、根因定位及 fuzz 证据。
- [Apache 复现工程](cve/apache/README.md)：构建脚本、配置、PoC、逐漏洞报告及原始证据。
- [方案初稿](00_赛题与方案/第一阶段_创新设计理念方案_初稿.md)：阶段设计材料。
- [基准程序终选结论](cve/_audit/三模型终选结论.md)：Apache 选型依据及尚待补齐的 V2/V3 实证。

## 仓库范围

```text
Apache项目/          Apache 总览、11 CVE 原始资料、补丁差分与挖掘成果
cve/apache/          自写构建脚本、实验配置、PoC、复现报告与证据
cve/_shared/         原工作区的共享脚本和环境说明
cve/_audit/          基准程序终选结论
00_赛题与方案/       赛题、方案及说明材料
01_选型/             选型报告与总结
docs/原工作区说明.md  原工作区目录地图快照
```

此次仅发布 Apache 主线。nginx、dnsmasq 工程、OpenSSL 历史归档、下载缓存、编译产物、Python 缓存、PID/socket 等运行时文件和密钥均不纳入本仓库。原工作区地图和部分早期文档可能引用未发布的历史材料；这不代表对应文件已包含在本次快照中。部分早期 README 的状态保留原貌，请优先参考 Apache CVE 总览及逐 CVE 报告。

## 复现环境注意事项

原工程针对 **Windows + WSL1 / Ubuntu-CTF**，脚本中包含 `E:\强网拟态`、`/mnt/e/强网拟态` 和 `/root/work` 等固定路径，**不是克隆后即可直接运行的便携工程**。第三方 Apache 源码包、系统依赖及已编译环境没有一并上传；换机器时需要检查下载来源、安装依赖并适配路径。

原有主要验证入口：

```powershell
wsl.exe -d Ubuntu-CTF -- bash /mnt/e/强网拟态/cve/apache/build/run_all_verify.sh
```

新增 CVE 的验证脚本位于 `cve/apache/poc/<CVE>/verify.sh`；修复版负向对照位于 `cve/apache/poc/fixed_2.4.52/`。

## 使用边界

本仓库含已公开漏洞的实验 PoC 与测试证据，仅限自行搭建或获得明确授权的隔离实验环境使用。不要向未授权系统发送测试请求。第三方赛题、公告和漏洞资料的权利归原作者；本次发布不新增许可授权。
