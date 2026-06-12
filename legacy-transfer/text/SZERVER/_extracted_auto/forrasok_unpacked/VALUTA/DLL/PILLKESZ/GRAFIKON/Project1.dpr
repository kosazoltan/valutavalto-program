program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit25 in 'Unit25.pas' {HAVITABLO};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(THAVITABLO, HAVITABLO);
  Application.Run;
end.
