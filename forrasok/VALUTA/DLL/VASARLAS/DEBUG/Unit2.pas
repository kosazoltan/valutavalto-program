
unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Grids, DBGrids, DB, DBTables, Buttons, StrUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, Shellapi, DateUtils,
  Wininet;

type
  TVasarlasForm = class(TForm)

    BizonylatLabel     : TLabel;
    Label2             : TLabel;

    EngedelyAdoPanel   : TPanel;
    EtGomb             : TPanel;
    FEtGomb            : TPanel;
    Label1             : TLabel;
    Label3             : TLabel;
    Label4             : TLabel;
    Label5             : TLabel;
    Label6             : TLabel;
    Label7             : TLabel;
    Label8             : TLabel;
    Label9             : TLabel;
    Label13            : TLabel;
    Label14            : TLabel;
    Label18            : TLabel;
    Label23            : TLabel;
    SumOsszegLabel     : TLabel;
    ArfolyamGomb       : TPanel;
    EzrelekPanel       : TPanel;
    KerekitesPanel     : TPanel;
    KonvCimPanel       : TPanel;
    KonvSumPanel       : TPanel;
    MentesGomb         : TPanel;
    NettoPanel         : TPanel;
    NoInternetPanel    : TPanel;
    Panel1             : TPanel;
    SZAMLAALAPLAP: TPanel;
    Panel3             : TPanel;
    Panel4             : TPanel;
    Panel5             : Tpanel;
    Panel6             : TPanel;
    Panel7             : TPanel;
    Panel8             : TPanel;
    Panel9             : TPanel;
    Panel11            : TPanel;
    Panel12            : TPanel;
    Panel13            : TPanel;
    Panel10            : TPanel;
    Panel14            : TPanel;
    QuitSurePanel      : TPanel;
    ShkPanel           : TPanel;
    TranzdijPanel      : TPanel;
    UVGomb             : TPanel;
    WF1                : TPanel;
    WF2                : TPanel;
    WF3                : TPanel;
    WF4                : TPanel;
    WF5                : TPanel;
    WF6                : TPanel;
    WN1                : TPanel;
    WN2                : TPanel;
    WN3                : TPanel;
    WN4                : TPanel;
    WN5                : TPanel;
    WN6                : TPanel;

    EndGomb            : TBitBtn;
    EscapeGomb         : TBitBtn;
    IgenKilepGomb      : TBitBtn;
    KezdijEngedmenyGomb: TBitBtn;
    NemlepkiGomb       : TBitBtn;

    RemoteQuery        : TIBQuery;
    RemoteDbase        : TIBDatabase;
    RemoteTranz        : TIBTransaction;

    TetQuery           : TIBQuery;
    TetDbase           : TIBDatabase;
    TetTranz           : TIBTransaction;

    TempQuery          : TIBQuery;
    TempDbase          : TIBDatabase;
    TempTranz          : TIBTransaction;

    ValutaDbase        : TIBDatabase;
    ValutaTranz        : TIBTransaction;
    ValutaQuery        : TIBQuery;
    ValutaTabla        : TIBTable;

    EngShape           : TShape;
    Shape1             : TShape;
    Shape2             : TShape;
    Shape3             : TShape;
    Shape4             : TShape;
    Shape5             : TShape;
    Shape6             : TShape;
    Shape7             : TShape;
    Shape8             : TShape;
    Shape9             : TShape;
    Shape10            : TShape;
    Shape11            : TShape;
    Shape12            : TShape;
    Shape13            : TShape;
    Shape14            : TShape;
    Shape15            : TShape;
    Shape16            : TShape;
    Shape17            : TShape;
    Shape18            : TShape;
    Shape19            : TShape;
    Shape20            : TShape;
    Shape21            : TShape;
    Shape22            : TShape;
    Shape23            : TShape;
    Shape24            : TShape;

    WA1                : TEdit;
    WA2                : TEdit;
    WA3                : TEdit;
    WA4                : TEdit;
    WA5                : TEdit;
    WA6                : TEdit;
    WB1                : TEdit;
    WB2                : TEdit;
    WB3                : TEdit;
    WB4                : TEdit;
    WB5                : TEdit;
    WB6                : TEdit;
    WD1                : TEdit;
    WD2                : TEdit;
    WD3                : TEdit;
    WD4                : TEdit;
    WD5                : TEdit;
    WD6                : TEdit;

    Kilep              : TTimer;

    // --------------------------------------------------------------

    procedure AdatBevitelkesz(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure ArfelterWrite;
    procedure ArfolyamGombClick(Sender: TObject);
    procedure ArfolyamotModosit;
    procedure ArfolyamKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BankjegyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Bizregiszter(_xbiz: string);
    procedure BlokkFejIro;
    procedure BlokktetelIro;
    procedure DnemKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EngedelyezoKijeloles;
    procedure EnggombClear;
    procedure EscapeGombClick(Sender: TObject);
    procedure EurErmeKonvertalas;
    procedure ETGOMBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ENGSHAPEMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ETGOMBClick(Sender: TObject);
    procedure KezdijEngedmenyGombClick(Sender: TObject);
    procedure Figyelmeztetes;
    procedure FizetendoDisplay;
    procedure Folytatas;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IgenKilepGombClick(Sender: TObject);
    procedure KezdijBeepites(_kk: integer);
    procedure KezdijRogzito;
    procedure KezdijTablaBeolvasas;
    procedure Kilepniakar;
    procedure KilepTimer(Sender: TObject);
    procedure KisugyfelLerendezes;
    procedure MakeXml;
    procedure NemlepkiGombClick(Sender: TObject);
    procedure NemlepkiGombEnter(Sender: TObject);
    procedure NemlepkiGombExit(Sender: TObject);
    procedure QrKodLerendezes;
    procedure RemoteLerendezes;
    procedure RemoteJogiLerendezes;
    procedure RemoteParancs(_ukaz: string);
    procedure SorBeirasVTempbe(_y: byte);
    procedure TablaNullazas;
    procedure TombBeToltes;
    procedure UgyfdataVtempbol;
    procedure Ujraszamolas;
    procedure ValutaParancs(_ukaz: string);
    procedure ValtozokNullazasa;
    procedure VtempDataPotlas;
    procedure WA1DblClick(Sender: TObject);
    procedure WD1Enter(Sender: TObject);
    procedure WD1Exit(Sender: TObject);
    procedure XMLBemasolas;

    function CHChange(_inkod: byte): byte;
    function DropHung(_eTXt: string): string;
    function EuKontrol: boolean;
    function Elokieg(_szo: string;_hh: integer):string;
    function ForintForm(_osszeg:integer):string;
    function GetBizonylatSzam(_write: boolean): string;
    function GetDnemAdatok(_zdnem: string): byte;
    function GetIdos:string;
    function GetKedvArf(_adnem: string): integer;
    function GetKezelesiDij(_ss: integer): integer;
    function GetNapdiff(_n1,_n2: string): extended;
    function GetsajathatasKoru: byte;
    function GetTetelsor(_dn: string): byte;
    function Hustrtodate(_ds: string): TDateTime;
    function Kerekito(_int: integer): integer;
    function Napidiff(_d1,_d2: string): integer;
    function Nulele(_b: integer;_hh: byte): string;
    function String2Date(_s: string): TDatetime;
    function VanIlyenDnem(_adnem: string): boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  VasarlasForm: TVasarlasForm;

  _host     : string;

  _piras    : Textfile;
  _rounder  : Real = 0.001;
  _logmess  : pchar;

  _wd,
  _wa,
  _wb: array[1..6] of TEdit;

  _wn,
  _wf: array[1..6] of TPanel;

  _wbankjegy,
  _wertek: array[1..6] of Integer;

  _wdnem,
  _wdnev: array[1..6] of string;

  _sorengedmeny,
  _wArfolyam,
  _wOrigarfolyam,
  _wKedvezmenyes,
  _wElszamolasi: array[1..6] of integer;

  _kdij        : array[1..23] of integer;
  _tranzsav    : array[1..23] of integer;

  _engGombok   : array[1..4] of TPanel;

  // ----------------------------------------------------------

  _aktdatum,_aktidos,_aktpenztarszam,_plombaszam,_lastdatum       : string;
  _bizonylatszam,_trbpenztar,_ugyfeltipus,_tranzstring,_ugyfelcim : string;
  _megnyitottnap,_adoszam,_irszam,_varos,_utca                    : string;
  _pcs,_aktdnem,_aktdnev,_ugyfelnev,_elojel                       : string;
  _okmanytipus,_azonosito,_megbizonev,_megbizocim,_telephely      : string;
  _megbizottnev,_aktprosid,_aktpenztarosnev,_idos,_lastfejbiz     : string;
  _aktugyfelnev,_bizelokod,_megbizottcim,_keres,_anyja            : string;
  _recnums,_zcounts,_aktnums,_forras,_engedelyezo                 : string;
  _szulido,_szulhely,_allampolg,_lakcim,_hptnev,_tarthely         : string;
  _localpath,_remotefile,_body,_mailstring,_nevtabla              : string;
  _mbvaros,_mbutca,_mbttvaros,_mbttutca,_remotePath,_MESS         : string;
  _homePenztarKod,_aktbs,_kisRemotePath,_biztabla,_kbetu          : string;
  _lakcimcard,_iso,_MBDATA,_mbs,_hasdnem,_kartyaszam              : string;

  _sorveg: string = chr(13)+chr(10);

  _top,_left,_width,_height,_kedvword,_trdb,_mbszam,_megbizott    : word;

  _ezKonverzio,_ezegyedikezdij,_securlevel                        : boolean;
  _volt8,_toomany,_voltshk,_voltkedvezmeny                        : boolean;

  _kulfoldi,_lastsor,_ratetype,_tetel,_fizetoeszkoz               : byte;
  _oszlop,_bill,_aktRateType,_coin,_saveaktsor,_spk,_konverzio    : byte;
  _kozszereplo,_secur,_tulajdarab,_storno,_maistornodarab,_hptn   : byte;
  _cardTip,_found,_kozszerep,_WW,_aktsor,_z,_shk,_qq,_aktsorenged : byte;
  _rateEngKod,_negykezdij,_aktsoreng,_serverAccess,_scanType      : byte;

  _napdiff                                                        : extended;

  _kezdijengedmenytip,_kezelesidij,_fixKezelesiDij,_minkezdij     : integer;
  _mresult,_origkezdij,_fizetendo,_evimax,_hetift,_voltermeakcio  : integer;
  _megbizoszam,_megbizottszam,_netto,_ugyfelszam,_sorszam,_diff   : integer;
  _mekd,_realezrelek,_tag,_code,_aktertek,_kezdijmax,_sorertek    : integer;
  _aktarfolyam,_origarfolyam,_aktVarf,_aktelszarf,_aktbankjegy    : integer;
  _kedvarfolyam,_kerekitendo,_aktzaro,_goke,_fto,_max,_heti,_mbss : integer;
  _modoke,_ujarfolyam,_cc,_aktsorkedv,_recno,_megbizo,_arfback    : integer;
  _aktadatlapszam,_sumertek,_aktugyfelszam,_maxsavdb,_nyugoke     : integer;
  _lastbuyBlokknum,_brutto,_kerekites,_forroke,_scanoke,_aktdek   : integer;
  _buyOke,_kellcimlet,_bignum,_engok,_aktshk                      : integer;
  _uOke,_aktKedvArf,_mshk,_fx,_aktorigarf,_pluszOsszeg            : integer;

function arfolyamkijelzes(_para:string): integer;stdcall; external 'c:\valuta\bin\Arfdisp.dll';
function bescannelorutin: integer; stdcall; external 'c:\valuta\bin\scanning.dll';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\valuta\bin\bloknyom.dll';
function confirmrutin: integer; stdcall; external 'c:\valuta\bin\confirm.dll';
function copyfiletoftprutin: integer; stdcall; external 'c:\valuta\bin\copy2ftp.dll';
function euakciokerdo: integer; stdcall; external 'c:\valuta\bin\eusakcio.dll';
function getnyugtarutin: integer; stdcall; external 'c:\valuta\bin\getnyug.dll';
function kellcimletrutin: integer; stdcall; external 'c:\valuta\bin\kellcim.dll';
function kezdijkedvezmeny: integer; stdcall; external 'c:\valuta\bin\kezdkedv.dll';
function kisarfolyamkedvezmeny: integer; stdcall; external 'c:\valuta\bin\kisarfvalt.dll';
function bigarfolyamkedvezmeny: integer; stdcall; external 'c:\valuta\bin\bigarfvalt.dll';
function kiscimletezes: integer; stdcall; external 'c:\valuta\bin\kiscim.dll';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll';
function procendrutin: integer; stdcall; external 'c:\valuta\bin\procend.dll';
function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\qrgener.dll';
function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll';
function ugyfelrutin: integer; stdcall; external 'c:\valuta\bin\ugyfel.dll';
function ujokmanyszkennelo: integer; stdcall; external 'c:\valuta\bin\scanner.dll';

function vasarlasrutin: integer; stdcall;

implementation

{$R *.dfm}

{   1.Fázis := Adatbevitel kész


}
{
  ------------------------------------------------------------------------------

  BIGCTRL.DLL: Input : ugyfeltipus,ugyfelszam,fizetendo,konverzio,bizonylatszam
  -----------  Output: gongyolt,sorszam,nevtabla,forras,engedelyezo,plombaszam

               Az input-output a VTEMP-en keresztül bonyolódik

               result :  1 = ugyfél könyvelve - minden rendben
                         2 = tranzakció STOP ! Nem folytatható !
                         3 = nem volt ugyfelszam vagy nincs internet
}

// =============================================================================
                    function VasarlasRutin: integer; stdcall;
// =============================================================================

begin
  VasarlasForm := TVasarlasForm.Create(Nil);
  Result := VasarlasForm.Showmodal;
  VasarlasForm.Free;
end;

// =============================================================================
              procedure TVasarlasForm.FormActivate(Sender: TObject);
// =============================================================================

begin

  logirorutin(pchar('...'));

  logirorutin(pchar('---------------------------------'));
  logirorutin(pchar('     Valuta vásárlásba kezd'));
  logirorutin(pchar('---------------------------------'));
  logirorutin(pchar('...'));

// ----------------------------------------------------------------------------
// VTEMP-bõl beolvassa   : _konverzio
// HARDWARE-böl beolvassa: _realezrelek,_megnyitottnap,_aktPenztarosnev,_aktprosid,_host
// PENZTAR-ból beolvassa : _homepenztarkod,_hptnev
// Megállapitja _bizelokod és _ezkonverzio értékét

  AlapadatBeolvasas;

  //Az aktuális évtized megûllaõitása:
  _aktdek  := yearof(Date)-2000;

  // Az ugyfelyy.fdb és kisugyfel.fdb elérési útvonalámak megállaõítása:
  _remotePath    := _host+':c:\receptor\database\ugyfel' + inttostr(_aktdek) + '.fdb';
  _kisremotePath := _host + ':c:\receptor\database\kisugyfel.fdb';

  // --------------------------------------------------------------------------
  // Az összes lényeges változó kinullázása:
  // forras,engedelyezo,nevtabla,aktpenuzarszam,plombaszam,trbpenztar
  // kartyaszam,ugyfelnev,ugyfeltipus,lakcim stringek üritése
  // sorszam,fizetendo,kezdijengedmenytip,kulfoldi,lastsor,megbizoszam,
  // megbizottszam,netto,origkezdij,ratetype,tetl,ugyfelszam nullázása
  // fizetoeszkoz,mresult = 1
  // fixkezelesidij       = -1
  // egyedikezdij,securlevel,voltshk hamisra állitása
  ValtozokNullazasa;

  // A VTEMP adatbázis kiüritése:
  ValutaParancs('DELETE FROM VTEMP');

  // Az öt tábla-oszlop tömbökbe illesztése + engedélyezés tipus gombok is:
  TombBeToltes;

  // A tábla-editek, valutanevek, arfolyamok, értékek lenullázása:
  TablaNullazas;

  // ------------------------------------------------------------------------
  // Beolvassa a kezelési dij-táblázat adatait tömbbökbe:
  KezdijTablaBeolvasas;

  // ------------------------------------------------------------------
  // A konverzió-flagtõl függöen, kiirja vagy nem, hogy konverziós vásárlás:
  if _ezKonverzio then
    begin
      Konvcimpanel.Visible    := True;
      KonvsumPanel.Visible    := True;
      logirorutin(pchar('Ez konverziós vásárlás lesz'));
    end else
    begin
      KonvCimpanel.Visible    := False;
      KonvSumPanel.visible    := False;
    end;

  // ----------------------------------------------------------------------
  // Saját hatáskörü kedvezmény kijelzése:

  _shk  := GetSajatHataskoru;
  _mShk := 5-_shk;

  ShkPanel.Caption := inttostr(_mshk);
  ShkPanel.Repaint;

  // ----------------------------------------------------------------------
  // A kezelési költség kalkulálásának kijelzése:

  if _realEzrelek>0 then _tranzString := inttostr(_realEzrelek)+' %%';
  if _realEzrelek=0 then _tranzString := 'nincs';
  if _realEzrelek<0 then _tranzString := 'sávos';

  EzrelekPanel.Caption := _tranzString;
  EzrelekPanel.repaint;

  // ----------------------------------------------------------------------
  // Az átmeneti bizonylatszám bekérése és kijelzése: (csak olvasva):

  _bizonylatSzam := GetBizonylatSzam(False);
  logirorutin(pchar('Elözetes bizonylatszám: '+ _bizonylatszam));
  BizonylatLabel.Caption := _bizonylatSzam;

  // -----------------------------------------------------------------------
  // Elsó valuta bekérésre elõkészitve:

  wd1.Enabled   := True;
  ActiveControl := wd1;
end;

// =============================================================================
      procedure TVasarlasForm.DnemKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================
//           A valutanem mezõbe irt egy betût:

begin
  _bill   := ord(key);   //  Beirt betü kódja

  // Betüket nem kell értékelni:
  if (_bill>64) AND (_bill<91) then exit;

  // A valutanem-edit melyik sorban van (1..6):
  _aktsor := TEdit(Sender).Tag;

  // Entert nyomott a valutanem oszlopára:
  if _bill=13 then
    begin

      // A beirt Dnem kódot kiolvasása:
      _aktDnem := trim(_wd[_aktsor].text);

      // Forintot nem veszünk:
      if _aktDnem='HUF' then
        begin
          ShowMessage('A FORINT NEM VÁLASZTHATÓ VALUTA');
          _wd[_aktsor].Text := '';
          exit;
        end;

      // Beolvassa: arfolyamai,aktuális készlete és hosszú neve
      _found := GetDnemAdatok(_aktdnem);

      // Nincs ilyen bankjegy !!!! (Nem találta az arfolyamtáblában)
      if _found=0 then
        begin
          ShowMessage('Nincs ilyen valutanem');
          _wd[_aktsor].Text := '';
          exit;
        end;

      // Ha már feljebb beirta ezt a valutanemet - mégegyszer nem lehet:
      if vanIlyenDnem(_aktdnem) then
        begin
          _wd[_aktSor].Text := '';
          exit;
        end;

      // Itt rendben van a valuta neve - beirja a megfelelõ tömbbe:
      _wdnem[_aktsor] := _aktdnem;

      // Az árfolyamok és a valutanev tömbbökbe tárolása:

      _aktArfolyam            := _aktVarf;
      _wArfolyam[_aktsor]     := _aktArfolyam;
      _wOrigArfolyam[_aktsor] := _aktarfolyam;
      _wElszamolasi[_aktsor]  := _aktElszarf;
      _wDnev[_aktsor]         := _aktdnev;

      _wd[_aktsor].Enabled    := False;  //  sor valutanem-oszlopa letiltva
      _wa[_aktsor].Enabled    := True;   // Az aktuális sor arfolyam mezõje
      _wb[_aktsor].Enabled    := True;   // és bankjegy mezõje megnyitva

      // A sor celláiba beirja a valuta -nemét,-nevét és árfolyamát:
      _wd[_aktsor].Text       := elokieg(_aktdnem,5);
      _wn[_aktsor].Caption    := _aktdnev; // Beirja a valuta nevét
      _wa[_aktSor].Text       := elokieg(intToStr(_aktArfolyam),11);

      // Az arfolyamgomb, vegegomb, és kezdijgomb letiltva a fél sor miatt:

      Endgomb.Enabled             := False;
      ArfolyamGomb.enabled        := False;
      Kezdijengedmenygomb.enabled := False;

      // Az aktuális oszlop a bankjegy-oszlop lesz:
      Activecontrol := _wb[_aktsor];
      exit;
    end;

  // A felfele kurzort nyomta meg:
  If _bill=38 then
    begin
      // A legfelsõ sorról nincs felfele:
      if _aktsor=1 then exit;

      // Az aktiv sor az eggyel feljebbi sor bankjegy oszlopa lesz:
      Activecontrol := _wb[_aktsor-1];
      exit;
    end;

  // A 'Készen van' gombot nyomta meg:
  if _bill=35 then
    begin

      // Ha már van tétel a táblázatban vége a valuták beviteléhez:
      if _tetel>0 then
        begin
          Endgomb.Enabled := True;
          Adatbevitelkesz(Nil);  // Nincs tovább adatbevitel
        end;
      exit;
    end;
end;

// =============================================================================
      procedure TVasarlasForm.BankjegyKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================
//           A bankjegy mezõbe irt egy számot:

begin
  _bill   := ord(key);   //  Beirt betü kódja

  // A szájegyek beirását nem vizsgálja:
  if (_bill>47) and (_bill<58) then exit;

  // A numpadon beirt számokat sem vizsgálja:
  if (_bill>95) and (_bill<106) then exit;

  // Megállapitja, hányadik sort szerkeszti:
  _aktsor := TEdit(Sender).Tag;

  // A sorhoz tartozó valutanem kiolvasása:
  _aktdnem := trim(_wd[_aktsor].text);

  // Enter nyomott a bankjegy-oszlopában:
  if _bill=13 then
    begin

      // A szám stringesitett adata:
      _aktBs := trim(_wb[_aktSor].text);

      // A string konvertálása akbankjegy integerbe:
      val(_aktBs,_aktBankJegy,_code);
      if _code<>0 then _aktbankjegy := 0;
      if _aktbankjegy=0 then exit;

      _wbankjegy[_aktsor] := _aktbankjegy;

      // Ez egy újabb tétel sor a számlán:
      if _tetel<_aktsor then inc(_tetel);

      // A tényleges árfolyam kiolvasása a sor tömbjébõl:
      _aktarfolyam     := _wArfolyam[_aktsor];

      // A sor forintértékének kiszámolása a valutanemtõl függõen:
      _aktErtek := round((_aktArfolyam/100*_aktBankjegy)+_rounder);
      if _aktDnem='JPY' then _aktertek := round(_aktertek/10);

      // A bankjegy és sorérték kiirása a számla táblájába:
      _wb[_aktsor].Text    := elokieg(inttostr(_aktbankjegy),10);
      _wf[_aktSor].Caption := EloKieg(ForintForm(_aktErtek),11);

      // Az érték tömbbe irása:
      _wErtek[_aktsor]    := _aktertek;

      // A tételsor adatait beirja a VTEmp táblába:
      SorbeirasVtempbe(_aktsor);

      if _aktdnem='EUA' then _voltermeakcio := euakciokerdo;

      // A teljes számla kiszámolása és kijelzése az eddigi adatok alapján:
      FizetendoDisplay;

      // Ha betelt a számla mind a 6 sora, akkor kilép:
      if _tetel=6 then exit;

      // Ha e legalsó sor most aktuális, akkor nyitok egy új sort:
      if _tetel=_aktsor then
        begin
          inc(_aktsor);

          // A következõ sor valutanem oszlopát teszi aktuálissá:
          _wd[_aktsor].Enabled := True;
          ActiveControl        := _wd[_aktsor];
        end;

      // A 'Készen van', 'Arfolyam' és a 'Kezdijengedmény' gombot felszabaditása:
      Endgomb.Enabled             := True;
      Arfolyamgomb.Enabled        := True;
      KezdijengedmenyGomb.Enabled := True;
      if _voltermeakcio=1 then KezdijengedmenyGomb.Enabled := False;
      exit;
    end;

  // A balra kurzor gombot nyomta meg:
  if _bill=37 then
    begin

      // Ha meg nincs beirva a Bankjegy lrtlke, akkor kilép:
      if _wbankjegy[_aktsor]=0 then exit;

      // HA be van irva már a bankjegy, akkor a sor árfolyam mezõje lesz aktiv:
      ActiveControl := _wa[_aktsor];
      exit;
    end;

  //  A felfele kuzor gombot nyomta meg:
  if _bill=38 then
    begin
      // Legfelsõ sorról nincs fellépés:
      if _aktsor=1 then exit;

      // Az eggyel feljebbi sor bankjegy mezõje lesz az aktiv edit:
      ActiveControl := _wb[_aktsor-1];
      exit;
    end;

  // A lefele kurzor gombot nyomta meg:
  if _bill=40 then
    begin

      // Ha van még lejebb is sor - akkor annak bankjegy mezõjére lép:
      if _tetel>_aktsor then
        begin
          ActiveCOntrol := _wb[_aktsor+1];
          exit;
        end;


      if (_tetel=_aktsor) and (_aktsor<6) then
        begin

          // HA a legalsó sor aktiv és még lehet újabb sor a következõ sor Valutanem-Editje lesz aktiv
          _wd[_aktsor+1].Enabled := True;
          Activecontrol := _wd[_aktsor+1];
          exit;
        end;
    end;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//////////////////         ARFOLYAM KEDVEZMÉNYEK       /////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
      procedure TVasarlasForm.ArfolyamKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================
//             Az árfolyam mezõre billentyüt nyomott

begin
  _bill   := ord(key);              //  Beirt betü kódja

  // Meghatározza, melyik sor aktiv:
  _aktsor := TEdit(Sender).Tag;

  // Entert nyomott az árfolyam oszlopon: (kedvezményt akar adni);
  if _bill=13 then
    begin

      // Ha már van a soron engedmény - itt nincs több lehetõség:
      if _sorengedmeny[_aktsor]>0 then
        begin
          ShowMessage('AZ ÁRFOLYAM MÁR MÓDOSÍTVA VAN !');
          exit;
        end;

      // Itt módosithatja az árfolyamot:
      ArfolyamotModosit;
      exit;
    end;

  // A felfele kurzor billentyüt nyomta meg:
  if _bill=38 then
    begin

      // Az elsö sorról nincs felfele:
      if _aktsor=1 then exit;

      // Az aktuális az eggyel feljebbi sor arfolyam mezõje::
      ActiveControl := _wa[_aktsor-1];
      exit;
    end;

  // A jobbra kurzor gombot nyomta meg:
  if _bill=39 then
    begin

      // Az aktuális oszlop a bankjegy oszlopa lesz:
      Activecontrol := _wb[_aktsor];
      exit;
    end;

  // A lefele kurzor gombot nyomta meg:
  if _bill=40 then
    begin

      // Ha több a tétel mint az aktuális sor:
      if _tetel>_aktsor then
        begin

          // Az aktuális edit a következõ sor árfolyamoszlopa:
          ActiveCOntrol := _wa[_aktsor+1];
          exit;
        end;

      // Ha nem a 6-ik sor az aktuális:
      if (_tetel=_aktsor) and (_aktsor<6) then
        begin
          // Az aktuális mezö a következõ sor (a legalsó) valutanem oszlopa lesz:
          Activecontrol := _wd[_aktsor+1];
          exit;
        end;
    end;
end;

// =============================================================================
            procedure TVasarlasForm.WA1DblClick(Sender: TObject);
// =============================================================================
//           Árfolyam engedmény kérés az értéktártól

begin
  _aktsor := Tedit(sender).Tag;
  if _sorEngedmeny[_aktSor]>0 then
    begin
      ShowMessage('EZ MÁR KEDVEZMÉNYES ÁRFOLYAM');
      exit;
    end;
  ArfolyamotModosit;
end;

// =============================================================================
                 procedure TVasarlasForm.ArfolyamotModosit;
// =============================================================================

// Az árfolyam-oszlopra kettintott:
// Az árfolyam módosulhat és utána le is rendezi a változást

begin
  // Ha már az aktuális oszlop árfolyama kedvezményes - mégegyszer nem lehet
  if _sorEngedmeny[_aktSor]>0 then
    begin
      ShowMessage('Ez már módositott árfolyam !');
      ActiveControl := EndGomb;
      exit;
    end;

  // Ha már adott a kezelési díjra engedményt -> nincs árfolyam-kedvezmény
  if _kezdijEngedmenyTip>0 then
    begin
      ShowMessage('KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !');
      exit;
    end;

  // kedvezményre jelölt valutanem VTEMP soráBA a 'MEGJEGYZES'-be '!'-t ir
  _aktdnem := _wDnem[_aktsor];
  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'!'+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
  ValutaParancs(_pcs);

  // Meghivja a bigarfolyamkedvezmény dll-ét
  _arfback := bigarfolyamkedvezmeny;

  // A visszatérõ minusz 1 jelzi, hogy mégsem ad árfolyamkedvezményt:
  if _arfBack=-1 then exit;

  _voltkedvezmeny := True;

  // Sikeresen módosult a kért valutanem árfolyama. Regeneráljuk a számlát:
   Ujraszamolas;
end;

// =============================================================================
           procedure TVasarlasForm.ArfolyamGombClick(Sender: TObject);
// =============================================================================
//                 Pénztáros által adott árfolyam kedvezmény  F1-GOMB

begin
  // hA MÁR ADOTT KEZELÉSI DÍJ KEDVEZMÉNYT -> Nics árfolyamkedvezmény
  if _kezdijEngedmenyTip>0 then
    begin
      ShowMessage('KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !');
      exit;
    end;

  // Meghivja a kisarfolyamkedvezmény dll-jét:
  _arfback := kisarfolyamkedvezmeny;

  if _arfback = -1 then exit;
  if _arfback =  2 then _voltshk := True;
  Ujraszamolas;
end;

// =============================================================================
              procedure TVasarlasForm.Ujraszamolas;
// =============================================================================

// A számla adatváltozása után újra rendezi a számlák adatait:


begin
  // A VTEMP-bõl kiolvassa: ARFOLYAMOT,BANKJEGYET,KEDV.ARFOLYAMOT,SORENGEDMENYT
  // a kiolvasott adatokat a megfelelõ valutanemek tömbjeibe irja, miközben
  // számitja az egyes sorok forint-értékeit

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM VTEMP');
      Open;
    end;

  while not ValutaQuery.Eof do
    begin
      _aktdnem := ValutaQuery.fieldByNAme('VALUTANEM').asString;
      _aktsor  := GetTetelsor(_aktdnem);

      _aktarfolyam := ValutaQuery.FieldByNAme('ARFOLYAM').asInteger;
      _aktbankjegy := ValutaQuery.FieldByNAme('BANKJEGY').asInteger;
      _aktkedvArf  := ValutaQuery.FieldByName('KEDVEZMENYESARFOLYAM').asInteger;
      _aktsorenged := ValutaQuery.FieldByNAme('SORENGEDMENY').asInteger;

      _wArfolyam[_aktsor]     := _aktArfolyam;
      _wKedvezmenyes[_aktsor] := _aktKedvarf;
      _wBankjegy[_aktsor]     := _aktBankjegy;
      _sorengedmeny[_aktsor]  := _aktsorenged;

      _aktertek := round((_aktarfolyam/100*_aktBankjegy)+_rounder);
      if _aktdnem='JPY' then _aktertek := round(_aktertek/10);
      _wErtek[_aktsor] := _aktertek;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  // ----------------------------------------
  // A kiolvasott és számított adatokat kijelzi és beirja VTEMP-be.

  _qq := 1;
  while _qq<=_tetel do
    begin
      _aktdnem := _wDnem[_qq];
      _aktertek := _wErtek[_qq];
      _wa[_qq].Text := elokieg(inttostr(_wArfolyam[_qq]),11);
      _wb[_qq].Text := elokieg(inttostr(_wBankjegy[_qq]),10);
      _wf[_qq].Caption := elokieg(forintform(_aktertek),11);

      _pcs := 'UPDATE VTEMP SET FORINTERTEK=' + inttostr(_aktertek) + _sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);
      ValutaParancs(_pcs);

      inc(_qq);
    end;

  // A számitott adatokat kijelzi azokat:
  FizetendoDisplay;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//////////////////     KEZELÉSI DÍJ KEDVEZMÉNYEK       /////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
         procedure TVasarlasForm.KezdijEngedmenyGombClick(Sender: TObject);
