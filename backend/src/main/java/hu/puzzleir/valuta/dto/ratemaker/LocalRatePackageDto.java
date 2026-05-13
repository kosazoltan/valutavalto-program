package hu.puzzleir.valuta.dto.ratemaker;

import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LocalRatePackageDto {
    @NotBlank(message = "Helyi csomagazonosító kötelező")
    private String clientPackageId;

    @NotBlank(message = "Helyi kliens gépazonosító kötelező")
    private String clientDeviceId;

    @NotBlank(message = "Kliensverzió kötelező")
    private String clientVersion;

    private Instant createdAt;

    @NotNull(message = "Munkacsoport kötelező")
    private UUID groupId;

    private String clientPackageHash;
    private String signature;
    private String operatorNote;

    @NotEmpty(message = "Legalább egy árfolyam bejegyzés szükséges")
    @Valid
    private List<GroupRateDTO.RateEntry> rates;
}
