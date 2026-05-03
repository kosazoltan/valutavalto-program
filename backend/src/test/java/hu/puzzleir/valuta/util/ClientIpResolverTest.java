package hu.puzzleir.valuta.util;

import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Audit P1.4 SSOT egyseg-tesztek: a kliens IP feloldas trusted proxy-aware modon.
 *
 * <p>Bizonyitja:
 * <ul>
 *   <li>Trusted proxy peer + X-Forwarded-For elso hop -> a feloldott IP a XFF elso eleme</li>
 *   <li>Trusted proxy peer + nincs XFF + van X-Real-IP -> X-Real-IP</li>
 *   <li>Trusted proxy peer + nincs XFF + nincs X-Real-IP -> remoteAddr (fallback)</li>
 *   <li>NEM trusted peer + spoof XFF/X-Real-IP -> remoteAddr (header NEM bizott)</li>
 *   <li>Localhost (127.0.0.1, ::1) trusted by default</li>
 *   <li>RFC1918 magan (10/8, 172.16/12, 192.168/16) trusted by default</li>
 *   <li>Public IP NEM trusted by default</li>
 * </ul>
 */
class ClientIpResolverTest {

    private ClientIpResolver resolver;

    @BeforeEach
    void setUp() {
        resolver = new ClientIpResolver();
        ReflectionTestUtils.setField(resolver, "trustedProxyCidrs",
            List.of("127.0.0.1/32", "::1/128", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"));
    }

    @Test
    @DisplayName("Trusted proxy + XFF -> XFF elso hop")
    void trustedProxy_xffFirstHop() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("10.5.5.5");
        when(req.getHeader("X-Forwarded-For")).thenReturn("203.0.113.42, 10.5.5.5");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("203.0.113.42");
    }

    @Test
    @DisplayName("Trusted proxy + nincs XFF + X-Real-IP -> X-Real-IP")
    void trustedProxy_xRealIp() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("172.17.0.1");
        when(req.getHeader("X-Forwarded-For")).thenReturn(null);
        when(req.getHeader("X-Real-IP")).thenReturn("198.51.100.7");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("198.51.100.7");
    }

    @Test
    @DisplayName("Trusted proxy + nincs XFF + nincs X-Real-IP -> remoteAddr")
    void trustedProxy_noHeaders_remoteAddr() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("192.168.1.1");
        when(req.getHeader("X-Forwarded-For")).thenReturn(null);
        when(req.getHeader("X-Real-IP")).thenReturn(null);
        assertThat(resolver.resolveClientIp(req)).isEqualTo("192.168.1.1");
    }

    @Test
    @DisplayName("Spoofed XFF NEM trusted peer-rol IGNORED")
    void untrustedPeer_xffSpoofIgnored() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("203.0.113.99");
        when(req.getHeader("X-Forwarded-For")).thenReturn("198.51.100.1");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("203.0.113.99");
    }

    @Test
    @DisplayName("Localhost IPv4 alapertelmezetten trusted")
    void localhost_ipv4_trusted() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("127.0.0.1");
        when(req.getHeader("X-Forwarded-For")).thenReturn("203.0.113.5");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("203.0.113.5");
    }

    @Test
    @DisplayName("Localhost IPv6 alapertelmezetten trusted")
    void localhost_ipv6_trusted() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("::1");
        when(req.getHeader("X-Forwarded-For")).thenReturn("2001:db8::1");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("2001:db8::1");
    }

    @Test
    @DisplayName("RFC1918 10.x trusted")
    void rfc1918_10_trusted() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("10.255.255.255");
        when(req.getHeader("X-Forwarded-For")).thenReturn("203.0.113.50");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("203.0.113.50");
    }

    @Test
    @DisplayName("Public IP NEM trusted alapertelmezetten")
    void publicIp_notTrusted() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("8.8.8.8");
        when(req.getHeader("X-Forwarded-For")).thenReturn("1.1.1.1");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("8.8.8.8");
    }

    @Test
    @DisplayName("Empty trusted-proxies lista -> minden header IGNORED")
    void emptyTrustedProxies_allIgnored() {
        ClientIpResolver emptyResolver = new ClientIpResolver();
        ReflectionTestUtils.setField(emptyResolver, "trustedProxyCidrs", List.of());
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("127.0.0.1");
        when(req.getHeader("X-Forwarded-For")).thenReturn("203.0.113.5");
        assertThat(emptyResolver.resolveClientIp(req)).isEqualTo("127.0.0.1");
    }

    @Test
    @DisplayName("XFF whitespace + multi hop -> trim elso hop")
    void xffMultiHop_trimFirst() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getRemoteAddr()).thenReturn("10.0.0.1");
        when(req.getHeader("X-Forwarded-For")).thenReturn("  203.0.113.42  ,  10.0.0.1  ");
        assertThat(resolver.resolveClientIp(req)).isEqualTo("203.0.113.42");
    }
}
