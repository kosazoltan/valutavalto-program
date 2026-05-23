# 2026-05-23 — N9 értéktári átértékelés-lecsorgatás + v2.26.29 tesztelő-build

## N9 — értéktári átértékelés lecsorgatása a pénztárakra (PR #811)
User-kérdésből nőtt ki: az értéktár puffer (NEM haszoncenter); a pénztár+terület a
haszoncenter. A pufferkészlet nem-realizált átértékelését (heldQty × (MNB − WAC)) valutánként
lecsorgatjuk a terület pénztáraira a **lehívott mennyiség × pénztári átlag-árrés** súly szerint.

- `RevaluationAllocator` (tiszta, függőség-mentes): legnagyobb-maradék kerekítés → `Σalloc == REVAL`
  bit-pontosan. `RevaluationAllocationService`: vault `CurrencyStock(VAULT,territoryId)` + MNB +
  `ProfitLog`(árrés) + `Transfer`(lehívás). Reconciliation: `terület MNB = Σ(pénztár tiszta WAC) +
  Σ(allokált átértékelés)` bit-pontosan (self-review P1 fix: egész-Ft REVAL + totál a kiosztottból).
- `/api/v1/reports/territory-reconciliation` + `TerritoryReconciliationPage` + **központi modul-kártya**
  (CentralWorkstationPage „Eredmény és területi haszon" csoport).
- 7 teszt. Számpélda: A(60000×5)=357143, B(40000×3)=142857, terület=920000.

## Teljes legacy-státusz
394 modul-MD, mind verifikálva. 7 valódi gap implementálva (G27,N1,N2,N3,N4,N6,N7,N9).
0 fennmaradó implementálható gap. (Lásd 05/06 EXCMD doc.)

## v2.26.29 tesztelő-build (user-kérés: hétvégi kollégák)
A v2.26.26–29 server-served (Hetzner auto-deploy), de a user a desktop-nézegetéshez kérte a
teljes 4-way telepítőt. Legyártva (UNSIGNED), Downloads-ba másolva:
- Penztar-Setup-2.26.29-20260523.exe — 283.84 MB — F9343A6F49E2E788A7A7537C6E21AEC80AC657CBBC82EBD288429393FE25E2DC
- Kozponti-Iranyitokozpont-Setup-2.26.29.exe — 101.06 MB — CDF25BF1FD8F006D3752973723786CE6DC87CB1A5677E7A3317F91940ED5CF72
- Arfolyamkeszito-Setup-2.26.29.exe — 101.06 MB — 44D939119EBA57AC03E865090E24A81E050B04D26C9188E066A3C5C4827B833F
- Penztar-Eltavolito-2.26.23-20260522.exe — verzió-független — 5D84BE6AA024D9543B5B13F9E846255A6E05F700D8AE4750007E97539B5BDFB4

## TANULSÁG (build): a >200 MB full-size küszöb TÚL KORÁN sül el
Az LZMA „compress whole" inkrementálisan ír; a Penztar fájl ~218 MB-nál még NEM kész (vég ~283 MB).
Ha a >200 MB küszöbre számolunk SHA-t, RÉSZLEGES fájlt hashelünk. Helyes: a build-task tényleges
befejezésére (exit 0) várni VAGY méret-stabilitást ellenőrizni (kétszeri stat egyezés), és csak
utána SHA. Ezt most elkaptam és újraszámoltam a kész 283.84 MB fájlon.
