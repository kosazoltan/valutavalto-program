---
title: inst_loc.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/inst_loc.figdoc.md
doc_type: text
---

# inst_loc.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 6.3 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/inst_loc.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# inst_loc

```yaml
    label: Telepítési hely
    pluralLabel: Telepítési helyek
    type: TABLE
```

| Field           | Label                       | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         | Hide |
|-----------------|-----------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|------|
| id              | Id                          | IDENT   |      |          |          |        |           |             |       |         |            |      |
| inst_loc_code   | Telepítési hely kód         | VARCHAR | 32   |          |          |        |           |             |       |         |            |      |
| partner_id      | Partner                     | FKIDENT |      |          |          |        |           |             | TABLE | partner | partner.id |      |
| name            | Név                         | VARCHAR | 256  |          |          |        |           |             |       |         |            |      |
| valid_from_date | Érvényes-től                | DATE    |      |          | X        |        |           |             |       |         |            |      |
| valid_to_date   | Érvényes-ig                 | DATE    |      |          |          |        |           |             |       |         |            |      |
| note            | Megjegyzés                  | VARCHAR | 2048 |          | X        |        |           |             |       |         |            |      |
| country_did     | Ország                      | DICT    |      |          |          |        |           |             |       | COUNTRY |            |      |
| zip_code        | Irányítószám                | VARCHAR | 10   |          |          |        |           |             |       |         |            |      |
| settlement      | Település                   | VARCHAR | 128  |          |          |        |           |             |       |         |            |      |
| street_house    | Utca, házszám               | VARCHAR | 512  |          |          |        |           |             |       |         |            |      |
| spec_access     | Speciális megközelíthetőség | VARCHAR | 1024 |          | X        |        |           |             |       |         |            |      |
| description     | Leírás                      | VARCHAR | 2048 |          | X        |        |           |             |       |         |            |      |

### FIGDEF# inst_loc_ext

```yaml
    label: Telepítési hely
    pluralLabel: Telepítési helyek
    type: EXTEND
    parent: inst_loc
```

| Field   | Label  | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign | FK          | Replacement |
|---------|--------|------------|------|----------|----------|--------|-----------|-------------|------|---------|-------------|-------------|
| country | Ország | Dictionary |      |          |          |        |           |             | DICT | COUNTRY | description | country_did |

### FIGDEF# inst_loc_with_partner_ext

```yaml
    label: Telepítési hely
    pluralLabel: Telepítési helyek
    type: EXTEND
    parent: inst_loc
```

| Field   | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign | FK          | Replacement | Hide |
|---------|---------|------------|------|----------|----------|--------|-----------|-------------|--------|---------|-------------|-------------|------|
| partner | Partner | Partner    |      |          |          |        |           |             | EXTEND | partner | short_name  | partner_id  |      |
| country | Ország  | Dictionary |      |          |          |        |           |             | DICT   | COUNTRY | description | country_did |      |

### FIGDEF# inst_loc_without_partner_ext

```yaml
    label: Telepítési hely
    pluralLabel: Telepítési helyek
    type: EXTEND
    parent: inst_loc
```

| Field   | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign | FK          | Replacement | Hide |
|---------|---------|------------|------|----------|----------|--------|-----------|-------------|--------|---------|-------------|-------------|------|
| partner | Partner | Partner    |      |          |          |        |           |             | EXTEND | partner |             |             | X    |
| country | Ország  | Dictionary |      |          |          |        |           |             | DICT   | COUNTRY | description | country_did |      |

### FIGDEF# inst_loc_document

```yaml
    label: Telepítési hely dokumentum
    pluralLabel: Telepítési hely dokumentumok
    type: TABLE
```

| Field       | Label           | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          |
|-------------|-----------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|
| id          | Id              | IDENT   |      |          |          |        |           |             |       |          |             | 
| inst_loc_id | Telepítési hely | FKIDENT |      |          |          |        |           |             | TABLE | inst_loc | inst_loc.id | 
| document_id | Dokumentum      | FKIDENT |      |          |          |        |           |             | TABLE | document | document.id | 

### FIGDEF# inst_loc_document_ext

```yaml
    label: Telepítési hely dokumentum
    pluralLabel: Telepítési hely dokumentumok
    type: EXTEND
    parent: inst_loc_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |
