---
title: worker.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/worker.figdoc.md
doc_type: text
---

# worker.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 24.6 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/worker.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

jasjhashjasdhasjdhjkadshhjasdhjkdsa
a
sdasd
as
d
asd
as
d
asd
as
d
asd
asd
asddasdsaasd
asdd
asd
asdadsasd

### FIGDEF# worker

```yaml
    label: Dolgozó
    pluralLabel: Dolgozók
    type: TABLE
```

| Field                      | Label                         | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign               | FK         |
|----------------------------|-------------------------------|----------|------|----------|----------|--------|-----------|-------------|-------|-----------------------|------------|
| id                         | Id                            | IDENT    |      |          |          |        |           |             |       |                       |            | 
| person_id                  | Személy                       | FKIDENT  |      |          |          |        |           |             | TABLE | person                | person.id  | 
| employment_type_did        | Foglalkoztatás típusa         | DICT     |      |          | X        |        |           |             |       | EMPLOYMENT_TYPE       |            | 
| worker_status_did          | Dolgozó állapota              | DICT     |      |          |          |        |           |             |       | WORKER_STATUS         |            | 
| payroll_type_did           | Bérszámfejtés típusa          | DICT     |      |          | X        |        |           |             |       | PAYROLL_TYPE          |            | 
| company_id                 | Cég                           | FKIDENT  |      |          |          |        |           |             | TABLE | company               | company.id | 
| feor_did                   | FEOR                          | DICT     |      |          | X        |        |           |             |       | FEOR                  |            | 
| position                   | Beosztás                      | VARCHAR  | 2048 |          | X        |        |           |             |       |                       |            | 
| entry_date                 | Belépés dátuma                | DATE     |      |          | X        |        |           |             |       |                       |            | 
| leaving_date               | Kilépés dátuma                | DATE     |      |          | X        |        |           |             |       |                       |            | 
| weekly_working_hours       | Heti munkaidő                 | SMALLINT | 5    |          | X        |        |           |             |       |                       |            | 
| other_labor_notice         | Egyéb munkajogi értesítés     | VARCHAR  | 2048 |          | X        |        |           |             |       |                       |            | 
| method_of_termination_did  | Megszüntetés módja            | DICT     |      |          | X        |        |           |             |       | METHOD_OF_TERMINATION |            | 
| method_of_termination_desc | Megszüntetés módjának leírása | VARCHAR  | 2048 |          | X        |        |           |             |       |                       |            | 

### FIGDEF# worker_ext

```yaml
    label: Dolgozó
    pluralLabel: Dolgozók
    type: EXTEND
    parent: worker
```

| Field                 | Label                 | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign               | FK          | Replacement               |
|-----------------------|-----------------------|------------|------|----------|----------|--------|-----------|-------------|--------|-----------------------|-------------|---------------------------|
| person                | Személy               | PersonExt  |      |          |          |        |           |             | EXTEND | person_ext            | last_name   | person_id                 |
| company               | Cég                   | Company    |      |          |          |        |           |             | DTO    | company               | shortName   | company_id                |
| employment_type       | Foglalkoztatás típusa | Dictionary |      |          |          |        |           |             | DICT   | EMPLOYMENT_TYPE       | description | employment_type_did       |
| worker_status         | Dolgozó állapota      | Dictionary |      |          |          |        |           |             | DICT   | WORKER_STATUS         | description | worker_status_did         |
| payroll_type          | Bérszámfejtés típusa  | Dictionary |      |          |          |        |           |             | DICT   | PAYROLL_TYPE          | description | payroll_type_did          |
| feor                  | FEOR                  | Dictionary |      |          |          |        |           |             | DICT   | FEOR                  | description | feor_did                  |
| method_of_termination | Megszüntetés módja    | Dictionary |      |          |          |        |           |             | DICT   | METHOD_OF_TERMINATION | description | method_of_termination_did |

### FIGDEF# worker_assignment_request

```yaml
    label: Dolgozó hozzárendelési kérelem
    pluralLabel: Dolgozó hozzárendelési kérelmek
    type: TABLE
```

