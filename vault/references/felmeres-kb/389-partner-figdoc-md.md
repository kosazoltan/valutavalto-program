---
title: partner.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/partner.figdoc.md
doc_type: text
---

# partner.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 25.5 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/partner.figdoc.md`

## Tartalom

# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# partner

```yaml
    label: Partner
    pluralLabel: Partnerek
    type: TABLE
```

| Field                | Label                         | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign        | FK | SubType  |
|----------------------|-------------------------------|----------|------|----------|----------|--------|-----------|-------------|----|----------------|----|----------|
| id                   | Id                            | IDENT    |      |          |          |        |           |             |    |                |    |          |
| short_name           | Rövid név                     | VARCHAR  | 256  |          |          |        |           |             |    |                |    |          |
| name                 | Név                           | VARCHAR  | 2048 |          |          |        |           |             |    |                |    |          |
| company_form_did     | Cégforma                      | DICT     |      |          | X        |        |           |             |    | COMPANY_FORM   |    |          |
| partner_role_did     | Partner szerepe               | DICT     |      |          |          |        |           |             |    | PARTNER_ROLE   |    |          |
| partner_status_did   | Partner állapota              | DICT     |      |          |          |        |           |             |    | PARTNER_STATUS |    |          |
| code                 | Kód                           | VARCHAR  | 32   |          | X        |        |           |             |    |                |    |          |
| tax_number           | Adószám                       | VARCHAR  | 32   |          | X        |        |           |             |    |                |    |          |
| country_did          | Székhely - Ország             | DICT     |      |          |          |        |           |             |    | COUNTRY        |    |          |
| zip_code             | Székhely - Irányítószám       | VARCHAR  | 10   |          |          |        |           |             |    |                |    |          |
| settlement           | Székhely - Település          | VARCHAR  | 128  |          |          |        |           |             |    |                |    |          |
| street_house         | Utca, házszám                 | VARCHAR  | 512  |          |          |        |           |             |    |                |    |          |
| inv_country_did      | Számlázási cím - Ország       | DICT     |      |          |          |        |           |             |    | COUNTRY        |    |          |
| inv_zip_code         | Számlázási cím - Irányítószám | VARCHAR  | 10   |          |          |        |           |             |    |                |    |          |
| inv_settlement       | Számlázási cím - Település    | VARCHAR  | 128  |          |          |        |           |             |    |                |    |          |
| inv_street_house     | Utca, házszám                 | VARCHAR  | 512  |          |          |        |           |             |    |                |    |          |
| mail_country_did     | Levelezési cím - Ország       | DICT     |      |          |          |        |           |             |    | COUNTRY        |    |          |
| mail_zip_code        | Levelezési cím - Irányítószám | VARCHAR  | 10   |          |          |        |           |             |    |                |    |          |
| mail_settlement      | Levelezési cím - Település    | VARCHAR  | 128  |          |          |        |           |             |    |                |    |          |
| mail_street_house    | Utca, házszám                 | VARCHAR  | 512  |          |          |        |           |             |    |                |    |          |
| iban                 | IBAN                          | VARCHAR  | 32   |          | X        |        |           |             |    |                |    | IBAN     |
| swift                | SWIFT                         | VARCHAR  | 32   |          | X        |        |           |             |    |                |    | SWIFT    |
| currency_did         | Pénznem                       | DICT     |      |          | X        |        |           |             |    | CURRENCY       |    |          |
| payment_method_did   | Fizetési mód                  | DICT     |      |          | X        |        |           |             |    | PAYMENT_METHOD |    |          |
| day_to_payment       | Fizetési határidő             | SMALLINT | 5    |          | X        |        |           |             |    |                |    |          |
| legal_representative | Jogosult képviselő            | VARCHAR  | 256  |          | X        |        |           |             |    |                |    |          |
| phone                | Telefon                       | VARCHAR  | 32   |          | X        |        |           |             |    |                |    |          |
| email                | E-mail                        | VARCHAR  | 256  |          | X        |        |           |             |    |                |    | EMAIL    |
| margin               | Árrés                         | DECIMAL  | 19   | 2        | X        |        |           |             |    |                |    | PERCENT  |      
| hourly_rate          | Óradíj                        | DECIMAL  | 19   | 2        | X        |        |           |             |    |                |    | CURRENCY |
| distance_fee         | Távolsági díj                 | DECIMAL  | 19   | 2        | X        |        |           |             |    |                |    | CURRENCY |
| departure_fee        | Kiszállási díj                | DECIMAL  | 19   | 2        | X        |        |           |             |    |                |    | CURRENCY |
| note                 | Megjegyzés                    | VARCHAR  | 2048 |          | X        |        |           |             |    |                |    |          |

