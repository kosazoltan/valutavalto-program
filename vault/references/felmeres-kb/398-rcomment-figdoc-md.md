---
title: rcomment.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/rcomment.figdoc.md
doc_type: text
---

# rcomment.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 2.0 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/rcomment.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

### FIGDEF# rcomment

```yaml
    label: Megjegyzés
    pluralLabel: Plural - Megjegyzések
    type: TABLE
```

| Field            | Label                | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK       |
|------------------|----------------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------|----------|
| id               | Id                   | IDENT    |      |          |          |        |           |             |       |         |          | 
| cgroup           | Megjegyzés csoport   | VARCHAR  | 64   |          |          |        |           |             |       |         |          | 
| cid              | Megjegyzés entitás   | VARCHAR  | 64   |          |          |        |           |             |       |         |          | 
| commenttxt       | megjegyzés szövege   | LONGTEXT |      |          |          |        |           |             |       |         |          | 
| ruser_id         | Felhasználó          | FKIDENT  |      |          |          |        |           |             | TABLE | ruser   | ruser.id | 
| comment_datetime | Megjegyzés időpontja | DATETIME |      |          |          |        |           |             |       |         |          | 

### FIGDEF# rcomment_ext

```yaml
    label: Megjegyzés
    pluralLabel: Megjegyzések
    type: EXTEND
    parent: rcomment
```

| Field | Label | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK        | Replacement |
|-------|-------|-------|------|----------|----------|--------|-----------|-------------|-----|---------|-----------|-------------|
| ruser | Ruser | Ruser |      |          |          |        |           |             | DTO | ruser   | user_name | ruser_id    |
