unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,Mapi,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,Registry,
  IBQuery, strutils, wininet, dateutils,TlHelp32, jpeg, IBTable, Grids, DBGrids;

type
  TForm1 = class(TForm)

    OpenDialog       : TOpenDialog;
    OpenDialog1      : TOpenDialog;

    ArchivePanel     : TPanel;
    CopyInfoPanel    : TPanel;
    FileTakaro       : TPanel;
    ImagePanel       : TPanel;
    InfoPanel        : TPanel;
    JelszoPanel      : TPanel;
    KivalasztottPanel: TPanel;
    KorlCimPanel     : TPanel;
    LastYearPanel    : TPanel;
    ListaCimPanel    : TPanel;
    ListaPanel       : TPanel;
    Menupanel        : TPanel;
    NagyFuggony      : TPanel;
    RacsPanel        : TPanel;
    ReadPanel        : TPanel;
    SendPanel        : TPanel;
    StartFuggony     : TPanel;
    TartalomPanel    : TPanel;

    DolgNev          : TLabel;
    Label1           : TLabel;
    Label2           : TLabel;
    Label3           : TLabel;
    Label4           : TLabel;
    Label5           : TLabel;
    Label6           : TLabel;
    Label7           : TLabel;
    Label8           : TLabel;
    Label9           : TLabel;

    ArchangeGomb     : TBitBtn;
    ArExpresszGomb   : TBitBtn;
    ArVIPGomb        : TBitBtn;
    ARExitGomb       : TBitBtn;
    ArchiveGomb      : TBitBtn;
    ListaBackGomb    : TBitBtn;
    KijeloloGomb     : TBitBtn;
    KilepoGomb       : TBitBtn;
    LastYearGomb     : TBitBtn;
    ListazoGomb      : TBitBtn;
    LyChangeGOMB     : TBitBtn;
    LyExpresszGomb   : TBitBtn;
    LyVIPGomb        : TBitBtn;
    LyExitGomb       : TBitBtn;
    MegsemSendGomb   : TBitBtn;
    Olvasogomb       : TBitBtn;
    ReadGomb         : TBitBtn;
    StartSendGomb    : TBitBtn;
    SupervisorGomb   : TBitBtn;
    SzetkuldoGomb    : TBitBtn;
    VIPGomb          : TBitBtn;
    VisszaGomb       : TBitBtn;
    ZalogGomb        : TBitBtn;

    Shape1           : TShape;
    Shape2           : TShape;
    Shape3           : TShape;
    Shape4           : TShape;
    Shape5           : TShape;
    Shape15          : TShape;

    ServerTabla      : TIBTable;

    ArcQuery         : TIBQuery;
    ProsQuery        : TIBQuery;
    ServerQuery      : TIBQuery;

    ArcDbase         : TIBDatabase;
    ProsDbase        : TIBDatabase;
    ServerDbase      : TIBDatabase;
    ProsTranz        : TIBTransaction;
    ServerTranz      : TIBTransaction;

    KorRacs          : TDBGrid;

    Image1           : TImage;
    Image2           : TImage;

    ArchiveSource    : TDataSource;
    KorSource        : TDataSource;
    ProsSource       : TDataSource;

    Kilepo           : TTimer;

    JelszoEdit       : TEdit;
    SelectEdit       : TEdit;

    GroupBox1        : TGroupBox;
    GroupBox2        : TGroupBox;

    NoSendMailGomb   : TRadioButton;
    RadioAll         : TRadioButton;
    RadioVIP         : TRadioButton;
    RadioZalog       : TRadioButton;
    SendMailGomb     : TRadioButton;

    procedure ArchiveGombClick(Sender: TObject);
    procedure ArChangeGombClick(Sender: TObject);
    procedure ArExpresszGombClick(Sender: TObject);
    procedure ArVIPGombClick(Sender: TObject);
    procedure ArExitGombClick(Sender: TObject);
    procedure LastYearGombClick(Sender: TObject);
    procedure DirMake;
    procedure DolgozokTombbe;
    procedure FormActivate(Sender: TObject);
    procedure JelszoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KijeloloGombClick(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure ListaBackGombClick(Sender: TObject);
    procedure ListazoGombClick(Sender: TObject);
    procedure LyEXITGombClick(Sender: TObject);
    procedure LyVIPGombClick(Sender: TObject);
    procedure LYExpresszGombClick(Sender: TObject);
    procedure LYChangeGombClick(Sender: TObject);
    procedure MenuBe;
    procedure Makexml;
    procedure OlvasasRegisztracio;
    procedure OlvasasRutin;
    procedure OlvasogombClick(Sender: TObject);
    procedure P1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure Paracontrol;
    procedure ReadGombClick(Sender: TObject);
    procedure RemoveTiltott;
    procedure ServerParancs(_ukaz: string);
    procedure SetRemotefile;
    procedure SetValasztottFile;
    procedure SetvezetoTomb;
    procedure SofficeLeallitas;
    procedure SorrendRegen;
    procedure StartSendGombClick(Sender: TObject);
    procedure SupervisorGombClick(Sender: TObject);
    procedure SzetKuldoGombClick(Sender: TObject);
    procedure TartalomTombbe;
    procedure VipgombClick(Sender: TObject);
    procedure VipEmailBeolvaso;
    procedure VisszaGombClick(Sender: TObject);
    procedure ZalogGombClick(Sender: TObject);
    procedure ZalogKuldes;

    function Angolra(_huName: string): string;
    function HutoGb(_kod: byte): byte;
    function FillNull(_num:word): string;
    function Getiktatoszam(_dest: string): integer;
    function GetSofficePath: string;
    function GetTiltott: byte;
    function GetZalogiktatoszam: integer;
    function LevelLetoltes(_fn: string): boolean;
    function Nulele(_b: byte): string;
    function SendEMail(Handle: THandle; Mail: TStrings): Cardinal;
    function SendMailStart: boolean;
    function SendRoundLetter: boolean;
    function SendZalogLetter: boolean;
    function Vaninternet: boolean;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _soffMinta: string = 'c:\Program Files (x86)\Libreoffice 5\program\soffice.exe';
  _soffmint2: string = 'c:\Program Files\Libreoffice 5\program\soffice.exe';
  _soffmint3: string = 'c:\Program Files\Libreoffice\program\soffice.exe';

  _sign        : string;      // pl. 'DA'
  _dolgnev     : string;      // pl. 'DÉKÁNY ANTAL'
  _dolgsorszam : word;        // pl. 1866
  _soffPath    : string;      // pl 'c:\program files\libreoffice5\program\soffice.exe
  _idstring    : string;      // pl '1866,DÉKÁNY ANTAL'

  _mailcim: array[1..50] of string;


  _hNet,_hFTP    : HINTERNET;

  _srec          : TSearchRec;

  _proc          : PROCESSENTRY32;
  _handle        : HWND;
  _Looper        : BOOL;

  _host          : string  = '185.43.207.99';
  _ftpPort       : integer = 21100;
  _userId        : string  = 'ebc-10%';
  _ftpPassword   : string  = 'klc+45%';

  _midchiefPath  : string = '185.43.207.99:C:\RECEPTOR\DATABASE\MIDCHIEF.FDB';

  _sorveg        : string  = chr(13)+chr(10);

  _iras,_olvas   : textfile;
  _pacs          : Pchar;

  _aktemailcim   : string;
  _currLettName  : string;
  _destiny       : string;
  _dirnev        : string;
  _idPath        : string;
  _iFileNev      : string;
  _iktatostring  : string;
  _jelszo        : string;
  _tipus         : string;
  _kordbasePath  : string;
  _kordir        : string;
  _korparamdir   : string;
  _lastItempath  : string;
  _lastNumPath   : string;
  _lettername    : string;
  _lettext       : string;
  _localPath     : string;
  _mailFile      : string;
  _mailinfoPath  : string;
  
  _mamas             : string;
  _mess              : string;
  _pcs               : string;
  _remotedir         : string;
  _remoteFile        : string;
  _selectedfile      : string;
  _signPath          : string;
  _serverKordbasePath: string;
  _serverProspath    : string;
  _signal            : string;
  _sPath             : string;
  _tartalom          : string;
  _tempdir           : string;
  _arctablanev       : string;
  _vipdir            : string;
  _zalogdir          : string;

  _pnev        : array[1..500] of string;
  _psor        : array[1..500] of word;

  _kltart      : array[0..500] of string;
  _klsors      : array[0..500] of word;

  _vipltart    : array[0..500] of string;
  _viplsors    : array[0..500] of word;

  _destNum         : byte;
  _extlen          : byte;
  _lettlen         : byte;
  _pos             : byte;
  _tiltottDb       : byte;
  _cimdb           : byte;

  _aktev           : word;
  _aktho           : word;
  _aktnap          : word; 
  _dolgozodarab    : word;
  _lastnum         : word;
  _lastReadItem    : word;
  _lastVIP         : word;
  _lastzalog       : word;
  _maiev           : word;
  _maiho           : word;
  _mainap          : word;
  _tartalomdarab   : word;
  _vezetodarab     : word;
  _viptartalomdarab: word;

  _code            : integer;
  _iktatoszam      : integer;
  _recno           : integer;
  _tag             : integer;

  _remotenev       : string;
  _xmlfile         : string;
  _xmlPath         : string;

  _szig: array[1..10] of string;
  _vkod: array[1..20] of word;
  _vnev: array[1..20] of string;

  _xp: array[1..13] of TPanel;
  _ed: array[1..13] of TEdit;
  _np: array[1..13] of TPanel;

  _loaded      : boolean;
  _sendMail    : boolean;
  _sikeres     : boolean;
  _vanAutoexec : boolean;

  _aktnpanel   : TPanel;
  _aktxpanel   : TPanel;

  _aktedit     : TEdit;

implementation

uses Unit2, Unit5, Unit6, Unit7;

{$R *.dfm}


// =============================================================================
           procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var _t,_fl,_ft: integer;

begin
  Top    := -360;
  Left   := 210;
  _t     := -200;
  Image2.repaint;

  ArchivePanel.Visible  := False;
  LastYearPanel.Visible := False;

  with startFuggony do
    begin
      top := 0;
      left := 0;
    end;

  Startfuggony.Repaint;
  while _t<=100 do
    begin
      _t := _t + 20;
      Top := _t;
      sleep(20);
    end;

  Top    := 120;
  Left   := 210;

  Image2.repaint;
  Startfuggony.Repaint;
  Sleep(500);

  _fl := 0;
  _ft := 0;
  while _ft>-400 do
    begin
      _ft := _ft-20;
      _fl := _fl-30;
      Startfuggony.Top := _ft;
      startFuggony.Left := _fl;
      sleep(20);
    end;
  Startfuggony.Visible := false;
  Korlcimpanel.Repaint;

  // ------------ Panelek eltüntetése ---------------------------------------

  MenuPanel.Visible         := False;
  CopyInfoPanel.visible     := False;

  ReadPanel.Visible         := False;
  Infopanel.Visible         := False;
  DolgNev.visible           := False;
  JelszoPanel.Visible       := False;
  Sendpanel.Visible         := False;
  KivalasztottPanel.Visible := False;
  ListaPanel.Visible        := False;
  Nagyfuggony.Visible       := False;
  ImagePanel.Visible        := False;

  Selectedit.text           := '';
  _localpath                := '';

  _maiev := yearof(date);
  _maiho := monthof(date);
  _mainap:= dayof(date);

  _mamas := inttostr(_maiev)+'.'+nulele(_maiho)+'.'+nulele(_mainap);

  // ---------------------------------------------------------------------------

  _tempdir := 'C:\TEMP';
  if not DirectoryExists(_tempdir) then Createdir(_tempdir);

  _kordir := 'C:\KORLEVEL';
  if not DirectoryExists(_kordir) then Createdir(_kordir);

  _korparamdir := _kordir + '\params';
  if not DirectoryExists(_korparamdir) then Createdir(_korparamdir);

  _vipdir := _kordir + '\VIP';
  if not DirectoryExists(_vipdir) then Createdir(_vipdir);

  _zalogdir := _kordir + '\ZALOG';
  if not DirectoryExists(_zalogdir) then Createdir(_zalogdir);

  _kordbasePath := 'c:\receptor\database\korlevel.fdb';
  _remotedir := 'KORLEVEL';

  _serverkordbasepath := _host + ':' + _kordbasePath;
  _serverProsPath := _host + ':C:\RECEPTOR\DATABASE\PTAROSOK.FDB';

  Dirmake; // több hiányzó dir makes  pl \LASTYEAR\ZALOG .. STB....

  // ------------- LASTNUM,LASTZALOG ÉS LASTVIP BEOLVASÁSA ---------------------

  ServerDbase.close;
  Serverdbase.DatabaseName := _serverkordbasePath;
  Serverdbase.Connected := True;

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM ADATOK');
      Open;

      _lastnum   := FieldByName('UTSORSZAM').asInteger;
      _lastVip   := Fieldbyname('UTVIPSORSZAM').asInteger;
      _lastzalog := FieldByName('UTZALOGSORSZAM').asInteger;

      Close;
    end;

  ServerDbase.close;
  Paracontrol;
  FileTakaro.Visible := True;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$  KIJELÖLÉS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// =============================================================================
            procedure TForm1.KIJELOLOGOMBClick(Sender: TObject);
// =============================================================================

//  ------------------ Egy körlevél kiválasztása -------------------------------

begin

  // Ha nem választott file-t -> akkor vége
  if not Opendialog1.Execute then exit;

  // Több kijelölés nincs. A körlevél path-ja a saját gépen = _localPath

//  KijeloloGomb.Enabled := False;

  _localPath    := Opendialog1.Filename;
  _selectedFile := extractfilename(_localpath); // ezt a file-t vákasztotta

  // A tábla alján kijelzi, hogy mit választott:
  Selectedit.text    := _localpath;
  Filetakaro.Visible := False;

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
  _lettext    := extractfileExt(_lettername);
  _lettlen    := length(_lettername);
  _extlen     := length(_lettext);
  _tartalom   := leftstr(_lettername,_lettlen-_extlen);

  if length(_tartalom)>80 then _tartalom := leftstr(_tartalom,76) + '...';
end;


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$ EGY LEVÉL SZÉTKÜLDÉSE $$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
            procedure TForm1.SZETKULDOGOMBClick(Sender: TObject);
// =============================================================================

// ------  A kiválasztott körlevél felmásolása a szerverre és iktatása ------

begin

  // Ha nincs meg a körlevél path-ja a gépen, akkor semmi sincs

  if _localPath='' then exit;

  // A menü eltünik

  Menupanel.Visible := False;

  TartalomPanel.Caption := uppercase(_tartalom);
  TartalomPanel.Repaint;
  KivalasztottPanel.Visible := False;

  // Elöjön a send-panel és a start send gomb lesz érvényes:

  Radioall.Checked := true;
  NosendMailgomb.checked := true;
  with sendpanel do
    begin
      Left := 16;
      Top  := 120;
      Visible := true;
      Repaint;
    end;
  Activecontrol := StartSendGomb;
end;

// =============================================================================
           procedure TForm1.STARTSENDGOMBClick(Sender: TObject);
// =============================================================================


var _sr: word;
    _last: string;
    _emoke: boolean;

// Elinditja a választott körlevél felmásolását a szerverre:

begin
  SendPanel.Visible := False;

  with CopyInfoPanel do
    begin
      Top := 240;
      Left := 190;
      Visible := true;
      Repaint;
    end;

  if RadioAll.Checked then
    begin
      _destiny := 'EBC';
      _currlettName := 'KORLEVEL';
    end;

  if RadioZalog.Checked then
    begin
      _destiny := 'ZALOG';
      _currlettName := 'ZALOGLEVEL';
    end;

  if RadioVip.Checked then
    begin
      _destiny := 'VIP';
      _currlettName := 'VIPLEVEL';
    end;

  _sendmail := False;
  if SendMailGomb.Checked then _sendMail := True;

  _iktatoszam := GetIktatoszam(_destiny);
  SetremoteFile;

  if not SendRoundletter then
    begin
      CopyInfoPanel.Visible := false;
      ShowMessage('SIKERTELEN SZÉTKÜLDES');
      Height := 410;
      exit;
    end;


  if _destiny='EBC' then
    begin
      _last := 'UTSORSZAM';
      _currlettName := 'KORLEVEL';
    end;

  if _destiny='VIP' then
    begin
      _last := 'UTVIPSORSZAM';
      _currlettName := 'VIPLEVEL';
    end;

  if _destiny='ZALOG' then
    begin
      _last := 'UTZALOGSORSZAM';
      _CurrlettName := 'ZALOGLEVEL';
    end;

  _sr := trunc(2*_ikTatoszam);

  _pcs := 'INSERT INTO ' + _currLettName + ' (IKTATOSZAM,DATUM,TARTALOM,';
  _pcs := _pcs + 'SORSZAM,SORREND,STORNO,FILENEV)'+ _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + _iktatostring + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
  _pcs := _pcs + inttostr(_iktatoszam) + ',';
  _pcs := _pcs + inttostr(_sr) + ',1,';
  _pcs := _pcs + chr(39) + _remotefile + chr(39)+')';

  ServerParancs(_pcs);

  _pcs := 'UPDATE ADATOK SET '+_last+'='+inttostr(_iktatoszam);
  ServerParancs(_pcs);

   // -----------------------------------------------------------

  SorrendRegen;

  with CopyInfopanel do
    begin
      top := 300;
      left := 135;
      Visible := true;
      repaint;
    end;

  _emoke :=False;

  if _sendMail then
    begin
      VipEmailBeolvaso;
      MakeXml;
      _emoke := SendMailStart;
    end;

  CopyInfoPanel.Visible := False;  
  infoPanel.Visible := false;
  if _emoke then Showmessage('Értesitéseket sikeresen kiküldtem');
  Menube;
end;

// =============================================================================
                  function TForm1.SendRoundLetter: boolean;
// =============================================================================

// A VÁLASZTOTT LEVÉL BEMÁSOLÁSA A SZERVEREN A megfelelö KÖNYVTÁRBA

var _subdir : string;

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
      ShowMessage('Központi szerver nem érhetõ el !');
      exit;
    end;

  _subdir := '';
  If _destiny='VIP' then _subdir := 'VIP';
  IF _destiny='ZALOG' then _subdir := 'ZALOG';

  IF _SUBDIR='' then _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\KORLEVEL'))
  else _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\KORLEVEL\'+_subdir));

  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      ShowMessage('Nem tud belépni a könyvtárba !');
      exit;
    end;

  result := FtpPutFile(_hFTP,pChar(_localPath),pChar(_remoteFile),
                                              FTP_TRANSFER_TYPE_BINARY,0);

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);
end;


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$  LEVELEK OLVASÁSA $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
            procedure TForm1.LISTAZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _localpath := '';
  Selectedit.Text := '';
  Selectedit.repaint;
  SzetkuldoGomb.Enabled := False;
  Menupanel.Visible := false;
  with readPanel do
    begin
      Top := 150;
      Left:= 200;
      Visible := true;
    end;
  Activecontrol := ReadGomb;
