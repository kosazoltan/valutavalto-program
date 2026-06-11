unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBQuery, IBDatabase, DB, IBCustomDataSet, IBTable,
  strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    READTABLA: TIBTable;
    READDBASE: TIBDatabase;
    READTRANZ: TIBTransaction;
    WRITEQUERY: TIBQuery;
    WRITEDBASE: TIBDatabase;
    WRITETRANZ: TIBTransaction;
    writetabla: TIBTable;
    Panel1: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    PROCEDURE AxaParancs(_ukaz: string);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _sorveg: string = chr(13)+chr(10);
  _pcs,_datum,_writepath,_honaps,_tnev: string;
  _utpenztar,_penztar: integer;
  _csnyito,_cszaro,_ftnyito,_ftzaro,_csad,_cskap,_ftad,_ftkap: integer;
  _elad,_eladft,_back,_backft: integer;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin

  _utpenztar := 0;
  readdbase.Connected := true;
  readTabla.open;
  readtabla.First;
  while not readtabla.Eof do
    begin
      _penztar := Readtabla.fieldbyname('PENZTAR').asInteger;
      _datum := Readtabla.fieldbyname('DATUM').asString;
      _csnyito := Readtabla.fieldbyname('CSOMAGNYITO').asInteger;
      _ftnyito := Readtabla.fieldByName('FORINTNYITO').asInteger;
      _cszaro := Readtabla.fieldbyname('CSOMAGZARO').asInteger;
      _ftzaro := ReadTabla.fieldByName('FORINTZARO').asInteger;
      _cskap := Readtabla.fieldbyname('CSOMAGATVETEL').asInteger;
      _csad := Readtabla.fieldbyname('CSOMAGATADAS').asInteger;
      _ftad := Readtabla.fieldbyname('FORINTATADAS').asInteger;
      _ftkap := Readtabla.fieldbyname('FORINTATVETEL').asInteger;
      _elad := readtabla.fieldbyname('ERTEKESITES').asInteger;
      _eladft := readtabla.fieldbyname('ERTEKFT').asInteger;
      _back := readtabla.fieldbyname('VISSZAVALTAS').asInteger;
      _backft := Readtabla.fieldbyname('VISSZAFT').asInteger;


      Panel1.Caption := inttostr(_penztar)+'.'+_datum;
      Panel1.repaint;

      _writePath := 'c:\receptor\database\v' + INTTOSTR(_penztar)+'.FDB';
      if not FileExists(_writePath) then
        begin
          Readtabla.next;
          continue;
        end;

      _honapS := midstr(_datum,6,2);
      _tnev := 'AXAD14'+_HONAPS;

      writedbase.Close;
      writetabla.close;
      writedbase.DatabaseName := _writePath;
      
      if _penztar>_utpenztar then
        begin
          _utpenztar := _penztar;
          _pcs := 'DELETE FROM AXAD1407';
          Axaparancs(_pcs);
          _pcs := 'DELETE FROM AXAD1408';
          Axaparancs(_pcs);
          _pcs := 'DELETE FROM AXAD1409';
          Axaparancs(_pcs);
        end;


      writedbase.Connected := true;
      writetabla.TableName := _TNEV;
      if writetabla.Exists then
        begin

          _pcs := 'INSERT INTO ' + _TNEV + ' (DATUM,CSOMAGNYITO,CSOMAGZARO,';
          _pcs := _pcs + 'FORINTNYITO,FORINTZARO,CSOMAGATVETEL,CSOMAGATADAS,';
          _pcs := _pcs + 'FORINTATVETEL,FORINTATADAS,ERTEKESITES,ERTEKFT,';
          _pcs := _pcs + 'VISSZAVALTAS,VISSZAFT)'+_SORVEG;
          _pcs := _pcs + 'VALUES (' + chr(39)+_datum+chr(39)+',';
          _pcs := _pcs + inttostr(_csnyito) + ',';
          _pcs := _pcs + inttostr(_cszaro) + ',';
          _pcs := _pcs + inttostr(_ftnyito)+',';
          _pcs := _pcs + inttostr(_ftzaro)+',';
          _pcs := _pcs + inttostr(_cskap)+',';
          _pcs := _pcs + inttostr(_csad) + ',';
          _pcs := _pcs + inttostr(_ftkap) + ',';
          _pcs := _pcs + inttostr(_ftad) + ',';
          _pcs := _pcs + inttostr(_elad)+',';
          _pcs := _pcs + inttostr(_eladft) + ',';
          _pcs := _pcs + inttostr(_back)+',';
          _pcs := _pcs + inttostr(_backft) + ')';
          AxaParancs(_pcs);
        end;
      writedbase.close;
      Readtabla.next;
    end;
  readtabla.close;
  readdbase.close;
  ShowMessAge('KESZEN VAN');
end;


PROCEDURE TForm1.AxaParancs(_ukaz: string);

begin
  writedbase.close;
  writeDbase.Connected := true;
  if writetranz.InTransaction then writetranz.Commit;
  writeTranz.StartTransaction;
  with writequery do
    begin
      Close;
      sql.clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  Writetranz.Commit;
  writedbase.close;
end;

end.
