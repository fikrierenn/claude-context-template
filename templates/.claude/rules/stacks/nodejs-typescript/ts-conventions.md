---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Konvansiyonları

## tsconfig
- `"strict": true` zorunlu.
- `"noUncheckedIndexedAccess": true` — array/obj erişimi undefined kontrol ettirir.
- `"exactOptionalPropertyTypes": true` — tercih.
- `"target": "ES2022"` veya üstü.

## Typing
- `any` **yasak** — `unknown` + type guard tercih.
- Public API'da explicit return type.
- `interface` > `type` — extensible.
- Utility type'lar (`Partial`, `Pick`, `Omit`, `Record`) aktif kullan.

## Async
- `async/await` — raw Promise chain minimum.
- Error handling: `try/catch` + typed error.
- `Promise.all` paralel, `for...of` sequential.

## Import Düzeni
```ts
// 1. Node built-in
import * as fs from 'node:fs';

// 2. External
import express from 'express';

// 3. Internal (alias / relative)
import { foo } from '@/utils/foo';

// 4. Types
import type { User } from '@/types';
```

## Error Handling
```ts
class DomainError extends Error {
  constructor(public code: string, message: string) { super(message); }
}

try {
  await doWork();
} catch (err) {
  if (err instanceof DomainError) { /* ... */ }
  else { logger.error({ err }); throw err; }
}
```

## Null / Undefined
- `| null` veya `| undefined` explicit. `?:` for optional.
- `??` yerine `||` kullanma (boolean false'ı da yakalar).
- Optional chaining `?.` güvenli.

## Naming
- PascalCase: class, interface, type, enum.
- camelCase: variable, function, method.
- UPPER_SNAKE: const (global config).
- `I` prefix **kullanma** TS'de interface'e (tartışmalı, modern TS karşı).

## Test
- Vitest / Jest — `*.test.ts` veya `*.spec.ts`.
- Her PR: test ekle veya güncellenmiş testi doğrula.

## Linting
- ESLint + typescript-eslint preset-strict.
- Prettier formatting.
- Husky pre-commit hook.
