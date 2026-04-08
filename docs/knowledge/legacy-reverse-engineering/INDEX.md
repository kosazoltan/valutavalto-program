---
type: registry
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Legacy Reverse Engineering — Index & Kereso"
load: on-demand
---

# Legacy Reverse Engineering — Index & Kereső

> **Keletkezés:** 2026-04-02 (eredeti elemzés), 2026-04-05 (vault archiválás + gap audit)
> **Forrás:** `D:\repo\valutavalto-program\Anti\VALUTA\` — Delphi 7 legacy rendszer
> **Cél:** A modern Java+React+Electron rendszer migrációjának teljes referenciája


---

## S1 FAJLOK

| Fájl | Szerző | Fókusz | Méret |
|------|--------|--------|-------|
| `RE-junior-teljes-rendszer-architektura.md` | Junior | Teljes rendszertérkép: 110+ DLL, üzleti logika, DB séma, bizonylatok | ~50 KB |
| `RE-egyestitett-osszes-csapat-elemzes.md` | Csapat (5 fős) | Egyesített elemzés, 17 fejezet, minden szempont | ~180 KB |
| `RE-tamas-technikai-architektura.md` | Tamás | Technikai architektúra, kommunikáció, tesztelhetőség, migrációs térkép | ~50 KB |
| `RE-eszter-uzleti-logika-minoseg.md` | Eszter | Üzleti szabályok, AML/KYC, kódminőség, jogszabályi audit | ~50 KB |
| `RE-gabor-uiux-design-wireframes.md` | Gábor | UI/UX design, DFM elemzés, wireframe-ek, design token rendszer | ~40 KB |
| `RE-gap-analysis-legacy-vs-modern.md` | Junior | Hiányelemzés: legacy vs modern implementáció | ezt a fájlt |


---

## S2 KERESESI_KULCSSZAVAK

### Üzleti területek
- **Devizaváltás**: Junior → 4.1-4.2, Eszter → 1.1-1.4, Merged → §4
- **Sztornó**: Junior → 4.3, Eszter → 1.5, Merged → §4
- **Napzárás**: Junior → 4.4, Tamás → §1, Merged → §8
- **Havi zárás**: Junior → 4.5, Merged → §8
- **Év-nyitó**: Junior → nemmentionált (külön implementálva Sprint 5 C4)
- **Foglalás**: Junior → 4.6, Gábor → 4.10, Merged → §4
- **Címletkezelés**: Junior → 3.3, Gábor → 4.11, Merged → §8
- **Bizonylatok/nyomtatás**: Junior → 5.1-5.5, Eszter → §3, Gábor → 4.12, Merged → §7
- **Ügyfél/AML/KYC**: Junior → 6.1-6.3, Eszter → §2, Merged → §5
- **Western Union**: Junior → 3.8, Merged → §11
- **Körlevél**: Junior → 3.10, (archiválás: év-nyitó)
- **Árfolyam**: Eszter → 1.1, Merged → §4

### Technikai területek
- **DLL architektúra**: Junior → 1.2, 3.x, Tamás → 1.x, Merged → §3
- **Adatbázis séma**: Junior → 7.x, Tamás → 2.x, Merged → §6
- **Nyomtatás/ESC-POS**: Junior → 10.1, Gábor → 11.2, Merged → §7
- **Biztonság**: Junior → 9.x, Tamás → 6.x, Merged → §9
- **FTP/szerver**: Junior → 8.x, Tamás → 3.x, Merged → §11
- **Konfiguráció**: Junior → 11.x, Merged → §12
- **Tesztelhetőség**: Tamás → 8.x, Merged → §13


---

## S3 HASZNALAT
```
memory_search("legacy devizaváltás árfolyam")
→ vault/03_creating/legacy-reverse-engineering/INDEX.md → megfelelő fájl + szekció
```
