# MANDATE — Claude Code munkamód (2026-05-31 → frissítve 2026-06-08, P0)

> ⚠️ **Branding-javítás 2026-06-08:** Az eredeti "Opus 4.8" modell-jelölés elavult volt (nem létező modell).
> A jelenlegi konfiguráció: `opusplan` (tervezés=Opus, végrehajtás=Sonnet) — lásd `feedback_cost_discipline_model_routing.md`.
> A tartalom érvényes és aktív marad.
>
> Forrás: user-átadott utasításkészlet (2026-05-31).
> Ez a fájl a **kötelező munkamód-kiegészítés** — az eddigi mandate-ekkel ÖSSZHANGBAN, nem helyettük.

## A HÁROM TILALOM (kikényszeríthető, nem óhaj)
1. **Hallucináció TILOS** — SOHA ne hivatkozz nem-olvasott/nem-ellenőrzött fájlra, függvényre, API-ra, libre, verzióra. Bizonytalanság esetén OLVASD EL ELŐSZÖR. Ha nem ellenőrizhető: MONDD KI („ezt nem ellenőriztem").
2. **„Hazugság" (bizonyíték nélküli sikerjelentés) TILOS** — „kész/működik/teszt zöld/build sikeres" CSAK lefuttatott parancs + kimenet bemutatásával. Futtatás nélküli sikerjelentés tilos.
3. **Lustaság TILOS** — nincs `// TODO`, nincs „... ide jön a többi", nincs csonkolt függvény (kivéve explicit kérés). Túl nagy feladat → mondd ki + bontsd, de amit leadsz, futtatható és teljes.

## BIZONYÍTÉK-KÉNYSZER (a leghatékonyabb hallucináció-ellenes eszköz)
Állítást csak parancs+kimenet párral. Egy állítást olcsóbb ellenőrizni, mint a munkát újracsinálni.

## ALAP-MUNKAFOLYAMAT (kódhoz)
Felfedezés (plan, nincs módosítás) → Terv (érintett fájlok, adatfolyam, peremesetek, elfogadási kritérium SZÁMPÉLDÁVAL) → Megvalósítás → **Ellenőrzés** → Commit (kicsi, fókuszált).
- Tervezést kihagyni CSAK ha 1 mondatban leírható a diff (átnevezés, log-sor).

## „LOST IN THE MIDDLE" ELLEN (a user kiemelt elvárása)
- Dokumentum/fájl olvasásnál a KÖZEPÉT is el kell olvasni, nem csak elejét-végét.
- Nagy doknál: sorszám-tartomány teljes olvasás + a végén szakaszcímek felsorolása bizonyítékként.
- Sok fájl → **subagent/Workflow** olvassa külön kontextusban, csak az összefoglaló jön vissza.
- TILOS hatókör nélküli „nézd át" — mindig konkrét fájl/mappa/kérdés.

## ELLENŐRZÉS 4 SZINTJE (pénzügyi szoftvernél a legfontosabb)
1. Promptban: „futtasd a tesztet, javíts amíg zöld".
2. Munkameneten át: cél-feltétel újraellenőrzés.
3. Determinisztikus kapu: Stop hook / lokál gate.
4. Második vélemény: **adverzariális ellenőrző subagent friss kontextusban** (`/code-review`, Workflow verify-fázis) — az ír, MÁS ellenőriz.

## PÉNZÜGYI DOMÉN EXTRA SZIGOR
- Pénzösszeg SOHA float/double → BigDecimal/egész (projektben: BigDecimal + HungarianRounding 5 Ft).
- Kerekítés/árfolyam/jutalék/AML KÖTELEZŐ teszttel, KONKRÉT SZÁMPÉLDÁKON bizonyítva.
- Minden külső bemenet validálva.
- **MINDIG ember/extra-figyelem:** árfolyam+kerekítés, jutalék, pénzmozgás, DB-migráció (főleg oszlop-törlés), jogosultság, audit-nyomvonal, AML-küszöbök.

## SPEC-ELŐSZÖR (laza emberi kérés → gépi spec)
Laza kérésből NE kezdj kódolni. Először: bemenetek(típus+tartomány), kimenetek, üzleti szabályok lépésenként, peremesetek+hibakezelés, elfogadási kritérium számpéldákkal, mi NINCS hatókörben. Kétértelműség → nyitott kérdés (AskUserQuestion), NEM találgatás.

## KONTEXTUS-KEZELÉS
- Független feladatok közt friss kontextus; körkörös korrekció (2× sikertelen) után újrakezdés jobb prompttal.
- Workflow/subagent a nagy olvasásokhoz, hogy a fő kontextus tiszta maradjon.

## ESZKÖZÖK (a projektben már élnek)
- Workflow (dynamic, Max-csomag): fan-out olvasás + adverzariális verify — EZT HASZNÁLJUK az audit/review körökhöz.
- Subagent: `Explore` (olvasás), `general-purpose` (komplex), kód-review friss kontextusban.
- Effort: kritikus pénzügyi logikára / nehéz bugra magasabb gondolkodás; rutinra alap.

## ÖSSZHANG a meglévő mandate-ekkel
Ez kiegészíti (nem írja felül): nem-informatikus-végfelhasználó alapelv, session-zárási protokoll, folyamatos tesztelési protokoll, research-first, security-gate, V234 error_code, GitHub minőségbiztosítás (Codex/Sourcery/Copilot zero-tolerance), 2-kör merge előtt.
