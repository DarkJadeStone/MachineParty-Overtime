param([string]$Out = '')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$imageRoot = if (Test-Path -LiteralPath (Join-Path $root 'release/images/03_smoke_break_bench.png')) { Join-Path $root 'release/images' } else { Join-Path $root 'images' }
if (-not $Out) { $Out = $imageRoot }
$Out = [IO.Path]::GetFullPath($Out)
New-Item -ItemType Directory -Path $Out -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
$culture = [Globalization.CultureInfo]::InvariantCulture
$shotPath = Join-Path $imageRoot '03_smoke_break_bench.png'
$shot = 'data:image/png;base64,' + [Convert]::ToBase64String([IO.File]::ReadAllBytes($shotPath))

# Native vector lettering: outline installed fonts so SVG appearance does not
# depend on fonts installed on a visitor's computer. Screenshot bytes stay intact.
function Vector-Text([string]$Text, [string]$Family, [float]$Size, [float]$X, [float]$Y, [string]$Fill, [float]$MaxWidth = 0) {
    $font = [Drawing.FontFamily]::new($Family)
    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    try {
        $path.AddString($Text, $font, 0, $Size, [Drawing.PointF]::new($X,$Y), [Drawing.StringFormat]::GenericTypographic)
        if ($MaxWidth -gt 0 -and $path.GetBounds().Width -gt $MaxWidth) {
            $scale = $MaxWidth / $path.GetBounds().Width
            $path.Reset()
            $path.AddString($Text, $font, 0, ($Size * $scale), [Drawing.PointF]::new($X,$Y), [Drawing.StringFormat]::GenericTypographic)
        }
        $p = $path.PathPoints; $t = $path.PathTypes
        $d = [Text.StringBuilder]::new()
        for ($i=0; $i -lt $p.Count; $i++) {
            $type = $t[$i] -band 7
            if ($type -eq 0 -or $type -eq 1) {
                $letter = if ($type -eq 0) {'M'} else {'L'}
                [void]$d.AppendFormat($culture,'{0}{1:0.###},{2:0.###}',$letter,$p[$i].X,$p[$i].Y)
            } elseif ($type -eq 3) {
                [void]$d.AppendFormat($culture,'C{0:0.###},{1:0.###} {2:0.###},{3:0.###} {4:0.###},{5:0.###}',$p[$i].X,$p[$i].Y,$p[$i+1].X,$p[$i+1].Y,$p[$i+2].X,$p[$i+2].Y)
                $i += 2
            } else { throw 'Unexpected glyph path type' }
            if ($t[$i] -band 128) { [void]$d.Append('Z') }
        }
        '<path fill="' + $Fill + '" fill-rule="evenodd" d="' + $d.ToString() + '"/>'
    } finally { $path.Dispose(); $font.Dispose() }
}
function Write-Svg([string]$Name, [int]$Width, [int]$Height, [string]$Title, [string]$Body) {
    $safeTitle = [Security.SecurityElement]::Escape($Title)
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="$Width" height="$Height" viewBox="0 0 $Width $Height" role="img" aria-label="$safeTitle">
<title>$safeTitle</title>
$Body
</svg>
"@
    [IO.File]::WriteAllText((Join-Path $Out $Name), $svg, $utf8)
}
foreach ($lang in @('zh','en')) {
    $parts = [Collections.Generic.List[string]]::new()
    $parts.Add('<defs><linearGradient id="shade"><stop offset="0" stop-color="#111713" stop-opacity=".99"/><stop offset=".44" stop-color="#111713" stop-opacity=".94"/><stop offset="1" stop-color="#111713" stop-opacity=".20"/></linearGradient></defs>')
    $parts.Add('<rect width="1600" height="520" fill="#111713"/>')
    $parts.Add('<image width="1600" height="520" preserveAspectRatio="xMidYMid slice" xlink:href="' + $shot + '"/>')
    $parts.Add('<rect width="1600" height="520" fill="url(#shade)"/>')
    $parts.Add('<path d="M72 55H210M72 55V73" stroke="#4DFF6A" stroke-width="3" fill="none"/>')
    $parts.Add((Vector-Text 'MACHINE PARTY / COMMUNITY MOD' 'Consolas' 25 72 81 '#4DFF6A' 850))
    $parts.Add((Vector-Text 'OVERTIME' 'Impact' 153 65 121 '#F1F2E9' 910))
    if ($lang -eq 'zh') {
        $parts.Add((Vector-Text '人数翻倍，工位满员。' 'Microsoft YaHei' 47 74 302 '#F1F2E9' 860))
        $parts.Add((Vector-Text '免费 · 开源 · 需要正版游戏' 'Microsoft YaHei' 25 267 410 '#CBD2C7' 640))
        $title = 'Machine Party Overtime 1.7 — 人数翻倍，工位满员。4 人扩展为 8 人，免费开源。'
    } else {
        $parts.Add((Vector-Text 'DOUBLE THE PLAYERS. FILL THE FLOOR.' 'Consolas' 33 74 313 '#F1F2E9' 900))
        $parts.Add((Vector-Text 'FREE / OPEN SOURCE / LEGITIMATE COPY REQUIRED' 'Consolas' 21 267 419 '#CBD2C7' 790))
        $title = 'Machine Party Overtime 1.7 — Double the players. Fill the floor. Free and open source.'
    }
    $parts.Add((Vector-Text '4 → 8' 'Consolas' 47 72 395 '#4DFF6A' 162))
    $parts.Add('<path d="M240 407V451" stroke="#697C6E" stroke-width="2"/>')
    $parts.Add('<rect x="1434" y="62" width="108" height="49" fill="#111713" stroke="#748777"/>')
    $parts.Add((Vector-Text 'V1.7' 'Consolas' 26 1457 68 '#E5B65B' 80))
    $parts.Add('<rect y="513" width="1600" height="7" fill="#4DFF6A"/>')
    Write-Svg "overtime-banner-$lang.svg" 1600 520 $title ($parts -join "`n")
    $label = if ($lang -eq 'zh') {'下载 1.7'} else {'DOWNLOAD 1.7'}
    $family = if ($lang -eq 'zh') {'Microsoft YaHei'} else {'Consolas'}
    $textX = if ($lang -eq 'zh') {72} else {53}
    $body = '<rect width="260" height="58" rx="3" fill="#4DFF6A"/><path d="M27 15V34M19 27L27 35L35 27M16 40H38" fill="none" stroke="#111713" stroke-width="2.5" stroke-linecap="square"/>'
    $body += Vector-Text $label $family 25 $textX 11 '#111713' 188
    Write-Svg "download-$lang.svg" 260 58 $label $body
}
$social = [Collections.Generic.List[string]]::new()
$social.Add('<defs><linearGradient id="shade"><stop offset="0" stop-color="#111713" stop-opacity=".99"/><stop offset=".48" stop-color="#111713" stop-opacity=".88"/><stop offset="1" stop-color="#111713" stop-opacity=".25"/></linearGradient></defs>')
$social.Add('<rect width="1280" height="640" fill="#111713"/><image width="1280" height="640" preserveAspectRatio="xMidYMid slice" xlink:href="' + $shot + '"/><rect width="1280" height="640" fill="url(#shade)"/>')
$social.Add((Vector-Text 'MACHINE PARTY / COMMUNITY MOD' 'Consolas' 23 62 67 '#4DFF6A' 900))
$social.Add((Vector-Text 'OVERTIME' 'Impact' 157 55 153 '#F1F2E9' 1000))
$social.Add((Vector-Text '人数翻倍，工位满员。' 'Microsoft YaHei' 48 64 349 '#F1F2E9' 950))
$social.Add((Vector-Text '4 → 8' 'Consolas' 53 62 469 '#4DFF6A' 185))
$social.Add((Vector-Text 'FREE & OPEN SOURCE' 'Consolas' 24 280 490 '#CBD2C7' 680))
$social.Add((Vector-Text '1.7' 'Impact' 39 1133 477 '#E5B65B' 95))
$social.Add('<rect y="630" width="1280" height="10" fill="#4DFF6A"/>')
Write-Svg 'social-preview-1.7.svg' 1280 640 'Machine Party Overtime 1.7 — 人数翻倍，工位满员。' ($social -join "`n")
Write-Host "Vector branding prepared: $Out"
