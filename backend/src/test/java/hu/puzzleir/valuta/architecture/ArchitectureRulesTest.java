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
    @DisplayName("Controller-biztonság: minden @RestController hordoz @PreAuthorize-t (class- vagy method-szinten), a dokumentált public kivételekkel")
    void restControllersMustBeSecured() {
        // A Spring a class-szintű @PreAuthorize-t is érvényesíti minden metódusra; a repo bevált
        // mintája a class-szintű annotáció. Ez a szabály azt garantálja, hogy egyetlen üzleti
        // @RestController se maradjon teljesen védelem nélkül (deny-by-default; FK-049 hibaosztály).
        // Kivételek: a SecurityConfig-ban permitAll-ként dokumentált, SZÁNDÉKOSAN publikus controllerek
        // (Auth = login/refresh/bootstrap; ErrorLog/ErrorReport = pre-login hibabejelentés; StaticAudit).
        ArchRule rule = classes()
                .that().areAnnotatedWith(org.springframework.web.bind.annotation.RestController.class)
                .and().haveSimpleNameNotEndingWith("AuthController")
                .and().haveSimpleNameNotEndingWith("ErrorLogController")
                .and().haveSimpleNameNotEndingWith("ErrorReportController")
                .and().haveSimpleNameNotEndingWith("StaticAuditController")
                .should(HAVE_CLASS_OR_METHOD_PREAUTHORIZE)
                .because("minden üzleti @RestController-nek explicit @PreAuthorize-t kell hordoznia "
                        + "(deny-by-default; az FK-049 @PreAuthorize-hiány/eltévesztés hibaosztály elleni statikus védelem)");
        rule.check(productionClasses);
    }

    /** Igaz, ha az osztályon VAGY bármely metódusán van @PreAuthorize (a Spring mindkettőt érvényesíti). */
    private static final com.tngtech.archunit.lang.ArchCondition<com.tngtech.archunit.core.domain.JavaClass>
            HAVE_CLASS_OR_METHOD_PREAUTHORIZE = new com.tngtech.archunit.lang.ArchCondition<>(
                    "have @PreAuthorize on the class or on at least one method") {
        @Override
        public void check(com.tngtech.archunit.core.domain.JavaClass clazz,
                          com.tngtech.archunit.lang.ConditionEvents events) {
            boolean classLevel = clazz.isAnnotatedWith(
                    org.springframework.security.access.prepost.PreAuthorize.class);
            boolean anyMethodLevel = clazz.getMethods().stream().anyMatch(m -> m.isAnnotatedWith(
                    org.springframework.security.access.prepost.PreAuthorize.class));
            boolean satisfied = classLevel || anyMethodLevel;
            events.add(new com.tngtech.archunit.lang.SimpleConditionEvent(clazz, satisfied,
                    String.format("%s %s @PreAuthorize (%s)",
                            clazz.getName(),
                            satisfied ? "hordoz" : "NEM hordoz",
                            clazz.getSourceCodeLocation())));
        }
    };
}
