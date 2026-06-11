---
paths:
  - "**/*.py"
---

# Python Test Kuralları

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_pytest'e özgü ekler — koşum disiplini `_universal/test-discipline.md`, framework/fixture temelleri `python-conventions.md`._

## Coverage

```bash
pytest --cov=src --cov-report=term-missing
```

- `term-missing` açıkta kalan satırları gösterir — boşluğu kritik path'ten başlayarak kapat.
- Hedef %80 (kritik path) — bkz. `python-conventions.md`.

## Test Kategorileri — pytest.mark

```python
import pytest

@pytest.mark.unit
def test_calculate_total():
    ...

@pytest.mark.integration
def test_database_connection():
    ...
```

- Marker'ları `pyproject.toml`'da tanımla (`[tool.pytest.ini_options] markers`) ve `--strict-markers` aç — typo'lu marker sessizce geçmesin.
- Hızlı feedback döngüsü: lokalde önce `pytest -m unit`, CI'da tam set.
- Integration testler dış kaynak (DB, network) gerektirir — unit set'i onlarsız da yeşil kalmalı.
