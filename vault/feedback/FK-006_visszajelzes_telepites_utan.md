# FK-006 – Visszajelzés a telepítés után

**Dátum:** 2026. május 27.
**Beküldő:** Kasza Helga – Főértéktár

---

## Fejlesztői visszajelzés
A fejlesztő visszajelezte, hogy az FK-006 (prod-deploy: SUCCESS) és a többi kapcsolódó kérés is élesben van, backend frissítésként – frontend frissítő nem szükséges.

## Tapasztalt helyzet

A képernyőképek alapján a változások **nem érvényesülnek minden felületen**.

| Felület | Státusz | Megjegyzés |
|---|---|---|
| Készlet-snapshot | ⚠️ Részleges | Az új valuták (BAM, BRL, ILS, MXN, NZD, THB) megjelennek, de DKK/NOK/SEK még látható |
| Országos készlet (kártyák) | ❌ Nem frissült | Régi valutasorrend, DKK/NOK/SEK még szerepel, TST ismeretlen valuta is látható |
| Aktuális árfolyamok | ❌ Nem frissült | Csak 14 valuta látható, az új valuták nem jelennek meg |

## Kért vizsgálat

A képernyőképek alapján valószínűsíthető, hogy nem minden modul olvassa ugyanabból a forrásból a valutanem törzsadatot. Kérjük megvizsgálni, hogy mely modulok használnak esetleg saját/külön valutanévsort, és azokat is a központi törzsadatra átállítani.

## Mellékletek
- 1. kép: Készlet-snapshot (Szekszárd tab)
- 2. kép: Országos készlet – Békéscsaba szekció
- 3. kép: Aktuális árfolyamok nézet