// =============================================================================

begin
  // Ha már adott kezelési díjra kedvezményt -> nincs több
  if _kezdijEngedmenyTip>0 then exit;

  // Ha itt nncs is kezelési dijadás kötelezettség -> ennyi
  if _realEzrelek=0 then exit;

  _ezegyedikezdij     := False;

  // Belép a kezdkedv.dll programba:
  _kezdijengedmenytip := kezdijkedvezmeny;

  // Ha kapott kezelésidíj-kedvezményt:
  if _kezdijengedmenytip>0 then
    begin
      // A számla letiltva a tüvábbi módositások elöl:
      SzamlaAlaplap.Enabled       := False;
      KezdijEngedmenyGomb.Enabled := False;

      // Beolvassa a kezelési dijat és a kártyaszámot:
      Valutadbase.Connected := true;
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          sql.add('SELECT * FROM VTEMP');
          Open;
          _fixkezelesidij := FieldByNAme('KEZELESIDIJ').asInteger;
          _kartyaszam := trim(FieldByNAme('KARTYASZAM').asString);
          close;
        end;
      valutadbase.close;

      // Ha kezdijengedmény tipus=6 akkor ez egyedi kezelési dij
      if _kezdijengedmenytip=6 then _ezegyedikezdij := True;
    end;
  FizetendoDisplay;
