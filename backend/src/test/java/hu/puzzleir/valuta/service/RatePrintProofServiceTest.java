package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class RatePrintProofServiceTest {

    private static final UUID DISTRIBUTION_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID OTHER_DISTRIBUTION_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID BRANCH_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID MASTER_RATE_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");
    private static final UUID COMPANY_ID = UUID.fromString("55555555-5555-5555-5555-555555555555");

    private final RatePrintProofService service = new RatePrintProofService("test-secret");

    @Test
    @DisplayName("issueToken determinisztikus és hex HMAC token")
    void issueTokenIsDeterministic() {
        String first = service.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID);
        String second = service.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID);

        assertThat(first).isEqualTo(second);
        assertThat(first).matches("[0-9a-f]{64}");
    }

    @Test
    @DisplayName("verifyToken elfogadja a saját paraméterekre kiadott tokent")
    void verifyTokenAcceptsIssuedToken() {
        String token = service.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID);

        assertThat(service.verifyToken(token, DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isTrue();
    }

    @Test
    @DisplayName("verifyToken elutasítja a másik distributionId-ra kiadott tokent")
    void verifyTokenRejectsOtherDistribution() {
        String token = service.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID);

        assertThat(service.verifyToken(token, OTHER_DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isFalse();
    }

    @Test
    @DisplayName("verifyToken elutasítja a megváltoztatott tokent")
    void verifyTokenRejectsTamperedToken() {
        String token = service.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID);
        String tampered = token.substring(0, token.length() - 1) + (token.endsWith("0") ? "1" : "0");

        assertThat(service.verifyToken(tampered, DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isFalse();
    }

    @Test
    @DisplayName("verifyToken null és üres tokenre false-t ad, exception nélkül")
    void verifyTokenRejectsMissingTokenWithoutException() {
        assertThat(service.verifyToken(null, DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isFalse();
        assertThat(service.verifyToken("", DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isFalse();
        assertThat(service.verifyToken("   ", DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isFalse();
    }

    @Test
    @DisplayName("ket instance ugyanazzal a secrettel kereszt-verifikal (HA/restart kontrakt)")
    void sameSecretInstancesCrossVerify() {
        RatePrintProofService a = new RatePrintProofService("shared-secret");
        RatePrintProofService b = new RatePrintProofService("shared-secret");

        String token = a.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID);
        assertThat(b.verifyToken(token, DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isTrue();
    }

    @Test
    @DisplayName("ures secret = processz-lokalis random fallback - instance-ok NEM kereszt-verifikalnak")
    void blankSecretInstancesDoNotCrossVerify() {
        RatePrintProofService a = new RatePrintProofService("");
        RatePrintProofService b = new RatePrintProofService("");

        String token = a.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID);
        assertThat(b.verifyToken(token, DISTRIBUTION_ID, BRANCH_ID, MASTER_RATE_ID, COMPANY_ID)).isFalse();
    }
}
