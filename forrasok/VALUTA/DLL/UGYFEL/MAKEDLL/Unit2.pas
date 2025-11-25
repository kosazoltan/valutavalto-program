unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, DBTables, StrUtils, wininet,
  IBDatabase, IBCustomDataSet, IBQuery, IBTable, Grids, DBGrids, jpeg;

type
  TUgyfelinput = class(TForm)

    JogiQuery             : TibQuery;
    JogiDbase             : TibDatabase;
    JogiTranz             : TibTransaction;

    TempQuery             : TibQuery;
    TempDbase             : TibDatabase;
    TempTranz             : TibTransaction;

    TulajQuery            : TIBQuery;
    TulajDbase            : TIBDatabase;
    TulajTranz            : TIBTransaction;

    UgyfelQuery           : TibQuery;
    UgyfelDbase           : TibDatabase;
    UgyfelTranz           : TibTransaction;

    ValutaQuery           : TIBQuery;
    ValutaDbase           : TIBDatabase;
    ValutaTranz           : TIBTransaction;
    AZONOSITOGOMB         : TBitBtn;
    KPOLGARGOMB           : TBitBtn;
    MegsemAzonositGomb    : TBitBtn;
    IgenAzonositGomb      : TBitBtn;
    JogiAdatOkeGomb       : TBitBtn;
    JogiNemAzonositGomb   : TBitBtn;
    JogiValasztoGomb      : TBitBtn;
    MasnevebenGomb        : TBitBtn;
    MbChangeGomb          : TBitBtn;
    MbRendbenGomb         : TBitBtn;
    MegbizoAdatOkeGomb    : TBitBtn;
    MegbizoMegsemGomb     : TBitBtn;
    MegsemAzonositokGomb  : TBitBtn;
    MegsemJogiValasztoGomb: TBitBtn;
    MegsemValasztokGomb   : TBitBtn;
    NaturAdatOkeGomb      : TBitBtn;
    NemAzonositGomb       : TBitBtn;
    NemAzonositoGomb      : TBitBtn;
    SajatNevebenGomb      : TBitBtn;
    TulajMegsemGomb       : TBitBtn;
    TulajOkeGomb          : TBitBtn;
    UgyfelValasztoGomb    : TBitBtn;

    JogiSource            : TDataSource;
    UgyfelSource          : TDataSource;

    JogiRacs              : TDBGrid;
    UgyfelRacs            : TDBGrid;

    AdoszamEdit           : TEdit;
    AnyjaEdit             : TEdit;
    AzonositoEdit         : TEdit;
    Edit26                : TEdit;
    Edit29                : TEdit;
    ElozoNevedit          : TEdit;
    ErdJellegEdit         : TEdit;
    ErdMertekEdit         : TEdit;
    FotevekenysegEdit     : TEdit;
    IrSzamEdit            : TEdit;
    JogiKeresoEdit        : TEdit;
    JoginevEdit           : TEdit;
    KepvisBeoEdit         : TEdit;
    KepvisNevEdit         : TEdit;
    LCimCardEdit          : TEdit;
    LeanykoriEdit         : TEdit;
    MegbizottBeoEdit      : TEdit;
    NevEdit               : TEdit;
    OkiratEdit            : TEdit;
    SzulhelyEdit          : TEdit;
    SzulidoEdit           : TEdit;
    TAllampolgEdit        : TEdit;
    TartHelyEdit          : TEdit;
    TelephelyEdit         : TEdit;
    TElozonevEdit         : TEdit;
    TLakcimEdit           : TEdit;
    TNevEdit              : TEdit;
    TSzulidoEdit          : TEdit;
    TSzulhelyEdit         : TEdit;
    TTarthelyEdit         : TEdit;
    TulajNev1Edit         : TEdit;
    TulajNeV2Edit         : TEdit;
    TulajNeV3Edit         : TEdit;
    TulajNeV4Edit         : TEdit;
    UgyfelKeresoEdit      : TEdit;
    UtcaEdit              : TEdit;
    VarosEdit             : TEdit;

    BkUgyfelLabel         : TLabel;
    Blistlabel            : TLabel;
    JListLabel            : TLabel;
    JogiLabel             : TLabel;
    Label1                : TLabel;
    Label2                : TLabel;
    Label3                : TLabel;
    Label4                : TLabel;
    Label5                : TLabel;
    Label6                : TLabel;
    Label7                : TLabel;
    Label8                : TLabel;
    Label9                : TLabel;
    Label10               : TLabel;
    Label11               : TLabel;
    Label13               : TLabel;
    Label14               : TLabel;
    Label15               : TLabel;
    Label16               : TLabel;
    Label17               : TLabel;
    Label18               : TLabel;
    Label19               : TLabel;
    Label20               : TLabel;
    Label21               : TLabel;
    Label22               : TLabel;
    Label23               : TLabel;
    Label24               : TLabel;
    Label25               : TLabel;
    Label26               : TLabel;
    Label27               : TLabel;
    Label30               : TLabel;
    Label57               : TLabel;
    Label58               : TLabel;
    Label59               : TLabel;
    Label60               : TLabel;
    Label61               : TLabel;
    Label63               : TLabel;
    Label64               : TLabel;
    Label65               : TLabel;
    Label66               : TLabel;
    Label67               : TLabel;
    Label68               : TLabel;
    Label69               : TLabel;
    Label70               : TLabel;
    Label71               : TLabel;
    Label72               : TLabel;
    Label73               : TLabel;
    Label74               : TLabel;
    Label78               : TLabel;
    NevLabel              : TLabel;

    AllamPolgarPanel      : TPanel;
    BelfoldiNaturPanel    : TPanel;
    BelkulPanel           : TPanel;
    ISOPanel              : TPanel;
    JogiGomb              : TPanel;
    JogiListaGomb         : TPanel;
    JogiPanel             : TPanel;
    JogiValasztoPanel     : TPanel;
    KAllampolgarPanel     : TPanel;
    KBSelectPanel         : TPanel;
    KBPanel               : TPanel;
    KIsoPanel             : TPanel;
    KotelezoPanel         : TPanel;
    KulfoldiNaturPanel    : TPanel;
    LakasCimPanel         : TPanel;
    LakcimCimke           : TPanel;
    MBValasztoGomb        : TPanel;
    MegbizottNevPanel     : TPanel;
    NaturGomb             : TPanel;
    NaturListaGomb        : TPanel;
    NaturPanel            : TPanel;
    OrszagPanel           : TPanel;
    Panel1                : TPanel;
    Panel2                : TPanel;
    UgyfelValasztoPanel   : TPanel;
    SajatMasPanel         : TPanel;
    MegbizottGombPanel    : TPanel;
    megbizotakaro         : TPanel;
    MegbizoKBPanel        : TPanel;
    NaturGombPanel        : TPanel;
    MegbizoGombPanel      : TPanel;
    TGomb1                : TPanel;
    TGomb2                : TPanel;
    TGomb3                : TPanel;
    TGomb4                : TPanel;
    TSorszamPanel         : TPanel;
    TulajPanel            : TPanel;
    UgyfelTipusPanel      : TPanel;

    Shape1                : TShape;
    Shape2                : TShape;
    Shape3                : TShape;
    Shape5                : TShape;
    Shape6                : TShape;
    Shape7                : TShape;
    Shape8                : TShape;
    Shape9                : TShape;
    Shape11               : TShape;
    Shape12               : TShape;
    Shape13               : TShape;
    Shape14               : TShape;
    Shape15               : TShape;

    BelRadio              : TRadioButton;
    JogiRadio             : TRadioButton;
    KozIgenRadio          : TRadioButton;
    KozNemRadio           : TRadioButton;
    KozszerepRadio        : TRadioButton;
    KulRadio              : TRadioButton;
    NaturRadio            : TRadioButton;
    NemKozszerepRadio     : TRadioButton;

    GroupBox2             : TGroupBox;
    GroupBox3             : TGroupBox;

    Image1                : TImage;
    Virag                 : TImage;

    OkmTipCombo           : TComboBox;

    BelGomb               : TBitBtn;
    KulGomb               : TBitBtn;
    KisUgyfelGomb         : TBitBtn;
    MasBELGomb            : TBitBtn;
    MasKULGomb            : TBitBtn;
    PolgarGomb            : TBitBtn;

    Kilep                 : TTimer;
    NoInternetPanel       : TPanel;
    Label12               : TLabel;
    TovaGomb              : TBitBtn;
    Label28               : TLabel;
    Label29               : TLabel;
    Shape4                : TShape;
    TiltoTabla            : TPanel;
    Label31               : TLabel;
    TiltoGomb             : TBitBtn;
    CardKerdoPanel        : TPanel;
    Label32               : TLabel;
    IGENGomb              : TBitBtn;
    NemGomb               : TBitBtn;
    Shape10               : TShape;
    TEAOREdit             : TEdit;
    Label33               : TLabel;
    TEAORNevEdit          : TEdit;
    TEAORQUERY: TIBQuery;
    TEAORDBASE: TIBDatabase;
    TEAORTRANZ: TIBTransaction;


// ***************************************************************************

  procedure AlapraAllitas;
  procedure KPolgarGombClick(Sender: TObject);
  procedure AzonositoGombClick(Sender: TObject);
  procedure PolgarGombClick(Sender: TObject);
  procedure BelGombClick(Sender: TObject);
  procedure BelRadioClick(Sender: TObject);
  procedure EditBeolvasas;
  procedure FillTulNevEdits;
  procedure FillJogiEdits;
  procedure FillNaturedits;
  procedure FinalRegistration;
  procedure FormActivate(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure GetJogiData;
  procedure GetJogiDataFromEdits;
  procedure GetJogiDataFromDbase;
  procedure GetMegbizo;
  procedure GetMegbizott;
  procedure GetnaturData;
  procedure GetNaturDataFromdbase;
  procedure GetNaturDAtafromEdits;
  procedure Getorszagkod;
  procedure GetTeaorszam;
  procedure GetTulajDataFromedits;
  procedure GombClear;
  procedure IgenAzonositGombClick(Sender: TObject);
  procedure IrszamEditChange(Sender: TObject);
  procedure JogiAdatOkeGombClick(Sender: TObject);
  procedure JogiGombClick(Sender: TObject);
  procedure JogiListaGombclick(Sender: TObject);
  procedure JogiNevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure JogiNevEditChange(Sender: TObject);
  procedure JogiOpen;
  procedure JogiRacsDblClick(Sender: TObject);
  procedure JogiRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure JogiRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure JogiRadioClick(Sender: TObject);
  procedure JogiSzemelytValasztott;
  procedure JogiValasztas;
  procedure KisugyfelGombClick(Sender: TObject);
  procedure KilepTimer(Sender: TObject);
  procedure KozIgenRadioClick(Sender: TObject);
  procedure KozNemRadioClick(Sender: TObject);
  procedure KulGombClick(Sender: TObject);
  procedure KulRadioClick(Sender: TObject);
  procedure MasBelGombclick(Sender: TObject);
  procedure MasKulGombclick(Sender: TObject);
  procedure MasNevebenGombClick(Sender: TObject);
  procedure MBValasztoGombClick(Sender: TObject);
  procedure MegsemAzonositOkGombClick(Sender: TObject);
  procedure MegsemJogiValasztoGombClick(Sender: TObject);
  procedure MegsemValasztokGombClick(Sender: TObject);
  procedure MezoAdatokAtmasolasa;
  procedure Mezovaltozas;
  procedure NaturAdatOkeGombClick(Sender: TObject);
  procedure NaturListaGombClick(Sender: TObject);
  procedure NaturValasztas;
  procedure NemAzonositoGombClick(Sender: TObject);
  procedure NemKozszerepRadioClick(Sender: TObject);
  procedure NevEditEnter(Sender: TObject);
  procedure NevEditExit(Sender: TObject);
  procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure OkmTipComboChange(Sender: TObject);
  procedure ParaBeolvasas;
  procedure RP1Click(Sender: TObject);
  procedure SajatNevebenGombClick(Sender: TObject);
  procedure SaveNaturUgyfel;
  procedure SaveJogiszemely;
  procedure SaveMegbizott;
  procedure SaveMegbizo;
  procedure SaveTulajdonosok;
  procedure SetKulfoldi;
  procedure SetNaturIso;
  procedure Shape12MouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
  procedure SureQuit(Sender: TObject);
  procedure TarthelyEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure TGomb1Click(Sender: TObject);
  procedure TGomb1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
  procedure TiltoGombClick(Sender: TObject);
  procedure TNeveditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure TombMeghatarozas;
  procedure TovaGombClick(Sender: TObject);
  procedure TulajAdatokNullazasa;
  procedure TulajMegsemGombClick(Sender: TObject);
  procedure TulajOkeGombClick(Sender: TObject);
  procedure UgyfeletValasztott;
  procedure UgyfelOpen;
  procedure UgyfelRacsDblClick(Sender: TObject);
  procedure UgyfelRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure UgyfelRacsKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
  procedure UgyfelValasztoGombClick(Sender: TObject);
  procedure UpdateNatur;
  procedure UpdateJogiszemely;
  procedure UpdateMegbizo;
  procedure UpdateMegbizott;
  procedure ValutaParancs(_ukaz: string);
  procedure ValutaTempctrl;
  procedure VTempNullazo;

  function Datumctrl(_dst: string): boolean;
  function ErdMertCtrl(_em: string): boolean;
  function Getteaornev(_ts: string): string;
  function GetTulajDarab: byte;
  function UgyfelszamLepteto: integer;

  procedure IGENGOMBClick(Sender: TObject);
  procedure NEMGOMBClick(Sender: TObject);
  procedure TEAOREDITDblClick(Sender: TObject);
    procedure TEAOREDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);


// õõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõõ

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Ugyfelinput: Tugyfelinput;

  _top,_left,_width,_height,_bill: word;

  _uTip        : string;

  _aktEdit     : TEdit;
  _aktGomb     : TPanel;
  _aktPanel    : TPanel;

  _securLevel,_konverzio,_tag,_ww,_tss,_utgomb,_postterm: byte;
  _fizetendo,_mResult,_tResult,_sFt,_code,_recno,_terrback: integer;
  _aktstring,_engedelyezo,_forras,_pcs,_ugyfeltipus,_keres,_ugyfelstatusz: string;
  _tipus,_mess: string;
  _kotelezo,_oke,_toltes: boolean;

  _tagedit     : array[1..9] of TEdit;
  _tGomb       : array[1..4] of TPanel;
  _okmtiptomb  : array[0..2] of string = ('SZIG','JOGOSITVANY','UTLEVEL');
  _sorveg      : string = chr(13)+chr(10);

  _serveraccess  : byte;

// --------------------- Általános mezöadatok ----------------------------------

  _nev,_elozo,_leany,_anyja,_szulhely,_szulido,_irszam,_varos,_utca : string;
  _lakcim,_lcimcard,_azonosito,_okmanytipus,_allampolgar,_tarthely,_iso: string;
  _ugyfelszam: integer;
  _kulfoldi,_okmtipindex,_kozszereplo: byte;

//  -------------------  Natur változók ----------------------------------------

  _naturedit: array[1..12] of TEdit;
  _nUgyfelszam: integer;
  _nKulfoldi,_nKozszereplo,_nOkmTipIndex: byte;
  _nnev,_nElozo,_nAnyja,_nLeany,_nSzulhely,_nSzulido,_nAllampolgar: string;
  _niso,_nLakcim,_nOkmanyTipus,_nAzonosito,_nTarthely: string;
  _nLcimCard,_nIrszam,_nVaros,_nUtca,_ugyfelnev: string;
  _voltF5: boolean;

// -----------------------------------------------------------------------------

  _ujNaturUgyfel,_voltNaturF5,_naturMezoValtozott: boolean;

// -------------------- Jogi személy változók ----------------------------------

  _jogiedit : array[1..9] of TEdit;
  _jUgyfelszam,_nTeaor: integer;
  _jKulfoldi: byte;
  _jNev,_jTelephely,_jOkirat,_jTevekeny,_jKepvisnev,_jMbBeo,_jIso: string;
  _jAdoszam,_jOrszag,_jKepvisbeo,_jTeaor,_teaornev: string;
  _ujjogiszemely,_jogimezovaltozott,_voltJogiF6: boolean;

// -------------------- Megbizott személy --------------------------------------

  _mbUgyfelszam: integer;
  _mbKulfoldi,_mbKozszereplo,_mbOkmTipIndex: byte;
  _mbnev,_mbElozo,_mbAnyja,_mbLeany,_mbSzulhely,_mbSzulido,_mbAllampolgar: string;
  _mbiso,_mbLakcim,_mbOkmanyTipus,_mbAzonosito,_mbTarthely: string;
  _mbLcimCard,_mbIrszam,_mbVaros,_mbUtca: string;
  _ujMegbizott,_voltMegbizottF5,_mbMezoValtozott: boolean;


// -------------------- Megbizó személy ----------------------------------------

  _mzUgyfelszam: integer;
  _mzKulfoldi,_mzKozszereplo,_mzOkmTipIndex: byte;
  _mznev,_mzElozo,_mzAnyja,_mzLeany,_mzSzulhely,_mzSzulido,_mzAllampolgar: string;
  _mziso,_mzLakcim,_mzOkmanyTipus,_mzAzonosito,_mzTarthely: string;
  _mzLcimCard,_mzIrszam,_mzVaros,_mzUtca: string;
  _ujMegbizo,_voltMegbizoF5,_mzMezoValtozott: boolean;

// -------------------------  Tulajdonosok -------------------------------------

  _tulajnevedit  : array[1..4] of TEdit;
  _ttKozszereplo : array[1..4] of byte;
  _ttNev,_ttElozonev,_tTlakcim,_ttSzulhely,_ttSzulido: array[1..4] of string;
  _ttAllampolgar,_ttTarthely,_tTerdJelleg,_ttErdMertek: array[1..4] of string;
  _tulajdarab,_tkozszereplo: byte;

  _tNev,_tElozo,_tLakcim,_tSzulhely,_tSzulido,_tAllamPolgar,_tTarthely: string;
  _tErdjelleg,_tErdMertek : string;



function terrorcontrol: integer; stdcall; external 'c:\valuta\bin\terrlist.dll';
function kisugyfelrutin: integer; stdcall; external 'c:\valuta\bin\kisugyfel.dll' name 'kisugyfelrutin';
function getisorutin: integer; stdcall; external 'c:\valuta\bin\getiso.dll' name 'getisorutin';
function gongyoletcontrol: integer; stdcall; external 'c:\valuta\bin\bigctrl.dll' name 'gongyoletcontrol';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function getkiemeltstatusz: integer; stdcall; external 'c:\valuta\bin\getstat.dll' name 'getkiemeltstatusz';
function teaorvalasztas: integer; stdcall; external 'c:\valuta\bin\teaorsel.dll';

function ugyfelrutin: integer; stdcall;



implementation

{$R *.dfm}

{
                Input : fizetendo,konverzio,tipus
                Output: ugyfeltipus,ugyfelszam,nevtabla,sorszam,kulfoldi,
                        forras,engedelyezo,securlevel,konverzio

  Visszatérés: -1 = Storno az egész bizonylat,
                1 = ügyfel rendben
                2 = Nem azonositja magát, de nem is kell
                3 = Kisugyfel azonositva

  ------------------------------------------------------------------------------

  KISUGYFEL.DLL: Input : fizetendo,kulfoldi,megnyitottnap
  -------------  Output: ugyfeltipus=K,ugyfelszam,nevtabla,sorszam

                 Az input output a VTEMP-en keresztül történik

           result : -1 = Tranzakció STOP ! Nem folytatható !
                     1 = Kisügyfél rögzitve (adatok VTEMP-ben)
                     2 = Kötelezõ a teljes azonositása
                     3 = Nincs intenet vagy szerverkapcsolat vagy 100ezer alatt

  ---------------------------------------------------------------------------------
}

// =============================================================================
                   function ugyfelrutin: integer; stdcall;
// =============================================================================


begin
  Ugyfelinput := TUgyfelinput.Create(Nil);
  Result := Ugyfelinput.Showmodal;
  Ugyfelinput.Free;
end;


// =============================================================================
             procedure TUgyfelinput.FormActivate(Sender: TObject);
// =============================================================================


begin
  logirorutin(pchar('...'));
  logirorutin(pchar('Az ügyfél kiválasztása. (ugyfel.dll)'));

  _width  := screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  _left   := round((_width-1024)/2);
  _top    := round((_height-768)/2);

  Top     := _top  + 144;
  Left    := _left + 312;

  Height  := 268;
  Width   := 402;

  TombMeghatarozas;
  AlapraAllitas;
  ParaBeolvasas;  // fizetendo,tipus,konverzio a VTEMP-bõl
  VtempNullazo;

  _toltes := False;

  // Securlevel beállitása

  _securlevel := 0;
  if _konverzio=1 then _fizetendo := _fizetendo + _fizetendo;
  if _fizetendo>=100000 then NemAzonositoGomb.Enabled := False;
  if (_fizetendo>=300000)  then
    begin
      _securlevel := 1;
      _kotelezo   := True;
      Kisugyfelgomb.Enabled := False;
    end;

  _pcs := 'UPDATE VTEMP SET SECURLEVEL='+inttostr(_securlevel);
  ValutaParancs(_pcs);

  if _securlevel=1 then logirorutin(pchar('Kötelezõ az azonosítás'));

  // --------------------------------------------

  with BelKulPanel do
    begin
      Top     := 0;
      Left    := 0;
      Visible := True;
      Repaint;
    end;

  if _securlevel=1 then
    begin
      Activecontrol := AzonositoGomb;
      exit;
    end;

  if (_fizetendo<100000) then
    begin
      Activecontrol := Nemazonositogomb;
      exit;
    end;

   Activecontrol := Kisugyfelgomb;
end;

// =============================================================================
          procedure TUgyfelinput.JOGIRADIOClick(Sender: TObject);
// =============================================================================

begin
  _kotelezo := true;

  _securlevel := 1;
  _pcs := 'UPDATE VTEMP SET SECURLEVEL=1';
  ValutaParancs(_pcs);

  Kisugyfelgomb.Enabled := False;
end;

// =============================================================================
          procedure TUgyfelinput.NEMAZONOSITOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Setkulfoldi;

  if _kotelezo then
    begin
      with Kotelezopanel do
        begin
          Left    := 35;
          Top     := 5;
          Visible := True;
          Bringtofront;
        end;
      Activecontrol := IgenazonositGomb;
      Exit;
    end;

  if (_tipus='E') AND (_postterm=1) then
    begin
      with CardkerdoPanel do
        begin
          top :=120;
          left := 50;
          visible := True;
        end;
      exit;
    end;

  _mResult := 2;
  Kilep.Enabled := true;
end;

// =============================================================================
      procedure TUgyfelinput.MegsemAzonositokGombClick(Sender: TObject);
// =============================================================================

begin
  // Nem azonositja magát -  pedig kellene

  _mResult := -1;
  Kilep.enabled := True;
end;


// =============================================================================
        procedure TUgyfelinput.KISUGYFELGOMBClick(Sender: TObject);
// =============================================================================


begin
  SetKulfoldi;

  if _serverAccess=1 then
    begin
      with NoInternetPanel do
        begin
          top     := 307;
          left    := 372;
          Visible := true;
          repaint;
        end;
      Activecontrol := Tovagomb;
      exit;
    end;

  _mResult := kisugyfelrutin;

  _mess := 'A kisugyfel.dll befejezve';

  logirorutin(pchar(_mess));
  logirorutin(pchar('...'));

  If (_mResult=-1) then
    begin
      _mess := 'Kisügyfélrutin üzeni -> tranzakciót be kell fejezni !';
      logirorutin(pchar(_mess));
      Kilep.Enabled := true;
      exit;
    end;

  if (_mresult=1) or (_mResult=3) then
    begin
       _mess := 'A kisügyfél rendben azonositva';
       logirorutin(pchar(_mess));
       _mResult := 3;
       Kilep.Enabled := true;
       exit;
     end;

   if _mresult=2 then // itt az _mresult=2 -> teljes azonositás kell !!
     begin
       _mess := 'Kisügyfélrutin üzeni -> teljes azonositás szükséges';
       logirorutin(pchar(_mess));

       Showmessage('AZ ÜGYFÉL TELJES AZONOSITÁST IGÉNYEL ');

       _securlevel := 1;
       _kotelezo := True;
       Azonositogombclick(Nil);
     end;
end;

// =============================================================================
                     procedure TUgyfelinput.Setkulfoldi;
// =============================================================================

begin
  _kulfoldi:= 0;
  if Kulradio.Checked then _kulfoldi := 1;

  _pcs := 'UPDATE VTEMP SET KULFOLDI='+inttostr(_kulfoldi);
  ValutaParancs(_pcs);
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
           procedure TUgyfelinput.AZONOSITOGOMBClick(Sender: TObject);
// =============================================================================

begin
  // AZ ügyfél azonositani akarja magát:

  Setkulfoldi;

  _ugyfeltipus := 'N';
  if JogiRadio.Checked then _ugyfeltipus := 'J';

  // Az induló menü eltünik:
  BelkulPanel.Visible := False;

  // Most kezdödhet az azonositást a szabadság-szobor kijelzése:

  Top    := _top;
  Left   := _left;
  Height := 765;
  Width  := 1020;

  //  Vagy természetes vagy jogi személy beolvasó panelját jelezzük ki:

  if _ugyfeltipus='N' then
    begin

      // Természetes személy ürlapja:

      Lakcimcimke.Caption      := 'Az ügyfél lakáscíme';
      UgyfeltipusPanel.caption := 'TERMÉSZETES SZEMÉLY';
      UgyfeltipusPanel.repaint;

      _uTip := 'N';
      UgyfeltipusPanel.repaint;

      // Természetes személy adatait kérjük be:
      GetNaturData;
    end else
    begin
      GetJogiData;
    end;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$ természetes személy $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// %%%%%%%%%%%%%%%%%%%%%%%    adatai bekérése  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                  procedure TUgyfelinput.GetNaturData;
// =============================================================================

var i: byte;

begin
  // Egy természetes személy adatait kérjük be
  // Az UTIP lehet = 'N' 'MBTT' 'MBZO' 'J'

  // A 12 edit-et kinulláza: belföldi=11 külföldi=12
  for i := 1 to 12 do _naturedit[i].Clear;

  // Default okmanytipus= SZIG
  OkmTipCombo.ItemIndex := 0;

  if _utip='MBTT' then _ujmegbizott := True;
  if _utip='MBZO' then _ujmegbizo := True;

  if _kulfoldi=1 then
    begin
      BelfoldiNaturPanel.Visible := False;
      KulfoldiNaturPanel.visible := True;
    end else
    begin
      KulfoldiNaturPanel.visible := False;
      Isopanel.Caption := _iso;
      Isopanel.repaint;
      BelfoldiNaturPanel.Visible := True;
    end;

  with NaturPanel do     // natur ürlapja
    begin
      Top     := 8;
      Left    := 260;
      Visible := True;
    end;

  with NaturgombPanel do   // natur rendben/nem panelja
    begin
      Top     := 650;
      Left    := 260;
      Visible := True;
    end;

  if _utip='N' then
    begin
      _voltNaturF5  := False;
      _naturmezovaltozott := False;
      _ujnaturugyfel := true;
    end;

  if _utip='MBTT' then
    begin
      _voltMegbizottF5  := False;
      _mbMezoValtozott := False;
    end;

  if _utip='MBZO' then
    begin
      _voltMegbizoF5  := False;
      _mzMezoValtozott := False;
      _ujmegbizo := true;
    end;

  Activecontrol := Nevedit;
