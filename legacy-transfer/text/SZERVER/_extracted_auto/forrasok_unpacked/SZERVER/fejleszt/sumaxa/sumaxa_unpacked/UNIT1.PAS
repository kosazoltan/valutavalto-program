unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    IBTABLA: TIBTable;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    SUMTRANZ: TIBTransaction;
    SUMDBASE: TIBDatabase;
    SUMQUERY: TIBQuery;
    Panel1: TPanel;

    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SumParancs(_ukaz: string);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _cc,_aktpenztar,_mozgas,_tipus,_axadarab,_ertek,_penztar: integer;
  _srec: TSearchRec;
  _minta,_pcs,_aktaxanev,_aktaxapath,_idkod,_datum: string;
  _axafile: array[0..149] of string;
  _sorveg: string = chr(13)+chr(10);

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  _pcs := 'DELETE FROM FORGALOM';
  SumParancs(_pcs);

  _pcs := 'SELECT * FROM FORGALOM' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR,DATUM';
  SumDbase.Connected := true;
  with Sumquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  // --------------------------------------------------

  _cc := 0;
  _minta := 'c:\receptor\database\axa*.fdb';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _axafile[_cc] := _srec.Name;
        inc(_cc);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
  _Axadarab := _cc;

  // -----------------------------------------------

  _cc := 0;
  while _cc<_Axadarab do
    begin
      _aktAxaNev  := _axafile[_cc];
      Panel1.Caption := _aktaxanev;
      Panel1.Repaint;


      _aktaxaPath := 'c:\receptor\database\' + _aktaxanev;
      _aktpenztar := strtoint(midstr(_aktaxanev,4,3));

      ibdbase.close;
      ibdbase.DatabaseName := _aktaxaPath;
      ibdbase.Connected := True;
      with ibquery do
        begin
          Close;
          Sql.clear;
          sql.add('SELECT * FROM FORGALOM');
          Open;
          First;
        end;

      while not Ibquery.Eof do
        begin
          _idkod := Ibquery.fieldByNAme('IDKOD').asString;
          _datum := Ibquery.FieldByNAme('DATUM').asString;
          _mozgas:= ibquery.FieldByName('MOZGAS').asInteger;
          _tipus := ibquery.FieldByName('TIPUS').asInteger;
          _ertek := ibquery.fieldByName('ERTEK').asInteger;

          _pcs := 'INSERT INTO FORGALOM (PENZTAR,IDKOD,DATUM,MOZGAS,TIPUS,ERTEK)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_aktpenztar) + ',';
          _pcs := _pcs + chr(39) + _idkod + chr(39) + ',';
          _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
          _pcs := _pcs + inttostr(_mozgas) + ',';
          _pcs := _pcs + inttostr(_tipus) + ',';
          _pcs := _pcs + inttostr(_ertek)+')';

          SumParancs(_pcs);
          ibQuery.next;
        end;
      ibquery.close;
      ibdbase.close;
      inc(_cc);
    end;
end;


procedure TForm1.SumParancs(_ukaz: string);

begin
  Sumdbase.connected := true;
  if sumtranz.InTransaction then Sumtranz.Commit;
  Sumtranz.StartTransaction;
  with Sumquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  sumtranz.Commit;
  sumdbase.close;
end;


end.
