program Tdij;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {TRANZDIJ},
  Unit3 in 'Unit3.pas' {MNBARFOLYAM},
  Unit4 in 'Unit4.pas' {hovalasztoform};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TTRANZDIJ, TRANZDIJ);
  Application.CreateForm(TMNBARFOLYAM, MNBARFOLYAM);
  Application.CreateForm(Thovalasztoform, hovalasztoform);
  Application.Run;
end.