end;

// =============================================================================
       procedure TUgyfelinput.NeveditKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  _tag  := Tedit(sender).Tag;
  _bill := ord(key);

  if (_bill=116) then  // F5 -  listából olvas
    begin
      logirorutin(pchar('F5 -> listából fog választani'));
      NaturValasztas;
      exit;
    end;

  if _bill= 38 then  // FeLFELE
    begin
      if _tag=1 then exit;
      dec(_tag);
      _aktedit := _naturedit[_tag];
      ActiveControl := _aktedit;
      exit;
    end;

  if _bill = 40 then   // LEFELE
    begin
      if (_tag=12) or ((_tag=11) and (_nkulfoldi=0))  then
         begin
          Activecontrol := NaturAdatOkeGomb;
          exit;
        end;

      inc(_tag);
      _aktedit := _naturedit[_tag];
      ActiveControl := _aktedit;
      exit;
    end;

  if _bill<>13 then exit;

  // ------------------- ENTERT NYOMOTT ----------------------------------------

  if _bill=13 then
    begin
      inc(_tag);

      if (_tag=12) and (_kulfoldi=0) then       // belföldi = 11 mezõ
        begin
          ActiveControl := NaturAdatOkeGomb;
          exit;
        end;

      if _tag=13 then                          // külföldi = 12 mezõ
        begin
          Activecontrol := NaturAdatOkeGomb;
          exit;
        end;

      _aktedit := _naturedit[_tag];
      ActiveControl := _aktEdit;
    end;
end;

// =============================================================================
         procedure TUgyfelinput.NaturAdatOkeGombClick(Sender: TObject);
// =============================================================================

//     A natur ürlapon az adatok be vannak irva

var _irnum: integer;

begin
  GetNaturDataFromedits;

  if (_allampolgar='') or (_iso='') then
    begin
      logirorutin(pchar('Allampolgár vagy ISO hiányzik'));
      Mezovaltozas;
      if _kulfoldi=1 then KpolgarGombClick(Nil)
      else PolgargombClick(Nil);

      exit;
    end;

  _nev := trim(_nev);
  Nevedit.Text := _nev;
  _ww := length(_nev);
  if _ww<6 then
    begin
      logirorutin(pchar('Név hiányzik'));
      Mezovaltozas;
      Activecontrol := Nevedit;
      exit;
    end;

  _Anyja := trim(_Anyja);
  AnyjaEdit.Text := _Anyja;
  _ww := length(_anyja);
  if _ww<6 then
    begin
      logirorutin(pchar('Hibás anyjaneve'));
      Mezovaltozas;
      Activecontrol := AnyjaEdit;
      exit;
    end;

  _Szulhely := trim(_Szulhely);
  SzulhelyEdit.text := _Szulhely;
  _ww := length(_szulhely);

  if _ww<2 then
    begin
      logirorutin(pchar('Hibás születési hely'));
      Mezovaltozas;
      Activecontrol := SZulhelyEdit;
      exit;
    end;

  _szulido := trim(leftstr(_szulido,10));
  if not DatumCtrl(_Szulido) then
    begin
      logirorutin(pchar('Hibás születési idõ'));
      SzulidoEdit.Text := '';
      Mezovaltozas;
      Activecontrol := SzulidoEdit;
      exit;
    end;

  if _kulfoldi=0 then
    begin
      val(_Irszam,_Irnum,_code);
      if _code<>0 then _irnum := 0;
      if (_Irnum=0) then
         begin
           logirorutin(pchar('Hibás ir-szám'));
           IrszamEdit.Text := '';
           Mezovaltozas;
           Activecontrol := IrszamEdit;
           exit;
         end;

      _varos := trim(_Varos);
      _ww := length(_varos);
      if _ww<2 then
        begin
          logirorutin(pchar('Hibás város'));
          Varosedit.Text := '';
          Mezovaltozas;
          Activecontrol := Varosedit;
          exit;
        end;

      if _Utca='' then
        begin
          logirorutin(pchar('Hibás utca'));
          UtcaEdit.Text := '';
          Mezovaltozas;
          Activecontrol := UtcaEdit;
          exit;
        end;

      if _LcimCard='' then
        begin
          logirorutin(pchar('Hibás lakcimkártya'));
          Mezovaltozas;
          ActiveControl := LcimCardedit;
          exit;
        end;

      if (_iso='') then
        begin
          _iso := 'HU';
          Mezovaltozas;
        end;
    end;

  if _Azonosito='' then
    begin
      logirorutin(pchar('Nincs azonosito'));
      Mezovaltozas;
      ActiveControl := Azonositoedit;
      exit;
    end;

  if _kulfoldi=1 then
    begin
      _TartHely := trim(_TartHely);
      _ww := length(_tarthely);
      If _ww<2 then
        begin
          logirorutin(pchar('Külföldi tartozkódési helye hiányzik'));
          TarthelyEdit.text := '';
          Mezovaltozas;
          ActiveControl := TartHelyEdit;
          exit;
        end;
    end;

  if (_Allampolgar='') or (_iso='') then
    begin
      setNaturIso;
      logirorutin(pchar('Állampolgárság hiányzik'));
      Mezovaltozas;
      if _kulfoldi=0 then PolgarGombclick(Nil)
      else KpolgargombClick(Nil);
      exit;
    end;

  _OkmTipIndex := OkmTipCombo.itemindex;
  NaturgombPanel.Visible := False;

  MezoadatokAtmasolasa;

  if _uTip='N' then
    begin
      BkUgyfelLabel.Caption := 'Belföldi ügyfél';
      if _nkulfoldi=1 then BkUgyfelLabel.Caption := 'Külföldi ügyfél';
      BkUgyfelLabel.repaint;

      if (_niso='RU') OR (_niso='BY') then
        begin
          with tiltoTabla do
             begin
               top := 120;
               left := 310;
               Visible := True;
               repaint;
             end;
           Activecontrol := TiltoGomb;
           exit;
        end;
      with SajatmasPanel do
        begin
          Top  := 630;
          Left := 260;
          Visible := true;
        end;

      ActiveControl := SajatnevebenGomb;
      exit;
    end;

  if _utip='MBZO' then
    begin
      SajatNevebenGombClick(Nil);
      exit;
    end;

  if _utip='MBTT' then
     begin
       if _ujmegbizott then _mbmezovaltozott:= False;
       MegbizottnevPanel.Caption := _mbnev;
       MegbizottnevPanel.repaint;
     end;

  Naturpanel.Visible := False;
end;

// =============================================================================
                 procedure TUgyfelinput.Mezovaltozas;
// =============================================================================

begin
  if _uTip='N' then
    begin
      if _voltNaturF5 then _naturmezovaltozott := True;
    end;

  if _utip='MBTT' then
    begin
      if _voltMegbizottF5 then _mbmezovaltozott := True;
    end;

  if _utip='MBZO' then
    begin
      if _voltmegbizoF5 then _mzmezovaltozott := True;
    end;

  if _utip='J' then
    begin
      if _voltJogiF6 then _jogimezovaltozott := True;
    end;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ===================== NATUR SZEMÉLY KIVÁLASZTÁSA LISTÁBÓL ===================
// =============================================================================

// =============================================================================
             procedure TUgyfelinput.NaturListaGombClick(Sender: TObject);
// =============================================================================

begin
  NaturValasztas;
end;

// =============================================================================
                     procedure TUgyfelinput.Naturvalasztas;
// =============================================================================

// az F5 gomb segitségét kérte:

begin

  _keres := '';
  UgyfelkeresoEdit.clear;

  with UgyfelValasztoPanel do
    begin
      top     := 4;
      Left    := 150;
      Visible := True;
    end;

  UgyfelOpen;
  Ugyfelracs.SelectedIndex := 0;
  Ugyfelracs.SetFocus;
end;

// =============================================================================
           procedure TUgyfelinput.UgyfelRacsDblClick(Sender: TObject);
// =============================================================================

begin
  UgyfeletValasztott;
end;

// =============================================================================
     procedure TUgyfelinput.UgyfelracsKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var
    _edkeres: string;
    _megvan : boolean;

begin
  _bill := ord(key);

  if (_bill>96) and (_bill<123) then _bill := _bill-32;
  if (_bill>64) or (_bill=32) then
    begin
      _edkeres := _keres;
      _keres   := _keres + chr(_bill);
      _megvan  := ugyfelQuery.Locate('NEV',_keres,[loPartialKey]);

      if _megvan then
        begin
          Ugyfelkeresoedit.Text := _keres;
          exit;
        end;

      _keres := _edkeres;
      exit;
    end;

  if (_bill=8) then
    begin
      _ww := length(_keres);
      if _ww=0 then exit;
      if _ww=1 then
        begin
          _keres := '';
          Ugyfelkeresoedit.clear;
          exit;
        end;
      _keres := leftstr(_keres,_ww-1);
      Ugyfelkeresoedit.Text := _keres;
      UgyfelQuery.Locate('NEV',_KERES,[loPartialKey]);
    end;

  if (_bill=13) then
    begin
      UgyfeletValasztott;
      Exit;
    end;
end;

// =============================================================================
          procedure TUgyfelinput.UgyfelValasztoGombClick(Sender: TObject);
// =============================================================================

begin
  UgyfeletValasztott;
end;

// =============================================================================
                     procedure TUgyfelinput.UgyfeletValasztott;
// =============================================================================

//  Ügyfelet választott F5 gomb segitségéval

begin
  _voltF5 := True;

  UgyfelValasztoPanel.visible := false;
  if _utip='N' then
    begin
      _voltnaturF5        := True;
      _ujnaturugyfel      := False;
      _naturmezovaltozott := False;
    end;

  if _utip='MBTT' then
    begin
      _voltmegbizottF5 := True;
      _ujmegbizott     := False;
    end;

  if _utip='MBZO' then
    begin
      _voltmegbizoF5 := true;
      _ujmegbizo := False;
      _mzmezovaltozott := False;
    end;

  GetNaturDataFromdbase;
  _mess := 'Választott ügyfél:' + inttostr(_ugyfelszam)+' '+_nev;
  logirorutin(pchar(_mess));

  FillNaturedits;
  if _utip='MBTT' then _mbmezovaltozott := False;

end;


// =============================================================================
                   procedure TUgyfelinput.FillNaturedits;
// =============================================================================

begin
  _toltes := True;
  Nevedit.text             := _Nev;
  Elozonevedit.Text        := _Elozo;
  Leanykoriedit.Text       := _Leany;
  Anyjaedit.text           := _Anyja;
  SzulhelyEdit.text        := _Szulhely;
  SzulidoEdit.text         := _Szulido;
  Irszamedit.Text          := _Irszam;
  Varosedit.text           := _Varos;
  Utcaedit.Text            := _Utca;
  LCimCardEdit.text        := _LcimCard;
  azonositoEdit.text       := _Azonosito;
  OkmTipCombo.ItemIndex    := _OkmtipIndex;

  if _kulfoldi=1 then
    begin
      TarthelyEdit.text         := _TartHely;
      KallampolgarPanel.caption := _Allampolgar;
      Kisopanel.Caption         := _Iso;
    end else
    begin
      ALLampOLGarPANEL.Caption := _Allampolgar;
      Isopanel.Caption         := _iso;
    end;

  if _kozszereplo>0 then KozszerepRadio.checked := true
  else NemKozszerepRadio.Checked := True;

  _naturMezoValtozott := False;

  if _voltF5 then
    begin
      Nevedit.ReadOnly := True;
      Anyjaedit.ReadOnly := True;
      Szulhelyedit.ReadOnly := True;
      SZulidoEdit.ReadOnly := True;
    end;
  _toltes := False;
end;


//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$  JOGI SZEMÉLY MEGHATÁROZÁSA   $$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
                   procedure TUgyfelinput.GetJogiData;
// =============================================================================

var i: byte;

begin
  _jiso := '';
  _jOrszag := '';
  _jKulfoldi := _kulfoldi;

  if _jkulfoldi=0 then
    begin
      _jiso := 'HU';
      _jOrszag := 'Magyarorzág';
    end;

  // tipus és statusz beállitva

  _ugyfeltipus := 'J';
  _utip := 'J';

  // A jogi adatokat bekérõ editek elõkészitése az adatbevitelre

  for i := 1 to 9 do
    begin
      _jogiedit[i].Clear;
    end;

  //  A tulajdonosok adatbekérö editjeit töröljük:

  TulajAdatokNullazasa;

  _ujjogiszemely     := True;

  // Még nincs megbizott -  paneljét töröljük

  _mbugyfelszam := 0;

  Megbizottnevpanel.Caption := '';
  with Jogipanel do
    begin
      top     := 8;
      Left    := 8;
      Visible := true;
    end;

  // A bevitel elészitése és inditása:

  Activecontrol := joginevEdit;
end;

// =============================================================================
    procedure TUgyfelinput.JOGINEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _tag  := Tedit(sender).Tag;
  _bill := ord(key);

  // F6-billentyüt nyomott -> régi ügyfél bekérése:

  if (_bill=117) then  // F6-ot nyomott listából választ
    begin
      _mess := 'F6 -> jogi személyt választ listából';
      logirorutin(pchar(_mess));
      JogiValasztas;
      exit;
    end;

  // FELFELE KURZORT NYOMOTT:

  if _bill= 38 then  // FeLFELE
    begin
      if _tag=1 then exit;
      dec(_tag);

      _aktedit := _jogiedit[_tag];
      ActiveControl := _aktedit;
      exit;
    end;

  //  LEFELE KURZORT NYOMOTT:

  if _bill = 40 then   // LEFELE
    begin
      if (_tag=8) then exit;

      inc(_tag);
      _aktedit := _jogiEdit[_tag];
      ActiveControl := _aktedit;
      exit;
    end;


  // Ha még nem nyomott entert -> tovább irhatja az adatot:

  if _bill<>13 then exit;

  // ------------------- ENTERT NYOMOTT ----------------------------------------

  if _bill=13 then
    begin
      // Ha már mind a 9 alapadat meg van -> nincs tovább

      if (_tag=9) then
        begin
          if _tulajdarab=0 then activeControl := Tgomb1
          else if trim(MegbizottnevPanel.caption)<>'' then Activecontrol := JogiadatOkeGomb;
          exit;
         end;

      // Jöhet a következõ adat:

      inc(_tag);
      _aktedit := _jogiEdit[_tag];
      ActiveControl := _aktedit;
    end;
