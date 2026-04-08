"""
Valutavalto Tudasbazis Kereso — a valutavalto repo-ban
Hasznalat:
  python docs/valuta-kb-search.py search "arfolyam keszites"
  python docs/valuta-kb-search.py stats
  python docs/valuta-kb-search.py category "igenyfelmerés"
"""
import sqlite3, sys, os, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

DB_PATH = os.path.join(os.path.dirname(__file__), 'valuta-knowledge.sqlite')

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
    print(f"\n{len(rows)} talalat")
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

if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'stats'
    args = ' '.join(sys.argv[2:]) if len(sys.argv) > 2 else ''
    if cmd == 'search': search(args)
    elif cmd == 'stats': stats()
    elif cmd == 'category': category(args)
    else: print("Usage: valuta-kb-search.py <search|stats|category> [args]")
