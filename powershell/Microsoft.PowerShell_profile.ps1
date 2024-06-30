function Test-Interactive
{
    <#
    .Synopsis
        Determines whether both the user and process are interactive.
    #>

    [CmdletBinding()] Param()
    [Environment]::UserInteractive -and !([Environment]::GetCommandLineArgs() | Where-Object { $_ -ilike '-NonI*' })
}

if ((Test-Interactive) -eq $false) {
    return;
}

# Force loading PSReadLine
if ($null -eq (Get-Module -Name PSReadLine)) {
	Import-Module PSReadLine
}

# Create variable to script's folder
New-Variable -Name 'PSUserRoot' -Value (Split-Path -Path $PROFILE -Parent) -Option Constant,AllScope -Scope Global

# Load Utilities Script
. "$PSUserRoot\Scripts\Utilities.ps1"
# Load git helers
. "$PSUserRoot\Scripts\GitHelpers.ps1"
# Load .NET helpers
. "$PSUserRoot\Scripts\DotNetHelpers.ps1"

# Configure PSReadLine
. "$PSUserRoot\Microsoft.PowerShell_PSReadLineConfig.ps1"

# Produce UTF-8 by default
# https://news.ycombinator.com/item?id=12991690
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

# https://technet.microsoft.com/en-us/magazine/hh241048.aspx
$MaximumHistoryCount = 10000;

# Common Paths
CreatePathVariable 'repos' $env:SOURCE_REPOS
if ($null -ne $repos) {
	CreatePathVariable 'shmuelie' "$repos/shmuelie"
	TryImportModule  "$shmuelie/PSVSEnv"
}

if (Test-Path "$PSUserRoot\Microsoft.PowerShell_paths.ps1") {
	. "$PSUserRoot\Microsoft.PowerShell_paths.ps1"
}

# Enabled VS environment
if ($null -ne (Get-Command Set-VS2022 -ErrorAction SilentlyContinue)) {
	Set-VS2022 -Architecture amd64 -HostArchitecture amd64
	CreateGlobalConst 'CppSdkIncludes' ($env:INCLUDE -split ';' | Resolve-Path)
}

CreateGlobalConst 'Paths' ($env:Path -split ';' | Where-Object -FilterScript {
    ($_ -NE '') -and ((Test-Path -Path $_) -eq $true)
} | Resolve-Path)

# Load custom prompt
. "$PSUserRoot\Microsoft.PowerShell_prompt.ps1"

# Import the Chocolatey Profile that contains the necessary code to enable tab-completions to function for `choco`.
TryImportModule "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
# Import vcpkg auto completion
TryImportModule "$repos\microsoft\vcpkg\scripts\posh-vcpkg"
