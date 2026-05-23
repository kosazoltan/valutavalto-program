# Anti-Legacy — TELJES forrás-lefedettség (minden .dpr modulnak van MD-je)

> Készült: 2026-05-23. **A user jogos bizalmatlansága nyomán** (az ARFOLYAM „nincs forrás"
> téves állítás után) a teljes `Anti/` fát szisztematikusan átfésültük MINDEN Delphi-forrásért.
> **Eredmény: minden forrás-modulnak (.dpr) van mély utasítás-MD-je — 0 kimaradt.**

## Korábbi TÉVES „nincs forrás" állítások — mind cáfolva (a forrás megvolt)
| Modul/alrendszer | Téves állítás volt | A VALÓDI forrás helye |
|---|---|---|
| **ARFOLYAM** | „nincs forrás, csak bináris-RE" | `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22` (Arfolyam.dpr + Unit1..16.pas) |
| **KESZLEX** | „csak bináris/adat, nincs .pas" | `Anti/SZERVER/_extracted/SZERVER/fejleszt/makeszlt/keszlex.dpr` (MAKESZLT.md) |
| **ERTEKTAR** | „nincs .pas (1 fájl)" | `Anti/SZERVER/_extracted/ERTEKTAR/etdll` (56 modul) |
| **SZERVER** | „mind duplikátum, nincs egyedi forrás" | `_extracted/SZERVER/{ujdll(36), fejleszt(174)}` |
| **VALUTA stubok** (ADATLAP, AFATABLA, ARFDISP, ARFREG, ARFTMK) | a `Anti/VALUTA/DLL`-ben 0-bájtos stub | a VALÓDI forrás `_extracted/VALUTA/DLL`-ben (20–97 KB .pas) |
| **IBVALTO** (fő pénztár-kliens) | nem volt feldolgozva | `Anti/VALUTA/IBVALTO/IBVALTO.DPR` (+ Unit1..18) |

**Tanulság (megőrzendő):** SOHA ne állítsd, hogy „nincs forrás" egyetlen mappa (pl. a deploy-mappa)
alapján — a forrás máshol (`_extracted`, `fejleszt`, `verzio22`) lehet. A teljes fát kell átfésülni.

## Generált modul-MD-k (összesen 394)
| Mappa | Darab | Forrás-fa |
|---|---|---|
| `EXCMD/legacy/modules/` | 110 | `Anti/VALUTA/DLL` (109) + TRADE + 5 stub valódi forrása az `_extracted`-ből + IBVALTO |
| `EXCMD/legacy/modules-ertektar/` | 56 | `_extracted/ERTEKTAR/etdll` |
| `EXCMD/legacy/modules-szerver/` | 36 | `_extracted/SZERVER/ujdll` |
| `EXCMD/legacy/modules-szerver-fejleszt/` | 174 | `_extracted/SZERVER/fejleszt` (top-level + beágyazott sub-modulok: helga/dllek, ugyfelcontrol/dll, terror, idprosct/UJCTRL stb.) |
| `EXCMD/legacy/modules-arfolyam/` | 17 | `fejleszt/arfolyam/verzio22` (16 form + index) |

## Lefedettség-bizonyíték (auditálható)
```
# minden forrás .dpr-név (a teljes Anti-fa, project1 nélkül):
find Anti -iname '*.dpr' | sed 's#.*/##;s#\.dpr$##' | grep -vi project1 | tr a-z A-Z | sort -u
# minden generált MD-név:
ls EXCMD/legacy/modules*/*.md | sed 's#.*/##;s#.md$##;s#^T##' | tr a-z A-Z | sort -u
# diff → egyetlen maradék: AFATAB (= AfaTab.dpr fájlnév az AFATABLA modulhoz → AFATABLA.md fedi)
```
**Minden más forrás-modulnak van MD-je. A maradék `AFATAB` az `AFATABLA` DLL fájlneve (alias), nem külön modul.**

## Generátorok (újrafuttatható)
- `scripts/legacy-module-md-generator.py` — VALUTA/DLL
- `scripts/legacy-ertektar-md-generator.py` — generikus (ROOT OUT SUBSYS): ERTEKTAR, SZERVER ujdll, fejleszt
- `scripts/legacy-arfolyam-md-generator.py` — ARFOLYAM verzio22 form-unitok
- `scripts/legacy-deep-md-generator.py` — beágyazott sub-modulok (helga/dllek, ugyfelcontrol/dll stb.)
- `scripts/legacy-valuta-stub-regen.py` — az 5 VALUTA-stub valódi forrása + IBVALTO

## Verifikáció a jelenlegi program ellen
A VALUTA + ERTEKTAR + SZERVER üzleti logika érdemi lefedettsége korábban verifikálva (10 ügynök).
A `fejleszt` (174) sok dev-verziót/duplikátumot is tartalmaz a már verifikált modulokról; az
ÚJ egyedi modulok (pl. MONEGRAM=MoneyGram, JOGISZEMELY, STATISZT, WWW, POSTTERM, POLICE) a
következő körben a tényleges kód ellen verifikálandók (file:line), és csak a VALÓS hiány implementálandó.
