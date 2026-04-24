# ArcGIS Pro SDK MCP

An MCP server that gives AI assistants (Claude Code, Claude Desktop) domain expertise for ArcGIS Pro add-in development. Runs standalone — no running ArcGIS Pro instance required.

## Install

Open PowerShell and run:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Woodland-Solutions-Group-LLC/arcgis-pro-sdk-mcp-releases/main/install.ps1)))
```

This downloads the latest release, installs to `%LOCALAPPDATA%\Programs\ArcGISProSDKMCP\`, adds it to your PATH, and registers it with Claude Code and Claude Desktop automatically.

**Requirements:** Windows, PowerShell 5.1+. ArcGIS Pro installation recommended for full functionality (required for deployment and launch tools).

## Uninstall

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Woodland-Solutions-Group-LLC/arcgis-pro-sdk-mcp-releases/main/install.ps1))) -Uninstall
```

## What it does

**Validation**
- ``sdk_validate_daml`` -- validates ``Config.daml`` against the Pro SDK XSD; catches structural and semantic errors
- ``sdk_check_nuget_alignment`` -- verifies NuGet package configuration for ArcGIS Pro add-in development
- ``sdk_detect_threading_issues`` -- scans C# source for MCT threading anti-patterns

**Build & Deployment**
- ``sdk_build_solution`` -- invokes Visual Studio MSBuild and returns structured diagnostics
- ``sdk_deploy_addin`` -- copies a built ``.esriAddinX`` to the add-in deployment folder
- ``sdk_close_pro`` -- gracefully closes ArcGIS Pro before a redeploy
- ``sdk_launch_pro`` -- launches ArcGIS Pro after deployment

**Environment**
- ``sdk_get_environment`` -- detects local Pro installation, SDK version, .NET SDK, Visual Studio

**SDK Knowledge**
- ``sdk://version-matrix`` -- ArcGIS Pro version compatibility matrix (NuGet versions, .NET, VS requirements)
- ``sdk://component-patterns`` -- implementation patterns for all 16 Pro SDK component types
- ``sdk_get_component_pattern`` -- query a specific component pattern by name