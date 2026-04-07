package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Notification;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.NotificationRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository repo;
    private final WorkerRepository workerRepository;
    private final EmailNotificationService emailNotificationService;

    public List<Notification> listByUser(String userId) {
        return repo.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<Notification> getUnread(String userId) {
        return repo.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId);
    }

    public int getUnreadCount(String userId) {
        return repo.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId).size();
    }

    @Transactional(rollbackFor = Exception.class)
    public void markAsRead(UUID id) {
        Notification n = repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Értesítés nem található: " + id));
        n.setIsRead(true);
        repo.save(n);
    }

    @Transactional(rollbackFor = Exception.class)
    public void markAllAsRead(String userId) {
        repo.markAllAsRead(userId);
    }

    @Transactional(rollbackFor = Exception.class)
    public Notification send(String userId, String title, String message, String type) {
        Notification n = Notification.builder()
                .userId(userId).title(title).message(message)
                .type(type).isRead(false).build();
        return repo.save(n);
    }

    /**
     * Értesítés küldése egy worker-nek (in-app + email).
     */
    @Transactional(rollbackFor = Exception.class)
    public Notification sendToWorker(Long workerId, String title, String message, String type) {
        log.info("Értesítés küldése: worker={}, title={}, type={}", workerId, title, type);
        Notification n = send(String.valueOf(workerId), title, message, type != null ? type : "INFO");
        // Email is küldünk (aszinkron, nem blokkolja a tranzakciót)
        emailNotificationService.sendToWorker(workerId, title, message);
        return n;
    }

    /**
     * Értesítés küldése egy iroda összes aktív dolgozójának (in-app + email).
     */
    @Transactional(rollbackFor = Exception.class)
    public int sendToBranch(UUID branchId, String title, String message) {
        List<Worker> workers = workerRepository.findActiveWorkersByBranch(branchId);
        int count = 0;
        for (Worker w : workers) {
            send(String.valueOf(w.getId()), title, message, "INFO");
            count++;
        }
        log.info("Értesítés küldve iroda összes dolgozójának: branch={}, count={}", branchId, count);
        // Email is küldünk az irodának (aszinkron)
        emailNotificationService.sendToBranch(branchId, title, message);
        return count;
    }

    /**
     * Broadcast értesítés minden dolgozónak.
     */
    @Transactional(rollbackFor = Exception.class)
    public int sendToAll(String title, String message) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Worker> workers = workerRepository.findByCompanyId(companyId);
        int count = 0;
        for (Worker w : workers) {
            if (Boolean.TRUE.equals(w.getActive())) {
                send(String.valueOf(w.getId()), title, message, "SYSTEM");
                count++;
            }
        }
        log.info("Broadcast értesítés küldve: count={}", count);
        return count;
    }
}
