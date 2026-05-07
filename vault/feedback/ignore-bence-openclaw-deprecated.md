---
name: Bence + OpenClaw zaj figyelmen kívül hagyandó
description: Bence auto-review trigger bot és OpenClaw (Codex) GitHub-integration emailek nem érdemi feedback — ignore
type: feedback
originSessionId: 05049cfb-3194-4601-a138-e8cb1aca09cc
---
A `kosazoltan/valutavalto-program` repón **Bence** (saját auto-review trigger bot, `github-actions[bot]`) és **OpenClaw** (Codex / `chatgpt-codex-connector[bot]`) értesítések nem érdemi review-feedback és **figyelmen kívül hagyandók** a session-folytatás során.

**Why:** A Bence bot minden PR push után rituálisan triggereli a `@sourcery-ai review` + `@codex review` parancsot — info-jellegű workflow zaj. Az OpenClaw (Codex GitHub integration) válasza minden PR-re ugyanaz: *"To use Codex here, create a Codex account and connect to github"* — a Codex GitHub integration nincs konfigurálva a repón, ezért nem ad valódi review-t. A Sourcery valós review-t ad, de jelenleg weekly rate-limit-en van (1.5M diff char). User explicit kérése 2026-04-27: "A Bence és OpenClaw hibajelentéseket helyezt figyelmen kívül csak a valutaváltó repóval foglalkozunk."

**How to apply:** Ha email-ben vagy konverzáció során Bence vagy OpenClaw értesítés érkezik (`github-actions[bot]` Bence-szignatúrával vagy `chatgpt-codex-connector[bot]` üzenettel), ne reagálj rá külön, ne állítsd le a folyamatban lévő munkát. Csak a **valódi AI review-feedback-ek** (Sourcery konkrét finding, vagy ha a Codex GitHub integration valaha aktiválódik) számítanak. A Dependabot/feature-PR feldolgozás zavartalanul folyhat.
