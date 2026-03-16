package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.mnb.MnbSubmissionResult;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.*;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MnbApiClient UNIT tesztek — Mockito + RestTemplate mock.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class MnbApiClientTest {

    @InjectMocks
    private MnbApiClient mnbApiClient;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private SystemParameterService systemParameterService;

    private static final String TEST_URL   = "https://mnb-test.hu/api/report";
    private static final String TEST_TOKEN = "test-token-abc";
    private static final String TEST_XML   = "<?xml version=\"1.0\"?><Jelentes/>";

    @BeforeEach
    void setUp() {
        when(systemParameterService.getValue("MNB_API_URL")).thenReturn(TEST_URL);
        when(systemParameterService.getValue("MNB_API_TOKEN")).thenReturn(TEST_TOKEN);
    }

    // ============ Sikeres HTTP 200 ============

    @Test
    @DisplayName("submitXml: HTTP 200 → success=true, referenceNumber kinyerve")
    void testSubmitXml_http200_success() {
        String responseBody = "<Response><RefNum>MNB-20260316-001</RefNum></Response>";
        ResponseEntity<String> okResponse = ResponseEntity.ok(responseBody);

        when(restTemplate.exchange(eq(TEST_URL), eq(HttpMethod.POST), any(HttpEntity.class), eq(String.class)))
            .thenReturn(okResponse);

        MnbSubmissionResult result = mnbApiClient.submitXml(TEST_XML, "DAILY");

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getReferenceNumber()).isEqualTo("MNB-20260316-001");
        assertThat(result.getErrorMessage()).isNull();
    }

    @Test
    @DisplayName("submitXml: HTTP 200 de nincs RefNum tag → fallback referencia")
    void testSubmitXml_http200_noRefNum() {
        ResponseEntity<String> okResponse = ResponseEntity.ok("OK");

        when(restTemplate.exchange(eq(TEST_URL), eq(HttpMethod.POST), any(HttpEntity.class), eq(String.class)))
            .thenReturn(okResponse);

        MnbSubmissionResult result = mnbApiClient.submitXml(TEST_XML, "DAILY");

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getReferenceNumber()).isNotBlank();
    }

    // ============ HTTP 500 hiba ============

    @Test
    @DisplayName("submitXml: HTTP 500 → success=false, errorMessage tartalmaz 500-at")
    void testSubmitXml_http500_failure() {
        when(restTemplate.exchange(eq(TEST_URL), eq(HttpMethod.POST), any(HttpEntity.class), eq(String.class)))
            .thenThrow(new HttpServerErrorException(HttpStatus.INTERNAL_SERVER_ERROR, "Server Error",
                "Internal Server Error".getBytes(), StandardCharsets.UTF_8));

        MnbSubmissionResult result = mnbApiClient.submitXml(TEST_XML, "DAILY");

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getErrorMessage()).contains("500");
    }

    // ============ Hiányzó konfiguráció ============

    @Test
    @DisplayName("submitXml: MNB_API_URL hiányzik → success=false, konfig hiba")
    void testSubmitXml_missingUrl_failure() {
        when(systemParameterService.getValue("MNB_API_URL"))
            .thenThrow(new ResourceNotFoundException("Paraméter nem található: MNB_API_URL"));

        MnbSubmissionResult result = mnbApiClient.submitXml(TEST_XML, "DAILY");

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getErrorMessage()).contains("konfiguráció");
        verifyNoInteractions(restTemplate);
    }

    @Test
    @DisplayName("submitXml: MNB_API_URL üres → success=false, üres URL hiba")
    void testSubmitXml_emptyUrl_failure() {
        when(systemParameterService.getValue("MNB_API_URL")).thenReturn("   ");

        MnbSubmissionResult result = mnbApiClient.submitXml(TEST_XML, "DAILY");

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getErrorMessage()).contains("MNB_API_URL");
        verifyNoInteractions(restTemplate);
    }

    @Test
    @DisplayName("submitXml: X-Report-Type fejléc beállítva a riport típusra")
    void testSubmitXml_reportTypeHeader() {
        ResponseEntity<String> okResponse = ResponseEntity.ok("<RefNum>REF-001</RefNum>");
        when(restTemplate.exchange(eq(TEST_URL), eq(HttpMethod.POST), any(HttpEntity.class), eq(String.class)))
            .thenReturn(okResponse);

        mnbApiClient.submitXml(TEST_XML, "WEEKLY");

        ArgumentCaptor<HttpEntity<String>> captor = ArgumentCaptor.forClass(HttpEntity.class);
        verify(restTemplate).exchange(eq(TEST_URL), eq(HttpMethod.POST), captor.capture(), eq(String.class));

        HttpHeaders headers = captor.getValue().getHeaders();
        assertThat(headers.getFirst("X-Report-Type")).isEqualTo("WEEKLY");
        assertThat(headers.getFirst("Authorization")).isEqualTo("Bearer " + TEST_TOKEN);
    }

    @Test
    @DisplayName("submitXml: hálózati hiba (RuntimeException) → success=false")
    void testSubmitXml_networkError_failure() {
        when(restTemplate.exchange(eq(TEST_URL), eq(HttpMethod.POST), any(HttpEntity.class), eq(String.class)))
            .thenThrow(new org.springframework.web.client.ResourceAccessException("Connection refused"));

        MnbSubmissionResult result = mnbApiClient.submitXml(TEST_XML, "MONTHLY");

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getErrorMessage()).containsIgnoringCase("hálózati");
    }
}
