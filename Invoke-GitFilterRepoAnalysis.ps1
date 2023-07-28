begin {
    $projectFileSizes = New-Object System.Collections.Generic.List[object]

    $pattern = "[\s]{2}([\w\d]{40})[\s]+([\d]+)[\s]+([\d]+)[\s]+([\W\w\d/]+)"

    $currentPath = Get-Location
    $outputFile = Join-Path $currentPath "project-large-files.json"
    $workDirectory = Join-Path $currentPath "_work"

    $workDirectoryExists = Test-Path $workDirectory

    if (!$workDirectoryExists) {
        New-Item $workDirectory -ItemType Directory | Out-Null
    }
}

process {
    Write-Output "Loading projects..."
    $projects = Get-Content .\projects.json | ConvertFrom-Json -Depth 10

    Set-Location $workDirectory

    $index = 1
    $totalProjects = $projects.Count

    foreach ($project in $projects) {
        $percentComplete = [System.Convert]::ToInt32(($index / $totalProjects) * 100)
        Write-Output "***********************************************************"
        Write-Output "Processing $($project.name) $percentComplete% ($index of $totalProjects)..."
        Write-Output "***********************************************************"
        $index++

        if ($project.empty_repo -or $project.repository_access_level -eq "disabled" -or $project.statistics.repository_size -lt 104857600) {
            continue
        }

        $files = Get-ChildItem $workDirectory -Filter "*.json"

        $projectsProcessed = New-Object System.Collections.Generic.List[int]

        foreach ($file in $files) {
            $projectsProcessed.Add([int]::Parse($file.BaseName))
        }
        # Temporary Conditions
        if($project.id -eq 4132 -or $project.id -eq 250 -or $projectsProcessed.Contains($project.id)) {
            continue
        }

        $bareCloneFolder = Join-Path $workDirectory $project.id

        Write-Output "Performing bare clone..."
        git clone --bare $project.ssh_url_to_repo $project.id

        Set-Location $bareCloneFolder

        Write-Output "Performing analysis..."
        git filter-repo --analyze
               
        $blobShasAndPaths = Get-Content -Path .\filter-repo\analysis\blob-shas-and-paths.txt

        $largeFiles = New-Object System.Collections.Generic.List[object]

        Write-Output "Parsing analysis output..."
        $lineNumber = 1
        foreach ($line in $blobShasAndPaths) {
            if ($lineNumber -le 2) {
                $lineNumber++
                continue
            }

            $line -match $pattern | Out-Null

            $sha = $matches[1]
            $unpackedSize = $matches[2]
            $packedSize = $matches[3]
            $path = $matches[4]

            $fileSizeInMb = [double]::Parse($unpackedSize) / 1048576

            if ($fileSizeInMb -ge 100.0) {
                $largeFiles.Add([PSCustomObject]@{
                        Sha          = $sha
                        UnpackedSize = $unpackedSize
                        PackedSize   = $packedSize
                        Path         = $path
                    })
            }
        }

        $projectLargeFiles = [PSCustomObject]@{
            ProjectId = $project.id
            Files     = $largeFiles
        }

        $projectFileSizes.Add($projectLargeFiles)

        $file = Join-Path $workDirectory "$($project.id).json"

        $projectLargeFiles | ConvertTo-Json -Depth 10 | Out-File $file

        Set-Location $workDirectory

        Write-Output "Removing bare clone..."
        Remove-Item $bareCloneFolder -Recurse -Force
    }

    Write-Output "Saving analysis..."

    $projectFileSizes | ConvertTo-Json -Depth 10 | Out-File $outputFile
}

end {
    Set-Location $currentPath
}