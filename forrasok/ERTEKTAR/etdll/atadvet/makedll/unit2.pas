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
    PRNZATADGOMB: TPanel;
    PENZATVETGOMB: TPanel;
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

    AxaQuery           : TibQuery;
    AxaDbase           : TibDatabase;
    AxaTranz           : TibTransaction;

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
    hrkgomb: TPanel;

    procedure AlapadatBeolvasas;
    procedure Alapnullazas;
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
    procedure PRNZATADGOMBClick(Sender: TObject);
    procedure PENZATVETGOMBClick(Sender: TObject);
    procedure DisappearPanels;
    procedure Dnemkod(_vn: string);
    procedure EgyebPenzatvetel;
    procedure EgyebPenzekKonyvelese;
    procedure EgytetelFeliras;
    procedure EkerGombClick(Sender: TObject);
    procedure EkerAtvetel;
    procedure ElszamBeolvasas;
    procedure ErtektarAllAtvetel(Sender: TObject);
    procedure ExitGombClick(Sender: TObject);
    procedure Fejleciro;
    procedure Fejteteltorles;
    procedure ForintGroupen;
    procedure FormActivate(Sender: TObject);
    procedure FtpSzerverreLep;
    procedure GiveDataBackOkeGombClick(Sender: TObject);
    procedure GroupenProgram;
    procedure FileKiiro(_fPath: string);
    procedure Integkod(_ertek: integer);
    procedure KeszletVisszaAdas(Sender: TObject);
    procedure Kezdijatvetel;
    procedure KezdijGombClick(Sender: TObject);
    procedure KozepreIr(_szoveg: string);
    procedure KozosAdvet;
    procedure MenuBe;
    procedure ParaMegsemGombClick(Sender: TObject);
    procedure PenztarBeolvasas;
    procedure PiszkozatBeolvasas;
    procedure PlombaAdatBeolvasas;
    procedure ProcessDisplay;

    procedure TranzakcioKonyveles;
    procedure ValutaParancs(_ukaz: string);
    procedure Vonalhuzo;
    procedure WesternAtvetel;
    procedure Wordkod(_w: word);
 
    function ByteDekod: byte;
    function DnemDekod:string;
    function Elokieg(_s: string;_h: byte):string;
    function ForintForm(_sm:integer):string;
    function Fourdisp(_s: string):string;
    function Getbizonylat: string;
    function Getidos: string;
    function IntegDekod: integer;
    function KeszletControl: boolean;

    //    function Kerekito(_int: integer): integer;

    function Negyes(_n: integer): string;
    function Nulele(_i: integer;_h: word):string;
    function RealToStr(_r: real):string;
    function RemdirCtrlAndSend(_remDir: string): boolean;
    function ScanDnem(_dn: string): byte;
    function TizenEgy(_b: integer): string;
    function TotalFileBeOlvasas: boolean;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    function WordDekod: word;
    procedure hrkgombClick(Sender: TObject);

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
  _devizasum,_devizaertek,_devertek: array[1..27] of integer; // bankjegy és érték
  _alaparfolyam,_elszi: array[1..27] of integer;
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

  _cimletListaPath: string = 'c:\ertektar\cimlprnt.txt';
  _LPath: string = 'c:\ertektar\aktlst.txt';

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
  _sourcePath,_wtipus: string;

  _akttegla: TPanel;
  _pacs: pchar;

  _tag,_uttag,_devsorindex,_dnemindex,_aktcimletdarab,_cimletss,_ctag,_m: byte;
  _cimletindex,_aktDnemIndex,_xx,_tetel,_cimletezve,_printer,_hufindex: byte;
  _penztarszam: byte;
  _cimlettype,_aktdb: byte;

  _dType,_megnyitottnap,_aktdnem,_aktText,_nums,_zaszloPath: string;
  _aktcimletsor,_tarsPenztarKod,_tarsPenztarNev,_munkacim,_pcs: string;
  _szallitonev,_plombaszam,_megjegyzes,_bizonylatszam,_ttema: string;
  _aktdnev,_tipus,_aktidos,_aktprosnev,_aktidkod,_trbpenztarkod: string;
  _mondat,_numeditText,_das,_remoteFile,_bizelokod,_precarfs: string;
  _penztarkod,_penztarnev,_penztarcim,_totalfilenev,_totaldir: string;
  _backPtar,_backbizony,_backDatum,_otip,_farok,_bttabla: string;
  _kerfilenev,_kerdir,_totalpath,_backFtBizony,_totPath: string;
  _elojel,_akttortresz: string;

  _ptoke,_aktnum,_code,_bankjegy,_sorertek,_sumertek,_aktsumertek,_aktbj: integer;
  _aktsorertek,_aktertek,_plombOke,_bizertek,_aktkesz,_wuosszeg,_totalhossz: integer;
  _ujblokknum,_aktelszarf,_ftnum,_recno,_cOke,_utblokk,_akttenyarf: integer;
  _forintkeszlet,_aktbankjegy,_hufkeszlet,_aktarfolyam,_spk,_aktkezdij: integer;
  _allkezdij,_allwuusd,_allwuhuf,_allafa,_alleker,_aktelszam: integer;
  _kezdij,_utbe,_nyugoke: integer;

  _NUMBER : BYTE;
  _kkheight,_dnemss,_ertektar,_pp,_bytess: word;
  _top,_left,_width,_height,_index,_aktcimletertek,_ix: word;
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

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\ertektar\bin\super.dll' name 'supervisorjelszo';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\ertektar\bin\bloknyom.dll' name 'blokknyomtatas';
function kezdijatadorutin: integer; stdcall; external 'c:\ertektar\bin\kezdij.dll' name 'kezdijatadorutin';
function logirorutin(_para: pchar): integer; stdcall; external 'c:\ertektar\bin\logiro.dll' name 'logirorutin';
function matpenztarrutin: integer; stdcall; external 'c:\ertektar\bin\matptar.dll' name 'matpenztarrutin';
function penztarrutin: integer; stdcall; external 'c:\ertektar\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\ertektar\bin\getplomb.dll' name 'getplombarutin';
function cimletctrlrutin: integer; stdcall; external 'c:\ertektar\bin\cimlctrl.dll' name 'cimletctrlrutin';
function cimletezorutin: integer; stdcall; external 'c:\ertektar\bin\cimlet.dll' name 'cimletezorutin';
function regeneralorutin(_para: integer): integer; stdcall; external 'c:\ertektar\bin\regen.dll' name 'regeneralorutin';

