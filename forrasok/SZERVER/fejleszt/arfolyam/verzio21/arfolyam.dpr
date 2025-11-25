program Arfolyam;

uses
  Forms,
  Unit1 in '..\verzio22\Unit1.pas' {Form1},
  Unit3 in 'Unit3.pas' {GETFUGGVENY},
  Unit4 in 'Unit4.pas' {NYOMTATOFORM},
  Unit7 in 'Unit7.pas' {CSOPORTDISPLAY},
  Unit8 in 'Unit8.pas' {MUNKAFORM},
  Unit9 in 'Unit9.pas' {ALAPLAP},
  Unit11 in 'Unit11.pas' {INTERNETBONGESZO},
  Unit12 in 'Unit12.pas' {ADATBETOLTES},
  Unit5 in 'Unit5.pas' {ARFDATAIRAS},
  Unit6 in 'Unit6.pas' {ADATSZETKULDES},
  Unit13 in 'Unit13.pas' {ZOLDMENU},
  Unit14 in 'Unit14.pas' {HOVAMASOLJAK},
  Unit15 in 'Unit15.pas' {LIMITALLITOFORM},
  Unit2 in 'Unit2.pas' {INTERNETTMKFORM},
  Unit16 in 'Unit16.pas' {IRODANEVLISTA},
  Unit10 in 'Unit10.pas' {helpform};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TGETFUGGVENY, GETFUGGVENY);
  Application.CreateForm(TNYOMTATOFORM, NYOMTATOFORM);
  Application.CreateForm(TCSOPORTDISPLAY, CSOPORTDISPLAY);
  Application.CreateForm(TMUNKAFORM, MUNKAFORM);
  Application.CreateForm(TALAPLAP, ALAPLAP);
  Application.CreateForm(TINTERNETBONGESZO, INTERNETBONGESZO);
  Application.CreateForm(TADATBETOLTES, ADATBETOLTES);
  Application.CreateForm(TARFDATAIRAS, ARFDATAIRAS);
  Application.CreateForm(TADATSZETKULDES, ADATSZETKULDES);
  Application.CreateForm(TZOLDMENU, ZOLDMENU);
  Application.CreateForm(THOVAMASOLJAK, HOVAMASOLJAK);
  Application.CreateForm(TLIMITALLITOFORM, LIMITALLITOFORM);
  Application.CreateForm(TINTERNETTMKFORM, INTERNETTMKFORM);
  Application.CreateForm(TIRODANEVLISTA, IRODANEVLISTA);
  Application.CreateForm(Thelpform, helpform);
  Application.Run;
end.
