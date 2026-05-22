# Modul: Régi Delphi valutaprogram — Pénztárállás, bizonylat-szűrés, listák  (forrás: Képernyőképek/Pillanatnyi pénztárállás kimutatása.jpeg, Pillanatnyi pénztár állás kimutatása2 .jpeg, Bizonylatok szűrése.jpeg, Bizonylatok szűrése2.jpeg, Összesített pénztárforgalom lekérdező menü.jpeg, Különféle listák menü .jpeg, Egyéb feladatok menü.jpeg, Egyéb feladatok menü(1).jpeg)

## 1. Cel (egy mondat)
A régi valutaprogram kimutatás/lekérdező felületei — pillanatnyi pénztárállás táblázat, bizonylat-szűrés, összesített pénztárforgalom időszak-választó, "Különféle listák" és "Egyéb feladatok" menük — hűen leírva.

## 2. Scope
### IN
- Pillanatnyi pénztárállás táblázat (oszlopok + sorok + alsó gombsor).
- Bizonylatok szűrése dialógus (rádiógomb-opciók).
- Összesített pénztárforgalom időszak-választó.
- "Különféle listák" menü tételei.
- "Egyéb feladatok" menü (két állapot/szint).
### OUT
- A listák tényleges nyomtatott kimenete (PDF/nyomtatvány tartalma).
- A "Különféle beállítások", "Pénztárgép utasításai" stb. aldialógusai (külön források).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | Pillanatnyi pénztárállás megtekintése/nyomtatása, bizonylat-szűrés, listák | TBD |
| Vezető / Belsőellenőr | Összesített pénztárforgalom, statisztikai listák | TBD |
| Adminisztrátor | "Egyéb feladatok" → beállítások, pénztárgép-parancsok, ügyfél-karbantartás | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-PA-01 | "A PILLANATNYI PÉNZTÁRÁLLÁS KIMUTATÁSA" táblázat oszlopai: VNEM, VALUTA NEVE, NYITÓ, BEVÉTEL, KIADÁS, KEZ-I DÍJ, ZÁRÓ. | Pillanatnyi pénztárállás kimutatása.jpeg / 2 .jpeg | M | penztar-client |
| FR-PA-02 | A táblázat valutánként egy sor; megfigyelt sorok (VNEM / név / nyitó=záró, bevétel-kiadás-kez.díj üres): BGN BOLGAR LEVA 235; CHF SVAJCI FRANK 680; CZK CSEH KORONA 2 000; EUR EURO 5 380; HUF MAGYAR FORINT 3 531 465; ILS IZRAELI SEKEL 400; PLN LENGYEL ZLOTYI 440; RON ÚJ ROMÁN LEI 4 730; RSD SZERB DINAR 8 060; TRY TÖRÖK LÍRA 635; USD USA DOLLAR 100. | Pillanatnyi pénztárállás kimutatása.jpeg / 2 .jpeg | M | penztar-client |
| FR-PA-03 | A ZÁRÓ oszlop a nyitó + bevétel − kiadás (± kez. díj) eredménye; a képen bevétel/kiadás üres → záró = nyitó. A HUF sor zöld, a többi záró piros (vélhetően valuta-megkülönböztető formázás). | Pillanatnyi pénztárállás kimutatása.jpeg | S | penztar-client |
| FR-PA-04 | A pillanatnyi pénztárállás alsó gombsora: "PILLANATNYI ÁLLÁS KINYOMTATÁSA", "KEZELÉSI DÍJ NYOMTATÁSA", "VISSZA A FŐMENÜRE (Escape)". | Pillanatnyi pénztárállás kimutatása.jpeg / 2 .jpeg | M | penztar-client |
| FR-PA-05 | "BIZONYLATOK SZŰRÉSE" dialógus rádiógomb-opciói: "Szűrés kikapcsolva", "Csak ügyfeles bizonylatok", "Csak vételi bizonylatok", "Csak eladási bizonylatok", "Csak konverziós bizonylatok", "Csak pénz-átadási bizonylatok", "Csak pénz átvételi bizonylatok", "Csak stornózott bizonylatok"; "Vissza" gomb. | Bizonylatok szűrése.jpeg / 2.jpeg | M | penztar-client |
| FR-PA-06 | A bizonylat-szűrés alsó sávja választógombokkal: "A HÓNAP ÖSSZES BIZONYLATA" / "CSAK A VÁLASZTOTT NAP". | Bizonylatok szűrése.jpeg / 2.jpeg | S | penztar-client |
| FR-PA-07 | A bizonylat-szűrés bal oldalán bizonylat-lista oszlopfejek ("Blokkfejek", DÁTUM, BIB, BLOKK kódok), jobb oldalt ügyfél-adat panel + "NAV NYUGTA" + bizonylatszám (pl. 1948/00001). | Bizonylatok szűrése.jpeg / 2.jpeg | C | penztar-client |
| FR-PA-08 | "ÖSSZESITETT PÉNZTÁRFORGALOM" időszak-választó: cím "ADJA MEG A KÉRT IDŐSZAKOT", legördülők: év (2024), hónap (MÁRCIUS), naptól (1) – napig (31); gombok: "IDŐSZAK RENDBEN", "CSAK A MAI NAP", "MÉGSEM". | Összesített pénztárforgalom lekérdező menü.jpeg | M | penztar-client |
| FR-PA-09 | "KÜLÖNFÉLE LISTÁK" menü tételei: "KIADOTT BIZONYLATOK LISTÁI", "PÉNZFORGALOM A PÉNZTÁRAK FELÉ", "TRB FORGALMI LISTÁK", "ELADÁSI - VÉTELI STATISZTIKA", "HAVI TABLÓK ÁTTEKINTÉSE" (szürkített), "PILLANATNYI KÉSZLETEK" (szürkített), "HAVI KEDVEZMÉNYEK LISTÁJA" (szürkített), "DEKÁD VAGY NAPIZÁRÁS KÖNYVELÉSE", "KEZELÉSI DÍJAK LISTÁJA"; "MÉGSEM" gomb. | Különféle listák menü .jpeg | M | penztar-client |
| FR-PA-10 | "EGYÉB FELADATOK" menü (1. állapot) tételei: "KÜLÖNFÉLE BEÁLLÍTÁSOK", "PÉNZTÁRGÉP UTASÍTÁSAI", "OTP POS TERMINÁL PARANCSOK", "ADATLAPOK KEZELÉSE", "ÜGYFÉL KARBANTARTAS", "KILÉPÉS AZ EGYÉB FELADATOKBÓL". | Egyéb feladatok menü.jpeg | M | penztar-client |
| FR-PA-11 | "EGYÉB FELADATOK" menü (kibontott / pénztárgép-almenü) tételei: "KÜLÖNFÉLE BEÁLLÍTÁSOK", "PÉNZTÁRGÉP VALUTÁINAK TÖRLÉSE", "VALUTÁK BETÖLTÉSE A PÉNZTÁRGÉPBE", "NAPNYITÁS A PÉNZTÁRGÉPEN", "NAPZÁRÁS A PÉNZTÁRGÉPEN", "PÉNZTÁRGÉP COM-PORTJÁNAK ÁLLITÁSA", "KILÉPÉS AZ EGYÉB FELADATOKBÓL". | Egyéb feladatok menü(1).jpeg | M | penztar-client |
| FR-PA-12 | A pillanatnyi pénztárállás kimutatás fejléce egységnevet/várost tartalmaz (kontextus). | Pillanatnyi pénztárállás kimutatása.jpeg | C | penztar-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-PA-01 | A pillanatnyi pénztárállás minden aktív valutát egy sorban, ezres tagolással jelenít meg. | Ezres szóköz-tagolás látható (pl. "3 531 465") |
| NFR-PA-02 | A bizonylat-szűrés egyszerre egy opciót enged (rádiógomb). | Egyetlen aktív opció |
| NFR-PA-03 | Az időszak-választó alapértelmezés a teljes aktuális hónap. | 1 – hó-utolsó nap előkitöltve (pl. 1–31) |
| NFR-PA-04 | Szürkített listatételek mód-/jogosultság-/adatfüggően nem elérhetők. | Szürke = letiltott állapot |

