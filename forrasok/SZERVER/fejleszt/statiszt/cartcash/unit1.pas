unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, IBTable,
  ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    PQUERY: TIBQuery;
    PDBASE: TIBDatabase;
    PTRANZ: TIBTransaction;
    GQUERY: TIBQuery;
    GDBASE: TIBDatabase;
    GTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    Panel1: TPanel;

    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Ugyfelazonositas;
    procedure Adatregisztralas;
    procedure Nullazo;
    procedure FormActivate(Sender: TObject);
    procedure DbUrites;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pt,_tetel: byte;
  _pcs,_fdbPath,_utbiz,_vnem1,_vnem2,_bizonylatszam,_datum: string;
  _ugyfeltipus,_ugyfelnev,_ugyfelcim,_pnev,_szulido,_szulhely: string;
  _anyjaneve,_allamp,_pcim,_okmtip,_azonosito,_tarthely,_jnev: string;
  _telhely,_okirat,_fotev,_kepvisnev,_kepvisbeo,_mbneve: string;
  _apcs,_cegbetu: string;
  _sorveg: string = chr(13)+chr(10);

  _cb: array[1..200] of string;

  _bjegy1,_bjegy2,_ugyfelszam,_RECNO,_mbszama: integer;
  _ufdbPath,_ppcs: string;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  _pt := 151;
  while _pt<=170 do
    begin
      _fdbPath := 'c:\cartcash\database\v'+inttostr(_pt)+'.fdb';

      if not FileExists(_fdbPath) then
        begin
          inc(_pt);
          continue;
        end;

      Vdbase.close;
      Vtabla.close;
      Vdbase.DatabaseName := _fdbPath;
      vtabla.TableName := 'BF1710';
      vDBASE.Connected := True;

      if not vtabla.Exists then
        begin
          Vdbase.close;
          inc(_pt);
          continue;
        end;

      panel1.Caption := _fdbPath;
      panel1.repaint;

      _pcs := 'SELECT * FROM BF1710' + _sorveg;
      _pcs := _pcs + 'WHERE (STORNO=1) and (FIZETENDO>=300000)';

      _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
      _pcs := _pcs +'FROM BF1710 FEJ JOIN BT1710 TET'+_sorveg;
      _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;
      _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND (OSSZESEN>=300000)';
      _pcs := _Pcs + ' AND ((TIPUS='+CHR(39)+'V'+CHR(39)+') OR (';
      _pcs := _pcs + 'TIPUS='+chr(39)+'E'+CHR(39)+'))';

      with Vquery do
        begin
          Close;
          sql.Clear;
          sql.add(_pcs);
          Open;
        end;

      _utbiz := 'xxxxxx';
      while not VQuery.eof do
        begin


          _bizonylatszam := VQuery.FieldByNAme('BIZONYLATSZAM').asString;
          if _BIZONYLATSZAM=_utbiz then
            begin
              Vquery.next;
              Continue;
            end;

          Nullazo;

          _utbiz := _bizonylatszam;
          with VQuery do
            begin

              _DATUM := FieldByNAme('DATUM').asString;
              _ugyfelszam := FieldByNAme('UGYFELSZAM').asInteger;
              _ugyfeltipus := FieldByNAme('UGYFELTIPUS').asString;
              _ugyfelnev := trim(FieldByNAme('UGYFELNEV').asString);
              _ugyfelcim := trim(FieldByNAme('UGYFELCIM').AsString);
              _tetel := FieldByNAme('TETEL').asInteger;
              _vnem1 := FieldByNAme('VALUTANEM').asString;
              _bjegy1 := FieldByNAme('BANKJEGY').asInteger;
            end;
          if _tetel>1 then
            begin
              VQuery.next;
              _vnem2 := VQuery.FieldByNAme('VALUTANEM').asString;
              _bjegy2 := VQuery.FieldByNAme('BANKJEGY').asInteger;
            end;

         Ugyfelazonositas;
         AdatRegisztralas;

          VQuery.next;
        end;
      Vquery.Close;
      Vdbase.close;

      inc(_pt);
    end;
  Showmessage('KESZEN VAN');
end;


procedure TForm1.Ugyfelazonositas;

