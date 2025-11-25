unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Buttons, StrUtils,wininet,
  IBDatabase, DB, IBCustomDataSet, IBQuery,jpeg;

type
  TForm2 = class(TForm)
    ScrollBox1   : TScrollBox;

    GombTakaro   : TPanel;
    ImagePanel   : TPanel;
    InfoPanel    : TPanel;
    OkmanyPanel  : TPanel;
    OkmNevPanel  : TPanel;
    OkmCimPanel  : TPanel;
    ValaszPanel  : TPanel;

    BackGomb     : TBitBtn;
    EloOkmGomb   : TBitBtn;
    KovOkmGomb   : TBitBtn;
    TotalKepGomb : TBitBtn;

    RecQuery     : TIBQuery;
    RecDbase     : TIBDatabase;
    RecTranz     : TIBTransaction;

    BizlatokQuery: TIBQuery;
    BizlatokDbase: TIBDatabase;
    BizlatokTranz: TIBTransaction;

    Kilepo       : TTimer;
    Label1       : TLabel;
    Csik         : TProgressBar;
    Vetito       : TImage;

    procedure BackGombClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure EloOkmGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure KovOkmGombClick(Sender: TObject);
    procedure Recparancs(_ukaz: string);
    procedure TotalKepGombClick(Sender: TObject);
    procedure Vetites;
    procedure VTempBeolvasas;

    function Beolvasas: boolean;
    function FtpOpen(_remdir: string): boolean;
    function Kikuldes(_lpath,_rFile: string): boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _height,_width,_top,_left,_count,_szeles,_magas: word;

  _hNet,_hFTP,_hSearch: HINTERNET;
  _findData: WIN32_FIND_DATA;

  _sorveg: string = chr(13)+chr(10);

  _ftpPassword : String  = 'klc+45%';
  _ftpPort     : Integer = 21100;
  _host        : String  = '185.43.207.99';
  _userId      : String  = 'ebc-10%';

  _sFile: array[1..9] of string;
  _okmany: array[1..9] of string;
  _srec: TSearchrec;

  _okmss: byte;
  _qNev,_qLakcim,_evtizes,_qDatum,_pcs,_askfile,_askPath: string;
  _localpath,_remotefile,_mess,_kPath,_minta,_aktokm: string;
  _mResult,_okmdb: integer;
  _iras: textfile;
  _kikuldve,_siker,_total: boolean;


procedure GetJPGSize(const sFile: string; var wWidth, wHeight: word);

function ReadMWord(f: TFileStream): word;
function okmanydisplayrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
             function okmanydisplayrutin: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;

// =============================================================================
                 procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height  := screen.Monitors[0].Height;
  _width   := Screen.Monitors[0].Width;
  _top     := round((_height-595)/2);
  _left    := round((_width-1017)/2);

  Top      := _top-50;
  Left     := _left;
  Height   := 537;
  width    := 1001;
  _mResult := 2;

  Vetito.Picture.CleanupInstance;

  GombTakaro.Visible  := True;
  Infopanel.Visible   := false;
  ValaszPanel.Visible := False;
  Csik.Position       := 0;

  repaint;

  VTempBeolvasas;

  OkmNevPanel.caption := _qnev;
  OkmNevPanel.repaint;

  OkmCimPanel.caption := _qLakcim;
  OkmanyPanel.repaint;

  _pcs := 'UPDATE RENDSZER SET MASOLVA=-1';
  RecParancs(_pcs);

  _askPath := 'c:\uctrl\data\' + _askfile;

  AssignFile(_iras,_askpath);
  rewrite(_iras);
  Closefile(_iras);

  _localPath := 'c:\UCTRL\DATA\' +_askfile;
  _remotefile := _askFile;

  _kikuldve := kikuldes(_localPath,_remoteFile);
  if not _kikuldve then ShowMessage('NEM SIKERÜLT A KÉRÉST KIKÜLDENI');
  Sysutils.DeleteFile(_askPath);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
  if not _Kikuldve then
    begin
      Modalresult := 2;
      exit;
    end;

  Infopanel.Caption := 'ELKÜLDTEM A KÉRÉST A SZERVERRE';
  InfoPanel.Visible := True;
  infoPanel.repaint;

  // -----------------------------------

  Csik.max := 60;
  _count := 1;
  while _count<=60 do
    begin
      csik.Position := _count;
      INc(_count);
      sleep(100);
    end;

  recdbase.close;
  recdbase.Databasename := _host+':C:\receptor\database\receptor.fdb';
  Recdbase.Connected := true;
  with Recquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM RENDSZER');
      Open;
      _okmdb := FieldByNAme('MASOLVA').asInteger;
    end;
  recquery.close;
  recdbase.close;

  // --------------------------------------------------

  Csik.Position := 60;

  _siker := False;
  if _okmdb>0 then
    begin
      if Beolvasas then _siker := True;
    end;

  if not _siker then
    begin
      ValaszPanel.Caption := 'Nem küldött okmányt a szerver';
      ValaszPanel.Visible := True;
      ValaszPanel.repaint;
      sleep(2500);
      Modalresult := 2;
      exit;
    end;

  _mess := inttostr(_okmdb)+' DARAB OKMÁNYT KÜLDÖTT A SZERVERRE';
  ValaszPanel.Caption := _mess;
  ValaszPanel.Visible := true;
  ValaszPanel.repaint;

  GombTakaro.Visible := False;
  Okmanypanel.repaint;

  elookmgomb.Enabled := false;
  if _okmdb=1 then kovokmgomb.Enabled := False else kovokmgomb.Enabled := true;

  _okmss := 1;
  _kpath := 'c:\uctrl\data\'+_okmany[1];
  Totalkepgomb.Caption := 'NAGYITOTT KÉP';
  _total := True;
  Vetites;
