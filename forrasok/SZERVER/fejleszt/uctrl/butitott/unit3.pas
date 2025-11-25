unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable, strutils, ExtCtrls, ComCtrls;

type
  TADATFELTOLTES = class(TForm)
    BQUERY: TIBQuery;
    BDBASE: TIBDatabase;
    BTRANZ: TIBTransaction;
    KILEPO: TTimer;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    CSIK: TProgressBar;
    Label1: TLabel;
    Shape1: TShape;
    VTABLA: TIBTable;
    COUNTPANEL: TPanel;
    MENETPANEL: TPanel;

    procedure FormActivate(Sender: TObject);

    procedure BlokkFeliro;
    function UJBedolgozo: integer;
    function Ezertektar(_et: byte): boolean;
    procedure KILEPOTimer(Sender: TObject);
    procedure TetelBeolvasas;

    procedure Bparancs(_ukaz: string);
 

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ADATFELTOLTES: TADATFELTOLTES;

  _top,_left,_mresult,_pp,_blokkdarab,_aktels,_aktarf: word;
  _pt,_wp,_akttet: byte;

  _farok,_aktfdbPath,_plomba,_p2cs,_bizonylat: string;
  _aktdat,_aktido,_aktntab,_pts,_aktid,_aktval,_aktbiz: string;
  _sorszam,_aktkdj,_aktbjy,_aktfte,_aktfiz,_aktsrs: integer;

  _val: array[1..8192,1..6] of string;
  _arf,_els: array[1..8192,1..6] of word;
  _bjy,_fte: array[1..8192,1..6] of integer;

  _biz,_dat,_ido,_pid,_nTab: array[1..8192] of string;
  _tval: array[1..6] of string;
  _tarf,_tels: array[1..6] of word;
  _tbjy,_tFte: array[1..6] of integer;

  _sors,_fiz,_kdj: array[1..8192] of integer;
  _tet: array[1..8192] of byte;


implementation

uses Unit1;

{$R *.dfm}


// =============================================================================
           procedure TADATFELTOLTES.FormActivate(Sender: TObject);
// =============================================================================

begin
  _top  := Form1.top;
  _left := Form1.left;

  top := _top + 160;
  left := _left+ 330;
  Repaint;

  _mResult := UjBedolgozo;  // 1 vagy 2
  Kilepo.enabled := true;
end;


/////////////////////  INNWN AZ UJ PROGRAM //////////////////////////////////

function TAdatFeltoltes.Ujbedolgozo: integer;

var _szm: string;

