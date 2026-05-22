# Modul: Munkavallalo-nyilvantartas (dolgozoi torzs)  (forras: Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/Képernyőképek/Képernyőképek - Munkavállaló különbségek/{Felhasználónév,Jelszó,Kód,Egyedi jel,Állampolgárság,Bizonyítvány számok,Üzemorvosi vizsgálat,Szabadságok, Gyerekek,Munkaügyi adatok, Fiókok, Jogosultságok}.png)

## 1. Cel
A munkavallaloi (dolgozoi) torzs teljes adatlapjat es fuleit kepkenti hu, AI-ugynok altal vegrehajthato spec-ke konvertalni: szemelyi adatok, azonositok, allampolgarsag, bizonyitvanyok, uzemorvosi vizsgalat, szabadsag/gyerek nyilvantartas, munkaugyi adatok + fiokok/jogosultsagok.

## 2. Scope
### IN
- "Uj munkavallalo felvetele" / "Dolgozok" adatlap (ket forras-rendszer kepernyokepekbol: "Expressz Zalog 1.130-20240216" rozsaszin UI es "Rate Software Licence 1.361.0-20240208" zold UI).
- Mezok: Felhasznalonev, Vezeteknev, Utonev, Jelszo, Kod*, Titulus, Egyedi jel, Allampolgarsag_1*/Allampolgarsag_2, szuletesi nevek (vezetek/kereszt), Anyja vezeteknev/keresztnev, Szuletesi hely*/datum*/ido, Allando lakcim, Tartozkodasi hely, Levelezesi cim (iranyitoszam/telepules/kozterulet/jelleg/hazszam/tovabbi cim adat), "Megegyezik a(z) ... cimmel" checkboxok.
- Igazolo okmanyok tablazat (Igazolo okmany tipusa / azonositoszama / lejarata / Dokumentum neve / Muveletek).
- Bankszamla szama, Iskolai vegzettseg, Bizonyitvany szama; Becsus / Eladoi / Valutapenztarosi bizonyitvany szama + hozzajuk tartozo vegzettseg checkbox.
- Elerhetosegek (Tipus = Email cim... / Elerhetoseg, tobbszorozheto).
- Munkaugyi adatok: Fiokok es jogosultsagok felvitele (Fiok neve / Jogosultsag, fontossagi sorrend), Jogviszony kezdete/vege, Dolgozo statusza, Foglalkoztatas tipusa.
- Szabadsagok tabla (Ev / Athozott / Szabadsag / Szabadsag szamolas / Betegszabadsag / Kivett szabadsag / Kivett betegszabadsag / Tappenz / Fizetes nelkuli szabadsag / Muveletek).
- Gyerekek szekcio (hozzaadasi gomb).
- Egyeb iratok tabla (Dokumentum tipus / Fajl tipus / Hozzaadva / Dokumentum nev / Muveletek).
- Fulek (zold rendszer): Kepesitesek / Iratok / Okmanyok / Cimek / Folyoszamlak / Autok / Uzemorvosi v. / Tappenz / Kapcsolatok / Felhasznaloi megjegyzesek.
- Uzemorvosi vizsgalat tabla (Orvosi vizsgalat allapota / Hatarido datuma / Vizsgalat datuma / Orvosi vizsgalat eredmenye / Megkotes).

