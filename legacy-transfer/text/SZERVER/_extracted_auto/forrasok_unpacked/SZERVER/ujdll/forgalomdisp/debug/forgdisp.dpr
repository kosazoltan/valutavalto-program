program ForgDisp;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {FORGDISPLAY};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFORGDISPLAY, FORGDISPLAY);
  Application.Run;
end.
