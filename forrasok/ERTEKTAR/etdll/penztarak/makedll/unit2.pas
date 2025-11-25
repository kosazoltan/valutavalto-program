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
    BitBtn1                : TBitBtn;
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
    FrissitoPanel          : TPanel;
    FuggonyPanel           : TPanel;
    GrafikonPanel          : TPanel;
    KorForgalomPanel       : TPanel;
    Panel2                 : TPanel;
    Panel6                 : TPanel;
    Panel9                 : TPanel;
    Panel10                : TPanel;
    Panel11                : TPanel;
    Panel12                : TPanel;
    Panel13                : TPanel;
    Panel14                : TPanel;
    Panel15                : TPanel;
    Panel17                : TPanel;
    Panel18                : TPanel;
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
    Panel161               : TPanel;
    Panel162               : TPanel;
    PenztarnevFocimPanel   : TPanel;

    NapiKorforgalom        : TPieSeries;

    CsakEladas             : TRadioButton;
    CsakVasarlas           : TRadioButton;

    KilepoTimer            : TTimer;
    ALAPPANEL: TPanel;
    K1: TPanel;
    FV1: TPanel;
    FE1: TPanel;
    EL1: TPanel;
    K1E1: TPanel;
    K2: TPanel;
    SE1: TPanel;
    AE1: TPanel;
    AV1: TPanel;
    K1V1: TPanel;
    K2E1: TPanel;
    K3: TPanel;
    SV1: TPanel;
    PF1: TPanel;
    K4: TPanel;
    K6: TPanel;
    K5: TPanel;
    K2V1: TPanel;
    K10: TPanel;
    K24: TPanel;
    K18: TPanel;
    K19: TPanel;
    K11: TPanel;
    K16: TPanel;
    K14: TPanel;
    K8: TPanel;
    K13: TPanel;
    K21: TPanel;
    K22: TPanel;
    K23: TPanel;
    K25: TPanel;
    K26: TPanel;
    K27: TPanel;
    K9: TPanel;
    K15: TPanel;
    K17: TPanel;
    K20: TPanel;
    K12: TPanel;
    K7: TPanel;
    FF2: TPanel;
    FF1: TPanel;
    MF1: TPanel;
    FF3: TPanel;
    OF1: TPanel;
    FF4: TPanel;
    OF2: TPanel;
    MF2: TPanel;
    TF1: TPanel;
    MF3: TPanel;
    OF3: TPanel;
    MF4: TPanel;
    MF5: TPanel;
    OF5: TPanel;
    FF5: TPanel;
    FF6: TPanel;
    FF7: TPanel;
    PTARCOMBO: TComboBox;
    EGYEBGOMB: TBitBtn;
    KILEPGOMB: TBitBtn;
    PF2: TPanel;
    PF3: TPanel;
    PS4: TPanel;
    PF5: TPanel;
    PF22: TPanel;
    PS7: TPanel;
    PS5: TPanel;
    PF7: TPanel;
    PF21: TPanel;
    PF15: TPanel;
    PF14: TPanel;
    PF9: TPanel;
    PF6: TPanel;
    PS6: TPanel;
    PF20: TPanel;
    PF11: TPanel;
    PF17: TPanel;
    FE7: TPanel;
    PF19: TPanel;
    PF12: TPanel;
    PF13: TPanel;
    PF8: TPanel;
    PF10: TPanel;
    PF16: TPanel;
    PS8: TPanel;
    PF18: TPanel;
    PF4: TPanel;
    AV10: TPanel;
    AV7: TPanel;
    AV8: TPanel;
    AV9: TPanel;
    AV12: TPanel;
    AV14: TPanel;
    AV18: TPanel;
    FE27: TPanel;
    AV17: TPanel;
    AV19: TPanel;
    FE25: TPanel;
    FE20: TPanel;
    AV4: TPanel;
    AV3: TPanel;
    AV6: TPanel;
    AV11: TPanel;
    AV13: TPanel;
    FE22: TPanel;
    AV16: TPanel;
    FE24: TPanel;
    FE26: TPanel;
    FE19: TPanel;
    FE21: TPanel;
    FE13: TPanel;
    FV24: TPanel;
    FV4: TPanel;
    FV2: TPanel;
    FV3: TPanel;
    FV5: TPanel;
    FE9: TPanel;
    FE4: TPanel;
    AV2: TPanel;
    FE8: TPanel;
    FE6: TPanel;
    FE5: TPanel;
    FV26: TPanel;
    FV12: TPanel;
    FV19: TPanel;
    FV18: TPanel;
    FV17: TPanel;
    FV11: TPanel;
    FV8: TPanel;
    FV7: TPanel;
    FE2: TPanel;
    AV5: TPanel;
    FE23: TPanel;
    FE11: TPanel;
    FE14: TPanel;
    AV15: TPanel;
    FE15: TPanel;
    FE16: TPanel;
    FV27: TPanel;
    FV25: TPanel;
    FV23: TPanel;
    FV22: TPanel;
    FV16: TPanel;
    FV10: TPanel;
    FE12: TPanel;
    FV15: TPanel;
    FE17: TPanel;
    FV20: TPanel;
    FV21: TPanel;
    FV14: TPanel;
    FV9: TPanel;
    FV6: TPanel;
    FE18: TPanel;
    FE3: TPanel;
    FE10: TPanel;
    FV13: TPanel;
    EL3: TPanel;
    EL7: TPanel;
    EL8: TPanel;
    EL11: TPanel;
    AE16: TPanel;
    EL16: TPanel;
    EL12: TPanel;
    EL15: TPanel;
    AE18: TPanel;
    AE20: TPanel;
    AE25: TPanel;
    EL19: TPanel;
    EL4: TPanel;
    EL10: TPanel;
    AE10: TPanel;
    AE8: TPanel;
    EL5: TPanel;
    EL14: TPanel;
    EL9: TPanel;
    EL13: TPanel;
    AE24: TPanel;
    EL18: TPanel;
    AE26: TPanel;
    AV27: TPanel;
    AE27: TPanel;
    EL17: TPanel;
    AE23: TPanel;
    AE14: TPanel;
    AE11: TPanel;
    AE9: TPanel;
    AE7: TPanel;
    AE5: TPanel;
    EL6: TPanel;
    AE4: TPanel;
    AE6: TPanel;
    AE2: TPanel;
    AE15: TPanel;
    AE13: TPanel;
    AE17: TPanel;
    AE21: TPanel;
    AV22: TPanel;
    AV26: TPanel;
    EL2: TPanel;
    AE3: TPanel;
    AE12: TPanel;
    AE22: TPanel;
    AE19: TPanel;
    AV21: TPanel;
    AV25: TPanel;
    AV24: TPanel;
    AV23: TPanel;
    AV20: TPanel;
    K1E8: TPanel;
    K1E4: TPanel;
    K1E16: TPanel;
    K1E10: TPanel;
    K1E12: TPanel;
    K1E15: TPanel;
    K1V18: TPanel;
    K1E17: TPanel;
    K1E20: TPanel;
    K1E22: TPanel;
    K1E19: TPanel;
    K1E27: TPanel;
    K1E2: TPanel;
    K1E9: TPanel;
    K1E11: TPanel;
    K1E14: TPanel;
    K1E3: TPanel;
    K1V21: TPanel;
    K1E7: TPanel;
    K1V20: TPanel;
    K1E25: TPanel;
    K1V26: TPanel;
    K1V27: TPanel;
    K1V23: TPanel;
    K1V25: TPanel;
    K1V15: TPanel;
    EL23: TPanel;
    K1E13: TPanel;
    K1V7: TPanel;
    K1V13: TPanel;
    K1E6: TPanel;
    K1E5: TPanel;
    K1V19: TPanel;
    K1V5: TPanel;
    K1V8: TPanel;
    K1V10: TPanel;
    K1V12: TPanel;
    K1V14: TPanel;
    EL22: TPanel;
    EL27: TPanel;
    K1V17: TPanel;
    K1V22: TPanel;
    EL26: TPanel;
    EL25: TPanel;
    EL24: TPanel;
    K1V24: TPanel;
    EL20: TPanel;
    EL21: TPanel;
    K1V16: TPanel;
    K1V11: TPanel;
    K1V9: TPanel;
    K1V6: TPanel;
    K1V3: TPanel;
    K1V4: TPanel;
    K1V2: TPanel;
    K2V2: TPanel;
    K2V9: TPanel;
    K2V3: TPanel;
    K2V6: TPanel;
    K2V4: TPanel;
    K2V5: TPanel;
    K2V7: TPanel;
    K2V12: TPanel;
    K2V25: TPanel;
    K2V10: TPanel;
    K2V17: TPanel;
    K2V8: TPanel;
    K2V14: TPanel;
    K2V21: TPanel;
    K2E2: TPanel;
    K2V13: TPanel;
    K2V15: TPanel;
    K2V11: TPanel;
    K2V19: TPanel;
    K2V16: TPanel;
    K2V18: TPanel;
    K1E18: TPanel;
    K1E24: TPanel;
    K2V20: TPanel;
    K1E21: TPanel;
    K2E23: TPanel;
    K2V22: TPanel;
    K2V26: TPanel;
    K2V24: TPanel;
    K1E23: TPanel;
    K2V23: TPanel;
    K2V27: TPanel;
    K1E26: TPanel;
    K2E4: TPanel;
    K2E6: TPanel;
    K2E5: TPanel;
    K2E9: TPanel;
    SV2: TPanel;
    K2E7: TPanel;
    K2E8: TPanel;
    SV3: TPanel;
    SE2: TPanel;
    K2E11: TPanel;
    K2E12: TPanel;
    K2E3: TPanel;
    K2E25: TPanel;
    K2E21: TPanel;
    K2E15: TPanel;
    K2E13: TPanel;
    K2E16: TPanel;
    K2E18: TPanel;
    K2E19: TPanel;
    K2E22: TPanel;
    K2E24: TPanel;
    K2E26: TPanel;
    K2E27: TPanel;
    K2E20: TPanel;
    K2E17: TPanel;
    K2E14: TPanel;
    K2E10: TPanel;
    SE3: TPanel;
    SE4: TPanel;
    SV4: TPanel;
    SE5: TPanel;
    SV5: TPanel;
    SV6: TPanel;
    SV10: TPanel;
    SE9: TPanel;
    SV9: TPanel;
    SE6: TPanel;
    SE8: TPanel;
    SV8: TPanel;
    SE7: TPanel;
    SV7: TPanel;
    SV12: TPanel;
    SV11: TPanel;
    SE10: TPanel;
    SE12: TPanel;
    SE11: TPanel;
    SV13: TPanel;
    SE13: TPanel;
    SV15: TPanel;
    SE14: TPanel;
    SE15: TPanel;
    SV14: TPanel;
    SE17: TPanel;
    SE16: TPanel;
    SV17: TPanel;
    SV18: TPanel;
    SV16: TPanel;
    SE19: TPanel;
    SV19: TPanel;
    SV22: TPanel;
    SV23: TPanel;
    SV24: TPanel;
    SE21: TPanel;
    SV25: TPanel;
    SV21: TPanel;
    SE20: TPanel;
    SV20: TPanel;
    SE18: TPanel;
    SE27: TPanel;
    SE25: TPanel;
    SE24: TPanel;
    SE23: TPanel;
    SE22: TPanel;
    SE26: TPanel;
    SV26: TPanel;
    SV27: TPanel;
    KESZLETPANEL: TPanel;
    Label11: TLabel;
    Label12: TLabel;
    E1: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    E2: TEdit;
    E3: TEdit;
    E4: TEdit;
    E5: TEdit;
    E6: TEdit;
    E7: TEdit;
    E8: TEdit;
    E9: TEdit;
    E10: TEdit;
    EGYEBBACKGOMB: TBitBtn;
    Shape3: TShape;
    GRAFIKONGOMB: TBitBtn;
    NYOMTATOGOMB: TBitBtn;
    Panel1: TPanel;
    INFOPANEL: TPanel;
    Label22: TLabel;
    EK: TEdit;
    Label23: TLabel;
    Label24: TLabel;
    EFV: TEdit;
    EFE: TEdit;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    ESV: TEdit;
    EK2V: TEdit;
    EK1V: TEdit;
    EAV: TEdit;
    EK1E: TEdit;
    EK2E: TEdit;
    ESE: TEdit;
    EEL: TEdit;
    EAE: TEdit;
    ZASZLO: TImage;
    DNEMPANEL: TPanel;
    DNEVPANEL: TPanel;
    INFOBACKGOMB: TBitBtn;
    PrintDialog1: TPrintDialog;
    ARFOLYAMGOMB: TBitBtn;
    AKTARFPANEL: TPanel;
    AKTARFSOURCE: TDataSource;
    AKTARFQUERY: TIBQuery;
    AKTARFDBASE: TIBDatabase;
    AKTARFTRANZ: TIBTransaction;
    ARFOLYAMRACS: TDBGrid;
    DTPANEL: TPanel;
    DATUMPANEL: TPanel;
    TMPANEL: TPanel;
    IDOPANEL: TPanel;
    MNBGOMB: TBitBtn;
    CSIK: TProgressBar;
    OF4: TPanel;

    procedure FormActivate(Sender: TObject);

    procedure AdatDisplay;
    procedure AdatFrissites;
    procedure AdatFrissitoGombClick(Sender: TObject);
    procedure AdatNullazo;
    procedure AdatSummazas;
    procedure AktaParancs(_ukaz: string);
    procedure AktArfFeltoltes;
    procedure AlapAdatBeolvasas;
    procedure ArfolyamDisplay(_ptsorszam: byte);
    procedure ArfolyamTombClear;
    procedure ArfolyamTombFeltoltes;
    procedure BitBtn1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure CsakEladasClick(Sender: TObject);
    procedure CsakVasarClick(Sender: TObject);
    procedure KeszForgtombFeltoltes;
    procedure PkDekodolo;
    procedure EgyPenztarDisplay(_ptx: byte);

    procedure F1GombClick(Sender: TObject);
    procedure F2GombClick(Sender: TObject);
    procedure F3GombClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FTPSzerverbeBelep;
    procedure FrissitoTimerTimer(Sender: TObject);
    procedure GrafikonDisplay;
    procedure GrafikonGombClick(Sender: TObject);
    procedure GrafikonPanelExit(Sender: TObject);
    procedure IrodaAdatBeolvasas;
    procedure PkDownload;
    procedure KilepesGombClick(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Kordiagramrutin;
    procedure KorDiagramGombClick(Sender: TObject);
    procedure Kistombbe;
    procedure Dirtorles;
    procedure Pitetolto(_pitetipus: integer);
    procedure SerialFree;
    procedure TombBetolto;
    procedure VisszaGombClick(Sender: TObject);
    procedure Feherito;
    procedure Szinezo;
    procedure MnbFrissites;
    procedure TextKiiro;
    procedure MNBFejlec;

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
    function Kitkod(_kdatum: string):string;
    function IntegDek(_5betu:string): integer;
    function Dnem2Dekod(_dkod:string):string;

    function ScanPenztar(_pn: byte): byte;
    function Vaninternet: boolean;
    procedure EGYEBGOMBClick(Sender: TObject);
    procedure EGYEBBACKGOMBClick(Sender: TObject);
    function Nul3(_n: byte): string;
    procedure KILEPGOMBClick(Sender: TObject);
    procedure PTARCOMBOChange(Sender: TObject);
    procedure INFOBACKGOMBClick(Sender: TObject);
    procedure PF1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ALAPPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FRISSITOGOMBClick(Sender: TObject);
    procedure PS1Click(Sender: TObject);
    procedure PS2Click(Sender: TObject);
    procedure NYOMTATOGOMBClick(Sender: TObject);
    procedure ARFOLYAMGOMBClick(Sender: TObject);
    procedure MNBGOMBClick(Sender: TObject);
    procedure MnbArfolyamNyomtatas;
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PillKeszForm: TPillKeszForm;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS',
     'JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER','NOVEMBER','DECEMBER');

  _dnem: array[1..28] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                       'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN',
                       'NOK','NZD','PLN','RCH','RON','RSD','RUB','SEK','THB','TRY',
                       'UAH','USD');

  _dnev: array[1..28] of string = ('AUSZTRÁL DOLLÁR','BOSNYÁK MÁRKA','BOLGÁR LEVA',
         'BRAZIL REÁL','KANADAI DOLLÁR','SVÁJCI FRANK','KINAI JÜAN','CSEH KORONA',
         'DÁN KORONA','EURÓ','ANGOL FONT','HORVÁT KUNA','MAGYAR FORINT','IZRAELI SHAKEL',
         'JAPÁN JEN','MEXIKÓI PESÓ','NORVÉG KORONA','UJZÉLANDI DOLLÁR',
         'LENGYEL ZLOTYI','RÉGI SVÁJCI FRANK','ROMÁN LEI','SZERB DINÁR','OROSZ RUBEL',
         'SVÉD KORONA','THAI BATH','TÖRÖK LÍRA','UKRÁN HRIVNYA','AMERIKAI DOLLÁR');

  _arfdnem: array[1..28] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD','RCH');

  _k,_fv,_fe,_av,_ae,_el,_k1v,_k1e,_k2v,_k2e,_sv,_se: array[1..28] of TPanel;
  _e: array[1..10] of TEdit;

  _keszlet,_forgvet,_forgelad: array[0..30,1..28] of integer;

  _varf    : array[0..30,0..28] of integer;
  _earf    : array[0..30,0..28] of integer;
  _elszarf : array[0..30,0..28] of integer;

  _bytetomb: array[1..4096] of byte;

  _LFile: textfile;

  _datums,_idos  : array[0..30] of string;
  _k1varf,_k1earf,_k2varf,_k2earf,_shkvet,_shkelad: array[0..30,0..28] of integer;
  _wuUsd,_wuHuf,_wuUsdErtek,_afa,_eker,_kezdij: array[0..30] of integer;
  _valutaErtek,_forintErtek,_foglalo: array[0..30] of integer;
  _napivetel,_napieladas: array[0..30] of integer;

  _ptindex    : byte;
  _xx         : byte;
  _valutadarab: byte;

  _ptnum        : array[0..30] of byte;
  _ptnev,_pttyp: array[0..30] of string;
  _ptdarab,_pkdb: byte;

  _hufindex: integer = 13;

  _bTomb   : array[1..737] of byte;
  _pkNev   : array[1..30] of string;

  _olvas   : File of byte;

  _aktPanel: TPanel;

  _sorveg      : string = chr(13)+chr(10);
  _foglalodnem : array[0..30] of string;

  // ---------------------------------------------------------------------------

  _pillDir            : string = 'C:\ERTEKTAR\PILLKESZ';
  _arfolyamDat        : string = 'c:\ertektar\arfolyam\arfolyam.dat';
  _binolvas           : File of byte;
  _srec               : TSearchrec;
  _hNet,_hFtp,_hsearch: HINTERNET;

  _host               : string;
  _userid             : string = 'ebc-10%';
  _ftpPassword        : string = 'klc+45%';
  _ftpPort            : integer = 21100;
  _findData           : WIN32_FIND_DATA;


  _mamas,_localPath,_pcs,_minta,_aktfilenev,_remoteFile,_aktpath,_aktdnem: string;
  _aktdnev,_aktzaszlopath,_kit,_mnbfile,_mnbPath: string;
  _ertektar,_ptss: byte;
  _counternum,_kodpointer,_height,_width : word;
  _mResult,_code,_pkindex,_qSumforint,_qSumValuta,_qUsdElszarf,_qWuUsd,_usdarf: integer;
  _pix,_dix,_dux,_aktkeszlet,_aktvetel,_akteladas,_aktvarf,_aktearf,_wuusdft: integer;
  _aktelszarf,_aktk1v,_aktk2v,_aktk1e,_aktk2e,_aktshkv,_aktshke,_TOTAL: integer;
  _elszamarfolyam: integer;

  // ---------------------------------------------------------------------------

   _pkFile   : array[1..24] of string;
  _csopTabla : array[1..200] of byte;

  _pszin: array[0..20] of TColor;

  // ---------------------------------------------------------------------------


  _kellvasarlas,_kelleladas,_vanVasarlasTabla,_vanEladasTabla,_sikeres: boolean;
  _vanfoglalo,_vanarfPanel,_szabad: boolean;
  Vasarlas,Eladas: TBarseries;

  _pf: array[1..24] of TPanel;
  _ps: array[1..8] of TPanel;
  _ff: array[1..7] of TPanel;
  _mf: array[1..5] of TPanel;
  _of: array[1..5] of TPanel;

  // ---------------------------------------------------------------------------

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

  _dux := 0;

  _vanarfpanel := False;
  _mamas := Hundatetostr(date);
  TombBetolto;
  Kistombbe;

  AlapadatBeolvasas;
  IrodaAdatBeolvasas;
  AdatNullazo;
