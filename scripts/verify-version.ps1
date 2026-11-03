[CmdletBinding()]
param(
    [string] $ExpectedVersion = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$spec = Get-Content -LiteralPath (Join-Path $root 'buildspec.json') -Raw | ConvertFrom-Json
$version = [string]$spec.version

if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "buildspec.json version is not semantic x.y.z: $version"
}
if ($ExpectedVersion -and $ExpectedVersion -ne $version) {
    throw "Expected version $ExpectedVersion but buildspec.json contains $version"
}

$checks = @(
    @{ Path = 'installer/OBSChzzkPing.iss'; Pattern = "#define MyAppVersion `"$([regex]::Escape($version))`"" },
    @{ Path = 'DISTRIBUTION.md'; Pattern = "(?m)^# OBSChzzkPing $([regex]::Escape($version))\r?$" },
    @{ Path = 'CHANGELOG.md'; Pattern = "(?m)^## $([regex]::Escape($version))\r?$" }
)

foreach ($check in $checks) {
    $path = Join-Path $root $check.Path
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -notmatch $check.Pattern) {
        throw "$($check.Path) does not contain version $version in the expected location"
    }
}

Write-Host "Version metadata is consistent: $version"
Write-Output $version
