package hu.puzzleir.valuta.dto.voice;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

import java.util.Arrays;
import java.util.Optional;

/**
 * EBC Hangsegéd üzemmódok kanonikus listája.
 *
 * <p>Copilot PR #659 finding: a `install` / `test` / `support` string-tripla
 * korábban 3 helyen volt duplikálva (DTO regex + service validation + service
 * reasoning ternary). Ez az enum az egyetlen forrás.
 */
public enum VoiceAssistantMode {
    INSTALL("install"),
    TEST("test"),
    SUPPORT("support");

    private final String wireName;

    VoiceAssistantMode(String wireName) {
        this.wireName = wireName;
    }

    @JsonValue
    public String getWireName() {
        return wireName;
    }

    @JsonCreator
    public static VoiceAssistantMode fromWireName(String value) {
        if (value == null) {
            throw new IllegalArgumentException("VoiceAssistantMode wireName: null");
        }
        return Arrays.stream(values())
                .filter(m -> m.wireName.equals(value))
                .findFirst()
                .orElseThrow(() ->
                        new IllegalArgumentException("VoiceAssistantMode ismeretlen: " + value));
    }

    public static Optional<VoiceAssistantMode> tryParse(String value) {
        if (value == null) return Optional.empty();
        return Arrays.stream(values())
                .filter(m -> m.wireName.equals(value))
                .findFirst();
    }

    public boolean usesMediumReasoning() {
        return this == TEST;
    }
}