end;

// =============================================================================
          procedure TPillkeszForm.FormActivate(Sender: TObject);
// =============================================================================

begin
  _pix := 0;
  AdatFrissites;

  _counternum := 0;
  Csik.Position := 0;
  _szabad := true;
  FrissitoTimer.Enabled := True;

  Adatdisplay;

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

  DirTorles;

  with FrissitoPanel do
    begin
      Top := 380;
      Left := 340;
      Visible := True;
      Repaint;
    end;

  KeszForgtombFeltoltes;

  ArfolyamtombFeltoltes;
  FrissitoPanel.Visible := False;
  FuggonyPanel.Visible  := False;

end;

// =============================================================================
           procedure TPillKeszForm.FrissitoTimerTimer(Sender: TObject);
// =============================================================================

begin
  if not _szabad then exit;

  FrissitoTimer.Enabled := False;
  inc(_counternum);
  if _counternum<13 then
    begin
      Csik.Position := _counternum;
      csik.Repaint;
      FrissitoTimer.Enabled := true;
      exit;
    end;

  _counternum := 0;
  Csik.Position := 0;
  Adatfrissites;
  adatDisplay;

  FrissitoTimer.Enabled := True;
end;


//==============================================================================
        procedure TPillkeszForm.AdatFrissitoGombClick(Sender: TObject);
//==============================================================================

begin
  FrissitoTimer.Enabled := False;
  Adatfrissites;
  FrissitoTimer.Enabled := True;
end;

// =============================================================================
        procedure TPillkeszForm.GRAFIKONGOMBClick(Sender: TObject);
// =============================================================================

begin
 // _szabad := false;
  _kellvasarlas     := True;
  _kelleladas       := False;
  _vanVasarlasTabla := false;
  _vanEladasTabla   := False;

  KorforgalomPanel.visible := False;
  with FuggonyPanel do
    begin
      Top  := 0;
      Left := 0;
      Visible := True;
    end;

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


// =============================================================================
           procedure TPillkeszForm.Arfolyamdisplay(_ptsorszam: byte);
// =============================================================================

var _z: byte;
    _aktvpanel,_aktepanel: TPanel;
    _aktvarf,_aktearf: integer;

begin
  for _z := 1 to 28 do
    begin
      _aktvpanel := _av[_z];
      _aktePanel := _ae[_z];

      _aktvPanel.caption := '';
      _aktePanel.caption := '';

      _aktvPanel.repaint;
      _aktePanel.repaint;
    end;

  _z := 1;
  while _z<=28 do
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


begin
  _ptindex := 0;
  while _ptindex <= _ptDarab do
    begin
      _xx := 1;
      while _xx<=28 do
        begin
          _varf[_ptindex,_xx] := 0;
          _earf[_ptindex,_xx] := 0;
          _elszarf[_ptindex,_xx] := 0;
          _k1varf[_ptindex,_xx] := 0;
          _k1earf[_ptindex,_xx] := 0;
          _k2varf[_ptindex,_xx] := 0;
          _k2earf[_ptindex,_xx] := 0;
          _shkvet[_ptindex,_xx] := 0;
          _shkelad[_ptindex,_xx] := 0;
          inc(_xx);
        end;
      inc(_ptindex);
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

var
    _maxi,_sb,_se: real;

begin

  with GrafikonPanel do
    begin
      Top     := 142;
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
          _ptindex := 1;
          while _ptindex<=_ptdarab do
            begin
              Add(_ptindex,inttostr(_PtNum[_ptindex]),clBlack);
              inc(_ptindex);
            end;

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

      _ptindex := 1;
      while _ptindex<=_ptdarab do
         begin
           _sb := _NapiEladas[_ptindex];
           Vasarlas.AddXY(_ptindex,_sb);
           if _sb>_maxi then _maxi := _sb;
           inc(_ptindex);
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
           _ptindex := 1;
           while _ptindex<=_ptdarab do
             begin
               Add(_ptindex,inttostr(_Ptnum[_ptindex]),clBlack);
               inc(_ptindex);
             end;

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

      _ptindex := 1;
      while _ptindex<=_ptdarab do
        begin
          _se := _NapiVetel[_ptindex];
          Eladas.addxy(_ptindex,_se);
          if _se>_maxi then _maxi := _se;
          inc(_ptindex);
        end;
    end;

//  ErtekValtas;


  with Grafikon do
    begin
      LeftAxis.Maximum   := (1.1*_maxi);
      BottomAxis.Maximum := _PtDarab;
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

var _ss:integer;
   _megnevezes: string;
   _sumVet,_sumElad,_sumForg: real;

begin

  NapiKorforgalom.Clear;
  _ss := -1;
  _ptindex := 1;
  while _ptindex<=_ptdarab do
    begin
      _megnevezes := trim(_PtNev[_ptindex]);
      _sumVet  := _napieladas[_ptindex];
      _sumElad := _napiVetel[_ptindex];
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
      inc(_ptindex);
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
  while _y<=28 do
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

//==============================================================================
                 procedure TPillKeszFORM.IrodaAdatBeolvasas;
// =============================================================================

var _uzlet: byte;
    _uznev,_status: string;

begin
  _ptindex := 0;

  while _ptindex<=30 do
    begin
      _ptnev[_ptindex]  := '';
      _ptnum[_ptindex]  := 0;
      _ptTyp[_ptindex] := '';
      inc(_ptindex);
    end;

  Ptarcombo.Items.clear;

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

  _ptindex := 0;
  _ptnum[0] := 0;
  _pttyp[0] := 'P';
  _ptnev[0] := 'KÖRZET ÖSSZESEN';

  Ptarcombo.Items.Clear;
  Ptarcombo.Items.Add('000 KÖRZET ÖSSZESEN');

  while not ServerQuery.Eof do
    begin
      _uzlet := Serverquery.FieldbyName('UZLET').asInteger;
      _uznev := trim(ServerQuery.fieldByName('KESZLETNEV').AsString);
      _status:= ServerQuery.FieldByNAme('STATUS').asString;
      if _uzlet>150 then _status := 'P';

      inc(_ptindex);

      _ptnum[_ptindex]  := _uzlet;
      _ptnev[_ptindex]   := _uznev;
      _pttyp[_ptindex] := _status;

      ptarcombo.Items.add(nul3(_uzlet)+' '+_uznev);


      ServerQuery.next;
    end;
  ServerQuery.close;
  Serverdbase.close;

  _ptdarab:= _ptindex;

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
  result := '';
  if _arf=0 then exit;

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


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                    procedure TPillkeszForm.TombBetolto;
// =============================================================================

