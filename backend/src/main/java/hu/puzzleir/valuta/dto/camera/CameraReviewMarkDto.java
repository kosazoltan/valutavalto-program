package hu.puzzleir.valuta.dto.camera;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CameraReviewMarkDto {
    private UUID id;
    private UUID branchId;
    private LocalDate reviewDate;
    private String cameraId;
    private LocalTime markTime;
    private Boolean openingClosingOk;
    private Boolean invoicesOk;
    private Boolean breaksOk;
    private Boolean boardOk;
    private Boolean curtainOk;
    private String note;
    private Long createdByWorkerId;
    private String createdByWorkerCode;
    private LocalDateTime createdAt;
    private boolean problematic;
}
