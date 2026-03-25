package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.OwnCompany;
import hu.puzzleir.valuta.repository.OwnCompanyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findAllByCompanyId(companyId);
    }

    public List<OwnCompany> listActive() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findByCompanyIdAndIsActiveTrue(companyId);
    }

    public OwnCompany getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Saját cég nem található: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public OwnCompany create(OwnCompany entity) {
        entity.setId(null);
        entity.setCompanyId(SecurityUtils.getCurrentCompanyId());
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return repo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
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

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
