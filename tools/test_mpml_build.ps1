param([Parameter(Mandatory=$true)][string]$PackageDirectory)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$package = (Resolve-Path -LiteralPath $PackageDirectory).Path
$info = Get-Content -LiteralPath (Join-Path $package 'BUILDINFO.json') -Raw | ConvertFrom-Json
$version = $info.mod_tag -replace '^overtime-', ''
$zipName = 'Machine-Party-Overtime-' + $version + '-MPML.zip'
$archive = Join-Path (Split-Path -Parent $package) $zipName
$work = Join-Path $env:TEMP ('mp8-mpml-build-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
Copy-Item -LiteralPath $package -Destination (Join-Path $work 'overtime') -Recurse
Copy-Item -LiteralPath $archive -Destination (Join-Path $work $zipName)
$code = Join-Path $work 'FailBuilder.cs'; $failBuilder = Join-Path $work 'FailBuilder.exe'
[IO.File]::WriteAllText($code, 'class FailBuilder { static int Main() { return 23; } }')
& 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' /nologo /target:exe "/out:$failBuilder" $code
if ($LASTEXITCODE -ne 0) { throw 'Failure fixture did not compile' }
function Snapshot {
    @(@(Get-ChildItem -LiteralPath (Join-Path $work 'overtime') -File) + @(Get-Item -LiteralPath (Join-Path $work $zipName)) | Sort-Object FullName | ForEach-Object { $_.Name + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash })
}
$before = Snapshot
$rejected = $false
try { & (Join-Path $PSScriptRoot 'build_mpml_mod.ps1') -Out (Join-Path $work 'overtime') -Godot $failBuilder } catch { $rejected = $_.Exception.Message -match 'packaging failed \(exit 23\)' }
if (-not $rejected -or @(Compare-Object $before (Snapshot)).Count) { throw 'Failed builder did not preserve both previous outputs' }
$unownedParent = Join-Path $work 'unowned'
New-Item -ItemType Directory -Path $unownedParent | Out-Null
$unownedArchive = Join-Path $unownedParent $zipName
[IO.File]::WriteAllText($unownedArchive, 'unrelated sibling archive')
$rejected = $false
try { & (Join-Path $PSScriptRoot 'build_mpml_mod.ps1') -Out (Join-Path $unownedParent 'overtime') -Godot $failBuilder } catch { $rejected = $true }
if (-not $rejected -or [IO.File]::ReadAllText($unownedArchive) -ne 'unrelated sibling archive' -or (Test-Path -LiteralPath (Join-Path $unownedParent 'overtime'))) { throw 'Unowned sibling archive was modified' }
$foreign = Join-Path $work 'foreign'
New-Item -ItemType Directory -Path $foreign | Out-Null
[IO.File]::WriteAllText((Join-Path $foreign 'user.txt'), 'keep')
$rejected = $false
try { & (Join-Path $PSScriptRoot 'build_mpml_mod.ps1') -Out $foreign -Godot $failBuilder } catch { $rejected = $true }
if (-not $rejected -or [IO.File]::ReadAllText((Join-Path $foreign 'user.txt')) -ne 'keep') { throw 'Foreign output directory was modified' }
Write-Host 'PASS MPML build failure preserves previous outputs; foreign directory and sibling archive are protected'
Write-Host "MPML build test artifacts: $work"
