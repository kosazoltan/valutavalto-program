program Electrad;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {GETIDOSZAK},
  Unit5 in 'Unit5.pas' {EREDMENYKIJELZES},
  Unit4 in 'Unit4.pas' {UJADATGYUJTO},
  Unit3 in 'Unit3.pas' {MEXCEL};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TGETIDOSZAK, GETIDOSZAK);
  Application.CreateForm(TEREDMENYKIJELZES, EREDMENYKIJELZES);
  Application.CreateForm(TUJADATGYUJTO, UJADATGYUJTO);
  Application.CreateForm(TMEXCEL, MEXCEL);
  Application.Run;
end.
