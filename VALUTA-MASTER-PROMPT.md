# VALUTA-MASTER-PROMPT — Teljes Valutaváltó Rendszer Dokumentáció

> **Generálva:** 2026-04-03 — 4 forrásdokumentum egyesítése
> **Források:**
> 1. `antivaluta.GPT-5.4.md` — Legacy rendszer feltérképezése (GPT-5.4 elemzés)
> 2. `Anti/antivaluta.md` — Anti mappa teljes forráskód-elemzés (2026-04-02)
> 3. `VALUTA-VEGREHAJTASI-UTASITAS.md` — AI végrehajtási utasítás
> 4. `Anti/ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md` — Modernizációs masterplan + Gap Analysis

---

# ══════════════════════════════════════════
# RÉSZ I: LEGACY RENDSZER TELJES DOKUMENTÁCIÓ
# ══════════════════════════════════════════

> Egyesített forrás: `antivaluta.GPT-5.4.md` + `Anti/antivaluta.md`
> Ahol mindkét dokumentum ugyanazt írja le, a részletesebb verzió szerepel.

---

## I.1. Rendszer Áttekintés

Az `Anti` mappa egy **többgenerációs, hibrid valutaváltó ERP rendszert** tartalmaz:

| Komponens | Technológia | Leírás |
|-----------|-------------|--------|
| **VALUTA/IBVALTO** | Delphi 7 EXE | Fő pénztári kliens alkalmazás |
| **VALUTA/DLL** | Delphi 7 DLL-ek (109 db) | Moduláris üzleti logika DLL-ekben |
| **VALUTA/TRADE** | Delphi 7 EXE | Kereskedési / tranzakciós alrendszer |
| **ARFOLYAM** | Delphi 7 EXE | Árfolyam-kezelő alkalmazás |
| **KESZLEX** | Delphi 7 EXE | Készletkezelő (pénztárak készletlekérdezése) |
| **KORLEVEL_ZIP/korlevel** | Delphi 7 EXE | Körlevél-kezelő rendszer |
| **SZERVER** | Mappa-struktúra (96+36 modul) | Szerver oldali logika |
| **camera2/camera** | Java (Maven multi-module, 238 Java fájl) | Kamerarendszer v2 |
| **camera3/old** | Java (37 almodul) | Régi Java ökoszisztéma |
| **camera** | Windows installer | Kameraszoftver telepítő |
| **firebird** | Firebird 2.1 | Adatbázis-motor és config |

### Statisztika
- **Pascal forrásfájlok (.pas):** ~420 db
- **Delphi projektfájlok (.dpr):** ~279 db
- **Form fájlok (.dfm):** ~419 db
- **Java forrásfájlok:** ~1600+ db
- **DLL-ek (lefordított):** 109 egyedi DLL
- **Adatbázis:** Firebird/InterBase (.fdb/.gdb)

### Technológiai rétegek
- Delphi 7 / Pascal desktop kliens és DLL plugin-rendszer
- InterBase / Firebird alapú lokális és távoli adatbázisok
- JavaFX / Spring / MySQL alapú újabb vagy kísérő rendszerek
- fájlalapú nyomtatás, export és mentés
- távoli Firebird elérés host:path formában
- HTTP, FTP és segéd-EXE integrációk

---

## I.2. Fő Alkalmazás: IBVALTO (Pénztári Kliens)

### I.2.1 Projekt struktúra

**Projektfájl:** `VALUTA/IBVALTO/IBVALTO.DPR`

| Unit | Form név | Funkció |
|------|----------|---------|
| Unit1 (UNIT1.PAS) — 69 131 byte | FORM1 | Fő alkalmazás-ablak, központi vezérlő |
| Unit2 | OPENKERDOFORM | Nyitó kérdés (indulási dialógus) |
| Unit3 | UJKONVERZIO | Új konverziós tranzakció form |
| Unit4 | TOLTOFORM | Betöltő/splash képernyő |
| Unit5 | TRYAGAINFORM | Újrapróbálkozás form (hiba esetén) |
| Unit18 | ZARASFORM | Zárási form (napzárás, havizárás, címletnyomtató) |
| Unit47 | FOMENUFORM | **Főmenü** — 9 pontos menürendszer |

Lényegi jellemzők:
- mutexszel védi az egyszeres futást: `IBVALTO.EXE`
- splash/loader képernyőt használ
- shell/orchestrator szerepet tölt be, a konkrét műveleteket a `c:\valuta\bin\*.dll` modulokba delegálja

### I.2.2 Indulási sorrend

1. egyszeres futás ellenőrzése mutexszel
2. splash és részmodulok betöltése
3. képernyőfelbontás ellenőrzése
4. lokális könyvtárak és ideiglenes fájlok előkészítése
5. hardver- és pénztáradatok beolvasása
6. szerver-hozzáférés állapotának meghatározása
7. pénztáros bejelentkeztetése DLL-en keresztül
8. értéktárszám bekérése, ha hiányzik
9. napállapot-ellenőrzés
10. szükség esetén napnyitás
11. havi zárás státusz ellenőrzése
12. opcionális terminál/OTP beléptetés
13. dekád és kezelési díj nyomtatások ellenőrzése
14. főmenü indítása

### I.2.3 Főmenü (FOMENUFORM — Unit47)

A főmenü **két oldalas**, balra-jobbra animált csúszkával vált:

#### 1. oldal — Alap pénztári műveletek
| Menüpont | Sorszám | Funkció |
|----------|---------|---------|
| **VALUTA VÉTEL** | MenuBar1 | Deviza vásárlás ügyféltől |
| **VALUTA ELADÁS** | MenuBar2 | Deviza eladás ügyfélnek |
| **VALUTA KONVERZIÓ** | MenuBar3 | Devizanemek közti átváltás |
| **PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL** | MenuBar4 | Társpénztárak közti pénzmozgás |
| **MAI BIZONYLAT SZTORNÓJA** | MenuBar5 | Napi bizonylat sztornózása |
| **NAPI FORGALOM KIMUTATÁSA** | MenuBar6 | Napi forgalom összesítő |
| **RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA** | MenuBar7 | Korábbi napzárás reprint |
| **A PILLANATNYI ÁLLÁS REGENERÁLÁSA** | MenuBar8 | Készlet újraszámítás |
| **EGYÉB BEÁLLÍTÁSOK ÉS PROGRAMOK** | MenuBar9 | Rendszerbeállítások |

#### 2. oldal — Kiegészítő funkciók
| Menüpont | Funkció |
|----------|---------|
| **ÁRFOLYAM BEÁLLÍTÁSOK** | Árfolyam törzs karbantartás |
| **A PILLANATNYI PÉNZTÁR ÁLLÁSA** | Aktuális készlet lekérdezés |
| **BIZONYLATOK MEGTEKINTÉSE A KÉPERNYŐN** | Bizonylat-visszanézés |
| **KÜLÖNFÉLE LISTÁK NYOMTATÁSA** | Riportok, kimutatások |
| **TÁRSPÉNZTÁRAK KARBANTARTÁSA** | Társpénztár törzs kezelés |
| **VALUTA FORGALOM ÖSSZESÍTŐJE** | Forgalmi összesítő |
| **A NAPI- ÉS HAVIZÁRÁS** | Napi és havi lezárás |
| **CÍMLETEZÉS** | Címletezési műveletek |

### I.2.4 Menü dispatch

A kiválasztott menüpontot a shell timer alapú diszpécserrel futtatja le:

- 1 -> `vasarlasrutin`
- 2 -> `eladasrutin`
- 3 -> `Ujkonverzio.ShowModal`
- 4 -> `atadatvetrutin`
- 6 -> `stornorutin`
- 7 -> `arfolyamtmkrutin`
- 8 -> `pillallasrutin`
- 9 -> `forgosszrutin`
- 10 -> `ZarasForm.ShowModal`
- 11 -> `bizonylattallozo`
- 12 -> `penztartmkrutin`
- 13 -> `kulonfelelistak`
- 14 -> `penztaroskarbantartas`
- 15 -> `napiforgalomrutin`
- 16 -> `regizarasrutin`
- 17 -> `regeneralorutin`
- 18 -> `othertaskrutin`, majd kilépés

### I.2.5 Gyorsgombok (Funkciógombok a főképernyőn)

| Gomb | Funkció |
|------|---------|
| F1HistoryGomb | Tranzakciós előzmények |
| F2ElolegGomb | Előleg kezelés |
| F3TerminalGomb | Banki terminál (OTP) |
| F4AfaTablaGomb | ÁFA tábla |
| F5MaiForgalomGomb | Mai forgalom |
| F6TescoAfaGomb | Tesco ÁFA kezelés |
| F7SupervisorGomb | Supervisor belépés |
| F9KeszletGomb | Készlet lekérdezés |
| F10AtadolapGomb | Átadólap |
| F11AfaGomb | ÁFA funkciók |
| F12WUGomb | Western Union |
| EscapeGomb | Kilépés |
| FomenuGomb | Főmenü megnyitás |
| FutofenyGomb | Futófény/LED kijelző |
| KorlevelGomb | Körlevél megtekintés |
| ReprintGomb | Bizonylat újranyomtatás |
| ConfidGomb | Bizalmas riport |
| VerzioFrissitoGomb | Verziófrissítés |
| SzunetGomb | Szünet mód |

### I.2.6 Adatbázis-kapcsolatok a főalkalmazásban

A FORM1 **7 párhuzamos Firebird/InterBase adatbázis-kapcsolatot** kezel:

| Kapcsolat neve | Adatbázis | Funkció |
|----------------|-----------|---------|
| ValutaDbase + ValutaQuery + ValutaTranz | `valuta.fdb` | Fő valuta törzs |
| Valuta2Dbase + Valuta2Query + Valuta2Tranz | `valuta.fdb` | Párhuzamos lekérdezés |
| Valuta3Dbase + Valuta3Query + Valuta3Tranz | `valuta.fdb` | Harmadik párhuzamos |
| ValdataDbase + ValdataQuery + ValdataTranz | `valdata.fdb` | Tranzakciós adatok |
| TradeDbase + TradeQuery + TradeTranz | `trade.fdb` | Kereskedési adatok |
| NaploDbase + NaploQuery + NaploTranz | — | Naplózás |
| TempDbase + TempQuery + TempTranz | — | Ideiglenes adatok |

