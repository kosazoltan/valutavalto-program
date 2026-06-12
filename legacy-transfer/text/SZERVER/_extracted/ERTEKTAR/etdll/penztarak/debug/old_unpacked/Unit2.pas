unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, wininet, IBDatabase, DB, IBQuery,
  IBCustomDataSet, IBTable, Grids, DBGrids, Buttons, StrUtils, printers,
  Mask, DBCtrls, TeeProcs, TeEngine, Chart, Series, Dateutils, jpeg,
  ComCtrls;

type
  TPillkeszForm = class(TForm)

    FrissitoTimer          : TTimer;

    KeszletTabla           : TibTable;
    KeszletQuery           : TibQuery;
    KeszletDbase           : TibDatabase;
    KeszletTranz           : TibTransaction;
    KeszletSource          : TDataSource;
    ServerDbase            : TIBDatabase;
    ServerQuery            : TIBQuery;
    ServerTranz            : TIBTransaction;
    ValutaQuery            : TIBQuery;
    ValutaDbase            : TIBDatabase;
    ValutaTranz            : TIBTransaction;

    Image1                 : TImage;
    Image2                 : TImage;
    Image3                 : TImage;
    Image4                 : TImage;
    Image5                 : TImage;
    Image6                 : TImage;
    Image7                 : TImage;
    Image8                 : TImage;
    Image9                 : TImage;
    Image10                : TImage;
    Image11                : TImage;
    Image12                : TImage;
    Image13                : TImage;
    Image14                : TImage;
    Image15                : TImage;
    Image16                : TImage;
    Image17                : TImage;
    Image18                : TImage;
    Image19                : TImage;
    Image20                : TImage;
    Image21                : TImage;
    Image22                : TImage;
    Image23                : TImage;
    Image24                : TImage;
    Image25                : TImage;
    Image26                : TImage;
    Image27                : TImage;
    Image28                : TImage;

    KeszletTablaAfa_Ft     : TIntegerField;
    KeszletTablaAUD        : TIntegerField;
    KeszletTablaBGN        : TIntegerField;
    KeszletTablaCAD        : TIntegerField;
    KeszletTablaCHF        : TIntegerField;
    KeszletTablaCNY        : TIntegerField;
    KeszletTablaCZK        : TIntegerField;
    KeszletTablaDKK        : TIntegerField;
    KeszletTablaEkerKeszlet: TIntegerField;
    KeszletTablaEladasFT   : TIntegerField;
    KeszletTablaEUR        : TIntegerField;
    KeszletTablaGBP        : TIntegerField;
    KeszletTablaHRK        : TIntegerField;
    KeszletTablaHUF        : TIntegerField;
    KeszletTablaILS        : TIntegerField;
    KeszletTablaIrodaszam  : TIntegerField;
    KeszletTablaJPY        : TIntegerField;
    KeszletTablaKezelesiDij: TIntegerField;
    KeszletTablaNOK        : TIntegerField;
    KeszletTablaPLN        : TIntegerField;
    KeszletTablaRON        : TIntegerField;
    KeszletTablaRSD        : TIntegerField;
    KeszletTablaRUB        : TIntegerField;
    KeszletTablaSEK        : TIntegerField;
    KeszletTablaTRY        : TIntegerField;
    KeszletTablaUAH        : TIntegerField;
    KeszletTablaUSD        : TIntegerField;
    KeszletTablaVetelFT    : TIntegerField;
    KeszletTablaWU_USD     : TIntegerField;
    KeszletTablaWU_HUF     : TIntegerField;

    KeszletTablaDatum      : TIBStringField;
    KeszletTablaIdo        : TIBStringField;
    KeszletTablaIrodanev   : TIBStringField;

    AdatFrissitoGomb       : TBitBtn;
    ArfolyamGomb           : TBitBtn;
    BitBtn1                : TBitBtn;
    GrafikonGomb           : TBitBtn;
    IrArfolyamGomb         : TBitBtn;
    KilepesGomb            : TBitBtn;
    KordiagramGomb         : TBitBtn;
    VisszaGomb             : TBitBtn;

    Button1                : TButton;
    Button2                : TButton;
    Button3                : TButton;

    Grafikon               : TChart;
    KorDiagram             : TChart;

    GroupBox1              : TGroupBox;

    Label1                 : TLabel;
    Label2                 : TLabel;
    Label3                 : TLabel;
    Label4                 : TLabel;
    Label5                 : TLabel;
    Label6                 : TLabel;
    Label7                 : TLabel;
    Label8                 : TLabel;
    Label9                 : TLabel;
    Label10                : TLabel;

    AdatPanel              : TPanel;
    Ae1Pan                 : TPanel;
    Ae2Pan                 : TPanel;
    Ae3Pan                 : TPanel;
    Ae4Pan                 : TPanel;
    Ae5Pan                 : TPanel;
    Ae6Pan                 : TPanel;
    Ae7Pan                 : TPanel;
    Ae8Pan                 : TPanel;
    Ae9Pan                 : TPanel;
    Ae10Pan                : TPanel;
    Ae11Pan                : TPanel;
    Ae12Pan                : TPanel;
    Ae13Pan                : TPanel;
    Ae14Pan                : TPanel;
    Ae15Pan                : TPanel;
    Ae16Pan                : TPanel;
    Ae17Pan                : TPanel;
    Ae18Pan                : TPanel;
    Ae19Pan                : TPanel;
    Ae20Pan                : TPanel;
    Ae21Pan                : TPanel;
    Ae22Pan                : TPanel;
    Ae23Pan                : TPanel;
    Ae24Pan                : TPanel;
    Ae25Pan                : TPanel;
    Ae26Pan                : TPanel;
    Ae27Pan                : TPanel;
    AfaFtPanel             : TPanel;
    AlsoCimPanel           : TPanel;
    ArfolyamPanel          : TPanel;
    Av1Pan                 : TPanel;
    Av2Pan                 : TPanel;
    Av3Pan                 : TPanel;
    Av4Pan                 : TPanel;
    Av5Pan                 : TPanel;
    Av6Pan                 : TPanel;
    Av7Pan                 : TPanel;
    Av8Pan                 : TPanel;
    Av9Pan                 : TPanel;
    Av10Pan                : TPanel;
    Av11Pan                : TPanel;
    Av12Pan                : TPanel;
    Av13Pan                : TPanel;
    Av14Pan                : TPanel;
    Av15Pan                : TPanel;
    Av16Pan                : TPanel;
    Av17Pan                : TPanel;
    Av18Pan                : TPanel;
    Av19Pan                : TPanel;
    Av20Pan                : TPanel;
    Av21Pan                : TPanel;
    Av22Pan                : TPanel;
    Av23Pan                : TPanel;
    Av24Pan                : TPanel;
    Av25Pan                : TPanel;
    Av26Pan                : TPanel;
    Av27Pan                : TPanel;
    EkerKeszletPanel       : TPanel;
    Elad1Panel             : TPanel;
    Elad2Panel             : TPanel;
    Elad3Panel             : TPanel;
    Elad4Panel             : TPanel;
    Elad5Panel             : TPanel;
    Elad6Panel             : TPanel;
    Elad7Panel             : TPanel;
    Elad8Panel             : TPanel;
    Elad9Panel             : TPanel;
    Elad10Panel            : TPanel;
    Elad11Panel            : TPanel;
    Elad12Panel            : TPanel;
    Elad13Panel            : TPanel;
    Elad14Panel            : TPanel;
    Elad15Panel            : TPanel;
    Elad16Panel            : TPanel;
    Elad17Panel            : TPanel;
    Elad18Panel            : TPanel;
    Elad19Panel            : TPanel;
    Elad20Panel            : TPanel;
    Elad21Panel            : TPanel;
    Elad22Panel            : TPanel;
    Elad23Panel            : TPanel;
    Elad24Panel            : TPanel;
    Elad28Panel            : TPanel;
    Elad27Panel            : TPanel;
    Elad26Panel            : TPanel;
    Elad25Panel            : TPanel;
    EvPanel                : TPanel;
    FoglaloPanel           : TPanel;
    ForintPanel            : TPanel;
    FrissitoPanel          : TPanel;
    FuggonyPanel           : TPanel;
    GrafikonPanel          : TPanel;
    HonevPanel             : TPanel;
    IdoPanel               : TPanel;
    K1Panel                : TPanel;
    K2Panel                : TPanel;
    K3Panel                : TPanel;
    K4Panel                : TPanel;
    K5Panel                : TPanel;
    K6Panel                : TPanel;
    K7Panel                : TPanel;
    K8Panel                : TPanel;
    K9Panel                : TPanel;
    K10Panel               : TPanel;
    K11Panel               : TPanel;
    K12Panel               : TPanel;
    K13Panel               : TPanel;
    K14Panel               : TPanel;
    K15Panel               : TPanel;
    K16Panel               : TPanel;
    K17Panel               : TPanel;
    K18Panel               : TPanel;
    K19Panel               : TPanel;
    K20Panel               : TPanel;
    K21Panel               : TPanel;
    K22Panel               : TPanel;
    K23Panel               : TPanel;
    K24Panel               : TPanel;
    K25Panel               : TPanel;
    K26Panel               : TPanel;
    K27Panel               : TPanel;
    K28Panel               : TPanel;
    KezelesiDijPanel       : TPanel;
    KorForgalomPanel       : TPanel;
    NapszamPanel           : TPanel;
    Panel2                 : TPanel;
    Panel3                 : TPanel;
    Panel4                 : TPanel;
    Panel5                 : TPanel;
    Panel6                 : TPanel;
    Panel7                 : TPanel;
    Panel8                 : TPanel;
    Panel9                 : TPanel;
    Panel10                : TPanel;
    Panel11                : TPanel;
    Panel12                : TPanel;
    Panel13                : TPanel;
    Panel14                : TPanel;
    Panel15                : TPanel;
    Panel17                : TPanel;
    Panel18                : TPanel;
    Panel19                : TPanel;
    Panel20                : TPanel;
    Panel21                : TPanel;
    Panel22                : TPanel;
    Panel23                : TPanel;
    Panel24                : TPanel;
    Panel25                : TPanel;
    Panel26                : TPanel;
    Panel27                : TPanel;
    Panel28                : TPanel;
    Panel29                : TPanel;
    Panel30                : TPanel;
    Panel31                : TPanel;
    Panel32                : TPanel;
    Panel33                : TPanel;
    Panel34                : TPanel;
    Panel35                : TPanel;
    Panel36                : TPanel;
    Panel37                : TPanel;
    Panel38                : TPanel;
    Panel39                : TPanel;
    Panel40                : TPanel;
    Panel41                : TPanel;
    Panel53                : TPanel;
    Panel54                : TPanel;
    Panel55                : TPanel;
    Panel56                : TPanel;
    Panel57                : TPanel;
    Panel58                : TPanel;
    Panel59                : TPanel;
    Panel60                : TPanel;
    Panel61                : TPanel;
    Panel62                : TPanel;
    Panel68                : TPanel;
    Panel70                : TPanel;
    Panel71                : TPanel;
    Panel72                : TPanel;
    Panel73                : TPanel;
    Panel74                : TPanel;
    Panel75                : TPanel;
    Panel82                : TPanel;
    Panel85                : TPanel;
    Panel86                : TPanel;
    Panel87                : TPanel;
    Panel88                : TPanel;
    Panel90                : TPanel;
    Panel91                : TPanel;
    Panel92                : TPanel;
    Panel93                : TPanel;
    Panel94                : TPanel;
    Panel102               : TPanel;
    Panel103               : TPanel;
    Panel106               : TPanel;
    Panel107               : TPanel;
    Panel108               : TPanel;
    Panel109               : TPanel;
    Panel110               : TPanel;
    Panel111               : TPanel;
    Panel130               : TPanel;
    Panel131               : TPanel;
    Panel132               : TPanel;
    Panel133               : TPanel;
    Panel134               : TPanel;
    Panel135               : TPanel;
    Panel136               : TPanel;
    Panel137               : TPanel;
    Panel138               : TPanel;
    Panel139               : TPanel;
    Panel140               : TPanel;
    Panel141               : TPanel;
    Panel142               : TPanel;
    Panel144               : TPanel;
    Panel145               : TPanel;
    Panel146               : TPanel;
    Panel147               : TPanel;
    Panel148               : TPanel;
    Panel149               : TPanel;
    Panel150               : TPanel;
    Panel151               : TPanel;
    Panel152               : TPanel;
    Panel153               : TPanel;
    Panel154               : TPanel;
    Panel155               : TPanel;
    Panel156               : TPanel;
    Panel159               : TPanel;
    Panel143               : TPanel;
    Panel157               : TPanel;
    Panel158               : TPanel;
    Panel160               : TPanel;
    Panel161               : TPanel;
    Panel162               : TPanel;
    PenztarakPanel         : TPanel;
    PenztarnevFocimPanel   : TPanel;
    Ptar1Panel             : TPanel;
    Ptar2Panel             : TPanel;
    Ptar3Panel             : TPanel;
    Ptar4Panel             : TPanel;
    Ptar5Panel             : TPanel;
    Ptar6Panel             : TPanel;
    Ptar7Panel             : TPanel;
    Ptar8Panel             : TPanel;
    Ptar9Panel             : TPanel;
    Ptar10Panel            : TPanel;
    Ptar11Panel            : TPanel;
    Ptar12Panel            : TPanel;
    Ptar13Panel            : TPanel;
    Ptar14Panel            : TPanel;
    Ptar15Panel            : TPanel;
    Ptar16Panel            : TPanel;
    Ptar17Panel            : TPanel;
    Ptar18Panel            : TPanel;
    Ptar19Panel            : TPanel;
    Ptar21Panel            : TPanel;
    Ptar22Panel            : TPanel;
    Ptar23Panel            : TPanel;
    Ptar24Panel            : TPanel;
    Ptar20Panel            : TPanel;
    PTarSzamPanel          : TPanel;
    PtOsszesenPanel        : TPanel;
    TotalPanel             : TPanel;
    ValutaPanel            : TPanel;
    Vet1Panel              : TPanel;
    Vet2Panel              : TPanel;
    Vet3Panel              : TPanel;
    Vet4Panel              : TPanel;
    Vet5Panel              : TPanel;
    Vet6Panel              : TPanel;
    Vet7Panel              : TPanel;
    Vet8Panel              : TPanel;
    Vet9Panel              : TPanel;
    Vet10Panel             : TPanel;
    Vet11Panel             : TPanel;
    Vet12Panel             : TPanel;
    Vet13Panel             : TPanel;
    Vet14Panel             : TPanel;
    Vet15Panel             : TPanel;
    Vet16Panel             : TPanel;
    Vet17Panel             : TPanel;
    Vet18Panel             : TPanel;
    Vet19Panel             : TPanel;
    Vet20Panel             : TPanel;
    Vet21Panel             : TPanel;
    Vet22Panel             : TPanel;
    Vet23Panel             : TPanel;
    Vet24Panel             : TPanel;
    Vet25Panel             : TPanel;
    Vet26Panel             : TPanel;
    Vet27Panel             : TPanel;
    Vet28Panel             : TPanel;
    WHufPanel              : TPanel;
    WUsdPanel              : TPanel;

    NapiKorforgalom        : TPieSeries;

    CsakEladas             : TRadioButton;
    CsakVasarlas           : TRadioButton;

    Shape1                 : TShape;
    Shape2                 : TShape;

    KilepoTimer            : TTimer;
    Panel1: TPanel;
    timeline: TProgressBar;

    procedure AdatDisplay;
    procedure AdatFrissites;
    procedure AdatFrissitoGombClick(Sender: TObject);
    procedure AdatNullazo;
    procedure AdatTablaClear;
    procedure AdatSummazo;
    procedure AlapAdatBeolvasas;
    procedure ArfolyamDisplay(_ptsorszam: byte);
    procedure ArfolyamGombClick(Sender: TObject);
    procedure ArfolyamTombClear;
    procedure ArfolyamTombFeltoltes;
    procedure BitBtn1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure CsakEladasClick(Sender: TObject);
    procedure CsakVasarClick(Sender: TObject);
    procedure Dekodolo(_f: string);
    procedure F1GombClick(Sender: TObject);
    procedure F2GombClick(Sender: TObject);
    procedure F3GombClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FTPSzerverbeBelep;
    procedure FrissitoTimerTimer(Sender: TObject);
    procedure GrafikonDisplay;
    procedure GrafikonGombClick(Sender: TObject);
    procedure GrafikonPanelExit(Sender: TObject);
    procedure IrArfolyamGombClick(Sender: TObject);
    procedure IrodaAdatBeolvasas;
    procedure PkDownload;
    procedure KilepesGombClick(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Kordiagramrutin;
    procedure KorDiagramGombClick(Sender: TObject);
    procedure OsszesDisplay;
    procedure PanelSargito(_y: byte);
    procedure PenztarGombRendezes;
    procedure Pitetolto(_pitetipus: integer);
    procedure PkSelejtezo;
    procedure Ptar1PanelClick(Sender: TObject);
    procedure SerialFree;
    procedure SummaNullazo;
    procedure TombBetoltes;
    procedure VisszaGombClick(Sender: TObject);

    function Arfform(_arf: integer): string;
    function Darabdekod: integer;
    function DnemDekod: string;
    function FtForm(_int: integer): string;
    function GetArfolyamData: boolean;
    function GetPtSorszam(_pknev: string): byte;
    function HunDatetostr(_caldat: TdateTime): string;
    function Intdekodol(_bs: integer): integer;
    function Nulele(_bb: byte): string;
    function Scandnem(_dn: string): integer;
    function ScanLivingSorszam(_pkfile: string): byte;
    function ScanPenztar(_pn: byte): byte;
    function Vaninternet: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PillKeszForm: TPillKeszForm;

  _irodaszam,_livPtNum  : array[1..24] of byte;
  _irodanev,_irodatipus,_livPtNev,_livPkNev,_livPtTyp: array[1..24] of string;
  _irodadarab,_pkdarab,_livPkDarab: byte;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS',
     'JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER','NOVEMBER','DECEMBER');

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                       'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN',
                       'NOK','NZD','PLN','RON','RSD','RUB','SEK','THB','TRY',
                       'UAH','USD');

  _arfdnem: array[1..27] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD');

  _hufindex: integer = 13;

  _bTomb: array[1..737] of byte;

  _pkNev : array[1..24] of string;
  _av,_ae: array[1..27] of TPanel;

  _napivetel,_napieladas: array[1..24] of integer;
  _keszlet,_vetel,_eladas: array[1..24,1..27] of integer;
  _wuusd,_wuhuf,_afa,_eker,_kezdij,_foglalo,_total: array[1..24] of integer;
  _valutaErtek,_forintErtek: array[1..24] of integer;

  _skeszlet,_svetel,_seladas: array[1..27] of integer;
  _swuusd,_swuhuf,_safa,_seker,_skezdij,_sfoglalo,_sTotal: integer;
  _sValutaErtek,_sForintErtek,_xwuusdErtek: integer;

  _aktPanel: TPanel;
  _pszin: array[0..20] of TColor;

  _datum,_ido  : array[1..24] of string;
  _sorveg      : string = chr(13)+chr(10);
  _foglalodnem : array[1..24] of string;

  _varf: array[1..24,1..27] of integer;
  _earf: array[1..24,1..27] of integer;

  // ---------------------------------------------------------------------------

  _pillDir            : string = 'C:\ERTEKTAR\PILLKESZ';
  _arfolyamDat        : string = 'c:\ertektar\arfolyam\arfolyam.dat';
  _binolvas           : File of byte;
  _srec               : TSearchrec;
  _hNet,_hFtp,_hsearch: HINTERNET;

  _host               : string = '185.43.207.99';
  _userid             : string = 'ebc-10%';
  _ftpPassword        : string = 'klc+45%';
  _ftpPort            : integer = 21100;
  _findData           : WIN32_FIND_DATA;

  // ---------------------------------------------------------------------------

  _kpanel,
  _vpanel,
  _epanel : array[1..27] of TPanel;

  _ptPanel: array[1..25] of TPanel;

   _pkFile   : array[1..24] of string;
  _csopTabla : array[1..200] of byte;

  // ---------------------------------------------------------------------------

  _xdatum,_xIdo,_aktdnem,_aktirodanev: string;
  _xk,_xkFt,_xv,_xvFt,_xe,_xeft: array[1..27] of integer;

  _xwuusd,_xwuhuf,_xAfa,_xkezdij,_xEker,_xfoglalo,_counternum: integer;
  _xfogdnem: string;

  _pTag,_lastTag,_ss,_aktIrodaszam,_kk,_pp,_aktPenztar: byte;
  _lastIrodaSorszam,_xx,_aktTag,_aktMtag,_lastMTag,_cc: byte;
  _ertektar: byte;

  _height,_width,_qq,_kodpointer: word;

   _aktForintErtek,_aktValutaErtek,_aktWuUsd,_aktWuHuf,_aktAfa,_aktKezdij: integer;
  _aktEker,_aktfoglalo,_aktirodasorszam,_aktWuUsdErtek,_mResult,_akttotal: integer;
  _kadat,_vAdat,_eAdat,_subcass,_code,_aktertek,_usdelszarf,_aktelszarf: integer;
  _aktkeszlet,_aktkeszletFt,_aktVetel,_aktVetelFt,_akteladas,_akteladasft: integer;

  _nums3,_pcs,_localPath,_remoteFile,_aktFilePath,_aktFile,_aktfogDnem: string;
  _aktdatum,_mamas,_penztarkod,_minta,_aktpkFilenev: string;

  _kellvasarlas,_vanVasarlasTabla,_kellEladas,_vanEladasTabla,_sikeres: boolean;
  _vanFoglalo,_ezOsszesen,_isRateDisp: boolean;

  Vasarlas,Eladas: TBarseries;

  // ---------------------------------------------------------------------------

   _qPtNev : string;
   _qPtszam: byte;
   _qEv,_qHonap,_qNap,_qOra,_qPerc: word;
   _qSumForint,_qSumValuta: integer;
   _qWuusd,_qWuHuf,_qAfa,_qUsdElszarf,_qWuUsdErtek: integer;
   _qEker,_qKezdij,_qFoglalo,_qTotal: integer;

   _qKeszlet,_qKeszletFt,_qVetel,_qEladas: array[1..27] of integer;

   _SumForint,_SumValuta: integer;
   _SumWuusd,_SumWuHuf,_SumAfa,_SumWuUsdErtek: integer;
   _SumEker,_SumKezdij,_SumFoglalo,_SumTotal: integer;

   _SumKeszlet,_SumKeszletFt,_SumVetel,_SumEladas: array[1..27] of integer;

  // ---------------------------------------------------------------------------

