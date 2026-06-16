package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.NeonSyncLog;
import hu.puzzleir.valuta.repository.NeonSyncLogRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * Neon DB replikációs szolgáltatás.
 * 5 percenként szinkronizálja a kritikus táblákat a Hetzner VPS-ről a Neon backup DB-be.
 * Két sync-mód:
 *  - Incremental: csak az utolsó sync óta módosult rekordok (updated_at/created_at alapján).
 *  - Teljes-snapshot (FULL_SYNC_TABLES): a tábla teljes tartalmának upsert-elése minden
 *    ciklusban — kis, kritikus tábláknál, ahol nincs megbízható inkrementális idobélyeg.
 * Ha a Neon elérhetetlen → WARNING log, NEM blokkolja a fő működést.
 */
@Service
@ConditionalOnProperty(name = "app.neon-sync.enabled", havingValue = "true")
@Slf4j
public class NeonReplicationService {

    // FONTOS: csak a forras sémában TÉNYLEGESEN létező táblák szerepelhetnek. A korábbi
    // "stock_snapshot" és "denomination_inventory" nevek soha nem léteztek (sem migráció,
    // sem @Table entitás), ezért minden ciklusban BadSqlGrammarException (undefined_table)
    // hibát dobtak, és látszat-lefedettséget keltettek. Eltávolítva (2026-06-14, prod
    // journal-diagnózis). Új tábla felvétele elott ellenorizd, hogy a Neon CÉL DB-ben is
    // létezik-e (az upsert ON CONFLICT (id)-t feltételez, tehát kell 'id' PK).
    // SORREND = FK-függőség: a SZÜLŐK előrébb, a gyerekek hátrébb. A full-sync upsert-ciklusban a
    // gyerekek (pl. transaction_line) a már felvitt szülőkre (transaction) hivatkoznak — így a
    // FK az első teljes cikluson is teljesül (a külső szülők, pl. branch/currency, a Neonon adottak).
    // 2026-06-16: TÖRZS/REFERENCIA-TÁBLÁK a lista ELEJÉN, FK-topológiai sorrendben (szülők előbb).
    // Gyökér-ok: korábban CSAK üzleti táblák szinkronizálódtak, a FK-céljaik (worker, currency, branch,
    // company, ...) NEM → a Neonon elavultak/hiányosak voltak, ezért az üzleti táblák upsertje FK-violationön
    // bukott (pl. transaction.worker_id=271 / cash_balance.currency_id=31 nincs a Neon worker/currency-ben),
    // és az all-or-nothing batch miatt a TELJES tábla elbukott (transaction 36/134). A Neon menedzselt DB-n a
    // `session_replication_role=replica` (FK-kikapcsolás) NEM engedélyezett (permission denied), ezért a
    // helyes FK-SORRENDDEL biztosítjuk az integritást: a törzs-szülők előbb kerülnek a Neonra, mint a rájuk
    // hivatkozó üzleti táblák. (A fullSync soronkénti fallbackje a maradék elszórt FK-lógást is kezeli.)
    private static final List<String> SYNC_TABLES = List.of(
            // — Törzs / referencia (FK-célok) —
            "company",
            "currency",
            "dictionary",
            "denomination",
            "branch",
            "vault_territory",
            "worker",
            "data_collection",
            // — Üzleti táblák (a FK-céljaik a fentiek) —
            "transaction",
            "transaction_line",
            "transaction_banknote",
            "receipt",
            "receipt_sequence",
            "daily_balance",
            "cash_balance",
            "transfer",
            "transfer_lines",
            "transfer_denomination",
            "shipment_request",
            "shipment_request_item",
            "decade_report",
            "decade_report_line",
            "cash_register_event",
            "collected_transaction",
            "vault_bank_transaction",
            "vault_transfer",
            "storno_approval",
            // 2026-06-14: backup-lefedettség bővítés — a korábbi fantom-nevek valós megfelelői.
            "currency_stock",        // élő deviza-készlet (id BIGSERIAL PK); teljes-snapshot
            "denomination_balance"   // címlet-egyenleg (id UUID PK); teljes-snapshot
    );