begin
  if _ugyfelszam=0 then exit;

  _ufdbPath := 'c:\4\P' + inttostr(_pt)+'.fdb';
  if not fileExists(_ufdbPath) then exit;
  Pdbase.close;
  Pdbase.DatabaseName := _ufdbPath;

  Pdbase.connected := true;
  if _ugyfeltipus='N' then
    begin
      _ppcs := 'SELECT * FROM UGYFEL' + _sorveg;
      _ppcs := _ppcs + 'WHERE UGYFELSZAM=' + inttostr(_ugyfelszam);

      with Pquery do
        begin
          Close;
          sql.clear;
          sql.add(_ppcs);
          Open;
          _recno := recno;
        end;
      if _recno=0 then
        begin
          Pquery.close;
          Pdbase.close;
          exit;
        end;
      with Pquery do
        begin
          _pnev := trim(FieldByNAme('NEV').asString);
          _anyjaneve := trim(FieldByNAme('ANYJANEVE').asString);
          _szulhely := trim(FieldByNAme('SZULETESIHELY').asString);
          _szulido := trim(FieldByNAme('SZULETESIIDO').asstring);
          _allamp := trim(FieldByNAme('ALLAMPOLGAR').asString);
          _pcim := trim(FieldByNAme('LAKCIM').asString);
          _okmtip := trim(FieldByNAme('OKMANYTIPUS').asstring);
          _azonosito := trim(fIELDbYnaME('AZONOSITO').asstring);
          _tarthely := trim(FieldByNAme('TARTOZKODASIHELY').asstring);
          Close;
        end;
      Pdbase.close;

      if _pnev<>'' then _ugyfelnev := _pnev;
      if _pcim<>'' then _ugyfelcim := _pcim;
      exit;
    end;

  _ppcs := 'SELECT * FROM JOGISZEMELY' + _sorveg;
  _ppcs := _ppcs + 'WHERE UGYFELSZAM=' + inttostr(_ugyfelszam);

  with Pquery do
    begin
      Close;
      sql.clear;
      sql.add(_ppcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Pquery.close;
      Pdbase.close;
      exit;
    end;

  with Pquery do
    begin
      _ugyfelnev := trim(FieldByNAme('JOGISZEMELYNEV').asString);
      _telhely := trim(FieldByNAme('TELEPHELYCIM').asString);
      _okirat := trim(FieldByNAme('OKIRATSZAM').asString);
      _fotev := trim(FieldByNAme('FOTEVEKENYSEG').asstring);
      _kepvisnev := trim(FieldByNAme('KEPVISELONEV').asString);
      _kepvisbeo := trim(FieldByNAme('KEPVISBEO').asstring);
      _mbneve := trim(FieldByNAme('MEGBIZOTTNEVE').asString);
      _mbszama := fieldByNAme('MEGBIZOTTSZAMA').asInteger;
      close;
    end;

  if _mbszama=0 then
    begin
      pdbase.close;
      exit;
    end;
  _ppcs := 'SELECT * FROM UGYFEL' + _sorveg;
  _ppcs := _ppcs + 'WHERE UGYFELSZAM=' + inttostr(_mbszama);
  with pquery do
    begin
      Close;
      sql.clear;
      sql.add(_ppcs);
      Open;
      _recno := recno;
    end;

  if _recno= 0 then
    begin
      pquery.close;
      pdbase.close;
      exit;
    end;
  with Pquery do
    begin
      _mbneve := trim(FieldByNAme('NEV').asString);
      _anyjaneve := trim(FieldByNAme('ANYJANEVE').asString);
      _szulhely := trim(FieldByNAme('SZULETESIHELY').asString);
      _szulido := trim(FieldByNAme('SZULETESIIDO').asstring);
      _allamp := trim(FieldByNAme('ALLAMPOLGAR').asString);
      _pcim := trim(FieldByNAme('LAKCIM').asString);
      _okmtip := trim(FieldByNAme('OKMANYTIPUS').asstring);
      _azonosito := trim(fIELDbYnaME('AZONOSITO').asstring);
      _tarthely := trim(FieldByNAme('TARTOZKODASIHELY').asstring);
      Close;
    end;
  Pdbase.close;
end;

procedure TForm1.Adatregisztralas;

var _iras: textfile;

begin
  Assignfile(_iras,'c:\4\lastcmd.txt');
  rewrite(_iras);

  _cegbetu := 'Z';

  _apcs := 'INSERT INTO CCASH1710 (NEV,PENZTAR,CEGBETU,DATUM,VALNEM1,BANKJEGY1,';
  _apcs := _apcs + 'VALNEM2,BANKJEGY2,LAKCIM,ALLAMPOLGAR,SZULIDO,SZULHELY,';
  _APCS := _apcs + 'TELEPHELY,OKMANYTIPUS,AZONOSITO,TARTHELY,OKIRATSZAM,';
  _apcs := _apcs + 'FOTEVEKENYSEG,KEPVISNEV,ANYJANEVE,MEGBIZOTTNEV,KEPVISBEO)'+_sorveg;


  _apcs := _apcs + 'VALUES ('+CHR(39)+_ugyfelnev+chr(39)+',';
  _apcs := _apcs + inttostr(_pt) + ',';
  _apcs := _apcs + chr(39) + _cegbetu + chr(39) + ',';
  _apcs := _apcs + chr(39) + _datum + chr(39) + ',';
  _apcs := _apcs + chr(39) + _vnem1 + chr(39) + ',';
  _apcs := _apcs + inttostr(_bjegy1) + ',';
  _apcs := _apcs + chr(39) + _vNem2 + chr(39) + ',';
  _apcs := _apcs + inttostr(_bjegy2) + ',';
  _apcs := _apcs + chr(39) + _ugyfelcim + chr(39) + ',';
  _apcs := _apcs + chr(39) + _allamp + chr(39) + ',';
  _apcs := _apcs + chr(39) + _szulido + chr(39) + ',';
  _apcs := _apcs + chr(39) + _szulhely + chr(39) + ',';
  _apcs := _apcs + chr(39) + _telhely + chr(39) + ',';
  _apcs := _apcs + chr(39) + _okmtip + chr(39) + ',';
  _apcs := _apcs + chr(39) + _azonosito + chr(39) + ',';
  _apcs := _apcs + chr(39) + _tarthely + chr(39) + ',';
  _apcs := _apcs + chr(39) + _okirat + chr(39) + ',';
  _apcs := _apcs + chr(39) + _fotev + chr(39) + ',';
  _apcs := _apcs + chr(39) + _kepvisnev + chr(39) + ',';
  _apcs := _apcs + chr(39) + _anyjaneve + chr(39) + ',';
  _apcs := _apcs + chr(39) + _mbneve + chr(39) + ',';
  _apcs := _apcs + chr(39) + _kepvisbeo + chr(39) + ')';

  writeLn(_iras,_apcs);
  Closefile(_iras);

  gdbase.Connected := true;
  if gtranz.InTransaction then Gtranz.commit;
  Gtranz.StartTransaction;

  with Gquery do
    begin
      Close;
      sql.clear;
      sql.add(_apcs);
      Execsql;
    end;
  Gtranz.commit;
  Gdbase.close;

end;


PROCEDURE TForm1.dbUrites;

begin
  _apcs := 'DELETE FROM CCASH1710';
  gdbase.Connected := true;
  if gtranz.InTransaction then Gtranz.commit;
  Gtranz.StartTransaction;

  with Gquery do
    begin
      Close;
      sql.clear;
      sql.add(_apcs);
      Execsql;
    end;
  Gtranz.commit;
  Gdbase.close;
END;



procedure TForm1.Nullazo;

begin
   _ugyfelnev := '';
  _vnem1 := '';
  _bjegy1 := 0;
  _vnem2 := '';
  _bjegy2 := 0;
  _ugyfelcim := '';
  _allamp := '';
  _szulido := '';
  _szulhely := '';
  _telhely := '';
  _okmtip := '';
  _azonosito := '';
  _tarthely := '';
  _okirat := '';
  _fotev := '';
  _kepvisnev := '';
  _anyjaneve := '';
  _mbneve := '';
  _kepvisbeo := '';
end;

procedure TForm1.FormActivate(Sender: TObject);

var _uzlet: byte;

begin
  dbUrites;
end;

end.
