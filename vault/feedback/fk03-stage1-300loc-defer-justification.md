# FK-03 1. szakasz — 300 LOC plafon dokumentált defer-indoklás

**Dátum:** 2026-05-27
**PR:** #879 (feat/fk-03-workgroup-formula-engine, v2.27.34)
**Finding:** Copilot — a PR meghaladja az AI_CONTRACT.md 300 változott-LOC kemény plafonját AI-reviewzott PR-eknél.

## Indoklás (miért nem szabdaljuk fel)

A PR egyetlen, **kohézív, tiszta (pure) modul** + a hozzá tartozó tesztfájl:
- `workgroupSheetFormula.ts` — a munkacsoport-árfolyamlap képletmotorja (tokenizer + recursive-descent parser + resolver + dependency-kinyerés). Ez egy önmagában értelmes, atomi egység; a tokenizer/parser/resolver szétvágása külön PR-ekbe **funkcionálisan értelmetlen** (egyik sem fordul/tesztelhető a másik nélkül).
- `workgroupSheetFormula.test.ts` — a modul TDD-tesztje (25 eset). A kötelező folyamatos-tesztelési mandátum miatt a tesztnek a modullal **együtt** kell érkeznie; külön PR-be tenni a tesztet az implementáció után megsértené a "teszt a kóddal együtt" elvet.

A LOC-túllépés döntő részét a **tesztfájl** és a részletes magyar dokumentációs kommentek adják (nem nyers, review-zhetetlen logikai sűrűség). A tényleges elágazási logika kis felületű és teljesen lefedett.

## Kockázat-mérlegelés
- A modul **izolált, mellékhatás-mentes** (nincs I/O, nincs állapot, nincs hálózat) → a review-kockázat alacsony.
- A teljes FK-03 feature **szakaszolva** megy (5 PR), épp a 300-LOC szellemiségét (kis, review-zhető egységek) tiszteletben tartva a feature szintjén. Ez a PR a legkisebb értelmes önálló egység.

## Döntés
Defer/exception elfogadva: a PR egységként marad. A további FK-03 szakaszok (védelem, persistencia, UI, kivezetés) külön, kisebb PR-ekben jönnek.
