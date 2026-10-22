# 更新日志 / Changelog

[返回首页](../README.md) · [English](../README.en.md)

历史公告保留当时的版本、范围与验证状态，不代表 1.7 的安装方式或验证结论。各版下载文件以对应 Release 为准。

## 未发布 — 本地大厅 8 人座位

- 本地大厅改用联机大厅的排法：原版 4 个座位不动，第 5–8 位复制第 1–4 位整排前移 (0.2, 0, 5.8)，椅子同样复制一排，摄像机拉远。
  原来 8 个模型被重新等距排开，但坐姿烘在各自的骨架里，结果人离开椅子，P1 进了左墙，P7、P8 在房间外。
- 名牌改成三行（P 号与名字 / 设备 / 准备状态）；原来第二行的 `KEYBOARD  NOT READY` 会压进右边那张卡。
- 房主卡的皇冠不再把整张卡往下顶，8 张卡的名字齐平。
- 联机握手串仍是 `overtime-1.7`，与 1.7 玩家互通。

> **English — unreleased: 8 seats in the local lobby.**
>
> - The local lobby now uses the online lobby's method. The 4 original seats stay as authored. Seats 5–8 are copies of
>   seats 1–4 in a second row at (0.2, 0, 5.8), with a matching row of chairs, and the camera pulls back. Before, all 8
>   models were re-spaced in a line, but each seat's pose is baked into its skeleton, so players sat off their chairs,
>   P1 sat inside the left wall, and P7 and P8 sat outside the room.
> - Panel labels use three lines (seat and name / device / ready state). On two lines, `KEYBOARD  NOT READY` ran into
>   the next panel's text.
> - The host's crown no longer pushes that panel down, so all 8 names sit at one height.
> - The handshake tag is still `overtime-1.7`, so it plays online with 1.7 players.

---

## 1.7 — 本地同屏、渐变外观与安装器重构

- 新增本地 5–8 人席位与分屏，保留设备身份，完善猎鸭双猎人视角。
- 改进当前回合重开、撤票和重复结束处理，补充 EN/ZHS/ZHT 提示。
- 新增落日、极光、暮色，修正同屏灯光、激光、鼠标与贴花问题。
- 安装器改用外置 ZIP、后台检查及可核验恢复记录；不代表已消除 Windows 告警。
- 全房间应使用 `v2.1.2+overtime-1.7`；完整实机验收范围见验证记录。

[1.7 完整中英文公告](RELEASE_1.7.md) · [验证范围](VERIFICATION_1.7.md)

---

## 历史更新日志


### 1.6 —— 新增「重开本轮」投票，修复猎鸭卡死与餐桌礼仪延迟

下载地址：
https://github.com/DarkJadeStone/MachineParty-Overtime/releases/tag/v1.6
普通玩家下载「Machine-Party-Overtime-1.6.zip」即可。已经安装旧版的玩家不需要先卸载：完全退出游戏，解压新版压缩包，运行里面的「overtime_launcher.exe」，点击“启用 Overtime”即可完成更新。
本次玩法调整只涉及猎鸭与餐桌礼仪，其余小游戏没有改动。

