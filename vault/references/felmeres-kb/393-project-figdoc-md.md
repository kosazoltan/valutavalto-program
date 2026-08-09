---
title: project.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/project.figdoc.md
doc_type: text
---

# project.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 12.9 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/project.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

### FIGDEF# project

```yaml
    label: Projekt
    pluralLabel: Projektek
    type: TABLE
```

| Field                    | Label                  | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign              | FK          | SubType  | Hide |
|--------------------------|------------------------|----------|------|----------|----------|--------|-----------|-------------|-------|----------------------|-------------|----------|------|
| id                       | Id                     | IDENT    |      |          |          |        |           |             |       |                      |             |          |      |
| project_code             | Munkaszám              | VARCHAR  | 32   |          |          |        |           |             |       |                      |             |          |      |
| name                     | Projekt elnevezése     | VARCHAR  | 1024 |          | X        |        |           |             |       |                      |             |          |      |
| company_id               | Cég                    | FKIDENT  |      |          |          |        |           |             | TABLE | company              | company.id  |          |      |
| partner_id               | Partner                | FKIDENT  |      |          |          |        |           |             | TABLE | partner              | partner.id  |          |      |
| inst_loc_id              | Telepítési hely        | FKIDENT  |      |          |          |        |           |             | TABLE | inst_loc             | inst_loc.id |          |      |
| valid_from_date          | Érvényes-től           | DATE     |      |          |          |        |           |             |       |                      |             |          |      |
| valid_to_date            | Érvényes-ig            | DATE     |      |          | X        |        |           |             |       |                      |             |          |      |
| project_date             | Projekt dátuma         | DATE     |      |          | X        |        |           |             |       |                      |             |          |      |
| project_status_did       | Projekt állapota       | DICT     |      |          |          |        |           |             |       | project_STATUS       |             |          |      |
| settlement_basis_did     | Elszámolás alapja      | DICT     |      |          | X        |        |           |             |       | SETTLEMENT_BASIS     |             |          |      |
| settlement_frequency_did | Elszámolás gyakorisága | DICT     |      |          | X        |        |           |             |       | SETTLEMENT_FREQUENCY |             |          |      |
| payment_deadline         | Fizetési határidő      | SMALLINT | 5    |          | X        |        |           |             |       |                      |             |          |      |
| technical_content        | Műszaki tartalom       | LONGTEXT |      |          | X        |        |           |             |       |                      |             |          | X    |
| note                     | Megjegyzés             | VARCHAR  | 2048 |          | X        |        |           |             |       |                      |             |          |      |
| margin                   | Árrés                  | DECIMAL  | 19   | 2        | X        |        |           |             |       |                      |             | PERCENT  |      |    
| hourly_rate              | Óradíj                 | DECIMAL  | 19   | 2        | X        |        |           |             |       |                      |             | CURRENCY |      |
| distance_fee             | Távolsági díj          | DECIMAL  | 19   | 2        | X        |        |           |             |       |                      |             | CURRENCY |      |
| departure_fee            | Kiszállási díj         | DECIMAL  | 19   | 2        | X        |        |           |             |       |                      |             | CURRENCY |      |

---

### FIGDEF# project_ext

```yaml
    label: Projekt
    pluralLabel: Projektek
    type: EXTEND
    parent: project
```

| Field                | Label                  | Type                      | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                   | FK          | Replacement              |
|----------------------|------------------------|---------------------------|------|----------|----------|--------|-----------|-------------|--------|---------------------------|-------------|--------------------------|
| inst_loc             | Telepítési hely        | InstLoc                   |      |          |          |        |           |             | DTO    | inst_loc                  | name        | inst_loc_id              |
| project_status       | Projekt állapota       | Dictionary                |      |          |          |        |           |             | DICT   | project_STATUS            | description | project_status_did       |
| project_documents    | íprojekt Document      | List<ProjectDocumentExt?> |      |          |          |        |           |             | EXTEND | list:project_document_ext |             |                          |
| company              | Cég                    | Company                   |      |          |          |        |           |             | DTO    | company                   | name        | company_id               |
| settlement_basis     | Elszámolás alapja      | Dictionary                |      |          |          |        |           |             | DICT   | SETTLEMENT_BASIS          | description | settlement_basis_did     |
| settlement_frequency | Elszámolás gyakorisága | Dictionary                |      |          |          |        |           |             | DICT   | SETTLEMENT_FREQUENCY      | description | settlement_frequency_did |

