<# 
.SYNOPSIS
Export Power BI Activity Logs

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

function Export-PbiActivityLog {
    param(
        [hashtable]$Config
    )

    if ($Config.ExportActivityLog) {
        Write-AssessmentLog "Exporting Audit Log for $($Config.AuditLogDays) days..." -Config $Config

        #################################### Configuration Section ###################################################
        #[DateTime]$start = Get-Date #"1/4/19 03:59"
        #[DateTime]$end = Get-Date.AddDays(-90) #"1/5/19 03:59"
        # Define dates for search. MSFT claims Windows short date format on the machine running the script should be used, but test proved "MM/dd/yyyy" must be used
        [DateTime]$start = (get-date).AddDays(-$Config.AuditLogDays - 1).Date
        [DateTime]$end = (get-date).AddDays(-1).Date
        #################################### End Configuration Section ###################################################

        [DateTime]$currentStart = $start
        [DateTime]$currentEnd = $start

        $totalDays = ($end - $start).TotalDays
        $continueToNextInterval = $True
        while ($continueToNextInterval) {

            if ($Config.LastTokenUpdateTime -lt (Get-Date).AddMinutes(-50)) {
                # Building Rest API header with authorization token
                $auth_header = @{
                    'Content-Type'  = 'application/json'
                    'Authorization' = Get-PowerBIAccessToken -AsString
                }
                $Config.LastTokenUpdateTime = Get-Date
            }

            $currentEnd = $currentStart.AddHours($Config.AuditLogBatchHours).AddSeconds(-1)
            $processingDay = [Math]::Round(($currentStart - $start).totalDays, 0) + 1

            Write-Progress -Activity "Exporting audit log" -Status "Retrieving logs for $($currentStart.ToString("yyyy-MM-dd")) - Day $($processingDay)/$($totalDays)" -PercentComplete (($processingDay - 1) * 100.0 / $totalDays)

            if ($currentEnd -gt $end ) {
                break
            }

            Write-AssessmentLog "Retrieving audit logs for $($currentStart)" -Config $Config
            $currentCount = 0
            
            $uri_auditlog = "$($Config.ApiGatewayUri)/v1.0/myorg/admin/activityevents?startDateTime=%27$($currentStart.ToString("yyyy-MM-ddTHH:mm:ssZ"))%27&endDateTime=%27$($currentEnd.ToString("yyyy-MM-ddTHH:mm:ssZ"))%27"
            $queryError = $null
            $response = (Invoke-RestMethod -Uri $uri_auditlog -Headers $auth_header -Method GET -ErrorVariable queryError)
            if ($null -eq $response) {
                $continueToNextInterval = $false
                $currentOffset = [Math]::Ceiling(((get-date) - $currentEnd).TotalDays)
                Write-AssessmentLog "Audit logs query failed for $($currentStart). Stopping at offset $($currentOffset)" -Config $Config -IsError
                Write-AssessmentLog $queryError -Config $Config
                break
            }
            $all_auditlog = $response.ActivityEventEntities
            $continuationToken = $response.continuationToken

            while (![string]::IsNullOrEmpty($continuationToken)) {
                $uri_innerresponse = $response.continuationUri
                $response = (Invoke-RestMethod -Uri $uri_innerresponse -Headers $auth_header -Method GET)
                if ($null -eq $response) {
                    $continueToNextInterval = $false
                    $currentOffset = [Math]::Ceiling(((get-date) - $currentEnd).TotalDays)
                    Write-AssessmentLog "Audit log contuniation token query failed for $($currentStart). Stopping at offset $($currentOffset)" -Config $Config -IsError
                    Write-AssessmentLog $queryError -Config $Config
                    break
                }
                
                $all_auditlog += $response.activityEventEntities   
                $currentCount = $all_auditlog.Count
                $message = "Retrieved $($currentCount) records with token: $($continuationToken)"
                Write-AssessmentLog $message -Config $Config 
                $continuationToken = $response.continuationToken
            }

            # Required in order to make a structured list to iterate over to include all fields. 
            $CsvObjects = @()       
            foreach ($activity in $all_auditlog) {

                $CsvObject = [PSCustomObject]@{
                    Id                                = $activity.Id 					
                    RecordType                        = $activity.RecordType 			 
                    CreationTime                      = $activity.CreationTime      
                    Operation                         = $activity.Operation         
                    OrganizationId                    = $activity.OrganizationId    
                    UserType                          = $activity.UserType          
                    UserKey                           = $activity.UserKey           
                    Workload                          = $activity.Workload          
                    UserId                            = $activity.UserId            
                    ClientIP                          = $activity.ClientIP          
                    UserAgent                         = $activity.UserAgent         
                    Activity                          = $activity.Activity          
                    ItemName                          = $activity.ItemName          
                    WorkSpaceName                     = $activity.WorkSpaceName     
                    DatasetName                       = $activity.DatasetName       
                    ReportName                        = $activity.ReportName        
                    CapacityId                        = $activity.CapacityId        
                    CapacityName                      = $activity.CapacityName      
                    WorkspaceId                       = $activity.WorkspaceId       
                    AppName                           = $activity.AppName           
                    ObjectId                          = $activity.ObjectId          
                    DatasetId                         = $activity.DatasetId         
                    ReportId                          = $activity.ReportId          
                    IsSuccess                         = $activity.IsSuccess         
                    ReportType                        = $activity.ReportType        
                    RequestId                         = $activity.RequestId         
                    ActivityId                        = $activity.ActivityId        
                    AppReportId                       = $activity.AppReportId       
                    DistributionMethod                = $activity.DistributionMethod
                    ConsumptionMethod                 = $activity.ConsumptionMethod 
                    TableName                         = $activity.TableName
                    DashboardName                     = $activity.DashboardName
                    DashboardId                       = $activity.DashboardId 
                    Datasets                          = ($activity.Datasets | ConvertTo-Json)
                    EmbedTokenId                      = $activity.EmbedTokenId
                    CustomVisualAccessTokenResourceId = $activity.CustomVisualAccessTokenResourceId
                    CustomVisualAccessTokenSiteUri    = $activity.CustomVisualAccessTokenSiteUri
                    DataConnectivityMode              = $activity.DataConnectivityMode
                }
                $CsvObjects += $CsvObject
            }

            $fileTag = $currentStart.ToString("yyyyMMddHH") + "-"
            $CsvObjects | Add-AssessmentRecords -SinkContainer "AuditRecords" -FileTag $fileTag -Config $Config
            
            $message = "Successfully retrieved $($currentCount) records for the current time range. Moving on."
            Write-AssessmentLog $message -Config $Config
                
            $currentStart = $currentEnd.AddSeconds(1)
        }
    }
    else {
        Write-AssessmentLog "ExportActivityLog is False. Skipping..." -Config $Config
    }
}