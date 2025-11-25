unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  strutils, printers, dateutils;

type
  TBlokkNyom = class(TForm)

    ValutaQuery: TIBQuery;
    ValutaDbase: TIBDatabase;
    ValutaTranz: TIBTransaction;
    kilepotimer: TTimer;

    Shape1     : TShape;
    Label1     : TLabel;

    procedure FormActivate(Sender: TObject);
    procedure Nullazo;

    // A nyomtatáshoz szükséges adatok beolvasásasa:

    procedure GetVtempBasic;
    procedure GetPartnerPara;
    procedure GetPenztarData;
    procedure NaturadatokBeolvasasa;
    procedure JogiAdatokBeolvasasa;

    // Cimlet nyomtatas procedurai:

    function CimletBedolgozas: boolean;
    function Getword: word;
    function Getbyte: byte;
    procedure CimletNyomtatas;

    // Ötféle számla nyomtatása:

    procedure VetelSzamlaNyomtatas;
    procedure EladasSzamlaNyomtatas;
    procedure AtadBlokkNyomtatas;
    procedure AtveszBlokkNyomtatas;
    procedure StornoBlokknyomtatas;

    // Bizonylat részlet nyomtatások:

    procedure ArfModNyomtatas;
    procedure ReklamNyomtatas;
    procedure Ugyfelnyomtatas;
    procedure SajatNyil;

    procedure Jogcimnyilatkozat;
    procedure DevizsStatuszNyomtatas;
    procedure KozszerepNyilatkozat(_ksz: byte);
    procedure BlokkFocimIro;
    procedure BlokkFejlecIro;
    procedure BlokkTetelIro;

    // Segéd programok

    procedure VonalHuzo;
    procedure KozepreIr(_szoveg: string);
    procedure TextKiiro;
    procedure KilepotimerTimer(Sender: TObject);
    procedure Soremeles;
    procedure OroszNyilatkozat;
    procedure StartNyomtatas;

    // Segéd funkciók:

    function Elokieg(_s:string;_h: byte):string;
    function HunDateTostr(_caldat: TDateTime): string;
    function ForintForm(_osszeg:integer):string;
    function ArfolyamForm(_curr: real): string;
    function Nulele(_i: integer):string;
    function EzoroszUgyfel: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BlokkNyom: TBlokkNyom;

  _cimDataPath   : string = 'c:\valuta\aktcim.dat';
  _binOlvas      : File of byte;
  _bytetomb      : array[1..16] of byte;

  _nyomTipus     : byte;      // ha nagyobb 10-nél, akkor másolat
  _tranztip      : string;    // tranzakció megnevezése (pl valuta vetel)
  _mondat        : string;

  _copyblokk     : boolean;

  _LFile         : textfile;
  _printer       : byte;
  _wideon        : string = #14;
  _wideoff       : string = #20;

  _inic          : string = #27#64;
  _Lf5           : string = #27#97#5;

  _pcs           : string;

  _sorveg: string = chr(13) + chr(10);


  // penztar adatai:

  _aktpenztarszam: byte;
  _aktPenztarkod : string;
  _aktpenztarnev : string;
  _aktpenztarcim : string;
  _akttelefon    : string;
  _aktadoszam    : string;
  _kartyaszam    : string;
  _cegnev        : string;
  _tszulhely     : string;
  _tSzulido      : string;
  _iso           : string;

  _yValDarab     : integer;
  _yNev          : array[1..3] of string;
  _yCdb          : array[1..3] of byte;
  _yC,_yB        : array[1..3,1..14] of word;

  // Tulajdonosok adatai

  _tNev,_tcim,_tSzulData: array[1..4] of string;
  _tAllamp,_ttarthely,_tjelleg,_tMertek: array[1..4] of string;

  _tKozszerep: array[1..4] of byte;

  _vanCimlet      : boolean;

  _ugyfeltipus    : string;
  _statusz        : string;
  _ugyfelszam     : integer;
  _megbizoszam    : integer;
  _mbszama        : integer;

  _securlevel     : byte;
  _kulfoldi       : byte;
  _kozszereplo    : byte;
  _tulajdarab     : byte;
  _mbkozszerep    : byte;

  _ugyfelnev      : string;
  _ugyfelcim      : string;
  _anyjaneve      : string;
  _aktprosnev     : string;
  _alcsopnev      : string;
  _currency       : string;

  _datum          : string;
  _ido            : string;
  _bizonylatszam  : string;
  _tipus          : string;
  _mbneve         : string;

  _szulhely       : string;
  _szulido        : string;
  _lakcim         : string;
  _irszam         : string;
  _varos          : string;
  _utca           : string;
  _ukozszerep     : integer;
  _engedelyezo    : string;
  _megbizonev     : string;

  _okmanytip      : string;
  _azonosito      : string;
  _tarthely       : string;

  _joginev        : string;
  _jogihely       : string;
  _okiratszam     : string;
  _cAdoszam       : string;
  _mbcime         : string;

  _tetel          : byte;
  _storno         : byte;
  _tuldarab       : byte;
  _tk             : byte;

  _konverzio      : byte;
  _width          : word;
  _height         : word;

  _qq             : integer;
  _recno          : integer;
  _skaf,_kaf      : integer;

  _netto          : integer;
  _fizetendo      : integer;
  _kezelesidij    : integer;
  _tarspenztarnev : string;
  _fizetoeszkoz   : byte;
  _kerekites      : integer;
  _code           : integer;

  _aktdnem        : string;
  _aktarfolyam    : integer;
  _arfolyam       : integer;
  _arfolyamreal   : integer;
  _aktbankjegy    : integer;
  _aktertek       : integer;
  _elojel         : string;

  _konvarfolyam   : integer;
  _kapforint      : integer;
  _kapbankjegy    : integer;
  _kapertek       : integer;
  _sumkonv        : integer;
  _konvdnem       : string;
  _adoszam        : string;
  _megnyitottnap  : string;

  _penztarkod     : string;
  _szallitonev    : string;
  _plombaszam     : string;
  _forras         : string;
  _nyil           : string;

  _lmezo          : string;
  _tmezo          : string;
  _amezo          : string;

  _stornoBizonylat: string;
  _megjegyzes     : string;
  _reprintindok   : string;
  _stornoindok    : string;
  _tranznev       : string;
  _zcounts        : string;
  _recnums        : string;

  _precarfs       : string;
  _akttort        : string;
  _precarf        : real;

  _oroszugyfel    : boolean;

  _nyomtatvanyPath: string = 'C:\VALUTA\AKTLST.TXT';

function blokknyomtatas(_para: integer): integer; stdcall;
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';


implementation

{$R *.dfm}


// =============================================================================
        function blokknyomtatas(_para: integer): integer; stdcall;
// =============================================================================

begin
  Blokknyom  := TBlokknyom.create(Nil);
  _nyomtipus := _Para;
  result     := Blokknyom.showmodal;

  Blokknyom.Free;
end;


// =============================================================================
               procedure TBLOKKNYOM.FormActivate(Sender: TObject);
// =============================================================================

