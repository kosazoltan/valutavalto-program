package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import org.springframework.http.HttpStatus;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * FS-9: közös thumbnail-segéd — az FS-5 DocumentScannerService.createThumbnail logikája
 * kiemelve (viselkedés-azonos). ≤256px JPEG; PNG-alfa fehérre lapítva; dekompressziós-bomba
 * védelem (max 8000px forrás-oldal); headless-safe (ImageIO).
 */
public final class ImageThumbnailUtil {

    public static final int THUMBNAIL_MAX_PX = 256;
    public static final int MAX_SOURCE_PX = 8000;

    private ImageThumbnailUtil() {
    }

    public static byte[] createThumbnail(byte[] imageBytes) {
        try {
            BufferedImage src = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (src == null) {
                throw new ValidationException("A kép nem dekódolható");
            }
            if (src.getWidth() > MAX_SOURCE_PX || src.getHeight() > MAX_SOURCE_PX) {
                throw new ValidationException("A kép felbontása túl nagy");
            }
            int w = src.getWidth();
            int h = src.getHeight();
            double scale = Math.min(1.0, (double) THUMBNAIL_MAX_PX / Math.max(w, h));
            int tw = Math.max(1, (int) Math.round(w * scale));
            int th = Math.max(1, (int) Math.round(h * scale));
            BufferedImage thumb = new BufferedImage(tw, th, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = thumb.createGraphics();
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, tw, th);
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.drawImage(src, 0, 0, tw, th, null);
            g.dispose();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ImageIO.write(thumb, "jpg", out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new BusinessException(
                    "A kép feldolgozása sikertelen",
                    "IMAGE_PROCESSING_ERROR",
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
