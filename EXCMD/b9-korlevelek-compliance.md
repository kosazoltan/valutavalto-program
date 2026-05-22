# Modul: Korlevelek mint compliance/AML kovetelmeny  (forras: Felmérés/Valuta/Kósa Tervezés és fejlesztés/Segédanyagok Valuta/{7 sz Körlevél esetleges bankkártyás csalásokról.odt, 9 sz Körlevél a FATF többszintű listájának változásáról 2024 02 hó.odt})

## 1. Cel
Ket belso korlevel (7. sz. bankkartyas csalas-figyelmeztetes; 9. sz. FATF tobbszintu lista-valtozas) tartalmat AML/compliance funkcionalis kovetelmenykent rogziteni, beleertve a korlevel-kezelest (kiadas, elolvasas-visszaigazolas szereponkent) es a benne foglalt szakmai szabalyokat.

## 2. Scope
### IN
- 7. sz. korlevel ("32 sz Korlevel esetleges bankkartyas csalasokrol", iktato: FZS-35/2023, hatalyos 2024.02.09., keszitette: Fabulya Zsuzsanna, Bekescsaba):
  - Figyelmeztetes: gondatlan ugyfelek hamis webes oldalakon megadtak banki belepo kodjaikat -> csalok atutaltak az osszegeket; strofuman-szamlakrol felvettek vagy bankkartyas vasarlassal elkoltottek.
  - Elofordul, hogy bankkartyaval valutat valtanak akar tobb alkalommal, tobb penztarban is.
  - Gyanu eseten: telefonon jelezni a teruleti vezeto/keszito fele, megbeszelni hogy a tranzakcio elvegezheto-e, es a tovabbi teendot.
  - Gyanus ismertetojegyek: naponta tobbszor jon valtani es bankkartyaval fizet; nem tudja fejbol, csak papirrol a PIN-kodjat; telefonrol (uzenetbol) nezi mennyi valutat kell valtania.
  - Szereponkenti teendo: Teruleti Vezeto elolvassa; Belso ellenorzes ellenorzeskor meggyozodik a betartasrol/ismeretrol; Penztaros/Ertektaros elolvassa, ertelmezi, betartja.
- 9. sz. korlevel ("Korlevel a FATF tobbszintu listajanak valtozasarol javitott", iktato: FZS-9/2024, hatalyos 2024.02.27., keszitette: Fabulya Zsuzsanna, Bekescsaba):
  - A Penzmosasi szabalyzat alapjan a FATF tobbszintu listat alkot a penzmosas/terrorizmus-finanszirozas szempontjabol kockazatos orszagokrol; "public statement"-ekkel modositja.
  - 1/a Csoport (ellenintezkedesekkel erintett): Eszak-Korea, Iran.
  - 1/b Csoport (kockazatokkal aranyos atvilagitas szukseges): Myanmar.
  - 2. Csoport (intezmenyrendszer fejlesztese/vizsgalata folyamatban): Bulgaria, Burkina Faso, Del-Afrika, Del-Szudan, Fulop-Szigetek, Haiti, Horvatorszag, Jamaica, Jemen, Kamerun, Kenya, Kongoi Demokratikus Koztarsasag, Mali, Mozambik, Namibia, Nigeria, Szenegal, Szirja, Tanzania, Torokorszag, Vietnam.
  - Kikerult a 2. csoportbol (uj public statement): Barbados, Gibraltar, Uganda, Egyesult Arab Emirsegek.
  - Szereponkenti teendo: Teruleti vezeto elolvassa/ertelmezi + ellenorzeskor figyelemmel koveti a betartast; Penztarosok elolvassak, az abban leirtaknak megfeleloen jarnak el, betartjak; Belso ellenorok ellenorzeskor figyelemmel kovetik.

