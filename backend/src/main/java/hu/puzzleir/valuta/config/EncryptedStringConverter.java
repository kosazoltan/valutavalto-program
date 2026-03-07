package hu.puzzleir.valuta.config;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import jakarta.persistence.PersistenceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.encrypt.Encryptors;
import org.springframework.security.crypto.encrypt.TextEncryptor;
import org.springframework.stereotype.Component;

/**
 * JPA AttributeConverter — AES titkosítás OAuth tokenekhez.
 * Spring Security Crypto TextEncryptor-t használ.
 */
@Converter
@Component
public class EncryptedStringConverter implements AttributeConverter<String, String> {

    private final TextEncryptor encryptor;

    public EncryptedStringConverter(
            @Value("${app.encryption.key}") String key,
            @Value("${app.encryption.salt}") String salt) {
        this.encryptor = Encryptors.text(key, salt);
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null) {
            return null;
        }
        try {
            return encryptor.encrypt(attribute);
        } catch (Exception e) {
            throw new PersistenceException("Token encryption hiba: " + e.getMessage(), e);
        }
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null) {
            return null;
        }
        try {
            return encryptor.decrypt(dbData);
        } catch (Exception e) {
            throw new PersistenceException("Token decryption hiba (corrupt data / rossz key): " + e.getMessage(), e);
        }
    }
}