end;

// =============================================================================
                procedure TForm1.ReadgombClick(Sender: TObject);
// =============================================================================

begin
  ReadPanel.visible := False;
  _destiny := 'EBC';
  OlvasasRutin;
end;

// =============================================================================
               procedure TForm1.VipGombClick(Sender: TObject);
// =============================================================================

begin
  ReadPanel.visible := False;
  _destiny := 'VIP';
  OlvasasRutin;
end;

// =============================================================================
               procedure TForm1.ZalogGombClick(Sender: TObject);
// =============================================================================

begin
  ReadPanel.visible := False;
  _destiny := 'ZALOG';
  OlvasasRutin;
end;


// =============================================================================
             procedure TForm1.OlvasogombClick(Sender: TObject);
// =============================================================================

var _letterpath,_LPath: string;

begin
  _aktsorszam := Serverquery.FieldByName('SORSZAM').asInteger;
  _iktatostring := trim(ServerQuery.FieldByName('IKTATOSZAM').asstring);
  _tartalom := trim(Serverquery.FieldByName('TARTALOM').asString);
  _iFileNev := trim(ServerQuery.FieldByName('FILENEV').AsString);
  with NagyFuggony do
    begin
      Top := 8;
      Left := 8;

      Visible := true;
    end;

  _lPath := 'C:\KORLEVEL\';
  if _destiny='EBC' then _letterPath := _Lpath + _ifileNev;
  if _destiny='VIP' then _letterPath := _LPath + 'vip\'+_ifileNev;
  if _destiny='ZALOG' then _letterPath := _LPath + 'ZALOG\'+_ifileNev;


      _loaded := Levelletoltes(_ifileNev);
      if not _loaded then
        begin
          Showmessage('Nem sikerült letölteni a körlevelet a szerverrõl');
          Nagyfuggony.Visible := false;
          exit;
        end;



  OlvasasRegisztracio;

  // ---------------------------------------------------------------------

  SofficeLeallitas;
  _pcs := _sOffPath + ' ' + _letterPath;
  _pacs := pchar(_pcs);
  WinexecandWait32(_pacs,sw_normal);
  Nagyfuggony.Visible := false;
  OlvasasRutin;
