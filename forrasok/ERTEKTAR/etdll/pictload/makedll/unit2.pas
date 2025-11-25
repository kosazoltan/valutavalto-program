unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, wininet, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type
  TForm2 = class(TForm)
    INDITO: TTimer;
    KILEPO: TTimer;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;

    procedure INDITOTimer(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure FTPszerverbeBelep;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _etszam : Byte;
  _mResult: integer;
  _akep,_path,_apath: string;

  _host : string;
  _userId : string = 'ebc-10%';
  _ftpPassword : string = 'klc+45%';
  _ftpPort: integer = 21100;
  _findData: WIN32_FIND_DATA;

  _localPath,_remoteFile: pchar;

  _hNet,_hFtp: HINTERNET;

  _siker: boolean;



function getcitypictures(_para: byte): integer; stdcall;

implementation

{$R *.dfm}


function getcitypictures(_para: byte): integer; stdcall;

begin
  Form2 := Tform2.Create(NIL);
  _etszam := _para;
  result := Form2.showModal;
  Form2.Free;
end;


procedure TForm2.INDITOTimer(Sender: TObject);
begin

  top := 0;
  left := 0;
  width := 5;
  Height := 5;

  valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT* FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
      Close;
    end;
  valutadbase.close;


  _mResult := 2;
  indito.Enabled := false;
  _akep := 'ET' + inttostr(_etszam)+'A.JPG';
  _path := 'c:\ertektar\flags\';
  _apath := _path + _akep;
  if Fileexists(_apath) then
    begin
      Kilepo.Enabled := true;
      exit;
    end;

   FTPSzerverbeBelep;
   if _hFTP=Nil then
     begin
       Kilepo.Enabled := true;
       exit;
     end;

   _siker :=  FTPSetCurrentDirectory(_hFTP,pchar('\PICTURES'));
   if not _siker then
     begin
       InternetCloseHandle(_hFTP);
       InternetCloseHandle(_hNet);
       Kilepo.Enabled := True;
       Exit;
     end;

   _localPath := pChar(_aPath);
   _remoteFile:= pChar(_aKep);
   FTPGetFile(_hftp,_remotefile,_localpath,False,0,FTP_TRANSFER_TYPE_BINARY,0);

   _aKep  := 'ET' + inttostr(_etszam) + 'B.JPG';
   _apath := _path + _akep;

   _localPath := pChar(_aPath);
   _remoteFile:= pChar(_aKep);
   FTPGetFile(_hftp,_remotefile,_localpath,False,0,FTP_TRANSFER_TYPE_BINARY,0);

   _aKep  := 'ET' + inttostr(_etszam) + 'C.JPG';
   _apath := _path + _akep;

   _localPath := pChar(_aPath);
   _remoteFile:= pChar(_aKep);
   FTPGetFile(_hftp,_remotefile,_localpath,False,0,FTP_TRANSFER_TYPE_BINARY,0);

   InternetCloseHandle(_hFTP);
   InternetCloseHandle(_hNet);

   _mResult := 1;
   Kilepo.Enabled := True;

end;



procedure TForm2.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  Modalresult := _mResult;
end;


// =============================================================================
                      procedure TForm2.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := NIL;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);

  if _hNet=NIL then exit;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=NIL then InternetCloseHandle(_hNet);

end;



end.
