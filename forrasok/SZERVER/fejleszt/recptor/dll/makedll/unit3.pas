unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DateUtils, StrUtils, ComCtrls, ExtCtrls, DB, IBCustomDataSet,
  IBTable, IBDatabase, StdCtrls, IBQuery;

type
   TTabmaker = class(TForm)

    Csik       : TProgressBar;
    Kilepotimer: TTimer;

    BlokkQuery : TIBQuery;
    BlokkDbase : TIBDatabase;
    BlokkTranz : TIBTransaction;
    BlokkTabla : TIBTable;

    Label1     : TLabel;

    ibTabla    : TIBTable;
    ibQuery    : TIBQuery;
    ibDbase    : TIBDatabase;
    ibTranz    : TIBTransaction;
    KORZETCSIK: TProgressBar;

   // -----------------------------------------

    procedure DnemKodwrite(_vnem: string);
    procedure ForgalomBeolvasas;
    procedure FormActivate(Sender: TObject);
    procedure irodaAdatBeolvasas;
    procedure ibParancs(_ukaz: string);
    procedure InsertProsList(_pnev: string; _iss: integer);
    procedure KeszletBeolvasas;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure ReadElozohonap;
    procedure ReadElozonap;
    procedure RealKodWrite(_real:real);
 //   procedure SumBestchange;
    procedure TextKodwrite(_szo: string);
 //   procedure TombNullazas;
    procedure WordKodWrite(_num: integer);
 //   procedure WriteBestChangeTablo;
 //   procedure WriteTablo;
    procedure WriteKorzetTablo;
    procedure WriteElozohonap;
    procedure WriteElozonap;

    function GetProsSorszam(_ptn: string; _irss: integer):integer;
    function ibOpen(_ukaz: string): integer;
    function Nulele(_int: integer): string;
    function ScanDnem(_devnem:string): integer;
    function ScanErtektar(_et: integer): integer;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Tabmaker      : TTabmaker;

  _tablo        : file of byte;
  _tablonapja   : TDatetime;
  _aktgdbPath   : string;

  _pcs          : string;
  _jelszo       : string;
  _sorveg       : string = chr(13) + chr(10);
  _recno        : integer;
  _aktnap       : byte;

  _bytetomb     : array[1..4096] of byte;

  _tabloev,_tabloho,_evtized,_eloev,_eloho: word;

  _eertektarnev : array[1..8] of string = ('Szekszárd','Szeged','Kecskemét',
                            'Debrecen','Nyíregyháza','Békéscsaba','Pécs',
                            'Kaposvár');

  _dnem         : array[1..22] of string = ('AUD','BGN','CAD','CHF','CNY','CZK','DKK','EUR','GBP',
                      'HRK','HUF','ILS','JPY','NOK','PLN','RON','RSD','RUB','SEK','TRY','UAH','USD');

  _eertektarszam: array[1..8] of integer = (10,20,40,50,63,75,120,145);

  _irodaDarab   : integer;
  _irodanev     : array[1..150] of string;
  _irodaErtektar: array[1..150] of integer;

  _korzetIrodaDarab: array[1..8] of integer;
  _korzetIrodasor  : array[1..8,1..35] of integer;

  // --------------------- Forgalmi adatok -------------------------------------

  _blokkfejnev,_blokktetnev: string;

//  _nvdb,_nedb: array[1..150,1..31] of integer; // napi vételek/eladások száma boltonként
  _nVetel,_nEladas: array[1..35,1..31] of integer;  // irodánkénti napi vétel/eladás összege forintban

  _sumVetel,_sumEladas   : integer;   // az irodák havi összes vétele és eladása forintban
  _sumVUgyfDb,_sumEUgyfDb: word;      // az összes vásárló és eladó ügyfelek száma

  _vevougyfeldarab,_eladoUgyfelDarab: array[1..35] of integer;
  _napivevodarab,_napieladodarab: array[1..35,1..31] of integer;
  _prosdb: array[1..35] of byte;  // irodánként az aktiv pénztárosok száma
  _prosnev: array[1..150,1..8] of string;  // Irodánként felsorolva a max 8 pénztáros neve
  _nPros: array[1..150,1..31] of byte;  // Irodánként naponta, a fõpénztáros sorszáma

  _utDatum,_utBlokknum: string;  // ciklus váltás figyelõ változók
  _aNapok: byte;

  // -------------------- Elözö havi adatok --------------------------------------

  _ehNapok: array[1..150] of byte;  // Elözõ havi munkanapok irodánként
  _ehVasar,_ehEladas: array[1..150] of integer; // elözö havi eladások és vásárlások ft*ban, irodánként
  _ehVdb,_ehEdb: array[1..150] of word; // elözõ havi vevõ és eladó ügyfél darabszáma irodánként

  _farok,_elofarok,_valutanem: string;

  // ----------------------- Készlet adatok ------------------------------------

  _cimtarnev: string;
  _munkanapicimlet: boolean;
  _vankeszlet: boolean;

  _cimsor  : array[1..150,1..22] of string;  // 28 byte hosszu string 1-14 word (lo-hi) a 14 cimlet nemenként és irodánként
  _vkeszlet: array[1..150,1..22] of integer; // Valutakészletek nemenként és irodánként

  // ---------------------- Elözõ napi adatok ----------------------------------

  _enKeszlet: array[1..150,1..22] of integer;  // Elözönapi valutakészletek irodánként, valutanemenként

  // ---------------------------------------------------------------------------

  _tablonap: word; // A tablón szereplõ havi utolsó nap
  _qq,_osszesen: integer;    // ciklusváltozó
  _etss,_irss,_byte: byte; // értéktár- és irodasorszám index
  _urcimsor,_mezo: string;
  _aktkorzetDarab,_aktertekTar: integer;
  _kirss,_aktKorzetIrodaDarab,_valss: byte;
  _aktvevougyfeldarab,_akteladougyfeldarab: integer;
  _aktvkeszlet,_aktenkeszlet,_aktirodaszam: integer;
  _aktertektarszam: integer;



  _munkanap: string;
 function makehavitablo(_para: string): integer; stdcall;