end;

// =============================================================================
                  procedure TForm1.OlvasasRutin;
// =============================================================================

begin
  Menupanel.Visible := true;
//  Kijelologomb.Enabled := true;
  SzetkuldoGomb.Enabled := False;

  if _destiny='EBC' then _currlettname := 'KORLEVEL';
  if _destiny='ZALOG' then  _currlettname := 'ZALOGLEVEL';
  if _destiny='VIP' then _currlettname := 'VIPLEVEL';


  Serverdbase.close;
  Serverdbase.DatabaseName := _serverKordbasePath;
  serverDbase.Connected := true;

  _pcs := 'SELECT * FROM ' + _currlettname + _SORVEG;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND DESC';

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  with ListaPanel do
    begin
      Top := 0;
      Left := 8;
      Visible := true;
    end;
  Activecontrol := Korracs;
end;

// =============================================================================
              procedure TForm1.LISTABACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  ListaPanel.Visible := False;
  Menube;
  Activecontrol := Kijelologomb;

end;

// =============================================================================
     procedure TForm1.P1MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                 Y: Integer);
// =============================================================================

var _aktpanel: TPanel;

begin
  _aktpanel := TPanel(Sender);
  if _aktPanel.color= clLime then
    begin
      _aktpanel.Cursor := crHandPoint;
    //  _aktnums := _aktpanel.caption;
    //  _aktnum := strtoint(_aktnums);
    //  _aktnaps := _typ[_aktnum];
    //  _aktpanel.hint := 'Letöltve: '+ _aktnaps+'-án';
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

