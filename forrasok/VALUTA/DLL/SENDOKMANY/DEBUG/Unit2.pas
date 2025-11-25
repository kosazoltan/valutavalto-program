unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  wininet, strutils;

type
  TForm2 = class(TForm)
    ALAPPANEL: TPanel;
    Label1: TLabel;
    MEMO1: TMemo;
    VALUTAQUERY: TIBQuery;
    VALDATAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALDATADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALDATATRANZ: TIBTransaction;
    KILEPO: TTimer;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;


    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure ParaBeolvasas;

    function GetRemoteAddress(_jss: string): string;
    function Getdir(_jpegnev: string): string;
    function VoltezazUgyfel(_usz: integer): boolean;
    function OpenFtp: integer;
    function Getjpgends(_jpgnev: string): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _sRec: TSearchrec;
  _LEFT,_WIDTH,_TOP,_HEIGHT,_sended,_wPlomba: word;
  _vTip,_datum,_farok,_pcs,_ugyfeltipus,_plombaszam,_minta,_kerPath: string;
  _aktjpg,_aktplomba,_sDir,_remotenev,_sourcePath,_evtizes,_remotefdb: string;
  _jogikod,_jpgends,_kertevs: string;
  _sorveg: string = chr(13)+chr(10);

  _siker: boolean;

  _ugyfeldb,_y,_wLen,_docdb: word;
  _recno,_ugyfelszam,_mbSzama,_openOke,_qq: integer;

  _host: string;

  _hFTP,_hNet  : HINTERNET;
  _FINDDATA    : WIN32_FIND_DATA;
  _ftpPassword : string  = 'klc+45%';
  _userId      : String  = 'ebc-10%';
  _ftpPort     : Integer = 21100;

  _ugyfelszamok: array[1..4096] of integer;
  _jpgtomb,_plombatomb: array[1..4096] of string;

function sendokmanyrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                function sendokmanyrutin: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.ShowModal;
  Form2.Free;
end;


// =============================================================================
               procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _left   := round((_width-472)/2);
  _top    := round((_height-352)/2);

  Top := _top;
  Left := _left;
  Repaint;

  ParaBeolvasas;   // _vTIP= 'NAPI' vagy 'HAVI', + _datum

  _kertevs  := leftstr(_datum,4);
  _evtizes  := midstr(_datum,3,2);
  _farok    := _evtizes + midstr(_datum,6,2);

  _remotefdb := _host+':C:\receptor\database\ugyfel'+_evtizes+'.fdb';
  Remotedbase.close;
  RemoteDbase.DatabaseName := _remotefdb;

  Memo1.Lines.Add('DOKUMENTUMOK SZERVERRE MÁSOLÁSA');
  Memo1.Lines.Add('-------------------------------');

  _pcs := 'SELECT * FROM BF'+_farok +_sorveg;
  _pcs := _pcs + 'WHERE ((UGYFELTIPUS='+chr(39)+'N'+chr(39)+') ';
  _pcs := _pcs + 'OR (UGYFELTIPUS='+chr(39)+'J'+chr(39);
  _pcs := _pcs + ')) AND (STORNO=1) AND (PLOMBASZAM>'+chr(39)+'@'+chr(39)+')';

  if _vtip= 'NAPI' then _PCS := _pcs + ' AND (DATUM=' + chr(39)+_datum+chr(39)+')';

  ValdataDbase.connected := True;
   with ValdataQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       _recno := recno;
     end;

  // Nem volt a kért napon egyetlen szkennelés sem !

  if _recno=0 then
    begin
      ValdataQuery.close;
      ValdataDbase.close;
      Memo1.Lines.add('NINCS BEKÜLDENDÕ OKMÁNY !');
      Kilepo.enabled := true;
      exit;
    end;

  // ---------------- Tömbbe gyüjti a képek neveit  ----------------------------

  _docdb    := 0;
  _ugyfeldb := 0;

  while not ValdataQuery.Eof do
    begin
      _ugyfelszam := ValdataQuery.FieldByNAme('UGYFELSZAM').asInteger;
      _ugyfeltipus:= ValdataQuery.FieldByName('UGYFELTIPUS').asString;
      _plombaszam := trim(ValdataQuery.fieldByNAme('PLOMBASZAM').asString);
      _mbszama    := Valdataquery.FieldByNAme('MEGBIZOTT').asInteger;

      _wplomba := length(_plombaszam);
      if _wPlomba<5 then
        begin
          ValdataQuery.Next;
          Continue;
        end;

      if _ugyfeltipus='J' then
        begin
          if leftstr(_plombaszam,4)<>'JOGI' then
            begin
              ValdataQuery.Next;
              Continue;
            end;

          _jogikod := midstr(_plombaszam,5,_wPlomba-4);
          _plombaszam := GetRemoteAddress(_jogikod);
          _ugyfelszam := _mbszama;
        end;

      if length(_plombaszam)<5 then
        begin
          ValdataQuery.next;
          continue;
        end;

      if VoltEzazUgyfel(_ugyfelszam) then
        begin
          ValdataQuery.next;
          Continue;
        end;

      _kerPath := 'c:\valuta\scans\'+ inttostr(_ugyfelszam);

      _minta := _kerPath + '\*.jpg';
      if FindFirst(_minta,faAnyfile,_srec)=0 then
        begin
          repeat;
            _aktjpg := _srec.Name;  // '2103-0.jpg'
            inc(_docdb);
            _jpgTomb[_docdb] := _aktjpg;
            _plombatomb[_docdb] := _plombaszam;
          until FindNext(_srec)<>0;
          Findclose(_srec);
        end;

      _minta := _kerPath + '\*.bmp';
      if FindFirst(_minta,faAnyfile,_srec)=0 then
        begin
          repeat;
            _aktjpg := _srec.Name;  // '2103-0.jpg'
            inc(_docdb);
            _jpgTomb[_docdb] := _aktjpg;
            _plombatomb[_docdb] := _plombaszam;
          until FindNext(_srec)<>0;
          Findclose(_srec);
        end;

      _minta := _kerPath + '\*.pdf';
      if FindFirst(_minta,faAnyfile,_srec)=0 then
        begin
          repeat;
            _aktjpg := _srec.Name;  // '2103-0.jpg'
            inc(_docdb);
            _jpgTomb[_docdb] := _aktjpg;
            _plombatomb[_docdb] := _plombaszam;
          until FindNext(_srec)<>0;
          Findclose(_srec);
        end;
      ValdataQuery.next;
    end;

  ValdataQuery.close;
  ValdataDbase.close;

  // -------------------------------------

  if _docdb=0 then
    begin
      Memo1.lines.add('NINCS BEKÜLDENDÕ OKMÁNY !');
      Kilepo.enabled := True;
      exit;
    end;
  // -------------------------------------

  _openOke := OpenFTP;
  if _openOke=2 then
    begin
      Memo1.lines.add('NEM SIKERÜLT FELTÖLTENI OKMÁNYT');
      Kilepo.enabled := True;
      exit;
    end;

  _qq := 1;
  _sended := 0;
  while _qq<=_docdb do
    begin
      _aktJpg     := _jpgTomb[_qq];            // '1109-0.jpg'
      _aktplomba  := _plombatomb[_qq];         // 'KNEV185'
      _sDir       := Getdir(_aktjpg);          // '1109'
      _jpgEnds    := GetJpgends(_aktjpg);
      _remoteNev  := _aktplomba+_jpgends;   // 'KNEV185@1109-0.JPG'
      _sourcepath := 'c:\valuta\scans\'+_sdir+'\' + _aktjpg;
      if not fileexists(_sourcePath) then
        begin
          inc(_qq);
          continue;
        end;

      Memo1.Lines.add(_remotenev);
      _siker := FtpPutFile(_hFTP,pChar(_sourcepath),pChar(_remoteNev),FTP_TRANSFER_TYPE_BINARY,0);
      if _siker then inc(_sended);
      inc(_qq);
    end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  Memo1.Lines.Add(' ');
  Memo1.Lines.Add(inttostr(_sended)+' szkennelt okmány feltöltve');

  kilepo.enabled := True;

