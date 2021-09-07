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

function Get-Configuration {
    param (
        #Override file path
        [string]$Override
    )

    $Config = @{
        Environment             = "Public"
        AdEnvironment           = "AzureCloud"

        SinkType                = "CSV"
        Sink                    = "out"
        SinkSchema              = "dbo"

        AuditLogDays            = 30
        AuditLogBatchHours      = 24

        ExportPremium           = $false
        PremiumDatasetId        = ""

        ExportActivityLog       = $true
        ExportTenantSettings    = $true
        ExportInventory         = $true
        ExportDatasources       = $true
        ExportRefreshes         = $true 
        ExportV1Users           = $true
        ExportLicenses          = $true
        ExportLicensesProDetail = $true
        
        # Service Principal Changes - Begin
        ServicePrincipalAuth    = $false
        ServicePrincipalID      = ""
        ServicePrincipalSecret  = ""
        TenantID                = ""
        # Service Principal Changes - End

        AuthContext             = $null
        AuthAdContext           = $null
        AuthToken               = $null
        LastTokenUpdateTime     = $null
        LogQueries              = $false

        ApiGatewayUri           = "https://api.powerbi.com"
        ApiResourceUri          = "https://analysis.windows.net"

        # Define tag for output file or record with DateStamp
        OutputTag               = (get-date).ToString("yyyyMMdd.hhmm")
    }

    #Read configuration from a file if provided, otherwise - ask
    if ($Override -and (Test-Path $Override)) {
        $overrideData = Get-Content $Override | ConvertFrom-Json
        if ($overrideData) {
            if ($null -ne $overrideData.Environment) { $Config.Environment = $overrideData.Environment }

            if ($null -ne $overrideData.SinkType) { $Config.SinkType = $overrideData.SinkType }
            if ($null -ne $overrideData.Sink) { $Config.Sink = $overrideData.Sink }
            if ($null -ne $overrideData.SinkSchema) { $Config.SinkSchema = $overrideData.SinkSchema }

            if ($null -ne $overrideData.AuditLogDays) { $Config.AuditLogDays = $overrideData.AuditLogDays }
            if ($null -ne $overrideData.AuditLogBatchHours) { $Config.AuditLogBatchHours = $overrideData.AuditLogBatchHours }
            if ($null -ne $overrideData.ExportPremium) { $Config.ExportPremium = $overrideData.ExportPremium }
            if ($null -ne $overrideData.PremiumDatasetId) { $Config.PremiumDatasetId = $overrideData.PremiumDatasetId }
            if ($null -ne $overrideData.ExportActivityLog) { $Config.ExportActivityLog = $overrideData.ExportActivityLog }
            if ($null -ne $overrideData.ExportTenantSettings) { $Config.ExportTenantSettings = $overrideData.ExportTenantSettings }
            if ($null -ne $overrideData.ExportInventory) { $Config.ExportInventory = $overrideData.ExportInventory }
            if ($null -ne $overrideData.ExportDatasources) { $Config.ExportDatasources = $overrideData.ExportDatasources }
            if ($null -ne $overrideData.ExportRefreshes) { $Config.ExportRefreshes = $overrideData.ExportRefreshes }
            if ($null -ne $overrideData.ExportV1Users) { $Config.ExportV1Users = $overrideData.ExportV1Users }
            if ($null -ne $overrideData.ExportLicenses) { $Config.ExportLicenses = $overrideData.ExportLicenses }
            if ($null -ne $overrideData.ExportLicensesProDetail) { $Config.ExportLicensesProDetail = $overrideData.ExportLicensesProDetail }
            if ($null -ne $overrideData.LogQueries) { $Config.LogQueries = $overrideData.LogQueries }
            
            #Service Principal Changes - Begin
            if ($null -ne $overrideData.ServicePrincipalAuth) { $Config.ServicePrincipalAuth = $overrideData.ServicePrincipalAuth }
            if ($null -ne $overrideData.ServicePrincipalID) { $Config.ServicePrincipalID = $overrideData.ServicePrincipalID }
            if ($null -ne $overrideData.ServicePrincipalSecret) { $Config.ServicePrincipalSecret = $overrideData.ServicePrincipalSecret }
            if ($null -ne $overrideData.TenantID) { $Config.TenantID = $overrideData.TenantID }
            #Service Principal Changes - End
        }
    }
    else {

        # Config File Missing Hint
        Write-Host "Configuration file not found. To re-run from configuration please abort and restart the scripts. Cmd: Run-PowerBIAssessment.ps1 <Config File Path>" -ForegroundColor Yellow
        Write-Host "Sample Command with config file specified:" -ForegroundColor Yellow
        Write-Host "Run-PowerBIAssessment.ps1 .\default.config." -ForegroundColor Green

        $readOutputFolder = Read-Host "Folder to put all the extracts in? (Default: out)"
        if ($readOutputFolder) { $Config.Sink = $readOutputFolder }

        $readPremium = Read-Host "Do you want to export Premium Capacity Metrics App data? [y/n] (Default: n)"
        if ($readPremium -eq "y") {
            $Config.ExportPremium = $readOutputFolder

        }
        if ($readOutputFolder) { $Config.Sink = $readOutputFolder }
    }

    $Config.AdEnvironment = @{Public = "AzureCloud"; USGov = "AzureUSGovernment"; USGovMil = "AzureUSGovernment2"; USGovHigh = "AzureUSGovernment3"; China = "AzureChinaCloud"; Germany = "AzureGermanyCloud" }[$Config.Environment]

    # Check If Service Principal Auth Enabled
    if ($Config.ServicePrincipalAuth) {
        
        $secureServicePrincipalSecret = ConvertTo-SecureString $Config.ServicePrincipalSecret -AsPlainText -Force
        $servicePrincipal = New-Object PSCredential -ArgumentList $Config.ServicePrincipalID, $secureServicePrincipalSecret 
        
        $Config.AuthContext = Connect-PowerBIServiceAccount -Environment $Config.Environment -ServicePrincipal -Credential $servicePrincipal -Tenant $Config.TenantID

        #disable what is not supported here by service principal auth
        $Config.ExportPremium = $false
        $Config.ExportTenantSettings = $false
        $Config.ExportV1Users = $false
        $Config.ExportLicenses = $false
        $Config.ExportLicensesProDetail = $false

        Write-Host "Service Principal only supports activity logs and Power BI inventory exports as of now." -ForegroundColor Yellow
    }
    else {
        # Prompt the user for credentials
        $Config.AuthContext = Connect-PowerBIServiceAccount -Environment $Config.Environment
    }

    # Store the auth token
    $Config.AuthToken = Get-PowerBIAccessToken -AsString
    $Config.LastTokenUpdateTime = [DateTime]::MinValue

    # Determine the API Gateway root Uri
    if ($Config.Environment -eq "USGov") {
        $Config.ApiGatewayUri = "https://api.powerbigov.us"
        $Config.ApiResourceUri = "https://analysis.usgovcloudapi.net"
    }
    if ($Config.Environment -eq "USGovHigh") {
        $Config.ApiGatewayUri = "https://api.high.powerbigov.us"
        $Config.ApiResourceUri = "https://high.analysis.usgovcloudapi.net"
    }

    # Prompt the user for credentials again for AD connection
    if ($Config.ExportV1Users -or $Config.ExportLicenses) {
        $Config.AuthAdContext = Connect-AzureAD -AzureEnvironmentName $Config.AdEnvironment 
    }

    return $Config
}