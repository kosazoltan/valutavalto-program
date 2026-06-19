#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
multi-tenant-audit.py --Potenciális multi-tenant companyId-lyuk felderítése.

Replaces: AI review "missing companyId filter" findings.

Keres:
  1. @Query annotációkban hiányzó companyId szűrő (JPA/JPQL)
  2. findAll() hívások service-ekben (nem szűrt lista)
  3. Repository metódusok companyId nélkül (findBy* de nem ByCompanyId*)

Usage:
  python scripts/dev-tools/multi-tenant-audit.py
  python scripts/dev-tools/multi-tenant-audit.py --strict   (findAll is hiba, nem csak figyelmeztetés)

Exit: 0 = clean, 1 = potential leaks found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import subprocess
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent.parent
SRC_JAVA = ROOT / "backend" / "src" / "main" / "java"

# JPA @Query pattern (JPQL --WHERE hiányzik companyId)
QUERY_ANNOTATION = re.compile(
    r'@Query\s*\(\s*(?:value\s*=\s*)?["\']([^"\']+)["\']', re.DOTALL
)

# Entitások amelyek BIZTOSAN multi-tenant hatókörűek (nem kell minden modell-fájlban)
MULTITENANT_ENTITIES = {
    "Transaction", "CashBalance", "CurrencyStock", "Branch", "Worker",
    "Customer", "AmlLog", "AuditLog", "DailyReport", "Transfer",
    "Denomination", "ExchangeRate", "RateWorkgroup", "StornedTransaction",
}

# JPQL companyId referencia
HAS_COMPANY_ID = re.compile(
    r'\bcompanyId\b|\bcompany_id\b|\bcompany\s*\.\s*id\b|'
    r'\bbranchId\b|\bbranchIds\b|\bbranch_id\b|\bbranch\s*\.\s*id\b|'
    r'\b\w*Branch\s*\.\s*id\b|\b\w*Worker\s*\.\s*id\b|'
    r'\bcashDeskId\b|\bvaultTerritoryId\b|\bworkerId\b',
    re.IGNORECASE,
)

IGNORED_DIRS = {"node_modules", ".git", "target", "dist", ".vite", "coverage"}


def rg(pattern: str, path: Path, extra_args: list[str] | None = None) -> list[str]:
    ignore = [arg for d in IGNORED_DIRS for arg in ("--glob", f"!**/{d}/**")]
    cmd = ["rg", "--no-heading", "--line-number", "--color=never",
           "-e", pattern, str(path)] + (extra_args or []) + ignore
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.stdout.strip().splitlines() if r.stdout.strip() else []


def check_jpql_queries(strict: bool) -> list[str]:
    """Find @Query annotations missing companyId filter."""
    issues: list[str] = []
    for java_file in SRC_JAVA.rglob("*Repository.java"):
        content = java_file.read_text(encoding="utf-8", errors="replace")
        lines   = content.splitlines()
        for i, line in enumerate(lines):
            if "@Query" not in line:
                continue
            # Collect the full annotation (may span multiple lines or string fragments).
            snippet = "\n".join(lines[i:i+16])
            if not QUERY_ANNOTATION.search(snippet):
                continue
            jpql = " ".join(re.findall(r'["\']([^"\']+)["\']', snippet))
            # Only check SELECT queries that return entity types
            if "SELECT" not in jpql.upper():
                continue
            if SAFE_RAW_CONTEXT.search(snippet):
                continue
            # Check if any multi-tenant entity is referenced
            mentions_tenant_entity = any(
                re.search(rf'\b{re.escape(e)}\b', jpql, re.IGNORECASE)
                for e in MULTITENANT_ENTITIES
            )
            if not mentions_tenant_entity:
                continue
            if not HAS_COMPANY_ID.search(jpql):
                rel = java_file.relative_to(ROOT)
                issues.append(f"  !  {rel}:{i+1}  JPQL missing companyId --{jpql[:80].strip()!r}")
    return issues


