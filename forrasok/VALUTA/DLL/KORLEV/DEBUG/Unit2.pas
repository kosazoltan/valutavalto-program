unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, idglobal, IBDatabase, DB,strutils,
  IBCustomDataSet, IBQuery, Grids, DBGrids, ExtCtrls, wininet, dateutils;

type
  TKORLEVEL = class(TForm)
    ServerQuery   : TIBQuery;
    ServerDbase   : TIBDatabase;
    ServerTranz   : TIBTransaction;

    KorQuery      : TIBQuery;
    KorDbase      : TIBDatabase;
    KorTranz      : TIBTransaction;

    LevelSOURCE   : TDataSource;

    ValutaQuery   : TIBQuery;
    ValutaDbase   : TIBDatabase;
    ValutaTranz   : TIBTransaction;

    LevelRacs     : TDBGrid;


    OlvasoGomb    : TBitBtn;
    QuitGomb      : TBitBtn;
    PathKereso    : TOpenDialog;

    Kilepo        : TTimer;

    CimPanel      : TPanel;
    MessPanel     : TPanel;
    Panel2        : TPanel;
    Nyelv         : TPanel;
    LevelRacsPanel: TPanel;
    RACSFUGGONY   : TPanel;
    Tartpanel     : TPanel;

    Label2        : TLabel;
    Label1        : TLabel;

    LastYearGomb  : TBitBtn;
    ArchiveGomb   : TBitBtn;

    procedure AlapAdatBeolvasas;
    procedure ArchiveGombClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure EgyNyelv;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure KorlevelLetoltes;
    procedure KorlevelOlvasas;
    procedure Korparancs(_ukaz: string);
    procedure LastYearGombClick(Sender: TObject);
    procedure LeveletValasztott;
    procedure LevelRegisztralas;
    procedure LevelRacsDblClick(Sender: TObject);
    procedure LevelRacsKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure MessKijelzes;
    procedure OlvasoGombClick(Sender: TObject);
    procedure Readregist(_ss: integer);

    function Adatbeolvasas: boolean;
    function GetIdkod: string;
    function Hundatetostr(_caldat: TDatetime): string;
    function Korleveldownload(_ss: integer): boolean;
    function LevelLetoltes: boolean;
    function Nulele(_b: byte): string;
    function ShowMeOfficePath: string;
    function Vaninternet: boolean;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KORLEVEL: TKORLEVEL;
  _kortype : integer;

  _lastloaded,_lastletter,_lastread: word;


  _host       : string;
  _userId     : string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';

  _ArchiveFlag: byte; // 0=idei, 1=múlt évi, 2=archive
  _pkod: byte;

  _remoteKorFdb : string;
  _remoteProsFdb: string;

  _sajatSorszam,_serversorszam,_neednum,_recno,_sorszam,_olvasott: integer;
  _olvasatlan,_code: integer;

  _dolgsorszam,_lastreadletter: word;
  _sikeres,_zalog: boolean;

  _needLett,_readLett,_newlett: array[1..30] of word;

  _mess,_prosnev,_pcs,_datum,_iktatoszam,_tartalom,_filenev,_readFileNev: string;
  _localPath,_remotefile,_aktidkod,_sofficepath,_mamas,_pks,_remotedir: string;
  _sorveg: string = chr(13)+chr(10);

  _height,_width,_top1,_top2,_left1,_left2: word;

  _ftpport: integer = 21100;

  _hNet,_hFTP: HINTERNET;


  function korlevelrutin(_para: integer): integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
      function korlevelrutin(_para: integer): integer; stdcall;
// =============================================================================

begin
  Korlevel := TKorlevel.Create(Nil);
  _kortype := _para;
  result   := Korlevel.ShowModal;
  Korlevel.Free;
end;

// =============================================================================
             procedure TKORLEVEL.FormActivate(Sender: TObject);
// =============================================================================

begin
 //  _kortype :=1;   // !!!!!!!!!!!!!!!!!!!!!! TESZT

  _aktidkod   := '';   // a belépett pénztáros ID-KÓDJA
  _lastloaded := 0;    // az utolsó letöltött levél
  _lastLetter := 0;    // az utolsó megirt levél
  _lastread   := 0;    // az utolsó olvasott levél

  Korlevel.Visible := false;
  AlapAdatBeolvasas;

