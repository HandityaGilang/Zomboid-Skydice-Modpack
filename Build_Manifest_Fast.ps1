param(
    [string]$RepositoryRoot = $PSScriptRoot,
    [string]$Owner = "HandityaGilang",
    [string]$Repository = "Zomboid-Skydice-Modpack",
    [string]$Branch = "main",
    [switch]$FullRehash
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BuilderVersion = "FINAL-1.0"
$ExternalPath = "Mods/LifestyleHobbies_KardinalTest/common/media/texturepacks/LS_Artwork.pack"
$ExternalUrl  = "https://www.dropbox.com/scl/fi/oprab9zm7q57aelb156t0/LS_Artwork.pack?rlkey=0fijr6zbzjztyfo0cb25o6gny&st=cgnhk4e6&dl=1"

function Format-Bytes([Int64]$Bytes) {
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-RelativeUnixPath([string]$BasePath, [string]$FullPath) {
    $base = [IO.Path]::GetFullPath($BasePath).TrimEnd('\','/')
    $full = [IO.Path]::GetFullPath($FullPath)
    $prefix = $base + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "File berada di luar repository: $FullPath"
    }
    return $full.Substring($prefix.Length).Replace('\','/')
}

function Get-RawUrl([string]$RawBase, [string]$RelativePath) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($part in ($RelativePath -split '/')) {
        $parts.Add([Uri]::EscapeDataString($part))
    }
    return $RawBase.TrimEnd('/') + "/" + ($parts -join '/')
}

function Load-JsonSafe([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Host "[WARN] Cache lama rusak/tidak terbaca; akan dibangun ulang." -ForegroundColor Yellow
        return $null
    }
}

function Write-JsonAtomic([object]$Object, [string]$Path, [int]$Depth) {
    $tmp = $Path + ".tmp"
    $utf8 = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($tmp, ($Object | ConvertTo-Json -Depth $Depth), $utf8)
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force }
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " SKYDICE MANIFEST BUILDER $BuilderVersion" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot.Trim().Trim('"'))
$ModsRoot       = Join-Path $RepositoryRoot "Mods"
$ManifestPath   = Join-Path $ModsRoot "manifest.json"
$CachePath      = Join-Path $RepositoryRoot ".skydice_manifest_cache.json"
$AttributesPath = Join-Path $RepositoryRoot ".gitattributes"
$RawBase        = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch"

if (-not (Test-Path -LiteralPath $ModsRoot -PathType Container)) {
    throw "Folder Mods tidak ditemukan: $ModsRoot"
}

# Menjaga byte file tetap identik saat Git checkout.
if (-not (Test-Path -LiteralPath $AttributesPath -PathType Leaf) -or
    ((Get-Content -LiteralPath $AttributesPath -Raw -ErrorAction SilentlyContinue) -notmatch '(?m)^\*\s+-text\s*$')) {
    [IO.File]::WriteAllText($AttributesPath, "* -text" + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
    Write-Host "[OK]   .gitattributes disetel ke: * -text" -ForegroundColor Green
}

Write-Host "[INFO] Repository : $RepositoryRoot"
Write-Host "[INFO] Mods       : $ModsRoot"
Write-Host "[INFO] Manifest   : $ManifestPath"
Write-Host "[INFO] Remote URL : $RawBase/Mods/manifest.json"
Write-Host "[INFO] Mode       : $(if($FullRehash){'FULL REHASH'}else{'FAST CACHE'})"
Write-Host ""

$files = @(
    Get-ChildItem -LiteralPath $ModsRoot -File -Recurse -Force |
    Where-Object {
        $_.Name -notin @("manifest.json","Thumbs.db",".DS_Store") -and
        $_.FullName -notmatch '[\\/]\.git([\\/]|$)'
    } |
    Sort-Object FullName
)

if ($files.Count -eq 0) { throw "Folder Mods tidak berisi file." }

$topLevelMods = @(
    Get-ChildItem -LiteralPath $ModsRoot -Directory -Force |
    Where-Object { $_.Name -notin @(".git",".github",".skydice","_updater","Updater") } |
    Sort-Object Name
)

$cacheJson = Load-JsonSafe $CachePath
$cacheByPath = @{}
if ($cacheJson -and $cacheJson.files) {
    foreach ($p in $cacheJson.files.PSObject.Properties) {
        $cacheByPath[$p.Name] = $p.Value
    }
}

$manifestFiles = New-Object System.Collections.Generic.List[object]
$newCache = @{}
$totalBytes = 0L
$reused = 0
$hashed = 0
$sw = [Diagnostics.Stopwatch]::StartNew()

for ($i = 0; $i -lt $files.Count; $i++) {
    $file = $files[$i]
    $relative = Get-RelativeUnixPath $RepositoryRoot $file.FullName
    $size = [Int64]$file.Length
    $ticks = [Int64]$file.LastWriteTimeUtc.Ticks
    $sha = $null

    if ($relative -eq $ExternalPath) {
        $sha = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashed++
    }
    elseif (-not $FullRehash -and $cacheByPath.ContainsKey($relative)) {
        $c = $cacheByPath[$relative]
        if ([Int64]$c.size -eq $size -and
            [Int64]$c.lastWriteTimeUtcTicks -eq $ticks -and
            -not [string]::IsNullOrWhiteSpace([string]$c.sha256)) {
            $sha = ([string]$c.sha256).ToLowerInvariant()
            $reused++
        }
    }

    if (-not $sha) {
        $sha = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashed++
    }

    $url = if ($relative -eq $ExternalPath) {
        $ExternalUrl
    } else {
        Get-RawUrl $RawBase $relative
    }

    $manifestFiles.Add([pscustomobject][ordered]@{
        path   = $relative
        url    = $url
        size   = $size
        sha256 = $sha
    })

    $newCache[$relative] = [ordered]@{
        size                  = $size
        lastWriteTimeUtcTicks = $ticks
        sha256                = $sha
    }

    $totalBytes += $size

    if (($i % 250) -eq 0 -or $i -eq ($files.Count - 1)) {
        $done = $i + 1
        Write-Progress -Activity "Membangun manifest" `
            -Status "$done / $($files.Count) | cache $reused | hash $hashed" `
            -PercentComplete ([int](100 * $done / $files.Count))
    }
}
Write-Progress -Activity "Membangun manifest" -Completed

$modsSummary = New-Object System.Collections.Generic.List[object]
foreach ($folder in $topLevelMods) {
    $prefix = "Mods/$($folder.Name)/"
    $count = 0
    $bytes = 0L
    foreach ($e in $manifestFiles) {
        if ($e.path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            $count++
            $bytes += [Int64]$e.size
        }
    }
    $modsSummary.Add([pscustomobject][ordered]@{
        name = $folder.Name
        fileCount = $count
        size = $bytes
    })
}

$manifest = [pscustomobject][ordered]@{
    schemaVersion = 2
    generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    repository = [pscustomobject][ordered]@{
        owner = $Owner
        name = $Repository
        branch = $Branch
        modsPath = "Mods"
        manifestPath = "Mods/manifest.json"
        rawBaseUrl = $RawBase
    }
    totals = [pscustomobject][ordered]@{
        mods = $topLevelMods.Count
        files = $manifestFiles.Count
        size = $totalBytes
    }
    mods = $modsSummary
    files = $manifestFiles
}

$cacheOut = [pscustomobject][ordered]@{
    version = 2
    generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    files = [pscustomobject]$newCache
}

Write-JsonAtomic $manifest $ManifestPath 12
Write-JsonAtomic $cacheOut $CachePath 8
$sw.Stop()

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " MANIFEST BERHASIL DIBUAT" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "File            : $($manifestFiles.Count)"
Write-Host "Ukuran modpack  : $(Format-Bytes $totalBytes)"
Write-Host "Cache digunakan : $reused"
Write-Host "File di-hash    : $hashed"
Write-Host "Waktu           : $([Math]::Round($sw.Elapsed.TotalSeconds,2)) detik"
Write-Host ""
Write-Host "Manifest lokal  : $ManifestPath"
Write-Host "Manifest online : $RawBase/Mods/manifest.json"
Write-Host ""
Write-Host "Selanjutnya commit + push SEMUA perubahan Mods beserta manifest.json." -ForegroundColor Yellow
