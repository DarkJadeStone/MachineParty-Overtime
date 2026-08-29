# Machine Party-Overtime

把《Machine Party》（机械狂欢）的联机上限提到 **8 人** —— 并且逐个小游戏重做了场地、算分
与部分玩法，不只是把人数常量改大。免费、开源、可自己编译。

🎬 **演示视频（B 站）**：https://www.bilibili.com/video/BV1Lo8b6QEh7/

> ## ⚠️ 本 mod 完全免费。如果你为它花过钱，说明你被骗了。
> **This mod is completely FREE. If you paid for it, you were scammed.**
> 只从本仓库的 [Releases](../../releases) 页面下载；任何人都无权拿它收费。

> **English**: An open-source mod that raises the multiplayer cap of *Machine Party* from 4 to 8
> players — and reworks arenas, scoring and some mechanics per minigame to make eight actually work. It patches only the game's own scripts — **no game assets are redistributed**, and you
> must own a legitimate copy. Download the installer from the
> [Releases](../../releases) page, run it, and it patches your local copy (with an automatic
> backup and one-command uninstall). Everyone in a lobby must install the **same** version.
> See it in action: https://www.bilibili.com/video/BV1Lo8b6QEh7/
> See [`docs/MINIGAMES.en.md`](docs/MINIGAMES.en.md) for a per-minigame changelog and
> [`docs/BUILD.md`](docs/BUILD.md) to build it yourself. Not affiliated with or endorsed by
> the game's developer or publisher.

---

![吸烟小憩：8 人一排坐满长凳](images/03_smoke_break_bench.png)

| | |
| --- | --- |
| ![大厅：8 个席位](images/01_lobby_8seats.png) | ![扶梯深渊：8 条独立扶梯](images/04_escalator_pit_8lanes.png) |
| ![餐桌礼仪：8 副餐位](images/02_green_pea_dinner_table.png) | ![结算：8 个名次槽](images/10_scoreboard_8slots.png) |

<sub>实机截图（1920×1080，未修图）。上：吸烟小憩。左上起顺时针：大厅席位、扶梯深渊、
结算榜、餐桌礼仪。**场地是重做的，不是把人数常量改大** —— 座位、餐位、扶梯、
名次槽都实打实扩到了 8 套。</sub>

<sub>*Real in-game captures, unretouched. Arenas are rebuilt, not just a constant bumped:
seats, place settings, escalator lanes and scoreboard slots are all genuinely extended to
eight.*</sub>

---

## 校验下载的文件 / Verifying your download

**1.4** 各文件的 SHA256：

```
82D84FA7AF88516FEF18EFD58A50A4592E38F281E0CD2A73ACA54847C46F7779  Machine-Party-Overtime-1.4.zip
E879C1831F2FC4E29DD909D4805BA319313B6F09BA28EEB3D5D73ED3D8AFD8C7  overtime_launcher.exe
933004418B2B7B1DE1C6B68C9C4A7B091EB6AF5772C964BFFBEFA418B6BC78ED  overtime_install.exe
```

在 PowerShell 里核对：

```powershell
Get-FileHash <文件> -Algorithm SHA256
```

对得上 = 你手里的文件就是本仓库构建出来的那个、中间没有被人改过。
⚠️ 但这**不代表**文件本身安全 —— 源码公开、可自行构建（见 [`docs/BUILD.md`](docs/BUILD.md)）才是更强的保证。

**这一条对本 mod 特别重要**：很多人是从别人那里转发拿到 zip 的，从没打开过本页面。
哈希是他们唯一能自查「这个文件有没有被别人动过手脚」的手段。

> **English** — a match proves the file you have is the one built here and that nobody modified it
> in between. It does **not** by itself prove the file is safe; the public source and building it
> yourself ([`docs/BUILD.md`](docs/BUILD.md)) are the stronger guarantee. This matters more than
> usual here: many players receive the zip forwarded by someone else and never open this page.

## 关于杀毒软件告警 / About antivirus warnings

启动器是**未签名**的小体积 .NET 程序（代码签名证书要花钱），每次发版都重新编译、内嵌 54 个补丁资源、
并且会改写游戏的数据包。这套组合会触发部分杀软的启发式与机器学习判定 —— 报出来的通常是
`Wacatac.B!ml`、`Gen:Variant.MSILHeracles` 这类**通用分类桶**，而不是具体的恶意软件家族。

本程序从立项起就在一批自我限制下开发，全部可在源码中核对：

