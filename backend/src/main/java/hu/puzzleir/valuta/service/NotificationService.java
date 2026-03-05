package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Notification;
import hu.puzzleir.valuta.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository repo;

    public List<Notification> listByUser(String userId) {
        return repo.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<Notification> getUnread(String userId) {
        return repo.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public void markAsRead(UUID id) {
        Notification n = repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Értesítés nem található: " + id));
        n.setIsRead(true);
        repo.save(n);
    }

    @Transactional
    public void markAllAsRead(String userId) {
        repo.markAllAsRead(userId);
    }

    @Transactional
    public Notification send(String userId, String title, String message, String type) {
        Notification n = Notification.builder()
                .userId(userId).title(title).message(message)
                .type(type).isRead(false).build();
        return repo.save(n);
    }
}
