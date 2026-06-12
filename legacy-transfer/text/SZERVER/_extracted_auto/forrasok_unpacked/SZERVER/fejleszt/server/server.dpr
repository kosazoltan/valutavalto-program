program server;

uses
  Forms,
  Unit1 in 'UNIT1.PAS' {Form1},
  Unit2 in 'UNIT2.PAS' {GETDATADISP},
  Unit3 in 'UNIT3.PAS' {RENDSZERADATOK},
  Unit4 in 'UNIT4.PAS' {ATTEKINTES},
  Unit6 in 'Unit6.pas' {MNBLISTAK},
  Unit7 in 'Unit7.pas' {HIBAKDISPLAY},
  Unit8 in 'Unit8.pas' {CIMLETEZO},
  Unit9 in 'Unit9.pas' {IDOSZAKBEFORM},
  Unit10 in 'Unit10.pas' {FOMENUFORM},
  Unit11 in 'Unit11.pas' {HIANYZOZARASOKFORM},
  Unit12 in 'Unit12.pas' {USERFORM},
  Unit13 in 'Unit13.pas' {KEZIADATPOTLASFORM},
  Unit15 in 'Unit15.pas' {UGYFELFORGALOMPOTLO},
  Unit14 in 'UNIT14.PAS' {MNBLEGYUJTO},
  Unit17 in 'Unit17.pas' {MNBLISTADISPLAY},
  Unit18 in 'Unit18.pas' {GETUZLETSZAM},
  Unit19 in 'Unit19.pas' {CIMLETLISTA},
  Unit20 in 'Unit20.pas' {KELLTEGNAP},
  Unit16 in 'Unit16.pas' {IRODATMK},
  Unit21 in 'Unit21.pas' {ARFOLYAMTMK},
  Unit23 in 'Unit23.pas' {FORGALOMDISPLAY},
  Unit24 in 'Unit24.pas' {KESZLETDISPLAY},
  Unit25 in 'Unit25.pas' {WUNIDISPLAY},
  Unit26 in 'Unit26.pas' {BANKFORGALOMDISPLAY},
  Unit27 in 'Unit27.pas' {PENZTARKOZOTTIDISPLAY},
  Unit28 in 'Unit28.pas' {ADATMENU},
  Unit29 in 'Unit29.pas' {ADATLEGYUJTES},
  Unit22 in 'Unit22.pas' {STORNODISP},
  Unit30 in 'Unit30.pas' {TRBDISPLAY},
  Unit31 in 'UNIT31.PAS' {JUTSZAM},
  Unit32 in 'Unit32.pas' {JUTALEKSZAZALEK},
  Unit33 in 'Unit33.pas' {ATLAGARFOLYAM},
  Unit34 in 'Unit34.pas' {ARFOLYAMELTERITES},
  Unit35 in 'Unit35.pas' {KEDVEZMENYLISTA},
  Unit36 in 'Unit36.pas' {ATLAGDISPLAY},
  Unit37 in 'Unit37.pas' {WUNIWAFACONTROL};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TGETDATADISP, GETDATADISP);
  Application.CreateForm(TRENDSZERADATOK, RENDSZERADATOK);
  Application.CreateForm(TATTEKINTES, ATTEKINTES);
  Application.CreateForm(TMNBLISTAK, MNBLISTAK);
  Application.CreateForm(THIBAKDISPLAY, HIBAKDISPLAY);
  Application.CreateForm(TCIMLETEZOForm, CIMLETEZOForm);
  Application.CreateForm(TIDOSZAKBEFORM, IDOSZAKBEFORM);
  Application.CreateForm(TFOMENUFORM, FOMENUFORM);
  Application.CreateForm(THIANYZOZARASOKFORM, HIANYZOZARASOKFORM);
  Application.CreateForm(TUSERFORM, USERFORM);
  Application.CreateForm(TKEZIADATPOTLASFORM, KEZIADATPOTLASFORM);
  Application.CreateForm(TUGYFELFORGALOMPOTLO, UGYFELFORGALOMPOTLO);
  Application.CreateForm(TMNBLEGYUJTO, MNBLEGYUJTO);
  Application.CreateForm(TMNBLISTADISPLAY, MNBLISTADISPLAY);
  Application.CreateForm(TGETUZLETSZAM, GETUZLETSZAM);
  Application.CreateForm(TCIMLETLISTA, CIMLETLISTA);
  Application.CreateForm(TKELLTEGNAP, KELLTEGNAP);
  Application.CreateForm(TIRODATMK, IRODATMK);
  Application.CreateForm(TARFOLYAMTMK, ARFOLYAMTMK);
  Application.CreateForm(TFORGALOMDISPLAY, FORGALOMDISPLAY);
  Application.CreateForm(TKESZLETDISPLAY, KESZLETDISPLAY);
  Application.CreateForm(TWUNIDISPLAY, WUNIDISPLAY);
  Application.CreateForm(TBANKFORGALOMDISPLAY, BANKFORGALOMDISPLAY);
  Application.CreateForm(TPENZTARKOZOTTIDISPLAY, PENZTARKOZOTTIDISPLAY);
  Application.CreateForm(TADATMENU, ADATMENU);
  Application.CreateForm(TADATLEGYUJTES, ADATLEGYUJTES);
  Application.CreateForm(TSTORNODISP, STORNODISP);
  Application.CreateForm(TTRBDISPLAY, TRBDISPLAY);
  Application.CreateForm(TJUTSZAM, JUTSZAM);
  Application.CreateForm(TJUTALEKSZAZALEK, JUTALEKSZAZALEK);
  Application.CreateForm(TATLAGARFOLYAM, ATLAGARFOLYAM);
  Application.CreateForm(TARFOLYAMELTERITES, ARFOLYAMELTERITES);
  Application.CreateForm(TKEDVEZMENYLISTA, KEDVEZMENYLISTA);
  Application.CreateForm(TATLAGDISPLAY, ATLAGDISPLAY);
  Application.CreateForm(TWUNIWAFACONTROL, WUNIWAFACONTROL);
  Application.Run;
end.
