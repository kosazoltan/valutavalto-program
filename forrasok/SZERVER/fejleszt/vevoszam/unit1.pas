unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable, comobj,
  ExtCtrls, StdCtrls;

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
    Button1: TButton;
    Button2: TButton;
    UGYFQUERY: TIBQuery;
    UGYFDBASE: TIBDatabase;
    ugyftranz: TIBTransaction;

    procedure IrodaBeolvasas;
    function Nulele(_b: byte): string;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pt,_aktetar,_ess: byte;
  _etar: array[1..150] of byte;
  _fdbpath,_farok,_bfnev,_pcs,_tipus,_allampolg: string;
  _sorveg: string = chr(13)+chr(10);
  _ev,_ho: word;
  _aktdb: integer;
  _vevodarab: array[1..12] of integer;
  _svevodarab: integer;
  _ptarnev: array[1..150] of string;
  _ptexists: array[1..150] of boolean;

  _UGYFELDARAB: INTEGER;

  _kv,_ke,_bv,_be,_ugyfszam,_forint,_uv,_ue,_recno: integer;
  _kulfoldi,_gazdag: boolean;
  _BVFT,_BEFT,_KVFT,_KEFT,_uvft,_ueft: real;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);

var i: byte;
 //  _iras: textfile;

begin
  _kv := 0;
  _ke := 0;
  _kvft := 0;
  _keft := 0;

  _bv := 0;
  _be := 0;
  _bvft := 0;
  _beft := 0;

  _uv := 0;
  _ue := 0;
  _uvft := 0;
  _ueft := 0;



  for i := 1 to 12 do  _vevodarab[i] := 0;

  pANEL1.Caption := 'IRODÁK BEOLVASÁSA';
  Panel1.Repaint;

  IrodaBeolvasas;
  _UGYFELDARAB:= 0;

  _pt := 1;
  while _pt<=150 do
    begin
      if not _ptexists[_pt] THEN
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

      vdbase.close;
      vdbase.databasename := _fdbpath;


      _bfnev := 'BF1401';

      vdbase.connected := true;
      vtabla.tablename := _bfnev;
      if not vtabla.exists then
        begin
          vDbase.Close;
          inc(_PT);
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
          first;
        end;

      while not vquery.eof do
        begin
          _UGYFELDARAB := _UGYFELDARAB+1;
          vquery.Next;
        end;

      vQuery.close;
      vdbase.close;

      inc(_pt);
    end;


  Showmessage('KESZEN VAN ! :'+INTTOSTR(_UGYFELDARAB)+' DB');

end;


PROCEDURE TForm1.Irodabeolvasas;

var _pt,i: byte;
    _cl,_st,_pn: string;

begin
  for i := 1 to 150 do _ptexists[i] := false;

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

      _cl := Recquery.FieldByNAme('CLOSED').asString;
      _st := Recquery.FieldByNAme('STATUS').asString;

      if (_cl='X') or (_st<>'P') then
        begin
          recquery.Next;
          continue;
        end;
      _ptexists[_pt] := True;
      _ptarnev[_pt] := _pn;
      Panel1.Caption := _pn;
      Panel1.Repaint;
     
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


procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;


end.
