# Machine Party 8 人 mod —— 把 patches\ 打到你自己解包出来的 src\ 上
#
# 本 mod 公开的是**差异补丁**，不是完整脚本 —— 因为完整脚本里绝大部分是游戏自己的
# 反编译源码，我们不分发它。你需要用自己那份正版游戏解包出 src\，再跑本脚本，
# 就能得到与作者本机**逐字节相同**的 patch\。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File tools\apply_patches.ps1
#   powershell -ExecutionPolicy Bypass -File tools\apply_patches.ps1 -Src D:\mp\src
#
# 前置：见 docs\BUILD.md（要 gdre_tools v2.6.4 + 游戏 v2.1.2 + git）

param(
    [string] $Src = "",       # 解包出来的原版脚本目录，默认 <仓库>\src
    [string] $Out = "",       # 输出目录，默认 <仓库>\patch
    [switch] $Force           # 输出目录已存在时先清空
)

$ErrorActionPreference = "Stop"

$root    = Split-Path -Parent $PSScriptRoot
$patches = Join-Path $root "patches"

if ($Src -eq "") { $Src = Join-Path $root "src" }
if ($Out -eq "") { $Out = Join-Path $root "patch" }

if (-not (Test-Path $patches)) { throw "找不到 $patches" }
if (-not (Test-Path $Src)) {
    throw @"
找不到 $Src

你需要先用 gdre_tools 把自己那份游戏的 PCK 解包成脚本。步骤见 docs\BUILD.md。
一句话版：
  gdre_tools.exe --headless --recover="<游戏目录>\Machine Party.pck" --output="$Src"
"@
}

$git = (Get-Command git -ErrorAction SilentlyContinue)
if ($null -eq $git) { throw "需要 git（用 git apply 打补丁）" }

$list = Get-ChildItem $patches -Recurse -Filter "*.patch" -File
if ($list.Count -eq 0) { throw "patches\ 下没有 .patch 文件" }

if (Test-Path $Out) {
    if ($Force) { Remove-Item $Out -Recurse -Force }
    else { throw "$Out 已存在。确认可以覆盖后加 -Force 重跑。" }
}
New-Item -ItemType Directory -Force $Out | Out-Null

Write-Host "打补丁：$($list.Count) 个"

$missing = @()
$failed  = @()
$ok      = 0

foreach ($p in $list) {
    # patches\modules\multiplayer\network_manager.gd.patch
    #   -> modules\multiplayer\network_manager.gd
    $rel = $p.FullName.Substring($patches.Length + 1)
    $rel = $rel.Substring(0, $rel.Length - 6)      # 去掉 .patch

    $from = Join-Path $Src $rel
    if (-not (Test-Path $from)) { $missing += $rel; continue }

    $dest = Join-Path $Out $rel
    New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
    Copy-Item $from $dest -Force

    # ⚠️ 这两个 -c 缺一不可。本机 git 若开着 core.autocrlf（Windows 默认装法常常是开的），
    #    apply 会把 LF 全部写成 CRLF，于是每行多一个字节 —— 编译能过，但产物与作者那份
    #    对不上，任何字节级校验都会挂。作者本机实测踩过这一条。
    Push-Location $Out
    git -c core.autocrlf=false -c core.eol=lf apply --whitespace=nowarn "$($p.FullName)" 2>&1 | Out-Null
    $code = $LASTEXITCODE
    Pop-Location

    if ($code -ne 0) { $failed += $rel } else { $ok++ }
}

Write-Host ""
if ($missing.Count -gt 0) {
    Write-Host "以下文件在 src\ 里找不到（$($missing.Count) 个）：" -ForegroundColor Red
    foreach ($x in $missing) { Write-Host "    $x" -ForegroundColor Red }
    Write-Host "→ 十有八九是**游戏版本不对**。本 mod 针对 v2.1.2；" -ForegroundColor Yellow
    Write-Host "  游戏更新过就会出现这个，要等 mod 出适配版，或按 docs\UPDATING.md 自己迁。" -ForegroundColor Yellow
}
if ($failed.Count -gt 0) {
    Write-Host "以下补丁打不上（$($failed.Count) 个）：" -ForegroundColor Red
    foreach ($x in $failed) { Write-Host "    $x" -ForegroundColor Red }
    Write-Host "→ 两个常见原因：" -ForegroundColor Yellow
    Write-Host "  ① 解包用的 gdre 版本不是 v2.6.4（反编译结果有出入，行号对不上）；" -ForegroundColor Yellow
    Write-Host "  ② 游戏不是 v2.1.2。" -ForegroundColor Yellow
}
if ($missing.Count -gt 0 -or $failed.Count -gt 0) {
    throw "打补丁未全部成功：成功 $ok / 共 $($list.Count)"
}

Write-Host "全部成功：$ok 个 → $Out" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File tools\build.ps1 -CompileOnly" -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File tools\build_installer.ps1" -ForegroundColor Yellow
