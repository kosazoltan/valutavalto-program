unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, strutils,
  ExtCtrls;

type
  TFnyUjsag = class(TForm)
    IBQuery: TIBQuery;
    IBDbase: TIBDatabase;
    ibtranz: TIBTransaction;
    INDITO: TTimer;
    Panel1: TPanel;
    Shape1: TShape;
    KILEPO: TTimer;

    procedure CloseComport;
    procedure ByteFileIras;
    procedure sendByteFile;

    function OpenCOMPort: Boolean;
    function SetupCOMPort: Boolean;
    procedure ValsorBeiro(_vsor: string);

    procedure FormActivate(Sender: TObject);
    procedure InditoTimer(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Fnyujsag: TFnyujsag;
  Comfile: THandle;

  _paranum: integer;
  _pname: string;

  _byteswritten: dword;
  _utbytess: word;
  _portdarab,_postterm: byte;

  _comDir  : string = 'c:\valuta\comport';
  _comPath : string = 'c:\valuta\comport\v4.txt';
  _portname : pchar;   // = pchar('COM1:');
  _port: array[1..4] of string;


//  _portname2: pchar = pchar('COM2:');

  _penztar  : string;
  _ptarszam,_code,_qq: integer;

  _displayDarab: integer;
  _doubledisplayPenztar: array of byte;

  _bytetomb: array[1..1024] of byte;
  _message: string;

  _iras,_olvas: File of byte;

  _eurvet,_chfvet,_usdvet,_gbpvet: real;
  _eurelad,_chfelad,_usdelad,_gbpelad: real;
  _pcs,_mondat: string;
  _sorveg: string = chr(13);

  _top,_left,_height,_width: word;
  _initsor : string = chr(21)+chr(18)+chr(5);

  _endchar : string = chr(254);
  _bytefileHossz: integer;
  _speed: integer;
  _parameters: string;

 function fenyujsagfrissito: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function fenyujsagfrissito: integer; stdcall;
// =============================================================================

begin
  fnyujsag := TFnyUjsag.create(Nil);
  result   := Fnyujsag.Showmodal;
  Fnyujsag.Free;
end;



// =============================================================================
               procedure TFnyujsag.FormActivate(Sender: TObject);
// =============================================================================


begin

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _top    := round((_height-61)/2);
  _left   := round((_width-660)/2);

  Top    := _top+100;
  Left   := _left;
  Height := 61;
  Width  := 660;

  Panel1.Repaint;


  Indito.Enabled := True;
end;



// =============================================================================
               procedure TFnyujsag.INDITOTimer(Sender: TObject);
// =============================================================================


begin
  Indito.Enabled := False;

  _portname := pchar('COM1:');
  _speed := 3;


  _pname := 'COM1:';
  _portname := pchar(_pname);

  if not OpenComport then
    begin
      ShowMessage('Nem sikerült megnyitni a '+_pName+' portot !');
      Application.terminate;
      Exit;
    end;

  if not SetupComport then
    begin
      CloseComport;
      ShowMessage('Nem sikerült beállítani a ' + _pname + ' portot !');
      Application.Terminate;
      Exit;
    end;

  BytefileIras;  
  SendBytefile;
  CloseComport;

  Kilepo.Enabled := true;
end;

// =============================================================================
                      procedure TFnyujsag.ByteFileIras;
// =============================================================================

var _2szokoz,_valsor: string;

begin
  _2szokoz := chr(32)+chr(32);
  _bytetomb[1] := 21;
  _bytetomb[2] := 18;
  _bytetomb[3] := 5;

  {
  _bytetomb[4] := 92;    // '\'
  _bytetomb[5] := 70;    // 'F'
  _bytetomb[6] := 83;    // 'S'
  _bytetomb[7] := 48+_speed;  // sebesség '0'-'9'
  }

  _utbytess := 3;

  _valsor := 'LEGSZÉLESEBB VALUTAKINÁLAT - EXTRA, EGYEDI ÁRFOLYAM KEDVEZMÉNYEKKEL';
  _valsor := _valsor + '       --------      ';
  Valsorbeiro(_valsor);

  inc(_utbytess);

  _bytetomb[_utbytess] := 254;
  _byteFileHossz := _utbytess;

  AssignFile(_iras,_comPath);
  Rewrite(_iras);
  Blockwrite(_iras,_bytetomb,_bytefileHossz);
  CloseFile(_iras);
end;

// =============================================================================
                procedure TFnyujsag.ValsorBeiro(_vsor: string);
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

// =============================================================================
                  function TFnyujsag.OpenCOMPort: Boolean;
// =============================================================================

var
   DeviceName: array[0..80] of Char;

begin
    { First step is to open the communications device for read/write.
      This is achieved using the Win32 'CreateFile' function.
      If it fails, the function returns false.

      Wir versuchen, COM1 zu öffnen.
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
                 function Tfnyujsag.SetupCOMPort: Boolean;
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
                    procedure TFnyujsag.sendByteFile;
// =============================================================================



begin
  _message := '';
  _qq := 1;
  while _qq<=_bytefileHossz do
    begin
      _message := _message + chr(_bytetomb[_qq]);
      inc(_qq);
    end;

  WriteFile(ComFile, _message[1], _bytefilehossz, _BytesWritten, nil);
end;

// =============================================================================
                         procedure TFnyujsag.CloseCOMPort;
// =============================================================================

begin
   // finally close the COM Port!

   CloseHandle(ComFile);
end;

// =============================================================================
             procedure TFnyUjsag.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  ModalResult := 2;
end;

end.