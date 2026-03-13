package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.CameraProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Iterator;
import java.util.UUID;

@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@Service
@RequiredArgsConstructor
@Slf4j
public class CameraStorageService {

    private final CameraProperties cameraProperties;

    private static final DateTimeFormatter DATE_DIR_FORMAT = DateTimeFormatter.ofPattern("yyyy/MM/dd");
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HHmmss");

    /**
     * Generate the directory path for a given date and branch.
     */
    public Path getStorageDirectory(UUID branchId, LocalDate date) {
        return Paths.get(cameraProperties.getLocalStoragePath(),
                branchId.toString(),
                date.format(DATE_DIR_FORMAT));
    }

    /**
     * Generate a segment file name.
     */
    public String generateSegmentFileName(String cameraId, LocalDateTime startTime) {
        return String.format("%s_%s_%s.mjpeg",
                cameraId,
                startTime.toLocalDate().format(DateTimeFormatter.BASIC_ISO_DATE),
                startTime.format(TIME_FORMAT));
    }

    /**
     * Ensure the storage directory exists.
     */
    public Path ensureDirectoryExists(UUID branchId, LocalDate date) throws IOException {
        Path dir = getStorageDirectory(branchId, date);
        Files.createDirectories(dir);
        return dir;
    }

    /**
     * Write a JPEG frame to an output stream.
     */
    public byte[] encodeJpeg(BufferedImage image) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpeg");
        if (!writers.hasNext()) {
            throw new IOException("No JPEG writer available");
        }
        ImageWriter writer = writers.next();
        ImageWriteParam param = writer.getDefaultWriteParam();
        param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
        param.setCompressionQuality(cameraProperties.getJpegQuality() / 100.0f);

        try (ImageOutputStream ios = ImageIO.createImageOutputStream(baos)) {
            writer.setOutput(ios);
            writer.write(null, new IIOImage(image, null, null), param);
        } finally {
            writer.dispose();
        }
        return baos.toByteArray();
    }

    /**
     * Write frame data to a segment file (append mode).
     * Format: [4-byte frame size][frame data]
     */
    public void appendFrame(Path segmentFile, byte[] frameData) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(segmentFile.toFile(), true);
             DataOutputStream dos = new DataOutputStream(fos)) {
            dos.writeInt(frameData.length);
            dos.write(frameData);
            dos.flush();
        }
    }

    /**
     * Get the file size of a segment.
     */
    public long getFileSize(Path filePath) {
        try {
            return Files.size(filePath);
        } catch (IOException e) {
            return 0L;
        }
    }

    /**
     * Delete a recording file from local storage.
     */
    public boolean deleteLocalFile(String filePath) {
        if (filePath == null) return false;
        try {
            Path path = Paths.get(filePath);
            boolean deleted = Files.deleteIfExists(path);
            if (deleted) {
                log.info("Helyi felvetel torolve: {}", filePath);
            }
            return deleted;
        } catch (IOException e) {
            log.error("Helyi felvetel torlese sikertelen: {}", filePath, e);
            return false;
        }
    }

    /**
     * Get total disk usage for camera storage.
     */
    public long getTotalDiskUsage() {
        Path basePath = Paths.get(cameraProperties.getLocalStoragePath());
        if (!Files.exists(basePath)) return 0L;
        try {
            return Files.walk(basePath)
                    .filter(Files::isRegularFile)
                    .mapToLong(p -> {
                        try { return Files.size(p); } catch (IOException e) { return 0L; }
                    })
                    .sum();
        } catch (IOException e) {
            log.error("Tarhelyhasznalat szamitas sikertelen", e);
            return 0L;
        }
    }

    /**
     * Check available disk space.
     */
    public long getAvailableDiskSpace() {
        Path basePath = Paths.get(cameraProperties.getLocalStoragePath());
        return basePath.toFile().getUsableSpace();
    }
}
