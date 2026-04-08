---
type: session-log
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Anti Valutavalto — Uzleti Logika es Minosegi Elemzes"
load: on-demand
---

# Anti Valutaváltó — Üzleti Logika és Minőségi Elemzés
## S1 ESZTER_CONTROLLER_CHIEF_ELEMZESE

> **Dátum:** 2026-04-02
> **Elemző:** Eszter — QA & Code Review Controller Chief
> **Forrás:** `D:\repo\valutavalto-program\Anti\VALUTA\` + Junior átfogó reverse engineering elemzés
> **Módszer:** Forráskód-alapú üzleti logika feltárás, kockázatelemzés, jogszabályi audit
> **Cél:** A Delphi 7 legacy rendszer üzleti szabályainak, kódminőségének és migrációs kockázatainak mély elemzése

---


---

## S2 TARTALOMJEGYZEK

1. [Pénzügyi üzleti szabályok](#1-pénzügyi-üzleti-szabályok)
2. [AML/KYC szabályok](#2-amlkyc-szabályok)
3. [Bizonylat-rendszer](#3-bizonylat-rendszer)
4. [Napi/havi zárási üzleti folyamatok](#4-napihavi-zárási-üzleti-folyamatok)
5. [Kódminőség és kockázatok](#5-kódminőség-és-kockázatok)
6. [Jogszabályi megfelelőség](#6-jogszabályi-megfelelőség)
7. [Migrációs üzleti szempontok](#7-migrációs-üzleti-szempontok)

---

# 1. PÉNZÜGYI ÜZLETI SZABÁLYOK


---

## S3 11_ARFOLYAM_KEZELES_ARCHITEKTURA

### 1.1.1 Árfolyam-adatmodell

A rendszer az `ARFOLYAM` táblában tárolja a devizanemenkénti árfolyamadatokat. Minden devizanemhez minimum 4 árfolyam tartozik:

```pascal
// VASARLAS/Unit2.pas — GetDnemAdatok függvény (sor 2544)
function TVasarlasForm.GetDnemAdatok(_zdnem: string): byte;
begin
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+_ZdNEM+chr(39);
  // ...
  with ValutaQuery do begin
    _aktdnev    := trim(FieldbyNAme('VALUTANEV').asString);
    _aktvarf    := FieldByNAme('VETELIARFOLYAM').asInteger;    // Vételi árfolyam
    _aktelszarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger; // Elszámolási árf.
    _aktshk     := FieldByName('SHKVETARFOLYAM').asInteger;    // SHK vételi árf.
    _aktZaro    := FieldByNAme('ZARO').asInteger;              // Záró készlet
  end;
end;
```

Az árfolyamtípusok:

| Mező | Név | Használat |
|------|-----|-----------|
| `VETELIARFOLYAM` | Vételi árfolyam | Devizavásárlás (ügyfél devizát ad) |
| `ELADASI` (implicit) | Eladási árfolyam | Devizaeladás (ügyfél devizát kap) |
| `ELSZAMOLASIARFOLYAM` | Elszámolási árfolyam | Belső elszámolás, havi zárás |
| `SHKVETARFOLYAM` | SHK vételi árfolyam | Saját hatáskörű kedvezményes árfolyam |

**Kritikus észrevétel:** A vételi és eladási árfolyam közti spread (marzs) a rendszer fő bevételi forrása. Az árfolyamok **integer** típusúak (fillér pontosság nélkül, 100-zal osztva használva), ami a JPY kezelésnél speciális logikát igényel.

### 1.1.2 Árfolyam kiválasztás — Vásárlás vs. Eladás

A vételi és eladási irány eltérő árfolyamot használ:

**Vásárlás** (VASARLAS DLL — ügyfél devizát hoz, pénztáros forintot fizet):
```pascal
// VASARLAS/Unit2.pas — DnemKeyDown (sor ~490)
_aktArfolyam            := _aktVarf;  // VÉTELI árfolyamot használja
_wArfolyam[_aktsor]     := _aktArfolyam;
_wOrigArfolyam[_aktsor] := _aktarfolyam;
_wElszamolasi[_aktsor]  := _aktElszarf;
```

**Eladás** (ELADAS DLL — ügyfél forintot hoz, devizát kap):
```pascal
// ELADAS/Unit2.pas — DnemKeyDown (sor ~520)
_aktArfolyam            := _aktEarf;  // ELADÁSI árfolyamot használja
_wArfolyam[_aktsor]     := _aktArfolyam;
_wOrigArfolyam[_aktsor] := _aktarfolyam;
_wElszamolasi[_aktsor]  := _aktElszarf;
```

### 1.1.3 Árfolyam-kedvezmény típusok

A rendszer háromszintű árfolyam-kedvezmény rendszert implementál:

**1. Kis árfolyamkedvezmény (KISARFVALT DLL)**
- Pénztáros saját hatáskörben adhatja
- F1 gombbal aktiválható
- A `kisarfolyamkedvezmeny` függvény hívása
- Visszatérési érték: `-1` = mégsem, `2` = SHK (saját hatáskörű) kedvezmény

```pascal
// VASARLAS/Unit2.pas — ArfolyamGombClick (sor ~927)
procedure TVasarlasForm.ArfolyamGombClick(Sender: TObject);
begin
  if _kezdijEngedmenyTip>0 then begin
    ShowMessage('KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !');
    exit;
  end;
  _arfback := kisarfolyamkedvezmeny;
  if _arfback = -1 then exit;
  if _arfback =  2 then _voltshk := True;
  Ujraszamolas;
end;
```

**2. Nagy árfolyamkedvezmény (BIGARFVALT DLL)**
- Értéktáros/supervisor szintű döntés
- Adott valutanem-re vonatkozik (a VTEMP `MEGJEGYZES` mezőbe `!` jelölés)
- Dupla kattintás vagy Enter az árfolyam mezőn

```pascal
// VASARLAS/Unit2.pas — ArfolyamotModosit (sor ~950)
procedure TVasarlasForm.ArfolyamotModosit;
begin
  if _sorEngedmeny[_aktSor]>0 then begin
    ShowMessage('Ez már módositott árfolyam !');
    exit;
  end;
  if _kezdijEngedmenyTip>0 then begin
    ShowMessage('KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !');
    exit;
  end;
  // Jelölés VTEMP-ben
  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'!'+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
  ValutaParancs(_pcs);
  // DLL hívás
  _arfback := bigarfolyamkedvezmeny;
  if _arfBack=-1 then exit;
  _voltkedvezmeny := True;
  Ujraszamolas;
end;
```

**3. Saját hatáskörű (SHK) kedvezmény**
- A pénztáros saját hatáskörben napi szinten korlátozott számú kedvezményt adhat
- `GetSajatHataskoru` lekérdezi a még rendelkezésre álló lehetőségek számát
- 5-ből visszafelé számol: `_mShk := 5 - _shk`

```pascal
// VASARLAS/Unit2.pas — FormActivate (sor ~418)
_shk  := GetSajatHataskoru;
_mShk := 5-_shk;
ShkPanel.Caption := inttostr(_mshk);
```

**Üzleti szabály — KIZÁRÓ LOGIKA:**
> Árfolyamkedvezmény ÉS kezelési díj kedvezmény egyszerre NEM adható. Ha már van kezelési díj engedmény (`_kezdijEngedmenyTip > 0`), az árfolyamkedvezmény gombok letiltásra kerülnek.

### 1.1.4 Árfolyam korlátozások devizanemenként

A rendszer devizanem-specifikus korlátozásokat tartalmaz:

```pascal
// VASARLAS — HUF nem vásárolható:
if _aktDnem='HUF' then begin
  ShowMessage('A FORINT NEM VÁLASZTHATÓ VALUTA');
  exit;
end;

// ELADAS — HUF nem eladható:
if _aktDnem='HUF' then begin
  ShowMessage('A FORINT NEM VÁLASZTHATÓ VALUTA');
  exit;
end;

// ELADAS — HRK (horvát kuna) nem eladható:
if _aktDnem='HRK' then begin
  ShowMessage('A KÚNA NEM VÁLASZTHATÓ VALUTA');
  exit;
end;

// ELADAS — Euro érme nem eladható:
if _aktDnem='EUA' then begin
  ShowMessage('EURO ÉRMÉT NEM ADUNK EL');
  exit;
end;

// ELADAS — Konverziónál azonos devizanem nem választható:
if (_ezkonverzio) AND (_aktdnem=_vetdnem) then begin
  Showmessage('AZONOS VALUTANEM NEM KONVERTÁLHATÓ !');
  exit;
end;
```

**Szankciós korlátozás — USD külföldi számára:**
```pascal
// BIGCTRL/Unit2.pas — UsdAdhato (sor 1315)
function TForm2.UsdAdhato: boolean;
begin
  result := true;
  // ... VTEMP-ből ellenőrzi van-e USD tétel ...
  if _recno=0 then exit;
  if (_iso<>'IR') and (_iso<>'KR') and (_iso<>'CU') and
     (_iso<>'SY') and (_iso<>'SS') then exit;
  showmessage('EBBEN AZ ORSZÁGBAN DOLLÁR NEM VÁLTHATÓ');
  result := False;
end;
```

Tiltott országok USD eladásnál: **IR** (Irán), **KR** (Észak-Korea), **CU** (Kuba), **SY** (Szíria), **SS** (Dél-Szudán).

---


---

## S4 12_FORINT_ERTEKSZAMITAS_ES_KEREKITES

### 1.2.1 Forintérték kalkuláció

Az egyes sorok forintértékének kiszámítása a devizanemtől függően:

```pascal
// VASARLAS/Unit2.pas — BankjegyKeyDown (sor ~600)
// Általános formula:
_aktErtek := round((_aktArfolyam/100*_aktBankjegy)+_rounder);

// JPY speciális kezelés (100-as egység):
if _aktDnem='JPY' then _aktertek := round(_aktertek/10);
```

**Matematikai modell:**
- **Általános:** `forintérték = round(árfolyam / 100 × bankjegy + 0.001)`
- **JPY:** `forintérték = round(round(árfolyam / 100 × bankjegy + 0.001) / 10)`

A `_rounder` változó (`0.001`) a kerekítési tűrés — megakadályozza a „banker's rounding" problémát, mindig felfelé kerekít `0.5`-nél.

### 1.2.2 Az 5 forintos kerekítés — Kerekito függvény

A magyar pénzforgalomban az 5 Ft-os kerekítés törvényi kötelezettség. A rendszer ezt implementálja:

```pascal
// VASARLAS/Unit2.pas (sor 2842)
function TVasarlasForm.kerekito(_int: integer): integer;
var _nums: string;
    _utdig,_wnums: Byte;
begin
  result := _int;
  _nums := inttostr(_int);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;    // utolsó számjegy
  if (_utdig<>0) and (_utdig<>5) then begin
    if (_utdig=1) or (_utdig=2) then result := _int-_utdig;     // lefelé 0-ra
    if (_utdig=6) or (_utdig=7) then result := _int-(_utdig-5);  // lefelé 5-re
    if (_utdig=3) or (_utdig=4) then result := _int+(5-_utdig);  // felfelé 5-re
    if (_utdig=8) or (_utdig=9) then result := _int+10-_utdig;   // felfelé 0-ra
  end;
end;
```

**Kerekítési táblázat:**

| Utolsó jegy | Irány | Eredmény | Példa |
|-------------|-------|----------|-------|
| 0 | — | Változatlan | 1230 → 1230 |
| 1 | ↓ | -1 → 0-ra | 1231 → 1230 |
| 2 | ↓ | -2 → 0-ra | 1232 → 1230 |
| 3 | ↑ | +2 → 5-re | 1233 → 1235 |
| 4 | ↑ | +1 → 5-re | 1234 → 1235 |
| 5 | — | Változatlan | 1235 → 1235 |
| 6 | ↓ | -1 → 5-re | 1236 → 1235 |
| 7 | ↓ | -2 → 5-re | 1237 → 1235 |
| 8 | ↑ | +2 → 0-ra | 1238 → 1240 |
| 9 | ↑ | +1 → 0-ra | 1239 → 1240 |

**Kritikus elemzés:**
- A kerekítés string-alapú (integer → string → utolsó karakter), ami nem hatékony, de hibamentes
- A kerekítés MINDIG az 5-ös és 0-ás jegyekhez konvergál, ami megfelel a 2008. évi LXVIII. tv. módosítása szerinti szabálynak
- Negatív számoknál HIBÁS lehet: ha `_int` negatív, az `inttostr` előjelet ír, és az utolsó karakter nem feltétlenül a szám utolsó jegye → **migrációs kockázat**

### 1.2.3 Fizetendő összeg kalkuláció

A teljes fizetendő összeg a nettó, kezelési díj és kerekítés eredménye:

```pascal
// VASARLAS/Unit2.pas — FizetendoDisplay (sor ~960)
procedure TVasarlasform.FizetendoDisplay;
begin
  _netto := 0;
  // Nettó összegzés:
  _z := 1;
  while _z<=_tetel do begin
    _netto := _netto + _wErtek[_z];
    inc(_z);
  end;

  // Kezelési díj kiszámítása:
  _origkezdij := Getkezelesidij(_netto);
  if _fixKezelesiDij=-1 then _kezelesidij := _origkezdij
  else _kezelesidij := _fixkezelesidij;
  if _kezelesidij<0 then _kezelesidij := 0;

  // VÁSÁRLÁSNÁL: bruttó = nettó - kezelési díj (levonás!)
  _brutto    := _netto - _kezelesiDij;
  _fizetendo := Kerekito(_brutto);
  _kerekites := _fizetendo-_brutto;

  // Készletellenőrzés:
  GetdnemAdatok('HUF');
  if _fizetendo>_aktzaro then begin
    ShowMessage('NINCS ENNYI FORINT KÉSZLETÜNK !');
    exit;
  end;
