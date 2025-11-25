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


    procedure ArfolyamBeolvasas;
    procedure Arfnyitas(_ukaz: string);

    procedure CloseComport;
    procedure ByteFileIras;
    procedure sendByteFile;

    function Arfform(_real: real): string;
    function EzdoublePenztar(_pp: integer): boolean;
    function OpenCOMPort: Boolean;
//    function OpenCOMPort2: Boolean;
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

var
    _pdbs,_speeds: string;

begin
  { _parameters: '2125' = 2 futófény, com1, com2, 5-ös speed
                 '1207' = 1 futófény, com2, 7-es speed
  }

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _top    := round((_height-61)/2);
  _left   := round((_width-660)/2);

  Top    := _top+100;
  Left   := _left;
  Height := 61;
  Width  := 660;

  Panel1.Repaint;

  // Comport könyvtár létrehozása, ha nincs még

  if not Directoryexists(_comDir) then CreateDir(_comdir);

  ibDbase.connected := true;
  _pcs := 'SELECT * FROM HARDWARE';
  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
     _paranum := FieldByName('FUTOFENY').asInteger;
     _postterm := FieldByName('POSTTERM').asInteger;
     Close;
   end;

  _pcs := 'SELECT * FROM PENZTAR';
  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
     _penztar := trim(FieldByname('PENZTARKOD').AsString);
     Close;
   end;
 ibDbase.close;

 val(_penztar,_ptarszam,_code);
 if _code<>0 then _ptarszam := 0;

 if _paranum<1 then
   begin
     Kilepo.Enabled := True;
     exit;
   end;

 _parameters := inttostr(_paranum);
 if length(_parameters)<>4 then
    begin
      Showmessage('HIBÁS PARAMÉTER');
      Kilepo.Enabled := true;
      exit;
    end;

  _pdbs := leftstr(_parameters,1);
  _port[1] := midstr(_parameters,2,1);
  _port[2] := midstr(_parameters,3,1);
  _speeds := midstr(_parameters,4,1);

  val(_pdbs,_portdarab,_code);
  if _code<>0 then _portdarab := 0;
  if _portdarab=0 then
    begin
      Showmessage('NINCS PORT MEGADVA');
      Kilepo.Enabled := True;
      exit;
    end;

  val(_speeds,_speed,_code);
  if _code<>0 then _speed := 5;

  Indito.Enabled := True;
end;



// =============================================================================
               procedure TFnyujsag.INDITOTimer(Sender: TObject);
// =============================================================================

var _z: byte;
    _nums,_pname: string;

begin
  Indito.Enabled := False;

  _portname := pchar('COM1:');
  _speed := 9-_speed;

  ArfolyamBeolvasas;
  ByteFileIras;

  _z := 1;
  while _z<=_portdarab do
    begin
      _nums := _port[_z];
      _pname := 'COM' + _nums + ':';
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

      SendBytefile;
      CloseComport;
      inc(_z);
    end;

  Kilepo.Enabled := true;
end;


// =============================================================================
                  procedure TFnyUjsag.Arfolyambeolvasas;
// =============================================================================

begin
  ibdbase.Connected := true;
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'EUR'+chr(39);
  Arfnyitas(_pcs);
  _eurvet := ibQuery.fieldByName('VETELIARFOLYAM').asFloat;
  _eurelad:= ibQuery.FieldByName('ELADASIARFOLYAM').asFloat;

  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'USD'+chr(39);
  Arfnyitas(_pcs);
  _usdvet := ibQuery.fieldByName('VETELIARFOLYAM').asFloat;
  _usdelad:= ibQuery.FieldByName('ELADASIARFOLYAM').asFloat;

  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'GBP'+chr(39);
  Arfnyitas(_pcs);
  _gbpvet := ibQuery.fieldByName('VETELIARFOLYAM').asFloat;
  _gbpelad:= ibQuery.FieldByName('ELADASIARFOLYAM').asFloat;

   _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'CHF'+chr(39);
  Arfnyitas(_pcs);
  _chfvet := ibQuery.fieldByName('VETELIARFOLYAM').asFloat;
  _chfelad:= ibQuery.FieldByName('ELADASIARFOLYAM').asFloat;
  ibQuery.close;
  ibdbase.close;
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
  _bytetomb[4] := 92;    // '\'   
  _bytetomb[5] := 70;    // 'F'
  _bytetomb[6] := 83;    // 'S'
  _bytetomb[7] := 48+_speed;  // sebesség '0'-'9'
  _utbytess := 7;

  _valsor := 'EUR: '+ arfform(_eurvet)+'/'+arfform(_eurelad);
  Valsorbeiro(_valsor);

  _valsor := 'USD: '+ arfform(_usdvet)+'/'+arfform(_usdelad);
  Valsorbeiro(_valsor);

  _valsor := 'GBP: '+ arfform(_gbpvet)+'/'+arfform(_gbpelad);
  Valsorbeiro(_valsor);

 _valsor := 'CHF: '+ arfform(_chfvet)+'/'+arfform(_chfelad);
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



