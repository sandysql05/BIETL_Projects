<# 
.SYNOPSIS
Export Power BI Embed Codes

.DESCRIPTION
The sample scripts are not supported under any Microsoft standard support program or service. 
The sample scripts are provided AS IS without warranty of any kind. 
Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of 
fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation 
remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of 
the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the 
sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages. 
#>

function Export-PbiEmbedCodes{
    param(
        [hashtable]$Config
    )

    Write-AssessmentLog "Exporting Embed Codes..." -Config $Config

    $clusterResponse = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/metadata/cluster" | ConvertFrom-Json
    $clusterUri = $clusterResponse.backendUrl
    $embedCodesUri = $clusterUri + "snapshots/embed/reports/tenantAdmin/interactive/"

    $headers = @{
        "Authorization" = $Config.AuthToken;
        "X-PowerBI-User-Admin" = $true
    }
    $data = Invoke-RestMethod -Headers $headers -Uri $embedCodesUri
    return $data | ForEach-Object { New-Object PSObject -Property @{ 
            snapshotName = $_.snapshotName; 
            workspaceName = $_.workspaceName;  
            publisherUserName = $_.publisherUserName;
            disabledByUser = $_.disabledByUser;
            createDate = $_.createDate;
            lastRefreshTime = $_.lastRefreshTime;
        } }
}