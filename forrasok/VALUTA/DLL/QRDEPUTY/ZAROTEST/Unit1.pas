unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    KILEPO: TTimer;
    Label1: TLabel;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    MEMO: TMemo;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure sendByteFile;
    function SetupCOMPort: Boolean;
    function OpenCOMPort: Boolean;
    procedure KILEPOTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pacs,_pname: STRING;
  _initstring: string = 'http://www.fiscat.com/AEE';
  _BYTEFILEHOSSZ,_BYTESWRITTEN: dword;
  _PortName: Pchar;
  COmfile : THandle;
  _navcom: byte;


implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  APPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _bytefilehossz := 37;
  _pacs := _initstring + '|DC|0|0|1|1|';

  IF NOT opencomport then
    begin
      ShowMessage('Nem sikerült a port megnyitása');
      Kilepo.enabled := True;
      exit;
    end;

  Memo.Lines.add(_pname + ' port megnyitva !');
  if not setupcomport then
    begin
      closehandle(comfile);
      ShowMessage('Nem sikerült a '+_pname+' port konfigurálása');
      Kilepo.enabled := true;
      exit;
    end;

  sendByteFile;
  closehandle(comfile);

  if _bytefilehossz<>_byteswritten then ShowMessage('SIKERTELEN MÜVELET')
  ELSE showmessage('SIKERES ADAT KIKÜLDÉS');

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

      Wir versuchen, COM1 zu öffnen.
      Sollte dies fehlschlagen, gibt die Funktion false zurück.
    }
  // StrPCopy(DeviceName, 'COM2:');
   mEMO.Lines.add(_pname + ' port megnyitása ...');
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
                 function TfORM1.SetupCOMPort: Boolean;
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

    Memo.Lines.Add(_pname+' port konfigurálása: ');

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

   Memo.Lines.Add(config);
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
                    procedure TFORM1.sendByteFile;
// =============================================================================



begin
  Memo.Lines.Add('Kiküldött sequencia: '+_pacs);
  WriteFile(ComFile, _PACS[1], _bytefilehossz, _BytesWritten, nil);
end;


procedure TForm1.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := fALSE;
  Application.Terminate;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  vdbase.Connected := True;
  with vquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _navcom := FieldByName('NAVCOM').asInteger;
      Close;
    end;
  vdbase.close;

  _pname := 'COM'+inttostr(_navcom)+':';
  _portname := pchar(_pname);
end;

end.
