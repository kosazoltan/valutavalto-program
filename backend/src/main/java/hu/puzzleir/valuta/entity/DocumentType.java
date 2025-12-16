package hu.puzzleir.valuta.entity;

/**
 * Dokumentum típusok ügyfél azonosításhoz.
 */
public enum DocumentType {
    ID_CARD("Személyi igazolvány"),
    PASSPORT("Útlevél"),
    DRIVING_LICENSE("Jogosítvány"),
    RESIDENCE_PERMIT("Tartózkodási engedély"),
    OTHER("Egyéb");

    private final String displayName;

    DocumentType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
