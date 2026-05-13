# Valutaváltó — Deploy Utasítások

## Backend (Render)

### 1. Render Dashboard → New → Web Service
- **Repository:** `kosazoltan/valutavalto-program`
- **Branch:** `main`
- **Root Directory:** `backend`
- **Runtime:** Docker
- **Region:** Frankfurt
- **Plan:** Free (vagy Starter)

### 2. Környezeti változók (Environment Variables)

```
PORT=8080
SPRING_PROFILES_ACTIVE=production
JDBC_DATABASE_URL=jdbc:postgresql://<db-host>/<db-name>?sslmode=require&user=<db-user>&password=<DATABASE_PASSWORD_FROM_SECRET_STORE>
JWT_SECRET=<GENERATE_32_PLUS_CHAR_RANDOM_SECRET>
JWT_EXPIRATION=86400000
CORS_ALLOWED_ORIGINS=http://localhost:5173,https://valutavalto.vercel.app
LOG_LEVEL=INFO
```

Ha a korabbi konkret JDBC/JWT pelda valaha eles kornyezetben is hasznalva volt,
azonnal rotalni kell a titkot, majd kotelezo redeploy es verifikacio kovetkezik.

### 3. Health Check Path
```
/actuator/health
```

## Frontend (Vercel)

### 1. Vercel Dashboard → New Project
- **Repository:** `kosazoltan/valutavalto-program`
- **Framework:** Vite
- **Root Directory:** `frontend-react`

### 2. Környezeti változók
```
VITE_API_URL=https://[render-service-name].onrender.com/api/v1
```

### 3. Build
```
npm run build
```

## Neon Database

- **Project:** Valutavalto (`orange-rice-31690230`)
- **Region:** aws-eu-central-1 (Frankfurt)
- **Host:** ep-polished-morning-altxohe7.c-3.eu-central-1.aws.neon.tech
- **Database:** neondb
- **User:** neondb_owner

## Test Login
```
POST /api/v1/auth/login
{
  "companyCode": "EBC",
  "workerCode": "ADMIN",
  "password": "admin123"
}
```
