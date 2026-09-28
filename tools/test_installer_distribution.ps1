param([Parameter(Mandatory=$true)][string]$Directory, [string]$MpmlDirectory = '')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$directoryPath = (Resolve-Path -LiteralPath $Directory).Path
foreach ($name in @('overtime_launcher.exe', 'overtime_install.exe', 'overtime_payload.zip', 'BUILDINFO.json', 'SHA256SUMS.txt', 'README.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $directoryPath $name))) { throw "Distribution missing: $name" }
}
$info = Get-Content -LiteralPath (Join-Path $directoryPath 'BUILDINFO.json') -Raw | ConvertFrom-Json
if ($info.format -ne 1 -or -not $info.runtimeKey -or -not $info.modTag) { throw 'Invalid BUILDINFO.json' }
if (@($info.artifacts).Count -ne 3 -or @($info.artifacts.name | Select-Object -Unique).Count -ne 3) { throw 'Artifact list must contain the three distinct build artifacts' }
$checksums = @(Get-Content -LiteralPath (Join-Path $directoryPath 'SHA256SUMS.txt') -Encoding UTF8)
if ($checksums.Count -ne 3) { throw 'Checksum file has wrong number of entries' }
foreach ($artifact in $info.artifacts) {
    if ($artifact.name -notin @('overtime_launcher.exe','overtime_install.exe','overtime_payload.zip')) { throw 'Unexpected artifact in build information' }
    $actual = (Get-FileHash -LiteralPath (Join-Path $directoryPath $artifact.name) -Algorithm SHA256).Hash
    if ($actual -ne $artifact.sha256) { throw "Build information hash mismatch: $($artifact.name)" }
    if ($checksums -notcontains "$actual  $($artifact.name)") { throw "Checksum record missing/wrong: $($artifact.name)" }
}
$payload = [IO.Compression.ZipFile]::OpenRead((Join-Path $directoryPath 'overtime_payload.zip'))
try {
    $manifestEntry = $payload.GetEntry('manifest.txt')
    if (-not $manifestEntry) { throw 'Payload manifest missing' }
    $reader = [IO.StreamReader]::new($manifestEntry.Open(), [Text.Encoding]::UTF8)
    try { $manifest = $reader.ReadToEnd() } finally { $reader.Dispose() }
    if (-not $manifest.StartsWith("OVERTIME-PAYLOAD`t1`n")) { throw 'Wrong payload format' }
    if (($manifest -split "`n") -notcontains "mod_tag`t$($info.modTag)") { throw 'Payload and build information versions differ' }
    $fileRows = @($manifest -split "`n" | Where-Object { $_.StartsWith("file`t") })
    if ($fileRows.Count -ne $info.scriptCount -or $payload.Entries.Count -ne $fileRows.Count + 1) { throw 'Payload entry count mismatch' }
    foreach ($row in $fileRows) {
        $fields = $row -split "`t"
        if ($fields.Count -ne 5) { throw 'Invalid file row' }
        $entry = $payload.GetEntry($fields[2])
        if (-not $entry -or $entry.Length -ne [long]$fields[3]) { throw "Entry missing/wrong size: $($fields[2])" }
        $stream = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $actual = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
        finally { $sha.Dispose(); $stream.Dispose() }
        if ($actual -ne $fields[4]) { throw "Entry hash mismatch: $($fields[2])" }
    }
} finally { $payload.Dispose() }
foreach ($archive in @(@{Name=$info.playerArchive;Exe='overtime_launcher.exe'},@{Name=$info.consoleArchive;Exe='overtime_install.exe'})) {
    $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $directoryPath $archive.Name))
    try {
        $expected = @('BUILDINFO.json','README.md','SHA256SUMS.txt',$archive.Exe,'overtime_payload.zip') | Sort-Object
        $actual = @($zip.Entries | ForEach-Object FullName) | Sort-Object
        if (@(Compare-Object $expected $actual).Count -ne 0) { throw "Archive has missing or extra files: $($archive.Name)" }
        foreach ($entry in $zip.Entries) {
            $stream = $entry.Open()
            $sha = [Security.Cryptography.SHA256]::Create()
            try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
            finally { $sha.Dispose(); $stream.Dispose() }
            if ($hash -ne (Get-FileHash -LiteralPath (Join-Path $directoryPath $entry.FullName)).Hash) { throw "Archived content differs: $($entry.FullName)" }
        }
    } finally { $zip.Dispose() }
}
if ($MpmlDirectory) {
    $overlay = [IO.Compression.ZipFile]::OpenRead((Join-Path $MpmlDirectory 'overtime_overlay.zip'))
    try {
        # Godot adds zero-length directory entries; compare actual resources.
        $resources = @($overlay.Entries | Where-Object { -not $_.FullName.EndsWith('/') })
        if ($resources.Count -ne $fileRows.Count) { throw 'MPML resource count differs from installer' }
        foreach ($row in $fileRows) {
            $fields = $row -split "`t"
            $entry = $overlay.GetEntry($fields[1].Substring(6))
            if (-not $entry -or $entry.Length -ne [long]$fields[3]) { throw "MPML resource missing/wrong size: $($fields[1])" }
            $stream = $entry.Open()
            $sha = [Security.Cryptography.SHA256]::Create()
            try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
            finally { $sha.Dispose(); $stream.Dispose() }
            if ($hash -ne $fields[4]) { throw "MPML bytecode differs: $($fields[1])" }
        }
        Write-Host "PASS installer/MPML parity: $($resources.Count) identical script resources"
    } finally { $overlay.Dispose() }
}
$verifyOutput = & (Join-Path $directoryPath 'overtime_install.exe') --verify-package 2>&1
if ($LASTEXITCODE -ne 0) { throw "Runtime rejected payload: $verifyOutput" }
$verifyOutput
Write-Host "PASS distribution: $($info.modTag), $($info.scriptCount) scripts, runtime $($info.runtimeKey)"
