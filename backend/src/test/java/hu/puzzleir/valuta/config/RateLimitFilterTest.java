package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.util.ClientIpResolver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RateLimitFilterTest {

    private RateLimitFilter filter;
    private ClientIpResolver clientIpResolver;

    @BeforeEach
    void setUp() {
        clientIpResolver = Mockito.mock(ClientIpResolver.class);
        // Audit P1.4 default: a `resolveClientIp` visszaad a request remoteAddr-jet
        Mockito.when(clientIpResolver.resolveClientIp(Mockito.any())).thenAnswer(inv -> {
            jakarta.servlet.http.HttpServletRequest req = inv.getArgument(0);
            return req == null ? "0.0.0.0" : req.getRemoteAddr();
        });
        filter = new RateLimitFilter(clientIpResolver);
        ReflectionTestUtils.setField(filter, "loginMaxRequests", 10);
        ReflectionTestUtils.setField(filter, "loginWindowMs", 60_000L);
        ReflectionTestUtils.setField(filter, "transactionMaxRequests", 1);
        ReflectionTestUtils.setField(filter, "transactionWindowMs", 60_000L);
        ReflectionTestUtils.setField(filter, "paymentMaxRequests", 3);
        ReflectionTestUtils.setField(filter, "paymentWindowMs", 60_000L);
    }

    @Test
    @DisplayName("POS payment endpoint uses dedicated higher limit")
    void posPaymentEndpoint_usesDedicatedHigherLimit() throws Exception {
        assertPassed(post("/api/v1/pos-terminal/process-transaction"));
        assertPassed(post("/api/v1/pos-terminal/process-transaction"));
        assertPassed(post("/api/v1/pos-terminal/process-transaction"));

        ResponseResult blocked = post("/api/v1/pos-terminal/process-transaction");
        assertBlocked(blocked, "Túl sok fizetési kérés");
    }

    @Test
    @DisplayName("Standard transaction endpoint still uses transaction limit")
    void standardTransactionEndpoint_usesTransactionLimit() throws Exception {
        assertPassed(post("/api/v1/transactions/buy"));

        ResponseResult blocked = post("/api/v1/transactions/buy");
        assertBlocked(blocked, "Túl sok tranzakciós kérés");
    }

    private ResponseResult post(String path) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", path);
        request.setRemoteAddr("127.0.0.1");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);
        return new ResponseResult(response, chain.getRequest() != null);
    }

    private void assertPassed(ResponseResult result) {
        assertTrue(result.passedRequest);
        assertEquals(200, result.response.getStatus());
    }

    private void assertBlocked(ResponseResult result, String expectedMessage) throws Exception {
        assertFalse(result.passedRequest);
        assertEquals(429, result.response.getStatus());
        assertTrue(result.response.getContentAsString().contains(expectedMessage));
    }

    private record ResponseResult(MockHttpServletResponse response, boolean passedRequest) {
    }
}
