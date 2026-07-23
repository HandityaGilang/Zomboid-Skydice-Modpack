param(
    [string]$RepositoryRoot = $PSScriptRoot,
    [string]$Owner = "HandityaGilang",
    [string]$Repository = "Zomboid-Skydice-Modpack",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

function Format-Bytes {
    param([Int64]$Bytes)

    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-RelativeUnixPath {
    param(
        [string]$BasePath,
        [string]$FullPath
    )

    $base = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/')
    $full = [System.IO.Path]::GetFullPath($FullPath)

    $prefix = $base + [System.IO.Path]::DirectorySeparatorChar

    if (-not $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "File berada di luar folder repository: $FullPath"
    }

    return $full.Substring($prefix.Length).Replace('\', '/')
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SKYDICE MODPACK MANIFEST BUILDER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot.Trim().Trim('"'))
$ModsRoot = Join-Path $RepositoryRoot "Mods"
$ManifestPath = Join-Path $RepositoryRoot "manifest.json"

if (-not (Test-Path -LiteralPath $ModsRoot -PathType Container)) {
    Write-Host "[ERROR] Folder Mods tidak ditemukan:" -ForegroundColor Red
    Write-Host "        $ModsRoot" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Repository : $RepositoryRoot"
Write-Host "[INFO] Folder Mods : $ModsRoot"
Write-Host "[INFO] Branch      : $Branch"
Write-Host ""

$startTime = Get-Date

$files = @(
    Get-ChildItem -LiteralPath $ModsRoot -File -Recurse -Force |
    Where-Object {
        $_.FullName -notmatch '[\\/]\.git([\\/]|$)' -and
        $_.Name -ne 'Thumbs.db' -and
        $_.Name -ne '.DS_Store'
    } |
    Sort-Object FullName
)

if ($files.Count -eq 0) {
    Write-Host "[ERROR] Tidak ada file di dalam folder Mods." -ForegroundColor Red
    exit 1
}

$topLevelMods = @(
    Get-ChildItem -LiteralPath $ModsRoot -Directory -Force |
    Where-Object { $_.Name -ne '.git' } |
    Sort-Object Name
)

Write-Host "[INFO] Folder mod terdeteksi : $($topLevelMods.Count)"
Write-Host "[INFO] Total file            : $($files.Count)"
Write-Host ""

$manifestFiles = @()
$totalBytes = [Int64]0
$rawBase = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch"

for ($i = 0; $i -lt $files.Count; $i++) {
    $file = $files[$i]
    $number = $i + 1
    $percent = [Math]::Floor(($number / $files.Count) * 100)

    $relativePath = Get-RelativeUnixPath -BasePath $RepositoryRoot -FullPath $file.FullName

    Write-Progress `
        -Activity "Membuat manifest Skydice Modpack" `
        -Status "$number / $($files.Count) - $relativePath" `
        -PercentComplete $percent

    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $fileSize = [Int64]$file.Length
    $totalBytes += $fileSize

    $escapedParts = @()
    foreach ($part in ($relativePath -split '/')) {
        $escapedParts += [System.Uri]::EscapeDataString($part)
    }
    $escapedPath = $escapedParts -join '/'

    $entry = New-Object PSObject -Property @{
        path   = $relativePath
        size   = $fileSize
        sha256 = $hash
        url    = "$rawBase/$escapedPath"
    }

    $manifestFiles += $entry
}

Write-Progress -Activity "Membuat manifest Skydice Modpack" -Completed

$modsSummary = @()

foreach ($modFolder in $topLevelMods) {
    $modPrefix = "Mods/$($modFolder.Name)/"
    $modFileCount = 0
    $modSize = [Int64]0

    foreach ($entry in $manifestFiles) {
        if ($entry.path.StartsWith($modPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $modFileCount++
            $modSize += [Int64]$entry.size
        }
    }

    $summaryEntry = New-Object PSObject -Property @{
        name      = $modFolder.Name
        fileCount = $modFileCount
        size      = $modSize
    }

    $modsSummary += $summaryEntry
}

$repositoryInfo = New-Object PSObject -Property @{
    owner      = $Owner
    name       = $Repository
    branch     = $Branch
    modsPath   = "Mods"
    rawBaseUrl = $rawBase
}

$totalsInfo = New-Object PSObject -Property @{
    mods  = $topLevelMods.Count
    files = $manifestFiles.Count
    size  = $totalBytes
}

$manifest = New-Object PSObject -Property @{
    schemaVersion = 1
    generatedAt   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    repository    = $repositoryInfo
    totals        = $totalsInfo
    mods          = $modsSummary
    files         = $manifestFiles
}

$json = $manifest | ConvertTo-Json -Depth 8

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ManifestPath, $json, $utf8NoBom)

$elapsed = (Get-Date) - $startTime
$manifestSize = (Get-Item -LiteralPath $ManifestPath).Length

Write-Host "[OK] manifest.json berhasil dibuat." -ForegroundColor Green
Write-Host ""
Write-Host "Ringkasan:"
Write-Host "  Folder mod     : $($topLevelMods.Count)"
Write-Host "  Total file     : $($manifestFiles.Count)"
Write-Host "  Ukuran modpack : $(Format-Bytes $totalBytes)"
Write-Host "  Ukuran manifest: $(Format-Bytes $manifestSize)"
Write-Host "  Waktu proses   : $([Math]::Round($elapsed.TotalSeconds, 2)) detik"
Write-Host ""
Write-Host "Lokasi manifest:"
Write-Host "  $ManifestPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Selanjutnya commit dan push:" -ForegroundColor Yellow
Write-Host "  Mods/"
Write-Host "  manifest.json"
