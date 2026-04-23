# GitHub Copilot Instructions

PRIORITAS: AGENTS.md a modellfuggetlen igazsagforras. Copilot csak kiegeszithet.
Hatály: GitHub Copilot, Copilot Chat, Copilot Workspace, Copilot Coding Agent

## Kotelezo olvasmanyok

1. /AGENTS.md - 10 kapu + 10 lepeses munkafolyamat
2. /AI_CONTRACT.md - kemeny tiltasok + plafonok (300 LOC, 5 fajl)
3. /REVIEW.md - push elotti checklist

## Viselkedes

- NEM javasol kodot a AGENTS.md 3. pont biztonsagi tiltolistajabol
- NEM javasol hard-coded secret-et
- NEM javasol --no-verify-t
- NEM javasol PR-t 300 LOC / 5 fajl felett bontas nelkul

## Required checks

Az alabbi check-eknek ZOLDNEK kell lennie merge elott:
- lint, typecheck, unit-tests, integration-tests, build
- codeql, dependency-review, secret-scan
- codex-review-gate, sourcery-review-gate, scorecard
