[CmdletBinding()]
param 
(
    [parameter(Mandatory=$True)]
	[string]$Path,
    [parameter(Mandatory=$True)]
    [string]$StorageAccountName,
    [parameter(Mandatory=$True)]
    [string]$StorageAccountKey,
    [parameter(Mandatory=$True)]
    [string]$ContainerName,
    [parameter(Mandatory=$True)]
	[int]$SampleInterval,
    [parameter(Mandatory=$True)]
	[int]$MaxSamples
)

$Guid = [Guid]::NewGuid()
$FullPath = "$($path)\MSMQ-TOTAL-$($guid).csv";
$BlobName = "MSMQ-TOTAL-$($env:COMPUTERNAME)-$($guid).csv";

Import-Module Azure.Storage -Force -ErrorAction SilentlyContinue

$Data = Get-Counter -Counter "\MSMQ Service\Total messages in all queues" -SampleInterval $SampleInterval -MaxSamples $MaxSamples
Export-Counter -Path $FullPath -InputObject $Data -FileFormat csv -Force -ErrorAction Stop

$Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
Set-AzureStorageBlobContent -File $FullPath -Container $ContainerName -Blob $BlobName -Context $Ctx -Force -ErrorAction Stop