**Adatbázis útvonalak:** `c:\valuta\database\*.fdb`

### I.2.7 Napi állapotgép

A rendszer nagyon erős napnyitás-napzárás logikával működik. A `ZarasControl` jellegű logika alapján a program megkülönböztet:
- normál újrabelépést
- normál új nap nyitását
- lezáratlan nap utáni újranyitási kísérletet
- lezárt nap utáni újrabelépést
- hibás állapotot

### I.2.8 Pénztáros beléptetés

A kasszás nem a shellben azonosítja magát, hanem külső DLL kezeli:
- Beléptetés: `prosbe.dll`
- Kilépés: `proski.dll`

Sikeres belépés után:
- a shell kiolvassa a pénztáros azonosítóját és nevét
- naplózza a belépést
- megjeleníti az aktív kezelőt

### I.2.9 Biztonsági mechanizmusok

- **Mutex:** Egyidejű futás megakadályozása (`A VALUTAVÁLTÓ PROGRAM MÁR FUT A RENDSZERBEN !!`)
- **Terrorlista ellenőrzés:** Induláskor kötelező (`NINCS TERRORLISTA !` → Application.Terminate)
- **Supervisor jelszó:** Érzékeny műveleteknél felettes beléptetés szükséges
- **Szerver hozzáférés ellenőrzés:** Internet-kapcsolat vizsgálat (`InternetGetConnectedState`)
- **FTP kommunikáció:** Adatcsere a központi szerverrel (`TNMFTP` komponens)

---

## I.3. DLL Modul Architektúra

Az üzleti logika **109 egyedi DLL-ben** van szervezve. Minden DLL önálló Delphi projekt:
- **DEBUG** almappa: tesztelő EXE (Unit1.pas = teszter, Unit2.pas = tényleges logika)
- **MAKEDLL** almappa: a végleges DLL fordítás (Unit2.pas = exportált logika)

### I.3.1 Tranzakciós műveletek
| DLL | Funkció | Méret |
|-----|---------|-------|
| **Vasarlas.dll** | Valuta vétel (vásárlás ügyféltől) | 104K forrás |
| **Eladas.dll** | Valuta eladás (eladás ügyfélnek) | 137K forrás |
| **Storno.dll** | Bizonylat sztornózás | 36K forrás |
| **Xtranz.dll** | Extra tranzakció díj megjelenítés | 9K forrás |

### I.3.2 Árfolyam és kezelés
| DLL | Funkció | Méret |
|-----|---------|-------|
| **Getarf.dll** | Árfolyam lekérdezés | — |
| **arfreg.dll** | Árfolyam regisztráció | — |
| **arftmk.dll** | Árfolyam törzs karbantartás | — |
| **Setrate.dll** | Árfolyam beállítás | 5K forrás |
| **Arfvalt.dll** | Árfolyam váltás (módosítás) | 8K forrás |
| **KisarfValt.dll** | Kis árfolyam kedvezmény | — |
| **BigArfValt.dll** | Nagy árfolyam kedvezmény | 11K forrás |
| **afatab.dll** | ÁFA tábla | — |

### I.3.3 Készletkezelés és címletezés
| DLL | Funkció |
|-----|---------|
| **aktkesz.dll** | Aktuális (pénztári) készlet |
| **CIMLMENU.dll** | Címletezés főmenü |
| **Cimlet.dll** | Címletezés végrehajtás |
| **CimlCtrl.dll** | Címlet kontroll |
| **CimlNyom.dll** | Címletezés nyomtatás |
| **Cimsetup.dll** | Címletezés beállítás |
| **Kcimlet.dll** | Kiegészítő címletezés |
| **Kiscim.dll** | Kis címletezés |
| **KESZUP.dll** | Készlet frissítés (update) |
| **Keszedit.dll** | Készlet szerkesztés |

### I.3.4 Napi műveletek és zárások
| DLL | Funkció |
|-----|---------|
| **Napzar.dll** | Napzárás (44K forrás) |
| **Havizar.dll** | Havi zárás |
| **Napiforg.dll** | Napi forgalom |
| **Maiforg.dll** | Mai forgalom |
| **Forgossz.dll** | Forgalom összesítő (16K) |
| **napikezd.dll** | Napi kezdés |
| **NAPIJEL.dll** | Napi jelentés |
| **napkonyv.dll** | Napi könyvelés |
| **NzNyomt.dll** | Napzárás nyomtatás |
| **REGIZARO.dll** | Régi zárás újranyomtatás |
| **Estizar.dll** | Esti zárás |
| **Navzaro.dll** | NAV zárás |

### I.3.5 Ügyfélkezelés és AML
| DLL | Funkció | Méret |
|-----|---------|-------|
| **Ugyfel.dll** | Ügyfél adatfelvétel és kezelés | 114K forrás |
| **UGYFTMK.dll** | Ügyfél törzs karbantartás | 3K |
| **KISUGYFEL.dll** | Kis ügyfél (gyors azonosítás) | — |
| **terrlist.dll** | Terrorlista ellenőrzés | 8K forrás |
| **Bigctrl.dll** | Nagy kontroll (okmány ellenőrzés) | 46K forrás |
| **FirstCtrl.dll** | Első kontroll (belépő ellenőrzés) | 7K |

### I.3.6 Western Union
| DLL | Funkció | Méret |
|-----|---------|-------|
| **Wunion.dll** | Western Union fő modul | 91K forrás |

### I.3.7 Bizonylatok és nyomtatás
| DLL | Funkció |
|-----|---------|
| **Bloknyom.dll** | Blokk (bizonylat) nyomtatás |
| **Bizodisp.dll** | Bizonylat megjelenítés |
| **Docdisp.dll** | Dokumentum megjelenítés |
| **Getnyug.dll** | Nyugta lekérdezés |
| **QRGENER.dll** | QR kód generálás (22K forrás) |
| **Listak.dll** | Különféle listák (48K forrás) |
| **Logdisp.dll** | Log megjelenítés |

### I.3.8 Pénztárak közötti műveletek
| DLL | Funkció |
|-----|---------|
| **Atadolap.dll** | Átadólap |
| **Atadvet.dll** | Átadás-átvétel |
| **ptartmk.dll** | Pénztár törzs karbantartás |
| **Prosbe.dll** | Pénztáros beléptetés |
| **Proski.dll** | Pénztáros kiléptetés |
| **Prostmk.dll** | Pénztáros törzs karbantartás |
| **PILLALL.dll** | Pillanatnyi állás |
| **PILLKESZ.dll** | Pillanatnyi készlet |
| **GetPTar.dll** | Pénztár lekérdezés |

### I.3.9 Supervisor és jogosultság
| DLL | Funkció |
|-----|---------|
| **super.dll** | Supervisor jelszó (5K) — JELSZÓ RENDBEN / ÉRVÉNYTELEN |
| **SUPERTSK.dll** | Supervisor feladatok |
| **getenged.dll** | Engedély lekérdezés |

### I.3.10 OTP / Banki terminál
| DLL | Funkció | Méret |
|-----|---------|-------|
| **otp.dll** | OTP terminál kezelés | 60K forrás |
| **otplog.dll** | OTP log | — |
| **Terminal.dll** | Terminál vezérlés | — |
| **Tesco.dll** | Tesco ÁFA modul | 56K |
| **Metro.dll** | Metro ÁFA modul | 75K |

### I.3.11 Rendszer és egyéb
| DLL | Funkció | Méret |
|-----|---------|-------|
| **Othertsk.dll** | Egyéb beállítások és programok | 42K forrás |
| **GEPSETUP.dll** | Gépbeállítások | 57K forrás |
| **MENTES.dll** | Mentés | 4K |
| **Logiro.dll** | Log író | — |
| **verzfris.dll** | Verziófrissítés | 35K |
| **REGEN.dll** | Regenerálás | — |
| **Matptar.dll** | Matrica pénztár | — |
| **Matregen.dll** | Matrica regenerálás | — |
| **COPY2FTP.dll** | FTP másolás | — |
| **Fnyujsag.dll** | Futó-fényújság (LED kijelző) | — |
| **foglalo.dll** | Foglalás | 83K forrás |
| **foglrend.dll** | Foglalás rendelés | 21K |
| **SCANNING.dll** | Szkenner kezelés | 7K |
| **scanner.dll** | Új szkenner | — |
| **SENDOKMANY.dll** | Okmány küldés | — |
| **Confi.dll** | Bizalmas riport | 8K |
| **confirm.dll** | Megerősítés | — |
| **korlev.dll** | Körlevél | 27K |
| **NEWYEAR.dll** | Újévi levél | — |
| **PausDisp.dll** | Szünet kijelzés | — |
| **QUITFORM.dll** | Kilépés form | — |
| **GongBack.dll** | Gong/visszajelzés | — |
| **Checklst.dll** | Ellenőrző lista | — |
| **dekad.dll** | Dekád rutin | — |
| **Idoszak.dll** | Időszak kezelés | — |
| **Procend.dll** | Folyamat vége | — |
| **GETISO.dll** | ISO kód lekérdezés | — |
| **Getfize.dll** | Fizetőeszköz lekérdezés | — |
| **Getplomb.dll** | Plomba lekérdezés | — |
| **GETSTAT.dll** | Státusz lekérdezés | — |
| **Getwceg.dll** | WU cég lekérdezés | — |
| **Getwugyf.dll** | WU ügyfél lekérdezés | — |
| **KELLCIM.dll** | Szükséges cím | — |
| **teaorsel.dll** | TEÁOR szám választás | — |
| **Hrksend.dll** | HRK adatküldés | — |
| **hrkzaro.dll** | HRK zárás | — |
| **MAKTABLA.dll** | Makró tábla | — |

### I.3.12 FNYUJSAG variánsok (telephely-specifikus LED kijelzők)
- `FNYUJSAG\MAKEDLL`, `FNYUJSAG\ALAP`, `FNYUJSAG\BAJCSY`, `FNYUJSAG\BCSABA`
- `FNYUJSAG\DIANA`, `FNYUJSAG\DUPLACOM`, `FNYUJSAG\DUPOTHER`, `FNYUJSAG\FERENCES`
- `FNYUJSAG\IRGALMAS`, `FNYUJSAG\NOSPEED`, `FNYUJSAG\OROS`, `FNYUJSAG\SZOBOSZLO`
- `FNYUJSAG\UJTIPUS`, `FNYUJSAG\dombovar`, `FNYUJSAG\spec8085`

---

## I.4. Tranzakciós Üzleti Logika

### I.4.1 Valuta Vétel (VASARLAS — 104K forrás)

**Folyamat:**
1. Ügyfél azonosítás (`ugyfelrutin`)
2. Terrorlista ellenőrzés (automatikus)
3. Árfolyam kijelzés (`arfolyamkijelzes`)
4. Kedvezmény kezelés:
   - Kis árfolyam kedvezmény (`kisarfolyamkedvezmeny`)
   - Nagy árfolyam kedvezmény (`bigarfolyamkedvezmeny`)
   - Kezdeti díj kedvezmény (`kezdijkedvezmeny`)
5. Címletezés (`kellcimletrutin`, `kiscimletezes`)
6. Supervisor jóváhagyás (ha szükséges — `supervisorjelszo`)
7. QR kód generálás (`qrdisplayrutin`)
8. Bizonylat nyomtatás (`blokknyomtatas`)
9. Megerősítés (`confirmrutin`)
10. Készlet regenerálás (`regeneralorutin`)
11. FTP feltöltés (`copyfiletoftprutin`)
12. Okmányszkennelés (`ujokmanyszkennelo`, `bescannelorutin`)
13. EU akció kérdés (`euakciokerdo`)
14. Nyugta lekérdezés (`getnyugtarutin`)
15. Folyamat vége (`procendrutin`)

**Üzleti szabályok:**
- `A FORINT NEM VÁLASZTHATÓ VALUTA`
- `EURO BANKJEGYET ÉS ÉRMÉT KÜLÖN BIZONYLATON KELL ADNI`
- `NINCS ENNYI FORINT KÉSZLETÜNK !`
- `KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !`
- `AZ ÁRFOLYAM MÁR MÓDOSÍTVA VAN !`

Összefoglaló lépések:
1. `VTEMP` előkészítése `KONVERZIO=0` értékkel
2. `vasarlas.dll` meghívása
3. partner- és ügyféladatok beolvasása
4. árfolyam, címlet, fizetendő és kezelési díj számítása
5. bizonylat generálás
6. adatbázis könyvelés
7. készletállapot frissítése

### I.4.2 Valuta Eladás (ELADAS — 137K forrás)

**Kiegészítő funkciók a vételhez képest:**
- `arfvaltrutin` — árfolyam váltás (módosítás eladáskor)
- `setraterutin` — árfolyam beállítás
- `fizetoeszkozrutin` — fizetőeszköz kezelés
- `gongyvisszavonas` — gönggy visszavonás
- `otpterminal` — OTP terminál integráció
- `KonvDataVtempbe` — konverziós adatok ideiglenes táblába

**Speciális szabályok:**
- `EURO ÉRMÉT NEM ADUNK EL`
- `A KONVERTÁLT VALUTA ÉRTÉKE NEM LEHET NAGYOBB...`

### I.4.3 Sztornó (STORNO — 36K forrás)

- `stornorutin` — sztornó végrehajtás
- `blokknyomtatas` — sztornó bizonylat nyomtatás
- `gongyvisszavonas` — göngy visszavonás kísérlet
- `supervisorjelszo` — felettes jóváhagyás **kötelező**
- `qrdisplayrutin` — QR kód a sztornó bizonylathoz
- `otpterminal` — OTP terminál visszavonás
- `regeneralorutin` — készlet újraszámítás

Üzleti szabály:
- nem egyszerű törlés
- storno bizonylatot állít elő
- hivatkozik az eredeti bizonylatra
- külön ok és státuszmezőkkel dolgozik

### I.4.4 Konverzió (Unit3 — UJKONVERZIO)

- Devizanemek közötti közvetlen átváltás, önálló form
- Üzletileg vétel+eladás jellegű összetett tranzakció
- A `VTEMP` `KONVERZIO` mezője külön jelöli

### I.4.5 Pénztárak közötti átadás/átvétel

Kapcsolódó modulok: `atadvet.dll`, `atadolap.dll`

- pénztár és társpénztár közötti pénzmozgás
- a rendszer külön bizonylatolja az átadást és az átvételt
- pénz, valuta, jutalék és készlet/társ-pénztári viszony is megjelenik

### I.4.6 Árfolyamkezelés

Kapcsolódó modulok: `arftmk.dll`, `getarf.dll`, `arfreg.dll`, `setrate.dll`

Funkciók:
- árfolyam beállítás
- árfolyam letöltés
- árfolyam történet / regiszter
- kedvezményes árfolyamok
- engedélyhez kötött árfolyam-módosítás

### I.4.7 Pillanatnyi pénztárállás és készlet

Kapcsolódó modulok: `pillall.dll`, `pillkesz.dll`, `aktkesz.dll`, `matptar.dll`, `keszup.dll`, `keszedit.dll`

Funkciók:
- aktuális készletnézet
- címlet- és valutabontás
- pénztár és társpénztár készletviszonyok
- szerver felé készletbeküldés

---

## I.5. Napzárás és Zárási Rendszer (NAPZAR — 44K forrás)

### I.5.1 Napzárási folyamat

A **ZARASFORM** (Unit18) három fő zárási műveletet kínál:
1. **Napzárás** (`napzarrutin`)
2. **Havi zárás** (`havizarorutin`)
3. **Címletnyomtató** (`cimletnyomtatorutin`)

### I.5.2 Napzárás részletei

- `UresPenztarControl` — üres pénztár ellenőrzés
- `SetRekordDarab` — rekord darabszám beállítás
- **Ellenőrzések:**
  - Foglalókészlet címletezve van-e
  - MoneyGram címletezve van-e
  - Western Union (WU) kereskedelem címletezve van-e
- **Adatmásolás:** `A NAPI ADATOK BEMÁSOLÁSA A HAVI GYŰJTŐKBE`
- **Táblák érintettek:** NAPIZAR, HAVIOSSSZESITO, NAPIKEZDIJ, stb.

### I.5.3 Havi zárás
- külön fut
- a rendszer blokkolhatja a munkát, ha előző hónap nincs lezárva

---

## I.6. Adatbázis Struktúra (Firebird/InterBase)

### I.6.1 Lokális és távoli adatbázisok

**Jellemző lokális adatbázisfájlok:**
- `c:\valuta\database\valuta.fdb`
- `c:\valuta\database\valdata.fdb`
- `c:\valuta\database\trade.fdb`

**Távoli adatbázisok:**
- `{host}:C:\RECEPTOR\DATABASE\...`
- például: `ugyfelYY.fdb`, `kisugyfel.fdb`, `TERRORISTS.FDB`, `RECEPTOR.FDB`, `frissito.fdb`

### I.6.2 Azonosított táblák (90+)

#### Törzstáblák
| Tábla | Funkció |
|-------|---------|
| CIKKTORZS | Valutanem törzs (cikktörzs) |
| PARAMETERS | Rendszer paraméterek |
| HARDWARE | Hardver konfiguráció |
| PENZTAR | Pénztár törzs |
| PENZTAROSOK | Pénztárosok törzs |
| IRODAK | Irodák (telephelyek) |
| COUNTRIES | Országok |
| CITIZENS | Állampolgárok |
| UGYFEL | Ügyféltörzs |
| JOGISZEMELY | Jogi személyek |
| JOGI | Jogi adatok |
| TEAORTABLA | TEÁOR számok |

#### Tranzakciós táblák
| Tábla | Funkció |
|-------|---------|
| BLOKKFEJ | Bizonylat fejléc |
| BLOKKTETEL | Bizonylat tételek |
| ARFOLYAM | Árfolyam adatok |
| VTEMP | Ideiglenes munkaterület (shell↔DLL paraméterátadás) |
| FOGLALOK | Foglalások |
| FOGLALOKESZLET | Foglalás készlet |
| GONGYCSOMAG | Göngycsomag |
| KEZELESIDIJ | Kezelési díj |
| NAPIKEZELESIDIJ | Napi kezelési díj |
| HAVIKEZELESIDIJ | Havi kezelési díj |
| KEZDIJSORSZAM | Kezdeti díj sorszám |
| KEZELESDATA | Kezelés adatok |
| TRANZDIJ TABLA | Tranzakciós díj tábla |

#### Zárási és összesítő táblák
| Tábla | Funkció |
|-------|---------|
| NAPIZAR | Napi zárás |
| HAVIOSSSZESITO | Havi összesítő |
| HAVIZAR | Havi zárás |
| HAVIMAT | Havi matrica |
| NAPIMAT | Napi matrica |
| NAPIOOSSSZESITO | Napi összesítő |
| IDOSZAK | Időszak |
| DEKADJELENTES | Dekád jelentés |
| EVISTATISZTIKA | Éves statisztika |
| LASTYEAR | Előző év adatok |
| BFyyMM | Havi lezárt bizonylat fej |
| BTyyMM | Havi lezárt bizonylat tétel |
| TRADyyMM | TRADE havi könyvelési táblái |
| PENZTARFORGALOM | Pénztárforgalmi összesítő |

#### Bizonylat és nyomtatás
| Tábla | Funkció |
|-------|---------|
| UTOLSOBLOKKOOK | Utolsó blokkok (sorszám) |
| LASTNUM / LASTNUMS | Utolsó sorszámok |
| PRINTCONTROL | Nyomtatás vezérlés |
| QRPARAMS | QR kód paraméterek |
| MATBIZONYLAT | Matrica bizonylat |
| MATDATA | Matrica adatok |
| IKTATO | Iktatószám |

#### Western Union
| Tábla | Funkció |
|-------|---------|
| WUGYFEL | WU ügyfél |
| WUMOZGAS | WU mozgás |
| WUNI | WU fő tábla |
| WUAFAADATOK | WU ÁFA adatok |
| WUAFACEGEK | WU ÁFA cégek |
| WZAR | WU zárás |

