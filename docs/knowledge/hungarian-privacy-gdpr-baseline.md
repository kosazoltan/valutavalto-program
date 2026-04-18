---
type: legal-baseline
scope: privacy-gdpr
version: 2026-04-09
format: structured-lookup
description: "Hungarian GDPR and privacy baseline for money exchange, AML and customer data processing"
---

# Hungarian Privacy And GDPR Baseline

> Cel: a magyarorszagi GDPR/adatvedelmi baseline rogzitese a penzvalto rendszerhez, kulonosen az ugyfel-azonositas, AML, kamera, marketing es partneri adatkezelesi szerepek szempontjabol.
> Modszertan: hivatalos jogforras + NAIH-elvi forras + a ceg publikus adatkezelesi tajekoztatoja.

---

## S1 FORRASKOR

### Elsodleges jogforrasok

1. `Regulation (EU) 2016/679 (GDPR)`
   - EUR-Lex: `https://eur-lex.europa.eu/eli/reg/2016/679`
   - Kulcspont: alapelvek, jogalapok, erintetti jogok, elszamoltathatosag, privacy by design/default

2. `2011. evi CXII. torveny (Infotv.)`
   - NJT: `https://njt.hu/jogszabaly/2011-112-00-00.5`
   - Kulcspont: magyar kiegeszito adatvedelmi keret, jogorvoslat, adatbiztonsag, tajekoztatasi kovetelmenyek

3. `2017. evi LIII. torveny (Pmt.)`
   - NJT: `https://njt.hu/jogszabaly/2017-53-00-00.3`
   - Kulcspont: kotelezo AML/KYC adatkezeles es megorzes

4. `2017. evi LII. torveny (Kit.)`
   - NJT: `https://njt.hu/jogszabaly/2017-52-00-00`
   - Kulcspont: szankcios szures es kapcsolodo adatkezeles

5. `297/2001. (XII. 27.) Korm. rendelet`
   - NJT: `https://njt.hu/jogszabaly/2001-297-20-22`
   - Kulcspont: kameras megfigyeleshez is kapcsolodo penzvaltoi kornyezet, bizonylati es telephelyi szabalyok

### Hivatalos/felugyeleti gyakorlati forrasok

6. `NAIH elvek es hatarozati gyakorlat`
   - kulcselvek: celhoz kotottseg, adattakarekossag, megfelelo tajekoztatas, jogszeru jogalap

### Cegspecifikus publikus forras

7. `Exclusive Best Change Zrt. Adatkezelesi Tajekoztato`
   - publikus PDF: `https://www.excbestchange.hu/legal/exc_best_change_adatkezelesi_tajekoztato.pdf`
   - kulcspont: szerepkorok, adatfeldolgozok, retention, kamera, VIP, hirlevel, DPO, partner-atadas

---

## S2 GDPR ALAPELVEK, AMELYEKET A PROGRAMBAN MODELLLE KELL TENNI

### 1. Kotelezo alapelvek

A GDPR es a ceg publikus tajekoztatoja alapjan a rendszernek biztositania kell:

- `jogszeruseg, tisztesseg, atlathatosag`
- `celhoz kotottseg`
- `adattakarekossag`
- `pontossag`
- `korlatozott tarolhatosag`
- `integritas es bizalmas jelleg`
- `elszamoltathatosag`

### 2. Privacy by design / by default

A ceg tajekoztatoja kifejezetten hivatkozik a `privacy-by-design` elvre.

Ebből kovetkezik:

1. a szemelyes adat mezok nem lehetnek altalanos, szabadon bovitheto dump-mezok;
2. minden adatmezohöz kell `purpose`, `legal_basis`, `retention_rule`, `access_scope`;
3. a UI-ban csak a tranzakciohoz szukseges mezok jelenhetnek meg az adott kontextusban;
4. a naplozasnak es jogosultsagkezelesnek bizonyithatonak kell lennie.

---

## S3 JOGALAP-RETEG A PENZVALTO PROGRAMBAN

### 1. Jogi kotelezettseg (`GDPR 6(1)(c)`)

Ez a fo jogalap a penzvalto program kritikus reszeiben:

- AML/KYC ugyfel-atvilagitas
- tenyleges tulajdonos azonositas
- penzeszkoz/vagyon forrasa
- szokatlan ugyletek monitorozasa
- szankcios szures
- kotelezo kameras megfigyeles
- bizonyos bizonylati es adomegorzes

### 2. Szerzodes teljesitese (`GDPR 6(1)(b)`)

Erre epithetok:

- ugyfelkapcsolati adatok az ugylet teljesitesehez
- visszaigazolasok, szolgaltatasi kapcsolattartas
- elorendeles / ajanlatfeldolgozas bizonyos reszei

### 3. Hozzajarulas (`GDPR 6(1)(a)`)

Ezt kulon kell kezelni az olyan folyamatoknal, mint:

- hirlevel
- marketingertesites
- VIP / kedvezmenyprogram
- opcionális kommunikacios csatornak

### 4. Jogos erdek

A ceg tajekoztatoja szerint a biztonsagi mentesek adatkezelese jogos erdekre tamaszkodik.

Programkovetelmeny:

- a backup-rendszer nem lehet ugyanaz a retention-logika, mint a tranzakcios fo adatbazise;
- dokumentalt `backup retention = max 5 ev` politika kell, ha a ceg ezt koveti.

---

## S4 CEGES SZEREPKOR-MODELL ADATVEDELMI SZEMPONTBOL

Az Exclusive Best Change publikus adatkezelesi tajekoztatoja kulcsfontossagu, mert nem egyetlen szerepkort ir le.

### 1. A tarsasag mint `adatfeldolgozo`

A tajekoztato szerint a tarsasag:

- penzvaltasi tevekenysegben a `Raiffeisen Bank Zrt.` kiemelt kozvetitojekent adatfeldolgozoi szerepben jar el;
- keszpenzatutalasi szolgaltatasnal `Exclusive Cash Kft.` / `Western Union` adatfeldolgozoi lanc resze;
- egyes egyeb szolgaltatasoknal partneri adatfeldolgozoi szerepben mukodik.

### 2. A tarsasag mint `adatkezelo`

Ugyanakkor a tajekoztato szerint a tarsasag a `Pmt.` szerinti atvilagitasi kotelezettsegek teljesitesekor adatkezelokent is eljar.

Ez rendszerszinten azt jelenti, hogy:

1. egyetlen rekordhoz tobb szerepkori cimke kellhet (`controller`, `processor`, `sub-processor-context`);
2. az adattovabbitasi logika nem lehet implicit;
3. ugyanazon ugyletben kulon kell kezelni a `bank/onallo adatkezelo` es a `tarsasag sajat AML adatkezelo` szerepet.

### 3. DPO

A publikus tajekoztato szerint:

- adatvedelmi tisztviselo: `Dávid Judit`
- e-mail: `adatvedelem@exclusive.hu`

Programkovetelmeny:

- legyen centralis `privacy contact / DPO contact` konfiguracio;
- legyen erintetti kerelem workflow tulajdonos.

---

## S5 RETENTION SZABALYOK

### 1. AML/KYC retention

A tajekoztato es a `Pmt.` alapjan:

- alap AML/KYC retention: `8 ev`
- hatosagi megkereses eseten: legfeljebb `10 ev`

### 2. Kamera retention

A tajekoztato szerint:

- a penzvalto helyisegekben kameras megfigyeles mukodik,
- a felveteleket `50 napig` orzik.

Ez fontos, mert a repo legacy anyaga is tobb helyen utal kameras integraciora.

### 3. Backup retention

A tajekoztato szerint:

- napi biztonsagi mentes keszul,
- a mentesek tarolasi ideje `legfeljebb 5 ev`.

### 4. Marketing / VIP retention

A publikus tajekoztato szerint:

- VIP/kedvezmeny program: a hozzajarulas visszavonasaig vagy a program lezarasaig,
- hirlevel/ertesites: a hozzajarulas visszavonasaig vagy a szolgaltatas lezarasaig.

### 5. Megjegyzes a 7 napos reszszabalyrol