def check_findall_service(strict: bool) -> list[str]:
    """Find .findAll() in service classes."""
    raw = rg(r'\.findAll\(\)', SRC_JAVA, ["--glob", "*Service*.java"])
    issues: list[str] = []
    for line in raw:
        # Parse Windows path: path:linenum:content
        m = re.match(r'^(.+?):(\d+):(.*)$', line)
        if not m:
            continue
        fpath, lineno, content = m.group(1), m.group(2), m.group(3).strip()
        rel = str(Path(fpath).relative_to(ROOT))
        if strict:
            issues.append(f"  X  {rel}:{lineno}  findAll() --needs companyId filter")
        else:
            issues.append(f"  !  {rel}:{lineno}  findAll() --verify companyId scope: {content[:60]}")
    return issues


def check_repository_methods() -> list[str]:
    """Find findBy* repository methods that lack CompanyId."""
    raw = rg(r'\bfindBy[A-Z]\w+\b(?!.*CompanyId)', SRC_JAVA,
             ["--glob", "*Repository.java"])
    issues: list[str] = []
    seen: set[str] = set()
    for line in raw:
        m = re.match(r'^(.+?):(\d+):(.*)$', line)
        if not m:
            continue
        fpath, lineno, content = m.group(1), m.group(2), m.group(3).strip()
        # Only flag if a multi-tenant entity name appears in the file name
        fname = Path(fpath).stem.replace("Repository", "")
        if fname not in MULTITENANT_ENTITIES:
            continue
        key = f"{fpath}:{content[:40]}"
        if key in seen:
            continue
        seen.add(key)
        rel = str(Path(fpath).relative_to(ROOT))
        issues.append(f"  !  {rel}:{lineno}  {content[:70]} --no CompanyId scope?")
    return issues


# ── IDOR by-id detektor (2026-06-15 audit): "lista-scope-olt DE by-id-unscoped" aszimmetria ──
# Egy entitas multi-tenant, ha kozvetlen company_id-je VAN, vagy a tenancy egy szulon
# (branch/customer/transaction/worker/vaultTerritory/cashDesk) keresztul el.
MT_ENTITY_HINT = re.compile(
    r'company_id|\bcompanyId\b|branch_id|\bbranchId\b|\bcustomerId\b|\btransactionId\b|'
    r'\bcashDeskId\b|\bvaultTerritoryId\b|\bworkerId\b|'
    r'@ManyToOne[\s\S]{0,120}?\b(Branch|Customer|Transaction|Worker|VaultTerritory|CashRegisterDevice|Company)\b',
)

# Ownership-check jelolok (ha a metodus kornyezeteben van, NEM IDOR)
OWNERSHIP_MARKERS = re.compile(
    r'companyId|getCurrentCompanyId|getCurrentBranchId|existsByIdAndCompany|findByIdAndCompany|'
    r'AndCompany_?Id|getCompany\(\)\.getId|validateBranch|assertOwn|requireOwn|verif(y|ied)Company|'
    r'verif(y|ied)Tenant|verifyClosingTenant|InCompany|OwnBranch|OwnCompany|OwnWizard|OwnReport|'
    r'OwnCashDesk|OwnTransaction|verifyBranchOwnership|assertBranch|requireBranch|isOwnBranch|'
    r'InCurrentCompany|assertAccountInCaller|enforceBranchAccess|canAccess|assertOwnedBy|loadOwned|'
    r'loadScoped|requireCustomerIn|requireTransactionIn|assertDocumentParent|getCurrentWorkerId',
    re.IGNORECASE,
)

# Olvasaskori, scope nelkul is veszelytelen lookupok (sajat-kontextus / not-found-utan dob)
SAFE_RAW_CONTEXT = re.compile(r'findByIdForUpdate|orElse\(null\)\s*;\s*$', re.IGNORECASE)


def build_multitenant_entities() -> set[str]:
    ents: set[str] = set()
    edir = SRC_JAVA / "hu" / "puzzleir" / "valuta" / "entity"
    if not edir.exists():
        return ents
    for f in edir.rglob("*.java"):
        txt = f.read_text(encoding="utf-8", errors="replace")
        if MT_ENTITY_HINT.search(txt):
            ents.add(f.stem)
    return ents


