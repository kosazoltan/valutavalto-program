program MakeBesz;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit3 in 'Unit3.pas' {ADATGYUJTES},
  Unit2 in 'Unit2.pas' {MAKEEXCEL};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TADATGYUJTES, ADATGYUJTES);
  Application.CreateForm(TMAKEEXCEL, MAKEEXCEL);
  Application.Run;
end.
