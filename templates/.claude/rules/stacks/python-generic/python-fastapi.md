---
paths:
  - "**/app/**/*.py"
  - "**/*_api.py"
---

# FastAPI Kuralları

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_FastAPI projelerinde `python-conventions.md` ile birlikte uygulanır._

## Yapı

- App kurulumu `create_app()` factory fonksiyonunda.
- Router'lar ince kalır: persistence + iş mantığı servis/CRUD katmanında.
- Request, update ve response şemaları **ayrı** Pydantic modeller — tek model üçünü birden taşımaz.
- DB session ve auth, dependency olarak (`Depends`) verilir.

## Async Disiplini

- I/O yapan endpoint → `async def` + async client (httpx, async SQLAlchemy).
- Async route içinde **yasak**: `requests`, sync SQLAlchemy session, bloklayan dosya/network çağrısı.
- Tek bloklayan çağrı tüm event loop'u durdurur — sync kütüphane şartsa `def` endpoint kullan (threadpool'da koşar).

## Dependency Injection

```python
@router.get("/users/{user_id}")
async def get_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ...
```

- Route handler içinde `SessionLocal()` veya uzun ömürlü client oluşturma — hep dependency'den al.

## Şemalar

- Response modelde **asla**: parola, parola hash'i, access/refresh token, iç auth state.
- Veri dönen her endpoint'te `response_model` belirt — fazla alan sızmaz.
- Pydantic'in ifade edebildiği kuralı elle doğrulama: `Field(min_length=..., ge=...)` vb. constraint kullan.

## Güvenlik

- CORS origin listesi ortam bazlı (env'den); wildcard origin + credentialed CORS birlikte **yasak**.
- JWT doğrulaması eksiksiz: expiry + issuer + audience + algorithm.
- Auth ve yazma-ağırlıklı endpoint'lere rate limit.
- Log redaksiyonu: credential, cookie, `Authorization` header, token loglanmaz.

## Test

- `Depends`'te kullanılan **aynı** dependency objesini override et (`app.dependency_overrides[get_db] = ...`).
- Test sonrası `app.dependency_overrides.clear()` — sızıntı diğer testleri kirletir.
- Async app → async test client (httpx `AsyncClient`).
