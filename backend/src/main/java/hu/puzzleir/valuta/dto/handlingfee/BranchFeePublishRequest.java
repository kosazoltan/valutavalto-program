package hu.puzzleir.valuta.dto.handlingfee;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * FK-096/D8/N11: publikálás előfeltétele — az expectedVersion a TÖRZSBEN utazik.
 *
 * <p><b>CSAK {@code @NotNull}</b> — nincs {@code @Positive}/{@code @Min(1)}: a V383 seed
 * minden sort {@code version = 0}-val hoz létre, így az ELSŐ publikálás ~90 irodában
 * {@code expectedVersion = 0}-t küld. A null → 400; az elavult nem-null → 409.</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BranchFeePublishRequest {

    @NotNull
    private Long expectedVersion;
}
