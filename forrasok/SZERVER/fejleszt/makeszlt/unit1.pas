unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, wininet, idGlobal, StdCtrls, ComCtrls, StrUtils, jpeg,
  Comobj, Buttons;

type
  TForm1 = class(TForm)
    Indito: TTimer;
    Csik  : TProgressBar;
    Shape1: TShape;
    Label2: TLabel;
    Shape2: TShape;
    Shape3: TShape;
    CIMPANEL: TPanel;
    KILEPOGOMB: TBitBtn;
    alcimpanel: TPanel;
    FASTCSIK: TProgressBar;
    Label1: TLabel;
    Shape4: TShape;
    Image1: TImage;
    Shape5: TShape;
    Label3: TLabel;
    Label4: TLabel;
    Image2: TImage;

  procedure FormActivate(Sender: TObject);
  procedure InditoTimer(Sender: TObject);
  function GetInteger: integer;
  function Getfbyte: byte;
  function GetFoglalodnemSorszam(_dd: string): byte;

  procedure KILEPOGOMBClick(Sender: TObject);
  procedure AdatNullazo;
  procedure AdatOsszesites;
  procedure MakeExcelTabla;
  procedure RangeKozepre(_rr: string);
  procedure KorzetExcelFejlec;
  procedure ExcelAdatFeltoltes;
  procedure KorzetOsszesenExcel;
  procedure KftOsszesenExcel;
  procedure FoglalokBedolgozasa;
  procedure AcAdatOsszesites;

  //  function AcEvaulate(_pkFile: string): boolean;
//  function AcScanIroda(_isz: byte): byte;

  function AcPkBeolvasasa(_kefornev: string):boolean;

  procedure RangefontKeszlet(_rstr,_fnev: string;_fsize: byte;_bold,_italic: boolean);

  function DarabDekod: integer;
  function DnemDekod: string;
  function FTForm(_num: integer; _dim: string): string;
  function GetByte: byte;
  function GetOszlopBetu(_oo: integer): string;
  function GetString: string;
  function ScanDnem(_dn: string): integer;
  function ScanKorzet(_kz: integer): integer;
  function VanInternet: boolean;
  function Nulele(_int: integer):string;
  function IrodaDatLetoltes: boolean;
  function IrodadatBeolvasas: boolean;
  function KeforLetoltes: boolean;
  function KeforTempBeolvasasa(_kefornev: string):boolean;
  function GetfString: string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _hNet,_hFTP,_hSearch,_hFile: HINTERNET;
  _findData: WIN32_FIND_DATA;

  _valutanemek: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF',
           'CNY','CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK',
           'NZD','PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');

  _valutanevek: array[1..27] of string = ('AUSZTRÁL DOLLÁR','BOSNYÁK MÁRKA',
            'BOLGÁR LEVA','BRAZIL REÁL','KANADAI DOLLÁR','SVÁJCI FRANK',
            'KINAI YUAN','CSEH KORONA','DÁN KORONA','EURÓ','ANGOL FONT',
            'HORVÁT KUNA','MAGYAR FORINT','IZRAELI SHAKEL','JAPÁN YEN',
            'MEXIKÓI PESO','NORVÉG KORONA','ÚJ-ZÉLANDI DOLLÁR','LENGYEL ZLOTYI',
            'ROMÁN LEJ','SZERB DINÁR','OROSZ RUBEL','SVÉD KORONA','THAI BAHT',
            'TÖRÖK LIRA','UKRÁN HRIVNYA','AMERIKAI DOLLÁR');

  _korzetszamok: array[1..9] of byte = (10,20,40,50,63,75,120,145,0);
  _korzetnevek : array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT','DEBRECEN',
             'NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXCLUSIVE CHANGE');

  _pillname  : array[0..150] of string;
  _acPillName: array[1..20] of string;

  _hiword: lpdword;
  _filemeret,_beolvasva: dword;
  _ext,_acdir: string;
  _irodanum,_pkIndex: byte;

  // ---------------------------------------------------------------------------

  // Az Exclusive Change irodái:

  _irodadarab      : byte;                     // ennyi váltóiroda van (a zártakkal együtt)
  _irodanev        : array[1..150] of string;  // az összes iroda neve

  // Expressz minibank pénztárai (az összes):

  _acirodadarab    : byte;
  _acirodanev      : array[1..20] of string;   // (index = pénztárszám-150)
  _acpksor         : array[1..20] of byte;     //

  // Körzetben lévõ pénztárak:

  _korzetptdb      : array[1..9] of integer;        // ennyi ptár adata jött be körzetenként
  _korzetptsor     : array[1..9,1..40] of integer;  // körzetekben lévõ irodaszámok

  _foglalodnem   : array[0..4] of string = ('HUF','CHF','EUR','GBP','USD');

  // Pénztárak adatai:

  _ptKeszlet     : array[1..150,1..27] of integer; // Az élõirodák valutakészletei
  _ptKeszletFt   : array[1..150,1..27] of integer; // A fenti adat forintértéke
  _ptFoglalo     : array[1..150,0..4]  of integer;  // A lehetséges 5 foglalÓ ÉRTÉKE
  _ptVetel       : array[1..150,1..27] of integer; // Mai vételek (valutánként)
  _ptvetelft     : array[1..150,1..27] of integer; // Mai vételek forintértéke (valutánként)
  _ptEladas      : array[1..150,1..27] of integer; // Mai eladások( valutánként)
  _ptEladasft    : array[1..150,1..27] of integer; // Mai eladások ft értéka (valutánként)

  _ptWusd        : array[1..150] of integer;     // egy pénztár W.U. Usd készletei
  _ptWhuf        : array[1..150] of integer;
  _ptWafa        : array[1..150] of integer;
  _ptWKezdij     : array[1..150] of integer;
  _ptWeker       : array[1..150] of integer;
  _ptDatum       : array[1..150] of string;
  _ptIdo         : array[1..150] of string;

  // Expressz tömbök:

  _acKeszlet     : array[0..20,1..27] of integer;  // Az élõirodák valutakészletei
  _acKeszletFt   : array[0..20,1..27] of integer;  // A fenti adat forintértéke
  _acFoglalo     : array[0..20,0..4]  of integer; // A lehetséges 5 foglalÓ ÉRTÉKE
  _acVetel       : array[0..20,1..27] of integer;  // Mai vételek (valutánként)
  _acvetelft     : array[0..20,1..27] of integer;  // Mai vételek forintértéke (valutánként)
  _acEladas      : array[0..20,1..27] of integer;  // Mai eladások( valutánként)
  _acEladasft    : array[0..20,1..27] of integer;  // Mai eladások ft értéka (valutánként)

  _acWusd        : array[0..20] of integer;     // egy pénztár W.U. Usd készletei
  _acWhuf        : array[0..20] of integer;
  _acWKezdij     : array[0..20] of integer;
  _acDatum       : array[0..20] of string;
  _acIdo         : array[0..20] of string;

  // Körzetek adatai:

  _ktKeszlet     : array[1..8,1..27] of integer; // A körzetek valutakészletei
  _ktKeszletFt   : array[1..8,1..27] of integer; // A fenti adat forintértéke
  _ktFoglalo     : array[1..8,0..4]  of integer; // A körzet foglalói
  _ktVetel       : array[1..8,1..27] of integer; // Mai vételek (valutánként)
  _ktvetelft     : array[1..8,1..27] of integer; // Mai vételek forintértéke (valutánként)
  _ktEladas      : array[1..8,1..27] of integer; // Mai eladások( valutánként)
  _ktEladasft    : array[1..8,1..27] of integer; // Mai eladások ft értéka (valutánként)

  _ktWusd        : array[1..8] of integer;  // A korzetek Western Union Usd készletei
  _ktWhuf        : array[1..8] of integer;
  _ktwafa        : array[1..8] of integer;
  _ktWkezdij     : array[1..8] of integer;
  _ktweker       : array[1..8] of integer;

  // A teljes cég adatai:

  _ttKeszlet     : array[1..27] of integer; // Az összes valutakészlet
  _ttKeszletFt   : array[1..27] of integer; // A fenti adat forintértéke
  _ttfoglalo     : array[0..4]  of integer; // A clg foglalói
  _ttVetel       : array[1..27] of integer; // Mai vételek (valutánként)
  _ttvetelft     : array[1..27] of integer; // Mai vételek forintértéke (valutánként)
  _ttEladas      : array[1..27] of integer; // Mai eladások( valutánként)
  _ttEladasft    : array[1..27] of integer; // Mai eladások ft értéka (valutánként)

  _ttWusd        : integer;     // A cég összes W.U. Usd készlete
  _ttwhuf        : integer;
  _ttwafa        : integer;
  _ttwkezdij     : integer;
  _ttweker       : integer;

  _wNev: array[0..5] of string = ('WESTERN UNION (USD)','WESTERN UNION (HUF)',
             'ÁFA','KEZELÉSI DÍJ','ELEKT. KERESKEDÉS','FOGLALÓK');

  // ---------------------------------------------------------------------------

  _tempKorzetszam,_acIrodaIndex,_aktirodaNum: byte;
  _tempPenztarszam: byte;
  _tempdatum,_tempido: string;

  _tempkeszlet    : array[1..27] of integer;
  _tempkeszletFt  : array[1..27] of integer;
  _tempfoglalo    : array[0..4]  of integer;
  _tempvetel      : array[1..27] of integer;
  _tempVetelFt    : array[1..27] of Integer;
  _tempeladas     : array[1..27] of integer;
  _tempeladasFt   : array[1..27] of integer;

  _tempWusd       : integer;
  _tempwhuf       : integer;
  _tempwafa       : integer;
  _tempwkezdij    : integer;
  _tempweker      : integer;

  // ---------------------------------------------------------------------------

  _ftpPort    : integer = 21100;
  _host       : string = '185.43.207.99';
  _userId     : string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';

  _bytetomb   : array[1..65535] of byte;
  _srec: Tsearchrec;

  // ---------------------------------------------------------------------------

  _acptindex,
  _acptnum,
  _pev,
  _pho,
  _pnap,
  _pora,
  _pperc: byte;

  // ---------------------------------------------------------------------------

  _acPkFileDarab,
  _aktf,
  _aktidokod,
  _akteker,
  _akteladas,
  _akteladasft,
  _aktkeszletft,
  _aktkezdij,
  _aktirodaDarab,
  _aktkeszlet,
  _aktkorzetdarab,
  _aktkorzeteladas,
  _aktkorzeteladasft,
  _aktkorzetkeszlet,
  _aktkorzetkeszletft,
  _aktkorzetss,
  _aktkorzetvetel,
  _aktkorzetvetelFt,
  _aktoszlop,
  _aktpenztar,
  _aktsor,
  _aktvetel,
  _aktvetelft,
  _aktwusd,
  _aktwhuf,
  _aktwafa,
  _cc,
  _code,
  _fileIndex,
  _height,
  _ii,
  _irss,
  _jj,
  _kithossz,
  _kodpointer,
  _korzetIndex,
  _korzetszam,
  _kosz,
  _ksumeladasFt,
  _ksumforint,
  _ksumvetelft,
  _left,
  _meret,
  _oszlopDarab,
  _pkFiledarab,
  _ptarindex,
  _ptsorindex,
  _qq,
  _sumeker,
  _sumeladasft,
  _sumforint,
  _sumkezdij,
  _sumvetelft,
  _sumwusd,
  _sumwafa,
  _sumwhuf,
  _top,
  _valutaindex,
  _vv,
  _width,
  _xOszlop,
  _xsor,
  _xx: integer;

  _sikeres,_ezac,_vanfoglalo: boolean;

  _binolvas,_biniras: file of byte;

  _oxl,
  _owb,
  _range: OleVariant;

  _aktIrodaszam,
  _koszlop,
  _x,
  _ksor: byte;

  _aktdnem,
  _aktertekstring,
  _aktfilenev,
  _aktfilePath,
  _aktirodanev,
  _aktktszfile,
  _aktpillFile,
  _aktPillPath,
  _datums,
  _fogs,
  _formula,
  _irszams,
  _kbetu,
  _kiterjesztes,
  _kits,
  _ktszfile,
  _lastletter,
  _localFile,
  _localPath,
  _mamas,
  _pdatum,
  _pido,
  _rangeStr,
  _remoteFile,
  _text,
  _times,
  _vbetu,
  _workdir: string;


