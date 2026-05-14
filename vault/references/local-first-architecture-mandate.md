# Local-first architektúra mandate — Valutaváltó ERP

**Dátum:** 2026-05-14
**Státusz:** KÖTELEZŐ ÉRVÉNYŰ — minden Electron kliens + backend fejlesztésre
**Forrás:** Kósa Zoltán user-direktíva + 3 db local-first utasításfájl

## Alapelv

A local-first modellben a felhasználó eszközén lévő helyi adatbázis az első rangú munkaterület. Az alkalmazás innen olvas, ide ír, offline is működik, a hálózat háttérben szinkronizál. Ez NEM cache, NEM optimistic UI.

## 7 Ink & Switch ideál (kötelező követelmény)

1. Nincs várakozási spinner az alapműveleteknél
2. A munka nincs egyetlen eszközbe zárva
3. A hálózat opcionális, nem működési feltétel
4. A kollaboráció természetes és zavartalan
5. Az adatok hosszú távon megőrizhetők
6. Biztonság és adatvédelem alapértelmezett
7. A felhasználó birtokolja és kontrollálja az adatait

## Architekturális rétegek

```
UI / View layer
  -> lokális query/subscription réteg
    -> lokális perzisztens tároló (SQLite)
      -> változásnapló / outbox
        -> sync adapter
          -> backend API (szinkron + validáció)
            -> másik kliens lokális tárolója
```

## Készletmodell — domain-specifikus

### Hierarchia
```
Bank <-> Értéktár(ak) -> Pénztár(ak) <-> Ügyfelek
```

### NINCS központi készlet
- Minden pénztár és értéktár SAJÁT készlettel rendelkezik
- Készlet = SUM(bejövő) - SUM(kimenő) devizánként
- Két pénztár SOHA nem ír ugyanabba a készletbe

### Készletáramlás
| Szereplő | Növeli | Csökkenti |
|---|---|---|
| Pénztár | Vétel ügyféltől + átvétel értéktártól | Eladás ügyfélnek + átadás értéktárnak |
| Értéktár | Bank-beszerzés + visszavétel pénztártól | Bank-eladás + kiadás pénztárnak |

### Transzferek: párosított esemény minta
- Mindkét fél saját eseményt rögzít lokálisan
- A szerver párosítja (transfer_out <-> transfer_in)

## Kötelező elemek minden local-first feature-höz

1. Lokális perzisztens tároló (SQLite, Electron Main process)
2. Outbox tábla (mutationId, entity, payload, status, retryCount, createdAt)
3. Explicit konfliktuspolitika entitásonként
4. Invariánslista
5. Idempotens sync (push + pull)
6. Tombstone-alapú törlés (_deleted + deleted_at + retention 30 nap)
7. Sémaverzió + migrációs terv
8. Offline/reconnect/concurrent edit tesztek

## Konfliktuspolitika entitás-típusonként

| Entitás | Politika | Indoklás |
|---|---|---|
| Tranzakciók (vétel/eladás) | Append-only, szerverhatóság | Pénzügyi, nem felülírható |
| Készlet | Számított, nincs conflict | SUM tranzakciókból |
| Transzferek | Párosított esemény, szerver validál | Két fél, szerver rendel össze |
| Árfolyam draft | Mezőszintű merge | Szerkeszthető, nem kritikus |
| Publikált árfolyam | Szerverhatóság | Egyszer publikált, immutable |
| Beállítások | LWW elfogadható | Nem vész el kritikus adat |
| Napzárás | Optimista lokális + szerver véglegesít | Audit trail kötelező |

## Tiltott minták

- Local-firstnek nevezni, ha valójában csak cache
- Vakon LWW pénzügyi adatoknál
- Tombstone nélkül törölni replikált entitást
- API secret kliensnek adni
- Renderer közvetlen DB/fájlrendszer hozzáférés
- Központi készletet feltételezni
- Kliensórára építeni globális sorrendet
- Késznek jelölni offline teszt nélkül

## Electron biztonsági szabályok

- Renderer: sandboxolt, contextIsolation=true
- Main process: validált IPC csatornákon keresztül végez DB/fájl/OS műveleteket
- IPC channel-ek nevesítve, whitelist-elve
- Logout/user váltás: teljes lokális adat törlés

## Sync állapot UI modell

```
saved_local   = lokálisan tartósítva
pending_sync  = outboxban vár
syncing       = hálózati küldés folyamatban
synced        = szerver visszaigazolt
conflicted    = alkalmazásszintű döntés kell
sync_failed   = újrapróbálható hiba
blocked       = jogosultsági/séma/invariáns hiba
```

## Tesztelési mátrix (12 kötelező teszt)

1. Offline CRUD
2. Reconnect sync
3. Concurrent edit (azonos mező)
4. Concurrent edit (különböző mezők)
5. Duplikált sync payload (idempotencia)
6. Out-of-order delivery
7. Tombstone propagáció
8. Nagy lokális dataset
9. Multi-instance
10. Jogosulatlan adat replikáció tiltása
11. App restart utáni állapotmegőrzés
12. Konfliktusfeloldás utáni invariáns-ellenőrzés