begin
   _copyBlokk   := False;  // HA EZ MÁSOLAT
   _oroszugyfel := False;

   // Ha a paraméter nagyobb 10-nél, akkor a bizonylat másolat:

   if _nyomtipus>10 then _copyblokk := true;

   _width := Screen.Monitors[0].Width;
   _height:= Screen.Monitors[0].Height;

   Top     := Trunc((_height-90)/2);
   Left    := Trunc((_width-280)/2);
   Visible := True;
   Repaint;

   // Adatok nullázása:

   Nullazo;

   // --------------------------------------------------------------------------
   // Beolvassa a pénztár nevét, cimet, adoszámát, pénztáros nevét
   // printer tipusát, kft nevét:

   GetPenztarData;

   // Beolvassa: datum,ido,tipus,netto,fizetendo, kezelesidij,bizonylatszam
   // konverzio,storno,tetel,elojel,penztarkod,stornobizonylat,szallitonev,
   // plombaszam,megjegyzes,reprintindok,stornoindok,tarspenztarnev,
   // fizetoeszkoz,recnums,zcounts,kerekites,forras,kedvarfolyam,

   GetVTempBasic;
   if (_tipus='V') or (_tipus='E') then GetPartnerPara;
   _vanCimlet := False;

   if _storno=3 then
     begin
       logirorutin(pchar('Stornóblokk nyomtatás'));
       StornoBlokknyomtatas;
       KilepoTimer.Enabled := True;
       exit;
     end;

   if (_tipus='F') OR (_tipus='U') then
       if FileExists(_cimDataPath) then _vancimlet := Cimletbedolgozas;

   if _tipus='V' then VetelSzamlaNyomtatas;
   if _tipus='E' then EladasSzamlaNyomtatas;
   if _tipus='F' then AtadBlokkNyomtatas;
   if _tipus='U' then AtveszBlokkNyomtatas;

   Kilepotimer.enabled := true;
end;

// =============================================================================
                       procedure TBlokkNyom.Nullazo;
// =============================================================================


begin
  _ugyfeltipus    := '';
  _securlevel     := 0;
  _kulfoldi       := 0;

  // Természetes személy adatai:

  _ugyfelszam     := 0;
  _ugyfelnev      := '';
  _szulhely       := '';
  _szulido        := '';
  _lakcim         := '';
  _okmanytip      := '';
  _azonosito      := '';
  _tarthely       := '';
  _kartyaszam     := '';
  _ukozszerep     := 0;

  // Jogi személy adatai:

  _joginev        := '';
  _jogihely       := '';
  _okiratszam     := '';
  _cAdoszam       := '';
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//$$$$$$$$$$$$$$$$$$$$$$  ADATOK BEOLVASASA $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TBlokknyom.GetVtempBasic;
// =============================================================================

begin
  Valutadbase.Connected := true;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  with Valutaquery do
    begin

      _datum          := trim(FieldByname('DATUM').AsString);
      _ido            := trim(FieldByName('IDO').AsString);
      _tipus          := trim(FieldByName('TIPUS').AsString);
      _kulfoldi       := FieldByName('KULFOLDI').asInteger;

      _ugyfeltipus    := FieldByNAme('UGYFELTIPUS').asString;
      _ugyfelszam     := FieldByNAme('UGYFELSZAM').asInteger;
      _securlevel     := FieldByNAme('SECURLEVEL').asInteger;
      _netto          := FieldByName('NETTO').asInteger;
      _fizetendo      := FieldByName('FIZETENDO').asInteger;
      _kezelesidij    := FieldByNAme('KEZELESIDIJ').asInteger;
      _bizonylatszam  := FieldByNAme('BIZONYLATSZAM').asstring;
      _konverzio      := FieldByname('KONVERZIO').asInteger;
      _storno         := FieldByName('STORNO').asInteger;
      _tetel          := FieldByName('TETEL').asInteger;
      _elojel         := FieldByNAme('ELOJEL').asString;
      _penztarkod     := FieldByName('PENZTARKOD').asString;
      _stornobizonylat:= trim(FieldByName('STORNOBIZONYLAT').asString);
      _szallitonev    := trim(FieldByName('SZALLITONEV').asstring);
      _plombaszam     := TRIM(FieldByName('PLOMBASZAM').asstring);
      _megjegyzes     := trim(FieldByNAme('MEGJEGYZES').asString);
      _reprintindok   := trim(FieldByName('COPYINDOK').asString);
      _stornoindok    := trim(FieldByName('STORNOINDOK').asstring);
      _tarspenztarnev := trim(FieldByName('TARSPENZTARNEV').asString);
      _fizetoeszkoz   := FieldByName('FIZETOESZKOZ').asInteger;
      _recnums        := FieldbyName('RECNUMS').asstring;
      _zcounts        := FieldByName('ZCOUNTS').asstring;
      _kerekites      := FieldByNAme('KEREKITES').asInteger;
      _forras         := trim(FieldByNAme('FORRAS').AsString);
      _engedelyezo    := trim(FieldByname('ENGEDELYEZO').asstring);
      _skaf           := FieldByName('KEDVEZMENYESARFOLYAM').asInteger;
      _megbizoszam    := FieldByNAme('MEGBIZOSZAM').asInteger;
      _kozszereplo    := FieldByName('KOZSZEREPLO').asInteger;
      _kartyaszam     := trim(FieldByName('KARTYASZAM').AsString);
      next;
    end;

  while not ValutaQuery.Eof do
    begin
      _kaf := Valutaquery.FieldbyNAme('KEDVEZMENYESARFOLYAM').asInteger;
      _skaf := _skaf + _kaf;
      ValutaQuery.Next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;


// =============================================================================
                     procedure TBlokkNyom.GetPenztarData;
// =============================================================================

begin
  _pcs := 'SELECT * FROM PENZTAR';
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      _aktPenztarkod  := trim(FieldByNAme('PENZTARKOD').asstring);
      _aktPenztarNev  := trim(FieldByName('PENZTARNEV').asString);
      _aktpenztarCim  := trim(FieldByName('PENZTARCIM').asstring);
      _aktTelefon     := trim(FieldByName('TELEFONSZAM').AsString);
      Close;
    end;

  val(_aktpenztarkod,_aktpenztarszam,_code);

  // ---------------------------------------------------------------

  _pcs := 'SELECT * FROM HARDWARE';
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      _printer := FieldByNAme('PRINTER').asInteger;
      _aktprosnev := trim(FieldByNAme('PENZTAROSNEV').AsString);
      Close;
    end;
  ValutaDbase.close;

  If _aktpenztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
      _aktadoszam := '32313332-2-02';
    end else
    begin
      _cegnev := 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT';
      _aktadoszam:= '14040535-2-02';
    end;
end;

// =============================================================================
                procedure TBlokknyom.GetPartnerPara;
// =============================================================================

begin
  if (_ugyfeltipus='K') or (_ugyfeltipus='N') then
    begin
      NaturadatokBeolvasasa;
      exit;
    end;

  if _ugyfeltipus='J' THEN
    begin
      JogiAdatokBeolvasasa;
      exit;
    end;

end;

// =============================================================================
                procedure TBlokknyom.NaturadatokBeolvasasa;
// =============================================================================

//             ParameteRs:  UGYFELSZAM - UGYFELTIPUS

