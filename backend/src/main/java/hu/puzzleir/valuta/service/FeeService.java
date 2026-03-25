package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.FeeDiscount;
import hu.puzzleir.valuta.entity.FeeRate;
import hu.puzzleir.valuta.entity.FeeType;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.FeeDiscountRepository;
import hu.puzzleir.valuta.repository.FeeRateRepository;
import hu.puzzleir.valuta.repository.FeeTypeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FeeService {

    private final FeeTypeRepository feeTypeRepo;
    private final FeeRateRepository feeRateRepo;
    private final FeeDiscountRepository feeDiscountRepo;
    private final BranchRepository branchRepository;

    // --- FeeType ---

    public List<FeeType> listTypes() {
        return feeTypeRepo.findAll();
    }

    @Transactional(rollbackFor = Exception.class)
    public FeeType createType(FeeType entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return feeTypeRepo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public FeeType updateType(UUID id, FeeType entity) {
        FeeType existing = feeTypeRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Díjtípus nem található: " + id));
        existing.setCode(entity.getCode());
        existing.setName(entity.getName());
        existing.setDescription(entity.getDescription());
        existing.setCalculationMethod(entity.getCalculationMethod());
        existing.setIsActive(entity.getIsActive());
        return feeTypeRepo.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteType(UUID id) {
        feeTypeRepo.deleteById(id);
    }

    // --- FeeRate ---

    public List<FeeRate> listRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<UUID> branchIds = branchRepository.findByCompanyId(companyId).stream()
                .map(Branch::getId)
                .toList();
        if (branchIds.isEmpty()) {
            return List.of();
        }
        return feeRateRepo.findByBranchIdIn(branchIds);
    }

    @Transactional(rollbackFor = Exception.class)
    public FeeRate createRate(FeeRate entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return feeRateRepo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public FeeRate updateRate(UUID id, FeeRate entity) {
        FeeRate existing = feeRateRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Díjráta nem található: " + id));
        existing.setFeeTypeId(entity.getFeeTypeId());
        existing.setCurrencyId(entity.getCurrencyId());
        existing.setBranchId(entity.getBranchId());
        existing.setMinAmount(entity.getMinAmount());
        existing.setMaxAmount(entity.getMaxAmount());
        existing.setRate(entity.getRate());
        existing.setFixedAmount(entity.getFixedAmount());
        existing.setValidFrom(entity.getValidFrom());
        existing.setValidTo(entity.getValidTo());
        existing.setIsActive(entity.getIsActive());
        return feeRateRepo.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteRate(UUID id) {
        feeRateRepo.deleteById(id);
    }

    // --- FeeDiscount ---

    public List<FeeDiscount> listDiscounts() {
        return feeDiscountRepo.findAll();
    }

    @Transactional(rollbackFor = Exception.class)
    public FeeDiscount createDiscount(FeeDiscount entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return feeDiscountRepo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public FeeDiscount updateDiscount(UUID id, FeeDiscount entity) {
        FeeDiscount existing = feeDiscountRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Díjkedvezmény nem található: " + id));
        existing.setCode(entity.getCode());
        existing.setName(entity.getName());
        existing.setDiscountType(entity.getDiscountType());
        existing.setDiscountValue(entity.getDiscountValue());
        existing.setMinTransactionAmount(entity.getMinTransactionAmount());
        existing.setValidFrom(entity.getValidFrom());
        existing.setValidTo(entity.getValidTo());
        existing.setIsActive(entity.getIsActive());
        return feeDiscountRepo.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteDiscount(UUID id) {
        feeDiscountRepo.deleteById(id);
    }
}