implementation

uses Unit2, Unit3;


{$R *.dfm}

// =============================================================================
            procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin

  // Képernyö beállitása:

  _width := Screen.Monitors[0].Width;
  _height:= Screen.Monitors[0].Height;
  _left  := Trunc((_width-710)/2);
  _top   := Trunc((_height-430)/2);

  _mamas := leftstr(datetostr(date),10);

  Top := _top;
  Left := _left;

  KilepoGomb.visible := False;

  _workDir := GetCurrentDir;
  _acdir := _workdir + '\AC';
  if not DirectoryExists(_acdir) then CreateDir(_acdir);
  Indito.Enabled := True;
end;

// =============================================================================
                       procedure TForm1.InditoTimer(Sender: TObject);
// =============================================================================
//                         program Start

var i,_y: integer;

begin
  Indito.Enabled := False;
  Form1.Repaint;

  CimPanel.Caption := 'ADATOK LETÖLTÉSE A SZERVERRÕL';
  Cimpanel.Repaint;

  // ---------------------------------------------------------------------------
  Csik.Position := 10;
  if not IrodadatBeolvasas then
    begin
      ShowMessage('AZ ADATOKAT NEM SIKERÜLT LETÖLTENI - MUNKA NEM LEHETSÉGES');
      Application.Terminate;
      exit;
    end;

  Csik.Position := 20;
  AlcimPanel.Caption := 'Adatfile-ok letöltése';
  Alcimpanel.Repaint;

  // ----------------- a PKppp.ééé az összese 0000ltése ------------------------

  if not KeforLetoltes then
    begin
      ShowMessage('NEM SIKERÜLT EGYETLEN ADATFILET SEM LETÖLTENI A SZERVERRÕL');
      Application.Terminate;
      exit;
    end;

  Csik.Position := 30;
  Alcimpanel.Caption := 'Pillanatnyi készletek letöltve';

  // ---------------------------------------------------------------------------

  Cimpanel.caption := 'AZ ADATOK ALAPÉRTÉKRE ÁLLITÁSA';
  Cimpanel.Repaint;

  AdatNullazo;
  Csik.Position := 40;

  //----------------------------------------------------------------------------

  Cimpanel.Caption := 'AZ ADATOK FELDOLGOZÁSA';
  Cimpanel.Repaint;

  Foglalokbedolgozasa;
  Csik.Position := 45;


  // Bedolgozza az összes letöltött PK file-t:

  _fileindex := 0;
  Fastcsik.Max := _pkFileDarab;
  while _fileindex<_pkFiledarab do
    begin
      Fastcsik.Position := _fileIndex;
      _aktpillfile := _pillname[_fileindex];
      if  KeforTempBeolvasasa(_aktPillFile) then
        begin
          // A pénztár besorolása:

           if _tempKorzetszam>0 then
             begin

               _korzetIndex := ScanKorzet(_tempKorzetSzam);
               _ptsorIndex  := _korzetptdb[_korzetIndex] + 1;
               _korzetptdb[_korzetIndex] := _ptsorindex;
               _korzetPtsor[_korzetIndex,_ptsorindex] := _tempPenztarSzam;

               _valutaindex := 1;
               while _valutaIndex<=27 do
                 begin
                   _ptKeszlet[_tempPenztarszam,_valutaIndex]   := _ptKeszlet[_tempPenztarSzam,_valutaindex]   + _tempKeszlet[_valutaIndex];
                   _ptKeszletFt[_tempPenztarszam,_valutaIndex] := _ptKeszletFt[_tempPenztarSzam,_valutaindex] + _tempKeszletFt[_valutaIndex];
                   _ptVetel[_tempPenztarszam,_valutaIndex]     := _ptVetel[_tempPenztarSzam,_valutaIndex]     + _tempVetel[_valutaIndex];
                   _ptVetelFt[_tempPenztarszam,_valutaIndex]   := _ptVetelFt[_tempPenztarSzam,_valutaindex]   + _tempVetelFt[_valutaindex];
                   _ptEladas[_tempPenztarszam,_valutaIndex]    := _ptEladas[_tempPenztarSzam,_valutaindex]    + _tempEladas[_valutaindex];
                   _ptEladasFt[_tempPenztarszam,_valutaindex]  := _ptEladasFt[_tempPenztarSzam,_valutaindex]  + _tempEladasFt[_valutaindex];
                   inc(_ValutaIndex);
                 end;

               _ptWusd[_tempPenztarszam]    := _ptWusd[_tempPenztarszam]    + _tempWusd;
               _ptWHuf[_tempPenztarszam]    := _ptWHuf[_tempPenztarszam]    + _tempWHuf;
               _ptWAfa[_tempPenztarszam]    := _ptWAfa[_tempPenztarszam]    + _tempWAfa;
               _ptWKezdij[_tempPenztarszam] := _ptWKezdij[_tempPenztarszam] + _tempWKezdij;
               _ptWEker[_tempPenztarszam]   := _ptWEker[_tempPenztarszam]   + _tempWeker;

               _ptDatum[_tempPenztarszam]   := _tempdatum;
               _ptIdo[_tempPenztarszam]     := _tempIdo;
             end;
        end;
      inc(_fileindex);
    end;

  // --------------------- AZ ARTCASH FILEOK BEDOLGOZÁSA -----------------------

  _PkIndex := 1;
  while _pkIndex<=_acPkFileDarab do
    begin
      _aktPillFile := _acPillName[_pkIndex];
      if  AcpkBeolvasasa(_aktPillFile) then
        begin

          _y := 1;
          while _y<=27 do
            begin
              _acKeszlet[_PKIndex,_y]  := _tempKeszlet[_y];
              _acKeszletFt[_pkIndex,_y]:= _tempKeszletFt[_y];
              _acVetel[_pkIndex,_y]    := _tempVetel[_y];
              _acVetelFt[_pkIndex,_y]  := _tempVetelFt[_y];
              _acEladas[_pkIndex,_y]   := _tempEladas[_y];
              _acEladasFt[_pkIndex,_y] := _tempEladasFt[_y];
              inc(_y);
            end;

          _acWusd[_pkIndex]   := _tempWUSd;
          _acWhuf[_pkIndex]   := _tempWHUF;
          _acWKezdij[_pkIndex]:= _tempwKezdij;
          _acDatum[_pkIndex]  := _tempDatum;
          _acIdo[_pkIndex]    := _tempido;
        end;

      inc(_pkIndex);
    end;

  // -------------- Itt az összes PK - file be van dolgozva --------------------

  Cimpanel.Caption := 'AZ ADATOK ÖSSZESITÉSE';
  Cimpanel.Repaint;

  AdatOsszesites;
  AcAdatOsszesites;

  Csik.Position := 50;
  Csik.Repaint;

  // ---------------- A cégösszesitõ táblája miatti változók  ------------------

  _korzetPtdb[9] := 8;
  for i := 1 to 8 do _korzetptsor[9,i] := _korzetszamok[i];


  // --------- ADATOK BEDOLGOZÁSA ----------------------------------------------

  Cimpanel.Caption := 'AZ EXCEL-TÁBLA ELKÉSZÍTÉSE';
  Cimpanel.Repaint;

  MakeExcelTabla;
//  AcExcelTabla.showmodal;
  ExpressExcel.showModal;
  Csik.Position := 100;
  sleep(1500);
  _oxl.visible := True;

  Cimpanel.Caption   := 'AZ EXCELTÁBLA BEZÁRVA';
  Cimpanel.repaint;
  sleep(1700);
  Cimpanel.Visible := False;
  AlcimPanel.Visible := false;
  Csik.Visible := false;
  FAstcsik.Visible := false;
  Kilepogomb.Visible := True;
end;


// =============================================================================
     function TForm1.KeforTempBeolvasasa(_kefornev: string):boolean;
// =============================================================================

var _pointindex,_irszamlen,_cc,_valutadarab: byte;