    // Teljes-snapshottal mentett táblák (a fullSync ág): a teljes tartalmat upsert-eljük minden
    // ciklusban (ON CONFLICT (id) DO UPDATE → a Neon hűen tükrözi a lokálist, felülírva a divergens
    // sorokat is). 2026-06-15 (incidens-tanulság): az inkrementális ág `WHERE updated_at > kurzor`
    // KIHAGYJA a NULL updated_at-ú (sosem módosított) sorokat ÉS a kurzor-eltolódás miatt a
    // historikus állományt → a backup hiányos lett (pl. cash_balance 39/1235, transaction 36/134).
    // Ezért a kritikus üzleti táblák MIND teljes-snapshotra kerülnek: hiánytalan + öngyógyító backup.
    // FELSŐ KORLÁT: MAX_FULL_SYNC_ROWS (50k) felett a fullSync skip+loud log → ha a `transaction` ezt
    // átlépi, vissza kell térni inkrementálisra COALESCE(updated_at, created_at) kurzorral (követő opt.).
    private static final Set<String> FULL_SYNC_TABLES = Set.of(
            // Törzs / referencia (kicsi, nincs megbízható inkrementális idobélyeg → teljes-snapshot).
            "company",
            "currency",
            "dictionary",
            "denomination",
            "branch",
            "vault_territory",
            "worker",
            "data_collection",
            // Üzleti táblák.
            "transaction",
            "transaction_line",
            "transaction_banknote",
            "receipt",
            "receipt_sequence",
            "daily_balance",
            "cash_balance",
            "transfer",
            "transfer_lines",
            "transfer_denomination",
            "shipment_request",
            "shipment_request_item",
            "decade_report",
            "decade_report_line",
            "cash_register_event",
            "collected_transaction",
            "vault_bank_transaction",
            "vault_transfer",
            "storno_approval",
            "currency_stock",
            "denomination_balance"
    );

    // Teljes-snapshot felso korlatja (felette skip + loud log, hogy ne terheljuk a Neont).
    private static final int MAX_FULL_SYNC_ROWS = 50_000;

    private static final int BATCH_SIZE = 500;

    private final JdbcTemplate primaryJdbc;
    private final DataSource neonDataSource;
    private final NeonSyncLogRepository syncLogRepository;

    public NeonReplicationService(
            @Qualifier("primaryJdbcTemplate") JdbcTemplate primaryJdbc,
            @Qualifier("neonDataSource") DataSource neonDataSource,
            NeonSyncLogRepository syncLogRepository) {
        this.primaryJdbc = primaryJdbc;
        this.neonDataSource = neonDataSource;
        this.syncLogRepository = syncLogRepository;
    }

    /**
     * Fő szinkronizációs job — 5 percenként.
     */
    @Scheduled(fixedDelayString = "${app.neon-sync.interval-ms:300000}", initialDelayString = "${app.neon-sync.initial-delay-ms:60000}")
    public void syncToNeon() {
        log.info("Neon szinkronizáció indítása...");
        int totalSynced = 0;

        for (String table : SYNC_TABLES) {
            try {
                int count = syncTable(table);
                totalSynced += count;
                if (count > 0) {
                    log.info("Neon sync [{}]: {} rekord szinkronizálva", table, count);
                }
            } catch (Exception e) {
                log.warn("Neon sync [{}] HIBA (nem blokkoló): {}", table, e.getMessage());
                logSyncResult(table, 0, "FAILED", e.getMessage());
            }
        }

        log.info("Neon szinkronizáció kész: {} rekord összesen", totalSynced);
    }