#### Biztonsági és log táblák
| Tábla | Funkció |
|-------|---------|
| ADATLAP | Ügyfél adatlap (AML) |
| BEJELENT | Bejelentés (FIU) |
| SIGNAL / ZSIGNAL / VIPSIGNAL | Jelzések |
| PAUSES | Szünetek |
| JELENLET | Jelenlét |
| MEDIA | Média (kamera) |
| CIMLETEK | Címletek |
| CIMLETPISZKOZAT | Címlet piszkozat |
| PARTNERPARA | Partner paraméterek |
| UJTULAJOK | Új tulajdonosok |
| UNOLLIST | UNO lista (szankciós) |
| KORLEVEL | Körlevél |
| HRKDATA / HRKNAPLO / HRKSZAMLAK | HRK adatok |
| VIPLEVEL | VIP levél |
| ZALOGLEVEL | Zálog levél |

#### Archív táblák
| Tábla | Pattern |
|-------|---------|
| ARCHIVE, V_ARCHIVE, Z_ARCHIVE | Archív fő adatok |
| SIGN_ARCHIVE, VSIGN_ARCHIVE, Z_SIGN_ARCHIVE | Archív aláírások |
| LASTYEAR típusú | Előző évi adatok |

### I.6.3 `VTEMP` szerepe

Az egyik legfontosabb architekturális elem:
- shell → DLL paraméterátadás
- tranzakció közbeni ideiglenes állapot
- nyomtatáshoz szükséges metaadatok átadása
- napzárás és egyéb funkciók paraméterezése
- lényegében egy köztes munkatábla, amelyre a modulok implicit szerződéssel támaszkodnak

---

## I.7. TRADE Alrendszer (Kereskedés)

**Projektfájl:** `VALUTA/TRADE/fejleszt/trade.dpr`

### I.7.1 Form-ok

| Unit | Form | Funkció |
|------|------|---------|
| unit1 (55K) | — | Fő kereskedési logika, supervisor, matrica |
| unit2 (49K) | TELEFONFORM | Telefonos rendelés kezelés |
| unit3 (65K) | AUTOPALYAFORM | Autopálya/útvonal keresés (ország-megye) |
| unit4 (11K) | MATRICANYOMTATO | Matrica nyomtatás |
| unit5 (7K) | GETPENZTAROS | Pénztáros név lekérdezés |
| unit8 (3K) | UJTANUSITVANY | Új tanúsítvány |
| unit9 (5K) | GETTANUSITVANY | Tanúsítvány lekérdezés |
| unit10 (21K) | PAYSAFEFORM | PaySafe kártya kezelés |
| unit11 (27K) | ZARAS | Zárás |
| unit12 (51K) | SELECTCOUNTY | Ország/megye választó |
| unit13 (5K) | LOGOLVASAS | Log olvasás |
| unit14 (2K) | ADATKULDES | Adatküldés (szerver felé) |

### I.7.2 Funkcionális fókusz
- telefonfeltöltés (T-Mobile, Telenor, Vodafone, T-Com, NeoPhone, Tesco)
- autópályamatrica (seller/customer copy, egyszerűsített számla)
- Paysafe (vevőpéldány, saját példány)
- tanúsítványkezelés
- logolvasás
- elektronikus kereskedési interfész
- archíválás (régi `TRAD*` táblák adatritkítása)

### I.7.3 Indulási folyamat
1. internetellenőrzés
2. alapadatok beolvasása
3. havi TRADE tábla biztosítása
4. logfájl előkészítése
5. matrica összesítő regenerálása
6. tanúsítvány-ellenőrzés
7. pénztáros belépés
8. cikktörzs betöltése

### I.7.4 Szerveres integrációi
- HTTP hívás kupon/topup oldalra
- FTP kapcsolat tanúsítvány letöltéshez
- Java helper `Coupon.exe`
- remote Firebird `MATRICA.FDB`

### I.7.5 Könyvelési logika
Könyvelés havi `TRADyyMM` táblákba. Mentett mezők: típus, bizonylatszám, kategória, tranzakció, ügyféladatok, fizetendő, pénztáros neve, dátum, idő, szolgáltatás/szolgáltató.

---

## I.8. Bizonylatok, Nyomtatás, Dokumentumtípusok

### I.8.1 Közös nyomtatási pipeline

1. szöveg generálása `c:\valuta\aktlst.txt` vagy hasonló fájlba
2. ESC/P vagy hasonló vezérlőkódok beszúrása
3. `LPT1` vagy Windows printer használata
4. fájl tartalmának kiküldése a nyomtatóra

### I.8.2 Fő bizonylattípusok

- `V` - valuta vételi bizonylat / számla
- `E` - valuta eladási bizonylat / számla
- `F` - pénztári átadási bizonylat
- `U` - pénztári átvételi bizonylat
- storno bizonylat
- stornozott bizonylat másolat
- címletezési lista
- átadólap
- WU nyugta
- telefonfeltöltés bizonylat
- autópályamatrica bizonylat
- egyszerűsített számla
- Paysafe saját és vevőpéldány
- különféle listák és összesítők

### I.8.3 A `BLOKNYOM` központi szerepe

Fő formatter: `Anti\VALUTA\DLL\BLOKNYOM\MAKEDLL\Unit2.pas`

Kezelt nyomtatások:
- `VetelSzamlaNyomtatas`, `EladasSzamlaNyomtatas`
- `AtadBlokkNyomtatas`, `AtveszBlokkNyomtatas`
- `StornoBlokkNyomtatas`
- árfolyammódosítási nyomtatás
- reklám / ügyfél / nyilatkozat típusú nyomtatások
- devizastátusz nyomtatás

### I.8.4 Bizonylat tartalmi elemei

Jellemző mezők: cégadatok, pénztárkód, pénztárnév, cím, adószám, terminál azonosító, bizonylatszám, dátum/idő, ügyféladatok, jogi személy adatok, okmány adatok, pénznem, árfolyam, bankjegyösszeg, forintérték, kezelési díj, megjegyzés, reprint indok, storno indok, engedélyező, társpénztár neve, forrás.

### I.8.5 Átadólapok

#### Értéktári átadólap
Tartalma: értéktárszám, dátum, átadó, átvevő, pénzkészlet egyezés/eltérés, tartozások, követelések, WU/ÁFA rendelések, banki beszállítás/kiszállítás, pénztári rendelések, körlevelek, egyéb fontos információk.

#### Pénztári átadólap
Tartalma: pénztárszám, dátum, átadó, átvevő, körlevelek, ügyfélrendelések, készletrendelés értéktár felé, konkurenciával kapcsolatos tudnivalók, egyéb tudnivalók.

### I.8.6 Western Union bizonylatok

Típusok: átvétel/átadás exclusive cash pénztártól/nak, átvétel/átadás WU pénztártól/nak, pénzátvétel/átadás ügyféltől/nek.

Jellemző adatok: bizonylatszám, MTCN szám, dátum/idő, átadott/átvett összeg és devizanem, szállító neve, zsákplombaszám, aláírási mezők.

---

## I.9. Pénztár, Értéktár, Főértéktár Logika

### I.9.1 Pénztár
- pénztárcentrikus rendszer
- minden kasszához kód, név, cím, telefon tartozik
- ha nincs pénztáradat, a program leáll

### I.9.2 Értéktár
Az értéktár a kasszát ellátó és összesítő szereplő:
- értéktárszám bekérése induláskor
- `ERTEKTARI ATADOLAP`
- pénzkészlet egyezés/nem egyezés/eltérés logika
- tartozások és követelések
- banki beszállítás és kiszállítás

### I.9.3 Főértéktári / központi logika
- központi árfolyamlogika
- készletkövetés
- banki kapcsolatok
- körlevelek
- engedélyezési és supervisor logika
- **hálózatos treasury modell**

---

## I.10. Riportok és Listák (LISTAK — 48K forrás)

| Funkció | Leírás |
|---------|--------|
| `forgalomdekad` | Forgalom dekád (10 napos) kimutatás |
| `idoszakrutin` | Időszaki kimutatás |
| `kezelesidijdekad` | Kezelési díj dekád |
| `napikonyvelorutin` | Napi könyvelés riport |
| `napikezdijrutin` | Napi kezdeti díj |
| `pillanatnyikeszlet` | Pillanatnyi készlet lista |
| `kulonfelelistak` | Különféle listák főmenü |

Listákon megjelenő adatok: kiadott bizonylatok listája, eladott valuták listája, valutanemek bontásban, ATVETTBANKJEGY/ATADOTTBANKJEGY oszlopok.

---

## I.11. Ügyfél, Compliance, Engedélyezés

### I.11.1 Ügyfélkezelés
Modulok: `UGYFEL`, `KISUGYFEL`, `SENDOKMANY`, `GETWUGYF`
Távoli DB-k: `ugyfelYY.fdb`, `kisugyfel.fdb`

### I.11.2 Terrorlista / Szankciós lista
- Induláskor kötelező ellenőrzés — hiánya leállítja a programot
- `terrlist.dll`, `UNOLLIST` tábla (UNO szankciós lista)

### I.11.3 Ügyfél-azonosítás (KYC)
- **Gongyölet kontroll** (`gongyoletcontrol`) — nagy összegű tranzakció AML
- **Okmány ellenőrzés** (`BigCtrl`, `FirstCtrl`)
- **Irányítószám nélküli** kezelés, **Betű nélküli okmány** kezelés

### I.11.4 FIU Bejelentés (pénzmosás elleni)
- Gyanús tranzakciók bejelentése a Pénzügyi Információs Egységnek
- Bejelentés pénzmosás és terrorizmus finanszírozás
- Pénzügyi és vagyoni korlátozás
- Cégek: `Exclusive Best Change Zrt` / `EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT`

### I.11.5 Engedélyezési logika
- `GETENGED`, supervisor jelszó, kedvezményes árfolyam
- Magasabb jogosultsághoz kötött műveletek

---

## I.12. Szerver Oldali Modulok

### I.12.1 SZERVER/fejleszt (96 modul)

**Árfolyam és forgalom:** arfolyam, _arfteszt, _napiforg, forgdisp, sumrate, sumtrade, sumtablo, summa, sumaxa, havitablo, havitrad, statiszt, trnzstat

**Ügyfélkezelés:** ugyfseek, ugyfelcontrol, nevseek, orsoseek, vevo, vevoszam, jogiszemely, jogi, mendjogi

**Tranzakciók:** tranzacs, tranzdb, tranzdij, etrade, setrade, strade, uforg, ptforg, pttrfee

**Zárások:** gbakall, expgbakall, archival

