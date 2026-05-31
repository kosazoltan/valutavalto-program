# Claude Code + Opus 4.8 — Komplett utasításkészlet a valutaváltó szoftverhez

> Cél: az Opus 4.8 modellt a Claude Code-on belül **gyorsabban, pontosabban, célratartóbban** használni a valutaváltó szoftver fejlesztéséhez — **hazugság, lustaság és hallucináció nélkül, kizárólag tényekre alapozva.**

Ez a dokumentum két dolgot ad:
1. **Másolható konfigurációkat** (CLAUDE.md, hookok, subagentek), amiket egyszer beállítasz, és onnantól minden munkamenetben hatnak.
2. **Másolható prompt-sablonokat és munkafolyamatokat**, amiket napi szinten használsz.

Minden állítás a hivatalos Claude Code dokumentációra (code.claude.com/docs) és az Opus 4.8 hivatalos kiadási anyagaira épül. A források a dokumentum végén.

---

## 0. A LEGFONTOSABB: a "három tilalom" — hazugság, lustaság, hallucináció nélkül

Ez nem jámbor óhaj, hanem **kikényszeríthető szabályrendszer**. Az LLM nem szándékosan hazudik, de hajlamos arra, hogy:
- **hallucináljon** — kitaláljon függvénynevet, API-t, fájlt, ami nem létezik;
- **lusta legyen** — félkész/„placeholder” kódot adjon le késznek (`// TODO`, `... rest of logic here`);
- **„hazudjon”** abban az értelemben, hogy *állítson* dolgokat bizonyíték nélkül („a teszt lefutott", „a build sikeres") anélkül, hogy ténylegesen lefuttatta volna.

Az Opus 4.8 itt komoly előrelépés: a hivatalos kiadás szerint **kb. négyszer kevésbé valószínű, mint az elődje, hogy a saját kódjában lévő hibát szó nélkül átengedje**, és hajlamosabb jelezni a bizonytalanságait ahelyett, hogy elrejtené őket. De ezt a viselkedést **meg kell erősíteni** a saját szabályaiddal.

### A „bizonyíték-kényszer" elve

A modell csak akkor állíthat valamit befejezettnek, ha **bizonyítékot mutat**: a lefuttatott parancsot ÉS annak kimenetét. Ez a leghatékonyabb hallucináció-ellenes eszköz, mert egy állítást olcsóbb ellenőrizni, mint magát a munkát.

### Másolható CLAUDE.md-blokk (tedd a projekt gyökerébe)

```markdown
# === MŰKÖDÉSI ALAPELVEK (KÖTELEZŐ) ===

## Tényalapúság — hallucináció tilalom
- SOHA ne hivatkozz olyan fájlra, függvényre, változóra, API-végpontra vagy
  könyvtárra, amit nem olvastál el VAGY nem ellenőriztél a kódbázisban.
  Ha nem vagy biztos benne, OLVASD EL ELŐSZÖR, ne találgass.
- Ha valamit nem tudsz vagy nem tudtál ellenőrizni, MONDD KI nyíltan:
  "Ezt nem ellenőriztem", "Ebben nem vagyok biztos". A bizonytalanság
  elrejtése súlyosabb hiba, mint maga a bizonytalanság.
- Csomag/könyvtár verziókat, függvény-szignatúrákat NE emlékezetből írj.
  Ellenőrizd a package.json-ban / a forrásban / a hivatalos dokumentációban.

## Bizonyíték-kényszer — "hazugság" tilalom
- "Kész", "működik", "a teszt zöld", "a build sikeres" állítást CSAK akkor
  tehetsz, ha ELŐTTE lefuttattad, és MEGMUTATOD a parancsot + a kimenetet.
- Tilos a tényleges futtatás nélküli sikerjelentés.

## Teljesség — lustaság tilalom
- TILOS félkész kódot késznek leadni: nincs "// TODO", nincs "... ide jön
  a többi logika", nincs csonkolt függvény, hacsak EXPLICIT nem kérem.
- Ha a feladat túl nagy egy menetre, MONDD KI, és bontsd lépésekre —
  de amit leadsz, az legyen teljes és futtatható.

## Pénzügyi domén (valutaváltó) — extra szigor
- Pénzösszeg SOHA ne legyen lebegőpontos (float/double). Egész alapú
  (kisegység, pl. fillér) vagy decimal típus, a projekt konvenciója szerint.
- Minden kerekítést, árfolyam-számítást, jutalékot KÖTELEZŐ teszttel
  bizonyítani konkrét számpéldákon.
- Minden külső bemenet (összeg, árfolyam, ügyfél-adat) validálva legyen.
```

