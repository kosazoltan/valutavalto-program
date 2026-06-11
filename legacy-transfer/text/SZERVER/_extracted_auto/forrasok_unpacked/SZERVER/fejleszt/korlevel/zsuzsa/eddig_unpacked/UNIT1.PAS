unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,Mapi,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,Registry,
  IBQuery, strutils, wininet, dateutils,TlHelp32, jpeg, IBTable, Grids, DBGrids;

type
  TForm1 = class(TForm)

    OpenDialog1      : TOpenDialog;

    DolgNevPanel     : TPanel;
    IdPanel          : TPanel;
    ImagePanel       : TPanel;
    JelszoPanel      : TPanel;
    KivalasztottPanel: TPanel;
    KorlCimPanel     : TPanel;
    ListaCimPanel    : TPanel;
    ListaPanel       : TPanel;
    Menupanel        : TPanel;
    NagyFuggony      : TPanel;
    RacsPanel        : TPanel;
    SendPanel        : TPanel;
    TartalomPanel    : TPanel;

    Label2           : TLabel;
    Label3           : TLabel;
    Label4           : TLabel;
    Label5           : TLabel;
    Label6           : TLabel;

    BitBtn1          : TBitBtn;
    BitBtn2          : TBitBtn;
    EzVagyokGomb     : TBitBtn;
    IdMegsemGomb     : TBitBtn;
    KijeloloGomb     : TBitBtn;
    KilepoGomb       : TBitBtn;
    ListazoGomb      : TBitBtn;
    MegsemSendGomb   : TBitBtn;
    Olvasogomb       : TBitBtn;
    StartSendGomb    : TBitBtn;
    SzetkuldoGomb    : TBitBtn;

    Shape1           : TShape;
    Shape2           : TShape;
    Shape3           : TShape;
    Shape4           : TShape;

    servertabla      : TIBTable;

    ProsQuery        : TIBQuery;
    ServerQuery      : TIBQuery;

    ProsDbase        : TIBDatabase;
    ServerDbase      : TIBDatabase;

    ProsTranz        : TIBTransaction;
    ServerTranz      : TIBTransaction;

    Image1           : TImage;

    KorSource        : TDataSource;
    ProsSource       : TDataSource;

    KorRacs          : TDBGrid;
    ProsRacs         : TDBGrid;

    Kilepo           : TTimer;

    JelszoEdit       : TEdit;

    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure DolgozokTombbe;
    procedure Ertesites;
    procedure EzVagyokGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IdMegsemGombClick(Sender: TObject);
    procedure JELSZOEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KijeloloGombClick(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure KorRacsDblClick(Sender: TObject);
    procedure ListazoGombClick(Sender: TObject);
    procedure MegsemSendGombClick(Sender: TObject);
    procedure Menube;
    procedure OlvasogombClick(Sender: TObject);
    procedure OnlyControl;
    procedure P1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure ReadIdKod;
    procedure ReadLastItem;
    procedure RemoveTiltott;
    procedure ServerParancs(_ukaz: string);
    procedure SetIdKod;
    procedure Setvalasztottfile;
    procedure SetvezetoTomb;
    procedure SofficeLeallitas;
    procedure Sorrendregen;
    procedure StartSendGombClick(Sender: TObject);
    procedure SzetKuldoGombClick(Sender: TObject);
    procedure TartalomTombbe;
    procedure WriteRegistry;

    function EmailKuldes(_aktemail: string): Cardinal;
    function FillNull(_num:word): string;
    function Getiktatoszam: integer;
    function GetsofficePath: string;
    function GetTiltott: byte;
    function LevelLetoltes(_fn: string): boolean;
    function Libkereso: integer;
    function PfKereso: integer;
    function Readregistry: boolean;
    function SendEMail(Handle: THandle; Mail: TStrings): Cardinal;
    function SendRoundLetter: boolean;
    function Vaninternet: boolean;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _KorlevPath : string = 'C:\RECEPTOR\DATABASE\KORLEVEL.FDB';
//  _KorlevPath : string = 'C:\RECEPTOR\DATABASE\KORLTEST.FDB';

  proc          : PROCESSENTRY32;
  _handle       : HWND;
  _Looper       : BOOL;

  _signPath     : string = 'c:\sign.txt';
  _idPath       : string = 'c:\id.txt';
  _lofficePath  : string = 'c:\loffpath.txt';
  _korleveldir  : string = 'c:\korlevel';
  _spath        : string = 'c:\soffpath.txt';
  _lastitempath : string = 'c:\last.txt';

  _host        : string  = '185.43.207.99';
  _ftpPort     : integer = 21100;
  _userId      : string  = 'ebc-10%';
  _ftpPassword : string  = 'klc+45%';

  _vNev,_eMail : array[1..13] of string;
  _vKod        : array[1..13] of word;

  _szig        : array[0..10] of string;
  _p           : array[1..180] of TPanel;
  _typ         : array[1..180] of string;
  _pfdir       : array[0..2] of string;

  _pnev        : array[0..500] of string;
  _psor        : array[0..500] of word;

  _kltart      : array[0..500] of string;
  _klsors      : array[0..500] of word;

  _sorveg: string = chr(13)+chr(10);

  _hNet,_hFTP: HINTERNET;
  _srec      : TSearchRec;

  _iras,_olvas: textfile;
  _pacs: Pchar;

  _aktdir,
  _currLettName,
  _dirnev,
  _farok,
  _iFileNev,
  _iktatostring,
  _jelszo,
  _korlevdir,
  _korlExePath,
  _letterName,
  _letterpath,
  _lettExt,
  _libdir,
  _localPath,
  _mamas,
  _mess,
  _pcs,
  _prosNev,
  _readSignName,
  _remoteFile,
  _serverFdbPath,
  _serverProsPath,
  _sign,
  _sofficepath,
  _tartalom: string;

  _code,
  _recno,
  _utolsosorszam: integer;

  _aktev,
  _aktsorszam,
  _available,
  _cc,
  _dolgozoDarab,
  _idSorszam,
  _iktatoszam,
  _lastread,
  _lastreadItem,
  _read,
  _tartalomdarab: word;

  _extlen,
  _lettlen,
  _libdarab,
  _pc,
  _pfdarab,
  _tiltottDb,
  _vezetoDarab: byte;

  _loaded,
  _sikeres,
  _vanAutoexec: BOOLEAN;

implementation

uses Unit2;

{$R *.dfm}


// =============================================================================
           procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 100;
  Left := 210;
  Korlcimpanel.Repaint;

  _serverFdbPath  := _host + ':' + _korLevPath;
  _serverProsPath := _host + ':C:\RECEPTOR\DATABASE\PTAROSOK.FDB';

  _korlevdir   := GetCurrentDir;
  _korlExePath := _korlevDir + '\KORLEVEL.EXE';

  // ------------ Panelek eltüntetése ---------------------------------------

  MenuPanel.Visible         := False;
  DolgNevpanel.visible      := False;
  IdPanel.Visible           := False;
  JelszoPanel.Visible       := False;
  Sendpanel.Visible         := False;
  KivalasztottPanel.Visible := False;
  ListaPanel.Visible        := False;
  Nagyfuggony.Visible       := False;
  ImagePanel.Visible        := False;

  // ------------ Szétküldö gomb letiltva -----------------------------------

  szetkuldoGomb.Enabled     := False;
  SetvezetoTomb;

  // CSak Control-paraméter ?

  _pc := ParamCount;

  _tiltottDb := GetTiltott;

  // -------------------- Ahol nincs körlevél directory ott csinál ----------

  if not DirectoryExists(_korleveldir) then CreateDir(_korleveldir);

  // ---------- A soffice exe elérési útvonalát beolvassa -------------------

  _sofficePath := GetSofficePath;

   //----------- A korlevél fdb beállítása -----------------------

  _aktev := yearof(date);
  _mamas := leftstr(datetostr(Date),10);

  _currlettname := 'KORL' + inttostr(_aktev);
  _readSignName := 'SIGN' + inttostr(_aktev);

  // ------ Ha nincs a gépen szignó rögzitve, bekéri és rögziti -------------
  // ------  Ha rögzitve van, akkor beolvassa a SIGN változóba --------------

  if not FileExists(_signPath) then
    begin
      _sign := Inputbox('Szignó bekérése','SZIGNÓ: ','    ');
      _sign := uppercase(trim(_sign));
      if _sign='' then
        begin
          Kilepo.Enabled := True;
          exit;
        end;

      if length(_sign)>4 then _sign := leftstr(_sign,4);

      AssignFile(_iras,_signPath);
      rewrite(_iras);
      write(_iras,_sign);
      Closefile(_iras);
    end else
    begin
      AssignFile(_olvas,_signPath);
      Reset(_olvas);
      read(_olvas,_sign);
      CLosefile(_olvas);
    end;

  _iktatoszam := GetIktatoszam;

  if not FileExists(_idpath) then
    begin
      SetIdkod;
      exit;
    end else
    begin
      ReadIdkod;
      ReadLastItem;
      if _idsorszam=0 then exit;
    end;

 _vanautoexec := ReadRegistry;
 if not _vanautoexec then WriteRegistry;

 if _pc>0 then
    begin
      OnlyControl;
      exit;
    end;

  if _tiltottDb>0 then REmoveTiltott;

  with ImagePanel do
    begin
      Top := 80;
      Left := 16;
      Visible := True;
    end;

  Menube;
  Activecontrol := KijeloloGomb;
end;

// =============================================================================
                          procedure TForm1.SetIdkod;
// =============================================================================

begin
  Prosdbase.Close;
  Prosdbase.DatabaseName := _serverProsPath;
  Prosdbase.Connected := true;

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  with IdPanel do
    begin
      Top := 110;
      Left := 250;
      Visible := True;
    end;
  Activecontrol := ProsRacs;
end;

// =============================================================================
            procedure TForm1.KIJELOLOGOMBClick(Sender: TObject);
// =============================================================================

//  ------------------ Egy körlevél kiválasztása -------------------------------

begin

  // Ha nem választott file-t -> akkor vége

  if not Opendialog1.Execute then exit;

  // Több kijelölés nincs. A körlevél path-ja a saját gépen = _localPath


  KijeloloGomb.Enabled := False;
  _localPath := Opendialog1.Filename;

  //  A _localpath alapján kiszámitja : _remotefile,_tartalom,_iktatoszam

  SetValasztottFile;

  // Kijelzi, hogy mit választott ki - és bekapcsolja a szétküldö gombot:

  with KivalasztottPanel do
    begin
      Caption := 'KIVÁLASZTVA : ' + _TARTALOM;
      Top := 344;
      Left := 16;
      Visible := True;
      Repaint;
    end;
  SzetKuldoGomb.Enabled := true;

end;


// =============================================================================
                    procedure TForm1.SetValasztottFile;
// =============================================================================

//   -------- A _localPath alapján adatokat állít össze -------------------

begin
  _lettername := extractfileName(_localpath);
  _lettext := extractfileExt(_lettername);
  _lettlen := length(_lettername);
  _extlen  := length(_lettext);
  _tartalom := leftstr(_lettername,_lettlen-_extlen);
  if length(_tartalom)>80 then _tartalom := leftstr(_tartalom,76) + '...';

  _iktatoszam := GetIktatoszam;
  _iktatostring := _sign + fillNull(_iktatoszam);
  _remotefile := _iktatostring + _lettext;
end;



// =============================================================================
            procedure TForm1.SZETKULDOGOMBClick(Sender: TObject);
// =============================================================================

// ------  A kiválasztott körlevél felmásolása a szerverre és iktatása ------

begin

  // Ha nincs meg a körlevél path-ja a gépen, akkor semmi sincs

  if _localPath='' then exit;

  // A menü eltünik

  Menupanel.Visible := False;

  TartalomPanel.Caption := _tartalom;
  TartalomPanel.Repaint;
  KivalasztottPanel.Visible := False;

  // Elöjön a send-panel és a start send gomb lesz érvényes:

  with sendpanel do
    begin
      Left := 16;
      Top  := 316;
      Visible := true;
      Repaint;
    end;
  Activecontrol := StartSendGomb;
end;

// =============================================================================
           procedure TForm1.STARTSENDGOMBClick(Sender: TObject);
// =============================================================================


var _sr: word;

// Elinditja a választott körlevél felmásolását a szerverre:

begin
   SendPanel.Visible := False;
   if not SendRoundletter then
    begin
      ShowMessage('SIKERTELEN SZÉTKÜLDES');
      exit;
    end;

  _sr := trunc(2*_ikTatoszam);

  _pcs := 'INSERT INTO ' + _currLettName + ' (IKTATOSZAM,DATUM,TARTALOM,';
  _pcs := _pcs + 'SORSZAM,SORREND,STORNO,FILENEV)'+ _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + _iktatostring + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
  _pcs := _pcs + inttostr(_IKTATOSZAM) + ',';
  _pcs := _pcs + inttostr(_sr) + ',1,';
  _pcs := _pcs + chr(39) + _remotefile + chr(39)+')';

  ServerParancs(_pcs);

  _pcs := 'UPDATE IKTATOSZAM SET IKTATOSZAM='+inttostr(_iktatoszam);
  ServerParancs(_pcs);

  // -----------------------------------------------------------

  SorrendRegen;

  Ertesites;

  _mess := _remotefile+' körlevél sikeresen szétküldve';
  ShowMessage(_mess);
  with MenuPanel do
    begin
      Top := 100;
      Left := 230;
      Visible := true;
    end;
  ActiveControl := KIlepoGomb;
end;

// =============================================================================
                     procedure TForm1.Sorrendregen;
// =============================================================================

var _ujsr: word;

begin
  ServerDbase.close;
  serverDbase.DatabaseName := _serverFdbPath;
  ServerDbase.Connected := True;
  if ServerTranz.InTransaction then ServerTranz.Commit;
  ServerTranz.StartTransaction;

  with Servertabla do
    begin
      close;
      TableName := _currlettname;
      IndexFieldNames := 'SORREND';

      Open;
      Filtered := False;
      First;
    end;

  while not ServerTabla.Eof do
    begin
      _sr := ServerTabla.FieldByName('SORREND').asInteger;
      with ServerTabla do
        begin
          Edit;
          FieldByName('SORTEMP').asInteger := _sr;
          Post;
          next;
        end;
    end;

  ServerTranz.commit;
  ServerDbase.close;
  ServerTabla.close;

  ServerDbase.Close;
  ServerDbase.DatabaseName := _serverFdbPath;
  ServerDbase.Connected := true;
  if ServerTranz.InTransaction then ServerTranz.Commit;
  ServerTranz.StartTransaction;

  with ServerTabla do
    begin
      Open;
      IndexFieldNames := 'SORTEMP';
      First;
    end;

  _sr := 0;
  while not ServerTabla.Eof do
    begin
      ServerTabla.edit;
      _storno := ServerTabla.fieldByName('STORNO').asInteger;
      if _storno<2 then _sr := _sr + 2;
      if _storno>1 then _ujsr := 0 else _ujsr := _sr;
      ServerTabla.FieldByName('SORREND').asInteger := _ujsr;
      ServerTabla.Post;
      ServerTabla.Next;
    end;
  ServerTranz.Commit;
  ServerDbase.close;
  ServerTabla.close;
end;

// =============================================================================
             procedure TForm1.ServerParancs(_ukaz: string);
// =============================================================================

begin
  ServerDbase.close;
  ServerDbase.DatabaseName := _serverFdbPath;
  Serverdbase.Connected := true;
  if servertranz.InTransaction then serverTranz.Commit;
  Servertranz.StartTransaction;
  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ServerTranz.Commit;
  Serverdbase.close;
end;

// =============================================================================
                  function TForm1.SendRoundLetter: boolean;
// =============================================================================

begin
  result := False;
  if not Vaninternet then
    begin
      ShowMessage('NINCS INTERNET !');
      exit;
    end;

  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      ShowMessage('Nem találom a WININET.DLL könyvtárt !');
      Exit;
    end;

  _hFtp := Nil;
  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
            Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hFtp=Nil then
    begin
      InternetCloseHandle(_hnet);
      ShowMessage('Központi szerver nem érhető el !');
      exit;
    end;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\KORLEVEL'));
  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      ShowMessage('Nem tud belépni a KORLEVEL könyvtárba !');
      exit;
    end;

  result := FtpPutFile(_hFTP,pChar(_localPath),pChar(_remoteFile),
                                              FTP_TRANSFER_TYPE_BINARY,0);

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);

