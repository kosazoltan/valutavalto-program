program ibvalto;

uses
  Forms,
  Windows,
  Dialogs,
  Unit1 in 'UNIT1.PAS' {FORM1},
  Unit18 in 'Unit18.pas' {ZARASFORM},
  Unit47 in 'Unit47.pas' {FOMENUFORM},
  Unit3 in 'Unit3.pas' {UJKONVERZIO},
  Unit2 in 'Unit2.pas' {OPENKERDOFORM},
  Unit4 in 'Unit4.pas' {TOLTOFORM},
  Unit5 in 'Unit5.pas' {TRYAGAINFORM};

{$R *.res}

var _mutex: THandle;


begin
  _mutex := CreateMutex(Nil,True,'IBVALTO.EXE');
  if ((_mutex=0) or (GETLASTERROR=ERROR_ALREADY_EXISTS)) then
    begin
      ShowMessage('A VALUTAVÁLTÓ PROGRAM MÁR FUT A RENDSZERBEN !!!');
    end else
    begin

  Application.Initialize;
  with TToltoform.Create(nil) do
    try
      Csik.Max := 25;
      show;
      update;

      Application.CreateForm(TFORM1, FORM1);
  Application.CreateForm(TTRYAGAINFORM, TRYAGAINFORM);
  Csik.StepBy(5);
      Uzenopanel.caption := 'Alapprogramok betöltve';
      update;
      sleep(1500);

      Application.CreateForm(TZARASFORM, ZARASFORM);
      Csik.stepby(5);
      Uzenopanel.caption := 'Zárások, cimletezések stb betöltve';
      Update;
      Sleep(1500);

      Application.CreateForm(TFOMENUFORM, FOMENUFORM);
      Csik.stepby(5);
      Uzenopanel.caption := 'Fömenü és tartozékai betöltve';
      Update;
      Sleep(1500);

      Application.CreateForm(TUJKONVERZIO, UJKONVERZIO);
      Csik.stepby(5);
      Uzenopanel.caption := 'Konverziós eladások programjai betöltve';
      Update;
      Sleep(1500);

      Application.CreateForm(TOPENKERDOFORM, OPENKERDOFORM);
      Csik.stepby(5);
      Uzenopanel.caption := 'Navos és egyéb programok betöltve';
      Update;
      Sleep(1500);

      Application.CreateForm(TTOLTOFORM, TOLTOFORM);
      Uzenopanel.caption := 'Programok rendben - program indul';
      Update;
      Sleep(1500);

  finally
     free;
  end;

  Application.Run;
      if _mutex<>0 then CLoseHandle(_mutex);
    end;

end.
