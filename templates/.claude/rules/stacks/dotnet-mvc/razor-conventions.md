---
paths:
  - "**/*.cshtml"
---

# Razor View Konvansiyonları

## Yapı
1. `@model ViewModels.XyzViewModel` — Entity direkt kullanma.
2. `Layout = "_AppLayout";` unutma.
3. `ViewData`/`ViewBag` minimum — ViewModel property tercih.

## Form
- **Tek pattern:** `Html.BeginForm(...)` veya tag helper `<form asp-action="X">`. Karışık yazma.
- `@Html.AntiForgeryToken()` her form'da. Tag helper otomatik.
- `<div asp-validation-for="Field">` veya `@Html.ValidationMessageFor(...)`.

## Güvenlik
- **`@Html.Raw` minimum.** Kullanman şart ise comment bırak.
- Kritik alanlar ViewModel'de `[BindNever]` (Id, PasswordHash, vs.).
- ReturnUrl: `Url.IsLocalUrl(returnUrl) && returnUrl.StartsWith("/") && !returnUrl.StartsWith("//")`.

## Inline JS
- **Minimum.** Kısa `onclick` OK ama büyük logic `wwwroot/assets/js/`'e.
- CSP uyumluluğu için yavaş yavaş dışarı çek.

## Partial View
Tekrar eden UI → `Views/Shared/_Xyz.cshtml`. `@await Html.PartialAsync("_Xyz", model)`.

## Mesaj / Hata Gösterimi
```cshtml
@if (!string.IsNullOrWhiteSpace(Model.Message)) {
    <div class="@(Model.MessageType == "success"
        ? "bg-green-100 border-green-400 text-green-700"
        : "bg-red-100 border-red-400 text-red-700") px-4 py-3 rounded border">
        @Model.Message
    </div>
}
```

## Iframe (rapor/dashboard embed)
- `<iframe sandbox="allow-scripts" srcdoc="...">`.
- `allow-same-origin` **ekleme** — XSS izolasyonu bozulur.
