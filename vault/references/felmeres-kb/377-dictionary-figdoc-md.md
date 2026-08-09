---
title: dictionary.figdoc.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/dictionary.figdoc.md
doc_type: text
---

# dictionary.figdoc.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 136.9 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/dictionary.figdoc.md`

## Tartalom

# Specifikáció

# Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

### Entitások

### FIGDEF# dictionary

```yaml
    label: Szótár
    pluralLabel: Szótárak
    type: TABLE
```

| Field         | Label      | Type     | Size  | Decimals | Nullable | Unique | AutoIncr. | Description | FT   | Foreign   | FK |
|---------------|------------|----------|-------|----------|----------|--------|-----------|-------------|------|-----------|----|
| id            | Id         | IDENT    |       |          |          |        |           |             |      |           |    | 
| code_type_did | Kód típusa | VARCHAR  | 64    |          |          |        |           |             | DICT | CODE_TYPE |    | 
| description   | Leírás     | VARCHAR  | 256   |          | X        |        |           |             |      |           |    | 
| note          | Megjegyzés | TEXT     | 65535 |          | X        |        |           |             |      |           |    | 
| seq           | Sorrend    | SMALLINT | 5     |          | X        |        |           |             |      |           |    | 
| contr_code    | Vezérlőkód | VARCHAR  | 128   |          | X        |        |           |             |      |           |    | 
| code          | Kód        | VARCHAR  | 64    |          |          |        |           |             |      |           |    | 

### FIGDEF# dictionary_language

```yaml
    label: Szótár nyelv
    pluralLabel: Szótár nyelvek
    type: TABLE
```

| Field         | Label      | Type    | Size  | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign    | FK            |
|---------------|------------|---------|-------|----------|----------|--------|-----------|-------------|-------|------------|---------------|
| id            | Id         | IDENT   |       |          |          |        |           |             |       |            |               | 
| dictionary_id | Szótár     | FKIDENT |       |          |          |        |           |             | TABLE | dictionary | dictionary.id | 
| description   | Leírás     | VARCHAR | 256   |          | X        |        |           |             |       |            |               | 
| note          | Megjegyzés | TEXT    | 65535 |          | X        |        |           |             |       |            |               | 
| language_did  | Nyelv      | DICT    |       |          |          |        |           |             |       | LANGUAGE   |               | 

### FIGDEF# dictionary_relation

```yaml
    label: Szótár kapcsolat
    pluralLabel: Szótár kapcsolatok
    type: TABLE
```

| Field             | Label            | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign       | FK |
|-------------------|------------------|----------|------|----------|----------|--------|-----------|-------------|----|---------------|----|
| id                | Id               | IDENT    |      |          |          |        |           |             |    |               |    | 
| code_type_1_did   | Kód típusa_1     | DICT     |      |          |          |        |           |             |    | CODE_TYPE_1   |    | 
| code_type_2_did   | Kód típusa_2     | DICT     |      |          |          |        |           |             |    | CODE_TYPE_2   |    | 
| relation_type_did | Kapcsolat típusa | DICT     |      |          |          |        |           |             |    | RELATION_TYPE |    | 
| valid_from_dt     | Érvényes-től     | DATETIME |      |          | X        |        |           |             |    |               |    | 
| valid_to_dt       | Érvényes-ig      | DATETIME |      |          | X        |        |           |             |    |               |    | 

### FIGDEF# dictionary_validity

```yaml
    label: Szótár érvényesség
    pluralLabel: Szótár érvényességek
    type: TABLE
```

| Field         | Label        | Type     | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT    | Foreign    | FK            |
|---------------|--------------|----------|------|----------|----------|--------|-----------|-------------|-------|------------|---------------|
| id            | Id           | IDENT    |      |          |          |        |           |             |       |            |               | 
| dictionary_id | Szótár       | FKIDENT  |      |          |          |        |           |             | TABLE | dictionary | dictionary.id | 
| valid_from_dt | Érvényes-től | DATETIME |      |          | X        |        |           |             |       |            |               | 
| valid_to_dt   | Érvényes-ig  | DATETIME |      |          | X        |        |           |             |       |            |               | 

## Adatszótárak

### DICTDEF# CAR_OWNER_CATEGORY

```yaml
    label: CAR_OWNER_CATEGORY
```

| Code      | Name     | Id                                   |
|-----------|----------|--------------------------------------|
| CORPORATE | céges    | 01940560-a617-7c63-9e46-aff48f2b0724 |
| EMPLOYEES | dolgozóé | 01940560-baa4-7740-94e8-bb686d7206ca |
| RENTED    | bérelt   | 01940560-cc61-7e3d-9fa0-0a52623782ab |

### DICTDEF# CATEGORY_GROUP

```yaml
    label: CATEGORY_GROUP
```

| Code            | Name                    | Id                                   |
|-----------------|-------------------------|--------------------------------------|
| CONTACT_SUBJECT | Kapcsolattartás témakör | 019406f8-b375-70d9-b93d-1c1c732bebb2 |

### DICTDEF# CODE_TYPE

```yaml
    label: CODE_TYPE
```

