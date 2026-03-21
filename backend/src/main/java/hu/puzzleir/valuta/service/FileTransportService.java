package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.*;
import java.nio.file.attribute.PosixFilePermission;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.EnumSet;
import java.util.HexFormat;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Slf4j
public class FileTransportService {

    private static final DateTimeFormatter TS = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss_SSS");
    private static final Pattern SAFE_SEGMENT = Pattern.compile("[A-Za-z0-9._-]+");

    private final IntegrationTransportProperties properties;
    private final ObjectMapper objectMapper;

    public Path copyToManagedStorage(Path source, String relativeDir, String targetFileName) throws IOException {
        Path targetDir = resolveManagedDir(relativeDir);
        Path target = targetDir.resolve(sanitizeFileName(targetFileName)).normalize();
        ensureInsideRoot(target);
        Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
        tightenPermissions(target);
        return target;
    }

    public Path writeJson(String relativeDir, String filePrefix, Object payload) throws IOException {
        Path dir = resolveManagedDir(relativeDir);
        Path file = dir.resolve(sanitizeFileName(filePrefix) + "_" + LocalDateTime.now().format(TS) + ".json").normalize();
        ensureInsideRoot(file);
        objectMapper.writerWithDefaultPrettyPrinter().writeValue(file.toFile(), payload);
        tightenPermissions(file);
        return file;
    }

    public String sha256(Path path) throws IOException {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            try (InputStream inputStream = Files.newInputStream(path);
                 DigestInputStream digestStream = new DigestInputStream(inputStream, digest)) {
                digestStream.transferTo(OutputStream.nullOutputStream());
            }
            return HexFormat.of().formatHex(digest.digest());
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 nem érhető el", e);
        }
    }

    public Map<String, Object> buildArtifactMeta(Path path) throws IOException {
        return Map.of(
                "fileName", Files.exists(path) ? path.getFileName().toString() : "",
                "sizeBytes", Files.exists(path) ? Files.size(path) : 0L,
                "sha256", Files.exists(path) ? sha256(path) : ""
        );
    }

    public String sanitizePathSegment(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " nem lehet üres");
        }
        String trimmed = value.trim();
        if (!SAFE_SEGMENT.matcher(trimmed).matches() || ".".equals(trimmed) || "..".equals(trimmed)) {
            throw new IllegalArgumentException(fieldName + " érvénytelen path szegmens: " + value);
        }
        return trimmed;
    }

    public String sanitizeFileName(String value) {
        return sanitizePathSegment(value, "fileName");
    }

    private Path resolveManagedDir(String relativeDir) throws IOException {
        Path root = root();
        Path resolved = root.resolve(relativeDir).normalize();
        ensureInsideRoot(resolved);
        Files.createDirectories(resolved);
        tightenPermissions(resolved);
        return resolved;
    }

    private void ensureInsideRoot(Path candidate) {
        Path normalizedRoot = root();
        Path normalizedCandidate = candidate.normalize();
        if (!normalizedCandidate.startsWith(normalizedRoot)) {
            throw new IllegalArgumentException("A célútvonal kilépne a managed storage gyökérből: " + candidate);
        }
    }

    private void tightenPermissions(Path path) {
        try {
            if (FileSystems.getDefault().supportedFileAttributeViews().contains("posix")) {
                Set<PosixFilePermission> perms = Files.isDirectory(path)
                        ? EnumSet.of(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE, PosixFilePermission.OWNER_EXECUTE)
                        : EnumSet.of(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE);
                Files.setPosixFilePermissions(path, perms);
            }
        } catch (Exception e) {
            log.debug("POSIX jogok nem állíthatók ezen a platformon: {}", path, e);
        }
    }

    private Path root() {
        return Paths.get(properties.getRootPath()).toAbsolutePath().normalize();
    }
}
