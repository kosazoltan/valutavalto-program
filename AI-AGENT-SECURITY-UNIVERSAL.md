# AI Agent Security Index

Security policy source: `AGENTS.md`.

Full security gate command for deploy/release or security-sensitive changes:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

Reports: `security-reports/latest/`.

Platform files (`CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `VSCODE.md`,
`ANTIGRAVITY.md`, `.github/copilot-instructions.md`) are indexes only. They must
not reintroduce always-on gate loops.