function atadatvetrutin: integer; stdcall;
function hrkatvevorutin: integer; stdcall; external 'c:\ertektar\bin\hrkget.dll';
function keszleteditalorutin(_para: byte): integer; stdcall; external 'c:\ertektar\bin\keszedit.dll'
                                                  name 'keszleteditalorutin';

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
  _noregen             := False;
  _maycomma            := False;
  
  Hatterkep.repaint;

  AlapadatBeolvasas;
  AlapNullazas;

  Menube;
end;

// =============================================================================
                       procedure Tatadatvetform.Menube;
// =============================================================================

begin
  {
  atvétel
  átadás
  kezdij átvétel
  eker átvétel
  }

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

//                        PÉNZ ÁTVÉTEL EGY TÁRSPÉNZTÁRTÓL
// =============================================================================
          procedure TATADATVETFORM.ATVETGOMBClick(Sender: TObject);
// =============================================================================

begin

  _irany := 1;  // 1 = átvétel
  with AtvetelPanel do
    begin
      top     := 245;
      left    := 232;
      Visible := True;
    end;
end;


//           PÉNZ VAGY A TELJES KÉSZLET ÁTVÉTELE EGY TÁRSPÉNZTÁRTÓL                       //
// =============================================================================
          procedure TATADATVETFORM.PENZATVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  _irany  := 1;
  _dtype := 'DEV';
  _tipus := 'U';
  logirorutin(pchar('Valuta átvételbe kezd'));
  KozosAdvet;
end;


// PÉNZ VAGY A TELJES BEKÜLDÖTT KÉSZLET ÁTADÁSA EGY TÁRSPÉNZTÁRNAK VAGY BANKNAK
// =============================================================================
             procedure TATADATVETFORM.ATADGOMBClick(Sender: TObject);
// =============================================================================

begin

   _irany := 2;    // 2 = átadás
  with AtadasPanel do
    begin
      top     := 245;
      left    := 232;
      Visible := True;
    end;
end;


//                     PÉNZ ÁTADÁSA EGY TÁRSPÉNZTÁRNAK
// =============================================================================
          procedure TATADATVETFORM.PRNZATADGOMBClick(Sender: TObject);
// =============================================================================

begin
  _irany  := 2;
  _dtype := 'DEV';
  _tipus := 'F';
  logirorutin(pchar('Valuta átadásba kezd'));
  Kozosadvet;
end;


//                A PÉNZ ÁTADÁSOK ÉS ÁTVÉTELEK KÖZÖS RUTINJA
// =============================================================================
                     procedure TAtadatvetform.KozosAdvet;
// =============================================================================

var _vankeszlet: byte;

begin

  // Képernyõ tisztára törlése:

  Menupanel.Visible     := False;
  MenuAlapPanel.Visible := False;
  AtadasPanel.Visible   := False;
  AtvetelPanel.Visible  := False;

  // A társpénztár 2 adatának beolvasása:

  _ptOke := penztarrutin;
  if _ptOke<>1 then
    begin
      Modalresult := 2;
      exit;
    end;

  Hatterkep.repaint;
  PenztarBeolvasas;  // a választott pénztár adfat

  _pcs := 'UPDATE VTEMP SET TIPUS=' + chr(39) + _tipus + chr(39);
  ValutaParancs(_pcs);

  Sleep(200);

  if (_tarspenztarkod='TH') OR (_tarspenztarkod='1') then
    begin
       _spk := supervisorjelszo(0);
       if _spk<>1 then
         begin
           Modalresult := 2;
           exit;
         end;
    end;

  _vankeszlet := keszleteditalorutin(_irany);
  if _vankeszlet=2 then
    begin
      Menube;
      exit;
    end;

  PiszkozatBeolvasas;  // A kitöltött táblázat beolvasása

  if not KeszletControl then
    begin
      Modalresult := 2;
      exit;
    end;

   // Bekéri a szállitó nevét és a plombaszámot:

  _plombOke := getplombarutin;
  if _plomboke<>1 then
    begin

      // Ha nem sikerült a plomba beplvasás -> storno az egész tranzakció

      Modalresult := 2;
      exit;
    end;

  PlombaadatBeolvasas;
  TranzakcioKonyveles;
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

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  BlokktetelIras;
  BlokkfejIras;

  blokknyomtatas(1);
  CimletNyomtatas;

  _fttipus := midstr(_bizonylatszam,2,1);
  if (_fttipus='F') then
    begin
      blokknyomtatas(2);
      CimletNyomtatas;
    end;

  if Fileexists(_cimletListaPath) then sysutils.DeleteFile(_cimletListaPath);
  _cimletezve := 0;
  if _noregen=False then regeneralorutin(0);
  Modalresult := 1;

end;


//               Átadás - átvétel blokk fejlécének felirása
// =============================================================================
                 procedure TatadAtvetForm.BlokkFejIras;
// =============================================================================

begin

  _aktidos := GetIdos;
