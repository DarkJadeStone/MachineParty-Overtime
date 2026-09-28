param()
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$work = Join-Path $env:TEMP ('overtime-build-test-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)
foreach ($directory in @('installer','patch/modules/multiplayer','patch_gdc','tools')) { New-Item -ItemType Directory -Path (Join-Path $work $directory) -Force | Out-Null }
foreach ($file in @('installer/Installer.cs','installer/app.manifest','installer/README.md','tools/build_installer.ps1','patch/modules/multiplayer/network_manager.gd','patch_gdc/network_manager.gdc')) {
    Copy-Item -LiteralPath (Join-Path $repo $file) -Destination (Join-Path $work $file)
}
[IO.File]::SetLastWriteTimeUtc((Join-Path $work 'patch_gdc/network_manager.gdc'), [DateTime]::UtcNow.AddSeconds(1))
$builder = Join-Path $work 'tools/build_installer.ps1'
function Build([string]$Name) { & $builder -Out (Join-Path $work $Name) }
function Info([string]$Name) { Get-Content -LiteralPath (Join-Path $work "$Name/BUILDINFO.json") -Raw | ConvertFrom-Json }
Build 'first'
Build 'reuse'
$first = Info 'first'; $reuse = Info 'reuse'
if ($first.runtimeKey -ne $reuse.runtimeKey -or $first.artifacts[0].sha256 -ne $reuse.artifacts[0].sha256 -or $first.artifacts[1].sha256 -ne $reuse.artifacts[1].sha256) { throw 'Unchanged runtime was not reused byte-for-byte' }
$builderCode = [IO.File]::ReadAllText($builder)
[IO.File]::WriteAllText($builder, $builderCode.Replace("'/optimize+'", "'/optimize-'"), $utf8)
Build 'flags'
if ((Info 'flags').runtimeKey -eq $first.runtimeKey) { throw 'Actual compiler option change did not invalidate the cache' }
[IO.File]::WriteAllText($builder, $builderCode, $utf8)
New-Item -ItemType Directory -Path (Join-Path $work 'foreign') | Out-Null
[IO.File]::WriteAllText((Join-Path $work 'foreign/overtime_launcher.exe'), 'unrelated file', $utf8)
$refused = $false
try { Build 'foreign' } catch { $refused = $true }
if (-not $refused -or [IO.File]::ReadAllText((Join-Path $work 'foreign/overtime_launcher.exe')) -ne 'unrelated file') { throw 'Foreign output was overwritten' }
# Race on an isolated copy only. A large, valid source comment makes it easy to
# mutate AFTER the immutable snapshot exists and before compilation completes.
$source = Join-Path $work 'installer/Installer.cs'
$code = [IO.File]::ReadAllText($source)
$raceCode = $code + "`n/*" + ((('x' * 4096) + "`n") * 4096) + "*/`n"
[IO.File]::WriteAllText($source, $raceCode, $utf8)
$cacheBefore = @(Get-ChildItem -LiteralPath (Join-Path $work 'dist/installer-runtime') -Directory | Select-Object -ExpandProperty Name)
$out = Join-Path $work 'race'
$stdout = Join-Path $work 'race.stdout.txt'; $stderr = Join-Path $work 'race.stderr.txt'
$shell = (Get-Process -Id $PID).Path
$p = Start-Process -FilePath $shell -ArgumentList @('-NoProfile','-File',('"'+$builder+'"'),'-Out',('"'+$out+'"')) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null = $p.Handle
$changed = $false
$timer = [Diagnostics.Stopwatch]::StartNew()
while (-not $p.HasExited -and $timer.ElapsedMilliseconds -lt 10000) {
    $snapshot = @(Get-ChildItem -Path (Join-Path $out '.build-*/inputs/Installer.cs') -ErrorAction SilentlyContinue)
    if ($snapshot.Count -and $snapshot[0].Length -eq $utf8.GetByteCount($raceCode)) {
        [IO.File]::WriteAllText($source, $code + "`n// changed while compiling`n", $utf8)
        $changed = $true
        break
    }
    Start-Sleep -Milliseconds 10
}
if (-not $p.WaitForExit(30000)) { $p.Kill(); throw 'Build race fixture timed out' }
if (-not $changed -or $p.ExitCode -eq 0 -or -not (Select-String -LiteralPath $stderr -Pattern 'Build metadata changed' -Quiet)) { Get-Content -LiteralPath $stderr; throw 'Source race did not abort before publishing' }
$cacheAfter = @(Get-ChildItem -LiteralPath (Join-Path $work 'dist/installer-runtime') -Directory | Select-Object -ExpandProperty Name)
if (@(Compare-Object $cacheBefore $cacheAfter).Count -or (Test-Path -LiteralPath (Join-Path $out 'BUILDINFO.json'))) { throw 'Aborted build published a cache entry or candidate' }
[IO.File]::WriteAllText($source, $code, $utf8)
Build 'restored'
if ((Info 'restored').artifacts[0].sha256 -ne $first.artifacts[0].sha256) { throw 'Source race poisoned the previous runtime' }
Write-Host 'PASS build cache: identical reuse, actual compiler flags, foreign output protection, source-race abort and no poisoned cache'
Write-Host "Build test artifacts: $work"