    /**
     * Egy tábla incremental szinkronizálása.
     */
    int syncTable(String tableName) {
        // Guard: ha a tábla nem létezik a forrás sémában, ne nyers SQL-kivétellel hasaljon
        // el minden ciklusban (BadSqlGrammarException), hanem tiszta, akcionálható log + SKIPPED.
        if (!tableExists(tableName)) {
            log.warn("Neon sync [{}]: a tábla NEM létezik a forrás DB-ben — kihagyva (ellenőrizd a SYNC_TABLES konfigurációt)", tableName);
            logSyncResult(tableName, 0, "SKIPPED_TABLE_MISSING", "Tábla nem létezik a forrás sémában");
            return 0;
        }

        // Explicit teljes-snapshot táblák (nincs megbízható inkrementális idobélyeg).
        if (FULL_SYNC_TABLES.contains(tableName)) {
            return fullSync(tableName);
        }

        LocalDateTime lastSync = getLastSuccessfulSync(tableName);
        String timestampColumn = detectTimestampColumn(tableName);

        if (timestampColumn == null) {
            log.debug("Neon sync [{}]: nincs timestamp oszlop, full sync", tableName);
            return fullSync(tableName);
        }

        LocalDateTime syncStart = LocalDateTime.now();
        LocalDateTime cursor = lastSync;
        int totalSynced = 0;
        int maxIterations = 10; // Safety: max 10 batch iteration (10 * 5000 = 50000 rows)

        for (int iteration = 0; iteration < maxIterations; iteration++) {
            String selectSql = String.format(
                    "SELECT * FROM \"%s\" WHERE \"%s\" > ? ORDER BY \"%s\" ASC LIMIT ?",
                    tableName, timestampColumn, timestampColumn);

            List<Object[]> rows = new ArrayList<>();
            List<String> columnNames = new ArrayList<>();
            final LocalDateTime cursorFinal = cursor;

            primaryJdbc.query(selectSql, ps -> {
                ps.setObject(1, cursorFinal);
                ps.setInt(2, BATCH_SIZE * 10); // max 5000 per batch
            }, rs -> {
                if (columnNames.isEmpty()) {
                    ResultSetMetaData meta = rs.getMetaData();
                    for (int i = 1; i <= meta.getColumnCount(); i++) {
                        columnNames.add(meta.getColumnName(i));
                    }
                }
                Object[] row = new Object[columnNames.size()];
                for (int i = 0; i < columnNames.size(); i++) {
                    row[i] = rs.getObject(i + 1);
                }
                rows.add(row);
            });

            if (rows.isEmpty()) {
                break;
            }

            int synced = upsertToNeon(tableName, columnNames, rows);
            totalSynced += synced;

            // Watermark: advance cursor to the last row's timestamp value
            int tsColIdx = columnNames.indexOf(timestampColumn);
            if (tsColIdx >= 0) {
                Object lastTs = rows.get(rows.size() - 1)[tsColIdx];
                if (lastTs instanceof LocalDateTime ldt) {
                    cursor = ldt;
                } else if (lastTs instanceof java.sql.Timestamp sqlTs) {
                    cursor = sqlTs.toLocalDateTime();
                }
            }

            // If we got fewer rows than the limit, we're done
            if (rows.size() < BATCH_SIZE * 10) {
                break;
            }
        }

        if (totalSynced > 0) {
            logSyncResult(tableName, totalSynced, "SUCCESS", null, syncStart);
        }
        return totalSynced;
    }

