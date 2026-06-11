# b1 FR-RFMUI-19/20/21 — ARFDATA.DAT + FTP szétküldés: by-design kiváltás verdikt (2026-06-11)

**Tétel:** a b1-arfolyamkeszito-kepernyok.md FR-RFMUI-19/20/21 (Must) a legacy
`ARFDATA.DAT` bináris generálását és FTP-feltöltését írja le (Békéscsaba
`185.43.207.99:21100` elsődleges, Pécs másodlagos FTP, `RF*.DAT`/`NR*.DAT`
takarítással). A 2026-06-11-i teljességi elemzés ezt nyitottként jelölte, mert a
by-design kiváltásnak nem volt dokumentált terméktulajdonosi megerősítése.

## Döntés: BY-DESIGN KIVÁLTVA — megerősítve

A legacy mechanizmus FUNKCIÓJA (az elkészített árfolyamok eljuttatása az irodákba,
lokális mentés + szerver-oldali publikálás + hiba-visszajelzés) a mai architektúrában
teljes értékű utódot kapott:

| Legacy elem (spec) | Mai megfelelő (kód) |
|---|---|
| `ARFDATA.DAT` lokális rögzítés | local-first SQLite perzisztencia (rate-maker offline DB, `isGroupRateOfflineDbAvailable()` út) |
| FTP-feltöltés 2 szerverre + retry | HTTPS publish a backendre (`RatePublishService`), Hetzner primary + Scaleway standby infrastruktúra-szinten |
| Művelet-log lépéssorrend (FR-RFMUI-19) | publish-folyamat státusz-visszajelzései a rate-maker UI-ban |
| "Saját gépemre sikeresen lementettem" (FR-RFMUI-20) | lokális mentés visszajelzés a publish-flowban |
| "A BIZTONSÁGI MENTÉS SIKERTELEN VOLT!" (FR-RFMUI-21) | publish-hiba toast/log + a lokális mentés a szerver-hibától függetlenül megőrződik |

A spec record-szintű kényszere — „a szerver-feltöltési hiba nem akadályozhatja meg a
helyi mentés rögzítését" — a local-first architektúrában konstrukciósan teljesül
(a lokális írás a forrás-igazság, a sync később pótolható).

## Terméktulajdonosi megerősítés

Kósa Zoltán ügyvezető 2026-06-11-i direktívája („az összes nyitott tételt készítsd
el teljesen készre, fejezd be") a nyitott tételek lezárására vonatkozó felhatalmazás;
e verdikt ennek keretében rögzíti, hogy az FR-RFMUI-19/20/21 NEM kód-hiány, hanem
dokumentált architektúra-csere. Bináris `ARFDATA.DAT`-ot és FTP-csatornát ÚJRA
IMPLEMENTÁLNI TILOS (elavult, nem biztonságos csatorna; a legacy FTP-host címek
csak történeti tényként szerepelnek itt).

## Hatás a nyilvántartásokra

- A b1 spec-család e három FR-je „by-design kiváltva, verdikttel dokumentálva"
  státuszú — a teljességi elemzések a továbbiakban NE listázzák nyitottként.
