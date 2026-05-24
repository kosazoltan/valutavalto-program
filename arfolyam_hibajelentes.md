# ÁRFOLYAMKÉSZÍTŐ ÉS SZINKRONIZÁCIÓS INTEGRITÁS-AUDIT JELENTÉS (2026-05-24)

> **Verzió:** 2.26.40  
> **Státusz:** COMPLETED (Exchange Rate Integrity Review)  
> **Biztonsági Kapuk:** Zero-Trust Verification Guard (npm run agent:guard) lefutott  
> **Cél-Repó:** `valutavalto-program`  
> **Auditor AI:** Antigravity Senior Principal Security Architect & Financial Cryptographer  

---

## 1. MŰSZAKI KONTEXTUS (TECHNICAL CONTEXT)

A valutaváltó program monorepójában az árfolyamok előállítását és kiküldését (Publishing Pipeline) a főértéktáros végzi az **Árfolyamkészítő Kliens** (`arfolyam-keszito-client`) segítségével. A rendszer a kiemelt adatintegritás és letagadhatatlanság (non-repudiation) biztosítására egy lokális csomag-aláírást és hash-láncolást (Local Rate Package) alkalmaz:
- A kliens a publikálandó vételi, eladási és limit rátákból összeállít egy JSON csomagot.
- SHA-256-os hash-t számít belőle: `clientPackageHash`.
- Beküldi a backend `/local-rate-maker/packages/publish` végpontjára.
- A központi backend szerver (`RateCreationService.java`) kiszámítja a szerveroldali hash-t (`serverPackageHash`), és a csomagot a `RatePublishService.java`-n keresztül érvényesíti az aktív deviza-szinteken (`ExchangeRate` tábla) és WebSocketen továbbítja a pénztáraknak.

A kód- és logikai audit során **3 kritikus és súlyos adatintegritási, kriptográfiai és API illeszkedési hibát** azonosítottunk ebben a folyamatban. Ezek a hibák teljesen meghiúsítják az adatintegritás ellenőrzését és árfolyam-manipulációhoz vezethetnek.

---

## 2. MEGÁLLAPÍTÁSOK RÉSZLETES LEÍRÁSA (DETAILED FINDINGS)

### #ERR-RATE-01: Megszakadt Kliens-Szerver Házasság a Helyi Árfolyamcsomag Hashingnél (Hiányzó és Inkonzisztens Kulcsok)

