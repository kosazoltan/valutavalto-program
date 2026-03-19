# Architektúra Döntések

**Dátum:** 2024-12-15  
**Projekt:** Valuta Váltó Rendszer - React + Spring Boot

---

## ✅ Kritikus Döntések (Megerősítve)

### 1. Multi-Tenant Architektúra

**Döntés:** MULTI-TENANT (2 cég)

**Cégek:**
1. **Exclusive Best Change Zrt.** (Best Change)
   - Legacy kód: `_kftnev := 'BEST'`
   - Cég név: `_cegnev := 'Exclusive Best Change ZRT.'`
   - Legacy logo: ChangeEmblemaPanel
   - **Színséma:** Piros, fekete, fehér
   - Primary color: #DC2626 (red-600)
   - Secondary color: #000000 (black)
   - Background: #FFFFFF (white)
   
2. **Expressz Ékszerház Kft.**
   - Legacy kód: `_cegnev := 'Expressz Ékszerház'`
   - Legacy logo: ExpEmblemaPanel
   - **Színséma:** Narancs, fekete, fehér
   - Primary color: #EA580C (orange-600)
   - Secondary color: #000000 (black)
   - Background: #FFFFFF (white)

**Implementáció:**
- ✅ Company entity már létezik (Phase 1)
- Minden tábla tartalmaz `company_id` foreign key-t
- Row-Level Security (RLS) PostgreSQL-ben
- Company context minden API híváshoz
- Frontend: Company selector login után

**Adatbázis módosítások:**
```sql
-- Branch tábla már kapcsolódik Company-hoz
ALTER TABLE branch ADD COLUMN IF NOT EXISTS company_id BIGINT REFERENCES company(id);

-- Worker tábla
ALTER TABLE worker ADD COLUMN company_id BIGINT REFERENCES company(id);

-- Minden tranzakciós tábla
ALTER TABLE transaction ADD COLUMN company_id BIGINT REFERENCES company(id);
ALTER TABLE daily_opening ADD COLUMN company_id BIGINT REFERENCES company(id);
ALTER TABLE daily_closing ADD COLUMN company_id BIGINT REFERENCES company(id);
-- stb...
```

**Security:**
- JWT token tartalmazza: `workerId`, `branchId`, `companyId`, `role`
- Repository query-k automatikus szűrése `company_id` alapján
- GlobalExceptionHandler: 403 Forbidden ha rossz company_id

---

### 2. Adatmigráció Scope

**Döntés:** TELJES MIGRÁCIÓ

**Tartalom:**
- Történelmi tranzakciók (BF/BT havi táblák)
- Pénztárosok és munkavállalók
- Árfolyam történet
- Készlet történet
- Bizonylatok (archív)

**Lépések:**
1. **Phase 0: Migráció Script Fejlesztés**
   - InterBase/Firebird → PostgreSQL adapter
   - Tábla-tábla mapping
   - Adattisztítás szabályok
   - Dry-run tesztek

2. **Phase 1: Master Data Migráció**
   - Companies (2 db)
   - Branches (KOZPONT, FOERTEKTAR, ERTEKTAR, PENZTAR hierarchia)
   - Workers (aktív pénztárosok)
   - Currencies (valuta törzsek)

3. **Phase 2: Transactional Data Migráció**
   - Utolsó 12 hónap tranzakciói
   - Aktív készletek
   - Nyitott átadás-átvételek

4. **Phase 3: Historical Data Migráció (Opcionális)**
   - 12 hónapnál régebbi adatok
   - Archív bizonylatok
   - Alacsony prioritás, későbbi batch job

**Becsült idő:** +2-4 hét (migration script + testing)

---

### 3. Western Union Integráció

**Döntés:** API INTEGRÁCIÓ (dokumentáció később)

**Státusz:** 
- ✅ API dokumentáció létezik (user megadja később)
- ⏸️ Phase 9-re ütemezve
- Prioritás: MAGAS (kellwestern flag alapján)

**Legacy referencia:**
- DLL: `wunion.dll`
- Gomb: `F12WUGomb`
- Enable flag: `_kellwestern` (HARDWARE tábla)
- Készlet típusok: WUUSDKESZLET, WUHUFKESZLET

