# Junior — Legacy Delphi SZERVER Kódbázis Elemzés
> Dátum: 2026-04-07 | Elemző: Junior (Orchestrator/Fejlesztő)
> Scope: `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\`

---

## 1. Kódbázis Áttekintés

| Metrika | Érték |
|---------|-------|
| Pascal/Delphi fájlok | 4343+ |
| Összes méret | ~129 MB |
| Fő könyvtárak | SZERVER, VALUTA, ERTEKTAR |
| Delphi verzió | Delphi 7, Object Pascal |
| Adatbázis | Firebird (InterBase: TIBDatabase, TIBQuery, TIBTable) |
| Archívumok | 8 db RAR/ZIP (kicsomagolva) |
| Egyedi Form osztályok | 200+ (TForm leszármazottak) |

---

## 2. Főbb Modulok Architektúrája

### SZERVER/fejleszt/server/ (75 fájl — központi szerver)
| Unit | Osztály | Funkció | Méret |
|------|---------|---------|-------|
| unit1.pas | TForm1 | **Fő szerver** — DayBook, BlokFej, BlokTetel kezelés, MNB csík | 37 KB |
| unit29.pas | TADATLEGYUJTES | **Adatgyűjtés** — receptor DB-ből adatlegyűjtés, blokk feldolgozás | 77 KB (LEGNAGYOBB) |
| unit16.pas | TIRODATMK | **Iroda karbantartás** — iroda CRUD, rács, szűrők | 41 KB |
| unit5.pas | TMAKEIMPORT | **Import modul** — bankforgalom, állomány import Excel/DB-ből | 38 KB |
| unit14.pas | TMNBLEGYUJTO | **MNB árfolyam letöltő** — MNB napkezdés, temp tábla, cimtar | 35 KB |
| unit8.pas | TCimletezoForm | **Címletezés** — bankjegy címletek kezelése (14+ edit mező) | 28 KB |
| unit36.pas | TATLAGDISPLAY | **Átlag/marge kimutatás** — valutánkénti átlagok, Excel export | 25 KB |
| unit37.pas | TWuniWafaControl | **WU/WAFA kontroll** — Western Union + WAFA tranzakciók | 20 KB |

### VALUTA/ (tranzakciós DLL-ek)
| DLL modul | Méret | Funkció |
|-----------|-------|---------|
| ATADVET | 135 KB | Átvétel/átadás (a legnagyobb üzleti logika) |
| ELADAS | 134 KB | Eladás tranzakció |
| UGYFEL | 111 KB | Ügyfél kezelés |
| VASARLAS | 102 KB | Vásárlás tranzakció |
| ESTIZAR | 91 KB | Esti záras |
| WUNION | 89 KB | Western Union integráció |
| FOGLALO | 81 KB | Foglalás |
| METRO | 73 KB | Metro tranzakciók |
| PILLKESZ | 64 KB | Pillanatnyi készlet |
| BIZODISP | 7 KB | Bizonylat megjelenítés |

### ERTEKTAR/ (értéktár modulok)
| Modul | Méret | Funkció |
|-------|-------|---------|
| penztarak | 97 KB | Pénztárak kezelése |
| atadvet | 85 KB | Értéktári átadás/átvétel |
| pillkesz | 63 KB | Pillanatnyi készlet (értéktár) |
| estizar | 6 KB | Esti záras (értéktár) |
| bloknyom | 6 KB | Blokk nyomtatás |

### VALUTA/TRADE/ (kereskedési modul)
- unit3.pas (63 KB) — fő kereskedési logika
- 25 fájl fejleszt/ alatt
- WU kupon, live/cancel text template-ek

### VALUTA/IBVALTO/ (fő pénztár)
- UNIT1.PAS (68 KB) — InterBase alapú valutaváltó főprogram
- 15 fájl

---

## 3. Architektúrai Jellemzők

### Erősségek (amit tisztelni kell)
1. **Teljes üzleti lefedettség** — 200+ form/class = minden üzleti folyamat implementálva
2. **Robusztus DLL struktúra** — minden tranzakciótípus izolált DLL-ben (ATADVET, ELADAS, VASARLAS, stb.)
3. **MNB integráció** — automatikus árfolyam letöltés
4. **Western Union + WAFA** — teljes pénzküldési integráció
5. **Címletezés** — részletes bankjegy-szintű nyilvántartás
6. **Értéktár szeparáció** — külön modul az értéktár logikának
7. **Excel export** — beépített Excel generálás (OLE automation)
8. **Bizonylat nyomtatás** — komplett nyomtatási alrendszer

### Gyengeségek (amit javítani kell a modernizációban)
1. **God unitok** — unit29.pas (77KB), ATADVET unit2.pas (135KB) = hatalmas monolitikus fájlok
2. **Nincs absztrakció** — üzleti logika közvetlenül a Form osztályokban
3. **Hardcoded DB kapcsolatok** — minden form saját TIBDatabase + TIBTransaction
4. **DLL határok = copy-paste** — debug/ és makedll/ verziók azonos kóddal (ATADVET, ELADAS, stb.)
5. **Magyar változónevek** — IRODARACS, CSIK, INDITO, VISSZAGOMB — lokalizált, de nehezen karbantartható
6. **Nincs verziókezelés** — verzio20/21/22 könyvtárak = manuális verziózás
7. **Nincs tesztelhetőség** — UI-ba ágyazott logika, unit test lehetetlen
8. **Firebird kötöttség** — InterBase komponensek mindenhol

---

## 4. Üzleti Logika Térképezés (Legacy → Modern)

| Legacy Modul | Legacy Form | Modern Megfelelő | Állapot |
|-------------|-------------|-------------------|---------|
| Vásárlás (BUY) | TVasarlasForm / VASARLAS DLL | TransactionService.buy() | Implementálva |
| Eladás (SELL) | TEladasForm / ELADAS DLL | TransactionService.sell() | Implementálva |
| Árfolyam | TARFOLYAMFORM / MNB | ExchangeRateService | Implementálva |
| Címletezés | TCimletezoForm | BanknoteBreakdownService | Implementálva |
| Ügyfél | TUgyfelinput / UGYFEL DLL | CustomerService | Implementálva |
| Napi záras | TNapzarForm | ClosingWizardService | Implementálva |
| Iroda karbantartás | TIRODATMK | BranchService | Implementálva |
| Western Union | TWesternUnionForm / WUNION | WesternUnionService | Implementálva |
| **Értéktár** | ERTEKTAR modulok | **???** | **HIÁNYZIK** |
| **Foglalás** | TFOGLALO / FOGLALO DLL | **???** | **HIÁNYZIK** |
| **Átadás/Átvétel** | TAtadAtvetForm / ATADVET | **???** | **HIÁNYZIK** |
| **Metro** | TMETROFORM / METRO DLL | **???** | **HIÁNYZIK** |
| **Paysafe** | TPAYSAFEFORM | **???** | **HIÁNYZIK** |
| **OTP terminál** | TOTPTERM | **???** | **HIÁNYZIK** |
| **Bizonylat nyomtatás** | TBLOKKNYOM, TNyomtatoForm | **???** | **RÉSZLEGES** |
| **Excel export** | TEXCELFORM, TMAKEEXCEL | **???** | **HIÁNYZIK** |
| **Haszon kimutatás** | THASZONFELVIVOFORM | **???** | **HIÁNYZIK** |
| **Jutalék** | TJUTALEK, TJUTALEKFORM | **???** | **HIÁNYZIK** |
| **Körlevél** | TKORLEVEL | CircularService | Implementálva |
| **Supervisor** | TSUPERVISORFORM | **???** | **RÉSZLEGES** |
| **Kedvezmény** | TKEDVEZMENYLISTA | DiscountService | Implementálva |
| **Stornó** | TSTORNOFORM | ReversalService | Implementálva |
| **MNB lista** | TMNBLISTAK | **???** | **RÉSZLEGES** |
| **Szünet** | TSZUNETKIJELZO | **???** | **HIÁNYZIK** |
| **Engedélyezés** | TENGEDELYADAS | **???** | **HIÁNYZIK** |
| **Havizáras** | THAVIZARAS | **???** | **HIÁNYZIK** |
| **Évnyitás** | TLASTYEARFORM | YearOpeningService | Implementálva |
| **Limit állítás** | TLIMITALLITOFORM | **???** | **HIÁNYZIK** |
| **Tesco** | TTESCOFORM | **???** | **HIÁNYZIK (speciális partner)** |
| **Telefon** | TTELEFONFORM | **???** | **HIÁNYZIK** |
| **Archívum** | TARCHIVEFORM | **???** | **HIÁNYZIK** |
| **Személyi** | TPERSONALBEDOLGOZAS | **???** | **HIÁNYZIK** |
| **Rendszer adatok** | TRENDSZERADATOK | **???** | **HIÁNYZIK** |
| **Zöld menü** | TZOLDMENU | **???** | **HIÁNYZIK** |

---

## 5. Kritikus Felismerések

### A legacy rendszer SOKKAL nagyobb mint a modern
A legacy ~200+ form/DLL, a modern ~30 service. A különbség a hiányzó modulokban van — a legacy teljes pénztári workflow-t fed le (nyomtatástól az Excel exportig), a modern csak a tranzakciós magot.

### DLL architektúra = mikroszolgáltatás a Delphi-ben
A legacy DLL-ek (ATADVET 135KB, ELADAS 134KB, VASARLAS 102KB) önálló üzleti egységek. Ez meglepően modern gondolkodás — minden tranzakciótípusnak saját izolált kódja van.

### Az ATADVET (135KB) a legnagyobb üzleti logika
Az átadás/átvétel (inter-branch transfer) a legbonyolultabb üzleti folyamat — ez a modern rendszerből HIÁNYZIK.

### Receptor = adatgyűjtő szerver
A unit29.pas (TADATLEGYUJTES, 77KB) a receptor — ez gyűjti össze a fiókok adatait a központi szerverre. Ez a modern rendszerben nincs implementálva mert a web API természeténél fogva centralizált.

---

## 6. Összefoglaló

A legacy Delphi kódbázis egy **teljes, érett, 20+ éves üzleti rendszer** ami mindent lefed a pénztári munkától az MNB jelentésekig. A modern rendszer jelenleg a **tranzakciós magot** implementálja (buy, sell, rate, customer, closing), de a legacy ~60%-a még nem lett portolva.

**Prioritási javaslat a hiányzó modulokra:**
1. Értéktár (legnagyobb üzleti gap)
2. Átadás/Átvétel (inter-branch)
3. Bizonylat nyomtatás (napi működéshez kell)
4. Excel export/riportok
5. Havizáras
6. Foglalás
7. Jutalék rendszer
