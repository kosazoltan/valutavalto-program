program Haszon;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {kijelzes},
  Unit3 in 'Unit3.pas' {IDOSZAKKEROFORM},
  Unit4 in 'Unit4.pas' {EXCELKESZITES},
  Unit5 in 'Unit5.pas' {HASZONFELVIVOFORM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(Tkijelzes, kijelzes);
  Application.CreateForm(TIDOSZAKKEROFORM, IDOSZAKKEROFORM);
  Application.CreateForm(TEXCELKESZITES, EXCELKESZITES);
  Application.CreateForm(THASZONFELVIVOFORM, HASZONFELVIVOFORM);
  Application.Run;
end.
