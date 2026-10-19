# Builds FS25_MotorSoundConfigurator.zip and installs it into the FS25 mods folder.
$ErrorActionPreference = 'Stop'
$modName = 'FS25_MotorSoundConfigurator'
$src     = $PSScriptRoot
$mods    = Join-Path $env:USERPROFILE 'Documents\My Games\FarmingSimulator2025\mods'
$target  = Join-Path $mods "$modName.zip"

if (Get-Process -Name 'FarmingSimulator2025Game' -ErrorAction SilentlyContinue) {
    throw 'Farming Simulator 25 is running. Close the game first (it locks the mod zips).'
}

# Validate all XML files before packing
foreach ($xmlFile in Get-ChildItem $src -Recurse -Filter *.xml) {
    # inside catch $_ is the error record, so the file comes from the loop variable
    try { [xml](Get-Content $xmlFile.FullName -Raw -Encoding UTF8) | Out-Null }
    catch { throw "Invalid XML: $($xmlFile.FullName): $($_.Exception.Message)" }
}

# Check all Lua files (syntax, undefined globals, goto) with the local luacheck setup two folders up, skipped where it
# does not exist (e.g. a clone of the public repository)
$luaCheck = Join-Path $src '..\..\tools\luacheck\check.ps1'
if (Test-Path $luaCheck) {
    & $luaCheck (Join-Path $src 'src')
    if ($LASTEXITCODE -ne 0) { throw "Lua check failed (exit $LASTEXITCODE), see findings above" }
} else {
    Write-Host 'Lua check skipped (tools\luacheck not found)'
}

$include = @('modDesc.xml')   # LICENSE not packed: TestRunner allows only game file types; GPL notice in the Lua headers and the description
$include += Get-ChildItem $src -Filter 'icon*.dds' | ForEach-Object { $_.Name }
$files = @()
foreach ($name in $include) { $files += Get-Item (Join-Path $src $name) }
foreach ($dir in 'src', 'l10n', 'gui', 'sounds') {
    $path = Join-Path $src $dir
    if (Test-Path $path) { $files += Get-ChildItem $path -Recurse -File }
}

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$tmp = Join-Path $env:TEMP "$modName.zip"
if (Test-Path $tmp) { [IO.File]::Delete($tmp) }
$zip = [IO.Compression.ZipFile]::Open($tmp, 'Create')
try {
    foreach ($f in $files) {
        $entry = $f.FullName.Substring($src.Length + 1).Replace('\', '/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $entry, 'Optimal') | Out-Null
        Write-Host "  + $entry"
    }
} finally { $zip.Dispose() }

Copy-Item $tmp $target -Force
[IO.File]::Delete($tmp)
Write-Host "Installed: $target"
