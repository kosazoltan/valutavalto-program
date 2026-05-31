# Session 2026-05-31 — Reversal-cap concurrency + security milestone (v2.27.66 → v2.27.70)

## Kiindulás
A #944 PR (napi sztornó-plafon: prior-day NEVER + aznapi max-3, 3.=supervisor, 4+=block) **OPEN** volt;
egy Codex P1 review valós concurrency-rést jelzett a `getDailyReversalCount()` lock-mentes olvasásán.
Mivel #944 nem mergelt, a fixet UGYANAZON a branchen (#944) folytattam (nem main-ről új branch).

## Elvégzett munka — 7 mergelt PR

| PR | Tartalom | Verzió |
|---|---|---|
| #944 | reversal-cap + 4 Codex-kör fix (lent) | 2.27.66→67 |
| #945 | Univerzális AI Ügynök Protokoll mandate (C.27) | docs |
| #946 | CodeQL log-injection — sanitizeForLog (CWE-117) | 2.27.68 |
| #947 | cash-vs-cash lock-ordering deadlock — CashLockOrdering | 2.27.69 |
| #948 | CodeQL #260 végleges — log → hossz (int) | 2.27.70 |
| #949 | Hibavédelmi Protokoll v2 mandate (C.28) | docs |

### #944 — 4 Codex-review-kör (mind a #944 branchen, merge előtt)
1. **P1 concurrency-lock:** `getDailyReversalCountForUpdate()` PESSIMISTIC_WRITE (`findByBranchIdAndSessionDateForUpdate`,
   CashBalance-mintát követve, JOIN FETCH nélkül) — a plafon-ellenőrzést szerializálja a count-növelés előtt.
   Fail-loud: nincs nyitott session → dob (nem 0). TDD: InOrder-teszt.
2. **P2 precheck-szinkron:** `StornoService.doCheckStorno` + `requestApproval` az execute-tel azonos branch-szintű
   szemantika (3.=approval, 4.+=throw plafon), nincs elárvult approval.
3. **P2 approval-honor:** a 3. sztornó megadott jóváhagyással (`approvalId`) a PÉNZTÁROS által is végrehajtható —
   `ReversalRequest.supervisorApproved` + szerver-oldali `isValidGrantedApproval` (APPROVED + azonos tx + azonos branch).
4. **P1 deadlock (daily_session↔cash):** a sztornó a cash sorokat a daily_session lock ELŐTT lockolja
   (`helper.lockCashBalance`) → konzisztens cash→daily_session sorrend a normál flow-val.

### #947 — cash-vs-cash deadlock (a #944 self-review tárta fel, PRE-EXISTING)
A BUY a HUF-ot lockolta előbb (`validateCurrencyStock(HUF)`), a SELL/sztornó a devizát → AB-BA deadlock.
Fix: `CashLockOrdering.lockInAscendingCurrencyOrder` — minden single-branch út növekvő currencyId sorrendben.
Lefedve: Buy/Sell/Reversal/PartialRefund/Conversion/MultiLine.

## Nyitott follow-up (dokumentált, NEM elvégezve)
- **Cross-branch cash lock-ordering** (`TradeService.moveTradeInventory`: forrás+cél iroda azonos valutája) —
  `(branch,currency)`-tuple rendezést igényel. CashLockOrdering javadocban dokumentálva.
- **approve() 4-szem-elv** (requester≠approver guard) — pre-existing, nem kihasználható priv-esc (supervisor amúgy
  is végrehajthatja). Korábban spawnolt taskként dokumentálva.

## Incidens — két-ágens-egy-fa ütközés (TANULSÁG)
A korábban (általam) `spawn_task`-kal létrehozott cash-lock follow-up ágens UGYANABBAN a working tree-ben
kezdett dolgozni → változásai beszivárogtak a log-injection branchembe + suite-bukás. **User-direktíva:
párhuzamos ügynök TILOS, ha nem kérte.** Helyreállítás: a cash-lock draftot stash + backup patch izolálta,
átvettem és befejeztem MAGAM (a #944 lock-order tesztet ascending-orderre javítva). Beépítve: Hibavédelmi v2 (C.28).

## Protokoll-integrációk
- **C.27 Univerzális AI Ügynök Protokoll** (#945): Plan-First→terv-de-ne-állj-meg; telepítő→Downloads MINDEN
  milestone-nál (user-döntés, felülírja a „merge≠telepítő"-t); memória=vault.
- **C.28 Hibavédelmi Protokoll v2** (#949): kísérlet-napló, hurok-/variáció-észlelés, STRATÉGIA-ROTÁCIÓ,
  kitörés 5-lépés, strukturált válaszforma.

## Verifikáció (bizonyíték)
- Teljes backend suite végállapot: **1812 teszt, 0 hiba, 0 error** (236 osztály).
- CodeQL: #259 + #260 (java/log-injection, StornoService) **fixed**; nincs nyitott log-injection alert.
- Production: `bootstrap-status` **HTTP 200**, EBC branches non-empty.
- 4-way verzió-sync: **2.27.70** (mind a 6 forrás).
- Minden PR: CI zöld + Codex „Didn't find any major issues" + 0 nyitott P0/P1/P2.

## Telepítő (C.27 értékes végtermék — LESZÁLLÍTVA)
Milestone-záró build (UNSIGNED — DigiCert EV cert még nincs kiadva → `ALLOW_UNSIGNED_BUILD=1`;
az első build CODE_SIGN unset miatt bukott, KONFIG-rotáció a flaggel megoldotta). A kész telepítők a
`C:\Users\Kósa Zoltán\Downloads` mappában:
- **Penztar-Setup-2.27.70-20260531.exe** — 295 425 080 bájt (281.74 MB), SHA256 `9A4FBFB245DEF810E86E6C482C9083AD5785EB356199F3B58BC4EBC624223B05`
- **Penztar-Eltavolito-2.27.70-20260531.exe** — 60 859 bájt, SHA256 `9B352323950365F4E8F88C03F8FD973EAEE2E04ED3E00FF00D859096781B4315`

Nincs külön Kozponti-Munkaallomas build-script a build-flow-ban (csak Penztar-Setup + Eltavolito).

## Munkamód-tanulság (Hibavédelmi v2 alkalmazva)
- Build-hiba: gyökérok-diagnózis ELŐSZÖR (CODE_SIGN unset) → KONFIG-réteg rotáció (ALLOW_UNSIGNED_BUILD=1),
  nem vak újrapróbálkozás.
- Két-ágens-egy-fa ütközés: izolálás (stash+patch) + saját befejezés, párhuzamos ügynök nélkül.
- Strukturált válaszforma + bizonyíték-kényszer végig (suite-kimenet, SHA256, CodeQL-state, prod-200).