### OUT
- A teljes Penzmosasi (Pmt.) szabalyzat (a 9. sz. csak hivatkozik ra).
- Aktualis FATF lista karbantartasanak automatizalt forrasa (a korlevel egy adott 2024.02-i pillanatkep).
- A bankkartyas fizetes technikai tiltasa/limitalasa (a korlevel emberi mertegelest ir elo, nem automatikus blokkot).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Penztaros / Ertektaros | Korlevel elolvasasa + visszaigazolas; gyanu jelzese | TBD |
| Teruleti vezeto | Korlevel elolvasas/ertelmezes; betartas figyelemmel kovetese | TBD |
| Belso ellenor | Ellenorzeskor a betartas/ismeret meggyozodese | TBD |
| Compliance/keszito (pl. Fabulya Zsuzsanna szerepkor) | Korlevel kiadasa, gyanu-jelzes fogadasa telefonon | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-01 | A rendszer kezeli a belso korleveleket metaadatokkal: iktatoszam, targy, keszito, hatalyos datum. | 7. sz. + 9. sz. korlevel fejlec | M | backend, frontend |
| FR-02 | Korlevel szereponkenti "elolvasta/visszaigazolta" nyilvantartas (Penztaros/Ertektaros, Teruleti vezeto, Belso ellenor). | mindket korlevel "teendo" zaroresz | M | backend, frontend |
| FR-03 | Bankkartyas-csalas figyelmeztetes: a penztaros gyanu eseten KEPES jelezni (telefonos eszkalacio a vezeto fele) es a tranzakciot felfuggeszteni dontesig. | 7. sz. korlevel | M | backend, frontend (penztar-client) |
| FR-04 | Gyanu-jelek tamogatasa az ugyfel/tranzakcio ertekelesehez: bankkartyas valutavaltas tobb alkalommal/tobb penztarban; ismetlodő napi valtas + bankkartyas fizetes; PIN papirrol; valtando osszeg telefonos uzenetbol. | 7. sz. korlevel | M | backend, frontend (penztar-client) |
| FR-05 | A FATF tobbszintu lista 3 szinten tarolhato: 1/a (ellenintezkedes), 1/b (fokozott atvilagitas), 2. csoport (monitorozott). | 9. sz. korlevel | M | backend |
| FR-06 | A FATF lista valtoztathato (orszag felvetel/kikerules) public statement alapjan, valtozas-koveteshez verzio/datum metaadattal (pl. hatalyos 2024.02.27). | 9. sz. korlevel | M | backend, frontend |
| FR-07 | A 9. sz. korlevel szerinti kezdo allapot betoltheto: 1/a={Eszak-Korea, Iran}, 1/b={Myanmar}, 2={21 felsorolt orszag}, kikerult={Barbados, Gibraltar, Uganda, Egyesult Arab Emirsegek}. | 9. sz. korlevel | M | backend |
| FR-08 | Ugyfel allampolgarsag/orszag ellenorzese a FATF lista ellen tranzakciokor; talalat eseten a szintnek megfelelo intezkedes (1/a tiltas/ellenintezkedes, 1/b fokozott atvilagitas, 2. fokozott figyelem). | 9. sz. korlevel (szerep-teendok) | M | backend, frontend (penztar-client) |
| FR-09 | Korlevel-tar/megjelenites a kliensben (penztaros elolvashatja a hatalyos korleveleket). | mindket korlevel | S | frontend (penztar-client) |
| FR-10 | A korlevel kotelezo elolvasasanak naplozasa (ki, mikor igazolta) auditcelra. | szerep-teendok ("elolvassa, betartja") | S | backend |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-01 | A FATF lista-ellenorzes a tranzakcio elott lefut (nem utolagosan). | Ellenorzes belep a tranzakcio-flow-ba mentes elott |
| NFR-02 | A korlevel-elolvasas visszaigazolas auditalhato (idobelyeg + dolgozo). | Naplobejegyzes letrejon, nem modosithato |
| NFR-03 | FATF lista valtozas datum-verziozott, visszakeresheto melyik idoszakban mi volt hatalyos. | Datum szerinti lekerdezes mukodik |

## 6. Adatmodell-erintettseg
- Postgres entitas(ok): TBD (forras dokumentumok; konkret tablanevek nincsenek). Fogalmi entitasok: korlevel (iktatoszam, targy, keszito, hatalyos datum, szoveg), korlevel-visszaigazolas (dolgozo, idobelyeg) 1:N, FATF-orszag-bejegyzes (orszag, csoport-szint, hatalyos-tol/ig).
- SQLite mirror: TBD — a FATF lista es a hatalyos korlevelek penztaros-oldali offline ellenorzeshez valoszinuleg kellenek, de a forras ezt nem mondja ki.
- Migracio szukseges: TBD (uj korlevel + FATF lista tabla eseten igen).