end;

// =============================================================================
                 function TForm1.Vaninternet: boolean;
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
           function TForm1.FillNull(_num:word): string;
// =============================================================================

begin
  result := inttostr(_num);
  while length(result)<4 do result := '0' + result;
end;

// =============================================================================
              procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
          procedure TForm1.MEGSEMSENDGOMBClick(Sender: TObject);
// =============================================================================

begin
  SendPanel.Visible := false;
  KijeloloGomb.Enabled := true;
  SzetkuldoGomb.Enabled := False;
  Menube;
  Activecontrol := Kijelologomb;
end;

// =============================================================================
                       procedure TForm1.Menube;
// =============================================================================

begin
  with MenuPanel do
    begin
      Top := 168;
      Left := 232;
      Visible := true;
    end;
end;

// =============================================================================
                   procedure TForm1.KORRACSDblClick(Sender: TObject);
// =============================================================================


begin
  _aktsorszam := Serverquery.FieldByName('SORSZAM').asInteger;
  _iktatostring := trim(ServerQuery.FieldByName('IKTATOSZAM').asstring);
  _tartalom := trim(Serverquery.FieldByName('TARTALOM').asString);
  _iFileNev := trim(ServerQuery.FieldByName('FILENEV').AsString);
  Olvasogomb.Enabled := true;
