# Modul: Beallitasok (jelszoval vedett konfiguracios kepernyok)  (forrás: Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/Képernyőképek/Beállítások menü külön jelszóval.jpeg + Beállítások külön jelszóval_ Alapfunkciók.jpeg + Beállítások csak jelszóval_ alapfunkció.jpeg + Beállítások külön jelszóval_ Alkalmazások .jpeg + Beállítások külön jelszóval_ Árfolyam kijelző beállításai.jpeg + Beállítások külön jelszóval_ IP cím beállítás.jpeg + Beállítások külön jelszóval_ Jelszó beállítások napi jelentéshez.jpg + Beállítások külön jelszóval_ adatok beküldése a szerverre.jpeg + Beállítások külön jelszóval_ nyomtató beállítás.jpeg + Beállítások külön jelszóval_ szkenner beállítás.jpeg + Beállítások csak jelszóval_ Kezelési költség számítások.jpeg + Beállítások csak jelszóval_ futófény beállítások.jpeg + Beállítások külön jelszóval_ Bankkártyás fizetések.jpeg)

## 1. Cel (egy mondat)
A regi penztaros program "Beallitasok" (jelszoval vedett) konfiguracios kepernyoinek hu leirasa: bal oldali TEMAK fulista, jobb oldali BEALLITASOK panel, alul Rogzites es kilepes / Kilepes modositas nelkul / Vissza a menure gombsor.

