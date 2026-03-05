package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.OwnCompany;
import hu.puzzleir.valuta.repository.OwnCompanyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OwnCompanyService {

    private final OwnCompanyRepository repo;

    public List<OwnCompany> listAll() {
        return repo.findAll();
    }

    public List<OwnCompany> listActive() {
        return repo.findByIsActiveTrue();
    }

    public OwnCompany getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Saját cég nem található: " + id));
    }

    @Transactional
    public OwnCompany create(OwnCompany entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return repo.save(entity);
    }

    @Transactional
    public OwnCompany update(UUID id, OwnCompany entity) {
        OwnCompany existing = getById(id);
        existing.setName(entity.getName());
        existing.setTaxNumber(entity.getTaxNumber());
        existing.setRegistrationNumber(entity.getRegistrationNumber());
        existing.setAddress(entity.getAddress());
        existing.setPhone(entity.getPhone());
        existing.setEmail(entity.getEmail());
        existing.setBankAccountNumber(entity.getBankAccountNumber());
        existing.setIban(entity.getIban());
        existing.setSwift(entity.getSwift());
        existing.setLicenseNumber(entity.getLicenseNumber());
        existing.setIsActive(entity.getIsActive());
        return repo.save(existing);
    }

    @Transactional
    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
