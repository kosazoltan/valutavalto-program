package hu.puzzleir.valuta.dto.cashregister;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class RegisterCashRegisterDeviceRequest {

    @NotNull(message = "A branchId kotelezo")
    private UUID branchId;

    @NotBlank(message = "A penztar code kotelezo")
    @Size(max = 40)
    private String code;

    @Size(max = 200)
    private String name;

    @Size(max = 30)
    private String appMode;   // penztar | ertektar | ertekszallito | full

    @Size(max = 30)
    private String appVersion;

    @Size(max = 255)
    private String deviceFingerprint;

    @Size(max = 255)
    private String osInfo;
}