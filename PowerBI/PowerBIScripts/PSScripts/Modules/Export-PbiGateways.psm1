<# 
.SYNOPSIS
Export Power BI Gateways

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

function Export-PbiGateways{
    param(
        [hashtable]$Config
    )

    Write-AssessmentLog "Exporting Gateways..." -Config $Config

    $gateways = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/v2.0/myorg/gatewayClusters?`$expand=memberGateways" | 
        ConvertFrom-Json

    if($gateways.value.length -gt 0){

        return $gateways.value | 
            Select-Object @{Name = "clusterId"; Expression={ $_.id}}, `
                @{Name = "clusterName"; Expression={ $_.name}}, `
                @{Name = "type"; Expression={ $_.type}}, `
                @{Name = "cloudDatasourceRefresh"; Expression={ $_.options.CloudDatasourceRefresh}}, `
                @{Name = "customConnectors"; Expression={ $_.options.CustomConnectors}}, `
                @{Name = "memberGateways"; Expression={ $_.memberGateways | Select-Object * -ExcludeProperty clusterId,publicKey }} |
            Select-Object * -ExpandProperty memberGateways -ExcludeProperty memberGateways |
            Select-Object @{Name = "clusterId"; Expression={ $_.clusterId}}, `
                @{Name = "clusterName"; Expression={ $_.clusterName}}, `
                @{Name = "type"; Expression={ $_.type}}, `
                @{Name = "cloudDatasourceRefresh"; Expression={ $_.cloudDatasourceRefresh}}, `
                @{Name = "customConnectors"; Expression={ $_.customConnectors}}, `
                @{Name = "version"; Expression={ $_.version}}, `
                @{Name = "status"; Expression={ $_.status}}, `
                @{Name = "versionStatus"; Expression={ $_.versionStatus}}, `
                @{Name = "contactInformation"; Expression={ ($_.annotation | ConvertFrom-Json).gatewayContactInformation}}, `
                @{Name = "machine"; Expression={ ($_.annotation | ConvertFrom-Json).gatewayMachine}}, `
                @{Name = "nodeId"; Expression={ $_.id}} 


    }else{
        Write-AssessmentLog "No gateways found" -Config $Config

        return @{clusterId="";clusterName="";type="";version="";status="";versionStatus="";contactInformation="";machine="";nodeId="";}  
    }
}