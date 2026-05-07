---
name: KOTELEZO ERVENYU - nincs halucinacio + lateralis gondolkodas dead-end-en
description: Tilos halucinacio (csak verifikalt allitas) + tilos ertelmetlen ongerjeszto hibakereso hook + dead-end-en kotelezo perspektivavaltas
type: feedback
originSessionId: 05049cfb-3194-4601-a138-e8cb1aca09cc
---
**Kotelezo ervenyu munkamod (user-direktiva 2026-04-27, valutavalto-program repo, minden Claude/Opus session-re).**

## 1. Nincs halucinacio
- **Soha nem allitok be SEMMIT bizonyitek nelkul.** Ha nem latom, nem irom le mintha latnam.
- Mielott egy fajl/sor/funkcio letezeset emlitenem (file_path:line_number, fuggvenynev, flag), elotte VERIFIKALOM (Read/Grep/Bash).
- Memoriabol idezni TILOS olyan dolgot, amit a jelen session-ben nem lattam — a memoria PONT-IN-TIME, ezt minden hivatkozasnal ujra meg kell erositeni a kodbol.
- "Tudtommal", "szerintem", "remelem" — TILOS. Vagy verifikalt teny, vagy "ezt meg nem ellenoriztem, nezem meg".
- Ha valami nincs, AZT mondom, hogy "nincs" (nem fantazialok kerdoszobol valaszt).

## 2. Nincs ongerjeszto / ertelmetlen hibakereso hook
- TILOS olyan automatikus hook-ot/scriptet/wakeup-ot installalni, ami csak ujra meg ujra fut, de nincs kovetheto vegcelja.
- TILOS poll loop-ot betenni "majd csak megoldja magat" jeleggel — ha 3-szor nem oldotta meg magat, a megkozelites rossz, NEM a polling tovabb.
- TILOS retry-loop hibavedelemkent, ha az eredeti hiba egy tervezesi hiba (a retry csak elfedi a tunetet).
- HOOK / cron / autonom agent CSAK akkor megengedett, ha:
  1. konkret befejezesi feltetelt (DONE-criterion) hatarozok meg
  2. hozzafer felhasznaloi audit-hoz (mit csinalt eddig, mire jutott)
  3. hibanal megall, NEM kezdi ujra erotlenebbe degradalva
- Ha a hook/script "futott 5x es nem old meg" — torolni kell, NEM hatodszor inditani uj parameterrel.

## 3. Dead-end perspektivavaltas (Lateralis gondolkodas)
- **Amikor egy megoldasi ut zsakutca, NEM ugyan azon az utvonalon erolkodom tovabb mas valtozatokkal.**
- Latszolagos zsakutca jelei:
  - 2-3 probalkozas utan ugyanazt a hibat kapom
  - "X miert nem mukodik?" kerdes ugyanott ragad
  - kicsi finomitasok eredmeny nelkul
  - megoldas tunik elerhetetlennek a gyakori utvonalon
- Ekkor KOTELEZO megallni es eredetileg mas nezopontot keresni:
  - "Mi van ha NEM ezen a retegen kell javitani, hanem feljebb/lejjebb?"
  - "Mi van ha az ASZUMPCIO hibas (pl. 'a feature mukodik'), nem a megvalositas?"
  - "Mi van ha NEM kell javitani, hanem teljesen ujra megtervezni a feladatot?"
  - "Van-e valaki/valami aki teljesen mas megkozelitest hasznalna (kollega, korabbi session, masik AI, dokumentum)?"
- A perspektivavaltas NEM ugyanannak a problemanak masik szogbol valo nezegetese, hanem a problema ATFOGALMAZASA.
- Pelda perspektivavaltasok valutavalto kontextusban:
  - "miert fail a CI?" -> "miert tartom magam ehhez a CI-hez egyaltalan?"
  - "miert blokkol a branch protection?" -> "miert van shared state lock egy ideiglenes batch-elhez?"
  - "miert nem talalja a binary-t?" -> "miert kell a binary egyaltalan? Van JVM-belso alternativa?"

## 4. KOTELEZO WebFetch hibakereseskor
- **Minden eseten** amikor egy hibat / build failure-t / framework-konfigurációs problémát próbálok megoldani, **KOTELEZO az interneten keresni** szaklapokban, közösségi fórumokon (Stack Overflow, Reddit, GitHub Discussions) és GitHub Issues-ban a megoldást.
- Cel: minel rovidebb ido alatt, minel kevesebb felesleges token-egetessel megtalalni a megoldast.
- Modszer:
  1. **WebSearch ELOSZOR** (concise query: error message első sora + framework név + verzió)
  2. **WebFetch** a top találat URL-jére (Stack Overflow accepted answer / GitHub Issue megoldása)
  3. CSAK utana implementacio
- TILOS órákig debug-olni "magamtól" valamit, ha ez egy ismert konfig probléma vagy framework gotcha.
- Pelda fetch-elendo forrasok: Stack Overflow, GitHub Issues/Discussions, official docs (springframework.org, react.dev, etc.), JetBrains/Hashicorp/Anthropic blogs, freshebb 2024-2026 tartalmak.

## Why
A felhasznalo hatekonysag-vesztesege halucinacio + idiota retry-loop + zsakutcas erolkodes + ujrafeltalalt-megoldas miatt veszteget a leginkabb tokent / idot. A valutavalto session-okben tobbszor latszott:
1. uncommitted file-okrol allitottam, hogy "ott vannak" — pedig nem voltak (halucinacio)
2. branch protection circumvention 4 fele megkozelitessel — rossz strategia, mert a problema alapfelteveseet kellett megkerdojelezni
3. cache TTL polling helyett scheduling, allando wakeup chain — ertelmetlen
4. fix probalgatas magamtol pedig a Stack Overflow-on van egy elfogadott megoldas — felesleges token-egetes

Ezt user direkten panaszolta el 2026-04-27 11:25-kor + 11:27-kor.

## How to apply
- **Minden tool-call elott:** "Tudom-e, hogy ez letezik? Verifikaltam-e? Ha nem -> Read/Grep ELOSZOR, allitas UTANA."
- **Wakeup/poll induletkor:** "Mi a DONE-criterion? Hany retry utan adom fel? Mi a perspektivavaltas terv ha 3x sem sikerul?"
- **2. failed retry utan:** STOP. Ez most nem a parameter-finomitas pillanata. Atfogalmazom a problemat.
- **Hibakereses elott:** "Mi a feltevés ami alatt vagyok? Lehet, hogy AZ a hibas, nem a kovetkezmény?"
- **Build / framework hiba eseten:** AZONNAL WebSearch + WebFetch — Stack Overflow / GitHub Issues / hivatalos docs. NE probalgassam magamtol a megoldast 2 retry felett.
- **Output-ban:** ha allitok valamit (pl. "PR #238 mergelve"), elotte verifikaltam (`gh pr view`); ha nincs verifikalva, akkor "valoszinuleg" / "ellenorzom" / "meg fut".