- **新增「重开本轮」投票**：任何玩家按 F5 或通过暂停菜单发起，房间过半同意后进入 5 秒自动确认倒计时（期间可撤票取消），确认后回到本轮开始并回滚本轮分数。门槛设为过半而不是全票，避免掉线或挂机的玩家让投票永远无法通过。
- **猎鸭**：修复角色被场地几何卡死、方向键无反应的问题。本地复现不出该问题，本轮加了自动脱困：按住方向键连续 3 秒几乎无位移时，自动退回约一米前的位置。卡住位置的坐标会写入游戏日志 —— 再遇到请用启动器的「游戏日志」按钮反馈，这是定位该问题的唯一途径。
- **餐桌礼仪**：修复新增的第 5~8 个座位在恢复进食后拿叉明显变慢的问题（原为座位唤醒等待逐人累加，第 8 座最坏约 2.6 秒）。现改为每人独立计时，总延迟与人数无关；4 人及以下与原版逐值一致。
- **版本提示**：进不去房间时的「版本不符」提示原本分不清原因（1.5 曾重写但没有生效）。现在能分清五种情形并列出双方版本号：您的版本低于或高于房主、对方没装或版本过旧、双方版本相同但游戏本体不同；顺带修复中文提示不换行的问题。
- **房间上限保护**：8 人上限由程序固定，其他 Mod 试图压回 4 人的写入会被忽略；Steam 房间人数上限也会定期核对并恢复。
- **新增 MPML 备选安装（实验性）**：给想与 MachineParty+ 等其他 Mod 共存的玩家准备（需先装 MachinePartyModLoader，再下载本次 Release 的第二个附件 `Machine-Party-Overtime-1.6-MPML.zip`，把里面的 `overtime` 文件夹放进游戏 `mods` 目录）。主推仍是 exe 启动器，两种装法可以同房，但每台机器只能选一种；挂载前核对原版文件，游戏更新后自动拒绝挂载，不会拿旧脚本盖新游戏。

「重开本轮」与版本提示均已通过本机 8 实例联机验证。猎鸭卡死与餐桌礼仪的修复受限于本地无法复现 / 静态检查覆盖不到，需经真实对局最终确认 —— 上线后如有问题请继续反馈。

⚠️ 1.6 与 1.5 及更早版本不能互通，同一房间的所有玩家都需要更新至 1.6。
如果进入房间时提示“您当前的游戏版本与该房间不符”，请查看主菜单右下角，所有人的版本都应显示：
v2.1.2+overtime-1.6
如果压缩包是群友或朋友转发的，也请把新版重新发给他们，避免房间里混入旧版本。

> **English — 1.6: a "restart this round" vote, plus fixes for Duck Hunt and Table Manners.**
>
> Download:
> https://github.com/DarkJadeStone/MachineParty-Overtime/releases/tag/v1.6
> Most players only need `Machine-Party-Overtime-1.6.zip`. If you already have an older version
> you do **not** need to uninstall first: quit the game completely, extract the new archive, run
> `overtime_launcher.exe` inside it, and click **Enable Overtime**.
>
> This update changes gameplay in **Duck Hunt and Table Manners only**. No other minigame was
> adjusted.
>
> - **New: a "restart this round" vote.** Any player can start one with F5 or from the pause menu.
>   Once more than half the lobby agrees, a 5-second confirmation countdown begins (withdrawing a
>   vote during it cancels the restart); on confirmation the round returns to its start and the
>   score earned in it is rolled back. The threshold is a majority rather than unanimity, so a
>   disconnected or idle player cannot make the vote impossible to pass.
> - **Duck Hunt**: fixed a character getting stuck in the arena geometry with the movement keys
>   doing nothing. The problem cannot be reproduced locally, so this version adds an automatic
>   escape: hold a direction for 3 seconds with almost no movement and you are returned to where
>   you were about a metre earlier. The stuck coordinates are written to the game log — if it
>   happens again, please send the log using the launcher's **Game log** button. That log is the
>   only way to pin this down.
> - **Table Manners**: fixed the new seats 5–8 being noticeably slower to pick the fork back up
>   after eating resumes (the per-seat wake-up wait used to accumulate player by player — about
>   2.6 seconds at worst for seat 8). Each player is now timed independently, so the total delay no
>   longer depends on the player count; with four players or fewer the values match the original
>   game exactly.
> - **Version mismatch messages**: the "version does not match" notice used to give no clue as to
>   why (1.5 rewrote it, but the rewrite never actually took effect). It now distinguishes five
>   cases and prints both version strings: your version is older or newer than the host's, the
>   other side has no mod or too old a one, or both mod versions match but the base game differs.
>   A Chinese line-wrapping bug in the same dialog is fixed as well.
> - **Player-cap protection**: the 8-player cap is now pinned by the mod, and writes from other
>   mods trying to force it back to 4 are ignored. The Steam lobby capacity is re-checked and
>   restored periodically as well.
> - **New: an alternative MPML install (experimental)** for players who want Overtime alongside
>   other mods such as MachineParty+. It requires MachinePartyModLoader to be installed first, and
>   the `overtime` folder from `Machine-Party-Overtime-1.6-MPML.zip` — the second asset on this
>   release — to be placed in the game's `mods` directory. The `.exe` launcher is still the
>   recommended route. The two install methods can share a lobby, but each machine has to pick one.
>   The package verifies the original game files before mounting and refuses to mount after a game
>   update, so it can never lay old scripts over a newer game.
>
> The restart vote and the version messages were both verified locally with 8 connected instances.
> The Duck Hunt and Table Manners fixes could not be — the first cannot be reproduced locally and
> the second is beyond what static checking covers — so both need confirmation from real matches.
> Please keep the reports coming.
>
> ⚠️ **1.6 is not compatible with 1.5 or earlier** — everyone in the lobby must update to 1.6.
> If joining shows "your client version does not match the host version", check the bottom right
> of the main menu; everyone should read:
> `v2.1.2+overtime-1.6`
> If someone forwarded you the archive, please send them the new one too, so no old version ends
> up in the lobby.

