# B.5 — Szabályozási kimenetek határidő-mandate

**Hatály:** always, P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.5 szakasz

## Határidős jelentések

| Jelentés | Címzett | Határidő | Hibakor mit kell tenni |
|---|---|---|---|
| MNB napi árfolyam | Magyar Nemzeti Bank | minden munkanap **14:30** | **P0** escalation, manuális feltöltés azonnal |
| NGM havi tranzakció-aggregátum | Nemzetgazdasági Minisztérium | tárgyhó+15. munkanap | P1, batch retry + manuális |
| NAV NPG online pénztárgép | NAV | real-time | **P0**, fallback off-line bizonylat |
| SAR (gyanús ügylet) | Pénzügyi Hírszerző Egység | 5 munkanap | **P0**, manager review kötelező |

## Kötelező scriptek (`scripts/regulatory/`)

```
scripts/regulatory/mnb-publish.sh         # cron 14:00-kor
scripts/regulatory/ngm-monthly-export.sh  # cron hó 14-én 06:00-kor
scripts/regulatory/sar-notify.sh          # webhook trigger AML hit-re
```

Sikertelen futás → email + Slack alert.

## Backend health endpoint

A 9-fázisú zárási protokoll új 8.5 lépésében:

```bash
curl https://excvaluta.com/api/v1/health/regulatory
# Várt:
# {
#   "mnb": { "lastSubmitted": "2026-05-17T14:25:00Z", "status": "OK" },
#   "ngm": { "lastExport": "2026-04-14T06:00:00Z", "status": "OK" },
#   "sar": { "pending": 0 }
# }
```

Bármelyik státusz NEM "OK" → deploy NEM minősíthető késznek.

## Monitoring (terv)

- UptimeRobot ping a `/health/regulatory`-ra 5 percenként
- Email alert ha status != OK
- Grafana dashboard a regulatory submission timestamps-szel
