unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, comobj, unit1, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TNYULEXCEL = class(TForm)
    BitBtn1: TBitBtn;
    takaro: TPanel;
    Label1: TLabel;
    MQUERY: TIBQuery;
    MDBASE: TIBDatabase;
    MTRANZ: TIBTransaction;
    procedure FormActivate(Sender: TObject);
    procedure ExcelKill;
    procedure excelZaras;
    procedure BitBtn1Click(Sender: TObject);
    procedure Valutadisplay(_aktdnem: string);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NYULEXCEL: TNYULEXCEL;
   _oxl,_owb: variant;
   _prisor : word;

implementation

{$R *.dfm}

procedure TNYULEXCEL.FormActivate(Sender: TObject);

var _y: byte;
    _betu,_rangestr,_focim: string;

begin
  Takaro.Visible := true;
  Takaro.repaint;

 
  _oxl := CreateOleObject('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.add[1];

  _y := 1;
  while _y<=9 do
    begin
      _betu := chr(64+_y);
      _rangestr := _betu + '1:' + _betu + '1';
      _oxl.range[_rangestr].columnwidth := 16;
      inc(_y);
    end;

  _rangestr := 'B2:I2';
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.range[_rangestr].Horizontalalignment := -4108;
  _oxl.range[_rangestr].Font.size := 14;
  _oxl.range[_rangestr].font.italic := True;
  _oxl.range[_rangestr].font.Font := True;

  _focim := inttostr(_kertev)+' '+_honev[_kertho]+' HAVI MONEYGRAM TRANZAKCIÓK';
  _oxl.cells[2,2] := _focim;

  _rangestr := 'B4:I4';
  _oxl.range[_rangestr].Horizontalalignment := -4108;
  _oxl.range[_rangestr].Font.size := 14;
  _oxl.range[_rangestr].font.italic := True;
  _oxl.range[_rangestr].font.Font := True;

  _oxl.cells[4,2] := 'PÉNZTÁR';
  _oxl.cells[4,3] := 'DÁTUM';
  _oxl.cells[4,4] := 'NYITÓ';
  _oxl.cells[4,5] := 'BANKBÓL';
  _oxl.cells[4,6] := 'BANKBA';
  _oxl.cells[4,7] := 'ÜGYFÉLTÖL';
  _oxl.cells[4,8] := 'ÜGYFÉLNEK';
  _oxl.cells[4,9] := 'ZÁRÓ';

  _oxl.range['A5:A5'].Select;
  _oxl.activewindow.FreezePanes := True;

  _prisor := 6;
  Valutadisplay('HUF');

  _prisor := _prisor + 2;
  Valutadisplay('EUR');

  _prisor := _prisor + 2;
  Valutadisplay('USD');

  Takaro.Visible := false;
  _oxl.Visible := true;
end;

procedure TNyulExcel.ExcelZaras;

begin
  _oxl.Quit;
  _oxl := Unassigned;
  _owb := Unassigned;
  ExcelKill;
end;

// =============================================================================
                  procedure TNyulexcel.Valutadisplay(_aktdnem: string);
// =============================================================================


begin
  Showmessage('a');
end;  



// =============================================================================
                  procedure TNyulexcel.ExcelKill;
// =============================================================================


var
  _fileName,_filePath: String;

begin

  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
end;


procedure TNYULEXCEL.BitBtn1Click(Sender: TObject);
begin
  ExcelZaras;
  Modalresult := 1;
end;

procedure TNyulexcel.Adatbeolvasas;

begin
  // index : 1= huf, 2=eur, 3= usd

  _pcs := 'SELECT * FROM TABLANEV' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  mDbase.Connected := true;
  with mQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end
  while not mQuery.eof do
    begin
      with mQuery do
        begin
          _datum := FieldByNAme('DATUM').asString;



end.
