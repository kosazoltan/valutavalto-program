unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  WININET;

type
  TForm2 = class(TForm)
    MQUERY: TIBQuery;
    MDBASE: TIBDatabase;
    MTRANZ: TIBTransaction;
    KILEPO: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _remoteDir,_remoteFile,_localpath: string;
  _siker: boolean;
  _mResult: integer;
  _hNet,_hFtp: HINTERNET;

  _host       : string;
  _ftpPort    : integer = 21100;
  _userId     : string  = 'ebc-10%';
  _ftpPassword: string  = 'klc+45%';


function copyfiletoftprutin: integer; stdcall;

implementation

{$R *.dfm}

function copyfiletoftprutin: integer; stdcall;
begin
  Form2 := TForm2.Create(Nil);
  result := Form2.Showmodal;
  Form2.Free;
end;


procedure TForm2.FormActivate(Sender: TObject);
begin
  Mdbase.Connected := True;
  with Mquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM MEDIA');
      Open;
      _remotedir := trim(FieldByNAme('REMOTEDIR').asString);
      _remoteFile := trim(FieldByNAme('REMOTEFILE').asString);
      _localPath := trim(FieldByName('LOCALPATH').asString);
      Close;
      sql.Clear;
      sql.Add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
      Close;
    end;
  Mdbase.close;

  _localPath := 'c:\valuta\' + _localpath;

  // ------------------------------------------------------------------

  _mResult := 2;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      Kilepo.Enabled := True;
      Exit;
    end;

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hFTP=nil then
    begin
      InternetCLoseHandle(_hNet);
      Kilepo.enabled := True;
      exit;
    end;

  _siker :=  FTPSetCurrentDirectory(_hFTP,pchar('\'+ _remoteDir));
  if not _siker then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Kilepo.enabled := True;
      Exit;
    end;

  _siker := FtpPutFile(_hFTP,pChar(_localPath),pChar(_remoteFile),
                                              FTP_TRANSFER_TYPE_BINARY,0);

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);
  if _siker then
    begin
      Sysutils.DeleteFile(_localpath);
      _mResult := 1;
    end;
  Kilepo.enabled := true;
end;



procedure TForm2.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

end.
