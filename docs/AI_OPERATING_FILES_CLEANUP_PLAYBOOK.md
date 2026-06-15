# AI Operating-Files Cleanup Playbook

> **Mi ez:** önálló, repo-agnosztikus utasítássor egy AI coding agentnek, hogy a saját
> repójában ugyanígy kitisztítsa az agent-vezérlő fájlok (mandate / memória / instruction MD-k)
> **duplikátumait, ellentmondásait, túlszabályozását, kódolási hibáit**, és hatékonyabbá tegye a
> programozást — **token-takarékosan, biztonságosan, de maximális alapossággal**.
>
> **Vezérelv (effort-allokáció):** a szabadság a *felfedezésben* van (tág, asszociatív hibakeresés),
> a fegyelem a *pazarlás és a hurok ellen*. Költs maximumot ott, ahol korrektséget/biztonságot vesz;
> takarékoskodj a rutinon és az ismétlésen. Egymondatos teszt minden lépésnél:
> *„ez korrektséget/biztonságot vesz, vagy csak ismétlés?"* — vesz → max effort; ismétlés → vágd.
>
> Verzió: 1.0 · A playbook maga is betartja, amit hirdet: lean, ismétlésmentes, kockázat-arányos.

---

## 0. Előfeltételek és biztonsági háló

1. **Tiszta git-állapot.** Kezdés előtt `git status` legyen tiszta (vagy commitold/stash-eld a meglévőt).
   Minden változás visszafordítható lesz (git history), de tiszta kiindulás kell.
2. **Dolgozz branchen**, ne a default ágon: `git checkout -b chore/operating-files-cleanup`.
3. **Semmit nem törlünk verifikáció és az egyedi tartalom átmentése nélkül** (lásd 4.C és a Fegyelmi korlátok).
4. **A strukturális törlés/merge a felhasználó jóváhagyásához kötött** — a mechanikus javítások (kódolás,
   dangling ref, ellentmondás, elavult szám) jóváhagyás nélkül mehetnek.

---

## 1. Hatókör meghatározása — melyek az „operating" fájlok?

Csak azokat auditáld, amelyek **az agent működését vezérlik** (NEM minden .md a repóban — a riportok,
setup-doksik, changelogok kimaradnak). Tipikus halmaz:

- **Egyetlen igazságforrás (SSOT):** `AGENTS.md` (vagy a repo ekvivalense).
- **Platform-fájlok:** `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.github/copilot-instructions.md`,
  `.cursor/rules/*`, IDE-instruction fájlok.
- **Szerződés/alkotmány:** `AI_CONTRACT.md`, `AI_CONSTITUTION.md` (hard tiltások, plafonok).
- **Mandate-könyvtár:** pl. `vault/feedback/*.md` + annak indexe (`_active_mandates.md`).
- **Memória-rendszer:** a perzisztens memória mappa + `MEMORY.md` index.

> Állítsd össze a pontos fájllistát a saját repód konvenciói szerint, mielőtt szkennelsz.

---

## 2. FÁZIS — Determinisztikus szkennek (gyors, magas jelszint, magad futtatod)

Ezeket **te magad** futtasd (nem subagent) — mechanikusak és biztosak. Cseréld a `FILES` listát a saját hatókörödre.

### 2.1 Mojibake / UTF-kódolási hiba

```python
# scan-mojibake.py — futtasd a repo gyökeréből
import glob, os
FILES = ['AGENTS.md','CLAUDE.md','CODEX.md','GEMINI.md','AI_CONTRACT.md','AI_CONSTITUTION.md',
         '.github/copilot-instructions.md'] \
        + glob.glob('.cursor/rules/*') + glob.glob('vault/feedback/*.md')   # IGAZÍTSD a repódhoz
FILES = [f for f in FILES if os.path.isfile(f)]
# UTF-8, ha latin1/cp1252-ként dekódolták majd újrakódolták -> jellegzetes bigramok + replacement char
MOJI = ['�','Ã¡','Ã©','Ã­','Ã³','Ã¶','Ã¼','Ã±','â€™','â€œ','â€“','â€”','Â ','Å‘','Å±','Å°']
hits = [(f,m) for f in FILES for m in MOJI if m in open(f,encoding='utf-8',errors='replace').read()]
print(f"Scanned {len(FILES)} files. " + ("CLEAN — 0 encoding issues." if not hits else f"ISSUES: {hits}"))
```

### 2.2 Dangling hivatkozások (nemlétező fájlra mutató belső linkek)

```bash
# Gyűjtsd ki a hivatkozott .md fájlneveket, és nézd meg, léteznek-e.
# Listázd az operating fájlokban szereplő [..](valami.md) és `valami.md` hivatkozásokat,
# majd minden hivatkozott névre: létezik-e a repóban? Ami nincs -> dangling.
grep -rhoE '[A-Za-z0-9_./-]+\.md' AGENTS.md CLAUDE.md vault/feedback/ .cursor/ 2>/dev/null \
  | sort -u | while read ref; do
      base=$(basename "$ref")
      [ -z "$(find . -name "$base" 2>/dev/null | head -1)" ] && echo "DANGLING: $ref"
    done
```

