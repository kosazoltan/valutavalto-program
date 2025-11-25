unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, DateUtils,
  Strutils, StdCtrls, ComCtrls, IBTable, COMOBJ;

type
  TSTORNOBIZONYLATOK = class(TForm)
    INDITOTIMER: TTimer;
    KILEPOTIMER: TTimer;
    STORNOFEJDBASE: TIBDatabase;
    STORNOFEJTRANZ: TIBTransaction;
    STORNOFEJQUERY: TIBQuery;
    STORNOTETELTRANZ: TIBTransaction;
    STORNOTETELDBASE: TIBDatabase;
    STORNOTETELQUERY: TIBQuery;
    CSIK: TProgressBar;
    Label1: TLabel;
    BLOKKDBASE: TIBDatabase;
    BLOkKTRANZ: TIBTransaction;
    BLOKKTABLA: TIBTable;
    BLOKKQUERY: TIBQuery;
    DAYBOOKDBASE: TIBDatabase;
    daybooktranz: TIBTransaction;
    DAYBOOKQUERY: TIBQuery;
    IRODADBASE: TIBDatabase;
    IRODATRANZ: TIBTransaction;
    IRODAQUERY: TIBQuery;
     procedure INDITOTIMERTimer(Sender: TObject);
   
    procedure Tetelfeliras;

    function GetpTarNev(_isz: integer): string;
    function Kieg(_szo: string;_hh: integer): string;
    function ElokiegFormat(_forint: integer):string;

    procedure KILEPOTIMERTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Excelcsinalo;
    function Dekodol(_kj: string):string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  STORNOBIZONYLATOK: TSTORNOBIZONYLATOK;
   _tesztnap,_munkad: TDateTime;
 
  _tegnaps,_fejtablanev,_tettablanev: string;
  _cc,_tnap,_stornoDarab,_irodaszam: integer;

  _bizonylatSzam,_stornoIndok,_tBizSzam: string;
  _body,_dbLine,_spline: string;
  _forintertek,_utiroda: integer;
  _elso: boolean;

  _ptdb,_siker,_siker2,_xsor: integer;
  _stornopath,_oribizonylat: string;

  _excelTabla,_sajatexcel,_range: variant;




implementation

uses Unit1;

{$R *.dfm}


procedure TStornoBizonylatok.FormActivate(Sender: TObject);
begin
  Top := 10;
  Left := 5;
  Height := 90;
  Csik.Position := 0;
  Color := $FFFFB0;
  InditoTimer.Enabled := true;
end;


procedure TStornoBizonylatok.INDITOTIMERTimer(Sender: TObject);