end;

// =============================================================================
                procedure TVasarlasform.FizetendoDisplay;
// =============================================================================

begin
  _netto := 0;

  // Összegezi a tételek értékét: -> netto és számolja a tételt -> _tetel
  _z := 1;
  while _z<=_tetel do
    begin
      _netto := _netto + _wErtek[_z];
      inc(_z);
    end;


  // Az alap (kiszámitott) kezelési dij:
  _origkezdij := Getkezelesidij(_netto);

  // Ha még nincs eltéritett kezelési dij, akkor marad az eredeti kez-i dij:

  if _fixKezelesiDij=-1 then _kezelesidij := _origkezdij
  else _kezelesidij := _fixkezelesidij;

  if _kezelesidij<0 then _kezelesidij := 0;

  if _voltermeakcio=1 then
    begin
      _kezelesidij := 0;
      Kezdijengedmenygomb.Enabled := False;
    end;

  _brutto    := _netto - _kezelesiDij; // vásárlásnál minusz !!!
  _fizetendo := Kerekito(_brutto);
  _kerekites := _fizetendo-_brutto;

  KerekitesPanel.Caption := intTostr(_kerekites);
  KerekitesPanel.Repaint;

  GetdnemAdatok('HUF');
  if _fizetendo>_aktzaro then
     begin
       ShowMessage('NINCS ENNYI FORINT KÉSZLETÜNK !');
       exit;
     end;

  if (_kezdijengedmenytip<1) then Kezdijengedmenygomb.enabled := True;

  _pcs := 'UPDATE VTEMP SET NETTO='+inttostr(_netto)+',ORIGKEZDIJ='+inttostr(_origkezdij);
  _pcs := _pcs + ',OSSZESFORINTERTEK='+inttostr(_netto);
  _pcs := _pcs + ',BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  _pcs := _pcs + ',ELOJEL=' + chr(39) + '+' +chr(39);
  _pcs := _pcs + ',TETEL=' + inttostr(_tetel);
  _pcs := _pcs + ',KEREKITES=' + inttostr(_kerekites);
  _pcs := _pcs + ',KEZELESIDIJ=' + inttostr(_kezelesidij);
  _pcs := _pcs + ',FIZETENDO=' + inttostr(_fizetendo);
  if _ezkonverzio then _pcs := _pcs + ',KONVERZIO=1';
  ValutaParancs(_pcs);

  NettoPanel.Caption     := ForintForm(_netto);
  TranzdijPanel.Caption  := ForintForm(_kezelesidij);
  SumosszegLabel.caption := ForintForm(_fizetendo);
end;


// =============================================================================
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%  AZ ADATBEVITELT BEFEJEZTEM  %%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TVasarlasForm.AdatbevitelKesz(sender:TObject);
// =============================================================================

// Itt befejezte a váltandó valuták bevitelét !
// Az esetleges kedvezményeket az árfolyamban illetve kezelési dijban lezártuk

