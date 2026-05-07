# Valutaváltó Vault

> **Egyetlen aktív memóriarendszer a valutaváltó-program AI-ügynökök számára.** (2026-04-27 user-direktíva)

## Aktuális hely

**2026-05-07 óta az aktív vault a repo alatt él:**

`D:\repo\valutavalto-program\vault\`

A korábbi külső `D:\valutavalto-vault\` példány törölve lett. Új vagy módosított
memória kizárólag ebbe a repo-local vaultba kerülhet, hogy ne legyen kettős
olvasás/írás.

## Cél

Megszüntetni a "memória mizériát" — egy projekt = egy vault, és a vault a
projekttel együtt verziózható/review-olható helyen van. Az **OpenClaw projekt
KÜLÖN vault-ban** dolgozik (`D:\openclaw\.openclaw\workspace`), nincs átfedés.

A korábbi memóriarendszerek **deprecated**:
- ❌ `D:\repo\valutavalto-program\.memory\` (SQLite, 2026-04-08 — törölve 2026-04-27)
- ❌ `D:\repo\valutavalto-program\.remember\remember.md` (csak rövid handoff marad)
- ❌ `C:\Users\Kósa Zoltán\.claude\projects\D--repo-valutavalto-program\memory\` (csak indexként marad)

**EZ az aktív memóriarendszer (2026-04-27 óta).**

## Struktúra (2026-05-02 frissítve)

```
D:\repo\valutavalto-program\vault\
├── README.md                              # EZ a fájl
├── .obsidian/                             # Obsidian config (auto)
├── sessions/                              # episodic memory: YYYY-MM-DD-session-name.md
│   └── 2026-04-27-audit-NO-GO-iter3.md   # példa
├── feedback/                              # user-direktívák, kötelező szabályok (preferences)
│   ├── ai-review-mandate-zero-tolerance.md
│   ├── hallucinacio-megszuntetese.md
│   ├── electron-architecture.md
│   └── ...
├── procedures/                            # procedurális memória: trigger + steps + verify
│   ├── push-merge-cycle.md               # új 2026-05-02
│   └── research-first-fix.md             # új 2026-05-02
└── references/                            # semantic facts: külső dokumentumok, SOTA
    ├── 2026-memory-architecture-sota.md  # új 2026-05-02
    ├── vault-evolution-gap-analysis.md   # új 2026-05-02
    ├── ngm-szamadas-23-2014.md
    ├── company-data-ebc-zrt.md
    └── ...
```

### Memóriatípusok (2026 SOTA mapping)

| Mappa | Memóriatípus | Mit tárol |
|---|---|---|
| `sessions/` | **Episodic** | "Mi történt az adott napon" — kronologikus napló |
| `feedback/` | **Preferences** + szabályok | "Hogyan akarja a user a dolgokat" |
| `procedures/` | **Procedurális** | "Hogyan kell egy adott workflow-t végrehajtani" — strukturált trigger + steps + verify |
| `references/` | **Semantic** | Külső doksik, SOTA, projekt-tudás |

A `CLAUDE.md` a "Core memory" — mindig a context window-ban (Letta-analógia).

Részletes architektúrális összehasonlítás: [`references/2026-memory-architecture-sota.md`](references/2026-memory-architecture-sota.md) és [`references/vault-evolution-gap-analysis.md`](references/vault-evolution-gap-analysis.md).

## Használati protokoll (minden új session elején)

1. Olvasd be a vault README-t: `D:\repo\valutavalto-program\vault\README.md` (EZ a fájl)
2. Olvasd be a legfrissebb `sessions/*.md` fájlt (episodic context)
3. Skim-eld a `feedback/*.md` mappát (kötelező szabályok)
4. **Ha workflow-feladat érkezik**: nézd meg a `procedures/*.md`-ben a kapcsolódó eljárást
5. Csak utána fejlesztés.

## Mentési protokoll (minden session végén)

1. Új sessionjegyzet: `sessions/YYYY-MM-DD-rovid-leiras.md`
2. Új feedback (ha user-direktíva érkezett): `feedback/<topic>.md`
3. Új projekt-tudás (ha externális forrás): `references/<topic>.md`
4. **Új vagy módosult workflow**: `procedures/<workflow-name>.md` — strukturált formátum (lásd a meglévő példákat)
5. **NE** írj a globális `~/.claude/projects/.../memory/` mappába — az csak az index-et tartja.

## Tilos

- ❌ Bence, Eszter, Tamás (régi belső AI csapat-koncepció — deprecated 2026-04-27)
- ❌ OpenClaw / openclaw / openclaw-workspace (a másik projekt, nem ide való)
- ❌ Több párhuzamos memóriarendszer (`.memory/`, `.remember/` complex tartalommal, etc.)

## Backlinks

- Projekt: `D:\repo\valutavalto-program\`
- Projekt CLAUDE.md: `D:\repo\valutavalto-program\CLAUDE.md`
- Régi külső vault: `D:\valutavalto-vault\` — törölve, tilos újra használni
- Másik projekt vault (NEM ide kapcsolódik): `D:\openclaw\.openclaw\workspace`