end;

// =============================================================================
       procedure TUgyfelinput.JOGIADATOKEGOMBClick(Sender: TObject);
// =============================================================================

var _aszlen: byte;

begin
   // Ellenörzi a jogi editek kitöltését:

    GetjogiDataFromedits;

    _jnev := trim(_jnev);
    _ww := length(_jnev);
    if _ww<6 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        logirorutin(pchar('Hibás jogiszemély név'));
        Joginevedit.Text := '';
        Activecontrol := Joginevedit;
        exit;
      end;

    _jtelephely := trim(_jtelephely);
    _ww := length(_jTelephely);
    if _ww<6 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        logirorutin(pchar('Hibás telephely'));
        telephelyedit.Text := '';
        Activecontrol := Telephelyedit;
        exit;
      end;

    _jtevekeny := trim(_jtevekeny);
    _ww := length(_jTevekeny);
    if _ww<6 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        logirorutin(pchar('Hibás fötevékenység'));
        FotevekenysegEdit.Text := '';
        Activecontrol := FotevekenysegEdit;
        exit;
      end;

    _aszlen := length(_jOkirat);

    if _aszlen<5 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        Okiratedit.Text := '';
        logirorutin(pchar('Hibás okiratszám'));
        Activecontrol := Okiratedit;
        exit;
      end;

    _jKepvisnev := trim(_jKepvisnev);
    _ww := length(_jKepvisnev);
    if _ww<6 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        Kepvisnevedit.Text := '';
        logirorutin(pchar('Hibás képviselõnév'));
        Activecontrol := Kepvisnevedit;
        exit;
      end;

    _jKepvisBeo := trim(_jKepvisBeo);
    _ww := length(_jKepvisbeo);
    if _ww<3 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        KepvisBeoEdit.Text := '';
        logirorutin(pchar('Hibás képviselõ beosztás'));
        Activecontrol := KepvisBeoedit;
        exit;
      end;

    _aszLen := length(_jAdoszam);
    if _aszlen<10 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        AdoszamEdit.Text := '';
        logirorutin(pchar('Hibás adószám'));
        Activecontrol := AdoszamEdit;
        exit;
      end;

    _jMbBeo := trim(_jMbBeo);
    _ww := length(_jMbBeo);
    if _ww<3 then
      begin
        if _voltjogiF6 then _jogimezovaltozott := True;
        MegbizottbeoEdit.Text := '';
        logirorutin(pchar('Hibás megbizott beosztás'));
        Activecontrol := MegbizottbeoEdit;
        exit;
      end;

  // Ha nincs egy tulajdonos sem - bekéri a tulajdonosokat

     if _tulajdarab=0 then
      begin
        logirorutin(pchar('Nincs tuljdonos !!'));
        ShowMessage('LEGALÁBB EGY TULAJDONOSNAK KELL LENNIE');
        Activecontrol := TGomb1;
        exit;
      end;

   // Ha még nincs megbizott -> kiteszi az ürlapot

  if Megbizottnevpanel.caption ='' then
    begin
      logirorutin(pchar('Hiányzik a negbizott'));
      ShowMessage('MÉG NINCS KIJELÖLVE A MEGBIZOTT SZEMÉLY');
      Activecontrol := MBValasztoGomb;
      exit;
    end;

    // Ha külföldi jogiszemély és nincs országa -> be kell kérni

    if (_jkulfoldi=1) and (_jiso='') then
      begin
        GetOrszagKod;
        if _voltjogiF6 then _jogimezovaltozott := True;
      end;

    if NaturPanel.Visible then
      begin
        ShowMessage('A MEGBIZOTT ADATAI RENDBEN ?');
        exit;
      end;

    if _tulajdarab=0 then
      begin
        Tgomb1Click(TGomb1);
        exit;
      end;

    Finalregistration;
end;


// =============================================================================
          procedure TUgyfelinput.MBValasztoGombClick(Sender: TObject);
// =============================================================================

begin
  if Naturpanel.Visible then exit;

  logirorutin(pchar('Megbizottat választ'));

  _voltmegbizottF5   := True;
  _mbmezovaltozott   := False;
  Naturpanel.Visible := False;
  _ujmegbizott       := True;

  with KbselectPanel do
    begin
      top  := 128;
      left := 572;
      Visible := true;
      repaint;
    end;
  Activecontrol := Belgomb;
end;

// =============================================================================
             procedure TUgyfelInput.Belgombclick(Sender: TObject);
// =============================================================================

begin
  kbSelectPanel.visible := False;
  _nKulfoldi := 0;
  _nISo := 'HU';
  Getmegbizott;
end;

// =============================================================================
           procedure TUgyfelInput.KulGombClick(Sender: TObject);
// =============================================================================

begin
  kbSelectPanel.visible := False;
  _nKulfoldi := 1;
  _kulfoldi := 1;
  Getmegbizott;
end;

// =============================================================================
                    procedure TUgyfelInput.Getmegbizott;
// =============================================================================

var i: byte;

begin
  for i := 1 to 12 do _naturedit[i].Clear;

  UgyfeltipusPanel.Caption := 'MEGBIZOTT SZEMÉLY';
  _utip := 'MBTT';
  _mbKulfoldi := _kulfoldi;

  if _mbKulfoldi=0 then
    begin
      KulfoldiNaturPanel.Visible := false;
      BelfoldiNaturPanel.Visible := True;
    end else
    begin
      KulfoldiNaturPanel.Visible := True;
      BelfoldiNaturPanel.Visible := False;
    end;

  with Naturpanel do
    begin
      Top     := 8;
      Left    := 510;
      Visible := True;
    end;

  with Naturgombpanel do
    begin
      Top     := 628;
      Left    := 510;
      Visible := True;
    end;

  ActiveControl := Nevedit;
end;

// =============================================================================
        procedure TUgyfelinput.MegsemJogiValasztoGombClick(Sender: TObject);
// =============================================================================

begin
  JogivalasztoPanel.Visible := false;
  _voltJogiF6 := False;
  JogiQuery.close;
  Jogidbase.close;
  _ujjogiszemely := True;
  Activecontrol := joginevEdit;
end;

// =============================================================================
            procedure TUgyfelinput.JogiRacsDblClick(Sender: TObject);
// =============================================================================

begin
  Jogiszemelytvalasztott;
end;

// =============================================================================
      procedure TUgyfelinput.JogiracsKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var
    _edkeres: string;
    _megvan : boolean;

begin
  _bill := ord(key);
  if (_bill>64) or (_bill=32) then
    begin
      _edkeres := _keres;
      _keres := _keres + uppercase(chr(_bill));
      _megvan := JogiQuery.Locate('JOGISZEMELYNEV',_keres,[loPartialKey]);
      if _megvan then
        begin
          Jogikeresoedit.Text := _keres;
          exit;
        end;
      _keres := _edkeres;
      exit;
    end;

  if (_bill=13) then
    begin
      JogiszemelytValasztott;
      Exit;
    end;
end;

// =============================================================================
       procedure TUgyfelinput.JogiRacsKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _wk: byte;

begin

  _bill := ord(key);
  if (_bill>32) and (_bill<41) then
    begin
      _keres := '';
      JogiKeresoedit.clear;
      exit;
    end;

  if (_bill=8) then
    begin
      if _keres='' then exit;
      _wk := length(_keres);
      if _wk=1 then
        begin
          _keres := '';
          JogiKeresoEdit.clear;
          exit;
        end;
      dec(_wk);
      _keres := leftstr(_keres,_wk);
      JogikeresoEdit.Text := _keres;
      JogiQuery.Locate('NEV',_keres,[loPartialKey]);
      exit;
    end;
end;


// =============================================================================
                 procedure TUgyfelinput.JogiszemelytValasztott;
// =============================================================================


begin
  JogilistaGomb.Enabled     := False;
  Mbvalasztogomb.Enabled    := False;
  JogiValasztoPanel.visible := False;

  GetJogiDataFromDbase;
  if _jTeaor='' then
    begin
      _nTeaor := Teaorvalasztas;
      if _nTeaor=-1 then
        begin
          _mResult := -1;
          Kilep.enabled := true;
          exit;
        end;
      _jTeaor := inttostr(_nTeaor);
      _pcs := 'UPDATE JOGISZEMELY SET TEAOR='+chr(39)+_jTeaor+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_jugyfelszam);
      ValutaParancs(_pcs);
    end;
  FillJogiEdits;
  FillTulNevEdits;
  _jogimezovaltozott := False;

  ugyfeltipusPanel.Caption := 'MEGBIZOTT SZEMÉLY';
  UgyfelTipusPanel.repaint;
  _uTip := 'MBTT';

  with Naturpanel do
    begin
      top := 8;
      left := 510;
      Visible := true;
      repaint;
    end;

  with NaturGombPanel do
    begin
      top := 625;
      left := 510;
      Visible := true;
      Repaint;
    end;

  if _mbugyfelszam>0 then
    begin
      _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_mbugyfelszam);
      UgyfelDbase.connected := true;
      with UgyfelQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          GetNaturDataFromdbase;
          FillNaturEdits;
          _mbmezoValtozott := False;
        end;

      UgyfelQuery.Close;
      UgyfelDbase.Close;
      _ugyfelstatusz := 'MEGBIZOTT';
    end;
  Activecontrol := NaturadatOkeGomb;  
end;

// =============================================================================
              procedure TUgyfelInput.FillJogiEdits;
// =============================================================================

begin
  Joginevedit.text          := _jNev;
  TelephelyEdit.text        := _jTelephely;
  Fotevekenysegedit.text    := _jTevekeny;
  Okiratedit.text           := _jOkirat;
  Teaoredit.text            := _jTeaor;

  _teaornev                 := getTeaornev(_jteaor);
  Teaornevedit.Text         := _teaornev;

  KepvisnevEdit.text        := _jkepvisnev;
  Kepvisbeoedit.text        := _jKepvisBeo;
  Adoszamedit.text          := _jAdoszam;
  Megbizottbeoedit.text     := _jMbBeo;
  MegbizottNevPanel.Caption := _mbnev;
  MegbizottNevPanel.repaint;
end;

// =============================================================================
               procedure TUgyfelinput.FillTulNevEdits;
// =============================================================================

var i: byte;

begin
  for i := 1 to 4 do _tulajnevedit[i].text := '';

  if _tulajdarab=0 then exit;

  i := 1;
  while i<=_tulajdarab do
    begin
      _tulajnevedit[i].Text := _ttnev[i];
      inc(i);
    end;
end;


// =============================================================================
                procedure TUgyfelinput.JogiGombClick(Sender: TObject);
// =============================================================================

begin
  JogilistaGomb.Enabled := True;
  ActiveControl := Joginevedit;
end;

// =============================================================================
         procedure TUgyfelinput.SAJATNEVEBENGOMBClick(Sender: TObject);
// =============================================================================


begin
  Sajatmaspanel.Visible := False;
  FinalRegistration;
end;

// =============================================================================
        procedure TUgyfelinput.MASNEVEBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  Sajatmaspanel.visible := false;
  _ISO := '';
  _ALLAMPOLGAR := '';

  with MegbizoKbPanel do
    begin
      top := 520;
      left := 328;
      Visible := true;
      repaint;
    end;
  Activecontrol := MasBelGomb;
end;

// =============================================================================
            procedure TUgyfelinput.Masbelgombclick(Sender: TObject);
// =============================================================================

begin
  MegbizoKBPanel.visible := False;
  _Kulfoldi := 0;
  GetMegbizo;
end;

// =============================================================================
           procedure TUgyfelinput.MasKulgombclick(Sender: TObject);
// =============================================================================

begin
  MegbizoKBPanel.visible := False;
  _Kulfoldi := 1;
  GetMegbizo;
end;

// =============================================================================
                    procedure TUgyfelInput.GetMegbizo;
// =============================================================================

begin
  UgyfeltipusPanel.caption := 'A MEGBIZÓ SZEMÉLY';
  UgyfeltipusPanel.repaint;
  _uTip := 'MBZO';

  _ugyfelstatusz := 'MEGBIZO';
  GetNaturData;
end;

// =============================================================================
       procedure TUgyfelinput.JogiListaGombclick(Sender: TObject);
// =============================================================================

begin
  JogiValasztas;
end;

// =============================================================================
                   procedure TUgyfelinput.JogiValasztas;
// =============================================================================

begin
  NaturListaGomb.Enabled := False;
  _keres := '';
  JogikeresoEdit.clear;
  _voltJogiF6 := True;
  _ujjogiszemely := false;

  with JogiValasztoPanel do
    begin
      top := 60;
      Left := 144;
      Visible := True;
    end;

  JogiOpen;
  Jogiracs.SelectedIndex := 0;
  Jogiracs.SetFocus;
end;

// =============================================================================
                     procedure TUgyfelinput.SureQuit(Sender: TObject);
// =============================================================================

begin
  if _fizetendo<100000 then
    begin
      _pcs := 'UPDATE VTEMP SET KULFOLDI='+inttostr(_kulfoldi);
      ValutaParancs(_pcs);
      _mresult := 2;
      Kilep.Enabled := true;
      exit;
    end;

  with KotelezoPanel do
    begin
      Top  := 240;
      Left := 340;
      Visible := True;
    end;
  ActiveControl := IgenAzonositGomb;
end;

// =============================================================================
       procedure TUgyfelinput.MEGSEMVALASZTOKGOMBClick(Sender: TObject);
// =============================================================================

begin
  UgyfelvalasztoPanel.Visible := false;
end;

// =============================================================================
           procedure TUgyfelinput.FormCreate(Sender: TObject);
// =============================================================================

begin
  _width  := screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  _left   := round((_width-1020)/2);
  _top    := round((_height-765)/2);

  Top     := _top+144;
  Left    := _left+312;

  Height  := 194;
  Width   := 402;
end;

// =============================================================================
   procedure TUgyfelinput.TARTHELYEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=13 then Activecontrol := NaturadatOkeGomb;
end;


// =============================================================================
                  function TUgyfelinput.GetTulajDarab: byte;
// =============================================================================

var _akttnev: string;
    _y : byte;

begin
  _y := 1;
  result := 0;
  while _y<=4 do
    begin
      _akttnev := trim(_ttnev[_y]);
      if _akttnev='' then exit;

      inc(result);
      inc(_y);
    end;
end;

// =============================================================================
         procedure TUgyfelinput.TULAJOKEGOMBClick(Sender: TObject);
// =============================================================================

var _aktTulajNev: string;

begin

  Editbeolvasas;

  _aktstring := _ttnev[_tss];
  _aktstring := trim(_aktstring);
  _ww := length(_aktstring);
  if _ww<6 then
    begin
      tnevedit.Text := '';
      ActiveControl := Tnevedit;
      exit;
    end;

  _aktstring := _ttlakcim[_tss];
  _aktstring := trim(_aktstring);
  _ww := length(_aktstring);
  if _ww<6 then
    begin
      tlakcimedit.Text := '';
      ActiveControl := TLakcimedit;
      exit;
    end;

  _aktstring := _ttszulhely[_tss];
  _aktstring := trim(_aktstring);
  _ww := length(_aktstring);
  if _ww<2 then
    begin
      tszulhelyEdit.Text := '';
      ActiveControl := TSzulhelyEdit;
      exit;
    end;

  _aktstring := leftstr(_ttszulido[_tss],10);
  _oke := datumctrl(_aktstring);
  if not _oke then
    begin
      tSzulidoedit.Text := '';
      ActiveControl := TSzulidoedit;
      exit;
    end;

  _aktstring := _tttarthely[_tss];
  _aktstring := trim(_aktstring);
  _ww := length(_aktstring);
  if _ww<6 then
    begin
      ttarthelyedit.Text := '';
      ActiveControl := TTarthelyedit;
      exit;
    end;

  _aktstring := _tterdJelleg[_tss];
  _aktstring := trim(_aktstring);
  _ww := length(_aktstring);
  if _ww<6 then
    begin
      erdjellegedit.Text := '';
      ActiveControl := erdjellegedit;
      exit;
    end;

  _aktstring := _tterdmertek[_tss];
  _oke := erdMertCtrl(_aktstring);
  if not _oke then
    begin
      Erdmertekedit.Text := '';
      ActiveControl := ErdMertekEdit;
      exit;
    end;

  Tulajpanel.Visible := false;
  _aktTulajNev := _ttNev[_tss];

  if _aktTulajNev='' then exit;

  _tulajnevedit[_tss].Text := _akttulajnev;
  _tulajdarab := GetTulajDarab;

  if (megbizottnevpanel.Caption<>'') and (_tulajdarab>0) then JogiadatOkeGomb.Enabled := True;
end;

// =============================================================================
     procedure TUgyfelinput.TNEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

var _tag,_bill: byte;

begin
  _tag := TEdit(sender).Tag;
  _bill := ord(key);

  if (_bill=13) or (_bill=40) then
    begin
      if _tag<9 then
        begin
          inc(_tag);
         _aktedit := _tagedit[_tag];
          Activecontrol := _aktedit;
          exit;
        end else
        begin
          Activecontrol := TulajOkeGomb;
          exit;
        end;
     end;

  if _bill=38 then
    begin
      if _tag=1 then exit;
      dec(_tag);
      _aktedit := _tagedit[_tag];

      Activecontrol := _aktedit;
      exit;
    end;
end;

// =============================================================================
         procedure TUgyfelinput.NemKozSzerepRadioClick(Sender: TObject);
// =============================================================================

begin
  _nKozszereplo  := 0;
end;



// =============================================================================
        procedure TUgyfelinput.UgyfelRacsKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _wk: byte;

begin
  _bill := ord(key);
  if (_bill>32) and (_bill<41) then
    begin
      _keres := '';
      Ugyfelkeresoedit.clear;
      exit;
    end;

  if (_bill=8) then
    begin
      if _keres='' then exit;
      _wk := length(_keres);
      if _wk=1 then
        begin
          _keres := '';
          UgyfelKeresoEdit.clear;
          exit;
        end;
      dec(_wk);
      _keres := leftstr(_keres,_wk);
      UgyfelkeresoEdit.Text := _keres;
      ugyfelQuery.Locate('NEV',_keres,[loPartialKey]);
      exit;
    end;
end;


// =============================================================================
                procedure TUgyfelinput.editbeolvasas;
// =============================================================================

begin
  _tTnev[_tss]         := trim(TNevedit.Text);
  _tTElozonev[_tss]    := trim(TElozonevedit.Text);
  _tTLakcim[_tss]      := trim(Tlakcimedit.Text);
  _tTSZulhely[_tss]    := trim(Tszulhelyedit.Text);
  _tTSzulido[_tss]     := trim(Tszulidoedit.Text);
  _tTAllampolgar[_tss] := trim(TAllampolgEdit.Text);
  _tTtarthely[_tss]    := trim(TTarthelyedit.Text);
  _TTErdjelleg[_tss]   := trim(Erdjellegedit.Text);
  _TTErdMertek[_tss]   := trim(ErdMertekedit.Text);
  _tTKozszereplo[_tss] := 0;
  if KozigenRadio.checked then _tTkozszereplo[_tss] := 1;
end;


// =============================================================================
                procedure TUgyfelinput.TGOMB1Click(Sender: TObject);
// =============================================================================

begin
  _aktpanel := Tpanel(Sender);
  if _aktpanel.color = clBtnFace then exit;

  _tss := _aktPanel.Tag;
  TSorszamPanel.Caption := chr(48+_tss)+'.';

  _tnev               := _ttNev[_tss];
  _telozo             := _ttElozonev[_tss];
  _TLakcim            := _ttLakcim[_tss];
  _Tszulhely          := _ttSzulhely[_tss];
  _Tszulido           := _ttSzulido[_tss];
  _Tallampolgar       := _ttAllampolgar[_tss];
  _ttarthely          := _tttarthely[_tss];
  _tErdjelleg         := _tterdjelleg[_tss];
  _tErdmertek         := _tterdMertek[_tss];
  _tkozszereplo       := _ttkozszereplo[_tss];

  TNevedit.Text       := _tnev;
  TElozonevedit.Text  := _telozo;
  Tlakcimedit.Text    := _TLakcim;
  Tszulhelyedit.Text  := _tszulhely;
  Tszulidoedit.Text   := _tszulido;
  TAllampolgEdit.Text := _Tallampolgar;
  TTarthelyedit.Text  := _ttarthely;
  Erdjellegedit.Text  := _terdjelleg;
  ErdMertekedit.Text  := _terdmertek;

  if _tkozszereplo>0 then KozigenRadio.Checked := true
  else KoznemRadio.checked := True;

  with TulajPanel do
    begin
       Top    := 310;
      Left    := 260;
      Visible := true;
    end;

  Activecontrol := Tnevedit;
end;


// =============================================================================
    procedure TUgyfelinput.TGOMB1MouseMove(Sender: TObject; Shift: TShiftState;
                                                                 X, Y: Integer);
// =============================================================================

begin
  _aktgomb := TPanel(sender);
  _tag := _aktgomb.Tag;

  if _tag=_utGomb then exit;
  if _tag>(_tulajdarab+1) then exit;
  _utGomb := _tag;

  GombClear;
  _aktgomb.color := $B0FFFF;
end;

// =============================================================================
                          procedure TUgyfelInput.GombClear;
// =============================================================================

var i: byte;

begin
  for i := 1 to 4 do _tGomb[i].Color := clBtnface;
end;

// =============================================================================
        procedure TUgyfelinput.Shape12MouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  GombClear;
  _utgomb := 0;
end;

// =============================================================================
           procedure TUgyfelinput.KozIgenRadioClick(Sender: TObject);
// =============================================================================

var _talksz: byte;

begin
  if _toltes then exit;
  _talksz := _kozszereplo;
  _kozszereplo := getkiemeltstatusz;
  if _talksz<>_kozszereplo then _naturmezovaltozott := True;
//  Activecontrol := TulajOkeGomb;
end;

// =============================================================================
           procedure TUgyfelinput.KozNemRadioClick(Sender: TObject);
// =============================================================================

begin
  _tkozszereplo := 0;
end;


// =============================================================================
         procedure TUgyfelinput.KPOLGARGOMBClick(Sender: TObject);
// =============================================================================

begin
  SetNaturIso;
  KAllampolgarPanel.caption := _Allampolgar;
  KAllampolgarPanel.Repaint;
  KisoPanel.Caption := _iso;
  KisoPanel.repaint;
end;

// =============================================================================
                      procedure TUgyfelinput.SetNaturIso;
// =============================================================================

var _back: integer;
    _isoPlus: string;
begin
  _iso := '';
  _allampolgar := '';


   ValutaTempCtrl;
  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'A'+chr(39);
  ValutaParancs(_pcs);

  _back := getisorutin;
  if _back = 2 then
    begin
      _iso := '';
      _allampolgar := '';
      exit;
    end;

  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _isoplus := trim(FieldByName('MEGJEGYZES').AsString);
      Close;
    end;
  Valutadbase.close;
  _iso := Leftstr(_isoPlus,2);
  _allampolgar := midstr(_isoplus,3,length(_isoplus)-2);
end;

// =============================================================================
           procedure TUgyfelinput.OkmTipComboChange(Sender: TObject);
// =============================================================================

begin

  Activecontrol := Azonositoedit;
end;

// =============================================================================
          procedure TUgyfelInput.GetOrszagKod;
// =============================================================================

var _back: integer;
    _isoplus: string;

begin

  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'O'+CHR(39);
  ValutaParancs(_pcs);

  _back := getisorutin;
  if _back=2 then
    begin
      _mResult := -1;
      Kilep.Enabled := true;
      exit;
    end;

  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _isoplus := trim(FieldByName('MEGJEGYZES').AsString);
      Close;
    end;
  Valutadbase.close;

  _jiso := Leftstr(_isoPlus,2);
  _jOrszag := midstr(_isoplus,3,length(_isoplus)-2);

  OrszagPanel.Caption := _jOrszag;
  OrszagPanel.repaint;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// ============= ADATOK BEOLVASÁSA AZ ADATBÁZIKBÓL =============================

// =============================================================================
              procedure TUgyfelInput.getNaturDataFromdbase;
// =============================================================================

begin
  with UgyfelQuery do
    begin
      _ugyfelszam := FieldByName('UGYFELSZAM').asInteger;
      _Nev := trim(FieldByNAme('NEV').asstring);
      _elozo := trim(FieldByNAme('ELOZONEV').asstring);
      _Leany := trim(FieldByNAme('LEANYKORI').asString);
      _Anyja := trim(FieldByNAme('ANYJANEVE').asstring);
      _Szulhely := trim(FieldByNAme('SZULETESIHELY').asstring);
      _Szulido := trim(FieldByNAme('SZULETESIIDO').asstring);
      _Irszam := trim(FieldByName('IRSZAM').asstring);
      _Varos := trim(FieldByNAme('VAROS').asString);
      _Utca    := trim(FieldByNAme('UTCA').asstring);
      _Lcimcard := trim(FieldByNAme('LAKCIMKARTYA').asString);
      _OkmTipIndex := FieldByNAme('OKMTIPINDEX').asInteger;
      _Azonosito := trim(FieldByNAme('AZONOSITO').asstring);
      _Allampolgar := trim(FieldByNAme('ALLAMPOLGAR').asstring);
      _iso := FieldByName('ISO').asString;
      _Tarthely := trim(FieldByNAme('TARTOZKODASIHELY').asstring);
      _Kozszereplo := FieldByNAme('KOZSZEREPLO').asInteger;
      _Kulfoldi := FieldByName('KULFOLDI').asInteger;
      Close;
    end;
  Ugyfeldbase.close;
  _lakcim := leftstr(_irszam+' '+_varos+' '+_utca,40);
  _OkmanyTipus := _OkmTipTomb[_nOkmTipIndex];
end;

// =============================================================================
              procedure TUgyfelinput.getJogiDataFromDbase;
// =============================================================================

