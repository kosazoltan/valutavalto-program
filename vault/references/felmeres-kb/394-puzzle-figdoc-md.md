---
title: puzzle.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/puzzle.figdoc.md
doc_type: text
---

# puzzle.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 45.4 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/puzzle.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

### FIGDEF# agreed_work_schedule

```yaml
    label: Munkaidő egyeztetés
    pluralLabel: Munkaidő egyeztetések
    type: TABLE
```

| Field               | Label                 | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK        |
|---------------------|-----------------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------|-----------|
| id                  | Id                    | IDENT    |      |          |          |        |           |             |       |         |           | 
| worker_id           | Dolgozó               | FKIDENT  |      |          |          |        |           |             | TABLE | worker  | worker.id | 
| valid_from_date     | Érvényes-től          | DATE     |      |          | X        |        |           |             |       |         |           | 
| valid_to_date       | Érvényes-ig           | DATE     |      |          | X        |        |           |             |       |         |           | 
| work_section_length | Munkaszakasz hossza   | SMALLINT | 5    |          | X        |        |           |             |       |         |           | 
| rest_section_length | Pihenő szakasz hossza | SMALLINT | 5    |          | X        |        |           |             |       |         |           | 

---

### FIGDEF# agreed_work_schedule_ext

```yaml
    label: Munkaidő egyeztetés
    pluralLabel: Munkaidő egyeztetések
    type: EXTEND
    parent: agreed_work_schedule
```

| Field  | Label   | Type   | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK               | Replacement |
|--------|---------|--------|------|----------|----------|--------|-----------|-------------|-----|---------|------------------|-------------|
| worker | Dolgozó | Worker |      |          |          |        |           |             | DTO | worker  | person.last_name | worker_id   |

---

### FIGDEF# assigned_role

```yaml
    label: Hozzárendelt szerep
    pluralLabel: Hozzárendelt szerepek
    type: TABLE
```

| Field            | Label                 | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK       |
|------------------|-----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|----------|
| id               | Id                    | IDENT   |      |          |          |        |           |             |       |         |          | 
| ruser_id         | Felhasználó           | FKIDENT |      |          |          |        |           |             | TABLE | ruser   | ruser.id | 
| creator_ruser_id | Létrehozó felhasználó | FKIDENT |      |          |          |        |           |             | TABLE | ruser   | ruser.id | 
| role_id          | Felhasználói csoport  | FKIDENT |      |          |          |        |           |             | TABLE | role    | role.id  | 

---

### FIGDEF# car

```yaml
    label: Gépjármű
    pluralLabel: Gépjárművek
    type: TABLE
```

| Field                | Label        | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|----------------------|--------------|----------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id                   | Id           | IDENT    |      |          |          |        |           |             |    |         |    | 
| license_plate_number | Rendszám     | VARCHAR  | 32   |          |          |        |           |             |    |         |    | 
| country_did          | Ország       | DICT     |      |          |          |        |           |             |    | COUNTRY |    | 
| chassis_number       | Alvázszám    | VARCHAR  | 64   |          | X        |        |           |             |    |         |    | 
| motor_number         | Motorszám    | VARCHAR  | 64   |          | X        |        |           |             |    |         |    | 
| seats_number         | Ülések száma | SMALLINT | 5    |          |          |        |           |             |    |         |    | 
| make                 | Gyártmány    | VARCHAR  | 256  |          | X        |        |           |             |    |         |    | 
| fuel                 | Üzemanyag    | VARCHAR  | 64   |          | X        |        |           |             |    |         |    | 

---

### FIGDEF# car_ext

```yaml
    label: Gépjármű
    pluralLabel: Gépjárművek
    type: EXTEND
    parent: car
```

| Field   | Label  | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign | FK          | Replacement |
|---------|--------|------------|------|----------|----------|--------|-----------|-------------|------|---------|-------------|-------------|
| country | Ország | Dictionary |      |          |          |        |           |             | DICT | COUNTRY | description | country_did |

---

### FIGDEF# category

