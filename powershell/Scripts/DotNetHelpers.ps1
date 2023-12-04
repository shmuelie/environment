function Get-GlobalDotNetTools() {
    Push-Location
    Set-Location ~
    dotnet tool list -g | Out-Null
    dotnet tool list -g | Select-Object -Skip 2 | ForEach-Object { 
        $_ -replace '\s+',',' 
    } | ConvertFrom-Csv -Header "PackageId","Version","Commands"
    Pop-Location
}

function Update-GlobalDotNetTools() {
    Push-Location
    Set-Location ~
    Get-GlobalDotNetTools | Select-Object -ExpandProperty PackageId | ForEach-Object { 
        dotnet tool update -g $_ 
    }
    Pop-Location
}