begin
  _k[1] := K1;
  _k[2] := K2;
  _k[3] := K3;
  _k[4] := K4;
  _k[5] := K5;
  _k[6] := K6;
  _k[7] := K7;
  _k[8] := K8;
  _k[9] := K9;
  _k[10]:= K10;
  _k[11]:= K11;
  _k[12]:= K12;
  _k[13]:= K13;
  _k[14]:= K14;
  _k[15]:= K15;
  _k[16]:= K16;
  _k[17]:= K17;
  _k[18]:= K18;
  _k[19]:= K19;
  _k[20]:= K20;
  _k[21]:= K21;
  _k[22]:= K22;
  _k[23]:= K23;
  _k[24]:= K24;
  _k[25]:= K25;
  _k[26]:= K26;
  _k[27]:= K27;

  _fv[1] := FV1;
  _fv[2] := FV2;
  _fv[3] := FV3;
  _fv[4] := FV4;
  _fv[5] := FV5;
  _fv[6] := FV6;
  _fv[7] := FV7;
  _fv[8] := FV8;
  _fv[9] := FV9;
  _fv[10]:= FV10;
  _fv[11]:= FV11;
  _fv[12]:= FV12;
  _fv[13]:= FV13;
  _fv[14]:= FV14;
  _fv[15]:= FV15;
  _fv[16]:= FV16;
  _fv[17]:= FV17;
  _fv[18]:= FV18;
  _fv[19]:= FV19;
  _fv[20]:= FV20;
  _fv[21]:= FV21;
  _fv[22]:= FV22;
  _fv[23]:= FV23;
  _fv[24]:= FV24;
  _fv[25]:= FV25;
  _fv[26]:= FV26;
  _fv[27]:= FV27;

  _fe[1] := FE1;
  _fe[2] := FE2;
  _fe[3] := FE3;
  _fe[4] := FE4;
  _fe[5] := FE5;
  _fe[6] := FE6;
  _fe[7] := FE7;
  _fe[8] := FE8;
  _fe[9] := FE9;
  _fe[10]:= FE10;
  _fe[11]:= FE11;
  _fe[12]:= FE12;
  _fe[13]:= FE13;
  _fe[14]:= FE14;
  _fe[15]:= FE15;
  _fe[16]:= FE16;
  _fe[17]:= FE17;
  _fe[18]:= FE18;
  _fe[19]:= FE19;
  _fe[20]:= FE20;
  _fe[21]:= FE21;
  _fe[22]:= FE22;
  _fe[23]:= FE23;
  _fe[24]:= FE24;
  _fe[25]:= FE25;
  _fe[26]:= FE26;
  _fe[27]:= FE27;

  _av[1] := AV1;
  _av[2] := AV2;
  _av[3] := AV3;
  _av[4] := AV4;
  _av[5] := AV5;
  _av[6] := AV6;
  _av[7] := AV7;
  _av[8] := AV8;
  _av[9] := AV9;
  _av[10]:= AV10;
  _av[11]:= AV11;
  _av[12]:= AV12;
  _av[13]:= AV13;
  _av[14]:= AV14;
  _av[15]:= AV15;
  _av[16]:= AV16;
  _av[17]:= AV17;
  _av[18]:= AV18;
  _av[19]:= AV19;
  _av[20]:= AV20;
  _av[21]:= AV21;
  _av[22]:= AV22;
  _av[23]:= AV23;
  _av[24]:= AV24;
  _av[25]:= AV25;
  _av[26]:= AV26;
  _av[27]:= AV27;

  _ae[1] := AE1;
  _ae[2] := AE2;
  _ae[3] := AE3;
  _ae[4] := AE4;
  _ae[5] := AE5;
  _ae[6] := AE6;
  _ae[7] := AE7;
  _ae[8] := AE8;
  _ae[9] := AE9;
  _ae[10]:= AE10;
  _ae[11]:= AE11;
  _ae[12]:= AE12;
  _ae[13]:= AE13;
  _ae[14]:= AE14;
  _ae[15]:= AE15;
  _ae[16]:= AE16;
  _ae[17]:= AE17;
  _ae[18]:= AE18;
  _ae[19]:= AE19;
  _ae[20]:= AE20;
  _ae[21]:= AE21;
  _ae[22]:= AE22;
  _ae[23]:= AE23;
  _ae[24]:= AE24;
  _ae[25]:= AE25;
  _ae[26]:= AE26;
  _ae[27]:= AE27;

  _el[1] := EL1;
  _el[2] := EL2;
  _el[3] := EL3;
  _el[4] := EL4;
  _el[5] := EL5;
  _el[6] := EL6;
  _el[7] := EL7;
  _el[8] := EL8;
  _el[9] := EL9;
  _el[10]:= EL10;
  _el[11]:= EL11;
  _el[12]:= EL12;
  _el[13]:= EL13;
  _el[14]:= EL14;
  _el[15]:= EL15;
  _el[16]:= EL16;
  _el[17]:= EL17;
  _el[18]:= EL18;
  _el[19]:= EL19;
  _el[20]:= EL20;
  _el[21]:= EL21;
  _el[22]:= EL22;
  _el[23]:= EL23;
  _el[24]:= EL24;
  _el[25]:= EL25;
  _el[26]:= EL26;
  _el[27]:= EL27;

  _k1v[1] := K1V1;
  _k1v[2] := K1V2;
  _k1v[3] := K1V3;
  _k1v[4] := K1V4;
  _k1v[5] := K1V5;
  _k1v[6] := K1V6;
  _k1v[7] := K1V7;
  _k1v[8] := K1V8;
  _k1v[9] := K1V9;
  _k1v[10]:= K1V10;
  _k1v[11]:= K1V11;
  _k1v[12]:= K1V12;
  _k1v[13]:= K1V13;
  _k1v[14]:= K1V14;
  _k1v[15]:= K1V15;
  _k1v[16]:= K1V16;
  _k1v[17]:= K1V17;
  _k1v[18]:= K1V18;
  _k1v[19]:= K1V19;
  _k1v[20]:= K1V20;
  _k1v[21]:= K1V21;
  _k1v[22]:= K1V22;
  _k1v[23]:= K1V23;
  _k1v[24]:= K1V24;
  _k1v[25]:= K1V25;
  _k1v[26]:= K1V26;
  _k1v[27]:= K1V27;

  _k1e[1] := K1E1;
  _k1e[2] := K1E2;
  _k1e[3] := K1E3;
  _k1e[4] := K1E4;
  _k1e[5] := K1E5;
  _k1e[6] := K1E6;
  _k1e[7] := K1E7;
  _k1e[8] := K1E8;
  _k1e[9] := K1E9;
  _k1e[10]:= K1E10;
  _k1e[11]:= K1E11;
  _k1e[12]:= K1E12;
  _k1e[13]:= K1E13;
  _k1e[14]:= K1E14;
  _k1e[15]:= K1E15;
  _k1e[16]:= K1E16;
  _k1e[17]:= K1E17;
  _k1e[18]:= K1E18;
  _k1e[19]:= K1E19;
  _k1e[20]:= K1E20;
  _k1e[21]:= K1E21;
  _k1e[22]:= K1E22;
  _k1e[23]:= K1E23;
  _k1e[24]:= K1E24;
  _k1e[25]:= K1E25;
  _k1e[26]:= K1E26;
  _k1e[27]:= K1E27;

  _k2v[1] := K2V1;
  _k2v[2] := K2V2;
  _k2v[3] := K2V3;
  _k2v[4] := K2V4;
  _k2v[5] := K2V5;
  _k2v[6] := K2V6;
  _k2v[7] := K2V7;
  _k2v[8] := K2V8;
  _k2v[9] := K2V9;
  _k2v[10]:= K2V10;
  _k2v[11]:= K2V11;
  _k2v[12]:= K2V12;
  _k2v[13]:= K2V13;
  _k2v[14]:= K2V14;
  _k2v[15]:= K2V15;
  _k2v[16]:= K2V16;
  _k2v[17]:= K2V17;
  _k2v[18]:= K2V18;
  _k2v[19]:= K2V19;
  _k2v[20]:= K2V20;
  _k2v[21]:= K2V21;
  _k2v[22]:= K2V22;
  _k2v[23]:= K2V23;
  _k2v[24]:= K2V24;
  _k2v[25]:= K2V25;
  _k2v[26]:= K2V26;
  _k2v[27]:= K2V27;

  _k2e[1] := K2E1;
  _k2e[2] := K2E2;
  _k2e[3]:= K2E3;
  _k2e[4] := K2E4;
  _k2e[5] := K2E5;
  _k2e[6] := K2E6;
  _k2e[7] := K2E7;
  _k2e[8] := K2E8;
  _k2e[9] := K2E9;
  _k2e[10]:= K2E10;
  _k2e[11]:= K2E11;
  _k2e[12]:= K2E12;
  _k2e[13]:= K2E13;
  _k2e[14]:= K2E14;
  _k2e[15]:= K2E15;
  _k2e[16]:= K2E16;
  _k2e[17]:= K2E17;
  _k2e[18]:= K2E18;
  _k2e[19]:= K2E19;
  _k2e[20]:= K2E20;
  _k2e[21]:= K2E21;
  _k2e[22]:= K2E22;
  _k2e[23]:= K2E23;
  _k2e[24]:= K2E24;
  _k2e[25]:= K2E25;
  _k2e[26]:= K2E26;
  _k2e[27]:= K2E27;

  _sv[1] := SV1;
  _sv[2] := SV2;
  _sv[3] := SV3;
  _sv[4] := SV4;
  _sv[5] := SV5;
  _sv[6] := SV6;
  _sv[7] := SV7;
  _sv[8] := SV8;
  _sv[9] := SV9;
  _sv[10]:= SV10;
  _sv[11]:= SV11;
  _sv[12]:= SV12;
  _sv[13]:= SV13;
  _sv[14]:= SV14;
  _sv[15]:= SV15;
  _sv[16]:= SV16;
  _sv[17]:= SV17;
  _sv[18]:= SV18;
  _sv[19]:= SV19;
  _sv[20]:= SV20;
  _sv[21]:= SV21;
  _sv[22]:= SV22;
  _sv[23]:= SV23;
  _sv[24]:= SV24;
  _sv[25]:= SV25;
  _sv[26]:= SV26;
  _sv[27]:= SV27;

  _se[1] := SE1;
  _se[2] := SE2;
  _se[3] := SE3;
  _se[4] := SE4;
  _se[5] := SE5;
  _se[6] := SE6;
  _se[7] := SE7;
  _se[8] := SE8;
  _se[9] := SE9;
  _se[10]:= SE10;
  _se[11]:= SE11;
  _se[12]:= SE12;
  _se[13]:= SE13;
  _se[14]:= SE14;
  _se[15]:= SE15;
  _se[16]:= SE16;
  _se[17]:= SE17;
  _se[18]:= SE18;
  _se[19]:= SE19;
  _se[20]:= SE20;
  _se[21]:= SE21;
  _se[22]:= SE22;
  _se[23]:= SE23;
  _se[24]:= SE24;
  _se[25]:= SE25;
  _se[26]:= SE26;
  _se[27]:= SE27;

  _e[1] := E1;
  _e[2] := E2;
  _e[3] := E3;
  _e[4] := E4;
  _e[5] := E5;
  _e[6] := E6;
  _e[7] := E7;
  _e[8] := E8;
  _e[9] := E9;
  _e[10]:= E10;
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                         ADAT-NULLÁZÓ                                   ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   procedure TPillkeszForm.Adatnullazo;
// =============================================================================


