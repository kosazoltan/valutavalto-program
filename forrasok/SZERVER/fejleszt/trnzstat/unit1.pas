unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  Buttons, strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    VALTOTABLA: TIBTable;
    VALTOQUERY: TIBQuery;
    VALTODBASE: TIBDatabase;
    VALTOTRANZ: TIBTransaction;
    Memo1: TMemo;
    TRANZQUERY: TIBQuery;
    TRANZDBASE: TIBDatabase;
    tranztranz: TIBTransaction;
    EVTIZEDPANEL: TPanel;
    HONAPPANEL: TPanel;
    PENZTARPANEL: TPanel;

    procedure BitBtn1Click(Sender: TObject);

    function Nulele(_int: integer): string;
    function Ezertektar(_ert: integer): boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _mintaPath,_fdb,_aktpenztars,_aktpenztarfdb: string;
  _ibdb,_aktpenztar,_vdb,_edb,_kdb,_qq: integer;
  _srec: TSearchRec;
  _fdbnev: array[0..149] of string;
  _penztarszam: array[0..149] of integer;
  _aktevtized,_akthonap: integer;
  _farok,_bfTablaNev,_pcs,_tipus,_aktfdbPath: string;
  _sorveg: string = chr(13)+chr(10);


implementation

{$R *.dfm}

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _pcs := 'DELETE FROM TRANZAKCIOK';
  TRANZDBASE.Connected := True;
  if tranztranz.InTransaction then tranztranz.commit;
  tranztranz.StartTransaction;
  with tranzQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      ExecSql;
    end;
  Tranztranz.Commit;
  Tranzdbase.close;

  // ---------------------------------------------------------------------------

  _mintaPath := 'c:\receptor\database\v*.fdb';
  _ibdb := 0;

  if FindFirst(_mintaPath, faAnyFile, _srec) = 0 then
    begin
      repeat
        _fdb := _srec.Name;
        _aktpenztars := midstr(_fdb,2,length(_fdb)-5);
        _aktpenztar := strtoint(_aktpenztars);
        if not Ezertektar(_aktpenztar) then
          begin
            _fdbnev[_ibdb] := _fdb;
            _penztarszam[_ibdb] := _aktpenztar;
            inc(_ibdb);
          end;

      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  // ---------------------------------------------------------------------------

  _qq := 0;
  while _qq<_ibdb do
    begin
      _aktpenztarfdb := _fdbnev[_qq];
      _aktfdbPath := 'c:\receptor\database\' + _aktpenztarfdb;

      _aktpenztar := _penztarszam[_qq];
      PenztarPanel.caption := inttostr(_aktpenztar);
      PenztarPanel.repaint;

      Valtodbase.close;
      ValtoTabla.close;
      Valtodbase.DatabaseName := _aktfdbPath;

      // -----------------------------------------------------------------------

      _aktevtized := 9;
      _akthonap   := 1;
      _farok := nulele(_aktevtized)+nulele(_akthonap);

      while _farok<='1110' do
        begin
          EvtizedPanel.caption := '20' + nulele(_aktevtized);
          EvtizedPanel.repaint;

          HonapPanel.caption := inttostr(_akthonap);
          HonapPanel.Repaint;

          _BfTablaNev := 'BF'+ _FAROK;
          ValtoDbase.Connected := True;
          ValtoTabla.TableName := _bfTablanev;
          if not ValtoTabla.Exists then
            begin
              inc(_akthonap);
              if _akthonap>12 then
                begin
                  _akthonap := 1;
                  inc(_aktevtized);
                end;
              _farok := nulele(_aktevtized)+nulele(_akthonap);
              Continue;
            end;

          // -------------------------------------------------------------------

          _pcs := 'SELECT * FROM ' + _bfTablanev + _sorveg;
          _pcs := _pcs + 'WHERE (STORNO=1) AND ((TIPUS='+chr(39)+'V'+chr(39)+')';
          _pcs := _pcs + ' OR (TIPUS='+chr(39)+'E'+chr(39)+')';
          _pcs := _pcs + ' OR (TIPUS='+chr(39)+'K'+CHR(39)+'))';

          with ValtoQuery do
            begin
              Close;
              sql.Clear;
              sql.Add(_pcs);
              Open;
              First;
            end;

          _vdb := 0;
          _edb := 0;
          _kdb := 0;

          while not ValtoQuery.eof do
            begin
              _tipus := ValtoQuery.FieldByName('TIPUS').asstring;

              if _tipus='V' then inc(_vdb);
              if _tipus='E' then inc(_edb);
              if _tipus='K' then inc(_kdb);
          
              ValtoQuery.Next;
            end;
          ValtoQuery.Close;
          ValtoDbase.close;

          // -------------------------------------------------------------------

          _pcs := 'INSERT INTO TRANZAKCIOK (EV,HONAP,PENZTAR,VASARLO,ELADO,KONVERTALO)'+_sorveg;
          _pcs := _pcs + 'VALUES (20' + nulele(_aktevtized) + ',';
          _pcs := _pcs + inttostr(_akthonap)+',';
          _pcs := _pcs + inttostr(_aktpenztar)+',';
          _pcs := _Pcs + inttostr(_vdb)+','+inttostr(_edb)+',';
          _pcs := _pcs + inttostr(_kdb)+')';
          mEMO1.Lines.add(_pcs);
          TranzDbase.Connected := true;
          if tranztranz.InTransaction then tranztranz.Commit;
          Tranztranz.StartTransaction;
          with TranzQuery do
            begin
              Close;
              sql.Clear;
              sql.Add(_Pcs);
              ExecSql;
            end;
          Tranztranz.Commit;
          TranzDbase.close;

          // -------------------------------------------------------------------

          inc(_akthonap);

          if _akthonap>12 then
            begin
              _akthonap := 1;
              inc(_aktevtized);
            end;

          _farok := Nulele(_aktevtized)+nulele(_akthonap);
        end;
      inc(_qq);
    end;
  Showmessage('AZ ÖSSZES TRANZAKCIÓT LEGYÜJTÖTTEM !');
  Application.Terminate;
end;

function TForm1.Nulele(_int: integer): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

function TForm1.Ezertektar(_ert: integer): boolean;

begin
  result := false;
  if (_ert=10) or (_ert=20) or (_ert=40) or (_ert=50) then result := True;
  if (_ert=63) or (_ert=75) or (_ert=120) or (_ert=145) then result := True;
end;


end.
