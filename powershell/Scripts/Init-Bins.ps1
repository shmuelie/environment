Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

function Install-BinFileSafe {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Path,
        [string]$Command = ''
    )
    process {
        if (($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) -and ((Test-Path -Path $Path) -eq $true)) {
            if ($Command -ne '') {
                Install-BinFile -Name $Name -Path $Path -Command $Command
            }
            else {
                Install-BinFile -Name $Name -Path $Path
            }
        }
    }
}

Install-BinFileSafe -Name nano -Path (Join-Path (Split-Path -Path (get-command git).Source -Parent) '../usr/bin/nano.exe')
@('mkvmerge','mkvinfo','mkextract','mkvpropedit') | ForEach-Object {
    $mkvPath = "C:\Program Files\MKVToolNix\$_.exe"
    Install-BinFileSafe -Name $_ -Path $mkvPath
}