# Modul: Régi Delphi valutaprogram — Kezelési költség, címletezés, engedélyezés  (forrás: Képernyőképek/Kezelési költségek.JPG, Kezelési költségek címletezése.jpeg, Cimletezés menü.jpeg, ERB Egyedi kötés.JPG, Havi tabló.JPG, Tranzakció engedélyeztetése.jpeg, Ügyfél országos ellenőrzése és engedély kérés tranzakciókra.jpeg, Ügyfél országos ellenőrzése és tranzalció engedélyezése .jpeg, Vásárlás email elküldve üzenet.jpeg)

## 1. Cel (egy mondat)
A régi valutaprogram kezelési-költség-menü, címletezés (kezelési díj + zárás), egyedi kötés (ERB), havi tabló, valamint az ügyfél országos ellenőrzése + tranzakció-engedélyezés és a vásárlás-email-visszajelzés képernyői hűen leírva.

## 2. Scope
### IN
- "KEZELÉSI KÖLTSÉGEK" menü.
- "KEZELÉSI KÖLTSEG CIMLETEZÉSE" címletező rács (valuta + címletek + összesítés).
- "Címletezés" menü (zárások).
- "EGYEDI KÖTES RB" (ERB) szállítás-űrlap.
- "HAVI TABLÓK KIJELZÉSE" főmenü.
- "TRANZAKCIÓ ENGEDÉLYEZÉSE" + "AZ ÜGYFÉL ORSZÁGOS ELLENŐRZÉSE" panel (10 millió feletti).
- "AZ E-MAILEKET SIKERESEN ELKÜLDTEM" megerősítő üzenet vásárlás közben.
### OUT
- A bizonylat/nyugta nyomtatott tartalma.
- A teljes valuta-törzs (a címletező csak a megjelenített valutákat mutatja).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | Kezelési díj átvétel/átutalás/jelenlegi készlet, címletezés, vásárlás | TBD |
| Engedélyező (vezető) | "Engedély megadása" / "Nem engedélyezett" 10M feletti tranzakcióra; "Engedélyező" mező kitöltése | TBD (jelszó/azonosító az "Engedélyező" sárga mezőbe) |
| Belsőellenőr / Vezető | Havi tabló statisztika, forgalom, Excel-export | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-KC-01 | "KEZELÉSI KÖLTSÉGEK" menü tételei: "KEZELÉSI KÖLTSÉGEK ÁTVÉTELE", "KEZELÉSI KÖLTSÉGEK ÁTUTALÁSA", "A KEZELÉSI KÖLTSÉGEK JELENLEGI KÉSZLETE", "BIZONYLATOK MEGTEKINTÉSE", "VISSZA". | Kezelési költségek.JPG | M | penztar-client |
| FR-KC-02 | "KEZELÉSI KÖLTSEG CIMLETEZÉSE" képernyő: bal oldalon valuta-lista (VNEM + magyar név + checkbox/jelölőnégyzet oszlop). Megfigyelt valuták: AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF (kiemelt/piros), ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD. | Kezelési költségek címletezése.jpeg | M | penztar-client |
| FR-KC-03 | A címletező jobb oldalán címlet-soronkénti darabszám-bevitel HUF-ra: 20 000-es, 10 000-es, 5 000-es, 2 000-es, 1 000-es, 500-as, 200-as, 100-as, 50-as, 20-as, 10-es, 5-ös (+ 2-es, 1-es szürkített). A darabszám × címletérték = részösszeg oszlop. Példa: 10 000-es ×1 = 10 000; 2 000-es ×2 = 4 000; 200-as ×2 = 400; 5-ös ×1 = 5. | Kezelési költségek címletezése.jpeg | M | penztar-client |
| FR-KC-04 | A címletező alul összesít: "HUF 14 405" (darabszámok szerinti és kiszámolt összeg egyezik); gomb: "CIMLETEK RENDBEN - TOVÁBB"; ablakbezáró "X". | Kezelési költségek címletezése.jpeg | M | penztar-client |
| FR-KC-05 | "CIMLETEZÉS - ZÁRÁSOK" képernyőn "Címletezés" almenü: "ESTI ZÁRÁS CÍMLETEZÉSE", "KEZELÉSI DÍJ CÍMLETEZÉSE", "WESTERN UNION CÍMLETEZÉSE" (szürkített), "ÁFA PÉNZTÁR CÍMLETEZÉSE" (szürkített), "FOGLALÓ KÉSZLET CÍMLETEZÉSE" (szürkített), "ELEKTROMOS KERESKEDÉS CIMLETEZÉSE" (szürkített); gombok: "VISSZA", "KILÉPÉS". | Cimletezés menü.jpeg | M | penztar-client |
| FR-KC-06 | A "CIMLETEZÉS - ZÁRÁSOK" háttér-menü tételei (részben takart): "KÜLÖNFÉLE CÍ..." , "CÍMLETEK KIN..." , "A MAI NAPI ZÁRÁS ...", "A HAVI ZÁRÁS VÉ...", "MÉGSEM". | Cimletezés menü.jpeg | C | penztar-client |
| FR-KC-07 | "EGYEDI KÖTES RB" (ERB) szállítás-űrlap mezői: TÁRSPÉNZTÁR = ERB / EGYEDI KOTES RB, SZÁLLÍTÓ NEVE, PLOMBASZÁM, MEGJEGYZÉS; gombok: "KÖNYVELHETŐ", "MÉGSEM". | ERB Egyedi kötés.JPG | S | penztar-client |
| FR-KC-08 | "HAVI TABLÓK KIJELZÉSE" képernyő: egység (pl. GYULA) + időszak (2024 MÁRCIUS). "HAVI TABLÓ FŐMENÜJE" tételei: "HAVI STATISZTIKA", "HAVI FORGALOM", "FORGALMI GRAFIKONOK", "VALUTA KÉSZLETEK", "FORGALOM-EXCEL KÉSZÍTÉSE", "KÉSZLET-EXCEL KÉSZÍTÉSE", "VISSZA A FŐMENÜRE". | Havi tabló.JPG | S | penztar-client |
| FR-KC-09 | A havi tabló jobb oldalán "KIJELZETT HÓNAP" (év + hónap legördülő + "HÓNAP RENDBEN") és "VALUTAVÁLTÓ EGYSÉG" (pl. GYULA) választó. | Havi tabló.JPG | S | penztar-client |
| FR-KC-10 | "AZ ÜGYFÉL ORSZÁGOS ELLENŐRZÉSE" panel az ügyfél-adatlap felett: mezők ÜGYFÉL NEVE, SZÜLETÉSI CSALÁDI- ÉS UTÓNEVE, LEÁNYKORI, ANYJA NEVE, SZÜLETÉSI HELY. Példa: <NEV>, anyja <ANYJA_NEVE>, szül. hely <SZUL_HELY>. | Tranzakció engedélyeztetése.jpeg, Ügyfél országos ellenőrzése ... .jpeg (mindkettő) | M | penztar-client |
| FR-KC-11 | "TRANZAKCIÓ ENGEDÉLYEZÉSE" panel: figyelmeztető szöveg "Az ügyfél 10 millió felett vált", "A pénz forrása" legördülő (pl. JÖVEDELEM), "Engedélyező" beviteli mező (sárga), gombok: "Engedély megadása", "Nem engedélyezett". | Tranzakció engedélyeztetése.jpeg, Ügyfél országos ellenőrzése és engedély kérés tranzakciókra.jpeg, Ügyfél országos ellenőrzése és tranzalció engedélyezése .jpeg | M | penztar-client |
| FR-KC-12 | Az ügyfél-azonosító fejléc "TERMÉSZETES SZEMÉLY", listából azonosítás "F5" gyorsbillentyűvel, "Mégsem azonosít" gomb; alul "Állampolgársága" (pl. HU MAGYAR). | Ügyfél országos ellenőrzése és engedély kérés tranzakciókra.jpeg, ... tranzalció engedélyezése .jpeg | S | penztar-client |
| FR-KC-13 | Vásárlás közben rendszerüzenet: ablakcím "ibvalto", szöveg "AZ E-MAILEKET SIKERESEN ELKÜLDTEM", "OK" gomb — vélhetően az engedély-kérő / értesítő email kiküldését erősíti meg. | Vásárlás email elküldve üzenet.jpeg | S | penztar-client |
| FR-KC-14 | A "VASARLAS" képernyő (kontextus) oszlopai: DNEM, VALUTA MEGNEVEZÉSE, ÁRFOLYAM, BANKJEGY, FIZETENDŐ; alul "Kezelési díj 3 %", "Kezelési díj engedmények", "Nettó forint", "Kezelési költség", "Kerekítési kompenzáció", "BLOKKSZÁM" (pl. <BIZONYLAT_SZAM>), nagy "FIZETENDŐ" összeg; gombok "Készen van (End)", "Vissza a főmenüre (Escape)". | Vásárlás email elküldve üzenet.jpeg | C | penztar-client |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-KC-01 | A címletező összege automatikusan frissül a darabszámok alapján, és egyeznie kell a könyvelendő összeggel. | Bevitt darab × címlet = összeg; "CIMLETEK RENDBEN" csak egyezésnél |
| NFR-KC-02 | 10 millió HUF feletti tranzakció engedély nélkül nem könyvelhető. | "Engedély megadása" előtt a tranzakció blokkolt |
| NFR-KC-03 | A pénz forrását kötelező megadni a 10M feletti engedélyezésnél. | "A pénz forrása" legördülő kitöltve |
| NFR-KC-04 | A szürkített címletezés-/zárás-típusok mód-/jogosultságfüggően nem elérhetők. | Szürke = letiltott |

