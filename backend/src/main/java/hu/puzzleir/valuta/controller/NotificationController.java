package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.notification.BroadcastNotificationDto;
import hu.puzzleir.valuta.dto.notification.SendNotificationDto;
import hu.puzzleir.valuta.entity.Notification;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService service;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<Notification>> list(Authentication auth) {
        return ResponseEntity.ok(service.listByUser(getUserId(auth)));
    }

    @GetMapping("/unread")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<Notification>> getUnread(Authentication auth) {
        return ResponseEntity.ok(service.getUnread(getUserId(auth)));
    }

    @GetMapping("/unread-count")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Integer>> getUnreadCount(Authentication auth) {
        int count = service.getUnreadCount(getUserId(auth));
        return ResponseEntity.ok(Map.of("count", count));
    }

    @PostMapping("/{id}/mark-read")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> markAsRead(@PathVariable UUID id) {
        service.markAsRead(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/read")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> markRead(@PathVariable UUID id) {
        service.markAsRead(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/mark-all-read")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> markAllAsRead(Authentication auth) {
        service.markAllAsRead(getUserId(auth));
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Notification> send(@Valid @RequestBody Map<String, String> body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.send(
                body.get("userId"), body.get("title"), body.get("message"), body.get("type")));
    }

    @PostMapping("/send")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Notification> sendToWorker(@Valid @RequestBody SendNotificationDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
                service.sendToWorker(dto.getWorkerId(), dto.getTitle(), dto.getMessage(), dto.getType()));
    }

    @PostMapping("/broadcast")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Integer>> broadcast(@Valid @RequestBody BroadcastNotificationDto dto) {
        int count = service.sendToAll(dto.getTitle(), dto.getMessage());
        return ResponseEntity.ok(Map.of("sent", count));
    }

    private String getUserId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return String.valueOf(details.getWorkerId());
        }
        throw new hu.puzzleir.valuta.exception.ValidationException("Hitelesítés szükséges!");
    }
}
