-- V311: EDD f) pass-through és g) profil-kiugrás detektálás paraméterei (V.2.7)
--
-- A szabályzat a f) esetnél 24-72h átfolyási ablakot nevez meg, a g) esetnél
-- "profil-kiugrást" számszerű küszöb nélkül. A numerikus defaultok ENGINEERING
-- defaultok — SystemParameter-ben compliance-vezetői döntéssel hangolhatók
-- kód-változtatás nélkül. A detektálás a meglévő AML_EDD_TRACKING_ENFORCEMENT
-- flag mögött fut (V310 óta true), és csak BŐVÍTI az EDD-jelölést (nem blokkol).

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_EDD_PASSTHROUGH_MIN_HUF', '5000000', 'NUMBER', 'AML',
       'V.2.7 f) pass-through: 72 órán belüli ellentétes irányú (vétel ÉS eladás) forgalom '
       || 'irányonkénti minimum összege HUF-ban az EDD-jelöléshez. Engineering default, compliance hangolhatja.',
       true
WHERE NOT EXISTS (SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_EDD_PASSTHROUGH_MIN_HUF');

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_EDD_PROFILE_OUTLIER_MULTIPLIER', '5', 'NUMBER', 'AML',
       'V.2.7 g) profil-kiugrás: az aktuális havi forgalom hányszorosa legyen az előző 6 hónap '
       || 'havi átlagának az EDD-jelöléshez. Engineering default, compliance hangolhatja.',
       true
WHERE NOT EXISTS (SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_EDD_PROFILE_OUTLIER_MULTIPLIER');

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_EDD_PROFILE_OUTLIER_MIN_HUF', '10000000', 'NUMBER', 'AML',
       'V.2.7 g) profil-kiugrás: minimum aktuális havi forgalom HUF-ban, amely alatt a '
       || 'kiugrás-vizsgálat nem fut (zaj-szűrés). Engineering default, compliance hangolhatja.',
       true
WHERE NOT EXISTS (SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_EDD_PROFILE_OUTLIER_MIN_HUF');
