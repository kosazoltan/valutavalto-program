package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.printtemplate.PrintTemplateDto;
import hu.puzzleir.valuta.dto.printtemplate.PrintTemplateResponse;
import hu.puzzleir.valuta.entity.PrintTemplate;
import hu.puzzleir.valuta.entity.PrintTemplateType;
import hu.puzzleir.valuta.repository.PrintTemplateRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.exception.ValidationException;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Nyomtatási sablon szolgáltatás.
 * Sablonok CRUD + előnézet renderelés placeholder cserével.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PrintTemplateService {

    private final PrintTemplateRepository printTemplateRepository;

    /**
     * Sablon lekérdezés típus és cég szerint.
     * Ha nincs cég-specifikus, az alapértelmezettet adja vissza.
     */
    @Transactional(readOnly = true)
    public PrintTemplateResponse getTemplate(String type, Integer companyId) {
        PrintTemplateType templateType = parseTemplateType(type);

        // Először cég-specifikus keresés
        if (companyId != null) {
            return printTemplateRepository.findByTemplateTypeAndCompanyId(templateType, companyId)
                    .map(this::toResponse)
                    .orElseGet(() -> getDefaultByType(templateType));
        }

        return getDefaultByType(templateType);
    }

    private PrintTemplateResponse getDefaultByType(PrintTemplateType templateType) {
        return printTemplateRepository.findByTemplateTypeAndIsDefaultTrue(templateType)
                .map(this::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Nincs alapértelmezett sablon ehhez a típushoz: " + templateType));
    }

    /**
     * Sablon mentés/létrehozás.
     */
    @Transactional(rollbackFor = Exception.class)
    public PrintTemplateResponse saveTemplate(PrintTemplateDto dto) {
        PrintTemplate template = PrintTemplate.builder()
                .name(dto.getName())
                .templateType(parseTemplateType(dto.getTemplateType()))
                .content(dto.getContent())
                .isDefault(dto.getIsDefault() != null ? dto.getIsDefault() : false)
                .companyId(dto.getCompanyId())
                .build();

        template = printTemplateRepository.save(template);
        log.info("Nyomtatási sablon létrehozva: id={}, name={}, type={}", template.getId(), template.getName(), template.getTemplateType());
        return toResponse(template);
    }

    /**
     * Sablon frissítés.
     */
    @Transactional(rollbackFor = Exception.class)
    public PrintTemplateResponse updateTemplate(UUID id, PrintTemplateDto dto) {
        PrintTemplate template = printTemplateRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Sablon nem található: " + id));

        template.setName(dto.getName());
        template.setTemplateType(parseTemplateType(dto.getTemplateType()));
        template.setContent(dto.getContent());
        if (dto.getIsDefault() != null) {
            template.setIsDefault(dto.getIsDefault());
        }
        if (dto.getCompanyId() != null) {
            template.setCompanyId(dto.getCompanyId());
        }

        template = printTemplateRepository.save(template);
        log.info("Nyomtatási sablon frissítve: id={}, name={}", id, template.getName());
        return toResponse(template);
    }

    /**
     * Alapértelmezett sablonok listája.
     */
    @Transactional(readOnly = true)
    public List<PrintTemplateResponse> getDefaultTemplates() {
        return printTemplateRepository.findByIsDefaultTrue()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Sablonok listája típus szerint.
     */
    @Transactional(readOnly = true)
    public List<PrintTemplateResponse> getTemplatesByType(String type) {
        PrintTemplateType templateType = parseTemplateType(type);
        return printTemplateRepository.findByTemplateType(templateType)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Sablon lekérdezés ID alapján.
     */
    @Transactional(readOnly = true)
    public PrintTemplateResponse getTemplateById(UUID id) {
        PrintTemplate template = printTemplateRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Sablon nem található: " + id));
        return toResponse(template);
    }

    /**
     * Sablon előnézet — placeholder csere.
     * Placeholder formátum: {{kulcs}}
     */
    @Transactional(readOnly = true)
    public String previewTemplate(UUID templateId, Map<String, Object> data) {
        PrintTemplate template = printTemplateRepository.findById(templateId)
                .orElseThrow(() -> new ResourceNotFoundException("Sablon nem található: " + templateId));

        String rendered = template.getContent();
        if (rendered == null) return "";

        for (Map.Entry<String, Object> entry : data.entrySet()) {
            String placeholder = "{{" + entry.getKey() + "}}";
            String value = entry.getValue() != null ? entry.getValue().toString() : "";
            rendered = rendered.replace(placeholder, value);
        }

        return rendered;
    }

    private PrintTemplateType parseTemplateType(String type) {
        if (type == null || type.isBlank()) {
            throw new ValidationException("Sablon típus nem lehet üres");
        }
        try {
            return PrintTemplateType.valueOf(type.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ValidationException("Érvénytelen sablon típus: " + type);
        }
    }

    private PrintTemplateResponse toResponse(PrintTemplate entity) {
        return PrintTemplateResponse.builder()
                .id(entity.getId())
                .name(entity.getName())
                .templateType(entity.getTemplateType().name())
                .content(entity.getContent())
                .isDefault(entity.getIsDefault())
                .companyId(entity.getCompanyId())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
