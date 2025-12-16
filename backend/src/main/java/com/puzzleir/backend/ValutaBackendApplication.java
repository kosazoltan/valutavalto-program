package com.puzzleir.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.boot.autoconfigure.domain.EntityScan;

@SpringBootApplication
@EnableJpaAuditing
@ComponentScan(basePackages = {"com.puzzleir.backend", "hu.puzzleir.valuta"})
@EntityScan(basePackages = {"com.puzzleir.backend.entity", "hu.puzzleir.valuta.entity"})
@EnableJpaRepositories(basePackages = {"com.puzzleir.backend.repository", "hu.puzzleir.valuta.repository"})
public class ValutaBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(ValutaBackendApplication.class, args);
    }
}
