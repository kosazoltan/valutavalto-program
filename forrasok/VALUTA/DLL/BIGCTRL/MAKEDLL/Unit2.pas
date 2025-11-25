unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, strutils,
  ExtCtrls, IBTable, Buttons;

type
  TForm2 = class(TForm)

    ValutaQuery: TIBQuery;
    ValutaDbase: TIBDatabase;
    ValutaTranz: TIBTransaction;

    RemoteTabla: TIBTable;
    RemoteQuery: TIBQuery;
    RemoteDbase: TIBDatabase;
    RemoteTranz: TIBTransaction;

    Kilep      : TTimer;
    Label1: TLabel;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure Bizonylatregisztralo;
    procedure GetNaturDataFromRemote;
    procedure GetJogiDatafromRemote;
    procedure JogiAdatBeolvasas;
    procedure KilepTimer(Sender: TObject);
    procedure Konyveles;
    procedure NaturAdatBeolvasas;
    procedure RemoteParancs(_ukaz: string);
    procedure UpdateMBValtozoadatok;
    procedure UpdateNaturValtozoadatok;
    procedure ValutaParancs(_ukaz: string);
    procedure VtempNullazas;

    function Angolra(_huName: string): string;
    function DoubleKill(_s: string): string;
    function FtForm(_n: integer): string;
    function GetQuoter: integer;
    function GetTranztip: integer;
    function HutoGb(_kod: byte): byte;
    function JogiUgyfelKereses: integer;
    function Napidiff(_d1,_d2: string): integer;
    function NaturUgyfelKereses: integer;
    function Nulele(_b: byte): string;
    function RemoteControl: integer;
    function String2Date(_s: string): TDatetime;
    function Tomorito(_ts: string): string;
    function UjnaturUgyfel: integer;
    function UjJogiUgyfel: integer;
    function UsdAdhato: boolean;
    function WithoutIrszam(_th: string): string;
    function WithoutLetter(_okir: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _host          : string;

  _ftpPort       : integer = 21100;
  _userId        : string  = 'ebc-10%';
  _ftpPassword   : string  = 'klc+45%';

  _sorveg: string = chr(13)+chr(10);

  _megvan,_ezUjUgyfel,_vanremote: boolean;

  _remotePath,_evFarok,_pcs,_kezdoBetu,_nevTabla,_bizTabla,_mess: string;
  _char,_mbstring,_mbcim,_plombaszam,_lastdatum,_lastvari,_rThCim: string;
  _ugyfeltipus,_megnyitottnap,_bizonylatszam,_szuletesiido: string;
  _ugyfelnev,_anyjaneve,_elozonev,_leanykori,_szuletesihely,_rOkir: string;
  _allampolgar,_lakcim,_okmanytipus,_azonosito,_tartozkodasihely: string;
  _lakcimkartya,_ch,_mbtablanev,_iso,_irszam,_varos,_utca,_hasthely: string;
  _jogiugyfelnev,_telephelycim,_okiratszam,_fotevekenyseg,_jokirat: string;
  _megbizottneve,_megbizottbeosztasa,_kepvisbeo,_kepviselonev,_jTelep: string;
  _rAnyjaneve,_rElozonev,_rLeanykori,_rSzuletesihely,_rSzuletesiido: string;
  _rAllampolgar,_rLakcim,_rOkmanytipus,_rAzonosito,_rTartozkodasihely: string;
  _rlakcimKartya,_rDatum,_rUgyfelnev,_rKepviselonev,_indok,_okirszam: string;
  _rJogiUgyfelNev,_rTelephelycim,_rOkiratszam,_rFotevekenyseg,_jUgynev: string;
  _rMegbizottneve,_rMegbizottBeosztasa,_rKepvisBeo,_tarsPenztarkod: string;
  _teaor,_rTeaor: string;

  _kulfoldi,_konverzio,_tiltva,_kozszerep,_rKozszerep,_rKulfoldi,_found: byte;
  _height,_top,_left,_width,_tranzdb: word;

  _fizetendo,_mResult,_aktsorszam,_total,_recno,_code,_jogiss,_tranztip: integer;
  _sorszam,_virtualfizetendo,_megbizoszam,_sumforint,_engedely: integer;
  _ugyfelszam,_negyedevFt,_megbizottss,_rsorszam,_naturss,_spk: integer;
  _napidiff,_hetiforint,_evimax,_gongyolt,_tranzdarab,_sss: integer;

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function getengedelyrutin(_para: integer):integer; stdcall; external 'c:\valuta\bin\getenged.dll' name 'getengedelyrutin';

function gongyoletcontrol: integer; stdcall;

implementation

{$R *.dfm}

// -------------------------------------------------------------------
//
// Feladata: Ha nem kap ügyfélszámot - semmit sem csinál
// --------
//   Ha ügyfélszámot kap: - megkeresi a szerveren (ugyfel20.fdb) at ugyfelet
//                        - ha nincs -> felveszi a szerverre
//   - végül a getenged.dll segitségével megállapitja. hogy kell-e engedélyezni
//     vagy nem engedélyezik, vagy ki engedélyezi és milyen forrásból
//     (az adatok a VTEMP táblában)
//     result=-1 ->nem engedélyezve,
//             1=engedélyezve vagy nem kell engedélyezni
//
//  Visszatérés: -1 = ügyfél tiltott vagy nem kapott engedélyt
//                1 = nem kellett engedély vagy kapott engedélyt
//                2 = nincs ügyél (nem is kell) vagy nincs internet
//  
// ---------------------------------------------------------------------


// =============================================================================
              function gongyoletcontrol: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;

// =============================================================================
                 procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top    := round((_height-291)/2);
  _left   := round((_width-413)/2);

  Top     := _top;
  Left    := _left;

  ClientHeight     := 41;
  Width            := 413;


  _ezUjugyfel      := False;
  _vanremote       := False;

  _nevtabla        := '';
  _mbtablanev      := '';
  _lastDatum       := '2010.01.01';

  _tiltva          := 0;
  _tranztip        := 0;
  _sss             := 0;
  _naturss         := 0;
  _jogiss          := 0;
  _megbizottSs     := 0;
  _hetiForint      := 0;
  _sumforint       := 0;

  logirorutin(pchar('...'));
  logirorutin(pchar('A nagy ügyfél ellenörzése (bigctrl.dll)'));

  VtempNullazas;
  AlapadatBeolvasas;

  _evFarok := midstr(_megnyitottnap,3,2);

  _remotePath := _host + ':C:\RECEPTOR\DATABASE\UGYFEL' + _evFarok + '.FDB';

  remotedbase.close;
  RemoteDbase.DatabaseName := _remotePath;

  // Ha nem azonositotta magát az ügyfél nincs mit tenni (nincs ügyfélszám):
  // Normál tranzakció - nincs korlátozás. (Vissza = 3)

  if _ugyfelszam=0 then
    begin
      ShowMessage('NINCS ÜGYFÉLSZÁM');
      logirorutin(pchar('Nincs ügyfélszám -> nincs ügyfélvizsgálat'));
      _mResult := 2;

      Kilep.Interval := 100;
      Kilep.enabled := true;
      exit;
    end;

  //////////////////////////////////////////////////////////////////////////////

  _mResult := remotecontrol; // 1=vanszerver, 3= nincs szerver
  if _mResult=-1 then
    begin
      ShowMessage('A SZERVER NEM ÉRHETÕ EL !');
      logirorutin(pchar('szerver nem érhetõ el. Kilépek'));

      _mresult := 3;
      Kilep.Interval := 50;
      Kilep.Enabled := True;
      exit;
    end;

  // Természetes személy az ügyfél:
  if _ugyfelTipus='N' then
    begin
      // Az ugyfel adatait beolvassa az ügyfélszám alapján az ügyfel táblából
      NaturAdatBeolvasas;

      // Megkeresi az ügyfelet a név, anyjaneve,szülhelye és ideje alapján
      // Sss = sorszam a megfelelö névtáblában  (0= nincs még regisztrálva)
      // Ha sss=-1, akkor az ügyfél le van tiltva !

      _sorszam := NaturUgyfelKereses;

      if _sorszam<0 then
        begin
          if _sorszam=-1 then ShowMessage('AZ ÜGYFÉL LE VAN TILTVA !');
          if _sorszam=-2 then ShowMessage('AZ ÜGYFÉL CSAK FORRÁS MEGJELÖLÉSSEL VÁLTHAT !');
          logirorutin(pchar('az ügyfél tiltott !'));
          _mResult := _sorszam;
          Kilep.Enabled := True;
          exit;
        end;

      if _sorszam>0 then UpdateNaturValtozoAdatok;

      if _sorszam=0 then
        begin
          _sorszam := UjnaturUgyfel;
          _lastdatum  := '2010.01.01';
          _hetiforint := 0;
          _sumforint  := 0;
        end;
      _plombaszam := _nevtabla + inttostr(_sorszam);
    end;

  if _ugyfeltipus='J' then
    begin

      // Jogi személy adatait beolvassa a valuta.fdb JOGISZEMELY táblájából
      // az ügyfélszám alapján:

      logirorutin(pchar('az ügyfél jogi személy'));
      JogiadatBeolvasas;

      _megbizottSS := Naturugyfelkereses;

      if _megbizottSS=0 then
        begin
          logirorutin(pchar('Rögziteni kell azügyfelet a szerveren'));
          _megbizottSs := UjNaturugyfel;
          _mbTablaNev  := _nevtabla;

        end else UpdateMbValtozoadatok;



      // Megkeresi a Jogiszemélyt a JOGISZEMELYNEV alapján:
      // Sss = sorszam a megfelelö névtáblában  (0= nincs még regisztrálva)
      // Ha sss=-1, akkor a jogiszemély le van tiltva !

      _jogiss :=  JogiUgyfelKereses;

      if _jogiss=-1 then
        begin
          ShowMessage('A JOGISZEMÉLY LE VAN TILTVA !');
          _mresult := -1;
          Kilep.Enabled := True;
          exit;
        end;

      if _jogiss=0 then
        begin
         _jogiss := UjJogiUgyfel;

         _lastdatum :='2010.01.01';
         _hetiforint := 0;
         _sumforint := 0;
        end;

       _mbCim := _mbtablanev + inttostr(_megbizottss);
       _pcs := 'UPDATE JOGI SET MBDATASORSZAM='+chr(39)+_mbcim+chr(39)+_sorveg;
       _pcs := _pcs + 'WHERE SORSZAM=' + INTTOSTR(_jogiss);
       RemoteParancs(_pcs);

       _plombaszam := 'JOGI'+inttostr(_jogiss);
     end;

  _tranztip := GetTranztip;
  if _tranztip=-1 then
    begin
      logirorutin(pchar('Az ügyfél nem kapott engedélyt a váltáshoz'));
      _mResult := -1;
      Kilep.Enabled := True;
      exit;
    end;

  if _tranztip=0 then
    begin
      logirorutin(pchar('Nincs semmi megszoritás - könyvelhetõ'));
      Konyveles;
      _Mresult := 1;
      Kilep.Enabled := True;
      exit;
    end;

  case _tranztip of
    1: _mess := 'közszereplö';
    2: _mess := 'kérdöjeles nemzetiségü külföldi';
    3: _mess := '2-szor vált idén 8 millió felett';
    4: _mess := 'negyed éven belül 25 millió 4 tranzakcióban';
    5: _mess := '10 millió felett vált';
    6: _mess := '50 millió felett vált';
  end;

  logirorutin(pchar(_mess));

  _mResult := getengedelyrutin(_tranztip);

  _mess := 'Engedélyezés eredménye: ';
  if _mresult=1 then _mess := _mess + 'Engedélyezve !';
  if _mResult=-1 then _mess := _mess + 'Nem engedélyezték';
  logirorutin(pchar(_mess));

  if _mresult=1 then Konyveles;
  Kilep.Enabled := True;
end;



// =============================================================================
//              T E R M É S Z E T E S   S Z E M É L Y
// =============================================================================
{
  - NaturAdatBeolvasas;
  - NaturUgyfelKereses: integer;
  - GetNaturDataFromRemote;
}
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TForm2.NaturAdatBeolvasas;
// =============================================================================

begin
  // Feladata:
  //  A VALUTA.FDB Ugyfelek adattáblából az Ugyfelszam alapján beolvassa
  // az összes többi adatot és azokat lekezeli (angolra,tomorit)

  _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
  Valutadbase.connected := true;
   with ValutaQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;

       _ugyfelnev     := angolra(FieldByNAme('NEV').AsString);
       _elozonev      := angolra(FieldByNAme('ELOZONEV').asstring);
       _anyjaneve     := angolra(FieldByNAme('ANYJANEVE').AsString);
       _leanykori     := angolra(FieldByNAme('LEANYKORI').asString);
       _szuletesihely := angolra(FieldByName('SZULETESIHELY').asstring);
       _szuletesiido  := trim(fieldByName('SZULETESIIDO').asString);
       _szuletesiido  := tomorito(_szuletesiido);

       _irszam := trim(Fieldbyname('IRSZAM').AsString);
       _varos  := trim(FieldByNAme('VAROS').AsString);
       _utca   := trim(FieldByName('UTCA').AsString);

       _allampolgar      := angolra(FieldbyNAme('ALLAMPOLGAR').asString);

       _okmanytipus      := angolra(FieldByNAme('OKMANYTIPUS').asString);
       _azonosito        := tomorito(FieldByName('AZONOSITO').asString);
       _tartozkodasihely := angolra(FieldByName('TARTOZKODASIHELY').asString);
       _lakcimkartya     := tomorito(FieldByNAme('LAKCIMKARTYA').AsString);
       _kulfoldi         := FieldByName('KULFOLDI').asInteger;
       _iso              := FieldByNAme('ISO').asString;
       _kozszerep        := FieldByName('KOZSZEREPLO').asInteger;

       Close;
     end;
   Valutadbase.close;

   _lakcim := leftstr(_irszam+' '+_varos+' '+_utca,40);
   _lakcim := angolra(_lakcim);

   _mess := lowercase(_ugyfelnev+','+_anyjaneve+','+_szuletesiido);

   logirorutin(pchar('Fõbb adatok: '+ _mess));
   _mess := lowercase(_szuletesihely+','+_lakcim);
   logirorutin(pchar(_mess));
end;

// =============================================================================
               function TForm2.NaturUgyfelKereses: integer;
// =============================================================================

var _pont: byte;

begin
  // Az ugyfelnev kezdöbetüje alapján meghatározza a NÉVTÁBLA-t

  result := 0;
  _kezdoBetu := leftstr(_ugyfelnev,1);
  _nevtabla  := _kezdoBetu + 'NEV';
  _biztabla  := _kezdobetu + 'BIZ';

  if _ugyfeltipus='J' then _mbtablanev := _nevtabla;

  // A szerveren megnyitja a névnek megfelelö Nevtablat
  // ée keresi az Ugyfelnev-et:

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE NEV=' + chr(39) + _ugyfelnev + chr(39);

  RemoteDbase.close;
  Remotedbase.databasename := _remotepath;
  RemoteDbase.connected := true;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := Recno;
    end;

  // Ha nem találja az ügyfél nevét a szerveren, akkor ez egy új ügyfél lesz

  if _recno=0 then
    begin
      RemoteQuery.close;
      Remotedbase.close;
      exit;
    end;

  // Az ügyfélnek megfelelö nevre van leszürve az adatbázis:

  _megvan := False; // default = nincs meg

  while not RemoteQuery.eof do
    begin
      // Ha a következö 4 adatból 2 egyezik, akkor azonositva van az ügyfel:

      _rAnyjaneve     := trim(RemoteQuery.fieldByNAme('ANYJANEVE').asString);
      _rSzuletesihely := trim(Remotequery.FieldByNAme('SZULETESIHELY').asString);
      _rSzuletesiido  := trim(RemoteQuery.FieldByNAme('SZULETESIIDO').asString);
      _rAzonosito     := trim(RemoteQuery.FieldByNAme('AZONOSITO').AsString);

      _pont := 0;
      if _ranyjaneve=_anyjaneve then _pont := 1;
      if _rszuletesiido=_szuletesiido then inc(_pont);
      if _rszuletesihely=_szuletesihely then inc(_pont);
      if _razonosito=_azonosito then inc(_pont);

      if _pont>1 then
        begin
          // AZ ügyfél egyeztetve van, befejezi a keresést:
          _megvan := True;
          break;
        end;

      // Tovább keres az adatbázisban:
      RemoteQuery.next;
    end;

  // Mégsem találta meg az egyezö adatu személyt:
  if not _megvan then
    begin
      logirorutin(pchar('Csak a nevet találta - a többi adata nem egyezik.'));

      RemoteQuery.close;
      Remotedbase.close;
      exit;
    end;

  // Megtalálta a szerveren az aktuális ügyfelet:
  // Igy beolvassa az összes személyi adatát, és az évi tranzakció adatait:

  GetNaturDataFromRemote;

  RemoteQuery.close;
  Remotedbase.close;

  if _tiltva=1 then
    begin
 //     ShowMessage('AZ ÜGYFÉL LE VAN TILTVA !');
      logirorutin(pchar('Az ügyfél tiltott'));
      result := -1;
      exit;
    end;

  if _tiltva=2 then
    begin
      ShowMessage('AZ ÜGYFÉL CSAK FORRÁS MEGJELÖLÉSSEL VÁLTHAT !');
      logirorutin(pchar('Az ügyfélnek forrást kell megjelölni'));
      _spk := supervisorjelszo(0);
      if _spk=1 then result :=1 else result := -1;
      exit;
    end;



  // A NEvtabla-ban lévö sorszámot adja vissza (Ha tiltott, akkor ez -1)

  result := _rSorszam;
end;

// =============================================================================
                     procedure TForm2.GetNaturDataFromRemote;
// =============================================================================

begin
  // Itt az aktuális ügyfél rekordját olvassa be a NEVTABLA-ból

  with remoteQuery do
    begin
      _rSorszam          := FieldByName('SORSZAM').asInteger;
      _rUgyfelnev        := trim(FieldByNAme('NEV').asString);
      _rElozonev         := trim(FieldByName('ELOZONEV').asString);
      _rLeanykori        := trim(FieldByNAme('LEANYKORI').asString);
      _rAllampolgar      := trim(FieldByNAme('ALLAMPOLGAR').asString);
      _rLakcim           := trim(FieldByNAme('LAKCIM').asString);
      _rOkmanytipus      := trim(FieldByNAme('OKMANYTIP').asString);
      _rAzonosito        := trim(FieldByName('AZONOSITO').asstring);
      _rTartozkodasihely := trim(FieldByName('TARTOZKODASIHELY').asString);
      _rLakcimkartya     := trim(FieldByNAme('LAKCIMKARTYA').asString);
      _rKulfoldi         := fieldByNAme('KULFOLDI').asInteger;
      _rkozszerep        := FieldByNAme('KOZSZEREP').asInteger;
      _tiltva            := FieldByNAme('TILTVA').asInteger;

      if _ugyfeltipus<>'J' then
        begin
          _lastDatum         := FieldByNAme('DATUM').asString;
          _hetiforint        := FieldByNAme('HETIOSSZ').asInteger;
          _sumforint         := FieldByNAme('FORINTOSSZEG').asInteger;
          _evimax            := FieldByNAme('EVIMAX').asInteger;
          _TranzDarab        := FieldByNAme('TRANZAKCIODB').asInteger;
        end;
    end;
end;


// =============================================================================
//                          J O G I S Z E M É L Y
// =============================================================================
{
   - JogiAdatBeolvasas;
   - JogiUgyfelKereses: integer;
   - GetJogiDataFromRemote;
}
// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                     procedure TForm2.JogiAdatBeolvasas;
// =============================================================================

begin
  // Feladata:
  // A VALUTA.FDB adatbázis Jogiszemely táblából olvassa be az ügyfélszámhoz
  // tartozó rekord alapján: _jogiugyfelnev,_telephelycim,...etc
  // Az adatokat megfelelöen kezeli (angolra,tomorito)
  // Végül beolvassa a NaturadatBeolvasóval a megbizott személy adatait is

  _pcs := 'SELECT * FROM JOGISZEMELY WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
  Valutadbase.connected := true;
   with ValutaQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;

       _jogiUgyfelnev := angolra(FieldByNAme('JOGISZEMELYNEV').AsString);
       _telephelycim  := FieldByNAme('TELEPHELYCIM').asString;
       _telephelycim  := angolra(_telephelycim);
       _okiratszam    := angolra(FieldByName('OKIRATSZAM').AsString);
       _fotevekenyseg := angolra(FieldByName('FOTEVEKENYSEG').AsString);
       _teaor         := FieldByName('TEAOR').asString;
       _kepviselonev  := angolra(FieldByName('KEPVISELONEV').asString);

       _megbizottneve := angolra(FieldByNAme('MEGBIZOTTNEVE').AsString);
       _megbizottbeosztasa  := angolra(FieldByNAme('MEGBIZOTTBEOSZTASA').AsString);
       _kepvisbeo     := Angolra(FieldByNAme('KEPVISBEO').AsString);
       _iso           := FieldByNAme('ISO').asstring;

       _megbizoszam := FieldByName('MEGBIZOTTSZAMA').asInteger;
       Close;
     end;
   Valutadbase.close;

  _ugyfelszam := _megbizoszam;

  NaturAdatbeolvasas;

end;

// =============================================================================
               function TForm2.JogiUgyfelKereses: integer;
// =============================================================================


begin
  // A jogi személy keresi a szerver UGYFELYY táblából Jogiugyfelnev alapján:

  result    := 0;   // default = nincs meg

  _nevtabla := 'JOGI';
  _BIZTABLA := 'JOGIBIZ';

  // A Jogiszemélynév elsõ 7 karaktere alapján keresem:

  _jugynev := leftstr(_jogiugyfelnev,7);

  _pcs := 'SELECT * FROM JOGI' +  _sorveg;
  _pcs := _pcs + 'WHERE JOGISZEMELYNEV LIKE ' + chr(39) + _Jugynev +'%'+ chr(39);

  RemoteDbase.close;
  Remotedbase.databasename := _remotepath;
  RemoteDbase.connected := true;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := Recno;
    end;

  // Ilyen nevü jogiszemély nincs regisztrálva a szerveren

  if _recno=0 then
    begin
      RemoteQuery.close;
      Remotedbase.close;
      exit;
    end;

  _megvan := False; // DEFAULT NINCS MEG

  // A 3 egyeztetendõ adat:

  _jugynev := leftstr(_jogiugyfelnev,7);
  _jtelep  := withoutirszam(_telephelycim);
  _jTelep  := leftstr(_jTelep,7);
  _jokirat := withoutLetter(_okiratszam);

  while not RemoteQuery.eof do
    begin
      _found := 0;
      _rThcim := trim(Remotequery.FieldByNAme('TELEPHELYCIM').asString);
      _rokir  := trim(RemoteQuery.FieldByName('OKIRATSZAM').AsString);
      _rTeaor := trim(RemoteQuery.fieldByName('TEAOR').AsString);
      _rthCim := leftstr(withoutIrszam(_rThCim),7);
      _rOkir  := withoutLetter(_rOkir);

      IF _rthCim=_jTelep then _found := 1;
      if _rokir=_jOkirat then inc(_found);

      if _found>0 then
        begin
          _megvan := true;
          break;
        end;
      remoteQuery.next;
    end;

  if not _megvan then
    begin
      RemoteQuery.close;
      RemoteDbase.close;

      logirorutin(pchar('Nincs egyezõ adat - igy új jogi ügyfél ez'));
      exit;
    end;

  _tiltva := RemoteQuery.fieldByName('TILTVA').asInteger;

  if _tiltva=1 then
    begin
      RemoteQuery.close;
      RemoteDbase.close;

      result := -1;
      exit;
    end;


  If _tiltva=2 then
    begin
      ShowMessage('AZ ÜGYFÉL CSAK FORRÁSMEGJELÖLÉSSEL VÁLTHAT !');
      _SPK := supervisorjelszo(0);
      if _spk<>1 then
        begin
          RemoteQuery.close;
          RemoteDbase.close;

          result := -1;
          exit;
        end;
    end;

  GetJogiDataFromRemote;

  RemoteQuery.close;
  RemoteDbase.close;
  if _rTeaor='' then
    begin
      _rTeaor := _teaor;
      _pcs := 'UPDATE JOGI SET TEAOR='+CHR(39)+_rTeaor+chr(39) + _sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_rSorszam);
      RemoteParancs(_pcs);
    end;

  result := _rSorszam;
