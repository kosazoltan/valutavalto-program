---
type: legal-baseline
scope: tax-accounting
version: 2026-04-09
format: structured-lookup
description: "Tax and accounting layer for fees, FX differences, receipts and retention in the money exchange program"
---

# Tax / Accounting Layer For Fees, FX Differences And Receipts

> Cel: az adojogi es szamviteli reteg kulon rogzitese a fee-, arfolyamkulonbozet-, bizonylati- es retention-logikahoz.
> Fontos: ez implementacios baseline, nem teljes adotanacsadas; a vegleges tax engine elott szukseges kulon adoszakertoi validacio.

---

## S1 FORRASKOR

1. `2000. evi C. torveny a szamvitelrol`
   - NJT: `https://njt.hu/jogszabaly/2000-100-00-00.50`
   - Kulcspont: `60. §` devizas es valutás tetelek forintos ertekelese, arfolyamkulonbozet

2. `2007. evi CXXVII. torveny az altalanos forgalmi adorol`
   - NJT: `https://njt.hu/jogszabaly/2007-127-00-00.95`
   - Kulcspont: penzugyi szolgaltatasok adojogi besorolasa, szamla/nyugta logika

3. `2017. evi CL. torveny az adozas rendjerol (Art.)`
   - NJT: `https://njt.hu/jogszabaly/2017-150-00-00`
   - Kulcspont: bizonylati, nyilvantartasi es megorzesi ellenorizhetoseg

4. `297/2001. (XII. 27.) Korm. rendelet`
   - NJT: `https://njt.hu/jogszabaly/2001-297-20-22`
   - Kulcspont: penzvaltasi veteli/eladasi/konverzios bizonylatok

5. `Exclusive Best Change publikus adatkezelesi tajekoztato`
   - a ceg sajat szabalyzati kornyezeteben hivatkozik a `Szamviteli tv.`, `Art.`, `Áfa tv.` alkalmazasara is

---

## S2 FEE-RETEG

### 1. Miert kell kulon entitaskent kezelni a fee-t?

A penzvaltasi uzleti logikaban a `fee / handling cost` nem keverheto ossze:

- a veteli/eladasi arfolyammarzzsal,
- a konyvelesi arfolyamkulonbozettel,
- a partneri jutalekkal,
- az esetleges adojogi besorolas szerinti adokoteles szolgaltatasi dijjal.

### 2. Kotelezo adatszerkezet

Minden tranzakciohoz ajanlott:

- `base_exchange_amount`
- `exchange_rate_used`
- `handling_fee_amount`
- `handling_fee_currency`
- `handling_fee_tax_code`
- `partner_commission_amount`
- `accounting_policy_rate_source`
- `cash_rounding_difference`

### 3. Implementacios szabaly

- a fee kulon sor legyen receipten / szamlan / accounting exportban;
- a fee adojogi besorolasa konfiguralt legyen;
- supervisor override kulon auditban rogzuljon, ha fee-t modosit.

---

## S3 DEVIZAS / VALUTAS SZAMVITELI RETEG

### 1. Szamviteli tv. `60. §` lenyege

A `Szamviteli tv.` alapjan:

- a valutapenztarba bekerulo valutakeszletet,
- a devizaszamlan levo devizat,
- a kulfoldi penzertekre szolo kovetelest es kotelezettseget

a bekerules napjara vonatkozo, forintra atszamitott erteken kell nyilvantartasba venni.

### 2. Valaszthato arfolyamforras

A torvenyi szoveg alapjan a forintra atszamitasnal alkalmazhato:

- a valasztott hitelintezet altal meghirdetett devizaveteli/devizaeladasi arfolyam atlaga, vagy
- az `MNB`, illetve `EKB` altal kozzetett hivatalos devizaarfolyam.

Kovetelmeny:

- az accounting export nem hasznalhat hardcoded, kezzel bemasolt arfolyamforrast;
- kell `accounting_rate_policy` konfiguracio;
- el kell kuloniteni a `transactional customer rate` es a `bookkeeping rate` fogalmat.

### 3. Arfolyamkulonbozet

A `Szamviteli tv.` alapjan a merlegfordulonapi ertekeleskor a konyv szerinti es az aktualis forintertek kulonbozete arfolyamkulonbozetkent jelenik meg.

Programkovetelmeny:

1. a rendszer tudjon `transaction FX result` es `accounting FX difference` kozott kulonbseget tenni;
2. a treasury/accounting retegben legyen kulon exportmező:
   - `book_value_huf`
   - `settlement_value_huf`
   - `fx_difference_huf`
3. a konyvelesi kulonbozet nem lehet azonos a front-office haszonkalkulacioval.

---

## S4 BIZONYLATI RETEG

### 1. Penzvaltoi bizonylatok

A `297/2001. Korm. rendelet` alapjan:

- veteli bizonylat,
- eladasi bizonylat,
- konverzios bizonylat

