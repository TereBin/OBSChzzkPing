[CmdletBinding()]
param(
    [string] $BuildDirectory = 'build_x64',
    [ValidateSet('RelWithDebInfo', 'Release')]
    [string] $Configuration = 'RelWithDebInfo',
    [string] $InnoSetup = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = & (Join-Path $PSScriptRoot 'verify-version.ps1') | Select-Object -Last 1
$build = [System.IO.Path]::GetFullPath((Join-Path $root $BuildDirectory))
$dll = Join-Path $build "$Configuration\streamping.dll"
if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) {
    throw "Plugin DLL was not found: $dll"
}

$dist = Join-Path $root 'dist'
$artifacts = Join-Path $root 'artifacts'
if (Test-Path -LiteralPath $dist) {
    Remove-Item -LiteralPath $dist -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $dist, $artifacts | Out-Null

cmake --install $build --config $Configuration --prefix $dist
if ($LASTEXITCODE -ne 0) {
    throw "cmake --install failed with exit code $LASTEXITCODE"
}

$zip = Join-Path $artifacts 'OBSChzzkPing-windows-x64.zip'
if (Test-Path -LiteralPath $zip) {
    Remove-Item -LiteralPath $zip -Force
}
Compress-Archive -Path (Join-Path $dist '*') -DestinationPath $zip -CompressionLevel Optimal

if (-not $InnoSetup) {
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
    )
    $InnoSetup = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $InnoSetup -or -not (Test-Path -LiteralPath $InnoSetup -PathType Leaf)) {
    throw 'Inno Setup 6 ISCC.exe was not found. Pass -InnoSetup explicitly.'
}

$relativeBuild = [System.IO.Path]::GetRelativePath((Join-Path $root 'installer'), (Join-Path $build $Configuration))
& $InnoSetup "/DMyAppVersion=$version" "/DMyBuildDir=$relativeBuild" (Join-Path $root 'installer\OBSChzzkPing.iss')
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup failed with exit code $LASTEXITCODE"
}

$files = @(
    (Join-Path $artifacts 'OBSChzzkPing-Setup.exe'),
    $zip
)
$checksum = $files | ForEach-Object {
    $hash = Get-FileHash -LiteralPath $_ -Algorithm SHA256
    "$($hash.Hash)  $([System.IO.Path]::GetFileName($_))"
}
Set-Content -LiteralPath (Join-Path $artifacts 'SHA256SUMS.txt') -Value $checksum -Encoding utf8NoBOM

Write-Host "Created OBSChzzkPing $version artifacts in $artifacts"
Get-ChildItem -LiteralPath $artifacts -File | Select-Object Name, Length
