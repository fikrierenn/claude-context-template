# Proje-Özel Skill / Agent / Hook — Kavram, Neden, Niçin

> **Bu doküman kime?** "Skill/agent/hook yazabileceğimi biliyorum ama *ne zaman* ve *neden* yazmalıyım?" diyen geliştirici.
> **Fark:** [`PROJE_OZEL_OLUSTURMA.md`](PROJE_OZEL_OLUSTURMA.md) = *nasıl* yazılır (reçete). Bu doküman = *neden* var, *hangi acıyı* çözer, *ne zaman* doğar (zihinsel model).

İçindekiler:
- [1. Çözülen Asıl Problem](#1-çözülen-asıl-problem)
- [2. Zihinsel Model: Dışsallaştırılmış Hafıza + Otomasyon](#2-zihinsel-model)
- [3. Üç Aracın Doğası — Hangi Boşluğu Doldurur](#3-üç-aracın-doğası)
- [4. Hook Kavramı — Derinlemesine](#4-hook-kavramı--derinlemesine)
- [5. Uçtan Uca Örnek: Bir Acıdan Skill/Agent/Hook Doğuşu](#5-uçtan-uca-örnek)
- [6. "Ne Zaman Doğar" Sinyalleri](#6-ne-zaman-doğar-sinyalleri)
- [7. Ne Zaman YAPMAMALI (Anti-pattern)](#7-ne-zaman-yapmamalı)
- [8. Yaşam Döngüsü: Doğ · Büyü · Emekli Ol](#8-yaşam-döngüsü)

---

## 1. Çözülen Asıl Problem

LLM ile çalışmanın dört kalıcı sızıntısı var. Hepsi aynı kökten: **bağlam kalıcı değil.**

| Sızıntı | Belirti | Maliyet |
|---|---|---|
| **Tekrar** | Aynı talimatı her oturumda yeniden yazıyorsun ("Dapper kullan, EF değil") | Token + zaman + dikkat |
| **Unutma** | Bir gün talimatı yazmayı atlıyorsun → kural ihlal edildi | Bug, yeniden iş |
| **Tutarsızlık** | İki dev (veya iki oturum) aynı işi farklı yapıyor | Teknik borç, review yükü |
| **Onboarding** | Yeni dev / yeni oturum domain'i sıfırdan öğreniyor | Yavaşlık, hata |

Bu dördü, "Claude akıllı değil mi, hatırlamıyor mu?" sorusunun cevabı: **hayır, hatırlamaz.** Her oturum sıfırdan başlar. Konuşma içinde söylediğin kural `/clear` veya compact ile buharlaşır.

**Skill/agent/hook = bu buharlaşmayı durduran kalıcı yapılar.** Bir kez yazarsın; dosyada yaşar; her oturum otomatik yüklenir veya doğru anda tetiklenir.

> Bunu "Claude'a not bırakmak" değil, **"kurumsal süreci kodlamak"** olarak düşün. Kod review checklist'ini insan hafızasına bırakmazsın — dökümante edersin. Aynı şey.

---

## 2. Zihinsel Model

İki eksen var: **kim tetikler** ve **kalıcı mı**.

```
                    OTOMATİK (olay tetikler)        ELLE (sen/Claude tetikler)
  KALICI DAVRANIŞ   ┌─────────────────────┐         ┌─────────────────────┐
  (her oturum)      │       HOOK          │         │       KURAL         │
                    │ olay → script çalışır│         │ pasif, hep yüklü    │
                    └─────────────────────┘         └─────────────────────┘
  TALEP ÜZERİNE     ┌─────────────────────┐         ┌─────────────────────┐
  (gerektiğinde)    │  AGENT (proaktif)   │         │  SKILL / KOMUT      │
                    │ Claude doğru anda    │         │ /<ad> veya doğal dil│
                    └─────────────────────┘         └─────────────────────┘
```

- **Hook** = refleks. Düşünmeden, olay olunca çalışır (oturum açıldı → özet enjekte et; commit edilecek → tara).
- **Kural** = içgüdü. Hep arka planda, davranışı şekillendirir ama bir "eylem" başlatmaz.
- **Agent** = uzman danışman. Çağrılır (veya Claude proaktif çağırır), izole kafa yapısında derin iş yapar, rapor döner.
- **Skill** = prosedür. Sen başlatırsın, çok adımlı reçeteyi yürütür.

**Doğru aracı seçmek = "bu davranış otomatik mi olmalı, kalıcı mı, kim başlatmalı?" sorusuna cevap.**

---

## 3. Üç Aracın Doğası

### Skill — "Bunu hep şöyle yaparız"
Bir **iş akışını standartlaştırır**. Domain bilgisi + adım sırası + kısıt tek dosyada.

- **Neden var:** Çok adımlı, domain-bilgili işler insan hafızasına/konuşmaya sığmaz. ("Migration yazarken: idempotent yap, yedek al, sonra şu sırada uygula.")
- **Niçin skill (kural değil):** Her zaman değil, *o işi yaparken* lazım. Sürekli context'te durması gereksiz şişme.
- **Örnek doğuş:** "Üçüncü kez migration'ı yanlış sırada çalıştırdık." → `migration-writer` skill.

### Agent — "Bu işi ayrı bir kafaya yaptır"
**İzole bağlamda derin/ağır iş** yapar, ana konuşmayı kirletmez.

- **Neden var:** (1) Ağır analiz ana context'i şişirir → izole et. (2) Bağımsız perspektif gerekir (denetçi). (3) Paralellik — 10 dosyayı 10 agent eşzamanlı.
- **Niçin agent (skill değil):** Kendi token bütçesi + kendi model katmanı (ucuz haiku / güçlü opus) + sonucu özetleyip döner.
- **Örnek doğuş:** "Her SP'den sonra transaction/ledger doğruluğunu elle kontrol ediyorum, yoruluyorum." → `sql-sp-reviewer` agent (opus, salt-okuma).

### Hook — "Bunu ben hatırlamak istemiyorum"
**Olay tetikli otomasyon.** İnsan ve LLM ikisinin de unutabileceği şeyi sisteme bağlar.

- **Neden var:** Disiplin insana/LLM'e bırakılınca er geç atlanır. Hook atlamaz.
- **Niçin hook (kural/skill değil):** Kural "yapmalısın" der ama zorlamaz. Hook **mekanik olarak çalışır** — commit'i bloklar, journal'a yazar, oturum başında özet basar.
- **Örnek doğuş:** "Gizli şifreyi iki kez commit'e kaçırdık." → `pre-commit-antipattern` hook (commit'i bloklar).

---

## 4. Hook Kavramı — Derinlemesine

Hook, diğer ikisinden farklı: **kod değil, Claude'un kararı değil — harness'in çalıştırdığı script.** Bu yüzden en güvenilir disiplin aracı.

### 4.1 Olay tipleri (en sık)

| Olay | Ne zaman fire eder | Tipik kullanım |
|---|---|---|
| `SessionStart` | Oturum açılınca | Durum özeti enjekte et (git/TODO/journal) |
| `PreToolUse` | Bir tool çalışmadan **önce** | `git commit` öncesi tara/blokla, tehlikeli komutu durdur |
| `PostToolUse` | Bir tool çalıştıktan **sonra** | Commit sonrası journal yaz, build sonrası bildir |
| `UserPromptSubmit` | Kullanıcı mesaj yollayınca | Bağlam enjekte et, mesajı zenginleştir |
| `Stop` | Claude yanıtı bitince | Lint çalıştır, bildirim gönder |

### 4.2 Hook'un anatomisi

İki parça: **(a)** script (`.claude/hooks/*.sh`), **(b)** kayıt (`.claude/settings.json`).

**Script** — stdin'den JSON olay alır, çıktı/exit code ile karar verir:

```bash
#!/usr/bin/env bash
# PreToolUse hook — tehlikeli git komutunu blokla
input=$(cat)                                   # harness JSON'u stdin'den verir
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Sadece git commit'e bak, digerini gecir
echo "$cmd" | grep -qE 'git[[:space:]]+commit' || exit 0

# Staged dosyada hardcoded sifre var mi?
if git diff --cached | grep -qE 'password\s*=\s*["'"'"'][^"'"'"']+'; then
  echo "BLOKLANDI: Hardcoded sifre staged. Once temizle." >&2
  exit 2                                        # exit 2 = tool'u durdur (PreToolUse)
fi
exit 0                                          # exit 0 = devam
```

**Kayıt** — `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash D:/Dev/proje/.claude/hooks/pre-commit-antipattern.sh" }
        ]
      }
    ]
  }
}
```

`matcher` = hangi tool'da fire eder (`Bash`, `Edit`, `Write`, regex). PreToolUse'da `exit 2` tool'u iptal eder, stderr Claude'a feedback olur.

### 4.3 Neden hook, "Claude dikkat etsin" demekten iyi?

Çünkü **Claude'a güvenmek = insana güvenmek**: çoğu zaman yapar, bazen atlar. Hook deterministik. Üç gerçek örnek:

| İhtiyaç | Kural/skill ile | Hook ile |
|---|---|---|
| Oturum başı durum | "Hatırla, journal oku" → bazen atlanır | `SessionStart` → her zaman enjekte |
| Sır sızıntısı | "Şifre commit'leme" → bir gün kaçar | `PreToolUse` → commit bloklanır |
| Commit kaydı | "Journal'a yaz" → unutulur | `PostToolUse` → otomatik append |

### 4.4 Proje-özel hook örnekleri (fikir)

- **`PostToolUse` (Edit/Write) → otomatik format:** Bir dosya yazıldıktan sonra `prettier`/`dotnet format`/`ruff` çalıştır. Stil tartışması biter.
- **`PreToolUse` (Bash) → migration koruması:** `DROP TABLE` / `DELETE FROM` içeren komut → yedek var mı kontrol et, yoksa blokla.
- **`Stop` → test hatırlatıcı:** Yanıt bitince değişen dosyalara karşılık test var mı bak, yoksa uyar.
- **`SessionStart` → ortam doğrulama:** `.env` eksik mi, DB ayakta mı, gerekli CLI kurulu mu — oturum başında söyle.
- **`PostToolUse` (Bash) → build kırıldıysa bildir:** `dotnet build`/`npm run build` exit≠0 ise net uyarı bas.

> **Kritik kural (deneyimden):** Hook çıktısı context'te görünse bile Claude onu "gördüm, atlıyorum" varsaymamalı — `session-protocol.md` bunu koşulsuz tekrar-çalıştır kuralıyla çözer. Hook'a güvenirken Claude'un "hook fire etti" varsayımına güvenme.

---

## 5. Uçtan Uca Örnek

**Senaryo:** Bir ekip, finansal işlem kayıtlarında tekrar tekrar aynı hatayı yapıyor: kaydı **silmek** (oysa kural: silme yok, ters kayıt at). Bu acıyı üç araçla nasıl ele alırız?

### Adım 1 — Acıyı teşhis et
> "İkinci kez bir `DELETE FROM transactions` review'da yakalandı."

İki kez = sinyal. Bir araç doğmalı. Ama hangisi?

### Adım 2 — Doğru aracı seç
Soru zinciri (§2 modeli):
- Otomatik mi olmalı? **Evet** — insan unutuyor. → Hook adayı.
- Kalıcı davranış mı? Kısmen — "silme yasak" felsefesi her zaman geçerli. → Kural adayı.
- Yazarken rehber lazım mı? Evet — "nasıl ters kayıt atılır" prosedürü. → Skill adayı.

**Cevap: üçü birden, katmanlı.** Tek araç yetmez; savunma derinliği.

### Adım 3 — Üç katmanı kur

**(a) Kural** — felsefeyi pasif yükle (`.claude/rules/document-immutability.md`):
```markdown
# Kayıt Değişmezliği
POSTED finansal kayıt SİLİNMEZ / GÜNCELLENMEZ.
Düzeltme = ters kayıt (reversal) + yeni doğru kayıt.
Neden: denetim izi + yasal saklama + mutabakat.
```

**(b) Skill** — doğru prosedürü ver (`.claude/skills/reversal-writer/SKILL.md`):
```markdown
---
name: reversal-writer
description: Finansal kayıt düzeltme/iptal akışı. "iptal et", "düzelt",
  "ters kayıt", "reversal" denildiğinde çağrılır. SİLME ÖNERMEZ.
allowed-tools: Read, Write, Edit, Grep
---
# Adımlar: 1) orijinali bul 2) ters kayıt (negatif) 3) yeni doğru kayıt
# 4) ledger net doğrula 5) audit log
```

**(c) Hook** — son savunma (`PreToolUse`, `delete-guard.sh`):
```bash
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')
if echo "$cmd" | grep -qiE 'DELETE FROM (transactions|ledger|movement)'; then
  echo "BLOKLANDI: Finansal kayit silme yasak. reversal-writer skill kullan." >&2
  exit 2
fi
exit 0
```

### Adım 4 — Sonuç
- Kural: Claude her zaman "silme yok" bilinciyle çalışır.
- Skill: "iptal et" dendiğinde doğru prosedürü uygular.
- Hook: yine de bir `DELETE` denenirse **mekanik olarak durur**.

Üç kez aynı hata → bir daha asla. Acı bir kez kodlandı, kalıcı çözüldü.

---

## 6. "Ne Zaman Doğar" Sinyalleri

Bir skill/agent/hook **şu sinyallerden biri** çıkınca doğmalı:

1. **Aynı talimatı 2. kez yazdın** → Kural veya skill.
2. **Aynı hata 2. kez çıktı** → Checklist skill + (geri-alınamazsa) hook.
3. **Aynı ağır analizi elle 2. kez yaptın** → Agent.
4. **"Keşke unutmasaydım" dedin** → Hook.
5. **Yeni dev'e aynı şeyi anlattın** → Kural/skill (onboarding hafızası).
6. **Domain kuralını LLM uydurdu/yanlış bildi** → Rehber skill (SALT-REHBER) + kaynak.
7. **Bir işi her seferinde `/x` gibi başlatmak istedin** → Komut.

> Kural: **İlk kez** olduğunda yapma (henüz pattern değil). **İkinci kez** olduğunda dur ve araç doğur. Üçüncü kez olmasın.

---

## 7. Ne Zaman YAPMAMALI

Aşırı-mühendislik gerçek risk. Şunlarda araç yaratma:

- **Tek seferlik iş.** Bir kez yapılacak şey için skill yazma — sadece yap.
- **Trivial tek mesaj.** "Bu fonksiyonu açıkla" için agent gerekmez.
- **Genel programlama bilgisi.** "SOLID nedir" skill'i yazma — LLM zaten bilir. Sadece *senin projene özgü* olanı kodla.
- **Spekülatif "ileride lazım olur."** `coding-discipline.md` ilkesi araçlara da geçerli — ihtiyaç kanıtlanmadan soyutlama yok.
- **Çakışan/örtüşen araçlar.** Yeni skill mevcut bir skill'in %70'iyse → mevcut olanı genişlet, yenisini yaratma.
- **Hook'la her şeyi zorlamak.** Her tool çağrısına ağır hook = yavaşlık + gürültü. Hook sadece *gerçekten* unutulması felaket olanlar için.

**Test:** "Bu araç olmadan ne kaybederim?" Cevap "biraz tekrar" ise belki gereksiz. "Sessiz veri bozulması / her oturum 5 dk / yeni dev 1 gün" ise → yaz.

---

## 8. Yaşam Döngüsü

Araçlar canlıdır — doğar, büyür, ölür:

1. **Doğ:** İkinci acıda, en küçük haliyle. Mükemmel olmasın, çalışsın.
2. **Büyü:** Her tetiklendiğinde gözlemle. Yanlış tetikleniyor → description daralt. Eksik madde → ekle. Aynı düzeltmeyi tekrar yaptın → skill'e işle.
3. **Birleş:** İki araç örtüşmeye başladı → tek araçta birleştir veya aralarında çapraz atıf kur.
4. **Emekli ol:** Domain değişti, araç geçersizleşti → **sil**. Stale skill aktif zarardır (yanlış yönlendirir). `session-memory.md`: geçersiz talimat fark edilince dosyadan silinir.

> Araç envanterini ara sıra gözden geçir: "Bu skill son 2 ayda tetiklendi mi? Hâlâ doğru mu?" Hayır → emekli et.

---

### İlişkili Dökümanlar
- [`PROJE_OZEL_ORNEK_SENARYO.md`](PROJE_OZEL_ORNEK_SENARYO.md) — somut ERP/fatura örneği + sana ne yazdırırım (kopyala-yapıştır prompt).
- [`PROJE_OZEL_OLUSTURMA.md`](PROJE_OZEL_OLUSTURMA.md) — *nasıl* yazılır (frontmatter, örnek katalog).
- [`GELISTIRICI_REHBERI.md`](GELISTIRICI_REHBERI.md) — mevcut skill/agent/komut/hook kataloğu.
- [`USAGE.md`](USAGE.md) — hook iç işleyişi, bootstrap.
- [`../templates/docs/CONTEXT_MANAGEMENT.md`](../templates/docs/CONTEXT_MANAGEMENT.md) — bağlam yönetimi anayasası.