end;

// =============================================================================
                   procedure TForm2.GetJogiDatafromRemote;
// =============================================================================

begin
  with RemoteQuery do
    begin
       _rSorszam      := FieldByName('SORSZAM').asInteger;

      _rjogiUgyfelnev := trim(FieldByNAme('JOGISZEMELYNEV').asString);
      _rTelephelycim  := trim(Fieldbyname('TELEPHELYCIM').asString);
      _rOkiratszam    := trim(Fieldbyname('OKIRATSZAM').asstring);
      _rFotevekenyseg := trim(FieldByNAme('FOTEVEKENYSEG').ASsTRING);
      _rTeaor         := trim(FieldByNAme('TEAOR').AsString);
      _rKepviselonev  := trim(FieldByNAme('KEPVISELONEV').asString);

      _rMegbizottNeve := trim(FieldByNAme('MEGBIZOTTNEVE').asString);
      _rMegbizottbeosztasa := trim(FieldByNAme('MEGBIZOTTBEOSZTASA').asString);
      _rKepvisBeo     := trim(FieldByNAme('KEPVISBEO').asString);

      _evimax         := FieldByNAme('EVIMAX').asInteger;
      _lastDatum      := FieldByNAme('DATUM').asString;
      _hetiforint     := FieldByNAme('HETIOSSZ').asInteger;
      _sumforint      := FieldByName('FORINTOSSZEG').asInteger;
      _tranzdb        := FieldByName('TRANZAKCIODB').asInteger;
      _tiltva         := FieldByNAme('TILTVA').asInteger;
    end;
end;




// =============================================================================
//##############################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$é
// =============================================================================
                   function TForm2.UjNaturUgyfel: integer;
// =============================================================================

begin

  _lastvari := _kezdobetu + 'LAST';

  RemoteDbase.close;
  Remotedbase.databasename := _remotepath;
  RemoteDbase.Connected := True;
  with RemoteQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add('SELECT * FROM LASTNUMS');
      Open;
      result := FieldByNAme(_LASTVARI).asInteger;
      Close;
    end;
  RemoteDbase.close;

  inc(result);
  _sorszam := result;

  _pcs := 'UPDATE LASTNUMS SET ' + _lastvari + '=' + inttostr(_sorszam);
  RemoteParancs(_pcs);

  _pcs := 'INSERT INTO ' + _nevtabla + ' (NEV,ANYJANEVE,ELOZONEV,LEANYKORI,';
  _pcs := _pcs + 'SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,LAKCIM,OKMANYTIP,';
  _pcs := _pcs + 'AZONOSITO,TARTOZKODASIHELY,LAKCIMKARTYA,';
  _pcs := _pcs + 'KULFOLDI,ISO,SORSZAM,KOZSZEREP,';
  _pcs := _pcs + 'TRANZAKCIODB,FORINTOSSZEG,EVIMAX,DATUM,HETIOSSZ)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _anyjaneve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _elozonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _leanykori + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szuletesihely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szuletesiido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _allampolgar + chr(39) + ',';
  _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + leftstr(_okmanytipus,12) + chr(39) + ',';
  _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tartozkodasihely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _lakcimkartya + chr(39) + ',';
  _pcs := _pcs + inttostr(_kulfoldi) + ',';
  _pcs := _pcs + chr(39) + _iso + chr(39) + ',';
  _pcs := _pcs + inttostr(_sorszam) + ',';
  _pcs := _pcs + inttostr(_kozszerep) + ',';
  _pcs := _pcs + '0,0,0,'+chr(39)+chr(39)+',0)';

  RemoteParancs(_pcs);
  _ezUjUgyfel := True;
