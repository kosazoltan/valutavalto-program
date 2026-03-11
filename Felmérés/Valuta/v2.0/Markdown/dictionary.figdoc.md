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
| 3136 | Műszaki rajzoló, szerkesztő                                                                    | 019406fd-da6e-7699-a42b-3dd12148cf0b | 
| 3139 | Egyéb, máshova nem sorolható technikus                                                         | 019406fd-da6e-7699-a42b-3dd224a4d33c | 
| 314  | Számítástechnikai (informatikai) és kommunikációs foglalkozások                                | 019406fd-da6e-7699-a42b-3dd30cb9c380 | 
| 3141 | Informatikai és kommunikációs rendszereket kezelő technikus                                    | 019406fd-da6f-7be2-ac42-aa26c4773c1e | 
| 3142 | Informatikai és kommunikációs rendszerek felhasználóit támogató technikus                      | 019406fd-da6f-7be2-ac42-aa2713715bef | 
| 3143 | Számítógéphálózat- és rendszertechnikus                                                        | 019406fd-da6f-7be2-ac42-aa2852e7f321 | 
| 3144 | Webrendszer- (hálózati) technikus                                                              | 019406fd-da6f-7be2-ac42-aa29858a2efd | 
| 3145 | Műsorszóró és audiovizuális technikus                                                          | 019406fd-da6f-7be2-ac42-aa2abf79a9cc | 
| 3146 | Telekommunikációs technikus                                                                    | 019406fd-da6f-7be2-ac42-aa2b9fea9167 | 
| 315  | Folyamatirányítók (berendezések vezérlői)                                                      | 019406fd-da6f-7be2-ac42-aa2ced452a30 | 
| 3151 | Energetikai (erőművi) berendezés vezérlője                                                     | 019406fd-da6f-7be2-ac42-aa2dadcb16e4 | 
| 3152 | Égető-, víz- és csatornaművi berendezés vezérlője                                              | 019406fd-da6f-7be2-ac42-aa2e4e94c2b0 | 
| 3153 | Vegyipari alapanyag-feldolgozó berendezés vezérlője                                            | 019406fd-da6f-7be2-ac42-aa2f32ed4dc3 | 
| 3154 | Kőolaj- és földgázfinomító berendezés vezérlője                                                | 019406fd-da6f-7be2-ac42-aa304e3bb67b | 
| 3155 | Fémgyártási berendezés vezérlője                                                               | 019406fd-da6f-7be2-ac42-aa3170226d62 | 
| 3159 | Egyéb folyamatirányító berendezés vezérlője                                                    | 019406fd-da6f-7be2-ac42-aa324868c486 | 
| 316  | Üzemfenntartási foglalkozások                                                                  | 019406fd-da6f-7be2-ac42-aa334d985e5a | 
| 3161 | Munka- és termelésszervező                                                                     | 019406fd-da6f-7be2-ac42-aa34dfe62c36 | 
| 3162 | Energetikus                                                                                    | 019406fd-da6f-7be2-ac42-aa3506852e3c | 
| 3163 | Munkavédelmi és üzembiztonsági foglalkozású                                                    | 019406fd-da6f-7be2-ac42-aa36d15ccff2 | 
| 317  | Vízi- és légijármű-vezetők, légiirányítók                                                      | 019406fd-da6f-7be2-ac42-aa379f97f8e7 | 
| 3171 | Tengeri és belvízi hajóparancsnok, fedélzeti tiszt                                             | 019406fd-da6f-7be2-ac42-aa380dd5ddac | 
| 3172 | Légijármű-vezető, hajózómérnök                                                                 | 019406fd-da6f-7be2-ac42-aa39707f8800 | 
| 3173 | Légiforgalmi irányító                                                                          | 019406fd-da6f-7be2-ac42-aa3a2009063a | 
| 3174 | Légiforgalmi irányítástechnikai berendezések üzemeltetője                                      | 019406fd-da6f-7be2-ac42-aa3b88f54e0f | 
| 319  | gyéb műszaki foglalkozások                                                                     | 019406fd-da6f-7be2-ac42-aa3c6627c212 | 
| 3190 | Egyéb műszaki foglalkozású                                                                     | 019406fd-da6f-7be2-ac42-aa3d0f6a2135 | 
| 32   | Szakmai irányítók, felügyelők                                                                  | 019406fd-da6f-7be2-ac42-aa3e57d35490 | 
| 321  | Ipari, építőipari szakmai irányítók, felügyelők                                                | 019406fd-da6f-7be2-ac42-aa3fe318ea00 | 
| 3211 | Bányászati szakmai irányító, felügyelő                                                         | 019406fd-da6f-7be2-ac42-aa4076693020 | 
| 3212 | Feldolgozóipari szakmai irányító, felügyelő                                                    | 019406fd-da6f-7be2-ac42-aa41db6151f9 | 
| 3213 | Építőipari szakmai irányító, felügyelő                                                         | 019406fd-da6f-7be2-ac42-aa42f6d4cf2e | 
| 322  | Egyéb szakmai irányítók, felügyelők                                                            | 019406fd-da6f-7be2-ac42-aa430e7526b8 | 
| 3221 | Irodai szakmai irányító, felügyelő                                                             | 019406fd-da6f-7be2-ac42-aa443f472a24 | 
| 3222 | Konyhafőnök, séf                                                                               | 019406fd-da6f-7be2-ac42-aa45e09a91f1 | 
| 33   | Egészségügyi foglalkozások                                                                     | 019406fd-da6f-7be2-ac42-aa4652fd9fa1 | 
| 331  | Ápolási és szülészeti kapcsolódó foglalkozások                                                 | 019406fd-da6f-7be2-ac42-aa4724046317 | 
| 3311 | Ápoló, szakápoló                                                                               | 019406fd-da6f-7be2-ac42-aa488ac7c49b | 
| 3312 | Szülész(nő)i tevékenység segítője                                                              | 019406fd-da6f-7be2-ac42-aa4920b035e1 | 
| 332  | Egészségügyi asszisztensek                                                                     | 019406fd-da6f-7be2-ac42-aa4a6d2ba4da | 
| 3321 | Általános egészségügyi asszisztens                                                             | 019406fd-da6f-7be2-ac42-aa4b004498cc | 
| 3322 | Egészségügyi dokumentátor                                                                      | 019406fd-da6f-7be2-ac42-aa4c0ce7362a | 
| 3323 | Orvosi képalkotó diagnosztikai és terápiás berendezések kezelője                               | 019406fd-da6f-7be2-ac42-aa4d7969155f | 
| 3324 | Orvosi laboratóriumi asszisztens                                                               | 019406fd-da6f-7be2-ac42-aa4ed60d4eec | 
| 3325 | Fogászati asszisztens                                                                          | 019406fd-da6f-7be2-ac42-aa4f57b4c7c9 | 
| 3326 | Gyógyszertári és gyógyszerellátási asszisztens                                                 | 019406fd-da6f-7be2-ac42-aa5052ad19d6 | 
| 3327 | Alternatív gyógymódok alkalmazásának segítője                                                  | 019406fd-da6f-7be2-ac42-aa510f1e170c | 
| 333  | umánegészségügyhöz kapcsolódó foglalkozások                                                    | 019406fd-da6f-7be2-ac42-aa52d1adaecb | 
| 3331 | Környezet- és foglalkozás-egészségügyi kiegészítő foglalkozású                                 | 019406fd-da6f-7be2-ac42-aa5325cdcc6e | 
| 3332 | Fizioterápiás asszisztens, masszőr                                                             | 019406fd-da6f-7be2-ac42-aa54de11f0ad | 
| 3333 | Fogtechnikus                                                                                   | 019406fd-da6f-7be2-ac42-aa5528608ede | 
| 3334 | Ortopédiai eszközkészítő                                                                       | 019406fd-da6f-7be2-ac42-aa56bdef1979 | 
| 3335 | Látszerész                                                                                     | 019406fd-da6f-7be2-ac42-aa5750cb0181 | 
| 3339 | Egyéb, humánegészségügyhöz kapcsolódó foglalkozású                                             | 019406fd-da6f-7be2-ac42-aa5886a92d94 | 
| 334  | Állat- és növényegészségügyhöz kapcsolódó foglalkozások                                        | 019406fd-da6f-7be2-ac42-aa598eac151d | 
| 3341 | Állatorvosi asszisztens                                                                        | 019406fd-da6f-7be2-ac42-aa5ad377c8e5 | 
| 3342 | Növényorvosi (növényvédelmi) asszisztens                                                       | 019406fd-da6f-7be2-ac42-aa5b5631e3ab | 
| 34   | Oktatási asszisztensek                                                                         | 019406fd-da6f-7be2-ac42-aa5cf25b4236 | 
| 341  | Oktatási asszisztensek                                                                         | 019406fd-da6f-7be2-ac42-aa5ddb67a373 | 
| 3410 | Oktatási asszisztens                                                                           | 019406fd-da6f-7be2-ac42-aa5ee247cfb8 | 
| 35   | Szociális gondozási és munkaerő-piaci szolgáltatási foglalkozások                              | 019406fd-da6f-7be2-ac42-aa5f69e7c505 | 
| 351  | Szociális foglalkozások                                                                        | 019406fd-da6f-7be2-ac42-aa60caf8b116 | 
| 3511 | Szociális segítő                                                                               | 019406fd-da6f-7be2-ac42-aa618307c9a3 | 
| 3512 | Hivatásos nevelőszülő, főállású anya                                                           | 019406fd-da6f-7be2-ac42-aa62e6cd71a0 | 
| 3513 | Szociális gondozó, szakgondozó                                                                 | 019406fd-da6f-7be2-ac42-aa6310a83835 | 
| 3514 | Jelnyelvi tolmács                                                                              | 019406fd-da6f-7be2-ac42-aa646634abd8 | 
| 3515 | Ifjúságsegítő                                                                                  | 019406fd-da6f-7be2-ac42-aa658ce9efdd | 
| 352  | Munkaerő-piaci szolgáltatási ügyintézők                                                        | 019406fd-da6f-7be2-ac42-aa66578e8aac | 
| 3520 | Munkaerő-piaci szolgáltatási ügyintéző                                                         | 019406fd-da6f-7be2-ac42-aa67f03a7b03 | 
| 36   | Üzleti jellegű szolgáltatások ügyintézői, hatósági ügyintézők, ügynökök                        | 019406fd-da6f-7be2-ac42-aa6827cd25df | 
| 361  | Pénzügyi, gazdasági ügyintézők                                                                 | 019406fd-da6f-7be2-ac42-aa695446856b | 
| 3611 | Pénzügyi ügyintéző (a pénzintézeti ügyintéző kivételével)                                      | 019406fd-da6f-7be2-ac42-aa6af3cde5b7 | 
| 3612 | Pénzintézeti ügyintéző                                                                         | 019406fd-da6f-7be2-ac42-aa6bd618d3ec | 
| 3613 | Tőzsde- és pénzügyi ügynök, bróker                                                             | 019406fd-da6f-7be2-ac42-aa6cd560b814 | 
| 3614 | Számviteli ügyintéző                                                                           | 019406fd-da6f-7be2-ac42-aa6dde906ac7 | 
| 3615 | Statisztikai ügyintéző                                                                         | 019406fd-da6f-7be2-ac42-aa6eebf18761 | 
| 3616 | Értékbecslő, kárbecslő, kárszakértő                                                            | 019406fd-da6f-7be2-ac42-aa6fe646458f | 
| 362  | ereskedelmi és értékesítési ügyintézők, ügynökök                                               | 019406fd-da6f-7be2-ac42-aa70653a7c84 | 
| 3621 | Biztosítási ügynök, ügyintéző                                                                  | 019406fd-da6f-7be2-ac42-aa718a78a9a7 | 
| 3622 | Kereskedelmi ügyintéző                                                                         | 019406fd-da6f-7be2-ac42-aa723524db3c | 
| 3623 | Anyaggazdálkodó, felvásárló                                                                    | 019406fd-da6f-7be2-ac42-aa73f90cebdf | 
| 3624 | Ügynök (a biztosítási ügynök kivételével)                                                      | 019406fd-da6f-7be2-ac42-aa74d63b1d81 | 
| 363  | gyéb üzleti jellegű szolgáltatások ügyintézői                                                  | 019406fd-da6f-7be2-ac42-aa75c2208e8a | 
| 3631 | Konferencia- és rendezvényszervező                                                             | 019406fd-da6f-7be2-ac42-aa7697d2b81b | 
| 3632 | Marketing- és PR-ügyintéző                                                                     | 019406fd-da6f-7be2-ac42-aa777dbf4f44 | 
| 3633 | Ingatlanügynök, ingatlanforgalmazási ügyintéző                                                 | 019406fd-da6f-7be2-ac42-aa78e5b15931 | 
| 3639 | Egyéb, máshova nem sorolható üzleti jellegű szolgáltatás ügyintézője                           | 019406fd-da6f-7be2-ac42-aa79d9a85cb7 | 
| 364  | Igazgatási és jogi asszisztensek                                                               | 019406fd-da6f-7be2-ac42-aa7aaaf503b8 | 
| 3641 | Személyi asszisztens                                                                           | 019406fd-da6f-7be2-ac42-aa7b9cf6536d | 
| 3642 | Jogi asszisztens                                                                               | 019406fd-da6f-7be2-ac42-aa7c2e91b041 | 
| 3649 | Egyéb igazgatási és jogi asszisztens                                                           | 019406fd-da6f-7be2-ac42-aa7d9afee00e | 
| 365  | Hatósági ügyintézők                                                                            | 019406fd-da6f-7be2-ac42-aa7e65261759 | 
| 3651 | Vám- és pénzügyőr                                                                              | 019406fd-da6f-7be2-ac42-aa7ff90909f9 | 
| 3652 | Adó- és illetékhivatali ügyintéző                                                              | 019406fd-da6f-7be2-ac42-aa80d95a8d34 | 
| 3653 | Társadalombiztosítási és segélyezési hatósági ügyintéző                                        | 019406fd-da6f-7be2-ac42-aa8195fcbd21 | 
| 3654 | Hatósági engedélyek kiadásával foglalkozó ügyintéző                                            | 019406fd-da6f-7be2-ac42-aa82c070f0ce | 
| 3655 | Nyomozó                                                                                        | 019406fd-da6f-7be2-ac42-aa83d8cfb63b | 
| 3656 | Végrehajtó, adósságbehajtó                                                                     | 019406fd-da6f-7be2-ac42-aa8416566555 | 
| 3659 | Egyéb hatósági ügyintéző                                                                       | 019406fd-da6f-7be2-ac42-aa858a546052 | 
| 37   | Művészeti, kulturális, sport- és vallási foglalkozások                                         | 019406fd-da6f-7be2-ac42-aa8602810a22 | 
| 371  | Művészeti és kulturális foglalkozások                                                          | 019406fd-da6f-7be2-ac42-aa875a957ba3 | 
| 3711 | Segédszínész, statiszta                                                                        | 019406fd-da6f-7be2-ac42-aa8892e5c626 | 
| 3712 | Segédrendező                                                                                   | 019406fd-da6f-7be2-ac42-aa89d551814b | 
| 3713 | Fényképész                                                                                     | 019406fd-da6f-7be2-ac42-aa8a9af6af13 | 
| 3714 | Díszletező, díszítő                                                                            | 019406fd-da6f-7be2-ac42-aa8b604e11c5 | 
| 3715 | Kiegészítő filmgyártási és színházi foglalkozású                                               | 019406fd-da6f-7be2-ac42-aa8c06cb9f78 | 
| 3716 | Lakberendező, dekoratőr                                                                        | 019406fd-da6f-7be2-ac42-aa8d0f8829bb | 
| 3717 | Kulturális intézményi szaktechnikus                                                            | 019406fd-da6f-7be2-ac42-aa8e043c8abb | 
| 3719 | Egyéb művészeti és kulturális foglalkozású                                                     | 019406fd-da6f-7be2-ac42-aa8f40a295d5 | 
| 372  | Sport- és szabadidős foglalkozások                                                             | 019406fd-da6f-7be2-ac42-aa90cf8b7679 | 
| 3721 | Sportoló                                                                                       | 019406fd-da6f-7be2-ac42-aa9124064672 | 
| 3722 | Fitnesz- és rekreációs program irányítója                                                      | 019406fd-da6f-7be2-ac42-aa928899103e | 
| 373  | Egyéb vallási foglalkozások                                                                    | 019406fd-da6f-7be2-ac42-aa93b0f7d505 | 
| 3730 | Egyéb vallási foglalkozású                                                                     | 019406fd-da6f-7be2-ac42-aa942233af0e | 
| 39   | Egyéb ügyintézők                                                                               | 019406fd-da70-7064-a23c-11074199974e | 
| 391  | Egyéb ügyintézők                                                                               | 019406fd-da70-7064-a23c-11080a66e7b9 | 
| 3910 | Egyéb ügyintéző                                                                                | 019406fd-da70-7064-a23c-1109a036c381 | 
| 4    | IRODAI ÉS ÜGYVITELI (ÜGYFÉLKAPCSOLATI) FOGLALKOZÁSOK                                           | 019406fd-da70-7064-a23c-110a7d8a77cb | 
| 41   | Irodai, ügyviteli foglalkozások                                                                | 019406fd-da70-7064-a23c-110ba2d0a6c4 | 
| 411  | Általános irodai, ügyviteli foglalkozások                                                      | 019406fd-da70-7064-a23c-110c105b85f6 | 
| 4111 | Titkár(nő)                                                                                     | 019406fd-da70-7064-a23c-110ded434a5c | 
| 4112 | Általános irodai adminisztrátor                                                                | 019406fd-da70-7064-a23c-110e09d1b3f0 | 
| 4113 | Gépíró, szövegszerkesztő                                                                       | 019406fd-da70-7064-a23c-110fd37b8513 | 
| 4114 | Adatrögzítő, kódoló                                                                            | 019406fd-da70-7064-a23c-111059d8b097 | 
| 412  | Számviteli foglalkozások                                                                       | 019406fd-da70-7064-a23c-11112c37d434 | 
| 4121 | Könyvelő (analitikus)                                                                          | 019406fd-da70-7064-a23c-11120aeda233 | 
| 4122 | Bérelszámoló                                                                                   | 019406fd-da70-7064-a23c-11136fecc479 | 
| 4123 | Pénzügyi, statisztikai, biztosítási adminisztrátor                                             | 019406fd-da70-7064-a23c-1114ebefa330 | 
| 4129 | Egyéb számviteli foglalkozású                                                                  | 019406fd-da70-7064-a23c-1115f508224e | 
| 413  | rodai szaknyilvántartási foglalkozások                                                         | 019406fd-da70-7064-a23c-1116a6bacea2 | 
| 4131 | Készlet- és anyagnyilvántartó                                                                  | 019406fd-da70-7064-a23c-1117ab4e8b18 | 
| 4132 | Szállítási, szállítmányozási nyilvántartó                                                      | 019406fd-da70-7064-a23c-1118db3630e3 | 
| 4133 | Könyvtári, levéltári nyilvántartó                                                              | 019406fd-da70-7064-a23c-11190faeeca4 | 
| 4134 | Humánpolitikai adminisztrátor                                                                  | 019406fd-da70-7064-a23c-111a46e6f129 | 
| 4135 | Postai szolgáltató (kézbesítő, válogató)                                                       | 019406fd-da70-7064-a23c-111bd74861d3 | 
| 4136 | Iratkezelő, irattáros                                                                          | 019406fd-da70-7064-a23c-111c14d99932 | 
| 419  | Egyéb irodai, ügyviteli foglalkozások                                                          | 019406fd-da70-7064-a23c-111dc6179a47 | 
| 4190 | Egyéb, máshova nem sorolható irodai, ügyviteli foglalkozású                                    | 019406fd-da70-7064-a23c-111ed1c99b01 | 
| 42   | Ügyfélkapcsolati foglalkozások                                                                 | 019406fd-da70-7064-a23c-111f1e80a61f | 
| 421  | Pénzkezelők, pénzintézeti pénztárosok                                                          | 019406fd-da70-7064-a23c-112046ded590 | 
| 4211 | Banki pénztáros                                                                                | 019406fd-da70-7064-a23c-11219a826fbb | 
| 4212 | Szerencsejáték-szervező                                                                        | 019406fd-da70-7064-a23c-1122e7ff7d92 | 
| 4213 | Zálogházi ügyintéző és pénzkölcsönző                                                           | 019406fd-da70-7064-a23c-112337241cdc | 
| 422  | Ügyfélkapcsolati foglalkozások                                                                 | 019406fd-da70-7064-a23c-1124455fcf12 | 
| 4221 | Utazásszervező, tanácsadó                                                                      | 019406fd-da71-7e64-a729-1213700a3551 | 
| 4222 | Recepciós                                                                                      | 019406fd-da71-7e64-a729-1214de8eb44c | 
| 4223 | Szállodai recepciós                                                                            | 019406fd-da71-7e64-a729-1215d96a8d3f | 
| 4224 | Ügyfél- (vevő)tájékoztató                                                                      | 019406fd-da71-7e64-a729-12165974deb7 | 
| 4225 | Ügyfélszolgálati központ tájékoztatója                                                         | 019406fd-da71-7e64-a729-121713c41d2e | 
| 4226 | Lakossági kérdező, összeíró                                                                    | 019406fd-da71-7e64-a729-12184d15b4e2 | 
| 4227 | Postai ügyfélkapcsolati foglalkozású                                                           | 019406fd-da71-7e64-a729-1219886414b4 | 
| 4229 | Egyéb ügyfélkapcsolati foglalkozású                                                            | 019406fd-da71-7e64-a729-121a0d4cccac | 
| 5    | KERESKEDELMI ÉS SZOLGÁLTATÁSI FOGLALKOZÁSOK                                                    | 019406fd-da71-7e64-a729-121b14d66c5c | 
| 51   | Kereskedelmi és vendéglátó-ipari foglalkozások                                                 | 019406fd-da71-7e64-a729-121c9b71c7fe | 
| 511  | Kereskedelmi foglalkozások                                                                     | 019406fd-da71-7e64-a729-121daecada49 | 
| 5111 | Kereskedő                                                                                      | 019406fd-da71-7e64-a729-121e89983458 | 
| 5112 | Vezető eladó                                                                                   | 019406fd-da71-7e64-a729-121f8043a00b | 
| 5113 | Bolti eladó                                                                                    | 019406fd-da71-7e64-a729-1220bc0a508f | 
| 5114 | Kölcsönző                                                                                      | 019406fd-da71-7e64-a729-12214b0d62bb | 
| 5115 | Piaci, utcai árus                                                                              | 019406fd-da71-7e64-a729-1222ada3c64a | 
| 5116 | Piaci, utcai étel- és italárus                                                                 | 019406fd-da71-7e64-a729-1223132e79df | 
| 5117 | Bolti pénztáros, jegypénztáros                                                                 | 019406fd-da71-7e64-a729-1224cd36dfa5 | 
| 512  | Egyéb kereskedelmi foglalkozások                                                               | 019406fd-da71-7e64-a729-1225b2f57021 | 
| 5121 | Üzemanyagtöltő állomás kezelője                                                                | 019406fd-da71-7e64-a729-12265e750856 | 
| 5122 | Áru- és divatbemutató                                                                          | 019406fd-da71-7e64-a729-12272fb89619 | 
| 5123 | Telefonos (multimédiás) értékesítési ügynök                                                    | 019406fd-da71-7e64-a729-122899a405f2 | 
| 5129 | Egyéb, máshova nem sorolható kereskedelmi foglalkozású                                         | 019406fd-da71-7e64-a729-1229b2e153f5 | 
| 513  | Vendéglátó-ipari foglalkozások                                                                 | 019406fd-da71-7e64-a729-122a0ef23375 | 
| 5131 | Vendéglős                                                                                      | 019406fd-da71-7e64-a729-122b02f69595 | 
| 5132 | Pincér                                                                                         | 019406fd-da71-7e64-a729-122c265ca43b | 
| 5133 | Pultos                                                                                         | 019406fd-da71-7e64-a729-122d2d673bb1 | 
| 5134 | Szakács                                                                                        | 019406fd-da71-7e64-a729-122e370b1731 | 
| 5135 | Cukrász                                                                                        | 019406fd-da71-7e64-a729-122fc33bc757 | 
| 52   | Szolgáltatási foglalkozások                                                                    | 019406fd-da71-7e64-a729-12300578c71f | 
| 521  | Személyi szolgáltatási foglalkozások                                                           | 019406fd-da71-7e64-a729-12316d488e5e | 
| 5211 | Fodrász                                                                                        | 019406fd-da71-7e64-a729-12321a2ce3de | 
| 5212 | Kozmetikus                                                                                     | 019406fd-da71-7e64-a729-1233f8870dc2 | 
| 5213 | Manikűrös, pedikűrös                                                                           | 019406fd-da71-7e64-a729-1234a84e0df5 | 
| 5219 | Egyéb személyi szolgáltatási foglalkozású                                                      | 019406fd-da71-7e64-a729-1235835c881c | 
| 522  | Személygondozási foglalkozások                                                                 | 019406fd-da71-7e64-a729-123614a2fc1f | 
| 5221 | Gyermekfelügyelő, dajka                                                                        | 019406fd-da71-7e64-a729-12373bd38f24 | 
| 5222 | Segédápoló, műtőssegéd                                                                         | 019406fd-da71-7e64-a729-1238608b8d0f | 
| 5223 | Házi gondozó                                                                                   | 019406fd-da71-7e64-a729-1239350ae3e4 | 
| 5229 | Egyéb személygondozási foglalkozású                                                            | 019406fd-da71-7e64-a729-123a023d56fb | 
| 523  | Utaskísérők, jegykezelők                                                                       | 019406fd-da71-7e64-a729-123bb4e897f1 | 
| 5231 | Kalauz, menetjegyellenőr                                                                       | 019406fd-da71-7e64-a729-123c135003ce | 
| 5232 | Utaskísérő (repülőn, hajón)                                                                    | 019406fd-da71-7e64-a729-123d2399c260 | 
| 5233 | Idegenvezető                                                                                   | 019406fd-da71-7e64-a729-123ea9c092f2 | 
| 524  | Épületfenntartási foglalkozások                                                                | 019406fd-da71-7e64-a729-123fa87fc27c | 
| 5241 | Vezető takarító                                                                                | 019406fd-da71-7e64-a729-12400db5371d | 
| 5242 | Házvezető                                                                                      | 019406fd-da71-7e64-a729-12412b3f3bd4 | 
| 5243 | Épületgondnok                                                                                  | 019406fd-da71-7e64-a729-1242e773d1df | 
| 525  | Személy- és vagyonvédelmi foglalkozások                                                        | 019406fd-da71-7e64-a729-1243fa263b21 | 
| 5251 | Rendőr                                                                                         | 019406fd-da71-7e64-a729-1244364cdfa8 | 
| 5252 | Tűzoltó                                                                                        | 019406fd-da71-7e64-a729-1245395e1a57 | 
| 5253 | Büntetés-végrehajtási őr                                                                       | 019406fd-da71-7e64-a729-1246f24ea490 | 
| 5254 | Vagyonőr, testőr                                                                               | 019406fd-da71-7e64-a729-12479effd3c1 | 
| 5255 | Természetvédelmi őr                                                                            | 019406fd-da71-7e64-a729-12486bcd29a2 | 
| 5256 | Közterület-felügyelő                                                                           | 019406fd-da71-7e64-a729-12497e5bd35b | 
| 5259 | Egyéb személy- és vagyonvédelmi foglalkozású                                                   | 019406fd-da71-7e64-a729-124af36ac9e1 | 
| 529  | Egyéb szolgáltatási foglalkozások                                                              | 019406fd-da71-7e64-a729-124b61a586f0 | 
| 5291 | Járművezető-oktató                                                                             | 019406fd-da71-7e64-a729-124c4a545b6a | 
| 5292 | Hobbiállat-gondozó, -kozmetikus                                                                | 019406fd-da71-7e64-a729-124d5d18aa3b | 
| 5293 | Temetkezési foglalkozású                                                                       | 019406fd-da71-7e64-a729-124e83fa1c10 | 
| 5299 | Egyéb, máshova nem sorolható szolgáltatási foglalkozású                                        | 019406fd-da71-7e64-a729-124f0b9b075a | 
| 6    | MEZŐGAZDASÁGI ÉS ERDŐGAZDÁLKODÁSI FOGLALKOZÁSOK                                                | 019406fd-da71-7e64-a729-1250f12e48b2 | 
| 61   | Mezőgazdasági foglalkozások                                                                    | 019406fd-da71-7e64-a729-1251f336d2e9 | 
| 611  | Növénytermesztési foglalkozások                                                                | 019406fd-da71-7e64-a729-12523a71467d | 
| 6111 | Szántóföldinövény-termesztő                                                                    | 019406fd-da71-7e64-a729-12532a60871c | 
| 6112 | Bionövény-termesztő                                                                            | 019406fd-da71-7e64-a729-1254feb3e86e | 
| 6113 | Zöldségtermesztő                                                                               | 019406fd-da71-7e64-a729-1255968f3584 | 
| 6114 | Szőlő-, gyümölcstermesztő                                                                      | 019406fd-da71-7e64-a729-1256884bb3f3 | 
| 6115 | Dísznövény-, virág- és faiskolai kertész, csemetenevelő                                        | 019406fd-da71-7e64-a729-12579bc63ecf | 
| 6116 | Gyógynövénytermesztő                                                                           | 019406fd-da71-7e64-a729-1258eebc804b | 
| 6119 | Egyéb növénytermesztési foglalkozású                                                           | 019406fd-da71-7e64-a729-12597ec4ad8d | 
| 612  | Állattenyésztési és állatgondozási foglalkozások                                               | 019406fd-da71-7e64-a729-125aeef6a555 | 
| 6121 | Szarvasmarha-, ló-, sertés-, juhtartó és -tenyésztő                                            | 019406fd-da71-7e64-a729-125b305351e8 | 
| 6122 | Baromfitartó és -tenyésztő                                                                     | 019406fd-da71-7e64-a729-125cf97935c4 | 
| 6123 | Méhész                                                                                         | 019406fd-da71-7e64-a729-125d7a67d446 | 
| 6124 | Kisállattartó és -tenyésztő                                                                    | 019406fd-da71-7e64-a729-125e361a26a4 | 
| 613  | Vegyes profilú gazdálkodók                                                                     | 019406fd-da71-7e64-a729-125fb5b5616e | 
| 6130 | Vegyes profilú gazdálkodó                                                                      | 019406fd-da71-7e64-a729-1260542a3c0e | 
| 62   | Erdőgazdálkodási, vadgazdálkodási és halászati foglalkozások                                   | 019406fd-da71-7e64-a729-12611c37071e | 
| 621  | Erdőgazdálkodási foglalkozások                                                                 | 019406fd-da71-7e64-a729-1262a8720595 | 
| 6211 | Erdészeti foglalkozású                                                                         | 019406fd-da71-7e64-a729-1263a8eae949 | 
| 6212 | Fakitermelő (favágó)                                                                           | 019406fd-da71-7e64-a729-12641ffb8644 | 
| 622  | Vadgazdálkodási foglalkozások                                                                  | 019406fd-da71-7e64-a729-1265d367fbb6 | 
| 6220 | Vadgazdálkodási foglalkozású                                                                   | 019406fd-da71-7e64-a729-12665c24fd67 | 
| 623  | Halászati foglalkozások                                                                        | 019406fd-da71-7e64-a729-1267a13c58b1 | 
| 6230 | Halászati foglalkozású                                                                         | 019406fd-da71-7e64-a729-12680710ca01 | 
| 7    | IPARI ÉS ÉPÍTŐIPARI FOGLALKOZÁSOK                                                              | 019406fd-da71-7e64-a729-126957040107 | 
| 71   | Élelmiszer-ipari foglalkozások                                                                 | 019406fd-da71-7e64-a729-126ae8b2eae8 | 
| 711  | Élelmiszergyártók, -feldolgozók és -tartósítók                                                 | 019406fd-da71-7e64-a729-126b2165fdb5 | 
| 7111 | Húsfeldolgozó                                                                                  | 019406fd-da71-7e64-a729-126ccc6110f8 | 
| 7112 | Gyümölcs- és zöldségfeldolgozó, -tartósító                                                     | 019406fd-da71-7e64-a729-126dfdcf9965 | 
| 7113 | Tejfeldolgozó, tejtermékgyártó                                                                 | 019406fd-da71-7e64-a729-126ec08e94b5 | 
| 7114 | Pék, édesiparitermék-gyártó                                                                    | 019406fd-da71-7e64-a729-126f94d383ce | 
| 7115 | Borász és egyéb szeszesital-gyártó, szikvízkészítő                                             | 019406fd-da71-7e64-a729-1270bdae8c1e | 
| 72   | Könnyűipari foglalkozások                                                                      | 019406fd-da71-7e64-a729-1271df3ee09f | 
| 721  | Ruha- és bőripari foglalkozások                                                                | 019406fd-da71-7e64-a729-12726ad546ad | 
| 7211 | Szabásminta-készítő                                                                            | 019406fd-da71-7e64-a729-127311f5faf5 | 
| 7212 | Szabó, varró                                                                                   | 019406fd-da71-7e64-a729-127455a49e94 | 
| 7213 | Kalapos, kesztyűs                                                                              | 019406fd-da71-7e64-a729-127509b04989 | 
| 7214 | Szűcs, szőrmefestő                                                                             | 019406fd-da71-7e64-a729-1276a0c361a6 | 
| 7215 | Tímár                                                                                          | 019406fd-da71-7e64-a729-1277967ff904 | 
| 7216 | Bőrdíszműves, bőröndös, bőrtermékkészítő, -javító                                              | 019406fd-da71-7e64-a729-127813a7cf62 | 
| 7217 | Cipész, cipőkészítő, -javító                                                                   | 019406fd-da71-7e64-a729-1279b2a79a71 | 
| 722  | aipari foglalkozások                                                                           | 019406fd-da71-7e64-a729-127abfe2a1ad | 
| 7221 | Famegmunkáló                                                                                   | 019406fd-da71-7e64-a729-127b6bd61c03 | 
| 7222 | Faesztergályos                                                                                 | 019406fd-da71-7e64-a729-127cc6327d91 | 
| 7223 | Bútorasztalos                                                                                  | 019406fd-da72-70a6-a2a5-1ac80dafe794 | 
| 7224 | Kárpitos                                                                                       | 019406fd-da72-70a6-a2a5-1ac9e92e7f4b | 
| 7225 | Kádár, bognár                                                                                  | 019406fd-da72-70a6-a2a5-1aca68b104b9 | 
| 723  | Nyomdaipari foglalkozások                                                                      | 019406fd-da72-70a6-a2a5-1acb57f88821 | 
| 7231 | Nyomdai előkészítő                                                                             | 019406fd-da72-70a6-a2a5-1acc49e874aa | 
| 7232 | Nyomdász, nyomdai gépmester                                                                    | 019406fd-da72-70a6-a2a5-1acd02207bc8 | 
| 7233 | Könyvkötő                                                                                      | 019406fd-da72-70a6-a2a5-1ace48bc287e | 
| 73   | Fém- és villamosipari foglalkozások                                                            | 019406fd-da72-70a6-a2a5-1acf1f7c7301 | 
| 731  | Kohászati foglalkozások                                                                        | 019406fd-da72-70a6-a2a5-1ad0da0dad56 | 
| 7310 | Fémöntőminta-készítő                                                                           | 019406fd-da72-70a6-a2a5-1ad1173874f3 | 
| 732  | Fémmegmunkálók                                                                                 | 019406fd-da72-70a6-a2a5-1ad234c9e914 | 
| 7321 | Lakatos                                                                                        | 019406fd-da72-70a6-a2a5-1ad369461258 | 
| 7322 | Szerszámkészítő                                                                                | 019406fd-da72-70a6-a2a5-1ad449eac33a | 
| 7323 | Forgácsoló                                                                                     | 019406fd-da72-70a6-a2a5-1ad5a4503272 | 
| 7324 | Fémcsiszoló, köszörűs, szerszámköszörűs                                                        | 019406fd-da72-70a6-a2a5-1ad6632fed73 | 
| 7325 | Hegesztő, lángvágó                                                                             | 019406fd-da72-70a6-a2a5-1ad718fbf47c | 
| 7326 | Kovács                                                                                         | 019406fd-da72-70a6-a2a5-1ad8f8d73870 | 
| 7327 | Festékszóró, fényező                                                                           | 019406fd-da72-70a6-a2a5-1ad9eb2f05fc | 
| 7328 | Fém- és egyéb tartószerkezet-szerelő                                                           | 019406fd-da72-70a6-a2a5-1adaf76f50d7 | 
| 733  | épek, berendezések karbantartói, javítói                                                       | 019406fd-da72-70a6-a2a5-1adb143f54ba | 
| 7331 | Gépjármű- és motorkarbantartó, -javító                                                         | 019406fd-da72-70a6-a2a5-1adc7fe5689e | 
| 7332 | Repülőgépmotor-karbantartó, -javító                                                            | 019406fd-da72-70a6-a2a5-1add837ae5a9 | 
| 7333 | Mezőgazdasági és ipari gép (motor) karbantartója, javítója                                     | 019406fd-da72-70a6-a2a5-1adeea080644 | 
| 7334 | Mechanikaigép-karbantartó, -javító (műszerész)                                                 | 019406fd-da72-70a6-a2a5-1adf33267ea3 | 
| 7335 | Kerékpár-karbantartó, -javító                                                                  | 019406fd-da72-70a6-a2a5-1ae0ed21a186 | 
| 734  | illamossági berendezések műszerészei, szerelői                                                 | 019406fd-da72-70a6-a2a5-1ae1387dc7d5 | 
| 7341 | Villamos gépek és készülékek műszerésze, javítója                                              | 019406fd-da72-70a6-a2a5-1ae2d400322e | 
| 7342 | Informatikai és telekommunikációs berendezések műszerésze, javítója                            | 019406fd-da72-70a6-a2a5-1ae31dd280b6 | 
| 7343 | Elektromoshálózat-szerelő, -javító                                                             | 019406fd-da72-70a6-a2a5-1ae43df83d0b | 
| 74   | Kézműipari foglalkozások                                                                       | 019406fd-da72-70a6-a2a5-1ae59646601b | 
| 741  | Kézműipari foglalkozások                                                                       | 019406fd-da72-70a6-a2a5-1ae65fe33cce | 
| 7411 | Címfestő                                                                                       | 019406fd-da72-70a6-a2a5-1ae737655981 | 
| 7412 | Ékszerkészítő, ötvös, drágakőcsiszoló                                                          | 019406fd-da72-70a6-a2a5-1ae84bedf8b0 | 
| 7413 | Keramikus                                                                                      | 019406fd-da72-70a6-a2a5-1ae9939f1ac8 | 
| 7414 | Üveggyártó                                                                                     | 019406fd-da72-70a6-a2a5-1aeabad4f3bf | 
| 7415 | Hangszerkészítő                                                                                | 019406fd-da72-70a6-a2a5-1aeb300d73cd | 
| 7416 | Szőr- és tollfeldolgozó                                                                        | 019406fd-da72-70a6-a2a5-1aec83fc11c4 | 
| 7417 | Nád- és fűzfeldolgozó, seprű-, kefegyártó                                                      | 019406fd-da72-70a6-a2a5-1aedca76dfbd | 
| 7418 | Textilműves, hímző, csipkeverő                                                                 | 019406fd-da72-70a6-a2a5-1aee38ebe39e | 
| 7419 | Egyéb kézműipari foglalkozású                                                                  | 019406fd-da72-70a6-a2a5-1aef371b762e | 
| 742  | Finommechanikai műszerészek                                                                    | 019406fd-da73-7986-8c19-0daef86b68d4 | 
| 7420 | Finommechanikai műszerész                                                                      | 019406fd-da73-7986-8c19-0daf4a85644c | 
| 75   | Építőipari foglalkozások                                                                       | 019406fd-da73-7986-8c19-0db056c6dbb7 | 
| 751  | Építőmesteri foglalkozások                                                                     | 019406fd-da73-7986-8c19-0db1ce3338b3 | 
| 7511 | Kőműves                                                                                        | 019406fd-da73-7986-8c19-0db24c2b6a2e | 
| 7512 | Gipszkartonozó, stukkózó                                                                       | 019406fd-da73-7986-8c19-0db38209847a | 
| 7513 | Ács                                                                                            | 019406fd-da73-7986-8c19-0db49685d288 | 
| 7514 | Épületasztalos                                                                                 | 019406fd-da73-7986-8c19-0db5e5d01a58 | 
| 7515 | Építményszerkezet-szerelő                                                                      | 019406fd-da73-7986-8c19-0db6d981e7bd | 
| 7519 | Egyéb építőmesteri foglalkozású                                                                | 019406fd-da73-7986-8c19-0db70e882957 | 
| 752  | Építési, szerelési foglalkozások                                                               | 019406fd-da73-7986-8c19-0db814f4f3a5 | 
| 7521 | Vezeték- és csőhálózat-szerelő (víz, gáz, fűtés)                                               | 019406fd-da73-7986-8c19-0db99d21e950 | 
| 7522 | Szellőző-, hűtő- és klimatizálóberendezés-szerelő                                              | 019406fd-da73-7986-8c19-0dba93f0900a | 
| 7523 | Felvonószerelő                                                                                 | 019406fd-da73-7986-8c19-0dbb8272ecbe | 
| 7524 | Épületvillamossági szerelő, villanyszerelő                                                     | 019406fd-da73-7986-8c19-0dbc9b0a3674 | 
| 7529 | Egyéb építési, szerelési foglalkozású                                                          | 019406fd-da73-7986-8c19-0dbd6fc4273c | 
| 753  | Építési szakipari foglalkozások                                                                | 019406fd-da73-7986-8c19-0dbe4dfbfedd | 
| 7531 | Szigetelő                                                                                      | 019406fd-da73-7986-8c19-0dbfb8852e79 | 
| 7532 | Tetőfedő                                                                                       | 019406fd-da73-7986-8c19-0dc0a60a4697 | 
| 7533 | Épület-, építménybádogos                                                                       | 019406fd-da73-7986-8c19-0dc15cae1759 | 
| 7534 | Burkoló                                                                                        | 019406fd-da73-7986-8c19-0dc2b311bf61 | 
| 7535 | Festő és mázoló                                                                                | 019406fd-da73-7986-8c19-0dc3213321b2 | 
| 7536 | Kőfaragó, műköves                                                                              | 019406fd-da73-7986-8c19-0dc416bb9625 | 
| 7537 | Kályha- és kandallóépítő                                                                       | 019406fd-da73-7986-8c19-0dc5d044c637 | 
| 7538 | Üvegező                                                                                        | 019406fd-da73-7986-8c19-0dc673d4c786 | 
| 7539 | Egyéb építési szakipari foglalkozású                                                           | 019406fd-da73-7986-8c19-0dc7aff2b2c3 | 
| 79   | Egyéb ipari és építőipari foglalkozások                                                        | 019406fd-da73-7986-8c19-0dc8d60ead3d | 
| 7911 | Ipari búvár                                                                                    | 019406fd-da73-7986-8c19-0dc9cabab264 | 
| 7912 | Ipari alpinista                                                                                | 019406fd-da73-7986-8c19-0dcaaa2fc748 | 
| 7913 | Robbantómester                                                                                 | 019406fd-da73-7986-8c19-0dcb4d1822fd | 
| 7914 | Kártevőirtó, gyomirtó                                                                          | 019406fd-da73-7986-8c19-0dcc4246c951 | 
| 7915 | Kéményseprő, épületszerkezet-tisztító                                                          | 019406fd-da73-7986-8c19-0dcda9fe6352 | 
| 7919 | Egyéb, máshova nem sorolható ipari és építőipari foglalkozású                                  | 019406fd-da73-7986-8c19-0dceb9f61f50 | 
| 8    | GÉPKEZELŐK, ÖSSZESZERELŐK, JÁRMŰVEZETŐK                                                        | 019406fd-da73-7986-8c19-0dcf31bb933e | 
| 81   | Feldolgozóipari gépek kezelői                                                                  | 019406fd-da73-7986-8c19-0dd0b2730d06 | 
| 811  | Élelmiszer-, ital-, dohánygyártó gépek kezelői                                                 | 019406fd-da73-7986-8c19-0dd11b335aee | 
| 8111 | Élelmiszer-, italgyártó gép kezelője                                                           | 019406fd-da73-7986-8c19-0dd207fc0ae0 | 
| 8112 | Dohánygyártó gép kezelője                                                                      | 019406fd-da73-7986-8c19-0dd35f66fae3 | 
| 812  | Könnyűipari gépek kezelői és gyártósor mellett dolgozók                                        | 019406fd-da73-7986-8c19-0dd4e15aba77 | 
| 8121 | Textilipari gép kezelője és gyártósor mellett dolgozó                                          | 019406fd-da73-7986-8c19-0dd5ab1fcb99 | 
| 8122 | Ruházati gép kezelője és gyártósor mellett dolgozó                                             | 019406fd-da73-7986-8c19-0dd6ca928ee5 | 
| 8123 | Bőrkikészítő és -feldolgozó gép kezelője és gyártósor mellett dolgozó                          | 019406fd-da73-7986-8c19-0dd702adc58a | 
| 8124 | Cipőgyártó gép kezelője és gyártósor mellett dolgozó                                           | 019406fd-da73-7986-8c19-0dd87fbbdda0 | 
| 8125 | Fafeldolgozó gép kezelője és gyártósor mellett dolgozó                                         | 019406fd-da73-7986-8c19-0dd91b286bac | 
| 8126 | Papír- és cellulóztermék-gyártó gép kezelője és gyártósor mellett dolgozó                      | 019406fd-da73-7986-8c19-0dda222f78c7 | 
| 813  | Vegyipari alapanyagot és terméket gyártók, gépkezelők                                          | 019406fd-da73-7986-8c19-0ddb53e39655 | 
| 8131 | Kőolaj- és földgázfeldolgozó gép kezelője                                                      | 019406fd-da73-7986-8c19-0ddcb01fb0ca | 
| 8132 | Vegyi alapanyagot és terméket gyártó gép kezelője                                              | 019406fd-da73-7986-8c19-0dddd66e7d62 | 
| 8133 | Gyógyszergyártó gép kezelője                                                                   | 019406fd-da73-7986-8c19-0ddefaf82d14 | 
| 8134 | Műtrágya- és növényvédőszer-gyártó gép kezelője                                                | 019406fd-da73-7986-8c19-0ddf0117986b | 
| 8135 | Műanyagtermék-gyártó gép kezelője                                                              | 019406fd-da73-7986-8c19-0de06b335cbc | 
| 8136 | Gumitermékgyártó gép kezelője                                                                  | 019406fd-da73-7986-8c19-0de125835809 | 
| 8137 | Fotó- és mozgófilmlaboráns                                                                     | 019406fd-da73-7986-8c19-0de2b73c8079 | 
| 814  | Alapanyaggyártó gépek kezelői                                                                  | 019406fd-da73-7986-8c19-0de355ad86da | 
| 8141 | Kerámiaipari terméket gyártó gép kezelője                                                      | 019406fd-da73-7986-8c19-0de43047263b | 
| 8142 | Üveget és üvegterméket gyártó gép kezelője                                                     | 019406fd-da73-7986-8c19-0de542320172 | 
| 8143 | Cement-, kő- és egyéb ásványianyag-feldolgozó gép kezelője                                     | 019406fd-da73-7986-8c19-0de6345a1500 | 
| 8144 | Papíripari alapanyagot gyártó gép kezelője                                                     | 019406fd-da73-7986-8c19-0de7a59ddbdf | 
| 815  | Fémfeldolgozó és -megmunkáló gépek kezelői                                                     | 019406fd-da73-7986-8c19-0de89042e02d | 
| 8151 | Fémfeldolgozó gép kezelője                                                                     | 019406fd-da73-7986-8c19-0de9bba217f9 | 
| 8152 | Fémmegmunkáló, felületkezelő gép kezelője                                                      | 019406fd-da73-7986-8c19-0dea75539b9b | 
| 819  | Egyéb feldolgozóipari gépek kezelői                                                            | 019406fd-da73-7986-8c19-0debdd48e58a | 
| 8190 | Egyéb, máshova nem sorolható feldolgozóipari gép kezelője                                      | 019406fd-da73-7986-8c19-0deca2d48e56 | 
| 82   | Összeszerelők                                                                                  | 019406fd-da73-7986-8c19-0dedad4b5a95 | 
| 8211 | Mechanikaigép-összeszerelő                                                                     | 019406fd-da73-7986-8c19-0dee89d63dc3 | 
| 8212 | Villamosberendezés-összeszerelő                                                                | 019406fd-da73-7986-8c19-0def6ccc277a | 
| 8219 | Egyéb termék-összeszerelő                                                                      | 019406fd-da73-7986-8c19-0df034c0dd90 | 
| 83   | Helyhez kötött gépek kezelői                                                                   | 019406fd-da73-7986-8c19-0df1c73f7dcb | 
| 831  | Bányászati gépek kezelői                                                                       | 019406fd-da73-7986-8c19-0df20a87f049 | 
| 8311 | Szilárdásvány-kitermelő gép kezelője (szén, kő)                                                | 019406fd-da73-7986-8c19-0df3b563764a | 
| 8312 | Kútfúró, mélyfúró gép kezelője (kőolaj, földgáz, víz)                                          | 019406fd-da73-7986-8c19-0df4dd549eae | 
| 832  | Egyéb, helyhez kötött gépek kezelői                                                            | 019406fd-da73-7986-8c19-0df5cf8fb127 | 
| 8321 | Energetikai gép kezelője                                                                       | 019406fd-da73-7986-8c19-0df65d69fb25 | 
| 8322 | Vízgazdálkodási gép kezelője                                                                   | 019406fd-da73-7986-8c19-0df7b466fb5e | 
| 8323 | Kazángépkezelő                                                                                 | 019406fd-da73-7986-8c19-0df8e4b8e6aa | 
| 8324 | Sugármentesítő gép, berendezés kezelője                                                        | 019406fd-da73-7986-8c19-0df91cc69e60 | 
| 8325 | Csomagoló-, palackozó- és címkézőgép kezelője                                                  | 019406fd-da73-7986-8c19-0dfa75e9825a | 
| 8326 | Mozigépész, vetítőgépész                                                                       | 019406fd-da73-7986-8c19-0dfb25cb53c8 | 
| 8327 | Mosodai gép kezelője                                                                           | 019406fd-da73-7986-8c19-0dfcb1a3a1ff | 
| 8329 | Egyéb, máshova nem sorolható, helyhez kötött gép kezelője                                      | 019406fd-da73-7986-8c19-0dfd9d0dcd6b | 
| 84   | Járművezetők és mobil gépek kezelői                                                            | 019406fd-da73-7986-8c19-0dfeb54aa141 | 
| 841  | Járművezetők és kapcsolódó foglalkozások                                                       | 019406fd-da73-7986-8c19-0dffabcd3224 | 
| 8411 | Mozdonyvezető                                                                                  | 019406fd-da73-7986-8c19-0e00a4aa1514 | 
| 8412 | Vasútijármű-vezetéshez kapcsolódó foglalkozású                                                 | 019406fd-da73-7986-8c19-0e0128bff1c9 | 
| 8413 | Villamosvezető                                                                                 | 019406fd-da73-7986-8c19-0e027e1170ca | 
| 8414 | Metróvezető                                                                                    | 019406fd-da73-7986-8c19-0e039f5ffc8b | 
| 8415 | Trolibuszvezető                                                                                | 019406fd-da73-7986-8c19-0e0487121b99 | 
| 8416 | Személygépkocsi-vezető                                                                         | 019406fd-da73-7986-8c19-0e05a272c872 | 
| 8417 | Tehergépkocsi-vezető, kamionsofőr                                                              | 019406fd-da73-7986-8c19-0e06f2a36e8b | 
| 8418 | Autóbuszvezető                                                                                 | 019406fd-da73-7986-8c19-0e0762144677 | 
| 8419 | Egyéb járművezető és kapcsolódó foglalkozású                                                   | 019406fd-da73-7986-8c19-0e08d22e8890 | 
| 842  | Mobil gépek kezelői                                                                            | 019406fd-da73-7986-8c19-0e096f740103 | 
| 8421 | Mezőgazdasági, erdőgazdasági, növényvédő gép kezelője                                          | 019406fd-da73-7986-8c19-0e0afbab2466 | 
| 8422 | Földmunkagép és hasonló könnyű- és nehézgép kezelője                                           | 019406fd-da73-7986-8c19-0e0bc8365c82 | 
| 8423 | Köztisztasági, településtisztasági gép kezelője                                                | 019406fd-da73-7986-8c19-0e0c01beca31 | 
| 8424 | Daru, felvonó és hasonló anyagmozgató gép kezelője                                             | 019406fd-da73-7986-8c19-0e0dca146bb9 | 
| 8425 | Targoncavezető                                                                                 | 019406fd-da73-7986-8c19-0e0e152f22c7 | 
| 843  | Hajózási foglalkozások                                                                         | 019406fd-da73-7986-8c19-0e0f0703b7a8 | 
| 8430 | Hajószemélyzet, kormányos, matróz                                                              | 019406fd-da73-7986-8c19-0e1012df13a7 | 
| 9    | SZAKKÉPZETTSÉGET NEM IGÉNYLŐ (EGYSZERŰ) FOGLALKOZÁSOK                                          | 019406fd-da73-7986-8c19-0e11fb3effc8 | 
| 91   | Takarítók és hasonló jellegű egyszerű foglalkozások                                            | 019406fd-da73-7986-8c19-0e1282c49214 | 
| 911  | Takarítók és kisegítők                                                                         | 019406fd-da73-7986-8c19-0e130350e16c | 
| 9111 | Háztartási takarító és kisegítő                                                                | 019406fd-da73-7986-8c19-0e140f55f994 | 
| 9112 | Intézményi takarító és kisegítő                                                                | 019406fd-da73-7986-8c19-0e15e92d2259 | 
| 9113 | Kézi mosó, vasaló                                                                              | 019406fd-da73-7986-8c19-0e16bba1b3dc | 
| 9114 | Járműtakarító                                                                                  | 019406fd-da73-7986-8c19-0e1776aaba7a | 
| 9115 | Ablaktisztító                                                                                  | 019406fd-da73-7986-8c19-0e18a79db978 | 
| 9119 | Egyéb takarító és kisegítő                                                                     | 019406fd-da73-7986-8c19-0e19f8138835 | 
| 92   | Egyszerű szolgáltatási, szállítási és hasonló foglalkozások                                    | 019406fd-da73-7986-8c19-0e1a0012ca7d | 
| 921  | Szemétgyűjtők és hasonló foglalkozások                                                         | 019406fd-da73-7986-8c19-0e1b60454849 | 
| 9211 | Szemétgyűjtő, utcaseprő                                                                        | 019406fd-da73-7986-8c19-0e1cb423736e | 
| 9212 | Hulladékosztályozó                                                                             | 019406fd-da73-7986-8c19-0e1d16805a47 | 
| 922  | Szállítási foglalkozások és rakodók                                                            | 019406fd-da73-7986-8c19-0e1eb7e95bcb | 
| 9221 | Pedálos vagy kézi hajtású gépek vezetője                                                       | 019406fd-da73-7986-8c19-0e1fb8ea55b2 | 
| 9222 | Állati erővel vont jármű hajtója                                                               | 019406fd-da73-7986-8c19-0e20c89ecd79 | 
| 9223 | Rakodómunkás                                                                                   | 019406fd-da73-7986-8c19-0e212905b77e | 
| 9224 | Pultfeltöltő, árufeltöltő                                                                      | 019406fd-da74-7118-a387-2c1157c546e4 | 
| 9225 | Kézi csomagoló                                                                                 | 019406fd-da74-7118-a387-2c1285a35477 | 
| 923  | Egyéb egyszerű szolgáltatási és szállítási foglalkozások                                       | 019406fd-da74-7118-a387-2c138345cecb | 
| 9231 | Portás, telepőr, egyszerű őr                                                                   | 019406fd-da74-7118-a387-2c14698462c4 | 
| 9232 | Mérőóra-leolvasó és hasonló egyszerű foglalkozású                                              | 019406fd-da74-7118-a387-2c1558b6d66c | 
| 9233 | Hivatalsegéd, kézbesítő                                                                        | 019406fd-da74-7118-a387-2c1684bdef6b | 
| 9234 | Hordár, csomagkihordó                                                                          | 019406fd-da74-7118-a387-2c17528ec811 | 
| 9235 | Gyorséttermi eladó                                                                             | 019406fd-da74-7118-a387-2c1823c63264 | 
| 9236 | Konyhai kisegítő                                                                               | 019406fd-da74-7118-a387-2c195c45588a | 
| 9237 | Háztartási alkalmazott                                                                         | 019406fd-da74-7118-a387-2c1ac2a58d61 | 
| 9238 | Parkolóőr                                                                                      | 019406fd-da74-7118-a387-2c1bcb502725 | 
| 9239 | Egyéb, máshova nem sorolható egyszerű szolgáltatási és szállítási foglalkozású                 | 019406fd-da74-7118-a387-2c1c493707fd | 
| 93   | Egyszerű ipari, építőipari, mezőgazdasági foglalkozások                                        | 019406fd-da74-7118-a387-2c1dad298704 | 
| 931  | Egyszerű ipari foglalkozások                                                                   | 019406fd-da74-7118-a387-2c1e558b7110 | 
| 9310 | Egyszerű ipari foglalkozású                                                                    | 019406fd-da74-7118-a387-2c1f3fe33e32 | 
| 932  | Egyszerű építőipari foglalkozások                                                              | 019406fd-da74-7118-a387-2c208095cb28 | 
| 9321 | Kubikos                                                                                        | 019406fd-da74-7118-a387-2c21d79a24d5 | 
| 9329 | Egyéb egyszerű építőipari foglalkozású                                                         | 019406fd-da74-7118-a387-2c22b1df4215 | 
| 933  | Egyszerű mezőgazdasági, erdészeti, vadászati és halászati foglalkozások                        | 019406fd-da74-7118-a387-2c2364c67370 | 
| 9331 | Egyszerű mezőgazdasági foglalkozású                                                            | 019406fd-da74-7118-a387-2c24ce96b957 | 
| 9332 | Egyszerű erdészeti, vadászati és halászati foglalkozású                                        | 019406fd-da74-7118-a387-2c2586735a40 | 

