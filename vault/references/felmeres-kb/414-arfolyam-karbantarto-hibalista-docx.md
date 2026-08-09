---
title: Árfolyam karbantartó hibalista.docx
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: arfolyam
original_path: Felmérés/Valuta/Árfolyam karbantartó hibalista.docx
doc_type: word
---

# Árfolyam karbantartó hibalista.docx

**Kategoria:** arfolyam  |  **Tipus:** word  |  **Meret:** 214.0 KB
**Eredeti utvonal:** `Felmérés/Valuta/Árfolyam karbantartó hibalista.docx`

## Tartalom

Hibajelentés – Sor másolásakor helytelen lapreferencia a képletekben
Érintett oldal/lap: Árfolyamkezelő – LapT01 Verzió: 3.189.0-20260216 Teszt dátuma: 2026.02.18.
A hiba leírása
Az Árfolyamkezelő táblázatban a „Copy selected row" → „Paste to selected row" funkció használatakor a beillesztett sor képleteiben a lapreferencia hibásan megváltozik: a $LapT01 helyett $LapT3 kerül be, ami érvénytelen hivatkozást eredményez, és minden érintett cellában #ERR hibaüzenetet okoz.
Reprodukálási lépések
Nyissa meg az Árfolyamkezelőt a LapT01 lapon.
Jelöljön ki egy sort (pl. a 7-es AUD sor) a sorszámra kattintva.
Kattintson a „Copy selected row" gombra a toolbarban — az alkalmazás visszajelez: „Sor 7 kimásolva a vágólapra."
Jelöljön ki egy másik sort (pl. a 9-es DKK sor).
Kattintson a „Paste to selected row" gombra. Eredmény: A 9-es sorban minden, $LapT01-re hivatkozó cella #ERR hibát dob.
Várt vs. tényleges viselkedés
Megjegyzések
A hiba a LapZ01 lapon is reprodukálható, tehát nem lapspecifikus probléma, hanem általános a sor másolás/beillesztés funkciójában.
Az alkalmazásban nincs működő visszavonás (Ctrl+Z) funkció, ezért a beillesztett hibás tartalom csak kézi javítással állítható helyre.
0-ás lapon csak az aktív valuták jelenjenek jelenjenek meg
Minden munkalap esetében csak az aktív valuták jelenjenek meg, és a pénztári programban is.
nem tudok inaktívvá tenni valutákat -> tudjak
A cellákat lehessen másolni. 👍
Kerekítés matematikai szabály szerint 👍
Ellenőrzés elvégzésekor egy új oszlopban hibalista
Ellenőrzés, Mentés, Szétküldés szétválasztása
Log pénztáranként (név,dátum),
Szeretnék a billentyűzet navigációs nyilaival közlekedni a cellák között
bevitelkor tudjam enterrel aktiválni a cellát és egyből írni bele. Jelenleg rákattintok, majd fel a szövegmezőbe, és enterrel rögzítek
Amikor gyorsan kell folyamatosan bevinni az adatokat ez nagy segítség. A lényeg, hogy lehessen egér használata nélkül is gyorsan és hatékonyan kezelni a felületet.👍
Ha új munkacsoportot hozok létre automatikusan tegye be az elszámoló árfolyamokat és a valuta elnevezéseket a megfeleő oszlopokba.
Currency mező HUF egész