implementation

uses Unit1;

{$R *.dfm}


function makehavitablo(_para: string): integer; stdcall;

begin
  Tabmaker := TTabmaker.Create(Nil);
  _munkanap := _para;
  result := Tabmaker.ShowModal;
  tabmaker.free;
end;



// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
             procedure TTabmaker.FormActivate(Sender: TObject);
// =============================================================================



begin
  Top   := 10;
  Left  := 185;
  Color := $f8e4d8;

  Label1.Repaint;
  Tabmaker.Repaint;

  // A dátumfüggö parameterek kalkulálása .......

  // A _Tablonapja = a tabló dátuma

  _TabloNapja := StrToDate(_Munkanap);   // ezt a napot kell zárni

  // A tabló-nap Farka és az azt megelözö hónap farka (ELOFAROK) meghatározása

  _tabloev := yearof(_tablonapja);   // záró év
  _tabloho := monthof(_tablonapja);  // záró hónap
  _tablonap:= dayof(_tablonapja);      // pl. 9-ike
  _mezo    := 'N'+inttostr(_tablonap);  // N09  pl. 9.-ikén

  // Kikalkulálja a farok és elöfarok stringeket:

  _eloev := _tabloEv;
  _eloho := _tabloho-1;

  if _eloHo=0 then
    begin
      _eloho := 12;
      dec(_eloev);
    end;

  _farok    := nulele(_tabloEv-2000) + nulele(_tabloho);
  _eloFarok := nulele(_eloev-2000) + nulele(_eloho);

  // -------------------------------------------------------------------

  // A blokkfej és -tétel tábla neve:

  _blokkfejnev := 'BF' + _farok;
  _blokktetnev := 'BT' + _farok;
  _cimtarnev   := 'CIMT' + _farok;

  // -----------------------------------------------------------

  IrodaAdatBeolvasas;


  // Mehet az összes körzeten át ívelõ ciklus:

  KorzetCsik.Max := 8;
  _etss := 1;
  while _etss<=8 do

   // =%=%=%=%=%=%=%=%=%=%=%= IRODA CIKLUS %=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=

     begin
       KorzetCsik.Position := _ETSS;
       _aktkorzetIrodaDarab := _korzetirodaDarab[_etss];
       if _aktkorzetIrodaDarab=0 then
         begin
           inc(_etss);
           continue;
         end;
       _kirss := 1;
       Csik.Max := _aktkorzetIrodadarab;
       while _kirss<=_aktKorzetIrodaDarab do
         begin
           Csik.Position := _kirss;
           _aktirodaszam := _korzetIrodaSor[_etss,_kirss];
        //   _aktertektar  := _eertekTarszam[_etss];

           // Az irodaszám alapján meghatározza a GDB path-ját:

           _aktgdbPath := 'c:\receptor\database\v'+inttostr(_aktirodaszam)+'.gdb';

           // Beolvassa az iroda forgalmát _farok hónapban _qq-ik irodában:

           ForgalomBeolvasas;

           // Beolvassa az elözö hónap forgalmi adatait, _qq-ik irodában:

           ReadElozohonap;

           // Beirja az elözöhavi adatokhoz az e-havi forgalmat (overwrite):

           WriteelozoHonap;

           // Beolvassa az utolsó napi készleteket Munkanapit vagy azt megelözöt

           KeszletBeolvasas;

           // Beolvassa az elözönapi Készleteket qq-ik irodában:

           ReadElozoNap;

           // Fel irja a mai készletadatokat, de csak ha azok a mai napik
           WriteElozonap;

           inc(_kirss);
         end;
       WriteKorzetTablo;
       inc(_etss);
     end;


  // Felirja  a tablókat az egyes pénztáraknak:

  Kilepotimer.Enabled := true;
end;

// =============================================================================
                  procedure TTabmaker.IrodaAdatBeolvasas;  // oke
// =============================================================================

// Feltölti a következõ tömböket: _irodanev[irodaszam]
//                                _irodaErtektar[irodaszam]
//                                _korzetirodadarab[1..8]
//                                _korzetirodasor[1..8,1..korzetirodadarab]
//
//  Beállitja a következõ változót: _irodadarab;
//  ----------------------------------------------------------------------------

var i: integer;
    _aktirodaszam,_kdb: integer;
    _aktirodaNev,_closed: string;

begin

  for i := 1 to 8 do _korzetIrodaDarab[i] := 0;
  for i := 1 to 150 do _irodaErtektar[i] := 0;

  _irodaDarab := 0;

  ibdbase.close;
  ibdbase.DatabaseName := 'c:\receptor\database\receptor.gdb';

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY ERTEKTAR,UZLET';

  ibOpen(_pcs);
  ibQuery.First;
  while not IbQuery.eof do
    begin
      with IbQuery do
        begin
          _aktirodaszam := FieldByName('UZLET').asInteger;
          _aktirodanev  := FieldByName('KESZLETNEV').AsString;
          _aktertektar  := FieldByName('ERTEKTAR').asInteger;
          _closed       := FieldByname('CLOSED').asString;
        end;
      if _closed='X' then
        begin
          Ibquery.Next;
          Continue;
        end;

      inc(_irodaDarab);
      _irodanev[_aktirodaszam]      := _aktirodanev;
      _irodaertektar[_aktirodaszam] := _aktertektar;

      _etss := Scanertektar(_aktertektar);

      _kdb := _korzetIrodaDarab[_etSs];
      inc(_kdb);

      _korzetIrodaSor[_etss,_kdb] := _aktirodaszam;
      _korzetIrodaDarab[_etss] := _kdb;

      IbQuery.Next;
    end;
  IbQuery.Close;
  IbDbase.close;
end;


// =============================================================================
            procedure TTabmaker.ForgalomBeolvasas;
// =============================================================================

var i,_ertek: integer;
    _datum,_blokknum,_tipus,_penztarosnev,_elojel: string;

