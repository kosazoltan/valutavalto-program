# Modul: Igenyfelmeres es uzleti igenyek (Valuta)  (forras: Cégcsoport felmérése/Igényfelmérési interjú/Kósa cégcsoport első igényfelmérési kérdések.docx; .../RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx; .../RSL 2. Igényfelmérési interjú összefoglaló 2024.02.15_.docx; Kósa Szervezés/Cégcsoport felmérése/kerdesek.docx)

## 1. Cel (egy mondat)
A Kosa-cegcsoport (Valuta/Best Change, Ekszer, Zalog) igenyfelmeresi interjuiban es a folytatolagos kerdes-valasz jegyzetekben rogzitett uzleti igenyek, fajdalompontok es muxodesi szabalyok hu osszegyujtese funkcionalis kovetelmenyekke.

## 2. Scope
### IN
- Cegcsoport-szervezet feltérképezés (Valuta cég: 180 fo, 62 valutapénztár, 8 régió/értéktár), önálló cégenkénti adatszétválasztás (forras: 02.12 interjú).
- Valutavaltasi tevekenyseg uzleti folyamata: vétel, eladás, kereszt/konverziós váltás, kezelési költség mint külön tranzakció/bizonylat, két elkülönített pénztár (forras: 02.12 interjú; kerdesek.docx).
- Bizonylatszamozas-szabalyok, sztornó-szabályok, supervisori jelszó (értéktárosi + belsőellenőri) (forras: kerdesek.docx).
- AML / Pmt. azonositasi kuszobok (300 e Ft, jogi szemely 5 Ft-tól), közszereplő nyilatkozat, tiltó-/szankciós lista, forrásigazolás (forras: kerdesek.docx; 02.12 interjú).
- Arfolyam-kedvezmeny / sávos vs egyedi árfolyam, 2% supervisori küszöb, elszámoló árfolyam, átlagárfolyam (forras: kerdesek.docx).
- NAV pénztárgép-feladás, banki napi/havi elszámolás, jutalék, tranzakciós illeték (forras: kerdesek.docx; 02.15 interjú).
- Foglaló-kezelés, pénztárak közötti mozgás (átadás/átvétel, plombaszám, szállító), valuta-igény (forras: kerdesek.docx).
- Külső rendszer-integrációk: könyvelés (Kulcs-Soft/Kulcs-Bér, RLB, Adriana, Számlázz.hu), bank (Raiffeisen Elektra), POS/OTP (forras: 02.12 + 02.15 interjú).
- HR / munkavállaló-megjelenítés (tab-fülek), beosztás/munkaszervezés mint közös modul (forras: 02.15 interjú).

