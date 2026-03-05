package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Document;
import hu.puzzleir.valuta.repository.DocumentRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DocumentStorageService {

    private final DocumentRepository repo;

    public List<Document> list(String entityType, UUID entityId) {
        if (entityType != null && entityId != null) {
            return repo.findByEntityTypeAndEntityId(entityType, entityId);
        }
        if (entityType != null) {
            return repo.findByEntityType(entityType);
        }
        return repo.findAll();
    }

    public Document getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Dokumentum nem található: " + id));
    }

    @Transactional
    public Document upload(MultipartFile file, String entityType, UUID entityId) throws IOException {
        Document doc = Document.builder()
                .fileName(file.getOriginalFilename())
                .fileType(file.getContentType())
                .fileSize(file.getSize())
                .entityType(entityType)
                .entityId(entityId)
                .fileData(file.getBytes())
                .uploadedById(SecurityUtils.getCurrentWorkerId())
                .build();
        return repo.save(doc);
    }

    @Transactional
    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
