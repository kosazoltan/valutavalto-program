unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, unit1, Comobj,
  StdCtrls, Buttons, ComCtrls, IBTable, ExtCtrls;

type
  TMAKEEXCEL = class(TForm)
    PENZTARTABLA: TIBTable;
    PENZTARTRANZ: TIBTransaction;
    PENZTARDBASE: TIBDatabase;
    PENZTAROSTABLA: TIBTable;
    PENZTAROSDBASE: TIBDatabase;
    PENZTAROSTRANZ: TIBTransaction;
    Label1: TLabel;
    csik: TProgressBar;
    KILEPO: TTimer;
    KILEPOGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure DarabBeolvasas;
    procedure ExcelTablaKeszites;
    procedure KorzetMunkalapTabla;
    procedure ExcelAdatFeltoltes;

    procedure FormCreate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure KILEPOGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAKEEXCEL: TMAKEEXCEL;
  _formula,_KNEV,_rangestr,_aktptarnev,_aktprosid,_aktprosnev: string;
  _akteforg,_aktaforg: real;
  _OXL,_OWB,_RANGE: OleVariant;
  _kzptdb,_kzprosdb:array[1..8] of byte;
  _korzetindex,_KORZETPTDARAB,_KORZETPROSDARAB,_lastptline,_focim2sor: byte;
  _qq,_lastprosline,_xsor,_aktptarnum: integer;

implementation

{$R *.dfm}

// =============================================================================
               procedure TMakeExcel.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := _top +108;
  Left := _left +228;
  width := 423;
  Height := 232;

  Form1.Repaint;

  MakeExcel.Repaint;


  DarabBeolvasas;
  Exceltablakeszites;
  kILEPOGOMB.Visible := TRUE;
end;


// =============================================================================
                     procedure TMakeExcel.DarabBeolvasas;
// =============================================================================

var i,_kz: integer;

begin
  for i := 1 to 8 do
    begin
      _kzptdb[i] := 0;
      _kzprosdb[i] := 0;
    end;

  PenztarDbase.Connected := true;
  PenztarTabla.Open;
  Penztartabla.First;
  _aktkorzet := 1;
  while not penztarTabla.Eof do
    begin
      _kz := PenztarTabla.FieldByName('KORZET').asInteger;
      if _kz=_aktkorzet then
        begin
          _kzptdb[_kz] := _kzptdb[_kz] + 1;
        end else
        begin
          _aktkorzet := _kz;
          _kzptdb[_kz] := 1;
        end;
      PenztarTabla.Next;
    end;
  PenztarTabla.close;
  PenztarDbase.close;

  // ---------------------------------------------------------------------------

  PenztarosDbase.Connected := true;
  PenztarosTabla.Open;
  Penztarostabla.First;
  _aktkorzet := 1;
  while not penztarosTabla.Eof do
    begin
      _kz := PenztarosTabla.FieldByName('KORZET').asInteger;
      if _kz=_aktkorzet then
        begin
          _kzprosdb[_kz] := _kzprosdb[_kz] + 1;
        end else
        begin
          _aktkorzet := _kz;
          _kzprosdb[_kz] := 1;
        end;
      PenztarosTabla.Next;
    end;
  PenztarosTabla.close;
  PenztarosDbase.close;
end;


// =============================================================================
                   procedure TMakeExcel.ExcelTablakeszites;
// =============================================================================

begin

   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add[1];

   // ---  A 9 fül létrehozása és elnevezése ------------------

   _oxl.workbooks[1].sheets.add(,,9);

   _korzetIndex := 1;
   while _korzetindex<=8 do
     begin
       _kNev := _korzetnevek[_korzetIndex];

       _oxl.workbooks[1].worksheets[_korzetindex].name := _kNev;
       _oxl.workbooks[1].worksheets[_korzetindex].select;

       _korzetPtdarab   := _kzptdb[_korzetindex];
       _korzetProsdarab := _kzprosDb[_korzetindex];

       KorzetmunkalapTabla;
       inc(_korzetindex);
     end;

  ExcelAdatFeltoltes;

  Csik.Visible := False;
  _oxl.visible := True;
end;


