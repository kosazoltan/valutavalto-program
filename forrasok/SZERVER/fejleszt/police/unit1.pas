unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, IBTable, strutils;


type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label1: TLabel;
    ibquery: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    IBTabla: TIBTable;
    PQUERY: TIBQuery;
    PDBASE: TIBDatabase;
    PTRANZ: TIBTransaction;
    BitBtn3: TBitBtn;
    PTABLA: TIBTable;
    UQUERY: TIBQuery;
    UDBASE: TIBDatabase;
    UTRANZ: TIBTransaction;

    procedure PParancs(_ukaz: string);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    function ezertektar(_p: byte): boolean;
    function FarokLepteto(_f: string): string;
    procedure Ugyfelbeolvaso;

    fUNCTION Nulele(_b: byte): string;
    procedure BitBtn3Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _tolfarok,_igfarok,_farok,_bt,_workdir,_irpath,_un,_ut,_bf: string;
  _fdbPath,_pcs,_biz,_dat,_mondat,_evs,_hos: string;
  _szulido,_szulhely,_azonosito: string;
  _pt: byte;
  _recno,_bjy,_ev,_ho,_code,_fte,_usz: integer;
  _sorveg: string = chr(13)+chr(10);
  _iras: textFile;

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin

  _PCS := 'DELETE FROM POLICE';
  pparancs(_pcs);

  _tolfarok := '1506';
  _igfarok  := '1710';

  _pt := 1;
  while _pt<=150 do
    begin
      _fdbPath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';
      if not FileExists(_fdbPath) then
        begin
          inc(_pt);
          Continue;
        end;

      if Ezertektar(_pt) then
         begin
          inc(_pt);
          Continue;
        end;


      Panel1.Caption := _fdbPath;
      Panel1.Repaint;

      // -----------------------------

      ibdbase.close;
      ibdbase.DatabaseName := _fdbPath;

      udbase.close;
      udbase.DatabaseName := _fdbPath;

      _farok := _tolfarok;
      while _farok<=_igfarok do
        begin
          _bt := 'BT'+_farok;
          _bf := 'BF'+_farok;

          Panel2.Caption := _bt;
          Panel2.repaint;

          ibtabla.close;
          ibtabla.TableName := _bt;
          ibdbase.connected := true;
          if not ibtabla.exists then
            begin
              _farok := FarokLepteto(_farok);
              ibdbase.close;
              Continue;
            end;
          _pcs := 'SELECT * FROM ' + _bf + _sorveg;
          _pcs := _pcs + 'WHERE (UGYFELNEV like '+CHR(39)+'FARKAS ATT%'+CHR(39)+')';
          _pcs := _pcs + ' OR (UGYFELNEV LIKE '+CHR(39)+'FARKAS RAM%'+CHR(39)+')';

          with ibquery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              First;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              while not ibquery.eof do
                begin
                  _biz := ibquery.FieldByName('BIZONYLATSZAM').asstring;
                  _dat := ibquery.FieldByName('DATUM').asstring;
                  _un := ibquery.FieldByName('UGYFELNEV').asString;
                  _usz := ibquery.FieldByName('UGYFELSZAM').asinteger;

                  Ugyfelbeolvaso;

                  _pcs := 'INSERT INTO POLICE (PENZTAR,DATUM,BIZONYLATSZAM,UGYFELNEV,';
                  _pcs := _pcs + 'SZULIDO,SZULHELY,AZONOSITO)'+_SORveg;
                  _pcs := _pcs + 'VALUES (' + inttostr(_pt) + ',';
                  _pcs := _pcs + chr(39) + _dat + chr(39) + ',';
                  _pcs := _pcs + chr(39) + _biz + chr(39) + ',';
                  _pcs := _pcs + chr(39) + _un + chr(39) + ',';
                  _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
                  _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
                  _pcs := _pcs + chr(39) + _azonosito + chr(39) + ')';


                  PParancs(_pcs);
                  ibquery.next;
                end;
            end;
          ibquery.close;
          ibdbase.close;
          _farok := farokLepteto(_farok);
        end;
      inc(_pt);
    end;

  ShowMessage(' készen vagyok');
end;



procedure TForm1.Ugyfelbeolvaso;

begin
  _szulido := '';
  _szulhely :='';
  _azonosito := '';

  _pcs := 'SELECT * FROM UGYFELEK WHERE UGYFELSZAM='+inttostr(_usz);
  Udbase.connected := true;
  with uquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      _szulido := trim(Uquery.FieldByName('SZULETESIIDO').asstring);
      _szulhely := trim(Uquery.FieldByName('SZULETESIHELY').asstring);
      _azonosito := trim(Uquery.Fieldbyname('AZONOSITO').asString);
    end;
  uquery.close;
  udbase.close;
end;



procedure TForm1.PParancs(_ukaz: string);

begin
  pdbase.connected := true;
  if ptranz.InTransaction then ptranz.Commit;
  ptranz.StartTransaction;
  with pquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Ptranz.commit;
  pdbase.close;
end;


function TForm1.ezertektar(_p: byte): boolean;

begin
  result := true;
  if (_p=10) or (_p=20) or (_p=40) or (_p=50) or (_p=63) then exit;
  if (_p=75) or (_p=120) or (_p=145) then exit;
  result := False;
end;

function TForm1.FarokLepteto(_f: string): string;

begin
  _evs := leftstr(_f,2);
  _hos := midstr(_f,3,2);

  val(_evs,_ev,_code);
  val(_hos,_ho,_code);

  inc(_ho);
  if _ho>12 then
    begin
      _ho := 1;
      inc(_ev)
    end;

  result := nulele(_ev)+nulele(_ho);
end;

FUNCTION tfORM1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  pDBASE.Connected := TRUE;
  if ptranz.InTransaction then Ptranz.commit;
  Ptranz.StartTransaction;

  PTabla.Open;
  Ptabla.first;
  while not Ptabla.Eof do
    begin
      _pt    := PTabla.FieldByName('PENZTAR').asInteger;
      _dat := Ptabla.fieldByName('DATUM').asstring;
      _biz   := Ptabla.FieldbyName('BIZONYLATSZAM').asstring;

      _farok := midstr(_dat,3,2)+midstr(_dat,6,2);
      _bf := 'BF' + _farok;
      _fdbPath := 'c:\receptor\database\v'+INTTOSTR(_PT)+'.FDB';

      _usz := 0;
      _ut := '';
      _un := '';

      ibdbase.Close;
      ibdbase.DatabaseName := _fdbPath;
      ibDbase.Connected := true;

      _pcs := 'SELECT * FROM '+_BF + _sorveg;
      _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_biz+chr(39);
      with ibquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _usz := FieldByName('UGYFELSZAM').asInteger;
        end;
      if _usz>0 then
        begin
          _Ut := ibquery.FieldByName('UGYFELTIPUS').ASSTRING;
          _UN := trim(IBQUERY.fIELDbYnAME('UGYFELNEV').asstring);
        end;

      ibquery.close;
      ibdbase.close;

      // -------------------------------

      with Ptabla do
        begin
          Edit;
          fieldByName('UGYFELTIPUS').AsString := _ut;
          fieldByName('UGYFELSZAM').AsInteger := _usz;
          FieldByName('UGYFELNEV').AsString := _un;
          post;
        end;
      Ptabla.next;
    end;
  Ptranz.commit;
  Pdbase.close;
end;

end.