```yaml
    label: Kategória
    pluralLabel: Kategóriák
    type: TABLE
```

| Field              | Label             | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign        | FK |
|--------------------|-------------------|---------|------|----------|----------|--------|-----------|-------------|----|----------------|----|
| id                 | Id                | IDENT   |      |          |          |        |           |             |    |                |    | 
| category_group_did | Kategória csoport | DICT    |      |          |          |        |           |             |    | CATEGORY_GROUP |    | 
| category           | Kategória         | VARCHAR | 256  |          |          |        |           |             |    |                |    | 

---

### FIGDEF# category_ext

```yaml
    label: Kategória
    pluralLabel: Kategóriák
    type: EXTEND
    parent: category
```

| Field          | Label             | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign        | FK          | Replacement        |
|----------------|-------------------|------------|------|----------|----------|--------|-----------|-------------|------|----------------|-------------|--------------------|
| category_group | Kategória csoport | Dictionary |      |          |          |        |           |             | DICT | CATEGORY_GROUP | description | category_group_did |

---

### FIGDEF# elementary_right

```yaml
    label: Elemi jog
    pluralLabel: Elemi jogok
    type: TABLE
```

| Field                | Label                           | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|----------------------|---------------------------------|---------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id                   | Id                              | IDENT   |      |          |          |        |           |             |    |         |    | 
| name                 | Név                             | VARCHAR | 128  |          |          |        |           |             |    |         |    | 
| description          | Leírás                          | VARCHAR | 2048 |          | X        |        |           |             |    |         |    | 
| only_locally         | Csak helybeni                   | BOOL    |      |          | X        |        |           |             |    |         |    | 
| external_user_issued | Külső felhasználó által kiadott | BOOL    |      |          | X        |        |           |             |    |         |    | 

---

### FIGDEF# elementary_right_parameter_type

```yaml
    label: Elemi jog paraméter típus
    pluralLabel: Elemi jog paraméter típusok
    type: TABLE
```

| Field               | Label         | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign          | FK                  |
|---------------------|---------------|---------|------|----------|----------|--------|-----------|-------------|-------|------------------|---------------------|
| id                  | Id            | IDENT   |      |          |          |        |           |             |       |                  |                     | 
| elementary_right_id | Elemi jog     | FKIDENT |      |          |          |        |           |             | TABLE | elementary_right | elementary_right.id | 
| right_parameter_did | Jog paraméter | DICT    |      |          |          |        |           |             |       | RIGHT_PARAMETER  |                     | 

---

### FIGDEF# hall

```yaml
    label: Csarnok
    pluralLabel: Csarnokok
    type: TABLE
```

| Field   | Label     | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK      |
|---------|-----------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|---------|
| id      | Id        | IDENT   |      |          |          |        |           |             |       |         |         | 
| site_id | Telephely | FKIDENT |      |          |          |        |           |             | TABLE | site    | site.id | 
| name    | Név       | VARCHAR | 256  |          |          |        |           |             |       |         |         | 

---

### FIGDEF# medical_exam

```yaml
    label: Orvosi vizsgálat
    pluralLabel: Orvosi vizsgálatok
    type: TABLE
```

| Field                   | Label                      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign             | FK        | Hide |
|-------------------------|----------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------------|-----------|------|
| id                      | Id                         | IDENT   |      |          |          |        |           |             |       |                     |           |      |
| worker_id               | Dolgozó                    | FKIDENT |      |          |          |        |           |             | TABLE | worker              | worker.id | X    |
| medical_exam_status_did | Orvosi vizsgálat állapota  | DICT    |      |          |          |        |           |             |       | MEDICAL_EXAM_STATUS |           |      |
| deadline_date           | Határidő dátuma            | DATE    |      |          |          |        |           |             |       |                     |           |      |
| examination_date        | Vizsgálat dátuma           | DATE    |      |          | X        |        |           |             |       |                     |           |      |
| medical_exam_result_did | Orvosi vizsgálat eredménye | DICT    |      |          | X        |        |           |             |       | MEDICAL_EXAM_RESULT |           |      |
| restriction             | Megkötés                   | VARCHAR | 256  |          | X        |        |           |             |       |                     |           |      |

