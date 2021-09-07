<# 
.SYNOPSIS
Export Power BI Premium Data

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

function Export-PbiPremiumData{
    param(
        [string]$DAXQuery,
        [string]$SinkContainer,
        [hashtable]$Config
    )

    Write-AssessmentLog "Exporting Premium data to $SinkContainer..." -Config $Config

    $premiumAppDataset = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/v1.0/myorg/admin/datasets?`$filter=id eq '$($Config.PremiumDatasetId)'"  | 
        ConvertFrom-Json | 
        ForEach-Object { $_.value } |
        Select-Object -First 1

    $clusterResponse = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/metadata/cluster" | ConvertFrom-Json
    $clusterUri = $clusterResponse.backendUrl

    if($premiumAppDataset){        
        $tokenOnly = $Config.AuthToken.Replace("Bearer ", "")
        $resourceUri = $Config.ApiResourceUri.Replace("https", "pbiazure")
        $datasetId = $premiumAppDataset.id
        $cs = "Provider=MSOLAP;Data Source=$resourceUri/powerbi/api;Identity Provider=https://login.microsoftonline.com/common, $($Config.ApiResourceUri)/powerbi/api, $datasetId;Initial Catalog=$datasetId;Location=" + $clusterUri + "xmla?vs=sobe_wowvirtualserver&db=$datasetId;Password=$tokenOnly"
        $connection = New-Object System.Data.OleDb.OleDbConnection $cs
        $connection.Open()
        $command = New-Object System.Data.OleDb.OleDbCommand -ArgumentList $DAXQuery, $connection
        $rdr = $command.ExecuteReader()
        $result = New-Object System.Collections.ArrayList
        While($rdr.Read()){
            $properties = @{}
            For($fieldIndex = 0; $fieldIndex -lt $rdr.FieldCount; $fieldIndex ++){
                $properties[$rdr.GetName($fieldIndex)] = $rdr[$fieldIndex]
            }
            $row = New-Object PSObject -Property $properties
            $void = $result.Add($row)
        }
        $rdr.Close()
        $connection.Close()        
        return $result 
    }else{
        Write-AssessmentLog "Premium Capacity Metrics app not found. Please install the app and try again." -Config $Config -IsError
    }
    return $null
}