//  _bizertek := kerekito(_bizertek);

  _pcs := 'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,';
  _pcs := _pcs + 'TETEL,FORINTERTEK,TARSPENZTARKOD,';
  _pcs := _pcs + 'PENZTAROSNEV,IDKOD,PLOMBASZAM,SZALLITONEV,';
  _pcs := _pcs + 'STORNO,TRBPENZTAR)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';

  _pcs := _pcs + inttostr(_tetel) + ',';
  _PCS := _PCS + inttostr(_bizertek) + ',';
  _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ',';

  _pcs := _pcs + chr(39) + _aktprosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidkod + chr(39) + ',';

  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';

  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _trbpenztarkod + chr(39) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE VTEMP SET BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  _pcs := _pcs + ',TIPUS=' + chr(39)+_tipus+chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _megnyitottnap + chr(39);
  _pcs := _pcs + ',IDO=' + chr(39) + (_aktidos) + chr(39);
  _pcs := _pcs + ',TETEL=' + inttostr(_tetel);
  _pcs := _pcs + ',PENZTARKOD=' + chr(39)+ _tarspenztarkod + chr(39);
  _pcs := _Pcs + ',TRBPENZTAR=' + chr(39) + _trbpenztarkod + chr(39);
  _pcs := _pcs + ',TARSPENZTARNEV=' + chr(39)+_tarspenztarnev+chr(39);
  _pcs := _pcs + ',OSSZESFORINTERTEK=' + inttostr(_bizertek);
  _pcs := _pcs + ',SZALLITONEV=' + chr(39) + _szallitonev + chr(39);
  _pcs := _pcs + ',PLOMBASZAM='+ chr(39) + _plombaszam + chr(39);
  _pcs := _pcs + ',MEGJEGYZES=' + chr(39) + _megjegyzes + chr(39);
  _pcs := _pcs + ',STORNO=1';
  ValutaParancs(_pcs);

  if _elojel='+' then _wtipus :='U+' else _wtipus := 'F-';


  _PCS := 'INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,PLOMBASZAM,';
  _pcs := _pcs + 'SZALLITONEV,WTIPUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_megnyitottnap+chr(39)+',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _plombaszam + CHR(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _wtipus + chr(39) + ')';
  Valutaparancs(_pcs);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET ' + _ttema + '=' + inttostr(_ujblokknum);
  ValutaParancs(_pcs);
end;


//               Átadás - átvétel összes tételeinek felirása
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

      _akttenyarf  := _alaparfolyam[_tetel];
      _aktelszarf  := _elszi[_tetel];
      _akttortresz := trim(_arftortresz[_tetel]);
      _aktertek    := _devertek[_tetel];
      _bizertek    := _bizertek + _aktertek;
      EgyTetelFeliras;
    end;
end;



//               Átadás - átvétel egy tételének felirása                      //
// =============================================================================
                procedure TatadAtvetForm.EgytetelFeliras;
// =============================================================================

begin
  _elojel := '+';
  if _irany=2 then _elojel := '-';

  _pcs := 'INSERT INTO BLOKKTETEL (DATUM,BIZONYLATSZAM,VALUTANEM,ELOJEL,';
  _pcs := _pcs + 'ARFOLYAM,ELSZAMOLASIARFOLYAM,BANKJEGY,FORINTERTEK,';
  _pcs := _pcs + 'STORNO,TORTRESZ)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39)+',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + inttostr(_akttenyarf) + ',';
  _pcs := _pcs + inttostr(_aktelszarf) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + inttostr(_aktertek) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _akttortresz + chr(39)+')';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (VALUTANEM,BANKJEGY,ELOJEL,FORINTERTEK,';
  _pcs := _pcs + 'BIZONYLATSZAM,ARFOLYAM,ELSZAMOLASIARFOLYAM,TORTRESZ)' +  _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktertek) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_akttenyarf) + ',';
  _pcs := _pcs + inttostr(_aktelszarf) + ',';
  _pcs := _pcs + chr(39) + _akttortresz + chr(39)+')';
  ValutaParancs(_pcs);
end;


//               Ha van - akkor kinyomtatja a cimlet(ek)et                                                                                               //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   procedure TatadAtvetform.CimletNyomtatas;
// =============================================================================

begin
  if not Fileexists(_cimletListaPath) then exit;
  FileKiiro(_cimletlistaPath);
end;


//                          Az fpath file  kinyomtatása                                                                            //
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

var _firstval,_aktarfs: string;
    _aktarf: integer;

