# Valutaváltó Backend - Spring Boot API

## 📋 Áttekintés

Spring Boot 3.2.5 + Java 21 alapú REST API a valutaváltó rendszerhez.

### Jelenlegi Implementáció: Branch (Értéktár) Modul

✅ **Kész komponensek:**
- Entity-k: Branch, Company, Dictionary
- Repository-k: JPA repók rekurzív query támogatással
- Service: Teljes üzleti logika + validációk
- Controller: REST API endpoint-ok
- DTO-k: Create, Update, Response
- Exception handling: Global handler
- Mapper: Entity ↔ DTO konverzió

## 🚀 Gyors Indítás

### Előfeltételek

- Java 21 JDK
- Maven 3.9+
- PostgreSQL 16 (Render vagy lokális)

### Futtatás

```bash
# Projekt gyökér
cd backend

# Dependency-k letöltése
mvn clean install

# Alkalmazás indítás
mvn spring-boot:run

# Vagy JAR build + futtatás
mvn clean package
java -jar target/valuta-backend-1.0.0-SNAPSHOT.jar
```

### Környezeti Változók

```bash
# PostgreSQL connection
DATABASE_URL=jdbc:postgresql://dpg-xxx.frankfurt-postgres.render.com/valuta_production
DATABASE_USERNAME=valuta_user
DATABASE_PASSWORD=your_password

# Server port (alapértelmezett: 8080)
SERVER_PORT=8080
```

## 📡 API Endpoint-ok

### Branch (Értéktár) API

**Base URL:** `http://localhost:8080/api/v1/branches`

#### GET Műveletek

```http
GET /api/v1/branches
Query params: 
  - type: KOZPONT | FOERTEKTAR | ERTEKTAR | PENZTAR
  - status: ACTIVE | INACTIVE | CLOSED
  - search: keresési kifejezés
  - activeOnly: true | false

GET /api/v1/branches/roots
# Gyökér fiókok (nincs szülő)

GET /api/v1/branches/{id}
# Egy fiók ID alapján

GET /api/v1/branches/code/{code}
# Egy fiók kód alapján

GET /api/v1/branches/{id}/children
# Közvetlen gyermekek

GET /api/v1/branches/{id}/path
# Útvonal a gyökérig (breadcrumb)
```

#### POST/PUT/DELETE Műveletek

```http
POST /api/v1/branches
Content-Type: application/json
Body: CreateBranchDto

PUT /api/v1/branches/{id}
Content-Type: application/json
Body: UpdateBranchDto

DELETE /api/v1/branches/{id}
# Soft delete (isActive = false)
```

### Példa Request: Új Fiók Létrehozása

```json
POST /api/v1/branches
{
  "code": "E001",
  "companyId": "01940841-da54-7dee-a346-b2610943e988",
  "bankCode": "E001",
  "branchTypeId": "0196de8d-3334-7bee-be4b-7e87f7c2755a",
  "parentBranchId": "0196de8d-3e4e-76e8-b389-ae47e12f21f9",
  "name": "Budapest Értéktár",
  "address": "Váci út 1-3.",
  "city": "Budapest",
  "zipCode": "1062",
  "countryId": "019406fa-d0ab-74cf-9334-c56ea0357188",
  "phone": "+36 1 234 5678",
  "email": "budapest@ertektar.hu",
  "branchStatusId": "0196e7ba-06d1-735a-9158-b3fb88c0e9bf",
  "openingDate": "2025-01-01"
}
```

### Példa Response

```json
{
  "id": "0199xxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "code": "E001",
  "name": "Budapest Értéktár",
  "companyId": "01940841-da54-7dee-a346-b2610943e988",
  "companyName": "PuzzleIR Kft.",
  "branchTypeId": "0196de8d-3334-7bee-be4b-7e87f7c2755a",
  "branchTypeCode": "ERTEKTAR",
  "branchTypeName": "Értéktár",
  "parentBranchId": "0196de8d-3e4e-76e8-b389-ae47e12f21f9",
  "parentBranchName": "Országos Főértéktár",
  "address": "Váci út 1-3.",
  "city": "Budapest",
  "zipCode": "1062",
  "countryId": "019406fa-d0ab-74cf-9334-c56ea0357188",
  "countryName": "Magyarország",
  "phone": "+36 1 234 5678",
  "email": "budapest@ertektar.hu",
  "branchStatusId": "0196e7ba-06d1-735a-9158-b3fb88c0e9bf",
  "branchStatusCode": "ACTIVE",
  "branchStatusName": "Aktív",
  "bankCode": "E001",
  "openingDate": "2025-01-01",
  "isActive": true,
  "createdAt": "2025-12-15T12:34:56",
  "updatedAt": "2025-12-15T12:34:56",
  "childBranchIds": []
}
```

## 🏗️ Projekt Struktúra

