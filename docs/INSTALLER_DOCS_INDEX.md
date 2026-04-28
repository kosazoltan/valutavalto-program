# Installer Dokumentáció — Index

> Egységes nézet a Valutaváltó Pénztár Windows telepítő összes hivatalos dokumentációjáról. Minden link a megfelelő doksira mutat — itt csak a navigáció van, **a tartalom nincs duplikálva**.

## Forrás-igazságok (single source of truth)

| Doksi | Tartalom | Célközönség | Frissítési ciklus |
|-------|----------|-------------|-------------------|
| [`installer/README.md`](../installer/README.md) | Installer belső struktúra, fájl-listák, telepítő-script referencia | Fejlesztő | Verziónként |
| [`docs/BUILD_WINDOWS.md`](BUILD_WINDOWS.md) | Build folyamat, build gép setup, troubleshooting | Fejlesztő | Verzió-független |
| [`docs/INSTALL_WINDOWS.md`](INSTALL_WINDOWS.md) | Végfelhasználói telepítési útmutató | Iroda dolgozó / IT support | Verzió-független |
| [`docs/UPDATE_WINDOWS.md`](UPDATE_WINDOWS.md) | Frissítés régi verzióról, backup/restore, rollback | Iroda dolgozó / IT support | Verzió-független |
| [`docs/SECURITY_INSTALLER_CHECKLIST.md`](SECURITY_INSTALLER_CHECKLIST.md) | Biztonsági ellenőrzőlista build/install/post-install fázisokra | Bence (security agent) | Negyedévente |
| [`docs/SECURITY-AUDIT.md`](SECURITY-AUDIT.md) | Általános Pénztár biztonsági audit (NEM csak installer!) | Bence | Évente |
| [`dist/release/install-notes.md`](../dist/release/install-notes.md) | Verzió-konkrét release notes (SHA256-okkal) | Iroda dolgozó | Releaseенként |

## Tudásbázisok (lessons learned, history)

| Doksi | Tartalom |
|-------|----------|
| [`docs/knowledge/installer-wizard-implementation-guide.md`](knowledge/installer-wizard-implementation-guide.md) | First-Run Setup Wizard implementációs részletek |
| [`docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.qmd`](knowledge/memory/2026-04-17-installer-release-v2.1.0-session.qmd) | v2.1.0 release session log |
| [`docs/knowledge/memory/2026-04-17-hetzner-deploy-v2.1.1-session.yaml`](knowledge/memory/2026-04-17-hetzner-deploy-v2.1.1-session.yaml) | Hetzner deploy v2.1.1 session log |
| [`docs/knowledge/memory/2026-04-20-installer-fix-v2.1.3-session.yaml`](knowledge/memory/2026-04-20-installer-fix-v2.1.3-session.yaml) | v2.1.3 fix session log |
| [`docs/knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.qmd`](knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.qmd) | v2.3.5 build pipeline narratív + lessons learned |
| [`docs/knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.yaml`](knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.yaml) | v2.3.5 build pipeline machine-parseable |
| [`docs/obsidian-vault/INSTALLER_BUILD_PIPELINE.md`](obsidian-vault/INSTALLER_BUILD_PIPELINE.md) | Obsidian vault graph-link verzió |

## AI agent skill

| Skill | Auto-load trigger |
|-------|-------------------|
| [`.claude/skills/installer-build/SKILL.md`](../.claude/skills/installer-build/SKILL.md) | "build a telepítőt", "új patch release", "package for windows", stb. |

## Cognee vector memory

A build pipeline knowledge ingest-elve van a `valutavalto-installer-build` Cognee dataset-be (data_id: `b594ef67-e52b-5dd7-b438-1a84dc8e7fea`). Lekérhető:

```
cognee_search(query="valutavalto installer build pipeline", datasets=["valutavalto-installer-build"])
```

## Workflow-onkénti olvasási útvonalak

### "Új gépre telepítek" (iroda dolgozó)
1. Olvasd: [`INSTALL_WINDOWS.md`](INSTALL_WINDOWS.md)
2. Verzió-konkrét részletek: `dist/release/install-notes.md` (a kapott telepítő mellé csomagolva)

### "Frissíteni szeretnék" (iroda dolgozó)
1. Olvasd: [`UPDATE_WINDOWS.md`](UPDATE_WINDOWS.md)
2. Mindig: backup ELŐSZÖR (lásd § 2)

### "Új verziót kell buildelni" (fejlesztő)
1. AI agent? → automatikusan betölti: [`.claude/skills/installer-build/SKILL.md`](../.claude/skills/installer-build/SKILL.md)
2. Ember? → olvasd: [`BUILD_WINDOWS.md`](BUILD_WINDOWS.md)
3. Belső struktúra: [`installer/README.md`](../installer/README.md)

### "Security audit" (Bence)
1. Olvasd: [`SECURITY_INSTALLER_CHECKLIST.md`](SECURITY_INSTALLER_CHECKLIST.md)
2. Általános audit: [`SECURITY-AUDIT.md`](SECURITY-AUDIT.md)

### "Telepítő hibás, mit csinálok?" (IT support)
1. Olvasd: [`INSTALL_WINDOWS.md` § 6](INSTALL_WINDOWS.md#6-hibás-telepítés-tisztítása) (Eltávolító használat)
2. Build hibák: [`BUILD_WINDOWS.md` § 8](BUILD_WINDOWS.md#8-tipikus-hibák-és-javítás)
3. Frissítési hibák: [`UPDATE_WINDOWS.md` § 8](UPDATE_WINDOWS.md#8-tipikus-frissítési-hibák)

## Duplikáció-elkerülési szabályok

A doksik **explicit forrás-felelősség** szerint vannak felosztva:

| Téma | Forrás-igazság |
|------|----------------|
| Build folyamat parancsai | `docs/BUILD_WINDOWS.md` |
| Installer fájl-listák, NSI script struktúra | `installer/README.md` |
| Verzió-konkrét SHA256 hash | `dist/release/install-notes.md` |
| Setup Wizard 4 lépés (UI) | `docs/INSTALL_WINDOWS.md` |
| Wizard implementáció (kód) | `docs/knowledge/installer-wizard-implementation-guide.md` |
| `$UPGRADE_MODE` flag (PR #222) | `docs/UPDATE_WINDOWS.md` |
| ACL hardening, secrets policy | `docs/SECURITY_INSTALLER_CHECKLIST.md` |
| 4-way verzió-szinkron | `docs/BUILD_WINDOWS.md` § 4 |
| Lessons learned (v2.3.5) | `docs/knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.qmd` |

Ha valami **több helyre is illeszkedne**, az elsődleges helyre tedd, a többi csak hivatkozzon (`Lásd: ...`).