| Code                              | Name                                     | Id                                   |
|-----------------------------------|------------------------------------------|--------------------------------------|
| ADDRESS_TYPE                      | Cím típus                                | 019406f8-c38b-7691-9825-3fec7e4af5b5 |
| CAR_OWNERSHIP_CATEGORY            | Autó tulajdoni kategória                 | 019406f8-cfa9-7be5-9536-53e657b2cb17 |
| CATEGORY_GROUP                    | Kategória csoport                        | 019406f8-d8b6-7fa0-9edb-58499fec0497 |
| CITIZENSHIP                       | Állampolgárság                           | 019406f8-dfde-74ab-89d5-4ca05091c2c6 |
| CODE_TYPE                         | Kódcsoportok                             | 019406f8-e771-78df-b9c2-8394785dcfae |
| COMPANY_FORM                      | Cégforma                                 | 019406f8-f009-7b0d-ae02-ffabbddf0723 |
| CONTACT_TYPE                      | Elérhetőség típus                        | 019406f8-f74e-7096-8afe-b17eb2d4ca79 |
| CONTRACT_STATUS                   | Szerződés státusz                        | 019406f8-fe38-7eca-8504-d84655c33435 |
| COUNTRY                           | Ország                                   | 019406f9-0518-77ff-a59f-a1b15f8a1920 |
| DAY_TYPE                          | Nap típus                                | 019406f9-0bd6-7499-b4ff-0fb2c1aacc81 |
| DEMAND_STATUS                     | Igény státusz                            | 019406f9-1295-79b0-a78e-add23568cb5a |
| DOCUMENT_STATUS                   | Dokumentum státusz                       | 019406f9-1d30-7d77-9e47-2dbf7fc0fb73 |
| EDUCATIONAL_DEGREE                | Képzettségi fok                          | 019406f9-25ae-7a8d-9816-9a7653c8b0ed |
| EMPLOYMENT_TYPE                   | Foglalkoztatás típusa                    | 019406f9-2cdc-7d71-8fb7-f84b3f5f6b75 |
| ERROR_MESSAGE                     | Hibaüzenet                               | 019406f9-33ed-7eae-b0d9-40216ff4f7c8 |
| FEOR                              | FEOR                                     | 019406f9-3acd-7747-95e0-fdcac12cd05e |
| LANGUAGE                          | Nyelv                                    | 019406f9-42b1-7dd5-8112-4d4fc82900bd |
| MEDICAL_EXAM_RESULT               | Üzemorvosi vizsgálat eredménye           | 019406f9-4a7e-75ca-87e2-f4767ac95288 |
| MEDICAL_EXAM_STATUS               | Üzemorvosi vizsgálat státusza            | 019406f9-5145-7878-8ea0-ff05c7de6756 |
| METHOD_OF_TERMINATION             | Kilépés módja                            | 019406f9-57f1-75af-b503-d97a79014bf7 |
| OBLIGATION                        | Kötelezttség                             | 019406f9-5ed7-71af-9d3c-c5b6d5e8dab4 |
| PARTNER_STATUS                    | Partner státusz                          | 019406f9-65e2-7b10-8c54-bfeedac948c2 |
| PAYROLL_TYPE                      | Bérfizetés módja                         | 019406f9-6ca6-7572-86dc-55d0700db5aa |
| PERSON_DOCUMENT_STATUS            | Személy dokumentum státusz               | 019406f9-7338-7f7a-ad9a-e583f0f851c4 |
| POSITION                          | Beosztás                                 | 019406f9-79bb-7fbb-8370-44cf9f2b5c17 |
| QUALIFICATION_TYPE                | Képzettség                               | 019406f9-8012-7217-ad60-b95579988784 |
| REASON                            | Táppénz kategória (ok)                   | 019406f9-8704-7dea-980b-282d8b14378b |
| SETTLEMENT_BASIS                  | Elszámolás alapja                        | 019406f9-8dc0-79cd-b41e-60b057b28923 |
| SETTLEMENT_FREQUENCY              | Elszámolási periódus                     | 019406f9-93fb-77a8-afe5-6cb65269c849 |
| SICK_PAYED_PERIOD_DOCUMENT_STATUS | Táppénz dokumentum státusz               | 019406f9-9a24-7599-b53f-b5cf63e16b90 |
| STATUS                            | Táppénzes időszak státusza               | 019406f9-a01d-7353-8b81-c1d3a4072c42 |
| TASK_TYPE                         | Feladat típus                            | 019406f9-a64b-7bdb-970b-00a62680414d |
| TIME_USE_TYPE                     | idő felhasználás típus                   | 019406f9-ac8b-75ee-ba5d-c0eaf840933c |
| WORKER_DOCUMENT_STATUS            | Munkavállaló dokumentum státusz          | 019406f9-b30a-72dc-9da1-c9219b96821c |
| WORKER_NOTE_STATUS                | Munkavállalóhoz való megjegyzés státusza | 019406f9-beef-7f13-918c-7b178a8a3693 |
| WORKER_STATUS                     | Munkavállaló státusz                     | 019406f9-c527-778f-b180-ba822f6f1d25 |
| WORKING_TIME_SCHEDULE_STATUS      | Munkaidő beosztás státusz                | 019406f9-cb2b-7047-958c-539cfb54f313 |
| CURRENCY                          | Pénznem                                  | 019406f9-d13c-74f2-b632-25607e0918fa |
| INVOICE_STATE                     | Számla állapot                           | 019406f9-d923-7a98-8a46-bebd15feae3f |
| INVOICE_TYPE                      | Számla típus                             | 019406f9-df4d-75f6-9fe6-607b97a5db10 |
| PAYMENT_METHOD                    | Fizetési mód                             | 019406f9-e57a-73d9-80f4-0d11864918a2 |

### DICTDEF# COMPANY_FORM

```yaml
    label: COMPANY_FORM
```

| Code            | Name                                | Id                                   |
|-----------------|-------------------------------------|--------------------------------------|
| BT              | betéti társaság                     | 019406f9-f353-7ec8-aeea-f69f3ea5680a |
| KFT             | korlátolt felelősségű társaság      | 019406f9-f9a8-7cb4-a90d-5a41a7ec13e2 |
| KKT             | közkereseti társaság                | 019406f9-ffdd-7755-bc02-8819c7b7c469 |
| NYRT            | nyilvánosan működő részvénytársaság | 019406fa-0604-7946-85c2-54c509c440ff |
| SE              | Európai társaság                    | 019406fa-0c03-71a8-8f1f-aa50635ce729 |
| ZRT             | zártkörűen működő részvénytársaság  | 019406fa-120d-7dfc-9fcb-7939e4593c98 |
| PERSON          | Magánszemély                        | 019406fa-188f-7263-bc26-de28b1c17e74 |
| SOLE_PROPRIETOR | Egyéni vállalkozó                   | 019406fa-2106-729f-8690-046fbe0429a0 |
| OTHER           | Egyéb                               | 019406fa-2785-782c-a080-3ac06e954c6d |

### DICTDEF# CONTRACT_STATUS

```yaml
    label: CONTRACT_STATUS
```

| Code    | Name   | Id                                   |
|---------|--------|--------------------------------------|
| ACTIVE  | Aktív  | 019406fa-3812-7052-ba5a-d9d4ee68fe0e |
| EXPIRED | Lejárt | 019406fa-3e0c-7f2e-83da-b097c462cfd5 |
| PLAN    | Terv   | 019406fa-43e4-758f-9f3c-5766cfcbc985 |

### DICTDEF# COUNTRY

```yaml
    label: COUNTRY
```

