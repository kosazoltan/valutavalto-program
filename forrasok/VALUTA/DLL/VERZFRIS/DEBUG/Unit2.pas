unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IDGLOBAL,ShlObj,ActiveX,
  IBDatabase, DB, IBCustomDataSet, IBQuery,wininet, strutils,dateutils,
  IBTable,COmObj,TlHelp32, registry, jpeg,shellapi;

{
TYPE
 POSVersionInfoEx = ^TOSVersionInfoEx;
 TOSVersionInfoEx = packed record

    dwOSVersionInfoSize: DWORD;
    dwMajorVersion     : DWORD;
    dwMinorVersion     : DWORD;
    dwBuildNumber      : DWORD;
    dwPlatformId       : DWORD;
    szCSDVersion       : array[0..127] of AnsiChar;
    wServicePackMajor  : Word;
    wServicePackMinor  : Word;
    wSuiteMask         : Word;
    wProductType       : Byte;
    wReserved          : Byte;
  end;
}


type
  TVFRISS = class(TForm)
    KERET: TShape;
    Label1: TLabel;
    MEMO1: TMemo;
    KILEPO: TTimer;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    VALDATATABLA: TIBTable;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    IBTABLA: TIBTable;
    VALUTATABLA: TIBTable;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure ValutaParancs(_ukaz: string);
    procedure Frissitoidobekuldes;
    procedure NavSorszamBeiro;
    procedure SettingNavCOm;

//    procedure KijelzoCsere;
//    procedure Foglalorendezes;
//    procedure TradeModosito;
//    procedure IkonKirako;
//    procedure TranzdijChange;
//    function ServerreLep(_remdir: string): boolean;
//    function RateDispLetoltes: boolean;

  function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
//   function KijelzesLeallitas: boolean;

  //  function Ratedispletoltes: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Vfriss: TVFriss;

  _dnem: array[1..24] of string = ('HUF','EUR','AUD','BAM','BGN','BRL','CAD',
            'CHF','CNY','CZK','GBP','ILS','JPY','MXN','NZD','PLN','RON','RSD',
            'RUB','THB','TRY','UAH','USD','HRK');

  _aktverzio: string = '35.20';
  _host : string;

   proc   : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;

   _mezonev,_mezotipus,_mezochar: array of string;
  _mezohossz: array of integer;

  _pcs,_ido,_datum,_cikkszam,_bizonylat: string;
  _aktfdbPath,_akttablanev,_remotefile,_localpath,_idos: string;
  _megnyitottnap,_penztarkod,_farok,_bfnev,_aktmezonev: string;
  _aktidkod,_aktidnev,_pcs2,_reklamstring,_remotePath: string;
  _soke: boolean;


  _aktmezotipus,_filter: string;
  _sorveg: string = chr(13)+chr(10);

  _ptdarab,_y,_pfdarab,_libdb,_c,_ePenztar,_oke,_ho,_szinkod,_navcom: byte;
  _srec: TSearchRec;
  _MEZODARAB,_CC,_mezosorszam,_monitordarab,_code,_recno: integer;

  _proc  : PROCESSENTRY32;

  _tranz,_kezdij: array[1..10] of integer;
  _akttranz,_aktkdij: integer;


  _hNet,_hFTp: HINTERNET;
  _sikeres,_vantrade: boolean;

  _height,_width,_top,_left: word;

  _ftpPort    : integer = 21100;
  _userId     : string  = 'ebc-10%';
  _ftpPassword: string  = 'klc+45%';

  _source,_target,_mezo,_dattime: string;
  _sourcePath,_targetpath: string;
  _pacs: pchar;

  _type: array[1..800] of byte;
  _uszam: array[1..800] of integer;
  _tnev,_tmbnev,_biz: string;
  _tuszam,_aktNum: integer;
  _aktType: byte;

  _snev,_cnev,_smbnev,_cmbnev: string;
  _nev,_mbnev: array[1..800] of string;

  _ss,_jdarab: word;
  _siker,_kellmatrica: boolean;


// function WindowsExit(RebootParam: Longword): Boolean;
// function adatpotlorutin: integer; stdcall; external 'c:\valuta\bin\potlas.dll' name 'adatpotlorutin';

function verziofrissitorutin: integer; stdcall;
function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\qrgener.dll';

implementation

{$R *.dfm}