---

### FIGDEF# project_from_menu_ext

```yaml
    label: Projekt
    pluralLabel: Projektek
    type: EXTEND
    parent: project
```

| Field                     | Label                  | Type                      | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                   | FK          | Replacement              |
|---------------------------|------------------------|---------------------------|------|----------|----------|--------|-----------|-------------|--------|---------------------------|-------------|--------------------------|
| partner                   | Partner                | Partner                   |      |          |          |        |           |             | DTO    | partner                   | short_name  | partner_id               |
| inst_loc_with_partner_ext | Telepítési hely        | InstLocWithPartnerExt     |      |          |          |        |           |             | EXTEND | inst_loc_with_partner_ext | name        | inst_loc_id              |
| project_status            | Projekt állapota       | Dictionary                |      |          |          |        |           |             | DICT   | project_STATUS            | description | project_status_did       |
| project_documents         | Projekt Document       | List<ProjectDocumentExt?> |      |          |          |        |           |             | EXTEND | list:project_document_ext |             |                          |
| company                   | Cég                    | Company                   |      |          |          |        |           |             | DTO    | company                   | name        | company_id               |
| settlement_basis          | Elszámolás alapja      | Dictionary                |      |          |          |        |           |             | DICT   | SETTLEMENT_BASIS          | description | settlement_basis_did     |
| settlement_frequency      | Elszámolás gyakorisága | Dictionary                |      |          |          |        |           |             | DICT   | SETTLEMENT_FREQUENCY      | description | settlement_frequency_did |

---

### FIGDEF# project_by_company_ext

```yaml
    label: Céges project
    pluralLabel: Céges projectek
    type: EXTEND
    parent: project
```

| Field                | Label                  | Type                      | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                   | FK          | Replacement              |
|----------------------|------------------------|---------------------------|------|----------|----------|--------|-----------|-------------|--------|---------------------------|-------------|--------------------------|
| inst_loc             | Telepítési hely        | InstLoc                   |      |          |          |        |           |             | DTO    | inst_loc                  | name        | inst_loc_id              |
| project_status       | Projekt állapota       | Dictionary                |      |          |          |        |           |             | DICT   | project_STATUS            | description | project_status_did       |
| project_documents    | Projekt Document       | List<ProjectDocumentExt?> |      |          |          |        |           |             | EXTEND | list:project_document_ext |             |                          |
| partner              | Partner                | PartnerExt                |      |          |          |        |           |             | EXTEND | partner_ext               | name        | partner_id               |
| settlement_basis     | Elszámolás alapja      | Dictionary                |      |          |          |        |           |             | DICT   | SETTLEMENT_BASIS          | description | settlement_basis_did     |
| settlement_frequency | Elszámolás gyakorisága | Dictionary                |      |          |          |        |           |             | DICT   | SETTLEMENT_FREQUENCY      | description | settlement_frequency_did |

---

### FIGDEF# project_document

```yaml
    label: Projekt dokumentum
    pluralLabel: Projekt dokumentumok
    type: TABLE
```

| Field       | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          |
|-------------|------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|
| id          | Id         | IDENT   |      |          |          |        |           |             |       |          |             | 
| project_id  | Projekt    | FKIDENT |      |          |          |        |           |             | TABLE | project  | project.id  | 
| document_id | Dokumentum | FKIDENT |      |          |          |        |           |             | TABLE | document | document.id | 

---

### FIGDEF# project_document_ext

```yaml
    label: Projekt dokumentum
    pluralLabel: Projekt dokumentumok
    type: EXTEND
    parent: project_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

---

### FIGDEF# settlement

```yaml
    label: Elszámolás
    pluralLabel: Elszámolások
    type: TABLE
```

| Field      | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         |
|------------|------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|
| id         | Id         | IDENT   |      |          |          |        |           |             |       |         |            |
| project_id | Projekt    | FKIDENT |      |          |          |        |           |             | TABLE | project | project.id | 
| note       | Megjegyzés | VARCHAR | 2048 |          | X        |        |           |             |       |         |            | 

---

### FIGDEF# settlement_ext

```yaml
    label: Elszámolás
    pluralLabel: Elszámolások
    type: EXTEND
    parent: settlement
```

| Field   | Label   | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|---------|---------|---------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| project | Projekt | Project |      |          |          |        |           |             | DTO | project | name | project_id  |
