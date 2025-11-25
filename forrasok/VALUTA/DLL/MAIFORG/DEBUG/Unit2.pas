unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, ExtCtrls, ComCtrls, DB,strutils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, DBGrids;

type
  TMAIFORGALOMTABLAFORM = class(TForm)
    ESCAPEGOMB: TBitBtn;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    SVFORINTPANEL: TPanel;
    Panel10: TPanel;
    SEFORINTPANEL: TPanel;
    Panel12: TPanel;
    MINDOSSZPANEL: TPanel;
    VALDATATABLA: TIBTable;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    VALUTATABLA: TIBTable;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    VALDATAQUERY: TIBQuery;
    FORGALOMRACS: TDBGrid;
    NAPIZARSOURCE: TDataSource;
    NAPIZARQUERY: TIBQuery;
    NAPIZARDBASE: TIBDatabase;
    NAPIZARTRANZ: TIBTransaction;
    NAPIZARQUERYVALUTANEV: TIBStringField;
    NAPIZARQUERYVETEL: TIntegerField;
    NAPIZARQUERYELADAS: TIntegerField;
    NAPIZARQUERYVETELFORINT: TIntegerField;
    NAPIZARQUERYELADASFORINT: TIntegerField;


    procedure FormActivate(Sender: TObject);
    procedure AlapadatBeolvasas;
    function Scandnem(_ad: string): byte;
    procedure AdatGyujtes;
    procedure Adatfeliras;
    procedure ValutaParancs(_ukaz: string);
    procedure AdatKijelzes;
    function Ftform(_ft: integer): string;
    procedure ESCAPEGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAIFORGALOMTABLAFORM: TMAIFORGALOMTABLAFORM;

   _valutadarab: byte = 27;
   _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                       'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN',
                       'NOK','NZD','PLN','RON','RSD','RUB','SEK','THB','TRY',
                       'UAH','USD');

  _dnev: array[1..27] of string = ('AUSZTRÁL DOLLÁR','BOSNYÁK MÁRKA','BOLGÁR LEVA',
         'BRAZIL REAL','KANADAI DOLLÁR','SVÁJCI FRANK','KINAI JÜAN','CSEH KORONA',
         'DÁN KORONA','EURÓ','ANGOL FONT','HORVÁT KUNA','MAGYAR FORINT','IZRAELI SHAKEL',
         'JAPÁN JEN','MEXIKÓI PESO','NORVÉG KORONA','ÚJZÉLANDI DOLLÁR',
         'LENGYEL ZLOTY','ROMÁN LEI','SZERB DINÁR','OROSZ RUBEL','SVÉD KORONA',
         'THAI BATH','TÖRÖK LIRA','UKRÁN HRIVNYA','USA DOLLÁR');
         
  _pcs,_megnyitottnap,_aktdnem,_bizonylat,_tipus,_kftnev,_farok: string;
  _btetTablanev,_aktdnev: string;
  _sorveg: string = chr(13)+chr(10);
  _vetel,_vetelft,_eladas,_eladasFt: array[1..27] of integer;
  _aktbankjegy,_aktertek,_aktvetel,_aktvetelft,_akteladas,_akteladasft: integer;
  _svForint,_seForint,_ssForint,_kerekites: integer;


  _top,_left,_height,_width: word;
  _xx,_printer,_postterm: byte;

function maiforgalomrutin: integer; stdcall;

implementation

{$R *.dfm}

function maiforgalomrutin: integer; stdcall;
begin
  MaiforgalomTablaForm := TmaiforgalomTablaForm.Create(Nil);
  result := maiforgalomTablaForm.showmodal;
  MaiforgalomTablaForm.free;
end;


// =============================================================================
           procedure TMAIFORGALOMTABLAFORM.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;
begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Width  := 1024;
  Height := 768;

  Alapadatbeolvasas;

  for i := 1 to 27 do
    begin
      _vetel[i] := 0;
      _vetelft[i] := 0;
      _eladas[i] := 0;
      _eladasft[i] := 0;
    end;
  Adatgyujtes;
  Adatfeliras;
  Adatkijelzes;
end;

// =============================================================================
                procedure TmaiForgalomTablaForm.Adatgyujtes;
// =============================================================================

