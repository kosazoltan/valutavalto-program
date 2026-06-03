# Modul: Munkavállaló-nyilvántartás (dolgozói törzs)

<system_context>
## Rendszerkontextus és Cél
A munkavállalói (dolgozói) törzs teljes adatlapját, füleit és kísérő adatait rögzíteni. A célrendszer egységesíti a régi Expressz Zálog (rózsaszín UI) és Rate Software (zöld UI) rendszerek adatait, különválasztva a bejelentkezéshez szükséges technikai adatokat (`worker`) és a részletes munkaügyi/HR törzsadatokat (`employee`), támogatva az offline kliens oldali hitelesítést is.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Adminisztrátor | Dolgozók CRUD, jogosultságok kezelése | ADMIN |
| Ügyvezető | Munkaügyi adatok, béradatok, státusz szerkesztése | EXECUTIVE |
| Főértéktáros / Helyettes | Beosztott dolgozók megtekintése/szerkesztése | HEAD_VAULT_KEEPER |
| Belső ellenőr | Olvasás, compliance ellenőrzés (bizonyítványok, üzemorvosi vizsgálatok) | INTERNAL_AUDITOR |
| Pénztáros / Értéktáros | Saját profil megtekintése | CASHIER / VAULT_KEEPER |

## Hatókör (Scope)
### IN
- Dolgozók személyi adatai (nevek, anyja neve, születési hely/idő, állampolgárságok).
- Igazoló okmányok és szakmai bizonyítványok (Becsüs, Eladói, Valutapénztárosi bizonyítvány).
- Elérhetőségek (e-mail, telefon) és bankszámla adatok.
- Munkaügyi adatok (fiók hozzáférések, beosztások, jogviszony tartama, FEOR kódok).
- Szabadság nyilvántartás évenként (áthozott, betegszabadság, kivett napok, táppénz).
- Üzemorvosi vizsgálat (állapot, határidő, dátum, eredmény, megkötések).
- Gyerekek nyilvántartása.
- SQLite szinkronizáció bejelentkezési és jogosultság adatokhoz offline mód támogatására.

### OUT
- Dolgozói bérszámfejtés és NAV adóbevallás generálás (a rendszer csak a törzsadatokat tárolja, az elszámolás külső szoftverben történik).

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-01 | A kötelező mezők vizuális jelölése | Kitöltetlen kötelező mező esetén a mentés gomb tiltott, hibaüzenet jelenik meg |
| NFR-02 | A jelszó mező maszkolása | Jelszó plain textként nem jelenik meg, adatbázisban csak hashelve (BCrypt) tárolható |
| NFR-03 | Táblázatos adatok kezelése | Keresés, szűrés, lapozás és CSV/Excel export funkciók az üzemorvosi és szabadság táblázatokon |
</system_context>

<functional_spec>
## Funkcionális Követelmények

### FR-01 Egységesített Dolgozói Adatlap
- **Leírás**: A rendszer a zöld rendszer füles elrendezését követve egyetlen adatlapba vonja össze a személyi, munkaügyi és HR adatokat (Képesítések, Címek, Folyószámlák, Üzemorvosi v., Táppénz, Szabadságok, Gyerekek).
- **Forrás**: Rate Software képernyőképek, `V53__employee_hr_module.sql`
- **Prio**: M
- **Csomag/Komponens**: frontend-react, backend

### FR-02 Felhasználói Bejelentkezési Adatok (Worker)
- **Leírás**: A dolgozókhoz társított bejelentkezési adatok kezelése: egyedi felhasználói kód (code, pl. P001), név, biztonságos BCrypt jelszó-hash, szerepkör (CASHIER, SUPERVISOR, MANAGER, ADMIN), alapértelmezett iroda (branch_id), aktív státusz.
- **Forrás**: `V2__create_worker_tables.sql`
- **Prio**: M
- **Csomag/Komponens**: backend, frontend
- **Validációk és Kényszerek**: A kódnak a cégen belül egyedinek kell lennie (`uk_worker_company_code`).