**Implementáció terv:**
- Külön `WesternUnionService` Spring Boot service
- RestTemplate vagy WebClient API hívásokhoz
- Külön endpoint-ok: `/api/v1/western-union/*`
- Készlet integrálás: CashInventory-ba WU USD/HUF típusok

---

### 4. OTP Terminal Integráció

**Döntés:** UTÁNAJÁRÁS SZÜKSÉGES (DE KELL)

**Státusz:**
- ❓ API vagy hardver driver - tisztázandó
- ⏸️ Phase 9-re ütemezve
- Prioritás: KÖZEPES-MAGAS

**Legacy referencia:**
- DLL: `otp.dll`, `otplog.dll`
- Funkció: `PtarosBelepOTPbe` (pénztáros OTP-be léptetés)
- Enable flag: `_otp`, `_otpopen` (HARDWARE tábla)
- Worker kapcsolat: `otp_user_id` mező Worker entity-ben

**Lehetséges implementációk:**
1. **OTP API** (ha létezik)
   - Spring Boot OtpService
   - REST API integráció
   - Token management

2. **COM Port / USB Driver** (ha hardver)
   - Java Serial Communication (jSerialComm library)
   - Native integration (JNI)
   - Separate Windows Service

3. **Hybrid** (API + hardver)
   - API autentikáció
   - Hardver terminal kommunikáció

**Következő lépés:** OTP kapcsolattartó megkeresése, dokumentáció/SDK kérése

---

### 5. Nyomtatás Architektúra

**Döntés:** KLIENS NYOMTATÓ (2 db eszköz)

**Eszközök:**
1. **Kis blokknyomtató** (Term receipt printer)
   - Típus: Thermal printer (valószínűleg)
   - Funkció: Bizonylatok, blokkok
   - Legacy: `bloknyom.dll`
   - Szélesség: 58mm vagy 80mm

2. **A4-es normál nyomtató**
   - Típus: Irodai lézernyomtató
   - Funkció: Címletezés, jelentések, átadólapok
   - Legacy: `cimlnyom.dll`, report DLL-ek
   - Formátum: A4

**Implementáció:**

**Backend:**
```java
// PDF generálás szerver oldalon (iText vagy Apache PDFBox)
@Service
public class ReceiptPrintService {
    public byte[] generateReceiptPdf(Receipt receipt) {
        // Generate 58mm/80mm thermal printer compatible PDF
    }
    
    public byte[] generateA4ReportPdf(Report report) {
        // Generate A4 format PDF
    }
}

// Endpoints
GET /api/v1/receipts/{id}/pdf?format=thermal|a4
GET /api/v1/reports/{id}/pdf
```

**Frontend:**
```typescript
// Browser Print API használata
const printReceipt = async (receiptId: number) => {
    const pdfBlob = await api.getReceiptPdf(receiptId, 'thermal');
    
    // Option 1: iframe print
    const iframe = document.createElement('iframe');
    iframe.src = URL.createObjectURL(pdfBlob);
    iframe.onload = () => {
        iframe.contentWindow.print();
    };
    
    // Option 2: Külső print szolgáltatás (jsPDF, print-js)
    printJS({ printable: pdfUrl, type: 'pdf' });
};
```

**Nyomtató beállítások:**
- Nyomtató kiválasztás böngésző print dialog-ban
- Alapértelmezett nyomtató localStorage-ban mentve
- Nyomtató teszt funkció Settings-ben

**Alternate:** Electron app native printing (későbbi opció)

---

### 6. QR Kód Generálás

**Döntés:** QR KÓD PÉNZTÁRGÉPNEK

**Funkció:** Bizonylat azonosítás, gyors keresés, ellenőrzés

**Legacy referencia:**
- DLL: `qrgener.dll`
- Funkció: `qrdisplayrutin`

**QR Kód tartalma:**
```
Format: JSON vagy egyszerű string
{
  "receiptId": "BF240112-001234",
  "companyId": 1,
  "branchId": 15,
  "date": "2024-01-12",
  "amount": 125000,
  "checksum": "ABC123"
}

Vagy egyszerűbb:
"BF240112-001234|1|15|125000|ABC123"
```

