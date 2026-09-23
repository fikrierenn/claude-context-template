# Hata Yönetimi (Beklenen Sonuç vs Gerçek Exception)

_Her stack'te geçerli ilke. `paths:` yok — compact sonrası survive._

## Temel Ayrım

**Beklenen sonuç (business outcome)** ≠ **gerçek exception (system failure)**.

| Durum | Tip | Mekanizma |
|---|---|---|
| "Kayıt bulunamadı", "yetki yok", "stok yetersiz", "geçersiz girdi" | Beklenen | **Result/Either pattern** veya tipli dönüş (`Result<T>`, `{ ok, error }`, `Option`) |
| DB connection loss, network timeout, JSON parse fail, file I/O fail | Gerçek exception | `try/catch` + log + generic kullanıcı mesajı |
| Bug / impossible state (null check fail, off-by-one) | Programming error | Fırlat, üst handler yakalasın |

**Anti-pattern:** Beklenen iş sonucu için exception fırlatmak (`throw new Error("bulunamadı")`) → exception ile akış kontrolü pahalı + okunabilirlik düşürür + gerçek hatayı maskeler.

## İlkeler

1. **Beklenen başarısızlık tipli dönsün.** Çağıran, hata olasılığını imzadan görsün — try/catch'e gömülü sürpriz olmasın.

2. **Gerçek exception loglanır + maskeli kullanıcı mesajı.**
   - Kullanıcıya: "Beklenmedik bir hata oluştu." (generic, Türkçe).
   - Logger'a: tam stack trace + context (sensitive maskeli).
   - Stack trace / exception message **asla** kullanıcıya/response'a sızmaz (bkz. `security-principles.md`).

3. **Boş catch yasak.** `catch {}` / `except: pass` → en azından logla. Yutulan hata = takip edilemeyen bug.

4. **Fallback sessiz olmasın.** Fallback'e düşüldüyse logla ("primary X failed, falling back to Y"). Sessiz fallback yanlış veriyi doğruymuş gibi gösterir.

5. **Hata sınıflandırması tutarlı.** Projede hata kodu/aralığı veya tip hiyerarşisi varsa ona uy.

## Reddet mi, Say mı? — Doğrulama Sınırının Ölçütü

> Terfi: 23.09.2026. Bu ölçüt iki depoda bağımsız olgunlaştı (`dogrulama-siniri.md`
> 4 depoda ayrı kural, ayrıca bir depoda bu dosyanın içine yazılmış) — merkeze alındı.

Bir doğrulayıcı ne zaman **koşuyu durdurur**, ne zaman **raporlayıp devam eder**?

**REDDET** — durum **ÇELİŞKİLİYSE**. İki doğru bilgi aynı anda tutamıyorsa.
**SAY** — durum **EKSİKSE**. Bilgi doğru ama tam değil.

Tek soru: *"bu iki şey aynı anda doğru olabilir mi?"* Olamazsa reddet.

**Neden:** çelişki bir VERİ durumu değil, bir **KOD hatasıdır**. Çalıştırmaya devam etmek
onu gizler — gizlenen kod hatası tam olarak "sessiz yanlış sonuç" sınıfıdır. Eksiklik ise
meşru olabilir: kayıt son kapanan döneme kadar gelir, ötesi henüz yoktur; reddetmek doğru
veriyi de atar.

| Durum | Tanı | Karar |
|---|---|---|
| `net != brüt − indirim` | ikisi aynı anda doğru olamaz | **REDDET** |
| Toplam ≠ parçaların toplamı | aritmetik çelişki | **REDDET** |
| Türetilmiş sayı, kaynağın üstünde | tanım gereği imkânsız | **REDDET** |
| Son dönemin verisi henüz işlenmemiş | henüz gelmemiş olabilir | **SAY** (`tam_mi: false` + uyarı) |
| Beklenen eşi olmayan kayıt | boş olabilir | **SAY** ("teyit bekliyor") |
| Gelecek döneme ait veri yok | gelecek | **SAY** (etiketli tahmin) |

**Sınırın bittiği yer: eksiklik çelişkiye döndüğü an.** O an sayma — reddet ya da tamamla.

## Hata Sınıflandırıcı — tip koda gömülmez

"Gerçek exception" tipini çağrı yerine gömme; **merkezi bir sınıflandırıcıdan** sor
(transient → retry+backoff, fatal → fail). Dağınık inline string-match yasak.

- Retry yalnızca **transient** + **bounded** (en çok 2) + **her deneme loglanır**.
- Bilinmeyen = transient sayılabilir ama yine bounded (sonsuz döngü yok).
- Sınıflandırıcı tek dosyada yaşar; her dil tarafı kendi karşılığını tutar
  (ör. `SqlErrorClassifier` / `_errors.py`), kural aynıdır.

## Anti-pattern

1. `throw` ile business validation (beklenen sonucu exception yapma).
2. `catch (e) { /* ignore */ }` — sessiz yutma.
3. `catch (e) { return null }` — neden null döndüğü kaybolur, çağıran ayırt edemez.
4. Exception message'ı kullanıcıya basmak — bilgi sızıntısı.
5. Try/catch'i fonksiyonun tamamına sarıp her şeyi tek "hata oldu"ya indirgemek.

## İlişkili
- `.claude/rules/security-principles.md` — exception sızıntısı, log maskeleme.
- `silent-failure-hunter` agent — sessiz hata avı.