begin
  _ptindex := 1;
  while _ptindex<=_ptdarab do
    begin
      _xx := 1;
      while _xx<=28 do
        begin
          _keszlet[_ptindex,_xx]  := 0;
          _forgvet[_ptindex,_xx]  := 0;
          _forgelad[_ptindex,_xx] := 0;

          _varf[_ptindex,_xx]     := 0;
          _earf[_ptindex,_xx]     := 0;
          _elszarf[_ptindex,_xx]  := 0;

          _k1varf[_ptindex,_xx]   := 0;
          _k1earf[_ptindex,_xx]   := 0;
          _k2varf[_ptindex,_xx]   := 0;
          _k2earf[_ptindex,_xx]   := 0;

          _shkvet[_ptindex,_xx]   := 0;
          _shkelad[_ptindex,_xx]  := 0;
          inc(_xx);
        end;

      _valutaErtek[_ptindex]      := 0;
      _forintErtek[_ptindex]      := 0;

      _wuHuf[_ptindex]            := 0;
      _wuusd[_ptindex]            := 0;
      _wuusdertek[_ptindex]       := 0;
      _afa[_ptindex]              := 0;

      _kezdij[_ptindex]           := 0;
      _eker[_ptindex]             := 0;
      _foglalo[_ptindex]          := 0;

      inc(_ptindex);
    end;
end;

// =============================================================================
         procedure TPillkeszForm.EGYEBGOMBClick(Sender: TObject);
// =============================================================================

begin

  with Keszletpanel do
    begin
      top := 152;
      left:= 232;
      Visible := True;
      repaint;
    end;
end;

// =============================================================================
         procedure TPillkeszForm.EGYEBBACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  KeszletPanel.Visible := False;
end;

// =============================================================================
              function TPillkeszForm.ScanPenztar(_pn: byte): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=_ptDarab do
    begin
      if _ptnum[_z]=_pn then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
            procedure TPillkeszForm.EgyPenztarDisplay(_ptx: byte);
// =============================================================================

var _aktdatums,_aktidos: string;
    _plus: byte;

begin
  _ptss := _ptx;
  if _ptx>0 then
    begin
      _aktdatums := '20' + _datums[_ptx];
      _aktidos := _idos[_ptx];
      _aktidos := leftstr(_aktidos,2)+' óra '+midstr(_aktidos,4,2)+' perckor';
      DatumPanel.caption := _aktdatums;
      IdoPanel.caption  := _aktidos;

      DatumPanel.repaint;
      idoPanel.Repaint;
    end;

  _plus := 0;
  _xx := 1;
  while _xx<=27 do
    begin
      if _xx=20 then _plus := 1;

      _k[_xx].caption   := Ftform(_keszlet[_ptx,_xx+_plus]);
      _fv[_xx].Caption  := Ftform(_forgvet[_ptx,_xx+_plus]);
      _fe[_xx].Caption  := FtForm(_forgelad[_ptx,_xx+_plus]);

      _av[_xx].Caption  := Arfform(_vArf[_ptx,_xx+_plus]);
      _ae[_xx].Caption  := Arfform(_eArf[_ptx,_xx+_plus]);
      _el[_xx].Caption  := Arfform(_ElszArf[_ptx,_xx+_plus]);

      _k1v[_xx].Caption := Arfform(_K1vArf[_ptx,_xx+_plus]);
      _k1e[_xx].Caption := Arfform(_K1eArf[_ptx,_xx+_plus]);
      _k2v[_xx].Caption := Arfform(_K2vArf[_ptx,_xx+_plus]);
      _k2e[_xx].Caption := Arfform(_K2eArf[_ptx,_xx+_plus]);

      _sv[_xx].caption  := Arfform(_shkvet[_ptx,_xx+_plus]);
      _se[_xx].caption  := Arfform(_shkelad[_ptx,_xx+_plus]);
      inc(_xx);
    end;

  _wuUsdFt := round(_wuusd[_ptx]/100*_usdArf);

  E1.text := ftform(_ValutaErtek[_ptx]);
  E2.Text := ftform(_ForintErtek[_ptx]);
  E3.Text := Ftform(_Kezdij[_ptx]);
  E4.text := FtForm(_wuhuf[_ptx]);
  E5.text := Ftform(_wuusd[_ptx]);
  e6.text := FtForm(_wuusdFt);
  e7.text := FtForm(_Afa[_ptx]);
  e8.text := FtForm(_Eker[_ptx]);
  e9.text := Ftform(_Foglalo[_ptx]);

  _total := _valutaErtek[_ptx]+_forintErtek[_ptx]+_kezdij[_ptx]+_wuhuf[_ptx];
  _total := _total + _wuusdFt+_afa[_ptx]+_eker[_ptx]+_foglalo[_ptx];

  e10.text:= FtForm(_Total);

  _ptss := _ptx;
  AktArfFeltoltes;

  KeszletPanel.visible := False;
  with AlapPanel do
    begin
      top := 0;
      left := 0;
      Visible := True;
      repaint;
    end;
  ActiveControl := Kilepgomb;
end;


////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                          ARFOLYAMKIJELZÉS                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                procedure TPillKeszForm.ArfolyamtombFeltoltes;
// =============================================================================

var _aktpt,_sajcsop,_valss: byte;
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

  _ptindex := 1;
  while _ptindex<=_ptDarab do
    begin
      if _ptTyp[_ptindex]='E' then
        begin
          inc(_ptindex);
          continue;
        end;

      _aktpt   := _PtNum[_ptindex];
      _sajcsop := _csoptabla[_aktpt];
      if _sajcsop=0 then _sajcsop := 3;

      _start := 201 + trunc((_sajcsop-1)*1266);

      Reset(_binolvas);
      Seek(_binolvas,_start);

      _valss := 1;
      while _valss<=28 do
        begin
          _aktdnem := _arfdnem[_valss];

          _xx := Scandnem(_aktdnem);

          BlockRead(_binolvas,_btomb,45);

          _elszarf[_ptindex,_xx] := intdekodol(1);
          _vArf[_ptindex,_xx]    := intdekodol(6);
          _earf[_ptindex,_xx]    := intdekodol(11);
          _k1varf[_ptindex,_xx]  := intdekodol(16);
          _k1earf[_ptindex,_xx]  := intdekodol(21);
          _k2varf[_ptindex,_xx]  := intdekodol(26);
          _k2earf[_ptindex,_xx]  := intdekodol(31);
          _shkvet[_ptindex,_xx]  := intdekodol(36);
          _shkelad[_ptindex,_xx] := intdekodol(41);

          inc(_valss);
        end;
      inc(_ptindex);
    end;
  Closefile(_binOlvas);
  _usdarf := _elszarf[1,27];
end;

////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                     ADATLETÖLTÉS A SZERVERRÕL                          ////
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

//==============================================================================
                 procedure TPillKeszFORM.AlapAdatBeolvasas;
// =============================================================================

//  Beolvassa az Értékár-számát és az USD elszámolási árfolyamát
//

var _penztarkod: string;

begin
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'USD'+chr(39);

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
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

// =============================================================================
             procedure TPillKeszForm.KeszForgTombFeltoltes;
// =============================================================================

begin
  PkDownload;
  PkDekodolo;
  Adatsummazas;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                     procedure TPillkeszForm.PkDownLoad;
// =============================================================================

(*   Feladat: A 'c:\ertektar\pillkesz könyvtárban lévú értékes pk-fileok
              nevét _Pkfile[] tömbbe iktatni, tömb itemszáma = _pkdb

              Az új fileokat a szerver Pillkesz könyvtárából veszi
*)

var _qq,_len,_pk: integer;
    _nev,_pks,_ppath: string;

