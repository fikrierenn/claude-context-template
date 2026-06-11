---
name: ui-ux-pro-max
description: "UI/UX design intelligence for web and mobile. Includes 50+ styles, 161 color palettes, 57 font pairings, 161 product types, 99 UX guidelines, and 25 chart types across 10 stacks (React, Next.js, Vue, Svelte, SwiftUI, React Native, Flutter, Tailwind, shadcn/ui, and HTML/CSS). Actions: plan, build, create, design, implement, review, fix, improve, optimize, enhance, refactor, and check UI/UX code."
---

# UI/UX Pro Max — Design Intelligence

Comprehensive design guide for web and mobile. Searchable database with priority-based recommendations.

## When to Use

**Must use:**
- Designing new pages (Landing, Dashboard, Admin, SaaS, Mobile)
- Creating/refactoring UI components (buttons, modals, forms, tables, charts)
- Choosing color schemes, typography, spacing, layout systems
- Reviewing UI code for UX quality, accessibility, visual consistency
- Implementing navigation, animations, responsive behavior

**Skip:**
- Pure backend / API / DB work
- Infrastructure / DevOps
- Non-visual scripts

## Rule Priority (1 = highest)

1. Accessibility & Usability
2. Layout & Hierarchy
3. Typography
4. Color & Contrast
5. Spacing & Alignment
6. Component Patterns
7. Interaction States
8. Animation & Motion
9. Responsive Design
10. Dark Mode / Theming

## Stack Support

React · Next.js · Vue · Nuxt · Svelte · SwiftUI · React Native · Flutter · Tailwind · shadcn/ui · HTML/CSS · Angular · Laravel · Astro

## Data Files

`data/` klasöründe CSV formatında:
- `colors.csv` — 161 renk paleti
- `typography.csv` — 57 font pairing
- `styles.csv` — 50+ tasarım stili
- `ux-guidelines.csv` — 99 UX kuralı
- `charts.csv` — 25 grafik tipi
- `stacks/` — stack-özel pattern'ler

> **Not:** Data dosyaları büyük (~100KB+). Tam veri için kaynak repodan kopyala: `skills/ui-ux-pro-max/data/`

## Usage Pattern

```
/ui-ux-pro-max [action] [target] [style?] [stack?]
```

Örnekler:
- `/ui-ux-pro-max design dashboard dark-mode nextjs`
- `/ui-ux-pro-max review navbar accessibility tailwind`
- `/ui-ux-pro-max improve table minimalism react`
