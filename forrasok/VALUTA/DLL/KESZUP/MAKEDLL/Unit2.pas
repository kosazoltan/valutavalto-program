unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Wininet, Strutils, IBTable, dateutils;

type
  TKESZLETBEKULDO = class(TForm)
    KILEPO       : TTimer;
    IBQuery      : TIBQuery;
    IBDBASE      : TIBDatabase;
    IBTRANZ      : TIBTransaction;
    IBTabla      : TIBTable;
    TradeQUERY   : TIBQuery;
    TradeDBASE   : TIBDatabase;
    TradeTRANZ   : TIBTransaction;
    ValutaQUERY  : TIBQuery;
    ValutaTABLA  : TIBTable;
    ValutaDBASE  : TIBDatabase;
    ValutaTRANZ  : TIBTransaction;
    ValdataTABLA : TIBTable;
    ValdataQUERY : TIBQuery;
    ValdataDBASE : TIBDatabase;
    ValdataTRANZ : TIBTransaction;
    Label1       : TLabel;


    procedure FormActivate(Sender: TObject);
    procedure Adatmeghatarozas;
    procedure KeszletFeliras;
    procedure Napiforgalom;
    procedure Aktualkeszletek;
    function Nulele(_b: byte): string;

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
  _idnem : array[0..26] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
  'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD','PLN','RON',
  'RSD','RUB','SEK','THB','TRY','UAH','USD');

  _hufindex : byte = 12;

  _kesziro: File of Byte;

  _bytetomb: array[1..4096] of byte;
  _vetel,_eladas,_vetelft,_eladasft,_keszlet,_keszletft: array[0..26] of real;


  _remoteFile,_localPath,_pcs,_filenev,_filePath,_minta,_keforFile,_keforPath: string;
  _sorveg: string = chr(13)+chr(10);

  _findData    : WIN32_FIND_DATA;
  _maildir : string = 'c:\valuta\mail';
  _pillkesz : string = '\PILLKESZ';
