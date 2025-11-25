unit Unit6;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, dATEuTILS,
  StrUtils, ComCtrls, StdCtrls, IBTable, COMOBJ;

type
  TBIGSUM = class(TForm)
    INDITOTIMER: TTimer;
    KILEPOTIMER: TTimer;
    STORNOFEJDBASE: TIBDatabase;
    STORNOFEJTRANZ: TIBTransaction;
    STORNOFEJQUERY: TIBQuery;
    stornoteteldbase: TIBDatabase;
    STORNOTETELTRANZ: TIBTransaction;
    stornotetelquery: TIBQuery;
    csik: TProgressBar;
    Label1: TLabel;
    BLOKKTRANZ: TIBTransaction;
    BLOKKDBASE: TIBDatabase;
    blokktabla: TIBTable;
    blokkquery: TIBQuery;
    ARFEDBASE: TIBDatabase;
    arfetranz: TIBTransaction;
    ARFEQUERY: TIBQuery;
    BIGSUMDBASE: TIBDatabase;
    BIGSUMTRANZ: TIBTransaction;
    BIGSUMQUERY: TIBQuery;

    procedure FormActivate(Sender: TObject);
    procedure InditoTimerTimer(Sender: TObject);

    procedure Tetelfeliras;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Excelcsinalo;

    function GetPenztarNev(_isz: integer): string;
    function Dekodol(_kj: string):string;
    function GetErtekTarnev(_eesz: integer): string;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BIGSUM: TBIGSUM;


  _munkad: TdateTime;

  _excelTabla,_sajatexcel,_range: variant;

  _tNap,_aktertekTar,_utertektar,_ertektar: integer;

  _tegNaps: string;

  _fejtablanev,_tettablanev,_engedtipus: string;

  _bigsumDarab: integer;

  _tBizszam: string;
  _forintErtek: integer;
  _arfolyam,_elszamarfolyam: real;
  _vars,_bolts,_tranzakcio,_trtipus: string;

  // =============================================
  _tesztnap: TDateTime;
  _cc,_stornoDarab,_irodaszam: integer;
  _body,_dbLine,_spline,_utdatum: string;
  _aktpenztar,_utiroda: integer;
  _elso: boolean;
  _ertek: integer;

  _ptdb,_siker,_siker2,_xsor: integer;
 _bigsumpath,_oribizonylat,_utsors: string;


implementation

uses Unit1;

{$R *.dfm}

procedure TBigsum.FormActivate(Sender: TObject);
begin
  Top := 10;
  Left := 5;
  Color := $f8e4d8;
  Label1.Repaint;
  Bigsum.Repaint;
  InditoTimer.Enabled := true;
end;



procedure TBigsum.INDITOTIMERTimer(Sender: TObject);

var _etip,_recno: integer;
     _arfeTablanev,_emeg: string;

