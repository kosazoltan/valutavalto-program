program Korlevel;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {superform},
  Unit3 in 'Unit3.pas' {READTIMEFORM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(Tsuperform, superform);
  Application.CreateForm(TREADTIMEFORM, READTIMEFORM);
  Application.Run;
end.