end;

// =============================================================================
             procedure TForm1.OlvasogombClick(Sender: TObject);
// =============================================================================

var _aktidos,_idostring: string;

begin
  with NagyFuggony do
    begin
      Top := 8;
      Left := 8;
      Visible := true;
    end;

  if _sofficepath='' then
    begin
      ShowMessage('NEM TUDOM HOL VAN A LIBREOFFICE !');
      Nagyfuggony.Visible := false;
      EXIT;
    end;

  _letterPath := 'c:\korlevel\'+ _ifileNev;
  if not FileExists(_letterPath) then
    begin
      _loaded := Levelletoltes(_ifileNev);
      if not _loaded then
        begin
          Showmessage('Nem sikerült letölteni a körlevelet a szerverről');
          Nagyfuggony.Visible := false;
          exit;
        end;
    end;

  // ------- Olvasás regisztrálása --------------------------------------

  _pcs := 'SELECT * FROM ' + _readsignName + _sorveg;
  _pcs := _pcs + 'WHERE (DOLGSORSZAM='+INTTOSTR(_idsorszam)+')';
  _pcs := _pcs + ' AND (LETTERNUM='+inttostr(_aktsorszam)+')';

  ServerDbase.close;
  serverDbase.DatabaseName := _serverFdbPath;
  ServerDbase.Connected := True;
  if ServerTranz.InTransaction then ServerTranz.Commit;
  ServerTranz.StartTransaction;

  with Serverquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      _aktidos := timetostr(Time);   // mamas = 2015.05.31
      if midstr(_aktidos,2,1)=':' then _aktidos := '0' + _aktidos;
      _idostring := midstr(_mamas,6,2)+midstr(_mamas,9,2)+leftstr(_aktidos,2)+midstr(_aktidos,4,2);
      _pcs := 'INSERT INTO ' + _readsignName + ' (DOLGSORSZAM,LETTERNUM,MIKOR)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_idsorszam)+ ',';
      _pcs := _pcs + inttostr(_aktsorszam) + ',';
      _pcs := _pcs + chr(39) + _idostring + chr(39) + ')';

      with Serverquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          ExecSql;
        end;
    end;

  ServerTranz.Commit;
  Serverdbase.close;

  if _aktsorszam>_lastreadItem then
    begin
      AssignFile(_iras,_lastItemPath);
      rewrite(_iras);
      write(_iras,inttostr(_aktsorszam));
      Closefile(_iras);
      _lastReadItem := _aktsorszam;
    end;

  // ---------------------------------------------------------------------

  SofficeLeallitas;
  _pcs := _sOfficePath + ' ' + _letterPath;
  _pacs := pchar(_pcs);
  WinexecandWait32(_pacs,sw_normal);
  Nagyfuggony.Visible := false;
