<# 
.SYNOPSIS
Persist assessment results

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

function Write-AssessmentLog{
    param(
        [string]$Message,
        [hashtable]$Config,
        [switch]$Silent,
        [switch]$IsError
    )

    if(-not $Silent){ 
        if($IsError){
            Write-Error $Message 
        }else{
            Write-Host $Message 
        }
    }

    $logFileName = "AssessmentLog$($Config.OutputTag).log"

    $final = ""
    if($IsError){
        $final = [DateTime]::Now.ToString() + ": ERROR: " + $Message
    }else{
        $final = [DateTime]::Now.ToString() + ": " + $Message
    }
    
    $final | Out-File $logFileName -Append

}