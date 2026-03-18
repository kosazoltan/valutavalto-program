# Teljes Biztonsagi Audit es Vedelmi Rendszer

Verzio: 3.0  
Datum: 2026-03-18  
Klasszifikacio: Bizalmas - belso fejlesztoi hasznalatra

## Cel es hatokor

Kotelezo, megkerulhetetlen pre-deploy security baseline minden agentnek.  
Erintett stackek:

- Java (Spring Boot)
- Electron
- React (Vite/Next)
- Python (Django/Flask/FastAPI)
- Node.js (Express/Nest/Fastify)

## Kritikus mukodesi szabalyok

1. Minden agent minden coding taskban automatikusan alkalmazza ezt a baseline-t.
2. Deploy/release elott kotelezo a teljes security gate futtatasa.
3. `FAILED` vagy `BLOCKED` gate allapot eseten deploy tiltott.
4. Nincs feltetelezes: bizonyitekalapu riport kotelezo (`security-reports/latest/`).
5. Minden valtoztatas utan relevans tesztek futtatasa kotelezo.

## 1) Stack-felismeres (kotelezo)

Projekt gyokerben es almappakban kereso mintak:

- Java: `pom.xml`, `build.gradle`, `build.gradle.kts`
- Node/React/Electron: `package.json`, `package-lock.json`, `next.config.*`, `vite.config.*`
- Python: `requirements.txt`, `pyproject.toml`, `Pipfile`, `poetry.lock`

A gate script csak a detektalt stackhez tartozo checkeket futtassa.

## 2) Dependency audit minimum

- Java: `mvnw dependency-check:check`
- Node/React/Electron: `npm audit --omit=dev --audit-level=high`
- Python: `pip-audit`, `safety check`
- Supply chain: lockfile lint where applicable
- Opcionis: `snyk test --all-projects` (ha token/tool elerheto)

## 3) NVD API key (kotelezo Java CVE scannerhez)

- Kulcs: [NVD API key request](https://nvd.nist.gov/developers/request-an-api-key)
- Tarolas: kornyezeti valtozoban (`NVD_API_KEY`)
- Soha ne commitold a kulcsot forraskodba.
- Gate logolja, hogy kulcs be van-e allitva (ertek nelkul, maszkoltan).

## 4) Security gate kovetelmenyek

Kotelezo script tulajdonsagok:

- Explicit timeout minden scannerre
- Timeout/halozati akadas -> `BLOCKED`
- High/Critical finding -> `FAILED`
- Csak teljesen tiszta futas -> `PASSED`
- Osszesitett `gate-status.json` + scanner szintu `summary.json`
- `latest` riport symlink/snapshot logika

## 5) SAST es kodmintak minimum

- Hardcoded secret scan
- Gyenge kriptografia mintak (MD5/SHA-1/DES/ECB)
- SQL injection / command injection pattern scan
- Electron dangerous APIs scan
- React XSS-mintak (`dangerouslySetInnerHTML`, `eval`, `javascript:`) minimum ellenorzes
- Python veszelyes primitívek (`eval/exec/pickle/yaml.load unsafe`) minimum ellenorzes
- Node veszelyes API-k (`eval`, `new Function`, `child_process.exec`) minimum ellenorzes

## 6) Deploy gate dontes

- `GO` csak akkor, ha:
  - nincs `FAILED`
  - nincs `BLOCKED`
  - nincs nyitott High/Critical finding
- Egyebkent: `NO-GO`.

## 7) Dokumentacios kotelezettseg

Minden security valtozasnal frissitendo:

- `CHANGELOG.md`
- Agent policy file-ok (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `VSCODE.md`, `ANTIGRAVITY.md`)
- Universal index: `AI-AGENT-SECURITY-UNIVERSAL.md`