begin
  Valutadbase.connected := true;

  _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _ugyfelnev  := trim(FieldByNAme('NEV').AsString);
      _szulhely   := trim(FieldByName('SZULETESIHELY').AsString);
      _szulido    := trim(FieldByNAme('SZULETESIIDO').AsString);
      _anyjaneve  := trim(FieldByNAme('ANYJANEVE').asString);
    end;

  if _ugyfeltipus='N' then
    begin
      _okmanytip  := trim(ValutaQuery.FieldByNAme('OKMANYTIPUS').AsString);
      _azonosito  := trim(ValutaQuery.FieldByNAme('AZONOSITO').AsString);
      _tarthely   := trim(ValutaQuery.FieldByName('TARTOZKODASIHELY').AsString);
      _irszam     := trim(Valutaquery.FieldByNAme('IRSZAM').AsString);
      _varos      := trim(ValutaQuery.FieldByName('VAROS').AsString);
      _utca       := trim(ValutaQuery.FieldByName('UTCA').asstring);
      _ugyfelcim  := leftstr(_irszam+' '+_varos+' '+_utca,40);
      _iso        := trim(ValutaQuery.FieldByNAme('ISO').AsString);
    end;

  if _megbizoszam>0 then
    begin
      _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_megbizoszam);
      with valutaQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;
      if _recno>0 then _megbizonev := trim(Valutaquery.fieldByNAme('NEV').AsString)
      else _megbizoszam := 0;
    end;

  ValutaQuery.close;
  Valutadbase.close;
end;

// =============================================================================
                 procedure TBlokknyom.JogiAdatokBeolvasasa;
// =============================================================================

begin
  _tuldarab := 0;
  _mbszama  := 0;
  _mbneve   := '';

  _pcs := 'SELECT * FROM JOGISZEMELY WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _JOGInev    := trim(FieldByNAme('JOGISZEMELYNEV').asstring);
      _jogihely   := trim(FieldByNAme('TELEPHELYCIM').AsString);
      _okiratszam := trim(FieldByName('OKIRATSZAM').assTRING);
      _cAdoszam   := trim(FieldByNAme('ADOSZAM').AsString);
      _mbszama    := Fieldbyname('MEGBIZOTTSZAMA').asInteger;
      close;
    end;

  if _mbszama<>0 then
    begin
      _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_mbszama);
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          _mbneve := trim(ValutaQuery.FieldByNAme('NEV').asString);
          _mbcime := trim(ValutaQuery.FieldByNAme('LAKCIM').asString);
          _irszam := trim(Valutaquery.FieldByNAme('IRSZAM').AsString);
          _varos  := trim(Valutaquery.FieldByName('VAROS').AsString);
          _utca   := trim(ValutaQuery.fieldByNAme('UTCA').AsString);
          _mbkozszerep := ValutaQuery.FieldByNAme('KOZSZEREPLO').asInteger;
        end;
        if _mbcime= '' then _mbcime := _irszam+' '+_varos+' '+_utca;
    end;

  Valutaquery.close;

  _pcs := 'SELECT * FROM UJTULAJOK WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  _tuldarab := 0;
  if _recno>0 then
    begin
      while not valutaquery.eof do
        begin
          inc(_tuldarab);
          _tnev[_tuldarab] := trim(Valutaquery.fieldByNAme('TULAJNEV').asString);
          _tcim[_tuldarab] := trim(ValutaQuery.FieldByNAme('LAKCIM').asString);
          _tszulhely := trim(Valutaquery.FieldByNAme('SZULHELY').AsString);
          _tszulido := trim(ValutaQuery.FieldByNAme('SZULIDO').AsString);
          _tszuldata[_tuldarab] := _tszulhely+' '+_tszulido;
          _tallamp[_tuldarab] := trim(ValutaQuery.FieldByNAme('ALLAMPOLGAR').asString);
          _tTarthely[_tuldarab] := trim(ValutaQuery.fieldbyname('TARTHELY').asString);
          _tJelleg[_tuldarab] := trim(ValutaQuery.FieldByNAme('ERDJELLEG').AsString);
          _tMertek[_tuldarab] := trim(ValutaQuery.FieldByNAme('ERDMERTEK').ASSTRING);
          _tKozszerep[_tuldarab] := ValutaQuery.fieldByNAme('TULKOZSZEREP').asInteger;
          ValutaQuery.next;
        end;
      ValutaQuery.close;
    end;
  Valutadbase.close;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$ CIMLET PROCEDURÁK  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                function TBlokkNyom.CimletBedolgozas: boolean;
// =============================================================================

var _vnev : string;
    _cc,_z,_p,_vcdb: byte;
    _zz   : word;

begin
  logirorutin(pchar('A cimletbedolgozás indul'));

  Result := false;
  Assignfile(_binolvas,_cimDataPath);
  Reset(_binolvas);
  Blockread(_binolvas,_bytetomb,1);

  _yValDarab := _byteTomb[1];

  _cc := 1;
  while _cc<=_yValdarab do
    begin
      Blockread(_binolvas,_bytetomb,3);

      _vnev := chr(255-_bytetomb[1])+chr(255-_bytetomb[2])+chr(255-_bytetomb[3]);
      _yNev[_cc] := _vNev;

      Blockread(_binolvas,_bytetomb,1);
      _vcdb := _bytetomb[1];
      _yCdb[_cc] := _vcdb;

      _p := 1;
      while _p<=_vcdb do
        begin
          _yC[_cc,_p] := getword;
          _yB[_cc,_p] := getword;
          inc(_p);
        end;
      _z := getbyte;
      if _z<255 then
        begin
          CloseFile(_binolvas);
          exit;
        end;
      inc(_cc);
    end;
  _z := getbyte;
  _zz := _z + Getbyte;
  CloseFile(_binolvas);
  if _zz<>510 then exit;
  result := true;
end;

// =============================================================================
                      function TBlokknyom.Getword: word;
// =============================================================================

begin

  Blockread(_binolvas,_bytetomb,2);
  result := _bytetomb[1]+trunc(256*_bytetomb[2]);
end;


// =============================================================================
                    function TBlokknyom.GetByte: byte;
// =============================================================================

begin
  Blockread(_binolvas,_bytetomb,1);
  result := _bytetomb[1];
end;


// =============================================================================
                   procedure TBlokkNyom.CimletNyomtatas;
// =============================================================================


var _sor,_vNev: string;
    _p,_cc,_vcdb,_sdb: byte;
    _cim,_bjy: word;

begin
  Cimletbedolgozas;
  WriteLn(_LFile,'        Cimletezes - denominations:'+_sorveg);
  _cc := 1;
  while _cc<=_yValDarab do
    begin
      _vNev:= _yNev[_cc];
      write(_LFile,_vNev + ': ');
      _sor := '';
      _vcdb := _yCdb[_cc];
      _p := 1;
      _sdb := 0;
      while _p<=_vcdb do
        begin
          _cim := _yC[_cc,_p];
          _bJy := _yB[_cc,_p];
          _sor := _sor + inttostr(_cim)+'='+inttostr(_bjy)+',';
          inc(_sdb);
          if _sdb=4 then
            begin
              writeLn(_LFile,_sor);
              _sdb := 0;
              _sor := '';
            end;
          inc(_p);
        end;
      if _sor<>'' then writeln(_LFile,'    '+_sor);
      inc(_cc);
    end;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$ BLOKKNYOMTATAS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                    procedure TBLOKKNYOM.VetelSzamlaNyomtatas;
// =============================================================================

