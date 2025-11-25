unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBDatabase, IBCustomDataSet, IBQuery,
  Grids, DBGrids, unit1, wininet, ExtCtrls;

type
  TARCHIVEFORM = class(TForm)
    ARCBACKGOMB: TButton;
    ARCREADGOMB: TBitBtn;
    ARCRACS: TDBGrid;
    ARCQUERY: TIBQuery;
    ARCDBASE: TIBDatabase;
    ARCTRANZ: TIBTransaction;
    ARCSOURCE: TDataSource;
    ARCQUERYDATUM: TIBStringField;
    ARCQUERYIKTATOSZAM: TIBStringField;
    ARCQUERYSORREND: TSmallintField;
    ARCQUERYSORSZAM: TSmallintField;
    ARCQUERYFILENEV: TIBStringField;
    ARCQUERYTARTALOM: TIBStringField;
    ARCQUERYSTORNO: TSmallintField;
    ARCQUERYSORTEMP: TSmallintField;
    INFOCSIK: TPanel;
    FOCIMPANEL: TPanel;

    procedure ARCBACKGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ARCREADGOMBClick(Sender: TObject);
    function Arcletoltes(_remoteFile: string): boolean;
    procedure FiletValasztott;
    procedure ARCRACSDblClick(Sender: TObject);
    procedure ARCRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ARCHIVEFORM: TARCHIVEFORM;
  _arcdir,_arcfilenev,_alkonyvtar: string;

implementation

{$R *.dfm}

procedure TARCHIVEFORM.ARCBACKGOMBClick(Sender: TObject);
begin
  Arcquery.close;
  Arcdbase.close;
  mODALRESULT := 1;
end;

procedure TARCHIVEFORM.FormActivate(Sender: TObject);
begin
  TOP := 155;
  lEFT := 220;
  Height := 366;
  Width := 836;
  Infocsik.Visible := false;

  if _tipus='N' then
    begin
      _dirnev := '';
      _remotenev := 'ARCHIVE';
      Focimpanel.Caption := 'ARHIV (Exclusive Change) KÖRLEVELEK';
    end;

  if _tipus='V' then
    begin
      _dirnev := 'VIP';
      _remotenev := 'V_ARCHIVE';
      Focimpanel.Caption := 'ARHÍV (középvezetöi) KÖRLEVELEK';
    end;

  if _tipus='Z' then
    begin
      _dirnev := 'ZALOG';
      _remotenev := 'Z_ARCHIVE';
      FocimPanel.Caption := 'ARHÍV (expressz) KÖRLEVELEK';
    end;

  focimpanel.repaint;

  ArcDbase.close;
  ArcDbase.DatabaseName := _serverKordbasePath;
  ArcDbase.Connected := true;

  _pcs := 'SELECT * FROM ' + _remotenev + _SORVEG;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND DESC';

  with ArcQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _ARCDIR := 'C:\KORLEVEL\ARCHIVE';
  If not DirectoryExists(_arcdir) then CreateDir(_arcdir);

  If _dirnev<>'' then _arcdir := _arcdir + '\' + _dirnev;
  If not DirectoryExists(_arcdir) then CreateDir(_arcdir);
  Activecontrol := Arcracs;
end;


procedure TARCHIVEFORM.ARCREADGOMBClick(Sender: TObject);
begin
  FiletValasztott;
end;


procedure TArchiveForm.FiletValasztott;

begin
  Infocsik.Visible := true;
  Infocsik.Repaint;

  _arcfilenev := TRIM(ArcQuery.FieldByNAme('FILENEV').asString);
  _localpath := _arcdir + '\' + _arcfilenev;
  if not FileExists(_localpath) then
    begin
      _loaded := Arcletoltes(_arcfilenev);
      if not _Loaded then
        begin
          ArcBackGombClick(Nil);
          exit;
        end;
    end;
  Form1.SofficeLeallitas;
  _pcs := _sOffPath + ' ' + _localPath;
  _pacs := pchar(_pcs);
  Form1.WinexecandWait32(_pacs,sw_normal);
  Infocsik.Visible := false;
  ArcBackGombClick(Nil);
end;

function TArchiveForm.Arcletoltes(_remoteFile: string): boolean;

begin
   result := False;
  if not Form1.Vaninternet then
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

  _alKonyvtar := '\KORLEVEL\' + _remotenev;
  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_alKonyvtar));
  if _sikeres then
      result := FTPGetFile(_hFtp,pchar(_remotefile),pchar(_localpath),False,0,
                           FTP_TRANSFER_TYPE_BINARY,0);

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);
end;


procedure TARCHIVEFORM.ARCRACSDblClick(Sender: TObject);
begin
  FiletValasztott;
end;

procedure TARCHIVEFORM.ARCRACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  FiletValasztott;
end;

end.