### FIGDEF# partner_ext

```yaml
    label: Partner
    pluralLabel: Partnerek
    type: EXTEND
    parent: partner
```

| Field            | Label                   | Type                     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                  | FK          | Replacement        | Hide |
|------------------|-------------------------|--------------------------|------|----------|----------|--------|-----------|-------------|--------|--------------------------|-------------|--------------------|------|
| company_form     | Cégforma                | Dictionary               |      |          |          |        |           |             | DICT   | COMPANY_FORM             | description | company_form_did   |      |
| partner_role     | Partner szerepe         | Dictionary               |      |          |          |        |           |             | DICT   | PARTNER_ROLE             | description | partner_role_did   |      |
| partner_status   | Partner állapota        | Dictionary               |      |          |          |        |           |             | DICT   | PARTNER_STATUS           | description | partner_status_did |      |
| sites            | Telephelyek             | List<SiteExt?>           |      |          |          |        |           |             | EXTEND | list:site_ext            |             |                    | X    |
| contracts        | Szerződések             | List<ContractExt?>       |      |          |          |        |           |             | EXTEND | list:contract_ext        |             |                    | X    |
| own_contacts     | Saját kapcsolattartók   | List<OwnContactExt?>     |      |          |          |        |           |             | EXTEND | list:own_contact_ext     |             |                    | X    |
| partner_contacts | Kapcsolattartók         | List<PartnerContactExt?> |      |          |          |        |           |             | EXTEND | list:partner_contact_ext |             |                    | X    |
| country          | Székhely - Ország       | Dictionary               |      |          |          |        |           |             | DICT   | COUNTRY                  | description | country_did        |      |
| inv_country      | Számlázási cím - Ország | Dictionary               |      |          |          |        |           |             | DICT   | COUNTRY                  | description | inv_country_did    |      |
| mail_country     | Levelezési cím - Ország | Dictionary               |      |          |          |        |           |             | DICT   | COUNTRY                  | description | mail_country_did   |      |

### FIGDEF# partner_for_import_ext

```yaml
    label: Partner
    pluralLabel: Partnerek
    type: EXTEND
    parent: partner
```

| Field            | Label                   | Type                     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                  | FK          | Replacement        | Hide |
|------------------|-------------------------|--------------------------|------|----------|----------|--------|-----------|-------------|--------|--------------------------|-------------|--------------------|------|
| company_form     | Cégforma                | Dictionary               |      |          |          |        |           |             | DICT   | COMPANY_FORM             | description | company_form_did   |      |
| partner_role     | Partner szerepe         | Dictionary               |      |          |          |        |           |             | DICT   | PARTNER_ROLE             | description | partner_role_did   |      |
| partner_status   | Partner állapota        | Dictionary               |      |          |          |        |           |             | DICT   | PARTNER_STATUS           | description | partner_status_did |      |
| sites            | Telephelyek             | List<SiteExt?>           |      |          |          |        |           |             | EXTEND | list:site_ext            |             |                    | X    |
| contracts        | Szerződések             | List<ContractExt?>       |      |          |          |        |           |             | EXTEND | list:contract_ext        |             |                    | X    |
| own_contacts     | Saját kapcsolattartók   | List<OwnContactExt?>     |      |          |          |        |           |             | EXTEND | list:own_contact_ext     |             |                    | X    |
| partner_contacts | Kapcsolattartók         | List<PartnerContactExt?> |      |          |          |        |           |             | EXTEND | list:partner_contact_ext |             |                    | X    |
| country          | Székhely - Ország       | Dictionary               |      |          |          |        |           |             | DICT   | COUNTRY                  | description | country_did        |      |
| inv_country      | Számlázási cím - Ország | Dictionary               |      |          |          |        |           |             | DICT   | COUNTRY                  | description | inv_country_did    |      |
| mail_country     | Levelezési cím - Ország | Dictionary               |      |          |          |        |           |             | DICT   | COUNTRY                  | description | mail_country_did   |      |
| common_key       | Közös kulcs             | VARCHAR                  | 512  |          | X        |        |           |             |        |                          |             |                    |      |