// =============================================================================
                 procedure TMakeExcel.KorzetMunkalapTabla;
// =============================================================================

begin
  _oxl.workSheets[_korzetIndex].Range['A1:A1'].columnWidth := 10;
  _oxl.worksheets[_korzetIndex].Range['B1:B1'].columnWidth := 12;
  _oxl.worksheets[_korzetIndex].Range['C1:C1'].columnWidth := 40;
  _oxl.worksheets[_korzetIndex].Range['D1:D1'].columnWidth := 24;
  _oxl.worksheets[_korzetIndex].Range['E1:E1'].columnWidth := 24;
  _oxl.worksheets[_korzetIndex].Range['F1:F1'].columnWidth := 18;
  _oxl.worksheets[_korzetIndex].Range['G1:G1'].columnWidth := 14;

  _rangestr := 'B2:G2';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 18;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Italic := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;

  _oxl.worksheets[_korzetIndex].Cells[2,2] := _knev+ ' KÖRZET VERSENYADATAI';

  _rangestr := 'B3:G3';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 18;

  _rangestr := 'B4:G4';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 14;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Italic := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;

  _oxl.worksheets[_korzetIndex].Cells[4,2] := 'PÉNZTÁRAK HELYEZÉSEI';

  _rangestr := 'B5:G5';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 14;

  _lastptLine := 8 + _korzetPtDarab;
  _rangestr := 'C8:C'+inttostr(_lastptline-1);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 11;


  _rangestr := 'B6:C6';
  _oxl.workSheets[_korzetIndex].Range['B6:C6'].Mergecells := true;
  _oxl.workSheets[_korzetIndex].Range['D6:E6'].mergecells := True;
  _oxl.workSheets[_korzetIndex].Range['B6:G7'].Font.Name  := 'Timer New Roman';
  _oxl.workSheets[_korzetIndex].Range['B6:G7'].Font.Bold  := True;
  _oxl.workSheets[_korzetIndex].Range['B6:G7'].Font.Italic:= True;

  _oxl.workSheets[_korzetIndex].Range['B6:E6'].Font.Size := 12;
  _oxl.workSheets[_korzetIndex].Range['B7:E7'].Font.Size := 10;

  _oxl.workSheets[_korzetIndex].Range['F6:F7'].Mergecells := True;
  _oxl.workSheets[_korzetIndex].Range['G6:G7'].Mergecells := True;

  _oxl.worksheets[_korzetindex].Range['F6:F7'].Wraptext := True;
  _oxl.workSheets[_korzetIndex].Range['B6:G7'].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range['B6:G7'].VerticalAlignment := -4108;


  _oxl.worksheets[_korzetIndex].Cells[6,2] := 'PÉNZTÁR';
  _oxl.worksheets[_korzetIndex].Cells[6,4] := 'FORGALOM';
  _oxl.worksheets[_korzetIndex].Cells[7,2] := 'SZÁMA';
  _oxl.worksheets[_korzetIndex].Cells[7,3] := 'MEGNEVEZÉSE';
  _oxl.worksheets[_korzetIndex].Cells[7,4] := _multevhos;
  _oxl.worksheets[_korzetIndex].Cells[7,5] := _aktevhos;

  _oxl.worksheets[_korzetIndex].Cells[6,6] := 'SZÁZALÉKOS NÕVEKEDÉS';
  _oxl.worksheets[_korzetIndex].Cells[6,7] := 'HELYEZÉS';

  _rangeStr := 'B'+inttostr(_lastptline)+':C'+inttostr(_lastptline);
  _oxl.worksheets[_korzetindex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := true;
  _oxl.worksheets[_korzetindex].Cells[_lastptline,2] := 'ÖSSZESEN';
  _oxl.worksheets[_korzetindex].Cells[_lastptline,2].Font.Name := 'Times New Roman';
  _oxl.worksheets[_korzetindex].Cells[_lastptline,2].Font.Bold := True;
  _oxl.worksheets[_korzetindex].Cells[_lastptline,2].Font.Italic := True;
  _oxl.worksheets[_korzetindex].Cells[_lastptline,2].Font.Size := 12;


  _formula := '=sum(D8:D'+inttostr(_lastptline-1)+')';
  _oxl.worksheets[_korzetIndex].Cells[_lastptline,4].formula := _formula;

  _formula := '=sum(E8:E'+inttostr(_lastptline-1)+')';
  _oxl.worksheets[_korzetIndex].Cells[_lastptline,5].formula := _formula;

  _formula := '=100*(E'+inttostr(_lastptline)+'/D'+inttostr(_lastptline)+')';
  _oxl.worksheets[_korzetIndex].Cells[_lastptline,6].formula := _formula;

  _oxl.worksheets[_korzetindex].Cells[_lastptline,7].Interior.color := clGray;



  // ===========================================================================

  _foCim2Sor := _lastPtLine + 4;
  _rangestr := 'B' + inttostr(_focim2Sor)+':G' + inttostr(_focim2sor);

  _oxl.worksheets[_korzetindex].Cells[_focim2sor,2] := 'PÉNZTÁROSOK HELYEZÉSEI';
  _oxl.worksheets[_korzetindex].Range[_rangestr].Mergecells := true;
  _oxl.worksheets[_korzetindex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetindex].Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.worksheets[_korzetindex].Range[_rangestr].Font.Size := 14;
  _oxl.worksheets[_korzetindex].Range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzetindex].Range[_rangestr].Font.Italic := True;

  // ------------------ BORDERS ------------------------------------------------

  _rangestr := 'B6:G'+inttostr(_lastPtLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Borders.LineStyle := 1;

  _oxl.worksheets[_korzetIndex].Range['B6:G7'].BorderAround(1,3);

  _rangestr := 'D6:D'+inttostr(_lastPtLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,2);

  _rangestr := 'E6:E'+inttostr(_lastPtLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,2);

  _rangestr := 'F6:F'+inttostr(_lastPtLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,2);

  _rangestr := 'B'+inttostr(_lastPtLine)+':G'+ inttostr(_lastPtLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,3);

  _rangestr := 'B6:G'+inttostr(_lastPtLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,3);


  // ---------------------------------------------------------------------------

  _lastProsLine := _focim2Sor + 3 + _korzetProsDarab;
  _rangestr := 'D'+inttostr(_focim2sor+2)+':E'+inttostr(_lastProsLine);

  _rangestr := 'B'+inttostr(_focim2sor+2)+':E'+inttostr(_focim2sor+2);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 12;

  _rangestr := 'B'+inttostr(_focim2sor+3)+':E'+inttostr(_focim2sor+3);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 10;

  _rangestr := 'B' + inttostr(_focim2sor+2)+':C' + inttostr(_focim2sor+2);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := true;

  _rangestr := 'D' + inttostr(_focim2sor+2)+':E' + inttostr(_focim2sor+2);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := true;

  _rangestr := 'B' + inttostr(_focim2sor+2)+':G' + inttostr(_focim2sor+2);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Italic := True;

  _rangestr := 'F' + inttostr(_focim2sor+2)+':F' + inttostr(_focim2sor+3);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := true;

  _rangestr := 'G' + inttostr(_focim2sor+2)+':G' + inttostr(_focim2sor+3);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := true;

  _rangestr := 'F'+inttostr(_focim2sor+2)+':G'+inttostr(_focim2sor+3);
  _oxl.worksheets[_korzetindex].Range[_rangestr].Font.size := 12;

  _rangestr := 'F' + inttostr(_focim2sor+2)+':F'+inttostr(_focim2sor+3);
  _oxl.worksheets[_korzetindex].Range[_rangestr].Wraptext := True;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].VerticalAlignment := -4108;

  _rangestr := 'G' + inttostr(_focim2sor+2)+':G'+inttostr(_focim2sor+3);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].VerticalAlignment := -4108;

  _rangestr := 'F' + inttostr(_focim2sor+2)+':G'+inttostr(_focim2sor+3);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size := 10;

  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+2,2] := 'PÉNZTÁROS';
  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+2,4] := 'FORGALOM';
  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+2,6] := 'SZÁZALÉKOS NÕVEKEDÉS';
  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+2,7] := 'HELYEZÉS';


  _rangestr := 'B' + inttostr(_focim2sor+3)+':E' +inttostr(_focim2sor+3);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Italic := true;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Bold := true;

  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+3,2] := 'ID-KÓDJA';
  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+3,3] := 'NEVE';
  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+3,4] := _multhos;
  _oxl.workSheets[_korzetIndex].Cells[_focim2sor+3,5] := _aktevhos;

  _rangestr := 'C8:C' +inttostr(_lastPtLine);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Size := 11;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Italic := true;

  _rangestr := 'C' + inttostr(_focim2sor+4)+':C' +inttostr(_lastProsLine);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Size := 11;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Font.Italic := true;

  // ------------------ BORDERS ------------------------------------------------

  _rangestr := 'B'+inttostr(_focim2sor+2)+':G'+inttostr(_lastProsLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Borders.LineStyle := 1;

  _rangestr := 'B' + inttostr(_focim2sor+2)+':G'+ inttostr(_focim2sor+3);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,3);

  _rangestr := 'D'+inttostr(_focim2sor+2)+':D'+inttostr(_lastProsLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,2);

  _rangestr := 'E'+inttostr(_focim2sor+2)+':E'+inttostr(_lastProsLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,2);

  _rangestr := 'F'+inttostr(_focim2sor+2)+':F'+inttostr(_lastProsLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,2);

  _rangestr := 'B'+inttostr(_focim2sor+2)+':G'+inttostr(_lastProsLine);
  _oxl.worksheets[_korzetIndex].Range[_rangestr].BorderAround(1,3);

  // ---------------------------------------------------------------------------

  _rangestr := 'B8:B' + inttostr(7+_korzetptdarab);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'B' + inttostr(_focim2sor+4)+':B'+inttostr(_focim2sor+3+_korzetprosdarab);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;

  // ---------------------------------------------------------------------------

  _rangestr := 'D8:E'+inttostr(_lastPtLine);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Numberformat := '### ### ### ###0[$ Ft]';

  _rangestr := 'F8:F'+inttostr(_lastPtLine);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Numberformat := '###,###0[$ %]';

  _rangestr := 'G8:G'+inttostr(_lastPtLine-1);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;

  // ---------------------------------------------------------------------------

  _rangestr := 'D'+ inttostr(_focim2sor+4)+':E'+inttostr(_lastProsLine);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Numberformat := '### ### ### ###0[$ Ft]';

  _rangestr := 'F' + inttostr(_focim2sor+4)+':F'+inttostr(_lastProsLine);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.workSheets[_korzetIndex].Range[_rangestr].Numberformat := '###,###0[$ %]';

  _rangestr := 'G' + inttostr(_focim2sor+4)+':G'+inttostr(_lastProsLine);
  _oxl.workSheets[_korzetIndex].Range[_rangestr].HorizontalAlignment := -4108;
