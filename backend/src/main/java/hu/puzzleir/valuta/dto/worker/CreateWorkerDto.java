package hu.puzzleir.valuta.dto.worker;

import hu.puzzleir.valuta.entity.WorkerRole;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Worker létrehozás DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateWorkerDto {
    
    @NotNull(message = "Company ID kötelező")
    private UUID companyId;
    
    @NotBlank(message = "Pénztáros kód kötelező")
    @Size(max = 10, message = "Kód maximum 10 karakter")
    private String code;
    
    @NotBlank(message = "Név kötelező")
    @Size(max = 100, message = "Név maximum 100 karakter")
    private String name;
    
    @NotBlank(message = "Jelszó kötelező")
    @Size(min = 4, message = "Jelszó minimum 4 karakter")
    private String password;
    
    @NotNull(message = "Szerepkör kötelező")
    private WorkerRole role;
    
    @NotNull(message = "Iroda ID kötelező")
    private UUID branchId;
    
    @Size(max = 20, message = "Telefonszám maximum 20 karakter")
    private String phone;
    
    @Size(max = 100, message = "Email maximum 100 karakter")
    private String email;
    
    private String otpUserId;
    private Boolean otpEnabled;
}
