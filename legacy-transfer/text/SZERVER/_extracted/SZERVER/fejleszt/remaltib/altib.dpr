program Altib;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {ROGZITESFORM},
  Unit3 in 'Unit3.pas' {REKORDTORLOFORM},
  Unit4 in 'Unit4.pas' {ZAPPOLOFORM},
  Unit5 in 'Unit5.pas' {SZAMSUMMA},
  Unit6 in 'Unit6.pas' {MEZOTOLTOFORM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TROGZITESFORM, ROGZITESFORM);
  Application.CreateForm(TREKORDTORLOFORM, REKORDTORLOFORM);
  Application.CreateForm(TZAPPOLOFORM, ZAPPOLOFORM);
  Application.CreateForm(TSZAMSUMMA, SZAMSUMMA);
  Application.CreateForm(TMEZOTOLTOFORM, MEZOTOLTOFORM);
  Application.Run;
end.