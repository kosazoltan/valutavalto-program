unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, Grids, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg, ComCtrls,
  printers, wininet;

type
  TAtadAtvetForm = class(TForm)
    Alaplap            : TPanel;
    AllAtadGomb        : TPanel;
    AllAtvetGomb       : TPanel;
    AllGetBackPanel    : TPanel;
    AllGiveBackPanel   : TPanel;
    APanel             : TPanel;
    AtadasFocimPanel   : TPanel;
    AtadasPanel        : TPanel;
    AtvetGomb          : TPanel;
    AtvetelPanel       : TPanel;
    AtadGomb           : TPanel;
    BackGomb           : TPanel;
    BackParaFocim      : TPanel;
    CimletFelirat      : TPanel;
    CimletFuggony      : TPanel;
    DevAtadGomb        : TPanel;
    DevAtvetGomb       : TPanel;
    EkerGomb           : TPanel;
    ForintPanel        : TPanel;
    FtFocimPanel       : TPanel;
    FtPanel            : TPanel;
    InfoPanel          : TPanel;
    KellCimletPanel    : TPanel;
    KezdijGomb         : TPanel;
    MenuAlapPanel      : TPanel;
    MenuPanel          : TPanel;
    Munkalec           : TPanel;
    Panel2             : TPanel;
    Panel3             : TPanel;
    Panel7             : TPanel;
    ProcessPanel       : TPanel;
    RacsPanel          : TPanel;

    HatterKep          : TImage;
    Image3             : TImage;

    Shape1             : TShape;
    Shape2             : TShape;
    Shape3             : TShape;
    Shape5             : TShape;
    Shape6             : TShape;
    Shape7             : TShape;

    BackPtarEdit       : TEdit;
    BackBizonyEdit     : TEdit;
    BackDatumEdit      : TEdit;
    BackFtBizonyEdit   : TEdit;
    GetDateEdit        : TEdit;
    GetBlokkEdit       : TEdit;
    GetFtBlokkEdit     : TEdit;
    HideEdit           : TEdit;
    Label1             : TLabel;
    Label2             : TLabel;
    Label3             : TLabel;
    Label4             : TLabel;
    Label5             : TLabel;
    Label6             : TLabel;
    Label7             : TLabel;
    Label8             : TLabel;
    Label9             : TLabel;
    Label10            : TLabel;
    Label11            : TLabel;
    Label12            : TLabel;
    Label13            : TLabel;
    Label14            : TLabel;
    Label15            : TLabel;

    FtOkeGomb          : TBitBtn;
    FtMegsemGomb       : TBitBtn;
    GetDataBackOkeGomb : TBitBtn;
    GetDataMegsemGomb  : TBitBtn;
    IgenGomb           : TBitBtn;
    KCimGomb           : TBitBtn;
    NemGomb            : TBitBtn;
    NoKcimGomb         : TBitBtn;
    GiveDataBackOkeGomb: TBitBtn;
    ParaMegsemGomb     : TBitBtn;
    TranzOkeGomb       : TBitBtn;
    TranzStornoGomb    : TBitBtn;

    AtadAtvetSource    : TDataSource;

    TempTabla          : TIBTable;
    TempQuery          : TIBQuery;
    TempDbase          : TIBDatabase;
    TempTranz          : TIBTransaction;

    TradeQuery         : TibQuery;
    TradeDbase         : TibDatabase;
    TradeTranz         : TibTransaction;

    ValdataQuery       : TIBQuery;
    ValdataDbase       : TIBDatabase;
    ValdataTranz       : TIBTransaction;

    ValutaQuery        : TIBQuery;
    ValutaDbase        : TIBDatabase;
    ValutaTranz        : TIBTransaction;

    VegRacs            : TStringGrid;
    SENDKUNAPANEL: TPanel;

    procedure AlapadatBeolvasas;
    procedure Alapnullazas;
    procedure AllAfaAtad;
    procedure AllAtadGombClick(Sender: TObject);
    procedure AllAtvetGombClick(Sender: TObject);
    procedure AllDevTombbe;
    procedure AllEkerAtad;
    procedure AllKezdijAtad;
    procedure AllMetroAfaAtad;
    procedure AllValutaTotFileBa;
    procedure AllWesternatad;
    procedure AtadGombClick(Sender: TObject);
    procedure AtvetGombClick(Sender: TObject);
    procedure B1Click(Sender: TObject);
    procedure B1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BackBizonyEditKeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
    procedure BackDatumEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BackFtBizonyEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BackGombClick(Sender: TObject);
    procedure BackPtarEditEnter(Sender: TObject);
    procedure BackPtarEditExit(Sender: TObject);
    procedure BackPtarEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BlokkFejIras;
    procedure BlokkTetelIras;
    procedure CimletBedolgozas;
    procedure CImletKijelolo(_ct: byte);
    procedure CimletNyomtatas;
    procedure CImletTombbe;
    procedure Dec1Click(Sender: TObject);
    procedure DevAtadGombClick(Sender: TObject);
    procedure DevAtvetGombClick(Sender: TObject);
    procedure DisappearPanels;
    procedure Dnemkod(_vn: string);
    procedure EgyebPenzatvetel;
    procedure EgyebPenzekKonyvelese;
    procedure EgytetelFeliras;
    procedure EkerGombClick(Sender: TObject);
    procedure EkerAtvetel;
    procedure ElszamBeolvasas;
    procedure ErtektarAllAtvetel;
    procedure EverythingTake;
    procedure ExitGombClick(Sender: TObject);
    procedure Fejleciro;
    procedure Fejteteltorles;
    procedure ForintGroupen;
    procedure FormActivate(Sender: TObject);
    procedure FtpSzerverreLep;
    procedure GeTBlokkEditKeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
    procedure GetFtBlokkEditKeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
    procedure GetDataBackOkeGombClick(Sender: TObject);
    procedure GetDataMegsemGombClick(Sender: TObject);
    procedure GetDateEditKeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
    procedure GiveDataBackOkeGombClick(Sender: TObject);
    procedure GroupenProgram;
    procedure FileKiiro(_fPath: string);
    procedure Integkod(_ertek: integer);
    procedure KeszletVisszaAdas;
    procedure Kezdijatvetel;
    procedure KezdijGombClick(Sender: TObject);
    procedure KozepreIr(_szoveg: string);
    procedure KozosAdvet;
    procedure MenuBe;
    procedure MetroBizonylat;
 
    procedure ParaMegsemGombClick(Sender: TObject);
    procedure PenztarAllAtvetel;
    procedure PenztarBeolvasas;
    procedure PiszkozatBeolvasas;
    procedure PlombaAdatBeolvasas;
    procedure ProcessDisplay;
    procedure TescoBizonylat;
    procedure TradeBizonylat;
    procedure TradeParancs(_ukaz: string);
    procedure TranzakcioKonyveles;
  
    procedure ValutaParancs(_ukaz: string);
    procedure Vonalhuzo;
    procedure WesternAtvetel;
    procedure Wordkod(_w: word);
    procedure WuBizonylatnyomtatas;
    procedure WURekord;

    function ByteDekod: byte;
    function DnemDekod:string;
    function Elokieg(_s: string;_h: byte):string;
    function ForintForm(_sm:integer):string;
    function Fourdisp(_s: string):string;
    function Getbizonylat: string;
    function Getidos: string;
    function IntegDekod: integer;
    function KeszletControl: boolean;
    function Kerekito(_int: integer): integer;
    function Negyes(_n: integer): string;
    function Nulele(_i: integer;_h: word):string;
    function RealToStr(_r: real):string;
    function RemdirCtrlAndSend(_remDir: string): boolean;
    function ScanDnem(_dn: string): byte;
    function TizenEgy(_b: integer): string;
    function TotalFileBeOlvasas: boolean;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    function WordDekod: word;
    procedure SENDKUNAPANELClick(Sender: TObject);

  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  AtadAtvetForm: TAtadAtvetForm;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY','CZK',
         'DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD','PLN','RON',
         'RSD','RUB','SEK','THB','TRY','UAH','USD');

  _dnev: array[1..27] of string = ('Ausztral dollar','Bosnyak marka','Bolgar leva',
         'Brazil real','Kanadai dollar','Svajci frank','Kinai juan','Cseh korona',
         'Dan korona','Euro','Angol font','Horvat kuna','Magyar forint','Izraeli shakel',
         'Japan jen','Mexikoi peso','Norveg korona','Ujzelandi dollar',
         'Lengyel zloty','Roman lei','Szerb dinar','Orosz rubel','Sved korona',
         'Thai bath','Torok lira','Ukran hrivnya','Usa dollar');

  _cimletstring: array[1..14] of string = ('20.000','10.000','5.000','2.000',
          '1.000','500','200','100','50','20','10','5','2','1');

  _cimletertek: array[1..14] of word = (20000,10000,5000,2000,1000,500,200,100,
           50,20,10,5,2,1);

  _cimletdarab: array[1..27] of byte = (5,5,7,7,5,6,7,6,5,9,4,7,12,4,4,5,5,5,5,7,
           9,7,7,9,7,9,7);

  _cimletsor: array[1..27] of string = ('89ABC','789AB','89ABCDE','89ABCDE',
           '89ABC','5789AB','89ABCDE','345678','56789','6789ABCDE','9ABC',
           '56789AB','123456789ABC','789A','2345','6789A','56789','89ABC',
           '789AB','6789BCE','3456789AB','34568BC','56789AB','5689ABCDE',
           '1789ABC','6789ABCDE','89ABCDE');

  _devizaDarab : byte;  // ennyi valuta vesz részt a tranzakcióban (1..26)
  _devizasor: array[1..27] of byte;    // a kiválasztott valuták sorszámai
  _devizasum,_devizaertek: array[1..27] of integer; // bankjegy és érték
  _alaparfolyam: array[1..27] of integer;
  _arftortresz: array[1..27] of string;
  _arfsum: array[1..27] of integer;
  _bjegystr,_arfestr,_decstr: array[1..27] of string;

  _devizaCimletBankjegy: array[1..27,1..14] of word; // A selected devizák
                                              // hasznos cimleteinek darabszáma

  _vanDevCimlet: array[1..27] of boolean;
  _vd: array[1..27] of TPanel;  // A valutanemek téglái
  _vflag: array[1..27] of byte; // valutanem-flag: 0 = noselected,
                                //                 1 = selected,
                                //                 2 = tiltva

  _nv,_bj,_af,_dec: array[1..27] of TPanel; // A selected valuták 2 oszlopa: név,bankjegy

  // A selected valuták formázatlan számstring-jeinek tárolója:

  _cimletListaPath: string = 'c:\valuta\cimlprnt.txt';
  _LPath: string = 'c:\valuta\aktlst.txt';

  _elszarf,_cdnem,_zaro: array[1..27] of integer;
  _precarf: array[1..27] of real;

  _bytetomb: array[1..2048] of byte;

  _sorveg: string = chr(13)+chr(10);

  _aktPanel: TPanel;
  _aktedit : Tedit;
  _aktprecarf: real;

  // A cimlet kitöltö tábla oszlopainak tömbjei:

  _cs,_ss: array[1..14] of TPanel;
  _ce: array[1..14] of TEdit;
  _dp: array[1..27] of Tlabel;

  _LCimsor: array[1..14] of byte;
  _sert,_hufcim: array[1..14] of integer;

  _cType: array[1..8] of byte;

  _otherdb: array[1..8] of byte;
  _otherkesz: array[1..8,1..2] of integer;
  _otherdnem: array[1..8,1..2] of string;

  _wideon : char = #14;
  _wideoff: char = #20;

  _irany: byte;  // 1= átvétel  2= átadás


  _binolvas,_biniras: File of byte;
  _nyomtat,_olvas,_LFile: TextFile;
  _sourcePath: string;

  _akttegla: TPanel;
  _pacs: pchar;

  _tag,_uttag,_devsorindex,_dnemindex,_aktcimletdarab,_cimletss,_ctag,_m: byte;
  _cimletindex,_aktDnemIndex,_xx,_tetel,_cimletezve,_printer,_hufindex: byte;
  _penztarszam,_kellmatrica,_kellmetroafa,_kelltescoafa,_kellwestern: byte;
  _cimlettype,_aktdb: byte;

  _dType,_megnyitottnap,_aktdnem,_aktText,_nums,_zaszloPath: string;
  _aktcimletsor,_tarsPenztarKod,_tarsPenztarNev,_munkacim,_pcs: string;
  _szallitonev,_plombaszam,_megjegyzes,_bizonylatszam,_ttema: string;
  _aktdnev,_tipus,_aktidos,_aktprosnev,_aktidkod,_trbpenztarkod: string;
  _mondat,_numeditText,_das,_remoteFile,_bizelokod,_precarfs: string;
  _penztarkod,_penztarnev,_penztarcim,_totalfilenev,_totaldir: string;
  _backPtar,_backbizony,_backDatum,_otip,_farok,_bttabla: string;
  _kerfilenev,_kerdir,_totalpath,_backFtBizony,_totPath: string;
  _allfogdnem,_KFTNEV,_CEGNEV,_tortresz,_elojel,_akttortresz: string;
  _recnums,_zcounts: string;

  _ptoke,_aktnum,_code,_bankjegy,_sorertek,_sumertek,_aktsumertek,_aktbj: integer;
  _aktsorertek,_aktertek,_plombOke,_bizertek,_aktkesz,_wuosszeg,_totalhossz: integer;
  _ujblokknum,_aktelszarf,_ujblokkszam,_ftnum,_recno,_cOke,_utblokk: integer;
  _forintkeszlet,_aktbankjegy,_hufkeszlet,_aktarfolyam,_spk,_aktkezdij: integer;
  _allkezdij,_allwuusd,_allwuhuf,_allafa,_allfoglalo,_alleker: integer;
  _kezdij,_utbe,_nyugoke,_vankeszlet: integer;

  _NUMBER : BYTE;
  _kkheight,_dnemss,_ertektar,_pp,_bytess: word;
  _top,_left,_width,_height,_gepfunkcio,_index,_aktcimletertek,_ix: word;
  _noSelect,_aktvancimlet,_firstkey,_maycomma: boolean;

  _hFTP,_hNet,_hSearch: HINTERNET;
  _FINDDATA : WIN32_FIND_DATA;
  _ftpPassword : string  = 'klc+45%';
  _host        : string; 
  _userId      : String  = 'ebc-10%';
  _ftpPort     : Integer = 21100;

  _pPath: string;
  _bennvan,_siker,_noregen,_vanfuggony,_ezvissza: boolean;

  // Aktadvetmenu: 0= ft kiadás, 1=dev kiadas,2=ftatvet, 3=devatvet,4=mat.ptár

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\valuta\bin\bloknyom.dll' name 'blokknyomtatas';
function kezdijatadorutin: integer; stdcall; external 'c:\valuta\bin\kezdij.dll' name 'kezdijatadorutin';
function matpenztarrutin: integer; stdcall; external 'c:\valuta\bin\matptar.dll' name 'matpenztarrutin';
function penztarrutin: integer; stdcall; external 'c:\valuta\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\valuta\bin\getplomb.dll' name 'getplombarutin';
function cimletctrlrutin: integer; stdcall; external 'c:\valuta\bin\cimlctrl.dll' name 'cimletctrlrutin';
function cimletezorutin: integer; stdcall; external 'c:\valuta\bin\cimlet.dll' name 'cimletezorutin';
function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll' name 'regeneralorutin';
function matricaregeneralo: integer; stdcall; external 'c:\valuta\bin\Matregen.dll' name 'matricaregeneralo';
function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\qrgener.dll' name 'qrdisplayrutin';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';

