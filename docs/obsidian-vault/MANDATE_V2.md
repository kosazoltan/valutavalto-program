---
tags: [mandate/v2, policy/active, vendor/anthropic, vendor/openai, vendor/gemini]
created: 2026-04-23
status: ACTIVE
supersedes: MANDATE_V1_SUPERSEDED
---

# Multi-modell GitHub/PUSH mandate v2

Ez a szabalyzat **minden Anthropic + OpenAI + Gemini modellre kotelezo**.

## 10 kapu

| Kapu | Bizonyitek | Blokkolo |
|---|---|---|
| Lokalis lint | 0 error | barmely error |
| Typecheck | 0 error | error |
| Teszt | suite zold | failure |
| Build | reprodukalhato | fail |
| Required checks | pass | fail/pending (v2) |
| Codex review | P0/P1 kezelve | unresolved P0/P1 |
| Sourcery review | blocking kezelve | security/test/complex |
| Dependabot | 0 high/crit | open high/crit |
| CodeQL | 0 high/crit | high/crit |
| Secret scan | 0 leak | leak/bypass |

## v1 szekciok (1-10)
1. PR info + head SHA
2. Required checks
3. Check-runs + annotations
4. Codex review + comments
5. Sourcery review + comments
6. Dependabot alerts
7. CodeQL alerts
8. Secret scanning
9. CI logok + runs
10. Conversation resolution

## v2 UJ szekciok (11-20)
11. [[PR_State_Polling]]
12. [[Checks_API_Plus_Legacy]]
13. [[Workflow_Jobs_Logs]]
14. [[GraphQL_Review_Threads]]
15. [[Rulesets_Merge_Queue]]
16. [[Dependency_Slopsquatting]]
17. [[Lockfile_Hash_Integrity]]
18. [[GitHub_Actions_Hardening]]
19. [[Release_Artifact_Attestation]]
20. [[Bizonyitasi_Minimum]]

## Projekt fajlok

- AGENTS.md (igazsagforras)
- AI_CONTRACT.md (tiltasok)
- CLAUDE.md + GEMINI.md + .github/copilot-instructions.md
- REVIEW.md

## Helper scriptek

- scripts/pre-push-quality-gate.ps1
- scripts/github-signal-check.ps1 <PR>

## Skillek (.claude/skills/)

- [[github-quality-gate]]
- [[ai-review-responder]]
- [[deploy-verification]]
- [[agents-md-generator]]

## Tanulsag (PR #157)

A v1 pre-push gate csak `mvn compile`-t futtatott -> PR #154+#155 regresszio atment. 
v2-ben `mvn test` + `mvn package` default mode.

## Related

- [[PR-156]]
- [[PR-157]]
- [[SKILLS_INDEX]]