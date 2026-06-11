unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  strutils, ExtCtrls;

type
  TPROSKILEP = class(TForm)
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    kilepotimer: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure kilepotimerTimer(Sender: TObject);
    procedure Valutaparancs(_ukaz: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PROSKILEP: TPROSKILEP;
  _pcs,_megnyitottnap,_hdidkod,_idos: string;
  _sorveg: string = chr(13)+chr(10);


function penztaroskileptetes: integer; stdcall;




implementation

{$R *.dfm}


function penztaroskileptetes: integer; stdcall;
begin
  Proskilep := TProskilep.create(Nil);
  result := Proskilep.showmodal;
  Proskilep.Free;
end;

procedure TPROSKILEP.FormActivate(Sender: TObject);
begin
  Proskilep.Visible := false;
  _pcs := 'SELECT * FROM HARDWARE';
  valutadbase.Connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asstring);
      _hdidKod := FieldByname('IDKOD').asString;
      close;
    end;
  Valutadbase.close;

  // -------------------------------------------------

  _pcs := 'UPDATE HARDWARE SET IDKOD=' + chr(39)+chr(39)+',';
  _pcs := _pcs + 'PENZTAROSNEV=' + chr(39)+chr(39);
  ValutaParancs(_pcs);

  // ---------------------------------------------------------

  _idos := trim(timetostr(Time+0.0068));   // + 10 perc
  if midstr(_idos,2,1)=':' then _idos := '0' + _idos;
  _idos := leftstr(_idos,5);

  _pcs := 'UPDATE JELENLET SET KILEPES=' + chr(39) + _idos + chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE(IDKOD=' + chr(39)+ _hdIdkod + chr(39)+') AND ';
  _PCS := _PCS + '(DATUM=' + chr(39) + _megnyitottnap + chr(39) + ')';
  ValutaParancs(_pcs);

  KIlepotimer.enabled := true;
end;

procedure TPROSKILEP.kilepotimerTimer(Sender: TObject);
begin
  KilepoTimer.Enabled := false;
  Modalresult := 1;
end;

procedure Tproskilep.Valutaparancs(_ukaz: string);

begin
  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then valutatranz.commit;
  ValutaTranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      Execsql;
    end;
  Valutatranz.Commit;
  ValutaDbase.close;
end;

end.