begin
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
      _aktdnem     := ValutaQuery.FieldByName('VALUTANEM').asstring;
      _aktbankjegy := ValutaQuery.FieldByName('BANKJEGY').asInteger;

      _aktarfolyam := Valutaquery.FieldByName('ARFOLYAM').asInteger;
      _aktelszam   := ValutaQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      _akttortresz := trim(ValutaQuery.fieldbyname('TORTRESZ').asstring);

      if _aktbankjegy=0 then
        begin
          ValutaQuery.next;
          Continue;
        end;

      inc(_devizadarab);

      _xx := scandnem(_aktdnem);

      _devizasor[_devizadarab]    := _xx;
      _devizasum[_devizadarab]    := _aktbankjegy;
      _alaparfolyam[_devizadarab] := _aktarfolyam;
      _elszi[_devizadarab]        := _aktelszam;
      _arftortresz[_devizadarab]  := _akttortresz;

      valutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  if _dtype='DEV' then
    begin
      _xx := 1;
      while _xx<=_devizadarab do
        begin
          _aktarf := _alaparfolyam[_xx];
          _aktbankjegy := _devizasum[_xx];
          _aktarfs    := inttostr(_aktarf);
          _akttortresz := trim(_arftortresz[_xx]);
          while length(_akttortresz)<4 do _akttortresz := _akttortresz + '0';

          if _akttortresz<>'' then _aktarfs := _aktarfs +_akttortresz;
          _aktarfolyam := strtoint(_aktarfs);
          _aktertek := round(_aktarfolyam/1000000*_aktbankjegy);
          _devertek[_xx] := _aktertek;
          inc(_xx);
        end;
    end else
    begin
      _devertek[1] := _devizasum[1];
    end;
end;



//                  Egy TotalFile beolvasása a szerverrõl                                                                                               //
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

  _totalPath := 'C:\ERTEKTAR\' + _totalFilenev;
  result := ftpgetfile(_hftp,pchar(_TotalFilenev),pchar(_totalPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);

  ftpdeletefile(_hFTP,pchar(_totalfilenev));

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

end;


//                                Belépés a szervere
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


// =============================================================================
           procedure TATADATVETFORM.EXITGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;



// =============================================================================
                 procedure TAtadAtvetForm.Fejteteltorles;
// =============================================================================


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


// =============================================================================
              function TatadAtvetForm.realtostr(_r: real):string;
// =============================================================================

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



//       Elöröl kiegésziti 0-kkal a stringet, mig _H hosszú nem lesz                                                                                     //
////////////////////////////////////////////////////////////////////////////////
// ============================================================================
         function TAtadAtvetform.Elokieg(_s: string;_h: byte):string;
// ============================================================================

begin
  result := _s;
  while length(result)<_h do  result := ' '+result;
end;


//                      39 karakter hosszu vonalat nyomtat                                                                                               //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 procedure TatadatvetForm.VonalHuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',39));
end;


//                  Formázva kinyomtat egy négyjegyü számot                                                                                               //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
               function TAtadAtvetForm.negyes(_n: integer): string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<4 do result := ' '+result;
end;


//                  Formázva kinyomtat egy tizenegyjegyü számot                                                                                          //
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



//               Átadás - átvétel  bizonylatszám meghatározása
//         _irany (1 vagy 2) és _dType ('DEV' vagy 'FT') alapján                                                                                     //
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
          _ttema := 'LASTATVET';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>999999 then _ujblokknum := 1;
          result := 'U' + _bizelokod + nulele(_ujblokknum,6);
        end else
        begin
          _ttema := 'LASTFTATVETEL';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>99999 then _ujblokknum := 1;
          result := 'UF' + _bizelokod + nulele(_ujblokknum,5);
        end;
    end else
    begin
      if _dType='DEV' then
        begin
          _ttema := 'LASTATADAS';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>999999 then _ujblokknum := 1;
          result := 'F' + _bizelokod + nulele(_ujblokknum,6);
        end else
        begin
          _ttema := 'LASTFTATADAS';
          _ujblokknum := ValutaQuery.FieldByNAme(_ttema).asInteger;
          inc(_ujblokknum);
          if _ujblokknum>99999 then _ujblokknum := 1;
          result := 'FF' + _bizelokod + nulele(_ujblokknum,5);
        end;
     end;
  Valutaquery.close;
  Valutadbase.close;
end;


//         Az összes valuta elszámolási árfolyamát tömbbe olvassa
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

//                   Végrehajt egy Firebird parancsot                         //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
             procedure TatadatvetForm.ValutaParancs(_ukaz: string);
// =============================================================================

begin
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
  _PCS := '';
  _UKAZ := '';
end;


//                  Egy word beolvasása a bytetombböl
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

//                  Egy integer beolvasása a bytetombböl
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


//                  Egy devizanem-string beolvasása a bytetombböl
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


//                      Megállapitja a pontos idõt
// =============================================================================
                  function TatadatvetForm.Getidos: string;
// =============================================================================

begin
  result := timetostr(Time);
  if ord(result[2])= 58 then result := '0' + result;
end;


//                    Megállapitja egy valuta sorszámát:
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


//                 Egy numbet-format ### ### ### alakra
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


//      A VTemp-bõl beolvassa tarspenztarkod és tarspenztarnev változókat
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


//         A VTemp-bõl beolvassa szallitonev és plombaszam változókat
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



//                Egy szaámstring elé _h darab nullát ir
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

      _printer       := FieldByNAme('PRINTER').asInteger;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      _aktidkod      := trim(FieldByName('IDKOD').AsString);
      _aktprosnev    := trim(FieldByNAme('PENZTAROSNEV').asString);
      _host          := trim(FieldByNAme('HOST').AsString);
    
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
  ElszamBeolvasas;
end;


//               Az alapadatok biztonsági okból való nullára állitása
// =============================================================================
                    procedure TatadAtvetForm.AlapNullazas;
// =============================================================================


begin
  _noselect    := False;
  _devizaDarab := 0;       // nincs egyetlen deviza sem kijelölve

 
  _hufIndex := Scandnem('HUF');
 
end;


// =============================================================================
             procedure TATADATVETFORM.BACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;



// =============================================================================
           procedure TATADATVETFORM.EKERGOMBClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('elektromos kereskedés tranzakcióba kezd'));
  DisappearPanels;
  matpenztarrutin;
  menube;
