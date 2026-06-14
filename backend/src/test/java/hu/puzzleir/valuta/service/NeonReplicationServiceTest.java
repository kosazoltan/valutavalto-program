package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.NeonSyncLog;
import hu.puzzleir.valuta.repository.NeonSyncLogRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class NeonReplicationServiceTest {

    @Mock
    private JdbcTemplate primaryJdbc;

    @Mock
    private DataSource neonDataSource;

    @Mock
    private NeonSyncLogRepository syncLogRepository;

    private NeonReplicationService service;

    @BeforeEach
    void setUp() {
        service = new NeonReplicationService(primaryJdbc, neonDataSource, syncLogRepository);

        // Default: nincs korábbi sync log
        when(syncLogRepository.findTopByTableNameAndStatusOrderBySyncFinishedAtDesc(anyString(), eq("SUCCESS")))
                .thenReturn(Optional.empty());
        // Default: minden tábla létezik (tableExists guard — information_schema.tables COUNT)
        when(primaryJdbc.queryForObject(contains("information_schema.tables"), eq(Integer.class), anyString()))
                .thenReturn(1);
        // Default: timestamp oszlop detektálás
        when(primaryJdbc.queryForList(anyString(), eq(String.class), anyString()))
                .thenReturn(java.util.List.of("updated_at"));
        // Default: üres query result (nincs új adat)
        doAnswer(inv -> null).when(primaryJdbc).query(
                anyString(),
                any(org.springframework.jdbc.core.PreparedStatementSetter.class),
                any(org.springframework.jdbc.core.RowCallbackHandler.class));
    }

    @Test
    void syncToNeon_shouldNotThrow_whenNeonUnreachable() throws SQLException {
        assertThatCode(() -> service.syncToNeon())
                .doesNotThrowAnyException();
    }

    @Test
    void syncToNeon_shouldCompleteGracefully_whenNoData() {
        service.syncToNeon();
        // Nem dob exception-t, és végigmegy mind a 10 táblán
    }

    @Test
    void syncTable_shouldReturn0_whenNoNewRecords() {
        when(syncLogRepository.findTopByTableNameAndStatusOrderBySyncFinishedAtDesc(eq("transaction"), eq("SUCCESS")))
                .thenReturn(Optional.of(NeonSyncLog.builder()
                        .syncFinishedAt(LocalDateTime.now())
                        .build()));

        int result = service.syncTable("transaction");
        assertThat(result).isEqualTo(0);
    }

    @Test
    void syncTable_shouldReturn0AndSkip_whenTableDoesNotExist() {
        // A guard: nem létező tábla -> tiszta SKIPPED, NEM nyers SQL-kivétel minden ciklusban
        when(primaryJdbc.queryForObject(contains("information_schema.tables"), eq(Integer.class), eq("stock_snapshot")))
                .thenReturn(0);

        int result = service.syncTable("stock_snapshot");

        assertThat(result).isEqualTo(0);
        // SKIPPED_TABLE_MISSING log mentés történik, és NEM fut le a timestamp-detektálás/fullSync
        verify(syncLogRepository).save(argThat(l -> "SKIPPED_TABLE_MISSING".equals(l.getStatus())));
        verify(primaryJdbc, never()).queryForList(anyString(), eq(String.class), eq("stock_snapshot"));
    }

    @Test
    void syncTable_shouldSkip_whenNoTimestampColumnAndTooLarge() {
        when(primaryJdbc.queryForList(anyString(), eq(String.class), eq("receipt")))
                .thenReturn(java.util.List.of());

        // Nincs timestamp → teljes-snapshot kísérlet, de MAX_FULL_SYNC_ROWS (50000) felett skip
        when(primaryJdbc.queryForObject(contains("receipt"), eq(Integer.class)))
                .thenReturn(60000);

        int result = service.syncTable("receipt");
        assertThat(result).isEqualTo(0);
        verify(syncLogRepository).save(argThat(l -> "SKIPPED_TOO_LARGE".equals(l.getStatus())));
    }

    @Test
    void syncTable_currencyStock_usesFullSnapshotPath() {
        // currency_stock a FULL_SYNC_TABLES-ben van -> a teljes-snapshot ág fut (NEM inkrementális),
        // a detectTimestampColumn-t (queryForList) NEM hívja. > MAX_FULL_SYNC_ROWS -> skip.
        when(primaryJdbc.queryForObject(contains("currency_stock"), eq(Integer.class)))
                .thenReturn(60000);

        int result = service.syncTable("currency_stock");

        assertThat(result).isEqualTo(0);
        verify(syncLogRepository).save(argThat(l -> "SKIPPED_TOO_LARGE".equals(l.getStatus())));
        verify(primaryJdbc, never()).queryForList(anyString(), eq(String.class), eq("currency_stock"));
    }
}
