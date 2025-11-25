program Keszlex;

uses
  Forms,
  Unit1 in 'UNIT1.PAS' {Form1},
  Unit2 in 'Unit2.pas' {ACEXCELTABLA},
  Unit3 in 'Unit3.pas' {EXPRESSEXCEL};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TACEXCELTABLA, ACEXCELTABLA);
  Application.CreateForm(TEXPRESSEXCEL, EXPRESSEXCEL);
  Application.Run;
end.
