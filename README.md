# GitLab Analysis
These PowerShell scripts are designed to collect details of projects with in a GitLab instance (cloud or server).
The scripts integrate the API via an access token of the specified GitLab instance to collect metadata about the projects.
It is important that the specified access token has access to all projects in order to do a proper analysis.
The scripts must be specified in a specific sequence as the metadata is saved locally and reused to improve the speed of the analyis.

## Prerequisites
- PowerShell v7: https://github.com/PowerShell/PowerShell/releases <br />
While PowerShell 5 may work, All scripts have been tested with PowerShell 7 and we cannot gurantee PowerShell 5 will work as expected.
- Git: https://git-scm.com/download <br />
Must have at least v2.22.0 installed
- Python 3: https://www.python.org/downloads/ <br />
- git filter-repo: https://github.com/newren/git-filter-repo <br />

## Collecting the Data
The first step in the analysis process is to collect the data and save it locally.
This is done to reduce the number of API calls and avoid potential throttling issues.
As stated above, the scripts must be executied in a specific order.
The first step is to collect the necessary metadata to perform the analysis.
To do so, the following scripts must be executed in the order listed below:

1. `Get-GitLabNamespaces.ps1` <br />
Collects the namespaces within GitLab and saves it to `namespaces.json`
1. `Get-GitLabProjects.ps1` <br />
Collects the projects within GitLab and saves it to `projects.json`
1. `Get-GitLabCommitActivity.ps1` <br />
Collects the number of commits for all projects in GitLab for a given time period and saves it to `project-commits.json`
1. `Get-GitLabBranchMergeRequests.ps1` <br />
Collects summary details of open branches and merge requests in GitLab and saves it to `project-branch-merge-requests.json`

## Performing Analysis
Once the data collection is complete, we can begin the analysis process.
There are three additional scripts to execute which will generate the full analysis of the GitLab instance.
The following scripts must be executed in the order specified:

1. `Invoke-GitLabAnalysis.ps1` <br />
This parse all of the created JSON files and organize the data into a CSV file which is then imported into a Power BI report
1. `Invoke-GitFilterReportAnalysis.ps1` <br />
This is an optional, as it will perform a bare clone of every repository, but highly recommended.
This will perform a detailed analysis of each repository and capturing details of the largest files in the repository.
This is a critical information as GitHub does not accept a commit where a files is over 100MB in size.
1. `Invoke-ProjectLargeFilesAnalysis.ps1`
Only execute this script if you have executed `Invoke-GitFilterReportAnalysis.ps1`.
The execution of this script will parse the output from `Invoke-GitFilterReportAnalysis.ps1` and create a `project-large-files.json`.
This will contain only repositories that have large files which can be problemmatic for a migration.

## Script Reference

<!-- Begin Get-GitLabBranchMergeRequests.ps1 -->
### `Get-GitLabBranchMergeRequests.ps1`

#### Pre-Execution Conditions
- Must have successfully run `Get-GitLabProjects.ps1`

#### Parameters
|Input|Summary|Constraints|
|-----|-------|-----------|
|`GitLabUrl`|The base URL to access the GitLab API from. The `api/v4` will automatically be added to the end of the URL.|None|
|`AccessToken`|The access token to use when authenticating against the GitLab API.| Must have the ability to read all projects and merge requests.|

#### Outputs
- The file `project-branch-merge-requests.json` in working location of the command prompt
<!-- End Get-GitLabBranchMergeRequests.ps1 -->

<!-- Begin Get-GitLabCommitActivity.ps1 -->
### `Get-GitLabCommitActivity.ps1`

#### Pre-Execution Conditions
- Must have successfully run `Get-GitLabProjects.ps1`

#### Parameters
|Input|Summary|Constraints|
|-----|-------|-----------|
|`GitLabUrl`|The base URL to access the GitLab API from. The `api/v4` will automatically be added to the end of the URL.|None|
|`StartDateTime`|The start date to fetch commits for. Typically, we recommend to pull commits in the last year.|None|
|`EndDateTime`|The end date to fetch commits for. Typically, we recommend this to be the date of execution.|None|
|`AccessToken`|The access token to use when authenticating against the GitLab API.| Must have the ability to read all projects and repository commits.|

#### Outputs
- The file `project-commits.json` in working location of the command prompt
<!-- End Get-GitLabCommitActivity.ps1 -->

<!-- Begin Get-GitLabNamespaces.ps1 -->
### `Get-GitLabNamespaces.ps1`

#### Pre-Execution Conditions
- None

#### Parameters
|Input|Summary|Constraints|
|-----|-------|-----------|
|`GitLabUrl`|The base URL to access the GitLab API from. The `api/v4` will automatically be added to the end of the URL.|None|
|`AccessToken`|The access token to use when authenticating against the GitLab API.| Must have the ability to read all  namespaces.|

#### Outputs
- The file `namespaces.json` in working location of the command prompt
<!-- End Get-GitLabNamespaces.ps1 -->

<!-- Begin Get-GitLabProjects.ps1 -->
### `Get-GitLabProjects.ps1`

#### Pre-Execution Conditions
- None

#### Parameters
|Input|Summary|Constraints|
|-----|-------|-----------|
|`GitLabUrl`|The base URL to access the GitLab API from. The `api/v4` will automatically be added to the end of the URL.|None|
|`AccessToken`|The access token to use when authenticating against the GitLab API.| Must have the ability to read all projects.|

#### Outputs
- The file `projects.json` in working location of the command prompt
<!-- End Get-GitLabProjects.ps1 -->

<!-- Begin Invoke-GitFilterRepoAnalysis.ps1 -->
### `Invoke-GitFilterRepoAnalysis.ps1`

#### Pre-Execution Conditions
- Must have successfully run `Get-GitLabProjects.ps1`
- Must have Git installed
- Must have Python 3 installed
- Must have Git filter-repo installed

#### Parameters
__None__

#### Outputs
- A JSON file for each project with the project ID as the name of the file in the `_work` relative to the terminal path
<!-- End Invoke-GitFilterRepoAnalysis.ps1 -->

<!-- Begin Invoke-GitLabAnalysis.ps1 -->
### `Invoke-GitLabAnalysis.ps1`

#### Pre-Execution Conditions
- Must have successfully run `Get-GitLabProjects.ps1`
- Must have successfully run `Get-GitLabCommitActivity.ps1`

#### Parameters
__None__

#### Outputs
- The file `project-summary.csv` in working location of the command prompt
<!-- End Invoke-GitLabAnalysis.ps1 -->

<!-- Begin Invoke-ProjectLargeFilesAnalysis.ps1 -->
### `Invoke-ProjectLargeFilesAnalysis.ps1`

#### Pre-Execution Conditions
- Must have successfully run `Get-GitLabProjects.ps1`
- Must have successfully run `Get-GitLabCommitActivity.ps1`
- Must have successfully run `Invoke-GitFilterRepoAnalysis.ps1`

#### Parameters
__None__

#### Outputs
- The file `project-large-files.json` in working location of the command prompt
<!-- End Invoke-ProjectLargeFilesAnalysis.ps1 -->
