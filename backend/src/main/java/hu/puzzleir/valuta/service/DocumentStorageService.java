package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (entityType != null && entityId != null) {
            return repo.findByCompanyIdAndEntityTypeAndEntityId(companyId, entityType, entityId);
        }
        if (entityType != null) {
            return repo.findByCompanyIdAndEntityType(companyId, entityType);
        }
        return repo.findByCompanyId(companyId);
    }

    public Document getById(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Dokumentum nem található: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public Document upload(MultipartFile file, String entityType, UUID entityId) throws IOException {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Document doc = Document.builder()
                .fileName(file.getOriginalFilename())
                .fileType(file.getContentType())
                .fileSize(file.getSize())
                .entityType(entityType)
                .entityId(entityId)
                .fileData(file.getBytes())
                .uploadedById(SecurityUtils.getCurrentWorkerId())
                .companyId(companyId)
                .build();
        return repo.save(doc);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Document doc = repo.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Dokumentum nem található: " + id));
        repo.delete(doc);
    }
}
