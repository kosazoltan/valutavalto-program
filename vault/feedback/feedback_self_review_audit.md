# B.9 — Önminősítés-ellenőrzés mandate

**Hatály:** always, P1
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.9 szakasz

## A probléma

A Claude Code önleírása (claude-code-mukodes-leiras-2026-05-16.md) 12. fejezete (Vakfoltok és gyengeségek) **saját bevallás**. Eddig nincs ellenőrzési mechanizmus, hogy a következő session valóban tanult-e belőle.

## A mandate

### 1. Session-zárási checklist (kötelező)

Minden session ZÁRÁSAKOR a Claude Code-nak kötelezően ki kell töltenie egy `vault/sessions/YYYY-MM-DD-name.md` jegyzetet, amely tartalmazza:

```markdown
## Vakfolt-checklist (claude-code-mukodes-leiras-2026-05-16.md 12. fejezet)

- [ ] 1. AI review polling automatikus (nem e-mail)
- [ ] 2. Titok-kezelés (semmi plaintext chat/MD/Bash)
- [ ] 3. PR-méret ≤ 300 LOC + 5 fájl (vagy dokumentált kivétel)
- [ ] 4. Nincs próba-szerencse iteráció (Context7 + brainstorming)
- [ ] 5. Csak vault + auto-memory használat (nincs régi rendszer)
- [ ] 6. CodeQL sanitizer-aware kód (ismert pattern)
- [ ] 7. TodoWrite használat komplex multi-step task-okhoz
- [ ] 8. Sourcery rate-limit NEM alibi a Copilot/Codex finding-eknek

## Mandate-checklist (vault/feedback/_active_mandates.md)

- [ ] C.1-C.20 (korábbi alap-mandate)
- [ ] B.1 Pmt. AML invariáns (új P0)
- [ ] B.2 Pénzügyi adatintegritás (új P0)
- [ ] B.3 Multi-tenant izoláció (új P0)
- [ ] B.4 Local-first outbox (új P0)
- [ ] B.5 Szabályozási határidő (új P0)
- [ ] B.6 Sztornó szabály (új P0)
- [ ] B.7 Code-signing release (új P0, 2026-05-21-ig)
- [ ] B.8 Prod-first vs TDD (új P1)
- [ ] B.9 Önminősítés (jelen mandate)
- [ ] D.1 AI ügynök push/CI doctrine (új P0)

## Eltérés-jelentés

Ha bármelyik `[x]` állítás NEM 100% → magyarázat + javítási terv a következő session-re.
```

### 2. Aktív mandate index (kötelező)

`vault/feedback/_active_mandates.md` index fájl fel kell sorolnia az AKTÍV mandate-ket (NE lehessen "felejteni"). Új mandate hozzáadása → index-update kötelező.

### 3. Heti meta-review (vasárnap, Drill 1 után)

Az AI ügynöknek átfogóan jelentenie kell a felhasználónak az aktív mandate-k betartási arányát az elmúlt 7 napon. Forrás: `vault/sessions/*.md` checklist-fájlok aggregátuma.

## Sikermérés

A `claude-code-korrekcios-mandate-2026-05-17.md` 5. szakaszának 3 kontrollkérdése:

1. Pmt. 100k HUF küszöb — hol enforced, melyik teszt fedi, mely PR-checklist pont
2. `cashCounter` mező PR-ben — mit teszek?
3. Legutóbb megszegett vakfolt — hivatkozás a session-jegyzetre

Ha a Claude Code helyesen válaszol → betöltés sikeres. Ha nem → újra a 4. szakasz sorrendje.

## Kapcsolódó hivatkozások

- `claude-code-mukodes-leiras-2026-05-16.md` (12. fejezet vakfoltok)
- `vault/feedback/_active_mandates.md` (index)
- `~/.claude/projects/.../memory/MEMORY.md` (auto-memory)