//  _remoteKorFdb := _HOST +':c:\receptor\database\korltest.fdb';
  _remoteKorFdb := _HOST + ':c:\receptor\database\korlevel.fdb';
  _remoteProsFdb:= _HOST + ':c:\receptor\database\ptarosok.fdb';

  if not Adatbeolvasas then
    begin
      Kilepo.Enabled := true;
      exit;
    end;

  // Megadva: _zalog,_lastletter,_dolgsorszam,_lastread,_lastloaded

  Nyelv.Left := -300;
  Nyelv.Visible := true;

  Messpanel.Caption := '';
  Racsfuggony.Visible := False;

  with LevelracsPanel do
    begin
      Visible := False;
      Top     := -600;
      Left    := -800;
    end;

  Korlevel.Visible := true;
  Korlevel.Repaint;

  _mamas := Hundatetostr(DATE);

  // Paramétertõl függöen: 1= Letöltés, 2=Olvasás

  if _kortype=1 then
    begin
      Egynyelv;
      KorlevelLetoltes;
      Kilepo.Enabled := true;
      exit;
    end else
    begin
      Korlevelolvasas;
    end;
end;

// =============================================================================
                procedure TKorlevel.KorlevelLetoltes;
// =============================================================================

// Új körlevelek letöltése, olvasás ellenörzése:

var _y: integer;

begin

  // Ha nincs internet - kilép a DLL-böl:

  if not Vaninternet then
    begin
      ModalResult := 2;
      exit;
    end;

  // Ha a szerveren már újabb körlevél van - akkor azt le kell tölteni:
  if _lastletter>_lastloaded then
    begin
       _y := _lastloaded + 1;
       while _y<=_lastletter do
         begin
            KorlevelDownLoad(_y);
            inc(_y);
         end;
    end;

  //--------------------------------------------------------------------

  Egynyelv;
  _olvasatlan := _lastletter-_lastread;
  if _olvasatlan<0 then _olvasatlan := 0;

  Korlevel.Visible := true;
  Korlevel.Repaint;

  if _olvasatlan>0 then _mess := inttostr(_olvasatlan)+' olvasatlan levelet találtam '+_prosnev+' részére'
  else _mess := 'Nincs olvasatlan levele';
  Nyelv.Visible := false;
  MessKijelzes;
end;

// =============================================================================
          function TKorlevel.Korleveldownload(_ss: integer): boolean;
// =============================================================================

// Egy új körlevél letöltése, regisztrálása: (Sorszama a parameter)

begin
  Result := False;

  // Beolvassa a szerver-adatbázisból a kért körlevél  mezõadatait:

  Serverdbase.close;
  Serverdbase.Databasename := _remoteKorFdb;
  try
    ServerDbase.connected := True;
  except
    exit;
  end;

  _pcs := 'SELECT * FROM KORLEVEL' + _sorveg;

  if _zalog then _pcs := 'SELECT * FROM ZALOGLEVEL' + _sorveg;

  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ss);

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno:= recno;
    end;

  if _recno=0 then
    begin
      ServerQuery.close;
      Serverdbase.close;
      result := False;
      exit;
    end;

  with ServerQuery do
    begin
      _datum      := trim(FieldByName('DATUM').AsString);
      _iktatoszam := trim(FieldByName('IKTATOSZAM').asstring);
      _tartalom   := trim(FieldByName('TARTALOM').AsString);
      _filenev    := trim(FieldbyName('FILENEV').AsString);
      _sorszam    := FieldbyName('SORSZAM').AsInteger;
      Close;
    end;
  ServerDbase.close;

  // -------------------------

  // A kért levél letöltése a sajat KORLEVEL directoryba:

  _mess := 'Levél letöltés: '+ leftstr(_tartalom,15);
  Messkijelzes;
  result := LevelLetoltes;

  // Ha sikerült a letöltés - regisztrálja a levelet:

  IF result then
    begin
      _mess := 'Sikeres letöltés';
      MessKijelzes;
      sleep(510);
      LevelRegisztralas;
    end;
end;

// =============================================================================
          function TKorlevel.LevelLetoltes: boolean;
// =============================================================================