end;


// =============================================================================
                   function TForm2.UjJogiUgyfel: integer;
// =============================================================================

begin
  RemoteDbase.close;
  Remotedbase.databasename := _remotepath;
  RemoteDbase.Connected := True;
  with RemoteQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add('SELECT * FROM LASTNUMS');
      Open;
      result := FieldByNAme('JOGILAST').asInteger;
      Close;
    end;
  RemoteDbase.close;

  inc(result);

  _pcs := 'UPDATE LASTNUMS SET JOGILAST=' + inttostr(result);
  RemoteParancs(_pcs);

  _pcs := 'INSERT INTO JOGI (JOGISZEMELYNEV,TELEPHELYCIM,OKIRATSZAM,TEAOR,';
  _pcs := _pcs + 'FOTEVEKENYSEG,KEPVISELONEV,MEGBIZOTTNEVE,';
  _pcs := _pcs + 'MEGBIZOTTBEOSZTASA,KEPVISBEO,KULFOLDI,';
  _pcs := _pcs + 'ISO,SORSZAM,';
  _pcs := _pcs + 'TRANZAKCIODB,FORINTOSSZEG,EVIMAX,DATUM,HETIOSSZ)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _jogiugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _telephelycim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _okiratszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _teaor + chr(39) + ',';
  _pcs := _pcs + chr(39) + _fotevekenyseg + chr(39) + ',';
  _pcs := _pcs + chr(39) + _kepviselonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megbizottneve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megbizottbeosztasa + chr(39) + ',';
  _pcs := _pcs + chr(39) + _kepvisbeo + chr(39) + ',';
  _pcs := _pcs + inttostr(_kulfoldi) + ',';
  _pcs := _pcs + chr(39) + _iso + chr(39) + ',';
  _pcs := _pcs + inttostr(result) + ',';
  _pcs := _pcs + '0,0,0,' + chr(39)+'2010,01,01'+chr(39)+',0)';

  RemoteParancs(_pcs);
    _ezUjUgyfel := True;