begin
  (*
  - Az aktuális file neve: _Kefornev
  _ktsznev: 'pk128.120  = 120 ÉRTÉKTÁR, 128-AS PÉNZTÁR

        ========================================================================
          1. byte = evtized
          2. byte = hónap
          3. byte = nap
          4. byte = óra
          5. byte = perc + 100
          6. byte = konstans 27 -> valutadarab
          --------------------- ciklus 1-tõl valutadarabig ---------------------
               Egy valuta 26 byte
                    1-2 byte: valutanem kód
                    3-6 byte: pillanatnyi készlet
                   7-10 byte: keszlet forint
                  11-14 byte: vétel
                  15-18 byte: vétel forint
                  19-22 byte: eladás
                  23-26 byte. eladas forint
          --------------------- ciklus láb -------------------------------------
                  1-4 byte: wu. usd
                  5-8 byte: wu. huf
                 9-12 byte: afa forint
                13-16 byte: kezelési dij
                17-20 byte: elektronikus kereskedés
                21-24 byte: foglaló
                25-26 byte: 255-255-255
            Teljes hossz: 659 byte
           =====================================================================

   - kefornev alapjan meghatározza: _aktpenztar, _aktkörzet integereket

   - _aktkorzetvaltodb = _korzetvaltodarab[_aktkorzet];
   - inc(_aktkorzetvaltodb)
   - _korzetvaltodarab[_aktkorzet]:=_aktkorzetvaltodb;

   - _valtosor[_aktkorzet,_aktkorzetvaltodb] := _aktpenztar;
   - inc(_eloirodadarab);
   - _eloirodasor[_eloirodadarab] := aktpenztar;

   - ktsz.dat megnyitása
   - valutadarabByte kiolvasása
   - ciklus indul 1-tõl valutaDarabByte-ig
         - valutanem, és bankjegy bolvasva
         - valutasorszam -> _Valss
         - _valutaKeszlet[_eloirodadarab,_valss] = Bnkjegy
         - következö valuta
   - ciklus láb:
   - ktsz.dat zárása és törlése
  *)

  // Paraméter: _kefornev (Pl: 'Pk118.120' = 118. pénztár, a 120-as körzetben)

  result := False;

  _kiterjesztes := extractfileExt(_kefornev);            // '.120'
  _kithossz     := length(_kiterjesztes);                // 4
  _kits         := midstr(_kiterjesztes,2,_kithossz-1);  // '120'

  val(_kits,_tempkorzetszam,_code);                           // = 120
  if _code<>0 then exit;

  _irszams    := midstr(_kefornev,3,3);            // = '118'
  val(_irszams,_temppenztarszam,_code);                       // = 118
  if (_code<>0) or (_tempPenztarszam>150) then exit;

  _aktfilePath := _workdir + '\' + _kefornev;       // 'c:\munka\PK118.120'


  AssignFile(_binolvas,_aktFilePath);           // 'c:\munka\pk118.120'
  Reset(_binolvas);

  _meret := FileSize(_binolvas);

  Blockread(_binolvas,_bytetomb,_MERET);
  CloseFile(_binolvas);

  // ---------------------------------------------------------------------------

  _pev    := _bytetomb[1];
  _pho    := _bytetomb[2];
  _pnap   := _bytetomb[3];
  _pora   := _bytetomb[4];
  _pperc  := _bytetomb[5];

  _vanfoglalo := False;
  if _pperc>=100 then
    begin
      _pperc := _pperc-100;
      _vanfoglalo := true;
    end;

  _tempdatum := inttostr(2000+_pev)+'.'+nulele(_pho)+'.'+nulele(_pnap);
  _tempido   := nulele(_pora)+':'+nulele(_pperc);

  _valutadarab :=  _byteTomb[6];           // = 24-27 (valutadarab) CONSTANS

  _kodpointer := 7;

  _cc := 1;
  Fastcsik.Max := _valutadarab;
  while _cc<=_valutadarab do    // valuta darab
    begin
      Fastcsik.Position := _cc;
      _aktdnem     := Dnemdekod;
      _aktkeszlet  := DarabDekod;
      _aktkeszletft:= DarabDekod;
      _aktvetel    := Darabdekod;
      _aktvetelft  := Darabdekod;
      _akteladas   := DarabDekod;
      _akteladasft := Darabdekod;

      _valutaIndex := Scandnem(_aktdnem);           // Mi a valuta sorszáma (1..24)

      _tempkeszlet[_valutaindex]   := _aktkeszlet;
      _tempkeszletft[_valutaIndex] := _aktkeszletft;
      _tempvetel[_valutaIndex]     := _aktVetel;
      _tempvetelft[_valutaIndex]   := _aktvetelFt;
      _tempeladas[_valutaIndex]    := _akteladas;
      _tempeladasft[_valutaIndex]  := _akteladasft;
      inc(_cc);
    end;

  // Az összes valuta adata fel van dolgozva, jöhet a következõ 16 byte
  // ami 4 double-word-ot tartalmaz:


  _tempwusd   := DarabDekod;  // Az iroda w.u. dollár készlete 1-4
  _tempwhuf   := Darabdekod;  // Az iroda w.u. forint készlete 5-8
  _tempwafa   := DarabDekod;  // Az iroda afa készlete 9-12 byte
  _tempwkezdij:= Darabdekod;  // Az aktuális kezelési díj
  _tempweker  := Darabdekod;  // Az aktualis e-keredkedelem forintja
 // _tempwfoglalo := Darabdekod;  // foglalo;

  // A munkakönyvtárból törölni a feldolgozott adatfile-t !

  DeleteFile(_aktfilePath);
  result := true;

end;


// =============================================================================
                         procedure TForm1.AdatOsszesites;
// =============================================================================


begin
  _korzetIndex := 1;
  while _KorzetIndex<=8 do
    begin
      _aktKorzetDarab := _korzetPtdb[_korzetIndex];
      _ptsorIndex := 1;
      Fastcsik.Max := _aktkorzetDarab;
      while _ptsorIndex<=_aktKorzetDarab do
        begin
          Fastcsik.Position := _ptsorindex;
          _ptarIndex := _korzetPtsor[_korzetIndex,_ptsorIndex];
          _valutaIndex := 1;
          while _valutaIndex<=27 do
            begin
              _ktkeszlet[_korzetIndex,_valutaIndex]  := _ktkeszlet[_korzetIndex,_valutaIndex]   + _ptkeszlet[_ptarIndex,_valutaIndex];
              _ktkeszletFt[_korzetIndex,_valutaIndex]:= _ktkeszletFt[_korzetIndex,_valutaIndex] + _ptkeszletFt[_ptarIndex,_valutaIndex];
              _ktvetel[_korzetIndex,_valutaIndex]    := _ktvetel[_korzetIndex,_valutaIndex]     + _ptvetel[_ptarIndex,_valutaIndex];
              _ktvetelFt[_korzetIndex,_valutaIndex]  := _ktvetelFt[_korzetIndex,_valutaIndex]   + _ptvetelFt[_ptarIndex,_valutaIndex];
              _kteladas[_korzetIndex,_valutaIndex]   := _kteladas[_korzetIndex,_valutaIndex]    + _pteladas[_ptarIndex,_valutaIndex];
              _kteladasFt[_korzetIndex,_valutaIndex] := _kteladasFt[_korzetIndex,_valutaIndex]  + _pteladasFt[_ptarIndex,_valutaIndex];

              // -------------------------------------------------------------------------------------------------------

              _ttkeszlet[_valutaindex]   := _ttkeszlet[_valutaIndex]   + _ptKeszlet[_ptarIndex,_valutaIndex];
              _ttkeszletft[_valutaIndex] := _ttkeszletft[_valutaIndex] + _ptKeszletft[_ptarIndex,_valutaIndex];
              _ttVetel[_valutaIndex]     := _ttvetel[_valutaIndex]     + _ptVetel[_ptarIndex,_valutaIndex];
              _ttVetelFt[_valutaIndex]   := _ttvetelFt[_valutaIndex]   + _ptVetelFt[_ptarIndex,_valutaIndex];
              _ttEladas[_valutaIndex]    := _ttEladas[_valutaIndex]    + _ptEladas[_ptarIndex,_valutaIndex];
              _ttEladasFt[_valutaIndex]  := _ttEladasFt[_valutaIndex]  + _ptEladasFt[_ptarIndex,_valutaIndex];

              inc(_valutaIndex);
            end;

          _ktWusd[_korzetIndex]    := _ktWusd[_KorzetIndex]   + _ptWusd[_ptarIndex];
          _ktWHuf[_korzetIndex]    := _ktWHuf[_KorzetIndex]   + _ptWHuf[_ptarIndex];
          _ktWAfa[_korzetIndex]    := _ktWAfa[_KorzetIndex]   + _ptWAfa[_ptarIndex];
          _ktWKezdij[_korzetIndex] := _ktWKezdij[_KorzetIndex]+ _ptWKezdij[_ptarIndex];
          _ktWEker[_korzetIndex]   := _ktWEker[_KorzetIndex]  + _ptWEker[_ptarIndex];

          // ---------------------------------------------------------------------

          _ttwusd    := _ttwusd    + _ptWusd[_ptarIndex];
          _ttwHuf    := _ttwHuf    + _ptWHuf[_ptarIndex];
          _ttwAfa    := _ttwAfa    + _ptWAfa[_ptarIndex];
          _ttwKezdij := _ttwKezdij + _ptWKezdij[_ptarIndex];
          _ttwEker   := _ttwEker   + _ptWEker[_ptarIndex];

          inc(_ptsorindex);
        end;
      inc(_KorzetIndex);
    end;
end;


// =============================================================================
                 function TForm1.ScanDnem(_dn: string): integer;
// =============================================================================

// A valuta sorszámát adja vissza a neve alapján

var _y: integer;

begin
  result := 0;
  _y := 1;
  while _y<=27 do
    begin
      if _valutanemek[_y]=_dn then
        begin
          result := _y;
          break;
        end;                                    //
      inc(_y);
    end;
end;



// =============================================================================
                       procedure TForm1.AdatNullazo;
// =============================================================================

//  Az adatok alapértékre állitása a munkát megelözõen:

var i,j: byte;

begin
    _irodadarab := 0;

  Fastcsik.Max := 150;
  for i := 1 to 150 do
    begin
      Fastcsik.Position := i;
      _ptwusd[i]     := 0;
      _ptwhuf[i]     := 0;
      _ptWafa[i]     := 0;
      _ptWkezdij[i]  := 0;
      _ptweker[i]    := 0;

      for j := 1 to 27 do
        begin
          _ptkeszlet[i,j]   := 0;
          _ptKeszletFt[i,j] := 0;
          _ptVetel[i,j]     := 0;
          _ptVetelFt[i,j]   := 0;
          _pteladas[i,j]    := 0;
          _pteladasFt[i,j]  := 0;
        end;
      for j := 0 to 4 do _ptfoglalo[i,j] := 0;
    end;

  for i := 1 to 8 do
    begin
      _ktWusd[i]    := 0;
      _ktWhuf[i]    := 0;
      _ktwafa[i]    := 0;
      _ktwkezdij[i] := 0;
      _ktWeker[i]   := 0;

      _korzetptdb[i] := 0;

      for j := 1 to 40 do _korzetptsor[i,j] := 0;
      for j := 0 to 4 do _ktFoglalo[i,j] := 0;

      for j := 1 to 27 do
        begin
          _ktkeszlet[i,j]   := 0;
          _ktKeszletFt[i,j] := 0;
          _ktVetel[i,j]     := 0;
          _ktVetelFt[i,j]   := 0;
          _ktEladas[i,j]    := 0;
          _ktEladasFt[i,j]  := 0;
        end;
    end;

  for j:= 1 to 27 do
    begin
      _ttkeszlet[j]   := 0;
      _ttkeszletFt[j] := 0;
      _ttVetel[j]     := 0;
      _ttVetelFt[j]   := 0;
      _ttEladas[j]    := 0;
      _ttEladasFt[j]  := 0;
    end;

  for j := 0 to 4 do _ttfoglalo[j] := 0;

  _ttwusd    := 0;
  _ttwhuf    := 0;
  _ttwafa    := 0;
  _ttwkezdij := 0;
  _ttweker   := 0;

  // ------------------------------------------

  for i := 0 to 15 do
    begin
      _acWUsd[i] := 0;
      _acWHuf[i] := 0;
      _acWkezdij[i] := 0;

      for j := 1 to 9 do
        begin
          _ackeszlet[i,j] := 0;
          _ackeszletft[i,j] := 0;
          _acFoglalo[i,j] := 0;
          _acVetel[i,j] := 0;
          _acVetelFt[i,j] := 0;
          _aceladas[i,j] := 0;
          _acEladasft[i,j] := 0;
        end;
    end;
end;


// =============================================================================
               function TForm1.ScanKorzet(_kz: integer): integer;
// =============================================================================

// A körzetszám (10,20,40 ...) alapján megadja a körzet sorszámát (1..8)

var _y: integer;

begin
  _y := 1;
  result := 0;
  while _y<=8 do
    begin
      if _kz=_korzetszamok[_y] then
        begin
          result := _y;
          Break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                       procedure TForm1.MakeExceltabla;
// =============================================================================

var i: integer;
    _kNev: string;

