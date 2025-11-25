program Ugyfctrl;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {GETIDOSZAK},
  Unit3 in 'Unit3.pas' {ADATFELTOLTES},
  Unit4 in 'Unit4.pas' {MAKEEXCEL},
  Unit5 in 'Unit5.pas' {IMPORTFORM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TGETIDOSZAK, GETIDOSZAK);
  Application.CreateForm(TADATFELTOLTES, ADATFELTOLTES);
  Application.CreateForm(TMAKEEXCEL, MAKEEXCEL);
  Application.CreateForm(TIMPORTFORM, IMPORTFORM);
  Application.Run;
end.
