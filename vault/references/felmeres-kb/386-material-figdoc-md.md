---
title: material.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/material.figdoc.md
doc_type: text
---

# material.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 22.4 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/material.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Felépítás

## Entitások

### FIGDEF# material

```yaml
    label: Anyag
    pluralLabel: Anyagok
    type: TABLE
```

| Field                 | Label             | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         |
|-----------------------|-------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|
| id                    | Id                | IDENT   |      |          |          |        |           |             |       |         |            |
| manufacturer          | Gyártó            | VARCHAR | 255  |          | X        |        |           |             |       |         |            |
| article_number        | Cikkszám          | VARCHAR | 128  |          |          |        |           |             |       |         |            |
| code                  | Anyagkód/Vonalkód | VARCHAR | 64   |          | X        |        |           |             |       |         |            | 
| name                  | Név               | VARCHAR | 1024 |          |          |        |           |             |       |         |            | 
| description           | Leírás            | VARCHAR | 2000 |          | X        |        |           |             |       |         |            | 
| category              | Kategória         | VARCHAR | 512  |          | X        |        |           |             |       |         |            |
| partner_id            | Beszállító        | FKIDENT |      |          | X        |        |           |             | TABLE | partner | partner.id |
| material_supplier_url | Anyag link        | VARCHAR | 1024 |          | X        |        |           |             |       |         |            |

---

### FIGDEF# material_ext

```yaml
    label: Anyag
    pluralLabel: Anyagok
    type: EXTEND
    parent: material
```

| Field   | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|---------|------------|---------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| partner | Beszállító | Partner |      |          | X        |        |           |             | DTO | partner | name | partner_id  |

---

### FIGDEF# material_with_stock_ext

```yaml
    label: Anyag
    pluralLabel: Anyagok
    type: EXTEND
    parent: material
```

| Field   | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|---------|------------|---------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| partner | Beszállító | Partner |      |          | X        |        |           |             | DTO | partner | name | partner_id  |
| stock   | Készlet    | Stock   |      |          | X        |        |           |             | DTO | stock   |      |             |

---

### FIGDEF# material_for_import_ext

```yaml
    label: Anyag
    pluralLabel: Anyagok
    type: EXTEND
    parent: material
```

| Field      | Label       | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT  | Foreign | FK   | Replacement |
|------------|-------------|---------|------|----------|----------|--------|-----------|-------------|-----|---------|------|-------------|
| partner    | Beszállító  | Partner |      |          | X        |        |           |             | DTO | partner | name | partner_id  |
| common_key | Közös kulcs | VARCHAR | 512  |          | X        |        |           |             |     |         |      |             |   

---

### FIGDEF# material_list_price

```yaml
    label: Listaár
    pluralLabel: Listaárak
    type: TABLE
```

| Field            | Label           | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          | Hide | SubType  |
|------------------|-----------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|------|----------|
| id               | Id              | IDENT   |      |          |          |        |           |             |       |          |             |      |          |
| material_id      | Anyag           | FKIDENT |      |          |          |        |           |             | TABLE | material | material.id | X    |          |
| list_price_date  | Listaár dátuma  | DATE    |      |          |          |        |           |             |       |          |             |      |          |
| list_price_netto | Listaár (nettó) | DECIMAL | 19   | 2        |          |        |           |             |       |          |             |      | CURRENCY |
| currency_did     | Pénznem         | DICT    |      |          | X        |        |           |             |       | CURRENCY |             |      |          |

---

### FIGDEF# material_list_price_ext

```yaml
    label: Listaár
    pluralLabel: Listaárak
    type: EXTEND
    parent: material_list_price
```

| Field    | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign  | FK          | Replacement  | Hide |
|----------|---------|------------|------|----------|----------|--------|-----------|-------------|------|----------|-------------|--------------|------|
| currency | Pénznem | Dictionary |      |          |          |        |           |             | DICT | CURRENCY | description | currency_did |      |
| material | Anyag   | Material   |      |          |          |        |           |             | DTO  | material | name        | material_id  | X    |

---

### FIGDEF# mat_procurement

```yaml
    label: Beszerzés
    pluralLabel: Beszerzések
    type: TABLE
```

| Field                | Label                 | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                 | SubType  |
|----------------------|-----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|--------------------|----------|
| id                   | Id                    | IDENT   |      |          |          |        |           |             |       |                 |                    |          |
| material_id          | Anyag                 | FKIDENT |      |          |          |        |           |             | TABLE | material        | material.id        |          |
| invoice_in_item_id   | Bejövő számlatétel    | FKIDENT |      |          |          |        |           |             | TABLE | invoice_in_item | invoice_in_item.id |          |
| purchase_price_netto | Beszerzési ár (nettó) | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| currency_did         | Pénznem               | DICT    |      |          |          |        |           |             |       | CURRENCY        |                    |          |
| sales_price_netto    | Eladási ár (nettó)    | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| quantity             | Mennyiség             | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| stock_quantity       | Készletmennyiség      | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |
| unit_of_measure_did  | Mértékegység          | DICT    |      |          |          |        |           |             |       | UNIT_OF_MEASURE |                    |          |

