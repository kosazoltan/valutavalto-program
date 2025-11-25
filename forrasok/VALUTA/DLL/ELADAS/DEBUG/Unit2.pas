
unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, ExtCtrls, DB, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, dateUtils,
  wininet;

type
  TEladasForm = class(TForm)
  EndGomb             : TBitBtn;
  EscapeGomb          : TBitBtn;
  IgenKilepGomb       : TBitBtn;
  KezdijEngedmenyGomb : TBitBtn;
  LimitMegsemGomb     : TBitBtn;
  LimitOkeGomb        : TBitBtn;
  NemLepKiGomb        : TBitBtn;
  SetLimitGomb        : TBitBtn;
  Limitedit           : Tedit;
  Wa1                 : tedit;
  WA2                 : TEdit;
  WA3                 : TEdit;
  WA4                 : TEdit;
  WA5                 : TEdit;
  WA6                 : TEdit;
  WB1                 : TEdit;
  WB2                 : TEdit;
  WB3                 : TEdit;
  WB4                 : TEdit;
  WB5                 : TEdit;
  WB6                 : TEdit;
  WD1                 : TEdit;
  WD2                 : TEdit;
  WD3                 : TEdit;
  WD4                 : TEdit;
  WD5                 : TEdit;
  WD6                 : TEdit;

  RemoteQuery         : TIBQuery;
  RemoteDbase         : TIBDatabase;
  RemoteTranz         : TIBTransaction;

  TetQuery            : TIBQuery;
  TetDbase            : TIBDatabase;
  TetTranz            : TIBTransaction;

  TempQuery           : TIBQuery;
  TempDbase           : TIBDatabase;
  TempTranz           : TIBTransaction;

  ValutaTabla         : TIBTable;
  ValutaQuery         : TiBQuery;
  ValutaDbase         : TiBDatabase;
  ValutaTranz         : TiBTransaction;

    BizonylatLabel    : TLabel;
    BKInfoPanel       : TPanel;
    Label1            : TLabel;
    Label2            : TLabel;
    Label3            : TLabel;
    Label4            : TLabel;
    Label5            : TLabel;
    Label6            : TLabel;
    Label8            : TLabel;
    Label9            : TLabel;
    Label10           : TLabel;
    Label11           : TLabel;
    Label14           : TLabel;
    Label16           : TLabel;
    Label17           : TLabel;
    Label19           : TLabel;
    Label25           : TLabel;
    SumOsszegLabel    : TLabel;

    ArfolyamGomb      : TPanel;
    EzrelekPanel      : TPanel;
    KdPanel           : TPanel;
    KerekitesPanel    : TPanel;
    KonvCimPanel      : TPanel;
    KonvHibaPanel     : TPanel;
    KonvSumPanel      : TPanel;
    LimitBekeroPanel  : TPanel;
    LimitForint       : TPanel;
    LimitTakaro       : TPanel;
    MaradtForint      : TPanel;
    MinDiffPanel      : TPanel;
    NettoPanel        : TPanel;
    NoInternetPanel   : TPanel;
    SZAMLAALAPLAP: TPanel;
    Panel2            : TPanel;
    Panel3            : TPanel;
    Panel4            : TPanel;
    Panel5            : TPanel;
    Panel6            : TPanel;
    Panel7            : TPanel;
    Panel8            : TPanel;
    Panel10           : TPanel;
    Panel11           : TPanel;
    Panel14           : TPanel;
    Panel15           : TPanel;
    Panel17           : TPanel;
    Panel18           : TPanel;
    QuitSurePanel     : TPanel;
    Takaro            : TPanel;
    TooBigPanel       : TPanel;
    TranzdijPanel     : TPanel;
    WF1               : TPanel;
    WF2               : TPanel;
    WF3               : TPanel;
    WF4               : TPanel;
    WF5               : TPanel;
    WF6               : TPanel;
    WN1               : TPanel;
    WN2               : TPanel;
    WN3               : TPanel;
    WN4               : TPanel;
    WN5               : TPanel;
    WN6               : TPanel;


    Shape1            : TShape;
    Shape2            : TShape;
    Shape3            : TShape;
    Shape4            : TShape;
    Shape5            : TShape;
    Shape6            : TShape;
    Shape7            : TShape;
    Shape8            : TShape;
    Shape9            : TShape;
    Shape10           : TShape;
    Shape11           : TShape;
    Shape12           : TShape;
    Shape13           : TShape;
    Shape14           : TShape;
    Shape15           : TShape;
    Shape16           : TShape;
    Shape17           : TShape;
    Shape18           : TShape;
    Shape19           : TShape;
    Shape20           : TShape;
    Shape21           : TShape;
    Shape22           : TShape;
    Shape23           : TShape;
    Shape24           : TShape;
    Shape25           : TShape;
    Shape32           : TShape;

    VegeTimer         : TTimer;
    ENGEDELYADOPANEL: TPanel;
    Label7: TLabel;
    ETGOMB: TPanel;
    FETGOMB: TPanel;
    UVGOMB: TPanel;
    MENTESGOMB: TPanel;
    Shape26: TShape;
    KILEP: TTimer;

    procedure AdatbevitelKesz(sender:TObject);
    procedure AktualNullazo;
    procedure AlapadatBeolvasas;
    procedure ArfelterWrite;
    procedure ArfolyamGombClick(Sender: TObject);
    procedure ArfolyamKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ArfolyamotModosit;
    procedure ArfvaltParaWrite(_adnem: string);
    procedure BankjegyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BankKartyaRendezes;
    procedure BankkartyaKonyveles;
    procedure Bizregiszter(_xbiz: string);
    procedure BlokkFejIro;
    procedure Blokkteteliro;
    procedure DnemKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Dnem2VTemp;
    procedure EditTombTolto;
    procedure EngedelyezoKijeloles;
    procedure EscapeGombClick(Sender: TObject);
    procedure ETGOMBClick(Sender: TObject);
    procedure Figyelmeztetes;
    procedure FizetendoDisplay;
    procedure Folytatas;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GetKonvertAdatok;
    procedure GetLimitOsszeg;
    procedure IgenKilepGombClick(Sender: TObject);
    procedure KedvezmenyAnalizis;
    procedure KezdijBeepites(_kk: integer);
    procedure KezdijEngedmenyGombClick(Sender: TObject);
    procedure KezdijRogzito;
    procedure KezdijTablaBeolvasas;
    procedure KilepniAkar;
    procedure KilepTimer(Sender: TObject);
    procedure KisugyfelLerendezes;
    procedure KonvDataVtempbe;
    procedure KonvertHiba;
    procedure LimitDisplay;
    procedure LimitEditEnter(Sender: TObject);
    procedure LimitEditExit(Sender: TObject);
    procedure LimitEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure LimitMegsemGombClick(Sender: TObject);
    procedure LimitOkeGombClick(Sender: TObject);
    procedure MakeXml;
    procedure MaradtBeolvaso;
    procedure MaradtLepteto(_mit: byte);
    procedure NemlepkiGombClick(Sender: TObject);
    procedure NemlepkiGombEnter(Sender: TObject);
    procedure NemlepkiGombExit(Sender: TObject);
    procedure NyugtaszamBeiras;
    procedure QRkodLerendezes;
    procedure RemoteLerendezes;
    procedure RemoteJogiLerendezes;
    procedure RemoteParancs(_ukaz: string);
    procedure SetLimitGombClick(Sender: TObject);
    procedure SetupAlapra;
    procedure SorBeirasVTempbe(_y: byte);
    procedure Sorletilt(_dsor: integer);
    procedure SorNullazas(_tsor: integer);
    procedure SorRelease(_dsor: integer);
    procedure TablaUrito;
    procedure TablaNullazas;
    procedure TombBetoltes;
    procedure UgyfelAdatBeolvasas;
    procedure UgyfdataVtempbol;
    procedure UjadatlapIro;
    procedure Ujraszamolas;
    procedure ValtozokNullazasa;
    procedure ValutaParancs(_ukaz: string);
    procedure VegeTimerTimer(Sender: TObject);
    procedure VTempbeir;
    procedure VtempDataPotlas;
    procedure VtempKitoltes;
    procedure Wa1DblClick(Sender: TObject);
    procedure WD1Enter(Sender: TObject);
    procedure WD1Exit(Sender: TObject);
    procedure XMLBemasolas;

    function Adatolvasas(_adnem: string): integer;
    function CHChange(_inkod: byte): byte;
    function DropHung(_eTXt: string): string;
    function Elokieg(_szo: string;_hh: integer):string;
    function ForintForm(_osszeg:integer):string;
    function GetBizonylatszam(_write: boolean): string;
    function GetDnemAdatok(_zdnem: string): byte;
    function Getfizetoeszkoz: integer;
    function GetFtString(_ft: real): string;
    function GetIdos: string;
    function GetKedvArf(_adnem: string): integer;
    function GetKezelesidij(_ss: integer): integer;
    function GetPtParams: string;
    function GetsajathatasKoru: byte;
    function GetTetelsor(_dn: string): byte;
    function GetTranzdij(_ss: integer): integer;
    function Kerekito(_int: integer): integer;
    function KeszletKontrol(_dn: string): integer;
    function Napidiff(_d1,_d2: string): integer;
    function Nulele(_b: integer;_hh: byte): string;
    function String2Date(_s: string): TDatetime;
    function VanilyenDnem(_adnem: string): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EladasForm: TeladasForm;

  _iras: Textfile;

  _remotepath   : string;
  _kisremotepath: string;

  _wd,_wa,_wb       : array[1..6] of TEdit;
  _wn,_wf           : array[1..6] of TPanel;
  _wbankjegy,_wertek: array[1..6] of Integer;
  _wdnem,_wdnev     : array[1..6] of string;
  _engGombok        : array[1..4] of TPanel;

  _sorengedmeny,_warfolyam,_worigarfolyam: array[1..6] of integer;
  _wkedvezmenyes,_welszamolasi           : array[1..6] of integer;
  _tranzsav,_kdij                        : array[1..23] of integer;

  _pacs   : pchar;
  _rounder: real = 0.001;

  _host : string;
  _adoszam,_aktdatum,_aktdnem,_aktdnev,_aktidos,_aktnums,_ptParams,_pcs: string;
  _aktpenztarosnev,_aktprosid,_aktugyfelnev,_azonosito,_vetbiz,_vetdnem: string;
  _bizelokod,_bizonylatszam,_cardnums,_elojel,_engedelyezo,_ftstring   : string;
  _felezotipus,_forras,_lakcim,_lastfejbiz,_limitString,_hpts,_vannincs: string;
  _homePenztarSzam,_irszam,_keres,_megbizonev,_megbizocim,_mailstring  : string;
  _megbizottnev,_megbizottcim,_megnyitottnap,_okmanytipus,_hptnev,_van : string;
  _recnums,_telephely,_tranzstring,_trbpenztar,_plombaszam,_kbetu      : string;
  _ugyfelnev,_ugyfeltipus,_utca,_varos,_zcounts,_xKezdTip,_nevtabla    : string;
  _szulhely,_szulido,_allampolg,_body,_anyja,_remotefile,_localpath    : string;
  _eladdnem,_tarthely,_prosnev,_ktips,_mess,_ugyfelcim,_lastdatum,_idos: string;
  _biztabla,_lakcimcard,_iso,_mbdata,_mbs,_kartyaszam,_homepenztarkod  : string;
  _aktPenztarszam,_aktbs: string;

  _ptPath: string = 'c:\valuta\ptpara.txt';
  _sorveg: string = chr(13)+chr(10);

  _activesor,_aktratetype,_bill,_coin,_konverzio,_kozszereplo,_bk,_hptn: byte;
  _kulfoldi,_lastsor,_maistornodarab,_mekd,_mshk,_oszlop,_otp,_otpoke  : byte;
  _rateType,_saveactivesor,_secur,_storno,_spk,_tag,_tetel,_tulajdarab : byte;
  _cardtip,_kozszerep,_ww,_aktdek,_shk,_aktsor,_found,_aktsoreng       : byte;
  _negykezdij,_rateEngKod,_serverAccess,_scanType: byte;

  _height,_left,_top,_width,_kedvWord,_k,_a,_trdb,_dekad: word;

  _aktadatlapszam,_aktArfolyam,_aktBankjegy,_aktElszarf,_aktErtek     : integer;
  _aktSorkedv,_aktTenyArfolyam,_aktUgyfelszam,_aktZaro,_bignum,_brutto: integer;
  _cc,_code,_egyenleg,_fizetendo,_fizetoeszkoz,_forroke,_kedvarfolyam : integer;
  _kellcimlet,_kerekites,_kerekitendo,_kertTranzdij,_kezdij,_kezdijmax: integer;
  _kezdijengedmenytip,_konvertin,_konvertout,_lastSellblokknum,_limit : integer;
  _maradt,_maxsavdb,_megbizo,_megbizoszam,_megbizottszam,_minkezdij   : integer;
  _modoke,_netto,_nyugoke,_origkezdij,_qq,_realezrelek,_recno,_scanoke: integer;
  _selloke,_sumertek,_ugyfelszam,_uOke,_ujarfolyam,_z,_wft,_FX,_diff  : integer;
  _vetarf,_vetbjegy,_eladarf,_eladbjegy,_konvsec,_konvkulf,_hetift    : integer;
  _kdIndex,_fixkezelesidij,_kezelesidij,_AKTSHK,_aktearf,_gOke,_mbss  : integer;
  _ptoke,_fto,_termOke,_sorszam,_mResult,_evimax,_kdiff,_arfback      : integer;
  _aktkedvarf,_aktorigarf,_bankjegy,_origarfolyam: integer;

  _ezegyedikezdij,_ezkonverzio,_savos,_securlevel,_voltkedvezmeny     : boolean;
  _toomany,_vanKezdijEngedmeny,_volt8,_voltRateMode,_voltshk,_ezshk   : boolean;
  _voltgongyoles: boolean;