function irodaarfolyamrutin: integer; stdcall; external 'c:\ertektar\bin\irarfoly.dll'
                                                     name 'irodaarfolyamrutin';
function penztarakrutin: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
            function penztarakrutin: integer; stdcall;
// =============================================================================

begin
  PillKeszform := TPillkeszform.Create(Nil);
  result := Pillkeszform.showmodal;
  Pillkeszform.ShowModal;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                    PROGRAM INDULÓ PROCEDURÁI                           ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
            procedure TPillkeszForm.FormCreate(Sender: TObject);
// =============================================================================

begin
  _Height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  Top    := trunc((_height-768)/2);
  Left   := trunc((_width-1024)/2);
  Width  := 1024;
  Height := 768;

  ArfolyamPanel.Left    := -1012;
  ArfolyamPanel.Visible := False;

  _isRateDisp := False;
  ArfolyamGomb.Caption  := 'Árfolyamok';

  FrissitoPanel.visible := False;
  FrissitoPanel.Repaint;

  GrafikonGomb.Enabled  := True;
  GrafikonPanel.Visible := False;

  with FuggonyPanel do
    begin
      Top  := 96;
      Left := 11;
      Visible := true;
      Repaint;
    end;

  _mResult := 2;

  _mamas := Hundatetostr(date);
  TombBetoltes;

  _hufindex := scandnem('HUF');

  AlapadatBeolvasas;
  IrodaAdatBeolvasas;
 
  AdatFrissites;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                   AZ ADATOK FELFRISSITÉSE                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   procedure TPillkeszForm.AdatFrissites;