```
backend/src/main/java/com/puzzleir/backend/
├── ValutaBackendApplication.java     # Main class
├── config/
│   └── SecurityConfig.java           # Spring Security config
├── controller/
│   └── BranchController.java         # REST endpoints
├── service/
│   └── BranchService.java            # Üzleti logika
├── repository/
│   ├── BranchRepository.java         # JPA repó
│   ├── CompanyRepository.java
│   └── DictionaryRepository.java
├── entity/
│   ├── Branch.java                   # JPA entity
│   ├── Company.java
│   └── Dictionary.java
├── dto/
│   ├── BranchDto.java                # Response DTO
│   ├── CreateBranchDto.java          # Create request
│   └── UpdateBranchDto.java          # Update request
├── mapper/
│   └── BranchMapper.java             # Entity ↔ DTO
└── exception/
    ├── GlobalExceptionHandler.java   # REST exception handler
    ├── ResourceNotFoundException.java
    ├── ValidationException.java
    └── ErrorResponse.java
```

## 🔐 Hierarchia Validációk

A `BranchService` automatikusan ellenőrzi a hierarchia szabályokat:

### Típus Hierarchia Szabályok

| Típus | Kód | Szülő Típus | Szabály |
|-------|-----|-------------|---------|
| Központ | KOZPONT | - | Nincs szülő (NULL) |
| Fő Értéktár | FOERTEKTAR | KOZPONT | Csak központ alá |
| Értéktár | ERTEKTAR | KOZPONT vagy FOERTEKTAR | Központ vagy főértéktár alá |
| Pénztár | PENZTAR | ERTEKTAR | Csak értéktár alá |

### Példa Validációs Hibák

```json
// 400 Bad Request
{
  "timestamp": "2025-12-15T12:34:56",
  "status": 400,
  "error": "Bad Request",
  "message": "Pénztár csak értéktár alá helyezhető"
}

// 404 Not Found
{
  "timestamp": "2025-12-15T12:34:56",
  "status": 404,
  "error": "Not Found",
  "message": "Fiók nem található: 0199xxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

## 🧪 Tesztelés

### cURL Példák

```bash
# Összes fiók
curl -X GET http://localhost:8080/api/v1/branches

# Csak értéktárak
curl -X GET http://localhost:8080/api/v1/branches?type=ERTEKTAR

# Keresés
curl -X GET http://localhost:8080/api/v1/branches?search=budapest

# Egy fiók lekérése
curl -X GET http://localhost:8080/api/v1/branches/{id}

# Új fiók létrehozása
curl -X POST http://localhost:8080/api/v1/branches \
  -H "Content-Type: application/json" \
  -d @create-branch.json

# Fiók frissítése
curl -X PUT http://localhost:8080/api/v1/branches/{id} \
  -H "Content-Type: application/json" \
  -d '{"name": "Új Név", "phone": "+36 1 999 8888"}'

# Fiók törlése
curl -X DELETE http://localhost:8080/api/v1/branches/{id}
```

### Postman Collection

TODO: Postman collection export

## 📊 Adatbázis Kapcsolat

Az alkalmazás a `database/schema/valuta_schema.sql` alapján működik.

**Fontos táblák:**
- `branch` - Szervezeti egységek
- `dictionary` - Kódtárak (típusok, státuszok)
- `company` - Cégek

**Dictionary kategóriák:**
- `BRANCH_TYPE`: KOZPONT, FOERTEKTAR, ERTEKTAR, PENZTAR
- `BRANCH_STATUS`: ACTIVE, INACTIVE, CLOSED
- `COUNTRY`: Országok

## 🚧 Következő Fejlesztések

### Fázis 2: Hierarchia Lekérdezések (1 hét)
- [ ] Tree endpoint: teljes fa struktúra
- [ ] Descendants endpoint: rekurzív leszármazottak
- [ ] Circular reference check áthelyezésnél

### Fázis 3: Státusz Kezelés (1 hét)
- [ ] Aktiválás endpoint + feltételek
- [ ] Inaktiválás endpoint
- [ ] Bezárás workflow

### Fázis 4: Audit Log (1 hét)
- [ ] Változásnapló tábla
- [ ] Audit endpoint-ok
- [ ] Automatikus naplózás

### Fázis 5: Nyitvatartás (1 hét)
- [ ] OpeningHours entity + CRUD
- [ ] Naptár lekérdezések
- [ ] Template kezelés

## 📝 Megjegyzések

- **Security:** Jelenleg minden endpoint nyitott (permitAll). Később JWT auth.
- **Validation:** Jakarta Validation használata (@NotBlank, @Email, stb.)
- **Soft Delete:** A DELETE művelet csak isActive = false-ra állítja
- **Audit:** JPA Auditing (@CreatedDate, @LastModifiedDate)
- **CORS:** Engedélyezett frontend origin: localhost:5173, localhost:3000

## 🐛 Hibakezelés

Minden validációs és runtime hiba JSON formátumban kerül visszaadásra:

```json
{
  "timestamp": "2025-12-15T12:34:56",
  "status": 400,
  "error": "Validation Failed",
  "message": "Validációs hiba",
  "errors": {
    "code": "A kód megadása kötelező",
    "name": "A név 3-255 karakter hosszú lehet"
  }
}
```

---

**Verzió:** 1.0.0-SNAPSHOT  
**Utolsó frissítés:** 2025-12-15  
**Készítette:** Implementációs Terv alapján
