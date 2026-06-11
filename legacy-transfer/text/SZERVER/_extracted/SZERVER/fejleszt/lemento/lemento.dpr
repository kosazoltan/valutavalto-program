program LEMENTO;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {GYUJTESDISPLAY};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TGYUJTESDISPLAY, GYUJTESDISPLAY);
  Application.Run;
end.