// =============================================================================
              function verziofrissitorutin: integer; stdcall;
// =============================================================================

begin
  Vfriss := TVFriss.Create(Nil);
  result := Vfriss.ShowModal;
  Vfriss.Free;
end;


// =============================================================================
            procedure TVFriss.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left:= round((_width-1024)/2);

  Top      := _top + 10;
  Left     := _left + 10;

  Width    := 1004;
  Height   := 750;

  Label1.Repaint;
  Keret.Repaint;
  AlapadatBeolvasas;

  _PCS := 'c:\valuta\bin\valto.exe';
  _pacs := pchar(_pcs);
  WinExecAndWait32(_pacs,sw_normal);

  Memo1.Lines.add('A frissités tényét regisztrálom ...');
  _oke := 2;


  FrissitoIdoBekuldes;

  if _oke=1 then Memo1.Lines.Add('Sikeres regisztráció')
  else Memo1.Lines.Add('Sikertelen regisztració');

  Memo1.Lines.add('A valutaprogram verziószám rögzítése ...');
  _pcs := 'UPDATE HARDWARE SET VERZIO='+_aktVerzio;
  ValutaParancs(_pcs);

  Kilepo.Enabled:= True;
end;

// =============================================================================
                   procedure TVFRISS.AlapadatBeolvasas;
// =============================================================================

var _matrica: byte;

begin
  _kellMatrica := False;
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').AsString);
      _host := trim(FieldByName('HOST').AsString);
      _matrica := FieldByName('KELLMATRICA').asInteger;
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      close;
    end;
  Valutadbase.close;
  if _matrica>0 then _kellmatrica := True;
end;


procedure TVfriss.SettingNavcom;

begin
  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      SQL.ADD('SELECT * FROM HARDWARE');
      Open;
      _navcom := FieldByName('NAVCOM').asInteger;
      close;
    end;
  Valutadbase.close;

  if _navcom=0 then
    begin
      _pcs := 'UPDATE HARDWARE SET NAVCOM=1';
      ValutaParancs(_pcs);
    end;
end;