end;

// =============================================================================
                   procedure TForm2.AlapadatBeolvasas;
// =============================================================================

begin
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').asString);
      _host := trim(FieldByNAme('HOST').AsString);
      close;

      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;

      _fizetendo     := FieldByNAme('FIZETENDO').asInteger;
      _ugyfeltipus   := FieldByNAme('UGYFELTIPUS').asString;
      _ugyfelszam    := FieldbyName('UGYFELSZAM').asInteger;
      _konverzio     := FieldByName('KONVERZIO').asInteger;
      _bizonylatszam := FieldByNAme('BIZONYLATSZAM').asString;
      close;
    end;
  Valutadbase.close;

  _virtualFizetendo := _fizetendo;
  if _konverzio=1 then _virtualfizetendo := round(2*_fizetendo);
  _tarspenztarkod := midstr(_bizonylatszam,2,3);
end;

// =============================================================================
                    procedure TForm2.BizonylatRegisztralo;
// =============================================================================

begin
  // Feladata: A bizonylatszámot,dátumot,összeget rögziti az adatbázisban
  // Parameters: _ugyfeltipus,_kezdobetu,_megnyitottnap,_brutto,_bizonylatszam

  If _ugyfeltipus='N' then _biztabla := _kezdobetu + 'BIZ'
  else _bizTabla := 'JOGIBIZ';

  _pcs := 'INSERT INTO ' + _biztabla + ' (SORSZAM,DATUM,FIZETENDO,BIZONYLATSZAM)'+_SORVEG;
  _pcs := _pcs + 'VALUES (' + inttostr(_sss) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + inttostr(_fizetendo) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + CHR(39) + ')';
  RemoteParancs(_pcs);