end;

// =============================================================================
                    procedure TMakeExcel.ExcelAdatFeltoltes;
// =============================================================================


var _akorzet,_helyezes: integer;
    _szazalek: real;

begin
  PenztarDbase.connected := True;

  PenztarTabla.Open;
  PenztarTabla.First;

  Csik.Max := 8;
  _korzetindex := 1;
  _qq := 1;
  while not PenztarTabla.Eof do
    begin
      _akorzet := PenztarTabla.FieldByName('KORZET').asInteger;
      if _akorzet>_korzetindex then
        begin
          _korzetindex := _akorzet;
          Csik.Position := _aKorzet;
          _qq := 1;
        end;

      _xsor := _qq + 7;

      with PenztarTabla do
        begin
          _aktptarnum := Fieldbyname('PENZTARSZAM').asInteger;
          _aktptarnev := trim(FieldByName('PENZTARNEV').AsString);
          _akteforg   := FieldByName('ELOZOEVIFORGALOM').asFloat;
          _aktaforg   := FieldByName('EHAVIFORGALOM').asFloat;
          _helyezes   := Fieldbyname('HELYEZES').asInteger;
          _szazalek   := FieldByName('SZAZALEK').asFloat;
        end;

      _oxl.workSheets[_korzetIndex].cells[_xsor,2] := inttostr(_aktptarnum);
      _oxl.workSheets[_korzetIndex].cells[_xsor,3] := _aktptarnev;
      _oxl.workSheets[_korzetIndex].cells[_xsor,4] := Form1.RealToStr(_akteforg);
      _oxl.workSheets[_korzetIndex].cells[_xsor,5] := Form1.RealToStr(_aktaforg);
      _oxl.workSheets[_korzetIndex].cells[_xsor,6] := Form1.RealToStr(_szazalek);
      _oxl.worksheets[_korzetIndex].Cells[_xsor,7] := _helyezes;

      if _helyezes<4 then
        begin
          _oxl.workSheets[_korzetIndex].Cells[_xsor,3].font.color := clred;
           _oxl.workSheets[_korzetIndex].Cells[_xsor,3].font.Bold := True;
          _oxl.worksheets[_korzetindex].Cells[_xsor,7].font.color := clRed;
          _oxl.worksheets[_korzetindex].Cells[_xsor,7].font.Bold := true;
        end;

      inc(_qq);
      PenztarTabla.Next;
    end;

  PenztarTabla.Close;
  PenztarDbase.close;

  // ---------------------------------------------------------------------------

  PenztarosDbase.connected := True;
  PenztarosTabla.Open;
  PenztarosTabla.First;
  Csik.Max := 8;

  _korzetindex := 1;
  _qq := 1;
  while not PenztarosTabla.Eof do
    begin
      _akorzet := PenztarosTabla.FieldByName('KORZET').asInteger;
      if _akorzet>_korzetindex then
        begin
          _korzetindex := _akorzet;
          Csik.Position := _aKorzet;
          _qq := 1;
        end;

      _korzetPtDarab := _kzptdb[_korzetindex];
      _lastptLine:= 8 + _korzetPtDarab;
      _foCim2Sor := _lastPtLine + 4;

      _xSor := _focim2sor + 3 + _qq;
      with PenztarosTabla do
        begin
          _aktprosid  := FieldByName('IDKOD').asString;
          _aktprosnev := trim(FieldByNAme('PENZTAROSNEV').AsString);
          _akteforg := FieldByName('ELOZOHAVIFORGALOM').asFloat;
          _aktaforg := FieldByNAme('EHAVIFORGALOM').asFloat;
          _szazalek := FieldByName('SZAZALEK').asFloat;
          _helyezes := FieldByName('HELYEZES').asInteger;
        end;

      _oxl.workSheets[_korzetIndex].Cells[_xsor,2] := _aktprosid;
      _oxl.workSheets[_korzetIndex].Cells[_xsor,3] := _aktprosnev;
      _oxl.workSheets[_korzetIndex].Cells[_xsor,4] := Form1.RealToStr(_akteforg);
      _oxl.workSheets[_korzetIndex].Cells[_xsor,5] := Form1.RealToStr(_aktaforg);
      _oxl.workSheets[_korzetIndex].Cells[_xsor,6] := Form1.RealToStr(_szazalek);
      _oxl.worksheets[_korzetIndex].Cells[_xsor,7] := inttostr(_helyezes);

      if _helyezes<4 then
        begin
          _oxl.workSheets[_korzetIndex].Cells[_xsor,3].font.color := Clred;
          _oxl.workSheets[_korzetIndex].Cells[_xsor,3].font.Bold := True;
          _oxl.worksheets[_korzetindex].Cells[_xsor,7].font.color := clRed;
          _oxl.worksheets[_korzetindex].Cells[_xsor,7].font.Bold := True;
        end;
      inc(_qq);
      PenztarosTabla.Next;
    end;
  PenztarosTabla.Close;
  PenztarosDbase.close;
end;


// =============================================================================
               procedure TMAKEEXCEL.FormCreate(Sender: TObject);
// =============================================================================

begin
 //  top := _f1top +70;
 // Left := _f1left + 130;

  MakeExcel.Repaint;
end;

procedure TMAKEEXCEL.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  _owb := UnAssigned;
  _oxl.quit;
  _oxl := UnAssigned;
  Application.terminate;
end;

procedure TMAKEEXCEL.KILEPOGOMBClick(Sender: TObject);
begin
  kILEPO.Enabled := TRUE;
end;

end.
