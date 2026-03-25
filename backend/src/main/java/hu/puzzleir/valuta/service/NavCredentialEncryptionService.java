package hu.puzzleir.valuta.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.encrypt.Encryptors;
import org.springframework.security.crypto.encrypt.TextEncryptor;
import org.springframework.stereotype.Service;

/**
 * NAV credential titkosito service.
 *
 * Kulcs/salt forras:
 * - app.encryption.key
 * - app.encryption.salt
 */
@Service
@Slf4j
public class NavCredentialEncryptionService {

    private final TextEncryptor encryptor;

    public NavCredentialEncryptionService(
            @Value("${app.encryption.key}") String key,
            @Value("${app.encryption.salt}") String salt) {
        this.encryptor = Encryptors.text(key, salt);
    }

    public String encrypt(String plainText) {
        if (plainText == null) {
            return null;
        }
        return encryptor.encrypt(plainText);
    }

    public String decrypt(String encryptedText) {
        if (encryptedText == null) {
            return null;
        }
        return encryptor.decrypt(encryptedText);
    }
}