## 7. Fuggosegek
- Belso modul: AML/penzmosas-ellenorzes (Pmt. szabalyzat), tranzakcio-flow (vetel/eladas), audit-log.
- Kulso API: FATF lista hivatalos forrasa (a korlevel kezi public statement-re hivatkozik; automatikus API nincs nevesitve) -> TBD.
- Adatbazis: korlevel + visszaigazolas + FATF orszaglista.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Korlevel | Belso, iktatott compliance utasitas (pl. FZS-35/2023), szereponkenti teendokkel. |
| FATF tobbszintu lista | A FATF altal penzmosas/terrorfinanszirozas kockazat szerint csoportositott orszaglista. |
| 1/a csoport | Ellenintezkedesekkel erintett orszag (Eszak-Korea, Iran). |
| 1/b csoport | Kockazatokkal aranyos atvilagitasi igeny szukseges (Myanmar). |
| 2. csoport | AML/CTF intezmenyrendszer fejlesztese/vizsgalata folyamatban. |
| Public statement | A FATF nyilatkozata, amely alapjan a lista modosul (orszag fel/le). |
| Strofuman (struman) | Mas neveben szamlat nyito/tranzakciot vegzo szemely (csalas-kontextus). |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be mindket odt content.xml-jet (Python zipfile). A 9. sz. korlevel orszaglistait pontosan vedd at, az elgepelteket NE javitsd ertelmezessel (forrashű). A FATF lista idofuggo pillanatkep (2024.02.27).
### 9.2 Fazisok (acceptance criteria)
1. Korlevel-entitas + szereponkenti visszaigazolas (FR-01, FR-02, FR-10). AC: korlevel kiadhato metaadatokkal, dolgozo visszaigazolasa naplozodik.
2. Bankkartyas-csalas eszkalacio + gyanu-jelek (FR-03, FR-04). AC: penztaros felfuggesztheti a tranzakciot es jelezhet a vezetonek; a 4 gyanu-jel megjelenik figyelmeztetokent.
3. FATF lista 3 szintje + valtozas-koveteses betoltes (FR-05, FR-06, FR-07). AC: a 9. sz. korlevel kezdo allapota visszatoltheto datum-verzioval.
4. Tranzakcio elotti FATF-ellenorzes (FR-08) + korlevel-tar megjelenites (FR-09). AC: 1/a talalat tiltast/ellenintezkedest, 1/b fokozott atvilagitast, 2. fokozott figyelmet valt ki.
### 9.3 Tesztek
- Unit: FATF orszag->szint lekepezes; gyanu-jel ertekeles; korlevel-metaadat validacio.
- Integracios: FATF lista verziozott valtozas (orszag fel/le), korlevel-visszaigazolas naplozas.
- E2E/runtime: tranzakcio FATF-erintett orszag allampolgarral -> szintnek megfelelo akadaly; bankkartyas-gyanu eszkalacio happy path.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A FATF lista frissitese kezi (uj korlevel) vagy automatikus (kulso forras)? | Lista naprakeszseg. | A korlevel kezi public statement-et emlit -> forrasdontes TBD. |
| 2 | Az 1/a, 1/b, 2. szintekhez pontosan milyen rendszer-intezkedes tartozik (tiltas vs fokozott atvilagitas)? | FR-08 viselkedese. | A korlevel csak a csoport-besorolast adja, a konkret akciot a Pmt. szabalyzat -> TBD. |
| 3 | Mely orszag-mezo (allampolgarsag, szuletesi orszag, lakcim orszag) ellenorzendo a lista ellen? | Ellenorzes pontossaga. | A korlevel nem nevesiti -> TBD. |
| 4 | Kotelezo-e a korlevel elolvasasa minden szerepkornek belepeskor (blokkolo)? | Compliance-kikenyszerites. | A korlevel "elolvassa/betartja"-t ir, de blokkolast nem -> TBD. |
| 5 | A bankkartyas-csalas gyanu eszkalacio csatornaja (telefon vs rendszer-uzenet)? | FR-03 megvalositas. | A 7. sz. korlevel telefont ir; rendszer-tamogatas TBD. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak a korlevelek szovege)
- [x] minden TBD jelölt
VERIFIKACIO: FR=10 db, TBD=5 db, érintett csomag(ok)=backend, frontend-react, penztar-client (AML/Pmt.); Postgres (SQLite mirror TBD)