### FIGDEF# partner_contact

```yaml
    label: Partner kapcsolat
    pluralLabel: Partner kapcsolatok
    type: TABLE
```

| Field            | Label            | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign      | FK         | Hide |
|------------------|------------------|----------|------|----------|----------|--------|-----------|-------------|-------|--------------|------------|------|
| id               | Id               | IDENT    |      |          |          |        |           |             |       |              |            |      |
| contact_type_did | Kapcsolat típusa | DICT     |      |          |          |        |           |             |       | CONTACT_TYPE |            |      |
| last_name        | Vezetéknév       | VARCHAR  | 128  |          | X        |        |           |             |       |              |            |      |
| first_name       | Keresztnév       | VARCHAR  | 128  |          | X        |        |           |             |       |              |            |      |
| title            | Titulus          | VARCHAR  | 32   |          | X        |        |           |             |       |              |            |      |
| partner_id       | Partner          | FKIDENT  |      |          |          |        |           |             | TABLE | partner      | partner.id | X    |
| site_id          | Telephely        | FKIDENT  |      |          | X        |        |           |             | TABLE | site         | site.id    |      |
| contact          | Kapcsolat        | VARCHAR  | 256  |          |          |        |           |             |       |              |            |      |
| rank             | Rang             | SMALLINT | 5    |          | X        |        |           |             |       |              |            |      |

### FIGDEF# partner_contact_ext

```yaml
    label: Partner kapcsolat
    pluralLabel: Partner kapcsolatok
    type: EXTEND
    parent: partner_contact
```

| Field                      | Label                    | Type                             | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                           | FK          | Replacement      | Hide |
|----------------------------|--------------------------|----------------------------------|------|----------|----------|--------|-----------|-------------|--------|-----------------------------------|-------------|------------------|------|
| contact_type               | Kapcsolat típusa         | Dictionary                       |      |          |          |        |           |             | DICT   | CONTACT_TYPE                      | description | contact_type_did |      |
| site                       | Telephely                | SiteExt                          |      |          |          |        |           |             | EXTEND | site_ext                          | name        | site_id          |      |
| partner_contact_categories | Partner Contact Category | List<PartnerContactCategoryExt?> |      |          |          |        |           |             | EXTEND | list:partner_contact_category_ext |             |                  | X    |
| partner_contact_infos      | Partner Contact Info     | List<PartnerContactInfoExt?>     |      |          |          |        |           |             | EXTEND | list:partner_contact_info_ext     |             |                  | X    |

### FIGDEF# partner_contact_category

```yaml
    label: Partner kapcsolat kategória
    pluralLabel: Partner kapcsolat kategóriák
    type: TABLE
```

| Field              | Label             | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                      |
|--------------------|-------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|-------------------------|
| id                 | Id                | IDENT   |      |          |          |        |           |             |       |                 |                         | 
| partner_contact_id | Partner kapcsolat | FKIDENT |      |          |          |        |           |             | TABLE | partner_contact | partner_contact_info.id | 
| category_id        | Kategória         | FKIDENT |      |          |          |        |           |             | TABLE | category        | category.id             | 
| valid_from_date    | Érvényes-től      | DATE    |      |          | X        |        |           |             |       |                 |                         | 
| valid_to_date      | Érvényes-ig       | DATE    |      |          | X        |        |           |             |       |                 |                         | 

### FIGDEF# partner_contact_category_ext

```yaml
    label: Partner kapcsolat kategória
    pluralLabel: Partner kapcsolat kategóriák
    type: EXTEND
    parent: partner_contact_category
```

| Field    | Label     | Type         | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK |
|----------|-----------|--------------|------|----------|----------|--------|-----------|-------------|--------|--------------|----|
| category | Kategória | CategoryExt? |      |          |          |        |           |             | EXTEND | category_ext |    | 

### FIGDEF# partner_contact_info

```yaml
    label: Partner kapcsolat információ
    pluralLabel: Partner kapcsolat információk
    type: TABLE
```

