# Electron Cashier Smoke Checklist

Datum:
Commit:
Vegrehajto:
Kornyezet:

## Cel

Ez a checklist az Electron-authoritative penztari flow celzott kezelesi es visszaallasi ellenorzesehez keszult.
Nem regresszios tesztcsomag helyett van, hanem a release elotti kezi smoke validaciohoz.

## Elofeltetelek

- [ ] Backend elerheto es autentikacio mukodik.
- [ ] penztar-client build sikeres.
- [ ] Frontend build sikeres.
- [ ] Security gate friss evidence PASS: security-reports/latest/gate-status.json.
- [ ] Teszt user rendelkezik penztaros jogosultsaggal.
- [ ] Teszt irodaban van ervenyes, 24 oran beluli arfolyam.

## 1. Indulas es session recovery

- [ ] Electron app indul.
- [ ] Bejelentkezes utan a penztaros session es irodaazonositas helyesen betolt.
- [ ] App ujrainditas utan a local queue allapot megmarad.

Elvart eredmeny:
Az app nem vesziti el a lokalis pending vagy audit adatokat ujrainditas utan.

## 2. Vetel es eladas local-first

- [ ] BUY tranzakcio rogzitese sikeres.
- [ ] SELL tranzakcio rogzitese sikeres.
- [ ] A mentett tetel azonnal megjelenik a lokalis/pending nezetben, ha a sync nem fejezodik be azonnal.
- [ ] Sikeres sync utan a tetel hivatalos szerveres allapotban is lathato.

Elvart eredmeny:
Minden create flow Electron alatt eloszor lokalis mentest kap, es csak utana megy szerver fele.

## 3. Konverzio es draft receipt

- [ ] Conversion tranzakcio rogzitese sikeres.
- [ ] Draft receipt preview megnyithato pending allapotban.
- [ ] Draft receipt nyomtathato lokal draft jelzessel.
- [ ] Sikeres sync utan hivatalos receipt adatok jelennek meg.

Elvart eredmeny:
A draft es a hivatalos bizonylat UX nem keveredik.

## 4. Sztorno local-first

- [ ] Sztorno approval folyamat lefut.
- [ ] Electron execute local-first mentest hoz letre.
- [ ] Pending storno latszik a local queue oldalon.
- [ ] Sikeres sync utan a sztorno szerveroldali allapota egyezik.

Elvart eredmeny:
A sztorno nem keruli meg a lokalis queue-t.

## 5. Treasury, bank, handover

- [ ] Transfer/ertektari mozgas helyi mentest kap.
- [ ] Banki mozgas helyi mentest kap.
- [ ] Handover generate muvelet queue-ba kerul Electron alatt.
- [ ] Handover print muvelet queue-ba kerul Electron alatt.
- [ ] Handover complete muvelet queue-ba kerul Electron alatt.

Elvart eredmeny:
A listanezetek mutatjak a pending lokalis elemeket is, nem csak a szerveres adatot.

## 6. Local Queue oldal

- [ ] A Helyi Queue oldal megnyithato.
- [ ] Latszanak rajta a pending receipt, transfer, bank, handover es audit elemek.
- [ ] Manualis sync gomb mukodik.
- [ ] Sikeres sync utan a pending sorok csokkennek vagy eltunnek.

Elvart eredmeny:
A penztaros vagy auditor egy helyen at tudja nezni a lokalis fuggoben levo elemeket.

## 7. Offline es helyreallas

- [ ] Halozat megszakitasa mellett legalabb egy kritikus tranzakcio rogzitese sikeres.
- [ ] Visszakapcsolas utan a manualis vagy automatikus sync feltolja az elemet.
- [ ] Nincs duplikalt szerveroldali vegrehajtas.

Elvart eredmeny:
Az idempotens sync miatt ugyanaz a lokalis muvelet nem jelenik meg tobbszor szerveroldalon.

## 8. Bizonyitek es megorzes

- [ ] A release jegyzet vagy audit evidence hivatkozik erre a checklistre.
- [ ] A lokalis Electron retention cel 31 napkent dokumentalt.
- [ ] A backend archival retention minimum 8 evkent dokumentalt.
- [ ] Nem talalhato hard delete utvonal penzugyi archiv rekordra.

Elvart eredmeny:
A manualis smoke es a retention policy ugyanabba a bizonyitekcsomagba beteheto.

## Eredmeny

- [ ] PASS
- [ ] FAIL

Megjegyzesek:
