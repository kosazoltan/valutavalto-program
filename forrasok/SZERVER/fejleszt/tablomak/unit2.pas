unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,Strutils,
  IBTable, jpeg, unit1;

type
  TUjtablokeszites = class(TForm)
    DAYBOOKQUERY: TIBQuery;
    DAYBOOKDBASE: TIBDatabase;
    DAYBOOKTRANZ: TIBTransaction;
    KILEPOTIMER: TTimer;
    ADATQUERY: TIBQuery;
    ADATDBASE: TIBDatabase;
    ADATTRANZ: TIBTransaction;
    ADATTABLA: TIBTable;
    RECEPTQUERY: TIBQuery;
    RECEPTDBASE: TIBDatabase;
    RECEPTTRANZ: TIBTransaction;
    penztarpanel: TPanel;
    uzenopanel: TPanel;
    Panel1: TPanel;
    Image1: TImage;

    procedure FormActivate(Sender: TObject);
    procedure AdatNullazas;
    procedure Adatfeldolgozas;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure GetcimletAdatbazis;
    procedure HaviKeszletTolto;
    procedure ElozonapiKeszletek;
    procedure ElozohaviAdatok;
    procedure ElozohaviMainForgalom;
    procedure WriteElonapi;
    procedure AdatParancs(_ukaz:string);
    procedure KorzetBeolvasas;
    procedure WriteElohavi;
    procedure WriteMainCurrency;
    procedure Tablofeliras;
    procedure KorzetMeghatarozas;
    procedure ByteIras(_byte: byte);
    procedure Wordiras(_word: word);
    procedure RealIras(_real: real);
    procedure IntegIras(_int: integer);
    procedure StrIras(_str: string);
    procedure Cimletfeliro(_c: string);
    procedure ForgalomBeolvasas;
    procedure ErtektarosBeolvasas;
    procedure TalanNemvoltNyitvaElsejen;
    procedure Elohavicimlet;

    function Nulele(_int: byte): string;
    function Getvalss(_vn: string): integer;
    function GetWesternAdatbazis: boolean;
    function ScanDnem(_dev: string):byte;
    function ScanKorzet(_kz: byte): byte;
    function Ezertektar(_pt: byte): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UjtabloKeszites: TUjtabloKeszites;
  _vdb: byte = 27;
  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                           'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY',
                           'MXN','NOK','NZD','PLN','RON','RSD','RUB','SEK',
                           'THB','TRY','UAH','USD');

  _forintIndex : byte = 11;

  _korzetnum: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzetszam: array[1..150] of byte;
  _korzetdb: array[1..8] of byte;
  _korzetiroda: array[1..8,1..35] of byte;
  _nyitva: array[1..150] of boolean;

  // ELÖZÖHAVI FORGALMI ADATOK:

  _munkanapok,_eMunkanapok: array[1..150] of byte;     // 1
  _eHaviVetel,_ehavieladas: array[1..150] of real;
  _euerme : array[1..150] of integer;

  _utolsomunkanap: array[1..150] of byte;

  _eHaviVugyfel,_eHaviEugyfel: array[1..150] of word;

  _evChf,_eeChf,_evEur,_eeEur,_evHrk,_eeHrk: array[1..150] of real;
  _evGbp,_eeGbp,_evUsd,_eeUsd,_evRon,_eeRon: array[1..150] of real;


  // NAPI FORGALMI ADATOK:

  _napiVetel,_napiEladas: array[1..150,1..31] of real;
  _napiVugyfel,_napiEugyfel: array[1..150,1..31] of word;
  _penztarosId: array[1..150,1..31] of string;

  // A 6 FÕBB VALUTA NAPI FORGALMI ADATAI:

  _vChf,_eChf,_vEur,_eEur,_vGbp,_eGbp: array[1..150,1..31] of real;
  _vHrk,_eHrk,_vUsd,_eUsd,_vRon,_eRon: array[1..150,1..31] of real;

  // ZÁRÓKÉSZLETEK:

  _zaroKeszlet : array[1..150,1..27] of integer;
  _eZaroKeszlet: array[1..150,1..27] of integer;
  _cimletSor:    array[1..150,1..27] of string;

  _wuniUsd,_wuniHuf,_afaHuf: array[1..150] of integer;

  // AZ UTOLSÓ NAPTÁRI MUNKANAP:

  _kertdatums,_headName,_itemName,_lastBlokk,_datum,_valutanem: string;
  _blokknum,_tipus,_elojel,_cimletTar,_cimletdatums: string;
  _csor,_eFarok,_tabloname,_tabloPath,_aktcimlet,_ps: string;

  _kertev,_kerthonap,_kertnap,_eev,_eho: word;

  _farok,_pcs,_aktDaybookName,_mezo,_jel,_aktfdbpath,_aktidkod: string;
  _sorveg: string = chr(13)+chr(10);

  _pc,_ertek,_recno,_ossz,_cc,_xx,_qq,_pp,_elozaro,_aktzaro,_bankjegy: integer;
  _lastday,_penztar,_lastNap,_aktnap,_valss,_aktptdb,_vv: byte;
  _hhi,_hlo,_hi,_lo,_lastclosedDay: byte;

  _ezertektar: boolean;

  _biniras : file of byte;
  _bytetomb: array[1..1024] of byte;


   _hVetel,
  _hEladas : real;

  _hvugyf,
  _heugyf  : word;

  _wusd,_whuf,_wmetro,_wtesco,_wafa: integer;

  _havivetel,_havieladas: array[1..150] of real;
  _haviVugyfel,_haviEugyfel: array[1..150] of word;

  _hvCHF,
  _heCHF,
  _vFrank,
  _eFrank,

  _hvEUR,
  _heEUR,
  _veu,
  _eeu,

  _hvGBP,
  _heGBP,
  _vFont,
  _eFont,

  _hvHRK,
  _heHRK,
  _vKuna,
  _eKuna,

  _vLei,
  _eLei,

  _hvUSD,
  _heUSD,

  _hvRon,
  _heRon,

  _vDollar,
  _eDollar: real;

  _aktvetel,_akteladas: real;
  _aktvugyf,_akteugyf: word;

  _aktid: string;


implementation

{$R *.dfm}

// =======================================================================
          procedure TUjtabloKeszites.FormActivate(Sender: TObject);
// =======================================================================

begin
  _kertdatums := _munkanap;
  _lastClosedDay := strtoint(midstr(_munkanap,9,2));

  Ujtablokeszites.Repaint;

  if _pc=1 then _kertDatums := Paramstr(1);

  _kertev     := strtoint(leftstr(_kertDatums,4));
  _kerthonap  := strtoint(midstr(_kertDatums,6,2));
  _kertnap    := strtoint(midstr(_kertDatums,9,2));

  AdatNullazas;
  Adatfeldolgozas;

  UzenoPanel.Caption := 'Tablok felirása';
  UzenoPanel.REPAINT;


  Tablofeliras;

  UzenoPanel.Caption := 'Készen vagyok';
  UzenoPanel.Repaint;
  sleep(5000);

  KilepoTimer.Enabled := true;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                        procedure TUjtabloKeszites.AdatNullazas;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var i,j: byte;

begin
  UzenoPanel.Caption := 'ADATNULLÁZÁS';
  uZENOPANEL.REPAINT;
  for i := 1 to 150 do
    begin
      _nyitva[i] := False;
      _euerme[i] := 0;

      //  A kért havi munkanap

      _munkanapok[i] := 0;   // *
      _utolsoMunkanap[i] := 0;

      // Az elözö havi munkanapok, elözöhavi összvétel és összeladás

      _eMunkanapok[i]  := 0;
      _eHavivetel[i]   := 0;
      _eHavieladas[i]  := 0;

       //  Az elözöhavi vételek és eladások összes ügyfélszáma

      _ehavivugyfel[i] := 0;
      _ehavieugyfel[i] := 0;

      //  Napi adatok:

      for j := 1 to 31 do
        begin

          // A kért havi vételek és eladások napi lebontásban:

          _napivetel[i,j]   := 0;            // *
          _napieladas[i,j]  := 0;            // *

          //  A fentiekhez  tartozó ügyfélszámok:

          _napivugyfel[i,j] := 0;            // *
          _napieugyfel[i,j] := 0;            // *

          // A kért hónapban dolgozó pénztárosok napi idkodja

          _penztarosid[i,j] := '';          // *

          //  Az 5 fõbb valuta napi vétele és eladása:

          _vChf[i,j] := 0;                 // *
          _eChf[i,j] := 0;

          _vEur[i,j] := 0;                 // *
          _eEur[i,j] := 0;

          _vGbp[i,j] := 0;                 // *
          _eGbp[i,j] := 0;

          _vHrk[i,j] := 0;                 // *
          _eHrk[i,j] := 0;

          _vUsd[i,j] := 0;                 // *
          _eUsd[i,j] := 0;

          _vRon[i,j] := 0;
          _eRon[i,j] := 0;
        end;

      // Az 5 fõbb valuta elözöhavi összes eladása, ill. vétele

      _evChf[i] := 0;
      _eeChf[i] := 0;

      _evEur[i] := 0;
      _eeEur[i] := 0;

      _evHrk[i] := 0;
      _eeHrk[i] := 0;

      _evGbp[i] := 0;
      _eeGbp[i] := 0;

      _evUsd[i] := 0;
      _eeUsd[i] := 0;

      _evRon[i] := 0;
      _eeRon[i] := 0;

      _wuniUsd[i] := 0;
      _wuniHuf[i] := 0;
      _afaHuf[i]  := 0;

      // Az összes valuta utolsó nap készlete és cimletei:

      for j := 1 to _VDB do
        begin
          _zarokeszlet[i,j] := 0;
          _cimletsor[i,j]   := '0,0,0,0,0,0,0,0,0,0,0,0,0,0';

          // Elözönapi (nyito) Készlet az összes valutára vonatkozóan:

          _ezarokeszlet[i,j] := 0;

        end;
   end;
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                      procedure TUjtabloKeszites.AdatFeldolgozas;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


begin
  UzenoPanel.Caption := 'ADATFELDOLGOZÁS';
  UzenoPanel.Repaint;

  _farok := inttostr(_kertev-2000)+nulele(_kerthonap);
  _aktdaybookName := 'DAYB' + _farok;

  DayBookdbase.Connected := true;
  _pcs := 'SELECT * FROM '+_aktDaybookName;

  with DayBookQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  //  ==========================================================================

  while not Daybookquery.Eof do
    begin
      _penztar := Daybookquery.FieldByName('PENZTAR').asInteger;
      _ezErtektar := ezertektar(_penztar);

      _lastday := 31;
      while _lastday>0 do
        begin
          _mezo := 'N' +  inttostr(_lastday);
          _jel := DayBookQuery.FieldByName(_mezo).asString;
          if _jel='B' then break;
          dec(_lastday);
        end;

      if _lastday=0 then
        begin
          TalanNemvoltNyitvaElsejen;
          DaybookQuery.next;
          continue;
        end;

      _aktfdbPath := 'c:\receptor\database\v' + inttostr(_penztar)+'.fdb';
      if not fileExists(_aktfdbPath) then
        begin
          DayBookQuery.Next;
          Continue;
        end;

      AdatDbase.close;
      Adatdbase.DatabaseName := _aktfdbPath;

      _headname := 'BF' + _farok;
      _itemName := 'BT' + _farok;

      AdatTabla.close;
      AdatTabla.TableName := _headname;
      AdatDbase.Connected := true;
      if not AdatTabla.Exists then
        begin
          AdatDbase.close;
          DaybookQuery.next;
          Continue;
        end;

      Application.ProcessMessages;

      if not _ezertektar then _ps := inttostr(_penztar)+'. PÉNZTÁR'
      else _ps := inttostr(_penztar)+'. ÉRTÉKTÁR';
      PenztarPanel.Caption := _PS;
      penztarPanel.Repaint;

      if not _ezErtektar then ForgalomBeolvasas else
        begin
          _utolsomunkanap[_penztar] := _lastClosedDay;
          ErtektarosBeolvasas;
        end;

      // -----------------------------------------------------------------------

      UzenoPanel.Caption := 'Havi készletek';
      UzenoPanel.Repaint;

      GetcimletAdatbazis;
      if _cimletDatums<>'' then HaviKeszletTolto;

      // -------------- Westerns és Afa keszletek ------------------------------

      if GetWesternAdatbazis then
        begin
          _wuniUsd[_penztar] := _wusd;
          _wuniHuf[_penztar] := _wHuf;
          _afaHuf[_penztar]  := _wTesco + _wMetro;
        end;

      AdatDbase.close;

      // -----------------------------------------------------------------------

      ElozonapiKeszletek;
      ElozohaviAdatok;
      ElozohaviMainForgalom;

      // -----------------------------------------------------------------------

      UzenoPanel.Caption := 'Elözõnapi- és haviadatok felirása';
      UzenoPanel.REPAINT;

      WriteElonapi;
      WriteElohavi;
      WriteMainCurrency;

      DayBookQuery.next;
    end;
  DAybookquery.close;
  dayBookdbase.close;

  // ---------------------------------------------------------------------------

