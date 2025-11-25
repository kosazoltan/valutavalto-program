unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable, StdCtrls,
  ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    RECTABLA: TIBTable;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    pttabla: TIBTable;
    ptquery: TIBQuery;
    ptdbase: TIBDatabase;
    pttranz: TIBTransaction;
    TRANZTABLA: TIBTable;
    TRANZQUERY: TIBQuery;
    TRANZDBASE: TIBDatabase;
    TRANZTRANZ: TIBTransaction;
    ptarpanel: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure UzletekBeolvasasa;
    procedure Havikiolvasas;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _qq,_uzletdarab,_uzlet,_aktpenztar,_osszesen,_eladdb: integer;
  _sumvet,_sumelad,_sumkonv,_vetdb,_konvdb,_over3m: integer;
  _sorveg: string = chr(13)+chr(10);
  _pcs,_status,_CEGBETU,_aktcegbetu,_aktstatus,_aktfdbpath: string;
  _bfnev,_tipus: string;
  _3mill:real;

  _pt: array[0..150] of integer;
  _st: array[0..150] of string;
  _cb: array[0..150] of string;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  UzletekBeolvasasa;
  _qq := 0;
  while _qq<_uzletdarab do
    begin
      Havikiolvasas;
      inc(_qq);
    end;
end;

procedure TForm1.UzletekBeolvasasa;

begin
  _qq := 0;
  _pcs := 'SELECT * FROM IRODAK' +_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  recDbase.connected := true;
  with Recquery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not recquery.eof do
    begin
      _uzlet := recquery.fieldbyname('UZLET').asInteger;
      _status := recquery.FieldByNAme('STATUS').asString;
      _cegbetu := recquery.FieldByNAme('CEGBETU').asString;

      _pt[_qq] := _uzlet;
      _st[_qq] := _status;
      _cb[_qq] := _cegbetu;
      recquery.next;
      inc(_qq);
    end;
  _uzletdarab := _qq;
  recquery.close;
  recdbase.close;
end;

procedure TForm1.HaviKiolvasas;

begin
  _aktpenztar := _pt[_qq];
  _aktcegbetu := _cb[_qq];
  _aktstatus  := _st[_qq];


  ptarpanel.Caption := inttostr(_aktpenztar);
  ptarpanel.Repaint;

  if _aktstatus<>'P' then exit;

  _aktfdbpath := 'c:\receptor\database\v'+inttostr(_aktpenztar)+'.fdb';

  ptDbase.close;
  ptdbase.Databasename := _aktfdbPath;
  ptDbase.connected := True;
  pttabla.close;
  _bfnev := 'BF1212';
  pttabla.tablename := _bfnev;
  if not pttabla.exists then
    begin
      ptdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM BF1212' + _SORVEG;
  _pcs := _pcs + 'WHERE STORNO=1';

  with ptquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _vetdb   := 0;
  _eladdb  := 0;
  _konvdb  := 0;
  _sumvet  := 0;
  _sumelad := 0;
  _sumkonv := 0;
  _over3m  := 0;
  _3mill   := 0;

  while not ptQuery.eof do
    begin
      _tipus := ptquery.fieldbyname('TIPUS').asString;
      _osszesen := ptquery.FieldByName('OSSZESEN').asInteger;

      if _tipus='V' then
        BEGIN
          _SUMVET := _SUMVET  + _osszesen;
          inc(_vetdb);
        end;
      if _tipus='E' then
        begin
         _sumelad := _sumelad +  _osszesen;
         inc(_eladdb);
        end;
      if _tipus='K' then
       begin
         _sumkonv := _sumkonv + _osszesen;
         inc(_konvdb);
       end;
      if (_tipus='V') or (_tipus='E') then
        begin


      if _osszesen>=3000000 then
        begin
          inc(_over3m);
          _3mill := _3mill + _osszesen;
        end;
        end;

      ptquery.next;
    end;
  ptquery.close;
  ptdbase.close;

  _pcs := 'INSERT INTO TRANZAKCIOK (PENZTAR,CEGBETU,VETEL,ELADAS,KONVERZIO,';
  _pcs := _pcs + 'UGYFDBVETELNEL,UGYFDBELADASNAL,UGYFDBKONVERZIONAL,';
  _PCS := _pcs + 'OVER3MILLDB,OVER3MILLIOFT)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_aktpenztar) + ',';
  _pcs := _pcs + chr(39) + _aktcegbetu + CHR(39)+ ',';
  _pcs := _pcs + inttostr(_sumvet) + ',';
  _pcs := _pcs + inttostr(_sumelad) + ',';
  _pcs := _pcs + inttostr(_sumkonv)+',';
  _pcs := _pcs + inttostr(_vetdb)+',';
  _pcs := _pcs + inttostr(_eladdb) + ',';
  _pcs := _pcs + inttostr(_konvdb) + ',';
  _pcs := _pcs + inttostr(_over3m) + ',';
  _pcs := _pcs + floattostr(_3mill) + ')';

  Tranzdbase.connected := true;
  if tranzTranz.intransaction then Tranztranz.commit;
  TranzTranz.startTransaction;
  with tranzquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  tranztranz.commit;
  tranzdbase.close;
end;















end.
