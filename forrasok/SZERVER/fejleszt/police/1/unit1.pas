unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  IBTable;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    POLQUERY: TIBQuery;
    POLDBASE: TIBDatabase;
    POLTRANZ: TIBTransaction;
    UFQUERY: TIBQuery;
    UFDBASE: TIBDatabase;
    UFTRANZ: TIBTransaction;
    Panel1: TPanel;
    Panel2: TPanel;
    BTETQuery: TIBQuery;
    BTETDBASE: TIBDatabase;
    BTETTRANZ: TIBTransaction;
    BtetTABLA: TIBTable;
    BFEJQUERY: TIBQuery;
    BFEJDBASE: TIBDatabase;
    BFEJTRANZ: TIBTransaction;
    IRODAQUERY: TIBQuery;
    IRODADBASE: TIBDatabase;
    IRODATRANZ: TIBTransaction;

    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);

    procedure PoliceBejegyzes;
    procedure Polparancs(_ukaz: string);

    function Ezertektar(_e: byte): boolean;
    procedure FormActivate(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _knaps,_fdbPath,_bf,_bt,_pcs,_szulhely,_szulido,_anyja,_azonosito: string;
  _sorveg: string = chr(13)+chr(10);
  _vanugyfel: boolean;
  _recno,_bankjegy,_ftertek: integer;
  _ptarnev: array[1..150] of string;


  _ugyfelnev,_datum,_lakcim,_ido,_bizonylat: string;
  _ugyfelszam,_storno: word;

  _honap,_pt: byte;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  APPLICATION.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin

  PoLParancs('DELETE FROM POLICE');

  _knaps := '2016.04.18';

  _PT := 3;
  while _pt<=150 do
    begin
      if ezertektar(_pt) then
        begin
          inc(_pt);
          continue;
        end;

      _fdbpath := 'c:\receptor\database\v' + inttostr(_pt)+'.fdb';
      Panel1.Caption := _fdbpath;
      Panel1.repaint;

      if not fileExists(_fdbPath) then
        begin
          inc(_pt);
          continue;
        end;

      Bfejdbase.close;
      Bfejdbase.DatabaseName := _fdbPath;

      BTetdbase.close;
      BTetdbase.DatabaseName := _fdbPath;

      Ufdbase.close;
      Ufdbase.DatabaseName := _fdbPath;

      _honap :=4;
      while _honap<=6 do
        begin
          Panel2.Caption := inttostr(_honap)+'. hónap';
          Panel2.repaint;

          _bf := 'BF160'+chr(48+_honap);
          _bt := 'BT160'+chr(48+_honap);

          // -------------------------------------------------------------------

          Btettabla.close;

          BtetDbase.Connected := true;
          Btettabla.TableName := _bt;
          if not BtetTabla.Exists then
            begin
              Btetdbase.close;
              inc(_honap);
              Continue;
            end;

          _pcs := 'SELECT * FROM ' + _bt + _sorveg;
          _pcs := _pcs + 'WHERE (VALUTANEM='+chr(39)+'EUR'+chr(39)+')';
          _pcs := _pcs + ' AND (FORINTERTEK>=500000) AND (FORINTERTEK<=800000)';
          _pcs := _pcs + ' AND (BIZONYLATSZAM LIKE '+chr(39)+'V%'+chr(39)+')';

          with BtetQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              First;
              _recno := recno;
            end;

          if _recno=0 then
            begin
              BtetQuery.close;
              Btetdbase.close;
              inc(_honap);
              continue;
            end;

          // -------------------------------------------------------------------

          while not Btetquery.Eof do
            begin
              _storno    := BtetQuery.FieldByName('STORNO').asInteger;
              _bizonylat := BtetQuery.FieldByNAme('BIZONYLATSZAM').asString;
              _bankjegy  := BtetQuery.FieldByNAme('BANKJEGY').AsInteger;
              _ftertek   := BtetQuery.FieldByName('FORINTERTEK').asInteger;

              // ------------------

              if _storno=1 then
                begin
                  _pcs := 'SELECT * FROM ' + _BF + _sorveg;
                  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylat+chr(39);

                  // ------------------------------------------

                  Bfejdbase.Connected := true;
                  with BFejQuery do
                    begin
                      close;
                      sql.clear;
                      sql.add(_pcs);
                      Open;
                      _datum := FieldByName('DATUM').asString;
                      _ido   := FieldByName('IDO').asString;
                      _ugyfelszam := FieldByNAme('UGYFELSZAM').asInteger;
                      Close;
                    end;

                  Bfejdbase.close;

                  // -------------------------------------------

                  _pcs := 'SELECT * FROM UGYFELEK' + _sorveg;
                  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

                  Ufdbase.Connected := true;
                  with Ufquery do
                    begin
                      Close;
                      sql.clear;
                      sql.add(_pcs);
                      Open;
                      _recno := recno;
                    end;

                  if _recno>0 then
                    begin
                      _UGYFELNEV := TRIM(Ufquery.FieldByname('NEV').AsString);
                      _anyja     := trim(Ufquery.fieldbyName('ANYJANEVE').AsString);
                      _szulido   := Ufquery.FieldByName('SZULETESIIDO').asString;
                      _szulhely  := trim(Ufquery.FieldByName('SZULETESIHELY').AsString);
                      _azonosito := trim(UFquery.fieldbyname('AZONOSITO').AsString);
                      _lakcim    := trim(UFQuery.FieldByName('LAKCIM').AsString);
                      PoliceBejegyzes;
                    end;
                  Ufquery.close;
                  Ufdbase.close;
                end;
              Btetquery.next;
            end;

          BtetQuery.close;
          Btetdbase.close;
          inc(_honap);
        end;
      inc(_pt);
    end;
  ShowMessage('LEVÁLOGATVA !!!!');
end;





function TForm1.Ezertektar(_e: byte): boolean;

begin
  result := False;
  if (_e=10) or (_e=20) or (_e=40) or (_e=50) then
    begin
      result := true;
      exit;
    end;

  if (_e=63) or (_e=75) or (_e=120) or (_e=145) then
    begin
      result := True;
      exit;
    end;
end;


procedure TForm1.Policebejegyzes;

var _aktptnev: string;

begin

  _aktptnev := _ptarnev[_pt];


  _pcs := 'INSERT INTO POLICE (PENZTAR,PENZTARNEV,DATUM,IDO,BANKJEGY,FTERTEK,';
  _pcs := _pcs + 'UGYFELNEV,LAKCIM,ANYJANEVE,SZULIDO,SZULHELY,AZONOSITO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_pt) + ',';
  _pcs := _pcs + chr(39) + _aktptnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _DATUM +chr(39)+',';
  _pcs := _pcs + chr(39) + _ido + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + inttostr(_ftertek) + ',';
  _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _anyja + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _azonosito + chr(39) + ')';

  PolParancs(_pcs);
end;



procedure TForm1.PolParancs(_ukaz: string);


begin
  Poldbase.connected := true;
  if poltranz.intransaction then Poltranz.commit;
  poltranz.StartTransaction;
  with Polquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Poltranz.commit;
  Poldbase.close;
end;






procedure TForm1.FormActivate(Sender: TObject);

var _uzlet: byte;
    _ptnev: string;

begin
  irodadbase.Connected := true;
  with IrodaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK');
      oPEN;
    end;
  while not Irodaquery.Eof do
    begin
      _uzlet := Irodaquery.fieldByName('UZLET').asInteger;
      _ptnev := trim(Irodaquery.FieldByNAme('KESZLETNEV').asString);

      _ptarnev[_uzlet] := _ptnev;
      Irodaquery.next;
    end;
  Irodaquery.close;
  irodadbase.close;
end;


end.
