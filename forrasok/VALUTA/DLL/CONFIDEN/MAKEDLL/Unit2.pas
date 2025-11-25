unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, DateUtils, Strutils, wininet;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    MEMO: TMemo;
    KULDOGOMB: TBitBtn;
    NOKULDOGOMB: TBitBtn;
    Panel2: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    SERVERQUERY: TIBQuery;
    SERVERDBASE: TIBDatabase;
    SERVERTRANZ: TIBTransaction;
    HARDWAREQUERY: TIBQuery;
    PENZTARQUERY: TIBQuery;


    procedure NOKULDOGOMBClick(Sender: TObject);
    procedure AlapadatBeolvasas;

    function bejelentesBekuldes: boolean;
    function Entertheserver: boolean;
    function Kitkod(_kdatum: string):string;

    procedure KULDOGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _hNet,_hFtp: HINTERNET;

  _s: array[0..254] of string;
  _kodpt,_ptar,_sorkod,_sorlen: byte;
  _iras : file of byte;
  _bytetomb : array[1..16384] of byte;

  _perc,_y,_bytess,_z: word;
  _code: integer;

  _confdir     : string = '\CONF';

  _host: string;

  _userid      : string = 'ebc-10%';
  _ftppassword : string = 'klc+45%';
  _ftpport     : word = 21100;
  _sordarab    : byte;

  _kits,_idkod,_text,_aktsorstring,_aktsor,_ptkod: string;
  _localpath,_remotefile,_megnyitottnap: string;

  _width,_left,_top,_height: word;


function confidentreport: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
              function confidentreport: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.ShowModal;
  Form2.free;
end;



// =============================================================================
            procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  _top := round((_height-390)/2);
  _left := round((_width-810)/2);

  Top := _top;
  Left := _left;

  AlapadatBeolvasas;
  _kits := KitKod(_megnyitottnap);
end;

// =============================================================================
              procedure TForm2.KULDOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _sordarab :=  Memo.Lines.Count;

  _bytetomb[1] := 255-_sordarab;
  _bytetomb[2] := 255-_ptar;

  _y := 1;
  while _y<6 do
    begin
      _bytetomb[_y+2] := 255 - ord(_idkod[_y]);
      inc(_y);
    end;

  _bytess := 8;

  _y := 0;
  while _y<_sordarab do
    begin
      _aktsor := Memo.Lines[_y];
      _sorlen := length(_aktsor);
      _bytetomb[_bytess] := _sorlen;
      inc(_bytess);
      _z := 1;
      while _z<=_sorlen do
        begin
          _bytetomb[_bytess] := 255 - ord(_aktsor[_z]);
          inc(_bytess);
          inc(_z);
        end;
      inc(_y);
    end;
   _bytetomb[_bytess] := 255;
   inc(_bytess);
   _bytetomb[_bytess] := 255;
   inc(_bytess);
   _bytetomb[_bytess] := 255;

  //  -----------------------------------

  randomize;
  _perc := 65 + random(25);

  _remoteFile := 'CONF' + _KITS+ chr(_perc) + '.COF';
  _localPath := 'c:\valuta\out\' + _remoteFile;

  assignFile(_iras,_localPath);
  rewrite(_iras);
  Blockwrite(_iras,_bytetomb,_bytess);
  Closefile(_iras);

  if bejelentesbekuldes then ModalResult := 1
  else Modalresult := 2;

end;

// =============================================================================
                function TForm2.Kitkod(_kdatum: string):string;
// =============================================================================

var _hos,_naps,_evs: string;
    _ev,_honap,_nap: word;

begin
   result := '000';
   if _kdatum='' then exit;

   _evs := leftstr(_kdatum,4);
   _hos := midstr(_kdatum,6,2);
   _naps:= midstr(_kdatum,9,2);

   val(_evs,_ev,_code);
   val(_hos,_honap,_code);
   val(_naps,_nap,_code);

   if (_ev<2000) or (_ev>2036) then exit;

   _ev := _ev - 2000;
   _hos := chr(64+trunc(2*_honap));

   if _nap<10 then _naps := chr(48+_nap)
   else _naps := chr(55+_nap);

   _evs := chr(64+_ev);
   result := _naps + _evs + _hos;
end;

// =============================================================================
                      procedure TForm2.Alapadatbeolvasas;
// =============================================================================

begin
  valutadbase.connected := true;
  with HardwareQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').asString);
      _idKod := trim(FieldByNAme('IDKOD').asString);
      _host := trim(FieldByName('HOST').asString);
      Close;
    end;

  with PenztarQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _ptkod := trim(FieldByNAme('PENZTARKOD').asString);
      Close;
    end;
  Valutadbase.close;

  val(_ptkod,_ptar,_code);
end;


// =============================================================================
               procedure TForm2.NOKULDOGOMBClick(Sender: TObject);
// =============================================================================

begin
 Modalresult := 2;
end;



// ==========================================================================$$$
                   function TForm2.bejelentesBekuldes: boolean;
// =============================================================================

begin
  
  result := False;
  if not EntertheServer then exit;

  // --------- Change directory -----------------

  result :=  FTPSetCurrentDirectory(_hFTP,pchar(_confdir));

  if not result then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  result := FTPPutFile(_hFTP,pchar(_localPath),pchar(_remoteFile),FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);


  if not result then ShowMessage('AZ ADATOK BEKÜLDÉSE SIKERTELEN')
  else ShowMessage('AZ ADATOK SIKERESEN BEKÜLDVE');

  Deletefile(_localPath);

end;


// ==========================================================================$$$
               function TForm2.Entertheserver: boolean;
// =============================================================================

begin
  result := false;

  _hnet := InternetOpen('ConfiSend',
                  INTERNET_OPEN_TYPE_DIRECT,
                  nil,
                  nil,
                  0);

  if _hNet = nil then exit;

  // --------  connect to the server  -----------------

  _hFTP := InternetConnect(_hNet,
                           PChar(_Host),
                           _ftpPort,
                           PChar(_UserId),
                           PChar(_ftpPassword),
                           INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);


  IF _hFTP = nil then
    begin
      InternetCloseHandle(_hNet);
      Exit;
    end;

  result := true;
end;




end.
