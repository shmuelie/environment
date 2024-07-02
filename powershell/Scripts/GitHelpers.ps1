function Get-Worktrees() {
    ((git worktree list --porcelain) -join ',') -split ',,' | ConvertFrom-Csv -Header 'Path','Commit','Branch' | ForEach-Object {
        $_.Path = (Resolve-Path $_.Path.SubString(9))
        $_.Commit = $_.Commit.SubString(5)
        if ($_.Branch.Length -gt 18) {
            $_.Branch = $_.Branch.SubString(18)
        }
        $_
    }
}

function Get-CurrentWorktree() {
    $currentPath = Get-Location
    Get-Worktrees | Where-Object {
        $pathComparison = Compare-Object -ReferenceObject ($_.Path -split '\\') -DifferenceObject ($currentPath -split '\\')
        ($pathComparison.Length -eq 0) -or ($pathComparison.Length -eq ($pathComparison | Where-Object SideIndicator -eq '=>').Length)
    }
}

function Get-RepositoryName() {
    git remote get-url origin | ForEach-Object { 
        $_.SubString($_.LastIndexOf('/') + 1) -replace '\.git$',''
    }
}

function Get-RootWorktree() {
    $worktreePath = $null
    $isRoot = (Get-ChildItem .\ -Filter .git -Hidden | Select-Object -ExpandProperty PSIsContainer)
    if ($isRoot) {
        $worktreePath = Get-Location
    } else {
        $worktreePath = ((Get-Content .\.git).Substring(8) -split '/.git/')[0] -replace '/','\\'
    }
    Get-Worktrees | Where-Object {
        $pathComparison = Compare-Object -ReferenceObject ($_.Path -split '\\') -DifferenceObject ($worktreePath -split '\\')
        ($pathComparison.Length -eq 0) -or ($pathComparison.Length -eq ($pathComparison | Where-Object SideIndicator -eq '=>').Length)
    }
}

function Add-Worktree {
    <#
    .SYNOPSIS
    Create a new branch, checked out to a worktree
    .DESCRIPTION
    Auto appends user/senglard/ to the name
    .PARAMETER WorkName
    Name of the branch, without the user prefix
    .PARAMETER SetLocation
    Whether to change the current directory to the new worktree
    #>
    [CmdletBinding()]
    param(
        [string]$WorkName,
        [switch]$SetLocation = $false
    )
    process {
        $worktreePath = "$(Get-RootWorktree | Select-Object -ExpandProperty Path | Split-Path -Parent)/user/senglard/$WorkName"
        git worktree add -b user/senglard/$WorkName $worktreePath
        if (($LASTEXITCODE -eq 0) -and $SetLocation) {
            Set-Location -Path $worktreePath
        }
    }
}

function Update-Worktrees() {
    # Get latest state
    Write-Progress -Activity 'Updating Worktrees' -Status 'Fetching' -PercentComplete 0 -Id 0
    git fetch --all --recurse-submodules --quiet 2>&1 | Out-Null
    Write-Progress -Activity 'Updating Worktrees' -Status 'Getting Worktrees' -PercentComplete 0 -Id 0
    $worktrees = Get-Worktrees
    $percent = 0
    foreach ($worktree in $worktrees) {
        Write-Progress -Activity 'Updating Worktrees' -Status ($worktree.Path) -PercentComplete $percent -CurrentOperation 'Changing location' -Id 0
        # Change to worktre
        Push-Location -Path ($worktree.Path)
        Write-Progress -Activity 'Updating Worktrees' -Status ($worktree.Path) -PercentComplete $percent -CurrentOperation 'Getting GIT status' -Id 0
        $status = Get-GitStatus
        # If behind and nothing local
        if (($status.BehindBy -gt 0) -and ($status.AheadBy -eq 0)) {
            $stashed = $false;
            # Stash any local changes
            if ($status.HasWorking) {
                Write-Progress -Activity 'Updating Worktrees' -Status ($worktree.Path) -PercentComplete $percent -CurrentOperation 'Stashing changes' -Id 0
                $stashed = $true
                git stash push --include-untracked --quiet 2>&1 | Out-Null
            }
            # Fast forward
            Write-Progress -Activity 'Updating Worktrees' -Status ($worktree.Path) -PercentComplete $percent -CurrentOperation 'Fast forwarding' -Id 0
            git merge --ff-only `@`{upstream`} --quiet 2>&1 | Out-Null
            # Pop any stashed changes
            if ($stashed) {
                Write-Progress -Activity 'Updating Worktrees' -Status ($worktree.Path) -PercentComplete $percent -CurrentOperation 'Restoring changes' -Id 0
                git stash pop --quiet 2>&1 | Out-Null
            }
        }
        # Revert location
        Write-Progress -Activity 'Updating Worktrees' -Status ($worktree.Path) -PercentComplete $percent -CurrentOperation 'Reverting location' -Id 0
        Pop-Location
        $percent += 100 / ($worktrees.Length)
    }
}