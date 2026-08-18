package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.entity.WorkerRole;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Backend SSOT a kozponti iranyitokozpont moduljogosultsagaihoz.
 *
 * <p>A frontend modulindito csak megjelenit; bejelentkezeskor a szerver adja
 * vissza, hogy az aktiv szerepkor mely kozponti modulokat lathatja.</p>
 */
public final class CentralModuleManifest {

    private CentralModuleManifest() {}

    private record ModuleRule(String id, List<String> roles) {}

    private static final List<ModuleRule> MODULE_RULES = List.of(
            new ModuleRule("central-sprint", List.of(
                    "foertektar", "ugyvezeto", "belso_ellenor", "teruleti_vezeto",
                    "penzugyi_vezeto", "biztonsagi_vezeto")),
            new ModuleRule("rate-maker", List.of("foertektar", "ugyvezeto")),
            new ModuleRule("rate-publication", List.of("foertektar", "ugyvezeto")),
            new ModuleRule("national-stock", List.of("foertektar", "ugyvezeto")),
            new ModuleRule("vault-stocktake", List.of("foertektar", "ugyvezeto")),
            new ModuleRule("closing-control", List.of(
                    "foertektar", "ugyvezeto", "belso_ellenor", "teruleti_vezeto")),
            // FK-086 FR-4: a napi ellenőrző lista a teruleti_vezeto elől elzárt
            // (a modul id SZÁNDÉKOSAN marad daily-checklist — rename out of scope).
            new ModuleRule("daily-checklist", List.of(
                    "foertektar", "ugyvezeto", "belso_ellenor")),
            new ModuleRule("received-data", List.of(
                    "foertektar", "ugyvezeto", "belso_ellenor", "teruleti_vezeto")),
            new ModuleRule("daily-turnover", List.of(
                    "foertektar", "ugyvezeto", "belso_ellenor", "penzugyi_vezeto")),
            new ModuleRule("mnb-reports", List.of(
                    "foertektar", "ugyvezeto", "belso_ellenor", "penzugyi_vezeto")),
            new ModuleRule("bank-orders", List.of("foertektar", "ugyvezeto", "penzugyi_vezeto")),
            new ModuleRule("bank-transactions", List.of("foertektar", "ugyvezeto", "penzugyi_vezeto")),
            new ModuleRule("booking-export", List.of("ugyvezeto", "penzugyi_vezeto", "foertektar")),
            new ModuleRule("compliance-dashboard", List.of("belso_ellenor", "biztonsagi_vezeto", "ugyvezeto")),
            new ModuleRule("sanction-list", List.of("belso_ellenor", "biztonsagi_vezeto", "ugyvezeto")),
            new ModuleRule("transaction-audit", List.of(
                    "belso_ellenor", "biztonsagi_vezeto", "ugyvezeto", "foertektar")),
            new ModuleRule("wu-vat-control", List.of(
                    "belso_ellenor", "biztonsagi_vezeto", "ugyvezeto", "foertektar")),
            new ModuleRule("worker-registry", List.of("ugyvezeto", "irodavezeto", "irodai_dolgozo")),
            new ModuleRule("commission-rates", List.of("ugyvezeto", "berszamfejto", "foertektar")),
            new ModuleRule("branch-groups", List.of("ugyvezeto", "irodavezeto", "foertektar")),
            new ModuleRule("permission-matrix", List.of("ugyvezeto")),
            new ModuleRule("customer-control", List.of("belso_ellenor", "ugyvezeto", "irodavezeto", "foertektar")),
            new ModuleRule("document-vault", List.of(
                    "belso_ellenor", "biztonsagi_vezeto", "ugyvezeto", "foertektar")),
            new ModuleRule("police-requests", List.of("belso_ellenor", "biztonsagi_vezeto", "ugyvezeto")),
            new ModuleRule("circulars", List.of("ugyvezeto", "irodavezeto", "irodai_dolgozo"))
    );

    public static List<String> allModuleIds() {
        return MODULE_RULES.stream().map(ModuleRule::id).toList();
    }

    public static List<String> allowedModules(
            List<String> roleCodes,
            String activeRole,
            WorkerRole legacyWorkerRole
    ) {
        Set<String> effectiveRoles = effectiveRoles(roleCodes, activeRole, legacyWorkerRole);
        if (effectiveRoles.contains("admin")) {
            return allModuleIds();
        }

        List<String> allowed = new ArrayList<>();
        for (ModuleRule rule : MODULE_RULES) {
            if (rule.roles().stream().anyMatch(effectiveRoles::contains)) {
                allowed.add(rule.id());
            }
        }
        return allowed;
    }

    private static Set<String> effectiveRoles(List<String> roleCodes, String activeRole, WorkerRole legacyWorkerRole) {
        Set<String> roles = new LinkedHashSet<>();
        String normalizedActiveRole = normalizeRole(activeRole);
        if (!normalizedActiveRole.isBlank()) {
            roles.add(normalizedActiveRole);
            return roles;
        }

        if (roleCodes != null) {
            for (String roleCode : roleCodes) {
                String normalized = normalizeRole(roleCode);
                if (!normalized.isBlank()) {
                    roles.add(normalized);
                }
            }
        }
        if (roles.isEmpty() && legacyWorkerRole == WorkerRole.ADMIN) {
            roles.add("admin");
        }
        return roles;
    }

    private static String normalizeRole(String roleCode) {
        return roleCode == null ? "" : roleCode.trim().toLowerCase(Locale.ROOT);
    }
}
