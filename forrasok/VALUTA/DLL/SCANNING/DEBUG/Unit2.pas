unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, ShellApi;

type
  TForm2 = class(TForm)
    ScanPanel    : TPanel;
    FigyelemPanel: TPanel;

    ScanOkeGomb  : TBitBtn;
    RetryGomb    : TBitBtn;
    CancelGomb   : TBitBtn;

    Label1       : TLabel;
    Shape1       : TShape;

    ValutaQuery  : TIBQuery;
    ValutaDbase  : TIBDatabase;
    ValutaTranz  : TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure SCANOKEGOMBClick(Sender: TObject);
    procedure CANCELGOMBClick(Sender: TObject);
    procedure RETRYGOMBClick(Sender: TObject);
    procedure AdatBeolvasas;
    procedure ScanMenet;

//    procedure VegrehajtEsVar(_exepath: string);

    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

 SEInfo: TShellExecuteInfo;
 ExitCode: DWORD;
 ExecuteFile, ParamString, StartInString: string;

  _tempjpg : string = 'c:\valuta\bin\temp_scan.jpg';

  _height,_width,_top,_left: word;
  _usz,_ugyfeltipus,_pcs: string;
  _ugyfelszam,_mbszam,_winback: integer;
  _pacs: pchar;

// =============================================================================
            function bescannelorutin: integer; stdcall;
// =============================================================================


implementation

{$R *.dfm}

// =============================================================================
               function bescannelorutin: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;


// =============================================================================
               procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top  := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Height := 768;
  Width  := 1024;

  Adatbeolvasas;
  ScanMenet;
end;

// =============================================================================
                       procedure TForm2.ScanMenet;
// =============================================================================

begin
  with Figyelempanel do
    begin
      Top     := 270;
      Left    := 270;
      Visible :=true;
      Repaint;
    end;

  _usz := inttostr(_ugyfelszam);

  if _ugyfeltipus='W' then _usz := 'W' + _USZ;
  if _ugyfeltipus='J' then _usz := inttostr(_mbszam);

  if FileExists(_tempjpg) then Sysutils.DeleteFile(_tempjpg);

  Sleep(2300);

  FigyelemPanel.Visible := false;
  _pcs := 'c:\valuta\bin\escan.exe '+ _usz;

//  VegreHajtesVar(_pcs);

  _pacs := pchar(_pcs);
  _winback := winexecAndwait32(_pacs,sw_normal);

  if _winback<>0 then Showmessage('HIBA A SCANNELÉS KÖZBEN');
  Figyelempanel.Visible := False;

  with  ScanPanel do
    begin
      Top     := 240;
      Left    := 310;
      Visible := true;
    end;
  Activecontrol := ScanOkeGomb;
end;

// =============================================================================
     function TFORM2.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
// =============================================================================

var Msg: TMsg;
    lpExitCode: cardinal;
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;

begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);

  with StartupInfo do
    begin
      cb := SizeOf(TStartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
      wShowWindow := visibility; {you could pass sw_show or sw_hide as parameter}
    end;

  if CreateProcess(nil, path, nil, nil, False, NORMAL_PRIORITY_CLASS,
                                      nil, nil, StartupInfo,ProcessInfo) then

    begin
      repeat
        while PeekMessage(Msg, 0, 0, 0, pm_Remove) do
          begin
            if Msg.Message = wm_Quit then Halt(Msg.WParam);
            TranslateMessage(Msg);
            DispatchMessage(Msg);
          end;

        GetExitCodeProcess(ProcessInfo.hProcess,lpExitCode);
      until lpExitCode <> Still_Active;

    with ProcessInfo do {not sure this is necessary but seen in in some code elsewhere}
      begin
        CloseHandle(hThread);
        CloseHandle(hProcess);
      end;

    Result := 0; {success}
  end else Result := GetLastError;
end;


// =============================================================================
                      procedure TForm2.Adatbeolvasas;
// =============================================================================

begin
  valutadbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _ugyfelszam := FieldByName('UGYFELSZAM').asInteger;
      _ugyfeltipus := FieldByNAME('UGYFELTIPUS').asString;
      _mbszam      := FieldBynAme('MEGBIZOSZAM').asInteger;
      Close;
    end;
  Valutadbase.close;
end;


// =============================================================================
               procedure TForm2.SCANOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
             procedure TForm2.CANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
               procedure TForm2.RETRYGOMBClick(Sender: TObject);
// =============================================================================

begin
  ScanPanel.Visible := false;
  Scanmenet;
end;


{
procedure TForm2.VegrehajtEsVar(_exepath: string);

begin
  FillChar(SEInfo, SizeOf(SEInfo), 0) ;
  SEInfo.cbSize := SizeOf(TShellExecuteInfo) ;

  with SEInfo do
   begin
     fMask := SEE_MASK_NOCLOSEPROCESS;
     Wnd := Application.Handle;
     lpFile := PChar(_exepath) ;
     lpParameters := pchar(_usz);
     nShow := SW_SHOWNORMAL;
   end;

 if ShellExecuteEx(@SEInfo) then
   begin
     repeat
       Application.ProcessMessages;
       GetExitCodeProcess(SEInfo.hProcess, ExitCode) ;
     until (ExitCode <> STILL_ACTIVE) or Application.Terminated;
   end;
end;

ParamString can contain the
application parameters.
}
// lpParameters := PChar(ParamString) ;
{
StartInString specifies the
name of the working directory.
If ommited, the current directory is used.
}
// lpDirectory := PChar(StartInString) ;



end.