kulon szabalyzott kategoriak.

### 2. Art. altal megkivant ellenorizhetoseg

Az `Art.` alapjan a bizonylatokat, konyveket, nyilvantartasokat ugy kell vezetni, hogy azok:

- az adoalap,
- az ado osszege,
- a mentesség,
- a kedvezmeny,
- a megfizetes vagy igenybevetel

megallapitasara es ellenorzesere alkalmasak legyenek.

Kovetelmeny:

- immutable receipt numbering
- bizonylati hivatkozas minden ledger / export rekordban
- modositast csak storno, ervenytelenites vagy korrekcios dokumentum oldhasson meg

### 3. Nyugta / szamla / egyeb okirat

Az `Áfa tv.` es `Art.` egyuttesen arra mutatnak, hogy a rendszernek kulon tudnia kell:

- mikor eleg nyugta,
- mikor kell szamla,
- mikor van egyeb okirati igazolas,
- mikor kell modositani vagy ervenyteleniteni a korabbi bizonylatot.

Kovetelmeny:

- `document_type` kotelezo field
- `original_document_id` korrekcio eseten kotelezo
- `tax_evidence_status` kulon allapotkent ajanlott

---

## S5 AFA / TAX CLASSIFICATION RETEG

### 1. Mi ismert biztosan?

Az `Áfa tv.` szovegeben megjelenik a penzugyi szolgaltatasok kulon kezelese, valamint a szamla/nyugta logika tobb helyen.

Implementacios szempontbol a biztos kovetelmeny:

- nem szabad feltetelezni, hogy minden tranzakcios sor azonos AFA-besorolasu;
- a penzvaltasi alapugylet, a fee, a partneri kozvetites es az egyeb extra szolgaltatas kulon tax code-ot kaphat.

### 2. Mivel kell szamolni a modellben?

Legalabb ezekkel:

- `vat_classification`
- `vat_rate_percent`
- `is_vat_exempt`
- `vat_exemption_basis`
- `invoice_required`
- `receipt_allowed`

### 3. Nyitott adoexpert kérdések

Kulon validalando:

- a penzvaltasi fee pontos AFA-minositese,
- a partneri kozvetitesi dij es jutalek kezelese,
- a VAT refund kapcsolodo dokumentumok es elszamolasok.

Ezekhez szakertoi review kotelezo a vegleges release elott.

---

## S6 RETENTION ES ADATMEGORZES

Az `Art.` alapjan a bizonylatokat, nyilvantartasokat ugy kell megorizni, hogy ellenorzes eseten elektronikusan is hozzaferhetoek legyenek.

Kovetelmeny:

- receiptek / szamlak / exportok letolthetok legyenek;
- legyen `document_archive` reteg;
- elektronikusan orzott iratoknal online vagy export hozzaferest kell tudni adni;
- az audit trail ne valjon le a bizonylatokrol.

---

## S7 KONKRET PROGRAMKOVETELMENYEK

1. `transaction rate` es `accounting rate` kulon mező.
2. `handling fee` kulon line item.
3. `tax classification` kulon konfiguracios tabla.
4. `buy/sell/conversion receipt` kulon template.
5. `storno/correction chain` kotelezo.
6. `branch + partner + service` dimenziok az accounting exportban.
7. `MNB / bank average / ECB` accounting rate source policyzhato legyen.
8. `cash rounding difference` kulon mező, ne simuljon bele a fee-be.
9. `immutable numbering + audit` kotelezo.
10. `export evidence retention` kotelezo.

---

## S8 TESZTIRANYOK

### Fee

- fee override utan a receipt kulon sorban mutatja a modositott dijat
- fee tax code hianya eseten a publikacio blokkol

### FX

- ugyanazon ugyletnel a customer rate es accounting rate kulon ertekkent jelenik meg
- MNB policy es bank-atlag policy mas accounting exportot ad

### Receipt

- buy/sell/conversion mind eltero dokumentumtipust general
- storno utan a kapcsolat az eredeti bizonylathoz visszakeresheto

### Archive

- dokumentumok elektronikusan exportalhatok
- ellenorzeshez szukseges hivatkozasok (document id, original id, tax class, rate source) megmaradnak

---

## S9 NYITOTT GAP-EK

| Gap ID | Kerdes | Statusz |
|--------|--------|---------|
| `TAX-GAP-01` | A penzvaltasi fee pontos AFA-minositese a ceg konkret uzletszabalyzata alapjan teljesen levezetett-e? | nyitott |
| `TAX-GAP-02` | A VAT refund folyamat sajat tax/bizonylati dokumentumai teljesen fel vannak-e mar terkepezve? | nyitott |
| `TAX-GAP-03` | A repo jelenlegi treasury/export moduljai kulon kezelik-e a transaction vs accounting rate fogalmat? | nyitott |
| `TAX-GAP-04` | A receipt engine tamogatja-e a tax classification mezoszintu auditjat? | nyitott |
