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
    [ValidateSet('Snapshot', 'Sync', 'Report', 'Converge')]
    [string]$Mode = 'Report',
    [string]$RepoPath,
    [string]$Message = '',
    [string]$ConfigPath = '',
    [string]$Machine = $env:COMPUTERNAME,
    [switch]$Quiet,
    # Claude Code SessionEnd hook'u: stdin'den {cwd, session_id, reason} JSON'u okunur.
    [switch]$FromHook
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
    Invoke-Git -Repo $RepoPath -Arguments @('push', '-q', '--no-verify', $hubUrl, "+refs/heads/*:refs/makine/$Machine/*") | Out-Null
    # Push sonrası kendi ad alanımızın yerel aynasını tazele (rapor tutarlılığı).
    Invoke-Git -Repo $RepoPath -Arguments @('fetch', '-q', '--prune', $hubUrl, "+refs/makine/${Machine}/*:refs/esitle/${Machine}/*") | Out-Null

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

    if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Force $script:LogDir | Out-Null }
    [pscustomobject]@{
        Zaman = (Get-Date).ToString('dd.MM.yyyy HH:mm:ss'); Makine = $Machine; Mod = $Mode
        Ozet = $summary; Rapor = $report
    } | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $script:LogDir 'son-rapor.json') -Encoding UTF8

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
