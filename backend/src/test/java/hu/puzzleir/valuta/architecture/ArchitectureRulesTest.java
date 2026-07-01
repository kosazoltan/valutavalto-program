package hu.puzzleir.valuta.architecture;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * Architektúra-konformitás gate (ArchUnit) — statikusan kikényszeríti a réteg-izolációt és a
 * controller-biztonság alapszabályait a teljes backend kódbázison, minden PR-en.
 *
 * <p>Motiváció: az FK-049 (Átlag árfolyam) hibaosztály — @PreAuthorize hiánya/eltévesztése —
 * pontosan az a fajta konvenció-sértés, amit egyetlen kézi review sem lát meg megbízhatóan 183
 * controller mellett. Ezek a szabályok gépi kapuvá teszik a réteg- és biztonsági konvenciókat.</p>
 *
 * <p>Megjegyzés: a szabályok a repo JELENLEG BETARTOTT konvencióira épülnek (kódból verifikálva,
 * 2026-07-01). A @PreAuthorize szerepkör-nevek whitelist-konformitása (kanonikus vs. fantom role)
 * tágabb RBAC-audit tárgya (az FK-049 spec TBD-1 szerint külön FK), ezért ez a gate a STRUKTURÁLIS
 * konvenciókat őrzi, nem a role-nevek szemantikáját.</p>
 */
@DisplayName("Architektúra-konformitás (ArchUnit)")
class ArchitectureRulesTest {

    private static final String BASE = "hu.puzzleir.valuta";
    private static JavaClasses productionClasses;

    @BeforeAll
    static void importClasses() {
        // Csak a fő (production) kód — teszteket kizárjuk.
        productionClasses = new ClassFileImporter()
                .withImportOption(new ImportOption.DoNotIncludeTests())
                .importPackages(BASE);
    }

