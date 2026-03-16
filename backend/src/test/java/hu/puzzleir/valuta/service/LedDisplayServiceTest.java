package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.led.LedDisplayConfigDto;
import hu.puzzleir.valuta.dto.led.LedDisplayStatusDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.led.LedProtocolEncoder;
import hu.puzzleir.valuta.service.led.LedSerialPortDriver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * LedDisplayService egysgtesztek  mockolt fggsgekkel.
 */
@ExtendWith(MockitoExtension.class)
class LedDisplayServiceTest {

    @Mock LedDisplayRepository ledDisplayRepository;
    @Mock LedDisplayConfigRepository ledDisplayConfigRepository;
    @Mock BranchRepository branchRepository;
    @Mock ExchangeRateRepository exchangeRateRepository;
    @Mock LedProtocolEncoder encoder;
    @Mock LedSerialPortDriver serialDriver;

    @InjectMocks LedDisplayService service;

    private UUID branchId;
    private UUID companyId;
    private Branch branch;
    private Company company;
    private LedDisplayConfig config;
    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        branchId  = UUID.randomUUID();
        companyId = UUID.randomUUID();

        company = new Company();
        company.setId(companyId);

        branch = new Branch();
        branch.setId(branchId);
        branch.setName("Teszt Iroda");
        branch.setCode("TEST");
        branch.setCompany(company);

