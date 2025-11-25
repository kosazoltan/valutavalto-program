unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, dateutils,wininet, ComCtrls, ExtCtrls, jpeg,
  IBDatabase, DB, IBCustomDataSet, IBQuery, strutils;

type
  TForm1 = class(TForm)
    startgomb: TBitBtn;
    csik: TProgressBar;
    Label1: TLabel;
    Image1: TImage;
    szazalekpanel: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    Label2: TLabel;
    RECEPTQUERY: TIBQuery;
    RECEPTDBASE: TIBDatabase;
    RECEPTTRANZ: TIBTransaction;

    procedure startgombClick(Sender: TObject);
    procedure NaptaroloUrites(_dirnev: string);
    function  HuStrTOdate(_s: string): TDateTime;
    procedure NapimentesMentes;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _mentDate: TDatetime;
  _hNet,_hFtp,_hSearch: HINTERNET;
  _engname: array[1..7] of string = ('MONDAY','TUESDAY','WEDNESDY','THURSDAY',
                                      'FRIDAY','SATURDAY','SUNDAY');
  _delnev: array[1..500] of string;

  _HNAP,_letoltve,_qq,_fbkdarab: integer;

  _napnev,_sourcedir,_targetdir,_aktfbknev,_targetPath,_lastsave: string;
  _fbknev: array[1..500] of string;
  _cegdir : string = 'c:\cegment';
  _height,_width: word;
  _code: integer;

  _findData    : WIN32_FIND_DATA;
  _ftpPassword : String  = 'klc+45%';
  _ftpPort     : Integer = 21100;
  _host        : String  = '185.43.207.99';
  _userid      : string = 'ebc-10%';

  _sikeres : boolean;
  _minta,_aktdelnev,_delPath: string;
  _deldarab: integer;
  _srec: TsearchRec;

implementation

{$R *.dfm}


// =============================================================================
             procedure TForm1.FormCreate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  Left := trunc((_width-1020)/2);
  Top := 50;
end;

// =============================================================================
            procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin

  // Kiolvassa a szerver-rendszerbõl az utolsó mentés napját -> lastsave

  ReceptDbase.close;
  receptdbase.DatabaseName := _host + ':c:\receptor\database\receptor.fdb';
  ReceptDbase.Connected := true;
  with ReceptQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM RENDSZER');
      Open;
      _lastsave := fieldByNAme('LASTSAVE').asString;
      Close;
    end;
  ReceptDbase.close;

  // _Mentdate = az uoltsó mentés dátuma

  _mentdate := hustrtodate(_lastsave);

  Startgomb.Enabled := true;
  ActiveCOntrol := StartGomb;
end;

// =============================================================================
            procedure TForm1.startgombClick(Sender: TObject);
// =============================================================================

begin
  StartGomb.Visible := False;
  Shape1.repaint;

  NapimentesMentes;

  Showmessage(inttostr(_letoltve)+' darab file mentve');
  Application.Terminate;
end;

// =============================================================================
                  procedure TForm1.NapiMentesMentes;
// =============================================================================

var _szazalek: integer;

begin
  _letoltve  := 0;
  _fbkdarab  := 0;
  _hnap      := dayoftheweek(_mentdate);
  _napnev    := _engname[_hnap];

  if not DirectoryExists(_cegdir) then CreateDir(_cegdir);

  // Targetdir := c:\cegment\MONDAY  pl.
  _targetDir := _cegdir + '\' + _napnev;

  if not DirectoryExists(_targetdir) then CreateDir(_targetdir)
  else NaptaroloUrites(_targetdir);

  _sourcedir := _napnev;

  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then exit;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then exit;

   _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('MENTES\' + _napnev ));
  if not _sikeres then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  _hSearch := FtpFindFirstFile(_hFTp,pchar('*.Fbk'),_findData,0,0);
  if _hSearch=NIL then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  repeat
     inc(_fbkdarab);
    _fbknev[_fbkdarab] := _findData.cFileName;
  until not InternetFindNextFile(_hSearch,@_findData);
  InternetCloseHandle(_hSearch);

  Csik.Max := _fbkdarab;

  _qq := 1;
  while _qq<=_fbkDarab do
    begin
      Application.ProcessMessages;
      csik.Position := _qq;
      _szazalek := trunc(100*_qq/_fbkdarab);
      szazalekpanel.Caption := inttostr(_szazalek)+' %';
      szazalekPanel.repaint;

      _aktfbknev := _fbknev[_qq];
      _targetpath := _targetdir +'\'+ _aktfbknev;

      _sikeres := FTPGetFile(_hFTp,pchar(_aktfbknev),pchar(_targetpath),
                       False,0,FTP_TRANSFER_TYPE_BINARY,0);

      if _sikeres then inc(_letoltve);
      inc(_qq);
    end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

// =============================================================================
                procedure TForm1.NaptaroloUrites(_dirnev: string);
// =============================================================================

begin
  _minta := _dirnev + '\*.fbk';
  _deldarab := 0;

  if FindFirst(_minta, faAnyfile,_srec) = 0 then
    begin
      repeat
        inc(_deldarab);
        _delnev[_deldarab] := _srec.Name;
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
  if _delDarab=0 then exit;

  _qq := 1;
  while _qq<=_deldarab do
    begin
      _aktdelnev := _delnev[_qq];
      _delPath   := _dirnev + '\' + _aktdelnev;
      _sikeres := SysUtils.deletefile(_delPath);
      if not _sikeres then
         begin
           Showmessage('NEM TUDOM TÖRÖLNI '+_delPath+' nevü file-t !');
           exit;
         end;
      inc(_qq);
    end;
end;

// =============================================================================
           function Tform1.HuStrTOdate(_s: string): TDateTime;
// =============================================================================

var _xevs,_xhos,_xnaps: string;
    _xev,_xho,_xnap : word;

begin
  _xevs  := leftstr(_s,4);
  _xhos  := midstr(_s,6,2);
  _xnaps := midstr(_s,9,2);

  val(_xevs,_xev,_code);
  val(_xhos,_xho,_code);
  val(_xnaps,_xnap,_code);

  result := encodeDate(_xev,_xho,_xnap);
end;
end.



