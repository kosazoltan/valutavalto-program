-- V200: Vegleges jelszo-reset a v2.5.41 installer build ELOTT.
--
-- A V198 + V199 utan az integrcios teszt-hivasok (curl first-time-setup)
-- beallitottak ideiglenes jelszavakat. Ez a migracio MINDEN dolgozot resetel,
-- hogy az installer SetupWizard-jan keresztul allithassanak be VALODI jelszot.
--
-- FONTOS: Ez az UTOLSO jelszo-reset migracio. Tovabbi resetelest NE Flyway
-- migracioval csinalj, hanem admin UI jelszo-reset funkcioval.

UPDATE worker
SET password_hash = NULL,
    password_changed_at = NULL;