end;




// =============================================================================
            procedure TForm1.LISTAZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Menupanel.Visible := true;
  Kijelologomb.Enabled := true;
  SzetkuldoGomb.Enabled := False;
  OlvasoGomb.Enabled := False;

  Serverdbase.close;
  Serverdbase.DatabaseName := _serverFdbPath;
  serverDbase.Connected := true;

  _pcs := 'SELECT * FROM ' + _currlettname + _SORVEG;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND';

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
    end;

  with ListaPanel do
    begin
      Top :=8;
      Left := 8;
      Visible := true;
    end;
  Activecontrol := Korracs;
end;


// =============================================================================
              procedure TForm1.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  ListaPanel.Visible := False;
  Menube;
  Activecontrol := Kijelologomb;

end;

procedure TForm1.P1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);

var _aktpanel: TPanel;
    _aktnum: byte;
    _aktnaps,_aktnums: string;

begin
  _aktpanel := TPanel(Sender);
  if _aktPanel.color= clLime then
    begin
      _aktpanel.Cursor := crHandPoint;
      _aktnums := _aktpanel.caption;
      _aktnum := strtoint(_aktnums);
      _aktnaps := _typ[_aktnum];
      _aktpanel.hint := 'Letöltve: '+ _aktnaps+'-án';
      _aktpanel.showHint := true;
    end;

