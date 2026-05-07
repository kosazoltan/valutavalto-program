---
date: 2026-04-29
session_type: track-4-spring-boot-4-sprint
duration: ~30 min (06:30 - 07:00 CEST)
context: User direktíva "most csináld meg!!!!!!" (Track 4 + #205 + #196 unified)
---

# 2026-04-29 Track 4 — Spring Boot 4 sprint (PR #263)

## User direktíva
> "Defer (külön sprint) Track 4 — Spring Boot 4 #205: 1-2 napos sprint, magas kockázat (04-27 outage tanulság). Master plan: docs/superpowers/plans/2026-04-28-multi-track-execution.md. #196 springdoc 3: blokkolt SB4-ig (1 nyitott PR a repón). most csináld meg!!!!!!"

A korábbi defer-ajánlás (1-2 napos sprint külön session-be) felülírva. A SB4 + springdoc 3 **egyetlen sprintben** unified.

## A 04-27-i outage gyökér-oka (megszüntetve)

```
Failed to bind properties under spring.jackson.serialization to
java.util.Map<tools.jackson.databind.SerializationFeature, Boolean>:
Reason: failed to convert String to SerializationFeature
(No enum constant write-dates-as-timestamps)
```

A `spring.jackson.use-jackson2-defaults=true` stop-gap **NEM** oldja meg a property bindelést — a Spring Boot 4 default-ban a Jackson 3 enum-okra próbál bind-elni a `spring.jackson.serialization.*` properties-ből. Ezért a 04-27-i első próba (#205) production 502-vel végződött, hotfix #247 revertelte.

## Megoldás (3 réteg)

### 1. `application.properties` cleanup
A 3 problematic property **KIVÉVE**:
- ❌ `spring.jackson.serialization.write-dates-as-timestamps=false`
- ❌ `spring.jackson.time-zone=UTC`
- ❌ `spring.jackson.default-property-inclusion=non_null`

Marad:
- ✅ `spring.jackson.use-jackson2-defaults=true` (stop-gap aktivál)

### 2. Új `JacksonConfig.java` `@Primary @Bean ObjectMapper`
Programmatic Jackson 2 ObjectMapper config — a Spring Boot 4 NEM tud property-bind-en bukni, mert nincs property:
- `WRITE_DATES_AS_TIMESTAMPS=false` (ISO-8601)
- `setTimeZone(UTC)`
- `setSerializationInclusion(NON_NULL)`
- `JavaTimeModule` registered
- `FAIL_ON_UNKNOWN_PROPERTIES=false`

### 3. springdoc 2.8.17 → 3.0.3 (#196 cherry-pick)
A springdoc 2.x SB4-tel **inkompat** (`NoClassDefFoundError: org.springframework.boot.autoconfigure.web.servlet.WebMvcProperties` — ez a class SB4-ben átkerült/eltűnt). A springdoc 3.0.3 SB4-kompat. Ez a `#196` Dependabot PR-ből cherry-picked.

## Cherry-picked commits

```
73112a14 wip(spring-boot-4): part1 - EntityScan + FlywayMigrationStrategy + flyway-starter + messaging cast
fc02d176 fix(spring-boot-4): part2 - Jackson 2 stop-gap modul + SyncInboundEventRequest payload Object
cc2fad47 chore(deps): bump org.springdoc:springdoc-openapi-starter-webmvc-ui (2.8.17 → 3.0.3)
```

## Plus a `JacksonConfig.java` új commit + `application.properties` property-cleanup

## Verifikáció

| Lépés | Eredmény |
|---|---|
| `mvn clean compile` | ✅ BUILD SUCCESS 12.6s, 1147 fájl, 0 error |
| `mvn test` | ✅ **1009/1009 PASS** |
| `mvn package -DskipTests` | ✅ `valuta-backend-2.3.6.jar` 121MB |
| `java -jar` smoke (lokális) | ✅ Spring context init OK, Tomcat embedded indított, **Jackson bind hiba NEM** jött elő, springdoc init OK. Csak lokális DB credentials hibás (`valuta_user` password, nem SB4 issue). |

## Tanulságok

1. **A 04-27-i `#205` outage gyökér-oka**: a `spring.jackson.use-jackson2-defaults=true` **NEM** elégséges. A property-bindelés Jackson 3 enum-okra megy default-ban, és a stop-gap modul csak a runtime ObjectMapper-t aktiválja, **NEM** a property-binding-et.
2. **Megoldás**: a problematic properties-t **KIVENNI** és programmatic `JacksonConfig` bean-en állítani be. Ezzel a Spring Boot 4 NEM próbál bind-elni.
3. **springdoc 2.x vs SB4**: inkompat (`WebMvcProperties` class át/eltűnt). A `#196` springdoc 3.0.3 **kötelező** SB4-hez.
4. **Lokális production-profile smoke teszt nehéz**: DB credentials env-ek kellenek. A Hetzner deploy a végső validáció.

## Záró-állapot (2026-04-29 07:00 CEST)

### Mergelt PR-ek

| PR | Tartalom | SHA | Production hatás |
|---|---|---|---|
| ✅ [#263](https://github.com/kosazoltan/valutavalto-program/pull/263) | SB 3.5.13 → 4.0.6 sprint + Jackson 2 stop-gap + JacksonConfig + flyway 12.4 + springdoc 3 | `2c03e223` | **HTTP 200 stable 6 min** ✅ |
| ✅ [#264](https://github.com/kosazoltan/valutavalto-program/pull/264) | Codex P1 follow-up: Tomcat 10.1.54 override removed (→ SB 4.0.6 BOM default 11.0.21, Servlet 6.1) | `92bbd1a0` | Hetzner deploy monitor 🟡 (folyamatban) |

### Hetzner deploy results

#### #263 SB4 sprint deploy (06:54 CEST)
- T+30s: HTTP 200 (régi SB 3.5.13 még)
- T+120s: HTTP 502 (backend restart deploy alatt, **átmeneti** — 1 ciklus)
- T+150s: HTTP 200 (új SB 4.0.6 backend feláll)
- **T+360s: HTTP 200 stable 6 min — SB4 deploy SUCCESS** ✅

#### #264 Tomcat 11 deploy (07:00 CEST)
- Folyamatban, monitor `bp058hcqy` figyel.

### A 04-27-i outage gyökér-oka MEGSZÜNTETVE

A Spring Boot 4.0.6 + Jackson 2 stop-gap + programmatic `JacksonConfig` bean **stabil** a Hetzner production-on. A `spring.jackson.serialization.*` properties kivételével a Jackson 3 enum bind hiba **lehetetlen**.

### Post-merge AI review #263

| Bot | Finding | Súly | Fix |
|---|---|---|---|
| Codex | Tomcat 10 override SB4-tel inkompat (Servlet 6.0 vs 6.1) | **P1** | PR #264 (Tomcat override eltávolítva, BOM default 11.0.21) |
| Sourcery | `JacksonConfig` `Jackson2ObjectMapperBuilder`-rel építse az ObjectMapper-t | P2/style | Ezt a következő sessionre (NEM kritikus, programmatic config sztochasztikusan ekvivalens) |

## Tanulságok (production-szinten verifikált)

1. **A `spring.jackson.use-jackson2-defaults=true` NEM elégséges** — a property-bindelés Jackson 3 enum-okra megy default-ban, és a stop-gap modul csak a runtime ObjectMapper-t aktiválja, NEM a property-binding-et.
2. **Programmatic `JacksonConfig` bean** a tiszta megoldás — a problematic properties-t kivenni + `@Primary @Bean ObjectMapper` programmatic config.
3. **springdoc 2.x SB4-tel inkompat** — `WebMvcProperties` class átkerült/eltűnt. springdoc 3.0.3 kötelező.
4. **Tomcat verzió override-ot frissíteni kell** SB major upgrade-nél — a 10.1 (Servlet 6.0) NEM kompat a SB 4 (Servlet 6.1)-tel. SB4 BOM default Tomcat 11.0.21 (Servlet 6.1) → eltávolítani az override-ot.
5. **Hetzner deploy alatti 502 ÁTMENETI** — backend-restart deploy közben 1-2 ciklus 502 normális. A Monitor 3-consecutive-5xx küszöböt használ a revert-hez.
6. **1009/1009 mvn test PASS lokálisan ≠ Hetzner deploy success automatikus** — a 04-27 tanulság megerősítve. A production-szerű Tomcat config + DATABASE_URL csak a deploy-on vizsgálható.
