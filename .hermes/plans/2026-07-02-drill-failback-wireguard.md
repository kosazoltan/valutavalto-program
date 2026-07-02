# Terv: Failover-drill failback javítása WireGuard-ra (SSH-tunnel helyett)

Dátum: 2026-07-02 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2
Branch: `fix/drill-failback-wireguard`

## Kontextus (élő drill-futtatásból verifikálva)

- Az éles Drill 1 (run 28611399894) promote lépése hibátlanul futott, de a `Failback 2` elhasalt, mert az SSH-alapú replikációs alagútra (`pg-repl-tunnel.service` porton 5433) épült, ami már nem létezik (kivezetve a WireGuard-átállás során).
- A replikáció most már **született WireGuard-on** (Hetzner: 10.8.0.1, Scaleway: 10.8.0.2) megy a porton 5432.
- A `Failback 2` scriptje nem talált érvényes replicator jelszót a `postgresql.auto.conf` fájlban sem, mert a jelszavakat immár az `/opt/valutavalto/ha.env` hordozza a Hetzneren.

## Feladat — Failback 2 re-route-olása WireGuard-ra

Fájl: `.github/workflows/scaleway-failover-drill.yml`

1. **Jelszó-beolvasás és átadás (Hetzner):**
   - A step elején olvasd be a replicator jelszót a Hetzner `/opt/valutavalto/ha.env` fájljából:
     `RPWD=$(ssh -i ~/.ssh/hetzner_key root@${{ secrets.VPS_SERVER_IP }} "grep -E '^REPLICATION_PASSWORD=' /opt/valutavalto/ha.env | cut -d= -f2- | tr -d '\r'")`
     és ellenőrizd, hogy nem üres-e.
2. **Script-generálás (heredoc):**
   - A `cat > /tmp/basebackup_failback.sh << 'SCRIPT_EOF'` kifejezést cseréld le `cat > /tmp/basebackup_failback.sh << SCRIPT_EOF` alakra (NINCS single quote!), hogy az `$RPWD` a futtatáskor az aktuális jelszóra cserélődjön.
   - Minden egyéb olyan változót, amelyet Scaleway-en kell kiértékelni, escape-elj `\$` formátumra: `\$now`, `\$latest`, `\$age`, `\$BIN`, `\$REPLICATION_PASSWORD` (ha van).
3. **WireGuard handshake-ellenőrzés (Scaleway-en):**
   - A scriptbe építs be WireGuard ellenőrzést, mint a restore-workflowban: ping 10.8.0.1, majd `wg show wg0 latest-handshakes` ellenőrzése max 180s-os age limit-tel.
4. **pg_basebackup a WG-n át:**
   - Cseréld ki a `pg_basebackup` hostját `127.0.0.1`-ről `10.8.0.1`-re, portját `5433`-ról `5432`-re.
   - Passzold neki az `application_name=scaleway_standby` paramétert a kapcsolat-stringben.
5. **Tisztítás:**
   - Távolíts el minden olyan sort a scriptből, ami a `pg-repl-tunnel.service`-szel vagy az `5433` porttal foglalkozik.
   - Frissítsd a kísérő kommenteket és a workflow fejléc-kommentjeit (a L10-12 sorban is említi a tunnel-t, cseréld WireGuard-ra).

## Verifikáció
- `python -c "import yaml,sys; yaml.safe_load(open('.github/workflows/scaleway-failover-drill.yml'))"` → PASS
- actionlint PASS
- bash -n a módosított run blokkokra.
