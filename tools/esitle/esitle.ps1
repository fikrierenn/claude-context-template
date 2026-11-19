<#
.SYNOPSIS
  esitle — makineler arası git eşitleme (plan 58, pusula/plans/58-makine-esitleme-ve-dalsiz-is-disiplini.md).

.DESCRIPTION
  Modlar:
    Snapshot     Kaydedilmemiş işi wip/<MAKINE> dalına commit'ler. Çalışma ağacı, HEAD, index DEĞİŞMEZ. Ağ gerekmez.
    Sync         İKİ YÖNLÜ: Snapshot -> fetch (refs/esitle/<M>/*) -> Converge -> push (yalnız refs/makine/<MAKINE>/*).
                 İki makine de aynı görevi çalıştırır; ikişer koşuda iki taraf aynı commit'e oturur.
    Report       Son fetch'e göre dal dal durum tablosu (ağ gerekmez).
    Converge     Son fetch'e göre yakınsama: karşıda olan dalı oluştur, geride olanı ileri sar,
                 ayrışmışı çakışma yoksa birleştir (merge-tree, çalışma ağacına dokunmaz). Çakışmaya dokunmaz.

  rebase, reset, force (kendi ad alanı dışında) ve başka makinenin ref'ine yazma YOK.
  Karşının KAYDEDİLMEMİŞ işi çalışma ağacına uygulanmaz; yerelde wip/<KARSI> dalı olarak durur.

.EXAMPLE
  powershell -File esitle.ps1 -Mode Sync
  powershell -File esitle.ps1 -Mode Snapshot -RepoPath D:\Dev\pusula -Message "oturum sonu"
#>
[CmdletBinding()]
param(
    [ValidateSet('Snapshot', 'Sync', 'Report', 'Converge', 'Sessions')]
    [string]$Mode = 'Report',
    [string]$RepoPath,
    [string]$Message = '',
    [string]$ConfigPath = '',
    [string]$Machine = $env:COMPUTERNAME,
    [switch]$Quiet,
    # Claude Code SessionEnd hook'u: stdin'den {cwd, session_id, reason} JSON'u okunur.
    [switch]$FromHook,
    # Sessions modu: belirli oturumu ya da tümünü içeri al (varsayılan: son importDays gün).
    [string]$SessionId = '',
    [switch]$AllSessions
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# ── Logging ──────────────────────────────────────────────────────────────────
# AppData DEĞİL: Claude masaüstü (MSIX) içinden başlayan süreçlerin AppData yazmaları paket
# sanallaştırmasına gider; zamanlanmış görev gerçek AppData'ya yazar -> iki ayrı log (18.11 ölçüldü).
$script:LogDir = Join-Path $env:USERPROFILE '.esitle'

function Write-EsitleLog {
    param([string]$Text, [string]$Level = 'INFO')
    $line = '{0:dd.MM.yyyy HH:mm:ss} [{1}] {2}' -f (Get-Date), $Level, $Text
    try {
        if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Force $script:LogDir | Out-Null }
        Add-Content -Path (Join-Path $script:LogDir 'esitle.log') -Value $line -Encoding UTF8
    }
    catch {
        # Log yazılamazsa konsola düş; sessiz kalma.
        Write-Warning "esitle log yazilamadi: $($_.Exception.Message) | $line"
    }
}

# ── Git invocation (Process: stderr ayrı, env değişkeni desteği) ─────────────
function ConvertTo-ArgString {
    param([string[]]$Arguments)
    $parts = foreach ($a in $Arguments) {
        if ($a -eq '') { '""' }
        elseif ($a -match '[\s"]') { '"' + ($a -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"' }
        else { $a }
    }
    return ($parts -join ' ')
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][string[]]$Arguments,
        [hashtable]$Env = @{},
        [switch]$AllowFail
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'git'
    $psi.Arguments = ConvertTo-ArgString (@('-C', $Repo, '-c', 'core.quotepath=off') + $Arguments)
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    foreach ($k in $Env.Keys) { $psi.EnvironmentVariables[$k] = [string]$Env[$k] }
    $p = [System.Diagnostics.Process]::Start($psi)
    $errTask = $p.StandardError.ReadToEndAsync()
    $out = $p.StandardOutput.ReadToEnd()
    $p.WaitForExit()
    $err = $errTask.Result
    $result = [pscustomobject]@{ ExitCode = $p.ExitCode; Out = $out.TrimEnd("`r", "`n"); Err = $err.Trim() }
    if ($p.ExitCode -ne 0 -and -not $AllowFail) {
        throw "git $($Arguments -join ' ') [$Repo] cikis $($p.ExitCode): $($result.Err)"
    }
    return $result
}

function Get-GitLines {
    param([string]$Text, [switch]$NullSeparated)
    if ([string]::IsNullOrEmpty($Text)) { return @() }
    if ($NullSeparated) { return @($Text.Split([char]0) | Where-Object { $_ -ne '' }) }
    return @($Text -split "`r?`n" | Where-Object { $_ -ne '' })
}

function Test-GitRef {
    param([string]$Repo, [string]$Ref)
    return ((Invoke-Git -Repo $Repo -Arguments @('rev-parse', '-q', '--verify', "$Ref^{commit}") -AllowFail).ExitCode -eq 0)
}

function Get-GitRef {
    param([string]$Repo, [string]$Ref)
    $r = Invoke-Git -Repo $Repo -Arguments @('rev-parse', '-q', '--verify', "$Ref^{commit}") -AllowFail
    if ($r.ExitCode -ne 0) { return $null }
    return $r.Out
}

# ── Config ───────────────────────────────────────────────────────────────────
function Get-EsitleConfig {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Ayar dosyasi yok: $Path" }
    $cfg = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($req in @('hubRoot', 'machines', 'repos', 'maxFileMB', 'secretPatterns')) {
        if (-not ($cfg.PSObject.Properties.Name -contains $req)) { throw "Ayar eksik: '$req' ($Path)" }
    }
    if (-not ($cfg.PSObject.Properties.Name -contains 'secretAllow')) {
        $cfg | Add-Member -NotePropertyName secretAllow -NotePropertyValue @()
    }
    return $cfg
}

function Get-RepoPathFor {
    param($Config, [string]$Machine, $RepoEntry)
    $m = $Config.machines.PSObject.Properties[$Machine]
    if (-not $m) { throw "Makine ayarda tanimli degil: $Machine (esitle.json > machines)" }
    if ($RepoEntry.PSObject.Properties.Name -contains 'path') { return $RepoEntry.path }
    return (Join-Path $m.Value.devRoot $RepoEntry.name)
}

function Get-HubUrl {
    param($Config, $RepoEntryOrName)
    $hubName = if ($RepoEntryOrName -is [string]) {
        ($Config.repos | Where-Object { $_.name -eq $RepoEntryOrName } | Select-Object -First 1).hub
    } else { $RepoEntryOrName.hub }
    if (-not $hubName) { throw "Repo ayarda yok: $RepoEntryOrName" }
    return (($Config.hubRoot.TrimEnd('\', '/') + '/' + $hubName) -replace '\\', '/')
}

# ── Lock ─────────────────────────────────────────────────────────────────────
function Enter-RepoLock {
    param([string]$GitDir)
    $lock = Join-Path $GitDir 'esitle.lock'
    if (Test-Path $lock) {
        $age = (Get-Date) - (Get-Item $lock).LastWriteTime
        if ($age.TotalMinutes -gt 30) {
            Write-EsitleLog "Bayat kilit kaldirildi ($([int]$age.TotalMinutes) dk): $lock" 'WARN'
            Remove-Item $lock -Force
        }
        else { return $null }
    }
    try {
        $fs = [System.IO.File]::Open($lock, 'CreateNew', 'Write', 'None')
        $fs.Close()
        Set-Content -Path $lock -Value "$PID $env:COMPUTERNAME" -Encoding ASCII
        return $lock
    }
    catch [System.IO.IOException] { return $null }
}

function Exit-RepoLock {
    param([string]$Lock)
    if ($Lock -and (Test-Path $Lock)) { Remove-Item $Lock -Force }
}

# ── Snapshot ─────────────────────────────────────────────────────────────────
function Test-SecretPath {
    param([string]$Path, $Config)
    foreach ($allow in @($Config.secretAllow)) { if ($Path -match $allow) { return $false } }
    foreach ($pat in @($Config.secretPatterns)) { if ($Path -match $pat) { return $true } }
    return $false
}

function Invoke-EsitleSnapshot {
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [Parameter(Mandatory)][string]$Machine,
        [Parameter(Mandatory)]$Config,
        [string]$Message = ''
    )
    $res = [pscustomobject]@{ Repo = $RepoPath; Status = ''; Commit = $null; Detail = @(); Skipped = @() }
    $gitDir = (Invoke-Git -Repo $RepoPath -Arguments @('rev-parse', '--absolute-git-dir')).Out
    $lock = Enter-RepoLock $gitDir
    if (-not $lock) { $res.Status = 'Locked'; return $res }
    $tmpIndex = Join-Path $gitDir ("esitle-index-" + $PID + ".tmp")
    try {
        $wipRef = "refs/heads/wip/$Machine"
        $head = Get-GitRef $RepoPath 'HEAD'
        $realIndex = Join-Path $gitDir 'index'
        if (Test-Path $realIndex) { Copy-Item $realIndex $tmpIndex -Force }
        $gitEnv = @{ GIT_INDEX_FILE = $tmpIndex }

        Invoke-Git -Repo $RepoPath -Arguments @('add', '-A', '--', '.') -Env $gitEnv | Out-Null

        $base = if ($head) { $head } else { '4b825dc642cb6eb9a060e54bf8d69288fbee4904' } # boş ağaç
        $changed = @(Get-GitLines -NullSeparated (Invoke-Git -Repo $RepoPath -Env $gitEnv -Arguments @(
                'diff-index', '--cached', '--name-only', '--no-renames', '--diff-filter=AM', '-z', $base)).Out)

        $secrets = @($changed | Where-Object { Test-SecretPath $_ $Config })
        if ($secrets.Count -gt 0) {
            $res.Status = 'SecretRisk'; $res.Detail = $secrets
            Write-EsitleLog "SIR RISKI, repo atlandi: $RepoPath -> $($secrets -join ', ')" 'WARN'
            return $res
        }

        $limit = [double]$Config.maxFileMB * 1MB
        foreach ($f in $changed) {
            $full = Join-Path $RepoPath $f
            if ((Test-Path -LiteralPath $full -PathType Leaf) -and ((Get-Item -LiteralPath $full).Length -gt $limit)) {
                if ($head) { Invoke-Git -Repo $RepoPath -Env $gitEnv -Arguments @('reset', '-q', 'HEAD', '--', $f) | Out-Null }
                else { Invoke-Git -Repo $RepoPath -Env $gitEnv -Arguments @('rm', '-q', '--cached', '--', $f) | Out-Null }
                $res.Skipped += $f
            }
        }
        if ($res.Skipped.Count -gt 0) { Write-EsitleLog "Boyut siniri asildi, alinmadi: $RepoPath -> $($res.Skipped -join ', ')" 'WARN' }

        $tree = (Invoke-Git -Repo $RepoPath -Env $gitEnv -Arguments @('write-tree')).Out
        $headTree = if ($head) { (Invoke-Git -Repo $RepoPath -Arguments @('rev-parse', "$head^{tree}")).Out } else { $null }
        $wipTip = Get-GitRef $RepoPath $wipRef
        $wipTree = if ($wipTip) { (Invoke-Git -Repo $RepoPath -Arguments @('rev-parse', "$wipTip^{tree}")).Out } else { $null }

        if ($tree -eq $headTree -or $tree -eq $wipTree) { $res.Status = 'NoChange'; return $res }

        $parents = @()
        if ($wipTip) { $parents += $wipTip }
        if ($head) {
            $headIsAncestor = $false
            if ($wipTip) {
                $headIsAncestor = ((Invoke-Git -Repo $RepoPath -Arguments @('merge-base', '--is-ancestor', $head, $wipTip) -AllowFail).ExitCode -eq 0)
            }
            if (-not $headIsAncestor) { $parents += $head }
        }
        $branch = (Invoke-Git -Repo $RepoPath -Arguments @('symbolic-ref', '-q', '--short', 'HEAD') -AllowFail).Out
        if (-not $branch) { $branch = '(detached)' }
        $nFiles = $changed.Count - $res.Skipped.Count
        $subject = "wip($Machine): " + $(if ($Message) { $Message } else { 'otomatik anlik goruntu' })
        $body = "dal: $branch`nzaman: {0:dd.MM.yyyy HH:mm}`ndosya: $nFiles" -f (Get-Date)
        if ($res.Skipped.Count -gt 0) { $body += "`nalinmayan (boyut): $($res.Skipped -join ', ')" }

        $ctArgs = @('commit-tree', $tree)
        foreach ($p in $parents) { $ctArgs += @('-p', $p) }
        $ctArgs += @('-m', $subject, '-m', $body)
        $commit = (Invoke-Git -Repo $RepoPath -Arguments $ctArgs).Out
        $old = if ($wipTip) { $wipTip } else { '0000000000000000000000000000000000000000' }
        Invoke-Git -Repo $RepoPath -Arguments @('update-ref', '-m', 'esitle snapshot', $wipRef, $commit, $old) | Out-Null

        $res.Status = 'Committed'; $res.Commit = $commit
        Write-EsitleLog "Snapshot $RepoPath -> wip/$Machine $($commit.Substring(0,7)) ($nFiles dosya)"
        return $res
    }
    finally {
        if (Test-Path $tmpIndex) { Remove-Item $tmpIndex -Force }
        Exit-RepoLock $lock
    }
}

# ── Sync ─────────────────────────────────────────────────────────────────────
function Invoke-EsitleSync {
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][string]$Machine,
        [Parameter(Mandatory)]$Config,
        [string]$Message = ''
    )
    $res = [pscustomobject]@{ Repo = $RepoName; Status = ''; Snapshot = $null; Converge = @(); Detail = '' }
    $hubUrl = Get-HubUrl $Config $RepoName
    if (-not (Test-Path ($hubUrl -replace '/', '\'))) {
        $res.Status = 'HubMissing'; $res.Detail = "hub'da yok: $hubUrl"
        Write-EsitleLog "Hub'da repo yok: $hubUrl" 'WARN'
        # Hub olmasa da yerel iş güvenceye alınır.
        $res.Snapshot = Invoke-EsitleSnapshot -RepoPath $RepoPath -Machine $Machine -Config $Config -Message $Message
        return $res
    }
    # 1) Kendi kaydedilmemiş işimizi güvenceye al.
    $res.Snapshot = Invoke-EsitleSnapshot -RepoPath $RepoPath -Machine $Machine -Config $Config -Message $Message
    # 2) Karşıyı al: tüm makinelerin ad alanı (kendimizinki raporda süzülür).
    Invoke-Git -Repo $RepoPath -Arguments @('fetch', '-q', '--prune', $hubUrl, '+refs/makine/*:refs/esitle/*') | Out-Null
    # 3) Yakınsa: karşının dallarını yerelde oluştur / ileri sar / çakışmasız birleştir.
    $autoMerge = if ($Config.PSObject.Properties.Name -contains 'autoMerge') { [bool]$Config.autoMerge } else { $true }
    $res.Converge = @(Invoke-EsitleConverge -RepoPath $RepoPath -RepoName $RepoName -Machine $Machine -AutoMerge $autoMerge)
    # 4) Gönder: yalnız kendi ad alanı. '+' yalnız refs/makine/<KENDİ>/* için (plan 58 force istisnası).
    #    --no-verify: bu bir ayna, teslim değil. Projenin pre-push kapısı (build/test/gitleaks) her 30 dk koşmasın;
    #    teslim push'ları (origin) kapıdan geçmeye devam eder. Sır koruması: Snapshot'taki desen taraması.
    #    Kullanıcı kararı 18.11.2026 (NEXUSFLOW vakası).
    #    Karşı makinelerin wip/<KARSI> dalları GERİ GÖNDERİLMEZ (negatif refspec): aksi halde bir makinenin
    #    kaydedilmemiş içeriği öbürünün adıyla da yayılıyordu (18.11 fifo: parolalı geçmiş iki ad alanına
    #    sızdı). Kendi wip dalımız ayrıca gönderilir.
    #    Negatif refspec (^refs/heads/wip/*) bu git sürümünde push'ta yok sayılıyor (18.11 ölçüldü);
    #    bu yüzden dallar tek tek listelenir.
    $heads = @(Get-GitLines (Invoke-Git -Repo $RepoPath -Arguments @('for-each-ref', '--format=%(refname)', 'refs/heads/')).Out)
    $pushSpecs = @($heads | Where-Object { $_ -notlike 'refs/heads/wip/*' -or $_ -eq "refs/heads/wip/$Machine" } |
        ForEach-Object { '+' + $_ + ':refs/makine/' + $Machine + '/' + $_.Substring('refs/heads/'.Length) })
    # Boş liste push'u varsayılan davranışa düşürür (mevcut dal); hiç dal yoksa gönderme.
    if ($pushSpecs.Count -gt 0) {
        Invoke-Git -Repo $RepoPath -Arguments (@('push', '-q', '--no-verify', $hubUrl) + $pushSpecs) | Out-Null
    }
    # Push sonrası kendi ad alanımızın yerel aynasını tazele (rapor tutarlılığı).
    Invoke-Git -Repo $RepoPath -Arguments @('fetch', '-q', '--prune', $hubUrl, "+refs/makine/${Machine}/*:refs/esitle/${Machine}/*") | Out-Null
    # Kendi ad alanını buda: yerelde karşılığı olmayan ayna ref'i (silinmiş/yeniden adlandırılmış dal,
    # eski sürümün geri gönderdiği yabancı wip) hub'dan silinir. Başka makinenin ad alanına dokunulmaz.
    $expected = @($pushSpecs | ForEach-Object { ($_ -split ':', 2)[1] })
    $mirrorPrefix = "refs/esitle/$Machine/"
    $stale = @(Get-GitLines (Invoke-Git -Repo $RepoPath -Arguments @('for-each-ref', '--format=%(refname)', $mirrorPrefix)).Out |
        ForEach-Object { "refs/makine/$Machine/" + $_.Substring($mirrorPrefix.Length) } | Where-Object { $expected -notcontains $_ })
    if ($stale.Count -gt 0) {
        Invoke-Git -Repo $RepoPath -Arguments (@('push', '-q', '--no-verify', $hubUrl) + @($stale | ForEach-Object { ':' + $_ })) | Out-Null
        Invoke-Git -Repo $RepoPath -Arguments @('fetch', '-q', '--prune', $hubUrl, "+refs/makine/${Machine}/*:refs/esitle/${Machine}/*") | Out-Null
        Write-EsitleLog "Ad alani budandi: $RepoName -> $($stale -join ', ')"
    }

    $res.Status = 'Synced'
    Write-EsitleLog "Sync tamam: $RepoName ($Machine)"
    return $res
}

# ── Report ───────────────────────────────────────────────────────────────────
function Get-EsitleReport {
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][string]$Machine
    )
    $rows = @()
    $remote = @(Get-GitLines (Invoke-Git -Repo $RepoPath -Arguments @('for-each-ref', '--format=%(refname)', 'refs/esitle/')).Out)
    foreach ($ref in $remote) {
        if ($ref -notmatch '^refs/esitle/([^/]+)/(.+)$') { continue }
        $other = $Matches[1]; $branch = $Matches[2]
        if ($other -eq $Machine) { continue }
        $local = Get-GitRef $RepoPath "refs/heads/$branch"
        $otherTip = Get-GitRef $RepoPath $ref
        $date = (Invoke-Git -Repo $RepoPath -Arguments @('log', '-1', '--format=%cd', '--date=format:%d.%m.%Y %H:%M', $otherTip)).Out
        if (-not $local) {
            $state = 'YalnizOrada'; $ahead = 0; $behind = 0
        }
        else {
            $counts = (Invoke-Git -Repo $RepoPath -Arguments @('rev-list', '--left-right', '--count', "$local...$otherTip")).Out -split '\s+'
            $ahead = [int]$counts[0]; $behind = [int]$counts[1]
            $state = if ($ahead -eq 0 -and $behind -eq 0) { 'Ayni' }
            elseif ($behind -eq 0) { 'Onde' }
            elseif ($ahead -eq 0) { 'Geride' }
            else { 'Ayrismis' }
        }
        $rows += [pscustomobject]@{
            Repo = $RepoName; Branch = $branch; Other = $other; State = $state
            Ahead = $ahead; Behind = $behind; OtherDate = $date
        }
    }
    return $rows
}

# ── Converge (iki yönlü yakınsama) ───────────────────────────────────────────
# Her makine kendi tarafında aynı kuralı uygular; iki koşudan sonra iki taraf aynı commit'e oturur.
#   YalnizOrada  -> yerel dal oluşturulur (karşının wip/<O> dalı dahil)
#   Geride       -> ileri sarılır
#   Ayrismis     -> çakışma yoksa merge-tree ile çalışma ağacına dokunmadan merge commit'i
#   Cakisma      -> hiçbir şeye dokunulmaz, raporlanır
# Aktif (checkout edilmiş) dal yalnız `git merge --ff-only` ile ilerler: git yerel değişikliği
# ezecekse reddeder, o durumda 'AtlandiYerelDegisiklik' yazılır ve bir sonraki koşuda tekrar denenir.
function Move-BranchTip {
    param([string]$RepoPath, [string]$Branch, [string]$Target, [string]$Old, [string]$Current, [string]$Reason)
    if ($Branch -eq $Current) {
        $r = Invoke-Git -Repo $RepoPath -Arguments @('merge', '--ff-only', '-q', $Target) -AllowFail
        if ($r.ExitCode -ne 0) {
            Write-EsitleLog "Aktif dal ilerletilemedi ($Branch): $($r.Err)" 'WARN'
            return 'AtlandiYerelDegisiklik'
        }
        return 'Ilerletildi'
    }
    $oldArg = if ($Old) { $Old } else { '0000000000000000000000000000000000000000' }
    Invoke-Git -Repo $RepoPath -Arguments @('update-ref', '-m', "esitle: $Reason", "refs/heads/$Branch", $Target, $oldArg) | Out-Null
    return $(if ($Old) { 'Ilerletildi' } else { 'Olusturuldu' })
}

function Invoke-EsitleConverge {
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][string]$Machine,
        [bool]$AutoMerge = $true
    )
    $out = @()
    $current = (Invoke-Git -Repo $RepoPath -Arguments @('symbolic-ref', '-q', '--short', 'HEAD') -AllowFail).Out
    $rows = @(Get-EsitleReport -RepoPath $RepoPath -RepoName $RepoName -Machine $Machine)
    foreach ($r in $rows) {
        # Kendi wip dalımız yalnız bu makinede yazılır; karşıdaki kopyası bize geri akmaz.
        if ($r.Branch -eq "wip/$Machine") { continue }
        if ($r.State -in @('Ayni', 'Onde')) { continue }
        $target = Get-GitRef $RepoPath "refs/esitle/$($r.Other)/$($r.Branch)"
        $local = Get-GitRef $RepoPath "refs/heads/$($r.Branch)"
        $result = ''; $detail = ''
        switch ($r.State) {
            'YalnizOrada' { $result = Move-BranchTip $RepoPath $r.Branch $target $null $current "dal $($r.Other)'dan" }
            'Geride' { $result = Move-BranchTip $RepoPath $r.Branch $target $local $current "ff $($r.Other)'dan" }
            'Ayrismis' {
                if (-not $AutoMerge) { $result = 'AtlandiAyar'; break }
                $mt = Invoke-Git -Repo $RepoPath -Arguments @('merge-tree', '--write-tree', '--name-only', '--no-messages', $local, $target) -AllowFail
                if ($mt.ExitCode -eq 1) {
                    $files = @(Get-GitLines $mt.Out | Select-Object -Skip 1)
                    $result = 'Cakisma'; $detail = ($files -join ', ')
                    Write-EsitleLog "CAKISMA $RepoName/$($r.Branch) <-> $($r.Other): $detail" 'WARN'
                }
                elseif ($mt.Err -match 'unrelated histories') {
                    # İki makinede aynı adlı ama ortak kökü olmayan dal (ör. ayrı ayrı 'git init'). Otomatik
                    # birleştirme anlamsız; dokunma, raporla. Repo'nun geri kalanı (push dahil) sürer.
                    $result = 'IlgisizGecmis'; $detail = 'ortak gecmis yok'
                    Write-EsitleLog "ILGISIZ GECMIS $RepoName/$($r.Branch) <-> $($r.Other)" 'WARN'
                }
                elseif ($mt.ExitCode -ne 0) {
                    throw "merge-tree basarisiz ($RepoName/$($r.Branch)): $($mt.Err)"
                }
                else {
                    $tree = @(Get-GitLines $mt.Out)[0]
                    $msg = "esitle($Machine): $($r.Branch) <- $($r.Other) birlestirildi"
                    $merge = (Invoke-Git -Repo $RepoPath -Arguments @('commit-tree', $tree, '-p', $local, '-p', $target, '-m', $msg)).Out
                    $result = Move-BranchTip $RepoPath $r.Branch $merge $local $current "merge $($r.Other)"
                    if ($result -eq 'Ilerletildi') { $result = 'Birlestirildi' }
                }
            }
        }
        Write-EsitleLog "Converge $RepoName/$($r.Branch) <- $($r.Other): $result $detail"
        $out += [pscustomobject]@{ Repo = $RepoName; Branch = $r.Branch; Other = $r.Other; Result = $result; Detail = $detail }
    }
    return $out
}

# ── Oturum geçmişi (Faz 2) ───────────────────────────────────────────────────
# Claude Code geçmişi: <projects>\<kodlanmış-yol>\<oturum-id>.jsonl (+ alt klasörler: tool-results, subagents).
# Hub: <hubRoot>\<hubDir>\<MAKINE>\<repo>\<ek>\<göreli-yol>.gz + dizin.json. Git'e girmez (boyut + iş verisi).
# Gönderme: yalnız kendi makinenin ad alanına, yalnız ekleme/güncelleme. Alma: son N gün ya da kimlikle.
# Yereldeki daha yeni dosya asla ezilmez. İçeri alınıp değiştirilmeyen dosya geri gönderilmez.

function ConvertTo-ClaudeProjectName {
    param([string]$Path)
    return ($Path.TrimEnd('\', '/') -replace '[^A-Za-z0-9]', '-')
}

function Get-ClaudeProjectsRoot {
    param($Config, [string]$Machine)
    $m = $Config.machines.PSObject.Properties[$Machine]
    if ($m -and ($m.Value.PSObject.Properties.Name -contains 'claudeProjects')) { return $m.Value.claudeProjects }
    $base = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
    return (Join-Path $base 'projects')
}

function Get-SessionHubBase {
    param($Config, [string]$Machine, [string]$RepoName)
    $dir = '_oturumlar'
    if ($Config.PSObject.Properties.Name -contains 'sessions' -and $Config.sessions.PSObject.Properties.Name -contains 'hubDir') { $dir = $Config.sessions.hubDir }
    return (Join-Path (Join-Path (Join-Path ($Config.hubRoot -replace '/', '\') $dir) $Machine) $RepoName)
}

function Read-ImportManifest {
    param([string]$StateDir)
    $p = Join-Path $StateDir 'ice-alinan.json'
    $h = @{}
    if (Test-Path $p) {
        $o = Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($prop in $o.PSObject.Properties) { $h[$prop.Name] = [long]$prop.Value }
    }
    return $h
}

function Save-ImportManifest {
    param([string]$StateDir, [hashtable]$Manifest)
    if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Force $StateDir | Out-Null }
    $o = New-Object psobject
    foreach ($k in $Manifest.Keys) { $o | Add-Member -NotePropertyName $k -NotePropertyValue $Manifest[$k] }
    $o | ConvertTo-Json -Depth 3 | Set-Content -Path (Join-Path $StateDir 'ice-alinan.json') -Encoding UTF8
}

# ── Maskeleme ──
# Bilinen gizli değerler (git dışı ~/.esitle/gizli-degerler.txt, satır başına bir değer, '#' yorum) oturum
# dosyası hub'a giderken '***' olur. JSON içindeki kaçışlı biçim de aranır. Yerel dosyaya dokunulmaz.
# 18.11.2026: üretim ERP sa parolası 13 proje klasöründe 21 oturum dosyasında bulundu.
function Get-RedactList {
    param($Config, [string]$StateDir)
    $p = Join-Path $StateDir 'gizli-degerler.txt'
    if ($Config.PSObject.Properties.Name -contains 'sessions' -and $Config.sessions.PSObject.Properties.Name -contains 'redactFile') {
        $p = [Environment]::ExpandEnvironmentVariables($Config.sessions.redactFile)
    }
    $res = [pscustomobject]@{ Values = @(); Hash = '' }
    if (-not (Test-Path -LiteralPath $p)) { return $res }
    $raw = [IO.File]::ReadAllText($p)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $res.Hash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($raw))) -replace '-', '' } finally { $sha.Dispose() }
    $vals = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($raw -split "`r?`n")) {
        $v = $line.Trim([char]0xFEFF).Trim()
        if (-not $v -or $v.StartsWith('#')) { continue }
        if ($v.Length -lt 4) { Write-EsitleLog "Maskeleme: 4 karakterden kisa deger atlandi (yanlis pozitif riski)" 'WARN'; continue }
        $vals.Add($v)
        $j = (ConvertTo-Json $v).Trim('"')   # JSON içindeki kaçışlı biçim (\" \\ \u..)
        if ($j -ne $v) { $vals.Add($j) }
    }
    # Uzun olan önce: biri öbürünün parçasıysa yarım maske kalmasın.
    $res.Values = @($vals | Sort-Object Length -Descending -Unique)
    return $res
}

function Get-Redacted {
    param([string]$Text, [string[]]$Redact)
    if (-not $Text) { return $Text }
    foreach ($s in @($Redact)) { $Text = $Text.Replace($s, '***') }
    return $Text
}

function Copy-Compressed {
    param([string]$Source, [string]$Target, [switch]$Decompress, [string[]]$Redact = @())
    $dir = Split-Path -Parent $Target
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $tmp = "$Target.esitle-tmp"
    # Claude açık oturuma yazarken de okunabilsin: FileShare ReadWrite.
    $in = [IO.File]::Open($Source, 'Open', 'Read', 'ReadWrite')
    try {
        $out = [IO.File]::Open($tmp, 'Create', 'Write', 'None')
        try {
            if ($Decompress) {
                $gz = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress, $true)
                try { $gz.CopyTo($out) } finally { $gz.Dispose() }
            }
            elseif (@($Redact).Count -gt 0) {
                # Metin olarak satır satır maskele (oturum dosyaları ve tool-results metindir).
                $gz = New-Object IO.Compression.GZipStream($out, [IO.Compression.CompressionLevel]::Optimal, $true)
                $utf8 = New-Object Text.UTF8Encoding $false
                $sr = New-Object IO.StreamReader($in, $utf8, $true, 65536, $true)
                $sw = New-Object IO.StreamWriter($gz, $utf8, 65536, $true)
                try {
                    # Dosyanın tamamı tek seferde: satır başına PowerShell çağrısı milyonlarca satırda
                    # dakikalar sürüyordu (18.11: 18 dk'da 1 dosya). Oturum dosyaları belleğe sığar (<100 MB).
                    $text = $sr.ReadToEnd()
                    foreach ($s in $Redact) { $text = $text.Replace($s, '***') }
                    $sw.Write($text)
                    $text = $null
                }
                finally { $sw.Dispose(); $sr.Dispose(); $gz.Dispose() }
            }
            else {
                $gz = New-Object IO.Compression.GZipStream($out, [IO.Compression.CompressionLevel]::Optimal, $true)
                try { $in.CopyTo($gz) } finally { $gz.Dispose() }
            }
        }
        finally { $out.Dispose() }
    }
    finally { $in.Dispose() }
    if (Test-Path -LiteralPath $Target) { Remove-Item -LiteralPath $Target -Force }
    Move-Item -LiteralPath $tmp -Destination $Target
    (Get-Item -LiteralPath $Target).LastWriteTimeUtc = (Get-Item -LiteralPath $Source).LastWriteTimeUtc
}

function Get-FirstPrompt {
    param([string]$Path)
    try {
        $fs = [IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
        $sr = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)
        try {
            for ($i = 0; $i -lt 400; $i++) {
                $line = $sr.ReadLine()
                if ($null -eq $line) { break }
                if ($line -notmatch '"type"\s*:\s*"user"') { continue }
                $o = $line | ConvertFrom-Json
                # Bazı kullanıcı satırlarında message/text yok (araç sonucu, meta): StrictMode'da atla.
                if (-not ($o.PSObject.Properties.Name -contains 'message')) { continue }
                if (-not ($o.message.PSObject.Properties.Name -contains 'content')) { continue }
                $c = $o.message.content
                $text = $null
                if ($c -is [string]) { $text = $c }
                else {
                    $part = @($c) | Where-Object { $_.PSObject.Properties.Name -contains 'text' -and $_.PSObject.Properties.Name -contains 'type' -and $_.type -eq 'text' } | Select-Object -First 1
                    if ($part) { $text = $part.text }
                }
                if ($text -and $text -notmatch '^\s*<') {
                    $text = ($text -replace '\s+', ' ').Trim()
                    if ($text.Length -gt 120) { $text = $text.Substring(0, 120) + '...' }
                    return $text
                }
            }
        }
        finally { $sr.Dispose() }
    }
    catch { Write-EsitleLog "Ilk istek okunamadi: $Path ($($_.Exception.Message))" 'WARN' }
    return ''
}

function Export-EsitleSessions {
    param(
        [Parameter(Mandatory)][string]$RepoPath, [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][string]$Machine, [Parameter(Mandatory)]$Config,
        [string]$ProjectsRoot = '', [string]$StateDir = ''
    )
    if (-not $ProjectsRoot) { $ProjectsRoot = Get-ClaudeProjectsRoot $Config $Machine }
    if (-not $StateDir) { $StateDir = $script:LogDir }
    $res = [pscustomobject]@{ Repo = $RepoName; Sent = 0; Skipped = 0; Repaired = 0 }
    if (-not (Test-Path -LiteralPath $ProjectsRoot)) { return $res }
    $prefix = ConvertTo-ClaudeProjectName $RepoPath
    $base = Get-SessionHubBase $Config $Machine $RepoName
    $manifest = Read-ImportManifest $StateDir
    $index = @()
    # Maskeleme listesi değiştiyse (ya da bu repo için hiç uygulanmadıysa) bu repo arşivi bir kez baştan yazılır.
    $redact = Get-RedactList $Config $StateDir
    $stateFile = Join-Path $StateDir 'maskeleme-durumu.json'
    $state = @{}
    if (Test-Path -LiteralPath $stateFile) {
        $o = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($prop in $o.PSObject.Properties) { $state[$prop.Name] = [string]$prop.Value }
    }
    $force = (-not $state.ContainsKey($RepoName)) -or ($state[$RepoName] -ne $redact.Hash)
    if (-not $state.ContainsKey($RepoName) -and -not $redact.Hash) { $force = $false }   # liste hiç yok: ilk kayıt
    $touched = @{}
    $dirs = @(Get-ChildItem -LiteralPath $ProjectsRoot -Directory | Where-Object { $_.Name -ieq $prefix -or $_.Name -ilike "$prefix-*" })
    foreach ($d in $dirs) {
        $suffix = $d.Name.Substring($prefix.Length)
        $folder = if ($suffix) { $suffix } else { '_kok' }
        foreach ($f in @(Get-ChildItem -LiteralPath $d.FullName -Recurse -File | Where-Object { $_.Name -notlike '*.esitle-tmp' })) {
            $rel = $f.FullName.Substring($d.FullName.Length).TrimStart('\')
            if ($manifest.ContainsKey($f.FullName) -and $f.LastWriteTimeUtc.Ticks -le $manifest[$f.FullName]) { $res.Skipped++; continue }
            $target = Join-Path (Join-Path $base $folder) ($rel + '.gz')
            $touched[$target] = $true
            $need = $force -or -not (Test-Path -LiteralPath $target)
            if (-not $need) { $need = $f.LastWriteTimeUtc -gt (Get-Item -LiteralPath $target).LastWriteTimeUtc.AddSeconds(2) }
            if ($need) { Copy-Compressed -Source $f.FullName -Target $target -Redact $redact.Values; $res.Sent++ }
            if ($rel -notmatch '\\' -and $f.Extension -eq '.jsonl') {
                $index += [pscustomobject]@{
                    id = $f.BaseName; klasor = $folder; tarih = $f.LastWriteTime.ToString('dd.MM.yyyy HH:mm')
                    zaman = $f.LastWriteTimeUtc.Ticks; boyutMB = [math]::Round($f.Length / 1MB, 1)
                    ilkIstek = (Get-Redacted (Get-FirstPrompt $f.FullName) $redact.Values)
                }
            }
        }
    }
    # Baştan yazımda: yerelde artık karşılığı olmayan hub dosyaları da yerinde maskelenir.
    if ($force -and @($redact.Values).Count -gt 0 -and (Test-Path -LiteralPath $base)) {
        foreach ($g in @(Get-ChildItem -LiteralPath $base -Recurse -File -Filter '*.gz')) {
            if ($touched.ContainsKey($g.FullName)) { continue }
            $plain = $g.FullName.Substring(0, $g.FullName.Length - 3) + '.esitle-acik'
            try {
                Copy-Compressed -Source $g.FullName -Target $plain -Decompress
                Copy-Compressed -Source $plain -Target $g.FullName -Redact $redact.Values
                $res.Repaired++
            }
            finally { if (Test-Path -LiteralPath $plain) { Remove-Item -LiteralPath $plain -Force } }
        }
    }
    if ($index.Count -gt 0) {
        if (-not (Test-Path -LiteralPath $base)) { New-Item -ItemType Directory -Force $base | Out-Null }
        ConvertTo-Json -InputObject @($index | Sort-Object zaman -Descending) -Depth 3 |
            Set-Content -Path (Join-Path $base 'dizin.json') -Encoding UTF8
    }
    $state[$RepoName] = $redact.Hash
    if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Force $StateDir | Out-Null }
    $so = New-Object psobject
    foreach ($k in $state.Keys) { $so | Add-Member -NotePropertyName $k -NotePropertyValue $state[$k] }
    $so | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8
    if ($res.Sent -or $res.Repaired) { Write-EsitleLog "Oturum gonderildi: $RepoName $($res.Sent) dosya, maskeyle duzeltilen $($res.Repaired)" }
    return $res
}

function Import-EsitleSessions {
    param(
        [Parameter(Mandatory)][string]$RepoPath, [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][string]$Machine, [Parameter(Mandatory)]$Config,
        [string]$ProjectsRoot = '', [string]$StateDir = '',
        [int]$Days = -1, [string]$SessionId = '', [switch]$All
    )
    if (-not $ProjectsRoot) { $ProjectsRoot = Get-ClaudeProjectsRoot $Config $Machine }
    if (-not $StateDir) { $StateDir = $script:LogDir }
    if ($Days -lt 0) {
        $Days = 14
        if ($Config.PSObject.Properties.Name -contains 'sessions' -and $Config.sessions.PSObject.Properties.Name -contains 'importDays') { $Days = [int]$Config.sessions.importDays }
    }
    $res = [pscustomobject]@{ Repo = $RepoName; Received = 0; KeptLocal = 0 }
    $machinesDir = Split-Path -Parent (Split-Path -Parent (Get-SessionHubBase $Config $Machine $RepoName))
    if (-not (Test-Path -LiteralPath $machinesDir)) { return $res }
    $prefix = ConvertTo-ClaudeProjectName $RepoPath
    $cutoff = (Get-Date).ToUniversalTime().AddDays(-$Days)
    $manifest = Read-ImportManifest $StateDir
    foreach ($m in @(Get-ChildItem -LiteralPath $machinesDir -Directory | Where-Object { $_.Name -ne $Machine })) {
        $src = Join-Path $m.FullName $RepoName
        if (-not (Test-Path -LiteralPath $src)) { continue }
        foreach ($folderDir in @(Get-ChildItem -LiteralPath $src -Directory)) {
            $suffix = if ($folderDir.Name -eq '_kok') { '' } else { $folderDir.Name }
            $localDir = Join-Path $ProjectsRoot ($prefix + $suffix)
            foreach ($g in @(Get-ChildItem -LiteralPath $folderDir.FullName -Recurse -File -Filter '*.gz')) {
                $rel = $g.FullName.Substring($folderDir.FullName.Length).TrimStart('\')
                $rel = $rel.Substring(0, $rel.Length - 3)
                $sid = [IO.Path]::GetFileNameWithoutExtension(($rel -split '\\')[0])
                if ($SessionId) { if ($sid -ne $SessionId) { continue } }
                elseif (-not $All -and $g.LastWriteTimeUtc -lt $cutoff) { continue }
                $target = Join-Path $localDir $rel
                if (Test-Path -LiteralPath $target) {
                    $t = Get-Item -LiteralPath $target
                    if ($t.LastWriteTimeUtc -gt $g.LastWriteTimeUtc.AddSeconds(2)) { $res.KeptLocal++; continue }
                    if ($t.LastWriteTimeUtc -ge $g.LastWriteTimeUtc.AddSeconds(-2)) { continue }
                }
                Copy-Compressed -Source $g.FullName -Target $target -Decompress
                $manifest[$target] = (Get-Item -LiteralPath $target).LastWriteTimeUtc.Ticks
                $res.Received++
            }
        }
    }
    if ($res.Received) { Save-ImportManifest $StateDir $manifest; Write-EsitleLog "Oturum alindi: $RepoName $($res.Received) dosya" }
    return $res
}

# ── Kendini güncelleme ───────────────────────────────────────────────────────
# Repo dışındaki kopya (ör. SANAL-FIKRI C:\dev\_esitle, SURUM.txt taşır) her Sync sonunda, eşitlenmiş
# repodaki dalın ucu kopyadan İLERİDEYSE kendini git archive ile yeniler; değişiklik bir sonraki koşuda
# devreye girer. Yalnız ileri: dal geri alınmış ya da ayrışmışsa dokunmaz (18.11: kopya elle taşınıyordu).
function Update-EsitleSelf {
    param(
        [Parameter(Mandatory)][string]$CopyRoot, [Parameter(Mandatory)][string]$RepoPath,
        [Parameter(Mandatory)][string]$Branch, [Parameter(Mandatory)][string[]]$Paths
    )
    $verFile = Join-Path $CopyRoot 'SURUM.txt'
    $current = ''
    if (Test-Path -LiteralPath $verFile) { $current = ([IO.File]::ReadAllText($verFile)).Trim([char]0xFEFF, ' ', "`r", "`n", "`t") }
    $tip = Get-GitRef $RepoPath "refs/heads/$Branch"
    if (-not $tip) { return 'DalYok' }
    if ($current -eq $tip) { return 'Guncel' }
    if ($current -and -not (Test-GitRef $RepoPath $current)) {
        # Kopyanın sürümü repoda yok: kopya repodan yeni (elle konmuş) olabilir. Geri alma riski -> dokunma.
        Write-EsitleLog "Kendini guncelleme atlandi: kopya surumu ($($current.Substring(0, [Math]::Min(7, $current.Length)))) repoda bilinmiyor" 'WARN'
        return 'AtlandiBilinmeyen'
    }
    if ($current) {
        $ahead = (Invoke-Git -Repo $RepoPath -Arguments @('merge-base', '--is-ancestor', $current, $tip) -AllowFail).ExitCode -eq 0
        if (-not $ahead) {
            Write-EsitleLog "Kendini guncelleme atlandi: $Branch ($($tip.Substring(0,7))) kopyadan ($($current.Substring(0,7))) ileride degil" 'WARN'
            return 'AtlandiGeride'
        }
    }
    # Dosyaları git doğrudan yazar (geçici index + checkout-index). Eskiden TEMP'e zip açıp PowerShell ile
    # kendi .ps1'lerinin üstüne kopyalıyordu; Bitdefender ATC bu "indir-aç-üstüne yaz" desenini zararlı
    # sayıp betiği karantinaya aldı (19.11.2026 BT-FIKRI). Repo index'ine ve çalışma ağacına dokunulmaz.
    $gitDir = (Invoke-Git -Repo $RepoPath -Arguments @('rev-parse', '--absolute-git-dir')).Out
    $tmpIndex = Join-Path $gitDir ("esitle-self-index-" + $PID + ".tmp")
    try {
        $gitEnv = @{ GIT_INDEX_FILE = $tmpIndex }
        Invoke-Git -Repo $RepoPath -Env $gitEnv -Arguments @('read-tree', $tip) | Out-Null
        $files = @(Get-GitLines -NullSeparated (Invoke-Git -Repo $RepoPath -Env $gitEnv -Arguments (@('ls-files', '-z', '--') + $Paths)).Out)
        if ($files.Count -eq 0) { throw "kendini guncelleme: $Branch dalinda yol bulunamadi: $($Paths -join ', ')" }
        $prefix = (($CopyRoot.TrimEnd('\', '/')) -replace '\\', '/') + '/'
        Invoke-Git -Repo $RepoPath -Env $gitEnv -Arguments (@('checkout-index', '-f', "--prefix=$prefix", '--') + $files) | Out-Null
        [IO.File]::WriteAllText($verFile, $tip + "`n", (New-Object Text.ASCIIEncoding))
    }
    finally {
        if (Test-Path -LiteralPath $tmpIndex) { Remove-Item -LiteralPath $tmpIndex -Force }
    }
    $from = if ($current) { $current.Substring(0, [Math]::Min(7, $current.Length)) } else { '?' }
    Write-EsitleLog "Kendini guncelledi: $from -> $($tip.Substring(0,7)) ($Branch)"
    return 'Guncellendi'
}

# ── Main ─────────────────────────────────────────────────────────────────────
function Invoke-EsitleMain {
    $cfgPath = if ($ConfigPath) { $ConfigPath } else { Join-Path $PSScriptRoot 'esitle.json' }
    $config = Get-EsitleConfig -Path $cfgPath
    if ($FromHook) {
        $raw = [Console]::In.ReadToEnd()
        $hook = $raw | ConvertFrom-Json
        if (-not $RepoPath) {
            # Oturum alt klasörde açılmış olabilir: repo köküne çık.
            $top = Invoke-Git -Repo $hook.cwd -Arguments @('rev-parse', '--show-toplevel') -AllowFail
            if ($top.ExitCode -ne 0) { Write-EsitleLog "Hook: git reposu degil, atlandi: $($hook.cwd)"; return 0 }
            $script:RepoPath = ($top.Out -replace '/', '\')
        }
        if (-not $Message) {
            $sid = if ($hook.PSObject.Properties.Name -contains 'session_id') { ([string]$hook.session_id).Substring(0, [Math]::Min(8, ([string]$hook.session_id).Length)) } else { '?' }
            $why = if ($hook.PSObject.Properties.Name -contains 'reason') { $hook.reason } else { '' }
            $script:Message = ("oturum sonu $sid $why").Trim()
        }
    }
    $targets = @()
    if ($RepoPath) {
        $full = (Resolve-Path $RepoPath).Path.TrimEnd('\')
        $entry = $config.repos | Where-Object {
            (Get-RepoPathFor $config $Machine $_).TrimEnd('\') -ieq $full
        } | Select-Object -First 1
        if (-not $entry) {
            # Kapsam dışı repo (hook her projede çalışır): sessiz çıkış değil, logla.
            Write-EsitleLog "Kapsam disi repo, atlandi: $full"
            return 0
        }
        $targets += $entry
    }
    else { $targets = @($config.repos) }

    $hubOk = Test-Path ($config.hubRoot -replace '/', '\')
    if ($Mode -eq 'Sync' -and -not $hubOk) {
        Write-EsitleLog "Hub erisilemiyor: $($config.hubRoot)" 'WARN'
        if (-not $Quiet) { Write-Warning "Hub erisilemiyor: $($config.hubRoot). Yalniz anlik goruntu alinacak." }
    }

    $exit = 0
    $summary = @()
    $report = @()
    foreach ($t in $targets) {
        $path = Get-RepoPathFor $config $Machine $t
        if (-not (Test-Path (Join-Path $path '.git'))) {
            $summary += [pscustomobject]@{ Repo = $t.name; Status = 'RepoYok'; Detail = $path }
            continue
        }
        try {
            switch ($Mode) {
                'Snapshot' {
                    $r = Invoke-EsitleSnapshot -RepoPath $path -Machine $Machine -Config $config -Message $Message
                    $summary += [pscustomobject]@{ Repo = $t.name; Status = $r.Status; Detail = (@($r.Detail) + @($r.Skipped)) -join ', ' }
                    if ($r.Status -eq 'SecretRisk') { $exit = 1 }
                }
                'Sync' {
                    if ($hubOk) {
                        $r = Invoke-EsitleSync -RepoPath $path -RepoName $t.name -Machine $Machine -Config $config -Message $Message
                        $snap = if ($r.Snapshot) { $r.Snapshot.Status } else { '-' }
                        $conv = (@($r.Converge) | Group-Object Result | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' '
                        $summary += [pscustomobject]@{ Repo = $t.name; Status = $r.Status; Detail = "snapshot: $snap $conv $($r.Detail)".Trim() }
                        foreach ($c in @($r.Converge) | Where-Object { $_.Result -in @('Cakisma', 'IlgisizGecmis') }) {
                            $summary += [pscustomobject]@{ Repo = $t.name; Status = $c.Result; Detail = "$($c.Branch) <-> $($c.Other): $($c.Detail)" }
                        }
                        if ($r.Snapshot -and $r.Snapshot.Status -eq 'SecretRisk') { $exit = 1 }
                    }
                    else {
                        $r = Invoke-EsitleSnapshot -RepoPath $path -Machine $Machine -Config $config -Message $Message
                        $summary += [pscustomobject]@{ Repo = $t.name; Status = "HubYok/$($r.Status)"; Detail = '' }
                    }
                    $report += Get-EsitleReport -RepoPath $path -RepoName $t.name -Machine $Machine
                }
                'Report' { $report += Get-EsitleReport -RepoPath $path -RepoName $t.name -Machine $Machine }
                'Converge' {
                    $autoMerge = if ($config.PSObject.Properties.Name -contains 'autoMerge') { [bool]$config.autoMerge } else { $true }
                    $cv = Invoke-EsitleConverge -RepoPath $path -RepoName $t.name -Machine $Machine -AutoMerge $autoMerge
                    foreach ($x in @($cv)) { $summary += [pscustomobject]@{ Repo = $t.name; Status = $x.Result; Detail = "$($x.Branch) <- $($x.Other) $($x.Detail)".Trim() } }
                }
            }
        }
        catch {
            $exit = 1
            Write-EsitleLog "HATA $($t.name): $($_.Exception.Message)" 'ERROR'
            $summary += [pscustomobject]@{ Repo = $t.name; Status = 'Hata'; Detail = $_.Exception.Message }
        }
    }

    # Kendini güncelleme: yalnız repo dışı kopyada (SURUM.txt) ve Sync'te.
    $copyRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    if ($Mode -eq 'Sync' -and (Test-Path (Join-Path $copyRoot 'SURUM.txt')) -and ($config.PSObject.Properties.Name -contains 'selfUpdate')) {
        try {
            $su = $config.selfUpdate
            $suEntry = $config.repos | Where-Object { $_.name -eq $su.repo } | Select-Object -First 1
            if (-not $suEntry) { throw "selfUpdate.repo ayarda yok: $($su.repo)" }
            $suRes = Update-EsitleSelf -CopyRoot $copyRoot -RepoPath (Get-RepoPathFor $config $Machine $suEntry) -Branch $su.branch -Paths @($su.paths)
            if ($suRes -ne 'Guncel') { $summary += [pscustomobject]@{ Repo = '(esitle)'; Status = "KendiniGuncelle:$suRes"; Detail = $su.branch } }
        }
        catch {
            $exit = 1
            Write-EsitleLog "HATA kendini guncelleme: $($_.Exception.Message)" 'ERROR'
            $summary += [pscustomobject]@{ Repo = '(esitle)'; Status = 'KendiniGuncelleHata'; Detail = $_.Exception.Message }
        }
    }
    # Oturum geçmişi (Faz 2): Sync'te ve Sessions modunda, hub erişilebilirse.
    $sessOn = ($config.PSObject.Properties.Name -contains 'sessions') -and [bool]$config.sessions.enabled
    if ($hubOk -and (($Mode -eq 'Sync' -and $sessOn) -or $Mode -eq 'Sessions')) {
        foreach ($t in $targets) {
            $path = Get-RepoPathFor $config $Machine $t
            try {
                $ex = Export-EsitleSessions -RepoPath $path -RepoName $t.name -Machine $Machine -Config $config
                $imArgs = @{ RepoPath = $path; RepoName = $t.name; Machine = $Machine; Config = $config }
                if ($SessionId) { $imArgs.SessionId = $SessionId }
                if ($AllSessions) { $imArgs.All = $true }
                $im = Import-EsitleSessions @imArgs
                if ($ex.Sent -or $im.Received -or $im.KeptLocal) {
                    $summary += [pscustomobject]@{ Repo = $t.name; Status = 'Oturum'; Detail = "gonderilen $($ex.Sent), alinan $($im.Received), yerelde daha yeni $($im.KeptLocal)" }
                }
            }
            catch {
                $exit = 1
                Write-EsitleLog "HATA oturum $($t.name): $($_.Exception.Message)" 'ERROR'
                $summary += [pscustomobject]@{ Repo = $t.name; Status = 'OturumHata'; Detail = $_.Exception.Message }
            }
        }
    }

    if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Force $script:LogDir | Out-Null }
    [pscustomobject]@{
        Zaman = (Get-Date).ToString('dd.MM.yyyy HH:mm:ss'); Makine = $Machine; Mod = $Mode
        Ozet = $summary; Rapor = $report
    } | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $script:LogDir $(if ($Mode -eq 'Snapshot') { 'son-anlik.json' } else { 'son-rapor.json' })) -Encoding UTF8  # oturum sonu anlık görüntüsü eşitleme raporunu ezmesin

    if (-not $Quiet) {
        if ($summary.Count) { $summary | Format-Table -AutoSize | Out-String -Width 200 | Write-Host }
        if ($report.Count) {
            $report | Where-Object { $_.State -ne 'Ayni' } | Sort-Object Repo, State, Branch |
                Format-Table Repo, Branch, Other, State, Ahead, Behind, OtherDate -AutoSize | Out-String -Width 200 | Write-Host
        }
    }
    if ($Mode -eq 'Sync' -and -not $hubOk) { return 2 }
    if ($exit -eq 0 -and @($summary | Where-Object { $_.Status -in @('Cakisma', 'IlgisizGecmis') }).Count -gt 0) { return 3 }
    return $exit
}

if ($MyInvocation.InvocationName -ne '.') {
    $code = 1
    try { $code = Invoke-EsitleMain }
    catch {
        Write-EsitleLog "Beklenmeyen hata: $($_.Exception.Message)" 'ERROR'
        Write-Error $_
        $code = 1
    }
    exit $code
}
