unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Comobj, unit1;

type
  TMAKEEXCEL = class(TForm)
    Button1: TButton;
    
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KorzetExcelFejlec;
    procedure ExceladatFeltoltes;
    procedure FiveAnalyLine;
    procedure SorKikockazas(_start: byte);
    procedure MegnevezesSor(_ss: byte; _mn: string);
    procedure ErtekTarsor;
    procedure Elemzessor;
    procedure TervezSor;
    procedure Kozosjavaslat;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAKEEXCEL: TMAKEEXCEL;
  _oxl,_owb,_range: variant;
  _aktkorzetnev,_aktptnev: string;
  _y,_aktkorzetdb,_aktptszam,_aktkonkdb,_konkss: byte;
  _prisor : integer;


implementation

{$R *.dfm}

procedure TMAKEEXCEL.Button1Click(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TMAKEEXCEL.FormActivate(Sender: TObject);

var i: byte;

begin
   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add[1];

   // ---  A 9 fül létrehozása és elnevezése, sor fagyasztása ------------------

   _oxl.workbooks[1].sheets.add(,,9);

   for i := 1 to 8 do
     begin
       _aktkorzetNev := _korzetnevek[i]+'I KÖRZET';
       _oxl.workbooks[1].worksheets[i].name := _aktkorzetNev;
       _oxl.workbooks[1].worksheets[I].select;
       _range := _oxl.range['A5','A5'];
       _range.select;
       _oxl.Activewindow.FreezePanes := True;
     end;
   _oxl.workbooks[1].worksheets[9].name := 'ZÁLOG';

  _oxl.workbooks[1].worksheets[9].select;
  _range := _oxl.range['A5','A5'];
  _range.select;
  _oxl.Activewindow.FreezePanes := True;

   _korzetindex := 1;
   while _korzetindex<=9 do
     begin
       _aktkorzetnev := _korzetnevek[_korzetindex];
       _aktKorzetDarab := _korzetPtdb[_korzetindex];

       KorzetExcelFejlec;
     //  ExcelAdatFeltoltes;

       inc(_korzetindex);
     end;

   _oxl.visible := true;  

end;


procedure TMakeExcel.KorzetExcelFejlec;

begin
  _oxl.worksheets[_korzetindex].range['A1:A1'].Columnwidth := 10;
  _oxl.worksheets[_korzetindex].range['B1:B1'].Columnwidth := 32;
  _oxl.worksheets[_korzetindex].range['C1:C1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['D1:D1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['E1:E1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['F1:F1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['G1:G1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['H1:H1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['I1:I1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['J1:J1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['K1:K1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['L1:L1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['M1:M1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['N1:N1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['O1:O1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['P1:P1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['Q1:Q1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['R1:R1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['S1:S1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['T1:T1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['U1:U1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['V1:V1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['W1:W1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['X1:X1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['Y1:Y1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['Z1:Z1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['AA1:AA1'].Columnwidth := 9;
  _oxl.worksheets[_korzetindex].range['AB1:AB1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['AC1:AC1'].Columnwidth := 12;
  _oxl.worksheets[_korzetindex].range['AD1:AD1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AE1:AE1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AF1:AF1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AG1:AG1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AH1:AH1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AI1:AI1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AJ1:AJ1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AK1:AK1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AL1:AL1'].Columnwidth := 23;
  _oxl.worksheets[_korzetindex].range['AM1:AM1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AN1:AN1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AO1:AO1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AP1:AP1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AQ1:AQ1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AR1:AR1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AS1:AS1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AT1:AT1'].Columnwidth := 8;
  _oxl.worksheets[_korzetindex].range['AU1:AU1'].Columnwidth := 23;

  _rangestr := 'A1:H1';
  _oxl.worksheets[_korzetindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.italic := True;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Size := 16;
  _oxl.worksheets[_korzetindex].cells[1,1] := _aktkorzetnev;

  _rangestr := 'A2:AU4';

  _oxl.worksheets[_korzetindex].range[_rangestr].Font.NAme := 'Arial CE';
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := False;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.italic := False;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Size := 10;
  _oxl.worksheets[_korzetindex].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetindex].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_korzetindex].range[_rangestr].Wraptext := True;
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.Colorindex := 35;

  _rangestr := 'A2:A4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);
  _oxl.worksheets[_korzetindex].cells[2,1] := 'PÉNZTÁR SZÁMA';

  _rangestr := 'B2:B4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);
  _oxl.worksheets[_korzetindex].cells[2,2] := 'PÉNZTÁR NEVE';

  // =================== HAVI VALUTAVÁLTÁS =================================

  _rangestr := 'C2:H2';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);
  _oxl.worksheets[_korzetindex].cells[2,3] := '2015 SZEPTEMBER HAVI VALUTAVÁLTÁS';

  _rangestr := 'C3:D3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,3] := 'VÉTEL';
  _oxl.worksheets[_korzetindex].cells[4,3] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,4] := 'Forint';

  _oxl.worksheets[_korzetindex].range['C4:C4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['C3:D4'].BorderAround(1,4);

  _rangestr := 'E3:F3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,5] := 'ELADÁS';
  _oxl.worksheets[_korzetindex].cells[4,5] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,6] := 'Forint';

  _oxl.worksheets[_korzetindex].range['E4:E4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['E3:F4'].BorderAround(1,4);

  _rangestr := 'G3:H3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,7] := 'ÖSSZESEN';
  _oxl.worksheets[_korzetindex].cells[4,7] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,8] := 'Forint';

  _oxl.worksheets[_korzetindex].range['G4:G4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['G3:H4'].BorderAround(1,4);

   // ========== ELŐZŐ  HAVI VÁLTÁSHOZ VISZONYITÁSA =======================

   _rangestr := 'I2:N2';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);
  _oxl.worksheets[_korzetindex].cells[2,9] := 'VALUTAVÁLTÁS ALAKULÁSA ELÖZŐ HÓNAPHOZ KÉPEST %-OS';

  _rangestr := 'I3:J3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,9] := 'VÉTEL';
  _oxl.worksheets[_korzetindex].cells[4,9] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,10] := 'Forint';

  _oxl.worksheets[_korzetindex].range['I4:I4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['I3:J4'].BorderAround(1,4);

  _rangestr := 'K3:L3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,11] := 'ELADÁS';
  _oxl.worksheets[_korzetindex].cells[4,11] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,12] := 'Forint';

  _oxl.worksheets[_korzetindex].range['K4:K4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['K3:L4'].BorderAround(1,4);

  _rangestr := 'M3:N3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,13] := 'ÖSSZESEN';
  _oxl.worksheets[_korzetindex].cells[4,13] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,14] := 'Forint';

  _oxl.worksheets[_korzetindex].range['M4:M4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['M3:N4'].BorderAround(1,4);

   // ============== VALUTAVÁLTÁS ELŐZŐ ÉVHEZ KÉPEST ===========================

  _rangestr := 'O2:T2';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);
  _oxl.worksheets[_korzetindex].cells[2,15] := 'VALUTAVÁLTÁS ALAKULÁSA ELÖZŐ ÉVHEZ KÉPEST %-OS';

  _rangestr := 'O3:P3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,15] := 'VÉTEL';
  _oxl.worksheets[_korzetindex].cells[4,15] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,16] := 'Forint';

  _oxl.worksheets[_korzetindex].range['O4:O4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['O3:P4'].BorderAround(1,4);

  _rangestr := 'Q3:R3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,17] := 'ELADÁS';
  _oxl.worksheets[_korzetindex].cells[4,17] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,18] := 'Forint';

  _oxl.worksheets[_korzetindex].range['Q4:Q4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['Q3:R4'].BorderAround(1,4);

  _rangestr := 'S3:T3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[3,19] := 'ÖSSZESEN';
  _oxl.worksheets[_korzetindex].cells[4,19] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,20] := 'Forint';

  _oxl.worksheets[_korzetindex].range['S4:S4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['S3:T4'].BorderAround(1,4);

  // ================= WESTERN UNION ======================================

  _rangestr := 'U2:W3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,21] := '2015 SZEPTEMBER     WESTERN UNION';

  _oxl.worksheets[_korzetindex].cells[4,21] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,22] := 'HUF';
  _oxl.worksheets[_korzetindex].cells[4,23] := 'USD';

  _oxl.worksheets[_korzetindex].range['U4:U4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['W4:W4'].BorderAround(1,2);

  // ============== WU ELÖZŐ HÓNAPHOZ KÉPEST ===================================

  _rangestr := 'X2:Z3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,24] := 'WESTERN UNION ALAKULÁSA ELÖZŐ HÓNAPHOZ KÉPEST %-OS';

  _oxl.worksheets[_korzetindex].cells[4,24] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,25] := 'HUF';
  _oxl.worksheets[_korzetindex].cells[4,26] := 'USD';

  _oxl.worksheets[_korzetindex].range['X4:X4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['Z4:Z4'].BorderAround(1,2);

   // ============= WU ELÖZÖ ÉVHEZ KÉPEST ======================================

  _rangestr := 'AA2:AC3';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,27] := 'WESTERN UNION ALAKULÁSA ELÖZŐ ÉVHEZ KÉPEST %-OS';

  _oxl.worksheets[_korzetindex].cells[4,27] := 'Ügyfél';
  _oxl.worksheets[_korzetindex].cells[4,28] := 'HUF';
  _oxl.worksheets[_korzetindex].cells[4,29] := 'USD';

  _oxl.worksheets[_korzetindex].range['AA4:AA4'].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].range['AC4:AC4'].BorderAround(1,2);

  _oxl.worksheets[_korzetindex].range['U4:W4'].BorderAround(1,4);
  _oxl.worksheets[_korzetindex].range['X4:Z4'].BorderAround(1,4);
  _oxl.worksheets[_korzetindex].range['AA4:AC4'].BorderAround(1,4);

  // ================= BRUTTO HASZON ===========================================

  _rangestr := 'AD2:AD4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,30] := '2015 SZEPTEMBERI  BRUTTÓ HASZON';

  // ===================HASZON ELÖZŐ HÓNAPHOZ KÉPEST ===========================

  _rangestr := 'AE2:AE4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,31] := 'BRUTTÓ HASZON ALAKULÁSA ELÖZŐ HÓNAPHOZ KÉPEST';

 // =================== HASZON ELÖZÖ ÉVHEZ KÉPEST ==============================

  _rangestr := 'AF2:AF4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,32] := 'BRUTTÓ HASZON ALAKULÁSA ELÖZŐ ÉVHEZ KÉPEST';

 // =================== KEZELÉSI DÍJ ===========================================

  _rangestr := 'AG2:AG4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,33] := '2015 SZEPTEMBER HAVI KEZELÉSI DÍJ';

  // =================== KEZELÉSI DÍJ ELÖZŐ HÓNAPHOZ KÉPEST ====================

  _rangestr := 'AH2:AH4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,34] := 'KEZELÉSI DÍJ ALAKULÁSA ELÖZŐ HÓNAPHOZ KÉPEST %';


  // =================== KEZELÉSI DÍJ ELÖZŐ ÉVHEZ KÉPEST ====================

  _rangestr := 'AI2:AI4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,35] := 'KEZELÉSI DÍJ ALAKULÁSA ELÖZŐ ÉVHEZ KÉPEST %';


  // =================== TRANZAKCIÓS DÍJ ===========================================

  _rangestr := 'AJ2:AJ4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,36] := '2015 SZEPTEMBER TRANZAKCIÓS ADÓ';

  // =================== TRANZ ADÓ ELÖZŐ HÓNAPHOZ KÉPEST ====================

  _rangestr := 'AK2:AK4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,37] := 'TRANZAKCIÓS ADÓ ALAKULÁSA ELÖZŐ HÓNAPHOZ KÉPEST %';


  // =================== TRANZ ADÓ ELÖZŐ ÉVHEZ KÉPEST ====================

  _rangestr := 'AL2:AL4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,38] := 'TRANZAKCIÓS ADÓ ALAKULÁSA ELÖZŐ ÉVHEZ KÉPEST %';

  // ==================== KONKURENCIA ==========================================

  _rangestr := 'AM2:AP4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,39] := 'KONKURENCIA';

  // ==================== KONKURENCIA KK =======================================

  _rangestr := 'AQ2:AT4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,43] := 'KONKURENCIA KK (változás esetén alá kell irni a változást)';

  // ==================== KONKURENCIA EXK ======================================

  _rangestr := 'AU2:AU4';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,4);

  _oxl.worksheets[_korzetindex].cells[2,47] := 'EXK KK (javaslat esetén alá kell irni a változást)';

  // ===========================================================================
  //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

  _rangestr := 'A5:AU6';
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzetindex].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_korzetindex].range[_rangestr].INTERIOR.color := clWhite;
  _long := 'A rendelkezésre álló adatok alapján fiókonként itt szükséges bemutatni az adott hónapra vonatkozó forgalmi adatok alakulását.';
  _long := _long + ' Az elöző év ugyanazon hónapjával összehasonlitva a változások (+/-) okait is szükséges szerepeltetni.';
  _oxl.worksheets[_korzetindex].cells[5,1] := _long;

  // ===========================================================================


  _y := 1;
  _prisor := 6;
  while _y<=_aktkorzetdarab do
    begin
      inc(_prisor);
      _aktPtSzam := _korzetPtszamSor[_korzetindex,_y];
      _aktptNev := _penztarnev[_aktptszam];

      _oxl.worksheets[_korzetindex].cells[_prisor,1].HorizontalAlignment := -4108;
      _rangestr := 'A'+inttostr(_prisor)+':B'+inttostr(_prisor);
      _oxl.worksheets[_korzetindex].range[_rangestr].font.size :=12;
      _oxl.worksheets[_korzetindex].range[_rangestr].font.bold := true;

      _oxl.worksheets[_korzetindex].cells[_prisor,1] := inttostr(_aktptszam);
      _oxl.worksheets[_korzetindex].cells[_prisor,2] := _aktptnev;
      _rangestr := 'A'+inttostr(_prisor)+':AU'+inttostr(_prisor);
      _oxl.worksheets[_korzetindex].range[_rangestr].Interior.Colorindex := 35;

      // Adatsorfeltoltes

      SorKikockazas(1);
      FiveAnalyLine;
      inc(_y);
    end;

  inc(_prisor);

  _rangestr := 'A' + inttostr(_prisor)+':B' + inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Size := 12;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzetindex].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetindex].range[_rangestr].BorderAround(1,2);
  _oxl.worksheets[_korzetindex].cells[_prisor,1] := 'ÖSSZESEN';

  _rangestr := 'A' + inttostr(_prisor)+':AU' + inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.Colorindex := 35;
  Sorkikockazas(3);


  // ========================================================================
  // ========================================================================

  MegnevezesSor(1,'Értéktár összefoglaló elemzés');
  ertektarsor;

  // ------------------------------------------------------------------------

  MegnevezesSor(2,'A közelben található konkurens valutaváltókkal kapcsolatos tényadatok (ügyfélszám, árfolyam, bizonylatolási módszerek, próbaváltások tapasztalatai) szerepeltetése, valamint a kapcsolódó javaslatok megfogalmazása itt kell hogy megtörténjen.');

  _aktKonkdb := _konkdb[_korzetindex];
  _y := 1;
  while _y<=_aktkonkdb do
    begin
      inc(_prisor);
      _rangestr := 'B'+inttostr(_prisor)+':AU'+inttostr(_prisor);
      _oxl.worksheets[_korzetindex].range[_rangestr].Font.size := 12;
      _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := False;
      _oxl.worksheets[_korzetindex].range[_rangestr].Interior.colorindex := 19;

      _rangestr := 'C'+inttostr(_prisor)+':AU'+inttostr(_prisor);
      _oxl.worksheets[_korzetindex].range[_rangestr].Mergecells := True;
      _konkss := _kkonk[_korzetindex,_y];
      _oxl.worksheets[_korzetindex].cells[_prisor,2] := _konk[_konkss];
      inc(_y);
    end;

  Megnevezessor(3,'Az adott hónapra vonatkozó árfolyam-stratégiával kapcsolatos tapasztalatokat, ügyfél-visszajelzéseket valamint javaslatok');
  ErtektarSor;
  TervezSor;

  MegnevezesSor(4,'Valuta programmal kapcsolatos javaslatok');
  ErtektarSor;
  TervezSor;

  MegnevezesSor(5,'A területen dolgozó pénztárosok, valamint a szállítók munkájának értékelése, különös tekintettel a hozzállásra. Pozitívumokat, illetve az esetleges hibákat is. ');
  ErtektarSor;
  TervezSor;

  Megnevezessor(6,'Eseti jutalmak, büntetések (minden esetben indoklással )');
  ErtektarSor;
  TervezSor;

  MegnevezesSor(7,'Fiók nyitási vagy zárási javaslatok,indokkal');
  ErtektarSor;
  TervezSor;

  MegnevezesSor(8,'Működést javító ötletek,fejlesztési - vagy költség-takarékossági ötletek');
  ErtektarSor;
  TervezSor;

  Megnevezessor(9,'Iroda – értéktár – területi vezetői együttműködés: A központi irányítás (iroda), az értéktár és a területi vezetők együttműködésével kapcsolatos rövid beszámoló, az adott hónap vonatkozásában.');
  ErtektarSor;
  TervezSor;

  MegnevezesSor(10,'Főértéktárral való együttműködés: Ebben a pontban szükséges részletezni a főértéktárosokkal kapcsolatos együttműködés adott hónapra vonatkozó rövid értékelését');
  ErtektarSor;
  TervezSor;

  MegnevezesSor(11,'Egyéb');
  Kozosjavaslat;
end;

procedure TmakeExcel.MegnevezesSor(_ss: byte; _mn: string);

begin
  inc(_prisor);

  _rangestr := 'B' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _rangestr := 'A' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.size := 10;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzetindex].cells[_prisor,1].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetindex].cells[_prisor,1] := inttostr(_ss)+'.';
  _oxl.worksheets[_korzetindex].cells[_prisor,2] := _mn;
end;


procedure TmakeExcel.Ertektarsor;

begin
  inc(_prisor);
  _rangestr := 'B' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := False;
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.Colorindex := 19;

  _rangestr := 'C' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'ÉRTÉKTÁR';
end;

procedure TmakeExcel.ElemzesSor;

begin
  inc(_prisor);
  _rangestr := 'B' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := False;
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.Colorindex := 34;

  _rangestr := 'C' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'elemzés TV';
end;


procedure TmakeExcel.TervezSor;

begin
  inc(_prisor);
  _rangestr := 'B' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := False;
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.Colorindex := 34;

  _rangestr := 'C' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'Területi vezetés';
end;


procedure TmakeExcel.KozosJavaslat;

begin
  inc(_prisor);
  _rangestr := 'B' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_korzetindex].range[_rangestr].Font.Bold := False;
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.Colorindex := 34;

  _rangestr := 'C' + inttostr(_prisor)+':AU' +inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'Közös javaslat';