| Field                         | Label                          | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign                   | FK        |
|-------------------------------|--------------------------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------------------------|-----------|
| id                            | Id                             | IDENT    |      |          |          |        |           |             |       |                           |           | 
| worker_id                     | Dolgozó                        | FKIDENT  |      |          |          |        |           |             | TABLE | worker                    | worker.id | 
| requested_place_of_employment | Kért munkavégzés helye         | CHAR     | 10   |          | X        |        |           |             |       |                           |           | 
| reason                        | Indok                          | VARCHAR  | 2048 |          | X        |        |           |             |       |                           |           | 
| request_datetime              | Kérés dátuma                   | DATETIME |      |          | X        |        |           |             |       |                           |           | 
| worker_assignment_request_did | Dolgozó hozzárendelési kérelem | DICT     |      |          |          |        |           |             |       | WORKER_ASSIGNMENT_REQUEST |           | 

### FIGDEF# worker_assignment_request_ext

```yaml
    label: Munkaerő kirendelési kérelem
    pluralLabel: Munkaerő kirendelési kérelmek
    type: EXTEND
    parent: worker_assignment_request
```

| Field                     | Label                     | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign                   | FK          | Replacement                   |
|---------------------------|---------------------------|------------|------|----------|----------|--------|-----------|-------------|------|---------------------------|-------------|-------------------------------|
| worker_assignment_request | Worker Assignment Request | Dictionary |      |          |          |        |           |             | DICT | WORKER_ASSIGNMENT_REQUEST | description | worker_assignment_request_did |

### FIGDEF# worker_bank_account

```yaml
    label: Dolgozó bankszámla
    pluralLabel: Dolgozó bankszámlák
    type: TABLE
```

| Field                   | Label                 | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign             | FK        | Hide |
|-------------------------|-----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------------|-----------|------|
| id                      | Id                    | IDENT   |      |          |          |        |           |             |       |                     |           |      |
| worker_id               | Dolgozó               | FKIDENT |      |          |          |        |           |             | TABLE | worker              | worker.id | X    |
| name                    | Bank neve             | VARCHAR | 128  |          |          |        |           |             |       |                     |           |      |
| country_did             | Ország                | DICT    |      |          |          |        |           |             |       | COUNTRY             |           |      |
| address                 | Cím                   | VARCHAR | 2048 |          | X        |        |           |             |       |                     |           |      |
| swift                   | SWIFT                 | VARCHAR | 32   |          | X        |        |           |             |       |                     |           |      |
| huf_bank_account_number | HUF bankszámlaszám    | VARCHAR | 64   |          | X        |        |           |             |       |                     |           |      |
| huf_iban                | HUF IBAN              | VARCHAR | 32   |          | X        |        |           |             |       |                     |           |      |
| dev_bank_account_number | Deviza bankszámlaszám | VARCHAR | 64   |          | X        |        |           |             |       |                     |           |      |
| dev_iban                | Deviza IBAN           | VARCHAR | 32   |          | X        |        |           |             |       |                     |           |      |
| account_owner           | Számlatulajdonos      | VARCHAR | 128  |          | X        |        |           |             |       |                     |           |      |
| currency_did            | Dev. pénzneme         | DICT    |      |          | X        |        |           |             |       | CURRENCY            |           |      |
| bank_account_status_did | Bszla. állapota       | DICT    |      |          |          |        |           |             |       | BANK_ACCOUNT_STATUS |           |      |
| note                    | Megjegyzés            | VARCHAR | 2048 |          | X        |        |           |             |       |                     |           |      |

### FIGDEF# worker_bank_account_ext

```yaml
    label: Dolgozó bankszámla
    pluralLabel: Dolgozó bankszámlái
    type: EXTEND
    parent: worker_bank_account
```

