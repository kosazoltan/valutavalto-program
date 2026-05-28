# Központi Munkaállomás — v2.27.35 frissítés

**Dátum:** 2026-05-28  
**Címzett:** Kasza Helga (Főértéktár) és a központi munkaállomást használó kollégák

---

## Mi változott?

Két dolog javul ezzel a telepítővel:

### 1. Készlet-snapshot, Országos készlet és Aktuális árfolyamok — **mostantól ugyanaz a valutalista**

A korábbi telepítésnél a három felület eltérő valutákat mutatott (DKK/NOK/SEK megmaradt, TST ismeretlen valuta jelent meg, csak 14 valuta volt az árfolyam-nézetben). A v2.27.35-tel mindhárom felület a központi valutanem-törzset olvassa:

- **Aktív valuták** (HUF, AUD, BAM, BRL, CAD, CHF, CNY, CZK, EUR, GBP, ILS, JPY, MXN, NZD, PLN, RON, RSD, RUB, THB, TRY, UAH, USD) jelennek meg a felületeken;
- a **DKK/NOK/SEK** mostantól **inaktív** (a már rögzített tranzakciók és adatok megmaradnak az adatbázisban — csak a felületeken nem jelennek meg);
- a **TST** ismeretlen valuta inaktívvá vált;
- a HUF mindig az utolsó sorban marad (a megszokott bázis-pozícióban);
- ha egy pénztárban még van fizikai DKK/NOK/SEK készlet, a Készlet-snapshot riportban a leltár alján külön szakaszként megjelenik (MNB-jellegű készletriport — a riport nem mutathat alá a valós készletnél).

### 2. Belső konzisztencia-javítás

A Készlet-snapshot Excel-export sor-pozíciói mostantól dinamikusan igazodnak a valutalista hosszához (a régi fix sorszámozás 27 valuta fölött ütközéshez vezetett volna).

---

## Telepítés

1. Mentsd el a futó munkát és zárd be a programot.
2. Dupla-klikk a `Kozponti-Munkaallomas-Setup-2.27.35.exe` fájlra.
3. UAC kérdésre **Igen**.
4. A telepítő mindent automatikusan elvégez (régi verzió eltávolítása, adatbázis-védelem, friss bundle telepítése, parancsikon, tűzfal-szabályok).
5. A telepítő végén a program elindul.

A pénztárosi adatok és a beállítások érintetlenek maradnak.

---

## Ha valami nem stimmel

Ha a frissítés után is a régi viselkedés látszik (pl. még mindig 14 valuta az árfolyam-nézetben):

1. Indítsd újra a programot.
2. Ha továbbra is így van, **NE** próbálj manuálisan beavatkozni — küldd vissza a képernyőképet és a hibajelenséget a fejlesztőnek.

A fejlesztő (én) intézkedik a probléma okának felderítéséről és a javításról. **A te dolgod csak a dupla-klikk + UAC „Igen"** — semmi más.

---

## Műszaki háttér (csak referenciának)

- PR: [#880](https://github.com/kosazoltan/valutavalto-program/pull/880) (squash: `e161aba79`)
- Forrás-visszajelzés: `vault/feedback/FK-006_visszajelzes_telepites_utan.md` (Kasza Helga, 2026-05-27)
- Backend teszt: 1715/1715 zöld
- Frontend bundle: tartalmazza a FK-006 (központi valutanem-törzs), FK-007/008 (Országos készlet törzs-vezérelt kártyák), FK-006 follow-up (snapshot-fix) változásokat
- DigiCert EV Code Signing tanúsítvány: validáció folyamatban — ez a build **UNSIGNED** (a Windows SmartScreen figyelmeztethet, „További információ" → „Mégis futtatás"). A signed verzió a cert kiadása után jön.