---

### FIGDEF# medical_exam_ext

```yaml
    label: Orvosi vizsgálat
    pluralLabel: Orvosi vizsgálatok
    type: EXTEND
    parent: medical_exam
```

| Field                  | Label                         | Type                          | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                        | FK          | Replacement             | Hide |
|------------------------|-------------------------------|-------------------------------|------|----------|----------|--------|-----------|-------------|--------|--------------------------------|-------------|-------------------------|------|
| medical_exam_status    | Orvosi vizsgálat állapota     | Dictionary                    |      |          |          |        |           |             | DICT   | MEDICAL_EXAM_STATUS            | description | medical_exam_status_did |      |
| medical_exam_result    | Orvosi vizsgálat eredménye    | Dictionary                    |      |          |          |        |           |             | DICT   | MEDICAL_EXAM_RESULT            | description | medical_exam_result_did |      |
| medical_exam_documents | Orvosi vizsgálat dokumentumok | List<MedicalExamDocumentExt?> |      |          |          |        |           |             | EXTEND | list:medical_exam_document_ext |             |                         | X    |

---

### FIGDEF# medical_exam_document

```yaml
    label: Orvosi vizsgálat dokumentuma
    pluralLabel: Orvosi vizsgálat dokumentumok
    type: TABLE
```

| Field           | Label            | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign      | FK              |
|-----------------|------------------|---------|------|----------|----------|--------|-----------|-------------|-------|--------------|-----------------|
| id              | Id               | IDENT   |      |          |          |        |           |             |       |              |                 | 
| medical_exam_id | Orvosi vizsgálat | FKIDENT |      |          |          |        |           |             | TABLE | medical_exam | medical_exam.id | 
| document_id     | Dokumentum       | FKIDENT |      |          |          |        |           |             | TABLE | document     | document.id     | 

---

### FIGDEF# medical_exam_document_ext

```yaml
    label: Orvos vizsgálat dokumentuma
    pluralLabel: Orvos vizsgálat dokumentumai
    type: EXTEND
    parent: medical_exam_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

---

### FIGDEF# menu

```yaml
    label: Menü
    pluralLabel: Menük
    type: TABLE
```

| Field          | Label    | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK      |
|----------------|----------|----------|------|----------|----------|--------|-----------|-------------|----|---------|---------|
| id             | Id       | IDENT    |      |          |          |        |           |             |    |         |         | 
| superior       | Felettes | VARCHAR  | 32   |          | X        |        |           |             |    |         | menu.id | 
| superscription | Felirat  | VARCHAR  | 128  |          | X        |        |           |             |    |         |         | 
| help           | Segítség | VARCHAR  | 2048 |          | X        |        |           |             |    |         |         | 
| status         | Állapot  | VARCHAR  | 32   |          |          |        |           |             |    |         |         | 
| seq            | Sorrend  | SMALLINT | 5    |          | X        |        |           |             |    |         |         | 
| path           | Útvonal  | VARCHAR  | 2048 |          | X        |        |           |             |    |         |         | 

---

### FIGDEF# menu_access_right

```yaml
    label: Menü hozzáférési jog
    pluralLabel: Menü hozzáférési jogok
    type: TABLE
```

| Field               | Label     | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign          | FK                  |
|---------------------|-----------|---------|------|----------|----------|--------|-----------|-------------|-------|------------------|---------------------|
| id                  | Id        | IDENT   |      |          |          |        |           |             |       |                  |                     | 
| elementary_right_id | Elemi jog | FKIDENT |      |          |          |        |           |             | TABLE | elementary_right | elementary_right.id | 
| menu_id             | Menü      | FKIDENT |      |          |          |        |           |             | TABLE | menu             | menu.id             | 

---

### FIGDEF# own_contact

```yaml
    label: Saját kapcsolat
    pluralLabel: Saját kapcsolatok
    type: TABLE
