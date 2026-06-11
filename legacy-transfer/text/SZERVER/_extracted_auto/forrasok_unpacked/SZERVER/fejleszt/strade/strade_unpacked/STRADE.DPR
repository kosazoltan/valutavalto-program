program Strade;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {HAVIEGYENLEG};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(THAVIEGYENLEG, HAVIEGYENLEG);
  Application.Run;
end.