- **零网络调用** —— 没有 `System.Net` / `HttpClient` / `WebClient` / `Socket` / `WebRequest`
- 没有 P/Invoke、`Marshal`、`Assembly.Load`、`Reflection.Emit`，没有任何动态代码
- 注册表**只读**（只为找到你的 Steam 库路径），从不写入
- 「游戏日志」按钮**只是打开一个文件夹**，从不读取、打包或上传你的任何文件
- **不常驻**：改完游戏数据就退出，无服务、无计划任务、无开机自启
- 卸载**逐字节精确且可证明**：还原后的数据包 SHA256 与原版指纹一致，对不上就拒绝改动

安装器是**单个公开文件** [`installer/Installer.cs`](installer/Installer.cs)，可以逐行读完。
完整讨论见 [issue #2](../../issues/2)。

> **English** — the launcher is a small **unsigned** .NET executable (a signing certificate costs
> money), rebuilt for every release, carrying 54 embedded patch resources and rewriting the game's
> data pack. That combination trips some antivirus heuristics, and what they report are generic
> buckets (`Wacatac.B!ml`, `Gen:Variant.MSILHeracles`) rather than a named malware family.
> It makes **zero network calls**, stays resident nowhere, writes nothing to the registry, never
> reads or uploads your files, and uninstalls byte-exactly. The installer is a single public file
> you can read line by line. Full breakdown in [issue #2](../../issues/2).

---

## 更新日志

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

## 这是什么

原版联机上限 4 人。这个 mod 把上限改成 8 人，并且**逐个小游戏做了 8 人适配** ——
不是简单地把人数常量改大（那样大部分小游戏会当场崩，或者出现两个人叠在同一个出生点、
第 5~8 名看不到自己得分之类的问题）。

15 个可玩小游戏全部动过：出生点补位、道具/装置数量、场地摆位、算分名次、
记分板位数、大厅席位与座椅。

**适用游戏版本：v2.1.2（Steam）。** 游戏更新后不要硬装 —— 安装器会校验，
版本对不上会拒绝安装并告诉你原因，不会把你的游戏搞坏。

## 怎么装

到 [Releases](../../releases) 下载 **`Machine-Party-Overtime-x.y.zip`**，解压后
**完全退出游戏**，运行里面的 **`overtime_launcher.exe`**，点「启用 Overtime」。
装好后主菜单右下角版本号会变成 `v2.1.2+overtime-x.y`。

压缩包里只有两样东西：**启动器**（单文件，不需要装任何运行库）和一份说明。

**启动器不需要常驻** —— Overtime 不是运行时加载的，启用一次就改写完了，
之后**照常从 Steam 启动游戏**；启动器上那个「启动游戏」按钮只是顺手。
只有想切回原版、切回 Overtime、或看当前状态时才需要再打开它。

**切换是一秒钟的事**：还原数据只有几 KB（做法见下面「怎么做到的」），
想跟没装 mod 的朋友玩就点一下切回原版，玩完再点回来。
切回原版后程序会校验结果与原版**逐字节相同**才算成功。

完整说明（含 Windows SmartScreen 提示怎么过、手动指定游戏目录、常见问题）见
[`installer/README.md`](installer/README.md)。

### 三件必须知道的事

1. **你必须自己有正版游戏。** 安装器里没有任何游戏文件，它是在你自己那份游戏上打补丁。
2. **一起玩的人必须都装，而且是同一版。** 版本号会被写进联机握手，对不上会被房主直接拒绝
   —— 这是故意的：装了和没装的混在一起玩，会在半局中间以很难查的方式出问题。
   代价是**装了 mod 就不能和原版朋友一起玩**，想一起玩就先 `--uninstall`。
3. **随时能还原**，而且是精确还原（下面这段解释为什么只要几 KB）。

### 怎么做到「还原只存几 KB」

打补丁的做法是**把新内容追加到数据包末尾，再把索引里那一条指过去** ——
原文件的字节一个都没被覆盖，还躺在包里。所以还原不需要 605 MB 的整包备份，
只要把索引那几个字段写回去、再把文件截断回原长度就行。

这样做反而**更安全**：还原完可以直接算 SHA256 跟原版指纹比对，
**能证明是逐字节精确的**；整包拷贝反而没有这个保证。
而且还原之前会先逐条确认「现在这份包正是我改过的那一份」——
对不上（Steam 更新过、或你点过「验证游戏文件的完整性」）就拒绝动手，绝不瞎写。

## 已知限制（装之前就该知道）

| 项 | 说明 |
| --- | --- |
| **暂不兼容 mod loader 及其他改 PCK 的 mod** | 本 mod 靠重打游戏数据包（`.pck`）安装，**跟 [MachinePartyModLoader](https://github.com/Krunk-theduck/MachinePartyModLoader) 等同样改 PCK 的工具互斥，请二选一**。原因见下 |
| 角色配色只有 5 种 | 游戏自带 5 个颜色，8 人局**必然有人重色**。mod 没有加新颜色 |
| 局时变长 | 淘汰制小游戏人多则轮数多。人工筛选 8 人最多 7 轮，整局时长约为 4 人局的两倍 |
| 部分小游戏在 4 人以下也有视觉变化 | 少数小游戏的场地扩充没有按人数设闸门，2~4 人局会看到多出来的椅子/平台。不影响玩法 |
| 猎鸭 8 人是「6 鸭 2 猎」 | 原版是 3 鸭 1 猎。8 人保持同样的比例，不是 7 鸭 1 猎 |
| 摄像机偶尔拍到布景外 | 部分小游戏为容纳 8 人把镜头拉远，边角可能露出原本在取景框外的布景 |

### 为什么不能跟 mod loader 共存

人数上限写在 `const MAX_PLAYERS` 里，而 **GDScript 的常量是编译期内联的** —— 每一个调用点在编译时就把 `4` 焊死了，运行时没有任何办法改它，只能替换数据包里已编译的字节码。所以本 mod 只能走"重打 PCK"这条路。

而 MachinePartyModLoader 那类加载器是用 `extends` 继承原脚本来做覆盖 —— 这个设计在多 mod 叠加上明显更好，**但继承够不到一个已经内联的常量**：子类里声明 `MAX_PLAYERS = 8`，改不了那些已经编译进 `4` 的代码。

这是结构性冲突，不是打个补丁能绕过去的。**如果有办法在脚本首次加载前替换掉整个编译后的资源（而不是继承它），我很乐意改成散装文件的 mod** —— 欢迎来 [issue](../../issues) 里告诉我。

## 仓库里有什么（以及为什么不是完整脚本）

```
patches/      51 个差异补丁（.patch），相对游戏自己的脚本
installer/    单文件安装器的完整 C# 源码
tools/        构建链：打补丁 → 编译 → 出 exe
docs/         逐个小游戏的改动说明、构建说明、迁移到新版本的说明
```

**想知道具体改了什么玩法？** 看 [`docs/MINIGAMES.md`](docs/MINIGAMES.md) ——
15 个小游戏逐个写明：为了 8 个人改了什么、得分动没动、哪些是故意保持原版的。
（English: [`docs/MINIGAMES.en.md`](docs/MINIGAMES.en.md)）

**为什么发的是差异补丁而不是完整的 `.gd` 文件**：那 51 个文件是「游戏反编译源码 +
我们的改动」混在一起的（合计约 31,000 行），完整发出来等于公开约 14,300 行游戏自己的源代码。
本项目的红线是**不分发游戏原始资产**，所以只发我们自己写的那部分（16,746 行）
加上必要的上下文。

你拿自己那份正版解包出脚本，跑一条命令就能把补丁打上，得到的结果与作者本机
**逐字节相同**（出包时每次都会自动验证这一点）。步骤见
[`docs/BUILD.md`](docs/BUILD.md)。

## 自己编译

```powershell
# 1. 用自己那份游戏解包出原版脚本（需要 gdre_tools v2.6.4）
# 2. 打补丁
powershell -ExecutionPolicy Bypass -File tools\apply_patches.ps1
# 3. 编译
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -CompileOnly
# 4. 出安装器
powershell -ExecutionPolicy Bypass -File tools\build_installer.ps1
```

细节、前置条件和常见报错见 [`docs/BUILD.md`](docs/BUILD.md)。
游戏出新版本后怎么迁，见 [`docs/UPDATING.md`](docs/UPDATING.md)。

## 红线（本项目的自我约束）

- **只服务正版。** 不做任何让盗版联机的东西。
- **不分发游戏原始资产。** 不发美术、音频、场景、完整脚本、数据包。
- 不碰游戏 exe、不碰 Steam 相关的 dll、不改成就逻辑、不动任何与付费/授权相关的东西。

## 授权与声明

代码授权见 [`LICENSE`](LICENSE)（MIT，覆盖本仓库中我们自己写的部分）。

本 mod 是**非官方**的第三方修改，与游戏的开发商、发行商无任何关系，未获其背书。
游戏本身的代码与资产版权归其权利人所有。

出了任何问题，请先 `--uninstall` 还原成原版再向游戏官方反馈 ——
**不要拿装了 mod 的状态去给官方报 bug。**

如果权利人希望本仓库下架，请在 Issues 里提出，会配合处理。