function arfolyamkijelzes(_para:string): integer;stdcall; external 'c:\valuta\bin\Arfdisp.dll' name 'arfolyamkijelzes';
function arfvaltrutin: integer; stdcall; external 'c:\valuta\bin\arfvalt.dll' name 'arfvaltrutin';
function bescannelorutin: integer; stdcall; external 'c:\valuta\bin\scanning.dll' name 'bescannelorutin';
function bigarfolyamkedvezmeny: integer; stdcall; external 'c:\valuta\bin\bigarfvalt.dll';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\valuta\bin\bloknyom.dll' name 'blokknyomtatas';
function confirmrutin: integer; stdcall; external 'c:\valuta\bin\confirm.dll' name 'confirmrutin';
function copyfiletoftprutin: integer; stdcall; external 'c:\valuta\bin\copy2ftp.dll' name 'copyfiletoftprutin';
function fizetoeszkozrutin: integer; stdcall; external 'c:\valuta\bin\getfize.dll' name 'fizetoeszkozrutin';
function getnyugtarutin: integer; stdcall; external 'c:\valuta\bin\getnyug.dll' name 'getnyugtarutin';
function gongyvisszavonas: integer; stdcall; external 'c:\valuta\bin\gongback.dll' name 'gongyvisszavonas';
function kezdijkedvezmeny: integer; stdcall; external 'c:\valuta\bin\kezdkedv.dll';
function kellcimletrutin: integer; stdcall; external 'c:\valuta\bin\kellcim.dll' name 'kellcimletrutin';
function kisarfolyamkedvezmeny: integer; stdcall; external 'c:\valuta\bin\kisarfvalt.dll';
function kiscimletezes: integer; stdcall; external 'c:\valuta\bin\kiscim.dll' name 'kiscimletezes';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function procendrutin: integer; stdcall; external 'c:\valuta\bin\procend.dll' name 'procendrutin';
function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\QRGENER.dll' name 'qrdisplayrutin';
function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll' name 'regeneralorutin';
function setraterutin: integer; stdcall; external 'c:\valuta\bin\setrate.dll' name 'setraterutin';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function ugyfelrutin: integer; stdcall; external 'c:\valuta\bin\ugyfel.dll' name 'ugyfelrutin';
function otpterminal: integer; stdcall; external 'c:\valuta\bin\otp.dll' name 'otpterminal';
function ujokmanyszkennelo: integer; stdcall; external 'c:\valuta\bin\scanner.dll';

function eladasrutin: integer; stdcall;

implementation

{$R *.dfm}

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
                  function eladasrutin: integer; stdcall;
// =============================================================================

begin
  eladasForm := TeladasForm.Create(Nil);
  result := EladasForm.showModal;
  EladasForm.Free;
end;

// =============================================================================
            procedure TEladasForm.FormActivate(Sender: TObject);
// =============================================================================

begin
  width      := 1015;
  height     := 761;

  logirorutin(pchar('...'));

  logirorutin(pchar('---------------------------------'));
  logirorutin(pchar('     Valuta eladásába kezd'));
  logirorutin(pchar('---------------------------------'));
  logirorutin(pchar('...'));