---

### 1.5 —— 碎骨者：装置挂在身上却不处决

下载地址：
https://github.com/DarkJadeStone/MachineParty-Overtime/releases/tag/v1.5
普通玩家下载「Machine-Party-Overtime-1.5.zip」即可。已经安装旧版的玩家不需要先卸载：完全退出游戏，解压新版压缩包，运行里面的「overtime_launcher.exe」，点击“启用 Overtime”即可完成更新。
本次玩法更新只涉及「碎骨者」，其他小游戏的玩法没有调整。

* 修复装置扑到玩家身上后一直不处决的问题。
* 修复该状态下玩家按键没有反应、无法将装置扔出的问题。
* 修复由此造成的残局永久卡死：被挂住的玩家既不会死亡，也无法摆脱装置，最后只剩两人时游戏无法继续结算。
* 退休的装置由熄灯改为绿色慢闪。现在红色快闪代表引信正在燃烧，绿色慢闪代表装置已经退休、不会再次行动。

前三个现象实际来自同一个问题：装置之前发出的一次“重新寻找目标”请求会延迟执行。在等待期间，它可能已经扑到了玩家身上；但旧请求到点后，仍会把它强行派去追赶其他人。
这会导致装置实际已经离开，玩家背上的模型和状态却没有解除。服务器也不再认为那台装置真正挂在玩家身上，因此既不会继续处决，也找不到可以扔出的装置，最终让该玩家永久留在场内、整局无法结束。
现在，已经挂在玩家身上或正在处决的装置不会再被重新分配目标。引信会正常倒计时，玩家也可以正常将其扔出。
另外，只剩两名玩家时，按设计会有一台装置退休，只留下另一台进行最后的 1v1。旧版退休后直接熄灯，看起来很像装置又卡住了；1.5 改为绿色慢闪，可以直接区分“正常退休”和“仍在追击”。
这个问题先后由三位玩家在评论区独立反馈，描述的“蜘蛛挂在身上不咬人”“红蜘蛛扔不出去”“最后两人无法结束”已经确认是同一个问题。修复已通过本机 8 实例定向验证，成功拦截了三次错误的目标重派，正常处决和复位流程也能继续运行。
⚠️ 1.5 与 1.4 及更早版本不能互通，同一房间的所有玩家都必须更新至 1.5。
如果进入房间时提示“您当前的游戏版本与该房间不符”，请查看主菜单右下角，所有人的版本都应显示：
v2.1.2+overtime-1.5
如果压缩包是群友或朋友转发的，也请把新版重新发给他们，避免房间里混入旧版本。