begin
  logirorutin(pchar('Vétel-számla nyomtatás indul'));

  _vancimlet := fileexists('c:\valuta\aktcim.dat');

  if _skaf>0 then Arfmodnyomtatas else
    begin
      logirorutin(pchar('Modositott árfolyam nyomtatása'));
      AssignFile(_LFile,_nyomtatvanyPath);
      Rewrite(_LFile);
    end;

  writeLn(_LFile,_wideOn + '       NYUGTA' + _wideOff);

  SorEmeles;
  Kozepreir(_cegnev);
  Kozepreir(_aktpenztarnev);
  Kozepreir(_aktpenztarcim);

  if _aktTelefon<>'' then KozepreIr('Telefon: ' + _aktTelefon);
  KozepreIr('Adoszam: ' + _aktAdoszam);

  if _copyBlokk then
    begin
      WriteLn(_Lfile,_wideon+'     MASOLAT' + _wideOff);
      if _reprintIndok<>'' then
               KozepreIr('(Indoka: '+ trim(_reprintIndok)+')');
      _reprintIndok := '';
    end;

  if _konverzio=0 then _tranznev := 'Valuta vetel'
  else _tranznev := 'Konverzios valuta vetel';

  Kozepreir(_tranznev);
  KozepreIr('EXCHANGE (PURCHASE)');

  VonalHuzo;

  writeLn(_LFile,'Sorszam   (INVOICE NR)    :   '+_bizonylatSzam);
  writeLN(_LFile,'Datum     (DATE)          :   ' +  _datum);
  writeLn(_Lfile,'Ido       (TIME)          :     ' + _ido);

  if _recnums<>'' then
      writeLn(_LFile,'      (Nyugtaszam: '+_zcounts+'/'+_recnums+')');

  vonalhuzo;

  if _storno=2 then KozepreIr('S T O R N O Z O T T   B L O K K');
  if _stornoIndok>'' then Kozepreir('(indoka: '+ _stornoindok + ')');

  writeLn(_LFile,'Adómentes               Szj - 67.13.10.0');
  writeLn(_LFile,'M.A.A.    a szolgaltatas nyujtasa a 2007');
  writeLn(_LFile,'evi CXVII tv. 86 § e) alapjan mentes az');
  writeLn(_LFile,'             ado alol');

  VonalHuzo;

  writeLn(_LFile,'V.nem   Arfolyam    B.jegy       Forint');
  writeLn(_LFile,'CURR.    RATE        CASH        VALUE');
  VonalHuzo;


  //  A SZÁMLA TÉTELEINEK KINYOMTATÁSA:

  Valutadbase.Connected := true;

  _pcs := 'SELECT * FROM VTEMP' + _sorveg;
  _pcs := _pcs + 'WHERE (BANKJEGY>0)';

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.Eof do
    begin
      _aktDnem := ValutaQuery.FieldByName('VALUTANEM').asString;
      if _aktDnem='' then
        begin
          ValutaQuery.Next;
          Continue;
        end;

     if (_konverzio=1) and (_aktdnem='HUF') then
       begin
         Valutaquery.Next;
         Continue;
       end;

      with ValutaQuery do
        begin
          _aktArfolyam := FieldByName('ARFOLYAM').asInteger;
          _aktBankjegy := FieldByNAme('BANKJEGY').asInteger;
          _aktertek    := FieldByNAme('FORINTERTEK').asInteger;
        end;

      write(_LFile,_aktDnem + '     ');
      write(_LFile,elokieg(forintForm(_aktArfolyam),6)+'   ');
      write(_LFile,eloKieg(forintForm(_aktBankjegy),11)+' ');
      writeLN(_LFile,eloKieg(forintForm(_aktertek),11));

      ValutaQuery.Next;
    end;

  ValutaQuery.close;
  ValutaDbase.close;
  VonalHuzo;

  //  A SZÁMLA  LÁBRÉSZÉNEK KINYOMTAT5ÁSA:

   write(_LFile,'Kerekites  (ROUNDING)      :          ');

  if _kerekites>-1 then write(_LFile,' ');

  writeLn(_LFile,inttostr(_kerekites));

  Write(_LFile,'Netto  Ft  (SUM TOTAL)     : ');
  writeLn(_LFile,elokieg(forintform(_NETTO),11));

  write(_LFile,'Kez. kltsg (HANDLING FEE)  : ');
  writeln(_LFile,elokieg(forintform(_kezelesidij),11));

  write(_LFile,'Kifizetve:(PAID): ');
  WriteLN(_LFile,_wideon+elokieg(forintForm(_fizetendo),11)+_wideoff);

  // ===========================================================================

  Ugyfelnyomtatas;

  // A FIZETÖESZKÖZ TIPUSÁNAK KINYOMTATÁSA:

  kozepreir('Az ugyletet keszpenzben teljesitjuk');
  
  // A BEL- VAGY KÜLFÖLDI STÁTUSZ KIONYOMTATÁSA:

  DevizsStatuszNyomtatas;

  VonalHuzo;

  // CIMLETEK KINYOMTATÁSA:

  if _vanCimlet then
    begin
      CimletNyomtatas;
      Sysutils.DeleteFile(_cimDataPath);
    end;

  ReklamNyomtatas;

  if _securlevel=1 then Jogcimnyilatkozat;
  StartNyomtatas;

end;

// =============================================================================
                    procedure TBLOKKNYOM.EladasSzamlaNyomtatas;
// =============================================================================

var _fiz: integer;