### OUT
- Konkret technikai implementacio (kesobbi EXCMD modulokban + a jelenlegi programhoz hasonlitas).
- Ekszer es Zalog cegek belso reszletes folyamatai (csak annyiban, amennyiben a Valuta-modul kozos).
- Infrastruktura/halozat reszletes felmeres (kulon felmeresi dokumentum).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Penztaros | Vétel/eladás/konverzió/foglaló rögzítése, címletezés, napi nyitás/zárás | TBD (forrás csak munkaköri leírást ad) |
| Ertektaros | Pénzellátás-szervezés, készletfigyelés, banki ki-/beszállítás, supervisori (értéktárosi) jelszó árfolyam-módosításhoz | TBD |
| Foertektaros | Árfolyamok meghatározása/kiküldése, elszámoló és átlag árfolyam számítás, fixing (forras: kerdesek.docx, 02.12) | TBD |
| Teruleti vezeto | Régió személyi/tárgyi feltételei, jogosultság-kontroll, sztornó/zárás jóváhagyás | TBD |
| Belsoellenor | Belsőellenőri supervisori jelszó (sztornó 3. felett, újranyomtatás, módosítások) | TBD |
| Ugyvezeto / admin | Alaptőke meghatározás (Kósa Zoltán + főértéktár), rendszerbeállítás | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-01 | Napi zárás kikényszerítése: zárás előtt ~30 perccel kilépéskor erősen ajánlja fel a zárást (külön művelet kell a zárás nélküli kilépéshez). | kerdesek.docx (665, 691) | Must | penztar-client |
| FR-02 | Bizonylatszám = pénztár 3-jegyű kódja + folyamatos, kihagyás nélküli sorszám; típus-betűprefix: V/E/F/U/FF/UF/B/K (foglaló: B átvétel, K átadás). | kerdesek.docx (666, 692-704) | Must | backend |
| FR-03 | Árfolyam-kedvezmény 2% feletti eltérésnél csak értéktárosi supervisori jelszóval engedélyezhető. | kerdesek.docx (667, 705) | Must | penztar-client |
| FR-04 | Elszámoló árfolyam: főértéktáros határozza meg; napi forint-ellenérték elszámoló árfolyamon; hó végén MNB árfolyamon. | kerdesek.docx (706) | Must | backend / arfolyam-keszito-client |
| FR-05 | Átlag árfolyam riport: főértéktáros programja adott időszak vételi/eladási árfolyamából számol. | kerdesek.docx (706, 800) | Should | kozponti-client |
| FR-06 | Pénzkivét költségre TILOS (szigorúan tiltott művelet). | kerdesek.docx (669, 707) | Must | backend |
| FR-07 | Közszereplő típus választása kötelező listából (trv-i), rögzítés + bizonylaton nyomtatás + ügyfél aláírás. | kerdesek.docx (673, 711) | Must | penztar-client |
| FR-08 | Banktól valuta-átvételnél nincs külön banki bizonylat rögzítés (a saját bizonylat ellenpárja). | kerdesek.docx (676, 714) | Should | backend |
| FR-09 | Bizonylat újranyomtatás csak belsőellenőri supervisori jelszóval + nyomtatás indokának kötelező beírásával. | kerdesek.docx (677, 715) | Must | penztar-client |
| FR-10 | Kezelési költség kasszája és a valuta kassza elkülönített; átvezetés tilos. | kerdesek.docx (679, 717, 352) | Must | backend |
| FR-11 | Sztornó: minden pénztár helyileg sztornózhat indok megadásával; 3. sztornótól csak belsőellenőri jelszóval. | kerdesek.docx (680, 718, 725) | Must | penztar-client |
| FR-12 | Sztornónál nem kell NAV-bizonylatszám: ha volt NAV-nyugta, a program tudja és a sztornót a NAV-nyomtatóra is kiküldi. | kerdesek.docx (681, 719) | Must | backend |
| FR-13 | Tranzakciós illeték: 4,5 M Ft alatt 4,5 ezrelék, felette darabonként 20.000 Ft (NAV-nak fizetendő). | kerdesek.docx (683, 721) | Must | backend |
| FR-14 | Pénztár állapot (üzemel/nem üzemel) szerveren: ha egy pénztár tárgynapon zárva, a szerver ne keresse a zárását. | kerdesek.docx (684, 722, 791) | Must | kozponti-client |
| FR-15 | Pénztár-pénztár / értéktár-pénztár valutamozgás IS megy a NAV-gépre. | kerdesek.docx (685, 723) | Must | backend |
| FR-16 | Pénzszállítás bankba a fiók-átadással azonos, betűjelölésekkel: ERB / TRB / FRB. | kerdesek.docx (729, 734) | Should | backend |
| FR-17 | MNB társpénztár megszűnt; hamisgyanús valuta/forint most a TH (többlet-hiány) pénztárba könyvelődik. | kerdesek.docx (730, 735) | Must | backend |
| FR-18 | Kereszt/konverziós váltás (pl. EUR<->USD) törvény szerint két bizonylat (konverziós vétel + konverziós eladás), kezelési költség elengedve; sztornó 2 sztornó. | kerdesek.docx (731, 737, 779) | Must | penztar-client |
| FR-19 | Anonim/névtelen bejelentés: a bejelentő kiléte soha ne legyen visszakereshető; visszavonható a végleges küldés előtti kilépéssel. | kerdesek.docx (739, 767, 783) | Must | backend |
| FR-20 | 300 e Ft felett, ill. jogi személy 5 Ft-tól teljes azonosítás; közszereplő automatikusan 5 Ft-tól; ügyfél nem törölhető, ha 300 e felett váltott. | kerdesek.docx (742, 790, 797-798) | Must | penztar-client |
| FR-21 | Foglaló: határidő alapból következő nap (módosítható); >=5 nap eltérés csak supervisori jelszóval; csak kp-val fizethető; nem könyvelődik, nem megy szerverre. | kerdesek.docx (754, 761, 774) | Must | penztar-client |
| FR-22 | Új pénztár felvétele a társpénztár-listába; törlés csak supervisori jelszóval. | kerdesek.docx (752) | Should | kozponti-client |
| FR-23 | Fizikai eltérés (kiad 20 / bevesz 19) a TH pénztárral, visszapótlás az 1. sz. főpénztárral könyvelődik. | kerdesek.docx (759) | Must | backend |
| FR-24 | Díjkedvezmény: %-os és sávos; felezés (értéktári engedély), kártyás eltörlés, egyedi (bármely összeg) — supervisori jelszóval. | kerdesek.docx (768, 793, 786) | Should | penztar-client |
| FR-25 | Tiltó/szankciós lista automatikus letöltés + szerverrel folyamatos szinkron; tiltott ügyfélnél a program kilépteti a tételből; forrásigazolással supervisori jelszóval engedhető. | kerdesek.docx (775, 784, 812) | Must | backend |
| FR-26 | Plombaszám: 10 karakterig bármilyen betű-szám kombináció, NEM vonalkód (pénzszállító zsák száma). | kerdesek.docx (785) | Must | penztar-client |
| FR-27 | Bankkártyás fizetés +1 Ft-ot ró a cégre; POS tranzakciós díjat nem hárítják át. | kerdesek.docx (786) | Could | backend |
| FR-28 | Banki fixing: kis mennyiségű valutákra (pl. RON) 11 óráig leadás a bank honlapján; 2 tizedes árfolyam + valuta + forint, eltérés tilos. | kerdesek.docx (788-789) | Should | kozponti-client |
| FR-29 | Napi banki riport: csak 300 e Ft feletti azonosított tételek mennek a bank felé. | kerdesek.docx (790) | Must | backend |
| FR-30 | NAV pénztárgépre menő mezők: vétel/eladás valutaneme, összeg, árfolyam, kezelési költség, kifizetendő forint, deviza-státusz, dátum, pénztár neve/címe, időpont (XML). | kerdesek.docx (762, 590) | Must | backend |
| FR-31 | Munkavállaló-rögzítés tab-füles megjelenítéssel (a demó szerint), a Zálog meglévő adatmezőivel. | 02.15 interjú (132-136) | Should | kozponti-client |
| FR-32 | Könyvelési feladás (RLB) készletnyilvántartóból és bevételekből, kézi rögzítés csökkentése; cél: kerekítés-pontos egyezés (fillér eltérés tilos). | 02.15 interjú (149-155) | Should | backend |
| FR-33 | Cégenként teljes adatszétválasztás: külön DB/szerver, controlling cégenként, semmilyen adat nem mosható össze. | 02.12 interjú (316-321, 358) | Must | backend |
| FR-34 | Árfolyam-kijelző: főértéktárból gombnyomással az adott fiók gépére küldött, 5-20 perces frissítés a konkurencia függvényében; pénztáronként eltérő árfolyam. | 02.12 interjú (361-364) | Must | kozponti-client / penztar-client |
| FR-35 | Okmány-szkennelés: személyi + lakcímkártya beolvasása és tranzakcióhoz rendelése (Raiffeisennek leadva), állítható paraméterrel. | 02.12 interjú (374-375) | Should | penztar-client |
| FR-36 | Offline működés: árfolyam-lekérés 5 percenként újrapróbál, hiba esetén a legutóbbi árfolyammal dolgozik; kézi árfolyamnál nincs sávos opció. | RSL EXZ+EXV (576); kerdesek.docx (756) | Must | penztar-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-01 | Minimális kijelző-felbontás | 1920x1080 (forras: első kérdések, 24) |
| NFR-02 | Adatszétválasztás cégenként | 1 fizikai szerver, logikailag elkülönített DB-k cégenként (02.12, 358) |
| NFR-03 | NAV-lejelentés határidő kézi esetben | 24 óra (RSL EXZ+EXV, 586-588) |
| NFR-04 | Log-megőrzés | min. 1 év, bizonyos pénztáraknál >1 év nem törölhető (kerdesek.docx, 780) |
| NFR-05 | NIS2 megfelelés (audit, pentest, IPS tűzfal, logelemzés, 2FA VPN) | RSL EXZ+EXV (603-604) |
| NFR-06 | Internet: gyenge/mobil kapcsolat tolerálása (Vodafone 30 GB) | RSL 02.12 (387); EXZ+EXV (589) |

