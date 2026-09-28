param([switch]$KeepArtifacts)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$taskTestDir = Join-Path $taskTempRoot ('overtime-payload-test-' + [Guid]::NewGuid().ToString('N'))
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
New-Item -ItemType Directory -Path $taskTestDir | Out-Null
try {
    $testExe = Join-Path $taskTestDir 'PayloadTests.exe'
    & $compiler /nologo /target:exe /main:PayloadTests /codepage:65001 /reference:System.dll /reference:System.Core.dll /reference:System.IO.Compression.dll "/out:$testExe" (Join-Path $taskRoot 'installer\Installer.cs') (Join-Path $taskRoot 'installer\tests\PayloadTests.cs')
    if ($LASTEXITCODE -ne 0) { throw 'Payload test compilation failed.' }
    & $testExe
    if ($LASTEXITCODE -ne 0) { throw 'Payload tests failed.' }
    $guiTestExe = Join-Path $taskTestDir 'GuiPayloadTests.exe'
    & $compiler /nologo /target:exe /define:GUI /main:GuiPayloadTests /codepage:65001 /reference:System.dll /reference:System.Core.dll /reference:System.IO.Compression.dll /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "/win32manifest:$(Join-Path $taskRoot 'installer\app.manifest')" "/out:$guiTestExe" (Join-Path $taskRoot 'installer\Installer.cs') (Join-Path $taskRoot 'installer\tests\GuiPayloadTests.cs')
    if ($LASTEXITCODE -ne 0) { throw 'GUI test compilation failed.' }
    # The core test leaves its last fixture payload deleted; GUI must also start without it.
    $fixturePayload = Join-Path $taskTestDir 'overtime_payload.zip'
    if (Test-Path -LiteralPath $fixturePayload) { Remove-Item -LiteralPath $fixturePayload -Force }
    & $guiTestExe
    if ($LASTEXITCODE -ne 0) { throw 'GUI payload tests failed.' }
} finally {
    if ($KeepArtifacts) { Write-Host "Test artifacts: $taskTestDir" }
    else {
        $taskResolved = [IO.Path]::GetFullPath($taskTestDir)
        if (-not $taskResolved.StartsWith($taskTempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $taskResolved) -notlike 'overtime-payload-test-*') { throw 'Refusing to remove unexpected test path.' }
        Remove-Item -LiteralPath $taskResolved -Recurse -Force
    }
}
