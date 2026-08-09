---
title: company.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/company.figdoc.md
doc_type: text
---

# company.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 12.8 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/company.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# company

```yaml
    label: Saját cég
    pluralLabel: Saját cégek
    type: TABLE
```

| Field             | Label                         | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign      | FK | SubType  |
|-------------------|-------------------------------|---------|------|----------|----------|--------|-----------|-------------|----|--------------|----|----------|
| id                | Id                            | IDENT   |      |          |          |        |           |             |    |              |    |          |
| short_name        | Rövid név                     | VARCHAR | 256  |          |          |        |           |             |    |              |    |          |
| name              | Név                           | VARCHAR | 2048 |          | X        |        |           |             |    |              |    |          |      
| company_form_did  | Cégforma                      | DICT    |      |          |          |        |           |             |    | COMPANY_FORM |    |          |     
| group_code        | Csoportkód                    | VARCHAR | 32   |          | X        |        |           |             |    |              |    |          |    
| code              | Kód                           | VARCHAR | 32   |          | X        |        |           |             |    |              |    |          |   
| tax_number        | Adószám                       | VARCHAR | 32   |          | X        |        |           |             |    |              |    |          |  
| eu_tax_number     | EU adószám                    | VARCHAR | 32   |          | X        |        |           |             |    |              |    |          | 
| country_did       | Székhely cím - Ország         | DICT    |      |          |          |        |           |             |    | COUNTRY      |    |          |
| zip_code          | Székhely cím - Irányítószám   | VARCHAR | 10   |          |          |        |           |             |    |              |    |          |
| settlement        | Székhely cím - Település      | VARCHAR | 128  |          |          |        |           |             |    |              |    |          |
| street_house      | Utca, házszám                 | VARCHAR | 512  |          |          |        |           |             |    |              |    |          |
| inv_country_did   | Számlázási cím - Ország       | DICT    |      |          |          |        |           |             |    | COUNTRY      |    |          |     
| inv_zip_code      | Számlázási cím - Irányítószám | VARCHAR | 10   |          |          |        |           |             |    |              |    |          |    
| inv_settlement    | Számlázási cím - Település    | VARCHAR | 128  |          |          |        |           |             |    |              |    |          |   
| inv_street_house  | Utca, házszám                 | VARCHAR | 512  |          |          |        |           |             |    |              |    |          |
| mail_country_did  | Levelezési cím - Ország       | DICT    |      |          |          |        |           |             |    | COUNTRY      |    |          |     
| mail_zip_code     | Levelezési cím - Irányítószám | VARCHAR | 10   |          |          |        |           |             |    |              |    |          |    
| mail_settlement   | Levelezési cím - Település    | VARCHAR | 128  |          |          |        |           |             |    |              |    |          |   
| mail_street_house | Utca, házszám                 | VARCHAR | 512  |          |          |        |           |             |    |              |    |          |
| margin            | Árrés                         | DECIMAL | 19   | 2        |          |        |           |             |    |              |    | PERCENT  |     
| hourly_rate       | Óradíj                        | DECIMAL | 19   | 2        |          |        |           |             |    |              |    | CURRENCY |
| distance_fee      | Távolsági díj                 | DECIMAL | 19   | 2        |          |        |           |             |    |              |    | CURRENCY |
| departure_fee     | Kiszállási díj                | DECIMAL | 19   | 2        |          |        |           |             |    |              |    | CURRENCY |
| note              | Megjegyzés                    | VARCHAR | 2048 |          | X        |        |           |             |    |              |    |          |

### FIGDEF# company_ext

```yaml
    label: Saját cég
    pluralLabel: Saját cégek
    type: EXTEND
    parent: company
```

| Field        | Label                   | Type                 | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign              | FK          | Replacement      | Hide |
|--------------|-------------------------|----------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------|-------------|------------------|------|
| company_form | Cégforma                | Dictionary           |      |          |          |        |           |             | DICT   | COMPANY_FORM         | description | company_form_did |      |
| country      | Székhely cím - Ország   | Dictionary           |      |          |          |        |           |             | DICT   | COUNTRY              | description | country_did      |      |
| workers      | Munkavállalók           | List<WorkerExt?>     |      |          |          |        |           |             | EXTEND | list:worker_ext      |             |                  | X    |
| contracts    | Szerződések             | List<ContractExt?>   |      |          |          |        |           |             | EXTEND | list:contract_ext    |             |                  | X    |
| own_contacts | Saját kapcsolattartók   | List<OwnContactExt?> |      |          |          |        |           |             | EXTEND | list:own_contact_ext |             |                  | X    |
| inv_country  | Számlázási cím - Ország | Dictionary           |      |          |          |        |           |             | DICT   | COUNTRY              | description | inv_country_did  |      |
| mail_country | Levelezési cím - Ország | Dictionary           |      |          |          |        |           |             | DICT   | COUNTRY              | description | mail_country_did |      |

