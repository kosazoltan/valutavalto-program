"""ELES LANC-PROBA: a telepitett kliens szemszogebol ertekeli a publikalt manifestet.

MIERT KELL: a release-assetek belso konzisztenciajat a `verify-release.ps1` meri. Ez a
script a KLIENS OLDALI dontesi logikat futtatja le a VALODI, elesben publikalt
manifesten: letolti a `releases/latest/download/update-manifest.json`-t (ugyanazt az
URL-t, amit a penztargep hasznal), majd a `suite-update.ts` szabalyai szerint eldonti,
hogy a flotta ervenyes frissitest lat-e.

Hasznalat:
    python verify-update-chain.py --installed 2.28.79
    python verify-update-chain.py --installed 2.28.79 --expect 2.28.80 --rollout 25
    python verify-update-chain.py --assets C:\\...\\valutavalto-v2.28.80
    VV_MANIFEST_URL=https://... python verify-update-chain.py --installed 2.28.79

Exit: 0 = a lanc rendben, 1 = szabalysertes, 2 = nem futtathato.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

DEFAULT_MANIFEST_URL = (
    'https://github.com/kosazoltan/valutavalto-program/releases/latest/download/update-manifest.json'
)
INSTALLER_FILE_PATTERN = re.compile(r'^Penztar-Setup-[0-9A-Za-z._-]+\.exe$')
SEMVER = re.compile(r'^(\d+)\.(\d+)\.(\d+)$')

# A GitHub release-CDN elutasithatja a User-Agent nelkuli kereseket. Az Electron
# `fetch` mindig kuld UA-t, ezert a proba is kuld — kulonben olyan hibat jelentenenk,
# ami a valos kliensnel nem letezik.
USER_AGENT = 'valutavalto-update-chain-probe/1.0'
# A CDN idonkent valasz nelkul bontja a kapcsolatot -> korlatozott ismetles.
HTTP_RETRIES = 3
HTTP_RETRY_DELAY_S = 3
# Tranziens HTTP-statuszok: ezekre ERDEMES ujraprobalni (a CDN/rate-limit atmeneti
# allapotai). A 404/403 NEM ilyen — az valos hiba, azonnal buknia kell.
TRANSIENT_HTTP_STATUS = frozenset({408, 425, 429, 500, 502, 503, 504})


def _request(url: str, headers: dict[str, str] | None = None) -> urllib.request.Request:
    """Kereses osszeallitasa — a User-Agent MINDIG a mienk (nem irhato felul)."""
    merged = dict(headers or {})
    merged['User-Agent'] = USER_AGENT
    return urllib.request.Request(url, headers=merged)


def _http_with_retry(url: str, timeout: int, headers: dict[str, str] | None, reader):
    """Kozos ismetles-logika: tranziens halozati hiba ES tranziens HTTP-statusz eseten.

    MIERT AZ ISMETLES: a GitHub release-CDN idonkent valasz nelkul bontja a kapcsolatot
    ("Remote end closed connection without response"), illetve atmeneti 429/5xx-et adhat
    — ugyanaz a keres masodpercekkel kesobb 200-at ad. Ez tranziens, NEM a lanc hibaja;
    egy verifikalo scriptnek pedig nem szabad emiatt hamis FAIL-t jelentenie.
    A VALOS hibat (404 hianyzo asset, 403) az ismetles nem fedi el: azok NEM tranziens
    statuszok, ezert azonnal felszallnak.
    """
    last: Exception | None = None
    for attempt in range(1, HTTP_RETRIES + 1):
        try:
            with urllib.request.urlopen(_request(url, headers), timeout=timeout) as resp:
                return reader(resp)
        except urllib.error.HTTPError as exc:
            if exc.code not in TRANSIENT_HTTP_STATUS:
                raise
            last = exc
        except Exception as exc:  # noqa: BLE001
            last = exc
        if attempt < HTTP_RETRIES:
            print(
                f'[INFO] tranziens hiba ({type(last).__name__}: {last}), '
                f'ujraprobalkozas {attempt}/{HTTP_RETRIES - 1}...'
            )
            time.sleep(HTTP_RETRY_DELAY_S * attempt)
    raise last if last else RuntimeError('http: ismeretlen hiba')


def http_get(url: str, timeout: int = 60, headers: dict[str, str] | None = None) -> bytes:
    """HTTP GET korlatozott ujraprobalkozassal."""
    return _http_with_retry(url, timeout, headers, lambda resp: resp.read())


def http_get_range(url: str, timeout: int = 60) -> tuple[int, int]:
    """GET `Range: bytes=0-0` fejleccel — (status, kapott bajtok).

    NEM HTTP HEAD (a nev korabban ezt sugallta): a keres GET, csak az elso bajtot kerjuk,
    igy a link elerhetosege 276 MB letoltese nelkul igazolhato.
    """
    return _http_with_retry(
        url,
        timeout,
        {'Range': 'bytes=0-0'},
        lambda resp: (resp.status, len(resp.read(1))),
    )


failed = 0


def check(name: str, ok: bool, detail: str = '') -> None:
    global failed
    if ok:
        print(f'[PASS] {name}')
    else:
        print(f'[FAIL] {name}')
        if detail:
            print(f'       {detail}')
        failed += 1


def is_safe_installer_name(file: object) -> bool:
    """A kliens `isSafeInstallerFileName` szabalyainak port-ja."""
    if not isinstance(file, str) or not file or len(file) > 128:
        return False
    if re.search(r'[\\/]', file):
        return False
    if '..' in file:
        return False
    if re.match(r'^[A-Za-z]:', file):
        return False
    if os.path.basename(file) != file:
        return False
    return bool(INSTALLER_FILE_PATTERN.match(file))


def is_newer(candidate: str, current: str) -> bool:
    """A kliens `isNewerVersion` port-ja: szigoru semver, downgrade tilos."""
    m1 = SEMVER.match(str(candidate).strip())
    m2 = SEMVER.match(str(current).strip())
    if not m1 or not m2:
        return False
    for a, b in zip(map(int, m1.groups()), map(int, m2.groups())):
        if a > b:
            return True
        if a < b:
            return False
    return False


def is_in_rollout(version: str, percent: int, machine_id: str) -> bool:
    """A platform `isInRollout` port-ja (determinisztikus 32-bites hash)."""
    if percent <= 0:
        return False
    if percent >= 100:
        return True
    text = version + machine_id
    h = 0
    for ch in text:
        h = ((h << 5) - h + ord(ch)) & 0xFFFFFFFF
        if h >= 0x80000000:
            h -= 0x100000000
    return abs(h) % 100 < percent


def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with io.open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    global failed
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--installed', required=True, help='a flottan futo verzio, pl. 2.28.79')
    parser.add_argument('--expect', default='', help='az elvart uj verzio (opcionalis)')
    parser.add_argument(
        '--rollout',
        type=int,
        default=-1,
        help='az elvart rolloutPercent (opcionalis; -1 = csak informacio)',
    )
    parser.add_argument(
        '--assets',
        default=os.path.dirname(os.path.abspath(__file__)),
        help='a letoltott release-assetek konyvtara (a hash-osszevetéshez)',
    )
    parser.add_argument(
        '--url',
        default=os.environ.get('VV_MANIFEST_URL', DEFAULT_MANIFEST_URL),
        help='a manifest URL-je (VV_MANIFEST_URL env is hasznalhato)',
    )
    parser.add_argument(
        '--check-url',
        action='store_true',
        help='a manifestben publikalt telepito-URL tenyleges elerhetosegenek ellenorzese (range-keres)',
    )
    args = parser.parse_args()

    if not SEMVER.match(args.installed):
        print(f'[FAIL] a --installed nem ervenyes semver: {args.installed}')
        return 2

    print('=== ELES LANC-PROBA: telepitett kliens -> publikalt manifest ===')
    print(f'Telepitett verzio: v{args.installed}')
    print(f'Manifest URL:      {args.url}')
    print(f'Asset-konyvtar:    {args.assets}')
    print()

    # --- 1. A publikalt manifest letoltese ---
    # A GitHub release-CDN User-Agent nelkuli kereseket elutasithat ("Remote end closed
    # connection without response"), az Electron/`fetch` pedig mindig kuld UA-t — ezert
    # itt is kell, kulonben a script olyan hibat jelentene, ami a kliensnel nem letezik.
    try:
        raw = http_get(args.url).decode('utf-8')
        check('a manifest elerheto a publikalt URL-en (anonim, token nelkul)', True)
    except Exception as exc:  # noqa: BLE001
        check('a manifest elerheto a publikalt URL-en', False, str(exc))
        return 1

    try:
        manifest = json.loads(raw)
    except Exception as exc:  # noqa: BLE001
        check('a manifest ervenyes JSON', False, str(exc))
        return 1
    check('a manifest ervenyes JSON', True)

    # --- 2. parseManifest szabalyai ---
    print()
    print('--- A kliens parseManifest-szabalyai ---')
    check('schemaVersion == 1', manifest.get('schemaVersion') == 1, str(manifest.get('schemaVersion')))
    version = str(manifest.get('version', ''))
    check('version semver formatum', bool(SEMVER.match(version)), version)
    penztar = manifest.get('penztar') if isinstance(manifest.get('penztar'), dict) else {}
    check('van penztar blokk', bool(penztar))
    file_name = penztar.get('file', '')
    check('a fajlnev atmegy a path-traversal szuron', is_safe_installer_name(file_name), str(file_name))
    url = penztar.get('url', '')
    check('a letoltesi URL HTTPS', isinstance(url, str) and url.startswith('https://'), str(url))
    sha = str(penztar.get('sha256', ''))
    check('a sha256 64 hexa karakter', bool(re.match(r'^[0-9a-f]{64}$', sha, re.I)), sha[:20] + '...')
    silent = penztar.get('silentArgs') or []
    check(
        'a silentArgs csak engedelyezett zaszlo',
        all(a in ('/S', '/NCRC') for a in silent),
        str(silent),
    )
    # A `sizeBytes` a kliensben OPCIONALIS — csak informacio.
    if penztar.get('sizeBytes') is None:
        print('[INFO] sizeBytes nincs megadva (a kliensben opcionalis)')

    # --- 3. A frissitesi dontes ---
    print()
    print(f'--- A frissitesi dontes (telepitett: v{args.installed}) ---')
    check(
        f'a manifest verzioja UJABB a telepitettnel ({version} > {args.installed})',
        is_newer(version, args.installed),
        f'{version} vs {args.installed}',
    )
    if args.expect:
        check(f'a manifest verzioja a vart {args.expect}', version == args.expect, f'kapott: {version}')
    check('a SAJAT verzio NEM telepitheto ujra (ismetles tilalom)', not is_newer(version, version))
    check(
        'egy KORABBI verzio nem telepitheto (downgrade tilalom)',
        not is_newer(args.installed, version),
        f'{args.installed} vs {version}',
    )

    # --- 4. Rollout ---
    print()
    raw_rollout = manifest.get('rolloutPercent')
    # A kliens hianyzo/ertelmezhetetlen ertek eseten 100-at hasznal.
    try:
        rollout = 100 if raw_rollout is None else int(raw_rollout)
    except (TypeError, ValueError):
        rollout = 100
        print(f'[INFO] a rolloutPercent ertelmezhetetlen ({raw_rollout!r}) -> a kliens 100%-ot hasznal')
    print(f'--- Staged rollout: {rollout}% ---')
    if args.rollout >= 0:
        check(f'a rolloutPercent a vart {args.rollout}', rollout == args.rollout, f'kapott: {rollout}')

    machines = [f'PENZTAR-{i:02d}' for i in range(72)]
    included = [m for m in machines if is_in_rollout(version, rollout, m)]
    ratio = len(included) / len(machines) * 100
    print(f'       72 szimulalt gep kozul {len(included)} kapja meg ({ratio:.1f}%)')

    if rollout <= 0:
        # KILL-SWITCH: ilyenkor a helyes viselkedes az, hogy SENKI nem frissul.
        check('kill-switch (rolloutPercent<=0): SENKI nem frissul', len(included) == 0, f'{len(included)}/72')
    elif rollout >= 100:
        check('teljes rollout (>=100%): MINDEN gep frissul', len(included) == len(machines), f'{len(included)}/72')
    else:
        check(
            'reszleges rollout: nem mindenki es nem senki',
            0 < len(included) < len(machines),
            f'{len(included)}/72',
        )
        check(
            f'a rollout aranya a kert kozeleben ({rollout}% +/- 15 pont)',
            abs(ratio - rollout) <= 15,
            f'kert={rollout}% mert={ratio:.1f}%',
        )
    # A kill-switch mukodese fuggetlenul is igazolhato.
    check(
        'rolloutPercent=0 eseten a kapu SENKIT nem enged be',
        not any(is_in_rollout(version, 0, m) for m in machines),
    )

    # --- 5. A hivatkozott telepito integritasa ---
    print()
    print('--- A hivatkozott telepito integritasa ---')
    check('a letoltesi URL a manifest fajlnevere vegzodik', isinstance(url, str) and url.endswith(str(file_name)), str(url))

    local = os.path.join(args.assets, str(file_name)) if file_name else ''
    if local and os.path.exists(local):
        actual = sha256_of(local)
        check(
            'a manifest sha256-ja EGYEZIK a helyi telepito hash-evel',
            actual == sha.lower(),
            f'manifest={sha} actual={actual}',
        )
        size = penztar.get('sizeBytes')
        if size is not None:
            check(
                'a manifest sizeBytes egyezik a tenyleges merettel',
                size == os.path.getsize(local),
                f'manifest={size} actual={os.path.getsize(local)}',
            )
    else:
        print(f'[INFO] a telepito helyben nem elerheto ({local or "nincs fajlnev"}) — hash-osszevetes kihagyva')

    if args.check_url:
        # A publikalt URL TENYLEGES elerhetosege: 1 bajtos range-keres, hogy ne toltsunk
        # le 276 MB-ot csak azert, mert a link letezeset akarjuk igazolni.
        try:
            status, got = http_get_range(str(url))
            check(
                'a publikalt telepito-URL elerheto (range-keres)',
                status in (200, 206) and got == 1,
                f'HTTP {status}, {got} bajt',
            )
        except Exception as exc:  # noqa: BLE001
            check('a publikalt telepito-URL elerheto (range-keres)', False, str(exc))

    print()
    print('=' * 50)
    if failed:
        print(f'LANC-PROBA: FAIL - {failed} ellenorzes bukott.')
        return 1
    print(f'LANC-PROBA: PASS - a v{args.installed}-es kliens ERVENYES frissitest lat a v{version}-ben.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
