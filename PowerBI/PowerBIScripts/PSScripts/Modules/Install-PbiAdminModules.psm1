<# 
.SYNOPSIS
Install PowerShell modules

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

function Install-PbiAdminModules{
    param()
		
	[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
	
    if(Get-Module -Name MicrosoftPowerBIMgmt -ListAvailable){
        Update-Module MicrosoftPowerBIMgmt -Force
    }else{
        Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser -Force
    }

    if(Get-Module -Name AzureAD -ListAvailable){
        Update-Module AzureAD -Force
    }else{
        Install-Module AzureAD -Scope CurrentUser -Force
    }
}