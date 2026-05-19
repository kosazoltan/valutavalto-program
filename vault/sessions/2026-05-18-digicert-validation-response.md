# DigiCert Validation Response — 2026-05-18

> **Cél:** Másold be a teljes alábbi szöveget (a `---` jelek közötti részt) a céges Gmail / Outlook fiókodba (`kosa@bestchange.hu`), és küldd el a megadott címekre. A 5 fotót külön csatold (lásd a végén).

---

**To:** validation@digicert.com
**Cc:** support@signmycode.com
**Subject:** Re: Update on your order #CS-BNYK (Vendor Order ID: 1524362467) — Corporate email + ID + questionnaire — [Case Number: 04950233] [Org ID 2206189]

Dear Mandy, dear DigiCert Validation Team,

Thank you for your patience and for the follow-up email regarding the validation of **EXCLUSIVE BEST Change Zrt.** (Organization ID **2206189**, Order **CS-BNYK** / Vendor **1524362467**).

My sincere apologies for the missed authenticity call on Monday 2026-05-18 between 16:30 and 17:00 CEST (Booking ID 505190). I am addressing all three validation requirements below in a single reply.

---

## 1. Updated corporate email address (CA/B Forum compliance)

As required by the CA/Browser Forum rules for EV Code Signing approvers, please update my DigiCert and CertCentral account profiles with the following corporate email:

> **New approver email: `kosa@bestchange.hu`**

This address is hosted on our company domain `bestchange.hu` and **replaces** the previous personal Gmail address. I am sending this email from that corporate inbox so you can confirm authority.

Please retire the previous Gmail address (`kosa.zoltan.ebc@gmail.com`) from the certificate-approver role on this order. I still own that inbox for legacy correspondence, but it should no longer be the contact-of-record for the EV CS certificate.

---

## 2. Identity verification documents

Attached to this email you will find:

1. **Government-issued ID (front side)** — clear, full-frame photograph of my Hungarian National Identity Card (Magyarország / Hungary Identity Card, issued by the Belügyminisztérium / Ministry of the Interior). Shows photograph, name, date of birth, nationality, document number, CAN, expiry date, and signature.
2. **Government-issued ID (back side)** — clear, full-frame photograph showing place of birth, mother's maiden name, issuing authority, issue date, and the MRZ (machine-readable zone, ICAO 9303 compliant).
3. **Selfie with ID — front side visible** — photograph of me holding the same identity card next to my face. Both my face and the front side of the ID are clearly visible and unobstructed.
4. **Selfie with ID — back side visible** — photograph of me holding the back side of the same identity card next to my face. Both my face and the back side of the ID are clearly visible.
5. **Clean selfie (face only)** — additional reference photograph for biometric matching.

All five photographs are taken on neutral background with daylight; the ID details are sharp and the MRZ is fully readable. If you require higher-resolution versions or a notarized scan, please let me know.

---

## 3. Authenticity call — rescheduling

