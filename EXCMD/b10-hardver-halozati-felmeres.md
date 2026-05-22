# Modul: Hardver- es halozati felmeres (telepites-tervezesi katalogus)  (forras: `Felmérés/Valuta/Hálózati és számítógép felmérés/`, `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Hálózati és számítógép felmérés/`)

## 1. Cel (egy mondat)
A telephelyenkenti PC-, periferia- es internet-felmeres dokumentumainak katalogizalasa deployment-tervezesi referenciakent — **NEM** programfunkcio-specifikacio.

## 2. Scope
### IN
- A felmert eszkozok lista-jellegu katalogizalasa (mely fajl mit ir le).
- Kizarolag a deployment-relevans NFR-ek (min. gepigeny, OS, halozati sebesseg) kiemelese TBD-vel.

### OUT
- **Teljes modul OUT** (nem programfunkcio). Ezek a klienstelepites-tervezeshez keszult helyszini felmeresek.
- TILOS barmilyen funkcionalis kovetelmenyt levezetni belolук.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| (telepito/uzemeltető, NEM alkalmazas-szerep) | helyszini telepites | n/a (OUT) |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| — | Nincs FR. A forras hardver/halozati felmeres, nem funkcionalis spec. | — | — | OUT |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-HW-01 | Tamogatott OS-tartomany (a felmert gepek vegyesen: Windows 7 Professional/SP1, Windows 10 Home/Pro/Enterprise) | TBD: az Electron-kliensek min. tamogatott Windows verzioja (a Win7 gepek miatt) |
| NFR-HW-02 | Min. gepigeny: a felmert flotta gyengebb gepei (pl. i3-2120, Pentium G3220, 2–4 GB RAM, HDD/SSD vegyes) | TBD: a 3 Electron kliens dokumentalt min. CPU/RAM/tarhely kovetelmenye |
| NFR-NET-01 | Internet-sebesseg szelsosegek: feltoltes 0.81 Mbps (Kecskemet user-PC) – 55.61 Mbps; ping akar 470 ms (H81MGL8). Lassu/instabil telephelyek leteznek. | TBD: offline-first/sync tolerancia kuszob lassu vonalon (kapcsolat a local-first mandate-hez) |

## 6. Adatmodell-erintettseg
Nincs (OUT). Postgres/SQLite entitas nem erintett. Migracio nem szukseges.

## 7. Fuggosegek
Nincs alkalmazas-fuggoseg. Kulso: helyszini halozat/ISP, periferiak (cimkenyomtatok pl. ZDesigner GC420t/GK420t, lapnyomtatok HP/Brother, szkennerek CanoScan, webkamerak). Ezek deployment-input, NEM API.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Valutas gep | A valtoirodai munkaallomas a felmeresben (megkulonboztetve a "Zalog" gepektol) |
| Zalog gep/szerver/kliens | A zalogos (kulon termek) munkaallomasai — lasd `b10-zalog-kulon-termek.md` |
| Speedtest | Internet le-/feltoltes + ping merese telephelyenkent |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
Ez katalogus-stub. NINCS implementacios feladat. A forrasok deployment-tervezeshez (ki melyik gepre, milyen OS-re telepit) hasznalandok, NEM kodolashoz.
### 9.2 Fazisok (acceptance criteria-val)
- Fazis 0 (egyetlen): a felmeresi fajlok listazva maradnak referenciakent. AC: az NFR-HW/NET TBD-k uzleti dontesre varnak; nincs kodvaltozas.
### 9.3 Tesztes
Nincs (OUT).

## Forras-fajlok katalogus
**A) `.../Dokumentumok hálózati és számítógép felméréshez/*.docx` (~30 db, telephelyenkenti gep-spec):**
Bekescsaba Kliens, Bekescsaba Zalog, Debrecen hatso vezetoi gep, Debrecen zalog kliensgep, Debrecen zalog szerver gep, Dombovar hatso gep, Dombovar zalog fo gep, Dombovar zalog kliens, Fehergyarmat kereskedelmi gep, Fehergyarmat Zalog, Hodmezovasarhely Zalog, Kaposvar admin pc, Kaposvar Zalog kliens gep, Kecskemet Vezetoi gep, Kisvarda vezetoi gep, Komlo Vezetoi gep, Mateszalka Zalog kliens, Nyiregyhaza Zalog kliens, Nyiregyhaza Zalog server, Pecs Diana Andi hatso gep DELL, Pecs Diana Norbi laptopja, Pecs Diana Zalog szerver, Pecs Rakoczi Vezetoi gep, Pecs Ybl becsusi gep, Pecs Ybl Vezetosegi gep, Szeged kereskedelem, Szekszard Ekszerbolt, Szolnok vezetosegi gep. (A docx-ek tobbsege csak cim-jellegu szoveget tartalmaz, a tenyleges spec a kimutatas-xlsx-ben + screenshotokban van.)
**B) `Hálózati és számítógép felmérés kimutatás.xlsx`** — oszlopok: Telepules / Eszkoz neve / Tipus / Rendszer parameterek / Internet sebessege (le-/feltoltes/ping) / Dokumentum (Google Docs link). Tartalmazza a flotta osszesitett halozati merest.
**C) `Kósa Tervezés és fejlesztés/.../!zálog (1).xlsx`** — reszletes gepenkenti HW-leltar (CPU, RAM, OS+verzio, videokartya, nyomtatok, monitorok, tarolo, NOD32 antivirus verzio+licenc, szkenner, kamera). Telephelyenkent csoportositva (Bekescsaba…Szeged). Megj.: nev ellenere ez a VEGYES valutas+zalog gep-leltar.
**D) `Kósa Tervezés és fejlesztés/.../Ilcsi -spec..png`, `Ilcsi- speedtest.png`, `Szilvi - Specifikáció.png`, `Szilvi - Speedtest.png`** — 2 munkatars gepenek spec+speedtest screenshotjai (azonos jellegu, mint a docx-ek).
**E) `Kósa Tervezés és fejlesztés/.../Békéscsaba-...zip`** — a bekescsabai felmeres osszecsomagolt forrasanyaga (nem kicsomagolva; TBD ha kell).

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | Tamogatjuk-e a Windows 7 gepeket? | Tobb zalog/valtos gep meg Win7 SP1 | Electron min. Windows verzio dontese (uzleti) |
| 2 | Min. gepigeny formalizalasa | Gyenge gepek (2 GB RAM, HDD) | TBD: hivatalos min. spec dokumentum |
| 3 | Lassu vonal (0.8 Mbps feltoltes, 470 ms ping) tolerancia | Sync megbizhatosag | Kapcsolat a local-first/offline mandate-hez |
| 4 | Bekescsaba .zip tartalma | Lehet tovabbi felmeresi adat | Kicsomagolas csak ha uzletileg indokolt |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás (nincs FR — OUT)
- [x] 0 hallucináció (csak a kinyert tablazat-/spec-tartalom)
- [x] minden TBD jelölt
VERIFIKACIO: FR=0 db, TBD=4 db (+3 NFR), érintett csomag(ok)=deployment/uzemeltetés (alkalmazas-csomag NINCS, OUT). Katalogizalt forras: ~30 docx + 2 xlsx + 4 png + 1 zip = ~37 fajl.