end;

// =============================================================================
               procedure TForm1.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  Application.Terminate;
end;

// =============================================================================
                   function TForm1.GetsofficePath: string;
// =============================================================================

var _sofp: string;
     _y: byte;

begin
  result := '';
  if fileExists(_spath) then
    begin
      Assignfile(_olvas,_spath);
      reset(_olvas);
      read(_olvas,result);
      Closefile(_olvas);
      Exit;
    end;

  _pfdarab := Pfkereso;
  if _pfdarab=0 then exit;
  _libdarab := 0;
  _y := 0;
  while _y<_pfDarab do
    begin
      _aktdir := 'c:\' + _pfdir[_y];
      _libDarab := Libkereso;
      if _libDarab>0 then break;
      inc(_y);
    end;
  if _libdarab=0 then exit;
  _sofp := _libdir + '\program\soffice.exe';
  if not fileExists(_sofp) then exit;
  result := _sofp;

  assignFile(_iras,_spath);
  Rewrite(_iras);
  write(_iras,_sofp);
  Closefile(_iras);

end;

// =============================================================================
                function TForm1.Libkereso: integer;
// =============================================================================

var _minta: string;

begin
  result := 0;
  _minta :=  _aktdir+ '\Libre*.*';
  if findFirst(_minta, faDirectory,_srec)<>0 then exit;
  _DIRNev := _srec.name;
  _libdir := _AKTDIR + '\' + _dirnev;
  FindClose(_srec);
  result := 1;
end;

// =============================================================================
                    function TForm1.PfKereso: integer;
// =============================================================================

var _minta: string;
    _c: byte;
begin
  _minta := 'c:\PROGRAM FI*';
  _c := 0;
  if FindFirst(_MINTA, faDirectory, _srec) = 0 then
    begin
      repeat
        _pfdir[_c] := _srec.name;
        inc(_c);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
  result := _c;
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

// =============================================================================
          function Tform1.LevelLetoltes(_fn: string): boolean;
// =============================================================================

VAR _SAJDIR: string;

begin
  _sajdir := 'c:\KORLEVEL';
  if not DirectoryExists(_sajdir) then Createdir(_sajdir);

  _localPath := 'c:\korlevel\' + _fn;
  _remoteFile := _fn;

  result := False;
  if not Vaninternet then
    begin
      ShowMessage('NINCS INTERNET !');
      exit;
    end;

  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      ShowMessage('Nem találom a WININET.DLL könyvtárt !');
      Exit;
    end;

  _hFtp := Nil;
  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
            Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hFtp=Nil then
    begin
      InternetCloseHandle(_hnet);
      ShowMessage('Központi szerver nem érhető el !');
      exit;
    end;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\KORLEVEL'));
  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      ShowMessage('Nem tud belépni a KORLEVEL könyvtárba !');
      exit;
    end;

  _sikeres := FtpGetFile(_hFTP,pChar(_remotefile),pChar(_localpath),False,0,
                                              FTP_TRANSFER_TYPE_BINARY,0);
  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      exit;
    end;
  result := True;
end;


// =============================================================================
               procedure TForm1.SofficeLeallitas;
// =============================================================================

var
  _SelectedProcess,_fileName,_filePath: String;

begin
  _SelectedProcess := 'SOFFICE';
  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
       _filepath := Proc.szExeFile;
      _fileName := ExtractFileName(_filepath);
      _filename := uppercase(leftstr(_filename,7));
      if _fileName = _SelectedProcess then
          TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
             procedure TForm1.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Jelszoedit.clear;
  with JelszoPanel do
    begin
      top := 320;
      left := 300;
      Visible := True;
      Repaint;
    end;
  Activecontrol := Jelszoedit;
