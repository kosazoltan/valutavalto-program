package hu.puzzleir.valuta.dto.camera;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewStatusDto {
    private boolean reviewed;
    private Long reviewedByWorkerId;
    private String reviewedByWorkerCode;
    private LocalDateTime reviewedAt;
}
