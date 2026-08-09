---
title: demand.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/demand.figdoc.md
doc_type: text
---

# demand.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 5.1 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/demand.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# demand

```yaml
    label: Igény
    pluralLabel: Igények
    type: TABLE
```

| Field             | Label            | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign       | FK          |
|-------------------|------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------|-------------|
| id                | Id               | IDENT   |      |          |          |        |           |             |       |               |             | 
| contract_id       | Szerződés        | FKIDENT |      |          |          |        |           |             | TABLE | contract      | contract.id | 
| demand_status_did | Igény állapota   | DICT    |      |          |          |        |           |             |       | DEMAND_STATUS |             | 
| task_type_did     | Feladat típusa   | DICT    |      |          | X        |        |           |             |       | TASK_TYPE     |             | 
| description       | Leírás           | VARCHAR | 2048 |          | X        |        |           |             |       |               |             | 
| begin_date        | Kezdés dátuma    | DATE    |      |          | X        |        |           |             |       |               |             | 
| end_date          | Befejezés dátuma | DATE    |      |          | X        |        |           |             |       |               |             | 

### FIGDEF# demand_ext

```yaml
    label: Igény
    pluralLabel: Igények
    type: EXTEND
    parent: demand
```

| Field         | Label          | Type                 | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign              | FK          | Replacement       | Hide |
|---------------|----------------|----------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------|-------------|-------------------|------|
| contract      | Szerződés      | ContractExt          |      |          |          |        |           |             | EXTEND | contract_ext         | code        | contract_id       |      |
| demand_status | Igény állapota | Dictionary           |      |          |          |        |           |             | DICT   | DEMAND_STATUS        | description | demand_status_did |      |
| task_type     | Feladat típusa | Dictionary           |      |          |          |        |           |             | DICT   | TASK_TYPE            | description | task_type_did     |      |
| demand_items  | Demand Item    | List<DemandItemExt?> |      |          |          |        |           |             | EXTEND | list:demand_item_ext |             |                   | X    |

### FIGDEF# demand_item

```yaml
    label: Igény elem
    pluralLabel: Igény elemek
    type: TABLE
```

| Field                      | Label               | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK        |
|----------------------------|---------------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------|-----------|
| id                         | Id                  | IDENT    |      |          |          |        |           |             |       |         |           | 
| demand_id                  | Igény               | FKIDENT  |      |          |          |        |           |             | TABLE | demand  | demand.id | 
| hall_id                    | Részleg             | FKIDENT  |      |          | X        |        |           |             | TABLE | hall    | hall.id   | 
| begin_date                 | Kezdés dátuma       | DATE     |      |          |          |        |           |             |       |         |           | 
| end_date                   | Befejezés dátuma    | DATE     |      |          | X        |        |           |             |       |         |           | 
| head                       | Létszám             | SMALLINT | 5    |          | X        |        |           |             |       |         |           | 
| work_clothes_provided_flag | Munkaruhát biztosít | BOOL     |      |          | X        |        |           |             |       |         |           | 
| description                | Leírás              | VARCHAR  | 2048 |          | X        |        |           |             |       |         |           | 

### FIGDEF# demand_item_ext

```yaml
    label: Igény elem
    pluralLabel: Igény elemek
    type: EXTEND
    parent: demand_item
```

| Field | Label   | Type | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|-------|---------|------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| hall  | Részleg | Hall |      |          |          |        |           |             | DTO | hall    | name | hall_id     |
