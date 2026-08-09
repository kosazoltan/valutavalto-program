---
title: figdef.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/figdef.figdoc.md
doc_type: text
---

# figdef.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 2.4 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/figdef.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

### FIGDEF# figdef

```yaml
    label: Adatcsoport
    pluralLabel: Plural - Adatcsoportok
    type: TABLE
```

| Field     | Label             | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK        |
|-----------|-------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|-----------|
| id        | Id                | IDENT   |      |          |          |        |           |             |       |         |           | 
| name      | Adatcsoport kódja | VARCHAR | 255  |          |          |        |           |             |       |         |           | 
| label     | Adatcsoport neve  | VARCHAR | 1023 |          |          |        |           |             |       |         |           | 
| figdef_id | Szülő-adatcsoport | FKIDENT |      |          | X        |        |           |             | TABLE | figdef  | figdef.id | 
| visible   | Láthatóság        | BOOL    |      |          | X        |        |           |             |       |         |           | 

### FIGDEF# figdef_ext

```yaml
    label: Adatcsoport
    pluralLabel: Adatcsoportok
    type: EXTEND
    parent: figdef
```

| Field    | Label             | Type             | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign         | FK   | Replacement |
|----------|-------------------|------------------|------|----------|----------|--------|-----------|-------------|--------|-----------------|------|-------------|
| figdef   | Szülő-adatcsoport | Figdef           |      |          |          |        |           |             | DTO    | figdef          | name | figdef_id   |
| children | Aladatcsoportok   | List<FigdefExt?> |      |          |          |        |           |             | EXTEND | list:figdef_ext |      |             |
| canview  | Megtekintheti     | TINYINT          | 3    |          | X        |        |           |             | NORMAL |                 |      |             |
| canedit  | Szerkesztheti     | TINYINT          | 3    |          | X        |        |           |             | NORMAL |                 |      |             |
