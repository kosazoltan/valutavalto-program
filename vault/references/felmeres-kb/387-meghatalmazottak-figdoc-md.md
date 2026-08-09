---
title: meghatalmazottak.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/meghatalmazottak.figdoc.md
doc_type: text
---

# meghatalmazottak.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 27.9 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/meghatalmazottak.figdoc.md`

## Tartalom

# Valutaváltó Rendszer - Ügyfél Meghatalmazottak

## Változtatások

| Verzió/Dátum     | Leírás                                                |
|------------------|-------------------------------------------------------|
| 1.0 - 2025.05.06 | Első verzió - Meghatalmazottak kezelésének bevezetése |

## Ügyfél Meghatalmazottak és Kapcsolódó Entitások

---

### FIGDEF# authorized_representative

```yaml
    label: Meghatalmazott
    pluralLabel: Meghatalmazottak
    type: TABLE
```

| Field                   | Label                   | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description                  | FT    | Foreign             | FK          | SubType |
|-------------------------|-------------------------|---------|------|----------|----------|--------|-----------|------------------------------|-------|---------------------|-------------|---------|
| id                      | Id                      | IDENT   |      |          |          |        |           |                              |       |                     |             |         |
| customer_id             | Ügyfél                  | FKIDENT |      |          |          |        |           | A meghatalmazó ügyfél        | TABLE | customer            | customer.id |         |
| first_name              | Keresztnév              | VARCHAR | 64   |          |          |        |           |                              |       |                     |             |         |
| last_name               | Vezetéknév              | VARCHAR | 64   |          |          |        |           |                              |       |                     |             |         |
| birth_date              | Születési dátum         | DATE    |      |          | X        |        |           |                              |       |                     |             |         |
| identity_number         | Személyazonosító szám   | VARCHAR | 32   |          |          |        |           |                              |       |                     |             |         |
| identity_type_did       | Személyazonosító típusa | DICT    |      |          |          |        |           |                              |       | IDENTITY_TYPE       |             |         |
| address                 | Cím                     | VARCHAR | 256  |          | X        |        |           |                              |       |                     |             |         |
| city                    | Város                   | VARCHAR | 64   |          | X        |        |           |                              |       |                     |             |         |
| zip_code                | Irányítószám            | VARCHAR | 16   |          | X        |        |           |                              |       |                     |             |         |
| country_did             | Ország                  | DICT    |      |          | X        |        |           |                              |       | COUNTRY             |             |         |
| phone                   | Telefonszám             | VARCHAR | 32   |          | X        |        |           |                              |       |                     |             |         |
| email                   | E-mail cím              | VARCHAR | 128  |          | X        |        |           |                              |       |                     |             | EMAIL   |
| nationality_did         | Állampolgárság          | DICT    |      |          | X        |        |           |                              |       | NATIONALITY         |             |         |
| is_pep                  | Kiemelt közszereplő     | BOOL    |      |          |          |        |           |                              |       |                     |             |         |
| representative_type_did | Meghatalmazás típusa    | DICT    |      |          |          |        |           |                              |       | REPRESENTATIVE_TYPE |             |         |
| relationship_did        | Kapcsolat típusa        | DICT    |      |          | X        |        |           | Az ügyfélhez fűződő viszonya |       | RELATIONSHIP_TYPE   |             |         |
| is_active               | Aktív                   | BOOL    |      |          |          |        |           |                              |       |                     |             |         |

---

### FIGDEF# authorized_representative_ext

```yaml
    label: Meghatalmazott
    pluralLabel: Meghatalmazottak
    type: EXTEND
    parent: authorized_representative
```