end;




// =============================================================================
                procedure TForm2.Konyveles;
// =============================================================================

begin

  // Feladata: Frissiti a nevtabla osszegadatait , majd a bizonylatot is rögziti
  // Parameters: _nevtabla,_sss,_rtranzakciodb,_rForintosszeg,_brutto
  //             _rEvimax,_napidiff,_megnyitottnap,_rhetiossz

  logirorutin(pchar('Könyvelés:'));

  _pcs := 'UPDATE VTEMP SET NEVTABLA='+chr(39)+_nevtabla+chr(39);
  _pcs := _pcs + ',GONGYOLT=' + inttostr(_gongyolt);
  _pcs := _pcs + ',PLOMBASZAM=' + chr(39) + _plombaszam + chr(39);

  if _ugyfeltipus='N' then
    begin
      _pcs := _pcs + ',SORSZAM=' + inttostr(_sorszam);
      _pcs := _pcs + ',UGYFELNEV='+chr(39)+_ugyfelnev+chr(39);
      _pcs := _pcs + ',UGYFELCIM='+chr(39)+_lakcim+chr(39);
    end else
    begin
      _pcs := _pcs + ',UGYFELNEV='+chr(39)+_jogiugyfelnev+chr(39);
      _pcs := _pcs + ',UGYFELCIM='+chr(39)+_telephelycim+chr(39);
      _pcs := _pcs + ',SORSZAM=' + inttostr(_jogiss);
      _pcs := _pcs + ',MEGBIZOSZAM='+inttostr(_megbizoszam);
    end;
  ValutaParancs(_pcs);

end;


// =============================================================================
                 procedure TForm2.RemoteParancs(_ukaz: string);
// =============================================================================

