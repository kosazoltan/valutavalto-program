# Zálog + Ékszer ERP — Bootstrap Guide

> **Készült:** 2026-05-05  
> **Forrás:** Valutavaltó Pénztár (https://github.com/kosazoltan/valutavalto-program) 2026-04 — 2026-05 tapasztalatok  
> **Cél:** új ERP projekt (zálog + ékszer kereskedelem) gyorsabb felépítése a már bizonyított architektúrával, az itt iterációkon át javított hibák nélkül

---

## 0. Bevezetés

### 0.1 Mi ez a dokumentum

Ez egy **technikai bootstrap guide** egy új ERP-projekt elindításához, amely a Valutavaltó Pénztár (Penztar.exe v2.5.19) kódbázisának architektúrális mintázatait, technológia-stackjét és **bizonyítottan működő** konfigurációit foglalja össze. A célja, hogy egy új projekt fejlesztője (vagy AI-asszisztens) **azonnal** építeni tudjon egy hasonló rendszert, anélkül hogy belebotlana azokba a buktatókba, amelyeket itt már mind végigjártunk.

### 0.2 Project mapping (régi → új)

| Jelenlegi (Valutavaltó) | Új projekt | Funkció |
|---|---|---|
| **valuta pénztár** (Penztar.exe Electron) | **zálog tevékenység** | tárgy zálogba vétele, kifizetés, kamatozás |
| **értéktár** (Ertektar mode, ugyanaz a kódbázis) | **ékszer kereskedelem** | ékszer adás-vétel, készletkezelés |

**FONTOS:** a jelenlegi rendszerben a `valuta pénztár` és az `értéktár` ugyanazon a kódbázison osztozik (Electron app-mode flag-en keresztül). Az **új projektben ez NEM lesz így** — a két tevékenység **teljesen független**, **külön repo**, **külön domain**, **külön deploy**, **külön DB**. Nincs shared login, nincs cross-feature függőség.

### 0.3 Mit ad a guide

- ✅ **Pontos verziószámok** minden technológiához (ezek bizonyítottan együttműködnek)
- ✅ **Copy-paste pattern**ek a legfontosabb fájlokhoz
- ✅ **Anti-pattern lista** — 15+ konkrét hiba, amit NE kövess el
- ✅ Backend → Frontend → Electron → Installer → Deploy teljes pipeline
- ✅ Auto error-reporting (Sentry-style, saját szerveren)
- ✅ Google OAuth dual setup (Web + Desktop RFC 8252)

### 0.4 Mit NEM ad

- ❌ Üzleti logika (zálogkezelés, ékszer-katalógus stb.) — ezt a saját repo-ban dolgozzuk ki
- ❌ Tipikus React tutorial (feltételezem alap szintű React/TS/Java tudást)
- ❌ DevOps mélyrétegei (csak a működő minimális Hetzner+Caddy+CF beállítás)

### 0.5 Hogyan használd

1. **Először olvasd el a 10. szekciót** (Pitfalls) — mert ezeket TILOS megismételni
2. Aztán a 1. (Architecture) + 2. (Tech stack) — keret
3. Tier-enként haladj (3. Backend → 4. Frontend → 5. Electron → 6. OAuth → 7. ErrReport → 8. Deploy → 9. Installer)
4. A kódpéldákat **ne másold vakon** — értsd is meg, miért úgy van

---

## 1. Architecture Overview

### 1.1 Két független ERP

```
                                 ┌─────────────────────────────────┐
                                 │      Cloudflare DNS + WAF       │
                                 │   (IPv6 OFF, Proxy ON, Full TLS)│
                                 └──────────┬──────────────────────┘
                                            │
                ┌───────────────────────────┼─────────────────────────┐
                │                                                     │
        zalog.example.com                                  ekszer.example.com
                │                                                     │
                ▼                                                     ▼
        ┌──────────────────────┐                          ┌──────────────────────┐
        │ Hetzner VPS (Ubuntu) │                          │ Hetzner VPS (Ubuntu) │
        │  Caddy reverse proxy │                          │  Caddy reverse proxy │
        │  ↓                   │                          │  ↓                   │
        │  Spring Boot 4.0.6   │                          │  Spring Boot 4.0.6   │
        │  + Tomcat 11.0.21    │                          │  + Tomcat 11.0.21    │
        │  ↓                   │                          │  ↓                   │
        │  PostgreSQL 17       │                          │  PostgreSQL 17       │
        │  + Flyway 12.4       │                          │  + Flyway 12.4       │
        └──────────────────────┘                          └──────────────────────┘
                ▲                                                     ▲
                │ HTTPS                                               │ HTTPS
                │                                                     │
       ┌────────┴──────────┐                                ┌─────────┴──────────┐
       │ Zálog Admin (Web) │                                │ Ékszer Admin (Web) │
       │ React 19 + Vite   │                                │ React 19 + Vite    │
       └───────────────────┘                                └────────────────────┘
                ▲                                                     ▲
                │                                                     │
       ┌────────┴──────────┐                                ┌─────────┴──────────┐
       │ Zalog.exe (Win)   │                                │ Ekszer.exe (Win)   │
       │ Electron 33       │                                │ Electron 33        │
       │ + SQLite offline  │                                │ + SQLite offline   │
       └───────────────────┘                                └────────────────────┘

       Két különálló repo: zalog-program/ és ekszer-program/
```

### 1.2 4-tier architektúra (per ERP)

| Tier | Tech | Szerep |
|---|---|---|
| **DB** | PostgreSQL 17.5 | server-side persistence |
| **Backend** | Spring Boot 4.0.6 + Tomcat 11 | REST API + business logic |
| **Admin Web** | React 19 + Vite + Tailwind | adminisztrátor UI (browser) |
| **Desktop Client** | Electron 33 + React + SQLite | dolgozói UI (Windows-on telepített, offline-capable) |

### 1.3 Adatfolyam

```
[Felhasználó]
   │
   ├──► Browser (excvaluta.com / zalog.example.com / ekszer.example.com admin felület)
   │      │
   │      ▼
   │    Cloudflare → Hetzner Caddy → Spring Boot REST API → PostgreSQL
   │
   ├──► Desktop kliens (Penztar.exe / Zalog.exe / Ekszer.exe)
   │      │
   │      ├──► Bundled React UI (renderer)
   │      │      ↓ axios (timeout 30s, withCredentials)
   │      │      ↓
   │      └──► Electron main process (IPC bridge)
   │             ↓ electron.net.request (TLS, IPv4 forced via host-resolver-rules)
   │             ↓
   │           Cloudflare → Hetzner → Backend → DB
   │
   └──► Hibajelentés (auto, send-and-forget)
          │
          ▼
        POST /api/v1/diagnostics/error-report → client_error_log table → GitHub Issue auto-create
```

### 1.4 Külső függőségek

| Szolgáltatás | Szerep | Token tárolás |
|---|---|---|
| **Cloudflare** | DNS, CDN, WAF, IPv6 OFF | `CF_API_TOKEN` env (gitignored) |
| **Hetzner** | VPS hosting, SSH | `HETZNER_SSH_PRIVATE_KEY` GitHub Actions secret |
| **GitHub** | repo, issues, releases, Actions, Dependabot | `GITHUB_PAT` (fine-grained, repo+issues+pulls) |
| **Google Cloud Console** | OAuth client (Web + Desktop) | `GOOGLE_DESKTOP_CLIENT_ID` env |
| **Anthropic** | Claude API (auto-triage routine) | `ANTHROPIC_API_KEY` env |

### 1.5 Multi-tenant model (per ERP)

Egy ERP backend több ügyfelet (`company`) szolgál ki. **Minden lekérdezés `companyId`-ra szűr**. Soha ne felejtsd el a company-scope-ot — különben adatszivárgás.

```sql
-- Minden tábla tartalmazza a company_id-t
CREATE TABLE pawn_item (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES company(id),
  ...
);

-- Minden repo metódus szűr companyId-ra
public interface PawnItemRepository extends JpaRepository<PawnItem, Long> {
    List<PawnItem> findAllByCompanyIdAndStatus(Long companyId, PawnStatus status);
}
```

---

## 2. Tech Stack — pontos verziókkal

> **Ezek a verziók BIZONYÍTOTT együttműködésben állnak** a Valutavaltó Pénztár v2.5.19-ben. Ne tér el tőlük indok nélkül — minden eltérés további iterációt igényelhet.

### 2.1 Backend

| Komponens | Verzió | Megjegyzés |
|---|---|---|
| Java | **21 LTS** | Eclipse Temurin, NEM korábbi |
| Spring Boot | **4.0.6** | NEM 3.5.x — Jackson 3 a default |
| Tomcat | **11.0.21** (BOM default) | NE override-old `<tomcat.version>10.x</tomcat.version>`-szel — Servlet 6.1 stack-et ront |
| Spring Security | 6.5.10 | (CVE-fix) |
| Jackson 2 stop-gap | `spring-boot-jackson2` BOM | a meglévő `com.fasterxml.jackson.*` import-ok kompatibilitásához |
| PostgreSQL JDBC | (BOM default) | runtime scope |
| Flyway | 12.4.0 (`flyway-database-postgresql`) | + `spring-boot-starter-flyway` (SB4 koteleziti!) |
| Lombok | (BOM default) | optional scope |
| jjwt | 0.13.0 | api + impl + jackson |
| springdoc-openapi | 3.0.3 | NEM frissebb (Jackson 3-at húz be) |
| Webcam capture | 0.3.12 | sarxos |

### 2.2 Frontend admin

| Komponens | Verzió | Megjegyzés |
|---|---|---|
| Node.js | **20.19+** vagy **22 LTS** | engine-strict, az eslint 10 köteleziti |
| React | **19.2.5** | NEM 18 (peer-dep skew) |
| TypeScript | 5.7+ | strict mode |
| Vite | 5.x vagy 6.x | bundler |
| Tailwind CSS | 3.x | NEM 4 (még nem stabil prod-ban) |
| Zustand | 4.x | state management |
| axios | 1.16+ (CVE-fixed) | `npm audit fix` után |
| react-router-dom | 6.x vagy 7.x | |
| date-fns | latest | |
| react-hook-form | 7.x | |

### 2.3 Electron desktop

| Komponens | Verzió | Megjegyzés |
|---|---|---|
| Electron | **33.x** | egységes a frontend-réteggel |
| electron-builder | 25.x | csomagolás |
| electron-updater | 6.x | auto-update GitHub Release-ből |
| electron-log | 5.x | renderer + main log |
| better-sqlite3 vagy sql.js | latest | offline DB |
| node version (Electron-bundled) | 22.x | |

### 2.4 Build / packaging

| Komponens | Verzió | Megjegyzés |
|---|---|---|
| Maven Wrapper | 3.9.9 | `mvnw` checked-in |
| NSIS | 3.10+ | installer compiler |
| PowerShell | 7.x (Win 11) | build scriptek |

### 2.5 Infra

| Komponens | Verzió | Megjegyzés |
|---|---|---|
| Ubuntu | 22.04 LTS | Hetzner VPS |
| Caddy | 2.7+ | reverse proxy + Let's Encrypt |
| systemd | (built-in) | service unit |
| PostgreSQL (server) | **17.5** | NEM 16 vagy alacsonyabb (V172+ migrációk PostgreSQL 17-re számítanak) |

---

## 3. Backend Setup — Spring Boot 4 + Tomcat 11

### 3.1 Project structure

```
backend/
├── pom.xml
├── mvnw / mvnw.cmd
├── src/
│   ├── main/
│   │   ├── java/com/yourcompany/yourapp/
│   │   │   ├── YourAppApplication.java         # @SpringBootApplication
│   │   │   ├── config/
│   │   │   │   ├── SecurityConfig.java          # JWT + permitAll matchers
│   │   │   │   ├── JacksonConfig.java           # Jackson 2 stop-gap programmatic ObjectMapper
│   │   │   │   ├── CorsConfig.java
│   │   │   │   └── WebSocketConfig.java
│   │   │   ├── controller/                      # REST endpoints
│   │   │   ├── dto/                             # request/response
│   │   │   ├── entity/                          # @Entity JPA
│   │   │   ├── repository/                      # Spring Data JPA
│   │   │   ├── service/                         # business logic
│   │   │   ├── security/                        # JwtAuthenticationFilter, IdempotencyFilter
│   │   │   ├── mapper/                          # MapStruct
│   │   │   └── util/
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── application-production.properties
│   │       └── db/migration/
│   │           ├── V1__init.sql
│   │           ├── V2__add_company.sql
│   │           └── ...
│   └── test/
│       └── java/...
└── target/ (build output, gitignored)
```

### 3.2 pom.xml minta — Spring Boot 4 + Jackson 2 stop-gap

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>4.0.6</version>
        <relativePath/>
    </parent>
    <groupId>com.yourcompany</groupId>
    <artifactId>yourapp-backend</artifactId>
    <version>1.0.0</version>
    <properties>
        <java.version>21</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.release>${java.version}</maven.compiler.release>
        <!-- CVE-fix overrides; check current advisories -->
        <spring-security.version>6.5.10</spring-security.version>
        <log4j2.version>2.25.4</log4j2.version>
        <!-- NE használj <tomcat.version>10.x</tomcat.version> override-ot!
             SB4 a Servlet 6.1 stack-et célozza → Tomcat 11.x default. -->
    </properties>

    <dependencies>
        <!-- Web + Security + JPA + Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <!-- ⚠️ KRITIKUS: Jackson 2 stop-gap modul.
             SB4 default Jackson 3 (`tools.jackson.*`), de a meglévő `com.fasterxml.jackson.*`
             import-jaink kompatibilitásához ez KELL. Lásd a 10.2 szekciót. -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-jackson2</artifactId>
        </dependency>

        <!-- Flyway: SB4 KÖTELEZIT a starter-flyway-t (a flyway-core önmagában
             nem auto-konfigurálódik). -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-flyway</artifactId>
        </dependency>
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-database-postgresql</artifactId>
            <version>12.4.0</version>
        </dependency>

        <!-- PostgreSQL JDBC -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <!-- JWT (jjwt) -->
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.13.0</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.13.0</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.13.0</version>
            <scope>runtime</scope>
        </dependency>

        <!-- OpenAPI / Swagger -->
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>3.0.3</version>
        </dependency>

        <!-- Tests -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <configuration>
                    <argLine>${argLine}</argLine>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### 3.3 application.properties

```properties
# DB
spring.datasource.url=jdbc:postgresql://localhost:5432/yourapp
spring.datasource.username=yourapp
spring.datasource.password=${DB_PASSWORD}
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA + Hibernate
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.format_sql=false
spring.jpa.open-in-view=false

# Flyway
spring.flyway.enabled=true
spring.flyway.baseline-on-migrate=false
spring.flyway.locations=classpath:db/migration

# Jackson 2 stop-gap — defaults to Jackson 2 modul amíg meg nem migráljuk Jackson 3-ra
spring.jackson.use-jackson2-defaults=true

# Server
server.port=8080
server.servlet.context-path=/
server.compression.enabled=true
server.compression.mime-types=application/json,text/html,text/css,application/javascript

# Logging
logging.level.root=INFO
logging.level.com.yourcompany=INFO
logging.level.org.hibernate.SQL=WARN

# JWT
yourapp.jwt.secret=${JWT_SECRET}
yourapp.jwt.access-token-validity-ms=900000     # 15 perc
yourapp.jwt.refresh-token-validity-ms=604800000 # 7 nap

# Google OAuth
google.web.client.id=${GOOGLE_WEB_CLIENT_ID}
google.desktop.client.id=${GOOGLE_DESKTOP_CLIENT_ID}

# GitHub Issue auto-create (per 7. szekció)
github.issue.auto-create.enabled=${GITHUB_ISSUE_AUTO_CREATE_ENABLED:false}
github.issue.auto-create.token=${GITHUB_ISSUE_AUTO_CREATE_TOKEN:}
github.issue.auto-create.repo=${GITHUB_ISSUE_AUTO_CREATE_REPO:youruser/yourrepo}

# Multi-tenant default
yourapp.default-company-id=1
```

### 3.4 SecurityConfig — `requestMatchers` PERMIT a kulcs

```java
package com.yourcompany.yourapp.config;

import com.yourcompany.yourapp.security.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtFilter) {
        this.jwtFilter = jwtFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // ⚠️ KRITIKUS: a permitAll matcher-ek IDE jönnek, NEM csak @PreAuthorize-ban!
                // A SecurityFilterChain HTTP filter chain BLOKKOL ELŐTTE a controller method-okat,
                // ezért a @PreAuthorize("permitAll()") ÖNMAGÁBAN NEM ELÉG. Lásd 10.3.
                .requestMatchers(
                    "/api/v1/auth/login",
                    "/api/v1/auth/refresh-cookie",
                    "/api/v1/auth/google-login",
                    "/api/v1/auth/bootstrap-status",
                    "/api/v1/diagnostics/error-report",  // auto-error-reporting (7. szekció)
                    "/api/v1/diagnostics/health",
                    "/api/v1/public/**",                  // pl. branches list
                    "/actuator/health",
                    "/actuator/info",
                    "/swagger-ui/**",
                    "/v3/api-docs/**"
                ).permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

### 3.5 JacksonConfig — programmatic ObjectMapper (Jackson 2 stop-gap)

```java
package com.yourcompany.yourapp.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.module.paramnames.ParameterNamesModule;
import com.fasterxml.jackson.databind.SerializationFeature;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

/**
 * Spring Boot 4 + Jackson 2 stop-gap.
 *
 * <p>SB4 a Jackson 3-at (`tools.jackson.*`) használja default-ban. A meglévő
 * `com.fasterxml.jackson.*` import-jaink kompatibilitásához:
 *   1. pom.xml: `spring-boot-jackson2` modul
 *   2. application.properties: `spring.jackson.use-jackson2-defaults=true`
 *   3. ITT: programmatic ObjectMapper builder (override a 3 problematic property)
 *
 * <p>Csak átmeneti — a teljes Jackson 3 migráció (39 fájl import-csere
 * OpenRewrite recipe-pal) egy külön sprintben jön. Akkor ez a config törölhető.
 */
@Configuration
public class JacksonConfig {

    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        return Jackson2ObjectMapperBuilder.json()
            .modulesToInstall(new JavaTimeModule(), new ParameterNamesModule())
            .featuresToDisable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
            .build();
    }
}
```

### 3.6 IdempotencyFilter — POST request-eken Idempotency-Key kötelező, de néhány endpoint excluded

```java
package com.yourcompany.yourapp.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Idempotency-Key requirement on POST/PUT/PATCH/DELETE.
 *
 * <p>Néhány endpoint **stateless** és nem szabad megkövetelni rajtuk
 * az Idempotency-Key-t (pl. error-reporting, login). EZEKET EXCLUDE-OLD.
 * Lásd 10.4 szekció.
 */