### 2.3 Index-drift (a memória/mandate index és a tényleges fájlok eltérése)

```bash
# Index-bejegyzések vs valós fájlok (igazítsd az index és a mappa útját)
grep -oE '\]\([a-z0-9._-]+\.md\)' MEMORY.md | tr -d ']()' | sort > /tmp/idx.txt
ls -1 <memoria-mappa> | grep -v '^MEMORY.md$' | sort > /tmp/files.txt
echo "Indexben van, fájl NINCS:"; comm -23 /tmp/idx.txt /tmp/files.txt
echo "Fájl van, indexben NINCS:"; comm -13 /tmp/idx.txt /tmp/files.txt
```

### 2.4 Konkrét számok / hard értékek ellentmondása

Keress **két különböző hard értéket ugyanarra** (pl. PR-méret plafon, timeout, retry-limit) a fájlok közt:
`grep -rniE 'max .* (loc|sor|fájl)|PR.*[0-9]{3}|retry|timeout' <operating-fájlok>` → kézzel vesd össze.

---

## 3. FÁZIS — Szemantikus audit (fan-out subagensekkel, token-hatékony)

A duplikációt, ellentmondást, túlszabályozást **párhuzamos subagensekkel** térképezd fel — a *findingok*
jönnek vissza, nem a fájl-dömpingek. Klaszterezd a fájlokat (platform / mandate / memória), és minden
subagentnek add ezt a vázat (igazítsd):

```
Auditáld AS A SET ezeket az agent-operating fájlokat: <lista>.
A <SSOT-fájl> a deklarált egyetlen igazságforrás; a többi csak kiegészítheti, nem írhatja felül.
Találj CSAK valós, bizonyítható (fájl:sor) problémát ezekben a kategóriákban:
1. DUPLIKÁCIÓ — ugyanaz a szabály több fájlban (token-pazarlás). Add meg a klasztert.
2. ELLENTMONDÁS — egy fájl szembemegy az SSOT-tal vagy egy másik fájllal (két hard érték, ellentétes utasítás).
3. TÚLSZABÁLYOZÁS — always-on / „minden taskra teljes gate / 2 kör / minden session-ben újraolvasás",
   amit az SSOT vagy az index már kockázat-arányosra váltott (a repo elmozdult az always-on szabályoktól).
4. KÉTÉRTELMŰSÉG — kétféleképpen, ellentétesen is érthető utasítás.
5. ELAVULTSÁG — törölt fájlra/elavult modellre/superseded mandate-re hivatkozás.
Add: SÚLY (P1/P2/P3) · KATEGÓRIA · FÁJL:SOR · 1 mondat leírás · 1 mondat javasolt javítás.
Csoportosítsd a duplikátumokat klaszterekbe. NE dump-olj fájltartalmat, NE írj át semmit.
```

> Külön subagent a **mandate-könyvtárra** (kérd az indexszel való összevetést: melyik mandate
> superseded/duplikált), és külön a **memóriára** (duplikátum, elavult tény, index-drift).

---

## 4. FÁZIS — VERIFIKÁCIÓ, majd JAVÍTÁS (ebben a sorrendben)

### 4.0 Verifikáció (KÖTELEZŐ — a legfontosabb fegyelmi lépés)

**Ne cselekedj ellenőrizetlen subagent-finding alapján.** A subagent is tévedhet (hallucinált finding).
Minden teher-bíró findingot igazolj vissza determinisztikusan:
- Tényleg hiányzik a hivatkozott fájl? (`find`/`ls`) Tényleg ott a két ütköző érték? (`grep -n`)
- Ami „elavultnak" tűnik, valóban az? (pl. egy modellnév lehet, hogy **valós és aktív** — ne töröld vakon.)
- Kritikus/nagy hatású findingnél **refuter-kör**: előbb próbáld megcáfolni, csak megerősítés után cselekedj.

### 4.A Mechanikus javítások (jóváhagyás nélkül)
- Mojibake/kódolás javítása.
- Dangling hivatkozások: élő célra repointolás, vagy a halott link törlése.
- Ellentmondó hard értékek: egyetlen forrásra (SSOT) igazítás.
- Elavult számok/hivatkozások frissítése.

### 4.B Túlszabályozás → kockázat-arányos (jóváhagyással, ha policy-t érint)
Az „minden változásra / minden taskra" always-on szabályokat **szűkítsd kockázat-arányosra**, az SSOT
elve szerint: a szigor maradjon ott, ahol pénzt/biztonságot/kontraktust véd; a rutinról kerüljön le.
- Always-on review/polling → „csak merge/deploy/magas-kockázat előtt".
- „Globális hatásvizsgálat minden kódváltozásra" → „contract-érintő / pénzügyi / biztonsági változásra".
- Ne *töröld* a szabály magját — **hatály-pontosító bannert** tegyél rá (visszafordítható, megőrzi a szándékot).

### 4.C Duplikátum-konszolidáció (jóváhagyással — visszafordíthatatlan törlés)

