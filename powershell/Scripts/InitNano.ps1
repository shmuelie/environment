if ($null -eq (Get-Command nano -ErrorAction SilentlyContinue)) {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
    Install-BinFile -Name nano -Path (Join-Path (Split-Path -Path (get-command git).Source -Parent) '../usr/bin/nano.exe')
}