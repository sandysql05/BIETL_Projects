<# 
.SYNOPSIS
Export Power BI Dev Tokens Status

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

function Export-PbiDevTokensStatus{
    param(
        [hashtable]$Config
    )

    Write-AssessmentLog "Exporting Dev Token Status..." -Config $Config

    $features = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/v1.0/myorg/availableFeatures" | 
        ConvertFrom-Json

    return $features.features | 
        Where-Object { return $_.name -eq "embedTrial" } | 
        ForEach-Object { $_.additionalInfo }
}