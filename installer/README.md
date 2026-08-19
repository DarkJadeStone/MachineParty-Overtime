# Machine Party-Overtime

Raises the multiplayer cap from **4 to 8 players** — and reworks arenas, scoring and some
mechanics per minigame so that eight actually works. Free and open source.
**Game version: v2.1.2 (Steam).**

> ## ⚠️ This mod is completely FREE. If you paid for it, you were scammed.
> Get it only from the official Releases page. Nobody is authorised to sell it.

---

## Install

1. **Fully exit the game.** (Wait until Steam stops showing you as In-Game.)
2. Run **`overtime_launcher.exe`**.
3. Press **Enable Overtime**.

That is the whole thing. No runtime to install, nothing else to download.

**Installed correctly** = the version in the bottom right of the main menu ends with `+overtime`.

> Windows may show "Windows protected your PC" because this exe is not code-signed
> (a signing certificate costs money). Click **More info → Run anyway**. If you would rather not,
> the source is public — build it yourself.

## The launcher does not stay running

**Overtime is not loaded at runtime.** Enabling it rewrites your game data once, and that is the
end of it:

- Once enabled, **launch the game from Steam exactly as you always have.** The mod is already in
  your game files.
- Nothing runs in the background, nothing starts with Windows, nothing hooks the game process.
- The **Play** button is a convenience — it just asks Steam to start the game. Ignoring it changes
  nothing.
- You only open the launcher again to **switch back to vanilla**, switch back to Overtime, or check
  which state you are in.

## What the buttons do

| Button | What it does |
| --- | --- |
| **Enable Overtime** / **Switch to vanilla** | Flips between the two. Takes about a second. |
| **Play** | Asks Steam to launch the game. Optional. |
| **Steam repair** | Opens Steam's "verify integrity of game files". Use it if something is broken and you have no way back. |
| **Open log** | Shows exactly what the launcher did. **Attach this when reporting a problem.** |

## Three things you must know

1. **You need a legitimate copy of the game.** This program contains no game files; it patches
   your own installation.
2. **Everyone in the lobby must run the same mod version.** The version is part of the multiplayer
   handshake and the host refuses mismatches. This is deliberate — mixing modded and unmodded
   players fails mid-match in ways that are very hard to diagnose. So **while Overtime is enabled
   you cannot play with unmodded friends**; switch back to vanilla first (one click).
3. **Reverting is exact.** After switching back, the launcher verifies the result is byte-for-byte
   identical to the original game data before telling you it succeeded.

## FAQ

**The mod disappeared after a few days.**
Steam updated the game, or you ran "Verify integrity of game files" — both replace the game data.
Just enable it again. If the *game version* changed, the launcher will stop and tell you: wait for
an Overtime build that targets it. It will not patch a version it does not know.

**"The current PCK does not match the vanilla build this mod knows."**
Your game is not v2.1.2 (it updated), or another mod is installed. **Nothing was changed.** Safest
fix: Steam → right click the game → Properties → Installed Files → Verify integrity, then check
whether Overtime has a build for your version.

**The launcher cannot find my game.**
Use **Browse…** and pick the folder that contains `Machine Party.pck`
(Steam → right click the game → Manage → Browse local files).

**My friend cannot join / version mismatch.**
You are on different Overtime versions, or one of you has it disabled. Compare the version strings
in the bottom right of the main menu.

**Will this get me banned / break achievements?**
It replaces the game's own script data pack only — it does not touch the exe, any Steam dll, or
achievement logic. It is still an unofficial modification: if something breaks, **revert to vanilla
before reporting the bug to the developers.**

## Source

Fully open source. The repository publishes diffs against the game's own scripts — no game code or
assets are redistributed — plus the launcher's complete source, so you can rebuild it yourself from
your own legitimate copy.

Unofficial third-party modification. Not affiliated with, authorized by, or endorsed by the
developer or publisher of Machine Party.

---

# Machine Party-Overtime

把联机上限提到 **8 人** —— 并且逐个小游戏重做了场地、算分与部分玩法，不只是改大人数常量。
免费、开源。**适用游戏版本：v2.1.2（Steam）。**

> ## ⚠️ 本 mod 完全免费。如果你为它花过钱，说明你被骗了。
> 只从官方 Releases 页面下载。任何人都无权拿它收费。

---

## 安装

1. **完全退出游戏**（等 Steam 不再显示你「游戏中」）。
2. 运行 **`overtime_launcher.exe`**。
3. 点 **启用 Overtime**。

