# B.7 — Code-signing függő release mandate

**Hatály:** 2026-05-21-ig (DigiCert EV CS HSM cert kiadásig), utána re-evaluate
**P-szint:** P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.7 szakasz

## Tartalom

A DigiCert EV CS HSM kiadásig (várható 2026-05-19 / 21):

1. **TILOS unsigned `Penztar-Setup-*.exe`-t** publikus GitHub Release-be feltölteni.
2. **TILOS auto-update channel-re unsigned bináris.**
3. Engedélyezett: pre-release tagben, `internal-test` mappába, **kizárólag a fejlesztő gépén** futtatva.
4. Az `internal-test` belső osztogatás **kollégáknak TILOS** (SmartScreen prompt + nem-informatikus user mandate, C.1).

## CI guard (TERVEZETT, v2.5.54 release-től)

**A jelenlegi `windows-signed-release.yml` workflow még NEM tartalmaz** `require-signed` flag-et és `signtool verify` lépést. Ezek TERVEZETT bővítések a DigiCert HSM cert kiadása után (várható 2026-05-21 körül).

Tervezett YAML kiegészítés:

```yaml
- name: Verify signature (TERVEZETT v2.5.54+)
  if: ${{ inputs.publish_release == 'true' }}
  run: |
    if [ "$REQUIRE_SIGNED" = "true" ]; then
      signtool verify /pa /v "$INSTALLER_PATH" || exit 1
    fi
```

Kikapcsolása → P0 reject (mihelyt élesedik).

## v2.5.54+ verziók

Az `inputs.publish_release=true` workflow run automatikusan ellenőrzi:
- A binárik Microsoft Authenticode aláírtak (DigiCert EV CS, Azure Key Vault HSM)
- SHA-256 + provenance attestation
- SmartScreen reputation pre-built

## Re-evaluation (cert kiadás után)

A mandate hatálya 2026-05-21 után megszűnik (vagy ahogy a DigiCert cert kiadása megtörténik). Akkor:
- Mandate átírja: "minden publikus release signed bináris"
- Az "internal-test" path továbbra is csak fejlesztő gép

## DigiCert státusz (2026-05-17)

- HSM Approval: done 2026-05-15 09:55 CEST
- Company validation: done 2026-05-15
- Phone verification: scheduled 2026-05-18 16:30 CEST
- Cert kiadás várható: 2026-05-19 / 21
- Workflow trigger cert után: `gh workflow run windows-signed-release.yml -f version=2.5.54 -f publish_release=true`
