unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Wininet, strutils;

type
  TForm1 = class(TForm)
    MEMO: TMemo;
    IDOZITO: TTimer;
    Panel1: TPanel;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure FTPszerverbeBelep;
    procedure Arfolyamkikuldes;
    procedure ByteFileiras;
    procedure CloseComPort;
    procedure sendByteFile;
    procedure ValsorBeiro(_vsor: string);


    function GetaktRatesName: string;
    function Arfolyamletoltes: boolean;
    function Vaninternet: boolean;
    function CtrlSummaControl: boolean;
    function NRbedolgozas: boolean;
    function Intdekodol(_bs: string): integer;
    function OpenCOMPort: Boolean;
    function SetupCOMPort: Boolean;
    function arfform(_int: integer): string;
    procedure IDOZITOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _portname: pchar;
  _aktratesName,_aktRatesPath,_newRatesName,_newRatesPath: string;
  _sikeres: boolean;
  _arfolyamdir: string = '\ARFOLYAM';
  _hiba: integer;

  COmfile: THandle;

  _hNet,_hFTP,_hSearch: HINTERNET;
  _findData: WIN32_FIND_DATA;

  _byteswritten: dword;
  _utbytess,_byteFileHossz: word;

  _ftpPassword : String  = 'klc+45%';
  _ftpPort     : Integer = 21100;
  _host        : String  = '185.43.207.99';
  _userId      : String  = 'ebc-10%';

//  _plusText : string = 'ZÁLOG - ÉKSZER - MÛTÁRGY - CHANGE : ';
//  _plusbyte : byte = 36;


  _bytetomb: array[1..128000] of byte;

   _dnemDarab: integer = 27;
  _dnem:array[1..27] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD');
  _vetel,_eladas: array[1..27] of integer;


  _xdnem: array[1..5] of string = ('CHF','EUR','GBP','HRK','USD');
  _xSors: array[1..5] of byte = (4,1,3,12,2);
  _xVetel,_xEladas: array[1..5] of integer;
  _xValutaDarab: byte = 5;
  _zz,_aktsors: byte;

  _aktdnem: string;
  _aktvetel,_akteladas: integer;
  _compath: string = 'C:\litenews\v4.txt';


implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);
begin
  _portname:= pchar('COM1:');
  Memo.clear;
  Memo.lines.Clear;
  Repaint;


  _aktRatesName := GetAktRatesName;
  if _aktRatesName<>'' then
    begin
      _aktRatesPath := 'c:\litenews\'+_aktratesName;
      Sysutils.DeleteFile(_aktRatesPath);
    end;

  while not ArfolyamLetoltes do
    begin
      Memo.Lines.Add('Nem sikerült az árfolyamkiküldés. Várok 5 percet');
      Sleep(300000);
    end;

  Memo.Lines.Add('Most kiküldöm az árfolyamokat a fényújságra');
  ArfolyamKikuldes;
  Memo.Lines.add('Inditom az idözítõt');
  Idozito.Enabled := True;

end;

function TForm1.GetaktRatesName: string;

var _minta: string;
    _srec: TSearchRec;


begin
  result := '';
  _minta := 'c:\litenews\NR*.dat';
  if FindFirst(_minta, faAnyFile,_srec) = 0 then result := _srec.name;
  FindClose(_srec);
end;

// =============================================================================
                   function TForm1.Arfolyamletoltes: boolean;
// =============================================================================