| Code | Name               | Id                                   |
|------|--------------------|--------------------------------------|
| ALB  | Albánia            | 019406fa-51d9-7871-8293-9af289183bfa |
| AND  | Andorra            | 019406fa-57d7-7d52-a98f-35b1c681ffc2 |
| AUT  | Ausztria           | 019406fa-5e20-7fa2-b790-b7d3b422e966 |
| BEL  | Belgium            | 019406fa-65dc-736a-a2a5-3970574a034b |
| BGR  | Bulgária           | 019406fa-6c8a-7db9-a4d7-6edf6a5ce819 |
| BLR  | Fehéroroszország   | 019406fa-729b-74a5-948a-1a7974c13544 |
| CHE  | Svájc              | 019406fa-7860-7d64-a5fb-68d6dc91dec0 |
| CZE  | Csehország         | 019406fa-7e26-75e8-b6e4-c2ce7f4a4cd8 |
| DEU  | Németország        | 019406fa-83d5-7795-8065-4ac0e8b2e386 |
| DNK  | Dánia              | 019406fa-8f86-7c7e-8a5f-259f8096eea3 |
| ESP  | Spanyolország      | 019406fa-95fe-71b9-bad8-0b7ca8bea2bc |
| EST  | Észtország         | 019406fa-a44c-76cd-8d39-3c2a13f66d66 |
| FIN  | Finnország         | 019406fa-aabd-71a7-99c7-b85e976b90d9 |
| FRA  | Franciaország      | 019406fa-b0a8-7b58-9df2-f8a0bcc61f68 |
| GBR  | Egyesült Királyság | 019406fa-b6b6-7c41-a265-a3f3cf39c857 |
| GRC  | Görögország        | 019406fa-c359-71ff-86bb-643b0a8a73b1 |
| HRV  | Horvátország       | 019406fa-ca78-74d8-9977-985953e6fecd |
| HUN  | Magyarország       | 019406fa-d0ab-74cf-9334-c56ea0357188 |
| IRL  | Írország           | 019406fa-d722-7bbe-a21d-496fb9c25305 |
| ISL  | Izland             | 019406fa-dde0-7bf9-bfd2-0d9f9d95b90e |
| ITA  | Olaszország        | 019406fa-e789-7030-9862-ad2e27cbfea9 |
| LIE  | Liechtenstein      | 019406fa-edf0-78ad-b4e2-75c3fc34c9a9 |
| LTU  | Litvánia           | 019406fa-f9b6-7d6e-8f3d-28f9d6b259a8 |
| LUX  | Luxemburg          | 019406fb-002b-7f44-967a-639f5b08cb6d |
| LVA  | Lettország         | 019406fb-0939-7bd8-98e7-ccb91b73aded |
| MCO  | Monaco             | 019406fb-123c-7849-89fd-77cc19ef99c0 |
| MDA  | Moldova            | 019406fb-1cdc-745b-bc07-a4196eaee778 |
| MKD  | (Észak-)Macedónia  | 019406fb-2648-78d9-802e-a50fec4042a9 |
| MLT  | Málta              | 019406fb-2d2f-7e59-9beb-ed4e396710c1 |
| MNE  | Montenegró         | 019406fb-5f1f-7055-8f21-dd1db6e73729 |
| NLD  | Hollandia          | 019406fb-79a5-73be-9e37-0c1a18e7abd4 |
| NOR  | Norvégia           | 019406fb-8188-7c4d-95ae-c7bbd62d7d6d |
| POL  | Lengyelország      | 019406fb-8882-7989-b05d-1fa3c3839eff |
| PRT  | Portugália         | 019406fb-8f24-7ddc-bdda-08534a645620 |
| ROU  | Románia            | 019406fb-95e3-74f3-adb7-5b5d254cabca |
| RUS  | Oroszország        | 019406fb-9c02-76de-9f71-e06ffa0c8aa5 |
| SMR  | San Marino         | 019406fb-a1c6-7ee8-aebc-7751464370d7 |
| SRB  | Szerbia            | 019406fb-acaf-756b-9788-dc06c9080ee0 |
| SVK  | Szlovákia          | 019406fb-b2ba-71a0-8a82-4fc2402f3cbf |
| SVN  | Szlovénia          | 019406fb-b84b-74bd-87f0-77b4a51dde80 |
| SWE  | Svédország         | 019406fb-bdbe-7822-9280-00c5509ae59b |
| TUR  | Törökország        | 019406fb-c314-7967-8fda-590a3b10b6a9 |
| UKR  | Ukrajna            | 019406fb-c8be-7892-a7b0-c61184e26b33 |
| VAT  | Vatikán            | 019406fb-ce3e-7c71-990e-c872e9f9b17c |
| USA  | Egyesült Államok   | 019406fb-d2f0-7b8c-9a4d-5e1f3b6c3d1e |
| CAN  | Kanada             | 019406fb-d7a2-7b8c-9a4d-5e1f3b6c3d1e |

### DICTDEF# DAY_TYPE

```yaml
    label: DAY_TYPE
```

| Code    | Name     | Id                                   |
|---------|----------|--------------------------------------|
| HOLIDAY | Ünnepnap | 019406fb-e4dc-7946-bdef-3a9563e31b0b |
| SUNDAY  | Vasárnap | 019406fb-eb13-7408-b386-df93d83b5fb5 |
| WORK    | Munkanap | 019406fb-f114-7e66-933c-cc1bfd852569 |

### DICTDEF# DEMAND_STATUS

```yaml
    label: DEMAND_STATUS
```

| Code    | Name   | Id                                   |
|---------|--------|--------------------------------------|
| ACTIVE  | Élő    | 019406fb-fe1a-7104-ae01-77082838086a |
| CLOSED  | Lezárt | 019406fc-048c-73e7-951b-b897d1103afb |
| DELETED | Törölt | 019406fc-0c6b-7c98-bdce-d004740b3c85 |
| PLAN    | Terv   | 019406fc-131e-7468-ba4e-dcab75954681 |

### DICTDEF# DOCUMENT_STATUS

```yaml
    label: DOCUMENT_STATUS
```

| Code      | Name     | Id                                   |
|-----------|----------|--------------------------------------|
| ACTIVE    | aktív    | 019406fc-218e-70d5-92f6-b6435cbad1bc |
| ASKED     | bekért   | 019406fc-2854-7835-817c-7974de5de2ba |
| EXPIRED   | lejárt   | 019406fc-3004-724d-bcd5-f3c5b6c46e24 |
| REQUESTED | igényelt | 019406fc-37af-70d8-8bad-6cbd00488a2b |

### DICTDEF# EDUCATION_DEGREE

```yaml
    label: EDUCATION_DEGREE
```