begin

   Csik.Position := 50;


   // -------------- excel tábla létrehozása -----------------------------------

   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add[1];

   // ---  A 9 fül létrehozása és elnevezése, sor fagyasztása ------------------

   _oxl.workbooks[1].sheets.add(,,10);


   for i := 1 to 8 do
     begin

       _kNev := _korzetnevek[i]+'I KÖRZET';
       _oxl.workbooks[1].worksheets[i].name := _kNev;
       _oxl.workbooks[1].worksheets[I].select;
       _range := _oxl.range['C8','C8'];
       _range.select;
       _oxl.Activewindow.FreezePanes := True;
     end;
   _oxl.workbooks[1].worksheets[9].name := 'EXCLUSIVE CHANGE';

  _oxl.workbooks[1].worksheets[9].select;
  _range := _oxl.range['C8','C8'];
  _range.select;
  _oxl.Activewindow.FreezePanes := True;

  _oxl.workbooks[1].worksheets[10].name := 'EXPRESSZ MINIBANK.';

  _oxl.workbooks[1].worksheets[10].select;
  _range := _oxl.range['C8','C8'];
  _range.select;
  _oxl.Activewindow.FreezePanes := True;

   // --------------------------------------------------------------------------
   // A 8+1 körzet táblájának elökészítése és feltöltése:
   Alcimpanel.Caption := 'A NYOLC KÖRZET TÁBLÁJÁNAK ELÕKÉSZÍTÉSE';
   AlcimPanel.Repaint;

   Csik.Max := 9;
   Csik.Position := 0;
   _cc := 0;
   _korzetindex := 1;
   while _korzetindex<10 do
     begin
       _aktKorzetDarab := _korzetPtdb[_korzetindex];

       Alcimpanel.caption := _korzetnevek[_korzetIndex] + ' TÁBLÁZATA';
       AlcimPanel.Repaint;
       Csik.Position := _korzetindex;
       Csik.Repaint;

       KorzetExcelFejlec;

       ExcelAdatFeltoltes;
       inc(_korzetindex);
     end;

 
end;


// =============================================================================
                    procedure Tform1.ExcelAdatFeltoltes;
// =============================================================================


var _kptDarab,_skeszletFt,_aktKeszletFt,_ptv,_pte,_ptvft,_pteft: integer;
    _sptvft,_spteft: integer;

begin
  if _korzetIndex=9 then
    begin
     KftOsszesenExcel;
      exit;
    end;

  Alcimpanel.Caption := 'AZ EXCELTÁBLA ADATOKKAL FELTÖLTÉSE';

  //  A készletek celláinak szám kijelzés tipusa

  _rangestr := 'C8:' + _lastLetter + '35';
  _oxl.worksheets[_korzetIndex].range[_rangestr].Numberformat := '### ### ###';
  Rangefontkeszlet(_rangestr,'Arial',10,False,False);

  //  Az ÖSSZESEN sor beállitása

   _rangeStr := 'A35:' + getOszlopBetu(_oszlopDarab)+'35';
  RangeFontKeszlet(_rangestr,'Arial',12,True,True);
  RangeKozepre(_rangestr);


  _kptDarab := _korzetptdb[_korzetIndex];
  _ptsorIndex := 1;

  _skeszletft := 0;

  Fastcsik.Max := _kptDarab;
  while _ptsorIndex<=_kptDarab do
    begin
      FastCsik.Position := _ptsorIndex;

      _ptarindex   := _korzetPtsor[_korzetIndex,_ptsorindex];
      _valutaIndex := 1;

      _xoszlop     := 1 + trunc(2*_ptsorindex);

      _sptvft   := 0;
      _spteft   := 0;
      _skeszletft := 0;

      while _valutaIndex<=27 do
        begin

          // Az aktuális valuta sora: Xsor
          // Beirja a Valuta készletét és forint értékét:

          _xsor := _valutaIndex + 7;
          _aktKeszletFt := _ptKeszletFt[_ptarIndex,_valutaIndex];

          _oxl.worksheets[_korzetindex].Cells[_xSor,_xOszlop]  := _ptKeszlet[_ptarindex,_valutaIndex];
          _oxl.worksheets[_korzetIndex].Cells[_xSor,_xOszlop+1]:= _aktkeszletFt;
          _sKeszletFt := _sKeszletFt + _aktKeszletFt;

          //  Most az aktuális valuta Vétele és Eladása kerül beirásra:
          // Az AUD kezdõsora: 49

          _xsor := 47 + trunc(_valutaIndex*2);

          _ptv := _ptVetel[_ptarIndex,_valutaIndex];
          _pte := _ptEladas[_ptarIndex,_valutaIndex];

          // Vétel és mellé az eladás beirása:

          if _ptv>0 then _oxl.worksheets[_korzetIndex].cells[_xSor,_xoszlop]  := _ptv;
          if _pte>0 then _oxl.worksheets[_korzetindex].cells[_xSor,_xOszlop+1]:= _ptE;

          // A fenti tranzakciók forint értéke:

          _ptvFt := _ptVetelFt[_ptarIndex,_valutaIndex];
          _pteFt := _ptEladasFt[_ptarIndex,_valutaIndex];

          if _ptvFt>0 then
            begin
              _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop].font.color := clGray;
              _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop] := _ptvft;
              _sptvft := _sptvft + _ptvft;
            end;

          if _pteFt>0 then
            begin
              _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop+1].font.color := clGray;
              _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop+1] := _pteft;
              _spteft := _spteft + _pteft;
            end;

          inc(_valutaIndex);   // Jöhet a következõ valutanem
        end;

      // ----------- a valuták Vételi és eladási adatok felvannak irva ---------

      _x := 0;
      _fogs := '';

      while _x<5 do
        begin
          _aktf := _ptfoglalo[_ptarindex,_x];
          if _aktf>0 then _fogs := _fogs + inttostr(_aktf)+' '+ _foglalodnem[_x]+' ';
          inc(_x);
        end;

      // Az összes valuta készlet forint értéke a 35 sorba irva ------------

      _oxl.worksheets[_korzetIndex].Cells[35,_xoszlop] := _sKeszletFt;

      // A 103-ik sorba beirjuk az összes tranzakciók forint értékét
      // külön a vétel- és eladás rovatba:

      _oxl.worksheets[_korzetindex].Cells[103,_xoszlop] := _sptvFt;
      _oxl.worksheets[_korzetindex].Cells[103,_xoszlop+1] := _spteFt;

      // A WU- ÁFÁ KEZDIJ EKER FOGLALOK cellák elõkészitése:

      _rangeStr := 'A38:'+ getoszlopbetu(_oszlopdarab)+'43';
      _oxl.worksheets[_korzetIndex].range[_rangestr].HorizontalAlignment := -4108;
      _oxl.worksheets[_korzetIndex].range[_rangestr].NumberFormat := '### ### ###';

      // A WU (etc) adatok beirása:

      _oxl.worksheets[_korzetIndex].cells[38,_xoszlop] := _ptWusd[_ptarIndex];
      _oxl.worksheets[_korzetIndex].cells[39,_xoszlop] := _ptWHuf[_ptarIndex];
      _oxl.worksheets[_korzetIndex].cells[40,_xoszlop] := _ptWAfa[_ptarIndex];
      _oxl.worksheets[_korzetIndex].cells[41,_xoszlop] := _ptWKezdij[_ptarIndex];
      _oxl.worksheets[_korzetIndex].cells[42,_xoszlop] := _ptWEker[_ptarIndex];
      _oxl.worksheets[_korzetindex].cells[43,_xoszlop] := _fogs;

      inc(_ptsorIndex); // Jöhet a következõ pénztár a sorban
    end;

  KorzetOsszesenExcel;

end;

// =============================================================================
                      procedure TForm1.KorzetExcelFejlec;
// =============================================================================


var _kk: byte;