begin

  // A _filenev nevü körlevél letöltése a saját KORLEVEL directorba:
  // Wininet Ftp rutinjával

  _localPath := 'c:\korlevel\' + _filenev;
  _remoteFile := _filenev;

  Result := False;
  if not Vaninternet then exit;

  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then  exit;

  _hFtp := Nil;
  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
            Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hFtp=Nil then
    begin
      InternetCloseHandle(_hnet);
      exit;
    end;
  _remotedir := '\KORLEVEL';
  IF _zalog then _remotedir := _remotedir + '\ZALOG';

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_REMOTEDIR));
  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      exit;
    end;

  result := FtpGetFile(_hFTP,pChar(_remotefile),pChar(_localpath),False,0,
                                              FTP_TRANSFER_TYPE_BINARY,0);

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);
end;


// =============================================================================
                procedure TKorlevel.LevelRegisztralas;
// =============================================================================

begin
  // Ha esetleg ez a levél már regisztrálva volt, törli a régi regisztrációt

  _pcs := 'DELETE FROM IKTATO' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  KorParancs(_pcs);

  // Az IKTATO táblába regisztráljuk a kért körlevelet:

  _pcs := 'INSERT INTO IKTATO (DATUM,SORSZAM,TARTALOM,IKTATOSZAM,FILENEV)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
  _pcs := _pcs + inttostr(_sorszam) + ',';
  _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
  _pcs := _pcs + chr(39) + _iktatoszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _filenev + chr(39) + ')';
  KorParancs(_pcs);

  //  Az utolsó sorszámot és be kell irni:

  _pcs := 'UPDATE PARAMETERS SET LASTSORSZAM=' + inttostr(_sorszam);
  KorParancs(_pcs);
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                  procedure TKorlevel.KorlevelOlvasas;
// =============================================================================

var _y: word;

begin
  Top    := _top2;
  Left   := _left2;
  Height := 50;
  Width  := 80;

  _y := 1;
  while _y<=8 do
    begin
      width := width +80;
      height := height + 50;
      inc(_y);
      sleep(30);
    end;

  Height := 450;
  Width  := 730;

  Korlevel.Repaint;

  _archiveFlag := 0;
  Levelsource.Enabled := false;
  _pcs := 'SELECT * FROM PARAMETERS';

  Kordbase.Connected := true;
  with KorQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      _sofficepath := trim(FieldByNAme('SOFFICEPATH').AsString);
      Close;
    end;
  Kordbase.close;

  Korlevel.Visible := true;
  Korlevel.Repaint;

  if not FileExists(_sofficepath) then
    begin
      _sofficepath :=  ShowMeOfficePath;
      if not Fileexists(_sofficePath) then
        begin
          Modalresult := 2;
          exit;
        end;
    end;

  // ------------------------------------------------------------

  _pcs := 'SELECT * FROM IKTATO' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  Kordbase.Connected := true;
  with Korquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  LevelRacs.DataSource := LevelSource;

  with LevelracsPanel do
    begin
      top := 0;
      Left := 0;
      Visible := true;
      repaint;
    end;

  Levelsource.Enabled := True;
  Activecontrol := LevelRacs;
end;


// =============================================================================
                function TKorlevel.ShowMeOfficePath: string;
// =============================================================================

var _sPath: string;

begin
  if Pathkereso.Execute then
    begin
      _sPath := Pathkereso.FileName;
      _pcs := 'UPDATE PARAMETERS SET SOFFICEPATH='+chr(39)+_sPath+chr(39);
      KorParancs(_pcs);
    end;
  result := _sPath;
end;


// =============================================================================
             procedure TKORLEVEL.OLVASOGOMBClick(Sender: TObject);
// =============================================================================

begin
  LeveletValasztott;
end;

// =============================================================================
          procedure TKORLEVEL.LEVELRACSDblClick(Sender: TObject);
// =============================================================================

begin
  LeveletValasztott;
end;

// =============================================================================
     procedure TKORLEVEL.LEVELRACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================


begin
  if ord(key)<>13 then exit;
  LeveletValasztott;
end;

// =============================================================================
               procedure TKorlevel.LeveletValasztott;
// =============================================================================

var _readpath: string;
    _pacs: Pchar;