### FR-03 Szakmai Bizonyítványok és Képesítések
- **Leírás**: Becsüs, Eladói és Valutapénztárosi szakmai bizonyítványok számának és érvényességének rögzítése külön checkboxokkal és dátumokkal.
- **Forrás**: Bizonyítvány számok.png, `employee` tábla mezői
- **Prio**: M
- **Csomag/Komponens**: frontend-react, backend

### FR-04 Szabadságok és Betegszabadságok Kezelése
- **Leírás**: Évenkénti bontásban rögzíthető szabadság táblázat: áthozott, alapszabadság, betegszabadság, kivett szabadságok, táppénzes napok és fizetés nélküli szabadságok.
- **Forrás**: Szabadságok, Gyerekek.png, `employee_vacation` tábla
- **Prio**: M
- **Csomag/Komponens**: frontend-react, backend
- **Validációk és Kényszerek**: Évenként csak egy sor rögzíthető dolgozónként (`uq_employee_vacation_year`).

### FR-05 Üzemorvosi Vizsgálatok Nyilvántartása
- **Leírás**: Az üzemorvosi vizsgálatok rögzítése: vizsgálat állapota ("Lezárt", "Folyamatban"), határidő, vizsgálat dátuma, eredménye ("Alkalmas", "Korlátozással alkalmas", "Nem alkalmas"), és esetleges orvosi megkötések szöveges leírása.
- **Forrás**: Üzemorvosi vizsgálat.png, `employee_occupational_health` tábla
- **Prio**: M
- **Csomag/Komponens**: frontend-react, backend

### FR-06 Offline Hitelesítés Támogatása
- **Leírás**: A kliensprogram (penztar-client) offline üzemmódot is támogat. A dolgozó offline módban is be tud lépni a kasszába, és a rendszer a helyi SQLite-ban tárolt jogosultságait veszi figyelembe a napi zárások elvégzéséhez.
- **Szabály**: A `worker` és a jogosultság-táblák szinkronizálódnak az SQLite lokális adatbázisba. A részletes HR adatok (címek, szabadságok, gyerekek, üzemorvosi adatok) nem tükröződnek az SQLite-ba, azok csak online módban érhetőek el a Postgres szerverről.
- **Prio**: M
- **Csomag/Komponens**: penztar-client, backend

### FR-07: Kétlépcsős Google OAuth belépés (személyes bejelentkezés)
- **Leírás**: A megosztott/intézményi Google fiókokkal történő bejelentkezésnél (pl. `szeged.ebc@gmail.com` e-mail cím, ami a `G_SZEGED_ET` technikai workerhez van rendelve) a rendszernek kétlépcsős bejelentkezési folyamatot kell kikényszerítenie:
  - 1. lépés: Sikeres Google OAuth hitelesítés.
  - 2. lépés: A rendszer lekéri a Google fiókhoz tartozó iroda/értéktár (`branchId`) aktív személyes dolgozóinak listáját (a `Worker` táblából), majd a felhasználó kiválasztja saját magát és megadja a személyes jelszavát.
  - A személyes jelszót a backend a `Worker.passwordHash` alapján BCrypt-tel ellenőrzi. 5 sikertelen jelszó-próbálkozás után a személyes dolgozó fiókját 15 percre le kell tiltani (in-memory lockout).
  - Sikeres hitelesítés után a végleges alkalmazás-JWT session a személyes dolgozó azonosítójával (`workerId`), jogosultságával (`ertektar` vagy `penztar` role) és saját nevével jön létre az auditálhatóság érdekében.
- **Forrás**: 2026-06-02 Google OAuth audit
- **Prio**: Magas (P0)
- **Csomag/Komponens**: backend / penztar-client

### FR-08: Személyi Értéktári Dolgozók Felvétele (helyi végpont)
- **Leírás**: Biztosítani kell az `ERTEKTAR` szerepkörű bejelentkezett felhasználók (értéktárosok) számára, hogy új személyes munkatársakat regisztrálhassanak a saját értéktáruk (branch) alá egy szűkített, dedikált backend végponton keresztül:
  - Végpont: `POST /api/v1/vault-workers`.
  - A kérés tartalmazza a dolgozó nevét, jelszavát és a jelszó megerősítését. A jelszóból a backend BCrypt hash-t generál, a company és branch azonosítókat pedig automatikusan a bejelentkezett felhasználó SecurityContext-jéből származtatja.
  - A regisztrált új dolgozóhoz automatikusan hozzá kell rendelni az `ertektar` canonical role assignmentet. A `googleLoginEnabled` flag alapértelmezetten `false` értékkel jön létre.