    @Test
    @DisplayName("Réteg-izoláció: repository NEM függ service-től és controllertől (nem felfelé)")
    void repositoriesMustNotDependOnUpperLayers() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..repository..")
                .should().dependOnClassesThat().resideInAnyPackage("..service..", "..controller..")
                .because("a repository a legalsó adatréteg; nem hivatkozhat felfelé (service/controller)");
        rule.check(productionClasses);
    }

    @Test
    @DisplayName("Réteg-izoláció: entity NEM függ controllertől és service-től")
    void entitiesMustNotDependOnUpperLayers() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..entity..")
                .should().dependOnClassesThat().resideInAnyPackage("..controller..", "..service..")
                .because("a JPA entity domain-adatszerkezet; nem függhet a felsőbb rétegektől");
        rule.check(productionClasses);
    }

    @Test
    @DisplayName("Elnevezési konvenció: @RestController osztály neve *Controller-re végződik")
    void restControllersMustBeSuffixedController() {
        ArchRule rule = classes()
                .that().areAnnotatedWith(org.springframework.web.bind.annotation.RestController.class)
                .should().haveSimpleNameEndingWith("Controller")
                .because("a @RestController-ek egységes elnevezése (…Controller) a felfedezhetőséget "
                        + "és az ArchUnit/biztonsági szabályok célzását biztosítja");
        rule.check(productionClasses);
    }

    @Test
    @DisplayName("Elnevezési konvenció: @Repository osztály a repository package-ben van")
    void repositoriesResideInRepositoryPackage() {
        ArchRule rule = classes()
                .that().areAnnotatedWith(org.springframework.stereotype.Repository.class)
                .should().resideInAPackage("..repository..")
                .because("a repository-k egy helyen (réteg-izoláció, felfedezhetőség)");
        rule.check(productionClasses);
    }

    @Test
    @DisplayName("Controller-biztonság: minden @RestController @PreAuthorize-védett (class- vagy teljes method-szinten); baseline-frozen a SecurityConfig-matcherrel védett meglévőkre")
    void restControllersMustBeSecured() {
        // Deny-by-default a @PreAuthorize rétegen. A repo KETTŐS védelmi modellt használ: method/class
        // @PreAuthorize ÉS/VAGY SecurityConfig HTTP-matcher (requestMatchers(...).hasAnyRole/authenticated).
        // Az ArchUnit statikusan a @PreAuthorize-t látja, a SecurityConfig-matchert nem — ezért a
        // jelenleg @PreAuthorize nélküli, de SecurityConfig-matcherrel védett végpontok (pl. /workers/**,
        // saját-adat /me végpontok, MFA/Supervisor auth-lépések) FROZEN baseline-ba kerülnek (kódból
        // verifikálva NEM rések). A FreezingArchRule így minden ÚJ, teljesen új védtelen végpontot elkap
        // (regresszió-védelem; FK-049 hibaosztály), miközben a meglévő legitim eseteket nem hamisítja hibává.
        ArchRule rule = classes()
                .that().areAnnotatedWith(org.springframework.web.bind.annotation.RestController.class)
                .and().haveSimpleNameNotEndingWith("AuthController")
                .and().haveSimpleNameNotEndingWith("ErrorLogController")
                .and().haveSimpleNameNotEndingWith("ErrorReportController")
                .and().haveSimpleNameNotEndingWith("StaticAuditController")
                .should(HAVE_CLASS_OR_ALL_METHODS_PREAUTHORIZE)
                .because("minden üzleti @RestController-nek explicit @PreAuthorize-t kell hordoznia "
                        + "(deny-by-default; az FK-049 @PreAuthorize-hiány/eltévesztés hibaosztály elleni statikus védelem)");
        com.tngtech.archunit.library.freeze.FreezingArchRule.freeze(rule).check(productionClasses);
    }

    /**
     * Deny-by-default: a controller VAGY class-szintű @PreAuthorize-t hordoz (a Spring ezt minden
     * metódusra érvényesíti), VAGY MINDEN HTTP-végpont-metódusa saját method-szintű @PreAuthorize-t
     * kap. Részlegesen védett controller (néhány metódus védtelen) MEGBUKIK — a védtelen metódusokat
     * név szerint jelenti. Ez zárja az FK-049 @PreAuthorize-hiány hibaosztályt (GLM-review #1).
     *
     * <p>Megj.: a repo kizárólag @RestController-t használ (nincs @Controller+@ResponseBody), és a
     * HTTP-leképzés @Get/@Post/@Put/@Delete/@PatchMapping — ezeket nézzük végpont-metódusként.</p>
     */
    private static final com.tngtech.archunit.lang.ArchCondition<com.tngtech.archunit.core.domain.JavaClass>
            HAVE_CLASS_OR_ALL_METHODS_PREAUTHORIZE = new com.tngtech.archunit.lang.ArchCondition<>(
                    "have class-level @PreAuthorize, or @PreAuthorize on EVERY HTTP endpoint method") {
        @Override
        public void check(com.tngtech.archunit.core.domain.JavaClass clazz,
                          com.tngtech.archunit.lang.ConditionEvents events) {
            if (clazz.isAnnotatedWith(org.springframework.security.access.prepost.PreAuthorize.class)) {
                events.add(new com.tngtech.archunit.lang.SimpleConditionEvent(clazz, true,
                        clazz.getName() + " class-szintű @PreAuthorize (minden metódusra érvényes)"));
                return;
            }
            // Nincs class-szintű → MINDEN HTTP-végpont-metódusnak method-szintű @PreAuthorize kell.
            var unsecured = clazz.getMethods().stream()
                    .filter(ArchitectureRulesTest::isHttpEndpoint)
                    .filter(m -> !m.isAnnotatedWith(
                            org.springframework.security.access.prepost.PreAuthorize.class))
                    .map(m -> m.getFullName())
                    .sorted()
                    .toList();
            boolean secured = unsecured.isEmpty();
            events.add(new com.tngtech.archunit.lang.SimpleConditionEvent(clazz, secured,
                    secured
                        ? clazz.getName() + " minden HTTP-metódusa method-szintű @PreAuthorize-t hordoz"
                        : clazz.getName() + " védtelen HTTP-metódus(ok) @PreAuthorize nélkül: " + unsecured));
        }
    };

    private static final java.util.List<Class<? extends java.lang.annotation.Annotation>> HTTP_MAPPINGS =
            java.util.List.of(
                    org.springframework.web.bind.annotation.GetMapping.class,
                    org.springframework.web.bind.annotation.PostMapping.class,
                    org.springframework.web.bind.annotation.PutMapping.class,
                    org.springframework.web.bind.annotation.DeleteMapping.class,
                    org.springframework.web.bind.annotation.PatchMapping.class,
                    org.springframework.web.bind.annotation.RequestMapping.class);

    private static boolean isHttpEndpoint(com.tngtech.archunit.core.domain.JavaMethod method) {
        return HTTP_MAPPINGS.stream().anyMatch(method::isAnnotatedWith);
    }
}
