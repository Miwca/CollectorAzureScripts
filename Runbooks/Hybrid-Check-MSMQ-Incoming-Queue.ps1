[CmdletBinding()]
param 
(
    [parameter(Mandatory=$true)]
	[string]$path,
    [parameter(Mandatory=$true)]
    [string]$storageAccountName,
    [parameter(Mandatory=$true)]
    [string]$storageAccountKey,
    [parameter(Mandatory=$true)]
    [string]$containerName,
    [parameter(Mandatory=$true)]
	[int]$SampleInterval,
    [parameter(Mandatory=$true)]
	[int]$MaxSamples
)

$BackgroundJob = {
    $guid = [Guid]::NewGuid()
    $fullPath = "$($path)\MSMQ-INCOMING-$($guid).csv"
    $blobName = "MSMQ-INCOMMING-$($env:COMPUTERNAME)-$($guid).csv"
    
    $data = Get-Counter -Counter "\MSMQ Service\Incoming Messages/sec" -SampleInterval $SampleInterval -MaxSamples $MaxSamples
    Export-Counter -Path $fullPath -InputObject $data -FileFormat csv -Force

    $ctx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    Set-AzureStorageBlobContent -File $fullPath -Container $containerName -Blob $blobName -Context $ctx
}

Start-Job -ScriptBlock $BackgroundJob