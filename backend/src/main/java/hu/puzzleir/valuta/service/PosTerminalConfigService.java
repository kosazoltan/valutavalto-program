package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.PosTerminal;
import hu.puzzleir.valuta.repository.PosTerminalRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * POS terminál konfiguráció feloldó.
 *
 * Host és port meghatározása a következő prioritás szerint:
 *  1. PosTerminal DB rekord (pos_terminal.ip_address / port)
 *  2. application.properties alapértelmezett (pos.terminal.default.host / pos.terminal.default.port)
 *
 * Legacy: HARDWARE tábla POSHOST / POSPORT mezők.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class PosTerminalConfigService {

    private final PosTerminalRepository posTerminalRepository;

    @Value("${pos.terminal.default.host:127.0.0.1}")
    private String defaultHost;

    @Value("${pos.terminal.default.port:9100}")
    private int defaultPort;

    /**
     * Terminál cím feloldása UUID alapján.
     *
     * @param terminalId a PosTerminal UUID azonosítója
     * @return host és port rekord
     * @throws IllegalArgumentException ha a terminál nem található és nincs érvényes default
     */
    public TerminalAddress resolve(UUID terminalId) {
        if (terminalId != null) {
            UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
            Optional<PosTerminal> opt = branchId != null
                    ? posTerminalRepository.findByIdAndBranchId(terminalId, branchId)
                    : posTerminalRepository.findById(terminalId);
            if (opt.isPresent()) {
                PosTerminal terminal = opt.get();
                String host = (terminal.getIpAddress() != null && !terminal.getIpAddress().isBlank())
                    ? terminal.getIpAddress() : defaultHost;
                int port = (terminal.getPort() != null && terminal.getPort() > 0)
                    ? terminal.getPort() : defaultPort;
                log.debug("PosTerminalConfigService: terminál UUID={} → {}:{}", terminalId, host, port);
                return new TerminalAddress(host, port);
            }
            log.warn("PosTerminalConfigService: terminál nem található UUID={}, default használata", terminalId);
        }
        log.debug("PosTerminalConfigService: default cím → {}:{}", defaultHost, defaultPort);
        return new TerminalAddress(defaultHost, defaultPort);
    }

    /**
     * Alapértelmezett cím visszaadása (konfig alapján).
     */
    public TerminalAddress resolveDefault() {
        return resolve(null);
    }

    /**
     * Terminál cím (host + port) értékobjektum.
     */
    public record TerminalAddress(String host, int port) {}
}
