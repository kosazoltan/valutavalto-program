"""
Valutavalto Tudasbazis Kereso — a valutavalto repo-ban
Hasznalat:
  python docs/valuta-kb-search.py search "arfolyam keszites"
  python docs/valuta-kb-search.py stats
  python docs/valuta-kb-search.py category "igenyfelmerés"
  python docs/valuta-kb-search.py schema
  python docs/valuta-kb-search.py sources
  python docs/valuta-kb-search.py gaps
  python docs/valuta-kb-search.py coverage
"""
import sqlite3, sys, os, io, unicodedata

DB_PATH = os.path.join(os.path.dirname(__file__), 'valuta-knowledge.sqlite')


def configure_stdout():
    if getattr(sys.stdout, "encoding", "").lower() == "utf-8":
        return
    buffer = getattr(sys.stdout, "buffer", None)
    if buffer is not None:
        sys.stdout = io.TextIOWrapper(buffer, encoding='utf-8', errors='replace')


def has_table(conn, table_name):
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
    ).fetchone()
    return row is not None


def normalize_for_search(value):
    if not value:
        return ""
    normalized = unicodedata.normalize('NFKD', value)
    normalized = ''.join(ch for ch in normalized if not unicodedata.combining(ch))
    return normalized.lower()

def search(query, limit=10):
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("""
        SELECT f.filename, f.category, f.type, f.size_kb,
               snippet(felmeres_fts, 1, '>>>', '<<<', '...', 50) as snippet
        FROM felmeres_fts
        JOIN felmeres_docs f ON f.id = felmeres_fts.rowid
        WHERE felmeres_fts MATCH ?
        ORDER BY rank LIMIT ?
    """, (query, limit)).fetchall()
    
    if not rows:
        # Fallback LIKE
        rows = conn.execute("""
            SELECT filename, category, type, size_kb, substr(content, 1, 200) as snippet
            FROM felmeres_docs
            WHERE content LIKE ? OR filename LIKE ?
            ORDER BY size_kb DESC LIMIT ?
        """, (f'%{query}%', f'%{query}%', limit)).fetchall()

    for r in rows:
        print(f"[{r[1]}] {r[0]} ({r[2]}, {r[3]}KB)")
        if r[4]:
            print(f"  {r[4][:200]}")

    audit_rows = []
    if has_table(conn, "source_artifacts") and has_table(conn, "artifact_text_extracts"):
        raw_audit_rows = conn.execute("""
            SELECT sa.absolute_path, sa.format_family, te.extract_type,
                   te.text_content, te.char_count
            FROM artifact_text_extracts te
            JOIN source_artifacts sa ON sa.artifact_id = te.artifact_id
            WHERE sa.source_root = 'RepoDocs'
            ORDER BY te.char_count DESC, sa.absolute_path
        """).fetchall()
        tokens = [token for token in normalize_for_search(query).split() if token]
        for path, format_family, extract_type, text_content, char_count in raw_audit_rows:
            haystack = normalize_for_search(path) + "\n" + normalize_for_search(text_content)
            if tokens and all(token in haystack for token in tokens):
                snippet = text_content.replace('\n', ' ')[:240]
                audit_rows.append((path, format_family, extract_type, snippet, char_count))
            if len(audit_rows) >= limit:
                break

    if audit_rows:
        print("\nRepoDocs / audit reteg:")
        for r in audit_rows:
            print(f"[RepoDocs] {r[0]} ({r[1]}, {r[2]})")
            if r[3]:
                print(f"  {r[3][:240]}")

    print(f"\n{len(rows) + len(audit_rows)} talalat")
    conn.close()

