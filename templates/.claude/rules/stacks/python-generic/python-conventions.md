---
paths:
  - "**/*.py"
---

# Python Konvansiyonları

## Sürüm
Python 3.11+ hedef. `match`, `ExceptionGroup`, `tomllib` kullanılabilir.

## Typing
- Type hints her public function'da. `mypy --strict` hedef.
- `from __future__ import annotations` tüm dosyalarda.
- `typing.Protocol` duck typing, `ABC` concrete hierarchy.
- `list[int]` | `dict[str, X]` native generics (3.9+).

## Style (PEP 8)
- 88 karakter satır (Black default).
- `snake_case` function/variable, `PascalCase` class, `UPPER_SNAKE` const.
- Dunder (`__init__`, `__str__`) yalnız standart.
- Private → `_prefix`, really private → `__prefix` (name mangling).

## Async
- `asyncio.run(main())` entry.
- `async def` + `await`. Blocking sync çağrı ile karıştırma.
- `asyncio.gather()` paralel, `async for` iteration.

## Error Handling
- Çok geniş `except Exception:` minimum — spesifik tercih.
- Custom exception hierarchy (DomainError → SpecificError).
- `logging.exception()` traceback'i log'lar.
- Re-raise gerekliyse `raise` (plain).

## Context Manager
Kaynaklı iş: `with` blokları. DB connection, file, lock — hep `with`.
```python
async with session.begin():
    await session.execute(...)
```

## Data Class
```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class User:
    id: int
    name: str
```
`slots=True` hafıza, `frozen=True` immutability.

## Dependencies
- `pyproject.toml` + `uv` veya `poetry`.
- `requirements.txt` sadece deploy için.
- Dev deps ayrı grup.

## Test
- `pytest` — `test_*.py` / `*_test.py`.
- Fixture'lar `conftest.py`.
- Her bug fix → test önce.
- Coverage %80 hedefi (critical path).

## Linting
- `ruff` — hepsini kapsar (pyflakes, pycodestyle, isort, bugbear).
- `black` format.
- `mypy --strict`.
- Pre-commit hook'la entegre.

## Logging
```python
import logging
logger = logging.getLogger(__name__)
logger.info("User %s logged in", user.id)  # % formatting — lazy
```
f-string log message'da **kullanma** — her zaman evaluate edilir.

## Async Web (FastAPI / Starlette / aiohttp)
- Dependency injection FastAPI'da `Depends`.
- Pydantic v2 validation.
- `HTTPException` raise — middleware handle eder.

## Django Özel
- Models → `app/models.py`.
- Views → CBV tercih (FBV küçük case).
- Migrations: `makemigrations` + `migrate`.
- Signals dikkatli — koordinasyon karmaşası yaratır.