VAR _SAJDIR,_remotedir: string;

begin
  _sajdir := 'C:\KORLEVEL';
  if _destiny='ZALOG' then _sajdir := 'C:\KORLEVEL\ZALOG';
  if _destiny='VIP' then _sajdir := 'C:\KORLEVEL\VIP';

  _localPath := _SAJDIR + '\' + _fn;
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
      ShowMessage('Központi szerver nem érhetõ el !');
      exit;
    end;

  _remotedir := '\KORLEVEL';
  if _destiny='ZALOG' then _remotedir := _remotedir + '\ZALOG';
  if _destiny='VIP' then _remoteDir := _remotedir + '\VIP';

  _sikeres := FTPSetCurrentDirectory(_hFTP,pchar(_remotedir));
  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      ShowMessage('Nem tud belépni a '+_remotedir+' könyvtárba !');
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
  _Proc.dwSize := SizeOf(_Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
       _filepath := _Proc.szExeFile;
      _fileName := ExtractFileName(_filepath);
      _filename := uppercase(leftstr(_filename,7));
      if _fileName = _SelectedProcess then
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
             procedure TForm1.supervisorgombClick(Sender: TObject);
// =============================================================================

begin
  Selectedit.Text := '';
  Selectedit.repaint;
  Jelszoedit.clear;
  SzetkuldoGomb.Enabled := false;
  with JelszoPanel do
    begin
      top  := 310;
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
  Jelszopanel.Visible := False;

  if _jelszo<>'ZSU' then EXIT;
  SuperForm.showmodal;
end;


// =============================================================================
                          procedure TForm1.setVezetoTomb;
// =============================================================================

begin
  _vezetoDarab := 13;

  _vNev[1] := 'Fabulya Zsuzsanna';
  _vNev[2] := 'Kósa-Gallusz Ildikó';
  _vNev[3] := 'Gál-Ferencz Rita';
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

   {
  _eMail[1] := 'fabulyazsuzsa.eec@gmail.com';
  _eMail[2] := 'gallusz.ildiko.ebc@gmail.com';
  _eMail[3] := 'galferenczrita.ebc@gmail.com';
  _eMail[4] := 'vigh.emilia.ebc@gmail.com';
  _eMail[5] := 'hrabina.krisztian.eec@gmail.com';
  _eMail[6] := 'nagyannamari.ebc@gmail.com';
  _eMail[7] := 'kosa.zoltan.ebc@gmail.com';
  _eMail[8] := 'schnell.edit.ebc@gmail.com';
  _eMail[9] := 'reszegi.emese.eec@gmail.com';
  _eMail[10] := 'timarbiro.zita.epc@gmail.com';
  _eMail[11] := 'durucz.tamas.eec@gmail.com';
  _eMail[12] := 'kardos.ildiko.ebc@gmail.com';
  _eMail[13] := 'madarzoltan.ebc@gmail.com';
  }

end;









// =============================================================================
                          procedure TForm1.DolgozokTombbe;
// =============================================================================

var _cc: integer;

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
      inc(_cc);
      _pnev[_cc] := trim(Prosquery.fieldByname('PENZTAROSNEV').asString);
      _psor[_cc] := ProsQuery.FieldByName('SORSZAM').asInteger;
      ProsQuery.next;
    end;
  _DolgozoDarab := _cc;
  ProsQuery.close;
  Prosdbase.close;
end;


// =============================================================================
                       procedure TForm1.TartalomTombbe;
// =============================================================================

var _cc: integer;
    _tablanev : string;

begin
  if _destiny='EBC' then _tablanev := 'KORLEVEL';
  if _destiny='VIP' then _tablanev := 'VIPLEVEL';
  if _destiny='ZALOG' then _tablanev := 'ZALOGLEVEL';

  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND';

  ServerDbase.close;
  serverDbase.DatabaseName := _serverKordbasePath;
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
  serverdbase.close;

  // -----------------------------------------------------------------

  {
  _pcs := 'SELECT * FROM VIPLEVEL' + _sorveg;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND';

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
      _vipltart[_cc] := trim(serverQuery.fieldbyname('TARTALOM').asString);
      _viplsors[_cc] := ServerQuery.FieldByName('SORSZAM').asInteger;
      inc(_cc);
      ServerQuery.next;
    end;
  _viptartalomdarab := _cc;
  ServerQuery.close;
  ServerDbase.close;
  }

end;


// =============================================================================
                       procedure TForm1.Removetiltott;
// =============================================================================


var _volttiltas: boolean;
    _y: word;
    _aktTiltott,_aktIkt: string;
    _aktlen: byte;

begin
  ServerDbase.close;
  serverDbase.DatabaseName := _serverkordbasepath;
  ServerDbase.Connected := True;
  if ServerTranz.InTransaction then ServerTranz.Commit;
  ServerTranz.StartTransaction;

  _voltTiltas := False;
  _y := 1;
  while _y<=_tiltottdb do
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


// =============================================================================
                  procedure TForm1.OlvasasRegisztracio;
// =============================================================================

var _aktidos,_idostring: string;

begin
  if _destiny='ZALOG' then exit;

  _signal := 'SIGNAL';
  if _destiny='VIP' then _signal := 'VIPSIGNAL';


  _pcs := 'SELECT * FROM ' + _signal + _sorveg;
  _pcs := _pcs + 'WHERE (DOLGSORSZAM='+ inttostr(_dolgsorszam)+') ';
  _pcs := _pcs + 'AND (LETTERNUM=' + inttostr(_aktsorszam)+')';

  ServerDbase.close;
  serverDbase.databasename := _serverkordbasepath;
  serverDbase.connected := true;

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
      Close;
    end;
  serverdbase.close;

  if _recno=0 then
    begin
      _aktidos := timetostr(Time);   // mamas = 2015.05.31

      if midstr(_aktidos,2,1)=':' then _aktidos := '0' + _aktidos;
      _idostring := midstr(_mamas,6,2)+midstr(_mamas,9,2)+leftstr(_aktidos,2)+midstr(_aktidos,4,2);

      _pcs := 'INSERT INTO ' + _signal + ' (DOLGSORSZAM,LETTERNUM,MIKOR)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_dolgsorszam)+ ',';
      _pcs := _pcs + inttostr(_aktsorszam) + ',';
      _pcs := _pcs + chr(39) + _idostring + chr(39) + ')';

      with Serverquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          ExecSql;
        end;
      ServerTranz.Commit;
      Serverdbase.close;
    end;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$ SEGÉD-PROGRAMOK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// =============================================================================
                     procedure TForm1.Sorrendregen;
// =============================================================================

var _ujsr: word;

begin
  ServerDbase.close;
  serverDbase.DatabaseName := _serverKorDbasePath;
  ServerDbase.Connected := True;
  if ServerTranz.InTransaction then ServerTranz.Commit;
  ServerTranz.StartTransaction;

  with Servertabla do
    begin
      close;
      TableName := _currlettName;
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
  ServerDbase.DatabaseName := _serverKorDbasePath;
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
                     procedure TForm1.SetRemotefile;
// =============================================================================

var _nurnums: string;

begin
  _nurnums := fillnull(_iktatoszam);

  If _destiny='VIP' then _iktatostring := 'V' + _nurnums;
  if _destiny='EBC' then _iktatostring := _nurnums;
  if _destiny='ZALOG' then _iktatostring := 'Z' + _nurnums;

  _iktatostring := _sign + _iktatostring;
  _remotefile := _iktatostring + _lettext;
end;

// =============================================================================
              function TForm1.Getiktatoszam(_dest: string): integer;
// =============================================================================

begin
  result := -1;
  Serverdbase.close;
  Serverdbase.DatabaseName := _serverKordbasePath;
  serverdbase.Connected := true;

  _pcs := 'SELECT * FROM ADATOK';

  with serverQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  if _dest='EBC' then result :=  ServerQuery.FieldByName('UTSORSZAM').asInteger;
  if _dest='VIP' then result :=  ServerQuery.FieldByName('UTVIPSORSZAM').asInteger;
  if _dest='ZALOG' then result :=  ServerQuery.FieldByName('UTZALOGSORSZAM').asInteger;

  serverdbase.close;
  inc(result);
end;

// =============================================================================
                      function TForm1.getTiltott: byte;
// =============================================================================

var _cc: byte;

begin

  Serverdbase.close;
  Serverdbase.DatabaseName := _serverkordbasePath;
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
   _cc := 1;
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
                       procedure TForm1.Menube;
// =============================================================================

begin
  with MenuPanel do
    begin
      Top := 100;
      Left := 232;
      Visible := true;
    end;
end;

// =============================================================================
             procedure TForm1.ServerParancs(_ukaz: string);
// =============================================================================

begin
  ServerDbase.close;
  ServerDbase.DatabaseName := _serverKorDbasePath;
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
  while length(result)<3 do result := '0' + result;
end;

// =============================================================================
              procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;


procedure TForm1.ARCHIVEGOMBClick(Sender: TObject);

begin
  with ArchivePanel do
    begin
      left := 24;
      top  := 40;
      Visible := True;
    end;
end;


procedure TForm1.visszagombClick(Sender: TObject);
begin
  ReadPanel.visible := False;
  Menube;
  Activecontrol := Kijelologomb;
end;




function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

procedure TForm1.ZalogKuldes;
begin
  _iktatoszam := GetZalogIktatoszam;
  SetremoteFile;

  if not SendZalogLetter then
    begin
      CopyInfoPanel.Visible := false;
      ShowMessage('SIKERTELEN SZÉTKÜLDES');
      Height := 410;
      exit;
    end;

   _sr := trunc(2*_ikTatoszam);

   _pcs := 'INSERT INTO ZALOGLEVEL (IKTATOSZAM,DATUM,TARTALOM,';
   _pcs := _pcs + 'SORSZAM,SORREND,STORNO,FILENEV)'+ _sorveg;

   _pcs := _pcs + 'VALUES (' + CHR(39) + _iktatostring + chr(39) + ',';
   _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
   _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
   _pcs := _pcs + inttostr(_IKTATOSZAM) + ',';
   _pcs := _pcs + inttostr(_sr) + ',1,';
   _pcs := _pcs + chr(39) + _remotefile + chr(39)+')';

   ServerParancs(_pcs);
   _last := 'UTSORSZAM';

   _pcs := 'UPDATE ADATOK SET UTZALOGSORSZAM='+inttostr(_iktatoszam);
   ServerParancs(_pcs);

   // -----------------------------------------------------------

  copyInfoPanel.Visible := false;
  infoPanel.Visible := false;
  Menube;
end;



// =============================================================================
                  function TForm1.SendZalogLetter: boolean;
// =============================================================================

// A VÁLASZTOTT LEVÉL BEMÁSOLÁSA A SZERVEREN A MEGFELELÖ KÖNYVTÁRBA

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
      ShowMessage('Központi szerver nem érhetõ el !');
      exit;
    end;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\ZALOGLEVEL'));

  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      ShowMessage('Nem tud belépni a ZALOGLEVEL könyvtárba !');
      exit;
    end;

  result := FtpPutFile(_hFTP,pChar(_localPath),pChar(_remoteFile),
                                              FTP_TRANSFER_TYPE_BINARY,0);

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);
end;

