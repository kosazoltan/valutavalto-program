unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, strutils;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Memo1: TMemo;
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    Memo2: TMemo;
    TETQUERY: TIBQuery;
    TETDBASE: TIBDatabase;
    TETTRANZ: TIBTransaction;
    PQUERY: TIBQuery;
    PDBASE: TIBDatabase;
    PTRANZ: TIBTransaction;

    procedure BitBtn1Click(Sender: TObject);

    function Angolra(_huName: string): string;
    function HutoGb(_kod: byte): byte;
    procedure BitBtn2Click(Sender: TObject);
    procedure EgypenztarMenet;
    procedure Regisztralas;
    procedure Egysorbeiras;

    function Nulele(_b: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _farok,_bfej,_pcs: string;

  _sorveg : string = chr(13) + chr(10);

  _aktfark,_hasnev,_biz,_aktdnem,_aktunev,_datum: string;
  _endfarok,_btet: string;
  _bankjegy,_ftertek,_ARFOLYAM: integer;

  _aktev,_q,_wh: BYTE;
  _aktho : byte;

  _endev : byte;
  _endho : byte;


  _nev: array[1..14] of string = ('FARAGO VIVIEN','CSURAR FERENC','ROSTAS MATILD',
         'JAKAB LI','CSURAR BENCE','SZTOJKA KATALIN','CSURAR ROLAND',
         'KONCSIK DZSEN','FARAGO RAJMUND','FARAGONE ERDELYI','CSURAR MIHALY',
         'CSURAR FERENC','MOHACSI KATALIN','FARAGO ROBERT');

  _szul: array[1..14] of string = ('1999.03','1985.06','1986.03','2001.01',
         '1999.06','1992.04','1988.01','1999.07','1997.11','2002.07','1995.02',
         '1965.11','1968.10','2000.10');

   _penztar: array[1..4] of byte = (71,74,76,77);
   _pss,_aktpenztar: byte;
   _fdbPath,_unev: string;

implementation

{$R *.dfm}


procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  _pss := 1;
  while _pss<=4 do
    begin
      _aktpenztar := _penztar[_pss];
      _fdbPath := 'c:\receptor\database\v' + inttostr(_aktpenztar)+'.FDB';
      vdbase.close;
      vdbase.Databasename := _fdbpath;
      vdbase.connected := true;

      Memo2.Lines.Add(_fdbpath);

      EgypenztarMenet;
      inc(_pss);
    end;
  Vdbase.close;
end;

procedure TForm1.EgypenztarMenet;

begin
  _aktev    := 22;
  _aktho    := 1;
  _endfarok := '2203';
  _farok    := '2201';

  while _farok<=_endfarok do
    begin
      _bfej := 'BF' + _farok;
      vtabla.close;
      vtabla.TableName := _bfej;
      if not Vtabla.Exists then
        begin
          inc(_aktho);
          if _aktho>12 then
            begin
              _aktho := 1;
              inc(_aktev);
             end;
          _farok := inttostr(_aktev) + nulele(_aktho);
          Continue;
        end;

      Memo2.Lines.Add(_bfej);
      _pcs := 'SELECT * FROM ' + _bfej + _sorveg;
      _pcs := _pcs + 'WHERE (UGYFELTIPUS=' + chr(39) + 'N' + chr(39)+')';
      _pcs := _pcs + ' AND (STORNO=1)';

      with Vquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not Vquery.eof do
        begin
          _unev := trim(Vquery.fieldByNAme('UGYFELNEV').asString);
          _biz  := Vquery.fieldByNAme('BIZONYLATSZAM').asString;
          _unev := angolra(_unev);
          _q := 1;
          while _q<=14 do
            begin
              _hasnev := _nev[_q];
              _wh := length(_hasnev);
              if leftstr(_unev,_wh)=_hasnev then
                begin
                  REGISZTRALAS;
                  mEMO1.Lines.ADD(_UNEV);
                end;
              inc(_q);
            end;
          Vquery.next;
        end;
      Vquery.close;
      inc(_aktho);
      if _aktho>12 then
        begin
          _aktho := 1;
          inc(_aktev);
        end;
      _farok := inttostr(_aktev) + nulele(_aktho);
    end;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  Application.Terminate;
end;


// =============================================================================
                 function TForm1.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
end;


// =============================================================================
                   function TForm1.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;

function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


PROCEDURE TForm1.Regisztralas;

begin
  _bTet := 'BT' + _farok;
  tetdbase.close;
  tetdbase.DatabaseName :=_fdbPath;
  Tetdbase.Connected := True;
  _pcs := 'SELECT * FROM ' + _BTET + _sorveg;
  _pcs := _PCS + 'WHERE BIZONYLATSZAM=' + chr(39)+_biz+chr(39);
  with TetQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  while not Tetquery.Eof do
    begin
      with Tetquery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _datum := FieldByName('DATUM').asString;
          _bankjegy := FieldByName('BANKJEGY').asInteger;
          _FTERTEK := Fieldbyname('FORINTERTEK').asInteger;
          _arfolyam := FieldByNAme('ARFOLYAM').asInteger;
        end;
      Egysorbeiras;
      Tetquery.Next;
    end;
  TetQuery.close;
  Tetdbase.close;
end;

procedure TForm1.Egysorbeiras;
begin
  _pcs := 'INSERT INTO POLICE (NEV,DATUM,PENZTAR,BIZONYLATSZAM,BANKJEGY,';
  _pcs := _pcs + 'VALUTANEM,ARFOLYAM,FORINTOSSZEG)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + _uNev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktpenztar) + ',';
  _pcs := _pcs + chr(39) + _biz + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_arfolyam) + ',';
  _pcs := _pcs + inttostr(_ftertek) + ')';

  Pdbase.connected := True;
  if ptranz.InTransaction then ptranz.commit;
  ptranz.StartTransaction;
  with Pquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  ptranz.commit;
  pdbase.close;
end;


end.
