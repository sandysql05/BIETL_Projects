<# 
.SYNOPSIS
Export Power BI Tenant Settings

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

function Export-PbiTenantSettings{
    param(
        [hashtable]$Config
    )

    Write-AssessmentLog "Exporting Tenant Settings..." -Config $Config

    $clusterResponse = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/metadata/cluster" | ConvertFrom-Json
    $clusterUri = $clusterResponse.backendUrl

    $headers = @{
        "Authorization" = $Config.AuthToken;
        "X-PowerBI-User-Admin" = $true
    }
    $uri = $clusterUri + "metadata/tenantsettings"
    $data = Invoke-RestMethod -Headers $headers -Uri $uri
    return $data.featureSwitches | ForEach-Object { New-Object PSObject -Property @{ 
            switchId = $_.switchId; 
            switchName = $_.switchName;  
            isEnabled = $_.isEnabled;
            isGranular = $_.isGranular;
            allowedSecurityGroups = [String]::Join(",", $_.allowedSecurityGroups )
            deniedSecurityGroups =[String]::Join(",", $_.deniedSecurityGroups)
        } }
}