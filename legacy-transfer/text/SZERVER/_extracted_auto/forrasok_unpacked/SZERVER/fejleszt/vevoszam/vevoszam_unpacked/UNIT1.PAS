unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable, comobj,
  ExtCtrls;

type
  TForm1 = class(TForm)
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    Panel1: TPanel;
    procedure FormActivate(Sender: TObject);
    procedure IrodaBeolvasas;
    function Nulele(_b: byte): string;
    procedure MakeExcel;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pt,_aktetar,_ess: byte;
  _etar: array[1..150] of byte;
  _fdbpath,_farok,_bfnev,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _ev,_ho: word;
  _aktdb: integer;
  _vdb: array[1..150,0..1] of integer;
  _ptarnev: array[1..150] of string;
  _oxl,_owb: variant;


implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);

var i,j: byte;

begin
  for i := 1 to 150 do
    begin
      for j := 0 to 1 do _vdb[i,j] := 0;
    end;
  for i := 1 to 150 do _ptarnev[i] := ' ';

  iRODABEOLVASAS;
  _pt := 1;
  while _pt<=150 do
    begin
      _aktetar := _etar[_pt];
      if _aktetar=0 then
        begin
          inc(_pt);
          Continue;
        end;

      _fdbPath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';
      if not fileExists(_fdbpath) then
         begin
           inc(_pt);
           Continue;
         end;

      Panel1.Caption := _fdbpath;
      Panel1.Repaint;
      vdbase.databasename := _fdbpath;

      _ev := 2013;
      while _ev<=2014 do
        begin
          _ho := 1;
          while _ho<=12 do
            begin
              _farok := inttostr(_ev-2000)+nulele(_ho);
              _bfnev := 'BF' + _farok;
              vdbase.connected := true;
              vtabla.tablename := _bfnev;
              if not vtabla.exists then
                begin
                  VDBASE.CLOSE;
                  inc(_ho);
                  continue;
                end;
              _pcs := 'SELECT *  FROM ' + _BFNEV + _sorveg;
              _pcs := _pcs + 'WHERE (STORNO=1) AND (TIPUS<>' + chr(39)+'F'+chr(39);
              _pcs := _pcs + ') AND (TIPUS<>'+chr(39)+'U'+CHR(39)+')';
              with vquery do
                begin
                  Close;
                  Sql.clear;
                  sql.add(_pcs);
                  Open;
                  Last;
                  _aktdb := recno;
                  close;
                end;
              vdbase.close;
              _ess := _ev-2013;
              _vdb[_pt,_ess] := _vdb[_pt,_ess] + _aktdb;
              inc(_ho);
            end;
          inc(_ev);
        end;
      inc(_pt);
    end;
  Makeexcel;


end;


PROCEDURE TForm1.Irodabeolvasas;

var i,_pt,_et: byte;
    _cl,_st,_pn: string;

begin

  for i := 1 to 150 do _etar[i] := 0;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  recdbase.Connected := True;
  with recquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not recquery.Eof do
    begin
      _pt := Recquery.fieldbyname('UZLET').asInteger;
      _pn := trim(Recquery.FieldByNAme('KESZLETNEV').asString);
      _et := Recquery.fieldByNAme('ERTEKTAR').asInteger;
      _cl := Recquery.FieldByNAme('CLOSED').asString;
      _st := Recquery.FieldByNAme('STATUS').asString;

      if (_cl='X') or (_st<>'P') then
        begin
          recquery.Next;
          continue;
        end;
      _ptarnev[_pt] := _pn;
      _etar[_pt] := _et;
      recquery.next;
    end;
  recquery.close;
  recdbase.close;
end;

function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


procedure TForm1.Makeexcel;

begin
  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

  _pt := 1;
  while _pt<=150 do
    begin
      _oxl.cells[_pt,1] := inttostr(_pt);
      _oxl.cells[_pt,2] := _ptarnev[_pt];
      _oxl.cells[_pt,3] := inttostr(_vdb[_pt,0]);
      _oxl.cells[_pt,4] := inttostr(_vdb[_pt,1]);
      inc(_pt);
    end;
  _oxl.visible := true;
end;




end.
