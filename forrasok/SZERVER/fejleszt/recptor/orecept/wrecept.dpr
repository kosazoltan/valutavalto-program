program WRecept;

uses
  Forms,
  Dialogs,
  Windows,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {MENTES},
  Unit5 in 'Unit5.pas' {STORNOBIZONYLATOK},
  Unit6 in 'Unit6.pas' {BIGSUM},
  Unit4 in 'Unit4.pas' {PERSONALBEDOLGOZAS},
  Unit3 in 'Unit3.pas' {GETLETTER};

{$R *.res}

var _mutex: THandle;

begin
  _mutex := CreateMutex(Nil,True,'Wrecept.exe');
  if ((_mutex=0) or (GETLASTERROR=ERROR_ALREADY_EXISTS)) then
    begin
      ShowMessage('A RECEPTOR MAR FUT A RENDSZERBEN !');
    END ELSE
    Begin
      Application.Initialize;
      Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TMENTES, MENTES);
  Application.CreateForm(TSTORNOBIZONYLATOK, STORNOBIZONYLATOK);
  Application.CreateForm(TBIGSUM, BIGSUM);
  Application.CreateForm(TPERSONALBEDOLGOZAS, PERSONALBEDOLGOZAS);
  Application.CreateForm(TGETLETTER, GETLETTER);
  Application.Run;
      if _mutex<>0 then CloseHandle(_mutex);
    end;
end.