end;



procedure TUjtabloKeszites.ErtektarosBeolvasas;

var _naps,_utdatum: string;
    _nap: byte;
    _code: integer;

begin
  _headname := 'BF' + _farok;

  Adatdbase.close;
  AdatDbase.connected := true;

  _pcs := 'SELECT * FROM ' + _headname + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with Adatquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  _UTDATUM := '2000.01.01';
  while not adatquery.eof do
    begin
      _datum := AdatQuery.FieldbyName('DATUM').asstring;
      if _datum>_utdatum then
        begin
          _aktidkod := AdatQuery.FieldByName('IDKOD').asString;
          _naps := midstr(_datum,9,2);
          val(_naps,_nap,_code);
          if _code<>0 then _nap := 0;
          if _nap>0 then _penztarosid[_penztar,_nap] := _aktidkod;
          _utdatum := _datum;
        end;
      AdatQuery.next;
    end;
  AdatQuery.close;
  AdatDbase.close;
end;




// =============================================================================
                         procedure TUjtabloKeszites.ForgalomBeolvasas;
// =============================================================================


begin

  Adatdbase.close;
  Adatdbase.connected := true;

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM ' + _headname + ' FEJ JOIN ' + _itemname + ' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND (TIPUS<>'+chr(39)+'F'+chr(39)+') ';
  _pcs := _pcs + 'AND (TIPUS<>' + chr(39) + 'U' + chr(39) + ') ';
  _pcs := _pcs + 'AND (FEJ.DATUM<='+chr(39) + _kertDatums + chr(39) + ')' + _sorveg;
  _pcs := _pcs + 'ORDER BY FEJ.DATUM,FEJ.BIZONYLATSZAM';

  with AdatQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  _lastNap := 0;
  _lastBlokk := 'XXXXXXX';

  while not AdatQuery.Eof do
    begin
      with adatquery do
        begin
          _datum        := FieldByname('DATUM').asString;
          _valutanem    := FieldbyName('VALUTANEM').asString;
          _blokknum     := FieldByName('BIZONYLATSZAM').asstring;
          _bankjegy     := FieldByName('BANKJEGY').asInteger;
          _tipus        := FieldByName('TIPUS').asString;
          _aktidkod     := FieldByName('IDKOD').asString;
          _ertek        := FieldByName('FORINTERTEK').asInteger;
          _elojel       := FieldByName('ELOJEL').asString;
        end;

      _aktnap := strtoint(midstr(_datum,9,2));

      if _aktnap<>_lastnap then
        begin
          _lastNap := _aktnap;
          _munkanapok[_penztar] := _munkanapok[_penztar] + 1;
          _penztarosId[_penztar,_aktnap] := _aktidkod;
        end;

      if _blokknum<>_lastblokk then
        begin
          if (_tipus='V') or (_tipus='K') then
          _napiVugyfel[_penztar,_aktnap] := _napiVugyfel[_penztar,_aktnap] + 1;

          if (_tipus='E') or (_tipus='K') then
          _napiEugyfel[_penztar,_aktnap] := _napiEUgyfel[_penztar,_aktnap] + 1;

          _lastBlokk := _blokknum;
        end;

      if _tipus='V' then _napiVetel[_penztar,_aktnap]  := _napiVetel[_penztar,_aktnap] + _ertek;
      if _tipus='E' then _napiEladas[_penztar,_aktnap] := _napiEladas[_penztar,_aktnap] + _ertek;
      if _tipus='K' then
        begin
          if _elojel='+' then _napiVetel[_penztar,_aktnap]  := _napiVetel[_penztar,_aktnap] + _ertek
          else begin
             if _valutanem<>'HUF' then
               _napiEladas[_penztar,_aktnap] := _napiEladas[_penztar,_aktnap] + _ertek;
          end;
        end;

      _valss := GetValss(_valutanem);
      if _valss>0 then
        begin
          case _valss of
            1: begin
                 if _elojel='+' then _vCHf[_penztar,_aktnap] := _vChf[_penztar,_aktnap] + _bankjegy
                 else _eCHf[_penztar,_aktnap] := _eChf[_penztar,_aktnap] + _bankjegy
               end;

            2: begin
                 if _elojel='+' then _vEur[_penztar,_aktnap] := _vEur[_penztar,_aktnap] + _bankjegy
                 else _eEur[_penztar,_aktnap] := _eEur[_penztar,_aktnap] + _bankjegy
               end;

            3: begin
                 if _elojel='+' then _vGbp[_penztar,_aktnap] := _vGbp[_penztar,_aktnap] + _bankjegy
                 else _eGbp[_penztar,_aktnap] := _eGbp[_penztar,_aktnap] + _bankjegy
               end;

            4: begin
                 if _elojel='+' then _vHrk[_penztar,_aktnap] := _vHrk[_penztar,_aktnap] + _bankjegy
                 else _eHrk[_penztar,_aktnap] := _eHrk[_penztar,_aktnap] + _bankjegy
               end;

            5: begin
                 if _elojel='+' then _vUsd[_penztar,_aktnap] := _vUsd[_penztar,_aktnap] + _bankjegy
                 else _eUsd[_penztar,_aktnap] := _eUsd[_penztar,_aktnap] + _bankjegy
               end;

            6: begin
                 if _elojel='+' then _vRon[_penztar,_aktnap] := _vRon[_penztar,_aktnap] + _bankjegy
                 else _eRon[_penztar,_aktnap] := _eRon[_penztar,_aktnap] + _bankjegy
               end;
          end;
        end;
      adatQuery.next;
    end;
  Adatquery.close;
  Adatdbase.close;

  _utolsoMunkanap[_penztar] := _lastnap;
end;



// =============================================================================
                 function TUjtabloKeszites.Getvalss(_vn: string): integer;
// =============================================================================

begin
  result := 0;
  if _vn='CHF' then result := 1;
  if _vn='EUR' then result := 2;
  if _vn='GBP' then result := 3;
  if _vn='HRK' then result := 4;
  if _vn='USD' then result := 5;
  if _vn='RON' then result := 6;
end;


// =============================================================================
               procedure TUjtabloKeszites.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := False;
  ModalResult := 1;
end;

// =============================================================================
               function TUjtabloKeszites.Nulele(_int: byte): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
             function TUjtabloKeszites.ScanDnem(_dev: string):byte;
// =============================================================================

begin
  result := 1;
  while result<=_VDB do
    begin
      if _dnem[result]=_dev then exit;
      inc(result);
    end;
end;


// =============================================================================
                   function TUjtabloKeszites.GetWesternAdatbazis: boolean;
// =============================================================================

var _wZarnev: string;

begin

  Result := false;

  _wzarNev := 'WZAR' + _farok;
  Adattabla.close;
  AdatTabla.TableName := _wzarnev;
  AdatDbase.Connected := True;
  if not Adattabla.Exists then
    begin
      Adatdbase.close;
      exit;
    end;  


  _pcs := 'SELECT * FROM ' + _wzarnev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM<=' + chr(39) + _kertdatums + chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  AdatDbase.close;
  adatdbase.Connected := true;
  with AdatQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  // Ha nincs az e-havi adatbázisban bejegyzes ....

  if _recno=0 then
    begin
      Adatquery.close;

      // Megnézzük az elözõ havi adatbázist ........

      _eev := _kertev;
      _eHo := _kerthonap-1;

      if _eHo=0 then
        begin
          _eHo := 12;
          dec(_eev);
        end;

      _eFarok := inttostr(_eev-2000)+nulele(_eHo);
      _wzarnev := 'WZAR' + _efarok;

      // ha nincs elözõhavi wzar-tábla - akkor nincs adat

      Adattabla.TableName := _wzarnev;
      if not AdatTabla.Exists then exit;

      // Megynyitja az utolsó bejegyzést az elözö havi wzar-táblában

      _pcs := 'SELECT * FROM '+ _wzarnev + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with AdatQuery do
        begin
          Close;
          sql.clear;
          Sql.add(_pcs);
          Open;
          Last;
          _recno := recno;
        end;

      // Ha az elözö havi wzártábla üres - akkor nincs adat
      if _recno=0 then
        begin
          AdatQuery.close;
          Adatdbase.close;
          exit;
        end;
    end;

  // ------ Itt meg van nyitva a legutolsó wzar rekord:

  _wusd := Adatquery.FieldByName('USDZARO').asInteger;
  _wHuf := Adatquery.FieldByName('HUFZARO').asInteger;
  _wMetro := AdatQuery.FieldByName('METROZARO').asInteger;
  _wTesco := AdatQuery.FieldByName('TESCOZARO').asInteger;
  AdatQuery.close;
  Adatdbase.close;
  result := true;
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                   procedure TUjtabloKeszites.GetcimletAdatbazis;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

begin
  _cimlettar := 'CIMT' + _farok;
  Adatdbase.connected := true;
  AdatTabla.TableName := _cimlettar;
  if not AdatTabla.Exists then
    begin
      Elohavicimlet;
      exit;
    end;  


  _pcs := 'SELECT * FROM '+ _cimletTar + _sorveg;
  _pcs := _pcs + 'WHERE DATUM<=' + chr(39) + _kertdatums + chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  Adatdbase.Connected := true;
  with AdatQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno=0 then
    begin

      AdatQuery.close;
      EloHavicimlet;
      exit;

    end;

  _cimletdatums := AdatQuery.FieldByName('DATUM').asString;
  AdatQuery.close;

end;



procedure TUJtabloKeszites.Elohavicimlet;

begin
  _eev := _kertev;
  _eHo := _kerthonap-1;
  if _eHo=0 then
    begin
      _eHo := 12;
      dec(_eev);
    end;

  _eFarok := inttostr(_eev-2000)+nulele(_eHo);
  _cimlettar := 'CIMT' + _efarok;

  Adatdbase.connected := True;
  Adattabla.TableName := _cimlettar;
  if not AdatTabla.Exists then
    begin
      _cimlettar := '';
      _cimletdatums := '';
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _cimletTar + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with AdatQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      AdatQuery.close;

      _cimlettar := '';
      _cimletdatums := '';
      exit;
    end;
  _cimletdatums := AdatQuery.FieldByName('DATUM').asString;
  Adatquery.close;
end;






// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                       procedure TUjtabloKeszites.HaviKeszletTolto;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var _z,_coin1,_coin2: integer;

begin
  _pcs := 'SELECT * FROM ' + _cimlettar + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _cimletdatums + chr(39);

  with Adatquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not Adatquery.eof do
    begin
      _valutanem := AdatQuery.FieldByName('VALUTANEM').asString;
      _ossz := AdatQuery.FieldbyName('OSSZESEN').asInteger;
      _csor := '';
      _z := 1;

      while _z<=14 do
        begin
          _mezo := 'CIMLET'+inttostr(_z);
          _cc := AdatQuery.FieldbyName(_mezo).asInteger;
          _csor := _csor + inttostr(_cc);
          if _z<14 then _csor := _csor + ',';
          inc(_z);
        end;

      if _valutanem='EUR' then
        begin
          _coin2 := Adatquery.FieldByName('CIMLET13').asInteger;
          _coin1 := Adatquery.FieldByName('CIMLET14').asInteger;
          _euerme[_penztar] := _coin2 + _coin2 + _coin1;
        end;

      _xx := scandnem(_valutanem);
      _zarokeszlet[_penztar,_xx] := _ossz;
      _cimletsor[_penztar,_xx] := _csor;

      Adatquery.next;
    end;

  Adatquery.close;
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                   procedure TUjtabloKeszites.ElozonapiKeszletek;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var _elodatums: string;

begin
  _pcs := 'SELECT * FROM ELONAPI' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM<' + chr(39)+ _kertdatums + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with AdatQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      _elodatums := FieldByName('DATUM').asString;
    end;

  if _recno=0 then
    begin
      AdatQuery.close;
      exit;
    end;

  // --------------------------------------------------------------------------

  _pcs := 'SELECT * FROM ELONAPI' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39)+ _elodatums + chr(39);

   with AdatQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not adatquery.Eof do
    begin
      _ossz := AdatQuery.FieldByName('OSSZESEN').asInteger;
      _valutanem := adatquery.FieldByName('VALUTANEM').asString;
      _xx := scandnem(_valutanem);
      _ezarokeszlet[_penztar,_xx] := _ossz;
      Adatquery.Next;
    end;
  AdatQuery.close;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                      procedure TUjtabloKeszites.ElozohaviAdatok;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _aktevhos: string;

begin
  _aktevhos := leftstr(_kertdatums,4) + midstr(_kertdatums,6,2);
  _pcs := 'SELECT * FROM ELOHAVI' + _sorveg;
  _pcs := _pcs + 'WHERE EVHOSTRING<'+chr(39)+_aktevhos + chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY EVHOSTRING';

  with Adatquery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      AdatQuery.close;
      exit;
    end;

  with AdatQuery do
    begin
      _eMunkanapok[_penztar]  := FieldByname('NAPOK').asInteger;
      _eHaviVetel[_penztar]   := FieldByName('VETEL').asFloat;
      _eHaviEladas[_penztar]  := FieldByName('ELADAS').asFloat;
      _eHaviVugyfel[_penztar] := FieldByName('VETELUGYFELDARAB').asInteger;
      _eHaviEugyfel[_penztar] := FieldByName('ELADASUGYFELDARAB').asInteger;
      Close;
    end;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                   procedure TUjtabloKeszites.ElozoHaviMainForgalom;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var _multev,_multho: word;

begin
  _multev := _kertev;
  _multho := _kerthonap-1;
  if _multho=0 then
    begin
      _multho := 12;
      dec(_multev);
    end;

  _pcs := 'SELECT * FROM MAINCURR' + _sorveg;
  _pcs := _pcs + 'WHERE (EV='+inttostr(_multev)+') AND (HONAP='+inttostr(_multho)+')';
  with AdatQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      AdatQuery.close;
      exit;
    end;

  _evCHF[_penztar] := adatQuery.FieldByNAme('VCHF').asFloat;
  _eeCHF[_penztar] := adatQuery.FieldByNAme('ECHF').asFloat;
  _evEUR[_penztar] := adatQuery.FieldByNAme('VEUR').asFloat;
  _eeEUR[_penztar] := adatQuery.FieldByNAme('EEUR').asFloat;
  _evGBP[_penztar] := adatQuery.FieldByNAme('VGBP').asFloat;
  _eeGBP[_penztar] := adatQuery.FieldByNAme('EGBP').asFloat;
  _evHRK[_penztar] := adatQuery.FieldByNAme('VHRK').asFloat;
  _eeHRK[_penztar] := adatQuery.FieldByNAme('EHRK').asFloat;
  _evUSD[_penztar] := adatQuery.FieldByNAme('VUSD').asFloat;
  _eeUSD[_penztar] := adatQuery.FieldByNAme('EUSD').asFloat;
  _evRON[_penztar] := adatQuery.FieldByNAme('VRON').asFloat;
  _eeRON[_penztar] := adatQuery.FieldByNAme('ERON').asFloat;


  AdatQuery.close;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                        procedure TUjtabloKeszites.WriteElonapi;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _z: byte;

begin
  _pcs := 'DELETE FROM ELONAPI WHERE DATUM='+chr(39)+_kertdatums+chr(39);
  AdatParancs(_pcs);

  _z := 1;
  while _z<=_VDB do
    begin
      _ossz := _zarokeszlet[_penztar,_z];
      if _ossz>0 then
        begin
          _pcs := 'INSERT INTO ELONAPI (DATUM,VALUTANEM,OSSZESEN)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + CHR(39)+_kertdatums+chr(39)+',';
          _pcs := _pcs + chr(39) + _dnem[_z] + chr(39) + ',';
          _pcs := _pcs + inttostr(_ossz)+')';
          AdatParancs(_pcs);
        end;
      inc(_z);
    end;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                       procedure TUjtabloKeszites.WriteElohavi;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var _evhostring: string;
    i: integer;

begin
  _evhostring := inttostr(_kertev)+nulele(_kerthonap);
  _pcs := 'DELETE FROM ELOHAVI WHERE EVHOSTRING='+chr(39)+_evhostring+chr(39);
  AdatParancs(_pcs);

  _hVetel  := 0;
  _hEladas := 0;
  _hvugyf  := 0;
  _heugyf  := 0;

  for i := 1 to 31 do
    begin
      _hVetel  := _hVetel + _napivetel[_penztar,i];
      _hEladas := _hEladas + _napiEladas[_penztar,i];
      _hvugyf  := _hvugyf + _napiVugyfel[_penztar,i];
      _heugyf  := _heugyf + _napiEugyfel[_penztar,i];
    end;

  _havivetel[_penztar]   := _hvetel;
  _havieladas[_penztar]  := _hEladas;
  _haviVugyfel[_penztar] := _hvugyf;
  _haviEUgyfel[_penztar] := _heugyf;

  _pcs := 'INSERT INTO ELOHAVI (EVHOSTRING,NAPOK,VETEL,ELADAS,VETELUGYFELDARAB,';
  _PCS := _pcs + 'ELADASUGYFELDARAB)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _evhostring + chr(39) + ',';
  _pcs := _pcs + inttostr(_munkanapok[_penztar]) + ',';
  _pcs := _pcs + floattostr(_hvetel) + ',';
  _pcs := _pcs + floattostr(_hEladas) + ',';
  _pcs := _pcs + inttostr(_hvugyf) + ',';
  _pcs := _pcs + inttostr(_heugyf) + ')';

  AdatParancs(_pcs);
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                        procedure TUjtabloKeszites.WriteMainCurrency;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var i: integer;

begin
  _pcs := 'DELETE FROM MAINCURR WHERE (EV='+inttostr(_kertev);
  _pcs := _pcs + ') AND (HONAP='+inttostr(_kerthonap)+')';
  AdatParancs(_pcs);

  _hvCHF := 0;
  _heCHF := 0;

  _hvEUR := 0;
  _heEUR := 0;

  _hvGBP := 0;
  _heGBP := 0;

  _hvHRK := 0;
  _heHRK := 0;

  _hvUSD := 0;
  _heUSD := 0;

  _hvRon := 0;
  _heRON := 0;

  for i := 1 to 31 do
    begin
      _hvCHF := _hvCHF + _vCHF[_penztar,i];
      _heCHF := _heCHF + _eCHF[_penztar,i];
      _hvEUR := _hvEUR + _vEUR[_penztar,i];
      _heEUR := _heEUR + _eEUR[_penztar,i];
      _hvHRK := _hvHRK + _vHRK[_penztar,i];
      _heHRK := _heHRK + _eHRK[_penztar,i];
      _hvGBP := _hvGBP + _vGBP[_penztar,i];
      _heGBP := _heGBP + _eGBP[_penztar,i];
      _hvUSD := _hvUSD + _vUSD[_penztar,i];
      _heUSD := _hvUSD + _eUSD[_penztar,i];
      _hvRON := _hvRON + _vRON[_penztar,i];
      _heRON := _hvRON + _eRON[_penztar,i];
    end;

  _pcs := 'INSERT INTO MAINCURR (EV,HONAP,VCHF,ECHF,VEUR,EEUR,VGBP,EGBP,';
  _PCS := _pcs + 'VHRK,EHRK,VUSD,EUSD,VRON,ERON)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_kertev) + ',';
  _pcs := _pcs + inttostr(_kerthonap) + ',';

  _pcs := _pcs + floattostr(_hvCHF) + ',';
  _pcs := _pcs + floattostr(_heCHF) + ',';

  _pcs := _pcs + floattostr(_hvEUR) + ',';
  _pcs := _pcs + floattostr(_heEUR) + ',';

  _pcs := _pcs + floattostr(_hvGBP) + ',';
  _pcs := _pcs + floattostr(_heGBP) + ',';

  _pcs := _pcs + floattostr(_hvHRK) + ',';
  _pcs := _pcs + floattostr(_heHRK) + ',';

  _pcs := _pcs + floattostr(_hvUSD) + ',';
  _pcs := _pcs + floattostr(_heUSD) + ',';

  _pcs := _pcs + floattostr(_hvRON) + ',';
  _pcs := _pcs + floattostr(_heRON) + ')';


  AdatParancs(_pcs);
end;


// =============================================================================
              procedure TUjtabloKeszites.AdatParancs(_ukaz:string);
// =============================================================================


begin
  AdatDbase.close;
  Adatdbase.connected := true;
  if adatTranz.InTransaction then adattranz.Commit;
  Adattranz.StartTransaction;
  with adatquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  AdatTranz.commit;
  Adatdbase.close;
end;

// =============================================================================
                procedure TUjtabloKeszites.Korzetbeolvasas;
// =============================================================================

var i,_u,_k: integer;
    _c: string;

begin
  for i := 1 to 150 do _korzetszam[i] := 0;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;

  Receptdbase.connected := true;
  with ReceptQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not Receptquery.eof do
    begin
      _u := Receptquery.FieldByName('UZLET').asInteger;
      _k := ReceptQuery.FieldByName('ERTEKTAR').asInteger;
      _c := ReceptQuery.FieldByName('CLOSED').asString;
      _korzetszam[_u] := _k;
      if _c<>'X' then _nyitva[_u] := true;

      ReceptQuery.next;
    end;
  _nyitva[34] := False;
  receptQuery.close;
  ReceptDbase.close;
end;


// =============================================================================
                    procedure TUjtabloKeszites.KorzetMeghatarozas;
// =============================================================================

var i: integer;
    _aktkorzet,_kdb: byte;

begin
  KorzetBeolvasas;
  for i := 1 to 8 do _korzetdb[i] := 0;

  for i := 1 to 150 do
    begin
      if (_nyitva[i]) AND (NOT Ezertektar(i)) then
        begin
          _aktkorzet := _korzetszam[i];
          _xx := scankorzet(_aktkorzet);

          _kdb :=  _korzetdb[_xx];
          inc(_kdb);
          _korzetiroda[_xx,_kdb] := i;
          _korzetdb[_xx] := _kdb;
        end;
    end;

  // -------------------------------------------------

  for i := 1 to 8 do
    begin
      _kdb := _korzetdb[i];
      inc(_kdb);
      _korzetiroda[I,_kdb] := _korzetnum[i];
      _korzetdb[i] := _kdb;
    end;


end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                 function TUjtabloKeszites.ScanKorzet(_kz: byte): byte;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

begin
  result := 1;
  while result<=8 do
    begin
      if _korzetnum[result]=_kz then exit;
      inc(result);
    end;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                        procedure  TUjtabloKeszites.Tablofeliras;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var _ehavivChf,_ehavieChf,_ehavivEur,_ehavieEur,_ehavivGbp,_ehavieGbp: real;
    _ehavivUsd,_ehavieUsd,_ehavivRon,_ehavieRon,_ehavivHrk,_ehavieHrk: real;
    _ptErme: integer;

begin

  Korzetmeghatarozas;
  _qq := 1;
  while _qq<=8 do
    begin
      _tabloname := 'Tab_' + _farok + '.' + inttostr(_korzetnum[_qq]);
      _tabloPath := 'c:\receptor\mail\tablo\' + _tabloname;

      // ---  Tablófelirás - start !!

      AssignFile(_biniras,_tablopath);
      rewrite(_biniras);

      // A tabló ID-kódjának felirása ...

      ByteIras(78);   // NX - IDKOD
      ByteIras(88);   // X

      // A hónapzárás napja ....

      ByteIras(_kertnap);

      // A körzet pénztárainak darabszámának felirása ...

      _AktPtDb := _korzetDb[_QQ];
      ByteIras(_aktPtDb);

      _pp := 1;
      while _pp<=_aktPtdb do
        begin

          // A pénztár számának felirása:

          _penztar := _korzetiroda[_qq,_pp];
          Byteiras(_penztar);

          // Elözõ havi munkanapok száma:

          Byteiras(_eMunkanapok[_penztar]);

          // Elözõ havi vétel és eladás:

          RealIras(_eHaviVetel[_penztar]);
          RealIras(_eHaviEladas[_penztar]);

          // Elözõ havi ügyfelek:

          WordIras(_eHaviVUgyfel[_penztar]);
          Wordiras(_eHaviEUgyfel[_penztar]);

          // Az aktuálhavi munkanapok eddig a hónapban:

          ByteIras(_munkanapok[_penztar]);
          _lastnap := _utolsomunkanap[_penztar];

          // Az utolsó lezárt nap a hónapban:

          ByteIras(_lastnap);

          _aktnap := 1;
          while _aktnap<=_lastNap do
            begin
              // Napi forgalmak és ügyfélszámok:

              _aktvetel := _napivetel[_penztar,_aktnap];
              _akteladas:= _napieladas[_penztar,_aktnap];
              _aktvugyf := _napiVUgyfel[_penztar,_aktnap];
              _akteUgyf := _napiEugyfel[_penztar,_aktnap];

              // A napi pénztárosok:

              _aktid    := _penztarosid[_penztar,_aktnap];

              // Az egyes valuták napi forgalmai:

              _vfrank   := _vChf[_penztar,_aktnap];
              _eFrank   := _eChf[_penztar,_aktnap];
              _veu      := _vEur[_penztar,_aktnap];
              _eeu      := _eEur[_penztar,_aktnap];
              _vKuna    := _vHrk[_penztar,_aktnap];
              _eKuna    := _eHrk[_penztar,_aktnap];
              _vFont    := _vGbp[_penztar,_aktnap];
              _eFont    := _eGbp[_penztar,_aktnap];
              _vDollar  := _vUsd[_penztar,_aktnap];
              _eDollar  := _eUsd[_penztar,_aktnap];

              _vLei  := _vRon[_penztar,_aktnap];
              _eLei  := _eRon[_penztar,_aktnap];

              // A napi vétel és eladás felirása:

              Realiras(_aktvetel);
              Realiras(_akteladas);

              // A napi ügyfélszám felirása:

              WordIras(_aktvugyf);
              WordIras(_akteugyf);

              // A pénztárosid-k felirása:

              StrIras(_aktid);

              // A fontosabb valuták forgalmai felirása:

              Realiras(_vFrank);
              RealIras(_eFrank);

              RealIras(_veu);
              RealIras(_eeu);

              RealIras(_vFont);
              Realiras(_efont);

              Realiras(_vKuna);
              RealIras(_eKuna);

              Realiras(_vDollar);
              Realiras(_eDollar);

              Realiras(_vLei);
              Realiras(_eLei);

              inc(_aktnap);
            end;

         // ----------------  Keszletek ------------------------------------

         _vv := 1;
         while _vv<=_VDB do
           begin
             _elozaro := _ezarokeszlet[_penztar,_vv];
             _aktzaro := _zarokeszlet[_penztar,_vv];
             _aktcimlet := _cimletsor[_penztar,_vv];

             Integiras(_elozaro);
             Integiras(_aktzaro);
             Cimletfeliro(_aktcimlet);
             inc(_vv);
           end;

         _wusd := _wuniUsd[_penztar];
         _wHuf := _wuniHuf[_penztar];
         _wAfa := _afaHuf[_penztar];

         Integiras(_wusd);
         Integiras(_wHuf);
         Integiras(_wafa);

         // Az elözö havi föbb 6 valutaforgalma:

         _ehavivChf := _evChf[_penztar];
         _ehavieChf := _eeChf[_penztar];

         _ehavivEur := _evEur[_penztar];
         _ehavieEur := _eeEur[_penztar];

         _ehavivGbp := _evGbp[_penztar];
         _ehavieGbp := _eeGbp[_penztar];

         _ehavivHrk := _evHrk[_penztar];
         _ehavieHrk := _eeHrk[_penztar];

         _ehavivUsd := _evUsd[_penztar];
         _ehavieUsd := _eeUsd[_penztar];

         _ehavivRon := _evRon[_penztar];
         _ehavieRon := _eeRon[_penztar];

         // ------------------------------

         Realiras(_ehavivChf);
         Realiras(_ehavieChf);

         Realiras(_ehavivEur);
         Realiras(_ehavieEur);

         Realiras(_ehavivGbp);
         Realiras(_ehavieGbp);

         Realiras(_ehavivHrk);
         Realiras(_ehavieHrk);

         Realiras(_ehavivUsd);
         Realiras(_ehavieUsd);

         Realiras(_ehavivRon);
         Realiras(_ehavieRon);

         // -------- Az euroérme darabszáma ------------------------------------

         _pterme := _euerme[_penztar];
         IntegIras(_ptErme);

         inc(_pp);
       end;

      // ----------- control-summa ---------------------------------------------

      byteiras(255);
      byteiras(255);
      byteiras(255);
      Closefile(_biniras);

      inc(_qq);
    end;
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                     procedure TUjtabloKeszites.Byteiras(_byte:byte);
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


begin
  _bytetomb[1] := _Byte;
  Blockwrite(_biniras,_bytetomb,1);
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                      procedure TUjtabloKeszites.WordIras(_word: word);
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


begin
  _hi := trunc(_word/256);
  _lo := _word - trunc(256*_hi);
  _bytetomb[1] := _lo;
  _bytetomb[2] := _hi;
  Blockwrite(_biniras,_bytetomb,2);
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                     procedure TUjtabloKeszites.realIras(_real: real);
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _maradt: integer;

begin
  _hhi := trunc(_real/16777216);
  _maradt := trunc(_real-trunc(_hhi*16777216));
  _hlo := trunc(_maradt/65536);
  _maradt := _maradt - trunc(65536*_hlo);
  _hi := trunc(_maradt/256);
  _lo := _maradt - trunc(256*_hi);

  _bytetomb[1] := _lo;
  _bytetomb[2] := _hi;
  _bytetomb[3] := _hlo;
  _bytetomb[4] := _hhi;

  Blockwrite(_biniras,_bytetomb,4);
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                    procedure TUjtabloKeszites.IntegIras(_int: integer);
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _maradt: integer;

begin
  _hhi := trunc(_int/16777216);
  _maradt := _int-trunc(_hhi*16777216);
  _hlo := trunc(_maradt/65536);
  _maradt := _maradt - trunc(65536*_hlo);
  _hi := trunc(_maradt/256);
  _lo := _maradt - trunc(256*_hi);

  _bytetomb[1] := _lo;
  _bytetomb[2] := _hi;
  _bytetomb[3] := _hlo;
  _bytetomb[4] := _hhi;

  Blockwrite(_biniras,_bytetomb,4);
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                      procedure TUjtabloKeszites.StrIras(_str: string);
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _len,_y,_kod: byte;

begin
  _str := trim(_str);
  _len :=length(_str);
  if _len=0 then
    begin
      byteIras(0);
      exit;
    end;

  _bytetomb[1] := _len;
  _y := 1;

  while _y<=_len do
    begin
      _kod := 255 - ord(_str[_y]);
      _bytetomb[_y+1] := _kod;
      inc(_y);
    end;
  Blockwrite(_biniras,_bytetomb,1+_len);
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
        procedure TUjtabloKeszites.Cimletfeliro(_c: string); //  123,4,2,12, ..  14 szám
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var _pp,_len,_betukod: byte;
    _ws: string;
    _clet: word;

begin
  _pp := 1;
  _len := length(_c);
  while _pp<=_len do
    begin
      _ws := '';
      while true do
        begin
          _betukod := ord(_c[_pp]);
          if (_betukod=44) then
            begin
              inc(_pp);
              break;
            end;
          _ws := _ws + chr(_betukod);
          inc(_pp);
          if _pp>_len then break;
        end;
      _Clet := strtoint(_ws);
      WordIras(_cLet);
    end;
end;

// =============================================================================
                 function TUjtabloKeszites.Ezertektar(_pt: byte): boolean;
// =============================================================================

var _y: byte;

begin
  result := false;
  _y:= 1;
  while _y<=8 do
    begin
      if _korzetNum[_y]=_pt then
        begin
          result := true;
          exit;
        end;
      inc(_y);
    end;
end;



procedure TUjtablokeszites.TalanNemvoltNyitvaElsejen;

begin
  _aktfdbPath := 'c:\receptor\database\v' + inttostr(_penztar)+'.fdb';
  if not fileExists(_aktfdbPath) then exit;

  AdatDbase.close;
  Adatdbase.DatabaseName := _aktfdbPath;

   Application.ProcessMessages;

   if not _ezertektar then _ps := inttostr(_penztar)+'. PÉNZTÁR'
   else _ps := inttostr(_penztar)+'. ÉRTÉKTÁR';
   PenztarPanel.Caption := _PS;
   penztarPanel.Repaint;

   GetcimletAdatbazis;
   if _cimletDatums<>'' then HaviKeszletTolto;

   // -------------- Westerns és Afa keszletek ------------------------------

   if GetWesternAdatbazis then
     begin
       _wuniUsd[_penztar] := _wusd;
       _wuniHuf[_penztar] := _wHuf;
       _afaHuf[_penztar]  := _wTesco + _wMetro;
     end;

   AdatDbase.close;
end;


end.
