param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string]$Archive,
    [Parameter(Mandatory = $true)]
    [string]$ExtractDirectory
)

$ErrorActionPreference = "Stop"
$executablePath = (Resolve-Path $Executable).Path
$archivePath = [System.IO.Path]::GetFullPath($Archive)
$extractPath = [System.IO.Path]::GetFullPath($ExtractDirectory)
$archiveParent = [System.IO.Path]::GetDirectoryName($archivePath)
[System.IO.Directory]::CreateDirectory($archiveParent) | Out-Null

if (Test-Path $extractPath) {
    throw "Clean extraction target already exists: $extractPath"
}

$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("market-of-ash-portable-" + [Guid]::NewGuid().ToString("N"))
$productDirectory = Join-Path $stagingRoot "Market of Ash"
$packagedExecutable = Join-Path $productDirectory "market-of-ash.exe"
try {
    New-Item -ItemType Directory -Path $productDirectory | Out-Null
    Copy-Item -Path $executablePath -Destination $packagedExecutable
    Compress-Archive -Path $productDirectory -DestinationPath $archivePath -CompressionLevel Optimal -Force
    Expand-Archive -Path $archivePath -DestinationPath $extractPath
    $extractedExecutable = Join-Path $extractPath "Market of Ash\market-of-ash.exe"
    if (-not (Test-Path -Path $extractedExecutable -PathType Leaf)) {
        throw "Portable archive did not extract the expected executable: $extractedExecutable"
    }
    Write-Host "Windows portable package: $archivePath"
    Write-Host "Clean extracted executable: $extractedExecutable"
}
finally {
    if (Test-Path $stagingRoot) {
        Remove-Item -Path $stagingRoot -Recurse -Force
    }
}