begin
  logirorutin(pchar('Eladás számla nyomtatás indul'));
  _vancimlet := fileexists('c:\valuta\aktcim.dat');

  if _skaf>0 then Arfmodnyomtatas else
    begin
      logirorutin(pchar('Arfolyam modositás nyomtatása'));
      AssignFile(_LFile,_nyomtatvanyPath);
      Rewrite(_LFile);
    end;

  writeLn(_LFile,_wideOn + '       NYUGTA' + _wideOff);

  SorEmeles;
  Kozepreir(_cegnev);
  Kozepreir(_aktpenztarnev);
  Kozepreir(_aktpenztarcim);

  IF _aktTelefon<>'' then KozepreIr('Telefon: ' + _aktTelefon);
  KozepreIr('Adoszam: ' + _aktAdoszam);

  if _copyBlokk then
    begin
      WriteLn(_Lfile,_wideon+'     MASOLAT' + _wideOff);
      if _reprintIndok<>'' then
               KozepreIr('(Indoka: '+ trim(_reprintIndok)+')');
      _reprintIndok := '';
    end;

  if _konverzio=0 then _tranznev := 'Valuta eladás'
  else _tranznev := 'Konverzios valuta eladas';

  Kozepreir(_tranznev);
  KozepreIr('EXCHANGE (SELLING)');

  VonalHuzo;

  writeLn(_LFile,'Sorszám   (INVOICE NR)    :   ' + _bizonylatSzam);
  writeLN(_LFile,'Dátum     (DATE)          :   ' +  _datum);
  writeLn(_Lfile,'Idö       (TIME)          :     ' + _ido);
  writeLn(_LFile,'      (Nyugtaszam: '+_zcounts+'/'+_recnums+')');

  vonalhuzo;

  if _storno=2 then KozepreIr('S T O R N O Z O T T   B L O K K');

  if _storno=3 then
    begin
      KozepreIr('S T O R N O   B L O K K');
      if _stornoIndok<>'' then KozepreIr('Storno indoka: '+trim(_stornoIndok)+')');
    end;

  _stornoIndok := '';

  writeLn(_LFile,'Adomentes               Szj - 67.13.10.0');
  writeLn(_LFile,'M.A.A.    a szolgaltatas nyujtasa a 2007');
  writeLn(_LFile,'evi CXVII tv. 86 § e) alapjan mentes az');
  writeLn(_LFile,'             ado alol');


  VonalHuzo;

  writeLn(_LFile,'V.nem   Arfolyam    B.jegy       Forint');
  writeLn(_LFile,'CURR.    RATE        CASH        VALUE');
  VonalHuzo;

  Valutadbase.Connected := true;

  _pcs := 'SELECT * FROM VTEMP' + _sorveg;
  _pcs := _pcs + 'WHERE (BANKJEGY>0)';

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.Eof do
    begin
      _aktDnem := ValutaQuery.FieldByName('VALUTANEM').asString;
      if _aktDnem='' then
        begin
          ValutaQuery.Next;
          Continue;
        end;

     if (_konverzio=1) and (_aktdnem='HUF') then
       begin
         Valutaquery.Next;
         Continue;
       end;

     _currency    := _aktdnem;
     _oroszugyfel := EzOroszugyfel;
     
     with ValutaQuery do
        begin
          _aktArfolyam := FieldByName('ARFOLYAM').asInteger;
          _aktBankjegy := FieldByNAme('BANKJEGY').asInteger;
          _aktertek    := FieldByNAme('FORINTERTEK').asInteger;
        end;

      write(_LFile,_aktDnem + '     ');
      write(_LFile,elokieg(forintForm(_aktArfolyam),6)+'   ');
      write(_LFile,eloKieg(forintForm(_aktBankjegy),11)+' ');
      writeLN(_LFile,eloKieg(forintForm(_aktertek),11));

      ValutaQuery.Next;
    end;

  ValutaQuery.close;
  ValutaDbase.close;

  _statusz := 'belfoldi';
  if _kulfoldi=1 then _statusz := 'kulfoldi';

  // ---------------------------------------------------------------------------

  VonalHuzo;

  _fiz := _fizetendo;
 
  write(_LFile,'Kerekites  (ROUNDING)      :          ');
  if _kerekites>-1 then write(_LFile,' ');
  writeLn(_LFile,inttostr(_kerekites));
  Write(_LFile,'Netto  Ft  (SUM TOTAL)     : ');
  writeLn(_LFile,elokieg(forintform(_NETTO),11));
  write(_LFile,'Kez. kltsg (HANDLING FEE)  : ');
  writeln(_LFile,elokieg(forintform(_kezelesidij),11));

  write(_LFile,'Kifizetve:(PAID): ');
  WriteLN(_LFile,_wideon+elokieg(forintForm(_fiz),11)+_wideoff);

  Ugyfelnyomtatas;

  if _fizetoeszkoz=1 then kozepreir('Az ugyletet keszpenzben teljesitjuk');
  if _fizetoeszkoz=2 then
    begin
      Kozepreir('Az ugylet bankkartyaval tortent');
      if (_fiz<300000) and (_ugyfeltipus='J') then
        begin
          writeLN(_LFile,'------------- ugyfel adatai ------------');
          writeLN(_lfILE,'   Ugyfel: '+_joginev);
          writeLN(_lfILE,'Telephely: '+_jogihely);
          writeLN(_lfILE,'  Adoszam: '+_adoszam);
        end;
    end;

  DevizsStatuszNyomtatas;

  VonalHuzo;
  if _vanCimlet then
    begin
      CimletNyomtatas;
      Sysutils.DeleteFile(_cimDataPath);
    end;

  ReklamNyomtatas;

  if _oroszugyfel then
    begin
      OroszNyilatkozat;
      StartNyomtatas;
      exit;
    end;

  if _securlevel=1 then Jogcimnyilatkozat;
  StartNyomtatas;

end;

// =============================================================================
               procedure TBLOKKNYOM.AtadBlokkNyomtatas;
// =============================================================================

begin
  logirorutin(pchar('Átadó - nyugta nyomtatás indul'));

  BlokkFocimiro;

  if _copyBlokk then
     begin
       WriteLn(_Lfile,_wideon+'M  A  S  O  L  A  T' + _wideOff);
       if _reprintIndok<>'' then
               KozepreIr('(Indoka: '+ trim(_reprintIndok)+')');
       _reprintIndok := '';
    end;


  writeLn(_LFile,_wideon + '  Penztari atadas' + _wideoff + _sorveg);
  writeLn(_LFile,'Atvevo: ' +  _penztarkod + ' - ' + _tarsPenztarNev);
  BlokkFejlecIro;

  BlokkTetelIro;

  writeLn(_LFile,'SZALLITO NEVE: ' + _szallitoNev);
  writeLn(_LFile,'PLOMBA SZAMA : ' + _plombaSzam);

  if _megjegyzes<>'' then writeLN(_LFile,'Megjegyzes: '+_megjegyzes);

   // 123456789012345678901234567890123456789
  // Büntetö felelösségem tudatában kijelen-
  // tem, hogy a fentiekben felsorolt pénz-
  // készletet a szállitóknak átadtam, azt
  //         tételesen átszámoltam.

  writeLn(_LFIle,'Büntetö felelösségem tudatában kijelen-');
  writeLn(_LFIle,'tem,  hogy a fentiekben felsorolt pénz-');
  writeLn(_LFIle,'készletet a szállitóknak átadtam,  azt');
  writeLn(_LFIle,'        tételesen átszámoltam.');

  writeLN(_LFile,_sorveg);
  writeLn(_LFile,dupestring('.',18)+'     '+ dupestring('.',18));
  writeLn(_Lfile,'       atado'+dupestring(' ',15) + 'atvevo');
  writeLn(_Lfile,_Lf5);

  StartNyomtatas;

end;

// =============================================================================
             procedure TBLOKKNYOM.AtveszBlokkNyomtatas;
// =============================================================================

begin
  logirorutin(pchar('Átvétel-blokk nyomtatása indul'));

  BlokkFocimiro;

  if _copyBlokk then
    begin
      WriteLn(_Lfile,_wideon+'M  A  S  O  L  A  T' + _wideOff);
      if _reprintIndok<>'' then
               KozepreIr('(Indoka: '+ trim(_reprintIndok)+')');
      _reprintIndok := '';
    end;

  writeLn(_LFile,_wideon+'  Penztari atvetel' + _wideoff + _sorveg);
  writeLn(_LFile,'Atado: '+ _PenztarKod+ ' - ' +_tarsPenztarNev);

  BlokkFejlecIro;
  BlokkTetelIro;

  writeLn(_LFile,'SZALLITO NEVE: ' + _szallitoNev);
  writeLn(_LFile,'PLOMBA SZAMA : ' + _plombaSzam);
  if _megjegyzes<>'' then writeLN(_LFile,'Megjegyzes: '+_megjegyzes);
  writeLN(_LFile,_sorveg);

  // 123456789012345678901234567890123456789
  // Büntetö felelösségem tudatában kijelen-
  // tem, hogy a fentiekben felsorolt pénz-
  // készletet a szállitóktól átvettem, azt
  //         tételesen átszámoltam.

  writeLn(_LFIle,'Büntetö felelösségem tudatában kijelen-');
  writeLn(_LFIle,'tem,  hogy a fentiekben felsorolt pénz-');
  writeLn(_LFIle,'készletet a szállitóktól átvettem,  azt');
  writeLn(_LFIle,'        tételesen átszámoltam.');


  writeLN(_LFile,_sorveg);
  writeLn(_LFile,dupeString('.',18)+'     '+ dupeString('.',18));
  writeLn(_Lfile,'       atado'+dupestring(' ',15) + 'atvevo');
  writeLn(_Lfile,_LF5);

  StartNyomtatas;

end;

// =============================================================================
               procedure TBlokknyom.StornoBlokknyomtatas;
// =============================================================================

