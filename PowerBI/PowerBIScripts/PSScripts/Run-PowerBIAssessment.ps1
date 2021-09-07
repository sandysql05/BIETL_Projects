<# 
.SYNOPSIS
Verify Power BI Assessment Pre-requesites

.DESCRIPTION
The sample scripts are not supported under any Microsoft standard support program or service. 
The sample scripts are provided AS IS without warranty of any kind. 
Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of 
fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation 
remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of 
the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the 
sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages. 

.INFO
“.\Run-PowerBIAssessment.ps1 default.config”.
#>

param (
    [string]$Config
)

Write-Host "Loading Power BI Assessment modules"

#import the powershell functions to run the rest of the script
$modulesFolder = "$PSScriptRoot\Modules"
 Get-Childitem $modulesFolder -Name -Filter "*.psm1" `
    | Sort-Object -Property @{ Expression = {if($_ -eq "Export-PbiObjects.psm1" -or $_ -eq "Export-PbiActivityLog.psm1"){"Z"}else{$_}}} `
    | ForEach-Object {
        $modulePath = "$modulesFolder\$_"
        Unblock-File $modulePath
        Import-Module $modulePath -Force
}

Write-Host "Installing Power BI management modules"
# Install any needed modules
Install-PbiAdminModules

Write-Host "Loading assessment configuration"
$assessmentConfig = Get-Configuration -Override $Config

if($assessmentConfig){
    
    Write-AssessmentLog "Running Microsoft Power BI Assessment..." -Config $assessmentConfig
    Write-AssessmentLog ($assessmentConfig | ConvertTo-Json) -Config $assessmentConfig -Silent

    Export-PbiObjects $assessmentConfig

    Export-PbiActivityLog $assessmentConfig

}else{
    Write-Error "ERROR: Assessment configuration is not valid"
}