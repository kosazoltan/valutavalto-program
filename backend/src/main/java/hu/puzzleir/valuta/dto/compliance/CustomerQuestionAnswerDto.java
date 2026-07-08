package hu.puzzleir.valuta.dto.compliance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerQuestionAnswerDto {
    private UUID id;
    private UUID questionId;
    private Long customerId;
    private Long transactionId;
    private String answerText;
    private String answeredByWorkerCode;
    private LocalDateTime answeredAt;
}
