unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, wininet, IBDatabase, DB, IBQuery,
  IBCustomDataSet, IBTable, Grids, DBGrids, Buttons, StrUtils, printers,
  Mask, DBCtrls, TeeProcs, TeEngine, Chart, Series, Dateutils, jpeg;

type
  TPillkeszForm = class(TForm)

    INDITOTIMER: TTimer;
    KESZLETTABLA: TIBTable;
    KESZLETQUERY: TIBQuery;
    KESZLETDBASE: TIBDatabase;
    KESZLETTRANZ: TIBTransaction;
    KESZLETSOURCE: TDataSource;
    KILEPESGOMB: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;

    KeszletTablaIrodaszam: TIntegerField;
    KeszletTablaIrodanev: TIBStringField;
    KeszletTablaAUD: TIntegerField;
    KeszletTablaBGN: TIntegerField;
    KeszletTablaCAD: TIntegerField;
    KeszletTablaCHF: TIntegerField;
    KeszletTablaCZK: TIntegerField;
    KeszletTablaDKK: TIntegerField;
    KeszletTablaEUR: TIntegerField;
    KeszletTablaGBP: TIntegerField;
    KeszletTablaHRK: TIntegerField;
    KeszletTablaHUF: TIntegerField;
    KeszletTablaILS: TIntegerField;
    KeszletTablaJPY: TIntegerField;
    KeszletTablaNOK: TIntegerField;
    KeszletTablaPLN: TIntegerField;
    KeszletTablaRON: TIntegerField;
    KeszletTablaRSD: TIntegerField;
    KeszletTablaRUB: TIntegerField;
    KeszletTablaSEK: TIntegerField;
    KeszletTablaTRY: TIntegerField;
    KeszletTablaUAH: TIntegerField;
    KeszletTablaUSD: TIntegerField;
    KeszletTablaWU_USD: TIntegerField;
    KeszletTablaWU_HUF: TIntegerField;
    KeszletTablaAFA_FT: TIntegerField;
    KeszletTablaDatum: TIBStringField;
    KeszletTablaIdo: TIBStringField;
    KeszletTablaCNY: TIntegerField;
    KeszletTablaKezelesiDij: TIntegerField;
    KeszletTablaEkerKeszlet: TIntegerField;
    KeszletTablaVetelFT: TIntegerField;
    KeszletTablaEladasFT: TIntegerField;
    AdatFrissitoGom: TBitBtn;
    Panel51: TPanel;
    PTarSzamPanel: TPanel;
    Panel53: TPanel;
    Panel54: TPanel;
    Panel55: TPanel;
    Panel56: TPanel;
    Panel57: TPanel;
    Panel58: TPanel;
    Panel59: TPanel;
    Panel60: TPanel;
    Panel61: TPanel;
    Panel62: TPanel;
    K7PANEL: TPanel;
    K1PANEL: TPanel;
    K6PANEL: TPanel;
    K4PANEL: TPanel;
    K3PANEL: TPanel;
    Panel68: TPanel;
    K5PANEL: TPanel;
    Panel70: TPanel;
    Panel71: TPanel;
    Panel72: TPanel;
    Panel73: TPanel;
    Panel74: TPanel;
    Panel75: TPanel;
    K13PANEL: TPanel;
    VET2PANEL: TPanel;
    ELAD4PANEL: TPanel;
    ELAD6PANEL: TPanel;
    VET1PANEL: TPanel;
    K2PANEL: TPanel;
    Panel82: TPanel;
    VET5PANEL: TPanel;
    VET6PANEL: TPanel;
    Panel85: TPanel;
    Panel86: TPanel;
    Panel87: TPanel;
    Panel88: TPanel;
    ELAD5PANEL: TPanel;
    Panel90: TPanel;
    Panel91: TPanel;
    Panel92: TPanel;
    Panel93: TPanel;
    ELAD1PANEL: TPanel;
    VET3PANEL: TPanel;
    ELAD3PANEL: TPanel;
    ELAD2PANEL: TPanel;
    VET4PANEL: TPanel;
    VET7PANEL: TPanel;
    ELAD7PANEL: TPanel;
    Panel102: TPanel;
    Panel94: TPanel;
    Panel103: TPanel;
    WHUFPANEL: TPanel;
    WUSDPANEL: TPanel;
    Panel106: TPanel;
    Panel107: TPanel;
    Panel108: TPanel;
    Panel109: TPanel;
    Panel110: TPanel;
    Panel111: TPanel;
    K15PANEL: TPanel;
    VET15PANEL: TPanel;
    VET16PANEL: TPanel;
    VET17PANEL: TPanel;
    VET22PANEL: TPanel;
    VET21PANEL: TPanel;
    VET18PANEL: TPanel;
    VET20PANEL: TPanel;
    VET14PANEL: TPanel;
    K18PANEL: TPanel;
    K20PANEL: TPanel;
    K11PANEL: TPanel;
    K23PANEL: TPanel;
    K21PANEL: TPanel;
    K17PANEL: TPanel;
    K16PANEL: TPanel;
    VET13PANEL: TPanel;
    K9PANEL: TPanel;
    K8PANEL: TPanel;
    K10PANEL: TPanel;
    K22PANEL: TPanel;
    K19PANEL: TPanel;
    K14PANEL: TPanel;
    VET19PANEL: TPanel;
    ELAD16PANEL: TPanel;
    ELAD18PANEL: TPanel;
    ELAD19PANEL: TPanel;
    ELAD22PANEL: TPanel;
    ELAD20PANEL: TPanel;
    ELAD14PANEL: TPanel;
    ELAD15PANEL: TPanel;
    ELAD17PANEL: TPanel;
    ELAD23PANEL: TPanel;
    ELAD11PANEL: TPanel;
    ELAD10PANEL: TPanel;
    VET11PANEL: TPanel;
    ELAD9PANEL: TPanel;
    VET8PANEL: TPanel;
    VET9PANEL: TPanel;
    VET23PANEL: TPanel;
    VET10PANEL: TPanel;
    ELAD21PANEL: TPanel;
    ELAD8PANEL: TPanel;
    ELAD13PANEL: TPanel;
    Panel143: TPanel;
    Panel157: TPanel;
    Panel158: TPanel;
    KEZELESIDIJPANEL: TPanel;
    Panel160: TPanel;
    AFAFTPANEL: TPanel;
    EKERKESZLETPANEL: TPanel;
    EVPANEL: TPanel;
    IDOPANEL: TPanel;
    NAPSZAMPANEL: TPanel;
    HONEVPANEL: TPanel;
    Label1: TLabel;
    Panel15: TPanel;
    PTAR1PANEL: TPanel;
    PTAR6PANEL: TPanel;
    PTAR11PANEL: TPanel;
    PTAR16PANEL: TPanel;
    PTAR2PANEL: TPanel;
    PTAR3PANEL: TPanel;
    PTAR4PANEL: TPanel;
    PTAR5PANEL: TPanel;
    PTAR7PANEL: TPanel;
    PTAR8PANEL: TPanel;
    PTAR9PANEL: TPanel;
    PTAR10PANEL: TPanel;
    PTAR12PANEL: TPanel;
    PTAR13PANEL: TPanel;
    PTAR14PANEL: TPanel;
    PTAR17PANEL: TPanel;
    PTAR15PANEL: TPanel;
    PTAR18PANEL: TPanel;
    PTAR19PANEL: TPanel;
    PTOSSZESENPANEL: TPanel;
    Shape1: TShape;
    PENZTARNEVFOCIMPANEL: TPanel;
    Shape2: TShape;
    FUGGONYPANEL: TPanel;
    GRAFIKONGOMB: TBitBtn;
    KILEPOTIMER: TTimer;
    MEMOTABLA: TMemo;
    FILELISTA: TListBox;
    GRAFIKONPANEL: TPanel;
    GRAFIKON: TChart;
    ALSOCIMPANEL: TPanel;
    KORFORGALOMPANEL: TPanel;
    KORDIAGRAM: TChart;
    NAPIKORFORGALOM: TPieSeries;
    KORDIAGRAMGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    GroupBox1: TGroupBox;
    CSAKVASARLAS: TRadioButton;
    CSAKELADAS: TRadioButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    BitBtn1: TBitBtn;
    K12PANEL: TPanel;
    VET12PANEL: TPanel;
    ELAD12PANEL: TPanel;
    K24PANEL: TPanel;
    VET24PANEL: TPanel;
    ELAD24PANEL: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    PTAR21PANEL: TPanel;
    PTAR22PANEL: TPanel;
    PTAR23PANEL: TPanel;
    PTAR24PANEL: TPanel;
    PTAR20PANEL: TPanel;
    FOGLALOPANEL: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    FORINTPANEL: TPanel;
    VALUTAPANEL: TPanel;
    SERVERQUERY: TIBQuery;
    SERVERDBASE: TIBDatabase;
    SERVERTRANZ: TIBTransaction;
    TOTALPANEL: TPanel;
    ELAD28PANEL: TPanel;
    ELAD27PANEL: TPanel;
    ELAD26PANEL: TPanel;
    ELAD25PANEL: TPanel;
    VET27PANEL: TPanel;
    VET26PANEL: TPanel;
    VET25PANEL: TPanel;
    VET28PANEL: TPanel;
    K28PANEL: TPanel;
    K27PANEL: TPanel;
    K26PANEL: TPanel;
    K25PANEL: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    Image1: TImage;
    Panel23: TPanel;
    Panel24: TPanel;
    Panel25: TPanel;

    procedure AdatFrissites;
    procedure AdatFrissitoGomClick(Sender: TObject);
    procedure Adatnullazo;
    procedure AdatokTombbeOlvasasa;
    procedure AdatTablaClear;
    procedure AdatTablaDisplay(_ss: byte);
    procedure AdatSummazo;
    procedure EgyirodaDisplay(_is: integer);
    procedure FileEvolution;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FTPSzerverbeBelep;
    procedure GethardwareAdatok;
    procedure InditoTimerTimer(Sender: TObject);
    procedure KeszletDownLoad;
    procedure KilepesGombClick(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure OsszesTablaDisplay;
    procedure PenztarTablaClear;
    procedure PenztarTablaDisplay;
    procedure PenztarTablaSzinezo;
    procedure PTAR1PANELClick(Sender: TObject);
    procedure Ptar0PanelEnter(Sender: TObject);
    procedure PTAR1PANELMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure PtOsszesenPanelEnter(Sender: TObject);
    procedure PtOsszesenPanelClick(Sender: TObject);
    procedure PtOsszesenPanelExit(Sender: TObject);
    procedure Summanullazo;

    function Darabdekod: integer;
    function DnemDekod: string;
    function FtForm(_int: integer): string;
    function HunDatetostr(_caldat: TdateTime): string;
    function IrodaDatBeolvasas: BOOLEAN;
    function Irodascan(_pt: integer): string;
    function Nulele(_bb: byte): string;
    function Null3(_int: integer):string;
    function Scandnem(_dn: string): integer;
    function ScanIroda(_ptsz: integer):integer;
    function Vaninternet: boolean;
  

    /// ------------------------- grafikonok -----------------------------------

    procedure BitBtn1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure CsakEladasClick(Sender: TObject);
    procedure CsakVasarClick(Sender: TObject);
    procedure F1GombClick(Sender: TObject);
    procedure F2GombClick(Sender: TObject);
    procedure F3GombClick(Sender: TObject);
    procedure GrafikonDisplay;
    procedure GrafikonGombClick(Sender: TObject);
    procedure GrafikonPanelExit(Sender: TObject);
    procedure Kordiagramrutin;
    procedure KorDiagramGombClick(Sender: TObject);
    procedure Pitetolto(_pitetipus: integer);
    procedure SerialFree;
    procedure VisszaGombClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PillKeszForm: TPILLKESZForm;


  _kfDarab : integer;

  _kfIrodaSzam: array[1..24] of Integer;
  _kfIrodaNev : array[1..24] of string;

  _kfDatum,_kfIdo  : array[1..24] of string;
  _kfEker,_kfKezdij,_kfFoglalo: array[1..24] of Integer;
  _kfWusd,_kfWHuf,_kfWAfa: array[1..24] of Integer;

  _foglalodnem: array[1..24] of string;

  _kfKeszlet,_kfVetel,_kfEladas: array[1..24,1..27] of Integer;
  _kfValutaFt,_kfForintFt: array[1..27] of integer;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS',
            'JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER','NOVEMBER','DECEMBER');

  // ---------------------------------------------------------------------------

  _pillDir: string = 'C:\VALUTA\PILLKESZ';
  _binolvas: file of byte;
  _srec: TSearchrec;
  _hNet,_hFtp,_hsearch: HINTERNET;

  _host  :      string;
  _userid:      string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';
  _ftpPort:     integer = 21100;
  _findData    : WIN32_FIND_DATA;

  // ---------------------------------------------------------------------------

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                       'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN',
                       'NOK','NZD','PLN','RON','RSD','RUB','SEK','THB','TRY',
                       'UAH','USD');

  _hufindex: integer;
  _bytetomb: array[1..1024] of byte;
  _kpanel,_vpanel,_epanel: array[1..27] of TPanel;
  _ptPanel: array[1..24] of TPanel;

  _sumKeszlet,_sumvetel,_sumeladas: array[1..27] of integer;
  _sumwUsd,_sumwHuf,_sumWafa,_sumeker,_sumkezdij,_total: integer;
  _sumvalutaft,_sumforintFT: integer;

  _pkfForintFt,_pkfValutaFt,_pkfwusd,_pkfWhuf,_pkfWafa,_pkfEker: integer;
  _pkfkezdij,_pkfFoglalo,_pkfTotal,_usdelszarf,_pkfwusdFt: integer;
  _pfogdnem: string;


  _lastMTag,_aktMtag,_lastTag,_aktTag,_forintKeszlet,_valutakeszlet: integer;
  _aktPanel : TPanel;

  _pszin: array[0..20] of TColor;

  _kev,_kho,_knap,_kora,_kperc,_pp,_kk,_AA: word;

  _mResult,_lastirodasorszam,_ss,_sIrodaDarab: integer;
  _irodasorszam,_aktirodaszam,_valss,_aktho,_ertektar,_meret,_qq,_xx: integer;

  _kAdat,_vAdat,_eAdat,_aktft,_sft,_hufft,_uzlet: integer;
  _sorveg: string = chr(13)+chr(10);

  _vanfoglalo: boolean;

  _aktdatum,_aktevs,_aktnap,_aktfilenev,_aktfilePath,_remotefile: string;
  _localpath,_pcs,_minta,_mamas,_uznev: string;

  _sIrodaszam: array[0..40] of integer;
  _sIrodanev: array[0..40] of string;

  _sikeres: boolean;
  _pTag: byte;

  _kellVasarlas,_vanVasarlasTabla: boolean;
  _kellEladas,_vanEladasTabla: boolean;
  _aktirodasorszam: integer;
  _ezOsszesen: boolean;

  Vasarlas,Eladas: TBarseries;