begin

  if _tipus='V' then _tranztip := 'valuta vetel';
  if _tipus='E' then _tranztip := 'valuta eladas';
  if _tipus='F' then _tranztip := 'deviza atadas';
  if _tipus='U' then _tranztip := 'deviza atvetel';

  Sysutils.DeleteFile(_nyomtatvanyPath);

  logirorutin(pchar('Stornoblokk nyomtatás indul'));

  AssignFile(_LFile,_nyomtatvanyPath);
  Rewrite(_LFile);

  writeLN(_LFile,_wideon+'STORNO BIZONYLAT'+_wideOff);
  writeLn(_Lfile,' ');

  Kozepreir(_cegnev);
  Kozepreir(_aktpenztarkod + ' ' + _aktpenztarnev);
  KozepreIr('Telefon: ' + _aktTelefon);
  Kozepreir('Adoszam: ' + _aktadoszam);
  writelN(_Lfile,dupestring('-',40));

  writeLn(_LFile,'       Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'               Datum: ' + _datum);
  writeLn(_Lfile,'                 Ido: ' + _ido);
  writelN(_Lfile,dupestring('-',40));

  writeLN(_LFile,'       A stornozott bizonylat adatai:');
  writeLn(_LFile,'       ------------------------------');

  Kozepreir('Eredeti bizonylatszam: '+_stornobizonylat);
  Kozepreir('Tranzakcio tipusa: '+ _tranztip);
  Kozepreir('Bizonylat forinterteke: ' + trim(forintForm(_fizetendo)));
  Kozepreir('Stornozas indoka: ' + _stornoIndok);
  Kozepreir('Stornozast vegezte:');
  Kozepreir(_aktprosnev);
  writeln(_lfile,dupestring('-',51));
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  CloseFile(_Lfile);

  TextKiiro;
  Modalresult := 1;

end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$  RÉSZADAT NYOMTATÁSOK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                           procedure TBLOKKNYOM.ArfModNyomtatas;
// =============================================================================

var _arfolyReal: integer;

begin
  Sysutils.DeleteFile(_nyomtatvanyPath);

  logirorutin(pchar('Arfolyam módositás nyomtatás indul'));
  AssignFile(_LFile,_nyomtatvanyPath);
  Rewrite(_LFile);

  WriteLn(_LFile,_datum+' '+_ido);
  writeLN(_Lfile,_wideon+'Egyedi arfolyamok'+_wideOff);
  writeLn(_Lfile,dupeString('-',40));
  writeLn(_Lfile,'Valuta      Lista            Egyedi');
  writeLn(_LFile,'            arfolyam        arfolyam');
  writeLN(_Lfile,dupeString('-',40));

  // ---------------------------------------------------------------------------

  ValutaDbase.Connected := true;

  _pcs := 'SELECT * FROM VTEMP' + _sorveg;
  _pcs := _pcs + 'WHERE KEDVEZMENYESARFOLYAM>0';

  with ValutaQuery do
    begin
      CLose;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.Eof do
    begin
      _arfolyReal := ValutaQuery.FieldByName('EREDETIARFOLYAM').asInteger;
      _arfolyam   := ValutaQuery.FieldByNAme('KEDVEZMENYESARFOLYAM').asInteger;
      if _arfolyReal<>_arfolyam then
        begin
          _aktDnem := ValutaQuery.FieldByName('VALUTANEM').asString;
          write(_LFile,_aktdnem+'         ');
          write(_LFile,elokieg(forintform(_arfolyreal),6) + '           ');
          writeLn(_Lfile,elokieg(forintform(_arfolyam),6));
        end;
      ValutaQuery.Next;
    end;

  WriteLn(_Lfile,_sorveg+_sorveg);

  ValutaQuery.CLose;
  ValutaDbase.close;
end;

// =============================================================================
                       procedure TBlokknyom.ReklamNyomtatas;
// =============================================================================

begin

  writeLn(_LFile,_wideOn+'Raiffeisen Bank Zrt.'+_wideoff);
  Kozepreir('KIEMELT KOZVETITOJE');
  Soremeles;

  IF _aktpenztarszam>150 then exit;

  writeLn(_Lfile,_wideOn+'  EXCLUSIVE CHANGE');
  writeLn(_LFile,_wideOn+'     KEDVEZOBB,');
  writeLn(_LFile,_wideOn+'     GYORSABB,');
  writeLn(_Lfile,_wideOn+'  BIZTONSAGOSABB !'+_wideoff);
  writeLn(_LFile,' ');
end;

// =============================================================================
                 procedure TBlokknyom.Ugyfelnyomtatas;
// =============================================================================

var _tth: string;

begin
  writeLN(_LFile,'------------- ugyfel adatai ------------');

  // AZ EGySZERÜSITETT UGYFELBEKERES ADATAI:

  if (_ugyfeltipus='') OR (_UGYFELSZAM=0) then exit;

  if (_ugyfeltipus='K')  then
    begin
      writeLn(_LFile,'neve: ' + _ugyfelnev);
      if _anyjaneve<>'' then
        begin
          writeLn(_LFile,'anyja neve : '+ _anyjaneve);
          if _kulfoldi=1 then writeln(_Lfile,'(anyja neve rogzitese bemondasra tortent)');
        end;
      writeLn(_Lfile,'szul-i hely: '+ _szulhely);
      writeLn(_LFile,'szul-i ido : '+ _szulido);

      if _megbizoszam>0 then sajatnyil;
      exit;
    end;

  if _ugyfeltipus='J' then
    begin
      writeLn(_LFile,'Jogi szemely neve:');
      KozepreIr(trim(_joginev));
      writeLn(_LFile,'Jogi szemely szekhelye:');
      KozepreIr(trim(_jogihely));
      if _okiratSzam<>'' then writeln(_LFile,'Okiratszam: ' + _okiratSzam);
      _cadoszam := 'Adoszam: '+_cAdoszam;
      writeLn(_Lfile,_cAdoszam);
      if _mbneve<>'' then
        begin
          writeLn(_Lfile,'Megbizott neve:');
          Kozepreir(_mbneve);
        end;
      if _mbcime<>'' then
        begin
          if length(_mbcime)>40 then _mbcime := leftstr(_mbcime,40);
          writeLn(_LFile,'Megbizott cime:');
          Kozepreir(_mbcime);
        end;

      writeLn(_Lfile,'Megbizott statusza:');
      KozszerepNyilatkozat(_mbkozszerep);

      if _tuldarab>0 then
        begin
          writeLn(_LFile,'---------------------------------------');
          writeLn(_lFile,'Tényleges tulajdonosok adatai:');
          _qq := 1;
          while _qq<=_tuldarab do
            begin
              writeLn(_Lfile,' ');
              writeLn(_LFile,inttostr(_qq)+'. tulajdonos:');
              writeLn(_lFile,_tnev[_qq]);
              writeLn(_lFile,_tcim[_qq]);
              writeLn(_lFile,_tszuldata[_qq]);
              writeLn(_lFile,_tallamp[_qq]);
              _tth := _ttarthely[_qq];
              if _tth<>'' then writeLn(_lFile,_ttarthely[_qq]);
              writeLn(_lFile,_tjelleg[_qq]);
              writeLn(_lFile,_tmertek[_qq]);
              _tk := _tkozszerep[_qq];
              if _tk=0 then writeLn(_Lfile,'Nem közszereplö')
              else writeLn(_LFile,'A tulaj közszereplö');
              inc(_qq);
            end;
        end;
    end;

  if _ugyfeltipus='N' then
    begin
      writeln(_LFile,'Nev (NAME):');
      Kozepreir(_ugyfelnev);

      if _anyjaneve<>'' then
        begin
          writeLn(_LFile,'anyja neve : '+ _anyjaneve);
          if _kulfoldi=1 then writeln(_Lfile,'(anyja neve rogzitese bemondasra tortent)');
        end;
      writeLn(_Lfile,'szul-i hely: '+ _szulhely);
      writeLn(_LFile,'szul-i ido : '+ _szulido);
      writelN(_LFile,'Lakcim:(ADDRESS):');
      KozepreIr(trim(_ugyfelCim));

      writeLn(_Lfile,'DOC TYPE: '+ _okmanyTip);
      writeLn(_LFile,'     NR.: '+ _azonosito);
      if _kozszereplo>0 then Kozepreir('Az ugyfel kiemelt kozszereplo')
      else Kozepreir('Az ugyfel nem kozszereplo');

      if _kulfoldi=1 then
        begin
          writeLn(_LFile,'Residence:');
          KozepreIr(_tarthely);
        end;
    end;
end;


// =============================================================================
                  procedure TBLOKKNYOM.Jogcimnyilatkozat;
// =============================================================================

begin
   WriteLn(_Lfile,_sorveg);
   WriteLn(_LFile,_wideon+'JOGCIM NYILATKOZAT'+_wideoff);
   WriteLn(_Lfile,_sorveg + 'Buntetojogi felelossegem tudataban nyi-');
   WriteLn(_lfile,'latkozom,   hogy  a  fenti  tranzakciot');

   if _ugyfeltipus='J' then
     begin
       kozepreir(_joginev);
       kozepreir('neveben bonyolitom,');
       Kozszerepnyilatkozat(_kozszereplo);
     end;

   if _ugyfeltipus='N' then
     begin
       if _megbizoszam=0 then
         begin
           writeLn(_LFile,'termeszetes szemelyenkent, sajat magam');
           write(_LFile,'neveben bonyolitom, ');
         end else
         begin
           kozepreir(_megbizonev);
           kozepreir('megbizasabol bonyolitom, ');
         end;
       KozszerepNyilatkozat(_kozszereplo);
     end;

    {
   1234567890123456789012345678901234567890
   Tudomasom van arrol, hogy 5 (ot) munka-
   napon belul koteles vagyok bejelenteni a
   szolgaltatonal a fenti adatokban, vagy a
   sajat  adataimban  bekovetkezo esetleges
   valtozasokat,  es  e kötelezettseg elmu-
      lasztasabol eredo kar engem terhel
   }

   writeLn(_LFile,'Tudomasom van arrol,  hogy 5 (ot) munka-');
   writeLn(_Lfile,'napon belul koteles vagyok bejelenteni a');
   writeLn(_LFile,'szolgaltatonak a fenti adatokban, vagy a');
   writeLn(_Lfile,'sajat  adataimban  bekovetkezo esetleges');
   writeLn(_LFile,'valtozasokat,  es  e kötelezettseg elmu-');
   writeLn(_LFile,'   lasztasabol eredo kar engem terhel' + _sorveg);
   writeLn(_LFile,' ');

   if _forras<>'' then
       writeLn(_LFile,_sorveg+'Pénzeszközöm forrása: '+ _forras);

   writeLN(_LFile,_sorveg + _sorveg);
   writeLn(_Lfile,dupeString('.',39));
   writeLn(_Lfile,'             ugyfel alairasa');
   writeLN(_Lfile,_sorveg);

end;

procedure TBlokknyom.sajatnyil;

begin
   WriteLn(_Lfile,_sorveg + 'Buntetojogi felelossegem tudataban nyi-');
   WriteLn(_lfile,'latkozom,   hogy  a  fenti  tranzakciot');
   kozepreir(_megbizonev);
   kozepreir('megbizasabol bonyolitom');
end;

// =============================================================================
              procedure TBlokknyom.KozszerepNyilatkozat(_ksz: byte);
// =============================================================================

var _tizes,_egyes: byte;

begin
  writeLn(_lfile,' ');
  if _ksz=0 then
    begin
      Kozepreir('Nem (vagyok) kiemelt kozszereplo');
      exit;
    end;

  _tizes := trunc(_ksz/10);
  _egyes := _ksz - trunc(10*_tizes);

  writeln(_LFile,'Kiemelt kozszereplo (vagyok), mint ...');
  if _egyes>0 then
    begin
      case _tizes of
        1: writeLn(_LFile,'hazastarsa ...');
        2: writeln(_Lfile,'elettarsa ...');
        3: writeLn(_LFile,'verszerinti (mostoha,stb) gyermeke ...');
        4: writeLn(_LFile,'gyermeke hazastarsa (elettarsa) ...');
        5: writeln(_LFile,'verszerinti (mostoha, stb) szuloje ...');
        6: begin
             writeLn(_LFile,'szervezet kozos tulajdonosa, vagy');
             writeLn(_LFile,'szoros uzeéeti lacsolatnam allo ...');
           end;
        7: begin
              writeLn(_LFile,'egyszemelyes tulajdonosa jogiszemnek');
              WRITElN(_lfILE,'melyet a szemely javara hoztak letre');
           end;
       end;
    end else _egyes := _tizes;

  case _egyes of
    1: writeLn(_LFile,'allamfo,kormanyfo,miniszter,allamtitkar');
    2: writeLn(_LFile,'orszaggyulesi kepviselo,nemz-i szoszolo');
    3: writeLn(_LFile,'politikai part vezeto tisztsegviseloje');
    4: writeLn(_LFile,'alkotmanybiro, itelotabla, kuria tagja');
    5: writeLn(_LFile,'szamvevoszek,kozponti bank ig-i tagja');
    6: writeLn(_LFile,'nagykovet,fegyveres erok parancsnoka');
    7: begin
         writeLn(_LFile,'allami tulajdonu vallalat igazgatasi');
         writeLN(_LFile,'iranyito vagy felugyeleti test tagja');
       end;
    8: writeLn(_LFile,'nemzetkozi szervezet vezeosegi tagja');
  end;
end;

// =============================================================================
                procedure Tblokknyom.DevizsStatuszNyomtatas;
// =============================================================================

var _ctip,_cs: string;
    _clen: byte;

begin
  if _kartyaszam<>'' then
    begin
      _ctip := leftstr(_kartyaszam,1);
      _clen := length(_kartyaszam);
      _kartyaszam := midstr(_kartyaszam,3,_clen-2);
      if _ctip='D' then _cs:= 'Diak igazolvany'
      else _cs := 'Kartyaszam';
      Kozepreir(_cs+': ' + _kartyaszam);
    end;

  if _kulfoldi=0 then
    begin
      Kozepreir('Deviza-statusz: Belfoldi');
      exit;
    end;

  Kozepreir('Deviza-statusz: Kulfoldi');
  VonalHuzo;
end;

// =============================================================================
                  procedure TBLOKKNYOM.BlokkFocimIro;
// =============================================================================

begin
  Sysutils.DeleteFile(_nyomtatvanyPath);

  logirorutin(pchar('Blokkfocum nyomtatás indul'));

  AssignFile(_LFile,_nyomtatvanyPath);
  Rewrite(_LFile);
  write(_LFile,_inic);

  KozepreIr(_cegnev);
  Kozepreir(_aktpenztarkod+'. '+_aktpenztarnev);
  Kozepreir(_aktpenztarcim);
  Kozepreir('Adoszam: ' + _AKTADOSZAM);
  if _akttelefon<>'' then KozepreIr('Tel: '+ _aktTelefon);
end;

// =============================================================================
                       procedure TBLOKKNYOM.BlokkFejlecIro;
// =============================================================================

begin
  Vonalhuzo;

  writeLn(_LFile,'Sorszam   (INVOICE NR)    :   ' + _bizonylatSzam);
  writeLN(_LFile,'Datum     (DATE)          :   ' +  _datum);
  writeLn(_Lfile,'Ido       (TIME)          :     ' + _ido);

  vonalhuzo;

  if _storno=2 then
    begin
      writeLn(_LFile,'      S T O R N O Z O T T   B L O K K');
      if _stornoindok<>'' then KozepreIr('Storno indoka: '+trim(_stornoIndok)+')');
    end;

  writeLn(_LFile,'Adomentes               Szj - 67.13.10.0');

  VonalHuzo;
  writeLn(_LFile,'V.nem    Arf.       B.jegy       Forint');
  writeLn(_LFile,'CURR.    RATE        CASH        VALUE');
  VonalHuzo;
end;

// =============================================================================
                          procedure TBLOKKNYOM.BlokkTetelIro;
// =============================================================================

var _precarfs,_akttort: string;
    _precarf : real;

begin

  Valutadbase.Connected := true;

  _pcs := 'SELECT * FROM VTEMP' + _sorveg;
  _pcs := _pcs + 'WHERE (BANKJEGY>0)';

  if _tipus='K' then _pcs := _pcs + ' AND (ELOJEL='+chr(39)+'+'+chr(39)+')';

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.Eof do
    begin
      _aktDnem := ValutaQuery.FieldByName('VALUTANEM').asString;
      if _aktDnem='' then
        begin
          ValutaQuery.Next;
          Continue;
        end;
     if (_konverzio=1) and (_aktdnem='HUF') then
       begin
         Valutaquery.Next;
         Continue;
       end;

      with ValutaQuery do
        begin
          _aktArfolyam := FieldByName('ARFOLYAM').asInteger;
          _aktBankjegy := FieldByNAme('BANKJEGY').asInteger;
          _aktertek    := FieldByNAme('FORINTERTEK').asInteger;
          _akttort     := trim(FieldByName('TORTRESZ').asstring);
        end;

      if _akttort='' then _akttort := '0000';
      _precarfs := inttostr(_aktarfolyam)+','+ _akttort;
      _precarf := strtofloat(_precarfs);

      write(_LFile,_aktDnem + '  ');
      write(_LFile,arfolyamForm(_precarf)+' ');
      write(_LFile,eloKieg(forintForm(_aktBankjegy),11)+'  ');
      writeLN(_LFile,eloKieg(forintForm(_aktertek),11));

      ValutaQuery.Next;
    end;

  ValutaQuery.close;
  ValutaDbase.close;

  // ---------------------------------------------------------------------------

  VonalHuzo;
  write(_LFile,'Kifizetve:(PAID): ');
  WriteLN(_LFile,_wideon+elokieg(forintForm(_fizetendo),11)+_wideoff);

  VonalHuzo;
end;


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$ SEGÉD  - PROGRAMOK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                          procedure TBLOKKNYOM.VonalHuzo;
// =============================================================================

begin
  writeLn(_Lfile,dupeString('-',40));
end;

// =============================================================================
                     procedure TBlokknyom.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;


// =============================================================================
                            procedure TBlokknyom.TextKiiro;
// =============================================================================

var
  _olvas: textFile;

  _nyomtat: textFile;

  {
  _memstr : Tmemorystream;
  _strlst : TStringList;
  _q: word;
  }

begin

  {
  _memstr := TmemoryStream.create;
  _memstr.LoadFromFile(_nyomtatvanypath);
  _strlst := TstringList.Create;
  _strlst.LoadFromStream(_memstr);
  }

  logirorutin(pchar('text-kiiró indul'));
  if _printer<>1 then
    begin
      logirorutin(pchar('Nyomtatás küldés az LPT1-re'));
      AssignFile(_nyomtat,'LPT1:')
    end else
    begin
      logirorutin(pchar('Prn-re küldi a nyomtatást'));
      AssignPrn(_nyomtat);
    end;

  Rewrite(_nyomtat);

  {
  _q := 0;
  while _q<_strlst.Count do
    begin
      writeln(_nyomtat,_strlst.strings[_q]);
      inc(_q);
    end;
  System.CloseFile(_nyomtat);

  _strlst.free;
  _memstr.Free;
  }

  logirorutin(pchar('Most megnyitja a '+_nyomtatvanypath+'-t'));
  AssignFile(_olvas,_nyomtatvanypath);
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);

