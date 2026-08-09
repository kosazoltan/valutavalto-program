---
title: task.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/task.figdoc.md
doc_type: text
---

# task.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 1.3 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/task.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Dokumentum célja

A dokumentum célja a email modul adatmodeljének leírása.

## Entitások

### FIGDEF# task

```yaml
    label: Feladat
    pluralLabel: Feladatok
    type: TABLE
```

| Field              | Label        | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign        | FK |
|--------------------|--------------|----------|------|----------|----------|--------|-----------|-------------|----|----------------|----|
| id                 | Id           | IDENT    |      |          |          |        |           |             |    |                |    |
| name               | Név          | VARCHAR  | 512  |          |          |        |           |             |    |                |    |
| description        | Leírás       | VARCHAR  | 1024 |          |          |        |           |             |    |                |    |
| task_rule_type_did | Szabálytípus | DICT     |      |          |          |        |           |             |    | TASK_RULE_TYPE |    | 
| rule               | Szabály      | LONGTEXT |      |          | X        |        |           |             |    |                |    |
