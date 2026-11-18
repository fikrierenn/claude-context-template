<#
.SYNOPSIS
  esitle kurulumu (plan 58): Görev Zamanlayıcı + Claude Code SessionEnd hook'u + eksik hub repoları.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File kur.ps1                    # görev + hook
  powershell -ExecutionPolicy Bypass -File kur.ps1 -HubOlustur ens.git,mimbal.git
  powershell -ExecutionPolicy Bypass -File kur.ps1 -Kaldir

.NOTES
  -HubOlustur paylaşılan sunucuya yazar: yalnız adı açıkça verilen bare repolar oluşturulur.
  Hook, ~/.claude/settings.json'a yedek alınarak eklenir (settings.json.esitle-yedek-<tarih>).
#>
[CmdletBinding()]
param(
    [switch]$Kaldir,
    [string[]]$HubOlustur = @(),
    [switch]$HookYok,
    [switch]$GorevYok
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$esitle = Join-Path $PSScriptRoot 'esitle.ps1'
$configPath = Join-Path $PSScriptRoot 'esitle.json'
$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$taskName = 'esitle'
$settings = Join-Path $env:USERPROFILE '.claude\settings.json'
$hookMarker = 'esitle.ps1'

if (-not ($config.machines.PSObject.Properties.Name -contains $env:COMPUTERNAME)) {
    throw "Bu makine ($env:COMPUTERNAME) esitle.json > machines icinde yok. Once ekleyin."
}

# ── Hook (python ile JSON birleştirme: settings.json biçimi bozulmasın) ──────
function Set-SessionEndHook {
    param([bool]$Remove)
    $cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $esitle + '" -Mode Snapshot -FromHook -Quiet'
    $py = @'
import json, os, sys, shutil, datetime
path, marker, remove = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
cmd = os.environ["ESITLE_HOOK_CMD"]  # argv degil: PS 5.1 gomulu tirnaklari siler
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    shutil.copy2(path, path + ".esitle-yedek-" + datetime.datetime.now().strftime("%d%m%Y-%H%M%S"))
hooks = data.setdefault("hooks", {})
groups = hooks.get("SessionEnd", [])
cleaned = []
for g in groups:
    hs = [h for h in g.get("hooks", []) if marker not in h.get("command", "")]
    if hs:
        g["hooks"] = hs
        cleaned.append(g)
if not remove:
    cleaned.append({"hooks": [{"type": "command", "command": cmd, "timeout": 60}]})
if cleaned:
    hooks["SessionEnd"] = cleaned
else:
    hooks.pop("SessionEnd", None)
if not hooks:
    data.pop("hooks", None)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
print("hook " + ("kaldirildi" if remove else "eklendi") + ": " + path)
'@
    $tmp = Join-Path $env:TEMP ("esitle-hook-" + [guid]::NewGuid().ToString('N') + '.py')
    Set-Content -Path $tmp -Value $py -Encoding UTF8
    try {
        $env:ESITLE_HOOK_CMD = $cmd
        & python -I $tmp $settings $hookMarker $(if ($Remove) { '1' } else { '0' })
        if ($LASTEXITCODE -ne 0) { throw "settings.json guncellenemedi (python cikis $LASTEXITCODE)" }
    }
    finally { if ([IO.File]::Exists($tmp)) { [IO.File]::Delete($tmp) } }  # Remove-Item 8.3 kisa yolu (FIKRI~1.ERE) cozemiyor
}

# ── Görev Zamanlayıcı: oturum açılışı + 30 dk + ağ bağlanınca ────────────────
function Set-SyncTask {
    $user = "$env:USERDOMAIN\$env:USERNAME"
    # Oturum tetiğinin tekrarı yalnız bir sonraki girişte başlar; kayıttan hemen sonra da 30 dk döngü için zaman tetiği.
    $start = (Get-Date).AddMinutes(2).ToString('yyyy-MM-ddTHH:mm:ss')  # Görev XML biçimi (ISO 8601) zorunlu
    $taskArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File &quot;$esitle&quot; -Mode Sync -Quiet"
    $xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>esitle: makineler arasi iki yonlu git esitleme (plan 58)</Description></RegistrationInfo>
  <Triggers>
    <LogonTrigger><Enabled>true</Enabled><UserId>$user</UserId><Delay>PT2M</Delay>
      <Repetition><Interval>PT30M</Interval><StopAtDurationEnd>false</StopAtDurationEnd></Repetition>
    </LogonTrigger>
    <TimeTrigger><Enabled>true</Enabled><StartBoundary>$start</StartBoundary>
      <Repetition><Interval>PT30M</Interval><StopAtDurationEnd>false</StopAtDurationEnd></Repetition>
    </TimeTrigger>
    <EventTrigger><Enabled>true</Enabled><Delay>PT1M</Delay>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"&gt;&lt;Select Path="Microsoft-Windows-NetworkProfile/Operational"&gt;*[System[(EventID=10000)]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals><Principal id="Author"><UserId>$user</UserId><LogonType>InteractiveToken</LogonType><RunLevel>LeastPrivilege</RunLevel></Principal></Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT20M</ExecutionTimeLimit>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <Enabled>true</Enabled>
  </Settings>
  <Actions Context="Author"><Exec><Command>powershell.exe</Command><Arguments>$taskArgs</Arguments></Exec></Actions>
</Task>
"@
    Register-ScheduledTask -TaskName $taskName -Xml $xml -Force | Out-Null
    Write-Host "Gorev kaydedildi: $taskName (simdi+2 dk itibariyle 30 dk dongu + oturum acilisi + ag baglaninca)"
}

# ── Hub'da eksik bare repo ───────────────────────────────────────────────────
function New-HubRepo {
    param([string]$Name)
    $known = @($config.repos | ForEach-Object { $_.hub })
    if ($known -notcontains $Name) { throw "$Name esitle.json repos listesinde yok." }
    $path = (($config.hubRoot.TrimEnd('/', '\') + '/' + $Name) -replace '/', '\')
    if (Test-Path $path) { Write-Host "Zaten var: $path"; return }
    & git init -q --bare $path
    if ($LASTEXITCODE -ne 0) { throw "bare repo olusturulamadi: $path" }
    # Yönetici paylaşımı (C$) üzerinden açılan klasörün sahibi BUILTIN\Administrators olur ve
    # git push "dubious ownership" ile reddeder (18.11 nexusflow.git vakası). Sahibi kullanıcıya çevir.
    & icacls $path /setowner "$env:USERDOMAIN\$env:USERNAME" /T /C /Q | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "sahiplik ayarlanamadi: $path" }
    Write-Host "Hub repo olusturuldu: $path"
}

# ── Kural: kullanıcı düzeyi CLAUDE.md'ye import (tüm projelerde yüklenir) ───
function Set-RuleImport {
    param([bool]$Remove)
    $userMd = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
    $rule = (Resolve-Path (Join-Path $PSScriptRoot '..\..\templates\.claude\rules\_universal\cikti-yeri.md')).Path -replace '\\', '/'
    $line = "@$rule"
    $lines = @()
    if (Test-Path $userMd) { $lines = @(Get-Content $userMd -Encoding UTF8) }
    $kept = @($lines | Where-Object { $_ -notmatch 'cikti-yeri\.md' -and $_ -ne '<!-- esitle: plan 58 -->' })
    if (-not $Remove) { $kept += @('<!-- esitle: plan 58 -->', $line) }
    if ($kept.Count -eq 0 -and (Test-Path $userMd)) { Remove-Item $userMd; Write-Host "Kural importu kaldirildi: $userMd"; return }
    [IO.File]::WriteAllText($userMd, (($kept -join "`n") + "`n"), (New-Object Text.UTF8Encoding $false))
    Write-Host ("Kural importu " + $(if ($Remove) { 'kaldirildi' } else { 'eklendi' }) + ": $userMd -> $line")
}

if ($Kaldir) {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Gorev kaldirildi: $taskName"
    }
    Set-SessionEndHook -Remove $true
    Set-RuleImport -Remove $true
    return
}

# ── Hub yolları için safe.directory (global) ─────────────────────────────────
# git 2.5x ağ paylaşımındaki repoların sahibini doğrulayamıyor ("may refer to a non-local directory")
# ve push'u reddediyor (18.11 SANAL-FIKRI, git 2.55). Komut satırı -c push'ta karşı tarafa geçmediği
# için global ayar gerekiyor. YALNIZ esitle.json'daki hub yolları eklenir, '*' asla.
function Set-HubSafeDirectory {
    $have = @(& git config --global --get-all safe.directory 2>$null)
    foreach ($r in $config.repos) {
        $url = (($config.hubRoot.TrimEnd('/', '\') + '/' + $r.hub) -replace '\\', '/')
        if ($have -notcontains $url) {
            & git config --global --add safe.directory $url
            if ($LASTEXITCODE -ne 0) { throw "safe.directory eklenemedi: $url" }
            Write-Host "safe.directory eklendi: $url"
        }
    }
}
foreach ($h in $HubOlustur) { New-HubRepo $h }
Set-HubSafeDirectory
if (-not $GorevYok) { Set-SyncTask }
if (-not $HookYok) { Set-SessionEndHook -Remove $false }
Set-RuleImport -Remove $false

# Kurulum özeti: hub'da olmayan repolar
$missing = @($config.repos | Where-Object { -not (Test-Path ((($config.hubRoot.TrimEnd('/', '\') + '/' + $_.hub) -replace '/', '\'))) })
if ($missing.Count) {
    Write-Warning ("Hub'da olmayan repolar (esitlenmez): " + (($missing | ForEach-Object { $_.hub }) -join ', ') +
        ". Olusturmak icin: kur.ps1 -HubOlustur <ad.git>,...")
}
