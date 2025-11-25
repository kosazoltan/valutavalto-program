program Project1;

uses
  Forms,
  Windows,
  Dialogs,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

var _mutex: THandle;

begin
  _mutex := CreateMutex(Nil,True,'RECGUARD.EXE');
  if ((_mutex=0) or (GETLASTERROR=ERROR_ALREADY_EXISTS)) then
    begin
      ShowMessage('MÁR FUT A RECGUARD A GÉPEN');
    End Else
    Begin
      Application.Initialize;
      Application.CreateForm(TForm1, Form1);
      Application.Run;
      if _mutex<>0 then CloseHandle(_mutex);
    end;  
end.
