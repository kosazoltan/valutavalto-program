package hu.puzzleir.valuta.dto.compliance;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateQuestionAnswerDto {
    @NotNull(message = "Ügyfél megadása kötelező")
    private Long customerId;

    /** Opcionális: melyik váltáshoz kötődik a válasz. */
    private Long transactionId;

    @NotBlank(message = "A válasz szövege kötelező")
    private String answerText;
}
