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
$FullPath = $InputData.FullPath
$BlobName = $InputData.BlobName

$BackgroundJob = {
    Param(
        [Guid]$Id,
        [string]$FullPath,
        [string]$BlobName,
        [string]$StorageAccountName,
        [string]$StorageAccountKey,
        [string]$ContainerName,
        [int]$SampleInterval,
        [int]$MaxSamples
    )
    
    $Data = Get-Counter -Counter "\MSMQ Service\Incoming Messages/sec" -SampleInterval $SampleInterval -MaxSamples $MaxSamples
    Export-Counter -Path $FullPath -InputObject $Data -FileFormat csv -Force -ErrorAction Stop

    $Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    Set-AzureStorageBlobContent -File $FullPath -Container $ContainerName -Blob $BlobName -Context $Ctx -ErrorAction Stop
}

Start-Job -ScriptBlock $BackgroundJob -ArgumentList $Guid, 
                                                $FullPath, 
                                                $BlobName, 
                                                $storageAccountName, 
                                                $storageAccountKey, 
                                                $ContainerName, 
                                                $SampleInterval, 
                                                $MaxSamples