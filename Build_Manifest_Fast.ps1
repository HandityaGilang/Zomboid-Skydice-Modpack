param(
    [string]$RepositoryRoot = $PSScriptRoot,
    [string]$Owner = "HandityaGilang",
    [string]$Repository = "Zomboid-Skydice-Modpack",
    [string]$Branch = "main",
    [switch]$FullRehash
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BuilderVersion = "2.0"
$DrivePath = "Mods/LifestyleHobbies_KardinalTest/common/media/texturepacks/LS_Artwork.pack"
$DriveUrl  = "https://drive.google.com/uc?export=download&id=1pTtNBJhH8Djhbh9tR3pnZAF88bq4mpvO"
$DriveHash = "48fe9c8e39740ec3b299ae56fc250571d9be61e3979f0766e24a8306964ccaea"
$DriveSize = [Int64]143840426

function Format-Bytes {
    param([Int64]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-RelativeUnixPath {
    param([string]$BasePath, [string]$FullPath)

    $base = [IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/')
    $full = [IO.Path]::GetFullPath($FullPath)
    $prefix = $base + [IO.Path]::DirectorySeparatorChar

    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "File berada di luar repository: $FullPath"
    }

    return $full.Substring($prefix.Length).Replace('\', '/')
}

function Get-RawUrl {
    param([string]$RawBase, [string]$RelativePath)

    $parts = foreach ($part in ($RelativePath -split '/')) {
        [Uri]::EscapeDataString($part)
    }
    return "$RawBase/" + ($parts -join '/')
}

function Load-JsonSafe {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }

    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        Write-Host "[WARN] Tidak dapat membaca $Path; file akan dibuat ulang." -ForegroundColor Yellow
        return $null
    }
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " SKYDICE MANIFEST BUILDER v$BuilderVersion - FAST CACHE" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot.Trim().Trim('"'))
$ModsRoot       = Join-Path $RepositoryRoot "Mods"
$ManifestPath   = Join-Path $ModsRoot "manifest.json"
$CachePath      = Join-Path $RepositoryRoot ".skydice_manifest_cache.json"
$AttributesPath = Join-Path $RepositoryRoot ".gitattributes"
$RawBase        = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch"

if (-not (Test-Path -LiteralPath $ModsRoot -PathType Container)) {
    Write-Host "[ERROR] Folder Mods tidak ditemukan: $ModsRoot" -ForegroundColor Red
    exit 1
}

# Pastikan Git tidak mengubah byte file teks.
$requiredAttributes = "* -text"
$writeAttributes = $true
if (Test-Path -LiteralPath $AttributesPath -PathType Leaf) {
    $existingAttributes = Get-Content -LiteralPath $AttributesPath -Raw
    if ($existingAttributes -match '(?m)^\*\s+-text\s*$') {
        $writeAttributes = $false
    }
}
if ($writeAttributes) {
    [IO.File]::WriteAllText(
        $AttributesPath,
        $requiredAttributes + [Environment]::NewLine,
        (New-Object Text.UTF8Encoding($false))
    )
    Write-Host "[OK] .gitattributes dibuat otomatis: * -text" -ForegroundColor Green
}

Write-Host "[INFO] Repository : $RepositoryRoot"
Write-Host "[INFO] Manifest   : $ManifestPath"
Write-Host "[INFO] Cache      : $CachePath"
Write-Host "[INFO] Mode       : $(if ($FullRehash) {'FULL REHASH'} else {'FAST CACHE'})"
Write-Host ""

$excludedNames = @("Thumbs.db", ".DS_Store", "manifest.json")

$files = @(
    Get-ChildItem -LiteralPath $ModsRoot -File -Recurse -Force |
    Where-Object {
        $excludedNames -notcontains $_.Name -and
        $_.FullName -notmatch '[\\/]\.git([\\/]|$)'
    } |
    Sort-Object FullName
)

$topLevelMods = @(
    Get-ChildItem -LiteralPath $ModsRoot -Directory -Force |
    Where-Object { $_.Name -notin @(".git", ".github", ".skydice", "_updater", "Updater") } |
    Sort-Object Name
)

if ($files.Count -eq 0) {
    Write-Host "[ERROR] Tidak ada file mod yang ditemukan." -ForegroundColor Red
    exit 1
}

$oldManifest = Load-JsonSafe -Path $ManifestPath
$oldByPath = @{}
if ($oldManifest -and $oldManifest.files) {
    foreach ($entry in $oldManifest.files) {
        $oldByPath[[string]$entry.path] = $entry
    }
}

$cacheJson = Load-JsonSafe -Path $CachePath
$cacheByPath = @{}
if ($cacheJson -and $cacheJson.files) {
    foreach ($property in $cacheJson.files.PSObject.Properties) {
        $cacheByPath[$property.Name] = $property.Value
    }
}

$start = Get-Date
$manifestFiles = New-Object System.Collections.Generic.List[object]
$newCache = @{}
$totalBytes = [Int64]0
$reused = 0
$hashed = 0

for ($i = 0; $i -lt $files.Count; $i++) {
    $file = $files[$i]
    $relativePath = Get-RelativeUnixPath -BasePath $RepositoryRoot -FullPath $file.FullName
    $size = [Int64]$file.Length
    $ticks = [Int64]$file.LastWriteTimeUtc.Ticks
    $sha = $null

    # File Google Drive memakai hash tetap yang sudah diverifikasi.
    if ($relativePath -eq $DrivePath) {
        $sha = $DriveHash
        $size = $DriveSize
        $reused++
    }
    elseif (-not $FullRehash -and $cacheByPath.ContainsKey($relativePath)) {
        $cached = $cacheByPath[$relativePath]
        if (
            [Int64]$cached.size -eq $size -and
            [Int64]$cached.lastWriteTimeUtcTicks -eq $ticks -and
            -not [string]::IsNullOrWhiteSpace([string]$cached.sha256)
        ) {
            $sha = ([string]$cached.sha256).ToLowerInvariant()
            $reused++
        }
    }

    # Bootstrap cepat: manifest lama dibuat dari file lokal yang sama.
    # Dipakai hanya bila cache belum ada dan ukuran file cocok.
    if (
        -not $sha -and
        -not $FullRehash -and
        -not $cacheJson -and
        $oldByPath.ContainsKey($relativePath)
    ) {
        $old = $oldByPath[$relativePath]
        if (
            [Int64]$old.size -eq $size -and
            -not [string]::IsNullOrWhiteSpace([string]$old.sha256)
        ) {
            $sha = ([string]$old.sha256).ToLowerInvariant()
            $reused++
        }
    }

    if (-not $sha) {
        $sha = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashed++
    }

    $url = if ($relativePath -eq $DrivePath) {
        $DriveUrl
    } else {
        Get-RawUrl -RawBase $RawBase -RelativePath $relativePath
    }

    $manifestFiles.Add([pscustomobject][ordered]@{
        url    = $url
        path   = $relativePath
        sha256 = $sha
        size   = $size
    })

    $newCache[$relativePath] = [ordered]@{
        size                  = $size
        lastWriteTimeUtcTicks = $ticks
        sha256                = $sha
    }

    $totalBytes += $size

    if (($i % 100) -eq 0 -or $i -eq ($files.Count - 1)) {
        $done = $i + 1
        $percent = [Math]::Floor(($done / $files.Count) * 100)
        Write-Progress `
            -Activity "Membangun manifest" `
            -Status "$done / $($files.Count) | cache: $reused | hash baru: $hashed" `
            -PercentComplete $percent
    }
}

Write-Progress -Activity "Membangun manifest" -Completed

$modsSummary = New-Object System.Collections.Generic.List[object]
foreach ($modFolder in $topLevelMods) {
    $prefix = "Mods/$($modFolder.Name)/"
    $count = 0
    $modSize = [Int64]0

    foreach ($entry in $manifestFiles) {
        if ($entry.path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            $count++
            $modSize += [Int64]$entry.size
        }
    }

    $modsSummary.Add([pscustomobject][ordered]@{
        name      = $modFolder.Name
        fileCount = $count
        size      = $modSize
    })
}

$manifest = [pscustomobject][ordered]@{
    schemaVersion = 1
    generatedAt   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    repository    = [pscustomobject][ordered]@{
        owner      = $Owner
        name       = $Repository
        branch     = $Branch
        modsPath   = "Mods"
        rawBaseUrl = $RawBase
    }
    totals = [pscustomobject][ordered]@{
        mods  = $topLevelMods.Count
        files = $manifestFiles.Count
        size  = $totalBytes
    }
    mods  = $modsSummary
    files = $manifestFiles
}

$cacheObject = [pscustomobject][ordered]@{
    version     = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    files       = [pscustomobject]$newCache
}

$utf8NoBom = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText($ManifestPath, ($manifest | ConvertTo-Json -Depth 10), $utf8NoBom)
[IO.File]::WriteAllText($CachePath, ($cacheObject | ConvertTo-Json -Depth 6), $utf8NoBom)

$elapsed = (Get-Date) - $start
$manifestSize = (Get-Item -LiteralPath $ManifestPath).Length

Write-Host ""
Write-Host "[OK] manifest.json berhasil dibuat." -ForegroundColor Green
Write-Host ""
Write-Host "Ringkasan:"
Write-Host "  Folder mod      : $($topLevelMods.Count)"
Write-Host "  Total file      : $($manifestFiles.Count)"
Write-Host "  Cache digunakan : $reused"
Write-Host "  File di-hash    : $hashed"
Write-Host "  Ukuran modpack  : $(Format-Bytes $totalBytes)"
Write-Host "  Ukuran manifest : $(Format-Bytes $manifestSize)"
Write-Host "  Waktu           : $([Math]::Round($elapsed.TotalSeconds, 2)) detik"
Write-Host ""
Write-Host "Manifest:"
Write-Host "  $ManifestPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "URL Google Drive sudah diterapkan otomatis pada:" -ForegroundColor Green
Write-Host "  $DrivePath"
Write-Host ""
Write-Host "PENTING UNTUK SEKALI SAJA setelah menambah .gitattributes:" -ForegroundColor Yellow
Write-Host "  git add .gitattributes"
Write-Host "  git rm --cached -r ."
Write-Host "  git add ."
Write-Host "  git commit -m `"Preserve exact mod file bytes`""
Write-Host "  git push"
Write-Host ""
Write-Host "Untuk memaksa pemeriksaan SHA256 seluruh file:" -ForegroundColor DarkGray
Write-Host "  .\Build_Manifest_Fast.ps1 -FullRehash"