@Component
public class IdempotencyFilter extends OncePerRequestFilter {

    /** Endpoint-prefixek, amikre NEM követelünk Idempotency-Key headert. */
    private static final List<String> EXCLUDED_PREFIXES = List.of(
        "/api/v1/auth/",                  // login, refresh, OAuth flow
        "/api/v1/diagnostics/",           // error-report, health
        "/api/v1/public/",                // public branches, currencies, stb.
        "/actuator/"
    );

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse resp,
                                    FilterChain chain) throws ServletException, IOException {
        String method = req.getMethod();
        String path = req.getRequestURI();

        boolean isMutating = method.equals("POST") || method.equals("PUT")
                          || method.equals("PATCH") || method.equals("DELETE");
        boolean isExcluded = EXCLUDED_PREFIXES.stream().anyMatch(path::startsWith);

        if (isMutating && !isExcluded) {
            String idempotencyKey = req.getHeader("Idempotency-Key");
            if (idempotencyKey == null || idempotencyKey.isBlank()) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                resp.setContentType("application/json");
                resp.getWriter().write("{\"error\":\"Missing Idempotency-Key header\"}");
                return;
            }
            // (opcionálisan: idempotency cache check, request-replay-detection stb.)
        }

        chain.doFilter(req, resp);
    }
}
```

### 3.7 Multi-tenant pattern (`companyId` scope-olás)

Minden Entity-ben `company_id` (FK), minden lekérdezésben szűr.

```java
@Entity
@Table(name = "pawn_item")
@Getter @Setter @NoArgsConstructor
public class PawnItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "client_name", nullable = false, length = 200)
    private String clientName;

    @Column(name = "estimated_value", nullable = false, precision = 18, scale = 2)
    private BigDecimal estimatedValue;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}

// Repository — MINDIG companyId-ra szűr
public interface PawnItemRepository extends JpaRepository<PawnItem, Long> {
    Optional<PawnItem> findByIdAndCompanyId(Long id, Long companyId);
    List<PawnItem> findAllByCompanyIdAndCreatedAtAfter(Long companyId, LocalDateTime since);
    long countByCompanyIdAndStatus(Long companyId, PawnStatus status);
}

// Controller — JWT-ből kiolvasott companyId
@RestController
@RequestMapping("/api/v1/pawn-items")
@RequiredArgsConstructor
public class PawnItemController {
    private final PawnItemService service;
    private final SecurityUtils securityUtils;

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CASHIER','ADMIN')")
    public ResponseEntity<PawnItemDto> get(@PathVariable Long id) {
        Long companyId = securityUtils.getCurrentCompanyId();
        return service.findByIdAndCompanyId(id, companyId)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
}
```

### 3.8 Flyway migration pattern

```
backend/src/main/resources/db/migration/
├── V1__init.sql                      # alap táblák, company, user, worker
├── V2__add_role_table.sql
├── V3__seed_default_branches.sql     # idempotent INSERT ... ON CONFLICT DO NOTHING
├── V4__add_pawn_item.sql
├── ...
```

Konvenciók:
- `V<N>__<rövid_leírás>.sql` (V majuscule, dupla underscore)
- **NE használj `R__` repeatable migration-t** ha üzleti adatot frissítesz (idempotencia bonyolult)
- **Idempotens** legyen amennyire lehet:
  ```sql
  CREATE TABLE IF NOT EXISTS pawn_item (...);
  ALTER TABLE pawn_item ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
  INSERT INTO branch (code, name) VALUES ('TISZA', 'Tisza Sarok')
    ON CONFLICT (code) DO NOTHING;
  ```
- **NE használd az INET típust** Hibernate-elt `String` mezővel — VARCHAR(45) IPv4+IPv6 mapped tárolásra (lásd 10.1)
- JSONB: igen, **`@JdbcTypeCode(SqlTypes.JSON)` annotációval** map-olódik

```java
// Példa entity JSONB context-tel
@JdbcTypeCode(SqlTypes.JSON)
@Column(name = "metadata", columnDefinition = "JSONB")
private String metadataJson;
```

### 3.9 Common gotchas

#### a) `@Transactional` overhead minden controller method-on
Ne használd. Csak a service-rétegben. Ha minden controller `@Transactional`, a HTTP read-only request is connection-t foglal a poolból.

#### b) `Open-in-view` blokkolja a connection pool-t
```properties
spring.jpa.open-in-view=false
```
Default-ban true, ami minden HTTP-kérésen tartja a Hibernate session-t. Ne.

#### c) `@JdbcTypeCode(SqlTypes.JSON)` és `Map<String, Object>`
Jackson 3 incompat miatt **NEM használj `JsonNode`-ot**. `Map<String, Object>` univerzálisan működik (lásd 10.2):
```java
@JdbcTypeCode(SqlTypes.JSON)
@Column(name = "context", columnDefinition = "JSONB")
private String contextJson;   // tárolás stringként, parse a service-ben
```

VAGY:
```java
private Map<String, Object> context;  // dual-stack-friendly
```

#### d) Hibernate INET ↔ String type mismatch
Postgres `INET` típus + Hibernate default String mapping → `PSQLException: column is of type inet but expression is of type character varying`. **Mindig VARCHAR(45)** IP cím tárolásra (IPv6 39 + IPv4-mapped 45).

```sql
-- ❌ ROSSZ: client_ip INET → Hibernate failel
ALTER TABLE client_error_log ADD COLUMN client_ip INET;

-- ✅ JÓ: VARCHAR(45)
ALTER TABLE client_error_log ADD COLUMN client_ip VARCHAR(45);
```

---

## 4. Frontend Admin (React 19 + Vite + TypeScript)

### 4.1 Project structure

```
frontend-admin/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
├── postcss.config.js
├── index.html
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── pages/
│   │   ├── auth/LoginPage.tsx
│   │   ├── setup/SetupWizard.tsx
│   │   ├── dashboard/DashboardPage.tsx
│   │   └── pawn/PawnItemListPage.tsx
│   ├── components/
│   │   ├── ui/                     # button, input, modal, toaster
│   │   └── layout/
│   ├── services/
│   │   ├── api/
│   │   │   ├── client.ts           # axios setup, timeout 30s, interceptors
│   │   │   ├── auth.ts
│   │   │   └── pawn.ts
│   │   └── google-oauth.ts         # browser Web SDK wrapper
│   ├── stores/
│   │   └── authStore.ts            # Zustand
│   ├── types/
│   │   └── api.ts
│   ├── utils/
│   │   ├── logger.ts
│   │   └── i18n.ts
│   └── i18n/
│       └── hu.json
└── public/
    └── (static assets)
```

### 4.2 axios kliens — TIMEOUT: 30000ms (NEM 15000!)

> Lásd **10.7** anti-pattern: a 15s timeout kevés ESET MITM klienseken (TLS handshake + HTTP/1.1 új conn + Google API + JWT issuance > 15s).

```typescript
// src/services/api/client.ts
import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://yourapi.example.com/api/v1'

// ⚠️ KRITIKUS: 30s timeout, NEM 15s.
// ESET MITM proxy + HTTP/1.1 új TLS conn + Google API roundtrip + JWT issuance
// összesen >15s lehet. Lásd Borsi #417 fix Valutavalto-ban.
const AXIOS_GLOBAL_TIMEOUT_MS = 30_000

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: AXIOS_GLOBAL_TIMEOUT_MS,
  withCredentials: true,  // HttpOnly refresh-cookie
  headers: { 'Content-Type': 'application/json' },
})

