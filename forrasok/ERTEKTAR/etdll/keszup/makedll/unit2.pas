unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Wininet, Strutils, IBTable, dateutils;

type
  TKESZLETBEKULDO = class(TForm)
    KILEPO: TTimer;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    Panel1: TPanel;


    procedure FormActivate(Sender: TObject);
    procedure KeszletBeolvasas;
    procedure KeszletFeliras;
    procedure Aktualkeszletek;

    procedure Keszletkod(_kk: real);
    procedure DnemKod(_dn: string);
    procedure KILEPOTimer(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    function Nul3(_ptn: integer): string;
    function KeszletBekuldes: boolean;
    function Scandnem(_vnem: string): integer;
    function Entertheserver: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KESZLETBEKULDO: TKESZLETBEKULDO;

  _vdb : byte = 27;
  _idnem : array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
  'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD','PLN','RON',
  'RSD','RUB','SEK','THB','TRY','UAH','USD');

  _hufindex : byte = 13;

  _kesziro: File of Byte;
  _host,_userid,_ftppassword,_ptars: string;
  _ftpport,_zaro,_ertek: integer;

  _megnyitottnap,_homepenztarszam,_aktdnem: string;
  _aktkeszlet,_aktkeszletft: integer;

  _bytetomb: array[1..1024] of byte;
  _keszlet,_keszletft: array[1..27] of integer;
  _ekerkeszlet,_kezdijkeszlet,_mresult,_code,_usdkeszlet,_hufkeszlet: integer;
  _afakeszlet: integer;


  _remoteFile,_localPath,_pcs,_filenev,_filePath,_minta,_keforFile,_keforPath: string;
  _sorveg: string = chr(13)+chr(10);

  _findData : WIN32_FIND_DATA;
  _maildir  : string = 'c:\ERTEKTAR\mail';
  _pillkesz : string = '\PILLKESZ';

  _homept,_qq,_xx: byte;
  _height,_width,_top,_left,_pp: word;
  _hNet,_Hftp: HINTERNET;


function pillkeszletbekuldo: integer; stdcall;

implementation


{$R *.dfm}


// =============================================================================
                    function pillkeszletbekuldo: integer; stdcall;
// =============================================================================

begin
   KeszletBekuldo := TKeszletbekuldo.Create(Nil);
   result := Keszletbekuldo.ShowModal;
   KeszletBekuldo.Free;
end;


// ==========================================================================$$$
             procedure TKESZLETBEKULDO.FormActivate(Sender: TObject);
// =============================================================================

begin

  // Kilépö-timer leállítva:

  Kilepo.Enabled := False;

  // Koordináták beállítása:

  _height:= Screen.Monitors[0].Height;
  _width := Screen.Monitors[0].Width;

  _top := round((_height-41)/2);
  _left := round((_width-185)/2);

  Top  := _top;
  Left := _left;

  Panel1.Visible := true;

  // FTP adatok beállítása:

  _userid      := 'ebc-10%';
  _ftppassword := 'klc+45%';
  _ftpport     := 21100;


 // --------------------------------------------------------------------------
 // Elöször meghatározza a gépfunkciót és értéktárat és a postasorszámot:

  _pcs := 'SELECT * FROM HARDWARE';
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asstring);
      _host := trim(FieldByNAme('HOST').AsString);
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _homePenztarszam := Trim(FieldByNAme('PENZTARKOD').asstring);
      Close;
    end;
  ValutaDbase.close;

  val(_homepenztarszam,_homept,_code);
  if _code<>0 then _homept := 0;

  // -------------- A beküldendõ adatok meghatározása --------------------------

  KeszletBeolvasas;

  // ---------------------------------------------------------------------------
  // A készleteket kiirjuk a 'Valuta/Mail/Pk' + [HOME] . [ERTEKTAR] FILE-BA

  KeszletFeliras;

  //  A készleteket beküldi a server PILLKESZ könyvtárába:

   _mresult := 1;
  IF not KeszletBekuldes then _mResult := 2;

  // Végül kilép a programból

  Kilepo.Enabled := True;
end;



// ==========================================================================$$$
                     procedure TKESZLETBEKULDO.KeszletFeliras;
// =============================================================================

var _kev,_kho,_knap,_kora,_kperc: word;


begin

  // Az idökódszám meghatározása:

  _kev  := yearof(date)-2000;
  _kho  := monthof(date);
  _knap := dayof(date);
  _kora := hourof(Now);
  _kperc:= minuteof(Now);

  _bytetomb[1] := _kev;
  _bytetomb[2] := _kho;
  _bytetomb[3] := _knap;
  _bytetomb[4] := _kora;
  _bytetomb[5] := _kperc;
  _bytetomb[6] := _vdb; //27

  _qq := 1;
  _pp := 7;

  while _qq<=27 do
    begin
      _aktdnem      := _iDnem[_qq];

      _aktkeszlet   := _keszlet[_qq];
      _aktkeszletft := _keszletFt[_qq];

      DnemKod(_aktdnem);

      Keszletkod(_aktkeszlet);
      Keszletkod(_aktkeszletft);
      Keszletkod(0);
      Keszletkod(0);
      Keszletkod(0);
      Keszletkod(0);

      inc(_qq);
    end;

  Keszletkod(_Usdkeszlet);
  KeszletKod(_HufKeszlet);
  Keszletkod(_afakeszlet);

  Keszletkod(_kezdijkeszlet);
  KeszletKod(_ekerkeszlet);

  KeszletKod(0);
  DnemKod('XXX');

  _bytetomb[_pp]   := 255;
  _bytetomb[_pp+1] := 255;
  _bytetomb[_pp+2] := 255;

  _pp := _pp+2;

  if not DirectoryExists(_mailDir) then CreateDir(_maildir);
  _ptars := nul3(_homept);

  _KeforFile := 'PK' + _ptars+ '.' + inttostr(_homept);
  _keforPath := _maildir + '\' + _keforFile;

  // ------------------ A KEFOR file összeállitása és rögzitése ----------------

  AssignFile(_kesziro,_keforpath);
  Rewrite(_kesziro);
  Blockwrite(_kesziro,_bytetomb,_PP);
  CloseFile(_kesziro);