//  _pillkesz : string = '\PILLTEMP';

  _height,_width,_top,_left: word;
  _host,_userid,_ftppassword,_homepenztarszam,_aktdnem,_ptars: string;
  _bizonylat,_tipus,_megnyitottnap,_valutanem,_elojel,_farok: string;
  _btTablanev,_foglalodnem,_delfile: string;
  _gepfunkcio,_ftpport,_ertektar,_kellmatrica,_mResult,_qq,_pp,_ddb,_code: integer;
  _sVetel,_sEladas,_aktkesz,_aktelsz,_aktertek,_aktbevet: integer;
  _aktbertek,_aktkiad,_aktkertek,_bevet,_kiad,_elszarf,_ftertek: integer;
  _kev,_kho,_knap,_kora,_kperc,_homept,_xx,_valdarab: word;
  _wusd,_whuf,_afaft,_tradekeszlet,_bankjegy: real;
  _aktkeszlet,_aktkeszletft,_foglalokeszlet: real;
  _aktvetel,_aktvetelft,_akteladas,_akteladasft,_aktkezdij,_zaro: real;
  _ftIndex: byte = 12;

  _hNet,_Hftp,_hSearch: HINTERNET;
 

Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll';
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

  _top  := 0;
  _left := 0;

  if (_height>768) then _top := trunc((_height-768)/2);
  If (_width>1024) then _left := trunc((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Width  := 1024;
  Height := 24;

  Label1.Repaint;

  // FTP adatok beállítása:


  _userid      := 'ebc-10%';
  _ftppassword := 'klc+45%';
  _ftpport     := 21100;

  logirorutin(pchar('Készlet és forgalom beküldés indul'));


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
      _gepfunkcio  := FieldByName('GEPFUNKCIO').asInteger;
      _ertektar    := FieldByName('ERTEKTAR').asInteger;
      _kellmatrica := FieldByName('KELLMATRICA').asInteger;
      _megnyitottnap := FieldByName('MEGNYITOTTNAP').asstring;
      _host        := trim(FieldByNAme('HOST').ASsTRING);
      Close;
    end;

  // Kiolvassa a pénztár számát:

  _pcs := 'SELECT * FROM PENZTAR' + _sorveg;
  with ValutaQuery do
    begin
      CLose;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _homePenztarszam := trim(FieldByName('PENZTARKOD').asString);
      Close;
    end;

  ValutaDbase.close;

  val(_homepenztarszam,_homept,_code);
  if _code<>0 then _homept := 0;

  // -------------- A beküldendõ adatok meghatározása --------------------------

  Adatmeghatarozas;

  // ---------------------------------------------------------------------------
  // A készleteket kiirjuk a 'Valuta/Mail/Pk' + [HOME] . [ERTEKTAR] FILE-BA

  KeszletFeliras;

  //  A készleteket beküldi a server PILLKESZ könyvtárába:

   _mresult := 1;
  IF not KeszletBekuldes then _mResult := 2;


  logirorutin(pchar('A készletbeküldés siker kódja: '+inttostr(_mResult)));
  // Végül kilép a programból

  Kilepo.Enabled := True;
end;



// ==========================================================================$$$
                     procedure TKESZLETBEKULDO.KeszletFeliras;
// =============================================================================


var _bkks: integer;
    _bkkss: string;


begin

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _bkks := fieldByNAme('BKKS').asInteger;
      close;
    end;
  Valutadbase.close;

  inc(_bkks);
  if _bkks>99 then _bkks := 1;
  _bkkss := nulele(_bkks);

  _pcs := 'UPDATE HARDWARE SET BKKS=' + inttostr(_bkks);
  ValutaParancs(_pcs);

//  MemoTabla.Lines.Add('Az adatok felirása a MAIL könyvtárba');


  // Az idökódszám meghatározása:

  _kev := yearof(date)-2000;
  _kho := monthof(date);
  _knap:= dayof(date);

  _kora := hourof(Now);
  _kperc:= minuteof(Now);

  _bytetomb[1] := _kev;
  _bytetomb[2] := _kho;
  _bytetomb[3] := _knap;
  _bytetomb[4] := _kora;
  _bytetomb[5] := _kperc+100;
  _bytetomb[6] := _vdb;

  _qq := 0;
  _pp := 7;

  while _qq<_vdb do
    begin
      _aktdnem      := _iDnem[_qq];

      _aktkeszlet   := _keszlet[_qq];
      _aktkeszletft := _keszletFt[_qq];

      _aktvetel     := _vetel[_qq];
      _aktvetelFt   := _vetelFt[_qq];

      _akteladas    := _eladas[_qq];
      _akteladasft  := _eladasft[_qq];

      DnemKod(_aktdnem);

      Keszletkod(_aktkeszlet);
      Keszletkod(_aktkeszletft);
      Keszletkod(_aktvetel);
      Keszletkod(_aktvetelft);
      Keszletkod(_akteladas);
      Keszletkod(_akteladasft);

      inc(_qq);
    end;

  Keszletkod(_wUsd);
  KeszletKod(_wHuf);
  Keszletkod(_afaFt);

  Keszletkod(_aktkezdij);
  KeszletKod(_tradekeszlet);

  KeszletKod(_foglaloKeszlet);
  DnemKod(_foglalodnem);

  {
    KeszletKod(_hufkeszlet);
    Keszletkod(_valkeszlet);
    Keszletkod(_foglalokeszlet);

  }

  _bytetomb[_pp]   := 255;
  _bytetomb[_pp+1] := 255;
  _bytetomb[_pp+2] := 255;

  _pp := _pp+2;

  if not DirectoryExists(_mailDir) then CreateDir(_maildir);
  _ptars := nul3(_homept);

  _KeforFile := 'PK' + _ptars + _bkkss +  '.' + inttostr(_ertektar);
  _keforPath := _maildir + '\' + _keforFile;

  // ------------------ A KEFOR file összeállitása és rögzitése ----------------

  AssignFile(_kesziro,_keforpath);
  Rewrite(_kesziro);
  Blockwrite(_kesziro,_bytetomb,_PP);
  CloseFile(_kesziro);

// MemoTabla.Lines.Add('Az adatközlés rögzitve '+ _keforFile +' nevü file-ba');

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

//  MemoTabla.Lines.add('BELÉPEK A PILLKESZ KÖNYVTÁRBA');

  result :=  FTPSetCurrentDirectory(_hFTP,pchar(_pillkesz));

  if not result then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);

//      Memotabla.Lines.add('NEM TUDOK BELÉPNI A PILLKESZ KÖNYVTÁRBA');

      Exit;
    end;

  _minta := 'PK' + _ptars + '*.' + inttostr(_ertektar);
  _hSearch := FTPFindFirstFile(_hFTP,PCHAR(_minta),_findData,0,0);
  if _hSearch<>Nil then
    begin
      _delfile := _FindData.cFileName;
      FtpDeleteFile(_hftp,PCHAR(_delfile));
    end;  

  // ---------------------------------------------------------------------------

//  Memotabla.Lines.add('AZ ADATOK BEKÜLDÉSE A SZERVERRE');

  result := FTPPutFile(_hFTP,pchar(_KEFORPath),pchar(_keforFile),FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  Deletefile(_keforPath);

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

  result := -1;
  _y := 0;
  while _y < _vdb  do
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
  ibdbase.connected := True;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  Ibtranz.Commit;
  ibdbase.close;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ==========================================================================$$$
                procedure TKeszletBekuldo.AdatMeghatarozas;
// =============================================================================


begin

  Napiforgalom;
  AktualKeszletek;

  _pcs := 'SELECT * FROM WUAFAADATOK';
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _wusd := FieldByName('WUDOLLARKESZLET').asFloat;
      _whuf := FieldByName('WUFORINTKESZLET').asFloat;
      _afaft:= FieldByName('OSSZESAFAKESZLET').asFloat;
    end;
  ValutaQuery.Close;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM FOGLALOKESZLET';
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _valdarab := FieldByName('VALDARAB').asInteger;
      _foglaloKeszlet := FieldByNAme('K0').asFloat;
      _foglalodnem := trim(FieldByName('V0').AsString);
      Close;
    end;

  if _valdarab=0 then
    begin
      _foglalokeszlet := 0;
      _foglalodnem := 'HUF';
    end;

  // ---------------------------------------------------------------------------

  _tradekeszlet := 0;
  if (_kellMatrica=1) or (_gepfunkcio=2) then
    begin
      if _gepfunkcio=1 then
        begin
          tradedbase.close;
          tradeDbase.DatabaseName := 'c:\valuta\database\trade.fdb';
          tradeDbase.Connected := True;
          with TradeQuery do
            begin
              Close;
              sql.Clear;
              Sql.Add('SELECT * FROM PARAMETERS');
              Open;
              _tradeKeszlet := FieldByName('PILLALLAS').asInteger;
              Close;
            end;
          Tradedbase.close;
        end;

      if _gepfunkcio=2 then
        begin
          _pcs := 'SELECT * FROM MATDATA';
          ValutaDbase.Connected := true;
          with ValutaQuery do
            begin
              Close;
              sql.Clear;
              sql.Add(_pcs);
              Open;
              _tradekeszlet := FieldByName('AKTKESZLET').asInteger;
            end;
          ValutaQuery.close;
          ValutaDbase.close;
        end;
    end;
end;

// =============================================================================
                    procedure TKeszletbekuldo.Napiforgalom;
// =============================================================================

var i: integer;

begin
   for i := 0 to _vdb do
     begin
       _vetel[i]   := 0;
       _vetelft[i] := 0;
       _eladas[i]  := 0;
       _eladasft[i]:= 0;
     end;

   if _gepfunkcio=2 then exit;

   // --------------------------------------------------------------------------
   
  _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  ValutaDbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      with ValutaQuery do
        begin
          _bizonylat := FieldbyName('BIZONYLATSZAM').asString;
          _valutanem := FieldByName('VALUTANEM').asString;
          _bankjegy  := FieldByName('BANKJEGY').asInteger;
          _ftertek   := Fieldbyname('FORINTERTEK').asInteger;
          _elojel    := FieldByNAme('ELOJEL').asstring;
        end;

      _tipus := leftstr(_bizonylat,1);
      _xx := ScanDnem(_valutanem);

      if _tipus='V' then
        begin
          _vetel[_xx]       := _vetel[_xx] + _bankjegy;
          _vetelft[_xx]     := _vetelft[_xx] + _ftertek;
          _eladas[_ftindex] := _eladas[_ftIndex] + _ftertek;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx]     := _eladas[_xx] + _bankjegy;
          _eladasft[_xx]   := _eladasft[_xx] + _ftertek;
          _vetel[_ftindex] := _vetel[_ftIndex] + _ftertek;
        end;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  _farok := midstr(_megnyitottnap,3,2)+midstr(_megnyitottnap,6,2);
  _btTablanev := 'BT' + _farok;


  _pcs := 'SELECT * FROM ' + _bttablanev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (DATUM='+chr(39)+_megnyitottnap + chr(39)+')';

  ValdataDbase.connected := True;
  with ValdataQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValdataQuery.eof do
    begin
      with ValdataQuery do
        begin
          _bizonylat := FieldbyName('BIZONYLATSZAM').asString;
          _valutanem := FieldByName('VALUTANEM').asString;
          _bankjegy  := FieldByName('BANKJEGY').asInteger;
          _ftertek   := Fieldbyname('FORINTERTEK').asInteger;
          _elojel    := FieldByNAme('ELOJEL').asstring;
        end;

      _tipus := leftstr(_bizonylat,1);
      _xx := ScanDnem(_valutanem);

      if _tipus='V' then
        begin
          _vetel[_xx]       := _vetel[_xx] + _bankjegy;
          _vetelft[_xx]     := _vetelft[_xx] + _ftertek;
          _eladas[_ftindex] := _eladas[_ftIndex] + _ftertek;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx]     := _eladas[_xx] + _bankjegy;
          _eladasft[_xx]   := _eladasft[_xx] + _ftertek;
          _vetel[_ftindex] := _vetel[_ftIndex] + _ftertek;
        end;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  Valdatadbase.close;
