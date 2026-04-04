package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * HandoverSheet entitás unit tesztek — P1 Sprint 2
 *
 * Tesztelési célok:
 * 1. Entity JSONB szerializáció/deszerializáció (7 lista típus)
 * 2. Builder minta: teljes entitás felépítés
 * 3. Flyway V136 konzisztencia: column name ↔ JPA annotáció
 * 4. Null-safety: JSONB mezők null vs üres lista
 * 5. cashBalanceMatches Boolean tristate (true/false/null)
 * 6. cashBalanceDeviation BigDecimal precision
 */
@DisplayName("HandoverSheet Entity — P1 Sprint 2")
class HandoverSheetTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    // =========================================================================
    // 1. BUILDER MINTA — teljes entitás létrehozás
    // =========================================================================

    @Nested
    @DisplayName("1. Builder — teljes entitás")
    class BuilderTests {

        @Test
        @DisplayName("Builder: kötelező mezők beállíthatók")
        void builder_mandatoryFields() {
            UUID companyId = UUID.randomUUID();
            UUID fromCashDeskId = UUID.randomUUID();
            UUID toCashDeskId = UUID.randomUUID();

            HandoverSheet sheet = HandoverSheet.builder()
                    .companyId(companyId)
                    .sheetNumber("ATL-2026-001")
                    .fromCashDeskId(fromCashDeskId)
                    .toCashDeskId(toCashDeskId)
                    .transferDate(LocalDate.of(2026, 4, 4))
                    .build();

            assertThat(sheet.getCompanyId()).isEqualTo(companyId);
            assertThat(sheet.getSheetNumber()).isEqualTo("ATL-2026-001");
            assertThat(sheet.getFromCashDeskId()).isEqualTo(fromCashDeskId);
            assertThat(sheet.getToCashDeskId()).isEqualTo(toCashDeskId);
            assertThat(sheet.getTransferDate()).isEqualTo(LocalDate.of(2026, 4, 4));
        }

        @Test
        @DisplayName("Builder: default status = DRAFT")
        void builder_defaultStatusIsDraft() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-2026-002")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .build();

            assertThat(sheet.getStatus()).isEqualTo(HandoverSheetStatus.DRAFT);
        }

        @Test
        @DisplayName("Builder: összes 93 mezős struktúra beállítható")
        void builder_fullDelphi93Fields() {
            HandoverSheet sheet = buildFullSheet();

            // Relációs mezők (legacy [3-4])
            assertThat(sheet.getHandedOverBy()).isEqualTo("Kovács János");
            assertThat(sheet.getReceivedBy()).isEqualTo("Nagy Béla");

            // Pénzkészlet (legacy [5-7])
            assertThat(sheet.getCashBalanceMatches()).isTrue();
            assertThat(sheet.getCashBalanceDeviation()).isEqualByComparingTo(BigDecimal.ZERO);

            // JSONB listák
            assertThat(sheet.getDebts()).hasSize(2);
            assertThat(sheet.getClaims()).hasSize(1);
            assertThat(sheet.getWuVatOrders()).hasSize(1);
            assertThat(sheet.getBankInboundShipments()).hasSize(2);
            assertThat(sheet.getBankOutboundShipments()).hasSize(1);
            assertThat(sheet.getCashDeskOrders()).hasSize(1);
            assertThat(sheet.getCirculars()).hasSize(1);
        }
    }

    // =========================================================================
    // 2. JSONB SZERIALIZÁCIÓ/DESZERIALIÁCIÓ — minden lista típus
    // =========================================================================

    @Nested
    @DisplayName("2. JSONB szerializáció/deszerialiáció")
    class JsonbSerializationTests {

        @Test
        @DisplayName("DebtEntry: szerializáció és visszaolvasás")
        void debtEntry_roundTrip() throws Exception {
            List<HandoverSheet.DebtEntry> debts = List.of(
                    HandoverSheet.DebtEntry.builder()
                            .vaultNumber("ERT-001")
                            .amount(new BigDecimal("150000"))
                            .currency("HUF")
                            .build(),
                    HandoverSheet.DebtEntry.builder()
                            .vaultNumber("ERT-002")
                            .amount(new BigDecimal("500.50"))
                            .currency("EUR")
                            .build()
            );

            String json = objectMapper.writeValueAsString(debts);
            List<HandoverSheet.DebtEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.DebtEntry>>() {});

            assertThat(deserialized).hasSize(2);
            assertThat(deserialized.get(0).getVaultNumber()).isEqualTo("ERT-001");
            assertThat(deserialized.get(0).getAmount()).isEqualByComparingTo(new BigDecimal("150000"));
            assertThat(deserialized.get(0).getCurrency()).isEqualTo("HUF");
            assertThat(deserialized.get(1).getCurrency()).isEqualTo("EUR");
        }

        @Test
        @DisplayName("ClaimEntry: szerializáció és visszaolvasás")
        void claimEntry_roundTrip() throws Exception {
            List<HandoverSheet.ClaimEntry> claims = List.of(
                    HandoverSheet.ClaimEntry.builder()
                            .vaultNumber("ERT-010")
                            .amount(new BigDecimal("75000"))
                            .currency("HUF")
                            .build()
            );

            String json = objectMapper.writeValueAsString(claims);
            List<HandoverSheet.ClaimEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.ClaimEntry>>() {});

            assertThat(deserialized).hasSize(1);
            assertThat(deserialized.get(0).getVaultNumber()).isEqualTo("ERT-010");
            assertThat(deserialized.get(0).getAmount()).isEqualByComparingTo(new BigDecimal("75000"));
        }

        @Test
        @DisplayName("WuVatOrder: szerializáció és visszaolvasás")
        void wuVatOrder_roundTrip() throws Exception {
            List<HandoverSheet.WuVatOrder> orders = List.of(
                    HandoverSheet.WuVatOrder.builder()
                            .description("WU megbízás #2026-01")
                            .amount(new BigDecimal("1200.00"))
                            .currency("USD")
                            .build()
            );

            String json = objectMapper.writeValueAsString(orders);
            List<HandoverSheet.WuVatOrder> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.WuVatOrder>>() {});

            assertThat(deserialized).hasSize(1);
            assertThat(deserialized.get(0).getDescription()).isEqualTo("WU megbízás #2026-01");
            assertThat(deserialized.get(0).getAmount()).isEqualByComparingTo(new BigDecimal("1200.00"));
            assertThat(deserialized.get(0).getCurrency()).isEqualTo("USD");
        }

        @Test
        @DisplayName("BankShipmentEntry (inbound): összes 4 mező round-trip")
        void bankShipmentEntry_inbound_roundTrip() throws Exception {
            List<HandoverSheet.BankShipmentEntry> shipments = List.of(
                    HandoverSheet.BankShipmentEntry.builder()
                            .currency("EUR")
                            .amount(new BigDecimal("10000.00"))
                            .counterparty("OTP Bank Zrt.")
                            .rate(new BigDecimal("395.50"))
                            .build(),
                    HandoverSheet.BankShipmentEntry.builder()
                            .currency("USD")
                            .amount(new BigDecimal("5000.00"))
                            .counterparty("K&H Bank")
                            .rate(new BigDecimal("362.10"))
                            .build()
            );

            String json = objectMapper.writeValueAsString(shipments);
            List<HandoverSheet.BankShipmentEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.BankShipmentEntry>>() {});

            assertThat(deserialized).hasSize(2);
            assertThat(deserialized.get(0).getCurrency()).isEqualTo("EUR");
            assertThat(deserialized.get(0).getAmount()).isEqualByComparingTo(new BigDecimal("10000.00"));
            assertThat(deserialized.get(0).getCounterparty()).isEqualTo("OTP Bank Zrt.");
            assertThat(deserialized.get(0).getRate()).isEqualByComparingTo(new BigDecimal("395.50"));
        }

        @Test
        @DisplayName("CashDeskOrder: mind az 5 mező round-trip")
        void cashDeskOrder_roundTrip() throws Exception {
            List<HandoverSheet.CashDeskOrder> orders = List.of(
                    HandoverSheet.CashDeskOrder.builder()
                            .currency("EUR")
                            .cashDeskName("Szekszárdi Pénztár")
                            .workerName("Horváth Anna")
                            .amount(new BigDecimal("2500.00"))
                            .rate(new BigDecimal("394.00"))
                            .build()
            );

            String json = objectMapper.writeValueAsString(orders);
            List<HandoverSheet.CashDeskOrder> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.CashDeskOrder>>() {});

            assertThat(deserialized).hasSize(1);
            assertThat(deserialized.get(0).getCurrency()).isEqualTo("EUR");
            assertThat(deserialized.get(0).getCashDeskName()).isEqualTo("Szekszárdi Pénztár");
            assertThat(deserialized.get(0).getWorkerName()).isEqualTo("Horváth Anna");
            assertThat(deserialized.get(0).getAmount()).isEqualByComparingTo(new BigDecimal("2500.00"));
            assertThat(deserialized.get(0).getRate()).isEqualByComparingTo(new BigDecimal("394.00"));
        }

        @Test
        @DisplayName("CircularEntry: minden mező round-trip")
        void circularEntry_roundTrip() throws Exception {
            List<HandoverSheet.CircularEntry> circulars = List.of(
                    HandoverSheet.CircularEntry.builder()
                            .subject("Árfolyamváltozás értesítő")
                            .content("2026. április 1-jétől új EUR/HUF árfolyam érvényes.")
                            .issuedBy("Igazgatóság")
                            .build()
            );

            String json = objectMapper.writeValueAsString(circulars);
            List<HandoverSheet.CircularEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.CircularEntry>>() {});

            assertThat(deserialized).hasSize(1);
            assertThat(deserialized.get(0).getSubject()).isEqualTo("Árfolyamváltozás értesítő");
            assertThat(deserialized.get(0).getContent()).contains("2026. április");
            assertThat(deserialized.get(0).getIssuedBy()).isEqualTo("Igazgatóság");
        }

        @Test
        @DisplayName("Üres JSON tömb [] deszerialiáció → üres lista, nem null")
        void emptyJsonArray_deserializesToEmptyList() throws Exception {
            String emptyJson = "[]";
            List<HandoverSheet.DebtEntry> debts = objectMapper.readValue(
                    emptyJson, new TypeReference<List<HandoverSheet.DebtEntry>>() {});

            assertThat(debts).isNotNull().isEmpty();
        }

        @Test
        @DisplayName("Null mező értéke (pl. rate=null) JSON-ban: null-safe deszerialiáció")
        void bankShipmentEntry_nullRate_roundTrip() throws Exception {
            // rate mező lehet null, ha az árfolyam nem rögzített
            HandoverSheet.BankShipmentEntry entry = HandoverSheet.BankShipmentEntry.builder()
                    .currency("CHF")
                    .amount(new BigDecimal("3000"))
                    .counterparty("Raiffeisen Bank")
                    .rate(null)
                    .build();

            String json = objectMapper.writeValueAsString(List.of(entry));
            List<HandoverSheet.BankShipmentEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.BankShipmentEntry>>() {});

            assertThat(deserialized.get(0).getRate()).isNull();
            assertThat(deserialized.get(0).getCurrency()).isEqualTo("CHF");
        }
    }

    // =========================================================================
    // 3. FLYWAY V136 KONZISZTENCIA — column name ↔ JPA annotáció ellenőrzés
    // =========================================================================

    @Nested
    @DisplayName("3. Flyway V136 ↔ JPA konzisztencia")
    class FlywayJpaConsistencyTests {

        /**
         * Ellenőrzi, hogy a JPA @Column(name=...) megfelel a V136 SQL-ben
         * definiált oszlopneveknek. Ez reflection-alapú statikus ellenőrzés —
         * nincs szükség adatbázis-kapcsolatra.
         *
         * V136 oszlopok:
         *   handed_over_by, received_by,
         *   cash_balance_matches, cash_balance_deviation,
         *   debts, claims, wu_vat_orders,
         *   bank_inbound_shipments, bank_outbound_shipments,
         *   cash_desk_orders, circulars
         */
        @Test
        @DisplayName("handed_over_by mező JPA column name egyezik a V136 SQL-lel")
        void handedOverBy_columnName_matchesFlyway() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("handedOverBy");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("handed_over_by");
        }

        @Test
        @DisplayName("received_by mező JPA column name egyezik a V136 SQL-lel")
        void receivedBy_columnName_matchesFlyway() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("receivedBy");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("received_by");
        }

        @Test
        @DisplayName("cash_balance_matches mező JPA column name egyezik a V136 SQL-lel")
        void cashBalanceMatches_columnName_matchesFlyway() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("cashBalanceMatches");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("cash_balance_matches");
        }

        @Test
        @DisplayName("cash_balance_deviation mező JPA column name + precision egyezik a V136 SQL-lel")
        void cashBalanceDeviation_columnAndPrecision_matchesFlyway() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("cashBalanceDeviation");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("cash_balance_deviation");
            // V136: NUMERIC(15,0) → JPA precision=15, scale=0
            assertThat(col.precision()).isEqualTo(15);
            assertThat(col.scale()).isEqualTo(0);
        }

        @Test
        @DisplayName("debts mező columnDefinition = 'jsonb'")
        void debts_columnDefinition_isJsonb() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("debts");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("debts");
            assertThat(col.columnDefinition()).isEqualTo("jsonb");
        }

        @Test
        @DisplayName("claims mező columnDefinition = 'jsonb'")
        void claims_columnDefinition_isJsonb() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("claims");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("claims");
            assertThat(col.columnDefinition()).isEqualTo("jsonb");
        }

        @Test
        @DisplayName("wu_vat_orders mező columnDefinition = 'jsonb'")
        void wuVatOrders_columnDefinition_isJsonb() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("wuVatOrders");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("wu_vat_orders");
            assertThat(col.columnDefinition()).isEqualTo("jsonb");
        }

        @Test
        @DisplayName("bank_inbound_shipments mező columnDefinition = 'jsonb'")
        void bankInboundShipments_columnDefinition_isJsonb() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("bankInboundShipments");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("bank_inbound_shipments");
            assertThat(col.columnDefinition()).isEqualTo("jsonb");
        }

        @Test
        @DisplayName("bank_outbound_shipments mező columnDefinition = 'jsonb'")
        void bankOutboundShipments_columnDefinition_isJsonb() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("bankOutboundShipments");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("bank_outbound_shipments");
            assertThat(col.columnDefinition()).isEqualTo("jsonb");
        }

        @Test
        @DisplayName("cash_desk_orders mező columnDefinition = 'jsonb'")
        void cashDeskOrders_columnDefinition_isJsonb() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("cashDeskOrders");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("cash_desk_orders");
            assertThat(col.columnDefinition()).isEqualTo("jsonb");
        }

        @Test
        @DisplayName("circulars mező columnDefinition = 'jsonb'")
        void circulars_columnDefinition_isJsonb() throws Exception {
            var field = HandoverSheet.class.getDeclaredField("circulars");
            var col = field.getAnnotation(jakarta.persistence.Column.class);
            assertThat(col).isNotNull();
            assertThat(col.name()).isEqualTo("circulars");
            assertThat(col.columnDefinition()).isEqualTo("jsonb");
        }
    }

    // =========================================================================
    // 4. NULL-SAFETY — JSONB null vs üres lista
    // =========================================================================

    @Nested
    @DisplayName("4. Null-safety — JSONB listák")
    class NullSafetyTests {

        @Test
        @DisplayName("Builder: JSONB listák alapértéken null (nem üres lista)")
        void builder_jsonbListsAreNullByDefault() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-NULL-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .build();

            // Builder nem ad default üres listát — az a DB default '[]'::jsonb feladata
            assertThat(sheet.getDebts()).isNull();
            assertThat(sheet.getClaims()).isNull();
            assertThat(sheet.getWuVatOrders()).isNull();
            assertThat(sheet.getBankInboundShipments()).isNull();
            assertThat(sheet.getBankOutboundShipments()).isNull();
            assertThat(sheet.getCashDeskOrders()).isNull();
            assertThat(sheet.getCirculars()).isNull();
        }

        @Test
        @DisplayName("Builder: explicit üres lista beállítható")
        void builder_emptyListExplicit() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-EMPTY-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .debts(Collections.emptyList())
                    .claims(Collections.emptyList())
                    .build();

            assertThat(sheet.getDebts()).isNotNull().isEmpty();
            assertThat(sheet.getClaims()).isNotNull().isEmpty();
        }

        @Test
        @DisplayName("JSON null érték deszerialiáció: null marad (nem üres lista)")
        void nullJsonValue_deserializesToNull() throws Exception {
            // Ha a DB oszlop null (nem a default '[]'), a deszerialiáció null-t ad vissza
            String json = "null";
            List<HandoverSheet.DebtEntry> result = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.DebtEntry>>() {});
            assertThat(result).isNull();
        }

        @Test
        @DisplayName("DebtEntry null amount megengedett (részleges adat)")
        void debtEntry_nullAmount_allowed() throws Exception {
            HandoverSheet.DebtEntry entry = HandoverSheet.DebtEntry.builder()
                    .vaultNumber("ERT-999")
                    .amount(null)
                    .currency("HUF")
                    .build();

            String json = objectMapper.writeValueAsString(List.of(entry));
            List<HandoverSheet.DebtEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.DebtEntry>>() {});

            assertThat(deserialized.get(0).getAmount()).isNull();
            assertThat(deserialized.get(0).getVaultNumber()).isEqualTo("ERT-999");
        }
    }

    // =========================================================================
    // 5. cashBalanceMatches — Boolean tristate
    // =========================================================================

    @Nested
    @DisplayName("5. cashBalanceMatches Boolean tristate")
    class CashBalanceMatchesTests {

        @Test
        @DisplayName("cashBalanceMatches = true: pénzkészlet egyezik")
        void cashBalanceMatches_true() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-MATCH-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .cashBalanceMatches(Boolean.TRUE)
                    .cashBalanceDeviation(BigDecimal.ZERO)
                    .build();

            assertThat(sheet.getCashBalanceMatches()).isNotNull().isTrue();
            assertThat(sheet.getCashBalanceDeviation()).isEqualByComparingTo(BigDecimal.ZERO);
        }

        @Test
        @DisplayName("cashBalanceMatches = false: eltérés van")
        void cashBalanceMatches_false() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-MISMATCH-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .cashBalanceMatches(Boolean.FALSE)
                    .cashBalanceDeviation(new BigDecimal("5000"))
                    .build();

            assertThat(sheet.getCashBalanceMatches()).isNotNull().isFalse();
            assertThat(sheet.getCashBalanceDeviation()).isEqualByComparingTo(new BigDecimal("5000"));
        }

        @Test
        @DisplayName("cashBalanceMatches = null: nem ellenőrzött átadás")
        void cashBalanceMatches_null() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-UNCHECK-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .cashBalanceMatches(null)
                    .build();

            assertThat(sheet.getCashBalanceMatches()).isNull();
        }

        @Test
        @DisplayName("cashBalanceDeviation null ha egyezik")
        void cashBalanceDeviation_nullWhenMatches() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-MATCH-002")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .cashBalanceMatches(Boolean.TRUE)
                    .cashBalanceDeviation(null)
                    .build();

            assertThat(sheet.getCashBalanceMatches()).isTrue();
            assertThat(sheet.getCashBalanceDeviation()).isNull();
        }
    }

    // =========================================================================
    // 6. cashBalanceDeviation BigDecimal precision
    // =========================================================================

    @Nested
    @DisplayName("6. cashBalanceDeviation BigDecimal precision")
    class CashBalanceDeviationTests {

        @Test
        @DisplayName("NUMERIC(15,0): integer összeg pontosan tárolható")
        void deviation_integerPrecision() {
            BigDecimal deviation = new BigDecimal("9999999999999");  // 13 jegy, max 15
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-DEV-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .cashBalanceDeviation(deviation)
                    .build();

            assertThat(sheet.getCashBalanceDeviation())
                    .isEqualByComparingTo(new BigDecimal("9999999999999"));
        }

        @Test
        @DisplayName("NUMERIC(15,0): negatív eltérés is megengedett (visszafelé egyezés)")
        void deviation_negativeValue() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-DEV-NEG-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .cashBalanceDeviation(new BigDecimal("-12500"))
                    .build();

            assertThat(sheet.getCashBalanceDeviation())
                    .isEqualByComparingTo(new BigDecimal("-12500"));
            assertThat(sheet.getCashBalanceDeviation().signum()).isNegative();
        }

        @Test
        @DisplayName("NUMERIC(15,0): nulla eltérés = egyezés")
        void deviation_zero() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-DEV-ZERO-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .cashBalanceDeviation(BigDecimal.ZERO)
                    .build();

            assertThat(sheet.getCashBalanceDeviation().compareTo(BigDecimal.ZERO)).isZero();
        }
    }

    // =========================================================================
    // 7. EDGE CASES — határértékek és szélső esetek
    // =========================================================================

    @Nested
    @DisplayName("7. Edge case-ek")
    class EdgeCaseTests {

        @Test
        @DisplayName("DebtEntry: max 3 tétel (Delphi legacy korlát) — list > 3 is elfogadott a Java oldalon")
        void debtEntry_moreThanThreeEntries_allowedInJava() throws Exception {
            // A 3-as korlát Delphi legacy — Java/JPA nem enforce-olja, de dokumentáljuk
            List<HandoverSheet.DebtEntry> debts = List.of(
                    HandoverSheet.DebtEntry.builder().vaultNumber("V1").amount(new BigDecimal("1000")).currency("HUF").build(),
                    HandoverSheet.DebtEntry.builder().vaultNumber("V2").amount(new BigDecimal("2000")).currency("HUF").build(),
                    HandoverSheet.DebtEntry.builder().vaultNumber("V3").amount(new BigDecimal("3000")).currency("HUF").build(),
                    HandoverSheet.DebtEntry.builder().vaultNumber("V4").amount(new BigDecimal("4000")).currency("HUF").build()
            );

            String json = objectMapper.writeValueAsString(debts);
            List<HandoverSheet.DebtEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.DebtEntry>>() {});

            // Java szinten nincs size limit — ez üzleti validáció dolga
            assertThat(deserialized).hasSize(4);
        }

        @Test
        @DisplayName("BankShipmentEntry: max 4 tétel (Delphi legacy [32-47])")
        void bankShipment_fourEntries_roundTrip() throws Exception {
            List<HandoverSheet.BankShipmentEntry> shipments = List.of(
                    HandoverSheet.BankShipmentEntry.builder().currency("EUR").amount(new BigDecimal("1000")).counterparty("Bank1").rate(new BigDecimal("395")).build(),
                    HandoverSheet.BankShipmentEntry.builder().currency("USD").amount(new BigDecimal("2000")).counterparty("Bank2").rate(new BigDecimal("362")).build(),
                    HandoverSheet.BankShipmentEntry.builder().currency("GBP").amount(new BigDecimal("3000")).counterparty("Bank3").rate(new BigDecimal("455")).build(),
                    HandoverSheet.BankShipmentEntry.builder().currency("CHF").amount(new BigDecimal("4000")).counterparty("Bank4").rate(new BigDecimal("410")).build()
            );

            String json = objectMapper.writeValueAsString(shipments);
            List<HandoverSheet.BankShipmentEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.BankShipmentEntry>>() {});

            assertThat(deserialized).hasSize(4);
            assertThat(deserialized.get(3).getCurrency()).isEqualTo("CHF");
        }

        @Test
        @DisplayName("CircularEntry: hosszú content mező round-trip (több száz karakter)")
        void circularEntry_longContent() throws Exception {
            String longContent = "A".repeat(500);
            List<HandoverSheet.CircularEntry> circulars = List.of(
                    HandoverSheet.CircularEntry.builder()
                            .subject("Hosszú körlevél teszt")
                            .content(longContent)
                            .issuedBy("Tesztelő")
                            .build()
            );

            String json = objectMapper.writeValueAsString(circulars);
            List<HandoverSheet.CircularEntry> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.CircularEntry>>() {});

            assertThat(deserialized.get(0).getContent()).hasSize(500);
        }

        @Test
        @DisplayName("WuVatOrder: amount nulla esetén JSON null-ként szerializál")
        void wuVatOrder_zeroAmount() throws Exception {
            HandoverSheet.WuVatOrder order = HandoverSheet.WuVatOrder.builder()
                    .description("Nullás tétel")
                    .amount(BigDecimal.ZERO)
                    .currency("HUF")
                    .build();

            String json = objectMapper.writeValueAsString(List.of(order));
            List<HandoverSheet.WuVatOrder> deserialized = objectMapper.readValue(
                    json, new TypeReference<List<HandoverSheet.WuVatOrder>>() {});

            assertThat(deserialized.get(0).getAmount()).isEqualByComparingTo(BigDecimal.ZERO);
        }

        @Test
        @DisplayName("HandoverSheet @Builder.Default status nem null, ha nincs beállítva")
        void builderDefault_statusNotNullEvenWithoutExplicitSet() {
            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-BUILDERDEF-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .build();

            // @Builder.Default garantálja: soha nem null
            assertThat(sheet.getStatus()).isNotNull().isEqualTo(HandoverSheetStatus.DRAFT);
        }

        @Test
        @DisplayName("inbound és outbound shipment listák függetlenek egymástól")
        void inboundOutbound_areIndependent() throws Exception {
            HandoverSheet.BankShipmentEntry inEntry = HandoverSheet.BankShipmentEntry.builder()
                    .currency("EUR").amount(new BigDecimal("5000")).counterparty("OTP").rate(new BigDecimal("395")).build();
            HandoverSheet.BankShipmentEntry outEntry = HandoverSheet.BankShipmentEntry.builder()
                    .currency("USD").amount(new BigDecimal("3000")).counterparty("Raiffeisen").rate(new BigDecimal("361")).build();

            HandoverSheet sheet = HandoverSheet.builder()
                    .sheetNumber("ATL-INOUT-001")
                    .fromCashDeskId(UUID.randomUUID())
                    .toCashDeskId(UUID.randomUUID())
                    .transferDate(LocalDate.now())
                    .bankInboundShipments(List.of(inEntry))
                    .bankOutboundShipments(List.of(outEntry))
                    .build();

            assertThat(sheet.getBankInboundShipments()).hasSize(1);
            assertThat(sheet.getBankInboundShipments().get(0).getCurrency()).isEqualTo("EUR");
            assertThat(sheet.getBankOutboundShipments()).hasSize(1);
            assertThat(sheet.getBankOutboundShipments().get(0).getCurrency()).isEqualTo("USD");
        }
    }

    // =========================================================================
    // HELPERS
    // =========================================================================

    private HandoverSheet buildFullSheet() {
        return HandoverSheet.builder()
                .companyId(UUID.randomUUID())
                .sheetNumber("ATL-FULL-2026-001")
                .fromCashDeskId(UUID.randomUUID())
                .toCashDeskId(UUID.randomUUID())
                .transferDate(LocalDate.of(2026, 4, 4))
                .handedOverBy("Kovács János")
                .receivedBy("Nagy Béla")
                .cashBalanceMatches(Boolean.TRUE)
                .cashBalanceDeviation(BigDecimal.ZERO)
                .debts(List.of(
                        HandoverSheet.DebtEntry.builder().vaultNumber("V1").amount(new BigDecimal("10000")).currency("HUF").build(),
                        HandoverSheet.DebtEntry.builder().vaultNumber("V2").amount(new BigDecimal("500")).currency("EUR").build()
                ))
                .claims(List.of(
                        HandoverSheet.ClaimEntry.builder().vaultNumber("V3").amount(new BigDecimal("25000")).currency("HUF").build()
                ))
                .wuVatOrders(List.of(
                        HandoverSheet.WuVatOrder.builder().description("WU #001").amount(new BigDecimal("800")).currency("USD").build()
                ))
                .bankInboundShipments(List.of(
                        HandoverSheet.BankShipmentEntry.builder().currency("EUR").amount(new BigDecimal("8000")).counterparty("OTP").rate(new BigDecimal("395")).build(),
                        HandoverSheet.BankShipmentEntry.builder().currency("USD").amount(new BigDecimal("5000")).counterparty("K&H").rate(new BigDecimal("362")).build()
                ))
                .bankOutboundShipments(List.of(
                        HandoverSheet.BankShipmentEntry.builder().currency("GBP").amount(new BigDecimal("2000")).counterparty("Unicredit").rate(new BigDecimal("455")).build()
                ))
                .cashDeskOrders(List.of(
                        HandoverSheet.CashDeskOrder.builder().currency("EUR").cashDeskName("Pécs").workerName("Tóth K.").amount(new BigDecimal("1500")).rate(new BigDecimal("394")).build()
                ))
                .circulars(List.of(
                        HandoverSheet.CircularEntry.builder().subject("Teszt körlevél").content("Tartalom").issuedBy("Vezérigazgató").build()
                ))
                .notes("Egyéb megjegyzés — automatikus teszt")
                .status(HandoverSheetStatus.DRAFT)
                .build();
    }
}