// ----------------------------------------------------------------------------
// VTEMP-bõl beolvassa   : _konverzio
// HARDWARE-böl beolvassa: _realezrelek,_megnyitottnap,_aktPenztarosnev,_aktprosid,_host
// PENZTAR-ból beolvassa : _homepenztarkod,_hptnev
// Megállapitja _bizelokod és _ezkonverzio értékét

  AlapadatBeolvasas;

  //Az aktuális évtized megállapitása:
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
  if _ezkonverzio then GetKonvertAdatok;
  // A VTEMP adatbázis kiüritése:
  ValutaParancs('DELETE FROM VTEMP');

  // Az öt tábla-oszlop tömbökbe illesztése + engedélyezés tipus gombok is:
  TombBeToltes;

  // A tábla-editek, valutanevek, arfolyamok, értékek lenullázása:
  TablaNullazas;

  if _serveraccess=1 then
    begin
      ArfolyamGomb.Enabled    := False;
      NointernetPanel.Visible := True;
      NointernetPanel.repaint;
    end else
    begin
      ArfolyamGomb.Enabled := True;
      NoInternetPanel.Visible := False;
    end;


  KezdijTablaBeolvasas;

  if _ezKonverzio then
    begin
      logirorutin(pchar('Ez a konverziós vétel eladási része'));

      KonvCimPanel.Visible := True;
      KonvSumPanel.Visible := True;

      _limit  := _konvertIn;
      _maradt := _konvertIn;

      logirorutin(pchar('Ez konverziós eladás. Beadott érték='+inttostr(_limit)));

      LimitTakaro.Visible := False;
      LimitDisplay;
    end;

  // ----------------------------------------------------------------------
  // Saját hatáskörü kedvezmény kijelzése:

  _shk  := GetSajatHataskoru;
  _mShk := 5-_shk;

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
      procedure TEladasForm.DnemKeyDown(Sender: TObject; var Key: Word;
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

      // Forintot nem adunk el:
      if _aktDnem='HUF' then
        begin
          ShowMessage('A FORINT NEM VÁLASZTHATÓ VALUTA');
          _wd[_aktsor].Text := '';
          exit;
        end;

      // Kúnát nem adunk el:
      if _aktDnem='HRK' then
        begin
          ShowMessage('A KÚNA NEM VÁLASZTHATÓ VALUTA');
          _wd[_aktsor].Text := '';
          exit;
        end;


      // Eur érmét nem adunk el:
      if _aktDnem='EUA' then
        begin
          ShowMessage('EURO ÉRMÉT NEM ADUNK EL');
          _wd[_aktsor].Text := '';
          exit;
        end;

      if (_ezkonverzio) AND (_aktdnem=_vetdnem) then
         begin
           Showmessage('AZONOS VALUTANEM NEM KONVERTZÁLHATÓ !');
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

      _aktArfolyam            := _aktEarf;
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

      if _maradt>0 then
        begin
          if _aktdnem<>'JPY' then _bankjegy := trunc(100*_maradt/_aktArfolyam)
          else _bankjegy := trunc(1000*_maradt/_aktArfolyam);
          _wb[_aktsor].Text := inttostr(_bankjegy);
        end;

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
      procedure TEladasForm.BankjegyKeyDown(Sender: TObject; var Key: Word;
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

       _aktdnem := _wdnem[_aktsor];
       GetdnemAdatok(_aktdnem);

      // A szám stringesitett adata:
      _aktBs := trim(_wb[_aktSor].text);

      // A string konvertálása akbankjegy integerbe:
      val(_aktBs,_aktBankJegy,_code);
      if _code<>0 then _aktbankjegy := 0;
      if _aktbankjegy=0 then exit;

      if _aktbankjegy>_aktzaro then
        begin
          Showmessage('NINCS ENNYI ' + _aktdnem + ' BANKJEGYÜNK');
          _wb[_aktsor].text := '';
          Activecontrol := _wb[_aktsor];
          exit;
        end;

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
      if not _ezkonverzio then KezdijengedmenyGomb.Enabled := True;
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
      procedure TEladasForm.ArfolyamKeyDown(Sender: TObject; var Key: Word;
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
            procedure TEladasForm.WA1DblClick(Sender: TObject);
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
                 procedure TEladasForm.ArfolyamotModosit;
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
           procedure TEladasForm.ArfolyamGombClick(Sender: TObject);
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
              procedure TEladasForm.Ujraszamolas;
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
      _aktsoreng   := ValutaQuery.FieldByNAme('SORENGEDMENY').asInteger;

      _wArfolyam[_aktsor]     := _aktArfolyam;
      _wKedvezmenyes[_aktsor] := _aktKedvarf;
      _wBankjegy[_aktsor]     := _aktBankjegy;
      _sorengedmeny[_aktsor]  := _aktsoreng;

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
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%  AZ ADATBEVITELT BEFEJEZTEM  %%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TEladasForm.AdatbevitelKesz(sender:TObject);
// =============================================================================

// Itt befejezte a váltandó valuták bevitelét !
// Az esetleges kedvezményeket az árfolyamban illetve kezelési dijban lezártuk

begin
  if _ezkonverzio then
    begin
      if _fizetendo>_konvertin then
        begin
          ShowMessage('A KONVERTÁLT VALUTA ÉRTÉKE NEM LEHET NAGYOBB !');
          EXIT;
        end;

      konvDataVtempbe;

      if _maradt>=5000 then
        begin
          ShowMessage('AZ ÉRTÉK NEM LEHET 5.000 FT-NÁL NAGYOBB !');
          exit;
        end;
    end;

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
            procedure TEladasForm.EngedelyezoKijeloles;
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
           procedure TEladasForm.ETGOMBClick(Sender: TObject);
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
                    procedure TEladasForm.Folytatas;
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

   if not _ezkonverzio then
     begin

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
           if _scantype=1 then _scanOke := ujokmanyszkennelo
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

       logirorutin(pchar('...'));
     end;

  // ===========================================================================
  //////////////////////////////////////////////////////////////////////////////                                                                          //
  //////////////////   ITT VÉGLEGESITHETÕ A TRANZAKCIÓ   ///////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // ===========================================================================
  // Utolsó kérdés: Mehet-e a tranzakció ?

  _sellOke := confirmRutin;

  // ------------------------------------------
  // Mégsem endedélyezi a tranzakciót a pénztáros . Vissza a fõmenüre

  if _sellOke<>1 then
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

  // ---------------  fizetés eszköze: készpénz, vagy bankkártya ---------------


  _fizetoeszkoz := GetFizetoeszkoz;
  logirorutin(pchar('Választott fizetöeszköz kódja: ' + inttostr(_fizetoeszkoz)));
  if _fizetoeszkoz=-1 then
    begin
      _mResult := -1;
      Kilep.enabled := true;
      exit;
    end;

  _bizonylatSzam := Getbizonylatszam(True);
  logirorutin(pchar('Végleges bizonylatszám: ' + _bizonylatszam));

  // Kiolvassa a távoli gyüjtõ 2 paraméterét: a Táblanevet és Sorszámot

  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _nevtabla    := FieldByNAme('NEVTABLA').asstring;
      _sorszam     := FieldByName('SORSZAM').asInteger;
      _ugyfeltipus := FieldByNAme('UGYFELTIPUS').asString;
      _ugyfelnev   := trim(FieldByName('UGYFELNEV').asString);
      _ugyfelcim   := trim(FieldByNAme('UGYFELCIM').asString);
      _plombaszam  := trim(FieldByName('PLOMBASZAM').asString);
      _kulfoldi    := FieldByNAme('KULFOLDI').asInteger;
      _forras      := trim(FieldByNAme('FORRAS').asString);
      _engedelyezo := trim(FieldByNAme('ENGEDELYEZO').AsString);
      close;
    end;
  Valutadbase.close;

  // ----------  itt kell a VTEMP hiányzó adatait pótolni ----------------------

  logirorutin(pchar('Most a Vtemp adatpotlását végzem'));
  VTempDataPotlas;

  // Kis- vagy nagyügyfél szerveren lévõ gyüjtõjének update-e:
  // Beirja a KISUGYFEL-be a jelenlegi tranzakció adatait:

  if _ugyfelTipus='K' then
    begin
      TRY
        KisugyfelLerendezes;  // _uoke=3
      EXCEPT
      END;
    end;  

  // Nagy ügyfél adatait beépiti a szerver ÜGYFELyy adatbázisba:

  if _uoke=1 then RemoteLerendezes;

  // A NAPIEGYEDIKEZDIJ darabszámának léptetése, ha volt egyedi kezelési díj:

  if _ezEgyediKezdij then
    begin
      logirorutin(pchar('egyedi kezelesi dij regisztrálása'));
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

  if (_kezdijengedmenytip>0) or (_voltkedvezmeny) then ArfelterWrite;

  // ---------------------------------------------------------
  // A QR kod beolvasása a NAV-os pénztárgépbe:

  logirorutin(pchar('most jön a Qr-kod lerendezése'));
  QrKodLerendezes;

  // ---------------------------------------------------------------------------

  // Bekéri a NAV-os nyugta két számát - és beirja öket a VTEMP-be:

  _nyugoke := getnyugtarutin;
  logirorutin(pchar('Navos nyugta számát olvasom be'));

  // ------------------- A SZÁMLA BEIRÁSA A BLOKKFEJBE -------------------------

  _PCS := 'UPDATE VTEMP SET FIZETOESZKOZ='+inttostr(_fizetoeszkoz);
  ValutaParancs(_pcs);

  logirorutin(pchar('Felirja a blokkfej és blokktétel táblákat'));

  BlokkFejIro;
  BlokktetelIro;

  logirorutin(pchar('kezelési dij rögzités'));
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

  logirorutin(pchar('a második qr-kód kiadása'));
  if _fizetoEszkoz=2 then bankkartyarendezes;


  if _engedelyezo<>'' then
    begin
      logirorutin(pchar('Mivel volt engedélyezõ, ezt e-mailben jelzi'));
      MakeXML;
      XMLBemasolas;
    end;



   logirorutin(pchar('Befejezte az eladas procedurát'));
   logirorutin(pchar('...'));

  _mResult := 1;
  Kilep.Enabled := true;
end;

// =============================================================================
                 procedure TEladasForm.Blokkfejiro;
// =============================================================================

var _xBizo,_xtip,_xdatum,_xido,_xugyftip,_xProsnev,_xIdkod,_xPlombaszam: string;
  _xUgyfnev,_xUgyfcim,_xAdoszam,_xZcounts,_xRecnums,_xforras,_xengedelyezo: string;
  _xOsszft,_xUgyfszam,_xtetel,_xstorno,_xmegbizott,_xmegbizoszam: integer;
  _xNetto,_xKezdij,_xFizetendo,_xFizeszkoz,_xKonverzio,_xkerekites: integer;

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
      _xFizeszkoz   := FieldByNAme('FIZETOESZKOZ').asInteger;
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
   _pcs := _pcs + inttostr(_xFizeszkoz) + ',';
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
                   procedure TEladasForm.Blokkteteliro;
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
                  procedure TEladasForm.KezdijRogzito;
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
                function TEladasform.Getfizetoeszkoz: integer;
// =============================================================================

begin

  if (not _ezKonverzio) AND (_otp=1) then
     begin

       logirorutin(pchar('Mivel fizet az ügyfél'));

       // 1=KP, 2=OTP, -1= ELÁLL
       _fizetoeszkoz := fizetoeszkozrutin;

       if _fizetoeszkoz=-1 then
         begin
           logirorutin(pchar('Az ügyfél eláll a vásárlástól'));
           result := -1;
           exit;
         end;

       if (_fizetoeszkoz=2) then
         begin
           logirorutin(pchar('Az ügyfél bankkártyával akar fizetni'));
           _pcs := 'UPDATE VTEMP SET OTPFUNCTYPE=0';
           ValutaParancs(_pcs);

           _otpoke := otpterminal;  ///// TESZT !!!!!!!!!!!!!
           //////////////// _otpOke := 1;
           if _otpOke=2 then
             begin
               logirorutin(pchar('Nem sikerült bankkártyával fizetni'));
               Result := -1;
               exit;
             end;

           if _otpoke=3 then _fizetoeszkoz := 1;
         end;
     end;

  _pcs := 'UPDATE VTEMP SET FIZETOESZKOZ=' + inttostr(_fizetoeszkoz);
  ValutaParancs(_pcs);
  result := _fizetoeszkoz;
end;


// =============================================================================
                  procedure TEladasForm.BankKartyaRendezes;
// =============================================================================

var _randnum: integer;
    _randbizszam: string;

begin
  logirorutin(pchar('A második QR-kód kijelzése indul'));
  randomize;
  _randnum := random(9999);
  _randBizszam := 'FRND'+inttostr(_randnum);

  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (NUMBER,VALUTANEM,BANKJEGY,BIZONYLATSZAM)'+_sorveg;
  _pcs := _pcs + 'VALUES (6,'+chr(39)+'HUF'+CHR(39)+',' + inttostr(_fizetendo)+',';
  _pcs := _pcs + chr(39) + _randbizszam + chr(39) + ')';
  ValutaParancs(_pcs);

  // ------------------QRDISPLAY-(SELLING) -------------------------------------

  qrdisplayrutin;
end;

// =============================================================================
                   procedure TeladasForm.UgyfdataVtempbol;
// =============================================================================

begin
  logirorutin(pchar('Ugyfel adatok beolvasasa a VTempbõl'));

  ValutaDbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _ugyfeltipus:= FieldByNAme('UGYFELTIPUS').asString;
      _ugyfelszam := FieldByName('UGYFELSZAM').asInteger;
      _ugyfelnev  := trim(FieldByNAme('UGYFELNEV').asstring);
      Close;
    end;

   _mess := 'Ügyftip/szám: '+_ugyfeltipus+'/'+inttostr(_ugyfelszam);
   logirorutin(pchar(_mess));

  _szulido   := '';
  _szulhely  := '';
  _allampolg := '';

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
          _tarthely  := trim(ValutaQuery.FieldByName('TARTOZKODASIHELY').AsString);
          _anyja     := trim(ValutaQuery.FieldByName('ANYJANEVE').AsString);
          _IRSZAM    := trim(ValutaQuery.FieldByName('IRSZAM').AsString);
          _varos    := trim(ValutaQuery.FieldByName('VAROS').AsString);
          _utca    := trim(ValutaQuery.FieldByName('UTCA').AsString);
          _lakcim  := leftstr(_irszam+' '+_varos+' '+_utca,40);
        end;
      ValutaQuery.close;
    end;

  Valutadbase.close;
end;


// =============================================================================
                        procedure TEladasForm.Vtempbeir;
// =============================================================================

var _akttenyint: integer;

begin
  if _aktDnem='JPY' then _aktTenyArfolyam := 10*_aktTenyArfolyam;
  _aktTenyInt := round(_aktTenyArfolyam+_rounder);
  if _aktDnem='JPY' then _aktTenyArfolyam := round((_aktTenyInt/10)+_rounder)
  else _aktTenyArfolyam := _aktTenyInt;

  _pcs := 'UPDATE VTEMP SET BANKJEGY=' + inttostr(_aktbankjegy);
  _pcs := _pcs + ',ARFOLYAM=' + inttostr(_akttenyarfolyam);
  _pcs := _pcs + ',ELOJEL=' + chr(39) + '-' + chr(39);
  _pcs := _pcs + ',KEDVEZMENYESARFOLYAM='+intToStr(_KEDVARFOLYAM);
  _pcs := _pcs + ',FORINTERTEK=' + inttostr(_aktertek)+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);

  ValutaParancs(_pcs);
end;



// =============================================================================
            procedure TEladasForm.VegeTimerTimer(Sender: TObject);
// =============================================================================

begin
  VegeTimer.Enabled := False;
  ModalResult := _mResult;
end;

// =============================================================================
                           function TEladasForm.Getidos:string;
// =============================================================================

begin
  Result := TimeToStr(Now);
  if midStr(Result,2,1) = ':' then Result := '0' + Result;
  result := leftStr(result,5);
end;

// =============================================================================
                       procedure TEladasForm.MaradtBeolvaso;
// =============================================================================

var _sh,_ne: byte;

begin
  _pcs := 'SELECT * FROM HARDWARE';

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;

      _maiStornoDarab := FieldByName('NAPISTORNO').asInteger;
      _sh  := FieldByNAme('SAJATHATASKORU').asInteger;
      _ne  := FieldByNAme('NAPIEGYEDIKEZDIJ').asInteger;
      _otp := FieldByname('OTPOPEN').asInteger;
      Close;
    end;

  ValutaDbase.close;

  _mshk := 5-_sh;
  _mekd := 3-_ne;
end;

// =============================================================================
         function TEladasForm.GetBizonylatszam(_write: boolean): string;
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
      _lastSellBlokknum := ValutaQuery.FieldByName('UTOLSOELADASBLOKK').asInteger;
      Close;
    end;

  ValutaDbase.close;
  inc(_lastSellBlokkNum);

  if _lastSellBlokknum>= 999990 then _lastSellBlokknum := 100000;
  Result  := 'E' + _bizelokod + Nulele(_lastSellBlokkNum,6);

  if _write then
    begin
      _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOELADASBLOKK='+inttostr(_lastSellBlokknum)+',';
      _pcs := _pcs + 'AKTUALISBIZONYLATSZAM='+chr(39)+ result + chr(39);
      ValutaParancs(_pcs);
    end;
end;

// =============================================================================
            function TEladasForm.Nulele(_b: integer;_hh: byte): string;
// =============================================================================

begin
  result := intToStr(_b);
  while length(result)<_hh do result := '0' + result;
end;

// =============================================================================
             procedure TEladasForm.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.Close;
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
            function TEladasForm.KeszletKontrol(_dn: string): integer;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+_dn+chr(39);

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Result := FieldByName('ZARO').asInteger;
      Close;
    end;
  ValutaDbase.close;
end;

// =============================================================================
           function TEladasForm.Kerekito(_int: integer): integer;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _int;
  _nums  := intToStr(_int);
  _wNums := length(_nums);
  _utDig := ord(_nums[_wNums])-48;

  if (_utDig<>0) and (_utDig<>5) then
    begin
      if (_utDig=1) or (_utDig=2) then result := _int-_utDig;
      if (_utDig=6) or (_utDig=7) then result := _int-(_utDig-5);
      if (_utDig=3) or (_utDig=4) then result := _int+(5-_utDig);
      if (_utDig=8) or (_utDig=9) then result := _int+10-_utDig;
    end;
end;

// =============================================================================
           function TEladasForm.Elokieg(_szo: string;_hh: integer):string;
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
             function TEladasForm.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel    : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';
  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intToStr(_osszeg);

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
            function TeladasForm.GetTranzdij(_ss: integer): integer;
// =============================================================================

var _qq: byte;

begin

  if _vanKezdijEngedmeny then
    begin
      result := _kezelesidij;
      exit;
    end;

  if (_realEzrelek>0) then
     begin
       result := Kerekito(trunc(_ss*_realEzrelek/1000));
       if result>_kezdijMax then Result := _kezdijMax;
       exit;
     end;

  (*
  result := 50;
  if _ss<2001 then exit;

  result := 100;
  if _ss<=10001 then exit;

  result := 120;
  if _ss<=20001 then exit;

  result := 150;
  if _ss<=30001 then exit;

  result := 200;
  if _ss<=50001 then exit;

  result := 250;
  if _ss<=60001 then exit;

  result := 280;
  if _ss<=70001 then exit;

  result := 320;
  if _ss<=80001 then exit;

  result := 350;
  if _ss<=90001 then exit;

  result := 400;
  if _ss<=100001 then exit;

  result := 420;
  if _ss<=120001 then exit;

  result := 450;
  if _ss<=130001 then exit;

  result := 500;
  if _ss<=140001 then exit;

  result := 600;
  if _ss<=150001 then exit;

  result := 700;
  if _ss<=200001 then exit;

  result := 900;
  if _ss<=400001 then exit;

  result := 1200;
  if _ss<=500001 then exit;

  result := 1500;
  if _ss<=700001 then exit;

  result := 1800;
  if _ss<=5000001 then exit;


  result := 2000;
  if _ss<10000001 then exit;

  result := 2500;
  *)

  _qq := 1;
  while _qq<=_maxSavDb do
    begin
      result := _kDij[_qq];
      if _ss<=_tranzSav[_qq] then exit;
      inc(_qq);
    end;
  result := _kezdijMax;
end;


// =============================================================================
          function TEladasForm.GetkedvArf(_adnem: string): integer;
// =============================================================================


begin
  _pcs := 'SELECT * FROM VTEMP WHERE VALUTANEM=' + chr(39)+_adnem + chr(39);
  TempDbase.Connected := true;
  with TempQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Result := FieldByName('KEDVEZMENYESARFOLYAM').asInteger;
      Close;
    end;
  TempDbase.close;
end;

// =============================================================================
           procedure TEladasForm.MaradtLepteto(_mit: byte);
// =============================================================================

var _shk,_nek: byte;

begin
  Maradtbeolvaso;
  case _mit of
    1: if _mshk>0 then dec(_mshk);
    2: if _mekd>0 then dec(_mekd);
    3: inc(_maiStornoDarab);
  end;

  _shk := 5-_mshk;
  _nek := 3-_mekd;

  _pcs := 'UPDATE HARDWARE SET ';

  case _mit of
    1: _pcs := _pcs + 'SAJATHATASKORU='+inttostr(_shk);
    2: _pcs := _pcs + 'NAPIEGYEDIKEZDIJ='+inttostr(_nek);
    3: _pcs := _pcs + 'NAPISTORNO='+inttostr(_maistornodarab);
  end;

  ValutaParancs(_pcs);
end;

// =============================================================================
             procedure TEladasForm.ArfvaltParaWrite(_adnem: string);
// =============================================================================

begin
  _pcs := 'UPDATE VTEMP SET MEGJEGYZES=' + chr(39)+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'UPDATE VTEMP SET MEGJEGYZES=' + chr(39) + '+' + chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _adnem + chr(39);

  ValutaParancs(_pcs);
end;

// =============================================================================
                procedure TEladasForm.UgyfelAdatBeolvasas;
// =============================================================================

var _mbvaros,_mbutca,_mbttvaros,_mbttutca: string;

begin
  logirorutin(pchar('Ügyfél adat beolvasás'));

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;
      _engedelyezo := trim(FieldByNAme('ENGEDELYEZO').AsString);
      _forras      := trim(FieldByName('FORRAS').AsString);
      _ugyfelTipus := FieldByNAme('UGYFELTIPUS').asString;
      _ugyfelSzam  := FieldByNAme('UGYFELSZAM').asInteger;
      _secur       := FieldByNAme('SECURLEVEL').asInteger;
      _kozSzereplo := FieldByNAme('KOZSZEREPLO').asInteger;
      _megBizo     := FieldByNAme('MEGBIZOSZAM').asInteger;
      _tulajDarab  := FieldByNAme('TULAJDONOS').asInteger;
      _kulfoldi    := FieldByNAme('KULFOLDI').asInteger;
      _nevtabla    := FieldByNAme('NEVTABLA').asString;
      _sorszam     := FieldByNAme('SORSZAM').asInteger;
      close;
    end;

  _mess := 'Tip/szám='+_ugyfeltipus+'/'+inttostr(_ugyfelszam);
  logirorutin(pchar(_mess));
  _securLevel := False;
  if _secur=1 then _securlevel := True;
  _plombaszam := _nevtabla + inttostr(_sorszam);

  if _ugyfelTipus='N' then
    begin
      _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_ugyfelSzam);

      with ValutaQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          with ValutaQuery do
            begin
              _ugyfelNev   := trim(FieldByNAme('NEV').asString);
              _irSzam      := trim(FieldByNAme('IRSZAM').asString);
              _varos       := trim(FieldByname('VAROS').asstring);
              _utca        := trim(FieldByNAme('UTCA').asString);
              _okmanyTipus := trim(FieldByNAme('OKMANYTIPUS').asString);
              _azonosito   := trim(FieldByNAme('AZONOSITO').asString);
            end;
          _lakcim := leftstr(_irszam +' ' + _varos + ' '+_utca,40);
        end;

      ValutaQuery.close;

      if _megbizo>0 then
        begin
          _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
          _pcs := _pcs + 'WHERE UGYFELSZAM=' +inttostr(_megbizo);

          with ValutaQuery do
            begin
              Close;
              Sql.clear;
              Sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              _megbizoNev := trim(VAlutaquery.fieldBYNAme('NEV').asString);
              _mbVaros    := trim(ValutaQuery.FieldByName('VAROS').asString);
              _mbUtca     := trim(ValutaQuery.FieldByNAme('UTCA').asString);
              _megbizoCim := leftstr(_mbVaros + ', '+_mbUtca,55);
            end;
          Valutaquery.Close;
        end;
    end;

  if _ugyfeltipus = 'J' then
    begin
      _pcs := 'SELECT * FROM JOGISZEMELY' + _sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM=' + intToStr(_ugyfelSzam);
      with ValutaQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          _ugyfelNev := trim(ValutaQuery.FieldByNAme('JOGISZEMELYNEV').asstring);
          _telepHely := trim(ValutaQuery.FieldByNAme('TELEPHELYCIM').asstring);
          _megbizottSzam := ValutaQuery.FieldBynAme('MEGBIZOTTSZAMA').asInteger;
          Close;
        end;

      if _megbizottSzam>0 then
        begin
          _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
          _pcs := _pcs + 'WHERE UGYFELSZAM=' +intToStr(_megbizottSzam);
          with ValutaQuery do
            begin
              Close;
              Sql.clear;
              Sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              _megbizottNev := trim(ValutaQuery.FieldBYNAme('NEV').asString);
              _mbttVaros    := trim(ValutaQuery.FieldByName('VAROS').asString);
              _mbttUtca     := trim(ValutaQuery.FieldByNAme('UTCA').asString);
              _megbizottCim := leftstr(_mbttVaros+', '+_mbttUtca,55);
            end;
          Valutaquery.close;
        end;
    end;


  Valutadbase.close;
end;

// =============================================================================
                      procedure TEladasForm.AktualNullazo;
// =============================================================================

begin
  _pcs := 'UPDATE UTOLSOBLOKKOK SET AKTUALISBIZONYLATSZAM='+CHR(39)+CHR(39);
  ValutaParancs(_pcs);
end;


// =============================================================================
                       procedure TEladasForm.ArfelterWrite;
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
                    512 - KÁRTYÁS ELENGEDÉS (JELSZÓ NÉLKÜL)
                   1024 - ÜGYVEZETÕ JELSZAVAS ELENGEDÉS            JELSZAVAS
                   2048 - EGYEDILEG ADHATÓ KEZELÉSI DÍJ (MAX 3%%)

}