end;


function TForm2.Getjpgends(_jpgnev: string): string;

var _wlen,_pos: integer;

begin
  result := '';
  _wlen := length(_jpgnev);
  _pos := ansipos('-',_jpgnev);
  if _pos>0 then result := midstr(_jpgnev,_pos,_wlen-_pos+1);
end;



// =============================================================================
                procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;

// =============================================================================
                       procedure TForm2.Parabeolvasas;
// =============================================================================

begin
  valutadbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _vTip := trim(fieldByNAme('NEVTABLA').asString);
      _datum := TRIM(Fieldbyname('DATUM').asString);
      close;
    end;
  Valutadbase.close;
end;

// =============================================================================
                   function TForm2.OpenFtp: integer;
// =============================================================================

begin

  Result := 2;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then exit;

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hFTP=nil then
    begin
      InternetCLoseHandle(_hNet);
      exit;
    end;

  _siker :=  FTPSetCurrentDirectory(_hFTP,pchar('\SCANS\'+_kertevs));
  if not _siker then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;
  Result := 1;
end;


// =============================================================================
             function TForm2.VoltezazUgyfel(_usz: integer): boolean;
// =============================================================================

begin

  result := False;
  if _ugyfeldb=0 then
    begin
      _ugyfeldb := 1;
      _ugyfelszamok[1] := _usz;
      exit;
    end;

  _y := 1;
  while _y<=_ugyfeldb do
    begin
      if _ugyfelszamok[_y]=_usz then
        begin
          result := True;
          exit;
        end;
      inc(_y);
    end;

  inc(_ugyfeldb);
  _ugyfelszamok[_ugyfeldb] := _usz;
end;


// =============================================================================
               function TForm2.Getdir(_jpegnev: string): string;
// =============================================================================

var _asc: byte;

begin
  result := '';
  _wlen := length(_jpegnev);
  if _wlen<5 then exit;

  _y := 1;
  while _y<=_wlen do
    begin
      _asc := ord(_jPegnev[_y]);
      if _asc=45 then exit;
      result := result + chr(_asc);
      inc(_y);
    end;
end;

// =============================================================================
          function TForm2.GetRemoteAddress(_jss: string): string;
// =============================================================================

begin
  _pcs := 'SELECT * FROM JOGI WHERE SORSZAM='+_JSS;

  Remotedbase.connected := true;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := fieldByName('MBDATASORSZAM').asString;
      Close;
    end;
  remotedbase.close;
end;


end.