| Field                         | Label                         | Type                                | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                               | FK          | Replacement             | Hide |
|-------------------------------|-------------------------------|-------------------------------------|------|----------|----------|--------|-----------|-------------|--------|---------------------------------------|-------------|-------------------------|------|
| country                       | Ország                        | Dictionary                          |      |          |          |        |           |             | DICT   | COUNTRY                               | description | country_did             |      |
| currency                      | Pénznem                       | Dictionary                          |      |          | X        |        |           |             | DICT   | CURRENCY                              | description | currency_did            |      |
| bank_account_status           | Bszla. állapota               | Dictionary                          |      |          | X        |        |           |             | DICT   | BANK_ACCOUNT_STATUS                   | description | bank_account_status_did |      |
| worker_bank_account_documents | Worker Bank Account Documents | List<WorkerBankAccountDocumentExt?> |      |          |          |        |           |             | EXTEND | list:worker_bank_account_document_ext |             |                         | X    |

### FIGDEF# worker_bank_account_document

```yaml
    label: Dolgozó bankszámla dokumentum
    pluralLabel: Dolgozó bankszámla dokumentumok
    type: TABLE
```

| Field                  | Label              | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign             | FK                     |
|------------------------|--------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------------|------------------------|
| id                     | Id                 | IDENT   |      |          |          |        |           |             |       |                     |                        | 
| worker_bank_account_id | Dolgozó bankszámla | FKIDENT |      |          |          |        |           |             | TABLE | worker_bank_account | worker_bank_account.id | 
| document_id            | Dokumentum         | FKIDENT |      |          |          |        |           |             | TABLE | document            | document.id            | 

### FIGDEF# worker_bank_account_document_ext

```yaml
    label: Dolgozó bankszámla dokumentuma
    pluralLabel: Dolgozó bankszámla dokumentumai
    type: EXTEND
    parent: worker_bank_account_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

### FIGDEF# worker_car

```yaml
    label: Dolgozó autó
    pluralLabel: Dolgozó autók
    type: TABLE
```

| Field           | Label        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK        | Hide |
|-----------------|--------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|-----------|------|
| id              | Id           | IDENT   |      |          |          |        |           |             |       |         |           |      |
| worker_id       | Dolgozó      | FKIDENT |      |          |          |        |           |             | TABLE | worker  | worker.id | X    |
| car_id          | Autó         | FKIDENT |      |          |          |        |           |             | TABLE | car     | car.id    |      |
| valid_from_date | Érvényes-től | DATE    |      |          |          |        |           |             |       |         |           |      |
| valid_to_date   | Érvényes-ig  | DATE    |      |          | X        |        |           |             |       |         |           |      |

### FIGDEF# worker_car_ext

```yaml
    label: Dolgozó gépjárműve
    pluralLabel: Dolgozó gépjárművei
    type: EXTEND
    parent: worker_car
```

| Field | Label | Type   | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign | FK                   | Replacement |
|-------|-------|--------|------|----------|----------|--------|-----------|-------------|--------|---------|----------------------|-------------|
| car   | Autó  | CarExt |      |          |          |        |           |             | EXTEND | car_ext | license_plate_number | car_id      |

### FIGDEF# worker_car_document

```yaml
    label: Dolgozó autó dokumentuma
    pluralLabel: Dolgozó autó dokumentumok
    type: TABLE
```

| Field         | Label          | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign    | FK            |
|---------------|----------------|---------|------|----------|----------|--------|-----------|-------------|-------|------------|---------------|
| id            | Id             | IDENT   |      |          |          |        |           |             |       |            |               | 
| worker_car_id | Dolgozó autója | FKIDENT |      |          |          |        |           |             | TABLE | worker_car | worker_car.id | 
| document_id   | Dokumentum     | FKIDENT |      |          |          |        |           |             | TABLE | document   | document.id   | 

### FIGDEF# worker_car_document_ext

```yaml
    label: Dolgozó gépjármű dokumentuma
    pluralLabel: Dolgozó gépjármű dokumentumai
    type: EXTEND
    parent: worker_car_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

### FIGDEF# worker_document

```yaml
    label: Okmány
    pluralLabel: Okmányok
    type: TABLE
```

| Field       | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          |
|-------------|------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|
| id          | Id         | IDENT   |      |          |          |        |           |             |       |          |             | 
| worker_id   | Dolgozó    | FKIDENT |      |          |          |        |           |             | TABLE | worker   | worker.id   | 
| document_id | Dokumentum | FKIDENT |      |          |          |        |           |             | TABLE | document | document.id | 

### FIGDEF# worker_document_ext

