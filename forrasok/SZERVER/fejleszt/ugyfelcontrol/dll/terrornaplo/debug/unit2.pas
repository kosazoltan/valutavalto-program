unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Grids, DBGrids, comobj, Buttons, TlHelp32, ComCtrls;

type
  TForm2 = class(TForm)

    VisszaGomb  : TButton;
    Focim       : TLabel;
    Kilepo      : TTimer;
    UQuery      : TIBQuery;
    UDbase      : TIBDatabase;
    UTranz      : TIBTransaction;
    RemoteQuery : TIBQuery;
    RemoteDbase : TIBDatabase;
    RemoteTranz : TIBTransaction;
    IdoszakPanel: TPanel;
    NaploRacs   : TDBGrid;
    NaploSource : TDataSource;
    EXCELGOMB: TBitBtn;
    KILEPOGOMB: TPanel;
    TAKAROPANEL: TPanel;
    Label1: TLabel;
    CSIK: TProgressBar;
    Shape1: TShape;

    procedure VisszaGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure OszlopKijeloles;
    procedure MakeExcel;
    procedure FejlecOsszeAllitas;
    procedure AdatokKijelzese;

    procedure Freezing;
    procedure Vastagkeret(_rs: string);
    procedure Vekonykeret(_rs: string);
    procedure Killexcel;
    procedure EXCELGOMBClick(Sender: TObject);
    procedure KILEPOGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _oxl,_owb,_range: OleVariant;

  _vanexcel,_LOOPER: boolean;
  _proc : PROCESSENTRY32;
  _handle: HWND;

  _host: string = '185.43.207.99';

  _ptkod,_ptnev,_ugyfnev,_datum,_ido,_engedelyezve,_engedelyezo: string;
  _top,_left,_height,_width: word;
  _ok,_mResult,_recno,_tdb,_lastsor,_prisor: integer;
  _tolstring,_igstring,_pcs,_focim,_rangestr,_lasts: string;
  _sorveg: string = chr(13)+chr(10);

function idoszaksetting: integer; stdcall; external 'c:\uctrl\bin\idoszak.dll';
function terrornaplorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                function terrornaplorutin: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;


// =============================================================================
             procedure TForm2.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := true;
end;

// =============================================================================
            procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top := round((_height-595)/2);
  _left := 8+round((_width-1017)/2);

  top    := _top-50;
  left   := _left;
  width  := 1001;
  height := 537;
  color  := clGreen;

  _vanExcel := False;

  _ok    := idoszaksetting;
  if _ok=-1 then
    begin
      ShowMessage('Nincsenek adatok a kért idõszakban');
      Kilepo.enabled := True;
      exit;
    end;

  Focim.Top := 20;
  remoteDbase.close;
  remoteDbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';
  RemoteDbase.Connected := true;

  Udbase.Connected := true;
  with UQuery do
    begin
      close;
      sql.clear;
      sql.Add('SELECT * FROM IDOSZAK');
      Open;
      _tolstring := FieldByNAme('TOLSTRING').asString;
      _igstring := FieldByNAme('IGSTRING').asString;
      close;
    end;
  Udbase.close;
  idoszakPanel.caption := _tolstring+' - '+_igstring+ ' között';
  idoszakPanel.Visible := True;
  idoszakpanel.repaint;

   // -----------------------------------------

   _pcs := 'SELECT * FROM JOURNAL' + _sorveg;
   _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tolstring+chr(39)+')';
   _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igstring+chr(39)+')';
   with remotequery do
     begin
       CLose;
       sql.clear;
       sql.add(_pcs);
       Open;
       _recno := recno;
     end;

   NaploRacs.Visible := True;
   VisszaGomb.Visible := true;
   if _recno=0 then SHowmessage('NEM VOLT ESEMÉNY A KÉRT IDÕSZAK ALATT')
   else Excelgomb.Visible := True;
end;


// =============================================================================
           procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  RemoteQuery.close;
  Remotedbase.close;
  if _vanexcel then
    begin
      _owb := unassigned;
      _oxl.quit;
      _oxl := unassigned;
      KillExcel;
    end;
  Modalresult := 1;
end;

// =============================================================================
                    procedure TForm2.MakeExcel;
// =============================================================================