end;


//                    KEZELÉSI DIJAK ÁTVÉTELE ÁTADÁSA
// =============================================================================
            procedure TATADATVETFORM.KEZDIJGOMBClick(Sender: TObject);
// =============================================================================

begin
  DisappearPanels;
  logirorutin(pchar('Kezdij tranzakcióba kezd'));
  kezdijatadorutin;
  Menube;
end;




//       Bemásolja a sterverren a _totaldir-be (ha kell létrehozza) a
//                 Cimini.1 file-t _totalfilenev néven-
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
  _bennVan  :=  FTPSETCURRENTDIRECTORY(_hFTP,pchar(_totalDir));

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


//  Egy értéktár visszaadja  elözöleg átvett teljes készletet egy péntrárnak
//==============================================================================
              procedure TatadAtvetForm.KeszletvisszaAdas(Sender: TObject) ;
//==============================================================================

begin
  AtadasPanel.Visible   := False;
  menuAlappanel.Visible := False;
  menupanel.Visible     := False;

  BackPtarEdit.clear;
  BackBizonyEdit.clear;
  BackFtBizonyEdit.clear;
  BackDatumedit.clear;

  logirorutin(pchar('Készlet visszaadás tranzakcióba kezd'));
  with AllGiveBackPanel do
    begin
      top     := 260;
      left    := 250;
      Visible := true;
    end;
  Activecontrol := BackPtarEdit;
end;


//         A KÉSZLET VISSZAADÁS PARAMÉTER EDITJEI KERÜLNEK A FOKÚSZBA
//==============================================================================
       procedure TATADATVETFORM.BACKPTAREDITEnter(Sender: TObject);
//==============================================================================

begin
  Tedit(sender).Color := clYellow;
end;


//         A KÉSZLET VISSZAADÁS PARAMÉTER EDITJEI ELVESZTIK A FOKÚSZAIT
//==============================================================================
          procedure TATADATVETFORM.BACKPTAREDITExit(Sender: TObject);
//==============================================================================

begin
  Tedit(sender).Color := clWhite;
end;