// Request interceptor: JWT bearer token
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = useAuthStore.getState().accessToken
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error),
)

// Response interceptor: error reporting + 401 silent refresh
const REFRESH_SKIP_PATHS = ['/auth/login', '/auth/refresh-cookie', '/auth/google-login']

api.interceptors.response.use(
  (resp) => resp,
  async (error: AxiosError) => {
    const config = error.config as InternalAxiosRequestConfig | undefined
    const status = error.response?.status

    // 401 → silent refresh (kivéve auth-endpointokon)
    const url = config?.url ?? ''
    const isAuthAttempt = REFRESH_SKIP_PATHS.some(p => url.includes(p))
    if (status === 401 && !isAuthAttempt && config && !config._retry) {
      config._retry = true
      try {
        const refreshResp = await api.post('/auth/refresh-cookie')
        useAuthStore.getState().setAccessToken(refreshResp.data.accessToken)
        return api.request(config)
      } catch {
        useAuthStore.getState().logout()
      }
    }

    // Auto error report (4xx/5xx, kivéve auth)
    if (typeof window !== 'undefined' && window.electronAPI?.reportError) {
      try {
        if (status !== 401 || !isAuthAttempt) {
          void window.electronAPI.reportError({
            component: 'axios-http',
            message: `${error.message} [${status ?? 'NO_STATUS'}]`,
            context: {
              url,
              method: config?.method,
              responseData: typeof error.response?.data === 'string'
                ? error.response.data.slice(0, 500)
                : JSON.stringify(error.response?.data ?? '').slice(0, 500),
            },
          })
        }
      } catch { /* never throw on error-reporting */ }
    }

    return Promise.reject(error)
  },
)
```

### 4.3 Vite config

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/',
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
```

### 4.4 Zustand auth store

```typescript
// src/stores/authStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  accessToken: string | null
  user: { email: string; companyId: number; role: string } | null
  setAccessToken: (token: string) => void
  setUser: (user: AuthState['user']) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      user: null,
      setAccessToken: (accessToken) => set({ accessToken }),
      setUser: (user) => set({ user }),
      logout: () => set({ accessToken: null, user: null }),
    }),
    { name: 'auth-storage' },
  ),
)
```

### 4.5 LoginPage — Web SDK Google OAuth (browser)

```typescript
// src/pages/auth/LoginPage.tsx
import { useEffect, useRef } from 'react'
import { api } from '../../services/api/client'
import { useAuthStore } from '../../stores/authStore'

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: any) => void
          renderButton: (parent: HTMLElement, opts: any) => void
        }
      }
    }
    electronAPI?: {
      googleOAuthFlow: () => Promise<{ idToken: string }>
      reportError: (payload: any) => Promise<void>
    }
  }
}

export function LoginPage() {
  const buttonRef = useRef<HTMLDivElement>(null)
  const setAccessToken = useAuthStore((s) => s.setAccessToken)
  const setUser = useAuthStore((s) => s.setUser)

  const isElectron = typeof window !== 'undefined' && !!window.electronAPI

  useEffect(() => {
    if (isElectron) return  // Electron: külön gomb, RFC 8252 flow
    if (!window.google) return

    window.google.accounts.id.initialize({
      client_id: import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID,
      callback: handleGoogleResponse,
    })
    if (buttonRef.current) {
      window.google.accounts.id.renderButton(buttonRef.current, {
        theme: 'outline',
        size: 'large',
        text: 'signin_with',
      })
    }
  }, [isElectron])

  async function handleGoogleResponse(response: { credential: string }) {
    try {
      const resp = await api.post('/auth/google-login', { idToken: response.credential })
      setAccessToken(resp.data.accessToken)
      setUser(resp.data.user)
    } catch (err) {
      // hiba megjelenítése
    }
  }

  // Electron: a main process kezeli az OAuth flow-t (RFC 8252 loopback)
  async function electronGoogleLogin() {
    if (!window.electronAPI) return
    try {
      const { idToken } = await window.electronAPI.googleOAuthFlow()
      const resp = await api.post('/auth/google-login', { idToken })
      setAccessToken(resp.data.accessToken)
      setUser(resp.data.user)
    } catch (err) { /* ... */ }
  }

  return (
    <div className="login-page">
      <h1>Bejelentkezés</h1>
      {isElectron ? (
        <button onClick={electronGoogleLogin} className="btn-google">
          Belépés Google fiókkal
        </button>
      ) : (
        <div ref={buttonRef} />
      )}
    </div>
  )
}
```

---

## 5. Electron Desktop Client

### 5.1 Project structure

```
desktop-client/
├── package.json
├── tsconfig.json
├── electron-builder.json
├── electron/
│   ├── main.ts                # main process entry (Chromium switches, IPC, lifecycle)
│   ├── preload.ts             # contextBridge IPC bridge
│   ├── google-oauth.ts        # RFC 8252 + loopback redirect
│   ├── error-reporter.ts      # send-and-forget HTTP queue
│   ├── first-run.ts           # Setup Wizard logic (5-step)
│   ├── sync-engine.ts         # offline SQLite sync
│   └── auto-update.ts         # electron-updater wrapper
├── src/                       # ugyanaz mint admin-frontend, csak app://-protokollon
└── build/
    └── icon.ico
```

### 5.2 main.ts — Chromium switches + userData migration + IPC

```typescript
// electron/main.ts
import { app, BrowserWindow, ipcMain, protocol, net } from 'electron'
import path from 'node:path'
import fs from 'node:fs'
import log from 'electron-log/main'
import { initErrorReporter, reportError } from './error-reporter'
import { runGoogleOAuthFlow } from './google-oauth'
import { isFirstRun, runFirstTimeSetup } from './first-run'

// ⚠️ KRITIKUS: ezek a Chromium switch-ek a `app.whenReady()` ELŐTT KELLENEK.

// 1. Encrypted Client Hello (ECH) disable — ESET-tel kompatibilitás (10.10)
app.commandLine.appendSwitch('disable-features', 'EncryptedClientHello')

// 2. HTTP/2 disable — defensive, mert egyes ESET-konfigokon a HTTP/2 stream
//    FRAME-eket lassan dolgozza fel + minden connection 1 stream-mel megy.
//    NEM KELL feltétlenül, de ha nem akarsz iterálni: legyen.
app.commandLine.appendSwitch('disable-http2')

// 3. IPv4-only force a backend domain-re. Cloudflare AAAA OFF mellett már
//    nem kritikus, de defensive ha valaki visszakapcsolja.
//    ⚠️ Helyettesítsd a saját backend IP-vel + domain-nel.
app.commandLine.appendSwitch('host-resolver-rules',
  'MAP yourapi.example.com 188.114.96.10')

let mainWindow: BrowserWindow | null = null

async function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  })

  if (process.env.NODE_ENV === 'development') {
    await mainWindow.loadURL('http://localhost:3000')
  } else {
    await mainWindow.loadURL('app://localhost/index.html')
  }
}

app.whenReady().then(async () => {
  // Custom app:// protocol — a renderer ide tölti az index.html-t
  protocol.handle('app', (req) => {
    const url = new URL(req.url)
    const filePath = path.join(__dirname, '..', 'dist', url.pathname.replace(/^\/+/, ''))
    return net.fetch(`file://${filePath}`)
  })
  log.info('[App] Custom "app" protocol regisztrálva')

  // ⚠️ KRITIKUS: userData .env migration STARTUP-on (10.5).
  //    A régi telepítéssel (vagy buggy Setup Wizard-dal) a userData-ban lehet
  //    `VITE_API_URL="https://"` (üres host). Ezt detektálni + auto-felülírni.
  try {
    const userDataEnvPath = path.join(app.getPath('userData'), '.env')
    if (fs.existsSync(userDataEnvPath)) {
      const rawEnv = fs.readFileSync(userDataEnvPath, 'utf8')
      const apiUrlMatch = rawEnv.match(/^VITE_API_URL\s*=\s*"?([^"\r\n]*)"?\s*$/m)
      const currentApiUrl = (apiUrlMatch?.[1] ?? '').trim()
      const needsMigration = !currentApiUrl
        || currentApiUrl === 'https://'
        || currentApiUrl === 'http://'
        || /^https?:\/\/?$/.test(currentApiUrl)
      if (needsMigration) {
        log.warn(`[App] userData .env migration: VITE_API_URL="${currentApiUrl}" -> https://yourapi.example.com/api/v1`)
        const fixedEnv = rawEnv.replace(
          /^VITE_API_URL\s*=.*$/m,
          'VITE_API_URL="https://yourapi.example.com/api/v1"',
        )
        const tmpPath = `${userDataEnvPath}.tmp`
        fs.writeFileSync(tmpPath, fixedEnv, { encoding: 'utf8', mode: 0o600 })
        fs.renameSync(tmpPath, userDataEnvPath)
        log.info('[App] userData .env migration KESZ.')
      }
    }
  } catch (err) {
    log.warn('[App] userData .env migration kihagyva:', err)
  }

  // Error reporter init (process.on('uncaughtException') + 'unhandledRejection')
  initErrorReporter('https://yourapi.example.com/api/v1/diagnostics/error-report')

  // First-run check
  const firstRunCheck = await isFirstRun()
  if (firstRunCheck.isFirstRun) {
    // Setup Wizard ablak indítása helyett a renderer-ben fut a wizard,
    // a main process csak az IPC handler-eket biztosítja
  }

  // IPC handler-ek
  ipcMain.handle('auth:google-oauth-flow', async () => runGoogleOAuthFlow())
  ipcMain.handle('diagnostics:report-error', async (_evt, payload) => reportError(payload))
  ipcMain.handle('diagnostics:set-user-identifier', async (_evt, identifier) => {
    // setUserIdentifier(identifier);
  })
  ipcMain.handle('setup:check-first-run', async () => isFirstRun())
  ipcMain.handle('setup:run', async (_evt, payload) => runFirstTimeSetup(payload))

  await createWindow()
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

// uncaughtException + unhandledRejection → error-reporter (init() regisztrálja)
```

### 5.3 preload.ts — IPC bridge

```typescript
// electron/preload.ts
import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('electronAPI', {
  googleOAuthFlow: () => ipcRenderer.invoke('auth:google-oauth-flow'),
  reportError: (payload: any) => ipcRenderer.invoke('diagnostics:report-error', payload),
  setUserIdentifier: (id: string) => ipcRenderer.invoke('diagnostics:set-user-identifier', id),
  checkFirstRun: () => ipcRenderer.invoke('setup:check-first-run'),
  runSetup: (payload: any) => ipcRenderer.invoke('setup:run', payload),
  getConfig: (key: string) => ipcRenderer.invoke('config:get', key),
})
```

### 5.4 first-run.ts — Setup Wizard 5 lépés (KRITIKUS: NE küldd a bootstrapPassword-öt currentPassword-ként)

```typescript
// electron/first-run.ts
import { app, net } from 'electron'
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import log from 'electron-log/main'

export interface SetupSavePayload {
  branchCode: string
  branchName: string
  apiUrl: string
  companyCode: string
  adminUsername: string
  adminPassword: string         // új admin jelszó
  bootstrapUsername?: string    // Step 3: rendszer-admin auth (opcionális)
  bootstrapPassword?: string
  selectedWorkerCode?: string   // Step 4: dolgozó-választó
  selectedWorkerName?: string
  selectedWorkerRole?: string
  offlineMode: boolean
  appMode?: 'pawn' | 'jewelry'
}

