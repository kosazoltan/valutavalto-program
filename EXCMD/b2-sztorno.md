# Modul: Sztornókezelés  (forrás: Felmérés/Valuta/Kósa Szervezés/sztorno.docx; azonos másolat: Felmérés/Valuta/Szervezés/sztorno.docx)

## 1. Cel (egy mondat)
Korábbi valuta vétel/eladás (és kártyás POS) tranzakció szabályozott visszavonása, amely az eredeti vagy — eltérés esetén — az aktuális árfolyamon számítja a visszatérítést, a harmadik napi sztornó után pénzügyi vezetői engedélyhez kötött, és sztornó bizonylatot generál.

## 2. Scope
### IN
- Sztornó kezdeményezése a rendszerben vagy a POS terminálon (forrás: 1. szakasz).
- Eredeti tranzakció azonosítása: időpont, vásárolt/eladott deviza, eredeti árfolyam, összeg (forrás: 1. szakasz).
- Sztornó végrehajtása, visszafizetés az eredeti tranzakció szerint (forrás: 1. szakasz).
- NAV felé sztornó (a bekötött pénztárgép külön művelet nélkül automatikusan kezeli) (forrás: 1. szakasz).
- Napi sztornó-számlálás és a 3. utáni külön engedélyezési folyamat (forrás: 2. szakasz).
- Eltérő árfolyamon történő sztornó: eltérés feljegyzése, felhasználói értesítés, visszatérítendő összeg újraszámítása aktuális árfolyamon (forrás: 3. szakasz).
- POS terminál sztornókezelése: kártyás tranzakció visszahívása + visszatérítés (forrás: 4. szakasz).
- Sztornó bizonylat generálása, nyomtatása, sorszám alapú archiválása (forrás: 5. szakasz).