//         A KÉSZLET VISSZAADÁS TÁRSPÉNTÁRSZÁM-EDITBEN ENTERT ADOTT
//==============================================================================
        procedure TATADATVETFORM.BACKPTAREDITKeyDown(Sender: TObject;
                        var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := BackBizonyedit;
end;


//         A KÉSZLET VISSZAADÁS BIZONYLATSZÁM-EDIT ENTERT ADOTT
//==============================================================================
        procedure TATADATVETFORM.BACKBIZONYEDITKeyDown(Sender: TObject;
                   var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := BackfTbIZONYEdit;
end;


//         A KÉSZLET VISSZAADÁS FTBIZONYLATSZÁM-EDIT ENTERT ADOTT
//==============================================================================
      procedure TATADATVETFORM.BACKFTBIZONYEDITKeyDown(Sender: TObject;
                       var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  IF ord(KEY)<>13 then exit;
  Activecontrol := BackDatumEdit;
end;


//                 A KÉSZLET VISSZAADÁS DÁTUM-EDIT ENTERT ADOTT               //
//==============================================================================
        procedure TATADATVETFORM.BACKDATUMEDITKeyDown(Sender: TObject;
                     var Key: Word; Shift: TShiftState);
//==============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := giveDataBackOkeGomb;
end;

//      A KÉSZLET VISSZAADÁS PARAMÉTER EDITÁLÁSAKOR MÉGSEM GOMBOT NYOMOTT
//==============================================================================
         procedure TATADATVETFORM.PARAMEGSEMGOMBClick(Sender: TObject);
//==============================================================================

begin
  Modalresult := 1;
end;


//   KÉSZLET VISSZAADÁS PARAMÉTER EDITÁLÁSAKOR ADATOK RENDBEN GOMBOT NYOMOTT
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


//               Teljes valutakészlet átvétele egy pénztártól                 //
// =============================================================================
          procedure TatadAtvetForm.ErtektarAllAtvetel(Sender: TObject);
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

      _pcs := 'INSERT INTO CIMLETPISZKOZAT (VALUTANEM,BANKJEGY,';
      _pcs := _pcs + 'CIMLET1,CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,CIMLET7,';
      _pcs := _pcs + 'CIMLET8,CIMLET9,CIMLET10,CIMLET11,CIMLET12,CIMLET13,';
      _pcs := _pcs + 'CIMLET14)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _aktdnem +chr(39)+',';
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
      _aktbankjegy := Tempquery.FieldbyName('BANKJEGY').asInteger;

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
  Modalresult := 1;
end;



//                 AZ ÖSSZES PANELT ELTÜNTETI A KÉPERNYÕRÕL
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



//                     A CIMLET-TABLA ADATAIT TÖMBÖKBE TÖLTI                  
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


{
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
}

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

  if _cimletType=6 then _alleker := _aktkesz;
//  if _cimletType=8 then _allaxa := _aktkesz;

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

  if _noselect=False then _noselect := true;

  _devsorindex     := Tpanel(Sender).Tag;
  _aktpanel        := _bj[_devsorindex];
  _aktpanel.Color  := clYellow;

  _dnemIndex       := _devizasor[_devsorindex];
  _aktsumertek     := _devizasum[_devsorindex];
  _akttext         := inttostr(_aktsumertek);

end;



// =============================================================================
                    procedure TatadatvetForm.Fejleciro;
// =============================================================================

begin
  AssignFile(_LFile,'C:\ERTEKTAR\aktlst.txt');
  rewrite(_LFile);

  Kozepreir(_penztarnev);
  Kozepreir(_penztarcim);
  VonalHuzo;
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
  //        4: afaatvetel;
          6: ekeratvetel;
 //         8: axaatvetel;
        end;
      inc(_cimlettype);
    end;
end;

// =============================================================================
                   procedure TatadAtvetForm.Kezdijatvetel;
// =============================================================================

var 
    _kezdbe: integer;

begin
  _aktkezdij := _otherKesz[2,1];
  Valutadbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _utbe := FieldByNAme('LASTKEZDIJ').asInteger;
      CLose;
      Sql.clear;
      sql.add('SELECT * FROM KEZDIJDATA');
      Open;
      _kezdij := FieldByName('ZARO').asInteger;
      _kezdbe := FieldByNAme('BEVETEL').asInteger;
      close;
    end;
  Valutadbase.close;
  inc(_utbe);

  _bizonylatszam := 'B-' + nulele(_utbe,6);
  _pcs := 'INSERT INTO KEZDIJ (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,';
  _pcs := _pcs + 'PENZTAR,STORNO)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + '+' + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktkezdij) + ',';
  _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ',';
  _pcs := _pcs + '1)';

  ValutaParancs(_pcs);

  _kezdij := _kezdij + _aktkezdij;
  _pcs := 'UPDATE UTOLSOBLOKKOK SET LASTKEZDIJ='+inttostr(_utbe);
  ValutaParancs(_pcs);

  _pcs := 'UPDATE KEZDIJDATA SET BEVETEL='+inttostr(_kezdbe+_aktkezdij);
  _pcs := _pcs + ',ZARO='+inttostr(_kezdij+_aktkezdij);
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
  logirorutin(pchar('Western Union pénz átvétel'));
  Valutadbase.connected := true;
  with Valutaquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _utbe := FieldByNAme('LASTWUBE').asInteger;
      _uthuf := FieldByName('HUFKESZLET').asInteger;
      _utusd := FieldbyNAme('USDKESZLET').asInteger;
      Close;
    end;

  Valutadbase.close;
  inc(_utbe);
  _aktdnem := _otherdnem[3,1];
  _aktkesz := _otherkesz[3,1];

  if _aktdnem='HUF'  then _uthuf := _uthuf + _aktkesz
  else _utusd := _utusd + _aktkesz;

  _bizonylatszam := 'WB-' + nulele(_utbe,6);
  _pcs := 'INSERT INTO WUAFAFORG (DATUM,BIZONYLAT,VALUTANEM,BANKJEGY,';
  _pcs := _pcs + 'ELOJEL,PENZTAR,BIZTIPUS,STORNO)' + _sorveg;

  _pcs := _pcs + 'VALUES (' +CHR(39)+_megnyitottnap + chr(39)+',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) +',';
  _pcs := _pcs + inttostr(_aktkesz) + ',';
  _pcs := _pcs + chr(39) + '+' + chr(39) + ',';
  _PCS := _pcs + chr(39) + _TARSPENZTARKOD +chr(39)+',';
  _pcs := _pcs + chr(39) + 'WU' + chr(39) + ',1)';

  ValutaParancs(_pcs);

  if _aktdb=2 then
    begin
      _aktdnem := _otherdnem[3,2];
      _aktkesz := _otherkesz[3,2];

      if _aktdnem='HUF'  then _uthuf := _uthuf + _aktkesz
      else _utusd := _utusd + _aktkesz;

      _pcs := 'INSERT INTO WUAFAFORG (DATUM,BIZONYLAT,VALUTANEM,BANKJEGY,';
      _pcs := _pcs + 'ELOJEL,PENZTAR,BIZTIPUS,STORNO)' + _sorveg;
      _pcs := _pcs + 'VALUES ('+CHR(39)+_megnyitottnap + chr(39)+',';
      _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) +',';
      _pcs := _pcs + inttostr(_aktkesz) + ',';
      _pcs := _pcs + chr(39) + '+' + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ',';
      _pcs := _pcs + chr(39)+'WU'+chr(39)+',1)';
      ValutaParancs(_pcs);
    end;

  _pcs := 'UPDATE WUAFAADATOK SET LASTWUBE='+INTTOSTR(_UTBE);
  _pcs := _pcs + ',HUFKESZLET=' + inttostr(_uthuf);
  _pcs := _pcs + ',USDKESZLET=' + inttostr(_utusd);
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

var _utbiz,_akteker: integer;

begin
  _akteker := _otherkesz[6,1];
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _utbiz := FieldByNAme('LASTEKER').asInteger;
      close;
    end;
  Valutadbase.close;

  inc(_utbiz);
  _bizonylatszam := 'B' + nulele(_utbiz,6);
  

  _pcs := 'INSERT INTO EKERESKEDELEM (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,PENZTAR)'+_sorveg;
  _pcs := _pcs + 'VALUES ('+CHR(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + inttostr(_akteker) + ',';
  _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET LASTEKER=' + inttostr(_utbiz);
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


procedure TAtadAtvetForm.hrkgombClick(Sender: TObject);
begin
  DisappearPanels;
  hrkatvevorutin;
  Menube;
end;

end.


