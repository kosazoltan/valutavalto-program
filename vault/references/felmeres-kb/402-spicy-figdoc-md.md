---
title: spicy.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/spicy.figdoc.md
doc_type: text
---

# spicy.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 11.6 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/spicy.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

### FIGDEF# delivery_note

```yaml
    label: Szállítólevél
    pluralLabel: Szállítólevelek
    type: TABLE
```

| Field                 | Label                | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign           | FK         |
|-----------------------|----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-------------------|------------|
| id                    | Id                   | IDENT   |      |          |          |        |           |             |       |                   |            | 
| company_id            | Saját cég            | FKIDENT |      |          |          |        |           |             | TABLE | company           | company.id | 
| partner_id            | Partner              | FKIDENT |      |          |          |        |           |             | TABLE | partner           | partner.id |
| invoice_create_date   | Számla kelte         | DATE    |      |          |          |        |           |             |       |                   |            |
| invoice_no            | Számlaszám           | VARCHAR | 255  |          |          |        |           |             |       |                   |            |
| currency_did          | Pénznem              | DICT    |      |          |          |        |           |             |       | CURRENCY          |            |
| language_did          | Nyelv                | DICT    |      |          | X        |        |           |             |       | LANGUAGE          |            |
| completion_date       | Teljesítés dátuma    | DATE    |      |          |          |        |           |             |       |                   |            |
| payment_deadline      | Fizetési határidő    | DATE    |      |          |          |        |           |             |       |                   |            |
| payment_date          | Fizetés dátuma       | DATE    |      |          | X        |        |           |             |       |                   |            |
| payment_note          | Fizetés megjegyzése  | VARCHAR | 255  |          | X        |        |           |             |       |                   |            |
| payment_status_did    | Fizetési állapot     | DICT    |      |          |          |        |           |             |       | PAYMENT_STATUS    |            |
| processing_status_did | Feldolgozási állapot | DICT    |      |          | X        |        |           |             |       | PROCESSING_STATUS |            |

### FIGDEF# delivery_note_ext

```yaml
    label: Szállítólevél
    pluralLabel: Szállítólevelek
    type: EXTEND
    parent: delivery_note
```

| Field             | Label             | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign           | FK          | Replacement           |
|-------------------|-------------------|------------|------|----------|----------|--------|-----------|-------------|------|-------------------|-------------|-----------------------|
| company           | Saját cég         | Company    |      |          |          |        |           |             | DTO  | company           | name        | company_id            |
| partner           | Partner           | Partner    |      |          |          |        |           |             | DTO  | partner           | name        | partner_id            |
| currency          | Pénznem           | Dictionary |      |          |          |        |           |             | DICT | CURRENCY          | description | currency_did          |
| language          | Nyelv             | Dictionary |      |          |          |        |           |             | DICT | LANGUAGE          | description | language_did          |
| payment_status    | Fizetési áll.     | Dictionary |      |          |          |        |           |             | DICT | PAYMENT_STATUS    | description | payment_status_did    |
| processing_status | Feldolgozási áll. | Dictionary |      |          |          |        |           |             | DICT | PROCESSING_STATUS | description | processing_status_did |

### FIGDEF# delivery_note_item

```yaml
    label: Szállítólevél tétele
    pluralLabel: Szállítólevél tételek
    type: TABLE
```

| Field            | Label         | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign       | FK               | SubType  |
|------------------|---------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------|------------------|----------|
| id               | Id            | IDENT   |      |          |          |        |           |             |       |               |                  |          |
| delivery_note_id | Szállítólevél | FKIDENT |      |          |          |        |           |             | TABLE | delivery_note | delivery_note.id |          |
| product_id       | Termék        | FKIDENT |      |          |          |        |           |             | TABLE | product       | product.id       |          |
| quantity         | Mennyiség     | DECIMAL | 19   | 2        |          |        |           |             |       |               |                  | CURRENCY |
| unit_price       | Egységár      | DECIMAL | 19   | 2        |          |        |           |             |       |               |                  | CURRENCY |
| vat_rate_did     | ÁFA kulcs     | DICT    |      |          |          |        |           |             |       | VAT_RATE      |                  |          |
| net_amount       | Nettó érték   | DECIMAL | 19   | 2        |          |        |           |             |       |               |                  | CURRENCY |
| vat_amount       | ÁFA érték     | DECIMAL | 19   | 2        |          |        |           |             |       |               |                  | CURRENCY |
| gross_amount     | Bruttó érték  | DECIMAL | 19   | 2        |          |        |           |             |       |               |                  | CURRENCY |

