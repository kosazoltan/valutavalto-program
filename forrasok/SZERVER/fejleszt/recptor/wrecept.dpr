program WRecept;

uses
  Forms,
  Dialogs,
  Windows,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

var _mutex: THandle;

begin
  _mutex := CreateMutex(Nil,True,'WRECEPT.EXE');
  if ((_mutex=0) or (GETLASTERROR=ERROR_ALREADY_EXISTS)) then
    begin
      Showmessage('A RECEPTOR MÁR FUT A RENDSZERBEN');
      // Már fut a receptor
    end else
    begin

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
     end;
  if _mutex<>0 then CloseHandle(_mutex);
end.
