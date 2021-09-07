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
#>

##############################################################
# Microsoft Power BI Assessment
# Version:        1.4
# Author:         ae-aspr-powerbiasses@microsoft.com
# Last Update :   3 Apr 2020
##############################################################

#-------- Questions ------------
# 1 - Customer environment? Public | USGov | USGovMil | USGovHigh | China | Germany
$Environment = "Public" 

# 2 - Folder Output to put all the extracts in?
$folder = "out"
#-------------------------------

# Check PS version
Write-Host "Checking PowerShell version..." -NoNewline
if($PSVersionTable.PSVersion.Major -ge 3){
    Write-Host "ok" -ForegroundColor Green
}else{
    Write-Host "version 3 or later required" -ForegroundColor Red
    exit
}

# Check .NET version
Write-Host "Checking .NET version..." -NoNewline
$netInstalls = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse `
    | Get-ItemProperty -Name Version -ErrorAction Ignore `
    | Select-Object { $_.Version } `
    | Select-String -Pattern "(\d+)\.(\d+)\.(\d+)\.?(\d?)" `
    | Foreach-Object { [int]$_.Matches.Groups[1].ToString() * 100 + [int]$_.Matches.Groups[2].ToString() } `
    | Where-Object {$_ -ge 407}


if($netInstalls.Count -gt 0){
    Write-Host "ok" -ForegroundColor Green
}else{
    Write-Host "version 4.7 or later required" -ForegroundColor Red
    exit
}

$folderFullPath = "$PSScriptRoot\$folder"
# $folderFullPath = "c:\temp\$folder"
$modulesFolder = "$PSScriptRoot\Modules"

If(!(test-path $folderFullPath)) {
      New-Item -ItemType Directory -Force -Path $folderFullPath
}

#import the powershell functions to run the rest of the script
if(-not(Get-Item $folderFullPath -ErrorAction Ignore)) {
    $void = New-Item -Path $PSScriptRoot -Name $folder -ItemType Directory
}

foreach ($module in Get-Childitem $modulesFolder -Name -Filter "*.psm1") {
    $modulePath = "$modulesFolder\$module"
    Unblock-File $modulePath
    Import-Module $modulePath -Force
}

Install-PbiAdminModules

# Prompt the user for credentials
$account = Connect-PowerBIServiceAccount -Environment $Environment

# Check PBI access
Write-Host "Checking Power BI Admin access..." -NoNewline
$sampleDateStart = Get-Date -Year 2020 -Month 8 -Day 27 -Hour 0 -Minute 0 -Second 0
$sampleDateEnd = $sampleDateStart.AddDays(1).AddSeconds(-1)
$sampleLog = Get-PowerBIActivityEvent -StartDateTime $sampleDateStart.ToString("yyyy-MM-ddTHH:mm:ss.fffZ") -EndDateTime $sampleDateEnd.ToString("yyyy-MM-ddTHH:mm:ss.fffZ") | ConvertFrom-Json
$pbiAccess = if($sampleLog) {$True} else {$False}
if($pbiAccess){
    Write-Host "ok" -ForegroundColor Green
}else{
    Write-Host "no access" -ForegroundColor Red
}