begin
  logirorutin(pchar('Befejezte a vásárlási ürlap kitöltését'));

  Endgomb.Enabled             := False; // Többször nem nyomható le
  SzamlaAlapLap.Enabled       := False; // Nincs több tételmódositás
  KezdijengedmenyGomb.Enabled := False; // Nincs lehetõség kezdijengedmény adásra
  Arfolyamgomb.Enabled        := False; // Kis árengedmény nem adható

  // -----------------------------
  // Az üres tételsorok kitörlése:
  _pcs := 'DELETE FROM VTEMP' + _sorveg;
  _pcs := _pcs + 'WHERE BANKJEGY=0';
  ValutaParancs(_pcs);

  // --------------------------------------------------
  // Sajáthatáskörü kedvezmények lekönyvelése, ha volt:

  If _voltShk then
    begin
      inc(_shk);
      _pcs := 'UPDATE HARDWARE SET SAJATHATASKORU='+inttostr(_shk);
      ValutaParancs(_pcs);

      _mess := 'Sajáthatáskörü kedvezmény volt. Maradt '+inttostr(5-_shk);
      logirorutin(pchar(_mess));
    end;

  // -------------------------------------
  // Az esetleges EURÓ érmék konvertálása:

  EurErmeKonvertalas;

  // Kijelzi a fizetendó összeget:
  FizetendoDisplay;

  // ---------------------------------------------------------------

  // A lehetséges árfolyam kedvezmény engedélyezõjének lekezelése:

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _rateType := FieldByNAme('RATETYPE').asInteger;
      Close;
    end;
  Valutadbase.close;

  _rateEngKod := 0;

  if _ratetype=8 then EngedelyezoKijeloles
  else Folytatas;
end;

// =============================================================================
            procedure TVasarlasForm.EngedelyezoKijeloles;
// =============================================================================

begin
  // Amennyiben volt nagyobb árfolyamkedvezmény, itt beklri az engedélyezés tipusát
  with EngedelyadoPanel do
    begin
      top     := 224;
      left    := 296;
      Visible := True;
      repaint;
    end;
  Activecontrol := etgomb;
end;

// =============================================================================
           procedure TVasarlasForm.ETGOMBClick(Sender: TObject);
// =============================================================================

var _etips: string;

begin
  // A 4 engedélyadás tipusa közül választott egyet: (16,32,64,128)

  _rateEngKod := TPanel(sender).Tag;
  EngedelyadoPanel.Visible := False;

  // A VTEMP-be irja a megfelelõ árfolyam engedély tipusát = 16m32m64 vagy 128
  _pcs := 'UPDATE VTEMP SET RATETYPE=' + inttostr(_rateEngKod);
  ValutaParancs(_pcs);

  _mess := 'Az árfolyam kedvezmény: ';
  case _rateEngKod of
    16 : _etips := ' értéktárosi';
    32 : _etips := ' fõértéktárosi';
    64 : _etips := ' ügyvezetõi';
    128: _etips := ' jutalékmentes';
   end;
  _mess := _mess + _etips + ' engedéllyel';

  logirorutin(pchar(_mess));
  Folytatas;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                    procedure TVasarlasForm.Folytatas;
// =============================================================================

begin
  //  Itt folytatódik a számla lekönyvelése:

  // Ha nincs mit fizetni - kilép a tranzakcióból:

  if _fizetendo=0 then
    begin
      _Mresult := -1;
      Kilep.Enabled := True;
      exit;
    end;

  // ---------------------------------------------------------------------------

  // Van-e ennyi forint ?

  GetDnemAdatok('HUF');

  if _fizetendo>_aktzaro then
    begin
      // Nincs elég pénzünk - tranzakció befejezve:
      logirorutin(pchar('Nincs elég forint a pénztárban a tranzakcióhoz'));
      ShowMessage('NINCS ENNYI FORINTUNK KÉSZLETEN !');

      _Mresult := -1;
      Kilep.Enabled := true;
      exit;
    end;

 // ----------  itt kell a VTEMP hiányzó adatait pótolni ----------------------

   VTempDataPotlas; // dátum,ido,pénztárosnev,idkod,storno

// itt van vége az elsõ fázisnak -----------------------------------------------

  // ===========================================================================
  //////////////////////////////////////////////////////////////////////////////
  ////////////////     ÜGYFÉL LERENDEZÉSE     //////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  {
  // ---------------------------------------------------------------------------
  // ügyfelrutin back-kod: -1= A teljes tranzakció stornó
                            1= Ügyfel azonositva,
                            2= Nem kell, és nem is azonositotta magát
                            3= Kisugyfelet azonositottak
   }

  // Beállitjuk az ügyfél adatait:

  _uOke := ugyfelrutin;

  // --------------------------------------------------
  // Ha az ügyfél nem azonositja magát (pedig kellene) - tranzakció stornó

  if (_uoke=-1) then
    Begin
      logirorutin(pchar('Nem akarja azonositani magát. Tranzakció stornó'));
      _mResult := -1;
      Kilep.Enabled := True;
      Exit;
    end;

  // -----------------------------------------------------------
  // Az igazolványok beszkennelése:

  If _uOke=1 then
    begin
      // Bescaneli az okmányokat:
      logirorutin(pchar('...'));
      logirorutin(pchar('Okmányok beszkennelése'));

      if _ScanType=1 then _ScanOke := ujokmanyszkennelo
      else _scanOke := bescannelorutin;

      // Sikertelen scannelés: ekkor a tranzakció befejezve:

      if _scanOke=-1 then
        begin
          logirorutin(pchar('Nem sikerült a szkennelés'));
          logirorutin(pchar('...'));

          _mresult := -1;
          Kilep.Enabled := True;
          exit;
        end;
    end;

//  itt van vége a 2-ik fázisnak:

  UgyfDataVtempbol;

  logirorutin(pchar('...'));

  // ===========================================================================
  //////////////////////////////////////////////////////////////////////////////                                                                          //
  //////////////////   ITT VÉGLEGESITHETÕ A TRANZAKCIÓ   ///////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // ===========================================================================
  // Utolsó kérdés: Mehet-e a tranzakció ?

  _buyOke := confirmRutin;

  // ------------------------------------------
  // Mégsem endedélyezi a tranzakciót a pénztáros . Vissza a fõmenüre

  if _buyOke<>1 then
    begin
      logirorutin(pchar('A pénztáros leállitotta a tranzakciót'));
      _mResult := -1;
      Kilep.Enabled := true;
      Exit;
    end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
///////////////////////    A TRANZAKCIÓ ENGEDÉLYEZVE  //////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================

  // Meghatározza a végleges bizonylatszámot:

  logirorutin(pchar('A tranzakciót engedélyezte a pénztáros'));
  logirorutin(pchar('...'));

  _bizonylatSzam := Getbizonylatszam(True);

  if _ugyfelTipus='K' then KisugyfelLerendezes;  // _uoke=3
  if _uoke=1 then RemoteLerendezes;

  // A NAPIEGYEDIKEZDIJ darabszámának léptetése, ha volt egyedi kezelési díj:

  if _ezEgyediKezdij then
    begin
      inc(_nEgykezdij);
      _pcs := 'UPDATE HARDWARE SET NAPIEGYEDIKEZDIJ='+inttostr(_negykezdij);
      ValutaParancs(_pcs);

      logirorutin(pchar('Egyedi kezdij lehetõség '+inttostr(3-_negykezdij)+' maradt'));
    end;

   // -----------------------------------------
  // Kell-e a kiadott valutát cimletezni:

  _kellCimlet := kellcimletrutin;
  if _kellCimlet=1 then kiscimletezes;

  // -------------------------------------------

  // A kedv-word meghatározása:

  if (_kezdijengedmenyTip>0) or (_voltkedvezmeny) then ArfelterWrite;

  // ---------------------------------------------------------
  // A QR kod beolvasása a NAV-os pénztárgépbe:

  QrKodLerendezes;

  // ---------------------------------------------------------------------------

  // Bekéri a NAV-os nyugta két számát - és beirja öket a VTEMP-be:

  _nyugoke := getnyugtarutin;

  // ------------------- A SZÁMLA BEIRÁSA A BLOKKFEJBE -------------------------

  logirorutin(pchar('Felirja a blokkfej és blokktétel táblákat'));

  BlokkFejIro;
  BlokktetelIro;

  KezdijRogzito;

  // Kinyomtatja a tranzakció bizonylatát:

  logirorutin(pchar('Megkezdi a blokk nyomtatását'));
  blokknyomtatas(1);

  // Ha nem konverzio figyelmezteti az ügyfelet, hogy számolja meg a pénzét !

  if not _ezKonverzio then
    begin
      logirorutin(pchar('Jelez a kijelzönek, hogy számolja meg a pénzét'));
      Figyelmeztetes;
      procendrutin;
    end;

  logirorutin(pchar('Indul a regeneráló rutin'));
  regeneralorutin(0);

  if _engedelyezo<>'' then
    begin
      logirorutin(pchar('Mivel volt engedélyezõ, ezt e-mailben jelzi'));
      MakeXML;
      XMLBemasolas;
    end;

   logirorutin(pchar('Befejezte a vásárlást procedurát'));
   logirorutin(pchar('...'));

  _mResult := 1;
  Kilep.Enabled := true;
end;

// =============================================================================
           procedure TVasarlasForm.KilepTimer(Sender: TObject);
// =============================================================================

begin
  Kilep.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
                       procedure TVasarlasForm.ArfelterWrite;
// =============================================================================

{
     Kedvezmény word:

        LOW BYTE:  1 - F1 SÁVOS NORMÁL KEDVEZMÉNY
                   2 - F1 SAJÁTHATÁSKÖRÜ KEDVEZMÉNY
                   4 - JELSZÓ NÉLKÜLI ENGEDMÉNY (10%-ON BELÜL)
                   8 - JELSZAVAS VIP KÁRTYA                JELSZAVAS
                  16 - EGYÉNI - ÉRTÉKTÁROS ENGEDMÉNY       JELSZAVAS
                  32 -        - FÕÉRTÉKTÁROSI ENGEDMÉNY    JELSZAVAS
                  64 -        - ÜGYVEZETÕI ENGEDMÉNY       JELSZAVAS
                 128 - JUTALÉKMENTES ENGEDMÉNY

        HIGH BYTE:  256 - KEZELÉSI DÍJ GOMBBAL FELEZÉSE            JELSZAVAS
                    512 - FELEZÉS AKCIÓBAN
                   1024 - KÁRTYÁS ELENGEDÉS (JELSZÓ NÉLKÜL)

                   2048 - ÜGYVEZETÕ JELSZAVAS ELENGEDÉS            JELSZAVAS
                   4096 - EGYEDILEG ADHATÓ KEZELÉSI DÍJ (MAX 3%%)

                   8192 - EGYEDI KEZDIJ NAX 3 %%
                  16384 - BÁRMILYEN ENGEDMENY
}

var _wHi: word;

begin
  _qq := 1;
  _wHi := trunc(256*_kezdijengedmenytip);
  while _qq<=_tetel do
    begin
      _aktdnem      := _wDnem[_qq];
      _aktsoreng    := _sorengedmeny[_qq];
      _aktarfolyam  := _wArfolyam[_qq];
      _aktBankjegy  := _wBankjegy[_qq];
      _origarfolyam := _wOrigarfolyam[_qq];
      _kedvarfolyam := _wKedvezmenyes[_qq];

      if (_aktsoreng=8) or (_kezdijengedmenytip>0) then
        begin
          _kedvWord  := _rateengkod+_whi;
          _pcs := 'INSERT INTO ARFOLYAMELTERITES (DATUM,PENZTAROSNEV,';
          _pcs := _pcs + 'BIZONYLATSZAM,ENGEDMENYTIPUSSZAM,VALUTANEM,';
          _pcs := _pcs + 'ARFOLYAM,BANKJEGY,UJARFOLYAM,PENZTAROSIMAX,';
          _pcs := _pcs + 'ELSZAMARFOLYAM)' + _sorveg;

          _pcs := _pcs + 'VALUES ('+chr(39)+_megnyitottnap+chr(39)+',';
          _pcs := _pcs + chr(39) + _aktpenztarosnev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
          _pcs := _pcs + inttostr(_kedvWord)+',';
          _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
          _pcs := _pcs + inttostr(_origarfolyam) + ',';
          _pcs := _pcs + inttostr(_aktbankjegy) + ',';
          _pcs := _pcs + inttostr(_aktarfolyam) + ',';
          _pcs := _pcs + inttostr(_origkezdij) + ',';
          _pcs := _pcs + inttostr(abs(_kezelesidij))+')';
          ValutaParancs(_pcs);
        end;
      inc(_qq);
    end;
    logirorutin(pchar('Adatokat bejegyzi az ARFOLYAMELTERITES táblába'));
end;


// =============================================================================
                procedure TVasarlasForm.KezdijBeepites(_kk: integer);
// =============================================================================

var _kezdij,_napkdij: integer;