```

| Field           | Label        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         | Hide |
|-----------------|--------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|------|
| id              | Id           | IDENT   |      |          |          |        |           |             |       |         |            |      |
| partner_id      | Partner      | FKIDENT |      |          |          |        |           |             | TABLE | partner | partner.id | X    |
| worker_id       | Dolgozó      | FKIDENT |      |          |          |        |           |             | TABLE | worker  | worker.id  |      |
| valid_from_date | Érvényes-től | DATE    |      |          | X        |        |           |             |       |         |            |      |
| valid_to_date   | Érvényes-ig  | DATE    |      |          | X        |        |           |             |       |         |            |      |

---

### FIGDEF# own_contact_ext

```yaml
    label: Saját kapcsolat
    pluralLabel: Saját kapcsolatok
    type: EXTEND
    parent: own_contact
```

| Field  | Label   | Type      | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign    | FK               | Replacement |
|--------|---------|-----------|------|----------|----------|--------|-----------|-------------|--------|------------|------------------|-------------|
| worker | Dolgozó | WorkerExt |      |          |          |        |           |             | EXTEND | worker_ext | person.last_name | worker_id   |

---

### FIGDEF# password_log

```yaml
    label: Jelszó napló
    pluralLabel: Jelszó logok
    type: TABLE
```

| Field        | Label       | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK       |
|--------------|-------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|----------|
| id           | Id          | IDENT   |      |          |          |        |           |             |       |         |          | 
| ruser_id     | Felhasználó | FKIDENT |      |          | X        |        |           |             | TABLE | ruser   | ruser.id | 
| old_password | Régi jelszó | VARCHAR | 2048 |          | X        |        |           |             |       |         |          | 

---

### FIGDEF# position_necessary_right

```yaml
    label: Pozíció szükséges jog
    pluralLabel: Pozíció szükséges jogok
    type: TABLE
```

| Field        | Label                | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK      |
|--------------|----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|---------|
| id           | Id                   | IDENT   |      |          |          |        |           |             |       |          |         | 
| role_id      | Felhasználói csoport | FKIDENT |      |          |          |        |           |             | TABLE | role     | role.id | 
| position_did | Beosztás             | DICT    |      |          |          |        |           |             |       | POSITION |         | 

---

### FIGDEF# position_right_parameter

```yaml
    label: Pozíció jog paraméter
    pluralLabel: Pozíció jog paraméterek
    type: TABLE
```

| Field               | Label                | Type    | Size  | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                               |
|---------------------|----------------------|---------|-------|----------|----------|--------|-----------|-------------|-------|-----------------|----------------------------------|
| id                  | Id                   | IDENT   |       |          |          |        |           |             |       |                 |                                  | 
| role_id             | Felhasználói csoport | FKIDENT |       |          |          |        |           |             | TABLE | role            | position_necessary_right.role_id | 
| position_did        | Beosztás             | DICT    |       |          |          |        |           |             |       | POSITION        |                                  | 
| right_parameter_did | Jog paraméter        | DICT    |       |          |          |        |           |             |       | RIGHT_PARAMETER |                                  | 
| parameter_value     | Paraméter érték      | TEXT    | 65535 |          | X        |        |           |             |       |                 |                                  | 
| valid_from          | Érvényes-től         | DATE    |       |          | X        |        |           |             |       |                 |                                  | 
| valid_to            | Érvényes-ig          | DATE    |       |          | X        |        |           |             |       |                 |                                  | 

---

### FIGDEF# role

```yaml
    label: Felhasználói csoport
    pluralLabel: Felhasználói csoportok
    type: TABLE
```

| Field       | Label       | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK | Hide |
|-------------|-------------|---------|------|----------|----------|--------|-----------|-------------|----|---------|----|------|
| id          | Id          | IDENT   |      |          |          |        |           |             |    |         |    |      |
| name        | Név         | VARCHAR | 128  |          |          |        |           |             |    |         |    |      |
| description | Leírás      | VARCHAR | 2048 |          | X        |        |           |             |    |         |    |      |
| searchkey   | Keresőkulcs | VARCHAR | 2048 |          | X        |        |           |             |    |         |    | X    |

---

### FIGDEF# role_figdef

```yaml
    label: Felhasználói csoport-adatcsoport
    pluralLabel: Felhasználói csoport-adatcsoportok
    type: TABLE