function atadatvetrutin: integer; stdcall;
function keszleteditalorutin(_para: byte): integer; stdcall; external 'c:\valuta\bin\keszedit.dll';
function hrkbekuldorutin: integer; stdcall; external 'c:\valuta\bin\hrksend.dll';


implementation

{$R *.dfm}


// =============================================================================
             function atadatvetrutin: integer; stdcall;
// =============================================================================

begin
  AtadAtvetForm := TAtadAtvetForm.Create(Nil);
  result := atadatvetform.showmodal;
  atadatvetform.free;
end;


// =============================================================================
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
//
//                     PROGRAM INDULÁSI FELADATAI:
//                       - képernyõ beállítása
//                       - tömbök összeállitása
//                       - alapadatok beolvasása
//                       - alapadatok alapra állitása (nullázása)
//
//  UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// =============================================================================
              procedure TATADATVETFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top    := 0;
  _left   := 0;

  if _width>1024 then _left := trunc((_width-1024)/2);
  if _height>768 then _top := trunc((_height-768)/2);

  Top     := _top;
  left    := _left;
  Height  := 768;
  Width   := 1024;
  Visible := True;

  _ezvissza            := False;
  ProcessPanel.Visible := False;
  RacsPanel.Visible    := False;
  AtadasPanel.Visible  := False;
  AtvetelPanel.Visible := False;
  _noregen := False;
  _maycomma:= False;
  Hatterkep.repaint;

  AlapadatBeolvasas;
  AlapNullazas;

  logirorutin(pchar('============================='));
  logirorutin(pchar('Indul az átadás-átvétel rutin'));

  Menube;
end;

// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// UU                                                                         UU
// UU                    PÉNZ ÁTVÉTEL EGY TÁRSPÉNZTÁRTÓL                      UU
// UU                                                                         UU
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// =============================================================================
          procedure TATADATVETFORM.ATVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  // A gépfunkciótól függõen átirjuk a az alsó menügomb fekiratát:

  logirorutin(pchar('Pénz átvétele'));

  _irany := 1;
  if _gepfunkcio=2 then
    begin
      devatvetGomb.Caption := 'Pénz átvétele egy pénztártól vagy banktól';
      Allatvetgomb.Caption := 'Teljes készlet átvétele egy pénztártól';
    end else
    begin
      Devatvetgomb.caption := 'Pénz átvétele az értéktártól';
      AllatvetGomb.caption := 'Teljes készlet visszavétele az értéktártól';
    end;

  with AtvetelPanel do
    begin
      top     := 245;
      left    := 232;
      Visible := True;
    end;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                   DEVIZA ÁTVÉTELE EGY TÁRSPÉNZTÁRTÓL                       //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
          procedure TATADATVETFORM.DEVATVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  _irany  := 1;
  _dtype := 'DEV';

  logirorutin(pchar('Deviza átvétele'));

  KozosAdvet;
end;


// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// UU                                                                         UU
// UU                     PÉNZ ÁTADÁS EGY TÁRSPÉNZTÁRNAK                      UU
// UU                                                                         UU
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// =============================================================================
             procedure TATADATVETFORM.ATADGOMBClick(Sender: TObject);
// =============================================================================


begin

   logirorutin(pchar('Pénz átadása'));
   _irany := 2;

  // A gépfunkciótól függöen felülirja a gombok feliratát:

  if _gepfunkcio=2 then
    begin
      DevatadGomb.Caption := 'Pénz elküldése egy pénztárnak vagy banknak';
      AllatadGomb.Caption := 'Teljes készlet visszaküldése egy pénztárnak';
    end else
    begin
      DevatadGomb.Caption := 'Pénz beküldése az értéktárba';
      AllatadGomb.Caption := 'Teljes készlet beküldése az értéktárba';
    end;

  with AtadasPanel do
    begin
      top     := 245;
      left    := 232;
      Visible := True;
    end;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                     DEVIZA ÁTADÁSA EGY TÁRSPÉNZTÁRNAK                      //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
          procedure TATADATVETFORM.DEVATADGOMBClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Deviza átadása'));
  _irany  := 2;
  _dtype := 'DEV';
  Kozosadvet;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             A PÉNZ ÁTADÁSOK ÉS ÁTVÉTELEK KÖZÖS RUTINJA                     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                     procedure TAtadatvetform.KozosAdvet;
// =============================================================================



begin

  // Képernyõ tisztára törlése:

  Menupanel.Visible     := False;
  MenuAlapPanel.Visible := False;
  AtadasPanel.Visible   := False;
  AtvetelPanel.Visible  := False;

  // A társpénztár 2 adatának beolvasása:

  logirorutin(pchar('Kijelöli a társpénztárt'));

  _ptOke := penztarrutin;
  if _ptOke<>1 then
    begin
      Modalresult := 2;
      exit;
    end;

  Hatterkep.repaint;
  PenztarBeolvasas;

  Sleep(500);

  if (_tarspenztarkod='TH') OR (_tarspenztarkod='1') then
    begin
       logirorutin(pchar('TH vagy Fõpénztár esetén kéri a jelszót'));
       _spk := supervisorjelszo(0);
       if _spk<>1 then
         begin
           logirorutin(pchar('Nem tudta'));
           Modalresult := 2;
           exit;
         end;
    end;

  logirorutin(pchar('Most bekéri a tranzakció tételeit a keszlet-editálóval'));
  _vankeszlet := keszleteditalorutin(_irany);


  if _vankeszlet=2 then
    begin
      logirorutin(pchar('A készlet editáló nem adott adatot-> vége'));
      Menube;
      exit;
    end;

  PiszkozatBeolvasas;

  if not KeszletControl then
    begin
      logirorutin(pchar('Nincs ennyi készletünk'));
      Modalresult := 2;
      exit;
    end;

  logirorutin(pchar('Van ennyi készlet. Most bekéri a szállitót és plombát'));

   // Bekéri a szállitó nevét és a plombaszámot:

  _plombOke := getplombarutin;
  if _plomboke<>1 then
    begin

      // Ha nem sikerült a plomba beplvasás -> storno az egész tranzakció
      logirorutin(pchar('Nem sikerült beolvasni a szállítót'));
      Modalresult := 2;
      exit;
    end;
  logirorutin(pchar('Beolvassa a szállítót és plombát'));
  PlombaadatBeolvasas;

  logirorutin(pchar('Most következik a tranzakció könyvelése'));
  TranzakcioKonyveles;

  logirorutin(pchar('Kilép az átadás-átvétel rutinból'));
  Modalresult := 1;
end;


// uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
// uu                            KÖNYVELÉS - NYOMTATÁS                        uu
// uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                Egy átadás-átvétel tranzakció lekönyvelésa                  //
//
//  Szükséges paraméterek: _dType= ('FT' vagy 'DEV')  forint/deviza
//                         _irany = (1 vagy 2)     bevétel/kiadás
//                         _devizadarab: ennyi valuta tranzakciója
//                         _devizasor[1..devizadarab]: a valuták sorszáma
//                         _devizasum[1..devizadarab]: a valuták összege
//                         _tarspenztarkod, tarspenztarnev
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
         procedure TAtadAtvetForm.TranzakcioKonyveles;
// =============================================================================

var _fttipus: string;


begin
  _bizonylatszam := GetBizonylat;
  _tipus := leftstr(_bizonylatszam,1);

  logirorutin(pchar('A bizonylatszám: '+chr(39)+_bizonylatszam+chr(39)));


  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  logirorutin(pchar('Indul a blokktétel irása'));
  BlokktetelIras;

  logirorutin(pchar('Blokkfejiras indul'));
  BlokkfejIras;

  logirorutin(pchar('A QR paraméterek beállítása'));

  IF _TIPUS='U' then _number := 5 else _number := 6;

  _pcs := 'UPDATE QRPARAMS SET NUMBER=' + inttostr(_number);
  _pcs := _pcs + ',BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  ValutaParancs(_pcs);

  ProcessPanel.Visible := false;

  // ---------- QRDISPLAY KOD KIJELEZES (PAY_IN - PAY_OUT) ---------------------

  logirorutin(pchar('Kijelzi a qr-kódot'));
  qrdisplayrutin;

  logirorutin(pchar('Kinyomtatja a blokkot'));
  blokknyomtatas(1);

  CimletNyomtatas;
  _fttipus := midstr(_bizonylatszam,2,1);
  if (_fttipus='F') OR (_penztarszam>150) then
    begin
      logirorutin(pchar('Forint-blokknál vagy zálognál a második nyomtatás'));
      blokknyomtatas(11);
      Cimletnyomtatas;
    end;

  _cimletezve := 0;
  if _noregen=False then regeneralorutin(0);

end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Átadás - átvétel blokk fejlécének felirása                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 procedure TatadAtvetForm.BlokkFejIras;
// =============================================================================

begin

  _aktidos := GetIdos;
  _bizertek := kerekito(_bizertek);

  _pcs := 'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,KEZELESIDIJ,';
  _pcs := _pcs + 'FIZETENDO,FIZETOESZKOZ,OSSZESFORINTERTEK,TETEL,IDKOD,';
  _pcs := _pcs + 'PENZTAROSNEV,TARSPENZTARKOD,MEGBIZOSZAM,MEGBIZOTT,';
  _pcs := _pcs + 'PLOMBASZAM,SZALLITONEV,STORNO,TRBPENZTAR)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + '0,' + inttostr(_bizertek) + ',1,';
  _pcs := _pcs + inttostr(_bizertek) + ',';
  _pcs := _pcs + inttostr(_tetel) + ',';
  _pcs := _pcs + chr(39) + _aktidkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktprosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ',0,0,';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',1,';
  _pcs := _pcs + chr(39) + _trbpenztarkod + chr(39) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE VTEMP SET BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  _pcs := _pcs + ',TIPUS=' + chr(39)+_tipus+chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _megnyitottnap + chr(39);
  _pcs := _pcs + ',IDO=' + chr(39) + leftstr(_aktidos,5) + chr(39);
  _pcs := _pcs + ',FIZETENDO=' + inttostr(_bizertek);
  _pcs := _pcs + ',FIZETOESZKOZ=1';
  _pcs := _pcs + ',OSSZESFORINTERTEK=' + inttostr(_bizertek);
  _pcs := _pcs + ',TETEL=' + inttostr(_tetel);
  _pcs := _pcs + ',IDKOD=' + chr(39) + _aktidkod + chr(39);
  _pcs := _pcs + ',PENZTAROSNEV=' + chr(39) + _aktprosnev + chr(39);
  _pcs := _pcs + ',PENZTARKOD=' + chr(39)+ _tarspenztarkod + chr(39);
  _pcs := _pcs + ',TARSPENZTARNEV=' + CHR(39)+_tarspenztarnev + chr(39);
  _pcs := _pcs + ',PLOMBASZAM=' + CHR(39) + _plombaszam + chr(39);
  _pcs := _pcs + ',SZALLITONEV=' + chr(39) + _szallitonev + chr(39);
  _pcs := _pcs + ',STORNO=1';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET ' + _ttema + '=' + inttostr(_ujblokknum);
  ValutaParancs(_pcs);
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Átadás - átvétel összes tételeinek felirása                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                    procedure TAtadAtvetForm.Blokkteteliras;
// =============================================================================