end;

// =============================================================================
                   procedure TForm2.VtempBeolvasas;
// =============================================================================

begin
  bizlatokdbase.connected := true;
  with BizlatokQuery do
    begin
      Close;
      Sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _qnev := trim(FieldByNAme('NEV').asstring);
      _qLakcim := trim(FieldByNAme('CIM').asString);
      _qDatum := FieldByName('DATUM').asString;
      _askfile := trim(FieldByName('ASKFILE').asString);
    end;
  Bizlatokdbase.close;
end;

// =============================================================================
              procedure TForm2.Button1Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
                        procedure TForm2.Vetites;
// =============================================================================

begin
  if _total then
    begin
      ImagePanel.Width := 497;
      ImagePanel.Height := 530;
    end else
    begin
      GetJpgSize(_KPath,_szeles,_magas);
      ImagePanel.Width := _szeles;
      ImagePanel.Height := _magas;
    end;

  Vetito.Picture.LoadFromFile(_kpath);
  Vetito.repaint;
end;

// =============================================================================
         procedure GetJPGSize(const sFile: string; var wWidth, wHeight: word);
// =============================================================================

const
  ValidSig : array[0..1] of byte = ($FF, $D8);
  Parameterless = [$01, $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7];
var
  Sig: array[0..1] of byte;
  f: TFileStream;
  x: integer;
  Seg: byte;
  Dummy: array[0..15] of byte;
  Len: word;
  ReadLen: LongInt;
