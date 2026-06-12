unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, IBDatabase, IBCustomDataSet, IBQuery, IBTable,
  unit1, strutils, ExtCtrls;

type
  THAVIEGYENLEG = class(TForm)
    Label1: TLabel;
    STRADEQUERY: TIBQuery;
    STRADETRANZ: TIBTransaction;
    STRADEDBASE: TIBDatabase;
    HAVITABLA: TIBTable;
    HAVIQUERY: TIBQuery;
    HAVIDBASE: TIBDatabase;
    HAVITRANZ: TIBTransaction;
    INDITO: TTimer;
    EVPANEL: TPanel;
    HONAPPANEL: TPanel;
    IRODAPANEL: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure EgyevEgyenlege;
    procedure HNyitoBedolgozas;
    procedure EgyenlegKeszites;
    procedure HavitablaMake(_eev: integer);

    function Nulele(_int: integer):string;
    function VanHaviTabla(_hev: integer): boolean;
    procedure INDITOTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HAVIEGYENLEG: THAVIEGYENLEG;
  _evtizeds,_aktevs: string;
  _utev,_utho: integer;
  _irodaszam,_ertektar,_osszeg,_utiroda: Integer;
  _tipus,_datum,_feltetel,_tavalys: string;
  _matrica,_telefon,_atadas,_nyito,_zaro: integer;
  _hnyito,_hzaro: array[1..150] of integer;

implementation

{$R *.dfm}


// =============================================================================
            procedure THAVIEGYENLEG.FormActivate(Sender: TObject);
// =============================================================================

begin
   top := 300;
   Left := 250;

  // Az összesítendö év meghatározása ....

  _aktevs := inttostr(_egyaktev);
  Indito.Enabled := True;
end;

// =============================================================================
              procedure THAVIEGYENLEG.INDITOTimer(Sender: TObject);
// =============================================================================

var i: integer;

begin
  INDITO.Enabled := FALSE;
    for i := 1 to 150 do
    begin
      _hnyito[i] := 0;
      _hZaro[i]  := 0;
    end;
  Evpanel.Caption := _aktevs;
  Evpanel.Repaint;
  Haviegyenleg.Repaint;
  EgyevEgyenlege;
  ModalResult := 1;
end;

// =============================================================================
                     procedure THaviegyenleg.EgyevEgyenlege;
// =============================================================================


var _like: string;
    _aktzaro,i: integer;

