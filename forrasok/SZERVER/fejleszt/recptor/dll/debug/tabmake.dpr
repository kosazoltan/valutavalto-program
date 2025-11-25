program Tabmake;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit3 in 'Unit3.pas' {TABMAKER};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TTABMAKER, TABMAKER);
  Application.Run;
end.