end;


// =============================================================================
             procedure TBLOKKNYOM.kilepotimerTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := false;
  Modalresult := 1;
end;

// =============================================================================
                      procedure TBlokknyom.soremeles;
// =============================================================================

begin
  writeLn(_LFile,' ');
end;


// =============================================================================
                      procedure TBLOKKNYOM.StartNyomtatas;
// =============================================================================

begin
  Writeln(_LFile,_LF5);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);
  TextKiiro;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$ SEGÉD FUNKCIÓK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
            function TBlokknyom.Elokieg(_s:string;_h: byte):string;
// =============================================================================

begin

  result := _s;
  while length(result)<_h do  result := ' '+result;
end;

// =============================================================================
         function TBlokkNyom.Hundatetostr(_caldat: TdateTime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


// =============================================================================
             function TBlokknyom.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);

end;


// =============================================================================
               function TBlokknyom.ArfolyamForm(_curr: real): string;
// =============================================================================

var
    _rs: string;
    _w1,_pos,_tdb,_need0: byte;

begin
  // _curr : 123.05
  _rs := floattostr(_curr);
  _w1 := length(_rs);
  _pos := Pos(',',_rs);

  if _pos=0 then
    begin
      _rs := _rs + '.0000';
      while length(_rs)<10 do _rs := ' ' + _rs;
      result := _rs;
      exit;
    end;
   _TDB := _w1-_pos;
   _need0 := 4-_tdb;
   if _need0>0 then _rs := _rs + dupestring('0',_need0);
   while length(_rs)<10 do _rs := ' '+_rs;
   result := _rs;