| Field               | Label                   | Type                             | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                          | FK          | Replacement             |
|---------------------|-------------------------|----------------------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------------------|-------------|-------------------------|
| customer            | Ügyfél                  | Customer                         |      |          |          |        |           |             | EXTEND | customer                         | last_name   | customer_id             |
| identity_type       | Személyazonosító típusa | Dictionary                       |      |          |          |        |           |             | DICT   | IDENTITY_TYPE                    | description | identity_type_did       |
| country             | Ország                  | Dictionary                       |      |          |          |        |           |             | DICT   | COUNTRY                          | description | country_did             |
| nationality         | Állampolgárság          | Dictionary                       |      |          |          |        |           |             | DICT   | NATIONALITY                      | description | nationality_did         |
| representative_type | Meghatalmazás típusa    | Dictionary                       |      |          |          |        |           |             | DICT   | REPRESENTATIVE_TYPE              | description | representative_type_did |
| relationship        | Kapcsolat típusa        | Dictionary                       |      |          |          |        |           |             | DICT   | RELATIONSHIP_TYPE                | description | relationship_did        |
| authorizations      | Jogosultságok           | List<AuthorizationExt?>          |      |          |          |        |           |             | EXTEND | list:authorization_ext           |             |                         |
| documents           | Dokumentumok            | List<RepresentativeDocumentExt?> |      |          |          |        |           |             | EXTEND | list:representative_document_ext |             |                         |
| transactions        | Tranzakciók             | List<TransactionExt?>            |      |          |          |        |           |             | EXTEND | list:transaction_ext             |             |                         |

---

### FIGDEF# authorization

```yaml
    label: Meghatalmazás
    pluralLabel: Meghatalmazások
    type: TABLE
```

| Field                        | Label                  | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description                | FT    | Foreign                   | FK                           | SubType  |
|------------------------------|------------------------|----------|------|----------|----------|--------|-----------|----------------------------|-------|---------------------------|------------------------------|----------|
| id                           | Id                     | IDENT    |      |          |          |        |           |                            |       |                           |                              |          |
| authorized_representative_id | Meghatalmazott         | FKIDENT  |      |          |          |        |           |                            | TABLE | authorized_representative | authorized_representative.id |          |
| authorization_type_did       | Meghatalmazás típusa   | DICT     |      |          |          |        |           |                            |       | AUTHORIZATION_TYPE        |                              |          |
| issue_date                   | Kiállítás dátuma       | DATE     |      |          |          |        |           |                            |       |                           |                              |          |
| start_date                   | Érvényesség kezdete    | DATE     |      |          |          |        |           |                            |       |                           |                              |          |
| expiry_date                  | Érvényesség vége       | DATE     |      |          | X        |        |           |                            |       |                           |                              |          |
| max_amount                   | Maximum összeg         | DECIMAL  | 19   | 2        | X        |        |           | Maximum tranzakciós összeg |       |                           |                              | CURRENCY |
| max_transaction_count        | Maximum tranzakciószám | INT      | 10   |          | X        |        |           |                            |       |                           |                              |          |
| status_did                   | Státusz                | DICT     |      |          |          |        |           |                            |       | AUTHORIZATION_STATUS      |                              |          |
| created_by                   | Létrehozta             | FKIDENT  |      |          |          |        |           |                            | TABLE | cashier                   | cashier.id                   |          |
| created_date                 | Létrehozás dátuma      | DATETIME |      |          |          |        |           |                            |       |                           |                              |          |
| verified_by                  | Ellenőrizte            | FKIDENT  |      |          | X        |        |           |                            | TABLE | cashier                   | cashier.id                   |          |
| verification_date            | Ellenőrzés dátuma      | DATETIME |      |          | X        |        |           |                            |       |                           |                              |          |
| document_path                | Dokumentum útvonala    | VARCHAR  | 512  |          | X        |        |           |                            |       |                           |                              |          |
| notes                        | Megjegyzések           | VARCHAR  | 1024 |          | X        |        |           |                            |       |                           |                              |          |

---

### FIGDEF# authorization_ext

```yaml
    label: Meghatalmazás
    pluralLabel: Meghatalmazások
    type: EXTEND
    parent: authorization
```

| Field                     | Label                   | Type                       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                    | FK          | Replacement                  |
|---------------------------|-------------------------|----------------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------------|-------------|------------------------------|
| authorized_representative | Meghatalmazott          | AuthorizedRepresentative   |      |          |          |        |           |             | EXTEND | authorized_representative  | last_name   | authorized_representative_id |
| authorization_type        | Meghatalmazás típusa    | Dictionary                 |      |          |          |        |           |             | DICT   | AUTHORIZATION_TYPE         | description | authorization_type_did       |
| status                    | Státusz                 | Dictionary                 |      |          |          |        |           |             | DICT   | AUTHORIZATION_STATUS       | description | status_did                   |
| created_by_user           | Létrehozta              | Cashier                    |      |          |          |        |           |             | EXTEND | cashier                    | last_name   | created_by                   |
| verified_by_user          | Ellenőrizte             | Cashier                    |      |          |          |        |           |             | EXTEND | cashier                    | last_name   | verified_by                  |
| allowed_operations        | Engedélyezett műveletek | List<AllowedOperationExt?> |      |          |          |        |           |             | EXTEND | list:allowed_operation_ext |             |                              |