// =============================================================================
              function TForm1.GetZalogiktatoszam: integer;
// =============================================================================

begin
  Serverdbase.close;
  Serverdbase.DatabaseName := _serverKordbasePath;
  serverdbase.Connected := true;
  _pcs := 'SELECT * FROM ADATOK';

  with serverQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := FieldByName('UTZALOGSORSZAM').asInteger;
      close;
    end;
  serverdbase.close;
  inc(result);
end;

procedure TForm1.Paracontrol;

var _okeid: integer;
    _ws: byte;
    _nums: string;

begin
  _idpath   := _korparamdir + '\id.txt';            // 1340,DÉKÁNY ANTAL
  _spath    := _korparamdir + '\soffpath.txt';       // C:\PROGRAM FILES\....
  _signPath := _korparamdir + '\sign.txt';          // DA

  _soffPath := GetSofficePath;
  if _soffpath='' then
    begin
      Application.Terminate;
      exit;
    end;

  if not fileExists(_idpath) then
    begin
      _okeid :=  Getidkod.showmodal;
      if _okeid=2 then
        begin
          Application.Terminate;
          exit;
        end;
    end;

  if not fileExists(_signpath) then
    begin
      _okeid :=  Getidkod.showmodal;
      if _okeid=2 then
        begin
          Application.Terminate;
          exit;
        end;
    end else
    begin
      Assignfile(_olvas,_signPath);
      reset(_olvas);
      readln(_olvas,_sign);
      Closefile(_olvas);
    end;

  AssignFile(_olvas,_idpath);
  reset(_olvas);
  read(_olvas,_idstring);
  CloseFile(_olvas);

  _ws := length(_idstring);
  _pos := pos(',',_idstring);
  _nums := leftstr(_idstring,_pos-1);
  _dolgnev := midstr(_idstring,_pos+1,_ws-_pos);
  val(_nums,_dolgsorszam,_code);

  Dolgnev.Caption := _dolgnev;
  Dolgnev.Visible := true;
  Dolgnev.Repaint;
  Menube;