I sincerely apologize that the previous booking (Booking ID 505190, scheduled 2026-05-18 16:30-17:00 CEST) did not connect. I will rebook the authenticity call via the DigiCert call scheduler (https://callscheduler.digicert.com/v2/#book) for an earlier-morning Hungarian time slot, ideally **Tuesday 2026-05-19 09:00-10:00 CEST** (which is 01:00-02:00 MDT — please confirm that this slot is available for your team).

### Phone numbers (both verified, third-party-listed)

| Channel | Number | Source of verification |
|---|---|---|
| **Office (primary)** | **+36 72 515 625** | Hungarian Company Registry (Cégjegyzék) — search "EXCLUSIVE BEST Change Zrt." at https://www.e-cegjegyzek.hu |
| **Mobile (backup)** | +36 70 380 0202 | Same Cégjegyzék listing (authorized representative contact) |

### Booking parameters (for the scheduler form)

- **"Order or Validation Number"** field: `EXCLUSIVE BEST Change Zrt. - 2206189`
- **"Special Instructions"**: "Please call the **office line +36 72 515 625** as primary. Ring at least 5 times; if no answer, try the mobile backup +36 70 380 0202. Reception is briefed and expects the DigiCert call. Time zone: Europe/Budapest (CEST, UTC+2)."

### Why previous calls did not connect

I have asked our office to confirm that no spam-filter or international-call block is active on the office line. The mobile carrier has also been asked to whitelist US-originating calls (+1-801 / +1-866 prefixes). If you have a specific caller-ID you intend to use, please share it so we can pre-whitelist it.

---

## 4. Questionnaire answers (9 items)

**1. Link to the website where your software will be hosted**
https://excvaluta.com — production hostname for the Valutaváltó ERP. Serves the admin web portal and the authorized installer-download distribution page.

**2. Description of what your organization does**
EXCLUSIVE BEST Change Zrt. is a regulated Hungarian financial-services company. We operate licensed currency-exchange offices (valutaváltó) and develop in-house the **Valutaváltó ERP** — a multi-tenant, multi-branch enterprise resource planning system for currency-exchange businesses. The system has offline-capable Windows desktop clients (Electron-based) for cashier (penztár), value vault (értéktár), value transport (értékszállító), central control workstation (központi irányítóközpont), and rate-maker (árfolyam-készítő) workflows. The platform handles cash transactions, exchange-rate management, anti-money-laundering (AML / Pmt. compliance), NAV (Hungarian Tax Authority) reporting, and MNB (Hungarian National Bank) statistical reports.

**3. Description of the files that will be signed**
Windows Electron-based desktop application installers (NSIS-built `.exe` files) and the binaries they install (Electron main process, native Node.js modules, optional Java JAR backend). These are our own internally developed applications, distributed to authorized branch offices of EXCLUSIVE BEST Change Zrt. and licensed partner branches.

**4. Why do you need a code signing certificate?**
The applications are deployed to non-technical end-users (cashiers, vault attendants, central controllers) at currency-exchange branches. Windows SmartScreen blocks unsigned `.exe` installers by default with a "Windows protected your PC" prompt, which non-technical staff cannot bypass. EV Code Signing **eliminates this prompt at first install** and provides immediate publisher reputation — this is mandatory under our internal deployment standards for regulated financial software, and is a Hungarian banking-sector norm for signed deployed binaries.

**5. What will you be using the certificate to sign?**
The following Windows installers and the binaries packaged inside them (current release **v2.5.57**, future releases v2.5.58+):

- `Penztar-Setup-2.5.x.exe` — cashier client installer (~280 MB)
- `Kozponti-Iranyitokozpont-Setup-2.5.x.exe` — central control workstation installer (~101 MB)
- `Arfolyamkeszito-Setup-2.5.x.exe` — rate-maker client installer (~101 MB)
- `Penztar-Eltavolito-2.5.x.exe` — uninstaller (~60 KB)

Plus any auxiliary Windows binaries bundled inside (Electron native modules, JAR backend when shipped with the installer payload).

**6. What kind of files will you be signing? Please provide file extensions.**
- `.exe` — NSIS installer and uninstaller binaries (primary signing target)
- `.dll` — Electron native modules
- `.node` — Node.js native addons used by Electron
- `.jar` — Java backend binaries (Spring Boot 4 + Tomcat 11.0.21) when bundled with the installer

**7. Do you have an example code or file you need to sign?**
Yes — the most recent unsigned build is **v2.5.57** (built 2026-05-18):

- File: `Penztar-Setup-2.5.57-20260518.exe`
- Size: 280.94 MB (294,583,435 bytes)
- SHA-256: `E55E2D390688FE2B1F3CB947253D89B7D59203E63B3E7E72F24EA93198F13600`

A copy can be delivered via secure transfer (e.g. WeTransfer or SFTP) on request. This file is the cashier-client Windows installer that will be the first artifact signed by the EV Code Signing certificate once issued.

**8. Do you have a website for your software or product?**
Yes — https://excvaluta.com (production admin portal; also serves as the authorized installer-download distribution page for branch IT staff and licensed partners).

**9. Does your organization offer residential proxy services or SOCKS4/5 proxy connections as part of your product or service offerings?**
**No.** EXCLUSIVE BEST Change Zrt. is a regulated currency-exchange business; we do not operate or distribute residential proxy services, SOCKS4/5 proxies, or any kind of network-proxy product. The EV Code Signing certificate will be used exclusively to sign our own line-of-business currency-exchange ERP binaries (Windows installers and the binaries they install).

---

## 5. Azure Key Vault delivery mode (reminder)

Once validation is complete, please issue the EV Code Signing certificate via the **Azure Key Vault delivery mode**. The HSM Approval form was submitted on 2026-05-15 09:55 CEST and acknowledged by your team.

Our Azure Key Vault parameters:

- **Vault name:** `kv-valuta-codesign`
- **Certificate name:** `valuta-codesign-cert`
- **Tier:** Azure Key Vault **Premium** (HSM-backed, FIPS 140-2 Level 3 compliant, hosted in Azure North Europe region)

The CSR will be generated inside the Azure Key Vault HSM and merged into the issued certificate via `az keyvault certificate pending merge` on our side. We do not require physical token shipment.

---

If any further information is needed, please respond to this corporate email address (`kosa@bestchange.hu`). I am also reachable by phone at the numbers listed in section 3.

Thank you for your continued support in completing this validation. I look forward to a successful authenticity call and certificate issuance.

Best regards,

**Zoltán Kósa**
CEO (vezérigazgató)
EXCLUSIVE BEST Change Zrt.
Email: kosa@bestchange.hu
Office: +36 72 515 625
Mobile: +36 70 380 0202

---

**Attachments (5 files):**

1. `01_ID_front.jpg` — Hungarian National ID card front side (photograph + name + birth date + document number)
2. `02_ID_back.jpg` — Hungarian National ID card back side (place of birth + mother's name + MRZ + issuing authority)
3. `03_selfie_with_ID_front.jpg` — selfie holding the ID card, front side visible next to face
4. `04_selfie_with_ID_back.jpg` — selfie holding the ID card, back side visible next to face
5. `05_selfie_face_only.jpg` — clean reference selfie (face only, no ID)

---

# Mit kell csinálnod (gyakorlati lépések)

## 1. Mentsd el a 3 fotót külön néven

A beszélgetésben **3 fotó** van. Mentsd el őket az alábbi nevekkel (Mentés másként):

| Eredeti pozíció | Új fájlnév |
|---|---|
| 1. fotó — tiszta selfie | `05_selfie_face_only.jpg` |
| 2. fotó — selfie ID elejével | `03_selfie_with_ID_front.jpg` |
| 3. fotó — selfie ID hátoldalával | `04_selfie_with_ID_back.jpg` |

**Hiányzik még 2 fotó** — kell még külön:
- `01_ID_front.jpg` — csak az ID **elejének** zoom-olt fotója (a 3. fotódról kivágott rész, vagy egy újat csinálni, csak az ID látszik, kéz nélkül)
- `02_ID_back.jpg` — csak az ID **hátoldalának** zoom-olt fotója

A DigiCert mind a 4 ID-fotót szereti látni: 2 sima ID (front+back) + 2 selfie-ID-vel. Az 5. (tiszta selfie) bónusz.

## 2. Lépj be a `kosa@bestchange.hu` céges Gmail / Outlook fiókba

A céges e-mail fiókba, NEM a régi `kosa.zoltan.ebc@gmail.com`-ba!

## 3. Új levél írása

- **Címzett:** `validation@digicert.com`
- **Másolat (Cc):** `support@signmycode.com`
- **Tárgy:** lásd a `Subject:` sort fent
- **Tartalom:** Másold be a `Dear Mandy, dear DigiCert Validation Team,` sortól a `+36 70 380 0202` aláírásig terjedő teljes szöveget. (Az e-mail aláírás alatti "Attachments" rész **csak nektek info** — a fájlokat tényleges fájl-csatolásként kell mellékelni, nem szövegben.)

## 4. Csatold az 5 fájlt

A levél előnézetében ellenőrizd, hogy mindegyik fájl ott van-e (összesen ~5-10 MB).

## 5. Küldés előtt 1 utolsó check

- ✅ Tárgy tartalmazza: "Org ID 2206189" + "Case Number 04950233"
- ✅ Feladó cím: `kosa@bestchange.hu` (NEM Gmail!)
- ✅ Cc: signmycode.com is rajta
- ✅ Mind az 5 fotó csatolva
- ✅ Az e-mail testében ott van mind a 9 kérdés válasza

## 6. Új hívás foglalása (P0)

Küldés UTÁN azonnal:
1. Nyisd meg: https://callscheduler.digicert.com/v2/#book
2. "Order or Validation Number": `EXCLUSIVE BEST Change Zrt. - 2206189`
3. "Special Instructions": másold be a fenti **"Special Instructions"** mezőt (5 sor)
4. Időpont: **kedd 2026-05-19 09:00 CEST** (vagy a legkorábbi szabad reggeli szlot)

## 7. Kedd reggel 08:55-től

- Légy az irodában a +36 72 515 625-höz
- Whitelistezd a +1-801-* USA prefixet a mobilon (Beállítások → Hívásblokkolás)
- Tartsd kéznél a mobilt is (+36 70 380 0202)
- Ha 09:30-ig nem hív senki: küldj egy follow-up e-mailt Mandy-nak

---

# Kapcsolódó vault-jegyzetek

- `vault/sessions/2026-05-15-digicert-hsm-approval.md` — HSM Approval form submitted (2026-05-15)
- `vault/feedback/_active_mandates.md` B.7 — Code-signing függő release mandate (2026-05-21-ig P0)
- `CLAUDE.md` "Nyitott következő feladatok" P1.3 + P1.4 — DigiCert validation + signed v2.5.58 release