### DICTDEF# LANGUAGE

```yaml
    label: LANGUAGE
```

| Code | Name   | Id                                   |
|------|--------|--------------------------------------|
| DE   | német  | 01940700-03e3-7adf-b9dd-4f72870fef78 |
| EN   | angol  | 01940700-0eb0-7418-a856-4d46eff0d0bc |
| HU   | magyar | 01940700-1612-71da-99b4-0cb61aa7b02d |

### DICTDEF# MEDICAL_EXAM_RESULT

```yaml
    label: MEDICAL_EXAM_RESULT
```

| Code                       | Name                      | Id                                   |
|----------------------------|---------------------------|--------------------------------------|
| SUITABLE                   | Alkalmas                  | 01940700-2705-7574-ac47-d5a702518928 |
| SUITABLE_WITH_RESTRICTIONS | Megszorításokkal alkalmas | 01940700-2e0e-77f5-9704-1c0013bf7ff1 |
| UNSUITABLE                 | Alkalmatlan               | 01940700-3416-7cbd-9611-ec15da8ebd42 |

### DICTDEF# MEDICAL_EXAM_STATUS

```yaml
    label: MEDICAL_EXAM_STATUS
```

| Code   | Name      | Id                                   |
|--------|-----------|--------------------------------------|
| CLOSED | Lezárt    | 01940700-4021-706c-bc0b-9f6ef6352d9a |
| PLAN   | Tervezett | 01940700-4653-740c-ae2c-d9e11bb66e0b |