end;

// =============================================================================
               function TBlokkNyom.Nulele(_i: integer):string;
// =============================================================================

begin
  result := inttostr(_i);
  if _i<10 then result := '0' + result;
end;


function TBlokkNyom.EzoroszUgyfel: boolean;

begin
  result := False;
  if _currency<>'EUR' then exit;
  if _iso<>'RU' then exit;
  if _fizetendo<300000 then exit;

  result := true;
end;

procedure TBlokkNyom.OroszNyilatkozat;

var _un: string;

begin

  _un := trim(leftstr(_ugyfelnev,30));
  WriteLn(_LFile,_sorveg);
  writeLN(_Lfile,dupeString('-',40));
  Kozepreir('NYILATKOZAT/DECLARATION');
  writeLN(_Lfile,dupeString('-',40));

  writeLn(_Lfile,' ');
  writeLn(_Lfile,'Alulirott ' + _un);
  writeLn(_LFile,'kijelentem, hogy az altalam vasarolt EUR');
  writeLn(_LFile,'valutat szemelyes hasznalatra valtottam');
  writeLn(_LFile,' ');
  writeLn(_LFile,' /I declare that the just purchased');
  writeLn(_LFile,'EUR currency is for my personal usage');
  writeLN(_LFile,_sorveg + _sorveg);
  writeLn(_Lfile,dupeString('.',39));
  writeLn(_Lfile,'   ugyfel alairasa/signature of buyer');
  writeLN(_Lfile,_sorveg);
end;



end.
