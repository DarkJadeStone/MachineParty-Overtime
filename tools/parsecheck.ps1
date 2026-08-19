# Machine Party 8 人 mod —— 补丁脚本的**运行时解析**冒烟检查
#
# 用法：  powershell -ExecutionPolicy Bypass -File tools\parsecheck.ps1
# 前置：  先跑过 tools\build.ps1（本脚本挂的是打好补丁的 PCK）
#
# ── 它解决什么问题 ─────────────────────────────────────────────
# `build.ps1` 只保证 gdre 能把 .gd 编成 .gdc，**它不解析基类标识符**。
# 2026-08-16 实测：`Minigame extends Node`（不是 Node3D），补丁里写了
# `self.global_transform` —— 编译全绿、打包全绿，游戏一加载才炸：
#     Parse Error: Identifier "global_transform" not declared in the current scope
#     → Failed to load script → 节点没脚本 → @export 接不上 → 小游戏永远起不来
# 表面症状是"卡在 SessionIntro"，看起来像人数/出生点问题，极其误导。
# 那一轮白跑了 7 分钟。本脚本就是为了把这类错在 20 秒内挡下来。
#
# ── ⚠️ 它的能力边界（必须知道，否则会误判）────────────────────
# 这个检查是**把源码喂给 GDScript.reload() 真编一遍**，而同名的类同时又从 PCK 里
# 加载过一份，于是会冒出一批**与我们无关的噪音**，拿原版 src\ 跑基线同样会报：
#   - "Cannot assign a value of type X as Y"（同一个类两个身份，类型对不上）
#   - "Node export is only supported in Node-derived classes ... inherits RefCounted"
#   - "Compile Error: Identifier not found: GameManager"（autoload 没真的实例化）
#   - "class_name isn't allowed in built-in scripts"
# 而且**报什么错跟扫描顺序有关**（前面编过的脚本会影响后面的）。
# 所以：**不要把"零错误"当通过标准**，只看下面这一条高信号模式。
#
# ── 判据（唯一一条）──────────────────────────────────────────
#   出现 `not declared in the current scope` = 真的写错了，必须改。
#   其余的噪音一律忽略。
# 想要更严的结论就跑基线对比：
#   $env:MP8_CHECK_DIR="...\src"; 再跑一遍，只有"补丁报、原版不报"的才算我们的。

$ErrorActionPreference = "Stop"

$root  = Split-Path -Parent $PSScriptRoot
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
$probe = Join-Path $root "tools\probe"
$pck   = Join-Path $root "game_test\Machine Party.pck"

foreach ($needed in @($godot, $pck, (Join-Path $probe "parsecheck.gd"))) {
    if (-not (Test-Path $needed)) { throw "找不到 $needed" }
}

$out = Join-Path $env:TEMP "mp8_parsecheck.out"
$err = Join-Path $env:TEMP "mp8_parsecheck.err"

Write-Host "挂 PCK 解析 patch\ 下所有 .gd ..." -ForegroundColor Cyan
Start-Process $godot `
    -ArgumentList @("--headless", "--path", "`"$probe`"", "--script", "`"$probe\parsecheck.gd`"") `
    -NoNewWindow -Wait -RedirectStandardOutput $out -RedirectStandardError $err | Out-Null

# stderr 里 "---- 文件名" 是分隔线，用它把错归到文件上。
#
# ⭐ 关键区分（不做这一步就全是噪音）：
#   若某文件报了 `inherits "RefCounted"`，说明**它的基类没解析出来**，
#   于是它后面所有 Node 成员（multiplayer / visible / global_transform …）
#   都会连锁报"未声明" —— 这种文件的作用域错误**不可信，只能判为无法判定**。
#   反之，基类正常解析的文件，它报的作用域错误就是**真错**。
#   我们要抓的 `global_transform`（Minigame 是 Node 不是 Node3D）正属于后者。
# `Steam` / `SteamMultiplayerPeer` 是 Steam GDExtension 的单例，headless 探针没加载，
#   与补丁无关，单独滤掉。
$lines = (Get-Content $err -Raw) -split "`r?`n"
$current = "?"
$scope = @{}
$baseBroken = @{}
foreach ($l in $lines) {
    if ($l -match '^----\s*(.+)$') { $current = $Matches[1].Trim(); continue }
    if ($l -match 'inherits "RefCounted"') { $baseBroken[$current] = $true; continue }
    if ($l -match 'Identifier "(.+?)" not declared in the current scope') {
        $id = $Matches[1]
        if ($id -like "Steam*") { continue }
        if (-not $scope.ContainsKey($current)) { $scope[$current] = @() }
        if ($scope[$current] -notcontains $id) { $scope[$current] += $id }
    }
}

$real = @()
$unknown = @()
foreach ($f in $scope.Keys) {
    if ($baseBroken.ContainsKey($f)) { $unknown += $f } else { $real += $f }
}

Write-Host ""
if ($real.Count -gt 0) {
    Write-Host "❌ 真作用域错误 —— 这个 PCK 加载会失败，别拿去跑：" -ForegroundColor Red
    foreach ($f in $real) {
        Write-Host ("   {0}: {1}" -f $f, ($scope[$f] -join ", ")) -ForegroundColor Red
    }
    exit 1
}

Write-Host "✅ 基类能正常解析的脚本里，没有作用域错误。" -ForegroundColor Green
if ($unknown.Count -gt 0) {
    Write-Host ("   无法判定（基类在探针里没解析出来，属探针噪音）：{0}" -f ($unknown -join ", ")) -ForegroundColor DarkGray
}
Write-Host "   这不等于零风险，能力边界见本脚本顶部。" -ForegroundColor DarkGray
exit 0