begin
  _readfileNev := trim(Korquery.FieldByName('FILENEV').asstring);
  _sorszam := Korquery.FieldByName('SORSZAM').asInteger;
  _tartalom := trim(Korquery.FieldByName('TARTALOM').AsString);
  TartPanel.caption := _tartalom;

  with RacsFuggony do
    begin
      top := 40;
      Left := 8;
      visible := True;
      Repaint;
    end;
  sleep(1600);

  _readPath := 'C:\KORLEVEL';
  IF _archiveFlag=1 then _readpath := _readpath + '\LASTYEAR';
  IF _archiveFlag=2 then _readpath := _readpath + '\ARCHIVE';

  _readPath := _readPath + '\' + _readfilenev;


  _pcs := _sofficepath + ' ' + _readPath;
  _pacs := pchar(_pcs);

  if WinexecAndWait32(_pacs,sw_Normal)=0 then ReadRegist(_sorszam);
  Racsfuggony.Visible := False;

end;


// =============================================================================
          procedure TKorlevel.Readregist(_ss: integer );
// =============================================================================


var _aktidos,_mikor: string;

begin
  _aktidos := timetostr(TIME);

  if midstr(_aktidos,2,1)=':' then _aktidos := '0' + _aktidos;
  _aktidos := leftstr(_aktidos,2)+midstr(_aktidos,4,2);

  _mikor := midstr(_mamas,6,2)+midstr(_mamas,9,2)+_aktidos;

  _pcs := 'SELECT * FROM SIGNAL' + _sorveg;
  _pcs := _pcs + 'WHERE (DOLGSORSZAM='+inttostr(_dolgsorszam)+') AND (LETTERNUM='+inttostr(_ss)+')';

  Serverdbase.close;
  serverdbase.databaseName := _remoteKorFdb;

  TRY
    Serverdbase.connected := true;
  EXCEPT
    Modalresult := 1;
    exit;
  end;

  with serverQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _recno := Recno;
      close;
    end;

  if _recno=0 then
    begin
      _pcs := 'INSERT INTO SIGNAL (DOLGSORSZAM,LETTERNUM,MIKOR)'+ _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_dolgsorszam) + ',';
      _pcs := _pcs + inttostr(_ss) + ',';
      _pcs := _pcs + chr(39) + _mikor + chr(39) + ')';

      if servertranz.InTransaction then servertranz.commit;
      servertranz.StartTransaction;
      with ServerQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          ExecSql;
        end;
      ServerTranz.Commit;
    end;
  serverdbase.close;
  serverdbase.databasename := _remoteProsFdb;
  serverdbase.Connected := true;

  if servertranz.InTransaction then servertranz.Commit;
  Servertranz.StartTransaction;

  if _ss>_lastread then
    begin
      _pcs := 'UPDATE PENZTAROSOK SET LASTREADLETTER='+inttostr(_ss)+_sorveg;
      _pcs := _pcs + 'WHERE IDKOD=' + CHR(39) + _aktidkod + chr(39);
      with ServerQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          ExecSql;
        end;
    end;
  Servertranz.Commit;
  serverdbase.close;
  serverquery.close;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$ segéd programok $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
                 function TKorlevel.Vaninternet: boolean;
// =============================================================================

var
    _dwConnType: integer;

begin

   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;

// =============================================================================
                     procedure TKorlevel.MessKijelzes;
// =============================================================================

begin
  Messpanel.Caption := _mess;
  Messpanel.repaint;
end;

// =============================================================================
               procedure TKorlevel.Korparancs(_ukaz: string);
// =============================================================================

begin
  Kordbase.Connected := true;
  if korTranz.InTransaction then Kortranz.Commit;
  Kortranz.StartTransaction;
  with Korquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Kortranz.commit;
  Kordbase.close;
end;


// =============================================================================
   function TKorlevel.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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
             procedure TKORLEVEL.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;


// =============================================================================
             procedure TKORLEVEL.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;

// =============================================================================
                    procedure TKorlevel.Egynyelv;
// =============================================================================

var _b: integer;

begin
  _b := -76;
  while _b<381 do
    begin
      nyelv.left := _b;
      nyelv.repaint;
      sleep(50);
      _b := _b + 76;
    end;
end;


// =============================================================================
            procedure TKORLEVEL.LASTYEARGOMBClick(Sender: TObject);
// =============================================================================