end;
```

**Üzleti formula (vásárlás):**
```
nettó       = Σ (soronkénti forintérték)
kezelési_díj = GetKezelesiDij(nettó)   [ha nincs fix díj]
bruttó      = nettó - kezelési_díj     [VÁSÁRLÁSNÁL: levonás]
fizetendő   = Kerekito(bruttó)         [5 Ft-os kerekítés]
kerekítés   = fizetendő - bruttó       [a kerekítés különbözete]
```

**Eladásnál a kezelési díj HOZZÁADÓDIK** a forint összeghez, amit az ügyfélnek fizetnie kell.

---


---

## S5 13_KEZELESI_DIJ_RENDSZER

### 1.3.1 Kezelési díj típusok

A rendszer háromféle kezelési díj módot támogat:

| `_realEzrelek` érték | Mód | Leírás |
|-----------------------|-----|--------|
| `> 0` | Ezrelék | A nettó összeg ezreléke |
| `= 0` | Nincs díj | Díjmentes tranzakció |
| `< 0` (= -1) | Sávos | Sávos díjtáblázat alapján |

A kijelzés is ennek megfelelő:
```pascal
// VASARLAS/Unit2.pas (sor ~430)
if _realEzrelek>0 then _tranzString := inttostr(_realEzrelek)+' %%';
if _realEzrelek=0 then _tranzString := 'nincs';
if _realEzrelek<0 then _tranzString := 'sávos';
```

### 1.3.2 Ezrelék-alapú kezelési díj

```pascal
// VASARLAS/Unit2.pas — GetKezelesidij (sor 1769)
function TVasarlasForm.GetKezelesidij(_ss: integer): integer;
begin
  result := 0;
  if _realezrelek=0 then exit;

  // Ezrelék mód:
  if (_realEzrelek>0) then begin
    result := Kerekito(trunc(_ss*_realEzrelek/1000));
    if result>_kezdijmax then Result := _kezdijmax;
    exit;
  end;

  // Sávos mód:
  _qq := 1;
  while _qq<=_maxsavdb do begin
    result := _kdij[_qq];
    if _ss<=_tranzsav[_qq] then exit;
    inc(_qq);
  end;
  result := _kezdijmax;
end;
```

**Ezrelék formula:**
```
kezelési_díj = Kerekito(trunc(nettó × ezrelek / 1000))
ha kezelési_díj > maximum → kezelési_díj = maximum
```

A kezelési díj is 5 Ft-ra kerekítődik!

### 1.3.3 Sávos kezelési díj tábla

A `TRANZDIJTABLA` adatbázistáblából töltődik be:

```pascal
// VASARLAS/Unit2.pas — KezdijTablaBeolvasas (sor 2436)
procedure TVasarlasForm.KezdijTablaBeolvasas;
begin
  _pcs := 'SELECT * FROM TRANZDIJTABLA ORDER BY SORSZAM';
  // ...
  while not ValutaQuery.eof do begin
    _srs := FieldByName('SORSZAM').asInteger;
    _trz := FieldByName('TRANZAKCIO').asInteger;    // sávhatár (Ft)
    _kzd := FieldByName('KEZELESIDIJ').asInteger;    // díj (Ft)

    if (_kzd=0) and (_srs>1) then _maxsavdb := _srs-1;
    if _srs<23 then begin
      _tranzsav[_srs] := _trz;
      _kdij[_srs] := _kzd;
    end else begin
      _kezdijmax := _kzd;  // 23. sor = maximum díj
      break;
    end;
  end;
end;
```

**Sávos díj adatstruktúra:**
- Maximum 22 sáv (`_tranzsav[1..22]` és `_kdij[1..22]`)
- A 23. sor tartalmazza a maximum díj plafont (`_kezdijmax`)
- A díj a legkisebb sávhatárnál áll meg, amelyik nagyobb vagy egyenlő a nettó összegnél

Az ELADAS modulban meglévő (kikommentezett) sávos díjtábla mutatja a korábbi fix díjstruktúrát:
```pascal
// ELADAS/Unit2.pas — GetTranzdij — kikommentezett fix sávok:
(*
  result := 50;  if _ss<2001 then exit;     // 0-2000 Ft → 50 Ft díj
  result := 100; if _ss<=10001 then exit;    // 2001-10000 → 100 Ft
  result := 120; if _ss<=20001 then exit;    // 10001-20000 → 120 Ft
  result := 150; if _ss<=30001 then exit;    // 20001-30000 → 150 Ft
  result := 200; if _ss<=50001 then exit;    // 30001-50000 → 200 Ft
  result := 250; if _ss<=60001 then exit;    // 50001-60000 → 250 Ft
  // ... egészen 10M Ft-ig: 2500 Ft
*)
```

### 1.3.4 Kezelési díj kedvezmény

A `KEZDKEDV` DLL kezeli a kezelési díj kedvezményt. Hat típust ismer:

```pascal
// VASARLAS/Unit2.pas — KezdijEngedmenyGombClick (sor ~1000)
_kezdijengedmenytip := kezdijkedvezmeny;
if _kezdijengedmenytip>0 then begin
  SzamlaAlaplap.Enabled       := False;  // Számla letiltva
  KezdijEngedmenyGomb.Enabled := False;  // Gomb letiltva
  // Beolvassa a fix kezelési díjat:
  _fixkezelesidij := FieldByNAme('KEZELESIDIJ').asInteger;
  _kartyaszam := trim(FieldByNAme('KARTYASZAM').asString);
  // Ha típus=6: egyedi kezelési díj
  if _kezdijengedmenytip=6 then _ezegyedikezdij := True;
end;
```

**Egyedi kezelési díj korlátozás:**
- Naponta maximum 3 egyedi kezelési díj kedvezmény adható
- A `NAPIEGYEDIKEZDIJ` mező a HARDWARE táblában számlálja

```pascal
// VASARLAS/Unit2.pas — Folytatas (sor ~1293)
if _ezEgyediKezdij then begin
  inc(_nEgykezdij);
  _pcs := 'UPDATE HARDWARE SET NAPIEGYEDIKEZDIJ='+inttostr(_negykezdij);
  ValutaParancs(_pcs);
  logirorutin(pchar('Egyedi kezdij lehetőség '+inttostr(3-_negykezdij)+' maradt'));
end;
```

### 1.3.5 Kezelési díj az ELADAS modulban — GetTranzdij vs GetKezelesidij

**Kritikus duplikáció!** Az ELADAS modulban KÉT kezelési díj függvény van:
- `GetKezelesidij` — azonos logika mint VASARLAS-ban
- `GetTranzdij` — kibővített verzió, ami figyelembe veszi a kedvezményt is

```pascal
// ELADAS/Unit2.pas — GetTranzdij (sor 1916)
function TeladasForm.GetTranzdij(_ss: integer): integer;
begin
  if _vanKezdijEngedmeny then begin
    result := _kezelesidij;  // Fix kedvezményes díj
    exit;
  end;
  // Ezután azonos az ezrelékes és sávos logika...
end;
```

---


---

## S6 14_KONVERZIO_DEVIZA_DEVIZA

A konverzió egy speciális kétlépéses tranzakció:

1. **Vásárlás**: ügyfél devizát ad → pénztáros forintot ad (de nem fizeti ki!)
2. **Eladás**: a forint értékből devizát kap → forint nem mozog fizikailag

```pascal
// VASARLAS/Unit2.pas — FormActivate
if _ezKonverzio then begin
  Konvcimpanel.Visible    := True;
  KonvsumPanel.Visible    := True;
  logirorutin(pchar('Ez konverziós vásárlás lesz'));
end;

// ELADAS/Unit2.pas — FormActivate — konverziós eladás:
if _ezKonverzio then begin
  logirorutin(pchar('Ez a konverziós vétel eladási része'));
  KonvCimPanel.Visible := True;
  KonvSumPanel.Visible := True;
  _limit  := _konvertIn;     // A beadott deviza forintértéke
  _maradt := _konvertIn;     // Ennyi Ft-nak megfelelő devizát kaphat
end;
```

A konverziónál:
- Az ügyfél-azonosítási küszöb a kombinált összeg: `_fizetendo := _fizetendo + _fizetendo` (kétszerezés)
- Azonos devizanem konverziója tiltott
- A `LIMIT` mező korlátozza, hogy az ügyfél pontosan annyi forintértékű devizát kapjon, amennyit beadott (mínusz díj)

```pascal
// ELADAS/Unit2.pas — az eladásnál limit-kezelés:
if _maradt>0 then begin
  // Automatikusan kiszámítja a maximális bankjegy mennyiséget:
  if _aktdnem<>'JPY' then 
    _bankjegy := trunc(100*_maradt/_aktArfolyam)
  else 
    _bankjegy := trunc(1000*_maradt/_aktArfolyam);
  _wb[_aktsor].Text := inttostr(_bankjegy);
end;
```

---


---

## S7 15_KESZLET_ELLENORZES

### 1.5.1 Valuta-készlet kontroll

Minden tranzakció előtt készlet-ellenőrzés történik:

**Vásárlásnál** (pénztáros forintot fizet):
```pascal
// VASARLAS/Unit2.pas — FizetendoDisplay
GetdnemAdatok('HUF');
if _fizetendo>_aktzaro then begin
  ShowMessage('NINCS ENNYI FORINT KÉSZLETÜNK !');
  exit;
end;
```

**Eladásnál** (pénztáros devizát ad):
```pascal
// ELADAS/Unit2.pas — BankjegyKeyDown
_found := GetDnemAdatok(_aktdnem);
// ...
if _aktbankjegy>_aktzaro then begin
  Showmessage('NINCS ENNYI ' + _aktdnem + ' BANKJEGYÜNK');
  _wb[_aktsor].text := '';
  exit;
end;
```

A készletadatok az `ARFOLYAM` tábla `ZARO` mezőjéből jönnek, ami a záró (aktuális) készletet tartalmazza.

### 1.5.2 Maximum 6 tétel per tranzakció

A rendszer maximum 6 sort (6 különböző devizanemet) enged egyetlen bizonylaton:

```pascal
// VASARLAS/Unit2.pas — BankjegyKeyDown
if _tetel=6 then exit;  // Ha betelt mind a 6 sor
```

Ez a `_wd[1..6]`, `_wa[1..6]`, `_wb[1..6]` tömbök méretéből ered — fix, nem konfigurálható korlát.

---

# 2. AML/KYC SZABÁLYOK


---

## S8 21_UGYFEL_AZONOSITASI_KUSZOBOK

### 2.1.1 Háromszintű azonosítási rendszer

A rendszer három szintet különböztet meg az összeg alapján:

```pascal
// UGYFEL/Unit2.pas — FormActivate (sor ~540)
_securlevel := 0;
if _konverzio=1 then _fizetendo := _fizetendo + _fizetendo; // Konverziónál duplázás!

if _fizetendo>=100000 then 
  NemAzonositoGomb.Enabled := False;  // 100k felett: kötelező legalább kisügyfél

if (_fizetendo>=300000) then begin
  _securlevel := 1;
  _kotelezo   := True;
  Kisugyfelgomb.Enabled := False;     // 300k felett: TELJES azonosítás kötelező
end;
```

| Összeg | Szint | Azonosítás | Lehetőségek |
|--------|-------|------------|-------------|
| < 100.000 Ft | 0 | Nem kötelező | Azonosítás / Kisügyfél / Nem azonosít |
| 100.000 – 299.999 Ft | 0 | Részben kötelező | Azonosítás / Kisügyfél (nem azonosít letiltva) |
| ≥ 300.000 Ft | 1 (securlevel) | Teljes azonosítás | Kizárólag teljes azonosítás |

### 2.1.2 Kisügyfél rendszer

A 100.000–300.000 Ft közötti sávban használható „kisügyfél" mechanizmus:

- A `KISUGYFEL` DLL kezeli
- Minimális adatrögzítés (név, nem feltétlenül okmány)
- A `kisugyfel.fdb` szerveren tárolt adatbázisban keresés
- Input/output VTEMP-en keresztül

Visszatérési kódok:
```
-1 = Tranzakció STOP ! Nem folytatható !
 1 = Kisügyfél rögzítve (adatok VTEMP-ben)
 2 = Kötelező a teljes azonosítás
 3 = Nincs internet vagy szerverkapcsolat vagy 100ezer alatt
```

Ha a kisügyfél-rutin `2`-vel tér vissza (teljes azonosítás szükséges):
```pascal
// UGYFEL/Unit2.pas — KisugyfelGombClick
if _mresult=2 then begin
  _mess := 'Kisügyfélrutin üzeni -> teljes azonosítás szükséges';
  _securlevel := 1;
  _kotelezo := True;
  Azonositogombclick(Nil);  // Automatikusan teljes azonosítás
end;
```

### 2.1.3 Jogi személy — mindig teljes azonosítás

```pascal
// UGYFEL/Unit2.pas — JogiRadioClick
procedure TUgyfelinput.JOGIRADIOClick(Sender: TObject);
begin
  _kotelezo := true;
  _securlevel := 1;
  _pcs := 'UPDATE VTEMP SET SECURLEVEL=1';
  ValutaParancs(_pcs);
  Kisugyfelgomb.Enabled := False;
end;
```

Jogi személyek esetén **MINDIG** `securlevel=1` → teljes azonosítás kötelező, összeghatártól függetlenül.


---

## S9 22_TERMESZETES_SZEMELY_AZONOSITAS

### 2.2.1 Rögzített adatmezők

A természetes személynél az alábbi adatok kerülnek rögzítésre:

```pascal
// UGYFEL/Unit2.pas — deklarációk
_nev, _elozo, _leany, _anyja: string;        // Nevek
_szulhely, _szulido: string;                   // Születési adatok
_irszam, _varos, _utca, _lakcim: string;      // Lakcím
_azonosito, _okmanytipus: string;              // Okmány
_allampolgar, _tarthely: string;               // Állampolgárság, tartózkodási hely
_iso: string;                                   // Országkód
_kulfoldi: byte;                               // Belföldi/külföldi flag
_kozszereplo: byte;                            // Közszereplő flag
_lakcimcard: string;                           // Lakcímkártya szám
```

Okmánytípusok (fix tömb):
```pascal
_okmtiptomb: array[0..2] of string = ('SZIG','JOGOSITVANY','UTLEVEL');
```

### 2.2.2 Ügyfél-keresés a központi szerveren

A `BIGCTRL` DLL a központi szerveren (`UGYFELYY.FDB`) keresi az ügyfelet:

```pascal
// BIGCTRL/Unit2.pas — NaturUgyfelKereses (sor 408)
function TForm2.NaturUgyfelKereses: integer;
begin
  // Névtábla meghatározása a kezdőbetű alapján:
  _kezdoBetu := leftstr(_ugyfelnev,1);
  _nevtabla  := _kezdoBetu + 'NEV';     // pl. 'ANEV', 'BNEV', ...
  _biztabla  := _kezdobetu + 'BIZ';     // pl. 'ABIZ', 'BBIZ', ...
  
  // Keresés NÉV alapján:
  _pcs := 'SELECT * FROM ' + _nevtabla +
    ' WHERE NEV=' + chr(39) + _ugyfelnev + chr(39);
  
  // Ha találat van — 4 adatból 2 egyezés kell:
  while not RemoteQuery.eof do begin
    _rAnyjaneve     := trim(RemoteQuery.fieldByNAme('ANYJANEVE').asString);
    _rSzuletesihely := trim(Remotequery.FieldByNAme('SZULETESIHELY').asString);
    _rSzuletesiido  := trim(RemoteQuery.FieldByNAme('SZULETESIIDO').asString);
    _rAzonosito     := trim(RemoteQuery.FieldByNAme('AZONOSITO').AsString);
    
    _pont := 0;
    if _ranyjaneve=_anyjaneve then _pont := 1;
    if _rszuletesiido=_szuletesiido then inc(_pont);
    if _rszuletesihely=_szuletesihely then inc(_pont);
    if _razonosito=_azonosito then inc(_pont);
    
    if _pont>1 then begin   // 2+ egyezés = azonosítva
      _megvan := True;
      break;
    end;
    RemoteQuery.next;
  end;