> Tipp: a Claude Code dokumentáció szerint a `FONTOS` / `KÖTELEZŐ` / `SOHA` / `TILOS` típusú nyomatékosítás bizonyítottan javítja a szabálykövetést. Ne félj a nagybetűtől a kritikus pontoknál.

---

## 1. Opus 4.8 újdonságai — és hogyan használd ki őket

| Újdonság | Mit jelent neked a gyakorlatban |
|---|---|
| **1M tokenes kontextusablak** (API-n alapból) | A teljes valutaváltó-modult, sémát, kapcsolódó fájlokat egyszerre láthatja. De **a teljesítmény így is romlik, ahogy telik a kontextus** — a méret nem ürügy a fegyelmezetlenségre (lásd 3. fejezet). |
| **128k max kimeneti token + adaptív gondolkodás** | Nagy refaktorokat, teljes modulokat egy menetben legenerálhat. |
| **Jobb hosszú-távú ágens-kódolás** (kevesebb tömörítés, jobb tömörítés-utáni helyreállás) | A hosszú munkamenetek stabilabbak; ritkábban „felejt el" korábbi utasításokat. |
| **Effort-vezérlés** (`high` az alapérték; `xhigh`, `max` a legnehezebb feladatokra) | A `high` az Opus 4.8-on a 4.7-hez hasonló token-költségen ad jobb eredményt. Kritikus pénzügyi logikára, nehéz bugokra emeld `xhigh`/`max` szintre; rutinmunkára hagyd `high`-on. |
| **Magasabb őszinteség / hibajelzés** (~4× ritkábban enged át hibát szó nélkül) | Kérd is meg rá: „jelezd a kockázatokat" — pl. validáció nélküli végpontnál magától figyelmeztet. |
| **Fast mode** (2,5× sebesség, 3× olcsóbb a korábbinál) | Felfedezésre, gyors kérdezgetésre, könnyű feladatokra. Komoly pénzügyi logikára inkább a teljes (lassabb, alaposabb) mód. |
| **Dynamic workflows** (research preview — Claude Code **Enterprise / Team / Max** csomagon) | Egy munkamenetben több száz párhuzamos subagent: tervezés → párhuzamos végrehajtás → önellenőrzés. Kódbázis-méretű migrációkra a meglévő tesztkészlet mint mérce. Csak akkor érhető el, ha a csomagod tartalmazza. |
| **Köztes utasítás-frissítés a prompt-cache törése nélkül** | Hosszú ágens-futás közben módosíthatsz az irányon anélkül, hogy elveszne a gyorsítótár előnye (90%-ig olcsóbb input). |

**Költség-tudatosság:** Opus 4.8 ára $5 / millió input token és $25 / millió output token, prompt-caching-gel akár 90%, batch-csel 50% megtakarítással. A nagy kontextus és a `max` effort sokba kerülhet — mérd a token/feladat arányt a saját munkádon.

---

## 2. Az alap-munkafolyamat: Felfedezés → Terv → Megvalósítás → Ellenőrzés → Commit

A hivatalos dokumentáció szerint a kód-elsőre-ugrás a leggyakoribb hibaforrás: „rossz problémát old meg jól". Ezért válaszd szét a kutatást és a megvalósítást.

1. **Felfedezés (plan mode).** A Claude olvas, kérdez, de NEM módosít.
   ```
   Lépj plan módba. Olvasd el a src/arfolyam és src/tranzakcio mappákat,
   és értsd meg, hogyan számolunk jutalékot és hogyan kerekítünk.
   Még ne javasolj változtatást.
   ```
