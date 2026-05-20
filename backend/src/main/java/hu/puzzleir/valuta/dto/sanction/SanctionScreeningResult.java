package hu.puzzleir.valuta.dto.sanction;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Szankciós szűrés eredménye.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SanctionScreeningResult {

    /** Volt-e találat */
    private boolean matched;

    /** Találatok listája */
    private List<SanctionMatch> matches;

    /** Kockázati szint: CLEAR, POSSIBLE, CONFIRMED */
    private String riskLevel;

    /**
     * Offline cache fallback jelző (#4): true, ha a szűrés ELAVULT/ÜRES helyi szankciós
     * listán futott (online frissítés nem érhető el, lista &gt; N napos vagy üres). A szűrés
     * ekkor is lefut a cache-ből (NEM áll le), de a hívó/UI explicit jelzést kap a degradált módról.
     */
    private boolean staleData;

    /** A helyi szankciós lista kora napokban (null, ha még sosem importálták). */
    private Integer listAgeDays;
}
