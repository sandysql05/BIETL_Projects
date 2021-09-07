<# 
.SYNOPSIS
Export Power BI Licenses

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

function Export-PbiDataflow{
    param(
        [hashtable]$Config
    )

    Write-AssessmentLog "Exporting Dataflow..." -Config $Config

	$Dataflow = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/v1.0/myorg/admin/dataflows?" | ConvertFrom-Json
	
    if($Dataflow.value.length -gt 0){
        return $Dataflow.value | 
            Select-Object 
				@{Name = "objectId"; Expression={ $_.objectId}}, `
                @{Name = "name"; Expression={ $_.name}}, `
                @{Name = "modelUrl"; Expression={ $_.modelUrl}}, `
                @{Name = "configuredBy"; Expression={ $_.configuredBy}}
    }else{
        Write-AssessmentLog "No Dataflow found" -Config $Config
        return @{objectId="";name="";modelUrl="";configuredBy="";}  
    }
}