# Modul: Zárás Ablak (zárás-wizard)  (forrás: Felmérés/Valuta/Kósa Szervezés/zaras_ablak.docx; azonos másolat: Felmérés/Valuta/Szervezés/zaras_ablak.docx)

## 1. Cel (egy mondat)
Egy Zárás Ablak, amely lépésenkénti (16 lépéses) wizardon vezeti végig a felhasználót a napi / dekád / havi / POS terminál záráson — összesítéssel, eltérés-kezeléssel, bizonylat-nyomtatással és a központba küldött riportokkal —, plus a korábbi zárások megtekintését és a bizonylatok újranyomtatását.

## 2. Scope
### IN
- Zárás Ablak fő funkciói: Zárások megtekintése, Bizonylatok újranyomtatása, Zárás (forrás: bevezető).
- Zárás indítása gomb + rákérdezés a zárás típusára: napi / dekád / havi (forrás: bevezető).
- Dekád zárás rákérdezés időzítése: a legutóbbi dekád zárást követő 10. nyitvatartási nap zárásakor (forrás: bevezető).
- Havi zárás rákérdezés időzítése: a legutóbbi zárást követő hónap utolsó nyitvatartási nap zárásakor (forrás: bevezető).
- Zárás kiválasztása – OK → Zárás wizard indítása (forrás: bevezető).
- Wizard 16 lépése (Lépés 1–16), "Tovább"/"Vissza" navigációval és a záró "Megerősítés" gombbal (forrás: 1–7. szakasz).
- Zárási típusválasztó a wizard 1. képernyőjén: Napi, POS terminál, Dekád, Havi (forrás: 1. szakasz).

### OUT
- A zárási bizonylatok pontos mezőtartalma (külön forrás a bizonylat-képeknél, lásd b2-zaras-kepernyok-bizonylatok.md).
- A riportok küldésének technikai csatornája a központba (forrás csak "automatikus küldés"/"beállítás") — TBD-1.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Felhasználó (pénztáros) | Zárás indítása, összesítések ellenőrzése/jóváhagyása, eltérés-magyarázat megadása, bizonylat-nyomtatás, riport-küldés beállítása, zárás véglegesítése (forrás: 1–7. szakasz) | TBD-2 (forrás nem nevez RBAC értéket) |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | Zárás Ablak: korábbi zárások megtekintése | zaras_ablak.docx bevezető | Magas | penztar-client |
| FR-2 | Zárás Ablak: bizonylatok újranyomtatása | zaras_ablak.docx bevezető | Magas | penztar-client |
| FR-3 | "Zárás indítása" gomb, majd rákérdezés a zárás típusára (napi/dekád/havi), kiválasztás után OK → wizard indul | zaras_ablak.docx bevezető | Magas | penztar-client |
| FR-4 | Dekád zárás rákérdezés a legutóbbi dekád zárást követő 10. nyitvatartási nap zárásakor | zaras_ablak.docx bevezető | Magas | backend / penztar-client |
| FR-5 | Havi zárás rákérdezés a legutóbbi zárást követő hónap utolsó nyitvatartási nap zárásakor | zaras_ablak.docx bevezető | Magas | backend / penztar-client |
| FR-6 | Wizard 1. képernyő: tájékoztatás a zárási folyamatról + típusválasztó (Napi, POS terminál, Dekád, Havi) | zaras_ablak.docx 1. szakasz | Magas | penztar-client |
| FR-7 | Lépés 1: napi tranzakciók automatikus összesítése devizanemenként (vétel/eladás, pénztárak közötti mozgások), manuális ellenőrzés/jóváhagyás | zaras_ablak.docx 2. szakasz | Magas | penztar-client / backend |
| FR-8 | Lépés 2: készpénz nyitó- és zárókészlet ellenőrzése devizanemenként, kézi ellenőrzés és véglegesítés | zaras_ablak.docx 2. szakasz | Magas | penztar-client |
| FR-9 | Lépés 3: kezelési költségek összesített értékének megjelenítése | zaras_ablak.docx 2. szakasz | Magas | penztar-client |
| FR-10 | Lépés 4: pénztárak közötti mozgások (átadott/átvett devizák) összesített értékének megtekintése | zaras_ablak.docx 2. szakasz | Magas | penztar-client |
| FR-11 | Lépés 5: aznap használt valutaárfolyamok megjelenítése | zaras_ablak.docx 2. szakasz | Magas | penztar-client |
| FR-12 | Lépés 6 (dekád/havi): dekád tranzakciók és devizakészletek összesítése | zaras_ablak.docx 3. szakasz | Magas | penztar-client / backend |
| FR-13 | Lépés 7 (dekád/havi): pénzügyi eltérések (többlet/hiány) megjelenítése + eltérés-magyarázat megadása | zaras_ablak.docx 3. szakasz | Magas | penztar-client |
| FR-14 | Lépés 8 (dekád/havi): rendszer által generált korrekciós bizonylatok megtekintése (eltérések + magyarázatok) | zaras_ablak.docx 3. szakasz | Magas | penztar-client / backend |
| FR-15 | Lépés 9 (POS): kártyás tranzakciók összesítése | zaras_ablak.docx 4. szakasz | Magas | penztar-client |
| FR-16 | Lépés 10 (POS): visszatérítések és sztornók összesítése | zaras_ablak.docx 4. szakasz | Magas | penztar-client |
| FR-17 | Lépés 11 (POS): kezelési költségek és tranzakciós díjak összesítése | zaras_ablak.docx 4. szakasz | Magas | penztar-client |
| FR-18 | Lépés 12: zárási bizonylatok többpéldányos nyomtatása, kiválasztható bizonylatok (napi/dekád/havi/POS) | zaras_ablak.docx 5. szakasz | Magas | penztar-client |
| FR-19 | Lépés 13: napi forint készpénz átadás-átvételi bizonylatok nyomtatása folyamatos sorszámozással | zaras_ablak.docx 5. szakasz | Magas | penztar-client / backend |
| FR-20 | Lépés 14: napi zárási jelentések automatikus küldésének beállítása a központba | zaras_ablak.docx 6. szakasz | Magas | penztar-client / backend |
| FR-21 | Lépés 15: dekád/havi zárási jelentések automatikus küldésének beállítása a központi rendszerbe | zaras_ablak.docx 6. szakasz | Magas | penztar-client / backend |
| FR-22 | Lépés 16: zárási folyamat véglegesítése "Megerősítés" gombbal; a rendszer lezárja a napi vagy dekád/havi zárást és elkészíti a végleges jelentéseket | zaras_ablak.docx 7. szakasz | Magas | penztar-client / backend |
| FR-23 | Minden wizard-lépésen "Tovább" és "Vissza" navigáció | zaras_ablak.docx 2–6. szakasz | Magas | penztar-client |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Lépés-sorrend és kétirányú navigáció | Minden lépésen "Tovább"/"Vissza" elérhető; a 16. lépés a "Megerősítés" (forrás: 2–7. szakasz) |
| NFR-2 | Típus-feltételes lépések | A dekád/havi lépések (6–8) csak dekád/havi zárás kiválasztásakor jelennek meg (forrás: 3. szakasz) |
| NFR-3 | Bizonylat-sorszám folytonossága | A napi forint átadás-átvételi bizonylatok folyamatos sorszámozással nyomtatódnak (forrás: 5. szakasz) |
| NFR-4 | Zárás-rákérdezés időzítés | Dekád: 10. nyitvatartási nap; havi: hónap utolsó nyitvatartási nap (forrás: bevezető) |

