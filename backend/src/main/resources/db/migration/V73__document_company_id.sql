-- Dokumentumokhoz company_id hozzáadása IDOR védelem miatt
ALTER TABLE document ADD COLUMN IF NOT EXISTS company_id UUID;

-- Meglévő dokumentumok company_id kitöltése az uploadedById (worker) alapján
UPDATE document d
SET company_id = w.company_id
FROM worker w
WHERE d.uploaded_by_id = w.id
  AND d.company_id IS NULL;

-- Index a company_id alapú szűréshez
CREATE INDEX IF NOT EXISTS idx_document_company_id ON document(company_id);