def stats():
    conn = sqlite3.connect(DB_PATH)
    total = conn.execute("SELECT COUNT(*), SUM(size_kb) FROM felmeres_docs").fetchone()
    cats = conn.execute("SELECT category, COUNT(*), SUM(size_kb) FROM felmeres_docs GROUP BY category ORDER BY COUNT(*) DESC").fetchall()
    types = conn.execute("SELECT type, COUNT(*), SUM(size_kb) FROM felmeres_docs GROUP BY type ORDER BY COUNT(*) DESC").fetchall()
    
    print(f"Dokumentumok: {total[0]}")
    print(f"Osszes meret: {round(total[1]/1024, 1)} MB\n")
    print("Kategoriak:")
    for c in cats:
        print(f"  {c[0]}: {c[1]} db, {round(c[2])} KB")
    print("\nTipusok:")
    for t in types:
        print(f"  {t[0]}: {t[1]} db, {round(t[2])} KB")

    if has_table(conn, "source_artifacts"):
        art_total = conn.execute("SELECT COUNT(*) FROM source_artifacts").fetchone()[0]
        extract_total = conn.execute("SELECT COUNT(*) FROM artifact_text_extracts").fetchone()[0]
        gap_total = conn.execute("SELECT COUNT(*) FROM knowledge_gaps").fetchone()[0]
        print("\nAudit reteg:")
        print(f"  source_artifacts: {art_total}")
        print(f"  artifact_text_extracts: {extract_total}")
        print(f"  knowledge_gaps: {gap_total}")
    conn.close()

def category(cat, limit=20):
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("""
        SELECT filename, type, size_kb, substr(content, 1, 100) 
        FROM felmeres_docs WHERE category=? ORDER BY size_kb DESC LIMIT ?
    """, (cat, limit)).fetchall()
    for r in rows:
        print(f"  {r[0]} ({r[1]}, {r[2]}KB)")
    print(f"\n{len(rows)} db a '{cat}' kategoriaban")
    conn.close()


def schema():
    conn = sqlite3.connect(DB_PATH)
    tables = conn.execute("""
        SELECT name FROM sqlite_master
        WHERE type='table' AND name NOT LIKE 'sqlite_%'
        ORDER BY name
    """).fetchall()
    print("Tabla schema osszesito:")
    for (table_name,) in tables:
        cols = conn.execute(f"PRAGMA table_info({table_name})").fetchall()
        col_names = ', '.join(col[1] for col in cols)
        print(f"  - {table_name}: {col_names}")
    conn.close()


def sources(limit=20):
    conn = sqlite3.connect(DB_PATH)
    if not has_table(conn, "source_artifacts"):
        print("Nincs source_artifacts tabla.")
        conn.close()
        return
    rows = conn.execute("""
        SELECT source_root, format_family, visibility_status, COUNT(*)
        FROM source_artifacts
        GROUP BY source_root, format_family, visibility_status
        ORDER BY source_root, COUNT(*) DESC
        LIMIT ?
    """, (limit,)).fetchall()
    print("Forras artifact statisztika:")
    for row in rows:
        print(f"  {row[0]} | {row[1]} | {row[2]}: {row[3]}")
    conn.close()


def gaps(limit=20):
    conn = sqlite3.connect(DB_PATH)
    if not has_table(conn, "knowledge_gaps"):
        print("Nincs knowledge_gaps tabla.")
        conn.close()
        return
    rows = conn.execute("""
        SELECT severity, gap_type, resolution_status, substr(description, 1, 120)
        FROM knowledge_gaps
        ORDER BY severity, gap_type, created_at DESC
        LIMIT ?
    """, (limit,)).fetchall()
    print("Nyitott / rogzitett gap-ek:")
    for row in rows:
        print(f"  [{row[0]}] {row[1]} / {row[2]} - {row[3]}")
    conn.close()


def coverage(limit=20):
    conn = sqlite3.connect(DB_PATH)
    if not has_table(conn, "knowledge_coverage"):
        print("Nincs knowledge_coverage tabla.")
        conn.close()
        return
    rows = conn.execute("""
        SELECT source_root, topic_id, artifact_count_seen, artifact_count_indexed, coverage_percent
        FROM knowledge_coverage
        ORDER BY coverage_percent ASC, artifact_count_seen DESC
        LIMIT ?
    """, (limit,)).fetchall()
    print("Coverage osszesito:")
    for row in rows:
        print(f"  {row[0]} | {row[1]}: seen={row[2]}, indexed={row[3]}, coverage={row[4]}%")
    conn.close()

if __name__ == '__main__':
    configure_stdout()
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'stats'
    args = ' '.join(sys.argv[2:]) if len(sys.argv) > 2 else ''
    if cmd == 'search': search(args)
    elif cmd == 'stats': stats()
    elif cmd == 'category': category(args)
    elif cmd == 'schema': schema()
    elif cmd == 'sources': sources()
    elif cmd == 'gaps': gaps()
    elif cmd == 'coverage': coverage()
    else: print("Usage: valuta-kb-search.py <search|stats|category|schema|sources|gaps|coverage> [args]")