// =============================================================================

begin

  with FrissitoPanel do
    begin
      Top := 380;
      Left := 340;
      Visible := True;
      Repaint;
    end;

  PkDownload;

  if _livpkdarab=0 then
    begin
      Showmessage('NINCSENEK ADATOK !');
      exit;
    end;

  ArfolyamtombFeltoltes;
  Adatsummazo;

  FrissitoTimer.Enabled := False;
  _counterNum           := 0;

  {
  Counter.Caption       := '5';
  Counter.repaint;
  }

  FrissitoTimer.Enabled := true;
  PenztargombRendezes;

  FrissitoPanel.Visible := False;
  FuggonyPanel.Visible  := False;

  Ptar1PanelClick(ptar1panel);
end;

// =============================================================================
           procedure TPillKeszForm.FrissitoTimerTimer(Sender: TObject);
// =============================================================================

begin
  FrissitoTimer.Enabled := False;

  INC(_counterNum);

  Timeline.Position := _counternum;

  if _counternum>11 then
    begin
      AdatFrissitoGombClick(Nil);
      exit;
    end;

  FrissitoTimer.Enabled := True;
end;


//==============================================================================
        procedure TPillkeszForm.AdatFrissitoGombClick(Sender: TObject);
//==============================================================================

begin
  with FrissitoPanel do
    begin
      Top := 380;
      Left := 340;
      Visible := True;
      Repaint;
    end;

  Sleep(1700);

  FrissitoPanel.Visible := false;
  FrissitoTimer.Enabled := False;
  GrafikonPanel.Visible := False;
  modalresult := 2;

end;

//==============================================================================
                procedure TPillkeszForm.PenztarGombRendezes;
//==============================================================================
//
//     A PÉNZTÁRGOMBOK LERENDEZÉSE:

begin
  _qq := 1;
  while _qq<=24 do
    begin
      _aktpanel := _ptPanel[_qq];

      _aktpanel.Caption := '';
      _aktpanel.Enabled := False;
      _aktpanel.Font.Color := clBlack;
      _aktpanel.Color := clWhite;
      _aktpanel.repaint;
      inc(_qq);
    end;

  with PtOsszesenPanel do
    begin
      color := clWhite;
      font.color := clBlack;
      enabled := true;
      repaint;
    end;

  _qq := 1;
  while _qq<=_livPkDarab do
    begin
      _aktPanel := _ptPanel[_qq];
      _aktPanel.Caption := _livPtnev[_qq];
      _aktpanel.repaint;
      _aktPanel.Enabled := True;
      inc(_qq);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////           EGY PÉNZTÁR VAGY KÖRZET ADATAI KIJELZÉSÉNEK KÉRÉSE           ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
               procedure TPillkeszForm.PTAR1PANELClick(Sender: TObject);
// =============================================================================

VAR _aktfileNev: string;

begin
  
  _aktTag := TPanel(sender).Tag;
  if _aktirodasorszam=_akttag then exit;

  if (_isRateDisp) and (_livPtTyp[_aktTag]='E') then exit;

  _aktirodasorszam     := _akttag;
  _aktpanel            := _ptPanel[_akttag];

  if _akttag=25 then _aktirodanev := 'KÖRZET OSSZESEN'
  else _aktirodanev :=  _irodanev[_akttag];

  PanelSargito(_akttag);
  _aktFilenev := _livPkNev[_aktirodasorszam];

  Dekodolo(_aktfileNev);

  if _akttag=25 then
    begin
      OsszesDisplay;
      exit;
    end;

  AdatDisplay;
  Arfolyamdisplay(_aktirodasorszam);
