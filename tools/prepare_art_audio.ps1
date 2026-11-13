param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
# Deterministic production resizing/cropping only. Original illustrations generated with imagegen.
# Source PNGs and complete prompts live in marketing/branding. Never synthesizes replacement art.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = [System.IO.Path]::GetFullPath($ProjectRoot)
$source = Join-Path $root 'marketing/branding'
$outDirs = @('assets/brand', 'assets/badges', 'marketing/achievements', 'marketing/leaderboards')
foreach($dir in $outDirs) { [void][System.IO.Directory]::CreateDirectory((Join-Path $root $dir)) }
$records = [System.Collections.Generic.List[object]]::new()
function Export-Png {
    param([string]$InputName, [string]$RelativeOut, [int]$Width, [int]$Height, [System.Drawing.RectangleF]$Crop = [System.Drawing.RectangleF]::Empty)
    $inputPath = Join-Path $source $InputName
    $outputPath = Join-Path $root $RelativeOut
    $image = [System.Drawing.Image]::FromFile($inputPath)
    try {
        if ($Crop.IsEmpty) {
            $scale = [Math]::Max($Width / $image.Width, $Height / $image.Height)
            $cw = $Width / $scale
            $ch = $Height / $scale
            $Crop = [System.Drawing.RectangleF]::new(($image.Width-$cw)/2,($image.Height-$ch)/2,$cw,$ch)
        }
        $bitmap = [System.Drawing.Bitmap]::new($Width,$Height,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $attrs = [System.Drawing.Imaging.ImageAttributes]::new()
            try {
                $attrs.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
                $dest = [System.Drawing.Rectangle]::new(0,0,$Width,$Height)
                $graphics.DrawImage($image,$dest,$Crop.X,$Crop.Y,$Crop.Width,$Crop.Height,[System.Drawing.GraphicsUnit]::Pixel,$attrs)
                $bitmap.Save($outputPath,[System.Drawing.Imaging.ImageFormat]::Png)
            } finally { $attrs.Dispose() }
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
        $sha = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $length = (Get-Item -LiteralPath $outputPath).Length
        if ($RelativeOut -match '^marketing/(achievements|leaderboards)/' -and $length -ge 1000000) { throw "Oversized badge: $RelativeOut" }
        $records.Add([ordered]@{ path=$RelativeOut; width=$Width; height=$Height; bytes=$length; sha256=$sha; source=$InputName; crop=@($Crop.X,$Crop.Y,$Crop.Width,$Crop.Height) })
    } finally { $image.Dispose() }
}
Export-Png 'icon-source.png' 'marketing/app-icon-512.png' 512 512
Export-Png 'feature-source.png' 'marketing/feature-graphic-1024x500.png' 1024 500
Export-Png 'splash-source.png' 'marketing/splash-1080x1920.png' 1080 1920
Export-Png 'icon-source.png' 'assets/brand/icon.png' 512 512
Export-Png 'feature-source.png' 'assets/brand/feature.png' 1024 500
Export-Png 'splash-source.png' 'assets/brand/splash.png' 720 1280

$achievementKeys = @('first_fracture','cascade','chain_reaction','clean_sweep','steady_hand','amber_cartographer','azure_explorer','vault_keeper','star_pocket','constellation','master_miner','crystal_collector','crystal_connoisseur','bank_shot','spectacular','deep_diver','daily_spark','week_of_wonder','workshop_whiz','seasoned_miner')
$boardKeys = @('best_score','endless_depth','miner_xp')
function Export-Atlas {
    param([string]$InputName,[string[]]$Keys,[int]$Columns,[int]$Rows,[string]$MarketingDir)
    $atlas = [System.Drawing.Image]::FromFile((Join-Path $source $InputName))
    $cellW = $atlas.Width / $Columns
    $cellH = $atlas.Height / $Rows
    $atlas.Dispose()
    for($i=0;$i -lt $Keys.Length;$i++) {
        $crop = [System.Drawing.RectangleF]::new(($i % $Columns)*$cellW,[Math]::Floor($i/$Columns)*$cellH,$cellW,$cellH)
        Export-Png $InputName ("marketing/" + $MarketingDir + "/" + $Keys[$i] + ".png") 512 512 $crop
        Export-Png $InputName ("assets/badges/" + $Keys[$i] + ".png") 256 256 $crop
    }
}
Export-Atlas 'achievements-source.png' $achievementKeys 5 4 'achievements'
Export-Atlas 'leaderboards-source.png' $boardKeys 3 1 'leaderboards'

# Small review sheet derives from final shipped PNGs, with labels solely for reviewer orientation.
$contact = [System.Drawing.Bitmap]::new(1500,1250,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($contact)
$font = [System.Drawing.Font]::new('Segoe UI',12,[System.Drawing.FontStyle]::Regular)
$brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(226,236,240))
try {
    $g.Clear([System.Drawing.Color]::FromArgb(7,24,40))
    $allKeys = $achievementKeys + $boardKeys
    for($i=0;$i -lt $allKeys.Length;$i++) {
        $x=($i % 5)*300; $y=[Math]::Floor($i/5)*250
        $img = [System.Drawing.Image]::FromFile((Join-Path $root ("assets/badges/" + $allKeys[$i] + ".png")))
        try { $g.DrawImage($img,[System.Drawing.Rectangle]::new($x+45,$y,210,210)) } finally { $img.Dispose() }
        $g.DrawString($allKeys[$i],$font,$brush,[single]($x+25),[single]($y+216))
    }
    $contact.Save((Join-Path $source 'badge-contact-sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
} finally { $font.Dispose(); $brush.Dispose(); $g.Dispose(); $contact.Dispose() }

$sourceRecords = @(Get-ChildItem -LiteralPath $source -Filter '*-source.png' | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    try { [ordered]@{ path=('marketing/branding/'+$_.Name); width=$img.Width; height=$img.Height; bytes=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() } } finally { $img.Dispose() }
})
$badgeHashes = @($records | Where-Object { $_.path -match '^marketing/(achievements|leaderboards)/' } | ForEach-Object {$_.sha256})
if (($badgeHashes | Select-Object -Unique).Count -ne 23) { throw 'Badge SHA256 values are not all unique' }
$manifest=[ordered]@{
    schema_version=1; generator='Built-in image_gen; 2026-11-13'; source_type='Original AI-assisted commissioned illustrations';
    editing='Only deterministic crop, bicubic resize, PNG encode and review contact-sheet assembly';
    sources=$sourceRecords; outputs=$records; validation=[ordered]@{ marketing_badges=23; runtime_badges=23; unique_marketing_badge_hashes=23; marketing_badge_dimensions='512x512'; runtime_badge_dimensions='256x256'; all_marketing_badges_under_bytes=1000000 }
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $source 'art-manifest.json') -Encoding utf8
Write-Output ("Exported " + $records.Count + " PNGs; all 23 unique store badges < 1,000,000 bytes.")

