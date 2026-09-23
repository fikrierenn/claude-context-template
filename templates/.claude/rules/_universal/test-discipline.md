# Test Disiplini — Testleri Kapatmadan "Bitti" Deme

_Kapsam: Yeni feature / bug fix / refactor kapatma kriteri. `paths:` yok — compact sonrası survive._

## Mutlak Kurallar

1. **Yeni feature / bug fix / refactor → test çalıştırılmadan kapatma.**
   - Etkilenen testler projenin test komutuyla (`npm test` / `pytest` / `dotnet test` / `go test`) **geçti** olmalı (failure veya skip yetmez).
   - "Test yok ama kod doğru görünüyor" yetmez — boşluk varsa **yeni test yaz**, sonra çalıştır.
   - **Build yeşil ≠ test yeşil.** Bunu karıştırma. Compile/lint geçmesi runtime doğruluğu kanıtlamaz.

2. **Yeni test eklendiğinde → en az 1 koşum yap.**
   - Test dosyasını yazmak yetmez; çalıştır + sonucu raporla.
   - Failure varsa **fix et veya scaffolding'i geri al** — yarım kalmış test commit'leme.

3. **Test yokken bug fix → en az regression test yaz.**
   - Fix öncesi: bug'ı reproduce eden failing test.
   - Fix sonrası: aynı test geçer.
   - Sonraki regression yakalanır.

4. **Refactor → mevcut test seti yeşil kalmalı.**
   - Refactor öncesi: `N/N geçti` not.
   - Refactor sonrası: aynı sayı (veya artmış) geçti.
   - Test sayısı azalırsa kasıtlı silme dışında **regression sinyali**.

## "Bitti" Tanımı (Definition of Done)

Bir iş ancak şu üçü sağlanınca kapanır:
1. Build/compile/lint yeşil.
2. İlgili testler çalıştırıldı ve **geçti**.
3. Kullanıcı-görünür değişiklikse smoke test yapıldı (gerçek senaryo).

## Anti-pattern

1. **"Build yeşil, tamam sayalım"** — test çalıştırılmadı, runtime kırık olabilir.
2. **Test yazıp çalıştırmadan commit etmek** — failure git history'ye girer.
3. **`skip` / `xit` / `[Ignore]` ile testi by-pass etmek** — sebep dokümante edilmeden devre dışı kabul edilmez.
4. **Failure'ı "ileride bakacağım" diye bırakmak** — stale-claim olur (`.claude/rules/todo-verification.md`).
5. **Sadece happy-path test** — edge case, hata yolu, boş/null girdi de test edilir.
6. **Snapshot / change-detector test** — mevcut veriyi sabitleyen test kapsam katmaz, ilk
   değişimde kırılır ve hata yakalamaz.

## Davranışsal Kontrat > Snapshot

Test **ilişki/invariant** doğrular, anlık veriyi değil. Mevcut sayıyı/listeyi sabitleyen
test bir "change-detector"dır: her veri değişiminde kırılır, hiçbir hatayı yakalamaz.

| ❌ Snapshot | ✅ İnvariant |
|---|---|
| `assert len(kayitlar) == 3` | `assert len(kayitlar) >= 1` |
| `assert net == 5_401_374` | `assert net == brut - indirim` (formül ilişkisi) |
| `assert "X" in liste` | `assert all(k.tutar >= 0 for k in liste)` |
| `assert satir == 37` | `assert satir > 0 and toplam == sum(s.tutar for s in satirlar)` |

## YAZILI KURAL ≠ UYGULANAN KURAL

> Terfi: 23.09.2026. Ekosistemde **on vakayla** ölçüldü; bu deponun kendi mimari kararı
> da (`docs/MIMARI-KARARI-2026-09-23.md` §6) aynı sınıfa giriyor. Merkezde durması gereken
> kural budur — çünkü *"kural yazılıydı ve okunmuştu, çiğneyeni gören yoktu"* her depoda
> aynı şekilde ödendi.

"Kırılabilirliği kanıtlanmamış test, test değildir" kuralının daha genel hâli. Bir kuralın
METİN olarak var olması, ONU ÇİĞNEYENİN YAKALANDIĞI anlamına gelmez. Aradaki boşluk
sessizdir ve kural "var" göründüğü için kimse arkasına bakmaz.

**SINAMA — tek soru:**

> *"Bu kuralı çiğneyen bir durumu bugün KİM, NEREDE görür?"*
> Cevap **"hiç kimse"** ise kural **yoktur**; yalnız bir niyet beyanı vardır.

("Yazılı mı?" sorusu yetmez — yazılı olan tam da yanıltan şeydir.)

**Ödenmiş vaka sınıfları (her biri ayrı depoda ölçüldü):**