begin
  RemoteDbase.close;
  Remotedbase.databasename := _remotepath;

  RemoteDbase.close;
  Remotedbase.databasename := _remotepath;
  Remotedbase.connected := True;
  if Remotetranz.InTransaction then remotetranz.commit;
  RemoteTranz.StartTransaction;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      execsql;
    end;
  RemoteTranz.commit;
  RemoteDbase.close;
end;

// =============================================================================
                procedure TForm2.KILEPTimer(Sender: TObject);
// =============================================================================

begin
  Kilep.Enabled := False;
  Modalresult := _mResult;
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################
//                   KISEGITÕ FUNKCIOK, PROGRAMOK
// =============================================================================
                 function TForm2.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
  result := DoubleKill(result);
end;

// =============================================================================
                   function TForm2.DoubleKill(_s: string): string;
// =============================================================================

var _w,_asc,_utasc,_y: byte;

begin
  result := '';

  _s := trim(_s);
  _w := length(_s);

  // Ha üres string -> nincs mit tömöriteni
  if _w=0 then exit;

  _y     := 1;
  _utasc := 0;       // default

  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if (_asc=32) and (_utasc=32) then
        begin
          inc(_y);
          continue;
        end;

      if _asc=32 then
        begin
          result := result + ' ';
          _utasc := 32;
          inc(_y);
          Continue;
        end;

      if (_asc<48) or (_asc>90) then
        begin
          inc(_y);
          Continue;
        end;

      if (_asc>57) and (_asc<65) then
        begin
          inc(_y);
          Continue;
        end;

      result := Result + chr(_asc);
      _utasc := _asc;
      inc(_y);
    end;
end;

// =============================================================================
                   function TForm2.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;


// =============================================================================
               function TForm2.Tomorito(_ts: string): string;
// =============================================================================

var _ws,_y,_aktasc: byte;

begin
  _ts := trim(_ts);
  result := '';

  if _ts='' then exit;

  _ts := uppercase(_ts);
  _ws := length(_ts);
  _y := 1;

  while _y<=_ws do
    begin
      _aktasc := ord(_ts[_y]);
      if (_aktasc>47) and (_aktasc<58) then result := result + chr(_aktasc);
      if (_aktasc>64) and (_aktasc<91) then result := result + chr(_aktasc);
      inc(_y);
    end;
end;

// =============================================================================
                function TForm2.FtForm(_n: integer): string;
// =============================================================================

var _ns: string;
    _wn,_f1: byte;

begin
  result := '';
  _ns := inttostr(_N);
  _wn := length(_ns);
  if _wn=0 then exit;

  result := _ns;
  if _n<1000 then exit;

  if _wn>6 then
    begin
      _f1 := _wn-6;
      result := leftstr(_ns,_f1)+' '+midstr(_ns,_f1+1,3)+' '+midstr(_ns,_f1+4,3);
      exit;
    end;
  _f1 := _wn-3;
  result:=leftstr(_ns,_f1)+' '+midstr(_ns,_f1+1,3);
end;

// =============================================================================
                 procedure TForm2.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := True;
  if Valutatranz.InTransaction then Valutatranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;

// =============================================================================
           function TForm2.Napidiff(_d1,_d2: string): integer;
// =============================================================================

var _td1,_td2: TDatetime;
    _dnap: extended;
begin
  result := 100;
  _d1 := trim(_d1);
  _d2 := trim(_d2);
  if (_d1='') or (_d2='') then exit;

  _td1 := string2date(_d1);
  _td2 := String2date(_d2);
  _dnap := _td2-_td1;
  result := trunc(1*_dnap);
end;

// =============================================================================
          function Tform2.String2Date(_s: string): TDatetime;
// =============================================================================

var _yevs,_yhos,_ynaps: string;
    _yev,_yho,_ynap: word;

begin
  _yevs := leftstr(_s,4);
  _yhos := midstr(_s,6,2);
  _ynaps:= midstr(_s,9,2);

  val(_yevs,_yev,_code);
  val(_yhos,_yho,_code);
  val(_ynaps,_ynap,_code);

  result := encodedate(_yev,_yho,_ynap);
end;


// =============================================================================
                  function TForm2.RemoteControl: integer;
// =============================================================================

var _timeout: integer;

begin
  result := -1;
  _timeout := 3;
  _vanremote := False;

  RemoteDbase.close;
  Remotedbase.databasename := _remotepath;

  while _timeout>0 do
    begin
      TRY
        RemoteDbase.connected := true;
        _vanremote := True;
        break;
      EXCEPT
      END;
      Sleep(1500);
      dec(_timeout);
    end;
  if _vanremote then result := 1;
end;

// =============================================================================
                      procedure TForm2.VtempNullazas;
// =============================================================================

begin
  _pcs := 'UPDATE VTEMP SET GONGYOLT=0,SORSZAM=0,NEVTABLA='+chr(39)+chr(39);
  ValutaParancs(_pcs);
end;

// =============================================================================
                     function TForm2.GetTranztip: integer;
// =============================================================================

var _hasforint,_diff: integer;

