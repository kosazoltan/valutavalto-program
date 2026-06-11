program PtarCtrl;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {EREDMENYFORM},
  Unit3 in 'Unit3.pas' {BEMUTATO},
  Unit4 in 'Unit4.pas' {HOBEKERO};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TEREDMENYFORM, EREDMENYFORM);
  Application.CreateForm(TBEMUTATO, BEMUTATO);
  Application.CreateForm(THOBEKERO, HOBEKERO);
  Application.Run;
end.