end;

// =============================================================================
               procedure TPillkeszForm.PanelSargito(_y: byte);
// =============================================================================

var i: byte;

begin
  for i := 1 to 25 do
    begin
      _aktpanel := _ptPanel[i];
      _aktPanel.Font.Style := [];
      _aktpanel.Color := clWhite;
      _aktpanel.Font.Color := clBlack;
    end;

  _aktpanel := _ptPanel[_y];
  _aktPanel.Font.Style := [fsBold];
  _aktPanel.Color := clYellow;
  _aktpanel.Font.Color := clRed;
end;


////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                 KÉSZLETEK - FORGALMAK KIJELZÉSE                        ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                      procedure TpillkeszForm.AdatDisplay;
// =============================================================================

var _kp,_vp,_ep: Tpanel;
     _z,_k,_v,_e: integer;

begin
  AdatTablaClear;

  PenztarnevFocimPanel.Caption := _qPtnev;

  PtarSzamPanel.Caption    := inttostr(_qPtszam);
  Evpanel.Caption          := inttostr(_qEv);
  HonevPanel.Caption       := _honev[_qHonap];
  NapszamPanel.Caption     := inttostr(_qNap);
  IdoPanel.Caption         := nulele(_qOra)+':'+nulele(_qPerc);
  ForintPanel.Caption      := FtForm(_qSumForint);
  ValutaPanel.caption      := FtForm(_qSumValuta);
  WUsdPanel.Caption        := FtForm(_qWuUsd);
  WHufPanel.Caption        := Ftform(_qWuHuf);
  AfaFtPanel.Caption       := Ftform(_qAfa);
  EkerkeszletPanel.Caption := FtForm(_qEker);
  KezelesiDijPanel.Caption := FtForm(_qKezdij);
  FoglaloPanel.Caption     := FtForm(_qFoglalo);
  TotalPanel.Caption       := FtForm(_qTotal);

  _z := 1;
  while _z<=27 do
    begin
      _k  := _qKeszlet[_z];
      _v  := _qVetel[_z];
      _e  := _qEladas[_z];
      _kp := _kPanel[_z];
      _vp := _vPanel[_z];
      _ep := _ePanel[_z];

      if _k>0 then _kp.Caption := ftform(_k);
      if _v>0 then _vp.Caption := ftform(_v);
      if _e>0 then _ep.Caption := ftform(_e);

      inc(_z);
    end;
end;

// =============================================================================
                   procedure TPillkeszForm.AdatTablaClear;
// =============================================================================

var i: integer;

begin
  Penztarnevfocimpanel.Caption := '';

  PtarSzamPanel.Caption    := '';
  EvPanel.Caption          := '';
  HonevPanel.Caption       := '';
  NapszamPanel.Caption     := '';
  IdoPanel.Caption         := '';
  ForintPanel.Caption      := '';
  ValutaPanel.Caption      := '';
  WusdPanel.Caption        := '';
  WHufPanel.Caption        := '';
  AfaFtPanel.Caption       := '';
  EkerKeszletPanel.Caption := '';
  KezelesiDijPanel.Caption := '';
  FoglaloPanel.caption     := '';
  TotalPanel.Caption       := '';

  for i := 1 to 27 do
    begin
      _kpanel[i].Caption := '';
      _vPanel[i].Caption := '';
      _ePanel[i].Caption := '';
    end;
end;

// =============================================================================
                      procedure TpillkeszForm.OsszesDisplay;
// =============================================================================

var _kp,_vp,_ep: Tpanel;
     _z,_k,_v,_e: integer;

begin
  AdatTablaClear;

  PenztarnevFocimPanel.Caption := 'KÖRZET PÉNZTÁRAI ÖSSZESEN';
  PtarSzamPanel.Caption    := '-';

  Evpanel.Caption          := '-';
  HonevPanel.Caption       := '-';
  NapszamPanel.Caption     := '-';
  IdoPanel.Caption         := '-';

  ForintPanel.Caption      := FtForm(_SumForint);
  ValutaPanel.caption      := FtForm(_SumValuta);
  WUsdPanel.Caption        := FtForm(_SumWuUsd);
  WHufPanel.Caption        := Ftform(_SumWuHuf);
  AfaFtPanel.Caption       := Ftform(_SumAfa);
  EkerkeszletPanel.Caption := FtForm(_SumEker);
  KezelesiDijPanel.Caption := FtForm(_SumKezdij);
  FoglaloPanel.Caption     := FtForm(_SumFoglalo);
  TotalPanel.Caption       := FtForm(_SumTotal);

  _z := 1;
  while _z<=27 do
    begin
      _k  := _sumKeszlet[_z];
      _v  := _sumVetel[_z];
      _e  := _sumEladas[_z];
      _kp := _kPanel[_z];
      _vp := _vPanel[_z];
      _ep := _ePanel[_z];

      if _k>0 then _kp.Caption := ftform(_k);
      if _v>0 then _vp.Caption := ftform(_v);
      if _e>0 then _ep.Caption := ftform(_e);

      inc(_z);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                 KÖRZET ADATINAK ÖSSZESITÉSE                            ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                     procedure TPillkeszform.AdatSummazo;
// =============================================================================

var _ss,_zz: byte;
    _qFile: string;

begin
  SummaNullazo;

  _ss := 1;
  while _ss<=_livpkdarab do
    begin
      _qFile := _livPkNev[_ss];

      Dekodolo(_qFile);

      _Sumforint := _Sumforint+_qSumForint;
      _SumValuta := _SumValuta+_qSumvaluta;

      _SumWuUsd  := _SumWuUsd + _qWuUsd;
      _SumWuHuf  := _sumWuHuf + _qWuHuf;
      _SumAfa    := _sumAfa + _qAfa;
      _SumEker   := _sumEker + _qEker;
      _SumKezdij := _sumKezdij + _qKezdij;
      _SumFoglalo:= _sumFoglalo + _qFoglalo;
      _SumTotal  := _sumTotal + _qTotal;

      _zz := 1;
      while _zz<=27 do
        begin
          if _zz=_hufindex then
            begin
              _napivetel[_ss]  := _napivetel[_ss] + _qEladas[_zz];
              _napieladas[_ss] := _napiEladas[_ss]+ _qVetel[_zz];
            end;

          _SumKeszlet[_zz]   := _sumKeszlet[_zz]+_qKeszlet[_zz];
          _sumKeszletFt[_zz] := _sumKeszletFt[_zz] + _qKeszletFt[_zz];
          _SumVetel[_zz]     := _sumVetel[_zz] + _qVetel[_zz];
          _SumEladas[_zz]    := _sumEladas[_zz] + _qEladas[_zz];
          inc(_zz);
        end;
      inc(_ss);
    end;
end;


////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                    EGY PK-FILE DEKÓDOLÁSA 'Q' VÁLTOZÓKBA               ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                procedure TPillKeszForm.Dekodolo(_f: string);
// =============================================================================

var _ptss: byte;
    _path: string;
    _olvas: File of byte;

begin
   Adatnullazo;

  _ptss := ScanLivingSorszam(_f);
  if _ptss=0 then exit;

  _path := 'c:\ertektar\pillkesz\'+_f;
  if not FileExists(_path) then exit;

  Assignfile(_olvas,_path);
  reset(_olvas);
  Blockread(_olvas,_btomb,737);
  CloseFile(_olvas);

  _qPtnev := _livPtNev[_ptss];
  _qPtSzam:= _livPtNum[_ptss];

  // ----------------------------------------------------------------------

  _qEv    := _btomb[1];
  _qHonap := _btomb[2];
  _qNap   := _btomb[3];
  _qOra   := _btomb[4];
  _qPerc  := _btomb[5];

  _vanfoglalo := False;
  if _qPerc>=100 then
    begin
      _qPerc      := _qPerc-100;
      _vanfoglalo := true;
    end;

//  _valutadarab :=  _bTomb[6];           // = 27 (valutadarab) CONSTANS
  _kodpointer := 7;

  _cc := 1;
  while _cc<=27 do    // valuta darab= 27
    begin
      _aktdnem     := Dnemdekod;
      _aktkeszlet  := DarabDekod;
      _aktkeszletft:= DarabDekod;
      _aktvetel    := Darabdekod;
      _aktvetelft  := Darabdekod;
      _akteladas   := DarabDekod;
      _akteladasft := Darabdekod;

      _xx := Scandnem(_aktdnem);           // Mi a valuta sorszáma (1..24)

      if _aktdnem='HUF' then _qSumforint := _aktkeszlet
      else _qSumValuta := _qSumValuta + _aktkeszletFt;

      _qKeszlet[_xx]   := _aktkeszlet;
      _qkeszletft[_xx] := _aktkeszletft;
      _qVetel[_xx]     := _aktVetel;
      _qEladas[_xx]    := _akteladas;
      inc(_cc);
    end;


  // Az összes valuta adata fel van dolgozva, jöhet a következő 16 byte
  // ami 4 double-word-ot tartalmaz:

  _qWuUsd  := DarabDekod;  // Az iroda w.u. dollár készlete 1-4
  _qWuHuf  := Darabdekod;  // Az iroda w.u. forint készlete 5-8
  _qAfa    := DarabDekod;  // Az iroda afa készlete 9-12 byte
  _qKezdij := Darabdekod;  // Az aktuális kezelési díj
  _qEker   := Darabdekod;  // Az aktualis e-keredkedelem forintja
  _qFoglalo:= 0;

  _qWuUsdertek := trunc(_qUsdElszarf/100*_qWuUsd);

  _qTotal := _qSumValuta+_qSumForint+_qWuUsdErtek+_qAfa+_qKezdij+_qEker+_qFoglalo;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                          DEKÓDOLÓK                                     ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                        function TPillkeszForm.DnemDekod: string;
