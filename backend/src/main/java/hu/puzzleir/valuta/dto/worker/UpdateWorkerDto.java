package hu.puzzleir.valuta.dto.worker;

import hu.puzzleir.valuta.entity.WorkerRole;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Worker módosítás DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateWorkerDto {
    
    @Size(max = 100, message = "Név maximum 100 karakter")
    private String name;
    
    private WorkerRole role;
    
    private UUID branchId;
    
    @Size(max = 20, message = "Telefonszám maximum 20 karakter")
    private String phone;
    
    @Size(max = 100, message = "Email maximum 100 karakter")
    private String email;
    
    private Boolean active;
    
    private String otpUserId;
    private Boolean otpEnabled;
}