begin

   HaviTablamake(_egyaktev);
   _aktevs := inttostr(_egyaktev);

  // ---------------------------------------------------------------------------
  // Az összesitendő év teljes havitábláját kiüritjük:

  Havidbase.Connected := true;
  Havitranz.StartTransaction;
  with HaviQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('DELETE FROM HAVI'+_aktevs);
      ExecSql;
    end;
  Havitranz.Commit;
  Havidbase.close;

  // ---------------------------------------------------------------------------

  Havidbase.Connected := true;
  if havitranz.InTransaction then Havitranz.Commit;
  Havitranz.StartTransaction;
  for i := 1 to 150 do
    begin
      _aktzaro := _hZaro[i];
      _aktertekTar := Form1.ScanErtektar(i);
      if _aktZaro<>0 then
        begin
          _pcs := 'INSERT INTO HAVI'+_AKTEVS+' (IRODASZAM,ERTEKTAR,NYITO,HONAP)'+_sorveg;
          _pcs := _PCS + 'VALUES ('+ inttostr(i)+','+inttostr(_aktertektar)+','+inttostr(_aktzaro)+',1)';
          with HaviQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              ExecSql;
            end;
        end;
    end;
  HaviTranz.Commit;
  Havidbase.close;

  // -------------------------------------------------------
  // Az adatokat a STRADE adabázistáblából nyerjük ki
  // csak az összesítendő év adatait kell figyelembe venni
  //

  _like := chr(39) + _aktevs + '%' + chr(39);
   _pcs := 'SELECT * FROM STRADE' + _sorveg;
   _pcs := _pcs + 'WHERE DATUM LIKE ' + _like;

   Stradedbase.Connected := True;
   with StradeQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
     end;

   // A STRADE adatbázistáblából soronként olvassuk az adatokat:

   while not StradeQuery.eof do
     begin
       with StradeQuery do
         begin
           _irodaszam := FieldByName('IRODASZAM').asInteger;
           _ertektar  := Fieldbyname('ERTEKTAR').asInteger;
           _osszeg    := FieldByName('BEFIZETVE').asInteger;
           _tipus     := FieldByName('TIPUS').ASSTRING;
           _datum     := FieldByName('DATUM').asstring;
         end;

       // A kiolvasott rekord irodaszámát és hónapját kijelezzük:

       _akthonap := strtoint(midstr(_datum,6,2));
       Honappanel.Caption := inttostr(_akthonap);
       Honappanel.Repaint;

       IrodaPanel.Caption := inttostr(_IRODASZAM);
       IrodaPanel.Repaint;

       // ----------------------------------------------------------------------
       // Elöször megnézi, hogy ennek az irodának ebben a hónapban van-e
       // már bejegyzett rekordja:

       _pcs := 'SELECT * FROM HAVI'+_aktevs + _sorveg;
       _feltetel := 'WHERE (IRODASZAM='+inttostr(_irodaszam)+') AND (HONAP='+inttostr(_akthonap)+')';
       _pcs := _pcs + _feltetel;

       Havidbase.Connected := true;
       with HaviQuery do
         begin
           Close;
           sql.Clear;
           sql.Add(_pcs);
           Open;
           First;
           _recno := recno;
         end;

       _matrica := 0;
       _telefon := 0;
       _atadas  := 0;

       // Amennyiben van már ennek az irodának erre a hónapra bejegyzett
       // rekordja, az eddigi forgalmi adatokat kiolvassuk, ha még nincs
       // bejegyzés akkor a forgalmi adatok nullák:

       if _recno>0 then
         begin
           with Haviquery do
             begin
               _matrica := FieldbyName('MATRICA').asInteger;
               _telefon := FieldByName('TELEFON').asInteger;
               _atadas  := FieldByName('ATADAS').asInteger;
             end;
         end;

       HaviQuery.close;
       HaviDbase.close;

       // -------------------------------------------------------------------
       // Ha már volt adatbejegyzése ennek az irodának erre a hónapra, akkor
       // frissiteni kell a rekord forgalmi adazait

       if _recno>0 then
         begin
           _pcs := 'UPDATE HAVI'+_aktevs+' SET ';
           if _tipus='M' then _pcs := _pcs + 'MATRICA='+inttostr(_matrica+_osszeg);
           if _tipus='T' then _pcs := _pcs + 'TELEFON='+inttostr(_telefon+_osszeg);
           if _tipus='F' then _pcs := _pcs + 'ATADAS='+inttostr(_atadas+_osszeg);
           _pcs := _pcs + _feltetel;
         end else

         //  Ha nég nem volt ennek az irodának erre a hónapra bejegyzése, akkor
         //  ez lesz az első bejegyzés:

         begin
           _pcs := 'INSERT INTO HAVI'+_aktevs+' (MATRICA,TELEFON,ATADAS,IRODASZAM,ERTEKTAR,HONAP)'+_sorveg;
           if _tipus='M' then _matrica := _osszeg;
           if _tipus='T' then _telefon := _osszeg;
           if _tipus='F' then _atadas  := _osszeg;

           _pcs := _pcs + 'VALUES ('+inttostr(_matrica)+',';
           _pcs := _pcs + inttostr(_telefon)+',';
           _pcs := _pcs + inttostr(_atadas)+',';
           _pcs := _pcs + inttostr(_irodaszam)+','+inttostr(_ERTEKTAR)+','+inttostr(_akthonap)+')';
         end;

       Havidbase.Connected := true;
       if HaviTranz.InTransaction then Havitranz.Commit;
       Havitranz.StartTransaction;
         with HaviQuery do
           begin
             Close;
             Sql.Clear;
             sql.Add(_pcs);
             Execsql;
           end;

       Havitranz.Commit;
       Havidbase.Close;

       // Jöhet a következő STRADE rekord:

       StradeQuery.Next;
     end;

   StradeQuery.close;
   Stradedbase.close;

   EgyenlegKeszites;

   if _EGYaktev<_maiev then
     begin
       _EGYaktev := _maiev;
       Egyevegyenlege;
     end;
   Showmessage('AZ EGYENLEG RENDBEN ELKÉSZÍTVE');
end;


// =============================================================================
                     procedure THaviegyenleg.HNyitoBedolgozas;
// =============================================================================


begin
   _tavalys := inttostr(_aktev-1);
   _pcs := 'SELECT * FROM HAVI'+_tavalys+_sorveg;
   _pcs := _pcs + 'ORDER BY IRODASZAM,HONAP';

   HaviDbase.connected := True;
   with HaviQuery do
     begin
       Close;
       sql.Clear;
       sql.Add(_pcs);
       Open;
       First;
     end;

   while not HaviQuery.eof do
     begin
       _irodaszam := HaviQuery.FieldByName('IRODASZAM').asInteger;
       _nyito := Haviquery.FieldByname('ZARO').asInteger;

       _hnyito[_irodaszam] := _nyito;
       Haviquery.next;
     end;
   HaviQuery.Close;
   Havidbase.close;