    /**
     * Upsert rekordok a Neon DB-be.
     * ON CONFLICT (id) DO UPDATE — feltételezi hogy minden tábla rendelkezik 'id' PK-val.
     */
    private int upsertToNeon(String tableName, List<String> columns, List<Object[]> rows) {
        if (columns.isEmpty() || rows.isEmpty()) {
            return 0;
        }

        String colList = columns.stream()
                .map(c -> "\"" + c + "\"")
                .reduce((a, b) -> a + ", " + b)
                .orElse("");
        String placeholders = columns.stream()
                .map(c -> "?")
                .reduce((a, b) -> a + ", " + b)
                .orElse("");
        String updateSet = columns.stream()
                .filter(c -> !"id".equals(c))
                .map(c -> "\"" + c + "\" = EXCLUDED.\"" + c + "\"")
                .reduce((a, b) -> a + ", " + b)
                .orElse("");

        String upsertSql = String.format(
                "INSERT INTO \"%s\" (%s) VALUES (%s) ON CONFLICT (id) DO UPDATE SET %s",
                tableName, colList, placeholders, updateSet);

        try (Connection conn = neonDataSource.getConnection()) {
            conn.setAutoCommit(false);
            int batched = 0;
            try (PreparedStatement ps = conn.prepareStatement(upsertSql)) {
                for (Object[] row : rows) {
                    for (int i = 0; i < row.length; i++) {
                        ps.setObject(i + 1, row[i]);
                    }
                    ps.addBatch();
                    batched++;
                    if (batched % BATCH_SIZE == 0) {
                        ps.executeBatch();
                    }
                }
                ps.executeBatch();
                conn.commit();
                return rows.size();
            } catch (Exception batchEx) {
                // All-or-nothing batch bukott (tipikusan EGYETLEN soron FK-violation). Visszagörgetünk, és
                // SORONKÉNTI upsertre esünk vissza: a jó sorok átmennek, a FK-lógó/hibás sorok kimaradnak + log.
                // Így egy elszórt hibás sor nem bukja el a TELJES tábla backup-ját (a korábbi 36/134 gyökér-oka).
                conn.rollback();
                log.warn("Neon upsert [{}] batch HIBA, soronkénti fallback: {}", tableName, rootMsg(batchEx));
                return upsertRowByRow(conn, upsertSql, tableName, rows);
            }
        } catch (Exception e) {
            log.warn("Neon upsert [{}] HIBA (kapcsolat): {}", tableName, rootMsg(e));
            throw new RuntimeException("Neon upsert failed for " + tableName, e);
        }
    }

    /**
     * Soronkénti upsert-fallback: minden sor külön tranzakcióban; a FK/constraint-hibás sorok
     * kimaradnak (log), a jók átmennek. A {@code conn} autoCommit=false állapotban érkezik.
     * Visszaadja a SIKERESEN upsertelt sorok számát.
     */
    private int upsertRowByRow(Connection conn, String upsertSql, String tableName, List<Object[]> rows) throws java.sql.SQLException {
        int ok = 0;
        int failed = 0;
        try (PreparedStatement ps = conn.prepareStatement(upsertSql)) {
            for (Object[] row : rows) {
                try {
                    for (int i = 0; i < row.length; i++) {
                        ps.setObject(i + 1, row[i]);
                    }
                    ps.executeUpdate();
                    conn.commit();
                    ok++;
                } catch (java.sql.SQLException rowEx) {
                    conn.rollback();
                    failed++;
                    if (failed <= 5) {
                        log.warn("Neon upsert [{}] sor kihagyva (FK/constraint): {}", tableName, rootMsg(rowEx));
                    }
                }
            }
        }
        if (failed > 0) {
            log.warn("Neon upsert [{}] soronkénti fallback eredménye: {} ok, {} kihagyva (lógó FK / hibás sor)", tableName, ok, failed);
        }
        return ok;
    }

    /** A kivétel-lánc legmélyebb (root) üzenete, max 200 char — tiszta, nem-zajos log. */
    private static String rootMsg(Throwable t) {
        Throwable r = t;
        while (r.getCause() != null && r.getCause() != r) {
            r = r.getCause();
        }
        String m = r.getMessage();
        if (m == null) {
            return r.getClass().getSimpleName();
        }
        m = m.replaceAll("\\s+", " ").trim();
        return m.length() > 200 ? m.substring(0, 200) : m;
    }

