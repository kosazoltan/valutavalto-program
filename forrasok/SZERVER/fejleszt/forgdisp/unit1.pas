unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    DBOOKQUERY: TIBQuery;
    DBOOKDBASE: TIBDatabase;
    DBOOKTRANZ: TIBTransaction;
    RECQUERY: TIBQuery;
    VQUERY: TIBQuery;
    GYQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    VDBASE: TIBDatabase;
    GYDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    VTRANZ: TIBTransaction;
    GYTRANZ: TIBTransaction;
    Panel1: TPanel;
    BitBtn2: TBitBtn;

    procedure BitBtn1Click(Sender: TObject);
  
    procedure Gyparancs(_ukaz: string);
    procedure PenztarAdatOLvasas;
    procedure EgynapFeldolgozas;
    procedure MakePenztarsor;
    procedure Legyujtes;
    procedure BitBtn2Click(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _ptarsor: array[1..150] of byte;
  _ptarnev: array[1..150] of string;

  _farok,_kertdatum,_dayb,_bf,_bt,_naps,_napmezo,_apcs,_stat,_napnev,_uznev: string;
  _aktptnev,_datum,_ido,_aktdnem,_bizonylatszam,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _bankjegy,_ftertek,_kezdij,_code,_nap: integer;
  _ptss,ptdarab: word;
  _pt,_ptdarab,_uzlet,_aktptar: byte;



implementation

{$R *.dfm}

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  Application.terminate;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin

  GyParancs('DELETE FROM FORG2DAYS');

  PenztarAdatOlvasas;

  _kertdatum := '2022.12.23';
  Egynapfeldolgozas;

  _kertdatum := '2023.01.03';
  Egynapfeldolgozas;

  sHOWMESSAGE('KÉSZEN VAGYOK');

end;


procedure TForm1.Egynapfeldolgozas;

begin
  _farok := midstr(_kertdatum,3,2)+midstr(_kertdatum,6,2);

  _dayb := 'DAYB' + _farok;
  _bf := 'BF' + _farok;
  _BT := 'BT' + _farok;
  _naps := midstr(_kertdatum,9,2);
  val(_naps,_nap,_code);
  _napmezo := 'N' + inttostr(_nap);

  _apcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _apcs := _apcs +'FROM '+_bf + ' FEJ JOIN ' + _bt + ' TET'+_sorveg;
  _apcs := _apcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;
  _apcs := _apcs + 'WHERE (FEJ.STORNO=1) AND ((FEJ.TIPUS=';
  _apcs := _apcs + chr(39)+'V'+chr(39)+') OR (FEJ.TIPUS='+chr(39)+'E'+chr(39)+'))';
  _apcs := _apcs + ' AND (FEJ.DATUM='+chr(39)+ _kertdatum + chr(39)+')';

  MakePenztarSor;
  Legyujtes;
end;







procedure TForm1.MakePenztarsor;

begin
  _PCS := 'SELECT * FROM ' + _dayb + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR';
  dbookdbase.connected := true;
  with DBookQuery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  _ptss := 0;
  while not dbookquery.eof do
    begin
      _pt := dbookquery.fieldByNAme('PENZTAR').asInteger;
      _stat := dbookquery.FieldByNAme(_napMEZO).asString;
      if _stat='B' then
        begin
          inc(_ptss);
          _ptarsor[_ptss] := _pt;
        end;
      dbookquery.next;
    end;
  _ptdarab := _ptss;
  dbookquery.close;
  dbookdbase.close;
end;


PROCEDURE TForm1.PenztaradatOlvasas;

begin
  recdbase.connected := true;
  with recquery do
    begin
      CLose;
      sql.clear;
      sql.add('SELECT * FROM IRODAK');
      Open;
    end;

  while not recquery.eof do
    begin
      _uzlet := RecQuery.fieldByNAme('UZLET').asInteger;
      _uznev := trim(RecQuery.FieldByNAme('KESZLETNEV').asString);
      _ptarnev[_uzlet] := _uzNev;
      recquery.next;
    end;
  recquery.close;
  recdbase.close;
end;


procedure TForm1.Legyujtes;

begin
  _ptss := 1;
  while _ptss<=_ptDarab do
    begin
      _aktptar := _ptarsor[_ptss];
      _aktptnev := _ptarnev[_aktptar];
      panel1.Caption := _aktptnev;
      panel1.Repaint;
      vDbase.close;
      vdbase.databasename := 'c:\receptor\database\v' + inttostr(_aktptar)+'.FDB';
      vDBASE.connected := true;

      with vQuery do
        begin
          Close;
          sql.clear;
          sql.add(_apcs);
          Open;
        end;

      while not vQuery.Eof do
        begin
          _datum := vQuery.FieldByNAme('DATUM').asString;
          _ido  := vQuery.FieldByNAme('IDO').asstring;
          _bizonylatszam := vQuery.FieldByNAme('BIZONYLATSZAM').asString;
          _bankjegy := vQuery.fieldByNAme('BANKJEGY').asInteger;
          _aktdnem := vQuery.fieldByName('VALUTANEM').asString;
          _ftertek := vQuery.FieldByName('FORINTERTEK').asInteger;
          _kezdij := vQuery.FieldByNAme('KEZELESIDIJ').asInteger;

          _pcs := 'INSERT INTO FORG2DAYS (PENZTARSZAM,PENZTARNEV,DATUM,IDO,';
          _pcs := _pcs + 'BIZONYLATSZAM,BANKJEGY,VALUTANEM,FTERTEK,KEZELESIDIJ)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_aktptar) + ',';
          _pcs := _pcs + chr(39) + _aktptnev + chr(39) + ',';
          _PCS := _pcs + chr(39) + _datum + chr(39) + ',';
          _PCS := _pcs + chr(39) + _ido + chr(39) + ',';
          _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
          _pcs := _pcs + inttostr(_bankjegy) + ',';
          _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
          _pcs := _pcs + inttostr(_ftertek) + ',';
          _pcs := _pcs + inttostr(_kezdij) + ')';
          GyParancs(_pcs);
          vquery.next;
        end;
      Vquery.close;
      Vdbase.close;
      inc(_ptss);
    end;
end;

procedure TForm1.Gyparancs(_ukaz: string);
begin
  Gydbase.Connected := true;
  if gytranz.InTransaction then Gytranz.Commit;
  Gytranz.StartTransaction;
  with GyQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Gytranz.commit;
  Gydbase.close;
end;      







end.
