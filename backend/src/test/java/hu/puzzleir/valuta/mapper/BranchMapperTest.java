package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.BranchDto;
import hu.puzzleir.valuta.entity.Branch;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * BranchMapper.toDto teszt — FK-002: a területi besorolás (region) ÉS az isVault
 * átkerül a DTO-ba, hogy az Országos készlet nézet területi csoportosítása
 * (régió-szekciók) végpont-szinten megkapja az adatot.
 */
class BranchMapperTest {

    private final BranchMapper mapper = new BranchMapper();

    @Test
    @DisplayName("FK-002: region + isVault átkerül a DTO-ba (csoportosítás adatfeltétele)")
    void mapsRegionAndIsVault() {
        Branch branch = Branch.builder()
                .id(UUID.randomUUID())
                .code("SZE01")
                .name("Szeged Tisza Sarok")
                .region("SZEGED")
                .regionCode("20")
                .isVault(true)
                .vaultTerritoryId(2)
                .isActive(true)
                .build();

        BranchDto dto = mapper.toDto(branch);

        assertThat(dto).isNotNull();
        assertThat(dto.getRegion()).isEqualTo("SZEGED");
        assertThat(dto.getIsVault()).isTrue();
        assertThat(dto.getVaultTerritoryId()).isEqualTo(2);
        assertThat(dto.getName()).isEqualTo("Szeged Tisza Sarok");
    }

    @Test
    @DisplayName("Hiányzó region (null) → DTO region null (a frontend BESOROLATLAN-ként kezeli)")
    void mapsNullRegion() {
        Branch branch = Branch.builder()
                .id(UUID.randomUUID())
                .code("IRODA")
                .name("Központi Iroda")
                .region(null)
                .isVault(false)
                .isActive(true)
                .build();

        BranchDto dto = mapper.toDto(branch);

        assertThat(dto.getRegion()).isNull();
        assertThat(dto.getIsVault()).isFalse();
    }

    @Test
    @DisplayName("null entity → null DTO")
    void mapsNullEntity() {
        assertThat(mapper.toDto(null)).isNull();
    }
}