2. **Terv.** Kérj részletes megvalósítási tervet. `Ctrl+G`-vel megnyithatod a tervet a szerkesztődben és kézzel pontosíthatsz, mielőtt a Claude továbbmegy.
   ```
   Új valutapár felvételét akarom. Mely fájlok módosulnak? Mi az
   adatfolyam a bevitel → validáció → árfolyam → kerekítés → mentés úton?
   Készíts tervet, és írd ki PLAN.md-be.
   ```
3. **Megvalósítás.** Kilépsz plan módból, és a Claude a saját terve alapján kódol.
4. **Ellenőrzés.** (Lásd a 4. fejezet — ez a legfontosabb pénzügyi szoftvernél.)
5. **Commit.** Leíró üzenettel, kis, fókuszált commitokban.

> Mikor hagyd ki a tervezést? Ha egy mondatban le tudod írni a diffet (elgépelés, log-sor, átnevezés), ugord át. A tervezés akkor fizet ki, ha bizonytalan a megközelítés, több fájlt érint, vagy ismeretlen a kód.

---

## 3. A „dokumentum elejét-végét olvassa" probléma — és a megoldás

Ezt jól látod: az LLM-ek hajlamosak hosszú dokumentumnál a **elejére és végére** koncentrálni, a közepét „átugorni" (ez a *lost in the middle* jelenség). Az Opus 4.8 hosszú-kontextus kezelése jobb, de **a kockázat nem nulla**. Konkrét ellenintézkedések:

**a) Kérj sorszám-tartomány szerinti, teljes olvasást.**
```
Olvasd el a docs/arfolyam_spec.md 1–400. sorát TELJESEN, ne csak az elejét
és a végét. A végén sorold fel a fő szakaszcímeket sorszámmal, hogy lássam,
mindet láttad.
```

**b) Kérj bizonyítékot a közepéről.** Ha idéznie kell a dokumentum közepéről, kénytelen elolvasni.
```
Mielőtt bármit csinálsz: idézd szó szerint a "Kerekítési szabályok" és a
"Jutalék-sávok" szakasz egy-egy mondatát, fájl + sorszám megjelöléssel.
```

**c) Darabold a feldolgozást.** Nagy dokumentumot kérj szakaszonként összefoglalni, számozott listába, majd csak utána dolgozzon belőle.

**d) Használj subagentet a kutatásra.** A subagent külön kontextusban olvassa el a sok fájlt, és csak az összefoglalót adja vissza — így a fő beszélgetésed tiszta marad, és a részfeladat „kénytelen" végigolvasni.
```
Indíts subagentet: olvassa végig a teljes adatbázis-sémát és a migrációkat,
és adjon vissza egy táblát: tábla → oszlop → típus → megjegyzés. Ne hagyj ki
egyetlen táblát sem; a végén írd ki, hány táblát dolgoztál fel.
```

**e) Korlátozd a „végtelen felfedezést".** Soha ne mondd csak annyit, hogy „nézd át" hatókör nélkül — mert több száz fájlt beolvas, megtömi a kontextust, és romlik a minőség. Mindig adj konkrét fájlt/mappát/kérdést.

---

## 4. Ellenőrzés és AI-hibaelkerülés (a legfontosabb rész pénzügyi szoftvernél)

A dokumentáció egyértelmű: **„Adj a Claude-nak valamit, amivel ellenőrizheti a saját munkáját."** Enélkül a „késznek tűnik" az egyetlen jelzés, és te válsz az ellenőrző hurokká. Adj neki pass/fail jelet — teszt, build, linter, screenshot, fixture-diff —, és a hurok magától bezárul.

### Az ellenőrzés négy szintje (egyre erősebb kikényszerítés)

| Szint | Eszköz | Mikor |
|---|---|---|
| **Promptban** | „futtasd a teszteket megvalósítás után, és javíts, amíg zöld nem lesz" | Minden feladatra azonnal használható |
| **Munkameneten át** | `/goal` feltétel — külön értékelő minden kör után újraellenőrzi | Hosszabb, egy célra tartó munka |
| **Determinisztikus kapu** | **Stop hook** — script, ami blokkolja a kör befejezését, amíg át nem megy | Felügyelet nélküli futás |
| **Második vélemény** | **ellenőrző subagent** vagy `/code-review` friss kontextusban | Mielőtt késznek nyilvánítod |