### OUT
- A pénztárgép NAV-jelentés belső protokollja (a forrás szerint automatikus, nem részletezve) — TBD-1.
- Engedélykérés értesítési csatornája (rendszerben/e-mail/SMS) — a forrás csak "értesíti a pénzügyi vezetőt"-et ír, mód TBD-2.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros ("felhasználó") | Sztornó kezdeményezése, eredeti tranzakció azonosítása, sztornó végrehajtása napi 3 sztornóig (forrás: 1–2. szakasz) | TBD-3 (forrás nem nevez RBAC értéket) |
| Pénzügyi vezető | A 3. utáni sztornó jóváhagyása vagy elutasítása a rendszerben (forrás: 2. szakasz) | TBD-3 |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | Sztornó kezdeményezhető a rendszerben és a POS terminálon | sztorno.docx 1. szakasz | Magas | penztar-client |
| FR-2 | Eredeti tranzakció lekérése és azonosítása: időpont, vásárolt/eladott deviza, eredeti árfolyam és összeg | sztorno.docx 1. szakasz | Magas | penztar-client / backend |
| FR-3 | Sztornó végrehajtásakor a visszafizetés az eredeti tranzakció szerint történik, ha nincs eltérő árfolyam | sztorno.docx 1. szakasz | Magas | penztar-client / backend |
| FR-4 | NAV felé sztornó: a bekötött pénztárgép külön művelet nélkül automatikusan kezeli | sztorno.docx 1. szakasz | Magas | penztar-client (pénztárgép) |
| FR-5 | A rendszer automatikusan számolja a nap folyamán végrehajtott sztornók számát | sztorno.docx 2. szakasz | Magas | backend |
| FR-6 | A 3. sztornó utáni új sztornó előzetesen tiltva; a rendszer külön engedélyt kér a végrehajtáshoz | sztorno.docx 2. szakasz | Magas | backend |
| FR-7 | A rendszer értesíti a pénzügyi vezetőt az engedélyezési kérelemről | sztorno.docx 2. szakasz | Magas | backend |
| FR-8 | A pénzügyi vezető a rendszerben jóváhagyja vagy elutasítja a kérelmet; jóváhagyásnál engedélyezett a sztornó, elutasításnál a további sztornók blokkolva engedélyezésig | sztorno.docx 2. szakasz | Magas | backend / kozponti-client |
| FR-9 | A rendszer ellenőrzi az eredeti tranzakció árfolyamát és a sztornó pillanatában megjeleníti az aktuális valutaárfolyamokat | sztorno.docx 3. szakasz | Magas | penztar-client / backend |
| FR-10 | Ha az aktuális árfolyam eltér az eredetitől, a rendszer rögzíti az árfolyam-különbséget | sztorno.docx 3. szakasz | Magas | backend |
| FR-11 | A rendszer figyelmezteti a felhasználót az árfolyam-eltérésről és automatikusan kiszámítja a visszatérítendő összeget az aktuális árfolyam alapján | sztorno.docx 3. szakasz | Magas | penztar-client |
| FR-12 | Eltérő árfolyamú sztornónál a visszatérítés az új árfolyam szerint történik | sztorno.docx 3. szakasz (forrásban "??" jelölés) | Közepes | backend |
| FR-13 | A visszatérítés készpénzben vagy kártyás visszatérítéssel egyenlíthető ki (POS-ban is) | sztorno.docx 3. szakasz (forrásban "???" jelölés) | Közepes | penztar-client |
| FR-14 | POS terminálon a kártyás tranzakció visszahívása az eredeti adatokkal (árfolyam, fizetett összeg) | sztorno.docx 4. szakasz | Magas | penztar-client |
| FR-15 | POS sztornó az eredeti tranzakció szerint, vagy eltérő árfolyam esetén a 3. szakasz folyamata szerint | sztorno.docx 4. szakasz | Magas | penztar-client |
| FR-16 | Sztornó bizonylat automatikus generálása: eredeti tranzakció adatai (összeg, deviza, árfolyam), sztornó időpontja, alkalmazott árfolyam (ha eltér), árfolyam-különbség | sztorno.docx 5. szakasz | Magas | penztar-client / backend |
| FR-17 | Sztornó bizonylat nyomtatása a visszatérítés pontos összegével | sztorno.docx 5. szakasz | Magas | penztar-client |
| FR-18 | Sztornó bizonylatok sorszám alapú archiválása | sztorno.docx 5. szakasz | Magas | backend |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Napi sztornó-számláló pontossága | A számláló az adott nap végrehajtott sztornóit követi; a 4. sztornótól engedélykötelesség lép életbe (forrás: 2. szakasz) |
| NFR-2 | Bizonylat-sorszám folytonossága | A sztornó bizonylatok sorszám alapján egyértelműen archiválhatók (forrás: 5. szakasz) |
| NFR-3 | Engedélyezés nélkül a további sztornók blokkoltak | Elutasítás után a rendszer megakadályozza a további sztornókat, amíg nincs megfelelő engedélyezés (forrás: 2. szakasz) |

## 6. Adatmodell-erintettseg
A forrás nem nevez meg konkrét táblát/mezőt. A leírtak alapján szükséges fogalmak (entitás-szint a forrásból levezetve, konkrét séma TBD-4):
- Sztornó-rekord: hivatkozás az eredeti tranzakcióra, sztornó időpontja, alkalmazott árfolyam, árfolyam-különbség, visszatérítés összege és módja (készpénz/kártya).
- Napi sztornó-számláló (felhasználónként/napra).
- Engedélyezési kérelem: kérelmező, pénzügyi vezető döntése (jóváhagyás/elutasítás), állapot.
- Sztornó bizonylat sorszámmal.
SQLite mirror: IGEN (penztar-client offline tud sztornózni a forrás szerint, POS-os és rendszer-oldali) — pontos mezőkészlet TBD-4. Migráció szükséges? TBD-4 (a jelenlegi sémához nem hasonlítható ebben a fázisban).

