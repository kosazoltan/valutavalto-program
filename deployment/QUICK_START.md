# Gyors Telepítési Útmutató

## 1. VPS-re kapcsolódás

```bash
ssh root@YOUR_VPS_IP
```

## 2. Projekt klónozása

```bash
cd /var/www
git clone https://github.com/kosazoltan/valutavalto-program.git valutavalto
cd valutavalto
```

## 3. Telepítés futtatása

```bash
chmod +x deployment/*.sh
sudo ./deployment/install.sh
```

## 4. Environment beállítása

```bash
sudo ./deployment/setup-env.sh
```

## 5. Adatbázis séma importálása

```bash
sudo -u postgres psql -d valuta -f database/schema/valuta_schema.sql
```

## 6. Backend indítása

```bash
sudo systemctl start valutavalto-backend
sudo systemctl status valutavalto-backend
```

## 7. Elérés

Nyisd meg böngészőben: `http://YOUR_VPS_IP`

## Frissítés (később)

```bash
cd /var/www/valutavalto
sudo ./deployment/update.sh
```

