---
title: geprix.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/geprix.figdoc.md
doc_type: text
---

# geprix.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 12.6 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/geprix.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# seq_seq_generated_file

```yaml
    label: Seq Seq Generated File
    pluralLabel: Plural - Seq Seq Generated File
    type: TABLE
```

| Field | Label | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|-------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT |      |          |          |        |           |             |    |         |    | 
| dummy | Dummy | INT   | 10   |          | X        |        |           |             |    |         |    | 

### FIGDEF# seq_seq_rawdata

```yaml
    label: Seq Seq Rawdata
    pluralLabel: Plural - Seq Seq Rawdata
    type: TABLE
```

| Field | Label | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|-------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT |      |          |          |        |           |             |    |         |    | 
| dummy | Dummy | INT   | 10   |          | X        |        |           |             |    |         |    | 

### FIGDEF# seq_seq_resource

```yaml
    label: Seq Seq Resource
    pluralLabel: Plural - Seq Seq Resource
    type: TABLE
```

| Field | Label | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|-------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT |      |          |          |        |           |             |    |         |    | 
| dummy | Dummy | INT   | 10   |          | X        |        |           |             |    |         |    | 

### FIGDEF# seq_seq_resource_type_info

```yaml
    label: Seq Seq Resource Type Info
    pluralLabel: Plural - Seq Seq Resource Type Info
    type: TABLE
```

| Field | Label | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|-------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT |      |          |          |        |           |             |    |         |    | 
| dummy | Dummy | INT   | 10   |          | X        |        |           |             |    |         |    | 

### FIGDEF# seq_seq_resource_version

```yaml
    label: Seq Seq Resource Version
    pluralLabel: Plural - Seq Seq Resource Version
    type: TABLE
```

| Field | Label | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|-------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT |      |          |          |        |           |             |    |         |    | 
| dummy | Dummy | INT   | 10   |          | X        |        |           |             |    |         |    | 

### FIGDEF# seq_seq_resource_version_info

```yaml
    label: Seq Seq Resource Version Info
    pluralLabel: Plural - Seq Seq Resource Version Info
    type: TABLE
```

| Field | Label | Type  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|-------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT |      |          |          |        |           |             |    |         |    | 
| dummy | Dummy | INT   | 10   |          | X        |        |           |             |    |         |    | 

### FIGDEF# ring_generated_file

```yaml
    label: Ring Generated File
    pluralLabel: Plural - Ring Generated File
    type: TABLE
```

| Field          | Label          | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK | SubType  |
|----------------|----------------|----------|------|----------|----------|--------|-----------|-------------|----|---------|----|----------|
| id             | Id             | IDENT    |      |          |          |        |           |             |    |         |    |          |
| file_uuid      | File Uuid      | VARCHAR  | 64   |          |          |        |           |             |    |         |    |          |
| filetype       | Filetype       | VARCHAR  | 30   |          |          |        |           |             |    |         |    |          |
| generator_user | Generator User | VARCHAR  | 64   |          | X        |        |           |             |    |         |    |          |
| filedata       | Filedata       | LONGBLOB |      |          | X        |        |           |             |    |         |    |          |
| created_at     | Created At     | DATETIME |      |          |          |        |           |             |    |         |    |          |
| metadata       | Metadata       | LONGBLOB |      |          | X        |        |           |             |    |         |    |          |
| storage_type   | Storage Type   | VARCHAR  | 8    |          | X        |        |           |             |    |         |    |          |
| filepath       | Filepath       | LONGTEXT |      |          | X        |        |           |             |    |         |    |          |
| file_size      | Fájl mérete    | DECIMAL  | 19   |          | X        |        |           |             |    |         |    | FILESIZE |
| gstatus        | Gstatus        | VARCHAR  | 8    |          | X        |        |           |             |    |         |    |          |
| gmessage       | Gmessage       | LONGTEXT |      |          | X        |        |           |             |    |         |    |          |

### FIGDEF# ring_res_rawdata

```yaml
    label: Ring Res Rawdata
    pluralLabel: Plural - Ring Res Rawdata
    type: TABLE
```

| Field | Label | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|----------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT    |      |          |          |        |           |             |    |         |    | 
| data  | Data  | LONGBLOB |      |          | X        |        |           |             |    |         |    | 

### FIGDEF# ring_res_resource

```yaml
    label: Ring Res Resource
    pluralLabel: Plural - Ring Res Resource
    type: TABLE
```