        config = new LedDisplayConfig();
        config.setId(UUID.randomUUID());
        config.setBranch(branch);
        config.setIsActive(true);
        config.setSerialDisplayType(LedSerialDisplayType.STANDARD);
        config.setComPorts("COM1");
        config.setCurrencies("EUR,USD");
        config.setSpeedCommand(true);
        config.setSpeed(5);
        config.setEndMarkers("254");
        config.setDecimalSeparator(',');
        config.setShowBankCard(false);
        config.setDisplayType(LedDisplayConnectionType.SERIAL);

        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
    }

    @AfterEach
    void tearDown() {
        securityUtilsMock.close();
    }

    // ---------- refreshDisplay ----------

    @Test
    @DisplayName("1. refreshDisplay: kodolt adatot kuld COM portra")
    void refreshDisplaySendsEncodedData() {
        byte[] packet = new byte[]{21, 18, 5, (byte) 254};
        byte[][] packets = new byte[][]{packet};

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(ledDisplayConfigRepository.findByBranchId(branchId)).thenReturn(Optional.of(config));
        when(exchangeRateRepository.findAllActiveRates(eq(companyId), eq(branchId)))
                .thenReturn(List.of());
        when(encoder.encodeMultiDisplay(any(), any())).thenReturn(packets);
        when(serialDriver.send(eq("COM1"), eq(packet))).thenReturn(true);

        service.refreshDisplay(branchId);

        verify(serialDriver).send(eq("COM1"), eq(packet));
    }

    @Test
    @DisplayName("2. refreshDisplay: inaktiv konfiguracio eseten kihagyja a kuldest")
    void refreshDisplaySkipsInactive() {
        config.setIsActive(false);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(ledDisplayConfigRepository.findByBranchId(branchId)).thenReturn(Optional.of(config));

        service.refreshDisplay(branchId);

        verifyNoInteractions(serialDriver);
        verifyNoInteractions(encoder);
    }

    @Test
    @DisplayName("3. refreshDisplay: hianyzo konfiguracio ResourceNotFoundException-t dob")
    void refreshDisplayThrowsWhenConfigMissing() {
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(ledDisplayConfigRepository.findByBranchId(branchId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.refreshDisplay(branchId))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ---------- refreshAllActive ----------

    @Test
    @DisplayName("4. refreshAllActive: osszes aktiv kijelzot frissiti")
    void refreshAllActiveSendsToAllActive() {
        UUID branchId2 = UUID.randomUUID();
        Company company2 = new Company();
        company2.setId(UUID.randomUUID());
        Branch branch2 = new Branch();
        branch2.setId(branchId2);
        branch2.setCompany(company2);
        branch2.setCode("TEST2");
        branch2.setName("Teszt 2");

        LedDisplayConfig config2 = new LedDisplayConfig();
        config2.setBranch(branch2);
        config2.setIsActive(true);
        config2.setSerialDisplayType(LedSerialDisplayType.STANDARD);
        config2.setComPorts("COM2");
        config2.setCurrencies("EUR");
        config2.setSpeedCommand(false);
        config2.setSpeed(5);
        config2.setEndMarkers("254");
        config2.setDecimalSeparator(',');
        config2.setShowBankCard(false);

        when(ledDisplayConfigRepository.findByIsActiveTrue()).thenReturn(List.of(config, config2));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(branchRepository.findById(branchId2)).thenReturn(Optional.of(branch2));
        when(exchangeRateRepository.findAllActiveRates(any(), eq(branchId))).thenReturn(List.of());
        when(exchangeRateRepository.findAllActiveRates(any(), eq(branchId2))).thenReturn(List.of());
        when(encoder.encodeMultiDisplay(any(), any())).thenReturn(new byte[][]{new byte[]{21, 18, 5, (byte) 254}});
        when(serialDriver.send(any(), any())).thenReturn(true);

        service.refreshAllActive();

        verify(serialDriver, times(2)).send(any(), any());
    }

    // ---------- getConfig ----------

    @Test
    @DisplayName("5. getConfig: DTO-t ad vissza a branchId alapjan")
    void getConfigReturnsDto() {
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(ledDisplayConfigRepository.findByBranchId(branchId)).thenReturn(Optional.of(config));

        LedDisplayConfigDto dto = service.getConfig(branchId);

        assertThat(dto).isNotNull();
        assertThat(dto.getBranchId()).isEqualTo(branchId);
    }

    // ---------- updateConfig ----------

    @Test
    @DisplayName("6. updateConfig: elmenti es visszaadja a frissitett konfiguraciot")
    void updateConfigSavesAndReturns() {
        LedDisplayConfigDto dto = LedDisplayConfigDto.builder()
                .comPorts("COM3")
                .currencies("EUR,GBP")
                .speed(7)
                .speedCommand(true)
                .endMarkers("254")
                .decimalSeparator(',')
                .build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(ledDisplayConfigRepository.findByBranchId(branchId)).thenReturn(Optional.of(config));
        when(ledDisplayConfigRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LedDisplayConfigDto result = service.updateConfig(branchId, dto);

        verify(ledDisplayConfigRepository).save(any());
        assertThat(result).isNotNull();
    }

    // ---------- sendCustomText ----------

    @Test
    @DisplayName("7. sendCustomText: kodolja es elkuldi a szoveget")
    void sendCustomTextEncodesAndSends() {
        byte[] textPacket = new byte[]{21, 18, 5, 'H', 'I', (byte) 254};
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(ledDisplayConfigRepository.findByBranchId(branchId)).thenReturn(Optional.of(config));
        when(encoder.encodeText(eq(config), eq("HELLO"))).thenReturn(textPacket);
        when(serialDriver.send(eq("COM1"), eq(textPacket))).thenReturn(true);

        service.sendCustomText(branchId, "HELLO");

        verify(encoder).encodeText(eq(config), eq("HELLO"));
        verify(serialDriver).send(eq("COM1"), eq(textPacket));
    }

    // ---------- DUAL_SAME ----------

    @Test
    @DisplayName("8. DUAL_SAME: mindket COM portra kuld")
    void dualSameSendsToBothPorts() {
        config.setSerialDisplayType(LedSerialDisplayType.DUAL_SAME);
        config.setComPorts("COM1,COM2");

        byte[] packet = new byte[]{21, 18, 5, (byte) 254};
        byte[][] packets = new byte[][]{packet, packet};

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(ledDisplayConfigRepository.findByBranchId(branchId)).thenReturn(Optional.of(config));
        when(exchangeRateRepository.findAllActiveRates(eq(companyId), eq(branchId)))
                .thenReturn(List.of());
        when(encoder.encodeMultiDisplay(any(), any())).thenReturn(packets);
        when(serialDriver.send(anyString(), any())).thenReturn(true);

        service.refreshDisplay(branchId);

        verify(serialDriver).send(eq("COM1"), eq(packet));
        verify(serialDriver).send(eq("COM2"), eq(packet));
    }
}