end;

// =============================================================================
     procedure TForm1.JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _jelszo := trim(Jelszoedit.text);
  if _jelszo<>'ZSU' then
    begin
      Jelszopanel.visible := False;
      exit;
    end;
  Jelszopanel.visible := false;
  SuperForm.showmodal;
end;

// =============================================================================
                  function TForm1.Getiktatoszam: integer;
// =============================================================================


begin
  Serverdbase.close;
  Serverdbase.DatabaseName := _serverFdbPath;
  serverdbase.Connected := true;
  _pcs := 'SELECT * FROM IKTATOSZAM';

  with serverQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := FieldByName('IKTATOSZAM').asInteger;
      close;
    end;
  serverdbase.close;
  inc(result);
end;

// =============================================================================
                      function TForm1.getTiltott: byte;
// =============================================================================

var _cc: byte;

begin
  Result := 0;

  Serverdbase.close;
  Serverdbase.DatabaseName := _serverFdbPath;
  serverdbase.Connected := true;
  _pcs := 'SELECT * FROM TILTOTT';

  with serverQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      Result := recno;
    end;

  if Result=0 then
    begin
       Serverquery.close;
       ServerDbase.close;
       exit;
     end;
   _cc := 0;
   while not Serverquery.eof do
     begin
       _szig[_cc] := trim(ServerQuery.FieldByName('SZIGNO').asString);
       inc(_cc);
       ServerQuery.next;
     end;
   ServerQuery.close;
   ServerDbase.close;
end;


// =============================================================================
           procedure TForm1.EZVAGYOKGOMBClick(Sender: TObject);
// =============================================================================

var _iras: textfile;
    _mondat: string;

begin
  _IDSORSZAM := ProsQuery.FieldByNAme('SORSZAM').asInteger;
  _prosnev   := trim(Prosquery.fieldByName('PENZTAROSNEV').asString);

  _mondat := inttostr(_idsorszam)+','+_prosnev;

  ProsQuery.close;
  Prosdbase.close;
  IdPanel.Visible := False;

  assignfile(_iras,_idPath);
  rewrite(_iras);
  write(_iras,_mondat);
  CLoseFile(_iras);

  AssignFile(_iras,_lastItemPath);
  rewrite(_iras);
  write(_iras,inttostr(_iktatoszam));
  CloseFile(_iras);


  Menube;
  Activecontrol := KijeloloGomb;
end;

// =============================================================================
                     procedure TForm1.readidkod;
// =============================================================================

var _olvas: textfile;
    _idstring,_ids: string;
    _xx: byte;

begin
  _idsorszam := 0;

  AssignFile(_olvas,_idPath);
  reset(_olvas);
  read(_olvas,_idstring);
  Closefile(_olvas);

  _xx := pos(',',_idstring);

  if _xx=0 then
    begin
      deletefile(_idpath);
      Kilepo.Enabled := True;
      exit;
    end;

  _ids := leftstr(_idstring,_xx-1);
  _prosnev := midstr(_idstring,_xx+1,length(_idstring)-_xx);

  val(_ids,_idSorszam,_code);
  if _code<>0 then _idsorszam := 0;
  if _idsorszam=0 then
    begin
      DeleteFile(_idPath);
      Kilepo.Enabled :=True;
      exit;
    end;

  DolgNevPanel.Caption := _IDS + '. '+ _prosnev;
  dolgnevPanel.Visible := True;
  DolgnevPanel.Repaint;
end;

// =============================================================================
                    procedure TForm1.readLastItem;
// =============================================================================


var _lasts: string;

begin
  Assignfile(_olvas,_lastItempath);
  reset(_olvas);
  read(_olvas,_lasts);
  Closefile(_olvas);
  val(_lasts,_lastReadItem,_code);
  if _code<>0 then _lastReadItem := 0;
end;

// =============================================================================
            procedure TForm1.IDMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ProsQuery.close;
  Prosdbase.close;
  IdPanel.Visible := False;
  Kilepo.Enabled := True;
end;

// =============================================================================
                           procedure TForm1.OnlyControl;
// =============================================================================

begin
  _read      := _lastreadItem;
  _available := _iktatoszam;
  if _available>_read then ShowMessage('ÚJ KÖRLEVÉL OLVASHATÓ');
  Kilepo.enabled := true;
end;

// =============================================================================
                         procedure Tform1.WriteRegistry;
// =============================================================================

var _reg: Tregistry;
    _key: string;

begin
  _reg := TRegistry.Create(KEY_WRITE);
  _key := '\Software\Microsoft\Windows\CurrentVersion\Run';

  _reg.RootKey := HKEY_LOCAL_MACHINE;

  TRY
    if _reg.OpenKey(_key,False) then
      begin
        _reg.writeString('KORLEVEL',_korlExePath+' 1');
        _reg.CloseKey;
      end;
  FINALLY
    _reg.Free;
  END;
end;


// =============================================================================
                    function TForm1.Readregistry: boolean;
// =============================================================================