begin
  result := 2;

  _farok := midstr(_toldatums,3,2)+midstr(_toldatums,6,2);
  _bf := 'BF' + _farok;
  _bt := 'BT' + _farok;

  _pcs := 'SELECT * FROM ' + _bf + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (PLOMBASZAM>'+CHR(39)+'@'+CHR(39)+')';
  _pcs := _pcs + ' AND (DATUM>='+chr(39)+_toldatums+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igdatums+chr(39)+')';

  _pt := 1;
  menetPanel.Caption := '1. MENET';
  menetpanel.repaint;

  csik.max := 168;

  while _pt<=168 do
    begin
      Csik.Position := _pt;

      CountPanel.caption := inttostr(168-_pt);
      CountPanel.repaint;

      if _penztarnev[_pt]='-' then
        begin
          inc(_pt);
          Continue;
        end;

      // Van ilyen adatbázis ?

      _aktfdbpath := _HOST +':c:\receptor\database\v' + inttostr(_pt)+'.FDB';
      if _pt>150 then _aktfdbpath := _HOST +':c:\cartcash\database\v' + inttostr(_pt)+'.FDB';

      // Értéktárban nincs forgalom !

      if ezErtektar(_pt) then
        begin
          inc(_pt);
          continue;
        end;

      // Ha csak pénztárt akarunk listázni csak az aktpenztar jó !

      if _ptTipus='P' then
        begin
          if _pt<>_aktpenztar then
             begin
               inc(_pt);
               Continue;
             end;
        end;

      // Ha egy körzetet akarunk listázni, csak az aktkörzet jó !

      if _pttipus='K' then
        begin
          if _korzet[_pt]<>_aktkorzet then
            begin
              inc(_pt);
              Continue;
            end;
        end;

      // Ha egy KFT-t akarunk listázni, csak az akttcégbetü (vagy Mind) jó !

      If _pttipus='C' then
        begin

          // Ha aktcegbetu='A(LL)' minden pénztárt listázni kell

          if _aktcegbetu<>'A' then
            begin

              // Csak az  aktcegbetu kft jó !
              if _cegbetu[_pt]<>_aktcegbetu then
                begin
                  inc(_pt);
                  Continue;
                end;
            end;
        end;

      // Ez a pénztár megfelel a szürési feltételeknek !

      Vdbase.close;
      vdbase.databasename := _aktfdbpath;   // A penztár adatbázisdára kapcsol
      vdbase.connected := true;

      vtabla.close;
      vtabla.tablename := _bf;

      // Ha a kért havi adatbázis hiányzik, akkor ez a pénztár nem kell !

      if not vtabla.exists then
        begin
          vdbase.close;
          inc(_pt);
          Continue;
        end;

      // Megnyitja a kért havi adatbázis blokkfejeket:

      with vquery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      // Ha az adatbázis üres, jöhet a következõ pénztár:

      if _recno=0 then
        begin
          vquery.close;
          vdbase.close;
          inc(_pt);
          Continue;
        end;

      // Végigmegy a pénztár összes leszürt rekordjain:

      while not vquery.eof do
        begin
          _plomba := trim(Vquery.fieldByName('PLOMBASZAM').asString);
          _wp := length(_plomba);

          // Ha plomba nem a nevtabla+sorszam -> jöhet e következõ rekord:

          if _wp<5 then
            begin
              Vquery.next;
              continue;
            end;

          // Kiszámitjuk a nevtábla sorszámát:

          _szm := midstr(_plomba,5,_wp-4);
          Val(_szm,_sorszam,_code);
          if _code<>0 then _sorszam := 0;

          // Ha itt a sorszám zéró, akkor jöhet a következõ rekord:

          if _sorszam=0 then
            begin
              vquery.next;
              continue;
            end;

          //  Kifejti a névtáblát:
          // Ha a névtabla nem JOGI vagy más értékes NEVTABLA akkor next:

          _nevtabla := leftstr(_plomba,4);
          if (_nevtabla<>'JOGI') AND (midstr(_nevtabla,2,3)<>'NEV') then
            begin
              VQuery.next;
              continue;
            end;


          _bizonylat := trim(Vquery.FieldByNAme('BIZONYLATSZAM').asString);
          if _bizonylat='' then
            begin
              Vquery.next;
              Continue;
            end;

          // Lépteti a sorszám számlálót

          inc(_pp);
          _biz[_pp] := _bizonylat;

          with Vquery do
            begin
              // A fõtömbbe beirja a fejblokk értékes adatokat:

              _dat[_pp] := fieldbyname('DATUM').asString;
              _ido[_pp] := FieldByName('IDO').asString;
              _fiz[_pp] := FieldByNAme('OSSZESEN').asInteger;
              _kdj[_pp] := FieldByName('KEZELESIDIJ').asInteger;
              _tet[_pp] := FieldByName('TETEL').asInteger;
              _pid[_pp] := trim(FieldByNAme('IDKOD').asString);
            end;

          // A fõtömbbe beirja a névtáblát vagy sorszámát

          _ntab[_pp] := _nevtabla;
          _sors[_pp] := _sorszam;

          vQuery.next;
        end;
      Vquery.close;
      Vdbase.close;

      // Jöhet e következõ pénztár:

      inc(_pt);
    end;

  // --------------------------------------------------

  // Összesen ennyi fejrekord van a fõtömbben:

  _blokkdarab := _pp;

  // Ha nincs egy rekord sem, akkor nincs adat

  if _blokkDarab=0 then exit;

  // Most beolvassa a blokkfejekhet tartozó blokktételeket:

  TetelBeolvasas;

  // A fõtömb összes rekordját felirja

  BlokkFeliro;

  Result := 1;
end;

// =============================================================================
                   procedure TAdatFeltoltes.blokkfeliro;
// =============================================================================