### Add meg az elfogadási kritériumot konkrét számpéldával (valutaváltó)

A „make it work" típusú prompt helyett:
```
Írj egy valto_osszeg(input_osszeg, arfolyam, jutalek_szazalek) függvényt.
Tesztesetek, amiknek át KELL menniük:
- 100 EUR @ 400.00, 0% jutalék → 40 000 HUF
- 100 EUR @ 399.99, 1% jutalék → ellenőrizd a kerekítést, banker's rounding
- 0 és negatív összeg → dobjon hibát
- nagyon nagy összeg → ne legyen túlcsordulás/lebegőpont-hiba
Implementálás után FUTTASD a teszteket, és mutasd a kimenetet.
```

### A gyökérokot javítsd, ne a tünetet

```
A build ezzel a hibával áll le: [hibaüzenet beillesztve]. Javítsd, és
igazold, hogy a build sikeres. A GYÖKÉROKOT kezeld, ne nyomd el a hibát.
```

### Adverzariális (ellenfeles) ellenőrzés friss kontextusban

A leghatékonyabb minőségbiztosítás: **az írja a kódot, és MÁS ellenőrizze.** A friss kontextusú ellenőrző nem látja az indoklást, csak a diffet és a kritériumot — ezért tárgyilagosan ítél.
```
Indíts subagentet: ellenőrizze a jutalék-számító diffet a PLAN.md-vel
szemben. Minden követelmény megvalósult? Minden felsorolt peremeset
le van tesztelve? Változott-e bármi a feladat hatókörén kívül?
Csak a HELYESSÉGET vagy a követelményeket érintő hiányokat jelezd,
stílus-preferenciát ne.
```

> Figyelem: az ellenőrző subagent szinte mindig talál „hiányt", mert erre kérted. Ne ess túlmérnökösködésbe — csak a helyességet érintő hiányokat hajtsd be.

### Amit MINDIG ember nézzen át (a Claude jó, de ezeket te döntsd el)

A valutaváltó szoftvernél kiemelten: **árfolyam-számítás és kerekítés, jutalék-logika, pénzmozgás/tranzakció, adatbázis-migrációk (különösen oszlop-törlés), jogosultság/hozzáférés, naplózás és audit-nyomvonal, AML/jelentési küszöbök.** Egy rossz kerekítés vagy egy csendben oszlopot törlő migráció pénzbe és bizalomba kerül — ezeket automatizált teszt nem mindig fogja meg.

---

## 5. Emberi szöveg → AI-érthető specifikáció (kötelező első lépés)

Pontosan jó az érzéked: amikor egy laza, emberi megfogalmazású kérést kapsz, **ne abból kezdjen kódolni a Claude.** Először fordítsa át gépi, egyértelmű specifikációvá, és csak a te jóváhagyásod után induljon.

### A „spec-először" hurok

**5.1 — Hagyd, hogy a Claude kérdezzen ki téged.** A dokumentáció külön ajánlja: nagyobb funkciónál a Claude az `AskUserQuestion` eszközzel végigkérdez a peremesetekről, kompromisszumokról, amikre nem is gondoltál.
```
Új modult akarok: napi árfolyam-zárás és kassza-egyeztetés. Kérdezz ki
részletesen az AskUserQuestion eszközzel. Kérdezz a megvalósításról,
az adatmodellről, a peremesetekről, a kockázatokról és a kompromisszumokról.
Ne tegyél fel triviális kérdést, a nehéz részekre menj rá. Amikor mindent
lefedtünk, írd ki a teljes specifikációt SPEC.md-be.
```

**5.2 — Kérd a gépi specifikáció normalizálását.** Ha te adsz egy laza leírást:
```
Az alábbi emberi nyelvű leírásból KÉSZÍTS először egy egyértelmű,
gépi feldolgozásra alkalmas specifikációt, MIELŐTT bármilyen kódot írnál.
A spec tartalmazza: (1) bemenetek típussal és tartománnyal, (2) kimenetek,
(3) lépésenkénti üzleti szabályok, (4) peremesetek és hibakezelés,
(5) elfogadási kritériumok konkrét számpéldákkal, (6) ami EXPLICIT NINCS
a hatókörben. Ahol az eredeti szöveg kétértelmű, NE találgass — listázd a
nyitott kérdéseket. A spec jóváhagyásáig ne kezdj kódolni.

--- EMBERI LEÍRÁS ---
[ide jön a saját, laza megfogalmazásod]
```