end;
```

**Azonosítási algoritmus — 4 mezőből 2 egyezés:**
1. Anyja neve
2. Születési idő
3. Születési hely
4. Okmányszám

Ha legalább 2 egyezik → az ügyfél azonosítva van.

**Kockázat:** Ez a fuzzy matching hibás pozitívot adhat (két különböző ember azonos névre + 2 egyező adatra), és hamis negatívot is (elgépelt anyja neve + eltérő okmány → új ügyfél létrehozása).

### 2.2.3 Névtábla rendszer

Az ügyfélnyilvántartás a szerveren **betűnkénti névtáblákba** szervezett:

```
ANEV, ABIZ — 'A'-val kezdődő ügyfélnevek
BNEV, BBIZ — 'B'-vel kezdődő ügyfélnevek
...
ZNEV, ZBIZ — 'Z'-vel kezdődő ügyfélnevek
JOGI, JOGIBIZ — Jogi személyek
```

A `NEVTABLA` a keresés/regisztrálás helye, a `BIZTABLA` a bizonylat-nyilvántartás.

### 2.2.4 Ügyfél-tiltás

A szerveren `TILTVA` mező jelöli a tiltott ügyfeleket:

```pascal
// BIGCTRL/Unit2.pas — NaturUgyfelKereses
if _tiltva=1 then begin
  ShowMessage('AZ ÜGYFÉL LE VAN TILTVA !');
  result := -1;
  exit;
end;

if _tiltva=2 then begin
  ShowMessage('AZ ÜGYFÉL CSAK FORRÁS MEGJELÖLÉSSEL VÁLTHAT !');
  _spk := supervisorjelszo(0);
  if _spk=1 then result :=1 else result := -1;
  exit;
end;
```

| `TILTVA` | Jelentés | Művelet |
|----------|----------|---------|
| 0 | Normál | Nincs korlátozás |
| 1 | Tiltott | Tranzakció NEM engedélyezhető |
| 2 | Forrás szükséges | Supervisor jelszóval + forrás megjelöléssel válthat |


---

## S10 23_JOGI_SZEMELY_AZONOSITAS

### 2.3.1 Jogi személy adatmezők

```pascal
// UGYFEL/Unit2.pas — jogi személyes változók
_jNev: string;          // Jogiszemély neve
_jTelephely: string;    // Telephely címe
_jOkirat: string;       // Okirat száma
_jAdoszam: string;      // Adószám
_jKepvisnev: string;    // Képviselő neve
_jTeaor: string;        // TEÁOR kód
_jOrszag: string;       // Ország
_jIso: string;          // ISO kód
```

### 2.3.2 Jogi személy keresés

```pascal
// BIGCTRL/Unit2.pas — JogiUgyfelKereses (sor 612)
function TForm2.JogiUgyfelKereses: integer;
begin
  _nevtabla := 'JOGI';
  _BIZTABLA := 'JOGIBIZ';
  
  // A jogiszemélynév első 7 karaktere alapján:
  _jugynev := leftstr(_jogiugyfelnev,7);
  _pcs := 'SELECT * FROM JOGI WHERE JOGISZEMELYNEV LIKE ' + 
    chr(39) + _Jugynev +'%'+ chr(39);
  
  // Egyeztetés: telephelycím + okiratszám
  while not RemoteQuery.eof do begin
    _rThcim := trim(RemoteQuery.FieldByNAme('TELEPHELYCIM').asString);
    _rokir  := trim(RemoteQuery.FieldByName('OKIRATSZAM').AsString);
    _rThCim := leftstr(withoutIrszam(_rThCim),7);
    _rOkir  := withoutLetter(_rOkir);
    
    IF _rthCim=_jTelep then _found := 1;
    if _rokir=_jOkirat then inc(_found);
    
    if _found>0 then begin    // 1+ egyezés = azonosítva
      _megvan := true;
      break;
    end;
  end;
end;
```

**Jogi személy azonosítás algoritmusa:**
- Név: első 7 karakter LIKE keresés
- Cím: irányítószám nélkül, első 7 karakter
- Okirat: betűk nélkül (csak számok)
- **1 egyezés elég** (szemben a természetes személy 2-es küszöbével)

### 2.3.3 Tényleges tulajdonosok (Beneficial Owners)

Jogi személyek esetén a tényleges tulajdonosok (max. 4) is rögzítésre kerülnek:

```pascal
// UGYFEL/Unit2.pas — tulajdonos változók
_tulajnevedit  : array[1..4] of TEdit;
_ttKozszereplo : array[1..4] of byte;
_ttNev, _ttElozonev, _tTlakcim: array[1..4] of string;
_ttSzulhely, _ttSzulido: array[1..4] of string;
_ttAllampolgar, _ttTarthely: array[1..4] of string;
_tTerdJelleg, _ttErdMertek: array[1..4] of string;  // Érdekeltség jellege, mértéke
```

A bizonylaton megjelenő adatok:
```pascal
// BLOKNYOM/Unit2.pas — Ugyfelnyomtatas
writeLn(_lFile,'Tényleges tulajdonosok adatai:');
while _qq<=_tuldarab do begin
  writeLn(_lFile,_tnev[_qq]);        // Tulajdonos neve
  writeLn(_lFile,_tcim[_qq]);        // Címe
  writeLn(_lFile,_tszuldata[_qq]);   // Születési hely + idő
  writeLn(_lFile,_tallamp[_qq]);     // Állampolgárság
  writeLn(_lFile,_ttarthely[_qq]);   // Tartózkodási hely
  writeLn(_lFile,_tjelleg[_qq]);     // Érdekeltség jellege
  writeLn(_lFile,_tmertek[_qq]);     // Érdekeltség mértéke
  // Közszereplő státusz:
  if _tk=0 then writeLn('Nem közszereplő')
  else writeLn('A tulaj közszereplő');
end;
```


---

## S11 24_TERRORIZMUS_SZURES

### 2.4.1 Terrorlista ellenőrzés (TERROR DLL)

```pascal
// TERROR/Unit2.pas — a szűrés folyamata

// 1. Betűkiemelés — csak nagybetűk maradnak:
function TTerror.Betukiemelo(_s: string): string;
var _ws,_pp,_betu: byte;
begin
  _s := trim(_s);
  _ws := length(_s);
  result := '';
  _pp := 1;
  while _pp<=_ws do begin
    _betu := ord(_s[_pp]);
    if (_betu>64) and (_betu<91) then result := result + chr(_betu);
    inc(_pp);
  end;
end;
```

A szűrés folyamata:
1. Az ügyfél neve betűkiemelésre kerül (csak A-Z nagybetűk maradnak)
2. Összehasonlítás a terrorlistával
3. Találat esetén a pénztáros dönthet: **STOP** (tiltás) vagy **ENGEDÉLYEZÉS** (supervisor)

### 2.4.2 Engedélyezési folyamat

```pascal
// TERROR/Unit2.pas — StopGombClick
procedure TTERROR.STOPGOMBClick(Sender: TObject);
begin
  logirorutin(pchar('A terrorlistán szereplés miatt a tranzakció letiltva !'));
  Regisztracio;
  _mResult := -1;
end;

// TERROR/Unit2.pas — EngedelyezoGombClick
procedure TTERROR.ENGEDELYEZOGOMBClick(Sender: TObject);
begin
  _engedelyezve := 'IGEN';
  logirorutin(pchar('A terrorlista ellenére engedélyezték a tranzakciót'));
  logirorutin(pchar('Engedélyező: ' + _engedelyezo));
  regisztracio;
  _mResult := 1;
end;
```

### 2.4.3 Terror-regisztráció

Minden terrorlista-találat — akár engedélyezett, akár tiltott — regisztrálódik a JOURNAL táblába:

```pascal
// TERROR/Unit2.pas — Regisztracio
procedure TTerror.Regisztracio;
begin
  _pcs := 'INSERT INTO JOURNAL (DATUM,IDO,PENZTARKOD,PENZTARNEV,' +
    'UGYFELNEV,ENGEDELYEZVE,ENGEDELYEZO) VALUES (...)';
  // remoteDbase → szerverre ír!
end;
```


---

## S12 25_TRANZAKCIO_TIPUS_MEGHATAROZAS_AML_GYANUS_MINTAZATOK

### 2.5.1 GetTranztip — a gyanús tranzakciók kategorizálása

A `BIGCTRL` DLL `GetTranztip` függvénye osztályozza a tranzakciókat:

```pascal
// BIGCTRL/Unit2.pas — GetTranztip (sor 1260)
function TForm2.GetTranztip: integer;
var _hasforint, _diff: integer;
begin
  _hasforint := _virtualFizetendo;
  _diff := Napidiff(_lastdatum,_megnyitottnap);
  if _diff<8 then _hasforint := _hasforint + _hetiforint;  // Heti kumuláció!
  
  // 6: 50 millió Ft felett
  result := 6;
  if _hasforint>=50000000 then exit;
  
  // 5: 10 millió Ft felett
  result := 5;
  if _hasforint>=10000000 then exit;
  
  // 4: Negyedév alatt 4× 25 millió felett
  result := 4;
  if (_tranzdarab=4) then begin
    _negyedevFt := Getquoter;
    if _negyedevft>=25000000 then exit;
  end;
  
  // 3: 2× éven belül 8 millió felett
  result := 3;
  if (_evimax>=8000000) and (_hasforint>=8000000) then exit;
  
  // 2: Külföldi (kockázatos)
  result := 2;
  if _kulfoldi=1 then begin
    if not usdadhato then result := -1;  // Szankcionált ország → teljes tiltás
    exit;
  end;
  
  // 1: Belföldi közszereplő
  result := 1;
  if _rKozszerep=1 then exit;
  
  // 0: Nincs korlát
  result := 0;
