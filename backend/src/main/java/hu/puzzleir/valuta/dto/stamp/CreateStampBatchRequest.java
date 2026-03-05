package hu.puzzleir.valuta.dto.stamp;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateStampBatchRequest {
    @NotNull(message = "Iroda ID kötelező!")
    private UUID branchId;

    @NotBlank(message = "Sorszám előtag kötelező!")
    private String serialPrefix;

    @NotNull(message = "Kezdő sorszám kötelező!")
    @Min(value = 1, message = "Kezdő sorszám minimum 1!")
    private Integer serialStart;

    @NotNull(message = "Záró sorszám kötelező!")
    @Min(value = 1, message = "Záró sorszám minimum 1!")
    private Integer serialEnd;

    private String note;
}
