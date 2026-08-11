# Kod-stilus — Valutavalto ERP

Ez a leiras a repo gepfuggetlen kod-formazasat rogziti. Celja, hogy tobb gepen
es tobb (akar kulonbozo) AI-ugynokkel folytatott fejlesztes utan se keveredjenek
ossze a stilusok: minden gep es minden ugynok ugyanazt a determinisztikus
formazast allitja elo.

## 1. Eszkozok es szerepuk

- **Prettier** (pinned, `3.x`) — a **formazo**: behuzas, sortordeles, idezojel,
  pontosvesszo, vesszok. A stilus egyetlen forrasa a gyoker `.prettierrc.json`.
- **ESLint** (`frontend-react/eslint.config.js`, `penztar-client/eslint.config.cjs`)
  — a **linter**: kod-helyesseg, react-hooks, i18n. **Nem formaz.** Mivel az
  ESLint nem tartalmaz formazo szabalyt (indent / quote / semi), a ket eszkoz
  nem utkozik — egymas mellett futnak.

## 2. A config helye

- `.prettierrc.json` — a stilus-szabalyok (gyoker, az egesz repora ervenyes).
- `.prettierignore` — mit NEM formaz a Prettier (build, generalt, markdown, archivumok).

## 3. Stilus-szabalyok

A config a kodbazis **tenylegesen mert** konvencioit rogziti (nem onkenyes
default). A felmeres mind a negy kliens-modulra kiterjedt.

| Beallitas | Ertek | Indok (mert felmeres) |
|---|---|---|
| `printWidth` | `100` | a kod ~95%-a 100 karakter alatt |
| `tabWidth` | `2` | 2-space behuzas, 0 tab mindenhol |
| `useTabs` | `false` | nincs tab |
| `semi` | `false` (default) | a domináns stilus pontosvesszo nelkuli |
| `singleQuote` | `true` | JS/TS stringek ~98%-a single quote |
| `jsxSingleQuote` | `false` | JSX attributumok ~92%-a double quote |
| `trailingComma` | `all` | tobbsoros listak vegen kovetkezetesen vesszo |
| `bracketSpacing` | `true` | `{ foo }` (space-szel) |
| `bracketSameLine` | `false` | Prettier default, illeszkedik |
| `arrowParens` | `always` | `(x) =>` a domináns |
| `endOfLine` | `auto` | lasd 5. pont (Windows / line ending) |

## 4. Modul-elteres: pontosvesszo (semi)

Egyetlen lenyeges elteres van a modulok kozott, ezert a config `overrides`
mechanizmussal **minden modul a sajat, jelenlegi stilusat** kapja:

- **`penztar-client`** → `semi: true` (pontosvesszos). Override-ban rogzitve.
- **`frontend-react`, `kozponti-client`** → `semi: false`
  (pontosvesszo nelkuli). Ez a config alapertelmezese.

Igy a Prettier bevezetese egyik modulban sem csap at pontosvesszot — a status
quot kodifikalja, nem irja felul.

> Megjegyzes: a `kozponti-client` ket portolt
> fajlja (`local-first.ts`, `vv-logger.ts`) tortenetileg pontosvesszos (a
> `penztar-client`-bol szarmazik). Ezek a modul native (no-semi) stilusahoz
> igazodnak, amikor legkozelebb formazva lesznek.

## 5. Line ending (Windows / tobb gep)

A `.gitattributes` `*.ts/*.tsx text=auto` szabalya miatt a repoban (git index)
minden fajl **LF**, a Windows working-tree-ben viszont **CRLF**. A Prettier
`endOfLine: "auto"` beallitasa a fajl meglevo sorvegzodeset **megorzi**, ezert:

- Windows-on a `prettier --check` NEM panaszkodik a CRLF working-tree-re.
- A git a commitkor LF-re normalizalja az indexet → a **commitolt kod
  gepfuggetlenul mindig LF**, akar Windows, akar Linux gep szerkesztette.

Ezert nem hasznaljuk az `endOfLine: "lf"`-et: az a working-tree-t is LF-re
kenyszeritene (tomeges CRLF→LF atiras), amit nem akarunk.

## 6. Hasznalat

```powershell
# Egy fajl formazasa (ezt hasznald szerkesztes utan)
npx prettier --write <fajl>

# Stilus-ellenorzes iras nelkul (CI-barat)
npm run format:check

# Teljes formazas (a .prettierignore altal nem kizart fajlokra)
npm run format
```

**VS Code / Cursor:** telepitsd a `esbenp.prettier-vscode` bovitmenyt, es
allitsd be:

```jsonc
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true
}
```

A Prettier verzio **pinned** (exact) a gyoker `package.json`-ban, igy minden
gepen es ugynoknel ugyanaz a verzio ugyanazt a formazast adja. NE frissitsd a
Prettier major verziot kulon dontes nelkul — a formazas verziok kozott valtozhat.

## 7. Masik gep / masik ugynok munkafolyamat

1. A repo klonozasa / pull utan: `npm install` (a Prettier devDependency a
   gyoker `package.json`-ban van pinned verzioval).
2. Uj fajl: mindig Prettier-formazott legyen (`npx prettier --write` vagy
   formatOnSave).
3. Szerkesztett meglevo fajl: lasd 8. pont (baseline).
4. Push elott: `npm run format:check` + `npm run lint`.

A stilus egyetlen forrasa ez a leiras + a `.prettierrc.json`. Ha egy ugynok
mas stilust akarna alkalmazni, az ervenytelen — ehhez a confighoz kell igazodni.

## 8. Baseline allapot (FONTOS)

A kodbazis a Prettier bevezetesekor **meg nem volt Prettier-formazva**. Ezert
amikor a Prettier eloszor rafut egy meglevo fajlra, a kezi sortordelest a
`printWidth: 100` menten ujraszamolja. Ez **nem a config hibaja** — a stilus-
dimenziok (idezojel, pontosvesszo, behuzas, trailing comma) valtozatlanok
maradnak, csak a tordeles normalizalodik.

Meres a bevezeteskor: egy teljes `npm run format` a kliens-modulokban kb.
**503 fajlt** erintene (csak ujratordeles, nincs stilus-flip).

Ket lehetoseg:

- **Ajanlott — egyszeri baseline:** tiszta working-tree-n, parhuzamos munka
  nelkul futtass egy `npm run format`-ot egy dedikalt `style: prettier baseline`
  commitban. Ezutan minden fajl formazott, es a tovabbi `prettier --write`-ok
  mar **csak a tenylegesen valtozott sorokat** erintik. A baseline-commit
  hash-et tedd a `.git-blame-ignore-revs` fajlba, hogy a `git blame` ne romoljon.
- **Atmeneti — fokozatos:** a config rogziti a stilust, de a meglevo fajlok csak
  akkor formazodnak, amikor legkozelebb hozzajuk nyulsz. Atmenetileg formazott es
  nem-formazott fajlok egyutt elnek. Hatranya: egy szerkesztett fajl elso
  formazasa nagy (az egesz fajlra kiterjedo) diffet kever a tenyleges valtozasba.

A baseline egyszeri lefuttatasa a leg-determinisztikusabb vegallapot, de mivel
tomeges diff, csak tudatosan, tiszta allapotban, a futo CI / parhuzamos gep /
nyitott feature-branch figyelembevetelevel szabad megtenni.
