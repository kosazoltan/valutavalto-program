# VPS Deployment Safety

Before VPS changes:
- identify target host
- verify branch/commit
- backup database
- backup env/config
- prepare rollback
- run tests/build
- avoid destructive commands
- never print secrets
- verify service health after restart
