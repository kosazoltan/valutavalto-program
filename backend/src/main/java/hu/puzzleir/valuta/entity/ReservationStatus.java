package hu.puzzleir.valuta.entity;

/**
 * Foglaló státusz enum.
 *
 * Legacy mapping: FOGLALO.DLL _visszatipus
 * - ACTIVE: aktív foglaló (még nem járt le, nem teljesített)
 * - FULFILLED: _visszatipus=1 "ÜGYLET RENDBEN" — ügyfél megkapta a valutát
 * - CANCELLED_BY_CUSTOMER: _visszatipus=2 "ÜGYFÉL MIATT SEMMIS" — letét nem jár vissza
 * - CANCELLED_BY_COMPANY: _visszatipus=3 "EBC MIATT SEMMIS" — dupla visszafizetés
 */
public enum ReservationStatus {

    /** Aktív foglaló — még érvényes */
    ACTIVE,

    /** Teljesített — ügyfél megkapta a valutát, fizetendő = letét összeg */
    FULFILLED,

    /** Ügyfél miatt semmis — letét NEM jár vissza (fizetendő = 0) */
    CANCELLED_BY_CUSTOMER,

    /** EBC miatt semmis — dupla visszafizetés (fizetendő = 2 × letét) */
    CANCELLED_BY_COMPANY,

    /** Automatikusan lejárt — 2 nap után a scheduler zárta le, letét → kezelési költség pénztár */
    EXPIRED
}
