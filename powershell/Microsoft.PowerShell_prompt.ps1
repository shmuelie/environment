# Prints last command length if greater than 3 seconds and then bash styled prompt
function prompt {
	$historyItem = Get-History -Count 1

    if ($historyItem -and ($GLOBAL:LastHistoryItemProcessed -lt $historyItem.Id) -and $historyItem.CommandLine -ne 'git branch-details')
    {
        ## Check if the last command took a long time
        $lastCommandElapsedTime = $historyItem.EndExecutionTime - $historyItem.StartExecutionTime

        if ($lastCommandElapsedTime.TotalSeconds -gt 3)
        {
            if ($lastCommandElapsedTime.TotalSeconds -gt 3600) # greater than one hour
            {
                Write-Host -ForegroundColor Yellow ("`nCommand Time: {0:#0}:{1:00}:{2:00}.{3:000}." -f (($lastCommandElapsedTime.Days * 24) + $lastCommandElapsedTime.Hours), $lastCommandElapsedTime.Minutes, $lastCommandElapsedTime.Seconds, $lastCommandElapsedTime.Milliseconds)
            }
            elseif ($lastCommandElapsedTime.TotalSeconds -gt 60) # greater than one minute
            {
                Write-Host -ForegroundColor Yellow ("`nCommand Time: {0:#0}:{1:00}.{2:000}." -f $lastCommandElapsedTime.Minutes, $lastCommandElapsedTime.Seconds, $lastCommandElapsedTime.Milliseconds)
            }
            else
            {
                Write-Host -ForegroundColor Yellow ("`nCommand Time: {0} seconds." -f $lastCommandElapsedTime.TotalSeconds)
            }
        }

        $GLOBAL:LastHistoryItemProcessed = $historyItem.Id
    }

	if (IsElevated) {
		Write-Host -ForegroundColor Green -NoNewline '^'
	}

    $pathVariables = @()

    $isGitRepo = $null -ne (Get-GitStatus)

    $currentPath = Get-Location | Select-Object -ExpandProperty Path

    # If in a git repo, add it's name as a short hand
    if ($isGitRepo) {
        $gitRepositoryName = Get-RepositoryName
        $gitWorktreePath = (Get-CurrentWorktree).Path

        # If for whatever reason we fail to get the worktree path, just get the git root
        if ($null -eq $gitWorktreePath) {
            $gitWorktreePath = Split-Path (Get-GitStatus).GitDir -Parent
        }

        $pathVariables += [PSCustomObject]@{
            Name = $gitRepositoryName
            Value = $gitWorktreePath
        }

        $Host.UI.RawUI.WindowTitle = "$gitRepositoryName [$((Get-GitStatus).Branch)] $(GetSessionTitle)"
    }
    else {
        $Host.UI.RawUI.WindowTitle = GetSessionTitle
    }

    $pathVariables += [PSCustomObject]@{
        Name = '~'
        Value = $HOME
    }

    foreach ($pathVariable in $pathVariables) {
        $pathVariableValue = Resolve-Path $pathVariable.Value | Select-Object -ExpandProperty Path
        if ($currentPath.StartsWith($pathVariableValue)) {
            Write-Host -ForegroundColor Blue -NoNewline ($pathVariable.Name)
            $currentPath = $currentPath.Substring($pathVariableValue.Length)
            if (($currentPath -ne '') -and ($currentPath.StartsWith('\') -ne $true)) {
                Write-Host -ForegroundColor DarkBlue -NoNewline '\'
            }
            break
        }
    }

    Write-Host -ForegroundColor DarkBlue -NoNewline $currentPath

	if ($isGitRepo -and
        ($null -ne (Get-Command git -ErrorAction SilentlyContinue)) -and
        ($null -ne (Get-Command Write-VcsStatus -ErrorAction SilentlyContinue))) {
		Write-Host -NoNewline (Write-VcsStatus)
	}
    if ($Host.UI.RawUI.CursorPosition.X -ge ($Host.UI.RawUI.BufferSize.Width / 2)) {
        Write-Host -ForegroundColor Yellow ' ⏎'
    }
	Write-Host -ForegroundColor DarkBlue -NoNewline '$'
	return ' '
}
