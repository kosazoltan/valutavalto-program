unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, strutils,
  ExtCtrls, IBTable;

type
  TForm1 = class(TForm)
    Button1: TButton;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    RATETRANZ: TIBTransaction;
    RATEDBASE: TIBDatabase;
    RATEQUERY: TIBQuery;
    Panel1: TPanel;
    Panel2: TPanel;
    VTABLA: TIBTable;
    PERMQUERY: TIBQuery;
    PERMDBASE: TIBDatabase;
    PERMTRANZ: TIBTransaction;
    PERMTABLA: TIBTable;
    KILEPO: TTimer;

    procedure Button1Click(Sender: TObject);
    procedure IrodaBeolvasas;
    procedure FormActivate(Sender: TObject);
    procedure RateParancs(_ukaz: string);

    function Nulele(_b: byte): string;
    procedure KILEPOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _arfenev,_farok: STRING;
  _kertev,_kertho: word;

  _ptarnev: array[1..150] of string;
  _etar: array[1..150] of byte;
  _pcs,_fdbpath,_datum,_valutanem,_prosnev,_bizonylat,_trs: string;
  _sorveg: string = chr(13) + chr(10);
  _pt,_engtip,_et: byte;
  _arfolyam,_ujarfolyam,_bankjegy,_elszarf: integer;

implementation

{$R *.dfm}


{
  RATETYPE = F1-NÉL        -> 20
             FÕÉRTÉKTÁROS  -> 32
             ÉRTÉKTÁROS    -> 33
             JUT. MENTES   -> 34
             V.I.P.        -> 11


  RATEPERM.FDB = ENGYYMM: - DATUM         C-10
                          - PENZTAR       INTEGER
                          - VALUTANEM     C-3
                          - BANKJEGY      INTEGER
                          - ARFOLYAM      INTEGER
                          - TRANZAKCIO    C-1  (V,E,K)
                          - ENGEDELYEZO   C-1  (E, F)
                          - KEZDIJTORLES  INTEGER
                          - KONTROL       INTEGER

   ARFEYYMM: - DATUM
             - VALUTANEM
             - ARFOLYAM
             - UJARFOLYAM
             - PENZTAROSNEV
             - BIZONYLATSZAM
             - BANKJEGY
             - ELSZAMARFOLYAM
             - ENGEDMENYTIPUS

   c:\RECEPTOR\SUMRATE.FDB:
         COMPRATE =   DATUM C-10
                      PENZTAR INTEGER
                      VALUTANEM C-3
                      TRANZAKCIO C-1
                      BANKJEGY INTEGER
                      ARFOLYAM INTEGER
                      UJARFOLYAM INTEGER
                      ENGEDELYEZO C-1
                      KEZDIJTORLES SMALL
                      ENGEDMENYTIPUS SMALL
                      PENZTAROSNEV C-25
                      ELSZAMARFOLYAM INTEGER
                      STATUS SMALL



}

