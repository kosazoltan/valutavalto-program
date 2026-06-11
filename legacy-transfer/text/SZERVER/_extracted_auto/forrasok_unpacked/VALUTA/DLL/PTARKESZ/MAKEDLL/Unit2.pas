unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, strutils;

type
  TPTARKESZ = class(TForm)
    ALAPPANEL: TPanel;
    Shape1: TShape;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    FTKESZLET: TPanel;
    VALUTAKESZLET: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    WUUSDKESZLET: TPanel;
    Panel11: TPanel;
    WUHUFKESZLET: TPanel;
    Panel13: TPanel;
    AFAKESZLET: TPanel;
    Panel15: TPanel;
    TRADEKESZLET: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    SUMKESZLET: TPanel;
    VISSZAGOMB: TBitBtn;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    Panel1: TPanel;
    KEZELESIDIJ: TPanel;
    Panel7: TPanel;
    FOGLALO: TPanel;
    WUSDFORINT: TPanel;

    procedure VisszaGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure TablaTorles;
    procedure Adatbeolvasas;
    procedure Adatkijelzes;
    procedure ibnyitas(_ukaz: string);
    function FtForm(_int: integer): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PTARKESZ: TPTARKESZ;
  _height,_width,_top,_left,_valdarab: word;
  _wuusdkeszlet,_wuHufKeszlet,_wuAfaKeszlet: integer;
  _hufkeszlet,_valkeszlet,_tradekeszlet: integer;
  _sumkeszlet,_zaro,_wusdft,_kezelesidij,_foglalobjegy: integer;
  _pcs,_tradepath,_vnem,_foglalodnem: string;
  _elsz,_usdarf: real;

function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll' name 'regeneralorutin';

function penztarikeszletek: integer; stdcall;

implementation

{$R *.dfm}

function penztarikeszletek: integer; stdcall;

begin
  Ptarkesz := TPtarkesz.create(Nil);
  result := Ptarkesz.Showmodal;
  Ptarkesz.Free;
end;


procedure TPTARKESZ.VisszaGombClick(Sender: TObject);
begin
  mODALRESULT := 1;
end;


procedure TPTARKESZ.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top  := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);
   Top  := _top + 15;
   Left := _left + 500;

   Height := 737;
   Width  := 485;

   Tablatorles;

   regeneralorutin(0);

   Adatbeolvasas;
   Adatkijelzes;
   Activecontrol := Visszagomb;
end;

procedure TPtarKesz.TablaTorles;

begin
  Ftkeszlet.Caption     := '';
  ValutaKeszlet.Caption := '';
  Kezelesidij.Caption   := '';
  Wuusdkeszlet.Caption  := '';
  Wusdforint.Caption    := '';
  WuHufKeszlet.Caption  := '';
  Afakeszlet.Caption    := '';
  Tradekeszlet.Caption  := '';
  Foglalo.Caption       := '';
  SumKeszlet.Caption    := '';
end;

// =============================================================================
                     procedure TPtarkesz.Adatbeolvasas;
// =============================================================================


var _aktertek: real;

