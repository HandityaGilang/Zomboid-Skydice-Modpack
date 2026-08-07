param(
    [string]$RepositoryRoot = $PSScriptRoot,
    [string]$Owner = "HandityaGilang",
    [string]$Repository = "Zomboid-Skydice-Modpack",
    [string]$Branch = "main",
    [switch]$FullRehash
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BuilderVersion = "3.0"
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
    $parts = foreach ($part in ($RelativePath -split '/')) { [Uri]::EscapeDataString($part) }
    return "$RawBase/" + ($parts -join '/')
}

function Load-JsonSafe([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try { return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { return $null }
}

function Write-JsonNoBom([object]$Object, [string]$Path, [int]$Depth = 10) {
    $json = $Object | ConvertTo-Json -Depth $Depth
    [IO.File]::WriteAllText($Path, $json, (New-Object Text.UTF8Encoding($false)))
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SKYDICE MANIFEST BUILDER v$BuilderVersion" -ForegroundColor Cyan
Write-Host " FAST CACHE + ROOT/MODS MANIFEST" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot.Trim().Trim('"'))
$ModsRoot       = Join-Path $RepositoryRoot "Mods"
$ManifestRoot   = Join-Path $RepositoryRoot "manifest.json"
$ManifestCompat = Join-Path $ModsRoot "manifest.json"
$CachePath      = Join-Path $RepositoryRoot ".skydice_manifest_cache.json"
$AttributesPath = Join-Path $RepositoryRoot ".gitattributes"
$RawBase        = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch"

if (-not (Test-Path -LiteralPath $ModsRoot -PathType Container)) {
    throw "Folder Mods tidak ditemukan: $ModsRoot"
}

# Mencegah Git mengubah CRLF/LF sehingga SHA lokal = SHA hasil download.
if (-not (Test-Path -LiteralPath $AttributesPath -PathType Leaf) -or
    -not ((Get-Content -LiteralPath $AttributesPath -Raw) -match '(?m)^\*\s+-text\s*$')) {
    [IO.File]::WriteAllText($AttributesPath, "* -text`r`n", (New-Object Text.UTF8Encoding($false)))
    Write-Host "[OK] .gitattributes dipastikan berisi: * -text" -ForegroundColor Green
}

$excludedNames = @("Thumbs.db", ".DS_Store", "manifest.json")
$files = @(
    Get-ChildItem -LiteralPath $ModsRoot -File -Recurse -Force |
    Where-Object {
        $excludedNames -notcontains $_.Name -and
        $_.FullName -notmatch '[\\/]\.git([\\/]|$)'
    } |
    Sort-Object FullName
)
if ($files.Count -eq 0) { throw "Tidak ada file mod di $ModsRoot" }

$topLevelMods = @(
    Get-ChildItem -LiteralPath $ModsRoot -Directory -Force |
    Where-Object { $_.Name -notin @('.git','.github','.skydice','_updater','Updater') } |
    Sort-Object Name
)

$cacheJson = Load-JsonSafe $CachePath
$cacheByPath = @{}
if ($cacheJson -and $cacheJson.files) {
    foreach ($p in $cacheJson.files.PSObject.Properties) { $cacheByPath[$p.Name] = $p.Value }
}

$manifestFiles = New-Object System.Collections.Generic.List[object]
$newCache = @{}
$totalBytes = 0L
$reused = 0
$hashed = 0
$start = Get-Date

for ($i=0; $i -lt $files.Count; $i++) {
    $file = $files[$i]
    $relativePath = Get-RelativeUnixPath $RepositoryRoot $file.FullName
    $size = [Int64]$file.Length
    $ticks = [Int64]$file.LastWriteTimeUtc.Ticks
    $sha = $null

    if (-not $FullRehash -and $cacheByPath.ContainsKey($relativePath)) {
        $c = $cacheByPath[$relativePath]
        if ([Int64]$c.size -eq $size -and [Int64]$c.lastWriteTimeUtcTicks -eq $ticks -and $c.sha256) {
            $sha = ([string]$c.sha256).ToLowerInvariant()
            $reused++
        }
    }

    # File eksternal selalu di-hash ulang agar Dropbox selalu cocok dengan file lokal terbaru.
    if ($relativePath -eq $ExternalPath -or -not $sha) {
        $sha = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashed++
    }

    $url = if ($relativePath -eq $ExternalPath) { $ExternalUrl } else { Get-RawUrl $RawBase $relativePath }

    $manifestFiles.Add([pscustomobject][ordered]@{
        path   = $relativePath
        url    = $url
        sha256 = $sha
        size   = $size
    })

    $newCache[$relativePath] = [ordered]@{
        size = $size
        lastWriteTimeUtcTicks = $ticks
        sha256 = $sha
    }
    $totalBytes += $size

    if (($i % 100) -eq 0 -or $i -eq ($files.Count-1)) {
        $done = $i + 1
        $pct = [Math]::Floor(($done / $files.Count) * 100)
        Write-Progress -Activity "Membangun manifest" -Status "$done / $($files.Count) | cache $reused | hash $hashed" -PercentComplete $pct
    }
}
Write-Progress -Activity "Membangun manifest" -Completed

$modsSummary = New-Object System.Collections.Generic.List[object]
foreach ($folder in $topLevelMods) {
    $prefix = "Mods/$($folder.Name)/"
    $count = 0; $bytes = 0L
    foreach ($e in $manifestFiles) {
        if ($e.path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { $count++; $bytes += [Int64]$e.size }
    }
    $modsSummary.Add([pscustomobject][ordered]@{ name=$folder.Name; fileCount=$count; size=$bytes })
}

$manifest = [pscustomobject][ordered]@{
    schemaVersion = 2
    generatedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    repository = [pscustomobject][ordered]@{
        owner=$Owner; name=$Repository; branch=$Branch; modsPath='Mods'; rawBaseUrl=$RawBase
        archiveUrl="https://codeload.github.com/$Owner/$Repository/zip/refs/heads/$Branch"
    }
    totals = [pscustomobject][ordered]@{ mods=$topLevelMods.Count; files=$manifestFiles.Count; size=$totalBytes }
    mods = $modsSummary
    files = $manifestFiles
}

$cacheOut = [pscustomobject][ordered]@{
    version=2
    generatedAt=(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    files=[pscustomobject]$newCache
}

# Tulis dua lokasi: root = lokasi utama; Mods = kompatibilitas updater lama.
Write-JsonNoBom $manifest $ManifestRoot 12
Write-JsonNoBom $manifest $ManifestCompat 12
Write-JsonNoBom $cacheOut $CachePath 6

$elapsed = (Get-Date)-$start
Write-Host ""
Write-Host "[OK] Manifest selesai." -ForegroundColor Green
Write-Host "  File           : $($manifestFiles.Count)"
Write-Host "  Mod folder     : $($topLevelMods.Count)"
Write-Host "  Ukuran         : $(Format-Bytes $totalBytes)"
Write-Host "  Cache dipakai  : $reused"
Write-Host "  Hash dihitung  : $hashed"
Write-Host "  Waktu          : $([Math]::Round($elapsed.TotalSeconds,2)) detik"
Write-Host ""
Write-Host "Manifest utama   : $ManifestRoot" -ForegroundColor Cyan
Write-Host "Manifest kompat. : $ManifestCompat" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "Setelah builder selesai, PUSH manifest + Mods terbaru ke GitHub:" -ForegroundColor Yellow
Write-Host "  git add -A"
Write-Host "  git commit -m `"Update modpack`""
Write-Host "  git push origin $Branch"
Write-Host ""
Write-Host "Updater baru akan membaca manifest ONLINE saja; tidak memakai cache manifest lama." -ForegroundColor Green
