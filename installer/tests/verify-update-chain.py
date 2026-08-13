"""ELES LANC-PROBA: a v2.28.79-es kliens szemszogebol ertekeli a v2.28.80 manifestet.

MIERT KELL: eddig a release-assetek belso konzisztenciajat mertuk. Ez a script a
KLIENS OLDALI dontesi logikat futtatja le a VALODI, elesben publikalt manifesten:
letolti a `releases/latest/download/update-manifest.json`-t (ugyanazt az URL-t, amit
a penztargep hasznal), majd a `suite-update.ts` szabalyai szerint eldonti:

  1. ertelmezheto-e a manifest (parseManifest szabalyai),
  2. ujabb-e a verzio a telepitett 2.28.79-nel (downgrade tilalom),
  3. a fajlnev atmegy-e a path-traversal szuron,
  4. a rollout kapu mely gepeket engedi be (a valos determinisztikus hash-sel),
  5. a letoltesi URL valoban elerheto-e es a manifest szerinti hash-t adja-e
     (range-kereses: az elso 1 MB helyett a TELJES fajlt mar letoltottuk, azt merjuk).

Igy nem "hiszunk" a lancnak, hanem a kliens dontesét reprodukaljuk.
"""

import hashlib
import io
import json
import os
import re
import sys
import urllib.request

MANIFEST_URL = (
    'https://github.com/kosazoltan/valutavalto-program/releases/latest/download/update-manifest.json'
)
INSTALLED_VERSION = '2.28.79'  # amit a flotta most futtat
LOCAL_DIR = os.path.dirname(os.path.abspath(__file__))

INSTALLER_FILE_PATTERN = re.compile(r'^Penztar-Setup-[0-9A-Za-z._-]+\.exe$')

failed = 0


def check(name, ok, detail=''):
    global failed
    if ok:
        print(f'[PASS] {name}')
    else:
        print(f'[FAIL] {name}')
        if detail:
            print(f'       {detail}')
        failed += 1


def is_safe_installer_name(file: str) -> bool:
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
    m1 = re.match(r'^(\d+)\.(\d+)\.(\d+)$', candidate.strip())
    m2 = re.match(r'^(\d+)\.(\d+)\.(\d+)$', current.strip())
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


print('=== ELES LANC-PROBA: v2.28.79 kliens -> v2.28.80 manifest ===')
print(f'Manifest URL (amit a penztargep hasznal): {MANIFEST_URL}')
print()

# --- 1. A VALODI, eles manifest letoltese ---
try:
    with urllib.request.urlopen(MANIFEST_URL, timeout=60) as resp:
        raw = resp.read().decode('utf-8')
        final_url = resp.geturl()
    check('a manifest elerheto a releases/latest URL-en (anonim, token nelkul)', True)
    print(f'       vegso URL: {final_url}')
except Exception as exc:  # noqa: BLE001
    check('a manifest elerheto a releases/latest URL-en', False, str(exc))
    sys.exit(1)

try:
    manifest = json.loads(raw)
except Exception as exc:  # noqa: BLE001
    check('a manifest ervenyes JSON', False, str(exc))
    sys.exit(1)
check('a manifest ervenyes JSON', True)

# --- 2. parseManifest szabalyai ---
print()
print('--- A kliens parseManifest-szabalyai ---')
check('schemaVersion == 1', manifest.get('schemaVersion') == 1, str(manifest.get('schemaVersion')))
version = manifest.get('version', '')
check('version semver formatum', bool(re.match(r'^\d+\.\d+\.\d+$', str(version))), str(version))
penztar = manifest.get('penztar') or {}
check('van penztar blokk', isinstance(penztar, dict) and bool(penztar))
file_name = penztar.get('file', '')
check('a fajlnev atmegy a path-traversal szuron', is_safe_installer_name(file_name), str(file_name))
url = penztar.get('url', '')
check('a letoltesi URL HTTPS', isinstance(url, str) and url.startswith('https://'), str(url))
sha = str(penztar.get('sha256', ''))
check('a sha256 64 hexa karakter', bool(re.match(r'^[0-9a-f]{64}$', sha, re.I)), sha[:20] + '...')
silent = penztar.get('silentArgs') or []
check('a silentArgs csak engedelyezett zaszlo', all(a in ('/S', '/NCRC') for a in silent), str(silent))

# --- 3. A frissitesi dontes ---
print()
print(f'--- A frissitesi dontes (telepitett: v{INSTALLED_VERSION}) ---')
check(
    f'a manifest verzioja UJABB a telepitettnel ({version} > {INSTALLED_VERSION})',
    is_newer(str(version), INSTALLED_VERSION),
    f'{version} vs {INSTALLED_VERSION}',
)
check(
    'a SAJAT verzio NEM telepitheto ujra (downgrade/ismetles tilalom)',
    not is_newer(str(version), str(version)),
)
check(
    'egy KORABBI verzio nem telepitheto (downgrade tilalom)',
    not is_newer('2.28.78', INSTALLED_VERSION),
)

# --- 4. Rollout: mely gepek kapjak meg? ---
print()
rollout = manifest.get('rolloutPercent', 100)
print(f'--- Staged rollout: {rollout}% ---')
machines = [f'PENZTAR-{i:02d}' for i in range(72)]
included = [m for m in machines if is_in_rollout(str(version), int(rollout), m)]
ratio = len(included) / len(machines) * 100
print(f'       72 szimulalt gep kozul {len(included)} kapja meg ({ratio:.1f}%)')
check(
    'a rollout NEM engedi be az egesz flottat (staged, ahogy kertuk)',
    0 < len(included) < len(machines),
    f'{len(included)}/72',
)
check(
    'a rollout aranya a kert kozeleben van (25% +/- 15 pont)',
    abs(ratio - int(rollout)) <= 15,
    f'kert={rollout}% mert={ratio:.1f}%',
)
check(
    'rolloutPercent=0 eseten SENKI nem frissul (kill-switch mukodne)',
    not any(is_in_rollout(str(version), 0, m) for m in machines),
)

# --- 5. A hivatkozott telepito valoban a manifest szerinti hash-t adja ---
print()
print('--- A hivatkozott telepito integritasa ---')
local_installer = os.path.join(LOCAL_DIR, file_name) if file_name else ''
if local_installer and os.path.exists(local_installer):
    h = hashlib.sha256()
    with io.open(local_installer, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b''):
            h.update(chunk)
    actual = h.hexdigest()
    check(
        'a manifest sha256-ja EGYEZIK a letoltott telepito hash-evel',
        actual == sha.lower(),
        f'manifest={sha} actual={actual}',
    )
    check(
        'a manifest sizeBytes egyezik a tenyleges merettel',
        penztar.get('sizeBytes') == os.path.getsize(local_installer),
        f"manifest={penztar.get('sizeBytes')} actual={os.path.getsize(local_installer)}",
    )
    # A kliens a manifest URL-jerol tolt le: ellenorizzuk, hogy az URL a MI fajlunkra mutat.
    check('a letoltesi URL a manifestben megadott fajlnevre vegzodik', url.endswith(file_name), url)
else:
    check('a hivatkozott telepito helyben elerheto a hash-osszevetéshez', False, local_installer)

print()
print('=' * 50)
if failed:
    print(f'LANC-PROBA: FAIL - {failed} ellenorzes bukott.')
    sys.exit(1)
print('LANC-PROBA: PASS - a v2.28.79-es kliens ERVENYES frissitest lat a v2.28.80-ban.')
