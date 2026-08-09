---
title: carrental.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/carrental.figdoc.md
doc_type: text
---

# carrental.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 11.5 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/carrental.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# carrental

```yaml
    label: Autókölcsönző
    pluralLabel: Autókölcsönzők
    type: TABLE
```

| Field              | Label            | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign        | FK |
|--------------------|------------------|---------|------|----------|----------|--------|-----------|-------------|----|----------------|----|
| id                 | Id               | IDENT   |      |          |          |        |           |             |    |                |    | 
| short_name         | Rövid név        | VARCHAR | 256  |          |          |        |           |             |    |                |    | 
| name               | Név              | VARCHAR | 2048 |          |          |        |           |             |    |                |    | 
| company_form_did   | Cégforma         | DICT    |      |          |          |        |           |             |    | COMPANY_FORM   |    | 
| partner_status_did | Partner állapota | DICT    |      |          |          |        |           |             |    | PARTNER_STATUS |    | 
| code               | Kód              | VARCHAR | 32   |          | X        |        |           |             |    |                |    | 
| tax_number         | Adószám          | VARCHAR | 32   |          | X        |        |           |             |    |                |    | 
| eu_tax_number      | EU adószám       | VARCHAR | 32   |          | X        |        |           |             |    |                |    | 
| country_did        | Ország           | DICT    |      |          |          |        |           |             |    | COUNTRY        |    | 
| zip_code           | Irányítószám     | VARCHAR | 10   |          |          |        |           |             |    |                |    | 
| settlement         | Település        | VARCHAR | 128  |          |          |        |           |             |    |                |    | 
| street_house       | Utca, házszám    | VARCHAR | 512  |          |          |        |           |             |    |                |    | 

### FIGDEF# carrental_ext

```yaml
    label: Autókölcsönző
    pluralLabel: Autókölcsönzők
    type: EXTEND
    parent: carrental
```

| Field              | Label                 | Type                       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                    | FK          | Replacement        | Hide |
|--------------------|-----------------------|----------------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------------|-------------|--------------------|------|
| company_form       | Cégforma              | Dictionary                 |      |          |          |        |           |             | DICT   | COMPANY_FORM               | description | company_form_did   |      |
| partner_status     | Partner állapota      | Dictionary                 |      |          |          |        |           |             | DICT   | PARTNER_STATUS             | description | partner_status_did |      |
| country            | Ország                | Dictionary                 |      |          |          |        |           |             | DICT   | COUNTRY                    | description | country_did        |      |
| own_contacts       | Saját kapcsolattartók | List<OwnContactExt?>       |      |          |          |        |           |             | EXTEND | list:own_contact_ext       |             |                    | X    |
| carrental_contacts | Kapcsolattartók       | List<CarrentalContactExt?> |      |          |          |        |           |             | EXTEND | list:carrental_contact_ext |             |                    | X    |

### FIGDEF# carrental_contact

```yaml
    label: Autókölcsönző kapcsolat
    pluralLabel: Autókölcsönző kapcsolatok
    type: TABLE
```

| Field            | Label            | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign      | FK           |
|------------------|------------------|----------|------|----------|----------|--------|-----------|-------------|-------|--------------|--------------|
| id               | Id               | IDENT    |      |          |          |        |           |             |       |              |              | 
| contact_type_did | Kapcsolat típusa | DICT     |      |          |          |        |           |             |       | CONTACT_TYPE |              | 
| last_name        | Vezetéknév       | VARCHAR  | 128  |          | X        |        |           |             |       |              |              | 
| first_name       | Keresztnév       | VARCHAR  | 128  |          | X        |        |           |             |       |              |              | 
| title            | Titulus          | VARCHAR  | 32   |          | X        |        |           |             |       |              |              | 
| carrental_id     | Autókölcsönző    | FKIDENT  |      |          |          |        |           |             | TABLE | carrental    | carrental.id | 
| contact          | Kapcsolat        | VARCHAR  | 256  |          |          |        |           |             |       |              |              | 
| rank             | Rang             | SMALLINT | 5    |          | X        |        |           |             |       |              |              | 