end;



function TForm1.GetSofficePath: string;

begin
  if FileExists(_sPath) then
    begin
      AssignFile(_olvas,_sPath);
      reset(_olvas);
      Read(_olvas,result);
      CloseFile(_olvas);
      exit;
    end;

  if fileExists(_soffMinta) then
    begin
      result := _soffminta;
      AssignFile(_iras,_sPath);
      rewrite(_iras);
      write(_iras,result);
      Closefile(_iras);
      exit;
    end;

  if fileExists(_soffMint2) then
    begin
      result := _soffmint2;
      AssignFile(_iras,_sPath);
      rewrite(_iras);
      write(_iras,result);
      Closefile(_iras);
      exit;
    end;

  if fileExists(_soffMint3) then
    begin
      result := _soffmint2;
      AssignFile(_iras,_sPath);
      rewrite(_iras);
      write(_iras,result);
      Closefile(_iras);
      exit;
    end;

  ShowMessage('TELEPITENI KELL A LIBREOFFICE ALKALMAZÁST !');
  result := '';
END;


procedure TForm1.ARCHANGEGOMBClick(Sender: TObject);
begin
  ArchivePanel.Visible := False;
  _Tipus := 'N';
  Archiveform.showmodal;
end;

procedure TForm1.AREXPRESSZGOMBClick(Sender: TObject);
begin
  ArchivePanel.Visible := False;
  _Tipus := 'Z';
  Archiveform.showmodal;
