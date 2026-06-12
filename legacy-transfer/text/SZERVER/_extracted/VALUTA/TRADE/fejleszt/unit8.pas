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
    TRADEQUERY: TIBQuery;
    TRADEDBASE: TIBDatabase;
    TRADETRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure FTPszerverbeBelep;

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


implementation

{$R *.dfm}

// =============================================================================
           procedure TUJTANUSITVANY.FormActivate(Sender: TObject);
// =============================================================================

begin
  _top1 := Form1.top;
  _left1:= Form1.Left;

  Top  := _top1+560;
  Left := _left1+220;
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

  _remoteFile:= 'Coupon.p12';

  if _sikeres then
      result := ftpgetfile(_hftp,pchar(_remotefile),pchar(_localpath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
 
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

// =============================================================================
           procedure TUJTANUSITVANY.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
   Kilepo.Enabled := False;
   Modalresult := _mResult;
end;

end.