### OUT
- A fenti mezok mogotti tenyleges adatbazis-implementacio (kesobbi fazis).
- A ket forras-rendszer kozti egysegesites/lekepezes a celrendszerre (kulon fazis; itt csak a forrast irjuk le).
- Berszamfejtes, NAV-bevallas, fenykep-feltoltes uzleti logikaja (nincs a kepeken).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| admin | Munkavallalo CRUD, jogosultsag-kioszt | TBD |
| Ugyvezeto | Munkaugyi adatok, statusz, jogviszony | TBD |
| Foeertektaros / helyettes | Beosztott dolgozok megtekintes/szerk (TBD scope) | TBD |
| Belsoellenor | Olvasas, ellenorzes (uzemorvosi, bizonyitvany lejarat) | TBD |
| Penztaros / Ertektaros | Sajat adatlap olvasas (TBD) | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-01 | A dolgozonak egyedi `Felhasznalonev` mezoje van (bejelentkezeshez). | Felhasználónév.png | M | backend, frontend |
| FR-02 | A dolgozonak `Jelszo` mezoje van. | Jelszó.png | M | backend, frontend |
| FR-03 | A dolgozonak kotelezo `Kod *` azonositoja van (Szemelyi adatok elso mezo, zold rendszer). | Kód.png | M | backend, frontend |
| FR-04 | A dolgozonak szabadon kitoltheto `Egyedi jel` mezoje van. | Egyedi jel.png | S | backend, frontend |
| FR-05 | Nev-mezok: `Vezeteknev`, `Utonev`/`Keresztnev`, opcionalis `Titulus`, `Szuletesi vezeteknev`, `Szuletesi keresztnev`. | Felhasználónév.png, Kód.png | M | backend, frontend |
| FR-06 | Anyja neve ket mezoben: `Anyja vezetekneve`, `Anyja keresztneve`. | Felhasználónév.png | M | backend, frontend |
| FR-07 | `Szuletesi hely *` es `Szuletesi datum/ido *` (kotelezo, datumvalaszto). | Felhasználónév.png, Kód.png | M | backend, frontend |
| FR-08 | Ket allampolgarsag rogzitheto: `Allampolgarsag_1 *` (kotelezo) es `Allampolgarsag_2` (opcionalis), legordulo valasztoval. | Állampolgárság.png | M | backend, frontend |
| FR-09 | Harom cim rogzitheto: `Allando lakcim`, `Tartozkodasi hely`, `Levelezesi cim`; mindegyik strukturalt (iranyitoszam, telepules, kozterulet, jelleg-legordulo, hazszam, tovabbi cim adat). | Felhasználónév.png | M | backend, frontend |
| FR-10 | "Megegyezik az allando lakcimmel" / "Megegyezik a tartozkodasi lakcimmel" checkbox-ok masolando cimet. | Felhasználónév.png | S | frontend |
| FR-11 | Igazolo okmanyok tablakezelese: `Igazolo okmany tipusa`, `azonositoszama`, `lejarata`, `Dokumentum neve`, sor-muveletek; ures allapot: "Nincs megjelenitheto okmany!". | Bizonyítvány számok.png | M | backend, frontend |
| FR-12 | `Bankszamla szama` mezo. | Bizonyítvány számok.png | S | backend, frontend |
| FR-13 | `Iskolai vegzettseg` legordulo + `Bizonyitvany szama` mezo. | Bizonyítvány számok.png | M | backend, frontend |
| FR-14 | Szakmai bizonyitvanyok kulon: `Becsus bizonyitvany szama` + "Becsus vegzettseg" checkbox; `Eladoi bizonyitvany szama` + "Eladoi vegzettseg"; `Valutapenztarosi bizonyitvany szama` + "Valutapenztarosi vegzettseg". | Bizonyítvány számok.png | M | backend, frontend |
| FR-15 | `Elerhetosegek` tobbszorozheto blokk: `Tipus` (pl. "Email cim") + `Elerhetoseg`, sor hozzaadas/torles. | Bizonyítvány számok.png | S | backend, frontend |
| FR-16 | Munkaugyi adatok: `Fiokok es jogosultsagok felvitele` fontossagi sorrendben ("Az elso a legfontosabb"), soronkent `Fiok neve` + `Jogosultsag` legordulo, hozzaadas/torles. | Munkaügyi adatok, Fiókok, Jogosultságok.png | M | backend, frontend |
| FR-17 | `Jogviszony kezdete`, `Jogviszony vege` datummezok. | Munkaügyi adatok, Fiókok, Jogosultságok.png | M | backend, frontend |
| FR-18 | `Dolgozo statusza` legordulo es `Foglalkoztatas tipusa` legordulo. | Munkaügyi adatok, Fiókok, Jogosultságok.png | M | backend, frontend |
| FR-19 | `Szabadsagok` tabla evenkenti soraival: Ev, Athozott, Szabadsag, Szabadsag szamolas, Betegszabadsag, Kivett szabadsag, Kivett betegszabadsag, Tappenz, Fizetes nelkuli szabadsag, sor-muveletek; hozzaadas gomb. | Szabadságok, Gyerekek.png | M | backend, frontend |
| FR-20 | `Gyerekek` szekcio hozzaadas gombbal (gyermek-rekordok). | Szabadságok, Gyerekek.png | S | backend, frontend |
| FR-21 | `Egyeb iratok` tabla: Dokumentum tipus, Fajl tipus, Hozzaadva, Dokumentum nev, muveletek; ures allapot: "Nincs megjelenitheto dokumentum!". | Szabadságok, Gyerekek.png | S | backend, frontend |
| FR-22 | Uzemorvosi vizsgalat (kulon ful) tabla: Orvosi vizsgalat allapota (pl. "Lezart"), Hatarido datuma, Vizsgalat datuma, Orvosi vizsgalat eredmenye (pl. "Alkalmas"), Megkotes; oszlop-valaszto + kereses + export + lapozas + "Uj" gomb. | Üzemorvosi vizsgálat.png | M | backend, frontend |
| FR-23 | A dolgozoi adatlap a zold rendszerben tovabbi fulekre tagolt: Kepesitesek, Iratok, Okmanyok, Cimek, Folyoszamlak, Autok, Uzemorvosi v., Tappenz, Kapcsolatok, Felhasznaloi megjegyzesek. | Üzemorvosi vizsgálat.png | S | frontend |
| FR-24 | Adatlap-szintu muveletek: `Vissza`, `Mentes`, `Megsem` gombok. | Üzemorvosi vizsgálat.png, Szabadságok, Gyerekek.png | M | frontend |
| FR-25 | Opcionalis ertesitesek: "Szuletesnap ertesites" / "Nevnap ertesites" kapcsolok (zold rendszer). | Kód.png | C | backend, frontend |
| FR-26 | A dolgozoi adatlap fenykep/avatar megjelenites placeholderrel (bal felso kep). | Felhasználónév.png | C | frontend |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-01 | A kotelezo mezok (`*`) vizualisan jelolve (piros keret / csillag). | Kotelezo mezo ures -> mentes blokk + jelzes |
| NFR-02 | Jelszo mezo nem jelenik meg sima szovegkent (PII/biztonsag). | Maszkolt input + nem logolhato |
| NFR-03 | Tablazatos szekciok lapozhatok/keresetok/exportalhatok (uzemorvosi pl. 10/oldal). | Lapozas + kereses mukodik |