| Yazılı kural | Kodda karşılığı | Sonuç |
|---|---|---|
| "değer sıfır olamaz" | CHECK constraint `>= 0` | sıfıra izin veriyordu |
| "koşamamak yeşil değildir" | araç exit **0** dönüyordu | CI "temiz" okurdu |
| "şu kayıt hariç tutulmalı" | silme dar pencereli JOIN'e bağlıydı | 127.155 satırın 1'i kaçtı |
| "atlandığı YAZILIR" | çıktı test raporunda görünmüyordu | şart kâğıt üstünde |
| "asıl koruma metin ayrışması" | ad değişince `LIKE` boş dönüyordu | YANLIŞ GÜVEN verdi |
| saklama süresi 90 gün | betikte **yorum** olarak duruyordu | sahada **sonsuz** |
| dosya boyutu sınırı | commit kapısı boyuta bakmıyordu | üç gün sessizce kaydı |

**Alt-kural — yarım taşıma.** Bir soyutlama taşınırken TÜM yolları taşınmalı. Yarım
yapılmış taşıma hiç yapılmamıştan **kötüdür**: kural "taşındı" görünür, geride kalan yol
sessizce eski davranışı sürdürür ve kimse oraya bakmaz.

**Alt-kural — kapı kendi kör noktasını miras alır.** Bir doğrulama, doğruladığı şeyle
**aynı kütüphaneyi/aynı veri yapısını** kullanıyorsa o kütüphanenin kör noktalarını devralır.
İki taraf aynı veriyi aynı şekilde kaybedince fark SIFIR görünür ve kapı yeşil verir.
En az bir denetim **ham girdiye** (metin/satır/bayt) bakmalı.

**Alt-kural — kısmi körlük tam görüşle aynı görünür.** Bir denetim birden çok kaynak
okuyorsa, *"hiç okuyamadım"* ile *"kaynaklardan birini okuyamadım"* **ayrı** raporlanmalı.
Aksi hâlde biri okunduğu için "okundu" bayrağı kalkar, "ölçemedim" uyarısı hiç çıkmaz.

**Alt-kural — kapı güvenileceği yerde kırılır.** Başkasının deposunda kırılan kapı, senin
deponda KURULU olduğunun kanıtı değildir.

## UYGULANAN ≠ YAZILI — aynı boşluğun ters yüzü

> Terfi: 23.09.2026. Yukarıdaki kural *"yazılı ama kimse zorlamıyor"* der. Bu, tersidir:
> **zorlanıyor ama kimse yazmamış.** Ve daha sinsidir, çünkü bugün her şey yeşildir.

Bir koruma çalışıyor olabilir ve *koruma olduğu hiçbir yerde yazmıyor* olabilir. O hâlde
onu **bir sonraki temizlik siler** — silen kişi bir şey kırdığını bilmez, çünkü ortada
kırılan bir kural yoktur, yalnızca "gereksiz görünen" bir satır vardır.

**SINAMA — tek soru:**

> *"Bu satır yarın silinse ne kırılır, ve silen kişi bunu silmeden önce görür mü?"*
> Cevap *"kırılır ama göremez"* ise, **sebebi satırın yanına yaz.**

**Ölçülmüş vaka sınıfları (üçü ayrı depolarda, aynı gün):**

| Fiilen koruyan şey | Neden kayıtsızdı | Silinseydi |
|---|---|---|
| Komut zincirinde `&&` (`;` değil) | alışkanlıkla seçilmişti, karar olarak değil | önceki adım başarısızken sonraki adım **cari dizinde** koşardı |
| Yapılandırmadaki bir ad yazımı | "öylesine" öyleydi | derleme sessizce kırılırdı |
| Bir muafiyet kaydı | dört gün "çalışıyor" göründü, çünkü hiç temiz derlenmedi | ilk temiz derlemede çıkardı |

📐 **Doğru sonuç, kayıtsız sebep.** Yeşil bir koşum, sebebinin anlaşıldığını kanıtlamaz —
yalnız bugün kırılmadığını kanıtlar. Tesadüfen doğru olan bir şey, bilerek doğru olan bir
şeyle aynı görünür; ayıran tek şey **yanına yazılmış gerekçedir.**

Bu, `footprint-ladder`'ın *"mevcudu araştırmadan kaldırma"* maddesinin kanıt tarafıdır:
kaldırmadan önce araştırmak ancak sebep **yazılıysa** işe yarar.

**Uygulama:** yeni bir kural yazarken aynı commit'te şu üçünden birini göster —
(a) kuralı çiğneyeni yakalayan bir denetim/test/constraint, (b) kırmızı verdiği **ölçülmüş**
bir koşum, (c) *"bunu bugün hiçbir şey yakalamıyor"* cümlesinin kuralın YANINA yazılması.
Üçü de yoksa kural yazılmasın — **yanlış güven, güvensizlikten pahalıdır.**

## İlişkili
- `.claude/rules/todo-verification.md` — "kapalı" iddiasını kanıtla.
- `.claude/rules/before-major-change.md` — refactor öncesi güvenlik.
- `.claude/rules/evidence-discipline.md` — iddia değil ölçüm.
