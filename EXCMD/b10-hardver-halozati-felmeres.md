# Modul: Hardver- és hálózati felmérés

<system_context>
## Rendszerkontextus és Cél
A telephelyenkénti PC-, periféria- és internet-felmérés dokumentumainak katalogizálása deployment-tervezési referenciaként — **NEM** programfunkció-specifikáció.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Nem alkalmazható | Helyszíni telepítő / üzemeltető (OUT) | n/a (OUT) |

## Hatókör (Scope)
### IN
- A felmért eszközök lista-jellegű katalogizálása (mely fájl mit ír le).
- Kizárólag a deployment-releváns NFR-ek (minimális gépigény, OS, hálózati sebesség) kiemelése TBD-vel.

### OUT
- **Teljes modul OUT** (nem programfunkció). Ezek a klienstelepítés-tervezéshez készült helyszíni felmérések.
- Tilos bármilyen funkcionális követelményt levezetni belőlük.

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-HW-01 | Támogatott OS-tartomány (a felmért gépek vegyesen: Windows 7 Professional/SP1, Windows 10 Home/Pro/Enterprise) | TBD: az Electron-kliensek minimálisan támogatott Windows verziója (a Windows 7 gépek miatt) |
| NFR-HW-02 | Minimális gépigény: a felmért flotta gyengébb gépei (pl. i3-2120, Pentium G3220, 2–4 GB RAM, HDD/SSD vegyes) | TBD: a 3 Electron kliens dokumentált minimális CPU/RAM/tárhely követelménye |
| NFR-NET-01 | Internet-sebesség szélsőértékek: feltöltés 0.81 Mbps (Kecskemét user-PC) – 55.61 Mbps; ping akár 470 ms. Lassú/instabil telephelyek. | TBD: offline-first/sync tolerancia küszöb lassú vonalon (kapcsolat a local-first mandate-hez) |
</system_context>

<functional_spec>
## Funkcionális Követelmények
*Ebből a modulból nem származnak funkcionális követelmények. Minden katalogizált elem a hatókörön kívül esik (Scope: OUT).*
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma
- Nincs hatással az adatmodellre vagy az adatbázis sémára.
- SQLite mirror: Nem szükséges.
- Migráció: Nem szükséges.
</data_structure>

<integration_points>
## Integrációs Pontok és Végpontok
- Nincs alkalmazás-szintű integrációs vagy végponti függőség.
- Külső fizikai eszközök (perifériák) deployment-bemenetei:
  - Címkenyomtatók (pl. ZDesigner GC420t/GK420t)
  - Lapnyomtatók (HP/Brother)
  - Szkennerek (CanoScan)
  - Webkamerák
</integration_points>

<execution_workflow>
## AI Ügynök Végrehajtási Folyamat

### Phase 1 (Preparation)
1. Rögzítsd a scope-OUT státuszt.
2. A felmérési adatok (fájlok és struktúrák) kizárólag deployment-tervezési bemenetként szolgálnak.

### Phase 2 (Backend)
- Nincs backend fejlesztési feladat.

### Phase 3 (Frontend/Client)
- Nincs frontend fejlesztési feladat.

### Phase 4 (Verification)
- Győződj meg róla, hogy a Windows 7 és korlátozott hardver/internet képességű kliensek üzemeltetési korlátai (TBD) egyeztetve lettek.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Mit kell tudni |
|---|---|---|---|
| 1 | Támogatjuk-e a Windows 7 gépeket? | Telepítés tervezése | Több zálog/váltós gép még Windows 7 SP1 operációs rendszert futtat; Electron minimális verziójáról dönteni kell. |
| 2 | Minimális gépigény formalizálása | Flotta alkalmassága | Gyenge gépek (2 GB RAM, HDD) jelenléte miatt hivatalos minimális specifikáció szükséges. |
| 3 | Lassú vonal (0.8 Mbps feltöltés, 470 ms ping) tolerancia | Szinkronizáció megbízhatósága | Kapcsolat a local-first/offline működési követelményekhez. |
| 4 | Békéscsaba .zip tartalma | Esetleges további adatok | Kicsomagolás és feldolgozás csak ha üzletileg/technikailag indokolt. |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva (nincs FR - OUT státusz rögzítve).
- [x] Nincsenek kitalált vagy hallucinált követelmények (a felmérési fájlok és specifikációk alapján).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=0 db, TBD=4 db, érintett csomagok=NINCS (OUT).
</verification_checklist>