function pillanatnyikeszlet: integer; stdcall;

implementation

{$R *.dfm}


(*
 A keszlet file-ok neve:  PKppp.etar   (ppp= péntár száma (pl: 035)

 struktura: ev(byte)+ho(byte)+nap(byte)+ora(byte)+perc(byte)
            valutadarab(byte) = 27
            --------- ciklus fej ---------------

              dnemkod (word)
              keszlet   (dword)
              keszletft (dword)

              vetel     (dword)
              vetelft   (dword)

              eladas    (dword)
              eladasft  (dword)

            --------- ciklus láb -----------------

            wu.usd (dword)
            wu.huf (dword)
            afa ft (dword)

            kez-i dij(dword)
            eker ft(dword)

            végjel = 255-255-255

            A file teljes hossza = 601 byte
*)

// =============================================================================
            function pillanatnyikeszlet: integer; stdcall;
// =============================================================================


begin
  PillKeszform := TPillkeszform.Create(Nil);
  result := Pillkeszform.showmodal;
  Pillkeszform.ShowModal;
end;



// =============================================================================
            procedure TPILLKESZForm.FormActivate(Sender: TObject);
// =============================================================================

var _height,_width: word;

begin
  _Height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  Top    := trunc((_height-768)/2);
  Left   := trunc((_width-1024)/2);
  Width  := 1024;
  Height := 768;

  if _aa>0 then
    begin
      KilepoTimer.Enabled := true;
      exit;
    end;


  GrafikonPanel.Visible := false;
  with FuggonyPanel do
    begin
      Top  := 96;
      Left := 3;
      Visible := true;
    end;

  _mResult := 2;
  _mamas := Hundatetostr(date);

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

  InditoTimer.enabled := true;
end;

// =============================================================================
           procedure TPILLKESZForm.INDITOTIMERTimer(Sender: TObject);
// =============================================================================


begin
  InditoTimer.Enabled := False;

  _hufindex := scandnem('HUF');

  // Csak értéktárnál használatos ....

  GethardwareAdatok;  // gépfunkcio és értéktár beolvasása

  // Ha sehol se találok irodaadatokat, akkor ez nem megy ....
  // (_sIrodaDarab, _sIrodaszam, _sIrodaNev[0.. _sIrodaDarab-1]

  if not IrodadatBeolvasas then
    begin
      KilepoTimer.Enabled := true;
      exit;
    end;
  Adatfrissites;
end;

{
// =============================================================================
              function TPillKeszFORM.IrodaDatBeolvasas: boolean;
// =============================================================================

  Feladata: A c:\valuta\irodak\irodak.dat nevü file-ból kell kinyerni az
              irodaszámokat és irodaneveket (_sirodaszam,_sirodanev nevü
              tömbökbe. _sirodadarab pénztárt tud a tömbökbe olvasni.

              Az irodak.dat file-t mindenképpen megprobálja frissiteni az
              FTP-szerverrõl az \IRODAK nevü könyvtár IRODAK.DAT nevü
              file-jával.

              Ha nem tudja frissiteni, akkor a meglévõ adatokat használja fel.
              Ha nem áll rendelkezésre mentett DAT file és nem is tudja azt
              letölteni, akkor ennek a programnak vége);



var _irodadarab,_hossz: integer;
     _ptVarosnev,_etBoltNev,_etirodanev: string;

    _etIrodaszam,_ptErtektar,_t: byte;



begin

  Result := False;
  FTPszerverbeBelep;
  _localPath  := 'c:\valuta\IRODAK\IRODAK.DAT';

  if _hFTP<>NIL then
    begin
      _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\IRODAK'));
      if _sikeres then
        begin
          _remoteFile := 'IRODAK.DAT';
          if FileExists(_localPath) then Deletefile(_localPath);

          FTPGetfile(_hFTP,pchar(_remoteFile),pchar(_localPath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);
        end;

      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
    end;

  // ---------------------------------------------------------------------------

  if not Fileexists(_localPath) then
    begin
      ShowMessage('NEM TALÁLOM AZ IRODAK.DAT FILE-T');
      exit;
    end;

  AssignFile(_binolvas,_localPath);
  Reset(_binolvas);

  Blockread(_binolvas,_bytetomb,1);
  _sIrodaDarab := _byteTomb[1];

  Setlength(_sIrodaszam,_sIrodaDarab);
  Setlength(_sIrodanev,_sIrodaDarab);

  _qq := 0;
  _Irodadarab := 0;
  while _qq<_SIrodaDarab do
    begin
      BlockRead(_binolvas,_byteTomb,3);

      _etIrodaszam := _bytetomb[1];
      _ptErtekTar  := _bytetomb[2];

      _hossz := _byteTomb[3];
      _ptvarosnev := '';

      if _hossz>0 then
        begin
          Blockread(_binolvas,_bytetomb,_hossz);
          for _t := 1 to _hossz do _ptvarosnev := _ptvarosnev + chr(255-_bytetomb[_t]);
        end;

      _ptVarosnev := trim(_ptVarosNev);
      BlockRead(_binolvas,_bytetomb,1);

      _hossz     := _byteTomb[1];
      _etboltnev := '';

      if _hossz>0 then
        begin
          Blockread(_binolvas,_bytetomb,_hossz);
          for _t := 1 to _hossz do _etboltnev := _etboltnev + chr(255-_bytetomb[_t]);
        end;

      _etBoltnev  := trim(_etBoltNev);
      _etIrodanev := _ptVarosnev + ' ' + _etBoltnev;
      _etIrodaNev := leftstr(_etIrodanev,24);

      if _ptErtektar=_ertektar then
        begin
          _sIrodaSzam[_IrodaDarab]:= _etIrodaszam;
          _sIrodanev[_irodaDarab] := _etIrodaNev;
          inc(_Irodadarab);
        end;
      inc(_qq);
    end;
  _sIrodaDarab := _irodaDarab;
  Result := True;
end;
}


//==============================================================================
                 function TPillKeszFORM.IrodaDatBeolvasas: boolean;
// =============================================================================


begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (CLOSED<>'+CHR(39)+'X'+chr(39)+')';
  _pcs := _pcs + ' AND (ERTEKTAR='+INTTOSTR(_ERTEKTAR)+')';

  serverDbase.close;
  Serverdbase.DatabaseName := '185.43.207.99:C:\RECEPTOR\DATABASE\RECEPTOR.FDB';
  Serverdbase.Connected := true;

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _SirodaDarab := 0;
  while not ServerQuery.Eof do
    begin
      _uzlet := Serverquery.FieldbyName('UZLET').asInteger;
      _uznev := trim(ServerQuery.fieldByName('KESZLETNEV').AsString);
      _sIrodaSzam[_Sirodadarab] := _uzlet;
      _sIrodanev[_SirodaDarab] := _uznev;
      inc(_SirodaDarab);
      serverQuery.next;
    end;
  ServerQuery.close;
  Serverdbase.close;

  result := true;
end;

// =============================================================================
                      procedure TPillKeszForm.FTPszerverbeBelep;
// =============================================================================


begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      ShowMessage('Nem tlálom a WININET.DLL libraryt');
      Exit;
    end;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then
    begin
      Showmessage('A szerver nem érhetõ el !');
      InternetCloseHandle(_hNet);
    end;
end;

// =============================================================================
               procedure TPillkeszform.GethardwareAdatok;
// =============================================================================

// Feladata: gepfunkcio,ertektar beolvasása

var _pts: string;
    _code: integer;

begin

  ValutaDbase.connected := true;
  with valutaQuery do
    begin
      close;
      Sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
      Close;
      Sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      _pts := trim(FieldByName('PENZTARKOD').asstring);
      close;
      val(_pts,_ertektar,_code);
    end;

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.add('SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'USD'+CHR(39));
      Open;
      _usdelszarf := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      Close;
    end;
  Valutadbase.close;
end;





// =============================================================================
           procedure TPillkeszForm.PTAR0PANELEnter(Sender: TObject);
// =============================================================================


begin
  _pTag := TPanel(sender).Tag;
  PenztarTablaSzinezo;
  if _ptag=_lastTag then exit;

  _lastTag  := _pTag;
  _aktPanel := _ptPanel[_pTag];

  _aktpanel.Color      := clBlack;
  _aktPanel.Font.Style := [fsBold];
  _aktpanel.Font.Color := clWhite;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// **************************  GRAFIKON PROGRAMOK ******************************
// =============================================================================
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
      _vanVasarlasTabla := true;
      Alsocimpanel.Caption := 'A MAI NAPI VÁSÁRLÁSOK (Ft)';
      AlsoCimpanel.repaint;

      with Vasarlas do
        begin
          for i := 0 to _KFDARAB-1 do Add(i,inttostr(_kfIrodaszam[i]),clBlack);

          Marks.Visible := True;
          Marks.ArrowLength := 0;
          Marks.Visible := true;
          SeriesColor := clYellow;
          BarWidthPercent := 25;
          Name := 'VASARLAS';
          OffsetPercent := 15;

          with XValues do
            begin
              Name := 'X';
              MultiPlier := 1;
              Order := loAscending;
            end;

          with YValues do
            begin
              Name := 'Bar';
              MultiPlier := 1;
              Order := loNone;
            end;
        end;

      for i := 0 to _kfdarab-1 do            // @@@@
         begin
           _sb := _kfEladas[i,10];
           Vasarlas.AddXY(i,_sb);
           if _sb>_maxi then _maxi := _sb;
         end;
    end;

  if _kellEladas then
    begin
      Eladas := TBarSeries.Create(Grafikon);
      Eladas.ParentChart := Grafikon;
      _vaneladasTabla := true;
      Alsocimpanel.Caption := 'A MAI NAPI ELADÁSOK (Ft)';
      AlsoCimpanel.repaint;


      with Eladas do
         begin
           for i := 0 to _kfDarab-1 do Add(i,inttostr(_kfirodaszam[i]),clBlack);
           Marks.Visible := True;
           Marks.ArrowLength := 0;
           Marks.Visible := True;
           SeriesColor := clRed;
           BarWidthPercent := 25;
           Name := 'ELADAS';
           OffsetPercent := 15;

           with XValues do
             begin
               Name := 'X';
               MultiPlier := 1;
               Order := loAscending;
             end;

           with YValues do
             begin
               Name := 'Bar';
               Multiplier := 1;
               Order := loNone;
             end;
         end;

      for i := 0 to _kfDarab-1 do       // @@@@
        begin
          _se := _kfVetel[i,10];
          Eladas.addxy(i,_se);
          if _se>_maxi then _maxi := _se;
        end;
    end;

//  ErtekValtas;


  with Grafikon do
    begin
      LeftAxis.Maximum := (1.1*_maxi);
      BottomAxis.Maximum := _kfDarab;
      Visible := True;
    end;
 // ActiveControl := Kordiagramgomb;
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
  for i:= 1 to (_kfdarab) do
    begin
      _megnevezes := trim(_kfirodanev[i]);
      _sumVet  := _kfeladas[i,10];
      _sumElad := _kfVetel[i,10];
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
           procedure TPillkeszform.KORDIAGRAMGOMBClick(Sender: TObject);
// =============================================================================

begin
  SerialFree;
  KordiagramRutin;
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



procedure TPillkeszForm.ADATFRISSITOGOMClick(Sender: TObject);
begin
  GrafikonPanel.Visible := false;
  with FuggonyPanel do
    begin
      Top  := 96;
      Left := 3;
      Visible := true;
    end;
  ADATFRISSITES;
end;

// =============================================================================
             procedure TPillkeszForm.FormCreate(Sender: TObject);
// =============================================================================

begin
  _AA := 0;
end;

//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

// =============================================================================
                   procedure TPillkeszForm.AdatFrissites;
// =============================================================================

begin
  Memotabla.Lines.clear;
  Memotabla.clear;
  AdatNullazo;
  _lastirodaSorszam := -1;
  _aktirodasorszam := -1;
  _ezosszesen := false;
  _lastMTag := -1;

  // A Pillkesz könyvtárba letölti a szerver Pillkesz könyvtárban található
  // Pk-val kezdödö, és a kiterjesztése az értéktár száma file-okat
  // A letöltött file-ok darabszáma: _letolve

  KeszletDownLoad;

  AdatokTombbeOlvasasa;
  if _kfdarab=0 then
    begin
      SHowMessage('NEM TALÁLTAM EGYETLEN ADATOT SEM !');
      Kilepotimer.enabled := true;
      exit;
    end;

  AdatSummazo;
  PenztarTablaDisplay;

  Fuggonypanel.Visible := false;
  _aktirodasorszam := 0;
  Ptar1Panel.Color := clyellow;
  Ptar1Panel.Font.Style := [fsBold];
  Ptar1panel.Font.Color := clRed;
  EgyirodaDisplay(1);
end;


// =============================================================================
                   procedure TPillkeszForm.Adatnullazo;
// =============================================================================


var i,j: integer;

begin
  _kfdarab := 0;
  for i := 1 to 24 do
    begin
      for j := 1 to 27 do
        begin
          _kfKeszlet[i,j]:= 0;
          _kfVetel[i,j]  := 0;
          _kfEladas[i,j] := 0;
        end;

      _kfValutaft[i] := 0;
      _kfForintFt[i] := 0;
      _kfWusd[i]     := 0;
      _kfwhuf[i]     := 0;
      _kfwafa[i]     := 0;
      _kfkezdij[i]   := 0;
      _kfeker[i]     := 0;
      _kfFoglalo[i]  := 0;
      _foglalodnem[i]:= '';
    end;
end;


// =============================================================================
             procedure TPillkeszForm.KeszletDownLoad;
// =============================================================================


(*   Feladat: A szerver  \ PILLKESZ könyvtárból az összes PK*.ertektar
              mintájú file-t letölti (felülirja) a c:\valuta\pillkesz
              könyvtárba:


*)

var _keszletfiledarab,_letoltve: integer;


begin
  if not vanInternet then
    begin
      Memotabla.Lines.add('Nincs internet ! Nem tudom a készleteket frissiteni !');
      Memotabla.Lines.Add('Az utolsó mentett adatokat tudom mutatni');
      Sleep(2000);
      Exit;
    end;

  Memotabla.Lines.Add('Belépek a központi szerverre');
  MemoTabla.Repaint;

  FTPSzerverbeBelep;
  if _hFtp=Nil then exit;

  // ---------------------------------------------------------------------------

  Memotabla.Lines.Add('Belépek a PILLKESZ könyvtárba .. ');

  _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\PILLKESZ'));
  if not _sikeres then
    begin
      Memotabla.Lines.add('Nem tudtam belépni a PILLKESZ könyvtárba');

      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);

      Sleep(2000);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  _minta := 'pk*.' + inttostr(_ertektar);

  FileLista.Clear;
  FileLista.Items.Clear;

  _hSearch := FTPFindFirstFile(_hFTP,pchar(_minta),_findData,0,0);

  Memotabla.Lines.add('Keresem a friss készleteket');
  Memotabla.Repaint;

  if _hSearch=nil then
    begin
      MemoTabla.Lines.Add('Nem találtam friss készletjelentést');
      Memotabla.Repaint;
      Sleep(2000);

      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  repeat
    _aktfilenev := _findData.cFileName;
    Filelista.Items.Add(_aktfilenev);
  until not InternetFindNextFile(_hSearch,@_findData);
  InternetCloseHandle(_hSearch);

  // ---------------------------------------------------------------------------

  _keszletFiledarab := FileLista.Count;
  if _keszletFileDarab=0 then
    begin
      Memotabla.Lines.add('Nem találtam újabb készletjelentést');
      Memotabla.Repaint;
      sleep(2000);

      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  Memotabla.Lines.add(inttostr(_keszletFileDarab)+' készletjelentést találtam');
  Memotabla.repaint;
  Sleep(2000);

  // ---------------------------------------------------------------------------

  _qq       := 0;
  _letoltve := 0;

  while _qq<_keszletFileDarab do
    begin
      _aktfilenev := FileLista.items[_qq];
      _remoteFile := _aktfilenev;
      _localPath  := 'c:\valuta\pillkesz\' + _aktfilenev;

      if FileExists(_localPath) then Deletefile(_localPath);

      Memotabla.Lines.add(_remotefile+' LETÖLTÉSE ...');
      Memotabla.Repaint;

      _sikeres := FTPGetfile(_hFTP,pchar(_remoteFile),pchar(_localPath),false,
                                     0,FTP_TRANSFER_TYPE_BINARY,0);

      if _sikeres then inc(_letoltve);
      inc(_qq);
    end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  if _letoltve=0 then
    begin
      Memotabla.Lines.add('Nem tudtam letölteni friss készletjelentést');
      Memotabla.Repaint;
      sleep(2000);
      Exit;
    end;

  MemoTabla.lines.add(inttostr(_letoltve)+' darab friss készletjelentést töltöttem le');
  Memotabla.repaint;
  Sleep(1800);

end;


// =============================================================================
               procedure TPillkeszForm.AdatokTombbeOlvasasa;
// =============================================================================


var _aktFile: string;

begin

  _kfDarab := 0;
  _minta := 'C:\VALUTA\PILLKESZ\PK*.' + inttostr(_ertekTar);

  FileLista.Clear;
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _aktFileNev := _srec.Name;
        _aktfilePath := 'c:\valuta\pillkesz\'+_aktfilenev;

        AssignFile(_binOlvas,_aktFilePath);
        Reset(_binolvas);

        _meret := Filesize(_binolvas);
        CloseFile(_binOlvas);

        if _aktfilenev='PK034.20' then _meret := 0;

        if (_meret=633) or (_meret=659) or (_meret=737)  then FileLista.Items.add(_aktfilenev)
        else deleteFile(_aktFilepath);

      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  _kfDarab := FileLista.Count;
  if _kfDarab=0 then exit;

  // ---------------------------------------------------------------------------

  _qq := 0;
  _ss := 0;
  while _qq<_kfDarab do
    begin
      _aktfile := FileLista.Items[_qq];
      _aktIrodaszam := strtoint(midstr(_aktfile,3,3));
      _irodasorszam := ScanIroda(_aktIrodaszam);
      if _irodasorszam>-1 then
        begin
           INC(_SS);
          _kfIrodanev[_ss] := _sIrodaNev[_irodasorszam];
          _kfIrodaszam[_ss] := _aktirodaszam;

        end;
      inc(_qq);
    end;

  _kfDarab := _ss;
  if _ss= 0 then exit;

  // ---------------------------------------------------------------------------

  _irodaSorszam := 1;
  while _irodaSorszam<=_kfdarab do
    begin
      _aktIrodaszam := _kfIrodaszam[_irodaSorszam];
      _aktfilenev   := 'PK' + null3(_aktirodaszam)+'.'+inttostr(_ertektar);
      _aktfilePath := 'c:\valuta\pillkesz\'+_aktfileNev;

      Fileevolution;
      inc(_irodasorszam);
    end;
end;


// =============================================================================
                    procedure TPillkeszForm.FileEvolution;
// =============================================================================


var i,_sctrl,_vdarab,_meret: integer;
    _kdnem: string;

begin

  AssignFile(_binOlvas,_aktfilePath);
  Reset(_binOlvas);
  _meret := Filesize(_binolvas);
  BlockRead(_binolvas,_bytetomb,_meret);
  CloseFile(_binolvas);

  // -----------------------------------------------------------------------

  _kev  := 2000 + _bytetomb[1];
  _kho  := _bytetomb[2];
  _knap := _bytetomb[3];

  _KfDatum[_irodasorszam] := inttostr(_kev)+'.'+nulele(_kho)+'.'+nulele(_knap);

  _kora       := _bytetomb[4];
  _kperc      := _bytetomb[5];
  _vanfoglalo := False;
  if _kperc>=100 then
    begin
      _kperc := _kperc-100;
      _vanfoglalo := True;
    end;

  _kfIdo[_irodasorszam] := nulele(_kora)+':'+nulele(_kperc);
  _vdarab:= _bytetomb[6];   // mindig 27 !!!

  _kk := 1;
  _pp := 7;

  _sFt := 0;

  while _kk<=_vdarab do
    begin
      _kdnem            := Dnemdekod;
      _xx := ScanDnem(_kdnem);

      _kfkeszlet[_irodasorszam,_xx] := Darabdekod;  // keszlet
      _aktft := darabdekod;    // csak annamarinak kell       // ft

      if _xx<>_hufindex then _sFt := _sft + _aktft else _hufft := _aktft;

      _kfvetel[_irodasorszam,_xx]   := Darabdekod;   // vetel
      DarabDekod;     //  nem kell vetelft           //vetel ft

      _kfeladas[_irodasorszam,_xx]  := DarabDekod;  // eladas
      Darabdekod;     // nem kell eladasft          // ft

      inc(_kk);
    end;

  _kfValutaFt[_irodasorszam] := _sFt;
  _kfForintFt[_irodasorszam] := _hufft;

  _kfwusd[_irodaSorszam] := DarabDekod;
  _kfwhuf[_irodasorszam] := DarabDekod;
  _kfwafa[_irodasorszam] := Darabdekod;

  _kfkezdij[_irodasorszam] := DArabdekod;
  _kfeker[_irodasorszam]   := DarabDekod;

  if _vanfoglalo then
    begin
      _kfFoglalo[_irodasorszam] := Darabdekod;
      _foglalodnem[_irodasorszam] := DnemDekod;
    end;

  _sctrl := 0;
  for i := 0 to 2 do _sctrl := _sctrl + _bytetomb[_pp+i];

  if _sctrl<>765 then ShowMessage('Hibás '+inttostr(_aktirodaszam)+' készlete');
end;

// =============================================================================
                     procedure TPillkeszform.AdatSummazo;
// =============================================================================



begin
  SummaNullazo;
  _PP := 1;
  while _pp<=_kfDarab do
    begin
      _kk := 1;
      while _kk<=27 do
        begin
          _kAdat := _kfKeszlet[_pp,_kk];
          _vAdat := _kfVetel[_pp,_kk];
          _eAdat := _kfEladas[_pp,_kk];
          _sumkeszlet[_kk] := _sumkeszlet[_kk] + _kAdat;
          _sumvetel[_kk]   := _sumVetel[_kk]   + _vAdat;
          _sumeladas[_kk]  := _sumeladas[_kk]  + _eAdat;
          inc(_kk);
        end;

      _sumValutaFt := _sumValutaft + _kfValutaFt[_pp];
      _sumForintFt := _sumForintFt + _kfForintFt[_pp];
      _sumwUsd := _sumWUsd + _kfWUsd[_pp];
      _sumwHuf := _sumWHuf + _kfWHuf[_pp];
      _sumWafa := _sumWafa + _kfWafa[_pp];
      _sumeker := _sumeker + _kfEker[_pp];
      _sumKezdij := _sumkezdij + _kfKezdij[_pp];
      inc(_pp);
    end;
end;


// =============================================================================
                   procedure TPillkeszform.Summanullazo;
// =============================================================================

var i: integer;

begin
  for i := 1 to 27 do
    begin
      _sumkeszlet[i] := 0;
      _sumvetel[i] := 0;
      _sumeladas[i] := 0;
    end;

  _sumValutaft := 0;
  _sumForintFt := 0;
  _sumwUsd   := 0;
  _sumwHuf   := 0;
  _sumwAfa   := 0;
  _sumEker   := 0;
  _sumKezdij := 0;
end;

// =============================================================================
               procedure TPillkeszform.PenztarTablaDisplay;
// =============================================================================

var i: integer;
    _aktnev  : string;

begin
  PenztarTablaclear;
  for i := 1 to _kfdarab do
    begin
      _aktpanel := _ptPanel[i];
      _aktnev := _kfIrodanev[i];
      _aktpanel.Caption := _aktnev;
      _aktpanel.Enabled := true;
      _aktpanel.Repaint;
    end;
end;

// =============================================================================
                   procedure TPillKeszForm.PenztarTablaClear;
// =============================================================================

var i: integer;

begin
  for i := 1 to 24 do
    begin
      _aktpanel := _ptpanel[i];
      _aktPanel.Caption := '';
      _aktpanel.Enabled := false;
    end;
  PenztarTablaSzinezo;
end;

// =============================================================================
              procedure TPIllkeszForm.PenztarTablaSzinezo;
// =============================================================================

var i: integer;
    _col: Tcolor;

begin
  for i := 1 to 24 do
    begin
      _aktpanel := _ptPanel[i];
      if (i=_aktirodasorszam) then
        begin
          _aktpanel.Font.Color := clRed;
          _aktPanel.Font.Style := [fsBold];
          _aktPanel.Color := clYellow;
        end else
        begin
          _aktPanel.Font.Color := clBlack;
          _aktPanel.Font.Style := [];
          _col := clBtnFace;
          if i<5 then _col := clGray;
          if (i<10) and (i>4)  then _col := clMedGray;
          if (i<15) and (i>9)  then _col := clSilver;
          if (i<14) and (i<20) then _col := clScrollBar;
          if i>19 then _col := clBtnFace;
          _aktpanel.Color := _col;
        end;
    end;

  if _ezOsszesen then
    begin
      PtOsszesenPanel.Color := clRed;
      PtOsszesenPanel.Font.color := clYellow;
    end else
    begin
      PtOsszesenPanel.Color := clBtnFace;
      PtOsszesenPanel.Font.color := clRed;
    end;
end;

// =============================================================================
           procedure TPillkeszForm.EgyirodaDisplay(_is: integer);
// =============================================================================


begin
  _lastIrodasorszam := _is;
  PenztarTablaSzinezo;

  _ptpanel[_is].Color      := clYellow;
  _ptPanel[_is].Font.Color := clRed;

  AdatTablaDisplay(_is);
end;

// =============================================================================
             procedure TPillkeszform.AdatTablaDisplay(_ss: byte);
// =============================================================================

var _aktdatum,_aktevs,_aktidos,_aktnap: string;
    _aktho: word;


begin
  Adattablaclear;
  PenztarnevFocimPanel.Caption := _kfIrodanev[_ss];
  PenztarnevFocimPanel.Repaint;

  _aktirodaszam := _kfirodaszam[_ss];
  PtarszamPanel.Caption := inttostr(_aktirodaszam);
  PtarszamPanel.repaint;

  _aktdatum := _kfdatum[_ss];
  _aktevs   := leftstr(_aktdatum,4);
  _aktho    := strtoint(midstr(_aktdatum,6,2));
  _aktnap   := midstr(_aktdatum,9,2);
  _aktidos  := _kfIdo[_ss];

  Evpanel.Caption      := _aktevs;
  Honevpanel.Caption   := _honev[_aktho];
  NapszamPanel.Caption := _aktnap;
  IdoPanel.caption     := _aktidos;

  Evpanel.repaint;
  Honevpanel.repaint;
  NapszamPanel.repaint;
  Idopanel.Repaint;

  _pkfForintFt := _kfForintFt[_ss];
  _pkfValutaFt := _kfValutaFt[_ss];
  _pkfwUsd     := _kfWUsd[_ss];
  _pkfWHuf     := _kfWHuf[_ss];
  _pkfWAfa     := _kfWAfa[_ss];
  _pkfEker     := _kfEker[_ss];
  _pkfKezdij   := _kfKezdij[_ss];
  _pkfFoglalo  := _kfFoglalo[_ss];
  _pfogdnem    := _foglalodnem[_ss];

  _pkfWUsdFt := trunc(_pkfWUsd*_usdelszarf/100);

  _total := _pkfForintFt+_pkfValutaFt+_pkfWusdFt+_pkfWhuf+_pkfWafa+_pkfEker+_pkfKezdij;
  if _pfogdnem='HUF' then _total := _total + _pkfFoglalo;


  ForintPanel.Caption := FtForm(_pkfForintFt);
  ValutaPanel.caption := FtForm(_pkfValutaFt);

  WusdPanel.Caption := ftform(_pkfwusd);
  Whufpanel.Caption := ftform(_pkfwhuf);
  Afaftpanel.Caption := ftForm(_pkfWafa);
  Ekerkeszletpanel.Caption := ftform(_pkfeker);
  KezelesidijPanel.Caption := Ftform(_pkfKezdij);
  FoglaloPanel.Caption := ftform(_pkfFoglalo);
//  FogldnemPanel.Caption := _foglalodnem[_ss];

  TotalPanel.Caption := ftForm(_total);

  WusdPanel.Repaint;
  Whufpanel.Repaint;
  Afaftpanel.Repaint;
  Ekerkeszletpanel.Repaint;
  KezelesidijPanel.Repaint;
  Foglalopanel.Repaint;

  // --------------------------------------------------------------------

  _pp := 1;
  while _pp<=27 do
    begin
      _kadat := _kfKeszlet[_ss,_pp];
      _vadat := _kfVetel[_ss,_pp];
      _eadat := _kfEladas[_ss,_pp];

      _kPanel[_PP].caption := FtForm(_kadat);
      _vPanel[_PP].Caption := FtForm(_vadat);
      _ePanel[_PP].caption := FtForm(_eadat);

      _kpanel[_PP].Repaint;
      _vpanel[_PP].Repaint;
      _epanel[_PP].Repaint;
      inc(_pp);
    end;
end;


// =============================================================================
                   procedure TPillkeszForm.AdatTablaClear;
// =============================================================================

var i: integer;

begin
  Penztarnevfocimpanel.Caption := '';
  PtarSzamPanel.Caption := '';
  EvPanel.Caption := '';
  HonevPanel.Caption := '';
  NapszamPanel.Caption := '';
  IdoPanel.Caption := '';
  WusdPanel.Caption := '';
  WHufPanel.Caption := '';
  AfaFtPanel.Caption := '';
  EkerKeszletPanel.Caption := '';
  KezelesiDijPanel.Caption := '';

  for i := 1 to 27 do
    begin
      _kpanel[i].Caption := '';
      _vPanel[i].Caption := '';
      _ePanel[i].Caption := '';
    end;
end;


// =============================================================================
                procedure TPillkeszform.OsszesTablaDisplay;
// =============================================================================

var i: integer;
    _aktidos: string;

begin
  Adattablaclear;
  PenztarnevFocimPanel.Caption := 'KÖRZET ÖSSZESEN';;
  PenztarnevFocimPanel.Repaint;
 
  _aktirodaszam := _kfirodaszam[_ss];
  PtarszamPanel.Caption := 'ÖSSZ';
  PtarszamPanel.repaint;

  _aktdatum := _mamas;
  _aktevs   := leftstr(_aktdatum,4);
  _aktho    := strtoint(midstr(_aktdatum,6,2));
  _aktnap   := midstr(_aktdatum,9,2);
  _aktidos  := _kfIdo[_ss];

  Evpanel.Caption      := _aktevs;
  Honevpanel.Caption   := _honev[_aktho];
  NapszamPanel.Caption := _aktnap;
  IdoPanel.caption     := '------';

  Evpanel.repaint;
  Honevpanel.repaint;
  NapszamPanel.repaint;
  Idopanel.Repaint;

  ForintPanel.Caption   := ftForm(_sumForintFt);
  ValutaPanel.Caption   := ftForm(_sumValutaFt);
  WusdPanel.Caption     := ftform(_sumwusd);
  Whufpanel.Caption     := ftform(_sumwhuf);
  Afaftpanel.Caption    := ftform(_sumWafa);

  Ekerkeszletpanel.Caption := ftform(_sumeker);
  KezelesidijPanel.Caption := Ftform(_sumKezdij);
  FoglaloPanel.Caption := '-';

  WusdPanel.Repaint;
  Whufpanel.Repaint;
  Afaftpanel.Repaint;
  Ekerkeszletpanel.Repaint;
  KezelesidijPanel.Repaint;
  FoglaloPanel.Repaint;

  // --------------------------------------------------------------------

   for i := 1 to 27 do
    begin
      _kadat := _sumKeszlet[i];
      _vadat := _sumVetel[i];
      _eadat := _sumEladas[i];

      _kPanel[i].caption := FtForm(_kadat);
      _vPanel[i].Caption := FtForm(_vadat);
      _ePanel[i].caption := FtForm(_eadat);

      _kpanel[i].Repaint;
      _vpanel[i].Repaint;
      _epanel[i].Repaint;
    end;
end;


// =============================================================================
               procedure TPillkeszForm.PTAR1PANELClick(Sender: TObject);
// =============================================================================

begin
  _aktTag := TPanel(Sender).Tag;
  if _aktirodasorszam=_akttag then exit;
  _aktirodasorszam := _akttag;
  _aktpanel := _ptPanel[_akttag];
  _aktpanel.Color := clyellow;
  _aktPanel.Font.Style := [fsBold];
  _aktpanel.Font.Color := clred;

  EgyirodaDisplay(_aktirodasorszam);
end;

// =============================================================================
            procedure TPillkeszForm.PTOSSZESENPANELExit(Sender: TObject);
// =============================================================================

begin
  PtOsszesenPanel.     Color := clbtnface;
  PtosszesenPanel.Font.Color := clRed;
end;

// =============================================================================
         procedure TPillkeszForm.PTOSSZESENPANELEnter(Sender: TObject);
// =============================================================================

begin
  PtOsszesenPanel.Color      := clred;
  PtosszesenPanel.Font.Color := clyellow
end;

procedure TPillkeszForm.PTOSSZESENPANELClick(Sender: TObject);
begin
  _aktIrodasorszam := -1;
  PenztarTablaSzinezo;

  PtOsszesenPanel.Color      := clred;
  PtosszesenPanel.Font.Color := clyellow;

  OsszesTablaDisplay;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



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
                function TPillkeszform.Null3(_int: integer):string;
// =============================================================================


begin
  result := inttostr(_int);
  while length(result)<3 do result := '0' + result;
end;




// =============================================================================
             function TPillkeszForm.ScanIroda(_ptsz: integer):integer;
// =============================================================================

var _y: byte;

begin
  result := -1;
  _y := 0;
  while _y<_sIrodadarab do
    begin
      if _sirodaszam[_y]=_ptsz then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;



// =============================================================================
           function TPillKeszForm.DnemDekod: string;
// =============================================================================

var _b1,_b2,_l1,_l2,_l3: byte;

begin
  _b1 := _bytetomb[_pp];
  _b2 := _bytetomb[_pp+1];

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
  _pp := _pp + 2;
end;

// =============================================================================
             function TPillkeszForm.Darabdekod: integer;
// =============================================================================

var _b1,_b2,_b3,_b4: byte;

begin
  _b1 := _bytetomb[_pp];
  _b2 := _bytetomb[_pp+1];
  _b3 := _bytetomb[_pp+2];
  _b4 := _bytetomb[_pp+3];

  result := _b1 + trunc(256*_b2)+trunc(65536*_b3)+trunc(256*65536*_b4);
  _pp := _pp + 4;
end;

// =============================================================================
          function TpillkeszForm.Irodascan(_pt: integer): string;
// =============================================================================

var _y: byte;

begin
  _y := 0;
  result := '?';
  while _y<_sirodaDarab  do
    begin
      if _sIrodaszam[_y]=_pt then
        begin
          result := _sIrodanev[_y];
          break;
        end;
      inc(_y);
    end;
end;

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
            procedure TPillkeszForm.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := False;
  _aa := 2;
  Modalresult := _mResult;
end;

// =============================================================================
             function TPillkeszForm.Scandnem(_dn: string): integer;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  result := -1;
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
             procedure TPILLKESZForm.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepotimer.Enabled := true;
end;



// =============================================================================
       procedure TPillkeszForm.PTAR1PANELMouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  _aktMTag := TPanel(Sender).Tag;
  if _aktMTag=_lastMTag then exit;
  _lastmTag := _aktMTag;

  PenztarTablaSzinezo;
  if _aktmTag=_aktirodasorszam then exit;

  _aktpanel := _ptPanel[_aktMTag];
  _aktpanel.color := clBlack;
  _aktpanel.font.Color := clWhite;
  _aktpanel.font.Style := [fsBold];

end;


function TPillkeszForm.HunDateTostr(_calDat: TDatetime): string;

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


end.




