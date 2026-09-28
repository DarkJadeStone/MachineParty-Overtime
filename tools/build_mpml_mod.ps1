# Build the alternate MPML package without modifying the installed game/PCK.
param(
    [string]$Godot = '',
    [string]$Out = '',
    [string]$OriginalPack = '',
    [string]$RepositoryRoot = ''
)
$ErrorActionPreference = 'Stop'
$root = if ($RepositoryRoot) { [IO.Path]::GetFullPath($RepositoryRoot) } else { Split-Path -Parent $PSScriptRoot }
if (-not $Godot) { $Godot = $env:GODOT }
if (-not $Godot) { $Godot = 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' }
if (-not $Out) { $Out = Join-Path $root 'dist\mpml\overtime' }
if (-not [IO.Path]::IsPathRooted($Out)) { $Out = Join-Path $root $Out }
$Out = [IO.Path]::GetFullPath($Out).TrimEnd('\','/')
if (-not $OriginalPack) { $OriginalPack = Join-Path $root 'game_test\Machine Party.pck.orig' }
$OriginalPack = [IO.Path]::GetFullPath($OriginalPack)
$parent = Split-Path -Parent $Out
function Assert-UnlinkedPath([string]$Path) {
    $probe = [IO.Path]::GetFullPath($Path)
    while (-not (Test-Path -LiteralPath $probe)) { $probe = Split-Path -Parent $probe }
    $node = Get-Item -LiteralPath $probe
    while ($null -ne $node) {
        if ($node.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked output path: $($node.FullName)" }
        $node = $node.Parent
    }
}
if (-not $parent -or $Out -eq $root -or $root.StartsWith($Out + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe MPML output directory' }
foreach ($protected in @('patch','patch_gdc','src','mpml','tools','game','game_test')) {
    $p = [IO.Path]::GetFullPath((Join-Path $root $protected))
    if ($Out -eq $p -or $Out.StartsWith($p + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Output overlaps input directory: $p" }
}
foreach ($needed in @($Godot, $OriginalPack, (Join-Path $root 'patch'), (Join-Path $root 'patch_gdc'), (Join-Path $root 'mpml\overtime\main.gd'), (Join-Path $root 'mpml\overtime\mod.json'), (Join-Path $root 'tools\probe\build_mpml_mod.gd'))) {
    if (-not (Test-Path -LiteralPath $needed)) { throw "Missing build input: $needed" }
}
if ((Test-Path -LiteralPath $Out) -and -not (Test-Path -LiteralPath $Out -PathType Container)) { throw 'Out must name a package directory' }
Assert-UnlinkedPath $Out
Assert-UnlinkedPath (Join-Path $parent '.mpml-build.lock')
if (Test-Path -LiteralPath $Out) {
    if ((Get-Item -LiteralPath $Out).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Out must not be a linked directory' }
    $existing = @(Get-ChildItem -LiteralPath $Out -Force)
    $ownedNames = @('main.gd','mod.json','vanilla_md5.json','overtime_overlay.zip','BUILDINFO.json')
    if (@($existing | Where-Object { $_.PSIsContainer -or $_.Name -notin $ownedNames -or ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }).Count) { throw 'Refusing to replace a directory containing non-package files' }
    if ($existing.Count) {
        $existingMod = Get-Content -LiteralPath (Join-Path $Out 'mod.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($existingMod.id -ne 'overtime') { throw 'Output directory does not belong to Overtime' }
    }
}

function Hash-File([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Quote-Argument([string]$Value) { '"' + $Value + '"' }
function Remove-OwnedTree([string]$Path) {
    $absolute = [IO.Path]::GetFullPath($Path)
    if (-not $absolute.StartsWith($parent + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing cleanup outside output parent: $absolute" }
    if (Test-Path -LiteralPath $absolute) { Remove-Item -LiteralPath $absolute -Recurse -Force }
}
$sources = @(Get-ChildItem -LiteralPath (Join-Path $root 'patch') -Recurse -File -Filter '*.gd' | Sort-Object FullName)
if (-not $sources.Count) { throw 'No patch sources' }
if (@($sources | Group-Object BaseName | Where-Object Count -gt 1).Count) { throw 'Duplicate flat bytecode basenames' }
$inputs = [ordered]@{}
$records = @()
foreach ($source in $sources) {
    $compiled = Join-Path $root ('patch_gdc\' + $source.BaseName + '.gdc')
    if (-not (Test-Path -LiteralPath $compiled)) { throw "Missing compiled script: $compiled" }
    if ((Get-Item -LiteralPath $compiled).LastWriteTimeUtc -lt $source.LastWriteTimeUtc) { throw "Stale compiled script: $($source.Name). Run build.ps1 -CompileOnly." }
    if ((Get-Item -LiteralPath $compiled).Length -eq 0) { throw "Empty compiled script: $compiled" }
    $inputs[$source.FullName] = Hash-File $source.FullName
    $inputs[$compiled] = Hash-File $compiled
    $relative = $source.FullName.Substring((Join-Path $root 'patch').Length + 1).Replace('\','/')
    $records += [ordered]@{path=$relative; source_sha256=$inputs[$source.FullName]; bytecode_sha256=$inputs[$compiled]}
}
foreach ($inputPath in @($OriginalPack, (Join-Path $root 'mpml\overtime\main.gd'), (Join-Path $root 'mpml\overtime\mod.json'), (Join-Path $root 'tools\probe\build_mpml_mod.gd'))) { $inputs[$inputPath] = Hash-File $inputPath }
$network = Get-Content -LiteralPath (Join-Path $root 'patch\modules\multiplayer\network_manager.gd') -Raw -Encoding UTF8
$match = [regex]::Match($network, 'const MP8_VERSION_TAG:\s*String\s*=\s*"overtime-([A-Za-z0-9.-]+)"')
if (-not $match.Success) { throw 'Cannot read safe version tag' }
$version = $match.Groups[1].Value
$mod = Get-Content -LiteralPath (Join-Path $root 'mpml\overtime\mod.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$declared = [string]$mod.version
$normalized = $declared -replace '^(\d+\.\d+)\.0(?=-|$)', '$1'
if ($normalized -ne $version -or $mod.id -ne 'overtime') { throw 'mod.json identity/version does not match compiled-source tag' }
New-Item -ItemType Directory -Path $parent -Force | Out-Null
$lock = [IO.File]::Open((Join-Path $parent '.mpml-build.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$id = [guid]::NewGuid().ToString('N')
$stage = Join-Path $parent ('.mpml-stage-' + $id)
$stagedPackage = Join-Path $stage 'overtime'
$zipName = 'Machine-Party-Overtime-' + $version + '-MPML.zip'
$stagedZip = Join-Path $stage $zipName
$finalZip = Join-Path $parent $zipName
$backupOut = Join-Path $parent ('.mpml-old-package-' + $id)
$backupZip = Join-Path $parent ('.mpml-old-archive-' + $id)
$oldOut = $false; $oldZip = $false; $newOut = $false; $newZip = $false; $published = $false
try {
    # -Out names the mod directory; its archive is a sibling. Do not replace a
    # same-named sibling unless every archived file matches this existing Out.
    if (Test-Path -LiteralPath $finalZip) {
        Assert-UnlinkedPath $finalZip
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($finalZip)
        try {
            $files = @($zip.Entries | Where-Object { -not $_.FullName.EndsWith('/') })
            $expected = @('main.gd','mod.json','vanilla_md5.json','overtime_overlay.zip','BUILDINFO.json')
            if ($files.Count -ne $expected.Count -or @($files.FullName | Select-Object -Unique).Count -ne $expected.Count) { throw 'Unowned sibling MPML archive' }
            foreach ($entry in $files) {
                $name = $entry.FullName -replace '^overtime/', ''
                $local = Join-Path $Out $name
                if (-not $entry.FullName.StartsWith('overtime/') -or $name -notin $expected -or -not (Test-Path -LiteralPath $local -PathType Leaf)) { throw 'Unowned sibling MPML archive' }
                $sha = [Security.Cryptography.SHA256]::Create()
                $stream = $entry.Open()
                try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') } finally { $stream.Dispose(); $sha.Dispose() }
                if ($hash -ne (Hash-File $local)) { throw 'Sibling MPML archive does not match the selected output directory; use a new output parent' }
            }
        } finally { $zip.Dispose() }
    }
    New-Item -ItemType Directory -Path $stagedPackage -Force | Out-Null
    $stdout = Join-Path $stage 'godot.stdout.txt'; $stderr = Join-Path $stage 'godot.stderr.txt'
    $arguments = @('--headless','--path',(Quote-Argument (Join-Path $root 'tools\probe')),'--script','build_mpml_mod.gd','--','--mp8-root',(Quote-Argument $root),'--mp8-output',(Quote-Argument $stagedPackage),'--mp8-original',(Quote-Argument $OriginalPack))
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'MPML Godot packaging timed out' }
    if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $stderr -Pattern 'SCRIPT ERROR|ERROR:' -Quiet)) {
        Get-Content -LiteralPath $stdout -Encoding UTF8
        Get-Content -LiteralPath $stderr -Encoding UTF8
        throw "MPML Godot packaging failed (exit $($process.ExitCode))"
    }
    foreach ($name in @('main.gd','mod.json','vanilla_md5.json','overtime_overlay.zip')) {
        if (-not (Test-Path -LiteralPath (Join-Path $stagedPackage $name) -PathType Leaf)) { throw "Missing staged output: $name" }
    }
    foreach ($path in $inputs.Keys) {
        if (-not (Test-Path -LiteralPath $path) -or (Hash-File $path) -ne $inputs[$path]) { throw "Build input changed during packaging: $path" }
    }
    $manifest = Get-Content -LiteralPath (Join-Path $stagedPackage 'vanilla_md5.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $overlay = Join-Path $stagedPackage 'overtime_overlay.zip'
    if ($manifest.schema -ne 1 -or $manifest.game_version -ne ('overtime-' + $version) -or $manifest.overlay_size -ne (Get-Item -LiteralPath $overlay).Length -or $manifest.overlay_sha256 -ne (Hash-File $overlay)) { throw 'Staged overlay integrity metadata does not match' }
    if (@($manifest.files.PSObject.Properties).Count -ne $sources.Count) { throw 'Staged original-file manifest has wrong count' }
    $info = [ordered]@{
        schema=1; mod_tag=('overtime-' + $version); built_utc=[DateTime]::UtcNow.ToString('o')
        original_pack_sha256=$inputs[$OriginalPack]; files=$records
        verification_note='Source/bytecode hashes and freshness checks record these inputs; they do not prove how bytecode was compiled.'
    }
    [IO.File]::WriteAllText((Join-Path $stagedPackage 'BUILDINFO.json'), ($info | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
    Compress-Archive -LiteralPath $stagedPackage -DestinationPath $stagedZip
    # Both outputs are complete before either existing output is touched.
    if (Test-Path -LiteralPath $Out) { Move-Item -LiteralPath $Out -Destination $backupOut; $oldOut=$true }
    if (Test-Path -LiteralPath $finalZip) { Move-Item -LiteralPath $finalZip -Destination $backupZip; $oldZip=$true }
    Move-Item -LiteralPath $stagedPackage -Destination $Out; $newOut=$true
    Move-Item -LiteralPath $stagedZip -Destination $finalZip; $newZip=$true
    $published=$true
    Write-Host "MPML package: $Out"
    Write-Host "MPML archive: $finalZip"
} catch {
    if (-not $published) {
        if ($newZip -and (Test-Path -LiteralPath $finalZip)) { Remove-Item -LiteralPath $finalZip -Force }
        if ($newOut) { Remove-OwnedTree $Out }
        if ($oldOut) { Move-Item -LiteralPath $backupOut -Destination $Out }
        if ($oldZip) { Move-Item -LiteralPath $backupZip -Destination $finalZip }
    }
    throw
} finally {
    if ($published) {
        if ($oldOut) { Remove-OwnedTree $backupOut }
        if ($oldZip -and (Test-Path -LiteralPath $backupZip)) { Remove-Item -LiteralPath $backupZip -Force }
    }
    Remove-OwnedTree $stage
    $lock.Dispose()
}