### DICTDEF# METHOD_OF_TERMINATION

```yaml
    label: METHOD_OF_TERMINATION
```

| Code                  | Name                          | Id                                   |
|-----------------------|-------------------------------|--------------------------------------|
| COMMON_AGREEMENT      | Közös megegyezéssel           | 01940700-50f2-79f6-817a-2100a041a459 |
| IMMEDIATE_RESIGNATION | Azonnali hatályú felmondással | 01940700-56ec-7f03-8fcf-ec33984b6516 |
| RESIGNATION           | Felmondással                  | 01940700-5ca8-707e-b6d5-af6dda78b43e |

### DICTDEF# OBLIGATION

```yaml
    label: OBLIGATION
```

| Code      | Name         | Id                                   |
|-----------|--------------|--------------------------------------|
| CONDITION | Feltétellel  | 01940700-6ab4-7b46-88f8-2a9ff0183f78 |
| N         | Nem kötelező | 01940700-7101-7623-b4fe-5a07fcaa909f |
| Y         | Kötelező     | 01940700-7745-718e-b06f-6888dea3ad42 |

### DICTDEF# PARTNER_STATUS

```yaml
    label: PARTNER_STATUS
```

| Code       | Name    | Id                                   |
|------------|---------|--------------------------------------|
| ACTIVE     | Aktív   | 01940700-8474-7454-9a65-a33b00433b5b |
| INACTIVE   | Inaktív | 01940700-8a5e-7b57-9a1b-d5ef8621e4cc |
| INCOMPLETE | Hiányos | 01940700-8f3b-7b1b-8b4b-0f3b1f7b1b8b |