// =============================================================================

var _b1,_b2,_l1,_l2,_l3: byte;

begin

  _b1 := _btomb[_kodpointer];
  _b2 := _btomb[_kodpointer+1];
  _kodpointer := _kodPointer + 2;

  _l1 := trunc(_b1/4);
  _l2 := trunc(64*_b1);
  _l2 := trunc(_l2/8);
  _l3 := trunc(_b2/32);
  _l2 := _l2 + _l3;
  _l3 := trunc(8*_b2);
  _l3 := trunc(_l3/8);
  _l1 := _l1 + 64;
  _l2 := _l2 + 64;
  _l3 := _l3 + 64;

  result := chr(_l1)+chr(_l2)+chr(_l3);
end;

// =============================================================================
             function TPillkeszForm.Darabdekod: integer;
// =============================================================================

var _b1,_b2,_b3,_b4: byte;

begin
  _b1 := _btomb[_kodpointer];
  _b2 := _btomb[_kodpointer+1];
  _b3 := _btomb[_kodpointer+2];
  _b4 := _btomb[_kodpointer+3];
  _kodPointer := _kodPointer + 4;

  result := _b1 + trunc(256*_b2)+trunc(65536*_b3)+trunc(256*65536*_b4);
end;

// =============================================================================
           function TPillKeszForm.Intdekodol(_bs: integer): integer;
// =============================================================================

//    Az árfolyamok integer-kódolása

var _b1,_b2,_b3,_b4: byte;
    _real: real;

begin
   _b1 := _btomb[_bs];
   _b2 := _btomb[_bs+1];
   _b3 := _btomb[_bs+2];
   _b4 := _btomb[_bs+3];

   _real := (_b4*65536*256);
   _real := _real + (65536*_b3);
   _real := _real + (256*_b2);
   result:= trunc(_real + _b1);
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                         ADAT-NULLÁZÓ                                   ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   procedure TPillkeszForm.Adatnullazo;
// =============================================================================

var _z: byte;

begin
  _qPtnev     := '';
  _qPtSzam    := 0;
  _qEv        := 0;
  _qHonap     := 0;
  _qNap       := 0;
  _qOra       := 0;
  _qPerc      := 0;
  _qSumforint := 0;
  _qSumValuta := 0;
  _qWuUsd     := 0;
  _qWuHuf     := 0;
  _qAfa       := 0;
  _qEker      := 0;
  _qKezdij    := 0;
  _qFoglalo   := 0;
  _qTotal     := 0;

  _z := 1;
  while _z<=27 do
    begin
      _qKeszlet[_z]   := 0;
      _qKeszletFt[_z] := 0;
      _qVetel[_z]     := 0;
      _qEladas[_z]    := 0;
      inc(_z);
    end;
end;

// =============================================================================
                   procedure TPillkeszForm.SummaNullazo;
// =============================================================================

var _z: byte;

begin
  _Sumforint := 0;
  _SumValuta := 0;
  _SumWuUsd  := 0;
  _SumWuHuf  := 0;
  _SumAfa    := 0;
  _SumEker   := 0;
  _SumKezdij := 0;
  _SumFoglalo:= 0;
  _SumTotal  := 0;


  _z := 1;
  while _z<=27 do
    begin
      _SumKeszlet[_z]   := 0;
      _sumKeszletFt[_z] := 0;
      _SUmVetel[_z]     := 0;
      _SumEladas[_z]    := 0;
      inc(_z);
    end;

  _z := 1;
  while _z<=_livPkDarab do
    begin
      _napiVetel[_z] := 0;
      _napiEladas[_z]:= 0;
      inc(_z);
    end;
end;


////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                  KÜLÖNFÉLE GOMBOK LENYOMÁSA                            ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
         procedure TPillkeszForm.IRARFOLYAMGOMBClick(Sender: TObject);
//==============================================================================

begin
  irodaarfolyamrutin;
end;

// =============================================================================
         procedure TPillkeszForm.ARFOLYAMGOMBClick(Sender: TObject);
// =============================================================================

var _b: integer;

begin
  if _isRateDisp then
    begin
      _isRateDisp := False;
      _b := 12;
      while _b>-1012 do
        begin
          ArfolyamPanel.Left := _b;
          ArfolyamPanel.Repaint;
          Sleep(6);
          _b := _b - 16;
        end;

      irarfolyamgomb.Visible := False;
      irarfolyamgomb.Repaint;

      ArfolyamGomb.Caption := 'Árfolyamok';
      GrafikonGomb.Enabled := true;
      PtOsszesenPanel.Enabled := true;
    end else
    begin
      ArfolyamPanel.Visible := True;
      ArfolyamPanel.repaint;
      
      _isRateDisp := True;
      Arfolyamdisplay(1);
      _B := -1012;
      while _b<=12 do
        begin
          ArfolyamPanel.Left := _b;
          ArfolyamPanel.Repaint;
          Sleep(6);
          _b := _b +16;
        end;

      irarfolyamgomb.Visible := True;
      irarfolyamgomb.Repaint;
      Arfolyamgomb.Caption := 'Készlet/forgalom';

      Grafikongomb.enabled := False;
      PtOsszesenPanel.Enabled := False;
      _aktPanel := Ptar1Panel;
      Ptar1PanelClick(_aktPanel);
    end;
  Arfolyamgomb.Repaint;
end;

// =============================================================================
        procedure TPillkeszForm.GRAFIKONGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kellvasarlas     := True;
  _kelleladas       := False;
  _vanVasarlasTabla := false;
  _vanEladasTabla   := False;

  KorforgalomPanel.visible := False;
  with GrafikonPanel do
    begin
      Top := 0;
      Left := 0;
      Visible := True;
    end;
  FuggonyPanel.Visible := true;
  CsakVasarClick(Nil);
end;

// =============================================================================
           procedure TPillkeszform.KORDIAGRAMGOMBClick(Sender: TObject);
// =============================================================================

begin
  SerialFree;
  KordiagramRutin;
end;

// =============================================================================
              procedure TPillKeszForm.F1GOMBClick(Sender: TObject);
// =============================================================================

begin
  KorDiagram.Title.Text.Text := 'MAI NAPI VÁSÁRLÁSOK';
  Pitetolto(1);
end;

// =============================================================================
              procedure TPillkeszForm.F2GOMBClick(Sender: TObject);
// =============================================================================

begin
  KorDiagram.Title.Text.Text := 'MAI NAPI ELADÁSOK';
  Pitetolto(2);
end;

// =============================================================================
               procedure TPillkeszForm.F3GOMBClick(Sender: TObject);
// =============================================================================

begin
  kORDIAGRAM.Title.Text.Text := 'MAI NAPI TELJES FORGALOM';
  Pitetolto(3);
end;




////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                          ARFOLYAMKIJELZÉS                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                procedure TPillKeszForm.ArfolyamtombFeltoltes;
// =============================================================================

var _cc,_aktpt,_sajcsop,_valss: byte;
    _start: integer;

// Feladata: letölti az arfolyam.dat-t és feltölti varf,earf[irodass,valss] tömböt

begin
  // Letölti az NR...dat file-t c:\ertektar\arfolyam\arfolyam.dat néven)

  ArfolyamTombClear;

  if not Getarfolyamdata then exit;

  Assignfile(_binolvas,_arfolyamdat);
  Reset(_binolvas);
  Blockread(_binolvas,_csoptabla,1);
  Blockread(_binolvas,_csoptabla,200);

  _cc := 1;
  while _cc<=_livPkdarab do
    begin
      if _livPtTyp[_cc]='E' then
        begin
          inc(_cc);
          continue;
        end;

      _aktpt   := _livPtNum[_cc];
      _sajcsop := _csoptabla[_aktpt];
      if _sajcsop=0 then _sajcsop := 3;

      _start := 201 + trunc((_sajcsop-1)*1221);

      Reset(_binolvas);
      Seek(_binolvas,_start);

      _valss := 1;
      while _valss<=27 do
        begin
          _aktdnem := _arfdnem[_valss];

          // Az euró érme a HUF helyére kerül:

          If _aktdnem='EUA' then _xx := _hufindex
          else _xx := Scandnem(_aktdnem);

          BlockRead(_binolvas,_btomb,45);

          _aktelszarf    := intdekodol(1);
          _vArf[_cc,_xx] := intdekodol(6);
          _earf[_cc,_xx] := intdekodol(11);

          inc(_valss);
        end;
      inc(_cc);
    end;
  Closefile(_binOlvas);