begin

  if not vanInternet then exit;   // hs nincs internet, akkor vége


  FTPSzerverbeBelep;             // Ha nincs server. akkor vége
  if _hFtp=Nil then exit;

  // ---------------------------------------------------------------------------

  //  Nem sikerült a PILLKESZ könyvtárba belépni:

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

  // Ha nem talál pk file-t, akkor ennyi
  if _hSearch=nil then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ---------------------------------------------------------------------------
  // Belistáz pkdb filenevet (pk*.értéktár)

  _pkdb := 0;
  repeat
    inc(_pkdb);
    _aktfilenev := _findData.cFileName;
    _pkFile[_pkdb] := _aktfilenev;
  until not InternetFindNextFile(_hSearch,@_findData);
  InternetCloseHandle(_hSearch);

  // ---------------------------------------------------------------------------

  // Letölti (és felülirja) a belistázott pkdb pk-filet

  _qq := 1;
  while _qq<=_pkDb do
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

  //  leselejtezi a pillkesz könyvtárban levö (nem oda illõ) fileokat
  // Az értékes fileokat tombbe (_pkfile) szervezi

  _pkdb := 0;
  _minta := 'c:\ertektar\pillkesz\PK*.'+inttostr(_ertektar);

  if FindFirst(_minta, faAnyFile, _srec)=0 then
    begin
      repeat
        _len := _srec.Size;
        _nev := _srec.Name;
        _pks := midstr(_nev,3,3);
        val(_pks,_pk,_code);

        if _code<>0 then _pk := 0;
        _xx :=0;

        if _pk>0 then _xx := ScanPenztar(_pk);

        if (_len<>737) or (_xx=0) then
          begin
            _ppath := 'c:\ertektar\pillkesz\'+_nev;
            sysutils.DeleteFile(_ppath);
          end else
          begin
            inc(_pkdb);
            _PkFile[_pkdb] := _nev;
          end;

      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
end;

// =============================================================================
                   procedure TPillKeszForm.Adatsummazas;
// =============================================================================

begin
  _ptindex := 1;
  while _ptindex<=_ptdarab do
    begin
      _napivetel[_ptindex] := 0;
      _napieladas[_ptindex] := 0;
      inc(_ptindex);
    end;

  _xx := 1;
  while _xx<=28 do
    begin
      _keszlet[0,_xx] := 0;
      _forgvet[0,_xx] := 0;
      _forgelad[0,_xx]:= 0;
      inc(_xx);
    end;

  // --------------------------------------

  _ptindex := 1;
  while _ptindex<=_ptdarab do
    begin
      _xx := 1;
      while _xx<=28 do
        begin
          _keszlet[0,_xx] := _keszlet[0,_xx] + _keszlet[_ptindex,_xx];
          _forgvet[0,_xx] := _forgvet[0,_xx] + _forgvet[_ptindex,_xx];
          _forgelad[0,_xx] := _forgelad[0,_xx] + _forgelad[_ptindex,_xx];

          if _xx=_hufindex then
            begin
              _napivetel[_ptindex] := _napivetel[_ptindex] + _forgvet[_ptindex,_xx];
              _napieladas[_ptindex] := _napieladas[_ptindex] + _forgelad[_ptindex,_xx];
            end;
          inc(_xx);
        end;
      inc(_ptindex);
    end;
end;


////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                PK-FILEOK DEKODOLÁSA A TÖMB VÁLTOZÓKBA               ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   procedure TPillKeszForm.PkDekodolo;
// =============================================================================

var _nums: string;
    _aktnum,_cc: byte;
    _qev,_qhonap,_qnap,_qora,_qperc: word;
    _aktkeszlet,_aktkeszletft,_aktvetel,_aktvetelft,_akteladas,_akteladasft: integer;

begin
  _pkindex := 1;
  while _pkindex<=_pkdb do
    begin
      _aktfilenev := _pkfile[_pkindex];
      _aktpath := 'c:\ertektar\pillkesz\' + _aktfilenev;

      if not fileExists(_aktpath) then
        begin
          inc(_pkindex);
          continue;
        end;

      _nums := midstr(_aktfilenev,3,3);
      val(_nums,_aktnum,_code);
      if _code<>0 then _aktnum := 0;

      if _aktnum=0 then
        begin
          inc(_pkindex);
          continue;
        end;

      _ptindex := scanPenztar(_aktnum);

      Assignfile(_olvas,_aktpath);
      Reset(_olvas);
      Blockread(_olvas,_btomb,737);
      CloseFile(_olvas);

  // ----------------------------------------------------------------------
      _qSumForint := 0;
      _qSumValuta := 0;

      _qEv    := _btomb[1];
      _qHonap := _btomb[2];
      _qNap   := _btomb[3];
      _qOra   := _btomb[4];
      _qPerc  := _btomb[5];

      _datums[_ptindex] := inttostr(_qEv)+'.'+nulele(_qhonap)+'.'+nulele(_qnap);

      _vanfoglalo := False;
      if _qPerc>=100 then
        begin
          _qPerc      := _qPerc-100;
          _vanfoglalo := true;
        end;

      _Idos[_ptIndex]   := nulele(_qora)+':'+nulele(_qPerc);

//  _valutadarab :=  _bTomb[6];           // = 28 (valutadarab) CONSTANS

      _kodpointer := 7;
      _cc := 1;
      while _cc<=27 do    // valuta darab= 28
        begin
          _aktdnem     := Dnemdekod;
          _aktkeszlet  := DarabDekod;
          _aktkeszletft:= DarabDekod;
          _aktvetel    := Darabdekod;
                          Darabdekod;    // aktvetelft
          _akteladas   := DarabDekod;
                          Darabdekod;    // akteladasft

          _xx := Scandnem(_aktdnem);           // Mi a valuta sorszáma (1..24)

          if _aktdnem='HUF' then _qSumforint := _aktkeszlet
          else _qSumValuta := _qSumValuta + _aktkeszletFt;

          _Keszlet[_ptindex,_xx]  := _aktkeszlet;
      //    _keszletft[_xx]         := _aktkeszletft;
          _forgVet[_ptindex,_xx]  := _aktVetel;
          _forgElad[_ptindex,_xx] := _akteladas;

          inc(_cc);
        end;

      _valutaertek[_ptindex] := _qSumValuta;
      _forintertek[_ptindex] := _qSumForint;

  // Az összes valuta adata fel van dolgozva, jöhet a következõ 16 byte
  // ami 4 double-word-ot tartalmaz:

      _WuUsd[_ptindex]   := DarabDekod;  // Az iroda w.u. dollár készlete 1-4
      _WuHuf[_ptIndex]   := Darabdekod;  // Az iroda w.u. forint készlete 5-8
      _Afa[_ptindex]     := DarabDekod;  // Az iroda afa készlete 9-12 byte
      _Kezdij[_ptindex]  := Darabdekod;  // Az aktuális kezelési díj
      _Eker[_ptindex]    := Darabdekod;  // Az aktualis e-keredkedelem forintja
      _Foglalo[_ptindex] := darabdekod;

      _WuUsdertek[_ptindex] := trunc(_qUsdElszarf/100*_qWuUsd);

      inc(_pkindex);
    end;
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


// =============================================================================
                 procedure TPillKeszFORM.AdatDisplay;
// =============================================================================

begin
  ptarcombo.ItemIndex := _pix;

  EgypenztarDisplay(_pix);
  with AlapPanel do
    begin
      Top := 0;
      Left := 0;
      Visible := True;
      Repaint;
    end;
end;

// =============================================================================
               function TPIllkeszForm.Nul3(_n: byte): string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<3 do result := '0'+result;
end;


// =============================================================================
          procedure TPillkeszForm.KILEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _vanarfPanel then
    begin
      _vanarfPanel := False;
      Aktarfpanel.visible := False;
      Arfolyamgomb.Enabled := True;
      exit;
    end;
  FrissitoTimer.Enabled := False;
  Modalresult := 1;
end;

// =============================================================================
           procedure TPillkeszForm.PTARCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _pix := ptarcombo.itemindex;
  EgypenztarDisplay(_pix);
end;

// =============================================================================
         procedure TPillkeszForm.INFOBACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  INFOPANEL.Visible := False;
end;