| Field               | Label               | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK |
|---------------------|---------------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|----|
| resource_id         | Resource            | IDENT   |      |          |          |        |           |             | TABLE | resource |    | 
| rendszer            | Rendszer            | VARCHAR | 30   |          |          |        |           |             |       |          |    | 
| resourcealias       | Resourcealias       | VARCHAR | 30   |          |          |        |           |             |       |          |    | 
| resourcetype        | Resourcetype        | VARCHAR | 30   |          |          |        |           |             |       |          |    | 
| resourcename        | Resourcename        | VARCHAR | 255  |          |          |        |           |             |       |          |    | 
| resourceliveversion | Resourceliveversion | VARCHAR | 20   |          | X        |        |           |             |       |          |    | 

### FIGDEF# ring_res_resourcetypeinfo

```yaml
    label: Ring Res Resourcetypeinfo
    pluralLabel: Plural - Ring Res Resourcetypeinfo
    type: TABLE
```

| Field                | Label                | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign          | FK |
|----------------------|----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|------------------|----|
| resourcetypeinfo_id  | Resourcetypeinfo     | IDENT   |      |          |          |        |           |             | TABLE | resourcetypeinfo |    | 
| rendszer             | Rendszer             | VARCHAR | 30   |          |          |        |           |             |       |                  |    | 
| resourcetype         | Resourcetype         | VARCHAR | 30   |          |          |        |           |             |       |                  |    | 
| resourceinfotype     | Resourceinfotype     | VARCHAR | 30   |          |          |        |           |             |       |                  |    | 
| resourcedefaultvalue | Resourcedefaultvalue | VARCHAR | 255  |          | X        |        |           |             |       |                  |    | 

### FIGDEF# ring_res_resourceversion

```yaml
    label: Ring Res Resourceversion
    pluralLabel: Plural - Ring Res Resourceversion
    type: TABLE
```

| Field              | Label           | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK |
|--------------------|-----------------|----------|------|----------|----------|--------|-----------|-------------|-------|-----------------|----|
| resourceversion_id | Resourceversion | IDENT    |      |          |          |        |           |             | TABLE | resourceversion |    | 
| rendszer           | Rendszer        | VARCHAR  | 30   |          |          |        |           |             |       |                 |    | 
| resourcealias      | Resourcealias   | VARCHAR  | 30   |          |          |        |           |             |       |                 |    | 
| resourceversion    | Resourceversion | VARCHAR  | 20   |          |          |        |           |             |       |                 |    | 
| resourcedate       | Resourcedate    | DATETIME |      |          | X        |        |           |             |       |                 |    | 

### FIGDEF# ring_res_resourceversioninfo

```yaml
    label: Ring Res Resourceversioninfo
    pluralLabel: Plural - Ring Res Resourceversioninfo
    type: TABLE
```

| Field                  | Label               | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign             | FK |
|------------------------|---------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------------|----|
| resourceversioninfo_id | Resourceversioninfo | IDENT   |      |          |          |        |           |             | TABLE | resourceversioninfo |    | 
| rendszer               | Rendszer            | VARCHAR | 30   |          |          |        |           |             |       |                     |    | 
| resourcealias          | Resourcealias       | VARCHAR | 30   |          |          |        |           |             |       |                     |    | 
| resourcetype           | Resourcetype        | VARCHAR | 30   |          |          |        |           |             |       |                     |    | 
| resourceversion        | Resourceversion     | VARCHAR | 20   |          |          |        |           |             |       |                     |    | 
| resourceinfotype       | Resourceinfotype    | VARCHAR | 30   |          |          |        |           |             |       |                     |    | 
| resourceinfovalue      | Resourceinfovalue   | VARCHAR | 255  |          | X        |        |           |             |       |                     |    | 

### FIGDEF# ring_sorszam

```yaml
    label: Ring Sorszam
    pluralLabel: Plural - Ring Sorszam
    type: TABLE
```

| Field         | Label         | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK |
|---------------|---------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|----|
| sorszam_id    | Sorszam       | IDENT   |      |          |          |        |           |             | TABLE | sorszam |    | 
| sorszam_name  | Sorszam Name  | VARCHAR | 64   |          |          |        |           |             |       |         |    | 
| sorszam_type  | Sorszam Type  | DECIMAL | 10   |          |          |        |           |             |       |         |    | 
| sorszam_value | Sorszam Value | VARCHAR | 64   |          | X        |        |           |             |       |         |    |
