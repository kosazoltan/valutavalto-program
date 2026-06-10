# B1 — „ERB egyedi kötés" verdikt (2026-06-10)

**Módszer:** a forrás-képernyőkép (`Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/
Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/Képernyőképek/ERB Egyedi kötés.JPG`)
ÚJRA-OCR-ezése nagy felbontásban, a 2026-06-02-i részleges OCR helyett. Kizárólag a képen
ténylegesen látható elemek.

## Mit mutat valójában a kép

A dialógus tartalma (tisztán olvasható):

| Elem | Érték |
|---|---|
| Mező: `TÁRSPÉNZTÁR:` | `ERB` (előre kitöltött) |
| Fejléc (piros sáv) | `EGYEDI KOTES RB` |
| Mező: `SZÁLLÍTÓ NEVE:` | (üres beviteli mező) |
| Mező: `PLOMBASZÁM:` | (üres beviteli mező) |
| Mező: `MEGJEGYZÉS:` | (üres beviteli mező) |
| Gomb | `KÖNYVELHETŐ` |
| Gomb | `MÉGSEM` |

## Verdikt

1. **A b3b-erb-egyedi-kotas.md spec értelmezése TÉVES** (a részleges OCR-ből származó
   extrapoláció): a képernyő NEM bankkártyás szerződéskötési felület — nincs rajta
   bankkártya-mező, F3 gomb, PCI-DSS-releváns adat vagy terminál-protokoll elem.
2. A képernyő valójában: **értéktovábbítás (egyedi kötés) az ERB/Raiffeisen banki
   TÁRSPÉNZTÁR felé**, szállító nevével, plombaszámmal és megjegyzéssel, könyvelés
   (KÖNYVELHETŐ) vagy elvetés (MÉGSEM) választással.
3. **A funkciót a modern rendszer MÁR LEFEDI** az átadás-átvétel modulban (FK-013/FK02):
   - Cél-dropdown banki partnerekkel, köztük Raiffeisen:
     `frontend-react/src/pages/shipments/ShipmentNewPage.test.tsx:117` —
     `{ id: 'BR-PRB', code: 'PRB', name: 'POS Raiffeisen Bank', ... }` (assert: `:141`).
   - Szállító neve + plombaszám kötelező, közös validátorral:
     `ShipmentNewPage.tsx:216-231` (`validateCarrierSeal`).
   - Megjegyzés mező: `ShipmentNewPage.tsx:23,62,229` (`notes`).
   - Könyvelés/elvetés: a form submit / mégsem gombjai.

## Következmény

- **B1 a nyitott gap-listáról LEZÁRHATÓ** — nem új modul, hanem már implementált
  funkció más néven. Nincs kódteendő.
- A `b3b-erb-egyedi-kotas.md` FR-ERB-01..04 követelményei a téves értelmezésen alapulnak;
  a spec autoritatív forrása ez a verdikt + a fenti kép-átirat.