- **Forrás**: 2026-06-02 Google OAuth audit
- **Prio**: Magas (P1)
- **Csomag/Komponens**: backend / frontend-react
</functional_spec>

<data_structure>
## Jelenlegi Postgres Adatmodell Mappings

- `worker` (Technikai bejelentkezési adatok):
  - `id` (bigserial primary key)
  - `company_id` (uuid REFERENCES company)
  - `code` (varchar(10)) -- Pénztáros kód (pl. P001), company-n belül egyedi
  - `name` (varchar(100)) -- Pénztáros név
  - `password_hash` (varchar(255)) -- BCrypt jelszó hash
  - `role` (varchar(20)) -- CASHIER, SUPERVISOR, MANAGER, ADMIN
  - `branch_id` (uuid REFERENCES branch) -- Alapértelmezett iroda
  - `active` (boolean) -- Aktív/Inaktív státusz
- `employee` (Munkaügyi és személyi HR adatok):
  - `id` (bigserial primary key)
  - `company_id` (uuid REFERENCES company)
  - `worker_id` (bigint REFERENCES worker) -- Opcionális kapcsolat a bejelentkezéshez
  - `last_name` (varchar(100))
  - `first_name` (varchar(100))
  - `birth_last_name` (varchar(100))
  - `birth_first_name` (varchar(100))
  - `tax_id` (varchar(20)) -- Adóazonosító
  - `social_security_number` (varchar(20)) -- TAJ szám
  - `mothers_name` (varchar(150)) -- Anyja neve
  - `birth_date` (date)
  - `birth_place` (varchar(100))
  - `citizenship` (varchar(100))
  - `id_card_number` (varchar(30))
  - `id_card_expiry` (date)
  - `email` (varchar(200))
  - `phone` (varchar(30))
  - `employment_start_date` (date)
  - `employment_end_date` (date)
  - `feor_code` (varchar(10))
  - `job_title` (varchar(200))
  - `salary_type` (varchar(5)) -- 'HB' (havibér) / 'OB' (órabér)
  - `salary_amount` (numeric(12,2))
  - `payment_method` (varchar(5)) -- 'B' (banki) / 'K' (készpénz)
  - `vocational_qualification` (varchar(300)) -- Valutapénztárosi/Becsüs szakképesítés megnevezése
  - `certificate_date` (date)
- `employee_address` (Dolgozó lakcímei):
  - `id` (bigserial primary key)
  - `employee_id` (bigint REFERENCES employee ON DELETE CASCADE)
  - `address_type` (varchar(20)) -- 'PERMANENT', 'MAILING', 'TEMPORARY'
  - `postal_code` (varchar(10))
  - `city` (varchar(100))
  - `street_name` (varchar(200))
  - `street_type` (varchar(50)) -- utca, út, tér, krt.
  - `house_number` (varchar(20))
- `employee_bank_account` (Dolgozó bankszámlái):
  - `id` (bigserial primary key)
  - `employee_id` (bigint REFERENCES employee ON DELETE CASCADE)
  - `account_type` (varchar(20)) -- 'SALARY' (bérszámla), 'SZEP_CARD'
  - `account_number` (varchar(50))
- `employee_occupational_health` (Üzemorvosi vizsgálatok):
  - `id` (bigserial primary key)
  - `employee_id` (bigint REFERENCES employee ON DELETE CASCADE)
  - `status` (varchar(50)) -- 'Lezárt', 'Folyamatban'
  - `deadline_date` (date)
  - `exam_date` (date)
  - `result` (varchar(100)) -- 'Alkalmas', 'Nem alkalmas'
  - `restriction` (varchar(500))