## 7. Fuggosegek
- Külső: NAV (pénztárgép automatikus sztornó-jelentése) (forrás: 1. szakasz).
- Külső: POS terminál / kártyás visszatérítés (forrás: 3–4. szakasz).
- Belső: aktuális valutaárfolyam-forrás a sztornó pillanatában (forrás: 3. szakasz; konkrét MNB/bank-kötés TBD-5).
- Belső: eredeti tranzakció tárolása/lekérdezése; bizonylat-generálás és sorszám-kiosztás.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Sztornó | Korábbi valuta- vagy kártyás tranzakció visszavonása, visszatérítéssel (forrás: 1. szakasz) |
| Eredeti árfolyam | Az az árfolyam, amelyen az eredeti tranzakció történt (forrás: 3. szakasz) |
| Aktuális árfolyam | A sztornó pillanatában érvényes valutaárfolyam (forrás: 3. szakasz) |
| Árfolyam-különbség | Az eredeti és az aktuális árfolyam eltérése, amelyet a rendszer rögzít (forrás: 3. szakasz) |
| Engedélyezési kérelem | A 3. sztornó után a pénzügyi vezetőhöz benyújtott jóváhagyási kérés (forrás: 2. szakasz) |
| Sztornó bizonylat | Generált és nyomtatott dokumentum az eredeti adatokkal, sztornó időponttal, alkalmazott árfolyammal és különbséggel (forrás: 5. szakasz) |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be a `sztorno.docx`-ot mint egyetlen igazságforrást. Ne hasonlíts a jelenlegi kódbázishoz ebben a fázisban.
- Tisztázd a TBD-1..TBD-5 nyitott kérdéseket a megrendelővel a kódolás előtt.

### 9.2 Fazisok (acceptance criteria-val)
- 1. fázis — Alap sztornó: eredeti tranzakció azonosítása + visszavonás eredeti árfolyamon. AC: a kiválasztott tranzakcióra visszatérítés keletkezik az eredeti összeggel, és sztornó bizonylat generálódik (FR-1..FR-3, FR-16..FR-18).
- 2. fázis — Napi limit + engedélyezés: napi számláló + a 4. sztornótól tiltás + pénzügyi vezetői jóváhagyás/elutasítás. AC: a 4. sztornó kísérlet blokkolódik engedélyig; elutasítás után minden további sztornó blokkolt (FR-5..FR-8, NFR-1, NFR-3).
- 3. fázis — Eltérő árfolyam: különbség rögzítése, figyelmeztetés, aktuális árfolyamú visszatérítés-számítás. AC: árfolyam-eltérésnél a visszatérítendő összeg az aktuális árfolyamon számolódik és a bizonylaton megjelenik a különbség (FR-9..FR-13, FR-16).
- 4. fázis — POS sztornó: kártyás visszahívás + visszatérítés. AC: kártyás tranzakció sztornózható az eredeti adatokkal vagy eltérő árfolyam esetén a 3. fázis szabályaival (FR-14, FR-15).
- 5. fázis — NAV: a pénztárgép automatikus sztornó-jelentésének integrációja. AC: TBD-1 tisztázása után (FR-4).

### 9.3 Tesztes
- Egységteszt: napi számláló inkrementálás, 3→4 átmenet blokkolás, engedélyezett/elutasított ág.
- Egységteszt: eredeti vs. aktuális árfolyam visszatérítés-számítás (azonos és eltérő árfolyam).
- Integrációs teszt: sztornó bizonylat tartalma (eredeti adatok + különbség + visszatérítés) és sorszám-folytonosság.
- Negatív teszt: engedély nélküli 4. sztornó tiltása; elutasítás utáni blokk.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | A pénztárgép NAV felé történő automatikus sztornó-jelentésének pontos protokollja | NAV-megfelelőség | A bekötött pénztárgép interfésze és felelősség-határa |
| TBD-2 | A pénzügyi vezető értesítésének csatornája (rendszer/e-mail/SMS) | Engedélyezési folyamat működése | A forrás csak "értesíti"-t ír, módot nem |
| TBD-3 | A pénztáros és pénzügyi vezető konkrét RBAC szerepkör-értéke | Jogosultság-implementáció | A csomag szereplő-listájához kötés |
| TBD-4 | Sztornó/engedélyezés/bizonylat pontos adatmodellje és SQLite mirror mezőkészlete | Tárolás és offline működés | Konkrét entitás/mező-terv |
| TBD-5 | Az "aktuális árfolyam" forrása sztornózáskor (MNB/bank/belső árfolyamtábla) | Helyes visszatérítés-számítás | Árfolyam-forrás és frissesség |
| TBD-6 | Forrásban "??"/"???" jelöléssel ellátott pontok (eltérő árfolyamú visszatérítés módja; készpénz vs. POS kötelezőség) | A megrendelő maga is bizonytalan | Üzleti döntés szükséges |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak a sztorno.docx tartalma)
- [x] minden TBD jelölt
VERIFIKACIO: FR=18 db, TBD=6 db, érintett csomag(ok)=penztar-client, backend, kozponti-client.
