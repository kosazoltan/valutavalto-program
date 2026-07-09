-- V352: FS-7 legacy kulcs-enkódolt INCOME_PROOF_DOC_RECIPIENTS.<companyUUID> sorok
-- backfillje a V348-as company_id oszlopba. Idempotens; árva/parse-olhatatlan sor érintetlen.
UPDATE system_parameter sp
   SET company_id    = c.id,
       parameter_key = 'INCOME_PROOF_DOC_RECIPIENTS'
  FROM company c
 WHERE sp.company_id IS NULL
   AND sp.parameter_key LIKE 'INCOME\_PROOF\_DOC\_RECIPIENTS.%' ESCAPE '\'
   AND lower(substring(sp.parameter_key FROM char_length('INCOME_PROOF_DOC_RECIPIENTS.') + 1))
       = lower(c.id::text)
   AND NOT EXISTS (
        SELECT 1 FROM system_parameter dup
         WHERE dup.parameter_key = 'INCOME_PROOF_DOC_RECIPIENTS'
           AND dup.company_id = c.id
   );
