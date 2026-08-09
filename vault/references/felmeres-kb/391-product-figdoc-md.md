---
title: product.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/product.figdoc.md
doc_type: text
---

# product.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 21.8 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/product.figdoc.md`

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

### FIGDEF# procurement

```yaml
    label: Beszerzés
    pluralLabel: Beszerzések
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

### FIGDEF# procurement_ext

```yaml
    label: Beszerzés
    pluralLabel: Beszerzések
    type: EXTEND
    parent: procurement
```

| Field           | Label         | Type          | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign         | FK                 | Replacement         |
|-----------------|---------------|---------------|------|----------|----------|--------|-----------|-------------|------|-----------------|--------------------|---------------------|
| currency        | Pénznem       | Dictionary    |      |          |          |        |           |             | DICT | CURRENCY        | description        | currency_did        |
| product         | Termék        | Product       |      |          |          |        |           |             | DTO  | product         | name               | product_id          |
| unit_of_measure | Mértékegység  | Dictionary    |      |          |          |        |           |             | DICT | UNIT_OF_MEASURE | description        | unit_of_measure_did |
| invoice_in_item | Bejövő számla | InvoiceInItem |      |          |          |        |           |             | DTO  | invoice_in_item | invoice_in_item_id | invoice_in_item_id  |

---

### FIGDEF# warehouse

```yaml
    label: Raktár
    pluralLabel: Raktárak
    type: TABLE
```

| Field | Label | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|-------|-------|---------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id    | Id    | IDENT   |      |          |          |        |           |             |    |         |    |
| code  | Kód   | VARCHAR | 64   |          |          |        |           |             |    |         |    |
| name  | Név   | VARCHAR | 255  |          | X        |        |           |             |    |         |    |

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

| Field               | Label        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK             | SubType  | Hide |
|---------------------|--------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|----------------|----------|------|
| id                  | Id           | IDENT   |      |          |          |        |           |             |       |                 |                |          |      |
| product_id          | Termék       | FKIDENT |      |          |          |        |           |             | TABLE | product         | product.id     |          |      |
| warehouse_id        | Raktár       | FKIDENT |      |          |          |        |           |             | TABLE | warehouse       | warehouse.id   |          |      |
| procurement_id      | Beszerzés    | FKIDENT |      |          |          |        |           |             | TABLE | procurement     | procurement.id |          | X    |
| quantity            | Mennyiség    | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                | CURRENCY |      |
| unit_of_measure_did | Mértékegység | DICT    |      |          |          |        |           |             |       | UNIT_OF_MEASURE | description    |          |      |

---

### FIGDEF# stock_ext

```yaml
    label: Készlet
    pluralLabel: Készletek
    type: EXTEND
    parent: stock
```

| Field           | Label        | Type                  | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign              | FK          | Replacement         | Hide |
|-----------------|--------------|-----------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------|-------------|---------------------|------|
| product         | Termék       | Product               |      |          |          |        |           |             | DTO    | product              | name        | product_id          |      |
| warehouse       | Raktár       | Warehouse             |      |          |          |        |           |             | DTO    | warehouse            | code        | warehouse_id        |      |
| procurements    | Beszerzés    | List<ProcurementExt?> |      |          |          |        |           |             | EXTEND | list:procurement_ext |             |                     | X    |
| unit_of_measure | Mértékegység | Dictionary            |      |          |          |        |           |             | DICT   | UNIT_OF_MEASURE      | description | unit_of_measure_did |      |

---

### FIGDEF# stock_movement

```yaml
    label: Készletmozgás
    pluralLabel: Készletmozgások
    type: TABLE