### DICTDEF# PARTNER_ROLE

```yaml
    label: PARTNER_ROLE
```

| Code     | Name       | Id                                   |
|----------|------------|--------------------------------------|
| SUPPLIER | Beszállító | 01940700-9660-7def-b074-5476e7bce22b |
| CUSTOMER | Vevő       | 01940700-9cd7-729f-b36c-69d61f7cd42a |

### DICTDEF# PAYROLL_TYPE

```yaml
    label: PAYROLL_TYPE
```

| Code            | Name            | Id                                   |
|-----------------|-----------------|--------------------------------------|
| HOURLY_WAGE     | Órabér          | 01940700-a9a4-7448-ac8b-2daeb5c5554c |
| MONTHLY_SALERY  | Havibér         | 01940700-b1cb-76b3-9fa4-515c532a677d |
| PERFORMANCE_PAY | Teljesítménybér | 01940700-b838-72c7-8b84-ff2becae4314 |

### DICTDEF# POSITION

```yaml
    label: POSITION
```

| Code                    | Name               | Id                                   |
|-------------------------|--------------------|--------------------------------------|
| ACCOUNTANT              | könyvelő           | 01940700-c5b3-7e86-b0a5-213cfdbe950f |
| HR_COLLEAGUE            | munkaügyis         | 01940700-cc26-7a1a-ac05-e0f4cd0cdd72 |
| REGIONAL_REPRESANTATIVE | területi képvíselő | 01940700-d57f-70a0-a162-f6cb8ce1a334 |
| SECRETARY               | titkár             | 01940700-dbfe-7e50-a3bd-5681e5026cf4 |
| WAREHAUSMAN             | raktáros           | 01940700-e292-7854-b7ba-06f406461d67 |

