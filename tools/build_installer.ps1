# Machine Party 8 人 mod —— 编译单文件安装器
#
# 产物：dist\mp8-<版本>\overtime_install.exe
#   —— 补丁字节码全部内嵌，用户双击即可，**不需要装 .NET SDK、不需要下 gdre**。
#
# 用编译器是 Windows 自带的 csc.exe（.NET Framework 4，Win10/11 全都有），
# 所以本机不用装任何东西，朋友那边也不用（Framework 4 是系统组件）。
#
# 用法：  powershell -ExecutionPolicy Bypass -File tools\build_installer.ps1
# 前置：  先跑 tools\build.ps1（本脚本只搬 patch_gdc\ 里编译好的产物）

$ErrorActionPreference = "Stop"

$root  = Split-Path -Parent $PSScriptRoot
$patch = Join-Path $root "patch"
$gdc   = Join-Path $root "patch_gdc"
$src   = Join-Path $root "installer\Installer.cs"
$csc   = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

foreach ($needed in @($patch, $gdc, $src, $csc)) {
    if (-not (Test-Path $needed)) { throw "找不到 $needed" }
}

# 版本号唯一来源：network_manager.gd 的 MP8_VERSION_TAG（它同时决定谁能跟谁联机）
$nm = Get-Content (Join-Path $patch "modules\multiplayer\network_manager.gd") -Raw
$m  = [regex]::Match($nm, 'MP8_VERSION_TAG\s*:\s*String\s*=\s*"([^"]+)"')
if (-not $m.Success) { throw "从 network_manager.gd 里读不出 MP8_VERSION_TAG" }
$tag = $m.Groups[1].Value
Write-Host "[1/4] 版本 = $tag"

# 新鲜度：patch\ 里有谁比 patch_gdc\ 新 = build.ps1 没重跑
$sources = Get-ChildItem $patch -Recurse -Filter "*.gd" -File
$stale = @()
foreach ($s in $sources) {
    $o = Join-Path $gdc ($s.BaseName + ".gdc")
    if (-not (Test-Path $o)) { $stale += "$($s.Name)（没有编译产物）"; continue }
    if ((Get-Item $o).LastWriteTime -lt $s.LastWriteTime) { $stale += "$($s.Name)（产物比源码旧）" }
}
if ($stale.Count -gt 0) {
    foreach ($x in $stale) { Write-Host "    $x" -ForegroundColor Red }
    throw "patch_gdc\ 过期，先跑 tools\build.ps1"
}
Write-Host "[2/4] 新鲜度检查通过（$($sources.Count) 个补丁）"

# ── 备料：内嵌资源 ──────────────────────────────────────────────────
# 资源名用序号（mp8.0 / mp8.1 …）而不是 res:// 路径：
# csc 的 /resource: 用逗号分隔"文件,资源名"，路径里的斜杠冒号容易出岔子，
# 序号最稳；路径关系记在 mp8.manifest 里。
$work = Join-Path $env:TEMP "mp8_installer_build"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Force $work | Out-Null

$resArgs = @()
$manifest = @("# <序号>|<res:// 路径>    由 tools\build_installer.ps1 生成")
$i = 0
foreach ($s in $sources) {
    $rel = $s.FullName.Substring($patch.Length + 1) -replace '\\', '/' -replace '\.gd$', '.gdc'
    $blob = Join-Path $work "$i.bin"
    Copy-Item (Join-Path $gdc ($s.BaseName + ".gdc")) $blob -Force
    $resArgs += "/resource:$blob,mp8.$i"
    $manifest += "$i|res://$rel"
    $i++
}