end;

// =============================================================================
             function THaviegyenleg.Nulele(_int: integer):string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;




// =============================================================================
                       procedure THaviegyenleg.EgyenlegKeszites;
// =============================================================================


begin

  if _EGYaktev>2010 then HNyitoBedolgozas;

  HaviDbase.Connected := True;
  with HaviTabla do
    begin
      IndexName := 'X'+_aktevs+'2';
      Tablename := 'HAVI'+_AKTEVS;
      Open;
      First;
    end;

  _utiroda := 0;
  while not Havitabla.Eof do
    begin
      with HaviTabla do
        begin
          _matrica := FieldByName('MATRICA').asInteger;
          _telefon := FieldByName('TELEFON').asInteger;
          _atadas  := FieldByname('ATADAS').asInteger;
          _aktiroda:= FieldByname('IRODASZAM').asInteger;
          _akthonap:= FieldByName('HONAP').asInteger;
        end;

      Honappanel.Caption := inttostr(_akthonap);
      Honappanel.Repaint;

      Irodapanel.Caption := inttostr(_aktiroda);
      IrodaPanel.Repaint;
      if _aktiroda<>_utiroda then _nyito := _hnyito[_aktiroda];

      _zaro := _nyito + _matrica + _telefon - _atadas;

      with HaviTabla do
        begin
          Edit;
          FieldByName('NYITO').AsInteger := _nyito;
          FieldByName('ZARO').asInteger := _zaro;
          Post;
        end;

      _nyito   := _zaro;
      _utiroda := _aktiroda;
      _hZaro[_aktiroda] := _zaro;

      Havitabla.next;
    end;
  Havitabla.close;
  Havidbase.close;
end;

// =============================================================================
                   procedure THaviegyenleg.HavitablaMake(_eev: integer);
// =============================================================================

var _eevs: string;

begin

  _eevs := inttostr(_eev);
  if VanHaviTabla(_eev) then exit;

  // ---------------------------------------------------------------------------

  HaviDbase.Connected := True;
  if HaviTranz.InTransaction then Havitranz.Commit;
  HaviTranz.StartTransaction;

  _pcs := 'CREATE TABLE HAVI' + _eevs +' ('+_sorveg;
  _pcs := _pcs + 'IRODASZAM SMALLINT,'+_sorveg;
  _pcs := _pcs + 'ERTEKTAR SMALLINT,'+_sorveg;
  _pcs := _pcs + 'HONAP SMALLINT,'+_sorveg;
  _pcs := _pcs + 'NYITO INTEGER,'+_sorveg;
  _pcs := _pcs + 'MATRICA INTEGER,'+_sorveg;
  _pcs := _pcs + 'TELEFON INTEGER,'+_sorveg;
  _pcs := _pcs + 'ATADAS INTEGER,'+_sorveg;
  _pcs := _pcs + 'ZARO INTEGER)';

  with Haviquery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      ExecSql;
    end;

  HaviTranz.Commit;
  Havidbase.close;

  HaviDbase.Connected := True;
  HaviTranz.StartTransaction;

  _pcs := 'CREATE INDEX X' + _eevs + '1' + _sorveg;
  _pcs := _pcs + 'ON HAVI' + _eevs + ' (IRODASZAM)';

   with Haviquery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      ExecSql;
    end;

  HaviTranz.Commit;
  Havidbase.close;

  HaviDbase.Connected := True;
  HaviTranz.StartTransaction;

  _pcs := 'CREATE UNIQUE INDEX X' + _eevs + '2' + _sorveg;
  _pcs := _pcs + 'ON HAVI' + _eevs + ' (IRODASZAM,HONAP)';

   with Haviquery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      ExecSql;
    end;

  HaviTranz.Commit;
  Havidbase.close;
end;

// =============================================================================
                function THaviegyenleg.VanHaviTabla(_hev: integer): boolean;
// =============================================================================

var _hevs: string;

begin
  result := false;
  _hevs := inttostr(_hev);
  _tablanev := 'HAVI'+_hevs;

  Havitabla.Close;
  HaviTabla.TableName := _tablanev;
  HaviDbase.connected := True;
  if Havitabla.Exists then result := True;
end;





end.
