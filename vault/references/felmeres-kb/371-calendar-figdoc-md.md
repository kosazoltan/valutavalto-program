---
title: calendar.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/calendar.figdoc.md
doc_type: text
---

# calendar.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 6.0 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/calendar.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# calendar

```yaml
    label: Naptár
    pluralLabel: Naptárak
    type: TABLE
```

| Field        | Label     | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description          | FT | Foreign  | FK | Hide |
|--------------|-----------|-------|------|----------|----------|--------|-----------|----------------------|----|----------|----|------|
| id           | Id        | IDENT |      |          |          |        |           |                      |    |          |    |      |
| day          | Nap       | DATE  |      |          |          |        |           |                      |    |          |    |      |
| day_of_week  | Hét napja | INT   | 1    |          |          |        |           | 1-7 (hétfő-vasárnap) |    |          |    |
| day_type_did | Naptípus  | DICT  |      |          |          |        |           |                      |    | DAY_TYPE |    |      |
| country_did  | Ország    | DICT  |      |          | X        |        |           |                      |    | COUNTRY  |    |      |

### FIGDEF# calendar_ext

```yaml
    label: Naptár
    pluralLabel: Naptárak
    type: EXTEND
    parent: calendar
```

| Field    | Label    | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign  | FK          | Replacement  | Hide |
|----------|----------|------------|------|----------|----------|--------|-----------|-------------|------|----------|-------------|--------------|------|
| day_type | Naptípus | Dictionary |      |          |          |        |           |             | DICT | DAY_TYPE | description | day_type_did |      |
| country  | Ország   | Dictionary |      |          |          |        |           |             | DICT | COUNTRY  | description | country_did  |      |

### FIGDEF# calendar_name_info

```yaml
    label: Calendar Name Info
    pluralLabel: Plural - Calendar Name Info
    type: TABLE
```

| Field        | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign   | FK |
|--------------|------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------|----|
| id           | Id         | IDENT   |      |          |          |        |           |             |       |           |    | 
| year_day     | Yearday    | INT     | 10   |          | X        |        |           |             |       |           |    | 
| name_info_id | Name Info  | FKIDENT |      |          | X        |        |           |             | TABLE | name_info |    | 
| is_primary   | Is Primary | BOOL    |      |          | X        |        |           |             |       |           |    | 
| is_starred   | Is Starred | BOOL    |      |          | X        |        |           |             |       |           |    | 

### FIGDEF# name_day

```yaml
    label: Névnap
    pluralLabel: Névnapok
    type: TABLE
```

| Field      | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|------------|------------|---------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id         | Id         | IDENT   |      |          |          |        |           |             |    |         |    | 
| first_name | Keresztnév | VARCHAR | 64   |          |          |        |           |             |    |         |    | 
| name_day   | Névnap     | VARCHAR | 4    |          |          |        |           |             |    |         |    | 

### FIGDEF# name_day_ext

```yaml
    label: Névnap
    pluralLabel: Névnapok
    type: EXTEND
    parent: name_day
```

| Field               | Label      | Type                    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                  | FK |
|---------------------|------------|-------------------------|------|----------|----------|--------|-----------|-------------|--------|--------------------------|----|
| person_name_day_ext | Névnaposok | List<PersonNameDayExt?> |      |          |          |        |           |             | EXTEND | list:person_name_day_ext |    | 

### FIGDEF# name_info

```yaml
    label: Name Info
    pluralLabel: Plural - Name Info
    type: TABLE
```

| Field           | Label           | Type  | Size  | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-----------------|-----------------|-------|-------|----------|----------|--------|-----------|-------------|----|---------|----|
| id              | Id              | IDENT |       |          |          |        |           |             |    |         |    | 
| first_name      | Keresztnév      | TEXT  | 65535 |          | X        |        |           |             |    |         |    | 
| unaccented_name | Unaccented Name | TEXT  | 65535 |          | X        |        |           |             |    |         |    | 
| commonness      | Commonness      | INT   | 10    |          | X        |        |           |             |    |         |    | 
| gender          | Gender          | INT   | 10    |          | X        |        |           |             |    |         |    | 
| origin          | Origin          | TEXT  | 65535 |          | X        |        |           |             |    |         |    | 
| nicknames       | Nicknames       | TEXT  | 65535 |          | X        |        |           |             |    |         |    | 
| related_names   | Related Names   | TEXT  | 65535 |          | X        |        |           |             |    |         |    | 
| opposite_names  | Opposite Names  | TEXT  | 65535 |          | X        |        |           |             |    |         |    | 
| foreign_names   | Foreign Names   | TEXT  | 65535 |          | X        |        |           |             |    |         |    |