var _reg: TRegistry;
    _key,_klPath: string;

begin
  result := True;
  _key := '\Software\Microsoft\Windows\CurrentVersion\Run';

  _reg := TRegistry.Create(KEY_READ);
  _reg.Rootkey := HKEY_LOCAL_MACHINE;
  _key := '\Software\Microsoft\Windows\CurrentVersion\Run';

  _reg.Access := KEY_READ;
  _reg.OpenKey(_key,False);
  _klPath := _reg.ReadString('KORLEVEL');

  _reg.CloseKey;
  _reg.free;

  if _klPath='' then result := False;

end;


// =============================================================================
                          procedure TForm1.setVezetoTomb;
// =============================================================================

begin
  _vezetoDarab := 13;

  _vNev[1] := 'Fabulya Zsuzsanna';
  _vNev[2] := 'Kósa-Gallusz Ildikó';
  _vNev[3] := 'Bátori Mónika';
  _vNev[4] := 'Vígh Emília';
  _vNev[5] := 'Hrabina Krisztián';
  _vNev[6] := 'Nagy Annamária';
  _vNev[7] := 'Kósa Zoltán';
  _vNev[8] := 'Schnellné Balogh Edit';
  _vNev[9] := 'Reszegi-Tóth Emese';
  _vNev[10]:= 'Dr Tímár-Bíró Zita';
  _vNev[11]:= 'Durucz Tamás';
  _vNev[12]:= 'Kardos Ildikó';
  _vNev[13]:= 'Madár Zoltán';

  _vKod[1] := 10;
  _vKod[2] := 270;
  _vKod[3] := 357;
  _vKod[4] := 221;
  _vKod[5] := 359;
  _vKod[6] := 337;
  _vKod[7] := 360;
  _vKod[8] := 356;
  _vKod[9] := 358;
  _vKod[10]:= 355;
  _vKod[11]:= 361;
  _vKod[12]:= 353;
  _vKod[13]:= 354;


  _eMail[1] := 'fabulyazsuzsa.eec@gmail.com';
  _eMail[2] := 'gallusz.ildiko.ebc@gmail.com';
  _eMail[3] := 'bator.moni.ebc@gmail.com';
  _eMail[4] := 'vigh.emilia.ebv@gmail.com';
  _eMail[5] := 'hrabina.krisztian.eec@gmail.com';
  _eMail[6] := 'nagyannamari.ebc@gmail.com';
  _eMail[7] := 'kosa.zoltan.ebc@gmail.com';
  _eMail[8] := 'schnell.edit.ebc@gmail.com';
  _eMail[9] := 'reszegi.emese.eec@gmail.com';
  _eMail[10] := 'timarbiro.zita.epc@gmail.com';
  _eMail[11] := 'durucz.tamas.eec@gmail.com';
  _eMail[12] := 'kardos.ildiko.ebc@gmail.com';
  _eMail[13] := 'madarzoltan.ebc@gmail.com';

end;


// =============================================================================
            function TForm1.EmailKuldes(_aktemail: string): Cardinal;
// =============================================================================

var mail: TStringList;

begin

  mail := TstringList.Create;
  try
    mail.values['to'] := _aktemail;
    mail.values['subject'] := 'Korlevel';
    mail.values['body'] := 'Új körlevél elérhető';
    result := sendEMail(Application.Handle, mail);

  finally
    mail.Free;
  end;

end;

// =============================================================================
          function Tform1.SendEMail(Handle: THandle; Mail: TStrings): Cardinal;
// =============================================================================

  type
    TAttachAccessArray = array [0..0] of TMapiFileDesc;
    PAttachAccessArray = ^TAttachAccessArray;
  var
    MapiMessage: TMapiMessage;
    Receip: TMapiRecipDesc;
    Attachments: PAttachAccessArray;
    AttachCount: Integer;
    i1: integer;
    FileName: string;
    dwRet: Cardinal;
    MAPI_Session: Cardinal;
    WndList: Pointer;