> **English — 1.5: Spine Breaker devices that latch on but never execute.**
>
> Download:
> https://github.com/DarkJadeStone/MachineParty-Overtime/releases/tag/v1.5
> Most players only need `Machine-Party-Overtime-1.5.zip`. If you already have an older version
> you do **not** need to uninstall first: quit the game completely, extract the new archive, run
> `overtime_launcher.exe` inside it, and click **Enable Overtime**.
>
> This update changes gameplay in **Spine Breaker only**. No other minigame was adjusted.
>
> * Fixed a device latching onto a player and then never executing them.
> * Fixed the player being unable to act in that state — inputs did nothing and the device could
>   not be thrown off.
> * Fixed the permanent stall this caused: the pinned player neither died nor got free, so once
>   only two players were left the round could never settle.
> * A retired device now blinks slowly in green instead of going dark. Red and fast means the fuse
>   is burning; green and slow means the device has retired and will not act again.
>
> The first three are the same bug. A device's earlier "find a new target" request is executed
> after a delay. During that wait it may already have latched onto a player — but when the old
> request comes due, it is still sent off to chase someone else.
>
> The device has effectively left, yet the model and state on the player's back are never cleared.
> The server also no longer considers that device to be riding the player, so it neither continues
> the execution nor finds a device that can be thrown — leaving that player stuck on the field
> forever and the round unable to end.
>
> Now a device that is already riding a player, or currently executing one, is no longer
> reassigned. The fuse counts down normally and the player can throw it off as usual.
>
> Separately, when only two players remain one device retires by design, leaving the other for the
> final 1v1. Previously it simply went dark, which looked a lot like the device had frozen again;
> 1.5 makes it blink slowly in green so "retired normally" and "still hunting" can be told apart
> at a glance.
>
> Three players reported this independently in the comments — "the spider hangs on and won't
> bite", "the red spider can't be thrown", "the last two players can't finish" — all confirmed to
> be the same bug. The fix was verified locally with 8 instances, intercepting three incorrect
> target reassignments, with normal execution and reset flows still running.
>
> ⚠️ **1.5 is not compatible with 1.4 or earlier** — everyone in the lobby must update to 1.5.
> If joining shows "your client version does not match the host version", check the bottom right
> of the main menu; everyone should read:
> `v2.1.2+overtime-1.5`
> If someone forwarded you the archive, please send them the new one too, so no old version ends
> up in the lobby.

---

### 1.4 —— 残骸平台：修好 8 人局无法结束

本次更新只修改了「残骸平台」，其他小游戏没有改动。

- 修复 8 人局无法结束的问题：场上玩家已经全部消失，游戏却不结算，垃圾仍不断掉落并持续拖低帧数。
- 修复压缩机与平台错配：部分平台堆满残骸后压缩机不下来，反而是其他位置的压缩机被触发。
- 压缩机淘汰现在统一由房主判定，避免不同客户端按各自视角分别处理玩家死亡，并防止同一名玩家被重复判死。
- 增加结算保险：如果以后再次出现「玩家已经出局，但房主没有登记」的情况，大约 3 秒后会自动修正，
  不再让整局永久卡死。

这个问题是 1.3 加入 8 方位独立视角时引入的：当时压缩机被错误地跟着摄像机一起重新分配了，
现在已经把画面与玩法判定彻底分开。已通过本机 8 实例复现旧问题，并确认修复后能够正常进入结算。

如果你还在使用 1.3，1.4 的启动器也已经包含 1.3.1 的「误判游戏正在运行」修复。

另外，评论区反馈的「碎骨者只剩最后两人时无法投掷」未包含在本次更新，仍在排查。

⚠️ **1.4 与 1.3、1.3.1 均不能互通**，同一房间的所有玩家都需要更新至 1.4。
（主菜单右下角会显示 `v2.1.2+overtime-1.4`，一眼能对。）