**5.3 — Friss munkamenetben hajtsd végre.** Ha kész és jóváhagyott a SPEC.md, **indíts új munkamenetet** a megvalósításra. A tiszta kontextus teljesen a kódolásra fókuszál, és van leírt specifikációd hivatkozási alapnak.

> A legjobb spec önmagában megáll: megnevezi az érintett fájlokat és interfészeket, kimondja, mi NINCS a hatókörben, és egy végponttól-végpontig ellenőrző lépéssel zárul, ami bizonyítja, hogy a funkció működik.

---

## 6. Pontos prompt = kevesebb javítás

A precíz utasítás kevesebb korrekciót igényel. A négy fő stratégia:

| Stratégia | Gyenge | Erős |
|---|---|---|
| **Hatókör** | „írj tesztet a valto.py-ra" | „írj tesztet a valto.py-ra a kijelentkezett ügyfél peremesetére, mock nélkül" |
| **Mutass forrást** | „miért ilyen fura ez az API?" | „nézd át az ArfolyamFactory git-történetét, és foglald össze, hogyan alakult ki az API-ja" |
| **Hivatkozz meglévő mintára** | „adj hozzá egy widgetet" | „nézd meg, hogyan van megoldva a KasszaWidget, kövesd ugyanazt a mintát az új ArfolyamWidgethez, külső könyvtár nélkül" |
| **Írd le a tünetet** | „javítsd a bejelentkezést" | „az ügyfelek szerint session-lejárat után hibás a váltás-mentés. Nézd a src/tranzakcio token-frissítését. Írj előbb egy bukó tesztet, ami reprodukálja, aztán javítsd" |

**Gazdag tartalom bevitele:**
- `@fajlnev` — a Claude beolvassa a fájlt válasz előtt (gyorsabb, mint körülírni, hol a kód).
- Képek beillesztése (UI-bug, terv) — másold/húzd a promptba.
- URL-ek dokumentációhoz; gyakori domaineket `/permissions`-szel engedélyezhetsz.
- Adat-csővezetés: `cat hiba.log | claude` közvetlenül beküldi a tartalmat.

---

## 7. Munkamenet- és kontextus-kezelés (a teljesítmény kulcsa)

A legtöbb best practice egyetlen tényből fakad: **a kontextusablak gyorsan megtelik, és ahogy telik, romlik a teljesítmény** — a Claude „elfelejt" korábbi utasításokat, többet hibázik. Kezeld agresszíven:

- **`/clear`** — nullázd a kontextust *független feladatok között*. Ez az egyik leghatékonyabb minőség-trükk.
- **`/compact <instrukció>`** — irányított tömörítés, pl. `/compact a kerekítési és jutalék-döntésekre fókuszálj`.
- **`Esc`** — állítsd meg azonnal, ha rossz irányba megy; a kontextus megmarad, átirányíthatod.
- **`Esc + Esc` / `/rewind`** — visszaállás korábbi pontra (beszélgetés és/vagy kód). Minden prompt checkpointot hoz létre. (Figyelem: ez csak a Claude által végzett változásokat követi, **nem git-helyettesítő.**)
- **„Undo that"** — vond vissza az utolsó módosítást.
- **`/btw`** — gyors mellékkérdés, ami **nem kerül** a beszélgetés-történetbe (nem hizlalja a kontextust).

**Ökölszabály:** ha kétszernél többször javítottad ugyanazt egy menetben, a kontextus tele van zsákutcákkal. `/clear`, és írj egy jobb kezdő-promptot a tanultakkal. Egy tiszta munkamenet jobb prompttal szinte mindig veri a hosszú, korrekciókkal teli menetet.

**CLAUDE.md tömörítés-mentés** — tedd bele, hogy mit őrizzen meg:
```
# Tömörítéskor MINDIG őrizd meg a módosított fájlok teljes listáját,
# a futtatandó teszt-parancsokat és a kerekítési/jutalék-döntéseket.
```

