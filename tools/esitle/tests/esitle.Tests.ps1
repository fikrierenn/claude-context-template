# Pester 3.4 tests for esitle.ps1
# Run: Invoke-Pester tools\esitle\tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = Join-Path (Split-Path -Parent $here) 'esitle.ps1'
. $script   # dot-source: loads functions only
$script:LogDir = Join-Path ([System.IO.Path]::GetTempPath()) 'esitle-test-log'   # gercek log kirlenmesin

function New-TestGit {
    param([string]$Path, [string[]]$GitArgs)
    $out = & git -C $Path @GitArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed: $out" }
    return $out
}

function New-Sandbox {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("esitle-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $hubRoot = Join-Path $root 'hub'
    $devA = Join-Path $root 'A'
    $devB = Join-Path $root 'B'
    New-Item -ItemType Directory -Force $hubRoot, $devA, $devB | Out-Null
    & git init -q --bare (Join-Path $hubRoot 'proj.git') | Out-Null

    foreach ($dev in @($devA, $devB)) {
        $repo = Join-Path $dev 'proj'
        New-Item -ItemType Directory -Force $repo | Out-Null
        & git -C $repo init -q -b main | Out-Null
        & git -C $repo config user.name 'Test' | Out-Null
        & git -C $repo config user.email 'test@example.invalid' | Out-Null
        & git -C $repo config core.autocrlf false | Out-Null
    }
    # Shared first commit: A creates, pushes to hub main, B fetches it.
    $repoA = Join-Path $devA 'proj'
    $repoB = Join-Path $devB 'proj'
    Set-Content -Path (Join-Path $repoA 'readme.txt') -Value 'ilk' -Encoding UTF8
    Set-Content -Path (Join-Path $repoA '.gitignore') -Value 'yoksay/' -Encoding UTF8
    New-TestGit $repoA @('add', '-A') | Out-Null
    New-TestGit $repoA @('commit', '-q', '-m', 'ilk') | Out-Null
    $hubUrl = (Join-Path $hubRoot 'proj.git')
    New-TestGit $repoA @('push', '-q', $hubUrl, 'main:refs/heads/main') | Out-Null
    New-TestGit $repoB @('fetch', '-q', $hubUrl, 'main') | Out-Null
    New-TestGit $repoB @('reset', '-q', '--hard', 'FETCH_HEAD') | Out-Null

    $config = [pscustomobject]@{
        hubRoot        = $hubRoot
        maxFileMB      = 1
        machines       = [pscustomobject]@{
            A = [pscustomobject]@{ devRoot = $devA }
            B = [pscustomobject]@{ devRoot = $devB }
        }
        repos          = @([pscustomobject]@{ name = 'proj'; hub = 'proj.git' })
        secretPatterns = @('(^|/)\.env(\.[^/]*)?$', '\.(pfx|p12|pem|key)$', '(^|/)\.secrets/')
        secretAllow    = @('\.(example|sample|template)$')
    }
    $configPath = Join-Path $root 'esitle.json'
    $config | ConvertTo-Json -Depth 6 | Set-Content -Path $configPath -Encoding UTF8
    return [pscustomobject]@{
        Root = $root; Hub = $hubRoot; HubUrl = $hubUrl
        RepoA = $repoA; RepoB = $repoB; ConfigPath = $configPath
        Config = (Get-EsitleConfig -Path $configPath)
    }
}

function Get-RefOrNull {
    param([string]$Repo, [string]$Ref)
    $out = & git -C $Repo rev-parse -q --verify $Ref 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return $out
}

Describe 'Snapshot (Invoke-EsitleSnapshot)' {
    It 'calisma agacina, HEAD''e ve index''e dokunmadan wip/<makine> commit''i uretir' {
        $s = New-Sandbox
        Set-Content (Join-Path $s.RepoA 'yeni.txt') 'izlenmeyen dosya' -Encoding UTF8
        Add-Content (Join-Path $s.RepoA 'readme.txt') 'degisti'
        Set-Content (Join-Path $s.RepoA 'staged.txt') 'staged' -Encoding UTF8
        New-TestGit $s.RepoA @('add', 'staged.txt') | Out-Null

        $headBefore = Get-RefOrNull $s.RepoA 'HEAD'
        $statusBefore = (& git -C $s.RepoA status --porcelain) -join "`n"

        $r = Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config -Message 'deneme'

        $r.Status | Should Be 'Committed'
        (Get-RefOrNull $s.RepoA 'HEAD') | Should Be $headBefore
        ((& git -C $s.RepoA status --porcelain) -join "`n") | Should Be $statusBefore
        $files = & git -C $s.RepoA ls-tree -r --name-only 'refs/heads/wip/A'
        ($files -contains 'yeni.txt') | Should Be $true
        ($files -contains 'staged.txt') | Should Be $true
        (& git -C $s.RepoA show 'refs/heads/wip/A:readme.txt') -join "`n" | Should Match 'degisti'
        (& git -C $s.RepoA log -1 --format=%s 'refs/heads/wip/A') | Should Match 'deneme'
    }

    It 'degisiklik yoksa yeni commit uretmez' {
        $s = New-Sandbox
        Set-Content (Join-Path $s.RepoA 'yeni.txt') 'x' -Encoding UTF8
        Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config | Out-Null
        $tip1 = Get-RefOrNull $s.RepoA 'refs/heads/wip/A'
        $r = Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'NoChange'
        (Get-RefOrNull $s.RepoA 'refs/heads/wip/A') | Should Be $tip1
    }

    It 'temiz calisma agacinda wip dali acmaz' {
        $s = New-Sandbox
        $r = Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'NoChange'
        (Get-RefOrNull $s.RepoA 'refs/heads/wip/A') | Should Be $null
    }

    It 'ignore edilmemis sir dosyasi varsa repoyu atlar' {
        $s = New-Sandbox
        Set-Content (Join-Path $s.RepoA '.env') 'PAROLA=gizli' -Encoding UTF8
        Set-Content (Join-Path $s.RepoA 'yeni.txt') 'x' -Encoding UTF8
        $r = Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'SecretRisk'
        ($r.Detail -join ' ') | Should Match '\.env'
        (Get-RefOrNull $s.RepoA 'refs/heads/wip/A') | Should Be $null
    }

    It 'izinli ornek dosyayi (.env.example) sir saymaz' {
        $s = New-Sandbox
        Set-Content (Join-Path $s.RepoA '.env.example') 'PAROLA=' -Encoding UTF8
        $r = Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'Committed'
    }

    It 'boyut sinirini asan dosyayi disarida birakir ve raporlar' {
        $s = New-Sandbox
        $big = Join-Path $s.RepoA 'buyuk.bin'
        $bytes = New-Object byte[] (2MB); [System.IO.File]::WriteAllBytes($big, $bytes)
        Set-Content (Join-Path $s.RepoA 'kucuk.txt') 'x' -Encoding UTF8
        $r = Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'Committed'
        ($r.Skipped -contains 'buyuk.bin') | Should Be $true
        $files = & git -C $s.RepoA ls-tree -r --name-only 'refs/heads/wip/A'
        ($files -contains 'buyuk.bin') | Should Be $false
        ($files -contains 'kucuk.txt') | Should Be $true
    }

    It 'ignore edilen klasoru almaz' {
        $s = New-Sandbox
        New-Item -ItemType Directory (Join-Path $s.RepoA 'yoksay') | Out-Null
        Set-Content (Join-Path $s.RepoA 'yoksay\a.txt') 'x' -Encoding UTF8
        Set-Content (Join-Path $s.RepoA 'b.txt') 'x' -Encoding UTF8
        Invoke-EsitleSnapshot -RepoPath $s.RepoA -Machine 'A' -Config $s.Config | Out-Null
        $files = & git -C $s.RepoA ls-tree -r --name-only 'refs/heads/wip/A'
        ($files -contains 'yoksay/a.txt') | Should Be $false
    }
}

Describe 'Sync (Invoke-EsitleSync)' {
    It 'hub''da yalniz kendi ad alanina yazar, refs/heads''e dokunmaz' {
        $s = New-Sandbox
        $hubMainBefore = & git -C $s.HubUrl rev-parse refs/heads/main
        Set-Content (Join-Path $s.RepoA 'yeni.txt') 'x' -Encoding UTF8
        New-TestGit $s.RepoA @('commit', '-q', '--allow-empty', '-m', 'A ilerledi') | Out-Null

        $r = Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'Synced'

        (& git -C $s.HubUrl rev-parse refs/heads/main) | Should Be $hubMainBefore
        $refs = & git -C $s.HubUrl for-each-ref --format='%(refname)'
        ($refs -contains 'refs/makine/A/main') | Should Be $true
        ($refs -contains 'refs/makine/A/wip/A') | Should Be $true
        @($refs | Where-Object { $_ -like 'refs/makine/B/*' }).Count | Should Be 0
    }

    It 'ayna push''u projenin pre-push kapisina takilmaz (teslim push''u degildir)' {
        $s = New-Sandbox
        $hooks = Join-Path $s.RepoA '.git\hooks'
        [IO.File]::WriteAllText((Join-Path $hooks 'pre-push'), "#!/bin/sh`necho kapi reddetti >&2`nexit 1`n")
        New-TestGit $s.RepoA @('commit', '-q', '--allow-empty', '-m', 'A ilerledi') | Out-Null
        $r = Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'Synced'
        (& git -C $s.HubUrl rev-parse refs/makine/A/main) | Should Be (Get-RefOrNull $s.RepoA 'refs/heads/main')
        # Kapi yerinde duruyor: normal push hala reddediliyor
        $normal = Invoke-Git -Repo $s.RepoA -Arguments @('push', '-q', $s.HubUrl, 'main:refs/heads/deneme') -AllowFail
        $normal.ExitCode | Should Not Be 0
        $normal.Err | Should Match 'kapi reddetti'
    }

    It 'diger makinenin dallarini refs/esitle/<makine>/ altina ceker' {
        $s = New-Sandbox
        New-TestGit $s.RepoB @('commit', '-q', '--allow-empty', '-m', 'B isi') | Out-Null
        Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config | Out-Null
        Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config | Out-Null
        (Get-RefOrNull $s.RepoA 'refs/esitle/B/main') | Should Be (Get-RefOrNull $s.RepoB 'refs/heads/main')
    }

    It 'hub erisilemezse HubUnreachable doner' {
        $s = New-Sandbox
        $s.Config.hubRoot = Join-Path $s.Root 'olmayan-hub'
        Set-Content (Join-Path $s.RepoA 'yeni.txt') 'x' -Encoding UTF8
        $r = Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config
        $r.Status | Should Be 'HubMissing'
        $r.Snapshot.Status | Should Be 'Committed'
    }
}

Describe 'Report' {
    It 'geride / ayrismis / ayni durumlarini dogru siniflar' {
        $s = New-Sandbox
        # B ilerler -> A geride
        New-TestGit $s.RepoB @('commit', '-q', '--allow-empty', '-m', 'B1') | Out-Null
        Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config | Out-Null
        # Yalniz fetch (converge yok) -> rapor ham durumu gostermeli
        New-TestGit $s.RepoA @('fetch', '-q', $s.HubUrl, '+refs/makine/*:refs/esitle/*') | Out-Null
        $rows = Get-EsitleReport -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A'
        ($rows | Where-Object { $_.Branch -eq 'main' -and $_.Other -eq 'B' }).State | Should Be 'Geride'

        # A da ilerler -> ayrismis
        New-TestGit $s.RepoA @('commit', '-q', '--allow-empty', '-m', 'A1') | Out-Null
        $rows = Get-EsitleReport -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A'
        ($rows | Where-Object { $_.Branch -eq 'main' -and $_.Other -eq 'B' }).State | Should Be 'Ayrismis'
    }

}

function Add-TestCommit {
    param([string]$Repo, [string]$File, [string]$Text, [string]$Msg)
    Set-Content (Join-Path $Repo $File) $Text -Encoding UTF8
    New-TestGit $Repo @('add', '--', $File) | Out-Null
    New-TestGit $Repo @('commit', '-q', '-m', $Msg) | Out-Null
}

Describe 'Iki yonlu esitleme (Sync + Converge)' {
    It 'geride olan aktif dal ileri sarilir ve calisma agaci guncellenir' {
        $s = New-Sandbox
        Add-TestCommit $s.RepoB 'b.txt' 'B' 'B1'
        Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config | Out-Null
        $r = Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config
        (Get-RefOrNull $s.RepoA 'refs/heads/main') | Should Be (Get-RefOrNull $s.RepoB 'refs/heads/main')
        (Test-Path (Join-Path $s.RepoA 'b.txt')) | Should Be $true
        (@($r.Converge) | Where-Object { $_.Branch -eq 'main' }).Result | Should Be 'Ilerletildi'
    }

    It 'ayrismis dal cakismasizsa iki tarafta da ayni commit''e oturur' {
        $s = New-Sandbox
        Add-TestCommit $s.RepoA 'a.txt' 'A' 'A1'
        Add-TestCommit $s.RepoB 'b.txt' 'B' 'B1'
        Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config | Out-Null
        $rb = Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config
        (@($rb.Converge) | Where-Object { $_.Branch -eq 'main' }).Result | Should Be 'Birlestirildi'
        Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config | Out-Null

        (Get-RefOrNull $s.RepoA 'refs/heads/main') | Should Be (Get-RefOrNull $s.RepoB 'refs/heads/main')
        foreach ($repo in @($s.RepoA, $s.RepoB)) {
            (Test-Path (Join-Path $repo 'a.txt')) | Should Be $true
            (Test-Path (Join-Path $repo 'b.txt')) | Should Be $true
        }
    }

    It 'cakismada hicbir dala dokunmaz ve Cakisma raporlar' {
        $s = New-Sandbox
        Add-TestCommit $s.RepoA 'readme.txt' 'A surumu' 'A1'
        Add-TestCommit $s.RepoB 'readme.txt' 'B surumu' 'B1'
        Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config | Out-Null
        $bBefore = Get-RefOrNull $s.RepoB 'refs/heads/main'
        $rb = Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config
        $c = @($rb.Converge) | Where-Object { $_.Branch -eq 'main' }
        $c.Result | Should Be 'Cakisma'
        $c.Detail | Should Match 'readme\.txt'
        (Get-RefOrNull $s.RepoB 'refs/heads/main') | Should Be $bBefore
        ((Get-Content (Join-Path $s.RepoB 'readme.txt')) -join '') | Should Be 'B surumu'
    }

    It 'karsida acilan dal ve karsinin wip dali yerelde olusur; kendi wip dalimiz ezilmez' {
        $s = New-Sandbox
        New-TestGit $s.RepoB @('switch', '-q', '-c', 'ozellik') | Out-Null
        Add-TestCommit $s.RepoB 'o.txt' 'o' 'ozellik isi'
        Set-Content (Join-Path $s.RepoB 'taslak.txt') 'kaydedilmemis' -Encoding UTF8
        Set-Content (Join-Path $s.RepoA 'benim.txt') 'A kaydedilmemis' -Encoding UTF8
        Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config | Out-Null
        $myWip = Get-RefOrNull $s.RepoA 'refs/heads/wip/A'
        Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config | Out-Null
        Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config | Out-Null

        (Get-RefOrNull $s.RepoA 'refs/heads/ozellik') | Should Be (Get-RefOrNull $s.RepoB 'refs/heads/ozellik')
        $wipFiles = & git -C $s.RepoA ls-tree -r --name-only 'refs/heads/wip/B'
        ($wipFiles -contains 'taslak.txt') | Should Be $true
        # karsinin kaydedilmemis isi calisma agacina uygulanmaz
        (Test-Path (Join-Path $s.RepoA 'taslak.txt')) | Should Be $false
        (Get-RefOrNull $s.RepoA 'refs/heads/wip/A') | Should Be $myWip
        # B tarafinda da A'nin wip'i gorunur
        Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config | Out-Null
        (Get-RefOrNull $s.RepoB 'refs/heads/wip/A') | Should Be $myWip
    }

    It 'aktif dalda ezilecek yerel degisiklik varsa ilerletmez' {
        $s = New-Sandbox
        Add-TestCommit $s.RepoB 'readme.txt' 'B yeni' 'B1'
        Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config | Out-Null
        Add-Content (Join-Path $s.RepoA 'readme.txt') 'A yerel degisiklik'
        $before = Get-RefOrNull $s.RepoA 'refs/heads/main'
        $ra = Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config
        (@($ra.Converge) | Where-Object { $_.Branch -eq 'main' }).Result | Should Be 'AtlandiYerelDegisiklik'
        (Get-RefOrNull $s.RepoA 'refs/heads/main') | Should Be $before
        ((Get-Content (Join-Path $s.RepoA 'readme.txt')) -join "`n") | Should Match 'A yerel degisiklik'
    }

    It 'autoMerge kapaliysa ayrismis dali birlestirmez' {
        $s = New-Sandbox
        $s.Config | Add-Member -NotePropertyName autoMerge -NotePropertyValue $false -Force
        Add-TestCommit $s.RepoA 'a.txt' 'A' 'A1'
        Add-TestCommit $s.RepoB 'b.txt' 'B' 'B1'
        Invoke-EsitleSync -RepoPath $s.RepoA -RepoName 'proj' -Machine 'A' -Config $s.Config | Out-Null
        $rb = Invoke-EsitleSync -RepoPath $s.RepoB -RepoName 'proj' -Machine 'B' -Config $s.Config
        (@($rb.Converge) | Where-Object { $_.Branch -eq 'main' }).Result | Should Be 'AtlandiAyar'
    }
}
