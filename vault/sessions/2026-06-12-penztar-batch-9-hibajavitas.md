# 2026-06-12 — Pénztár-batch: 9 user-reportált hiba/kérés (Fabulya Zsuzsanna teszt, v2.27.99)

## Szállítás: 4 PR (3 MERGED + 1 folyamatban a jegyzet írásakor)

### PR #1100 — Sztornó (D.1+D.2) ✅ MERGED
- D.1: „Egyedi árfolyam" + „Fizetési mód" mezők törölve — a `paymentMethodDid` a backenden
  HALOTT mező volt (sehol nem olvassák; a sztornó az eredeti fizetési módot örökli), az üres
  customExchangeRate defaultja az eredeti árfolyam. Backend DTO változatlan (régi queue-k).
- D.2: végrehajtás után sztornó-bizonylat előnézet + nyomtatás a MEGLÉVŐ 'storno'
  template-tel; navigáció a modal zárásakor. Review-fixek: perzisztált LST-referencia a
  sync ELŐTT lekérve (Codex P2); onPrint hibaágak THROW-val (modal nyitva marad — Copilot).

### PR #1101 — Átadás-átvétel (A.1–A.3) ✅ MERGED
- A.1: a backend transfer_lines (V243) modell kész volt — a frontend Transfer interfész nem
  deklarálta a lines-t; lista + bizonylat-előnézet + offline queue (valutakóddal dúsított
  JSON) végig-vezetve.
- A.2: a szem ikon a /transfers/:id önmagára mutató route helyett bizonylat-előnézetet nyit
  a sor teljes adataiból; Kérő/Cél a kanonikus from/to mezőkből; sztornózott sornál
  sztornó-sorszám. Verif-fix: offline `direction` mapping (különben az átvétel fordított
  orientációval nyílt volna).
- A.3: címlet-preset a denomination törzsből (CASHIER-nek elérhető), csökkenő névértékkel;
  szabad bevitel fallback. Verif/review-fixek: stale-preset törlés üres törzsnél; ref a
  fetch indításakor (gépelés alatti refetch-spam ellen); beírt darabszám védelme
  (applyIfPristine); currencyCode-feloldás a törzsből (HUF-formázás).
- Defer (dokumentált): vaultAddress/vaultPhone a backend toDto-ban a NÉZŐ fiókjából —
  kiállító-cím perzisztálás backend-változást igényel (külön kérés).

### PR #1102 — Bizonylat-tartalom (C.1+C.2) ✅ MERGED ⚠️ Electron-natív → telepítő kell
- Kétrétegű gyökérok: (1) a receiptHeader/receiptBase nem adta át a foreignStatus + Pmt.
  mezőket; (2) a printer.ts (ESC/POS+HTML) és serial-printer.ts nem is renderelte őket.
- Fix a kanonikus EscPosReceiptService tükreként: „Az ügyletet készpénzben teljesítjük" +
  „Deviza-státusz: Külföldi/Belföldi/—" MINDEN vétel/eladás bizonylaton (összegtől és
  azonosítási szinttől függetlenül); 300k+ felett PEP-sor (minőséggel) + JOGCÍM NYILATKOZAT
  (saját nevemben / képviselt fél teljes adatai + pénzeszköz forrása, 42 char tördelés).
- Review-fixek: Codex P1 — a 300k-s küszöb az AML-lel azonos FIZETENDŐ összegre számol
  (payableHufAmount mező); HTML pre-wrap; import-összevonás; +HTML-útvonal tesztek.
- A.1 follow-up: több-valutás transfer-sorok az ESC/POS + HTML + soros template-ben is.

### PR #1103 — Kezelési díj + sávos árfolyam (B.1+B.2) — folyamatban
- TÉNY: a kért „Kezelési költség beállítások" menü MÁR LÉTEZETT (/handling-fee-config,
  ezrelékes/sávos, vezetői jog), és a szerver EDDIG IS ezzel könyvelt (HandlingFeeCalculator
  autoritatív). A valódi hibák:
- B.1: a pénztáros-képernyő 0 Ft díjat mutatott (a szerver mást könyvelt!) → backend GET
  read-only a pénztárosnak + utils/handlingFee.ts bit-pontos tükör (PER_MILLE: HALF_UP +
  sapka; BRACKET: sáv-lookup; roundToFive≡roundHuf) + auto-effect (override alatt nem ír felül).
  Defer: DiscountThresholdService küszöb-kedvezmény nem tükrözött.
- B.1/b: a díj-override (Felezés/Elengedés/Ügyfélkártya) az Electron offline úton CSENDBEN
  ELVESZETT → teljes lánc pótolva (input-típusok → buildEntry → SQLite 3 defenzív ALTER →
  sync-engine body). ⚠️ Electron-natív.
- B.2: kattintható sáv-gombok (Alap/Limit1–3) összeg-küszöb gate-tel + tooltip (wrapper
  span-en — Copilot). ADAT-előfeltétel: ha csak „Alap" látszik, a publikált ráta limit-mezői
  NULL-ok — a munkacsoport-lap limit-oszlopait kell kitölteni.
- Codex P1 (kritikus, pre-existing): a képernyő-total SELL-előjelű volt — BUY-nál a díj
  LEVONÓDIK a kifizetésből, a kedvezmény hozzáadódik → a total + AML-küszöb + a #1102-es
  singleRowPayable mind a kanonikus multiLinePayable-re állt át.

## Folyamat-jegyzetek
- PÁRHUZAMOS SESSION dolgozott ugyanezen a worktree-n (print-throw chip) → az ütközést
  git worktree-kkel (vv-receipt-fix, vv-fee-fix) kerültem el; memória-szabály született róla.
- Minden PR-en: CI + Codex/Copilot review + finding-javítás; a #1100/#1101-en adverzáriális
  verifikációs workflow is futott (1 valódi P1-et talált: dirty stale-closure mintájú
  direction-hiányt az offline transfer-bizonylatnál).
- Flaky: VaultClosingChecklistPanel a teljes suite alatt időnként bukik, izoláltan zöld —
  chip kiírva a stabilizálásra (task_26c70d64).
- Telepítő-build: a #1102+#1103 penztar-client/electron/** változásai miatt a batch végén
  EGY build (windows-unsigned-release.yml, Google-secretek CI-ben).
