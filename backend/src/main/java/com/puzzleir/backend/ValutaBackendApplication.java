package com.puzzleir.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.boot.autoconfigure.domain.EntityScan;

/**
 * Valutaváltó ERP — Spring Boot főosztály.
 *
 * ComponentScan: com.puzzleir.backend (errorlog + core) + hu.puzzleir.valuta (fő üzleti logika)
 * excludeFilters: com.puzzleir.backend duplikátok kizárva (hu.puzzleir.valuta verziók az aktívak):
 *   - EveningClosingService (com.puzzleir.backend.service) → hu.puzzleir.valuta.service verzió aktív
 *   - EveningClosingController (com.puzzleir.backend.controller) → hu.puzzleir.valuta.controller verzió aktív
 *   - SecurityConfig (com.puzzleir.backend.config) → hu.puzzleir.valuta.config verzió aktív
 */
@SpringBootApplication
@EnableJpaAuditing
@ComponentScan(
    basePackages = {"com.puzzleir.backend", "hu.puzzleir.valuta"},
    excludeFilters = @ComponentScan.Filter(
        type = FilterType.REGEX,
        pattern = {
            // duplikalt service/controller (hu.puzzleir.valuta verzio az aktiv)
            // CSAK azok kizarva amiknek van hu.puzzleir.valuta csereje!
            "com\\.puzzleir\\.backend\\.service\\.EveningClosingService",
            "com\\.puzzleir\\.backend\\.controller\\.EveningClosingController",

            // regi security config kikapcsolva (hu.puzzleir.valuta.config.SecurityConfig aktiv)
            "com\\.puzzleir\\.backend\\.config\\.SecurityConfig"
        }
    )
)
@EntityScan(basePackages = {"com.puzzleir.backend.entity", "com.puzzleir.backend.errorlog", "hu.puzzleir.valuta.entity"})
@EnableJpaRepositories(basePackages = {"com.puzzleir.backend.repository", "com.puzzleir.backend.errorlog", "hu.puzzleir.valuta.repository"})
public class ValutaBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(ValutaBackendApplication.class, args);
    }
}
