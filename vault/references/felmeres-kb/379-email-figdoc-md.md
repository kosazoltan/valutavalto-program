---
title: email.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/email.figdoc.md
doc_type: text
---

# email.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 1.8 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/email.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Dokumentum célja

A dokumentum célja a email modul adatmodeljének leírása.

## Entitások

### FIGDEF# email

```yaml
    label: Email
    pluralLabel: Emailek
    type: TABLE
```

| Field      | Label                | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK      | Hide |
|------------|----------------------|----------|------|----------|----------|--------|-----------|-------------|-------|---------|---------|------|
| id         | Id                   | IDENT    |      |          |          |        |           |             |       |         |         |      |
| email_uid  | Email UID            | VARCHAR  | 512  |          |          |        |           |             |       |         |         | X    |
| recv_date  | Levél dátuma         | DATETIME | 19   |          |          |        |           |             |       |         |         |      |
| sender     | Feladó               | VARCHAR  | 512  |          |          |        |           |             |       |         |         |      |
| recipients | Címzettek            | VARCHAR  | 1024 |          |          |        |           |             |       |         |         |      |
| subject    | Subject              | VARCHAR  | 2048 |          |          |        |           |             |       |         |         |      |
| content    | Tartalom             | LONGBLOB |      |          | X        |        |           |             |       |         |         | X    |
| task_id    | Hozzárendelt feladat | FKIDENT  |      |          | X        |        |           |             | TABLE | task    | task.id |      |
