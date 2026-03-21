package hu.puzzleir.valuta.util;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class LegacyCompanyIdentityCodecTest {

    @Test
    void toLegacyInt_returnsNullForNull() {
        assertNull(LegacyCompanyIdentityCodec.toLegacyInt(null));
    }

    @Test
    void toLegacyInt_isStableForSameUuid() {
        UUID companyId = UUID.fromString("123e4567-e89b-12d3-a456-426614174000");

        Integer first = LegacyCompanyIdentityCodec.toLegacyInt(companyId);
        Integer second = LegacyCompanyIdentityCodec.toLegacyInt(companyId);

        assertNotNull(first);
        assertEquals(first, second);
        assertTrue(first >= 0);
    }

    @Test
    void toLegacyInt_differsForDifferentLeastSignificantBits() {
        UUID firstCompany = new UUID(0L, 101L);
        UUID secondCompany = new UUID(0L, 202L);

        assertNotEquals(
                LegacyCompanyIdentityCodec.toLegacyInt(firstCompany),
                LegacyCompanyIdentityCodec.toLegacyInt(secondCompany)
        );
    }
}