begin
  with JogiQuery do
    begin
      _jugyfelszam    := FieldByNAme('UGYFELSZAM').asInteger;
      _jNev           := TRIM(FieldByNAme('JOGISZEMELYNEV').asstring);
      _jTelepHely     := trim(FieldByNAme('TELEPHELYCIM').asString);
      _jOkirat        := trim(FieldByNAme('OKIRATSZAM').asstring);
      _jTevekeny      := trim(FieldByNAme('FOTEVEKENYSEG').asString);
      _jTeaor         := trim(FieldByName('TEAOR').AsString);
      _jKepvisnev     := trim(FieldByNAme('KEPVISELONEV').asstring);
      _mbugyfelszam   := FieldByName('MEGBIZOTTSZAMA').asInteger;
      _mbnev          := trim(FieldByNAme('MEGBIZOTTNEVE').asstring);
      _jMbBeo         := trim(FieldbyNAme('MEGBIZOTTBEOSZTASA').asString);
      _jKepvisbeo     := trim(FieldByNAme('KEPVISBEO').asstring);
      _Jadoszam       := trim(FieldByNAme('ADOSZAM').asstring);
      Close;
    end;
  Jogidbase.close;

  Tulajdbase.Connected := true;

  _tulajdarab := 0;
  _pcs := 'SELECT * FROM UJTULAJOK WHERE UGYFELSZAM='+inttostr(_jugyfelszam);
  with TulajQuery do
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
      Tulajquery.close;
      TulajDbase.close;
      exit;
    end;

  while not TulajQuery.eof do
    begin
      inc(_tulajdarab);
      with TulajQuery do
        begin
          _tTnev[_tulajdarab]       := trim(FieldByNAme('TULAJNEV').asString);
          _tTelozonev[_tulajdarab]  := trim(FieldByName('ELOZONEV').asstring);
          _tTlakcim[_tulajdarab]    := trim(FieldByNAme('LAKCIM').asstring);
          _tTszulhely[_tulajdarab]  := trim(FieldByName('SZULHELY').asString);
          _tTSzulido[_tulajdarab]   := trim(FieldByNAme('SZULIDO').asString);
          _tTAllampolgar[_tulajdarab] := trim(FieldByNAme('ALLAMPOLGAR').asstring);
          _tTTarthely[_tulajdarab]  := trim(FieldByNAme('TARTHELY').asString);
          _tTerdJelleg[_tulajdarab] := trim(FieldByNAme('ERDJELLEG').asstring);
          _tTerdMertek[_tulajdarab] := trim(FieldByNAme('ERDMERTEK').asstring);
          _tTKozszereplo[_tulajdarab] := Fieldbyname('TULKOZSZEREP').asInteger;
        end;
      TulajQuery.next;
    end;
  TulajQuery.close;
  Tulajdbase.close;
end;

// ================= ADATOK FELIRÁSA AZ ADATBÁZISOKBA ==========================


// =================== ADATOK BEOLVASÁSA A KÉPERNYÕRÕL =========================

// =============================================================================
               procedure TUgyfelInput.GetNaturDAtafromEdits;
// =============================================================================

begin
  _tarthely    := '';

  _nev         := trim(NevEdit.text);
  _Elozo       := trim(Elozonevedit.text);
  _Leany       := trim(LeanykoriEdit.text);
  _Anyja       := trim(AnyjaEdit.text);
  _Szulhely    := trim(SzulhelyEdit.text);
  _Szulido     := trim(SzulidoEdit.text);
  _Irszam      := trim(Irszamedit.text);
  _Varos       := trim(Varosedit.text);
  _Utca        := trim(Utcaedit.text);
  _lakcim      := trim(_irszam+' '+_VAros+' '+_Utca);
  _Lakcim      := leftstr(_lakcim,40);
  _Lcimcard    := trim(LCimcardEdit.text);
  _Azonosito   := trim(AzonositoEdit.text);
  _OkmTipIndex := OkmTipCOmbo.Itemindex;
  _OkmanyTipus := _okmTipTomb[_OkmTipIndex];
  if _kulfoldi =0 then
    begin
      _Allampolgar := Allampolgarpanel.caption;
      _iso         := IsoPanel.caption;
    end else
    begin
      _allampolgar := kAllampolgarPanel.caption;
      _iso         := kIsoPanel.caption;
      _Tarthely    := trim(tarthelyedit.text);
    end;
end;





// =============================================================================
               procedure TUgyfelInput.GetJogiDataFromEdits;
// =============================================================================

begin
  _jNev          := trim(joginevedit.text);
  _jTelephely    := trim(Telephelyedit.text);
  _jtevekeny     := trim(FoTevekenysegedit.text);
  _jTeaor        := trim(Teaoredit.Text);
  _jOkirat       := trim(OkiratEdit.text);
  _jKepvisnev    := trim(Kepvisnevedit.text);
  _jKepvisBeo    := trim(KepvisbeoEdit.text);
  _jMbBeo        := trim(Megbizottbeoedit.text);
  _jAdoszam      := trim(Adoszamedit.Text);
  _mbNev         := trim(MegbizottnevPanel.caption);
end;

// =============================================================================
              procedure Tugyfelinput.GetTulajDataFromedits;
// =============================================================================

begin
  _tNev       := trim(Tnevedit.text);
  _telozo     := trim(Telozonevedit.text);
  _tLakcim    := trim(tlakcimedit.text);
  _tszulhely  := trim(TSzulhelyEdit.text);
  _tSzulido   := trim(Tszulidoedit.text);
  _tAllamPolgar := trim(tAllampolgedit.text);
  _tTarthely  := trim(tTarthelyedit.text);
  _terdjelleg := trim(erdJellegedit.text);
  _tErdmertek := trim(erdMertekedit.text);
end;


// ============================ SEGÉD PROGRAMOK ================================

// =============================================================================
             procedure TUgyfelInput.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.Connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;

  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  ValutaTranz.Commit;
  Valutadbase.Close;
end;

// =============================================================================
                  procedure TUgyfelInput.TombMeghatarozas;
// =============================================================================

begin
  _NaturEdit[1] := Nevedit;
  _Naturedit[2] := elozonevEdit;
  _naturEdit[3] := Leanykoriedit;
  _naturedit[4] := anyjaEdit;
  _naturedit[5] := szulhelyedit;
  _naturedit[6] := szulidoedit;
  _naturedit[7] := irszamedit;
  _naturedit[8] := varosedit;
  _naturedit[9] := utcaedit;
  _naturedit[10]:= lcimcardedit;
  _naturEdit[11]:= Azonositoedit;
  _naturedit[12]:= Tarthelyedit;

  _jogiedit[1] := Joginevedit;
  _jogiedit[2] := Telephelyedit;
  _jogiedit[3] := Fotevekenysegedit;
  _jogiedit[4] := Teaoredit;
  _jogiedit[5] := Okiratedit;
  _jogiedit[6] := Kepvisnevedit;
  _jogiedit[7] := Kepvisbeoedit;
  _jogiedit[8] := AdoszamEdit;
  _jogiedit[9] := Megbizottbeoedit;

  _tulajnevedit[1] := Tulajnev1Edit;
  _tulajnevedit[2] := Tulajnev2Edit;
  _tulajnevedit[3] := Tulajnev3Edit;
  _tulajnevedit[4] := Tulajnev4Edit;

  _tagedit[1] := TNevedit;
  _tagedit[2] := TElozonevedit;
  _tagedit[3] := Tlakcimedit;
  _tagedit[4] := Tszulhelyedit;
  _tagedit[5] := Tszulidoedit;
  _tagedit[6] := TAllampolgEdit;
  _tagedit[7] := TTarthelyedit;
  _tagedit[8] := Erdjellegedit;
  _tagedit[9] := ErdMertekedit;

  _tGomb[1] := Tgomb1;
  _tGomb[2] := Tgomb2;
  _tGomb[3] := Tgomb3;
  _tGomb[4] := Tgomb4;

end;

// =============================================================================
                  procedure TUgyfelInput.AlapraAllitas;
// =============================================================================

begin
  NaturPanel.Visible        := False;
  MegbizottGombPanel.Visible:= False;
  NaturgombPanel.Visible    := False;
  KotelezoPanel.Visible     := False;
  JogiValasztoPanel.Visible := False;
  SajatMasPanel.Visible     := False;
  MegbizogombPanel.Visible  := False;
  _voltF5                   := False;

  _ujJogiszemely            := False;
  _ujMegbizott              := False;

  _naturmezovaltozott       := False;
  _jogimezovaltozott        := False;
  _mbMezovaltozott          := False;
  _mzMezovaltozott          := False;

  _voltmegbizottF5          := False;
  _voltjogiF6               := False;
  _kotelezo                 := False;

  Belradio.checked          := True;
  Naturradio.checked        := True;

  _ugyfelszam               := 0;
  _mzugyfelszam             := 0;
  _mbugyfelszam             := 0;
end;

// =============================================================================
                 procedure TUgyfelinput.ParaBeolvasas;
// =============================================================================
//      Vtemp-bõl beolvassa: fizetendo,tipus éd konverzio

begin
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      First;
      _fizetendo  := FieldbyName('FIZETENDO').asInteger;
      _tipus      := FieldByName('TIPUS').asstring;
      _konverzio  := FieldByName('KONVERZIO').asInteger;
      Close;
      sql.Clear;
      sql.Add('SELECT * FROM HARDWARE');
      Open;

      _serveraccess := FieldByName('SERVERACCESS').asInteger;
      _postterm     := FieldByNAme('POSTTERM').asInteger;
      Close;
    end;
  Valutadbase.close;


  _mess := 'Paraolvasás: Fizetendo='+inttostr(_fizetendo);
  _mess := _mess + ' Tipus='+chr(39)+_tipus+chr(39);

end;

// =============================================================================
         procedure TUgyfelinput.IgenAzonositGombClick(Sender: TObject);
// =============================================================================

begin
  KotelezoPanel.Visible := False;
end;

// =============================================================================
               procedure TUgyfelinput.NevEditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := $B0FFFF;
end;

// =============================================================================
               procedure TUgyfelinput.NeveditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
end;

// =============================================================================
                           procedure TUgyfelinput.UgyfelOpen;
// =============================================================================

// Megnyitja az UGYFEL táblát (filter: kulfoldi=-kulfoldi, toroéve=1)

begin

  _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
  _pcs := _pcs + 'WHERE (TOROLVE=1) AND (KULFOLDI='+inttostr(_kulfoldi)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY NEV';

  UgyfelDbase.Connected := true;
  with UgyfelQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;
end;

// =============================================================================
                          procedure TUgyfelinput.JogiOpen;
// =============================================================================

begin
  _pcs := 'SELECT * FROM JOGISZEMELY' + _sorveg;
  _pcs := _pcs + 'WHERE TOROLVE=1' + _sorveg;
  _pcs := _pcs + 'ORDER BY JOGISZEMELYNEV';

  JogiDbase.Connected := true;
  with JogiQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;
end;

// =============================================================================
               procedure TUgyfelinput.RP1Click(Sender: TObject);
// =============================================================================

begin
  _kozszereplo := TRadioButton(Sender).Tag;
end;


// =============================================================================
          procedure TUgyfelinput.TULAJMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ttnev[_tss] := '';
  TulajPanel.Visible := False;
end;

// =============================================================================
         procedure TUgyfelinput.KULRADIOClick(Sender: TObject);
// =============================================================================

begin
  _nkulfoldi := 1;
end;

// =============================================================================
          procedure TUgyfelinput.BELRADIOClick(Sender: TObject);
// =============================================================================

begin
  _jkulfoldi := 0;
end;


// =============================================================================
             procedure TUgyfelinput.POLGARGOMBClick(Sender: TObject);
// =============================================================================

begin
  SetNaturIso;
  if _utip='N' then _naturmezovaltozott := True;
  if _utip='MBTT' then _mbMezoValtozott := true;
  if _utip='MBZO' then _mzMezoValtozott := True;
  AllampolgarPanel.caption := _Allampolgar;
  AllamPolgarPanel.Repaint;
  isoPanel.caption := _iso;
  isopanel.repaint;

end;



// =============================================================================
          function TUgyfelInput.datumctrl(_dst: string): boolean;
// =============================================================================

var _ctevs,_cthos,_ctnaps: string;
    _ctev,_ctho,_ctnap: word;

begin
  result := False;
  if length(_dst)<10 then exit;

  _ctevs := leftstr(_dst,4);
  val(_ctevs,_ctev,_code);
  if (_code<>0) or (_ctev>2040) or (_ctev<1920) then exit;
  if midstr(_dst,5,1)<>'.' then exit;
  if midstr(_dst,8,1)<>'.' then exit;

  _cthos := midstr(_dst,6,2);
  val(_cthos,_ctho,_code);
  if (_ctho<1) or (_ctho>12) or (_code<>0) then exit;

  _ctnaps := midstr(_dst,9,2);
  val(_ctnaps,_ctnap,_code);
  if (_ctnap<1) or (_ctnap>31) or (_code<>0)then exit;

  result := True;
end;


// =============================================================================
           function TUgyfelInput.erdmertctrl(_em: string): boolean;
// =============================================================================


var _wem,_asc,_y: byte;
    _nums: string;
    _num: integer;

begin
  result  := False;
  _em := trim(_em);
  _wem := length(_em);
  if _wem=0 then exit;
  if ord(_em[_wem])<>37 then exit;   // %-jel a végén
  _nums := '';
  _y := 1;
  while _y<_wem do
    begin
      _asc := ord(_em[_y]);
      if _asc=32 then break;
      _nums := _nums + chr(_asc);
      inc(_y);
    end;
  val(_nums,_num,_code);
  if (_code<>0) or (_num=0) then exit;
  result := true;
end;



// =============================================================================
             procedure TUgyfelinput.KILEPTimer(Sender: TObject);
// =============================================================================

begin
  Kilep.Enabled := False;
  _pcs := 'UPDATE VTEMP SET KULFOLDI='+inttostr(_kulfoldi);
  _pcs := _pcs + ',SECURLEVEL='+inttostr(_securlevel);
  ValutaParancs(_pcs);

  if _mResult>0 then
    begin
      Tempdbase.Connected := True;
      with TempQuery do
        begin
          Close;
          sql.clear;
          Sql.add('SELECT * FROM VTEMP');
          Open;
          _ugyfelnev := trim(FieldByNAme('UGYFELNEV').asString);
          Close;
        end;
      tempdbase.close;
      if _ugyfelnev<>'' then
         begin
           _terrback := terrorcontrol;
           if _terrback=-1 then _mResult := -1;
         end;
    end;

  Modalresult := _Mresult;

end;

// =============================================================================
        procedure TUgyfelinput.IRSZAMEDITChange(Sender: TObject);
// =============================================================================

begin
  if _uTip='N' then
    begin
      if _voltNaturF5 then _NaturMezoValtozott := true;
    end;

  if _uTip='MBTT' then
    begin
      if _voltjogiF6 then  _mbmezovaltozott := True;
    end;

  if _utip='MBZO' then
    begin
      if _voltmegbizoF5 then _mzMezoValtozott := True;
    end;
