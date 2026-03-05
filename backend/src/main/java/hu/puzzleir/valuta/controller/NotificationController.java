package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Notification;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService service;

    @GetMapping
    public ResponseEntity<List<Notification>> list(Authentication auth) {
        return ResponseEntity.ok(service.listByUser(getUserId(auth)));
    }

    @GetMapping("/unread")
    public ResponseEntity<List<Notification>> getUnread(Authentication auth) {
        return ResponseEntity.ok(service.getUnread(getUserId(auth)));
    }

    @PostMapping("/{id}/mark-read")
    public ResponseEntity<Void> markAsRead(@PathVariable UUID id) {
        service.markAsRead(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/mark-all-read")
    public ResponseEntity<Void> markAllAsRead(Authentication auth) {
        service.markAllAsRead(getUserId(auth));
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    public ResponseEntity<Notification> send(@RequestBody Map<String, String> body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.send(
                body.get("userId"), body.get("title"), body.get("message"), body.get("type")));
    }

    private String getUserId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return String.valueOf(details.getWorkerId());
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }
}
