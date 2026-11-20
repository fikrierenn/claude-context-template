# esitle — Karar Günlüğü

## 20.11.2026 — Oturum adımı takılması: görev önceliği Normal (5)

**Bulgu:** 20.11 sabah koşusu 48 dk sürdü ve 12:00'de 1 saatlik sınırla öldürüldü (`LastTaskResult 267014`).
Ölçüm: makine 4 çekirdek, her örnekte %100 CPU; görev BelowNormal (7) öncelikte ana iş parçacığı sürekli
"Ready" bekliyordu, G/Ç neredeyse sıfır. Kilitlenme değil, CPU açlığı. Yapısal yavaşlık da ölçüldü:
gönderimde dosya başına ~130 ms SMB kontrolü (pusula 695 dosya = 97 sn), almada repo başına 30–50 sn
özyinelemeli hub taraması.

**Karar:** Görev önceliği 7 → 5 (Normal). Kullanıcı: "Evet, Normal yap".
- SANAL-FIKRI'de koordinatör görevi elle 5'e çekti (20.11).
- `kur.ps1` görev XML'ine `<Priority>5</Priority>` eklendi. BT-FIKRI ancak orada `kur.ps1` yeniden
  çalıştırılınca 5 olur.
- Defender ayarı değiştirilmedi.

**Kod tarafı (aynı gün):**
- Oturum adımına süre bütçesi: varsayılan 10 dk (`sessions.budgetMinutes`). Aşılınca WARN log, kalan
  repolar `OturumAtlandi`, aşılan repo `OturumSureAsimi`; `son-rapor.json` yine yazılır.
- İlk istek okuma sınırlı: 64 KB üstü satır atlanır, toplam 1 MB / 400 satırda durulur.
- Gönderim: yerel `gonderilen.json` kaydı (boyut + zaman); değişmeyen dosya hub'a sorulmaz.
- Alma: karşı makinenin hub'a yazdığı `liste.json` okunur; liste yoksa ya da `-SessionId`/`-All`
  verilmişse eski özyinelemeli tarama.
- Sınır: tek bir takılan SMB çağrısı bütçeyle kesilemez; son emniyet yine görevin 1 saatlik sınırı.