begin

  InditoTimer.Enabled := False;
  Form1.StatusBeolvaso;
  _jelszo := Dekodol(trim(_kodjelszo));
  _munkad := strtodate(_munkanap);

  // -----------------------------------------------------

  _farok   := midstr(_munkanap,3,2)+midstr(_munkanap,6,2);
  _aktev   := yearof(_munkad);
  _aktho   := monthof(_munkad);

  // -------------------------------------------------------------------

  Form1.MemoTabla.Lines.Add('FEJ-TÁBLA KIÜRITÉSE');

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

  // -------------------------------------------------------------------

  Form1.MemoTabla.Lines.add('TÉTEL-TÁBLA KIÜRITÉSE');

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
  _arfetablaNev := 'ARFE' + _farok;

  Form1.MemoTabla.Lines.add('AZ EGYES PÉNZTÁRAK BEOLVASÁSA');
  Csik.Max := _irodaDarab;

  _qq := 1;
  while _qq<=_irodaDarab do
    begin
      Csik.Position := _qq;
      _aktPenztarSzam := _Uzletszam[_qq];
      _aktgdbPath := 'c:\receptor\database\v' + inttostr(_aktPenztarSzam)+'.GDB';

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
      _pcs := _pcs + 'WHERE ((TET.VALUTANEM='+ chr(39)+ 'EUR' +chr(39)+' AND TET.BANKJEGY>=5000)' + _SORVEG;
      _pcs := _pcs + 'OR (TET.VALUTANEM='+CHR(39)+'GBP'+CHR(39)+' AND TET.BANKJEGY>=5000)' + _sorveg;
      _pcs := _pcs + 'OR (TET.VALUTANEM='+chr(39)+'CHF'+chr(39)+' AND TET.BANKJEGY>=10000)' + _sorveg;
      _pcs := _pcs + 'OR (TET.VALUTANEM='+CHR(39)+'USD'+chr(39)+' AND TET.BANKJEGY>=15000))' + _sorveg;
      _pcs := _pcs + 'AND (FEJ.TIPUS='+CHR(39)+'V'+chr(39)+' OR FEJ.TIPUS='+chr(39)+'E'+chr(39)+')'+_sorveg;
      _pcs := _pcs + 'ORDER BY FEJ.BIZONYLATSZAM';

      with BlokkQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
          _bigsumDarab := Recno;
          First;
        end;

      Form1.MemoTabla.Lines.add(inttostr(_AKTPENZTARSZAM)+'-'+inttostr(_bigsumdarab));
      if _bigsumDarab=0 then
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
              _datum := FieldByName('DATUM').asString;
              _penztarosnev := FieldByName('PENZTAROSNEV').asstring;
              _ugyfelnev := FieldByNAme('UGYFELNEV').asstring;
            end;

          Arfedbase.Close;
          ArfeDbase.DatabaseName := _aktgdbPath;
          ArfeDbase.Connected := True;

          _pcs := 'SELECT * FROM ' + _ARFETABLANEV + _sorveg;
          _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
          with ArfeQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              Open;
              First;
              _recno := recno;
            end;

          _etip := 0;
          _emeg := '';
          if _recno>0 then _etip := ArfeQuery.FieldByName('ENGEDMENYTIPUS').asInteger;
          ArfeQuery.Close;
          ArfeDbase.Close;

          if _etip=34 then _emeg := 'JUTALEKMENTES';

           GetPenztarNev(_aktpenztarszam);
          _pcs := 'INSERT INTO STORNOFEJ (IRODASZAM,ERTEKTAR,DATUM,BIZONYLATSZAM,';
          _pcs := _pcs + 'PENZTAROSNEV,UGYFELNEV,STORNOINDOK)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_aktpenztarszam)+',';
          _pcs := _pcs + inttostr(_aktertektar) + ',';
          _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
          _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
          _pcs := _pcs + chr(39) + trim(_penztarosnev) + chr(39)+ ',';
          _pcs := _pcs + chr(39)+ trim(_ugyfelnev) + chr(39) + ',';
          _pcs := _pcs + chr(39) + _emeg + chr(39) + ')';

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
  _aktFilePath := _bigsumPath;
  _aktTargy    := 'Nagyértékü tranzakciók';

  Form1.EmailBejegyzes;
  Form1.StatusBeiro(4);
  KilepoTimer.Enabled := True;
end;

// ========================================================
        function TBigsum.Dekodol(_kj: string):string;
// ========================================================

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

// ==============================================
        procedure TBigsum.Tetelfeliras;
// ==============================================

begin
  while not BlokkQuery.Eof do
    begin
      with BlokkQuery do
        begin
          _tbizszam       := FieldByName('BIZONYLATSZAM').asString;
          _valutanem      := FieldByName('VALUTANEM').asString;
          _bjegy          := FieldByName('BANKJEGY').asInteger;
          _forintErtek    := FieldByName('FORINTERTEK').asInteger;
          _arfolyam       := FieldByName('ARFOLYAM').asFloat;
          _elszamarfolyam := FieldByname('ELSZAMOLASIARFOLYAM').asFloat;
        end;

      Form1.MemoTabla.Lines.Add(_VALUTANEM+' = '+INTTOSTR(_BJEGY));
      Form1.Repaint;
      if _tbizSzam<>_bizonylatszam then exit;

      _pcs := 'INSERT INTO STORNOTETEL (BIZONYLATSZAM,VALUTANEM,ELSZAMOLASIARFOLYAM,';
      _pcs := _pcs + 'BANKJEGY,IRODASZAM,ARFOLYAM,FORINTERTEK)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _bizonylatszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
      _pcs := _pcs + Form1.realtostr(_elszamarfolyam)+',';
      _pcs := _pcs + inttostr(_bjegy) + ',';
      _pcs := _pcs + inttostr(_aktpenztarszam) + ',';
      _pcs := _pcs + Form1.realtostr(_arfolyam)+',';
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