## 6. Adatmodell-erintettseg
- Kezelési költség: külön egyenleg-/forgalom-kezelés (átvétel, átutalás, jelenlegi készlet, bizonylatok). Postgres entitás a kezelési-díj-mozgásokra; SQLite mirror IGEN (offline rögzítés).
- Címletezés: címlet-szintű darabszám rekord valutánként (HUF-példa: 20000..5 + 2,1). Záráshoz/kezelési díjhoz kötött. SQLite mirror IGEN.
- Ügyfél azonosítás + AML: ügyfél entitás mezői (név, születési családi/utónév, leánykori, anyja neve, születési hely, állampolgárság), pénz forrása, engedélyező. AML/Pmt. kötelező adatkör. SQLite mirror IGEN (offline tranzakcióhoz), de PII kezelés körültekintést igényel.
- Tranzakció-engedélyezés: engedély-rekord (engedélyező, pénz forrása, eredmény: engedélyezett/nem). Migráció: a 10M küszöb + engedély-folyamat tárolása — pontos mezők a forrásból részben olvashatók → TBD.

## 7. Fuggosegek
- Belső: vásárlás/eladás tranzakció modul, kezelési díj modul, zárás/címletezés, ügyfél-modul, havi tabló/statisztika.
- Külső: e-mail kiküldés ("AZ E-MAILEKET SIKERESEN ELKÜLDTEM" — vélhetően engedély-kérő/értesítő levél), "ország ellenőrzés" (ÜGYFÉL ORSZÁGOS ELLENŐRZÉSE — vélhetően központi/szankciós/AML lista lekérdezés). Pontos végpont/szolgáltatás a forrásból nem olvasható → TBD.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Kezelési költség / díj | A váltási tranzakcióra felszámított díj (a vásárlás-képen "3 %"). |
| Címletezés | A készlet/kezelési díj/zárás bankjegy- és érme-darabszámra bontása. |
| Egyedi kötés (ERB) | Külön kategóriájú szállítás/mozgás technikai gyűjtő-pénztára. |
| Havi tabló | Havi statisztikai/forgalmi áttekintő (Excel-exporttal). |
| Engedélyező | A nagy összegű (10M feletti) tranzakciót jóváhagyó felelős. |
| Pénz forrása | Az ügyfél által megjelölt forrás (pl. JÖVEDELEM) — AML adatkör. |
| Országos ellenőrzés | Az ügyfél központi/országos (vélhetően AML/szankciós) ellenőrzése. |
| Kerekítési kompenzáció | A HUF 5 Ft-os kerekítésből adódó kompenzációs tétel a fizetendőn. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be mind a 9 forrásképet; rögzítsd pontosan a címlet-sorokat és a 10M engedélyezés folyamatát.
### 9.2 Fazisok
- Fázis 1 — Kezelési költség menü + címletező rács (valuták, címletsorok, összesítés). Acceptance: FR-KC-01..04.
- Fázis 2 — Címletezés/zárás menü + ERB szállítás + havi tabló. Acceptance: FR-KC-05..09.
- Fázis 3 — AML/engedélyezés: ügyfél országos ellenőrzés + 10M engedély + email-visszajelzés. Acceptance: FR-KC-10..14.
### 9.3 Tesztes
- Forrás-kép vs. spec összevetés. A 14 405 / 10M / 3% értékek példa-állapotok, nem kőbe vésett üzleti konstansok (a 10M küszöb mint szabály viszont FR-KC-11/NFR-KC-02 alapján rögzített a forrásban).

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A "pénz forrása" legördülő összes lehetséges értéke (JÖVEDELEM mellett)? | AML adatkör teljessége. | Csak JÖVEDELEM látható kiválasztva. |
| 2 | Az "Engedélyező" mező mit vár (jelszó / azonosító / név)? | Engedély-folyamat. | Sárga beviteli mező, tartalom nem látszik. |
| 3 | Mit küld pontosan az e-mail ("SIKERESEN ELKÜLDTEM") és kinek? | Értesítési/engedélyezési lánc. | Csak a megerősítő üzenet látszik. |
| 4 | Az "országos ellenőrzés" mely külső rendszert/listát hív? | AML/szankciós megfelelés. | Csak a panel-cím látszik. |
| 5 | A 10M küszöb fix-e vagy konfigurálható? | Üzleti szabály paraméterezése. | A szöveg "10 millió felett"; konfigurálhatóság nem látszik. |
| 6 | A teljes valuta-törzs és címlet-készlet (a 28 megjelenített valután túl)? | Hiánytalan címletezés. | Csak a listázott valuták láthatók. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (nem olvasható részek TBD)
- [x] minden TBD jelölt

VERIFIKACIO: FR=14 db, TBD=6 db, érintett csomag(ok)=penztar-client
