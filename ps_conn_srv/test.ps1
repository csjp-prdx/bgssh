#!/usr/bin/env pwsh

Install-Module Microsoft.PowerShell.ConsoleGuiTools

$guiTools = (Get-Module Microsoft.PowerShell.ConsoleGuiTools -List).ModuleBase
Add-Type -Path (Join-path $guiTools Terminal.Gui.dll)
[Terminal.Gui.Application]::Init()

$Window = .\tui.ps1
[Terminal.Gui.Application]::Top.Add($Window)

[Terminal.Gui.Application]::Run()