begin

  _tetel := 0;
  _bizertek := 0;
  while _tetel<_devizadarab do
    begin
      inc(_tetel);

      _bankjegy  := _devizasum[_tetel];
      _dnemindex := _devizasor[_tetel];
      _aktdnem   := _dnem[_dnemindex];

      _xx := scandnem(_aktdnem);

      _aktelszarf := _alaparfolyam[_tetel];
      _tortresz   := trim(_arftortresz[_tetel]);
      _aktdnev    := _dnev[_xx];
      _aktertek   := _devizaErtek[_tetel];
      _bizertek   := _bizertek + _aktertek;


      EgyTetelFeliras;
    end;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Átadás - átvétel egy tételének felirása                      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                procedure TatadAtvetForm.EgytetelFeliras;
// =============================================================================

begin
  _elojel := '+';
  if _irany=2 then _elojel := '-';

  _pcs := 'INSERT INTO BLOKKTETEL (DATUM,BIZONYLATSZAM,VALUTANEM,ELOJEL,';
  _pcs := _pcs + 'ARFOLYAM,ELSZAMOLASIARFOLYAM,BANKJEGY,FORINTERTEK,';
  _pcs := _pcs + 'COIN,STORNO,TORTRESZ)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39)+',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktelszarf) + ',';
  _pcs := _pcs + inttostr(_aktelszarf) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + inttostr(_aktertek) + ',0,1,';
  _pcs := _pcs + chr(39) + _tortresz + chr(39)+')';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (VALUTANEM,VALUTANEV,ARFOLYAM,ELSZAMOLASIARFOLYAM,';
  _pcs := _pcs + 'ELOJEL,BANKJEGY,FORINTERTEK,TORTRESZ)' +  _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnev + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktelszarf) + ',';
  _pcs := _pcs + inttostr(_aktelszarf) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + inttostr(_aktertek) + ',';
  _pcs := _pcs + chr(39) + _tortresz + chr(39)+')';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (VALUTANEM,BANKJEGY)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_aktdnem+chr(39)+',';
  _pcs := _pcs + inttostr(_Bankjegy) + ')';
  ValutaParancs(_pcs);


end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Ha van - akkor kinyomtatja a cimlet(ek)et                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   procedure TatadAtvetform.CimletNyomtatas;
// =============================================================================

begin
  if not Fileexists(_cimletListaPath) then exit;
  logirorutin(pchar('Kiirja a cimleteket'));
  FileKiiro(_cimletlistaPath);
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                          Az fpath file  kinyomtatása
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                procedure TAtadAtvetForm.FileKiiro(_fPath: string);
// =============================================================================

begin

  if _printer<>1 then AssignFile(_nyomtat,'LPT1:')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);

  AssignFile(_olvas,_fpath);
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

// =============================================================================
                procedure TAtadAtVetForm.PiszkozatBeolvasas;
// =============================================================================

var _firstval: string;

begin
  logirorutin(pchar('Beolvassa a cimletpiszkozatot'));

  valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM CIMLETPISZKOZAT');
      Open;
      First;
      _firstval := FieldByName('VALUTANEM').asstring;
    end;

  _dType := 'DEV';
  if _firstval='HUF' then _dType := 'FT';

  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.FieldByName('VALUTANEM').asstring;
      _aktbankjegy := ValutaQuery.FieldByName('BANKJEGY').asInteger;
      _aktertek := ValutaQuery.FieldByNAme('OSSZESFORINTERTEK').asInteger;
      _aktarfolyam := Valutaquery.FieldByName('ARFOLYAM').asInteger;
      _akttortresz := trim(ValutaQuery.fieldbyname('TORTRESZ').asstring);

      if _aktbankjegy=0 then
        begin
          ValutaQuery.next;
          Continue;
        end;

      inc(_devizadarab);

      _xx := scandnem(_aktdnem);

      _devizasor[_devizadarab] := _xx;
      _devizasum[_devizadarab] := _aktbankjegy;
      _alaparfolyam[_devizadarab] := _aktarfolyam;
      _arftortresz[_devizadarab] := _akttortresz;
      _devizaertek[_devizadarab] := _aktertek;

      if _dtype='FT' then break;

      valutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
  logirorutin(pchar('Beolvasott '+inttostr(_devizadarab)+' valutasort'));
end;


// QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ
// =============================================================================
//                        TELJES KÉSZLETEK MOZGÁSAI
// QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ
// =============================================================================

// =============================================================================
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// UU                                                                         UU
// UU  A TELJES KÉSZLET ÁTADÁSA AZ ÉRTÉKTÁRNAK  VAGY VISSZA EGY PÉNZTÁRNAK    UU
// UU                                                                         UU
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// =============================================================================
           procedure TAtadAtvetForm.AllAtadGombClick(Sender: TObject);
// =============================================================================

var i: byte;

begin
  if _gepfunkcio=2 then
    begin
      KeszletVisszaAdas;
      exit;
    end;

  // Egy pénztár átadja a teljes készletét az értéktárnak:

  for i := 1 to 8 do _ctype[i] := 0;

  _cimletType := 1;
  while _cimletType<=8 do
    begin
      if _cimlettype=7 then _cimlettype := 8;
      CimletKijelolo(_cimlettype);
      _coke := cimletctrlrutin;
      if _coke=1 then
        begin
          _ctype[_cimlettype] := 1;
          inc(_cimlettype);
          continue;
        end;

      if _coke=3 then
         begin
           inc(_cimlettype);
           continue;
         end;

      if _coke=2 then
        begin
          _coke := cimletezorutin;
          IF _coke=2 then
            begin
              ShowMessage('HIBÁS CIMLETEZÉS');
              mODALRESULT := 2;
              exit;
            end;
         end;
       inc(_cimlettype);
     end;

  _aktidos := timetostr(TIME);
  if midstr(_aktidos,2,1)=':' then _aktidos := '0' + _aktidos;

  // szerverre másolja a TOTTRANZ könyvtárba
  // a 'E10','E20', ... 'E120','E145' alkönyvtárba
  // Fmmdd. + _penztarkod néven

  // regisztrál blokfej,blokktetel ls Vtemp adatbázisokba
  // kinyomtatja a bizonylatot

  _das := midstr(_megnyitottnap,6,2)+midstr(_megnyitottnap,9,2);
  _dtype := 'DEV';
  _irany  := 2;

  _totalFilenev := 'F' + _das + '.' + _penztarkod;
  AllValutaTotFileBa;

  // A Cimini.1 file-t ráküldi a szerver TOTALDIR könyvtárába
  // a TOTALFILENEV néven:

  _siker := RemdirCtrlAndSend('E' + inttostr(_ertektar));

  _tarspenztarkod  := inttostr(_ertektar);
  _tarspenztarnev  := 'Értéktár';

  AtadasFocimPanel.Caption := 'ÖSSZES PÉNZ ÁTADÁSA AZ ÉRTÉKTÁRNAK';
  AtadasFocimPanel.Repaint;

  if _siker then
    begin
      AllDevTombbe;

      _tipus         := 'F';
      _trbpenztarkod := '';

      _plombOke := getplombarutin;
     if _plomboke<>1 then
       begin
         Modalresult := 2;
         exit;
       end;

     disappearPanels;
     PlombaAdatBeolvasas;
     AtadasPanel.Visible := False;
     Menupanel.Visible   := False;
     Processdisplay;

     _noregen := true;

     CimletTombbe;
     TranzakcioKonyveles;
     _devizadarab  := 1;
     _cdnem[1]     := 1;
     _devizasor[1] := _hufindex;
     _devizasum[1] := _forintkeszlet;
     _devizaertek[1]:= _forintKeszlet;
     _precarf[1] := 100.00;
     _dType := 'FT';

     _cimletezve := 1;
     for i := 1 to 14 do _devizacimletbankjegy[1,i] := _hufcim[i];
     _precarf[1] := 100;
     _alaparfolyam[1] := 100;
     TranzakcioKonyveles;

     _pcs := 'DELETE FROM CIMLETEK';
     ValutaParancs(_pcs);

     _pcs := 'INSERT INTO CIMLETEK (DATUM,VALUTANEM,OSSZESFORINTERTEK)'+_SORVEG;
     _pcs := _pcs + 'VALUES (' + chr(39)+_megnyitottnap+chr(39) + ',';
     _pcs := _pcs + chr(39) + 'HUF' + chr(39) + ',0)';
     ValutaParancs(_pcs);
    end;

  EverythingTake;

  ProcessPanel.Visible := false;
  regeneralorutin(0);
  if _kellmatrica=1 then matricaregeneralo;
  Modalresult := 1;
end;
































////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Egy TotalFile beolvasása a szerverrõl                     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
              function TAtadAtvetForm.TotalFileBeOlvasas: boolean;
// =============================================================================