**Backend implementáció:**
```java
// Maven dependency
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>core</artifactId>
    <version>3.5.1</version>
</dependency>
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>javase</artifactId>
    <version>3.5.1</version>
</dependency>

// Service
@Service
public class QRCodeService {
    public byte[] generateQRCode(String data, int width, int height) {
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(data, BarcodeFormat.QR_CODE, width, height);
        
        ByteArrayOutputStream pngOutputStream = new ByteArrayOutputStream();
        MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngOutputStream);
        return pngOutputStream.toByteArray();
    }
    
    public String generateReceiptQRData(Receipt receipt) {
        return String.format("%s|%d|%d|%d|%s",
            receipt.getReceiptNumber(),
            receipt.getCompanyId(),
            receipt.getBranchId(),
            receipt.getTotalHuf(),
            calculateChecksum(receipt)
        );
    }
}

// Controller endpoint
@GetMapping("/receipts/{id}/qr")
public ResponseEntity<byte[]> getReceiptQRCode(@PathVariable Long id) {
    Receipt receipt = receiptService.getReceiptById(id);
    String qrData = qrCodeService.generateReceiptQRData(receipt);
    byte[] qrImage = qrCodeService.generateQRCode(qrData, 200, 200);
    
    return ResponseEntity.ok()
        .contentType(MediaType.IMAGE_PNG)
        .body(qrImage);
}
```

**Frontend QR megjelenítés:**
```typescript
// React komponens
import QRCode from 'react-qr-code';

const ReceiptQRCode = ({ receiptData }: Props) => {
    return (
        <QRCode
            value={receiptData}
            size={200}
            level="H"
        />
    );
};
```

**QR használati esetek:**
1. **Bizonylaton** - Nyomtatott bizonylaton QR kód
2. **Keresés** - QR scan → bizonylat azonosítás
3. **Ellenőrzés** - Bizonylat hitelességének validálása
4. **Sztornó** - Gyors bizonylat kiválasztás QR alapján

---

### 7. Lapscanner Integráció

**Döntés:** ÜGYFÉL ADATOK BEOLVASÁSA

**Funkció:** Személyigazolvány / útlevél / egyéb okmány scanning

**Use case:**
- Ügyfél azonosítás nagyobb tranzakcióknál
- AML (Anti-Money Laundering) compliance
- NAV jelentési kötelezettség
- Terror lista ellenőrzés automatizálás

**Adatpontok beolvasva:**
- Név
- Születési dátum
- Okmány típus (személyi igazolvány, útlevél, jogosítvány)
- Okmány szám
- Érvényesség (lejárat)
- Állampolgárság

**Backend implementáció:**

**Customer Entity:**
```java
@Entity
@Table(name = "customer")
public class Customer extends AuditableEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 100)
    private String fullName;
    
    @Column
    private LocalDate birthDate;
    
    @Column(length = 50)
    private String documentType; // ID_CARD, PASSPORT, DRIVER_LICENSE
    
    @Column(length = 50)
    private String documentNumber;
    
    @Column
    private LocalDate documentExpiryDate;
    
    @Column(length = 50)
    private String nationality;
    
    @Column(length = 200)
    private String address;
    
    @Column(length = 20)
    private String phoneNumber;
    
    @ManyToOne
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;
    
    // Relations
    @OneToMany(mappedBy = "customer")
    private List<Transaction> transactions;
}
```

**Scanner Service:**
```java
@Service
public class DocumentScannerService {
    
    /**
     * Parse OCR text from document scanner
     */
    public CustomerDto parseScannedDocument(String ocrText) {
        // Parse Hungarian ID card format
        // Example OCR output:
        // "SZEMÉLYAZONOSÍTÓ IGAZOLVÁNY
        //  Kovács János
        //  Születési idő: 1985.03.15
        //  Szám: 123456AB"
        
        CustomerDto customer = new CustomerDto();
        
        // Regex parsing based on document type
        // Hungarian ID: Pattern matching
        // Passport: ICAO standard parsing
        
        return customer;
    }
    
    /**
     * Validate against terror list
     */
    public boolean checkTerrorList(CustomerDto customer) {
        // Call external API or check internal database
        // Legacy: terrlist.dll
        return true;
    }
}
```

**Frontend Scanner Integration:**

