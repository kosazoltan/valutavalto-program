package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.customer.CustomerDto;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.DocumentType;
import hu.puzzleir.valuta.service.AmlEddService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class CustomerMapperTest {

    private final CustomerMapper mapper = new CustomerMapper();

    @Test
    @DisplayName("null entity → null DTO")
    void mapsNullEntity() {
        assertThat(mapper.toDto(null)).isNull();
    }

    @Test
    @DisplayName("AML-kritikus mezők + ügyfélazonosítók átkerülnek a DTO-ba")
    void mapsAmlCriticalFields() {
        LocalDate today = LocalDate.now(AmlEddService.BUSINESS_ZONE);
        Customer entity = Customer.builder()
                .id(1L)
                .customerCode("U-001")
                .name("Teszt Elek")
                .documentNumber("AB123456")
                .documentType(DocumentType.ID_CARD)
                .taxNumber("12345678-1-23")
                .active(true)
                .isPep(true)
                .isVip(false)
                .eddUntil(today.plusDays(30))
                .eddReason("50M+ tranzakció")
                .build();

        CustomerDto dto = mapper.toDto(entity);

        assertThat(dto.getId()).isEqualTo(1L);
        assertThat(dto.getCustomerCode()).isEqualTo("U-001");
        assertThat(dto.getName()).isEqualTo("Teszt Elek");
        assertThat(dto.getDocumentNumber()).isEqualTo("AB123456");
        assertThat(dto.getDocumentType()).isEqualTo(DocumentType.ID_CARD);
        assertThat(dto.getTaxNumber()).isEqualTo("12345678-1-23");
        assertThat(dto.getActive()).isTrue();
        assertThat(dto.getIsPep()).isTrue();
        assertThat(dto.getIsVip()).isFalse();
        assertThat(dto.getEddUntil()).isEqualTo(today.plusDays(30));
        assertThat(dto.getEddReason()).isEqualTo("50M+ tranzakció");
        assertThat(dto.getEddActive()).isTrue();
    }

    @Test
    @DisplayName("EDD aktív, ha eddUntil pontosan a mai üzleti nap")
    void mapsEddUntilTodayAsActive() {
        LocalDate today = LocalDate.now(AmlEddService.BUSINESS_ZONE);
        Customer entity = Customer.builder()
                .name("Mai EDD")
                .eddUntil(today)
                .build();

        CustomerDto dto = mapper.toDto(entity);

        assertThat(dto.getEddActive()).isTrue();
    }

    @Test
    @DisplayName("Múltbeli vagy hiányzó EDD lejárat → eddActive false")
    void mapsPastOrMissingEddAsInactive() {
        LocalDate today = LocalDate.now(AmlEddService.BUSINESS_ZONE);
        Customer pastEdd = Customer.builder()
                .name("Lejárt EDD")
                .eddUntil(today.minusDays(30))
                .build();
        Customer missingEdd = Customer.builder()
                .name("Nincs EDD")
                .eddUntil(null)
                .build();

        assertThat(mapper.toDto(pastEdd).getEddActive()).isFalse();
        assertThat(mapper.toDto(missingEdd).getEddActive()).isFalse();
    }

    @Test
    @DisplayName("Builder default PEP/VIP flagek false-ként képződnek le")
    void mapsDefaultPepAndVipFlags() {
        Customer entity = Customer.builder().name("Alap Ügyfél").build();

        CustomerDto dto = mapper.toDto(entity);

        assertThat(dto.getIsPep()).isFalse();
        assertThat(dto.getIsVip()).isFalse();
    }
}
