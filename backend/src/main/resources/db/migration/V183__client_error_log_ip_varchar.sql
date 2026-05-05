-- =====================================================================
-- V183: client_error_log.client_ip -> VARCHAR(45) (Hibernate kompat)
-- =====================================================================
-- A V182 INET típust definiált, de a Hibernate alapértelmezetten String-et küld
-- — ez típus-mismatch hibát ad (PSQLException: column is of type inet but
-- expression is of type character varying).
-- Megoldas: VARCHAR(45) — IPv6 max 39 char + IPv4-mapped 45 char.

ALTER TABLE client_error_log
    ALTER COLUMN client_ip TYPE VARCHAR(45) USING client_ip::TEXT;
