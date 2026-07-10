package hu.puzzleir.valuta.dto.camera;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Data
public class CreateMarkRequest {
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
}
