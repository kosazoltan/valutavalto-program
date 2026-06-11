unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBTable, IBCustomDataSet, IBQuery,
  ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    FORGQUERY: TIBQuery;
    FORGTABLA: TIBTable;
    FORGDBASE: TIBDatabase;
    FORGTRANZ: TIBTransaction;
    SUMQUERY: TIBQuery;
    SUMDBASE: TIBDatabase;
    SUMTRANZ: TIBTransaction;
    Panel1: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    PROCEDURE Sumparancs(_ukaz: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _penztar,_recno,_cskap,_csad,_ftkap,_ftad,_ertek,_elad,_eladft: integer;
  _back,_backft,_mozgas,_tipus: integer;
  _datum,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _ujrekord: boolean;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  _pcs := 'DELETE FROM SUMFORG';
  Sumparancs(_pcs);

  forgdbase.Connected := true;
  Forgtabla.open;
  forgtabla.first;
  while not forgtabla.Eof do
    begin
      _penztar := Forgtabla.fieldByName('PENZTAR').asInteger;
      _datum := Forgtabla.FieldByName('DATUM').asString;
      _ertek := ForgTabla.FieldByName('ERTEK').asInteger;
      _MOZGAS := ForgTabla.fieldByName('MOZGAS').asInteger;
    //  _tipus := ForgTabla.FieldByname('TIPUS').asInteger;

      Panel1.Caption := inttostr(_penztar)+':' + _datum;
      Panel1.Repaint;

      _pcs := 'SELECT * FROM SUMFORG' + _SORVEG;
      _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_datum+chr(39);
      _pcs := _pcs + ') and (PENZTAR='+inttostr(_penztar)+')';

      Sumdbase.Connected := True;
      with Sumquery do
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
          _cskap := Sumquery.fieldbyname('CSOMAGATVETEL').asInteger;
          _csad  := SumQuery.FieldByName('CSOMAGATADAS').asInteger;
          _ftkap := Sumquery.FieldByName('FORINTATVETEL').asInteger;
          _ftad  := Sumquery.FieldByName('FORINTATADAS').asInteger;
          _elad  := Sumquery.FieldByName('ERTEKESITES').asInteger;
          _eladft:= Sumquery.FieldByName('ERTEKFT').asInteger;
          _back  := Sumquery.FieldByName('VISSZAVALTAS').asInteger;
          _backft:= Sumquery.FieldByName('VISSZAFT').asInteger;
          _ujrekord := False;
        end else
        begin
          _cskap := 0;
          _csad  := 0;
          _ftkap := 0;
          _ftad  := 0;
          _elad  := 0;
          _eladft:= 0;
          _back  := 0;
          _backft:= 0;
          _ujrekord := True;
        end;

      Sumquery.close;
      Sumdbase.close;

      case _mozgas of
        10: inc(_cskap);
        20: inc(_csad);
        30: _ftkap := _ftkap + _ertek;
        40: _ftad := _ftad + _ertek;

        21: begin
              inc(_elad);
              _eladft := _eladft + _ertek;
            end;

        11: begin
              inc(_back);
              _backft := _backft + _ertek;
            end;
      end;

      IF _UJREKORD THEN
        begin
          _pcs := 'INSERT INTO SUMFORG (PENZTAR,DATUM,ERTEKESITES,ERTEKFT,';
          _pcs := _pcs + 'VISSZAVALTAS,VISSZAFT,CSOMAGATVETEL,CSOMAGATADAS,';
          _pcs := _pcs + 'FORINTATVETEL,FORINTATADAS)' + _sorveg;
          _pcs := _pcs + 'VALUES ('+inttostr(_penztar)+',';
          _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
          _pcs := _pcs + inttostr(_elad) + ',';
          _pcs := _pcs + inttostr(_eladft) + ',';
          _pcs := _pcs + inttostr(_back) + ',';
          _pcs := _pcs + inttostr(_backft) + ',';
          _pcs := _pcs + inttostr(_cskap) + ',';
          _pcs := _pcs + inttostr(_csad) + ',';
          _pcs := _pcs + inttostr(_ftkap) + ',';
          _pcs := _pcs + inttostr(_ftad) + ')';
        end else
        begin
          _pcs := 'UPDATE SUMFORG SET ERTEKESITES='+inttostr(_elad)+',';
          _pcs := _pcs + 'ERTEKFT='+inttostr(_eladft)+',';
          _pcs := _pcs + 'VISSZAVALTAS=' + inttostr(_back) + ',';
          _pcs := _pcs + 'VISSZAFT='+inttostr(_backft) + ',';
          _pcs := _pcs + 'CSOMAGATVETEL='+inttostr(_cskap)+',';
          _pcs := _pcs + 'CSOMAGATADAS=' + inttostr(_csad) + ',';
          _pcs := _Pcs + 'FORINTATVETEL=' +inttostr(_ftkap) + ',';
          _pcs := _pcs + 'FORINTATADAS=' + inttostr(_ftad)+_sorveg;
          _pcs := _pcs + 'WHERE (PENZTAR='+inttostr(_penztar)+') AND (DATUM=';
          _pcs := _pcs + chr(39)+_datum+chr(39)+')';
        end;
      Sumparancs(_pcs);

      Forgtabla.next;
    end;
  ForgTabla.Close;
  Forgdbase.close;
  ShOwMessage('KESZEN VAN');
end;


PROCEDURE TForm1.Sumparancs(_ukaz: string);

begin
  Sumdbase.connected := true;
  if Sumtranz.InTransaction then sumtranz.commit;
  sumtranz.StartTransaction;
  with Sumquery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  Sumtranz.Commit;
  sumdbase.close;
end;

end.
