package hu.puzzleir.valuta.entity;

/**
 * Ügyfél típus.
 *
 * Legacy: KISUGYFEL — a Delphi rendszerben a kis összegű tranzakcióknál
 * nem kellett teljes KYC (Know Your Customer) adatgyűjtés.
 *
 * - FULL: Teljes ügyfél — minden KYC adat kötelező (AML törvény)
 * - SIMPLIFIED: Kis ügyfél — csak név + okmány szám (300.000 Ft alatt)
 */
public enum CustomerType {
    /** Teljes ügyfél: minden KYC mező kötelező */
    FULL,
    /** Egyszerűsített: csak név + dokumentum szám szükséges */
    SIMPLIFIED
}
