# Machine Party 8 人 mod —— 编译 + 打包
#
# 自动扫描 patch\ 下所有 .gd，按目录结构推出 res:// 路径，编译成 .gdc 再打进 PCK。
# 加新补丁文件时**不需要改本脚本**，放进 patch\ 对应目录即可。
#
# 用法：  powershell -ExecutionPolicy Bypass -File tools\build.ps1
#
# 注意事项（都是踩过的坑）：
#   - 打包永远从 Machine Party.pck.orig 打，不在已打过的包上叠
#   - 必须打到 res://xxx.gdc（.gd 是 remap 过去的，打 .gd 无效）
#   - 编译必须带 --bytecode=4.5.2
#   - 换 PCK 前必须先关掉所有游戏实例
#   - gdre_tools 把进度条写进 stderr，所以"stderr 为空 = 通过"不可靠，
#     本脚本改为按行过滤真实错误 + 核对产物时间戳

#   - -CompileOnly：只编译到 patch_gdc\，不碰 PCK、不杀游戏进程。
#     出安装器只需要 patch_gdc\（build_installer.ps1 不读 PCK），所以公开仓库那条
#     「自己编一个 exe」的路径不需要 game_test\ 那 605 MB 的包。
#     本机想跑测试台时才需要完整的四步。

param(
    [switch] $CompileOnly
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exe  = Join-Path $root "tools\gdre\gdre_tools.exe"
$p    = Join-Path $root "patch"
$out  = Join-Path $root "patch_gdc"
$gt   = Join-Path $root "game_test"
$orig = Join-Path $gt "Machine Party.pck.orig"

$needs = @($exe, $p)
if (-not $CompileOnly) { $needs += $orig }
foreach ($needed in $needs) {
    if (-not (Test-Path $needed)) { throw "找不到 $needed" }
}

if ($CompileOnly) {
    Write-Host "[1/4] 只编译模式：不关游戏实例、不动 PCK"
} else {
    Write-Host "[1/4] 关闭所有游戏实例"
    Get-Process "Machine Party" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500
}

$sources = Get-ChildItem $p -Recurse -Filter "*.gd" -File
if ($sources.Count -eq 0) { throw "patch\ 下没有 .gd 文件" }

# 编译产物是按**基名**落在 patch_gdc\ 的（gdre 的 --output 只认目录，不保留层级），
# 所以两个不同目录下的同名 .gd 会互相覆盖：后编译的赢，然后**两个** res:// 路径
# 都被打上同一份字节码，而且打包一声不吭。状态机脚本尤其容易撞
# （idle_state.gd / play_state.gd 这种名字每个小游戏都可能有一份）。
$dupes = $sources | Group-Object BaseName | Where-Object { $_.Count -gt 1 }
if ($dupes) {
    Write-Host "基名冲突（编译产物会互相覆盖，必须先改名或改 build 脚本）：" -ForegroundColor Red
    foreach ($d in $dupes) {
        Write-Host ("  {0}.gd :" -f $d.Name) -ForegroundColor Red
        foreach ($f in $d.Group) {
            Write-Host ("      " + $f.FullName.Substring($p.Length + 1)) -ForegroundColor Red
        }
    }
    throw "patch\ 下有同名脚本"
}

Write-Host "[2/4] 编译 $($sources.Count) 个脚本 -> .gdc"
New-Item -ItemType Directory -Force $out | Out-Null
Get-ChildItem $out -Filter "*.gdc" -ErrorAction SilentlyContinue | Remove-Item -Force

$cargs = @("--headless")
foreach ($s in $sources) { $cargs += "--compile=`"$($s.FullName)`"" }
$cargs += @("--bytecode=4.5.2", "--output=`"$out`"")

$cerr = Join-Path $env:TEMP "mp8_compile.err"
Start-Process $exe -ArgumentList $cargs -NoNewWindow -Wait `
    -RedirectStandardOutput (Join-Path $env:TEMP "mp8_compile.out") -RedirectStandardError $cerr

# 每个源文件都必须产出一个同名 .gdc，缺一个就是编译失败
$missing = @()
foreach ($s in $sources) {
    $gdc = Join-Path $out ($s.BaseName + ".gdc")
    if (-not (Test-Path $gdc)) { $missing += $s.Name }
}
if ($missing.Count -gt 0) {
    Write-Host "编译失败，缺少产物：$($missing -join ', ')" -ForegroundColor Red
    ((Get-Content $cerr -Raw) -split "`r|`n") |
        Where-Object { $_ -match "rror|ailed" } | Select-Object -First 20
    throw "编译失败"
}

if ($CompileOnly) {
    Write-Host "[3/4] 跳过打包（-CompileOnly）"
    Write-Host "[4/4] 跳过换包（-CompileOnly）"
    Write-Host ""
    Write-Host ("完成：{0} 个 .gdc → {1}" -f $sources.Count, $out) -ForegroundColor Green
    Write-Host "      下一步：tools\build_installer.ps1" -ForegroundColor Green
    return
}

Write-Host "[3/4] 从 .orig 打包"
$pargs = @("--headless", "--pck-patch=`"$orig`"")
foreach ($s in $sources) {
    # patch\modules\multiplayer\network_manager.gd
    #   -> res://modules/multiplayer/network_manager.gdc
    $rel = $s.FullName.Substring($p.Length + 1) -replace '\\', '/' -replace '\.gd$', '.gdc'
    $gdc = Join-Path $out ($s.BaseName + ".gdc")
    $pargs += "--patch-file=$gdc=res://$rel"
    Write-Host ("      res://{0}" -f $rel)
}
$newPck = Join-Path $gt "new.pck"
if (Test-Path $newPck) { Remove-Item $newPck -Force }
$pargs += "--output=`"$newPck`""

Start-Process $exe -ArgumentList $pargs -NoNewWindow -Wait `
    -RedirectStandardError (Join-Path $env:TEMP "mp8_pack.err")

if (-not (Test-Path $newPck)) { throw "打包失败：没有产出 new.pck" }

Write-Host "[4/4] 换上新 PCK"
$live = Join-Path $gt "Machine Party.pck"
if (Test-Path $live) { Remove-Item $live -Force }
Rename-Item $newPck "Machine Party.pck" -Force

$info = Get-Item $live
Write-Host ""
Write-Host ("完成：{0}  {1:N0} 字节  {2}" -f $info.Name, $info.Length, $info.LastWriteTime) -ForegroundColor Green