begin
   // Hány oszlop kell a körzet táblájában:

  Alcimpanel.Caption := _korzetnevek[_korzetIndex] + ' FEJLÉC KÉSZÍTÉSE';
  Alcimpanel.Repaint;

  _oszlopDarab := 4+trunc(2*_aktKorzetdarab); // 2 valutanem + 2*irodak + 2*összesen
  _lastLetter := GetOszlopBetu(_oszlopDarab); // ez az utolsó oszlop betüjele

  _oxl.workSheets[_korzetIndex].Range['A1:A1'].columnWidth := 5;
  _oxl.worksheets[_korzetIndex].Range['B1:B1'].columnWidth := 18;
  _rangestr := 'C1:' + _lastletter +'1';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].columnWidth := 15;


  // A fejléc összes betüje Times New Roman, bold, Italic, 12-es közepre;

  _rangestr := 'A2:' + _lastletter + '7';
  RangeFontKeszlet(_rangestr,'Times New Roman',12,True,True);
  RangeKozepre(_rangestr);

  // A legfelsõ magyarázó fõcimsor beállitása:

  _rangestr := 'A2:H2';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size   := 16;

  _text := _korzetNevek[_korzetIndex]+'I KÖRZET KÉSZLETEI ÉS FORGALMA';
  if _korzetindex=9 then _text := 'ESCLUSIVE CHANGE KFT KÉSZLETEI ÉS FORGALMA';
  _oxl.worksheets[_korzetIndex].cells[2,1] := _text;

  //----------------------------------------------------------------------------

  // Valutanemek box:

  _rangestr := 'A4:B5';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_korzetIndex].Cells[4,1] := 'VALUTANEMEK';

  // Dátumbox

  _rangestr := 'A6:B6';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[6,1] := 'DÁTUM';

  // Idõbox:

  _rangestr := 'A7:B7';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[7,1] := 'IDÕ';

  // ---------------------------------------------------------------------------

  // Az egységek ossulopainak kialakitása: körzetenként

  Fastcsik.Max := _aktkorzetdarab;

  _ptsorindex := 1;
  while _ptsorindex<=_aktkorzetDarab do
    begin
      // Az elsõ a 3-ik oszlop: (majd 5,7 stb)

      Fastcsik.Position := _ptsorIndex;
      _aktoszlop := 1 + trunc(2*_ptsorindex);

      // A következö pénztárszám:  ELSÕ RANGE= 'C4:B4'

      // Az összenyitott két cellába az egység neve kerül: (pl: Nyiregyháza TESCO)

      _ptarIndex := _korzetptsor[_korzetindex,_ptsorindex];
      _rangestr := getoszlopbetu(_aktoszlop) + '4:' + getoszlopbetu(_aktoszlop+1) + '4';
      _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;

      _text := _irodanev[_ptarindex];
      if _korzetIndex=9 then
        begin
          _kk := scanKorzet(_ptarindex);
          _text := _korzetnevek[_kk] + 'I KÖRZET';
        end;

      // ------------------Egység neve, és a 2 oszlop neve ---------------------

      _oxl.worksheets[_korzetIndex].Cells[4,_aktoszlop]   := _text;
      _oxl.worksheets[_korzetIndex].Cells[5,_aktoszlop]   := 'KÉSZLET';
      _oxl.worksheets[_korzetIndex].Cells[5,_aktoszlop+1] := 'ÉRTÉK (Ft)';

      // ------------- Elsö range = 'C6:D6' Beirja az aktuális dûtumot ---------

      _rangestr := getoszlopbetu(_aktoszlop) + '6:' + getoszlopbetu(_aktoszlop+1) + '6';
      _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
      _oxl.worksheets[_korzetIndex].Cells[6,_aktoszlop] := _ptDatum[_ptarIndex];

      // ----------- Elsö range = 'C7:D7' -- Beirja az aktuális idöt -----------

      _rangestr := getoszlopbetu(_aktoszlop) + '7:' + getoszlopbetu(_aktoszlop+1) + '7';
      _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
      _oxl.worksheets[_korzetIndex].Cells[7,_aktoszlop] := _ptIdo[_ptarIndex];

      //  Jöhet a következö egység oszlopa -------------------------------------

      inc(_ptsorIndex);
    end;

  // ---------------------------------------------------------------------------

  // Az összesen oszlop kialakitása:

  _rangestr := getoszlopbetu(_oszlopDarab-1)+'4:' + getoszlopBetu(_oszlopdarab)+'7';
  _oxl.worksheets[_korzetindex].range[_rangestr].VerticalAlignment := -4108;

  // Az ÖSSZESEN felirat 4 összenyitott cellába kerül:

  _rangestr := getoszlopbetu(_oszlopDarab-1)+'4:'+getoszlopbetu(_oszlopdarab)+'5';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[4,_oszlopDarab-1] := 'ÖSSZESEN';

  // Két-két cella összenyitva a KÉSZLET és ÉRTÉK (Ft) beirásának:

  _rangestr := getoszlopbetu(_oszlopDarab-1)+'6:'+getoszlopbetu(_oszlopdarab-1)+'7';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[6,_oszlopDarab-1] := 'KÉSZLET';

  _rangestr := getoszlopbetu(_oszlopDarab)+'6:'+getoszlopbetu(_oszlopdarab)+'7';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[6,_oszlopDarab] := 'ÉRTÉK (Ft)';

  // ------------------- OLDAL FEJLÉC (Valutanemek) ----------------------------

  //  A valutanemek és valutanevek beirása az 1 és 2-ik oszopba
  // a 8-tól a 34-ig sorig:

  _valutaIndex := 1;
  while _valutaIndex<=27 do
    begin
      _oxl.worksheets[_korzetIndex].Cells[7+_valutaindex,1] := _valutanemek[_valutaIndex];
      _oxl.worksheets[_korzetIndex].Cells[7+_valutaIndex,2] := _valutaNevek[_valutaIndex];
      inc(_valutaIndex);
    end;

  // A valutanemek oszlop-betüjének beállitása:

  _rangestr := 'A8:A34';
  RangeFontKeszlet(_rangestr,'Arial',10,True,False);
  RangeKozepre(_rangestr);

  // A valutanevek oszlop-betüjének beállitása

  _rangestr := 'B8:B34';
  RangeFontKeszlet(_rangestr,'Arial',10,False,False);

  // Az ÖSSZESEN felirat részére 2 cella összenyitva:

  _oxl.worksheets[_korzetIndex].range['A35:B35'].mergeCells := True;
  _oxl.worksheets[_korzetIndex].Cells[35,1] := 'ÖSSZESEN';

  //  Az ÖSSZESEN sor bankjegy-érték cellák összenyitása, mert csk érték van itt

  _xoszlop := 3;
  while _xoszlop<_oszlopDarab do
    begin
      _rangestr := getOszlopBetu(_xoszlop)+'35:'+getoszlopBetu(_xoszlop+1)+'35';
      _oxl.worksheets[_korzetIndex].range[_rangestr].MergeCells := true;
      _xoszlop := _xoszlop + 2;
    end;

  // --------- Az egyéb (WU,afa,kezdij,eker,foglalo) készletei -----------------

  _xsor := 38;
  while _xsor<44 do
    begin
      // a két cella összenyitása: és cim beirása (wu (usd)... stb)

      _rangestr := 'A'+inttostr(_xsor)+':B'+inttostr(_xsor);
      _oxl.worksheets[_korzetIndex].range[_rangestr].Mergecells := true;
      RangeFontKeszlet(_rangestr,'Times New Roman',11,False,True);
      _cc := _xsor-38;
      _oxl.worksheets[_korzetIndex].Cells[_xsor,1] := _wNev[_cc];

      //  Minden péntárnak, 2-2 celláját összenyitjuk az értékeknek:

      _xoszlop := 3;
      while _xOszlop<_oszlopdarab do
        begin
          _rangestr := getoszlopBetu(_xoszlop)+inttostr(_xsor)+':'+getoszlopbetu(_xOszlop+1)+inttostr(_xsor);
          _oxl.workSheets[_korzetIndex].range[_rangestr].Mergecells := True;
          _xoszlop := _xoszlop + 2;
        end;
      inc(_xsor);
    end;

  // Az egyéb készletek betütipusának beállitása:

  _rangestr := 'C38:' + getOszlopbetu(_oszlopDarab)+'43';
  RangeFontkeszlet(_rangestr,'Times New Roman',11,False,True);

  // ---------------------------------------------------------------------------

  // A NAPI FORGALOM sorának beállitása

  _Rangestr := 'A47:'+ getoszlopbetu(_oszlopdarab)+'47';
  RangeFontkeszlet(_rangestr,'Times New Roman',12,True,True);
  RangeKozepre(_rangestr);
  _oxl.worksheets[_korzetIndex].range['A47:B47'].mergecells := True;
  _oxl.worksheets[_korzetIndex].cells[47,1] := 'NAPI FORGALOM';

  // A forgalom sor fejlécének fejlécneveinek beirása:

  _xOszlop := 3;
  while _xOszlop<_oszlopdarab do
    begin
      _oxl.worksheets[_korzetIndex].cells[47,_xoszlop] := 'VÉTEL';
      _oxl.worksheets[_korzetIndex].cells[47,_xoszlop+1] := 'ELADÁS';
      _xOszlop := _xOszlop + 2;
    end;

  // --------- A forgalom  valutanemenként ------------------------------

  _xsor := 49;
  _valutaindex := 1;
  FAstcsik.Max := 27;

  while _valutaIndex<=27 do
    begin

      // Beirja a valutanemeket és valutaneveket:

      Fastcsik.Position := _valutaIndex;
      _oxl.worksheets[_korzetIndex].cells[_xsor,1] := _valutanemek[_valutaIndex];
      _oxl.worksheets[_korzetIndex].cells[_xsor,2] := _valutanevek[_valutaIndex];

      // Két-két cellát egymás alatt összenyit a valuta-nemeknek és neveknek:

      _rangestr := 'A'+inttostr(_xsor)+':A'+inttostr(_xsor+1);
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;

      _rangestr := 'B'+inttostr(_xsor)+':B'+inttostr(_xsor+1);
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;

      _xsor := _xsor + 2;
      inc(_valutaIndex);
    end;

  // A valutanemek betütipusai és elrendezése:

  _rangestr := 'A49:A102';
  RangeFontkeszlet(_rangestr,'Arial',10,True,False);
  RangeKozepre(_rangestr);

  _oxl.worksheets[_korzetIndex].range[_rangestr].VerticalAlignment := -4108;

  // A valutanevek betütipusai és elrendezése:

  _rangestr := 'B49:B102';
  RangeFontkeszlet(_rangestr,'Arial',10,False,False);
  _oxl.worksheets[_korzetIndex].range[_rangestr].VerticalAlignment := -4108;

  // A legalsó ÖSSZSESEN sor beállitása:

  _rangestr := 'A103:' + getoszlopbetu(_oszlopDarab)+'103';
  RangeFontkeszlet(_rangestr,'Arial',12,True,False);
  RangeKozepre(_rangestr);

  _oxl.worksheets[_korzetIndex].range[_rangestr].NumberFormat := '### ### ###';
  _oxl.worksheets[_korzetIndex].range['A103:B103'].Mergecells := true;
  _oxl.worksheets[_korzetIndex].range['A103:B103'].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetIndex].Cells[103,1] := 'ÖSSZESEN';

  // A teljes forgalmi számok beállitása:

  _rangestr := 'C49:' + getoszlopBetu(_oszlopDarab)+'102';
  _oxl.worksheets[_korzetIndex].range[_rangestr].NumberFormat := '### ### ###';
  RangeKozepre(_rangestr);

end;

// =============================================================================
              procedure TForm1.RangeKozepre(_rr: string);
// =============================================================================


begin
  _oxl.worksheets[_korzetIndex].range[_rr].HorizontalAlignment := -4108;
end;


// =============================================================================
      function TForm1.FTForm(_num: integer; _dim: string): string;
// =============================================================================

var _nums: string;
    _p1,_numlen: integer;

begin
  _nums := inttostr(_num);
  _numlen := length(_nums);
  if _num = 0 then
    begin
      result := '-';
      exit;
    end;

  if _Numlen<4 then
    begin
      result := _nums;
      if _dim<>'' then result := result + ' '+_dim;
      exit;
    end;


  if _num>999999 then
    begin
      _p1 := _numlen-6;
      result := leftstr(_nums,_p1)+' '+midstr(_nums,_p1+1,3)+' '+midstr(_nums,_p1+4,3);
      if _dim<>'' then result := result + ' '+_dim;
      exit;
    end;

  _p1 := _numlen-3;
  result := leftstr(_nums,_p1)+' '+midstr(_nums,_p1+1,3);
  if _dim<>'' then result := result + ' '+_dim;
end;


// =============================================================================
        procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================



begin
  _owb := UnAssigned;
  _oxl.quit;
  _oxl := UnAssigned;
  Application.Terminate;
end;



// =============================================================================
        function TForm1.GetOszlopBetu(_oo: integer): string;
// =============================================================================


// Visszaadja az oszlop betüjelét: A,B,C,D ...AA,AB,AC ...

begin
  if _oo<27 then Result := chr(64+_oo)
  else Result := 'A' + chr(38+_oo);
end;

// =============================================================================
              function TForm1.Nulele(_int: integer):string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;




//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =========================== KOMMUNIKÁCIO ====================================
// =============================================================================
                 function TForm1.IrodadatBeolvasas: boolean;
// =============================================================================

var _irodaPath,_varosnev,_boltnev: string;
    _irodaSzam,_acIndex: byte;

begin
  result := false;

  CimPanel.Caption := 'IRODÁK BEOLVASÁSA';
  CimPanel.Repaint;

  if not IrodadatLetoltes then exit;
  _irodaPath := _workdir + '\irodak.dat';

  Assignfile(_binolvas,_irodaPath);
  Reset(_binolvas);

  _meret := Filesize(_binolvas);
  Blockread(_binolvas,_bytetomb,_meret);
  CloseFile(_binOlvas);

  _kodpointer := 1;
  _irodadarab := Getbyte;


  _qq := 0;
  Fastcsik.Max := _irodaDarab;
  while _qq<_irodadarab do
    begin
      Fastcsik.Position := _qq;
      _irodaszam := getbyte;
      getbyte;  // értéktár nem kell
      _varosnev  := Getstring;
      _boltnev   := Getstring;
      _irodanev[_irodaszam] := _varosnev + ' ' + _boltnev;
      inc(_qq);
    end;

   deleteFile(_irodaPath);

  {
  _irodanev[10]  := 'Szekszárdi Értéktár';
  _irodanev[20]  := 'Szegedi Értéktár';
  _irodanev[40]  := 'Kecskeméti Értéktár';
  _irodanev[50]  := 'Debreceni Értéktár';
  _irodanev[63]  := 'Nyíregyházi Értéktár';
  _irodanev[75]  := 'Békéscsabai Értéktár';
  _irodanev[120] := 'Pécsi Értéktár';
  _irodanev[145] := 'Kaposvári Értéktár';
  }

  // ======================== art cash =========================================

  _irodaPath := _workdir + '\acirodak.dat';

  Assignfile(_binolvas,_irodaPath);
  Reset(_binolvas);

  _meret := Filesize(_binolvas);
  Blockread(_binolvas,_bytetomb,_meret);
  CloseFile(_binOlvas);

  _kodpointer := 1;
  _acirodadarab := Getbyte;

  _qq := 1;
  Fastcsik.Max := _acirodadarab;
  while _qq<=_acirodadarab do
    begin
      Fastcsik.Position := _qq;
      _irodanum := getbyte;
      _boltnev   := Getstring;
      _acindex := _irodanum-150;
      _acirodanev[_acindex] := _boltnev;
      inc(_qq);
    end;

  deleteFile(_irodaPath);
  Result := true;