// =============================================================================
          procedure TPillkeszForm.PF1MouseMove(Sender: TObject;
                                              Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  _dix := TPanel(Sender).Tag;
  if _dix=_dux then exit;
  if _dix>=20 then inc(_dix);
  _dux := _dix;
  _aktdnem := _dnem[_dix];
  _aktdnev := _dnev[_dix];

  _aktkeszlet := _keszlet[_pix,_dix];
  _aktvetel   := _forgvet[_pix,_dix];
  _akteladas  := _forgelad[_pix,_dix];

  _aktvarf := _varf[_pix,_dix];
  _aktearf := _earf[_pix,_dix];
  _aktelszarf := _elszarf[_pix,_dix];

  _aktk1v := _k1varf[_pix,_dix];
  _aktk2v := _k2varf[_pix,_dix];

  _aktk1e := _k1earf[_pix,_dix];
  _aktk2e := _k2earf[_pix,_dix];

  _aktshkv := _shkvet[_pix,_dix];
  _aktshke := _shkelad[_pix,_dix];

  _aktzaszlopath := 'c:\ertektar\flags\'+_aktdnem+'.jpg';

  dnemPanel.Caption := _aktdnem;
  dnevPanel.Caption := _aktdnev;

  eav.Text := arfform(_aktvarf);
  eel.Text := arfform(_aktelszarf);
  eae.Text := arfform(_aktearf);

  ek1v.Text := arfform(_aktk1v);
  ek1e.Text := arfform(_aktk1e);

  ek2v.Text := arfform(_aktk2v);
  ek2e.Text := arfform(_aktk2e);

  esv.Text  := arfform(_aktshkv);
  ese.Text  := arfform(_aktshke);

  ek.Text   := ftform(_aktkeszlet);
  efv.Text  := Ftform(_aktvetel);
  efe.text  := Ftform(_akteladas);

  Zaszlo.Picture.LoadFromFile(_aktzaszlopath);
  if infopanel.Visible then exit;

  with Infopanel do
    begin
      top := 392;
      left := 120;
      Visible := True;
      Repaint;
    end;
  ActiveControl := InfoBackGomb;
end;

// =============================================================================
        procedure TPillkeszForm.ALAPPANELMouseMove(Sender: TObject;
                                             Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  Infopanel.Visible := False;
  _dux := 0;
end;

// =============================================================================
         procedure TPillkeszForm.FRISSITOGOMBClick(Sender: TObject);
// =============================================================================

begin
  AdatFrissites;
  Adatdisplay;
end;

// =============================================================================
                         procedure TPillkeszForm.feherito;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  while _y<=24 do
    begin
      _aktpanel := _pf[_y];
      _aktpanel.Color := clWhite;
      _aktpanel.Font.Color := clBlack;
      inc(_y);
    end;

  _y := 4;
  while _y<=8 do
    begin
      _aktpanel := _ps[_y];
      _aktpanel.Color := clWhite;
      _aktpanel.Font.Color := clBlack;
      inc(_y);
    end;

  _y := 1;
  while _y<=7 do
    begin
      _aktpanel := _ff[_y];
      _aktpanel.Color := clWhite;
      _aktpanel.Font.Color := clBlack;
      inc(_y);
    end;

  _y := 1;
  while _y<=5 do
    begin
      _aktpanel := _mf[_y];
      _aktpanel.Color := clWhite;
      _aktpanel.Font.Color := clBlack;

       _aktpanel := _of[_y];
      _aktpanel.Color := clWhite;
      _aktpanel.Font.Color := clBlack;

      inc(_y);
    end;

  _aktpanel := TF1;
  _aktpanel.Color := clWhite;
  _aktpanel.Font.Color := clBlack;

  _y := 1;
  while _y<=28 do
    begin
      _k[_y].color := clWhite;
      _fv[_y].Color := clWhite;
      _fe[_y].color := clWhite;
      _av[_y].Color := clWhite;
      _ae[_y].color := clWhite;
      _el[_y].Color := clwhite;
      _k1v[_y].Color := clWhite;
      _k1e[_y].Color := clwhite;
      _k2v[_y].Color := clWhite;
      _k2e[_y].Color := clwhite;
      _sv[_y].Color := clwhite;
      _se[_y].Color := clwhite;
      inc(_y);
    end;

  with Arfolyamracs do
    begin
      color := clWhite;
      Font.Color := clBlack;
    end;


end;

// =============================================================================
             procedure TPillkeszForm.PS1Click(Sender: TObject);
// =============================================================================

begin
  Feherito;
end;

// =============================================================================
                       procedure TPillkeszForm.kistombbe;
// =============================================================================

begin
  _pf[1] := PF1;
  _pf[2] := PF2;
  _pf[3] := PF3;
  _pf[4] := PF4;
  _pf[5] := PF5;
  _pf[6] := PF6;
  _pf[7] := PF7;
  _pf[8] := PF8;
  _pf[9] := PF9;
  _pf[10]:= PF10;
  _pf[11]:= PF11;
  _pf[12]:= PF12;
  _pf[13]:= PF13;
  _pf[14]:= PF14;
  _pf[15]:= PF15;
  _pf[16]:= PF16;
  _pf[17]:= PF17;
  _pf[18]:= PF18;
  _pf[19]:= PF19;
  _pf[20]:= PF20;
  _pf[21]:= PF21;
  _pf[22]:= PF22;
  _pf[23]:= DTPANEL;
  _pf[24]:= TMPANEL;

  _ps[4] := PS4;
  _ps[5] := PS5;
  _ps[6] := PS6;
  _ps[7] := PS7;
  _ps[8] := PS8;

  _ff[1] := FF1;
  _ff[2] := FF2;
  _ff[3] := FF3;
  _ff[4] := FF4;
  _ff[5] := FF5;
  _ff[6] := FF6;
  _ff[7] := FF7;

  _mf[1] := MF1;
  _mf[2] := MF2;
  _mf[3] := MF3;
  _mf[4] := MF4;
  _mf[5] := MF5;

  _of[1] := OF1;
  _of[2] := OF2;
  _of[3] := OF3;
  _of[4] := OF4;
  _of[5] := OF5;

END;

// =============================================================================
            procedure TPillkeszForm.PS2Click(Sender: TObject);
// =============================================================================

begin
  Szinezo;
end;

// =============================================================================
                        procedure TPillkeszForm.Szinezo;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  while _y<=24 do
    begin
      _aktpanel := _pf[_y];
      _aktpanel.Color := clRed;
      _aktpanel.Font.Color := clWhite;
      inc(_y);
    end;

  _y := 4;
  while _y<=8 do
    begin
      _aktpanel := _ps[_y];
      _aktpanel.Color := clRed;
      _aktpanel.Font.Color := clYellow;
      inc(_y);
    end;

  _y := 1;
  while _y<=7 do
    begin
      _aktpanel := _ff[_y];
      _aktpanel.Color := clBlack;
      _aktpanel.Font.Color := clWhite;
      inc(_y);
    end;

  _y := 1;
  while _y<=5 do
    begin
      _aktpanel := _mf[_y];
      _aktpanel.Color := clMaroon;
      _aktpanel.Font.Color := clWhite;

       _aktpanel := _of[_y];
      _aktpanel.Color := clOlive;
      _aktpanel.Font.Color := clWhite;

      inc(_y);
    end;

  _aktpanel := TF1;
  _aktpanel.Color := clTeal;
  _aktpanel.Font.Color := clWhite;

  _y := 1;
  while _y<=28 do
    begin
      _k[_y].color := $FFFFD0;
      _fv[_y].Color := $FFD0FF;
      _fe[_y].Color := $D0FFFF;
      _av[_y].color := $FFD0FF;
      _ae[_y].Color := $D0FFFF;
      _el[_y].Color := $FFFFD0;
      _k1v[_y].Color := $FFD0FF;
      _k1e[_y].Color := $D0FFFF;
      _k2v[_y].Color := $FFD0FF;
      _k2e[_y].Color := $D0FFFF;
      _sv[_y].Color  := $FFD0FF;
      _se[_y].Color := $D0FFFF;
      inc(_y);
    end;

   _k[6].Color := $FFFF80;
  _k[10].Color := $FFFF80;
  _k[11].Color := $FFFF80;
  _k[27].Color := $FFFF80;

  _el[6].Color  := $FFFF80;
  _el[10].Color := $FFFF80;
  _el[11].Color := $FFFF80;
  _el[27].Color := $FFFF80;

  _fv[6].Color  := $FF80FF;
  _fv[10].Color := $FF80FF;
  _fv[11].Color := $FF80FF;
  _fv[27].Color := $FF80FF;

  _Av[6].Color  := $FF80FF;
  _Av[10].Color := $FF80FF;
  _Av[11].Color := $FF80FF;
  _Av[27].Color := $FF80FF;

  _k1v[6].Color  := $FF80FF;
  _k1v[10].Color := $FF80FF;
  _k1v[11].Color := $FF80FF;
  _k1v[27].Color := $FF80FF;

  _k2v[6].Color  := $FF80FF;
  _k2v[10].Color := $FF80FF;
  _k2v[11].Color := $FF80FF;
  _k2v[27].Color := $FF80FF;

  _sv[6].Color  := $FF80FF;
  _sv[10].Color := $FF80FF;
  _sv[11].Color := $FF80FF;
  _sv[27].Color := $FF80FF;

  _fe[6].Color  := $80FFFF;
  _fe[10].Color := $80FFFF;
  _fe[11].Color := $80FFFF;
  _fe[27].Color := $80FFFF;

  _Ae[6].Color  := $80FFFF;
  _Ae[10].Color := $80FFFF;
  _Ae[11].Color := $80FFFF;
  _Ae[27].Color := $80FFFF;

  _k1e[6].Color  := $80FFFF;
  _k1e[10].Color := $80FFFF;
  _k1e[11].Color := $80FFFF;
  _k1e[27].Color := $80FFFF;

  _k2e[6].Color  := $80FFFF;
  _k2e[10].Color := $80FFFF;
  _k2e[11].Color := $80FFFF;
  _k2e[27].Color := $80FFFF;

  _se[6].Color  := $80FFFF;
  _se[10].Color := $80FFFF;
  _se[11].Color := $80FFFF;
  _se[27].Color := $80FFFF;

  with Arfolyamracs do
    begin
      color := clBlack;
      Font.Color := clWhite;
    end;


end;

// =============================================================================
                     procedure TPillkeszform.dirtorles;
// =============================================================================

var _srec: Tsearchrec;
    _deldb,_y: byte;
    _dfile,_delpath: string;
    _delfile: array[1..50] of string;

begin
  _minta := 'c:\ertektar\pillkesz\pk*.*';

  _deldb := 0;
  if FindFirst(_minta, faAnyfile, _srec) = 0 then
    begin
       repeat
         inc(_deldb);
         _delfile[_deldb] := _srec.name;
       until FindNext(_srec) <> 0;
       FindClose(_srec);
     end;

   _y := 1;
   while _y<=_deldb do
     begin
       _dfile := _delfile[_y];
       _delpath := 'c:\ertektar\pillkesz\'+_dfile;
       sysutils.DeleteFile(_delpath);
       inc(_y);
     end;

   Sysutils.DeleteFile(_arfolyamdat);

end;



procedure TPillkeszForm.NYOMTATOGOMBClick(Sender: TObject);
begin
  if Printdialog1.Execute then
    begin
      Printer.Orientation := poLandscape;
      Feherito;
      Print;
      szinezo;
    end;

end;

procedure TPillkeszForm.ARFOLYAMGOMBClick(Sender: TObject);
begin
  if _ptss=0 then exit;

  ArfolyamGomb.Enabled := False;

  with Aktarfpanel do
    begin
      top := 42;
      left := 29;
      visible := True;
      repaint;
    end;
  _vanarfPanel := true;
  ArfolyamRacs.SetFocus;
end;

procedure TpillkeszForm.AktarfFeltoltes;

var _aktvet,_aktelad,_aktelsz: word;

begin

  AktarfSource.enabled := False;

  _pcs := 'DELETE FROM AKTARF';
  AktaParancs(_pcs);

  _xx := 1;
  while _xx<=28 do
    begin
      _aktdnem := _dnem[_xx];
      _aktvet  := _varf[_ptss,_xx];
      _aktelad := _earf[_ptss,_xx];
      _aktelsz := _elszarf[_ptss,_xx];

      _pcs := 'INSERT INTO AKTARF (VALUTANEM,VETELIARFOLYAM,ELADASIARFOLYAM,';
      _pcs := _pcs + 'ELSZAMOLASIARFOLYAM)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + chr(39) + arfform(_aktvet) + chr(39) + ',';
      _pcs := _pcs + chr(39) + arfform(_aktelad) + chr(39) + ',';
      _pcs := _pcs + chr(39) + arfform(_aktelsz) + chr(39) + ')';
      AktaParancs(_pcs);
      inc(_xx);
    end;
  _pcs := 'SELECT * FROM AKTARF' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM<>'+chr(39)+'HUF'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';
  Aktarfdbase.Connected := True;
  with AktarfQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;
  AktarfSource.enabled := true;
end;

procedure TPillkeszForm.AktaParancs(_ukaz: string);

begin
  Aktarfdbase.connected := true;
  if Aktarftranz.InTransaction then aktarftranz.Commit;
  Aktarftranz.StartTransaction;
  with Aktarfquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Aktarftranz.Commit;
  aktarfdbase.close;

end;

procedure TPillkeszForm.MNBGOMBClick(Sender: TObject);
begin
  // mnb arfolyam letöltése

 FtpszerverbeBelep;
 if _hFTP=Nil then
   begin
     Showmessage('NEM TUDOK A SZERVERRE LÉPNI');
     exit;
   end;

 _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\ARFOLYAM'));
 if _sikeres then
   begin
     _kit := Kitkod(_mamas);
     _mnbFile := 'AF100.'+_kit;
     _mnbPath := 'c:\ertektar\in\' + _mnbFile;

     if fileExists(_mnbpath) then sysutils.DeleteFile(_mnbPath);
     _sikeres := ftpgetfile(_hFtp,pchar(_mnbFile),pchar(_mnbPath),false,0,FTP_TRANSFER_TYPE_BINARY,0);
   end;
 InternetCloseHandle(_hFtp);
 InternetCloseHandle(_hNet);

 if not _sikeres then
   begin
     ShowMessage('NEM SIKERÜLT AZ MNB ÁRFOLYAMOK LETÖLTÉSE');
     EXIT;
   end;

 MNBFrissites;


end;

// =============================================================================
                function TPillKeszForm.Kitkod(_kdatum: string):string;
// =============================================================================

var _hos,_naps,_evs: string;
    _ev,_honap,_nap: word;

begin
   result := '000';
   if _kdatum='' then exit;

   _evs := leftstr(_kdatum,4);
   _hos := midstr(_kdatum,6,2);
   _naps:= midstr(_kdatum,9,2);

   val(_evs,_ev,_code);
   if _code<>0 then _ev := 0;

   val(_hos,_honap,_code);
   if _code<>0 then _honap := 0;

   val(_naps,_nap,_code);
   if _code<>0 then _ev := 0;

   if (_ev<2000) or (_ev>2036) then exit;

   _ev := _ev - 2000;
   _hos := chr(64+trunc(2*_honap));

   if _nap<10 then _naps := chr(48+_nap)
   else _naps := chr(55+_nap);

   _evs := chr(64+_ev);
   result := _naps + _evs + _hos;
end;

// =============================================================================
                  procedure TPillkeszform.MnbFrissites;
// =============================================================================

var
    _kodstr: string;
    i: integer;
  

begin
  if not fileexists(_mnbPath) then
    begin
      ShowMessage('NINCS A SZERVEREN MAI NAPI MNB ÁRFOLYAM RÖGZITVE');
      exit;
    end;

  AssignFile(_olvas,_mnbPath);  // arf100.ddd bedolgozása
  Reset(_olvas);
  BlockRead(_olvas,_byteTomb,1);
  _valutaDarab := _bytetomb[1];

  if _valutaDarab=0 then
    begin
      CloseFile(_olvas);
      DeleteFile(_mnbPath);
      ShowMessage('NINCSENEK ÁRFOLYAMOK AZ ADATOKBAN');
      Exit;
    end;

  ValutaDbase.Close;
  ValutaDbase.Connected := true;

  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;

  while true do
    begin
      BlockRead(_olvas,_byteTomb,2);
      if (_byteTomb[1]=255) and (_byteTomb[2]=255) then break;

      _kodstr := chr(_byteTomb[1])+chr(_byteTomb[2]);
      _aktdnem := dnem2dekod(_kodstr);

      BlockRead(_olvas,_byteTomb,5);
      _kodstr := chr(_byTeTomb[1]);

      for i := 2 to 5 do  _kodStr := _kodstr + chr(_byteTomb[i]);
      _elszamarfolyam := trunc(integDek(_kodstr)/10000);

      _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM='+inttoStr(_elszamarfolyam);
      _pcs := _pcs + ' WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);

      with ValutaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;
    end;

  CloseFile(_olvas);

  ValutaTranz.Commit;
  ValutaDbase.Close;

  MnbArfolyamNyomtatas;

  Showmessage('SIKERES MNB ARFOLYAM FRISSITÉS');
end;

// =============================================================================
           function TPillKeszForm.IntegDek(_5betu:string): integer;
// =============================================================================

var _a1,_a2,_a3,_a4,_a5,_negativ: integer;
    _r0,_r1,_r2,_r3,_r4,_big: real;

begin
  result := 0;

  if _5betu='' then exit;
  _a1 := ord(_5betu[1]);
  _a2 := ord(_5betu[2]);
  _a3 := ord(_5betu[3]);
  _a4 := ord(_5betu[4]);
  _a5 := ord(_5betu[5]);
  _negativ := 0;

  if _a1>127 then
    begin
      _a1 := _a1 - 128;
      _negativ := 1;
    end;
  _big := sqr(65536);
  _r0 := (1.00*_a5);
  _r1 := 256*_a4;
  _r2 := 65536*_a3;
  _r3 := 256*65536*_a2;
  _r4 := _big*_a1;

  result := trunc(_r0+_r1+_r2+_r3+_r4);

  if _negativ>0 then result := trunc(result*(-1));
end;


// =============================================================================
           function TPillKeszForm.Dnem2Dekod(_dkod:string):string;
// =============================================================================

var _a1,_a2,_x1,_x2,_x3: integer;

begin
  result := '';
  if _dkod='' then exit;
  _a1 := ord(_dkod[1]);    //  2
  _a2 := ord(_dkod[2]);    //  131

  _x1 := trunc(_a1/4);
  _x2 := trunc((_a1 and 3) * 8) + trunc(_a2/32);
  _x3 := (_a2 and 31);

  result := chr(_x1+65)+chr(_x2+65)+chr(_x3+65);
end;


procedure TPillkeszform.MnbArfolyamNyomtatas;

begin
  MnbFejlec;

  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';
  Valutadbase.Connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not ValutaQuery.Eof do
    begin
      _elszamarfolyam := ValutaQuery.FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      _aktdnem := ValutaQuery.FieldByNAme('VALUTANEM').AsString;
      writeLn(_Lfile,'              '+ _aktdnem+' - '+arfform(_elszamarfolyam));
      ValutaQuery.next;
    end;
  writeLn(_LFile,'---------------------------------------');
  ValutaQuery.Close;
  Valutadbase.close;
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  closeFile(_LFile);
  TextKiiro;
end;

// =============================================================================
      procedure TPillKeszForm.MNBFejlec;
// =============================================================================

begin

  assignFile(_LFile,'C:\ERTEKTAR\Aktlst.txt');
  Rewrite(_LFile);

  {
  ----------------------------------------
       A 2019.05.06-I MNB ARFOLYAMOK
  ----------------------------------------
                AUD - 312,40

  }

  writeLn(_LFile,'---------------------------------------');
  writeLn(_LFile,'     A ' + _mamas + '-I MNB ARFOLYAMOK');
  writeLn(_LFile,'---------------------------------------');

end;




// =============================================================================
                            procedure TPillkeszform.TextKiiro;
// =============================================================================

var
    _nyomtat,_olvas: textFile;
    _mondat: string;

begin
  AssignFile(_nyomtat,'LPT1:');
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\ertektar\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;




end.
