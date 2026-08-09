---
title: product_v0.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/product_v0.md
doc_type: text
---

# product_v0.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 14.2 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/product_v0.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Felépítás

## Entitások

### FIGDEF# product

```yaml
    label: Termék
    pluralLabel: Termékek
    type: TABLE
```

| Field                | Label              | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         |
|----------------------|--------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|
| id                   | Id                 | IDENT   |      |          |          |        |           |             |       |         |            |
| manufacturer         | Gyártó             | VARCHAR | 255  |          | X        |        |           |             |       |         |            |
| article_number       | Cikkszám           | VARCHAR | 128  |          |          |        |           |             |       |         |            |
| code                 | Termékkód/Vonalkód | VARCHAR | 64   |          | X        |        |           |             |       |         |            | 
| name                 | Név                | VARCHAR | 1024 |          |          |        |           |             |       |         |            | 
| description          | Leírás             | VARCHAR | 2000 |          | X        |        |           |             |       |         |            | 
| category             | Kategória          | VARCHAR | 512  |          | X        |        |           |             |       |         |            |
| partner_id           | Beszállító         | FKIDENT |      |          | X        |        |           |             | TABLE | partner | partner.id |
| product_supplier_url | Termék link        | VARCHAR | 1024 |          | X        |        |           |             |       |         |            |

---

### FIGDEF# product_ext

```yaml
    label: Termék
    pluralLabel: Termékek
    type: EXTEND
    parent: product
```

| Field   | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|---------|------------|---------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| partner | Beszállító | Partner |      |          | X        |        |           |             | DTO | partner | name | partner_id  |

---

### FIGDEF# product_with_stock_ext

```yaml
    label: Termék
    pluralLabel: Termékek
    type: EXTEND
    parent: product
```

| Field   | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|---------|------------|---------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| partner | Beszállító | Partner |      |          | X        |        |           |             | DTO | partner | name | partner_id  |
| stock   | Készlet    | Stock   |      |          | X        |        |           |             | DTO | stock   |      |             |

---

### FIGDEF# product_for_import_ext

```yaml
    label: Termék
    pluralLabel: Termékek
    type: EXTEND
    parent: product
```

| Field      | Label       | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|------------|-------------|---------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| partner    | Beszállító  | Partner |      |          | X        |        |           |             | DTO | partner | name | partner_id  |
| common_key | Közös kulcs | VARCHAR | 512  |          | X        |        |           |             |     |         |      |             |   

---

### FIGDEF# product_list_price

```yaml
    label: Listaár
    pluralLabel: Listaárak
    type: TABLE
```

| Field            | Label           | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK         | Hide | SubType  |
|------------------|-----------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|------------|------|----------|
| id               | Id              | IDENT   |      |          |          |        |           |             |       |          |            |      |          |
| product_id       | Termék          | FKIDENT |      |          |          |        |           |             | TABLE | product  | product.id | X    |          |
| list_price_date  | Listaár dátuma  | DATE    |      |          |          |        |           |             |       |          |            |      |          |
| list_price_netto | Listaár (nettó) | DECIMAL | 19   | 2        |          |        |           |             |       |          |            |      | CURRENCY |
| currency_did     | Pénznem         | DICT    |      |          | X        |        |           |             |       | CURRENCY |            |      |          |

---

### FIGDEF# product_list_price_ext

```yaml
    label: Listaár
    pluralLabel: Listaárak
    type: EXTEND
    parent: product_list_price
```

| Field    | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign  | FK          | Replacement  | Hide |
|----------|---------|------------|------|----------|----------|--------|-----------|-------------|------|----------|-------------|--------------|------|
| currency | Pénznem | Dictionary |      |          |          |        |           |             | DICT | CURRENCY | description | currency_did |      |
| product  | Termék  | Product    |      |          |          |        |           |             | DTO  | product  | name        | product_id   | X    |

---

### FIGDEF# product_price

```yaml
    label: Termék ára
    pluralLabel: Termékek árai
    type: TABLE
```

| Field                | Label                 | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                 | SubType  |
|----------------------|-----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|--------------------|----------|
| id                   | Id                    | IDENT   |      |          |          |        |           |             |       |                 |                    |          |
| product_id           | Termék                | FKIDENT |      |          |          |        |           |             | TABLE | product         | product.id         |          |
| invoice_in_item_id   | Bejövő számlatétel    | FKIDENT |      |          |          |        |           |             | TABLE | invoice_in_item | invoice_in_item.id |          |
| purchase_price_netto | Beszerzési ár (nettó) | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| currency_did         | Pénznem               | DICT    |      |          |          |        |           |             |       | CURRENCY        |                    |          |
| sales_price_netto    | Eladási ár (nettó)    | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| quantity             | Mennyiség             | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| stock_quantity       | Készletmennyiség      | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| unit_of_measure_did  | Mértékegység          | DICT    |      |          |          |        |           |             |       | UNIT_OF_MEASURE |                    |          |

