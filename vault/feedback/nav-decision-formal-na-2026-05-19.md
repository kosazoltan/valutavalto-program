---
title: "NAV Online Számla integráció — formális N/A döntés (P0.2)"
status: active
priority: P0
hatály: 2026-05-19+ (felülbírálható)
forrás: Sprint A P0.2 close-out, Kósa Zoltán hallgatólagos elfogadás
related: docs/LEGACY_PARITY_P1_ACTION_PLAN.md P1-06
---

# NAV Online Számla integráció — formális N/A döntés

## A kérdés

A LEGACY_PARITY_P1_ACTION_PLAN.md P1-06 (és a strategic-development-plan-v2-5-64
P0.2) kérdés: **kötelező-e a NAV Online Számla API integráció** a valutaváltó
ERP-be, vagy formális N/A döntés?

## Üzleti kontextus

Valutaváltó iroda **NEM** ad ki ÁFA-s számlát a tranzakciókról:
- A vétel/eladás a Pmt. (2017. évi LIII. tv) hatálya alá tartozik, NEM az ÁFA tv.
- A jövedelem-bizonylat formátuma a Pmt. szerinti tranzakciós bizonylat
  (`Receipt` entity, ESC/POS print + PDF), NEM számla
- A NAV Online Számla **kötelező** csak az ÁFA-s számlák real-time
  jelentésére (350.000 Ft+ B2B + 2024-től minden B2C)
- A valutaváltás **NEM számla-köteles** a NAV Online Számla felé

## Meglévő NAV-integrációs pontok

A jelenlegi `NavIntegrationService` (`backend/src/main/java/.../service/NavIntegrationService.java`)
**placeholder/mock** — NEM hív valódi NAV API-t. Hatóköre limitált:
1. NAV pénztárgép zárás (NAVZARO legacy, ha lenne POS-szerű készülék) — N/A
2. Adatlap generálás (Pmt. szerinti) — már szerver-oldali, NEM kell külső API
3. ÁNYK XML export (éves jelentés) — `NavClosingService` már létezik, működik

## Döntés

**Formális N/A** — a NAV Online Számla API integráció **NEM kötelező** a valutaváltó
ERP-be a következő okok miatt:

1. **Üzleti**: a valutaváltás NEM számla-köteles tevékenység
2. **Compliance**: a Pmt. 27. § + adatlap-megőrzés (8 év) automatikusan teljesül
   a meglévő DB + audit_log + V234 hash-chain szabályrendszerrel
3. **NAV Online Számla scope**: B2B/B2C **ÁFA-s** számla real-time jelentés — a
   valuta tranzakciókhoz nincs ÁFA, így nincs jelentési kötelezettség

## Mit megőrzünk

- `NavClosingService` továbbra is működik (ÁNYK XML — éves összesítő, manuális
  feltöltés a NAV-portálra, a meglévő szabályozás szerint)
- `NavIntegrationService` placeholder marad — `@Deprecated` jelölés a következő
  takarításban
- Ha üzleti környezet változik (pl. valutaváltó ÁFA-köteles státusz),
  ezt a vault-jegyzetet felülírjuk

## Felülbírálás

Ha Kósa Zoltán bármikor felülbírálja (üzleti kötelezettség változás,
hatósági elvárás), új feedback fájl `nav-online-szamla-required-YYYY-MM-DD.md`
néven kerül a vault-ba, és új sprint indul.

## Hivatkozások

- `docs/LEGACY_PARITY_P1_ACTION_PLAN.md` P1-06
- `vault/references/strategic-development-plan-v2-5-64-2026-05-19.md` P0.2
- `backend/src/main/java/hu/puzzleir/valuta/service/NavClosingService.java` (működő)
- `backend/src/main/java/hu/puzzleir/valuta/service/NavIntegrationService.java` (placeholder, N/A)
- Pmt. (2017. évi LIII. tv.) — pénzmosás megelőzéséről szóló tv.
- ÁFA tv. (2007. évi CXXVII. tv.) — itt NEM hatályos a valutaváltáshoz