end;


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$  FINAL   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
              procedure TUgyfelInput.FinalRegistration;
// =============================================================================

{
  A kötelezõ adatok: _ugyfeltipus        = 'N' VAGY 'J'

                     NATURSZEMÉLY ESETÉN:

                         _ujnaturugyfel      = FALSE vagy TRUE
                         _naturmezovaltozott = FALSE vagy TRUE
                         _megbizovaltozott   = FALSE vagy TRUE
                         _megbizoszam        = integer;

                     JOGISZEMÉLY ESETÉN:

                         _ujjogiszemely      = FALSE vagy TRUE;
                         _ujmegbizott        = FALSE vagy TRUE;
                         _jogimezovaltozott  = FALSE vagy TRUE;
                         _megbizottvaltozott = FALSE vagy TRUE;


}

begin
  if _ugyfeltipus='N' then
    begin
      if _ujnaturugyfel then SaveNaturugyfel
      else if _naturmezoValtozott then UpdateNatur;

      if _ujmegbizo then SaveMegbizo;
      if _mzmezoValtozott then UpdateMegbizo;
    end;

  if _ugyfeltipus='J' then
    begin
      if _ujmegbizott then SaveMegbizott;
      if _mbmezovaltozott then UpdateMegbizott;

      if (_ujjogiszemely) then
        begin
          SaveJogiszemely;
          SaveTulajdonosok;
        end;

      if _jogiMezoValtozott then UpdateJogiszemely;
    end;

  _ugyfelszam := _nUgyfelszam;

  if _ugyfeltipus='J' then _ugyfelszam := _jugyfelszam;
  ValutaTempctrl;

  _pcs := 'UPDATE VTEMP SET UGYFELSZAM='+inttostr(_ugyfelszam);
  _pcs := _pcs + ',UGYFELTIPUS=' + chr(39) + _ugyfeltipus + chr(39);
  _pcs := _pcs + ',MEGBIZOSZAM=';

  if _ugyfeltipus='J' then _pcs := _pcs + inttostr(_mbugyfelszam)
  else _pcs := _pcs + inttostr(_mzUgyfelszam);

  _pcs := _pcs + ',KOZSZEREPLO=' + inttostr(_kozszereplo);
  if _ugyfeltipus='J' then
    begin
      _pcs := _pcs + ',ADOSZAM='+chr(39)+_jAdoszam+chr(39);
      _pcs := _pcs + ',MEGBIZOTTSZAM=' + inttostr(_mbugyfelszam);
    end;

  ValutaParancs(_pcs);

 {
  _pcs := 'DELETE FROM PARTNERPARA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO PARTNERPARA (UGYFELTIPUS,UGYFELSZAM,SECURLEVEL,MEGBIZO,';
  _pcs := _pcs + 'MEGBIZOTT,KULFOLDI,TULAJDARAB,STATUSZ,ENGEDELYEZO)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_ugyfeltipus + chr(39) + ',';
  _pcs := _pcs + inttostr(_ugyfelszam) + ',';
  _pcs := _pcs + inttostr(_securlevel) + ',';
  _pcs := _pcs + inttostr(_mzugyfelszam) + ',';
  _pcs := _pcs + inttostr(_mbugyfelszam) + ',';
  _pcs := _pcs + inttostr(_kulfoldi) + ',';
  _pcs := _pcs + inttostr(_tulajdarab) + ',';
  _pcs := _pcs + inttostr(_kozszereplo) + ',';
  _pcs := _pcs + chr(39) + _engedelyezo + chr(39)+ ')';
  ValutaParancs(_pcs);
  }

  if _serverAccess=1 then
    begin
      with NoInternetPanel do
        begin
          top := 307;
          left := 372;
          Visible := true;
          repaint;
        end;
      Activecontrol := Tovagomb;
      exit;
    end;

  TRY
    _mResult := gongyoletcontrol;
  EXCEPT
    _mResult := 2;
    Kilep.enabled := True;
    exit;
  END;
  Kilep.Enabled := true;
end;


// =============================================================================
                   procedure TUgyfelInput.SaveTulajdonosok;
// =============================================================================

var _y: byte;

begin

  _pcs := 'DELETE FROM UJTULAJOK WHERE UGYFELSZAM='+inttostr(_jUgyfelszam);
  ValutaParancs(_pcs);

  if _tulajdarab=0 then exit;

  _Y := 1;
  while _y<=_tulajdarab do
    BEGIN
      _tNev         := _tTnev[_y];
      _telozo       := _tTelozonev[_y];
      _tLakcim      := _tTlakcim[_y];
      _tszulhely    := _tTSzulhely[_y];
      _tSzulido     := _tTszulido[_y];
      _tAllamPolgar := _tTallampolgar[_y];
      _tTarthely    := _tTTarthely[_y];
      _terdjelleg   := _tTerdjelleg[_y];
      _terdmertek   := _tTerdMertek[_y];
      _tKozszereplo := _tTkozszereplo[_y];

      _pcs := 'INSERT INTO UJTULAJOK (UGYFELSZAM,SORSZAM,TULAJNEV,ELOZONEV,';
      _pcs := _pcs + 'LAKCIM,SZULHELY,SZULIDO,ALLAMPOLGAR,TARTHELY,ERDJELLEG,';
      _pcs := _pcs + 'ERDMERTEK,TULKOZSZEREP)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + inttostr(_jugyfelszam)+',';
      _pcs := _pcs + inttostr(_y) + ',';
      _pcs := _pcs + chr(39) + _tNev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _telozo + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tLakcim + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tSzulhely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tSzulido + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tAllampolgar + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tTarthely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _terdjelleg + chr(39) + ',';
      _pcs := _pcs + chr(39) + _terdmertek + chr(39) + ',';
      _pcs := _pcs + inttostr(_tKozszereplo) + ')';

      ValutaParancs(_pcs);
      inc(_y);
    end;
end;



// =============================================================================
           procedure TUgyfelinput.mezoadatokAtmasolasa;
// =============================================================================

begin
  if _utip='N' then
    begin
      _nugyfelszam  := _ugyfelszam;
      _nnev         := _nev;
      _nElozo       := _elozo;
      _nLeany       := _leany;
      _nAnyja       := _anyja;
      _nSzulhely    := _szulhely;
      _nSzulido     := _szulido;
      _nIrszam      := _irszam;
      _nVaros       := _varos;
      _nUtca        := _utca;
      _nLcimcard    := _lCimCard;
      _nAzonosito   := _azonosito;
      _nOkmTipIndex := _okmtipindex;
      _nOkmanyTipus := _okmanytipus;
      _nAllampolgar := _allampolgar;
      _niso         := _iso;
      _nTarthely    := _tarthely;
      _nkulfoldi    := _kulfoldi;
      _nKozszereplo := _kozszereplo;
    end;

  if _utip='MBTT' then
    begin
      _mbugyfelszam  := _ugyfelszam;
      _mbnev         := _nev;
      _mbElozo       := _elozo;
      _mbLeany       := _leany;
      _mbAnyja       := _anyja;
      _mbSzulhely    := _szulhely;
      _mbSzulido     := _szulido;
      _mbIrszam      := _irszam;
      _mbVaros       := _varos;
      _mbUtca        := _utca;
      _mbLcimcard    := _lCimCard;
      _mbAzonosito   := _azonosito;
      _mbOkmTipIndex := _okmtipindex;
      _mbOkmanyTipus := _okmanytipus;
      _mbAllampolgar := _allampolgar;
      _mbiso         := _iso;
      _mbTarthely    := _tarthely;
      _mbkulfoldi    := _kulfoldi;
      _mbKozszereplo := _kozszereplo;
    end;

   if _utip='MBZO' then
     begin
      _mzugyfelszam  := _ugyfelszam;
      _mznev         := _nev;
      _mzElozo       := _elozo;
      _mzLeany       := _leany;
      _mzAnyja       := _anyja;
      _mzSzulhely    := _szulhely;
      _mzSzulido     := _szulido;
      _mzIrszam      := _irszam;
      _mzVaros       := _varos;
      _mzUtca        := _utca;
      _mzLcimcard    := _lCimCard;
      _mzAzonosito   := _azonosito;
      _mzOkmTipIndex := _okmtipindex;
      _mzOkmanyTipus := _okmanytipus;
      _mzAllampolgar := _allampolgar;
      _mziso         := _iso;
      _mzTarthely    := _tarthely;
      _mzkulfoldi    := _kulfoldi;
      _mzKozszereplo := _kozszereplo;
    end;
end;

// =============================================================================
         procedure TUgyfelinput.JOGINEVEDITChange(Sender: TObject);
// =============================================================================

begin
  if _voltjogiF6 then _jogimezovaltozott := true;
end;


// =============================================================================
             procedure TugyfelInput.TulajAdatokNullazasa;
// =============================================================================

var i: byte;

begin
  for i := 1 to 4 do
    begin
      _tulajnevedit[i].Clear;
      _ttnev[i]       := '';
      _ttelozonev[i]  := '';
      _ttlakcim[i]    := '';
      _ttszulhely[i]  := '';
      _ttszulido[i]   := '';
      _ttAllampolgar[i] := '';
      _ttTarthely[i]  := '';
      _tterdjelleg[i] := '';
      _tterdmertek[i] := '';
      _ttKozszereplo[i] := 0;
    end;
end;




// =============================================================================
                     procedure TugyfelInput.UpdateNatur;
// =============================================================================

begin
  if _nLakcim='' then
         _nLakcim := _nirszam + ' '+_nVaros + ' ' + _nUtca;

  _pcs := 'UPDATE UGYFEL SET NEV='+CHR(39)+_NNEV + chr(39);
  _pcs := _pcs + ',ELOZONEV=' + chr(39) + _nElozo + chr(39);
  _pcs := _pcs + ',ANYJANEVE=' + chr(39) + _nAnyja + chr(39);
  _pcs := _pcs + ',LEANYKORI=' + chr(39) + _nLeany + chr(39);
  _pcs := _pcs + ',SZULETESIHELY=' + chr(39) + _nSZulhely + chr(39);
  _pcs := _pcs + ',SZULETESIIDO=' + chr(39) + _nSzulido + chr(39);
  _pcs := _pcs + ',ALLAMPOLGAR=' + CHR(39) + _nAllampolgar + chr(39);
  _pcs := _pcs + ',ISO=' + chr(39) + _nIso + chr(39);
  _pcs := _pcs + ',TOROLVE=1';
  _pcs := _pcs + ',LAKCIM=' + chr(39) + _nLakcim + chr(39);
  _pcs := _pcs + ',OKMANYTIPUS=' + chr(39)+ _nOkmanytipus+chr(39);
  _pcs := _pcs + ',OKMTIPINDEX=' + inttostr(_nOkmTipIndex);
  _pcs := _pcs + ',AZONOSITO=' + CHR(39) + _nAzonosito + chr(39);
  _pcs := _pcs + ',TARTOZKODASIHELY=' + chr(39) + _nTartHely + chr(39);
  _pcs := _pcs + ',LAKCIMKARTYA=' + chr(39) + _nLcimcard + chr(39);
  _pcs := _pcs + ',KULFOLDI=' + inttostr(_nKulfoldi);
  _pcs := _pcs + ',KOZSZEREPLO=' + inttostr(_nKozszereplo);
  _pcs := _pcs + ',IRSZAM=' + chr(39) + _nIrszam + chr(39);
  _pcs := _pcs + ',VAROS=' + chr(39) + _nvaros + chr(39);
  _pcs := _pcs + ',UTCA='+ chr(39) + _nUtca + chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_nUgyfelszam);
  ValutaParancs(_pcs);
end;


// =============================================================================
           procedure TugyfelInput.UpdateJogiszemely;
// =============================================================================

begin
  _pcs := 'UPDATE JOGISZEMELY SET JOGISZEMELYNEV='+chr(39)+_jnev+chr(39);
  _pcs := _pcs + ',TELEPHELYCIM=' + chr(39)+ _jTelephely + chr(39);
  _pcs := _pcs + ',OKIRATSZAM=' + chr(39) + _jOkirat + chr(39);
  _pcs := _pcs + ',FOTEVEKENYSEG=' + chr(39) + _jTevekeny + chr(39);
  _pcs := _pcs + ',TEAOR=' + chr(39) + _jTeaor + chr(39);
  _pcs := _pcs + ',KEPVISELONEV=' + chr(39) + _jKepvisnev + chr(39);
  _pcs := _pcs + ',MEGBIZOTTSZAMA=' + inttostr(_mbugyfelszam);
  _pcs := _pcs + ',MEGBIZOTTNEVE=' + chr(39)+ _mbnev + chr(39);
  _pcs := _pcs + ',MEGBIZOTTBEOSZTASA=' +chr(39)+ _jMbBeo + chr(39);
  _pcs := _pcs + ',KEPVISBEO='+chr(39) + _jKepvisbeo + chr(39);
  _pcs := _pcs + ',ISO=' + chr(39) + _jIso + chr(39);
  _pcs := _pcs + ',ORSZAG='+chr(39) + _jOrszag + chr(39);
  _pcs := _pcs + ',TOROLVE=1';
  _pcs := _pcs + ',KULFOLDI=' + inttostr(_jKulfoldi);
  _pcs := _pcs + ',ADOSZAM=' + CHR(39) + _jAdoszam + chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_jUgyfelszam);
  ValutaParancs(_pcs);
end;

// =============================================================================
                     procedure TugyfelInput.UpdateMegbizott;
// =============================================================================

