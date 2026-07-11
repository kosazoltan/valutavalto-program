package hu.puzzleir.valuta.repository;

import jakarta.persistence.LockModeType;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.lang.reflect.Method;
import java.time.LocalDate;
import java.util.Collection;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class DariusFixingRequestRepositoryLockContractTest {

    @Test
    void mutationAndExportQueriesUsePessimisticWriteWithTenantScopeAndDeterministicOrder() throws Exception {
        Method mutation = DariusFixingRequestRepository.class.getMethod(
                "findForUpdateByIdAndCompanyId", UUID.class, UUID.class);
        Method export = DariusFixingRequestRepository.class.getMethod(
                "findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc",
                UUID.class,
                LocalDate.class,
                Collection.class);

        assertThat(mutation.getAnnotation(Lock.class).value()).isEqualTo(LockModeType.PESSIMISTIC_WRITE);
        assertThat(export.getAnnotation(Lock.class).value()).isEqualTo(LockModeType.PESSIMISTIC_WRITE);
        assertThat(mutation.getAnnotation(Query.class).value())
                .contains("r.id = :id")
                .contains("r.companyId = :companyId");
        assertThat(export.getAnnotation(Query.class).value())
                .contains("r.companyId = :companyId")
                .contains("r.requestDate = :requestDate")
                .contains("r.status IN :statuses")
                .contains("ORDER BY r.createdAt ASC, r.id ASC");
    }
}
