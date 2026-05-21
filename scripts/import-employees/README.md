# Dolgozói törzs (employee) import — EBC

A `employee` HR-törzstábla (V53) feltöltése a hivatalos személyi-adat Excelből,
**kizárólag nem-érzékeny mezőkkel** + worker-illesztéssel (pénztárosi kód).

## Alapelv (Kósa Zoltán user-direktíva, 2026-05-21)

A program **szándékosan NEM kezel érzékeny személyes adatot**. Az importból
**KIMARAD**: TAJ-szám, adóazonosító, anyja születési neve, születési hely/dátum,
személyi igazolvány szám, lakcímek (állandó/levelezési/ideiglenes), bankszámla,
SZÉP-kártya, bér, adókedvezmények, nyugdíj, végzettség.

**BEKERÜL** (operatívan szükséges): szervezeti egység (munkahely), vezeték- és
keresztnév, FEOR, munkakör, jogviszony kezdete/megnevezése/vége, `is_active`.

Az `employee` tábla érzékeny oszlopai (tax_id, social_security_number,
id_card_number, mothers_name, stb.) **NULL-ok maradnak** — sosem töltjük fel.

## PII / git szabály

- A **generált SQL és a worker-export NEM commitolható** (neveket + munkaköröket
  tartalmaz). A `.gitignore` kizárja: `import_work/`, `scripts/import-employees/*.sql`.
- Csak ez a generátor-script + README kerül a repóba (PII-mentes tooling).

## Használat

```bash
# 1. Worker-export a production-ból (id|code|name) a név-illesztéshez:
ssh -i ~/.ssh/hetzner_ed25519 root@<HETZNER_IP> \
  "sudo -u postgres psql -d valuta -At -F'|' -c \
   \"SELECT id, code, name FROM worker WHERE is_active=true \
     AND company_id=(SELECT id FROM company WHERE code='EBC') ORDER BY name;\"" \
  > import_work/prod_workers.txt

# 2. SQL generálás (csak nem-érzékeny mezők, worker-linkkel):
python scripts/import-employees/generate_employee_import.py \
  "<szemelyi_adatok.xls>" import_work/prod_workers.txt import_work/employee_import.sql

# 3. Futtatás a production-ön (root olvassa, postgres stdin-en kapja — /root perm-fix):
scp -i ~/.ssh/hetzner_ed25519 import_work/employee_import.sql root@<IP>:/root/
ssh -i ~/.ssh/hetzner_ed25519 root@<IP> \
  "cat /root/employee_import.sql | sudo -u postgres psql -d valuta -v ON_ERROR_STOP=1; \
   shred -u /root/employee_import.sql"
```

A generált SQL tranzakcionális (BEGIN/COMMIT), idempotens (előbb DELETE az EBC-re,
majd INSERT), és a végén kiírja az `imported` + `linked` darabszámot.

## Worker-illesztés

Normalizált teljes-név egyezés (`Vezetéknév + Keresztnév` ↔ `worker.name`),
ékezet-érzéketlen. Alias-térkép a hivatalos↔rövid névkülönbségekre (pl.
"Borossebesiné Bali Henriett Anita" → "Bali Henrietta"). A nem-illeszthető
dolgozók `worker_id=NULL`-lal kerülnek be (léteznek HR-ben, de nincs belépő-fiók).

## ⚠️ Séma-drift megjegyzés

A V53 migráció `active` oszlopot definiál, a live prod-séma viszont `is_active`-ot
használ (JPA `active` mező → `is_active` oszlop, Hibernate naming). Az import a
**live sémához** igazodik (`is_active`). A V53-forrás és a prod-séma eltérése
külön rendezendő (nem ennek az importnak a scope-ja).

## Utolsó import — 2026-05-21

- **196 dolgozó** importálva (a 207 soros Excelből, ahol van vezeték+keresztnév).
- **193 worker-linkelt**, 3 linkeletlen (nincs aktív worker-fiókjuk).
- Munkakör-eloszlás: Valutapénztáros 128, Értékszállító 22, Értéktáros 10,
  Hivatalsegéd 4, Területi vezető 3, Főértéktáros 2, + egyedi vezetői munkakörök.
- 8 terület (Békéscsaba, Debrecen, Kaposvár, Kecskemét, Nyíregyháza, Pécs, Szeged,
  Szekszárd) + Iroda.
