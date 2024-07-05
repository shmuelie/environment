function Install-ModernAlias {
    [CmdletBinding()]
    param(
        [string]$PackageName,
        [string]$Alias,
        [string]$AppId = $null
    )
    process {
        $Package = Get-AppxPackage -Name $PackageName
        if ($null -eq $Package) {
            Write-Error -Message "No Package found with name $PackageName"
            return
        }
        if ($null -eq $AppId) {
            $PackageManifest = "$($Package.InstallLocation)\AppxManifest.xml"
            $AppId = [xml](Get-Content $PackageManifest) | Select-Object -ExpandProperty Package | Select-Object -ExpandProperty Applications | Select-Object -ExpandProperty Application | Select-Object -First 1 -ExpandProperty Id
        }
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
        Install-BinFile -Name $Alias -Path 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Command "`"-Command start shell:AppsFolder\$($Package.PackageFullName)!$AppId`"" -UseStart
    }
}