---

### FIGDEF# allowed_operation

```yaml
    label: Engedélyezett művelet
    pluralLabel: Engedélyezett műveletek
    type: TABLE
```

| Field            | Label         | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign        | FK               |
|------------------|---------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------------|------------------|
| id               | Id            | IDENT   |      |          |          |        |           |             |       |                |                  | 
| authorization_id | Meghatalmazás | FKIDENT |      |          |          |        |           |             | TABLE | authorization  | authorization.id | 
| operation_did    | Művelet       | DICT    |      |          |          |        |           |             |       | OPERATION_TYPE |                  | 
| is_allowed       | Engedélyezett | BOOL    |      |          |          |        |           |             |       |                |                  | 
| notes            | Megjegyzések  | VARCHAR | 512  |          | X        |        |           |             |       |                |                  | 

---

### FIGDEF# allowed_operation_ext

```yaml
    label: Engedélyezett művelet
    pluralLabel: Engedélyezett műveletek
    type: EXTEND
    parent: allowed_operation
```

| Field         | Label         | Type          | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign        | FK          | Replacement      |
|---------------|---------------|---------------|------|----------|----------|--------|-----------|-------------|--------|----------------|-------------|------------------|
| authorization | Meghatalmazás | Authorization |      |          |          |        |           |             | EXTEND | authorization  | id          | authorization_id |
| operation     | Művelet       | Dictionary    |      |          |          |        |           |             | DICT   | OPERATION_TYPE | description | operation_did    |

---

### FIGDEF# representative_document

```yaml
    label: Meghatalmazott dokumentum
    pluralLabel: Meghatalmazott dokumentumok
    type: TABLE
```

| Field                        | Label               | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign                   | FK                           |
|------------------------------|---------------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------------------------|------------------------------|
| id                           | Id                  | IDENT    |      |          |          |        |           |             |       |                           |                              | 
| authorized_representative_id | Meghatalmazott      | FKIDENT  |      |          |          |        |           |             | TABLE | authorized_representative | authorized_representative.id | 
| document_type_did            | Dokumentum típusa   | DICT     |      |          |          |        |           |             |       | DOCUMENT_TYPE             |                              | 
| document_number              | Dokumentum száma    | VARCHAR  | 64   |          |          |        |           |             |       |                           |                              | 
| issue_date                   | Kiállítás dátuma    | DATE     |      |          | X        |        |           |             |       |                           |                              | 
| expiry_date                  | Lejárat dátuma      | DATE     |      |          | X        |        |           |             |       |                           |                              | 
| issuing_authority            | Kiállító hatóság    | VARCHAR  | 128  |          | X        |        |           |             |       |                           |                              | 
| issuing_country_did          | Kiállító ország     | DICT     |      |          | X        |        |           |             |       | COUNTRY                   |                              | 
| document_path                | Dokumentum útvonala | VARCHAR  | 512  |          | X        |        |           |             |       |                           |                              | 
| verified                     | Ellenőrizve         | BOOL     |      |          |          |        |           |             |       |                           |                              | 
| verification_date            | Ellenőrzés dátuma   | DATETIME |      |          | X        |        |           |             |       |                           |                              | 
| verified_by                  | Ellenőrizte         | FKIDENT  |      |          | X        |        |           |             | TABLE | cashier                   | cashier.id                   | 
| notes                        | Megjegyzések        | VARCHAR  | 1024 |          | X        |        |           |             |       |                           |                              | 

---

### FIGDEF# representative_document_ext

```yaml
    label: Meghatalmazott dokumentum
    pluralLabel: Meghatalmazott dokumentumok
    type: EXTEND
    parent: representative_document
```

