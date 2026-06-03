package hu.puzzleir.valuta.entity;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Regressziós teszt: a Worker NOT NULL boolean mezőinek a Lombok @Builder-en keresztül is a
 * mezőhöz tartozó NEM-NULL defaultot kell adniuk (active = TRUE, a többi = FALSE) — @Builder.Default
 * nélkül a Lombok figyelmen kívül hagyja a mező-inicializálót, és a builderrel épített Worker
 * (pl. WorkerService.createWorker) null-t kapna, ami a NOT NULL oszlopokon (active/otp_enabled/
 * setup_grace/google_login_enabled/shared_account) INSERT-kor constraint-sértést okozna.
 * A setup_grace-en korábban hiányzott a @Builder.Default (ez volt a javított latens bug).
 */
class WorkerBuilderDefaultsTest {

    @Test
    void builderAppliesNonNullBooleanDefaults() {
        Worker worker = Worker.builder()
                .code("P999")
                .name("Teszt Pénztáros")
                .role(WorkerRole.CASHIER)
                .build();

        // Egyik NOT NULL boolean sem maradhat null a builderből (különben DB INSERT bukna).
        assertThat(worker.getActive()).isNotNull().isTrue();
        assertThat(worker.getOtpEnabled()).isNotNull().isFalse();
        assertThat(worker.getSetupGrace()).isNotNull().isFalse();
        assertThat(worker.getGoogleLoginEnabled()).isNotNull().isFalse();
        assertThat(worker.getSharedAccount()).isNotNull().isFalse();
    }
}
