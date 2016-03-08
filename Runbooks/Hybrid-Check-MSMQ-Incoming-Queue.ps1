[CmdletBinding()]
param 
(
    [parameter(Mandatory=$false)]
	[string]$path,
    [parameter(Mandatory=$false)]
    [string]$storageAccountName,
    [parameter(Mandatory=$false)]
    [string]$storageAccountKey,
    [parameter(Mandatory=$false)]
    [string]$containerName,
    [parameter(Mandatory=$false)]
	[int]$SampleInterval,
    [parameter(Mandatory=$false)]
	[int]$MaxSamples
)

$guid = [Guid]::NewGuid()
$fullPath = "$($path)\MSMQ-INCOMING-$($guid).csv"
$blobName = "$($env:COMPUTERNAME)-$($guid).csv"

$data = Get-Counter -Counter "\MSMQ Service\Incoming Messages/sec" -SampleInterval $SampleInterval -MaxSamples $MaxSamples
Export-Counter -Path $fullPath -InputObject $data -FileFormat csv -Force

$ctx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Set-AzureStorageBlobContent -File $fullPath -Container $containerName -Blob $blobName -Context $ctx