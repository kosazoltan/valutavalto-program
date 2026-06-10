package hu.puzzleir.valuta.dto.bankapi;

import hu.puzzleir.valuta.entity.BankApiAuthType;
import hu.puzzleir.valuta.entity.BankApiMode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateBankApiConfigRequest {

    @NotNull
    private BankApiMode mode;

    @Size(max = 2000)
    private String endpointUrl;

    @NotNull
    private BankApiAuthType authType;

    @Size(max = 255)
    private String clientId;

    @Size(max = 4000)
    private String clientSecret;

    @Size(max = 255)
    private String mtlsCertificateAlias;

    @NotBlank
    @Size(max = 120)
    private String updateFrequency;

    @NotNull
    private Boolean enabled;
}