```

| Field     | Label                | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK        |
|-----------|----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|-----------|
| id        | Id                   | IDENT   |      |          |          |        |           |             |       |         |           | 
| role_id   | Felhasználói csoport | FKIDENT |      |          |          |        |           |             | TABLE | role    | role.id   | 
| figdef_id | Adatcsoport          | FKIDENT |      |          |          |        |           |             | TABLE | figdef  | figdef.id | 
| canview   | Megtekintheti        | BOOL    |      |          | X        |        |           |             |       |         |           | 
| canedit   | Szerkesztheti        | BOOL    |      |          | X        |        |           |             |       |         |           | 

---

### FIGDEF# role_figdef_ext

```yaml
    label: Felhasználói csoport-adatcsoport
    pluralLabel: Felhasználói csoport-adatcsoportok
    type: EXTEND
    parent: role_figdef
```

| Field  | Label                | Type   | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|--------|----------------------|--------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| role   | Felhasználói csoport | Role   |      |          |          |        |           |             | DTO | role    | name | role_id     |
| figdef | Adatcsoport          | Figdef |      |          |          |        |           |             | DTO | figdef  | name | figdef_id   |

---

### FIGDEF# role_right

```yaml
    label: Felhasználói csoport joga
    pluralLabel: Felhasználói csoport jogai
    type: TABLE
```

| Field               | Label                | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign          | FK                  |
|---------------------|----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|------------------|---------------------|
| id                  | Id                   | IDENT   |      |          |          |        |           |             |       |                  |                     | 
| role_id             | Felhasználói csoport | FKIDENT |      |          |          |        |           |             | TABLE | role             | role.id             | 
| elementary_right_id | Elemi jog            | FKIDENT |      |          |          |        |           |             | TABLE | elementary_right | elementary_right.id | 

---

### FIGDEF# ruser

```yaml
    label: Felhasználó
    pluralLabel: Felhasználók
    type: TABLE
```

| Field                  | Label                      | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description                        | FT    | Foreign | FK         | Hide | SubType |
|------------------------|----------------------------|----------|------|----------|----------|--------|-----------|------------------------------------|-------|---------|------------|------|---------|
| id                     | Id                         | IDENT    |      |          |          |        |           |                                    |       |         |            |      |         |
| user_name              | Felhasználó név            | VARCHAR  | 256  |          |          |        |           |                                    |       |         |            |      |         |
| worker_id              | Dolgozó                    | FKIDENT  |      |          | X        |        |           |                                    | TABLE | worker  | worker.id  |      |         |
| partner_id             | Partner                    | FKIDENT  |      |          | X        |        |           |                                    | TABLE | partner | partner.id | X    |         |
| last_name              | Vezetéknév                 | VARCHAR  | 128  |          | X        |        |           |                                    |       |         |            |      |         |
| first_name             | Keresztnév                 | VARCHAR  | 128  |          | X        |        |           |                                    |       |         |            |      |         |
| password_hash          | Jelszó hash                | VARCHAR  | 2048 |          |          |        |           | Tárolt jelszó hash                 |       |         |            | X    |         |
| password_reset_token   | Jelszó visszaállító        | VARCHAR  | 100  |          | X        |        |           | Jelszó visszaállító token          |       |         |            | X    |         |
| password_reset_expires | Visszaállító lejárat       | DATETIME |      |          | X        |        |           | Visszaállító token lejárati ideje  |       |         |            | X    |         |
| last_password_change   | Utolsó jelszóváltozás      | DATETIME |      |          | X        |        |           | Utolsó jelszóváltoztatás időpontja |       |         |            |      |         |
| email                  | E-mail                     | VARCHAR  | 256  |          |          |        |           |                                    |       |         |            |      | EMAIL   |
| user_enabled           | Felhasználó engedélyezve   | BOOL     |      |          |          |        |           |                                    |       |         |            |      |         |
| must_change_pwd        | Kötelező jelszóváltoztatás | BOOL     |      |          |          |        |           |                                    |       |         |            |      |         |

---

### FIGDEF# ruser_ext

```yaml
    label: Felhasználó
    pluralLabel: Felhasználók
    type: EXTEND
    parent: ruser
