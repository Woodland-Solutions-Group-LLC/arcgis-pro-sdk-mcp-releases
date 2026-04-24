#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$repo       = 'Woodland-Solutions-Group-LLC/arcgis-pro-sdk-mcp-releases'
$exeName    = 'arcgis-pro-sdk-mcp.exe'
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\ArcGISProSDKMCP'
$exePath    = Join-Path $installDir $exeName
$apiHeaders = @{ 'User-Agent' = 'arcgis-pro-sdk-mcp-installer' }

# PS 5.1 defaults to TLS 1.0; GitHub API requires TLS 1.2+.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Add-ToUserPath {
    param([string]$Dir)
    $current = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    if (-not $current) { $current = '' }
    $parts = $current -split ';' | Where-Object { $_ -ne '' }
    if ($Dir -notin $parts) {
        [System.Environment]::SetEnvironmentVariable('PATH', ($parts + $Dir -join ';'), 'User')
        # Append to current session; avoids rebuilding Machine PATH and double-semicolons.
        $env:PATH = $env:PATH.TrimEnd(';') + ";$Dir"
    }
}

function Remove-FromUserPath {
    param([string]$Dir)
    $current = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    if (-not $current) { $current = '' }
    $parts = $current -split ';' | Where-Object { $_ -ne '' -and $_ -ne $Dir }
    [System.Environment]::SetEnvironmentVariable('PATH', ($parts -join ';'), 'User')
    $machine = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH = ($machine, $user | Where-Object { $_ }) -join ';'
}

if ($Uninstall) {
    Write-Host 'ArcGIS Pro SDK MCP - Uninstall'
    Write-Host ('-' * 40)

    if (Test-Path $exePath) {
        Write-Host 'Deregistering from AI clients...'
        # why: deregistration failure (locked config, malformed JSON) must not abort
        # directory removal and PATH cleanup — those should always complete.
        try { & $exePath setup --uninstall }
        catch { Write-Warning "AI client deregistration failed: $_" }
    } else {
        Write-Host 'Executable not found - skipping AI client deregistration.'
    }

    if (Test-Path $installDir) {
        Write-Host "Removing $installDir ..."
        Remove-Item $installDir -Recurse -Force
    } else {
        Write-Host 'Install directory not found - nothing to remove.'
    }

    Remove-FromUserPath $installDir
    Write-Host 'Removed from PATH.'
    Write-Host ('-' * 40)
    Write-Host 'Uninstall complete.'
    return
}

Write-Host 'ArcGIS Pro SDK MCP - Install'
Write-Host ('-' * 40)

Write-Host 'Fetching latest release...'
$releaseJson = Invoke-WebRequest -Uri "https://api.github.com/repos/$repo/releases/latest" `
    -UseBasicParsing -Headers $apiHeaders
$release = $releaseJson.Content | ConvertFrom-Json
$asset   = $release.assets | Where-Object { $_.name -eq $exeName } | Select-Object -First 1
if (-not $asset) {
    throw "Release asset '$exeName' not found in latest release ($($release.tag_name))."
}

Write-Host "Downloading $exeName $($release.tag_name)..."

if (Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($exeName)) -ErrorAction SilentlyContinue) {
    throw "$exeName is currently running. Stop it before reinstalling."
}

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $exePath -UseBasicParsing -Headers $apiHeaders

Write-Host 'Updating PATH...'
Add-ToUserPath $installDir

Write-Host 'Running setup (first run may take a few seconds)...'
& $exePath setup

Write-Host ('-' * 40)
Write-Host 'Install complete.'
Write-Host "  Installed to : $installDir"
Write-Host "  Run anywhere : arcgis-pro-sdk-mcp"
Write-Host ''
Write-Host 'To uninstall:'
Write-Host "  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/$repo/main/install.ps1))) -Uninstall"
