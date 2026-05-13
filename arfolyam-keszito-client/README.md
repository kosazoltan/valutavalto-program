# Helyi árfolyamkészítő kliens

Ez a csomag a főértéktáros gépén futó külön árfolyamkészítő alkalmazás
Electron GUI-ja és kommunikációs magja. A döntés: az árfolyam nem a szerveren készül, hanem helyi
alkalmazásban; a szerver hitelesített átvételi, validációs, audit és terítési
központ.

## Telepíthető GUI

```powershell
npm --prefix arfolyam-keszito-client run package:unsigned
```

Kimenet:

```text
arfolyam-keszito-client/release/Arfolyamkeszito-Setup-2.5.41.exe
```

A GUI `rate-maker` app módban indul, a fő képernyő az árfolyamkészítés. A
normál szerveres web UI nem kap elsődleges árfolyamíró szerepet.

## Folyamat

1. A főértéktáros Google Desktop OAuth-fal jelentkezik be. Az Electron main
   process RFC 8252/PKCE flow-t futtat, majd a backend `/auth/google-login`
   végpontját hívja `appMode=rate-maker` módban.
2. A kliens bejelentkezett főértéktárosi tokennel lekéri:
   `GET /api/v1/local-rate-maker/bootstrap`.
3. A kliens helyben elkészíti az árfolyamcsomagot.
4. A kliens `buildRatePackage()`-gel validálja és hash-eli a csomagot.
5. A kliens `POST /api/v1/local-rate-maker/packages/publish` végpontra küldi,
   `Idempotency-Key` fejléccel.
6. A szerver validálja, auditálja, `exchange_rate` rekordokba írja, majd outboxon
   keresztül kiküldi a pénztáraknak.
7. A pénztárak a meglévő automatikus `/exchange-rates/pos-current` szinkronnal
   olvassák be.

Az árfolyamkészítő build már nem tiltja a Google OAuth-ot. A desktop OAuth
adatokat a build a helyi, gitignore-olt `.env` konfigurációból olvassa be; ezek
nem kerülhetnek dokumentációba vagy verziózott fájlba.

## Példa

```ts
import { buildRatePackage, fetchBootstrap, publishRatePackage } from './dist-core/index.js'

const config = {
  serverBaseUrl: 'https://excvaluta.com',
  accessToken: '<bejelentkezett foertektar JWT>',
}

const bootstrap = await fetchBootstrap(config)
const workgroup = bootstrap.workgroups[0] as { id: string }

const pkg = buildRatePackage({
  groupId: workgroup.id,
  clientDeviceId: 'FOERTEKTAR-PC-01',
  clientVersion: '2.5.41',
  rates: [
    { currencyId: 1, buyRate: '395.10', sellRate: '398.10', officialRate: '396.50' },
  ],
})

const result = await publishRatePackage(config, pkg)
console.log(result.status, result.publicationId)
```

## Parancssori használat

```powershell
$env:RATE_MAKER_SERVER_URL='https://excvaluta.com'
$env:RATE_MAKER_ACCESS_TOKEN='<bejelentkezett foertektar JWT>'
npm run build
node dist-core/cli.js bootstrap
node dist-core/cli.js publish .\rates.json
```

`rates.json` formátum:

```json
{
  "groupId": "00000000-0000-0000-0000-000000000000",
  "clientDeviceId": "FOERTEKTAR-PC-01",
  "clientVersion": "2.5.41",
  "rates": [
    { "currencyId": 1, "buyRate": "395.10", "sellRate": "398.10", "officialRate": "396.50" }
  ]
}
```
