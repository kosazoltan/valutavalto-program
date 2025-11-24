# Valuta Flutter Alkalmazás

Ez a dokumentum a Valuta Flutter alkalmazás Windows platformra történő telepítési és futtatási útmutatója.

## Rendszerkövetelmények

- Windows operációs rendszer

## Futtatás

Az alkalmazás indításához futtassa a `valuta.exe` fájlt. A program a futtatásához szükséges minden függőséget tartalmaz a mappában.

## Konfiguráció

A backend szerver elérhetőségét a `data/flutter_assets/assets/cfg/production_windows.json` fájlban lehet beállítani.

Nyissa meg a fájlt egy szövegszerkesztővel, és módosítsa a `baseUrl` paraméter értékét a megfelelő backend címre.

**Példa `production_windows.json` tartalom:**

```json
{
    "baseUrl": "https://backend.pelda.hu",
    "apiBaseUrl": "/api"
}
```
