---
title: "EBC Hangsegéd — Kollégai útmutató (1 oldal)"
date: 2026-05-18
type: operations
audience: ebc-kollegak
status: draft
deployment: "Csak a Phase 9.5 integration PR mergelése után válik elérhetővé a kollégák számára."
---

# EBC Hangsegéd — Kollégai útmutató (1 oldal)

> **Verzió:** 2026-05-18 · v0.1 — első release · **Nyomtatható**: A4, álló
> **Cél:** Minden EBC kolléga 5 perc alatt megtanulhatja, hogyan használja a Hangsegédet a programon belül.
> **Állapot:** ELŐZETES — a Hangsegéd csak a Phase 9.5 integráció telepítője után jelenik meg a kliensben (v2.5.55+).

---

## Mi a Hangsegéd?

Az **EBC Hangsegéd** egy magyar nyelvű hangasszisztens, amely a programon belül él. Nem kell semmilyen különálló alkalmazás. Beszélsz vele magyarul, ő válaszol, és lejegyzi neked, amit kérsz.

A jobb alsó sarokban találod a kis lebegő panelt (csak v2.5.55+ telepítőben). Három gomb van rajta:

| Gomb | Mikor használd |
|---|---|
| **Telepítés** | Most telepítetted először a programot, vagy újratelepítetted. Végigvezet a beállításon. |
| **Tesztelés** | Új verzió jött, szeretnél átfutni rajta. Strukturáltan kikérdez. |
| **Hibajelzés** | Munka közben valami nem stimmel — felírja neked, hogy a fejlesztő majd kijavíthassa. |

## Hogyan beszélj vele?

1. **Klikk a megfelelő gombra.** A panel azt mondja "Kapcsolódás…", ez 2-3 másodperc.
2. **Beszélj normálisan, magyarul.** Nem kell parancsokat tudni — úgy mondd, ahogy egy kollégának mesélnéd.
3. **A Hangsegéd válaszol hangban.** Ha nem tudja a választ, ezt is mondja: "Ezt jegyzetelem és a fejlesztő majd válaszol."
4. **Klikk a "Beszélgetés befejezése" gombra**, ha végeztél.

## Trigger szavak — azonnal lejegyzi

Ha bármikor azt mondod a programmal kapcsolatban:

- **"jegyezd fel"**
- **"írd ezt le"**
- **"rögzítsd"**
- **"készíts hibajegyet"**
- **"ne felejtsd el"**
- **"jegyzeteld le"**

A Hangsegéd AZONNAL felírja, akkor is, ha épp másról beszéltetek. Nem kell külön mód.

## Tesztelés módban — strukturáltan kikérdez

A Tesztelés gombra kattintva a Hangsegéd 6 dolgot kérdez minden hibára:

1. **Mi történt pontosan?**
2. **Mit csináltál előtte?**
3. **Mit vártál volna?**
4. **Mit láttál valójában?**
5. **Melyik modulban történt?** (pénztár, központi, árfolyamkészítő, …)
6. **Mennyire sürgős?** (kritikus / magas / közepes / alacsony)

A végén a **"Jelentés letöltése"** gombbal egy `.md` fájlt kapsz a gépedre — ezt küldd el e-mailben a fejlesztőnek (Kósa Zoltán).

## Adatvédelem — Mi marad helyileg, mi megy az OpenAI-hoz?

A Hangsegéd egy **OpenAI Realtime API**-t használ a háttérben, ezért fontos tudni:

**MARAD a gépeden:**
- A `.md` hibajegyzet, amit letöltöttél
- A program belső naplója (IndexedDB) a saját gépeden
- Az ügyféltranzakció-adatok (a Hangsegéd EZEKET NEM kérdezi és NEM kapja meg)

**AZ OPENAI-HOZ MEGY (a beszélgetés alatt):**
- A mikrofonos audió-stream (amit elmondasz)
- Az audió-szöveg konvertálás eredménye (transcript)
- A Hangsegéd válasza, amit visszahallasz

**A Hangsegéd EZT NEM csinálja:**
- ❌ Nem kér tőled jelszót vagy ügyfél-adatot (csak a saját nevedet + irodát kérdezi a Telepítés módban).
- ❌ Nem küld semmit a backend-szerverre az ügyfél-tranzakciókról.
- ❌ Nem helyettesít téged — csak segít naplózni és emlékezni.

## Ha nem működik

Egyszerű ellenőrzés:

1. **Mikrofon engedély:** ha a böngésző / Electron rákérdez "engedélyezi a mikrofont?", **igen**.
2. **Internet:** kell hozzá. Ha leesik a net, a Hangsegéd is leáll, a többi funkció megy tovább.
3. **Backend kapcsolat:** ellenőrizd a Setup Wizardban a "Kapcsolat tesztelése" gombot — ha zöld, a Hangsegéd is működik.

Ha mégse megy, **jelezd Kósa Zoltánnak** (kosa.zoltan.ebc@gmail.com) — fontos a visszajelzés a továbbfejlesztéshez.

---

**EBC Valutaváltó · Hangsegéd v0.1 · 2026-05-18**
