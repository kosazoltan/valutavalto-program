# Compliance feature-flag matrix - 2026-06-09

## Scope

Ez a matrix a Product Ready audit soran vizsgalt compliance kapcsolokat rogziti.
Allitas csak a jelenlegi repo kodjabol, migracioibol es tesztjeibol szerepel.

## Kapcsolok

| Flag | Kod-default | DB/migracio teny | Enforcement helye | Teszt bizonyitek | Product Ready megjegyzes |
| --- | --- | --- | --- | --- | --- |
| `PMT_STRICT_ENFORCEMENT` | `true` | Ebben a korben kulon migracios default nem lett bizonyitva. | `PmtComplianceValidator` 300k+ PEP-minoseg es kepviselt fel teljes azonositas. | `PmtComplianceValidatorTest` | Kod szerint strict default. Eles DB-ben parameter-ertek ellenorzendo go-live elott. |
| `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT` | `false` | `V291__activate_source_of_funds_50m_enforcement.sql` beszurja/frissiti `true` ertekre. | `TransactionService.enforceSourceOfFunds`, `TransactionOperationHelper.enforceSourceOfFunds`; `>=50M` HUF, elfogadott dokumentum: kozjegyzo/ugyvedi maganokirat vagy max. 3 eves banki szlip. | `TransactionServiceSourceOfFundsTest` | Kod-default fail-open, migracio elesiti. Product Ready elott az eles DB parameter-erteket es UX mezok kotelezoseget manualisan is igazolni kell. |
| `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT` | `false` | Ebben a korben aktiv migracios `true` nem lett bizonyitva. | `TransactionService.highValueApprovalBlockReason`; 10M+/fokozott AML threshold vezetoi jovahagyas nelkul WARN-only vagy blokk. | `TransactionServiceHighValueApprovalTest` | Bekapcsolas uzleti/jogi dontes: a POS-on explicit supervisor/manager/admin jovahagyasi flow szukseges. |
| `AML_FATF_TIER_ENFORCEMENT` | `false` | Ebben a korben aktiv migracios `true` nem lett bizonyitva. | `AmlService.checkTransaction`; FATF tier mindig besorolodik, enforce=true eseten 1/a, 1/b/2 utak jovahagyas-kotelesek lehetnek. | `AmlServiceTest` FATF tesztek | Jogszabalyi go-live dontes kell: mely tiernel hard block, melynel felelos vezetoi jovahagyas. |
| `CIRCULAR_ACK_BLOCKING_ENFORCEMENT` | `false` | `V289__circular_requires_acknowledgment.sql` oszlopot ad, komment szerint production-biztos default false. | `TransactionService.circularAckBlockReason`, `TransactionOperationHelper.performAmlCheck`; olvasatlan kotelezo korlevel tranzakcio elott blokkolhat. | `CircularAckGateTest` | Bekapcsolashoz operacios dontes kell, mert bejelentkezes/tranzakcio folyamatot blokkolhat. |

## Helyi bizonyito parancs

```powershell
npm run compliance:flags:test
```

2026-06-09-en a parancs celja a fenti flag-logikak gyors regresszios futtatasa.
Ez nem helyettesiti az eles adatbazis parameter-ellenorzest, a jogi go-live dontest
vagy a manualis POS acceptance-et.

## Product Ready maradek

- Eles/staging `system_parameter` tabla tenyleges ertekeinek exportja.
- Ugyfel altal jovahagyott enforcement politika: hard block, warn-only vagy vezeto altali explicit jovahagyas.
- Penztaros UX smoke minden bekapcsolt flagre.
- Audit log bizonyitek minden blokkrol es minden vezetoi jovahagyasrol.