## 6. Adatmodell-erintettseg
- Pillanatnyi pénztárállás: levezetett nézet (nem új entitás) — valutánként nyitó/bevétel/kiadás/kezelési díj/záró aggregáció a tranzakciókból és nyitó-egyenlegekből. SQLite mirror IGEN (offline kimutatás a helyi tranzakciókból).
- Bizonylat-szűrés: bizonylat/tranzakció entitásra szűr (típus: ügyfeles, vételi, eladási, konverziós, pénz-átadási, pénz-átvételi, stornózott). SQLite mirror IGEN.
- Összesített pénztárforgalom: időszak-paraméteres aggregáció (év/hó/naptól-napig). Új entitás nem szükséges.
- "Egyéb feladatok": rendszerbeállítás + pénztárgép-/POS-terminál parancsok + ügyfél-karbantartás (ügyfél entitás). Migráció a leírásból közvetlenül nem következik → TBD.

## 7. Fuggosegek
- Belső: tranzakció/bizonylat modul, kezelési díj modul, készlet-modul, napi/havi zárás, ügyfél-modul.
- Külső: pénztárgép (AEE/online pénztárgép — "PÉNZTÁRGÉP UTASÍTÁSAI", "NAPNYITÁS/NAPZÁRÁS A PÉNZTÁRGÉPEN", "COM-PORT ÁLLÍTÁS"), OTP POS terminál ("OTP POS TERMINÁL PARANCSOK"), NAV ("NAV NYUGTA"). Pontos protokoll/integráció a forrásból nem olvasható → TBD.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| VNEM | Valutanem (ISO-kód, pl. EUR, USD, HUF). |
| Nyitó / Záró | A pénztár adott valutából vett nyitó- ill. záró-egyenlege. |
| KEZ-I DÍJ | Kezelési díj oszlop a pénztárállásban. |
| Dekád | 10 napos elszámolási időszak ("DEKÁD VAGY NAPIZÁRÁS KÖNYVELÉSE"). |
| TRB forgalmi lista | A TRB (egyedi kötés mozgás) gyűjtő-pénztár forgalmi kimutatása. |
| NAV nyugta | NAV-felé bejelentett/nyomtatott nyugta a bizonylathoz. |
| Pénztárgép COM-port | Az online pénztárgép soros (COM) portjának beállítása. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be mind a 8 forrásképet; rögzítsd a pillanatnyi pénztárállás oszlopfejeit pontosan (VNEM/VALUTA NEVE/NYITÓ/BEVÉTEL/KIADÁS/KEZ-I DÍJ/ZÁRÓ).
### 9.2 Fazisok
- Fázis 1 — Pillanatnyi pénztárállás: oszlopok + sorok + gombsor. Acceptance: FR-PA-01..04 forrás-hivatkozással.
- Fázis 2 — Bizonylat-szűrés: 8 opció + nap/hónap kapcsoló. Acceptance: FR-PA-05..07.
- Fázis 3 — Lekérdező/lista-menük: időszak-választó + "Különféle listák" + "Egyéb feladatok" két állapota. Acceptance: FR-PA-08..11.
### 9.3 Tesztes
- Forrás-kép vs. spec összevetés (minden FR-hez kép). A számértékek (NYITÓ=ZÁRÓ) csak példa-állapot, nem üzleti szabály.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A pillanatnyi pénztárállás BEVÉTEL/KIADÁS/KEZ-I DÍJ oszlopai a képen üresek — mikor töltődnek? | A nézet teljes viselkedése. | A példa-állapot zárás előtti/forgalom nélküli; a kitöltési logika nem látszik. |
| 2 | A ZÁRÓ szín-kódolás (HUF zöld, többi piros) jelentése? | Helyes UI-reprodukció. | Vélhetően forint vs. deviza megkülönböztetés; nem dokumentált. |
| 3 | A szürkített "Különféle listák" tételek mikor aktívak (HAVI TABLÓK, PILLANATNYI KÉSZLETEK, HAVI KEDVEZMÉNYEK)? | Funkció-elérhetőség. | Szürke = letiltott; ok ismeretlen. |
| 4 | A "TRB FORGALMI LISTÁK" / "DEKÁD VAGY NAPIZÁRÁS KÖNYVELÉSE" pontos tartalma? | Lista-spec. | Csak menüfelirat. |
| 5 | A pénztárgép/POS integráció protokollja (COM-port, OTP POS, AEE)? | Hardver-integráció. | Csak menüfelirat olvasható. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (nem olvasható részek TBD)
- [x] minden TBD jelölt

VERIFIKACIO: FR=12 db, TBD=5 db, érintett csomag(ok)=penztar-client
