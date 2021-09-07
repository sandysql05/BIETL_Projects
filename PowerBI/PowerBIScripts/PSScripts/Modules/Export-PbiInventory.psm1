<# 
.SYNOPSIS
Export Power BI Inventory

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

function Export-PbiInventory {
    param(
        [hashtable]$Config
    )
    Write-AssessmentLog "Exporting Inventory..." -Config $Config

    $workspaces = @()
    $datasets = @()
    $datasources = @()
    $dfdatasources = @()
    $dashboards = @()
    $reports = @()
    $users = @()
    $dataflows = @()
        
    $batch = 0
    $batchSize = 500
        
    #Get workspaces with reports, datasets, and dashboards
    while ($True) {
        $skip = $batch * $batchSize
        $workspaceBatch = Invoke-PowerBIRestMethod -Method Get  -Url "$($Config.ApiGatewayUri)/v1.0/myorg/admin/groups?`$skip=$skip&`$top=$batchSize&`$expand=reports,dashboards,datasets,dataflows,users" | ConvertFrom-Json        
        $totalWorkspaces = $workspaceBatch.'@odata.count'
                
        if ($workspaceBatch.value.Count -gt 0) {
            $workspaces += $workspaceBatch.value | Select-Object * -ExcludeProperty @("reports", "dashboards", "datasets")   
                
            #Select workspace users from the workspace objects
            $users += $workspaceBatch.value | Where-Object { $_.users.Count -gt 0 } `
            | Select-Object @{Name = "workspaceId"; Expression = { $_.Id } }, @{Name = "users"; Expression = { $_.users | Select-Object * -ExcludeProperty WorkspaceId } } `
            | Select-Object * -ExpandProperty users -ExcludeProperty users

            #Select reports from the workspace objects
            $reports += $workspaceBatch.value | Where-Object { $_.reports.Count -gt 0 } `
            | Select-Object @{Name = "workspaceId"; Expression = { $_.Id } }, @{Name = "reports"; Expression = { $_.reports | Select-Object * -ExcludeProperty WorkspaceId } } `
            | Select-Object * -ExpandProperty reports -ExcludeProperty reports
        
            #Select dashboards from the workspace objects
            $dashboards += $workspaceBatch.value | Where-Object { $_.dashboards.Count -gt 0 } `
            | Select-Object @{Name = "workspaceId"; Expression = { $_.Id } }, @{Name = "dashboards"; Expression = { $_.dashboards | Select-Object * -ExcludeProperty WorkspaceId } } `
            | Select-Object * -ExpandProperty dashboards -ExcludeProperty dashboards

            #Select datasets from the workspace objects
            $datasets += $workspaceBatch.value | Where-Object { $_.datasets.Count -gt 0 } `
            | Select-Object @{Name = "workspaceId"; Expression = { $_.Id } }, @{Name = "datasets"; Expression = { $_.datasets | Select-Object * -ExcludeProperty WorkspaceId } } `
            | Select-Object * -ExpandProperty datasets -ExcludeProperty datasets            
                
            #Select dataflows from the workspace objects
            $dataflows += $workspaceBatch.value | Where-Object { $_.dataflows.Count -gt 0 } `
            | Select-Object @{Name = "workspaceId"; Expression = { $_.Id } }, @{Name = "dataflows"; Expression = { $_.dataflows | Select-Object * -ExcludeProperty WorkspaceId } } `
            | Select-Object * -ExpandProperty dataflows -ExcludeProperty dataflows            

            Write-Progress -Activity "Retreiving $totalWorkspaces workspaces" -PercentComplete ($batch * $batchSize * 100.0 / $totalWorkspaces)
            $batch = $batch + 1            
        }
        else {
            break
        }
    }        
        
    #save all of the workspaces in use in the organization
    $workspaces | Select-Object -ExcludeProperty "Users" *, @{n = "Users"; e = { $_.Users | ConvertTo-Csv -NoTypeInformation -Delimiter ":" } } `
    | Select-Object @{Name = "Id"; Expression = { $_.Id } }, @{Name = "Name"; Expression = { $_.Name } }, @{Name = "IsReadOnly"; Expression = { $_.IsReadOnly } }, @{Name = "IsOnDedicatedCapacity"; Expression = { $_.IsOnDedicatedCapacity } }, @{Name = "CapacityId"; Expression = { $_.CapacityId } }, @{Name = "Description"; Expression = { $_.Description } }, @{Name = "Type"; Expression = { $_.Type } }, @{Name = "State"; Expression = { $_.State } }, @{Name = "IsOrphaned"; Expression = { [string]::IsNullOrEmpty($_.Users) } }, @{Name = "Users"; Expression = { $_.Users } } `
    | Add-AssessmentRecords -SinkContainer "Workspaces" -Config $Config


    if ($Config.ExportV1Users) {
        $v1Workspaces = $workspaces | Where-Object { $_.Type -eq "Group" }
        $totalV1Workspaces = $v1Workspaces.Count        
        $workspaceCounter = 0
        $pref = $ErrorActionPreference
        $ErrorActionPreference = "silentlycontinue"
        $v1Workspaces | ForEach-Object {   
            $currentWorkspaceId = $_.Id
                
            $members = Get-AzureADGroupMember -ObjectId $currentWorkspaceId -ErrorAction SilentlyContinue 2>$null

            $users += $members | Select-Object `
            @{Name = "workspaceId"; Expression = { $currentWorkspaceId } }, `
            @{Name = "emailAddress"; Expression = { $_.userPrincipalName } }, `
            @{Name = "groupUserAccessRight"; Expression = { $_.UserType } }, `
            @{Name = "identifier"; Expression = { $_.userPrincipalName } }, `
            @{Name = "displayName"; Expression = { $_.displayName } }, `
            @{Name = "principalType"; Expression = { "User" } }

            Write-Progress -Activity "Retreiving users from $totalV1Workspaces v1 workspaces. To skip this step, set `$ExportV1Users to `$False and rerun the script" -PercentComplete ($workspaceCounter * 100.0 / $totalV1Workspaces)
            $workspaceCounter += 1
        } 
        $ErrorActionPreference = $pref
    }
    else {
        Write-AssessmentLog "ExportV1Users is False. Skipping..." -Config $Config
    }

    #save all of the workspace users in the organization
    $users | Select-Object @{Name = "workspaceId"; Expression = { $_.workspaceId } }, @{Name = "emailAddress"; Expression = { $_.emailAddress } }, @{Name = "groupUserAccessRight"; Expression = { $_.groupUserAccessRight } }, @{Name = "identifier"; Expression = { $_.identifier } }, @{Name = "principalType"; Expression = { $_.principalType } }, @{Name = "displayName"; Expression = { $_.displayName } } `
    | Add-AssessmentRecords -SinkContainer "WorkspaceUsers" -Config $Config

    #save all of the datasets in use in the organization
    $datasets | Select-Object @{Name = "Id"; Expression = { $_.Id } }, @{Name = "Name"; Expression = { $_.Name } }, @{Name = "ConfiguredBy"; Expression = { $_.ConfiguredBy } }, @{Name = "DefaultRetentionPolicy"; Expression = { $_.DefaultRetentionPolicy } }, @{Name = "AddRowsApiEnabled"; Expression = { $_.AddRowsApiEnabled } }, @{Name = "Tables"; Expression = { $_.Tables } }, @{Name = "WebUrl"; Expression = { $_.WebUrl } }, @{Name = "Relationships"; Expression = { $_.Relationships } }, @{Name = "Datasources"; Expression = { $_.Datasources } }, @{Name = "DefaultMode"; Expression = { $_.DefaultMode } }, @{Name = "IsRefreshable"; Expression = { $_.IsRefreshable } }, @{Name = "IsEffectiveIdentityRequired"; Expression = { $_.IsEffectiveIdentityRequired } }, @{Name = "IsEffectiveIdentityRolesRequired"; Expression = { $_.IsEffectiveIdentityRolesRequired } }, @{Name = "IsOnPremGatewayRequired"; Expression = { $_.IsOnPremGatewayRequired } }, @{Name = "WorkspaceId"; Expression = { $_.WorkspaceId } } `
    | Add-AssessmentRecords -SinkContainer "Datasets" -Config $Config
                
    #save all of the dataflows in use in the organization
    $dataflows | Select-Object @{Name = "Id"; Expression = { $_.objectId } }, @{Name = "Name"; Expression = { $_.name } }, @{Name = "ConfiguredBy"; Expression = { $_.configuredBy } }, @{Name = "Description"; Expression = { $_.description } }, @{Name = "ModelUrl"; Expression = { $_.modelUrl } }, @{Name = "ModifiedBy"; Expression = { $_.modifiedBy } }, @{Name = "ModifiedDateTime"; Expression = { $_.modifiedDateTime } }, @{Name = "WorkspaceId"; Expression = { $_.WorkspaceId } } `
    | Add-AssessmentRecords -SinkContainer "DataFlows" -Config $Config
        
    #save all of the dashboard in the organization
    $dashboards | Select-Object @{Name = "Id"; Expression = { $_.Id } }, @{Name = "displayName"; Expression = { $_.displayName } }, @{Name = "IsReadOnly"; Expression = { $_.IsReadOnly } }, @{Name = "EmbedUrl"; Expression = { $_.EmbedUrl } }, @{Name = "WorkspaceId"; Expression = { $_.WorkspaceId } } `
    | Add-AssessmentRecords -SinkContainer "Dashboards" -Config $Config

    #save all of the reports in the organization
    $reports | Select-Object @{Name = "Id"; Expression = { $_.Id } }, @{Name = "ReportType"; Expression = { $_.ReportType } }, @{Name = "Name"; Expression = { $_.Name } }, @{Name = "DatasetId"; Expression = { $_.DatasetId } }, @{Name = "WorkspaceId"; Expression = { $_.WorkspaceId } } `
    | Add-AssessmentRecords -SinkContainer "Reports" -Config $Config

    #Iterate datasets / dataflows to extract datasources
    if ($Config.ExportDatasources) {
        $totalDatasets = $datasets.Count        
        $datasetCounter = 0
        $datasets | ForEach-Object {     
            $currentDatasetId = $PSItem.id
            $currentWorkspaceId = $PSItem.workspaceId
            $datasetDatasources = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/v1.0/myorg/admin/datasets/$currentDatasetId/datasources" -ErrorAction SilentlyContinue | ConvertFrom-Json 
            $datasources += $datasetDatasources.value | Select-Object *, @{ Name = "DatasetId"; Expression = { $currentDatasetId } }, @{ Name = "WorkspaceId"; Expression = { $currentWorkspaceId } }

            Write-Progress -Activity "Retreiving datasources from $totalDatasets datasets. To skip this step, set ExportDatasources to `$False and rerun the script" -PercentComplete ($datasetCounter * 100.0 / $totalDatasets)
            $datasetCounter += 1

            #save all of the data sources in use in the organization. remember there can be multiple data sources per dataset
            #https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets_getdatasourcesasadmin#code-try-0
            $datasources | Select-Object @{Name = "Name"; Expression = { $_.Name } }, @{Name = "ConnectionString"; Expression = { $_.ConnectionString } }, @{Name = "DatasourceType"; Expression = { $_.DatasourceType } }, @{Name = "ConnectionDetails"; Expression = { $_.ConnectionDetails } }, @{Name = "GatewayId"; Expression = { $_.GatewayId } }, @{Name = "DatasourceId"; Expression = { $_.DatasourceId } }, @{Name = "WorkspaceId"; Expression = { $_.WorkspaceId } }, @{Name = "DatasetId"; Expression = { $_.DatasetId } } `
            | Add-AssessmentRecords -SinkContainer "Datasources" -Config $Config
        }

        #Dataflows Data Sources 
        $totalDataflows = $dataflows.Count        
        $dataflowCounter = 0
        $dataflows | ForEach-Object {     
            $currentDataflowId = $PSItem.objectId
            $currentWorkspaceId = $PSItem.workspaceId
            $dataflowDatasources = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/v1.0/myorg/admin/dataflows/$currentDataflowId/datasources" -ErrorAction SilentlyContinue | ConvertFrom-Json 
            $dfdatasources += $dataflowDatasources.value | Select-Object *, @{ Name = "DataflowId"; Expression = { $currentDataflowId } }, @{ Name = "WorkspaceId"; Expression = { $currentWorkspaceId } }

            Write-Progress -Activity "Retreiving datasources from $totalDataflows dataflows. To skip this step, set ExportDatasources to `$False and rerun the script" -PercentComplete ($dataflowCounter * 100.0 / $totalDataflows)
            $dataflowCounter += 1

            #save all of the data sources in use in the organization. remember there can be multiple data sources per dataset
            #https://docs.microsoft.com/en-us/rest/api/power-bi/admin/dataflows_getdatasourcesasadmin#code-try-0
            $dfdatasources | Select-Object @{Name = "Name"; Expression = { $_.Name } }, @{Name = "ConnectionString"; Expression = { $_.ConnectionString } }, @{Name = "DatasourceType"; Expression = { $_.DatasourceType } }, @{Name = "ConnectionDetails"; Expression = { $_.ConnectionDetails } }, @{Name = "GatewayId"; Expression = { $_.GatewayId } }, @{Name = "DatasourceId"; Expression = { $_.DatasourceId } }, @{Name = "WorkspaceId"; Expression = { $_.WorkspaceId } }, @{Name = "DataflowId"; Expression = { $_.DataflowId } } `
            | Add-AssessmentRecords -SinkContainer "DataflowDatasources" -Config $Config
        } 
    }
    else {
        Write-AssessmentLog "ExportDatasources is False. Skipping..." -Config $Config
    }


    if ($Config.ExportRefreshes) {
        $TopN = 50
        $hists = @()

        $totalDatasets = $datasets.Count
        $datasetIndex = 0
        $datasets | ForEach-Object { 
            $hist = New-Object PSObject
            if ($PSItem.IsRefreshable -eq "True") {
                $hist = Invoke-PowerBIRestMethod -Method Get -Url "$($Config.ApiGatewayUri)/v1.0/myorg/groups/$($PSItem.workspaceId)/datasets/$($PSItem.id)/refreshes/?`$top=$($TopN)" -ErrorAction SilentlyContinue | ConvertFrom-Json
                if ($hist) {
                    $hist.value | Add-Member -NotePropertyName "DatasetID" -NotePropertyValue $PSItem.id
                    $hist.value | Add-Member -NotePropertyName "DatasetName" -NotePropertyValue $PSItem.name
                    $hist.value | Add-Member -NotePropertyName "WorkspaceID" -NotePropertyValue $PSItem.workspaceId
                }
                $hists += $hist
            }
            $datasetIndex += 1
            Write-Progress -Activity "Retreiving refresh history for $totalDatasets datasets. To skip this step, set ExportRefreshes to `$False and rerun the script" -PercentComplete ($datasetIndex * 100.0 / $totalDatasets)
        }
          
        $hists.value | ForEach-Object { 
            New-Object PSObject -Property @{ 
                id                   = $_.id; 
                refreshType          = $_.refreshType;  
                startTime            = $_.startTime;
                endTime              = $_.endTime;
                serviceExceptionJson = $_.serviceExceptionJson;
                status               = $_.status;
                DatasetID            = $_.DatasetID;
                WorkspaceID          = $_.WorkspaceID;
                DatasetName          = $_.DatasetName;
            } 
        } | Add-AssessmentRecords -SinkContainer "RefreshHistory" -Config $Config
        
    }
    else {
        Write-AssessmentLog "ExportRefreshes is False. Skipping..." -Config $Config
    }
}