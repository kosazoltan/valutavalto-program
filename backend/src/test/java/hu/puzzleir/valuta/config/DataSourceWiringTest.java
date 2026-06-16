package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.NeonReplicationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.lang.annotation.Annotation;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Strukturális kontraktus-teszt a DataSource/JdbcTemplate bean-wiringre.
 *
 * <p><b>Miért.</b> 2026-06-16 prod-probe: a Neon-backup hiányos lett (pl. transaction 36/134), mert a
 * {@link NeonReplicationService} {@code primaryJdbc} mezője — {@code @Qualifier} nélkül — a Neon
 * {@code neonJdbcTemplate}-re kötődött (a Spring Boot JdbcTemplate auto-config visszalépett, mert a
 * neonJdbcTemplate már létezett). Így a teljes-snapshot a Neont olvasta és önmagába írta vissza.
 *
 * <p>Ez a teszt a wiring KÉT sarokpontját rögzíti, hogy a regresszió ne térhessen vissza csendben:
 * (1) van explicit {@code @Primary} lokális {@link JdbcTemplate}; (2) a {@link NeonReplicationService}
 * az olvasóját ehhez ({@code primaryJdbcTemplate}) köti.
 */
class DataSourceWiringTest {

    @Test
    void primaryJdbcTemplate_isAnnotatedPrimary() throws NoSuchMethodException {
        Method m = PrimaryDataSourceConfig.class.getMethod("primaryJdbcTemplate", DataSource.class);
        assertThat(m.isAnnotationPresent(Primary.class))
                .as("a lokális JdbcTemplate-nek @Primary-nek kell lennie, különben a neonJdbcTemplate lesz az egyetlen/elsődleges")
                .isTrue();
        assertThat(m.getReturnType()).isEqualTo(JdbcTemplate.class);
    }

    @Test
    void neonReplicationService_readsFromPrimaryJdbcTemplate() {
        Constructor<?> ctor = NeonReplicationService.class.getDeclaredConstructors()[0];
        Parameter[] params = ctor.getParameters();

        Parameter jdbcParam = null;
        for (Parameter p : params) {
            if (JdbcTemplate.class.equals(p.getType())) {
                jdbcParam = p;
                break;
            }
        }
        assertThat(jdbcParam).as("a NeonReplicationService konstruktorának van JdbcTemplate paramétere").isNotNull();

        Qualifier q = jdbcParam.getAnnotation(Qualifier.class);
        assertThat(q)
                .as("a primaryJdbc olvasónak @Qualifier-rel a LOKÁLIS template-hez kell kötődnie (különben a Neonról olvasna)")
                .isNotNull();
        assertThat(q.value()).isEqualTo("primaryJdbcTemplate");

        // A Neon backup-cél DataSource-nak külön qualifierrel kell mennie (az írás iránya local→Neon).
        boolean hasNeonQualifier = false;
        for (Parameter p : params) {
            if (DataSource.class.equals(p.getType())) {
                for (Annotation a : p.getAnnotations()) {
                    if (a instanceof Qualifier qd && "neonDataSource".equals(qd.value())) {
                        hasNeonQualifier = true;
                    }
                }
            }
        }
        assertThat(hasNeonQualifier)
                .as("a Neon backup-cél DataSource @Qualifier(\"neonDataSource\")-szal van bekötve")
                .isTrue();
    }
}