procedure TBigsum.KILEPOTIMERTimer(Sender: TObject);
begin
  KilepoTimer.Enabled := false;
  Modalresult := 1;
end;


// =================================================================
      function TBigsum.GetPenztarNev(_isz: integer): string;
// =================================================================


var i: integer;

begin
  result := '?';
  for i := 1 to _irodadarab do
    begin
      if  _uzletszam[i]=_isz then
        begin
          _aktErtektar := _uErtektar[i];
          result := _uirodanev[i];
          break;
        end;
    end;
end;



(*
procedure TBigsum.JelentesKuldes;

begin
  _xEmailcim := 'controlling@bestchange.hu';
  _xCimzett := 'Annamari';
  _siker := fORM1.SendMailMapi(_xCimzett,_xEmailCim);

  _xEmailcim := 'fabulyazs@bestchange.hu';
  _xCimzett := 'Fabulya Zsuzsa';
  _siker2 := Form1.Sendmailmapi(_xCimzett,_xEmailCim);

  _xEmailcim := '06703800202@vodafone.hu';
  _xCimzett := 'Kósa Zoli';
  _siker2 := Form1.Sendmailmapi(_xCimzett,_xEmailCim);
end;
*)



// ================================================
     procedure TBigsum.ExcelCsinalo;
// ================================================

var
    _stDarab: integer;
    _keret,_penztarNev,_ertektarNev: string;
    _piros,_kek: boolean;