begin
  result := False;

  FTPSzerverrelep;
  if _hFTP=Nil then exit;

  // --------- Change directory -----------------

  _siker :=  FTPSetCurrentDirectory(_hFTP,pchar(_totalDir));
  if not _siker then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  _hSearch := FTPFindFirstFile(_hFTP,pchar(_TotalFilenev),_findData,0,0);
  if _hsearch=NIL then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      showmessage('A PÉNZTÁR MÉG NEM KÜLDTE BE A KÉSZLETET');
      exit;
    end;

  InternetCloseHandle(_hsearch);

  _totalPath := 'C:\VALUTA\' + _totalFilenev;
  result := ftpgetfile(_hftp,pchar(_TotalFilenev),pchar(_totalPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);

  ftpdeletefile(_hFTP,pchar(_totalfilenev));

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                Belépés a szervere                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 procedure Tatadatvetform.FtpSzerverrelep;
// =============================================================================

begin

  _hFTP := Nil;
  _hNET := InternetOpen('serverre',INTERNET_OPEN_TYPE_PRECONFIG,Nil,Nil,0);
  if _hNET=NIL then exit;

  _hFTP := INTERNETCONNECT(_hNet,pchar(_host),_ftpPort,pchar(_userID),
                             pchar(_ftpPassword),INTERNET_SERVICE_FTP,
                                             INTERNET_FLAG_PASSIVE,0);

end;


procedure TATADATVETFORM.EXITGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;


procedure TAtadAtvetForm.Fejteteltorles;

begin
  _pcs := 'DELETE FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'DELETE FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  ValutaParancs(_pcs);
end;


// ========================= cimletezés ========================================


procedure TatadAtvetForm.ProcessDisplay;

begin
  with ProcessPanel do
    begin
      top := 400;
      left := 310;
      Visible := true;
      Repaint;
    end;
end;


function TatadAtvetForm.realtostr(_r: real):string;

var _rs: string;
    _pos,_w1: byte;

begin
  _rs := floattostr(_r);
  result := _rs;
  _w1 := length(_rs);
  _pos := pos(',',_rs);
  if _pos>0 then
    result := leftstr(_rs,_pos-1)+'.'+midstr(_rs,_pos+1,_w1-_pos);
end;


// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//       Elöröl kiegésziti 0-kkal a stringet, mig _H hosszú nem lesz          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// ============================================================================
         function TAtadAtvetform.Elokieg(_s: string;_h: byte):string;
// ============================================================================

begin
  result := _s;
  while length(result)<_h do  result := ' '+result;
end;

// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                      39 karakter hosszu vonalat nyomtat                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 procedure TatadatvetForm.VonalHuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',39));
end;

// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Formázva kinyomtat egy négyjegyü számot                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
               function TAtadAtvetForm.negyes(_n: integer): string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<4 do result := ' '+result;
end;

// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Formázva kinyomtat egy tizenegyjegyü számot               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
             function TAtadAtvetForm.Tizenegy(_b: integer): string;
// =============================================================================

var _r: string;
    _w1,_p1: byte;

begin
  _r := inttostr(_b);
  _w1 := length(_r);
  if _b>999999 then
    begin
      _p1 := _w1-6;
      _r := leftstr(_r,_p1)+'.'+midstr(_r,_p1+1,3)+'.'+midstr(_r,_p1+4,3);
    end else
    begin
      if _b>999 then
         begin
            _p1 := _w1-3;
            _r := leftstr(_r,_p1)+'.'+midstr(_r,_p1+1,3);
          end;
    end;
  _w1 := length(_r);
  while _w1<11 do
    begin
      _r := ' '+_r;
      _w1 := length(_r);
    end;

  result := _r;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Átadás - átvétel  bizonylatszám meghatározása                //
//         _irany (1 vagy 2) és _dType ('DEV' vagy 'FT') alapján           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 function TatadAtvetForm.Getbizonylat: string;
// =============================================================================

begin
  valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
    end;

  if _irany=1 then
    begin
      if _dType='DEV' then
        begin
          _ttema := 'UTOLSOATVETELBLOKK';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>999999 then _ujblokknum := 1;
          result := 'U' + _bizelokod + nulele(_ujblokknum,6);
        end else
        begin
          _ttema := 'UTOLSOFORINTATVETELBLOKK';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>99999 then _ujblokknum := 1;
          result := 'UF' + _bizelokod + nulele(_ujblokknum,5);
        end;
    end else
    begin
      if _dType='DEV' then
        begin
          _ttema := 'UTOLSOATADASBLOKK';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>999999 then _ujblokknum := 1;
          result := 'F' + _bizelokod + nulele(_ujblokknum,6);
        end else
        begin
          _ttema := 'UTOLSOFORINTATADASBLOKK';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>99999 then _ujblokknum := 1;
          result := 'FF' + _bizelokod + nulele(_ujblokknum,5);
        end;
     end;
  Valutaquery.close;
  Valutadbase.close;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         Az összes valuta elszámolási árfolyamát tömbbe olvassa             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                    procedure TatadAtvetForm.ElszamBeolvasas;
// =============================================================================

var _aktelszarf: integer;

begin
  _pcs := 'SELECT * FROM ARFOLYAM ORDER BY VALUTANEM';

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      _aktdnem := trim(Valutaquery.fieldByName('VALUTANEM').asstring);
      _aktelszarf := Valutaquery.FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      _xx := Scandnem(_aktdnem);
      IF _XX>0 THEN
        begin
          _elszarf[_xx] := _aktelszarf;
          _zaro[_xx] := ValutaQuery.FieldByName('ZARO').asInteger;
        end;
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
//                           SEGÉD - PROGRAMOK
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                   Végrehajt egy Firebird parancsot                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
             procedure TatadatvetForm.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  if _ukaz='' then exit;

  valutadbase.connected := true;
  if ValutaTranz.intransaction then ValutaTranz.commit;
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
  _pcs := '';
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Egy word beolvasása a bytetombböl                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                function TAtadAtvetForm.WordDekod: word;
// =============================================================================

var _lo,_hi: byte;

begin
  _lo := _bytetomb[_bytess];
  _hi := _bytetomb[_bytess+1];
  _bytess := _bytess+2;
  result := _lo + trunc(_hi*256);
end;


// =============================================================================
                function TAtadAtvetForm.ByteDekod: byte;
// =============================================================================

begin
   result := _bytetomb[_bytess];
   inc(_bytess);
end;



// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Egy integer beolvasása a bytetombböl                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
              function TAtadAtvetForm.IntegDekod: integer;
// =============================================================================

var _lo,_hi,_hlo,_hhi: byte;

begin
  _lo := _bytetomb[_bytess];
  _hi := _bytetomb[_bytess+1];
  _hlo:= _bytetomb[_bytess+2];
  _hhi:= _bytetomb[_bytess+3];

  _bytess := _bytess + 4;

  result := _lo+trunc(256*_hi)+trunc(65536*_hlo)+trunc(256*65536*_hhi);
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Egy devizanem-string beolvasása a bytetombböl                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
           function TAtadAtvetForm.DnemDekod:string;
// =============================================================================

var _a1,_a2,_x1,_x2,_x3: integer;

begin
  _a1 := ord(_bytetomb[_bytess]);    //  2
  _a2 := ord(_bytetomb[_bytess+1]);    //  131

  _x1 := trunc(_a1/4);
  _x2 := trunc((_a1 and 3) * 8) + trunc(_a2/32);
  _x3 := (_a2 and 31);

  _bytess := _bytess+2;
  result := chr(_x1+65)+chr(_x2+65)+chr(_x3+65);
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                      Megállapitja a pontos idõt                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                  function TatadatvetForm.Getidos: string;
// =============================================================================

begin
  result := timetostr(Time);
  if ord(result[2])= 58 then result := '0' + result;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                    Megállapitja egy valuta sorszámát:                      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
            function TatadatvetForm.Scandnem(_dn: string): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=27 do
    begin
      if _dNem[_y] = _dn then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                 Egy numbet-format ### ### ### alakra                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
             function TAtadAtvetForm.ForintForm(_sm:integer):string;
// =============================================================================

var _slen,_pp: integer;

begin
  Result := '-';

  if _sm=0 then exit;
  Result := intTostr(_sm);

  if _sm<1000 then exit;

  _sLen := length(Result);
  if _sm>999999 then
    begin
      _pp := _sLen-5;
      Result := midStr(Result,1,_pp-1)+' '+midStr(Result,_pp,3)+' '+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := midStr(result,1,_pp-1)+' '+midStr(result,_pp,3);
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//      A VTemp-bõl beolvassa tarspenztarkod és tarspenztarnev változókat     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                    procedure TAtadAtvetForm.PenztarBeolvasas;
// =============================================================================

begin
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _tarspenztarKod := trim(FieldbyName('PENZTARKOD').AsString);
      _tarspenztarnev := trim(FieldByNAme('TARSPENZTARNEV').AsString);
      _trbpenztarkod  := trim(FieldByName('TRBPENZTAR').asString);
      Close;
    end;
  Valutadbase.close;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         A VTemp-bõl beolvassa szallitonev és plombaszam változókat         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
              procedure TAtadAtvetForm.PlombaAdatBeolvasas;
// =============================================================================

begin
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _szallitonev := trim(FieldbyNAme('SZALLITONEV').asString);
      _plombaszam := trim(FieldByNAme('PLOMBASZAM').asString);
      _megjegyzes := trim(FieldbyNAme('MEGJEGYZES').asString);
      Close;
    end;
  ValutaDbase.close;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                Egy szaámstring elé _h darab nullát ir                      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
          function TatadatvetForm.Nulele(_i: integer;_h: word):string;
// =============================================================================

begin
  result := inttostr(_i);
  while length(result)<_h do result := '0' + result;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
// A dll nélkülözhetetlen alapadainak beolvasása HARDWARE-böl és PENZTAR-ból  **
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 procedure TAtadAtvetform.AlapadatBeolvasas;
// =============================================================================

begin

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;

      _gepfunkcio    := FieldByName('GEPFUNKCIO').asInteger;
      _printer       := FieldByNAme('PRINTER').asInteger;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      _aktidkod      := trim(FieldByName('IDKOD').AsString);
      _aktprosnev    := trim(FieldByNAme('PENZTAROSNEV').asString);
      _ertektar      := FieldbyNAme('ERTEKTAR').asInteger;
      _kellMatrica   := FieldByNAme('KELLMATRICA').asInteger;
      _kellWestern   := FieldByNAme('KELLWESTERN').asInteger;
      _kelltescoafa  := FieldByName('KELLTESCOAFA').asInteger;
      _kellmetroafa  := FieldByNAme('KELLMETROAFA').asInteger;
      _kftnev        := trim(FieldbyName('KFTNEV').asstring);
      _host          := trim(FieldByName('HOST').AsString);
      Close;

      Sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod  := trim(FieldByNAme('PENZTARKOD').asstring);
      _penztarnev  := trim(FieldbyNAme('PENZTARNEV').AsString);
      _penztarcim  := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;

  ValutaDbase.Close;

  val(_penztarkod,_penztarszam,_code);
  if _code<>0 then _penztarszam := 0;

  _bizelokod := nulele(_penztarszam,3);
  if _penztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;

  if (_penztarszam<>154) then
    begin
      ekergomb.Enabled := false;
      ekergomb.Color := clSilver;
    end;  


  ElszamBeolvasas;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//               Az alapadatok biztonsági okból való nullára állitása
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                    procedure TatadAtvetForm.AlapNullazas;
// =============================================================================


begin
  _noselect    := False;
  _devizaDarab := 0;       // nincs egyetlen deviza sem kijelölve

 
  _hufIndex := Scandnem('HUF');
 
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//
//       A KÉPERNYÕN CSAK A MENÜPANEL LÁTSZIK AZ ÖSSZES TÖBBI NEM
//
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                       procedure Tatadatvetform.Menube;
// =============================================================================

begin
 

  ProcessPanel.Visible   := False;
  AtadasPanel.Visible    := False;
  AtvetelPanel.Visible   := False;

  with MenuAlapPanel do
    begin
      Top := 220;
      Left := 224;
      Visible := true;
    end;

  with Menupanel do
    begin
      Top := 310;
      Left := 344;
      Visible := true;
    end;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  KILÉPÉS A DLL-BÕL - VISSZA A VALUTAPROGRAMHOZ             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
             procedure TATADATVETFORM.BACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;


// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             ELEKTROMOS KERESKEDES PÉNZÁTADÁS-PÉNZÁTVÉTEL                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
           procedure TATADATVETFORM.EKERGOMBClick(Sender: TObject);
// =============================================================================

begin
  DisappearPanels;
  matpenztarrutin;
  menube;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                    KEZELÉSI DIJAK ÁTVÉTELE ÁTADÁSA                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
            procedure TATADATVETFORM.KEZDIJGOMBClick(Sender: TObject);
// =============================================================================

begin
  DisappearPanels;
  kezdijatadorutin;
  Menube;
end;

// =============================================================================
             procedure TAtadAtvetForm.SENDKUNAPANELClick(Sender: TObject);
// =============================================================================

begin
  DisappearPanels;
  hrkbekuldorutin;
  Menube;
end;



// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// AZ ÖSSZES DEVIZA BEOLVASÁSA AZ ARFOLYAM TÁBLÁBÓL ÉS DEVIZATÖMBBE TÖLTÉSE   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
               procedure TatadAtvetForm.AllDevTombbe;
// =============================================================================


begin
  _devizaDarab := 0;

  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs  + 'WHERE ZARO>0' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';


  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      _aktdnem     := ValutaQuery.FieldByName('VALUTANEM').asString;
      _aktbankjegy := Valutaquery.FieldbyName('ZARO').asInteger;
      _aktelszarf  := ValutaQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;

      if _aktdnem='HUF' then
        begin
          _forintKeszlet := _aktbankjegy;
          Valutaquery.next;
          Continue;
        end;

      _xx := scandnem(_aktdnem);
      inc(_devizadarab);
      _devizasum[_devizadarab] := _aktbankjegy;
      _devizasor[_devizadarab] := _xx;
      _elszarf[_xx] := _aktelszarf;
      _alaparfolyam[_devizadarab] := _aktelszarf;
     // _precarf[_devizadarab] := 1*_elszarf[_xx];
      _aktertek := round(_aktbankjegy/100*_aktelszarf);
      _devizaertek[_devizadarab] := _aktertek;

      ValutaQuery.next;
    end;

  ValutaQuery.Close;
  Valutadbase.close;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//       Bemásolja a sterverren a _totaldir-be (ha kell létrehozza) a         //
//                 Cimini.1 file-t _totalfilenev néven-                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
      function TAtadAtvetForm.RemdirCtrlAndSend(_remDir: string): boolean;
// =============================================================================

begin
  result := False;
  FtpSzerverreLep;
  if _hFTP=Nil  then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  _totalDir := 'TOTTRANZ\' + _remDir;
  _bennVan   :=  FTPSETCURRENTDIRECTORY(_hFTP,pchar(_totalDir));

  if not _bennvan then
     begin
       FtpCreateDirectory(_hFTP,pchar(_totaldir));
       _bennVan :=  FTPSETCURRENTDIRECTORY(_hFTP,pchar(_totaldir));
     end;

  if not _bennvan then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

   if fileExists(_sourcePath) then
       result := FTPPutFile(_hFTP,pchar(_sourcePath),pchar(_totalFileNev),FTP_TRANSFER_TYPE_BINARY,0);

   InternetCloseHandle(_hFTP);
   InternetCloseHandle(_hNet);
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Egy értéktár visszaadja  elözöleg átvett teljes készletet egy péntrárnak  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
              procedure TatadAtvetForm.KeszletvisszaAdas;
//==============================================================================

begin
  AtadasPanel.Visible   := False;
  menuAlappanel.Visible := False;
  menupanel.Visible     := False;

  BackPtarEdit.clear;
  BackBizonyEdit.clear;
  BackFtBizonyEdit.clear;
  BackDatumedit.clear;

  with AllGiveBackPanel do
    begin
      top     := 260;
      left    := 250;
      Visible := true;
    end;
  Activecontrol := BackPtarEdit;
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         A KÉSZLET VISSZAADÁS PARAMÉTER EDITJEI KERÜLNEK A FOKÚSZBA         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
       procedure TATADATVETFORM.BACKPTAREDITEnter(Sender: TObject);
//==============================================================================

begin
  Tedit(sender).Color := clYellow;
end;


//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         A KÉSZLET VISSZAADÁS PARAMÉTER EDITJEI ELVESZTIK A FOKÚSZAIT       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
          procedure TATADATVETFORM.BACKPTAREDITExit(Sender: TObject);
//==============================================================================

begin
  Tedit(sender).Color := clWhite;
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         A KÉSZLET VISSZAADÁS TÁRSPÉNTÁRSZÁM-EDITBEN ENTERT ADOTT           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
        procedure TATADATVETFORM.BACKPTAREDITKeyDown(Sender: TObject;
                        var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := BackBizonyedit;
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         A KÉSZLET VISSZAADÁS BIZONYLATSZÁM-EDIT ENTERT ADOTT               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
        procedure TATADATVETFORM.BACKBIZONYEDITKeyDown(Sender: TObject;
                   var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := BackfTbIZONYEdit;
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         A KÉSZLET VISSZAADÁS FTBIZONYLATSZÁM-EDIT ENTERT ADOTT             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
      procedure TATADATVETFORM.BACKFTBIZONYEDITKeyDown(Sender: TObject;
                       var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  IF ord(KEY)<>13 then exit;
  Activecontrol := BackDatumEdit;
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                 A KÉSZLET VISSZAADÁS DÁTUM-EDIT ENTERT ADOTT               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
        procedure TATADATVETFORM.BACKDATUMEDITKeyDown(Sender: TObject;
                     var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := giveDataBackOkeGomb;
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//      A KÉSZLET VISSZAADÁS PARAMÉTER EDITÁLÁSAKOR MÉGSEM GOMBOT NYOMOTT     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
         procedure TATADATVETFORM.PARAMEGSEMGOMBClick(Sender: TObject);
//==============================================================================

begin
  Modalresult := 1;
end;

//==============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//   KÉSZLET VISSZAADÁS PARAMÉTER EDITÁLÁSAKOR ADATOK RENDBEN GOMBOT NYOMOTT  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
         procedure TATADATVETFORM.GIVEDATABACKOKEGOMBClick(Sender: TObject);
//==============================================================================

var _w: byte;

begin
  // A Back-para panelen levõ editek kiértékelése:
  // A pénztár, ahova az átvett készleteket vissza kell adni:

  _tarspenztarkod := trim(BackPtaredit.Text);
  if _tarspenztarkod='' then
    begin
      Activecontrol := BackPtaredit;
      exit;
    end;

  //  A bizonylat amin a készletek érkeztek az értéktárba:

  _backbizony := 'U' + trim(BackBizonyEdit.Text);
  if _backbizony='' then
    begin
      Activecontrol := BackBizonyEdit;
      exit;
    end;

  _w := length(_backbizony);
  if _w<>10 then
    begin
      Backbizonyedit.Clear;
      Activecontrol := BackBizonyEdit;
      exit;
    end;

  // A bizonylatszám, amin a FT készlet érkezett a pénztárból:

  _backFtBizony := 'UF' + trim(Backftbizonyedit.Text);
  if length(_backftBizony)<>10 then
    begin
      BackFtBizonyEdit.clear;
      ActiveControl := BackFtBizonyEdit;
      exit;
    end;

  // A dátum, amikor a pénztár teljes készlete érkezett az értéktárba:

  _backDatum := trim(BackDatumEdit.Text);
  if _backDatum='' then
    begin
      Activecontrol := BackDatumEdit;
      exit;
    end;

  // A paraméter panel eltünik:
  AllGiveBackPanel.Visible := false;

  // A back-dátum alapján képzi a farkat, majd a tételtábla nevét:

  _farok   := midstr(_backdatum,3,2)+midstr(_backdatum,6,2);
  _btTabla := 'BT' + _farok;

  // Megnyitja a régebbi bizonylatot, amelyen a devizák érkeztek:

  _pcs := 'SELECT * FROM ' + _btTabla + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_backBizony+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  valdatadbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin

      ShowMessage('ÉRVÉNYTELEN BIZONYLATSZÁM: (' + _backbizony +')');
      ValdataQuery.close;
      Valdatadbase.close;
      Modalresult := 2;
      exit;
    end;

  // A számla tételeit a devizatömbökbe irja:

  _devizadarab := 0;
  while not ValdataQuery.Eof do
    begin
      _aktdnem     := ValdataQuery.FieldbyName('VALUTANEM').asstring;
      _aktbankjegy := ValdataQuery.FieldbyName('BANKJEGY').asInteger;
      _aktertek    := ValdataQuery.FieldByName('FORINTERTEK').asInteger;
      _aktarfolyam := ValdataQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      _xx := scandnem(_aktdnem);

      inc(_devizadarab);

      _devizasor[_devizadarab] := _xx;
      _devizasum[_devizadarab] := _aktbankjegy;
      _devizaertek[_devizadarab] := _aktertek;
      _alaparfolyam[_devizadarab]:= _aktarfolyam;
      _arftortresz[_devizadarab] := '';
      ValdataQuery.next;
    end;

  ValdataQuery.close;
  Valdatadbase.close;
  _dType := 'DEV';
  _irany  := 2;

  _munkacim := 'TELJES VALUTAKÉSZLET VISSZAADÁSA EGY PÉNZTÁRNAK';
  _noregen := true;
  _ezvissza := true;
 // groupenProgram;
   TranzakcioKonyveles;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM ' + _btTabla + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_backFtBizony+chr(39);

  valdatadbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _recno := _recno;
    end;

  if _recno=0 then
    begin
      ShowMessage('ÉRVÉNYTELEN A FORINT BIZONYLATSZÁM: (' + _backFtbizony +')');
      ValdataQuery.close;
      Valdatadbase.close;
      Modalresult := 2;
      exit;
    end;

  _aktbankjegy := ValDataQuery.FieldbyName('BANKJEGY').asInteger;
  ValdataQuery.close;
  ValdataDbase.close;

  _dType := 'FT';
  _bizonylatszam := Getbizonylat;

  _devizadarab     := 1;
  _devizasor[1]    := _hufindex;
  _devizasum[1]    := _aktbankjegy;
  _devizaertek[1]  := _aktbankjegy;
  _alaparfolyam[1] := 100;
  _arftortresz[1]  := '';
  _bizertek := _aktbankjegy;

  _noregen := False;
  TranzakcioKonyveles;
  Menube;
end;



// TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// UU                      TELJES KÉSZLET ÁTVÉTELE                            UU
// UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
// =============================================================================
              procedure TATADATVETFORM.ALLATVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  IF _gepfunkcio=2 then ErtekTarAllAtvetel
  else PenztarAllAtvetel;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Teljes valutakészlet átvétele egy pénztártól                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 procedure TatadAtvetForm.ErtektarAllAtvetel;
// =============================================================================

var _honapfarok: string;
    _vss,_cimss: byte;
    _cimdb: integer;

begin
  _plombaszam     := '';
  _szallitonev    := '';
  _trbpenztarkod  := '';
  _tipus          := 'U';

  // Elöször kiválasztjuk a pénztárat, ahonnan átvesszük a teljes készletet:

  _ptOke := penztarrutin;
   if _ptOke<>1 then
    begin
      Modalresult := 2;
      exit;
    end;

   DisappearPanels;
   ProcessDisplay;

  // A Vtemp-bõl beolvassa _tarspenztarkod és _tarspenztarnev adatokat

  PenztarBeolvasas;

  // A totál pénzkészlet értékei a szerveren a '\TOTTRANZ\E' + ertektars'
  // könyvtárban kell lennie a megfelelö Totalfile-nak:
  // A file neve = >> 'F' + mmdd + '.' + _tarspénztárkod  <<

  _honapfarok := midstr(_megnyitottnap,6,2)+midstr(_megnyitottnap,9,2);

  _TotalFileNev := 'F' + _honapfarok + '.' + _tarspenztarkod;
  _Totaldir := '\TOTTRANZ\E' + _penztarkod;

  // A szerverrõl beolvassa a TotalFile-t:

  if not TotalFileBeolvasas then
    begin
      processPanel.Visible := false;
      Modalresult := 2;  // nem sikerült !!
      exit;
    end;

  // Kiüriti a cimletpiszkozat táblát - ide tölti a pénztár teljes készletét

  _pcs := 'DELETE FROM CIMLETPISZKOZAT';
  ValutaParancs(_pcs);

  // Megnyitja a letöltött totalfile-t

  Assignfile(_binolvas,_totalpath);
  reset(_binolvas);
  _totalhossz := filesize(_binolvas);


  // Kiolvassa, hogy hány deviza lett átadva:

  blockread(_binolvas,_bytetomb,_totalhossz);
  Closefile(_binolvas);

  Sysutils.DeleteFile(_totalpath);

  _bytess := 1;
  _devizadarab := Bytedekod;
  _vss := 1;
  while _vss<=_devizadarab do
    begin
      _aktdnem := dnemDekod;
      _aktkesz := integdekod;
      _xx      := scandnem(_aktdnem);
      _cimss   := 1;

      _pcs := 'INSERT INTO CIMLETPISZKOZAT (VALUTANEM,VALUTANEV,OSSZESFORINTERTEK,';
      _pcs := _pcs + 'CIMLET1,CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,CIMLET7,';
      _pcs := _pcs + 'CIMLET8,CIMLET9,CIMLET10,CIMLET11,CIMLET12,CIMLET13,';
      _pcs := _pcs + 'CIMLET14)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _aktdnem +chr(39)+',';
      _pcs := _pcs + chr(39) + _dnev[_xx] + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktkesz);

      while _cimss<=14 do
        begin
          _cimdb := worddekod;
          _pcs := _pcs +','+ inttostr(_cimdb);
          inc(_cimss);
        end;
      _pcs := _pcs + ')';

      // Az aktuális deviza rekordját feltölti a Cimletpiszkozat táblába:

      ValutaParancs(_pcs);

      // Jühet a következõ deviza:

      inc(_vss);
    end;

  egyebPenzAtvetel;

  // ----------- A cimletpiszkozatban benne az átvett cimletezés ---------------

  // Paraméterek: deviza és bevétel:

  _dtype := 'DEV';
  _irany  := 1;

  _pcs := 'SELECT * FROM CIMLETPISZKOZAT' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  TempDbase.Connected := True;
  with TempQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _devizaDarab := 0;

  while not TempQuery.Eof do
    begin
      _aktdnem := TempQuery.FieldbyName('VALUTANEM').asstring;
      _aktbankjegy := Tempquery.FieldbyName('OSSZESFORINTERTEK').asInteger;

      if _aktdnem='HUF' then
        begin
          _forintKeszlet := _aktbankjegy;
          TempQuery.Next;
          Continue;
        end;

      _xx := scanDnem(_aktDnem);
      inc(_devizadaraB);

      _devizasor[_devizadarab] := _xx;
      _devizasum[_devizadarab] := _aktbankjegy;
      _aktarfolyam := _elszarf[_xx];
      _alaparfolyam[_devizadarab] := _aktarfolyam;
      _arftortresz[_devizadarab] := '';
      _aktertek := round(_aktbankjegy/100*_aktarfolyam);
      _devizaertek[_devizadarab] := _aktertek;
      TempQuery.next;
    end;

  TempQuery.close;
  TempDbase.close;

  ProcessPanel.Visible := False;

  _noregen := true;
  TranzakcioKonyveles;

  _devizadarab  := 1;
  _devizasor[1] := _hufindex;
  _devizasum[1] := _forintkeszlet;
  _alaparfolyam[1] := 100;
  _devizaertek[1] := _forintkeszlet;
  _arftortresz[1] := '';

  _dType := 'FT';
  TranzakcioKonyveles;

  EgyebPenzekkonyvelese;
  regeneralorutin(0);
  if _kellmatrica=1 then matricaregeneralo;
  Modalresult := 1;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         EGY PÉNZTÁR VISSZAVESZI AZ TELJES KÉSZLETET AZ ÉRTÉKTÁRTÓL         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                procedure TatadAtvetForm.PenztarAllAtvetel;
// =============================================================================

begin

  DisAppearPanels;
  GetDateEdit.clear;
  GetBlokkEdit.clear;
  GetFtBlokkEdit.clear;

  with AllGetBackPanel do
    begin
      top     := 260;
      left    := 250;
      Visible := true;
    end;
  Activecontrol := GetDateEdit;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//       A VISSZAVÉTEL PARAMÉTERBEKÉRÉSÉNÉL A DÁTUMRA ENTERT NYOMOTT          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
   procedure TATADATVETFORM.GETDATEEDITKeyDown(Sender: TObject; var Key: Word;
                         Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := GetBlokkedit;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//    A VISSZAVÉTEL PARAMÉTERBEKÉRÉSÉNÉL A BIZONYLATSZÁMRA ENTERT NYOMOTT     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
       procedure TATADATVETFORM.GETBLOKKEDITKeyDown(Sender: TObject;
                       var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := GetFtBlokkedit;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// A VISSZAVÉTEL PARAMÉTERBEKÉRÉSÉNÉL A FORINTBIZONYLATSZÁMRA ENTERT NYOMOTT  //        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
        procedure TATADATVETFORM.GETFTBLOKKEDITKeyDown(Sender: TObject;
                          var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := GetDataBackOkeGomb;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//       A VISSZAVÉTEL PARAMÉTERBEKÉRÉSÉNÉL A MÉGSEM GOMBOT NYOMTA            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
       procedure TATADATVETFORM.GETDATAMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  AllGetBackPanel.Visible := False;
  Modalresult := 2;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//       A VISSZAVÉTEL PARAMÉTERBEKÉRÉSÉNÉL AU OKE GOMBOT NYOMTA              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
        procedure TATADATVETFORM.GETDATABACKOKEGOMBClick(Sender: TObject);
// =============================================================================

var _w: byte;

begin
  _backDatum := trim(GetDateEdit.Text);
  if _backDatum='' then
    begin
      Activecontrol := GetDateEdit;
      exit;
    end;

   //  A bizonylat amin a készletek érkeztek az értéktárba:
  _backbizony := 'F' + trim(GetBlokkEdit.Text);
  if _backbizony='' then
    begin
      Activecontrol := GetBlokkEdit;
      exit;
    end;

  _w := length(_backbizony);
  if _w<>10 then
    begin
      Backbizonyedit.Clear;
      Activecontrol := GetBlokkEdit;
      exit;
    end;

  _backFtBizony := 'FF' + trim(GetFtBlokkEdit.Text);
  if length(_backftBizony)<>10 then
    begin
      BackFtBizonyEdit.clear;
      ActiveControl := GetFtBlokkEdit;
      exit;
    end;

  _farok := midstr(_backdatum,3,2)+midstr(_backdatum,6,2);
  _btTabla := 'BT' + _farok;

  _pcs := 'SELECT * FROM ' + _btTabla + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+ _backbizony + chr(39);

  AllGetBackPanel.Visible := false;
  Valdatadbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      ValdataDbase.close;
      Showmessage('HIBÁS A VALUTAÁTADÁS BIZONYLATSZÁMA');
      Modalresult := 2;
      exit;
    end;

  _devizadarab := 0;
  while not ValdataQuery.eof do
    begin
      _aktdnem := Valdataquery.fieldbyname('VALUTANEM').AsString;
      _aktbankjegy := ValdataQuery.FieldByName('BANKJEGY').asInteger;

      {
      if _aktdnem='HUF' then
        begin
          _forintkeszlet := _aktbankjegy;
          ValdataQuery.next;
          continue;
        end;
      }

      inc(_devizadarab);
      _xx := scandnem(_aktdnem);
      _devizasor[_devizadarab] := _xx;
      _devizasum[_devizadarab] := _aktbankjegy;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;

  _dType := 'DEV';
  _irany  := 1;
  _bizonylatszam := Getbizonylat;
   _plombOke := getplombarutin;
  if _plomboke<>1 then
    begin

      // Ha nem sikerült a plomba beplvasás -> storno az egész tranzakció
      Modalresult := 2;
      exit;
    end;

  // A plombaadatok beolvasása a VTEMP adatbázisból:

  disappearPanels;
  PlombaAdatBeolvasas;
  _noregen := true;
  TranzakcioKonyveles;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM ' + _btTabla + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+ _backFtbizony + chr(39);

  AllGetBackPanel.Visible := false;
  Valdatadbase.Connected := true;

  with ValdataQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _forintkeszlet := ValdataQuery.FieldByName('BANKJEGY').asInteger;
      Close;
    end;

  ValdataDbase.close;

  _devizadarab  := 1;
  _devizasor[1] := _hufindex;
  _devizasum[1] := _forintkeszlet;

  _dType := 'FT';
  _noregen := False;

  TranzakcioKonyveles;
  Modalresult := 1;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                 AZ ÖSSZES PANELT ELTÜNTETI A KÉPERNYÕRÕL                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                procedure TAtadAtvetForm.DisappearPanels;
// =============================================================================


// Minden panelt eltüntet

begin
  Menupanel.visible := False;
  MenuAlapPanel.Visible := False;
 
  AtadasPanel.visible := False;
  AtvetelPanel.visible := False;
  RacsPanel.Visible := false;
  Munkalec.Visible := False;
  Hatterkep.Repaint;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                     A CIMLET-TABLA ADATAIT TÖMBÖKBE TÖLTI                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                    procedure Tatadatvetform.CImletTombbe;
// =============================================================================

var
    _mezo: string;

begin
  _pcs := 'SELECT * FROM CIMLETEK' + _SORVEG;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cimletezve := 0;
  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.FieldByName('VALUTANEM').asString;
      if _aktdnem='HUF' then
        begin
          _m := 1;
          while _m<=14 do
            begin
              _mezo := 'cimlet' + inttostr(_m);
              _hufcim[_m] := ValutaQuery.FieldByName(_mezo).asInteger;
              inc(_m);
            end;
          ValutaQuery.next;
          Continue;
        end;
      inc(_cimletezve);
      _xx := scandnem(_aktdnem);
      _cdnem[_cimletezve] := _cimletezve;


      _m := 1;
      while _m<=14 do
        begin
          _mezo := 'cimlet' + inttostr(_m);
          _devizaCimletBankjegy[_cimletezve,_m] := ValutaQuery.FieldByName(_mezo).asInteger;
          inc(_m);
        end;
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  ValutaDbase.close;
end;



// =============================================================================
            function TatadAtvetForm.Keszletcontrol: boolean;
// =============================================================================

// Kiadásnál ellenörzi, hogy van-e annyi devizánk, amennyit kiakarunk adbi

var _y: byte;
    _aktsum : integer;
    _aktdss : word;

begin
  result := True;

  if _devizadarab=0 then exit;
  if _irany=1 then exit;

  _y := 1;
  while _y<=_devizadarab do
    begin
      _aktsum := _devizasum[_y];
      _aktdss := _devizasor[_y];
      if  _aktsum>_zaro[_aktdss] then
        begin
          ShowMessage('NINCS ENNYI '+ _dnem[_aktdss] + ' KÉSZLETÜNK');
          result := false;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
 function TatadatvetForm.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
// =============================================================================

var Msg: TMsg;
    lpExitCode: cardinal;
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;

begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
    begin
      cb := SizeOf(TStartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
      wShowWindow := visibility; {you could pass sw_show or sw_hide as parameter}
    end;

  if CreateProcess(nil, path, nil, nil, False, NORMAL_PRIORITY_CLASS,
                                      nil, nil, StartupInfo,ProcessInfo) then

    begin
      repeat
        while PeekMessage(Msg, 0, 0, 0, pm_Remove) do
          begin
            if Msg.Message = wm_Quit then Halt(Msg.WParam);
            TranslateMessage(Msg);
            DispatchMessage(Msg);
          end;

        GetExitCodeProcess(ProcessInfo.hProcess,lpExitCode);
      until lpExitCode <> Still_Active;

    with ProcessInfo do {not sure this is necessary but seen in in some code elsewhere}
      begin
        CloseHandle(hThread);
        CloseHandle(hProcess);
      end;

    Result := 0; {success}
  end else Result := GetLastError;
end;


// =============================================================================
           function TAtadAtvetForm.kerekito(_int: integer): integer;
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
             procedure TatadAtvetForm.AllValutaTotFileBa;
// =============================================================================

var _vdb,_y: byte;
    _mezo: string;
    _aktc: word;

begin
  _pcs := 'SELECT * FROM CIMINI' + _sorveg;
  _pcs := _pcs + 'WHERE (CIMLETTYPE=1) AND (AKTKESZLET>0)' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _pp := 2;
  _vdb := 0;
  while not Valutaquery.eof do
    begin
      _aktdnem := Valutaquery.FieldByName('VALUTANEM').asString;
      _aktkesz := Valutaquery.FieldByNAme('CIMLETEZETT').asInteger;

      dnemkod(_aktdnem);
      integkod(_aktkesz);

      _y := 1;
      while _y<=14 do
        begin
          _mezo := 'CIMLET'+inttostr(_y);
          _aktc := Valutaquery.FieldByName(_mezo).asInteger;
          wordkod(_aktc);
          inc(_y);
        end;
      inc(_vdb);
      ValutaQuery.next;
    end;

  Valutaquery.Close;
  Valutadbase.close;
  _bytetomb[1] := _vdb;

  // ---------------------------------------------------------------------------
  //
  // Itt a többi pénzlészletet kell regisztrálni:
  //

   _allkezdij := 0;
   _allwuusd  := 0;
   _allwuhuf  := 0;
   _allafa    := 0;
   _allfoglalo:= 0;
   _alleker   := 0;
   _allfogdnem:= '';

  _cimlettype :=2;
  while _cimlettype<=8  do
    begin
      if _cimlettype=7 then _cimlettype := 8;
      if _ctype[_cimlettype]=0 then
        begin
          inc(_cimlettype);
          continue;
        end;
      CimletBedolgozas;
      inc(_cimlettype);
    end;

 // ----------------------------------------------------------------------------
  _bytetomb[_pp] := 255;
  inc(_pp);
  _bytetomb[_pp] := 255;

  _sourcepath := 'c:\valuta\' + _totalFileNev;

  AssignFile(_biniras,_sourcepath);
  rewrite(_biniras);
  Blockwrite(_biniras,_bytetomb,_pp);
  Closefile(_biniras);
end;

// =============================================================================
                  procedure TatadAtvetForm.cimletbedolgozas;
// =============================================================================

var _v: array[1..4] of string;
    _k: array[1..4] of integer;
    _db,_y: byte;


begin
  _pcs := 'SELECT * FROM CIMINI' + _sorveg;
  _pcs := _pcs + 'WHERE (CIMLETTYPE=' + inttostr(_cimlettype)+')';
  _pcs := _pcs + ' AND (AKTKESZLET>0)' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _db := 0;
  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.FieldByName('VALUTANEM').asString;
      _aktkesz := ValutaQuery.FieldByName('AKTKESZLET').asInteger;

      inc(_db);
      _v[_db] := _aktdnem;
      _k[_db] := _aktkesz;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  if _db=0 then exit;

  if _cimletType=2 then _allkezdij := _aktkesz;
  if _cimletType=3 then
    begin
      _y := 1;
      while _y<=_db do
        begin
          if _v[_y]='HUF' then _allwuhuf := _k[_y];
          if _v[_y]='USD' then _allwuusd := _k[_y];
          inc(_y);
        end;
    end;

  if _cimletType=4 then _allafa := _aktkesz;

  if _cimlettype=5 then
    begin
      _allfoglalo := _aktkesz;
      _allfogdnem := _aktdnem;
    end;

  if _cimletType=6 then _alleker := _aktkesz;

  _bytetomb[_pp]   := _cimlettype;
  _bytetomb[_pp+1] := _db;
  _pp := _pp + 2;

  _y := 1;
  while _y<=_db do
    begin
      dnemkod(_v[_y]);
      Integkod(_k[_y]);
      inc(_y);
    end;
end;

// =============================================================================
                procedure TatadAtvetForm.wordkod(_w: word);
// =============================================================================

var _hi,_lo: byte;

begin
  _hi := trunc(_w/256);
  _lo := _w - trunc(256*_hi);

  _bytetomb[_pp] := _lo;
  _bytetomb[_pp+1] := _hi;
  _pp := _pp + 2;
end;

// =============================================================================
               procedure TatadAtvetForm.Integkod(_ertek: integer);
// =============================================================================

var _hhi,_hlo,_hi,_lo: byte;

begin
   _hhi := trunc(_ertek/16777216);
   _ertek := _ertek-trunc(16777216*_hhi);

   _hlo := trunc(_ertek/65536);
   _ertek := _ertek - trunc(_hlo*65536);

  _hi := trunc(_ertek/256);
  _lo := _ertek - trunc(256*_hi);

  _bytetomb[_pp]    := _lo;
  _bytetomb[_pp+1] := _hi;
  _bytetomb[_pp+2] := _hlo;
  _bytetomb[_pp+3] := _hhi;
  _pp := _pp + 4;
end;


// =============================================================================
                procedure TatadAtvetForm.Dnemkod(_vn: string);
// =============================================================================

var _a,_b,_c,_lo,_hi: byte;

begin
  _a := ord(_vn[1])-65;
  _b := ord(_vn[2])-65;
  _c := ord(_vn[3])-65;

  asm
    mov al,_a
    shl al,2

    mov ah,_b
    shr ah,3
    or al,ah
    mov _lo,al

    mov al,_b
    shl al,5
    mov ah,_c
    or al,ah
    mov _hi,al
  end;

  _bytetomb[_pp] := _lo;
  _bytetomb[_pp+1] := _hi;
  _pp := _pp + 2;
end;

// =============================================================================
                  procedure TatadAtvetform.GroupenProgram;
// =============================================================================

var _y: byte;

begin
  Munkalec.Caption := _munkacim;
  {

   for i := 1 to 27 do
    begin
      _vflag[i] := 0;
      _bj[i].Enabled  := False;
      _dec[i].Enabled := False;
      _dec[i].Caption    := '';
      _af[i].Caption     := '';
      _af[i].Enabled  := False;

    end;
   }

  with Munkalec do
    begin
      Caption := _munkacim;
      Top     := 32;
      Left    := 110;
      Visible := True;
      Repaint;
    end;


  _y := 1;
  while _y<=_devizadarab do
    begin
      _xx := _devizasor[_y];

      _aktelszarf := _elszarf[_xx];
      _aktPanel := _af[_y];
      _aktPanel.Caption := inttostr(_aktelszarf);
      _aktPanel.Enabled := true;

      _aktdnev := _dnev[_xx];
      _aktkesz := _devizasum[_y];
      _bjegystr[_y] := inttostr(_aktkesz);

      _nv[_y].caption := _aktdnev;
      _bj[_y].caption := Forintform(_aktkesz);
      _bj[_y].Enabled := true;
      _nv[_y].repaint;
      _bj[_y].repaint;
      inc(_y);
    end;
 
end;

// =============================================================================
               procedure TAtadAtvetForm.ForintGroupen;
// =============================================================================

begin
  _dType := 'FT';
  _devizadarab := 1;

  _pcs := 'SELECT * FROM ' + _btTabla + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_backFtBizony+chr(39);

  valdatadbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _recno := _recno;
    end;

  if _recno=0 then
    begin
      ShowMessage('ÉRVÉNYTELEN A FORINT BIZONYLATSZÁM: (' + _backFtbizony +')');
      ValdataQuery.close;
      Valdatadbase.close;
      Modalresult := 2;
      exit;
    end;

  _aktbankjegy := ValDataQuery.FieldbyName('BANKJEGY').asInteger;
  ValdataQuery.close;
  ValdataDbase.close;

  _devizasor[1] := _hufindex;
  _devizasum[1] := _aktbankjegy;
  _ezVissza     := False;
  TranzakcioKonyveles;
end;

// =============================================================================
              function TatadatvetForm.Fourdisp(_s: string):string;
// =============================================================================

begin
  while length(_s)<4 do _s := _s + ' ';
  result := leftstr(_s,4);
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//    Valamelyik egérgombot megnyomta az egyik deviza bankjegy-tégláján       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
    procedure TATADATVETFORM.B1MouseDown(Sender: TObject; Button: TMouseButton;
                       Shift: TShiftState; X, Y: Integer);
// =============================================================================

var _l,_t: word;

begin


  // Ha még nincs letiltva a devizák kiválasztása - akkor most letiltja azt:

  if _noselect=False then
    begin

      _noselect := true;
    end;


  
  // A kiválasztott valuták sorszáma -> devsorindex

  _devsorindex := Tpanel(Sender).Tag;

  // A kiválasztott valután milyen sorszámu valuta van -> _dnemindex

  _dnemIndex   := _devizasor[_devsorindex];

  // A kiválasztott valuta eddigi bankjegye

  _aktsumertek := _devizasum[_devsorindex];
  _akttext := inttostr(_aktsumertek);

 

  // a kiválasztott devizasorból az aktuális deviza sorszáma:
  // A téglát besárgitja:

  _aktTegla       := _bj[_devsorindex];
  _aktTegla.Color := $B0FFFF;

  // Amennyiben a bal egérgomb van benyomva:

  if Button=mbleft then
    begin

      // A bankjegytéglán levõ összeget beirja a HydeEdit-be és odaFokuszál

      _akttext := inttostr(_aktsumertek);

      // Beirja a rejtett Edit-be a bankjegyek összegét:

      exit;
    end;

  // OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

  // Amennyiben a jobb egérgombot nyomta be:

  If Button=mbright then
    begin

      // A 'KELL CIMLET KÉRDÉS' bal margójának megállapitása

      _l := 517;
      if _devsorindex>13 then _l := 824;

      // A fenti kérdés TOP pontjának meghatározása:

      _t := _devsorindex;

      if _t>13 then _t := _t-13;
      _t := 210+trunc(29*_t);

      // A kérdés kijelzése a képernyõre és ráfokuszál:

      with KellCimletPanel do
        begin
          Left    := _L;
          Top     := _T;
          Visible := True;
        end;
    end;
end;

// =============================================================================
               procedure TATADATVETFORM.DEC1Click(Sender: TObject);
// =============================================================================

begin
  _devsorindex := Tedit(sender).tag;
  if _bjegystr[_devsorindex]='' then exit;

 
  _dec[_devsorindex].Color := clYellow;
  _akttext := _decstr[_devsorindex];
  _aktPanel := _dec[_devsorindex];
  _aktPanel.Enabled := true;
  _aktPanel.Caption := fourDisp(_akttext);

end;



// =============================================================================
           procedure TATADATVETFORM.B1Click(Sender: TObject);
// =============================================================================

begin
  // Ha még nincs letiltva a devizák kiválasztása - akkor most letiltja azt:

  if _noselect=False then
    begin
 
      _noselect := true;
    end;




  _devsorindex     := Tpanel(Sender).Tag;
  _aktpanel        := _bj[_devsorindex];
  _aktpanel.Color  := clYellow;

  _dnemIndex       := _devizasor[_devsorindex];
  _aktsumertek     := _devizasum[_devsorindex];
  _akttext         := inttostr(_aktsumertek);

end;


// =============================================================================
                 procedure Tatadatvetform.AllKezdijAtad;
// =============================================================================

var _utkiadas,_mozgas: word;

begin
  if _allkezdij=0 then exit;

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      Sql.Add('SELECT * FROM KEZELESIDATA');
      Open;
      _aktkezdij   := Fieldbyname('AKTKEZELESIDIJ').asInteger;
      _utKiadas := FieldByName('UTKIADAS').asInteger;
      Close;
     end;
  Valutadbase.close;
  inc(_utkiadas);
  _bizonylatszam := inttostr(_utkiadas);

  while length(_bizonylatszam)<6 do _bizonylatszam := '0' + _bizonylatszam;
  _bizonylatszam := 'K-' + _bizonylatszam;
  _mozgas := 3;

  _pcs := 'INSERT INTO KEZELESIDIJ (DATUM,BIZONYLAT,ELOJEL,KEZELESIDIJ,';
  _pcs := _pcs + 'PENZTAR,STORNO,MOZGAS,PLOMBASZAM,SZALLITONEV)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + '-' + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktkezdij) + ',';
  _pcs := _pcs + inttostr(_ertektar)+',';
  _pcs := _pcs + '1,' + inttostr(_mozgas)+',';
  _pcs := _pcs + chr(39) + trim(_plombaszam) + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_szallitonev) + chr(39) + ')';
  ValutaParancs(_pcs);


  _pcs := 'UPDATE KEZELESIDATA SET AKTKEZELESIDIJ=0';
  _pcs := _pcs + ',UTKIADAS=' + inttostr(_UTKIADAS);
  ValutaParancs(_pcs);

  FejlecIro;

  WriteLn(_LFile,' KEZELESI KOLTSEG ATADASI BIZONYLATA');

  VonalHuzo;
  writeLn(_LFile,'      Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'    Bizomylat kelte: ' + _megnyitottnap);

  write(_LFile,'     Atvevo penztar: ');
  writeLn(_LFile,inttostr(_ertektar));

  write(_LFile,'     Atadott osszeg: ');
  writeLn(_LFile,forintform(_aktkezdij)+' Ft');
  VonalHuzo;


  writeLn(_LFile,'Szallitonev: '+_szallitonev);
  writeLn(_LFile,'Plomba-szam: '+_plombaszam);
  writeLn(_LFile,' Megjegyzes: '+_megjegyzes);
  writeLn(_lFile,_sorveg+_sorveg);
  writeLN(_Lfile,'..................  ...................');
  writeLn(_LFile,'      atado                 atvevo     ');
  writeLn(_LFile,_sorveg);
  closeFile(_Lfile);

  FileKiiro(_LPath);
end;

// =============================================================================
                    procedure TatadatvetForm.Fejleciro;
// =============================================================================

begin
  AssignFile(_LFile,'C:\VALUTA\aktlst.txt');
  rewrite(_LFile);

  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_penztarcim);
  VonalHuzo;
end;

// =============================================================================
               procedure Tatadatvetform.AllWesternatad;
// =============================================================================

var _utwki: integer;

begin
  if (_allwuusd=0) and (_allwuhuf=0) then  exit;

  _pcs := 'SELECT * FROM WUAFAADATOK';
  ValutaDbase.Connected := true;
  with  ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      _utwki := FieldByName('UTOLSOWUKIBLOKK').asInteger;
      CLOSE;
    end;
  Valutadbase.close;

  if _allwuusd>0 then
    begin
      inc(_utwki);
      _bizonylatszam := 'WK-'+nulele(_utwki,6);
      _aktdnem := 'USD';
      _wuOsszeg := _allwuusd;
      Wurekord;
    end;

  if _allwuhuf>0 then
    begin
      inc(_utwki);

      _bizonylatszam := 'WK-'+ NULELE(_utwki,6);

      _aktdnem := 'HUF';
      _wuOsszeg := _allwuHUF;
      Wurekord;
    end;

  _PCS := 'UPDATE WUAFAADATOK SET UTOLSOWUKIBLOKK='+inttostr(_utwki);
  _pcs := _pcs + ',WUDOLLARKESZLET=0,WUFORINTKESZLET=0';
  ValutaParancs(_pcs);
end;

// =============================================================================
               procedure Tatadatvetform.Wurekord;
// =============================================================================

begin

  _pcs := 'INSERT INTO WUMOZGAS (FOEGYSEGSZAM,PENZTARSZAM,SORSZAM,';
  _pcs := _pcs + 'DATUM,IDO,VALUTANEM,BANKJEGY,PENZTAROSNEV,';
  _pcs := _pcs + 'TRANZAKCIOTIPUS,STORNO,IDKOD)' + _sorveg;

  _pcs := _pcs + 'VALUES (2,';
  _pcs := _pcs + inttostr(_ertektar) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_wuosszeg) + ',';
  _pcs := _pcs + chr(39) + _aktprosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + '-K' + chr(39) + ',';    // -K vagy +B
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _aktidkod + chr(39) + ')';
  ValutaParancs(_pcs);

  WuBizonylatnyomtatas;
end;

// =============================================================================
             procedure TatadatvetForm.Wubizonylatnyomtatas;
// =============================================================================

begin
  Fejleciro;
  KozepreIr('WU ATADAS AZ ERTEKTARNAK');
  writeLn(_LFile,'Atvevo: ' + inttostr(_ertektar)+' ERTEKTAR');
  VonalHuzo;

  writeln(_LFile,' Bizonylatszam: ' + _bizonylatszam);
  writeln(_LFile,' Atadas  kelte: ' + _megnyitottnap);
  writeln(_LFile,'Atadott osszeg: ' + inttostr(_wuosszeg)+' '+_AKTDNEM);
  writeLn(_Lfile,' Szallito neve: ' + _szallitonev);
  writeLn(_LFile,'Zsakplombaszam: ' + _plombaszam);
  VonalHuzo;
  writeln(_Lfile,_sorveg,_sorveg);
  writeln(_Lfile,'..................   ..................');
  writeln(_LFile,'     atado                 atvevo');
  writeln(_LFile,_sorveg);

  CloseFile(_LFile);

  Filekiiro(_Lpath);
end;

// =============================================================================
                   procedure Tatadatvetform.AllEkerAtad;
// =============================================================================

var _utbiz: integer;
    _havitabla: string;

begin
  if _alleker=0 then exit;

  tradedbase.close;
  tradedbase.DatabaseName := 'C:\VALUTA\DATABASE\TRADE.FDB';
  tradedbase.connected := true;
  with tradequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM PARAMETERS');
      Open;
      _utbiz := FieldByName('UTBIZONYLAT').asInteger;
      Close;
    end;
  Tradedbase.close;
  inc(_utbiz);
  _bizonylatszam := nulele(_utbiz,6);
  _bizonylatszam := 'F' + _bizonylatszam;


  _havitabla := 'TRAD'+MIDSTR(_megnyitottnap,3,2)+midstr(_megnyitottnap,6,2);

  _pcs := 'INSERT INTO ' + _havitabla + ' (TIPUS,BIZONYLATSZAM,FIZETENDO,';
  _pcs := _pcs + 'PENZTAROSNEV,DATUM,IDO,TARSPENZTAR,STORNO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + 'F' + chr(39) + ',';
  _pcs := _pcs +  chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_alleker) + ',';
  _pcs := _pcs + chr(39) + _aktprosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + inttostr(_ertektar) + ',';
  _pcs := _pcs + '1)';

  TradeParancs(_pcs);

  _pcs := 'UPDATE PARAMETERS SET UTBIZONYLAT=' + inttostr(_utbiz);
  TradeParancs(_pcs);

  Tradebizonylat;
end;

// =============================================================================
                  procedure TatadatvetForm.TradeBizonylat;
// =============================================================================

begin
  FejlecIro;
  kozepreir('EKER FORINT FELADASA AZ ERTEKTARNAK');
  Vonalhuzo;
  writeLn(_LFile,'   BIZONYLATSZAM: ' + _bizonylatszam);
  writeLn(_LFile,'  FELADAS DATUMA: ' + _megnyitottnap);
  writeln(_LFile,'   FELADAS IDEJE: ' + _aktidos);
  writeln(_LFile,' FELADOTT OSSZEG: ' + inttostr(_alleker));
  writeLn(_LFile,'  ATVEVO PENZTAR: ' + inttostr(_ertektar)+ ' ERTEKTAR');
  writeln(_Lfile,'FELADAST VEGEZTE: ' + _aktProsnev);
  Vonalhuzo;
  writeLn(_LFile,_sorveg);
  CloseFile(_LFile);
  FileKiiro(_LPath);

end;


// =============================================================================
                     procedure TatadatvetForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
             procedure TatadatvetForm.TradeParancs(_ukaz: string);
// =============================================================================

begin
  Tradedbase.close;
  Tradedbase.databasename := 'c:\valuta\database\trade.fdb';
  Tradedbase.connected := true;
  if TradeTranz.intransaction then TradeTranz.commit;
  TradeTranz.StartTransaction;
  with TradeQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  TradeTranz.commit;
  tradedbase.close;
end;

// =============================================================================
                   procedure TatadatvetForm.EverythingTake;
// =============================================================================

begin
  AllKezdijatad;
  Allwesternatad;
  Allekeratad;
end;

// =============================================================================
                  procedure TatadatvetForm.AllAfaAtad;
// =============================================================================

begin
  if _allafa=0 then exit;

  if _kellmetroafa=1 then
    begin
      AllMetroAfaAtad;
      exit;
    end;

  // ---------- All tesco afa atadása --------------------

  valutadbase.connected := true;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _utblokk := FieldbyNAme('UTOLSOTESCOBLOKK').asInteger;
      Close;
    end;
  Valutadbase.close;
  inc(_utblokk);
  _bizonylatszam := 'K-' + nulele(_utblokk,5);

  _pcs := 'INSERT INTO TESCO (DATUM,IDO,BIZONYLATSZAM,WUGYFELNEV,IDKOD,';
  _pcs := _pcs + 'OSSZESFORINT,STORNO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + inttostr(_ertektar)+'. ERTEKTAR' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidkod + chr(39) + ',';
  _pcs := _pcs + inttostr(_allafa) + ',0)';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE WUAFAADATOK SET UTOLSOTESCOBLOKK=' + inttostr(_utblokk);
  ValutaParancs(_pcs);

  Tescobizonylat;
end;

// =============================================================================
              procedure TatadatvetForm.TescoBizonylat;
// =============================================================================

begin
  fejleciro;

  writeLn(_Lfile,'     ----------  INNOVA -----------');
  writeLN(_LFile,' Bizonylatszam: ' + _bizonylatszam);
  writeLn(_Lfile,'  Atadas kelte: ' + _megnyitottnap);
  writeLn(_Lfile,'Atadott osszeg: ' + inttostr(_allafa));
  writeln(_LFile,' Szallito neve: ' + _szallitonev);
  writeLn(_LFile,'Zsakplombaszam: ' + _plombaszam);
  writeln(_LFile,_sorveg);
  writeLn(_Lfile,'................       .................');
  writeLn(_LFile,'     atado                   atvevo');
  writeln(_LFile,_sorveg+_sorveg);

  CloseFile(_LFile);
  FileKiiro(_LPath);
end;

// =============================================================================
                 procedure TatadatvetForm.AllmetroAfaAtad;
// =============================================================================

begin
  valutadbase.connected := true;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _utblokk := FieldbyNAme('UTOLSOAFAKIBLOKK').asInteger;
      Close;
    end;
  Valutadbase.close;
  inc(_utblokk);
  _bizonylatszam := 'AK-' + nulele(_utblokk,6);

  _pcs := 'INSERT INTO METROAFAMOZGAS (FOEGYSEG,DATUM,IDO,SORSZAM,STORNO,';
  _pcs := _pcs + 'ELLATMANYFORINT,TRANZAKCIOTIPUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (4,' + CHR(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',1,';
  _pcs := _pcs + inttostr(_allafa)+',';
  _pcs := _pcs + chr(39) + '-K' + CHR(39) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE WUAFAADATOK SET UTOLSOAFAKIBLOKK=' + inttostr(_utblokk);
  ValutaParancs(_pcs);

  Metrobizonylat;
end;


// =============================================================================
                  procedure TAtadatvetForm.MetroBizonylat;
// =============================================================================

begin
   fejleciro;

  KozepreIr('AFA ELLATMANY ATADASA ERTEKTARNAK');
  Kozepreir(inttostr(_ertektar)+' ERTEKTAR');
  Vonalhuzo;

  writeLN(_LFile,' Bizonylatszam: ' + _bizonylatszam);
  writeLn(_Lfile,'  Atadas kelte: ' + _megnyitottnap);
  writeLn(_Lfile,'Atadott osszeg: ' + inttostr(_allafa));
  writeln(_LFile,' Szallito neve: ' + _szallitonev);
  writeLn(_LFile,'Zsakplombaszam: ' + _plombaszam);
  writeln(_LFile,_sorveg);
  writeLn(_Lfile,'................       .................');
  writeLn(_LFile,'     atado                   atvevo');
  writeLn(_LFile,_sorveg,_sorveg);
  CloseFile(_LFile);
  FileKiiro(_LPath);
end;

// =============================================================================
                   procedure TAtadatvetForm.Egyebpenzatvetel;
// =============================================================================

var i,_z,_db: byte;

begin
  for i := 1to 8 do
    begin
      _otherdb[i] := 0;
      for _z := 1 to 2 do
        begin
          _otherdnem[i,_z] := '';
          _otherkesz[i,_z] := 0
        end;
    end;

  while True do
    begin
      _cimlettype := Bytedekod;
      if _cimlettype=255 then break;

      _db := bytedekod;
      _otherdb[_cimlettype] := _db;

      _z := 1;
      while _z<=_db do
        begin
          _aktdnem := dnemdekod;
          _aktkesz := integdekod;
          _otherdnem[_cimlettype,_z] := _aktdnem;
          _otherkesz[_cimlettype,_z] := _aktkesz;
          inc(_z);
        end;
    end;
end;


// =============================================================================
                procedure Tatadatvetform.EgyebPenzekKonyvelese;
// =============================================================================

begin
  _cimlettype := 2;
  while _cimlettype<=8 do
    begin
      if _cimlettype=7 then _cimlettype := 8;
      _aktdb := _otherdb[_cimlettype];
      if _aktdb>0 then
        case _cimlettype of
          2: Kezdijatvetel;
          3: westernatvetel;
          6: ekeratvetel;
        end;
      inc(_cimlettype);
    end;
end;

// =============================================================================
                   procedure TatadAtvetForm.Kezdijatvetel;
// =============================================================================

var _mozgas: Byte;

begin
  _aktkezdij := _otherKesz[2,1];
  Valutadbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM KEZELESIDATA');
      Open;
      _utbe := FieldByName('UTBEVET').asInteger;
      _kezdij := FieldByName('AKTKEZELESIDIJ').asInteger;
      close;
    end;
  Valutadbase.close;
  inc(_utbe);

  _bizonylatszam := 'B-' + nulele(_utbe,6);
  _mozgas := 4;

  _pcs := 'INSERT INTO KEZELESIDIJ (DATUM,BIZONYLAT,ELOJEL,KEZELESIDIJ,';
  _pcs := _pcs + 'PENZTAR,STORNO,MOZGAS,PLOMBASZAM,SZALLITONEV)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + '+' + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktkezdij) + ',';
  _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ',';
  _pcs := _pcs + '1,' + inttostr(_mozgas)+',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ')';

  ValutaParancs(_pcs);

  _kezdij := _kezdij + _aktkezdij;
  _pcs := 'UPDATE KEZELESIDATA SET UTBEVET='+inttostr(_utbe)+',';
  _pcs := _pcs + 'AKTKEZELESIDIJ='+inttostr(_kezdij);

  ValutaParancs(_pcs);

  Fejleciro;
  kozepreIr('KEZELESI DIJ ATVETEL EGY PENZTARTOL');
  VonalHuzo;
  writeLn(_LFile,'      Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'    Bizonylat kelte: ' + _megnyitottnap);

  write(_LFile,'      Átadó pénztár: ');
  writeLn(_LFile,_tarspenztarkod);

  write(_LFile,'      Átvett összeg: ');
  writeLn(_LFile,forintform(_AKTkezdij)+' Ft');
  VonalHuzo;

  writeLn(_lFile,_sorveg+_sorveg);
  writeLN(_Lfile,'..................  ...................');
  writeLn(_LFile,'      atado                 atvevo     ');
  writeLn(_LFile,_sorveg+_sorveg);
  closeFile(_LFile);
  FileKiiro(_Lpath);
end;

// =============================================================================
                   procedure TatadAtvetForm.WesternAtvetel;
// =============================================================================

var _utusd,_uthuf: integer;

begin
  Valutadbase.connected := true;
  with Valutaquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _utbe := FieldByNAme('UTOLSOWUBEBLOKK').asInteger;
      _uthuf := FieldByName('WUFORINTKESZLET').asInteger;
      _utusd := FieldbyNAme('WUDOLLARKESZLET').asInteger;
      Close;
    end;

  Valutadbase.close;
  inc(_utbe);
  _aktdnem := _otherdnem[3,1];
  _aktkesz := _otherkesz[3,1];

  if _aktdnem='HUF'  then _uthuf := _uthuf + _aktkesz
  else _utusd := _utusd + _aktkesz;

  _bizonylatszam := 'WB-' + nulele(_utbe,6);
  _pcs := 'INSERT INTO WUMOZGAS (FOEGYSEGSZAM,SORSZAM,DATUM,VALUTANEM,BANKJEGY,';
  _pcs := _pcs + 'UGYFELTIPUS,TRANZAKCIOTIPUS,STORNO,IDO)' + _sorveg;
  _pcs := _pcs + 'VALUES (2,'+CHR(39)+_bizonylatszam + chr(39)+',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) +',';
  _pcs := _pcs + inttostr(_aktkesz) + ',';
  _pcs := _pcs + chr(39) + 'P' + chr(39) + ',';
  _pcs := _pcs + chr(39) + '+B' + chr(39) + ',';
  _pcs := _pcs + '1,'+chr(39)+_aktidos+chr(39)+')';
  ValutaParancs(_pcs);

  if _aktdb=2 then
    begin
      _aktdnem := _otherdnem[3,2];
      _aktkesz := _otherkesz[3,2];

      if _aktdnem='HUF'  then _uthuf := _uthuf + _aktkesz
      else _utusd := _utusd + _aktkesz;

      _pcs := 'INSERT INTO WUMOZGAS (FOEGYSEGSZAM,SORSZAM,DATUM,VALUTANEM,BANKJEGY,';
      _pcs := _pcs + 'UGYFELTIPUS,TRANZAKCIOTIPUS,STORNO,IDO)' + _sorveg;
      _pcs := _pcs + 'VALUES (2,'+CHR(39)+_bizonylatszam + chr(39)+',';
      _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) +',';
      _pcs := _pcs + inttostr(_aktkesz) + ',';
      _pcs := _pcs + chr(39) + 'P' + chr(39) + ',';
      _pcs := _pcs + chr(39) + '+B' + chr(39) + ',';
      _pcs := _pcs + '1,'+chr(39)+_aktidos+chr(39)+')';
      ValutaParancs(_pcs);
    end;

  _pcs := 'UPDATE WUAFAADATOK SET UTOLSOWUBEBLOKK='+INTTOSTR(_UTBE);
  _pcs := _pcs + ',WUFORINTKESZLET=' + inttostr(_uthuf);
  _pcs := _pcs + ',WUDOLLARKESZLET=' + inttostr(_utusd);
  ValutaParancs(_pcs);

  Fejleciro;
  kozepreir('WU. PENZATVETEL EGY PENZTARTOL');
  writeLn(_LFile,'PARTNER: ' + _tarspenztarkod);
  vonalhuzo;
  writeLn(_Lfile,'BIZONYLATSZAM: ' + _bizonylatszam);
  writeLn(_LFile,'Atvetel kelte: '+ _megnyitottnap);
  _aktdnem := _otherdnem[3,1];
  _aktkesz := _otherkesz[3,1];

  writeln(_LFile,'Atvett osszeg: ' +  inttostr(_aktkesz)+' '+_aktdnem);
  if _aktdb=2 then
    begin
      _aktdnem := _otherdnem[3,2];
      _aktkesz := _otherkesz[3,2];

      writeln(_LFile,'               ' +  inttostr(_aktkesz)+' '+_aktdnem);
    end;
  VonalHuzo;
  writeLn(_LFile,_sorveg+_sorveg);
  writeLn(_LFile,'..................      ....................');
  writeLN(_LFile,'      atado                     atvevo');
  writeln(_LFile,_sorveg+_sorveg);
  CloseFile(_LFile);

  FileKiiro(_LPath);
end;

// =============================================================================
                       procedure TatadAtvetForm.Ekeratvetel;
// =============================================================================

var _akteker,_utbiz,_aktkesz: integer;

begin
  _akteker := _otherkesz[6,1];
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM MATDATA');
      Open;
      _utbiz := FieldByNAme('UTMATSORSZAM').asInteger;
      _aktkesz := FieldByNAme('AKTKESZLET').asInteger;
      close;
    end;
  Valutadbase.close;

  inc(_utbiz);
  _bizonylatszam := 'B' + nulele(_utbiz,6);
  _aktkesz := _aktkesz + _akteker;

  _pcs := 'INSERT INTO MATBIZONYLAT (DATUM,BIZONYLATSZAM,OSSZEG,PENZTARSZAM,';
  _pcs := _pcs + 'BIZONYLATTIPUS,STORNO,PENZTAROS)' + _sorveg;
  _pcs := _pcs + 'VALUES ('+CHR(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_akteker) + ',';
  _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'B' + chr(39) + ',';
  _pcs := _pcs + '1,'+chr(39)+_aktprosnev+chr(39)+')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE MATDATA SET UTMATSORSZAM=' + inttostr(_utbiz);
  _pcs := _pcs + ',AKTKESZLET='+inttostr(_aktkesz);
  ValutaParancs(_pcs);

  // ------------------------------------------------------------

  Fejleciro;
  Kozepreir('E-KERESKEDELEM PENZATVETEL BIZONYLAT');
  vONALhUZO;

  writeLn(_lFile,'BIZONYLATSZAM: ' + _bizonylatszam);
  writeLn(_LFile,'        DATUM: ' + _megnyitottnap);
  writeLn(_LFile,'ATADO PENZTAR: ' + _TARSPENZTARKOD);
  writeLn(_LFile,'ATVETT OSSZEG: ' + inttostr(_akteker));
  vonalhuzo;
  writeLn(_LFile,'SZALLITONEV: ' + _szallitonev);
  writeLn(_LFile,' PLOMBASZAM: ' + _plombaszam);

  writeln(_LFile,' MEGJEGYZES: ' + _megjegyzes);
  writeln(_LFile,_sorveg+_sorveg);

  writeln(_LFile,'................        ...............');
  writeLn(_LFile,'    atado                     atvevo');
  writeln(_Lfile,_sorveg+_sorveg);
  CloseFile(_LFile);
  FileKiiro(_LPath);

end;


// =============================================================================
             procedure Tatadatvetform.CImletKijelolo(_ct: byte);
// =============================================================================

begin
  _pcs := 'UPDATE HARDWARE SET MENETSZAM='+inttostr(_ct);
  ValutaParancs(_pcs);
end;




end.