begin
   result := 0;
   dwRet := MapiLogon(Handle,
                        PChar(''),
                        PChar(''),
                        MAPI_LOGON_UI or MAPI_NEW_SESSION,
                        0, @MAPI_Session);

   if (dwRet <> SUCCESS_SUCCESS) then
     begin
       MessageBox(Handle,
       PChar('Error while trying to send email'),
       PChar('Error'),
       MB_ICONERROR or MB_OK);
     end
     else
     begin
       FillChar(MapiMessage, SizeOf(MapiMessage), #0);
       Attachments := nil;
       FillChar(Receip, SizeOf(Receip), #0);

       if Mail.Values['to'] <> '' then
         begin
           Receip.ulReserved := 0;
           Receip.ulRecipClass := MAPI_TO;
           Receip.lpszName := StrNew(PChar(Mail.Values['to']));
           Receip.lpszAddress := StrNew(PChar('SMTP:' + Mail.Values['to']));
           Receip.ulEIDSize := 0;
           MapiMessage.nRecipCount := 1;
           MapiMessage.lpRecips := @Receip;
         end;

        AttachCount := 0;
        for i1 := 0 to MaxInt do
          begin
            if Mail.Values['attachment' + IntToStr(i1)] = '' then break;
            Inc(AttachCount);
          end;

        if AttachCount > 0 then
          begin
            GetMem(Attachments, SizeOf(TMapiFileDesc) * AttachCount);
            for i1 := 0 to AttachCount - 1 do
              begin
                FileName := Mail.Values['attachment' + IntToStr(i1)];
                Attachments[i1].ulReserved := 0;
                Attachments[i1].flFlags := 0;
                Attachments[i1].nPosition := ULONG($FFFFFFFF);
                Attachments[i1].lpszPathName := StrNew(PChar(FileName));
                Attachments[i1].lpszFileName :=
                               StrNew(PChar(ExtractFileName(FileName)));
                Attachments[i1].lpFileType := nil;
              end;
            MapiMessage.nFileCount := AttachCount;
            MapiMessage.lpFiles := @Attachments^;
          end;

       if Mail.Values['subject'] <> '' then
            MapiMessage.lpszSubject := StrNew(PChar(Mail.Values['subject']));

       if Mail.Values['body'] <> '' then
            MapiMessage.lpszNoteText := StrNew(PChar(Mail.Values['body']));

       WndList := DisableTaskWindows(0);
       try
         Result := MapiSendMail(MAPI_Session, Handle,
                                      MapiMessage, MAPI_DIALOG, 0);
       finally
         EnableTaskWindows( WndList );
       end;

       for i1 := 0 to AttachCount - 1 do
         begin
           StrDispose(Attachments[i1].lpszPathName);
           StrDispose(Attachments[i1].lpszFileName);
         end;

       if Assigned(MapiMessage.lpszSubject) then
                                     StrDispose(MapiMessage.lpszSubject);
       if Assigned(MapiMessage.lpszNoteText) then
                                     StrDispose(MapiMessage.lpszNoteText);
       if Assigned(Receip.lpszAddress) then
                                     StrDispose(Receip.lpszAddress);
       if Assigned(Receip.lpszName) then
                                      StrDispose(Receip.lpszName);
       MapiLogOff(MAPI_Session, Handle, 0, 0);
     end;
end;


// =============================================================================
                           procedure TForm1.ertesites;
// =============================================================================


var _y: byte;
    _aktvkod: word;
    _aktemailcim: string;

begin
  _y := 1;
  while _y<=_vezetodarab do
    begin
      _aktVkod := _vKod[_y];
      if _aktvkod<>_idsorszam then
        begin
          _aktemailcim := _email[_y];
          Emailkuldes(_aktemailcim);
          Sleep(1200);
        end;
      inc(_y);
    end;
end;


procedure TForm1.DolgozokTombbe;

begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  prosdbase.close;
  Prosdbase.databasename := _serverProsPath;
  Prosdbase.connected := True;

  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not Prosquery.Eof do
    begin
      _pnev[_cc] := trim(Prosquery.fieldByname('PENZTAROSNEV').asString);
      _psor[_cc] := ProsQuery.FieldByName('SORSZAM').asInteger;
      inc(_cc);
      ProsQuery.next;
    end;
  _DolgozoDarab := _cc;
  ProsQuery.close;
  Prosdbase.close;
end;


procedure TForm1.TartalomTombbe;

begin
  _pcs := 'SELECT * FROM ' + _CURRLETTNAME + _sorveg;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND';

  ServerDbase.close;
  serverDbase.DatabaseName := _serverFdbPath;
  ServerDbase.Connected := True;

  with ServerQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not ServerQuery.eof do
    begin
      _kltart[_cc] := trim(serverQuery.fieldbyname('TARTALOM').asString);
      _klsors[_cc] := ServerQuery.FieldByName('SORSZAM').asInteger;
      inc(_cc);
      ServerQuery.next;
    end;
  _tartalomdarab := _cc;
  ServerQuery.close;
  ServerDbase.close;

end;


procedure TForm1.Removetiltott;

var _volttiltas: boolean;
    _y: word;
    _aktTiltott,_aktIkt: string;
    _aktlen: byte;

begin
  ServerDbase.close;
  serverDbase.DatabaseName := _serverFdbPath;
  ServerDbase.Connected := True;
  if ServerTranz.InTransaction then ServerTranz.Commit;
  ServerTranz.StartTransaction;

  _voltTiltas := False;
  _y := 0;
  while _y<_tiltottdb do
    begin
      _akttiltott := _szig[_y];
      _aktlen := length(_akttiltott);

      with Servertabla do
        begin
          close;
          TableName := _currlettname;
          Open;

          Filtered := False;
          First;
        end;

      while not serverTabla.eof do
        begin
          _aktIkt := ServerTabla.FieldByName('IKTATOSZAM').asstring;
          if leftStr(_aktikt,_aktlen)=_akttiltott then
            begin
              Servertabla.edit;
              servertabla.fieldbyname('STORNO').asInteger := 2;
              servertabla.post;
              _voltTiltas := True;
            end;

          serverTabla.next;
        end;
      servertabla.close;
      inc(_y);
    end;
  serverTranz.commit;
  serverdbase.close;

  if _voltTiltas then SorrendRegen;

end;


end.
