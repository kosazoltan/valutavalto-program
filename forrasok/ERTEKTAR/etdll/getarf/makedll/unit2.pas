unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, Buttons,
  ExtCtrls,wininet, strutils, dateutils;

type
  TGetArfolyam = class(TForm)

    IBQuery: TIBQuery;
    IBDbase: TIBDatabase;
    IBTranz: TIBTransaction;
    Shape2: TShape;
    ChangePanel: TPanel;
    changebox: TListBox;
    Shape3: TShape;
    Label4: TLabel;
    ChangeGomb: TBitBtn;
    InditoTimer: TTimer;
    Label1: TLabel;

    procedure AlapAdatBeolvasas;
    procedure FormActivate(Sender: TObject);
    procedure InditoTimerTimer(Sender: TObject);
    procedure AktCurrateTorlese;
    procedure FTPszerverbeBelep;
    procedure ibParancs(_ukaz: string);

    function WCurateBeolvasas: boolean;
    function wCurateFeldolgozas: boolean;
    function Intdekodol(_bs: integer): real;
    function GetCurrate: string;
    function Vaninternet: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Getarfolyam: TGetarfolyam;

  _ELSZARF: array[1..28] of integer;

  _aktcurrate  : string;
  _lastCurrate : string;
  _arfolyamdir : string = '\ARFOLYAM';

  _valnemDarab: integer = 28;
  _valnem:array[1..28] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD','RCH');

   _hNet,_hFTP,_hSearch: HINTERNET;
   _findData: WIN32_FIND_DATA;

   _width,_height,_arfdnemdarab,_ptarszam: word;
   _vaninternet,_qq,_valutadarab,_xx: byte;
   _code: integer;

   _aktelszarf: INTEGER;
   _sikeres: boolean;

   _aktdnem,_pcs,_mondat,_lognev: string;
   _ujwpath: string;

   _sorveg: string = chr(13)+chr(10);

   _ftpPassword : String  = 'klc+45%';
   _ftpPort     : Integer = 21100;
   _host        : String;
   _userId      : String  = 'ebc-10%';

   _bytetomb: array[1..4096] of byte;

   _Olvas: file of byte;
 
function arfolyamletoltes: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
               function arfolyamletoltes: integer; stdcall;
// =============================================================================

begin
  Getarfolyam := TGetarfolyam.Create(Nil);
  result := Getarfolyam.ShowModal;
  Getarfolyam.free;
end;

// =============================================================================
             procedure TGETARFOLYAM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width := screen.Monitors[0].Width;
  _height:= screen.Monitors[0].Height;

  Top := 200 + trunc((_height-313)/2);
  Left:= 250 + trunc((_width-401)/2);

  AlapadatBeolvasas;
  Inditotimer.Enabled := true;
end;


procedure TGetarfolyam.alapadatbeolvasas;
begin
  ibdbase.Connected := True;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT* FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').asString);
      Close;
    end;
  ibdbase.close;
end;

// =============================================================================
           procedure TGetArfolyam.InditoTimerTimer(Sender: TObject);
// =============================================================================

begin
  InditoTimer.Enabled := False;
  _aktcurrate := Getcurrate;

  if not WCurateBeolvasas then
    begin
      Modalresult := 2;
      exit;
    end;

  if not wCurateFeldolgozas then
    begin
      ModalResult := 2;
      exit;
    end;

  _xx := 1;
  while _xx<=28 do
    begin
      _aktdnem    := _valnem[_xx];
      _aktelszarf := _elszarf[_xx];
      if _aktdnem='HUF' then _aktelszarf := 100;

      _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM='+inttostr(_aktelszarf)+_sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+_aktdnem + chr(39);
      ibParancs(_pcs);

      inc(_xx);
    end;

  _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=100'+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+ 'HUF' + chr(39);
  ibParancs(_pcs);

  Modalresult := 1;
end;

// =============================================================================
                  function Tgetarfolyam.GetCurrate: string;
// =============================================================================

var _srec: Tsearchrec;
    _minta : string;

begin
  result := 'NR000000.DAT';
  _minta := 'c:\valuta\arfolyam\NR*.dat';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then result := _srec.name;
  FindClose(_srec);
end;

// =============================================================================
           function TGetarfolyam.Intdekodol(_bs: integer): real;
// =============================================================================

var _b1,_b2,_b3,_b4,_b5: byte;

begin
   _b1 := _bytetomb[_bs];
   _b2 := _bytetomb[_bs+1];
   _b3 := _bytetomb[_bs+2];
   _b4 := _bytetomb[_bs+3];
   _b5 := _bytetomb[_bs+4];

   result := _b5*65536*65536;
   result := result + (_b4*65536*256);
   result := result + (65536*_b3);
   result := result + (256*_b2);
   result := result + _b1;
end;

// =============================================================================
              function TGetarfolyam.wCurateBeolvasas: boolean;
// =============================================================================

begin
  result := False;
  FTPSzerverbeBelep;
  if _hFTP=Nil then exit;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_arfolyamdir));
  if not _sikeres then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  _hSearch := FTPFindFirstFile(_hFTP,'NR*.DAT',_findData,0,0);

  if _hsearch=NIL then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;
  _Lastcurrate := _finddata.cFileName;
  InternetCloseHandle(_hsearch);

  _lastCurrate := uppercase(trim(_lastcurrate));
  if _lastcurrate=_aktcurrate then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

  AktCurrateTorlese;

  _ujwPath := 'C:\ERTEKTAR\ARFOLYAM\' + _lastCurrate;

  RESULT := ftpgetfile(_hftp,pchar(_lastCurrate),pchar(_ujwPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

// =============================================================================
                      procedure TGetarfolyam.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then exit;

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hFTP=nil then   InternetCloseHandle(_hNet);
end;


// =============================================================================
               function TGetArfolyam.wCurateFeldolgozas: boolean;
// =============================================================================

var _kezdet: integer;

begin
  result := False;
  if not FileExists(_UJwPath) then exit;

  Assignfile(_olvas,_ujwPath);
  Reset(_olvas);

  _kezdet := 201;
  seek(_olvas,_kezdet);
  _qq := 1;

  while _qq<=28 do
     begin
       Blockread(_olvas,_bytetomb,45);
       _aktelszarf := round(intDekodol(1));
       _aktdnem := _valnem[_qq];

       if _aktdnem='JPY' then  _aktelszarf := round(_aktelszarf/10);
       _elszarf[_qq] := _aktelszarf;
       inc(_qq);
     end;
  closeFile(_olvas);
  result := true;
end;

// =============================================================================
                 function TGetarfolyam.Vaninternet: boolean;
// =============================================================================

var _dwConnType: integer;

begin
   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;

// =============================================================================
                   procedure Tgetarfolyam.ibParancs(_ukaz: string);
// =============================================================================

begin
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      ExecSql;
    end;

  ibtranz.commit;
  ibdbase.close;
end;

// =============================================================================
                     procedure TGetarfolyam.AktcurrateTorlese;
// =============================================================================

var _minta,_delFile,_delPath: string;
    _srec: TSearchRec;

begin
  _minta := 'C:\VALUTA\ARFOLYAM\NR*.DAT';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _delFile := _srec.Name;
        _delPath := 'c:\valuta\arfolyam\'+_delfile;
        deleteFile(_delPath);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
end;
end.