```

| Field  | Label   | Type      | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign    | FK               | Replacement |
|--------|---------|-----------|------|----------|----------|--------|-----------|-------------|--------|------------|------------------|-------------|
| worker | Dolgozó | WorkerExt |      |          |          |        |           |             | EXTEND | worker_ext | person.last_name | worker_id   |

---

### FIGDEF# ruser_role

```yaml
    label: Felhasználói jogosultság
    pluralLabel: Felhasználói jogosultságok
    type: TABLE
```

| Field    | Label                | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK       |
|----------|----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|----------|
| id       | Id                   | IDENT   |      |          |          |        |           |             |       |         |          | 
| ruser_id | Felhasználó          | FKIDENT |      |          |          |        |           |             | TABLE | ruser   | ruser.id | 
| role_id  | Felhasználói csoport | FKIDENT |      |          |          |        |           |             | TABLE | role    | role.id  | 

---

### FIGDEF# ruser_role_ext

```yaml
    label: Felhasználói jogosultság
    pluralLabel: Felhasználói jogosultságok
    type: EXTEND
    parent: ruser_role
```

| Field | Label                | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK        | Replacement |
|-------|----------------------|-------|------|----------|----------|--------|-----------|-------------|-----|---------|-----------|-------------|
| ruser | Felhasználó          | Ruser |      |          |          |        |           |             | DTO | ruser   | user_name | ruser_id    |
| role  | Felhasználói csoport | Role  |      |          |          |        |           |             | DTO | role    | name      | role_id     |

---

### FIGDEF# sick_pay_period

```yaml
    label: Táppénz időszak
    pluralLabel: Táppénz időszakok
    type: TABLE
```

| Field       | Label    | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK        | Hide |
|-------------|----------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|-----------|------|
| id          | Id       | IDENT   |      |          |          |        |           |             |       |         |           |      |
| worker_id   | Dolgozó  | FKIDENT |      |          |          |        |           |             | TABLE | worker  | worker.id | X    |
| from_date   | Dátumtól | DATE    |      |          |          |        |           |             |       |         |           |      |
| to_date     | Dátumig  | DATE    |      |          | X        |        |           |             |       |         |           |      |
| status_did  | Állapot  | DICT    |      |          |          |        |           |             |       | STATUS  |           |      |
| reason_did  | Indok    | DICT    |      |          | X        |        |           |             |       | REASON  |           |      |
| description | Leírás   | VARCHAR | 2048 |          |          |        |           |             |       |         |           |      |

---

### FIGDEF# sick_pay_period_ext

```yaml
    label: Táppénz időszak
    pluralLabel: Táppénz időszakok
    type: EXTEND
    parent: sick_pay_period
```

| Field                     | Label        | Type                            | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                           | FK          | Replacement |
|---------------------------|--------------|---------------------------------|------|----------|----------|--------|-----------|-------------|--------|-----------------------------------|-------------|-------------|
| status                    | Állapot      | Dictionary                      |      |          |          |        |           |             | DICT   | STATUS                            | description | status_did  |
| reason                    | Indok        | Dictionary                      |      |          |          |        |           |             | DICT   | REASON                            | description | reason_did  |
| sick_pay_period_documents | Dokumentumok | List<SickPayPeriodDocumentExt?> |      |          |          |        |           |             | EXTEND | list:sick_pay_period_document_ext |             |             |

---

### FIGDEF# sick_pay_period_document

```yaml
    label: Táppénz időszak dokumentuma
    pluralLabel: Táppénz időszak dokumentumok
    type: TABLE