begin

  _sumVetel   := 0;
  _sumEladas  := 0;
  _sumvugyfdb := 0;
  _sumeugyfdb := 0;

  for i := 1 to 35 do _prosdb[i] := 0;

  for i := 1 to 31 do
    begin
      _npros[_kirss,i]  := 0;
      _nVetel[_kirss,i] := 0;
      _neladas[_kirss,i]:= 0;
      _napiVevoDarab[_kirss,i] := 0;
      _napiEladoDarab[_kirss,i] := 0;
    end;

  // ---------------------------------------------------------------------------

  ibtabla.Close;
  ibdbase.Close;

  ibDbase.DatabaseName := _aktGdbPath;
  ibDbase.Connected    := True;
  ibTabla.TableName    := _blokkfejnev;

  if not ibTabla.Exists then exit;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_blokkfejnev+' FEJ JOIN '+_blokktetnev+' TET'+_sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND (FEJ.TIPUS=';
  _pcs := _pcs + chr(39)+'V'+chr(39)+' OR FEJ.TIPUS='+chr(39)+'E'+chr(39);
  _pcs := _pcs + ' OR FEJ.TIPUS='+chr(39)+'K'+chr(39)+')';
  _pcs := _pcs + ' AND (FEJ.DATUM<='+chr(39)+ _munkanap + chr(39)+')' + _sorveg;
  _pcs := _pcs + 'ORDER BY FEJ.DATUM,FEJ.BIZONYLATSZAM';

  _recno := ibOpen(_pcs);
  IF _RecNo=0 then
    begin
      ibQuery.CLose;
      ibdbase.close;
      _vevoUgyfelDarab[_kirss]  := 0;
      _eladoUgyfeldarab[_kirss] := 0;

      exit;
    end;

  _utdatum    := 'xxxx';    // bizonylat dátuma
  _utblokknum := 'xxxx';    // bizonylatok
  _anapok     := 0;         // ennyi napon volt forgalom

  while not ibQuery.eof do
    begin
      with ibQuery do
        begin
          _datum        := FieldByname('DATUM').asString;
          _valutanem    := FieldbyName('VALUTANEM').asString;
          _blokknum     := FieldByName('BIZONYLATSZAM').asstring;
          _tipus        := FieldByName('TIPUS').asString;
          _penztarosnev := FieldByName('PENZTAROSNEV').asString;
          _ertek        := FieldByName('FORINTERTEK').asInteger;
          _elojel       := FieldByName('ELOJEL').asString;
        end;

      // Ha ez új nap, a munkanapok lépnek:

      if _datum<>_utdatum then
        begin
          _utdatum := _datum;
          inc(_anapok);
        end;

      // Az aktuális dátum napja -> _aktnap

      _aktnap := strtoint(midstr(_datum,9,2));

      if _blokknum<>_utblokknum then
        begin
          // Vétel és konverziós bizonylat:

          if (_tipus='V') or (_tipus='K') then
            begin
              inc(_sumEugyfdb);
              _napivevodarab[_kirss,_aktnap] := _napivevodarab[_kirss,_aktnap]+1;
            end;

          // Eladás és konverziós bizonylatok:

          if (_tipus='E') or (_tipus='K') then
            begin
              inc(_sumVugyfdb);
              _napieladodarab[_kirss,_aktnap] := _napieladodarab[_kirss,_aktnap]+1;
            end;
          _utblokknum := _blokknum;
        end;

      // A pénztáros nevet regisztrálja:
      // A pénztáros neve bekerül a ss sorszámu iroda névsorába:
      // Az iroda aktnapi pénztáros sorszáma az _npros tömbbe iródik

      if _penztarosnev<>'' then  InsertProsList(_penztarosnev,_kirss);


  //  VÉTEL --------------------------------------------------------------------

      if (_tipus='V') then
        begin
          _nVetel[_kirss,_aktnap] := _nVetel[_kirss,_aktnap] + _ertek;
          _sumvetel := _sumvetel + _ertek;
        end;

  // ELADÁS --------------------------------------

      if (_tipus='E') then
        begin
          _neladas[_kirss,_aktnap] := _nEladas[_kirss,_aktnap] + _ertek;
          _sumeladas := _sumeladas + _ertek;
        end;

   // KONVERZIÓ ------------------------------------

       if (_tipus='K') and (_valutanem<>'HUF') then
         begin
           if _elojel='+' then
             begin
               _nVetel[_kirss,_aktnap] := _nVetel[_kirss,_aktnap] + _ertek;
               _sumvetel := _sumvetel + _ertek;
             end else
             begin
               _nEladas[_kirss,_aktnap] := _nEladas[_kirss,_aktnap] + _ertek;
               _sumeladas := _sumeladas + _ertek;
             end;
         end;
      ibQuery.Next;
    end;

  _vevoUgyfelDarab[_kirss]  := _sumVUgyfDb;
  _eladoUgyfeldarab[_kirss] := _sumEUgyfDb;

  ibQuery.Close;
end;

// =============================================================================
          procedure TTabmaker.InsertProsList(_pnev: string; _iss: integer);
//==============================================================================

var _eddigProsdb,_ptss: integer;

begin

  // Az _iss sorszamu iroda pénztáros névsorába, bekerül a pnevü pénztáros

  _pnev        := trim(_pnev);

  // Az iss sorszámu pénztárban eddig ennyi pénztáros van regisztrálva:

  _eddigProsdb := _prosdb[_iss];

  // Maximum 8 pénztárost tárolhatunk

  if _eddigProsdb=8 then exit;

  // Megnézi, hogy milyen sorszámon van regisztrálva _pnev nevü pénztáros
  // Ha még nincs regisztrálva, akkor 0 sorszámot ad vissza:

  _ptss := GetProsSorszam(_pnev,_iss);

  // Ha még a pénztáros nincs benn az iroda névsorába:

  if _ptss=0 then
    begin
      _ptss := _eddigProsdb + 1;
      _prosdb[_iss] := _ptss;
      _prosnev[_iss,_ptss] := _pnev;
    end;

   // A mai nap ebben az irodában a ptss sorszámu
  _npros[_iss,_aktnap] := _ptss;
end;

// =============================================================================
    function TTabmaker.GetProsSorszam(_ptn: string; _irss: integer):integer;
// =============================================================================

// Az _irss sorszámu pénztárban, van-e _ptn nevü pénztáros regisztrálva:

var _yy: integer;
    _haspnev: string;

begin

  // Default: 0 = még nincs regisztrálva

  result := 0;
  _yy := 1;

  // Megnézi az iroda eddigi pénztáros sorát (Max 8 fõ)

  while _yy<=8 do
    begin
      _haspnev := _prosnev[_irss,_yy];
      if _haspnev=_ptn then
        begin
          Result := _yy;
          Break;
        end;
      inc(_yy);
    end;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


// =============================================================================
               procedure TTabmaker.REadElozohonap;
// =============================================================================


begin

  with ibDbase do
    begin
      Close;
      DatabaseName := _AktgdbPath;
      Connected := true;
    end;

  ibTabla.Close;
  ibTabla.TableName := 'ELOHAVI';
  if not ibTabla.Exists then
    begin
      ibDbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ELOHAVI' + _sorveg;
  _pcs := _pcs + 'WHERE EVHOSTRING=' + chr(39)+ '20' + _elofarok + chr(39);

  _recno := ibOpen(_pcs);
  if _recno>0 then
    begin
      with ibQuery do
        begin
          _ehNapok[_kirss]  := FieldByNAme('NAPOK').asInteger;
          _ehVasar[_kirss]  := FieldByName('VETEL').asInteger;
          _ehEladas[_kirss] := FieldByName('ELADAS').asInteger;
          _ehVdb[_kirss]    := FieldByName('VETELUGYFELDARAB').asInteger;
          _ehEdb[_kirss]    := FieldByName('ELADASUGYFELDARAB').asInteger;
        end;
     end;
  ibQuery.Close;
  ibdbase.close;
end;

// =============================================================================
                      procedure TTabmaker.WriteElozohonap;
// =============================================================================

var _evhostring: string;

begin
  _evhostring := '20'+_farok;   // '200910'
  _pcs := 'DELETE FROM ELOHAVI WHERE EVHOSTRING='+chr(39)+_evHostring+chr(39);
  ibParancs(_pcs);

  _pcs := 'INSERT INTO ELOHAVI (EVHOSTRING,NAPOK,VETEL,ELADAS,VETELUGYFELDARAB,';
  _pcs := _pcs + 'ELADASUGYFELDARAB)'+_sorveg;
  _pcs := _pcs + 'VALUES ('+_evhostring+','+inttostr(_anapok)+','+floattostr(_sumvetel);
  _pcs := _pcs + ','+floattostr(_sumeladas)+','+inttostr(_sumvugyfdb)+',';
  _pcs := _pcs + inttostr(_sumeugyfdb)+')';

  ibParancs(_pcs);
end;


// =============================================================================
             procedure TTabmaker.KeszletBeolvasas;
// =============================================================================
//
// ITT BE KELL OLVASNI A munkanapi vagy az azt megelözö napi készleteket
// HA A HAVI CIMTÁR ÜRES VAGY NeM LÉTEZIK, AKKOR A MULTHAVI UTOLSÓ NAPOT
//

var i,j,_aktcimlet: integer;
    _cimtarinap,_aktcimsor,_mezo: string;
    _hi,_lo: byte;

begin
  _vanKeszlet      := False;
  _munkanapiCimlet := False;
  _urcimsor        := dupestring(chr(0),28);

  for i := 1 to 22 do
    begin
      _vkeszlet[_kirss,i] := 0;
      _cimsor[_kirss,i]   := _urcimsor;
    end;

  ibTabla.Close;
  with ibDbase do
    begin
      Close;
      DatabaseName := _aktGdbPath;
      Connected := True;
    end;

  ibTabla.Tablename := _cimtarnev;

  if not ibTabla.Exists then
    begin
      ibTabla.TableName := 'CIMT' + _eloFarok;

      // Ha elözõ havi cimletek sincsenek, akkor nincs készlet !!

      if not ibTabla.Exists then
        begin
          ibdbase.close;
          exit;
        end;

      _pcs := 'SELECT * FROM CIMT'+_elofarok+_sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';
      _recno := ibOpen(_pcs);

      // Ha az elözö havi cimlettábla is üres -> nincs készlet !!
      if _Recno=0 then
        begin
          ibQuery.Close;
          ibDbase.close;
          Exit;
        end;

      // A legutolsó cimletbejegyzés napja:

      ibQuery.Last;
      _cimtariNap := ibQuery.FieldByName('DATUM').asString;

      _pcs := 'SELECT * FROM CIMT' + _elofarok + _sorveg;
      _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _cimtariNap + chr(39);

      _recno := ibOpen(_pcs);
    end else
    begin
      _pcs := 'SELECT * FROM ' + _cimtarnev + _sorveg;
      _pcs := _pcs + 'WHERE DATUM<=' + chr(39) + _munkanap + chr(39) + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';
      _recno := IbOpen(_pcs);
      if _recno=0 then
        begin
          ibquery.close;
          ibdbase.close;
          exit;
        end;

      ibQuery.Last;
      _cimtariNap := ibQuery.FieldByName('DATUM').asString;
      if _Cimtarinap =_munkanap then _munkanapiCimlet := True;

      _pcs := 'SELECT * FROM ' + _cimtarnev + _sorveg;
      _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _cimtariNap + chr(39);
      _recno := ibOpen(_pcs);
    end;

  if _recno=0 then
    begin
      ibQuery.close;
      ibdbase.close;
      exit;
    end;

// A cimlettábla  napjának adatait mind beolvassuk:

  while not ibQuery.eof do
    begin
      _aktcimsor := '';

  // Megállapitja a valuta sorszámát: _vss

      _valutanem := ibQuery.FieldByName('VALUTANEM').asstring;
      _valss := ScanDnem(_valutanem);

  // Beolvassa a készletet és a cimleteket

      _osszesen := ibQuery.FieldByName('OSSZESEN').asInteger;
      _vKeszlet[_kirss,_valss] := _osszesen;

      for j := 1 to 14 do
        begin
          _mezo := 'CIMLET'+inttostr(j);
          _aktcimlet := ibQuery.FieldByName(_mezo).asInteger;
          _hi := trunc(_aktcimlet/256);
          _lo := _aktcimlet-trunc(256*_hi);
          _aktcimsor := _aktcimsor + chr(_lo)+chr(_hi);
        end;

      _cimsor[_kirss,_valss] := _aktcimsor;
      ibQuery.Next;
    end;

  ibQuery.Close;
  _vanKeszlet := True;
end;


// =============================================================================
             procedure TTabmaker.ReadElozonap;
// =============================================================================


//  Be kell olvasni a Munkanap elötti nap készleteit az ss-ik irodában:

var _elonap,_valutanem: string;
    i: integer;

begin

   for i := 1 to 22 do _enkeszlet[_kirss,i] := 0;

  // Elönapi tábla elökészitése:

  with ibDbase do
    begin
      Close;
      DatabaseName := _aktGdbPath;
      Connected := True;
    end;

  ibTabla.Close;
  ibTabla.TableName := 'ELONAPI';

// Van elönapi tábla ?
  if not IBtabla.Exists then exit;

  _pcs := 'SELECT * FROM ELONAPI'+_sorveg;
  _pcs := _pcs + 'WHERE DATUM<' + chr(39) + _munkanap + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  // Az aktuális (MUNKANAP) elötti napokra szürve:

  _recno := ibOpen(_pcs);
  ibQuery.Last;

  // Ez volt a legelsö nap: Nincs egyetlen  elözö nap sem regisztrálva !!

  if _RecNo = 0 then
    begin
      ibQuery.close;
      ibdbase.close;
      Exit;
    end;

  // Az utolsó regiszrált nap a munkanap elött = ELONAPI

  _elonap := ibQuery.FieldByName('DATUM').asString;

  _pcs := 'SELECT * FROM ELONAPI'+_sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_elonap+chr(39);

  // csak a Munkanap elötti utolsó napok látszanak !

  _recno := ibOpen(_pcs);

  if _recno>0 then
    begin

     // Végigmegyünk a Munkanap elötti utolsó nap adatain:

      while not ibQuery.eof do
        begin

         // Az elözö napi készletek tömbökbe lesznek olvasva
          with ibQuery do
             begin
               _valutanem := FieldByName('VALUTANEM').asstring;
               _osszesen := FieldByName('OSSZESEN').asInteger;
             end;

         // Az aktuális deviza sorszáma:
         _valss := scanDnem(_valutanem);

         // Ezeket a cimleteket beolvassa az ENKESZLET tömbbe:

         _enKeszlet[_kirss,_valss] := _osszesen;
         ibQuery.Next;
        end;
    end;
  ibQuery.CLose;
  ibdbase.close;
end;


// =============================================================================
               procedure TTabmaker.WriteElozonap;
// =============================================================================


var _cleardatum: TdateTime;
    _clearDatString: string;
    _aktkeszlet: real;

begin

  if not _Munkanapicimlet then exit;

  ibdbase.Close;
  ibDbase.DatabaseName := _aktgdbPath;
  ibDbase.connected := true;

  //  Elöször kitöröljük a munkanapi (esetleges) bejegyzéseket !

  _pcs := 'DELETE FROM ELONAPI'+_SORVEG;
  _pcs := _pcs + 'WHERE DATUM='+chr(39) + _Munkanap + chr(39);

  ibParancs(_pcs);

  // ------- Most a 22 valuta készletét beirjuk a mai napra,
  //   holnapra való tekintettel a _vkeszlet tömbböl:

  _valss := 1;
  while _valss<=22 do
    begin
      _aktkeszlet := _vKeszlet[_kirss,_valss];
      if _aktkeszlet>0 then
         begin
           _pcs := 'INSERT INTO ELONAPI (DATUM,VALUTANEM,OSSZESEN)'+ _sorveg;
           _pcs := _pcs + 'VALUES ('+chr(39) + _munkanap + chr(39)+',';
           _pcs := _pcs + chr(39) + _dnem[_valss] + chr(39) + ',';
           _pcs := _pcs + floattostr(_aktkeszlet) + ')';

           ibParancs(_pcs);
         end;
       inc(_valss);
    end;

  // ---- Most kicsit takaritok: a multheti adatok már nem kellenek:

  _cleardatum := _tabloNapja - 6;
  _clearDatstring := leftStr(datetostr(_clearDatum),10);

  _pcs := 'DELETE FROM ELONAPI WHERE DATUM<'+chr(39)+_clearDatString+chr(39);
  ibparancs(_pcs);

end;


(*
// =============================================================================
                      procedure TTabmaker.WriteTabloes;
// =============================================================================



       _byteTomb[2] := _tabloho;

     BlockWrite(_tablo,_byteTomb,1);
     CloseFile(_tablo); // %%++

     inc(_etss);
   end;
end;
*)

// =============================================================================
                      procedure TTabmaker.WriteKorzetTablo;
// =============================================================================


var _p,i,_v: integer;
    _evtized,_uzletdarab: byte;
    _aktirodaszam,_ptdarab,_aDay,_napipros: byte;
    _ertId,_aktFileNev,_aktFilePath,_aktirodanev,_aktcimletsor: string;
    _napiVetel,_napiEladas,_aktVKeszlet,_aktEnKeszlet: integer;
    _napiVevo,_napiElado,_nvdb,_nedb: word;

BEGIN
   _kirss := 1;
   _aktKorzetIrodaDarab := _korzetIrodaDarab[_etss];
   _aktertektarszam := _eertektarszam[_etss];

   // Az aktuális értéktár ID-je : 10,20,40,50,63,75,12,14
   _ertid := leftstr(inttostr(_aktertektarszam),2);

   // Ez lesz a tablófile neve:
   _aktfileNev := 'HS' + _ertId + _farok + '.STT';
   _aktFilePath := 'c:\receptor\Mail\TABLO\'+_aktfilenev;

   // A régebbi tablót törölni kell:

   if Fileexists(_aktfilePath) then DeleteFile(_aktfilePath);

   // Itt kezdi irni egy értéktár tablóját:

   AssignFile(_tablo,_aktfilePath);
   Rewrite(_tablo);

   // ------------ 'H4' a file ID-je (új verzió)   -------------------------

   _byteTomb[1] := 72;
   _byteTomb[2] := 52;
   Blockwrite(_tablo,_bytetomb,2);  // 'H3

   // ------------- A tabló éve és hava felirása ---------------------------

   _evtized     := _tabloev - 2000;
   _byteTomb[1] := _evtized;
   _byteTomb[2] := _tabloho;
   Blockwrite(_tablo,_bytetomb,2);  // '1201'


   // -------------- Az értéktárban lévõ irodák száma ----------------------

   _byteTomb[1] := _aktkorzetIrodaDarab;
   BlockWrite(_tablo,_bytetomb,1);  // ennyi iroda van a körzetben

   while _kirss<=_aktkorzetIrodaDarab do
     begin


       _aktIrodaszam := _korzetIrodasor[_etss,_kirss];
       _aktirodanev := _irodanev[_aktirodaszam];
       TextKodWrite(_aktirodanev);   // az iroda megnevezés felirása

       // Az iroda elözöhavi munkanapjait irja fel:

       _ByteTomb[1] := _ehNapok[_kirss];   // elözö havi munkanapok
       BlockWrite(_tablo,_byteTomb,1);

       // Az elözöhavi vásárlás és eladás felirása:

       RealKodwrite(_ehVasar[_kirss]);    // elozohavi vasar
       RealKodwrite(_ehEladas[_kirss]);   // elozohavi eladas

       // Az elözöhavi vásárló és eladó ügyfelek száma:

       wordKodwrite(_ehvdb[_kirss]);      // elozohavi vásárlószám
       wordKodWrite(_ehedb[_kirss]);      // elözöhavi eladásszám

       // Az aktuális irodában ennyi penztáros volt:

       _ptdarab := _prosdb[_kirss];       // ennyi pénztáros darab
       _bytetomb[1] := _ptdarab;
       BlockWrite(_tablo,_bytetomb,1);

       // Ha voltak pénztárosok, akkor azokat felirjuk:

       if _ptdarab>0 then
          for _p := 1 to _ptdarab do TextKodWrite(_prosnev[_kirss,_p]);

       // Most jönnek a napi adatok felirása:

       _aDay := 1;
       while _aday<=_tablonap do
         begin
           _napivetel  := _nvetel[_kirss,_aday];
           _napieladas := _neladas[_kirss,_aday];
           _napipros   := _npros[_kirss,_aday];
           //   _napivevo   := _nvdb[_kirss,_aday];
           //   _napielado  := _nedb[_kirss,_aday];

           // Ha volt forgalom az adott napon akkor azt felirjuk:

           if (_napivetel>0) or (_napieladas>0) then
             begin
               // A hónap napját felirja:

               _byteTomb[1] := _aday;
               BlockWrite(_tablo,_byteTomb,1);

               // A napi vétel-eladás forgalom felirása:

               RealKodwrite(_napivetel);
               RealKodWrite(_napieladas);

               _nvdb := _napiVevodarab[_kirss,_aday];
               _nedb := _napiEladodarab[_kirss,_aday];

               WordKodWrite(_nvdb);
               WordKodwrite(_nedb);

               // Fõpénztáros sorszama az adott napon

               _byteTomb[1] := _napipros;
               Blockwrite(_tablo,_bytetomb,1);

               //     // Felirja a napi vevo és eladó ügyfelek számát:
               //
               //     wordKodwrite(_napivevo);
               //     wordKodwrite(_napielado);
             end;

           // Jöhet a következõ nap:

           inc(_aday);

         end;

       // Az iroda forgalmi adatai készen vannak. 255-el zárjuk le !

       _byteTomb[1] := 255;
       Blockwrite(_tablo,_bytetomb,1);

       _aktvevoUgyfeldarab  := _vevoUgyfelDarab[_kirss];
       _aktEladoUgyfelDarab := _eladoUgyfeldarab[_kirss];

       wordKodWrite(_aktvevoUgyfelDarab);
       wordKodWrite(_aktEladoUgyfeldarab);

       // Jöhet a következö iroda az értéktárban:

       inc(_kirss);
     end;

   // ==================================================

   // A tabló készitésének napja:

   _bytetomb[1] := _tablonap;

   // A valutanemek darabszáma:

   _byteTomb[2] := 22;   // dnemdarab
   BlockWrite(_tablo,_bytetomb,2);

   // Az összes valutanem kodolt felirása_

   for i := 1 to 22 do dnemKodwrite(_dnem[i]);

   _kirss := 1;
   while _kirss<=_aktkorzetIrodaDarab do
     begin
      // _aktIrodaszam := _korzetIrodaSor[_etss,_kirss];

       _valss := 1;
       while _valss<=22 do
         begin
           _aktvkeszlet := _vkeszlet[_kirss,_valss];
           _aktenkeszlet := _enKeszlet[_kirss,_valss];
           _aktcimletsor := _cimsor[_kirss,_valss];

           if (_aktvKeszlet>0) or (_aktenKeszlet>0) then
             begin
               _byteTomb[1] := _valss;
               Blockwrite(_tablo,_bytetomb,1);

               RealKodWrite(_aktVKeszlet);
               RealKodWrite(_aktEnKeszlet);

               for i := 1 to 28 do
                 begin
                   _byte := ord(_aktcimletsor[i]);
                   _bytetomb[i] := _byte;
                 end;
               Blockwrite(_tablo,_byteTomb,28);
             end;
           inc(_valss);
         end;

       _byteTomb[1] := 255;
       Blockwrite(_tablo,_byteTomb,1);
       inc(_kirss);
     end;

   _bytetomb[1] := 255;
   BlockWrite(_tablo,_byteTomb,1);
   CloseFile(_tablo); // %%++
end;





(*
// =============================================================================
              procedure TTabmaker.WriteBestChangeTablo;
// =============================================================================

var _aktertektarnev,_aktcimletsor: string;
    _ee,_aday: integer;
    _napivetel,_napieladas,_aktvkeszlet,_aktenkeszlet: real;
    _napivevo,_napielado,_v,i: integer;
    _byte: byte;

BEGIN

  _aktfileNev := 'HS00' + _farok + '.STT';
  _aktFilePath := 'c:\receptor\mail\TABLO\'+_aktfilenev;
  if Fileexists(_aktfilePath) then DeleteFile(_aktfilePath);

  AssignFile(_tablo,_aktfilePath);
  Rewrite(_tablo);

  _byteTomb[1] := 72;
  _byteTomb[2] := 50;
  Blockwrite(_tablo,_bytetomb,2);  // 'H2'

  _byteTomb[1] := _evtized;
  _byteTomb[2] := _tabloho;
  Blockwrite(_tablo,_bytetomb,2);  // '0905'

  TextKodwrite(_jelszo);
  _byteTomb[1] := 8;  // értéktár darab
  BlockWrite(_tablo,_bytetomb,1);

   _ee := 1;
   while _ee<=8 do
     begin

       _aktertekTarnev  := _eertekTarnev[_ee];

       TextKodWrite(_eertektarNev[_ee]);
       TextKodwrite('KÖRZET');

       _ByteTomb[1] := _sehNapok[_ee];
       BlockWrite(_tablo,_byteTomb,1);

       RealKodwrite(_sehVasar[_ee]);
       RealKodwrite(_sehEladas[_ee]);

       WordKodwrite(_sehvdb[_ee]);
       WordKodWrite(_sehedb[_ee]);

       _bytetomb[1] := 0;
       BlockWrite(_tablo,_bytetomb,1);

       _aDay := 1;
       while _aday<=_tablonap do
         begin
           _napivetel  := _snvetel[_ee,_aday];
           _napieladas := _sneladas[_ee,_aday];
           _napivevo := _snvdb[_ee,_aday];
           _napielado := _snedb[_ee,_aday];

           if (_napivetel>0) or (_napieladas>0) then
             begin
               _byteTomb[1] := _aday;
               BlockWrite(_tablo,_bytetomb,1);

               RealKodwrite(_napivetel);
               RealKodWrite(_napieladas);

               _byteTomb[1] := 0;
               Blockwrite(_tablo,_bytetomb,1);

               wordKodwrite(_napivevo);
               wordKodwrite(_napielado);
             end;
           inc(_aday);
         end;

       _byteTomb[1] := 255;
       Blockwrite(_tablo,_bytetomb,1);
       inc(_ee);
     end;

   _bytetOmb[1] := _tablonap;
   _byteTomb[2] := 22;   // dnemdarab
   BlockWrite(_tablo,_bytetomb,2);

   for _v := 1 to 22 do dnemKodwrite(_dnem[_v]);

   _ee := 1;
   while _ee<=8 do
     begin
       _v := 1;
       while _v<=22 do
         begin
           _aktvkeszlet := _svkeszlet[_ee,_v];
           _aktenkeszlet := _senKeszlet[_ee,_v];
           _aktcimletsor := _scimsor[_ee,_v];

           if (_aktvKeszlet>0) then
             begin
               _byteTomb[1] := _v;
               Blockwrite(_tablo,_bytetomb,1);

               RealKodWrite(_aktVKeszlet);
               RealKodWrite(_aktEnKeszlet);

               for i := 1 to 28 do
                 begin
                   _byte := ord(_aktcimletsor[i]);
                   _bytetomb[i] := _byte;
                 end;
               BlockWrite(_tablo,_byteTomb,28);
             end;
           inc(_v)
         end;
       _byteTomb[1] := 255;
       Blockwrite(_tablo,_byteTomb,1);
       inc(_ee);
     end;
   _bytetomb[1] := 255;
   BlockWrite(_tablo,_byteTomb,1);
   CloseFile(_tablo); // %%++

end;

// =============================================================================
                   procedure TTabmaker.SumBestchange;
// =============================================================================

var _n: integer;

begin
  _ee := 1;
  while _ee<=8 do
    begin
      _sehnapok[_ee] := 0;
      _sehVasar[_ee] := 0;
      _sehEladas[_ee] := 0;
      _sehvdb[_ee] := 0;
      _sehEdb[_ee] := 0;

      for _n := 1 to 31 do
        begin
          _snvetel[_ee,_n] := 0;
          _sneladas[_ee,_n] := 0;
          _snVdb[_ee,_n] := 0;
          _snEdb[_ee,_n] := 0;
        end;

      _v := 1;
      while _v<=22 do
        begin
          _svkeszlet[_ee,_v] := 0;
          _senKeszlet[_ee,_v] := 0;
          _scimsor[_ee,_v] := _urcimsor;
          inc(_v);
        end;
      inc(_ee);
    end;

  _ee := 1;
  while _ee<=8 do
    begin
      _boltdb := _korzetIrodaDarab[_ee];
      _bb := 1;
      while _bb<=_boltdb do
        begin
          _aktirodaszam := _korzetirodaSor[_ee,_bb];
          _aktirss := scanUzlet(_aktirodaszam);
          if _ehnapok[_aktirss]>_sehnapok[_ee] then _sehnapok[_ee] := _ehnapok[_aktirss];
          _sehvasar[_ee] := _sehvasar[_ee] + _ehvasar[_aktirss];
          _seheladas[_ee]:= _seheladas[_ee] + _eheladas[_aktirss];
          _sehvdb[_ee] := _sehvdb[_ee] + _ehvdb[_aktirss];
          _sehedb[_ee] := _sehedb[_ee] + _ehedb[_aktirss];

          _n := 1;
          while _n<=_tablonap do
            begin
              _snVetel[_ee,_n] := _snVetel[_ee,_n] + _nVetel[_aktirss,_n];
              _snEladas[_ee,_n] := _snEladas[_ee,_n] + _nEladas[_aktirss,_n];
              _snVdb[_ee,_n] := _snVdb[_ee,_n] + _nVdb[_aktirss,_n];
              _snEdb[_ee,_n] := _snEdb[_ee,_n] + _nEdb[_aktirss,_n];
              inc(_n);
            end;

          _v := 1;
          while _v<=22 do
            begin
              _sVkeszlet[_ee,_v] := _sVkeszlet[_ee,_v] + _vkeszlet[_aktirss,_v];
              _sEnKeszlet[_ee,_v] := _sEnKeszlet[_ee,_v] + _enKeszlet[_aktIrss,_v];
              _icimsor := _cimsor[_aktirss,_v];
              if _icimsor = _urcimsor then
                begin
                  inc(_v);
                  continue;
                end;

              _sicimsor := _scimsor[_ee,_v];
              _zz := 1;
              _ujscimsor := '';
              while _zz<28 do
                begin
                  _icimpar := midstr(_icimsor,_zz,2);
                  _sicimpar := midstr(_sicimsor,_zz,2);
                  _lo := ord(_icimpar[1]);
                  _hi := ord(_icimpar[2]);
                  _hilo := _lo + trunc(256*_hi);
                  _slo := ord(_sicimpar[1]);
                  _shi := ord(_sicimpar[2]);
                  _shilo := _slo + trunc(256*_shi);
                  _shilo := _shilo + _hilo;
                  _shi := trunc(_shilo/256);
                  _slo := _shilo - trunc(_shi*256);
                  _ujscimsor := _ujscimsor + chr(_slo)+chr(_shi);
                  _zz := _zz + 2;
                end;
              _scimsor[_ee,_v] := _ujsCimsor;
              inc(_v);
            end;
          inc(_bb);
        end;
      inc(_ee);
    end;

end;
*)





// =============================================================================
             procedure TTabmaker.TextKodwrite(_szo: string);
// =============================================================================


var _lenszo,y,_aa: integer;

begin
  _szo := Trim(_szo);
  _lenszo := length(_szo);
  if _lenszo = 0 then
    begin
      _byteTomb[1] := 0;
      Blockwrite(_tablo,_bytetomb,1);
      exit;
    end;
  _bytetomb[1] := _lenszo;
  for y := 1 to _lenszo do
    begin
      _aa := ord(_szo[y]);
      _byteTomb[y+1] := 255 - _aa;
    end;
  BlockWrite(_Tablo,_byteTomb,_lenszo+1);
end;


// =============================================================================
              procedure TTabmaker.WordKodWrite(_num: integer);
// =============================================================================

var _lo,_hi: byte;

begin
  _hi := trunc(_num/256);
  _lo := _num - trunc(256*_hi);
  _bytetomb[1] := _lo;
  _bytetomb[2] := _hi;
  Blockwrite(_tablo,_bytetomb,2);
end;

// =============================================================================
              procedure TTabmaker.RealKodWrite(_real:real);
// =============================================================================


var _b1,_b2,_b3,_b4,_b5: byte;
    _c1,_a2,_a3,_a4: real;

begin
  _a4 := 256;
  _a3 := 65536;
  _a2 := 256*65536;


  _c1 := _real/_a3;
  _b1 := trunc(_c1/_a3);

  _real := _real - (_b1*_a3*_a3);

  _b2 := trunc(_real/_a2);
  _real := _real - (_b2*_a2);

  _b3 := trunc(_real/_a3);
  _real := _real - (_b3*_a3);

  _b4 := trunc(_real/_a4);
  _b5 := trunc(_real -(_b4*_a4));

  _byteTomb[1] := _b1;
  _byteTomb[2] := _b2;
  _byteTomb[3] := _b3;
  _byteTomb[4] := _b4;
  _byteTomb[5] := _b5;

  BlockWrite(_tablo,_byteTomb,5);
end;


// =============================================================================
             procedure TTabmaker.DnemKodwrite(_vnem: string);
// =============================================================================


var _a,_b,_c: byte;

begin
  _a := ord(_vnem[1])-65;
  _b := ord(_vnem[2])-65;
  _c := ord(_vnem[3])-65;

  _a := trunc(4*_a)+trunc(_b/8);
  _b := trunc(32*_b);
  _b := _b + _c;
  _byteTomb[1] := _a;
  _bytetomb[2] := _b;
  Blockwrite(_tablo,_bytetomb,2);
end;


// =============================================================================
             function TTabmaker.ScanDnem(_devnem:string): integer;
// =============================================================================

var z: integer;

begin
  Result := 0;

  // Végignézi mind a 22 valutát, és visszadja a paraméterben adott
  // valutanem sorszámát:

  for z := 1 to 22 do
    begin
      if _dnem[z] = _devnem then
        begin
          Result := z;
          Exit;
        end;
    end;
end;


// =============================================================================
               function TTabmaker.Nulele(_int: integer): string;
// =============================================================================


begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;



// =============================================================================
           procedure TTabmaker.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := False;
  ModalResult := 1;
end;


// =============================================================================
              function TTabmaker.ScanErtektar(_et: integer): integer;
// =============================================================================


var _y: integer;

begin
  result := 0;
  _y := 1;
  while _y<=8 do
    begin
      if _eErtektarszam[_y]=_et then
        begin
          result := _y;
          Break;
        end;
      inc(_y);
    end;
end;


// ==========================================================================
                procedure TTabmaker.ibParancs(_ukaz: string);
// ==========================================================================

begin
  ibdbase.close;
  ibdbase.connected := True;
  if ibTranz.Intransaction then ibtranz.commit;
  ibtranz.startTransaction;
  with IbQuery do
    begin
      CLose;
      sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  Ibtranz.Commit;
  IbDbase.close;
end;

// ==========================================================================
               function TTabmaker.ibOpen(_ukaz: string): integer;
// ==========================================================================

begin
  ibdbase.connected := True;
  with IbQuery do
    begin
      CLose;
      sql.Clear;
      Sql.Add(_ukaz);
      Open;
      Last;
      result := recno;
      First;
    end;
end;




end.