### DICTDEF# REASON

```yaml
    label: REASON
```

| Code | Name                                         | Id                                   |
|------|----------------------------------------------|--------------------------------------|
| 1    | Üzemi baleset                                | 01940701-00c0-7da3-9183-4ca78d6d1cde |
| 2    | Foglalkoztatási megbetegedés                 | 01940701-0760-7271-8f6b-bf416e349bd9 |
| 3    | Közúti baleset                               | 01940701-0d8b-7239-a16f-52f514a4239f |
| 4    | Egyéb baleset                                | 01940701-1375-7945-856e-a2322ee9c77e |
| 5    | Beteg gyermek ápolása                        | 01940701-19aa-7cd3-afe6-741d0f781d6f |
| 6    | Szülés                                       | 01940701-1f87-7e20-a6fe-13db040d67e6 |
| 7    | hatósági elkülönítés közegészségügyi okokból | 01940701-25b4-7fb6-824a-9a3cc5110314 |
| 8    | egyéb betegség                               | 01940701-2bcf-7d7d-a6b9-5044dca62012 |
| 9    | veszélyeztetett terhesség                    | 01940701-3192-774d-afec-40257ddb7acb |

### DICTDEF# SETTLEMENT_BASIS

```yaml
    label: SETTLEMENT_BASIS
```

