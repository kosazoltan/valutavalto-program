---
title: postal.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/postal.figdoc.md
doc_type: text
---

# postal.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 1.1 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/postal.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

### FIGDEF# postalcode

```yaml
    label: Irányítószám-Település
    pluralLabel: Irányítószámok-Települések
    type: TABLE
```

| Field      | Label        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|------------|--------------|---------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id         | Id           | IDENT   |      |          |          |        |           |             |    |         |    | 
| code       | Irányítószám | VARCHAR | 16   |          |          |        |           |             |    |         |    | 
| settlement | Település    | VARCHAR | 64   |          |          |        |           |             |    |         |    | 
| province   | Tartomány    | VARCHAR | 64   |          | X        |        |           |             |    |         |    |
