# API Áttekintés — Valutaváltó Program v2.0

> 106 controller | 400+ REST endpoint | JWT autentikáció  
> Base URL: `/api/v1`

---

## Autentikáció & Felhasználókezelés
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/auth` | AuthController | Login, logout, token refresh |
| `/users` | UserController | Felhasználó CRUD |
| `/workers` | WorkerController | Pénztáros kezelés (self: /me) |
| `/workers` | WorkerManagementController | Pénztáros admin (SUPERVISOR+) |
| `/roles` | RoleController | Szerepkör kezelés |
| `/permissions` | PermissionController | Jogosultság kezelés |

## Cég & Szervezet
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/admin` | CompanyAdminController | Cég adminisztráció |
| `/own-companies` | OwnCompanyController | Saját cég adatok |
| `/organizations` | OrganizationController | Szervezeti egységek |
| `/organizational-system-parameters` | OrganizationalSystemParameterController | Szervezeti paraméterek |

## Fiók (Branch) Kezelés
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/branches/**` | (SecurityConfig) | Fiók CRUD (authenticated) |
| `/branch-groups` | BranchGroupController | Fiókcsoportok |
| `/monitoring` | BranchMonitoringController | Fiók monitoring |
| `/workstations` | WorkstationController | Munkaállomások |

## Tranzakciók & Pénztár
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/transactions` | TransactionController | Tranzakció CRUD |
| `/receipts` | ReceiptController | Bizonylat generálás |
| `/receipts` | ReceiptSearchController | Bizonylat keresés |
| `/stornos` | StornoController | Sztornó kezelés |
| `/cash-balances` | CashBalanceController | Pénztár egyenleg |
| `/denominations` | DenominationController | Címlet kezelés |
| `/cash-desks` | DenominationBalanceController | Pénztárfiók egyenleg |
| `/handling-fees` | HandlingFeeController | Kezelési díjak |
| `/reservations` | ReservationController | Foglalások |
| `/sessions` | SessionOpenController | Napi nyitás |
| `/daily-sessions` | DailySessionController | Napi munkamenet |

## Árfolyam & Kalkulátor
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/exchange-rates` | ExchangeRateController | Árfolyam CRUD |
| `/calculator` | CurrencyCalculatorController | Deviza kalkulátor |
| `/rate-creation` | RateCreationController | Árfolyam létrehozás |
| `/rate-approvals` | RateApprovalController | Árfolyam jóváhagyás |
| `/rate-categories` | RateCategoryController | Árfolyam kategóriák |
| `/rate-history` | RateHistoryController | Árfolyam történet |
| `/rates/polling` | ExchangeRatePollingController | Árfolyam polling |
| `/exchange-rate-display` | ExchangeRateDisplayController | Kijelző árfolyam |
| `/currencies` | CurrencyController | Valuták |
| `/currency-groups` | CurrencyGroupController | Valutacsoportok |
| `/rounding-rules` | RoundingRuleController | Kerekítési szabályok |
| `/competitors` | CompetitorController | Versenytárs árfolyamok |

## AML & Compliance
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/aml` | AmlController | AML ellenőrzés & jelentés |
| `/customers` | CustomerController | Ügyfél kezelés |
| `/authorized-representatives` | AuthorizedRepresentativeController | Meghatalmazottak |
| `/sanctions` | SanctionScreeningController | Szankciós lista |
| `/blacklist` | BlacklistController | Tiltólista |
| `/anonymous-reports` | AnonymousReportController | Anonim bejelentések |
| `/police/requests` | PoliceRequestController | Rendőrségi megkeresések |

## Jelentések & Export
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/reports` | ReportController | Általános jelentések |
| `/reports/daily` | DailyReportController | Napi jelentés |
| `/reports-extended` | ReportExtendedController | Kibővített riportok |
| `/central-reports` | CentralReportController | Központi jelentések |
| `/decade-reports` | DecadeReportController | Dekád jelentések |
| `/mnb/reports` | MnbReportController | MNB jelentés (XML) |
| `/nav-reports` | NavReportController | NAV jelentés |
| `/nav/closings` | NavClosingController | NAV zárás |
| `/nav-integration` | NavIntegrationController | NAV integráció |
| `/booking` | BookingExportController | Könyvelési export |
| `/turnover` | TurnoverController | Forgalom |
| `/profit` | ProfitController | Profit kalkuláció |

## Záró Folyamatok
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/closing-wizard` | ClosingWizardController | 5 lépéses záró wizard |
| `/closing/monthly` | MonthlyClosingController | Havi zárás |
| `/handover-sheets` | HandoverSheetController | Átadó-átvevő lap |

## Trade & Szállítás
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/trades` | TradeController | Irodák közti deviza trade |
| `/transfers` | TransferController | Átutalások |
| `/shipments` | ShipmentController | Szállítmányok |
| `/treasury` | TreasuryController | Értéktár |
| `/inventory` | InventoryController | Készlet kezelés |
| `/inventory` | InventoryMovementController | Készlet mozgás |
| `/inventory/regeneration` | InventoryRegenerationController | Készlet újraszámítás |
| `/packaging` | PackagingController | Csomagolás |

## Jutalék & Verseny
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/commissions` | CommissionCalculationController | Jutalék számítás |
| `/commission-rates` | CommissionRateController | Jutalék díjszabás |
| `/worker-commissions` | WorkerCommissionController | Pénztáros jutalékok |
| `/competitions` | CompetitionController | Versenyek |
| `/contributions` | ContributionController | Hozzájárulások |

## Hardver & Integráció
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/cash-register` | CashRegisterController | Pénztárgép (NAV online) |
| `/pos-terminal` | PosTerminalController | POS terminál |
| `/led` | LedDisplayController | LED kijelző |
| `/documents` | DocumentScannerController | Dokumentum szkenner |
| `/documents` | DocumentStorageController | Dokumentum tár |
| `/western-union` | WesternUnionController | Western Union |
| `/stamps` | StampController | Illetékbélyeg |

## Rendszer & Adminisztráció
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/dashboard` | DashboardController | Dashboard összesítő |
| `/system-parameters` | SystemParameterController | Rendszerparaméterek |
| `/system-params` | SystemParameterManagementController | Paraméter kezelés |
| `/config` | ConfigExportController | Konfig export/import |
| `/license` | LicenseController | Licenc kezelés |
| `/print-templates` | PrintTemplateController | Nyomtatási sablonok |
| `/translations` | TranslationController | Fordítások (i18n) |
| `/notifications` | NotificationController | Értesítések |
| `/audit` | AuditLogController | Audit trail |
| `/logs` | LoggingController | Naplózás |
| `/supervisor` | SupervisorController | Supervisor felület |
| `/scheduler` | SchedulerController | Ütemezett feladatok |
| `/health` | HealthController | Health check |

## Szinkronizáció & Backup
| Endpoint | Controller | Leírás |
|----------|-----------|--------|
| `/sync` | SyncController | Szinkronizáció |
| `/synchronization` | SynchronizationController | Szinkronizáció v2 |
| `/ftp-sync` | FtpSyncController | FTP szinkronizáció |
| `/backup` | BackupController | Backup/Restore |
| `/archiving` | ArchivingController | Archiválás |
| `/data-collection` | DataCollectionController | Adatgyűjtés |
| `/data-import` | DataImportController | Adat import |
| `/cash-desk-breaks` | CashDeskBreakController | Pénztáros szünetek |
| `/circulars` | CircularController | Körlevelek |
| `/fees` | FeeController | Díjak |