begin

  _bigsumpath := 'c:\receptor\bigs' + _farok + '.xls';

  _excelTabla := cREATEOLEOBJECT('EXCEL.APPLICATION');
  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.Activate;

  // ---------------------------------------------------

  _excelTabla.Range['A1:M1'].MergeCells := True;
  _excelTabla.Cells[1,1] := inttostr(_aktev)+' '+_honev[_aktho]+' HAVI NAGYÉRTÉKÜ TRANZAKCIÓK';
  _excelTabla.Cells[1,1].Font.size := 18;
  _excelTabla.Cells[1,1].Font.Bold := True;
  _excelTabla.Cells[1,1].Font.Color:= clNavy;
  _excelTabla.Cells[1,1].Interior.color := $B0FFFF;
  _excelTabla.Cells[1,1].HorizontalAlignment := -4108;

  _excelTabla.Range['A2:M3'].horizontalAlignment := -4108;


  _excelTabla.Cells[2,1] := 'ÉRTÉKTÁR SZÁMA';    //a2:a3
  _excelTabla.Cells[2,2] := 'ÉRTÉKTÁR NEVE';     //b2:b3
  _excelTabla.Cells[2,3] := 'PÉNZTÁR SZÁMA';     //c2:c3
  _excelTabla.Cells[2,4] := 'PÉNZTÁR NEVE';      //d2:d3
  _excelTabla.Cells[2,5] := 'DÁTUM';
  _excelTabla.Cells[2,6] := 'ÖSSZEG';
  _excelTabla.Cells[2,7] := 'VALUTA NEME';       //g2:g3
  _excelTabla.Cells[2,8] := 'ÁRFOLYAM';
  _excelTabla.Cells[2,9] := 'FORINT ÉRTÉK';      //i2:i3
  _excelTabla.Cells[2,10] := 'PÉNZTÁROS NEVE';   //j2:j3
  _excelTabla.Cells[2,11] := 'ÜGYFÉL NEVE';      //k2:k3
  _excelTabla.Cells[2,12] := 'ELSZÁMOLÁSI ÁRFOLYAM'; // L2:L3
  _excelTabla.Cells[2,13] := 'TRANZAKCIÓ';  // M2:M3

  // A fejléc betüinek paraméterezése:

  _range := _excelTabla.Range['A2:K3'];
  _range.select;
  _range.Font.size := 10;
  _range.Font.Bold := True;

  // Értéktár száma:

  _range := _excelTabla.Range['A2:A3'];
  _range.Select;
  _range.MergeCells := True;
  _range.WrapText := True;
  _range.Columnwidth := 11;

  // Értéktár neve:

  _range := _excelTabla.Range['B2:B3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 16;
  _range.VerticalAlignment := -4108;

  // Pénztár száma:

  _range := _excelTabla.Range['C2:C3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 11;
  _range.WrapText := True;

  // Pénztár neve:

  _range := _excelTabla.Range['D2:D3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 40;
  _range.VerticalAlignment := -4108;

  // Dátum:

  _range := _excelTabla.Range['E2:E3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 11;
  _range.VerticalAlignment := -4108;

  // ÖSSZEG:

  _range := _excelTabla.Range['F2:F3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 11;
  _range.VerticalAlignment := -4108;

  // VALUTA NEME:

  _range := _excelTabla.Range['G2:G3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 8;
  _range.wraptext := true;
  _range.VerticalAlignment := -4108;

  // ÁRFOLYAM:

  _range := _excelTabla.Range['H2:H3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 11;
  _range.VerticalAlignment := -4108;

  // FORINT ÉRTÉK:

  _range := _excelTabla.Range['I2:I3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 11;
   _range.wraptext := true;

  // PÉNZTÁROS NEVE:

  _range := _excelTabla.Range['J2:J3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 32;
  _range.VerticalAlignment := -4108;

  // ÜGYFÉL NEVE:

  _range := _excelTabla.Range['K2:K3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 32;
  _range.VerticalAlignment := -4108;

  // ELSZÁMOLÁSI ÁRFOLYAM:

  _range := _excelTabla.Range['L2:L3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 12;
  _range.VerticalAlignment := -4108;

  // TRANZAKCIÓ

  _range := _excelTabla.Range['M2:M3'];
  _range.Select;
  _range.Mergecells := True;
  _range.ColumnWidth := 12;
  _range.VerticalAlignment := -4108;

  _XSOR := 4;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs +'FROM STORNOFEJ FEJ JOIN STORNOTETEL TET'+_sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;
  _pcs := _pcs + 'ORDER BY FEJ.ERTEKTAR,FEJ.DATUM';

  BigSumdbasE.Connected := true;
  if Bigsumtranz.InTransaction then Bigsumtranz.commit;

  with BigsumQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _stdarab := recno;
      First;
    end;

  // ---------------------------------------------------------------------------


  _keret := 'A4:M'+ inttostr(13+_stDarab);

  _range := _exceltabla.Range[_keret];
  _range.select;
  _range.HorizontalAlignment := -4108;

  // ---------------------------------------------------------------------------

  _range := _excelTabla.Range[_keret];
  _range.select;
  _range.NumberFormat := '### ### ###';

  _keret := 'H4:H'+ inttostr(13+_stDarab);
  _range := _excelTabla.Range[_keret];
  _range.select;
  _range.NumberFormat := '## ###';

  _keret := 'L4:L'+ inttostr(13+_stDarab);
  _range := _excelTabla.Range[_keret];
  _range.select;
  _range.NumberFormat := '## ###';


  _keret := 'I4:K'+ inttostr(13+_stDarab);
  _range := _excelTabla.Range[_keret];
  _range.select;
  _range.NumberFormat := '### ### ###';

  Csik.Max := _stDarab;
  _utertektar := 0;
  _utDatum := 'X';
  _cc := 0;
  _xsor := 4;
  while not BigsumQuery.Eof do
    begin
      Csik.Position := _cc;
      with BigsumQuery do
        begin
          _ertektar := FieldByName('ERTEKTAR').AsInteger;
          _bizonylatszam := FieldByName('BIZONYLATSZAM').AsString;
          _irodaszam := FieldByNAme('IRODASZAM').asInteger;
          _datum := FieldByName('DATUM').AsString;
          _penztarosnev := trim(FieldByName('PENZTAROSNEV').AsString);
          _ugyfelnev := trim(FieldByName('UGYFELNEV').AsString);
          _bjegy := FieldByName('BANKJEGY').asInteger;
          _arfolyam := FieldByName('ARFOLYAM').asFloat;
          _ertek := FieldByName('FORINTERTEK').asInteger;
          _valutanem := FieldByName('VALUTANEM').asString;
          _elszamarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').ASfLOAT;
          _engedtipus := trim(FieldByName('STORNOINDOK').asString);
        end;

      _trtipus := leftstr(_bizonylatszam,1);
      if _trtipus = 'V' then _tranzakcio := 'VÉTEL';
      if _trtipus = 'E' then _tranzakcio := 'ELADÁS';
      if _trtipus = 'K' then _tranzakcio := 'KONVERZIÓ';
      if _trtipus = 'U' then _tranzakcio := 'PÉNZÁTVÉTEL';
      if _trtipus = 'F' then _tranzakcio := 'PÉNZÁTADÁS';


      if _ertektar<>_utertektar then
        begin
          _ertektarnev := GetErtekTarNev(_ertekTar);
          _excelTabla.Cells[_xsor,1] := inttostr(_ertektar);
          _excelTabla.Cells[_xsor,2] := _ertektarnev;
          _excelTabla.cells[_xsor,1].interior.color := $B0FFFF;
          _excelTabla.cells[_xsor,2].interior.color := $B0FFFF;
          _utertektar := _ertektar;
          inc(_xsor);
        end;

      IF _engedTipus='JUTALEKMENTES' THEN
        begin
          _keret := 'C'+INTTOSTR(_XSOR)+':M'+INTTOSTR(_XSOR);
          _range := _excelTabla.Range[_KERET];
          _range.select;
          _range.interior.color := $C0FFC0;
        end;


      _penztarNev  := GetPenztarNev(_irodaszam);   //

      Form1.MEMOTABLA.Lines.add(_penztarnev);
      Form1.MEMOTABLA.Repaint;

      _excelTabla.Cells[_xSor,3] := inttostr(_irodaszam);
      _excelTabla.Cells[_xSor,4] := _penztarNev;
      _excelTabla.Cells[_xsor,5] := _datum;
      _exceltabla.Cells[_xsor,6] := _bjegy;
      _excelTabla.Cells[_xsor,7] := _valutanem;
      _excelTabla.Cells[_xsor,8] := _arfolyam;
      _excelTabla.Cells[_xsor,9] := _ertek;
      _excelTabla.Cells[_xsor,10] := _penztarosnev;
      _excelTabla.Cells[_xsor,11] := _ugyfelnev;
      _exceltabla.cells[_xsor,12] := _elszamarfolyam;
      _exceltabla.cells[_xsor,13] := _tranzakcio;

      _piros := False;
      _kek := False;
      if (_trTipus='V') and (_arfolyam>_elszamarfolyam) then _piros := True;
      if (_trTipus='E') and (_arfolyam<_elszamarfolyam) then _piros := True;
      if abs(_elszamarfolyam-_arfolyam)<51 then _kek := True;

       IF _piros or _kek THEN
        begin
          _keret := 'C'+INTTOSTR(_XSOR)+':M'+INTTOSTR(_XSOR);
          _range := _excelTabla.Range[_KERET];
          _range.select;
        end;

       if _piros then _range.Font.color := clRed;
       if _kek then _range.Font.color := clBlue;

      inc(_cc);
      inc(_xsor);
      BigsumQuery.next;
    end;
  BigsumQuery.close;
  Bigsumdbase.Close;

  DeleteFile(_Bigsumpath);
  _sajatexcel.saveas(_Bigsumpath,password:=_jelszo);

  _excelTabla.ActiveWorkBook.close;
  _excelTabla.quit;
  _excelTabla := Unassigned;

end;



// ===============================================================
         function TBigsum.GetErtekTarnev(_eesz: integer): string;
// ===============================================================


begin
  if _eesz=10 then
    begin
      Result := 'SZEKSZÁRD';
      Exit;
    end;

  if _eesz=20 then
    begin
      Result := 'SZEGED';
      Exit;
    end;

  if _eesz=40 then
    begin
      Result := 'KECSKEMÉT';
      Exit;
    end;

  if _eesz = 50 then
    begin
      Result := 'DEBRECEN';
      Exit;
    end;

  if _eesz=63 then
    begin
      Result := 'NYÍREGYHÁZA';
      Exit;
    end;

  if _eesz=75 then
    begin
      Result := 'BÉKÉSCSABA';
      Exit;
    end;

  if _eesz=120 then
    begin
      Result := 'PÉCS';
      Exit;
    end;

  if _eesz=145 then
    begin
      Result := 'KAPOSVÁR';
      Exit;
    end;
end;

end.