```

| Field              | Label           | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                 |
|--------------------|-----------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|--------------------|
| id                 | Id              | IDENT   |      |          |          |        |           |             |       |                 |                    | 
| sick_pay_period_id | Táppénz időszak | FKIDENT |      |          |          |        |           |             | TABLE | sick_pay_period | sick_pay_period.id | 
| document_id        | Dokumentum      | FKIDENT |      |          |          |        |           |             | TABLE | document        | document.id        | 

---

### FIGDEF# sick_pay_period_document_ext

```yaml
    label: Táppénz időszak dokumentuma
    pluralLabel: Táppénz időszak dokumentumai
    type: EXTEND
    parent: sick_pay_period_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

---

### FIGDEF# site

```yaml
    label: Telephely
    pluralLabel: Telephelyek
    type: TABLE
```

| Field           | Label         | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         | Hide |
|-----------------|---------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|------|
| id              | Id            | IDENT   |      |          |          |        |           |             |       |         |            |      |
| partner_id      | Partner       | FKIDENT |      |          |          |        |           |             | TABLE | partner | partner.id |      |
| name            | Név           | VARCHAR | 256  |          |          |        |           |             |       |         |            |      |
| valid_from_date | Érvényes-től  | DATE    |      |          | X        |        |           |             |       |         |            |      |
| valid_to_date   | Érvényes-ig   | DATE    |      |          |          |        |           |             |       |         |            |      |
| note            | Megjegyzés    | VARCHAR | 2048 |          | X        |        |           |             |       |         |            |      |
| country_did     | Ország        | DICT    |      |          |          |        |           |             |       | COUNTRY |            |      |
| zip_code        | Irányítószám  | VARCHAR | 10   |          |          |        |           |             |       |         |            |      |
| settlement      | Település     | VARCHAR | 128  |          |          |        |           |             |       |         |            |      |
| street_house    | Utca, házszám | VARCHAR | 512  |          |          |        |           |             |       |         |            |      |

---

### FIGDEF# site_ext

```yaml
    label: Telephely
    pluralLabel: Telephelyek
    type: EXTEND
    parent: site
```

| Field   | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign | FK          | Replacement | Hide |
|---------|---------|------------|------|----------|----------|--------|-----------|-------------|--------|---------|-------------|-------------|------|
| partner | Partner | Partner    |      |          |          |        |           |             | EXTEND | partner | name        | partner_id  | X    |
| country | Ország  | Dictionary |      |          |          |        |           |             | DICT   | COUNTRY | description | country_did |      |

---

### FIGDEF# site_with_partner_ext

```yaml
    label: Telephely
    pluralLabel: Telephelyek
    type: EXTEND
    parent: site
```

| Field   | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign | FK          | Replacement |
|---------|---------|------------|------|----------|----------|--------|-----------|-------------|--------|---------|-------------|-------------|
| partner | Partner | Partner    |      |          |          |        |           |             | EXTEND | partner | name        | partner_id  |
| country | Ország  | Dictionary |      |          |          |        |           |             | DICT   | COUNTRY | description | country_did |

---

### FIGDEF# user_basic_right

```yaml
    label: Felhasználó alapjog
    pluralLabel: Felhasználó alapjogok
    type: TABLE
```

| Field               | Label                 | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign          | FK                  |
|---------------------|-----------------------|----------|------|----------|----------|--------|-----------|-------------|-------|------------------|---------------------|
| id                  | Id                    | IDENT    |      |          |          |        |           |             |       |                  |                     | 
| ruser_id            | Felhasználó           | FKIDENT  |      |          |          |        |           |             | TABLE | ruser            | ruser.id            | 
| elementary_right_id | Elemi jog             | FKIDENT  |      |          |          |        |           |             | TABLE | elementary_right | elementary_right.id | 
| creator_ruser_id    | Létrehozó felhasználó | FKIDENT  |      |          |          |        |           |             | TABLE | creator_ruser    | ruser.id            | 
| assigned_role_id    | Hozzárendelt szerep   | FKIDENT  |      |          | X        |        |           |             | TABLE | assigned_role    | assigned_role.id    | 
| valid_from_dt       | Érvényes-től          | DATETIME |      |          | X        |        |           |             |       |                  |                     | 
| valid_to_dt         | Érvényes-ig           | DATETIME |      |          | X        |        |           |             |       |                  |                     | 