// =============================================================================
                 procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin

  _kertev := 2014;
  _kertho := 11;

  _farok := inttostr(_kertev-2000)+nulele(_kertho);
  _arfeNev := 'ARFE' + _farok;

  _engnev := 'ENG' + _farok;

  PermTabla.close;
  PermDbase.Connected := true;
  PermTabla.TableName := _engnev;

  if not Permtabla.Exists then
    begin
      Permdbase.close;
      ShowMessage('NINCS A HÓNAP FELDOLGOZVA !');
      Kilepo.Enabled := True;
      exit;
    end;

  Permdbase.close;

  // Beolvassa a pénztárak neveit és értéktárait, kivéve a bezártakat és
  // értéktárakat - ezt az értéktar=0 jelzi

  IrodaBeolvasas;

  // A CompRate tábla kiüritése:

  _pcs := 'DELETE FROM COMPRATE';
  RateParancs(_pcs);

  // Mind a 150 pénztrászámot kipróbálja:

  _pt := 1;
  while _pt<=150 do
    begin
      // Ha ilyen számú érvényes pénztár nincs, akkor ezt átlépi:

      if _etar[_pt] = 0 then
        begin
          inc(_pt);
          Continue;
        end;

      // Érvényes pénztár számhoz tartozó Adatbázis neve:

      _fdbpath := 'c:\receptor\database\v' + inttostr(_pt)+'.fdb';
      if not fileexists(_fdbPath) then
        begin
          inc(_pt);
          Continue;
        end;

      // Beirja at adatbázisnév elérési útvonalát:

      Panel1.Caption := _fdbPath;
      Panel1.Repaint;

      vdbase.close;
      vdbase.DatabaseName := _fdbPath;
      vdbase.Connected := True;

      // Van ebben az adatbázisban ARFE - tábla ?

      vTabla.close;
      vtabla.TableName := _ARFENEV;
      if not Vtabla.Exists then
        begin

          // Nincs az adatbázisban ARFE tábla:

          Vdbase.close;
          inc(_pt);
          Continue;
        end;

     // Megnyitja az ARFE táblát a föértéktárosi és értéktárosi engedményre

      _pcs := 'SELECT * FROM ' +_ARFENEV + _sorveg;
      _pcs := _pcs + 'WHERE (ENGEDMENYTIPUS=32) OR (ENGEDMENYTIPUS=33)';

      with vQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
        end;

      // Végigmegy az ARFE rekordjain:

      while not vquery.Eof do
       begin
         with Vquery do
           begin
             _datum      := FieldByName('DATUM').asString;
             _valutanem  := FieldByNAme('VALUTANEM').asString;
             _arfolyam   := FieldByNAme('ARFOLYAM').asInteger;
             _ujarfolyam := FieldByNAme('UJARFOLYAM').asInteger;
             _prosnev    := trim(FieldByNAme('PENZTAROSNEV').AsString);
             _bankjegy   := Fieldbyname('BANKJEGY').asInteger;
             _elszarf    := FieldByName('ELSZAMARFOLYAM').asInteger;
             _engtip     := FieldByName('ENGEDMENYTIPUS').asInteger;
             _bizonylat  := FieldByNAme('BIZONYLATSZAM').asString;
           end;

         Panel2.Caption := _datum+' '+_bizonylat;
         Panel2.Repaint;

         _trs := leftstr(_bizonylat,1);
         _ET := _etar[_pt];

         // Az ARFE-bõl kiolvasott rekordot, beirja a COMPRATE-be:

         _pcs := 'INSERT INTO COMPRATE (DATUM,PENZTAR,VALUTANEM,TRANZAKCIO,';
         _pcs := _pcs + 'BANKJEGY,ARFOLYAM,UJARFOLYAM,PENZTAROSNEV,ELSZAMARFOLYAM,';
         _pcs := _pcs + 'ENGEDMENYTIPUS,ERTEKTAR,STATUS)' + _sorveg;

         _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
         _pcs := _pcs + inttostr(_pt) + ',';
         _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
         _pcs := _pcs + chr(39) + _trs + chr(39) + ',';
         _pcs := _pcs + inttostr(_bankjegy) + ',';
         _pcs := _pcs + inttostr(_arfolyam) + ',';
         _pcs := _pcs + inttostr(_ujarfolyam) + ',';
         _pcs := _pcs + chr(39) + _prosnev + chr(39) + ',';
         _pcs := _pcs + inttostr(_elszarf) + ',';
         _pcs := _pcs + inttostr(_engtip) + ',';
         _pcs := _pcs + inttostr(_et) + ',0)';
         RateParancs(_pcs);

         Vquery.Next;
       end;
      Vquery.close;
      Vdbase.close;

      // Jöhet a következö szám a 150-bõl

      inc(_pt);
    end;

   // ----------------------------------------------------------------

  // Most megnyitja az ellenoldalt az ENGYYMM táblát:

  _pcs := 'SELECT *  FROM ' + _engnev;

  Permdbase.connected := true;
  with PermQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  // Végigmegy az ENGYYMM rekordjain:

  while not Permquery.eof do
    begin
      with PermQuery do
        begin
          _datum       := FieldByName('DATUM').AsString;
          _penztar     := FieldByName('PENZTAR').asInteger;
          _valutanem   := FieldByName('VALUTANEM').asString;
          _bankjegy    := FieldByNAme('BANKJEGY').asInteger;
          _arfolyam    := FieldByNAme('ARFOLYAM').asInteger;
          _tranzakcio  := FieldByName('TRANZAKCIO').asString;
          _engedelyezo := FieldByname('ENGEDELYEZO').asString;
          _kezdijtorles:= FieldByNAme('KEZDIJTORLES').asInteger;
        end;


      // Beolvassa az aktuális értéktár számát:

      _aktertektar := _etar[_penztar];

      // Az COMPRATE táblában megkeresi a rekordnak megfelelõ rekordokat:
      // A megfeleltetés: DATUM-PENZTAR-VALUTANEM-BANKJEGY adatokkal.

      _feltetel := '(DATUM='+chr(39)+_datum+chr(39)+')';
      _feltetel := _feltetel + ' AND (PENZTAR=' + inttostr(_penztar)+')';
      _feltetel := _feltetel + ' AND (VALUTANEM='+chr(39)+_valutanem+chr(39)+')';
      _feltetel := _feltetel + ' AND (BANKJEGY='+inttostr(_bankjegy)+')';

      _pcs := 'SELECT * FROM COMPRATE' + _sorveg;
      _pcs := _pcs + 'WHERE ' + _feltetel;

      // Megnézi, hogy van-e megfelelõ rekord a COMPRATE táblában:

      RateDbase.Connected := true;
      with Ratequery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          First;
          _recno := recno;
        end;

      // Nincs megfelelõ rekord !!!

      if _recno=0 then
        begin
          // Bezárja a CompRate táblát:

          ratequery.close;
          ratedbase.close;

          // A féllábas adatokat felirja STATUS=9 kóddal;

          _pcs := 'INSERT INTO COMPRATE (DATUM,PENZTAR,VALUTANEM,TRANZAKCIO,ERTEKTAR';
          _pcs := _pcs + 'BANKJEGY,UJARFOLYAM,ENGEDELYEZO,KEZDIJTORLES,STATUS)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39)+_datum+chr(39)+',';
          _pcs := _pcs + inttostr(_penztar) + ',';
          _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
          _pcs := _pcs + chr(39) + _tranzakcio + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktertektar)+',';
          _pcs := _pcs + inttostr(_bankjegy) + ',';
          _pcs := _pcs + inttostr(_arfolyam) + ',';
          _pcs := _pcs + chr(39) + _engedelyezo + chr(39) + ',';
          _pcs := _pcs + inttostr(_kezdijtorles) + ',';
          _pcs := _pcs + '9)';   //  9 nincs nyom az ARFEYYMM-ban
        end else
        begin
          _farfolyam := Ratequery.FieldByName('UJARFOLYAM').asInteger;
          _fkezdij   := RateQuery.FieldByNAme('KEZDIJTORLES').asInteger;
          _fenged    := Ratequery.FieldByName('ENGEDMENYTIPUS').asInteger;
          _status    := 1;
          _ratetr    := RateQuery.FieldByName('TRANZAKCIO').asString;
          if _ratetr<>_tranzakcio then _status := 5;
          if _farfolyam<>_arfolyam then _status := 7;

          _pcs := 'UPDATE COMPRATE SET TRANZAKCIO='+chr(39)+_ratetr+chr(39)+',';
          _pcs := _pcs +


          _pcs := 'INSERT INTO COMPRATE (TRANZAKCIO';
          _pcs := _pcs + 'ENGEDELYEZO,KEZDIJTORLES,STATUS)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39)+_datum+chr(39)+',';
          _pcs := _pcs + inttostr(_penztar) + ',';
          _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
          _pcs := _pcs + chr(39) + _tranzakcio + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktertektar)+',';
          _pcs := _pcs + inttostr(_bankjegy) + ',';
          _pcs := _pcs + inttostr(_arfolyam) + ',';
          _pcs := _pcs + chr(39) + _engedelyezo + chr(39) + ',';
          _pcs := _pcs + inttostr(_kezdijtorles) + ',';
          _pcs := _pcs + '9)';   //  9 nincs nyom az ARFEYYMM-ban









