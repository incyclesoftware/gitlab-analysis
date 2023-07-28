begin {
    $endDateTime = Get-Date
    $projectcommitsHashTable = @{}
    $projectBranchesHashTable = @{}
    $projectMergeRequestsHashTable = @{}
    $projectsSummary = New-Object System.Collections.Generic.List[object]
}

process {
    Write-Output "Loading projects from file..."
    $projects = Get-Content .\projects.json | ConvertFrom-Json -Depth 10

    Write-Output "Loading project commits..."
    $projectCommits = Get-Content .\project-commits.json | ConvertFrom-Json -Depth 10

    foreach ($commits in $projectCommits) {
        $projectcommitsHashTable.Add($commits.ProjectId, $commits.Commits)
    }

    Write-Output "Loading project branch merge requests..."
    $projectBranchMergeRequests = Get-Content .\project-branch-merge-requests.json | ConvertFrom-Json -Depth 10

    foreach ($projectBranchMergeRequest in $projectBranchMergeRequests) {
        $projectBranchesHashTable.Add($projectBranchMergeRequest.ProjectId, $projectBranchMergeRequest.Branches)
        $projectMergeRequestsHashTable.Add($projectBranchMergeRequest.ProjectId, $projectBranchMergeRequest.MergeRequests)
    }

    $index = 1
    $totalProjects = $projects.Count

    foreach ($project in $projects) {
        $percentComplete = [System.Convert]::ToInt32(($index / $totalProjects) * 100)
        Write-Progress "Processing projects..." -Status "$percentComplete%" -PercentComplete $percentComplete

        if($project.id -ne 1411) {
            continue
        }

        $index++
        
        $commitsLastThirtyDays = 0
        $commitsLastSixtyDays = 0
        $commitsLastNinetyDays = 0
        $commitsLastOneHundredTweentyDays = 0
        $commitsLastSixMonths = 0

        $totalBranches = 0
        $mergeRequestsOpen = 0
        $mergeRequestsMerged = 0
        $mergerequestsClosed = 0

        if ($projectBranchesHashTable.ContainsKey($project.id)) {
            $totalBranches = $projectBranchesHashTable[$project.id].Count

            foreach ($mergeRequest in $projectMergeRequestsHashTable[$project.id]) {

                if ($mergeRequest.State -eq "opened") {
                    $mergeRequestsOpen++
                }
                elseif ($mergeRequest.State -eq "merged") {
                    $mergeRequestsMerged++
                }
                else {
                    $mergerequestsClosed++
                }
            }
        }
        
        $lastCommitDateTime = $null

        $commiters = New-Object System.Collections.Generic.List[string]

        if ($projectcommitsHashTable.ContainsKey($project.id)) {
            $commits = $projectcommitsHashTable[$project.id]

            foreach ($commit in $commits) {
                $commitDateTime = [datetime]$commit.created_at
                $timeSpan = New-TimeSpan -Start $commitDateTime -End $endDateTime
    
                if ($null -eq $lastCommitDateTime -or $lastCommitDateTime -lt $commitDateTime) {
                    $lastCommitDateTime = $commitDateTime
                }

                write-output $commitsLastThirtyDays++ 
                write-output $commitsLastSixtyDays++ 
                write-output $commitsLastNinetyDays++ 
                write-output $commitsLastOneHundredTweentyDays++ 
    
                switch ($timeSpan.Days) {
                    { $_ -le 30 } { $commitsLastThirtyDays++ }
                    { $_ -le 60 } { $commitsLastSixtyDays++ }
                    { $_ -le 90 } { $commitsLastNinetyDays++ }
                    { $_ -le 120 } { $commitsLastOneHundredTweentyDays++ }
                }

                if ($commiters.Contains($commit.committer_email)) {
                    continue
                }

                $commiters.Add($commit.committer_email)
            }

            $commitsLastSixMonths = $commits.Count
        }

        Write-Output $commitsLastSixMonths
        Write-output $commits.Count
        $projectSummary = [PSCustomObject]@{
            Id                               = $project.id
            Name                             = $project.name
            CreatedOn                        = $project.created_at
            # Fetch from a user file
            CreatedBy                        = $project.creator_id
            Namespace                        = $project.namespace.name
            NamespaceType                    = $project.namespace.kind
            Owner                            = $project.owner.username
            Visibility                       = $project.visibility
            SizeInMb                         = [System.Convert]::ToInt32($project.statistics.repository_size / 1048576)
            IsEmpty                          = $project.empty_repo
            IsArchived                       = $project.archived
            HasForks                         = $project.forks_count -gt 0 ? $true : $false
            RepositoryStatus                 = $project.repository_access_level
            IsForked                         = $null -ne $project.forked_from_project
            LastCommitDateTime               = $null -eq $lastCommitDateTime ? "" : $lastCommitDateTime
            CommitsLastThirtyDays            = $commitsLastThirtyDays
            CommitsLastSixtyDays             = $commitsLastSixtyDays
            CommitsLastNinetyDays            = $commitsLastNinetyDays
            CommitsLastOneHundredTweentyDays = $commitsLastOneHundredTweentyDays
            CommitsLastSixMonths             = $commitsLastSixMonths
            TotalBranches                    = $totalBranches
            MergeRequestsOpen                = $mergeRequestsOpen
            MergeRequestsMerged              = $mergeRequestsMerged
            MergeRequestsClosed              = $mergerequestsClosed
            TotalContributors                = $commiters.Count
            LfsEnabled                       = $project.lfs_enabled
            ProjectUrl                       = $project.web_url
            RepoHttpUrl                      = $project.http_url_to_repo
            RepoSshUrl                       = $project.ssh_url_to_repo
        }
        $projectsSummary.Add($projectSummary)
    }

    Write-Output "Saving to file..."
    $projectsSummary | Export-Csv .\project-summary.csv
}

end {
    Write-Output "Finished."
}