| Code         | Name                       | Id                                   |
|--------------|----------------------------|--------------------------------------|
| BSC          | BSC                        | 019406fc-4d91-7ad9-ac9a-3d3143fae64a |
| GENERAL      | 8 általános                | 019406fc-5404-7924-927c-5f2a00444a20 |
| HIGH_SCHOOL  | gimnáziumi érettségi       | 019406fc-5d0f-7830-bc76-3467f5443cca |
| MSC          | MSC                        | 019406fc-6754-7b3a-ae66-8c7a0439b933 |
| SEC_SCHOOL   | szakközépiskolai érettségi | 019406fc-6e62-7427-8111-6f05c012b1f9 |
| VOC_TRAINING | szakmunkásképző            | 019406fc-7762-7fa1-916b-e6bb97808c73 |

### DICTDEF# EMPLOYMENT_TYPE

```yaml
    label: EMPLOYMENT_TYPE
```

| Code     | Name                         | Id                                   |
|----------|------------------------------|--------------------------------------|
| FULLTIME | teljes munkaidős alkalmazott | 019406fc-ef89-733e-b64a-6c6254d42d43 |
| PARTTIME | részmunkaidős alkalmazott    | 019406fc-f635-7739-a171-5cfe15063d58 |
| RENDTED  | bérelt                       | 019406fc-fc97-7302-ae3a-61bfeacffb0b |
| EXTERNAL | Külsős                       | 01940701-fb8e-7b4b-8b4b-0f3b1f7b1b8c |
| RETIRED  | Nyugdíjas                    | 01940701-01c0-7da3-9183-4ca78d6d1cdf |
| STUDENT  | Diák                         | 01940701-0a3b-7b4e-9b4b-0f3b1f7b1b8d |

### DICTDEF# ERROR_MESSAGE

```yaml
    label: ERROR_MESSAGE
```

| Code            | Name              | Id                                   |
|-----------------|-------------------|--------------------------------------|
| CLIENT_UNIQ_001 | Nem egyedi kliens | 019406fd-0a96-7a38-a8f2-e5d415eda6f3 |

### DICTDEF# FEOR

```yaml
    label: FEOR
```

