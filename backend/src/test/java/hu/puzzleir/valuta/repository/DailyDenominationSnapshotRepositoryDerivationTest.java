package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.repository.query.parser.Part;
import org.springframework.data.repository.query.parser.PartTree;

import java.lang.reflect.Method;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-111: proves the bulk finder is a VALID derived query against the real entity metamodel —
 * mocked repository unit tests never exercise Spring Data's query derivation, so a typo in the
 * property path would only surface at application startup.
 */
class DailyDenominationSnapshotRepositoryDerivationTest {

    private static final String BULK_FINDER = "findByBranchIdInAndSnapshotDateAndClosingType";

    @Test
    @DisplayName("the bulk finder derives to branchId IN (..) AND snapshotDate = .. AND closingType = ..")
    void bulkFinderDerives() {
        PartTree tree = new PartTree(BULK_FINDER, DailyDenominationSnapshot.class);

        List<Part> parts = tree.getParts().toList();
        assertThat(parts).hasSize(3);
        assertThat(parts.get(0).getProperty().toDotPath()).isEqualTo("branchId");
        assertThat(parts.get(0).getType()).isEqualTo(Part.Type.IN);
        assertThat(parts.get(1).getProperty().toDotPath()).isEqualTo("snapshotDate");
        assertThat(parts.get(1).getType()).isEqualTo(Part.Type.SIMPLE_PROPERTY);
        assertThat(parts.get(2).getProperty().toDotPath()).isEqualTo("closingType");
        assertThat(parts.get(2).getType()).isEqualTo(Part.Type.SIMPLE_PROPERTY);
        assertThat(tree.isDelete()).isFalse();
        assertThat(tree.isLimiting()).isFalse();
    }

    @Test
    @DisplayName("the declared signature matches the derived parameter order and returns a collection")
    void signatureMatchesDerivation() throws NoSuchMethodException {
        Method method = DailyDenominationSnapshotRepository.class.getMethod(
                BULK_FINDER, List.class, java.time.LocalDate.class, Integer.class);

        assertThat(method.getReturnType()).isEqualTo(List.class);
        // An IN part must be fed by a collection, otherwise the query fails at bind time.
        assertThat(method.getParameterTypes()[0]).isEqualTo(List.class);
    }

    @Test
    @DisplayName("branchIds is the only tenant filter in the query — the repository is not company aware")
    void finderCarriesNoImplicitCompanyFilter() {
        PartTree tree = new PartTree(BULK_FINDER, DailyDenominationSnapshot.class);

        // Documented contract: ReceivedDenominationsService must pass company-scoped ids only,
        // because the query itself has no company predicate to fall back on.
        assertThat(tree.getParts().toList())
                .extracting(part -> part.getProperty().toDotPath())
                .containsExactly("branchId", "snapshotDate", "closingType")
                .doesNotContain("companyId");
    }
}