| Field              | Label             | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign         | FK                 |
|--------------------|-------------------|---------|------|----------|----------|--------|-----------|-------------|-------|-----------------|--------------------|
| id                 | Id                | IDENT   |      |          |          |        |           |             |       |                 |                    | 
| partner_contact_id | Partner kapcsolat | FKIDENT |      |          |          |        |           |             | TABLE | partner_contact | partner_contact.id | 
| contact_type_did   | Kapcsolat típusa  | DICT    |      |          |          |        |           |             |       | CONTACT_TYPE    |                    | 
| info               | Információ        | VARCHAR | 256  |          |          |        |           |             |       |                 |                    | 
| valid_from_date    | Érvényes-től      | DATE    |      |          | X        |        |           |             |       |                 |                    | 
| valid_to_date      | Érvényes-ig       | DATE    |      |          | X        |        |           |             |       |                 |                    | 

### FIGDEF# partner_contact_info_ext

```yaml
    label: Partner kapcsolatok információ
    pluralLabel: Partner kapcsolatok információi
    type: EXTEND
    parent: partner_contact_info
```

| Field        | Label            | Type       | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign      | FK          | Replacement      |
|--------------|------------------|------------|------|----------|----------|--------|-----------|-------------|------|--------------|-------------|------------------|
| contact_type | Kapcsolat típusa | Dictionary |      |          |          |        |           |             | DICT | CONTACT_TYPE | description | contact_type_did |

### FIGDEF# partner_bank_account

```yaml
    label: Partner bankszámla
    pluralLabel: Partner bankszámlák
    type: TABLE
```

| Field                   | Label                 | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign             | FK         |
|-------------------------|-----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|---------------------|------------|
| id                      | Id                    | IDENT   |      |          |          |        |           |             |       |                     |            | 
| partner_id              | Partner               | FKIDENT |      |          |          |        |           |             | TABLE | partner             | partner.id |
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

### FIGDEF# partner_bank_account_ext

```yaml
    label: Partner bankszámla
    pluralLabel: Partner bankszámlái
    type: EXTEND
    parent: partner_bank_account
```

| Field                          | Label                          | Type                                 | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign                                | FK          | Replacement             | Hide |
|--------------------------------|--------------------------------|--------------------------------------|------|----------|----------|--------|-----------|-------------|--------|----------------------------------------|-------------|-------------------------|------|
| country                        | Ország                         | Dictionary                           |      |          |          |        |           |             | DICT   | COUNTRY                                | description | country_did             |      |
| currency                       | Pénznem                        | Dictionary                           |      |          | X        |        |           |             | DICT   | CURRENCY                               | description | currency_did            |      |
| bank_account_status            | Bszla. állapota                | Dictionary                           |      |          | X        |        |           |             | DICT   | BANK_ACCOUNT_STATUS                    | description | bank_account_status_did |      |
| partner_bank_account_documents | Partner Bank Account Documents | List<PartnerBankAccountDocumentExt?> |      |          |          |        |           |             | EXTEND | list:partner_bank_account_document_ext |             |                         | X    |

### FIGDEF# partner_bank_account_document

```yaml
    label: Partner bankszámla dokumentuma
    pluralLabel: Partner bankszámla dokumentumok
    type: TABLE
```

| Field                   | Label                | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign              | FK                      |
|-------------------------|----------------------|---------|------|----------|----------|--------|-----------|-------------|-------|----------------------|-------------------------|
| id                      | Id                   | IDENT   |      |          |          |        |           |             |       |                      |                         | 
| partner_bank_account_id | Partner bankszámlája | FKIDENT |      |          |          |        |           |             | TABLE | partner_bank_account | partner_bank_account.id | 
| document_id             | Dokumentum           | FKIDENT |      |          |          |        |           |             | TABLE | document             | document.id             | 

### FIGDEF# partner_bank_account_document_ext

```yaml
    label: Partner bankszámla dokumentuma
    pluralLabel: Partner bankszámla dokumentumok
    type: EXTEND
    parent: partner_bank_account_document
```

| Field    | Label      | Type        | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT     | Foreign      | FK   | Replacement |
|----------|------------|-------------|------|----------|----------|--------|-----------|-------------|--------|--------------|------|-------------|
| document | Dokumentum | DocumentExt |      |          |          |        |           |             | EXTEND | document_ext | name | document_id |