**Személyzet:** jelenlet, personal, dolgozok, permit, palyadij, jutmend, jutszamito, jutszazalek, kedvmak, verseny, verseny_mend, everseny

**Western Union:** western, westuni, wucontrol, wuniforg, monegram

**Bejelentések és kontroll:** bejelentes, terror, police, recguard, recptor, okmctrl, tiltcopy

**MNB és hatósági:** mnbgyujto, mnbhibak

**Adatkezelés:** import, frissdat, senddata, lemento, napiment, mentes, idbeiro, idpotlo, idprosct, hovalasz, newrate, newyear

**Rendszer:** server, uctrl, www, booking, litenews, tablomak, makeszlt, makiroda, confident, foglalo, korlevel, kereso, banklist, beszam, kamersum, kdchange, remaltib, helga

### I.12.2 SZERVER/ujdll (36 modul)

adatgyujto, arftmk, atlagarf, bankforg, beerkctrl, beerkezes, bejelentes, datadisp, dbookctrl, dolgozok, forgalomdisp, getdisp, getuzlet, hovalasz, hrkserver, idoszak, import, irtmk, jutszamito, jutszazalek, keszletdisp, kezdij, kezdtranzdisp, mnbgyujto, mnbhibak, ptarkozott, stornodisp, sumwuafa, tranzakc, trbdisp, unpacker, userbelep, western, wuafatranz, wunidisp, zarasctrl

---

## I.13. Kamerarendszer

### I.13.1 Camera v2 (camera2/camera — Java Maven multi-module)

| Modul | Java fájlok | Funkció |
|-------|-------------|---------|
| **camera-center** | 6 | Központi kamera vezérlés |
| **camera-cmn** | 6 | Közös osztályok |
| **camera-config** | 29 | Konfiguráció kezelés |
| **camera-film-inspecter** | 4 | Felvétel vizsgálat |
| **camera-film-restorer** | 4 | Felvétel helyreállítás |
| **camera-office** | 136 | Irodai kamera modul (fő) |
| **camera-player** | 49 | Videó lejátszó |
| **camera-updater** | 4 | Frissítés |

**Kamera típusok:** Pénztári kamera (Public) + Intim kamera (Private)

**Export működés (FilmConverterMainThread):**
- filmek exportálása kijelölt könyvtárba
- párhuzamos konvertálás
- opcionális lejátszó export
- opcionális tranzakciós adatexport
- `ExclusivePlayer.exe` másolása exportcsomagba

**Távoli üzenetküldés (MessageService):**
- `http://excupdate.ddns.net:55658/api/sendMail/...`
- office azonosítóval és üzenettel küld jelentést

### I.13.2 Camera v3/old (camera3/old — régi Java ökoszisztéma)

| Modul | Funkció |
|-------|---------|
| excold-camera-server | Kamera szerver |
| excold-camera-local | Helyi kamera (110 Java) |
| excold-camera-remote / remote2 | Távoli kamera |
| excold-camera-film-player | Film lejátszó |
| excold-MNB-exchange-rate-server / server2 | MNB árfolyam szerver |
| excold-circular-letter-server | Körlevél szerver |
| excold-circular-letter-android-client | Körlevél Android kliens |
| excold-management | Menedzsment |
| excold-supervisor | Supervisor |
| excold-sim-manager | SIM kezelő |
| excold-pszaf-server / client | PSZÁF (felügyeleti) szerver/kliens |
| excold-survey-manager-server / client | Felmérés kezelő |
| excold-survey-office-server / client | Irodai felmérés (105 Java) |
| excold-desktop-client | Asztali kliens |
| excold-constraint | Korlátozások |
| excold-coupon | Kupon |
| excold-escan | E-szkenner |
| excold-ocrqrg / ocrqrg2 | OCR / QR olvasó |
| excold-oldcamerafilmcutter / 2 | Film vágó |
| excold-exclusive-change-western-union-inspecter-* | WU ellenőr |
| excold-expressz-ekszerhaz-es-minibank-* | Expressz ékszerház és minibank |
| excold-exclusive-nav-data-provider-server | NAV adatszolgáltató |
| excold-expressz-nav-data-provider-server | Expressz NAV |
| excold-citysim-client / prod | CitySim |

**WU inspecter server (LocalDatabase.java):**
- Firebird JDBC, boltazonosítóhoz kötött lokális `V{shop}.FDB`
- `WUNIyyMM` táblákból olvas, dátumintervallumra gyűjt, stornózottakat kiszűri

---

## I.14. Körlevél Rendszer (KORLEVEL)

**Alkalmazás:** `Korlevel.exe` (1 MB)

A `KORLEVEL_ZIP/korlevel/` mappa tartalmazza:
- **109 bizonylatsablon** (FZS001–FZS073, BT, KI, KZ, SCS, DURU, DA típusok)
- Formátumok: `.odt`, `.docx`, `.pdf`, `.txt`
- ARCHIVE, LASTYEAR, VIP, ZALOG, params almappák

### Bizonylat típusok
| Prefix | Típus | Mennyiség |
|--------|-------|-----------|
| **FZS** | Feljegyzés / bizonylat sablon | ~73 db |
| **BT** | Bizonylat típus | 5 db |
| **KI** | Kimenő irat | 15+ db |
| **KZ** | Közlemény | 2 db |
| **SCS** | SCS bizonylat | 1 db |
| **DURU** | DURU bizonylat | 1 db |
| **DA** | DA bizonylat | 1 db |

---

## I.15. Árfolyam Rendszer, Készletkezelő, Egyéb

### I.15.1 Árfolyam alkalmazás
**Alkalmazás:** `Arfolyam.exe` (1.1 MB)
- `arfdata.dat` (272K), `old_arfdata.dat` (41K), `ujdata.dat` (69K), `ARFDATA.TMP`

### I.15.2 Készletkezelő (KESZLEX)
**Alkalmazás:** `KESZLEX.EXE` (703K)
- 64 pénztár-készlet fájl `PK` prefixszel (737 byte/fájl)
- `FOGLALO.DAT` (2.5K, bináris)

### I.15.3 Egyéb Beállítások (OTHERTSK — 42K forrás)
- Paraméterezes, Adatlap rutin, Bejelentő rutin (FIU), Ügyfél TMK
- OTP terminál, QR display, Supervisor jelszó, COM port beállítás

### I.15.4 Foglalás Rendszer (FOGLALO — 83K forrás)
- foglalorutinok, foglalorendeles, Getarfolyam, logirorutin, copyfiletoftprutin, supervisorjelszo

### I.15.5 Verziófrissítés (VERZFRIS — 35K forrás)
- verziofrissitorutin, SettingNavcom, Navsorszambeiro, TradeModosito, FrissAtnevezes, MakeIdoszakTabla, Mezobovites

### I.15.6 Gépbeállítások (GEPSETUP — 57K forrás)
- Nyomtató, COM port, szkenner típus, szövegszerkesztő, menüpont engedélyezés/letiltás

### I.15.7 Futófény / LED Kijelző (FNYUJSAG)
Telephelyenként egyedi konfiguráció, dupla COM portos és egyszeres változatok.

---

## I.16. Mentés és Adatcsere

### I.16.1 Mentés (MENTES — 4K)
- `valuta.fdb` → `c:\valuta\mentes\lastgood\valuta.fdb`
- `VTEMP` bejegyzés + `sendokmanyrutin`

### I.16.2 FTP Adatcsere
- `COPY2FTP.dll`, `TNMFTP` komponens
- Bizonylatok, napi zárások, statisztikák feltöltése

### I.16.3 Szerver kommunikáció
- `SERVERCTRLPANEL`, `NOSZERVERPANEL`
- `InternetGetConnectedState`, `SetserverAccess`

---

## I.17. Firebird Adatbázis Infrastruktúra

- **Firebird 2.1.1** motor
- **IBManager** adatbázis-kezelő eszköz
- **SYSDBA jelszó módosítás:** `pw.bat` → `gsec` paranccsal
- Mintaadatbázis: `expedvet.fdb` (672K)

---

## I.18. Rendszer Összefoglaló

| Jellemző | Érték |
|----------|-------|
| **Technológia** | Delphi 7 + Java + Firebird |
| **Architektúra** | Moduláris DLL-alapú monolit |
| **Modulok száma** | 109 DLL + 6 EXE + Java ökoszisztéma |
| **Adatbázis** | Firebird/InterBase (3+ DB fájl) |
| **Telepítési útvonal** | `c:\valuta\` |
| **Táblák száma** | 90+ azonosított tábla |
| **Bizonylattípusok** | FZS, BT, KI, KZ, SCS, DURU, DA |
| **Támogatott valuták** | Multi-valuta (ISO kódokkal) |
| **Integrációk** | OTP, Tesco, Metro, Western Union, MNB, NAV, FIU |
| **Kamera** | IP kamera (Public + Private), Java alapú |
| **AML/KYC** | Terrorlista, szankciós lista, FIU bejelentés |
| **Szerep alapú hozzáférés** | Pénztáros + Supervisor (jelszóval) |
| **Offline képesség** | Helyi Firebird DB, FTP szinkron |
| **LED kijelző** | COM port vezérelt futófény, telephely-specifikus |
| **Riportok** | Napi, havi, dekád, éves, kezelési díj, forgalom |
| **Nyomtatás** | Blokk nyomtató, QR kód, matrica, címlet lista |

---

# ══════════════════════════════════════════
# RÉSZ II: MODERNIZÁCIÓS VÉGREHAJTÁSI UTASÍTÁS
# ══════════════════════════════════════════

> Forrás: `VALUTA-VEGREHAJTASI-UTASITAS.md` — teljes tartalom

---

## II.1. Rendszer Áttekintés

- **Építsd újra az Anti (Delphi7) valutaváltó rendszert** modern Java+React stack-re.
- **Fő modulok**:
  - Klasszikus valutaváltás (vétel, eladás, konverzió)
  - Napnyitás/zárás, havi zárás, címletezés
  - Pénztárak közti átadás/átvétel
  - Western Union és kereskedelmi bővítések
  - Bizonylatkezelés, nyomtatás, riport, compliance
  - Integráció: kamera, szerverek, külső API
- **Backend**: REST API, PostgreSQL, transzparens napállapotgép
- **Frontend**: React SPA, desktop wrapper Electronnal, teljes menümodellel
- **Adatmodell**: relációs
- Szigorú napállapot és jogosultságkezelés
- Backend URL: `https://excvaluta.com/api/v1/`

