# ARFOLYAM (árfolyamkészítő) — VALÓDI forrás modul-MD-k

> Forrás: `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked` (verzio22, a legújabb). 16 Delphi form-unit + `Arfolyam.dpr`.
> **KORREKCIÓ (2026-05-23):** a korábbi doksi tévesen állította, hogy az ARFOLYAM-nak
> nincs forrása (csak bináris-RE). A teljes Object Pascal forrás MEGVAN ezen az úton.

| Form | Funkció |
|---|---|
| `TForm1` | fő ablak / belépés |
| `TINTERNETTMKFORM` | INTERNET-cím (URL) karbantartó — gomb {sorszám, felirat, URL} |
| `TGetFuggveny` | képlet/függvény segéd (cella-másolás) |
| `TNyomtatoForm` | nyomtatás |
| `TARFDATAIRAS` | arfdata.dat írás (árfolyam-fájl perzisztálás) |
| `TAdatSzetkuldes` | árfolyamok szétküldése az irodáknak |
| `TCSOPORTDISPLAY` | 54-csempe csoport-rács (J–S oszlopok) |
| `TMUNKAFORM` | munka-form |
| `TALAPLAP` | 0-s alaplap (A–I oszlopok árfolyam-rács) |
| `THELPFORM` | súgó |
| `TINTERNETBONGESZO` | internet-böngésző (a karbantartott URL-ek megnyitása) |
| `TAdatBetoltes` | adat-betöltés (arfdata.dat olvasás) |
| `TZOLDMENU` | zöld menü (fő navigáció) |
| `THOVAMASOLJAK` | hova-másoljak (cella-másolás cél) |
| `TLIMITALLITOFORM` | limit-állító (kedvezmény alsó/közép/felső) |
| `TIRODANEVLISTA` | iroda-név lista (árfolyam-csoport→iroda hozzárendelés) |