end;



// =============================================================================
           procedure TPillkeszForm.Arfolyamdisplay(_ptsorszam: byte);
// =============================================================================

var _z: byte;
    _aktvpanel,_aktepanel: TPanel;
    _aktvarf,_aktearf: integer;

begin
  for _z := 1 to 27 do
    begin
      _aktvpanel := _av[_z];
      _aktePanel := _ae[_z];

      _aktvPanel.caption := '';
      _aktePanel.caption := '';

      _aktvPanel.repaint;
      _aktePanel.repaint;
    end;

  _z := 1;
  while _z<=27 do
    begin
      _aktvPanel := _av[_z];
      _aktePanel := _ae[_z];

      _aktvarf   := _varf[_ptsorszam,_z];
      _aktearf   := _earf[_ptsorszam,_z];

      _aktvPanel.caption := arfform(_aktvarf);
      _aktePanel.caption := arfform(_aktearf);

      _aktvPanel.repaint;
      _aktePanel.repaint;
      inc(_z);
    end;
end;

// =============================================================================
                    procedure TPIllkeszForm.ArfolyamTombClear;
// =============================================================================

var _ird,_val: byte;

begin
  _ird := 1;
  while _ird<=24 do
    begin
      _val := 1;
      while _val<=27 do
        begin
          _varf[_ird,_val] := 0;
          _earf[_ird,_val] := 0;
          inc(_val);
        end;
      inc(_ird);
    end;
end;




// =============================================================================
            procedure TPillkeszForm.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := False;
  FrissitoTimer.Enabled := False;
  Modalresult := 1;
end;






//==============================================================================
////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                        G R A F I K O N O K                             ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
//==============================================================================
                  procedure TpillKeszForm.GrafikonDisplay;
// =============================================================================

var i:integer;
    _maxi,_sb,_se: real;

begin

  with GrafikonPanel do
    begin
      Top     := 0;
      Left    := 0;
      Visible := True;
    end;

  _maxi := 0;
  with Grafikon do
    begin
      Visible := False;
      Left    := 1;
      Top     := 0;
      Width   := 1018;
      Height  := 570;

      AllowPanning      := pmNone;
      AnimatedZoom      := true;
      AnimatedZoomSteps := 10;

      // ------------------------- HÁTSÓ FAL -----------------------------------

      with BackWall do
        begin
          Brush.Color := clWhite;
          Brush.Style := bsClear;
          Color := clSilver;
        end;

      // --------------------------ALSÓ FAL ------------------------------------

      BottomWall.Dark3D := False;

      with Gradient do
        begin
          StartColor := clAqua;
          EndColor := clBlue;
          Visible := true;
        end;

      // -------------------  BAL FAL  -----------------------------------------

      LeftWall.Color := clWhite;
      BackColor := clSilver;

      // ------------------------------ALSÓ TENGELY ----------------------------

      with BottomAxis do
        begin
          Automatic        := False;
          AutomaticMaximum := False;
          AutomaticMinimum := False;
          Axis.Color       := clNavy;
          Axis.Mode        := pmBlack;
          Axis.Width       := 1;

          Grid.Color       := clSilver;
          Increment        := 1;
          Maximum          := 21;
          MinorTickCount   := 7;
          EndPosition      := 90;
          Labels := False;
          LabelStyle       := talText;

          with Title do
            begin
              Caption      := '';   // 'Pénztárak számai';
              Font.Charset := default_charset;
              Font.Color   := clBlack;
              Font.Height  := -16;
              Font.Name    := 'arial';
              Font.Style   := [fsBold];
            end;
        end;

      DepthAxis.Visible := true;

      // --------------------- BAL TENGELY -------------------------------------

      with LeftAxis do
        begin
          Automatic        := False;
          AutomaticMAximum := False;
          AutomaticMinimum := False;

          with Title do
            begin
              Caption      := 'MAI FORGALOM (Ft)';
              Font.Color   := clBlack;
              Font.Height  := -16;
              Font.Name    := 'Times new Roman';
              Font.Style   := [fsBold];
            end;
        end;

      // -------------------------- MEGJEGYZÉS  --------------------------------

      with Legend do
        begin
          Inverted    := True;
          ShadowColor := clNAvy;
          ShadowSize  := 0;
          Legendstyle := lsseries;
        end;

      // ----------------------------- JOBB TENGELY ----------------------------

      with RightAxis do
        begin
          Automatic        := False;
          AutomaticMaximum := False;
          AutomaticMinimum := False;
        end;

      view3dWalls := False;
    end;

  if _kellvasarlas then
    begin
      Vasarlas             := TBarSeries.Create(Grafikon);
      Vasarlas.ParentChart := Grafikon;
      _vanVasarlasTabla    := True;
      Alsocimpanel.Caption := 'A MAI NAPI VÁSÁRLÁSOK (Ft)';
      AlsoCimpanel.repaint;

      with Vasarlas do
        begin
          Add(0,'0',clBlack);
          for i := 1 to _livPkDarab do Add(i,inttostr(_livPtNum[i]),clBlack);

          Marks.Visible     := True;
          Marks.ArrowLength := 0;
          Marks.Visible     := True;
          SeriesColor       := clYellow;
          BarWidthPercent   := 25;
          Name              := 'VASARLAS';
          OffsetPercent     := 15;

          with XValues do
            begin
              Name          := 'X';
              MultiPlier    := 1;
              Order         := loAscending;
            end;

          with YValues do
            begin
              Name          := 'Bar';
              MultiPlier    := 1;
              Order         := loNone;
            end;
        end;

      for i := 1 to _livPkDarab do            // @@@@
         begin
           _sb := _NapiEladas[i];
           Vasarlas.AddXY(i,_sb);
           if _sb>_maxi then _maxi := _sb;
         end;
    end;

  if _kellEladas then
    begin
      Eladas               := TBarSeries.Create(Grafikon);
      Eladas.ParentChart   := Grafikon;
      _vaneladasTabla      := true;
      Alsocimpanel.Caption := 'A MAI NAPI ELADÁSOK (Ft)';
      AlsoCimpanel.repaint;


      with Eladas do
         begin
           Add(0,'0',clBlack);
           for i := 1 to _livPkDarab do Add(i,inttostr(_livPtnum[i]),clBlack);
           Marks.Visible     := True;
           Marks.ArrowLength := 0;
           Marks.Visible     := True;
           SeriesColor       := clRed;
           BarWidthPercent   := 25;
           Name              := 'ELADAS';
           OffsetPercent     := 15;

           with XValues do
             begin
               Name          := 'X';
               MultiPlier    := 1;
               Order         := loAscending;
             end;

           with YValues do
             begin
               Name          := 'Bar';
               Multiplier    := 1;
               Order         := loNone;
             end;
         end;

      for i := 1 to _livPkDarab do       // @@@@
        begin
          _se := _NapiVetel[i];
          Eladas.addxy(i,_se);
          if _se>_maxi then _maxi := _se;
        end;
    end;

//  ErtekValtas;


  with Grafikon do
    begin
      LeftAxis.Maximum   := (1.1*_maxi);
      BottomAxis.Maximum := _livPkDarab;
      Visible            := True;
    end;
 // ActiveControl := Kordiagramgomb;
end;



// =============================================================================
            procedure TPillkeszForm.CSAKVASARClick(Sender: TObject);
// =============================================================================

begin
  SerialFree;
  _kellvasarlas := True;
  _kelleladas   := false;
  GrafikonDisplay;
end;

// =============================================================================
              procedure TPillKeszForm.CSAKELADASClick(Sender: TObject);
// =============================================================================

begin
   SerialFree;
  _kelleladas := true;
  _kellvasarlas := false;
  GrafikonDisplay;
end;

// =============================================================================
            procedure TPillkeszform.GRAFIKONPANELExit(Sender: TObject);
// =============================================================================

begin
   SerialFree;
end;



// =============================================================================
                  procedure TPillKeszForm.Kordiagramrutin;
// =============================================================================

begin

  Kordiagram.Top := 0;
  Kordiagram.Left := 0;

  with KorForgalomPanel do
    begin
      Top      := 0;
      Left     := 0;
      Visible  := true;
    end;

  _pszin[0]  := clGreen;
  _pszin[1]  := clYellow;
  _pszin[2]  := clRed;
  _pszin[3]  := clBlue;
  _pszin[4]  := clLime;
  _pszin[5]  := clFuchsia;
  _pszin[6]  := clwhite;
  _pszin[7]  := clBlack;
  _pszin[8]  := clPurple;
  _pszin[9]  := clAqua;
  _pszin[10] := clMoneyGreen;
  _pszin[11] := clNavy;
  _pszin[12] := clTeal;
  _pszin[13] := clOlive;
  _pszin[14] := clInactiveCaptiontext;
  _pszin[15] := clSilver;
  _pszin[16] := clSkyBlue;
  _pszin[17] := clScrollBar;
  _pszin[18] := $B0FFFF;
  _pszin[19] := $FFB0FF;
  _pszin[20] := $FFFFB0;

  KorDiagram.Title.Text.Text := 'A MAI NAPI VÁSÁRLÁSOK';
  Pitetolto(1);
end;

