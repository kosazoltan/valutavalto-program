package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Notification;
import hu.puzzleir.valuta.repository.NotificationRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository repo;
    @Mock
    private WorkerRepository workerRepository;
    @Mock
    private EmailNotificationService emailNotificationService;

    @InjectMocks
    private NotificationService service;

    @Test
    void sendToWorkerPassesCurrentCompanyScopeToEmailNotification() {
        UUID companyId = UUID.randomUUID();
        when(repo.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);

            service.sendToWorker(7L, "Cím", "Üzenet", "INFO");

            verify(emailNotificationService).sendToWorker(7L, companyId, "Cím", "Üzenet");
        }
    }
}
