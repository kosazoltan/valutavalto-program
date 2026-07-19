package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import jakarta.persistence.Column;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;

import java.lang.reflect.Method;
import java.util.Collection;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class ShipmentRequestS0b4ContractTest {

    @ParameterizedTest(name = "{0} scopes both shipment branches to company")
    @MethodSource("protectedListQueries")
    void protectedListQueriesRequireBothBranchesInTenant(String methodName, Class<?>[] parameterTypes)
            throws Exception {
        Method method = ShipmentRequestRepository.class.getMethod(methodName, parameterTypes);
        String query = method.getAnnotation(Query.class).value();

        assertThat(query)
                .contains("sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId)")
                .contains("sr.toBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId)");
    }

    @Test
    void companyIdRemainsInsertableButCannotBeUpdatedByJpa() throws Exception {
        Column column = ShipmentRequest.class.getDeclaredField("companyId").getAnnotation(Column.class);

        assertThat(column.name()).isEqualTo("company_id");
        assertThat(column.insertable()).isTrue();
        assertThat(column.updatable()).isFalse();
    }

    private static Stream<Arguments> protectedListQueries() {
        return Stream.of(
                Arguments.of("findByStatusAndCompanyId", new Class<?>[]{
                        ShipmentRequestStatus.class, UUID.class, Pageable.class}),
                Arguments.of("findAllOrderedByCompanyId", new Class<?>[]{
                        UUID.class, Pageable.class}),
                Arguments.of("findByBranchAndCompanyId", new Class<?>[]{
                        UUID.class, ShipmentRequestStatus.class, UUID.class, Pageable.class}),
                Arguments.of("findScopedByCompanyId", new Class<?>[]{
                        Collection.class, UUID.class, ShipmentRequestStatus.class, UUID.class, Pageable.class}),
                Arguments.of("findPendingForToBranch", new Class<?>[]{
                        UUID.class, UUID.class, Collection.class}));
    }
}
