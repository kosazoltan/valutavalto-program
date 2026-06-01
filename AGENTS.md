# AGENTS.md - AI coding agent szabalyzat

Ez a repo egyetlen, rovid, modellfuggetlen agent-szabalya. Platformfajlok
(`CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.github/copilot-instructions.md`,
Cursor/VS Code/Antigravity leirasok) csak kiegeszithetik, de nem irhatjak felul.

## 1. Cel

Az agent feladata: mukodo programkodot, tesztet, dokumentaciot vagy javitast
szallitani. Az ellenorzes a szallitas resze, nem onallo vegtelen tevekenyseg.

Alap mukodes:

1. Ertsd meg a feladatot a legkisebb elegseges kontextusbol.
2. Tervezz roviden: mi valtozik, miert, mivel bizonyitod.
3. Kodold vagy javitsd meg a kert dolgot.
4. Futtasd a kockazattal aranyos, relevans ellenorzest.
5. Ha bukik, root cause alapjan javitsd; ha ugyanaz a hiba ketszer visszajon,
   valts diagnosztikai tengelyt vagy jelents blokkolot.
6. Zarj rovid, tenyszeru osszefoglaloval.

## 2. Kontextus es tokenfegyelem

- Ne olvasd be a teljes vaultot, mandate-archivumot vagy minden szabalyfajlt.
- Mindig a konkret feladathoz kapcsolodo fajlokat olvasd.
- Ha hosszu dokumentum kell, csak a relevans szakaszt olvasd.
- Ha ellentmondas van memoria/mandate es repo-teny kozott, a repo aktualis
  kodja, migracioja, tesztje es git allapota az erosebb.
- Lost-in-the-middle vedelem: a feladat celjat, dontest es nyitott kockazatot
  tartsd rovid munkamemoriaban; ne temesd el hosszu idezetek koze.

## 3. Builder-first munkamod

- Ne allj meg puszta tervnel, ha a feladat megvalosithato.
- Ne kerj engedelyt rutin olvasasra, szerkesztesre, tesztre vagy buildre.
- Ne futtass teljes gate-lancot minden apro valtozasra.
- Ne nyiss uj nagy refaktort a kert javitas melle.
- Ha a felhasznalo agent-mukodest ker javitani, ne irj uzleti programkodot.

## 4. Ellenorzes kockazat szerint

### Mindig tilos

- hard-coded secret vagy credential commitolasa
- SQL/shell string-konkat user inputbol
- `eval`, `Function`, unsafe deserialization
- path traversal validacio nelkul
- nema `catch(Exception e){}` / `except: pass`
- hamis mock adat production valaszkent
- teszt skip/torles/assertion-gyengites csak a zold eredmenyert
- `--no-verify`, force push vedett agra, branch protection gyengitese

### Celzott ellenorzes eleg, ha

- kis, lokalis kod- vagy dokumentacios valtozas tortent;
- nincs dependency, auth, security, deploy, DB schema vagy CI modositas;
- a valtozas bizonyithato egy celzott testtel, linttel, typecheckkel vagy diff
  self-review-val.

### Teljesebb ellenorzes kell, ha

- push, merge, release vagy deploy tortenik;
- security/auth/permission/crypto/secret/logging/CI/dependency/schema erintett;
- installer vagy Electron runtime reteg valtozik;
- tobb modul kozotti szerzodes valtozik;
- korabbi ellenorzes bukott.

Deploy/release elott a security gate tovabbra is kotelezo:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

## 5. Hibajavitasi hurok

- Egy hibara legfeljebb ket azonos jellegu javitasi kiserlet mehet.
- Ha nincs haladas, tilos kenyszeresen modot valtogatni vagy ugyanazt ujra futtatni.
- Strategiavaltas csak bizonyitek alapjan: forrasolvasas, minimal repro,
  dokumentacio, log, teszt, dependency-verzio, kornyezeti ok vagy API-szerzodes.
- Ha objektiv blokkolas van, nevezd meg pontosan es add meg a kovetkezo hasznos
  lepest.

## 6. Mikor kell GitHub/AI review polling

- Csak push/PR/merge utan, vagy ha a felhasznalo review-visszaolvasast ker.
- Nem kell lokalis dokumentacio- vagy instruction-javitas kozben.
- `scripts/github-signal-check.ps1 <PR>` a PR-minoseg kapuja, nem minden chat-turn
  alaptevekenysege.

## 7. Zaro valasz minimuma

Rovid, tenyszeru zaras:

- mi valtozott;
- mely fajlok erintettek;
- milyen relevans ellenorzes futott vagy miert nem kellett/nem tudott futni;
- mi maradt bizonytalan vagy blokkolt.

Ne allits abszolut bizonyossagot. A helyes allitas: a repo ismert,
megvizsgalt agent-utasitas hibai javitva lettek; ismeretlen kulso agent runtime
viselkedesre nincs 100%-os garancia.

## 8. Platform fajlok szerepe

- `CLAUDE.md`: projekt- es domain-kontekstus, rovid parancsreferencia.
- `CODEX.md`, `GEMINI.md`, `.github/copilot-instructions.md`: platformrovidito.
- `AI_CONTRACT.md`: hard tiltasok es PR-meret plafon.
- `AI_CONSTITUTION.md`: rovid mukodesi alapelvek.
- `.cursor/rules/*`: csak celzott, nem allandoan mindent betolto szabalyok.

Ha egy platformfajl teljes gate-et vagy minden taskban security auditot kovetel,
azt ezzel a fajllal osszhangban kell ertelmezni: teljes gate csak magas
kockazatnal, push/merge/deploy/release elott kotelezo.