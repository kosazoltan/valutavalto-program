program Idpotlo;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {JONEVETVALASZT};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TJONEVETVALASZT, JONEVETVALASZT);
  Application.Run;
end.
