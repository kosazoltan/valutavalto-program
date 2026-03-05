package hu.puzzleir.valuta.dto.supervisor;

import hu.puzzleir.valuta.entity.SystemParameter;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SystemParamDto {
    private UUID id;
    private String key;
    private String value;
    private String type;
    private String category;
    private String description;
    private LocalDateTime updatedAt;

    public static SystemParamDto from(SystemParameter param) {
        return SystemParamDto.builder()
                .id(param.getId())
                .key(param.getParameterKey())
                .value(param.getParameterValue())
                .type(param.getParameterType())
                .category(param.getCategory())
                .description(param.getDescription())
                .updatedAt(param.getUpdatedAt())
                .build();
    }
}