var _whi: word;

begin
  logirorutin(pchar('Arfolyam eltérés felirása indul'));
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
                procedure TEladasForm.KezdijBeepites(_kk: integer);
// =============================================================================

var _napikdij: integer;

begin
  _pcs := 'SELECT * FROM KEZELESIDATA';

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _kezdij := FieldByname('AKTKEZELESIDIJ').asInteger;
      _napikdij := FieldByNAme('NAPIKEZELESIDIJ').asInteger;
      Close;
    end;
  Valutadbase.Close;

  _kezDij   := _kezDij + _kk;
  _napikdij := _napikdij + _kk;

  _pcs := 'UPDATE KEZELESIDATA SET AKTKEZELESIDIJ='+inttostr(_kezdij);
  _pcs := _pcs + ',NAPIKEZELESIDIJ='+inttostr(_napikdij);

  ValutaParancs(_pcs);
end;

// =============================================================================
            procedure TEladasForm.BizRegiszter(_xbiz: string);
// =============================================================================

var _bizFile: string;
    _bizIro: textfile;

begin
  _bizFile := 'c:\valuta\aktbizo.txt';

  AssignFile(_bizIro,_bizFile);
  Rewrite(_bizIro);
  Write(_bizIro,_xBiz);
  CloseFile(_bizIro);