---

### FIGDEF# mat_procurement_ext

```yaml
    label: Beszerzés
    pluralLabel: Beszerzések
    type: EXTEND
    parent: mat_procurement
```

| Field           | Label         | Type          | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign         | FK                 | Replacement         |
|-----------------|---------------|---------------|------|----------|----------|--------|-----------|-------------|------|-----------------|--------------------|---------------------|
| currency        | Pénznem       | Dictionary    |      |          |          |        |           |             | DICT | CURRENCY        | description        | currency_did        |
| material        | Anyag         | Material      |      |          |          |        |           |             | DTO  | material        | name               | material_id         |
| unit_of_measure | Mértékegység  | Dictionary    |      |          |          |        |           |             | DICT | UNIT_OF_MEASURE | description        | unit_of_measure_did |
| invoice_in_item | Bejövő számla | InvoiceInItem |      |          |          |        |           |             | DTO  | invoice_in_item | invoice_in_item_id | invoice_in_item_id  |

---

### FIGDEF# mat_warehouse

```yaml
    label: Raktár
    pluralLabel: Raktárak
    type: TABLE
```

| Field      | Label   | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         |
|------------|---------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|
| id         | Id      | IDENT   |      |          |          |        |           |             |       |         |            |
| code       | Kód     | VARCHAR | 64   |          |          |        |           |             |       |         |            |
| name       | Név     | VARCHAR | 255  |          | X        |        |           |             |       |         |            |
| project_id | Projekt | FKIDENT |      |          | X        |        |           |             | TABLE | project | project.id |

### FIGDEF# material_document

```yaml
    label: Anyag dokumentum
    pluralLabel: Anyag dokumentumok
    type: TABLE
```

| Field       | Label      | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign  | FK          |
|-------------|------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------|-------------|
| id          | Id         | IDENT   |      |          |          |        |           |             |       |          |             | 
| material_id | Anyag      | FKIDENT |      |          |          |        |           |             | TABLE | material | material.id | 
| document_id | Dokumentum | FKIDENT |      |          |          |        |           |             | TABLE | document | document.id | 

---

### FIGDEF# material_document_ext

```yaml
    label: Anyag dokumentum
    pluralLabel: Anyag dokumentumok
    type: EXTEND
    parent: material_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |

---

### FIGDEF# mat_stock

```yaml
    label: Készlet
    pluralLabel: Készletek
    type: TABLE
```

| Field               | Label        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                 | SubType  | Hide |
|---------------------|--------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|--------------------|----------|------|
| id                  | Id           | IDENT   |      |          |          |        |           |             |       |                 |                    |          |      |
| material_id         | Anyag        | FKIDENT |      |          |          |        |           |             | TABLE | material        | material.id        |          |      |
| mat_warehouse_id    | Raktár       | FKIDENT |      |          |          |        |           |             | TABLE | mat_warehouse   | mat_warehouse.id   |          |      |
| mat_procurement_id  | Beszerzés    | FKIDENT |      |          |          |        |           |             | TABLE | mat_procurement | mat_procurement.id |          | X    |
| quantity            | Mennyiség    | DECIMAL | 19   | 2        |          |        |           |             |       |                 |                    | CURRENCY |      |
| unit_of_measure_did | Mértékegység | DICT    |      |          |          |        |           |             |       | UNIT_OF_MEASURE | description        |          |      |

---

### FIGDEF# mat_stock_ext

```yaml
    label: Készlet
    pluralLabel: Készletek
    type: EXTEND
    parent: mat_stock
```

| Field            | Label        | Type                     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                  | FK          | Replacement         | Hide |
|------------------|--------------|--------------------------|------|----------|----------|--------|-----------|-------------|--------|--------------------------|-------------|---------------------|------|
| material         | Anyag        | Material                 |      |          |          |        |           |             | DTO    | material                 | name        | material_id         |      |
| mat_warehouse    | Raktár       | MatWarehouse             |      |          |          |        |           |             | DTO    | mat_warehouse            | code        | mat_warehouse_id    |      |
| mat_procurements | Beszerzés    | List<MatProcurementExt?> |      |          |          |        |           |             | EXTEND | list:mat_procurement_ext |             |                     | X    |
| unit_of_measure  | Mértékegység | Dictionary               |      |          |          |        |           |             | DICT   | UNIT_OF_MEASURE          | description | unit_of_measure_did |      |

---

### FIGDEF# mat_stock_movement

```yaml
    label: Készletmozgás
    pluralLabel: Készletmozgások
    type: TABLE