begin
   if _mbLakcim='' THEN
        _mblakcim := _mbirszam+' '+_mbVaros+' '+_mbutca;


  _pcs := 'UPDATE UGYFEL SET NEV='+CHR(39)+_mbNEV + chr(39);
  _pcs := _pcs + ',ELOZONEV=' + chr(39) + _mbElozo + chr(39);
  _pcs := _pcs + ',ANYJANEVE=' + chr(39) + _mbAnyja + chr(39);
  _pcs := _pcs + ',LEANYKORI=' + chr(39) + _mbLeany + chr(39);
  _pcs := _pcs + ',SZULETESIHELY=' + chr(39) + _mbSZulhely + chr(39);
  _pcs := _pcs + ',SZULETESIIDO=' + chr(39) + _mbSzulido + chr(39);
  _pcs := _pcs + ',ALLAMPOLGAR=' + CHR(39) + _mbAllampolgar + chr(39);
  _pcs := _pcs + ',ISO=' + chr(39) + _mbIso + chr(39);
  _pcs := _pcs + ',TOROLVE=1';
  _pcs := _pcs + ',LAKCIM=' + chr(39) + _mbLakcim + chr(39);
  _pcs := _pcs + ',OKMANYTIPUS=' + chr(39)+ _mbOkmanytipus+chr(39);
  _pcs := _pcs + ',OKMTIPINDEX=' + inttostr(_mbOkmTipIndex);
  _pcs := _pcs + ',AZONOSITO=' + CHR(39) + _mbAzonosito + chr(39);
  _pcs := _pcs + ',TARTOZKODASIHELY=' + chr(39) + _mbTartHely + chr(39);
  _pcs := _pcs + ',LAKCIMKARTYA=' + chr(39) + _mbLcimcard + chr(39);
  _pcs := _pcs + ',KULFOLDI=' + inttostr(_mbKulfoldi);
  _pcs := _pcs + ',KOZSZEREPLO=' + inttostr(_mbKozszereplo);
  _pcs := _pcs + ',IRSZAM=' + chr(39) + _mbIrszam + chr(39);
  _pcs := _pcs + ',VAROS=' + chr(39) + _mbvaros + chr(39);
  _pcs := _pcs + ',UTCA='+ chr(39) + _mbUtca + chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_mbUgyfelszam);
  ValutaParancs(_pcs);
end;

// =============================================================================
                     procedure TugyfelInput.UpdateMegbizo;
// =============================================================================

begin
   if _mzLakcim='' THEN
        _mzlakcim := _mzirszam+' '+_mzVaros+' '+_mzutca;


  _pcs := 'UPDATE UGYFEL SET NEV='+CHR(39)+_mzNEV + chr(39);
  _pcs := _pcs + ',ELOZONEV=' + chr(39) + _mzElozo + chr(39);
  _pcs := _pcs + ',ANYJANEVE=' + chr(39) + _mzAnyja + chr(39);
  _pcs := _pcs + ',LEANYKORI=' + chr(39) + _mzLeany + chr(39);
  _pcs := _pcs + ',SZULETESIHELY=' + chr(39) + _mzSZulhely + chr(39);
  _pcs := _pcs + ',SZULETESIIDO=' + chr(39) + _mzSzulido + chr(39);
  _pcs := _pcs + ',ALLAMPOLGAR=' + CHR(39) + _mzAllampolgar + chr(39);
  _pcs := _pcs + ',ISO=' + chr(39) + _mzIso + chr(39);
  _pcs := _pcs + ',TOROLVE=1';
  _pcs := _pcs + ',LAKCIM=' + chr(39) + _mzLakcim + chr(39);
  _pcs := _pcs + ',OKMANYTIPUS=' + CHR(39)+ _mzOkmanytipus+chr(39);
  _pcs := _pcs + ',OKMTIPINDEX=' + inttostr(_mzOkmTipIndex);
  _pcs := _pcs + ',AZONOSITO=' + CHR(39) + _mzAzonosito + chr(39);
  _pcs := _pcs + ',TARTOZKODASIHELY=' + chr(39) + _mzTartHely + chr(39);
  _pcs := _pcs + ',LAKCIMKARTYA=' + chr(39) + _mzLcimcard + chr(39);
  _pcs := _pcs + ',KULFOLDI=' + inttostr(_mzKulfoldi);
  _pcs := _pcs + ',KOZSZEREPLO=' + inttostr(_mzKozszereplo);
  _pcs := _pcs + ',IRSZAM=' + chr(39) + _mzIrszam + chr(39);
  _pcs := _pcs + ',VAROS=' + chr(39) + _mzvaros + chr(39);
//  _pcs := _pcs + ',ADOSZAM=' + CHR(39) + _ADOSZAM + CHR(39);
  _pcs := _pcs + ',UTCA='+ chr(39) + _mzUtca + chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_mzUgyfelszam);
  ValutaParancs(_pcs);
end;


// =============================================================================
                  procedure TUgyfelInput.SaveNaturUgyfel;
// =============================================================================

begin
  _nugyfelszam := UgyfelszamLepteto;
  _nLakcim := leftstr(_nIrszam+' '+_nVaros+' '+_nUtca,40);

  _pcs := 'INSERT INTO UGYFEL (UGYFELSZAM,NEV,ELOZONEV,ANYJANEVE,';
  _pcs := _pcs + 'LEANYKORI,SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,ISO,TOROLVE,';
  _pcs := _pcs + 'LAKCIM,OKMANYTIPUS,OKMTIPINDEX,AZONOSITO,TARTOZKODASIHELY,';
  _pcs := _pcs + 'LAKCIMKARTYA,KULFOLDI,KOZSZEREPLO,IRSZAM,VAROS,UTCA)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_nugyfelszam)+',';
  _pcs := _pcs + chr(39) + _nNev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nElozo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nAnyja + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nLeany + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nSzulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nSzulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nAllampolgar + chr(39) + ',';
  _pcs := _pcs + chr(39) + _niso + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _nlakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nOkmanyTipus + chr(39) + ',';
  _pcs := _pcs + inttostr(_nOkmTipIndex) + ',';
  _pcs := _pcs + chr(39) + _nAzonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nTarthely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nLcimCArd + chr(39) + ',';
  _pcs := _pcs + inttostr(_nkulfoldi) + ',';
  _pcs := _pcs + inttostr(_nkozszereplo) + ',';
  _pcs := _pcs + chr(39) + _nIrszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nVAros + chr(39) + ',';
  _pcs := _pcs + chr(39) + _nUtca + chr(39) + ')';
  ValutaParancs(_pcs);
end;

// =============================================================================
                   procedure TUgyfelInput.SaveJogiszemely;
// =============================================================================

begin
  _jugyfelszam := UgyfelszamLepteto;

  _pcs := 'INSERT INTO JOGISZEMELY (UGYFELSZAM,JOGISZEMELYNEV,TELEPHELYCIM';
  _pcs := _pcs + ',OKIRATSZAM,FOTEVEKENYSEG,TEAOR,KEPVISELONEV,MEGBIZOTTSZAMA,';
  _pcs := _pcs + 'MEGBIZOTTNEVE,MEGBIZOTTBEOSZTASA,KEPVISBEO,ISO,ORSZAG,';
  _pcs := _pcs + 'TOROLVE,KULFOLDI,ADOSZAM)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_jugyfelszam) + ',';
  _pcs := _pcs + chr(39) + _jNev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jTelephely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jOkirat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jTevekeny + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jTeaor + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jKepvisnev + chr(39) + ',';
  _pcs := _pcs + inttostr(_mbugyfelszam) + ',';
  _pcs := _pcs + chr(39) + _mbnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jMbBeo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jKepvisbeo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jIso + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jOrszag + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + inttostr(_jkulfoldi) + ',';
  _pcs := _Pcs + chr(39) + _jadoszam + chr(39) + ')';
  ValutaParancs(_pcs);
end;


// =============================================================================
                procedure TUgyfelInput.SaveMegbizott;
// =============================================================================

begin
  _mbUgyfelszam := UgyfelszamLepteto;


  _mblakcim := leftstr(_mbIrszam+' '+_mbVaros+' '+_mbutca,40);

  _pcs := 'INSERT INTO UGYFEL (UGYFELSZAM,NEV,ELOZONEV,ANYJANEVE,';
  _pcs := _pcs + 'LEANYKORI,SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,ISO,TOROLVE,';
  _pcs := _pcs + 'LAKCIM,OKMANYTIPUS,OKMTIPINDEX,AZONOSITO,TARTOZKODASIHELY,';
  _pcs := _pcs + 'LAKCIMKARTYA,KULFOLDI,KOZSZEREPLO,IRSZAM,VAROS,UTCA)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_mbugyfelszam)+',';
  _pcs := _pcs + chr(39) + _mbNev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbElozo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbAnyja + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbLeany + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbSzulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbSzulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbAllampolgar + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbiso + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _mblakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbOkmanyTipus + chr(39) + ',';
  _pcs := _pcs + inttostr(_mbOkmTipIndex) + ',';
  _pcs := _pcs + chr(39) + _mbAzonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbTarthely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbLcimCArd + chr(39) + ',';
  _pcs := _pcs + inttostr(_mbkulfoldi) + ',';
  _pcs := _pcs + inttostr(_mbkozszereplo) + ',';
  _pcs := _pcs + chr(39) + _mbIrszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbVAros + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbUtca + chr(39) + ')';
  ValutaParancs(_pcs);
end;

// =============================================================================
                procedure TUgyfelInput.SaveMegbizo;
// =============================================================================

begin
  _mzUgyfelszam := UgyfelszamLepteto;

  if _mzlakcim='' then
      _mzlakcim := leftstr(_mzIrszam+' '+_mzVaros+' '+_mzutca,40);

  _pcs := 'INSERT INTO UGYFEL (UGYFELSZAM,NEV,ELOZONEV,ANYJANEVE,';
  _pcs := _pcs + 'LEANYKORI,SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,ISO,TOROLVE,';
  _pcs := _pcs + 'LAKCIM,OKMANYTIPUS,OKMTIPINDEX,AZONOSITO,TARTOZKODASIHELY,';
  _pcs := _pcs + 'LAKCIMKARTYA,KULFOLDI,KOZSZEREPLO,IRSZAM,VAROS,UTCA)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_mzugyfelszam)+',';
  _pcs := _pcs + chr(39) + _mbNev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbElozo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbAnyja + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbLeany + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbSzulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbSzulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbAllampolgar + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbiso + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _mblakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbOkmanyTipus + chr(39) + ',';
  _pcs := _pcs + inttostr(_mbOkmTipIndex) + ',';
  _pcs := _pcs + chr(39) + _mbAzonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbTarthely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbLcimCArd + chr(39) + ',';
  _pcs := _pcs + inttostr(_mbkulfoldi) + ',';
  _pcs := _pcs + inttostr(_mbkozszereplo) + ',';
  _pcs := _pcs + chr(39) + _mbIrszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbVAros + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbUtca + chr(39) + ')';
  ValutaParancs(_pcs);
end;

// =============================================================================
                function TUgyfelinput.UgyfelszamLepteto: integer;
// =============================================================================

begin
  _pcs := 'SELECT * FROM UTOLSOBLOKKOK';
  tempDbase.Connected := true;
  with TempQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      result := FieldByName('UTOLSOUGYFELSZAM').asInteger;
      Close;
    end;
  Tempdbase.close;
  inc(result);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOUGYFELSZAM='+inttostr(result);
  ValutaParancs(_pcs);
end;



procedure TUgyfelinput.VtempNullazo;

begin
  _pcs := 'UPDATE VTEMP SET UGYFELTIPUS='+chr(39)+chr(39)+',UGYFELSZAM=0';
  _pcs := _pcs + ',GONGYOLT=0,SORSZAM=0,NEVTABLA='+chr(39)+chr(39);
  _pcs := _pcs + ',FORRAS='+chr(39)+chr(39)+',ENGEDELYEZO='+chr(39)+chr(39);
  _pcs := _pcs + ',PLOMBASZAM='+chr(39)+chr(39)+',KULFOLDI=0';
  _pcs := _pcs + ',MEGBIZOSZAM=0';
  ValutaParancs(_pcs);
end;


// =============================================================================
            procedure TUgyfelinput.TOVAGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  NoInternetPanel.visible := False;
  Kilep.Enabled := True;
end;

// =============================================================================
                procedure TUgyfelinput.ValutaTempCtrl;
// =============================================================================

begin
  ValutaDbase.connected := true;
  If valutatranz.InTransaction then valutatranz.commit;
  valutatranz.StartTransaction;
  with valutaQuery do
    begin
      Close;
      Sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _recno := recno;
     end;

  if _recno=0 then
    begin
      _pcs := 'INSERT INTO VTEMP (SECURLEVEL)' + _sorveg;
      _pcs := _pcs + 'VALUES (' +inttostr(_securlevel)+ ')';
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
    end;

  ValutaTranz.commit;
  Valutadbase.close;
end;

procedure TUgyfelinput.TILTOGOMBClick(Sender: TObject);
begin
  Modalresult := -1;
end;

procedure TUgyfelinput.IGENGOMBClick(Sender: TObject);
begin
  Kisugyfelgombclick(Nil);
end;

procedure TUgyfelinput.NEMGOMBClick(Sender: TObject);
begin
  _mResult := 2;
  Kilep.Enabled := true;
end;

procedure TUgyfelinput.TEAOREDITDblClick(Sender: TObject);
begin
  GetTeaorszam;
end;
procedure TUgyfelinput.TEAOREDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  GetTeaorszam;
end;

procedure TUgyfelinput.getTeaorszam;

begin
  _nTeaor := TeaorValasztas;
  if _nTeaor>0 then _jTeaor := inttostr(_nTeaor);
  Teaoredit.text := _jteaor;
  _teaornev := getTeaornev(_jteaor);
  Teaornevedit.Text := _teaornev;
end;


function TUGyfelinput.Getteaornev(_ts: string): string;

begin
  _pcs := 'SELECT * FROM TEAORTABLA WHERE TEAOR='+CHR(39)+_TS+CHR(39);
  teaordbase.connected := true;
  with TeaorQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then result := trim(Teaorquery.fieldByNAme('TEAORNEV').asString)
  else result := '?';

  teaorquery.close;
  teaordbase.close;
  Activecontrol := Okiratedit;
end;  

end.