end;


// =============================================================================
               procedure TForm1.RateParancs(_ukaz: string);
// =============================================================================

begin
  ratedbase.connected := True;
  if ratetranz.InTransaction then ratetranz.Commit;
  ratetranz.StartTransaction;
  with RateQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  RateTranz.Commit;
  Ratedbase.close;
end;

function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
               procedure TForm1.Button1Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;


// =============================================================================
                         PROCEDURE TForm1.Irodabeolvasas;
// =============================================================================

var i,_pt,_et: byte;
    _cl,_st,_pn: string;

begin

  for i := 1 to 150 do _etar[i] := 0;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := 'WHERE (CLOSED<>' + chr(39)+'X'+chr(39)+') AND (STATUS='+chr(39)+'P'+chr(39)+')';
  _pcs := _pcs + 'ORDER BY UZLET';

  recdbase.Connected := True;
  with recquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not recquery.Eof do
    begin
      _pt := Recquery.fieldbyname('UZLET').asInteger;
      _pn := trim(Recquery.FieldByNAme('KESZLETNEV').asString);
      _et := Recquery.fieldByNAme('ERTEKTAR').asInteger;
      _cl := Recquery.FieldByNAme('CLOSED').asString;
      _st := Recquery.FieldByNAme('STATUS').asString;

      if (_cl='X') or (_st<>'P') then
        begin
          recquery.Next;
          continue;
        end;
      _ptarnev[_pt] := _pn;
      _etar[_pt] := _et;
      recquery.next;
    end;
  recquery.close;
  recdbase.close;

end;


// =============================================================================
             procedure TForm1.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

end.