## 6. Adatmodell-erintettseg
A forrás nem nevez konkrét táblát/mezőt. A wizardból levezetett szükséges fogalmak (konkrét séma TBD-3):
- Zárás-rekord: típus (napi/dekád/havi/POS), dátum/időszak, állapot (folyamatban/véglegesített).
- Napi összesítés devizanemenként (vétel/eladás, pénztárak közötti mozgások), nyitó/zárókészlet, kezelési költség, használt árfolyamok.
- Dekád/havi összesítés, eltérés (többlet/hiány) + magyarázat, korrekciós bizonylat.
- POS összesítés: kártyás tranzakció, visszatérítés/sztornó, díjak.
- Forint átadás-átvételi bizonylat sorszámmal.
- Riport-küldés beállítás (napi, dekád/havi) a központ felé.
SQLite mirror: IGEN (a zárás a penztar-client offline-képes folyamata; konkrét mezők TBD-3). Migráció szükséges? TBD-3.

## 7. Fuggosegek
- Belső: tranzakció-adatok, készlet-nyilvántartás, kezelési költség, árfolyamtábla, pénztárak közötti mozgás (átadás-átvétel).
- Belső: korrekciós bizonylat generálás (eltéréskezelés).
- Külső: POS terminál (kártyás tranzakciók, visszatérítés/sztornó) (forrás: 4. szakasz).
- Külső/belső: központi rendszer (riportok automatikus küldése) — csatorna TBD-1.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Napi zárás | Az adott nap tranzakcióinak/készleteinek összesítése és lezárása (forrás: 2. szakasz) |
| Dekád zárás | 10 nyitvatartási napos időszak zárása; a 10. nyitvatartási nap zárásakor kérdez rá (forrás: bevezető, 3. szakasz) |
| Havi zárás | A hónap utolsó nyitvatartási napján esedékes zárás (forrás: bevezető, 3. szakasz) |
| POS terminál zárás | A kártyás tranzakciók, visszatérítések, sztornók és díjak összesítése (forrás: 4. szakasz) |
| Eltérés (többlet/hiány) | A dekád/havi időszak alatt fellépett pénzügyi különbözet, amelyhez magyarázat adható (forrás: 3. szakasz) |
| Korrekciós bizonylat | A rendszer által generált bizonylat az eltérésekről és magyarázatokról (forrás: 3. szakasz) |
| Forint átadás-átvételi bizonylat | Napi forint készpénz átadás-átvétel bizonylata, folyamatos sorszámozással (forrás: 5. szakasz) |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A `zaras_ablak.docx` az egyetlen igazságforrás; ne hasonlíts a jelenlegi kódhoz ebben a fázisban.
- A bizonylatok mezőtartalmáért lásd a b2-zaras-kepernyok-bizonylatok.md-t (külön forráscsoport).
- Tisztázd a TBD-1..TBD-3 kérdéseket a kódolás előtt.

