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

function Export-PbiLicenses{
    param(
        [hashtable]$Config
    )

    Write-AssessmentLog "Exporting Licenses..." -Config $Config

    # Declare variables for export file paths, Power BI Pro service plan GUID, and current date
    $RetrieveDate = Get-Date 

    # MS Licensing Service Plan reference: https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/licensing-service-plan-reference
    $PBIProServicePlanID = "70d33638-9c74-4d01-bfd3-562de28bd4ba"

    # Retrieve and export users
    $ADUsers = Get-AzureADUser -All $true | Select-Object ObjectId, CompanyName, Department, DisplayName, UserPrincipalName, UserType, @{Name="Date Retrieved";Expression={$RetrieveDate}}

    0..($ADUsers.count-1) | foreach {
        $percent = ($_/$ADUsers.count)*100
        Write-Progress -Activity 'Retrieve and export users to CSV' -Status "$percent % Complete" -CurrentOperation "Exporting item # $($_+1)" -PercentComplete $percent
        $ADUsers[$_]
    } | Add-AssessmentRecords -SinkContainer "LicensesUsers" -Config $Config

    # Retrieve and export organizational licenses : https://docs.microsoft.com/en-us/office365/enterprise/powershell/view-licenses-and-services-with-office-365-powershell
    $OrgO365Licenses = Get-AzureADSubscribedSku | Select-Object SkuID, SkuPartNumber,CapabilityStatus, ConsumedUnits -ExpandProperty PrepaidUnits | `
        Select-Object SkuID,SkuPartNumber,CapabilityStatus,ConsumedUnits,Enabled,Suspended,Warning, @{Name="Retrieve Date";Expression={$RetrieveDate}} 

    0..($OrgO365Licenses.count-1) | foreach {
        $percent = ($_/$OrgO365Licenses.count)*100
        Write-Progress -Activity 'Retrieve and export organizational licenses to CSV' -Status "$percent % Complete" -CurrentOperation "Exporting item # $($_+1)" -PercentComplete $percent
        $OrgO365Licenses[$_]
    } | Add-AssessmentRecords -SinkContainer "LicensesOrgO365" -Config $Config


	 if($Config.ExportLicensesProDetail){
        Write-AssessmentLog "Exporting Licenses Pro details..." -Config $Config
		
		# Retrieve and export users with pro licenses based on Power BI Pro service plan ID ($PBIProServicePlanID). Each row represents a service plan for a particular user. This license detail is filtered to only the Power BI Pro service plan ID.
		$ProUsersCounter = 0
		$ProUsersCount = $ADUsers.Count 
		$UserLicenseDetail = ForEach ($ADUser in $ADUsers){
			$UserObjectID = $ADUser.ObjectId
			$UPN = $ADUser.UserPrincipalName
			Get-AzureADUserLicenseDetail -ObjectId $UserObjectID -ErrorAction SilentlyContinue | `
				Select-Object ObjectID, @{Name="UserPrincipalName";Expression={$UPN}} -ExpandProperty ServicePlans
			Write-Progress -Activity "Retreiving users Licenses, to skip set `$ExportLicensesProDetail to false and rerun the script" -PercentComplete ($ProUsersCounter * 100.0/$ProUsersCount)
			$ProUsersCounter += 1
		}
		$ProUsers = $UserLicenseDetail | Where-Object {$_.ServicePlanId -eq $PBIProServicePlanID}
		$ProUsers | Add-AssessmentRecords -SinkContainer "LicensesUsersPro" -Config $Config
	}else{
		Write-AssessmentLog "Export Licenses Pro details skipped" -Config $Config
	}
}