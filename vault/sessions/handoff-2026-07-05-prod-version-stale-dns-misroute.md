# Handoff — 2026-07-05 PROD-VERSION-STALE (DNS-misroute) diagnózis + fix

## Mi volt a baj
A publikus `excvaluta.com`/`/api/v1/version` hetekig `2.28.8`-at adott (buildTime
07-04 15:11), miközben minden deploy sikeresen `2.28.27`-et telepített. A backlog
eredeti hipotézise (systemctl restart nem cserélte a JVM-et) **HAMIS** volt.

## Valós gyökérok (VERIFY-DON'T-TRUST győzött)
- Hetzner primary VÉGIG egészséges: `curl localhost:8080/api/v1/version` → 2.28.27,
  JVM PID uptime = a #1315 restart pillanata, `current.jar`→2.28.27.jar, ExecStart helyes.
- A `2.28.8`-at a **Cloudflare edge** szolgálta: az `excvaluta.com`+`www` A-rekord egy
  korábbi **auto-failover** óta a **Scaleway standby IP-jén (163.172.152.234) ragadt**,
  ahol egy régi 2.28.8 backend futott. `primary.excvaluta.com` végig a friss 2.28.27-et adta.
- A `primary-watchdog` recovery-kor NEM csinál DNS-failbacket (csak emailt) → beragadt.
- A deploy health-check a PUBLIKUS edge-et pingelte → stale origin 200 → hamis-zöld deploy.

## Adatbiztonság (kritikus — bizonyítva, NINCS split-brain)
Minden pénz/mozgás-tábla `count(*)` bájtra azonos Hetzner↔Scaleway (transaction=134,
cash_balance=1232, audit_log=236, employee=196…), legfrissebb audit UUID egyezik,
és **0 írás a Scaleway-promote (07-04 15:10) óta** → nincs csak-Scaleway-n létező adat.

## Amit csináltunk
### A — azonnali prod-helyreállítás (élő)
- **#1316** `prod-dns-failback.yml`: CF apex+www A-rekord → Hetzner (95.216.191.162),
  proxied megőrizve, dry_run-first. Prod publikus most 2.28.27. ✅
- **#1317** `scaleway-standdown.yml`: Scaleway `primary-watchdog.timer` + `valuta-backend`
  stop+disable (rogue 2.28.8 origin megszűnt, nincs re-failover). PG ÉRINTETLEN. ✅

### B — tartós kód-megelőzés (#1318 MERGED, pipeline: Fable→GPT-5.5→GLM, holdout 5/5)
- `deploy-hetzner.yml`: health-check origin-pin `--resolve VPS_SERVER_IP` + origin
  `/version`==build-verzió BLOKKOLÓ assert; edge-drift NEM-blokkoló warning.
- `cloudflare-dns-failover.sh`: apex ÉS www kezelés, per-rekord CF-hiba izolálva.
- `primary-watchdog.sh`: recovery-ág 24h-ismétlő FAILBACK-SZÜKSÉGES riasztás a pontos
  paranccsal; `promoted=1` csak DNS==ORIGIN_IP esetén nullázódik.

## 🔴 HA-REBUILD MEGKÍSÉRELVE → LEDÖNTÖTTE A PRODOT (07-05, elhárítva)
A user kérésére elindítottam a `scaleway-ha-restore.yml`-t (dry_run zöld volt), az
éles rebuild viszont **ledöntötte a Hetzner primaryt**:

**Láncreakció:** a Hetzner pg_wal EGY **külön, csak 2GB-os TITKOSÍTOTT köteten** van
(`/dev/mapper/pgdata-crypt` → `/mnt/pgdata-encrypted`; a DB maga csak ~70MB). A rebuild
létrehozta a `standby_slot_0`-t, a basebackup a WG-tunnelen `SSL SYSCALL EOF`-fel
megszakadt, de **a slot fogyasztó nélkül maradt** → WAL-recycle blokk → a pg_wal
megtöltötte a 2GB kötetet → **PG crash (No space) → backend dependency-fail → ~90
iroda offline**.

