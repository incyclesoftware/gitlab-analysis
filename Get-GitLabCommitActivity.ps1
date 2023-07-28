[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [string]
    $GitLabUrl,

    [Parameter(Mandatory = $true)]
    [datetime]
    $StartDateTime,

    [Parameter(Mandatory = $true)]
    [datetime]
    $EndDateTime,

    [Parameter(Mandatory = $true)]
    [string]
    $AccessToken
)

begin {
    $apiPath = "api/v4"
    $apiBaseUrl = $GitLabUrl.EndsWith("/") ? "$($GitLabUrl)$apiPath" : "$GitLabUrl/$apiPath"

    $headers = @{}
    $headers.Add("PRIVATE-TOKEN", $AccessToken)

    $failures = New-Object System.Collections.Generic.List[object]
    $gitLabProjectCommits = New-Object System.Collections.Generic.List[object]

    $projectsApiEndpoint = "$apiBaseUrl/projects"

    $since = $StartDateTime.ToUniversalTime().ToString("o")
    $until = $EndDateTime.ToUniversalTime().ToString("o")
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
        Write-Progress "Fetching commits for $($project.name.PadRight($padding))" -Status "$percentComplete%" -PercentComplete $percentComplete
        $index++

        if ($project.empty_repo -or $project.repository_access_level -eq "disabled") {
            continue
        }

        $page = 1
        $pageSize = 100
        $projectCommits = New-Object System.Collections.Generic.List[object]

        do {
            Write-Output "$projectsApiEndpoint/$($project.id)/repository/commits?page=$page&per_page=$pageSize&since=$since&until=$until"
            $commits = Invoke-RestMethod "$projectsApiEndpoint/$($project.id)/repository/commits?page=$page&per_page=$pageSize&since=$since&until=$until" -Headers $headers

            foreach ($commit in $commits) {
                $projectCommits.Add($commit)
            }

            $page++
        } while ($commits.Count -ne 0)
            
        $projectCommitSummary = [PSCustomObject]@{
            ProjectId   = $project.id
            ProjectName = $project.name
            Commits     = $projectCommits
        }

        $gitLabProjectCommits.Add($projectCommitSummary)
    }

    Write-Output "Saving to disk..."
    $gitLabProjectCommits | ConvertTo-Json -Depth 10 | Out-File "project-commits.json"

    Write-Output $failures
}

end {
    Write-Output "Finished"
}
