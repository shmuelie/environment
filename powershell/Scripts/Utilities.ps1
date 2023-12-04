function IsElevated() {
    <#
    .SYNOPSIS
    Check if current session is elevated.

    .OUTPUTS
    True if elevated; otherwise false.
    #>
	if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsWindows) {
		return ((id -u) -eq 0)
	}
	return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function CreateGlobalConst($Name, $Value) {
	New-Variable -Name $Name -Value $Value -Option Constant,AllScope -Scope Global
}

function CreatePathVariable($Name, $Path) {
	if ($null -ne $Path -and (Test-Path -Path $Path) -eq $true) {
		CreateGlobalConst $Name $Path
	}
}

function GetSessionTitle() {
    $title = "PowerShell $($PSVersionTable.PSVersion) ($([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture))"
    if ($PSVersionTable.PSVersion.Major -le 5) {
        $title = "Windows $title"
    }
    if (IsElevated) {
        $title = "Elevated: $title"
    }
    return $title
}

function TryImportModule($Path) {
    if ((Test-Path -Path $Path) -eq $true) {
        Import-Module $Path
    }
}