Klaszterenként, ebben a **biztonságos sorrendben**:

1. **Válaszd ki a kanonikust** (a legteljesebb fájl a klaszterből).
2. **Mentsd át az egyedi szabályokat** a kanonikusba — soronként verifikálva, hogy tényleg egyedi
   (a kanonikus még nem tartalmazza). Tedd egy rövid `## Beolvasztva: <fájl> (dátum)` szekcióba (nyomkövethető).
3. **Az elavult/túlszabályozó részt dobd el** (ne mentsd át) — pl. deprecated parancsblokk, „zero-tolerance always" framing.
4. **Repointold a referrereket**: minden link, ami a törlendő fájlra mutat → a kanonikusra
   (`grep -rn <fájlnév>` az összes operating fájlban; a linkleírás általában továbbra is illik).
5. **CSAK ezután töröld**: `git rm <redundáns-fájl>`.
6. **Verifikáld**: 0 dangling ref a törölt fájlra (a `## Beolvasztva:` eredet-jelölés nem dangling),
   mojibake re-szken tiszta.

> **Aranyszabály:** előbb migrálás + repoint, *utána* törlés. Soha fordítva.

---

## 5. Fegyelmi korlátok (anti-loop, anti-token-égetés)

- **A fázisok lineáris pipeline-t alkotnak, NEM hurkot.** Szken → audit → verifikáció → javítás egyszer fut.
  Tilos önmagába visszacsatolni („újra audit, hátha van több").
- **Javítási hurok-fék:** egy problémára max **2** azonos jellegű kísérlet; utána stratégiaváltás
  bizonyíték alapján vagy blokkoló jelzése — nem kompulzív újrapróbálkozás.
- **Stuck-state:** 5 érdemi haladás nélküli iteráció vagy 3× megközelítés-váltás → ÁLLJ MEG, írd le az
  akadályt + 2-3 opciót, ne iterálj vakon.
- **Hallucinált finding ≠ javítandó.** FP/Needs-More-Context findingre nincs javítási kör.
- **Scope-arányos költés:** teljes fan-out és magas effort csak nagy/kockázatos hatókörre; kis diffre
  egyetlen célzott pass.
- **Strukturális törlés = jóváhagyás.** Mandate/memória törlését/összevonását a felhasználó hagyja jóvá;
  mechanikus javítás mehet anélkül.

---

## 6. FÁZIS — Szállítás (ship)

Tisztán dokumentáció/agent-konfig változásnál:
1. Futtasd a repo **pre-push gate**-jét (lint/teszt/audit), ha van — a hookok megkövetelhetik.
2. **Secret-szken** a diffre push előtt.
3. Commit fókuszált üzenettel (mit konszolidáltál, mit szűkítettél, mit javítottál; sor-mérleg).
4. Push → PR → **várd meg a zöld CI-t**, majd merge (a repo merge-konvenciója szerint).
5. **Deploy:** docs/agent-konfig változás esetén **NEM** indokolt — a futó alkalmazás bitre azonos
   („merge != telepítő"). Csak akkor deployolj, ha valódi futtatható kód/réteg változott.

---

## 7. Záró ellenőrzőlista (Definition of Done)

- [ ] Mojibake/kódolás-szken: **0 hiba** (re-szken a javítások után is).
- [ ] Dangling hivatkozás: **0** (a `## Beolvasztva:` eredet-jelölés nem számít).
- [ ] Index-drift: **0** (minden index-bejegyzéshez fájl, minden fájl az indexben).
- [ ] Nincs két ütköző hard érték ugyanarra (PR-méret, timeout stb.).
- [ ] Duplikátum-klaszterek: egy kanonikus / klaszter, egyedi szabályok átmentve, redundánsak törölve.
- [ ] Always-on túlszabályozás kockázat-arányosra szűkítve (a domain-szigor megőrizve).
- [ ] Minden subagent-finding verifikálva; téves findingok dokumentáltan elvetve.
- [ ] CI zöld; szállítás a repo konvenciója szerint; docs-only → nincs felesleges deploy.

---

## 8. Általánosítás más stackre

- A szkennek **nyelv-/stack-függetlenek** (MD/szöveg-szintűek) — csak a `FILES` listát és az index/mappa
  útvonalakat igazítsd.
- Ha nincs `AGENTS.md`-szerű SSOT, **előbb jelöld ki** (vagy hozd létre) az egyetlen igazságforrást — a
  konszolidáció ehhez mér mindent.
- A determinisztikus eszközöket (secret-szken, dependency-CVE) **kombináld** az AI-réteggel; az AI a
  szemantikus duplikáció/ellentmondás felderítésében erős, a determinisztikus eszköz a teljes lefedettség
  és a pontos kódolás-/secret-ellenőrzés garanciája.

---

*Forrás: a valutavalto-program operating-rendszer 2026-06-15-i mély auditja és karcsúsítása
(48→44 mandate, −333 sor duplikáció, 7 dangling ref és 1 hard-érték-ellentmondás javítva, 0 kódolási hiba).*
