package hu.puzzleir.valuta.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Kamera felvétel titkosítás — AES-256-GCM.
 *
 * Minden videó szegmens titkosítva kerül tárolásra a helyi lemezen.
 * A titkosítási kulcs a company szintű master key-ből származik.
 *
 * Biztonsági modell:
 * - AES-256-GCM (authenticated encryption)
 * - Szegmensenként egyedi nonce (12 byte)
 * - Nonce a titkosított fájl elejére írva
 * - Master key: konfigurációból (élesben: HSM/Vault)
 *
 * Fájlformátum: [12 byte nonce][titkosított adat + GCM tag]
 */
@Service
@Slf4j
public class CameraEncryptionService {

    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private static final int GCM_TAG_LENGTH = 128; // bit
    private static final int NONCE_LENGTH = 12; // byte
    private static final int KEY_LENGTH = 256; // bit

    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${camera.encryption.masterKey:}")
    private String masterKeyBase64;

    @Value("${camera.encryption.enabled:true}")
    private boolean encryptionEnabled;

    /**
     * Videó szegmens titkosítása fájlból fájlba.
     *
     * @param plainFile   bemeneti (sima) videó fájl
     * @param encryptedFile kimeneti (titkosított) fájl
     * @return A nonce Base64 kódolva (audit loghoz)
     */
    public String encryptFile(Path plainFile, Path encryptedFile) throws Exception {
        if (!encryptionEnabled) {
            Files.copy(plainFile, encryptedFile);
            log.debug("Titkosítás kikapcsolva — másolás: {}", plainFile);
            return "UNENCRYPTED";
        }

        SecretKey key = getEncryptionKey();
        byte[] nonce = generateNonce();

        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, nonce);
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);

        byte[] plainData = Files.readAllBytes(plainFile);
        byte[] encrypted = cipher.doFinal(plainData);

        // Fájlformátum: [nonce][encrypted data + GCM tag]
        try (OutputStream os = new BufferedOutputStream(new FileOutputStream(encryptedFile.toFile()))) {
            os.write(nonce);
            os.write(encrypted);
        }

        log.debug("Szegmens titkosítva: {} → {} ({} byte → {} byte)",
            plainFile.getFileName(), encryptedFile.getFileName(),
            plainData.length, nonce.length + encrypted.length);

        return Base64.getEncoder().encodeToString(nonce);
    }

    /**
     * Titkosított szegmens visszafejtése.
     *
     * @param encryptedFile titkosított fájl
     * @param plainFile     kimeneti (sima) fájl
     */
    public void decryptFile(Path encryptedFile, Path plainFile) throws Exception {
        if (!encryptionEnabled) {
            Files.copy(encryptedFile, plainFile);
            return;
        }

        byte[] fileData = Files.readAllBytes(encryptedFile);
        if (fileData.length < NONCE_LENGTH) {
            throw new IllegalArgumentException("Titkosított fájl túl rövid: " + encryptedFile);
        }

        // Nonce kiolvasása
        byte[] nonce = new byte[NONCE_LENGTH];
        System.arraycopy(fileData, 0, nonce, 0, NONCE_LENGTH);

        // Titkosított adat
        byte[] encrypted = new byte[fileData.length - NONCE_LENGTH];
        System.arraycopy(fileData, NONCE_LENGTH, encrypted, 0, encrypted.length);

        SecretKey key = getEncryptionKey();
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, nonce);
        cipher.init(Cipher.DECRYPT_MODE, key, spec);

        byte[] decrypted = cipher.doFinal(encrypted);
        Files.write(plainFile, decrypted);

        log.debug("Szegmens visszafejtve: {} → {} ({} byte)", encryptedFile.getFileName(), plainFile.getFileName(), decrypted.length);
    }

    /**
     * Byte tömb titkosítása (kisebb adatok, pl. metaadat).
     *
     * @return [nonce + encrypted data] összefűzve
     */
    public byte[] encryptBytes(byte[] plainData) throws Exception {
        if (!encryptionEnabled) return plainData;

        SecretKey key = getEncryptionKey();
        byte[] nonce = generateNonce();

        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, nonce);
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);

        byte[] encrypted = cipher.doFinal(plainData);
        byte[] result = new byte[NONCE_LENGTH + encrypted.length];
        System.arraycopy(nonce, 0, result, 0, NONCE_LENGTH);
        System.arraycopy(encrypted, 0, result, NONCE_LENGTH, encrypted.length);

        return result;
    }

    /**
     * Byte tömb visszafejtése.
     */
    public byte[] decryptBytes(byte[] encryptedData) throws Exception {
        if (!encryptionEnabled) return encryptedData;

        byte[] nonce = new byte[NONCE_LENGTH];
        System.arraycopy(encryptedData, 0, nonce, 0, NONCE_LENGTH);

        byte[] encrypted = new byte[encryptedData.length - NONCE_LENGTH];
        System.arraycopy(encryptedData, NONCE_LENGTH, encrypted, 0, encrypted.length);

        SecretKey key = getEncryptionKey();
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, nonce);
        cipher.init(Cipher.DECRYPT_MODE, key, spec);

        return cipher.doFinal(encrypted);
    }

    /**
     * Fájl SHA-256 hash számítása (integritás ellenőrzéshez).
     */
    public String computeFileHash(Path file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream is = new BufferedInputStream(new FileInputStream(file.toFile()))) {
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = is.read(buffer)) != -1) {
                digest.update(buffer, 0, bytesRead);
            }
        }
        byte[] hash = digest.digest();
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) {
            hex.append(String.format("%02x", b));
        }
        return hex.toString();
    }

    /**
     * Új AES-256 kulcs generálása (kulcsrotációhoz).
     */
    public String generateNewKey() throws Exception {
        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(KEY_LENGTH, secureRandom);
        SecretKey key = keyGen.generateKey();
        return Base64.getEncoder().encodeToString(key.getEncoded());
    }

    public boolean isEncryptionEnabled() {
        return encryptionEnabled;
    }

    // === PRIVÁT ===

    private SecretKey getEncryptionKey() {
        if (masterKeyBase64 == null || masterKeyBase64.isBlank()) {
            throw new IllegalStateException(
                "Camera encryption master key nincs konfigurálva! " +
                "Állítsd be a camera.encryption.masterKey property-t.");
        }
        byte[] keyBytes = Base64.getDecoder().decode(masterKeyBase64);
        if (keyBytes.length != 32) {
            throw new IllegalStateException(
                "Camera encryption key mérete nem 256 bit (32 byte)! Jelenlegi: " + keyBytes.length + " byte");
        }
        return new SecretKeySpec(keyBytes, "AES");
    }

    private byte[] generateNonce() {
        byte[] nonce = new byte[NONCE_LENGTH];
        secureRandom.nextBytes(nonce);
        return nonce;
    }
}
