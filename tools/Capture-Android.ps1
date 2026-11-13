param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9-]+$')][string]$Label,
    [ValidateSet('phone','tablet7','tablet10')][string]$Profile='phone',
    [Parameter(Mandatory=$true)][string]$Apk,
    [string]$Adb="$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$apkPath=(Resolve-Path -LiteralPath $Apk).Path
if (-not $apkPath.StartsWith($projectRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'APK must belong to this project.' }
$serial='emulator-5560'
$outDirectory=Join-Path $projectRoot "marketing\screenshots\android-$Profile"
New-Item -ItemType Directory -Path $outDirectory -Force | Out-Null
$output=Join-Path $outDirectory "$Label.png"
$remote='/sdcard/prism-quarry-capture.png'
& $Adb -s $serial shell screencap -p $remote
if ($LASTEXITCODE -ne 0) { throw 'Android screenshot failed.' }
& $Adb -s $serial pull $remote $output
if ($LASTEXITCODE -ne 0) { throw 'Android screenshot transfer failed.' }
Add-Type -AssemblyName System.Drawing
$frame=[Drawing.Image]::FromFile($output)
try { $width=$frame.Width; $height=$frame.Height } finally { $frame.Dispose() }
$displaySize=(& $Adb -s $serial shell wm size | Out-String).Trim()
$displayDensity=(& $Adb -s $serial shell wm density | Out-String).Trim()
$receipt=[ordered]@{
    label=$Label;profile=$Profile;source='Actual Android emulator full framebuffer; no resizing or pixel editing';
    serial=$serial;physical_device=$false;captured_utc=[DateTime]::UtcNow.ToString('o');
    display_size=$displaySize;display_density=$displayDensity;
    image="marketing/screenshots/android-$Profile/$Label.png";width=$width;height=$height;
    image_sha256=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant();
    apk_sha256=(Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant()
}
$receipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outDirectory "$Label.json") -Encoding utf8
$receipt | ConvertTo-Json
