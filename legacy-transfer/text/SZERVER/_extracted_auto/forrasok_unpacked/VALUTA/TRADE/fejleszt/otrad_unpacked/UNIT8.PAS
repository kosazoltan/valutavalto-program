unit Unit8;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, unit1, IBDatabase, DB, IBCustomDataSet,
  IBQuery, ExtCtrls, idglobal, wininet;

type
  TUJTANUSITVANY = class(TForm)
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;
    Panel1: TPanel;
    KILEPO: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure FTPszerverbeBelep;

    function Zeroele(_b: byte): string;
    function PemekLetoltese: boolean;




  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UJTANUSITVANY: TUJTANUSITVANY;
  _top1,_left1: word;
  _MRESULT,_homeptar: integer;
  _tradeNnnDir,_homepts,_localdir,_source,_target,_localpath,_remotefile: string;
  _hNet,_hFTP: HINTERNET;
  _host: string = '185.43.207.99';
  _userid: string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';
  _ftpport: integer = 21100;

implementation

{$R *.dfm}


procedure TUJTANUSITVANY.FormActivate(Sender: TObject);
begin
  _top1 := Form1.top;
  _left1:= Form1.Left;

  Top := _top1+560;
  Left := _left1+150;

  Panel1.Repaint;

  Valdbase.Connected := true;
  with Valquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepts := trim(FieldByName('PENZTARKOD').asString);
      Close;
    end;

  Valdbase.close;
  Val(_homepts,_homeptar,_code);

  _tradeNnnDir := '\TRADE\PEMS\PT'+ zeroEle(_homeptar);

  _localdir := 'c:\valuta\temp';
  if not DirectoryExists(_localdir) then Createdir(_localdir);

  if not PemekLetoltese then
    begin
      _mResult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  _source := _localdir + '\CERTIFIC.PEM';
  _target := 'C:\VALUTA\TRADE\CERTIFIC.PEM';

  _mResult := 2;

  if fileExists(_target) then Sysutils.DeleteFile(_target);
  if CopyFileto(_source,_target) then
    begin
      _source := _localdir + '\PRIVKEY.PEM';
      _target := 'C:\VALUTA\TRADE\PRIVKEY.PEM';

      if fileExists(_target) then Sysutils.DeleteFile(_target);
      if CopyFileto(_source,_target) then _mResult := 1;
    end;
  Kilepo.enabled := true;
end;


function TUJtanusitvany.Zeroele(_b: byte): string;

begin
  result := inttostr(_b);
  while length(result)<3 do result := '0' + result;
end;



// =============================================================================
               function TUjtanusitvany.PemekLetoltese: boolean;
// =============================================================================

begin
  result := False;

  FTPSzerverbeBelep;
  if _hFTP=Nil then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_tradeNnnDir));
  if not _sikeres then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  _localpath := _localdir + '\CERTIFIC.PEM';
  _remoteFile:= 'CERTIFIC.PEM';

  _sikeres := ftpgetfile(_hftp,pchar(_remotefile),pchar(_localpath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);
  if _sikeres then
    begin
      _localpath := _localdir + '\PRIVKEY.PEM';
      _remoteFile:= 'PRIVKEY.PEM';
      _sikeres := ftpgetfile(_hftp,pchar(_remotefile),pchar(_localpath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);
    end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
  Result := _sikeres;
end;


// =============================================================================
                      procedure TUjtanusitvany.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then exit;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

end;

procedure TUJTANUSITVANY.KILEPOTimer(Sender: TObject);
begin
   Kilepo.Enabled := False;
   Modalresult := _mResult;
end;

end.