## 6. Adatmodell-erintettseg
- Postgres entitas(ok): TBD (forras kepekbol a mezok azonosithatok, a tabla/oszlopnevek a celrendszerben kesobb dolnek el). Erintett fogalmi entitasok: dolgozo/munkavallalo torzs, cim (1:N), igazolo okmany (1:N), bizonyitvany, elerhetoseg (1:N), fiok-jogosultsag (1:N), szabadsag-ev (1:N), gyerek (1:N), egyeb irat (1:N), uzemorvosi vizsgalat (1:N).
- SQLite mirror: TBD (a dolgozoi torzs offline penztaros-oldali szuksege kepekbol nem allapithato meg).
- Migracio szukseges: TBD (uj mezok/tablak eseten igen, de a celrendszer jelenlegi semaja nem resze a forrasnak).

## 7. Fuggosegek
- Belso modul: bejelentkezes/auth (felhasznalonev+jelszo), RBAC (fiok+jogosultsag), dokumentum-tarolas (okmany/irat feltoltes).
- Kulso API: nincs a forrasban (NAV/MNB/bank nem jelenik meg). TBD.
- Adatbazis: dolgozoi torzs + 1:N gyermek-tablak.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Egyedi jel | A dolgozohoz rendelt szabad azonosito/jelzes mezo. |
| Kod | A dolgozo kotelezo egyedi azonositoja (zold rendszer Szemelyi adatok). |
| Igazolo okmany | Szemelyazonosito/igazolo dokumentum tipusa+szama+lejarata. |
| Becsus / Eladoi / Valutapenztarosi bizonyitvany | Szakmai vegzettseget igazolo bizonyitvany szama + megfelelo vegzettseg checkbox. |
| Athozott (szabadsag) | Elozo evrol athozott szabadsag-napok. |
| Uzemorvosi vizsgalat eredmenye | Pl. "Alkalmas"; allapot pl. "Lezart". |
| Foglalkoztatas tipusa | Munkaviszony jellege (legordulo). |
| Fiok + Jogosultsag | A dolgozohoz rendelt rendszer-hozzaferes fontossagi sorrendben. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be mind a 9 kepernyokepet; vedd figyelembe hogy KET kulonbozo forras-rendszer (rozsaszin "Expressz Zalog", zold "Rate Software Licence") kepei keverednek — a mezoket egyseges dolgozoi-torzs spec-be gyujtsd, de NE talald ki a hianyzo leKepezest.
### 9.2 Fazisok (acceptance criteria)
1. Adatlap-vaz + szemelyi/azonosito mezok (FR-01..FR-08): minden mezo renderelodik, kotelezok jelolve. AC: ures kotelezo -> nem menthet.
2. Cimek + okmanyok + bizonyitvanyok + elerhetosegek (FR-09..FR-15): 1:N blokkok hozzaadas/torles. AC: harom cim + masolo checkbox mukodik, okmany-tabla ures-allapot szoveg helyes.
3. Munkaugyi + fiok/jogosultsag + statusz (FR-16..FR-18): fontossagi sorrend megorzodik. AC: jogosultsag sor felvihet/torolheto.
4. Szabadsag/gyerek/egyeb irat (FR-19..FR-21): evenkenti szabadsag-sorok osszes oszloppal. AC: 10 oszlop helyes.
5. Uzemorvosi ful + tovabbi fulek + adatlap-gombok (FR-22..FR-26). AC: uzemorvosi tabla lapozhato/kereseto, Mentes/Vissza/Megsem mukodik.
### 9.3 Tesztek
- Unit: kotelezo-mezo validacio, cim-masolo checkbox logika, szabadsag-szamolas oszlopok jelenlete.
- Integracios: 1:N blokkok (okmany, elerhetoseg, fiok-jogosultsag, szabadsag-ev, gyerek, irat) mentese/visszatoltese.
- E2E/runtime: uj dolgozo felvitel happy path + uzemorvosi vizsgalat sor hozzaadasa.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | Melyik forras-rendszer (Expressz Zalog vagy Rate Software) a mervado a celrendszerhez? | Mezokeszlet/elnevezes eltero a ket UI kozt. | Uzleti dontes / tovabbi forras. |
| 2 | Pontos legordulo-ertekek (Allampolgarsag, Iskolai vegzettseg, Jelleg, Dolgozo statusz, Foglalkoztatas tipus, Jogosultsag, Fiok). | Validacio + adatmodell. | Listak nem olvashatok a kepekrol -> TBD. |
| 3 | Kotelezoseg pontos koere (mely mezok `*`). | Validacios szabalyok. | Csak Kod, Vezeteknev, Keresztnev, Allampolgarsag_1, Szul.datum, Szul.hely jelolt a kepeken. |
| 4 | SQLite offline mirror szukseges-e a dolgozoi torzsbol. | Penztaros-oldali bejelentkezes. | Nem allapithato meg a kepekrol -> TBD. |
| 5 | "Felhasznaloi megjegyzesek", "Kapcsolatok", "Autok", "Folyoszamlak" fulek tartalma. | FR-pontositas. | Tartalmuk nincs kepen -> TBD. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak a kepeken latott mezok)
- [x] minden TBD jelölt
VERIFIKACIO: FR=26 db, TBD=5 db, érintett csomag(ok)=backend, frontend (frontend-react + penztar-client TBD), Postgres (SQLite mirror TBD)
