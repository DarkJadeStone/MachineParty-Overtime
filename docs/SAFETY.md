# 下载、文件校验与 Windows 告警

[返回首页](../README.md) · [English](#english)

## 从哪里下载

从本仓库的 [Releases](https://github.com/DarkJadeStone/MachineParty-Overtime/releases) 下载完整安装包。
普通玩家选择 `Machine-Party-Overtime-1.7.zip`；CLI 与 MPML 是不同用途的完整包。

1.7 程序与补丁数据分离。只有 Mod 改动时，可以复用同一份程序文件；
安装前验证补丁包与目标资源，操作以普通用户权限离线进行。
启动器会查找 Steam 安装目录、读取并修改选中的游戏 PCK、写入还原记录和本机安装日志。
它没有下载并运行代码、安装服务、添加开机任务或修改 Defender 设置的功能。

## 当前的验证状态

**1.7 安装程序未签名，尚无有效 Defender 检测通过结论。**
历史版本收到过具名病毒检测，见 [issue #2](https://github.com/DarkJadeStone/MachineParty-Overtime/issues/2)。
无法仅从检测名称得知微软的具体触发规则；重构和减少程序变化也不等于已经消除误报。

页面设计、源码公开、哈希校验和代码签名各有用途，不能互相替代。
这里不会把构建成功显示为“安全认证”，也不提供关闭防护或添加排除项的步骤。

## 两种提示要分别处理

| 看到的提示 | 请记录什么 |
| --- | --- |
| Defender/浏览器报告具体威胁名称 | 检测名称、被拦文件名、下载的版本、检测时的安全情报版本；能取得文件时附 SHA-256 |
| SmartScreen 提示未知发布者或应用信誉不足 | 提示原文、文件名、下载来源与版本 |

保持防护开启。不要反复运行被拦的文件，也不要用管理员权限绕过缺包、版本或安全提示。
通过 [Issues](https://github.com/DarkJadeStone/MachineParty-Overtime/issues) 提交上述信息，项目方可按微软的
[软件开发者提交指南](https://learn.microsoft.com/en-us/defender-xdr/submission-guide) 申请复核。

## 核对文件是否一致

发行页的 `SHA256SUMS.txt` 对应三个完整 ZIP 和发布清单。
下载后运行：

```powershell
Get-FileHash .\Machine-Party-Overtime-1.7.zip -Algorithm SHA256
```

逐字符核对同名文件那一行。包内的同名校验文件对应解压后的程序和补丁，不要混淆两个层级。
`BUILDINFO.json` 记录构建内容；外层 `RELEASE_MANIFEST.json` 记录发行附件。

**哈希相同只证明文件内容相同，不证明文件安全，也不是发布者签名。**

## English

Download complete archives from this repository's [Releases](https://github.com/DarkJadeStone/MachineParty-Overtime/releases). Most players need `Machine-Party-Overtime-1.7.zip`.

The 1.7 installer uses normal user privileges, operates offline and validates a separate standard ZIP payload. It reads Steam installation information and the selected game PCK, modifies that PCK, and writes local restore data/logs. It does not download executable code, install services, add startup tasks or change Defender settings.

**The executables are unsigned, and there is no valid Defender-pass result for this build.** Packaging changes and source availability do not prove a detection was resolved. SmartScreen reputation prompts and named antivirus detections are different checks.

Keep protection enabled. Report the exact message or threat name, filename, Mod version and security intelligence version; include a SHA-256 when the file is available. Do not disable protection or add exclusions.

Compare each archive with the release-level `SHA256SUMS.txt`. The checksum file inside an archive refers to its extracted contents instead. A matching hash establishes content identity, not safety or publisher identity.
