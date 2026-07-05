package hu.puzzleir.valuta.errorlog;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class StaticAuditServiceTest {

    @Test
    @DisplayName("runStaticAudit tartalmazza az APP_RATE_PRINT_HMAC_SECRET láthatósági check-et")
    void runStaticAuditIncludesRatePrintSecretEnvVisibility() {
        EntityManager em = mock(EntityManager.class);
        Query query = mock(Query.class);
        when(em.createNativeQuery("SELECT 1")).thenReturn(query);
        when(query.getSingleResult()).thenReturn(1);

        ErrorMailerService mailer = mock(ErrorMailerService.class);

        StaticAuditService service = new StaticAuditService(em, mailer);
        List<AuditCheck> checks = service.runStaticAudit();

        assertThat(checks)
                .anyMatch(c -> "APP_RATE_PRINT_HMAC_SECRET".equals(c.getName()));
    }
}
