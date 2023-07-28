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

    $gitLabNamespaces = New-Object System.Collections.Generic.List[object]
    $namespacesApiEndpoint = "$apiBaseUrl/namespaces"
}

process {
    Write-Output $apiBaseUrl
    Write-Output $namespacesApiEndpoint

    $page = 1
    $pageSize = 100
    do {
        Write-Output "Fetching Namespaces Page $page"
        $namespaces = Invoke-RestMethod "$($namespacesApiEndpoint)?page=$page&per_page=$pageSize" -Headers $headers

        foreach ($namespace in $namespaces) {
            $gitLabNamespaces.Add($namespace)
        }

        $page++
    } while ($namespaces.Count -eq $pageSize)

    $gitLabNamespaces | ConvertTo-Json -Depth 10 | Out-File "namespaces.json"
}

end {
    Write-Output "Finished"
}