begin
  InditoTimer.Enabled := False;
  Form1.StatusBeolvaso;

  _KODjelszo := Dekodol(trim(_kodjelszo));
  _munkad := strtodate(_munkanap);

  _farok := midstr(_munkanap,3,2)+midstr(_munkanap,6,2);
  _aktev := yearof(_munkad);
  _aktho := monthof(_munkad);
 
  // -------------------------------------------------------------------

  Form1.MemoTabla.Lines.add('STORNOFEJTÁBLA KIÜRITÉSE');

  StornofejDbase.Connected := true;
  if StornoFejTranz.InTransaction then StornoFejTranz.Commit;
  StornofejTranz.StartTransaction;

  _pcs := 'DELETE FROM STORNOFEJ';
  with StornoFejQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  StornofejTranz.Commit;
  StornoFejDbase.close;

  // ---------------------------------------------------------------------------

  StornoFejDbase.Connected := true;
  StornoFejTranz.StartTransaction;

  // ---------------------------------------------------------------------------

  Form1.MemotABLA.Lines.add('STORNOTÉTELTÁBLA KIÜRITÉSE');

  StornoTetelDbase.Connected := true;
  if StornoTetelTranz.InTransaction then StornoTetelTranz.Commit;
  StornoTetelTranz.StartTransaction;

  _pcs := 'DELETE FROM STORNOTETEL';
  with StornoTetelQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  StornoTetelTranz.Commit;
  stornoTetelDbase.Close;

  // ---------------------------------------------------------------------------

  Stornoteteldbase.Connected := True;
  StornoTetelTranz.StartTransaction;

  // --------------------------------------------------------------------

  _fejTablaNev := 'BF' + _farok;
  _tetTablaNev := 'BT' + _farok;

  Form1.Memotabla.Lines.add('AZ EGYES PÉNZTÁRAK BEOLVASÁSA');
  Csik.Max := _irodaDarab;
  _qq := 1;

  while _qq<=_irodaDarab do
    begin
      Csik.Position := _qq;
      _aktPenztarSzam := _uzletszam[_qq];
      _AKTgdbPath := 'c:\receptor\database\v' + inttostr(_aktPenztarSzam)+'.GDB';
      with BlokkDbase do
        begin
          Close;
          DatabaseName := _aktgdbpath;
          Connected := True;
        end;
      if BlokkTranz.InTransaction then Blokktranz.Commit;

      Blokktabla.close;
      Blokktabla.TableName := _fejtablanev;
      if not Blokktabla.Exists then
        begin
          inc(_qq);
          Continue;
        end;

      Blokktabla.close;
      Blokktabla.TableName := _tettablanev;
      if not Blokktabla.Exists then
        begin
          inc(_qq);
          Continue;
        end;

      _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
      _pcs := _pcs +'FROM '+_fejtablanev+' FEJ JOIN '+_tettablanev+' TET'+_sorveg;
      _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;
      _pcs := _pcs + 'WHERE FEJ.STORNO=3'+_sorveg;
      _pcs := _pcs + 'ORDER BY FEJ.BIZONYLATSZAM';

      with BlokkQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
          _stornoDarab := Recno;
          First;
        end;

      Form1.MemoTabla.Lines.Add(inttostr(_aktPenztarSzam)+'-'+inttostr(_stornodarab));
      Form1.MEMOTABLA.Repaint;

      if _stornoDarab=0 then
        begin
          BlokkQuery.Close;
          BlokkDbase.close;
          inc(_qq);
          Continue;
        end;

      while not BlokkQuery.Eof do
        begin
          with BlokkQuery do
            begin
              _bizonylatszam := FieldByName('BIZONYLATSZAM').asString;
              _datum         := FieldByName('DATUM').asString;
              _aktido        := FieldByName('IDO').asstring;
              _penztarosnev  := FieldByName('PENZTAROSNEV').asstring;
              _stornoIndok   := FieldByNAme('SZALLITONEV').asstring;
            end;

          Form1.MEMOTABLA.Lines.Add(_datum +':'+_stornoindok);
          Form1.Repaint;  

          _pcs := 'INSERT INTO STORNOFEJ (IRODASZAM,BIZONYLATSZAM,DATUM,';
          _pcs := _pcs + 'IDO,PENZTAROSNEV,STORNOINDOK)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_aktpenztarszam)+',';
          _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
          _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
          _pcs := _pcs + chr(39) + _aktido + chr(39) + ',';
          _pcs := _pcs + chr(39) + trim(_penztarosnev) + chr(39)+ ',';
          _pcs := _pcs + chr(39)+ trim(_stornoIndok) + chr(39) + ')';

          with StornofejQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              ExecSql;
            end;

          Tetelfeliras;
        end;
      INC(_QQ);
    end;

  Stornofejtranz.Commit;
  StornoFejdbase.Close;

  StornotetelTranz.Commit;
  StornoTetelDbase.Close;

  Blokkquery.Close;
  BlokkDbase.close;

  Excelcsinalo;
//  JelentesIras;
//  Jelenteskuldes;


  _aktemailcim := 'fabulyazsuzsa@gmail.com';
  _aktcimzett  := 'Fabulya Zsuzsa';
  _aktFilePath := _stornoPath;
  _aktTargy    := 'Stornózott bizonylatok';

  Form1.EmailBejegyzes;

  Form1.StatusBeiro(5);
  KilepoTimer.Enabled := True;
end;