```

| Field                        | Label                | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK               | SubType  |
|------------------------------|----------------------|----------|------|----------|----------|--------|-----------|-------------|-------|-----------------|------------------|----------|
| id                           | Id                   | IDENT    |      |          |          |        |           |             |       |                 |                  |          |
| material_id                  | Anyag                | FKIDENT  |      |          |          |        |           |             | TABLE | material        | material.id      |          |
| mat_warehouse_id             | Raktár               | FKIDENT  |      |          |          |        |           |             | TABLE | mat_warehouse   | mat_warehouse.id |          |
| movement_date                | Készletmozgás dátuma | DATETIME |      |          |          |        |           |             |       |                 |                  |          |
| quantity                     | Mennyiség            | DECIMAL  | 19   | 2        |          |        |           |             |       |                 |                  | CURRENCY |
| unit_of_measure_did          | Mértékegység         | DICT     |      |          |          |        |           |             |       | UNIT_OF_MEASURE |                  |          |
| partner_id                   | Partner              | FKIDENT  |      |          |          |        |           |             | TABLE | partner         | partner.id       |          |
| source_mat_warehouse_id      | Forrás raktár        | FKIDENT  |      |          | X        |        |           |             | TABLE | mat_warehouse   | mat_warehouse.id |          |
| destination_mat_warehouse_id | Cél raktár           | FKIDENT  |      |          | X        |        |           |             | TABLE | mat_warehouse   | mat_warehouse.id |          |
| movement_type_did            | Mozgás iránya        | DICT     |      |          |          |        |           |             |       | MOVEMENT_TYPE   |                  |          |
| note                         | Megjegyzés           | VARCHAR  | 2000 |          | X        |        |           |             |       |                 |                  |          |

---

### FIGDEF# mat_stock_movement_ext

```yaml
    label: Készletmozgás
    pluralLabel: Készletmozgások
    type: EXTEND
    parent: mat_stock_movement
```

| Field                     | Label         | Type         | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign         | FK          | Replacement                  |
|---------------------------|---------------|--------------|------|----------|----------|--------|-----------|-------------|------|-----------------|-------------|------------------------------|
| material                  | Anyag         | Material     |      |          |          |        |           |             | DTO  | material        | name        | material_id                  |
| mat_warehouse             | Raktár        | MatWarehouse |      |          |          |        |           |             | DTO  | mat_warehouse   | code        | mat_warehouse_id             |
| mat_source_warehouse      | Forrás raktár | MatWarehouse |      |          |          |        |           |             | DTO  | mat_warehouse   | code        | source_mat_warehouse_id      |
| mat_destination_warehouse | Cél raktár    | MatWarehouse |      |          |          |        |           |             | DTO  | mat_warehouse   | code        | destination_mat_warehouse_id |
| partner                   | Partner       | Partner      |      |          |          |        |           |             | DTO  | partner         | short_name  | partner_id                   |
| movement_type             | Mozgás iránya | Dictionary   |      |          |          |        |           |             | DICT | MOVEMENT_TYPE   | description | movement_type_did            |
| unit_of_measure           | Mértékegység  | Dictionary   |      |          |          |        |           |             | DICT | UNIT_OF_MEASURE | description | unit_of_measure_did          |

---

### FIGDEF# mat_order_in

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

### FIGDEF# mat_order_in_ext

```yaml
    label: Beszerzési megrendelés
    pluralLabel: Beszerzési megrendelések
    type: EXTEND
    parent: mat_order_in
```

| Field        | Label   | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign      | FK          | Replacement      |
|--------------|---------|------------|------|----------|----------|--------|-----------|-------------|------|--------------|-------------|------------------|
| partner      | Partner | Partner    |      |          |          |        |           |             | DTO  | partner      | short_name  | partner_id       |
| order_status | Státusz | Dictionary |      |          |          |        |           |             | DICT | ORDER_STATUS | description | order_status_did |

---

### FIGDEF# mat_order_in_item

```yaml
    label: Beszerzési megrendelés tétele
    pluralLabel: Beszerzési megrendelés tételek
    type: TABLE
```

| Field               | Label                  | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK          |
|---------------------|------------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|-------------|
| id                  | Id                     | IDENT   |      |          |          |        |           |             |       |                 |             |
| mat_order_in_id     | Beszerzési megrendelés | FKIDENT |      |          |          |        |           |             | TABLE | order           | order.id    |
| material_id         | Anyag                  | FKIDENT |      |          |          |        |           |             | TABLE | material        | material.id |
| quantity            | Mennyiség              | DECIMAL | 19   | 2        |          |        |           |             |       |                 |             |
| unit_of_measure_did | Mértékegység           | DICT    |      |          |          |        |           |             |       | UNIT_OF_MEASURE | description |
