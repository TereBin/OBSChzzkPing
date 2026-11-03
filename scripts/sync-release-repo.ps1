[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ReleaseRepository,
    [Parameter(Mandatory)]
    [string] $ArtifactsDirectory
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$version = & (Join-Path $PSScriptRoot 'verify-version.ps1') | Select-Object -Last 1
$releaseRoot = [System.IO.Path]::GetFullPath($ReleaseRepository)
$artifacts = [System.IO.Path]::GetFullPath($ArtifactsDirectory)

foreach ($name in @('OBSChzzkPing-Setup.exe', 'OBSChzzkPing-windows-x64.zip', 'SHA256SUMS.txt')) {
    $source = Join-Path $artifacts $name
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Release artifact is missing: $source"
    }
    Copy-Item -LiteralPath $source -Destination (Join-Path $releaseRoot $name) -Force
}

Get-ChildItem -LiteralPath $releaseRoot -Filter 'OBSChzzkPing-*-windows-x64.zip' -File |
    Where-Object Name -ne 'OBSChzzkPing-windows-x64.zip' |
    Remove-Item -Force

$changelog = Get-Content -LiteralPath (Join-Path $sourceRoot 'CHANGELOG.md') -Raw
$escapedVersion = [regex]::Escape($version)
$match = [regex]::Match($changelog, "(?ms)^## $escapedVersion\s*\r?\n(?<notes>.*?)(?=^## |\z)")
if (-not $match.Success) {
    throw "CHANGELOG.md has no section for $version"
}
$notes = $match.Groups['notes'].Value.Trim()
$firstNote = (($notes -split "\r?\n") | Where-Object { $_ -match '^- ' } | Select-Object -First 1) -replace '^-\s*', '' -replace '`', ''

$readmePath = Join-Path $releaseRoot 'README.md'
$readme = Get-Content -LiteralPath $readmePath -Raw
$readme = [regex]::Replace($readme, '현재 버전은 `[^`]+`입니다\.', "현재 버전은 ``$version``입니다.", 1)
$section = "### $version 변경 사항`r`n`r`n$notes`r`n"
$readme = [regex]::Replace(
    $readme,
    '(?ms)^### [0-9]+\.[0-9]+\.[0-9]+ 변경 사항\s*\r?\n.*?(?=^- \[Windows 설치 관리자 바로 다운로드\])',
    $section,
    1
)
Set-Content -LiteralPath $readmePath -Value $readme -Encoding utf8NoBOM

$manifestPath = Join-Path $releaseRoot 'update.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$manifest.latestVersion = $version
$manifest.title = "OBSChzzkPing $version 업데이트"
$manifest.message = $firstNote
$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM

Write-Host "Synchronized release repository metadata and artifacts for $version"
Write-Output $version
