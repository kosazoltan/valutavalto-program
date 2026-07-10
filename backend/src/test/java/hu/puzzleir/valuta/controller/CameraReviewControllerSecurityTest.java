package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.camera.CreateMarkRequest;
import hu.puzzleir.valuta.dto.camera.ReviewStatusDto;
import hu.puzzleir.valuta.dto.camera.SetReviewStatusRequest;
import hu.puzzleir.valuta.entity.CameraReviewMark;
import hu.puzzleir.valuta.service.CameraReviewService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;

import java.lang.reflect.Method;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = CameraReviewControllerSecurityTest.TestConfig.class)
class CameraReviewControllerSecurityTest {

    private static final String REQUIRED_AUTH = "hasAnyAuthority('COMPLIANCE_OFFICER', 'REGIONAL_MANAGER', 'SYSTEM_ADMIN')";
    private static final UUID BRANCH_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID MARK_ID = UUID.fromString("55555555-5555-5555-5555-555555555555");
    private static final LocalDate REVIEW_DATE = LocalDate.of(2026, 7, 10);

    @Autowired private CameraReviewController controller;
    @Autowired private CameraReviewService service;

    @BeforeEach
    void setUp() {
        reset(service);
    }

    @Test
    void everyHandlerMethodHasReviewAuthorities() {
        Stream.of(CameraReviewController.class.getDeclaredMethods())
                .filter(CameraReviewControllerSecurityTest::isHandlerMethod)
                .forEach(method -> {
                    PreAuthorize preAuthorize = method.getAnnotation(PreAuthorize.class);
                    assertThat(preAuthorize)
                            .as(method.getName() + " must be protected")
                            .isNotNull();
                    assertThat(preAuthorize.value()).isEqualTo(REQUIRED_AUTH);
                });
    }

    @Test
    @WithMockUser(authorities = "COMPLIANCE_OFFICER")
    void overview_allowsComplianceOfficerAndDelegates() {
        when(service.overview(REVIEW_DATE, REVIEW_DATE, BRANCH_ID, true)).thenReturn(java.util.List.of());

        controller.overview(REVIEW_DATE, REVIEW_DATE, BRANCH_ID, true);

        verify(service).overview(REVIEW_DATE, REVIEW_DATE, BRANCH_ID, true);
    }

    @Test
    @WithMockUser(authorities = "REGIONAL_MANAGER")
    void createMark_allowsRegionalManagerAndDelegates() {
        CreateMarkRequest request = new CreateMarkRequest();
        when(service.createMark(request)).thenReturn(CameraReviewMark.builder()
                .id(MARK_ID)
                .branchId(BRANCH_ID)
                .reviewDate(REVIEW_DATE)
                .cameraId("cam-1")
                .markTime(LocalTime.of(8, 5, 7))
                .openingClosingOk(true)
                .invoicesOk(true)
                .breaksOk(true)
                .boardOk(true)
                .curtainOk(true)
                .build());

        controller.createMark(request);

        verify(service).createMark(request);
    }

    @Test
    @WithMockUser(authorities = "SYSTEM_ADMIN")
    void status_allowsSystemAdminAndDelegates() {
        when(service.getReviewStatus(BRANCH_ID, REVIEW_DATE)).thenReturn(ReviewStatusDto.builder().reviewed(false).build());

        controller.getStatus(BRANCH_ID, REVIEW_DATE);

        verify(service).getReviewStatus(BRANCH_ID, REVIEW_DATE);
    }

    @Test
    @WithMockUser(authorities = "CASHIER")
    void deleteMark_deniesCashierBeforeServiceCall() {
        assertThrows(AccessDeniedException.class, () -> controller.deleteMark(MARK_ID));

        verify(service, never()).deleteMark(any());
    }

    @Test
    @WithMockUser(authorities = "CASHIER")
    void setStatus_deniesCashierBeforeServiceCall() {
        SetReviewStatusRequest request = new SetReviewStatusRequest();
        request.setBranchId(BRANCH_ID);
        request.setReviewDate(REVIEW_DATE);
        request.setReviewed(true);

        assertThrows(AccessDeniedException.class, () -> controller.setStatus(request));

        verify(service, never()).setReviewStatus(any(), any(), eq(true));
    }

    private static boolean isHandlerMethod(Method method) {
        return method.isAnnotationPresent(GetMapping.class)
                || method.isAnnotationPresent(PostMapping.class)
                || method.isAnnotationPresent(PutMapping.class)
                || method.isAnnotationPresent(DeleteMapping.class);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        CameraReviewService cameraReviewService() {
            return mock(CameraReviewService.class);
        }

        @Bean
        CameraReviewController cameraReviewController(CameraReviewService service) {
            return new CameraReviewController(service);
        }
    }
}
