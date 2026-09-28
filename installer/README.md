# Machine Party — Overtime 1.7

Free, unofficial community mod for **Machine Party v2.1.2 (Steam)**.
Online lobbies require the same complete version: `v2.1.2+overtime-1.7`.
联机双方应显示 `v2.1.2+overtime-1.7`；不能与 1.6、1.7-dev 或其他 fork 混连。

## Install / 安装

1. Exit the game completely. / 完全退出游戏。
2. Extract **the entire downloaded ZIP** to a folder. Keep `overtime_launcher.exe` and
   `overtime_payload.zip` together. Do not run the exe inside the archive.
   / 将下载的 ZIP **完整解压**到文件夹，让程序和补丁包放在一起。不要直接在压缩包里运行。
3. Run `overtime_launcher.exe`, select Chinese or English, check the game directory, then
   choose **Enable Overtime**. / 运行启动器，选择语言，核对游戏目录后点击「启用 Overtime」。
4. Start the game normally from Steam. Everyone joining an online lobby needs the **same
   complete Mod version**. / 照常从 Steam 启动游戏；联机双方必须使用完全相同的 Mod 版本。

The launcher remains usable for detection and uninstall when the payload is missing.
To enable or upgrade, re-extract the complete archive; a missing or damaged package is
rejected before modifying an existing installation.
缺少补丁包时仍能检查状态和卸载；启用或升级请重新完整解压。损坏或缺失的包会在改动现有安装前被拒绝。

## Windows security / Windows 安全提示

The program and payload are separate, inspectable files. Mod-only updates can reuse an
unchanged launcher executable. The launcher requests normal user privileges and does not
download executable code, install a background service, add startup tasks or change
Defender settings. Enabling the mod still modifies your selected game's PCK data file.
程序与补丁数据分开，只有 Mod 变化时可复用同一个启动器。启动器使用普通用户权限，不下载并运行程序，
不安装后台服务、不添加开机启动、不修改 Defender 设置。启用 Mod 仍然需要修改所选游戏的 PCK 数据包。

These executables are **unsigned**. Packaging changes do not guarantee that
Defender or SmartScreen will accept a download. If Windows reports a named threat, record
the threat name, filename and SHA-256 for the project issue; do not disable protection or
add exclusions. SmartScreen reputation warnings and antivirus detections are different
checks. A release should be tested with current, enabled Defender, and false detections
submitted to Microsoft.
本程序**尚未代码签名**，不能保证 Defender 或 SmartScreen 不再拦截。若出现具体病毒名称，
请记录名称、被拦文件及 SHA-256 并反馈。不要关闭防护或添加排除项。SmartScreen 信誉提示与杀毒检测
是不同机制；正式发布前仍需在更新并开启 Defender 的环境中测试，并向微软提交误报复核。

`SHA256SUMS.txt` and `BUILDINFO.json` describe the build contents. Hashes detect a mismatch;
they are not a publisher signature or an antivirus certificate.
这两个文件用于核对构建内容；哈希不是发布者签名，也不是安全认证。

## Restore / 还原

Choose **Switch to vanilla** to restore and verify the original PCK. Keep
`overtime_restore.dat` beside the installed PCK. It records the original index and length
needed to undo the patch. Do not delete it while the mod is installed.
点击「切回原版」后，程序会还原并校验原始 PCK。启用期间请保留游戏目录的 `overtime_restore.dat`。

An interrupted write can be recovered using this record. On a failed upgrade, recovery
returns to the validated original game data; it does not promise to reinstall the old mod.
If recovery cannot be verified, the launcher reports the failure and retains evidence.
写入中断可用还原记录恢复。升级失败时回滚目标是校验过的原始游戏数据，不保证重新装回旧版 Mod。
无法验证恢复结果时会明确报错并保留故障记录。

Steam updates or “Verify integrity” can replace the PCK. Unknown game builds are rejected.
Use **Browse** to choose the directory containing `Machine Party.pck`; do not run as
administrator to work around a package or version error.
Steam 更新或验证文件可能替换 PCK。不匹配的游戏版本会被拒绝。找不到游戏时用「浏览」选择 PCK
所在文件夹；不要为了绕过补丁包或版本错误而以管理员身份运行。

## Options / 可选方式

- **Play** asks Steam to start the game; the launcher can then close.
  /「启动游戏」交给 Steam 启动，启动器无需常驻。
- **Install log / Game log** open local logs; nothing is uploaded automatically.
  / 安装日志、游戏日志只在本机打开，不会自动上传。
- The separate CLI archive supports `overtime_install.exe --verify-package` and
  `--uninstall`; see `--help` for path selection. Do not use its advanced force mode for
  normal installations. / 命令行包可验证补丁或卸载，正常安装不要使用强制模式。
- The separate **MPML** overlay package is an alternative installation route. Restore
  vanilla before switching routes, and do not install both over the same PCK.
  / MPML 覆盖包是另一种安装方式，切换前先还原，不能与 PCK 安装器叠加使用。

The source release contains diffs against scripts extracted from your own legitimate copy,
plus the independent installer and build tools. No original art or sound assets are included.
参考 NotAsher999 与 JaredMerritt 的 fork 中的功能方向、问题定位和修复思路，在本项目主线中重写实现；
已阅读对方实现，不宣称严格净室开发。具体来源见仓库 docs/CREDITS.md。公开源码通过差异补丁发布，需自行从正版提取
原始脚本；包内不附带原版美术与音频资源。

Not affiliated with or endorsed by Machine Party's developer or publisher.
非官方第三方修改，未获游戏开发商或发行商背书。禁止将免费 Mod 冒充收费产品。