end;

// =============================================================================
                        procedure TEladasForm.UjadatlapIro;
// =============================================================================

begin
  // Amennyiben nem szükséges, akkor nincs mit tenni:

  if not _securLevel then exit;


  // ---------------------------------------------------------------------------
  // Kiolvassa az utolso adatlapszámot:

  _pcs := 'SELECT * FROM UTOLSOBLOKKOK';

  valutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _aktAdatLapSzam := ValutaQuery.FieldByNAme('UTOLSOADATLAPSZAM').asInteger;
  ValutaQuery.close;
  ValutaDbase.close;

  inc(_aktAdatLapSzam);

  // A léptetett adatlapsorszámot is beirjuk az utolsóblokkokba:

  _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOADATLAPSZAM='+inttostr(_aktadatlapszam);
  ValutaParancs(_pcs);

  // ---------------------------------------------------------------------------
  // Végul kitöltjük az adatlapot is

  _pcs := 'INSERT INTO ADATLAP (SORSZAM,DATUM,IDO,PENZTARKOD,PENZTAROSNEV,';
  _pcs := _pcs + 'UGYFELTIPUS,UGYFELSZAM,UGYFELNEV,NEVTABLA,NEVSORSZAM,';
  _pcs := _pcs + 'OSSZESFORINT,STORNO)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + intToStr(_aktAdatlapSzam)+',';
  _pcs := _pcs + chr(39)+_megnyitottNap+chr(39)+',';
  _pcs := _pcs + chr(39)+_aktIdos+chr(39)+',';
  _pcs := _pcs + chr(39)+_homePenztarSzam+chr(39)+',';
  _pcs := _pcs + chr(39)+_aktPenztarosNev+chr(39)+',';
  _pcs := _pcs + chr(39)+_ugyfelTipus+chr(39)+',';
  _pcs := _pcs + intToStr(_aktUgyfelSzam)+',';
  _pcs := _pcs + chr(39)+_aktUgyfelNev+chr(39)+',';
  _PCS := _pcs + chr(39)+_nevtabla+chr(39)+',';
  _pcs := _pcs + intToStr(_SORSzam)+',';
  _pcs := _pcs + intToStr(_sumErtek)+',1)';
  ValutaParancs(_pcs);
end;




// =============================================================================
          function TEladasForm.Adatolvasas(_adnem: string): integer;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+_adnem+chr(39);

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      sql.add(_pcs);
      Open;
      First;
      result := recno
    end;

  if result=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  with ValutaQuery do
    begin
      _aktArfolyam := FieldByName('ELADASIARFOLYAM').asInteger;
      _aktDnev     := trim(FieldByName('VALUTANEV').asString);
      _aktElszarf  := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      _aktZaro     := FieldbyName('ZARO').asInteger;
      close;
    end;
  ValutaDbase.close;
end;



// =============================================================================
                     procedure TEladasForm.BankkartyaKonyveles;
// =============================================================================

begin
  BkInfoPanel.Visible := True;
  BkInfopanel.Repaint;

  _pcs := 'UPDATE VTEMP SET TETEL=' + IntToStr(_tetel)+',TIPUS=';
  _pcs := _pcs + chr(39) + 'E' + chr(39)+ ',FIZETENDO='+intToStr(_fizetendo);
  _pcs := _pcs + ',RATETYPE='+intToStr(_aktrateType);
  ValutaParancs(_pcs);
end;





// =============================================================================
               procedure TEladasForm.FormCreate(Sender: TObject);
// =============================================================================

begin

  KonvCimpanel.Visible     := False;
  KonvSumPanel.Visible     := False;

  _width  := Screen.Monitors[0].width;
  _height := Screen.Monitors[0].height;

  _top   := round((_height-768)/2);
  _left  := round((_width-1024)/2);

  Top    := _top;
  Left   := _left;
end;



// =============================================================================
                   procedure TEladasForm.NyugtaszamBeiras;
// =============================================================================

begin
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;
      _recnums := FieldByName('RECNUMS').asString;
      _zcounts := FieldbyName('ZCOUNTS').asString;
      Close;
    end;

  ValutaDbase.close;

  _pcs := 'UPDATE BLOKKFEJ SET RECNUMS='+chr(39)+_recnums+chr(39);
  _pcs := _pcs + ',ZCOUNTS='+chr(39)+_zcounts+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+ _bizonylatszam + chr(39);
  ValutaParancs(_pcs);

  logirorutin(pchar('NAV számok: '+_zcounts+'/'+_recnums));

end;



// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$ SEGÉD PROGRAMOK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================

// =============================================================================
                    procedure TEladasForm.EditTombTolto;
// =============================================================================

var i: byte;

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

  for i := 1 to 6 do _wb[i].Enabled := True;
end;


// =============================================================================
                        procedure TEladasForm.TablaUrito;
// =============================================================================

var i: integer;

begin
  for i := 1 to 6 do
    begin
      _sorEngedmeny[i] := 0;
      SorNullazas(i);
      if i>1 then SorLetilt(i);
    end;
  NettoPanel.Caption := '';
  TranzdijPanel.Caption := '';

  ValutaParancs('DELETE FROM VTEMP');
  logirorutin(pchar('A VTEMP TÁBLÁT KINULLÁZOM'));

end;


// =============================================================================
               procedure TEladasForm.Sorletilt(_dsor: integer);
// =============================================================================

begin
  _wd[_dSor].Enabled := False;
  _wa[_dSor].Enabled := False;
  _wb[_dSor].Enabled := False;
end;

// =============================================================================
               procedure TEladasForm.SorRelease(_dsor: integer);
// =============================================================================

begin
  _wd[_dSor].Enabled := True;
  _wa[_dSor].Enabled := True;
  _wb[_dSor].Enabled := True;
end;




// =============================================================================
             procedure TEladasForm.WD1Enter(Sender: TObject);
// =============================================================================

var _egyes: integer;

begin
  TEdit(sender).Color := $B0FFFF;
  _tag := Tedit(sender).tag;
  _oszlop := trunc(_tag/10);
  _egyes := _tag - trunc(10*_oszlop);
  _activeSor := _egyes;
end;

// =============================================================================
                procedure TEladasForm.WD1Exit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWhite;
