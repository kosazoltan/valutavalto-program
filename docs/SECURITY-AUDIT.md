# Security Audit — Valutaváltó Program v2.0

> Dátum: 2026-03-06  
> Auditor: Tamás (Főfejlesztő)  
> Eredmény: **0 kritikus** | 2 közepes | 3 alacsony

---

## 1. Autentikáció & Autorizáció

### JWT Authentication ✅
- **SecurityConfig.java** — Spring Security + JWT filter implementálva
- Stateless session management (`SessionCreationPolicy.STATELESS`)
- `JwtAuthenticationFilter` a `UsernamePasswordAuthenticationFilter` előtt
- `@EnableMethodSecurity` engedélyezve a method-level security-hez

### Endpoint védelmi mátrix ✅
| Endpoint pattern | Védelem | Státusz |
|---|---|---|
| `/api/v1/auth/login`, `/api/v1/auth/refresh` | `permitAll()` | ✅ Helyes |
| `/actuator/**` | `permitAll()` | ✅ Health check |
| `/api/v1/health/**` | `permitAll()` | ✅ Health check |
| `/swagger-ui/**`, `/api-docs/**` | `permitAll()` | ✅ Docs |
| `/api/v1/branches/**` | `authenticated()` | ✅ |
| `/api/v1/workers/me` | `authenticated()` | ✅ |
| `/api/v1/workers/**` | `hasAnyRole(SUPERVISOR, MANAGER, ADMIN)` | ✅ |
| `/api/v1/companies/**` | `hasRole(ADMIN)` | ✅ |
| Minden más | `authenticated()` | ✅ |

### Jelszó kezelés ✅
- **BCryptPasswordEncoder** bean a SecurityConfig-ban
- ✅ Ipari szabvány, 10 rounds alapértelmezetten

---

## 2. SQL Injection Védelem

### JPQL @Query-k ✅
- **106 repository fájl** átvizsgálva
- Minden `@Query` annotáció JPQL-t használ `:param` paraméterekkel
- Nincsenek raw `String` concat SQL query-k
- Az összes `+` karakter a repository-kban JPQL string-ek többsoros összefűzése (nem user input concat!)

### Egyetlen kivétel (ALACSONY kockázat):
- `AuditLogController.java:152` — `String filename = "audit_export_" + LocalDateTime.now()...`
  - Ez fájlnév generálás, nem SQL — **NEM security issue**
- `CurrencyCalculatorService.java:221,238` — `"Cross-rate: " + fromCurrency + ...`
  - Ez log/info üzenet, nem query — **NEM security issue**

**Eredmény:** ✅ SQL injection védett — Spring Data JPA paraméteres query-k mindenhol

---

## 3. XSS Védelem

### Frontend (React 19 + TypeScript) ✅
- **1 darab `dangerouslySetInnerHTML` használat:**
  - `PrintTemplatePage.tsx:319` — nyomtatási sablon előnézet
  - **Kontextus:** A `previewHtml` a sablon editor-ból jön, NEM user input-ból
  - **Kockázat:** KÖZEPES — adminisztrátori felület, de sanitizálás ajánlott

### Ajánlás:
```typescript
// DOMPurify használata a previewHtml-re
import DOMPurify from 'dompurify';
dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(previewHtml) }}
```

---

## 4. CORS Konfiguráció

### Jelenlegi beállítás ✅
```java
@Value("${cors.allowed-origins:http://localhost:3000,http://localhost:5173}")
private String corsAllowedOrigins;
```

- ✅ Origins konfigurálható környezeti változóból
- ✅ `allowCredentials(true)` — JWT cookie-khoz szükséges
- ✅ Specifikus HTTP metódusok: GET, POST, PUT, DELETE, PATCH, OPTIONS

### Ajánlás (KÖZEPES):
- ⚠️ `setAllowedHeaders(Arrays.asList("*"))` — túl megengedő
- Ajánlott: explicit header lista (`Authorization`, `Content-Type`, `Accept`, `X-Requested-With`)
- ⚠️ Produkcióban a `cors.allowed-origins` értékét a konkrét domain-ekre kell szűkíteni

---

## 5. CSRF Védelem

- CSRF kikapcsolva: `.csrf(csrf -> csrf.disable())`
- ✅ Ez helyes JWT-alapú stateless alkalmazásnál
- A CSRF token-ek cookie-alapú session-ökhöz kellenek, amit nem használunk

---

## 6. Session Kezelés

- ✅ `SessionCreationPolicy.STATELESS` — nincs szerver-oldali session
- ✅ JWT token a kliensben tárolódik, minden kéréshez mellékeli

---

## 7. Egyéb Security Szempontok

### Swagger UI produkciós kockázat (ALACSONY)
- Swagger UI elérhető `permitAll()` módban
- **Ajánlás:** Produkcióban profilfüggő kikapcsolás:
  ```properties
  # application-production.properties
  springdoc.api-docs.enabled=false
  springdoc.swagger-ui.enabled=false
  ```

### Actuator endpointok (ALACSONY)
- `/actuator/**` publikus
- **Ajánlás:** Produkcióban csak `/actuator/health` legyen publikus
  ```java
  .requestMatchers("/actuator/health").permitAll()
  .requestMatchers("/actuator/**").hasRole("ADMIN")
  ```

### Flyway produkciós konfiguráció (ALACSONY)
- `application-production.properties`: `spring.flyway.enabled=false` + `ddl-auto=update`
- **Ajánlás:** Produkcióban `ddl-auto=validate` és Flyway engedélyezve

---

## Összesítő Táblázat

| # | Kategória | Szint | Leírás | Státusz |
|---|-----------|-------|--------|---------|
| 1 | XSS | KÖZEPES | `dangerouslySetInnerHTML` sanitizálás nélkül | ⚠️ Ajánlás adva |
| 2 | CORS | KÖZEPES | `allowedHeaders("*")` túl megengedő | ⚠️ Ajánlás adva |
| 3 | Swagger | ALACSONY | Swagger UI nyilvános produkcióban | ℹ️ Profil-függő |
| 4 | Actuator | ALACSONY | Actuator endpointok nyilvánosak | ℹ️ Profil-függő |
| 5 | Flyway | ALACSONY | Produkcióban `ddl-auto=update` | ℹ️ Ajánlás adva |

### Kritikus találatok: **0** ✅
### SQL Injection: **Védett** ✅
### Jelszó hash: **BCrypt** ✅
### JWT Auth: **Implementálva** ✅
### @PreAuthorize / SecurityConfig: **Konfigurálva** ✅
