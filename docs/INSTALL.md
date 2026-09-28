# 安装、升级与还原 / Installation

[返回首页](../README.md) · [English quick start](#english-quick-start)

适用 **Machine Party v2.1.2（Steam 正版）**。本说明对应 Overtime 1.7。

## 普通玩家安装

1. 在 [v1.7 Release](https://github.com/DarkJadeStone/MachineParty-Overtime/releases/tag/v1.7) 下载 `Machine-Party-Overtime-1.7.zip`。
2. **完整解压**到普通文件夹；不要在压缩包内直接打开程序。
3. 完全退出游戏，运行 `overtime_launcher.exe`，检查选中的游戏目录并点击「启用 Overtime」。
4. 等待检查和写入完成，再从 Steam 启动游戏。主菜单应显示 `v2.1.2+overtime-1.7`。

解压后这些文件应在一起：

```text
overtime_launcher.exe
overtime_payload.zip
README.md
BUILDINFO.json
SHA256SUMS.txt
```

**不要只复制或转发 exe。** `overtime_payload.zip` 是启动器使用的补丁包，保持 ZIP 原样放在程序旁边即可。
运行期间不会下载补丁；程序找不到它时无法启用或升级。启动器不需要一直开着。

联机时所有人都需要相同完整版本；1.7 不与原版、1.6、1.7-dev 或其他 fork 混连。
本地同屏中的所有输入设备则使用同一台机器上的安装。

## 从旧版升级

完全退出游戏，下载并完整解压 1.7，然后使用新目录中的启动器。
旧版已安装时不必先卸载：程序会先验证新补丁包，再根据还原记录恢复安装前数据，随后安装新版。

请保留游戏目录中的 `overtime_restore.dat`（早期版本可能叫 `mp8_restore.dat`）。
缺少或损坏的新补丁包会在还原旧安装前被拒绝。
如果旧安装已经还原但新版本未能安装，启动器会明确报告状态；不要把这种结果误认为旧 Mod 仍然在运行。

## 切回原版

完全退出游戏，在启动器中选择「切回原版」，等待还原与校验完成。
还原只依赖游戏目录中的记录，不要求外置补丁包仍在；但不要在 Mod 启用期间删除还原记录。

Steam 更新游戏或验证文件可能覆盖 Mod。遇到不匹配的数据包时，先查看启动器提示；
不要通过强制模式或管理员权限绕过版本错误。损坏的游戏文件可通过 Steam 验证恢复。

## 本地设备与分屏

1.7 支持八席本地大厅，键鼠可加入任意席位。
游戏中断开控制器会保留身份；原编号设备接回后按确认键，再松开，才恢复操作。
如果系统分配了不同设备编号，请回大厅重新加入。

5–8 个实际输入设备的完整对局仍需实机验收；遇到问题请记录席位、设备类型及发生阶段。

## MPML 备选安装

这是替代路线，**不能与启动器修改 PCK 叠装**。

1. 先用启动器切回原版，确认 PCK 为支持的原版数据。
2. 从 [MachinePartyModLoader 仓库](https://github.com/Krunk-theduck/MachinePartyModLoader) 自行取得并安装兼容加载器。本项目适配层要求 API 2，不捆绑加载器。
3. 下载 `Machine-Party-Overtime-1.7-MPML.zip`，把里面的 `overtime` 文件夹放入游戏的 `mods` 目录。
4. 包内应有 `main.gd`、`mod.json`、`vanilla_md5.json`、`overtime_overlay.zip` 和 `BUILDINFO.json`，保持同一套版本。

移除该路线的 Mod 时按加载器说明禁用/移除 `mods/overtime`。
其他 Mod 若修改同一脚本仍可能冲突；不能把“可以由加载器加载”理解成与任何 Mod 都兼容。
两条路线使用同一套补丁与版本标签，但完整混合路线联网流程仍需实机确认。

## 命令行

下载完整 `Machine-Party-Overtime-1.7-CLI.zip`，解压后可用：

```powershell
.\overtime_install.exe --verify-package
.\overtime_install.exe --game "D:\Steam\steamapps\common\party project\Machine Party_Windows" --status --no-pause
.\overtime_install.exe --game "D:\Steam\steamapps\common\party project\Machine Party_Windows" --uninstall --no-pause
```

将示例路径换成自己的游戏目录。普通安装不要使用 `--force`。

## 常见问题

- **找不到游戏：** 用「浏览」选择包含 `Machine Party.pck` 的文件夹；存在多个安装副本时核对完整路径。
- **缺少补丁包：** 重新下载完整 ZIP 并解压；保持程序与 `overtime_payload.zip` 同目录。
- **提示游戏正在运行：** 完全退出游戏；若仍被拒绝，查看「安装日志」记录的进程/路径。
- **进不去朋友房间：** 对照双方主菜单完整版本，确保游戏本体和 Mod 都一致。
- **Windows 拦截：** 阅读 [安全与告警说明](SAFETY.md)，保持防护开启并反馈检测名称。
- **游戏内异常：** 通过「游戏日志」按钮查找日志；没有日志时仍可反馈人数、模式、关卡和现象。

## English quick start

For a legitimate Steam copy of **Machine Party v2.1.2**:

1. Download `Machine-Party-Overtime-1.7.zip` and extract the **entire** archive.
2. Keep `overtime_payload.zip` beside `overtime_launcher.exe`. Do not run the exe from inside the archive.
3. Quit the game, run the launcher, check the game folder and enable or upgrade Overtime. Existing users do not need to uninstall first.
4. Start through Steam. Every online player must show **`v2.1.2+overtime-1.7`**. Do not mix with 1.6, 1.7-dev, vanilla or forks.

To restore vanilla, quit the game and choose **Switch to vanilla**. Keep the game's `overtime_restore.dat` while the Mod is enabled; restoration can work without the external payload. An upgrade failure may leave the restored original input rather than the old Mod; the launcher explains that outcome.

The `-CLI.zip` provides the complete command-line package. The `-MPML.zip` requires a separately installed compatible API 2 loader and an original PCK. Extract its `overtime` folder into `mods`; never stack it with direct PCK patching. Mods replacing the same scripts may conflict.

Reconnect a controller with the same device ID, confirm, then release the button to resume. A changed ID requires rejoining in the lobby. Full sessions with physical controllers still need in-game acceptance.

See [security notes](SAFETY.md#english) for download blocks, and include the version, player count, mode and failure phase in [reports](https://github.com/DarkJadeStone/MachineParty-Overtime/issues). Logs are helpful but not mandatory.