## 2. Scope
### IN
- Beallitas-menu kerete: bal "TEMAK" fullista (12 ful), jobb "BEALLITASOK" tartalom-panel, also gombsor (3 gomb).
- 12 beallitas-ful: Alapfunkcio, Alkalmazasok, IP-cim beallitasa, Jelszo beallitas (napi jelentes), Kijelzes szine (arfolyam-kijelzo szine), Futofeny, Keszletek bekuldese (adatok bekuldese a szerverre), Kezelesi koltseg szamitasa, Bankkartya fizetes, Nyomtato, Reklam a kijelzon, Scanner beallitasa.
- A kepernyo-csoport "kulon jelszoval" es "csak jelszoval" valtozatban is megjelenik (azonos tartalom).
### OUT
- A jelszoval-bekeres parbeszedablak konkret kinezete (a forrasban nem szerepel kep) -> TBD.
- A "Reklam a kijelzon" ful: csak a fejlec-kepen lathato (REKLAMOK A KIJELZON: Nincs reklam / Van reklam radiogomb) — kulon screenshot nincs, reszletes mezok TBD.
- A "Szoveg szerkesztese" (futofeny szoveg) szerkesztofelulet — nincs kepe -> TBD.
- A jelenlegi (uj) ERP-hez valo hasonlitas (kesobbi fazis).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Penztaros | A beallitas-menu jelszoval vedett; a forras "kulon/csak jelszoval" cimkezi — pontos szerep-megfeleltetes nem lathato | TBD |
| Ertektaros / Foertektaros / admin | Konfiguracios hozzaferes feltetelezheto, de a kepen nem azonositott | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-01 | Beallitas-keret: bal "TEMAK" fullista (12 ful), jobb "BEALLITASOK" tartalom-panel; also gombsor: "ROGZITES ES KILEPES", "KILEPES MODOSITAS NELKUL", "VISSZA A MENURE". | menü külön jelszóval.jpeg | M | penztar-client |
| FR-02 | ALAPFUNKCIO ful: 3 egymast kizaro radiogomb a gep szerepehez — "PENZTARI GEP" (alapertelmezetten kivalasztva a kepen), "ERTEKTARI GEP", "AFAS GEP". | Alapfunkciók.jpeg / csak jelszóval_ alapfunkció.jpeg | M | penztar-client |
| FR-03 | ALKALMAZASOK ful: tobbszoros valasztasu (checkbox) lista — "VALUTAVALTAS" (a kepen bepipalva), "WESTERN UNION", "TESCO AFA", "METRO AFA", "E-KERESKEDELEM". | Alkalmazások .jpeg | S | penztar-client |
| FR-04 | KIJELZES SZINE ful ("AZ ARFOLYAM KIJELZO SZINE"): 3 radiogomb — "ZOLD", "SARGA", "PIROS" (a kepen PIROS kivalasztva); a panelen elo elonezet az arfolyam-kijelzo tablazatrol (VETEL/ELADAS oszlop a valasztott szinnel). | Árfolyam kijelző beállításai.jpeg | S | penztar-client |
| FR-05 | IP-CIM BEALLITASA ful ("A SZERVER ELERES IP-CIME"): 4 kulon oktett-beviteli mezo (a kepen <IP_OKTETT_1> / <IP_OKTETT_2> / <IP_OKTETT_3> / <IP_OKTETT_4>); gombok: "IP-CIM RENDBEN", "MEGSEM". | IP cím beállítás.jpeg | M | penztar-client |
| FR-06 | JELSZO BEALLITAS ful ("NAPI JELENTES JELSZAVA"): jelenlegi jelszo kijelzese (a kepen "<JELSZO>") + "JELSZO MODOSITAS" gomb; "AZ ERTEKTAR E-MAIL CIME" szovegmezo (a kepen <EMAIL>); "SZOMBATI NYITVATARTAS" radio: "SZOMBATON NYITVA" / "SZOMBATON ZARVA" (a kepen ZARVA). | Jelszó beállítások napi jelentéshez.jpg | M | penztar-client |
| FR-07 | KESZLETEK BEKULDESE ful ("ADATOK BEKULDESE A SZERVERRE"): "Adatok bekuldesenek gyakorisaga: N percenkent" — csuszka 0–25 skalan (a kepen 2 perc). | adatok beküldése a szerverre.jpeg | M | penztar-client |
| FR-08 | NYOMTATO ful ("NYOMTATO TIPUSA"): 2 radiogomb — "LPT1 PORTRA CSATLAKOZTATVA" (a kepen kivalasztva), "USB PORTRA CSATLAKOZTATVA". | nyomtató beállítás.jpeg | S | penztar-client |
| FR-09 | SCANNER BEALLITASA ful ("A SCANNER BEALLITASA"): "Az alkalmazott driver:" radio-lista a rendszeren elerheto szkenner-driverekrol (a kepen: "CanoScan Lide 120", "WIA-CanoScan Lide 120" — utobbi kivalasztva). | szkenner beállítás.jpeg | S | penztar-client |
| FR-10 | KEZELESI KOLTSEG ful ("KEZELESI KOLTSEG SZAMITASA"): 3 radiogomb — "NINCS KEZELESI KOLTSEG", "EZRELEKES KEZELESI KOLTSEG" (a kepen kivalasztva), "SAVOS KEZELESI KOLTSEG"; alul parameter-panel a valasztott modhoz (a kepen "EZRELEKES KEZELESI KOLTSEG: 3 ezrelek Max: 9990 Ft") + "MODOSITAS" gomb. | Kezelési költség számítások.jpeg | M | penztar-client |
| FR-11 | FUTOFENY ful ("FUTOFENY BEALLITASA"): kijelzett parameterek "Hany futofenytabla van: N" (kepen 2), "Elso futofenytabla comportja: N" (kepen 1), "Masodik futofenytabla comportja: N" (kepen 2); megjelenites-radio: "CSAK ARFOLYAMKIJELZES" (kepen kivalasztva), "CSAK SZOVEG KIJELZESE" (+ "Szoveg szerkesztese" gomb), "VALTAKOZO KIJELZES (Nappal szoveg/Ejjel arfolyam)"; "FUTOFENY KIKAPCSOLASA" gomb; "Futofeny sebessege" csuszka LASSU–GYORS kozott. | futófény beállítások.jpeg | S | penztar-client |
| FR-12 | BANKKARTYA FIZETES ful ("FIZETES BANKKARTYAVAL"): 2 radiogomb — "NINCS ENGEDELYEZVE" (a kepen kivalasztva), "ENGEDELYEZVE"; "ADATOK RENDBEN" gomb. | Bankkártyás fizetések.jpeg | S | penztar-client |
| FR-13 | REKLAM A KIJELZON ful: "REKLAMOK A KIJELZON" radio — "NINCS REKLAM A KIJELZON" (a fejlec-kepen kivalasztva), "VAN REKLAM A KIJELZON". Tovabbi mezok nem lathatok (nincs kulon screenshot). | menü külön jelszóval.jpeg | C | penztar-client |
| FR-14 | A keret also gombsorja minden fulnel azonos: "ROGZITES ES KILEPES" (mentes), "KILEPES MODOSITAS NELKUL" (eldobas), "VISSZA A MENURE" (visszalepes). | minden screenshot | M | penztar-client |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-01 | A teljes Beallitasok kepernyo-csoport jelszoval vedett ("kulon jelszoval" / "csak jelszoval" cimkek a forras-fajlnevekben). | A menu csak sikeres jelszo-megadas utan nyilik meg; ervenytelen jelszo eseten nincs hozzaferes. |
| NFR-02 | Letezik legalabb ket vedelmi mod: "kulon jelszoval" es "csak jelszoval" (a fajlnevek alapjan); a pontos kulonbseg a forrasbol nem allapithato meg. | TBD — a ket mod kozti elteres tisztazasa. |
| NFR-03 | A "napi jelentes jelszava" kulon, fultartalmon belul modosithato jelszo (FR-06), elkulonul a menu-belepteto jelszotol. | A "JELSZO MODOSITAS" gomb csak a napi-jelentes jelszot valtoztatja. |