| Field                     | Label             | Type                     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                   | FK          | Replacement                  |
|---------------------------|-------------------|--------------------------|------|----------|----------|--------|-----------|-------------|--------|---------------------------|-------------|------------------------------|
| authorized_representative | Meghatalmazott    | AuthorizedRepresentative |      |          |          |        |           |             | EXTEND | authorized_representative | last_name   | authorized_representative_id |
| document_type             | Dokumentum típusa | Dictionary               |      |          |          |        |           |             | DICT   | DOCUMENT_TYPE             | description | document_type_did            |
| issuing_country           | Kiállító ország   | Dictionary               |      |          |          |        |           |             | DICT   | COUNTRY                   | description | issuing_country_did          |
| verified_by_user          | Ellenőrizte       | Cashier                  |      |          |          |        |           |             | EXTEND | cashier                   | last_name   | verified_by                  |

---

### FIGDEF# representative_log

```yaml
    label: Meghatalmazott aktivitás napló
    pluralLabel: Meghatalmazott aktivitás naplók
    type: TABLE
```

| Field                        | Label          | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign                   | FK                           |
|------------------------------|----------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------------------------|------------------------------|
| id                           | Id             | IDENT    |      |          |          |        |           |             |       |                           |                              | 
| authorized_representative_id | Meghatalmazott | FKIDENT  |      |          |          |        |           |             | TABLE | authorized_representative | authorized_representative.id | 
| log_date                     | Dátum          | DATETIME |      |          |          |        |           |             |       |                           |                              | 
| log_type_did                 | Napló típusa   | DICT     |      |          |          |        |           |             |       | REPRESENTATIVE_LOG_TYPE   |                              | 
| transaction_id               | Tranzakció     | FKIDENT  |      |          | X        |        |           |             | TABLE | transaction               | transaction.id               | 
| performed_by                 | Végrehajtotta  | FKIDENT  |      |          |          |        |           |             | TABLE | cashier                   | cashier.id                   | 
| branch_id                    | Fiók           | FKIDENT  |      |          |          |        |           |             | TABLE | branch                    | branch.id                    | 
| details                      | Részletek      | VARCHAR  | 1024 |          | X        |        |           |             |       |                           |                              | 

---

### FIGDEF# representative_log_ext

```yaml
    label: Meghatalmazott aktivitás napló
    pluralLabel: Meghatalmazott aktivitás naplók
    type: EXTEND
    parent: representative_log
```

| Field                     | Label          | Type                     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                   | FK                 | Replacement                  |
|---------------------------|----------------|--------------------------|------|----------|----------|--------|-----------|-------------|--------|---------------------------|--------------------|------------------------------|
| authorized_representative | Meghatalmazott | AuthorizedRepresentative |      |          |          |        |           |             | EXTEND | authorized_representative | last_name          | authorized_representative_id |
| log_type                  | Napló típusa   | Dictionary               |      |          |          |        |           |             | DICT   | REPRESENTATIVE_LOG_TYPE   | description        | log_type_did                 |
| transaction               | Tranzakció     | Transaction              |      |          |          |        |           |             | EXTEND | transaction               | transaction_number | transaction_id               |
| performed_by_user         | Végrehajtotta  | Cashier                  |      |          |          |        |           |             | EXTEND | cashier                   | last_name          | performed_by                 |
| branch                    | Fiók           | Branch                   |      |          |          |        |           |             | EXTEND | branch                    | name               | branch_id                    |

## Kódszótárak

### DICTDEF# REPRESENTATIVE_TYPE

```yaml
    label: REPRESENTATIVE_TYPE
```

| Code              | Name                     | Id                                   |
|-------------------|--------------------------|--------------------------------------|
| PERMANENT         | Állandó meghatalmazott   | 01968c15-a123-7a22-b345-01ac432de100 |
| TEMPORARY         | Időszakos meghatalmazott | 01968c15-b234-7b33-c456-12bd543ef200 |
| LEGAL_GUARDIAN    | Törvényes képviselő      | 01968c15-c345-736a-9408-5cd3e99dc300 |
| POWER_OF_ATTORNEY | Ügyvédi meghatalmazás    | 01968c15-d456-7d9b-9c77-003175234400 |
| COMPANY_DELEGATE  | Céges megbízott          | 01968c15-e567-73a9-9420-c173e3f8f500 |

### DICTDEF# RELATIONSHIP_TYPE

```yaml
    label: RELATIONSHIP_TYPE
```

