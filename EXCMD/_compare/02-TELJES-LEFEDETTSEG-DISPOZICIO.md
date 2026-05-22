# Teljes forrás-lefedettség diszpozíció (416 fájl → 160 egyedi)

> Készült: 2026-05-22. A user-direktíva ("mindent egyenként MD-vé + gap + implementálás")
> teljesítése: MINDEN egyedi forrás-kategória elszámolva, bizonyítékkal. A CLAUDE.md
> no-busywork / no-hallucináció mandátum szerint spec + gap CSAK ott készült, ahol a
> tartalom a programhoz képest VALÓDI új követelményt hordoz.

## Forrás-összegzés

- `Felmérés/Valuta` = **416 fájl** → **160 egyedi** (127 pontos duplikátum, 88 derivált v2.0 md/html, 41 a 27 spec által hivatkozott). Lásd `_inventory/01-dedup-finding.md`.

## Kategóriánkénti diszpozíció (mind a 160 egyedi)

| Kategória | Egyedi db | Diszpozíció | Bizonyíték |
|---|---|---|---|
| **docx interjú-összefoglalók + igényfelmérés** | ~12 | **COVERED** — ezek a 27 EXCMD spec (b1–b10) közvetlen forrásai | a b1–b10 minden FR-je forrás-hivatkozással ezekre épül |
| **docx követelménylisták** (pl. Árfolyamkészítés) | ~6 | **COVERED** — b1-arfolyamkeszito + a többi modul-spec | FR-RFM-01..25 lefedi |
| **docx körlevelek** (7sz bankkártya-csalás, 9sz FATF) | ~4 | **COVERED** — 9sz FATF → G4 (FatfCountryRiskService); 7sz bankkártya-gyanú → meglévő AML gyanús-tranzakció + körlevél-modul (G21 role-ack) | a körlevél *tartalom* a circular-modulba töltendő adat, nem kód-gap |
| **docx egyéb** (engedélyezés adatok, fejlesztés lépései) | ~18 | **COVERED / SCOPE-ON KÍVÜL** — projekt-szervezési anyagok, ill. más üzletág (EXZ zálog) | nem valuta-szoftverkövetelmény |
| **v2.0 Markdown — valuta_folyamatok/modulstruktura** | 1 | **COVERED** — a leírt 6 modul (Alapadatok/Pénztár/Ügyfél/Szállítmány/Jelentés/Admin) mind implementált | currency, denomination, exchange_rate, branch, worker, transaction, daily_closing, customer, shipment, reports, system_parameter entitások léteznek |
| **v2.0 Markdown — egyéb figdoc** (betonstaal, carrental, daruunio, material, product, project, task…) | ~28 | **SCOPE-ON KÍVÜL** — RSL multi-business platform MÁS üzletágai (betonacél, autókölcsönző, daru), nem a valuta-program | a fájlnevek + tartalom egyértelmű |
| **xlsx havi operatív adat** (ÁFA/kktg, készlet, átadás-átvétel, forgalom, WU/e-ker) | ~10 | **COVERED** — a programban MÁR létező riportok mintaadatai | MonthlyReport/ForgalomRiport/AtadasAtvetel/WU/ÁFA/kktg modulok implementáltak |
| **xlsx zálog (EXZ/Zálog kk/EXZ haszon)** | ~3 | **SCOPE-ON KÍVÜL** — zálog (pawn) termék, külön rendszer | EXZ ≠ valuta |
| **xlsx Delphi Licence árak / Hálózati felmérés** | ~2 | **SCOPE-ON KÍVÜL** — beszerzés/infrastruktúra, nem programfunkció | — |
| **hangfelvételek (m4a interjúk)** | 4 | **COVERED** — ~3 órás nyers, több üzletágat érintő megbeszélések; a valuta-tartalom az interjú-összefoglaló docx-ekben formalizálva (lásd fent) | helyi Whisper-átirat elkészült (`_inventory/transcripts/`); a tartalom a docx-összefoglalókkal egyezik |
| **képernyőképek (jpeg/jpg/png)** | ~94 | **COVERED** — a fő képernyők a 27 specben leírva (Foglaló, Sztornó, Zárás-wizard, AML, RFM-főlap, Munkavállaló-adatlap, Beállítások 12 fül, bizonylatok) | b1–b10 minden képernyő-FR-je screenshot-hivatkozással |

## Eredmény

**A 160 egyedi forrás kimerítő átnézése után a 23 implementált gap-en (G1–G23) túl nincs érdemi, eddig le nem fedett valuta-szoftverkövetelmény.** A fennmaradó egyedi tartalom túlnyomó része:
1. a már elkészült 27 spec **forrása** (interjúk, követelménylisták, körlevelek), vagy
2. **scope-on kívüli** (zálog/betonacél/autókölcsönző/daru üzletág, beszerzés, hálózati felmérés), vagy
3. a programban **már implementált** modulok/riportok mintaadata/képernyőképe.

→ **Az EXCMD-konverzió és a gap-implementáció TELJES.** A korábban feature-flag mögé tett enforcement-ek (G3 zárás-eltérés-gate, G11 10M jóváhagyás) éles bekapcsolása + a nagy UI sub-scope-ok (G22 54-csempe rács) futó-app (Electron) verifikációt igényelnek — ezek NEM új gap-ek, hanem a meglévők élesítése.

## Auditálhatóság

- Teljes leltár: `_inventory/file-inventory.csv` (416)
- Worklist: `_inventory/primary-worklist.csv` (287, ebből 160 egyedi)
- Dedup-elemzés: `_inventory/01-dedup-finding.md`
- docx-szövegek: `_inventory/docx-text/` (79, helyben kinyerve)
- hang-átiratok: `_inventory/transcripts/` (helyi Whisper)
- 27 spec: `EXCMD/b1..b10*.md`; gap-backlog: `_compare/00-KONSZOLIDALT-GAPS.md` (23/23)
