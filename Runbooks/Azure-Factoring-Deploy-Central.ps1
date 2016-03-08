[CmdletBinding()] 
Param
(
    [parameter(Mandatory=$false)]
    [string]$subscriptionName = "integration-1-PROD",
    [parameter(Mandatory=$false)]
    [string]$defaultLocation = "West Europe",
    [parameter(Mandatory=$false)]
    [string]$websiteName = "Factoring-Valoratrade-PROD",
    [parameter(Mandatory=$false)]
    [string]$storageAccount = "valoratradeprod",
    [parameter(Mandatory=$false)]
    [string]$serviceBusNameSpace = "Factoring-Valoratrade-PROD",
    [parameter(Mandatory=$false)]
    [string]$loggingBusNameSpace = "LoggingBus-PROD",
    [parameter(Mandatory=$false)]
    [string]$resourceGroupName = 'Group-Factoring-Valoratrade-PROD',
    [parameter(Mandatory=$false)]
    [string]$appPlan = "Default1",
    [parameter(Mandatory=$false)]
    [string]$appPlanResourceGroupName = "Default-Web-WestEurope",
    [parameter(Mandatory=$false)]
    [hashtable]$applicatonSettings = @{},
    [parameter(Mandatory=$false)]
    [ValidateScript({if (($applicationSettings.Count -eq 0) -and ([string]::IsNullOrEmpty($_)))
                    {
                        throw "If you're not gonna provide a hashtable you need to provide the FTP password."
                    }})]
    [string]$ftpPassword,
    [parameter(Mandatory=$false)]
    [ValidateScript({if (($applicationSettings.Count -eq 0) -and ([string]::IsNullOrEmpty($_)))
                    {
                        throw "If you're not gonna provide a hashtable you need to provide the SMTP password."
                    }})]
    [string]$smtpPassword
)

if ($applicatonSettings.Count -eq 0)
{
    $applicationSettings = @{
                        "WEBSITE_NODE_DEFAULT_VERSION" = "0.10.32";

                        "FtpsServer" = "ftp.collector.se";
                        "FtpsUser" = "integration_eman";
                        "FtpsPassword" = $ftpPassword;
                        "FtpsFactoringUser" = "Factoring";
                        "FtpsFactoringPassword" = "Fact5456";
						"AsitisSEDirectory" = "/Asitis/OUT_Asix_SE";
                        "AsitisNODirectory" = "/Asitis/OUT_Asix_NO";
                        "AsitisDKDirectory" = "/Asitis/OUT_Asix_DK";
						"AsitisFIDirectory" = "/Asitis/OUT_Asix";
						"FtpsDirectoryHighjump" = "/Valora_trade_prod/in";
                        "FtpsDirectoryHighjumpFinland" = "/Valora_trade_prod/in_finland";
						"FtpsDirectoryMarwell" = "/Engelschon-prod/in";
						"FtpsDirectoryScanco" = "/Scanco-PROD/in";
                        "RegExp" = "^.*[.]*$";
						"SmtpServer" = "smtp.sendgrid.net";
						"SmtpPort" = "587";
						"SmtpUser" = "azure_ad18f8165506345b082d8666d4bddf1f@azure.com";
						"SmtpPass" = $smtpPassword;
						"Recepient" = "prio.factoring@collectorbank.se";
    }
}

##First create resources using the resource manager
##Login AzureRmAccount  
Login-AzureRmAccount
Set-AzureRmContext -SubscriptionName $subscriptionName

Select-AzureSubscription -SubscriptionName $subscriptionName
##CREATE RESOURCE GROUP
New-AzureRmResourceGroup -Name $resourceGroupName -Location $defaultLocation

##CREATE STORAGEACCOUNT
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount -Location $defaultLocation -Type Standard_LRS
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccount).Key1
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccount;AccountKey=$storageKey"

##CREATE WEBSITE
$serverFarm = Get-AzureRMAppServicePlan -Name $appPlan -ResourceGroupName $appPlanResourceGroupName
New-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $websiteName -Location $defaultLocation -AppServicePlan $serverFarm.Id

##SET ALWAYSON - MAY NEED TO GET APIVERSION
Set-AzureRmResource -PropertyObject @{"AlwaysOn" = $true} -ResourceName $websiteName"/web" -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/config -ApiVersion 2015-08-01 -Force

##GET LOGGING BUS
$loggingBusConnectionString = (Get-AzureSBNamespace -Name $loggingBusNameSpace -Debug).ConnectionString

##CREATE SERVICE BUS
New-AzureSBNamespace -Name $serviceBusNameSpace -Location $defaultLocation -CreateACSNamespace $true -NamespaceType Messaging

Set-AzureWebsite $websiteName -AppSettings $applicatonSettings

#ADD CONNECTION STRINGS TO WEBSITE
$serviceBusConnectionString = (Get-AzureSBNamespace -Name $serviceBusNameSpace).ConnectionString
$connStrings = (Get-AzureWebsite $websiteName).ConnectionStrings

$newConnString = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
$newConnString.Name = "ReferenceMessagesStorage"
$newConnString.ConnectionString = $storageConnectionString
$newConnString.Type = "Custom"
$connStrings.Add($newConnString)

$newConnString = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
$newConnString.Name = "AzureWebJobsServiceBus"
$newConnString.ConnectionString = $serviceBusConnectionString
$newConnString.Type = "Custom"
$connStrings.Add($newConnString)

$newConnString = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
$newConnString.Name = "AzureWebJobsStorage"
$newConnString.ConnectionString = $storageConnectionString
$newConnString.Type = "Custom"
$connStrings.Add($newConnString)

$newConnString = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
$newConnString.Name = "AzureWebJobsDashboard"
$newConnString.ConnectionString = $storageConnectionString
$newConnString.Type = "Custom"
$connStrings.Add($newConnString)

$newConnString = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
$newConnString.Name = "Log4netServiceBusConnection"
$newConnString.ConnectionString = $loggingBusConnectionString
$newConnString.Type = "Custom"
$connStrings.Add($newConnString)

Set-AzureWebsite $websiteName -ConnectionStrings $connStrings