> **English — 1.4: Debris Platforms rounds that could never end.**
>
> This update changes **Debris Platforms only**. No other minigame was touched.
>
> - **Fixed 8-player rounds that could not end**: every player on the field was already gone, yet
>   the round never settled — junk kept falling and the frame rate kept dropping.
> - **Fixed compactors being matched to the wrong platform**: some platforms would pile up with
>   debris while the compactor above them never came down, and a compactor somewhere else fired
>   instead.
> - **Compactor eliminations are now decided by the host**, so clients no longer each resolve a
>   player's death according to their own camera angle, and the same player can no longer be
>   counted out twice.
> - **Added a settlement safety net**: if a player ever ends up "out, but not registered by the
>   host" again, it is corrected automatically after about 3 seconds instead of hanging the whole
>   round forever.
>
> This was introduced in 1.3 together with the 8-direction independent camera: the compactors were
> incorrectly reassigned along with the camera. Visuals and gameplay decisions are now fully
> separated. Reproduced locally with 8 instances, and confirmed the round settles again after the fix.
>
> If you are still on 1.3, the 1.4 launcher also includes the 1.3.1 fix for the false
> "the game is running" report.
>
> The "Spine Breaker: cannot throw when only two players remain" report from the comments is
> **not** included in this update — still being investigated.
>
> ⚠️ **1.4 is not compatible with 1.3 or 1.3.1** — everyone in the lobby has to update to 1.4.
> (The main menu bottom right reads `v2.1.2+overtime-1.4`.)

---

### 1.3.1 —— 只换启动器：修好「明明没开游戏，却说游戏正在运行」

⚠️ **这一版只改启动器，游戏内容一个字节都没变。**

- **已经装好 1.3 的人不用做任何事**，主菜单右下角仍然是 `v2.1.2+overtime-1.3`；
- **1.3.1 和 1.3 能一起玩**，不需要全房间同步更新；
- 只有**装不上**的人才需要下这一版。

- **修复**：少数玩家点「启用 Overtime」时必定弹出「游戏正在运行，先完全退出」，
  但游戏其实根本没开，重启电脑、重装游戏都没用，等于永远装不上。
  原因是旧版只按**进程名**判断游戏在不在跑 —— 系统里只要存在任何一个叫
  `Machine Party.exe` 的进程（上次没退干净的残留进程、崩溃后被系统挂住的进程、
  或者别的目录下一个同名程序），就会被拦下。现在改为**直接检查游戏数据包本身有没有被占用**，
  并且只有当同名进程**确实位于你选中的那个游戏目录里**时才拦截。
- **提示更清楚**：真的被占用时，弹窗会直接列出占用进程的 PID 和完整路径，
  照着去任务管理器结束它就行，不用再猜是什么东西占着。
- **安装日志**：修复同一批记录被写进文件两遍、以及每次启动多记一行的问题，日志现在干净可读。
- **界面**：右上角多显示一行「安装器」版本号，反馈问题时能一眼说清自己用的是哪一版。

> **English — 1.3.1: launcher only — fixes "the game is running" when it isn't.**
>
> ⚠️ **This release changes the launcher only. Not one byte of game content changed.**
>
> - **If you already have 1.3 installed, do nothing** — the main menu still reads `v2.1.2+overtime-1.3`;
> - **1.3.1 and 1.3 play together**, so a lobby does not have to update in lockstep;
> - Only download this if the installer refused to work for you.
>
> - **Fixed**: for a few players, "Enable Overtime" always popped up "The game is running.
>   Fully exit it first" even though the game was closed — and neither rebooting nor
>   reinstalling the game helped, making it impossible to install at all.
>   The old check went purely by **process name**: any process called `Machine Party.exe`
>   anywhere on the system (a leftover process that never exited, one Windows kept alive after
>   a crash, or an unrelated program with the same name) would block it. It now **checks whether
>   the game's PCK is actually locked**, and only treats a same-named process as the game when
>   it really lives inside the game folder you picked.
> - **Clearer message**: when something genuinely is holding the file, the dialog now lists the
>   PID and full path of that process, so you can end it in Task Manager directly.
> - **Install log**: fixed the same batch of lines being written to the file twice, plus one
>   redundant line per launch. The log is readable now.
> - **UI**: the top right corner now also shows an "installer" build number, which makes bug
>   reports much easier to place.

