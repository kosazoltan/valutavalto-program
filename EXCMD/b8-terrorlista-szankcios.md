# Modul: Terror / szankciós lista  (forrás: `Felmérés/Valuta/Terrorlista2008.txt`, `Felmérés/Valuta/Cégcsoport felmérése/Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/Dokumentumok/Terrorlista2008.txt`)

## 1. Cel (egy mondat)
A régi program szankciós/terror-lista állományának STRUKTÚRÁJÁT leírni — EU pénzügyi és vagyoni korlátozó intézkedések alá vont személyek/szervezetek nevét és azonosító-számát tartalmazó plain-text lista, amellyel az ügyfél-átvilágítás (AML) szűr.

## 2. Scope
### IN
- Plain-text (`.txt`) szankciós névlista: fejléc (cégcsoport + év + jogi hivatkozás) + soronkénti tételek.
- Tétel formátum: név (személy vagy szervezet) + opcionális numerikus azonosító-szám (pl. `329`, `3540`).
- Alias/névváltozat-kezelés: ugyanaz az azonosító-szám több névsoron (pl. `'The Base' 329`, `«La Base» 329`, `∆ίκτυο του Οσάµα Μπιν Λάντεν 329`).
- Vegyes karakterkészlet: latin + magyar ékezetes + görög + cirill + diakritikus nevek.
### OUT
- Az árfolyam-/tranzakció-blokkolás üzleti workflow-ja (külön AML modul) — itt csak a lista-formátum.
- A lista frissítési forrása (EU/ENSZ feed) — a fájl 2008-as statikus pillanatkép.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | Szankciós találat figyelmeztetés tranzakció közben | CASHIER |
| Belsőellenőr | Lista karbantartás, találat-felülvizsgálat | INTERNAL_AUDITOR |
| admin | Lista import/csere | ADMIN |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | A lista plain-text állomány, fejléccel: "Exclusive Cégcsoport 2008" + jogi hivatkozás "Az Európai Unió által elrendelt pénzügyi és vagyoni korlátozó intézkedések alá vont személyek, szervezetek." | `Terrorlista2008.txt` 2–4. sor | M | backend, penztar-client |
| FR-2 | Soronként egy tétel: név (szabad szöveg) + opcionális numerikus azonosító-szám a sor végén | `Terrorlista2008.txt` (pl. `'The Base' 329`, `Abbasi-Davani Fereidoun 3780`) | M | backend |
| FR-3 | Vannak azonosító nélküli sorok is (pl. `Sayed Ghias`, `Abd Al Hadi`, `Ali Gufron`, `DHDS`) | `Terrorlista2008.txt` 6–13. sor | M | backend |
| FR-4 | Alias/névváltozat: azonos azonosító-szám több névsoron (név-deduplikáció a számra) | `Terrorlista2008.txt` (329 → "The Base", "La Base", "A Base"...; 3540, 537, 506 stb.) | M | backend |
| FR-5 | Személy- és szervezetnevek vegyesen (pl. szervezet: "A Tamil Eelam Felszabadító Tigrisei 3480", "7th of Tir 3827", "A1 Construction and Trading Co., Ltd 4177") | `Terrorlista2008.txt` | S | backend |
| FR-6 | Multi-script karakterek: latin, magyar ékezetes, görög (`∆ιεθνής...`), cirill, diakritikus; névszűrés ezeket toleráns módon kezeli (normalizálás) | `Terrorlista2008.txt` 27–28. sor stb. | M | backend |
| FR-7 | Névsorrend vegyes: "Vezetéknév Keresztnév" és "Keresztnév Vezetéknév" is előfordul (pl. "ABAS Mohamad Nasir" vs "Abd al-Rahim Abdallah") | `Terrorlista2008.txt` 40–55. sor | S | backend |
| FR-8 | Vezető szóköz/behúzás a sorok elején (formázási zaj, trim szükséges) | `Terrorlista2008.txt` (behúzott sorok) | S | backend |
| FR-9 | A lista mint AML-szűrő bemenet az ügyfél-átvilágításnál (találat → figyelmeztetés/blokkolás) | a fájl szerepe (terror/szankciós lista) | M | backend, penztar-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Karakterkódolás-tolerancia (latin/görög/cirill/ékezet) | név-egyezés Unicode-normalizálással (NFC + diakritika-strip) |
| NFR-2 | Találati teljesítmény tranzakció közben | név-szűrés <200 ms a teljes listán |
| NFR-3 | Fuzzy/alias egyezés a névváltozatok miatt | azonos azonosító alá tartozó alias-ok egy entitásként |

## 6. Adatmodell-erintettseg
- Szankciós entitás: id (lista-azonosító-szám, lehet null), név(ek)/alias-ok, típus (személy/szervezet — a forrásból nem explicit, levezetett → részben TBD), forrás-év (2008).
- Postgres: szankciós lista tábla + alias tábla (1:N a listaszámra).
- SQLite mirror: IGEN (penztar-client offline AML-szűrés a tranzakció előtt). Migráció: TBD (import-pipeline a plain-text → tábla).

## 7. Fuggosegek
- Belső: AML / ügyfél-átvilágítás modul, tranzakció pre-validáció.
- Külső API: jelenleg nincs (statikus 2008-as txt); élesben EU/ENSZ szankciós feed-re cserélendő → TBD.
- Adatbázis: Postgres + SQLite.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Szankciós/terror lista | EU/ENSZ korlátozó intézkedés alá vont személyek/szervezetek |
| Azonosító-szám | A lista belső sorszáma; alias-ok közös számot kapnak |
| Alias | Ugyanazon entitás eltérő név-/írásmód-változata |
| Találat (hit) | Az ügyfél neve egyezik egy listatétellel → AML-figyelmeztetés |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd a `Terrorlista2008.txt` fejlécét + minta-sorokat. Figyeld: vezető szóköz, sorvégi szám opcionális, multi-script.
### 9.2 Fazisok
- F1: Import-parser (FR-1..8) — acceptance: sorok → (név, opcionális azonosító) párok; behúzás trim; azonos azonosító → alias-csoport.
- F2: AML-szűrő integráció (FR-9, NFR-1,3) — acceptance: ügyfélnév normalizált egyezés (NFC + diakritika-strip), találat figyelmeztetést ad.
### 9.3 Tesztes
- Unit: parser azonosítóval/nélkül; alias-dedup (329 → több név); multi-script egyezés (görög/cirill); behúzott sor trim.
- Integration: ügyfélnév-szűrés a teljes listán <200 ms.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | Személy vs szervezet típus megkülönböztetése | szűrési/megjelenítési logika | a txt nem jelöli explicit; névből levezetni kockázatos → TBD |
| 2 | A lista frissítési forrása élesben | 2008-as statikus lista elavult | EU/ENSZ szankciós feed integráció szükséges → TBD |
| 3 | Az azonosító-szám tartomány/jelentése (pl. 1xxx vs 3xxx vs 4xxx blokkok) | esetleges kategória | nem dokumentált → TBD |
| 4 | Pontos egyezés vs fuzzy küszöb | hamis pozitív/negatív arány | a forrás nem ad szabályt → TBD |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció
- [x] minden TBD jelölt
VERIFIKACIO: FR=9 db, TBD=4 db, érintett csomag(ok)=backend, penztar-client