begin
  _pcs := 'SELECT * FROM KEZELESIDATA';

  ValutaDbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
      _kezdij := FieldByname('AKTKEZELESIDIJ').asInteger;
      _napkdij:= FieldByNAme('NAPIKEZELESIDIJ').asInteger;
      Close;
    end;
  Valutadbase.close;

  _kezdij  := _kezdij + _kk;
  _napkdij := _napkdij + _kk;

  _pcs := 'UPDATE KEZELESIDATA SET AKTKEZELESIDIJ='+inttostr(_kezdij);
  _pcs := _pcs + ',NAPIKEZELESIDIJ='+inttostr(_napkdij);
  ValutaParancs(_pcs);
end;


// =============================================================================
           procedure TVasarlasForm.Bizregiszter(_xbiz: string);
// =============================================================================

var _bizfile: string;
    _biziro: textfile;

begin
  _bizfile := 'c:\valuta\aktbizo.txt';
  assignfile(_biziro,_bizfile);
  rewrite(_biziro);
  write(_biziro,_xbiz);
  closefile(_biziro);
end;

// =============================================================================
          procedure TVasarlasForm.FormCreate(Sender: TObject);
// =============================================================================

begin
  _width := screen.Monitors[0].width;
  _height := screen.Monitors[0].height;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Height := 768;
  Width  := 1024;
end;

// =============================================================================
                   procedure TVasarlasForm.UgyfdataVtempbol;
// =============================================================================

begin
  ValutaDbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _nevtabla   := FieldByName('NEVTABLA').asString;
      _sorszam    := FieldByNAme('SORSZAM').asInteger;
      _kulfoldi   := FieldByNAme('KULFOLDI').asInteger;
      _ugyfeltipus:= FieldByNAme('UGYFELTIPUS').asString;
      _ugyfelszam := FieldByName('UGYFELSZAM').asInteger;
      _ugyfelnev  := trim(FieldByNAme('UGYFELNEV').asstring);
      _forras     := trim(FieldByNAme('FORRAS').asString);
      _engedelyezo:= trim(FieldByName('ENGEDELYEZO').AsString);
      _secur      := FieldByNAme('SECURLEVEL').asInteger;
      Close;
    end;

  _plombaszam := _nevtabla + inttostr(_sorszam);

  _securlevel := False;
  if _secur=1 then _securlevel := True;

  _szulido   := '';
  _szulhely  := '';
  _allampolg := '';
  _anyja     := '';
  _tarthely  := '';
  _lakcim    := '';

  if (_ugyfeltipus='N') or (_ugyfeltipus='K') then
    begin
      _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
      with ValutaQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          _szulido   := ValutaQuery.fieldByName('SZULETESIIDO').asString;
          _szulhely  := trim(ValutaQuery.FieldByName('SZULETESIHELY').asString);
          _allampolg := trim(ValutaQuery.FieldByNAme('ALLAMPOLGAR').AsString);
          _tarthely  := trim(ValutaQuery.FieldByNAme('TARTOZKODASIHELY').AsString);
          _anyja     := trim(ValutaQuery.FieldByName('ANYJANEVE').asstring);
          _irszam    := trim(Valutaquery.FieldByName('IRSZAM').AsString);
          _varos     :=  trim(ValutaQuery.FieldByName('VAROS').asString);
          _utca      := trim(ValutaQuery.FieldByName('UTCA').AsString);
          _lakcim    := leftstr(_irszam+' '+_varos+' '+_utca,40);
        end;
      ValutaQuery.close;
    end;

  Valutadbase.close;
end;


// =============================================================================
                  procedure TVasarlasForm.MakeXml;
// =============================================================================

var
    _ora,_perc,_t: word;

begin
  UgyfdataVtempBol;

  _body := 'Penztar szama: ' + _homePenztarKod + _sorveg;
  _body := _body + 'Penztar neve : ' + drophung(_hptnev) + chr(13);
  _body := _body + 'Bizonylatszam: ' + _bizonylatszam + chr(13);
  _body := _body + 'Tranz.osszege: ' + inttostr(_fizetendo) + chr(13);
  _t := 1;
  while _t<= _tetel do
    begin
      _body := _body + '  '+inttostr(_t) + '. valuta: ' + forintform(_wBankjegy[_t]);
      _body := _body + ' '+_wDnem[_t] + chr(13);
      _body := _body + '  '+inttostr(_t) + '. arfoly: ' + inttostr(_warfolyam[_t])+ chr(13);
      _body := _body + '  '+inttostr(_t) + '. ertek : ' + forintform(_wErtek[_t])+' Ft' + chr(13);
      inc(_t);
    end;

  _body := _body + 'Ugyfel adatai:'+chr(13);
  _body := _body + '       - neve: ' + drophung(_ugyfelnev) + chr(13);
  _body := _body + '      - anyja: ' + drophung(_anyja) + chr(13);
  _body := _body + '   - szul.ido: ' + drophung(_szulido) + chr(13);
  _body := _body + '  - szul.hely: ' + drophung(_szulhely) + chr(13);
  _body := _body + '    - lakcime: ' + drophung(_lakcim) + chr(13);
  _body := _body + '- okmany tip.: ' + drophung(_okmanytipus) + chr(13);
  _body := _body + ' - okm. szama: ' + _azonosito + chr(13);
  _body := _body + '- allampolgar: ' + drophung(_allampolg) + chr(13);
  _body := _body + '- tart-i hely: ' + drophung(_tarthely) + chr(13);
  _body := _body + '- engedelyezo: ' + drophung(_engedelyezo) + chr(13);

  _ora := Hourof(Time);
  _perc := Minuteof(Time);

  _remoteFile := 'E' + trim(_homePenztarKod) + nulele(_ora,2)+nulele(_perc,2)+'.xml';
  _localPath := _remotefile;

  _mailstring := '<mail>' + _sorveg;
  _mailstring := _mailstring + '  <addresses>' + _sorveg;
  _mailstring := _mailstring + '    <address>' + _sorveg;
  _mailstring := _mailstring + '       fabulyazsuzsa.eec@gmail.com'+_sorveg;
  _mailstring := _mailstring + '    </address>'+_sorveg;

  if _hptn<151 then
    begin
      _mailstring := _mailstring + '    <address>' + _sorveg;
      _mailstring := _mailstring + '       kosa.zoltan.ebc@gmail.com'+_sorveg;
      _mailstring := _mailstring + '    </address>'+_sorveg;

      _mailstring := _mailstring + '    <address>' + _sorveg;
      _mailstring := _mailstring + '       nagyannamaria.ebc@gmail.com'+_sorveg;
      _mailstring := _mailstring + '    </address>'+_sorveg;

    end else
    begin
      _mailstring := _mailstring + '    <address>' + _sorveg;
      _mailstring := _mailstring + '       batori.monika.ebc@gmail.com'+_sorveg;
      _mailstring := _mailstring + '    </address>'+_sorveg;
    end;

  _mailstring := _mailstring + '  </addresses>' + _sorveg;
  _mailstring := _mailstring + '  <subject>' + _sorveg;
  _mailstring := _mailstring + '     Engedely megadasa egy tranzakciohoz'+_sorveg;
  _mailstring := _mailstring + '  </subject>'+_sorveg;
  _mailstring := _mailstring + '  <message>'+ _sorveg;
  _mailstring := _mailstring + '    ' +_body + _sorveg;
  _mailstring := _mailstring + '  </message>' + _sorveg;
  _mailstring := _mailstring + '</mail>';

  AssignFile(_pIras,'c:\valuta\'+_localPath);
  rewrite(_pIras);
  write(_piras,_mailstring);
  closefile(_piras);
end;


// ============================================================================
          procedure TVasarlasform.XMLBemasolas;
// =============================================================================

var _sendoke : integer;

begin
  if _serveraccess=1 then exit;

  _PCS := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (REMOTEDIR,REMOTEFILE,LOCALPATH)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + 'SENDMAIL' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _remotefile + chr(39) + ',';
  _pcs := _pcs + chr(39) + _localpath + chr(39) + ')';
  ValutaParancs(_pcs);

  _sendoke := copyfiletoftprutin;
  if _sendoke=1 then
    begin
      ShowMessage('AZ E-MAILEKET SIKERESEN ELKÜLDTEM');
    end else
    begin
      Showmessage('SIKERTELEN E-MAIL KÜLDÉS');
    end;
  Sysutils.DeleteFile('c:\valuta\'+_localPath);
end;


// =============================================================================
         function TVasarlasForm.DropHung(_eTXt: string): string;
// =============================================================================

var _wtxt: byte;
    _p,_kod: byte;

begin
  result := '';
  _eTxt := trim(_eTxt);
  _wtxt := length(_etxt);
  if _wTxt=0 then exit;

  _p := 1;
  while _p<=_wtxt do
    begin
      _kod := ord(_etxt[_p]);
      if _kod>122 then _kod := chchange(_kod);
      result := result + chr(_kod);
      inc(_p);
    end;
end;

// =============================================================================
              function TVasarlasform.CHChange(_inkod: byte): byte;
// =============================================================================

begin
  result := 0;
  case _inkod of
    193: result := 65;
    225: result := 97;

    201: result := 69;
    233: result := 101;

    205: result := 73;
    237: result := 105;

    211: result := 79;
    243: result := 111;

    214: result := 79;
    246: result := 111;

    213: result := 79;
    245: result := 111;

    218: result := 85;
    250: result := 117;

    219: result := 85;
    251: result := 117;

    220: result := 85;
    252: result := 117;
  end;
end;

// =============================================================================
                 procedure TVasarlasForm.Figyelmeztetes;
// =============================================================================
//
// Üzenet az árfolyamkijelzõnek: Trja ki, hogy számolja meg a pénzét !
//

begin
  Tempdbase.connected := true;
  if temptranz.InTransaction then temptranz.commit;
  Temptranz.StartTransaction;
  with TempQuery do
    begin
      Close;
      sql.clear;
      sql.add('UPDATE HARDWARE SET UJKIJELZES=1');
      ExecSql;
    end;

  TempTranz.Commit;
  Tempdbase.Close;
end;

{

Penztar szama: 134
Penztar neve : Kaposvár PLAZA
Bizonylatszam: V147123456
Tranz.osszege: 123 400 Ft
    1. valuta: 2.000 EUR
    1. arfoly: 23400 FT/100 EUR
    1. ertek : 1.345.000 Ft
    2. valuta: 1.440 USD
    2. arfoly: 20000 FT/100 USD
    2. ertek : 2.870.000 Ft
Ugyfel adatai:
       - neve: SZERDAHELYI TOBIÁS
      - anyja: DEBRECENI PIROSKA
   - szul.ido: 2017.22.33
  - szul.hely: NAGYRÉCSE
    - lakcime: Budapest, Károly krt. 333
- allampolgar: URUGUAY
- engedelyezo: KOSA ZOLTAN

}



// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================


// =============================================================================
            function TVasarlasForm.GetKezelesidij(_ss: integer): integer;
// =============================================================================

var _qq: byte;

begin
  // A pillanatnyi netto (ss) érték alapján megadja a kezelési díj értékét.
  result := 0;

  // Ha az árfolyam ezrelék 0, akkor a kezelési díj is nulla
  if _realezrelek=0 then exit;

  // Ha az árfolyam-ezrelék nagyobb mint nulla, ennyi ezrelék a kez-díj

  if (_realEzrelek>0) then
     begin
       result := Kerekito(trunc(_ss*_realEzrelek/1000));
       if result>_kezdijmax then Result := _kezdijmax;
       exit;
     end;


  // ha az arfolyamezrelék minusz 1 -> sávos kezdij lesz meghatározása:

  _qq := 1;
  while _qq<=_maxsavdb do
    begin
      result := _kdij[_qq];
      if _ss<=_tranzsav[_qq] then exit;
      inc(_qq);
    end;
  result := _kezdijmax;
end;


// =============================================================================
              procedure TVasarlasform.KisugyfelLerendezes;
// =============================================================================


begin
  IF (_sorszam=0) OR (_nevtabla='') THEN exit;

  if _serverAccess=1 then
    begin
      Showmessage('SZERVER NEM ELÉRHETÕ');
      exit;
    end;

  Remotedbase.close;
  remoteDbase.databaseName := _kisremotePath;
  RemoteDbase.connected := true;

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _fto := FieldByNAme('OSSZEG').asInteger;
      Close;
     end;
   Remotedbase.close;

   _fto := _fto + _fizetendo;

   _pcs := 'UPDATE ' + _nevtabla + ' SET OSSZEG='+inttostr(_fto);
   _pcs := _Pcs + ',LASTDATE='+chr(39)+_megnyitottnap+chr(39)+_sorveg;
   _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
   RemoteParancs(_pcs);
   logirorutin(pchar('A kisügyfél tranzakciós adatait könyveli a szerveren'));
   logirorutin(pchar('...'));

end;


// =============================================================================
              procedure TVasarlasform.RemoteLerendezes;
// =============================================================================

{
         A mostani számla NagyUgyfel-nek lett kiadva
     A szamla adatait be kell dolgozni a szerveren lévõ UGYFELyy adatbázisba

}

begin

  if _serverAccess=1 then
    begin
      Showmessage('SZERVER NEM ELÉRHETÕ');
      exit;
    end;

  Remotedbase.Close;
  Remotedbase.Databasename := _remotePath;
  Remotedbase.Connected := true;

  // Ha az ügyfél jogi-személy -> ott kell lerendezni

  if _ugyfeltipus='J' then
    begin
      RemoteJogiLerendezes;
      exit;
    end;

  // Természetes személy tranzakciójának lerendezése:

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  // Kiolvassa a távoli szerver NEVTABLA/SORSZAM sorában lévõ adatokat:

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      // személyi adatai:

      _lakcim      := trim(FieldByNAme('LAKCIM').asString);
      _lakcimcard  := trim(FieldByNAme('LAKCIMKARTYA').AsString);
      _allampolg   := trim(FieldByNAme('ALLAMPOLGAR').AsString);
      _okmanytipus := trim(FieldByNAme('OKMANYTIP').AsString);
      _azonosito   := trim(FieldByNAme('AZONOSITO').AsString);
      _tarthely    := trim(FieldByNAme('TARTOZKODASIHELY').AsString);
      _iso         := FieldByNAme('ISO').asString;
      _kozszerep   := FieldByNAme('KOZSZEREP').asInteger;
      _kulfoldi    := FieldByNAme('KULFOLDI').asInteger;

      // A göngyölitett adatai:

      _trdb        := FieldByName('TRANZAKCIODB').asInteger;
      _fto         := FieldByNAme('FORINTOSSZEG').asInteger;
      _evimax      := FieldByName('EVIMAX').asInteger;
      _lastdatum   := FieldByName('DATUM').asString;
      _hetift      := FieldByNAme('HETIOSSZ').asInteger;
      close;
    end;
  Remotedbase.close;

  // Eggyel töb tranzakciója lesz:

  inc(_trdb);

  _pluszOsszeg := _fizetendo;
  if _ezkonverzio then _pluszOsszeg := trunc(2*_pluszOsszeg);

  _fto := _fto + _pluszosszeg;

  // Ez az idei legnegyobb váltása ?

  if _evimax<_pluszOsszeg then _evimax := _pluszOsszeg;

  // Utolsó váltás óta hány naptelt el -> diff;
  _diff := Napidiff(_lastdatum,_megnyitottnap);

  // HA 7-nél több, akkor új heti gyüjtöt nyitok:

  if _diff>7 then _hetift := _pluszOsszeg
  else _hetift := _hetift + _pluszOsszeg;

  // A kiszámolt adatokkal frissitem a távoli adatbázist:

  _pcs := 'UPDATE ' + _nevtabla + ' SET TRANZAKCIODB='+inttostr(_trdb);
  _pcs := _pcs + ',FORINTOSSZEG=' + inttostr(_fto);
  _pcs := _pcs + ',EVIMAX=' + inttostr(_evimax);
  _pcs := _pcs + ',HETIOSSZ=' + inttostr(_hetift);
  _pcs := _pcs + ',DATUM=' + chr(39)+_megnyitottnap+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  Remoteparancs(_pcs);

  //  Most a bizonylatokat is frissiteni kell:

  // Meghatározza a biztábla nevét:

  _kbetu := leftstr(_nevtabla,1);
  _biztabla := _kBetu + 'BIZ';

  // Beirja a bizonylat-táblába a számla adatait:

  _pcs := 'INSERT INTO ' + _biztabla + ' (SORSZAM,LAKCIM,LAKCIMKARTYA,OKMANYTIP,';
  _pcs := _pcs + 'AZONOSITO,ALLAMPOLGAR,TARTOZKODASIHELY,KOZSZEREP,KULFOLDI,ISO,';
  _pcs := _pcs + 'BIZONYLATSZAM,FIZETENDO,DATUM)'+_SORVEG;

  _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
  _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _lakcimcard + chr(39) + ',';
  _pcs := _pcs + chr(39) + _okmanytipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _allampolg + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tarthely + chr(39) + ',';
  _pcs := _pcs + inttostr(_kozszerep) + ',';
  _pcs := _pcs + inttostr(_kulfoldi) + ',';
  _pcs := _pcs + chr(39) + _iso + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_pluszOsszeg) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ')';
  RemoteParancs(_pcs);
  logirorutin(pchar('A nagyügyfél adatait künyveli a szerveren'));
  logirorutin(pchar('...'));

end;

// =============================================================================
              procedure TVasarlasform.RemoteJogiLerendezes;
// =============================================================================

// AZ ügyfél jogi személy - a bizonylat adataival frissiti az adatbázist:

begin

  if _serverAccess=1 then
    begin
      Showmessage('SZERVER NEM ELÉRHETÕ');
      exit;
    end;

  Remotedbase.Close;
  Remotedbase.Databasename := _remotePath;
  Remotedbase.Connected := True;

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _mbdata    := trim(Fieldbyname('MBDATASORSZAM').AsString);
      _trdb      := FieldByName('TRANZAKCIODB').asInteger;
      _fto       := FieldByNAme('FORINTOSSZEG').asInteger;
      _evimax    := FieldByName('EVIMAX').asInteger;
      _lastdatum := FieldByName('DATUM').asString;
      _hetift    := FieldByNAme('HETIOSSZ').asInteger;
      close;
    end;

  _nevtabla := trim(leftstr(_mbdata,4));
  _ww       := length(_mbData);
  _mbs      := midstr(_mbdata,5,_ww-4);

  val(_mbs,_mbss,_code);
  if _code<>0 then _mbss := 0;
  if _mbss>0 then
    begin
      _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_mbss);

      with RemoteQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;

          _lakcim      := trim(FieldByNAme('LAKCIM').asString);
          _lakcimcard  := trim(FieldByNAme('LAKCIMKARTYA').AsString);
          _allampolg   := trim(FieldByNAme('ALLAMPOLGAR').AsString);
          _okmanytipus := trim(FieldByNAme('OKMANYTIP').AsString);
          _azonosito   := trim(FieldByNAme('AZONOSITO').AsString);
          _tarthely    := trim(FieldByNAme('TARTOZKODASIHELY').AsString);
          _iso         := FieldByNAme('ISO').asString;
          _kozszerep   := FieldByNAme('KOZSZEREP').asInteger;
          _kulfoldi    := FieldByNAme('KULFOLDI').asInteger;
          close;
        end;
    end;
  RemoteDbase.close;

  inc(_trDb);

  _pluszOsszeg := _fizetendo;
  if _ezKonverzio then _pluszOsszeg := _pluszOsszeg + _fizetendo;

  _fto := _fto + _pluszOsszeg;
  if _evimax<_pluszOsszeg then _evimax := _pluszOsszeg;

  _diff := Napidiff(_lastdatum,_megnyitottnap);
  if _diff>7 then _hetift := _pluszOsszeg
  else _hetift := _hetift + _pluszOsszeg;

  _pcs := 'UPDATE JOGI SET TRANZAKCIODB='+inttostr(_trdb);
  _pcs := _pcs + ',FORINTOSSZEG=' + inttostr(_fto);
  _pcs := _pcs + ',EVIMAX=' + inttostr(_evimax);
  _pcs := _pcs + ',HETIOSSZ=' + inttostr(_hetift);
  _pcs := _pcs + ',DATUM=' + chr(39)+_megnyitottnap+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  Remoteparancs(_pcs);

  _pcs := 'INSERT INTO JOGIBIZ (SORSZAM,LAKCIM,LAKCIMKARTYA,OKMANYTIP,';
  _pcs := _pcs + 'AZONOSITO,ALLAMPOLGAR,TARTOZKODASIHELY,KOZSZEREP,KULFOLDI,ISO,';
  _pcs := _pcs + 'BIZONYLATSZAM,FIZETENDO,DATUM)'+_SORVEG;

  _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
  _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _lakcimcard + chr(39) + ',';
  _pcs := _pcs + chr(39) + _okmanytipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _allampolg + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tarthely + chr(39) + ',';
  _pcs := _pcs + inttostr(_kozszerep) + ',';
  _pcs := _pcs + inttostr(_kulfoldi) + ',';
  _pcs := _pcs + chr(39) + _iso + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_pluszOsszeg) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ')';
  RemoteParancs(_pcs);
