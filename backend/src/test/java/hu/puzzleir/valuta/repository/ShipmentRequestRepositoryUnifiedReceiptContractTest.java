package hu.puzzleir.valuta.repository;

import jakarta.persistence.LockModeType;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.lang.reflect.Method;
import java.util.Collection;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ShipmentRequestRepositoryUnifiedReceiptContractTest {

    @Test
    void normalLookupScopesByAuthoritativeShipmentCompanyId() throws Exception {
        Method method = ShipmentRequestRepository.class.getMethod(
                "findByIdAndCompanyId", UUID.class, UUID.class);

        assertThat(method.getAnnotation(Query.class).value())
                .contains("sr.id = :id")
                .contains("sr.companyId = :companyId");
    }

    @Test
    void deliverMutationUsesTenantScopedPessimisticWriteLock() throws Exception {
        Method method = ShipmentRequestRepository.class.getMethod(
                "findByIdAndCompanyIdForUpdate", UUID.class, UUID.class);

        assertThat(method.getAnnotation(Lock.class).value())
                .isEqualTo(LockModeType.PESSIMISTIC_WRITE);
        assertThat(method.getAnnotation(Query.class).value())
                .contains("sr.id = :id")
                .contains("sr.companyId = :companyId");
    }

    @Test
    void pendingQueryScopesReceiverStatusAndBothBranchesToTenant() throws Exception {
        Method method = ShipmentRequestRepository.class.getMethod(
                "findPendingForToBranch", UUID.class, UUID.class, Collection.class);
        String query = method.getAnnotation(Query.class).value();

        assertThat(query)
                .contains("sr.toBranchId = :toBranchId")
                .contains("sr.status IN :statuses")
                .contains("sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId)")
                .contains("sr.toBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId)")
                .contains("ORDER BY sr.createdAt DESC");
    }
}
