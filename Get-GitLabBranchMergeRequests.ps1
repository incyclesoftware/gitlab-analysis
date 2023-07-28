[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [String]
    $GitLabUrl,

    [Parameter(Mandatory = $true)]
    [string]
    $AccessToken
)

begin {
    $apiPath = "api/v4"
    $apiBaseUrl = $GitLabUrl.EndsWith("/") ? "$($GitLabUrl)$apiPath" : "$GitLabUrl/$apiPath"

    $projectsApiEndpoint = "$apiBaseUrl/projects"

    $headers = @{}
    $headers.Add("PRIVATE-TOKEN", $AccessToken)

    $gitLabProjects = New-Object System.Collections.Generic.List[object]
    $projectBranchMergeRequests = New-Object System.Collections.Generic.List[object]
}

process {
    $maxNameLength = 0

    Write-Output "Loading projects from file..."
    $gitLabProjects = Get-Content .\projects.json | ConvertFrom-Json -Depth 10

    foreach ($project in $gitLabProjects) {
        if ($maxNameLength -lt $project.name.Length) {
            $maxNameLength = $project.name.Length
        }
    }    

    $index = 1
    foreach ($project in $gitLabProjects) {
        $percentComplete = [System.Convert]::ToInt32(($index / $gitLabProjects.Count) * 100)
        $padding = $maxNameLength - $project.name.Length
        Write-Progress "Fetching merge for $($project.name.PadRight($padding))" -Status "$percentComplete%" -PercentComplete $percentComplete
        $index++

        if ($project.empty_repo -or $project.repository_access_level -eq "disabled") {
            continue
        }

        $page = 1
        $pageSize = 100
        $mergeRequests = New-Object System.Collections.Generic.List[object]

        do {
            Write-Output "$projectsApiEndpoint/$($project.id)/merge_requests?state=all&page=$page&per_page=$pageSize"
            $pagedMergeRequests = Invoke-RestMethod "$projectsApiEndpoint/$($project.id)/merge_requests?state=all&page=$page&per_page=$pageSize" -Headers $headers

            foreach ($mergeRequest in $pagedMergeRequests) {
                $mergeRequests.Add([PSCustomObject]@{
                        Id    = $mergeRequest.id
                        State = $mergeRequest.state
                    })
            }

            $page++
        } while ($pagedMergeRequests.Count -ne 0)

        $page = 1
        $pageSize = 100
        $branches = New-Object System.Collections.Generic.List[string]

        do {
            Write-Output "$projectsApiEndpoint/$($project.id)/repository/branches?page=$page&per_page=$pageSize"
            $pageBranches = Invoke-RestMethod "$projectsApiEndpoint/$($project.id)/repository/branches?page=$page&per_page=$pageSize" -Headers $headers

            foreach ($branch in $pageBranches) {
                $branches.Add($branch.name)
            }

            $page++
        } while ($pageBranches.Count -ne 0)

        $projectBranchMergeRequests.Add([PSCustomObject]@{
                ProjectId     = $project.id
                Branches      = $branches
                MergeRequests = $mergeRequests
            })
    }

    Write-Output "Saving to disk..."
    $projectBranchMergeRequests | ConvertTo-Json -Depth 10 | Out-File "project-branch-merge-requests.json"
}

end {
    Write-Output "Finished"
}