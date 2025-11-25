program Korlevel;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {superform},
  Unit3 in 'Unit3.pas' {READTIMEFORM},
  Unit4 in 'Unit4.pas' {GETVIPFORM},
  Unit5 in 'Unit5.pas' {ARCHIVEFORM},
  Unit6 in 'Unit6.pas' {GETIDKOD},
  Unit7 in 'Unit7.pas' {LASTYEARFORM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(Tsuperform, superform);
  Application.CreateForm(TREADTIMEFORM, READTIMEFORM);
  Application.CreateForm(TGETVIPFORM, GETVIPFORM);
  Application.CreateForm(TARCHIVEFORM, ARCHIVEFORM);
  Application.CreateForm(TGETIDKOD, GETIDKOD);
  Application.CreateForm(TLASTYEARFORM, LASTYEARFORM);
  Application.Run;
end.