## 6. Adatmodell-erintettseg
- A beallitasok jellemzoen gep-szintu / telephely-szintu konfiguracio (Postgres parameter-tabla, pl. SystemParameter jellegu kulcs-ertek, vagy branch-konfig). Konkret entitas/mezo a forrasbol nem azonosithato -> TBD.
- Erintett fogalmi mezok: gep-szerep (penztari/ertektari/afas), engedelyezett alkalmazasok (multi-select), szerver IP, adatkuldes-gyakorisag (perc), kijelzo-szin, napi-jelentes jelszo, ertektar e-mail, szombati nyitvatartas, kezelesi-koltseg mod + parameter, nyomtato-port, szkenner-driver, futofeny-konfig (tablaszam, comport-ok, mod, sebesseg), bankkartya-engedely, reklam-megjelenites.
- SQLite mirror: a penztaros kliens local-first, ezert a gep-szintu beallitasok lokalis perzisztencianak indokoltak (offline mukodes) — IGEN/NEM dontes a tervezesi fazisban -> TBD.
- Migracio szuksege: TBD (a celarchitektura entitasai a kovetkezo fazisban dolnek el).

## 7. Fuggosegek
- Belso modul: penztar-client beallitas/konfiguracio; futofeny-tabla soros (COM) port kezelo; szkenner-driver (WIA/TWAIN); nyomtato (LPT1/USB) kezelo; arfolyam-kijelzo (masodkijelzo) renderer.
- Kulso: szerver elerese a megadott IP-cimen (adatkuldes); szkenner-driver az operacios rendszerbol; bankkartya-terminal (ha "ENGEDELYEZVE") — protokoll a forrasbol nem lathato -> TBD.
- Adatbazis: szerver-oldali adatfogadas a "Keszletek bekuldese" gyakorisag szerint.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Alapfunkcio | A gep uzemmodja: penztari / ertektari / afas gep. |
| Futofeny | Kulso LED futofeny-tabla(k) soros (COM) porton, arfolyam vagy szoveg kijelzesere. |
| Comport | A futofenytabla(k) soros portja (kepen 1 es 2). |
| Kezelesi koltseg | Tranzakcios dij: nincs / ezrelekes (pl. 3 ezrelek, max 9990 Ft) / savos. |
| Napi jelentes jelszava | A napi zaras/jelentes funkciot vedo kulon jelszo (kepen "<JELSZO>"). |
| Keszletek bekuldese | Adatok periodikus felkuldese a szerverre (kepen 2 percenkent). |
| Kijelzes szine | A (masodik) arfolyam-kijelzo szinsemaja: zold/sarga/piros. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Forrasként a 13 screenshotot tekintsd hitelesnek; ami nem lathato → TBD, nem talalgatas.
- A "kulon jelszoval" / "csak jelszoval" valtozat tartalma azonos (csak hozzaferesi mod) — egy logikai kepernyo-csoport.
### 9.2 Fazisok (acceptance criteria-val)
- F1 — Keret + navigacio: 12- full ful-lista + tartalom-panel + 3 also gomb. AC: minden ful kivalaszthato, a panel a megfelelo tartalmat mutatja; "Kilepes modositas nelkul" eldobja a valtoztatasokat.
- F2 — Egyszeru valasztos fulek (FR-02, FR-04, FR-08, FR-10, FR-11, FR-12, FR-13): radio/checkbox allapot mentese es betoltese. AC: a kivalasztott ertek perzisztens "Rogzites es kilepes" utan.
- F3 — Strukturalt fulek (FR-05 IP 4-oktett, FR-06 jelszo+email+nyitvatartas, FR-07 csuszka, FR-09 driver-lista, FR-10 koltseg-parameter, FR-11 futofeny comport/sebesseg). AC: validalt bevitel (IP-oktett 0–255; gyakorisag a skala-tartomanyban); "JELSZO MODOSITAS" kulon dialogus.
- F4 — Jelszo-vedelem (NFR-01..03): a menu belepteto-jelszoval nyilik, a napi-jelentes jelszo kulon kezelve.
### 9.3 Tesztes
- Unit: ertek-perzisztencia fulenkent (mentes/eldobas), IP-oktett es gyakorisag-tartomany validacio.
- Integracio: "Rogzites es kilepes" utan ujranyitva a beallitasok visszatoltodnek; "Kilepes modositas nelkul" utan valtozatlanok.
- UI/smoke: ful-navigacio, jelszo-bekeres a menu elott.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | "kulon jelszoval" vs "csak jelszoval" pontos kulonbsege | Hozzaferes-modell helyessege | A ket vedelmi mod elterese / mikor melyik aktiv. |
| 2 | Mely szerepek erhetik el a beallitas-menut + a belepteto jelszo eredete | RBAC | Szerep–jelszo megfeleltetes (a kepen nem lathato). |
| 3 | "Reklam a kijelzon" ful tovabbi mezoi | Teljesseg | Kulon screenshot nincs; csak a Nincs/Van radio lathato. |
| 4 | "Szoveg szerkesztese" (futofeny) szerkeszto-felulet | FR-11 teljesseg | Nincs kepe. |
| 5 | "Savos kezelesi koltseg" parameter-panel tartalma | FR-10 teljesseg | Csak az "ezrelekes" panel lathato (3 ezrelek, max 9990 Ft). |
| 6 | Bankkartya "ENGEDELYEZVE" eseten megjeleno tovabbi mezok/terminal-protokoll | FR-12 teljesseg | A kepen csak a radio + "Adatok rendben" gomb. |
| 7 | Szerver-IP adatkuldes pontos protokollja/portja | FR-05/FR-07 | A kepen csak az IP-oktettek (<SZERVER_IP>) lathatok. |
| 8 | Az ertek-tarolas helye (gep-szintu vs telephely-szintu, lokalis SQLite vs szerver) | Adatmodell | Architekturalis dontes a kovetkezo fazisban. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak a kepeken lathato tartalom; minden hianyt TBD jelol)
- [x] minden TBD jelölt
VERIFIKACIO: FR=14 db, TBD=8 db, érintett csomag(ok)=penztar-client