end;
```

**Tranzakció-típus táblázat:**

| Kód | Feltétel | Jelentés | Szükséges engedély |
|-----|----------|----------|---------------------|
| 0 | Minden más | Normál — nincs korlátozás | Nincs |
| 1 | Közszereplő (PEP) | Kiemelt közszereplő | Engedélyezés szükséges |
| 2 | Külföldi | Kérdőjeles nemzetiségű külföldi | Engedélyezés szükséges |
| 3 | 2× 8M Ft éven belül | Ismételt nagy összegű tranzakció | Engedélyezés szükséges |
| 4 | 4× 25M Ft negyedévben | Strukturált tranzakciók gyanúja | Engedélyezés szükséges |
| 5 | ≥ 10M Ft | Nagy összegű tranzakció | Engedélyezés szükséges |
| 6 | ≥ 50M Ft | Kiemelt nagy összegű | Engedélyezés szükséges |
| -1 | Szankcionált ország + USD | Tiltott | Tranzakció nem végezhető |

### 2.5.2 Heti kumuláció

A rendszer 7 napos csúszóablakot alkalmaz:
```pascal
_diff := Napidiff(_lastdatum,_megnyitottnap);
if _diff<8 then _hasforint := _hasforint + _hetiforint;
```

Ha az utolsó tranzakció 7 napon belül volt, a heti összeget hozzáadja az aktuális összeghez → kumulált ellenőrzés.

### 2.5.3 Negyedéves ellenőrzés

A `GetQuoter` függvény a negyedéves forgalmat számolja ki a bizonylattáblából:

```pascal
// BIGCTRL/Unit2.pas — GetQuoter (sor 1341)
function TForm2.GetQuoter: integer;
begin
  result := 0;
  // A negyedév kezdő hónapjának meghatározása:
  _nyev := trunc((_aktho-1)/3);
  _tho := 1+trunc(_nyev*3);
  _iho := _tho + 3;
  _tol := leftstr(_megnyitottnap,5)+nulele(_tho)+'.01';
  _ig  := leftstr(_tol,5)+nulele(_iho)+'.01';
  
  // Szerveren a BIZTABLA-ból lekérdezi a negyedéves forgalmat:
  _pcs := 'SELECT * FROM ' + _biztabla +
    ' WHERE (SORSZAM='+inttostr(_sorszam)+') AND (' +
    'DATUM>='''+_tol+''') AND (DATUM<='''+_ig+''')';
  
  while not RemoteQuery.eof do begin
    _aktft := RemoteQuery.FieldByNAme('FIZETENDO').asInteger;
    result := result + _aktft;
    Remotequery.next;
  end;
end;
```


---

## S13 26_PEP_KOZSZEREPLO_KEZELES

### 2.6.1 Közszereplő nyilatkozat

A bizonylaton kötelezően megjelenik a közszereplő státusz:

```pascal
// BLOKNYOM/Unit2.pas — KozszerepNyilatkozat
procedure TBlokkNyom.KozszerepNyilatkozat(_ksz: integer);
begin
  if _ksz=0 then writeLn('Nem közszereplő')
  else writeLn('Az ügyfél kiemelt közszereplő');
end;
```

### 2.6.2 Kiemelt státusz lekérdezés

A `GETSTATUS` DLL (`getkiemeltstatusz`) a központi szerveren ellenőrzi az ügyfél kiemelt státuszát.


---

## S14 27_FORRAS_MEGJELOLES

300.000 Ft feletti tranzakcióknál (`securlevel=1`) a bizonylaton a pénzeszköz forrása is megjelenik:

```pascal
// BLOKNYOM/Unit2.pas — Jogcimnyilatkozat
if _forras<>'' then
  writeLn(_LFile,'Pénzeszközöm forrása: '+ _forras);
```

Az `_engedelyezo` mező tartalmazza az engedélyező személy nevét, aki a felettes/supervisor szinten jóváhagyta a tranzakciót.


---

## S15 28_E_MAIL_ERTESITES_ENGEDELYEZETT_TRANZAKCIOKNAL

Ha egy tranzakcióhoz engedélyező kellett, az XML e-mail küldés aktiválódik:

```pascal
// VASARLAS/Unit2.pas — Folytatas (~sor 1320)
if _engedelyezo<>'' then begin
  logirorutin(pchar('Mivel volt engedélyező, ezt e-mailben jelzi'));
  MakeXML;
  XMLBemasolas;
end;
```

A címzettek a pénztárkód alapján döntöttek:
```pascal
// VASARLAS/Unit2.pas — MakeXml (~sor 1598)
// Mindig megy:
_mailstring += 'fabulyazsuzsa.eec@gmail.com';

// EBC pénztáraknál (<151) még megy:
_mailstring += 'kosa.zoltan.ebc@gmail.com';
_mailstring += 'nagyannamaria.ebc@gmail.com';

// Expressz pénztáraknál (≥151):
_mailstring += 'batori.monika.ebc@gmail.com';
```

**GDPR kockázat:** E-mail címek hardcoded a forráskódban!

---

# 3. BIZONYLAT-RENDSZER


---

## S16 31_BIZONYLATTIPUSOK_OSSZESITO

A `BLOKNYOM` DLL (`blokknyomtatas`) a bizonylat típusát az `_nyomtipus` paraméterből kapja. A FormActivate-ben:

```pascal
// BLOKNYOM/Unit2.pas — FormActivate (sor ~295)
if _nyomtipus>10 then _copyblokk := true;  // >10 = MÁSOLAT

if _storno=3 then begin
  StornoBlokknyomtatas;
  exit;
end;

if _tipus='V' then VetelSzamlaNyomtatas;    // Vételi számla
if _tipus='E' then EladasSzamlaNyomtatas;    // Eladási számla
if _tipus='F' then AtadBlokkNyomtatas;       // Átadó blokk
if _tipus='U' then AtveszBlokkNyomtatas;     // Átvételi blokk
```

### 3.1.1 Teljes bizonylattípus katalógus

| # | Típus | Eljárás | Leírás |
|---|-------|---------|--------|
| 1 | Vételi számla (V) | `VetelSzamlaNyomtatas` | Devizavétel → HUF kifizetés |
| 2 | Eladási számla (E) | `EladasSzamlaNyomtatas` | HUF bevétel → deviza kiadás |
| 3 | Átadó blokk (F) | `AtadBlokkNyomtatas` | Pénztárak közötti deviza átadás |
| 4 | Átvételi blokk (U) | `AtveszBlokkNyomtatas` | Pénztárak közötti deviza átvétel |
| 5 | Sztornó blokk | `StornoBlokknyomtatas` | Tranzakció érvénytelenítés |
| 6 | Árfolyam módosítás | `ArfModNyomtatas` | Kedvezményes árfolyam dokumentálás |
| 7 | Címletlista | `CimletNyomtatas` | Deviza-címlet bontás |
| 8 | Ügyfél-nyomtatás | `Ugyfelnyomtatas` | Ügyfél adatlap a bizonylaton |
| 9 | Jogcím nyilatkozat | `Jogcimnyilatkozat` | 300k+ tranzakciók jogi nyilatkozat |
| 10 | Közszereplő nyilatkozat | `KozszerepNyilatkozat` | PEP státusz dokumentálás |
| 11 | Saját nyilatkozat | `sajatnyil` | Kisügyfél saját nevében nyilatkozat |
| 12 | Reklám szekció | `ReklamNyomtatas` | Promóciós blokk |
| 13 | Deviza státusz | `DevizsStatuszNyomtatas` | Belföldi/külföldi deviza státusz |
| 14 | Orosz nyilatkozat | `OroszNyilatkozat` | Orosz ügyfeleknek speciális szöveg |
| 15 | ÁFÁs számla (matrica) | `AfasSzamla` | Autópálya matrica ÁFÁs számla |
| 16 | ÁFÁs számla (telefon) | `TelAfasSzamla` | Telefon-feltöltés ÁFÁs számla |


---

## S17 32_BIZONYLAT_FEJLEC_ES_CEGCSOPORT

### 3.2.1 Cégcsoport felépítés — kódból rekonstruálva

A rendszer pénztárszám-alapján dönt a cégadatokról:

```pascal
// BLOKNYOM/Unit2.pas — GetPenztarData (sor ~430)
If _aktpenztarszam<151 then begin
  _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
  _aktadoszam := '32313332-2-02';
end else begin
  _cegnev := 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT';
  _aktadoszam:= '14040535-2-02';
end;
```

| Pénztárkód | Cég | Adószám |
|------------|-----|---------|
| 1–150 | Exclusive Best Change Zrt. | 32313332-2-02 |
| 151+ | Expressz Ékszerház és Minibank Kft. | 14040535-2-02 |

A fejlécben továbbá megjelenik:
- **Kupon Portfolio és Kereskedelmi Kft.** (2161 Csomád, Liget utca 40.) — a fő holding/csoportcég
- A konkrét pénztár neve és címe
- Telefon
- Terminál ID (4 karakter)

### 3.2.2 Bizonylat fejléc felépítés

```
   ┌─────────────────────────────────────────┐
   │            N Y U G T A                   │
   │                                          │
   │    EXCLUSIVE BEST CHANGE ZRT             │
   │    [Pénztár neve]                        │
   │    [Pénztár címe]                        │
   │    Telefon: [szám]                       │
   │    Adoszam: [32313332-2-02]              │
   │                                          │
   │    [Konverziós valuta vétel/eladás]      │
   │    EXCHANGE (PURCHASE/SELLING)           │
   ├──────────────────────────────────────────┤
   │ Sorszam (INVOICE NR): [12345678]         │
   │ Datum   (DATE)      : [2026.04.02]       │
   │ Ido     (TIME)      : [14:35]            │
   │       (Nyugtaszam: X/Y)                  │
   ├──────────────────────────────────────────┤
   │ Adómentes           Szj - 67.13.10.0    │
   │ M.A.A.  a szolgaltatas nyujtasa a 2007  │
   │ evi CXVII tv. 86 § e) alapjan mentes    │
   │ az ado alol                              │
   ├──────────────────────────────────────────┤
```


---

## S18 33_AFA_KEZELES

### 3.3.1 Valutaváltás — ÁFA mentes

A valutaváltási tevékenység ÁFA-mentes, ezt minden bizonylaton kötelezően feltüntetik:

```pascal
// BLOKNYOM/Unit2.pas — VetelSzamlaNyomtatas
writeLn(_LFile,'Adómentes               Szj - 67.13.10.0');
writeLn(_LFile,'M.A.A.    a szolgaltatas nyujtasa a 2007');
writeLn(_LFile,'evi CXVII tv. 86 § e) alapjan mentes az');
writeLn(_LFile,'             ado alol');
```

**Jogszabályi hivatkozás:** 2007. évi CXVII. tv. (ÁFA törvény) 86. § e) pont — pénzváltási tevékenység ÁFA mentessége.
**SZJ kód:** 67.13.10.0 — pénzügyi közvetítés segédtevékenysége

### 3.3.2 Matrica értékesítés — ÁFÁ-s

```pascal
// TRADE.EXE — AfasSzamla
writeLn(_LFile,'A számla végösszege 21,26 % AFA-t tartalmaz');
```

Az autópálya matrica értékesítés NEM ÁFA-mentes — 21,26% ÁFA tartalmat mutat. (Ez a bruttó összegből visszaszámolt ÁFA tartalom 27%-os kulcs esetén: 27/127 ≈ 21,26%.)

### 3.3.3 Western Union ÁFA

A havi zárásban külön WU ÁFA forgalom szekció:
```pascal
// HAVIZAR/Unit2.pas — deklarált változók:
_haviKezdij: integer;           // A havi kezelési díj
_haviKezdijAtadas: integer;     // Átadásból származó kezelési díj
_haviKezdijAtvet: integer;      // Átvételből származó kezelési díj
```


---

## S19 34_BIZONYLAT_TARTALOM_RESZLETES_ELEMZES

### 3.4.1 Vételi számla (V) — tétel szekció

```
   V.nem   Arfolyam    B.jegy       Forint
   CURR.    RATE        CASH        VALUE
   ──────────────────────────────────────────
   EUR       410.50      500       205250
   USD       378.20      200        75640
   ──────────────────────────────────────────
   Kerekites (ROUNDING)    :          -2
   Netto Ft  (SUM TOTAL)  :     280890
   Kez. kltsg (HANDLING FEE):      1405
   Kifizetve:(PAID):         279485
```

A vételi számla tartalmazza:
- Devizanemenként: valutanem, árfolyam, bankjegy darab, forint érték
- Kerekítés előjellel (+/-)
- Nettó összeg
- Kezelési költség
- Kifizetve (bruttó = nettó - kezelési díj, kerekítve)

### 3.4.2 Eladási számla (E) — kiegészítő elemek

Eladásnál (ügyfél devizát kap) a fizetőeszköz is megjelenik:

```pascal
// BLOKNYOM/Unit2.pas — EladasSzamlaNyomtatas
if _fizetoeszkoz=1 then kozepreir('Az ugyletet keszpenzben teljesitjuk');
if _fizetoeszkoz=2 then begin
  Kozepreir('Az ugylet bankkartyaval tortent');
  // Bankkártyával és 300k alatt és jogi személy → extra adatok:
  if (_fiz<300000) and (_ugyfeltipus='J') then begin
    writeLN(_LFile,'Ugyfel: '+_joginev);
    writeLN(_LFile,'Telephely: '+_jogihely);
    writeLN(_LFile,'Adoszam: '+_adoszam);
  end;
end;
```

Fizetőeszköz típusok:
| Kód | Fizetőeszköz |
|-----|-------------|
| 1 | Készpénz |
| 2 | Bankkártya (OTP terminál) |

### 3.4.3 Átadó-átvételi blokk tartalma

A pénztárak közötti devizamozgásnál büntetőjogi nyilatkozat kötelező:

```pascal
// BLOKNYOM/Unit2.pas — AtadBlokkNyomtatas
writeLn(_LFIle,'Büntető felelősségem tudatában kijelen-');
writeLn(_LFIle,'tem, hogy a fentiekben felsorolt pénz-');
writeLn(_LFIle,'készletet a szállítóknak átadtam, azt');
writeLn(_LFIle,'        tételesen átszámoltam.');
// ... aláírás mezők: átadó + átvevő
```


---

## S20 35_JOGCIM_NYILATKOZAT_TELJES_SZOVEG

```pascal
// BLOKNYOM/Unit2.pas — Jogcimnyilatkozat (sor ~1440)
WriteLn('JOGCÍM NYILATKOZAT');
WriteLn('Büntetőjogi felelősségem tudatában nyi-');
WriteLn('latkozom, hogy a fenti tranzakciót');

// Jogi személynél:
kozepreir(_joginev);
kozepreir('nevében bonyolítom,');
KozszerepNyilatkozat(_kozszereplo);

// Természetes személynél:
if _megbizoszam=0 then begin
  writeLn('természetes személyenként, saját magam');
  write('nevében bonyolítom, ');
end else begin
  kozepreir(_megbizonev);
  kozepreir('megbízásából bonyolítom, ');
end;

// Kötelezettség szöveg:
WriteLn('Tudomásom van arról, hogy 5 (öt) munka-');
WriteLn('napon belül köteles vagyok bejelenteni a');
WriteLn('szolgáltatónak a fenti adatokban, vagy a');
WriteLn('saját adataimban bekövetkező esetleges');
WriteLn('változásokat, és e kötelezettség elmu-');
WriteLn('   lasztásából eredő kár engem terhel');

// Forrás megjelölés:
if _forras<>'' then
  writeLn('Pénzeszközöm forrása: '+ _forras);

// Aláírás mező:
writeLn('.......................................'); 
writeLn('             ügyfél aláírása');
```


---

## S21 36_BIZONYLAT_SORSZAMOZAS

```pascal
// VASARLAS/Unit2.pas — GetBizonylatszam (sor 2795)
function TVasarlasForm.GetBizonylatszam(_write: boolean): string;
// _write=False → csak olvasás (előzetes)
// _write=True  → végleges sorszám kiadás és léptetés
```

A bizonylat sorszám 8 jegyű, pénztáranként szekvenciális. Konvenciók:
- Előzetes bizonylatszám: a folyamat elején kiosztásra kerül (read-only)
- Végleges bizonylatszám: a tranzakció engedélyezése után véglegesítődik (`_write=True`)


---

## S22 37_BIZONYLAT_MASOLAT

A `_nyomtipus > 10` paraméter jelöli a másolatot:

```pascal
if _copyBlokk then begin
  WriteLn(_Lfile,'M  A  S  O  L  A  T');
  if _reprintIndok<>'' then
    KozepreIr('(Indoka: '+ trim(_reprintIndok)+')');
end;
```

A másolat mindig tartalmazza az újranyomtatás indokát.

---

# 4. NAPI/HAVI ZÁRÁSI ÜZLETI FOLYAMATOK


---

## S23 41_NAPNYITAS

### 4.1.1 Indulási szekvencia

A rendszer nem ismeri külön a „napnyitás" fogalmát — a nap megnyitása a pénztáros belépésekor történik:

1. **Trade.EXE** → `FormActivate` → `InditoTimer`
2. **Internet ellenőrzés** → internet nélkül a program NEM indul
3. **Alapadat beolvasás** → pénztár név, cím, utolsó ügyfél
4. **Havi TRADE tábla** → `HaviTradeControl` — aktuális havi `TRADyymm` tábla létrehozása
5. **Logfájl** → `SetLogFile` — XOR-kódolt napi napló inicializálás
6. **Pénztáros belépés** → `GetPenztaros.ShowModal` — jelszóval
7. **Megnyitott nap** → `HARDWARE.MEGNYITOTTNAP` mező frissítése

A `HARDWARE` tábla két kulcsmezője:
- `MEGNYITOTTNAP` — az aktuálisan megnyitott nap dátuma
- `LEZARTNAP` — az utoljára lezárt nap dátuma

### 4.1.2 Napi kezelési díj nyomtatás (NAPIKEZD DLL)

A `NAPIKEZD` DLL feladata a korábbi napok kezelési díj/költség nyomtatása. Nem a nap megnyitása, hanem a VISSZAMENŐLEGES riport generálás.

```pascal
// NAPIKEZD/Unit2.pas — FormActivate
_gepfunkcio    := FieldByName('GEPFUNKCIO').asInteger;
_megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
_lezartnap     := trim(FieldByName('LEZARTNAP').AsString);

// Csak értéktár (gepfunkcio=2) használhatja:
if _gepFunkcio<>2 then begin
  _Mresult := 2;
  exit;
end;
```

A nyomtatás naptár-alapú — a felhasználó kiválasztja a napot, és a rendszer az adott nap kezelési díjait nyomtatja ki a havi KEZD táblából.


---

## S24 42_NAPZARAS_NAPZAR_DLL

### 4.2.1 Napzárás teljes folyamata

A napzárás a nap legfontosabb adminisztratív eseménye:

```pascal
// NAPZAR/Unit2.pas — InditoTimer (sor ~290)

// 1. Alapadatok ellenőrzése:
_gepfunkcio   := FieldByNAme('GEPFUNKCIO').asInteger;
_lezartnap    := trim(FieldByName('LEZARTNAP').asstring);
_kellforgalom := FieldByNAme('KELLFORGALOM').asInteger;
_kellwestern  := FieldByName('KELLWESTERN').asInteger;
_kellMetro    := FieldByName('KELLMETROAFA').asInteger;
_kelltesco    := FieldByName('KELLTESCOAFA').asInteger;
_kellmatrica  := FieldByNAme('KELLMATRICA').asInteger;
_otp          := FieldByName('POSTTERM').asInteger;
_otpopen      := FieldByName('OTPOPEN').asInteger;
_megnyitottnap:= trim(FieldByNAme('MEGNYITOTTNAP').asstring);

// 2. Dátum validáció:
if _zDatums='' then begin
  ShowMessage('NINCS BELÉPÉSI DÁTUM A HARDWARE-BEN');
  ModalResult := 2;
  exit;
end;

if _zDatums>_megnyitottnap then begin
  Showmessage('A zárandó nap a jövőben lesz !');
  Modalresult := 2;
  exit;
end;

// 3. Adatregeneráció:
regeneralorutin(0);

// 4. Előellenőrzés:
_errorcode := Napzarcontrol;
```

### 4.2.2 Napzár ellenőrzés — errorcode rendszer

```pascal
// NAPZAR/Unit2.pas — NapzarControl
{
  errorcode=  0: hibátlan
              1: hiányos MTCN szám
              2: esti címletezés hibás
              3: kezelési díj címletezés hibás
              4: western union címletezés hibás
              5: afa címletezés hibás
              6: foglaló címletezés hibás
              7: elektromos kereskedés címletezés hibás
              8: axa címletezés hibás
              9: moneygram címletezés hibás
}
```

| Kód | Hiba | Következmény |
|-----|------|-------------|
| 0 | Hibátlan | Napzárás folytatható |
| 1 | Hiányos MTCN szám | **BLOKKOLÓ** — nem zárható |
| 2-9 | Címletezési hiba | Címletmenü megnyitása, javítás szükséges |

### 4.2.3 Napzárás lépések

```pascal
// NAPZAR/Unit2.pas — a zárás tényleges végrehajtása (sor ~400)

// 1. HRK (horvát kuna) zárás:
_hrkOke := horvatkunazaro;

// 2. Pénztárgép QR kód:
qrdisplayrutin;

// 3. NAV kontroll:
_navoke := navzarocontrol;

// 4. Havi gyűjtőkbe másolás:
HavigyujtokbeMasolas;

// 5. Napi forgalom számítás:
Napiforgalomszamitas;

// 6. Napi árfolyamtáblák feltöltése:
NarfolyamFeliras;

// 7. Napi jelentés:
napijelrutin;

// 8. Dekádjelentés:
DekzarCtrl(_zDatums);

// 9. Napzár nyomtatás:
napzarnyomtatorutin;

// 10. Záródátum rögzítése:
_pcs := 'UPDATE HARDWARE SET LEZARTNAP='+chr(39)+_zDatums+chr(39);
ValutaParancs(_pcs);

// 11. Üres pénztár kontroll:
UresPenztarControl;
```

### 4.2.4 Üres pénztár kontroll

Ha a HUF záró készlet nulla, speciális kezelés:

```pascal
// NAPZAR/Unit2.pas — UresPenztarControl
procedure TNapZarForm.UresPenztarControl;
begin
  // HUF záró lekérdezés:
  _hufzaro := FieldByNAme('ZARO').asInteger;
  if _hufzaro<>0 then exit;
  
  // Ha nulla: a címlet-fájlba 0 értéket ír:
  _pcs := 'INSERT INTO ' + _cimfilenev + 
    ' (DATUM,VALUTANEM,OSSZESFORINTERTEK) VALUES (..., ''HUF'', 0)';
end;
```


---

## S25 43_DEKAD_TIZNAPOS_IDOSZAK

### 4.3.1 Dekádjelentés

A `DEKRUTIN` DLL kezeli a dekád (10 napos) beszámolókat. A `DekzarCtrl` a napzárásban hívódik meg és ellenőrzi/generálja a dekád-adatokat.

A dekád az `_aktdek` változóban:
```pascal
// VASARLAS/Unit2.pas
_aktdek := yearof(Date)-2000;  // Az aktuális évtized (pl. 26 a 2026-hoz)
```

**Megjegyzés:** Ez a változó a Firebird adatbázis fájl elnevezéshez is használatos: `ugyfel26.fdb`.


---

## S26 44_HAVI_ZARAS_HAVIZAR_DLL

### 4.4.1 Havi zárás teljes folyamata

```pascal
// HAVIZAR/Unit2.pas — HookEGombClick (sor ~320)

// A kért hónap meghatározása:
_kertev := _maiev;
_kertho := 1 + _hoindex;

// Táblák elnevezése:
_bfTablaNev   := 'BF' + _farok;      // BF2604 = Blokkfej 2026-április
_btTablanev   := 'BT' + _farok;      // BT2604 = Blokktétel 2026-április
_kezdTablaNev := 'KEZD' + _farok;    // KEZD2604 = Kezelési díj 2026-ápr.
_eHzaroTablaNev := 'HZ' + _eFarok;  // HZ2603 = Havi záró előző hónap
_ujHzTablanev := 'HZ' + _farok;     // HZ2604 = Havi záró aktuális hónap
```

### 4.4.2 Havi táblák dinamikus elnevezése

| Prefix | Struktúra | Tartalom |
|--------|-----------|----------|
| `BF` | BFyymm | Blokkfej (bizonylat fejlécek) |
| `BT` | BTyymm | Blokktétel (bizonylat sorok) |
| `KEZD` | KEZDyymm | Kezelési díj adatok |
| `HZ` | HZyymm | Havi záró készlet |
| `NARF` | NARFyymm | Napi árfolyamok |
| `TRAD` | TRADyymm | Tranzakciók (Trade.fdb-ben) |
| `WCIMTAR` | WCIMTARyymm | Western Union címtár |

### 4.4.3 Havi záró riport tartalma

A havi zárás nyomtatás szekciói (HAVIZAR modulból):
1. **Fejléc** — cég, pénztár adatok
2. **Valuta forgalom** — devizanemenkénti bontás (be/ki/nyitó/záró)
3. **HUF forgalom** — forint be/ki/nyitó/záró
4. **Kezelési költség** — havi kezelési díj összesítő
5. **Western Union** — WU tranzakciók összesítője
6. **ÁFA** — külön ÁFÁ-s tételek (Metro, Tesco)
7. **Matrica** — autópálya matrica értékesítés
8. **E-ker** — elektromos kereskedelmi forgalom
9. **OTP terminál** — POS tranzakciók


---

## S27 45_KESZLETKEZELES_ES_CIMLETEZES

### 4.5.1 Címletezés (CIMLET DLL)

A készlet nem csak összeg, hanem címlet szinten is nyilvántartott:

```pascal
// BLOKNYOM/Unit2.pas — CimletBedolgozas
// Bináris fájlból olvassa a címlet adatokat: c:\valuta\aktcim.dat
function TBlokkNyom.CimletBedolgozas: boolean;
begin
  Assignfile(_binolvas,_cimDataPath);
  Reset(_binolvas);
  Blockread(_binolvas,_bytetomb,1);
  _yValDarab := _byteTomb[1];   // Valutanemek száma
  
  while _cc<=_yValdarab do begin
    // 3 byte XOR-kódolt valutanév:
    _vnev := chr(255-_bytetomb[1])+chr(255-_bytetomb[2])+chr(255-_bytetomb[3]);
    _yNev[_cc] := _vNev;
    
    // Címletek száma:
    _vcdb := _bytetomb[1];
    _yCdb[_cc] := _vcdb;
    
    // Címlet-bankjegy párok:
    _p := 1;
    while _p<=_vcdb do begin
      _yC[_cc,_p] := getword;   // Címlet névérték
      _yB[_cc,_p] := getword;   // Bankjegy darabszám
      inc(_p);
    end;
  end;
end;
```

**Bináris címletfájl formátum (aktcim.dat):**
```
[1 byte: valutanemek száma]
  [3 byte: XOR-kódolt valutanév (255-karakter)]
  [1 byte: címletek száma]
    [2 byte: címlet névérték] [2 byte: darabszám]  × N
  [1 byte: 255 elválasztó]
[2 byte: 255+255 lezáró]
```

### 4.5.2 Készletátadás és plombaszám

Pénztárak közötti átadásnál `PLOMBASZAM` kötelező:

```pascal
// BLOKNYOM/Unit2.pas — AtadBlokkNyomtatas
writeLn(_LFile,'SZALLÍTÓ NEVE: ' + _szallitoNev);
writeLn(_LFile,'PLOMBA SZÁMA : ' + _plombaSzam);
```

A plombaszám a fizikai biztonsági lezárás azonosítója — a szállító dokumentum és a fizikai csomag összekapcsolására szolgál.

### 4.5.3 Napi bizonylat-regisztrálás

Minden tranzakció a VTEMP ideiglenes táblán keresztül kerül a havi BF/BT táblákba:

```pascal
// VASARLAS/Unit2.pas — Folytatas (~sor 1300)
BlokkFejIro;          // → BFyymm táblába
BlokktetelIro;        // → BTyymm táblába
KezdijRogzito;        // → KEZDyymm táblába
```


---

## S28 46_REGENERACIO

### 4.6.1 A REGEN modul feladata

A `regeneralorutin` az adatbázis konzisztenciáját állítja helyre — készletek, forgalmi adatok újraszámolása:

```pascal
// VASARLAS/Unit2.pas
regeneralorutin(0);  // 0 = teljes regeneráció
```

Ez kritikus pl. napzárásnál és a nap elején, hogy a készletadatok konzisztensek legyenek.

---

# 5. KÓDMINŐSÉG ÉS KOCKÁZATOK


---

## S29 51_DUPLIKACIO_A_LEGKOMOLYABB_PROBLEMA

### 5.1.1 VASARLAS vs ELADAS duplikáció

A két fő tranzakciós modul (VASARLAS és ELADAS) a kód ~70%-ban azonos, másolással készültek:

**Azonos függvények (teljes másolat):**
- `Kerekito` — 5 Ft-os kerekítés
- `GetKezelesidij` — kezelési díj kalkuláció
- `KezdijTablaBeolvasas` — sávos díjtábla betöltése
- `GetBizonylatszam` — bizonylat sorszám generálás
- `GetDnemAdatok` — devizanem adatok betöltése
- `VanIlyenDnem` — dupla devizanem ellenőrzés
- `GetTetelsor` — tétel sor keresése
- `GetSajatHataskoru` — SHK kedvezmény ellenőrzése
- `Ujraszamolas` — számla újrakalkuláció
- `SorbeirasVtempbe` — VTEMP tábla írás
- `ValtozokNullazasa` — változók nullázása
- `TombBetoltes` — tömb inicializálás
- `TablaNullazas` — tábla nullázás
- `ForintForm` — formázás
- `Elokieg` — string formázás
- `Nulele` — nulla-kiegészítés
- `ArfolyamotModosit` — árfolyam módosítás
- `MakeXml` — XML e-mail generálás
- `XMLBemasolas` — XML FTP-re másolás
- `RemoteLerendezes` — szerver szinkronizáció
- `KisugyfelLerendezes` — kisügyfél adatok frissítése

**Eltérő elemek:**
- `GetDnemAdatok` — VASARLAS a VÉTELI, ELADAS az ELADÁSI árfolyamot olvassa
- Eladásban: `GetTranzdij` extra függvény (kezelési díj kedvezménnyel)
- Eladásban: `KeszletKontrol` — deviza készlet ellenőrzés
- Eladásban: `Getfizetoeszkoz` — fizetőeszköz (készpénz/bankkártya)
- Eladásban: `LimitDisplay`, `MaradtLepteto` — konverzió limites kezelése
- Eladásban: OTP terminál integráció
- Eladásban: `_savos` flag, `SetRate` típus kezelés

**Becslés:** ~3500 sor duplikált kód a két modulban.

### 5.1.2 Kockázat: eltérésbugok

Az ELADAS modulban kikommentezett (`(* ... *)`) sávos díjtábla azt mutatja, hogy volt egy korábbi fix díjstruktúra, ami VASARLAS-ban nincs benne. Ez azt jelenti, hogy a modulok fejlesztése aszinkron történt — az egyik modul frissítése nem mindig tükröződött a másikban.


---

## S30 52_GLOBALIS_ALLAPOTKEZELES

### 5.2.1 Globális változók tömege

Mindkét tranzakciós modul ~150+ globális (unit-szintű) változót használ. Példa a VASARLAS modulból:

```pascal
var
  // 80+ string változó:
  _aktdatum, _aktidos, _aktpenztarszam, _plombaszam, _lastdatum: string;
  _bizonylatszam, _trbpenztar, _ugyfeltipus, _tranzstring, _ugyfelcim: string;
  _megnyitottnap, _adoszam, _irszam, _varos, _utca: string;
  // ... ~60 további string
  
  // 30+ integer változó:
  _kezdijengedmenytip, _kezelesidij, _fixKezelesiDij, _minkezdij: integer;
  _mresult, _origkezdij, _fizetendo, _evimax, _hetift: integer;
  // ... ~20 további integer
  
  // 15+ byte változó:
  _kulfoldi, _lastsor, _ratetype, _tetel, _fizetoeszkoz: byte;
  // ... ~10 további byte
  
  // 10+ boolean változó:
  _ezKonverzio, _ezegyedikezdij, _securlevel: boolean;
  // ... ~7 további boolean
  
  // Tömbök:
  _wd, _wa, _wb: array[1..6] of TEdit;
  _wbankjegy, _wertek: array[1..6] of Integer;
  _kdij: array[1..23] of integer;
  _tranzsav: array[1..23] of integer;
```

### 5.2.2 VTEMP mint globális állapottár

A `VTEMP` tábla az adatbázisban lényegében egy **globális struct/record**:

```
VTEMP tábla mezők (a kódból rekonstruálva):
  DATUM, IDO, TIPUS, KULFOLDI,
  UGYFELTIPUS, UGYFELSZAM, SECURLEVEL,
  NETTO, FIZETENDO, KEZELESIDIJ,
  BIZONYLATSZAM, KONVERZIO, STORNO,
  TETEL, ELOJEL, PENZTARKOD,
  STORNOBIZONYLAT, SZALLITONEV, PLOMBASZAM,
  MEGJEGYZES, COPYINDOK, STORNOINDOK,
  TARSPENZTARNEV, FIZETOESZKOZ,
  RECNUMS, ZCOUNTS, KEREKITES,
  FORRAS, ENGEDELYEZO,
  KEDVEZMENYESARFOLYAM, MEGBIZOSZAM,
  KOZSZEREPLO, KARTYASZAM,
  VALUTANEM, ARFOLYAM, BANKJEGY,
  FORINTERTEK, EREDETIARFOLYAM,
  SORENGEDMENY, ELSZAMOLASIARFOLYAM,
  UGYFELNEV, UGYFELCIM, NEVTABLA,
  SORSZAM, RATETYPE,
  OSSZESFORINTERTEK
```

**Probléma:** Egyetlen globális sor szolgál az összes DLL közötti kommunikációra. Egy DLL felülírja a VTEMP-et, a másik DLL onnan olvassa. Ha bármelyik DLL rosszul ír vagy nem törli a VTEMP-et, az a következő tranzakciót is elronthatja.

```pascal
// VASARLAS/Unit2.pas — FormActivate — mindig törli a VTEMP-et:
ValutaParancs('DELETE FROM VTEMP');
```

### 5.2.3 Adatbázis-alapú IPC (Inter-Process Communication)

A DLL-ek kizárólag adatbázison keresztül kommunikálnak:
1. **Hívó DLL** → VTEMP táblába ír inputot
2. **Hívott DLL** → VTEMP-ből olvas, feldolgoz
3. **Hívott DLL** → VTEMP-be ír outputot
4. **Hívó DLL** → VTEMP-ből olvassa az eredményt

Ez lassú, de megbízható (tranzakcionális), és nem igényel memóriamegosztást a DLL-ek között.


---

## S31 53_BIZTONSAGI_GYENGESEGEK

### 5.3.1 XOR „titkosítás" — NEM valódi védelem

```pascal
// TRADE.EXE — Kodxor
function TForm1.Kodxor(_s: string): string;
begin
  result := '';
  for _y := 1 to length(_s) do begin
    _asc := 255 - ord(_s[_y]);
    result := result + chr(_asc);
  end;
end;
```

Ez egyszerű karakter-invertálás (`255 - c`). Önmagára alkalmazva visszaadja az eredetit → szimmetrikus. **NEM titkosítás**, hanem obfuszkáció. A logfájlok bárki által visszafejthetők.

### 5.3.2 Hardcoded jelszavak és IP címek

```pascal
// A kódban közvetlenül megtalálható:
_host     := '185.43.207.99';      // FTP szerver IP
_ftpPort  := 21100;                 // FTP port
_userid   := 'ebc-10%';            // FTP user
_ftpPass  := 'klc+45%';            // FTP jelszó
_ipcim    := '193.68.57.146';      // Központi szerver IP

// E-mail címek:
'fabulyazsuzsa.eec@gmail.com'
'kosa.zoltan.ebc@gmail.com'
'nagyannamaria.ebc@gmail.com'
'batori.monika.ebc@gmail.com'
```

### 5.3.3 SQL injection sebezhetőség

A kód SEHOL nem használ paraméteres lekérdezést:

```pascal
// Tipikus minta (több száz helyen):
_pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

// String értékeknél:
_pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'!'+chr(39);
// ...WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
```

A `chr(39)` = aposztróf. Ha bármely felhasználói input aposztrófot tartalmaz, az SQL injection lehetséges. **A jelenlegi fenyegetettség alacsony**, mert:
- Helyi Firebird adatbázis (nem hálózaton)
- A beviteli mezők többsége korlátozva van (combo box, szűrt input)
- De: az ügyfélnév, cím, megjegyzés mezők szabadszövegesek

### 5.3.4 Jelszó-kezelés

```pascal
// PROSBE DLL — pénztáros jelszó:
_jelszo := FieldByName('JELSZO').asString;
// Összehasonlítás: JelszoKodolo + Evaulate (hex)
```

A jelszavak a TRADE.FDB `PARAMETERS.JELSZO` mezőben vannak tárolva — nem plaintext, de a „kódolás" feltehetően egyszerű (hex → összehasonlítás), nem bcrypt/PBKDF2 szintű hash.

### 5.3.5 Fix útvonalak

Minden DLL hardcoded `c:\valuta\` útvonalon keresi a fájlokat:

```pascal
function arfolyamkijelzes(_para:string): integer;stdcall; 
  external 'c:\valuta\bin\Arfdisp.dll';
function blokknyomtatas(_para: integer):integer; stdcall; 
  external 'c:\valuta\bin\bloknyom.dll';
// ... minden DLL hivatkozás c:\valuta\bin\*.dll
```

Ez lehetetlenné teszi:
- Többpéldányos telepítést
- Tesztkörnyezet futtatását
- UAC-kompatibilis modern Windows telepítést


---

## S32 54_TESZTELHETOSEG

### 5.4.1 Automatizált tesztek hiánya

A teljes kódbázisban **EGYETLEN** automatizált teszt sincs. Nincs:
- Unit test
- Integrációs teszt
- Regressziós teszt
- UI teszt

### 5.4.2 Tesztelhetőségi akadályok

| Akadály | Leírás | Hatás |
|---------|--------|-------|
| Globális állapot | 150+ globális változó per DLL | Izolált tesztelés lehetetlen |
| Adatbázis-függőség | Minden logika Firebird lekérdezésen alapul | Mock-olás komplex |
| UI-logika összefonódás | Üzleti logika a Form event handlerekben | Headless tesztelés lehetetlen |
| `ShowModal` DLL hívás | Minden DLL modális ablakot nyit | Automatizált futtatás nehéz |
| Fix fájl útvonalak | `c:\valuta\*` hardcoded | Párhuzamos tesztelés lehetetlen |
| Remote szerver függőség | Központi Firebird szerver szükséges | Offline tesztelés lehetetlen |

### 5.4.3 A legtesztelhetőbb komponensek

| Komponens | Tisztaság | Tesztelhetőség |
|-----------|-----------|----------------|
| `Kerekito` | Tiszta függvény (int → int) | ★★★★★ — triviálisan tesztelhető |
| `Betukiemelo` | Tiszta függvény (string → string) | ★★★★★ |
| `ForintForm` | Tiszta függvény (int → string) | ★★★★★ |
| `Elokieg` | Tiszta függvény (string, int → string) | ★★★★★ |
| `GetKezelesidij` | Adatbázis-függő | ★★☆☆☆ |
| `GetTranztip` | Adatbázis + remote | ★☆☆☆☆ |
| Teljes tranzakció | DB + DLL + szerver + nyomtató | ☆☆☆☆☆ |


---

## S33 55_KARBANTARTHATOSAG

### 5.5.1 Kódbázis méret

| Metrika | Érték |
|---------|-------|
| Teljes fájlszám | ~6972 |
| Pascal forrásfájlok | ~420 .pas |
| Form fájlok | ~419 .dfm |
| DLL projektek | ~131 |
| Becsült összesített LOC | ~200.000+ sor |

### 5.5.2 Kódszervezési problémák

1. **Flat struktúra:** Minden DLL egyetlen `Unit2.pas` fájlban van — nincs moduláris szervezés
2. **Névkonvenció:** Magyar + angol keverék, globális változók `_` prefixszel
3. **Kommentelés:** Vegyes — néhány függvény jól kommentelt, mások egyáltalán nincsenek
4. **Error handling:** Minimális — `ShowMessage` + `exit` minta, nincs try/except
5. **Kódolás:** Windows-1250 (magyar ékezetek), ami a kommenteket olvashatatlanná teszi modern editorokban

### 5.5.3 Pozitív kódminőségi elemek

Nem minden rossz:
- **Következetes minta:** Minden DLL azonos architektúrát követ (Create → ShowModal → Free)
- **Naplózás:** A `logirorutin` konzisztensen használt az összes modulban
- **Moduláris építkezés:** A DLL-es felépítés lehetővé tette a független frissítéseket
- **Kommentezett flow:** A VASARLAS/ELADAS modulok a fő folyamatot kommentekkel dokumentálják
- **Fázisokra bontás:** A tranzakció jól definiált fázisokra osztott (bevitel → ellenőrzés → ügyfél → megerősítés → véglegesítés)

---

# 6. JOGSZABÁLYI MEGFELELŐSÉG


---

## S34 61_IMPLEMENTALT_SZABALYOK

### 6.1.1 Pmt. (pénzmosás elleni törvény) — 2017. évi LIII. tv.

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| 300k Ft feletti ügyfél-azonosítás | `securlevel=1` ha `fizetendo>=300000` | ✅ Implementált |
| Kiemelt közszereplő (PEP) kezelés | `_kozszereplo` mező + `KozszerepNyilatkozat` | ✅ Implementált |
| Tényleges tulajdonos azonosítás | `_tulajnevedit[1..4]` + bizonylat nyomtatás | ✅ Implementált |
| Terrorlista szűrés | `TERROR` DLL + `terrorcontrol` | ✅ Implementált |
| Forrás igazolás | `_forras` mező + bizonylat | ✅ Implementált |
| Gyanús tranzakció jelentés | `GetTranztip` + JOURNAL tábla + e-mail | ⚠️ Részben — manuális |
| 4.5M EUR éves limit | `_evimax` mező | ✅ Implementált (8M Ft küszöbbel) |
| Ügyfél-nyilvántartás 8 évig | Szerveren tárolt NEVTABLA | ⚠️ Részben — nincs automatikus törlés |

### 6.1.2 ÁFA törvény — 2007. évi CXVII. tv.

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| Pénzváltás ÁFA-mentessége | Bizonylaton: "86. § e) alapján mentes" | ✅ Korrekt |
| SZJ kód feltüntetés | "Szj - 67.13.10.0" | ✅ Korrekt |
| ÁFÁs számla matrica/telefon | `AfasSzamla`, `TelAfasSzamla` | ✅ Implementált |
| 27% ÁFA tartalom | "21,26% ÁFA-t tartalmaz" (bruttóból) | ✅ Számítás korrekt |

### 6.1.3 Devizatörvény / MNB előírások

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| Vételi/eladási árfolyam megkülönböztetés | `VETELIARFOLYAM` / eladási árf. | ✅ |
| Árfolyam közzététele | `ARFDISP` DLL | ✅ |
| 5 Ft-os kerekítés | `Kerekito` függvény | ✅ |
| Bizonylat kétnyelvű (HU+EN) | Mezők: "Sorszam (INVOICE NR)" stb. | ✅ |
| Napi forgalmi jelentés | `NAPIFORG`, `NAPIJEL` DLL-ek | ✅ |
| Dekádjelentés | `DEKRUTIN` DLL | ✅ |
| Havi zárás | `HAVIZAR` DLL | ✅ |

### 6.1.4 NAV előírások

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| Pénztárgép napi zárás | `QR kód` + `navzarocontrol` | ✅ |
| Nyugtaszámozás | `RECNUMS`/`ZCOUNTS` mezők | ✅ |
| Bizonylat archiválás | Szerveren BF/BT táblákban | ✅ |


---

## S35 62_GDPR_HIANYOSSAGOK

### 6.2.1 Személyes adatok kezelése — problémák

| Probléma | Részletezés | Súlyosság |
|----------|-------------|-----------|
| **Nincs adattörlési mechanizmus** | Az ügyfél adatai a szerveren „örökre" megmaradnak | 🔴 Kritikus |
| **Nincs hozzáférés-korlátozás** | Minden pénztáros minden ügyfél adatát látja | 🔴 Kritikus |
| **Hardcoded e-mail címek** | Személyes e-mailek a forráskódban | 🟡 Közepes |
| **Nincs audit log** | Ki, mikor, milyen ügyfél adatot nézett meg — nem naplózott | 🔴 Kritikus |
| **XOR „titkosítás"** | A napló nem valódi titkosítás | 🟡 Közepes |
| **FTP jelszó plaintext** | FTP hozzáférés hardcoded | 🟡 Közepes |
| **Nincs jogosultságkezelés** | Pénztáros = supervisor → mindenhez hozzáfér | 🔴 Kritikus |
| **Nincs adathordozhatóság** | Ügyfél nem kérheti saját adatainak exportját | 🟡 Közepes |
| **Nincs beleegyezés-kezelés** | Nincs nyilvántartva az ügyfél hozzájárulása | 🔴 Kritikus |

### 6.2.2 Adatmegőrzési idők

A Pmt. szerint az ügyfél-azonosítási adatokat **8 évig** kell megőrizni. A rendszerben:
- **Nincs automatikus törlés** — az adatok korlátlan ideig megmaradnak
- **Nincs archiválási/anonimizálási mechanizmus** az 8 év utáni adatokra
- A `TRADE.EXE` `Archivalo` eljárása csak a régi havi tranzakciós táblákat törli, de az ügyfél-adatokat NEM

### 6.2.3 A szerveren tárolt adatok

A központi szerveren (`193.68.57.146`) tárolt adatok:

```
ANEV..ZNEV  — természetes személyek (név + személyes adatok)
ABIZ..ZBIZ  — bizonylatok személyes hivatkozásokkal
JOGI        — jogi személyek + tulajdonosok
JOGIBIZ     — jogi személy bizonylatok
KISUGYFEL   — egyszerűsített ügyfél adatok
JOURNAL     — terrorlista-szűrési napló
```

Minden adat plaintext, titkosítás nélkül, Firebird adatbázisban.


---

## S36 63_SZANKCIOS_MEGFELELOSEG

### 6.3.1 USD korlátozás

A rendszer implementálja az USA szankciók szerinti USD korlátozást:
- Irán (IR), Észak-Korea (KR), Kuba (CU), Szíria (SY), Dél-Szudán (SS) — USD eladás TILTOTT
- Az ISO országkód alapján ellenőrzi

### 6.3.2 Hiányzó szankciós elemek

| Hiányosság | Leírás |
|------------|--------|
| EU szankciós lista | Nincs integrálva az EU szankciós rendszere |
| OFAC SDN lista | Nincs automatikus frissítés |
| Terrorlista frissítés | A terrorlista karbantartása manuális |
| Szankciós ország bővítés | Csak 5 ország van hardcoded-olva |

---

# 7. MIGRÁCIÓS ÜZLETI SZEMPONTOK


---

## S37 71_MEGORZENDO_UZLETI_LOGIKA_MUST_KEEP

### 7.1.1 Kritikus algoritmusok — változatlan reprodukálandók

| # | Komponens | Forrás | Indoklás |
|---|-----------|--------|----------|
| 1 | **5 Ft-os kerekítés** | `Kerekito` | Törvényi kötelezettség, pénzügyi pontosság |
| 2 | **Kezelési díj kalkuláció** | `GetKezelesidij` | Bevételi modell, ügyfél-ígérvény |
| 3 | **Sávos díjtábla** | `KezdijTablaBeolvasas` + `TRANZDIJTABLA` | Üzleti konfiguráció |
| 4 | **Forintérték számítás** | `round(arf/100*bjgy+0.001)` + JPY | Pénzügyi pontosság |
| 5 | **Tranzakció-típus meghatározás** | `GetTranztip` | AML jogszabályi megfelelőség |
| 6 | **300k küszöb** | `securlevel` logika | Pmt. követelmény |
| 7 | **Ügyfél-egyeztetés** | `NaturUgyfelKereses` (4 mezőből 2) | Ügyfél-nyilvántartás integritás |
| 8 | **Bizonylat tartalom** | Minden `*Nyomtatas` eljárás | Jogi kötelezettség |
| 9 | **Negyedéves/éves kumuláció** | `GetQuoter` + `_evimax` | AML előírás |
| 10 | **Konverzió logika** | VASARLAS→ELADAS lánc | Üzleti funkció |

### 7.1.2 Üzleti szabályok — teljesen dokumentálandók és portálandók

```
PÉNZÜGYI:
  ├── Árfolyam-típusok (vételi, eladási, elszámolási, SHK)
  ├── Kezelési díj (ezrelékes + sávos + maximum plafon)
  ├── 5 Ft-os kerekítés algoritmusa
  ├── JPY speciális kezelés (/10)
  ├── Maximum 6 tétel per bizonylat
  ├── Árfolyam vs. kezelési díj kedvezmény kizáró logika
  ├── SHK napi korlát (5)
  ├── Egyedi kezdij napi korlát (3)
  └── Készletellenőrzés (HUF + deviza)

AML/KYC:
  ├── 3 szintű ügyfél-azonosítás (<100k / 100-300k / 300k+)
  ├── Jogi személy → mindig teljes azonosítás
  ├── Konverziónál összegduplázás
  ├── Heti kumuláció (7 napos ablak)
  ├── Negyedéves 4×25M szabály
  ├── Éves 2×8M szabály
  ├── PEP (közszereplő) kezelés
  ├── Terrorlista szűrés + engedélyezés + regisztráció
  ├── USD szankciós országok tiltás
  └── Forrás-megjelölési kötelezettség

BIZONYLAT:
  ├── Cégcsoport megkülönböztetés (pénztárkód alapján)
  ├── Kétnyelvű (HU/EN) formátum
  ├── ÁFA-mentesség szöveg
  ├── Jogcím nyilatkozat (300k+)
  ├── Közszereplő nyilatkozat
  ├── Forrás megjelölés
  ├── Ügyfél típusonkénti adatok (natur/jogi/kisügyfél)
  ├── Tulajdonos adatok (jogi személynél max 4)
  └── Másolat kezelés (indokkal)
```


---

## S38 72_MODERNIZALANDO_MUST_MODERNIZE

### 7.2.1 Architekturális modernizáció

| Legacy | Modern | Prioritás |
|--------|--------|-----------|
| 110+ DLL (monolitikus-moduláris) | REST API mikroszolgáltatások | 🔴 Kritikus |
| Firebird/InterBase | PostgreSQL | 🔴 Kritikus |
| VTEMP tábla IPC | Memória-alapú állapotkezelés | 🔴 Kritikus |
| Globális változók | Dependency Injection + Service réteg | 🔴 Kritikus |
| Delphi 7 Win32 | Java + React + Electron | 🔴 Kritikus |
| `ShowModal` UI | Async/reactive UI | 🟡 Közepes |
| LPT1 nyomtatás | Modern nyomtató API (PDF/ESC/POS USB) | 🟡 Közepes |
| XOR „titkosítás" | AES-256 + TLS | 🔴 Kritikus |
| Hardcoded jelszavak | Vault/Secret Manager | 🔴 Kritikus |
| SQL string concatenation | Paraméteres lekérdezések (PreparedStatement) | 🔴 Kritikus |

### 7.2.2 Adatmodell modernizáció

| Legacy | Modern |
|--------|--------|
| Betűnkénti névtáblák (ANEV..ZNEV) | Egyetlen CUSTOMER tábla + index |
| Havi dinamikus táblák (TRADyymm, BFyymm) | Particionált táblák vagy JSONB |
| VTEMP átmeneti tábla | Transaction DTO / session state |
| Bináris címletfájl (aktcim.dat) | JSON/DB tábla |
| Fix 6 tételes tömb | Dinamikus lista |

### 7.2.3 Biztonsági modernizáció

| Legacy | Modern |
|--------|--------|
| Supervisor jelszó (egy szint) | RBAC (role-based access control) |
| Nincs audit log | Strukturált audit trail |
| XOR log | Titkosított, tamper-evident napló |
| FTP szinkronizáció | REST API + TLS |
| Nincs GDPR | Adattörlés, anonimizálás, hozzáférés-naplózás |


---

## S39 73_ELHAGYHATO_CAN_DROP

### 7.3.1 Elavult funkciók

| Komponens | Indoklás |
|-----------|----------|
| Mobiltelefon feltöltés (kupon) | A prepaid feltöltés piaca összeomlott |
| VFD vevőkijelző | Modern POS-ban integrált |
| LPT1 nyomtatás | Parallel port nem létezik modern gépen |
| HRK (horvát kuna) kezelés | Horvátország eurozónában 2023 óta |
| Matrica értékesítés | Más csatornákon keresztül |
| `EUA` (euro érme) kategória | Integrálható az EUR-ba |
| FTP szinkronizáció | REST API váltja ki |
| XOR log kódolás | Valódi titkosítás kell |
| Fix `c:\valuta\` útvonalak | Konfigurálható paths |
| Delphi 7 form koordináták | Modern responsive UI |

### 7.3.2 Elavult integrációk

| Integráció | Állapot |
|------------|---------|
| CitySim SIM kártya | Valószínűleg megszűnt |
| Tesco/Metro ÁFA | Vizsgálandó, hogy aktív-e |
| Western Union | Vizsgálandó — WU saját szoftverre válthatott |


---

## S40 74_MIGRACIOS_PRIORITASOK

### 7.4.1 Fázis 1 — Kritikus üzleti logika (Sprint 1-4)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 1 | Kerekítő algoritmus + unit tesztek | Alacsony | Alacsony |
| 2 | Kezelési díj kalkulátor (3 mód) | Közepes | Közepes |
| 3 | Árfolyam-kezelés + devizanem törzs | Közepes | Közepes |
| 4 | Forintérték számítás + JPY | Alacsony | Alacsony |
| 5 | Vételi tranzakció flow | Magas | Magas |
| 6 | Eladási tranzakció flow | Magas | Magas |
| 7 | Konverzió (vétel→eladás) | Magas | Magas |

### 7.4.2 Fázis 2 — AML/KYC (Sprint 5-8)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 8 | Ügyfél-azonosítási szintek (3 tier) | Magas | Közepes |
| 9 | Természetes személy regisztráció | Közepes | Közepes |
| 10 | Jogi személy + tulajdonosok | Közepes | Magas |
| 11 | Tranzakció-típus meghatározás | Magas | Magas |
| 12 | Terrorlista szűrés | Magas | Közepes |
| 13 | Heti/negyedéves/éves kumuláció | Magas | Közepes |
| 14 | PEP kezelés | Közepes | Alacsony |

### 7.4.3 Fázis 3 — Bizonylat és zárás (Sprint 9-12)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 15 | Bizonylat generátor | Közepes | Magas |
| 16 | Napzárás | Magas | Magas |
| 17 | Havi zárás | Magas | Magas |
| 18 | Címletkezelés | Közepes | Közepes |
| 19 | Készletkezelés | Közepes | Közepes |
| 20 | Sztornó (4 típus) | Közepes | Magas |

### 7.4.4 Fázis 4 — Integráció és migráció (Sprint 13-16)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 21 | OTP terminál integráció | Közepes | Közepes |
| 22 | Központi szerver szinkronizáció | Magas | Magas |
| 23 | Átadás-átvétel (pénztárak között) | Közepes | Közepes |
| 24 | GDPR modul (törlés/anonimizálás) | Magas | Közepes |
| 25 | Audit trail | Közepes | Közepes |


---

## S41 75_MIGRACIOS_KOCKAZATOK

### 7.5.1 Legmagasabb kockázatú területek

| # | Kockázat | Hatás | Valószínűség | Mitigáció |
|---|----------|-------|-------------|-----------|
| 1 | **Kerekítési eltérés** | Pénzügyi pontatlansság, ügyfél reklamáció | Közepes | Karakterszintű unit tesztek az eredeti algoritmus alapján |
| 2 | **AML küszöb kihagyás** | Jogszabálysértés, MNB bírság | Magas | 1:1 üzleti szabály reprodukció + regressziós teszt |
| 3 | **Bizonylat formátum eltérés** | NAV/MNB vizsgálati probléma | Közepes | Pixel-pontos összehasonlítás eredeti vs. új bizonylat |
| 4 | **Adatvesztés migráció közben** | Üzleti adatfolytonosság elvesztése | Magas | Párhuzamos üzem 3+ hónapig |
| 5 | **Havi tábla struktúra eltérés** | Zárási hibák | Közepes | Teljes havi ciklus tesztelése |
| 6 | **Konverzió kettős számlázás** | Pénzügyi veszteség | Alacsony | Atomi tranzakció garantálása |

### 7.5.2 Migráció stratégia — javasolt sorrend

```
I. FÁZIS: Alapok
   ├── [1] PostgreSQL adatbázis tervezés (1:1 séma migráció)
   ├── [2] Kerekítő + forintérték + kezelési díj szolgáltatás
   ├── [3] Árfolyam kezelés szolgáltatás
   └── [4] UNIT TESZTEK mindháromra (100% coverage)

II. FÁZIS: Tranzakciók
   ├── [5] Vételi tranzakció API + UI
   ├── [6] Eladási tranzakció API + UI
   ├── [7] Konverzió API + UI
   ├── [8] Sztornó API + UI
   └── [9] INTEGRÁCIÓS TESZTEK (API szint)

III. FÁZIS: AML/KYC
   ├── [10] Ügyfél-nyilvántartás
   ├── [11] 3-szintű azonosítás
   ├── [12] Tranzakció-típus meghatározás
   ├── [13] Terrorlista integráció (EU + OFAC)
   └── [14] PEP + közszereplő kezelés

IV. FÁZIS: Bizonylat + Zárás
   ├── [15] Bizonylat generátor (PDF)
   ├── [16] Napzárás
   ├── [17] Havi zárás
   ├── [18] Címletkezelés
   └── [19] Készlet + átadás-átvétel

V. FÁZIS: Integráció + Go-Live
   ├── [20] OTP POS terminál
   ├── [21] Központi szinkronizáció → REST API
   ├── [22] Párhuzamos üzem (3 hónap)
   └── [23] Go-Live + legacy leállítás
```

---

# FÜGGELÉK


---

## S42 A_SZTORNO_FOLYAMAT_RESZLETES_ELEMZESE_STORNO_DLL

### A.1 Sztornó típusok

A `STORNO` DLL négy bizonylattípust tud sztornózni:

```pascal
// STORNO/Unit2.pas — rádiógombok:
VR: TRadioButton;   // V = Vételi bizonylat sztornó
ER: TRadioButton;   // E = Eladási bizonylat sztornó
UR: TRadioButton;   // U = Átvételi bizonylat sztornó
FR: TRadioButton;   // F = Átadási bizonylat sztornó
```

### A.2 Sztornó bizonylat jelölések a BLOKKFEJ.STORNO mezőben

| STORNO érték | Jelentés |
|-------------|----------|
| 1 | Érvényes, aktív bizonylat |
| 2 | Sztornózott (az eredeti bizonylat) |
| 3 | Sztornó bizonylat (az érvénytelenítő) |

### A.3 Sztornó korlátozás — napi limit

```pascal
// STORNO/Unit2.pas — FormActivate
_napiStorno := FieldByName('NAPISTORNO').asInteger;
// ...
if _napistorno>2 then begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then begin
    Kilepo.Enabled := true;
    exit;
  end;
end;
```

**Üzleti szabály:** Naponta maximum 2 sztornó engedélyezett supervisor jelszó nélkül. A 3. sztornótól supervisor engedély szükséges.

### A.4 Sztornó indokolás

Minden sztornóhoz **kötelező indoklás**:

```pascal
// STORNO/Unit2.pas — IndokEditKeyDown
_stornoIndok := trim(indokedit.Text);
if _stornoindok='' then exit;  // Üres indok → nem engedélyezi
StartGomb.Enabled := true;     // Csak indokkal engedélyezi
```

### A.5 Érvénytelenítés teljes folyamata

Az `Ervenytelenites` eljárás az alábbi lépéseket hajtja végre:

```pascal
// STORNO/Unit2.pas — Ervenytelenites
// 1. Átadás/átvétel sztornónál: NAV QR kód + valuta sztornó
if (_tipus='F') or (_tipus='U') then begin
  EllenTranzakcio;   // NAV pénztárgépben ellentétes tranzakció
  ValutaStorno;      // Készlet visszarendezés
  Exit;
end;

// 2. OTP terminál sztornó (ha bankkártyás fizetés volt):
if _fizetoEszkoz=2 then begin
  if OtpKontrol then 
    _otpOke := OTPTermStorno        // Utolsó bizonylat → sima sztornó
  else 
    _otpOke := OtpAruvisszavet;     // Nem utolsó → áru-visszavét
  if _otpoke<>1 then begin
    ShowMessage('SIKERTELEN OTP-STORNÓ !');
    exit;
  end;
end;

// 3. Kisügyfél sztornó (szerveren összeg csökkentés):
if _ugyftipus='K' then KisUgyfelstorno;

// 4. Nagyügyfél visszagöngyölítés (szerveren bizonylat visszavonás):
if (_ugyftipus<>'K') and (_nevtabla<>'') then GongyoletVissza;

// 5. Normál valuta-sztornó:
Valutastorno;
```

### A.6 ValutaStorno — készlet-visszarendezés

```pascal
// STORNO/Unit2.pas — ValutaStorno (~sor 860)

// Eredeti bizonylat STORNO=2-re állítása:
_pcs := 'UPDATE BLOKKFEJ SET STORNO=2 WHERE BIZONYLATSZAM=...';
_pcs := 'UPDATE BLOKKTETEL SET STORNO=2 WHERE BIZONYLATSZAM=...';

// Új sztornó bizonylat létrehozása (STORNO=3):
_stornoBizonylat := _tipus + _bizelokod + nulele(_blokk, _nLen);
_oft             := trunc(_oft * (-1));       // Előjel megfordítás
_fizetendo       := trunc(_fizetendo * (-1)); // Negatív összeg
_kezdij          := trunc(_kezdij * (-1));    // Negatív díj

// BLOKKFEJ INSERT a sztornó bizonylattal:
'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,...,STORNO,...) VALUES (...,3,...)'

// Tételek negatív előjellel:
_bankjegy    := trunc(_bankjegy * (-1));
_forintertek := trunc(_forintertek * (-1));
'INSERT INTO BLOKKTETEL (...,STORNO,...) VALUES (...,3,...)'

// VTEMP frissítés a blokknyomtatáshoz:
'UPDATE VTEMP SET STORNOBIZONYLAT=...,STORNO=3,...,STORNOINDOK=...'

// Napi sztornó számláló növelése:
inc(_napistorno);
'UPDATE HARDWARE SET NAPISTORNO=' + inttostr(_napistorno)

// Sztornó blokk nyomtatása:
blokknyomtatas(1);
```

### A.7 OTP sztornó vs. áru-visszavét

```pascal
// OTP terminál sztornó — UTOLSÓ bizonylat esetén:
// OTPFUNCTYPE = 100 → terminál sztornó
_pcs := 'INSERT INTO VTEMP (BIZONYLATSZAM,FIZETENDO,OTPFUNCTYPE) VALUES (...,100)';
result := otpterminal;

// OTP áru-visszavét — NEM utolsó bizonylat:
// OTPFUNCTYPE = 4 → áru visszavétel
// + supervisor jelszó szükséges!
_spk := supervisorjelszo(0);
if _spk<>1 then exit;
_pcs := 'INSERT INTO VTEMP (...,OTPFUNCTYPE) VALUES (...,4)';
result := otpterminal;
```

### A.8 Kisügyfél sztornó — szerveren

```pascal
// STORNO/Unit2.pas — KisUgyfelStorno
// A kisügyfél szerveren lévő kumulált összegéből levonja:
remotedbase.DatabaseName := _host+':c:\receptor\database\kisugyfel.fdb';
_edosszeg := FieldByName('OSSZEG').asInteger;
_ujosszeg := _edosszeg - _fizetendo;
if _ujosszeg < 0 then _ujOsszeg := 0;
'UPDATE ' + _nevtabla + ' SET OSSZEG=' + inttostr(_ujOsszeg)
```

### A.9 Göngyölítés visszavonása — szerveren

A `GongyoletVissza` a szerveren regisztrált nagyügyfél tranzakciót vonja vissza:

```pascal
// A plombaszám tartalmazza a névtáblát és sorszámot:
_nevtabla := leftstr(_plombaszam, 4);  // pl. 'ANEV'
_sorszam  := midstr(_plombaszam, 5, ...);
// VTEMP-be írja az adatokat, majd:
gongyvisszavonas;  // Extern DLL hívás
```


---

## S43 B_NAPLOZAS_ES_AUDIT_LOGIRO_DLL

### B.1 Naplózási minta

Minden DLL a `logirorutin` eljárást használja naplózásra:

```pascal
// Hívási minták:
logirorutin(pchar('Devizavásárlás indul'));
logirorutin(pchar('Fizetendő: ' + inttostr(_fizetendo)));
logirorutin(pchar('Egyedi kezdij lehetőség ' + inttostr(3-_negykezdij) + ' maradt'));
logirorutin(pchar('A terrorlistán szereplés miatt a tranzakció letiltva !'));
logirorutin(pchar('A terrorlista ellenére engedélyezték a tranzakciót'));
```

A napló XOR-kódolva (255-c) mentésre kerül a `c:\valuta\temp\` könyvtárba. A naplófájl neve: `AKTLST.TXT`.

### B.2 Napló integritási probléma

A `SetLogFile` függvény a nap elején inicializálja a naplót, de:
- **Nincs idő-pecsét** az egyes bejegyzéseknél (csak szöveg)
- **Nincs hash/HMAC** — a napló manipulálható
- **Nincs rotáció** — a fájl korlátlanul nőhet
- **A XOR kódolás visszafejthető** — bárki elolvashatja


---

## S44 C_DLL_KOMMUNIKACIOS_PROTOKOLL_RESZLETES_ADATFOLYAM

### C.1 Vásárlás teljes adatfolyam

```
TRADE.EXE                      VASARLAS.DLL
    │                               │
    │──── VTEMP törlése ───────────►│ DELETE FROM VTEMP
    │                               │
    │──── DLL hívás ───────────────►│ vasarlasrutin() → ShowModal
    │                               │
    │                               │ ◄── ARFOLYAM tábla olvasás
    │                               │ ◄── HARDWARE tábla olvasás
    │                               │ ◄── PENZTAR tábla olvasás
    │                               │ ◄── TRANZDIJTABLA olvasás
    │                               │
    │                               │ ──► VTEMP sorok írása (max 6)
    │                               │
    │                               │ ──► kisarfolyamkedvezmeny DLL
    │                               │ ──► bigarfolyamkedvezmeny DLL
    │                               │ ──► kezdijkedvezmeny DLL
    │                               │
    │                               │ ──► ugyfelcontrol DLL
    │                               │     └── terrorcontrol DLL
    │                               │     └── kisugyfel DLL
    │                               │     └── bigcontrol DLL
    │                               │         └── getkiemeltstatusz DLL
    │                               │
    │                               │ ──► blokknyomtatas DLL
    │                               │ ──► confirmrutin DLL
    │                               │
    │                               │ ──► BLOKKFEJ INSERT
    │                               │ ──► BLOKKTETEL INSERT
    │                               │ ──► ARFOLYAM UPDATE (készlet)
    │                               │
    │◄──── visszatérési kód ────────│ _mResult
    │                               │
    │──── VTEMP olvasás ───────────►│ (eredmények)
    │                               │
```

### C.2 DLL hívási mélység

A leghosszabb DLL hívási lánc:

```
TRADE.EXE
  └── VASARLAS.DLL (vasarlasrutin)
       └── BIGARFVALT.DLL (bigarfolyamkedvezmeny)
       └── UGYFEL.DLL (ugyfelcontrol)
            └── KISUGYFEL.DLL (kisugyfel)
            └── BIGCTRL.DLL (bigcontrol)
                 └── GETSTATUS.DLL (getkiemeltstatusz)
                 └── SUPER.DLL (supervisorjelszo)
            └── TERROR.DLL (terrorcontrol)
       └── CONFIRM.DLL (confirmrutin)
       └── BLOKNYOM.DLL (blokknyomtatas)
       └── COPY2FTP.DLL (xmlbemasolas)
```

Maximum **4 szint mély** DLL lánc.


---

## S45 D_ADATBAZIS_SEMA_OSSZEFOGLALO

### D.1 Fő adatbázis (valuta.fdb) — lokális

| Tábla | Funkció |
|-------|---------|
| `ARFOLYAM` | Devizanem árfolyamok + készlet |
| `BLOKKFEJ` | Bizonylat fejlécek (napi) |
| `BLOKKTETEL` | Bizonylat tételsorok (napi) |
| `HARDWARE` | Pénztárgép konfiguráció + státusz |
| `PARAMETERS` | Rendszerbeállítások + jelszavak |
| `PENZTAR` | Pénztár törzsadatok |
| `TRANZDIJTABLA` | Sávos kezelési díj tábla |
| `UGYFEL` | Természetes személy ügyfélnyilvántartás (lokális) |
| `JOGISZEMELY` | Jogi személy nyilvántartás (lokális) |
| `UTOLSOBLOKKOK` | Bizonylat sorszám számlálók |
| `VTEMP` | Átmeneti adatcsere tábla (DLL IPC) |
| `QRPARAMS` | NAV pénztárgép QR paraméterek |

### D.2 Trade adatbázis (trade.fdb) — lokális

| Tábla minta | Funkció |
|-------------|---------|
| `TRADyymm` | Havi tranzakciók |
| `BFyymm` | Havi blokkfejek |
| `BTyymm` | Havi blokktételek |
| `KEZDyymm` | Havi kezelési díjak |
| `HZyymm` | Havi záró készletek |
| `NARFyymm` | Napi árfolyamok (havi) |
| `WCIMTARyymm` | Western Union címtár |
| `CIMTARyymm` | Címletezés havi |

### D.3 Remote adatbázis (193.68.57.146) — központi szerver

| Adatbázis | Funkció |
|-----------|---------|
| `UGYFELyy.FDB` | Központi ügyfél-nyilvántartás (éves) |
| `kisugyfel.fdb` | Egyszerűsített ügyfél adatbázis |
| `remotedbase` | Szinkronizációs kapcsolat |

### D.4 Központi szerver táblaszerkezet

| Tábla | Funkció |
|-------|---------|
| `ANEV..ZNEV` | Természetes személyek betű szerint |
| `ABIZ..ZBIZ` | Bizonylatok betű szerint |
| `JOGI` | Jogi személyek |
| `JOGIBIZ` | Jogi személy bizonylatok |
| `JOURNAL` | Terrorlista-szűrési napló |


---

## S46 E_OSSZESITETT_KOCKAZATI_MATRIX

| # | Kockázat | Valószínűség | Hatás | Prioritás |
|---|----------|-------------|-------|-----------|
| 1 | SQL injection ügyfélnév mezőn | Alacsony | Magas | 🟡 |
| 2 | Hardcoded FTP jelszó kiszivárgás | Közepes | Magas | 🔴 |
| 3 | XOR log visszafejtése | Magas | Közepes | 🟡 |
| 4 | GDPR adatkérés (törlés/export) teljesíthetetlen | Magas | Magas | 🔴 |
| 5 | Terrorlista nem naprakész | Közepes | Magas | 🔴 |
| 6 | Szankciós ország lista nem teljes | Közepes | Magas | 🔴 |
| 7 | Kerekítési hiba negatív összegnél | Alacsony | Közepes | 🟡 |
| 8 | VTEMP-ben maradt adat (DLL crash) | Alacsony | Közepes | 🟡 |
| 9 | Egyidejű DLL hívás (VTEMP race condition) | Nagyon alacsony | Magas | 🟢 |
| 10 | Firebird adatbázis korrupció (áramszünet) | Alacsony | Nagyon magas | 🟡 |
| 11 | Központi szerver elérhetetlen | Közepes | Magas | 🔴 |
| 12 | Jelszó bruteforce (egyszerű kódolás) | Alacsony | Közepes | 🟡 |


---

## S47 F_AJANLASOK_OSSZEFOGLALASA

### F.1 Azonnali teendők (migráció előtt)

1. **FTP jelszó cseréje** és konfigurációs fájlba helyezése
2. **Terrorlista frissítés** automatizálása
3. **Szankciós lista bővítése** (EU + OFAC teljes)
4. **GDPR adatkezelési tájékoztató** megalkotása
5. **Naplózás megerősítése** — timestamp, hash

### F.2 Migráció során kötelező

1. **100% unit teszt lefedettség** a kerekítési, díjszámítási és AML algoritmusokra
2. **Párhuzamos üzem** — minimum 3 havi bizonylat-összehasonlítás
3. **Bizonylat pixel-pontos egyeztetés** — eredeti vs. modern
4. **Teljes AML szabálykatalógus** reprodukciója és auditálása
5. **RBAC jogosultságkezelés** a pénztáros/supervisor/admin szinteken
6. **Paraméteres SQL** mindenhol
7. **TLS titkosítás** a központi szerver felé

### F.3 Migráció után

1. **Legacy rendszer fokozatos leállítása** — csak teljes párhuzamos validáció után
2. **Adatmigráció** — betűnkénti névtáblák → egyetlen tábla
3. **Havi tábla struktúra** → particionált PostgreSQL tábla
4. **Audit trail** — minden művelet naplózva, GDPR-konform
5. **Automatikus adattörlés** — 8 év + 1 nap után

---

> **Dokumentum vége**
> Készítette: Eszter (Controller Chief) — 2026-04-02
> Forrás: `D:\repo\valutavalto-program\Anti\VALUTA\` forráskód közvetlen elemzése
> Módszer: Reverse engineering + üzleti logika feltárás + kockázatelemzés
> Terjedelem: ~2200 sor, 7 fókuszterület lefedve