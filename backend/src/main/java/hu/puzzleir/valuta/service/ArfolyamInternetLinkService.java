package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ArfolyamInternetLink;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ArfolyamInternetLinkRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Árfolyamkészítő internet-link (legacy ARFOLYAM / TINTERNETTMKFORM, Unit2.pas) — multi-tenant.
 *
 * <p>Lista + felvétel (egyedi gombszám-kényszer, a legacy "X SZÁMÚ GOMB MÁR KI VAN
 * OSZTVA" üzenet parity) + törlés (IDOR-guard).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class ArfolyamInternetLinkService {

    private final ArfolyamInternetLinkRepository repository;
    private final CompanyRepository companyRepository;

    public List<ArfolyamInternetLink> list() {
        return repository.findByCompanyIdOrderByButtonNumberAsc(SecurityUtils.getCurrentCompanyId());
    }

    @Transactional
    public ArfolyamInternetLink create(Integer buttonNumber, String label, String url) {
        if (buttonNumber == null) {
            throw new ValidationException("A gombszám kötelező!");
        }
        if (label == null || label.isBlank()) {
            throw new ValidationException("A gomb felirata kötelező!");
        }
        if (url == null || url.isBlank()) {
            throw new ValidationException("Az internetcím (URL) kötelező!");
        }
        // Biztonsági guard: csak http/https séma engedett (javascript:/data: open-redirect+XSS tiltva)
        String normalizedUrl = url.trim();
        if (!normalizedUrl.matches("(?i)^https?://\\S+$")) {
            throw new ValidationException("Az internetcím csak http:// vagy https:// címmel kezdődhet!");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Legacy gombszám-egyediség: "X SZÁMÚ GOMB MÁR KI VAN OSZTVA. VÁLASSZON MÁSIKAT"
        repository.findByCompanyIdAndButtonNumber(companyId, buttonNumber).ifPresent(existing -> {
            throw new ValidationException(buttonNumber + " számú gomb már ki van osztva, válasszon másikat!");
        });
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található"));
        return repository.save(ArfolyamInternetLink.builder()
                .company(company)
                .buttonNumber(buttonNumber)
                .label(label.trim())
                .url(normalizedUrl)
                .build());
    }

    @Transactional
    public void delete(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        ArfolyamInternetLink entity = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Internet-link nem található"));
        // IDOR-védelem: csak a saját cég linkje törölhető
        if (entity.getCompany() == null || !companyId.equals(entity.getCompany().getId())) {
            throw new ResourceNotFoundException("Internet-link nem található");
        }
        repository.delete(entity);
    }
}