begin

  result := False;
  {
  if not Vaninternet then
    begin
      Memo.Lines.add('Nincs internet - befejezem az árfolyamletöltést');
      exit;
    end;
  }

  Memo.Lines.add('Megpróbálok a szerverre lépni');
  FTPSzerverbeBelep;
  if _hFTP=Nil then
    begin
      Memo.Lines.add('Nem sikerült a szerverre lépni - nincs árfolyamletöltés');
      exit;
    end;

  // --------- Change directory -----------------

  Memo.Lines.add('Belépek az árfolyam könyvtárban ...');

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_arfolyamdir));
  if not _sikeres then
    begin
      Memo.Lines.add('Nem tudtam bellépni az árfolyam könyvtárba !');
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  Memo.Lines.add('Keresem az NR*.dat nevú árfolyamfile-t');
  _hSearch := FTPFindFirstFile(_hFTP,'NR*.DAT',_findData,0,0);
  if _hsearch=NIL then
    begin
      Memo.Lines.add('Nem találtam NR*.DAT file-t az ARFOLYAM könyvtárban');
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

  _newRatesName := _finddata.cFileName;
  Memo.Lines.Add('Megtaláltam a '+_newRatesName+' nevû árfolyamfile-t');

  InternetCloseHandle(_hsearch);

  _newRatesName := uppercase(trim(_newRatesName));
  _aktRatesName := getAktRatesName;
  Memo.Lines.add('Az utoljára kiküldött árfolyamfile neve: '+_aktRatesName);

  if _newratesName=_aktRatesName then
    begin
      Memo.Lines.add('Nem változott az árfolyamfile neve - nincs új árfolyam');
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;


  if _aktratesName<>'' then
    begin
      _aktRatesPath := 'c:\LiteNews\' + _aktRatesName;
      Sysutils.DeleteFile(_aktRatesPath);
      Memo.Lines.add('Töröltem '+ _aktRatesPath + ' file-t !');
    end;

  _newRatesPath := 'c:\liteNews\' + _newRatesName;

  Memo.Lines.Add('Megpróbálom letölteni '+_newratesPath+' nevû file-t');

  _sikeres := ftpgetfile(_hftp,pchar(_newRatesName),pchar(_newRatesPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  if _sikeres then
    begin
      Memo.Lines.add('Sikeresen letöltöttem a '+_newRatesPath+' nevû file-t');
      if not CtrlSummaControl then
         begin
           Memo.Lines.add('Hibás a file summakontrolja - törlöm !');
           if FileExists(_newRatesPath) then DeleteFile(_newRatesPath);
           exit;
         end;
    end else
    begin
       Memo.Lines.Add('Nem sikerült letölteni az új árfolyamfile-t');
      _hiba := GetLastError();
      exit;
    end;

  Memo.Lines.add('Sikeresen letöltöttem a '+_newRatesPath+' nevû file-t');
  Result := NrBedolgozas;
end;

// =============================================================================
                 function TForm1.Vaninternet: boolean;
// =============================================================================

var
    _dwConnType: integer;

begin
   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;

// =============================================================================
                      procedure TForm1.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  Memo.Lines.Add('Fellépek az internetre ...');
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      Memo.Lines.Add('Nem tudok fellépni az internetre !');
      Exit;
    end;

   Memo.Lines.add('Belépek a központi szerverre ...');

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------


  if _hFTP=nil then
    begin
      Memo.Lines.add('A központi sterver nem érhetõ el !');
      InternetCloseHandle(_hNet);
    end;
end;

// =============================================================================
                 function TForm1.CtrlSummaControl: boolean;
// =============================================================================

var _sByte,_fhossz: integer;
    _olvas: File of byte;

begin
  Result := False;
  if not FileExists(_newRatesPath) then exit;

  AssignFile(_olvas,_newRatesPath);
  Reset(_olvas);

  _fHossz := FileSize(_olvas);
  if _fhossz<>66138 then
    begin
      CloseFile(_olvas);
      exit;
    end;

  Seek(_olvas,(_fhossz-3));

  BlockRead(_olvas,_bytetomb,3);
  CloseFile(_olvas);

  _sByte := _bytetomb[1]+_bytetomb[2]+_bytetomb[3];
  if _sByte=765 then Result := true;
end;

// =============================================================================
             function TForm1.NRbedolgozas: boolean;
// =============================================================================

var _cs,_vss,_z,i: byte;
    _bpoint,_v,_e: integer;
    _vs,_nrp: string;
    _pp : word;

    _vv,_ee: array[1..5] of integer;
    _olvas: File of byte;

begin
  Memo.Lines.add(_newRatesPath+' nevû file feldolgozása indul');

  result := False;
  _nrp := _newRatesPath;

  AssignFile(_olvas,_nrp);
  Reset(_olvas);
  Blockread(_olvas,_bytetomb,1);
  if _bytetomb[1]<>15 then
    begin
      Memo.Lines.add('Az árfolyamfile verziószáma nem 15 - igy nem jó');
      closefile(_olvas);
      exit;
    end;

  Blockread(_olvas,_bytetomb,200);

  _cs := _bytetomb[153];
  Memo.Lines.add('A pénztár csoportszáma: '+inttostr(_cs));

  _bpoint := 201+trunc((_cs-1)*1221);


  reset(_olvas);
  seek(_olvas,_bpoint);
  Blockread(_olvas,_bytetomb,1221);
  CloseFile(_olvas);

  _vss := 1;
  _pp := 1;
  while _vss<=27 do
    begin
      _z := 5;
      while _z<10 do
        begin
          _vv[_z-4] := _bytetomb[_pp+_z];
          _ee[_z-4] := _bytetomb[_pp+_z+5];
          inc(_z);
        end;

      _vs := '';
      for i := 1 to 5 do _vs := _vs + chr(_vv[i]);
      _v := intdekodol(_vs);

      _vs := '';
      for i := 1 to 5 do _vs := _vs + chr(_ee[i]);
      _e := intDekodol(_vs);

      _vetel[_vss] := _v;
      _eladas[_vss]:= _e;

      inc(_vss);
      _pp := _pp+45;
    end;

  Memo.Lines.Add('A 27 valuta árfolyamát bedolgoztam');

  // --------------------------------------------------------

  _zz := 1;
  while _zz<=_xValutaDarab do
    begin
      _aktsors     := _xSors[_zz];
      _aktdnem     := _dnem[_aktsors];
      _aktvetel    := _vetel[_aktsors];
      _akteladas   := _eladas[_aktsors];

      Memo.Lines.add(_aktdnem+': '+inttostr(_aktvetel)+'/'+inttostr(_akteladas));

      _xvetel[_zz] := _aktvetel;
      _xEladas[_zz]:= _akteladas;
      inc(_zz);
    end;

  Memo.Lines.add(inttostr(_xvalutadarab)+' darab valuta árfolyamai betöltve');
  result := True;

end;

// =============================================================================
           function TForm1.Intdekodol(_bs: string): integer;
// =============================================================================

var _lo,_hi,_hlo: byte;

begin
   _lo := ord(_bs[1]);
   _hi := ord(_bs[2]);
   _hlo:= ord(_bs[3]);

   result := trunc(65535*_hlo)+trunc(256*_hi)+_lo;
end;

procedure TForm1.Arfolyamkikuldes;

begin
  if fileExists(_compath) then Sysutils.DeleteFile(_compath);

  ByteFileIras;

  if not OpenComport then
    begin
      ShowMessage('Nem sikerült megnyitni a COM3 portot !');
      Application.terminate;
      Exit;
    end;

  if not SetupComport then
    begin
      CloseComport;
      ShowMessage('Nem sikerült beállítani a COM3 portot !');
      Application.Terminate;
      Exit;
    end;

  SendBytefile;

//  Sendtext(_initsor);
//  SzovegKikuldo;
//  Sendtext(_endchar);

  CloseComport;
end;

// =============================================================================
                      procedure TForm1.ByteFileIras;
// =============================================================================

var _2szokoz,_valsor: string;
    _valss: byte;
    _IRAS: File of byte;

begin
  _2szokoz := chr(32)+chr(32);
  _bytetomb[1] := 21;
  _bytetomb[2] := 18;
  _bytetomb[3] := 5;

//  _bytetomb[4] := 92;    // '\'
//  _bytetomb[5] := 70;    // 'F'
//  _bytetomb[6] := 83;    // 'S'
//  _bytetomb[7] := 48+_speed;  // sebesség '0'-'9'

//   _y := 1;
//   while _y<=36 do
//     begin
//       _betu := ord(_plusText[_y]);
//       _bytetomb[3+_y] := _betu;
//       inc(_y);
//     end;

  _utbytess := 3;
  _valss := 1;
  while _valss<=_xValutaDarab do
    begin
      _aktdnem := _xdnem[_valss];
      _aktvetel := _xvetel[_valss];
      _akteladas := _xEladas[_valss];
      _valsor := _aktdnem+': '+  arfform(_aktvetel)+'/'+arfform(_akteladas);
      Valsorbeiro(_valsor);
      inc(_valss);
    end;

  inc(_utbytess);

  _bytetomb[_utbytess] := 254;
  _byteFileHossz := _utbytess;

  AssignFile(_iras,_comPath);
  Rewrite(_iras);
  Blockwrite(_iras,_bytetomb,_bytefileHossz);
  CloseFile(_iras);
end;

// =============================================================================
                  function TForm1.OpenCOMPort: Boolean;
// =============================================================================

var
   DeviceName: array[0..80] of Char;

begin
    { First step is to open the communications device for read/write.
      This is achieved using the Win32 'CreateFile' function.
      If it fails, the function returns false.

      Wir versuchen, COM zu öffnen.
      Sollte dies fehlschlagen, gibt die Funktion false zurück.
    }
  // StrPCopy(DeviceName, 'COM2:');

   StrCopy(DeviceName,_portName);
   ComFile := CreateFile(DeviceName,
     GENERIC_READ or GENERIC_WRITE,
     0,
     nil,
     OPEN_EXISTING,
     FILE_ATTRIBUTE_NORMAL,
     0);

   if ComFile = INVALID_HANDLE_VALUE then
     Result := False
   else
     Result := True;
end;


// =============================================================================
                 function TForm1.SetupCOMPort: Boolean;
// =============================================================================

const
   RxBufferSize = 256;
   TxBufferSize = 256;
var
   DCB: TDCB;
   Config: string;
   CommTimeouts: TCommTimeouts;

begin
    { We assume that the setup to configure the setup works fine.
      Otherwise the function returns false.
    }

   if not SetupComm(ComFile, RxBufferSize, TxBufferSize) then
     begin
       Result := False;
       exit;
     end;

   if not GetCommState(ComFile, DCB) then
     begin
       Result := False;
       exit;
     end;

   // define the baudrate, parity,...

   Config := 'baud=9600 parity=n data=8 stop=1';

   if not BuildCommDCB(@Config[1], DCB) then
     begin
       Result := False;
       exit;
     end;

   if not SetCommState(ComFile, DCB) then
     begin
       Result := False;
       exit;
     end;

   with CommTimeouts do
   begin
     ReadIntervalTimeout         := 0;
     ReadTotalTimeoutMultiplier  := 0;
     ReadTotalTimeoutConstant    := 1000;
     WriteTotalTimeoutMultiplier := 0;
     WriteTotalTimeoutConstant   := 1000;
   end;

   if not SetCommTimeouts(ComFile, CommTimeouts) then Result := False
   else result := true;
end;

// =============================================================================
                         procedure TForm1.CloseCOMPort;
// =============================================================================

begin
   // finally close the COM Port!

   CloseHandle(ComFile);
end;


// =============================================================================
                    procedure TForm1.sendByteFile;
// =============================================================================

var _message: string;
    _qq: word;

begin
  _message := '';
  _qq := 1;
  while _qq<=_bytefileHossz do
    begin
      _message := _message + chr(_bytetomb[_qq]);
      inc(_qq);
    end;

  WriteFile(ComFile, _message[1], _bytefilehossz, _BytesWritten, nil);
  if _bytesWritten=_bytefilehossz then
        Memo.Lines.add('AZ ÁRFOLYAMOK SIKERESEN KI LETTEK KÜLDVE A FÉNYÚJSÁGRA !')
      ELSE
        Memo.Lines.add('AZ ÁRFOLYAMOKAT NEM SIKERÜLT KIKÜLDENI A FÉNYÚJSÁGRA !');
end;

// =============================================================================
             function TForm1.arfform(_int: integer): string;
// =============================================================================


var _ints: string;

begin
  _ints := inttostr(_int);
  while length(_ints)<5 do _ints := ' ' + _ints;
  result := leftstr(_ints,3)+','+midstr(_ints,4,2);
end;

// =============================================================================
                procedure TForm1.ValsorBeiro(_vsor: string);
// =============================================================================

var _zz,_lensor: integer;

begin
  _lensor := length(_vsor);
  _zz := 1;
  while _zz<=_lensor do
    begin
      _bytetomb[_utbytess+_zz] := ord(_vsor[_zz]);
      inc(_zz);
    end;
  _bytetomb[_utbytess+_zz] := 32;
  inc(_zz);

  _bytetomb[_utbytess+_zz] := 32;
  _utbytess := _utbytess + _zz;
end;

procedure TForm1.IDOZITOTimer(Sender: TObject);
begin
  Idozito.Enabled := False;
  if ArfolyamLetoltes then ArfolyamKikuldes;
  Idozito.Enabled := true;
end;

end.