end;

// ==========================================================================$$$
           function TKeszletBekuldo.Nul3(_ptn: integer): string;
// ==========================================================================$$$

begin
  result := inttostr(_ptn);
  while length(result)<3 do result := '0' + result;
end;


// ==========================================================================$$$
                   function TKESZLETBEKULDO.KeszletBekuldes: boolean;
// =============================================================================



begin


  result := False;
  if not EntertheServer then exit;

  // --------- Change directory -----------------

  result :=  FTPSetCurrentDirectory(_hFTP,pchar(_pillkesz));

  if not result then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  result := FTPPutFile(_hFTP,pchar(_KEFORPath),pchar(_keforFile),FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  Deletefile(_keforPath);
  
  result := True;

end;


// ==========================================================================$$$
               function TKeszletBekuldo.Entertheserver: boolean;
// =============================================================================

begin
  result := false;

  _hnet := InternetOpen('QuantySend',
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


// =========================================================================$$$$
                       procedure TKESZLETBEKULDO.DnemKod(_dn: string);
// =============================================================================

var _d1,_d2,_d3,_b1,_b2: byte;

begin
  _d1 := ord(_dn[1]);
  _d2 := ord(_dn[2]);
  _d3 := ord(_dn[3]);

  asm
    push eax
    push ebx

    mov al,_d1
    and al,31
    mov cl,2
    shl al,cl

    mov ah,_d2
    and ah,31
    mov cl,3
    shr ah,cl
    or al,ah

    mov bl,_d2
    mov cl,5
    shl bl,cl

    mov bh,_d3
    and bh,31
    or bl,bh

    mov _b1,al
    mov _b2,bl

    pop ebx
    pop eax
  end;

  _bytetomb[_pp] := _b1;
  _byteTomb[_pp+1] := _b2;
  _pp := _pp + 2;
end;

// ==========================================================================$$$
                 procedure TKESZLETBEKULDO.Keszletkod(_kk: real);
// =============================================================================


var _hhi,_hlo,_hi,_lo: byte;

begin
  _hhi := trunc(_kk/16777216);
  _kk := _kk - (16777216*_hhi);
  _hlo := trunc(_kk/65536);
  _kk := _kk -(65536*_hlo);
  _hi := trunc(_kk/256);
  _lo := trunc(_kk - (256*_hi));
  _bytetomb[_pp] := _lo;
  _bytetomb[_pp+1] := _hi;
  _bytetomb[_pp+2] := _hlo;
  _bytetomb[_pp+3] := _hhi;
  _pp := _pp + 4;
end;


// ==========================================================================$$$
           procedure TKESZLETBEKULDO.kilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;


// ==========================================================================$$$
         function TKeszletbekuldo.Scandnem(_vnem: string): integer;
// =============================================================================


var _y: integer;

begin

  result := 0;
  _y := 1;
  while _y <= _vdb  do
    begin
      if _iDnem[_y]=_vNem then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;


// ==========================================================================$$$
           procedure TKeszletbekuldo.ValutaParancs(_ukaz: string);
// =============================================================================


begin
  Valutadbase.connected := True;
  if Valutatranz.InTransaction then Valutatranz.Commit;
  Valutatranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  Valutatranz.Commit;
  Valutadbase.close;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ==========================================================================$$$
                procedure TKeszletBekuldo.KeszletBeolvasas;
// =============================================================================

begin

  AktualKeszletek;

  _pcs := 'SELECT * FROM WUAFAADATOK';
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _usdkeszlet := FieldByName('USDKESZLET').asInteger;;
      _hufkeszlet := FieldByName('HUFKESZLET').asInteger;
      _afakeszlet := FieldByName('AFAKESZLET').asInteger;
    end;
  ValutaQuery.Close;

  // ---------------------------------------------------------------------------

  _ekerkeszlet   := 0;
  _kezdijkeszlet := 0;

  _pcs := 'SELECT * FROM EKERDATA';
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _ekerkeszlet := FieldByName('ZARO').asInteger;
      CLOSE;
      sql.clear;
      sql.add('SELECT * FROM KEZDIJDATA');
      Open;
      _kezdijkeszlet := FieldByName('ZARO').asInteger;
      Close;
    end;
  ValutaQuery.close;
  ValutaDbase.close;
end;


// =============================================================================
              procedure TKeszletBekuldo.AktualKeszletek;
// =============================================================================

var i: byte;
    _elszamarf: integer; 

begin

  for i := 1 to 27 do
    begin
      _keszlet[i] := 0;
      _keszletft[i] :=0;
    end;

  _Pcs := 'SELECT * FROM ARFOLYAM'+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM<>'+chr(39)+'EUA'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';


  valutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
    end;

  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.FieldByName('VALUTANEM').asstring;
      _zaro      := Valutaquery.FieldbyName('ZARO').asInteger;
      _elszamarf := ValutaQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      _ertek     := trunc(_elszamarf/100*_zaro);

      if _aktdnem='JPY' then _ertek := trunc(_ertek/100);

      _xx := ScanDnem(_aktdnem);
      if _xx>0 then
        begin
          _keszlet[_xx]   := _zaro;
          _keszletft[_xx] := _ertek;
        end;

      Valutaquery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

end.