| Code        | Name            | Id                                   |
|-------------|-----------------|--------------------------------------|
| PERFORMANCE | Teljesítmény    | 01940701-3fef-7561-8444-23cf703e259d |
| TIME_WORKED | Ledolgozott idő | 01940701-462a-7950-a53b-333a24472f14 |

### DICTDEF# SETTLEMENT_FREQUENCY

```yaml
    label: SETTLEMENT_FREQUENCY
```

| Code | Name         | Id                                   |
|------|--------------|--------------------------------------|
| 15D  | 15 naponként | 01940701-5370-7cc8-83ae-fdd878c41f45 |
| 1M   | Havi         | 01940701-5991-75fc-b8c0-7ca0fe416afe |
| 1W   | Heti         | 01940701-5fc3-704e-9008-02d72e8ce660 |

### DICTDEF# STATUS

```yaml
    label: STATUS
```

| Code     | Name        | Id                                   |
|----------|-------------|--------------------------------------|
| CLOSED   | Lezárt      | 01940701-6c41-700d-9354-ae8b4bee0611 |
| FINISHED | Befejezett  | 01940701-73ec-709b-af7e-3cea53a2361e |
| ONGOING  | Folyamatban | 01940701-7a0e-7a7b-90a7-0e29c9bfcbdf |