export async function runFirstTimeSetup(payload: SetupSavePayload) {
  // ... validation, branch check, backend health, stb.

  if (payload.selectedWorkerCode && payload.selectedWorkerCode.trim().length > 0) {
    log.info('[Setup] Worker first-time-setup uton:', payload.selectedWorkerCode)

    // ⚠️ KRITIKUS (10.6): a `bootstrapPassword` a step 3 SYSTEM admin auth.
    //    NEM a kiválasztott worker seed-jelszava. Ezért NE küldd `currentPassword`-ként.
    //    A backend WorkerFirstTimeSetupService EXPLICIT engedi az ÜRES `currentPassword`-öt
    //    seed workerekre (passwordChangedAt == null).
    const workerSetup = await workerFirstTimeSetup(payload.apiUrl, {
      companyCode: payload.companyCode,
      workerCode: payload.selectedWorkerCode.trim().toUpperCase(),
      newPassword: payload.adminPassword,
      // NE: currentPassword: payload.bootstrapPassword ❌
    })

    if (!workerSetup.success) {
      return {
        success: false,
        errorMessage: `A dolgozói jelszó beállítása nem sikerült: ${workerSetup.errorMessage}`,
      }
    }
    // ... env file írás, app.relaunch()
  }
}

async function workerFirstTimeSetup(
  apiUrl: string,
  payload: { companyCode: string; workerCode: string; newPassword: string; currentPassword?: string },
): Promise<{ success: boolean; errorMessage?: string; workerIdentity?: any }> {
  return new Promise((resolve) => {
    const req = net.request({
      method: 'POST',
      url: `${apiUrl.replace(/\/+$/, '')}/auth/first-time-worker-setup`,
    })
    req.setHeader('Content-Type', 'application/json')
    let body = ''
    req.on('response', (resp) => {
      resp.on('data', (chunk) => { body += chunk.toString() })
      resp.on('end', () => {
        try {
          const parsed = JSON.parse(body)
          resolve({
            success: resp.statusCode === 200,
            errorMessage: resp.statusCode !== 200 ? parsed.message : undefined,
            workerIdentity: parsed.workerIdentity,
          })
        } catch {
          resolve({ success: false, errorMessage: 'Parse hiba' })
        }
      })
    })
    req.on('error', (err) => resolve({ success: false, errorMessage: err.message }))
    req.write(JSON.stringify(payload))
    req.end()
  })
}
```

### 5.5 google-oauth.ts — RFC 8252 Authorization Code Flow + loopback redirect

> ⚠️ KRITIKUS (10.11): a Google Sign-in **Web SDK** (gsi/client) **NEM működik** Electron-ban (`app://localhost` origin → `idpiframe_initialization_failed`). **Desktop OAuth client + loopback redirect KELL.**

```typescript
// electron/google-oauth.ts
import { app, net, shell } from 'electron'
import http from 'node:http'
import crypto from 'node:crypto'
import log from 'electron-log/main'

// ⚠️ A Google Cloud Console-ban "Desktop app" típusú OAuth client kell, NEM Web!
//    Két KÜLÖN client_id van — a Web az admin-frontendnek, a Desktop ennek.
const DESKTOP_CLIENT_ID = process.env.GOOGLE_DESKTOP_CLIENT_ID || ''
const DESKTOP_CLIENT_SECRET = process.env.GOOGLE_DESKTOP_CLIENT_SECRET || ''

interface OAuthResult {
  idToken: string
  accessToken: string
  email?: string
  sub?: string
}

export async function runGoogleOAuthFlow(): Promise<OAuthResult> {
  // 1. PKCE (RFC 7636) — code_verifier + code_challenge
  const codeVerifier = base64url(crypto.randomBytes(32))
  const codeChallenge = base64url(crypto.createHash('sha256').update(codeVerifier).digest())

  // 2. State CSRF
  const state = base64url(crypto.randomBytes(16))

  // 3. Loopback HTTP server (RFC 8252)
  const server = http.createServer()
  const port = await new Promise<number>((resolve) => {
    server.listen(0, '127.0.0.1', () => {
      const addr = server.address()
      if (addr && typeof addr === 'object') resolve(addr.port)
    })
  })
  const redirectUri = `http://127.0.0.1:${port}/callback`

  // 4. Auth URL
  const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth')
  authUrl.searchParams.set('client_id', DESKTOP_CLIENT_ID)
  authUrl.searchParams.set('redirect_uri', redirectUri)
  authUrl.searchParams.set('response_type', 'code')
  authUrl.searchParams.set('scope', 'openid email profile')
  authUrl.searchParams.set('state', state)
  authUrl.searchParams.set('code_challenge', codeChallenge)
  authUrl.searchParams.set('code_challenge_method', 'S256')
  authUrl.searchParams.set('access_type', 'offline')

  await shell.openExternal(authUrl.toString())  // user böngészőjében nyit

  // 5. Várjuk a callback-et
  const code = await new Promise<string>((resolve, reject) => {
    const timeout = setTimeout(() => {
      server.close()
      reject(new Error('OAuth flow timeout (5 min)'))
    }, 5 * 60 * 1000)

    server.on('request', (req, res) => {
      const url = new URL(req.url ?? '/', `http://127.0.0.1:${port}`)
      if (url.pathname !== '/callback') {
        res.writeHead(404).end()
        return
      }
      const returnedState = url.searchParams.get('state')
      const returnedCode = url.searchParams.get('code')
      if (returnedState !== state) {
        res.writeHead(400, { 'Content-Type': 'text/html; charset=utf-8' })
        res.end('<h1>State CSRF mismatch</h1>')
        clearTimeout(timeout)
        server.close()
        reject(new Error('State CSRF mismatch'))
        return
      }
      if (!returnedCode) {
        res.writeHead(400).end()
        return
      }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' })
      res.end('<h1>Sikeres bejelentkezés!</h1><p>Visszatérhetsz az alkalmazásba.</p>')
      clearTimeout(timeout)
      server.close()
      resolve(returnedCode)
    })
  })

  // 6. Token exchange — code → idToken + accessToken
  const tokenResp = await electronNetPostForm('https://oauth2.googleapis.com/token', {
    code,
    client_id: DESKTOP_CLIENT_ID,
    client_secret: DESKTOP_CLIENT_SECRET,
    redirect_uri: redirectUri,
    grant_type: 'authorization_code',
    code_verifier: codeVerifier,
  })

  const tokenData = JSON.parse(tokenResp) as {
    id_token: string; access_token: string
  }

  // 7. ID token decode (csak az email-hez log-olásra; verify a backend-en)
  const decoded = decodeIdTokenPayload(tokenData.id_token)

  log.info('[google-oauth] Login OK:', decoded.email)
  return {
    idToken: tokenData.id_token,
    accessToken: tokenData.access_token,
    email: decoded.email,
    sub: decoded.sub,
  }
}