- `employee_vacation` (Szabadságok):
  - `id` (bigserial primary key)
  - `employee_id` (bigint REFERENCES employee ON DELETE CASCADE)
  - `year` (integer)
  - `brought_forward` (integer) -- Áthozott szabadság napok
  - `vacation_days` (integer) -- Éves szabadság napok
  - `sick_leave_days` (integer) -- Betegszabadság napok
  - `taken_vacation` (integer) -- Kivett szabadság napok
  - `taken_sick_leave` (integer)
  - `sick_pay_days` (integer) -- Táppénz napok
  - `unpaid_leave_days` (integer)
- `employee_child` (Gyermekek):
  - `id` (bigserial primary key)
  - `employee_id` (bigint REFERENCES employee ON DELETE CASCADE)
  - `name` (varchar(200))
  - `birth_date` (date)

SQLite mirror támogatás: **IGEN**, a `worker` és `worker_role` táblák SQLite-ban szinkronizálva vannak. A HR al-táblák (`employee_*`) kizárólag a Postgres szerveren érhetőek el.
</data_structure>

<integration_points>
## Integrációs Pontok és API-k
- **Dolgozó Kezelő API**:
  - `POST /api/employees`: Új dolgozó rögzítése és a kapcsolódó 1:N táblák tranzakciós mentése.
  - `GET /api/employees/{id}`: Teljes HR adatlap lekérdezése füles struktúrához.
  - `GET /api/employees/medical-checks`: Üzemorvosi vizsgálatok szűrése és exportálása.
- **Offline hitelesítés**: A `penztar-client` az offline indítás során a helyi SQLite `worker` táblában ellenőrzi a megadott jelszó-hasht (BCrypt) és a jogosultságokat.
</integration_points>

<execution_workflow>
## Végrehajtási Folyamat
1. **Dolgozó felvétele**: Az adminisztrátor kitölti az adatlapot. A mentés gomb megnyomásakor a backend egyetlen tranzakció keretében elmenti a `worker` (ha van bejelentkezés) és `employee` rekordot, valamint a kapcsolódó címeket, bankszámlákat és gyermekeket.
2. **Kassza bejelentkezés**: Bejelentkezéskor a kliens ellenőrzi a helyi SQLite-ban a jogosultságot, és ha nincs visszaigazolatlan körlevél, engedélyezi a munkát.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | Melyik forrásrendszer elrendezése a mérvadó a célrendszerben? | UI dizájn | **RESOLVED**: A célrendszer a zöld ("Rate Software") rendszer füles felosztását és elrendezését követi egyetlen egyesített dolgozói adatlapon. |
| 2 | Mik a pontos legördülő értékek a listáknál? | Validáció és adattárolás | **RESOLVED**: `citizenship` = ISO kódok, `salary_type` = HB/OB, `payment_method` = B/K, `address_type` = PERMANENT/MAILING/TEMPORARY, `account_type` = SALARY/SZEP_CARD. |
| 3 | Mely mezők kötelezőek pontosan a célrendszerben? | Validációs logika | **RESOLVED**: `employee` esetén `last_name`, `first_name`, `company_id`. `worker` esetén `code` (egyedi), `name`, `password_hash`, `role`, `branch_id`. |
| 4 | Szükséges-e a dolgozói törzs SQLite offline tükrözése? | Offline elérés | **RESOLVED**: Igen, de kizárólag a `worker` és a jogosultság-táblák tükröződnek offline bejelentkezéshez. A részletes HR adatok (szabadság, vizsgálatok stb.) nem. |
| 5 | A "Felhasználói megjegyzések", "Kapcsolatok", "Autók", "Folyószámlák" fülek tartalma? | Specifikáció teljessége | **RESOLVED**: A folyószámlák az `employee_bank_account` táblába, a kapcsolatok az `employee` phone/email mezőibe kerülnek. Az autók és egyéb megjegyzések metaadatként vannak tárolva. |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva.
- [x] Nincsenek kitalált vagy hallucinált követelmények (minden mező és táblanév a Postgres SQL migrációk alapján pontosan verifikálva).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=6 db, TBD=5 db, érintett csomagok=backend, frontend-react, penztar-client.
</verification_checklist>
