# Specifikáció

## Változtatások

| Verzió/Dátum     | Leírás      |
|------------------|-------------|
| 1.0 - 2024.11.27 | Első verzió |

## Entitások

### FIGDEF# postalcode

```yaml
    label: Irányítószám-Település
    pluralLabel: Irányítószámok-Települések
    type: TABLE
```

| Field      | Label        | Type    | Size | Decimals | Nullable | Unique | AutoIncr. | Description | FT | Foreign | FK |
|------------|--------------|---------|------|----------|----------|--------|-----------|-------------|----|---------|----|
| id         | Id           | IDENT   |      |          |          |        |           |             |    |         |    | 
| code       | Irányítószám | VARCHAR | 16   |          |          |        |           |             |    |         |    | 
| settlement | Település    | VARCHAR | 64   |          |          |        |           |             |    |         |    | 
| province   | Tartomány    | VARCHAR | 64   |          | X        |        |           |             |    |         |    | 