end;

procedure TForm1.ARVIPGOMBClick(Sender: TObject);
begin
  ArchivePanel.Visible := False;
  _Tipus := 'V';
  Archiveform.showmodal;
end;

procedure TForm1.AREXITGOMBClick(Sender: TObject);
begin
  ArchivePanel.Visible := false;
end;

// ---------------------------------------------------------

procedure TForm1.LASTYEARGOMBClick(Sender: TObject);
begin
  with LastYearPanel do
    begin
      left := 24;
      top  := 40;
      Visible := True;
    end;
end;

procedure TForm1.LYChangeGombClick(Sender: TObject);
begin
  LastYearPanel.Visible := False;
  _Tipus := 'N';
  LastYearform.showmodal;
end;

procedure TForm1.LYEXPRESSZGOMBClick(Sender: TObject);
begin
  LastYearPanel.Visible := False;
  _Tipus := 'Z';
  LastYearform.showmodal;
end;

procedure TForm1.LyVIPGOMBClick(Sender: TObject);
begin
  LastYearPanel.Visible := False;
  _Tipus := 'V';
  LastYearform.showmodal;
end;

procedure TForm1.LyEXITGOMBClick(Sender: TObject);
begin
  LastyearPanel.Visible := false;
end;


procedure TForm1.Dirmake;

