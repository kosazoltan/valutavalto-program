unit Unit14;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TADATKULDES = class(TForm)
    ADATKULDES: TLabel;
    KILEPO: TTimer;

    procedure FormActivate(Sender: TObject);
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    procedure KILEPOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ADATKULDES: TADATKULDES;

implementation

{$R *.dfm}

procedure TADATKULDES.FormActivate(Sender: TObject);
begin
  WINEXECANDWAIT32(Pchar('Coupon.exe'),Sw_hide);
  Kilepo.enabled := True;
end;


// =============================================================================
       function TADATKULDES.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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

    Result := 0;
  end else Result := GetLastError;
end;

procedure TADATKULDES.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := False;
  Modalresult := 1;
end;

end.
