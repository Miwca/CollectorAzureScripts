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
$FullPath = "$($path)\MSMQ-INCOMING-$($guid).csv";
$BlobName = "MSMQ-INCOMMING-$($env:COMPUTERNAME)-$($guid).csv";
    
Import-Module Azure.Storage -Force -ErrorAction SilentlyContinue

$Data = Get-Counter -Counter "\MSMQ Service\Incoming Messages/sec" -SampleInterval $SampleInterval -MaxSamples $MaxSamples
Export-Counter -Path $FullPath -InputObject $Data -FileFormat csv -Force -ErrorAction Stop

$Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
Set-AzureStorageBlobContent -File $FullPath -Container $ContainerName -Blob $BlobName -Context $Ctx -Force -ErrorAction Stop