end;


// =============================================================================
            function TVasarlasform.GetNapdiff(_n1,_n2: string): extended;
// =============================================================================

var _d1,_d2: TDateTime;

begin
  _d1 := hustrtodate(_n1);
  _d2 := Hustrtodate(_n2);
  result := _d1-_d2;
end;

// =============================================================================
          procedure TVasarlasForm.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  if _tetel=0 then
    begin
      _mResult := 2;
      kilep.Enabled := true;
      exit;
    end;
  KilepniAkar;
end;

// =============================================================================
                     procedure TVasarlasForm.KilepniAkar;
// =============================================================================

begin
  with QuitSurePanel do
    begin
      Top     := 460;
      Left    := 300;
      Visible := True;
    end;
  Activecontrol := Nemlepkigomb;
end;

// =============================================================================
       function TVasarlasForm.VanilyenDnem(_adnem: string): boolean;
// =============================================================================

var _y: integer;

begin
  result := False;
  for _y:= 1 to 6 do
    begin
      if leftstr(_wDnem[_y],2)=leftstr(_aDnem,2) then
        begin
          ShowMessage('ILYEN VALUTA MÁR VAN');
          result := True;
          Break;
        end;
    end;
end;

// =============================================================================
                function TVasarlasForm.EuKontrol: boolean;
// =============================================================================

var _y: integer;
    _dnm: string;

begin
  result := False;
  for _y := 1 to 6 do
    begin
      _dnm := leftstr(_wDnem[_y],2);
      if _dnm = 'EU' then
        begin
          ShowMessage('EURO BANKJEGYET ÉS ÉRMÉT KÜLÖN BIZONYLATON KELL KIADNI');
          result := True;
          Break;
        end;
    end;
end;


// =============================================================================
           procedure TVasarlasForm.NemlepkiGombClick(Sender: TObject);
// =============================================================================

begin
  QuitSurePanel.Visible := False;
end;

// =============================================================================
           procedure TVasarlasForm.IgenKilepGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilep.Enabled := true;
end;

// =============================================================================
           procedure TVasarlasForm.NemlepkiGombEnter(Sender: TObject);
// =============================================================================

begin
  TBitbtn(Sender).Font.Style := [fsBold];
end;

// =============================================================================
            procedure TVasarlasForm.NemlepkiGombExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Style := [];
end;


// =============================================================================
           function TVasarlasForm.Napidiff(_d1,_d2: string): integer;
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
          function TVasarlasform.String2Date(_s: string): TDatetime;
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
              procedure TVasarlasForm.Alapadatbeolvasas;
// =============================================================================
//
// VTEMP-bõl beolvassa   : _konverzio
// HARDWARE-böl beolvassa: _realezrelek,_megnyitottnap,_aktPenztarosnev,_aktprosid,_host
// PENZTAR-ból beolvassa : _homepenztarkod,_hptnev
// Megállapitja _bizelokod és _ezkonverzio értékét
// ----------------------------------------------------------------------------

begin
  _ezKonverzio := False;

  _pcs := 'SELECT * FROM VTEMP';
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _konverzio := FieldByNAme('KONVERZIO').asInteger;
      Close;

      Sql.Clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;

      _realEzrelek     := FieldByNAme('REALEZRELEK').asInteger;
      _megnyitottNap   := trim(FieldByName('MEGNYITOTTNAP').AsString);
      _aktPenztarosNev := trim(FieldByName('PENZTAROSNEV').AsString);
      _aktProsId       := FieldByNAme('IDKOD').asString;
      _host            := Trim(FieldByNAme('HOST').asString);
      _serverAccess    := FieldByName('SERVERACCESS').asInteger;
      _scanType        := FieldByNAme('SCANNER').asInteger;
      Close;

      Sql.Clear;
      Sql.Add('SELECT * FROM PENZTAR');
      Open;

      _homePenztarKod  := trim(FieldByNAme('PENZTARKOD').AsString);
      _hptnev := trim(FieldByName('PENZTARNEV').AsString);
      Close;
    end;

  ValutaDbase.close;
  val(_homepenztarkod,_hptn,_code);

  _bizEloKod := inttostr(_hptn);
  while length(_bizEloKod)<3 do _bizEloKod := '0' + _bizEloKod;

  if _konverzio=1 then _ezKonverzio := True;
  _idos := Getidos;