end;


// =============================================================================
       function TEladasform.VanilyenDnem(_adnem: string): boolean;
// =============================================================================

var _y: integer;

begin
  result := False;
  for _y:= 1 to 6 do
    begin
      if leftStr(_wDnem[_y],2)=leftStr(_aDnem,2) then
        begin
          ShowMessage('ILYEN VALUTA MÁR VAN');
          Result := True;
          Break;
        end;
    end;
end;


// =============================================================================
       procedure TEladasForm.FormKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
   _bill := ord(key);
  if _bill=27 then
    begin
      KilepniAkar;
      exit;
    end;

  if _bill=35 then  // end
    begin
      if EndGomb.Enabled then AdatBevitelKesz(Nil);
      EndGomb.Enabled := False;
      exit;
    end;
end;


// =============================================================================
           procedure TEladasForm.NemlepkiGOMBClick(Sender: TObject);
// =============================================================================

begin
  QuitSurePanel.Visible := false;
end;

// =============================================================================
           procedure TEladasForm.IgenKilepGombClick(Sender: TObject);
// =============================================================================

begin
  KeyPreview := False;
  _MResult := 2;
  Vegetimer.Enabled := True;
end;

// =============================================================================
           procedure TEladasForm.NemlepkiGombEnter(Sender: TObject);
// =============================================================================

begin
  TBitBtn(sender).Font.Style := [fsBold];
end;

// =============================================================================
            procedure TEladasForm.NemlepkiGombExit(Sender: TObject);
// =============================================================================

begin
  TBitBtn(sender).Font.Style := [];
end;


// =============================================================================
              procedure TEladasForm.SorNullazas(_tSor: integer);
// =============================================================================

begin
  _wd[_tSor].ReadOnly   := False;
  _wd[_tSor].Text       := '';
  _wn[_tSor].Caption    := '';
  _wa[_tSor].Text       := '';
  _wb[_tSor].Text       := '';
  _wf[_tSor].Caption    := '';
  _wDnem[_tSor]         := '';
  _wDnev[_tSor]         := '';

  _wArfolyam[_tSor]     := 0;
  _wElszamolasi[_tSor]  := 0;
  _wOrigArfolyam[_tsor] := 0;
  _wKedvezmenyes[_tSor] := 0;

  _wBankjegy[_tSor]     := 0;
  _wErtek[_tSor]        := 0;
end;




//==============================================================================
            procedure TEladasForm.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  if _tetel=0 then
    begin
      KeyPreview := False;
      _Mresult := 2;
      Vegetimer.Enabled := True;
      exit;
    end;

  KilepniAkar;
end;

// =============================================================================
                     procedure TEladasForm.KilepniAkaR;
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
                procedure TEladasform.FizetendoDisplay;
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

  if not _ezkonverzio then
    begin
      // Az alap (kiszámitott) kezelési dij:
      _origkezdij := Getkezelesidij(_netto);

     // Ha még nincs eltéritett kezelési dij, akkor marad az eredeti kez-i dij:

     if _fixKezelesiDij=-1 then _kezelesidij := _origkezdij
     else _kezelesidij := _fixkezelesidij;
     if _kezelesidij<0 then _kezelesidij := 0;
     if _kezdijengedmenytip<1 then Kezdijengedmenygomb.enabled := True;
   end else
   begin
     _origkezdij := 0;
     _kezelesidij := 0;
   end;

  _brutto    := _netto + _kezelesiDij; // eladásnál plusz !!!
  _fizetendo := Kerekito(_brutto);
  _kerekites := _fizetendo-_brutto;

  KerekitesPanel.Caption := intTostr(_kerekites);
  KerekitesPanel.Repaint;




  _pcs := 'UPDATE VTEMP SET NETTO='+inttostr(_netto)+',ORIGKEZDIJ='+inttostr(_origkezdij);
  _pcs := _pcs + ',BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  _pcs := _pcs + ',ELOJEL=' + chr(39) + '-' +chr(39);
  _pcs := _pcs + ',TETEL=' + inttostr(_tetel);
  _pcs := _pcs + ',KEREKITES=' + inttostr(_kerekites);
  _pcs := _pcs + ',KEZELESIDIJ=' + inttostr(_kezelesidij);
  _pcs := _pcs + ',FIZETENDO=' + inttostr(_fizetendo);
  ValutaParancs(_pcs);

  NettoPanel.Caption     := ForintForm(_netto);
  TranzdijPanel.Caption  := ForintForm(_kezelesidij);
  SumosszegLabel.caption := ForintForm(_fizetendo);
  Limitdisplay;
end;



// =============================================================================
                        procedure TEladasForm.Dnem2Vtemp;
// =============================================================================

begin

  _pcs := 'INSERT INTO VTEMPD (VALUTANEM,VALUTANEV,ARFOLYAM,EREDETIARFOLYAM,';
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM,COIN)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnev + chr(39) + ',';
  _pcs := _pcs + inttostr(_akttenyarfolyam) + ',';
  _pcs := _pcs + inttostr(_aktarfolyam) + ',';
  _pcs := _pcs + inttostr(_aktelszarf) + ',0)';

  ValutaParancs(_pcs);
end;


// =============================================================================
                 function TEladasform.GetPtParams: string;
// =============================================================================


begin
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _bk := FieldByNAme('BKKS').asInteger;
      Close;
    end;
  Valutadbase.close;

  if _bk<10 then _bk := 9;
  inc(_bk);

  if _bk>99 then _bk := 10;

  _pcs := 'UPDATE HARDWARE SET BKKS='+ inttostr(_bk);
  ValutaParancs(_pcs);

  _ftstring := getFtstring(_fizetendo);
  result := _hpts +inttostr(_bk)+'10'+_ftstring+'0000000000';
end;


// =============================================================================
         function TEladasForm.GetFtString(_ft: real): string;
// =============================================================================

begin
  result := '0000000000';
  if _ft=0 then exit;

  _ft := trunc(_ft*100);
  result := floattostr(_ft);
  while length(result)<10 do result := '0' + result;
end;