begin
  FillChar(Sig, SizeOf(Sig), #0);
  f := TFileStream.Create(sFile, fmOpenRead);
  try
    ReadLen := f.Read(Sig[0], SizeOf(Sig));
    for x := Low(Sig) to High(Sig) do
      if Sig[x] <> ValidSig[x] then
        ReadLen := 0;
      if ReadLen > 0 then
      begin
        ReadLen := f.Read(Seg, 1);
        while (Seg = $FF) and (ReadLen > 0) do
        begin
          ReadLen := f.Read(Seg, 1);
          if Seg <> $FF then
          begin
            if (Seg = $C0) or (Seg = $C1) then
            begin
              ReadLen := f.Read(Dummy[0], 3);  // don't need these bytes
              wHeight := ReadMWord(f);
              wWidth := ReadMWord(f);
            end
            else
            begin
              if not (Seg in Parameterless) then
              begin
                Len := ReadMWord(f);
                f.Seek(Len - 2, 1);
                f.Read(Seg, 1);
              end
              else
                Seg := $FF;  // Fake it to keep looping.
            end;
          end;
        end;
      end;
    finally
    f.Free;
  end;
end;

// =============================================================================
                function ReadMWord(f: TFileStream): word;
// =============================================================================

type
  TMotorolaWord = record
  case byte of
  0: (Value: word);
  1: (Byte1, Byte2: byte);
end;

var
  MW: TMotorolaWord;
begin
  // It would probably be better to just read these two bytes in normally and
  // then do a small ASM routine to swap them. But we aren't talking about
  // reading entire files, so I doubt the performance gain would be worth the trouble.
  f.Read(MW.Byte2, SizeOf(Byte));
  f.Read(MW.Byte1, SizeOf(Byte));
  Result := MW.Value;
end;

// =============================================================================
          function Tform2.FtpOpen(_remdir: string): boolean;
// =============================================================================

begin
  result := False;
  _hnet := InternetOpen('Server',INTERNET_OPEN_TYPE_PRECONFIG,Nil,Nil,0);
  if _hnet=NIL then exit;

  _hFTP := InternetConnect(_hNet,pchar(_host),_ftpPort,pchar(_userId),
             pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  If _hFTP=Nil then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  result := FtpSetCurrentDirectory(_hFTP,pchar(_remdir));
  If not result then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;
end;

// =============================================================================
     function Tform2.Kikuldes(_lpath,_rFile: string): boolean;
// =============================================================================

begin
  result := False;
  if not FtpOpen('\SCANS\ASK') then exit;
  result := FtpPutFile(_hFtp,pchar(_lPath),pchar(_rFile),FTP_TRANSFER_TYPE_BINARY,0);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

// =============================================================================
                 function Tform2.Beolvasas: boolean;
// =============================================================================

var _q: byte;

begin
  result := False;
  _okmdb := 0;

  if not FtpOpen('\SCANS\OUT') then exit;
  _minta := '*.JPG';
  _hSearch := ftpFindFirstFile(_hFTP,pchar(_minta),_findData,0,0);
  if _hSearch=Nil then
     begin
       InternetCloseHandle(_hFTP);
       InternetCloseHandle(_hNet);
       exit;
     end;
  repeat
    inc(_okmdb);
    _okmany[_okmdb] := _findData.cFilename;
  until not InternetFindNextFile(_hSearch,@_findData);
  InternetCloseHandle(_hsearch);

  // ------------------------------------------------------------------

  _q := 0;
  while _q<_okmdb do
    begin
      inc(_q);
      _aktokm := _okmany[_q];
      _localpath := 'c:\UCTRL\DATA\'+_aktokm;
      _remoteFile := _aktokm;
      result := ftpgetFile(_hFtp,pchar(_remoteFile),pchar(_localPath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);
      FtpDeleteFile(_hFtp,pchar(_remoteFile));
    end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  _okmdb := _q;
end;

// =============================================================================
                procedure Tform2.Recparancs(_ukaz: string);
// =============================================================================

begin
  recdbase.close;
  recdbase.databasename := _host + ':c:\receptor\database\receptor.fdb';
  recdbase.connected := true;
  if rectranz.InTransaction then rectranz.Commit;
  rectranz.StartTransaction;
  with recquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      execsql;
    end;
  rectranz.commit;
  recdbase.close;
end;

// =============================================================================
              procedure Tform2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  Modalresult := _mResult;
end;

// =============================================================================
               procedure Tform2.BACKGOMBClick(Sender: TObject);
// =============================================================================

var _okmPath: string;

begin
 _okmss := 1;
 while _okmss<=_okmdb do
   begin
     _okmPath := 'c:\uctrl\data\' + _okmany[_okmss];
     sysutils.DeleteFile(_okmPath);
     inc(_okmss);
   end;
 ModalResult := 1;
end;

// =============================================================================
               procedure Tform2.KOVOKMGOMBClick(Sender: TObject);
// =============================================================================

begin
  inc(_okmss);
  if _okmss=_okmdb then KovOkmgomb.Enabled := False;
  EloOkmGomb.Enabled := true;
  _kPath := 'c:\uctrl\data\'+_okmany[_okmss];
  Vetites;
end;

//==============================================================================
          procedure Tform2.ELOOKMGOMBClick(Sender: TObject);
// =============================================================================

begin
  dec(_okmss);
  if _okmss=1 then elookmgomb.Enabled := False;
  KovOkmGomb.Enabled := true;
  _kPath := 'c:\uctrl\data\'+_okmany[_okmss];
  Vetites;
end;

// =============================================================================
            procedure TForm2.TOTALKEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _total then
    begin
      Totalkepgomb.Caption := 'TELJES KÉP';
      TotalKepGomb.repaint;
      _total := False;
    end else
    begin
      Totalkepgomb.Caption := 'NAGYITOTT KÉP';
      TotalKepGomb.repaint;
      _total := True;
    end;
  Vetites;
end;
end.