A tajekoztato egyik AML-hez kapcsolodo resze penzvaltas eseten `7 napos` idotartamot is jelez egy szukebb, osszefuggo-ugylet-ellenorzesi adatkorre.

Ez nem azonos a teljes AML retentionnel.

Kovetelmeny:

- a programban kulon kell kezelni a `short-window linkage data` es a `long-retention AML dossier` reteget.

---

## S6 ERINTETTI JOGOK ES KORLATAIK

### 1. Kezelt jogok

A ceg tajekoztatoja szerint a rendszernek kezelnie kell:

- hozzaferesi jog
- helyesbites
- torles
- korlatozas
- adathordozhatosag
- tiltakozas
- panasztetel
- jogorvoslat

### 2. Fontos gyakorlati korlat

AML/KYC es kotelezo adatkezeles eseten a `torleshez valo jog` nem ervenyesul szabadon, ha a megorzes torvenyi kotelezettseg.

Rendszerkovetelmeny:

- a privacy request engine-nek tudnia kell `delete denied due to legal retention`;
- az ugyintezoknek szabvanyos, indokolt valaszsablont kell adni;
- torles helyett sokszor `restricted processing / archived legal hold` allapot kell.

### 3. Tajekoztatasi kovetelmeny

Az `Infotv.` es a GDPR alapjan az erintettet vilagosan tajekoztatni kell:

- az adatkezeles celjarol
- jogalapjarol
- idotartamarol
- cimzettekrol
- jogorvoslati lehetosegekrol

Ez a programban:

- onboarding text,
- privacy notice linkek,
- branch-level signage,
- and request-response audit trail

formaiban kell megjelenjen.

---

## S7 CEGES PUBLIKUS TAJEKOZTATO ALAPJAN KIFOLYONDO KONKRET PROGRAMKOVETELMENYEK

1. `Controller/processor split` mezoszintu es folyamat-szintu modellje kotelezo.
2. `Pmt-based legal hold` kulon statuszkent kell, nem torleskent.
3. `CCTV retention = 50 nap` kulon media retention policy kell.
4. `Newsletter/VIP consent` kulon hozzajarulasi objektumkent kezelendo.
5. `Processor register` kell a Raiffeisen, Western Union, Exclusive Cash, INNOVA-INVEST, Kupon Portfolió es egyeb partnerekhez.
6. `DPO contact + privacy request workflow` be kell epiteni.
7. `Access log` es `who saw what` audit trail kotelezo az erzekeny ugyfeladatokra.
8. `Short-window linked-transaction analysis` es `long-term AML archive` kulon adattarolasi szabalyra keruljon.

---

## S8 NYITOTT PRIVACY GAP-EK

| Gap ID | Kerdes | Statusz |
|--------|--------|---------|
| `GDPR-GAP-01` | A repo jelenlegi customer/transaction modelleiben kulon szerepkent megjelenik-e a controller vs processor kontextus? | nyitott |
| `GDPR-GAP-02` | A kamerarendszer retentionje es a camera modul technikai retentionje megfelel-e a 50 napos publikus szabalyzatnak? | nyitott |
| `GDPR-GAP-03` | A privacy request workflow es annak SLA-i jelenleg vannak-e barmely admin feluleten? | nyitott |
| `GDPR-GAP-04` | A VIP/hirlevel consent adat a jelenlegi repo-ban kulon, auditolhato hozzajarulasi rekordkent tarolodik-e? | nyitott |

---

## S9 RENDSZER-TERVEZESI IRANYELVEK

### Kotelezo adatobjektumok

- `privacy_notice_version`
- `processing_role_context`
- `legal_basis`
- `retention_policy_id`
- `consent_record`
- `access_audit_event`
- `data_export_request`
- `data_erasure_request`
- `legal_hold_reason`

### Kotelezo tiltott mintak

- ne legyen globális `customer_notes` mezoben szabalyozatlan szemelyes adatdump;
- ne legyen marketing consent es AML retention ugyanabban a mezoben;
- ne lehessen manualisan, audit nelkul szemelyes adatot torolni;
- ne lehessen kamera/okmanymasolat retentiont altalanos file cleanup taskkal kezelni.