end;


// =============================================================================
                    procedure TVasarlasForm.TombBeToltes;
// =============================================================================

begin
  _wd[1] := wd1;
  _Wn[1] := wn1;
  _wa[1] := wa1;
  _wb[1] := wb1;
  _wf[1] := wf1;

  _wd[2] := wd2;
  _Wn[2] := wn2;
  _wa[2] := wa2;
  _wb[2] := wb2;
  _wf[2] := wf2;

  _wd[3] := wd3;
  _Wn[3] := wn3;
  _wa[3] := wa3;
  _wb[3] := wb3;
  _wf[3] := wf3;

  _wd[4] := wd4;
  _Wn[4] := wn4;
  _wa[4] := wa4;
  _wb[4] := wb4;
  _wf[4] := wf4;

  _wd[5] := wd5;
  _Wn[5] := wn5;
  _wa[5] := wa5;
  _wb[5] := wb5;
  _wf[5] := wf5;

  _wd[6] := wd6;
  _Wn[6] := wn6;
  _wa[6] := wa6;
  _wb[6] := wb6;
  _wf[6] := wf6;

  _engGombok[1] := etgomb;
  _engGombok[2] := fetgomb;
  _engGombok[3] := uvgomb;
  _engGombok[4] := mentesgomb;
end;

// =============================================================================
                procedure TVasarlasForm.ValtozokNullazasa;
// =============================================================================

// forras,engedelyezo,nevtabla,aktpenuzarszam,plombaszam,trbpenztar
// kartyaszam,ugyfelnev,ugyfeltipus,lakcim stringek üritése
// sorszam,fizetendo,kezdijengedmenytip,kulfoldi,lastsor,megbizoszam,
// megbizottszam,netto,origkezdij,ratetype,tetl,ugyfelszam nullázása
// fizetoeszkoz,mresult = 1
// fixkezelesidij       = -1
// egyedikezdij,securlevel,voltshk hamisra állitása


begin
  // Változók alapra állitása:

  _forras                     := '';
  _engedelyezo                := '';
  _nevtabla                   := '';
  _aktPenztarSzam             := '';
  _plombaSzam                 := '';
  _trbPenztar                 := '';
  _kartyaszam                 := '';
  _ugyfelnev                  := '';
  _lakcim                     := '';
  _ugyfelTipus                := '';

  _sorszam                    := 0;
  _fizetendo                  := 0;
  _kezdijEngedmenyTip         := 0;
  _kulfoldi                   := 0;
  _lastSor                    := 0;
  _megbizoSzam                := 0;
  _megbizottSzam              := 0;
  _netto                      := 0;
  _origKezdij                 := 0;
  _rateType                   := 0;
  _tetel                      := 0;
  _ugyfelSzam                 := 0;
  _voltermeakcio              := 0;

  _fizetoEszkoz               := 1;
  _mresult                    := 1;

  _fixkezelesidij             := -1;

  _ezEgyediKezdij             := False;
  _securLevel                 := False;
  _voltshk                    := False;
  _voltkedvezmeny             := False;



end;

// =============================================================================
                procedure TVasarlasForm.TablaNullazas;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  while _y<=6 do
    begin
      // A 3 edit letiltása:

      _wd[_y].Enabled := False;
      _wa[_y].Enabled := False;
      _wb[_y].Enabled := False;

      // A valuta megnevezés alapra:

      _wDnem[_y] := '';
      _wDnev[_y] := '';

      // Az árfolyamok és értékek nullázása:

      _wArfolyam[_y]     := 0;
      _wBankjegy[_y]     := 0;
      _wErtek[_y]        := 0;
      _wOrigArfolyam[_y] := 0;
      _wElszamolasi[_y]  := 0;
      _sorengedmeny[_y]  := 0;

      inc(_y);
    end;
  _tetel := 0;
end;

// =============================================================================
                    procedure TVasarlasForm.KezdijTablaBeolvasas;
// =============================================================================

var _srs,_trz,_kzd: integer;

begin
  _pcs := 'SELECT * FROM TRANZDIJTABLA' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  Valutadbase.connected := true;
  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      with Valutaquery do
        begin
          _srs := FieldByName('SORSZAM').asInteger;
          _trz := FieldByName('TRANZAKCIO').asInteger;
          _kzd := FieldByName('KEZELESIDIJ').asInteger;
        end;

      if (_kzd=0) and (_srs>1) then _maxsavdb := _srs-1;

      if (_trz=0) and (_srs>1) and (_srs<24) then
        begin

          valutaquery.Next;
          continue;
        end;

      if _srs<23 then
        begin
          _tranzsav[_srs] := _trz;
          _kdij[_srs] := _kzd;
          Valutaquery.next;
        end else
        begin
          _kezdijmax := _kzd;
          break;
        end;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

// =============================================================================
           procedure TVasarlasForm.SorBeirasVTempbe(_y: byte);
// =============================================================================

begin
  _aktdnem     := _wdnem[_y];
  _aktdnev     := _wDnev[_y];
  _aktarfolyam := _wArfolyam[_y];
  _aktorigarf  := _wOrigArfolyam[_y];

  _aktelszarf  := _wElszamolasi[_y];
  _aktbankjegy := _wBankjegy[_y];
  _aktertek    := _wErtek[_y];

  // -----------------------------------

  _pcs := 'SELECT * FROM VTEMP WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);
  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
      close;
    end;

  Valutadbase.close;
  if _recno=0 then
    begin
      _pcs := 'INSERT INTO VTEMP (VALUTANEM,VALUTANEV,ARFOLYAM,ELSZAMOLASIARFOLYAM,';
      _pcs := _pcs + 'BANKJEGY,FORINTERTEK,TIPUS,SORENGEDMENY,';
      _pcs := _pcs + 'EREDETIARFOLYAM)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnev + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktarfolyam) + ',';
      _pcs := _pcs + inttostr(_aktelszarf) + ',';
      _pcs := _pcs + inttostr(_aktbankjegy) + ',';
      _pcs := _pcs + inttostr(_aktertek) + ',';
      _pcs := _pcs + chr(39) + 'V' + chr(39) + ',';
      _pcs := _pcs + '0,';
      _pcs := _pcs + inttostr(_aktOrigarf) + ')';
    end else
    begin
      _pcs := 'UPDATE VTEMP SET ARFOLYAM=' + inttostr(_aktarfolyam)+',BANKJEGY=';
      _pcs := _pcs + inttostr(_aktbankjegy)+',FORINTERTEK='+inttostr(_aktertek)+_sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);
    end;
  ValutaParancs(_pcs);
  logirorutin(pchar('Beirt egy sort a számlába:'));
  _mess :='   '+inttostr(_aktbankjegy)+' '+ _aktdnem + ' x '+inttostr(_aktarfolyam)+'='+inttostr(_aktertek)+' Ft';
  logirorutin(pchar(_mess));
end;

// =============================================================================
           function TVasarlasForm.GetDnemAdatok(_zdnem: string): byte;
// =============================================================================
//          Visszaadja a kért valuta pillanatnyi készletét és adatait

begin
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+_ZdNEM+chr(39);

  ValutaDbase.connected := true;
  with Valutaquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := recno;
    end;

  if result>0 then
    begin
      with ValutaQuery do
        begin
          _aktdnev    := trim(FieldbyNAme('VALUTANEV').asString);
          _aktvarf    := FieldByNAme('VETELIARFOLYAM').asInteger;
          _aktelszarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
          _aktshk     := FieldByName('SHKVETARFOLYAM').asInteger;
          _aktZaro    := FieldByNAme('ZARO').asInteger;
        end;
    end;
  Valutaquery.close;
  Valutadbase.close;
end;



// =============================================================================
              procedure TVasarlasForm.WD1Enter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
                procedure TVasarlasForm.WD1Exit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWhite;
end;


// =============================================================================
           function TVasarlasForm.GetTetelsor(_dn: string): byte;
// =============================================================================

var _q: byte;

begin
  result := 0;
  _q := 1;
  while _q<=_tetel do
    begin
      if _wdnem[_q]=_dn then
        begin
          result := _q;
          exit;
        end;
      inc(_q);
    end;
end;

// =============================================================================
             function TVasarlasForm.GetsajathatasKoru: byte;
// =============================================================================

begin
  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      result := FieldByName('SAJATHATASKORU').asInteger;
      _negykezdij := FieldByNAme('NAPIEGYEDIKEZDIJ').asInteger;
      Close;
    end;
  Valutadbase.close;
end;

