package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * HandlingFeeBracket repository INTEGRATION teszt — Flyway V75 + V109 + V227 ágon.
 *
 * <p>A 2026-05-13 v2.5.48 release után a kollégák production-on "Kezelési költség
 * mértéke nem rögzíthető" hibát tapasztaltak. Gyökér ok: a V75 a táblát
 * `active BOOLEAN` oszloppal hozta létre, a JPA entity viszont
 * {@code @Column(name = "is_active")}-ot vár. A V109 dinamikus alias-trigger
 * elvileg fedezné, de production-on nem szinkronizált — V227 ezt explicit
 * megoldja.</p>
 *
 * <p>Ez a teszt bizonyítja, hogy a teljes save + read flow működik H2-n
 * (és átalakítva PostgreSQL-en) miután a migrációk lefutottak.</p>
 */
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
@ActiveProfiles("test")
@Transactional
class HandlingFeeBracketRepositoryIT {

    @Autowired
    private HandlingFeeBracketRepository bracketRepository;

    @Autowired
    private CompanyRepository companyRepository;

    @Test
    @DisplayName("Save + findByCompanyIdAndActive: bracket round-trip (V227 ensure is_active works)")
    void saveAndFindRoundTrip() {
        Company company = companyRepository.save(Company.builder()
                .code("TST-" + System.nanoTime())
                .name("Test Company V227")
                .createdAt(java.time.LocalDateTime.now())
                .build());

        HandlingFeeBracket b1 = HandlingFeeBracket.builder()
                .company(company)
                .bracketOrder(1)
                .upperLimit(new BigDecimal("100000"))
                .feeAmount(new BigDecimal("500"))
                .active(true)
                .build();
        HandlingFeeBracket b2 = HandlingFeeBracket.builder()
                .company(company)
                .bracketOrder(2)
                .upperLimit(new BigDecimal("500000"))
                .feeAmount(new BigDecimal("1500"))
                .active(true)
                .build();

        bracketRepository.save(b1);
        bracketRepository.save(b2);

        List<HandlingFeeBracket> found = bracketRepository
                .findByCompanyIdAndActiveOrderByBracketOrder(company.getId(), true);

        assertThat(found)
                .as("Mindkét sáv vissza kell jöjjön az aktiv-keresésre (V227 fix bizonyíték)")
                .hasSize(2);
        assertThat(found.get(0).getBracketOrder()).isEqualTo(1);
        assertThat(found.get(0).getFeeAmount()).isEqualByComparingTo("500");
        assertThat(found.get(1).getBracketOrder()).isEqualTo(2);
        assertThat(found.get(1).getFeeAmount()).isEqualByComparingTo("1500");
    }

    @Test
    @DisplayName("Soft-delete (setActive(false)) -> findActive üres, full findAll megtalálja")
    void softDelete() {
        Company company = companyRepository.save(Company.builder()
                .code("TST-" + System.nanoTime())
                .name("Test Company V227 soft")
                .createdAt(java.time.LocalDateTime.now())
                .build());

        HandlingFeeBracket b = HandlingFeeBracket.builder()
                .company(company)
                .bracketOrder(1)
                .upperLimit(new BigDecimal("100000"))
                .feeAmount(new BigDecimal("500"))
                .active(true)
                .build();
        bracketRepository.save(b);

        b.setActive(false);
        bracketRepository.save(b);

        List<HandlingFeeBracket> activeOnly = bracketRepository
                .findByCompanyIdAndActiveOrderByBracketOrder(company.getId(), true);
        assertThat(activeOnly)
                .as("Inaktív sáv nem szerepelhet az active=true keresésben")
                .isEmpty();

        List<HandlingFeeBracket> inactiveOnly = bracketRepository
                .findByCompanyIdAndActiveOrderByBracketOrder(company.getId(), false);
        assertThat(inactiveOnly).hasSize(1);
        assertThat(inactiveOnly.get(0).getActive()).isFalse();
    }
}
