package hu.puzzleir.valuta.security;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ErrorResponse;
import hu.puzzleir.valuta.repository.CompanyRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Defense-in-depth cross-check for protected write requests from offline clients.
 *
 * <p>The JWT-derived company remains the only tenant source. The optional
 * X-Company-Code header can only reject a request when it contradicts the
 * authenticated worker's company code.</p>
 */
@Component
public class CompanyCodeCrossCheckFilter extends OncePerRequestFilter {

    public static final String COMPANY_CODE_HEADER = "X-Company-Code";

    private final CompanyRepository companyRepository;
    private final ObjectMapper objectMapper;

    public CompanyCodeCrossCheckFilter(CompanyRepository companyRepository, ObjectMapper objectMapper) {
        this.companyRepository = companyRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return ProtectedWritePaths.shouldNotFilter(request);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String claimedCompanyCode = request.getHeader(COMPANY_CODE_HEADER);
        if (!StringUtils.hasText(claimedCompanyCode)) {
            filterChain.doFilter(request, response);
            return;
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
                || !(authentication.getDetails() instanceof WorkerAuthenticationDetails details)
                || details.getCompanyId() == null) {
            filterChain.doFilter(request, response);
            return;
        }

        String tokenCompanyCode = companyRepository.findById(details.getCompanyId())
                .map(Company::getCode)
                .filter(StringUtils::hasText)
                .orElse(null);

        if (tokenCompanyCode == null || !tokenCompanyCode.trim().equalsIgnoreCase(claimedCompanyCode.trim())) {
            writeCompanyMismatchResponse(response, claimedCompanyCode, tokenCompanyCode, details);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private void writeCompanyMismatchResponse(HttpServletResponse response,
                                              String claimedCompanyCode,
                                              String tokenCompanyCode,
                                              WorkerAuthenticationDetails details) throws IOException {
        String claimed = claimedCompanyCode.trim();
        String token = StringUtils.hasText(tokenCompanyCode) ? tokenCompanyCode.trim() : "ismeretlen";
        logger.warn(String.format(
                "Company code mismatch rejected: workerId=%s claimedCompanyCode=%s tokenCompanyCode=%s",
                details.getWorkerId(), sanitizeForLog(claimed), sanitizeForLog(token)));

        ErrorResponse errorResponse = ErrorResponse.builder()
                .status(HttpStatus.CONFLICT.value())
                .error("CONFLICT")
                .message("Cégeltérés: a kérés a(z) '" + claimed
                        + "' cégre hivatkozik, a bejelentkezett munkatárs a(z) '"
                        + token + "' céghez tartozik — a művelet elutasítva")
                .build();

        response.setStatus(HttpStatus.CONFLICT.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
    }

    private String sanitizeForLog(String value) {
        return value.replace('\n', '_').replace('\r', '_');
    }
}