{
// =============================================================================
                  function TFnyujsag.OpenCOMPort2: Boolean;
// =============================================================================

var
   DeviceName: array[0..80] of Char;

begin
    { First step is to open the communications device for read/write.
      This is achieved using the Win32 'CreateFile' function.
      If it fails, the function returns false.

      Wir versuchen, COM1 zu öffnen.
      Sollte dies fehlschlagen, gibt die Funktion false zurück.
    
  // StrPCopy(DeviceName, 'COM2:');

   StrCopy(DeviceName,_portName2);
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
}

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


// =============================================================================
         function TFnyUjsag.EzdoublePenztar(_pp: integer): boolean;
// =============================================================================

var _jj: integer;

begin
  _jj := 0;
  result := false;
  while _jj<_displayDarab do
    begin
      if _doubleDisplayPenztar[_jj]= _pp  then
        begin
          result := True;
          break;
        end;
      inc(_jj);
    end;
end;


// =============================================================================
             function TFnyujsag.arfform(_real: real): string;
// =============================================================================


var _reals: string;

begin
  _reals := floattostr(_real);
  result := leftstr(_reals,3)+','+midstr(_reals,4,2);
end;

// =============================================================================
            procedure TFnyujsag.Arfnyitas(_ukaz: string);
// =============================================================================

begin
  with IbQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_ukaz);
      Open;
      First;
    end;
end;



 (*

// =============================================================================
                        procedure TFnyujsag.Szovegkikuldo;
// =============================================================================

begin

  _2szokoz := '  ';
  Assignfile(_olvas,_textPath);
  Reset(_olvas);
  while not eof(_olvas) do
    begin
      Readln(_olvas,_mondat);
      Sendtext(_mondat+_2szokoz);
    end;
  CloseFile(_olvas);
end;


// =============================================================================
                      procedure TFnyujsag.TextFileIras;
// =============================================================================

var _2szokoz: string;

begin
  _2szokoz := '  ';
  AssignFile(_iras,_textPath);
  Rewrite(_iras);

  write(_iras,_initsor+'\FS'+ chr(48+_speed));
  writeLn(_iras,'EUR: ' + Arfform(_eurvet)+'/'+arfform(_eurelad)+_2szokoz);
  writeLn(_iras,'CHF: ' + Arfform(_chfvet)+'/'+arfform(_chfelad)+_2szokoz);
  writeLn(_iras,'USD: ' + Arfform(_usdvet)+'/'+arfform(_usdelad)+_2szokoz);
  write(_iras,'GBP: ' + Arfform(_gbpvet)+'/'+arfform(_gbpelad)+chr(254);
  closeFile(_iras);
end;


// =============================================================================
                    procedure TFnyujsag.SendText(s: string);
// =============================================================================

var
   BytesWritten: DWORD;
begin
   WriteFile(ComFile, s[1], Length(s), BytesWritten, nil);
end;

(*
// =============================================================================
                          function TForm1.ReadText: string;
// =============================================================================

var
   d: array[1..80] of Char;
   s: string;
   i: Integer;
begin
   Result := '';
   if not ReadFile(ComFile, d, SizeOf(d), BytesRead, nil) then
   begin
     { Raise an exception }
     exit;
   end;
   s := '';
   for i := 1 to BytesRead do s := s + d[I];
   Result := s;
end;
*)


end.