package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SupervisorServiceConfigTest {

    private static final String VALID_TEST_HASH =
            new BCryptPasswordEncoder(4).encode("test-only-supervisor-password");

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"  ", "CHANGE-ME-supervisor-hash", "not-a-hash"})
    void validateSupervisorHash_rejectsInvalidHashInProduction(String hash) {
        SupervisorService service = createService(hash, productionEnvironment(), mock(PasswordEncoder.class));

        assertThrows(IllegalStateException.class, service::validateSupervisorHash);
    }

    @Test
    void validateSupervisorHash_acceptsBcryptHashInProduction() {
        SupervisorService service = createService(
                VALID_TEST_HASH, productionEnvironment(), mock(PasswordEncoder.class));

        assertDoesNotThrow(service::validateSupervisorHash);
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"  "})
    void validateSupervisorHash_allowsMissingHashOutsideProduction(String hash) {
        SupervisorService service = createService(hash, new MockEnvironment(), mock(PasswordEncoder.class));

        assertDoesNotThrow(service::validateSupervisorHash);
    }

    @Test
    void validateSupervisorHash_acceptsBcryptHashOutsideProduction() {
        SupervisorService service = createService(
                VALID_TEST_HASH, new MockEnvironment(), mock(PasswordEncoder.class));

        assertDoesNotThrow(service::validateSupervisorHash);
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   "})
    void authenticate_returnsFalseWithoutConfiguredHash(String hash) {
        PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
        SupervisorService service = createService(hash, new MockEnvironment(), passwordEncoder);

        assertFalse(service.authenticate("anything"));
        verify(passwordEncoder, never()).matches(any(), any());
    }

    @Test
    void authenticate_delegatesForConfiguredHashAndReturnsTrueOnMatch() {
        PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
        when(passwordEncoder.matches("x", VALID_TEST_HASH)).thenReturn(true);
        SupervisorService service = createService(VALID_TEST_HASH, new MockEnvironment(), passwordEncoder);

        assertTrue(service.authenticate("x"));
        verify(passwordEncoder).matches("x", VALID_TEST_HASH);
    }

    @Test
    void authenticate_delegatesForConfiguredHashAndReturnsFalseOnMismatch() {
        PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
        when(passwordEncoder.matches("wrong", VALID_TEST_HASH)).thenReturn(false);
        SupervisorService service = createService(VALID_TEST_HASH, new MockEnvironment(), passwordEncoder);

        assertFalse(service.authenticate("wrong"));
        verify(passwordEncoder).matches("wrong", VALID_TEST_HASH);
    }

    private static MockEnvironment productionEnvironment() {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("production");
        return environment;
    }

    private static SupervisorService createService(
            String hash, MockEnvironment environment, PasswordEncoder passwordEncoder) {
        SupervisorService service = new SupervisorService(
                mock(SystemParameterRepository.class),
                mock(TransactionRepository.class),
                mock(ExchangeRateRepository.class),
                mock(AuditLogService.class),
                passwordEncoder,
                environment);
        ReflectionTestUtils.setField(service, "supervisorPasswordHash", hash);
        return service;
    }
}