---

## 8. Konfiguráció: tedd egyszer, hasson mindig

### CLAUDE.md — a tartós kontextus
`/init` paranccsal generálj alapot, majd finomítsd. Tartsd **rövidnek és emberi nyelvűnek** — ha túl hosszú, a Claude a felét figyelmen kívül hagyja, mert a fontos szabály elvész a zajban.

Tedd bele: nem kitalálható bash-parancsok; alapértelmezéstől eltérő kódstílus; teszt-futtatás módja; branch/PR-konvenciók; projekt-specifikus architektúra-döntések; környezeti furcsaságok (pl. **az ékezetes Windows-felhasználónév okozta útvonal-problémák**, BOM-kódolás). Ne tedd bele: amit a Claude a kódból amúgy is kiolvas; gyakran változó infót; hosszú magyarázatokat.

Helyek: `~/.claude/CLAUDE.md` (minden munkamenetre), `./CLAUDE.md` (projektre, gitbe), `./CLAUDE.local.md` (személyes, gitignore-ba), szülő/gyermek mappák (monorepóhoz). Importálás: `@docs/git-instructions.md`.

### Skillek — domén-tudás igény szerint
Ami csak néha kell, az ne a CLAUDE.md-be, hanem **skillbe** menjen (`.claude/skills/<nev>/SKILL.md`) — a Claude igény szerint tölti be, nem hizlalja minden beszélgetést. Pénzügyi konvencióidat (kerekítés, jutalék-sávok, áfa, kassza-szabályok) érdemes skillbe tenni.

### Hookok — determinisztikus garanciák
A CLAUDE.md tanácsadó; a **hook determinisztikus** — garantáltan lefut. A Claude meg is írja neked:
```
Írj egy hookot, ami minden fájl-szerkesztés után lefuttatja az eslintet.
Írj egy hookot, ami megtiltja a migrations/ mappába írást jóváhagyás nélkül.
```
Pénzügyi szoftverhez aranyat ér egy **Stop hook**, ami a tesztkészletet futtatja, és nem engedi befejezni a kört, amíg zöld nem lesz.

### Subagentek — izolált, fókuszált feladatok
`.claude/agents/<nev>.md` — saját kontextus, saját engedélyezett eszközök. Pl. egy `biztonsagi-ellenor` (jogosultság, injekció, titkok), vagy egy `penzugyi-ellenor` (kerekítés, túlcsordulás, validáció).

### CLI-eszközök és MCP
- A Claude hatékonyan használ CLI-t: `gh` (GitHub), és tetszőleges sajátot: `Tanuld meg a 'foo-cli --help'-ből, majd oldd meg vele A-t, B-t.`
- MCP-szerverek: `claude mcp add` — adatbázis-lekérdezés, issue-tracker, design-integráció. (A te Neon PostgreSQL-edhez is köthető.)

---

## 9. Automatizálás és skálázás

- **Nem-interaktív mód:** `claude -p "prompt"` — CI-be, pre-commit hookba, scriptbe. Strukturált kimenet: `--output-format json` vagy `stream-json --verbose`.
- **Több párhuzamos munkamenet:** *worktree*-k (izolált git-checkoutok, hogy a szerkesztések ne ütközzenek), desktop app, web, vagy **agent teams** (automatikus koordináció).
- **Writer/Reviewer minta:** egy munkamenet ír, egy másik **friss kontextusból** ellenőrzi — mivel nincs elfogultság a saját kód iránt, jobb a kódellenőrzés.
- **Fan-out** nagy migrációhoz: listázd a fájlokat, majd ciklusban `claude -p ... --allowedTools "Edit,Bash(git commit *)"`. Előbb 2-3 fájlon próbáld, finomíts, aztán futtasd a teljesre.
- **Auto mód** felügyelet nélküli futáshoz: `claude --permission-mode auto -p "javíts minden lint hibát"` — egy osztályozó modell előzetesen blokkolja a kockázatos parancsokat.
- **Dynamic workflows** (ha a csomagod — Enterprise/Team/Max — tartalmazza): a Claude megtervezi a munkát, több száz párhuzamos subagentet futtat egy menetben, és ellenőrzi a kimenetet a meglévő tesztkészlettel mint mércével. Kódbázis-méretű migrációkra.