// =============================================================================
              procedure TPillkeszform.Pitetolto(_pitetipus: integer);
// =============================================================================

var i,_ss:integer;
   _megnevezes: string;
   _sumVet,_sumElad,_sumForg: real;

begin

  NapiKorforgalom.Clear;
  _ss := -1;
  for i:= 1 to _livPkDarab do
    begin
      _megnevezes := trim(_livPtNev[i]);
      _sumVet  := _napieladas[i];
      _sumElad := _napiVetel[i];
      _sumForg := _sumvet+_sumelad;

      case _piteTipus of
      1: begin
           if _sumvet>0 then
             begin
                inc(_ss);
                NapiKorforgalom.addpie(_sumvet,_megnevezes,_pszin[_ss]);
             end;
          end;

      2: begin
           if _sumElad>0 then
             begin
               inc(_ss);
               NapiKorforgalom.addpie(_sumElad,_megnevezes,_pszin[_ss]);
             end;
         end;

      3: begin
           if _sumforg>0 then
              begin
                inc(_ss);
                NapiKorforgalom.addpie(_sumForg,_megnevezes,_pszin[_ss]);
              end;
         end;
      end;
    end;
end;

// =============================================================================
             procedure TPillKeszForm.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  KorForgalomPanel.Visible := False;
  GrafikonDisplay;
end;



// =============================================================================
                        procedure TPillkeszform.SerialFree;
// =============================================================================


begin
  if _vanVasarlasTabla then
    begin
      Vasarlas.Free;
      _vanVasarlasTabla := False;
    end;

  if _vanEladasTabla then
    begin
      Eladas.Free;
      _vanEladasTabla := False;
    end;
end;

// =============================================================================
             function TPillkeszForm.Scandnem(_dn: string): integer;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  result := 0;
  while _y<=27 do
    begin
      if _dnem[_y]=_dn then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                procedure TPillkeszform.Button5Click(Sender: TObject);
// =============================================================================

begin
  KorForgalomPanel.visible := false;
end;

// =============================================================================
            procedure TPillkeszForm.Button9Click(Sender: TObject);
// =============================================================================

begin
  kORFORGALOMPANEL.Visible := FALSE;
  GrafikonDisplay;
end;

// =============================================================================
             procedure TPillkeszForm.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  serialfree;
  Fuggonypanel.Visible := false;
  GrafikonPanel.Visible := false;
end;

// =============================================================================
             procedure TPILLKESZForm.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  FrissitoTimer.Enabled := False;
  Kilepotimer.Enabled   := True;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                     ADATLETÖLTÉS A SZERVERRŐL                          ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                      procedure TPillKeszForm.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then exit;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then InternetCloseHandle(_hNet);
end;

// =============================================================================
               function TPillkeszForm.GetArfolyamData: boolean;
// =============================================================================

var _aktNRFile: string;