end;

// =============================================================================
              procedure TKeszletBekuldo.AktualKeszletek;
// =============================================================================

var i:integer;
    _elszamarf,_ertek: real;

begin

  for i := 0 to _vdb do
    begin
      _keszlet[i] := 0;
      _keszletft[i] :=0;
    end;

  _Pcs := 'SELECT * FROM ARFOLYAM';

  valutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
    end;

  _aktkezdij := 0;
  while not ValutaQuery.eof do
    begin
      _valutanem := ValutaQuery.FieldByName('VALUTANEM').asstring;
      _zaro := Valutaquery.FieldbyName('ZARO').asInteger;
      _elszamarf := ValutaQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      _ertek := trunc(_elszamarf*_zaro/100);
      if _valutanem='JPY' then _ertek := trunc(_ertek/100);

      _xx := ScanDnem(_valutanem);
      if _xx<_vdb then
        begin
          _keszlet[_xx] := _zaro;
          _keszletft[_xx] := _ertek;
        end;

      Valutaquery.next;
    end;
  _pcs := 'SELECT * FROM KEZELESIDATA';
  WITH ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktkezdij := FieldByName('AKTKEZELESIDIJ').asInteger;
      close;
    end;

  Valutadbase.close;
end;

function TKeszletBekuldo.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

end.


