---
type: compliance-matrix
scope: repo-wide
version: 2026-04-09
format: matrix
description: "Law -> system requirement -> test case matrix for money exchange, AML, GDPR, rounding and company public rules"
---

# Law -> System Requirement -> Test Matrix

> Cel: a jogi/ceges baseline kozvetlen leforditasa implementalhato rendszerkovetelmenyekké es tesztelheto allitasokka.

| Matrix ID | Jogszabaly / forras | Kotelezettség | Rendszerkovetelmeny | Minimum teszteset |
|-----------|----------------------|---------------|---------------------|-------------------|
| `LSTM-01` | `Hpt.` | A penzvaltas kulon penzugyi tevekenyseg, beleertve a konverziot is | `buy`, `sell`, `conversion` kulon domain flow es receipt-tipus | `POST /transactions/conversion` kulon tranzakciotipust es receiptet hoz letre |
| `LSTM-02` | `297/2001. Korm. rendelet` | Arfolyamjegyzek kozzetetele es 5 eves megorzese | rate board verziozott entitas, archivummal | rate publish utan archivalt elozo verzio visszakeresheto |
| `LSTM-03` | `297/2001. Korm. rendelet` | Minden ugyletrol megfelelo bizonylat kell | buy/sell/conversion receipt template kulon kezelese | buy/sell/conversion mind mas receipt-tipust ad |
| `LSTM-04` | `Pmt. 21. §` | `300 000 Ft` felett teljes CDD penzvaltasnal | threshold AML gate a frontendben es backendben | `299999` alatt nem, `300000`-tol kotelezo teljes azonositas |
| `LSTM-05` | `Pmt. 21. § (3)` | Osszefuggo ugyletek aggregalasa | linked transaction detection | ket kulon ugylet egyuttesen atlepve a kuszobot blokkol vagy CDD-t ker |
| `LSTM-06` | `Pmt.` | Ha CDD nem vegezheto el, a szolgaltatas nem nyujthato | `cannot-complete-cdd -> refuse transaction` allapot | hianyos okmanynal a commit nem sikerul |
| `LSTM-07` | `Pmt. 56-58. §` | AML adatok 8 evig, egyes esetekben 10 evig orzendoek | retention engine legal-hold tamogatassal | rekord retention policy-ja `AML_8Y` vagy `AML_10Y_REQUEST` |
| `LSTM-08` | `Kit.` + MNB rendelet | Szankcios szures folyamatos es haladektalan legyen | kulon sanctions screening service es talalatkezeles | szankcios talalat blokkolja a tranzakciot es audit rekordot general |
| `LSTM-09` | `14/2025. MNB rendelet` | Szurorendszer tesztelese es dokumentalasa | configurable AML/sanctions rules engine + audit log | ruleset verziozas es alert decision log visszakeresheto |
| `LSTM-10` | `2008. evi III. torveny` | 5 Ft-os kerekites a keszpenzes vegosszegre | cash rounding csak payment finalization szinten | `102` -> `100`, `103` -> `105`, kartyanal nincs kotelezo kerekites |
| `LSTM-11` | `GDPR 5. cikk` | Celhoz kotottseg es adattakarekossag | mezoszintu purpose/legal-basis model | transaction UI nem ker marketing mezot AML-only flowban |
| `LSTM-12` | `GDPR 25. cikk` | privacy by design / by default | minimal default field set + role-based visibility | cashier nem lat irrelevans erzekeny mezoket |
| `LSTM-13` | `Infotv.` + GDPR | Erintetti tajekoztatas, hozzaferes, helyesbites | privacy request workflow | erintetti hozzaferesi kerelem exportot general hataridovel |
| `LSTM-14` | `Exclusive Best Change privacy PDF` | A tarsasag bizonyos flowkban adatfeldolgozo, masokban adatkezelo | processing-role context a recordokon | Raiffeisen-penzvaltas es sajat AML dossier kulon role-contexttel tarolodik |
| `LSTM-15` | `Exclusive Best Change privacy PDF` | Kamera retention `50 nap` | media retention policy kulon modulban | 50 napnal regebbi CCTV rekord purge listara kerul |
| `LSTM-16` | `Exclusive Best Change public page` | Egyedi arfolyam `100 000 Ft` felett, `2 ora` ervenyesseg | quote workflow with expiration | lejart egyedi arfolyamot a rendszer nem engedi felhasznalni |
| `LSTM-17` | `branch feed xlsx` | Telephelyenkent kulon service capability (`WU`, `MG`) | branch capability matrix | MG nelkuli fiokban MoneyGram nem foglalhato |
| `LSTM-18` | `Szamviteli tv. 60. §` | Devizas es valutás tetelek policy szerinti arfolyamon kerulnek be a konyvekbe | accounting FX source config (`bank_avg`, `MNB`, `ECB`) | accounting export a valasztott policy szerinti arfolyamot menti |
| `LSTM-19` | `Áfa tv.` + `Art.` | Bizonylatnak ellenorizheto adougyi alapnak kell lennie | receiptek/invoicek tax classification mezovel | fee line tax code nelkul nem publikálhato |
| `LSTM-20` | `297/2001` + `Art.` | Bizonylat es nyilvantartas ellenorizheto legyen | immutable receipt numbering + audit trail | receipt szam duplikacio tilos, modositas csak storno/ervenytelenites utjan |

---

## Megjegyzesek

- A `LSTM-18` es `LSTM-19` soroknal tovabbi adoszakertoi validacio ajanlott a vegleges tax engine elott.
- A matrix minimumteszteket tartalmaz; egyes sorokhoz kulon `unit + integration + UI + audit evidence` csomag indokolt.
