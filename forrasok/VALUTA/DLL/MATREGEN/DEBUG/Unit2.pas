unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, IBCustomDataSet, IBQuery, ExtCtrls, IBDatabase, DateUtils,
  StrUtils, IBTable;

type
  TForm2 = class(TForm)
    TradeDbase: TIBDatabase;
    TradeTranz: TIBTransaction;
    KILEPES: TTimer;
    TradeQuery: TIBQuery;
    TRADETABLA: TIBTable;
    Panel1: TPanel;
    NAPIQUERY: TIBQuery;
    NAPIDBASE: TIBDatabase;
    NAPITRANZ: TIBTransaction;
    HAVIQUERY: TIBQuery;
    HAVIDBASE: TIBDatabase;
    HAVITRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    function Nulele(_int: integer): string;
    procedure KILEPESTimer(Sender: TObject);
    procedure ErtektartotalRegen;
    procedure TradeParancs(_ukaz: string);
    procedure ValutaParancs(_ukaz: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _sorveg: string = chr(13)+chr(10);
  _trdatum,_pcs,_farok,_tradeNev,_tradePath,_tipus,_evhonap,_hokereso: string;
  _btipus: string;

  _gepfunkcio,_penz,_mresult,_storno: integer;
  _nnyito,_nzaro,_nTelefon,_nVodafon,_nTelenor,_nMatrica,_nPaysafe,_nFeladas: integer;
  _hNyito,_hTelefon,_hVodafon,_hMatrica,_hPaysafe,_hFeladas,_htelenor: integer;
  _telefon,_matrica,_paysafe,_feladas,_hZaro,_vodafon,_telenor: integer;
  _natadas,_natvetel,_osszeg,_atadas,_atvetel,_hatadas,_hatvetel: integer;

function matricaregeneralo: integer;stdcall;


implementation

{$R *.dfm}


// =============================================================================
                function matricaregeneralo:integer;stdcall;
// =============================================================================

begin
  Form2 := Tform2.Create(Nil);
  result := Form2.ShowModal;
  Form2.Free;
end;

// =============================================================================
                 procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  top  := 467;
  Left := 410;

  Panel1.Repaint;
  _mresult := 2;

  // Kiolvassa a regeneráció napját és a gép funkcióját:

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _trDatum := trim(FieldByName('MEGNYITOTTNAP').asstring);
      _gepfunkcio := FieldByName('GEPFUNKCIO').asInteger;
      Close;
    end;

  Valutadbase.close;

  // Az értéktárnál -> értéktár totál-regen:

  if _gepfunkcio=2 then
    begin
      ertektarTotalregen;
      _mresult := 1;
      Kilepes.Enabled := true;
      exit;
    end;

  // A regeneráció havának farka, és havi adatbázistáblája:

  _farok := midstr(_trdatum,3,2)+midstr(_trdatum,6,2);
  _tradeNev := 'TRAD' + _farok;


  // Ha nincs trade adatbázis a gépen, akkor nincs is rajta e-ker

  _tradePath := 'c:\valuta\database\trade.fdb';
  if not fileexists(_tradepath) then
    begin
      Kilepes.Enabled := true;
      exit;
    end;

  Tradedbase.close;
  TradeDbase.DatabaseName := _tradePath;

  // --------------------------------------------------

  // A napi összesitõrõl törli a regenerálás napi rekordot !

  _pcs := 'DELETE FROM NAPIOSSZESITO WHERE DATUM='+chr(39)+_trDatum+chr(39);
  TradeParancs(_pcs);

  // Most megnyitja a napi összesitõt, ahol az utolsó zárás lesz a nyitó !

  _pcs := 'SELECT * FROM NAPIOSSZESITO' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  Tradedbase.Connected := true;
  with Tradequery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _nnyito := FieldByName('ZAROKESZLET').asInteger;
      Close;
    end;

  // ----------------------------------------------------

  // Megnyitom a havi-táblán a zárás napi rekordokra szürve

  _pcs := 'SELECT * FROM ' + _tradenev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39)+_trDatum+chr(39);

  with Tradequery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  // Tételek nullázása:

  _nTelefon := 0;
  _nVodafon := 0;
  _nTelenor := 0;
  _nMatrica := 0;
  _nPaysafe := 0;
  _nFeladas := 0;

  // Kiolvassa, és összegyüjti az egyes tételeket:

  while not Tradequery.Eof do
    begin
      _tipus := TradeQuery.FieldByName('TIPUS').asString;
      _penz  := TradeQuery.FieldByName('FIZETENDO').asInteger;
      _storno:= Tradequery.FieldByName('STORNO').asInteger;

      if _tipus='T' then _nTelefon := _nTelefon + _penz;
      if _tipus='M' then _nMatrica := _nMatrica + _penz;
      if _tipus='V' then _nVodafon := _nVodafon + _penz;
      if _tipus='N' then _nTelenor := _nTelenor + _penz;
      if _tipus='P' then _nPaysafe := _nPaysafe + _penz;
      if (_tipus='F') AND (_storno<>2) AND (_storno<>3) then _nFeladas := _nFeladas + _penz;

      TradeQuery.Next;
    end;
  Tradequery.close;
  Tradedbase.close;

  // Kiszámitja a napi záróösszeget:

  _nzaro := _nnyito+_nTelefon+_nMatrica+_nVodafon+_nTelenor+_nPaysafe-_nFeladas;

  // ----------------------------------------------------------------

  // A regenerálás napjának adatait felirja egy rekorddal a napi összesitöbe:

  _pcs := 'INSERT INTO NAPIOSSZESITO (DATUM,NYITO,TELEFON,MATRICA,VODAFON,';
  _pcs := _pcs + 'TELENOR,PAYSAFECARD,ATADAS,ZARO,ZAROKESZLET)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _trDatum + chr(39) + ',';
  _pcs := _pcs + inttostr(_nnyito) + ',';
  _pcs := _pcs + inttostr(_nTelefon) + ',';
  _pcs := _pcs + inttostr(_nMatrica) + ',';
  _pcs := _pcs + inttostr(_nVodafon) + ',';
  _pcs := _pcs + inttostr(_nTelenor) + ',';
  _pcs := _pcs + inttostr(_nPaySafe) + ',';
  _pcs := _pcs + inttostr(_nFeladas) + ',';
  _pcs := _pcs + inttostr(_nZaro) + ',';
  _pcs := _pcs + inttostr(_nzaro)+')';

  Tradeparancs(_pcs);

  // -----------------------------------------------------------------

  // Megkezdjük a havi összesitést:

  // Az lezárandó év és hónap a dátum elején van:

  // Törötljük a lezárandó hónap rekordját:

  _evhonap  := leftstr(_trDatum,4)+midstr(_trdatum,6,2);
  _hokereso := leftstr(_trdatum,7);

  _pcs := 'DELETE FROM HAVIOSSZESITO' + _sorveg;
  _pcs := _PCS + 'WHERE EVHONAP='+chr(39)+_evhonap+chr(39);
  TradeParancs(_pcs);

  // ------------------------------------------------------------------

  // A havi adatokat nullázza:

  _hTelefon := 0;
  _hVodafon := 0;
  _hTelenor := 0;
  _hMatrica := 0;
  _hPaysafe := 0;
  _hFeladas := 0;

  // A napi összesitõben summázza a hónapra vonatkozó adatokat:


  _pcs := 'SELECT * FROM NAPIOSSZESITO' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM LIKE '+chr(39)+_hokereso+'%'+chr(39);

  Tradedbase.connected := True;
  with TradeQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not TradeQuery.Eof do
    begin
      _telefon := TradeQuery.FieldByNAme('TELEFON').asInteger;
      _matrica := TradeQuery.FieldByNAme('MATRICA').asInteger;
      _vodafon := TradeQuery.FieldByNAme('VODAFON').asInteger;
      _telenor := TradeQuery.FieldByNAme('TELENOR').asInteger;
      _paysafe := TradeQuery.FieldByNAme('PAYSAFECARD').asInteger;
      _feladas := TradeQuery.FieldByNAme('ATADAS').asInteger;

      _hTelefon := _hTelefon + _telefon;
      _hMatrica := _hMatrica + _matrica;
      _hVodafon := _hVodafon + _vodafon;
      _hTelenor := _hTelenor + _telenor;
      _hpaysafe := _hPaysafe + _paysafe;
      _hFeladas := _hFeladas + _feladas;
      Tradequery.Next;
    end;

  Tradequery.close;
  Tradedbase.close;

  // --------------------------------------------------------------------

  // Kiolvassuk az elözö hónap záróját -> regenerálás havi nyitó

  _pcs := 'SELECT * FROM HAVIOSSZESITO' + _sorveg;
  _pcs := _pcs + 'ORDER BY EVHONAP';

  TradeDbase.Connected := True;
  with TradeQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _hnyito := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  Tradedbase.close;

  // ---------------------------------------------------------------------------

  // Kiszámitjuk a havi záróértéket:

  _hZaro := _hnyito + _hTelefon + _hVodafon + _hTelenor + _hMatrica + _HPaysafe - _hFeladas;

  _pcs := 'INSERT INTO HAVIOSSZESITO (EVHONAP,NYITO,TELEFONFORINT,MATRICAFORINT,';
  _pcs := _pcs + 'VODAFONFORINT,TELENORFORINT,PAYSAFEFORINT,FELADASFORINT,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _evhonap + chr(39) + ',';
  _pcs := _pcs + inttostr(_hnyito) + ',';
  _pcs := _pcs + inttostr(_hTelefon) + ',';
  _pcs := _pcs + inttostr(_hMatrica) + ',';
  _pcs := _pcs + inttostr(_hVodafon) + ',';
  _pcs := _pcs + inttostr(_hTelenor) + ',';
  _pcs := _pcs + inttostr(_hPaySafe) + ',';
  _pcs := _pcs + inttostr(_hFeladas) + ',';
  _pcs := _pcs + inttostr(_hZaro) + ')';

  TradeParancs(_pcs);
  if _hzaro<>_nzaro then Showmessage('Valami hiba van az E-kereskedelem zárásánál');

  _pcs := 'UPDATE PARAMETERS SET PILLALLAS=' + inttostr(_nzaro);
  TradeParancs(_pcs);

   _mResult := 1;
   Kilepes.Enabled := true;
