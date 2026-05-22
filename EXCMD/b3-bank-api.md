# Modul: Banki API integráció  (forrás: Kósa Tervezés és fejlesztés/Bank API/API_bank.docx)

## 1. Cel (egy mondat)
Külső banki/jegybanki webszolgáltatások (MNB árfolyam-webservice, Raiffeisen Bank API) integrálása a valutaváltó rendszerbe a forrásdokumentumban megadott végpontok alapján.

## 2. Scope
### IN
- MNB árfolyam-webservice integráció (forrás-link: MNB sajtóközlemény az árfolyam-webservice működéséről).
- Raiffeisen Bank API integráció (forrás-link: `https://api.rbinternational.com/api-categories?provider=raiffeisenbank-zrt`).
### OUT
- Konkrét lekérendő/küldendő mezők, import/export adatformátum — a forrás NEM specifikálja → TBD.
- Egyéb bankok (a forrás csak MNB-t és Raiffeisent nevez meg).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| TBD (a forrás nem nevez meg szereplőt az API-kezeléshez) | TBD | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | MNB árfolyam-webservice integráció a hivatalos jegybanki árfolyamok lekérésére (a forrás csak a működés-tájékoztató linket adja meg: MNB sajtóközlemény 2015). | API_bank.docx „mnb" sor + URL | TBD | TBD (vélhetően backend + arfolyam-keszito-client, de a forrás nem mondja → TBD) |
| FR-2 | Raiffeisen Bank API integráció a megadott api-categories végpont szerint (`provider=raiffeisenbank-zrt`). A konkrét kategória/művelet a forrásból nem derül ki. | API_bank.docx „raffeisen" sor + URL | TBD | TBD |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Auth/hitelesítés a banki API-khoz (token/kulcs/OAuth) | TBD — a forrás nem ír auth-módot |
| NFR-2 | Lekérdezési gyakoriság / TTL | TBD |

## 6. Adatmodell-erintettseg
TBD — a forrás nem ír mezőket, entitásokat vagy formátumot. (Postgres entitás/mező: TBD; SQLite mirror: TBD; migráció: TBD.)

## 7. Fuggosegek
- Külső API: MNB árfolyam-webservice (jegybanki SOAP/REST — a link tájékoztató, a protokoll a forrásból nem derül ki → TBD).
- Külső API: Raiffeisen Bank API (`api.rbinternational.com`).
- Belső modul: TBD.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| MNB árfolyam-webservice | Magyar Nemzeti Bank hivatalos árfolyam-lekérő webszolgáltatása (forrás-link szerint). |
| Raiffeisen Bank API | Raiffeisen Bank International fejlesztői API-katalógus, `raiffeisenbank-zrt` provider. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A 2 forrás-URL tényleges API-dokumentációjának feltárása (mely végpontok, mely műveletek, auth) — ez a forrásból hiányzik, külön kutatási fázis kell.
### 9.2 Fazisok (acceptance criteria-val)
- Fázis 1 (MNB): integráció spec tisztázása a webservice doc alapján. AC: TBD a doc feltárásáig.
- Fázis 2 (Raiffeisen): api-categories listából a releváns művelet kiválasztása. AC: TBD.
### 9.3 Tesztes
- TBD — a forrás nem ad acceptance-adatokat. Integrációs teszt mock banki válaszokkal, ha a végpontok tisztázódnak.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | Mely MNB/Raiffeisen műveletek (árfolyam, számla, fizetés)? | A scope teljesen ettől függ | A forrás csak landing-linkeket ad |
| TBD-2 | Import vagy export irány? Adatformátum (XML/JSON/CSV)? | Adatmodell + parser | Nincs a forrásban |
| TBD-3 | Auth mód (kulcs/OAuth/cert)? | Biztonság | Nincs a forrásban |
| TBD-4 | Mely szereplő/csomag használja? | RBAC | Nincs a forrásban |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (az URL-eken túli minden részlet TBD)
- [x] minden TBD jelölt

VERIFIKACIO: FR=2 db, TBD=4 db (+ szétszórt inline TBD-k), érintett csomag(ok)=TBD (forrás nem mondja meg)
