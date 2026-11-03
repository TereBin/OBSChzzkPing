[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string] $Version
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$specPath = Join-Path $root 'buildspec.json'
$spec = Get-Content -LiteralPath $specPath -Raw | ConvertFrom-Json
$spec.version = $Version
$spec | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $specPath -Encoding utf8NoBOM

$installerPath = Join-Path $root 'installer\OBSChzzkPing.iss'
$installer = Get-Content -LiteralPath $installerPath -Raw
$installer = [regex]::Replace($installer, '#define MyAppVersion "[0-9]+\.[0-9]+\.[0-9]+"', "#define MyAppVersion `"$Version`"", 1)
Set-Content -LiteralPath $installerPath -Value $installer -Encoding utf8NoBOM

$distributionPath = Join-Path $root 'DISTRIBUTION.md'
$distribution = Get-Content -LiteralPath $distributionPath -Raw
$distribution = [regex]::Replace($distribution, '(?m)^# OBSChzzkPing [0-9]+\.[0-9]+\.[0-9]+\r?$', "# OBSChzzkPing $Version", 1)
Set-Content -LiteralPath $distributionPath -Value $distribution -Encoding utf8NoBOM

$changelogPath = Join-Path $root 'CHANGELOG.md'
$changelog = Get-Content -LiteralPath $changelogPath -Raw
if ($changelog -notmatch "(?m)^## $([regex]::Escape($Version))\r?$") {
    $changelog = [regex]::Replace(
        $changelog,
        '(?m)^# 변경 이력\s*\r?\n',
        "# 변경 이력`r`n`r`n## $Version`r`n`r`n- 변경 사항을 작성하세요.`r`n`r`n",
        1
    )
    Set-Content -LiteralPath $changelogPath -Value $changelog -Encoding utf8NoBOM
}

& (Join-Path $PSScriptRoot 'verify-version.ps1') -ExpectedVersion $Version | Out-Null
Write-Host "Updated project version to $Version"