## II.2. Üzleti Folyamatok Specifikáció

### II.2.1. Valuta Vétel
1. Tranzakciós tábla előkészítése (`vtemp`-nek megfelelő)
2. Ügyfél/partner adat bekérés
3. Árfolyam lekérdezése, vételi paraméterek generálása
4. Címletezés, jutalék, összeg számítása
5. Bizonylat (számla) létrehozása
6. Könyvelés adatbázisba
7. Készlet állapot frissítés
8. Nyomtatás triggerelése
- Legacy referencia: vasarlas.dll, FORM1

### II.2.2. Valuta Eladás
1. Tranzakciós tábla előkészítése
2. Ügyfél/partner/ellenőrzés
3. Aktuális eladási árfolyam olvasása
4. Bizonylat mezők elkészítése
5. Könyvelés
6. Nyomtatás
- Legacy referencia: eladas.dll

### II.2.3. Konverzió
1. Vétel+eladás felület és logika
2. `konverzio=true` flag a folyamatban
3. Mindkét művelet auditja, bizonylat kezelése
- Legacy referencia: UJKONVERZIO, vasarlas.dll

### II.2.4. Pénztárak között Átadás/Átvétel
1. Forrás/cél pénztár kiválasztás
2. Mozgás rögzítése
3. Bizonylatkezelés két példányban (átadó, átvevő)
4. Készlet/jutalék/ellenőrző folyamatok
- Legacy referencia: atadvet.dll, atadolap.dll

### II.2.5. Sztornó
1. Stornózni kívánt tranzakció visszakeresése
2. Ok, státusz rögzítése, storno bizonylat generálása
3. Minden kapcsolódó tétel visszaforgatása
4. Bizonylat újranyomtatás, log update
- Legacy referencia: storno.dll

### II.2.6. Árfolyam kezelés
1. Lekérdezés/jóváhagyás/szerkesztés/mentés
2. Árfolyam-történet karbantartás
3. Jogosultsághoz kötött módosítás
- Legacy referencia: arftmk.dll, getarf.dll, arfreg.dll

### II.2.7. Pillanatnyi pénztár és készletállás
- Valós, címletbontásos nézet, szűrési opciókkal
- Frissítsd automatikusan (vétel/eladás/átadás után)

### II.2.8. Napi/Havi Zárás
1. Állapot-gép megvalósítás
2. Időszakváltás (hónapváltás) logika
3. Címletezés, ellenőrzések, nyomtatás
4. Integráció terminállal/szerverrel
- Legacy referencia: napzar.dll, havizar.dll, cimlmenu.dll

### II.2.9. Bizonylat Tallózás, Újranyomtatás
- Jogosultság- és indokalapú újranyomtatás

### II.2.10. Riportok, Listák
- Kiadott bizonylatok, napi/havi/pillanatnyi forgalom, TRB-spec, statisztikák
- Export opciók: CSV, PDF, plain text

### II.2.11. Compliance
- Ügyfél, terrorlista, supervisor és engedélyezési kontroll
- Kockázatos művelet jogosultsághoz és felülvizsgálathoz kötve

### II.2.12. Trade & Kiegészítők
- Telefonfeltöltés, matrica, Paysafe/kuponok
- Minden core legacy funkció

## II.3. Menürendszer & Navigáció

- Két oldalas főmenü (9+9 menüpont)
- Tükrözi a legacy FOMENUFORM/dispatch logikát
- Minden üzleti funkció önálló képernyő (React route/component, Electron view)
- Gyorsgombok button-bárban

## II.4. Adatmodell

Implementálandó entitások/táblák:
- **PENZTAR**, **VTEMP**, **ÜGYFEL**, **JELENLET**
- **BLOKKFEJ**, **BLOKKTETEL**, **PENZTARFORGALOM**
- **ÉRTÉKTÁR**, **TRADyyMM**, **TERRORLISTA**
- Minden legacy tábla mappingolva modern, titkosított, auditálható sémára

## II.5. Bizonylat & Nyomtatás

- Minden művelethez saját bizonylatformátum
- **Jogszabályi megfelelés KÖTELEZŐ** (adóigazolvány, összeg, ÁFA zászló, vevő 300k+ adatok, iroda azonosító)
- REST endpoint-on át triggerelhető nyomtatás
- Teljes másolat/storno/újranyomtatási flow

## II.6. Jogosultságok és Szerepkörök

- **Pénztáros:** napi műveletek, sztornó saját tételre
- **Supervisor:** árfolyam, engedélyezés, sztornó minden tételen, napi/havi zárás
- **Admin:** minden művelet
- API endpointok és GUI route-ok role-guard-dal

## II.7. Integrációk

- Kamera (REST/proxy), Remote DB szinkron
- Western Union/OTP terminál
- Topup/matrica/kupon HTTP/FTP
- Export, bizonylat és média küldés

## II.8. Prioritási Sorrend

1. Napnyitás/Napzárás, napállapot-gép, beléptetés
2. Vétel, eladás, sztornó, konverzió full flow
3. Pénztárak közti mozgások
4. Árfolyam és készlet-kezelés
5. Ügyfél/compliance modulok
6. Riportolás, újranyomtatás, lista-funkciók
7. Integrációk (kép, terminál, remote)
8. Kiegészítő szolgáltatások (topup, matrica, paysafe)
9. Admin/dashboard/mentés, migráció/modul export

## II.9. Legacy Referencia Mátrix

| DLL | Funkció |
|-----|---------|
| vasarlas.dll | vétel |
| eladas.dll | eladás |
| storno.dll | sztornó |
| napzar.dll | napi zárás |
| havizar.dll | havi zárás |
| arftmk.dll/getarf.dll/arfreg.dll | árfolyam |
| atadvet.dll/atadolap.dll | átadás/átvétel |
| cimlmenu.dll/cimlnyom.dll | címletezés |
| bizodisp.dll | bizonylat tallózó |
| pillall.dll/pillkesz.dll | készlet |
| prosbe.dll/proski.dll | beléptetés/exit |
| wunion.dll | Western Union |
| terminal.dll | terminál integráció |
| listak.dll | riportok, listák |
| regen.dll | regenerálás |

> **Kötelező:** Minden felsorolt flow és entitás végrehajtása RESTful, stateful, role-guarded és auditált architektúrában.

---

# ══════════════════════════════════════════
# RÉSZ III: MODERNIZÁCIÓS MASTERPLAN ÉS CÉLARCHITEKTÚRA
# ══════════════════════════════════════════

> Forrás: `Anti/ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md` — teljes tartalom

---

## III.1. Executive Summary

A célrendszer nem egyszerű újraírás, hanem:
1. a legacy üzleti működés **megtartása és formalizálása**
2. a gyenge pontok **biztonságos újratervezése**
3. egy **50 valutaváltó irodát** kiszolgáló, magas rendelkezésre állású rendszer felépítése
4. erős **helyi rögzítéssel**, **központi összesítéssel**, **jogosultsági szintekkel**, **hatósági exporttal**, **riportinggal**, **auditálhatósággal**

Ajánlott célállapot:
- helyi telephelyi kliens + helyi adatbázis + helyi kamera rögzítő node
- központi szerver + PostgreSQL + riporting + admin + treasury menedzsment
- biztonságos, webes hozzáférés
- offline-first szinkronizáció
- 50 napos, titkosított helyi videómegőrzés

## III.2. Feltárt Legacy Üzleti Modell

### III.2.1 Core üzleti funkciók
- valuta vétel/eladás/konverzió
- napnyitás/napzárás/havi zárás
- készletlekérdezés, pillanatnyi pénztárállás
- pénztár↔társpénztár pénzátadás, pénztár↔értéktár készletmozgás
- árfolyamkezelés és árfolyamtörténet
- bizonylatnyomtatás és újranyomtatás
- riportok/kimutatások
- terminál/OTP/külső beküldési folyamatok

### III.2.2 Fontos szerepkörök

1. **Pénztáros** — ügyfélkiszolgálás, vétel/eladás/konverzió, bizonylatkiadás
2. **Értéktáros** — pénztárak ellátása, banki beszállítás/kihozatal, értéktár↔pénztár tranzakciók
3. **Főértéktár** — teljes rálátás, árfolyam publikálás, Darius/Raiffeisen jelentések
4. **Területi vezető** — saját irodákra látó, kameraanyag kontrolláltan
5. **Compliance / audit** — napló/export ellenőrzés, hatósági export jóváhagyás
6. **IT admin** — konfiguráció, jogosultságkezelés, szinkron/eszköz/cert kezelés

## III.3. Kritikus Üzleti Szabályok (kötelezően átviendő)

1. **Napnyitás–napzárás státuszgép** — lezáratlan nap kezelése kötelező
2. **Havi zárás függőség** — előző hónap lezáratlansága blokkolhat
3. **Bizonylatolt pénzmozgási lánc** — pénztár/értéktár/bank/főértéktár teljes nyomvonal
4. **Sztornó ellenkönyvelés** — szabályos ellenművelet, nem egyszerű törlés
5. **Árfolyam történet** — ki, mikor, mit, miért módosított
6. **Készlet pillanatkép + készletnapló** — telephelyi és központi szinten
7. **Riportok és újranyomtatás auditja** — minden érzékeny újranyomtatás logolt
8. **Terminál / banki session állapotok** — újrabeléptetés, session-state, hibakezelés
9. **Hatósági export folyamat** — videó + tranzakciós összerendelés + audit

## III.4. Technikai Megfigyelések a Legacy-ból

### III.4.1 Kamera működés
- `PublicCameraThread.java`, `PrivateCameraThread.java`
- `PublicCameraFilmRecorderService.java`, `PrivateCameraFilmRecorderService.java`
- `ExportModel.java`, `ExportController.java`, `InspectionModel.java`
- Két kameraszint: **pénztári kamera** + **intim kamera**

### III.4.2 Helyi videó export
- Film exportálás, lejátszó exportálás, tranzakciós adat export
- Dátumtartomány és bizonylatszám szerinti keresés

### III.4.3 Biztonsági problémák
- Hardcoded jelszó/bypass nyomok
- Gyenge jelszókezelés, obfuszkált de nem valóban biztonságos tárolás
- Nem modern RBAC, audit-grade naplózás hiánya
- Külső DLL-ekben elzárt üzleti logika

## III.5. Darius / Raiffeisen Napi Jelentések

A kódbázisban `Darius` név nem került elő forrásszinten. Az új rendszerben **külön modul**:
- főértéktár által elérhető
- napi automatikus és manuális futtatás
- exportálható, auditált, újrapróbálható
- **Kötelező üzleti tisztázási pont:** discovery workshop kell a bemenő adatmezőkre, formátumra, banki csatornára, SLA-ra

## III.6. Célrendszer — Ajánlott Architektúra

### III.6.1 Alapelvek
- offline-first, security-first, high availability
- role-based, auditálható, telephelyi működésre optimalizált

### III.6.2 Makro-architektúra

```text
[Telephely / Pénztár]
  ├─ Local Desktop Cashier App
  ├─ Local Edge Service
  ├─ Local PostgreSQL / SQLite cache
  ├─ Local Camera Recorder Node
  └─ Secure Sync Agent
           ↓
      [Central Platform]
  ├─ API Gateway
  ├─ Auth / RBAC / MFA
  ├─ Core ERP Services
  ├─ Treasury Services
  ├─ Reporting Services
  ├─ Video Metadata / Export Services
  ├─ Integration Services (Bank / Darius / NAV / stb.)
  ├─ PostgreSQL Cluster
  ├─ Object Storage / Archive
  └─ Monitoring / Audit / Alerting
```

## III.7. Stack Javaslatok

### Opció A — Ajánlott fő stack
- **Backend:** Java 21 + Spring Boot 3
- **Frontend/kliens:** React + TypeScript + Electron
- **Helyi tárolás:** SQLite vagy local PostgreSQL
- **Központi DB:** PostgreSQL
- **Videó:** dedikált edge recorder service + ffmpeg/gstreamer

### Opció B — Microsoft-közeli
- .NET 8 backend + Blazor/WPF/MAUI/Electron hybrid

### Opció C — Teljes web + PWA
- Next.js/React + NestJS/Java backend + edge recorder daemon

**Döntés:** Opció A (Java/Spring + React/Electron + PostgreSQL)

## III.8. Célrendszer Fő Komponensei

### III.8.1 Telephelyi pénztár kliens
login, napnyitás/napzárás, ügyfélkiszolgálás, vétel/eladás/konverzió, bizonylatnyomtatás, készletkövetés, offline queue, központi szinkron

### III.8.2 Telephelyi értéktár kliens
pénztárak kiszolgálása, banki készletmozgások, valuták és HUF mozgatása, készletoptimalizálás

### III.8.3 Főértéktár központi felület
teljes hálózati rálátás, árfolyam publikálás, Darius/Raiffeisen jelentések, hatósági export felügyelet

### III.8.4 Kamera helyi rögzítő node
1+ kamera/telephely, pénztári+intim kamera, 50 nap retention, titkosítás, hash+integritás, bizonylatszám/esemény hozzárendelés

### III.8.5 Központi admin és riport platform
szervezet/telephely/user/role menedzsment, dashboardok, audit logok, export központ

### III.8.6 Integrációs réteg
bank/Darius/Raiffeisen, NAV, OTP terminál, külső ügyviteli rendszerek

## III.9. Adatmodell — Ajánlott Fő Entitások

### III.9.1 Törzs entitások
Organization, Region, Office, CashDesk, Treasury, MainTreasury, User, Role, Permission, Currency, ExchangeRate, ExchangeRateHistory

### III.9.2 Tranzakciós entitások
CashTransaction, CurrencyBuyTransaction, CurrencySellTransaction, ConversionTransaction, CashTransfer, TreasuryTransfer, BankTransfer, DailyOpen, DailyClose, MonthlyClose, Cancellation/Storno, Receipt, ReceiptPrintEvent

### III.9.3 Kamera entitások
CameraDevice, CameraRecorderNode, VideoSegment, VideoSegmentHash, VideoExportRequest, VideoExportArtifact, CameraEvent, CameraAlert, VideoAccessAudit, ChainOfCustodyRecord

### III.9.4 Audit / security entitások
AuditLog, LoginEvent, RoleAssignment, ApprovalRequest, ApprovalDecision, SessionToken, DeviceCertificate, SyncJob, SyncFailure

### III.9.5 Integrációs entitások
DariusDailyReport, DariusDailyReportRun, DariusDailyReportPayload, BankTerminalSession, ExternalExportJob, ExternalExportArtifact

## III.10. Jogosultsági Modell — RBAC

### Szerepkörök
CASHIER, CASHIER_SUPERVISOR, TREASURY_OPERATOR, TREASURY_MANAGER, MAIN_TREASURY, REGIONAL_MANAGER, COMPLIANCE_OFFICER, IT_ADMIN, SYSTEM_ADMIN, AUDITOR

### Jogosultságok minták
TRANSACTION_CREATE, TRANSACTION_CANCEL, CASHDESK_OPEN_DAY, CASHDESK_CLOSE_DAY, TREASURY_TRANSFER_CREATE, BANK_TRANSFER_CREATE, EXCHANGE_RATE_PUBLISH, REPORT_VIEW, REPORT_EXPORT, DARIUS_REPORT_RUN, VIDEO_VIEW_LOCAL, VIDEO_VIEW_REGION, VIDEO_VIEW_GLOBAL, VIDEO_EXPORT, VIDEO_EXPORT_APPROVE, VIDEO_DELETE_FORBIDDEN, USER_MANAGE, DEVICE_MANAGE, CERTIFICATE_MANAGE

### Alapelvek
- deny by default
- role + office/region scope
- minden érzékeny művelet auditált
- exporthoz és riportokhoz **4-eyes approval**

## III.11. Kamera Architektúra — Kötelező Célállapot

### Követelmények
- helyi rögzítés, internet nélkül is működjön
- 50 nap tárolás, titkosítva, csak jogosultak nézhessék

### Rögzítés
- óránkénti vagy kisebb szegmensek
- metaadat: office_id, cashdesk_id, camera_id, start/end time, receipt correlation, hash

### Biztonság
- AES-256-GCM at rest, TPM/HSM kulcsvédelem
- szegmens hash lánc, integritás scan, export+visszanézés audit

### Export
- MP4 + manifest + hash + meta, chain of custody, dual approval
- USB/adathordozó export, hatósági formátum

## III.12. Offline-first Adatarchitektúra

### Telephelyen
- minden tranzakció helyben commitálódik
- minden videó helyben tárolódik
- minden változás sync queue-ba kerül

### Központ felé
- aszinkron szinkron, retry, resume, idempotent események, konfliktuskezelés

### Szinkron modell
- Outbox pattern, Inbox deduplication, event versioning, sync watermarkok, per-office queue

## III.13. Központi Szerver Architektúra

### Backend szolgáltatások
- **A) Auth & Identity Service** — login, MFA, session, RBAC, device trust
- **B) CashDesk Service** — napi működés, tranzakciók, bizonylatok
- **C) Treasury Service** — értéktár, banki átadások, készletmozgatás
- **D) Rate Management Service** — árfolyamok, publikálás, történet
- **E) Reporting Service** — riportok, újranyomtatások, exportok
- **F) Video Metadata Service** — keresés, export workflow, chain-of-custody
- **G) Sync Service** — telephelyi sync, konfliktuskezelés
- **H) Integration Service** — Darius/Raiffeisen, NAV, banki kapcsolatok

## III.14. UI / UX Elvek

### Telephelyi pénztár UI
- desktop-first, érintőkijelzős
- billentyűzetes gyors működés, nagy gombok
- hibabiztos bizonylatfolyamat, offline státusz jól látszódjon

### Treasury UI
- készlet és transzferek vizualizációja
- címlet és valutabontás

### Főértéktár / vezetői UI
- dashboardok, készlet térképek, napi riportok, riasztások, export és audit központ

## III.15. Darius / Raiffeisen Riport Modul

### Modulnév
`bank-reporting-service` → `darius-daily-report` + `raiffeisen-export-adapter`

### Funkciók
napi automatikus generálás, manuális újrafuttatás, diff/hibaellenőrzés, beküldési státuszok, exportfájl megőrzés, aláírt audit trail

### Állapotok
CREATED → VALIDATED → APPROVED → SUBMITTED → ACCEPTED / REJECTED / RETRY_PENDING / FAILED_HARD

## III.16. Security Architektúra — Kötelező Minimum

### Videó és helyi tárolás
AES-256-GCM, per-office kulcs, napi kulcsrotáció, hash chain, integritás ellenőrzés

### Hálózat
office edge ↔ center: mTLS, admin: VPN, belső kamera hálózat elkülönítés

### Hozzáférés
MFA kötelező vezetői/admin/export szerepköröknél, scope-olt jogosultságok, rövid életű stream URL-ek

### Web security
TLS 1.3, CSP, HSTS, CSRF védelem, short-lived tokenek, rate limit

### Audit
immutable audit trail, export/visszanézés/törléskísérlet/sikertelen login naplózandó

## III.17. Nem-funkcionális Követelmények

- **Rendelkezésre állás:** telephely helyben működjön központ nélkül, kamera kiesés azonnali riasztás
- **Teljesítmény:** 50 iroda, több pénztár, videó visszakeresés perceken belül
- **Karbantarthatóság:** moduláris, egységes domain model, dokumentált interface-ek
- **Adatbiztonság:** minimalizált secret exposure, titkosított backupok, role scoped export

## III.18. Megvalósítási Stratégia — Fázisok

### Fázis 0 — Discovery és formalizálás
Legacy feltérképezés, Darius pontosítás, role matrix, topológia, compliance szabályok, legacy mapping
**Deliverable:** domain glossary, permission matrix, transaction lifecycle spec, reporting spec, integration contracts

### Fázis 1 — Core domain és adatmodell
PostgreSQL schema, office/cashdesk/treasury/user/rate/transaction modellek, audit/sync/report/video modellek
**Deliverable:** ERD, migration scripts, domain ADR-ek

### Fázis 2 — Auth, RBAC, organization
Identity provider/internal auth, MFA, office/region scoped access, audit login, session management

