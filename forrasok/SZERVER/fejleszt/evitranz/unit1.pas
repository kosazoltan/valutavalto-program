unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, IBTable;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    BEST: TPanel;
    EAST: TPanel;
    PANNON: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    IBTABLA: TIBTable;
    penztar: TPanel;
    honap: TPanel;

    procedure IrodaBeolvasas;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    function Nulele(_b: byte): string;
    function Ezertektar(_p: byte): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _sumtranz: array[1..3] of integer;
  _pt,_kft,_ho,_uzlet: byte;
  _cb: array[1..150] of byte;

  _fdbPath,_bf,_PCS,_betu: string;
  _sorveg: string = chr(13)+chr(10);

  _AKTVET,_aktelad: integer;



implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  APPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
   Irodabeolvasas;

  _sumtranz[1] := 0;
  _sumtranz[2] := 0;
  _sumtranz[3] := 0;

  _pt := 4;
  while _pt<=150 do
    begin
      if ezertektar(_pt) then
        begin
          inc(_pt);
          Continue;
        end;

     _fdbPath := 'c:\receptor\database\v' + INTTOSTR(_PT)+'.FDB';
     IF not FileExists(_fdbPath) then
        begin
          inc(_pt);
          Continue;
        end;

      _kft := _cb[_pt];

      Penztar.caption := _fdbPath;
      Penztar.repaint;

      ibdbase.close;
      ibdbase.DatabaseName := _fdbPath;

      ibdbase.Connected := true;
      _ho := 1;
      while _ho<=12 do
        begin
          _bf := 'BF18' + NULELE(_HO);
          Honap.Caption := _bf;
          Honap.repaint;
          ibtabla.tablename := _bf;
          if not ibtabla.exists then
            begin
              inc(_ho);
              Continue;
            end;
          _pcs := 'SELECT * FROM ' + _BF + _sorveg;
          _pcs := _pcs + 'WHERE (STORNO=1) AND (TIPUS='+chr(39)+'V'+chr(39)+')';

          with ibquery do
            begin
              Close;
              Sql.clear;
              sql.add(_pcs);
              Open;
              Last;
              _aktvet := recno;
              Close;
            end;

          _pcs := 'SELECT * FROM ' + _BF + _sorveg;
          _pcs := _pcs + 'WHERE (STORNO=1) AND (TIPUS='+chr(39)+'E'+chr(39)+')';

          with ibquery do
            begin
              Close;
              Sql.clear;
              sql.add(_pcs);
              Open;
              Last;
              _aktelad := recno;
              Close;
            end;

          _sumTRANZ[_kft] := _sumTRANZ[_kft] + _AKTVET + _aktELAD;

          inc(_ho);
        end;
      ibdbase.close;
      inc(_pt);
    end;

  Best.Caption := inttostr(_sumtranz[1]);
  Best.repaint;

  East.Caption := inttostr(_sumtranz[2]);
  East.repaint;

  Pannon.Caption := inttostr(_sumtranz[3]);
  Pannon.repaint;

end;

procedure TForm1.irodaBeolvasas;

begin
  _fdbPath := 'c:\receptor\database\receptor.fdb';
  ibdbase.close;
  ibdbase.databasename := _fdbPath;
  _pcs := 'Select * FROM IRODAK';
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not ibquery.eof do
    begin
      _uzlet := ibquery.FieldByNAme('UZLET').asInteger;
      _betu  := ibquery.FieldByNAme('CEGBETU').asString;
      if _betu = 'B' then _cb[_uzlet] := 1;
      if _betu = 'E' then _cb[_uzlet] := 2;
      if _betu = 'P' then _cb[_uzlet] := 3;
      IBQUERY.NEXT;
    end;
  ibquery.close;
  ibdbase.close;
end;

function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + RESULT;
end;

function Tform1.Ezertektar(_p: byte): boolean;

begin
  result := false;
  if (_p=10) or (_p=20) or (_p=40) or (_p=63) or (_p=75) then result := True;
  if (_p=120) or (_p=145) or (_p=50) then result := true;
end;

end.