---

### FIGDEF# product_document

```yaml
    label: Termék dokumentum
    pluralLabel: Termék dokumentumok
    type: TABLE
```

| Field       | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          |
|-------------|------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|
| id          | Id         | IDENT   |      |          |          |        |           |             |       |          |             | 
| product_id  | Termék     | FKIDENT |      |          |          |        |           |             | TABLE | product  | product.id  | 
| document_id | Dokumentum | FKIDENT |      |          |          |        |           |             | TABLE | document | document.id | 

---

### FIGDEF# product_document_ext

```yaml
    label: Termék dokumentum
    pluralLabel: Termék dokumentumok
    type: EXTEND
    parent: product_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

---

### FIGDEF# stock

```yaml
    label: Készlet
    pluralLabel: Készletek
    type: TABLE
```

| Field               | Label        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK          | SubType  |
|---------------------|--------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|-------------|----------|
| id                  | Id           | IDENT   |      |          |          |        |           |             |       |                 |             |          |
| product_id          | Termék       | FKIDENT |      |          |          |        |           |             | TABLE | product         | product.id  |          |
| quantity            | Mennyiség    | DECIMAL | 19   | 2        |          |        |           |             |       |                 |             | CURRENCY |
| unit_of_measure_did | Mértékegység | DICT    |      |          |          |        |           |             |       | UNIT_OF_MEASURE | description |          |

---

### FIGDEF# stock_ext

```yaml
    label: Készlet
    pluralLabel: Készletek
    type: EXTEND
    parent: stock
```

| Field           | Label        | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign         | FK          | Replacement         |
|-----------------|--------------|------------|------|----------|----------|--------|-----------|-------------|------|-----------------|-------------|---------------------|
| product         | Termék       | Product    |      |          |          |        |           |             | DTO  | product         | name        | product_id          |
| unit_of_measure | Mértékegység | Dictionary |      |          |          |        |           |             | DICT | UNIT_OF_MEASURE | description | unit_of_measure_did |

---

### FIGDEF# stock_movement

```yaml
    label: Készletmozgás
    pluralLabel: Készletmozgások
    type: TABLE
```

| Field               | Label                | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK         | SubType  |
|---------------------|----------------------|----------|------|----------|----------|--------|-----------|-------------|-------|-----------------|------------|----------|
| id                  | Id                   | IDENT    |      |          |          |        |           |             |       |                 |            |          |
| movement_date       | Készletmozgás dátuma | DATETIME |      |          |          |        |           |             |       |                 |            |          |
| product_id          | Termék               | FKIDENT  |      |          |          |        |           |             | TABLE | product         | product.id |          |
| quantity            | Mennyiség            | DECIMAL  | 19   | 2        |          |        |           |             |       |                 |            | CURRENCY |
| unit_of_measure_did | Mértékegység         | DICT     |      |          |          |        |           |             |       | UNIT_OF_MEASURE |            |          |
| partner_id          | Partner              | FKIDENT  |      |          |          |        |           |             | TABLE | partner         | partner.id |          |
| movement_type_did   | Mozgás iránya        | DICT     |      |          |          |        |           |             |       | MOVEMENT_TYPE   |            |          |

---

### FIGDEF# stock_movement_ext

```yaml
    label: Készletmozgás
    pluralLabel: Készletmozgások
    type: EXTEND
    parent: stock_movement
```

| Field           | Label         | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign         | FK          | Replacement         |
|-----------------|---------------|------------|------|----------|----------|--------|-----------|-------------|------|-----------------|-------------|---------------------|
| product         | Termék        | Product    |      |          |          |        |           |             | DTO  | product         | name        | product_id          |
| partner         | Partner       | Partner    |      |          |          |        |           |             | DTO  | partner         | short_name  | partner_id          |
| movement_type   | Mozgás iránya | Dictionary |      |          |          |        |           |             | DICT | MOVEMENT_TYPE   | description | movement_type_did   |
| unit_of_measure | Mértékegység  | Dictionary |      |          |          |        |           |             | DICT | UNIT_OF_MEASURE | description | unit_of_measure_did |
