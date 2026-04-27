package hu.puzzleir.valuta;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * Valutaváltó ERP — Spring Boot főosztály.
 */
@SpringBootApplication
@EnableJpaAuditing
@EnableAsync
@ComponentScan(basePackages = {"hu.puzzleir.valuta"})
@EntityScan(basePackages = {"hu.puzzleir.valuta.entity", "hu.puzzleir.valuta.errorlog"})
@EnableJpaRepositories(basePackages = {"hu.puzzleir.valuta.repository", "hu.puzzleir.valuta.errorlog"})
public class ValutaBackendApplication {

    public static void main(String[] args) {
        // Render sometimes provides DATABASE_URL in non-JDBC format (postgres://...)
        String databaseUrl = System.getenv("DATABASE_URL");
        if (databaseUrl != null && !databaseUrl.isBlank() && !databaseUrl.startsWith("jdbc:")) {
            if (databaseUrl.startsWith("postgres://") || databaseUrl.startsWith("postgresql://")) {
                String jdbcUrl = databaseUrl.replaceFirst("^postgres(ql)?://", "jdbc:postgresql://");
                System.setProperty("spring.datasource.url", jdbcUrl);
            }
        }

        SpringApplication.run(ValutaBackendApplication.class, args);
    }
}