| Code | Name                                                                                           | Id                                   |
|------|------------------------------------------------------------------------------------------------|--------------------------------------|
| 11   | Törvényhozók, igazgatási és érdek-képviseleti vezetők                                          | 019406fd-da6d-71be-9c3e-bdb2ecfc6c01 | 
| 1    | Fegyveres szervek felsőfokú képesítést igénylő foglalkozásai                                   | 019406fd-da6d-71be-9c3e-bdb3934e446a | 
| 111  | Törvényhozók, miniszterek, államtitkárok                                                       | 019406fd-da6d-71be-9c3e-bdb44a97748e | 
| 1110 | Törvényhozó, miniszter, államtitkár                                                            | 019406fd-da6d-71be-9c3e-bdb56213c64e | 
| 112  | Országos és területi közigazgatás, igazságszolgáltatás vezetői                                 | 019406fd-da6d-71be-9c3e-bdb6bd1a3212 | 
| 1121 | Országos és területi közigazgatás, igazságszolgáltatás vezetője                                | 019406fd-da6d-71be-9c3e-bdb7b3666641 | 
| 1122 | Helyi önkormányzat választott vezetője                                                         | 019406fd-da6d-71be-9c3e-bdb8be249c2c | 
| 1123 | Helyi önkormányzat kinevezett vezetője                                                         | 019406fd-da6d-71be-9c3e-bdb92db88048 | 
| 113  | Országos és területi társadalmi (érdek-képviseleti), és egyéb szervezetek vezetői              | 019406fd-da6d-71be-9c3e-bdba5a498981 | 
| 1131 | Társadalmi (érdek-képviseleti) és egyéb szervezet vezetője                                     | 019406fd-da6d-71be-9c3e-bdbb603cfeaa | 
| 1132 | Egyházi vezető                                                                                 | 019406fd-da6d-71be-9c3e-bdbcb4c199fa | 
| 12   | Gazdasági, költségvetési szervezetek vezetői                                                   | 019406fd-da6d-71be-9c3e-bdbdf57996be | 
| 1210 | Gazdasági, költségvetési szervezet vezetője (igazgató, elnök, ügyvezető igazgató)              | 019406fd-da6d-71be-9c3e-bdbe185aa3e3 | 
| 13   | Termelési és szolgáltatást nyújtó egységek vezetői                                             | 019406fd-da6d-71be-9c3e-bdbfdbd93c35 | 
| 131  | Termelési egységek vezetői                                                                     | 019406fd-da6d-71be-9c3e-bdc0ec3f9816 | 
| 1311 | Mezőgazdasági, erdészeti, halászati és vadászati tevékenységet folytató egység vezetője        | 019406fd-da6d-71be-9c3e-bdc1f6fc6188 | 
| 1312 | Ipari tevékenységet folytató egység vezetője                                                   | 019406fd-da6d-71be-9c3e-bdc292fb6f89 | 
| 1313 | Építőipari tevékenységet folytató egység vezetője                                              | 019406fd-da6d-71be-9c3e-bdc383adb3fe | 
| 132  | Szolgáltatást nyújtó egységek vezetői                                                          | 019406fd-da6d-71be-9c3e-bdc4edabd3d2 | 
| 1321 | Szállítási, logisztikai és raktározási tevékenységet folytató egység vezetője                  | 019406fd-da6d-71be-9c3e-bdc5f5683990 | 
| 1322 | Informatikai és telekommunikációs tevékenységet folytató egység vezetője                       | 019406fd-da6d-71be-9c3e-bdc67c0d6c5c | 
| 1323 | Pénzintézeti tevékenységet folytató egység vezetője                                            | 019406fd-da6d-71be-9c3e-bdc72950fe5b | 
| 1324 | Szociális tevékenységet folytató egység vezetője                                               | 019406fd-da6d-71be-9c3e-bdc889fe490c | 
| 1325 | Gyermekgondozási tevékenységet folytató egység vezetője                                        | 019406fd-da6d-71be-9c3e-bdc9a3f9149f | 
| 1326 | Idősgondozási tevékenységet folytató egység vezetője                                           | 019406fd-da6d-71be-9c3e-bdca6eedf4f5 | 
| 1327 | Egészségügyi tevékenységet folytató egység vezetője                                            | 019406fd-da6d-71be-9c3e-bdcb38ea6ce0 | 
| 1328 | Oktatási-nevelési tevékenységet folytató egység vezetője                                       | 019406fd-da6d-71be-9c3e-bdcc516a698c | 
| 1329 | Egyéb szolgáltatást nyújtó egység vezetője                                                     | 019406fd-da6d-71be-9c3e-bdcd8638c701 | 
| 133  | Kereskedelmi, vendéglátó és hasonló szolgáltatási tevékenységet folytató egységek vezetői      | 019406fd-da6d-71be-9c3e-bdce19ce662f | 
| 1331 | Szálláshely-szolgáltatási tevékenységet folytató egység vezetője                               | 019406fd-da6d-71be-9c3e-bdcfd4bca784 | 
| 1332 | Vendéglátó tevékenységet folytató egység vezetője                                              | 019406fd-da6d-71be-9c3e-bdd0c92ca6b9 | 
| 1333 | Kereskedelmi tevékenységet folytató egység vezetője                                            | 019406fd-da6d-71be-9c3e-bdd1f600415c | 
| 1334 | Üzleti szolgáltatási tevékenységet folytató egység vezetője                                    | 019406fd-da6d-71be-9c3e-bdd2f98a9395 | 
| 1335 | Kulturális tevékenységet folytató egység vezetője                                              | 019406fd-da6d-71be-9c3e-bdd3c138d219 | 
| 1336 | Sport- és rekreációs tevékenységet folytató egység vezetője                                    | 019406fd-da6d-71be-9c3e-bdd47cf0826f | 
| 1339 | Egyéb kereskedelmi, vendéglátó és hasonló szolgáltatási tevékenységet folytató egység vezetője | 019406fd-da6d-71be-9c3e-bdd5f5d32a4a | 
| 14   | Gazdasági tevékenységet segítő egységek vezetői                                                | 019406fd-da6d-71be-9c3e-bdd643c5645b | 
| 1411 | Számviteli és pénzügyi tevékenységet folytató egység vezetője                                  | 019406fd-da6d-71be-9c3e-bdd7b642d792 | 
| 1412 | Személyzeti vezető, humánpolitikai egység vezetője                                             | 019406fd-da6d-71be-9c3e-bdd8d861d50a | 
| 1413 | Kutatási és fejlesztési tevékenységet folytató egység vezetője                                 | 019406fd-da6d-71be-9c3e-bdd973f71919 | 
| 1414 | Vállalati stratégiatervezési egység vezetője                                                   | 019406fd-da6d-71be-9c3e-bddaba73040b | 
| 1415 | Értékesítési és marketingtevékenységet folytató egység vezetője                                | 019406fd-da6d-71be-9c3e-bddb260d39a6 | 
| 1416 | Reklám-, PR- és egyéb kommunikációs tevékenységet folytató egység vezetője                     | 019406fd-da6d-71be-9c3e-bddc2de75eac | 
| 1419 | Egyéb gazdasági tevékenységet segítő egység vezetője                                           | 019406fd-da6d-71be-9c3e-bddd106cfc1c | 
| 2    | Fegyveres szervek középfokú képesítést igénylő foglalkozásai                                   | 019406fd-da6d-71be-9c3e-bdde47c13a11 | 
| 21   | Műszaki, informatikai és természettudományi foglalkozások                                      | 019406fd-da6d-71be-9c3e-bddfabb58f9d | 
| 211  | Ipari, építőipari mérnökök                                                                     | 019406fd-da6d-71be-9c3e-bde0b7cbc892 | 
| 2111 | Bányamérnök                                                                                    | 019406fd-da6d-71be-9c3e-bde11804a9ad | 
| 2112 | Kohó- és anyagmérnök                                                                           | 019406fd-da6d-71be-9c3e-bde247711490 | 
| 2113 | Élelmiszer-ipari mérnök                                                                        | 019406fd-da6d-71be-9c3e-bde3e0176dbf | 
| 2114 | Fa- és könnyűipari mérnök                                                                      | 019406fd-da6d-71be-9c3e-bde4c27a30f2 | 
| 2115 | Építészmérnök                                                                                  | 019406fd-da6d-71be-9c3e-bde5f409fa52 | 
| 2116 | Építőmérnök                                                                                    | 019406fd-da6d-71be-9c3e-bde6a02d57ba | 
| 2117 | Vegyészmérnök                                                                                  | 019406fd-da6d-71be-9c3e-bde762ceaede | 
| 2118 | Gépészmérnök                                                                                   | 019406fd-da6d-71be-9c3e-bde8ccc3cd8c | 
| 212  | Elektromérnökök                                                                                | 019406fd-da6d-71be-9c3e-bde95fa09494 | 
| 2121 | Villamosmérnök (energetikai mérnök)                                                            | 019406fd-da6d-71be-9c3e-bdea29ed1607 | 
| 2122 | Villamosmérnök (elektronikai mérnök)                                                           | 019406fd-da6d-71be-9c3e-bdeb7ff4a17a | 
| 2123 | Telekommunikációs mérnök                                                                       | 019406fd-da6d-71be-9c3e-bdec042ffb3c | 
| 213  | Egyéb mérnökök                                                                                 | 019406fd-da6d-71be-9c3e-bded9dbaa883 | 
| 2131 | Mezőgazdasági mérnök                                                                           | 019406fd-da6d-71be-9c3e-bdee7c9c6ebe | 
| 2132 | Erdő- és természetvédelmi mérnök                                                               | 019406fd-da6d-71be-9c3e-bdef9fde51c1 | 
| 2133 | Táj- és kertépítészmérnök                                                                      | 019406fd-da6d-71be-9c3e-bdf06e4ccbe2 | 
| 2134 | Település- és közlekedéstervező mérnök                                                         | 019406fd-da6d-71be-9c3e-bdf1e6d9e63a | 
| 2135 | Földmérő és térinformatikus                                                                    | 019406fd-da6d-71be-9c3e-bdf243a749aa | 
| 2136 | Grafikus és multimédia-tervező                                                                 | 019406fd-da6e-7699-a42b-3d3e6c18fe09 | 
| 2137 | Minőségbiztosítási mérnök                                                                      | 019406fd-da6e-7699-a42b-3d3f295453da | 
| 2139 | Egyéb, máshova nem sorolható mérnök                                                            | 019406fd-da6e-7699-a42b-3d4091003da9 | 
| 214  | Szoftver- és alkalmazásfejlesztők, -elemzők                                                    | 019406fd-da6e-7699-a42b-3d41dd600d19 | 
| 2141 | Rendszerelemző (informatikai)                                                                  | 019406fd-da6e-7699-a42b-3d42f7b8ca7c | 
| 2142 | Szoftverfejlesztő                                                                              | 019406fd-da6e-7699-a42b-3d437929122c | 
| 2143 | Hálózat- és multimédia-fejlesztő                                                               | 019406fd-da6e-7699-a42b-3d44ea6a2efc | 
| 2144 | Alkalmazásprogramozó                                                                           | 019406fd-da6e-7699-a42b-3d459bba07a3 | 
| 2149 | Egyéb szoftver- és alkalmazásfejlesztő, -elemző                                                | 019406fd-da6e-7699-a42b-3d460fad204b | 
| 215  | Adatbázis- és hálózati elemzők, üzemeltetők                                                    | 019406fd-da6e-7699-a42b-3d47908f8d9f | 
| 2151 | Adatbázis-tervező és -üzemeltető                                                               | 019406fd-da6e-7699-a42b-3d4845cd9108 | 
| 2152 | Rendszergazda                                                                                  | 019406fd-da6e-7699-a42b-3d49bc626f7b | 
| 2153 | Számítógép-hálózati elemző, üzemeltető                                                         | 019406fd-da6e-7699-a42b-3d4ac2eb1136 | 
| 2159 | Egyéb adatbázis- és hálózati elemző, üzemeltető                                                | 019406fd-da6e-7699-a42b-3d4bdf972e40 | 
| 216  | Természettudományi foglalkozások                                                               | 019406fd-da6e-7699-a42b-3d4c50f82baf | 
| 2161 | Fizikus                                                                                        | 019406fd-da6e-7699-a42b-3d4d94f48474 | 
| 2162 | Csillagász                                                                                     | 019406fd-da6e-7699-a42b-3d4eedfdec09 | 
| 2163 | Meteorológus                                                                                   | 019406fd-da6e-7699-a42b-3d4fa9339a93 | 
| 2164 | Kémikus                                                                                        | 019406fd-da6e-7699-a42b-3d5012fddfa9 | 
| 2165 | Geológus                                                                                       | 019406fd-da6e-7699-a42b-3d512a0d8811 | 
| 2166 | Matematikus                                                                                    | 019406fd-da6e-7699-a42b-3d529ba50dc9 | 
| 2167 | Biológus, botanikus, zoológus és rokon foglalkozású                                            | 019406fd-da6e-7699-a42b-3d537990da64 | 
| 2168 | Környezetfelmérő, -tanácsadó                                                                   | 019406fd-da6e-7699-a42b-3d548d25ae77 | 
| 2169 | Egyéb természettudományi foglalkozású                                                          | 019406fd-da6e-7699-a42b-3d5548aab949 | 
| 22   | Egészségügyi foglalkozások (felsőfokú képzettséghez kapcsolódó)                                | 019406fd-da6e-7699-a42b-3d562ff8634f | 
| 221  | Orvosi, gyógyszerészi foglalkozások                                                            | 019406fd-da6e-7699-a42b-3d57a3a9b649 | 
| 2211 | Általános orvos                                                                                | 019406fd-da6e-7699-a42b-3d58523e3161 | 
| 2212 | Szakorvos                                                                                      | 019406fd-da6e-7699-a42b-3d595ad653ca | 
| 2213 | Fogorvos, fogszakorvos                                                                         | 019406fd-da6e-7699-a42b-3d5ac109fec2 | 
| 2214 | Gyógyszerész, szakgyógyszerész                                                                 | 019406fd-da6e-7699-a42b-3d5b7129c05c | 
| 222  | Humán-egészségügyi (társ)foglalkozások                                                         | 019406fd-da6e-7699-a42b-3d5ce111df0e | 
| 2221 | Környezet- és foglalkozás-egészségügyi foglalkozású                                            | 019406fd-da6e-7699-a42b-3d5decc59830 | 
| 2222 | Optometrista                                                                                   | 019406fd-da6e-7699-a42b-3d5e6afc1758 | 
| 2223 | Dietetikus és táplálkozási tanácsadó                                                           | 019406fd-da6e-7699-a42b-3d5fcdf64093 | 
| 2224 | Gyógytornász                                                                                   | 019406fd-da6e-7699-a42b-3d60cbded15a | 
| 2225 | Védőnő                                                                                         | 019406fd-da6e-7699-a42b-3d6157e63b19 | 
| 2226 | Mentőtiszt                                                                                     | 019406fd-da6e-7699-a42b-3d62eb393617 | 
| 2227 | Hallás- és beszédterapeuta                                                                     | 019406fd-da6e-7699-a42b-3d632375d544 | 
| 2228 | Alternatív gyógymódot alkalmazó                                                                | 019406fd-da6e-7699-a42b-3d64a64eec8a | 
| 2229 | Egyéb humán-egészségügyi (társ)foglalkozású                                                    | 019406fd-da6e-7699-a42b-3d65c8e4aa0a | 
| 223  | Ápoló, szülész(nő) (felsőfokú képzettséghez kapcsolódó)                                        | 019406fd-da6e-7699-a42b-3d664f4785f2 | 
| 2231 | Ápoló (felsőfokú képzettséghez kapcsolódó)                                                     | 019406fd-da6e-7699-a42b-3d676fdc7daa | 
| 2232 | Szülész(nő) (felsőfokú képzettséghez kapcsolódó)                                               | 019406fd-da6e-7699-a42b-3d687990847c | 
| 224  | Állat- és növény-egészségügyi foglalkozások                                                    | 019406fd-da6e-7699-a42b-3d69e9427e30 | 
| 2241 | Állatorvos                                                                                     | 019406fd-da6e-7699-a42b-3d6a1ee89738 | 
| 2242 | Növényorvos (növényvédelmi szakértő)                                                           | 019406fd-da6e-7699-a42b-3d6b16f51d93 | 
| 23   | Szociális szolgáltatási foglalkozások (felsőfokú képzettséghez kapcsolódó)                     | 019406fd-da6e-7699-a42b-3d6cd87e8296 | 
| 231  | zociális szolgáltatási foglalkozások                                                           | 019406fd-da6e-7699-a42b-3d6d23c19616 | 
| 2311 | Szociálpolitikus                                                                               | 019406fd-da6e-7699-a42b-3d6e86de804b | 
| 2312 | Szociális munkás és tanácsadó                                                                  | 019406fd-da6e-7699-a42b-3d6f69681b92 | 
| 24   | Oktatók, pedagógusok                                                                           | 019406fd-da6e-7699-a42b-3d70382b58ee | 
| 241  | Felsőoktatási intézményi oktatók, tanárok                                                      | 019406fd-da6e-7699-a42b-3d713a9988b9 | 
| 2410 | Egyetemi, főiskolai oktató, tanár                                                              | 019406fd-da6e-7699-a42b-3d725abbccb3 | 
| 242  | özépfokú nevelési-oktatási intézményi oktatók, tanárok                                         | 019406fd-da6e-7699-a42b-3d7399cf35cf | 
| 2421 | Középiskolai tanár                                                                             | 019406fd-da6e-7699-a42b-3d7497b3d4fe | 
| 2422 | Középfokú nevelési-oktatási intézményi szakoktató, gyakorlati oktató                           | 019406fd-da6e-7699-a42b-3d759135c981 | 
| 243  | Óvodai és alapfokú nevelési-oktatási intézményi tanárok, oktatók, nevelők                      | 019406fd-da6e-7699-a42b-3d76d36d3d4a | 
| 2431 | Általános iskolai tanár, tanító                                                                | 019406fd-da6e-7699-a42b-3d77107607db | 
| 2432 | Csecsemő- és kisgyermeknevelő, óvodapedagógus                                                  | 019406fd-da6e-7699-a42b-3d7825e9f36c | 
| 244  | Speciális oktatók, nevelők                                                                     | 019406fd-da6e-7699-a42b-3d79c0bda7a6 | 
| 2441 | Gyógypedagógus                                                                                 | 019406fd-da6e-7699-a42b-3d7a3d10c545 | 
| 2442 | Konduktor                                                                                      | 019406fd-da6e-7699-a42b-3d7be98bc359 | 
| 249  | gyéb szakképzett oktatók, nevelők                                                              | 019406fd-da6e-7699-a42b-3d7cd9e59fa7 | 
| 2491 | Pedagógiai szakértő, szaktanácsadó                                                             | 019406fd-da6e-7699-a42b-3d7d1e02579a | 
| 2492 | Nyelvtanár (iskolarendszeren kívül)                                                            | 019406fd-da6e-7699-a42b-3d7e5c8c00e9 | 
| 2493 | Zenetanár (iskolarendszeren kívül)                                                             | 019406fd-da6e-7699-a42b-3d7f494aacf4 | 
| 2494 | Egyéb művészetek tanára (iskolarendszeren kívül)                                               | 019406fd-da6e-7699-a42b-3d802fd74c43 | 
| 2495 | Informatikatanár (iskolarendszeren kívül)                                                      | 019406fd-da6e-7699-a42b-3d81804a3bee | 
| 2499 | Egyéb szakképzett oktató, nevelő                                                               | 019406fd-da6e-7699-a42b-3d828a97fb0b | 
| 25   | Gazdálkodási jellegű foglalkozások                                                             | 019406fd-da6e-7699-a42b-3d837589d230 | 
| 251  | Pénzügyi és számviteli foglalkozások                                                           | 019406fd-da6e-7699-a42b-3d84f3863dc7 | 
| 2511 | Pénzügyi elemző és befektetési tanácsadó                                                       | 019406fd-da6e-7699-a42b-3d85e8758379 | 
| 2512 | Adótanácsadó, adószakértő                                                                      | 019406fd-da6e-7699-a42b-3d86359ef035 | 
| 2513 | Könyvvizsgáló, könyvelő, könyvszakértő                                                         | 019406fd-da6e-7699-a42b-3d8751010f30 | 
| 2514 | Kontroller                                                                                     | 019406fd-da6e-7699-a42b-3d8827d029a8 | 
| 252  | Szervezetirányítási, üzletpolitikai foglalkozások                                              | 019406fd-da6e-7699-a42b-3d890bf2ec17 | 
| 2521 | Szervezetirányítási elemző, szervező                                                           | 019406fd-da6e-7699-a42b-3d8ac1d377f1 | 
| 2522 | Üzletpolitikai elemző, szervező                                                                | 019406fd-da6e-7699-a42b-3d8bc3f8430e | 
| 2523 | Személyzeti és pályaválasztási szakértő                                                        | 019406fd-da6e-7699-a42b-3d8cd8b21ed9 | 
| 2524 | Képzési és személyzetfejlesztési szakértő                                                      | 019406fd-da6e-7699-a42b-3d8d2b1bafde | 
| 253  | Kereskedelmi és marketingfoglalkozások                                                         | 019406fd-da6e-7699-a42b-3d8ea28cedc0 | 
| 2531 | Piackutató, reklám- és marketingtevékenységet tervező, szervező                                | 019406fd-da6e-7699-a42b-3d8f8afc52e1 | 
| 2532 | PR-tevékenységet tervező, szervező                                                             | 019406fd-da6e-7699-a42b-3d908b491a62 | 
| 2533 | Kereskedelmi tervező, szervező                                                                 | 019406fd-da6e-7699-a42b-3d9141612eb9 | 
| 2534 | Informatikai és telekommunikációs technológiai termékek értékesítéséttervező, szervező         | 019406fd-da6e-7699-a42b-3d928ab11da1 | 
| 26   | Jogi és társadalomtudományi foglalkozások                                                      | 019406fd-da6e-7699-a42b-3d93e4e99e83 | 
| 261  | Jogi foglalkozások                                                                             | 019406fd-da6e-7699-a42b-3d944acf8b3c | 
| 2611 | Jogász, jogtanácsos                                                                            | 019406fd-da6e-7699-a42b-3d95379d7c46 | 
| 2612 | Ügyész                                                                                         | 019406fd-da6e-7699-a42b-3d96e5779d1f | 
| 2613 | Bíró                                                                                           | 019406fd-da6e-7699-a42b-3d97d2d723d3 | 
| 2614 | Közjegyző                                                                                      | 019406fd-da6e-7699-a42b-3d98fa0ad127 | 
| 2615 | Ügyvéd                                                                                         | 019406fd-da6e-7699-a42b-3d99f2a2eff8 | 
| 2619 | Egyéb jogi foglalkozású                                                                        | 019406fd-da6e-7699-a42b-3d9a3b4ab7cb | 
| 262  | Társadalomtudományi foglalkozások                                                              | 019406fd-da6e-7699-a42b-3d9b0882ee9c | 
| 2621 | Filozófus, politológus                                                                         | 019406fd-da6e-7699-a42b-3d9c8ff0e1f8 | 
| 2622 | Történész, régész                                                                              | 019406fd-da6e-7699-a42b-3d9d8b2d0000 | 
| 2623 | Néprajzkutató                                                                                  | 019406fd-da6e-7699-a42b-3d9e231096b2 | 
| 2624 | Elemző közgazdász                                                                              | 019406fd-da6e-7699-a42b-3d9f2afbbc67 | 
| 2625 | Statisztikus                                                                                   | 019406fd-da6e-7699-a42b-3da0c9a45e51 | 
| 2626 | Szociológus, demográfus                                                                        | 019406fd-da6e-7699-a42b-3da1fb1803b6 | 
| 2627 | Nyelvész, fordító, tolmács                                                                     | 019406fd-da6e-7699-a42b-3da29bf3f6c3 | 
| 2628 | Pszichológus                                                                                   | 019406fd-da6e-7699-a42b-3da35c734ebe | 
| 2629 | Egyéb társadalomtudományi foglalkozású                                                         | 019406fd-da6e-7699-a42b-3da406d64b44 | 
| 27   | Kulturális, sport-, művészeti és vallási foglalkozások (felsőfokú képzettséghez kapcsolódó)    | 019406fd-da6e-7699-a42b-3da5cacda17a | 
| 271  | Kulturális és sportfoglalkozások (felsőfokú képzettséghez kapcsolódó)                          | 019406fd-da6e-7699-a42b-3da65e334de2 | 
| 2711 | Könyvtáros, informatikus könyvtáros                                                            | 019406fd-da6e-7699-a42b-3da74f0be474 | 
| 2712 | Levéltáros                                                                                     | 019406fd-da6e-7699-a42b-3da8b9a7f81f | 
| 2713 | Muzeológus, múzeumi gyűjteménygondnok                                                          | 019406fd-da6e-7699-a42b-3da9221ed163 | 
| 2714 | Kulturális szervező                                                                            | 019406fd-da6e-7699-a42b-3daa05b01cbb | 
| 2715 | Könyv- és lapkiadó szerkesztője                                                                | 019406fd-da6e-7699-a42b-3dab26a5ca49 | 
| 2716 | Újságíró, rádióműsor-, televízióműsor-szerkesztő                                               | 019406fd-da6e-7699-a42b-3dacbd2a3a11 | 
| 2717 | Szakképzett edző, sportszervező, -irányító                                                     | 019406fd-da6e-7699-a42b-3dadef34dafe | 
| 2719 | Egyéb kulturális és sportfoglalkozású (felsőfokú képzettséghez kapcsolódó)                     | 019406fd-da6e-7699-a42b-3dae9f5b0e7e | 
| 272  | lkotó- és előadó-művészi foglalkozások (felsőfokú képzettséghez kapcsolódó)                    | 019406fd-da6e-7699-a42b-3daf4bb35b9f | 
| 2721 | Író (újságíró nélkül)                                                                          | 019406fd-da6e-7699-a42b-3db09a1558ea | 
| 2722 | Képzőművész                                                                                    | 019406fd-da6e-7699-a42b-3db1df80cc94 | 
| 2723 | Iparművész, gyártmány- és ruhatervező                                                          | 019406fd-da6e-7699-a42b-3db262387e53 | 
| 2724 | Zeneszerző, zenész, énekes                                                                     | 019406fd-da6e-7699-a42b-3db3aae8fbbb | 
| 2725 | Rendező, operatőr                                                                              | 019406fd-da6e-7699-a42b-3db47b420509 | 
| 2726 | Színész, bábművész                                                                             | 019406fd-da6e-7699-a42b-3db59c55ec81 | 
| 2727 | Táncművész, koreográfus                                                                        | 019406fd-da6e-7699-a42b-3db6ded61063 | 
| 2728 | Cirkuszi- és hasonló előadóművész                                                              | 019406fd-da6e-7699-a42b-3db74d9ce348 | 
| 2729 | Egyéb alkotó- és előadó-művészi foglalkozású (felsőfokú képzettséghez kapcsolódó)              | 019406fd-da6e-7699-a42b-3db878a82588 | 
| 273  | Vallási foglalkozások (felsőfokú képzettséghez kapcsolódó)                                     | 019406fd-da6e-7699-a42b-3db923b0a67f | 
| 2730 | Pap (lelkész), egyházi foglalkozású                                                            | 019406fd-da6e-7699-a42b-3dbab6bc0cc9 | 
| 29   | Egyéb magasan képzett ügyintézők                                                               | 019406fd-da6e-7699-a42b-3dbbde188406 | 
| 291  | gyéb magasan képzett ügyintézők                                                                | 019406fd-da6e-7699-a42b-3dbce63392bc | 
| 2910 | Egyéb magasan képzett ügyintéző                                                                | 019406fd-da6e-7699-a42b-3dbda906f7c9 | 
| 3    | Fegyveres szervek középfokú képesítést nem igénylő foglalkozásai                               | 019406fd-da6e-7699-a42b-3dbe24bd814e | 
| 31   | Technikusok és hasonló műszaki foglalkozások                                                   | 019406fd-da6e-7699-a42b-3dbf4264916b | 
| 311  | Ipari, építőipari technikusok                                                                  | 019406fd-da6e-7699-a42b-3dc05c600465 | 
| 3111 | Bányászati technikus                                                                           | 019406fd-da6e-7699-a42b-3dc1ce189fb5 | 
| 3112 | Kohó- és anyagtechnikus                                                                        | 019406fd-da6e-7699-a42b-3dc2ed2215eb | 
| 3113 | Élelmiszer-ipari technikus                                                                     | 019406fd-da6e-7699-a42b-3dc357766e2c | 
| 3114 | Fa- és könnyűipari technikus                                                                   | 019406fd-da6e-7699-a42b-3dc41827ba7d | 
| 3115 | Vegyésztechnikus                                                                               | 019406fd-da6e-7699-a42b-3dc58328e211 | 
| 3116 | Gépésztechnikus                                                                                | 019406fd-da6e-7699-a42b-3dc6fd07a3eb | 
| 3117 | Építő- és építésztechnikus                                                                     | 019406fd-da6e-7699-a42b-3dc7bee46df7 | 
| 312  | Elektrotechnikusok                                                                             | 019406fd-da6e-7699-a42b-3dc89e772dbc | 
| 3121 | Villamosipari technikus (energetikai technikus)                                                | 019406fd-da6e-7699-a42b-3dc93eed36f7 | 
| 3122 | Villamosipari technikus (elektronikai technikus)                                               | 019406fd-da6e-7699-a42b-3dca26fbd33c | 
| 313  | Egyéb technikusok                                                                              | 019406fd-da6e-7699-a42b-3dcb88227352 | 
| 3131 | Mezőgazdasági technikus                                                                        | 019406fd-da6e-7699-a42b-3dccaf3e93b3 | 
| 3132 | Erdő- és természetvédelmi technikus                                                            | 019406fd-da6e-7699-a42b-3dcd5d599c14 | 
| 3133 | Földmérő és térinformatikai technikus                                                          | 019406fd-da6e-7699-a42b-3dce74359fa4 | 
| 3134 | Környezetvédelmi technikus                                                                     | 019406fd-da6e-7699-a42b-3dcf21794cc2 | 
| 3135 | Minőségbiztosítási technikus                                                                   | 019406fd-da6e-7699-a42b-3dd0f312233f | 
| 313
