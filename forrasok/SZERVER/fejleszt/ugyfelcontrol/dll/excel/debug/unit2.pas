unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  Comobj, Grids, DBGrids, Buttons, ComCtrls, TlHelp32;

type
  TForm2 = class(TForm)
    HeadMakePanel    : TPanel;
    Kilepo           : TTimer;
    UQuery           : TIBQuery;
    UDbase           : TIBDatabase;
    UTranz           : TIBTransaction;
    MezoRacs         : TDBGrid;
    MezoSource       : TDataSource;
    Panel2           : TPanel;
    Panel3           : TPanel;
    FejRacs          : TDBGrid;
    Panel4           : TPanel;
    FejQuery         : TIBQuery;
    FejDbase         : TIBDatabase;
    FejTranz         : TIBTransaction;
    FejSource        : TDataSource;
    FejlecRendbenGomb: TBitBtn;
    ExcelMegsemFomb  : TBitBtn;
    KilepoGomb       : TPanel;
    TakaroPanel      : TPanel;
    Label1           : TLabel;
    Csik             : TProgressBar;


    procedure FormActivate(Sender: TObject);
    procedure ExcelParancs(_ukaz: string);
    procedure MezotValasztott;
    procedure FejTablaOpen;
    procedure MezoTablaOpen;
    procedure Fejlecboltorolni;
    procedure MakeExcel;
    procedure SetMezoszelesseg;
    procedure FejlecOsszeallitas;
    procedure Keretezes;
    procedure AdatokKijelzese;
    procedure KillExcel;
    procedure KilepoTimer(Sender: TObject);
    procedure Vastagkeret(_rs: string);
    procedure Vekonykeret(_rs: string);
    procedure MezoRacsDblClick(Sender: TObject);
    procedure MezoRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FejRacsDblClick(Sender: TObject);
    procedure FejRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ExcelMegsemFombClick(Sender: TObject);
    procedure fejlecrendbengombClick(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _proc: PROCESSENTRY32;
  _handle: HWND;

  _fmezoss,_fMezoSzel,_horizont,_nformat: array[1..50] of byte;
  _fMezonev,_fmezofej,_mTipus: array[1..50] of string;
  _ss,_fejmezoDarab,_aktszelesseg,_mm,_ec,_fleclen: byte;

  _expath,_rangestr,_lastbetus,_aktfejnev,_betus,_terulet: string;
  _order,_idoszak,_feltetel,_aktmezo,_aktstring: string;
  _oxl,_owb,_range: Olevariant;
  _udbnev,_bizonylat,_valutanem,_tipus,_pcs,_datum,_ugyftip,_lowers: string;
  _joginev,_jogicim,_okirat,_mbneve,_aktkftnev,_aktptcim,_csoport: string;

  _mbnev,_mbelozonev,_mbszuletesihely,_mbszuletesiido,_mbanyjaneve: string;
  _mbAllampolgar,_mbOkmanytipus,_mbAzonosito,_megbizott,_mbTabla,_akttipus: string;

  _asc,_aktevtized,_penztar,_aktkftnum,_wmb,_mezoss,_oszlop: byte;
  _prisor,_aktev,_top,_left,_height,_width: word;
  _bankjegy,_arfolyam,_ftertek,_sorszam,_cc,_recno,_aktnum: integer;

  _head: string;
  _sorpath : string = 'c:\uctrl\data\sorszam.txt';
  _sorveg : string = chr(13)+chr(10);

  _vanmb,_looper: boolean;
  _fejmezodb: byte;

function exceltablakeszites: integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
             function exceltablakeszites: integer; stdcall;
// =============================================================================

begin
  Form2 := Tform2.Create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;



// =============================================================================
           procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top := round((_height-595)/2);
  _left := 163 + round((_width-1017)/2);

  Top := _top;
  Left := _left;
  Repaint;

  with HeadMakePanel do
    begin
      top := 0;
      left := 0;
      Visible := true;
      repaint;
    end;

  _fejmezodb := 0;
  Mezosource.Enabled := False;

  _pcs := 'UPDATE EXCELDATA SET FLAG=0';
  excelParancs(_pcs);

  Udbase.Connected := True;
  with UQuery do
    begin
      CLose;
      Sql.clear;
      sql.add('SELECT * FROM VTEMP');
      open;
      _terulet := trim(FieldByNAme('MEGNEVEZES').AsString);
      _order   := trim(FieldByNAme('ORDERMEZO').AsString);
      _idoszak := trim(FieldByNAme('KERTDATUMS').AsString);
      _feltetel := trim(FieldByNAme('FELTETEL').AsString);
      Close;
    end;
  Udbase.close;

  FejtablaOpen;
  MezoTablaOpen;
end;

// =============================================================================
                 procedure TForm2.MezoTablaOpen;
// =============================================================================

begin
  _pcs := 'SELECT * FROM EXCELDATA WHERE FLAG=0'+ _SORVEG;
  _pcs := _pcs + 'ORDER BY MEZOSS';

  Udbase.Connected := true;
  with Uquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  Mezosource.Enabled := True;
  Mezoracs.Refresh;
  MezoRacs.repaint;
  Activecontrol := Mezoracs;
end;


// =============================================================================
                 procedure TForm2.MezotValasztott;
// =============================================================================

begin

  _mezoss := UQuery.fieldByNAme('MEZOSS').asInteger;
  inc(_fejmezodb);

  Mezosource.enabled := False;
  _pcs := 'UPDATE EXCELDATA SET FLAG = ' + inttostr(_fejmezodb) + _sorveg;
  _pcs := _pcs + 'WHERE MEZOSS=' + inttostr(_mezoss);
  ExcelParancs(_pcs);
  MezotablaOpen;
  FejtablaOpen;
  Activecontrol := Mezoracs;
end;

// =============================================================================
                  procedure TForm2.FejtablaOpen;
// =============================================================================

begin
  FejSource.Enabled := False;

  _pcs := 'SELECT * FROM EXCELDATA WHERE FLAG>0' + _sorveg;
  _pcs := _pcs + 'ORDER BY FLAG';

  Fejdbase.Connected := true;
  with Fejquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  Fejsource.Enabled := True;
  Fejracs.Refresh;
  Fejracs.Repaint;
end;

// =============================================================================
          procedure TForm2.fejlecrendbengombClick(Sender: TObject);
// =============================================================================

begin
  _recno := Fejquery.RecNo;
  if _recno=0 then exit;

  uquery.close;
  uDbase.close;

  fejquery.close;
  fejdbase.close;

  HeadMakePanel.Visible := False;
  Fejsource.Enabled := False;
  FejTablaOpen;

  _ss := 0;
  Fejquery.first;
  while not Fejquery.Eof do
    begin
      inc(_ss);
      _fMezoss[_ss]   := Fejquery.Fieldbyname('MEZOSS').asInteger;
      _fMezonev[_ss]  := trim(Fejquery.FieldByName('MEZONEV').asString);
      _fMezoszel[_ss] := Fejquery.FieldByNAme('MEZOSZELESSEG').asInteger;
      _fMezofej[_ss]  := trim(FejQuery.fieldByName('MEZOFEJ').asString);
      _horizont[_ss] := Fejquery.FieldByName('HORIZONTAL').asInteger;
      _nformat[_ss] := Fejquery.FieldByName('NUMBERFORMAT').asInteger;
      _mTipus[_ss]  := Fejquery.FieldByNAme('MEZOTIPUS').asString;
      FejQuery.next;
    end;
  _fejMezoDarab := _ss;
  Fejquery.close;
  Fejdbase.close;

  MakeExcel;
  TakaroPanel.visible := false;
  _oxl.visible := True;
end;

// =============================================================================
                    procedure TForm2.MakeExcel;
// =============================================================================

begin
  _oxl := CreateOleObject('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.Add[1];
  _owb.Activate;

  _rangestr := 'B2:J2';

  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Size   := 16;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.cells[2,2] := _idoszak + ' közötti forgalom';

  _fleclen := 8+_fmezoszel[1]+_fmezoszel[2];
  if _fleclen>30 then _eC :=3 else _eC := 4;

  if _ec=3 then _rangestr := 'B4:C4' else _rangestr := 'B4:D4';
  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Size   := 12;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.cells[4,2] := 'Feldolgozott terület:';

  IF _ec=3 then _rangestr := 'B5:C5' else _rangestr := 'B5:D5';
  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Size   := 12;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.cells[5,2] := 'Adatok sorrendje:';

  If _ec=3 then _rangestr := 'B6:C6' else _rangestr := 'B6:D6';
  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Size   := 12;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.cells[6,2] := 'Adatok szûrése:';

  if _ec=3 then _rangestr := 'D4:J6' else _rangestr := 'E4:J6';
  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Size   := 12;
  _oxl.range[_rangestr].Font.Bold   := False;
  _oxl.range[_rangestr].Font.Italic := True;

  IF _EC=3 THEN _rangestr := 'D4:J4' else _rangestr := 'E4:J4';
  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.Cells[4,_EC+1] := _terulet;

  if _ec=3 then _rangestr := 'D5:J5' else _rangestr := 'E5:J5';
  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.Cells[5,_EC+1] := _order+ ' szerint';

  if _ec=3 then _rangestr := 'D6:J6' else _rangestr := 'E6:J6';
  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.Cells[6,_ec+1] := _feltetel;

  SetMezoSzelesseg;
  FejlecOsszeallitas;
  Keretezes;

  _rangestr := 'A10:A10';
  _range := _oxl.range[_rangestr];
  _range.select;
  _oxl.ActiveWindow.FreezePanes := true;
  AdatokKijelzese;

end;

// =============================================================================
                  procedure TForm2.AdatokKijelzese;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ADATGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE MARKER=1' + _sorveg;

  if _order<>'' then _pcs := _pcs + 'ORDER BY ' + _order;


  // ----------------------------

  Udbase.connected := true;
  with Uquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  // ------------------------------

  if _recno=0 then
    begin
      UQuery.close;
      Udbase.close;
      exit;
    end;

   // -----------------------------

   Csik.Min := 10;
   Csik.Max := _recno+10;
  _lowers := inttostr(_recno+11);

  _rangestr := 'B10:' + _lastbetus + _lowers;
  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Size   := 10;
  _oxl.range[_rangestr].Font.Bold   := False;
  _oxl.range[_rangestr].Font.Italic := False;

  // -------------------------------

  _mm := 1;
  while _mm<=_fejMezoDarab do
    begin
      _oszlop := _mm+1;

      if _oszlop<27 then _betus := chr(_oszlop+64)
      else _betus := 'A' + chr(_oszlop+38);

      _rangestr := _betus+'10:'+_betus+_lowers;

      if _horizont[_mm]=1 then _oxl.range[_rangestr].HorizontalAlignment := -4108;
      if _nformat[_mm]=1 then _oxl.range[_rangestr].Numberformat := '### ### ###';

      inc(_mm);
    end;

  // -------------------------------------

  _prisor := 10;
  while not Uquery.Eof do
    begin
      Csik.Position := _prisor;
      _mm := 1;
      while _mm<=_fejmezodarab do
        begin
          _akttipus := _mTipus[_mm];
          _aktmezo  := _fMezoNev[_mm];

          if _akttipus='C' then
            begin
              _aktstring := trim(Uquery.fieldByName(_aktmezo).asString);
              _oxl.Cells[_prisor,_mm+1] := _aktstring;
            end;

          if _akttipus='N' then
            begin
              _aktnum := Uquery.fieldByName(_aktmezo).asInteger;
              _oxl.Cells[_prisor,_mm+1] := _aktnum;
            end;
          inc(_mm);
        end;

      inc(_prisor);
      Uquery.Next;
    end;

  // ---------------------------------

  Uquery.close;
  Udbase.close;
end;

// =============================================================================
                        procedure TForm2.Keretezes;
// =============================================================================

begin
  _mm := 1;
  While _mm<=_fejmezodarab do
    begin
      _oszlop := _mm+1;
      if _oszlop<27 then _betus := chr(_oszlop+64)
      else _betus := 'A' + chr(_oszlop+38);
      _rangestr := _betus+'8:'+_betus+'9';
      Vekonykeret(_rangestr);
      inc(_mm);
    end;
  VastagKeret('B8:'+_lastbetus+'9');
end;


// =============================================================================
                  procedure TForm2.SetMezoszelesseg;
// =============================================================================

var _betus: string;

begin
  _oxl.range['A1:A1'].Columnwidth := 8;

  _mm := 1;
  while _mm<= _fejmezodarab do
    begin
      _aktszelesseg := _fMezoszel[_mm];
      _oszlop := _mm+1;
      if _oszlop<27 then _betus := chr(_oszlop+64)
      else _betus := 'A' + chr(_oszlop+38);
      _rangestr := _betus+'1:'+_betus+'1';
      _oxl.range[_rangestr].columnwidth := _aktszelesseg;
      inc(_mm);
    end;
  _lastBetus := _betus;
end;

// =============================================================================
               procedure TForm2.FejlecOsszeallitas;
// =============================================================================

begin
  _rangestr := 'B8:'+_lastbetus+'9';

  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Size   := 10;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.range[_rangestr].VerticalAlignment := -4108;
  _oxl.range[_rangestr].Wraptext := true;


  _mm := 1;
  while _mm<=_fejmezodarab do
    begin
      _oszlop := _mm+1;

      if _oszlop<27 then _betus := chr(_oszlop+64)
      else _betus := 'A' + chr(_oszlop+38);
      _rangestr := _betus+'8:'+_betus+'9';
      _oxl.range[_rangestr].Mergecells := true;

      _aktfejnev := _fMezofej[_mm];
      _oxl.cells[8,_mm+1] := _aktfejnev;
      inc(_mm);
    end;
end;


// =============================================================================
                  procedure TForm2.KillExcel;
// =============================================================================

var
  _fileName,_filePath: String;

begin

  _Proc.dwSize := SizeOf(_Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := _Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
              procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  ModalResult := 1;
end;

// =============================================================================
           procedure TForm2.Vastagkeret(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderAround(1,4);
end;

// =============================================================================
          procedure TForm2.Vekonykeret(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderAround(1,2);
end;

// =============================================================================
           procedure TForm2.ExcelParancs(_ukaz: string);
// =============================================================================

begin
  Udbase.close;
  Udbase.connected := true;
  if utranz.InTransaction then utranz.Commit;
  Utranz.StartTransaction;
  with Uquery do
    begin
      Close;
      sql.clear;
      Sql.add(_ukaz);
      Execsql;
    end;
  utranz.commit;
  udbase.close;
end;

// =============================================================================
           procedure TForm2.MEZORACSDblClick(Sender: TObject);
// =============================================================================

begin
  Mezotvalasztott;
end;

// =============================================================================
       procedure TForm2.MEZORACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Mezotvalasztott;
end;

// =============================================================================
            procedure TForm2.FEJRACSDblClick(Sender: TObject);
// =============================================================================

begin
  fejlecbolTorolni;
end;

// =============================================================================
        procedure TForm2.FEJRACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  fejlecboltorolni;
end;

// =============================================================================
                   procedure TForm2.Fejlecboltorolni;
// =============================================================================

begin
  _mezoss := FejQuery.fieldByNAme('MEZOSS').asInteger;
  Mezosource.Enabled := False;

  _pcs := 'UPDATE EXCELDATA SET FLAG=0' + _sorveg;
  _pcs := _pcs + 'WHERE MEZOSS=' + inttostr(_mezoss);
  ExcelParancs(_pcs);
  MezotablaOpen;
  FejtablaOpen;
  Activecontrol := Fejracs;
end;

// =============================================================================
          procedure TForm2.EXCELMEGSEMFOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
            procedure TForm2.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
   _OWB := unassigned;
   _oxl.quit;
   _oxl := unassigned;

   Killexcel;
   Modalresult := 1;
end;
end.
