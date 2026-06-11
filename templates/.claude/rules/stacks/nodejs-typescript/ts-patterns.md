---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Pattern'leri

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_API yanıt zarfı, custom hook ve repository pattern — `ts-conventions.md`'yi tamamlar._

## API Yanıt Zarfı (tek tip)

Tüm endpoint'ler aynı zarfı döner; client tarafında tek tip parse:

```typescript
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  meta?: {
    total: number
    page: number
    limit: number
  }
}
```

- `meta` sayfalama içindir — liste endpoint'lerinde doldur.
- Hata durumunda `success: false` + `error`; exception detayı sızdırma (bkz. `_universal/error-handling.md`).

## Custom Hook Pattern (React)

Tekrarlanan state mantığı component'te kalmaz, `useXyz` hook'una çıkar:

```typescript
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay)
    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}
```

- Effect içinde kurulan her kaynak (timer, listener, subscription) cleanup'ta sökülür.

## Repository Pattern

Data access tek arayüz arkasında — servis katmanı ORM/DB detayını görmez:

```typescript
interface Repository<T> {
  findAll(filters?: Filters): Promise<T[]>
  findById(id: string): Promise<T | null>
  create(data: CreateDto): Promise<T>
  update(id: string, data: UpdateDto): Promise<T>
  delete(id: string): Promise<void>
}
```

- "Bulunamadı" → `null` döner, exception değil (bkz. `_universal/error-handling.md`).
