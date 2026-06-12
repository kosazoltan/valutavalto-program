program Trade;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {TELEFONFORM},
  Unit3 in 'Unit3.pas' {AUTOPALYAFORM},
  Unit4 in 'Unit4.pas' {automotorform},
  Unit5 in 'Unit5.pas' {GETPENZTAROSNEV},
  Unit6 in 'Unit6.pas' {MATRICAHTTPSRUTINOK},
  Unit7 in 'Unit7.pas' {TELEFONHTTPSRUTINOK},
  Unit11 in 'Unit11.pas' {ZARAS},
  Unit9 in 'Unit9.pas' {GETTANUSITVANY},
  Unit10 in 'Unit10.pas' {PAYSAFEFORM},
  Unit12 in 'Unit12.pas' {SELECTCOUNTY},
  Unit8 in 'Unit8.pas' {UJTANUSITVANY},
  Unit13 in 'Unit13.pas' {LOGOLVASAS};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TTELEFONFORM, TELEFONFORM);
  Application.CreateForm(TAUTOPALYAFORM, AUTOPALYAFORM);
  Application.CreateForm(Tautomotorform, automotorform);
  Application.CreateForm(TGETPENZTAROS, GETPENZTAROS);
  Application.CreateForm(TMATRICAHTTPSRUTINOK, MATRICAHTTPSRUTINOK);
  Application.CreateForm(TTELEFONHTTPSRUTINOK, TELEFONHTTPSRUTINOK);
  Application.CreateForm(TZARAS, ZARAS);
  Application.CreateForm(TGETTANUSITVANY, GETTANUSITVANY);
  Application.CreateForm(TPAYSAFEFORM, PAYSAFEFORM);
  Application.CreateForm(TSELECTCOUNTY, SELECTCOUNTY);
  Application.CreateForm(TUJTANUSITVANY, UJTANUSITVANY);
  Application.CreateForm(TLOGOLVASAS, LOGOLVASAS);
  Application.Run;
end.
