package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.customer.CreateCustomerDto;
import hu.puzzleir.valuta.dto.customer.CustomerDto;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.service.CustomerService;
import org.springframework.stereotype.Component;

/**
 * Customer entity <-> DTO mapper
 */
@Component
public class CustomerMapper {

    public CustomerDto toDto(Customer entity) {
        if (entity == null) return null;

        return CustomerDto.builder()
                .id(entity.getId())
                .customerCode(entity.getCustomerCode())
                .name(entity.getName())
                .birthName(entity.getBirthName())
                .motherName(entity.getMotherName())
                .birthDate(entity.getBirthDate())
                .birthPlace(entity.getBirthPlace())
                .nationality(entity.getNationality())
                .documentNumber(entity.getDocumentNumber())
                .documentType(entity.getDocumentType())
                .documentExpiry(entity.getDocumentExpiry())
                .address(entity.getAddress())
                .postalCode(entity.getPostalCode())
                .city(entity.getCity())
                .country(entity.getCountry())
                .phone(entity.getPhone())
                .email(entity.getEmail())
                .isCompany(entity.getIsCompany())
                .companyName(entity.getCompanyName())
                .taxNumber(entity.getTaxNumber())
                .registrationNumber(entity.getRegistrationNumber())
                .active(entity.getActive())
                .isVip(entity.getIsVip())
                .notes(entity.getNotes())
                .lastTransactionDate(entity.getLastTransactionDate())
                .transactionCount(entity.getTransactionCount())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    public CustomerService.CreateCustomerRequest toCreateRequest(CreateCustomerDto dto) {
        return CustomerService.CreateCustomerRequest.builder()
                .name(dto.getName())
                .birthName(dto.getBirthName())
                .motherName(dto.getMotherName())
                .birthDate(dto.getBirthDate())
                .birthPlace(dto.getBirthPlace())
                .nationality(dto.getNationality())
                .documentNumber(dto.getDocumentNumber())
                .documentType(dto.getDocumentType())
                .documentExpiry(dto.getDocumentExpiry())
                .address(dto.getAddress())
                .postalCode(dto.getPostalCode())
                .city(dto.getCity())
                .country(dto.getCountry())
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .isCompany(dto.getIsCompany())
                .companyName(dto.getCompanyName())
                .taxNumber(dto.getTaxNumber())
                .registrationNumber(dto.getRegistrationNumber())
                .isVip(dto.getIsVip())
                .notes(dto.getNotes())
                .build();
    }

    public CustomerService.UpdateCustomerRequest toUpdateRequest(CreateCustomerDto dto) {
        return CustomerService.UpdateCustomerRequest.builder()
                .name(dto.getName())
                .birthName(dto.getBirthName())
                .motherName(dto.getMotherName())
                .birthDate(dto.getBirthDate())
                .birthPlace(dto.getBirthPlace())
                .nationality(dto.getNationality())
                .documentNumber(dto.getDocumentNumber())
                .documentType(dto.getDocumentType())
                .documentExpiry(dto.getDocumentExpiry())
                .address(dto.getAddress())
                .postalCode(dto.getPostalCode())
                .city(dto.getCity())
                .country(dto.getCountry())
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .isCompany(dto.getIsCompany())
                .companyName(dto.getCompanyName())
                .taxNumber(dto.getTaxNumber())
                .registrationNumber(dto.getRegistrationNumber())
                .isVip(dto.getIsVip())
                .notes(dto.getNotes())
                .build();
    }
}