begin
  _pcs := 'DELETE FROM FEJEK';
  Bparancs(_pcs);

  _pcs := 'DELETE FROM TETELEK';
  Bparancs(_pcs);

  MenetPanel.Caption := '3. MENET';
  MenetPanel.repaint;

  Csik.max := _Blokkdarab;
  _pp := 1;
  while _pp<=_blokkdarab do
    begin
      Csik.position := _pp;

      CountPanel.Caption := inttostr(_blokkdarab-_pp);
      CountPanel.repaint;

      _aktbiz := _biz[_pp];
      _aktdat := _dat[_pp];
      _aktido := _ido[_pp];
      _aktfiz := _fiz[_pp];
      _aktkdj := _kdj[_pp];
      _akttet := _tet[_pp];
      _aktid  := _pid[_pp];
      _aktsrs := _sors[_pp];
      _aktntab:= _nTab[_pp];

      _pts := midstr(_aktbiz,2,3);
      val(_pts,_aktpenztar,_code);
      if _code<>0 then _aktpenztar := 0;

      _t := 1;
      while _t<=_akttet do
        begin
          _tval[_t] := _val[_pp,_t];
          _tarf[_t] := _arf[_pp,_t];
          _tels[_t] := _els[_pp,_t];
          _tbjy[_t] := _bjy[_pp,_t];
          _tfte[_t] := _fte[_pp,_t];
          inc(_t);
        end;

      _pcs := 'INSERT INTO FEJEK (BIZONYLAT,DATUM,IDO,TETEL,FIZETENDO,';
      _pcs := _pcs + 'KEZELESIDIJ,SORSZAM,PENZTAR,PROSID,NEVTABLA)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktbiz + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdat + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktido + chr(39) + ',';
      _pcs := _pcs + inttostr(_akttet) + ',';
      _pcs := _pcs + inttostr(_aktfiz) + ',';
      _pcs := _pcs + inttostr(_aktkdj) + ',';
      _pcs := _pcs + inttostr(_aktsrs) + ',';
      _pcs := _pcs + inttostr(_aktpenztar) + ',';
      _pcs := _pcs + chr(39) + _aktid + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktntab + chr(39) + ')';

      Bparancs(_pcs);

      _T := 1;
      while _t<=_akttet do
        begin
          _aktval := _tval[_t];
          _aktbjy := _tbjy[_t];
          _aktarf := _tArf[_t];
          _aktels := _tEls[_t];
          _aktfte := _tFte[_t];

          _pcs := 'INSERT INTO TETELEK (BIZONYLAT,VALUTANEM,BANKJEGY,ARFOLYAM,';
          _pcs := _pcs + 'ELSZAM,ERTEK)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _aktbiz + chr(39) + ',';
          _pcs := _pcs + chr(39) + _aktval + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktbjy) + ',';
          _pcs := _pcs + inttostr(_aktarf) + ',';
          _pcs := _pcs + inttostr(_aktels) + ',';
          _pcs := _pcs + inttostr(_aktfte) + ')';
          Bparancs(_pcs);

          inc(_t);
        end;

      inc(_pp);
    end;
end;


function TAdatFeltoltes.ezertektar(_et: byte): boolean;

begin
  result := True;
  if (_et=10) or (_et=20) or (_et=40) or (_et=50) or (_et=63) then exit;
  if (_et=85) or (_et=120) or (_et=145) then exit;
  result := False;
end;



procedure TAdatFeltoltes.BParancs(_ukaz: string);

begin
  Bdbase.connected := true;
  if btranz.InTransaction then btranz.Commit;
  Btranz.StartTransaction;

  with Bquery do
    begin
      Close;
      sql.clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  Btranz.Commit;
  Bdbase.close;
end;

// =============================================================================
           procedure TADATFELTOLTES.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  Modalresult := _mResult;
end;


procedure TadatFeltoltes.TetelBeolvasas;

var _utPtar,_apt: byte;
 

begin

  MenetPanel.Caption := '2. MENET';
  MenetPanel.repaint;

  _utPtar := 0;

  Csik.Max := _blokkdarab;

  // Végigmegy az összes rekordot 1-tõl a blokkdarab-ig:

  _pp := 1;
  while _pp<=_blokkdarab do
    begin
      Csik.position := _pp;

      CountPanel.Caption := inttostr(_blokkdarab-_pp);
      CountPanel.repaint;

      // Veszi sorban a bizonylatszámokat:

      _aktbiz := _biz[_pp];
      _pts := midstr(_aktbiz,2,3);
      val(_pts,_apt,_code);
      if _apt=0 then
        begin
          inc(_pp);
          continue;
        end;

      if _code<>0 then _apt := 0;

      if _apt<>_utptar then
        begin
          Vdbase.close;
          _aktfdbpath := _HOST+ ':c:\receptor\database\v'+inttostr(_apt)+'.FDB';
          if _apt>150 then _aktfdbpath :=_HOST+ ':c:\cartcash\database\v'+inttostr(_apt)+'.FDB';
          Vdbase.DatabaseName := _aktfdbpath;
          Vdbase.connected := true;
          _utptar := _apt;
        end;

      _p2cs := 'SELECT * FROM ' + _bt + _sorveg;
      _p2cs := _p2cs + 'WHERE BIZONYLATSZAM=' + chr(39) + _aktbiz + chr(39);

      with Vquery do
        begin
          Close;
          sql.clear;
          sql.add(_p2cs);
          Open;
        end;

      _t := 0;
      while not Vquery.eof do
        begin
          inc(_t);
          _val[_pp,_t] := Vquery.FieldByName('VALUTANEM').asString;
          _arf[_pp,_t] := VQuery.FieldByName('ARFOLYAM').asInteger;
          _els[_pp,_t] := VQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _bjy[_pp,_t] := Vquery.FieldByNAme('BANKJEGY').asInteger;
          _fte[_pp,_t] := Vquery.FieldByName('FORINTERTEK').asInteger;
          Vquery.next;
        end;
      Vquery.close;

      inc(_pp);
    end;
  Vdbase.close;

end;
end.


