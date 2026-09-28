# Stable offline executables + a transparent external patch ZIP.
# Mod version and script bytes are not inputs to the executable compiler.
param([string]$Out = '', [switch]$ForceRebuild, [string]$RepositoryRoot = '')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = if ($RepositoryRoot) { [IO.Path]::GetFullPath($RepositoryRoot) } else { Split-Path -Parent $PSScriptRoot }
$patchRoot = Join-Path $root 'patch'
$gdcRoot = Join-Path $root 'patch_gdc'
$sourcePath = Join-Path $root 'installer/Installer.cs'
$appManifest = Join-Path $root 'installer/app.manifest'
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$framework = Split-Path -Parent $compiler
$utf8 = [Text.UTF8Encoding]::new($false)
foreach ($needed in @($patchRoot,$gdcRoot,$sourcePath,$appManifest,$compiler)) {
    if (-not (Test-Path -LiteralPath $needed)) { throw "Missing build input: $needed" }
}
function Hash-Bytes([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-','') } finally { $sha.Dispose() }
}
function Read-Constant([string]$Text, [string]$Name) {
    $match = [regex]::Match($Text, '\b' + [regex]::Escape($Name) + '\s*=\s*"([^"]+)"')
    if (-not $match.Success) { throw "Missing string constant $Name" }
    $match.Groups[1].Value
}
function Remove-BuildStage([string]$Path, [string]$Parent) {
    $resolved = [IO.Path]::GetFullPath($Path)
    $boundary = [IO.Path]::GetFullPath($Parent).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notlike '.build-*') { throw "Refusing cleanup: $resolved" }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
function Write-Zip([string]$Path, $Entries) {
    $file = [IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {
        $zip = [IO.Compression.ZipArchive]::new($file,[IO.Compression.ZipArchiveMode]::Create,$true)
        try {
            foreach ($item in $Entries) {
                $entry = $zip.CreateEntry($item.Name,[IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = [DateTimeOffset]::new(2000,1,1,0,0,0,[TimeSpan]::Zero)
                $stream = $entry.Open()
                try { $stream.Write($item.Bytes,0,$item.Bytes.Length) } finally { $stream.Dispose() }
            }
        } finally { $zip.Dispose() }
    } finally { $file.Dispose() }
}
$sourceBytes = [IO.File]::ReadAllBytes($sourcePath)
$code = $utf8.GetString($sourceBytes).TrimStart([char]0xFEFF)
$networkSource = [IO.File]::ReadAllText((Join-Path $patchRoot 'modules/multiplayer/network_manager.gd'))
$tagMatch = [regex]::Match($networkSource, 'MP8_VERSION_TAG\s*:\s*String\s*=\s*"([^"]+)"')
if (-not $tagMatch.Success) { throw 'Missing MP8_VERSION_TAG' }
$modTag = $tagMatch.Groups[1].Value
if ($modTag -notmatch '^overtime-[0-9]+\.[0-9]+(?:\.[0-9]+)?(?:-[a-z0-9][a-z0-9.-]*)?$') { throw 'Unsafe Mod tag' }
$modVersion = $modTag.Substring('overtime-'.Length)
$runtimeVersion = Read-Constant $code 'ReleaseNum'
if ($runtimeVersion -notmatch '^[0-9]+\.[0-9]+(?:\.[0-9]+)?(?:-[a-z0-9][a-z0-9.-]*)?$') { throw 'Unsafe installer version' }
$gameVersion = Read-Constant $code 'GameVersion'
$vanillaHash = Read-Constant $code 'VanillaSha'
$sizeMatch = [regex]::Match($code, '\bVanillaSize\s*=\s*([0-9]+)L')
if (-not $sizeMatch.Success) { throw 'Missing VanillaSize' }
$vanillaSize = $sizeMatch.Groups[1].Value
if ([string]::IsNullOrWhiteSpace($Out)) { $Out = Join-Path $root "dist/overtime-$modVersion-launcher-$runtimeVersion" }
$outDir = [IO.Path]::GetFullPath($Out)
foreach ($protected in @($root, $patchRoot, $gdcRoot, (Join-Path $root 'src'), (Join-Path $root 'installer'), (Join-Path $root 'tools'), (Join-Path $root 'mpml'), (Join-Path $root 'game_test'))) {
    $boundary = [IO.Path]::GetFullPath($protected).TrimEnd('\','/')
    if ($outDir.TrimEnd('\','/') -eq $boundary -or $boundary.StartsWith($outDir.TrimEnd('\','/') + '\',[StringComparison]::OrdinalIgnoreCase) -or ($protected -ne $root -and $outDir.StartsWith($boundary + '\',[StringComparison]::OrdinalIgnoreCase))) { throw "Unsafe output directory: $outDir" }
}
$playerArchive = "Machine-Party-Overtime-$modVersion.zip"
$consoleArchive = "Machine-Party-Overtime-$modVersion-CLI.zip"
$outputNames = @('overtime_launcher.exe','overtime_install.exe','overtime_payload.zip','BUILDINFO.json','SHA256SUMS.txt','README.md',$playerArchive,$consoleArchive)
function Assert-PlainDirectory([string]$Path) {
    $probe = [IO.Path]::GetFullPath($Path)
    while (-not (Test-Path -LiteralPath $probe)) { $probe = Split-Path -Parent $probe }
    $node = Get-Item -LiteralPath $probe
    while ($null -ne $node) {
        if ($node.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point in output path: $($node.FullName)" }
        $node = $node.Parent
    }
}
function Assert-OutputOwnership {
    Assert-PlainDirectory $outDir
    if (-not (Test-Path -LiteralPath $outDir)) { return }
    if (-not (Test-Path -LiteralPath $outDir -PathType Container)) { throw 'Out must be a directory' }
    $lockPath = Join-Path $outDir '.installer-build.lock'
    if ((Test-Path -LiteralPath $lockPath) -and ((Get-Item -LiteralPath $lockPath).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Linked build lock' }
    $items = @(Get-ChildItem -LiteralPath $outDir -Force | Where-Object Name -ne '.installer-build.lock')
    foreach ($item in $items) {
        if ($item.PSIsContainer -or $item.Name -notin $outputNames -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Unowned output item: $($item.FullName)" }
    }
    if ($items.Count -eq 0) { return }
    $existing = Get-Content -LiteralPath (Join-Path $outDir 'BUILDINFO.json') -Raw | ConvertFrom-Json
    if ($existing.format -ne 1 -or $existing.modTag -ne $modTag -or $existing.playerArchive -ne $playerArchive -or $existing.consoleArchive -ne $consoleArchive -or @($existing.artifacts).Count -ne 3) { throw 'Output is not a matching installer candidate directory' }
    foreach ($record in $existing.artifacts) {
        if ($record.name -notin @('overtime_launcher.exe','overtime_install.exe','overtime_payload.zip') -or (Get-FileHash -LiteralPath (Join-Path $outDir $record.name)).Hash -ne $record.sha256) { throw 'Existing output differs from its build record; use a new -Out directory' }
    }
}
Assert-OutputOwnership
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outLock = [IO.File]::Open((Join-Path $outDir '.installer-build.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$cacheLock = $null
$stage = Join-Path $outDir ('.build-' + [guid]::NewGuid().ToString('N'))
try {
    Assert-OutputOwnership
    New-Item -ItemType Directory -Path $stage | Out-Null
    Write-Host "[1/5] Verify compiled inputs: $modTag / installer $runtimeVersion"
    $sources = @(Get-ChildItem -LiteralPath $patchRoot -Recurse -Filter '*.gd' -File | Sort-Object FullName)
    if ($sources.Count -lt 1 -or $sources.Count -gt 256) { throw 'Patch count outside limits' }
    if (@($sources | Group-Object BaseName | Where-Object Count -gt 1).Count) { throw 'Duplicate compiled script basename' }
    $manifest = [Collections.Generic.List[string]]::new()
    foreach ($line in @("OVERTIME-PAYLOAD`t1","mod_tag`t$modTag","game_version`t$gameVersion","vanilla_sha256`t$vanillaHash","vanilla_size`t$vanillaSize")) { $manifest.Add($line) }
    $payloadEntries = [Collections.Generic.List[object]]::new()
    $sourceRecords = [Collections.Generic.List[object]]::new()
    $total = 0L
    for ($i=0; $i -lt $sources.Count; $i++) {
        $source = $sources[$i]
        $compiledPath = Join-Path $gdcRoot ($source.BaseName + '.gdc')
        if (-not (Test-Path -LiteralPath $compiledPath)) { throw "Missing bytecode: $compiledPath" }
        if ((Get-Item -LiteralPath $compiledPath).LastWriteTimeUtc -lt $source.LastWriteTimeUtc) { throw "Stale bytecode; run build.ps1 -CompileOnly: $($source.Name)" }
        $bytes = [IO.File]::ReadAllBytes($compiledPath)
        if ($bytes.Length -eq 0 -or $bytes.Length -gt 4MB) { throw "Script size outside limits: $($source.Name)" }
        $total += $bytes.Length
        if ($total -gt 32MB) { throw 'Payload exceeds limit' }
        $relative = $source.FullName.Substring($patchRoot.Length + 1).Replace('\','/')
        $target = 'res://' + $relative.Substring(0,$relative.Length-3) + '.gdc'
        $entryName = 'scripts/{0:D3}.gdc' -f $i
        $hash = Hash-Bytes $bytes
        $manifest.Add("file`t$target`t$entryName`t$($bytes.Length)`t$hash")
        $payloadEntries.Add([pscustomobject]@{Name=$entryName;Bytes=$bytes})
        $sourceRecords.Add([ordered]@{path=('patch/'+$relative);sha256=(Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash;bytecodeSha256=$hash})
    }
    $manifestBytes = $utf8.GetBytes(($manifest -join "`n") + "`n")
    if ($manifestBytes.Length -gt 128KB) { throw 'Manifest exceeds limit' }
    Write-Zip (Join-Path $stage 'overtime_payload.zip') (@([pscustomobject]@{Name='manifest.txt';Bytes=$manifestBytes}) + @($payloadEntries.ToArray()))
    Write-Host '[2/5] Build or reuse unchanged runtime executables'
    # Compile only immutable snapshots. /noconfig and /nostdlib+ make every
    # reference explicit instead of inheriting mutable csc.rsp defaults.
    $inputDir = Join-Path $stage 'inputs'
    New-Item -ItemType Directory -Path $inputDir | Out-Null
    $runtimeRecords = [Collections.Generic.List[object]]::new()
    $references = @('mscorlib.dll','System.dll','System.Core.dll','System.IO.Compression.dll','System.Drawing.dll','System.Windows.Forms.dll')
    foreach ($path in @($sourcePath,$appManifest) + @($references | ForEach-Object { Join-Path $framework $_ })) {
        $bytes = if ($path -eq $sourcePath) { $sourceBytes } else { [IO.File]::ReadAllBytes($path) }
        $name = Split-Path -Leaf $path
        [IO.File]::WriteAllBytes((Join-Path $inputDir $name), $bytes)
        $runtimeRecords.Add([pscustomobject]@{path=$path;name=$name;sha256=(Hash-Bytes $bytes)})
    }
    foreach ($name in @('csc.exe','csc.exe.config','cscomp.dll')) {
        $path = Join-Path $framework $name
        $hash = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path).Hash } else { 'absent' }
        $runtimeRecords.Add([pscustomobject]@{path=$path;name=$name;sha256=$hash})
    }
    $runtimeNames = @('overtime_launcher.exe','overtime_install.exe')
    $compilerPlans = @()
    foreach ($name in $runtimeNames) {
        $arguments = @('/nologo','/noconfig','/nostdlib+','/platform:anycpu','/optimize+','/codepage:65001','/win32manifest:inputs\app.manifest',('/out:'+$name))
        foreach ($ref in @('mscorlib.dll','System.dll','System.Core.dll','System.IO.Compression.dll')) { $arguments += '/reference:inputs\' + $ref }
        if ($name -eq 'overtime_launcher.exe') { $arguments += @('/target:winexe','/define:GUI','/reference:inputs\System.Drawing.dll','/reference:inputs\System.Windows.Forms.dll') } else { $arguments += '/target:exe' }
        $arguments += 'inputs\Installer.cs'
        $compilerPlans += [pscustomobject]@{name=$name;arguments=$arguments}
    }
    # Hash the actual compiler argv, not a manually maintained description.
    $runtimeInputs = @('overtime-runtime-cache-v2', ($compilerPlans | ConvertTo-Json -Depth 5 -Compress))
    foreach ($record in $runtimeRecords) { $runtimeInputs += $record.name + ':' + $record.sha256 }
    $runtimeKey = Hash-Bytes ($utf8.GetBytes($runtimeInputs -join "`n"))
    $cacheRoot = Join-Path $root 'dist/installer-runtime'
    Assert-PlainDirectory $cacheRoot
    New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
    $cacheLock = [IO.File]::Open((Join-Path $cacheRoot '.runtime-build.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $cacheDir = Join-Path $cacheRoot $runtimeKey
    $cacheIndex = Join-Path $cacheDir 'runtime.json'
    $cacheValid = $false
    if (Test-Path -LiteralPath $cacheIndex) {
        try {
            $cached = Get-Content -LiteralPath $cacheIndex -Raw -Encoding UTF8 | ConvertFrom-Json
            $cacheValid = $cached.key -eq $runtimeKey -and @($cached.files).Count -eq 2 -and @($cached.files.name | Select-Object -Unique).Count -eq 2
            foreach ($record in $cached.files) {
                if ($record.name -notin @('overtime_launcher.exe','overtime_install.exe')) { $cacheValid=$false; break }
                if ((Get-FileHash -LiteralPath (Join-Path $cacheDir $record.name) -Algorithm SHA256).Hash -ne $record.sha256) { $cacheValid=$false; break }
            }
        } catch { $cacheValid = $false }
    }
    if ($cacheValid -and -not $ForceRebuild) {
        foreach ($name in $runtimeNames) { Copy-Item -LiteralPath (Join-Path $cacheDir $name) -Destination (Join-Path $stage $name) }
        Write-Host "      Reused runtime $runtimeKey"
    } else {
        Push-Location $stage
        try {
            foreach ($plan in $compilerPlans) {
                $arguments = $plan.arguments
                $compilerOutput = & $compiler @arguments 2>&1
                if ($LASTEXITCODE -ne 0) { throw "Compiler failed: $compilerOutput" }
                if ($compilerOutput) { $compilerOutput | Write-Host }
                if ((Get-Item -LiteralPath (Join-Path $stage $plan.name)).Length -gt 5MB) { throw 'Unexpected executable size' }
            }
        } finally { Pop-Location }
    }
    Write-Host '[3/5] Verify payload through the actual installer entry point'
    $verifyOutput = & (Join-Path $stage 'overtime_install.exe') --verify-package 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Installer verification failed: $verifyOutput" }
    $verifyOutput | Write-Host
    Write-Host '[4/5] Record hashes and package the candidate'
    # Another development process must not change inputs while this candidate is
    # being assembled. Timestamps reject stale builds; hashes detect this race.
    foreach ($record in $sourceRecords) {
        $currentSource = Join-Path $root $record.path
        $currentCompiled = Join-Path $gdcRoot (([IO.Path]::GetFileNameWithoutExtension($record.path)) + '.gdc')
        if ((Get-FileHash -LiteralPath $currentSource -Algorithm SHA256).Hash -ne $record.sha256 -or (Get-FileHash -LiteralPath $currentCompiled -Algorithm SHA256).Hash -ne $record.bytecodeSha256) { throw "Build input changed: $($record.path)" }
    }
    if ([IO.File]::ReadAllText($sourcePath) -cne $code -or [IO.File]::ReadAllText((Join-Path $patchRoot 'modules/multiplayer/network_manager.gd')) -cne $networkSource) { throw 'Build metadata changed during assembly' }
    foreach ($record in $runtimeRecords) {
        $currentHash = if (Test-Path -LiteralPath $record.path) { (Get-FileHash -LiteralPath $record.path).Hash } else { 'absent' }
        if ($currentHash -ne $record.sha256) { throw "Runtime input changed: $($record.name)" }
    }
    Copy-Item -LiteralPath (Join-Path $root 'installer/README.md') -Destination (Join-Path $stage 'README.md')
    $artifactRecords = @()
    $checksumLines = @()
    foreach ($name in @('overtime_launcher.exe','overtime_install.exe','overtime_payload.zip')) {
        $hash = (Get-FileHash -LiteralPath (Join-Path $stage $name) -Algorithm SHA256).Hash
        $artifactRecords += [ordered]@{name=$name;sha256=$hash}
        $checksumLines += "$hash  $name"
    }
    $sourceCommit = 'unavailable'
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            $gitResult = & git -C $root rev-parse HEAD 2>$null
            if ($LASTEXITCODE -eq 0) { $sourceCommit = [string]$gitResult }
        } catch { $sourceCommit = 'unavailable' }
    }
    $buildInfo = [ordered]@{format=1;modTag=$modTag;installerVersion=$runtimeVersion;gameVersion=$gameVersion;sourceCommit=$sourceCommit;runtimeKey=$runtimeKey;scriptCount=$sources.Count;playerArchive=$playerArchive;consoleArchive=$consoleArchive;artifacts=$artifactRecords;sources=$sourceRecords.ToArray();notes='Content hashes describe this build. Signing and Defender evaluation are separate release checks.'}
    [IO.File]::WriteAllText((Join-Path $stage 'BUILDINFO.json'),($buildInfo | ConvertTo-Json -Depth 6),$utf8)
    [IO.File]::WriteAllText((Join-Path $stage 'SHA256SUMS.txt'),($checksumLines -join "`n") + "`n",$utf8)
    foreach ($archive in @(@{Name=$playerArchive;Exe='overtime_launcher.exe'},@{Name=$consoleArchive;Exe='overtime_install.exe'})) {
        $archiveEntries = @()
        foreach ($name in @($archive.Exe,'overtime_payload.zip','README.md','BUILDINFO.json','SHA256SUMS.txt') | Sort-Object) { $archiveEntries += [pscustomobject]@{Name=$name;Bytes=[IO.File]::ReadAllBytes((Join-Path $stage $name))} }
        Write-Zip (Join-Path $stage $archive.Name) $archiveEntries
    }
    # Publish the cache only after all input checks and package assembly pass.
    # A forced rebuild does not replace an already verified canonical runtime.
    if (-not $cacheValid) {
        $cacheStage = Join-Path $stage 'runtime-cache'
        New-Item -ItemType Directory -Path $cacheStage | Out-Null
        $cacheRecords = @()
        foreach ($name in $runtimeNames) {
            Copy-Item -LiteralPath (Join-Path $stage $name) -Destination (Join-Path $cacheStage $name)
            $cacheRecords += [ordered]@{name=$name;sha256=(Get-FileHash -LiteralPath (Join-Path $cacheStage $name)).Hash}
        }
        [IO.File]::WriteAllText((Join-Path $cacheStage 'runtime.json'),([ordered]@{key=$runtimeKey;files=$cacheRecords;compilerPlans=$compilerPlans;inputs=@($runtimeRecords | Select-Object name,sha256)} | ConvertTo-Json -Depth 6),$utf8)
        if (Test-Path -LiteralPath $cacheDir) {
            $resolved = [IO.Path]::GetFullPath($cacheDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($cacheRoot).TrimEnd('\') + '\',[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notmatch '^[A-F0-9]{64}$' -or ((Get-Item -LiteralPath $resolved).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe runtime cache path' }
            Move-Item -LiteralPath $resolved -Destination ($resolved + '.rejected-' + [guid]::NewGuid().ToString('N'))
        }
        Move-Item -LiteralPath $cacheStage -Destination $cacheDir
    }
    Write-Host '[5/5] Publish candidate files locally'
    foreach ($item in Get-ChildItem -LiteralPath $stage -File) { Move-Item -LiteralPath $item.FullName -Destination (Join-Path $outDir $item.Name) -Force }
    Write-Host "Candidate: $outDir"
    Write-Host "Player archive: $playerArchive (keep payload beside the exe)"
    Write-Host 'Defender detection reduction has not been established by this build.'
} finally {
    if ($null -ne $cacheLock) { $cacheLock.Dispose() }
    $outLock.Dispose()
    Remove-BuildStage $stage $outDir
}
