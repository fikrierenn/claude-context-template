---
paths:
  - "**/*.py"
---

# Python Pattern'leri

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_Sınır (boundary) tipleri ve hafıza-verimli iterasyon — `python-conventions.md`'yi tamamlar._

## Protocol ile Arayüz (structural typing)

```python
from typing import Protocol

class Repository(Protocol):
    def find_by_id(self, id: str) -> dict | None: ...
    def save(self, entity: dict) -> dict: ...
```

- Concrete sınıf Protocol'ü import etmek/miras almak zorunda değil — imza uyumu yeter.
- Test double yazmak kolaylaşır: arayüze uyan herhangi bir sınıf geçer.
- Servis katmanı Protocol'e bağımlı olur, somut implementasyona değil.

## Dataclass DTO (sınır tipleri)

API/servis sınırında ham `dict` taşıma — dataclass DTO kullan (alan adı typo'su mypy'de yakalanır):

```python
from dataclasses import dataclass

@dataclass
class CreateUserRequest:
    name: str
    email: str
    age: int | None = None
```

- Stil detayları (`frozen=True`, `slots=True`) → `python-conventions.md`.
- Web framework varsa Pydantic modeli sınır tipi olarak öncelikli (`python-fastapi.md`).

## Generator — Lazy İterasyon

- Büyük veri setini listeye yükleme; generator (`yield`) ile akıt — bellek sabit kalır.
- Dosya ve DB cursor zaten lazy — `list(...)` ile sarmadan doğrudan iterate et.
- Tek geçişlik dönüşüm zincirlerinde generator expression: `sum(x.amount for x in rows)`.
