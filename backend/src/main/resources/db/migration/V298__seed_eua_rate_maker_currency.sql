-- V298 (FK02-E / FR-3, FR-4): EUA (euró érme) felvétele a currency törzsbe — KIZÁRÓLAG az
-- árfolyamkészítő csoport-árfolyamlapja számára.
--
-- Háttér: az EUA a 0-s lapon (Főlap) eddig is megjelent, mert ott egy frontend-konstans
-- (MainRateSheetPage.DEFAULT_CURRENCIES) sorolja fel. A munkacsoport-lap viszont a backend
-- getRateOverview()-ból tölt, ami az AKTÍV valutákat adja — így EUA nem jelent meg (FR-3 gyökere).
--
-- Stratégia (minimális blast-radius): az EUA `is_active = false`, ezért a pénztár / készlet /
-- címletezés / átadás-átvétel felületek (mind `findByActiveTrue...`-t használnak) ÉRINTETLENEK
-- maradnak. Az árfolyam-overview (RateCreationService.getRateOverview) expliciten beemeli az
-- EUA-t (aktív ∪ EUA), így az árfolyamkészítőn megjelenik és publikálható. Az EUA készletezési /
-- címletezési / átadás-átvételi logikája KÜLÖN kérés (lásd FK02-E §2 OUT, TBD-1).
--
-- MNB szabály: az EUA (euró érme) max 20%-kal térhet el az EUR hivatalos középárfolyamtól
-- (vö. V78__currency_max_deviation_percent.sql, ami eddig no-op UPDATE volt, mert EUA nem létezett).
--
-- A display_order pusztán kozmetikai: az árfolyamlap a frontend MAIN_SHEET_CURRENCY_ORDER szerint
-- rendez (EUA a RUB és TRY közé kerül), függetlenül a DB sorrendtől.
--
-- Idempotens: ismételt futtatáskor sem duplikál; meglévő EUA-nál csak a törzs-attribútumokat
-- igazítja (az is_active-et NEM erőlteti, hogy egy esetleg már aktivált EUA-t ne vegyen ki forgalomból).

INSERT INTO currency (code, name, symbol, decimal_places, is_active, display_order, max_deviation_percent, created_at)
VALUES ('EUA', 'Euró érme', '€', 2, false, 17, 20.00, NOW())
ON CONFLICT (code) DO UPDATE
    SET name = EXCLUDED.name,
        symbol = COALESCE(currency.symbol, EXCLUDED.symbol),
        decimal_places = EXCLUDED.decimal_places,
        max_deviation_percent = EXCLUDED.max_deviation_percent,
        updated_at = NOW();