### 9.2 Fazisok (acceptance criteria-val)
- 1. fázis — Wizard váz + típusválasztó + rákérdezés-időzítés. AC: "Zárás indítása" → típus-rákérdezés napi/dekád/havi, OK indítja a wizardot; dekád a 10. nyitvatartási napon, havi a hónap utolsó nyitvatartási napján kérdez rá (FR-1..FR-6, NFR-2, NFR-4).
- 2. fázis — Napi lépések (1–5) "Tovább"/"Vissza" navigációval. AC: devizanemenkénti összesítés, nyitó/zárókészlet, kezelési költség, mozgások, árfolyamok megjeleníthetők és jóváhagyhatók (FR-7..FR-11, FR-23, NFR-1).
- 3. fázis — Dekád/havi lépések (6–8). AC: dekád/havi összesítés + eltérés-magyarázat + korrekciós bizonylatok megtekintése csak dekád/havi módban (FR-12..FR-14, NFR-2).
- 4. fázis — POS lépések (9–11). AC: kártyás összesítés, visszatérítés/sztornó és díjak megjelennek (FR-15..FR-17).
- 5. fázis — Bizonylatok (12–13) + riportok (14–15) + véglegesítés (16). AC: többpéldányos zárási bizonylat-nyomtatás + sorszámos forint átadás-átvétel + riport-küldés beállítás + "Megerősítés" lezárja a zárást és elkészíti a végleges jelentéseket (FR-18..FR-22, NFR-3).

### 9.3 Tesztes
- Egységteszt: típusválasztó → mely lépéssor aktiválódik (napi vs. dekád/havi vs. POS).
- Egységteszt: dekád/havi rákérdezés-időzítés (10. nyitvatartási nap; hónap utolsó nyitvatartási nap).
- Egységteszt: lépés-navigáció ("Tovább"/"Vissza"), állapotmegőrzés.
- Integrációs teszt: napi összesítés devizanemenként, nyitó/zárókészlet, kezelési költség, mozgások, árfolyamok.
- Integrációs teszt: dekád/havi eltérés (többlet/hiány) + magyarázat + korrekciós bizonylat.
- Integrációs teszt: forint átadás-átvételi bizonylat folyamatos sorszámozás; véglegesítés utáni végleges jelentés.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | A riportok központba küldésének technikai csatornája és formátuma | Központi konszolidáció | A forrás csak "automatikus küldés"/"beállítás"-t ír |
| TBD-2 | A zárást végző felhasználó konkrét RBAC szerepkör-értéke | Jogosultság-implementáció | Csomag szereplő-listához kötés |
| TBD-3 | Zárás/összesítés/eltérés/bizonylat pontos adatmodellje + SQLite mirror mezők | Tárolás és offline működés | Konkrét entitás/mező-terv |
| TBD-4 | "Nyitvatartási nap" pontos definíciója és forrása (naptár/üzleti naptár) | Dekád/havi rákérdezés időzítése | Munkanap/ünnepnap-kezelés szabálya |
| TBD-5 | A POS lépések feltételessége (mindig vagy csak POS-os fiókoknál) | Wizard-lépéssor összeállítása | A forrás külön "POS terminál zárás" típust is felsorol az 1. képernyőn |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak a zaras_ablak.docx tartalma)
- [x] minden TBD jelölt
VERIFIKACIO: FR=23 db, TBD=5 db, érintett csomag(ok)=penztar-client, backend.