var _dir: string;

begin
  _dir := 'C:\KORLEVEL\ARCHIVE';
  if not DirectoryExists(_dir) then Createdir(_dir);

  _dir := 'C:\KORLEVEL\LASTYEAR';
  if not DirectoryExists(_dir) then Createdir(_dir);

  _dir := 'C:\KORLEVEL\ARCHIVE\ZALOG';
  if not DirectoryExists(_dir) then Createdir(_dir);

  _dir := 'C:\KORLEVEL\LASTYEAR\ZALOG';
  if not DirectoryExists(_dir) then Createdir(_dir);

  _dir := 'C:\KORLEVEL\ARCHIVE\VIP';
  if not DirectoryExists(_dir) then Createdir(_dir);

  _dir := 'C:\KORLEVEL\LASTYEAR\VIP';
  if not DirectoryExists(_dir) then Createdir(_dir);

END;

procedure TForm1.VipEmailBeolvaso;

begin
  _pcs := 'SELECT * FROM ADDRESS WHERE SORSZAM>1';

  serverdbase.close;
  serverdbase.DatabaseName := _midchiefPath;
  ServerDbase.Connected := true;

  with ServerQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _cimdb := 0;
  while not Serverquery.eof do
    begin
      inc(_cimdb);
      _aktemailcim := trim(Serverquery.Fieldbyname('EMAIL').asString);
      _mailcim[_cimdb] := _aktemailcim;
      ServerQuery.next;
    end;
  ServerQuery.close;
  ServerDbase.close;
end;

procedure TForm1.Makexml;

var _y: byte;

begin
  _aktnap := dayof(date);
  _xmlFile := 'EFZS' + inttostr(_aktnap)+'.xml';
  _xmlPath := 'c:\temp\' + _xmlFile;

  assignfile(_iras,_xmlpath);
  rewrite(_iras);
  writeLn(_iras,'<mail>');
  writeln(_iras,'  <addresses>');

  _y :=1;
  while _y<=_cimdb do
    begin
      writeLn(_iras,'    <address>'+_mailcim[_y]+'</address>');
      inc(_y);
    end;
  writeLn(_iras,'</addresses>');
  writeLn(_iras,'<subject>korlevel erkezett</subject>');

  _selectedFile := angolra(_selectedFile);

  writeln(_iras,'<message>Fabulya Zsuzsa ' + _selectedfile + ' nevu korlevelet kuldott');
  writeLn(_iras,'Kerem elolvasni. Koszonom</message>');
  writeLn(_iras,'</mail>');

  closefile(_iras);
end;

// =============================================================================
                  function TForm1.SendMailStart: boolean;
// =============================================================================

// A VÁLASZTOTT LEVÉL BEMÁSOLÁSA A SZERVEREN A megfelelö KÖNYVTÁRBA

begin
  _localpath  := _xmlPath;
  _remotefile := _xmlFile;

  result := False;

  if not Vaninternet then exit;

  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then exit;

  _hFtp := Nil;
  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
            Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hFtp=Nil then
    begin
      InternetCloseHandle(_hnet);
      exit;
    end;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\SENDMAIL'));

  If not _sikeres then
    begin
      InternetCLosehandle(_hFTP);
      InternetCloseHandle(_hnet);
      exit;
    end;

  result := FtpPutFile(_hFTP,pChar(_localPath),pChar(_remoteFile),
                                              FTP_TRANSFER_TYPE_BINARY,0);

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);
end;

// =============================================================================
                 function TForm1.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
end;


// =============================================================================
                   function TForm1.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;


end.