**Option 1: File Upload (Manual Scan)**
```typescript
const DocumentUpload = () => {
    const handleFileUpload = async (file: File) => {
        const formData = new FormData();
        formData.append('document', file);
        
        const response = await api.post('/api/v1/customers/scan', formData);
        setCustomerData(response.data);
    };
    
    return (
        <input type="file" accept="image/*" onChange={handleFileUpload} />
    );
};
```

**Option 2: Direct Scanner API (Windows only)**
```typescript
// Native scanner integration via Electron vagy COM
const scanDocument = async () => {
    if (window.electron) {
        const scannedData = await window.electron.scan();
        const customer = await api.parseScannedDocument(scannedData);
        return customer;
    }
};
```

**Option 3: Camera OCR (Browser)**
```typescript
// React-Webcam + Tesseract.js
import Webcam from 'react-webcam';
import Tesseract from 'tesseract.js';

const CameraScanner = () => {
    const webcamRef = useRef(null);
    
    const captureAndOCR = async () => {
        const imageSrc = webcamRef.current.captureScreenshot();
        const result = await Tesseract.recognize(imageSrc, 'hun');
        
        // Send OCR text to backend for parsing
        const customer = await api.parseScannedDocument(result.data.text);
        return customer;
    };
};
```

**API Endpoints:**
```
POST /api/v1/customers/scan         - Upload scanned document
POST /api/v1/customers/parse-ocr    - Parse OCR text
POST /api/v1/customers               - Create customer from parsed data
GET  /api/v1/customers/{id}          - Get customer
GET  /api/v1/customers/search        - Search by name/document
POST /api/v1/customers/{id}/verify   - Verify against terror list
```

**Transaction Connection:**
```java
@Entity
public class Transaction {
    // ... other fields
    
    @ManyToOne
    @JoinColumn(name = "customer_id")
    private Customer customer; // NULL for small transactions
    
    @Column
    private Boolean customerRequired = false; // Threshold alapján
}
```

**Compliance Rules:**
- Tranzakció > 5000 EUR → Customer required
- Terror list check minden ügyfélnél
- Penzugyi tranzakciok, bizonylatok es AML-hez kotott azonositas szerveroldali archiv megorzese minimum 8 evig, hard delete nelkul

---

## 📊 Architektúra Hatások

### Multi-Tenant Impact

| Komponens | Változás | Komplexitás |
|-----------|----------|-------------|
| **Entitások** | +1 mező (company_id) minden táblában | +10% |
| **Repository** | Automatikus company_id szűrés | +15% |
| **Service** | Company context validálás | +10% |
| **Security** | JWT company claim | +5% |
| **Frontend** | Company selector | +2 screen |
| **Tesztelés** | Multi-tenant test cases | +20% |

**Becsült extra idő:** +40-60 óra (5-7.5 munkanap)

### Migráció Impact

| Lépés | Idő (óra) | Kockázat |
|-------|-----------|----------|
| Migration script fejlesztés | 40-60 | Közepes |
| Adattisztítás szabályok | 16-24 | Közepes |
| Dry-run tesztek | 16-24 | Alacsony |
| Production migráció | 8-16 | Magas |
| Validálás és ellenőrzés | 16-24 | Magas |
| **TOTAL** | **96-148 óra** | - |

**12-18.5 munkanap** (1.5-2.3 hét)

### QR + Scanner Impact

| Funkció | Idő (óra) | Komplexitás |
|---------|-----------|-------------|
| QR generálás (backend) | 4-6 | ⭐⭐ |
| QR megjelenítés (frontend) | 2-4 | ⭐ |
| Customer entity + CRUD | 8-12 | ⭐⭐⭐ |
| OCR parsing service | 12-16 | ⭐⭐⭐⭐ |
| Scanner integráció (frontend) | 8-12 | ⭐⭐⭐ |
| Terror list check | 4-6 | ⭐⭐ |
| **TOTAL** | **38-56 óra** | - |

**4.75-7 munkanap**

---

## 🎯 Frissített MVP Scope

**MVP (Minimum Viable Product):**
- ✅ Phase 1: Branch CRUD
- Phase 2: Worker + Auth + **Multi-tenant**
- Phase 3: Napi műveletek
- Phase 4: Készlet (with WU USD/HUF types)
- Phase 5: Tranzakciók + **Customer entity** + **QR generálás**
- Phase 6: Árfolyam
- **Phase 7: Bizonylat nyomtatás (2 nyomtató)**
- Phase 8: Basic riportok

