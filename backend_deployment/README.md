# PuzzleIR Rendszer Dokumentáció

Ez a dokumentum a PuzzleIR rendszer telepítési, futtatási és üzemeltetési útmutatója. A rendszer Docker konténerekben fut, és Docker Compose segítségével van orchestrálva.
Valamint a Valuta alkalmazás PostgreSQL adatbázisának várható erőforrásigényét becsüli meg 2 éves időtávra, napi 6-7 ezer tranzakcióval számolva. A becslés a `valuta_data.sql` szkriptben definiált adatbázis séma alapján készült.

## Adatbázis Erőforrásigény Becslés és Javaslat

### Tárhelyigény Becslése (2 évre)

- **Napi tranzakciók száma:** 7 000
- **Egy tranzakció becsült mérete (tranzakció, ügyfél, és kapcsolódó tételek):** ~700-800 bájt
- **Napi adatnövekedés:** 7 000 tranzakció/nap * 800 bájt/tranzakció ≈ 5.6 MB/nap
- **Éves adatnövekedés:** 5.6 MB/nap * 365 nap ≈ 2 GB/év
- **Két éves adatnövekedés:** 2 GB/év * 2 év = 4 GB

Ehhez hozzáadódik az indexek, a rendszer táblák, a naplófájlok és az adatbázis belső működéséből adódó overhead, ami a teljes adatméret 100-150%-a is lehet.

**Javasolt tárhely 2 évre: 25-30 GB**

Ez egy biztonságos becslés, ami elegendő teret hagy a nem várt növekedésnek és a rendszeres karbantartási feladatoknak is.

### Felhő Infrastruktúra Javaslat

A megbízható és skálázható működés érdekében javasolt menedzselt adatbázis szolgáltatást (pl. Amazon RDS for PostgreSQL, Google Cloud SQL for PostgreSQL, vagy Azure Database for PostgreSQL) igénybe venni.

#### Javasolt Kiinduló Konfiguráció

- **Adatbázis Motor:** PostgreSQL 16 vagy újabb.
- **Példány (Instance) Típus:**
    - **CPU:** 2 vCPU
    - **Memória:** 8 GB RAM
    - Ez a konfiguráció egy általános célú, burstable (terhelés függvényében skálázódó) példánytípusnak felel meg a legtöbb felhő szolgáltatónál (pl. AWS `db.t3.medium` vagy `db.t4g.medium`, Google Cloud `db-n1-standard-2`).
- **Tárhely:**
    - **Méret:** Kezdeti 50 GB, ami kényelmesen fedezi a becsült 2 éves növekedést és puffert is biztosít.
    - **Típus:** Általános célú SSD (General Purpose SSD, pl. `gp2` vagy `gp3` AWS-en). Ez a legtöbb esetben optimális ár/érték arányt nyújt.
    - **Automatikus skálázás (Autoscaling):** Javasolt bekapcsolni, hogy a tárhely automatikusan növekedhessen, ha eléri a beállított küszöbértéket.

#### Mentés és Magas Rendelkezésre Állás

- **Automatikus mentések:** Mindenképpen javasolt a napi automatikus mentések beállítása, legalább 7-14 napos megőrzési idővel.
- **Magas rendelkezésre állás (Multi-AZ):** Kiemelten fontos üzletkritikus alkalmazás esetén a Multi-AZ (több rendelkezésre állási zóna) opció bekapcsolása. Ez biztosítja, hogy egy esetleges adatközpont hiba esetén az adatbázis egy másik zónában automatikusan újrainduljon, minimalizálva ezzel a leállási időt.

### Összefoglalás

Egy menedzselt PostgreSQL szolgáltatás a fentebb vázolt kiinduló konfigurációval stabil és költséghatékony alapot biztosít az alkalmazás számára. A felhő platformok monitorozó eszközeivel folyamatosan figyelemmel kell kísérni az adatbázis terheltségét (CPU, memória, I/O), és szükség esetén a példány méretét vagy a tárhely típusát a valós használatnak megfelelően kell módosítani.

## Architektúra

A rendszer a következő fő komponensekből áll, melyek a `puzzleir.yml` fájlban vannak definiálva:

-   `puzzleir-api`: A központi backend alkalmazásszerver.
    -   **Port**: A hoszton a `${PUZZLEIR_API_PORT}` környezeti változóban megadott porton érhető el (alapértelmezetten 8183), ami a konténer 8081-es portjára van irányítva.
    -   **Logok**: A log fájlok a `${PUZZLEIR_API_LOG}` által meghatározott könyvtárba kerülnek a hoszton.
    -   **Függőség**: A `puzzleir-postgres` szolgáltatástól függ.

-   `puzzleir-ngx`: Egy Nginx-alapú reverse proxy vagy frontend szerver.
    -   **Port**: A hoszton a `${PUZZLEIR_NGX_PORT}` környezeti változóban megadott porton érhető el (alapértelmezetten 8182), ami a konténer 8081-es portjára van irányítva.
    -   **Függőség**: A `puzzleir-api` szolgáltatástól függ.