### Fázis 3 — CashDesk működés
Napnyitás, napzárás, vétel/eladás/konverzió, bizonylatkiadás, sztornó, napi limitlogika, offline queue

### Fázis 4 — Treasury és készlet
Pénzátadás/átvétel, címletezés, készletnézet, banki mozgások, treasury transzferek

### Fázis 5 — Árfolyamkezelés
Publikálás, időzített életbe léptetés, történet, telephelyi cache és szétküldés

### Fázis 6 — Kamera és helyi rögzítés
Recorder node, kameraforrások, helyi titkosított tárolás, 50 nap retention, hash+integritás, receipt/event correlation, export workflow

### Fázis 7 — Központi riport és Darius modul
Napi vezetői riportok, Darius/Raiffeisen napi jelentés, banki/hatósági export, újrafuttatás és diff

### Fázis 8 — Szinkron és resiliency
Outbox/inbox, konfliktuskezelés, reconnect/retry, monitoring, alerting

### Fázis 9 — Hardening + pilot
Penetration/security review, failover tesztek, pilot 1-2 iroda, fokozatos rollout

## III.19. AI Ügynök Végrehajtási Utasítás

### Első szabály
**Ne kezdj kódolni, amíg a discovery artefaktok nincsenek lezárva.**

### Kötelező sorrend
1. Repo split és célarchitektúra létrehozása
2. Legacy mapping (`legacy-function-map.md`)
3. Domain model és ERD (`domain-model.md`, `erd.md`, `rbac-matrix.md`)
4. ADR-ek (stack, offline-first, video storage, reporting)
5. Skeleton (backend, desktop client, edge recorder, shared packages)
6. Auth + org structure
7. CashDesk MVP
8. Treasury MVP
9. Rate Management
10. Video recorder MVP
11. Sync MVP
12. Reporting MVP
13. Darius/Raiffeisen adapter (csak pontos specifikáció után)
14. Hardening

### Kódolási szabályok
- domain-first fejlesztés
- minden kritikus use case-hez acceptance criteria
- minden pénzügyi tranzakció idempotens és auditált
- delete helyett state transition
- minden export és videó hozzáférés külön audit event
- offline queue nélkül NE implementálj telephelyi műveletet
- explicit precision/timezone idő és pénz mezőknél

### TILOS
- legacy jelszókezelés másolása
- hardcoded credential
- központi online függőség telephelyi core műveletekhez
- audit nélküli újranyomtatás / videó export
- role scope nélküli admin nézet

## III.20. Javasolt Repo-struktúra

```text
/ebc-platform
  /apps
    /backend-api
    /desktop-cashier
    /desktop-treasury
    /edge-recorder
    /admin-portal
    /reporting-worker
    /integration-worker
  /packages
    /shared-types
    /shared-domain
    /shared-ui
    /shared-security
    /shared-sync
  /infra
    /docker
    /k8s
    /terraform
  /docs
    /adr
    /domain
    /legacy-mapping
    /runbooks
```

## III.21. Elfogadási Kritériumok

### Core működés
- [ ] pénztári műveletek internet nélkül is működnek
- [ ] napnyitás/napzárás teljesen kontrollált
- [ ] sztornó auditálva működik
- [ ] értéktári folyamatok működnek
- [ ] árfolyam publikálás központból működik

### Kamera
- [ ] helyi videórögzítés stabil
- [ ] 50 nap retention működik
- [ ] titkosított tárolás bizonyított
- [ ] jogosultság nélküli hozzáférés kizárt
- [ ] hatósági export működik

### Központ
- [ ] vezetői dashboard működik
- [ ] riportok működnek
- [ ] Darius/Raiffeisen riport működik
- [ ] audit trail visszakövethető

### Security
- [ ] MFA és RBAC működik
- [ ] mTLS sync működik
- [ ] exportok 4-eyes approval alatt vannak
- [ ] minden kritikus művelet auditált

### Operáció
- [ ] 50 telephelyes skála terhelés alatt validált
- [ ] monitoring és alerting működik
- [ ] backup/restore tesztelt
- [ ] rollout runbook kész

## III.22. Legacy Bizonyítékok / Hivatkozási Nyomok

### Fő legacy valutaváltó
- `VALUTA\IBVALTO\IBVALTO.DPR`
- `VALUTA\TRADE\fejleszt\trade.dpr`
- `VALUTA\DLL\...`

### Kamera
- `camera2\camera\camera-office\...\PublicCameraThread.java`
- `camera2\camera\camera-office\...\PrivateCameraThread.java`
- `camera2\camera\camera-office\...\ExportModel.java`
- `camera2\camera\camera-office\...\ExportController.java`

### Security / center
- `camera2\camera\camera-center\...\SecurityConfiguration.java`

### DB / Reporting
- `VALUTA\TRADE\fejleszt\database\trade.gdb`
- `camera3\old\excold-exclusive-nav-data-provider-server\...`
- `camera3\old\excold-exclusive-change-western-union-inspecter-server\...`

---

# ══════════════════════════════════════════
# RÉSZ IV: ÚJ RENDSZER AKTUÁLIS ÁLLAPOT (GAP ANALYSIS)
# ══════════════════════════════════════════

> Forrás: `ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md` utolsó szekciója — Kód alapú funkcionális terv

---

## IV.1. Új Architektúra és Stack

- **Backend (API):** Java / Spring Boot (Hibernate/JPA, Flyway migrációk)
- **Adatbázis:** PostgreSQL, szigorú relációs sémák, audit logolás
- **Frontend (Kliens):** React (TypeScript) Vite alkalmazás
- **Offline-First Szinkronizáció:** SyncInboxEvent, SyncOutboxEvent, SyncLog
- **Asztali futás:** penztar-client (Electron) — hardver kezelés

## IV.2. Megvalósított Modulok (Kód Alapján)

### IV.2.1 Alap Üzleti Folyamatok
- Transaction, TransactionLine, TransactionItemBanknote (címletezés)
- StornoApproval, Receipt, ReceiptSequence
- CashBalance, DenominationBalance, DenominationCount
- CashRegisterEvent, CashDeskBreak

### IV.2.2 Értéktár és Hierarchia
- Branch, Company, OwnCompany, BranchStatus
- VaultTransfer, VaultDistribution, VaultCollection, VaultBankTransaction
- ShipmentRequest, CashTransportPackage

### IV.2.3 Biztonság, Jogosultság és RBAC
- Worker, Employee, Role, Permission, Authorization
- WorkerRoleAssignment, WorkerSession
- AuditLog, ErrorLog, AuthorizationLog, PasswordLog
- @EntityListeners(AuditingEntityListener.class)

### IV.2.4 Árfolyamkezelés
- ExchangeRateMaster, ExchangeRate, ExchangeRateSource
- RateApproval, RatePublication, RateHistory
- RateDiscount, CompetitorRate

### IV.2.5 AML és Biztonság
- Customer, CustomerScreeningLog
- ProhibitedPerson, ProhibitedCompany, SanctionEntry, SanctionScreeningLog
- AmlCheck, AmlThreshold, AmlReport

### IV.2.6 Kamera Integráció
- CameraConfig, CameraRecording
- CameraTransactionLink (bizonylat↔videó összerendelés)
- CameraAccessLog

### IV.2.7 Zárások és Adatszolgáltatás
- DailySession, DailyClosing, MonthlyClosing, ClosingWizard, EveningClosing
- MnbReport, MnbReportLine, NavClosing, DecadeReport
- HandlingFeeDecadeReport, DataCollection

### IV.2.8 Western Union
- WuTransaction, WuCustomer, WuBalance

## IV.3. Gap Analysis — Legacy vs. Új

### Ami sikeresen átemelésre került
- Valuta adás-vétel és címletezés adatmodell robusztus
- Pénztár↔Értéktár↔Bank hierarchia struktúra megvan
- AML és szankciós listák automatikus szűrése dedikált táblákkal (fejlődés!)
- Kamera és tranzakció összekapcsolása (CameraTransactionLink) előkészített
- Árfolyamkezelés sokrétűbb (kedvezmények, konkurencia, MNB szinkron)

### Ahol további fejlesztés szükséges

1. **Valós idejű hardver vezérlés hiánya:**
   Legacy: Java app közvetlenül vezérelte IP kamerákat és asztali hardvereket. Új: adatbázis szinten előkészítve (LedDisplay, PosTerminal, CameraConfig), de helyi hardver kommunikáció még nincs integrálva. → penztar-client (Electron) környezetben kell megvalósítani.

2. **Kamera videók helyi fizikai rögzítése és titkosítása:**
   CameraRecording tábla megvan, de 50 napos helyi perzisztencia és AES-256-GCM titkosítás a lokális gép szoftverének (Local Daemon) feladata.

3. **Offline-First Végrehajtás és Szinkron:**
   SyncInbox és SyncOutbox táblák léteznek, de el kell dönteni: "Helyi módban" is telepítünk-e Spring Boot-ot minden pénztárgépbe, vagy vékonyabb helyi réteget írunk.

4. **Darius / Raiffeisen specifikus napi jelentések:**
   MnbReport és NavClosing implementálva, de bank-specifikus struktúrák kód szintű nyomai kevésbé dominánsak.

## IV.4. Akcióterv a Teljes Kompatibilitáshoz

1. **Hardver integrációs réteg véglegesítése:** penztar-client-ben IP kamera, LED kijelző, blokknyomtató natív vezérlés
2. **Helyi videókezelő motor:** RTSP stream elkapás, tranzakció-vágás, helyi titkosítás, metaadat küldés felhőbe
3. **Offline-Sync Engine tesztelése:** szimulált hálózati szakadás mellett pénztárnyitás, váltás, címletezés tesztelés
4. **Banki riportok illesztése:** Raiffeisen és Darius API generálás, fájl export formátum egyeztetés

---

**Összegzés:** Az új backend kód részletes, az adatmodell lefedi és sok esetben túlszárnyalja a legacy rendszert (különösen AML, Audit és struktúra terén). A fő kihívás a **fizikai asztali peremhálózat (Edge/Local)** biztonságos és stabil működésének összekötése a modern backenddel.

---

*Ez a dokumentum a teljes Valutaváltó rendszer egyetlen, egységes referenciája. Használható: funkciótérképnek, legacy audit alapnak, modernizációs inputnak, AI ügynök vagy fejlesztő handoff dokumentumnak.*
