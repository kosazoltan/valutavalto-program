---
title: "Release marathon: v2.5.60 → v2.5.64 (B-kategória bug fix + Branch/Vault sync + 2-kör mandate kibővítés)"
date: 2026-05-19
participants: [Kósa Zoltán, Claude Opus 4.7]
verzió_kezdő: v2.5.59
verzió_záró: v2.5.64
pr_merged: [#695, #697, #698, #699, #700]
pr_closed_garbage: [#693]
mandate_új: vault/feedback/two-rounds-self-subagent-review-mandatory-2026-05-19.md
---

# Release marathon 2026-05-19: 5 release egy napon

## Áttekintés

A reggel-délután-este maraton 5 release-t adott ki, mindegyik a Fabulya Zsuzsanna
által 2026-05-19-én reggel jelentett **18 felhasználói bug** B-kategóriájára,
plus a Kósa Zoltán Google Sheets alapú Branch/Vault sync direktívájára.

## Release-ek sorrendje

### v2.5.60 (PR #695, merge `28d7c70d`)
**8 bug B-kategória atomikus fix-batch** (HIBA #10, #12, #13, #14, #15, #17, #18, #19):

- **HIBA #13 root-cause:** `customer.nationality VARCHAR(3)` nem fért bele a frontend
  "Magyar"/"EU-állampolgárság"/"Egyéb" humanreadable szövegbe → HTTP 500. V236 ALTER.
- **HIBA #14, #17, #18:** 16 customer-snapshot oszlop az Electron offline queue
  `pending_transactions` táblába + actor identity (más nevében).
- **HIBA #15:** PepKind enum (6 érték) + V235 + ReceiptGeneratorService buildPepStatusText().
- **HIBA #19 új direktíva:** Konverzió Pmt. — ha buy+sell összeg ≥ 100k HUF, egyszerűsített
  azonosítás, ≥ 300k teljes (PEP + saját nevében kérdés).
- **Codex P1 #1:** Pmt. enforcement feature-flag (`PMT_STRICT_ENFORCEMENT`, default false v2.5.59 kompat).
- **Codex P1 #2:** Conversion Electron Pmt. plumbing 5-layer fix.
- Plus 12 Copilot P2 + CI fix (PepSourceOfFundsTest NPE).

### v2.5.61 (PR #697, merge `0660ff46c`)
**HyperFormula cell-engine + 6 valuta törlés + Currency Manager UI** — új P0 mandate
("két ellenőrzési kör merge előtt") **trigger**:

- **HyperFormula v3.2.0** (GPL v3, internal-use): A-I oszlopok Excel-szerű formulákkal,
  reaktív dependency-graph, formulaMap state + localStorage.
- **6 valuta törlés** (DKK, NOK, SEK, HRK, BGN, RCH): V237 `UPDATE is_active=false`,
  DEFAULT_CURRENCIES 28 → 22.
- **Currency Manager UI:** új admin modal (admin/főértéktáros/ügyvezető), `POST /currencies`
  + `PATCH /currencies/{id}/active`, **SOHA NEM DELETE** (Pmt./NAV 8-év megőrzés).
- **V238:** `currency_audit_log` immutable table (UPDATE+DELETE trigger-tiltva, JSONB
  snapshot, worker_id + ip_address + note).
- Plus CodeQL log-injection sanitizeForLog + Codex P1 sync formula eval + 5 Copilot P2.

### v2.5.62 (PR #698, merge `3847c65236`)
**NSIS Penztar.exe ESET silent-deny hot-fix** — v2.5.61 install Kósa Zoltán
tesztgépen broken: 212 MB Penztar.exe hiányzott a `C:\Program Files`-ből.
ESET ekrn.exe silent-deny (NEM karantén, file-write-block) UNSIGNED Electron exe-re:

- NSIS `File /r ... /x "Penztar.exe"` (exclude) + explicit `File "${STAGE_DIR}\electron\Penztar.exe"`
- Post-install `IfFileExists $INSTDIR\Penztar.exe` verify → `Abort` + **MAGYAR MAGAZÓ**
  MessageBox ("Kapcsolja ki az ESET-et 10 percre / Indítsa újra a telepítőt").
- `$EXEFILE` macro a hardcoded név helyett (Sourcery P3).
- `IfSilent +2` silent-install guard (Copilot P2).

### v2.5.63 (PR #699, merge `f84a31d4ea`)
**V239 Branch/Vault sync** — Kósa Zoltán Google Sheets direktíva
("értéktári program csak értéktárra lehessen telepíteni"):

- DIAGNÓZIS: production 66 iroda + **0 isVault=true**. Sheet 73 + 8 értéktár.
  9 hiány (8 értéktár + 1 Szeged Móra).
- V239: DO $$ PL/pgSQL — idempotens INSERT 9 új branch FK-clone BR009 template-ből,
  `ON CONFLICT (code) DO NOTHING`, defensive UPDATE `is_vault=TRUE`.
- Frontend `filterBranchesForAppMode` MÁR HELYES (graceful fallback) — csak data-INSERT.
- Production verify: 74 iroda + 8 isVault=true ✅.

### v2.5.64 (PR #700, merge `727d08079`) — JELEN SESSION FŐ MUNKÁJA
**V240 follow-up #699 AI review P2 fix-jeire:**

- **Codex P2:** V145 seed-ben már létezett BR026 ('Szeged Shell Site-Móra' + zip 6720).
  V239 `ON CONFLICT DO NOTHING` kihagyta a Google Sheet értékek (Szeged Móra,
  Szabadkai út 7., 6729) UPDATE-jét.
- **Copilot P2:** V239 a BR009 template-ből clone-olta a `bank_code`-ot → 9 új branch
  mind `bank_code='BR009'` (helytelen). V145 konvenció: `bank_code = self.code`.
- V240 idempotens UPDATE-pár, IS DISTINCT FROM null-safe, GET DIAGNOSTICS ROW_COUNT.
- **2-kör SAJÁT subagent self-review** (új user-direktíva):
  - Round 1: 2 párhuzamos agent (SQL/Flyway + multi-tenant/safety) → mindkettő SAFE TO MERGE
  - Round 2: fresh verify agent → 4 aggály feloldva (`branch.updated_at` V0_1:57 létezik,
    V145 re-run kockázat LOW, V239 production state OK, IS DISTINCT FROM NULL OK)
- Production verify: BR026 name='Szeged Móra' ✅, 74 + 8 isVault=true ✅.

## PR #693 — felesleges repó-szemét

User kérdezte: "Miért van itt?". Megválaszolva + closed + branch deleted.
Eredetileg release/v2.5.59 verzió-bump volt, de 6 release-szel ezelőtti — a verzió
azóta v2.5.64-re ugrott, így overwrite-olódott. Tisztítás.

## Új user-direktíva (P0 mandate)

**15:45 CEST** (V240 review-flow közben):
> "Neked kell kétszer ellenőrizned a saját ai közeiddel egy másik ügynökkel
> az elkészült kódot, és csak utána mergeld."

Eredetileg `vault/feedback/two-rounds-self-subagent-review-mandatory-2026-05-19.md`-be
mentve. Teljes merge-protokoll: CI gate + GitHub AI gate + SAJÁT Round 1 + SAJÁT Round 2.

## Telepítő fájlok v2.5.64 (UNSIGNED, kész tesztelésre)

| Komponens | Méret | SHA-256 |
|---|---|---|
| Penztar-Setup-2.5.64-20260519.exe | 282.66 MB | ADE0455FCB21861905ADABECC434AAAE0B5773853A94227F4FC1A1657DC97956 |
| Kozponti-Iranyitokozpont-Setup-2.5.64.exe | 101.05 MB | A18BF6C40BEF48D3B9A5D3CE44EEEEDB6D236883E84C5F98A45D2638A6760AB9 |
| Arfolyamkeszito-Setup-2.5.64.exe | 101.05 MB | DFC24DAA08D95D8CD2971CDA191D8A46A22D093D33D25126508E4CFB8D22EEC3 |
| Penztar-Eltavolito-2.5.64-20260519.exe | 59.43 KB | 79717D8C9549F4A04BE2EC2BBEBAD6E38A5581558A1D62AC2E3C24FF0B9DD8ED |

UNSIGNED build — DigiCert EV CS cert még pending (Isabella org-domain email +
phone callback). SmartScreen "További információ" → "Futtatás mindenképp".

## DigiCert EV CS status (2026-05-19 napi update)

- Photo ID + selfie: ✅ DigiCert kézhez vette, review alatt
- Phone verification: 🔄 pending — Kósa Zoltán-nak callback időpontot kell foglalnia
- Org domain email proof: 🔄 Isabella kérte email update `kosa.zoltan.ebc@gmail.com` →
  `@bestchange.hu` (DigiCert "excbestchange.hu"-t írt — domain pontosítás kell)
- HSM Approval (Azure KV Premium): ✅ submitted 2026-05-15
- Reply email vázlat előkészítve (a session során) + cégkivonat attach
  (`Best cégkivonat 2026 05. hó.pdf`, 218 KB)

## Tanulságok (NEM jegyzetelendő, de "memóriában" hagyandó)

1. **Memória-mentés mulasztása** — A mai 5 release-t a user kifejezetten rákérdezett
   amíg én nem mentettem. **NE várd meg, hogy ráérdezzen** — merge után azonnal
   feedback + session jegyzet.
2. **Subagent self-review értéke** — A V240 subagent-ek felfedezték hogy a `branch.updated_at`
   oszlop létezését verifikálni kell + flagelték a V145 re-run kockázatot. Ez a GitHub
   AI botok elől elcsúszott.
3. **AI bot dual-channel** — Codex review API `/pulls/{N}/reviews` MŰKÖDIK. Codex
   ChatGPT-mention csatorna (`@codex review` komment) **kollérázódhat** auth-error-rel
   (chatgpt-codex-connector setup-prompt), de az `/reviews` API-ra automatikusan érkezik.
4. **2-kör mandate skálázhatóság** — A GitHub AI gate (round 1+2) + SAJÁT subagent
   (round 1+2) együtt = **4-kör** total. Idő-költség kb. +5 perc / merge, de
   production-bug-kockázatot drasztikusan csökkenti.