{
// =============================================================================
                        procedure TVfriss.KijelzoCsere;
// =============================================================================

VAR _handle: THandle;
    _back: integer;

begin
  Memo1.Lines.add('Megkisérelem a kijelzõ letöltését');

  KijelzesLeallitas;

  _sikeres := RateDispLetoltes;

  if _sikeres then Memo1.Lines.Add('Sikeres letöltés')
  else Memo1.Lines.Add('Sikertelen az árfolyamkijelzés letöltése');

  _back := shellExecute(_handle,'open',pchar('c:\valuta\bin\ratedisp.exe\'),'','',SW_SHOWNORMAL);
  IF _back>32 then Memo1.Lines.Add('A KIJELZÉS ELINDULT')
  else Memo1.Lines.Add(inttostr(_back)+' SZÁMU HIBA TÖRTÉNT');
end;

// =============================================================================
                    function TVFriss.KijelzesLeallitas: boolean;
// =============================================================================

   // Leállitja a kijelzést

var
  _fileName,_filePath: String;

begin
  result := False;

  Memo1.Lines.add('A kijelzés leállitáse folyamatban');

  Proc.dwSize := SizeOf(Proc);
  _handle     := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper     := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
       _filepath := Proc.szExeFile;
      _fileName  := uppercase(ExtractFileName(_filepath));

      if _fileName = 'RATEDISP.EXE' then
        begin
          result := TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
          break;
        end;
      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);

end;

// =============================================================================
             function TVFriss.RateDispLetoltes: boolean;
// =============================================================================

begin
  result := ServerreLep('\RATEDISP');
  if not result then
    begin
      Memo1.Lines.Add('Nem sikerült fellépni a szerverre');
      sleep(1200);
      exit;
    end;

  Memo1.Lines.Add('Az új kijelzõ letöltése');

  _localPath := 'c:\VALUTA\BIN\RATEDISP.EXE';
  _remoteFile := 'RATEDISP.EXE';

  result := ftpgetfile(_hftp,pchar(_remotefile),pchar(_localpath),False,0,FTP_TRANSFER_TYPE_BINARY,0);
  IF RESULT then Memo1.Lines.Add('Sikeresen letöltve az új kijelzõ')
  else Memo1.Lines.Add('Sikertelen kijelzõ csere');

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

// =============================================================================
            function TVFriss.ServerreLep(_remdir: string): boolean;
// =============================================================================

begin
  result := False;

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

  RESULT := FtpSetCurrentDirectory(_hFTP,pchar(_remdir));

  if not Result then
    begin
      internetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;
  Result := true;
end;
}

// =============================================================================
           procedure TVFRISS.Frissitoidobekuldes;
// =============================================================================


begin
  _idos := Timetostr(Time);
  if midstr(_idos,2,1)=':' then _idos := ' ' + _idos;
  _dattime := _megnyitottnap+' '+leftstr(_idos,5);

  _remotePath := _host + ':C:\receptor\database\frissito.fdb';

  _mezo := 'V' + _penztarkod;


  _pcs := 'UPDATE FRISSITESEK SET ' +_mezo + '='+chr(39)+_dattime+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE VERZIO='+chr(39)+'V'+_aktverzio+chr(39);

  _oke := 0;

  remotedbase.Close;
  remotedbase.databasename := _remotePath;
  TRY
    remotedbase.Connected := true;
    _OKE := 1;
  EXCEPT
     exit;
  END;

  if remotetranz.InTransaction then remotetranz.commit;
  remoteTranz.StartTransaction;
  with remoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Remotetranz.commit;
  remotedbase.close;

end;



// =============================================================================
           procedure TVFriss.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := true;
  if Valutatranz.InTransaction then Valutatranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;
end;

// =============================================================================
 function TVfriss.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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
      wShowWindow := visibility;
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

    with ProcessInfo do
      begin
        CloseHandle(hThread);
        CloseHandle(hProcess);
      end;

    Result := 0;
  end else Result := GetLastError;
end;

// =============================================================================
          procedure TVFRISS.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
//  GepUjrainditas;
  Modalresult := 1;
end;


procedure TVFRISS.Navsorszambeiro;

var _y: byte;

begin
  _y := 1;
  while _y<=24 do
    begin
      _pcs := 'UPDATE ARFOLYAM SET NAVSORSZAM='+inttostr(_y)+_sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+_dnem[_y] + chr(39);
      ValutaParancs(_pcs);
      inc(_y);
    end;
end;    




{
// =============================================================================
                  procedure TVFriss.SetRegiSvajcifrank;
// =============================================================================

begin

  IF KijelzesLeallitas THEN Memo1.Lines.Add('A kijelzõt sikerült leállitani');
  Sleep(400);

  _target := 'c:\valuta\bin\RateDisp.exe';

  Memo1.Lines.Add('Törlöm a Ratedisp.exe-t');
  IF Sysutils.DeleteFile(_target) THEN
    memo1.Lines.Add('Sikerült törölni')
  ELSE memo1.Lines.Add('Nem sikerült törölni a kijelzõt');

  SLEEP(1300);
  KijelzoCsere;

end;

// =============================================================================
                 procedure TVfriss.FoglaloRendezes;
// =============================================================================

begin
  IBDBASE.CLOSE;
  ibdbase.DatabaseName := 'c:\valuta\database\valuta.fdb';
  IBdbase.Connected := true;

  ValutaDbase.Connected := TRUE;
  IF ValutaTRANZ.InTransaction then ValutaTranz.commit;
  ValutaTranz.StartTransaction;

  ValutaTabla.tablename := 'FOGLALOK';
  _filter := 'BIZONYLATSZAM LIKE '+CHR(39)+'B%' + chr(39);
  ValutaTabla.Filter := _filter;
  ValutaTabla.Filtered := true;
  ValutaTabla.Open;
  while not vALUTAtabla.Eof do
    begin
      _biz := Valutatabla.FieldByName('BIZONYLATSZAM').asString;

      _pcs := 'SELECT * FROM FOGLALOK WHERE HIVATKOZAS='+chr(39)+_BIZ+chr(39);
      with Ibquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
          close;
        end;

      if _recno>0 then
        begin
          ValutaTabla.Edit;
          ValutaTabla.FieldByName('MOZGAS').AsInteger := 2;
          Valutatabla.Post;
        end;
      Valutatabla.next;
    end;
  ValutaTranz.commit;
  ValutaDbase.close;
  Valutatabla.close;
  ibdbase.close;
end;


// =============================================================================
                     procedure TVfriss.TranzdijChange;
// =============================================================================

begin
  _tranz[1] := 3000;
  _kezdij[1]:= 290;

  _tranz[2] := 10000;
  _kezdij[2]:= 690;

  _tranz[3] := 60000;
  _kezdij[3]:= 990;

  _tranz[4] := 100000;
  _kezdij[4]:= 1190;

  _tranz[5] := 150000;
  _kezdij[5]:= 1790;

  _tranz[6] := 300000;
  _kezdij[6]:= 2990;

  _tranz[7] := 500000;
  _kezdij[7]:= 3990;

  _tranz[8] := 1000000;
  _kezdij[8]:= 4990;

  _tranz[9] := 1500000;
  _kezdij[9]:= 5990;

  _tranz[10] := 2000000;
  _kezdij[10]:= 7990;

  ValutaParancs('DELETE FROM TRANZDIJTABLA');
  _ss :=1;
  while _ss<=10 do
    begin
      _akttranz := _tranz[_ss];
      _aktkdij  := _kezdij[_ss];

      _pcs := 'INSERT INTO TRANZDIJTABLA (TRANZAKCIO,KEZELESIDIJ,SORSZAM)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_akttranz) + ',';
      _pcs := _pcs + inttostr(_aktkdij) + ',';
      _pcs := _pcs + inttostr(_ss) + ')';
      ValutaParancs(_pcs);

      inc(_ss);
    end;

  while _ss<23 do
    begin
      _pcs := 'INSERT INTO TRANZDIJTABLA (TRANZAKCIO,KEZELESIDIJ,SORSZAM)'+_sorveg;
      _pcs := _pcs + 'VALUES (0,0,';
      _pcs := _pcs + inttostr(_ss) + ')';
      ValutaParancs(_pcs);
      inc(_ss);
    end;
  _akttranz := 999999999;
  _aktKdij := 9990;

  _pcs := 'INSERT INTO TRANZDIJTABLA (TRANZAKCIO,KEZELESIDIJ,SORSZAM)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_akttranz) + ',';
  _pcs := _pcs + inttostr(_aktkdij) + ',';
  _pcs := _pcs + inttostr(_ss) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE HARDWARE SET KEZDIJMAX=9990';
  ValutaParancs(_pcs);
  Kilepo.Enabled := True;
end;

procedure TVfriss.TradeModosito;

var _tradefdb: string;

begin
  _tradefdb := 'c:\valuta\database\trade.fdb';
  if not FileExists(_tradeFdb) then exit;

  ibDbase.close;
  ibDbase.databaseName := _tradefdb;
  ibdbase.connected := True;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;

  _pcs := 'UPDATE CIKKTORZS SET AZONOSITO=2647 WHERE AZONOSITO=2530';
  with Ibquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;

  _pcs := 'UPDATE CIKKTORZS SET AZONOSITO=2648 WHERE AZONOSITO=2550';
  with Ibquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;

  _pcs := 'UPDATE CIKKTORZS SET AZONOSITO=2649 WHERE AZONOSITO=2510';
  with Ibquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;

  _pcs := 'UPDATE CIKKTORZS SET AZONOSITO=2650 WHERE AZONOSITO=2570';
  with Ibquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  ibTranz.commit;
  ibdbase.close;

  Memo1.Lines.add('AUTÓPÁLYA FRISSITVE JÁSZ-NAGYKUN MEGYÉVEL');
end;


 // ===========================================================================
                             procedure TVFriss.IkonKirako;
// =============================================================================

var IObject: IUnKnown;
    isLink : IShellLink;
    ipFile : iPersistFile;
    PIDL   : pItemidList;
   inFolder: array[0..MAX_PATH] of char;
 TargetName: string;
   LinkName: widestring;

begin
  TargetName := 'C:\valuta\bin\otpreg.exe';
  IoBJECT    := CreateComObject(CLSID_ShellLink);
  isLink     := iObject as iShellLink;
  ipFile     := iObject as iPersistFile;

  with Islink do
    begin
      SetPath(pchar(targetName));
      SetWorkingDirectory(pchar(extractFilePath(TargetName)));
    end;

  ShGetSpecialFolderLocation(0,CSIDL_DESKTOPDIRECTORY,PIDL);
  ShGetPathFromIdList(PIDL,InFolder);
  LinkName := infolder + '\OTP LAFAGYAS.lnk';
  ipFile.Save(pwChar(Linkname),False);
end;


procedure TVFriss.FrissAtnevezes;

var _oldnevPath: string;

begin
  _sourcePath := 'c:\valuta\bin\frissito.exe';
  _oldnevPath := 'c:\valuta\bin\_rissito.exe';
  if not Fileexists(_oldnevpath) then exit;

  Sysutils.DeleteFile(_sourcepath);
  _targetpath := _sourcePath;
  _sourcePAth := 'c:\valuta\bin\_rissito.exe';

  Sysutils.RenameFile(_sourcePath,_targetpath);
end;

// =============================================================================
                     procedure TVFriss.GepUjraInditas;
// =============================================================================

begin
  WindowsExit(EWX_REBOOT or EWX_FORCE);
end;

// =============================================================================
              function WindowsExit(RebootParam: Longword): Boolean;
// =============================================================================

var
   TTokenHd: THandle;
   TTokenPvg: TTokenPrivileges;
   cbtpPrevious: DWORD;
   rTTokenPvg: TTokenPrivileges;
   pcbtpPreviousRequired: DWORD;
   tpResult: Boolean;

const
   SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';

begin
   if Win32Platform = VER_PLATFORM_WIN32_NT then
   begin
     tpResult := OpenProcessToken(GetCurrentProcess(),
       TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
       TTokenHd) ;
     if tpResult then
     begin
       tpResult := LookupPrivilegeValue(nil,
                                        SE_SHUTDOWN_NAME,
                                        TTokenPvg.Privileges[0].Luid) ;
       TTokenPvg.PrivilegeCount := 1;
       TTokenPvg.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
       cbtpPrevious := SizeOf(rTTokenPvg) ;
       pcbtpPreviousRequired := 0;
       if tpResult then
         Windows.AdjustTokenPrivileges(TTokenHd,
                                       False,
                                       TTokenPvg,
                                       cbtpPrevious,
                                       rTTokenPvg,
                                       pcbtpPreviousRequired) ;
     end;
   end;
   Result := ExitWindowsEx(RebootParam, 0) ;
end;


// =============================================================================
           procedure TVFriss.ValdataParancs(_ukaz: string);
// =============================================================================

begin
  Valdatadbase.connected := true;
  if Valdatatranz.InTransaction then Valdatatranz.Commit;

  TRY
    Valdatatranz.StartTransaction;
    with ValdataQuery do
      begin
        Close;
        sql.clear;
        sql.add(_ukaz);
        ExecSql;
      end;
    ValdataTranz.Commit;
  FINALLY
     Valdatadbase.close;
  END;
end;


function TVFriss.GettradeAdatok: boolean;

var _ptkod,_idkod,_idnev: array[1..13] of string;
    _sourcePath,_targetPath: string;

begin

  _sourcePath := 'c:\valuta\bin\trade.fdb';
  if fileexists(_sourcePath) then
    begin
      _targetPath := 'c:\valuta\database\trade.fdb';
      result := copyfileto(_sourcePath,_targetPath);
      if not result then exit;

      Sysutils.deletefile(_sourcepath);
    end;

  _ptkod[1] := '151';
  _idkod[1] := '3477';
  _idnev[1] := 'expbaja';

  _ptkod[2] := '161';
  _idkod[2] := '3484';
  _idnev[2] := 'expbekes';

  _ptkod[3] := '169';
  _idkod[3] := '3486';
  _idnev[3] := 'expcegl';

  _ptkod[4] := '157';
  _idkod[4] := '3478';
  _idnev[4] := 'expdomb';

  _ptkod[5] := '168';
  _idkod[5] := '3480';
  _idnev[5] := 'expfeh';

  _ptkod[6] := '164';
  _idkod[6] := '3485';
  _idnev[6] := 'exphod';

  _ptkod[7] := '166';
  _idkod[7] := '3482';
  _idnev[7] := 'expkisv';

  _ptkod[8] := '158';
  _idkod[8] := '3479';
  _idnev[8] := 'expkoml';

  _ptkod[9] := '167';
  _idkod[9] := '3481';
  _idnev[9] := 'expmate';

  _ptkod[10] := '160';
  _idkod[10] := '3475';
  _idnev[10] := 'pecskert';

  _ptkod[11] := '159';
  _idkod[11] := '3474';
  _idnev[11] := 'pecsuran';

  _ptkod[12] := '153';
  _idkod[12] := '3483';
  _idnev[12] := 'expszeg';

  _ptkod[13] := '152';
  _idkod[13] := '3476';
  _idnev[13] := 'expszek';

  _y := 1;
  while _y<=13 do
    begin
      if _ptkod[_y]=_penztarkod then  break;
      inc(_y);
    end;

  if _y>13 then
    begin
      result := False;
      exit;
    end;

  _aktidkod := _idkod[_y];
  _aktidnev := _idnev[_y];
  result := true;
end;

procedure TVFriss.MakeIdoszakTabla;

VAR _tablanev: string;

begin

  _tablanev := 'IDOSZAK';
  ibdbase.Connected := true;
  ibtabla.close;
  ibtabla.TableName := _tablanev;
  if ibtabla.Exists then
    begin
      ibdbase.close;
      exit;
    end;

  _pcs := 'CREATE TABLE ' + _tablaNev + ' (' +_sorveg ;
  _pcs := _pcs + 'KERTEV SMALLINT,'+_sorveg;
  _pcs := _pcs + 'KERTHO SMALLINT,'+_sorveg;
  _pcs := _pcs + 'TOLNAP SMALLINT,'+_sorveg;
  _pcs := _pcs + 'IGNAP SMALLINT,'+_sorveg;
  _pcs := _pcs + 'TOLSTRING CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'IGSTRING CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250)';
  ValutaParancs(_pcs);
end;

procedure TVfriss.Mezobovites;

begin
  _aktfdbPath := 'c:\valuta\database\valdata.fdb';

  _ho := 1;
  while _ho<=12 do
    begin
      _farok := '17' + nulele(_ho);
      _aktTablaNev := 'BF' + _farok;
      GetMezoadatok;

      ValdataDbase.connected := True;
      ValdataTabla.close;
      ValdataTabla.Tablename := _akttablanev;
      if not ValdataTabla.exists then
        begin
          Valdatadbase.close;
          inc(_ho);
          Continue;
        end;
      ValdataDbase.close;

      _aktmezonev := 'ZCOUNTS';
      _aktmezotipus := 'CHAR (4)';
      MezoHozzaAdas;

        _aktmezonev := 'RECNUMS';
      _aktmezotipus := 'CHAR (5)';
      MezoHozzaAdas;

      _aktmezonev := 'KEREKITES';
      _aktmezotipus := 'SMALLINT';
      MezoHozzaAdas;

        _aktmezonev := 'FORRAS';
      _aktmezotipus := 'CHAR (20)';
      MezoHozzaAdas;

        _aktmezonev := 'ENGEDELYEZO';
      _aktmezotipus := 'CHAR (20)';
      MezoHozzaAdas;

      inc(_ho);
    end;


  _pcs := 'ALTER TABLE UGYFEL ALTER COLUMN NEV TYPE CHAR (50) CHARACTER SET WIN1250';
  ValutaParancs(_pcs);

  _pcs := 'ALTER TABLE UGYFEL ALTER COLUMN LAKCIM TYPE CHAR (60) CHARACTER SET WIN1250';
  ValutaParancs(_pcs);

end;


function TVFriss.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================
       procedure TvFRISS.GetMezoAdatok;
// =============================================

var _mnev,_mTipus,_mChar: string;
    _mHossz: integer;

begin

   ibdbase.close;
   ibDbase.DatabaseName := _aktfdbPath;
   ibDbase.Connected := True;

   if ibTranz.InTransaction then ibTranz.Commit;
   ibtabla.close;
   ibtabla.TableName := _aktTablaNev;
   IF NOT ibTabla.Exists then
     begin
       ibdbase.close;
       exit;
     end;

   ibTabla.Open;

  // Egy új Tábla strukturájának meghatározása:

   _mezoDarab := ibTabla.FieldCount;
   ibTabla.Close;

  // A Tábla strukturájának és adatainak tömbjét:

   Setlength(_mezonev,_mezodarab);
   SetLength(_mezotipus,_mezodarab);
   SetLength(_mezoHossz,_mezodarab);
   Setlength(_mezochar,_mezodarab);

  // Az SQL parancs-sor összeállitása:

   _pcs := 'SELECT r.RDB$FIELD_NAME AS FIELD_NAME,'+_sorveg;
   _pcs := _pcs + 'f.RDB$FIELD_LENGTH AS FIELD_LENGTH,'+_sorveg;
   _pcs := _pcs + 'case f.RDB$Field_type'+_sorveg;
   _pcs := _pcs + 'WHEN 14 THEN ' + chr(39)+ 'SZÖVEG' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 27 THEN ' + chr(39)+ 'TIZEDES TÖRT' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 8 THEN ' + chr(39)+ 'EGÉSZ SZÁM' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 7 THEN ' + chr(39)+ 'EGÉSZ SZÁM' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 12 THEN ' + chr(39)+ 'DÁTUM' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 13 THEN ' + chr(39)+ 'IDÕ' + chr(39)+_sorveg;
   _pcs := _pcs + 'ELSE ' + chr(39) + 'ISMERTELEN' + chr(39)+_sorveg;
   _pcs := _pcs + 'END AS FIELD_TYPE,'+ _sorveg;
   _pcs := _pcs + 'cset.RDB$CHARACTER_SET_NAME AS FIELD_CHARSET' + _sorveg;
   _pcs := _pcs + 'FROM RDB$RELATION_FIELDS r' + _sorveg;
   _pcs := _pcs + 'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE=F.RDB$FIELD_NAME' + _sorveg;
   _pcs := _pcs + 'LEFT JOIN RDB$COLLATIONS COLL on r.RDB$COLLATION_ID=COLL.RDB$COLLATION_ID' + _sorveg;
   _pcs := _pcs + 'AND f.RDB$CHARACTER_SET_ID = coll.RDB$CHARACTER_SET_ID' + _sorveg;
   _pcs := _pcs + 'LEFT JOIN RDB$CHARACTER_SETS CSET ON f.RDB$CHARACTER_SET_ID=cset.RDB$CHARACTER_SET_ID'+_sorveg;
   _pcs := _pcs + 'WHERE r.RDB$RELATION_NAME=' + chr(39) + _aktTablaNev + chr(39) + _sorveg;
   _pcs := _pcs + 'ORDER BY r.RDB$FIELD_POSITION' + _sorveg;

  // A struktura meghatározása az SQL parancs segitségével:

  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  // A struktura adatok tömbökbe másolása a QUERYTÁBLÁBÓL:

  _cc := 0;
  while not ibQuery.Eof do
    begin
      with ibQuery do
        begin
          _mNev := FieldByName('FIELD_NAME').AsString;
          _mTipus:= FieldByName('FIELD_TYPE').AsString;
          _mHossz := FieldByName('FIELD_LENGTH').asinteger;
          _mchar := FieldByName('FIELD_CHARSET').asString;
        end;
      _mnev := trim(_mnev);
      _mezoNev[_cc] := _mNev;
      _mezotipus[_cc] := trim(_mTipus);
      _mezoHossz[_cc] := _mHossz;
      _mezochar[_cc] := trim(_mchar);
      inc(_cc);
      ibQuery.Next;
    end;
  ibQuery.close;
  ibdbase.close;
end;

// =============================================================================
                      procedure TvFRISS.MezoHozzaAdas;
// =============================================================================

begin

  _mezosorszam := ScanMezo(_aktMezoNev);
  if _mezosorszam<0 then
    begin
      with IBDbase do
        begin
          Close;
          DatabaseName := _aktFdbPath;
        end;

      _pcs := 'ALTER TABLE '+ _aktTablaNev + _sorveg;
      _pcs := _pcs + 'ADD '+ _aktmezonev+ ' '+ _aktMezoTipus;

      IBdbase.Connected := true;
      if ibtranz.InTransaction then ibtranz.commit;
      ibtranz.StartTransaction;
      with ibQuery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Execsql;
        end;
      ibTranz.commit;
      ibdbase.close;
    end;
end;

// =============================================================================
               function TVFriss.ScanMezo(_mnev: string): integer;
// =============================================================================

var i: integer;

begin
  result := -1;
  for i := 0 to (_mezodarab-1) do
    begin
      if _mnev=_mezoNev[i] then
        begin
          result := i;
          Break;
        end;
    end;
end;


  _vantrade := PemLetoltes('AC'+_penztarkod);
  if _vantrade then
    begin
      if getTradeAdatok then
        begin
          ibdbase.close;
          ibdbase.DatabaseName := 'c:\valuta\database\trade.fdb';
          ibdbase.Connected := true;
          if ibtranz.InTransaction then ibtranz.Commit;
          ibtranz.StartTransaction;
          _pcs := 'UPDATE PARAMETERS SET TERMINALID=' + chr(39)+ _aktidkod + chr(39);
          _pcs := _pcs + ',USERNAME=' + chr(39) + _aktidnev + chr(39);
          _pcs := _pcs + ',JELSZO=' + chr(39) + '123456' + chr(39);

          with Ibquery do
            begin
              Close;
              sql.clear;
              sql.Add(_pcs);
              Execsql;
              close;
            end;
          ibtranz.commit;
          ibdbase.close;

          _pcs := 'UPDATE HARDWARE SET KELLMATRICA=1';
          Valutaparancs(_pcs);

        end;
    end;


PROCEDURE TVFriss.Tulajrendezes;

var _utnum,_aktnum: integer;
    _utnev,_aktnev: string;

begin
  Valutadbase.connected := true;
  if Valutatranz.InTransaction then valutatranz.commit;
  Valutatranz.StartTransaction;

  ValutaTabla.close;
  ValutaTabla.Tablename := 'UJTULAJOK';
  ValutaTabla.indexfieldNames := 'UGYFELSZAM';
  ValutaTabla.Open;
  ValutaTabla.first;
  _utnum := 0;
  _utnev := 'NN';
  while not ValutaTabla.eof do
    begin
      _aktnev := trim(Valutatabla.fieldByNAme('TULAJNEV').asstring);
      _aktnum := Valutatabla.fieldByName('UGYFELSZAM').asInteger;
      if (_aktnum=_utnum) and (_utnev=_aktnev) then
        begin
          Valutatabla.edit;
          Valutatabla.Delete;
    //      Valutatabla.post;
        end;
      _utnev := _aktnev;
      _utnum := _aktnum;
      Valutatabla.Next;
    end;
  Valutatranz.commit;
  Valutadbase.close;
end;

// =============================================================================
              procedure TvFriss.Jogirendezes;
// =============================================================================

var _j: word;

begin
   for _j := 1 to 800 do _type[_j] := 1;

   _pcs := 'SELECT * FROM JOGISZEMELY' + _sorveg;
   _pcs := _pcs + 'ORDER BY JOGISZEMELYNEV';

   ibdbase.close;
   ibDbase.DatabaseName := 'c:\valuta\database\valuta.fdb';
   IBdbase.connected := True;

   with ibquery do
     begin
       Close;
       sql.clear;
       sql.Add(_pcs);
       Open;
     end;

   _cc := 0;
   while not ibquery.Eof do
     begin
       inc(_cc);
       _tnev   := ibQuery.FieldByNAme('JOGISZEMELYNEV').asString;
       _tnev   := trim(leftstr(_tnev,14));
       _tmbnev := ibQuery.fieldByName('MEGBIZOTTNEVE').asString;
       _tmbnev := trim(leftstr(_tmbnev,14));
       _tuszam := ibQuery.FieldByNAme('UGYFELSZAM').asInteger;
       _nev[_cc]   := _tnev;
       _mbnev[_cc] := _tmbnev;
       _uszam[_cc] := _tuszam;
       ibquery.next;
     end;
   ibquery.close;
   ibdbase.close;

   _jdarab := _cc;

   // ----------------------------------
   _cc := 1;
   while _cc<=_jdarab do
     begin
       _cnev := _nev[_cc];
       _cmbnev := _mbnev[_cc];

       _ss := _cc+1;
       while _ss<=_jdarab do
         begin
           _snev := _nev[_ss];
           _smbnev := _mbnev[_ss];
           if _snev>_cnev then break;

           if _cmbnev=_smbnev then
             begin
               _type[_cc]:= 2;
               Break;
             end;
           inc(_ss);
         end;
       inc(_cc);
     end;

   // ---------------------------------------------

  _cc :=1;
  while _cc<=_jDarab do
    begin
      _aktType := _type[_cc];
      _aktNum  := _uszam[_cc];

      _pcs := 'UPDATE JOGISZEMELY SET TOROLVE='+inttostr(_aktType)+_sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_aktnum);
      ValutaParancs(_pcs);
      inc(_cc);
    end;

end;
}



END.










