---
title: document.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/document.figdoc.md
doc_type: text
---

# document.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 11.1 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/document.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# document

```yaml
    label: Dokumentum
    pluralLabel: Dokumentumok
    type: TABLE
```

| Field               | Label               | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK               |
|---------------------|---------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|------------------|
| id                  | Id                  | IDENT   |      |          |          |        |           |             |       |                 |                  | 
| document_rule_id    | Dokumentum fajtája  | FKIDENT |      |          |          |        |           |             | TABLE | document_rule   | document_rule.id | 
| document_number     | Dokumentum száma    | VARCHAR | 256  |          | X        |        |           |             |       |                 |                  | 
| name                | Név                 | VARCHAR | 2048 |          | X        |        |           |             |       |                 |                  | 
| document_id         | Előzmény dokumentum | FKIDENT |      |          | X        |        |           |             | TABLE | document        | document.id      | 
| valid_from_date     | Érvényes-től        | DATE    |      |          | X        |        |           |             |       |                 |                  | 
| valid_to_date       | Érvényes-ig         | DATE    |      |          | X        |        |           |             |       |                 |                  | 
| note                | Megjegyzés          | VARCHAR | 2048 |          | X        |        |           |             |       |                 |                  | 
| date_of_signature   | Aláírás dátuma      | DATE    |      |          | X        |        |           |             |       |                 |                  | 
| country_did         | Ország              | DICT    |      |          | X        |        |           |             |       | COUNTRY         |                  | 
| language_did        | Nyelv               | DICT    |      |          | X        |        |           |             |       | LANGUAGE        |                  | 
| document_status_did | Dokumentum állapota | DICT    |      |          |          |        |           |             |       | DOCUMENT_STATUS |                  | 

### FIGDEF# document_ext

```yaml
    label: Dokumentum
    pluralLabel: Dokumentumok
    type: EXTEND
    parent: document
```

| Field           | Label               | Type                   | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign         | FK          | Replacement         |
|-----------------|---------------------|------------------------|------|----------|----------|--------|-----------|-------------|--------|-----------------|-------------|---------------------|
| document_rule   | Document Rule       | DocumentRule           |      |          |          |        |           |             | DTO    | document_rule   | name        | document_rule_id    |
| former_document | Előzmény dokumentum | Document               |      |          |          |        |           |             | DTO    | document        | name        | document_id         |
| files           | Fájlok              | List<FileWithoutBlob?> |      |          |          |        |           |             | EXTEND | list:file       |             |                     |
| country         | Ország              | Dictionary             |      |          |          |        |           |             | DICT   | COUNTRY         | description | country_did         |
| language        | Nyelv               | Dictionary             |      |          |          |        |           |             | DICT   | LANGUAGE        | description | language_did        |
| document_status | Document Status     | Dictionary             |      |          |          |        |           |             | DICT   | DOCUMENT_STATUS | description | document_status_did |

### FIGDEF# document_rule

```yaml
    label: Dokumentum fajtája
    pluralLabel: Dokumentum fajtái
    type: TABLE
```

| Field                      | Label                     | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign       | FK               |
|----------------------------|---------------------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------------|------------------|
| id                         | Id                        | IDENT    |      |          |          |        |           |             |       |               |                  | 
| name                       | Név                       | VARCHAR  | 256  |          |          |        |           |             |       |               |                  | 
| code                       | Kód                       | VARCHAR  | 32   |          |          |        |           |             |       |               |                  | 
| document_rule_id           | Dokumentum fajtája        | FKIDENT  |      |          | X        |        |           |             | TABLE | document_rule | document_rule.id | 
| subject_did                | Tárgy                     | DICT     |      |          | X        |        |           |             |       | SUBJECT       |                  | 
| obligation_did             | Kötelezettség             | DICT     |      |          | X        |        |           |             |       | OBLIGATION    |                  | 
| validity_type_did          | Érvényesség típusa        | DICT     |      |          | X        |        |           |             |       | VALIDITY_TYPE |                  | 
| validity                   | Érvényesség               | VARCHAR  | 32   |          | X        |        |           |             |       |               |                  | 
| notification_before_expiry | Értesítés lejárat előtt   | SMALLINT | 5    |          | X        |        |           |             |       |               |                  | 
| template                   | Sablon                    | BIGINT   |      |          | X        |        |           |             |       |               |                  | 
| valid_from_date            | Érvényes-től              | DATE     |      |          | X        |        |           |             |       |               |                  | 
| valid_to_date              | Érvényes-ig               | DATE     |      |          | X        |        |           |             |       |               |                  | 
| interpretable_attributes   | Értelmezhető attribútumok | VARCHAR  | 2048 |          | X        |        |           |             |       |               |                  | 

### FIGDEF# document_rule_ext

```yaml
    label: Dokumentum fajtája
    pluralLabel: Dokumentum fajtái
    type: EXTEND
    parent: document_rule
```

| Field         | Label              | Type         | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign       | FK          | Replacement       |
|---------------|--------------------|--------------|------|----------|----------|--------|-----------|-------------|------|---------------|-------------|-------------------|
| document_rule | Document Rule      | DocumentRule |      |          |          |        |           |             | DTO  | document_rule | name        | document_rule_id  | 
| subject       | Objektum           | Dictionary   |      |          |          |        |           |             | DICT | SUBJECT       | description | subject_did       |
| obligation    | Kötelezettség      | Dictionary   |      |          |          |        |           |             | DICT | OBLIGATION    | description | obligation_did    |
| validity_type | Érvényesség típusa | Dictionary   |      |          |          |        |           |             | DICT | VALIDITY_TYPE | description | validity_type_did |

### FIGDEF# file

```yaml
    label: Fájl
    pluralLabel: Fájlok
    type: TABLE
```

| Field         | Label         | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          |
|---------------|---------------|----------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|
| id            | Id            | IDENT    |      |          |          |        |           |             |       |          |             | 
| document_id   | Dokumentum    | FKIDENT  |      |          |          |        |           |             | TABLE | document | document.id | 
| file_name     | Fájl név      | VARCHAR  | 256  |          |          |        |           |             |       |          |             | 
| file_datetime | Fájl dátuma   | DATETIME |      |          |          |        |           |             |       |          |             | 
| mime_type     | Mime típus    | VARCHAR  | 256  |          |          |        |           |             |       |          |             | 
| file_size     | Fájl mérete   | BIGINT   |      |          |          |        |           |             |       |          |             | 
| file_content  | Fájl tartalma | LONGBLOB |      |          |          |        |           |             |       |          |             | 
| note          | Megjegyzés    | VARCHAR  | 2048 |          | X        |        |           |             |       |          |             | 

### FIGDEF# file_without_blob

```yaml
    label: Fájl
    pluralLabel: Fájlok
    type: DTO
```

| Field         | Label       | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          |
|---------------|-------------|----------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|
| id            | Id          | IDENT    |      |          |          |        |           |             |       |          |             | 
| document_id   | Dokumentum  | UUID     | 36   | 0        |          |        |           |             | TABLE | document | document.id | 
| file_name     | Fájl név    | VARCHAR  | 256  |          |          |        |           |             |       |          |             | 
| file_datetime | Fájl dátuma | DATETIME | 19   |          |          |        |           |             |       |          |             | 
| mime_type     | Mime típus  | VARCHAR  | 256  |          |          |        |           |             |       |          |             | 
| file_size     | Fájl mérete | BIGINT   | 19   |          |          |        |           |             |       |          |             | 
| note          | Megjegyzés  | VARCHAR  | 2048 |          | X        |        |           |             |       |          |             |