function base64url(buf: Buffer): string {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function decodeIdTokenPayload(idToken: string): { email?: string; sub?: string } {
  try {
    const parts = idToken.split('.')
    if (parts.length !== 3) return {}
    const part1 = parts[1]
    if (!part1) return {}
    // 'base64url' encoding TS lib type-on néha hiányzik → cast
    const payloadJson = Buffer.from(part1, 'base64url' as BufferEncoding).toString('utf8')
    const payload = JSON.parse(payloadJson) as { email?: string; sub?: string }
    return { email: payload.email, sub: payload.sub }
  } catch { return {} }
}

function electronNetPostForm(url: string, fields: Record<string, string>): Promise<string> {
  return new Promise((resolve, reject) => {
    const req = net.request({ method: 'POST', url })
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded')
    let body = ''
    req.on('response', (resp) => {
      resp.on('data', (chunk) => { body += chunk.toString() })
      resp.on('end', () => resolve(body))
    })
    req.on('error', reject)
    const formBody = Object.entries(fields)
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
      .join('&')
    req.write(formBody)
    req.end()
  })
}
```

### 5.6 error-reporter.ts — send-and-forget HTTPS queue

```typescript
// electron/error-reporter.ts
import { net } from 'electron'
import log from 'electron-log/main'

interface ErrorPayload {
  component: string
  message: string
  stack?: string
  context?: Record<string, unknown>
}

interface QueueEntry extends ErrorPayload {
  timestamp: number
}

const MAX_QUEUE_SIZE = 50
const ANTI_SPAM_INTERVAL_MS = 5_000   // ugyanaz az üzenet 5s-en belül skip
const FLUSH_INTERVAL_MS = 5 * 60 * 1000  // 5 perc

let endpointUrl = ''
let queue: QueueEntry[] = []
let lastSentAt = new Map<string, number>()
let userIdentifier: string | null = null
let flushTimer: NodeJS.Timeout | null = null

export function initErrorReporter(url: string): void {
  endpointUrl = url

  process.on('uncaughtException', (err) => {
    void report({
      component: 'electron-main',
      message: err.message,
      stack: err.stack,
    })
  })
  process.on('unhandledRejection', (reason) => {
    void report({
      component: 'electron-main',
      message: 'unhandledRejection: ' + String(reason),
    })
  })

  flushTimer = setInterval(() => { void flushQueue() }, FLUSH_INTERVAL_MS)
  log.info('[App] Error reporter initialized -> POST', endpointUrl)
}

export function setUserIdentifier(id: string): void {
  userIdentifier = id
}

export async function report(payload: ErrorPayload): Promise<void> {
  // anti-spam: ugyanaz az üzenet 5s-en belül skip
  const key = `${payload.component}:${payload.message.slice(0, 80)}`
  const now = Date.now()
  if ((lastSentAt.get(key) ?? 0) > now - ANTI_SPAM_INTERVAL_MS) return
  lastSentAt.set(key, now)

  if (queue.length >= MAX_QUEUE_SIZE) {
    queue.shift()  // legrégebbi-t dobjuk
  }
  queue.push({ ...payload, timestamp: now })

  // azonnali küldés-kísérlet (send-and-forget)
  void sendOne({ ...payload, timestamp: now })
}

async function sendOne(entry: QueueEntry): Promise<void> {
  if (!endpointUrl) return
  return new Promise((resolve) => {
    try {
      const req = net.request({ method: 'POST', url: endpointUrl })
      req.setHeader('Content-Type', 'application/json')
      const body = JSON.stringify({
        component: entry.component,
        version: process.env.npm_package_version,
        osInfo: `${process.platform} ${process.arch}`,
        userIdentifier,
        errorMessage: entry.message,
        stackTrace: entry.stack,
        context: entry.context,
      })
      req.on('response', (resp) => {
        if (resp.statusCode === 200) {
          // sikeres: kivesszük a queue-ból
          queue = queue.filter((e) => e.timestamp !== entry.timestamp)
        }
        resp.on('end', resolve)
        resp.on('data', () => {})
      })
      req.on('error', () => resolve())
      req.write(body)
      req.end()
    } catch { resolve() }
  })
}

async function flushQueue(): Promise<void> {
  const snapshot = [...queue]
  for (const entry of snapshot) {
    await sendOne(entry)
  }
}
```

---

## 6. Google OAuth — DUAL setup

> ⚠️ A Web és a Desktop OAuth flow **KÉT KÜLÖN client_id-t használ**. Ne keverd!

### 6.1 Google Cloud Console setup

1. **Google Cloud Console → APIs & Services → Credentials**
2. **Create Credentials → OAuth client ID**

#### a) Web client (admin-frontend, browser)
- Application type: **Web application**
- Authorized JavaScript origins: `https://yourapi.example.com`
- Authorized redirect URIs: `https://yourapi.example.com/api/v1/auth/google-callback`
- Mentsd: **Web client_id** (használat: frontend `VITE_GOOGLE_WEB_CLIENT_ID`)

#### b) Desktop client (Electron, RFC 8252)
- Application type: **Desktop app**
- Mentsd: **Desktop client_id + client_secret** (használat: Electron env)

### 6.2 Backend GoogleLoginConfig — audience list

```java
package com.yourcompany.yourapp.config;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class GoogleLoginConfig {

    // .env-ből érkeznek mindkét client_id
    @Value("${google.web.client.id}")
    private String webClientId;

    @Value("${google.desktop.client.id}")
    private String desktopClientId;

    @Bean
    public GoogleIdTokenVerifier googleIdTokenVerifier() {
        // ⚠️ MINDKÉT client_id legyen az audience list-ben — különben
        // a Desktop ID token NEM verifálható.
        return new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), GsonFactory.getDefaultInstance())
            .setAudience(List.of(webClientId, desktopClientId))
            .build();
    }
}
```

### 6.3 Backend AuthController — Google login endpoint

```java
@PostMapping("/google-login")
@PreAuthorize("permitAll()")
public ResponseEntity<LoginResponse> googleLogin(@RequestBody GoogleLoginRequest req) throws Exception {
    GoogleIdToken idToken = googleIdTokenVerifier.verify(req.idToken());
    if (idToken == null) {
        return ResponseEntity.status(401).body(new LoginResponse(false, null, null, "Invalid Google ID token"));
    }
    String email = idToken.getPayload().getEmail();

    // Whitelist: csak engedélyezett email
    User user = userRepository.findByEmail(email)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Email nincs whitelisten: " + email));

    // JWT issue
    String accessToken = jwtService.generateAccessToken(user);
    String refreshToken = jwtService.generateRefreshToken(user);

    return ResponseEntity.ok()
        .header(HttpHeaders.SET_COOKIE, refreshCookie(refreshToken))
        .body(new LoginResponse(true, accessToken, user, null));
}
```

### 6.4 Whitelist email pattern

```sql
-- V100__user_whitelist.sql
CREATE TABLE user_whitelist (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES company(id),
  email VARCHAR(200) NOT NULL,
  role VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, email)
);

INSERT INTO user_whitelist (company_id, email, role) VALUES
  (1, 'admin@yourcompany.com', 'ADMIN'),
  (1, 'cashier1@yourcompany.com', 'CASHIER');
```

---

## 7. Auto Error Reporting (Sentry-style, in-house)

### 7.1 Architektúra

```
[Penztar.exe / Zalog.exe]
   │ uncaughtException / axios 4xx-5xx / unhandledRejection
   ▼
[error-reporter.ts in-memory queue (max 50, anti-spam 5s, flush 5min)]
   │ HTTPS POST (send-and-forget)
   ▼
[Backend DiagnosticsController]
   │ permitAll + idempotency-skip + rate-limit
   ▼
[PostgreSQL client_error_log table (JSONB context, VARCHAR(45) IP)]
   │
   ▼
[GitHubIssueAutoCreator @Async]
   │ CRITICAL_PATTERN regex match? + 24h dedup signature
   ▼
[GitHub Issue auto-created (label: client-error, auto-reported)]
   │
   ▼
[Hourly auto-triage routine (mcp__scheduled-tasks)]
   │ classify + comment + opcionális <20 LOC fix PR
```

### 7.2 ErrorReportDto — `Map<String, Object>` (NEM JsonNode!)

```java
package com.yourcompany.yourapp.dto.diagnostics;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ErrorReportDto {

    @NotBlank
    @Pattern(regexp = "^(electron-main|electron-renderer|nsis-installer|axios-http|setup-wizard|sync-engine|other)$")
    @Size(max = 80)
    private String component;

    @Size(max = 40)
    private String version;

    @Size(max = 200)
    private String osInfo;

    @Size(max = 150)
    private String userIdentifier;

    @NotBlank
    @Size(max = 1000)
    private String errorMessage;

    @Size(max = 8000)
    private String stackTrace;

    /**
     * ⚠️ Map<String, Object>, NEM JsonNode! Lásd 10.2.
     * SB4 default Jackson 3, ami a `com.fasterxml.jackson.databind.JsonNode`-ot
     * NEM tudja deszerializálni. A Map dual-stack-friendly.
     */
    private Map<String, Object> context;
}
```

### 7.3 ClientErrorLog entity — VARCHAR(45) (NEM INET!)

```java
@Entity
@Table(name = "client_error_log")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ClientErrorLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "component", nullable = false, length = 80)
    private String component;

    @Column(name = "version", length = 40)
    private String version;

    @Column(name = "os_info", length = 200)
    private String osInfo;

    @Column(name = "user_identifier", length = 150)
    private String userIdentifier;

    @Column(name = "error_message", nullable = false, length = 1000)
    private String errorMessage;

    @Column(name = "stack_trace", columnDefinition = "TEXT")
    private String stackTrace;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "context", columnDefinition = "JSONB")
    private String contextJson;

    /**
     * IPv4 vagy IPv6 cím (max 45 char: IPv6 39 + esetleg ::ffff:1.2.3.4 IPv4-mapped).
     * ⚠️ VARCHAR(45), NEM INET! Lásd 10.1.
     */
    @Column(name = "client_ip", length = 45)
    private String clientIp;

    @Column(name = "user_agent", length = 300)
    private String userAgent;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
```

### 7.4 Migration — V1_init + V_followup INET fix

```sql
-- V100__client_error_log_table.sql
CREATE TABLE client_error_log (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    component VARCHAR(80) NOT NULL,
    version VARCHAR(40),
    os_info VARCHAR(200),
    user_identifier VARCHAR(150),
    error_message VARCHAR(1000) NOT NULL,
    stack_trace TEXT,
    context JSONB,
    -- ⚠️ EGYBŐL VARCHAR(45), NE INET! (10.1)
    client_ip VARCHAR(45),
    user_agent VARCHAR(300)
);

CREATE INDEX idx_client_error_log_created_at ON client_error_log (created_at DESC);
CREATE INDEX idx_client_error_log_component ON client_error_log (component);
```

### 7.5 DiagnosticsController

```java
package com.yourcompany.yourapp.controller;

import com.yourcompany.yourapp.dto.diagnostics.ErrorReportDto;
import com.yourcompany.yourapp.entity.ClientErrorLog;
import com.yourcompany.yourapp.repository.ClientErrorLogRepository;
import com.yourcompany.yourapp.service.GitHubIssueAutoCreator;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/diagnostics")
@RequiredArgsConstructor
@Slf4j
public class DiagnosticsController {

    private final ClientErrorLogRepository errorLogRepository;
    private final GitHubIssueAutoCreator gitHubIssueAutoCreator;

    @PostMapping("/error-report")
    @PreAuthorize("permitAll()")
    @Transactional
    public ResponseEntity<Map<String, Object>> reportError(
            @Valid @RequestBody ErrorReportDto dto,
            HttpServletRequest request) {

        String clientIp = extractClientIp(request);
        String userAgent = truncate(request.getHeader("User-Agent"), 300);

        ClientErrorLog entry = ClientErrorLog.builder()
            .component(dto.getComponent())
            .version(truncate(dto.getVersion(), 40))
            .osInfo(truncate(dto.getOsInfo(), 200))
            .userIdentifier(truncate(dto.getUserIdentifier(), 150))
            .errorMessage(truncate(dto.getErrorMessage(), 1000))
            .stackTrace(truncate(dto.getStackTrace(), 8000))
            .contextJson(serializeContext(dto.getContext()))
            .clientIp(clientIp)
            .userAgent(userAgent)
            .build();

        errorLogRepository.save(entry);

        log.warn("[client-error] {} v{} {} | user={} | ip={} | msg='{}'",
            dto.getComponent(), dto.getVersion(), dto.getOsInfo(),
            dto.getUserIdentifier(), clientIp, truncate(dto.getErrorMessage(), 200));

        // Aszinkron eskalálás GitHub Issue-ra
        gitHubIssueAutoCreator.evaluateAndEscalate(entry);

        return ResponseEntity.ok(Map.of("ok", true, "id", entry.getId()));
    }

    @GetMapping("/health")
    @PreAuthorize("permitAll()")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of("ok", true, "totalReportedErrors", errorLogRepository.count()));
    }

    private String extractClientIp(HttpServletRequest req) {
        // Reverse-proxy mögött (Caddy → Tomcat) az X-Forwarded-For-ban van a valódi IP
        String fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            return fwd.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }

    private String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }

    private String serializeContext(Map<String, Object> ctx) {
        if (ctx == null || ctx.isEmpty()) return null;
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(ctx);
        } catch (Exception ex) {
            log.warn("Context serialize failed: {}", ex.getMessage());
            return ctx.toString();
        }
    }
}
```

### 7.6 GitHubIssueAutoCreator — @Async + 24h dedup

```java
package com.yourcompany.yourapp.service;

import com.yourcompany.yourapp.entity.ClientErrorLog;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Slf4j
public class GitHubIssueAutoCreator {

    private static final Pattern CRITICAL_PATTERN = Pattern.compile(
        "uncaughtException|timeout|ECONNREFUSED|setupWizard.*fail|Network Error",
        Pattern.CASE_INSENSITIVE);

    @Value("${github.issue.auto-create.enabled:false}")
    private boolean enabled;

    @Value("${github.issue.auto-create.token:}")
    private String token;

    @Value("${github.issue.auto-create.repo:}")
    private String repo;

    /** signature → last issue createdAt — in-memory dedup */
    private final ConcurrentHashMap<String, LocalDateTime> recentSignatures = new ConcurrentHashMap<>();

    @Async
    public void evaluateAndEscalate(ClientErrorLog entry) {
        if (!enabled || token.isBlank() || repo.isBlank()) {
            log.info("[GitHubIssueAutoCreator] enabled=false vagy hiányzó config, skip");
            return;
        }

        String msg = entry.getErrorMessage() != null ? entry.getErrorMessage() : "";
        if (!CRITICAL_PATTERN.matcher(msg).find()) {
            return;  // nem kritikus minta
        }

        // 24h dedup
        String signature = entry.getComponent() + ":" + msg.substring(0, Math.min(80, msg.length()));
        LocalDateTime lastTime = recentSignatures.get(signature);
        if (lastTime != null && lastTime.isAfter(LocalDateTime.now().minusHours(24))) {
            log.info("[GitHubIssueAutoCreator] dedup match ({}), skip", signature);
            return;
        }
        recentSignatures.put(signature, LocalDateTime.now());

        // GitHub Issue create
        try {
            String body = String.format("""
                **Auto-eskalalt kliens hiba** (%s)

                | Mező | Érték |
                |------|-------|
                | ID | %d |
                | Időpont | %s |
                | Komponens | `%s` |
                | Verzió | `%s` |
                | OS | `%s` |

                ## Hibaüzenet
                ```
                %s
                ```

                ## Stack trace
                ```
                %s
                ```

                ## Kontextus
                ```json
                %s
                ```

                ---
                *Privacy: a user_identifier (Google email) NEM kerul ide. SSH-zel barmikor lekerheto.*
                """,
                repo, entry.getId(), entry.getCreatedAt(),
                entry.getComponent(), entry.getVersion(), entry.getOsInfo(),
                entry.getErrorMessage(), entry.getStackTrace(), entry.getContextJson());

            String json = """
                {"title": "[auto] %s — %s", "body": %s, "labels": ["client-error", "auto-reported"]}
                """.formatted(
                escapeJson(entry.getErrorMessage().substring(0, Math.min(80, msg.length()))),
                escapeJson(entry.getComponent()),
                jsonString(body));

            HttpClient client = HttpClient.newHttpClient();
            HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(String.format("https://api.github.com/repos/%s/issues", repo)))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/vnd.github+json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();
            HttpResponse<String> resp = client.send(req, HttpResponse.BodyHandlers.ofString());
            log.info("[GitHubIssueAutoCreator] issue created for client-error #{}, response={}",
                entry.getId(), resp.statusCode());
        } catch (Exception ex) {
            log.error("[GitHubIssueAutoCreator] failed: {}", ex.getMessage());
        }
    }

    private String escapeJson(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private String jsonString(String s) {
        return "\"" + escapeJson(s) + "\"";
    }
}
```

### 7.7 Hourly auto-triage routine (Claude Code scheduled-task)

A repo gyökerében nem kell scriptet írni — a **lokális Claude Code-ban** `mcp__scheduled-tasks__create_scheduled_task` tool-lal hozz létre egy óránkénti task-ot. A prompt:

```
Te egy autonóm Claude routine vagy, ami óránként triázsolja a [PROJECT_NAME] auto-reportolt kliens-hibáit.

## REPO
Lokális: D:\repo\zalog-program (vagy ekszer-program)
Remote: youruser/zalog-program

## WORKFLOW (óránként)
1. cd a repo-ba, gh auth status check
2. gh issue list -R youruser/zalog-program --label client-error --label auto-reported --state open --limit 50 (last 90 perc)
3. SSH-on a Hetzner-re: SELECT id, component, error_message, client_ip FROM client_error_log WHERE created_at > NOW() - INTERVAL '90 minutes'
4. Klasszifikáció:
   - axios timeout / Network Error → server-side (Cloudflare, Caddy, backend health)
   - uncaughtException → client bug (recent commits)
   - PSQLException / Hibernate → backend bug
5. Komment minden új issue-ra (klasszifikáció + root cause + javasolt fix)
6. <20 LOC obvious fix → új branch + commit + PR (NEM auto-merge)
7. >20 LOC → needs-human-review label
8. Duplikátum → close + duplicate label

## ABSZOLÚT SZABÁLYOK
- ⛔ SOHA ne küldj parancssoros utasítást a kollégáknak — server-side / installer fix
- ⛔ SOHA ne expose tokent / user_identifier-t / IP-t issue commentekben
- ⛔ Csak biztosan értett javítás, bizonytalan eseteknél needs-human-review
```

Cron: `13 * * * *` lokális idő (8 perc jitter → ~`:21`-kor fut).

---

## 8. Deployment — Hetzner + Caddy + Cloudflare

### 8.1 Hetzner VPS setup

```bash
# Ubuntu 22.04 LTS, x86_64
# Csomagok
apt update && apt upgrade -y
apt install -y openjdk-21-jdk postgresql-17 caddy

# PostgreSQL setup
sudo -u postgres psql -c "CREATE USER yourapp WITH PASSWORD 'STRONG_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE yourapp OWNER yourapp;"

# Backend systemd unit
cat > /etc/systemd/system/yourapp-backend.service <<'EOF'
[Unit]
Description=YourApp Backend
After=network.target postgresql.service

[Service]
Type=simple
User=yourapp
WorkingDirectory=/opt/yourapp
ExecStart=/usr/lib/jvm/java-21-openjdk-amd64/bin/java -jar /opt/yourapp/yourapp-backend.jar
EnvironmentFile=/etc/yourapp/yourapp.env
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# .env (chmod 600)
mkdir /etc/yourapp
cat > /etc/yourapp/yourapp.env <<EOF
DB_PASSWORD=STRONG_PASSWORD
JWT_SECRET=$(openssl rand -hex 32)
GOOGLE_WEB_CLIENT_ID=...
GOOGLE_DESKTOP_CLIENT_ID=...
GITHUB_ISSUE_AUTO_CREATE_ENABLED=true
GITHUB_ISSUE_AUTO_CREATE_TOKEN=github_pat_...
GITHUB_ISSUE_AUTO_CREATE_REPO=youruser/zalog-program
EOF
chmod 600 /etc/yourapp/yourapp.env
chown yourapp:yourapp /etc/yourapp/yourapp.env

# Service indítás
useradd -r -s /bin/false yourapp
mkdir /opt/yourapp && chown yourapp:yourapp /opt/yourapp
systemctl daemon-reload
systemctl enable --now yourapp-backend
```

### 8.2 Caddy reverse proxy

```caddyfile
# /etc/caddy/Caddyfile
yourapi.example.com {
    encode gzip
    reverse_proxy localhost:8080 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
    log {
        output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
        }
    }
}
```

```bash
caddy reload --config /etc/caddy/Caddyfile
```

### 8.3 Cloudflare DNS — IPv6 OFF kötelező!

> ⚠️ **(10.8)** Magyar ISP-knél az IPv6 routing nem mindig működik megbízhatóan. Ha az AAAA record él, a Chromium happy-eyeballs-on hangol, axios timeout. **Kapcsold ki**.

```bash
# Cloudflare API-val (CF_API_TOKEN-t a tokMINDEN.txt-ből vagy hasonlóan tárolva)
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/settings/ipv6" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"value":"off"}'
```

VAGY Cloudflare dashboard:
- Zone → Network → IPv6 Compatibility → **Off**

### 8.4 GitHub Actions auto-deploy on main

```yaml
# .github/workflows/deploy.yml
name: Deploy to Hetzner VPS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: 21

      - name: Build backend
        working-directory: backend
        run: ./mvnw package -DskipTests

      - name: SCP JAR to Hetzner
        env:
          SSH_KEY: ${{ secrets.HETZNER_SSH_PRIVATE_KEY }}
          SERVER: ${{ secrets.HETZNER_SERVER_IP }}
        run: |
          mkdir -p ~/.ssh && echo "$SSH_KEY" > ~/.ssh/id && chmod 600 ~/.ssh/id
          scp -i ~/.ssh/id -o StrictHostKeyChecking=no \
              backend/target/yourapp-backend-*.jar \
              root@${SERVER}:/opt/yourapp/yourapp-backend.jar
          ssh -i ~/.ssh/id -o StrictHostKeyChecking=no root@${SERVER} \
              "systemctl restart yourapp-backend"
```

### 8.5 GitHub Actions secrets

| Secret | Forrás |
|---|---|
| `HETZNER_SSH_PRIVATE_KEY` | `~/.ssh/hetzner_ed25519` tartalma |
| `HETZNER_SERVER_IP` | Hetzner Cloud Console |
| `GOOGLE_DESKTOP_CLIENT_ID` | Google Cloud Console → Credentials |
| `GOOGLE_DESKTOP_CLIENT_SECRET` | ugyanott |
| `GITHUB_ISSUE_AUTO_CREATE_TOKEN` | github.com/settings/tokens (fine-grained PAT, repo+issues+pulls scope) |

---

## 9. Installer (NSIS) — Windows

### 9.1 Project structure

```
installer/
├── YourApp-Setup.nsi              # NSIS installer script
├── YourApp-Cleanup.nsi            # NSIS uninstaller (verzió-független)
├── build-installer.ps1            # ferro: 4-way version sync + mvn + npm + makensis
├── build-cleanup.ps1              # az uninstaller külön build script
├── build-common.ps1               # shared utility (Get-VersionFromPackageJson)
├── scripts/
│   └── check-version-bump.ps1     # AUTO-PATCH version gate
└── build/                         # output (gitignored)
    ├── stage/                     # staging dir az fájloknak
    ├── YourApp-Setup-X.Y.Z-DATE.exe
    └── YourApp-Eltavolito-X.Y.Z-DATE.exe
```

### 9.2 4-way version sync gate

Minden buildelés előtt **4 helyen kell ugyanaz a verziószám**:
- `package.json` (root)
- `frontend-admin/package.json`
- `desktop-client/package.json`
- `backend/pom.xml`

Ha bármelyik eltér, a build gate exit 2-vel failel. (Lásd 10.13)

```powershell
# scripts/check-version-bump.ps1
[CmdletBinding()]
param(
  [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..\.."),
  [string]$BuildDir,
  [string]$CurrentVersion,
  [switch]$NoAutoPatch
)
. "$PSScriptRoot\..\build-common.ps1"

$rootJson = Get-VersionFromPackageJson -ScriptRoot "$RepoRoot"
$frontendJson = Get-VersionFromPackageJson -ScriptRoot "$RepoRoot\frontend-admin"
$desktopJson = Get-VersionFromPackageJson -ScriptRoot "$RepoRoot\desktop-client"
$pomXml = Get-VersionFromPomXml -PomPath "$RepoRoot\backend\pom.xml"

$versions = @($rootJson, $frontendJson, $desktopJson, $pomXml) | Sort-Object -Unique
if ($versions.Count -gt 1) {
    Write-Host "ERROR: Version drift detected. All 4 locations must be in sync."
    Write-Host "Found: $($versions -join ', ')"
    exit 2
}
# ... AUTO-PATCH bump if needed (lásd a Valutavalto check-version-bump.ps1 minta)
```

### 9.3 NSIS encoding rule — Windows-1252 ASCII only

> ⚠️ **(10.14)** A `.nsi` fájlokban **NE használj ékezetet, em-dash-t (—), vagy bármi non-ASCII karaktert**. Az NSIS Windows-1252-ben mentett fájlt parsolja, és pl. egy "ő" karakter a ProductName mezőben ki tudja botoltatni a teljes installer GUI-t.

```nsis
# ❌ ROSSZ
!define MUI_PAGE_HEADER_TEXT "Pénztár telepítés — válaszd ki az iroda kódját"

# ✅ JÓ (sima ASCII)
!define MUI_PAGE_HEADER_TEXT "Penztar telepites - valaszd ki az iroda kodjat"
```

### 9.4 YourApp-Setup.nsi minta — THIN/FULL mode

```nsis
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "nsDialogs.nsh"

!define APP_NAME "YourApp"
!define APP_VERSION "${VERSION}"  ; build-installer.ps1 cli args-ból
!define INSTALL_DIR "$PROGRAMFILES64\${APP_NAME}"
!define DATA_DIR "$APPDATA\${APP_NAME}"

Name "${APP_NAME}"
OutFile "build\${APP_NAME}-Setup-${APP_VERSION}-${BUILD_DATE}.exe"
InstallDir "${INSTALL_DIR}"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

Var INSTALL_MODE   ; "THIN" vagy "FULL"

; --- Custom InstallMode page ---
Var DLG_RB_THIN
Var DLG_RB_FULL

Function InstallModePage
  !insertmacro MUI_HEADER_TEXT "Telepitesi tipus" "Valaszd ki: online vagy offline"
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 100% 24u "Az alkalmazas ket modban hasznalhato. Az alapertelmezett (Online) elegendo a legtobb felhasznalonak."
  Pop $0
  ${NSD_CreateRadioButton} 0 30u 100% 12u "Online klient (alapertelmezett)"
  Pop $DLG_RB_THIN
  ${NSD_OnClick} $DLG_RB_THIN OnSelectThin
  ${NSD_CreateRadioButton} 0 60u 100% 12u "Offline-kepes klient (lokalis Postgres + Java backend ~280 MB)"
  Pop $DLG_RB_FULL
  ${NSD_OnClick} $DLG_RB_FULL OnSelectFull
  ${NSD_SetState} $DLG_RB_THIN ${BST_CHECKED}
  StrCpy $INSTALL_MODE "THIN"
  nsDialogs::Show
FunctionEnd

Function OnSelectThin
  StrCpy $INSTALL_MODE "THIN"
FunctionEnd

Function OnSelectFull
  StrCpy $INSTALL_MODE "FULL"
FunctionEnd

; --- Init ---
Function .onInit
  ; Default mode silent install esetén
  ${If} $INSTALL_MODE == ""
    StrCpy $INSTALL_MODE "THIN"
  ${EndIf}
FunctionEnd

; --- Pages ---
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom InstallModePage
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "Hungarian"

; --- Install section ---
Section "MainInstall" SEC_MAIN
  ; Penztar.exe + node_modules + dist mindig települ (THIN + FULL is)
  SetOutPath "${INSTALL_DIR}"
  File /r "${STAGE_DIR}\client\*"

  ; Backend csak FULL módban
  ${If} $INSTALL_MODE == "FULL"
    DetailPrint "FULL mod: backend + Postgres telepitese..."
    SetOutPath "${DATA_DIR}\backend"
    File "${STAGE_DIR}\backend\yourapp-backend.jar"
    File /r "${STAGE_DIR}\postgres\*"
    ; ... systemctl-szerű Windows service install
  ${EndIf}

  ; Asztali parancsikon
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "${INSTALL_DIR}\YourApp.exe"

  ; DNS cache flush (IP-cím frissesség biztosítása)
  ExecWait 'ipconfig /flushdns'
SectionEnd
```

### 9.5 build-installer.ps1 — fő build pipeline

```powershell
# installer/build-installer.ps1
param(
  [string]$Version,
  [switch]$SkipDownloads
)
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\build-common.ps1"

# 1/6: Verzió-load + 4-way gate
if (-not $Version) {
    $Version = Get-VersionFromPackageJson -ScriptRoot $PSScriptRoot
}
$BuildDate = Get-Date -Format 'yyyyMMdd'
& "$PSScriptRoot\scripts\check-version-bump.ps1" -CurrentVersion $Version
if ($LASTEXITCODE -ne 0) { throw "VERSION BUMP GATE FAILED" }

# 2/6: Backend build (mvn package)
Push-Location "$PSScriptRoot\..\backend"
& .\mvnw.cmd package -DskipTests -q
Pop-Location

# 3/6: Frontend admin build (npm install + npm run build)
Push-Location "$PSScriptRoot\..\frontend-admin"
npm ci
npm run build
Pop-Location

# 4/6: Desktop client build (npm install + npm run build:electron)
Push-Location "$PSScriptRoot\..\desktop-client"
npm ci
npm run build
Pop-Location

# 5/6: Stage dir + asset másolás
$StageDir = "$PSScriptRoot\build\stage"
Remove-Item -Recurse -Force $StageDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $StageDir | Out-Null
Copy-Item "$PSScriptRoot\..\desktop-client\dist\*" "$StageDir\client\" -Recurse -Force
Copy-Item "$PSScriptRoot\..\backend\target\yourapp-backend-*.jar" "$StageDir\backend\yourapp-backend.jar" -Force
# (Postgres binary letöltése FULL-hez)

# 6/6: NSIS makensis
& "C:\Program Files (x86)\NSIS\makensis.exe" `
  /DVERSION=$Version `
  /DBUILD_DATE=$BuildDate `
  /DSTAGE_DIR=$StageDir `
  /DOUTPUT_DIR="$PSScriptRoot\build" `
  "$PSScriptRoot\YourApp-Setup.nsi"

Write-Host "KESZ: YourApp-Setup-$Version-$BuildDate.exe"
```

### 9.6 Eltavolito külön build (verzió-független)

A YourApp-Cleanup.nsi egy **verzió-független** uninstaller — minden release-en ugyanaz, csak a fájlnévben tükrözi a verziót. Funkciója: `RMDir /r "${INSTALL_DIR}"` + `RMDir /r "${DATA_DIR}"`.

```nsis
; YourApp-Cleanup.nsi — minimal, ~60 KB
!include "MUI2.nsh"
Name "YourApp Eltavolito"
OutFile "build\YourApp-Eltavolito-${VERSION}-${BUILD_DATE}.exe"
RequestExecutionLevel admin
ShowInstDetails show

Section "Uninstall" SEC_UNINSTALL
  SetShellVarContext current
  RMDir /r "$APPDATA\YourApp"
  SetShellVarContext all
  RMDir /r "$PROGRAMFILES64\YourApp"
  Delete "$DESKTOP\YourApp.lnk"
  ; Windows uninstall registry key
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourApp"
SectionEnd
```

### 9.7 electron-builder.json + auto-update

```json
{
  "appId": "com.yourcompany.yourapp",
  "productName": "YourApp",
  "directories": {
    "output": "dist-electron",
    "buildResources": "build"
  },
  "files": ["dist/**/*", "dist-electron/**/*", "electron/**/*"],
  "extraResources": [
    {"from": "production-config.json", "to": "production-config.json"}
  ],
  "win": {
    "target": "nsis",
    "icon": "build/icon.ico"
  },
  "publish": [
    {
      "provider": "github",
      "owner": "youruser",
      "repo": "yourapp",
      "releaseType": "release"
    }
  ]
}
```

⚠️ Az auto-update **csak akkor működik**, ha a GitHub Release-ben fent van a `latest.yml` fájl. A `build-installer.ps1`-ben generáld ezt manuálisan és uplodold a release-be:

```yaml
# latest.yml (a Release-ben)
version: 1.0.5
files:
  - url: YourApp-Setup-1.0.5-20260505.exe
    sha512: <SHA512>
    size: 280123456
path: YourApp-Setup-1.0.5-20260505.exe
sha512: <SHA512>
releaseDate: '2026-05-05T10:00:00Z'
```

---

## 10. Pitfalls / Anti-patterns — 15 konkrét hiba

> Ezeket TILOS megismételni az új projektben. Mindegyikből egy iterációval, sok órányi debug-gal tanultunk.

### 10.1 PostgreSQL `INET` ↔ Hibernate String mismatch

**Tünet:** `PSQLException: column is of type inet but expression is of type character varying`

**Forrás:** Valutavaltó PR #414 (V183 migration), Borsi/Helga gépein 500-at adott a `/diagnostics/error-report` endpoint.

**Root cause:** Hibernate alapértelmezetten `String`-et küld a JDBC felé, az `INET` postgres-típus `Inet4Address` vagy custom converter-t igényelne.

**Fix:**
```sql
-- ❌ NE
client_ip INET

-- ✅ HASZNÁLD
client_ip VARCHAR(45)   -- IPv6 max 39 + ::ffff:1.2.3.4 IPv4-mapped 45 char
```

### 10.2 Jackson 3 `JsonNode` incompat → `Map<String, Object>`

**Tünet:** `InvalidDefinitionException: Cannot construct instance of com.fasterxml.jackson.databind.JsonNode`

**Forrás:** Valutavaltó PR #413, Spring Boot 4.0.6 + `tools.jackson.databind` default.

**Root cause:** SB4 Jackson 3-at hoz be (`tools.jackson.*`). A meglévő DTO-knál a `com.fasterxml.jackson.databind.JsonNode` import nem deszerializálható.

**Fix DTO-ban:**
```java
// ❌ NE
private JsonNode context;

// ✅ HASZNÁLD
private Map<String, Object> context;
```

**Plusz a `pom.xml`-ben:** `spring-boot-jackson2` modul + `application.properties` `spring.jackson.use-jackson2-defaults=true`.

### 10.3 SecurityFilterChain `permitAll` ALONE NEM elég

**Tünet:** `@PreAuthorize("permitAll()")` annotációval ellátott controller method-ra **401 Unauthorized**.

**Forrás:** Valutavaltó PR #411.

**Root cause:** A `@PreAuthorize` Spring Security **method-level** auth. A HTTP filter chain (JWT filter, security filter) ELŐTTE blokkol — ha az endpoint nincs `requestMatchers().permitAll()`-on, soha nem jut el a controller method-ig.

**Fix:**
```java
// SecurityConfig
.authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/v1/diagnostics/**").permitAll()  // KELL
    .anyRequest().authenticated())
```

### 10.4 IdempotencyFilter blokkolja a stateless POST-okat

**Tünet:** `400 Bad Request: Missing Idempotency-Key header` a `/diagnostics/error-report` POST-on.

**Forrás:** Valutavaltó PR #412.

**Root cause:** A globális `IdempotencyFilter` minden POST-on kötelezővé tette az `Idempotency-Key` header-t. A diagnosztikai endpointok stateless-ek (nincs duplicate-prevention szükség).

**Fix:**
```java
private static final List<String> EXCLUDED_PREFIXES = List.of(
    "/api/v1/auth/",
    "/api/v1/diagnostics/",
    "/api/v1/public/"
);
```

### 10.5 userData `.env` malformált `VITE_API_URL="https://"`

**Tünet:** Penztar.exe induláskor minden API hívás failel `Network Error`-ral, mert a `.env`-ben üres host van.

**Forrás:** Valutavaltó BALI/Helga gépeken (2026-04-18-tól).

**Root cause:** A Setup Wizard 2 hete tárolt egy malformált envet (`VITE_API_URL="https://"`). A régi eltávolítók nem törölték a `%APPDATA%\valuta-penztar`-t.

**Fix (main.ts startup-on):**
```typescript
const apiUrlMatch = rawEnv.match(/^VITE_API_URL\s*=\s*"?([^"\r\n]*)"?\s*$/m)
const currentApiUrl = (apiUrlMatch?.[1] ?? '').trim()
const needsMigration = !currentApiUrl
  || currentApiUrl === 'https://'
  || currentApiUrl === 'http://'
  || /^https?:\/\/?$/.test(currentApiUrl)
if (needsMigration) {
    // overwrite .env-ben az `VITE_API_URL`-t a helyes prod URL-re
}
```

### 10.6 Setup Wizard `bootstrapPassword` mint `currentPassword`

**Tünet:** Setup Wizard 5. lépésnél **"A megadott jelenlegi (seed) jelszo nem egyezik"**.

**Forrás:** Valutavaltó dev gép, 2026-05-05.

**Root cause:** A wizard step 3-ban beírt `bootstrapPassword` (system admin auth) NEM ugyanaz, mint a worker seed-jelszava (V111 default). A wizard mégis ezt küldte `currentPassword`-ként a `/auth/first-time-worker-setup` endpoint-ra → backend WorkerFirstTimeSetupService elutasította.

**Fix (first-run.ts):**
```typescript
// ❌ NE
const workerSetup = await workerFirstTimeSetup(apiUrl, {
    workerCode: ...,
    newPassword: payload.adminPassword,
    currentPassword: payload.bootstrapPassword || undefined,  // BUG
});

// ✅ HASZNÁLD (seed worker first-time-setup nem igényel currentPassword-öt)
const workerSetup = await workerFirstTimeSetup(apiUrl, {
    workerCode: ...,
    newPassword: payload.adminPassword,
    // NE küldd a currentPassword-öt
});
```

### 10.7 axios `timeout: 15000` túl rövid ESET MITM kliensekhez

**Tünet:** "Belépés Google fiókkal" → `timeout of 15000ms exceeded` Borsi gépén.

**Forrás:** Valutavaltó Issue #417, PR #419.

**Root cause:** ESET MITM TLS handshake (~3-5s) + HTTP/1.1 új TLS conn (`--disable-http2` mellett) + Google API roundtrip (~3-5s) + JWT issuance (~1-2s) + Caddy + Tomcat összesen >15s.

**Fix:**
```typescript
// frontend api/client.ts
const AXIOS_GLOBAL_TIMEOUT_MS = 30_000  // NEM 15_000!
```

### 10.8 IPv6 happy-eyeballs hang a Cloudflare AAAA recordon

**Tünet:** Magyar ISP-knél a kliens IPv6-on próbál csatlakozni → timeout, IPv4 fallback késik.

**Forrás:** Valutavaltó Borsi (2026-04-29).

**Root cause:** A Cloudflare AAAA record él, a Chromium happy-eyeballs algoritmus először IPv6-ot próbál. Egyes magyar ISP-knél (Magyar Telekom, Vodafone) az IPv6 routing megszakad → 30s timeout amíg fallback-el IPv4-re.

**Fix (server-side, Cloudflare API):**
```bash
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/settings/ipv6" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -d '{"value":"off"}'
```

VAGY Cloudflare dashboard → Network → IPv6 Compatibility → **Off**.

### 10.9 electron-updater 404 a `latest.yml`-re

**Tünet:** `[autoUpdate] error: Cannot find latest.yml in the latest release artifacts`

**Forrás:** Valutavaltó BALI gépen (v2.3.2 telepítve).

**Root cause:** Az electron-updater a publish.provider GitHub Release-ből próbálja letölteni a `latest.yml`-t. Ha a release-ben nincs feltöltve, 404. (A v2.3.2 release létezik, de a `latest.yml` hiányzik onnan.)

**Fix:**
1. **Manuális latest.yml generálása** a build-installer.ps1-ben (SHA512 + size)
2. **Upload a GitHub Release-be** minden új verzió esetén

VAGY: ha nem akarsz auto-update-et (manuális telepítő-küldés a kollégáknak):
```typescript
// Disable auto-update completely
import { autoUpdater } from 'electron-updater'
autoUpdater.autoDownload = false
autoUpdater.autoInstallOnAppQuit = false
// ne hívd a checkForUpdates() metódust
```

### 10.10 `--disable-http2` + `--host-resolver-rules` Chromium switches

**Forrás:** Valutavaltó Borsi/BALI ESET-tüneti debug.

**Root cause:** Egyes ESET-konfigurációkon a HTTP/2 stream FRAME-eket lassan dolgozza fel. Defensive: HTTP/1.1-re fallback. Plus IPv4-only DNS resolve override a backend domain-re.

**Fix (main.ts, app.whenReady ELŐTT):**
```typescript
app.commandLine.appendSwitch('disable-features', 'EncryptedClientHello')
app.commandLine.appendSwitch('disable-http2')
app.commandLine.appendSwitch('host-resolver-rules',
    'MAP yourapi.example.com 188.114.96.10')
```

### 10.11 Google OAuth Web SDK reject `app://localhost` origin

**Tünet:** Electron-ban a Google Sign-in JS SDK `idpiframe_initialization_failed` errort dob.

**Forrás:** Valutavaltó PR #400, kezdeti Google OAuth implementáció.

**Root cause:** A Google Sign-in `gsi/client` Web SDK csak HTTPS origin-eket fogad el. Az Electron `app://localhost` (custom protocol) nem felel meg.

**Fix:** Electron-ban **ne használd a Web SDK-t**. Helyette:
1. Google Cloud Console → új **Desktop app** OAuth client (külön a Web-től)
2. RFC 8252 Authorization Code Flow + loopback `http://127.0.0.1:RANDOM/callback`
3. PKCE (RFC 7636) + state CSRF
4. Token exchange `electron.net.request`-tel

(Lásd 5.5 szekció)

### 10.12 GitHub Push Protection blokkolja a committed secret-eket

**Tünet:** `git push` `remote: Push declined due to repository rule violations` (secret detected).

**Forrás:** Valutavaltó initial Google OAuth setup.

**Root cause:** A `.env.production` accidentálisan commitolva, a Web client_id + Desktop client_secret a content-be került → GitHub Push Protection elkapja.

**Fix:**
1. **`.gitignore`**:
   ```
   .env
   .env.*
   !.env.example
   ```
2. **`.env.example`** (placeholder-ekkel):
   ```
   VITE_API_URL=https://yourapi.example.com/api/v1
   GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
   GOOGLE_DESKTOP_CLIENT_ID=YOUR_DESKTOP_CLIENT_ID
   ```
3. **build-installer.ps1**: build-time injection a repo `.env` (gitignored) fájlból a stage dir-be:
   ```powershell
   if (Test-Path "$RepoRoot\.env") {
       Copy-Item "$RepoRoot\.env" "$StageDir\client\.env"
   }
   ```

### 10.13 4-way version drift → build gate fail

**Tünet:** `installer\build-installer.ps1` exit 2 — `Version drift detected. Found: 2.5.12, 2.5.18`

**Forrás:** Valutavaltó dev workflow.

**Root cause:** A 4 version-tartó fájl közül csak 3-at frissítettem (3 package.json igen, pom.xml-t elfelejtettem).

**Fix:** **Mindig 4 helyen bumpolj:**
```powershell
npm version X.Y.Z --no-git-tag-version          # root
cd frontend-admin && npm version X.Y.Z --no-git-tag-version
cd ../desktop-client && npm version X.Y.Z --no-git-tag-version
# manuális Edit a backend/pom.xml-ben:
#   <version>X.Y.Z</version>
```

VAGY: készíts egy `bump-version.ps1` szkriptet, amit egy paranccsal hív:
```powershell
# scripts/bump-version.ps1
param([string]$Version)
npm version $Version --no-git-tag-version
Push-Location frontend-admin; npm version $Version --no-git-tag-version; Pop-Location
Push-Location desktop-client; npm version $Version --no-git-tag-version; Pop-Location
(Get-Content backend\pom.xml) -replace '<version>\d+\.\d+\.\d+</version>',"<version>$Version</version>" | Set-Content backend\pom.xml
```

### 10.14 NSIS encoding (Windows-1252 ASCII only)

**Tünet:** `Penztar.exe` indul, de az installer GUI bizonyos szövegei mojibake-elve jelennek meg, vagy az installer crashel az "ő" karakteren.

**Forrás:** Valutavaltó NSIS scripts.

**Root cause:** Az NSIS `.nsi` fájlt Windows-1252-ben parse-olja. UTF-8-ban mentett szöveg (ékezetekkel, em-dash-ekkel) hibás karaktereket eredményez.

**Fix:**
- A `.nsi` fájlt mentsd **Windows-1252** kódolásban (Notepad++ → Encoding → Windows-1252)
- **Sima ASCII** szöveget használj — ékezet helyett alaphang ("kód" → "kod"), em-dash (—) helyett kötőjel (-)
- Magyar lokalizáció (üzenetek): `MUI_LANGUAGE "Hungarian"` — ez beépített, ASCII-ban

### 10.15 Penztar.exe locked during reinstall

**Tünet:** Silent install fails ha az `Penztar.exe` fut, mert a fájl locked.

**Forrás:** Valutavaltó Borsi gépén.

**Root cause:** Windows fájlrendszer nem engedi felülírni egy futó .exe-t (LockedList probléma).

**Fix:**
- NSIS `LockedList` plugin használata (`installer/Penztar-Setup.nsi`):
  ```nsis
  !include "LockedList.nsh"
  Function .onInit
    LockedList::AddProcess "Penztar.exe"
    LockedList::AddProcess "Zalog.exe"
    Pop $R0
    ${If} $R0 != ""
        MessageBox MB_OK "A program fut, kerlek zard be elotte."
        Abort
    ${EndIf}
  FunctionEnd
  ```
- VAGY az installer .onInit-ban `nsExec::Exec 'taskkill /f /im YourApp.exe'`

---

## 11. Bonus: Iparági standard practice-ek (NEM csak a Valutavaltó tanulság)

### 11.1 Continuous Integration kapuk

Minden PR-en:
- ✅ Lint (ESLint + TypeScript strict)
- ✅ Typecheck (`tsc --noEmit`)
- ✅ Test (Vitest / JUnit)
- ✅ Build (mvn package + npm run build)
- ✅ Dependabot (security advisories)
- ✅ CodeQL (SAST)
- ✅ GitLeaks (secret detection)
- ✅ npm audit (high+critical block)

### 11.2 Pre-commit hooks (Husky)

```json
// package.json
"husky": {
  "hooks": {
    "pre-commit": "npm run lint && npm run typecheck",
    "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
  }
}
```

### 11.3 Conventional Commits

```
feat(diagnostics): kliens-oldali hibajelentes endpoint
fix(client): axios timeout 15s -> 30s
chore(deps): bump react 18 -> 19
docs(architecture): error-reporting flow diagram
```

### 11.4 Squash + delete branch on merge (CI auto-clean)

```yaml
# Repository settings:
- Allow squash merging: ON (default merge type)
- Automatically delete head branches: ON
```

### 11.5 Dependabot config

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "maven"
    directory: "/backend"
    schedule:
      interval: "weekly"
  - package-ecosystem: "npm"
    directory: "/frontend-admin"
    schedule:
      interval: "weekly"
  - package-ecosystem: "npm"
    directory: "/desktop-client"
    schedule:
      interval: "weekly"
```

### 11.6 Trivy backend SCA + npm audit

GitHub Actions:
```yaml
- name: Trivy Backend SCA
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: 'backend'
    severity: 'HIGH,CRITICAL'
    exit-code: '1'

- name: npm audit (frontend + desktop)
  run: |
    cd frontend-admin && npm audit --audit-level=high
    cd ../desktop-client && npm audit --audit-level=high
```

### 11.7 Sentry-style error reporting (saját szerveren)

Lásd 7. szekció. Plusz:

- **PII Privacy Guard** a `GitHubIssueAutoCreator`-ban: NE küldd ki az issue body-ban a `userIdentifier`-t (Google email), `client_ip`-t, vagy bármilyen PII-t. SSH-zel az SQL-ből bárki ki tudja kérdezni a backend admin.
- **Anti-spam** a kliens queue-ban: ugyanaz az üzenet 5s-en belül skip.
- **24h dedup signature** a backend-ben: `component+errorMessage[0..80]` hash → ha 24h-ban már volt issue, skip.

### 11.8 Hourly auto-triage routine

Mindenképpen érdemes egy lokális Claude Code scheduled-task (`mcp__scheduled-tasks__create_scheduled_task`) — óránként végigfut az új issue-kon, klasszifikálja, kommentál, ÉS opcionálisan `<20 LOC` fix-et nyit. Lásd 7.7.

### 11.9 4-tier release pipeline

```
Local dev → PR (feature branch) → CI green → merge to main → auto-deploy Hetzner → smoke test → telepito build → Downloads → kollegák
```

---

## 12. Záró checklist — új projekt elindításához

### 12.1 Initial setup (1-2 óra)

- [ ] GitHub repo létrehozása (private, default branch: main)
- [ ] Domain regisztráció + Cloudflare DNS setup (IPv6 OFF!)
- [ ] Hetzner VPS létrehozás (Ubuntu 22.04, 4 vCPU, 16GB RAM minimum)
- [ ] Caddy + Postgres 17 + Java 21 telepítés
- [ ] Google Cloud Console: Web + Desktop OAuth client
- [ ] GitHub Actions secrets setup

### 12.2 Backend skeleton (4-6 óra)

- [ ] Spring Boot 4.0.6 + pom.xml minta (3.2 szekció)
- [ ] application.properties + .env.example (3.3)
- [ ] SecurityConfig + JWT filter (3.4)
- [ ] JacksonConfig (3.5)
- [ ] IdempotencyFilter (3.6)
- [ ] Multi-tenant Entity + Repository pattern (3.7)
- [ ] V1__init.sql migration
- [ ] AuthController (login + Google login + bootstrap-status)
- [ ] DiagnosticsController + ErrorReportDto + ClientErrorLog (7. szekció)
- [ ] GitHubIssueAutoCreator (7.6)

### 12.3 Frontend admin (4-6 óra)

- [ ] Vite + React 19 + TS skeleton
- [ ] api/client.ts (axios timeout 30s, 4.2)
- [ ] Tailwind + Zustand
- [ ] LoginPage Web SDK Google OAuth (4.5)
- [ ] SetupWizard 5-step (4. szekció + 10.6 anti-pattern)
- [ ] Dashboard + business-specific oldalak

### 12.4 Electron desktop (4-6 óra)

- [ ] Electron 33 + electron-builder skeleton
- [ ] main.ts (5.2)
- [ ] preload.ts IPC bridge (5.3)
- [ ] first-run.ts (5.4)
- [ ] google-oauth.ts RFC 8252 (5.5)
- [ ] error-reporter.ts (5.6)
- [ ] sync-engine.ts (offline SQLite, business-specific)

### 12.5 Installer (3-4 óra)

- [ ] NSIS Setup.nsi (9.4)
- [ ] NSIS Cleanup.nsi (9.6)
- [ ] build-installer.ps1 + check-version-bump.ps1 (9.5, 9.2)
- [ ] electron-builder.json (9.7)

### 12.6 Auto error reporting + auto-triage (1-2 óra)

- [ ] Hetzner backend env-be: GITHUB_ISSUE_AUTO_CREATE_TOKEN
- [ ] V_init migration: client_error_log table (VARCHAR(45) IP, JSONB context!)
- [ ] Lokális Claude Code: scheduled-task `error-monitor` cron `13 * * * *`

### 12.7 Smoke test (30 min)

- [ ] Backend deploy → curl `/api/v1/auth/bootstrap-status` → 200
- [ ] Frontend admin: localhost → login Google-lal → dashboard
- [ ] Desktop client: telepítő → Setup Wizard → bejelentkezés → működik
- [ ] Hibajelentés smoke: POST `/api/v1/diagnostics/error-report` → 200 + DB row + GitHub Issue

---

## 13. Hivatkozások

- **Forrás repo:** https://github.com/kosazoltan/valutavalto-program
- **Vault:** `D:\valutavalto-vault\` (Obsidian)
- **Critical PR-ek (példák):**
  - PR #407 — initial diagnostics endpoint (V182, ErrorReportDto, ClientErrorLog)
  - PR #410 — GitHubIssueAutoCreator @Async + 24h dedup
  - PR #411 — SecurityConfig requestMatchers permitAll
  - PR #412 — IdempotencyFilter EXCLUDED_PREFIXES
  - PR #413 — Jackson 3 incompat fix (JsonNode → Map)
  - PR #414 — V183 INET → VARCHAR(45) Hibernate fix
  - PR #419 — axios timeout 15s → 30s + Setup Wizard currentPassword fix
- **Valós kollégai issuek:**
  - #417 — Borsi Network Error timeout 15s
  - #418 — automatikusan eskaláld
- **Iparági standard:**
  - **Sentry:** https://docs.sentry.io/development/integrations/store/
  - **RFC 8252** OAuth 2.0 for Native Apps: https://tools.ietf.org/html/rfc8252
  - **RFC 7636** PKCE: https://tools.ietf.org/html/rfc7636
  - **Spring Boot 4 migration guide:** https://github.com/spring-projects/spring-boot/wiki

---

## 14. Záró megjegyzések

### 14.1 Mit NE csinálj

- ❌ NE használj **Spring Boot 3.5.x**-et — Jackson 2 default, kompatibilis a meglévő import-okkal, DE jövőbeli upgrade nehéz
- ❌ NE használj **React 18 + axios 1.6**-ot — peer-dep skew + CVE-fix követés bonyolult
- ❌ NE bundle-old a **Postgres-t** kis felhasználói körre — túl nagy installer (~280 MB → 60 MB ha THIN-only)
- ❌ NE használj **electron-updater auto-update**-et amíg nincs GitHub Release pipeline-od (10.9)
- ❌ NE küldj parancssoros utasítást a **nem-informatikus kollégáknak** — minden ismétlődő instrukció felesleges, az installer/program oldja meg
- ❌ NE keverj **Web** és **Desktop** Google OAuth client_id-t (10.11)

### 14.2 Mit ÉRDEMES

- ✅ Kezdd a 10. szekciót átolvasva, mielőtt egy sor kódot is írnál
- ✅ A pom.xml + package.json-ekben **rögzítsd a verziókat** (NE `^` vagy `~`-szel) — reproducible build
- ✅ A backend stack: **`spring-boot-jackson2` + JacksonConfig.java + `spring.jackson.use-jackson2-defaults=true`** kombinációt **EGYBŐL** építsd be — később migrálni Jackson 3-ra egy külön sprint
- ✅ A `.env`-ek kezelését **build-time injection-nel** old meg, NE commit-old a secret-eket
- ✅ Auto error-reporting: már a **legelső** release-ben legyen — különben kollégaiad kénytelenek lesznek manuálisan jelezni a hibákat
- ✅ Hourly auto-triage routine: ahogy a backend kész, ezt is állítsd be — proaktív hibafigyelés > reaktív debug

### 14.3 Tovább?

A guide alapján egy ~1-2 hét alatt egy fejlesztő (vagy AI-asszisztens) felhúz egy production-ready ERP-skeleton-t a Valutavaltó tanulságaival. Az üzleti logika (zálogkezelés, ékszer-katalógus) attól függetlenül fejleszthető — az alap stack stabil.

**Sok sikert!**

---

*Készült Claude Code-ban a 2026-05-05-i Valutavaltó session tapasztalatai alapján.*
*Sourcefile: D:\repo\valutavalto-program @ 7ebddb58 + fix/v2.5.19-axios-timeout-and-wizard-current-password.*
