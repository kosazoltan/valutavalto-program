# Modul: EXZ+EXV uzemeltetes es jelenlegi rendszer-architektura (Valuta)  (forras: Kósa Szervezés/Cégcsoport felmérése/RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx)

## 1. Cel (egy mondat)
A jelenlegi (Delphi + Firebird) valutavalto rendszer uzemeltetesi mukodesenek, kliens-szerver kommunikaciojanak es a NAV-/bank-/tiltolista-folyamatoknak a hu rogzitese az ujrafejlesztes alapjaul.

## 2. Scope
### IN
- Jelenlegi rendszer-architektura: kliens lokális Firebird DB + RackForest-en hostolt központi szerver (RDP), Anti bácsi által írt szoftver (557-576).
- Árfolyam- és tiltólista-leküldés szerverről kliensre (5 percenként lekérés, pénztáronként egyedi árfolyam) (572-573, 576).
- Felfelé irányuló kommunikáció: nyitás/zárás, kasszaállapot, címletezés, pénzszállítás, forgalmi adat + DB-mentés (577).
- Hibakezelés gép-hiba esetén: kézi bizonylat + nyomtatott árfolyamlista, utólagos rögzítés (579-580).
- NAV-kommunikáció kliensenként (kötelező), 24 órás határidő, ÁNYK fallback (585-588).
- Napzárási időablak (30 perc), területi vezető jóváhagyás (584).
- Kamerás program (Java), nyomtató párhuzamos port probléma, NIS2 érintettség (600-604).
- Webes/központi-szerver-alapú jövőbeni megoldás megfontolása (596, 605-606).

### OUT
- Konkret uj implementacios technologia-valasztas (kesobbi modul).
- A jelenlegi programmal valo osszehasonlitas/atvetel reszletes terve.
- Bank/NAV uzleti szabalyok reszletes katalogusa (lasd b7-igenyfelmeres-interjuk.md).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Penztaros | Tranzakció + kézi bizonylat hiba esetén, címletező nyitás/zárás | TBD |
| Foertektaros | Árfolyamok kiküldése szerverről, tiltólista kezelés | TBD |
| Teruleti vezeto | Zárás jóváhagyás 30 perc időablak után, ÁNYK lejelentés hiba esetén | TBD |
| Belsoellenor | Kasszaállapot/címletezés felfelé irányuló adat megtekintése | TBD |
| Uzemeltetes (EXZ+EXV / Póka János) | Telepítés, DB helyreállítás (C mappa visszamásolás), új pénztár üres DB | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-37 | Kliens 5 percenként lekéri a központi szervertől az árfolyamokat; sikertelen lekérésnél jelzi és a jelenlegivel dolgozik, folyamatosan újrapróbál. | EXZ+EXV (572, 576) | Must | penztar-client |
| FR-38 | Szerver pénztáronként egyedi árfolyamot tud leküldeni (konkurencia-függő); egy gép = egy önálló kasszagép, gépenként lokális DB. | EXZ+EXV (573, 576) | Must | kozponti-client / penztar-client |
| FR-39 | Tiltott-ügyfél lista központi vezérlése; kiszolgálható-e az ügyfél jelzés a pénztárosnak (terrorista-/szankciós lista). | EXZ+EXV (572) | Must | backend |
| FR-40 | Tiltólista-frissítés globális (minden pénztárnál azonos), csak a változás (név be/ki) terjed, NEM pénztáronként eltérő. | EXZ+EXV (591) | Must | backend |
| FR-41 | Felfelé irányuló kommunikáció záráskor: forgalmi adat + DB-mentés + kasszaállapot + címletezés nyitás-zárás, gépenként függetlenül. | EXZ+EXV (577) | Must | penztar-client / kozponti-client |
| FR-42 | Pénzszállításkor (be/ki vételezés) kliens->szerver kommunikáció a területi vezető irányába. | EXZ+EXV (577) | Must | backend |
| FR-43 | Gép-hiba esetén kézi bizonylat + nyomtatott/blokknyomtatott árfolyamlista, utólagos rögzítés a gép helyreállítása után. | EXZ+EXV (579-580) | Must | penztar-client |
| FR-44 | Belső szabályzat: bizonyos időközönként árfolyam-bizonylat nyomtatása, ebből dolgoznak hiba esetén. | EXZ+EXV (580) | Should | penztar-client |
| FR-45 | Kliens kötelezően kommunikál a NAV-val (a delphis program végzi); minden tranzakcióról blokk + azonnali NAV-lejelentés. | EXZ+EXV (585-586) | Must | backend |
| FR-46 | Kézi munka esetén 24 óra a NAV-lejelentésre (ÁNYK), különben a területi vezető jelenti; késedelem = bírság. | EXZ+EXV (586, 588) | Must | backend |
| FR-47 | Net-kiesésnél a gép gyűjti a lejelentéseket, kapcsolat helyreálltakor feltölti (24 órás határidőn belül). | EXZ+EXV (588) | Must | penztar-client |
| FR-48 | Napzárási időablak: zárás után 30 percig beküldhető, utána csak területi vezető jóváhagyásával. | EXZ+EXV (584) | Must | backend |
| FR-49 | NAV-lejelentés mezői: dátum, összegek, tétel(ek) megnevezése, vevő adatai névre szóló ÁFA-s számlánál, időbélyeg (XML). | EXZ+EXV (590) | Must | backend |
| FR-50 | Kliensek a telepítéstől kezdve mindent visszamenőleg tárolnak (pénztárhiány / hatósági megkeresés visszakereshetőség). | EXZ+EXV (595) | Must | penztar-client |
| FR-51 | Címletező a kliens gépeken; nyitás-zárás címletadata felmegy, hogy a területi vezető és belsőellenőr lássa a kasszában lévő pénzt címletre rendezve. | EXZ+EXV (577) | Must | penztar-client |
| FR-52 | (Jövőbeni megfontolás) Webes/böngészőben futó, központi szerverrel kommunikáló megoldás a Delphi helyett. | EXZ+EXV (596, 605-606) | Could | backend / frontend-react |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-07 | Árfolyam-lekérés gyakorisága | 5 perc (EXZ+EXV 572) |
| NFR-08 | NAV-lejelentés azonnali, kézi esetben max. határidő | 24 óra (586-588) |
| NFR-09 | Napzárás-beküldés időablak | 30 perc zárás után, utána jóváhagyás (584) |
| NFR-10 | Visszakereshetőség / megőrzés | telepítéstől visszamenőleg minden (595) |
| NFR-11 | NIS2 megfelelés | audit, pentest, IPS-modulos tűzfal, logelemzés, 2FA VPN (603-604) |
| NFR-12 | Internet | feltöltőkártyás, gyenge kapcsolat tolerálása (589) |

