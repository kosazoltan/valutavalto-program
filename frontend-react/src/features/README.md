# Features - Moduláris struktúra

Ez a mappa az új, moduláris funkciókat tartalmazza.

## Struktúra

```
features/
├── reporting/          # Riportok és statisztikák
│   ├── api/           # API hívások (reportingApi.ts)
│   ├── components/    # UI komponensek
│   ├── hooks/         # React Query hooksk
│   └── types/         # TypeScript típusok
├── compliance/         # Megfelelőségi modul (TODO)
└── export/            # Export modul (TODO)
```

## Moduláris átalakítás szabályai

1. **NEM MÓDOSÍTJUK** a meglévő fájlokat:
   - `src/services/api.ts`
   - `src/stores/authStore.ts`

2. **HASZNÁLJUK** a meglévő infrastruktúrát:
   - `useAuthStore` az authentikációhoz
   - Meglévő típusok és util-ok

3. **API verzió**: `/api/v2/` prefix az új végpontokhoz

4. **Naming**: camelCase, angol nevek, magyar kommentek