$manFile = Join-Path $work "manifest.txt"
[System.IO.File]::WriteAllText($manFile, ($manifest -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
$resArgs += "/resource:$manFile,mp8.manifest"

$verFile = Join-Path $work "version.txt"
[System.IO.File]::WriteAllText($verFile, $tag, (New-Object System.Text.UTF8Encoding($false)))
$resArgs += "/resource:$verFile,mp8.version"

# ── 编译 ────────────────────────────────────────────────────────────
# 每次重建都从空目录开始：残留上一版的文件会让"发给朋友的到底是哪一版"变成糊涂账
$outDir = Join-Path $root "dist\$tag"
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Force $outDir | Out-Null

# 同一份源码编两个 exe：控制台版（命令行齐全）+ 窗口版（双击即用，一键切换）。
# 窗口版靠 /define:GUI 走另一个 Main，/target:winexe 才不会弹黑框。
$targets = @(
    @{ Name = "overtime_install.exe";  Kind = "/target:exe";    Extra = @() },
    @{ Name = "overtime_launcher.exe"; Kind = "/target:winexe"; Extra = @(
           "/define:GUI",
           "/reference:System.Windows.Forms.dll",
           "/reference:System.Drawing.dll") }
)

Write-Host "[3/4] 编译（csc.exe，内嵌 $i 个补丁）"
$log = Join-Path $env:TEMP "mp8_csc.log"
$built = @()

foreach ($t in $targets) {
    $exe = Join-Path $outDir $t.Name
    # /codepage:65001：源码是无 BOM 的 UTF-8，中文字面量全靠它。
    # 本机 csc 能自己认出来，但换台机器未必，写死更保险。
    $cargs = @(
        "/nologo", $t.Kind, "/platform:anycpu", "/optimize+", "/codepage:65001",
        "/reference:System.dll", "/reference:System.Core.dll"
    ) + $t.Extra + @("/out:$exe", $src) + $resArgs

    if (Test-Path $log) { Remove-Item $log -Force }
    Start-Process $csc -ArgumentList $cargs -NoNewWindow -Wait -RedirectStandardOutput $log
    if (-not (Test-Path $exe)) {
        Get-Content $log | Select-Object -First 30
        throw "编译失败：$($t.Name)"
    }
    $warn = Get-Content $log | Where-Object { $_ -match "error|warning" }
    if ($warn) { $warn | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow } }
    Write-Host ("      {0}  {1:N0} 字节" -f $t.Name, (Get-Item $exe).Length)
    $built += $exe
}

Copy-Item (Join-Path $root "installer\README.md") $outDir -Force
Remove-Item $work -Recurse -Force

# ── 发布包：一个 zip，里面只有启动器 + README ────────────────────────
# 用户 2026-08-18 定：**玩家只该看到一个程序**。
# 控制台版仍然编（自己排查、脚本化安装、以及从源码构建的人要用），
# 但**不进发布包** —— 两个 exe 摆在一起只会让玩家纠结该点哪个。
$zipName = "Machine-Party-Overtime-$($tag -replace '^overtime-', '').zip"
$zip     = Join-Path $outDir $zipName
$stage   = Join-Path $env:TEMP "ot_zip_stage"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item (Join-Path $outDir "overtime_launcher.exe") $stage -Force
Copy-Item (Join-Path $outDir "README.md")             $stage -Force
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -Force
Remove-Item $stage -Recurse -Force
Write-Host ("      发布包 {0}  {1:N0} 字节" -f $zipName, (Get-Item $zip).Length)

# ── 自检：绝不能混进游戏资产 ────────────────────────────────────────
$bad = Get-ChildItem $outDir -Recurse -File | Where-Object { $_.Extension -notin @(".exe", ".md", ".zip") }
if ($bad) {
    foreach ($b in $bad) { Write-Host "    多余文件：$($b.Name)" -ForegroundColor Red }
    throw "发布目录里有不该发的文件"
}
foreach ($e in $built) {
    $sz = (Get-Item $e).Length
    if ($sz -gt 5MB) {
        throw ("{0} 有 {1:N0} 字节，超过 5 MB —— 八成混进了游戏资产，停下来查" -f (Split-Path -Leaf $e), $sz)
    }
}

Write-Host "[4/4] 自检通过"
Write-Host ""
Write-Host "完成：$outDir" -ForegroundColor Green
foreach ($e in $built) {
    $sz = (Get-Item $e).Length
    Write-Host ("      {0,-18} {1,10:N0} 字节（{2:N0} KB）" -f (Split-Path -Leaf $e), $sz, ($sz / 1KB)) -ForegroundColor Green
}
Write-Host ("      内嵌 {0} 个补丁，无外部依赖" -f $i) -ForegroundColor Green
Write-Host ""
Write-Host ("      发给玩家的只有 {0}（启动器 + README）" -f $zipName) -ForegroundColor Green
Write-Host "      overtime_install.exe 是命令行版，自己排查用，**不发**" -ForegroundColor DarkGray
Write-Host ""
Write-Host "给朋友时说清楚：他得自己有正版；一起玩的人必须装同一版。" -ForegroundColor Yellow