**MVP Backend:** 26-32 munkanap  
**MVP Frontend:** 22-28 munkanap  
**MVP Tesztelés:** 12-18 munkanap

**MVP TOTAL:** **60-78 munkanap = 3-3.9 hónap (1 dev)**

---

## 📋 Technológiai Stack Kiegészítések

### Backend Dependencies

```xml
<!-- QR Code -->
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>core</artifactId>
    <version>3.5.1</version>
</dependency>
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>javase</artifactId>
    <version>3.5.1</version>
</dependency>

<!-- PDF Generation -->
<dependency>
    <groupId>com.itextpdf</groupId>
    <artifactId>itext7-core</artifactId>
    <version>7.2.5</version>
</dependency>

<!-- OCR Processing (Optional - ha szerver oldali OCR) -->
<dependency>
    <groupId>net.sourceforge.tess4j</groupId>
    <artifactId>tess4j</artifactId>
    <version>5.7.0</version>
</dependency>
```

### Frontend Dependencies

```json
{
  "dependencies": {
    "react-qr-code": "^2.0.12",
    "react-webcam": "^7.1.1",
    "tesseract.js": "^5.0.0",
    "print-js": "^1.6.0",
    "file-saver": "^2.0.5"
  }
}
```

---

### 8. Multi-Tenant UI/UX - Céges Branding

**Döntés:** DINAMIKUS SZÍNSÉMA company_id ALAPJÁN

**Implementáció:**

**1. Exclusive Best Change Zrt. (company_id = 1)**
- **Primary color:** #DC2626 (Tailwind red-600)
- **Secondary color:** #000000 (black)
- **Background:** #FFFFFF (white)
- **Akcent:** #EF4444 (red-500 hover)

**2. Expressz Ékszerház Kft. (company_id = 2)**
- **Primary color:** #EA580C (Tailwind orange-600)
- **Secondary color:** #000000 (black)
- **Background:** #FFFFFF (white)
- **Akcent:** #F97316 (orange-500 hover)

**Frontend implementáció:**

```typescript
// src/theme/companyThemes.ts
export const companyThemes = {
  1: { // Exclusive Best Change
    primary: 'bg-red-600 text-white hover:bg-red-700',
    secondary: 'bg-black text-white hover:bg-gray-800',
    border: 'border-red-600',
    text: 'text-red-600',
    logo: '/assets/logos/best-change-logo.png'
  },
  2: { // Expressz Ékszerház
    primary: 'bg-orange-600 text-white hover:bg-orange-700',
    secondary: 'bg-black text-white hover:bg-gray-800',
    border: 'border-orange-600',
    text: 'text-orange-600',
    logo: '/assets/logos/expressz-logo.png'
  }
};

// Context használat
const { companyId } = useAuth();
const theme = companyThemes[companyId];

// JSX
<button className={theme.primary}>Mentés</button>
<div className={theme.border}>...</div>
```

**CSS Custom Properties (alternatív):**

```css
:root[data-company="1"] {
  --color-primary: #DC2626;
  --color-secondary: #000000;
  --color-accent: #EF4444;
}

:root[data-company="2"] {
  --color-primary: #EA580C;
  --color-secondary: #000000;
  --color-accent: #F97316;
}
```

**Logo megjelenítés:**
- Header-ben dinamikus logo
- Login képernyőn cég választó (2 opció nagy logo-val)
- Nyomtatott bizonylatokon cég specifikus fejléc

---

## ✅ Következő Lépések Prioritás Szerint

1. **MOST:** Phase 2 - Worker + JWT + Multi-tenant (3-4 nap)
2. **NEXT:** Customer entity + Scanner alapok (2-3 nap)
3. **THEN:** Migration script v1.0 (5-7 nap)
4. **AFTER:** Phase 3-5 implementálás
5. **PARALLEL:** Western Union API dokumentáció áttekintés
6. **PARALLEL:** OTP Terminal technikai tisztázás

---

**Dokumentum utoljára frissítve:** 2024-12-15  
**Következő felülvizsgálat:** Phase 2 befejezése után