### DICTDEF# TASK_TYPE

```yaml
    label: TASK_TYPE
```

| Code   | Name   | Id                                   |
|--------|--------|--------------------------------------|
| OTHER  | Egyéb  | 01940701-85a6-7490-ba38-af261208d761 |
| STAIRS | Lépcső | 01940701-8ba7-7b31-87f9-a9e9991c6ed7 |
| WALL   | Fal    | 01940701-92ac-7c2b-b89f-7171c17c94f8 |

### DICTDEF# TIME_USE_TYPE

```yaml
    label: TIME_USE_TYPE
```

| Code       | Name      | Id                                   |
|------------|-----------|--------------------------------------|
| HOLIDAY    | Szabadság | 01940701-a129-7279-b406-b1a4ce5239de |
| SICK_PAYED | Táppénz   | 01940701-a762-7245-a652-5ae99908f463 |
| WORK       | Munka     | 01940701-b1f2-7af4-b263-5e1ece13c632 |

### DICTDEF# WORKER_NOTE_STATUS

```yaml
    label: WORKER_NOTE_STATUS
```

| Code     | Name    | Id                                   |
|----------|---------|--------------------------------------|
| ACTIVE   | Aktív   | 01940701-c266-7199-940a-b7e2fe10b19f |
| INACTIVE | Inaktív | 01940701-ca2b-7df9-b78f-af5ff1685c42 |

### DICTDEF# WORKER_STATUS

```yaml
    label: WORKER_STATUS
```

| Code        | Name          | Id                                   |
|-------------|---------------|--------------------------------------|
| ACTIVE      | Aktív         | 01940701-d5e6-7fcd-afba-08bb361964dd |
| COME_ON     | GYES          | 01940701-dec7-795d-b65d-cb087ce8b754 |
| DURING_EXIT | Kilépés alatt | 01940701-e491-7a0a-8592-fe1224425529 |
| INTERESTED  | Érdeklődő     | 01940701-ea1b-7b4b-a29e-3ddc58958caa |
| PROBATION   | Próbaidős     | 01940701-ef64-774d-aa75-2b0f54b1a5ca |
| RESIGNED    | Felmondott    | 01940701-f51b-7cf4-a464-95f84288d833 |

### DICTDEF# WORKING_TIME_SCHEDULE_STATUS

```yaml
    label: WORKING_TIME_SCHEDULE_STATUS
```

| Code   | Name   | Id                                   |
|--------|--------|--------------------------------------|
| CLOSED | Lezárt | 01940702-030e-72b8-9874-086ce9154587 |
| PLAN   | Terv   | 01940702-0af2-7c7a-becd-4ac3a5cc53df |

### DICTDEF# INVOICE_STATE

```yaml
    label: INVOICE_STATE
```

| Code        | Name             | Id                                   |
|-------------|------------------|--------------------------------------|
| TERV        | Tervezett        | 01940702-1bca-7365-bd27-96a2d8e4b7cf |
| ELLVAR      | Ellenőrzésre vár | 01940702-2248-7170-9e9e-3512eac4647c |
| JAVVAR      | Javításra vár    | 01940702-2803-7e42-a223-52af0fdaecb3 |
| ROGZ        | Rögzített        | 01940702-2d64-783d-a8a4-e94e4e560942 |
| FINVAR      | Számlázásra vár  | 01940702-32fb-7ebb-9d36-2e3db6b01e5d |
| ELO         | Élő              | 01940702-3976-75b3-884d-6f103fa5e147 |
| RESZTELJ    | Részteljesített  | 01940702-4198-70bf-a4eb-54edfbb03bc3 |
| RENDEZVE    | Rendezve         | 01940702-4796-721f-a045-c66a451995f3 |
| LEZART      | Lezárt           | 01940702-4ec8-7d06-8d0d-11874fe2287b |
| ELUTASITOTT | Elutasított      | 01940702-54f8-7335-ad34-21f64f9b8578 |
| TOROLT      | Törölt           | 01940702-5b3d-7000-bdb3-474b09f1dfbe |

### DICTDEF# INVOICE_TYPE

```yaml
    label: INVOICE_TYPE
```

| Code | Name             | Id                                   |
|------|------------------|--------------------------------------|
| SZAM | Számla           | 01940702-795b-7214-8219-4bf27b7e1d23 |
| STOR | Sztornó számla   | 01940702-80ab-7211-9332-a0eed2af9c3b |
| DIJB | Díjbekérő számla | 01940702-861d-7f13-87cc-11ab80738670 |

### DICTDEF# PAYMENT_METHOD

```yaml
    label: PAYMENT_METHOD
```

| Code          | Name           | Id                                   |
|---------------|----------------|--------------------------------------|
| CREDIT_CARD   | Bankkártya     | 02967c33-a123-7a22-b345-01ac432de000 |
| BANK_TRANSFER | Banki átutalás | 02967c33-b234-7b33-c456-12bd543ef111 |
| PAYPAL        | PayPal         | 02967c33-c345-736a-9408-5cd3e99dc222 |
| CASH          | Készpénz       | 01940702-950e-7688-9cce-0ac50dd650ed |
| CHEQ          | Csekk          | 01940702-9f92-70fc-9ef4-696a03fecb0c |
| OTHER         | Egyéb          | 02967c33-d456-7d9b-9c77-003175234333 |

### DICTDEF# CURRENCY

```yaml
    label: CURRENCY
```

| Code | Name         | Id                                   |
|------|--------------|--------------------------------------|
| HUF  | Forint       | 01940702-b076-7c23-b1bc-358b900dcc44 |
| EUR  | Euro         | 01940702-b599-70be-bb40-3e5b38196e1b |
| USD  | US Dollár    | 01940702-bb0c-7010-976a-b256ce811f49 |
| GBP  | Angol font   | 01940702-c0a1-7b4c-8f2d-5e3f9b6a0c3d |
| CHF  | Svájci frank | 01940702-c65e-7792-b201-eb99933a1360 |

### DICTDEF# TASK_RULE_TYPE

```yaml
    label: TASK_RULE_TYPE
```

| Code          | Name          | Id                                   |
|---------------|---------------|--------------------------------------|
| SENDER_REGEX  | Feladó minta  | 01940702-d354-73e7-aa8c-a2a85196c49a |
| SUBJECT_REGEX | Subject minta | 01940702-d8e5-7187-ae32-41ca4d9aed99 |

### DICTDEF# BANK_ACCOUNT_STATUS

```yaml
    label: BANK_ACCOUNT_STATUS
```

| Code     | Name    | Id                                   |
|----------|---------|--------------------------------------|
| ACTIVE   | Aktív   | 01940702-e6f8-7e74-b1b7-536d87d78c49 |
| INACTIVE | Inaktív | 01940702-ed45-7216-8f2f-5e9e4180dd37 |
| DELETED  | Törölt  | 01940702-f39f-790a-b36b-010fbce42b96 |

### DICTDEF# SUPPLIER

```yaml
    label: SUPPLIER
```

| Code  | Name        | Id                                   |
|-------|-------------|--------------------------------------|
| POWER | Power bizt. | 01940703-02c3-730a-a7d9-7e5e3338c1bc |
| RIEL  | RIEL        | 01940703-092b-7484-b720-ce192f8b3d05 |

### DICTDEF# VAT_PERIOD

```yaml
    label: VAT_PERIOD
```

| Code     | Name       | Id                                   |
|----------|------------|--------------------------------------|
| MONTHLY  | Havi       | 01940703-15ac-76e1-8e40-92758d07c4ba |
| QUATERLY | Negyedéves | 01940703-1c51-7dd8-82c9-e7106abb2e75 |
| YEARLY   | Éves       | 01940703-23fd-756c-b107-9177b47064de |

### DICTDEF# PROJECT_STATUS

```yaml
    label: PROJECT_STATUS
```

| Code     | Name        | Id                                   |
|----------|-------------|--------------------------------------|
| CLOSED   | Lezárt      | 01940703-3327-7e56-8aed-1c56e1430fc2 |
| FINISHED | Befejezett  | 01940703-3a4b-734e-be2f-ca21a87938c9 |
| ONGOING  | Folyamatban | 01940703-4099-7f6b-bc34-e05aa22b44af |

### DICTDEF# CONTACT_TYPE

```yaml
    label: CONTACT_TYPE
```

| Code  | Name    | Id                                   |
|-------|---------|--------------------------------------|
| EMAIL | Email   | 01940703-4db4-7aae-9e6d-2128bff35bbd |
| PHONE | Telefon | 01940703-55a0-7e8c-be4b-6fef1034a9bd |

### DICTDEF# QUALIFICATION_TYPE

```yaml
    label: QUALIFICATION_TYPE
```

| Code             | Name                | Id                                   |
|------------------|---------------------|--------------------------------------|
| ACCOUNTANT       | Könyvelő            | 01940703-6c78-7a11-a0a6-e5b219dddda4 |
| ARCHITECT        | Építőmérnök         | 01940703-7745-7c87-96cf-b02355fbb6e4 |
| CRANE_HANDLING   | Darukezelés         | 01940703-7e89-7bc5-965e-cce3a9edfeef |
| DRIVING_CAR      | Személyautó vezetés | 01940703-8449-7a79-a55d-720d7459dca9 |
| ENGLISH_LANGUAGE | Angol               | 01940703-8a25-7367-8575-2b5f42376b4d |
| FORKLIFT_DRIVING | Targoncavezetés     | 01940703-8fa4-75ed-bea5-524c6d85b030 |
| GERMAN_LANGUAGE  | Német               | 01940703-95a2-7e23-8c90-b1884e6bbcc3 |
| HEAVY_OP         | Nehézgépkezelő      | 01940703-9bb6-75bd-b33d-cd61ad3d3dc2 |
| MASON            | Kőműves             | 01940703-a199-75a2-b8a0-9016ac2ef0ad |
| WOODWORKER       | Asztalos            | 01940703-a7d3-7827-9e52-542c922c755d |

### DICTDEF# CITIZENSHIP

```yaml
    label: CITIZENSHIP
```