// ==============================================
        procedure TStornoBizonylatok.Tetelfeliras;
// ==============================================


begin
  while not BlokkQuery.Eof do
    begin
      with BlokkQuery do
        begin
          _tbizszam    := FieldByName('BIZONYLATSZAM').asString;
          _valutanem   := FieldByName('VALUTANEM').asString;
          _bjegy       := FieldByName('BANKJEGY').asInteger;
          _forintErtek := FieldByName('FORINTERTEK').asInteger;
        end;

      if _tbizSzam<>_bizonylatszam then exit;

      _pcs := 'INSERT INTO STORNOTETEL (BIZONYLATSZAM,VALUTANEM,';
      _pcs := _pcs + 'BANKJEGY,IRODASZAM,FORINTERTEK)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _tbizszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
      _pcs := _pcs + inttostr(_bjegy) + ',';
      _pcs := _pcs + inttostr(_aktpenztarszam) + ',';
      _pcs := _pcs + inttostr(_forintertek) + ')';

      with StornoTetelQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;
      BlokkQuery.next;
    end;
end;



procedure TStornoBizonylatok.KILEPOTIMERTimer(Sender: TObject);
begin
  KilepoTimer.Enabled := false;
  Modalresult := 1;
end;



(*
// =======================================================
           procedure TStornoBizonylatok.JELENTESIRAS;
// =======================================================


begin

  _dbLine := dupestring('=',75)+_sorveg;
  _spLine := dupestring('-',120)+_sorveg;

  StornoFejdbase.Connected := true;
  if stornofejtranz.InTransaction then Stornofejtranz.commit;

  Stornoteteldbase.Connected := True;
  if stornoteteltranz.InTransaction then stornotetelTranz.Commit;

  _pcs := 'SELECT * FROM STORNOFEJ ORDER BY IRODASZAM';
  with StornoFejQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _body := _dbline + 'BIZONYLAT    DÁTUM    IDÕ        PÉNZTÁROSNÉV            STORNO INDOKA'+_sorveg;

  // ===========================================================================
  // BIZONYLAT    DÁTUM    IDÕ        PÉNZTÁROSNÉV            STORNO INDOKA
  // ===========================================================================
  //  145 HODMEZOVASARHELY - MEZOVASARI ABCDE:
  // ---------------------------------------------------------------------------
  //  V123456  2009.11.23 12:36 ABCDFREGTHZTREDFGBHGFREWD ASDFGHZTGFREDWSDEFRG
  //              2. TÉTEL:
  //                        3,000 USD  2,345,600 Ft
  //                        1,000 EUR  1,300,400 Ft
  // ---------------------------------------------------------------------------
  //  E100000  2009.11.23 13:44 KOVÁCS ELEONORA           MERT CSAK
  // ===========================================================================
  //   25 SZEGEDI - SZEGEDI TESCO:
  // ---------------------------------------------------------------------------
  //  V110234  2009.11.29 16:00 NAGY KRISZTIÁN            MERT LOPTAM
  //              1. TÉTEL: 1,000 NOK 5,300 Ft
  //


  _utiroda := 0;
  while not stornofejQuery.Eof do
    begin
      with StornoFejQuery do
        begin
          _bizonylatszam := FieldByName('BIZONYLATSZAM').AsString;
          _irodaszam     := FieldByNAme('IRODASZAM').asInteger;
          _datum         := FieldByName('DATUM').AsString;
          _aktido        := FieldByName('IDO').AsString;
          _penztarosnev  := trim(FieldByName('PENZTAROSNEV').AsString);
          _stornoindok   := trim(FieldByName('STORNOINDOK').AsString);
        end;

      if _utIroda<>_irodaszam then
        begin
          _body := _body + _dbLine;
          _body := _body + ' '+inttostr(_irodaszam)+' '+ getptarnev(_irodaszam)+':'+_sorveg;
        end;

      _utiroda := _irodaszam;
      _body := _body + _spline + ' ' + _bizonylatszam+'  '+_datum + ' ' + _aktido + ' ';
      _body := _body + kieg(_penztarosnev,26) + ' ' + _stornoIndok + _sorveg;

      _pcs := 'SELECT * FROM STORNOTETEL WHERE BIZONYLATSZAM='+CHR(39)+_bizonylatszam+chr(39);

      with StornoTetelQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
          _tetel := recno;
          First;
        end;

      _body := _body + '             ' + inttostr(_tetel)+'. TÉTEL: ';
      _elso := true;

      while not StornoTetelQuery.Eof do
        begin
          with StornoTetelQuery do
            begin
              _valutanem := FieldByName('VALUTANEM').asString;
              _bjegy     := FieldByName('BANKJEGY').asInteger;
              _ertek     := FieldByname('FORINTERTEK').asInteger;
            end;
          if not _elso then _body := _body + dupestring(' ',32);
          _elso := False;
          _body := _body + elokiegformat(_bjegy) + ' ' + _valutanem + ' ';
          _body := _body + elokiegFormat(_ertek)+' Ft' + _sorveg;

          StornotetelQuery.Next;
        end;

      StornoTetelQuery.close;
      StornoFejQuery.Next;
    end;
  StornoFejQuery.Close;
  StornoFejDbase.Close;
  StornoTetelQuery.Close;
  StornoTetelDbase.Close;
end;
*)


