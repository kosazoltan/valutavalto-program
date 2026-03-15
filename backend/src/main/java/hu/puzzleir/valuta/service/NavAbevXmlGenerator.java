package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * NAV ABEV/PTGSZLAH XML generátor.
 *
 * Legacy: excold-exclusive-nav-data-provider-server / CompanyXMLGenerator.java
 *
 * A magyar adóhatóság (NAV) felé kötelező havi adatszolgáltatás generálása
 * ABEV formátumú XML-ben. A pénztárgépes számlák havi jelentése (PTGSZLAH)
 * tartalmazza az összes tranzakciót pénztáranként, naponként bontva.
 *
 * XML struktúra:
 * {@code
 * <nyomtatvanyok xmlns="http://www.apeh.hu/abev/nyomtatvanyok/2005/01">
 *   <abev>
 *     <hibakszama>-1</hibakszama>
 *     <hash>...</hash>
 *     <programverzio>v.3.0.0</programverzio>
 *   </abev>
 *   <nyomtatvany>
 *     <nyomtatvanyinformacio>
 *       <nyomtatvanyazonosito>PTGSZLAH</nyomtatvanyazonosito>
 *       <nyomtatvanyverzio>5.0</nyomtatvanyverzio>
 *       <adozo>...</adozo>
 *       <idoszak>...</idoszak>
 *     </nyomtatvanyinformacio>
 *     <mezok>
 *       <mezo eazon="...">érték</mezo>
 *       ...
 *     </mezok>
 *   </nyomtatvany>
 * </nyomtatvanyok>
 * }
 *
 * Mező azonosítók (eazon):
 *   27751          — adószám (rövid, 8 jegy)
 *   0A0001C001A    — teljes adószám (11 jegy)
 *   0A0001C004A    — cégnév
 *   0A0001C027A    — ügyvivő név
 *   0A0001C028A    — ügyvivő telefonszám
 *   0A0001D001A    — időszak tól
 *   0A0001D002A    — időszak ig
 *   0A0001C007A-C011A — székhely cím mezők
 *   0A0001C018A-C022A — levelezési cím mezők
 *   0B{page}B{attr}A  — pénztár fejléc mezők
 *   0B{page}C{trx}{field}A — tranzakció mezők:
 *     AA = bizonylat sorszám
 *     BA = bizonylat típus (mindig "NOR")
 *     DA = ügyfélnév
 *     EA = ügyfél cím
 *     FA = valutanem (mindig "HUF" — a forint oldal)
 *     GA = összeg (forintban, negatív = vétel)
 *
 * Szabályok:
 *   - Max 30 tranzakció/oldal, utána új oldal (page++)
 *   - Ha page >= 9999, új fájl keletkezik
 *   - A valutanem mindig "HUF" (a forint oldali értéket közöljük)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class NavAbevXmlGenerator {

    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;

    private static final int MAX_TRANSACTIONS_PER_PAGE = 30;
    private static final String PTGSZLAH_ID = "PTGSZLAH";
    private static final String PTGSZLAH_VERSION = "5.0";
    private static final String PROGRAM_VERSION = "v.3.0.0";
    private static final String NAMESPACE = "http://www.apeh.hu/abev/nyomtatvanyok/2005/01";
    private static final DateTimeFormatter ABEV_DATE_FMT = DateTimeFormatter.ofPattern("yyyyMMdd");

    /**
     * Havi PTGSZLAH XML generálása az aktuális céghez.
     *
     * @param year  év (pl. 2026)
     * @param month hónap (1-12)
     * @return ABEV XML string
     */
    public String generateMonthlyPtgszlah(int year, int month) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new IllegalStateException("Cég nem található: " + companyId));

        LocalDate dateFrom = LocalDate.of(year, month, 1);
        LocalDate dateTo = dateFrom.withDayOfMonth(dateFrom.lengthOfMonth());

        List<Branch> branches = branchRepository.findByCompanyId(companyId);

        log.info("NAV PTGSZLAH generálás: company={}, period={}-{}, branches={}",
                company.getName(), dateFrom, dateTo, branches.size());

        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        xml.append("<nyomtatvanyok xmlns=\"").append(NAMESPACE).append("\">\n");

        // ABEV fejléc
        appendAbevHeader(xml);

        // Nyomtatvány blokk
        xml.append("    <nyomtatvany>\n");
        appendFormInformation(xml, company, dateFrom, dateTo);

        xml.append("        <mezok>\n");

        // Cég adatok
        String taxNumber = cleanTaxNumber(company.getTaxNumber());
        appendField(xml, "27751", taxNumber.length() > 8 ? taxNumber.substring(0, 8) : taxNumber);
        appendField(xml, "0A0001C001A", taxNumber);
        appendField(xml, "0A0001C004A", company.getName());
        // Ügyvivő — a Company-ból vagy config-ból
        appendField(xml, "0A0001C027A", ""); // TODO: ügyvivő név a cég konfigból
        appendField(xml, "0A0001C028A", ""); // TODO: ügyvivő telefon a cég konfigból

        // Időszak
        appendField(xml, "0A0001D001A", dateFrom.format(ABEV_DATE_FMT));
        appendField(xml, "0A0001D002A", dateTo.format(ABEV_DATE_FMT));

        // Székhely cím — parse from company.address
        appendCompanyAddress(xml, company);

        // Pénztáranként, naponként bontva
        int page = 0;
        for (Branch branch : branches) {
            // Adott hónap aktív tranzakciói az irodához
            List<Transaction> branchTransactions = transactionRepository
                    .findActiveByBranchAndDateRange(branch.getId(), dateFrom, dateTo);

            if (branchTransactions.isEmpty()) continue;

            // Napok csoportosítása
            Map<LocalDate, List<Transaction>> byDate = new TreeMap<>();
            for (Transaction tx : branchTransactions) {
                byDate.computeIfAbsent(tx.getTransactionDate(), k -> new ArrayList<>()).add(tx);
            }

            for (Map.Entry<LocalDate, List<Transaction>> dayEntry : byDate.entrySet()) {
                LocalDate txDate = dayEntry.getKey();
                List<Transaction> dayTx = dayEntry.getValue();

                page++;
                appendCashDeskHeader(xml, page, txDate, taxNumber, branch);

                int txNumber = 1;
                for (Transaction tx : dayTx) {
                    if (txNumber > MAX_TRANSACTIONS_PER_PAGE) {
                        page++;
                        appendCashDeskHeader(xml, page, txDate, taxNumber, branch);
                        txNumber = 1;
                    }

                    appendTransactionFields(xml, page, txNumber, tx);
                    txNumber++;
                }
            }
        }

        xml.append("        </mezok>\n");
        xml.append("    </nyomtatvany>\n");
        xml.append("</nyomtatvanyok>\n");

        String result = xml.toString();
        log.info("NAV PTGSZLAH generálás kész: {} oldal, {} byte", page, result.length());
        return result;
    }

    /**
     * Egyedi időszakra szóló PTGSZLAH generálás.
     */
    public String generateCustomPtgszlah(LocalDate dateFrom, LocalDate dateTo) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new IllegalStateException("Cég nem található: " + companyId));

        List<Branch> branches = branchRepository.findByCompanyId(companyId);

        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        xml.append("<nyomtatvanyok xmlns=\"").append(NAMESPACE).append("\">\n");
        appendAbevHeader(xml);
        xml.append("    <nyomtatvany>\n");
        appendFormInformation(xml, company, dateFrom, dateTo);
        xml.append("        <mezok>\n");

        String taxNumber = cleanTaxNumber(company.getTaxNumber());
        appendField(xml, "27751", taxNumber.length() > 8 ? taxNumber.substring(0, 8) : taxNumber);
        appendField(xml, "0A0001C001A", taxNumber);
        appendField(xml, "0A0001C004A", company.getName());
        appendField(xml, "0A0001D001A", dateFrom.format(ABEV_DATE_FMT));
        appendField(xml, "0A0001D002A", dateTo.format(ABEV_DATE_FMT));
        appendCompanyAddress(xml, company);

        int page = 0;
        for (Branch branch : branches) {
            List<Transaction> branchTx = transactionRepository
                    .findActiveByBranchAndDateRange(branch.getId(), dateFrom, dateTo);

            if (branchTx.isEmpty()) continue;

            Map<LocalDate, List<Transaction>> byDate = new TreeMap<>();
            for (Transaction tx : branchTx) {
                byDate.computeIfAbsent(tx.getTransactionDate(), k -> new ArrayList<>()).add(tx);
            }

            for (Map.Entry<LocalDate, List<Transaction>> dayEntry : byDate.entrySet()) {
                page++;
                appendCashDeskHeader(xml, page, dayEntry.getKey(), taxNumber, branch);

                int txNumber = 1;
                for (Transaction tx : dayEntry.getValue()) {
                    if (txNumber > MAX_TRANSACTIONS_PER_PAGE) {
                        page++;
                        appendCashDeskHeader(xml, page, dayEntry.getKey(), taxNumber, branch);
                        txNumber = 1;
                    }
                    appendTransactionFields(xml, page, txNumber, tx);
                    txNumber++;
                }
            }
        }

        xml.append("        </mezok>\n");
        xml.append("    </nyomtatvany>\n");
        xml.append("</nyomtatvanyok>\n");

        return xml.toString();
    }

    // ========== PRIVATE XML BUILDER METHODS ==========

    private void appendAbevHeader(StringBuilder xml) {
        xml.append("    <abev>\n");
        xml.append("        <hibakszama>-1</hibakszama>\n");
        xml.append("        <hash></hash>\n");
        xml.append("        <programverzio>").append(PROGRAM_VERSION).append("</programverzio>\n");
        xml.append("    </abev>\n");
    }

    private void appendFormInformation(StringBuilder xml, Company company, LocalDate from, LocalDate to) {
        String taxNumber = cleanTaxNumber(company.getTaxNumber());
        xml.append("        <nyomtatvanyinformacio>\n");
        xml.append("            <nyomtatvanyazonosito>").append(PTGSZLAH_ID).append("</nyomtatvanyazonosito>\n");
        xml.append("            <nyomtatvanyverzio>").append(PTGSZLAH_VERSION).append("</nyomtatvanyverzio>\n");
        xml.append("            <adozo>\n");
        xml.append("                <nev>").append(escXml(company.getName())).append("</nev>\n");
        xml.append("                <adoszam>").append(taxNumber).append("</adoszam>\n");
        xml.append("            </adozo>\n");
        xml.append("            <idoszak>\n");
        xml.append("                <tol>").append(from.format(ABEV_DATE_FMT)).append("</tol>\n");
        xml.append("                <ig>").append(to.format(ABEV_DATE_FMT)).append("</ig>\n");
        xml.append("            </idoszak>\n");
        xml.append("            <megjegyzes></megjegyzes>\n");
        xml.append("        </nyomtatvanyinformacio>\n");
    }

    private void appendCashDeskHeader(StringBuilder xml, int page, LocalDate date,
                                       String taxNumber, Branch branch) {
        String pageStr = String.format("%04d", page);
        int attrId = 1;

        // Dátum
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", attrId) + "A",
                date.format(ABEV_DATE_FMT));
        // Oldalszám
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                String.valueOf(page));
        // Adószám
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                taxNumber);
        // Pénztár neve (attrId+2 = 5, a legacy-ben 4-et kihagyja)
        attrId += 2;
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", attrId) + "A",
                branch.getName());
        // Cégnév
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                branch.getCompany() != null ? branch.getCompany().getName() : "");
        // Cím — irányítószám, város, utca, jelleg, házszám
        String[] addressParts = parseAddress(branch.getAddress());
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                addressParts[0]); // irányítószám
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                addressParts[1]); // település
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                addressParts[2]); // közterület neve
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                addressParts[3]); // közterület jellege
        appendField(xml, "0B" + pageStr + "B" + String.format("%03d", ++attrId) + "A",
                addressParts[4]); // házszám
    }

    private void appendTransactionFields(StringBuilder xml, int page, int txNumber, Transaction tx) {
        String pageStr = String.format("%04d", page);
        String txStr = String.format("%04d", txNumber);
        String prefix = "0B" + pageStr + "C" + txStr;

        // AA = bizonylat sorszám
        appendField(xml, prefix + "AA", safe(tx.getReceiptNumber()));
        // BA = bizonylat típus (mindig "NOR")
        appendField(xml, prefix + "BA", "NOR");
        // DA = ügyfélnév
        appendField(xml, prefix + "DA", safe(tx.getCustomerName()));
        // EA = ügyfél cím
        appendField(xml, prefix + "EA", safe(tx.getCustomerAddress()));
        // FA = valutanem (mindig "HUF" — a forint oldali értéket jelezzük)
        appendField(xml, prefix + "FA", "HUF");
        // GA = összeg (forintban, negatív ha vétel/kiadás)
        long hufAmount = tx.getHufAmount() != null ? tx.getHufAmount().longValue() : 0;
        if (tx.getTransactionType() == TransactionType.BUY) {
            hufAmount = -Math.abs(hufAmount); // vétel = negatív (cég fizet)
        }
        appendField(xml, prefix + "GA", String.valueOf(hufAmount));
    }

    private void appendField(StringBuilder xml, String eazon, String value) {
        xml.append("            <mezo eazon=\"").append(eazon).append("\">")
           .append(escXml(value != null ? value : ""))
           .append("</mezo>\n");
    }

    private void appendCompanyAddress(StringBuilder xml, Company company) {
        String[] parts = parseAddress(company.getAddress());
        appendField(xml, "0A0001C007A", parts[0]); // irányítószám
        appendField(xml, "0A0001C008A", parts[1]); // település
        appendField(xml, "0A0001C009A", parts[2]); // közterület neve
        appendField(xml, "0A0001C010A", parts[3]); // közterület jellege
        appendField(xml, "0A0001C011A", parts[4]); // házszám
        // Teljes cím (28736 mező a legacy-ben)
        appendField(xml, "28736", company.getAddress() != null ? company.getAddress() : "");
    }

    // ========== UTILITY METHODS ==========

    private String cleanTaxNumber(String taxNumber) {
        if (taxNumber == null) return "";
        return taxNumber.replace("-", "").replace(" ", "");
    }

    /**
     * Cím parse: "6720 Szeged, Kárász u. 5" →
     * ["6720", "Szeged", "Kárász", "u.", "5"]
     */
    private String[] parseAddress(String address) {
        String[] result = {"", "", "", "", ""};
        if (address == null || address.isBlank()) return result;

        String cleaned = address.trim();

        // Irányítószám: első 4 számjegy
        if (cleaned.length() >= 4 && cleaned.substring(0, 4).matches("\\d{4}")) {
            result[0] = cleaned.substring(0, 4);
            cleaned = cleaned.substring(4).trim();
        }

        // Település: vesszőig
        int commaIdx = cleaned.indexOf(',');
        if (commaIdx > 0) {
            result[1] = cleaned.substring(0, commaIdx).trim();
            cleaned = cleaned.substring(commaIdx + 1).trim();
        }

        // Közterület név + jelleg + házszám
        String[] streetParts = cleaned.split("\\s+");
        if (streetParts.length >= 3) {
            result[2] = streetParts[0]; // közterület név
            result[3] = streetParts[1]; // jelleg (u., tér, krt.)
            result[4] = streetParts[streetParts.length - 1]; // házszám (utolsó)
        } else if (streetParts.length == 2) {
            result[2] = streetParts[0];
            result[4] = streetParts[1];
        } else if (streetParts.length == 1) {
            result[2] = streetParts[0];
        }

        return result;
    }

    private String escXml(String value) {
        if (value == null) return "";
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }

    private String safe(String value) {
        return value != null ? value : "Ismeretlen";
    }
}