| Code         | Name              | Id                                   |
|--------------|-------------------|--------------------------------------|
| FAMILY       | Családtag         | 01968d16-a123-71a1-a123-45ef6789a100 |
| COLLEAGUE    | Munkatárs         | 01968d16-b234-7890-b573-4a18075ba200 |
| FRIEND       | Barát             | 01968d16-c345-70af-b28c-8712af444300 |
| PROFESSIONAL | Szakmai kapcsolat | 01968d16-d456-7f9f-955e-88b361f2d400 |
| BUSINESS     | Üzleti kapcsolat  | 01968d16-e567-7a1a-1a1a-a1a1a1a1a500 |
| OTHER        | Egyéb             | 01968d16-f678-7b2b-2b2b-b2b2b2b2b600 |

### DICTDEF# AUTHORIZATION_TYPE

```yaml
    label: AUTHORIZATION_TYPE
```

| Code           | Name                      | Id                                   |
|----------------|---------------------------|--------------------------------------|
| FULL           | Teljes körű meghatalmazás | 01968e17-a123-7a22-b345-01ac432d0100 |
| LIMITED        | Korlátozott meghatalmazás | 01968e17-b234-7b33-c456-12bd543e0200 |
| WITHDRAWAL     | Csak pénzfelvétel         | 01968e17-c345-736a-9408-5cd3e99d0300 |
| EXCHANGE       | Csak valutaváltás         | 01968e17-d456-7d9b-9c77-003175230400 |
| ADMINISTRATIVE | Csak ügyintézés           | 01968e17-e567-73a9-9420-c173e3f80500 |

### DICTDEF# AUTHORIZATION_STATUS

```yaml
    label: AUTHORIZATION_STATUS
```

| Code      | Name           | Id                                   |
|-----------|----------------|--------------------------------------|
| ACTIVE    | Aktív          | 01968f18-a123-71a1-a123-45ef67890100 |
| PENDING   | Függőben       | 01968f18-b234-7890-b573-4a18075b0200 |
| EXPIRED   | Lejárt         | 01968f18-c345-70af-b28c-8712af440300 |
| REVOKED   | Visszavont     | 01968f18-d456-7f9f-955e-88b361f20400 |
| SUSPENDED | Felfüggesztett | 01968f18-e567-7a1a-1a1a-a1a1a1a10500 |

### DICTDEF# OPERATION_TYPE

```yaml
    label: OPERATION_TYPE
```

| Code          | Name                       | Id                                   |
|---------------|----------------------------|--------------------------------------|
| WITHDRAWAL    | Pénzfelvétel               | 01969019-a123-7a22-b345-01ac432d0100 |
| DEPOSIT       | Pénzbefizetés              | 01969019-b234-7b33-c456-12bd543e0200 |
| EXCHANGE      | Valutaváltás               | 01969019-c345-736a-9408-5cd3e99d0300 |
| DATA_CHANGE   | Adatmódosítás              | 01969019-d456-7d9b-9c77-003175230400 |
| VIEW_HISTORY  | Tranzakciótörténet lekérés | 01969019-e567-73a9-9420-c173e3f80500 |
| DOCUMENTATION | Dokumentáció igénylés      | 01969019-f678-71a1-a123-45ef67890600 |

### DICTDEF# REPRESENTATIVE_LOG_TYPE

```yaml
    label: REPRESENTATIVE_LOG_TYPE
```

| Code          | Name                   | Id                                   |
|---------------|------------------------|--------------------------------------|
| LOGIN         | Bejelentkezés          | 0196911a-a123-7a22-b345-01ac432d0100 |
| LOGOUT        | Kijelentkezés          | 0196911a-b234-7b33-c456-12bd543e0200 |
| TRANSACTION   | Tranzakció végrehajtás | 0196911a-c345-736a-9408-5cd3e99d0300 |
| DATA_UPDATE   | Adatmódosítás          | 0196911a-d456-7d9b-9c77-003175230400 |
| AUTH_CHANGE   | Jogosultság változás   | 0196911a-e567-73a9-9420-c173e3f80500 |
| DOC_UPLOAD    | Dokumentum feltöltés   | 0196911a-f678-71a1-a123-45ef67890600 |
| STATUS_CHANGE | Státusz változás       | 0196911a-0789-7890-b573-4a18075b0700 |