就这些。不用装运行库，不用再下别的东西。

**装好的标志**：主菜单右下角的版本号后面带 `+overtime`。

> **Windows 可能弹「已保护你的电脑」**：因为这个 exe 没有买代码签名证书（那要花钱）。
> 点「更多信息」→「仍要运行」。不放心就别装 —— 源码是公开的，可以自己编。

## 启动器不需要常驻

**Overtime 不是运行时加载的。** 启用一次就是改写一次游戏数据，改完就结束了：

- 启用之后，**照常从 Steam 启动游戏**，跟以前一模一样。mod 已经在你的游戏文件里了。
- 没有后台进程、不开机自启、不注入游戏进程。
- **「启动游戏」按钮只是顺手** —— 它就是让 Steam 帮你启动游戏，不点也完全不影响。
- 只有在你想**切回原版**、想**切回 Overtime**、或者想**看看现在是什么状态**时，才需要再打开它。

## 几个按钮分别做什么

| 按钮 | 作用 |
| --- | --- |
| **启用 Overtime** / **切回原版** | 在两者之间切换，大约一秒 |
| **启动游戏** | 让 Steam 启动游戏。可有可无 |
| **Steam 修复** | 打开 Steam 的「验证游戏文件的完整性」。出了问题又没别的办法时用它 |
| **打开日志** | 看它到底做了什么。**报问题时请把这个一起发来** |

## 先说清楚三件事

1. **你必须自己有正版 Machine Party。** 这个程序里**没有任何游戏文件** ——
   只有 mod 改过的几十个脚本（几百 KB），补丁是打在你自己那份游戏上的。
2. **一起玩的人必须都装，而且是同一版。** 版本号写进了联机握手，对不上会被房主直接拒绝。
   这是故意的：装了和没装的混在一起玩，会在半局中间以很难查的方式出问题。
   代价是**启用 Overtime 期间不能跟没装的朋友玩**，想一起玩就先切回原版（一次点击）。
3. **还原是精确的。** 切回原版之后，程序会算一遍哈希、确认结果与原版**逐字节相同**才告诉你成功。

## 常见问题

**装完玩了几天，mod 没了？**
Steam 更新了游戏，或者你点过「验证游戏文件的完整性」—— 两者都会把数据包换回原版。
重新启用一次即可。**但如果是游戏版本变了**，启动器会停下来告诉你，要等 Overtime 出适配版本 ——
它不会去打一个自己不认识的版本。

**提示「当前数据包跟本 mod 认识的原版对不上」？**
说明你那份游戏不是 v2.1.2（更新了），或者装过别的 mod。**程序没有动你的文件。**
最稳的办法：先用 Steam「验证游戏文件的完整性」拿回原版，再看 Overtime 有没有出适配版本。

**启动器找不到我的游戏？**
点「**浏览…**」，选那个装着 `Machine Party.pck` 的目录
（Steam 里右键游戏 → 管理 → 浏览本地文件，打开的就是它）。

**朋友进不来，提示版本不匹配？**
两边的 Overtime 版本不一样（或者一边没启用）。对一下主菜单右下角的版本号。

**还原数据（`overtime_restore.dat`）能删吗？**
删了就没法一键切回原版了，只能靠 Steam「验证游戏文件的完整性」。它只有几 KB，留着吧。

**会不会被封号 / 影响成就？**
mod 只替换游戏自己的脚本数据包，不碰 exe、不碰 Steam 相关的 dll，也不改成就逻辑。
但它毕竟是非官方修改：出了任何问题，**先还原成原版再向游戏开发者反馈**。

## 它到底改了什么

- 联机人数上限 4 → 8（大厅席位、出生点、记分板等一起跟着改）
- **逐个小游戏**做 8 人适配：出生点、道具数量、场地摆位、算分名次；
  其中两个小游戏的玩法机制也改了（仓库的 `docs/MINIGAMES.md` 里逐条写明）
- 给游戏版本号加 `+overtime` 后缀，让装了和没装的互相进不了房

**没改**：游戏的美术资源、音频、成就逻辑、任何与付费/授权相关的东西。

## 源码

完全开源。仓库里公开的是**相对游戏脚本的差异补丁**（不转发任何游戏代码与资产），
加上启动器的完整源码 —— 你可以拿自己那份正版从头把它编出来。

非官方第三方修改，与 Machine Party 的开发商、发行商无关，未获其背书。
