program Verseny;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {JUTALEK},
  Unit4 in 'Unit4.pas' {MAKEEXCEL},
  Unit5 in 'Unit5.pas' {UJPENZTARFORGALOM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TJUTALEK, JUTALEK);
  Application.CreateForm(TMAKEEXCEL, MAKEEXCEL);
  Application.CreateForm(TUJPENZTARFORGALOM, UJPENZTARFORGALOM);
  Application.Run;
end.


