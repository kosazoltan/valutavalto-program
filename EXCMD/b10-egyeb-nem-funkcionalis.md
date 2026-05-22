# Modul: Egyeb nem-funkcionalis forrasok (szotarak, beosztas, licenc, infra, chat-zaj)  (forras: `Felmérés/Valuta/Kósa Szervezés/Tematikus szótárak/`, `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Segédanyagok Valuta/`, `Delphi Licence árak.xlsx`, `Kósa Szervezés/Névtelen táblázat.xlsx`, `.../képernyőképek 2024.10.24_/`, `.../Képernyőképek/Messenger_creation_*.jpeg`)

## 1. Cel (egy mondat)
A funkcionalis kovetelmenyt NEM hordozo segedanyagok (referencia-szotarak, munkabeosztas, licenc-arak, infra-screenshotok, chat-screenshot zaj) katalogizalasa scope-OUT statusszal.

## 2. Scope
### IN
- Az egyes fajlok kategoria-szintu leirasa + indok, miert OUT.
### OUT
- **Teljes modul OUT.** Egyik forras sem programfunkcio-spec. Szotar=referencia, beosztas=HR-zaj, licenc=beszerzes, infra-kep=uzemeltetes, Messenger=chat-zaj.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| (nincs alkalmazas-szerep) | n/a | n/a (OUT) |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| — | Nincs FR. Egyik forras sem funkcionalis kovetelmeny. | — | — | OUT |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-INF-01 | A "Szerver szolgaltatasok" screenshot szerver-oldali uzemeltetesi referencia | TBD: a kep tartalma nem ertelmezve reszletesen; csak ha uzemeltetes keri |
| NFR-LIC-01 | A regi rendszer Delphi-alapu volt (licenc-arak Delphi 12 Pro/Enterprise/Architect) — a megbizas uj stack (Java/Electron) | TBD: csak kontextus; nincs licenc-kovetelmeny az uj termekre |

## 6. Adatmodell-erintettseg
Nincs (OUT). Migracio nem szukseges.

## 7. Fuggosegek
Nincs alkalmazas-fuggoseg. A szotarak kulso PDF-ek (referencia). A beosztas/licenc HR/beszerzes.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Tematikus szotar | Jogi (angol-magyar) + nyelveszeti szakszotar PDF — forditasi/terminologiai referencia |
| Beosztas | Munkatarsi muszakbeosztas (HR), nem programfunkcio |

## Forras-fajlok katalogus
**A) Szotarak — `Kósa Szervezés/Tematikus szótárak/`:**
- `jogi_angol-magyar.pdf` (~2 MB) — jogi terminologiai referencia.
- `magyar-angol_nyelveszeti_szakszotar.pdf` (~1.1 MB) — nyelveszeti szakszotar.
Indok: forditasi/terminologiai referencia, NEM kovetelmeny. Scope: OUT.
**B) Munkabeosztas — `Kósa Tervezés és fejlesztés/Segédanyagok Valuta/Beosztás 2024 03 hó II Szarvas.ods`:**
Napi muszakbeosztas-tablazat (Bcs Tesco / Bcs Belvaros / Gyula Tesco / Gyula Belv / Szarvas oszlopok, dolgozonkenti 8-18 / 8-17 idosavok, nyitvatartas + munkakezdes/vegzes/szunet). HR-dokumentum. Scope: OUT (nem programfunkcio; legfeljebb tavoli kontextus a nyitvatartas/muszak fogalomhoz, de NEM kovetelmeny).
**C) Licenc — `Delphi Licence árak.xlsx`:**
Delphi 12 Athens Professional/Enterprise/Architect arak (euro + Ft tajekoztato, KERSOFT/Embarcadero). A REGI Delphi-rendszer ujralicencelesere keszult arazas. Az uj termek Java/Electron stack → nem relevans. Scope: OUT (beszerzesi/historikus).
**D) `Kósa Szervezés/Névtelen táblázat.xlsx` (= `Szervezés/Névtelen táblázat.xlsx`, duplikatum):**
Tartalom mindossze: "hianyok 1. verzioban" (egyetlen cella-szoveg, lenyegi adat nelkul). Scope: OUT (ures/jelentektelen). TBD: ha kesobb feltoltik tartalommal.
**E) Infra-screenshotok:**
- `Kósa Szervezés/képernyőképek 2024.10.24_/Szerver szolgáltatások.jpeg` (~7.6 MB) — szerver-szolgaltatasok kepernyokep (uzemeltetesi referencia). NEM olvasva reszletesen (nagy infra-kep). Scope: OUT, TBD ha uzemeltetes keri.
- `.../Személyes találkozó.../nyomtató.jpg` — nyomtato-foto (periferia-felmeres). Scope: OUT (deployment, lasd `b10-hardver-halozati-felmeres.md`).
- `Kósa Tervezés és fejlesztés/.../Ilcsi/Szilvi -spec/speedtest png-k` — gepspec+speedtest (deployment). Reszletes katalogus: `b10-hardver-halozati-felmeres.md`. Itt csak utalas.
**F) Messenger chat-screenshotok (zaj) — `.../Képernyőképek/Messenger_creation_*.jpeg` (8 db):**
Fajlnevek UUID-vegzodessel (`Messenger_creation_2379dd5f-…`, `…26016104-…`, `…2ecc1a32-…`, `…395d793b-…`, `…490e4846-…`, `…53216ab7-…`, `…da19dd8d-…`, `…f00c9b01-…`). **Chat-screenshot zaj** — az instrukcio szerint NEM olvasandok be egyenkent. Scope: OUT. TBD: ha valamelyik megis kovetelmenyt tartalmaz, kulon kerni.

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
Katalogus-stub. NINCS implementacios feladat. Minden forras OUT.
### 9.2 Fazisok (acceptance criteria-val)
- Fazis 0 (egyetlen): rogziteni a scope-OUT statuszt. AC: nincs kodvaltozas; a TBD-k uzleti/uzemeltetes-dontesre varnak.
### 9.3 Tesztes
Nincs (OUT).

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A Messenger-screenshotok tartalmaznak-e kovetelmenyt? | Zajnak feltetelezve | Ha igen, egyenkenti olvasas kulon kerésre |
| 2 | "Szerver szolgaltatasok" kep relevans-e az uj infra-hoz? | Hetzner/Scaleway mar adott | Csak uzemeltetesi osszevetes, ha keri |
| 3 | `Névtelen táblázat.xlsx` feltoltodik-e? | Most ures | Ujra-katalogizalas ha tartalmat kap |
| 4 | Beosztas/nyitvatartas befolyasolja-e a program logikat? | Pl. napi nyitas/zaras idoablak | Valoszinuleg NEM kovetelmeny — uzleti megerosites |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás (nincs FR — OUT)
- [x] 0 hallucináció (fajlnevek + kinyert minimális tartalom alapjan)
- [x] minden TBD jelölt
VERIFIKACIO: FR=0 db, TBD=4 db (+2 NFR), érintett csomag(ok)=NINCS (OUT). Katalogizalt forras: 2 szotar PDF + 1 beosztas ODS + 1 Delphi licenc xlsx + 1 (dupla) Nevtelen xlsx + 2 infra-kep + 8 Messenger jpeg = ~14 fajl (+ utalas a hardver-felmeres png-kre).
