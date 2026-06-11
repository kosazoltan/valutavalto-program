program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {MAIFORGALOMTABLAFORM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TMAIFORGALOMTABLAFORM, MAIFORGALOMTABLAFORM);
  Application.Run;
end.