begin
  _xx := 1;
  while _xx<=27 do
    begin
      _vetel[_xx] := 0;
      _eladas[_xx] := 0;
      _vetelft[_xx] := 0;
      _eladasft[_xx] := 0;
      inc(_xx);
    end;

  _svForint := 0;
  _seForint := 0;
  _ssForint := 0;

  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs  + 'WHERE (STORNO=1) AND (DATUM='+chr(39)+_megnyitottnap+chr(39)+')';
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sQl.add(_pcs);
      Open;
    end;

  while not valutaQuery.eof do
    begin
      _tipus := ValutaQuery.FieldbyNAme('TIPUS').asString;
      _kerekites := ValutaQuery.fieldbyname('KEREKITES').asInteger;
      if _tipus='V' then _svforint := _svforint + _kerekites;
      if _tipus='E' then _seForint := _seForint + _kerekites;
      if (_tipus='V') or (_tipus='E') then _ssForint := _ssForint + _kerekites;
      ValutaQuery.next;
    end;
  ValutaQuery.close;

  // ----------------------------------------------------------------------------

  _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs  + 'WHERE (STORNO=1) AND (DATUM='+chr(39)+_megnyitottnap+chr(39)+')';

  with ValutaQuery do
    begin
      close;
      sql.clear;
      sQl.add(_pcs);
      Open;
    end;

  while not valutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.fieldByNAme('VALUTANEM').asstring;
      _xx := scandnem(_aktdnem);
      if _xx=0 then
        begin
          Valutaquery.next;
          Continue;
        end;

      _bizonylat := ValutaQuery.fieldByName('BIZONYLATSZAM').asstring;
      _TIPUS := leftstr(_bizonylat,1);
      if (_tipus<>'V') AND (_tipus<>'E') then
        begin
          Valutaquery.next;
          Continue;
        end;
      _aktbankjegy := ValutaQuery.FieldByNAme('BANKJEGY').asInteger;
      _aktertek := ValutaQuery.FieldByNAme('FORINTERTEK').asInteger;
      if _tipus='V' then
        begin
          _vetel[_xx] := _vetel[_xx] + _aktbankjegy;
          _vetelft[_xx] := _vetelft[_xx] +_aktertek;
          _svForint := _svForint + _aktertek;
          _ssForint := _ssForint + _aktertek;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx] := _eladas[_xx] + _aktbankjegy;
          _eladasft[_xx] := _eladasft[_xx] +_aktertek;
          _seForint := _seForint + _aktertek;
          _ssForint := _ssForint + _aktertek;
        end;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  _farok := midstr(_megnyitottnap,3,2)+midstr(_megnyitottnap,6,2);
  _btetTablanev := 'BT' + _farok;

  _pcs := 'SELECT * FROM ' +_btetTablanev + _sorveg;
  _pcs := _pcs  + 'WHERE (STORNO=1) AND (DATUM='+chr(39)+_megnyitottnap+chr(39)+')';
  Valdatadbase.connected := true;
  with ValdataQuery do
    begin
      close;
      sql.clear;
      sQl.add(_pcs);
      Open;
    end;

  while not valdataQuery.eof do
    begin
      _aktdnem := ValdataQuery.fieldByNAme('VALUTANEM').asstring;
      _xx := scandnem(_aktdnem);
      if _xx=0 then
        begin
          Valdataquery.next;
          Continue;
        end;

      _bizonylat := ValdataQuery.fieldByName('BIZONYLATSZAM').asstring;
      _TIPUS := leftstr(_bizonylat,1);
      if (_tipus<>'V') or (_tipus<>'E') then
        begin
          Valdataquery.next;
          Continue;
        end;
      _aktbankjegy := ValdataQuery.FieldByNAme('BANKJEGY').asInteger;
      _aktertek := ValdataQuery.FieldByNAme('FORINTERTEK').asInteger;
      if _tipus='V' then
        begin
          _vetel[_xx] := _vetel[_xx] + _aktbankjegy;
          _vetelft[_xx] := _vetelft[_xx] +_aktertek;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx] := _eladas[_xx] + _aktbankjegy;
          _eladasft[_xx] := _eladasft[_xx] +_aktertek;
        end;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  Valdatadbase.close;
end;

function TmaiForgalomTablaForm.Scandnem(_ad: string): byte;

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=27 do
    begin
      if _dnem[_y]= _ad then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

procedure TmaiForgalomTablaForm.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := TRIM(FieldByNAme('MEGNYITOTTNAP').asString);
      _printer := FieldByName('PRINTER').asInteger;
      _kftnev := trim(FieldByNAme('KFTNEV').AsString);
      _postterm:= FieldByNAme('POSTTERM').asInteger;

      Close;
      {
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      _homePenztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _homePenztarCim := trim(FieldByNAme('PENZTARCIM').asString);
      Close;
      }
    end;
  Valutadbase.close;
end;

procedure TmaiForgalomTablaForm.Adatfeliras;

begin
  _pcs := 'DELETE FROM NAPIZAR';
  ValutaParancs(_pcs);

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnev := _dnev[_xx];
      _aktvetel := _vetel[_xx];
      _akteladas := _eladas[_xx];
      _aktvetelft := _vetelft[_xx];
      _akteladasft := _eladasft[_xx];

      if (_aktvetel=0) and (_akteladas=0) and (_aktvetelft=0) and (_akteladasft=0) then
        begin
          inc(_xx);
          continue;
        end;

      _pcs := 'INSERT INTO NAPIZAR (VALUTANEV,VETEL,VETELFORINT,ELADAS,ELADASFORINT)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnev + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktvetel) + ',';
      _pcs := _pcs + inttostr(_aktvetelft) + ',';
      _pcs := _pcs + inttostr(_akteladas) + ',';
      _pcs := _pcs + inttostr(_akteladasft) + ')';
      ValutaParancs(_pcs);
      inc(_xx);
    end;
end;

procedure TmaiForgalomTablaForm.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := true;
  if valutatranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;

procedure TmaiForgalomTablaForm.AdatKijelzes;

begin
  _pcs := 'SELECT* FROM NAPIZAR' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';
  
  SvForintPanel.Caption := Ftform(_svForint)+' Ft';
  SeForintPanel.Caption := FtForm(_seForint)+' Ft';
  MindOsszPanel.Caption := FtForm(_ssForint)+' Ft';
  Napizardbase.Connected := true;
  with NapizarQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  NapizarSource.Enabled := true;
  ActiveControl := fORGALOMRACS;    
end;

function TmaiForgalomTablaForm.Ftform(_ft: integer): string;

var _wFt,_f1: byte;

begin
  result := inttostr(_ft);
  _wft := length(result);
  if _wft<4 then exit;

  if _wft>6 then
    begin
      _f1 := _wft-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _wFt-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;


procedure TMAIFORGALOMTABLAFORM.ESCAPEGOMBClick(Sender: TObject);
begin
  NapizarQuery.close;
  Napizardbase.close;
  Modalresult := 1;
end;

end.