    /**
     * Teljes-snapshot szinkronizáció — timestamp-oszlop nélküli / explicit teljes-snapshot
     * táblákhoz. A tábla TELJES tartalmát beolvassa és upsert-eli a Neonba (ON CONFLICT id).
     * Törlést NEM végez (konzisztens az inkrementális ág nem-törlő backup-filozófiájával);
     * MAX_FULL_SYNC_ROWS felett skip + loud log, hogy ne terheljük a Neont.
     */
    private int fullSync(String tableName) {
        Integer count = primaryJdbc.queryForObject(
                String.format("SELECT COUNT(*) FROM \"%s\"", tableName), Integer.class);
        if (count == null || count == 0) {
            logSyncResult(tableName, 0, "SUCCESS", null);
            return 0;
        }
        if (count > MAX_FULL_SYNC_ROWS) {
            log.warn("Neon sync [{}]: túl nagy tábla teljes-snapshothoz ({} sor > limit {}), skip",
                    tableName, count, MAX_FULL_SYNC_ROWS);
            logSyncResult(tableName, 0, "SKIPPED_TOO_LARGE",
                    "Teljes-snapshot tábla " + count + " sor > " + MAX_FULL_SYNC_ROWS);
            return 0;
        }

        LocalDateTime syncStart = LocalDateTime.now();
        List<Object[]> rows = new ArrayList<>();
        List<String> columnNames = new ArrayList<>();

        primaryJdbc.query(String.format("SELECT * FROM \"%s\"", tableName), rs -> {
            if (columnNames.isEmpty()) {
                ResultSetMetaData meta = rs.getMetaData();
                for (int i = 1; i <= meta.getColumnCount(); i++) {
                    columnNames.add(meta.getColumnName(i));
                }
            }
            Object[] row = new Object[columnNames.size()];
            for (int i = 0; i < columnNames.size(); i++) {
                row[i] = rs.getObject(i + 1);
            }
            rows.add(row);
        });

        int synced = upsertToNeon(tableName, columnNames, rows);
        logSyncResult(tableName, synced, "SUCCESS", null, syncStart);
        return synced;
    }

    /**
     * Tábla létezés-ellenőrzés a forrás (primary) sémában.
     * Megakadályozza, hogy egy hibásan konfigurált / nem létező táblanév
     * minden sync-ciklusban undefined_table SQL-kivételt dobjon.
     */
    private boolean tableExists(String tableName) {
        try {
            Integer n = primaryJdbc.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = ?",
                    Integer.class, tableName);
            return n != null && n > 0;
        } catch (Exception e) {
            // Ha maga az ellenőrzés is elhasal, ne blokkoljuk a többi tábla sync-jét.
            log.warn("Neon sync [{}]: tábla-létezés ellenőrzés hiba: {}", tableName, e.getMessage());
            return false;
        }
    }

    /**
     * Timestamp oszlop detektálás — updated_at > created_at > null.
     */
    private String detectTimestampColumn(String tableName) {
        try {
            List<String> columns = primaryJdbc.queryForList(
                    "SELECT column_name FROM information_schema.columns WHERE table_name = ? AND column_name IN ('updated_at', 'created_at') ORDER BY column_name DESC",
                    String.class, tableName);
            // Prefer updated_at, fallback created_at
            if (columns.contains("updated_at")) return "updated_at";
            if (columns.contains("created_at")) return "created_at";
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Utolsó sikeres sync ideje.
     */
    private LocalDateTime getLastSuccessfulSync(String tableName) {
        Optional<NeonSyncLog> lastLog = syncLogRepository
                .findTopByTableNameAndStatusOrderBySyncFinishedAtDesc(tableName, "SUCCESS");
        return lastLog.map(NeonSyncLog::getSyncFinishedAt)
                .orElse(LocalDateTime.of(2020, 1, 1, 0, 0));
    }

    private void logSyncResult(String tableName, int recordsSynced, String status, String error) {
        logSyncResult(tableName, recordsSynced, status, error, LocalDateTime.now());
    }

    private void logSyncResult(String tableName, int recordsSynced, String status, String error, LocalDateTime syncStartedAt) {
        try {
            NeonSyncLog logEntry = NeonSyncLog.builder()
                    .syncStartedAt(syncStartedAt)
                    .syncFinishedAt(LocalDateTime.now())
                    .tableName(tableName)
                    .recordsSynced(recordsSynced)
                    .status(status)
                    .errorMessage(error != null && error.length() > 2000 ? error.substring(0, 2000) : error)
                    .build();
            syncLogRepository.save(logEntry);
        } catch (Exception e) {
            log.warn("Neon sync log mentés hiba: {}", e.getMessage());
        }
    }
}
