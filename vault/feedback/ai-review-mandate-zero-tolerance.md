---
date: 2026-04-29
type: mandate
priority: P0 — KÖTELEZŐ ÉRVÉNYŰ
source: User direktíva (Kósa Zoltán) 2026-04-29 20:55 CEST
---

# AI Review Zero-Tolerance Mandate (v2.3.18+)

## A szabály

> **Addig nem léphetsz tovább, amíg a GitHub Codex + Sourcery AI Botok jelentéseit
> le nem kérted a GitHub-ról, és nem javítottad azokat a jelzett hibákat.**
>
> **Minden PR / Merge után KÖTELEZŐ:**
> 1. **Várni** a Sourcery + Codex review-kra
> 2. **Lekérdezni** a finding-eket (`gh api .../pulls/{N}/reviews + comments`)
> 3. **Javítani** **MINDEN** P0/P1/P2 jelzett hibát (NEM csak P0/P1!)
> 4. **Új PR-t nyitni** (follow-up), és újra végigmenni a cikluson
> 5. **CSAK akkor léphet a következő feladatra**, ha:
>    - Sourcery: "looks great!" (vagy minden finding kezelve / dismissed indoklással)
>    - Codex: csak boilerplate (vagy minden P0/P1 fixed)
>
> **Ezentúl minden PR-nél!**

## Tilos

❌ "P2 minor → defer" megjelölés indoklás nélkül
❌ Új feladat indítása amíg Sourcery/Codex finding nyitva
❌ Saját döntéssel "kihagyni" review-k figyelmen kívül hagyását
❌ "Looks great!" feltételezés review nélkül

## Engedélyezett

✅ P2 finding **dismiss + dokumentált indoklás** a vault-jegyzetben
   (pl. ">1000 LOC refaktor → külön sprint-be" — DE explicit GitHub issue-ban követni)
✅ Sourcery finding amit a Codex felülír (P1 elsőbbség P2 felett)
✅ Várás (sleep / poll) a review-érkezésre

## Munkafolyamat (KÖTELEZŐ)

```bash
# 1. Push + auto-merge enable
git push -u origin <branch>
gh pr merge $PR --squash --auto --delete-branch

# 2. CI poll + admin merge
while true; do
  state=$(gh pr view $PR --json state,mergeStateStatus --jq '.state + "/" + .mergeStateStatus')
  if echo "$state" | grep -q 'MERGED'; then break; fi
  # ... pending/failing check
done

# 3. KÖTELEZŐ Sourcery + Codex review query
gh api "repos/.../pulls/$PR/reviews" --jq '.[] | select(...sourcery|codex...) | .body'
gh api "repos/.../pulls/$PR/comments" --jq '...'

# 4. Ha van új P0/P1/P2 finding → ÚJ PR follow-up branch
git checkout -b fix/v$NEXT-followup main
# fix... commit... push... merge...

# 5. ISMÉTELNI a 3-4. lépést amíg Sourcery "looks great!" + Codex tiszta
```

## Időkeret-becslés

- 1 PR review-cycle: ~2-3 perc (Sourcery query → fix → push → merge)
- Egy follow-up PR átlagosan 5-15 LOC változás
- 3-5 review-iteráció után természetesen tisztul

## Indok (mai tanulság — 2026-04-29)

A mai sessionben a `console.log` heartbeat (v2.3.16) → Codex P1 észrevette: az
Electron renderer→main forward filter `level >= 2`-t követel, így a `console.log`
**silently elsüllyedne** production-ban. Ha NEM követjük a mandate-et, a
fagyás-detection elvész a production-ban.

A Sourcery P2 minor szintű feedback-ek is fontosak — pl. `grid-cols-3` mobile-tört,
`href="/shipments"` full-page-reload — ezek UX-bug-ok, csak a felhasználó-tesztelés
során derülne ki.

**Konklúzió:** a code review tooling másodlagos szem-pár, NEM választható.

## Implementáció

- ✅ CLAUDE.md frissítve (kötelező érvényű érintetteknél)
- ✅ `.remember/remember.md` frissítve
- ✅ Vault feedback-jegyzet (ez a fájl)

## Hatálybalépés

**2026-04-29 20:55 CEST** — minden PR-re visszamenőleg, és az új PR-ekre is.
