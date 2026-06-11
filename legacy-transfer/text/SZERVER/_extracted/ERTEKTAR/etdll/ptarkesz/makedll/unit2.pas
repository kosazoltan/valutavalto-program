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
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    Panel1: TPanel;
    KEZELESIDIJ: TPanel;
    WUSDFORINT: TPanel;
    BELEPO: TTimer;

    procedure VisszaGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure TablaTorles;
    procedure Adatbeolvasas;
    procedure Adatkijelzes;
    procedure Start(sender: TObject);

    function FtForm(_int: integer): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PTARKESZ: TPTARKESZ;
  _height,_width,_top,_left: word;

  _ftKeszlet,_valutaKeszlet,_kezdijKeszlet,_wusdKeszlet,_wusdftKeszlet: integer;
  _whufkeszlet,_wafakeszlet,_ekerkeszlet,_usdarf,_elszarf,_zaro,_ertek: integer;
  _sumkeszlet: integer;
  _pcs,_aktdnem: string;

function regeneralorutin: integer; stdcall; external 'c:\ertektar\bin\regen.dll' name 'regeneralorutin';
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
  Modalresult := 1;
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

   regeneralorutin;
   belepo.Enabled := True;
end;


procedure TPtarkesz.Start(sender: TObject);

begin

   Belepo.Enabled := false;
   Adatbeolvasas;
   Adatkijelzes;

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
  SumKeszlet.Caption    := '';
end;

// =============================================================================
                     procedure TPtarkesz.Adatbeolvasas;
// =============================================================================

begin
  _valutakeszlet := 0;
  _ftkeszlet     := 0;
  _usdarf        := 0;

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM ARFOLYAM WHERE ZARO>0');
      Open;
    end;

  while not ValutaQuery.Eof do
    begin
      _aktdnem := ValutaQuery.FieldByNAme('VALUTANEM').asstring;
      _elszarf  := ValutaQuery.FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      _zaro    := ValutaQuery.FieldByNAme('ZARO').asinteger;
      if _aktdnem='USD' then _usdarf := _elszarf;


      if _aktdnem='HUF' then _ftKeszlet := _zaro
      else
      begin
        _ertek := round(_elszarf/100*_zaro);
        _valutaKeszlet := _valutakeszlet + _ertek;
      end;

      Valutaquery.Next;
    end;
  ValutaQuery.close;

  // ----------------------------------

  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _wusdkeszlet := FieldByNAme('USDKESZLET').asInteger;
      _whufkeszlet := FieldByNAme('HUFKESZLET').asInteger;
      _wAfakeszlet := FieldByNAme('AFAKESZLET').asInteger;
      Close;
    end;

  _wusdftkeszlet := round(_usdarf/100*_wusdkeszlet);

  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM KEZDIJDATA');
      Open;
      _kezdijkeszlet := FieldByNAme('ZARO').asInteger;
      Close;
    end;

  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM EKERDATA');
      Open;
      _EKERkeszlet := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  Valutadbase.close;
end;


procedure TPtarkesz.Adatkijelzes;


begin
  _sumkeszlet := _ftkeszlet+_valutakeszlet+_kezdijkeszlet;
  _sumkeszlet := _sumkeszlet+_wusdftkeszlet+_whufkeszlet+_wafakeszlet;
  _sumkeszlet := _sumkeszlet+_ekerkeszlet;

  Ftkeszlet.Caption     := Ftform(_ftkeszlet)+' Ft';
  ValutaKeszlet.Caption := FtForm(_valutakeszlet)+' Ft';
  KezelesiDij.Caption   := FtForm(_kezdijkeszlet)+ ' Ft';

  WuUsdKeszlet.Caption  := Ftform(_wUsdKeszlet);
  WusdForint.Caption := '('+Ftform(_wUSDFTkeszlet)+' Ft)';
  WuHufkeszlet.Caption  := Ftform(_wHufkeszlet);

  Afakeszlet.Caption := FtForm(_wAfaKeszlet)+ ' Ft';
  TradeKeszlet.Caption := Ftform(_EKERkeszlet)+ ' Ft';

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