-- V144: First-run admin bootstrap flag.
--
-- Háttér:
--   A penztar-client First-Run Setup Wizard 4. lépésében a felhasználó
--   egy admin jelszót ad meg. A 2.1.0-ban ez SEHOVA NEM került elmentésre
--   (csak a .env-be a kliens oldalon). A 2.1.1-ben a wizard meghívja a
--   POST /api/v1/auth/bootstrap-admin endpointot, ami ezt a flag-et
--   figyeli — ha már true, elutasítja a másodszori bootstrap-ot.
--
-- Biztonsági cél:
--   Egy támadó ne tudja felülírni az admin hitelesítő adatokat azzal,
--   hogy a telepítés után újra lefuttatja a bootstrap-admin endpointot.
--
-- Érintett service: hu.puzzleir.valuta.service.AdminBootstrapService
-- Érintett controller: hu.puzzleir.valuta.controller.AuthController

-- system_parameter.id UUID NOT NULL DEFAULT nelkul -> gen_random_uuid() explicit kell
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
VALUES
    (gen_random_uuid(), 'auth.bootstrap-completed', 'false', 'BOOLEAN', 'AUTH',
     'Első indítás admin bootstrap lezárása. true: AuthController POST /bootstrap-admin letiltott.',
     TRUE)
ON CONFLICT (parameter_key) DO NOTHING;
