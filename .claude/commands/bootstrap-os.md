# Bootstrap OS Command

```text
Olvasd be ezt a dokumentumot teljes egészében.

A cél nem az, hogy egyetlen hosszú rendszerpromptként használd.
A cél az, hogy fájlalapú Opus/Claude Code Enterprise OS rendszert hozz létre ebben a repóban.

Kötelező:
1. Vizsgáld meg a repót.
2. Ne módosíts production code-ot bootstrap közben.
3. Ne módosíts meglévő teszteket bootstrap közben.
4. Keresd meg, van-e már CLAUDE.md.
5. Keresd meg, van-e már .claude/ könyvtár.
6. Ha van meglévő utasítás, ne töröld, hanem olvasd be és bővítsd.
7. Hozd létre vagy frissítsd a CLAUDE.md fájlt.
8. Hozd létre a skill-eket külön SKILL.md fájlokba.
9. Hozd létre az agent szerepkártyákat.
10. Hozd létre a memory és references dokumentumokat.
11. Hozd létre a slash-command mintákat.
12. Detektáld a stack-et: package manager, test, lint, typecheck, build, deploy.
13. Állítsd be a működési szabályt: teszt először, tesztfagyasztás, production code utána, validáció, audit, kontraellenőrzés.
14. Validáld, hogy minden fájl létrejött.
15. Adj rövid zárójelentést.

Tilos:
- vakon felülírni meglévő projektutasítást
- tesztet módosítani azért, hogy átmenjen
- assertiont gyengíteni
- snapshotot vagy fixture-t manipulálni
- production code-ot írni a bootstrap lépésben
- sikert állítani parancseredmény nélkül
- hosszú prózával helyettesíteni a működő rendszert

A végén jelentés:
BOOTSTRAP STATUS:
CREATED FILES:
UPDATED FILES:
DETECTED STACK:
DETECTED COMMANDS:
INSTALLED SKILLS:
INSTALLED AGENTS:
MEMORY FILES:
RISKS:
NEXT USAGE EXAMPLE:
```