end;

// =============================================================================
                       function TFORM1.IrodaDatLetoltes: boolean;
// =============================================================================

begin

  result := False;

  if not VanInternet then
    begin
      ShowMessage('NINCS INTERNETKAPCSOLAT !');
      exit;
    end;

  _hNet := InternetOpen('Irodak',
                         INTERNET_OPEN_TYPE_PRECONFIG,
                         nil,
                         nil,
                         0);

  if _hNet=nil then
    begin
      ShowMessage('NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT');
      Exit;
    end;

   // -------------------  connect to the server  -------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_Host),_ftpPort,Pchar(_userId),
                           PChar(_ftpPassword),INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

  if _hftp=Nil then
    begin
      ShowMessage('Nem érem el a Szervert !');
      InternetCloseHandle(_hNet);
      exit;
    end;

  // ---------------------------------------------------------------------------

  _remoteFile := '\irodak\irodak.dat';
  _localFile  := _workdir +'\irodak.dat';

  if Fileexists(_localfile) then DeleteFile(_localFile);

  _sikeres := FTPgetFile(_hFTP,
                  pchar(_remoteFile),
                  pchar(_localfile),
                  False,
                  0,
                  FTP_TRANSFER_TYPE_BINARY,
                  0);

  if _sikeres then
     begin
       _remoteFile := '\irodak\acirodak.dat';
       _localFile := _workdir + '\acirodak.dat';

       _sikeres := FTPgetFile(_hFTP,
       pchar(_remoteFile),
       pchar(_localfile),
       False,
       0,
       FTP_TRANSFER_TYPE_BINARY,
       0);
     end;


  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  if _sikeres then result := true;
end;


// =============================================================================
                  function TForm1.KeforLetoltes: boolean;
// =============================================================================

var _code: integer;
    _lenrem,_lenext: byte;
    _irodas: string;

begin
  Result := False;

  _hnet := InternetOpen('LoadFormServer',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);

  if _hNet = nil then
    begin
      Showmessage('Nem tudtam fellépni az internetre ...');
      exit;
    end;

  // -------------------  connect to the server  -------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_Host),_ftpPort,Pchar(_userId),
                           PChar(_ftpPassword),INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

  // ---------------------------------------------------------------------------

  IF _hFTP = nil then
    begin
      ShowMessage('Nem sikerült csatlakozni a szerverhez !');
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ----------------------- Change directory PILLKESZ -------------------------

  // Belép a PILLKESZ köbnyvtárba a szerveren

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\PILLKESZ'));
  if not _sikeres then
    begin
      ShowMessage('Nem sikerült belépni a pillanatnyi-készlet-könyvtárába !');
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // --------ENDNEWPRG ---------------------------------------------------------

  // Keresi a KEFOR kezdetü file-okat (Olyan nincs is, hogy egy se lenne)

  _pkFileDarab := 0;
  _acpkFileDarab := 0;
  _hSearch := FtpFindFirstFile(_hFTP,pchar('PK*.*'),_findData,0,0);
  if _hSearch = nil then
  begin
    ShowMessage('NEM TALÁLTAM PILLANATNYI KÉSZLETEKET');
    InternetCloseHandle(_hFTP);
    InternetCloseHandle(_hNet);
    Exit;
  end
  else  // ---------- itt beolvassa az összeset a munkadirectoryba -------------
  begin
    FAstcsik.max :=200;
    _cc := 0;

    Alcimpanel.Caption := 'A file-ok beolvasása a munkakönyvtárba';
    Alcimpanel.repaint;

    repeat
       inc(_cc);
       Fastcsik.Position := _cc;

      // A következõ megtalált Kefor file forrása és céja:

      _remoteFile := _findData.cFileName;
      _lenrem := length(_remotefile);
      _ext := extractfileext(_remotefile);
      _lenext := length(_ext);

      _irodas := midstr(_remotefile,3,3);
      val(_irodas,_irodanum,_code);
      if _code<>0 then _irodanum := 0;
      _ezac := false;
      if _irodanum>150 then
        begin
          _localpath := _workdir + '\AC';
          _ezac := True;
        end else _localpath := _workdir;

      _localPath := _localPath + '\' + _remotefile;

      // Bemásolja a munkakönyvtárba a megtalált KEFOR file-t:

      if Fileexists(_localPath) then DeleteFile(_localpath);
      _sikeres := FTPGetFile(_hFTP,pchar(_remoteFile),pchar(_localpath),
                                  False,0,FTP_TRANSFER_TYPE_BINARY,0);

      // Ha sikeres volt a letöltés a file nevet regisztrálja:

      if _sikeres then
        begin
          AssignFile(_binolvas,_localpath);
          reset(_binolvas);
          _meret := FileSize(_binOlvas);
          CloseFile(_binOlvas);


          if _ezac then
            begin
              inc(_acPkfileDarab);
              _acPillName[_acpkFileDarab] := _remotefile;
              _acPksor[_acPkFileDarab] := _irodanum;
            end else
            begin
              _pillname[_pkFileDarab]:= _remoteFile;
              inc(_pkFileDarab);
            end;
        end;

    // A ciklus addig megy, mig talál KEFOR file-okat:
    until not InternetFindNextFile(_hSearch,@_findData);
    InternetCloseHandle(_hSearch);
  end;


  // ---------------------------------------------------------------------------

  _remotefile := 'FOGLALO.DAT';
  _localPath  := _workdir + '\FOGLALO.DAT';
  if fileexists(_localPath) then DeleteFile(_localPath);
  _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\FOGLALO'));

  if _sikeres then
       FTPGetFile(_hFTP,pchar(_remoteFile),pchar(_localpath),
                                  False,0,FTP_TRANSFER_TYPE_BINARY,0);

  // ---------------------------------------------------------------------------

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  // Ha egyet sem töltött le, akkor result=FALSE

  if _pkFileDarab>0 then Result := True;
end;



// =============================================================================
                        function TfORM1.DnemDekod: string;
// =============================================================================

var _b1,_b2,_l1,_l2,_l3: byte;

begin

  _b1 := _bytetomb[_kodpointer];
  _b2 := _bytetomb[_kodpointer+1];
  _kodpointer := _kodPointer + 2;

  _l1 := trunc(_b1/4);
  _l2 := trunc(64*_b1);
  _l2 := trunc(_l2/8);
  _l3 := trunc(_b2/32);
  _l2 := _l2 + _l3;
  _l3 := trunc(8*_b2);
  _l3 := trunc(_l3/8);
  _l1 := _l1 + 64;
  _l2 := _l2 + 64;
  _l3 := _l3 + 64;

  result := chr(_l1)+chr(_l2)+chr(_l3);
end;

// =============================================================================
             function TForm1.Darabdekod: integer;
// =============================================================================

var _b1,_b2,_b3,_b4: byte;

begin
  _b1 := _bytetomb[_kodpointer];
  _b2 := _bytetomb[_kodpointer+1];
  _b3 := _bytetomb[_kodpointer+2];
  _b4 := _bytetomb[_kodpointer+3];
  _kodPointer := _kodPointer + 4;

  result := _b1 + trunc(256*_b2)+trunc(65536*_b3)+trunc(256*65536*_b4);
end;

// =============================================================================
                    function TForm1.GetByte: byte;
// =============================================================================

begin
  result := _Bytetomb[_kodpointer];
  inc(_kodpointer);
end;

// =============================================================================
                 function TForm1.Getstring: string;
// =============================================================================

var _shossz,_y,_kod: integer;

begin
  result := '';
  _sHossz := _bytetomb[_kodpointer];
  inc(_kodpointer);
  if _shossz=0 then exit;

  _y := 1;
  while _y<=_sHossz do
    begin
      _kod := 255-_bytetomb[_kodpointer];
      inc(_kodPointer);
      result := result + chr(_kod);
      inc(_y);
    end;
end;

// =============================================================================
                 function TForm1.VanInternet: boolean;
// =============================================================================

var
  _dwConnType: integer;
begin
   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;

// =============================================================================
procedure TForm1.RangefontKeszlet(_rstr,_fnev: string;_fsize: byte;_bold,_italic: boolean);
// =============================================================================

begin
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Name   := _fnev;
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Bold   := _bold;
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Italic := _italic;
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Size   := _fsize;
end;


// =============================================================================
                  procedure TForm1.KorzetOsszesenExcel;
// =============================================================================


var _skeszletFt,_sptvFt,_sPteFt,_ptv,_pte,_ptvft,_pteft: integer;

begin
  _valutaIndex := 1;
  _xOszlop := _oszlopDarab-1;

  _sKeszletFt := 0;
  _sptVFt := 0;
  _spteFt := 0;

  FastCsik.Max := 27;
  while _valutaIndex<=27 do
    begin
      FAstcsik.Position := _valutaIndex;
      _xsor := _valutaIndex + 7;
      _aktKeszletFt := _ktKeszletFt[_korzetIndex,_valutaIndex];

      // Az aktuális valuta készlete és forint értéke: beirni:

      _oxl.worksheets[_korzetindex].Cells[_xSor,_xOszlop]  := _ktKeszlet[_korzetindex,_valutaIndex];
      _oxl.worksheets[_korzetIndex].Cells[_xSor,_xOszlop+1]:= _aktkeszletFt;

      // Forintérték summázása:

      _sKeszletFt := _sKeszletFt + _aktKeszletFt;


      // Az körzet összes vétele és eladása:

      _xsor := 47 + trunc(_valutaIndex*2);

      _ptv := _ktVetel[_korzetIndex,_valutaIndex];
      _pte := _ktEladas[_korzetIndex,_valutaIndex];

      // A körzet akt valutájának összes vétele és eladása:

      if _ptv>0 then _oxl.worksheets[_korzetIndex].cells[_xSor,_xoszlop]  := _ptv;
      if _pte>0 then _oxl.worksheets[_korzetindex].cells[_xSor,_xOszlop+1]:= _ptE;

      _ptvFt := _ktVetelFt[_korzetIndex,_valutaIndex];
      _pteFt := _ktEladasFt[_korzetIndex,_valutaIndex];

      if _ptvFt>0 then
        begin
          _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop].font.color := clGray;
          _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop] := _ptvft;
          _sptvft := _sptvft + _ptvft;
        end;

      if _pteFt>0 then
        begin
          _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop+1].font.color := clGray;
          _oxl.worksheets[_korzetIndex].cells[_xSor+1,_xoszlop+1] := _pteft;
          _spteft := _spteft + _pteft;
        end;

      inc(_valutaIndex); // jöhet a következõ valuta:
    end;

  //  Az összes forint készlet feladása (minden valutájé)

  _oxl.worksheets[_korzetIndex].Cells[35,_xoszlop]   := _sKeszletFt;

  //  Az aktuális valuta összes vásárlása és eladása:

  _oxl.worksheets[_korzetindex].Cells[103,_xoszlop]   := _sptvFt;
  _oxl.worksheets[_korzetindex].Cells[103,_xoszlop+1] := _spteFt;

  // Az összes western-union stb felirása:

  _oxl.worksheets[_korzetIndex].cells[38,_xoszlop] := _ktWusd[_korzetIndex];
  _oxl.worksheets[_korzetIndex].cells[39,_xoszlop] := _ktWHuf[_korzetIndex];
  _oxl.worksheets[_korzetIndex].cells[40,_xoszlop] := _ktWAfa[_korzetIndex];
  _oxl.worksheets[_korzetIndex].cells[41,_xoszlop] := _ktWKezdij[_korzetIndex];
  _oxl.worksheets[_korzetIndex].cells[42,_xoszlop] := _ktWEker[_korzetIndex];

  // ------------------ foglalók felirása --------------------------------------

  _fogs := '';
  _x := 0;
  while _x<5 do
    begin
      _aktf := _ktfoglalo[_korzetindex,_x];
      if _aktf>0 then _fogs := _fogs +inttostr(_aktf)+' '+ _foglalodnem[_x]+' ';
      inc(_x);
    end;
   _oxl.worksheets[_korzetindex].cells[43,_xoszlop] := _fogs;
