package hu.puzzleir.valuta;

import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Minimális teszt konfiguráció a hu.puzzleir.valuta package-ben.
 *
 * NEM @SpringBootApplication — tehát NEM csinál @ComponentScan-t!
 * Így a @WebMvcTest NEM tölti be a valódi @Service és @Configuration bean-eket,
 * hanem CSAK a controller-t (amit a @WebMvcTest(controllers = ...) megad)
 * és a @MockBean-eket.
 *
 * A @DataJpaTest saját entity scanning-et csinál, de az EntityScan és
 * EnableJpaRepositories biztosítja, hogy a repository tesztek működjenek.
 */
@SpringBootConfiguration
@EnableAutoConfiguration
@EntityScan(basePackages = "hu.puzzleir.valuta.entity")
@EnableJpaRepositories(basePackages = "hu.puzzleir.valuta.repository")
public class TestApplication {
}
