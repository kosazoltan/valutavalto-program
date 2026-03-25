package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.entity.ProhibitedCompany;
import hu.puzzleir.valuta.entity.ProhibitedPerson;
import hu.puzzleir.valuta.repository.ProhibitedCompanyRepository;
import hu.puzzleir.valuta.repository.ProhibitedPersonRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BlacklistService {

    private final ProhibitedPersonRepository personRepo;
    private final ProhibitedCompanyRepository companyRepo;

    // --- Persons ---

    public List<ProhibitedPerson> listPersons() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return personRepo.findAllByCompanyId(companyId);
    }

    @Transactional(rollbackFor = Exception.class)
    public ProhibitedPerson createPerson(ProhibitedPerson entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return personRepo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public ProhibitedPerson updatePerson(UUID id, ProhibitedPerson entity) {
        ProhibitedPerson existing = personRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Tiltott személy nem található: " + id));
        existing.setFullName(entity.getFullName());
        existing.setDocumentNumber(entity.getDocumentNumber());
        existing.setIdentityNumber(entity.getIdentityNumber());
        existing.setPassportNumber(entity.getPassportNumber());
        existing.setDateOfBirth(entity.getDateOfBirth());
        existing.setNationality(entity.getNationality());
        existing.setListType(entity.getListType());
        existing.setListSource(entity.getListSource());
        existing.setReason(entity.getReason());
        existing.setIsActive(entity.getIsActive());
        return personRepo.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void deletePerson(UUID id) {
        personRepo.deleteById(id);
    }

    @Transactional(rollbackFor = Exception.class)
    public List<ProhibitedPerson> importPersonsCsv(MultipartFile file) {
        List<ProhibitedPerson> imported = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            boolean header = true;
            while ((line = reader.readLine()) != null) {
                if (header) { header = false; continue; }
                String[] parts = line.split(";", -1);
                if (parts.length < 3) continue;
                ProhibitedPerson p = ProhibitedPerson.builder()
                        .fullName(parts[0].trim())
                        .documentNumber(parts.length > 1 ? parts[1].trim() : null)
                        .identityNumber(parts.length > 2 ? parts[2].trim() : null)
                        .passportNumber(parts.length > 3 ? parts[3].trim() : null)
                        .dateOfBirth(parts.length > 4 && !parts[4].isBlank() ? LocalDate.parse(parts[4].trim()) : null)
                        .nationality(parts.length > 5 ? parts[5].trim() : null)
                        .listType(parts.length > 6 ? parts[6].trim() : null)
                        .listSource(parts.length > 7 ? parts[7].trim() : null)
                        .reason(parts.length > 8 ? parts[8].trim() : null)
                        .isActive(true)
                        .build();
                imported.add(personRepo.save(p));
            }
        } catch (Exception e) {
            throw new BusinessException("CSV import hiba: " + e.getMessage(), "CSV_IMPORT_FAILED");
        }
        return imported;
    }

    // --- Companies ---

    public List<ProhibitedCompany> listCompanies() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return companyRepo.findAllByCompanyId(companyId);
    }

    @Transactional(rollbackFor = Exception.class)
    public ProhibitedCompany createCompany(ProhibitedCompany entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return companyRepo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public ProhibitedCompany updateCompany(UUID id, ProhibitedCompany entity) {
        ProhibitedCompany existing = companyRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Tiltott cég nem található: " + id));
        existing.setCompanyName(entity.getCompanyName());
        existing.setTaxNumber(entity.getTaxNumber());
        existing.setRegistrationNumber(entity.getRegistrationNumber());
        existing.setListType(entity.getListType());
        existing.setListSource(entity.getListSource());
        existing.setReason(entity.getReason());
        existing.setIsActive(entity.getIsActive());
        return companyRepo.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteCompany(UUID id) {
        companyRepo.deleteById(id);
    }

    @Transactional(rollbackFor = Exception.class)
    public List<ProhibitedCompany> importCompaniesCsv(MultipartFile file) {
        List<ProhibitedCompany> imported = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            boolean header = true;
            while ((line = reader.readLine()) != null) {
                if (header) { header = false; continue; }
                String[] parts = line.split(";", -1);
                if (parts.length < 2) continue;
                ProhibitedCompany c = ProhibitedCompany.builder()
                        .companyName(parts[0].trim())
                        .taxNumber(parts.length > 1 ? parts[1].trim() : null)
                        .registrationNumber(parts.length > 2 ? parts[2].trim() : null)
                        .listType(parts.length > 3 ? parts[3].trim() : null)
                        .listSource(parts.length > 4 ? parts[4].trim() : null)
                        .reason(parts.length > 5 ? parts[5].trim() : null)
                        .isActive(true)
                        .build();
                imported.add(companyRepo.save(c));
            }
        } catch (Exception e) {
            throw new BusinessException("CSV import hiba: " + e.getMessage(), "CSV_IMPORT_FAILED");
        }
        return imported;
    }
}
