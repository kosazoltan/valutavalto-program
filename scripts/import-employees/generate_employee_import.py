#!/usr/bin/env python3
"""
EBC dolgozói törzs (employee) import-SQL generátor — CSAK NEM-ÉRZÉKENY mezők.

Kósa Zoltán user-direktíva (2026-05-21): a dolgozói törzs HR-táblát (employee) a
hivatalos személyi-adat Excelből töltjük fel, DE a program szándékosan NEM kezel
érzékeny adatot. KIMARAD: TAJ-szám, adóazonosító, anyja neve, születési hely/dátum,
személyi igazolvány szám, lakcímek, bankszámla, SZÉP-kártya, bér, adókedvezmények.
BEKERÜL: szervezeti egység (munkahely), név, FEOR, munkakör, jogviszony-dátumok.

A script PII-mentes: az Excel elérési útját és a worker-exportot paraméterből kapja,
maga nem tartalmaz személyes adatot. A GENERÁLT SQL nevet+munkakört tartalmaz —
azt NEM commitoljuk a repóba (runtime artefakt, lásd .gitignore).

Worker-illesztés: a worker.name (teljes név) ellen normalizált egyezés
(Vezetéknév + Keresztnév). Alias-térkép a hivatalos↔rövid névkülönbségekre.

Használat:
  python generate_employee_import.py <excel.xls> <prod_workers.txt> <output.sql>
    prod_workers.txt formátuma: "id|code|name" soronként (psql -At -F'|' export).
"""
import sys, re, unicodedata
import pandas as pd

SHEET = 'EBC Zrt dolgozói lista'

# Hivatalos (Excel) -> worker rövid név alias, ha a normalizált egyezés nem fog.
NAME_ALIASES = {
    'borossebesine bali henriett anita': 'bali henrietta',
}

# Csak ezeket az oszlopokat olvassuk az Excelből (a többi — érzékeny — meg sem érintjük).
COLS = {
    'Sorszám': 'serial',
    'szervezeti egység/terület': 'org',
    'Vezetéknév': 'last',
    'Keresztnév': 'first',
    'FEOR': 'feor',
    'Munkakör': 'job',
    'Jogviszony kezdete': 'emp_start',
    'Jogviszony megnevezése': 'emp_type',
    'Jogviszony vége': 'emp_end',
}


def norm(s):
    if s is None:
        return ''
    s = str(s).strip().lower()
    s = ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')
    return re.sub(r'\s+', ' ', s)


def sql_str(v):
    if v is None or (isinstance(v, float) and pd.isna(v)) or str(v).strip() == '':
        return 'NULL'
    return "'" + str(v).strip().replace("'", "''") + "'"


def sql_date(v):
    if v is None or (isinstance(v, float) and pd.isna(v)) or str(v).strip() == '':
        return 'NULL'
    try:
        d = pd.to_datetime(v, errors='coerce')
        if pd.isna(d):
            return 'NULL'
        return "'" + d.strftime('%Y-%m-%d') + "'"
    except Exception:
        return 'NULL'


def sql_int(v):
    try:
        if v is None or pd.isna(v):
            return 'NULL'
        return str(int(v))
    except Exception:
        return 'NULL'


def sql_feor(v):
    """FEOR kód: ha számként jött (pl. 1323.0), egész-szám stringre normáljuk ('1323')."""
    if v is None or (isinstance(v, float) and pd.isna(v)) or str(v).strip() == '':
        return 'NULL'
    s = str(v).strip()
    m = re.fullmatch(r'(\d+)\.0+', s)
    if m:
        s = m.group(1)
    return "'" + s.replace("'", "''") + "'"


def main():
    excel, workers_file, out_sql = sys.argv[1], sys.argv[2], sys.argv[3]

    workers = {}
    for line in open(workers_file, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line or '|' not in line:
            continue
        wid, code, name = line.split('|', 2)
        workers[norm(name)] = wid

    df = pd.read_excel(excel, sheet_name=SHEET, header=0, engine='xlrd')
    df = df[df['Vezetéknév'].notna() & df['Keresztnév'].notna()]

    rows, matched, unmatched = [], 0, []
    for _, r in df.iterrows():
        last = str(r['Vezetéknév']).strip()
        first = str(r['Keresztnév']).strip()
        key = norm(f'{last} {first}')
        wid = workers.get(key) or workers.get(NAME_ALIASES.get(key, ''))
        if wid:
            matched += 1
        else:
            unmatched.append(f'{last} {first}')
        rows.append({
            'wid': wid,
            'serial': sql_int(r.get('Sorszám')),
            'org': sql_str(r.get('szervezeti egység/terület')),
            'last': sql_str(last),
            'first': sql_str(first),
            'feor': sql_feor(r.get('FEOR')),
            'job': sql_str(r.get('Munkakör')),
            'emp_start': sql_date(r.get('Jogviszony kezdete')),
            'emp_type': sql_str(r.get('Jogviszony megnevezése')),
            'emp_end': sql_date(r.get('Jogviszony vége')),
        })

    with open(out_sql, 'w', encoding='utf-8') as f:
        f.write('-- EBC employee HR-törzs import (NEM-érzékeny mezők, worker-linkkel)\n')
        f.write('-- Generálva: scripts/import-employees/generate_employee_import.py\n')
        f.write('-- FIGYELEM: ez a fájl neveket+munkaköröket tartalmaz — NEM commitolandó.\n')
        f.write('BEGIN;\n')
        f.write("DELETE FROM employee WHERE company_id = (SELECT id FROM company WHERE code='EBC');\n")
        for r in rows:
            wid = r['wid'] if r['wid'] else 'NULL'
            f.write(
                "INSERT INTO employee (company_id, worker_id, serial_number, organization_unit, "
                "last_name, first_name, feor_code, job_title, employment_start_date, "
                "employment_type, employment_end_date, is_active, created_at) VALUES ("
                "(SELECT id FROM company WHERE code='EBC'), "
                f"{wid}, {r['serial']}, {r['org']}, {r['last']}, {r['first']}, "
                f"{r['feor']}, {r['job']}, {r['emp_start']}, {r['emp_type']}, {r['emp_end']}, "
                "TRUE, NOW());\n"
            )
        f.write("SELECT count(*) AS imported, count(worker_id) AS linked FROM employee "
                "WHERE company_id = (SELECT id FROM company WHERE code='EBC');\n")
        f.write('COMMIT;\n')

    print(f'Rekord: {len(rows)} | worker-linkelt: {matched} | linkeletlen: {len(unmatched)}')
    print('Linkeletlen (worker_id=NULL):', ', '.join(unmatched) if unmatched else '(nincs)')
    print(f'SQL kiírva: {out_sql}')


if __name__ == '__main__':
    main()
