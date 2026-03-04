# Valutavalto Deployment - Vercel + Render

## Osszefoglalo

| Komponens | Platform | URL |
|-----------|----------|-----|
| Frontend (React) | Vercel | https://valutavalto.vercel.app |
| Backend (Spring Boot) | Render | https://valuta-backend.onrender.com |
| Database (PostgreSQL) | Render | Meglevo: dpg-d4i5v675r7bs73c8qqe0-a |

---

## 1. Backend Deployment (Render)

### 1.1 Uj Web Service letrehozasa

1. Menj a [Render Dashboard](https://dashboard.render.com)-ra
2. Kattints: **New** -> **Web Service**
3. Csatlakoztasd a GitHub repot: `valutavalto-program`
4. Beallitasok:
   - **Name**: `valuta-backend`
   - **Region**: Frankfurt (EU Central)
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: Docker
   - **Plan**: Free (vagy Starter $7/ho)

### 1.2 Kornyezeti valtozok (Render Dashboard)

Allitsd be ezeket a **Environment** tabfulon:

```
DATABASE_URL=<Render Dashboard-rol masold>
SPRING_PROFILES_ACTIVE=production
JWT_SECRET=<generalj 64 karakteres random stringet>
JWT_EXPIRATION=86400
ADMIN_INITIAL_PASSWORD=<valassz eros jelszot>
PORT=8080
CORS_ALLOWED_ORIGINS=https://excvaluta.com,https://www.excvaluta.com
LOG_LEVEL=INFO
```

### 1.3 Spring Boot application.properties frissites

Ellenorizd, hogy a `backend/src/main/resources/application.properties` tartalmazza:

```properties
# Production - Render
spring.datasource.url=${DATABASE_URL}
server.port=${PORT:8080}

# CORS
cors.allowed-origins=${CORS_ALLOWED_ORIGINS:http://localhost:3000}
```

---

## 2. Frontend Deployment (Vercel)

### 2.1 Vercel projekt letrehozasa

1. Menj a [Vercel Dashboard](https://vercel.com/dashboard)-ra
2. Kattints: **Add New** -> **Project**
3. Importald a GitHub repot: `valutavalto-program`
4. Beallitasok:
   - **Framework Preset**: Vite
   - **Root Directory**: `frontend-react`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`

### 2.2 Kornyezeti valtozok (Vercel Dashboard)

Settings -> Environment Variables:

```
VITE_API_URL=https://valuta-backend.onrender.com/api/v1
```

### 2.3 Domain beallitas (opcionalis)

Settings -> Domains -> Add Domain:
- `valuta.yourdomain.com`

---

## 3. Blueprint Deployment (Alternativa)

A `render.yaml` fajl hasznalataval automatikus deployment:

1. Render Dashboard -> **New** -> **Blueprint**
2. Valaszd a `valutavalto-program` repot
3. Render automatikusan felismeri a `render.yaml`-t
4. Allitsd be a `DATABASE_URL`-t manualisak (sync: false)
5. Kattints **Apply**

---

## 4. CI/CD Automatikus Deployment

### GitHub Actions (opcionalis)

Mindket platform automatikusan deployol push-ra:
- **Vercel**: Automatikus preview URL minden PR-hez
- **Render**: Automatikus redeploy main branch-re

---

## 5. Ellenorzes

### Backend (Render)
```bash
curl https://valuta-backend.onrender.com/actuator/health
# Elvart: {"status":"UP"}

curl https://valuta-backend.onrender.com/swagger-ui.html
# Elvart: Swagger UI oldal
```

### Frontend (Vercel)
```bash
curl -I https://valutavalto.vercel.app
# Elvart: HTTP/2 200
```

---

## 6. Hibaelharitas

### Render backend nem indul
1. Ellenorizd a Logs tabfult a Render Dashboard-on
2. Ellenorizd a DATABASE_URL-t (Internal vs External URL)
3. Ellenorizd a Docker build logokat

### Vercel frontend 404
1. Ellenorizd a Build Logs-t
2. Ellenorizd a vercel.json rewrites beallitast
3. Ellenorizd a VITE_API_URL kornyezeti valtozot

### CORS hiba
1. Ellenorizd a CORS_ALLOWED_ORIGINS-t a backend-en
2. Ellenorizd, hogy a Vercel domain szerepel-e benne

---

## 7. Koltsegek

| Platform | Plan | Korlatok | Ar |
|----------|------|----------|-----|
| Render Free | Web Service | 750 ora/ho, spin down 15 perc utan | $0 |
| Render Starter | Web Service | Mindig fut, 512MB RAM | $7/ho |
| Render Free | PostgreSQL | 1GB, 90 nap utan torlodik | $0 |
| Render Starter | PostgreSQL | 1GB, nem torlodik | $7/ho |
| Vercel Hobby | Frontend | 100GB bandwidth | $0 |
| Vercel Pro | Frontend | Unlimited | $20/ho |

### Ajanlott production setup:
- Backend: Render Starter ($7/ho)
- Database: Render Starter PostgreSQL ($7/ho)
- Frontend: Vercel Hobby ($0)
- **Osszesen: $14/ho**
