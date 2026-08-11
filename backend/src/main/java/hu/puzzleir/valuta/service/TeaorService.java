package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.TeaorCode;
import hu.puzzleir.valuta.repository.TeaorCodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * TEÁOR'08 tevékenységi kód keresés (legacy: teaorvalasztas / TEAORTABLA).
 *
 * <p>Use-case réteg a {@code TeaorController} alá. A controller korábban közvetlenül
 * injektálta a {@link TeaorCodeRepository}-t, ami megsértette a Clean Architecture
 * függőségi szabályát: a prezentációs réteg átugrotta a use-case réteget, és vele
 * együtt a tranzakcióhatárt is. Mivel az OSIV ki van kapcsolva, a controller-szintű
 * repository-olvasásnak nincs tranzakciója — ez ma működik (a lekérdezés nem érint
 * lazy asszociációt), de bármely későbbi bővítés (pl. TEÁOR-kategória kapcsolat)
 * azonnal {@code LazyInitializationException}-t okozna. A szűrés a service
 * {@code readOnly} tranzakcióján belül történik.
 *
 * <p>A TEÁOR-törzs országos, jogszabályi referencia-adat: <b>nem tenant-szűrt</b>,
 * minden cég ugyanazt a KSH-listát látja. Ez tudatos döntés, nem hiányzó companyId-szűrő.
 */
@Service
@RequiredArgsConstructor
public class TeaorService {

    /** A typeahead-kereső felső korlátja — a UI legfeljebb ennyi találatot jelenít meg. */
    public static final int MAX_RESULTS = 20;

    private final TeaorCodeRepository teaorCodeRepository;

    /**
     * TEÁOR-kód keresés kód-prefix vagy megnevezés alapján.
     *
     * <p>Üres, csak whitespace-ből álló vagy {@code null} keresőkifejezésre üres listát ad
     * vissza — a typeahead első billentyűleütése előtt nem terheljük a törzsadat-táblát
     * teljes olvasással.
     *
     * @param query nyers keresőkifejezés a kliensről (lehet {@code null} vagy üres)
     * @return legfeljebb {@link #MAX_RESULTS} találat, kód szerint növekvő sorrendben
     */
    @Transactional(readOnly = true)
    public List<TeaorCode> search(String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        return teaorCodeRepository.search(query.trim(), Limit.of(MAX_RESULTS));
    }
}
