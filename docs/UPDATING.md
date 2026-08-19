# 游戏出新版本之后怎么迁

这份是给「想自己把 mod 迁到新游戏版本」的人看的，也是作者自己的操作手册。
v2.1.1 → v2.1.2 那次是照这个流程实战走通的。

## 为什么游戏一更新 mod 就必须重打

不是「保险起见」，是硬性的：游戏两个联机后端都会拿客户端报上来的
`game_version` 和自己的比对，不一致直接拒绝入房。
所以在旧基线上打出来的 mod，连不上任何用当前零售版的人 —— 必须在新基线上重打。

安装器也会拦：它内嵌了原版 PCK 的 SHA256 与字节数，对不上就**拒装且不动你的文件**。

## 流程

### 1. 先搞清楚上游动了什么，别盲目重打

把新旧两个 PCK 里每个文件的 md5 各 dump 一份再 diff。

> ⚠️ **别跳过 `res://.godot/`**：编译后的场景（`.scn`）藏在 `res://.godot/exported/` 下面，
> 跳了就会漏看场景改动，容易得出「场景没变」的错误结论。

### 2. 看我们改的那 51 个脚本在不在改动清单里

- **不在** → 补丁大概率原样可用，走第 3 步。
- **在** → 上游对那个文件的改动必须合进补丁，否则打上去等于把作者的修复回退掉。

### 3. 重新解包 `src\`，重新打补丁

```powershell
tools\gdre\gdre_tools.exe --headless --recover="<新游戏目录>\Machine Party.pck" --output="src"
powershell -ExecutionPolicy Bypass -File tools\apply_patches.ps1 -Force
```

打不上的那些就是有冲突的文件，手工合。

### 4. 更新安装器里的版本指纹（三行）

`installer/Installer.cs` 顶部：

```csharp
const string GameVersion  = "v2.1.2";
const string VanillaSha   = "326CC398…3DFA8E";
const long   VanillaSize  = 634798100L;
```

三行必须同时改成**新版原版 PCK** 的值，否则会拿旧补丁去打新包。

新哈希这么取（对一份**没装过任何 mod** 的包）：

```powershell
Get-FileHash "<游戏目录>\Machine Party.pck" -Algorithm SHA256
(Get-Item "<游戏目录>\Machine Party.pck").Length
```

### 5. 抬 mod 版本号

`patch/modules/multiplayer/network_manager.gd` 里的 `MP8_VERSION_TAG`。

> 代码里到处是 `MP8_` / `_mp8_` 前缀 —— 那是本项目的**内部代号**，
> 早于「Overtime」这个名字。它们是不对外的标识符，刻意没有跟着改名：
> 全库 3,446 处横跨 37 个已验证文件，改它们是纯风险、零收益。

它是**唯一**的版本号来源：安装器包名、内嵌版本、联机握手全从这里读。

> ⚠️ 改它会让**装了旧版的人进不了新版的房**。这是有意的设计（版本不一致会在半局中间
> 以很难查的方式出问题），但也意味着**发新版要通知所有人一起更新**。

### 6. 重新编译、出包

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -CompileOnly
powershell -ExecutionPolicy Bypass -File tools\build_installer.ps1
```

### 7. 实机验一遍再发

至少确认：主菜单版本号带 `+overtime`、能建房、大厅显示 8 席、进得去小游戏。
理想是跑一局 5 人以上的真人局。

## 如果游戏结构大改

上面假设的是「小版本更新，脚本基本没动」。要是作者重构了某个小游戏，
对应的补丁就得重写而不是合并 —— 那等于把那个小游戏的 8 人适配重做一遍。

判断方法：`apply_patches.ps1` 报冲突的文件数。个位数是合并，
半数以上打不上就是重构，做好重写的准备。
