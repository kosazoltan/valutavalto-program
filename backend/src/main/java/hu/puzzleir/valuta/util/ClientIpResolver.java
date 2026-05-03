package hu.puzzleir.valuta.util;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.InetAddress;
import java.util.Collections;
import java.util.List;

/**
 * Audit P1.4 SSOT: kliens IP feloldas trusted proxy-aware modon.
 *
 * <p>Egyetlen forras-igazsag a kliens-IP feloldasara. Korabban a
 * {@code RateLimitFilter} robust trusted-proxy CIDR check-csel oldotta meg,
 * de a {@code RefreshTokenService}, {@code ErrorLogController},
 * {@code AuthController}, {@code WorkerAttendanceController} naivan vakon
 * bizott a kliens X-Forwarded-For/getRemoteAddr ertekeben — security gap
 * (audit log spoofing).</p>
 *
 * <p>Ez az util biztositja az osszes hely ugyanazt a logikat hasznalja:
 * <ol>
 *   <li>Lekerdez {@code request.getRemoteAddr()}-t (kozvetlenul kapcsolodo peer)</li>
 *   <li>Ha a peer cime a trusted proxy CIDR-eken belul van -> {@code X-Forwarded-For} elso hop ertekevel folytat</li>
 *   <li>Ha XFF nincs/blank -> {@code X-Real-IP} fallback</li>
 *   <li>Ha a peer NEM trusted -> visszaadja a {@code remoteAddr}-t valtozatlanul (NEM bizik a header-ekben)</li>
 * </ol>
 * </p>
 *
 * <p>Konfiguracio: {@code client-ip.trusted-proxies} property (csv CIDR ranges).</p>
 */
@Component
@Slf4j
public class ClientIpResolver {

    /**
     * Trusted proxy CIDR ranges — only these sources may set X-Forwarded-For / X-Real-IP.
     * Default: localhost (v4 + v6) + RFC1918 magan-tartomanyok (Hetzner LB / nginx mogul).
     */
    @Value("${client-ip.trusted-proxies:127.0.0.1/32,::1/128,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}")
    private List<String> trustedProxyCidrs;

    private volatile List<CidrRange> parsedTrustedProxies;

    /**
     * Kliens IP feloldas a request-bol.
     * @return string IP — soha nem null (worst-case `request.getRemoteAddr()`).
     */
    public String resolveClientIp(HttpServletRequest request) {
        String remoteAddr = request.getRemoteAddr();
        if (isTrustedProxy(remoteAddr)) {
            String xff = request.getHeader("X-Forwarded-For");
            if (xff != null && !xff.isBlank()) {
                return xff.split(",")[0].trim();
            }
            String realIp = request.getHeader("X-Real-IP");
            if (realIp != null && !realIp.isBlank()) {
                return realIp;
            }
        }
        return remoteAddr;
    }

    private List<CidrRange> getTrustedProxies() {
        // Lazy init — Spring property injection AFTER constructor, ezert volatile cache
        if (parsedTrustedProxies == null) {
            if (trustedProxyCidrs == null || trustedProxyCidrs.isEmpty()) {
                parsedTrustedProxies = Collections.emptyList();
            } else {
                parsedTrustedProxies = trustedProxyCidrs.stream()
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .map(CidrRange::parse)
                        .filter(java.util.Objects::nonNull)
                        .toList();
            }
        }
        return parsedTrustedProxies;
    }

    private boolean isTrustedProxy(String remoteAddr) {
        try {
            InetAddress addr = InetAddress.getByName(remoteAddr);
            for (CidrRange cidr : getTrustedProxies()) {
                if (cidr.contains(addr)) {
                    return true;
                }
            }
        } catch (Exception e) {
            log.debug("Cannot resolve remote address for trusted proxy check: {}", remoteAddr);
        }
        return false;
    }

    /** Inner CIDR range parser — lokalis, NEM publicus API. */
    private static class CidrRange {
        private final byte[] network;
        private final int prefixLength;

        CidrRange(byte[] network, int prefixLength) {
            this.network = network;
            this.prefixLength = prefixLength;
        }

        static CidrRange parse(String cidr) {
            try {
                String[] parts = cidr.split("/");
                InetAddress addr = InetAddress.getByName(parts[0]);
                int prefix = parts.length > 1 ? Integer.parseInt(parts[1]) : (addr.getAddress().length * 8);
                return new CidrRange(addr.getAddress(), prefix);
            } catch (Exception e) {
                return null;
            }
        }

        boolean contains(InetAddress addr) {
            byte[] addrBytes = addr.getAddress();
            if (addrBytes.length != network.length) {
                return false; // IPv4 vs IPv6 mismatch
            }
            int fullBytes = prefixLength / 8;
            int remainingBits = prefixLength % 8;
            for (int i = 0; i < fullBytes; i++) {
                if (addrBytes[i] != network[i]) return false;
            }
            if (remainingBits > 0 && fullBytes < network.length) {
                int mask = (0xFF << (8 - remainingBits)) & 0xFF;
                if ((addrBytes[fullBytes] & mask) != (network[fullBytes] & mask)) return false;
            }
            return true;
        }
    }
}