## 6. Adatmodell-erintettseg
- Postgres entitas-jeloltek a forras alapjan: tranzakció (vétel/eladás/konverzió), bizonylat (típusbetű + 3-jegyű pénztárkód + sorszám), kezelési-költség-tranzakció (külön kassza), foglaló, közszereplő-nyilatkozat, ügyfél-azonosítás + okmány-szkennelés, tiltólista, pénztár-állapot, pénztár-pénztár mozgás, banki fixing, NAV-feladás-rekord, díjkedvezmény, jutalék.
- SQLite mirror: IGEN a pénztáros offline működéshez (FR-36 — 5 perces árfolyam-újrapróba, kézi árfolyam-fallback). Indok: offline net-kiesés tolerálás (NFR-06).
- Migracio szukseges: TBD (forrás nem ad sémát; jelenlegi rendszerhez nem hasonlítunk).

## 7. Fuggosegek
- Külső API: NAV pénztárgép (XML, Fiscat slip — kerdesek.docx 802-803), MNB (hó végi árfolyam), Raiffeisen bank (napi/havi elszámolás, fixing, Elektra/Darius felület), OTP POS.
- Külső szoftver: Kulcs-Soft/Kulcs-Bér, RLB, Adriana, Számlázz.hu (02.15 interjú).
- Belső modul: árfolyamkezelés, AML/szankciós lista, bizonylat, pénztár-mozgás, foglaló.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Elszámoló árfolyam | Főértéktáros által megadott árfolyam, amin a napi forint-ellenértéket nyilvántartják (kerdesek.docx 706). |
| TH pénztár | Többlet-hiány pénztár, fizikai eltérés és hamisgyanús valuta könyvelésére (759, 735). |
| 1. sz. főpénztár | Visszapótlás könyvelési pénztára fizikai eltérésnél (759). |
| Fixing | Bank által tárgynapon adott kedvező árfolyam kis mennyiségű valutákra, 11 óráig leadva (788). |
| Konverziós vétel/eladás | Kereszt-váltás két bizonylata, kezelési költség elengedve (737, 779). |
| Sávos árfolyam | Főértéktáros által képletesen készített kedvezményes árfolyam-táblázat, gépekre letöltve (757). |
| Deviza-státusz | Bankba/NAV-hoz menő státusz-mező (kerdesek.docx 762). |
| Darius felület | Banki beküldési felület a napi tranzakciókhoz (02.12, 346). |
| Anti bácsi | A jelenlegi Delphi/Firebird rendszer eredeti fejlesztője (EXZ+EXV megbeszélés). |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A 4 forrásdokumentumot egységként kezeld; a `kerdesek.docx` a legrészletesebb (kérdés→ügyfélválasz párok, dátumozott blokkokban 2024.09-2024.10).
- Minden ügyfélválaszt tényként rögzíts; ahol a válasz "Ez hol van?" / "nem értem" → a kérdés nyitott, TBD-ként vidd tovább.
### 9.2 Fazisok (acceptance criteria-val)
- 1. fazis: bizonylatszámozás (FR-02) + sztornó-szabályok (FR-11, FR-12). AC: V/E/F/U/FF/UF/B/K prefix + 3-jegyű kód, kihagyás nélküli sorszám; 3. sztornótól belsőellenőri jelszó.
- 2. fazis: AML/azonosítás (FR-07, FR-20, FR-25) + közszereplő. AC: 300 e Ft / jogi 5 Ft / közszereplő 5 Ft küszöbök; tiltottlista-szinkron kilépteti a tételből.
- 3. fazis: kezelési költség külön kassza (FR-10) + tranzakciós illeték (FR-13) + NAV-feladás (FR-30). AC: két kassza átvezetés tiltva; illeték 4,5 ezrelék / 20.000 Ft darab.
- 4. fazis: árfolyam-kedvezmény 2% (FR-03) + offline fallback (FR-36) + foglaló (FR-21).
### 9.3 Tesztes
- Backend JUnit: bizonylatszám-generátor (prefix+kód+sorszám-folytonosság), illeték-számítás határértékek (4,5 M Ft alatt/felett), TH/1.sz. főpénztár könyvelés.
- Frontend/Electron: 2% árfolyam-supervisor gate, 3. sztornó gate, offline árfolyam-fallback, foglaló kp-kötelező.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | RBAC kódértékek (szerep->RBAC) | jogosultság-implementáció | A forrás csak munkaköröket nevez meg, nem ad RBAC-kódot. |
| TBD-2 | "maradék Forint" készlet-mező jelentése | készlet-nyilvántartás | Ügyfél visszakérdezett "ez hol van pontosan?" (708). |
| TBD-3 | Pénztár nyitó forgalmi adatok jelentése | nyitás/zárás napló | Ügyfél: "ez melyik menüpontban van?" (710). |
| TBD-4 | "...jutalék" kezelési-költség jelentésben | jelentés | Ügyfél: "ez hol van?" (720). |
| TBD-5 | Engedélyező kódképzés szabálya (sztornó/kedvezmény) | supervisori jelszó-algoritmus | Külön jelszóval védett e-mailben küldik, NEM a forrásban (726). |
| TBD-6 | Fiscat NAV-protokoll "11"-es kód jelentése | NAV-küldés | "a 11-es ok nincs a leírásban" (803). |
| TBD-7 | Alaptőke nyilvántartás a rendszerben | controlling | Most csak Excelbe írják, rendszerbe NEM (796). |
| TBD-8 | Havi forgalom trend %-számítás módja | riport | "hogy jön ki?" — nincs válasz (817). |
| TBD-9 | Foglaló könyvelési igénye | könyvelés | "Zsuzsa megkérdezi a könyvelőket" — nyitott (774). |
| TBD-10 | NAV pénztárgép (Prior Kft.) napzárás DC-paraméterek (daily dept/PLU/Exchange/X before Z) | NAV-integráció | Az RSL nem érti, Prior Kft-nek feltett kérdések, válasz nincs (832-837). |
| TBD-11 | Bank felé változás-jelentési kötelezettség pontos köre | banki integráció | Kérdés feltéve, válasz nincs (592). |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció
- [x] minden TBD jelölt
VERIFIKACIO: FR=36 db, TBD=11 db, érintett csomag(ok)=backend, penztar-client, kozponti-client, arfolyam-keszito-client.