---

### 1.3 —— 加载期间掉线，以及多人局中的实际游玩问题

- **联机掉线**：修复玩家在小游戏加载过程中掉线后，本局全程静音、结束时全员黑屏的问题；
  同时为 12 个小游戏补上异常收尾保护，并修正枪械工厂、吸烟小憩在该时机可能出现的清理报错。
- **碎骨者**：修复正对玩家时无法投掷、第二台装置持续追踪已经背着装置的玩家，
  以及投掷时误选别人背上或已经飞出的装置、导致投掷落空的问题。
- **残骸平台**：调整场地与摄像机，8 人局中每名玩家使用独立的 45° 视角，减少互相遮挡；
  静止残骸回收时间由 60 秒缩短至 30 秒。
- **残骸平台**：修复多人争抢同一块残骸后，残骸可能永久穿过其中一名玩家的问题。
- **猎鸭**：6 人局猎人射速降低 20%；修复 7 人独狼回合错误显示为「猎人削弱」的问题。
- **猎鸭**：修复两名猎人同时命中同一只鸭时，死亡动画、血和音效可能重复触发的问题；计分本身不会重复。
- **启动器**：新增「游戏日志」按钮，可以直接找到当前的 `godot.log`；原「打开日志」更名为「安装日志」。
  按钮只打开本地文件夹，不会自动上传日志。
- **日志清理**：开发用的 `[MP8-AUDIT]` 侦察日志改为按需开启，正式游玩时不再默认输出大量无用诊断信息。
- **安装说明**：补充说明 Overtime 暂不兼容 MachinePartyModLoader，以及其他会修改游戏 PCK 的 Mod。
  该限制并非 1.3 新增。

⚠️ **1.3 与 1.2 不能互通**，同一房间的所有玩家都需要更新至 1.3。
（主菜单右下角会显示 `v2.1.2+overtime-1.3`，一眼能对。）

> **English — 1.3: a disconnect during loading, plus issues that actually show up in multiplayer.**
>
> - **Disconnects**: fixed a player dropping *during minigame loading* leaving the whole round
>   silent and every player on a black screen at the end. Twelve minigames also got a guard
>   against running end-of-round logic before the round started, and cleanup errors in
>   Manufacture Gun and Smoke Break at that same moment are fixed.
> - **Spine Breaker**: fixed being unable to throw while facing a player directly; a second
>   device endlessly chasing someone who was already carrying one; and throws picking a device
>   on someone else's back — or one already in flight — instead of your own, so the throw did nothing.
> - **Debris Platforms**: arena and cameras reworked so each of the 8 players gets their own
>   45° view, greatly reducing players blocking each other. Idle debris is now recycled after
>   30 seconds instead of 60.
> - **Debris Platforms**: fixed debris being able to pass through a player permanently after
>   several players contested the same piece.
> - **Duck Hunt**: hunter fire rate reduced by 20% in 6-player rounds; fixed the 7-player
>   lone-hunter round showing "HUNTER NERFED" when the hunter is actually buffed.
> - **Duck Hunt**: fixed the death animation, blood and sound effects firing twice when two
>   hunters hit the same duck simultaneously. Scoring itself never double-counted.
> - **Launcher**: new "Game log" button that takes you straight to the current `godot.log`;
>   the old "Open log" is now "Install log". The buttons only open a local folder —
>   nothing is uploaded.
> - **Log cleanup**: the developer `[MP8-AUDIT]` diagnostic dump is now opt-in, so normal play
>   no longer floods the log with diagnostics nobody needs.
> - **Install notes**: documented that Overtime is not currently compatible with
>   MachinePartyModLoader, or with any other mod that modifies the game's PCK.
>   This is not new in 1.3.
>
> ⚠️ **1.3 is not compatible with 1.2** — everyone in the lobby has to update to 1.3.