```

| Field                    | Label                | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK           | SubType  |
|--------------------------|----------------------|----------|------|----------|----------|--------|-----------|-------------|-------|-----------------|--------------|----------|
| id                       | Id                   | IDENT    |      |          |          |        |           |             |       |                 |              |          |
| product_id               | Termék               | FKIDENT  |      |          |          |        |           |             | TABLE | product         | product.id   |          |
| warehouse_id             | Raktár               | FKIDENT  |      |          |          |        |           |             | TABLE | warehouse       | warehouse.id |          |
| movement_date            | Készletmozgás dátuma | DATETIME |      |          |          |        |           |             |       |                 |              |          |
| quantity                 | Mennyiség            | DECIMAL  | 19   | 2        |          |        |           |             |       |                 |              | CURRENCY |
| unit_of_measure_did      | Mértékegység         | DICT     |      |          |          |        |           |             |       | UNIT_OF_MEASURE |              |          |
| partner_id               | Partner              | FKIDENT  |      |          |          |        |           |             | TABLE | partner         | partner.id   |          |
| source_warehouse_id      | Forrás raktár        | FKIDENT  |      |          | X        |        |           |             | TABLE | warehouse       | warehouse.id |          |
| destination_warehouse_id | Cél raktár           | FKIDENT  |      |          | X        |        |           |             | TABLE | warehouse       | warehouse.id |          |
| movement_type_did        | Mozgás iránya        | DICT     |      |          |          |        |           |             |       | MOVEMENT_TYPE   |              |          |
| note                     | Megjegyzés           | VARCHAR  | 2000 |          | X        |        |           |             |       |                 |              |          |

---

### FIGDEF# stock_movement_ext

```yaml
    label: Készletmozgás
    pluralLabel: Készletmozgások
    type: EXTEND
    parent: stock_movement
```

| Field                 | Label         | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign         | FK          | Replacement              |
|-----------------------|---------------|------------|------|----------|----------|--------|-----------|-------------|------|-----------------|-------------|--------------------------|
| product               | Termék        | Product    |      |          |          |        |           |             | DTO  | product         | name        | product_id               |
| warehouse             | Raktár        | Warehouse  |      |          |          |        |           |             | DTO  | warehouse       | code        | warehouse_id             |
| source_warehouse      | Forrás raktár | Warehouse  |      |          |          |        |           |             | DTO  | warehouse       | code        | source_warehouse_id      |
| destination_warehouse | Cél raktár    | Warehouse  |      |          |          |        |           |             | DTO  | warehouse       | code        | destination_warehouse_id |
| partner               | Partner       | Partner    |      |          |          |        |           |             | DTO  | partner         | short_name  | partner_id               |
| movement_type         | Mozgás iránya | Dictionary |      |          |          |        |           |             | DICT | MOVEMENT_TYPE   | description | movement_type_did        |
| unit_of_measure       | Mértékegység  | Dictionary |      |          |          |        |           |             | DICT | UNIT_OF_MEASURE | description | unit_of_measure_did      |

---

### FIGDEF# order_in

```yaml
    label: Beszerzési megrendelés
    pluralLabel: Beszerzési megrendelések
    type: TABLE
```

| Field            | Label                    | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign      | FK         |
|------------------|--------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|--------------|------------|
| id               | Id                       | IDENT   |      |          |          |        |           |             |       |              |            |
| partner_id       | Partner                  | FKIDENT |      |          |          |        |           |             | TABLE | partner      | partner.id |
| expected_date    | Várható szállítás dátuma | DATE    |      |          |          |        |           |             |       |              |            |
| order_date       | Szállítás dátuma         | DATE    |      |          | X        |        |           |             |       |              |            |
| order_status_did | Státusz                  | DICT    |      |          |          |        |           |             |       | ORDER_STATUS |            |
| note             | Megjegyzés               | VARCHAR | 2000 |          | X        |        |           |             |       |              |            |

---

### FIGDEF# order_in_ext

```yaml
    label: Beszerzési megrendelés
    pluralLabel: Beszerzési megrendelések
    type: EXTEND
    parent: order_in
```

| Field        | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign      | FK          | Replacement      |
|--------------|---------|------------|------|----------|----------|--------|-----------|-------------|------|--------------|-------------|------------------|
| partner      | Partner | Partner    |      |          |          |        |           |             | DTO  | partner      | short_name  | partner_id       |
| order_status | Státusz | Dictionary |      |          |          |        |           |             | DICT | ORDER_STATUS | description | order_status_did |

---

### FIGDEF# order_in_item

```yaml
    label: Beszerzési megrendelés tétele
    pluralLabel: Beszerzési megrendelés tételek
    type: TABLE
```

| Field               | Label                  | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK          |
|---------------------|------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|-------------|
| id                  | Id                     | IDENT   |      |          |          |        |           |             |       |                 |             |
| order_in_id         | Beszerzési megrendelés | FKIDENT |      |          |          |        |           |             | TABLE | order           | order.id    |
| product_id          | Termék                 | FKIDENT |      |          |          |        |           |             | TABLE | product         | product.id  |
| quantity            | Mennyiség              | DECIMAL | 19   | 2        |          |        |           |             |       |                 |             |
| unit_of_measure_did | Mértékegység           | DICT    |      |          |          |        |           |             |       | UNIT_OF_MEASURE | description |