begin
  _archiveFlag := 1;
  LastYearGomb.Enabled := False;
  ArchiveGomb.Enabled := true;
  _pcs := 'SELECT * FROM LASTYEAR' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  Kordbase.Connected := true;
  with Korquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  LevelRacs.DataSource := LevelSource;

  with LevelracsPanel do
    begin
      top := 0;
      Left := 0;
      Visible := true;
      repaint;
    end;

  Levelsource.Enabled := True;
  Activecontrol := LevelRacs;
end;


// =============================================================================
            procedure TKORLEVEL.FormCreate(Sender: TObject);
// =============================================================================

begin

  _width := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  _top1 := trunc((_height-81)/2);
  _top2 := trunc((_height-450)/2);
  _left1 := trunc((_width-405)/2);
  _left2 := trunc((_width-730)/2);

  Top := _top1;
  Left := _left1;
  Height := 81;
  Width := 402;

end;

// =============================================================================
        function TKorlevel.HunDateTostr(_caldat: TDateTime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;

// =============================================================================
               function TKorlevel.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
                    function TKorlevel.GetIdkod: string;
// =============================================================================


begin
   ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      result := trim(FieldByName('IDKOD').asString);
      Close;
    end;
  ValutaDbase.close;
end;


// =============================================================================
                    function TKorlevel.Adatbeolvasas: boolean;
// =============================================================================
{

    Saját géprõl= _aktidkod   = VALUTA.FDB -> HARDWARE -> IDKOD
                  _lastloaded = KORLEVEL.FDB -> PARAMETERS -> LASTSORSZAM

    Szerverrõl  = _lastletter = (ip)KORLEVEL.FDB -> ADATOK -> LASTSORSZAM
                  _lastread   = (ip)PTAROSOK.FDB -> PENZTAROSOK -> LASTLETTER
                                                    while _aktidkod = IDKOD
}
begin
  result := false;

  _zalog := False;
  if _pkod>150 then _zalog := True;

  // ---------------------------------

  Kordbase.connected := True;
  with Korquery do
    begin
      close;
      Sql.clear;
      Sql.add('SELECT * FROM PARAMETERS');
      Open;
      _lastLoaded := FieldByName('LASTSORSZAM').asInteger;
      Close;
    end;
  Kordbase.close;

  // ---------------------------------

  TRY
    serverdbase.close;
    Serverdbase.databasename := _remotekorfdb;
    Serverdbase.connected := true;
  EXCEPT
    exit;
  END;

  with ServerQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM ADATOK');
      Open;
    end;
  if not _zalog then _lastletter := ServerQuery.FieldByname('UTSORSZAM').asInteger
  else _lastletter := ServerQuery.FieldByName('UTZALOGSORSZAM').AsInteger;

  ServerQuery.Close;
  Serverdbase.close;

  // -------------------------------------

  if _aktidkod<>'' then
    begin
      _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
      _pcs := _pcs + 'WHERE IDKOD=' + chr(39) + _aktidkod + chr(39);

      TRY
        Serverdbase.databasename := _remoteProsFdb;
        Serverdbase.connected := true;
      EXCEPT
         exit;
      END;

      with serverQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          _dolgsorszam := ServerQuery.FieldByName('SORSZAM').asInteger;
          _lastread    := Serverquery.FieldByName('LASTREADLETTER').asInteger;
        end;
      Serverquery.close;
      Serverdbase.close;
      result := true;
    end;
end;

// =============================================================================
             procedure TKORLEVEL.ARCHIVEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _archiveFlag := 2;
  ArchiveGomb.Enabled := False;
  LastYearGomb.Enabled := true;
  _pcs := 'SELECT * FROM ARCHIVE' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  Kordbase.Connected := true;
  with Korquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  LevelRacs.DataSource := LevelSource;

  with LevelracsPanel do
    begin
      top := 0;
      Left := 0;
      Visible := true;
      repaint;
    end;

  Levelsource.Enabled := True;
  Activecontrol := LevelRacs;
end;

// =============================================================================
               procedure TKorlevel.AlapadatBeolvasas;
// =============================================================================

begin
 Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _aktidkod := trim(FieldByName('IDKOD').asString);
      _HOST := trim(FieldByNAme('HOST').asString);
      Close;

      Sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _pks := trim(FieldByName('PENZTARKOD').AsString);
      Close;

    end;
  Valutadbase.close;

  val(_pks,_pkod,_code);
end;
end.