end;


// =============================================================================
                    procedure TForm1.KftOsszesenExcel;
// =============================================================================


var _skeszletft,_sptvft,_spteft,_ptv,_pte,_ptvft,_pteft: integer;

begin

  // A kft összes készlet adatának formázása:

  _rangestr := 'C8:T36';
  _oxl.worksheets[9].range[_rangestr].Numberformat := '### ### ###';
  Rangefontkeszlet(_rangestr,'Arial',10,False,False);

  // A kft összes western union:

  _rangeStr := 'A38:T43';

  RangeFontKeszlet(_rangestr,'Arial',12,True,True);
  RangeKozepre(_rangestr);

  //  Végig a 8 körzetben:

  _korzetIndex := 1;
  while _KorzetIndex <= 8 do
    begin

      _valutaIndex := 1;

      // Minden körzetnek 2 oszlopa van:

      _xoszlop    := 1 + trunc(2*_korzetindex);
      _sptvft     := 0;
      _spteft     := 0;
      _skeszletft := 0;

      fastcsik.max := 27;

      // Végig megy a 27 valután:

      while _valutaIndex<=27 do
        begin
          Fastcsik.Position := _valutaIndex;

          // Az aktuális valuta sora:

          _xsor := _valutaIndex + 7;
          _aktKeszletFt := _ktKeszletFt[_korzetIndex,_valutaIndex];

          // Az elsö oszlop a valutakészlet a 2. a forintértéke:

          _oxl.worksheets[9].Cells[_xSor,_xOszlop]  := _ktKeszlet[_korzetIndex,_valutaIndex];
          _oxl.worksheets[9].Cells[_xSor,_xOszlop+1]:= _aktkeszletFt;
          _sKeszletFt := _sKeszletFt + _aktKeszletFt;

          // A tranzakciók sora:

          _xsor := 47 + trunc(_valutaIndex*2);

          _ptv := _ktVetel[_korzetIndex,_valutaIndex];
          _pte := _ktEladas[_korzetIndex,_valutaIndex];

          if _ptv>0 then _oxl.worksheets[9].cells[_xSor,_xoszlop]  := _ptv;
          if _pte>0 then _oxl.worksheets[9].cells[_xSor,_xOszlop+1]:= _ptE;

          _ptvFt := _ktVetelFt[_korzetIndex,_valutaIndex];
          _pteFt := _ktEladasFt[_korzetIndex,_valutaIndex];

          if _ptvFt>0 then
            begin
              _oxl.worksheets[9].cells[_xSor+1,_xoszlop].font.color := clGray;
              _oxl.worksheets[9].cells[_xSor+1,_xoszlop] := _ptvft;
              _sptvft := _sptvft + _ptvft;
            end;

          if _pteFt>0 then
            begin
              _oxl.worksheets[9].cells[_xSor+1,_xoszlop+1].font.color := clGray;
              _oxl.worksheets[9].cells[_xSor+1,_xoszlop+1] := _pteft;
              _spteft := _spteft + _pteft;
            end;
          inc(_valutaIndex);
        end;

      _oxl.worksheets[9].Cells[35,_xoszlop]   := _sKeszletFt;
      _oxl.worksheets[9].Cells[103,_xoszlop]   := _sptvFt;
      _oxl.worksheets[9].Cells[103,_xoszlop+1] := _spteFt;

      //  A western Union és társai cellái:

      _rangeStr := 'A38:'+ getoszlopbetu(_oszlopdarab)+'43';
      _oxl.worksheets[9].range[_rangestr].HorizontalAlignment := -4108;
      _oxl.worksheets[9].range[_rangestr].NumberFormat := '### ### ###';

      // .. és az adatok beirása:

      _oxl.worksheets[9].cells[38,_xoszlop] := _ktWusd[_korzetIndex];
      _oxl.worksheets[9].cells[39,_xoszlop] := _ktWHuf[_korzetIndex];
      _oxl.worksheets[9].cells[40,_xoszlop] := _ktWAfa[_korzetIndex];
      _oxl.worksheets[9].cells[41,_xoszlop] := _ktWKezdij[_korzetIndex];
      _oxl.worksheets[9].cells[42,_xoszlop] := _ktWEker[_korzetIndex];

      //  A foglalók beirása:

      _x := 0;
      _fogs := '';
      while _x<5 do
        begin
          _aktf := _ktfoglalo[_korzetindex,_x];
          if _aktf>0 then _fogs := _fogs + inttostr(_aktf)+' '+ _foglalodnem[_x]+' ';
          inc(_x);
        end;
      _oxl.worksheets[9].cells[43,_xoszlop] := _fogs;
      inc(_korzetIndex);
    end;

  _valutaIndex := 1;
  _xOszlop     := 19;

  _sKeszletFt := 0;
  _sptVFt     := 0;
  _spteFt     := 0;

  Fastcsik.Max := 27;
  while _valutaIndex<=27 do
    begin
      Fastcsik.Position := _valutaIndex;

      // A valuták összes-összes készletei:

      _xsor := _valutaIndex + 7;
      _aktKeszletFt := _ttKeszletFt[_valutaIndex];

      _oxl.worksheets[9].Cells[_xSor,_xOszlop]  := _ttKeszlet[_valutaIndex];
      _oxl.worksheets[9].Cells[_xSor,_xOszlop+1]:= _aktkeszletFt;
      _sKeszletFt := _sKeszletFt + _aktKeszletFt;

      // Az összes-összes vételek és eladások:

      _xsor := 47 + trunc(_valutaIndex*2);

      _ptv := _ttVetel[_valutaIndex];
      _pte := _ttEladas[_valutaIndex];

      if _ptv>0 then _oxl.worksheets[9].cells[_xSor,_xoszlop]  := _ptv;
      if _pte>0 then _oxl.worksheets[9].cells[_xSor,_xOszlop+1]:= _ptE;

      _ptvFt := _ttVetelFt[_valutaIndex];
      _pteFt := _ttEladasFt[_valutaIndex];

      if _ptvFt>0 then
        begin
          _oxl.worksheets[9].cells[_xSor+1,_xoszlop].font.color := clGray;
          _oxl.worksheets[9].cells[_xSor+1,_xoszlop] := _ptvft;
          _sptvft := _sptvft + _ptvft;
        end;

      if _pteFt>0 then
        begin
          _oxl.worksheets[9].cells[_xSor+1,_xoszlop+1].font.color := clGray;
          _oxl.worksheets[9].cells[_xSor+1,_xoszlop+1] := _pteft;
          _spteft := _spteft + _pteft;
        end;

      inc(_valutaIndex);
    end;

  _formula := '=sum(T8:T34)';

  // ÖSSZES - ÖSSZES

  _oxl.worksheets[9].cells[35,19].Formula := _formula;
//  _oxl.worksheets[9].Cells[30,_xoszlop]   := _sKeszletFt;
  _oxl.worksheets[9].Cells[103,_xoszlop]   := _sptvFt;
  _oxl.worksheets[9].Cells[103,_xoszlop+1] := _spteFt;

  // összes western és társai:

  _oxl.worksheets[9].cells[38,_xoszlop] := _ttWusd;
  _oxl.worksheets[9].cells[39,_xoszlop] := _ttWHuf;
  _oxl.worksheets[9].cells[40,_xoszlop] := _ttWAfa;
  _oxl.worksheets[9].cells[41,_xoszlop] := _ttWKezdij;
  _oxl.worksheets[9].cells[42,_xoszlop] := _ttWEker;

  // Az összes fogló beirása:

  _x := 0;
  _fogs := '';
  while _x<5 do
    begin
      _aktf := _ttfoglalo[_x];
      if _aktf>0 then _fogs := _fogs + inttostr(_aktf)+' '+ _foglalodnem[_x]+' ';
      inc(_x);
    end;
  _oxl.worksheets[9].cells[43,_xoszlop] := _fogs;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                        procedure TForm1.FoglalokBedolgozasa;
// =============================================================================


var _fdb,_ptnum,_penztardarab,_korzet,_kxx,_dxx: byte;
    _foglalopath,_fogdnem,_ptnev: string;
    _foglalo: integer;

begin
   _foglalopath := _workdir + '\foglalo.dat';

   Assignfile(_binolvas,_foglalopath);
   reset(_binolvas);

   _penztardarab := getfbyte;

   _qq := 1;
    while _qq<=_penztardarab do
      begin
        _ptnum := getfbyte;
        _ptnev := getfstring;   // ptnev
        _korzet :=  getfbyte;
        _kxx := scankorzet(_korzet);
        _fdb := getfByte;
        if _fdb>0 then
          begin
            _vv := 0;
            while _vv<_fdb do
              begin
                _foglalo:= getInteger;
                _fogdnem:= getfstring;
                _dxx := getfoglalodnemsorszam(_fogdnem);
                _ptfoglalo[_ptnum,_dxx] := _foglalo;
                _ktfoglalo[_kxx,_dxx] := _ktfoglalo[_kxx,_dxx] + _foglalo;
                _ttfoglalo[_dxx] := _ttfoglalo[_dxx] + _foglalo;
                inc(_vv);
              end;
          end;
        getfbyte;  //_zbyte
        inc(_qq);
      end;
   closefile(_binolvas);
end;


// =============================================================================
                      function TForm1.Getfbyte: byte;
// =============================================================================

begin
  blockread(_binOlvas,_bytetomb,1);
  result := _bytetomb[1];
end;

// =============================================================================
                      function TForm1.GetInteger: integer;
// =============================================================================


begin
  Blockread(_binOlvas,_bytetomb,4);

  result := trunc(16777216*_bytetomb[4])+trunc(65536*_bytetomb[3]);
  result := result + trunc(256*_bytetomb[2]) + _bytetomb[1];
end;


// =============================================================================
                      function TForm1.GetfString: string;
// =============================================================================

var _hossz,_pp,_kk: byte;

begin
  Blockread(_binolvas,_bytetomb,1);
  _hossz := _bytetomb[1];
  result := '';
  if _hossz=0 then exit;
  Blockread(_binOlvas,_bytetomb,_hossz);
  _pp := 1;
  while _pp<=_hossz do
    begin
      _kk := 255 - _bytetomb[_pp];
      result := result + chr(_kk);
      inc(_pp);
    end;