### FIGDEF# delivery_note_item_ext

```yaml
    label: Szállítólevél tétele
    pluralLabel: Szállítólevél tételek
    type: EXTEND
    parent: delivery_note_item
```

| Field    | Label     | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign  | FK          | Replacement  |
|----------|-----------|------------|------|----------|----------|--------|-----------|-------------|------|----------|-------------|--------------|
| product  | Termék    | Product    |      |          |          |        |           |             | DTO  | product  | name        | product_id   |
| vat_rate | ÁFA kulcs | Dictionary |      |          |          |        |           |             | DICT | VAT_RATE | description | vat_rate_did |

### FIGDEF# order_out

```yaml
    label: Rendelés
    pluralLabel: Rendelések
    type: TABLE
```

| Field      | Label           | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign | FK         |
|------------|-----------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------|------------|
| id         | Id              | IDENT   |      |          |          |        |           |             |       |         |            |
| name       | Név             | VARCHAR | 255  |          |          |        |           |             |       |         |            |
| note       | Megjegyzés      | VARCHAR | 255  |          | X        |        |           |             |       |         |            |
| partner_id | Partner         | FKIDENT |      |          |          |        |           |             | TABLE | partner | partner.id |
| order_dt   | Rendelés dátuma | DATE    |      |          |          |        |           |             |       |         |            |

### FIGDEF# order_out_ext

```yaml
    label: Rendelés
    pluralLabel: Rendelések
    type: EXTEND
    parent: order_out
```

| Field   | Label   | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign | FK | Replacement | Hide |
|---------|---------|---------|------|----------|----------|--------|-----------|-------------|--------|---------|----|-------------|------|
| partner | Partner | Partner |      |          |          |        |           |             | EXTEND | partner |    |             | X    |

### FIGDEF# order_out_item

```yaml
    label: Rendelés tétele
    pluralLabel: Rendelés tételek
    type: TABLE
```

| Field            | Label            | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign      | FK           | SubType  |
|------------------|------------------|---------|------|----------|----------|--------|-----------|-------------|-------|--------------|--------------|----------|
| id               | Id               | IDENT   |      |          |          |        |           |             |       |              |              |          |
| order_out_id     | Rendelés         | FKIDENT |      |          |          |        |           |             | TABLE | order_out    | order_out.id |          |
| product_id       | Termék           | FKIDENT |      |          |          |        |           |             | TABLE | product      | product.id   |          |
| quantity         | Mennyiség        | DECIMAL | 19   | 2        |          |        |           |             |       |              |              | CURRENCY |
| unit_price       | Egységár         | DECIMAL | 19   | 2        |          |        |           |             |       |              |              | CURRENCY |
| vat_rate_did     | ÁFA kulcs        | DICT    |      |          |          |        |           |             |       | VAT_RATE     |              |          |
| net_amount       | Nettó érték      | DECIMAL | 19   | 2        |          |        |           |             |       |              |              | CURRENCY |
| vat_amount       | ÁFA érték        | DECIMAL | 19   | 2        |          |        |           |             |       |              |              | CURRENCY |
| gross_amount     | Bruttó érték     | DECIMAL | 19   | 2        |          |        |           |             |       |              |              | CURRENCY |
| order_status_did | Rendelés állapot | DICT    |      |          |          |        |           |             |       | ORDER_STATUS |              |          |

### FIGDEF# order_out_item_ext

```yaml
    label: Rendelés tétele
    pluralLabel: Rendelés tételek
    type: EXTEND
    parent: order_out_item
```

| Field        | Label            | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign      | FK          | Replacement      |
|--------------|------------------|------------|------|----------|----------|--------|-----------|-------------|------|--------------|-------------|------------------|
| vat_rate     | ÁFA kulcs        | Dictionary |      |          |          |        |           |             | DICT | VAT_RATE     | description | vat_rate_did     |
| order_status | Rendelés állapot | Dictionary |      |          |          |        |           |             | DICT | ORDER_STATUS | description | order_status_did |
