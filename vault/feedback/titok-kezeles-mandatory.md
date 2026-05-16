# Titkos kulcsok kezelése — kötelező érvényű mandate (2026-05-16)

**Forrás:** repo-tulajdonos user-direktíva, 2026-05-16. A mandate forrás-dokumentum off-repo, az operátor lokális Downloads mappájában tárolt (verzió 1.0). **Hatály:** minden beszélgetés, minden program, minden fájl-művelet.

**Why:** 2026-05-16 incidens — az AI agent (Claude Opus 4.7) kompromittálta a Backblaze master key-t + bucket-scoped key-t + Tailscale authkey-t azzal, hogy a credentials-eket sima szövegként beírta a chatbe és a `Downloads/` mappa MD fájljaiba. Az AI alapelvei szerint is tilos, de a user explicit direktívával is megerősítette mandate-szerűen.

**How to apply:** Minden válasz előtt, minden tool-call előtt, minden fájl-írás előtt az ellenőrzőlista végrehajtása kötelező.

---

## 1. ALAPELVEK (NEM TÁRGYALHATÓK)

1. **A titkos érték SOHA nem szerepelhet sima szövegben** — sem chat-ben, sem kódblokkban, sem kommentben, sem hibajelentésben, sem commit message-ben, sem fájlnévben, sem URL query paraméterben.
2. **A titok mindig változón / placeholder-en / referencián keresztül használandó** — `process.env.X`, `os.environ["X"]`, `${SECRET}`, secret manager hívás.
3. **A titok forrása mindig külső** — `.env` (gitignored), `secrets.json` (gitignored), env var, secret manager. Soha NE hardcode-old.
4. **Ha a user beilleszt egy titkot a chat-be:** NE ismételd meg, figyelmeztesd hogy ROTÁLNI kell, placeholder-rel folytasd.
5. **Ha titkot tartalmazó fájlt megnyitsz** (Read tool): NE írd ki a tartalmat a chat-be / Bash output-ba.
6. **NE küldj titkot logba**, `console.log`-ba, `print`-be, debug-ba (még részlegesen sem).
7. **NE tegyél titkot URL-be query paraméterként** — mindig Authorization header.
8. **NE másold titkot ideiglenes fájlba** "csak a teszthez".

## 2. TIPIKUS TITOK-MINTÁZATOK (detektorhoz)

| Provider | Prefix / formátum |
|---|---|
| OpenAI | `sk-`, `sk-proj-`, `sk-svcacct-` |
| Anthropic | `sk-ant-api01-`, `sk-ant-api03-` |
| Stripe | `pk_live_`, `sk_live_`, `pk_test_`, `sk_test_` |
| GitHub | `ghp_`, `gho_`, `github_pat_`, `ghs_` |
| Slack | `xoxb-`, `xoxp-`, `xoxa-` |
| AWS | `AKIA...` Access Key, hosszú base64 Secret |
| Google Cloud | `AIza...` API key, service account JSON |
| JWT / id_token | `eyJ` prefix |
| PEM / SSH private key | `-----BEGIN [...] PRIVATE KEY-----` |
| Backblaze B2 | `K00` (applicationKey), `00...` (25-char keyID) |
| Tailscale | `tskey-auth-`, `tskey-api-` |
| Sentry DSN | `https://<key>@<host>.ingest.sentry.io/...` |
| DB URL | `postgres://`, `mysql://`, `mongodb+srv://` user:pass közbeékelve |

## 3. PRE-OUTPUT ELLENŐRZŐ LISTA

Minden response / fájl-write / Bash kimenet előtt:

- [ ] Tartalmaz-e a kimenet titok-mintázatot (lásd fenti táblázat)?
- [ ] Tartalmaz-e `.env` vagy `secrets.json` tartalmát placeholder helyett?
- [ ] URL titkos query-paraméterrel?
- [ ] Logoltam-e titkot debug-hoz?

**BÁRMELYIKRE IGEN → STOP, javítsd, csak utána küldd a választ.**

## 4. INCIDENT RESPONSE

Ha mégis felbukkan egy titok a beszélgetésben (akár user-input, akár fájl-tartalom):

1. NE ismételd meg semmilyen formában
2. Figyelmeztetés a usernek:
   > "⚠️ Titkos érték került a beszélgetésbe / fájlba. Kérlek azonnal:
   > 1. Rotáld a kulcsot a kibocsátó felületén
   > 2. Frissítsd minden olyan helyen ahol használatban van (.env, secrets.json, CI/CD, deploy env)
   > 3. Ha publikus repo-ba is bekerülhetett, használj git-filter-repo vagy BFG-t"
3. Folytasd a feladatot placeholder hivatkozással
4. NE logold az incidenst olyan helyre ami a titkot megőrizné

## 5. PÉLDÁK — ROSSZ vs. JÓ

### API hívás

❌ `fetch("...", { headers: { "Authorization": "Bearer sk-proj-AbCd..." } })`

✅ `fetch("...", { headers: { "Authorization": \`Bearer ${process.env.OPENAI_API_KEY}\` } })`

### Adatbázis

❌ `new Pool({ connectionString: "postgres://user:p4ssw0rd@host:5432/db" })`

✅ `new Pool({ connectionString: process.env.DATABASE_URL })`

### User beilleszt egy kulcsot

❌ "Rendben, beállítom a `sk-proj-abc...` kulcsot."

✅ "⚠️ A kulcs exponálódott — rotáld azonnal. A rotált új kulcsot tedd a `.env`-be `OPENAI_API_KEY=...` néven. Én `process.env.OPENAI_API_KEY` placeholderrel hivatkozom rá."

## 6. AI-OLDALI WORKFLOW (KÖTELEZŐ)

- Read tool egy fájl titok-tartalmával: oké, de a kimenet NE menjen sima szövegként chatre / Bash output-ba
- Bash használatkor: `B2_KEY_ID=$VAR && curl -u "$B2_KEY_ID:$B2_APP_KEY"` — NE echo-zd vissza a `$B2_KEY_ID` / `$B2_APP_KEY` értéket
- MD-fájl írásánál: a credentials placeholderrel hivatkozottak legyenek; a user SEPARATE channel-en kapja a tényleges értéket
- Bash output redact: ha API válasz tartalmaz secret-et, ne print-eld; mentsd file-ba, és a következő lépés ne echo-zza

## 7. KIVÉTEL — NINCS

Sem "csak teszt", sem "csak gyorsan", sem "csak privát beszélgetés", sem "csak helyileg fut". Soha.

---

## 2026-05-16 incidens dokumentálva

Az AI (Claude Opus 4.7) a Backblaze B2 master key + bucket-scoped key + Tailscale authkey-t kompromittálta:
- Sima szövegű Bash parancsokban (user-visible Bash output)
- Sima szövegű MD fájlokban a `Downloads/` mappában (a user által közvetlenül elérhető)

A user joggal jelezte a mandate-szabály-szegést. **Rotálási akció szükséges** mindhárom kulcsra a következő felületeken:
- Backblaze: https://secure.backblaze.com/app_keys.htm
- Tailscale: https://login.tailscale.com/admin/settings/keys

A jelen mandate-vault entry biztosítja, hogy a következő session NE ismételje meg ezt a hibát.

---

**Verzió:** 1.0
**Forrás dokumentum:** `C:\Users\Kósa Zoltán\Downloads\AI_titok_kezeles_utasitas.md`
**Hatály:** azonnal, minden további beszélgetésben, minden programozási feladatban