---

### FIGDEF# user_basic_right_parameter

```yaml
    label: Felhasználó alapjog paraméter
    pluralLabel: Felhasználó alapjog paraméterek
    type: TABLE
```

| Field               | Label               | Type    | Size  | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign          | FK                  |
|---------------------|---------------------|---------|-------|----------|----------|--------|-----------|-------------|-------|------------------|---------------------|
| id                  | Id                  | IDENT   |       |          |          |        |           |             |       |                  |                     | 
| user_basic_right_id | Felhasználó alapjog | FKIDENT |       |          |          |        |           |             | TABLE | user_basic_right | user_basic_right.id | 
| right_parameter_did | Jog paraméter       | DICT    |       |          |          |        |           |             |       | RIGHT_PARAMETER  |                     | 
| parameter_value     | Paraméter érték     | TEXT    | 65535 |          | X        |        |           |             |       |                  |                     | 

---

### FIGDEF# user_profil

```yaml
    label: Felhasználó profil
    pluralLabel: Felhasználó profilok
    type: TABLE
```

| Field            | Label            | Type    | Size  | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign      | FK       |
|------------------|------------------|---------|-------|----------|----------|--------|-----------|-------------|-------|--------------|----------|
| id               | Id               | IDENT   |       |          |          |        |           |             |       |              |          | 
| ruser_id         | Felhasználó      | FKIDENT |       |          |          |        |           |             | TABLE | ruser        | ruser.id | 
| setting_type_did | Beállítás típusa | DICT    |       |          |          |        |           |             |       | SETTING_TYPE |          | 
| setting          | Beállítás        | TEXT    | 65535 |          | X        |        |           |             |       |              |          | 

---

### FIGDEF# working_time_schedule

```yaml
    label: Munkaidő beosztás
    pluralLabel: Munkaidő beosztások
    type: TABLE
```

| Field                            | Label                          | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign                      | FK                           |
|----------------------------------|--------------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|------------------------------|------------------------------|
| id                               | Id                             | IDENT   |      |          |          |        |           |             |       |                              |                              | 
| worker_id                        | Dolgozó                        | FKIDENT |      |          |          |        |           |             | TABLE | worker                       | worker.id                    | 
| time_use_type_did                | Idő felhasználás típusa        | DICT    |      |          |          |        |           |             |       | TIME_USE_TYPE                |                              | 
| working_time_schedule_status_did | Munkaidő beosztás állapota     | DICT    |      |          |          |        |           |             |       | WORKING_TIME_SCHEDULE_STATUS |                              | 
| demand_id                        | Igény                          | FKIDENT |      |          | X        |        |           |             | TABLE | demand                       | demand_item.id               | 
| position_did                     | Beosztás                       | DICT    |      |          | X        |        |           |             |       | POSITION                     |                              | 
| day                              | Nap                            | DATE    |      |          |          |        |           |             |       |                              |                              | 
| worker_assignment_request_id     | Dolgozó hozzárendelési kérelem | FKIDENT |      |          | X        |        |           |             | TABLE | worker_assignment_request    | worker_assignment_request.id | 
| sick_pay_period_id               | Táppénz időszak                | FKIDENT |      |          | X        |        |           |             | TABLE | sick_pay_period              | sick_pay_period.id           | 
| calendar_id                      | Naptár                         | FKIDENT |      |          |          |        |           |             | TABLE | calendar                     | calendar.id                  | 
| from_time                        | Kezdés                         | TIME    | 10   |          | X        |        |           |             |       |                              |                              | 
| to_time                          | Befejezés                      | TIME    | 10   |          | X        |        |           |             |       |                              |                              |
