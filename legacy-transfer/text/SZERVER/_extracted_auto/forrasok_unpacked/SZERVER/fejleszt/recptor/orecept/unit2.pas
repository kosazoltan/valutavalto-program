unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StrUtils, StdCtrls, ComCtrls, UNIT1;

type
  TMENTES = class(TForm)
    Timer1: TTimer;
    Label1: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    CSIK: TProgressBar;
    procedure FormActivate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MENTES: TMENTES;
  _gdbdarab : integer;
  _gdbnev: array[0..200] of string;
  _psor: string;
  _pacs: pchar;

implementation

{$R *.dfm}

procedure TMENTES.FormActivate(Sender: TObject);

var _aktgdbnev,_baknev: string;
    _srec: TSearchRec;
    _qq,_bakhossz: integer;
    _source,_target: string;

begin

  Top := 10;
  Left := 5;

  _gdbdarab := 0;
  if FindFirst('c:\receptor\database\*.gdb', faAnyfile, _srec) = 0 then
    begin
      repeat
        _gdbnev[_gdbdarab] := _srec.Name;
        inc(_gdbdarab);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  cSIK.Max := _gdbDarab;
  Csik.Position := 0;
  _qq := 0;
  while _qq<_gdbDarab do
    begin
      Csik.Position := _qq;
      _aktgdbnev := _gdbnev[_qq];
      _bakhossz := length(_aktgdbnev);
      _baknev := leftstr(_aktgdbnev,_bakhossz-3)+'GBK';
      _source := 'c:\receptor\database\'+_aktGdbNev;
      _target := _TARGETdir + '\' + _baknev;

      EDIT1.Text := _source;
      edit2.Text := _target;

      edit1.Repaint;
      edit2.Repaint;

      _psor := 'c:\receptor\gbak.exe -v -t -user SYSDBA -password masterkey ';
      _psor := _psor + _source+' '+_target;
      _pacs := addr(_psor[1]);

      winexecandwait32(_pacs,sw_hide);
      winexecandwait32(_pacs,sw_hide);
      inc(_qq);
    end;

  Timer1.Enabled := True;
end;

// =============================================================================
                  procedure TMENTES.Timer1Timer(Sender: TObject);
// =============================================================================

begin
  tIMER1.Enabled := False;
  ModalResult := 1;
end;

// =============================================================================
     function TMentes.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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

end.
