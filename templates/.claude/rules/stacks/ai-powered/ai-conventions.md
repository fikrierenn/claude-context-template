# AI-Powered Proje — AI Konvansiyonları

paths: src/lib/ai/**, src/lib/llm/**, app/api/**

## 1. Model Seçim İlkesi

| Görev karmaşıklığı | Önerilen model tier |
|---|---|
| Basit analiz, JSON çıkarma | Ucuz / free tier (Gemini Flash, Haiku) |
| Kod üretimi, yapılandırılmış yanıt | Orta (GPT-4o-mini, Sonnet) |
| Görsel analiz, vision | Vision destekli model (GPT-4o, Gemini Flash) |
| Derin analiz, uzun bağlam | Güçlü (GPT-4o, Sonnet, Opus) |
| TTS | Proje gereksinimi: hız vs kalite |

> Proje `CLAUDE.md`'sine spesifik model→görev tablosu ekle.

## 2. Maliyet Takip Zorunluluğu

Her AI çağrısından sonra maliyet loglanır:

```typescript
import { calculateCost, formatCost } from '@/lib/utils/costTracking';

// input ve output token ayrı geçilir:
const cost = calculateCost(model, inputTokens, outputTokens);
logger.info('AI call completed', { model, cost: formatCost(cost.estimatedCost) });
```

> ❌ `calculateCost(model, total_tokens)` — YANLIŞ (input/output karışır)

## 3. AI Çıktısı Validasyonu

Her AI çıktısı parse edilmeden önce schema ile validate:

```typescript
import { z } from 'zod';

const OutputSchema = z.object({
  score: z.number().min(0).max(100),
  summary: z.string(),
});

const parsed = OutputSchema.safeParse(rawJson);
if (!parsed.success) {
  logger.warn('AI output validation failed', { errors: parsed.error.issues });
  // fallback döndür veya throw
}
```

## 4. Retry Stratejisi

```typescript
export async function withRetry<T>(fn: () => Promise<T>, maxRetries = 2): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: unknown) {
      const status = (error as { status?: number }).status;
      if (status === 429) await sleep(10_000); // rate limit: 10s bekle
      if (attempt === maxRetries) throw error;
      await sleep(3000 * attempt);
    }
  }
  throw new Error('Max retries exceeded');
}
```

## 5. Prompt Güvenliği

- Kullanıcı inputu prompt'a doğrudan eklenmez — sanitize et
- Uzun metin → max karakter ile kes (proje sınırını CLAUDE.md'ye yaz)
- JSON çıktı isteklerinde `response_format: { type: 'json_object' }` (OpenAI) veya `responseMimeType: 'application/json'` (Gemini) kullan
- AI çıktısını her zaman try/catch + Zod içinde parse et

## 6. SSL / Network Bypass

```typescript
// Sadece development'ta (kurumsal proxy vb.):
if (process.env.NODE_ENV === 'development') {
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
}
```

Production'da bypass kesinlikle kapalı — `NODE_ENV` kontrolü olmadan eklenmez.

## 7. Soyutlama Katmanı

Tüm AI çağrıları provider soyutlamasından geçer, doğrudan SDK çağrısı yapılmaz:

```
lib/llm/gemini.ts     → Gemini çağrıları
lib/llm/openai.ts     → OpenAI çağrıları
lib/llm/anthropic.ts  → Claude çağrıları
```

Modül içinde `new OpenAI()` veya `new GoogleGenerativeAI()` doğrudan oluşturulmaz.