| Code | Name        | Id                                   |
|------|-------------|--------------------------------------|
| HU   | Magyar      | 01940704-87ee-7aff-ac11-603938fff434 |
| DE   | Német       | 01940704-87ee-7aff-ac11-603a5519ae81 |
| EN   | Angol       | 01940704-87ee-7aff-ac11-603ba97901cc |
| FR   | Francia     | 01940704-87ee-7aff-ac11-603cf912a30e |
| IT   | Olasz       | 01940704-87ee-7aff-ac11-603d57df8a11 |
| ES   | Spanyol     | 01940704-87ee-7aff-ac11-603e63e35d62 |
| RO   | Román       | 01940704-87ee-7aff-ac11-603f078b3f8d |
| PL   | Lengyel     | 01940704-87ee-7aff-ac11-60405cd4304a |
| CZ   | Cseh        | 01940704-87ee-7aff-ac11-6041791c487d |
| SK   | Szlovák     | 01940704-87ee-7aff-ac11-6042e287dcc2 |
| SI   | Szlovén     | 01940704-87ee-7aff-ac11-6043203fb2b2 |
| HR   | Horvát      | 01940704-87ee-7aff-ac11-6044156a34b7 |
| RS   | Szerb       | 01940704-87ee-7aff-ac11-60459ae65180 |
| BA   | Bosnyák     | 01940704-87ee-7aff-ac11-60462240106a |
| ME   | Montenegrói | 01940704-87ee-7aff-ac11-6047b2578122 |
| XK   | Koszovói    | 01940704-87ee-7aff-ac11-60486651f799 |
| AL   | Albán       | 01940704-87ee-7aff-ac11-6049383c81f0 |
| MK   | Macedón     | 01940704-87ee-7aff-ac11-604a4c4e3696 |
| BG   | Bolgár      | 01940704-87ee-7aff-ac11-604b88f8c1b6 |
| GR   | Görög       | 01940704-87ee-7aff-ac11-604c940a4c29 |
| TR   | Török       | 01940704-87ee-7aff-ac11-604d129bf887 |
| UR   | Ukrán       | 01940704-87ee-7aff-ac11-604e79726638 |

### DICTDEF# ADDRESS_TYPE

```yaml
    label: ADDRESS_TYPE
```

| Code      | Name           | Id                                   |
|-----------|----------------|--------------------------------------|
| RESIDENCE | Lakcím         | 01940704-b64f-7614-9230-91a04dabe660 |
| WORK      | Munkahely      | 01940704-b64f-7614-9230-91a1edf4f121 |
| PERMANENT | Állandó lakcím | 01940704-b64f-7614-9230-91a284333e34 |
| MAIL      | Levelezési cím | 01940704-b64f-7614-9230-91a3a7599a22 |
| SITE      | Telephely      | 01940704-b64f-7614-9230-91a4e58fd755 |

### DICTDEF# RIGHT_PARAMETER

```yaml
    label: RIGHT_PARAMETER
```

| Code | Name        | Id                                   |
|------|-------------|--------------------------------------|
| 1    | Új          | 01940704-f708-751b-aa6b-777a14c9add8 |
| 2    | Módosítás   | 01940704-f708-751b-aa6b-777bfa7997ff |
| 3    | Törlés      | 01940704-f708-751b-aa6b-777cabdb9a92 |
| 4    | Megtekintés | 01940704-f708-751b-aa6b-777d6b1ed401 |
| 5    | Nyomtatás   | 01940704-f708-751b-aa6b-777e68140678 |
| 6    | Exportálás  | 01940704-f708-751b-aa6b-777f997416dd |
| 7    | Importálás  | 01940704-f708-751b-aa6b-778056b88a1e |
| 8    | Mentés      | 01940704-f708-751b-aa6b-7781497537ea |

### DICTDEF# SETTING_TYPE

```yaml
    label: SETTING_TYPE
```

| Code | Name     | Id                                   |
|------|----------|--------------------------------------|
| 1    | Szöveges | 01940705-1f40-764f-9938-a93a44939bfa |
| 2    | Szám     | 01940705-1f40-764f-9938-a93b84ae487e |
| 3    | Dátum    | 01940705-1f40-764f-9938-a93c3e239b6a |
| 4    | Logikai  | 01940705-1f40-764f-9938-a93d9c7df04a |
| 5    | Szöveg   | 01940705-1f40-764f-9938-a93e2c8728bf |

### DICTDEF# CONTRACT_TYPE

```yaml
    label: CONTRACT_TYPE
```

| Code | Name           | Id                                   |
|------|----------------|--------------------------------------|
| 1    | Munkaszerződés | 01940705-4985-79e8-8627-5f76a647ae79 |
| 2    | Szolgáltatási  | 01940705-4985-79e8-8627-5f77a0380f15 |
| 3    | Megbízási      | 01940705-4985-79e8-8627-5f788cb6baa2 |
| 4    | Egyéb          | 01940705-4985-79e8-8627-5f79def21249 |

### DICTDEF# SUBJECT

```yaml
    label: SUBJECT
```

| Code | Name      | Id                                   |
|------|-----------|--------------------------------------|
| 1    | Árajánlat | 01940705-6ae1-7c66-b13a-0ff3b6c717c6 |
| 2    | Szerződés | 01940705-6ae1-7c66-b13a-0ff424961f67 |
| 3    | Számla    | 01940705-6ae1-7c66-b13a-0ff5c01e1e0b |
| 4    | Egyéb     | 01940705-6ae1-7c66-b13a-0ff6a21f9726 |

### DICTDEF# VALIDITY_TYPE

```yaml
    label: VALIDITY_TYPE
```

| Code | Name     | Id                                   |
|------|----------|--------------------------------------|
| 1    | Érvényes | 01940705-8577-7aca-abdc-7c90b3a61bbb |
| 2    | Lejárt   | 01940705-8f04-7247-89d8-a83adcea44e5 |

### DICTDEF# PAYMENT_STATUS

```yaml
    label: PAYMENT_STATUS
```

| Code | Name         | Id                                   |
|------|--------------|--------------------------------------|
| 1    | Fizetett     | 01940705-9ae2-7017-a755-5616c6a6d4b3 |
| 2    | Kifizetetlen | 01940705-a20b-7c10-b77d-a8b883cbb58b |

### DICTDEF# PROCESSING_STATUS

```yaml
    label: PROCESSING_STATUS
```

| Code | Name       | Id                                   |
|------|------------|--------------------------------------|
| 1    | Beérkezett | 01940705-ac9c-71e3-8d51-bada8c64d91e |
| 2    | Besorolt   | 01940705-b3ee-77e6-af56-e300a4ee8555 |
| 3    | Befogadott | 019481b2-9e91-7281-9747-e50358d2c1cf |

### DICTDEF# UNIT_OF_MEASURE

```yaml
    label: UNIT_OF_MEASURE
```

| Code | Name | Id                                   |
|------|------|--------------------------------------|
| KG   | kg   | 01940705-d353-73ba-bac9-49de6fbe2a6f |
| L    | l    | 01940705-d353-73ba-bac9-49df4a538f35 |
| M    | m    | 01940705-d353-73ba-bac9-49e02da3546a |
| DB   | db   | 01940705-d353-73ba-bac9-49e103cf18f2 |

### DICTDEF# WORKER_ASSIGNMENT_REQUEST

```yaml
    label: WORKER_ASSIGNMENT_REQUEST
```

| Code  | Name        | Id                                   |
|-------|-------------|--------------------------------------|
| NEW   | Új          | 01940705-f49c-7cac-a579-05e8cc87a93c |
| MOD   | Módosítás   | 01940705-f49c-7cac-a579-05e9d930b053 |
| DEL   | Törlés      | 01940705-f49c-7cac-a579-05eaaa399fc6 |
| VIEW  | Megtekintés | 01940705-f49c-7cac-a579-05eb58b09101 |
| PRINT | Nyomtatás   | 01940705-f49c-7cac-a579-05ec431b56b9 |
| EXP   | Exportálás  | 01940705-f49c-7cac-a579-05ed06dd693a |
| IMP   | Importálás  | 01940705-f49c-7cac-a579-05eecd8a2ec7 |
| SAVE  | Mentés      | 01940705-f49c-7cac-a579-05efa74b5a3e |

### DICTDEF# WORKSHEET_STATUS

```yaml
    label: WORKSHEET_STATUS
```

| Code     | Name        | Id                                   |
|----------|-------------|--------------------------------------|
| CLOSED   | Lezárt      | 01940706-13ef-77d4-af60-9381b6ab3b2c |
| FINISHED | Befejezett  | 01940706-13ef-77d4-af60-9382c2611e42 |
| ONGOING  | Folyamatban | 01940706-13ef-77d4-af60-938365eb2ff2 |

### DICTDEF# MATERIAL_USE

```yaml
    label: MATERIAL_USE
``` 

| Code       | Name        | Id                                   |
|------------|-------------|--------------------------------------|
| USED       | Felhasznált | 01940706-309f-7924-828e-9534a39d8b2b |
| DISMOUNTED | Leszerelt   | 01940706-309f-7924-828e-9535e0d60b6c |
| DISCARDED  | Selejtezett | 01940706-309f-7924-828e-953658ac2527 |

### DICTDEF# MATERIAL_REASON

```yaml
    label: MATERIAL_REASON
```

| Code    | Name      | Id                                   |
|---------|-----------|--------------------------------------|
| DAMAGED | Sérült    | 01940706-4be8-7abd-b8f7-87bd677388e4 |
| LOST    | Elveszett | 01940706-4be8-7abd-b8f7-87bea7b1b1b7 |
| OTHER   | Egyéb     | 01940706-4be8-7abd-b8f7-87c0b1b1b1b1 |

### DICTDEF# CLOSURE_STATUS

```yaml
    label: CLOSURE_STATUS
```

| Code   | Name    | Id                                   |
|--------|---------|--------------------------------------|
| CLOSED | Lezárt  | 01940706-59de-7f46-8271-2df713337fd5 |
| OPEN   | Nyitott | 01940706-60dc-70ad-91a9-11c3967dae93 |

### DICTDEF# CLOSURE_ITEM_TYPE

```yaml
    label: CLOSURE_ITEM_TYPE
```

| Code     | Name              | Id                                   |
|----------|-------------------|--------------------------------------|
| WORKER   | Munkavégzés       | 01940706-751f-7369-b876-af7873de9c5a |
| MATERIAL | Anyagfelhasználás | 01940706-7d5e-77dc-a509-4654103a4b58 |

### DICTDEF# MOVEMENT_TYPE

```yaml
    label: MOVEMENT_TYPE
```

| Code     | Name        | Id                                   |
|----------|-------------|--------------------------------------|
| IN       | Bevételezés | 0194402b-e5f3-7364-9913-ba00a36514db |
| OUT      | Kivételezés | 0194402b-ffc4-764a-9352-1c9881385f67 |
| MOVE     | Mozgatás    | 0194402c-15c1-7646-9bee-bea860a04360 |
| DISPOSAL | Selejtezés  | 0194402c-292c-7cc0-8a05-6ee529a60bfc |

