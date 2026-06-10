# MANDATE — Univerzális AI Ügynök Protokoll (2026-05-31, P0)

> Forrás: user-átadott `universal_agent_protocol.md` (101 sor, teljes szöveg lent).
> Hatály: MINDEN ágens (Claude Code, Codex, Gemini), minden munkamenet.
> Ez a fájl a **kötelező munkamód-kiegészítés** — az eddigi mandate-ekkel ÖSSZHANGBAN.
> Konfliktusban a **repo-tény + a user explicit döntése** felülír.

## PROJEKT-SPECIFIKUS PRECEDENCIA (user-döntések 2026-05-31, kötelező)

A protokoll három pontban ütközik a projekt-szabályokkal; a user az alábbiakat döntötte:

1. **Plan-First (2. szakasz) → „Csak terv, ne állj meg".** Új/komplex feladatnál bemutatom
   a SPEC+PLAN-t 1 üzenetben, majd a YOLO-elv szerint AZONNAL folytatom megállás nélkül
   (a user menet közben leállíthat). NEM hard approval-gate. A globális CLAUDE.md YOLO
   („végezd el kérdezés nélkül") marad elsődleges a tool-végrehajtásra; a terv-bemutatás
   transzparenciát ad, nem blokkol.

2. **Valuable Final Product / Telepítő (3.3. szakasz) → „Mindig telepítő Downloads-ba".**
   A user FELÜLÍRTA a projekt „merge ≠ telepítő" szabályát: MINDEN mérföldkő végén telepítőt
   buildelek és a `C:\Users\Kósa Zoltán\Downloads` mappába teszem, a fájl jelenlétét méret
   (bájt) + név megadásával IGAZOLVA — backend-only PR esetén is. (Eddig: telepítő csak
   Electron-natív változásnál/milestone-záráskor. ÚJ: a milestone-záró telepítő-szállítás
   minden esetben kötelező végtermék.)

3. **Memória (5. szakasz) → vault, NEM `.memory` SQLite.** A protokoll `.memory && npm run mem`
   parancsai egy DEPRECATED rendszerre mutatnak ebben a projektben. A kanonikus aktív memória:
   `D:\repo\valutavalto-program\vault\` (sessions/ feedback/ ...). Session-keresés/-mentés ODA
   történik (NEM `.memory`). A protokoll szándéka (induló keresés, mérföldkő-mentés, záró
   összefoglaló) változatlanul kötelező, csak a vault-rendszerrel.

## ÖSSZHANG a meglévő mandate-ekkel (nem ír felül, kiegészít)

- 0. Négy alaptörvény = Claude Code munkamód 3 tilalma + bizonyíték-kényszer (már él; "opus48" branding elavult — lásd 2026-06-08 javítás a mandate fájlban).
- 1. Lost-in-the-Middle = opus48 dokumentum-olvasási fegyelem (már él).
- 2. Goal Protocol (North Star / Mérföldkő / Mikrocél) = ÚJ explicit elvárás, alkalmazandó.
- 3.1 Pre-Flight = session-zárási protokoll lokál gate (már él: teljes suite zöld push előtt).
- 3.2 CI Feedback (Sourcery/Copilot/Codex) = GitHub minőségbiztosítás zero-tolerance (már él).
- 3.4 Gyökérok + bukó-teszt-először + adverzariális review = research-first + TDD + 2-kör
  self-review (már él).
- 4. Egy szál = egy feladat = kontextus-kezelés (már él).

---

## FORRÁS — teljes szöveg (megőrzés, hivatkozás)

# UNIVERZÁLIS MESTERSÉGES INTELLIGENCIA ÜGYNÖK PROTOKOLL
*Egységesített, platform- és szoftverfüggetlen senior AI mérnöki keretrendszer és működési elv*

## 0. A NÉGY ALAPTÖRVÉNY (KIKÉNYSZERÍTHETŐ)
1. TÉNYALAPÚSÁG (Hallucináció Tilalom) — sosem hivatkozz nem-olvasott fájlra/függvényre/API-ra;
   verziókat/szignatúrákat forrásból; bizonytalanságot mondj ki.
2. BIZONYÍTÉK-KÉNYSZER (Hazugság Tilalom) — „kész/működik/zöld/build OK" CSAK lefuttatott
   parancs + kimenet bemutatásával.
3. TELJESSÉG (Lustaság/Csonkítás Tilalom) — nincs TODO/csonk; nagy feladat → bontás, de a leadott
   rész teljes és futtatható.
4. MÉRTÉKTARTÓ DOKUMENTÁLÁS ÉS KÓD-PRIORITÁS — egyetlen tömör igazságforrás; a dokumentálás ne
   vegye el a tokent a kódtól.

## 1. DOKUMENTUM-OLVASÁSI FEGYELEM
Sorszám szerinti teljes olvasás; szakasz-visszaigazolás; idézet-kényszer a közepéből; izolált
subagent-kutatás a fő kontextus védelmére.

## 2. PLAN-FIRST + GOAL PROTOCOL
Emberi kérés → gépi spec (bemenetek/kimenetek típussal+tartománnyal, üzleti szabályok lépésenként,
peremesetek+biztonság, elfogadási kritérium konkrétan). Jóváhagyási hurok (→ user-döntés: terv-
bemutatás, de megállás nélkül). Kétrétegű cél: North Star / Mérföldkő / Mikrocél — minden lépést
ehhez mérj; ha nem visz közelebb a mikrocélhoz, állj meg.

## 3. QA KAPUK
3.1 Pre-Flight: lint+build+typecheck+teszt 100% zöld push/merge/deploy ELŐTT.
3.2 CI Feedback: Sourcery/Copilot/Codex visszajelzések tételes feldolgozása a telepítő-build ELŐTT.
3.3 Valuable Final Product: telepítő build + Downloads mappa + méret/név bizonyíték (→ user-döntés:
    minden milestone végén kötelező, backend-only esetén is).
3.4 Gyökérok-kezelés; bukó-teszt-először bugfixnél; adverzariális diff-review friss subagenttel.

## 4. CONTEXT-GAZDÁLKODÁS
Egy szál = egy feladat; agresszív takarítás új feladatnál; tartós szabályok AGENTS.md/skill-ekbe.

## 5. MEMÓRIA PROTOKOLL
Induló keresés; mérföldkő-mentés (decision/error/learning/context); záró összefoglaló.
(→ projekt-korrekció: vault rendszer, NEM `.memory` SQLite.)
