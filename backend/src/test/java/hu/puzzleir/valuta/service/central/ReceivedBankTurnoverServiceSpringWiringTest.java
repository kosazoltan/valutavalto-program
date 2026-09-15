package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/**
 * Characteristic test for the 2026-09-15 origin 502: Spring refused to start
 * {@code ReceivedBankTurnoverService} because two constructors and no
 * {@code @Autowired} made it fall back to a missing no-arg ctor.
 */
class ReceivedBankTurnoverServiceSpringWiringTest {

    @Test
    @DisplayName("Spring can construct ReceivedBankTurnoverService from the public 3-arg constructor")
    void springWiresPublicThreeArgConstructor() {
        try (AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext()) {
            ctx.registerBean(DailyBalanceRepository.class, () -> mock(DailyBalanceRepository.class));
            ctx.registerBean(ClosingControlRepository.class, () -> mock(ClosingControlRepository.class));
            ctx.registerBean(BranchRepository.class, () -> mock(BranchRepository.class));
            ctx.register(ReceivedBankTurnoverService.class);
            ctx.refresh();

            assertThat(ctx.getBean(ReceivedBankTurnoverService.class)).isNotNull();
        } catch (BeanCreationException ex) {
            throw new AssertionError(
                    "Spring must wire ReceivedBankTurnoverService via the public 3-arg constructor; "
                            + "missing @Autowired on a dual-ctor @Service crashes production startup",
                    ex);
        }
    }
}
