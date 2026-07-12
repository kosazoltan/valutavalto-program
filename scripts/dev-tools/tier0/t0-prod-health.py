#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-prod-health.py -- Tier-0 fetcher: prod health + verzio-drift.

Cel-repo (csak OLVASVA, sosem irva): VALUTA_REPO env vagy alapertelmezetten
C:\\Repo\\valutavalto-program.

Bemenet:
  - REPO/config/production-urls.json: base_url, api_url, health_url,
    fallback_host_primary, fallback_host_scaleway.
  - REPO/package.json "version" mezoje (repo-verzio).
Ez a script KIZAROLAG ezt a ket ismert fajlt olvassa a REPO-bol (nincs
repo-szintu bejaras) -- a KOZOS KONTRAKTUS denylistje (.env*, .env.ssh-keys,
backend_deployment/) igy nem erintett.

Ellenorzes: HTTP GET (urllib, 10s timeout) a health_url-ra es az
api_url+"/version"-re, HAROM host-variansban:
  1) "config"            -- a production-urls.json-ban literalisan szereplo host
  2) "fallback_primary"  -- fallback_host_primary (Host-csere, path/query marad)
  3) "fallback_scaleway" -- fallback_host_scaleway (ua.)
Igy osszesen 6 HTTP-hivas. UP = HTTP 200. A verzio-endpoint valaszabol
(JSON "version" mezo) szarmazik a "deployed-verzio".

Ket kulon-jelzett inkonzisztencia:
  - drift:       a "config" host deployed-verzioja != repo-verzio.
  - divergencia: a fallback_primary es fallback_scaleway host verzioja
                  eltero egymastol (ket eles host nem egyezik).
Terveszeti dontes (dokumentalva, mert a feladatleiras "DOWN vagy drift -> 1"
formaban egyetlen kifejezest hasznal): a divergencia is a "drift" fogalom ala
tartozik ebben a scriptben -- mindketto azt jelzi, hogy a production verzio-
allapot nem a vart/konzisztens allapotban van. A JSON/digest kimenet mindket
tenyt kulon-kulon is felfedi, tehat semmi nem tunik el a dontes mogott.

Env-mock (T0_HEALTH_MOCK_DIR): ha be van allitva, MINDEN HTTP-hivas ebben a
konyvtarban levo, elore elkeszitett JSON-fajlokbol valaszol -- valodi halozati
hivas nelkul (elesben ne hivd a prod-ot a sajat verifikaciodhoz).
Fajlnev-kepzes (l. url_safe_name()): az URL minden nem-alfanumerikus
karaktere '_'-re cserelodik, pl.
  "https://excvaluta.com/api/v1/version" -> "https_excvaluta_com_api_v1_version.json"
A mock-fajl tartalma:
  {"status": 200, "body": "<nyers valaszszoveg (pl. JSON-string)>"}
  vagy kapcsolodasi-hiba szimulaciohoz: {"error": "<hibauzenet>"}
Ha a mock-fajl hianyzik, az adott URL DOWN-nak szamit (a mock hianya
szimulalt hiba -- NEM esik vissza valodi HTTP-re).