**Helyreállítás (root@Hetzner, `runuser -u postgres -- psql`, sudo NEM kell):**
1. A redo-pont (0x75) ELŐTTI 107 WAL-szegmenst átmozgattam `/root/wal_rescue`-be → PG indul.
2. `SELECT pg_drop_replication_slot('standby_slot_0')` — a WAL-pin megszűnt.
3. `ALTER SYSTEM SET synchronous_standby_names = ''` + reload — különben nincs standby →
   minden írás szinkron-ack-re várna = **írhatatlan prod**.
4. `systemctl restart valuta-backend` → origin 200.
5. **Latens bomba:** `wal_keep_size=2048MB` egy 2GB köteten → leírtam **256MB**-ra.
6. Box-takarítás: WAL-rescue törölve, 36G régi JAR (315 db) → 365MB (megtartva current+3).
   FIGYELEM: a prune törölte a `current.jar` SYMLINK-et is (glob!) → újralétrehoztam.

Végállapot: prod 200/2.28.27, DB in_recovery=f, slots=0, sync='', wal_keep=256.

## ⛔ HA-REBUILD TILOS, amíg ezek nincsenek meg (user-döntés + kódmunka)
A jelenlegi `scaleway-ha-restore.yml` NEM futtatható újra biztonságosan:
1. **Slot-orphan-guard kell a workflow-ba**: ha a basebackup elbukik, a `standby_slot_0`-t
   AZONNAL el kell dobni a Hetzneren (trap/cleanup), különben megismétli a WAL-fault kiesést.
   Ideális: a slot létrehozása CSAK a sikeres basebackup UTÁN, vagy `failsafe` DROP.
2. **A Hetzner pg_wal 2GB-os titkosított kötete túl kicsi** volt streaming standbyhez.
   ✅ **MEGOLDVA (07-05):** a kötetet **2GB → 8GB**-ra bővítettem, online, adatvesztés nélkül.
   Topológia: LUKS2 loopback-fájl `/opt/pgdata-encrypted.img` (a root fs-en, 127G szabad) →
   `/dev/loop0` → `pgdata-crypt` → ext4. Lépések: `fallocate -l 8G img` → `losetup -c loop0`
   → `cryptsetup resize pgdata-crypt --key-file /root/.pgdata-luks-key` → `resize2fs`.
   PITFALL: a LUKS2 resize keyfile NÉLKÜL `No key available with this passphrase`-szel bukik;
   a nyitó keyfile a `pgdata-luks.service`-ben van (`/root/.pgdata-luks-key`). REBOOT-SAFE:
   a service `luksOpen <img>`-et hív, ami a teljes 8G fájlból auto-méretezi a loopot; a LUKS
   data-area + ext4 superblock a lemezen perzisztens. Pre-resize mentés: `pg_dumpall` →
   `/root/pre-walresize-backup-*.sql` (40MB). Végállapot: 7.9G/7.4G szabad, PG egészséges.
3. A `deploy-standby` job (if:false) csak a HA-rebuild UTÁN aktiválható.
4. **wal_keep_size visszaemelése**: jelenleg 256MB (nincs standby). A HA-rebuildkor a 8G
   kötet már bírná a 2048MB-ot is, de ezt CSAK a guardolt rebuild részeként érdemes.

→ **A HA jelenleg NINCS** (Scaleway passzív, watchdog OFF). A prod egyszerűen, egy régióban
stabil. A HA visszaépítése a maradék #1 (slot-orphan-guard kód) + user-jóváhagyás után,
pipeline-on. A #2 (kötet-bővítés) KÉSZ.

## Kulcs-tanulságok
- CF proxied rekord mögött a `dig` a CF edge IP-ket adja; origin-igazsághoz
  `curl --resolve <host>:443:<origin-ip>` VAGY `curl localhost:8080` a boxon.
- `primary.excvaluta.com` origin-hostname mindig a Hetznert adta — hasznos diff-pont.
- Redaction-csapda (pitfall 27): patch-eléskor `$CF_API_TOKEN`→`***` becsúszhat;
  hex/char-split próba a döntő, a terminál-nézet maszkol.
- Egyszeri ops-workflow-k csak a main-ről dispatchelhetők (workflow_dispatch) → PR+admin-merge.