// =================================================================
      function TStornoBizonylatok.GetpTarNev(_isz: integer): string;
// =================================================================


var i: integer;

begin
  result := '?';
  for i := 1 to _irodadarab do
    begin
      if  _uzletszam[i]=_isz then
        begin
          result := _uirodaNev[i];
          break;
        end;
    end;
end;

function TStornoBizonylatok.kieg(_szo: string;_hh: integer): string;

begin
  result := _szo;
  while length(result)<_hh do result := result + chr(32);
end;

function TStornoBizonylatok.ElokiegFormat(_forint: integer):string;

var _ftreal: real;
begin
  _ftreal := (1*_forint);
  result := formatfloat('### ### ###',_ftReal);
  while length(result)<11 do result := ' ' + result;
end;



(*
procedure TStornoBizonylatok.JelentesKuldes;

begin
  _xEmailcim := 'controlling@bestchange.hu';
  _xCimzett := 'Annamari';
  _siker := Form1.SendMailMapi(_xCimzett,_xEmailCim);

  _xEmailcim := 'fabulyazs@bestchange.hu';
  _xCimzett := 'Fabulya Zsuzsa';
  _siker2 := Form1.Sendmailmapi(_xCimzett,_xEmailCim);

  _xEmailcim := '06703800202@vodafone.hu';
  _xCimzett := 'Kósa Zoli';
  _siker2 := Form1.Sendmailmapi(_xCimzett,_xEmailCim);

end;
*)


// ================================================
     procedure TStornoBizonylatok.ExcelCsinalo;
// ================================================

var
    _stDarab: integer;

begin

  _stornopath := 'c:\receptor\stor' + _farok + '.xls';

  _excelTabla := cREATEOLEOBJECT('EXCEL.APPLICATION');
  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.Activate;

  // ---------------------------------------------------

  _excelTabla.Range['A1:H1'].MergeCells := True;
  _excelTabla.Cells[1,1] := inttostr(_aktev)+' '+_honev[_aktho]+'I STORNOZOTT BIZONYLATOK';
  _excelTabla.Cells[1,1].Font.size := 14;
  _excelTabla.Cells[1,1].Font.Bold := True;
  _excelTabla.Cells[1,1].HorizontalAlignment := -4108;
  _XSOR := 3;

  StornoFejdbase.Connected := true;
  if stornofejtranz.InTransaction then Stornofejtranz.commit;

  Stornoteteldbase.Connected := True;
  if stornoteteltranz.InTransaction then stornotetelTranz.Commit;

  _pcs := 'SELECT * FROM STORNOFEJ ORDER BY IRODASZAM,DATUM,IDO';

  with StornoFejQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _stdarab := recno;
      First;
    end;



  Csik.Max := _stDarab;
  _utiroda := 0;
  _cc := 0;

  while not stornofejQuery.Eof do
    begin
      Csik.Position := _cc;
      with StornoFejQuery do
        begin
          _bizonylatszam := FieldByName('BIZONYLATSZAM').AsString;
          _irodaszam     := FieldByNAme('IRODASZAM').asInteger;
          _datum         := FieldByName('DATUM').AsString;
          _aktido        := FieldByName('IDO').AsString;
          _penztarosnev  := trim(FieldByName('PENZTAROSNEV').AsString);
          _stornoindok   := trim(FieldByName('STORNOINDOK').AsString);
        end;

      Form1.MEMOTABLA.Lines.add(_bizonylatszam+':'+_stornoindok);
      Form1.Memotabla.Repaint;  

      if _utiroda<>_irodaszam then
        begin
          _utiroda := _irodaszam;
          inc(_xsor);
          _range := _excelTabla.Range['A'+inttostr(_xsor)+':H'+inttostr(_xsor)];
          _range.select;
          _Range.Mergecells := True;
          _range.Interior.color := $B0FFFF;
          _range.HorizontalAlignment := -4108;
          _range.Font.Bold := True;
          _range.Font.Size := 12;

          _excelTabla.Cells[_xsor,1] := inttostr(_irodaszam)+'. '+ getptarnev(_irodaszam);
          inc(_xsor);
      end;
      _range := _excelTabla.Range['A'+inttostr(_xsor)+':H'+inttostr(_xsor)];
      _range.select;
      _range.HorizontalAlignment := -4108;

      _excelTabla.Cells[_xsor,1] := _bizonylatszam;
      _excelTabla.Cells[_xsor,2] := _datum+'-'+_aktido;
      _exceltabla.Cells[_xsor,3] := _penztarosnev;
      _excelTabla.Cells[_xsor,4] := _stornoIndok;

      _pcs := 'SELECT * FROM STORNOTETEL WHERE BIZONYLATSZAM='+CHR(39)+_bizonylatszam+chr(39);

      with StornoTetelQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
          _tetel := recno;
          First;
        end;

      _exceltabla.cells[_xsor,5] := inttostr(_tetel)+' TÉTEL';

      while not StornoTetelQuery.Eof do
        begin
          with StornoTetelQuery do
            begin
              _valutanem := FieldByName('VALUTANEM').asString;
              _bjegy := FieldByName('BANKJEGY').asInteger;
              _ertek := FieldByname('FORINTERTEK').asInteger;
            end;

          _excelTabla.cells[_xsor,6].HorizontalAlignment := -4108;
          _excelTabla.cells[_xsor,6].NumberFormat := '### ### ###';
          _excelTabla.cells[_xsor,6] := inttostr(_bJegy);

          _excelTabla.cells[_xsor,7].HorizontalAlignment := -4108;
          _excelTabla.Cells[_xsor,7] := _valutaNem;

          _excelTabla.cells[_xsor,8].HorizontalAlignment := -4108;
          _excelTabla.cells[_xsor,8].NumberFormat := '### ### ###';
          _excelTabla.Cells[_xSor,8] := inttostr(_ertek);
          inc(_xSor);
          StornotetelQuery.Next;
        end;

      inc(_cc);
      StornoTetelQuery.close;
      StornoFejQuery.Next;
    end;

  StornoFejQuery.Close;
  StornoFejDbase.Close;
  StornoTetelQuery.Close;

  DeleteFile(_stornopath);
  _sajatexcel.saveas(_stornopath,password:=_jelszo);

  _excelTabla.ActiveWorkBook.close;
  _excelTabla.quit;
  _EXCELTABLA := UnAssigned;
end;

// =============================================================================
           function TStornoBizonylatok.Dekodol(_kj: string):string;
// =============================================================================


var i,_asc: integer;

begin
  result := '';
  for i := 1 to length(_kj) do
    begin
      _asc := ord(_kj[i]);
      if _asc<82 then _asc := _asc + 40
      else _asc := _asc - 40;
      result := result + chr(_asc);
    end;
end;

end.
