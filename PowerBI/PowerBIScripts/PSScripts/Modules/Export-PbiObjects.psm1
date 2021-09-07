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

function Export-PbiObjects {
    param(
        [hashtable]$Config
    )

    if ($Config.ExportTenantSettings) {
        # Export Tenant Name
        Write-AssessmentLog "Exporting Tenant Name" -Config $Config
        $Tenant = New-Object -TypeName PSObject -Property @{TenantDomain = (New-Object MailAddress $Config.AuthContext.UserName).Host }
        $Tenant | Add-AssessmentRecords -SinkContainer "PowerBITenant" -Config $Config

        # Export the tenant settings via the Export-PbiTenantSettings module
        Export-PbiTenantSettings -Config $Config | Add-AssessmentRecords -SinkContainer "TenantSettings" -Config $Config
        # Export the embed codes via the Export-PbiEmbedCodes module
        Export-PbiEmbedCodes -Config $Config | Add-AssessmentRecords -SinkContainer "EmbedCodes" -Config $Config
        # Export any dev tokens and their status
        Export-PbiDevTokensStatus -Config $Config | Add-AssessmentRecords -SinkContainer "DevTokens" -Config $Config
        # Export any gateways
        Export-PbiGateways -Config $Config | Add-AssessmentRecords -SinkContainer "Gateways" -Config $Config
    }
    else {
        Write-AssessmentLog "ExportTenantSettings is False. Skipping..." -Config $Config
    }

    if (-not $Config.ExportPremium) {
        Write-AssessmentLog "ExportPremium is False. Skipping..." -Config $Config
    }
    $proceedPremium = $Config.ExportPremium

    # Export premium specific metrics. this connects to the underlying SSAS database that powers the workspace and exports the data
    # DAX Queries to query against PowerBI. Should not need changed.
    IF ($proceedPremium) { 
        Export-PbiPremiumData -DAXQuery "EVALUATE SUMMARIZE (DatasetInfo, DatasetInfo[id], DatasetInfo[datasetName], DatasetInfo[workspaceId])" -SinkContainer "PremiumDatasetInfo" -Config $Config `
        | Add-AssessmentRecords -SinkContainer "PremiumDatasetInfo" -Config $Config
    }
    IF ($proceedPremium) { 
        Export-PbiPremiumData -DAXQuery "EVALUATE SUMMARIZE (DatasetSize, DatasetSize[datasetId], DatasetSize[timestamp], ""datasetSizeInMB"", 'DatasetSize'[datasetSizeInMB] ,""ActiveDatasetsCountComputed"", [ActiveDatasetsCountComputed])" -SinkContainer "PremiumDataSetSize" -Config $Config `
        | Add-AssessmentRecords -SinkContainer "PremiumDataSetSize" -Config $Config
    }
    IF ($proceedPremium) { 
        Export-PbiPremiumData -DAXQuery "EVALUATE SUMMARIZE (Capacities, Capacities[capacityId], Capacities[capacityMemoryInGB], Capacities[capacityNumberOfVCores], Capacities[capacityPlan], Capacities[displayName], Capacities[region], Capacities[Owners])" -SinkContainer "PremiumCapacities" -Config $Config `
        | Add-AssessmentRecords -SinkContainer "PremiumCapacities" -Config $Config
    }
    IF ($proceedPremium) { 
        Export-PbiPremiumData -DAXQuery "EVALUATE SUMMARIZE (
            SystemMetrics, 
            SystemMetrics[capacityObjectId], 
            SystemMetrics[Timestamp],
            ""SystemMemoryConsumptionInGB"", [SystemMemoryConsumptionInGB],
            ""DatasetsMemoryConsumptionInGB"", [DatasetsMemoryConsumptionInGB],
            ""DataflowsMemoryConsumptionInGB"", [DataflowsMemoryConsumptionInGB],
            ""PaginatedReportsMemoryConsumptionInGB"", [PaginatedReportsMemoryConsumptionInGB],
            ""DatasetsCPUConsumption"", [DatasetsCPUConsumption],
            ""DataflowsCPUConsumption"", [DataflowsCPUConsumption],
            ""PaginatedReportsCPUConsumption"", [PaginatedReportsCPUConsumption],
            ""SystemCPUConsumption"", [SystemCPUConsumption])" -SinkContainer "PremiumSystemMetrics" -Config $Config `
        | Add-AssessmentRecords -SinkContainer "PremiumSystemMetrics" -Config $Config
    }
    IF ($proceedPremium) { 
        Export-PbiPremiumData -DAXQuery "EVALUATE SUMMARIZE (EvictionMetrics, EvictionMetrics[capacityObjectId], EvictionMetrics[timestamp], EvictionMetrics[activeModelCount], EvictionMetrics[inactiveModelCount], EvictionMetrics[averageIdleTimeBeforeEviction])" -SinkContainer "PremiumEvictionMetrics" -Config $Config `
        | Add-AssessmentRecords -SinkContainer "PremiumEvictionMetrics" -Config $Config
    }
    IF ($proceedPremium) { 
        Export-PbiPremiumData -DAXQuery "EVALUATE SUMMARIZE(QueryMetrics,
                'QueryMetrics'[timestamp],
                'QueryMetrics'[capacityObjectId],
                'QueryMetrics'[datasetId],
                ""SumtotalHighWaitCount"", SUM('QueryMetrics'[totalHighWaitCount]),
                ""SumtotalWaitCount"", SUM('QueryMetrics'[totalWaitCount]),
                ""SummaxWaitTime"", SUM('QueryMetrics'[maxWaitTime]),
                ""SummaxDuration"", SUM('QueryMetrics'[maxDuration]),
                ""SummaxCPUTime"", SUM('QueryMetrics'[maxCPUTime]),
                ""SumaverageWaitTime"", SUM('QueryMetrics'[averageWaitTime]),
                ""SumaverageDuration"", SUM('QueryMetrics'[averageDuration]),
                ""SumaverageCPUTime"", SUM('QueryMetrics'[averageCPUTime])
            )" -SinkContainer "PremiumQueryMetrics" -Config $Config `
        | Add-AssessmentRecords -SinkContainer "PremiumQueryMetrics" -Config $Config
    }
    IF ($proceedPremium) { 
        $fileName = [System.IO.Path]::Combine($Config.Sink, $SinkContainer)
        $fileName = "$fileName$($fileTag)PremiumRefresh$($Config.OutputTag).json"
        Export-PbiPremiumRefresh -SinkContainer "PremiumRefresh" -Config $Config | Out-File $fileName -Force
        Write-Host "Saving assessment records to CSV: " $fileName
    }

    IF ($Config.ExportInventory) {
        Export-PbiInventory -Config $Config
    }
    else {
        Write-AssessmentLog "ExportInventory is False. Skipping..." -Config $Config
    }

    IF ($Config.ExportLicenses) {
        Export-PbiLicenses -Config $Config
    }
    else {
        Write-AssessmentLog "ExportLicenses is False. Skipping..." -Config $Config
    }
}