begin
  _oxl := CreateOleObject('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.Add[1];
  _owb.Activate;

  Csik.Position := 1;
  OszlopKijeloles;

  Csik.Position := 2;
  FejlecOsszeallitas;

  Csik.Position := 3;
  AdatokKijelzese;
  csik.Position := 4;
  sleep(300);

  Freezing;
  csik.visible := false;
  TakaroPanel.Visible := False;
  Excelgomb.Visible  := False;
  VisszaGomb.Visible := False;
  _oxl.visible :=True;
end;


// =============================================================================
                    procedure TForm2.OszlopKijeloles;
// =============================================================================

begin
  _oxl.range['A1:A1'].Columnwidth := 8;
  _oxl.range['B1:B1'].Columnwidth := 8;
  _oxl.range['C1:C1'].Columnwidth := 12;
  _oxl.range['D1:D1'].Columnwidth := 30;
  _oxl.range['E1:E1'].Columnwidth := 12;
  _oxl.range['F1:F1'].Columnwidth := 9;
  _oxl.range['G1:G1'].Columnwidth := 33;
  _oxl.range['H1:H1'].Columnwidth := 9;
  _oxl.range['I1:I1'].Columnwidth := 30;
end;


// =============================================================================
                    procedure TForm2.FejlecOsszeallitas;
// =============================================================================

begin
  _focim := 'TERRORISTA GYANÚS ÜGYFELEK NAPLÓZÁSA '+_tolstring+' ÉS ';
  _focim := _focim + _igstring + ' KÖZÖTT';

  _rangestr := 'C2:I2';

  _oxl.range[_rangestr].MergeCells  := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.range[_rangestr].Font.Name   := 'Calibri';
  _oxl.range[_rangestr].Font.Size   := 14;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.cells[2,3] := _focim;

  // -------------------------------------------------

  _oxl.range['C5:C6'].MergeCells  := True;
  _oxl.range['D5:D6'].MergeCells  := True;
  _oxl.range['E5:E6'].MergeCells  := True;
  _oxl.range['F5:F6'].MergeCells  := True;
  _oxl.range['G5:G6'].MergeCells  := True;
  _oxl.range['H5:H6'].MergeCells  := True;
  _oxl.range['I5:I6'].MergeCells  := True;

  // ---------------------------------------------------

  _rangestr := 'C5:I6';
  _oxl.range[_rangestr].Font.Name   := 'Cslibri';
  _oxl.range[_rangestr].Font.Size   := 11;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.range[_rangestr].VerticalAlignment := -4108;
  _oxl.range[_rangestr].WrapText := True;

  // ---------------------------------------------------

  _oxl.Cells[5,3] := 'PÉNZTÁR SZÁM';
  _oxl.Cells[5,4] := 'PÉNZTÁR MEGNEVEZÉSE';
  _oxl.Cells[5,5] := 'DÁTUM';
  _oxl.Cells[5,6] := 'IDÕ';
  _oxl.Cells[5,7] := 'A VIZSGÁLT ÜGYFÉL NEVE';
  _oxl.Cells[5,8] := 'ENGE- DÉLY';
  _oxl.Cells[5,9] := 'ENGEDÉLYEZÕ NEVE';

  // ----------------------------------------------------

  VekonyKeret('D5:D6');
  VekonyKeret('F5:F6');
  VekonyKeret('H5:H6');

  VastagKeret('C5:I6');
end;

// =============================================================================
                            procedure TForm2.Freezing;
// =============================================================================

begin
  _rangestr := 'B7:B7';
  _range := _oxl.range[_rangestr];
  _range.select;
  _oxl.ActiveWindow.FreezePanes := true;
end;

// =============================================================================
                      procedure TForm2.AdatokKijelzese;
// =============================================================================

begin
  remoteDbase.connected := true;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _tdb := recno;
      First;
    end;

  _lastsor := 6 + _tdb;
  _lasts := inttostr(_lastsor);
  _prisor := 6;

  _rangestr := 'C7:I' + _lasts;

  _oxl.range[_rangestr].Font.Name   := 'Cslibri';
  _oxl.range[_rangestr].Font.Size   := 11;
  _oxl.range[_rangestr].Font.Bold   := False;
  _oxl.range[_rangestr].Font.Italic := False;

  _rangestr := 'C7:C' + _lasts;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'E7:F' + _lasts;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'H7:H' + _lasts;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  while not remoteQuery.eof do
    begin
      _ptkod := trim(remoteQuery.FieldByNAme('PENZTARKOD').asString);
      _ptnev := trim(remoteQuery.FieldByNAme('PENZTARNEV').asString);
      _datum := trim(remoteQuery.FieldByNAme('DATUM').asString);
      _ido   := trim(remoteQuery.FieldByNAme('IDO').asString);
      _engedelyezve := trim(remoteQuery.FieldByNAme('ENGEDELYEZVE').asString);
      _engedelyezo := trim(remoteQuery.FieldByNAme('ENGEDELYEZO').asString);
      _ugyfnev := trim(remoteQuery.FieldByNAme('UGYFELNEV').asString);

      inc(_prisor);

      _oxl.Cells[_prisor,3] := _ptkod;
      _oxl.Cells[_prisor,4] := _ptnev;
      _oxl.Cells[_prisor,5] := _datum;
      _oxl.Cells[_prisor,6] := _ido;
      _oxl.Cells[_prisor,7] := _ugyfnev;
      _oxl.Cells[_prisor,8] := _engedelyezve;
      _oxl.Cells[_prisor,9] := _engedelyezo;

      remoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;
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



procedure TForm2.EXCELGOMBClick(Sender: TObject);
begin
  KilepoGomb.Visible := true;
  TakaroPanel.visible := true;
  _vanexcel := True;
  MakeExcel;
end;

procedure TForm2.KILEPOGOMBClick(Sender: TObject);
begin
  Kilepo.Enabled := true;
end;

end.
