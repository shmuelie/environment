# Check that options are available before setting them.
New-Variable -Name 'PSReadLineOptions' -Value (Get-Command Set-PSReadLineOption | Select-Object -ExpandProperty Parameters) -Scope Script
if ($PSReadLineOptions.ContainsKey("PredictionViewStyle")) {
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
}
if ($PSReadLineOptions.ContainsKey("PredictionSource")) {
    # Check that plugins are supported
    if (([System.Enum]::GetNames([Microsoft.PowerShell.PredictionSource]) -contains 'HistoryAndPlugin') -and
        ($PSVersionTable.PSVersion -gt 7.2)) {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
    } else {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
    }
}
if ($PSReadLineOptions.ContainsKey("ShowToolTips")) {
    Set-PSReadLineOption -ShowToolTips -ErrorAction SilentlyContinue
}

# Load completion plugins
if ($null -eq (Get-Module -Name CompletionPredictor)) {
    Import-Module -Name CompletionPredictor -ErrorAction SilentlyContinue
}