// =============================================================================
            procedure TVasarlasForm.ETGOMBMouseMove(Sender: TObject;
                                             Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  EngGombClear;
  Tpanel(sender).Color := clYellow;
  TPanel(sender).Font.Style := [fsBold,fsItalic];
end;

// =============================================================================
                procedure TVasarlasForm.EnggombClear;
// =============================================================================

var _k: byte;

begin
  _K := 1;
  while _k<=4 do
    begin
      _engGombok[_k].Color := clBtnFace;
      _engGombok[_k].Font.Style := [fsItalic];
      inc(_k);
    end;
end;

// =============================================================================
         procedure TVasarlasForm.ENGSHAPEMouseMove(Sender: TObject;
                                             Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  engGombClear;
end;

// =============================================================================
                 procedure TVasarlasform.QRkodLerendezes;
// =============================================================================

var _zz: byte;

begin
  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _zz := 1;
  while _zz<=_tetel do
    begin
      _aktdnem     := _wDnem[_zz];
      _aktArfolyam := _wArfolyam[_zz];
      _aktbankjegy := _wBankjegy[_zz];

      _pcs := 'INSERT INTO QRPARAMS (VALUTANEM,ARFOLYAM,BANKJEGY)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39)+_aktdnem+chr(39)+',';
      _pcs := _pcs + intTostr(_aktarfolyam)+',';
      _pcs := _pcs + inttostr(_aktbankjegy)+')';
      ValutaParancs(_pcs);
      inc(_zz);
    end;

  _okmanyTipus := leftstr(_okmanyTipus,10);
  if _kulfoldi=1 then
    begin
      _okmanytipus := 'NN';
      _azonosito := '0000';
    end;

  _pcs := 'UPDATE QRPARAMS SET BIZONYLATSZAM=' + chr(39)+_bizonylatSzam+chr(39)+',';
  _pcs := _pcs + 'KEZELESIDIJ=' + intToStr(_kezelesidij);

  IF _okmanytipus<>'' then _pcs := _pcs + ',OKMANYTIPUS='+chr(39)+_okmanyTipus+chr(39);
  if _azonosito<>'' then _pcs := _pcs + ',AZONOSITO='+CHR(39)+_azonosito+chr(39);

  _pcs := _pcs + ',KULFOLDI=' + inttostr(_kulfoldi);
  _pcs := _pcs + ',FIZETENDO=' + inttostr(_fizetendo);
  _pcs := _pcs + ',NUMBER=7';
  ValutaParancs(_pcs);
  logirorutin(pchar('Elinditja a QR-kód kijelzõ rutint'));
  qrdisplayrutin;
end;

// =============================================================================
                procedure TVasarlasform.EurErmeKonvertalas;
// =============================================================================

begin
  // Az esetleges EURÓ érmék konvertálása:

  _pcs := 'UPDATE VTEMP SET COIN=1,VALUTANEM=' +chr(39) + 'EUR' + chr(39);
  _pcs := _pcs + ',VALUTANEV=' + chr(39) + 'EURÓ' + chr(39) + _SORVEG;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + 'EUA' + CHR(39);
  ValutaParancs(_pcs);

  _Z := 1;
  while _z<=_tetel do
    begin
      if _wDnem[_z]='EUA' then
        begin
          _wDnem[_z] := 'EUR';
          _wDnev[_z] := 'EURÕ';
        end;
      inc(_z);
    end;
end;

// =============================================================================
                  procedure TVasarlasForm.KezdijRogzito;
// =============================================================================

var _kezdij,_napkdij: integer;

begin
  if _KezdijEngedmenyTip>0 then
     begin
       _pcs := 'INSERT INTO EGYENIKEZDIJ (DATUM,BIZONYLAT,BIZONYLATFORINT,TIPUS,EGYEDIKEZDIJ)'+_sorveg;
       _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
       _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
       _pcs := _pcs + inttostr(_netto) + ',';
       _pcs := _pcs + chr(39) + chr(64+_kezdijengedmenytip) + chr(39) + ',';
       _pcs := _pcs + inttostr(_kezelesidij) + ')';
       ValutaParancs(_pcs);
     end;

  ValutaDbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add('SELECT * FROM KEZELESIDATA');
      Open;
      _kezdij := FieldByname('AKTKEZELESIDIJ').asInteger;
      _napkdij:= FieldByNAme('NAPIKEZELESIDIJ').asInteger;
      Close;
    end;
  Valutadbase.close;

  _kezdij  := _kezdij + _kezelesidij;
  _napkdij := _napkdij+ _kezelesidij;

  _pcs := 'UPDATE KEZELESIDATA SET AKTKEZELESIDIJ='+inttostr(_kezdij);
  _pcs := _pcs + ',NAPIKEZELESIDIJ='+inttostr(_napkdij);
  ValutaParancs(_pcs);

end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
///////////////////   SEGÉDPROGRAMOK ÉS FUNKCIÓK      //////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                           function TVasarlasForm.Getidos:string;
// =============================================================================

begin
  Result := TimeTostr(Now);
  if midstr(Result,2,1) = ':' then Result := '0' + Result;
  Result := leftstr(result,5);
end;

// =============================================================================
         function TVasarlasForm.GetBizonylatszam(_write: boolean): string;
// =============================================================================

begin
  _pcs := 'SELECT * FROM UTOLSOBLOKKOK' + _sorveg;

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _lastBuyBlokknum := FieldByName('UTOLSOVETELBLOKK').asInteger;
      Close;
    end;
  ValutaDbase.close;

  // ---------------------------------------------------------------------------

  inc(_lastBuyBlokknum);
  if _lastBuyBlokknum>=999990 then _lastBuyBlokknum := 100000;

  // ---------------------------------------------------------------------------

  Result  := 'V' + _bizelokod + Nulele(_lastbuyBlokknum,6);

  if _write then
    begin
      _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOVETELBLOKK='+inttostr(_lastBuyBlokknum);
      ValutaParancs(_pcs);

      _pcs := 'UPDATE VTEMP SET BIZONYLATSZAM='+chr(39)+ Result + chr(39);
      ValutaParancs(_pcs);
    end;
end;

// =============================================================================
               function TVasarlasForm.Nulele(_b: integer;_hh: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<_hh do result := '0' + result;
end;

// =============================================================================
           function TVasarlasForm.kerekito(_int: integer): integer;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _int;
  _nums := inttostr(_int);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;
  if (_utdig<>0) and (_utdig<>5) then
    begin
      if (_utdig=1) or (_utdig=2) then result := _int-_utdig;
      if (_utdig=6) or (_utdig=7) then result := _int-(_utdig-5);
      if (_utdig=3) or (_utdig=4) then result := _int+(5-_utdig);
      if (_utdig=8) or (_utdig=9) then result := _int+10-_utdig;
    end;
end;

// =============================================================================
           function TvASARLASForm.Elokieg(_szo: string;_hh: integer):string;
// =============================================================================

begin
  if length(_szo)>=_hh then
    begin
      Result := leftStr(_szo,_hh);
      exit;
    end;

  while length(_szo)<_hh do _szo := ' '+_szo;

  Result := _szo;
end;

// =============================================================================
             function TVasarlasForm.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);
end;

// =============================================================================
        function TVasarlasForm.GetkedvArf(_adnem: string): integer;
// =============================================================================

begin
  _pcs := 'SELECT * FROM VTEMP WHERE VALUTANEM=' + chr(39)+_adnem + chr(39);
  Tempdbase.connected := true;
  with Tempquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := FieldByName('KEDVEZMENYESARFOLYAM').asinteger;
      Close;
    end;
  Tempdbase.close;
end;

// =============================================================================
         function TVasarlasform.Hustrtodate(_ds: string): TDateTime;
// =============================================================================

var _xevs,_xhos,_xnaps: string;
    _xev,_xho,_xnap: word;

begin
  _xevs := leftstr(_ds,4);
  _xhos := midstr(_ds,6,2);
  _xnaps:= midstr(_ds,9,2);

  val(_xevs,_xev,_code);
  val(_xhos,_xho,_code);
  val(_xnaps,_xnap,_code);
  result := encodeDate(_xev,_xho,_xnap);
end;

// =============================================================================
               procedure TVasarlasform.RemoteParancs(_ukaz: string);
// =============================================================================

begin
  if _serverAccess=1 then exit;

  remoteDbase.connected := true;
  if remotetranz.InTransaction then remoteTranz.commit;
  remotetranz.StartTransaction;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  RemoteTranz.commit;
  remotedbase.close;
end;

// =============================================================================
                 procedure TVasarlasform.Blokkfejiro;
// =============================================================================

var _xBizo,_xtip,_xdatum,_xido,_xugyftip,_xProsnev,_xIdkod,_xPlombaszam: string;
  _xUgyfnev,_xUgyfcim,_xAdoszam,_xZcounts,_xRecnums,_xforras,_xengedelyezo: string;
  _xOsszft,_xUgyfszam,_xtetel,_xstorno,_xmegbizott,_xmegbizoszam: integer;
  _xNetto,_xKezdij,_xFizetendo,_xKonverzio,_xkerekites: integer;

begin
  tempdbase.connected := True;
  with TempQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;
      First;

      _xBizo        := trim(FieldByNAme('BIZONYLATSZAM').asString);
      _xTip         := FieldByName('TIPUS').asString;
      _xDatum       := trim(FieldByName('DATUM').asString);
      _xIdo         := trim(FieldByNAme('IDO').asString);
      _xosszft      := FieldByNAme('OSSZESFORINTERTEK').asInteger;
      _xUgyftip     := FieldByNAme('UGYFELTIPUS').asString;
      _xUgyfszam    := FieldByName('UGYFELSZAM').asInteger;
      _xTetel       := FieldByName('TETEL').asInteger;
      _xprosnev     := trim(FieldByName('PENZTAROSNEV').asString);
      _xIdkod       := FieldByName('IDKOD').asString;
      _xStorno      := FieldByName('STORNO').asInteger;
      _xMegbizott   := FieldByNAme('MEGBIZOTT').asInteger;
      _xMegbizoszam := FieldByNAme('MEGBIZOSZAM').asInteger;
      _xplombaszam  := trim(FieldByNAme('PLOMBASZAM').asString);
      _xNetto       := FieldByNAme('NETTO').asInteger;
      _xKezdij      := FieldByNAme('KEZELESIDIJ').asInteger;
      _xFizetendo   := FieldByNAme('FIZETENDO').asInteger;
      _xKonverzio   := FieldByNAme('KONVERZIO').asInteger;
      _xUgyfnev     := trim(FieldByNAme('UGYFELNEV').asString);
      _xUgyfcim     := trim(FieldByNAme('UGYFELCIM').asString);
      _xAdoszam     := trim(FieldByNAme('ADOSZAM').asString);
      _xKerekites   := FieldByNAme('KEREKITES').asInteger;
      _xZcountS     := trim(Fieldbyname('ZCOUNTS').asString);
      _xRecnums     := trim(FieldByName('RECNUMS').asString);
      _xForras      := trim(FieldByName('FORRAS').asString);
      _xEngedelyezo := trim(FieldByNAme('ENGEDELYEZO').asString);
      Close;
    end;
   Tempdbase.close;

   _pcs := 'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,OSSZESFORINTERTEK,';
   _pcs := _pcs + 'UGYFELTIPUS,UGYFELSZAM,TETEL,PENZTAROSNEV,IDKOD,STORNO,MEGBIZOTT,';
   _pcs := _pcs + 'MEGBIZOSZAM,PLOMBASZAM,NETTO,KEZELESIDIJ,FIZETENDO,FIZETOESZKOZ,';
   _pcs := _pcs + 'KONVERZIO,UGYFELNEV,UGYFELCIM,ADOSZAM,KEREKITES,ZCOUNTS,';
   _pcs := _pcs + 'RECNUMS,FORRAS,ENGEDELYEZO)' + _sorveg;
   _pcs := _pcs + 'VALUES (' + chr(39) + _xbizo + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xTip + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xDatum + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xIdo + chr(39) + ',';
   _pcs := _pcs + inttostr(_xOsszFt) + ',';
   _pcs := _pcs + chr(39) + _xUgyfTip + chr(39) + ',';
   _pcs := _pcs + inttostr(_xUgyfszam) + ',';
   _pcs := _pcs + inttostr(_xtetel) + ',';
   _pcs := _pcs + chr(39) + _xProsnev + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xIdkod + chr(39) + ',';
   _pcs := _pcs + inttostr(_xStorno) + ',';
   _pcs := _pcs + inttostr(_xMegbizott) + ',';
   _pcs := _pcs + inttostr(_xMegbizoszam) + ',';
   _pcs := _pcs + chr(39) + _xPlombaszam + chr(39) + ',';
   _pcs := _pcs + inttostr(_xNetto) + ',';
   _pcs := _pcs + inttostr(_xKezdij) + ',';
   _pcs := _pcs + inttostr(_xFizetendo) + ',';
   _pcs := _pcs + '1,';
   _pcs := _pcs + inttostr(_xKonverzio) + ',';
   _pcs := _pcs + chr(39) + _xUgyfnev + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xUgyfCim + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xAdoszam + chr(39) + ',';
   _pcs := _pcs + inttostr(_xKerekites) + ',';
   _pcs := _pcs + chr(39) + _xZcounts + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xRecnums + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xForras + chr(39) + ',';
   _pcs := _pcs + chr(39) + _xEngedelyezo + chr(39) + ')';
   ValutaParancs(_pcs);
end;

// =============================================================================
                   procedure TVasarlasform.Blokkteteliro;
// =============================================================================

var _xBiz,_xDatum,_xValnem,_xElojel: string;
    _xArfolyam,_xElszarf,_xBankjegy,_xFtErtek,_xCoin,_xStorno: integer;

begin
  tempdbase.connected := true;
  with TempQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;
      First;
    end;

  while not tempquery.eof do
    begin
      with Tempquery do
        begin
          _xbiz      := trim(FieldByNAme('BIZONYLATSZAM').asString);
          _xDatum    := trim(FieldByNAme('DATUM').asString);
          _xValnem   := FieldByNAme('VALUTANEM').asString;
          _xarfolyam := FieldByNAme('ARFOLYAM').asInteger;
          _xElszarf  := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
          _xbankjegy := FieldByNAme('BANKJEGY').asInteger;
          _xFtertek  := FieldByNAme('FORINTERTEK').asInteger;
          _xelojel   := FieldByNAme('ELOJEL').asString;
          _xCoin     := FieldByNAme('COIN').asInteger;
          _xStorno   := FieldByNAme('STORNO').asInteger;
        end;
      _pcs := 'INSERT INTO BLOKKTETEL (BIZONYLATSZAM,DATUM,VALUTANEM,ARFOLYAM,';
      _pcs := _pcs + 'ELSZAMOLASIARFOLYAM,BANKJEGY,FORINTERTEK,ELOJEL,COIN,';
      _pcs := _pcs + 'STORNO)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39) + _xbiz + chr(39) + ',';
      _pcs := _pcs + chr(39) + _xDatum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _xValnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_xArfolyam) + ',';
      _pcs := _pcs + inttostr(_xElszarf) + ',';
      _pcs := _pcs + inttostr(_xBankjegy) + ',';
      _pcs := _pcs + inttostr(_xFtErtek) + ',';
      _pcs := _pcs + chr(39) + _xElojel + chr(39) + ',';
      _pcs := _pcs + inttostr(_xCoin) + ',';
      _pcs := _pcs + inttostr(_xStorno) + ')';
      ValutaParancs(_pcs);

      Tempquery.next;
    end;
  tempQuery.close;
  Tempdbase.close;
end;

// =============================================================================
             procedure TVasarlasForm.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;

// =============================================================================
               procedure TVasarlasForm.VtempDataPotlas;
// =============================================================================
// Beolvassa: ügyfél tipusát, számát és mbszámát VTEMP-böl
// Az UGYFEL-böl beolvassa: okmanytipus, azonosito, külföldi
// HARDWARE-böl beolvassa a pénztáros nevét és id-kódját
// A VTEMP-be beirja: penztáros nevét és idkódját.
//

begin
  _pcs := 'UPDATE VTEMP SET DATUM=' + chr(39) + _megnyitottnap + chr(39);
  _pcs := _pcs + ',IDO=' + chr(39) + _idos + chr(39);
  _pcs := _pcs + ',PENZTAROSNEV=' + chr(39) + _aktpenztarosnev + chr(39);
  _pcs := _pcs + ',IDKOD=' + chr(39) + _aktprosid + chr(39);
  _pcs := _pcs + ',STORNO=1';
  ValutaParancs(_pcs);
end;


end.