-   `puzzleir-postgres`: A PostGIS-kiterjesztéssel ellátott PostgreSQL adatbázisszerver.
    -   **Port**: A hoszton az `5432`-es porton érhető el.
    -   **Adattárolás**: Az adatbázis fájljai a `${PGSQL_DATA}` által meghatározott könyvtárban tárolódnak a hoszton, így a konténer újraindítása után is megmaradnak.
    -   **Secretek**: Az adatbázis jelszava a `deploy/postgres/secrets/postgres-passwd.txt` fájlból van csatolva a konténerbe.

### Hálózat

A szolgáltatások egy `pgnetwork` nevű bridge hálózaton kommunikálnak egymással, amely egy dedikált alhálózattal (`172.24.240.0/24`) rendelkezik.

## Előfeltételek

A rendszer futtatásához a következő szoftverekre van szükség:

-   [Docker](https://www.docker.com/get-started)
-   [Docker Compose](https://docs.docker.com/compose/install/)

## Telepítés

1.  **Klónozza a repository-t**: Szerezze be a projekt forráskódját.
2.  **Konfiguráció**: A `deployment` mappában található `puzzleir.env` fájlban állítsa be a környezeti változókat. Ezekkel a változókkal szabható testre a telepítés (pl. portok, adatbázis beállítások).

## Használat

A `deployment` mappában található szkriptek segítségével vezérelhető a környezet. A szkriptek elérhetőek Windows (`.cmd`) és Linux/macOS (`.sh`) rendszerekre is.

-   **Image-ek építése**:
    ```bash
    puzzleir-build.sh
    ```
    vagy
    ```batch
    puzzleir-build.cmd
    ```
    Ez a parancs újraépíti a Docker image-eket a `puzzleir.yml` fájlban definiált `build` kontextusok alapján, a cache használata nélkül (`--no-cache`).

-   **Környezet indítása (előtérben)**:
    ```bash
    puzzleir-up.sh
    ```
    vagy
    ```batch
    puzzleir-up.cmd
    ```
    Elindítja a konténereket. A logok a terminálban fognak megjelenni. A leállításhoz használja a `Ctrl+C` kombinációt.

-   **Környezet indítása (háttérben)**:
    ```bash
    puzzleir-daemon.sh
    ```
    vagy
    ```batch
    puzzleir-daemon.cmd
    ```
    Elindítja a konténereket a háttérben (`-d` kapcsoló).

-   **Környezet leállítása**:
    ```bash
    puzzleir-down.sh
    ```
    vagy
    ```batch
    puzzleir-down.cmd
    ```
    Leállítja és eltávolítja a konténereket, hálózatokat.

## Adatbázis inicializálása

A `deployment/pgsql/valuta_data.sql` szkript tartalmazza az adatbázis struktúrájának és alap adatainak létrehozásához szükséges parancsokat. A szkript futtatásához a Docker konténernek már futnia kell.

A szkriptet a következő parancsokkal lehet futtatni a `deployment` mappából.

### Linux/macOS

```bash
cat pgsql/valuta_data.sql | docker exec -i puzzleir-postgres psql -U postgres -d xxxxxxxx
```

### Windows

```batch
cd deployment
type pgsql\valuta_data.sql | docker exec -i puzzleir-postgres psql -U postgres -d xxxxxxxx
```

**Fontos:** A parancsok feltételezik, hogy a `puzzleir-postgres` konténer fut. Az adatbázis neve (`xxxxxxxx`) és a felhasználónév (`postgres`) a `puzzleir.env` fájlban lévő `POSTGRES_DEFAULT_DATABASE` és `DATASOURCE_USERNAME` változókkal vannak meghatározva.

## Konfiguráció (`puzzleir.env`)

A rendszer viselkedése a `puzzleir.env` fájlban található környezeti változókkal szabható testre:

-   `POSTGRES_PORT`: Az adatbázis külső portja (alapértelmezetten: `5432`).
-   `POSTGRES_DEFAULT_DATABASE`: Az alapértelmezett adatbázis neve.
-   `PGSQL_DATA`: Az adatbázis adatfájljainak helye a hoszton (pl. `./runtime/pg_data`).
-   `DATASOURCE_USERNAME`: Az adatbázishoz csatlakozó felhasználónév.
-   `DATASOURCE_PASSWORD`: A `DATASOURCE_USERNAME` felhasználó jelszava.
-   `DATASOURCE_URL`: A JDBC kapcsolódási URL.
-   `PUZZLEIR_API_PORT`: A backend API külső portja (alapértelmezetten: `8183`).
-   `PUZZLEIR_API_LOG`: A backend API log fájljainak helye a hoszton (pl. `./runtime/logs`).
-   `PUZZLEIR_NGX_PORT`: A frontend/proxy külső portja (alapértelmezetten: `8182`).
-   `IMAP_ENABLED`: IMAP funkcionalitás engedélyezése.
-   `IMAPJOB_ENABLED`: IMAP-alapú időzített feladat engedélyezése.