#### 1. Műszaki probléma leírása
A kliens oldalon az árfolyamkészítő API ([exchange-rates.ts](file:///d:/repo/valutavalto-program/frontend-react/src/services/api/exchange-rates.ts#L326-L347)) a `buildLocalRatePackage` metódussal hozza létre a hashelendő JSON alapot:

```typescript
326: async function buildLocalRatePackage(data: PublishGroupRateRequest) {
...
333:   const packageWithoutHash = {
334:     clientPackageId,
335:     clientDeviceId: await getRateMakerDeviceId(),
336:     clientVersion,
337:     createdAt,
338:     groupId: data.groupId,
339:     operatorNote: 'Helyi főértéktárosi árfolyamkészítő', // <-- JELEN VAN
340:     rates: data.rates,
341:   }
342: 
343:   return {
344:     ...packageWithoutHash,
345:     clientPackageHash: await sha256Hex(JSON.stringify(packageWithoutHash)),
346:   }
347: }
```

Azonban a backend oldalon a [RateCreationService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java#L606-L622) `computeServerPackageHash` metódusa az alábbiak szerint építi fel a canonical map-et a szerveroldali hash kalkulációhoz:

```java
606:     private String computeServerPackageHash(LocalRatePackageDto packageDto) {
607:         try {
608:             Map<String, Object> canonical = new LinkedHashMap<>();
609:             canonical.put("clientPackageId", packageDto.getClientPackageId());
610:             canonical.put("clientDeviceId", packageDto.getClientDeviceId());
611:             canonical.put("clientVersion", packageDto.getClientVersion());
612:             canonical.put("createdAt", packageDto.getCreatedAt()); // <-- Instant objektum!
613:             canonical.put("groupId", packageDto.getGroupId());
614:             canonical.put("rates", packageDto.getRates());
615:             // AZ operatorNote MEZŐ HIÁNYZIK!
```

Ez a megvalósítás **két okból is teljesen hibás**:
1. **Hiányzó mező:** A szerveroldali canonical mapből teljesen kimarad a kliens által beletett `operatorNote` ("Helyi főértéktárosi árfolyamkészítő") mező. Emiatt a hashelendő stringek tartalma eltér, így **a kliens és a szerver által számított SHA-256 hash SOHA nem fog megegyezni**.
2. **Adattípus eltérés:** A kliensoldalon a `createdAt` egy standard ISO string (pl. `"2026-05-24T17:39:41.937Z"`). A backend DTO-ban ez `java.time.Instant` objektummá parsolódik. Amikor a Jackson `objectMapper.writeValueAsString(canonical)` lefut a backendben, a dátumot az ObjectMapper beállításoktól függően vagy float timestamp formátumba (pl. `1779644381.937`), vagy nanomásodperces ISO formátumba írja ki, ami eltér a kliens JavaScript által generált string formátumtól.

#### 2. Hatás és üzleti kockázat
- Az árfolyamcsomagok integritásának hitelesítése elvi szinten megbukik.
- A tranzakció-kiküldés és csomag-szinkronizáció megakad, vagy a naplózott adatok hash-láncolása megszakad, ami hatósági (MNB) vizsgálat során szankciókat von maga után.

#### 3. AI Ügynök által Végrehajtható Javítási Terv

**A. Lépés: Kliensoldali canonical JSON szigorítás (`exchange-rates.ts`)**
Kivezetjük az `operatorNote` mezőt a hashelés alapjául szolgáló objektumból, és a `createdAt` mezőt fixen stringként adjuk át:

```typescript
// exchange-rates.ts refaktorálás
async function buildLocalRatePackage(data: PublishGroupRateRequest) {
  const clientPackageId = crypto.randomUUID()
  const createdAt = new Date().toISOString() // ISO 8601 string
  const clientVersion = typeof window !== 'undefined' && window.electronAPI?.getAppVersion
    ? await window.electronAPI.getAppVersion()
    : (import.meta.env.VITE_APP_VERSION ?? __APP_VERSION__)

  // Szigorú, canonical sorrendű hashelendő struktúra (operatorNote nélkül!)
  const canonicalData = {
    clientPackageId,
    clientDeviceId: await getRateMakerDeviceId(),
    clientVersion,
    createdAt,
    groupId: data.groupId,
    rates: data.rates,
  }

  const clientPackageHash = await sha256Hex(JSON.stringify(canonicalData))

  return {
    ...canonicalData,
    operatorNote: 'Helyi főértéktárosi árfolyamkészítő', // Az audit megjegyzés kívül marad a hashen
    clientPackageHash,
  }
}
```

**B. Lépés: Szerveroldali canonical hash számítás szinkronizálása (`RateCreationService.java`)**
Módosítsuk a `computeServerPackageHash` metódust, hogy a `createdAt` dátumot pontosan a kliens által küldött string formátumban hashelje:

```java
// RateCreationService.java módosítás
private String computeServerPackageHash(LocalRatePackageDto packageDto) {
    try {
        Map<String, Object> canonical = new LinkedHashMap<>();
        canonical.put("clientPackageId", packageDto.getClientPackageId());
        canonical.put("clientDeviceId", packageDto.getClientDeviceId());
        canonical.put("clientVersion", packageDto.getClientVersion());
        
        // A createdAt Instant objektumot pontosan ISO-8601 stringgé alakítjuk vissza
        String formattedDate = packageDto.getCreatedAt() != null 
                ? packageDto.getCreatedAt().toString() 
                : "";
        canonical.put("createdAt", formattedDate);
        canonical.put("groupId", packageDto.getGroupId().toString());
        canonical.put("rates", packageDto.getRates());

        byte[] json = objectMapper.writeValueAsString(canonical).getBytes(StandardCharsets.UTF_8);
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        return HexFormat.of().formatHex(digest.digest(json));
    } catch (JsonProcessingException | NoSuchAlgorithmException e) {
        throw new IllegalStateException("Árfolyamcsomag hash számítás sikertelen", e);
    }
}
```

---

### #ERR-RATE-02: Bypassed Kliens-oldali Hash Verifikáció a Backendben (Fail-Open Integrity Leak)

#### 1. Műszaki probléma leírása
Bár a kliens kiszámítja és beküldi a `clientPackageHash`-t a `/local-rate-maker/packages/publish` végponton, a backend oldali [RateCreationService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java#L454-L496) `publishLocalRatePackage` metódusa kiszámítja ugyan a `serverPackageHash` értéket, de **SEHOL nem veti össze a kliens által beküldött `clientPackageHash` értékkel**!

```java
463:         String serverPackageHash = computeServerPackageHash(packageDto);
464:         GroupRateDTO groupRateDTO = GroupRateDTO.builder()
...
477:         RatePublication publication = publishGroupRateInternal(groupRateDTO, notes, metadata);
```

Nincs semmilyen integritás-ellenőrzési kapu, amely elutasítaná a csomagot eltérés esetén.

#### 2. Hatás és biztonsági kockázat
- **Integrity bypass / Man-in-the-Middle:** Ha egy támadó a hálózaton elfogja az árfolyam-publikálási kérést, és önkényesen átírja az árfolyamokat (pl. kedvezőbb EUR/HUF vételi rátát állít be a saját pénztárához), a backend ellenőrzés nélkül elfogadja és kiküldi azt a hálózatba. A szerver által kiszámított `serverPackageHash` egyszerűen felülírja a hibás értéket a biztonsági naplóban, elfedve a manipulációt.

#### 3. AI Ügynök által Végrehajtható Javítási Terv
Építsünk be egy szigorú verifikációs kaput a `publishLocalRatePackage` metódus legelejére:

```java
// RateCreationService.java javítása
public LocalRatePublishResponseDto publishLocalRatePackage(LocalRatePackageDto packageDto) {
    if (packageDto.getGroupId() == null) {
        throw new ValidationException("Helyi árfolyamcsomag csak explicit munkacsoporttal publikálható.");
    }
    UUID companyId = SecurityUtils.getCurrentCompanyId();
    if (ratePublicationRepository.existsByCompanyIdAndClientPackageId(companyId, packageDto.getClientPackageId())) {
        throw new ValidationException("Ez az árfolyamcsomag már beérkezett: " + packageDto.getClientPackageId());
    }

    // Integritás ellenőrzés és hash verifikáció!
    String serverPackageHash = computeServerPackageHash(packageDto);
    if (packageDto.getClientPackageHash() == null || !packageDto.getClientPackageHash().equals(serverPackageHash)) {
        log.warn("Árfolyamcsomag integritás hiba! clientHash={}, serverHash={}, packageId={}",
                packageDto.getClientPackageHash(), serverPackageHash, packageDto.getClientPackageId());
        throw new ValidationException("Árfolyamcsomag integritás-ellenőrzés sikertelen (Hash mismatch).");
    }

    // ... (folytatás változatlan)
}
```

---

### #ERR-RATE-03: Árfolyam-publikálási Áthágás és Helytelen API Végpont Összevont Kliens Esetén (Merged Client Flavor Bypass)

#### 1. Műszaki probléma leírása
A kliensoldali [exchange-rates.ts](file:///d:/repo/valutavalto-program/frontend-react/src/services/api/exchange-rates.ts#L391-L402) `publishGroupRate` metódusában a publikálás logikája a build-time-ban beállított `VITE_APP_FLAVOR` környezeti változó alapján dől el:

```typescript
391:   publishGroupRate: async (data: PublishGroupRateRequest): Promise<void | LocalRatePublishResponse> => {
392:     if (import.meta.env.VITE_APP_FLAVOR === 'rate-maker') {
393:       const ratePackage = await buildLocalRatePackage(data)
           // Helyi csomag küldése a /local-rate-maker/packages/publish végpontra
394:       const response = await api.post<LocalRatePublishResponse>(...);
399:       return response.data
400:     }
401:     await api.post('/rate-creation/publish-group-rate', data)
402:   },
```

Az új, összevont `kozponti-client` (Központi Munkaállomás) esetén a `VITE_APP_FLAVOR` változó build-time értéke `'central-workstation'`. Ha a felhasználó az alkalmazás indításakor a magyar nyelvű választó-ablakban az **Árfolyamkészítő** (`rate-maker`) üzemmódot választja, az Electron main folyamat az `activeAppMode = 'rate-maker'` állapottal indul el.

Azonban a frontend Vite bundle a build-time inlining miatt az `import.meta.env.VITE_APP_FLAVOR === 'central-workstation'` állapotot látja. Emiatt az árfolyam-publikáláskor a program **a `else` ágra fut rá**, és megpróbálja közvetlenül meghívni a `/rate-creation/publish-group-rate` végpontot a lokális csomag-hashing és aláírás-generálás helyett.

#### 2. Hatás és kockázat
- Az összevont Központi munkaállomásból futtatott árfolyamkészítés során a publikálás azonnal meghiúsul (a backend elutasítja a közvetlen, nem-aláírt hívásokat a `rate-maker` appMode-dal bejelentkezett felhasználóktól), vagy kikerüli az idempotencia láncolatot.

#### 3. AI Ügynök által Végrehajtható Javítási Terv
Módosítsuk a `publishGroupRate` feltételét, hogy a futásidejű `appMode`-ot (vagy az Electron-tól jövő konfigot) vegye alapul a statikus build-time környezeti változó helyett:

```typescript
// exchange-rates.ts refaktorálása a dinamikus appMode támogatásához:
publishGroupRate: async (data: PublishGroupRateRequest): Promise<void | LocalRatePublishResponse> => {
  // Megnézzük a session-ben tárolt tényleges futásidejű módot (pl. window.electronAPI konfigurációból)
  const electronApi = typeof window !== 'undefined' ? window.electronAPI : undefined;
  const runtimeMode = electronApi?.getConfig ? await electronApi.getConfig('app_mode') : null;
  
  const isRateMakerMode = import.meta.env.VITE_APP_FLAVOR === 'rate-maker' || runtimeMode === 'rate-maker';

  if (isRateMakerMode) {
    const ratePackage = await buildLocalRatePackage(data)
    const response = await api.post<LocalRatePublishResponse>(
      '/local-rate-maker/packages/publish',
      ratePackage,
      { headers: { 'Idempotency-Key': ratePackage.clientPackageId } },
    )
    return response.data
  }
  
  await api.post('/rate-creation/publish-group-rate', data)
}
```

---

## 3. ZÁRÓ SELF-REVIEW ÉS DÖNTÉS

Az árfolyamkészítő integritási hibáinak (#ERR-RATE-01 - #ERR-RATE-03) javítása elengedhetetlen a pénzügyi tranzakciók letagadhatatlanságának és a hálózati támadások elleni védelemnek a biztosításához.

Mivel kódmódosítás ebben a fázisban nem volt engedélyezve (Audit-Only fázis), forráskód-módosítás nem történt, de a verifikációs kapuk zöldek.

## Állapot
Kész (Árfolyam-integritási hibajelentés sikeresen elmentve).

## Modell és hatály
- modell/tool: Gemini / Antigravity Agent
- szabályzat: AGENTS.md (multi-modell v2)
- bizonyíték-időpont: 2026-05-24T21:14:00+02:00

## Változtatott fájlok
- [arfolyam_hibajelentes.md](file:///d:/repo/valutavalto-program/arfolyam_hibajelentes.md): ÚJ árfolyam-integritási és szabályozási hibajelentés elmentése a monorepóban.