end;











procedure TMakeExcel.FiveAnalyLine;

begin
  inc(_prisor);
  _rangestr := 'A' + inttostr(_prisor)+':A'+ inttostr(_prisor+4);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _rangestr := 'C' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _rangestr := 'B' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.colorIndex := 19; // sárga
  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'Elemzés ÉT';

  inc(_prisor);

  _rangestr := 'C' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _rangestr := 'B' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.colorIndex := 34; // vilkék
  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'Elemzés TV';

  inc(_prisor);

  _rangestr := 'C' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _rangestr := 'B' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.colorIndex := 37; // sötkék
  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'Közös javaslat';

  inc(_prisor);

  _rangestr := 'C' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _rangestr := 'B' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.colorIndex := 38; // vilpir
  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'Ellenörzések eredménye FZS';

  inc(_prisor);

  _rangestr := 'C' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].MergeCells := true;

  _rangestr := 'B' + inttostr(_prisor)+':AU'+ inttostr(_prisor);
  _oxl.worksheets[_korzetindex].range[_rangestr].Interior.colorIndex := 22; // sötpir
  _oxl.worksheets[_korzetindex].cells[_prisor,2] := 'Ügyvezetői hozzáfűzés';
end;


// =============================================================================
                    procedure TMakeExcel.ExcelAdatFeltoltes;
// =============================================================================


begin

   ShowMessage('ADATFELTOLTES');

 
end;


procedure TmakeExcel.Sorkikockazas(_start: byte);

var _z: byte;

begin
  _z := _start;
  while _z<=47 do
    begin
      _oxl.worksheets[_korzetindex].cells[_prisor,_z].BorderAround(1,2);
      inc(_z);
    end;
end;



end.