begin
  ibdbase.close;
  ibdbase.DatabaseName := 'C:\valuta\database\valuta.fdb';

  _wuUsdKeszlet := 0;
  _wuHufKeszlet := 0;
  _wuAfaKeszlet := 0;

  _pcs := 'SELECT * FROM WUAFAADATOK';
  ibNyitas(_pcs);
  with ibQuery do
    begin
      _wuUsdKeszlet := FieldByName('WUDOLLARKESZLET').asInteger;
      _wuHufKeszlet := FieldByNAme('WUFORINTKESZLET').asInteger;
      _wuAfaKeszlet := FieldByNAme('OSSZESAFAKESZLET').asInteger;
    end;
  ibquery.close;
  ibdbase.close;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM KEZELESIDATA';
  ibNyitas(_pcs);

  _kezelesidij := ibQuery.FieldByName('AKTKEZELESIDIJ').asInteger;
  ibquery.close;
  ibdbase.close;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM FOGLALOKESZLET';
  ibNyitas(_pcs);
  _valDarab := ibQuery.FieldByName('VALDARAB').asInteger;
  _foglalodnem := ibquery.FieldByNAme('V0').asString;
  _foglalobjegy := ibquery.FieldByName('K0').asInteger;
  ibquery.close;
  ibdbase.close;

  if _valdarab=0 then
    begin
      _foglalodnem := '';
      _foglalobjegy := 0;
    end;

  // ---------------------------------------------------------------------------

  _valkeszlet := 0;
  _hufkeszlet := 0;
  _usdarf     := 0;

  _pcs := 'SELECT * FROM ARFOLYAM';
  ibNyitas(_pcs);
  while not Ibquery.eof do
    begin
      with Ibquery do
        begin
          _vnem := FieldByNAme('VALUTANEM').asString;
          _zaro := FieldByName('ZARO').asInteger;
          _elsz := FieldByName('ELSZAMOLASIARFOLYAM').asFloat;
        end;
      _aktertek := _zaro*_elsz/100;
      if _vnem='JPY' then _aktertek := _aktertek/10;
      if _vnem='HUF' then _hufkeszlet := _zaro
      else _valkeszlet := _valkeszlet + trunc(_aktertek);
      if _vnem='USD' then _usdarf := _elsz;
      Ibquery.next;
    end;
  ibquery.close;
  ibdbase.close;

   // ---------------------------------------------------------------------------

  _tradekeszlet := 0;
  _tradepath := 'c:\valuta\database\trade.fdb';
  if FileExists(_tradePath) then
    begin
      ibdbase.close;
      ibdbase.databasename := _tradePath;
      _pcs := 'SELECT * FROM PARAMETERS';
      ibNyitas(_pcs);
      _tradekeszlet := Ibquery.FieldByName('PILLALLAS').asInteger;
    end;
  ibquery.close;
  ibdbase.close;
end;

procedure TPtarkesz.ibnyitas(_ukaz: string);

begin
  ibdbase.connected := true;
  with Ibquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      Open;
      First;
    end;
end;

procedure TPtarkesz.Adatkijelzes;


begin
  _wusdft := trunc(_usdarf*_wuusdkeszlet/100);
  _sumkeszlet := _hufkeszlet+_valkeszlet+_wusdft+_wuafakeszlet+_tradekeszlet+_wuHufkeszlet+_kezelesidij;

  Ftkeszlet.Caption     := Ftform(_hufkeszlet)+' Ft';
  ValutaKeszlet.Caption := FtForm(_valkeszlet)+' Ft';
  KezelesiDij.Caption   := FtForm(_kezelesidij)+ ' Ft';

  if _wuUsdkeszlet>0 then
    begin
      WuUsdKeszlet.Caption  := Ftform(_wuUsdKeszlet);
      WusdForint.Caption := '('+Ftform(_wusdFt)+' Ft)';
    end;
  if _wuHufkeszlet>0 then WuHufkeszlet.Caption  := Ftform(_wuHufkeszlet);

  if _wuAfakeszlet>0 then Afakeszlet.Caption := FtForm(_wuAfaKeszlet)+ ' Ft';
  if _tradekeszlet>0 then TradeKeszlet.Caption := Ftform(_tradekeszlet)+ ' Ft';

  if _valdarab>0 then Foglalo.Caption := FtForm(_foglalobjegy)+' '+_foglalodnem;

  SumKeszlet.Caption    := Ftform(_sumkeszlet)+ ' Ft';
  Alappanel.Repaint;
end;

function TPTarkesz.FtForm(_int: integer): string;

var _wt,_f1: byte;

begin
  result := inttostr(_int);
  if _int<1000 then exit;

  _wt := length(result);

  if _int>=1000000 then
    begin
      _f1 := _wt-6;
      result := leftstr(result,_f1)+','
                          +midstr(result,_f1+1,3)+','+midstr(result,_f1+4,3);
      exit;
    end;

  _f1 := _wt-3;
  result := Leftstr(result,_f1)+','+midstr(result,_f1+1,3);
end;


end.