end;

function Tform1.GetFoglalodnemSorszam(_dd: string): byte;

begin
  result := 0;
  if _dd='HUF' then exit;
  inc(result);
  if _dd='CHF' then exit;
  inc(result);
  if _dd='GBP' then exit;
  inc(result);
  if _dd='EUR' then exit;
  inc(result);
end;

{
// =============================================================================
             function TForm1.AcEvaulate(_pkFile: string): boolean;
// =============================================================================

var i: byte;
    _aktPkPath: string;

begin
  result := False;

  for i := 1 to 9 do
    begin
      _tempkeszlet[i]  := 0;
      _tempkeszletFt[i]:= 0;
      _tempfoglalo[i]  := 0;
      _tempvetel[i]    := 0;
      _tempVetelFt[i]  := 0;
      _tempeladas[i]   := 0;
      _tempeladasFt[i] := 0;
    end;

  _tempWusd    := 0;
  _tempWHuf    := 0;
  _tempwkezdij := 0;

  // -----------------------------------------------------

  _aktPkPath := _workdir + '\Ac\'+ _pkFile;

  // -----------------------------------------------------

  AssignFile(_binolvas,_aktPkPath);           // 'c:\munka\pk118.120'
  Reset(_binolvas);

  _meret := FileSize(_binolvas);

   {
  if (_meret<>633) or (_meret=659) then
    begin
      CloseFile(_binolvas);
      deletefile(_aktPkPath);
      exit;
    end;


  Blockread(_binolvas,_bytetomb,_meret);
  CloseFile(_binolvas);

  // ---------------------------------------------------------------------------

  _pev    := _bytetomb[1];
  _pho    := _bytetomb[2];
  _pnap   := _bytetomb[3];
  _pora   := _bytetomb[4];
  _pperc  := _bytetomb[5];

  if _pperc>=100 then _pperc := _pperc-100;

  _tempdatum := inttostr(2000+_pev)+'.'+nulele(_pho)+'.'+nulele(_pnap);
  _tempido   := nulele(_pora)+':'+nulele(_pperc);

 // _valutadarab :=  _byteTomb[6];   // IGNORED

  _kodpointer := 7;

  _cc := 1;
  Fastcsik.Max := 27;
  while _cc<=27 do    // valuta darab
    begin
      Fastcsik.Position := _cc;
      _aktdnem     := Dnemdekod;
      _aktkeszlet  := DarabDekod;
      _aktkeszletft:= DarabDekod;
      _aktvetel    := Darabdekod;
      _aktvetelft  := Darabdekod;
      _akteladas   := DarabDekod;
      _akteladasft := Darabdekod;

      _valutaIndex := Scandnem(_aktdnem);   // Mi a valuta sorszáma (1..27)
      if _valutaindex>0 then
        begin
          _tempkeszlet[_valutaindex]   := _aktkeszlet;
          _tempkeszletft[_valutaIndex] := _aktkeszletft;
          _tempvetel[_valutaIndex]     := _aktVetel;
          _tempvetelft[_valutaIndex]   := _aktvetelFt;
          _tempeladas[_valutaIndex]    := _akteladas;
          _tempeladasft[_valutaIndex]  := _akteladasft;
        end;
      inc(_cc);
    end;

  // Az összes valuta adata fel van dolgozva, jöhet a következõ 16 byte
  // ami 4 double-word-ot tartalmaz:


  _tempwusd   := DarabDekod;  // Az iroda w.u. dollár készlete 1-4
  _tempwhuf   := Darabdekod;  // Az iroda w.u. forint készlete 5-8

  DarabDekod;  // Az iroda afa készlete 9-12 byte

  _tempwkezdij:= Darabdekod;  // Az aktuális kezelési díj

  Darabdekod;  // Az aktualis e-keredkedelem forintja

  Darabdekod;   // _tempwfoglalo := Darabdekod;  // foglalo;

  // A munkakönyvtárból törölni a feldolgozott adatfile-t !

  DeleteFile(_aktPkPath);
  result := true;
end;
}


// =============================================================================
                     procedure TForm1.AcAdatOsszesites;
// =============================================================================

var _y: byte;

begin
  _pkindex := 1;
  while _pkIndex<=_acPkFileDarab do
    begin
      _y := 1;
      while _y<=27 do
        begin
          _acKeszlet[0,_y] := _acKeszlet[0,_y] + _ackeszlet[_pkIndex,_y];
          _acKeszletFt[0,_y] := _acKeszletFt[0,_y] + _ackeszletFt[_pkIndex,_y];
          _acVetel[0,_y] := _acVetel[0,_y] + _acVetel[_pkIndex,_y];
          _acVetelFt[0,_y] := _acVetelFt[0,_y] + _acVetelFt[_pkIndex,_y];
          _acEladas[0,_y] := _acEladas[0,_y] + _acEladas[_pkIndex,_y];
          _acEladasFt[0,_y] := _acEladasFt[0,_y] + _acEladasFt[_pkIndex,_y];
          inc(_y);
        end;
      _acWusd[0]    := _acWUsd[0] + _acWusd[_pkindex];
      _acWhuf[0]    := _acWhuf[0] + _acWHuf[_pkIndex];
      _acWKezdij[0] := _acWkezdij[0] + _acwkezdij[_pkIndex];

      inc(_pkIndex);
    end;
end;


// =============================================================================
     function TForm1.AcPkBeolvasasa(_kefornev: string):boolean;
// =============================================================================

var _cc,_valutadarab: byte;
    _acptnums: string;

begin
  (*
  - Az aktuális file neve: _Kefornev
  _ktsznev: 'pk128.120  = 120 ÉRTÉKTÁR, 128-AS PÉNZTÁR

        ========================================================================
          1. byte = evtized
          2. byte = hónap
          3. byte = nap
          4. byte = óra
          5. byte = perc + 100
          6. byte = konstans 27 -> valutadarab
          --------------------- ciklus 1-tõl valutadarabig ---------------------
               Egy valuta 26 byte
                    1-2 byte: valutanem kód
                    3-6 byte: pillanatnyi készlet
                   7-10 byte: keszlet forint
                  11-14 byte: vétel
                  15-18 byte: vétel forint
                  19-22 byte: eladás
                  23-26 byte. eladas forint
          --------------------- ciklus láb -------------------------------------
                  1-4 byte: wu. usd
                  5-8 byte: wu. huf
                 9-12 byte: afa forint
                13-16 byte: kezelési dij
                17-20 byte: elektronikus kereskedés
                21-24 byte: foglaló
                25-26 byte: 255-255-255
            Teljes hossz: 659 byte
           =====================================================================

   - kefornev alapjan meghatározza: _aktpenztar, _aktkörzet integereket

   - _aktkorzetvaltodb = _korzetvaltodarab[_aktkorzet];
   - inc(_aktkorzetvaltodb)
   - _korzetvaltodarab[_aktkorzet]:=_aktkorzetvaltodb;

   - _valtosor[_aktkorzet,_aktkorzetvaltodb] := _aktpenztar;
   - inc(_eloirodadarab);
   - _eloirodasor[_eloirodadarab] := aktpenztar;

   - ktsz.dat megnyitása
   - valutadarabByte kiolvasása
   - ciklus indul 1-tõl valutaDarabByte-ig
         - valutanem, és bankjegy bolvasva
         - valutasorszam -> _Valss
         - _valutaKeszlet[_eloirodadarab,_valss] = Bnkjegy
         - következö valuta
   - ciklus láb:
   - ktsz.dat zárása és törlése
  *)

  // Paraméter: _kefornev (Pl: 'Pk118.120' = 118. pénztár, a 120-as körzetben)

  result := False;

  {
  _kiterjesztes := extractfileExt(_kefornev);            // '.120'
  _kithossz     := length(_kiterjesztes);                // 4
  _kits         := midstr(_kiterjesztes,2,_kithossz-1);  // '120'

  val(_kits,_tempkorzetszam,_code);                           // = 120
  if _code<>0 then exit;

  _pointindex := pos('.',_kefornev);                     // = 9
  _irszamlen  := _pointindex-3;                           // = 3
  _irszams    := midstr(_kefornev,3,_irszamlen);            // = '118'

  val(_irszams,_temppenztarszam,_code);                       // = 118
  if (_code<>0) or (_tempPenztarszam>150) then exit;
  }

  _acptNums := midstr(_kefornev,3,3);
  val(_acptnums,_acptnum,_code);
  _acptindex := _acptnum-150;

  _aktfilePath := _workdir + '\AC\' + _kefornev;       // 'c:\munka\PK118.120'

  AssignFile(_binolvas,_aktFilePath);           // 'c:\munka\pk118.120'
  Reset(_binolvas);

  _meret := FileSize(_binolvas);

  Blockread(_binolvas,_bytetomb,_MERET);
  CloseFile(_binolvas);

  // ---------------------------------------------------------------------------

  _pev    := _bytetomb[1];
  _pho    := _bytetomb[2];
  _pnap   := _bytetomb[3];
  _pora   := _bytetomb[4];
  _pperc  := _bytetomb[5];

  _vanfoglalo := False;
  if _pperc>=100 then
    begin
      _pperc := _pperc-100;
      _vanfoglalo := true;
    end;

  _tempdatum := inttostr(2000+_pev)+'.'+nulele(_pho)+'.'+nulele(_pnap);
  _tempido   := nulele(_pora)+':'+nulele(_pperc);

  _valutadarab :=  _byteTomb[6];           // = 24-27 (valutadarab) CONSTANS

  _kodpointer := 7;

  _cc := 1;
  Fastcsik.Max := _valutadarab;
  while _cc<=_valutadarab do    // valuta darab
    begin
      Fastcsik.Position := _cc;
      _aktdnem     := Dnemdekod;
      _aktkeszlet  := DarabDekod;
      _aktkeszletft:= DarabDekod;
      _aktvetel    := Darabdekod;
      _aktvetelft  := Darabdekod;
      _akteladas   := DarabDekod;
      _akteladasft := Darabdekod;

      _valutaIndex := Scandnem(_aktdnem);           // Mi a valuta sorszáma (1..24)

      _tempkeszlet[_valutaindex]   := _aktkeszlet;
      _tempkeszletft[_valutaIndex] := _aktkeszletft;
      _tempvetel[_valutaIndex]     := _aktVetel;
      _tempvetelft[_valutaIndex]   := _aktvetelFt;
      _tempeladas[_valutaIndex]    := _akteladas;
      _tempeladasft[_valutaIndex]  := _akteladasft;
      inc(_cc);
    end;

  // Az összes valuta adata fel van dolgozva, jöhet a következõ 16 byte
  // ami 4 double-word-ot tartalmaz:


  _tempwusd   := DarabDekod;  // Az iroda w.u. dollár készlete 1-4
  _tempwhuf   := Darabdekod;  // Az iroda w.u. forint készlete 5-8
  _tempwafa   := DarabDekod;  // Az iroda afa készlete 9-12 byte
  _tempwkezdij:= Darabdekod;  // Az aktuális kezelési díj
  _tempweker  := Darabdekod;  // Az aktualis e-keredkedelem forintja
 // _tempwfoglalo := Darabdekod;  // foglalo;

  // A munkakönyvtárból törölni a feldolgozott adatfile-t !

  DeleteFile(_aktfilePath);
  result := true;

end;




end.
