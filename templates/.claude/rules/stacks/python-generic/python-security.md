---
paths:
  - "**/*.py"
---

# Python Güvenlik Kuralları

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_Stack'e özgü ekler — genel ilkeler `_universal/security-principles.md`'de, burada tekrarlanmaz._

## Secret — Fail-Fast Okuma

```python
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.environ["OPENAI_API_KEY"]  # yoksa KeyError — sessiz None değil
```

- Zorunlu sır için `os.environ["X"]` (eksikse KeyError) > `os.getenv("X")` (sessiz `None` → hata ilk kullanımda, geç ve kafa karıştırıcı).
- `.env` dosyası `.gitignore`'da; `load_dotenv()` yalnız lokal geliştirme içindir.

## Statik Güvenlik Taraması — bandit

```bash
bandit -r src/
```

- CI pipeline'a ekle; bulgu HIGH ise merge engellenir.
- Tipik yakaladıkları: `eval`/`exec`, `subprocess(..., shell=True)`, hardcoded password, untrusted `pickle`, zayıf hash (md5).
- `# nosec` istisnası ancak gerekçe yorumu ile birlikte kullanılabilir.