// ============================================================================
          procedure TEladasform.XMLBemasolas;
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
      logirorutin(pchar('Sikeres email küldés az engedélyezöröl'));
      ShowMessage('AZ E-MAILEKET SIKERESEN ELKÜLDTEM')
    end else
    begin
      logirorutin(pchar('Sikertelen e-mail küldés'));
      ShowMessage('SIKERTELEN E-MAIL KÜLDÉS');
    end;
  Sysutils.DeleteFile('c:\valuta\' +_localpath);
end;


// =============================================================================
           function TEladasForm.DropHung(_eTXt: string): string;
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
             function TEladasform.CHChange(_inkod: byte): byte;
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
                  procedure TEladasForm.Figyelmeztetes;
// =============================================================================

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


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$  KEZELÉSI DÍJ ENGEDMÉNYEK $$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
          procedure TEladasForm.KEZDIJENGEDMENYGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _kezdijEngedmenyTip>0 then exit;

  if _realEzrelek=0 then exit;

  _ezEgyediKezdij := False;
  _kezdijengedmenytip := kezdijkedvezmeny;
  if _kezdijengedmenytip>0 then
    begin
      KezdijEngedmenyGomb.Enabled := False;
      Panel2.Enabled := False;
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
      Valutadbase.close;
      if _kezdijEngedmenytip=6 then _ezEgyedikezdij := True;
    end;
  FizetendoDisplay;
end;

// =============================================================================
            function TEladasForm.GetKezelesidij(_ss: integer): integer;
// =============================================================================

var _qq: byte;

begin
  result := 0;
  if _realezrelek=0 then exit;

  if (_realEzrelek>0) then
     begin
       result := Kerekito(trunc(_ss*_realEzrelek/1000));
       if result>_kezdijmax then Result := _kezdijmax;
       exit;
     end;

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
               procedure TEladasForm.KedvezmenyAnalizis;
// =============================================================================

begin
 // Ha valamelyik tétel engedményes akkor _VOLT8 = True

  _cc:= 1;
  _volt8 := False;
  while _cc<=_tetel do
    begin
      if _sorEngedmeny[_cc]=8 then
        begin
           logirorutin(pchar(inttostr(_cc)+' tétel kedvezményes'));
          _volt8 := true;
          break;
        end;
      inc(_cc);
    end;

  // Ha volt sorengedmeny -> a 8-at átirja a megfelelö tipusu kódra
  //                         és _voltRAteMode-t True-ra állitja

  _aktRateType := 0;
  if _volt8 then
    begin
      _aktRateType  := setraterutin;
      _voltRateMode := True;
      _cc := 1;
      while _cc<=_tetel do
        begin
          if _sorEngedmeny[_cc]=8 then _sorEngedmeny[_cc] := _aktRateType;
          inc(_cc);
        end;
    end;
end;

// =============================================================================
                      procedure TEladasForm.VtempKitoltes;
// =============================================================================


begin
  _pcs := 'UPDATE VTEMP SET NETTO='+inttostr(_netto);
  if _voltrateMode then _pcs := _pcs + ',RATETYPE=' + inttostr(_ratetype);
  _pcs := _pcs + ',FIZETENDO=' + inttostr(_fizetendo);
  _pcs := _pcs + ',KEREKITES=' + inttostr(_kerekites);
  _pcs := _pcs + ',KONVERZIO=' + inttostr(_konverzio);
  _pcs := _pcs + ',OSSZESFORINTERTEK=' + inttostr(_netto);
  _pcs := _pcs + ',FIZETOESZKOZ=' + inttostr(_fizetoeszkoz);
  _pcs := _pcs + ',BIZONYLATSZAM=' + chr(39) + _bizonylatszam + chr(39);
  _pcs := _pcs + ',TIPUS=' + chr(39) + 'E' + chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _megnyitottnap + chr(39);
  _pcs := _pcs + ',IDO=' + chr(39) + leftstr(_aktidos,5) + chr(39);
  _pcs := _pcs + ',TETEL=' + inttostr(_tetel);
  _pcs := _pcs + ',KEZELESIDIJ=' + inttostr(_kezelesidij);
  _pcs := _pcs + ',KOZSZEREPLO=' + inttostr(_kozszereplo);
  _pcs := _pcs + ',STORNO=' + inttostr(_storno);
  _pcs := _pcs + ',SZALLITONEV=' + chr(39) + _cardnums + chr(39);
  ValutaParancs(_pcs);
end;



// =============================================================================
                   procedure TEladasForm.GetkonvertAdatok;
// =============================================================================

begin
  logirorutin(pchar('Get konverziós adatok'));
  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;

      _konvertin := FieldbyNAme('FIZETENDO').asInteger;
      _vetbiz    := trim(FieldByName('BIZONYLATSZAM').asString);
      _vetdnem   := FieldByName('VALUTANEM').asString;
      _vetarf    := FieldByName('ARFOLYAM').asInteger;
      _vetBjegy  := FieldbyName('BANKJEGY').asInteger;
      _secur     := FieldByNAme('SECURLEVEL').asInteger;
      _kulfoldi  := FieldByName('KULFOLDI').asInteger;

      _engedelyezo := trim(FieldByNAme('ENGEDELYEZO').asString);
      _forras      := trim(FieldByNAme('FORRAS').asString);
      _ugyfeltipus := fieldByName('UGYFELTIPUS').asString;
      _ugyfelszam  := FieldByNAme('UGYFELSZAM').asInteger;
      _ugyfelnev   := trim(FieldByNAme('UGYFELNEV').asString);
      _ugyfelcim   := trim(FieldByNAme('UGYFELCIM').asString);
      _nevtabla    := trim(FieldByName('NEVTABLA').asString);
      _sorszam     := FieldByNAme('SORSZAM').asInteger;
      _plombaszam  := trim(FieldByNAme('PLOMBASZAM').asString);
      Close;
    end;
  Valutadbase.close;
  _limit  := _konvertin;
  _maradt := _limit;
  Limitdisplay;
end;

// =============================================================================
                    procedure TEladasForm.SetupAlapra;
// =============================================================================

begin
  SumOsszegLabel.Caption      := '0';    // A nagybetüs fizetendo felirat = '0'

  _cardNums                := '';      // kartyaszám nincs
  _trbPenztar              := '';      // itt nincs trb pénztár
  _xKezdTip                := '';      // Rxtra kez dij tipusa (üres)
  _savos                   := False;   // nem sávos a kezelési dij

end;


// =============================================================================
              procedure TEladasform.KisugyfelLerendezes;
// =============================================================================

begin
  if _serveraccess=1 then exit;

  logirorutin(pchar('Kisügyfél lerendezése'));
  IF (_nevtabla='') or (_sorszam=0) then exit;

  Remotedbase.close;

  RemoteDbase.databaseName := _kisremotePath;
  RemoteDbase.connected := true;
  logirorutin(pchar('Kisremotepath: '+_kisremotepath));

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  logirorutin(pchar(_pcs));

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

   _mess := 'Fto='+inttostr(_fto) + ' + _fizetendo='+inttostr(_fizetendo);
   logirorutin(pchar(_mess));
   _fto := _fto + _fizetendo;

   _pcs := 'UPDATE ' + _nevtabla + ' SET OSSZEG='+inttostr(_fto);
   _pcs := _Pcs + ',LASTDATE='+chr(39)+_megnyitottnap+chr(39)+_sorveg;
   _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
   logirorutin(pchar('pcs: '+_pcs));

   RemoteParancs(_pcs);
   logirorutin(pchar('Kisügyfél lerendezve'));
end;

// =============================================================================
             procedure TEladasForm.RemoteParancs(_ukaz: string);
// =============================================================================

begin
  if _serveraccess=1 then exit;

  remoteDbase.Connected := True;
  if remoteTranz.InTransaction then remoteTranz.Commit;
  RemoteTranz.StartTransaction;
  with Remotequery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  RemoteTranz.Commit;
  RemoteDbase.close;
end;

// =============================================================================
           function TEladasForm.Napidiff(_d1,_d2: string): integer;
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
          function TeLADASform.String2Date(_s: string): TDatetime;
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
                    procedure TEladasForm.KonvertHiba;
// =============================================================================

begin
  if _kdiff<0 then Mindiffpanel.Visible := true;
  if _kdiff>5000 then toobigpanel.Visible := true;
  with KonvHibaPanel do
    begin
      top  := 305;
      left := 256;
      Visible := True;
      repaint;
    end;
  sleep(3500);
  KonvhibaPanel.Visible := False;
end;

// =============================================================================
              procedure TEladasform.RemoteLerendezes;
// =============================================================================

begin
  if _serveraccess =1 then exit;

  logirorutin(pchar('Remote lerendezés indul'));
  Remotedbase.close;
  remotedbase.databasename := _remotePath;
  Remotedbase.connected := true;

  if _ugyfeltipus='J' then
    begin
      remoteJogiLerendezes;
      exit;
    end;


  IF (_NEVTABLA='') or (_sorszam=0) then exit;

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _lakcim := trim(FieldByNAme('LAKCIM').asString);
      _lakcimcard := trim(FieldByNAme('LAKCIMKARTYA').AsString);
      _allampolg := trim(FieldByNAme('ALLAMPOLGAR').AsString);
      _okmanytipus := trim(FieldByNAme('OKMANYTIP').AsString);
      _azonosito := trim(FieldByNAme('AZONOSITO').AsString);
      _tarthely := trim(FieldByNAme('TARTOZKODASIHELY').AsString);
      _iso := fieldByNAme('ISO').asString;
      _kozszerep := fieldByNAme('KOZSZEREP').asInteger;
      _kulfoldi := FieldByNAme('KULFOLDI').asInteger;

      _trdb := FieldByName('TRANZAKCIODB').asInteger;
      _fto  := FieldByNAme('FORINTOSSZEG').asInteger;
      _evimax := FieldByName('EVIMAX').asInteger;
      _lastdatum := FieldByName('DATUM').asString;
      _hetift := FieldByNAme('HETIOSSZ').asInteger;
      close;
    end;
  Remotedbase.close;

  inc(_trdb);
  _fto := _fto + _Fizetendo;
  if _evimax<_Fizetendo then _evimax := _fizetendo;
  _diff := Napidiff(_lastdatum,_megnyitottnap);
  if _diff>7 then _hetift := _fizetendo
  else _hetift := _hetift + _fizetendo;

  _pcs := 'UPDATE ' + _nevtabla + ' SET TRANZAKCIODB='+inttostr(_trdb);
  _pcs := _pcs + ',FORINTOSSZEG=' + inttostr(_fto);
  _pcs := _pcs + ',EVIMAX=' + inttostr(_evimax);
  _pcs := _pcs + ',HETIOSSZ=' + inttostr(_hetift);
  _pcs := _pcs + ',DATUM=' + chr(39)+_megnyitottnap+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  Remoteparancs(_pcs);

  _kbetu := leftstr(_nevtabla,1);
  _biztabla := _kBetu + 'BIZ';

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
  _pcs := _pcs + inttostr(_fizetendo) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ')';
  RemoteParancs(_pcs);
  logirorutin(pchar('Remote lerendezés befejezve'));
end;

// =============================================================================
              procedure TEladasForm.RemoteJogiLerendezes;
// =============================================================================

begin
  if _serveraccess=1 then exit;

  Remotedbase.close;
  remotedbase.databasename := _remotePath;
  Remotedbase.connected := true;

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _mbdata := trim(Fieldbyname('MBDATASORSZAM').AsString);
      _trdb := FieldByName('TRANZAKCIODB').asInteger;
      _fto  := FieldByNAme('FORINTOSSZEG').asInteger;
      _evimax := FieldByName('EVIMAX').asInteger;
      _lastdatum := FieldByName('DATUM').asString;
      _hetift := FieldByNAme('HETIOSSZ').asInteger;
      close;
    end;

  _nevtabla := trim(leftstr(_mbdata,4));
  _ww := length(_mbData);
  _mbs := midstr(_mbdata,5,_ww-4);

  val(_mbs,_mbss,_code);
  if _code<>0 then _mbss := 0;

  if _nevtabla='' then exit;

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

          _lakcim := trim(FieldByNAme('LAKCIM').asString);
          _lakcimcard := trim(FieldByNAme('LAKCIMKARTYA').AsString);
          _allampolg := trim(FieldByNAme('ALLAMPOLGAR').AsString);
          _okmanytipus := trim(FieldByNAme('OKMANYTIP').AsString);
          _azonosito := trim(FieldByNAme('AZONOSITO').AsString);
          _tarthely := trim(FieldByNAme('TARTOZKODASIHELY').AsString);
          _iso := fieldByNAme('ISO').asString;
          _kozszerep := fieldByNAme('KOZSZEREP').asInteger;
          _kulfoldi := FieldByNAme('KULFOLDI').asInteger;
          close;
        end;
    end;
  Remotedbase.close;

  inc(_trdb);
  _fto := _fto + _Fizetendo;
  if _evimax<_Fizetendo then _evimax := _fizetendo;
  _diff := Napidiff(_lastdatum,_megnyitottnap);
  if _diff>7 then _hetift := _fizetendo
  else _hetift := _hetift + _fizetendo;

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
  _pcs := _pcs + inttostr(_fizetendo) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ')';
  RemoteParancs(_pcs);
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
/////////////////////   SEGÉDPROGRAMOK, FUNKCIÓK    ////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
//                      LIMIT BEÁLLITÁS RUTINJAI
// =============================================================================
          procedure TEladasForm.SetLimitGombClick(Sender: TObject);
// =============================================================================

begin
  LimitTakaro.Visible := False;
  GetLimitOsszeg;
end;

// =============================================================================
                     procedure TEladasForm.GetLimitOsszeg;
// =============================================================================

begin
  LimitEdit.clear;
  with LimitBekeroPanel do
    begin
      Top     := 300;
      Left    := 264;
      Visible := True;
    end;

  ActiveControl := LimitEdit;
end;

// =============================================================================
            procedure TEladasForm.LimitEditEnter(Sender: TObject);
// =============================================================================

begin
  LimitEdit.Color := clYellow;
end;

// =============================================================================
               procedure TEladasForm.LimitEditExit(Sender: TObject);
// =============================================================================

begin
  LimitEdit.Color := clWhite;
end;

// =============================================================================
     procedure TEladasForm.LimitEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := LimitOkeGomb;
end;

// =============================================================================
            procedure TEladasForm.LimitOkeGombClick(Sender: TObject);
// =============================================================================

var _limStr: string;

begin
  _limStr := LimitEdit.Text;
  val(_limstr,_limit,_code);
  if _code<>0 then _limit := 0;
  _maradt := _limit;

  LimitBekeroPanel.Visible := False;
  LimitDisplay;
  Activecontrol := wd1;
end;

// =============================================================================
            procedure TEladasForm.LimitMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  VegeTimer.Enabled := False;
  LimitBekeroPanel.Visible := False;
end;

// =============================================================================
                    procedure TeladasForm.LimitDisplay;
// =============================================================================

begin
  if _limit=0 then exit;

  LimitForint.Caption  := ForintForm(_limit)+' Ft';
  _maradt := _limit - _fizetendo;

  if _maradt>=0 then
    begin
      Maradtforint.Font.Color := clBlack;
      Maradtforint.Font.Style := [];
      MaradtForint.Caption := ForintForm(_maradt)+' Ft'
    end else
    begin
      Maradtforint.Font.Color := clRed;
      Maradtforint.Font.Style := [fsBold];
      MaradtForint.Caption := ForintForm(_maradt)+' Ft'
    end;

  LimitForint.Repaint;
  MaradtForint.Repaint;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
              procedure TEladasForm.Alapadatbeolvasas;
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
      _otp             := fieldbyname('OTPOPEN').asInteger;
      _serverAccess    := FieldByName('SERVERACCESS').asInteger;
      _scantype        := FieldByNAme('SCANNER').AsInteger;
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


{
// =============================================================================
                    procedure TEladasForm.KonvadatAtolvasas;
// =============================================================================

begin
   logirorutin(pchar('Konverziós adatok átolvasása'));
   ValutaDbase.Connected := true;
      with ValutaQuery do
        begin
          Close;
          Sql.clear;
          Sql.Add('SELECT * FROM VTEMP');
          Open;

          _fizetendo   := FieldByNAme('FIZETENDO').asInteger;
          _ugyfelSzam  := FieldbyName('UGYFELSZAM').asInteger;
          _ugyfelTipus := FieldbyName('UGYFELTIPUS').AsString;
          _ugyfelNev   := trim(FieldbyName('UGYFELNEV').AsString);
          _nevtabla    := trim(FieldByNAme('NEVTABLA').AsString);
          _sorszam     := FieldByNAme('SORSZAM').asInteger;
          _kulfoldi    := FieldbyName('KULFOLDI').asInteger;
          _kozSzereplo := FieldByname('KOZSZEREPLO').asInteger;
          _adoSzam     := trim(FieldByName('ADOSZAM').AsString);
          _megbizoSzam := FieldbyName('MEGBIZOSZAM').asInteger;
          _tulajDarab  := FieldByName('TULAJDONOS').asInteger;
          CLose;
        end;
     ValutaDbase.close;
     _plombaszam := _nevtabla + inttostr(_sorszam);
     _limit  := _fizetendo;
     _maradt := _limit;
     Limitdisplay;
end;
}


// =============================================================================
                procedure TEladasForm.ValtozokNullazasa;
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
  _limit                      := 0;
  _maradt                     := 0;
  _megbizoSzam                := 0;
  _megbizottSzam              := 0;
  _netto                      := 0;
  _origKezdij                 := 0;
  _rateType                   := 0;
  _tetel                      := 0;
  _ugyfelSzam                 := 0;

  _fizetoEszkoz               := 1;
  _mresult                    := 1;

  _fixkezelesidij             := -1;

  _ezEgyediKezdij             := False;
  _securLevel                 := False;
  _voltshk                    := False;
  _voltkedvezmeny             := False;
end;

// =============================================================================
                    procedure TEladasForm.TombBeToltes;
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
                procedure TEladasForm.TablaNullazas;
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
                    procedure TEladasForm.KezdijTablaBeolvasas;
// =============================================================================

var _srs,_trz,_kzd: integer;

begin
  _pcs := 'SELECT * FROM TRANZDIJTABLA' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      with ValutaQuery do
        begin
          _srs := FieldByName('SORSZAM').asInteger;
          _trz := FieldByName('TRANZAKCIO').asInteger;
          _kzd := FieldByName('KEZELESIDIJ').asInteger;
        end;

      if (_kzd=0) and (_srs>1) then _maxSavDb := _srs-1;

      if (_trz=0) and (_srs>1) and (_srs<24) then
        begin
          ValutaQuery.Next;
          Continue;
        end;

      if _srs<23 then
        begin
          _tranzsav[_srs] := _trz;
          _kdij[_srs] := _kzd;
          ValutaQuery.next;
        end else
        begin
          _kezdijMax := _kzd;
          Break;
        end;
    end;
  ValutaQuery.Close;
  ValutaDbase.Close;
end;

// =============================================================================
             function TEladasForm.GetsajathatasKoru: byte;
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
           function TEladasForm.GetDnemAdatok(_zdnem: string): byte;
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
          _aktearf    := FieldByNAme('ELADASIARFOLYAM').asInteger;
          _aktelszarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
          _aktshk     := FieldByName('SHKVETARFOLYAM').asInteger;
          _aktZaro    := FieldByNAme('ZARO').asInteger;
        end;
    end;
  Valutaquery.close;
  Valutadbase.close;
end;

// =============================================================================
           procedure TEladasForm.SorBeirasVTempbe(_y: byte);
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
      _pcs := _pcs + chr(39) + 'E' + chr(39) + ',';
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

  SetLimitGomb.Visible := False;
end;


// =============================================================================
           function TEladasForm.GetTetelsor(_dn: string): byte;
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
               procedure TEladasForm.VtempDataPotlas;
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
  _pcs := _pcs + ',FIZETENDO=' + inttostr(_fizetendo);
  _pcs := _pcs + ',KEREKITES=' + inttostr(_kerekites);
  _pcs := _pcs + ',OSSZESFORINTERTEK=' + inttostr(_netto);
  _pcs := _pcs + ',FIZETOESZKOZ=1';
  ValutaParancs(_pcs);
end;

// =============================================================================
                 procedure TEladasForm.QRkodLerendezes;
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
  _pcs := _pcs + ',NUMBER=8';
  ValutaParancs(_pcs);
  logirorutin(pchar('Elinditja a QR-kód kijelzõ rutint'));
  qrdisplayrutin;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
/////////////////////  RLGI PROGRAMOK PROCEDURÁK   /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// =============================================================================
                        procedure TEladasForm.MakeXml;
// =============================================================================

var  _pIras: TextFile;
    _ora,_perc,_t: word;

begin
  UgyfdataVtempBol;

  _body := 'Penztar szama: ' + _hpts + _sorveg;
  _body := _body + 'Penztar neve : ' + drophung(_hptnev) + chr(13);

  _body := _body + 'Bizonylatszam: ';

  if _konverzio=1 then _body := _body + _vetbiz +'-';
  _body := _body + _bizonylatszam + chr(13);

  if _konverzio=1 then
    begin
      _eladdnem := _wDnem[1];
      _eladarf  := _wArfolyam[1];
      _eladbjegy:= _wBankjegy[1];

      _body := _body + '       Beadva: '+forintform(_vetbjegy)+' '+_vetdnem;
      _body := _body + ' - ' + inttostr(_vetarf)+' arf-on = '+forintform(_konvertin)+ chr(13);

      _body := _body + '       Kiadva: '+forintform(_eladbjegy)+' '+_eladdnem;
      _body := _body + ' - ' + inttostr(_eladarf)+' arf-on = '+forintform(_konvertout)+ chr(13);

      _body := _body + '   Visszajaro: ' + inttostr(_egyenleg) + ' Ft' + chr(13);

    end else
    begin
      _body := _body + 'Tranz.osszege: ' + inttostr(_fizetendo) + chr(13);
      _t := 1;
      while _t<= _tetel do
        begin
          _body := _body + '  '+inttostr(_t) + '. valuta: ' + forintform(_wBankjegy[_t]);
          _body := _body + ' ' + _wDnem[_t] + chr(13);
          _body := _body + '  '+inttostr(_t) + '. arfoly: ' + inttostr(_warfolyam[_t])+ chr(13);
          _body := _body + '  '+inttostr(_t) + '. ertek : ' + forintform(_wErtek[_t])+' Ft' + chr(13);
          inc(_t);
        end;
    end;

  _body := _body + 'Ugyfel adatai:'+chr(13);
  _body := _body + '       - neve: ' + drophung(_ugyfelnev) + chr(13);
  _body := _body + '      - anyja: ' + drophung(_anyja) + chr(13);
  _body := _body + '   - szul.ido: ' + drophung(_szulido) + chr(13);
  _body := _body + '  - szul.hely: ' + drophung(_szulhely) + chr(13);
  _body := _body + '    - lakcime: ' + drophung(_lakcim) + chr(13);
  _body := _body + '- allampolgar: ' + drophung(_allampolg) + chr(13);
  _body := _body + '- tart-i hely: ' + drophung(_tarthely) + chr(13);
  _body := _body + '- okmany tip.: ' + drophung(_okmanytipus) + chr(13);
  _body := _body + ' - okm. szama: ' + _azonosito + chr(13);
  _body := _body + '- engedelyezo: ' + drophung(_engedelyezo) + chr(13);

  _ora := Hourof(Time);
  _perc := Minuteof(Time);

  _remoteFile := 'E' + trim(_hpts) + nulele(_ora,2)+nulele(_perc,2)+'.xml';
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

  AssignFile(_pIras,'c:\valuta\'+_remotefile);
  rewrite(_pIras);
  write(_piras,_mailstring);
  closefile(_piras);

end;

procedure TEladasForm.KILEPTimer(Sender: TObject);
begin
  Kilep.Enabled := False;
  Modalresult := _mResult;
end;

procedure TEladasForm.KonvDataVtempbe;

begin
  _pcs := 'UPDATE VTEMP SET KONVERZIO=1,UGYFELTIPUS='+chr(39)+_ugyfeltipus+chr(39);
  _pcs := _pcs + ',UGYFELSZAM='+inttostr(_ugyfelszam);
  _pcs := _pcs + ',UGYFELCIM='+chr(39)+ _ugyfelcim + chr(39)+',NEVTABLA=';
  _pcs := _pcs + chr(39)+_nevtabla+chr(39)+',SORSZAM='+inttostr(_sorszam);
  _pcs := _pcs + ',SECURLEVEL='+inttostr(_secur);

  ValutaParancs(_pcs);
end;

end.