## 6. Adatmodell-erintettseg
- Postgres entitas-jeloltek: árfolyam (pénztáronként egyedi), tiltólista (globális, változás-alapú szinkron), nyitás/zárás bizonylat, kasszaállapot + címletezés, pénzszállítás-mozgás, NAV-lejelentés-rekord (status: beküldve/megszakítva/gyűjtésben), DB-mentés metaadat.
- SQLite mirror: IGEN (a jelenlegi rendszer is gépenként lokális Firebird DB-vel működik; offline NAV-gyűjtés + árfolyam-fallback megköveteli). Indok: net-kiesés és kötelező lokális megőrzés (FR-47, FR-50).
- Migracio szukseges: TBD (régi Firebird C-mappa adat migrációja külön feladat; a programozó/korábbi fejlesztő adja a forráskódot — 02.12 interjú 392).

## 7. Fuggosegek
- Külső API: NAV pénztárgép (kliensenként kötelező, XML), ÁNYK (kézi/területi vezetői fallback), Raiffeisen bank (változás-jelentés — köre TBD).
- Külső szoftver/eszköz: kamerás program (Java), blokknyomtató (párhuzamos portos, PCEA kártya), árfolyam-kijelző monitor (ugyanazon a gépen).
- Infrastruktura: jelenleg RackForest hosting + RDP; jövőben központi szerver / webes megoldás megfontolás.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| C mappa / valuta könyvtár | A teljes kliensoldali valutaprogram + Firebird DB egy könyvtárban, helyreállítás = C mappa visszamásolás (569, 583). |
| RackForest | A jelenlegi központi szerver hosting-szolgáltatója (575). |
| ÁNYK | NAV Általános Nyomtatványkitöltő, kézi lejelentés fallback (586). |
| Adóügyi nap / Z-zárás | NAV pénztárgép napzárás (a Prior-kérdésekben DC-paraméterek). |
| NIS2 | EU kiberbiztonsági irányelv, a zálog és valuta is kötelezően érintett (603). |
| Anti bácsi | A jelenlegi Delphi + Firebird rendszer és a központi szerver szoftver eredeti fejlesztője (569, 572). |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Ez a dokumentum a JELENLEGI rendszer leírása (architektúra-as-is), nem az új rendszer terve; tényként rögzíts, ne javasolj alternatívát a 4-8. szekcióban.
- A "webes megoldás" / "központi szerveren minden tárolva" csak megfontolás-szintű (605-606), Could prioritás.
### 9.2 Fazisok (acceptance criteria-val)
- 1. fazis: árfolyam-szinkron (FR-37, FR-38) + tiltólista-szinkron (FR-39, FR-40). AC: 5 perces poll + offline fallback; globális tiltólista-változás terjedés.
- 2. fazis: NAV-kommunikáció (FR-45, FR-46, FR-47, FR-49). AC: azonnali lejelentés, net-kiesésnél gyűjtés + feltöltés 24 órán belül.
- 3. fazis: napzárás-időablak (FR-48) + felfelé kommunikáció (FR-41, FR-42, FR-51). AC: 30 perc után jóváhagyás-gate; címlet/kassza adat felmegy.
### 9.3 Tesztes
- Backend: tiltólista delta-szinkron, NAV-lejelentés állapotgép (beküldve/megszakítva/gyűjtés/feltöltve), napzárás 30 perces időablak gate.
- Electron: 5 perces árfolyam-poll + fallback, offline NAV-gyűjtés perzisztencia, lokális visszamenőleges tárolás.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-12 | Bank felé változás-jelentési kötelezettség pontos köre | banki integráció | Kérdés feltéve, válasz nincs (592). |
| TBD-13 | NAV API kommunikációs protokoll részletei | NAV-integráció | "Erről van egy dokumentáció" — a dok nincs csatolva (597-598). |
| TBD-14 | Központi szerveres tárolás megvalósíthatósága (számla ott jön létre, ahol az adatbázis) | architektúra-döntés | "még beszélünk róla" — nyitott (605-606). |
| TBD-15 | Kamerás program (Java) technológiai továbbvitele | kamera-integráció | "szóba kerülhet" — nincs döntés (602). |
| TBD-16 | Régi Firebird C-mappa adatmigráció módja | migráció | Forráskódot a korábbi fejlesztő adja (02.12 interjú), de migrációs terv nincs. |
| TBD-17 | Blokknyomtató párhuzamos-port / PCEA kártya kiváltása | hardver | Beszerzési nehézség említve, megoldás nincs (583, 601). |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció
- [x] minden TBD jelölt
VERIFIKACIO: FR=16 db (FR-37..FR-52), TBD=6 db (TBD-12..TBD-17), érintett csomag(ok)=backend, penztar-client, kozponti-client, frontend-react.
