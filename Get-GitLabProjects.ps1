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

    $headers = @{}
    $headers.Add("PRIVATE-TOKEN", $AccessToken)

    $gitLabProjects = New-Object System.Collections.Generic.List[object]
    $projectsApiEndpoint = "$apiBaseUrl/projects"
}

process {
    $page = 1
    $pageSize = 100
    do {
        Write-Output "Fetching Projects Page $page"
        $projects = Invoke-RestMethod "$($projectsApiEndpoint)?statistics=true&page=$page&per_page=$pageSize&order_by=id&sort=asc" -Headers $headers

        foreach ($project in $projects) {
            $gitLabProjects.Add($project)
        }

        $page++
    } while ($projects.Count -eq $pageSize)

    $gitLabProjects | ConvertTo-Json -Depth 10 | Out-File "projects.json"
}

end {
    Write-Output "Finished"
}