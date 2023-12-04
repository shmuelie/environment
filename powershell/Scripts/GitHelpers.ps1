function Get-Worktrees() {
    ((git worktree list --porcelain) -join ',') -split ',,' | ConvertFrom-Csv -Header 'Path','Commit','Branch' | ForEach-Object {
        $_.Path = (Resolve-Path $_.Path.SubString(9))
        $_.Commit = $_.Commit.SubString(5)
        $_.Branch = $_.Branch.SubString(7)
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

function Add-Worktree($WorkName) {
    git worktree add -b user/senglard/$WorkName "$(Get-RootWorktree | Select-Object -ExpandProperty Path | Split-Path -Parent)/user/senglard/$WorkName"
}