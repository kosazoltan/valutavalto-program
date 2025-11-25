unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    TOMORITOGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    KIBONTOGOMB: TBitBtn;
    Panel1: TPanel;
    Panel2: TPanel;
    CSIK: TProgressBar;
    KILEPO: TTimer;
    TAKARO: TPanel;
    Label1: TLabel;
    ottvangomb: TBitBtn;
    NINCSOTTGOMB: TBitBtn;
    BitBtn1: TBitBtn;

    procedure KILEPOGOMBClick(Sender: TObject);
    procedure TOMORITOGOMBClick(Sender: TObject);
    procedure KIBONTOGOMBClick(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);

    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    procedure NINCSOTTGOMBClick(Sender: TObject);
    procedure ottvangombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _fdbdb,_bakdb,_qq: word;
  _minta,_aktfdb,_source,_target,_pcs,_aktbak,_newfile: string;
  _pacs : pchar;
  _sRec  :TSearchrec;
  _fdbfile,_bakfile : array[1..300] of string;
  _bazisdir : string = 'c:\receptor\mail\1';


implementation

{$R *.dfm}

procedure TForm1.KILEPOGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.TOMORITOGOMBClick(Sender: TObject);
begin
  _fdbdb := 0;
  _minta := _bazisdir + '\*.FDB';
  if FindFirst(_minta, faAnyFile, _sRec) = 0 then
  begin
    repeat
      inc(_fdbdb);
      _fdbfile[_fdbdb] := _SREC.NAME;
    until FindNext(_SREC) <> 0;
    FindClose(_SREC);
  end;

  If _fdbdb=0 then
    begin
      ShowMessage('Nincs tömöritendõ adatbázis');
      Kilepo.enabled := True;
      exit;
    end;

  Csik.Max := _fdbdb;

  _qq := 1;
  while _qq<=_fdbdb do
    begin
      Csik.Position := _qq;
      _aktfdb := _fdbfile[_qq];
      _source := _bazisdir + '\' + _aktfdb;
      _aktbak := ChangeFileExt(_aktfdb,'.gbk');
      _target := _bazisdir + '\' + _aktbak;

      Panel1.Caption := _source + ' -->  ' + _target;
      Panel1.repaint;

      _pcs := _bazisdir + '\gbak.exe -v -t -user SYSDBA -password dek@nySo '+_source+' '+_target;
      _pacs := pchar(_pcs);
      winexecandwait32(_pacs,SW_HIDE);
      sysutils.DeleteFile(_source);
      inc(_qq);
    end;
end;

// =============================================================================
    function TForm1.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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



procedure TForm1.KIBONTOGOMBClick(Sender: TObject);
begin
  _bakdb := 0;
  _MINTA := _bazisdir + '\*.GBK';
  if FindFirst(_minta, faAnyFile, _sRec) = 0 then
  begin
    repeat
      inc(_bakdb);
      _bakfile[_bakdb] := _SREC.NAME;
    until FindNext(_SREC) <> 0;
    FindClose(_SREC);
  end;

  If _bakdb=0 then
    begin
      ShowMessage('Nincs tömöritett adatbázis');
      Kilepo.enabled := True;
      exit;
    end;

  Csik.Max := _bakdb;
  _qq := 1;
  while _qq<=_bakdb do
    begin
      Csik.Position := _qq;

      _aktbak := _bakfile[_qq];
      _source := _bazisdir + '\' + _aktbak;
      _newfile := ChangeFileExt(_aktbak,'.fdb');
      _target :=  _bazisdir + '\' + _newfile;

      Panel2.Caption := _source + ' -->  ' + _target;
      Panel2.repaint;

      _pcs := _bazisdir + '\gbak.exe -c -v -user SYSDBA -password dek@nySo '+_source+' '+_target;
      _pacs := pchar(_pcs);
      winexecandwait32(_pacs,SW_HIDE);
      sysutils.DeleteFile(_source);
      inc(_qq);
    end;
end;

procedure TForm1.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Application.Terminate;
end;

procedure TForm1.NINCSOTTGOMBClick(Sender: TObject);
begin
  kILEPO.Enabled := true;
end;

procedure TForm1.ottvangombClick(Sender: TObject);
begin
  Takaro.Visible := False;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  if not fileExists('c:\receptor\mail\1\gbak.exe') then
    begin
      showmessage('BE KELL MÁSOLNI GBAK.EXE-T C:\RECEPTOR\MAIL\1 - KÖNYVTÁRBA');
      exit;
    end;

  if not fileExists('c:\receptor\mail\1\fbclient.dll') then
    begin
      showmessage('BE KELL MÁSOLNI FBCLIENT.DLL-T C:\RECEPTOR\MAIL\1 - KÖNYVTÁRBA');
      exit;
    end;

  oTTVANGOMB.Enabled := True;
  NincsOttGomb.Enabled := True;

end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  Application.terminate;
end;

end.
