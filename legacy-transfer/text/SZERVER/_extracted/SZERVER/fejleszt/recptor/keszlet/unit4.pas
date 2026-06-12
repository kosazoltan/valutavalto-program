unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, IBDatabase, IBCustomDataSet, IBQuery,
  IBTable, strutils, unit1;

type
  TKESZLETREGISZT = class(TForm)
    IDOZITO: TTimer;
    VQUERY: TIBQuery;
    VTRANZ: TIBTransaction;
    VDBASE: TIBDatabase;
    vtabla: TIBTable;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    Label1: TLabel;

    procedure FormActivate(Sender: TObject);
    procedure IDOZITOTimer(Sender: TObject);
    function Getertektar: integer;

    procedure DnemKodolo(_dnem: string);
    procedure Zarokodolo(_sVal: integer);
    function Nulele4(_int: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KESZLETREGISZT: TKESZLETREGISZT;
  _keszDatum: string;
  _kesziroda: integer;

  _bytetomb: array[1..255] of byte;
  _fnev: array[0..99] of string;
  _farok,_keszirodastring,_keszfile,_keszpath,_minta,_delPath: string;
  _gdbPath,_cimtarnev,_wzarnev,_tradenev,_pcs,_aktdnem: string;
  _ertektar,_cc,_tetel,_aktzaro,_recno,_usdzaro,_hufzaro,_metrozaro: integer;
  _tescoZaro,_afazaro,_kezelesidij,_zaro: integer;
  _srec: Tsearchrec;
  _pointer,_fileHossz: byte;
  _sorveg: string = chr(13)+chr(10);
  _biniras: file of byte;
  _width,_height: word;



implementation

{$R *.dfm}


procedure TKESZLETREGISZT.FormActivate(Sender: TObject);
begin
  
  Top  := 100;
  Left := 250;
  Label1.repaint;


  _keszdatum := _aktdatum;
  _kesziroda := _aktirodaszam;

  Idozito.enabled := true;
end;

procedure TKESZLETREGISZT.IDOZITOTimer(Sender: TObject);

var i: integer;

begin
  Idozito.Enabled := False;

  _farok := midstr(_keszdatum,3,2)+midstr(_keszdatum,6,2);

  _ertektar := getertektar;
  _keszirodastring := Nulele4(_kesziroda);
  _keszfile := _keszirodastring+midstr(_keszdatum,6,2)+midstr(_keszdatum,9,2)+'.'+inttostr(_ertektar);
  _keszpath := 'c:\receptor\mail\keszlet\'+_keszfile;

  _minta := 'c:\receptor\mail\keszlet\'+_keszirodastring + '*.'+ inttostr(_ertektar);

  if FindFirst(_minta,faAnyFile,_srec) = 0 then
    begin
      repeat
        _fnev[_cc] := _srec.name;
        inc(_cc);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  if _cc>0 then
    begin
      for i:= 0 to (_cc-1) do
        begin
          _delpath := 'c:\receptor\mail\keszlet\'+_fnev[i];
          DeleteFile(_delpath);
        end;
    end;

  // ---------------------------------------------------------------------------

  _gdbPath   := 'c:\receptor\database\V'+inttostr(_kesziroda)+'.gdb';

  _cimtarnev := 'CIMT' + _farok;
  _wzarnev   := 'WZAR' + _farok;
  _tradenev  := 'TRAD' + _farok;

  _pointer := 2;
  _tetel := 0;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM ' + _cimtarnev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _keszdatum + chr(39);


  vdbase.close;
  vdbase.DatabaseName := _gdbPath;
  vdbase.Connected := true;

  with vQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not vQuery.Eof do
    begin
      _aktdnem := Vquery.fieldByNAme('VALUTANEM').asString;
      _aktzaro := VQuery.FieldByName('OSSZESEN').asInteger;

      dnemKodolo(_aktdnem);
      Zarokodolo(_aktzaro);
      inc(_tetel);
      Vquery.Next;
    end;
  Vquery.close;


  // -*-------------------------------------------------------------------------

  _pcs := 'SELECT * FROM ' + _wZarnev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _keszdatum + chr(39);

  with vQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      _usdzaro := Vquery.FieldByName('USDZARO').asInteger;
      _hufzaro := Vquery.FieldByName('HUFZARO').asInteger;
      _metrozaro := Vquery.FieldByName('METROZARO').asInteger;
      _tescozaro := Vquery.FieldByName('TESCOZARO').asInteger;
      _afazaro := _metrozaro + _tescozaro;
      _kezelesidij := VQuery.FieldByName('UGYKEZELESIDIJ').asInteger;

      if _usdzaro>0 then
        begin
          dnemKodolo('WUS');
          zarokodolo(_usdzaro);
          inc(_tetel);
        end;

      if _hufzaro>0 then
        begin
          dnemKodolo('WHU');
          zarokodolo(_hufzaro);
          inc(_tetel);
        end;

      if _afazaro>0 then
        begin
          dnemkodolo('AFA');
          zarokodolo(_afazaro);
          inc(_tetel);
        end;

      if _kezelesidij>0 then
        begin
          dnemkodolo('KEZ');
          zarokodolo(_kezelesidij);
          inc(_tetel);
        end;
    end;

  vQuery.close;

  // ---------------------------------------------------------------------------

  vtabla.close;
  vtabla.TableName := _tradenev;
  if vtabla.Exists then
    begin
      _pcs := 'SELECT * FROM ' + _tradenev + _sorveg;
      _pcs := _Pcs + 'WHERE DATUM=' +chr(39)+ _keszdatum +chr(39);
      with VQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          _zaro := VQuery.fieldbyName('ZAROKESZLET').asInteger;
          dnemKodolo('TRD');
          zarokodolo(_zaro);
          inc(_tetel);
        end;
      vquery.close;
    end;
  Vdbase.close;

  _fileHossz := _pointer-1;
  _bytetomb[1] := _filehossz;

  Assignfile(_biniras,_keszPath);
  rewrite(_biniras);

  BlockWrite(_biniras,_bytetomb,_fileHossz);
  CLoseFile(_biniras);
  ModalResult := 1;
end;


function TKeszletREGISZT.Getertektar: integer;

begin
  recdbase.connected := true;
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE UZLET=' + inttostr(_kesziroda);
  with recQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  result := 0;

  if _recno>0 then
    begin
      result := recquery.fieldbyNAme('ERTEKTAR').asInteger;
    end;

  recquery.close;
  recdbase.close;
end;

function TKeszletREGISZT.Nulele4(_int: byte): string;

begin
  result := inttostr(_int);
  if _int<100 then result := '0' + result;
  if _int<10 then result := '0' + result;
  result := '0' + result;
end;


// =============================================================================
                procedure TKeszletREGISZT.DnemKodolo(_dnem: string);
// =============================================================================

var _a,_b,_c,_1,_1a,_2: integer;

begin

  if _dnem='' then exit;
  _a := ord(_dnem[1]) - 65;
  _b := ord(_dnem[2]) - 65;
  _c := ord(_dnem[3]) - 65;
  _1 := 4*_a;
  _1a := trunc(_b/8);
  _1 := _1 + _1a;
  _2 := 32*_b;
  while _2>255 do _2 := _2 - 256;
  _2 := _2 + _c;

  _bytetomb[_pointer] := _1;
  _bytetomb[1+_pointer]:= _2;
  _pointer := _pointer+2;
end;

// =============================================================================
             procedure TKeszletRegiszt.Zarokodolo(_sVal: integer);
// =============================================================================


var _big3: integer;
    _hhi,_hlo,_hi,_lo: byte;

begin
  _big3 := trunc(65536*256);
  _hhi := trunc(_sVal/_big3);
  _sVal := _sval - trunc(_big3*_hhi);
  _hlo := trunc(_sval/65536);
  _sval := _sval - trunc(65536*_hlo);
  _hi := trunc(_sval/256);
  _lo := _sval - trunc(256*_hi);

  _bytetomb[_pointer]   := _lo;
  _bytetomb[_pointer+1] := _hi;
  _bytetomb[_pointer+2] := _hlo;
  _bytetomb[_pointer+3] := _hhi;

  _pointer := _pointer +4;

end;





end.
