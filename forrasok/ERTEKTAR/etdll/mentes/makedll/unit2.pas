unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,ExtCtrls, idglobal, Buttons, strutils, wininet,
  IBDatabase, DB, IBCustomDataSet, IBQuery;

type

  TNAPIMENTES = class(TForm)
    BACKUPPANEL: TPanel;
    Memo2: TMemo;
    KILEPO: TTimer;
    Shape4: TShape;
    Panel1: TPanel;
    ALCIMPANEL: TPanel;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure RemdirCtrlAndSend(_remDir: string);
    procedure KILEPOTimer(Sender: TObject);
    procedure AlapadatBeolvasas;

    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    function FdbMentese(_aktfdb: string): boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPIMENTES: TNAPIMENTES;
  _top,_left,_width,_height: word;

  _savepcs,_restpcs,_fixpcs,_pcs,_mText,_ptnums: string;
  _dbasedir,_mentesdir,_remoteFile,_farok,_lezartnap: string;
  _mBakPath,_mFbPath: string;
  _sourcePath,_targetPath: string;
  _sourcedir,_targetdir: string;
  _pacs: pchar;
  _mOke,_result: boolean;

  _hFTP,_hNet: HINTERNET;
  _FINDDATA : WIN32_FIND_DATA;
  _ftpPassword : string  = 'klc+45%';
  _host: string;
  
  _userId      : String  = 'ebc-10%';
  _ftpPort     : Integer = 21100;

  _pPath: string;
  _bennvan: boolean;

function backuprestore: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
      function backuprestore: integer; stdcall;
// =============================================================================



begin
  Napimentes := TNapimentes.create(Nil);
  result := Napimentes.Showmodal;
  Napimentes.Free;
end;

// =============================================================================
             procedure TNAPIMENTES.FormActivate(Sender: TObject);
// =============================================================================

var _rdir: string;

begin
  _height := Screen.Monitors[0].Height;
  _width := Screen.Monitors[0].Width;

  _top := trunc((_height-384)/2);
  _left := trunc((_width-512)/2);

  Top      := _top;
  Left     := _left;
  Width    := 505;
  Height   := 350;

  Kilepo.Enabled       := False;

  Memo2.Lines.Clear;
  Memo2.Clear;

  AlapadatBeolvasas;

  _mentesdir := 'c:\ertektar\mentes';
  _dbaseDir := 'c:\ertektar\database';

  _mbakPath := _mentesdir + '\gbak.exe';

  if not FileExists(_mBakPath) then
    begin
      ShowMessage('NEM TALÁLOM '+_mBakPath+' file-t !');
      Kilepo.Enabled := true;
      exit;
    end;

  _savepcs := _mBakPath + ' -v -t -user SYSDBA -password dek@nySo ';

  // A 'ERTEKTAR\MENTES konyvtarba kell masolni:
  // gbak.exe,gfix.exe,fbclient.dll ha valamelyik nincs ott

  alCimPanel.Caption := 'ELMENTÉSE';

  if FdbMentese('VALUTA.FDB') then
    begin
      Memo2.Lines.Add('Valuta.fdb tömöritése sikerült');
      if FdbMentese('VALDATA.FDB') then Memo2.Lines.Add('Valuta.fdb tömöritése sikerült');
      _rdir := 'PM' + _ptNums;
      RemDirCtrlAndSend(_rDir);
    end;

  Kilepo.Enabled := True;
end;

// =============================================================================
         function Tnapimentes.FdbMentese(_aktfdb: string): boolean;
// =============================================================================

var _fw: byte;
    _fn: string;

begin
  result := False;
  _fw := length(_aktfdb);
  _fn := leftstr(_aktfdb,_fw-4);

  _sourcepath := _dbaseDir  + '\' + _aktfdb;
  _targetpath := _mentesdir + '\' + _fn + '.gbk';

  if not FileExists(_sourcePath) then exit;

  if FileExists(_targetpath) then DeleteFile(_targetpath);

  // A source file backup-olása a mentés könyvtárba;
  _pcs := _savepcs + _sourcepath + ' ' + _targetpath;

  _mtext := 'A ' + _aktfdb + ' MENTÉSE';
  Memo2.Lines.Add(_mText);

  _pacs := addr(_pcs[1]);
  WinExecAndWait32(_pacs,SW_HIDE);
  _mOke := FileExists(_targetPath);
  if _mOke then result := true;
end;

// =============================================================================
                procedure TNAPIMENTES.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  ModalResult := 1;
end;


// =============================================================================
           procedure TNapiMentes.RemdirCtrlAndSend(_remDir: string);
// =============================================================================

begin

  _hFTP := Nil;
  _hNET := InternetOpen('serverre',INTERNET_OPEN_TYPE_PRECONFIG,Nil,Nil,0);
  if _hNET=NIL then exit;

  _hFTP := INTERNETCONNECT(_hNet,pchar(_host),_ftpPort,pchar(_userID),
                             pchar(_ftpPassword),INTERNET_SERVICE_FTP,
                                             INTERNET_FLAG_PASSIVE,0);

  if _hFTP=Nil  then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  _pPath := 'PMENTES\' + _remDir;
  _bennVan :=  FTPSETCURRENTDIRECTORY(_hFTP,pchar(_pPath));

  if not _bennvan then
     begin
       FtpCreateDirectory(_hFTP,pchar(_pPath));
       _bennVan :=  FTPSETCURRENTDIRECTORY(_hFTP,pchar(_pPath));
     end;

  if not _bennvan then
    begin
      Memo2.Lines.Add('Sikertelen szerverre mentés');
      sleep(2500);
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

   _sourcePath := 'c:\ertektar\mentes\valuta.gbk';
   if fileExists(_sourcePath) then
     begin
       _remotefile := 'VALU' + _farok;
       _result := FTPPutFile(_hFTP,pchar(_sourcePath),pchar(_remoteFile),FTP_TRANSFER_TYPE_BINARY,0);
       Memo2.lines.add('Valuta.gbk szereverre mentése ...');
       if _result then Memo2.lines.add('SIKERES !') else Memo2.lines.add('Nem sikerült');
     end;

   _sourcePath := 'c:\ertektar\mentes\valdata.gbk';
   if fileExists(_sourcePath) then
     begin
       _remotefile := 'VALD' + _farok;
       _result := FTPPutFile(_hFTP,pchar(_sourcePath),pchar(_remoteFile),FTP_TRANSFER_TYPE_BINARY,0);
       Memo2.lines.add('Valdata.gbk szereverre mentése ...');
       if _result then Memo2.lines.add('SIKERES !') else Memo2.lines.add('Nem sikerült');
     end;


   // -------------------------------------------------------------------------------

   sleep(2500);
   InternetCloseHandle(_hFTP);
   InternetCloseHandle(_hNet);
end;

procedure TnapiMentes.AlapadatBeolvasas;

begin
  valdbase.Connected := True;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM HARDWARE');
      Open;
      _lezartnap := trim(FieldByName('LEZARTNAP').asString);
      _host := trim(FieldByNAme('HOST').AsString);
      Close;

      Sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _ptNums := trim(FieldByName('PENZTARKOD').asString);
      Close;
    end;
  Valdbase.close;
  if _lezartnap='' then
    begin
      Kilepo.Enabled := true;
      exit;
    end;
  _farok := midstr(_lezartnap,3,2)+midstr(_lezartnap,6,2);
end;


// =============================================================================
   function TNapiMentes.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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

END.

