unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, UNIT1, IBDatabase, DB, IBCustomDataSet, IBTable,
  ExtCtrls, Grids, DBGrids, IBQuery,strutils;

type
  TBEMUTATO = class(TForm)
    visszagomb: TButton;
    KULDORACS: TDBGrid;
    FOGADORACS: TDBGrid;
    KULDOPANEL: TPanel;
    FOGADOPANEL: TPanel;
    KULDODBASE: TIBDatabase;
    KULDOTRANZ: TIBTransaction;
    FOGADODBASE: TIBDatabase;
    FOGADOTRANZ: TIBTransaction;
    KULDOQUERY: TIBQuery;
    FOGADOQUERY: TIBQuery;
    KULDOSOURCE: TDataSource;
    FOGADOSOURCE: TDataSource;
    KSUMPANEL: TPanel;
    FSUMPANEL: TPanel;
    KULDOQUERYDATUM: TIBStringField;
    KULDOQUERYIDO: TIBStringField;
    KULDOQUERYBIZONYLATSZAM: TIBStringField;
    KULDOQUERYTIPUS: TIBStringField;
    KULDOQUERYOSSZESEN: TIntegerField;
    KULDOQUERYNETTO: TIntegerField;
    KULDOQUERYTRANZDIJ: TIntegerField;
    KULDOQUERYUGYFELTIPUS: TIBStringField;
    KULDOQUERYUGYFELSZAM: TIntegerField;
    KULDOQUERYUGYFELNEV: TIBStringField;
    KULDOQUERYTETEL: TIntegerField;
    KULDOQUERYPENZTAROSNEV: TIBStringField;
    KULDOQUERYIDKOD: TIBStringField;
    KULDOQUERYPENZTAR: TIBStringField;
    KULDOQUERYTRBPENZTAR: TIBStringField;
    KULDOQUERYPLOMBASZAM: TIBStringField;
    KULDOQUERYSZALLITONEV: TIBStringField;
    KULDOQUERYKEZELESIDIJ: TIntegerField;
    KULDOQUERYSTORNO: TSmallintField;
    KULDOQUERYSTORNOBIZONYLAT: TIBStringField;
    KULDOQUERYBIZONYLATSZAM1: TIBStringField;
    KULDOQUERYDATUM1: TIBStringField;
    KULDOQUERYVALUTANEM: TIBStringField;
    KULDOQUERYBANKJEGY: TIntegerField;
    KULDOQUERYARFOLYAM: TFloatField;
    KULDOQUERYELSZAMOLASIARFOLYAM: TFloatField;
    KULDOQUERYFORINTERTEK: TIntegerField;
    KULDOQUERYELOJEL: TIBStringField;
    KULDOQUERYCOIN: TSmallintField;
    KULDOQUERYSTORNO1: TSmallintField;
    FOGADOQUERYDATUM: TIBStringField;
    FOGADOQUERYIDO: TIBStringField;
    FOGADOQUERYBIZONYLATSZAM: TIBStringField;
    FOGADOQUERYTIPUS: TIBStringField;
    FOGADOQUERYOSSZESEN: TIntegerField;
    FOGADOQUERYNETTO: TIntegerField;
    FOGADOQUERYTRANZDIJ: TIntegerField;
    FOGADOQUERYUGYFELTIPUS: TIBStringField;
    FOGADOQUERYUGYFELSZAM: TIntegerField;
    FOGADOQUERYUGYFELNEV: TIBStringField;
    FOGADOQUERYTETEL: TIntegerField;
    FOGADOQUERYPENZTAROSNEV: TIBStringField;
    FOGADOQUERYIDKOD: TIBStringField;
    FOGADOQUERYPENZTAR: TIBStringField;
    FOGADOQUERYTRBPENZTAR: TIBStringField;
    FOGADOQUERYPLOMBASZAM: TIBStringField;
    FOGADOQUERYSZALLITONEV: TIBStringField;
    FOGADOQUERYKEZELESIDIJ: TIntegerField;
    FOGADOQUERYSTORNO: TSmallintField;
    FOGADOQUERYSTORNOBIZONYLAT: TIBStringField;
    FOGADOQUERYBIZONYLATSZAM1: TIBStringField;
    FOGADOQUERYDATUM1: TIBStringField;
    FOGADOQUERYVALUTANEM: TIBStringField;
    FOGADOQUERYBANKJEGY: TIntegerField;
    FOGADOQUERYARFOLYAM: TFloatField;
    FOGADOQUERYELSZAMOLASIARFOLYAM: TFloatField;
    FOGADOQUERYFORINTERTEK: TIntegerField;
    FOGADOQUERYELOJEL: TIBStringField;
    FOGADOQUERYCOIN: TSmallintField;
    FOGADOQUERYSTORNO1: TSmallintField;
    Shape1: TShape;
    Panel1: TPanel;
    procedure visszagombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function Ftform(_i: integer): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BEMUTATO: TBEMUTATO;

