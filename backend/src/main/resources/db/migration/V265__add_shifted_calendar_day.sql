-- V265: kormányzati áthelyezett naptári napok (rendkívüli munkanap / pihenőnap)
-- Audit finding #PP-17: az AmlService.calculateBusinessDayDeadline a Pmt. 33. § 2
-- munkanapos SAR-határidőt számítja, de figyelmen kívül hagyja a kormányrendelettel
-- áthelyezett szombati munkanapokat és a hétközi pihenőnapokat. Ez (a) késedelmes
-- bejelentést rejthet el (under-reporting → Pmt. bírság), vagy (b) téves OVERDUE
-- riasztást okozhat. Fix: adat-vezérelt naptár-felülírás tábla (kódváltás nélkül,
-- évente admin tölti a hivatalos NGM/kormányrendelet alapján).

CREATE TABLE IF NOT EXISTS shifted_calendar_day (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    calendar_date DATE        NOT NULL UNIQUE,
    is_workday    BOOLEAN     NOT NULL,  -- true: szombat amin dolgozunk; false: hétköznap ami pihenőnap
    description   VARCHAR(255),
    created_at    TIMESTAMP   NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shifted_calendar_day_date ON shifted_calendar_day (calendar_date);
