## 1.7 —— 本地 5–8 人同屏、渐变外观与安装器重构

下载地址：https://github.com/DarkJadeStone/MachineParty-Overtime/releases/tag/v1.7

**普通玩家下载 `Machine-Party-Overtime-1.7.zip`。** 完全退出游戏，把新版 ZIP **完整解压**，运行里面的 `overtime_launcher.exe`，核对游戏目录后启用或升级。已经安装旧版的玩家无需先卸载。

**这次必须保留同目录的 `overtime_payload.zip`。不要只复制 exe，不要在压缩包内直接运行。** 启动器无需常驻，安装后照常从 Steam 启动游戏。

本次主要补齐本地同屏、回合流程和安装体验，并增加外观选择；保留主线已有的八人玩法与计分适配。

- **本地 5–8 人同屏**：大厅扩为八席，席位、角色与设备配对；键鼠可处于任意席位，离开和重入不会重新排列其他玩家。人工筛选、凿刻考验和内部暗手补齐分屏布局；猎鸭支持双猎人分别拥有自己的视角。手柄断开保留原席位，同编号设备接回后需确认并松开按键，避免确认操作同时触发游戏动作。
- **「重开本轮」投票**：投票绑定当前关卡与回合。修复旧回合状态残留，以及正常结算和重开同时到达时重复推进的问题；重复赞成/撤回不再反向切票。仍需房间过半同意和五秒确认，名单变化时重新计算。版本与投票提示支持英文、简体和繁体中文。
- **三套渐变服装**：新增「落日」「极光」「暮色」，与原有五种纯色并存。主菜单及本地大厅可选择，正常身体和分离的躯干、腿部沿用相同外观。
- **同屏细节修复**：恢复内部暗手各席位的环境照明和投影显示；恢复猎鸭中鸭群可见、猎人不可见的激光规则；修复凿刻缩放窗口后的鼠标落点、结算光标显隐及墙壁血迹贴花影响角色的问题。
- **安装器和启动器重构**：针对下载拦截反馈，将程序与补丁分开为普通 exe＋标准 ZIP，使用普通用户权限并保留离线安装/还原。坏包或缺包会在升级改动前被拒绝，文件检查在后台进行。升级已还原旧安装却未能装上新版时，会如实说明当前状态。
- **MPML 备选包**：补充覆盖包完整性和版本检查。它与启动器安装是两条替代路线；使用 MPML 前先恢复原版 PCK，不能叠装。不保证与修改同一脚本的其他 Mod 兼容。

### 附件怎么选

| 附件 | 用途 |
| --- | --- |
| `Machine-Party-Overtime-1.7.zip` | 普通玩家；内含窗口启动器、补丁 ZIP、说明和校验信息 |
| `Machine-Party-Overtime-1.7-CLI.zip` | 需要命令行的用户；也是完整包 |
| `Machine-Party-Overtime-1.7-MPML.zip` | 已自行安装兼容 MPML 的用户；不要与 PCK 修改叠装 |
| `SHA256SUMS.txt` | 三个发行 ZIP 和清单的 SHA-256 |
| `RELEASE_MANIFEST.json` | 版本、构建来源及附件校验记录 |

不要把 GitHub 自动生成的 **Source code** 当作安装包。需要恢复原版时，在启动器中选择「切回原版」；保持游戏目录中的 `overtime_restore.dat`，不要在 Mod 启用期间删除它。

### 已验证与仍需反馈的部分

70 份脚本已编译；分屏隔离检查、两种渲染器的小场景检查、投票/计分回归以及安装还原检查已完成。安装器与 MPML 的脚本资源逐项一致，原版 PCK 临时副本卸载后的 SHA-256 与原版一致。

这些检查不代替 5–8 个真实输入设备和 Steam 多人的完整对局。此前反馈的“1.6、五人、残骸平台结束黑屏”缺少现场日志，原始根因仍未确认，不能据此宣称已根治。再遇到请反馈版本、人数、联机/同屏模式和发生阶段；有日志时可通过启动器的「游戏日志」按钮找到它。

**Windows 告警：本次程序未签名，尚无有效 Defender 检测通过结论。** 重构不保证 Windows 不再拦截。出现具体病毒名称时，请记录文件名、检测名称和 SHA-256；保持防护开启，不要添加排除项。

⚠️ **1.7 与 1.6、1.7-dev 及其他 fork 不能混连。** 同一房间所有玩家都要更新；主菜单应显示 `v2.1.2+overtime-1.7`。如果压缩包由朋友转发，也请转发完整新版 ZIP。

Mod 免费，需要正版 Machine Party v2.1.2。非官方社区修改，不代表原作开发商或发行商。

---

## English — Local 5–8 players, mixed suits and a rebuilt installer

Most players need **`Machine-Party-Overtime-1.7.zip`**. Quit the game, extract the **entire** archive, run `overtime_launcher.exe`, check the game folder and enable or upgrade Overtime. Existing users do not need to uninstall first. **Keep `overtime_payload.zip` beside the executable.** Start the game normally through Steam afterward.

- Local play now has eight paired seats, arbitrary keyboard seating and expanded split-screen layouts. Duck Hunt gives each local hunter a separate view. Reconnected controllers require a complete confirmation press/release before gameplay resumes.
- Restart voting is tied to the active round. Stale votes and competing finish/restart paths cannot advance that round twice. Agreement and withdrawal are explicit states. The majority threshold and five-second confirmation remain; messages support English, Simplified Chinese and Traditional Chinese.
- Three mixed suits—Sunset, Aurora and Twilight—join the original five colors, including matching separated body parts.
- Local rendering fixes restore Knife at the Office lighting/projectors, Duck Hunt laser visibility, and Chisel Gauntlet cursor/decal behavior.
- The offline installer uses a separate standard patch ZIP, normal user privileges, background file checks and validated restore records. Missing or corrupt payloads are rejected before reverting an existing installation. Upgrade failures describe what was actually restored.
- The optional MPML package checks its overlay and metadata before mounting. Restore vanilla before switching installation routes. Mods that replace the same scripts may conflict.

The `-CLI.zip` is the complete command-line package. The `-MPML.zip` requires a separately installed compatible loader. `SHA256SUMS.txt` and `RELEASE_MANIFEST.json` identify the release assets; GitHub's automatic **Source code** archives are not installers.

Compilation, isolated regressions, small-scene GPU checks and real-PCK copy install/restore checks are complete. Full sessions with physical controllers and Steam peers still need in-game acceptance. The reported five-player end-of-round black screen in 1.6 has no confirmed root cause.

**The executables are unsigned; packaging changes do not establish that Defender detections are resolved.** Keep protection enabled and report named detections with the filename and hash.

Everyone in a lobby must use **`v2.1.2+overtime-1.7`**. Do not mix 1.7 with 1.6, 1.7-dev or forks. This is a free, unofficial community mod and requires a legitimate copy of the game.