def build_repo_entity_map() -> dict[str, str]:
    m: dict[str, str] = {}
    for f in SRC_JAVA.rglob("*Repository.java"):
        txt = f.read_text(encoding="utf-8", errors="replace")
        mm = re.search(r'interface\s+(\w+Repository)\s+extends\s+\w*(?:Jpa|CrudPaging|Crud)?Repository<\s*(\w+)\s*,', txt)
        if mm:
            m[mm.group(1)] = mm.group(2)
    return m


def check_findbyid_without_scope() -> list[str]:
    """Service/Controller: <repo>.findById(...) multi-tenant entitason, ownership-check NELKUL a kornyezetben."""
    mt = build_multitenant_entities()
    repo_entity = build_repo_entity_map()
    issues: list[str] = []
    targets = list(SRC_JAVA.rglob("*Service.java")) + list(SRC_JAVA.rglob("*Controller.java"))
    for f in targets:
        txt = f.read_text(encoding="utf-8", errors="replace")
        lines = txt.splitlines()
        # injektalt repo-mezok: TipusRepository varName
        var_entity: dict[str, str] = {}
        for vm in re.finditer(r'\b(\w+Repository)\s+(\w+)\s*[;,)=]', txt):
            ent = repo_entity.get(vm.group(1))
            if ent:
                var_entity[vm.group(2)] = ent
        for i, line in enumerate(lines):
            for cm in re.finditer(r'\b(\w+)\.findById\s*\(([^)]*)', line):
                ent = var_entity.get(cm.group(1))
                if not ent or ent not in mt:
                    continue
                arg = cm.group(2)
                # Sajat-kontextus (a hivo sajat worker/branch/company id-ja) -> NEM cross-tenant IDOR
                if re.search(r'getCurrent\w*|currentWorker|currentBranch|currentUser|\bme\b|principal', arg, re.IGNORECASE):
                    continue
                lo, hi = max(0, i - 32), min(len(lines), i + 36)
                window = "\n".join(lines[lo:hi])
                if OWNERSHIP_MARKERS.search(window):
                    continue
                rel = str(f.relative_to(ROOT))
                issues.append(f"  ?  {rel}:{i+1}  {cm.group(1)}.findById({arg.strip()[:30]}) -> {ent} — NINCS ownership-check")
    return issues


def main():
    args   = sys.argv[1:]
    strict = "--strict" in args
    if "--idor" in args:
        print("multi-tenant-audit --idor: by-id scope-hiany detektor\n")
        idor = check_findbyid_without_scope()
        if not idor:
            print("OK -- nincs gyanus by-id findById (multi-tenant entitason ownership-check nelkul)")
            sys.exit(0)
        print(f"[findById multi-tenant entitason, ownership-check nelkul] ({len(idor)} jelolt -- verifikald)")
        for x in idor:
            print(x)
        print(f"\n{len(idor)} potencialis by-id IDOR-jelolt. Mindegyiket verifikald (false-positive lehet).")
        sys.exit(1)

    print("multi-tenant-audit: scanning for companyId gaps...\n")

    jpql_issues  = check_jpql_queries(strict)
    findall_issues = check_findall_service(strict)
    repo_issues  = check_repository_methods()

    total = len(jpql_issues) + len(findall_issues) + len(repo_issues)

    if jpql_issues:
        print(f"[JPQL @Query without companyId] ({len(jpql_issues)})")
        for i in jpql_issues:
            print(i)
        print()

    if findall_issues:
        print(f"[findAll() in Service] ({len(findall_issues)})")
        for i in findall_issues:
            print(i)
        print()

    if repo_issues:
        print(f"[Repository findBy* without CompanyId] ({len(repo_issues)} --spot-check sample)")
        for i in repo_issues[:15]:
            print(i)
        if len(repo_issues) > 15:
            print(f"  ... ({len(repo_issues) - 15} more)")
        print()

    if total == 0:
        print("OK --no obvious multi-tenant gaps found")
        sys.exit(0)

    severity = "ERROR" if strict or jpql_issues else "WARNING"
    print(f"{severity}: {total} potential gap(s). Review each --false positives possible.")
    sys.exit(1 if (strict or jpql_issues) else 0)


if __name__ == "__main__":
    main()
