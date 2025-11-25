unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons,ComObj, IBDatabase, DB, IBCustomDataSet,
  IBQuery, TlHelp32, ExtCtrls;

type
  TForm3 = class(TForm)
    GYUJTOQUERY: TIBQuery;
    GYUJTODBASE: TIBDatabase;
    GYUJTOTRANZ: TIBTransaction;
    KILEPO: TTimer;
    Panel1: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure Vastagkeret(_rs: string);
    procedure VekonyKeret(_rs: string);
    procedure KillExcel;
    procedure KILEPOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;
  _oxl,_owb: Olevariant;

  _xAdoszam,_xElozonev,_xLakcim,_xSzuletesihely,_xSzuletesiido: string;
  _xAllampolgar,_xTarthely,_xErdjelleg,_xErdmertek: string;
  _xBizonylatszam: string;
  _mresult : integer;


implementation

uses Unit1;

{$R *.dfm}



procedure TForm3.FormActivate(Sender: TObject);
begin
  _pcs := 'SELECT * FROM GYUJTO' + _sorveg;
  _pcs := _pcs + 'ORDER BY BIZONYLATSZAM';

   Gyujtodbase.Connected := True;
   with GyujtoQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       Last;
       _ugyfeldb := Recno;
       First;
     end;

   if _ugyfeldb=0 then
     begin
       _mresult := -1;
       Kilepo.Enabled := true;
       exit;
     end;

   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add[1];

   _vanexcel := true;

  _oxl.range['A1:A1'].columnwidth := 2;
  _oxl.range['B1:B1'].columnwidth := 8;
  _oxl.range['C1:C1'].columnwidth := 42;
  _oxl.range['D1:D1'].columnwidth := 40;
  _oxl.range['E1:E1'].columnwidth := 14;
  _oxl.range['F1:F1'].columnwidth := 40;
  _oxl.range['G1:G1'].columnwidth := 40;
  _oxl.range['H1:H1'].columnwidth := 40;
  _oxl.range['I1:I1'].columnwidth := 34;
  _oxl.range['J1:J1'].columnwidth := 14;
  _oxl.range['K1:K1'].columnwidth := 28;
  _oxl.range['L1:L1'].columnwidth := 28;
  _oxl.range['M1:M1'].columnwidth := 26;
  _oxl.range['N1:N1'].columnwidth := 22;


  // ---------------------------------------------------------------------------

  _akthonev := trim(_honev[_kertho]);
  _focim := inttostr(_kertev)+' '+_akthonev+' '+inttostr(_kertnap)+'-I JOGISZEMÉLY ÜGYFELEK';

  _rangestr := 'B2:C2';
  _oxl.range[_rangestr].Mergecells := True;
  _oxl.range[_rangestr].Font.Name  := 'Calibri';
  _oxl.range[_rangestr].Font.Size  := 14;
  _oxl.range[_rangestr].Font.Bold  := True;
  _oxl.range[_rangestr].Font.Italic:= True;
  _oxl.cells[2,2] := _focim;

  _rangestr := 'B4:P5';
  _oxl.range[_rangestr].Font.size := 11;
  _oxl.range[_rangestr].Font.Name  := 'Calibri';
  _oxl.range[_rangestr].Font.Bold  := True;
  _oxl.range[_rangestr].Font.Italic:= True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'B4:B5';
  _oxl.range[_rangestr].verticalAlignment := -4108;
  _oxl.range[_rangestr].mergecells := True;
  _oxl.cells[4,2] := 'PÉNZTÁR';

  _rangestr := 'C4:C5';
  _oxl.range[_rangestr].verticalAlignment := -4108;
  _oxl.range[_rangestr].mergecells := True;
  _oxl.cells[4,3] := 'JOGISZEMÉLY MEGNEVEZÉSE';

  _rangestr := 'D4:D5';
  _oxl.range[_rangestr].mergecells := True;
  _oxl.range[_rangestr].verticalAlignment := -4108;
  _oxl.cells[4,4] := 'A TELEPHELY CÍME';

  _rangestr := 'E4:E5';
  _oxl.range[_rangestr].verticalAlignment := -4108;
  _oxl.range[_rangestr].mergecells := True;
  _oxl.cells[4,5] := 'ADÓSZÁMA';

  _rangestr := 'F4:N4';
  _oxl.range[_rangestr].mergecells := True;
  _oxl.cells[4,6] := 'TULAJDONOSOK';

  _oxl.cells[5,6]  := 'NEVE';
  _oxl.cells[5,7]  := 'ELÖZÕ NEVE';
  _oxl.cells[5,8]  := 'LAKCÍME';
  _oxl.cells[5,9]  := 'SZÜLETÉSI HELYE';
  _oxl.cells[5,10] := 'SZÜLETÉSIIDEJE';
  _oxl.cells[5,11] := 'ÁLLAMPOLGÁRSÁGA';
  _oxl.cells[5,12] := 'TARTOZKÓDÁSI HELYE';
  _oxl.cells[5,13] := 'ÉRDEKELTSÉGE JELLEGE';
  _oxl.cells[5,14] := 'ÉRDEKELTSÉGÉNEK MÉRTÉKE';


  // ------------------------------------------------------------------

  vekonykeret('C4:C5');
  vekonykeret('E4:E5');
  vekonykeret('F4:N4');
  vekonykeret('G5:G5');
  vekonykeret('I5:I5');
  vekonykeret('K5:K5');
  vekonykeret('K5:K5');
  vekonykeret('M5:M5');
  vekonykeret('O5:O5');

  VastagKeret('B4:P5');
  VastagKeret('O4:N5');

  // -------------------------------------

   _ignums := inttostr(5+_ugyfeldb);

  _rangestr := 'B6:O' + _ignums;
  _oxl.range[_rangestr].Font.Name  := 'Calibri';
  _oxl.range[_rangestr].Font.Size  := 9;
  _oxl.range[_rangestr].Font.Bold  := False;
  _oxl.range[_rangestr].Font.Italic:= False;

  _rangestr := 'B6:B'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'D6:F'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'D6:F'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'H6:H'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'K6:K'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'M6:M'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'N6:N'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'O6:O'+_ignums;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'E6:E'+_ignums;
  _oxl.range[_rangestr].NumberFormat := '### #### ###';

  // ------------------------------------------------------

  _PRISOR := 6;
  while not GyujtoQuery.eof do
    begin
      with GyujtoQuery do
        begin
          _xPenztar       := FieldByNAme('PENZTAR').asInteger;
          _xKulfoldi      := FieldByNAme('KULFOLDI').asInteger;
          _xNev           := trim(FieldByNAme('JOGINEV').asString);
          _xTelephelycim  := trim(FieldByNAme('TELEPHELYCIM').asString);
          _xAdoszam       := trim(FieldByNAme('ADOSZAM').AsString);
          _xTulajnev      := trim(FieldByNAme('TULAJNEV').asString);
          _xElozonev      := trim(FieldByNAme('ELOZONEV').asString);
          _xLakcim        := trim(FieldByNAme('LAKCIM').asString);
          _xSzuletesihely := trim(FieldByNAme('SZULETESIHELY').asString);
          _xSzuletesiido  := trim(FieldByNAme('SZULETESIIDO').asString);
          _xAllampolgar   := trim(FieldByNAme('ALLAMPOLGAR').asString);
          _xTarthely      := trim(FieldByNAme('TARTOZKODASIHELY').asString);
          _xErdjelleg     := trim(FieldByNAme('ERDJELLEG').asString);
          _xErdmertek     := trim(FieldByNAme('ERDMERTEK').asString);
          _xKozszereplo   := FieldByNAme('KOZSZEREPLO').asInteger;
          _xBizonylatszam := trim(Fieldbyname('BIZONYLATSZAM').AsString);
          _xSorszam       := FieldByNAme('MEGBIZOTTSZAMA').asInteger;
          _xMbNevtabla    := FieldByNAme('MBNEVTABLA').asString;
        end;

      _oxl.cells[_prisor,2] := _xPenztar;
      _oxl.cells[_prisor,3] := _xNev;
      _oxl.cells[_prisor,4] := _xTelephelyCim;
      _oxl.cells[_prisor,5] := _xAdoszam;
      _oxl.cells[_prisor,6] := _xTulajnev;
      _oxl.cells[_prisor,7] := _xElozonev;
      _oxl.cells[_prisor,8] := _xLakcim;
      _oxl.cells[_prisor,9] := _xSzuletesihely;
      _oxl.cells[_prisor,10]:= _xSzuletesiido;
      _oxl.cells[_prisor,11]:= _xAllampolgar;
      _oxl.cells[_prisor,12]:= _xTarthely;
      _oxl.cells[_prisor,13]:= _xErdjelleg;
      _oxl.cells[_prisor,14]:= _xErdmertek;
      _oxl.cells[_prisor,15]:= _xMbNevtabla;
      _oxl.cells[_prisor,16]:= _xSorszam;

      inc(_prisor);

      GyujtoQuery.next;
    end;
  GyujtoQuery.close;
  GyujtoDbase.close;

  _oxl.range['D6:D6'].select;
  _oxl.ActiveWindow.FreezePanes := true;

  if fileExists(_excelPath) then Sysutils.DeleteFile(_excelpath);

  _owb.SaveAs(_excelPath);
  _oxl.Visible := True;
  Form2.Fuggony.Visible := true;
  _mResult := 1;
  Kilepo.enABLED := TRUE;
end;


// =============================================================================
           procedure TForm3.Vastagkeret(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderAround(1,4);
end;

// =============================================================================
          procedure TForm3.Vekonykeret(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderAround(1,2);
end;

// =============================================================================
                  procedure TForm3.KillExcel;
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



procedure TForm3.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  GyujtoQuery.close;
  GyujtoDbase.close;
  Modalresult := _mResult;
end;


end.