### FIGDEF# carrental_contact_ext

```yaml
    label: Autókölcsönző kapcsolat
    pluralLabel: Autókölcsönző kapcsolatok
    type: EXTEND
    parent: carrental_contact
```

| Field                        | Label                              | Type                               | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                             | FK          | Replacement      | Hide |
|------------------------------|------------------------------------|------------------------------------|------|----------|----------|--------|-----------|-------------|--------|-------------------------------------|-------------|------------------|------|
| contact_type                 | Kapcsolat típusa                   | Dictionary                         |      |          |          |        |           |             | DICT   | CONTACT_TYPE                        | description | contact_type_did |      |
| carrental_contact_categories | Autókölcsönző kapcsolat kategória  | List<CarrentalContactCategoryExt?> |      |          |          |        |           |             | EXTEND | list:carrental_contact_category_ext |             |                  | X    |
| carrental_contact_infos      | Autókölcsönző kapcsolat információ | List<CarrentalContactInfoExt?>     |      |          |          |        |           |             | EXTEND | list:carrental_contact_info_ext     |             |                  | X    |

### FIGDEF# carrental_contact_category

```yaml
    label: Autókölcsönző kapcsolat kategória
    pluralLabel: Autókölcsönző kapcsolat kategóriák
    type: TABLE
```

| Field                | Label                   | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign           | FK                        |
|----------------------|-------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-------------------|---------------------------|
| id                   | Id                      | IDENT   |      |          |          |        |           |             |       |                   |                           | 
| carrental_contact_id | Autókölcsönző kapcsolat | FKIDENT |      |          |          |        |           |             | TABLE | carrental_contact | carrental_contact_info.id | 
| category_id          | Kategória               | FKIDENT |      |          |          |        |           |             | TABLE | category          | category.id               | 
| valid_from_date      | Érvényes-től            | DATE    |      |          | X        |        |           |             |       |                   |                           | 
| valid_to_date        | Érvényes-ig             | DATE    |      |          | X        |        |           |             |       |                   |                           | 

### FIGDEF# carrental_contact_category_ext

```yaml
    label: Autókölcsönző kapcsolat kategória
    pluralLabel: Autókölcsönző kapcsolat kategóriák
    type: EXTEND
    parent: carrental_contact_category
```

| Field    | Label     | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK       | Replacement |
|----------|-----------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|----------|-------------|
| category | Kategória | CategoryExt |      |          |          |        |           |             | EXTEND | category_ext | category | category_id |

### FIGDEF# carrental_contact_info

```yaml
    label: Autókölcsönző kapcsolat információ
    pluralLabel: Autókölcsönző kapcsolat információk
    type: TABLE
```

| Field                | Label                   | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign           | FK                   |
|----------------------|-------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-------------------|----------------------|
| id                   | Id                      | IDENT   |      |          |          |        |           |             |       |                   |                      | 
| carrental_contact_id | Autókölcsönző kapcsolat | FKIDENT |      |          |          |        |           |             | TABLE | carrental_contact | carrental_contact.id | 
| contact_type_did     | Kapcsolat típusa        | DICT    |      |          |          |        |           |             |       | CONTACT_TYPE      |                      | 
| info                 | Információ              | VARCHAR | 256  |          |          |        |           |             |       |                   |                      | 
| valid_from_date      | Érvényes-től            | DATE    |      |          | X        |        |           |             |       |                   |                      | 
| valid_to_date        | Érvényes-ig             | DATE    |      |          | X        |        |           |             |       |                   |                      | 

### FIGDEF# carrental_contact_info_ext

```yaml
    label: Autókölcsönző kapcsolatok információ
    pluralLabel: Autókölcsönző kapcsolatok információi
    type: EXTEND
    parent: carrental_contact_info
```

| Field        | Label            | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign      | FK          | Replacement      |
|--------------|------------------|------------|------|----------|----------|--------|-----------|-------------|------|--------------|-------------|------------------|
| contact_type | Kapcsolat típusa | Dictionary |      |          |          |        |           |             | DICT | CONTACT_TYPE | description | contact_type_did |
