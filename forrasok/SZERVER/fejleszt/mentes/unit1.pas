unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, dateutils, ComCtrls, STRUTILS, ExtCtrls, jpeg;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    CSIK: TProgressBar;
    Panel1: TPanel;
    Panel2: TPanel;
    Timer1: TTimer;
    Panel3: TPanel;
    Image1: TImage;
    procedure FormActivate(Sender: TObject);
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    procedure BitBtn1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _munkanap: word;
  _angnapnev: array[1..7] of string = ('MONDAY','TUESDAY','WENDESDY','THURSDAY',
                                 'FRIDAY','SATURDAY','SUNDAY');

  _TARGETDIR: STRING;
  _FDBdARAB: WORD;
  _srec: TSearchRec;
  _aktfdbnev,
    _baknev,
    _source,
    _target,
    _PSOR,
    _tDir: string;

    _qq,
    _bakhossz: integer;

    _dmunka: TDateTime;

    _PACS: pchar;
    _hetNapja: word;
    _FDBNEV: array[0..250] of string;



implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);

begin
  _munkanap := dayof(Date);

  _hetnapja  := dayoftheweek(Date);
  _tdir      := _angNapNev[_hetnapja];
  _targetdir := 'c:\receptor\mail\mentes\'+_tDir;

  Top  := 10;
  Left := 5;
end;


procedure TForm1.BitBtn1Click(Sender: TObject);

var _fnev: string;

begin
  _fdbdarab := 0;
  if FindFirst('c:\receptor\database\v*.fdb', faAnyfile, _srec) = 0 then
    begin
      repeat
        _fnev := uppercase(_srec.Name);
        if leftstr(_fnev,3)<>'ALL' then _fdbnev[_fdbdarab] := _fnev;
        inc(_fdbdarab);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  Csik.Max := _fdbDarab;
  Csik.Position := 0;
  _qq := 0;

  while _qq<_fdbDarab do
    begin
      Csik.Position := _qq;

      _aktfdbnev := _fdbnev[_qq];
      _bakhossz  := length(_aktfdbnev);
      _baknev    := leftstr(_aktfdbnev,_bakhossz-3)+'FBK';
      _source    := 'c:\receptor\database\'+_aktFdbNev;
      _target    := _TARGETdir + '\' + _baknev;

      Panel1.Caption := _source;
      Panel2.Caption := _target;

      Panel1.Repaint;
      Panel2.Repaint;

      _psor := 'c:\receptor\gbak.exe -v -t -user SYSDBA -password dek@nySo ';
      _psor := _psor + _source+' '+_target;
      _pacs := addr(_psor[1]);

      Form1.WinexecAndWait32(_pacs,sw_hide);
      inc(_qq);
    end;

  _psor   := 'c:\receptor\gbak.exe -v -t -user SYSDBA -password dek@nySo ';
  _source := 'c:\receptor\database\receptor.fdb';
  _target := _targetDir + '\receptor.fbk';
  _psor   := _psor + _source + ' ' + _target;
  _pacs   := addr(_psor[1]);
  Form1.WinexecAndWait32(_pacs,sw_hide);

  _psor   := 'c:\receptor\gbak.exe -v -t -user SYSDBA -password dek@nySo ';
  _source := 'c:\receptor\database\daybook.fdb';
  _target := _targetDir + '\daybook.fbk';
  _psor   := _psor + _source + ' ' + _target;
  _pacs   := addr(_psor[1]);
  WinexecAndWait32(_pacs,sw_hide);
  Timer1.Enabled := True;
end;

// =============================================================================
                  procedure TForm1.Timer1Timer(Sender: TObject);
// =============================================================================

begin
  Timer1.Enabled := False;
  ModalResult := 1;
end;



// =============================================================================
     function TFORM1.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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



procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