begin
  result := False;
  FTPSzerverbeBelep;

  if _hFtp=NIL then exit;

  result :=  FTPSetCurrentDirectory(_hFTP,pchar('\ARFOLYAM'));
  if result then
    begin
      _hSearch := FTPFindFirstFile(_hFTP,'NR*.DAT',_findData,0,0);

      if _hsearch=NIL then
        begin
          Result := false;
          InternetCloseHandle(_hFTP);
          InternetCloseHandle(_hNet);
          exit;
        end;
    end;

  _aktNRFile := _finddata.cFileName;
  InternetCloseHandle(_hsearch);

  _localPath := _arfolyamDat;
  if fileexists(_localpath) then sysutils.DeleteFile(_localpath);
  result := ftpgetfile(_hftp,pchar(_aktNrFile),pchar(_localPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

// =============================================================================
                     procedure TPillkeszForm.PkDownLoad;
// =============================================================================

(*   Feladat: A szerver  \ PILLKESZ könyvtárból az összes PK*.*
              mintájú file-t letölti (felülirja) a c:\ERTEKTAR\pillkesz
              könyvtárba:(amennyiben a penztarkodja
*)


var _aktFileNev: string;

begin
  _livPkDarab :=0;

  if not vanInternet then
    begin
      PkSelejtezo;
      Exit;
    end;

  FTPSzerverbeBelep;
  if _hFtp=Nil then exit;

  // ---------------------------------------------------------------------------

  _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\PILLKESZ'));
  if not _sikeres then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  _minta := 'pk*.'+inttostr(_ertektar);
  _hSearch := FTPFindFirstFile(_hFTP,pchar(_minta),_findData,0,0);
  if _hSearch=nil then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  _pkdarab := 0;
  repeat
    inc(_pkdarab);
    _aktfilenev := _findData.cFileName;
    _xx := GetPtSorszam(_aktfilenev);
    _pkFile[_xx] := _aktfilenev;
  until not InternetFindNextFile(_hSearch,@_findData);
  InternetCloseHandle(_hSearch);

  // ---------------------------------------------------------------------------

  _qq := 1;
  while _qq<=_pkDarab do
    begin
      _aktfilenev := _pkfile[_qq];
      _remoteFile := _aktfilenev;
      _localPath  := 'c:\ertektar\pillkesz\' + _aktfilenev;

      if FileExists(_localPath) then Deletefile(_localPath);

      FTPGetfile(_hFTP,pchar(_remoteFile),pchar(_localPath),false,
                                                  0,FTP_TRANSFER_TYPE_BINARY,0);
      inc(_qq);
    end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
  PKSelejtezo;
end;

// =============================================================================
                    procedure TPillkeszForm.PkSelejtezo;
// =============================================================================

var _nev,_ppath: string;
    _len: word;

begin
  _qq := 0;
  _minta := 'c:\ertektar\pillkesz\PK*.'+inttostr(_ertektar);

  if FindFirst(_minta, faAnyFile, _srec)=0 then
    begin
      repeat
        _len := _srec.Size;
        _nev := _srec.Name;
        _xx := GetPtSorszam(_nev);

        if (_len<>737) or (_xx=0) then
          begin
            _ppath := 'c:\ertektar\pillkesz\'+_nev;
            sysutils.DeleteFile(_ppath);
          end else
          begin
            inc(_qq);
            _Pknev[_qq] := _nev;
          end;

      until FindNext(_srec) <> 0;
      FindClose(_srec);
      _pkDarab := _qq;
    end;

  if _pkdarab=0 then
    begin
      _livPkDarab := 0;
       exit;
    end;

  // -------------------------------------------------------------

  _cc := 0;
  _qq := 1;
  while _qq<=_pkdarab do
    begin
      _aktPkFileNev := _pkNev[_qq];
      _xx := getPtSorszam(_aktPkFilenev);
      if _xx>0 then
        begin
          inc(_cc);
          _livPtNev[_cc] := _irodanev[_xx];
          _livPtNum[_cc] := _irodaszam[_xx];
          _livPtTyp[_cc] := _irodatipus[_xx];
          _livPkNev[_cc] := _aktPkFileNev;
        end;
      inc(_qq);
    end;
  _livPkDarab := _cc;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                     ADAT BEOLVASÁS - ADATRENDEZÉS                      ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                    procedure TPIllkeszForm.TombbeToltes;
// =============================================================================

begin
  _ptPanel[1] := Ptar1Panel;
  _ptPanel[2] := Ptar2Panel;
  _ptPanel[3] := Ptar3Panel;
  _ptPanel[4] := Ptar4Panel;
  _ptPanel[5] := Ptar5Panel;
  _ptPanel[6] := Ptar6Panel;
  _ptPanel[7] := Ptar7Panel;
  _ptPanel[8] := Ptar8Panel;
  _ptPanel[9] := Ptar9Panel;
  _ptPanel[10]:= Ptar10Panel;
  _ptPanel[11]:= Ptar11Panel;
  _ptPanel[12]:= Ptar12Panel;
  _ptPanel[13]:= Ptar13Panel;
  _ptPanel[14]:= Ptar14Panel;
  _ptPanel[15]:= Ptar15Panel;
  _ptPanel[16]:= Ptar16Panel;
  _ptPanel[17]:= Ptar17Panel;
  _ptPanel[18]:= Ptar18Panel;
  _ptPanel[19]:= Ptar19Panel;
  _ptPanel[20]:= Ptar20Panel;
  _ptPanel[21]:= Ptar21Panel;
  _ptPanel[22]:= Ptar22Panel;
  _ptPanel[23]:= Ptar23Panel;
  _ptPanel[24]:= Ptar24Panel;
  _ptPanel[25]:= PtOsszesenPanel;

  _kPanel[1] := K1PANEL;
  _kPanel[2] := K2PANEL;
  _kPanel[3] := K3PANEL;
  _kPanel[4] := K4PANEL;
  _kPanel[5] := K5PANEL;
  _kPanel[6] := K6PANEL;
  _kPanel[7] := K7PANEL;
  _kPanel[8] := K8PANEL;
  _kPanel[9] := K9PANEL;
  _kPanel[10]:= K10PANEL;
  _kPanel[11]:= K11PANEL;
  _kPanel[12]:= K12PANEL;
  _kPanel[13]:= K13PANEL;
  _kPanel[14]:= K14PANEL;
  _kPanel[15]:= K15PANEL;
  _kPanel[16]:= K16PANEL;
  _kPanel[17]:= K17PANEL;
  _kPanel[18]:= K18PANEL;
  _kPanel[19]:= K19PANEL;
  _kPanel[20]:= K20PANEL;
  _kPanel[21]:= K21PANEL;
  _kPanel[22]:= K22PANEL;
  _kPanel[23]:= K23PANEL;
  _kPanel[24]:= K24PANEL;
  _kPanel[25]:= K25PANEL;
  _kPanel[26]:= K26PANEL;
  _kPanel[27]:= K27PANEL;

  _vPanel[1] := VET1PANEL;
  _vPanel[2] := VET2PANEL;
  _vPanel[3] := VET3PANEL;
  _vPanel[4] := VET4PANEL;
  _vPanel[5] := VET5PANEL;
  _vPanel[6] := VET6PANEL;
  _vPanel[7] := VET7PANEL;
  _vPanel[8] := VET8PANEL;
  _vPanel[9] := VET9PANEL;
  _vPanel[10]:= VET10PANEL;
  _vPanel[11]:= VET11PANEL;
  _vPanel[12]:= VET12PANEL;
  _vPanel[13]:= VET13PANEL;
  _vPanel[14]:= VET14PANEL;
  _vPanel[15]:= VET15PANEL;
  _vPanel[16]:= VET16PANEL;
  _vPanel[17]:= VET17PANEL;
  _vPanel[18]:= VET18PANEL;
  _vPanel[19]:= VET19PANEL;
  _vPanel[20]:= VET20PANEL;
  _vPanel[21]:= VET21PANEL;
  _vPanel[22]:= VET22PANEL;
  _vPanel[23]:= VET23PANEL;
  _vPanel[24]:= VET24PANEL;
  _vPanel[25]:= VET25PANEL;
  _vPanel[26]:= VET26PANEL;
  _vPanel[27]:= VET27PANEL;

  _ePanel[1] := ELAD1PANEL;
  _ePanel[2] := ELAD2PANEL;
  _ePanel[3] := ELAD3PANEL;
  _ePanel[4] := ELAD4PANEL;
  _ePanel[5] := ELAD5PANEL;
  _ePanel[6] := ELAD6PANEL;
  _ePanel[7] := ELAD7PANEL;
  _ePanel[8] := ELAD8PANEL;
  _ePanel[9] := ELAD9PANEL;
  _ePanel[10]:= ELAD10PANEL;
  _ePanel[11]:= ELAD11PANEL;
  _ePanel[12]:= ELAD12PANEL;
  _ePanel[13]:= ELAD13PANEL;
  _ePanel[14]:= ELAD14PANEL;
  _ePanel[15]:= ELAD15PANEL;
  _ePanel[16]:= ELAD16PANEL;
  _ePanel[17]:= ELAD17PANEL;
  _ePanel[18]:= ELAD18PANEL;
  _ePanel[19]:= ELAD19PANEL;
  _ePanel[20]:= ELAD20PANEL;
  _ePanel[21]:= ELAD21PANEL;
  _ePanel[22]:= ELAD22PANEL;
  _ePanel[23]:= ELAD23PANEL;
  _ePanel[24]:= ELAD24PANEL;
  _ePanel[25]:= ELAD25PANEL;
  _ePanel[26]:= ELAD26PANEL;
  _ePanel[27]:= ELAD27PANEL;

  _av[1] := av1Pan;
  _ae[1] := ae1Pan;
  _av[2] := av2Pan;
  _ae[2] := ae2Pan;
  _av[3] := av3Pan;
  _ae[3] := ae3Pan;
  _av[4] := av4Pan;
  _ae[4] := ae4Pan;
  _av[5] := av5Pan;
  _ae[5] := ae5Pan;
  _av[6] := av6Pan;
  _ae[6] := ae6Pan;
  _av[7] := av7Pan;
  _ae[7] := ae7Pan;
  _av[8] := av8Pan;
  _ae[8] := ae8Pan;
  _av[9] := av9Pan;
  _ae[9] := ae9Pan;
  _av[10]:= av10Pan;
  _ae[10]:= ae10Pan;
  _av[11]:= av11Pan;
  _ae[11]:= ae11Pan;
  _av[12]:= av12Pan;
  _ae[12]:= ae12Pan;
  _av[13]:= av13Pan;
  _ae[13]:= ae13Pan;
  _av[14]:= av14Pan;
  _ae[14]:= ae14Pan;
  _av[15]:= av15Pan;
  _ae[15]:= ae15Pan;
  _av[16]:= av16Pan;
  _ae[16]:= ae16Pan;
  _av[17]:= av17Pan;
  _ae[17]:= ae17Pan;
  _av[18]:= av18Pan;
  _ae[18]:= ae18Pan;
  _av[19]:= av19Pan;
  _ae[19]:= ae19Pan;
  _av[20]:= av20Pan;
  _ae[20]:= ae20Pan;
  _av[21]:= av21Pan;
  _ae[21]:= ae21Pan;
  _av[22]:= av22Pan;
  _ae[22]:= ae22Pan;
  _av[23]:= av23Pan;
  _ae[23]:= ae23Pan;
  _av[24]:= av24Pan;
  _ae[24]:= ae24Pan;
  _av[25]:= av25Pan;
  _ae[25]:= ae25Pan;
  _av[26]:= av26Pan;
  _ae[26]:= ae26Pan;
  _av[27]:= av27Pan;
  _ae[27]:= ae27Pan;
end;

//==============================================================================
                 procedure TPillKeszFORM.AlapAdatBeolvasas;
// =============================================================================

//  Beolvassa az Értékár-számát és az USD elszámolási árfolyamát
//

begin
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'USD'+chr(39);

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').AsString);
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _qUsdElszarf := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      Close;
    end;
  Valutadbase.close;
  val(_penztarkod,_ertektar,_Code);
end;

//==============================================================================
                 procedure TPillKeszFORM.IrodaAdatBeolvasas;
// =============================================================================

var _uzlet: byte;
    _uznev,_status: string;

begin
  _qq := 1;

  while _qq<=24 do
    begin
      _irodanev[_qq]   := '';
      _irodaszam[_qq]  := 0;
      _irodaTipus[_qq] := '';
      inc(_qq);
    end;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (CLOSED<>'+chr(39)+'X'+chr(39)+')';
  _pcs := _pcs + ' AND (ERTEKTAR=' +inttostr(_ertektar)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  with ServerDbase do
    begin
      Close;
      DatabaseName := '185.43.207.99:C:\RECEPTOR\DATABASE\RECEPTOR.FDB';
      Connected := true;
    end;

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _qq := 0;
  while not ServerQuery.Eof do
    begin
      _uzlet := Serverquery.FieldbyName('UZLET').asInteger;
      _uznev := trim(ServerQuery.fieldByName('KESZLETNEV').AsString);
      _status:= ServerQuery.FieldByNAme('STATUS').asString;

      inc(_qq);

      _irodaSzam[_qq]  := _uzlet;
      _Irodanev[_qq]   := _uznev;
      _irodatipus[_qq] := _status;

      ServerQuery.next;
    end;
  ServerQuery.close;
  Serverdbase.close;

  _irodadarab:= _qq;

end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                FONTOS FUNKCIÓK - SEGÉD PROGRAMOK                       ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 function TPillKeszForm.Vaninternet: boolean;
// =============================================================================

var
    _dwConnType: integer;

begin

   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := True;
   except
   end;
end;

// =============================================================================
             function TPillkeszForm.Nulele(_bb: byte): string;
// =============================================================================

begin
  result := inttostr(_bb);
  if _bb<10 then result := '0' + result;
end;

// =============================================================================
         function TPillkeszForm.Arfform(_arf: integer): string;
// =============================================================================

var _w: byte;

begin
  result := inttostr(_arf);
  _w := length(result);
  result := leftstr(result,_w-2)+','+midstr(result,_w-1,2);
end;

// =============================================================================
          function TPillkeszForm.GetPtSorszam(_pknev: string): byte;
// =============================================================================

var _pks: string;
    _n: integer;

begin
  _pks := midstr(_pknev,3,3);
  Val(_pks,_n,_code);
  if _code<>0 then _n := 0;
  result := ScanPenztar(_n);
end;

// =============================================================================
            function TPillkeszForm.ScanPenztar(_pn: byte): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=_irodaDarab do
    begin
      if _irodaszam[_z]=_pn then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
        function TPillkeszForm.ScanLivingSorszam(_pkfile: string): byte;
// =============================================================================

var _ps: string;
    _q,_pn: byte;

begin
  result := 0;

  _ps := midstr(_pkfile,3,3);
  val(_ps,_pn,_code);
  if _code<>0 then exit;

  _q := 1;
  while _q<=_livPkDarab do
    begin
      if _livPtnum[_q]=_pn then
        begin
          result := _q;
          exit;
        end;
      inc(_q);
    end;
end;


// =============================================================================
             function TPillkeszform.FtForm(_int: integer): string;
// =============================================================================

var _WN,_F1: integer;

begin
  result := '';
  if _int=0 then exit;

  result := inttostr(_int);
  if _int<1000 then exit;

  _wn := length(result);
  if _wn>6 then
    begin
      _f1 := _wn-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _wn-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
       function TPillkeszForm.HunDateTostr(_calDat: TDatetime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;

begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;



end.




