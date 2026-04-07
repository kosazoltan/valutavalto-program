package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Email értesítési szolgáltatás.
 * 
 * Az in-app NotificationService mellé email küldési képesség.
 * Aszinkron — nem blokkolja a hívó szálat.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailNotificationService {

    private final JavaMailSender mailSender;
    private final WorkerRepository workerRepository;

    @Value("${spring.mail.username:noraautomatizalas@gmail.com}")
    private String fromAddress;

    @Value("${app.notification.email.enabled:true}")
    private boolean emailEnabled;

    @Value("${app.notification.email.subject-prefix:[Valutaváltó]}")
    private String subjectPrefix;

    /**
     * Email küldése egy worker-nek (ha van email címe).
     */
    @Async
    public void sendToWorker(Long workerId, String subject, String body) {
        if (!emailEnabled) {
            log.debug("Email notification kikapcsolva, skip: worker={}", workerId);
            return;
        }

        workerRepository.findById(workerId).ifPresent(worker -> {
            if (worker.getEmail() != null && !worker.getEmail().isBlank()) {
                sendEmail(worker.getEmail(), subject, body);
            } else {
                log.debug("Worker-nek nincs email címe: id={}, code={}", workerId, worker.getCode());
            }
        });
    }

    /**
     * Email küldése egy iroda összes aktív dolgozójának.
     */
    @Async
    public void sendToBranch(UUID branchId, String subject, String body) {
        if (!emailEnabled) return;

        List<Worker> workers = workerRepository.findActiveWorkersByBranch(branchId);
        int sent = 0;
        for (Worker w : workers) {
            if (w.getEmail() != null && !w.getEmail().isBlank()) {
                sendEmail(w.getEmail(), subject, body);
                sent++;
            }
        }
        log.info("Email értesítés küldve irodának: branchId={}, sent={}/{}", branchId, sent, workers.size());
    }

    /**
     * Email küldése tetszőleges címre.
     */
    @Async
    public void sendEmail(String to, String subject, String body) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(to);
            message.setSubject(subjectPrefix + " " + subject);
            message.setText(body);
            mailSender.send(message);
            log.info("Email elküldve: to={}, subject={}", to, subject);
        } catch (Exception e) {
            log.error("Email küldés sikertelen: to={}, subject={}, error={}", to, subject, e.getMessage());
        }
    }
}