begin
  _hasforint := _virtualFizetendo;
  _diff := Napidiff(_lastdatum,_megnyitottnap);
  if _diff<8 then _hasforint := _hasforint + _hetiforint;

  // Ha 50 millió felett vásárol -> Tranztipus= 6
  result := 6;
  if _hasforint>=50000000 then exit;

  // Ha 10 millió felett vásárol -> TranzTipus = 5
  result := 5;
  if _hasforint>=10000000 then exit;

  // Negyedév alatt 4-szer 25 millió felett vált -> Tranztipus = 4

  result := 4;
  if (_tranzdarab=4) then
    begin
      _negyedevFt := Getquoter;
      if _negyedevft>=25000000 then exit;
    end;


  // 2-szor vált idén 8 millió felett -> Tranztipus = 3

  result := 3;
  if (_evimax>=8000000) and (_hasforint>=8000000) then exit;

  // Ha külföldi de nem kaphat USD-T -> Tranztipus =-1
  // Ha csak egyszerüen külföldi -> Tranztipus = 2

  // Ha belföldi és kiemelt közszereplõ -> Tranztipus = 1

  result := 2;
  if _kulfoldi=1 then
    begin
      if not usdadhato then result := -1;
      exit;
    end else
    begin
      result := 1;
      if _rKozszerep=1 then exit;
  end;

  //  Minden egyéb esetben (nincs korlat) -> tranztipus = 0

  result := 0;
end;

// =============================================================================
                     function TForm2.UsdAdhato: boolean;
// =============================================================================

begin
  result := true;

  _pcs := 'SELECT *  FROM VTEMP WHERE VALUTANEM='+ chr(39)+'USD'+chr(39);
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
      close;
    end;
  Valutadbase.close;

  if _recno=0 then exit;
  if (_iso<>'IR') and (_iso<>'KR') and (_iso<>'CU') and (_iso<>'SY') and (_iso<>'SS') then exit;
  showmessage('EBBEN AZ ORSZÁGBAN DOLLÁR NEM VÁLTHATÓ');
  result := False;
end;

// =============================================================================
                      function TForm2.GetQuoter: integer;
// =============================================================================

var _akthos: string;
    _nyev,_tho,_iho,_aktho: word;
    _tol,_ig: string;
    _aktft: integer;

begin
  result :=0;
  // _biztabla, sorszam

  _akthos := midstr(_megnyitottnap,6,2);
  val(_akthos,_aktho,_code);
  if _code<>0 then exit;

  _nyev := trunc((_aktho-1)/3);
  _tho := 1+trunc(_nyev*3);
  _iho := _tho + 3;
  _tol := leftstr(_megnyitottnap,5)+nulele(_tho)+'.01';
  _ig  := leftstr(_tol,5)+nulele(_iho)+'.01';

  _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
  _pcs := _pcs + 'WHERE (SORSZAM='+inttostr(_sorszam)+') AND (';
  _pcs := _pcs + 'DATUM>='+chr(39)+_tol+chr(39)+') AND (';
  _pcs := _pcs + 'DATUM<='+chr(39)+_ig+chr(39)+')';

  Remotedbase.connected := true;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;
  while not RemoteQuery.eof do
    begin
      _aktft := RemoteQuery.FieldByNAme('FIZETENDO').asInteger;
      result := result + _aktft;
      Remotequery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;
end;

// =============================================================================
                  function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                  procedure Tform2.UpdateNaturValtozoAdatok;
// =============================================================================

begin


  _pcs := 'UPDATE ' + _nevtabla + ' SET LAKCIM='+chr(39)+_lakcim+chr(39);
  _pcs := _pcs + ',LAKCIMKARTYA=' + chr(39)+_lakcimkartya+chr(39);
  _pcs := _pcs + ',TARTOZKODASIHELY='+chr(39)+_tartozkodasihely+chr(39);
  _pcs := _pcs + ',OKMANYTIP='+chr(39)+_okmanytipus+chr(39);
  _pcs := _pcs + ',AZONOSITO='+chr(39)+_azonosito+chr(39);
  _pcs := _pcs + ',KOZSZEREP='+inttostr(_kozszerep);
  _pcs := _pcs + ',KULFOLDI='+inttostr(_kulfoldi);
  _pcs := _pcs + ',ALLAMPOLGAR='+chr(39)+_allampolgar+chr(39);
  _pcs := _pcs + ',ISO='+chr(39)+_iso+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_sorszam);
  RemoteParancs(_pcs);
end;

// =============================================================================
                  procedure Tform2.UpdateMBValtozoAdatok;
// =============================================================================

begin
  _pcs := 'UPDATE ' + _mbtablanev + ' SET LAKCIM='+chr(39)+_lakcim+chr(39);
  _pcs := _pcs + ',LAKCIMKARTYA=' + chr(39)+_lakcimkartya+chr(39);
  _pcs := _pcs + ',TARTOZKODASIHELY='+chr(39)+_tartozkodasihely+chr(39);
  _pcs := _pcs + ',OKMANYTIP='+chr(39)+_okmanytipus+chr(39);
  _pcs := _pcs + ',AZONOSITO='+chr(39)+_azonosito+chr(39);
  _pcs := _pcs + ',KOZSZEREP='+inttostr(_kozszerep);
  _pcs := _pcs + ',KULFOLDI='+inttostr(_kulfoldi);
  _pcs := _pcs + ',ALLAMPOLGAR='+chr(39)+_allampolgar+chr(39);
  _pcs := _pcs + ',ISO='+chr(39)+_iso+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_megbizottss);
  RemoteParancs(_pcs);
end;

function TForm2.WithoutIrszam(_th: string): string;

var _pp: byte;

begin
  _th := trim(_th);
  _pp := 1;
  while _pp<6 do
    begin
      if ord(_th[_pp])>64 then break;
      inc(_pp);
    end;
  result := midstr(_th,_pp,7);
end;


function TForm2.WithoutLetter(_okir: string): string;

var _wok,_betu,_pp: byte;

begin
  _okir := trim(_okir);
  _wok  := length(_okir);
  result := '';
  _pp := 1;
  while _pp<=_wok do
    begin
      _betu := ord(_okir[_pp]);
      if (_betu>47) and (_betu<58) then result := result + chr(_betu);
      inc(_pp);
    end;
end;

end.