---

## 10. Gyakori hibaminták és azonnali javításuk

| Hibaminta | Javítás |
|---|---|
| **Mindenes munkamenet** — egy feladatból más feladatba ugrálsz, a kontextus tele lesz lommal | `/clear` a független feladatok között |
| **Körkörös korrekció** — javítasz, rossz, javítasz, rossz | Két sikertelen korrekció után `/clear` + jobb kezdő-prompt |
| **Túlírt CLAUDE.md** — a Claude a felét ignorálja | Könyörtelenül vágd ki, amit a kódból amúgy is tud; tedd hookba |
| **Bízz-de-ellenőrizd rés** — hihető, de a peremeseteket nem kezelő kód | MINDIG adj ellenőrzést (teszt, script, screenshot). Ha nem tudod igazolni, ne szállítsd ki |
| **Végtelen felfedezés** — hatókör nélküli „nézd át" | Szűk hatókör, vagy subagent, hogy ne egye a fő kontextust |

---

## 11. Másolható prompt-sablonok (pénzügyi/valutaváltó fókusszal)

**Új funkció, biztonságosan:**
```
Plan mód. Olvasd el TELJESEN a [mappa] érintett fájljait. Készíts tervet
PLAN.md-be: érintett fájlok, adatfolyam, peremesetek, elfogadási
kritériumok konkrét számpéldákkal. Még ne kódolj. Ami kétértelmű,
listázd nyitott kérdésként, ne találgass.
```

**Bug, gyökérok-javítással + reprodukáló teszttel:**
```
Tünet: [pontos leírás + hibaüzenet]. Valószínű hely: [fájl/mappa].
1) Írj előbb egy BUKÓ tesztet, ami reprodukálja a hibát (mutasd, hogy bukik).
2) Javítsd a gyökérokot, ne a tünetet.
3) Futtasd újra a tesztet, mutasd, hogy zöld.
```

**Kerekítés/jutalék/árfolyam — kötelező bizonyíték:**
```
Implementáld a [logika]. Pénzösszeg ne legyen float. Add meg a számpéldákat
tesztként [konkrét be- és kimenetek]. Implementálás után FUTTASD a teszteket,
és illeszd be a teljes kimenetet. Ha bármelyik bukik, javíts, és futtasd újra.
```

**Friss kontextusú felülvizsgálat commit előtt:**
```
Indíts subagentet: ellenőrizd a diffet a PLAN.md követelményeivel szemben.
Csak helyességet/követelményt érintő hiányt jelezz. Mutasd, melyik
követelmény hol valósult meg (fájl + sor).
```

---

## 12. Fejleszd az intuíciódat

Ezek kiindulópontok, nem dogmák. Néha *hagyni kell* a kontextust felhalmozódni (ha mélyen egy összetett problémában vagy, és a történet értékes). Néha *érdemes* kihagyni a tervezést (felfedező feladat). Néha egy *laza* prompt épp jó (látni akarod, hogyan értelmezi a problémát). Figyeld, mi működik: amikor a Claude remek kódot ad, jegyezd meg, mit csináltál — a prompt szerkezetét, a megadott kontextust, a módot. Idővel kialakul egy érzék, amit semmilyen útmutató nem ad meg.

---

## Források

- Best practices for Claude Code — hivatalos dokumentáció: https://code.claude.com/docs/en/best-practices
- Claude Code dokumentáció-index: https://code.claude.com/docs/llms.txt
- Bevezetés: Claude Opus 4.8 — Anthropic: https://www.anthropic.com/news/claude-opus-4-8
- Mi az új az Opus 4.8-ban — Claude API Docs: https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-8
- Claude Opus 4.8 termékoldal (árazás, képességek): https://www.anthropic.com/claude/opus
- CLAUDE.md / memória: https://code.claude.com/docs/en/memory
- Subagentek: https://code.claude.com/docs/en/sub-agents
- Hookok: https://code.claude.com/docs/en/hooks-guide
```