end;


// =============================================================================
                 function TForm2.Nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
              procedure TForm2.KILEPESTimer(Sender: TObject);
// =============================================================================

begin
  Kilepes.Enabled := False;
  ModalResult := _mResult;
end;


// =============================================================================
                    procedure TForm2.ErtektarTotalRegen;
// =============================================================================


begin
   // Summázzuk a napi átadást és átvételt:

  _natadas  := 0;
  _natvetel := 0;

  _pcs := 'SELECT * FROM MATBIZONYLAT' + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (DATUM='+chr(39)+_trdatum+chr(39)+')';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not Valutaquery.eof do
    begin
      _btipus := ValutaQuery.FieldByName('BIZONYLATTIPUS').asString;
      _osszeg := ValutaQuery.FieldByName('OSSZEG').asInteger;
      _osszeg := abs(_osszeg);

      if _btipus='B' then _natvetel := _natvetel + _osszeg
      else _natadas := _natadas + _osszeg;

      ValutaQuery.next;
    end;
  Valutaquery.close;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  _pcs := 'DELETE FROM NAPIMAT' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _trdatum + chr(39);
  ValutaParancs(_pcs);

  _pcs := 'SELECT * FROM NAPIMAT' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  Valutadbase.Connected := true;
  with valutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _nNyito := FieldByName('ZARO').asInteger;
      Close;
    end;
  Valutadbase.close;

  _nZaro := _nNyito + _natvetel - _natadas;

  // ---------------------------------------------------------------------------

  _pcs := 'INSERT INTO NAPIMAT (DATUM,NYITO,ATADAS,ATVETEL,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _trDatum + chr(39) + ',';
  _pcs := _pcs + inttostr(_nNyito) + ',';
  _pcs := _pcs + inttostr(_natadas) + ',';
  _pcs := _pcs + inttostr(_natvetel) + ',';
  _pcs := _pcs + inttostr(_nZaro) + ')';

  ValutaParancs(_pcs);

  // ---------------------------------------------------------------------------

  _evhonap  := leftstr(_trdatum,4)+midstr(_trdatum,6,2);
  _hokereso := leftstr(_trdatum,7);

  _pcs := 'SELECT * FROM NAPIMAT' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM LIKE ' + chr(39) + _hokereso + '%' + chr(39);

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

 _hatadas  := 0;
 _hAtvetel := 0;

  while not ValutaQuery.eof do
    begin
      _atadas := ValutaQuery.FieldByNAme('ATADAS').asInteger;
      _atvetel:= ValutaQuery.FieldByname('ATVETEL').asInteger;
      _hAtadas  := _hAtadas + _atadas;
      _hAtvetel := _hAtvetel + _atvetel;
      ValutaQuery.Next;
    end;

  ValutaQuery.close;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  _pcs := 'DELETE FROM HAVIMAT' + _sorveg;
  _pcs := _pcs + 'WHERE EVHONAP=' + chr(39) + _evhonap + chr(39);
  ValutaParancs(_pcs);

  _pcs := 'SELECT * FROM HAVIMAT' + _sorveg;
  _pcs := _pcs + 'ORDER BY EVHONAP';
  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _hnyito := FieldBynAme('ZARO').asInteger;
      Close;
    end;
  Valutadbase.close;

  _hzaro := _hnyito + _hAtvetel - _hAtadas;

  _pcs := 'INSERT INTO HAVIMAT (EVHONAP,NYITO,ATADAS,ATVETEL,ZARO)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _evhonap + chr(39) + ',';
  _pcs := _pcs + inttostr(_hnyito) + ',';
  _pcs := _pcs + inttostr(_hAtadas) + ',';
  _pcs := _pcs + inttostr(_hAtvetel) + ',';
  _pcs := _pcs + inttostr(_hZaro) + ')';
  ValutaParancs(_pcs);

  if _hZaro<>_nZaro then ShowMessage('HIBA AZ E-KER ZÁRÓKÉSZLETÉBEN');

  _pcs := 'UPDATE MATDATA SET AKTKESZLET=' + inttostr(_hzaro);
  ValutaParancs(_pcs);
end;

// =============================================================================
               procedure TForm2.TradeParancs(_ukaz: string);
// =============================================================================

begin
  TradeDbase.connected := True;
  if TradeTranz.InTransaction then Tradetranz.Commit;
  TradeTranz.StartTransaction;

  with TradeQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_ukaz);
      ExecSql;
    end;
  TradeTranz.Commit;
  Tradedbase.close;
end;

// =============================================================================
              procedure TForm2.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := True;
  if ValutaTranz.InTransaction then Valutatranz.Commit;
  ValutaTranz.StartTransaction;

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;
end;

end.