implementation

{$R *.dfm}

procedure TBEMUTATO.visszagombClick(Sender: TObject);
begin
  kULDODBASE.CLOSE;
  Kuldoquery.close;

  FogadoDbase.close;
  FogadoQuery.close;
  
  mODALRESULT := 1;
end;

procedure TBEMUTATO.FormActivate(Sender: TObject);

var _kinf,_finf: string;
    _KSUM,_kbj,_fsum: integer;
    _btop,_bleft: word;

begin
   // _kuldo, _fogado, _valutanem

  _btop := trunc((_height-640)/2);
  _bleft:= trunc((_width-1024)/2);

  Top := _bTop;
  Left := _bLeft;


  _kinf := inttostr(_kuldo)+'. pénztár ' + _valutanem+' küldései '+inttostr(_fogado)
                                        + '. pénztárnak';
  _finf := inttostr(_fogado)+'. pénztár ' + _valutanem + ' fogadásai '+inttostr(_kuldo)
                                        + '. pénztártól';

  KuldoPanel.Caption := _kInf;
  FogadoPanel.Caption := _finf;

  Kuldopanel.Repaint;
  FogadoPanel.Repaint;

  KuldoSource.Enabled := False;
  FogadoSource.Enabled := False;

  Kuldodbase.close;
  _fdbpath := 'c:\receptor\database\v'+inttostr(_kuldo)+'.fdb';
  KUldoDbase.databasename := _fdbPath;

  _pcs := 'SELECT KFEJ.*, KTET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_fejtablanev+' KFEJ JOIN '+_tettablanev+' KTET'+_sorveg;
  _pcs := _pcs + 'ON KFEJ.BIZONYLATSZAM=KTET.BIZONYLATSZAM'+_sorveg;

  _pcs := _pcs + 'WHERE (KFEJ.STORNO=1) AND (KFEJ.BIZONYLATSZAM LIKE ';
  _pcs := _pcs + chr(39) + 'F%' + chr(39)+') AND (KFEJ.PENZTAR=';
  _pcs := _pcs + chr(39) + inttostr(_fogado) + chr(39) + ') AND (KTET.VALUTANEM=';
  _pcs := _pcs + chr(39) + _valutanem + chr(39) + ')';

  Kuldodbase.Connected := true;
  with kuldoQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  _ksum := 0;
  while not KuldoQuery.eof do
    begin
      _kbj := KuldoQuery.FieldByName('BANKJEGY').asInteger;
      _ksum := _ksum + _kbj;
      KuldoQuery.Next;
    end;

  KuldoQuery.First;

  // -----------------------------------------------------------


  Fogadodbase.close;
  _fdbpath := 'c:\receptor\database\v'+inttostr(_fogado)+'.fdb';
  FogadoDbase.databasename := _fdbPath;

  _pcs := 'SELECT FFEJ.*, FTET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_fejtablanev+' FFEJ JOIN '+_tettablanev+' FTET'+_sorveg;
  _pcs := _pcs + 'ON FFEJ.BIZONYLATSZAM=FTET.BIZONYLATSZAM'+_sorveg;

  _pcs := _pcs + 'WHERE (FFEJ.STORNO=1) AND (FFEJ.BIZONYLATSZAM LIKE ';
  _pcs := _pcs + chr(39) + 'U%' + chr(39)+') AND (FFEJ.PENZTAR=';
  _pcs := _pcs + chr(39) + inttostr(_kuldo) + chr(39) + ') AND (FTET.VALUTANEM=';
  _pcs := _pcs + chr(39) + _valutanem + chr(39) + ')';

  FogadoDbase.Connected := true;
  with FogadoQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  _fsum := 0;
  while not FogadoQuery.eof do
    begin
      _kbj := FogadoQuery.FieldByName('BANKJEGY').asInteger;
      _Fsum := _Fsum + _kbj;
      FogadoQuery.Next;
    end;
  FogadoQuery.First;

  _kinf := 'Összesen küldött: '+ ftform(_ksum)+' '+_valutanem+'-t';
  _finf := 'Összesen kapott: '+ftform(_fsum)+ ' '+_valutanem+'-t';
  KsumPanel.Caption := _kinf;
  FsumPanel.Caption := _finf;
  KsumPanel.Repaint;
  Fsumpanel.Repaint;

   KuldoSource.Enabled := True;
  FogadoSource.Enabled := True;



end;

function TBemutato.Ftform(_i: integer): string;

var _wr,_f1: byte;

begin
  result := inttostr(_i);
  _wr := length(result);
  if _wr<4 then exit;

  if _wr>6 then
    begin
      _f1 := _wr-6;
      result := leftstr(result,_f1)+','+midstr(result,_f1+1,3)+','+midstr(result,_f1+4,3);
      exit;
    end;

  _f1 := _wr-3;
  result := leftstr(result,_f1)+','+midstr(result,_f1+1,3);
end;


end.