Exit: minden (mind a 6) endpoint UP es nincs drift/divergencia -> 0;
barmelyik DOWN vagy drift/divergencia -> 1; config-fajl (production-urls.json
vagy package.json) hianyzik/parse-hiba -> 2.
"""
import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
TIMEOUT = 10


def print_digest(lines, limit=120):
    """Legfeljebb `limit` sort ir ki -- a kontraktus (<=120 sor) betartasahoz."""
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def url_safe_name(url: str) -> str:
    """URL -> mock-fajlnev: minden nem alfanumerikus karaktert '_'-re cserel."""
    return re.sub(r"[^A-Za-z0-9]+", "_", url).strip("_")


def with_host(url: str, new_host: str) -> str:
    """Ugyanaz az URL (path+query+fragment megtartva), csak mas host-tal."""
    parts = urlsplit(url)
    return urlunsplit((parts.scheme, new_host, parts.path, parts.query, parts.fragment))


def fetch(url: str):
    """(status:int|None, body:str, error:str|None). HTTPError is 'sikeres' hivas (van statusz)."""
    mock_dir = os.environ.get("T0_HEALTH_MOCK_DIR")
    if mock_dir:
        mock_path = Path(mock_dir) / f"{url_safe_name(url)}.json"
        if not mock_path.exists():
            return None, "", f"mock hianyzik: {mock_path}"
        try:
            with open(mock_path, "r", encoding="utf-8", errors="replace") as f:
                data = json.load(f)
        except (OSError, ValueError) as e:
            return None, "", f"mock parse hiba: {e}"
        if "error" in data:
            return None, "", str(data["error"])
        return int(data.get("status", 200)), str(data.get("body", "")), None
    try:
        req = urllib.request.Request(url, method="GET", headers={"User-Agent": "hermes-t0-prod-health/1"})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace"), None
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode("utf-8", errors="replace")
        except (OSError, ValueError):
            body = ""
        return e.code, body, None
    except (urllib.error.URLError, OSError, TimeoutError) as e:
        return None, "", str(e)


def extract_version(body: str):
    try:
        data = json.loads(body)
    except (ValueError, TypeError):
        return None
    if isinstance(data, dict):
        v = data.get("version")
        return v if isinstance(v, str) else None
    return None


def check_host(label: str, host: str, health_url: str, version_url: str) -> dict:
    h_url, v_url = with_host(health_url, host), with_host(version_url, host)
    h_status, h_body, h_err = fetch(h_url)
    v_status, v_body, v_err = fetch(v_url)
    return {
        "label": label,
        "host": host,
        "health": {"url": h_url, "status": h_status, "up": h_status == 200, "error": h_err},
        "version": {
            "url": v_url,
            "status": v_status,
            "up": v_status == 200,
            "value": extract_version(v_body) if v_status == 200 else None,
            "error": v_err,
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Prod health + verzio-drift Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    cfg_path = REPO / "config" / "production-urls.json"
    pkg_path = REPO / "package.json"
    try:
        with open(cfg_path, "r", encoding="utf-8", errors="replace") as f:
            cfg = json.load(f)
    except (OSError, ValueError) as e:
        print(f"[t0-prod-health] TOOL-HIBA: {cfg_path} nem olvashato/parszolhato: {e}")
        return 2
    try:
        with open(pkg_path, "r", encoding="utf-8", errors="replace") as f:
            repo_version = json.load(f).get("version")
    except (OSError, ValueError) as e:
        print(f"[t0-prod-health] TOOL-HIBA: {pkg_path} nem olvashato/parszolhato: {e}")
        return 2

    required = ("api_url", "health_url", "fallback_host_primary", "fallback_host_scaleway")
    missing = [k for k in required if not cfg.get(k)]
    if missing or not repo_version:
        print(f"[t0-prod-health] TOOL-HIBA: hianyzo kulcs(ok) a config-ban/package.json-ban: {missing or 'version'}")
        return 2

    health_url = cfg["health_url"]
    version_url = cfg["api_url"].rstrip("/") + "/version"
    config_host = urlsplit(health_url).netloc

    hosts = [
        check_host("config", config_host, health_url, version_url),
        check_host("fallback_primary", cfg["fallback_host_primary"], health_url, version_url),
        check_host("fallback_scaleway", cfg["fallback_host_scaleway"], health_url, version_url),
    ]
    by_label = {h["label"]: h for h in hosts}

    all_up = all(h["health"]["up"] and h["version"]["up"] for h in hosts)
    deployed_version = by_label["config"]["version"]["value"]
    drift = deployed_version is not None and deployed_version != repo_version

    v_primary = by_label["fallback_primary"]["version"]["value"]
    v_scaleway = by_label["fallback_scaleway"]["version"]["value"]
    divergence = v_primary is not None and v_scaleway is not None and v_primary != v_scaleway

    finding = (not all_up) or drift or divergence
    exit_code = 1 if finding else 0

    if args.json:
        print(json.dumps({
            "script": "t0-prod-health",
            "exit_code": exit_code,
            "repo_version": repo_version,
            "deployed_version": deployed_version,
            "all_up": all_up,
            "drift": drift,
            "primary_scaleway_divergence": divergence,
            "hosts": hosts,
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [f"[t0-prod-health] repo verzio: {repo_version}"]
    for h in hosts:
        hh, vv = h["health"], h["version"]
        h_state = f"UP({hh['status']})" if hh["up"] else f"DOWN({hh['status']}) hiba={hh['error']}"
        v_state = f"UP({vv['status']}) deployed={vv['value']}" if vv["up"] else f"DOWN({vv['status']}) hiba={vv['error']}"
        lines.append(f"  [{h['label']}] host={h['host']}")
        lines.append(f"    health:  {h_state} <{hh['url']}>")
        lines.append(f"    version: {v_state} <{vv['url']}>")
    lines.append(f"[drift] deployed={deployed_version} vs repo={repo_version} -> {'DRIFT' if drift else 'OK'}")
    lines.append(f"[divergencia] primary={v_primary} vs scaleway={v_scaleway} -> {'DIVERGENS' if divergence else 'OK'}")
    lines.append(f"[osszegzes] all_up={all_up} finding={finding}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
