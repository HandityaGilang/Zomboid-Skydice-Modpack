param(
    [string]$RepositoryRoot = $PSScriptRoot,
    [string]$Owner = "HandityaGilang",
    [string]$Repository = "Zomboid-Skydice-Modpack",
    [string]$Branch = "main",
    [int]$HashWorkers = 8,
    [switch]$FullRehash
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BuilderVersion = "FINAL-MODS-1.0"
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
    if (-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {
        throw "File berada di luar repository: $FullPath"
    }
    return $full.Substring($prefix.Length).Replace('\','/')
}

function Get-RawUrl([string]$RawBase,[string]$RelativePath) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach($part in ($RelativePath -split '/')) {
        $parts.Add([Uri]::EscapeDataString($part))
    }
    return $RawBase.TrimEnd('/') + "/" + ($parts -join '/')
}

function Load-JsonSafe([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try { return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch {
        Write-Host "[WARN] Cache/manifest lama tidak dapat dibaca; file terkait akan di-hash ulang." -ForegroundColor Yellow
        return $null
    }
}

function Write-JsonAtomic([object]$Object,[string]$Path,[int]$Depth) {
    $tmp=$Path+".tmp"
    [IO.File]::WriteAllText($tmp,($Object|ConvertTo-Json -Depth $Depth),(New-Object Text.UTF8Encoding($false)))
    if(Test-Path -LiteralPath $Path){Remove-Item -LiteralPath $Path -Force}
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " SKYDICE MANIFEST BUILDER $BuilderVersion" -ForegroundColor Cyan
Write-Host " FAST CACHE + PARALLEL SHA256" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$RepositoryRoot=[IO.Path]::GetFullPath($RepositoryRoot.Trim().Trim('"'))
$ModsRoot=Join-Path $RepositoryRoot "Mods"
$ManifestPath=Join-Path $ModsRoot "manifest.json"
$CachePath=Join-Path $RepositoryRoot ".skydice_manifest_cache.json"
$AttributesPath=Join-Path $RepositoryRoot ".gitattributes"
$RawBase="https://raw.githubusercontent.com/$Owner/$Repository/$Branch"

if(-not(Test-Path -LiteralPath $ModsRoot -PathType Container)){throw "Folder Mods tidak ditemukan: $ModsRoot"}

if(-not(Test-Path -LiteralPath $AttributesPath -PathType Leaf) -or
   ((Get-Content -LiteralPath $AttributesPath -Raw -ErrorAction SilentlyContinue)-notmatch '(?m)^\*\s+-text\s*$')){
    [IO.File]::WriteAllText($AttributesPath,"* -text"+[Environment]::NewLine,(New-Object Text.UTF8Encoding($false)))
    Write-Host "[OK]   .gitattributes: * -text" -ForegroundColor Green
}

Write-Host "[INFO] Repository  : $RepositoryRoot"
Write-Host "[INFO] Manifest    : $ManifestPath"
Write-Host "[INFO] Hash worker : $HashWorkers"
Write-Host "[INFO] Mode        : $(if($FullRehash){'FULL REHASH'}else{'FAST CACHE'})"
Write-Host ""

$scanSw=[Diagnostics.Stopwatch]::StartNew()
$files=@(
    Get-ChildItem -LiteralPath $ModsRoot -File -Recurse -Force |
    Where-Object {
        $_.Name -notin @("manifest.json","Thumbs.db",".DS_Store") -and
        $_.FullName -notmatch '[\\/]\.git([\\/]|$)'
    } |
    Sort-Object FullName
)
$scanSw.Stop()
if($files.Count-eq0){throw "Folder Mods tidak berisi file."}
Write-Host "[INFO] Scan selesai : $($files.Count) file dalam $([Math]::Round($scanSw.Elapsed.TotalSeconds,2)) detik"

$topLevelMods=@(
    Get-ChildItem -LiteralPath $ModsRoot -Directory -Force |
    Where-Object {$_.Name -notin @(".git",".github",".skydice","_updater","Updater")} |
    Sort-Object Name
)

$cacheJson=Load-JsonSafe $CachePath
$cacheByPath=@{}
if($cacheJson -and $cacheJson.files){
    foreach($p in $cacheJson.files.PSObject.Properties){$cacheByPath[$p.Name]=$p.Value}
}

# Old manifest is only a secondary bootstrap source. We DO NOT trust it based
# on size alone. Cache remains the trusted fast path.
$oldManifest=Load-JsonSafe $ManifestPath
$oldByPath=@{}
if($oldManifest -and $oldManifest.files){
    foreach($e in @($oldManifest.files)){if($e.path){$oldByPath[[string]$e.path]=$e}}
}

# Prepare records first; hash only files that cannot be safely reused from cache.
$records=New-Object System.Collections.Generic.List[object]
$hashQueue=New-Object System.Collections.Generic.List[object]
$totalBytes=0L
$reused=0

for($i=0;$i-lt$files.Count;$i++){
    $f=$files[$i]
    $relative=Get-RelativeUnixPath $RepositoryRoot $f.FullName
    $size=[Int64]$f.Length
    $ticks=[Int64]$f.LastWriteTimeUtc.Ticks
    $sha=$null

    # External Dropbox payload is always hashed to guarantee exact published metadata.
    if($relative-ne$ExternalPath -and -not$FullRehash -and $cacheByPath.ContainsKey($relative)){
        $c=$cacheByPath[$relative]
        if([Int64]$c.size-eq$size -and
           [Int64]$c.lastWriteTimeUtcTicks-eq$ticks -and
           -not[string]::IsNullOrWhiteSpace([string]$c.sha256)){
            $sha=([string]$c.sha256).ToLowerInvariant()
            $reused++
        }
    }

    $rec=[pscustomobject]@{
        Index=$i
        File=$f
        Path=$relative
        Size=$size
        Ticks=$ticks
        Sha256=$sha
    }
    $records.Add($rec)
    if(-not$sha){$hashQueue.Add($rec)}
    $totalBytes+=$size

    if(($i%2000)-eq0 -or $i-eq($files.Count-1)){
        Write-Progress -Activity "Menyiapkan manifest" `
            -Status "$($i+1) / $($files.Count) | cache $reused | perlu hash $($hashQueue.Count)" `
            -PercentComplete ([int](100*($i+1)/$files.Count))
    }
}
Write-Progress -Activity "Menyiapkan manifest" -Completed

$hashedCount=0
$hashedBytes=0L
$hashSw=[Diagnostics.Stopwatch]::StartNew()

if($hashQueue.Count-gt0){
    Write-Host "[INFO] SHA256 diperlukan untuk $($hashQueue.Count) file."
    Write-Host "[INFO] $reused file tidak di-hash ulang karena cache valid."

    # Batch prevents 90k PowerShell jobs. Only ~N/256 runspace jobs are created.
    $chunkSize=256
    $chunks=New-Object System.Collections.Generic.List[object]
    for($offset=0;$offset-lt$hashQueue.Count;$offset+=$chunkSize){
        $count=[Math]::Min($chunkSize,$hashQueue.Count-$offset)
        $arr=New-Object object[] $count
        for($j=0;$j-lt$count;$j++){$arr[$j]=$hashQueue[$offset+$j]}
        $chunks.Add($arr)
    }

    $pool=[RunspaceFactory]::CreateRunspacePool(1,[Math]::Max(1,$HashWorkers))
    $pool.Open()
    $active=New-Object System.Collections.Generic.List[object]
    $next=0

    $worker={
        param([object[]]$Items)
        $out=New-Object System.Collections.Generic.List[object]
        foreach($x in $Items){
            $stream=New-Object IO.FileStream(
                [string]$x.File.FullName,
                [IO.FileMode]::Open,
                [IO.FileAccess]::Read,
                [IO.FileShare]::Read,
                1048576,
                [IO.FileOptions]::SequentialScan
            )
            try{
                $sha=[Security.Cryptography.SHA256]::Create()
                try{$hb=$sha.ComputeHash($stream)}finally{$sha.Dispose()}
            }finally{$stream.Dispose()}

            $out.Add([pscustomobject]@{
                Index=[int]$x.Index
                Hash=[BitConverter]::ToString($hb).Replace('-','').ToLowerInvariant()
                Bytes=[Int64]$x.Size
            })
        }
        return $out.ToArray()
    }

    try{
        while($next-lt$chunks.Count -or $active.Count-gt0){
            while($next-lt$chunks.Count -and $active.Count-lt$HashWorkers){
                $ps=[PowerShell]::Create()
                $ps.RunspacePool=$pool
                [void]$ps.AddScript($worker.ToString())
                [void]$ps.AddArgument([object[]]$chunks[$next])
                $active.Add([pscustomobject]@{PowerShell=$ps;Handle=$ps.BeginInvoke()})
                $next++
            }

            for($a=$active.Count-1;$a-ge0;$a--){
                $job=$active[$a]
                if($job.Handle.IsCompleted){
                    $out=$job.PowerShell.EndInvoke($job.Handle)
                    $job.PowerShell.Dispose()
                    $active.RemoveAt($a)

                    foreach($r in $out){
                        $records[[int]$r.Index].Sha256=[string]$r.Hash
                        $hashedCount++
                        $hashedBytes+=[Int64]$r.Bytes
                    }
                }
            }

            $rate=if($hashSw.Elapsed.TotalSeconds-gt0){[Int64]($hashedBytes/$hashSw.Elapsed.TotalSeconds)}else{0}
            Write-Progress -Activity "SHA256 paralel ($HashWorkers worker)" `
                -Status "$hashedCount / $($hashQueue.Count) | $(Format-Bytes $hashedBytes) | $(Format-Bytes $rate)/s" `
                -PercentComplete ([int](100*$hashedCount/[Math]::Max(1,$hashQueue.Count)))
            Start-Sleep -Milliseconds 10
        }
    }finally{
        Write-Progress -Activity "SHA256 paralel ($HashWorkers worker)" -Completed
        foreach($j in $active.ToArray()){try{$j.PowerShell.Stop();$j.PowerShell.Dispose()}catch{}}
        $pool.Close();$pool.Dispose()
    }
}
$hashSw.Stop()

$manifestFiles=New-Object System.Collections.Generic.List[object]
$newCache=@{}
$modStats=@{}

foreach($folder in $topLevelMods){
    $modStats[$folder.Name]=[ordered]@{fileCount=0;size=0L}
}

foreach($r in $records){
    if([string]::IsNullOrWhiteSpace([string]$r.Sha256)){throw "Hash kosong: $($r.Path)"}

    $url=if($r.Path-eq$ExternalPath){$ExternalUrl}else{Get-RawUrl $RawBase $r.Path}

    $manifestFiles.Add([pscustomobject][ordered]@{
        path=$r.Path
        url=$url
        size=[Int64]$r.Size
        sha256=([string]$r.Sha256).ToLowerInvariant()
    })

    $newCache[$r.Path]=[ordered]@{
        size=[Int64]$r.Size
        lastWriteTimeUtcTicks=[Int64]$r.Ticks
        sha256=([string]$r.Sha256).ToLowerInvariant()
    }

    # O(N), not nested O(mods*N)
    if($r.Path -match '^Mods/([^/]+)/'){
        $modName=$matches[1]
        if($modStats.ContainsKey($modName)){
            $modStats[$modName].fileCount++
            $modStats[$modName].size+=[Int64]$r.Size
        }
    }
}

$modsSummary=New-Object System.Collections.Generic.List[object]
foreach($folder in $topLevelMods){
    $s=$modStats[$folder.Name]
    $modsSummary.Add([pscustomobject][ordered]@{
        name=$folder.Name
        fileCount=[int]$s.fileCount
        size=[Int64]$s.size
    })
}

$manifest=[pscustomobject][ordered]@{
    schemaVersion=2
    generatedAt=(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    repository=[pscustomobject][ordered]@{
        owner=$Owner
        name=$Repository
        branch=$Branch
        modsPath="Mods"
        manifestPath="Mods/manifest.json"
        rawBaseUrl=$RawBase
    }
    totals=[pscustomobject][ordered]@{
        mods=$topLevelMods.Count
        files=$manifestFiles.Count
        size=$totalBytes
    }
    mods=$modsSummary
    files=$manifestFiles
}

$cacheOut=[pscustomobject][ordered]@{
    version=3
    generatedAt=(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    files=[pscustomobject]$newCache
}

Write-JsonAtomic $manifest $ManifestPath 12
Write-JsonAtomic $cacheOut $CachePath 8

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " MANIFEST SELESAI" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Total file       : $($manifestFiles.Count)"
Write-Host "Ukuran modpack   : $(Format-Bytes $totalBytes)"
Write-Host "Cache digunakan  : $reused"
Write-Host "File di-hash     : $hashedCount"
Write-Host "Data di-hash     : $(Format-Bytes $hashedBytes)"
Write-Host "Waktu hashing    : $([Math]::Round($hashSw.Elapsed.TotalSeconds,2)) detik"
Write-Host "Manifest         : $ManifestPath"
Write-Host ""