---

### 1.2 —— 修好了两个会卡死整局的 bug，顺带把重复音效压下去

**内部暗手：拿到针筒的人再拿到一支，整局会卡死。**
猎杀阶段永远不开始 —— 扎不了人、其他人的视角不会拉近、灯也不会关，
而那支针已经从柜子里被取走了，场上再没有第二支可找，只能干等到超时。
根因是「已找到的针筒数」被按**人**去重了，而它本该按**针**计数。

**残骸平台：后半局不再掉石头。**
停在平台上不动的残骸永远不会被回收（原版唯一的回收口是「掉出平台」），
攒够 40 块之后就一块都不再掉，这一局的玩法直接消失。
8 人局尤其严重：掉落点是每人一个，一个 tick 就投 8 块，十几秒就能把池子掏空。
现在静止超过 1 分钟的残骸会被主动回收并重新投放。

**重复音效。** 多处音效由 8 台机器各广播一遍，每台最终叠着播 8 声
（心电图滴答、换弹、拾枪、死亡音、送货区指示灯）。现在每端各响一声。
顺带修掉「内部暗手一次搜索被算 7 次」的连锁广播。

⚠️ **1.2 与 1.1 不能互通**：版本号写进了联机握手，一起玩的人都要更新。
（主菜单右下角会显示 `v2.1.2+overtime-1.2`，一眼能对。）

> **English — 1.2: two game-breaking hangs fixed, plus duplicated sound effects.**
> **Inside Job**: if the player who already held a syringe picked up the second one, the hunt
> phase never started — nobody could stab, cameras never zoomed, lights never went out, and
> the round could only time out. The syringe counter was de-duplicated per *player* when it
> should have counted per *syringe*. **Debris Platforms**: debris that came to rest on the
> platform was never recycled (the only recycler was "fell off the platform"), so after 40
> pieces nothing dropped for the rest of the round — much worse at 8 players, where every
> player is a spawn point. Debris idle for over a minute is now actively recycled.
> **Duplicated SFX**: several sounds were broadcast once per machine and played 8 times over
> on every client; now once each. **1.2 is not compatible with 1.1** — everyone in the lobby
> has to update.

---

### 1.1 —— 修好了「房主和客机看到的场地不一样」

6 人局与 5 人局实测报出来的三处**主客机不同步**，全部修好。
三处的共同点：那些东西是**每台机器各自摆的**，而摆的依据只有房主有 ——
所以两边都不报错，只能靠人对着画面才看得出来。

| 小游戏 | 之前是什么样 |
| --- | --- |
| **枪械工厂** | 房主看到的走道是空的，**其他人的走道中间杵着一张桌子，还挡路**（有碰撞） |
| **凿刻考验** | 记忆阶段（看巨幕）房主视野里其他人会隐身让开，**其他人看到的还是一排后脑勺** |
| **吸烟小憩** | 8 个座位和两个木箱的摆位，房主和其他人不是同一套 |

⚠️ **1.1 与 1.0 不能互通**：版本号写进了联机握手，一起玩的人都要更新。
（主菜单右下角会显示 `v2.1.2+overtime-1.1`，一眼能对。）

> **English — 1.1: fixed the host seeing a different arena from everyone else.**
> Three desyncs found in real 5- and 6-player sessions. All three came from props that each
> machine places locally from data only the host had, so nothing errored — you could only
> catch it by comparing screens. **Manufacture Gun**: clients had an extra solid workbench
> blocking the walkway. **Chisel Gauntlet**: during the memorise phase other players only
> vanished on the host's screen. **Smoke Break**: seats and crates were laid out differently
> for the host and everyone else. **1.1 is not compatible with 1.0** — the version string is
> part of the multiplayer handshake, so everyone in the lobby has to update.

---