```yaml
    label: Dolgozó dokumentum
    pluralLabel: Dolgozó dokumentumok
    type: EXTEND
    parent: worker_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

### FIGDEF# worker_document_site_validity

```yaml
    label: Dolgozó dokumentum telephely érvényesség
    pluralLabel: Dolgozó dokumentum telephely érvényességek
    type: TABLE
```

| Field              | Label              | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                 |
|--------------------|--------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|--------------------|
| id                 | Id                 | IDENT   |      |          |          |        |           |             |       |                 |                    | 
| worker_document_id | Dolgozó dokumentum | FKIDENT |      |          |          |        |           |             | TABLE | worker_document | worker_document.id | 
| site_id            | Telephely          | FKIDENT |      |          |          |        |           |             | TABLE | site            | site.id            | 

### FIGDEF# worker_life_path

```yaml
    label: Dolgozó életpálya
    pluralLabel: Dolgozó életpályák
    type: TABLE
```

| Field                            | Label                                        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK        | SubType  |
|----------------------------------|----------------------------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|-----------|----------|
| id                               | Id                                           | IDENT   |      |          |          |        |           |             |       |         |           |          |
| worker_id                        | Dolgozó                                      | FKIDENT |      |          |          |        |           |             | TABLE | worker  | worker.id |          |
| valid_from_date                  | Érvényes-től                                 | DATE    |      |          | X        |        |           |             |       |         |           |          |
| valid_to_date                    | Érvényes-ig                                  | DATE    |      |          | X        |        |           |             |       |         |           |          |
| description                      | Leírás                                       | VARCHAR | 2048 |          |          |        |           |             |       |         |           |          |
| abroad                           | Külföld                                      | BOOL    |      |          | X        |        |           |             |       |         |           |          |
| health_insurance_fee_settled     | Egészségbiztosítási járulék rendezve         | BOOL    |      |          | X        |        |           |             |       |         |           |          |
| who_settled_health_insurance_fee | Ki rendezte az egészségbiztosítási járulékot | VARCHAR | 32   |          | X        |        |           |             |       |         |           |          |
| health_insurance_fee_debt        | Egészségbiztosítási járulék tartozás         | DECIMAL | 19   | 2        | X        |        |           |             |       |         |           | CURRENCY |

### FIGDEF# worker_note

```yaml
    label: Dolgozó megjegyzés
    pluralLabel: Dolgozó megjegyzések
    type: TABLE
```

| Field                  | Label                       | Type     | Size  | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign            | FK        | Hide |
|------------------------|-----------------------------|----------|-------|----------|----------|--------|-----------|-------------|-------|--------------------|-----------|------|
| id                     | Id                          | IDENT    |       |          |          | X      |           |             |       |                    |           |      |
| worker_id              | Dolgozó                     | FKIDENT  |       |          |          |        |           |             | TABLE | worker             | worker.id | X    |
| note                   | Megjegyzés                  | TEXT     | 65535 |          |          |        |           |             |       |                    |           |      |
| ruser_id               | Felhasználó                 | FKIDENT  |       |          |          |        |           |             | TABLE | ruser              | ruser.id  |      |
| worker_note_status_did | Dolgozó megjegyzés állapota | DICT     |       |          |          |        |           |             |       | WORKER_NOTE_STATUS |           |      |
| creation_dt            | Létrehozás dátuma           | DATETIME |       |          |          |        |           |             |       |                    |           |      |

### FIGDEF# worker_note_ext

```yaml
    label: Dolgozó megjegyzése
    pluralLabel: Dolgozó megjegyzései
    type: EXTEND
    parent: worker_note
```

| Field              | Label                       | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign            | FK          | Replacement            |
|--------------------|-----------------------------|------------|------|----------|----------|--------|-----------|-------------|------|--------------------|-------------|------------------------|
| ruser              | Ruser                       | Ruser      |      |          |          |        |           |             | DTO  | ruser              | user_name   | ruser_id               |
| worker_note_status | Dolgozó megjegyzés állapota | Dictionary |      |          |          |        |           |             | DICT | WORKER_NOTE_STATUS | description | worker_note_status_did |
