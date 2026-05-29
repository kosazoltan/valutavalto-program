# Rendszer alapstruktúra — válaszok a kollégák kérdéseire

> **Forrás-dokumentum:** `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/kerdesek.docx`
> (az eredeti Windows-úton `Rendszer_alapstruktura_kerdesek.md` néven érkezett; a tárolt
> tartalom a fenti `.docx` fájlban van).
>
> **Hatókör és módszertan:** Az alábbi válaszok KIZÁRÓLAG ennek a repónak a tényein alapulnak
> (CLAUDE.md, AI_CONSTITUTION.md, AGENTS.md, a backend `entity/` / `controller/` / `service/`
> állományai, Flyway-migrációk, frontend és Electron-kliensek). Ahol a forrás-dokumentum maga
> tartalmazza a kolléga (Kósa cégcsoport) hiteles üzleti válaszát, azt **üzleti elvárásként**
> idézem, és mellé teszem, hogy a repo (az épülő új ERP) ezt **jelenleg hogyan fedi le**.
> Ahol a repo nem ad egyértelmű választ, azt nyíltan jelzem:
> „a repo alapján erre nincs egyértelmű információ".
>
> **Megjegyzés a tényalapra (repo):** Java 21 / Spring Boot 4 backend (`backend/`), React 19 admin
> (`frontend-react/`), Electron-kliensek (`penztar-client/`, `kozponti-client/`,
> `arfolyam-keszito-client/`) local-first SQLite + outbox-sync architektúrával. Multi-tenant
> (`companyId` szűrés mindenhol), OSIV kikapcsolva, HUF 5 Ft-os kerekítés
> (`backend/.../util/HungarianRounding.java`), Flyway-migrációk (`backend/.../db/migration/`),
> production: Hetzner HA `https://excvaluta.com`. A domain-fogalmakat dedikált entitások/szolgáltatások
> fedik le; a repóban ténylegesen megtalált, releváns nevek (a teljesség igénye nélkül):
> `Transaction` / `TransactionType` / `TransactionLine` (vétel/eladás/konverzió),
> `TransactionConversionService` + `ConversionRequestDto` (konverzió), `StornoService` /
> `StornoController` / `StornoApproval` (sztornó), `Reservation` (foglaló), `Receipt` /
> `ReceiptSequence` (bizonylat), `NavClosing` / `NavIntegrationService` / `NavReportService` (NAV),
> `Denomination` / `DenominationCount` (címletezés), `ExchangeRate` / `RateWorkgroup` / `RateDiscount`
> / `FeeDiscount` / `DiscountApprovalService` (árfolyam, kedvezmény), `AverageRateReportService`
> (átlagárfolyam), `BankOrder` / `BankOrderService` / `RaiffeisenRateService` (banki kötés/fixing),
> `SanctionEntry` / `SanctionScreeningService` / `ProhibitedPerson` / `ProhibitedCompany` /
> `BlacklistService` (szankciós/tiltólista), `PoliceRequest` (hatósági megkeresés), `AnonymousReport`
> (névtelen bejelentés), `SupervisorService` / `SupervisorPinService` (supervisori engedély),
> `TeaorCode` (TEÁOR), `BookingExportService` (könyvelési export), `Transfer` / `TransferLine` /
> `VaultTransfer` (átadás-átvétel), `DailySession` / `EveningClosing` / `ClosingWizard`
> / `MonthlyClosing` (nap-/hó-zárás), `ArchivingService` (archiválás), `Circular` (körlevél),
> `HandlingFeeBracket` / `HandlingFeeService` (kezelési díj), `CommissionRate` / `WorkerCommission`
> (jutalék), `AuditLog` (immutable hash-chain audit), `SealNumber` / `SealTracking` (plomba).
>
> **Fontos pontosítás:** néhány alább hivatkozott domain-fogalomra a repóban nincs külön nevesített
> entitás (pl. „közszereplő nyilatkozat" külön táblaként, „tranzakciós adó" külön entitásként,
> „fiók-nyitvatartás" külön entitásként) — ezeket más mezők/szolgáltatások fedik, és ahol így van,
> azt az adott válasznál jelzem.

---

## 1. A napi zárás „kikényszerítése" — kilépés előtti felajánlás
**Kérdés:** A napi zárás „kikényszerítéséhez" megfelelő-e, ha a fiók zárása előtt x (pl. 30) perccel a kilépéskor erősen (külön tennie kelljen valamit, hogy zárás nélkül kilépjen) felajánlja a zárást?
**Válasz:** Üzleti elvárás (a dokumentumban a kolléga válasza): **„Elegendő."** Tehát a kilépés előtti, nyomatékos zárás-felajánlás megfelelő megoldás. A repóban a napzárás domainjét a `DailySession` entitás / `CashRegisterSessionController` kezeli (pénztár-szesszió nyitás/zárás). A konkrét „x perccel kilépés előtt erős felajánlás" UI-viselkedés a pénztáros Electron-kliens (`penztar-client/`) felelőssége — a repo alapján a session-zárás backend-támogatása megvan, de a 30 perces figyelmeztetés pontos kliens-implementációjára nincs egyértelmű külön bizonyíték.

## 2. Bizonylatszámok sorszám-része: fiókon belül vagy céges szinten egyedi?
**Kérdés:** A bizonylatszámok sorszám része fiókon belül egyedi, vagy céges szinten?
**Válasz:** Üzleti elvárás (kolléga válasza): a bizonylat sorszáma **a pénztár (fiók) számával kezdődik**, és azon belül folyamatos, kihagyásmentes. Pl. 74. sz. pénztár (Békéscsaba Tesco) → `074`, 143. sz. pénztár (Pécs Pláza) → `143` kezdőszám, utána folytonos sorszám. A betű a tranzakció típusára utal:
- V – vétel, E – eladás
- F – valuta átadás, U – valuta átvétel
- FF – Forint átadás, UF – Forint átvétel
- B – kezelési ktg. átvétele, K – kezelési átadás
- Foglalónál is B (átvétel) / K (átadás)

Vagyis a sorszámozás **fiók-szintű (pénztár-prefix + fiókon belüli folyamatos sorszám)**, nem céges szintű folytonos. A repóban a multi-tenant elv (`companyId`) és a pénztár-fogalom (`CashRegisterDevice` / `Workstation`) megvan; a bizonylat-prefix/sorszám-képzés a tranzakciós entitásokhoz (`Transaction` stb.) kötődik, de a fenti betűkód-séma pontos kódszintű leképezésére a repo nem ad explicit megerősítést (a tárolt szabály a forrás-dokumentumból származik).

## 3. Árfolyam-kedvezmény eltérés-figyelmeztetés — %-ot jelent?
**Kérdés:** Figyelmeztetést várnak akkor, ha az árfolyam-kedvezmény „előre meghatározott értéknél nagyobb mértékben tér el". Ez %-ot jelent?
**Válasz:** Üzleti elvárás (kolléga válasza): **Igen, %-ot jelent.** Van egy mérték (**2%**), amely felett csak supervisori (értéktárosi supervisori) jelszóval lehet az árfolyamot módosítani. A repóban az engedélyező/supervisori mechanizmust az `SupervisorService` / `SupervisorPinService` (supervisori PIN) fedi le; a sávos/egyedi árfolyam-kedvezmény az `RateWorkgroup` / `RateDiscount` / `RateDiscount` / `FeeDiscount` entitásokon keresztül modellezett. A konkrét 2%-os küszöb-konstans repo-szintű jelenlétére nincs egyértelmű külön bizonyíték — ezt küszöbként kell konfigurálni.

## 4. Átlagárfolyam: középárfolyam vagy számolt?
**Kérdés:** Átlag árfolyam: az a középárfolyam, vagy számolt? Amennyiben számolt, miként?
**Válasz:** Üzleti elvárás (kolléga válasza): **számolt.** A főértéktár számolja (a szerveren menü végzi). A valutás programban vételi, eladási és **elszámoló** árfolyam van; az elszámolót az árfolyamos főértéktáros határozza meg. A napi valuta forint-ellenértékét az **elszámoló árfolyammal** tartják nyilván, **hó végén viszont MNB-árfolyamon**. Külön kérdésben pontosítva: a főértéktárnak van egy programja, amely egy adott időszak vételi/eladási árfolyamából számol átlagárfolyamot. A repóban ezt az `AverageRateReportService` + `AverageRateReportController` fedi le (átlagárfolyam-számítás külön domain). A pontos képlet (mely tételekből, milyen súlyozással) repo-szinten nem dokumentált egyértelműen — az üzleti definíció a fenti.

## 5. Hirtelen költségre pénzkivét és lekönyvelés?
**Kérdés:** Olyan lehet, hogy valami hirtelen költségre vesznek ki pénzt, és azt kéne lekönyvelni?
**Válasz:** Üzleti elvárás (kolléga válasza): **Nem, szigorúan TILOS.** A pénztárból ad-hoc költségre pénzt kivenni nem szabad. A repóban nincs is „költség-kivét" tranzakciótípus — a pénzmozgásokat zárt típusok kezelik (vétel/eladás, átadás-átvétel, foglaló, kezelési díj). Ez összhangban van a tiltással.

## 6. Készlet-nyilvántartás: „maradék Forint" mit jelent?
**Kérdés:** Készlet nyilvántartás: „maradék Forint" mit jelent?
**Válasz:** A kolléga visszakérdezett: **„Ez hol van pontosan?"** — azaz a fogalmat maga is tisztázni kérte. A repo alapján erre nincs egyértelmű, „maradék Forint" néven nevesített mező; a forint-készletet az `CashBalance` / `DailyBalance` (nyitó/napi egyenleg) és a pénztár-mozgások (`CashBalance` / `InventoryMovement`) együttese adja. Konkrét „maradék Forint" definícióra a repo alapján nincs egyértelmű információ.

## 7. Forgalom-nyilvántartás: „MTCN szám(ok)" mit jelent?
**Kérdés:** Forgalom nyilvántartás: „MTCN szám(ok)" mit jelent?
**Válasz:** Üzleti válasz (kolléga): **„Ez már nincs, a WU (Western Union) kikerült a programból."** Az MTCN a Western Union pénzküldemény-azonosító száma volt. A repóban ugyan létezik Western Union domain (`WuTransaction` / `WesternUnionService`, örökölt fogalom), de az üzleti elvárás szerint a WU-funkció megszűnt, így ez a mező új rendszerben nem releváns / kivezetendő.

## 8. Pénztár nyitási/zárási napló — a nyitónál a „forgalmi adatok" mit jelentenek?
**Kérdés:** Pénztár nyitási/zárási napló naponként tételesen lekérhető lista: a nyitónál a forgalmi adatok mit jelentenek?
**Válasz:** A kolléga visszakérdezett: **„Ez melyik menüpontban van?"** A repóban a nyitás/zárás naplót a `DailySession` (napi szesszió) + `CashBalance` / `DailyBalance` (nyitó/napi egyenleg) fedi le, naponként lekérdezhetően. A „nyitónál szereplő forgalmi adatok" pontos jelentésére (várhatóan a nyitó címlet/egyenleg-állapot) a repo alapján nincs egyértelmű, definíciószintű információ.

## 9. Közszereplő típusa (államfő, képviselő) rögzítendő?
**Kérdés:** Közszereplő típusa (államfő, képviselő) rögzítendő?
**Válasz:** Üzleti elvárás (kolléga válasza): **Igen.** Választani kell a megadott (törvényi) listából, rögzíteni kell, és a bizonylaton nyomtatni kell, mert az ügyfél nyilatkozik és aláírja. A repóban ezt a a `Transaction` PEP-mezői (V235 `transaction_pep_kind_and_actor_identity` migráció) + a bizonylat-nyomtatás (`Receipt`) fedik le — tehát a típus-rögzítés és nyilatkozat domain szinten támogatott.

## 10. Részletes jelentés: többlet/hiány/eltérés — nincs redundancia?
**Kérdés:** Részletes jelentés: többlet mennyiség, hiány mennyiség, eltérés: itt nincs redundancia az eltérés kapcsán?
**Válasz:** A kolléga visszakérdezett: **„Ezt nem értem, ez hol van?"** — tehát a redundancia-aggályt nem erősítette meg, tisztázást kért. A repo alapján a többlet/hiány-kezelés a kasszaszámolás/eltérés-könyvelés körébe tartozik (lásd 49. pont: TH-pénztár), de konkrét „részletes jelentés" mezőstruktúrára és redundanciára a repo alapján nincs egyértelmű információ.

## 11. Címletezésnél legyen-e címlet-mennyiség figyelés?
**Kérdés:** Címletezésnél legyen-e címlet mennyiség figyelés (ha valaki mindig címletezik)?
**Válasz:** Üzleti elvárás (kolléga válasza): **Nem szükséges** a folyamatos címlet-mennyiség figyelés; és igen, van, aki egész nap, minden tétel után címletezik. A repóban a címletezést a `Denomination` + `DenominationCount` entitások fedik le (címlet-bontás rögzítése), de a forrás szerint nem kell ehhez automatikus mennyiség-figyelő riasztás.

## 12. Valuta átvétel banktól: banki bizonylat rögzítése nem kéne?
**Kérdés:** Valuta átvétel banktól: banki bizonylat rögzítése nem kéne?
**Válasz:** Üzleti válasz (kolléga): **Nem,** mert a mi bizonylatunk a banki bizonylat ellenpárja (a saját átvételi bizonylat elegendő). A repóban a banktól való valuta-/forintmozgást a `VaultBankTransaction` (+ `BankTransferController`) és a `BankOrder` fedik le; külön „banki bizonylat" rögzítő mező nem szükséges.

## 13. Bizonylat másolat nyomtatása (nem újranyomtatás) — kell?
**Kérdés:** Bizonylat másolat nyomtatása nem kell? (Nem az újranyomtatásra gondolok.)
**Válasz:** Üzleti válasz (kolléga): van ilyen lehetőség most is — a „bizonylatok megtekintése" menüben van egy **újranyomtatás** gomb, amelyet csak belső ellenőri (supervisori) jelszóval lehet használni, és **be kell írni a nyomtatás indokát/okát**. A repóban a bizonylat-újranyomtatás supervisori engedélyhez kötése konzisztens a `SupervisorService` / `SupervisorPinService` mechanizmussal és az immutable `audit_log` elvárással (minden ilyen művelet auditálandó). Konkrét „másolat vs. újranyomtatás" külön kódmezőre nincs egyértelmű bizonyíték, de az engedély+indok elvárás a fenti.

## 14. Bank Forint átadás: átutalás kezelése?
**Kérdés:** Bank Forint átadás: átutalás: ennek a kezelése?
**Válasz:** Üzleti válasz (kolléga): **Nincs átutalás** náluk, csak készpénz vagy bankkártyás fizetés. A repóban a forint-mozgást a `Transfer` / `TransferLine` (forint-átadás típus) fedi le pénztárak/bank között; átutalás-funkció nem szükséges.

## 15. Kezelési díj pénztárból a valutába forint áttétel?
**Kérdés:** Olyan lehet, hogy a kezelési díj pénztárból a valutába áttesznek Forintot?
**Válasz:** Üzleti elvárás (kolléga válasza): **Nem lehet** — a két kasszát (kezelési díj és valuta) **elkülönítetten** kell kezelni. A repóban a kezelési díjat külön domain (`HandlingFeeService` + `HandlingFeeConfigController`) kezeli, ami támogatja a kassza-elkülönítést.

## 16. Központban stornóznak — az eredeti fiók kap értesítést?
**Kérdés:** Központban stornóznak. Az eredeti fiók kap értesítést?
**Válasz:** Üzleti válasz (kolléga): **Nem** — minden pénztár **helyileg** stornózhat, indok megadásával; a **harmadik** stornót követően már csak belső ellenőri jelszóval lehet stornózni. A repóban a stornót a `StornoService` / `StornoController` (+ `StornoApproval`) fedi le, az engedélyhez kötést pedig a `SupervisorService` / `SupervisorPinService`. A „harmadik storno után belső ellenőri jelszó" küszöbszabály a forrás-dokumentum üzleti elvárása; konkrét konstans repo-szintű jelenlétére nincs egyértelmű külön bizonyíték.

## 17. Sztornónál a NAV-os bizonylatszámot nem kell bekérni?
**Kérdés:** Sztornónál a NAV-os bizonylatszámot nem kell bekérni?
**Válasz:** Üzleti válasz (kolléga): **Nem,** mert ha történt NAV-nyugta-nyomtatás, azt a gép tudja, és a stornót ki lehet küldeni a NAV-nyomtatóra, ahol a program is lestornózza. A repóban a NAV-kommunikációt a `NavIntegrationService` / `NavReportService` / `NavClosing` fedi le, ami a stornó NAV felé történő továbbítását is kezeli — így a NAV-bizonylatszám kézi bekérése nem szükséges.

## 18. Kezelési költségek jelentése: „...jutalék" mit jelent?
**Kérdés:** Kezelési költségek jelentése: „...jutalék" mit jelent? A kezelési díjat, vagy?
**Válasz:** A kolléga visszakérdezett: **„Ez hol van?"** Külön, későbbi kérdésnél (lásd lent) megerősíti, hogy a jutalék **%-os** és a kifizetettségéről/könyvelésnek átadásáról kell információ. A repo alapján a „jutalék" külön nevesített, kezelési díjtól megkülönböztetett mezőre nem ad egyértelmű információt; a kezelési díjat a `HandlingFeeService` / `HandlingFeeBracket` fedi.

## 19. Tranzakciós adó jelentés: hogyan számolandó?
**Kérdés:** Tranzakciós adó jelentés: hogyan számolandó?
**Válasz:** Üzleti válasz (kolléga): törvényi előírás szerint a **tranzakciós illeték 4,5 millió Ft alatt 4,5 ezrelék, e felett darabonként 20 000 Ft**, amit a NAV-nak meg kell fizetni (a forrás szerint aug. 1-jével emelkedett ennyire). A repóban ezt a tranzakciós illeték-számítás (a repóban nincs külön tranzakciós illeték-logika (nincs külön entitás) entitás; a tranzakciós adatokból a riport-szolgáltatások számolják) fedi le. A konkrét aktuális ráta/küszöb-konstansok repo-szintű értékére nincs egyértelmű külön bizonyíték — az üzleti számítási szabály a fenti.

## 20. Pénztárak kezelése — „állapot (nyitva/zárva)" mit jelent?
**Kérdés:** Pénztárak kezelése: „állapot (nyitva/zárva)": a napi nyitva/zárva, vagy üzemel/nem üzemel?
**Válasz:** Üzleti válasz (kolléga): a szerveren lévő állapot azt jelenti, hogy **az adott pénztár üzemel-e vagy sem** (pl. hétvégén nincs nyitva, vagy a tárgynapon nem volt nyitva). Ez azért kell, hogy a szerver ellenőrzéskor **ne keresse az adott pénztár zárását**. A repóban a pénztárt a `CashRegisterDevice` / `Workstation`, a napi szessziót a `DailySession` modellezi — tehát megkülönböztethető a „üzemel-e" törzsadat-állapot és a napi szesszió-állapot.

## 21. Valuta értéktár↔pénztár közti mozgás — kell-e NAV-gépre?
**Kérdés:** Valuta mozog értéktár–pénztár közt: annak ugye nem kell NAV-gépre mennie?
**Válasz:** Üzleti válasz (kolléga): **De, kell.** (Lásd 47. pont is: a pénztárak közötti átadás/átvétel is bemegy a NAV-hoz.) A repóban az értéktár↔pénztár mozgást a `Transfer` (+ `TransferController`), a NAV-továbbítást a `NavIntegrationService` / `NavClosing` fedi — tehát az átadás-átvétel NAV felé jelentése domain szinten támogatható.

## 22. Pénzküldemény nem érkezik meg — mi a teendő?
**Kérdés:** Pénz küldemény nem érkezik meg. Mi a teendő? Stornó valami jogcímmel és jegyzőkönyv-csatolás pl.?
**Válasz:** Üzleti válasz (kolléga): **Csak akkor veszi át a pénztár a küldeményt, ha az fizikálisan ott van.** Tehát nincs „eltűnt küldemény storno" eljárás: átvétel csak fizikai jelenlét esetén történik. A repóban az átadás-átvételt a `Transfer` modellezi; a fizikai átvétel-feltétel üzleti szabály, amit az átvétel rögzítésének feltételeként kell érvényesíteni.

## 23. Storno darabszám-engedély: nap/fiók, vagy nap/pénztáros/fiók?
**Kérdés:** Sztornó darabszám engedély: nap/fiók, vagy nap/pénztáros/fiók darabra vonatkozik?
**Válasz:** Üzleti válasz (kolléga): „fentebb írtam a központi stornónál" — azaz a 16. pont szabálya érvényes: helyi stornó indokkal, a **harmadik storno után belső ellenőri jelszó**. A pontos „nap/pénztáros/fiók" granularitásra a repo nem ad egyértelmű kódszintű információt; a `StornoService` / `StornoApproval` rögzíti a stornókat, az engedély a `SupervisorService` / `SupervisorPinService`-höz kötött.

## 24. Engedélyező kódképzés szabálya stornónál/kedvezményeknél?
**Kérdés:** Az engedélyező kódképzés szabálya sztornónál, kedvezményeknél?
**Válasz:** Üzleti válasz (kolléga): kétféle jelszó van — **belső ellenőri supervisori** és **értéktárosi**. Az értéktárosit **csak az árfolyamok módosításához** használják, minden más módosításhoz (storno stb.) a belső ellenőri supervisori kell. A pontos **kódképzési algoritmust** a kolléga külön, jelszóval védett csatornán küldené, mert szeretnék megtartani (fejben számolják). A repóban az engedélyező jelszó-mechanizmust az `SupervisorService` / `SupervisorPinService` fedi le; a konkrét kódképzési képlet **érzékeny adat, nincs (és nem is lehet) a repóban** — erről a repo alapján nincs információ (és titokként nem is tárolandó).

## 25. Bankba pénzszállítás: úgy mint fiókba, vagy a bank intézi?
**Kérdés:** Bankba pénz szállításnál: ugyanúgy mint pl. egy fiókba, vagy a bank intézi (kell-e plombaszám, szállító)? Esetleg ilyen is olyan is lehet?
**Válasz:** Üzleti válasz (kolléga): **Ugyanúgy, mint egy fióknál,** annyi eltéréssel, hogy vannak betűjelölések: pl. **ERB** – egyedi kötés bank, **TRB** – területek közötti befizetés bank, **FRB** – fixing bank stb. A repóban a banki mozgást a `VaultBankTransaction` / `BankOrder` fedi, a plombaszám a szállítmány-kezeléshez tartozik (lásd 39. pont — plombaszám formátum). A konkrét betűkód-séma a forrás-dokumentum üzleti szabálya.

## 26. Értéktárosi felületen a társpénztárnál szereplő MNB — mit, mikor, hogyan?
**Kérdés:** Az értéktárosi felületen a társpénztárnál szerepel az MNB. Oda mit, mikor, hogyan?
**Válasz:** Üzleti válasz (kolléga): **Az már nem kell.** Régebben az MNB-hez beszállított hamisgyanús valutát/forintot itt adták ki, de **most már TH (többlet-hiány) pénztárnak** könyvelik. A repóban tehát az MNB-társpénztár kivezetendő; a TH-pénztár logika a pénztár-mozgás/eltérés-könyveléshez kapcsolódik.

## 27. Egy ügyletben vétel és eladás (keresztváltás) — egy vagy két bizonylat?
**Kérdés:** Ha egy ügyletben van vétel is, eladás is (pl. keresztváltás), ragaszkodtok a két bizonylathoz, vagy szerepelhet egyen is a két tranzakció (az irányt jelölve)?
**Válasz:** Üzleti válasz (kolléga): **Két bizonylat kell (törvényi előírás).** A konverzió menüpontban könyvelik, de **egy vétel és egy eladás** bizonylat keletkezik, és a bizonylatokon fel kell tüntetni: **konverziós vétel / konverziós eladás**. A repóban ezt külön domain fedi: `TransactionConversionService` + `ConversionRequestDto` (a sima `Transaction` mellett, V267 `conversion_returned_huf` migrációval) — tehát a két-bizonylatos konverzió struktúrája adott.

## 28. Névtelen bejelentés: ki tette — soha senki ne lássa, vagy van „szuperjog"?
**Kérdés:** Névtelen bejelentés: azt, hogy ki tette, soha senki ne láthassa, vagy van olyan, hogy valamilyen hiper-szuper joggal meg kell tudni nézni? (Később: Névtelen bejelentést kik nézhetik, és hol? Nem probléma, ha a fiókban nézi meg valaki, és abból rájöhet, ki írta?)
**Válasz:** A forrás-dokumentum a bejelentés-folyamatra ad választ (lásd 30. pont: feladás előtt kiléphet, beküldés után nem módosítható; a központban Zsuzsáék nézik), de **arra, hogy a bejelentő kilétét bárki (szuperjoggal) megtekintheti-e, a dokumentum nem ad egyértelmű, kifejezett választ** — ez nyitott pont maradt. A repóban a bejelentés-/hatósági adatszolgáltatás domainjét a `PoliceRequest` és az `AnonymousReport` fedik le; a bejelentő-anonimitásra vonatkozó konkrét hozzáférési szabályra a repo alapján nincs egyértelmű információ. (Általános repo-elv: minden hozzáférés `@PreAuthorize`-zal védett, és immutable `audit_log` rögzíti a betekintést.)

## 29. Átadólistán az ügyfél-rendelések: foglaló, kérelmek, vagy mindkettő?
**Kérdés:** Átadólistán: az ügyfél-rendelések az a foglaló, vagy csak kérelmek, vagy mindkettő?
**Válasz:** A repo alapján erre nincs egyértelmű információ (a forrás-dokumentum sem ad rá explicit választ). A foglaló-domaint a `Reservation` fedi; az „átadólista" és a foglaló viszonyára nincs kódszintű megerősítés.

## 30. Adatlapok funkció? Mire szolgál?
**Kérdés:** Adatlapok funkció? Mire szolgálna / szolgál?
**Válasz:** Üzleti válasz (kolléga): ebben a menüben van az **adatlap**, amin az adatok feltöltésével lehet elkészíteni a **bejelentést**, amelyet lenyomtatnak egy átadólappal, és zárt borítékban beküldenek továbbításra a területi vezetőnek. Kapcsolódó elvárás: a bejelentésből feladás (nyomtatás) **előtt** ki lehessen lépni (ezzel törölve azt); legyen a végén egy „valóban elküldi?" gomb; **beküldés után nem módosítható**. A repóban a hatósági bejelentés-/adatlap-domaint a `PoliceRequest` / `AnonymousReport` (+ a `Transaction` adat-mezői) fedik. A „beküldés előtt törölhető, utána nem módosítható" életciklus üzleti elvárás; pontos állapotgép-implementációra a repo nem ad külön egyértelmű bizonyítékot.

## 31. Supervisori jelszóval törölhető a 300 ezer felett váltó ügyfél?
**Kérdés:** Supervisori jelszóval simán tudtam törölni olyan ügyfelet is, aki 300 ezer fölött váltott. Ezt szabad?
**Válasz:** Üzleti válasz (kolléga): **Nem.** A 300 ezer Ft felett (teljes azonosítással) váltó ügyfél nem törölhető. A repóban az ügyfelet a `Customer` entitás fedi; a megőrzési/törlés-tiltási szabály AML-megőrzési követelmény (lásd 37. pont — min. 1 év, audit immutable). Ez hibajavítandó tényező, ha a jelenlegi rendszer megengedi — az új ERP-ben a 300k feletti, azonosított ügyfél törlését tiltani kell.

## 32. Alkalmazás-típus átállítása pénztáriból értéktáriba — van relevanciája?
**Kérdés:** Az alkalmazás típusát át tudom állítani pénztáriból értéktáriba. Ennek van relevanciája? (Semmi sem változik tőle, viszont indításkor hibaüzenet jön azóta.)
**Válasz:** Ez a **régi (Delphi) rendszer** viselkedésére vonatkozó megfigyelés; a forrás nem ad rá üzleti választ. Az **új** architektúrában a szerepkör nem egy állítható „alkalmazás-típus", hanem külön Electron-kliensek vannak: `penztar-client` (pénztáros), `kozponti-client` (központi + árfolyamkészítő, módválasztóval), `arfolyam-keszito-client`. Tehát az új rendszerben ez a problémás kapcsoló fogalmilag megszűnik. A régi hibaüzenet okára a repo alapján nincs információ.

## 33. Eladási és vételi kezelési díj ugyanannyi?
**Kérdés:** Eladási és vételi kezelési díj ugyanannyi?
**Válasz:** Üzleti válasz (kolléga): **Igen.** A repóban a kezelési díjat a `HandlingFeeService` / `HandlingFeeBracket` konfigurálja; a vételi/eladási díj egyenlősége konfigurációs/üzleti beállítás kérdése.

## 34. Szünet közben miért lehet a rendszerben tevékenykedni?
**Kérdés:** Szünet közben miért lehet a rendszerben tevékenykedni?
**Válasz:** Ez a régi rendszerre vonatkozó megfigyelés/hibajelzés; a forrás nem ad rá üzleti magyarázatot. A repo alapján a pénztárszünet-állapot megjelenik az árfolyamkijelzőn (lásd 36. pont), de hogy szünet alatt miért engedett a tevékenység, arra nincs egyértelmű információ — feltehetően az új rendszerben a szünet-állapot alatt a tranzakciós műveleteket tiltani/korlátozni kell.

## 35. OTP-terminál log olvasása a supervisori/pénztári szüneteknél — miért?
**Kérdés:** OTP terminál log olvasása a supervisori / pénztári szüneteknél miért van?
**Válasz:** Üzleti válasz (kolléga): **„technika ördöge"** — azaz nem szándékos elvárás. A repo alapján a POS/bankkártya-terminál interfész a nyitó rutinban van (lásd 53. pont); a szünet alatti log-olvasásra nincs egyértelmű repo-információ, és üzletileg sem elvárás.

## 36. NAV-os pénztárgép: egylépcsős és 3 lépcsős nyitás mit jelent?
**Kérdés:** NAV-os pénztárgép működése? Egylépcsős és 3 lépcsős nyitás mit jelent?
**Válasz:** Üzleti válasz (kolléga): **régen volt 3 lépcsős** (ma egylépcsős). Tehát a 3 lépcsős nyitás örökölt fogalom, már nem releváns. A repóban a NAV-kommunikáció a `NavIntegrationService` / `NavReportService` / `NavClosing` domainhez tartozik; a részletes NAV-gép protokoll (DC/Z paraméterek stb.) a Prior Kft.-nek feltett külön kérdésblokk tárgya (lásd 53–54. pont).

## 37. „Úton lévő pénztár" és „POS átvétel banktól" társpénztár — mit jelent?
**Kérdés:** „Úton lévő pénztár" és „POS átvétel banktól" a társpénztár választásakor mit jelent?
**Válasz:** Üzleti válasz (kolléga): **„Úton lévő pénztár"** – olyan, mint bármelyik pénztár, csak technikai elnevezés (szállítás alatti pénzkészlet). **„POS átvétel banktól"** – a bankkártyás fizetések ellenértékét ettől a (technikai) pénztártól veszik fel. A repóban a pénztár-fogalom (`CashRegisterDevice` / `Workstation`) és a pénztárak közti mozgás (`Transfer`) ezt lefedi; a POS/bank-pénztár technikai pénztárként kezelendő.

## 38. „Új pénztár felvétele" ad-hoc, előfordul? Törölhető?
**Kérdés:** „Új pénztár felvétele" ad-hoc, előfordul?
**Válasz:** Üzleti válasz (kolléga): új pénztár nyitásakor a listába itt kell felrögzíteni; a listából **alapból nem lehet törölni**, **de supervisori jelszóval lehet** pénztárat törölni. A repóban a pénztárt a `CashRegisterDevice` / `Workstation` (+ `CashRegisterController`) kezeli; a törlés engedélyhez (supervisori) kötése konzisztens a `SupervisorService` / `SupervisorPinService` mechanizmussal.

## 39. Ügyfél-adat szerkesztés — szükséges funkció?
**Kérdés:** Ügyfél adat szerkesztés, szükséges funkció?
**Válasz:** Üzleti válasz (kolléga): **NEM.** Az ügyfél-adatok utólagos szerkesztése nem szükséges/nem kívánt funkció (AML-szempontból is indokolt: rögzített azonosító adat ne legyen szabadon módosítható). A repóban az ügyfél a `Customer` entitás; az adat-szerkesztés tiltása/korlátozása üzleti elvárás.

## 40. Foglaló határidejét hogyan állapítja meg a rendszer?
**Kérdés:** Foglaló határidejét hogyan állapítja meg a rendszer?
**Válasz:** Üzleti válasz (kolléga): mindig **a következő napot** ajánlja fel, de ez módosítható; ha a tárgynap és a foglalási időpont között **5 vagy több nap** van, akkor a dátumot csak **supervisori jelszóval** lehet módosítani. Külön kérdésnél megerősítve: a foglaló határidejénél a **nyitvatartást nem kell** figyelembe venni. A repóban a foglalót a `Reservation` (+ `ReservationController` / `ReservationService`) fedi le; az 5 napos supervisori-küszöb a forrás üzleti szabálya (kódszintű konstansra nincs külön bizonyíték).

## 41. NAV-feladás: pontosan mikor és mit?
**Kérdés:** NAV feladás: pontosan mikor és mit?
**Válasz:** Üzleti válasz (kolléga): tranzakció közben a NAV-os gépre küldi ki a tételt. Részletesen (lásd a NAV-blokk): a NAV-hoz bemegy a **vétel/eladás valutaneme, összege, árfolyama, kezelési költsége, kifizetendő forint, deviza-státusz, dátum, pénztár neve/címe, időpont**. A pénztárak közötti átadás/átvétel **is** bemegy a NAV-hoz; a **foglaló nem** megy be. A repóban a NAV-kommunikációt a `NavIntegrationService` / `NavReportService` / `NavClosing` domain fedi; a fenti adatkör a NAV felé küldött payload üzleti specifikációja.

## 42. Árfolyam-kedvezmény működése — kézi árfolyam után nem enged adni?
**Kérdés:** Az árfolyam-kedvezmény működésének részletei. Pl. kézzel módosítottam az árfolyamot, ettől kezdve nem enged adni.
**Válasz:** Üzleti válasz (kolléga): ha kézzel történik az árfolyam-módosítás (mert nincs szerver/net), ahhoz **supervisori jelszó** kell, és **nem lehet sávos árfolyamot választani** (azt nem tudja letölteni a gép), így **minden ilyen módosítás egyedi árfolyamként könyvelődik**. A repóban a sávos árfolyamot az `RateWorkgroup` / `RateDiscount`, az árfolyamot az `ExchangeRate` fedi; az „offline → csak egyedi árfolyam, supervisori jelszóval" viselkedés összhangban van a local-first/offline-képes Electron-kliens (`penztar-client`) + sync architektúrával. CLAUDE.md tény: lejárt (24h TTL) rátával nincs tranzakció.

## 43. Egy tranzakcióban egy vagy több deviza; a kedvezményes táblázat hogyan képződik?
**Kérdés:** Egy vagy több devizára is egy tranzakcióban, és akkor az egynek vagy többnek számít a számolásban? Az árfolyam-kedvezményes táblázat hogyan képződik?
**Válasz:** Üzleti válasz (kolléga): adható sávos vagy egyedi árfolyam egyetlen devizára is, de **egy tételen belül többre is**. A kedvezményes táblázatot a **főértéktáros** készíti az árfolyamkészítéskor (képletes), és azt töltik le a gépek. A repóban az árfolyamkészítés az `arfolyam-keszito-client` és/vagy a `kozponti-client` (árfolyamkészítő mód) feladata; a sávokat az `RateWorkgroup` / `RateDiscount` / `RateDiscount` / `FeeDiscount` modellezi. Több deviza egy bizonylaton (lásd 51. pont): „amennyi 1 bizonylatra rögzíthető".

## 44. A pénztárszünet ténye megjelenik valami kijelzőn?
**Kérdés:** A pénztárszünet ténye megjelenik valami kijelzőn?
**Válasz:** Üzleti válasz (kolléga): **Igen, az árfolyamkijelzőn.** A repóban az árfolyam-megjelenítés (kijelző) az árfolyam-domainhez kapcsolódik; a szünet-állapot kijelzése üzleti elvárás.

## 45. Pénzmozgásnál mi van, ha nem érkezik meg / eltérés van (kiad 20, bevesz 19)?
**Kérdés:** Pénz mozgásnál mi van, ha nem érkezik meg, vagy eltérés van (kiad 20, bevesz 19)?
**Válasz:** Üzleti válasz (kolléga): a **főértéktáros** ellenőrzi másnap a szerveren; kasszaszámoláskor kijön a **fizikális eltérés**, és leegyeztetik a bizonylatokon. Fizikális eltérést a **TH (többlet-hiány) pénztárral** könyvelnek, a visszapótlást az **1. sz. főpénztárral**; ezeknek a szerveren lévő leválogatásnál van jelentősége. A repóban az átadás-átvételt a `Transfer`, az eltérés-/TH-könyvelést a pénztár-mozgás (`CashBalance` / `InventoryMovement`) + nyitó egyenleg (`CashBalance` / `DailyBalance`) logika fedi; a TH-/főpénztár-konvenció üzleti szabály.

## 46. NAV: mely esetekben kell küldeni, és mit?
**Kérdés:** A NAV-pénztárgép felé mely esetekben kell küldeni akármit, és az „akármi" mi?
**Válasz:** Lásd 41. pont: a NAV-hoz a **vétel/eladás** adatai (valutanem, összeg, árfolyam, kezelési költség, kifizetendő forint, deviza-státusz, dátum, pénztár neve/címe, időpont) mennek; a **pénztárak közötti átadás/átvétel is** bemegy; a **foglaló nem**. Megjegyzés a kolléga részéről: pénztárak közti mozgásnál a valutanemek kódolva mennek; Szegeden ad egy „slippet", amin pontosan látszik minden. A repóban a `NavIntegrationService` / `NavReportService` / `NavClosing` domain ezt fedi; a pontos byte-szintű FISCAT-protokoll a Prior Kft.-blokk tárgya (lásd 53–54.).

## 47. Pénztárak közti mozgás és a foglaló is megy a NAV-ra?
**Kérdés:** Pénztárak közti mozgásnál is mintha lenne valami; a foglalónál kell?
**Válasz:** Üzleti válasz (kolléga): a **pénztárak közötti átadás/átvétel is bemegy** a NAV-hoz; a **foglaló nem megy be.** (Lásd 41. és 50. pont.) A repóban: `Transfer` → NAV (`NavIntegrationService` / `NavClosing`), `Reservation` → nincs NAV-feladás.

## 48. Díjszámítási mód (%-os és sávos) — fiók-függő vagy csoportosítható?
**Kérdés:** Díj számítási mód lehet %-os és sávos. Ennek beállítása teljesen fiók-függő, vagy köthető valamilyen fiók-csoportosításhoz (pl. belvárosi fiókoknál ilyen, tescosoknál olyan)?
**Válasz:** A kolléga visszautal egy korábbi pontra („Mint 38. Csak díj mértékekre."), de a forrás nem ad explicit „fiók-csoport" választ. A repóban a kezelési díjat a `HandlingFeeService` / `HandlingFeeBracket`, a sávokat a `RateDiscount` / `FeeDiscount` fedi, a fiókot a `Branch`. Hogy a díjbeállítás fiók-csoport szinten (nem csak fiók szinten) konfigurálható-e, arra a repo alapján nincs egyértelmű információ.

## 49. Jutalék: kifizetettségről kell info? Hogyan számolódik? Mi lett átadva a könyvelésnek?
**Kérdés:** Jutalék kifizetettségéről kell infó? Hogy számolódik a jutalék? Arról kell info, hogy mi lett átadva már a könyvelésnek?
**Válasz:** Üzleti válasz (kolléga): a **jutalék %-os**. A „kifizetettség" és a „könyvelésnek átadva" igényekre a forrás nem ad teljes igen/nem választ (nyitott pont). A repóban a könyvelésnek való átadást az `BookingExportService` / `BookingExportController` (könyvelési export) fedi le — ez tudja kezelni a „mi lett már átadva" kérdést. A jutalék-kifizetettség külön nyilvántartására (`CommissionCalculation` / `WorkerCommission`) a repo alapján nincs egyértelmű információ.

## 50. Foglalót lehessen kártyával fizetni?
**Kérdés:** Foglalót lehessen kártyával fizetni?
**Válasz:** Üzleti válasz (kolléga): **Nem.** Foglalót csak készpénzzel lehet fizetni (kártyásan deficites lenne). A foglalót a könyvelés nem könyveli (ideiglenes, vissza is megy); a mostani programban a foglaló **nem is megy be a szerverre** és a NAV/bank nem tud róla. (Zsuzsa megkérdezi a könyvelőket, hogy akarnak-e ezzel mégis valamit kezdeni.) A repóban a foglaló a `Reservation`; a „csak készpénz / nincs NAV-/szerver-feladás" üzleti szabály.

## 51. Terror-/szankciós lista játszik a zálognál is?
**Kérdés:** Terror-gyanús emberek listája játszik a zálognál is?
**Válasz:** Üzleti válasz (kolléga): **Igen,** a terror-/szankciós lista a zálogosokat is ugyanúgy érinti; a szankciós listát össze kell kötni a programmal. A repóban a szankciós szűrést a `SanctionEntry` + `SanctionScreeningService` (+ `SanctionScreeningLog`); tiltólista: `ProhibitedPerson` / `ProhibitedCompany` / `BlacklistService` fedi le. Megjegyzés: a Change és a Zálog **két külön cég** (lásd 55. pont), de multi-tenant alapon mindkettő ugyanazt a szankciós szűrést használhatja.

## 52. Keresztváltásnál storno: lehet csak az egyiket? 2-nek vagy 1-nek számít?
**Kérdés:** Keresztváltásnál sztornó: lehet csak az egyiket? 2-nek vagy 1-nek számít?
**Válasz:** Üzleti válasz (kolléga): keresztárfolyamon **nem** számolnak (pl. dollárról euróra közvetlenül nem); **konverziós vétel + konverziós eladás** van (ekkor a kezelési költséget elengedik). Ha 5000 Ft-nál többet kellene visszaadni, akkor már **sima vétel/eladás**. A **konverziós vétel + konverziós eladás = 2 storno** (azaz a keresztváltás stornója két stornónak számít). A repóban a konverziót a `TransactionConversionService`, a stornót a `StornoService` / `StornoApproval` fedi; a „2 stornó" szabály a konverzió kétbizonylatos természetéből adódik (lásd 27. pont).

## 53. Logolás: meddig kell tárolni? Törölhető vagy felülírható?
**Kérdés:** Logolás — mennyi ideig kell tárolni? A figyelmeztetés után mindet törölheti a rendszer, vagy felülírja?
**Válasz:** Üzleti válasz (kolléga): **minimum 1 évig.** Bizonyos pénztáraknál legyen kérhető, hogy az 1 évnél régebbi **ne legyen törölhető** (bírósági ügynél kevés lehet az 1 év). A repóban a log/audit-ot az `AuditLog` entitás fedi, és a repo szabálya szerint az `audit_log` **immutable** (UPDATE/DELETE tiltott triggerrel) — tehát a „ne legyen törölhető" elvárás architekturálisan érvényesül. A min. 1 éves megőrzés AML-/jogi követelmény.

## 54. Központi adatleadást ők csinálják, vagy külön Zálog / külön Valuta?
**Kérdés:** Központi dolgok leadását ők csinálják-e, vagy külön Zálog / külön Valuta?
**Válasz:** Üzleti válasz (kolléga): **külön** csinálják, mert **két külön cég** (hiába egy a tulajdonosi kör). Banki fixing-leadás (Helga), ügyfél-importok (Zsuzsa); külön Change- és külön Zálog-jelszóval töltik fel. A repóban ezt a multi-tenant modell támogatja: `Company` entitás + `companyId` szűrés mindenhol — a két cég adatai elkülönülnek.

## 55. Munkavállaló-nyilvántartás — megegyezzen a záloggal?
**Kérdés:** Munkavállaló nincs a mostani Delphi-s rendszerben. Megegyezőnek kéne lennie a záloggal?
**Válasz:** Üzleti válasz (kolléga): **Záloggal nem mosható össze.** A „dolgozók karbantartása" alatt veszik fel a szerveren. Fontos a **területi egység megnevezése** a valutában (a zálognál nem kell). A repóban a felhasználó/dolgozó a `User` entitás (+ `UserController`); a területi egység a `Branch`-hez kötődik. A cégenkénti elkülönítést a `companyId` biztosítja.

## 56. Bejelentés visszavonható feladás előtt/után?
**Kérdés:** Bejelentést még feladás előtt / esetleg után visszavonhatja-e bárki?
**Válasz:** Üzleti válasz (kolléga): **feladás (nyomtatás) előtt igen** — ki lehet lépni a bejelentésből, ezzel törölve azt; legyen a végén egy „valóban elküldi?" gomb. A **beküldés után nem módosítható.** A központból nem akar ránézni senki (ahogy beérkezik Zsuzsáékhoz, ők nézik/finomítják); visszatartási joguk nincs. A repóban a bejelentés-domaint a `PoliceRequest` / `AnonymousReport` fedi; a „beküldés előtt törölhető, utána zárolt" életciklus üzleti elvárás (lásd 30. pont).

## 57. Tiltólista automatikus letöltése — „közzététel" előtt rá kell néznie valakinek?
**Kérdés:** Ha a tiltólistát automatán tölti le a rendszer és dolgozza be, a „közzététel" előtt rá kell néznie valakinek?
**Válasz:** Üzleti válasz (kolléga): **elméletileg nem** — a beolvasást időnként teszteli (egy ismert listás névvel próbatranzakció, és ha kidobja, hogy szankciós listán van, akkor működik). A kapott linkekkel a szervernek **folyamatosan kommunikálnia** kellene: ha új elem van, befogadja; ha lekerült a listáról, törölje. A repóban a szankciós lista automatizmusát a `SanctionEntry` + `SanctionScreeningService` + `BlacklistService` fedi le; az automatikus letöltés/frissítés üzleti elvárás (manuális jóváhagyás nélkül).

## 58. Plombaszám formátuma? Vonalkód-olvasóval?
**Kérdés:** Plombaszám formátuma? Vonalkód-olvasóval?
**Válasz:** Üzleti válasz (kolléga): **Vonalkód szállításnál nem opció** (nem működőképes). A pénzszállító zsákokat rendelik, azoknak száma van (nem ők adják); a kötegeket nem lehet vonalkódozni. A formátum/hossz **változó** (betű+szám kombináció, zsák-függő); **10 karakterig bármi** megadható legyen. A repóban a szállítás/banki mozgás a `Transfer` / `VaultBankTransaction` domainhez tartozik; a plombaszám szabad szöveges, max 10 karakter, kézi bevitel (nem vonalkód) — ez az üzleti elvárás (kódszintű hossz-konstansra nincs külön bizonyíték).

## 59. Kedvezmény lehet a POS-tranzakciós díj elengedése is?
**Kérdés:** Kedvezmény lehet pl. a POS-tranzakciós díj elengedése is?
**Válasz:** Üzleti válasz (kolléga): a kezelési rész **akár teljesen elengedhető** (kp vagy bankkártya esetén is). POS-terminál tranzakciós díjat **nem hárítanak át**; POS csak a multis helyeken van; bankkártyás fizetés +1 Ft-ot ró rájuk. A repóban a kezelési díj/kedvezmény a `HandlingFeeService` / `HandlingFeeBracket` + `RateDiscount` / `FeeDiscount` domainhez tartozik; a teljes elengedés engedélyhez kötött (lásd 64. pont).

## 60. Tárgynapi fixinges üzletkötések — banki fixing
**Kérdés:** Tárgynapi fixinges üzletkötések? Banki átadandóba banki fixing?
**Válasz:** Üzleti válasz (kolléga): kisebb mennyiségű valutáknál (pl. román lej) **kifixingelik a banknál** (jó árfolyamot kapnak rá); Helga megnézi a készleteket az értéktárakban, és **11 óráig** kell leadni a bank honlapján (összegek felvitele). **Itt nem kell küldeni** (NAV-ra). A repóban a fixing-domaint a `FixingOrder` / `BankOrder` / `BankOrderService` (+ `RaiffeisenRateService`) fedi le.

## 61. Banki árfolyam 2 tizedesre + összeg + forint — kerekítés miatt lehet-e eltérés?
**Kérdés:** Bankba az árfolyamot 2 tizedesre + valuta-összeget + forintot adnak. Az árfolyam-kerekítés miatt nem lehet-e eltérés az ügyletben lévő Forint és az átadottban számolható Forint közt?
**Válasz:** Üzleti válasz (kolléga): a **bank adja az árfolyamot** (kötés vagy fixing); **nem lehet eltérés** a bevitt/kihozott forintban a bank és a cég között. Sima kötésben nincs tizedes; a fixing tárgynapon esetleg lehet tizedes; **amit forintra beírnak, nem térhet el.** A repóban a HUF-kerekítés (`HungarianRounding`, 5 Ft) a saját pénztári oldalon érvényes; a bank felé adott forintnak egyeznie kell — ez üzleti egyezőségi követelmény.

## 62. Napi tranzakciós riport bank felé — csak a teljes azonosítottak mennek?
**Kérdés:** Napi tranzakciós riportban (bank felé) csak a teljes azonosítottak mennek. Igaz ez?
**Válasz:** Üzleti válasz (kolléga): **Igen** — csak a **300 ezer Ft feletti** tételeket kell jelenteni a napi tranzakciós riportban. **Jogi személyeket 5 Ft-tól** azonosítják (csak hitelesített cégkivonattal). A repóban az AML-küszöböket az `AmlThresholdService` / `AmlService` kezeli; a CLAUDE.md rögzíti: **100k (SIMPLIFIED) / 300k (FULL)** azonosítási küszöbök. A bank felé menő riport a 300k feletti (teljes azonosítású) tételeket tartalmazza.

## 63. Fiókok nyitvatartási rendje kezelve van a rendszerben?
**Kérdés:** Fiókok nyitvatartási rendje van valahol/valahogyan kezelve a rendszerben?
**Válasz:** Üzleti válasz (kolléga): a szerveren csak annyi van, hogy a pénztár hétvégén nyitva van-e, illetve beállítható, ha egy pénztár valamiért zárva volt (így a program nem keresi a zárását). **Tól-ig (nyitvatartási intervallum) nincs** a rendszerben (mert nem tudják tervezni). Max. **1 évig** lehet szüneteltetni egy irodát; újranyitást is le kell jelenteni. A repóban a nyitvatartást a `BranchStatus` + `ShiftedCalendarDay` + `DailySession` (a repóban nincs külön `BranchStatus` entitás) fedi le — tehát az új ERP-ben a nyitvatartás-kezelés strukturáltabb lehet, mint a régiben.

## 64. Fiók bezárást tudják-e a rendszeren belül?
**Kérdés:** Fiók bezárást tudják-e a rendszeren belül? Van-e valami most erre a központi rendszerben?
**Válasz:** Lásd 63. pont: a szünetelés/lezárás lejelentése a szerveren a zárás-kereséshez kötődik; max. 1 év szüneteltetés. Önálló „fiók véglegesen bezárva" életciklus-mezőre a forrás nem ad explicit választ. A repóban a fiók a `Branch`; a fiók-állapot (aktív/szüneteltetett/zárt) kezelésére a `Branch` + `BranchStatus` adhat alapot, de a teljes bezárás-folyamatra a repo alapján nincs egyértelmű információ.

## 65. Adható díjkedvezmények karbantartása — milyen felületen?
**Kérdés:** Adható díjkedvezmények karbantartása milyen felületen történik (pl. bevezetésre kerül egy 33%-os, kártyára adható)? Hol van pontosan a rendszerben?
**Válasz:** Üzleti válasz (kolléga): a régi programban a kezelés „be van égetve" (felezés, törlés, egyedi kktg-kedvezmény). A kezelési kedvezmények **supervisori jelszóval**: felezés – főértéktári/értéktári engedély; kártyás eltörlés; specifikus – bármilyen összeg beírható. A tranzakción belül a **kezelési ktg módosításokban**, supervisori jelszó megadásával választható. A repóban a díjkedvezményt a `RateDiscount` / `FeeDiscount` + `HandlingFeeService` / `HandlingFeeBracket` (+ `DiscountApprovalController`) fedi, az engedély a `SupervisorService` / `SupervisorPinService`. Az új ERP-ben a kedvezmények nem „beégetve", hanem karbantartható törzsadatként kezelhetők.

## 66. Megjelenített készlet-adat frissítése — most nincs, de kellene?
**Kérdés:** Megjelenített készlet-adat frissítése: most nincs, de kellene?
**Válasz:** Üzleti válasz (kolléga): van pillanatnyi készlet és forgalom a főértéktárnál és értéktáraknál, valamint pénztár pillanatnyi állása. A **tárgynapi folyamatos címletváltozás nem szükséges**; csak az **előző napi címletek** láthatók, az esti záráskori címletek bejönnek — ez bőven elegendő. A repóban a készletet a `Denomination` / `DenominationCount` + `CashBalance` / `DailyBalance` + `CashBalance` / `InventoryMovement` adja; a real-time címlet-frissítés nem követelmény.

## 67. Bizonylat utólagos NAV-feladás van a rendszerben?
**Kérdés:** Bizonylat utólagos NAV-feladás van a rendszerben?
**Válasz:** Üzleti válasz (kolléga): **Nincs,** másképp van megoldva. Ha a NAV-hoz nem megy be a nyugta (megszakítva): ha csak internethiba van, **visszastornózzák** és a pénztáros újra csinálja a tételt; ha a NAV-gép elromlik, addig **kézi nyugtát** állítanak ki (+ valutás bizonylat), majd a hiba elhárulása után, új adóügyi napon, zárást követően összeadják a tételek kezelési költségeit, és csinálnak egy vételt, ahol a kezelési költséget az adott összegre állítják. A repóban a NAV-kommunikáció a `NavIntegrationService` / `NavClosing`; az „utólagos feladás helyett storno+újrafelvétel / kézi nyugta" üzleti eljárás.

## 68. Exceles alaptőke-oszlop honnan veszi az adatot?
**Kérdés:** Van egy exceles lista, amiben szerepel egy alaptőke-oszlop (0028: Expressz Ékszerház és Minibank Kft forgalom). Honnan veszi?
**Válasz:** Üzleti válasz (kolléga): az alaptőkét **Kósa Zoltán és a főértéktár határozza meg** a területeken (változtatható). Minden területnek van alaptőkéje, azzal indul minden hónap elsején (nyáron magasabb, télen alacsonyabb). Ezt **nem rögzítik a rendszerbe, csak az excelbe** írják. A repo alapján tehát ez az adat jelenleg rendszeren kívüli (Excel); az új ERP-ben az `CashBalance` / `DailyBalance` / `Branch` szintű alaptőke-mező lehetne a leképezés, de erről a repo alapján nincs konkrét megerősítés.

## 69. Közszereplő-kezelés: csak azonosításkor jön elő — ez így jó?
**Kérdés:** A közszereplő kérdés magánszemélynél csak akkor jön elő, ha valahogy azonosítani kell. Ez így jó? Egy közszereplőt 80 ezerért váltáskor nem kell „inzultálni"?
**Válasz:** Üzleti válasz (kolléga): **Igen, jó.** Kivéve, ha **ismert emberről** van szó (pl. közismert politikus) — akkor automatikusan, **5 Ft-tól is** előjön a közszereplői nyilatkoztatás. Ha nem ismert és nem jelzi az azonosítási összeghatár alatt, hogy közszereplő, akkor nem azonosítják/engedélyeztetik. A repóban a közszereplő/PEP-kezelést a a `Transaction` PEP-mezői (V235 migráció) fedi; a küszöb-logika az AML-szolgáltatásokhoz (`AmlService` / `AmlThresholdService`) kötődik.

## 70. Meghatalmazással 120 ezer Ft váltás — teljes azonosítás kell?
**Kérdés:** Meghatalmazással jön egy ügyfél 120 ezer Ft váltásra: teljes azonosítás kell?
**Válasz:** Üzleti válasz (kolléga): teljes azonosítás csak **300 ezer Ft felett** (illetve jogi személynél stb. 5 Ft-tól). **DE** ha az azonosítási összeghatár alatt ragaszkodik a **meghatalmazáshoz** és annak feltüntetéséhez, akkor **teljes azonosítás és „más nevében végzett tranzakció" könyvelése** szükséges. A repóban: AML-küszöbök 100k/300k (`AmlThresholdService`), ügyfél `Customer`; a meghatalmazás → teljes azonosítás kiváltó eseménye üzleti szabály.

## 71. Árfolyam-kedvezmény több valutanem esetén
**Kérdés:** Árfolyam-kedvezmény több valutanem esetén?
**Válasz:** Üzleti válasz (kolléga): **Működik most is, adható** — annyi, amennyi **1 bizonylatra rögzíthető**. A repóban a több devizás tétel/kedvezmény az `Transaction` + `RateWorkgroup` / `RateDiscount` / `RateDiscount` / `FeeDiscount` kombinációján modellezett (lásd 43. pont).

## 72. Átlagárfolyam-lista: pontosan hogyan kell számolni?
**Kérdés:** Átlag árfolyam lista: pontosan hogyan kell számolni?
**Válasz:** Üzleti válasz (kolléga): a főértéktárnak van erre egy programja, amely egy **adott időszak vételi/eladási árfolyamából** számol átlagárfolyamot. A repóban ezt az `AverageRateReportService` (+ `AverageRateReportController`) fedi le. A pontos képletre (súlyozás, időszak-definíció) a repo nem ad teljes részletet — az üzleti definíció a fenti (lásd 4. pont).

## 73. Pénzfogadás értéktárból a NAV felé — árfolyam helyett 1 megy, jó ez?
**Kérdés:** Pénz fogadásnál értéktárból a NAV felé (`...|RA|08|U...|CY21|80000|1|CY00|95000|1`): az árfolyam helyett 1 megy, az összegek devizában. Jó ez így?
**Válasz:** Üzleti válasz (kolléga): **Jó.** Ez **csak a valutakészletet érinti** (pénztárak/értéktár közti mozgás), ezért megy árfolyam helyett `1`, és az összegek devizában. A repóban a NAV-payload a `NavIntegrationService` / `NavClosing`; a készlet-mozgás NAV-formátuma (árfolyam=1) a FISCAT-protokoll része (lásd a Prior-blokk, 53–54. pont).

## 74. Küldésnél a `11`-es ok kód nincs a leírásban
**Kérdés:** Küldésnél (`...|PO|11|F...|CY06|50|1`) a `11`-es ok nincs a leírásban — mi ez?
**Válasz:** A repo alapján erre nincs egyértelmű információ — ez a NAV/FISCAT pénztárgép-protokoll belső kódja, amely a **Prior Kft.-nek feltett külön kérdés** tárgya (a NAV-pénztárgép dokumentáció hiányossága). A `NavIntegrationService` / `NavReportService` / `NavClosing` domain a küldést kezeli, de a `11`-es ok-kód jelentése a beszállítói protokoll-dokumentációból derülhet ki, nem a repóból.

## 75. Kiemelt közszereplőnél az engedélyezőt kéri, de anélkül is továbbmegy — jó ez?
**Kérdés:** Kiemelt közszereplőnél az engedélyezőt kéri be, de anélkül is továbbmegy. Ez így jó?
**Válasz:** Üzleti válasz (kolléga): **Elméletileg nem** mehet tovább engedélyező és a többi szükséges adat (pl. pénzeszköz-forrás) kitöltése nélkül. Ez tehát a régi rendszer hibája, amit az új ERP-ben javítani kell: PEP/kiemelt közszereplő esetén az engedélyező + forrás-adatok kötelezőek. A repóban a PEP-domaint a a `Transaction` PEP-mezői, az engedélyezőt a `SupervisorService` / `SupervisorPinService` fedi; a kötelező-mező kikényszerítés üzleti elvárás.

## 76. POS-zárásnál kellenek a zárási infók a POS-ból?
**Kérdés:** POS-zárásnál kellenek a zárási infók a POS-ból?
**Válasz:** Üzleti válasz (kolléga): **NEM.** A valutás programban is külön könyvelődik, külön szedik le. A repóban a POS/bankkártyás ág elkülönítve kezelt (lásd 37. pont — „POS átvétel banktól" technikai pénztár); a POS-zárási adatok nem szükségesek a valutás záráshoz.

## 77. Kiadott bizonylatok listája: a storno-bizonylat is kell? Hivatkozással?
**Kérdés:** Kiadott bizonylatok listája: a sztornó bizonylat is kell? Kell a sztornózottra való hivatkozás?
**Válasz:** Üzleti válasz (kolléga): **Kell, és benne is van** a listázásban (a stornózottra való hivatkozással együtt). A repóban a stornót a `StornoService` / `StornoApproval` fedi, amely az eredeti tranzakcióra hivatkozik; a bizonylat-listázás tartalmazza a storno-tételeket is.

## 78. Kiadott bizonylatok listája: pénztári átadás/átvételnél a forrás/cél pénztár?
**Kérdés:** Kiadott bizonylatok listája: pénztári átadások/átvételek esetén a forrás/cél pénztár nem kéne rá?
**Válasz:** A kolléga visszakérdezett: **„Itt melyik listára gondoltok? Pénztárban, értéktárban, vagy szerveren listázhatóra?"** — azaz tisztázást kért. A repóban az átadás-átvételt a `Transfer` fedi (forrás/cél pénztárral); a több listázási kontextus (pénztár/értéktár/szerver) különböző nézet. A pontos elvárás a lista-szint pontosítása után rögzíthető — a repo alapján a forrás/cél pénztár adat rendelkezésre áll a `Transfer` entitásban.

## 79. Foglalót cég is köthet?
**Kérdés:** Foglalót cég is köthet?
**Válasz:** Üzleti válasz (kolléga): **Igen.** A repóban a foglaló a `Reservation`, az ügyfél a `Customer` (amely jogi személyt is reprezentálhat); a céges foglaló támogatott.

## 80. TEÁOR-kód karbantartás van most?
**Kérdés:** TEÁOR kód karbantartás van most?
**Válasz:** Üzleti válasz (kolléga): a TEÁOR-listát a **banktól kapták**, ezt építették be a programba. A repóban a TEÁOR-kódot a `TeaorCode` entitás (+ `TeaorController`) fedi le — tehát az új ERP-ben karbantartható törzsadat.

## 81. Körlevél iktatószám hogyan épül fel?
**Kérdés:** Körlevél iktatószám hogy épül fel? (Pl. FZS-1/2024.)
**Válasz:** Üzleti válasz (kolléga): a **betű** a körlevelet író monogramja, a **szám** a tárgyévben írt körlevelek sorszáma, majd a **dátum** (év). Minden évben **1-es sorszámmal** indul. A repo alapján körlevél-/iktatószám domaint nem azonosítottam a backend-entitások között — erre a repo alapján nincs egyértelmű információ (a szabály a forrás-dokumentum üzleti definíciója).

## 82. Adható díjkedvezmények karbantartása pontosan hol van? Nem találják
**Kérdés:** Adható díjkedvezmények karbantartása pontosan hol van a rendszerben? Nem találjuk.
**Válasz:** Üzleti válasz (kolléga): a tranzakción belül, a **kezelési ktg módosításokban**, supervisori jelszó megadásával választható (márciusban megmutatták, lefotózták). A repóban a díjkedvezmény a `RateDiscount` / `FeeDiscount` / `HandlingFeeService` / `HandlingFeeBracket` (lásd 65. pont), az engedély a `SupervisorService` / `SupervisorPinService`. Ez ugyanaz, mint a 65. kérdés — a karbantartás a tranzakció kezelési-díj részében, supervisori jelszóval.

## 83. Tiltólista-kezelés van, vagy csak körlevélben megy?
**Kérdés:** Tiltólista kezelés van? Vagy csak körlevélben megy?
**Válasz:** Üzleti válasz (kolléga): **Nem csak körlevél.** A programban beállítható; ha a pénztáros tiltott ügyfelet választ, **nem végezhet neki tranzakciót** (a program jelzi és kilépteti a tételből). Ha az ügyfél **forrásigazolással** válthat, azt is jelzi a program, és **supervisori jelszóval** engedi a tételt. A repóban ezt a `SanctionEntry` + `SanctionScreeningService` + `BlacklistService` (+ `SupervisorService`) fedi le — a tiltólista-szűrés és a supervisori felülbírálás domain szinten támogatott.

## 84. Archiválás van a rendszerben?
**Kérdés:** Archiválás van a rendszerben?
**Válasz:** Üzleti válasz (kolléga): **Van.** Az év eleji frissítő végzi, de külön programmal is futtatható (a Valuta-BIN mappában). A repóban az archiválást az `ArchivingController` / `ArchivingService` (archiválás-domain) fedi le — tehát az új ERP-ben is van archiválási funkció.

## 85. Nyitásnál a POS-interfész lekérdezés benne van a pénztáros nyitó rutinjában?
**Kérdés:** Nyitásnál a POS interfész lekérdezés benne van-e a pénztáros nyitó rutinjában, és ha igen, hogyan?
**Válasz:** Üzleti válasz (kolléga): **Igen** — programba írva, illetve az „egyéb beállítások" menüben **„kézzel" is nyitható/zárható** a bankkártyás terminál. A repóban a pénztár-nyitást a `DailySession` kezeli; a POS-terminál interfész a nyitó rutin része, kézi felülbírálási lehetőséggel.

## 86. Havi forgalom-jelentés körzetre szűrve: trend számítása?
**Kérdés:** Havi forgalom jelentés körzetre szűrve: trend számítása? (Vétel és eladás oszlop %-ban — hogy jön ki?)
**Válasz:** A repo alapján erre nincs egyértelmű, képletszintű információ (a forrás-dokumentum sem ad rá választ). A forgalom-/riport-adatok a tranzakciós entitásokból (`Transaction` stb.) és a `Branch`/körzet-bontásból állíthatók elő; a „trend %" konkrét képlete a repóban nincs dokumentálva.

## 87. Foglaló-bizonylat
**Kérdés:** Foglaló bizonylat (igény/kérdés a foglaló-bizonylatra).
**Válasz:** A forrás-dokumentumban ez címszó-szintű (külön szöveges válasz nélkül). A repóban a foglaló a `Reservation` (+ `ReservationController` / `ReservationService`), amelyhez bizonylat tartozik; a foglaló-bizonylat a foglaló-domain része. Egyéb (kp-fizetés, nincs NAV/szerver-feladás) lásd 50. pont. Részletes bizonylat-formátumra a repo alapján nincs külön egyértelmű információ.

## 88. Árfolyam: a 0-s lap elszámoló oszlop — csak a fő valuták állíthatók kézzel?
**Kérdés:** (Tamáshoz) A 0-s árfolyam lap, elszámoló árfolyamok oszlop, fő valuták: csak ezek állíthatók kézzel és a többi nem, vagy minden valuta kézzel állítható, és csak a 4 fő van állítva?
**Válasz:** Üzleti válasz (kolléga/Tamás): **minden valutánál kézzel állítható** az elszámoló árfolyam, de a gyakorlatban **csak a fővalutákat** állítják, mert a többi **képlettel** van számolva. A repóban az elszámoló/árfolyam az `ExchangeRate` (+ `RateWorkgroup` / `RateDiscount`); az árfolyamkészítés az `arfolyam-keszito-client` / `kozponti-client` (árfolyamkészítő mód) feladata. A „fő valuta kézi, többi képlet" logika árfolyamkészítő-oldali szabály.

## 89. Új valutanem felvétele lehetséges? Szükséges?
**Kérdés:** Valutanemek oszlop: új valutanem felvétele lehetséges? Szükséges?
**Válasz:** Üzleti válasz (kolléga/Tamás): jelenleg csak **programmódosítással** lehet. A legjobb az lenne, ha **lehetne új valutát felvenni és meglévőt megszüntetni**, vagy legyen **supervisori jelszóhoz** kötve a módosítás. A repóban a valutanem/árfolyam az `ExchangeRate` domainhez tartozik; az új ERP-ben a valutanem karbantartható törzsadatként, supervisori engedéllyel kezelhető (üzleti elvárás). Konkrét „valuta-CRUD UI" jelenlétére a repo alapján nincs külön egyértelmű bizonyíték.

## 90. Saját hatáskörű vétel-eladás (R és S oszlop) képzése?
**Kérdés:** Saját hatáskörű vétel-eladás (R és S oszlop): ennek a képzése?
**Válasz:** Üzleti válasz (kolléga/Tamás): az előttük lévő oszlopokhoz hasonlóan **képletezve** van; az előző értékhez hozzáadják a kedvezmény mértékét (pl. EUR „R" oszlop képlete: **P + 0,25**). A repóban a kedvezmény-sávokat az `RateWorkgroup` / `RateDiscount` / `RateDiscount` / `FeeDiscount` fedi; az oszlop-képletek az árfolyamkészítő logika részei (árfolyamkészítő kliens).

## 91. Új oszlop beszúrása lehetséges? Szükséges?
**Kérdés:** Új oszlop beszúrás lehetséges? Szükséges?
**Válasz:** Üzleti válasz (kolléga/Tamás): **Nem szükséges.** A meglévő oszlopok elegendők:
- „J" – Elszámoló árf.
- „K" – Valuta rövidített elnevezés
- „L" – Alap vételi árf.
- „M" – Alap eladási árf.
- „N–P–R" – Vételi kedvezmény-sávok
- „O–Q–S" – Eladási kedvezmény-sávok

A repóban ezeket az `ExchangeRate` (alap vételi/eladási, elszámoló) + `RateWorkgroup` / `RateDiscount` (vételi/eladási kedvezmény-sávok) modellezik; új oszlop bevezetése nem cél.

## 92. (Prior Kft. — NAV-pénztárgép) A küldött dokumentum teljes-e a kábeles kapcsolatra tekintettel?
**Kérdés:** Tudtunkkal sem az Exclusive Best Change Zrt-nél, sem az Express Ékszerház Zrt-nél már nem QR-kóddal kommunikálnak a pénztárgéppel, hanem kábeles kapcsolat van. Ennek fényében a küldött dokumentum teljes?
**Válasz:** Ez a **NAV-pénztárgép beszállítónak (Prior Kft.) feltett külső kérdés** — a repo nem tartalmazza a beszállítói protokoll-dokumentációt, így a teljességére a repo alapján nincs információ. A repo oldali NAV-integrációt a `NavIntegrationService` / `NavReportService` / `NavClosing` domain fedi; a fizikai kapcsolat (QR vs. kábel) a beszállítói/eszköz-szint kérdése.

## 93. (Prior Kft.) Tranzakciók válasz- és hibaüzeneteire vonatkozó információk
**Kérdés:** Szeretnénk kérni a tranzakciók válasz-üzeneteire, hiba-üzeneteire vonatkozó információkat.
**Válasz:** Ez szintén a **Prior Kft.-nek** szóló kérés a NAV-pénztárgép protokollról; a repo nem tartalmazza ezeket a beszállítói válasz-/hibakód-leírásokat. Repo-oldalon a saját belső hibakód-rendszer él (`packages/shared-logging/error-codes.yaml`, `VV-<KAT>-<3jegy>` kódok), de a NAV-gép protokoll-üzenetei külső dokumentációból származnak — a repo alapján erre nincs információ.

## 94. (Prior Kft.) Napzárás (DC) paraméterei: daily dept / PLU / Exchange Report / X before Z?
**Kérdés:** A napzárás (DC) paramétereit nem értjük: daily dept before Z? daily PLU before Z? daily Exchange Report before Z? daily X before Z?
**Válasz:** Ezek a **NAV-pénztárgép (FISCAT/Prior) napzárási parancs-paraméterei** — a beszállítói protokoll fogalmai (Z = napi zárás, X = közbenső jelentés, PLU/dept = a pénztárgép tételcsoport-fogalmai). A repo nem tartalmazza a pénztárgép-beszállító dokumentációját, így ezek pontos jelentésére **a repo alapján nincs információ**; ezt a Prior Kft. válasza adja meg. A repo saját napzárás-fogalmát (pénztár-szesszió zárás) a `DailySession` fedi, ami fogalmilag elkülönül a NAV-pénztárgép DC/Z parancsaitól.

---

### Záró megjegyzés
A fenti válaszok többsége két forrásból építkezik: (1) a forrás-dokumentumban szereplő **kolléga
(Kósa cégcsoport) hiteles üzleti válaszai** (a meglévő/elvárt működésről), és (2) az **új ERP repo
tényei** (mely entitás/controller/service fedi le az adott domaint). Több NAV-pénztárgép-specifikus
kérdés (74., 92–94.) a **beszállító (Prior Kft.)** hatáskörébe tartozik, ezekre a repo érdemben nem
ad választ. Ahol sem a dokumentum, sem a repo nem ad egyértelmű választ, ezt kifejezetten jeleztem.