### FIGDEF# company_bank_account

```yaml
    label: Cég bankszámla
    pluralLabel: Cég bankszámlák
    type: TABLE
```

| Field                   | Label                 | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign             | FK         |
|-------------------------|-----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------------|------------|
| id                      | Id                    | IDENT   |      |          |          |        |           |             |       |                     |            | 
| company_id              | Cég                   | FKIDENT |      |          |          |        |           |             | TABLE | company             | company.id |
| name                    | Bank neve             | VARCHAR | 128  |          |          |        |           |             |       |                     |            |
| country_did             | Ország                | DICT    |      |          |          |        |           |             |       | COUNTRY             |            | 
| address                 | Cím                   | VARCHAR | 2048 |          | X        |        |           |             |       |                     |            |
| swift                   | SWIFT                 | VARCHAR | 32   |          | X        |        |           |             |       |                     |            | 
| huf_bank_account_number | HUF bankszámlaszám    | VARCHAR | 64   |          | X        |        |           |             |       |                     |            | 
| huf_iban                | HUF IBAN              | VARCHAR | 32   |          | X        |        |           |             |       |                     |            | 
| dev_bank_account_number | Deviza bankszámlaszám | VARCHAR | 64   |          | X        |        |           |             |       |                     |            | 
| dev_iban                | Deviza IBAN           | VARCHAR | 32   |          | X        |        |           |             |       |                     |            | 
| currency_did            | Dev. pénzneme         | DICT    |      |          | X        |        |           |             |       | CURRENCY            |            |
| bank_account_status_did | Bszla. állapota       | DICT    |      |          |          |        |           |             |       | BANK_ACCOUNT_STATUS |            |
| note                    | Megjegyzés            | VARCHAR | 2048 |          | X        |        |           |             |       |                     |            | 

### FIGDEF# company_bank_account_ext

```yaml
    label: Cég bankszámla
    pluralLabel: Cég bankszámlái
    type: EXTEND
    parent: company_bank_account
```

| Field                          | Label                          | Type                                 | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                                | FK          | Replacement             | Hide |
|--------------------------------|--------------------------------|--------------------------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------------------------|-------------|-------------------------|------|
| country                        | Ország                         | Dictionary                           |      |          |          |        |           |             | DICT   | COUNTRY                                | description | country_did             |      |
| currency                       | Pénznem                        | Dictionary                           |      |          | X        |        |           |             | DICT   | CURRENCY                               | description | currency_did            |      |
| bank_account_status            | Bszla. állapota                | Dictionary                           |      |          | X        |        |           |             | DICT   | BANK_ACCOUNT_STATUS                    | description | bank_account_status_did |      |
| company_bank_account_documents | Company Bank Account Documents | List<CompanyBankAccountDocumentExt?> |      |          |          |        |           |             | EXTEND | list:company_bank_account_document_ext |             |                         | X    |

### FIGDEF# company_bank_account_document

```yaml
    label: Cég bankszámla dokumentuma
    pluralLabel: Cég bankszámla dokumentumok
    type: TABLE
```

| Field                   | Label            | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign              | FK                      |
|-------------------------|------------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------------------|-------------------------|
| id                      | Id               | IDENT   |      |          |          |        |           |             |       |                      |                         | 
| company_bank_account_id | Cég bankszámlája | FKIDENT |      |          |          |        |           |             | TABLE | company_bank_account | company_bank_account.id | 
| document_id             | Dokumentum       | FKIDENT |      |          |          |        |           |             | TABLE | document             | document.id             | 

### FIGDEF# company_bank_account_document_ext

```yaml
    label: Cég bankszámla dokumentuma
    pluralLabel: Cég bankszámla dokumentumok
    type: EXTEND
    parent: company_bank_account_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |
