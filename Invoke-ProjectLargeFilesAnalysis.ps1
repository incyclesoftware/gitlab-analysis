$files = Get-ChildItem .\_work -Filter "*.json"

$projectLargeFiles = New-Object System.Collections.Generic.List[object]

foreach($file in $files) {
    Write-Output "Processing $($file.Name)"
    $individualProjectLargeFiles = Get-Content $file.FullName | ConvertFrom-Json -Depth 10
    $projectLargeFiles.Add($individualProjectLargeFiles)
}

Write-Output "Saving to disk"
$projectLargeFiles | ConvertTo-Json -Depth 10 | Out-File .\project-large-files.json