unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, StrUtils,
  Dialogs, StdCtrls, Buttons, ExtCtrls, jpeg, DB, DBTables, Grids, DBGrids,DateUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, Calendar,printers;

type
  TWesternUnionForm = class(TForm)

   KerdoMondat         : TLabel;
   Label1              : TLabel;
   Label2              : TLabel;
   Label3              : TLabel;
   Label4              : TLabel;
   Label5              : TLabel;
   Label6              : TLabel;
   Label7              : TLabel;
   Label8              : TLabel;
   Label9              : TLabel;
   Label10             : TLabel;
   Label11             : TLabel;
   Label12             : TLabel;
   Label13             : TLabel;
   Label14             : TLabel;
   Label15             : TLabel;
   Label16             : TLabel;
   Label17             : TLabel;
   Label18             : TLabel;
   Label19             : TLabel;
   Label20             : TLabel;
   Label21             : TLabel;
   Label22             : TLabel;
   Label23             : TLabel;
   Label25             : TLabel;
   Label28             : TLabel;
   StBizLabel          : TLabel;

   BizonylatszamPanel  : TPanel;
   DatumPanel          : TPanel;
   DnemPanel           : TPanel;
   DnemTakaroPanel     : TPanel;
   DsoftPanel          : TPanel;
   EloHoPanel          : TPanel;
   Evhopanel           : TPanel;
   ExclusiveCashPanel  : TPanel;
   HeadlinePanel       : TPanel;
   HufKeszletPanel     : TPanel;
   HufPanel            : TPanel;
   ICAtvetGomb         : TPanel;
   ICAtadGomb          : TPanel;
   InfoPanel           : TPanel;
   IranyPanel          : TPanel;
   KovHoPanel          : TPanel;
   MTCNPanelTakaro     : TPanel;
   MunkaPanel          : TPanel;
   NapValasztoPanel    : TPanel;
   OsszegPanel         : TPanel;
   Panel1              : TPanel;
   Panel2              : TPanel;
   Panel3              : TPanel;
   Panel4              : TPanel;
   Panel10             : TPanel;
   Panel13             : TPanel;
   Panel17             : TPanel;
   Panel18             : TPanel;
   Panel19             : TPanel;
   Panel20             : TPanel;
   Panel22             : TPanel;
   Panel24             : TPanel;
   PenzAtvetGomb       : TPanel;
   PenzAtadGomb        : TPanel;
   PenzKepPanel        : TPanel;
   PenzSzallitoPanel   : TPanel;
   PenztarValasztoPanel: TPanel;
   StornoPanel         : TPanel;
   SureStornoPanel     : TPanel;
   TranzDnemPanel      : TPanel;
   TranzOsszegPanel    : TPanel;
   TranzTipusPanel     : TPanel;
   UgyfelValasztoPanel : TPanel;
   UjPenztarPanel      : TPanel;
   UjUgyfelPanel       : TPanel;
   UsdKeszletPanel     : TPanel;
   UsdPanel            : TPanel;
   WuAtvetGomb         : TPanel;
   WuAtadGomb          : TPanel;

   PenzTarQuery        : TIBQuery;
   PenzTarDbase        : TIBDatabase;
   PenzTarTranz        : TIBTransaction;
   PenzTarSource       : TDataSource;

   UgyfelQuery         : TIBQuery;
   UgyfelDbase         : TIBDatabase;
   UgyfelTranz         : TIBTransaction;

   ValutaQuery         : TIBQuery;
   ValutaDbase         : TIBDatabase;
   ValutaTranz         : TIBTransaction;

   WumozgasTabla       : TIBTable;
   WumozgasQuery       : TIBQuery;
   WumozgasTranz       : TIBTransaction;
   WumozgasDbase       : TIBDatabase;
   WumozgasSource      : TDataSource;

   KezFotoImage        : TImage;
   LogoImage           : TImage;

   Naptar              : TCalendar;

   AnyjaEdit           : TEdit;
   AzonositoEdit       : TEdit;
   DnemHideEdit        : TEdit;
   LakcimEdit          : TEdit;
   MTCNPanel           : TEdit;
   NevEdit             : TEdit;
   OkmanyTipusEdit     : TEdit;
   OsszegHideEdit      : TEdit;
   PartnerFoNevEdit    : TEdit;
   PartnerNevEdit      : TEdit;
   PlombaSzamEdit      : TEdit;
   PtarKeresoEdit      : TEdit;
   SzallitoEdit        : TEdit;
   SzulidoEdit         : TEdit;
   SzulhelyEdit        : TEdit;
   UgyfelKeresoEdit    : TEdit;
   UJPenztarEdit       : TEdit;

   HufShape            : TShape;
   KepShape            : TShape;
   Shape1              : TShape;
   Shape2              : TShape;
   Shape3              : TShape;
   Shape4              : TShape;
   Shape5              : TShape;
   Shape12             : TShape;
   Shape13             : TShape;
   UsdShape            : TShape;

   BitBtn1             : TBitBtn;
   MegsemGomb          : TBitBtn;
   NincsRendbenGomb    : TBitBtn;
   PszOkeGomb          : TBitBtn;
   PszMegsemGomb       : TBitBtn;
   RendbenGomb         : TBitBtn;
   RePrintGomb         : TBitBtn;
   StornoGomb          : TBitBtn;
   StornozdleGomb      : TBitBtn;
   StornoMegsemGomb    : TBitBtn;
   UjPenztarOkeGomb    : TBitBtn;
   UjPenztarMegsemGomb : TBitBtn;
   UjUgyfelGomb        : TBitBtn;
   UjUgyfelMegsemGomb  : TBitBtn;
   UjUgyfelOkeGomb     : TBitBtn;

   BizonylatRacs       : TDBGrid;
   PenztarRacs         : TDBGrid;
   UgyfelRacs          : TDBGrid;

   CsakEgyNap          : TRadioButton;
   TeljesHonap         : TRadioButton;

   Image1              : TImage;
   Image2              : TImage;
   Image3              : TImage;
    LISTAGOMB: TBitBtn;
    LISTASTARTPANEL: TPanel;
    TOLNAPTAR: TCalendar;
    IGNAPTAR: TCalendar;
    Label24: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    TOLPANEL: TPanel;
    IGPANEL: TPanel;
    TOLELOHOGOMB: TBitBtn;
    TOLKOVHOGOMB: TBitBtn;
    LISTADATUMOKEGOMB: TBitBtn;
    Shape6: TShape;
    LISTAMEGSEMGOMB: TBitBtn;
    IGELOHOGOMB: TBitBtn;
    IGKOVHOGOMB: TBitBtn;
    KESZLETPRINTGOMB: TBitBtn;
    szemadatgomb: TBitBtn;
    szemadatpanel: TPanel;
    Label29: TLabel;
    XNEVEDIT: TEdit;
    XANYJAEDIT: TEdit;
    XSZULHELYEDIT: TEdit;
    XSZULIDOEDIT: TEdit;
    XOKMANYTIPUSEDIT: TEdit;
    XAZONOSITOEDIT: TEdit;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    visszagomb: TBitBtn;
    Shape7: TShape;
    XLAKCIMEDIT: TEdit;
    ESCAPEGOMB: TBitBtn;
    UGYFELSOURCE: TDataSource;
    tacepao: TPanel;
    Image4: TImage;
    FIGYELEMPANEL: TPanel;
    SCANPANEL: TPanel;
    Label37: TLabel;
    SCANOKEGOMB: TBitBtn;
    RETRYGOMB: TBitBtn;
    CANCELGOMB: TBitBtn;
    Shape8: TShape;
    OKMANYGOMB: TBitBtn;
    TEMPQUERY: TIBQuery;
    TEMPDBASE: TIBDatabase;
    TEMPTRANZ: TIBTransaction;


// ------------------------------------------------------------

    procedure BitBtn1Click(Sender: TObject);
    procedure BizonylatRacsCellClick(Column: TColumn);
    procedure BizonylatRacsDblClick(Sender: TObject);
    procedure Bizregiszter(_xbiz: string);
    procedure BizonylatRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Blokkfocimiro;
    procedure CsakEgynapClick(Sender: TObject);
    procedure DnemHideEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EloHoPanelClick(Sender: TObject);
    procedure Evhodisplay;
    procedure FormActivate(Sender: TObject);
    procedure GetAktualkeszlet;
    procedure GetHardware;
    procedure HufPanelClick(Sender: TObject);
    procedure HufPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ICAtvetGombEnter(Sender: TObject);
    procedure ICAtvetGombExit(Sender: TObject);
    procedure ICAtvetGombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ICnyugta;
    procedure KeszletDisplay;
    procedure KilepesGombClick(Sender: TObject);
    procedure KovHoPanelClick(Sender: TObject);
    procedure KozepreIr(_szoveg: string);
    procedure MaiNapDisplay;
    procedure MegsemGombClick(Sender: TObject);
    procedure MTCNPanelEnter(Sender: TObject);
    procedure MTCNPanelExit(Sender: TObject);
    procedure MTCNPanelKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NaptarChange(Sender: TObject);
    procedure NapValasztoPanelClick(Sender: TObject);
    procedure NevEditEnter(Sender: TObject);
    procedure NevEditExit(Sender: TObject);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NyugtaLablec;
    procedure OsszegHideEditEnter(Sender: TObject);
    procedure OsszegHideEditExit(Sender: TObject);
    procedure OsszegHideEditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PenzAtvetGombClick(Sender: TObject);
    procedure PenztarRacsDblClick(Sender: TObject);
    procedure PenztarRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PenztartValasztott;
    procedure PenzkeszletList(Sender: TObject);
    procedure PlombaszamEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PszMegsemGombClick(Sender: TObject);
    procedure PszOkeGombClick(Sender: TObject);
    procedure RegebbiNapDisplay;
    procedure RekordBeolvasas;
    procedure RekordValtozott;
    procedure RendbenGombClick(Sender: TObject);
    procedure RendbenGombEnter(Sender: TObject);
    procedure RePrintGombClick(Sender: TObject);
    PROCEDURE sCANNELES;
    procedure StartNyomtatas;
    procedure StornoGombClick(Sender: TObject);
    procedure StornoMegsemGombClick(Sender: TObject);
    procedure StornozdLeGombClick(Sender: TObject);
    procedure SzallitoEditEnter(Sender: TObject);
    procedure SzallitoEditExit(Sender: TObject);
    procedure SzallitoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TeljesHonapClick(Sender: TObject);
    procedure TranzKonyveles;
    procedure TranzOsszegPanelClick(Sender: TObject);
    procedure TranztipusKijelzes;
    procedure UgyfeletValasztott;
    procedure Ugyfelparancs(_ukaz: string);
    procedure UgyfelRacsDblClick(Sender: TObject);
    procedure UgyfelRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UgyfNyugta;
    procedure UjPenztarEditEnter(Sender: TObject);
    procedure UjPenztarEditExit(Sender: TObject);
    procedure UjPenztarEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UjPenztarMegsemGombClick(Sender: TObject);
    procedure UjPenztarOkeGombClick(Sender: TObject);
    procedure UjUgyfelGombClick(Sender: TObject);
    procedure UjUgyfelOkeGombClick(Sender: TObject);
    procedure UsdPanelClick(Sender: TObject);
    procedure UsdPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Valutaparancs(_ukaz: string);
    procedure VonalHuzo;
    procedure WuAtvetGombClick(Sender: TObject);
    procedure WuBizonylatPrint;
    procedure WuKeszletRegen(_sum: integer;_dev,_ejel: string);
    procedure Wunyugta;
    procedure WuRekordrogzites;
    procedure AskScanAllright;


// -----------------------------------------------------------------------

    function ForintForm(_int: integer): string;
    function Getbizonylatszam: string;
    function GetIdos: string;
    function GetPenztarNev(_ptnum: integer): string;
    function GetUgyfelnev(_ugyfnum: integer): string;
    function GetUsdarfolyam: integer;
    function HunDatetostr(_calDat: TDateTime): string;
    function Nul6(_int: integer): string;
    function Nulele(_i: integer): string;
    function VanennyiPenzunk(_dev: string; _bjegy: integer):boolean;
    procedure LISTAGOMBClick(Sender: TObject);
    procedure TOLNAPTARChange(Sender: TObject);
    procedure IGNAPTARChange(Sender: TObject);
    procedure TOLELOHOGOMBClick(Sender: TObject);
    procedure TOLKOVHOGOMBClick(Sender: TObject);
    procedure LISTAMEGSEMGOMBClick(Sender: TObject);
    procedure LISTADATUMOKEGOMBClick(Sender: TObject);
    procedure ListaNyomtatas;
    function Elokieg(_s:string;_h: byte):string;
    function kerekito(_int: integer): integer;
    procedure IGELOHOGOMBClick(Sender: TObject);
    procedure IGKOVHOGOMBClick(Sender: TObject);
    procedure szemadatgombClick(Sender: TObject);
    procedure visszagombClick(Sender: TObject);
    procedure XLAKCIMEDITChange(Sender: TObject);
    procedure XLAKCIMEDITEnter(Sender: TObject);
    procedure XLAKCIMEDITExit(Sender: TObject);
    procedure UJUGYFELMEGSEMGOMBClick(Sender: TObject);
    procedure BIZONYLATRACSEnter(Sender: TObject);
    procedure BIZONYLATRACSExit(Sender: TObject);
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    procedure SCANOKEGOMBClick(Sender: TObject);
    procedure RETRYGOMBClick(Sender: TObject);
    procedure CANCELGOMBClick(Sender: TObject);
    procedure OKMANYGOMBClick(Sender: TObject);
    procedure Tempparancs(_ukaz: string);

// -----------------------------------------------------------------------

  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  WesternUnionForm: TWesternUnionForm;

  _honev: array[1..12] of string = ('január','február','március','április','május',
                 'június','július','augusztus','szeptember','október',
                 'november','december');

  _ujUgyfelEdit: array[1..7] of TEdit;
  _elojelsor   : array[1..7] of string = ('+','-','+','-','+','-','+');

  _inic   : string = #27#64;
  _LF5    : string = #27#97#5;
  _sorveg : string = chr(13)+chr(10);
  _widoff : string = #20;
  _widon  : string = #14;

  _csakegynap,
  _foegyseg,
  _gepfunkcio,
  _printer,
  _storno,
  _tag: byte;

  _height,
  _igev,
  _igho,
  _ignap,
  _kertev,
  _kertho,
  _kertnap,
  _tolev,
  _tolho,
  _tolnap,
  _width: word;

  
  _aktugyfelszam,
  _bill,
  _cegszam,
  _code,
  _homepenztarszam,
  _lastnum,
  _menupont,
  _aktpenztarszam,
  _recno,
  _s,
  _stosszeg,
  _usdarfolyam,
  _whufkeszlet,
  _wuosszeg,
  _wusdkeszlet: integer;

  _aktdnem,
  _aktelojel,
  _aktido,
  _aktidos,
  _aktpenztarnev,
  _aktugyfelnev,
  _anyjaneve,
  _azonosito,
  _bizonylat,
  _cegnev,
  _cegadoszam,
  _dirs,
  _farok,
  _homePenztarKod,
  _homePenztarNev,
  _homePenztarCim,
  _homePenztarTelefon,
  _idkod,
  _igdatum,
  _keres,
  _lakcim,
  _lfarok,
  _mamas,
  _minta,
  _mtcnszam,
  _okmanytipus,
  _partnernev,
  _pcs,
  _penztarosnev,
  _plombaszam,
  _stornozottbizonylat,
  _stornobizonylat,
  _szallitonev,
  _szulhely,
  _szulido,
  _tablanev,
  _tipus,
  _toldatum,
  _tranzakcio,
  _ugyfeltipus,
  _ujpenztarnev,
  _utfarok,
  _wudatum: string;
 

  _kertDatum: TDateTime;

  _datavaltozott,
  _ezcopy,
  _ezmainap,
  _menuActive,
  _maystorno: boolean;

  _LFile: textFile;
  _igdat,
  _toldat: TDateTime;

  _xnev,_xAnyja,_xSzulhely,_xSzulido,_xLakcim: string;
  _xOkmTipus,_xAzonosito: string;
  _xUgyfelszam: integer;

  _pacs: pchar;
  _srec: TSearchrec;


function docdisprutin: integer; stdcall; external 'c:\valuta\bin\docdisp.dll' name 'docdisprutin';  
function supervisorjelszo(_para: integer): integer; stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function westernunionrutin: integer; stdcall;



implementation

{$R *.dfm}


// =============================================================================
                function westernunionrutin: integer; stdcall;
// =============================================================================

begin
  WesternUnionForm := TWesternUnionForm.create(Nil);
  result := WesternUnionForm.Showmodal;
  WesternUnionForm.Free;
end;


// =============================================================================
          procedure TWesternUnionForm.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  Top := trunc((_height-768)/2);
  Left := trunc((_width-1024)/2);

  Width  := 1024;
  Height := 768;

  with TacePao do
    begin
      Top := 320;
      Left := 384;
      Visible := True;
      Repaint;
    end;

  _mamas := Hundatetostr(date);
  _wudatum := _mamas;

  _ujugyfeledit[1] := NevEdit;
  _ujugyfeledit[2] := AnyjaEdit;
  _ujugyfeledit[3] := SzulhelyEdit;
  _ujugyfeledit[4] := SzulidoEdit;
  _ujugyfeledit[5] := LakcimEdit;
  _ujugyfeledit[6] := OkmanytipusEdit;
  _ujugyfeledit[7] := AzonositoEdit;

  PenztarValasztoPanel.Visible := false;
  UgyfelValasztoPanel.visible := False;
  SzemadatPanel.Visible := False;

  _ezMaiNap := False;
  _ezCopy := False;

  DsoftPanel.Visible := false;
  MunkaPanel.Visible := false;
  PenzKeppanel.Visible := false;
  Penzszallitopanel.Visible := false;
  exclusiveCashPanel.Visible := False;
  MTCNPanelTakaro.Visible := False;
  ListaStartPanel.visible := False;

  Partnernevedit.Text := '';
  BizonylatszamPanel.Caption := '';
  DatumPanel.caption := '';
  OsszegPanel.Caption := '';
  DnemPanel.Caption := '';
  SureStornoPanel.Visible := False;

  _csakegynap := 1;
  _menuActive := true;

  Napvalasztopanel.Enabled := true;
  NapvalasztoPanel.Font.color := clBlack;

  _usdarfolyam := GetUsdArfolyam;

  _utFarok := '';

  KeszletDisplay;
  Naptar.CalendarDate := Date;

  GethardWare;
  if (_gepfunkcio<>2) AND (_homepenztarszam<151) then
    begin
      IcAtvetGomb.Enabled:= false;
      IcAtadGomb.Enabled := False;
    end;

  WumozgasDbase.close;
  with InfoPanel do
    begin
      Top  := 320;
      Left := 384;
      Visible := True;
    end;
  NapvalasztoPanelClick(Nil);
end;

// =============================================================================
       procedure TWesternUnionForm.NapValasztoPanelClick(Sender: TObject);
// =============================================================================

begin
  NapvalasztoPanel.Enabled := False;
  NapvalasztoPanel.Font.Color := clGray;
  _kertdatum := Naptar.CalendarDate;

  evhodisplay;

  _kertNap := dayof(_kertdatum);
  _wudatum := hundatetostr(_kertdatum);

  if _kertDatum=date then
    begin
      _ezmainap := True;
      _maystorno := true;
      StornoGomb.Enabled := true;
      MainapDisplay;
      exit;
    end;
  _ezmainap := False;
  _mayStorno := false;
  stornoGomb.Enabled := false;
  RegebbiNapDisplay;
end;


// =============================================================================
                  procedure TWesternUnionForm.Gethardware;
// =============================================================================

begin
  _pcs := 'SELECT * FROM HARDWARE';

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _gepfunkcio := FieldByName('GEPFUNKCIO').asInteger;
      _penztarosnev := trim(FieldByName('PENZTAROSNEV').asstring);
      _idkod := trim(FieldByName('IDKOD').asString);
      _printer := FieldByName('PRINTER').asInteger;
      close;
    end;

  _pcs := 'SELECT * FROM PENZTAR';
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _homePenztarNev  := trim(FieldByName('PENZTARNEV').asstring);
      _homePenztarKod  := trim(FieldByName('PENZTARKOD').asString);
      _homePenztarCim  := trim(FieldByName('PENZTARCIM').asString);
      _homePenztarTelefon := trim(FieldBynAme('TELEFONSZAM').AsString);
      close;
    end;
  Valutadbase.close;

  val(_homepenztarkod,_homepenztarszam,_code);
  if _homepenztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
      _cegadoszam := '32313332-2-02';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
      _cegadoszam := '14040535-2-02';
    END;

  GetAktualKeszlet;
end;


// =============================================================================
                 procedure TWesternUnionForm.MaiNapDisplay;
// =============================================================================

begin
  Csakegynap.Checked := true;

  Wumozgasquery.close;
  WuMozgasDbase.close;
  WuMozgasDbase.DatabaseName := 'c:\valuta\database\valuta.fdb';
  WuMozgasDbase.connected := True;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM WUMOZGAS';
  with wumozgasQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;
  BizonylatRacs.SetFocus;
  RekordValtozott;
end;


// =============================================================================
                 procedure TWesternUnionForm.RekordValtozott;
// =============================================================================

begin

  RekordBeolvasas;

  if _foegyseg=1 then _partnerNev := 'Exclusive Cash';
  if _foegyseg=2 then _partnerNev := GetPenztarnev(_aktpenztarszam);
  if _foegyseg=5 then _partnerNev := GetUgyfelnev(_aktugyfelszam);

  TranztipusKijelzes;

  PartnerNevedit.text := _partnernev;
  BizonylatszamPanel.Caption := _bizonylat;
  Datumpanel.caption := _wuDatum;
  OsszegPanel.caption := forintform(_wuosszeg);
  DnemPanel.caption := _aktdnem;

  Stornopanel.caption := '';
  if _storno=2 then StornoPanel.caption := 'STORNOZOTT BIZONYLAT';
  if _storno=3 then StornoPanel.caption := 'STORNO BIZONYLAT';
  if _storno>1 then Stornogomb.Enabled := False
  else if _maystorno then StornoGomb.Enabled := True;

  Okmanygomb.Enabled := false;
  if _foegyseg=5 then
    begin
      _dirs := 'W' + inttostr(_aktugyfelszam);
      _minta := 'c:\valuta\scans\' + _dirs + '\*.jpg';
      if FindFirst(_minta,faAnyFile,_srec) = 0 then Okmanygomb.Enabled := true;
      FindClose(_srec);
    end;
end;

procedure TwesternUnionForm.RekordBeolvasas;

begin
   with WumozgasQuery do
    begin
      _wudatum    := FieldByNAme('DATUM').asString;
      _aktido      := FieldByNAme('IDO').asstring;
      _aktugyfelszam := FieldByName('UGYFELSZAM').asInteger;
      _ugyfeltipus  := FieldByName('UGYFELTIPUS').asString;
      _bizonylat   := FieldByNAme('SORSZAM').asString;
      _aktdnem     := FieldByName('VALUTANEM').asstring;
      _wuosszeg    := FieldByName('BANKJEGY').asInteger;
      _tranzakcio  := trim(FieldByNAme('TRANZAKCIOTIPUS').asString);
      _mtcnszam    := trim(FieldByNAme('MTCNSZAM').asString);
      _storno      := FieldByName('STORNO').asInteger;
      _foegyseg    := FieldByNAme('FOEGYSEGSZAM').asInteger;
      _aktpenztarszam := FieldByName('PENZTARSZAM').asInteger;
    end;
end;


// =============================================================================
              procedure TWesternUnionForm.TranztipusKijelzes;
// =============================================================================

var _tranztipusNev: string;

begin
  if (_foegyseg=1) then
    begin
      if _tranzakcio='+B' then _tranztipusnev := 'Ellátmány átvétele Exlusive Cashtõl'
      else _tranztipusnev := 'Ellátmány átadása Exclusive Cashnek';
    end;

  if (_foegyseg=2) then
    begin
      if _tranzakcio='+B' then _tranztipusnev := 'Ellátmány átvétele Western Uniontól'
      else _tranztipusnev := 'Ellátmány átadása Western Unionnak';
    end;

  if (_foegyseg=5) then
    begin
      if _tranzakcio='+B' then _tranztipusnev := 'Pénzátvétel egy ügyféltõl'
      else _tranztipusnev := 'Pénzátadás egy ügyfélnek';
    end;
  TranztipusPanel.caption := _tranztipusnev;
end;


// =============================================================================
       function TWesternUnionForm.GetPenztarNev(_ptnum: integer): string;
// =============================================================================

begin
  result := '';
  _pcs := 'SELECT * FROM WUAFACEGEK' + _sorveg;
  _pcs := _pcs + 'WHERE CEGSZAM=' + Inttostr(_ptnum);

  PenztarDbase.connected := True;
  with PenztarQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then result := trim(PenztarQuery.FieldByNAme('CEGNEV').asString);
  PenztarQuery.close;
  PenztarDbase.close;
end;


// =============================================================================
        function TWesternUnionForm.GetUgyfelnev(_ugyfnum: integer): string;
// =============================================================================

begin
  result := '';

  _pcs := 'SELECT * FROM WUGYFEL' + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_ugyfnum);

  Ugyfeldbase.connected := True;
  with UgyfelQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno>0 then result := trim(Ugyfelquery.FieldByNAme('NEV').asString);

  UgyfelQuery.close;
  UgyfelDbase.close;
end;


// =============================================================================
        function TWesternUnionForm.ForintForm(_int: integer): string;
// =============================================================================

var _elojel: integer;
    _wlen,_f1: byte;

begin
  _elojel := 0;
  if _int<0 then
    begin
      _elojel := -1;
      _int := abs(_int);
    end;

  result := inttostr(_int);
  if _int=0 then exit;

  _wLen := length(result);
  if _wlen>6 then
    begin
      _f1 := _wlen-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      if _elojel<0 then result := '-'+result;
      exit;
    end;

  if _wlen>3 then
    begin
      _f1 := _wlen-3;
      result := leftstr(result,_f1)+ ' ' + midstr(result,_f1+1,3);
    end;
  if _elojel<0 then result := '-' + result;
end;


// =============================================================================
                     procedure TwesternUnionForm.Keszletdisplay;
// =============================================================================

begin
  GetaktualKeszlet;
  UsdKeszletPanel.Caption := ForintForm(_wusdKeszlet);
  HufKeszletPanel.Caption := ForintForm(_whufKeszlet);

  UsdKeszletPanel.Repaint;
  HufKeszletPanel.Repaint;
end;


// =============================================================================
                 procedure TWesternUnionForm.GetAktualkeszlet;
// =============================================================================

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;

      Sql.Clear;
      Sql.Add('SELECT * FROM WUAFAADATOK');
      Open;

      _wusdkeszlet := FieldByName('WUDOLLARKESZLET').asInteger;
      _whufKeszlet := FieldByName('WUFORINTKESZLET').asInteger;

      close;
    end;
  Valutadbase.close;
end;


// =============================================================================
                 procedure TWesternUnionForm.RegebbinapDisplay;
// =============================================================================

begin
  _farok := inttostr(_kertev-2000)+nulele(_kertho);

  WumozgasDbase.close;
  WumozgasTabla.close;
  wumozgasQuery.close;

  _tablanev := 'WUNI'+_farok;
  wumozgasTabla.TableName := _tablanev;

  wumozgasDbase.databasename := 'c:\valuta\database\valdata.fdb';
  wumozgasDbase.connected := true;

  if not WumozgasTabla.exists then
    begin
      WumozgasDbase.close;
      ShowMessage('A KÉRT HÓNAPRÓL NINCSENEK ADATAIM');
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _tablanev;
  if _csakegynap=1 then _pcs := _pcs +_SORVEG + 'WHERE DATUM=' +chr(39)+_wudatum+chr(39);

  with WUmozgasQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  RekordValtozott;
  Bizonylatracs.SetFocus;

end;

// =============================================================================
          function TWesternUnionForm.Nulele(_i: integer): string;
// =============================================================================

begin
  result := inttostr(_i);
  if _i<10 then result := '0' + result;
end;


// =============================================================================
         procedure TWesternUnionForm.KilepesGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;



// =============================================================================
       procedure TWesternUnionForm.BizonylatRacsCellClick(Column: TColumn);
// =============================================================================

begin
  RekordValtozott;
end;

// =============================================================================
        procedure TWESTERNUNIONFORM.BIZONYLATRACSDblClick(Sender: TObject);
// =============================================================================

begin
  RekordValtozott;
end;


// =============================================================================
         procedure TWESTERNUNIONFORM.BIZONYLATRACSKeyUp(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

var  _bill : integer;
begin
  _bill:= ord(key);
  if (_bill>32) AND (_bill<41) then
    begin
      Rekordvaltozott;
      exit;
    end;
end;

// =============================================================================
          procedure TWESTERNUNIONFORM.ELOHOPANELClick(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
  Evhodisplay;
end;

// =============================================================================
           procedure TWESTERNUNIONFORM.KOVHOPANELClick(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
  Evhodisplay;
end;

// =============================================================================
                     procedure TWesternUnionForm.EvhoDisplay;
// =============================================================================

var _evhos: string;

begin
  _kertev := naptar.year;
  _kertho := naptar.month;
  _evhos := inttostr(_kertev)+' '+_honev[_kertho];

  EvHoPanel.caption := _evhos;
  EvHoPanel.Repaint;
end;

// =============================================================================
         procedure TWesternUnionForm.TeljesHonapClick(Sender: TObject);
// =============================================================================

begin
  _csakegynap := 0;
  _maystorno := False;
  StornoGomb.Enabled := False;
  NapvalasztoPanel.Enabled := true;
  NapvalasztoPanelClick(Nil);
end;

// =============================================================================
           procedure TWESTERNUNIONFORM.CSAKEGYNAPClick(Sender: TObject);
// =============================================================================
begin
  _csakegynap := 1;
  NapvalasztoPanel.Enabled := true;
  NapvalasztoPanelclick(Nil);
end;

// =============================================================================
       procedure TWESTERNUNIONFORM.ICATVETGOMBMouseMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================
begin
  if not _MenuActive then exit;
  ActiveControl := TPanel(sender);
end;

// =============================================================================
       procedure TWESTERNUNIONFORM.ICATVETGOMBEnter(Sender: TObject);
// =============================================================================

var _headline: string;

begin
  TPanel(sender).Font.Color := clWhite;
  _headline := TPanel(sender).caption;
  HeadlinePanel.Caption := _headline;
end;

// =============================================================================
         procedure TWESTERNUNIONFORM.ICATVETGOMBExit(Sender: TObject);
// =============================================================================

begin
  TPanel(sender).font.color := clSilver;
end;


// =============================================================================
           procedure TWESTERNUNIONFORM.WUATVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  Tacepao.Visible := False;

  _menupont := TPanel(Sender).Tag;
  _menuactive := False;
  Megsemgomb.Enabled := True;

  _aktugyfelszam := 0;

  if (_menupont=1) or (_menupont=3) then Iranypanel.Caption := 'ÁTVETT ÖSSZEG'
  else Iranypanel.caption := 'ÁTADOTT OSSZEG';

  if _menupont<3 then
    begin
      with ExclusiveCashPanel do
        begin
          Top := 48;
          Left := 384;
          Visible := True;
        end;

      _aktpenztarNev := 'Exclusive Cash';
      _aktpenztarszam := 0;
      PenztartValasztott;
      Exit;
    end;

  _keres := '';
  PtarKeresoedit.clear;
  Infopanel.Visible := false;

  _pcs := 'SELECT * FROM WUAFACEGEK' + _sorveg;
  _pcs := _pcs + 'ORDER BY CEGNEV';

  Penztardbase.Connected := true;
  with PenztarQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  with DsoftPanel do
    begin
      Top := 320;
      Left :=  843;
      Visible := True;
    end;

  UjpenztarPanel.Visible := false;
  with PenztarValasztoPanel do
    begin
      top := 48;
      Left := 384;
      Visible := true;
    end;
  ActiveControl := PenztarRacs;
  PenztarRacs.SetFocus;
end;


// =============================================================================
         procedure TWESTERNUNIONFORM.megsemgombClick(Sender: TObject);
// =============================================================================

begin
  MegsemGomb.Enabled   := False;
  PenzKepPanel.Visible := False;
  Munkapanel.Visible   := False;
  PenzSzallitoPanel.Visible := False;

  ExclusivecashPanel.Visible := False;

  PenztarQuery.close;
  Penztardbase.close;

  UgyfelQuery.Close;
  UgyfelDbase.close;
  DsoftPanel.Visible := False;

  PenztarValasztoPanel.visible := False;
  UgyfelValasztoPanel.visible := false;
  _menuActive := True;

  NapvalasztoPanel.Enabled := true;
  NapValasztoPanelClick(Nil);

  InfoPanel.Visible := true;
  BizonylatRacs.SetFocus;
end;

// =============================================================================
         procedure TWESTERNUNIONFORM.PENZTARRACSDblClick(Sender: TObject);
// =============================================================================

begin
  _aktpenztarnev  := trim(Penztarquery.fieldbyname('CEGNEV').AsString);
  _aktpenztarszam := PenztarQuery.FieldByName('CEGSZAM').asInteger;

  PenztarQuery.close;
  Penztardbase.close;

  PenztartValasztott;
end;


// =============================================================================
       procedure TWESTERNUNIONFORM.PENZTARRACSKeyDown(Sender: TObject;
                                         var Key: Word; Shift: TShiftState);
// =============================================================================

var _bill: integer;
    _ujchar,_ujkeres: string;
    _megvan: boolean;
    _wlen: byte;

begin
  _bill := ord(key);
  if _bill=13 then
    begin
      _aktpenztarnev  := trim(Penztarquery.fieldbyname('CEGNEV').AsString);
      _aktpenztarszam := PenztarQuery.FieldByName('CEGSZAM').asInteger;

      PenztarQuery.close;
      Penztardbase.close;

      PenztartValasztott;
      exit;
    end;

  if (_bill>32) and (_bill<41) then
    begin
      PtarkeresoEdit.Clear;
      _keres := '';
      exit;
    end;

  if _bill>64 then
    begin
      _ujchar := uppercase(chr(_bill));
      _ujkeres := _keres + _ujchar;
      _megvan := PenztarQuery.locate('CEGNEV',_ujkeres,[loPartialKey]);
      if _megvan then
        begin
          _keres := _ujkeres;
          Ptarkeresoedit.Text := _keres;
        end else PenztarQuery.Locate('CEGNEV',_keres,[loPartialkey]);
      exit;
    end;

  if _bill=8 then
    begin
      if _keres='' then exit;
      _wlen := length(_keres);
      if _wlen=1 then
        begin
          _keres := '';
          PtarKeresoedit.clear;
          exit;
        end;
      _keres := leftstr(_keres,_wlen-1);
      PenztarQuery.Locate('CEGNEV',_keres,[loPartialKey]);
    end;
end;


// =============================================================================
              procedure TWesternUnionForm.PenztartValasztott;
// =============================================================================

begin
  PenztarvalasztoPanel.Visible := False;
  with PenzkepPanel do
    begin
      Top := 48;
      Left := 384;
      Visible := true;
    end;

  PartnerFoNevedit.Text := _aktpenztarnev;
  KerdoMondat.Visible := false;
  TranzosszegPanel.Caption := '';
  TranzDnempanel.Caption := '';
  MtcnPanel.Text := '';
 
  if _menuPont<5 then
    begin
      MTCNpanel.Enabled := False;
      MTcnpanel.color := $A0A0A0;
    end else
    begin
      MTCNpanel.Enabled := True;
      MTcnpanel.color   := clWhite;
    end;

  if _menuPont<5 then
    begin
      with MTCNPanelTakaro do
        begin
          Top := 224;
          Left := 48;
          Visible := True;
        end;
    end;

  UsdPanel.Color       := $B0FFFF;
  UsdShape.Brush.Color := $B0FFFF;
  UsdPanel.Font.Color  := clBlack;

  HufPanel.Color       := $A0A0A0;
  HufShape.Brush.Color := $A0A0A0;
  HufPanel.Font.Color  := clGray;

  _aktdnem := 'USD';
  Tranzdnempanel.Caption := '';

  DnemTakaropanel.Visible := False;
  with Munkapanel do
    begin
      Top  := 320;
      Left := 380;
      Visible := true;
    end;
  RendbenGomb.Enabled := False;
  ActiveControl := DnemHideedit;
end;


// =============================================================================
            procedure TWESTERNUNIONFORM.USDPANELClick(Sender: TObject);
// =============================================================================

begin
  TranzdnemPanel.Caption := 'USD';
  DnemtakaroPanel.Visible := true;

  ActiveControl := OsszegHideedit;
end;


// =============================================================================
        procedure TWESTERNUNIONFORM.USDPANELMouseMove(Sender: TObject;
                                         Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  UsdPanel.Color       := $B0FFFF;
  UsdShape.Brush.Color := $B0FFFF;
  UsdPanel.Font.Color  := clBlack;
  _aktdnem := 'USD';

  HufPanel.Color       := $A0A0A0;
  HufShape.Brush.Color := $A0A0A0;
  Hufpanel.Font.Color  := clGray;
end;


// =============================================================================
       procedure TWESTERNUNIONFORM.HUFPANELMouseMove(Sender: TObject;
                                         Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  HufPanel.Color := $b0ffff;
  HufShape.Brush.Color := $B0FFFF;
  Hufpanel.Font.Color := clBlack;

  UsdPANEL.Color := $A0A0A0;
  UsdShape.Brush.Color := $A0A0A0;
  UsdPanel.Font.Color := clGray;

  _aktdnem := 'HUF';
end;


// =============================================================================
           procedure TWESTERNUNIONFORM.HUFPANELClick(Sender: TObject);
// =============================================================================


begin
  TranzdnemPanel.Caption := 'HUF';
  DnemTakaroPanel.Visible := true;
  ActiveControl := OsszegHideedit;
end;


// =============================================================================
        procedure TWESTERNUNIONFORM.OSSZEGHIDEEDITEnter(Sender: TObject);
// =============================================================================

begin
  OsszegHideedit.clear;
  TranzOsszegPanel.color := clYellow;
end;


// =============================================================================
      procedure TWESTERNUNIONFORM.OSSZEGHIDEEDITKeyUp(Sender: TObject;
                                        var Key: Word; Shift: TShiftState);
// =============================================================================


var _hetext: string;

begin
  _bill := ord(key);
  _hetext := trim(OsszegHideEdit.Text);

  val(_hetext,_wuosszeg,_code);

  if _code<>0 then _wuosszeg := 0;
  if _wuosszeg=0 then
    begin
      OsszegHideEdit.Text   := '';
      TranzOsszegPanel.caption := '';
    end;

  if _wuosszeg>0 then TranzosszegPanel.Caption := ForintForm(_wuosszeg)
  else TranzOsszegPanel.Caption := '';

  if _bill=13 then
    begin
      if _menupont<5 then
        begin
          RendbenGomb.Enabled := True;
          Activecontrol := RendbenGomb;
        end
      else activeControl := MtcnPanel;
    end;

end;


// =============================================================================
         procedure TWESTERNUNIONFORM.RENDBENGOMBClick(Sender: TObject);
// =============================================================================


var _vtip: string;
begin
  if _wuosszeg=0 then exit;

  _aktelojel := _elojelsor[_menupont];
  if not VanennyiPenzunk(_aktdnem,_WUoSSZEG) then
    begin
      if _aktdnem='USD' then  _vtip := 'DOLLAR' else _vtip := 'FORINT';

      ShowMessage('NINCS ENNYI '+_VTIP+' KESZLETUNK');
      exit;
    end;

  RendbenGomb.Enabled := False;

  if _menupont<5 then
    begin
      ExclusiveCashPanel.Visible := False;
      Szallitoedit.clear;
      PlombaszamEdit.clear;
      with Penzszallitopanel do
        begin
          top := 48;
          Left := 384;
          Visible := true;
        end;
      ActiveControl := Szallitoedit;
      exit;
    end else

    // ---------- ugyfel atadas vagy atvetel ----------------

    TranzKonyveles;

    {
    begin
      if _aktdnem='USD' then _s := round(_usdarfolyam/100*_wuOsszeg)
      else _s := _wuosszeg;
      if _s>=300000 then
        begin
          Scanneles;
          exit;
        end;
    end;
    }

END;    

procedure TWesternUnionForm.TranzKonyveles;
begin
  WuRekordRogzites;
  WukeszletRegen(_wuOsszeg,_aktdnem,_aktelojel);
  KeszletDisplay;
  WuBizonylatPrint;
  Tacepao.Visible := True;
  MegsemGombclick(Nil);
end;


function TWesternUnionForm.GetUsdarfolyam: integer;

begin
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'USD'+chr(39);
  ValutaDbase.connected := true;
  with valutaquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      Close;
    end;
  Valutadbase.close;
end;      


// =============================================================================
               procedure TWesternUnionForm.WuRekordrogzites;
// =============================================================================

begin

  _aktIdos := GetIdos;
  _bizonylat := Getbizonylatszam;

  Bizregiszter(_bizonylat);


  _foegyseg := 5;
  if _menupont<3 then _foegyseg := 1;
  if (_menupont>2) and (_menupont<5) then _foegyseg := 2;
  if _menupont<5 then
    begin
      _ugyfeltipus := 'P';
      _mtcnSzam := '-';
    end
    else
    begin
       _ugyfelTipus := 'U';
       _partnernev := _aktugyfelnev;
    end;
  if _aktdnem='HUF' then _wuosszeg := kerekito(_wuosszeg);

  _storno := 1;

  _pcs := 'INSERT INTO WUMOZGAS (FOEGYSEGSZAM,PENZTARSZAM,UGYFELSZAM,SORSZAM,';
  _pcs := _pcs + 'DATUM,IDO,VALUTANEM,BANKJEGY,UGYFELTIPUS,PENZTAROSNEV,';
  _pcs := _pcs + 'TRANZAKCIOTIPUS,MTCNSZAM,STORNO,IDKOD)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_foegyseg)+',';
  _pcs := _pcs + inttostr(_aktpenztarszam) + ',';
  _pcs := _pcs + inttostr(_aktugyfelszam) + ',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_wuosszeg) + ',';
  _pcs := _pcs + chr(39) + _ugyfeltipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _penztarosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranzakcio + chr(39) + ',';    // -K vagy +B
  _pcs := _pcs + chr(39) + _mtcnszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_storno)+',';
  _pcs := _pcs + chr(39) + _idkod + chr(39) + ')';
  ValutaParancs(_pcs);
end;

procedure TwesternUnionForm.Bizregiszter(_xbiz: string);

var _biziro: textfile;

begin
  assignFile(_biziro,'c:\valuta\aktbizo.txt');
  rewrite(_biziro);
  write(_biziro,_xbiz);
  Closefile(_biziro);
end;


// =============================================================================
              function TWesternUnionForm.Getbizonylatszam: string;
// =============================================================================

begin
  Valutadbase.connected := true;
  with Valutaquery do
    begin
      close;
      sql.clear;
      sql.Add('SELECT * FROM WUAFAADATOK');
      Open;
    end;

  if (_menupont=1) or (_menupont=3) then
    begin
       _lastnum := Valutaquery.fieldbyname('UTOLSOWUBEBLOKK').asInteger;
       _tranzakcio := '+B';
       inc(_lastnum);
       result := 'WB-' +nul6(_lastnum);
       Valutaquery.close;
       Valutadbase.close;
       _pcs := 'UPDATE WUAFAADATOK SET UTOLSOWUBEBLOKK='+inttostr(_lastnum)+',';
       _pcs := _pcs + 'WAKTUALBIZONYLAT=' + chr(39) + result + chr(39);
       ValutaParancs(_pcs);
       exit;
     end;

   if (_menupont=2) or (_menupont=4) then
    begin
       _tranzakcio := '-K';
       _lastnum := Valutaquery.fieldbyname('UTOLSOWUKIBLOKK').asInteger;
       inc(_lastnum);
       result := 'WK-' +nul6(_lastnum);
       Valutaquery.close;
       Valutadbase.close;
       _pcs := 'UPDATE WUAFAADATOK SET UTOLSOWUKIBLOKK='+inttostr(_lastnum)+',';
       _pcs := _pcs + 'WAKTUALBIZONYLAT=' + chr(39) + result + chr(39);
       ValutaParancs(_pcs);
       exit;
     end;

   if (_menupont=5) then
     begin
       _tranzakcio := '+B';
       _lastnum := Valutaquery.fieldByName('UTOLSOWUUGYFELBEBLOKK').asInteger;
       inc(_lastnum);
       result := 'UB-' + nul6(_lastnum);
       Valutaquery.close;
       Valutadbase.close;
       _pcs := 'UPDATE WUAFAADATOK SET UTOLSOWUUGYFELBEBLOKK='+inttostr(_lastnum)+',';
       _pcs := _pcs + 'WAKTUALBIZONYLAT=' + chr(39) + result + chr(39);
       ValutaParancs(_pcs);
       exit;
     end;

    if (_menupont=6) then
     begin
       _tranzakcio := '-K';
       _lastnum := Valutaquery.fieldByName('UTOLSOWUUGYFELKIBLOKK').asInteger;
       inc(_lastnum);
       result := 'UK-' + nul6(_lastnum);
       Valutaquery.close;
       Valutadbase.close;
       _pcs := 'UPDATE WUAFAADATOK SET UTOLSOWUUGYFELKIBLOKK='+inttostr(_lastnum)+',';
       _pcs := _pcs + 'WAKTUALBIZONYLAT=' + chr(39) + result + chr(39);
       ValutaParancs(_pcs);
       exit;
     end;
END;

// =============================================================================
           function TwesternUnionForm.Nul6(_int: integer): string;
// =============================================================================


begin
  result := inttostr(_int);
  while length(result)<6 do result := '0' + result;
end;


// =============================================================================
                    procedure TWesternUnionForm.WuBizonylatPrint;
// =============================================================================

begin
  if _menupont<3 then icNyugta;
  if (_menupont>2) and (_menupont<5) then Wunyugta;
  if _menupont>4 then UgyfNyugta;

  StartNyomtatas;
end;

// =============================================================================
                     procedure TWesternUnionForm.ICnyugta;
// =============================================================================

begin
  _mtcnszam := '-';

  BlokkFoCimIro;
  VonalHuzo;
  if _menuPont=1 then writeLn(_LFile,'  ATVETEL EXCLUSIVE CASH PENZTARATOL')
                  else writeLn(_LFile,'   ATADAS EXCLUSIVE CASH PENZTARANAK');
  NyugtaLablec;
end;


// =============================================================================
                     procedure TwesternUnionForm.WUnyugta;
// =============================================================================

begin
  _MtcnSzam := '-';

  BlokkFoCimIro;
  VonalHuzo;
  if _menuPont=3 then writeLn(_LFile,'  ATVETEL WESTERN UNION PENZTARATOL')
                   else writeLn(_LFile,'   ATADAS WESTERN UNION PENZTARANAK');
  writeLn(_LFile,' Partnerceg: '+ _aktpenztarnev);
  NyugtaLablec;
end;

// =============================================================================
                   procedure TWesternUnionForm.ugyfNyugta;
// =============================================================================

begin
  BlokkFoCimIro;
  VonalHuzo;
  if _menuPont=5 then writeLn(_LFile,'       PENZATVETEL EGY UGYFELTOL')
                   else writeLn(_LFile,'       PENZATADAS EGY UGYFELNEK');
  writeLn(_LFile,'    UGYFEL: '+ _partnernev);
  NyugtaLablec;
end;



// =============================================================================
                     procedure TwesternUnionForm.NyugtaLablec;
// =============================================================================

begin

//  if _storno=3 then KozepreIr('STORNO BIZONYLAT');
//  if _storno=2 then KozepreIr('STORNOZOTT BIZONYLAT');

  VonalHuzo;
  writeLn(_LFile,'  Bizonylatszam : '+_bizonylat);
  writeLn(_Lfile,'      MTCN szam : '+_mtcnszam);

  if (_menuPont=1) or (_menupont=3) or (_menuPont=5) then
    begin
      writeLn(_LFile,'  Atvetel kelte : '+ _wuDatum+' '+_aktidos);
        write(_Lfile,'  Atvett osszeg : ');
    end else
    begin
      writeLn(_LFile,'  Atadas  kelte : '+ _wuDatum+' '+_aktidos);
        write(_Lfile,' Atadott osszeg : ');
    end;

  writeLn(_LFile,ForintForm(_wuosszeg)+' '+_aktDnem);

  if _menupont<5 then
    begin
      writelN(_Lfile,'  Szallito neve : ' + _szallitonev);
      writeln(_LFile,'  Zsakplombaszam: ' + _plombaszam);
    end;

  VonalHuzo;
  writeLn(_LFile,_sorveg);
  writeLn(_Lfile,dupestring('.',18)+'   '+dupestring('.',18));
  writeLn(_LFile,'     atado' + dupestring(' ',17)+'atvevo');
end;


// =============================================================================
            procedure TwesternUnionForm.Valutaparancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.close;
  Valutadbase.connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      ExecSql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;

// =============================================================================
            procedure TwesternUnionForm.Ugyfelparancs(_ukaz: string);
// =============================================================================

begin
  Ugyfeldbase.close;
  Ugyfeldbase.connected := true;
  if UgyfelTranz.InTransaction then UgyfelTranz.Commit;
  UgyfelTranz.StartTransaction;
  with UgyfelQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      ExecSql;
    end;
  UgyfelTranz.Commit;
  UgyfelDbase.close;
end;


// =============================================================================
              procedure TWesternUnionForm.BlokkFocimIro;
// =============================================================================

begin

  assignFile(_LFile,'c:\valuta\Aktlst.txt');
  Rewrite(_LFile);
  write(_LFile,_inic);


  Kozepreir(_cegNev);
  Kozepreir(_homepenztarkod+' '+_homePenztarNev);
  Kozepreir(_homePenztarCim);
  Kozepreir('Aoszam: ' + _cegAdoszam);
  Kozepreir('Tel: '+ _homePenztarTelefon);

  if _ezcopy then writeLn(_LFile,'          (Bizonylat masolat)');
  if _storno=2 then  // stornozott
      writeln(_LFile,'(Stornozott bizonylat. Storno: '+_stornobizonylat+')');

  if _storno=3 then
      writeLN(_LFile,'(Storno bizonylat. Eredeti biz: '+_stornozottbizonylat+')');
end;


// =============================================================================
                  procedure TWesternUnionForm.StartNyomtatas;
// =============================================================================


var _mondat: string;
    _nyomtat,_olvas: textFile;


begin
  Writeln(_LFile,_LF5);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else Assignprn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
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
                 procedure TWesternUnionForm.VonalHuzo;
// =============================================================================


begin
  writeLn(_Lfile,dupeString('-',40));
end;

// ============================================================================
              procedure TWesternUnionForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;


// =============================================================================
                 function TwesternUnionForm.getidos: string;
// =============================================================================


var _time: TDatetime;

begin
  if _wudatum='' then _wudatum := _mamas;
  _time := Time;
  result := Timetostr(_time);
  if midstr(result,3,1)<>':' then result := '0' + result;
  result := leftstr(result,5);
end;


// =============================================================================
           procedure TWESTERNUNIONFORM.szallitoeditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;


// =============================================================================
          procedure TWESTERNUNIONFORM.szallitoeditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
end;


// =============================================================================
      procedure TWESTERNUNIONFORM.szallitoeditKeyDown(Sender: TObject;
                                        var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);
  if (_bill=40) or (_bill=13) then
    begin
      ActiveControl := Plombaszamedit;
      exit;
    end;
end;


// =============================================================================
       procedure TWESTERNUNIONFORM.PLOMBASZAMEDITKeyDown(Sender: TObject;
                                         var Key: Word; Shift: TShiftState);
// =============================================================================

begin

  _bill := ord(key);
  if (_bill=38) then
    begin
      ActiveControl := SzallitoEdit;
      exit;
    end;

  if (_bill=40) or (_bill=13) then
    begin
      ActiveControl := PszokeGomb;
      exit;
    end;
end;



// =============================================================================
           procedure TWESTERNUNIONFORM.PSZOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _szallitonev := trim(SzallitoEdit.Text);
  _plombaszam := trim(Plombaszamedit.Text);

  if _szallitonev='' then
    begin
      ActiveControl := Szallitoedit;
      exit;
    end;

  if _plombaszam='' then
    begin
      ActiveControl := Plombaszamedit;
      exit;
    end;
  Penzszallitopanel.Visible := false;
  WuRekordRogzites;

  _aktelojel := _elojelsor[_menupont];
  WukeszletRegen(_wuOsszeg,_aktdnem,_aktelojel);
  KeszletDisplay;
  WuBizonylatPrint;
  MegsemGombclick(Nil);
end;



// =============================================================================
        procedure TWESTERNUNIONFORM.PSZMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  PenzSzallitoPanel.visible := false;
  MegsemgombClick(Nil);
end;


// =============================================================================
             procedure TWESTERNUNIONFORM.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  uJPENZTAREDIT.clear;
  with UjpenztarPanel do
    begin
      Top := 144;
      Left := 24;
      Visible := True;
    end;
  ActiveControl := UjpenztarEdit;
end;

// =============================================================================
           procedure TWESTERNUNIONFORM.UJPENZTAREDITEnter(Sender: TObject);
// =============================================================================

begin
  Ujpenztaredit.Color := $b0000;
end;

// =============================================================================
         procedure TWESTERNUNIONFORM.UJPENZTAREDITExit(Sender: TObject);
// =============================================================================

begin
  Ujpenztaredit.Color := clgRAY;
end;

// =============================================================================
       procedure TWESTERNUNIONFORM.UJPENZTAREDITKeyDown(Sender: TObject;
                                        var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=13 then Activecontrol := Ujpenztarokegomb;
end;


// =============================================================================
        procedure TWESTERNUNIONFORM.UJPENZTAROKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ujpenztarnev :=trim(Ujpenztaredit.Text);
  if _ujpenztarnev='' then exit;

  UgyfelQuery.close;
  Ugyfeldbase.close;

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;

      Sql.Clear;
      Sql.Add('SELECT * FROM WUAFAADATOK');
      Open;
      _cegszam := FieldbyName('UTOLSOWUCEG').asInteger;
      Close;
    end;

  ValutaDbase.close;
  inc(_cegszam);
  _pcs := 'INSERT INTO WUAFACEGEK (CEGSZAM,CEGNEV)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_cegszam) + ',';
  _pcs := _pcs + chr(39) + _ujpenztarnev + chr(39) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE WUAFAADATOK SET UTOLSOWUCEG=' +inttostr(_cegszam);
  ValutaParancs(_pcs);

  _aktPenztarNev := _ujPenztarNev;
  _aktPenztarszam := _cegszam;
  PenztartValasztott;

end;

// =============================================================================
     procedure TWESTERNUNIONFORM.UJPENZTARMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  UjpenztarPanel.Visible := False;
  PenztarRacs.SetFocus;
end;

// =============================================================================
            procedure TWESTERNUNIONFORM.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  NapvalasztoPanel.Enabled := true;
  NapvalasztoPanel.Font.Color := clBlack;
end;

// =============================================================================
       procedure TWESTERNUNIONFORM.TRANZOSSZEGPANELClick(Sender: TObject);
// =============================================================================

begin
  ActiveControl := OsszegHideEdit;
end;

// =============================================================================
         procedure TWESTERNUNIONFORM.dnemhideeditKeyDown(Sender: TObject;
// =============================================================================

  var Key: Word; Shift: TShiftState);
begin
  _bill := ord(key);
  if (_bill=37) or (_bill=39) then
    begin
      if _aktDnem='HUF' then
        begin
          UsdPanel.Color       := $B0FFFF;
          UsdShape.Brush.Color := $B0FFFF;
          UsdPanel.Font.Color  := clBlack;
          _aktdnem := 'USD';

          HufPanel.Color       := $A0A0A0;
          HufShape.Brush.Color := $A0A0A0;
          Hufpanel.Font.Color  := clGray;
        end else
        begin
          HufPanel.Color := $b0ffff;
          HufShape.Brush.Color := $B0FFFF;
          Hufpanel.Font.Color := clBlack;

          UsdPANEL.Color := $A0A0A0;
          UsdShape.Brush.Color := $A0A0A0;
          UsdPanel.Font.Color := clGray;
          _aktdnem := 'HUF';
        end;
      exit;
    end;

  if _bill=13 then
    begin
      TranzdnemPanel.Caption := _aktdnem;
      DnemTakaroPanel.Visible := true;
      ActiveControl := OsszegHideedit;
      exit;
    end;


end;

// =============================================================================
        procedure TWESTERNUNIONFORM.OSSZEGHIDEEDITExit(Sender: TObject);
// =============================================================================

begin
  Tranzosszegpanel.Color := clWhite;
end;

// =============================================================================
          procedure TWESTERNUNIONFORM.RENDBENGOMBEnter(Sender: TObject);
// =============================================================================

begin
  if _wuOsszeg=0 then Activecontrol := OsszegHideEdit;
end;

// =============================================================================
        procedure TWESTERNUNIONFORM.PENZATVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  TacePao.Visible := False;

  _menupont := TPanel(Sender).Tag;
  _menuactive := False;
  Megsemgomb.Enabled := True;

  _aktpenztarszam := 0;

  if (_menupont=5) then Iranypanel.Caption := 'ÁTVETT ÖSSZEG'
  else Iranypanel.caption := 'ÁTADOTT OSSZEG';

  _keres := '';
  UgyfelKeresoedit.clear;
  Infopanel.Visible := false;

  _pcs := 'SELECT * FROM WUGYFEL' + _sorveg;
  _pcs := _pcs + 'ORDER BY NEV';

  Ugyfeldbase.Connected := true;
  with UgyfelQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  with DsoftPanel do
    begin
      Top := 320;
      Left :=  843;
      Visible := True;
    end;

  UjUgyfelPanel.Visible := false;
  with UgyfelValasztoPanel do
    begin
      top := 48;
      Left := 384;
      Visible := true;
    end;
  ActiveControl := UgyfelRacs;
  UgyfelRacs.SetFocus;
end;


// =============================================================================
         procedure TWESTERNUNIONFORM.UGYFELRACSDblClick(Sender: TObject);
// =============================================================================

begin
  UgyfeletValasztott;
end;

// =============================================================================
    procedure TWESTERNUNIONFORM.UGYFELRACSKeyUp(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
// =============================================================================


var _ujchar,_ujkeres: string;
    _megvan: boolean;
    _wlen: byte;


begin
   _bill := ord(key);
  if _bill=13 then
    begin
      UgyfeletValasztott;
      exit;
    end;

  if (_bill>32) and (_bill<41) then
    begin
      UgyfelkeresoEdit.Clear;
      _keres := '';
      exit;
    end;

  if _bill>64 then
    begin
      _ujchar := uppercase(chr(_bill));
      _ujkeres := _keres + _ujchar;
      _megvan := UgyfelQuery.locate('NEV',_ujkeres,[loPartialKey]);
      if _megvan then
        begin
          _keres := _ujkeres;
          UgyfelKeresoedit.Text := _keres;
        end else UgyfelQuery.Locate('NEV',_keres,[loPartialkey]);
      exit;
    end;

  if _bill=8 then
    begin
      if _keres='' then exit;
      _wlen := length(_keres);
      if _wlen=1 then
        begin
          _keres := '';
          UgyfelKeresoedit.clear;
          exit;
        end;
      _keres := leftstr(_keres,_wlen-1);
      UgyfelQuery.Locate('NEV',_keres,[loPartialKey]);
    end;
end;


// =============================================================================
              procedure TWesternUnionForm.UgyfeletValasztott;
// =============================================================================

begin
  _aktugyfelnev := trim(UgyfelQuery.fieldByName('NEV').AsString);
  _aktugyfelszam := Ugyfelquery.FieldByName('UGYFELSZAM').asInteger;

  UgyfelQuery.close;
  Ugyfeldbase.close;

  UgyfelValasztoPanel.Visible := False;
  with PenzkepPanel do
    begin
      Top := 48;
      Left := 384;
      Visible := true;
    end;

  PartnerFoNevedit.Text := _aktugyfelnev;
  KerdoMondat.Visible := false;
  TranzosszegPanel.Caption := '';
  TranzDnempanel.Caption := '';
  MtcnPanel.Text := '';

  MTCNpanel.Enabled := True;
  MTcnpanel.color   := clWhite;
  MTCNPanelTakaro.Visible := False;

  UsdPanel.Color       := $B0FFFF;
  UsdShape.Brush.Color := $B0FFFF;
  UsdPanel.Font.Color  := clBlack;

  HufPanel.Color       := $A0A0A0;
  HufShape.Brush.Color := $A0A0A0;
  HufPanel.Font.Color  := clGray;

  _aktdnem := 'USD';
  Tranzdnempanel.Caption := '';

  DnemTakaropanel.Visible := False;
  with Munkapanel do
    begin
      Top  := 320;
      Left := 380;
      Visible := true;
    end;
  RendbenGomb.Enabled := False;
  ActiveControl := DnemHideedit;
end;


// =============================================================================
            procedure TWESTERNUNIONFORM.MTCNPANELEnter(Sender: TObject);
// =============================================================================

begin
  if _wuosszeg=0 then
    begin
      ActiveControl := Osszeghideedit;
      exit;
    end;
  MTCNPanel.Color := clYellow;
end;


// =============================================================================
            procedure TWESTERNUNIONFORM.MTCNPANELExit(Sender: TObject);
// =============================================================================

begin
  MTCNPanel.Color := clWindow;
end;



// =============================================================================
            procedure TWESTERNUNIONFORM.MTCNPANELKeyDown(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _mtcnszam := trim(MTCNpanel.Text);

  if _mtcnSzam='' then exit;

  RendbenGomb.Enabled := true;
  Activecontrol := RendbenGomb;
end;

// =============================================================================
        procedure TWESTERNUNIONFORM.UJUGYFELGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nevedit.clear;
  AnyjaEdit.Clear;
  SzulhelyEdit.clear;
  SzulidoEdit.clear;
  LakcimEdit.clear;
  OkmanytipusEdit.clear;
  AzonositoEdit.Clear;

  with UjUgyfelpanel do
   begin
     Top  := 76;
     Left := 6;
     Visible := true;
   end;
  ActiveControl := Nevedit;
end;


// =============================================================================
           procedure TWESTERNUNIONFORM.neveditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clBlack;
  Tedit(sender).Font.Color := clyellow;
end;


// =============================================================================
         procedure TWESTERNUNIONFORM.neveditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := $777777;
end;


// =============================================================================
  procedure TwesternUnionForm.WukeszletRegen(_sum: integer;_dev,_ejel: string);
// =============================================================================

begin
  GetAktualKeszlet;
  if _dev='USD' then
    begin
      if _ejel='+' then _wusdKeszlet := _wusdKeszlet + _sum
      else _wusdKeszlet := _wUsdKeszlet - _sum;
    end else
    begin
      if _ejel='+' then _wHufKeszlet := _wHufKeszlet + _sum
      else _wHufKeszlet := _wHufKeszlet - _sum;
    end;
  _pcs := 'UPDATE WUAFAADATOK SET WUDOLLARKESZLET='+inttostr(_wusdkeszlet)+',';
  _pcs := _pcs + 'WUFORINTKESZLET='+inttostr(_whufkeszlet)+',';
  _pcs := _pcs + 'WAKTUALBIZONYLAT='+chr(39)+chr(39);

  ValutaParancs(_pcs);
end;


// =============================================================================
    procedure TWESTERNUNIONFORM.neveditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _bill,_tag: integer;

begin
  _bill := ord(key);
  _tag := TEdit(Sender).Tag;

  if (_bill=38) and (_tag=1) then exit;
  if _bill=38 then
    begin
      ActiveControl := _ujugyfeledit[_tag];
      exit;
    end;

  if (_bill=40) or (_bill=13) then
    begin
      if _tag=7 then
        begin
          ActiveControl := ujUgyfelOkegomb;
          exit;
        end;
      ActiveControl := _ujugyfelEdit[_tag+1];
      exit;
    end;
end;

// =============================================================================
        procedure TWESTERNUNIONFORM.UJUGYFELOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _aktugyfelnev := trim(Nevedit.Text);
  if _aktugyfelnev='' then exit;

  _anyjaneve := trim(AnyjaEdit.Text);
  _szulhely  := trim(Szulhelyedit.Text);
  _szulido := szulidoedit.text;
  _lakcim := trim(Lakcimedit.text);
  _okmanytipus := trim(okmanytipusedit.text);
  _azonosito := trim(azonositoedit.text);

   _ujpenztarnev :=trim(Ujpenztaredit.Text);
  if _ujpenztarnev='' then exit;

  UgyfelQuery.close;
  Ugyfeldbase.close;

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;

      Sql.Clear;
      Sql.Add('SELECT * FROM WUAFAADATOK');
      Open;
      _aktugyfelszam := FieldbyName('UTOLSOWUGYFEL').asInteger;
      Close;
    end;

  ValutaDbase.close;
  inc(_aktugyfelszam);

  _pcs := 'INSERT INTO WUGYFEL (UGYFELSZAM,NEV,ANYJANEVE,SZULETESIHELY,SZULETESIIDO,';
  _pcs := _pcs + 'LAKCIM,OKMANYTIPUS,AZONOSITO)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_aktugyfelszam) + ',';
  _pcs := _pcs + chr(39) + _aktugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _anyjaneve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _okmanytipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _azonosito + chr(39) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE WUAFAADATOK SET UTOLSOWUGYFEL=' +inttostr(_aktugyfelszam);
  ValutaParancs(_pcs);

  _pcs := 'SELECT * FROM WUGYFEL' + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_aktugyfelszam);

  Ugyfeldbase.Connected := true;
  with UgyfelQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  UgyfeletValasztott;

end;

// =============================================================================
         procedure TWESTERNUNIONFORM.REPRINTGOMBClick(Sender: TObject);
// =============================================================================


var _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;

  _ezcopy := True;
  with WumozgasQuery do
    begin
      _foegyseg := FieldByName('FOEGYSEGSZAM').asInteger;
      _tranzakcio := FieldByNAme('TRANZAKCIOTIPUS').asstring;
      _wuOsszeg := FieldByName('BANKJEGY').asInteger;
      _aktdnem := FieldByName('VALUTANEM').asstring;
      _storno := FieldByName('STORNO').AsInteger;
      _stornobizonylat := trim(FieldByNAme('STORNOBIZONYLAT').asstring);
      _stornozottbizonylat := trim(FieldByName('STORNOZOTTBIZONYLAT').asString);
    end;
  if _foegyseg=1 then
      if _tranzakcio='+B' then _menupont := 1 else _menupont := 2;

  if _foegyseg=2 then
      if _tranzakcio='+B' then _menupont := 3 else _menupont := 4;
      _aktpenztarnev := _partnernev;

  if _foegyseg=5 then
      if _tranzakcio='+B' then _menupont := 5 else _Menupont := 6;

  WuBizonylatPrint;
  _ezCopy := False;

end;

// =============================================================================
          procedure TWESTERNUNIONFORM.STORNOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _stornozottBizonylat := _bizonylat;
//  _origbizonylat := _bizonylat;

  if _foegyseg=1 then
      if _tranzakcio='+B' then _menupont := 1 else _menupont := 2;

  if _foegyseg=2 then
      if _tranzakcio='+B' then _menupont := 3 else _menupont := 4;

  if _foegyseg=5 then
      if _tranzakcio='+B' then _menupont := 5 else _Menupont := 6;


  StBizLabel.Caption := _stornozottbizonylat;

  StBizLabel.Repaint;

  with SureStornoPanel do
    begin
      Top := 270;
      Left := 300;
      Visible := true;
    end;
  ActiveControl := STORNOMegsemGomb;
end;


// =============================================================================
        procedure TWESTERNUNIONFORM.STORNOMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Surestornopanel.Visible := false;
end;

// =============================================================================
          procedure TWESTERNUNIONFORM.STORNOZDLEGOMBClick(Sender: TObject);
// =============================================================================

var _minosszeg: integer;

begin
  Wumozgasquery.close;
  Wumozgasdbase.close;

  SureStornoPanel.Visible := false;
  _storno := 2;
  _aktIdos := GetIdos;
  _stornobizonylat := Getbizonylatszam;
  _minosszeg := trunc((-1)*_wuosszeg);

  _pcs := 'INSERT INTO WUMOZGAS (FOEGYSEGSZAM,PENZTARSZAM,UGYFELSZAM,SORSZAM,';
  _pcs := _pcs + 'DATUM,IDO,VALUTANEM,BANKJEGY,UGYFELTIPUS,PENZTAROSNEV,';
  _pcs := _pcs + 'TRANZAKCIOTIPUS,MTCNSZAM,STORNO,STORNOZOTTBIZONYLAT,IDKOD)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_foegyseg)+',';
  _pcs := _pcs + inttostr(_aktpenztarszam) + ',';
  _pcs := _pcs + inttostr(_aktugyfelszam) + ',';
  _pcs := _pcs + chr(39) + _stornobizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_minosszeg) + ',';
  _pcs := _pcs + chr(39) + _ugyfeltipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _penztarosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranzakcio + chr(39) + ',';    // -K vagy +B
  _pcs := _pcs + chr(39) + _mtcnszam + chr(39) + ',';
  _pcs := _pcs + '3,'+CHR(39)+_stornozottbizonylat+chr(39)+',';
  _pcs := _pcs + chr(39) + _idkod + chr(39) + ')';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE WUMOZGAS SET STORNO=2,';
  _pcs := _pcs + 'STORNOBIZONYLAT='+chr(39)+_stornobizonylat+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+chr(39)+_stornozottbizonylat+chr(39);

  ValutaParancs(_pcs);

  wumozgasdbase.Connected := true;
  with wumozgasquery do
    begin
      Close;
      sql.clear;
      Sql.Add('SELECT * FROM WUMOZGAS');
      Open;
      Last;
    end;

  _aktelojel := _elojelsor[_menupont];
  WukeszletRegen(_minosszeg,_aktdnem,_aktelojel);
  KeszletDisplay;

  wumozgasquery.Locate('SORSZAM',_stornobizonylat,[loPartialkey]);

  RekordBeolvasas;
  WubizonylatPrint;

  _storno := 1;

  Activecontrol := Bizonylatracs;
  BizonylatRacs.SetFocus;
end;


// =============================================================================
   function TWesternUnionForm.VanennyiPenzunk(_dev: string; _bjegy: integer):boolean;
// =============================================================================

begin
  result := True;
  if _aktelojel='+' then exit;

  if (_dev='USD') AND (_wusdkeszlet>=_bjegy) then exit;

  if (_dev='HUF') AND (_wHufKeszlet>=_bjegy) then exit;
  result := false;
end;


// =============================================================================
        procedure TWESTERNUNIONFORM.ListaNyomtatas;
// =============================================================================

//            KINYOMTATJA A WESTERN UNION BIZONYLATOKAT

var _tipnev,_bjs,_pSor: string;

begin
  wuMozgasdbase.close;
  if _tolDatum=_mamas then
    begin
      _pcs := 'SELECT * FROM WUMOZGAS';
      wuMozgasDbase.DatabaseName := 'c:\valuta\database\valuta.fdb';
    end else
    begin
      _LFarok := midstr(_toldatum,3,2)+midstr(_toldatum,6,2);
      wuMozgasDbase.DatabaseName := 'c:\valuta\database\valdata.fdb';
      _pcs := 'SELECT * FROM WUNI'+_lfarok + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>=' + chr(39) + _toldatum + chr(39) + ')';
      _pcs := _pcs + ' AND (DATUM<=' + chr(39)+_igdatum + chr(39) + ')';
    end;

  _pcs := _pcs + _sorveg + 'ORDER BY DATUM,IDO';

  wuMozgasdbase.Connected := true;
  with WuMozgasQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
    end;

  AssignFile(_LFile,'c:\valuta\Aktlst.txt');
  Rewrite(_LFile);

  KozepreIr('Western Union Bizonylatok');
 // writeLn(_Lfile,' ');

  KozepreIr(_tolDatum+'-'+_igDatum+' kozott');
  VonalHuzo;
  writeLn(_LFile,'   Datum   Ttip Bankjegy Dnem   MTCN');
  VonalHuzo;


  wuMozgasQuery.First;
  while not wuMozgasQuery.eof do
    begin
      with WuMozgasQuery do
        begin
          _storno      := FieldByName('STORNO').asInteger;
          _wudatum     := FieldByName('DATUM').AsString;
          _tipus       := FieldByName('TRANZAKCIOTIPUS').AsString;
          _wuosszeg    := FieldByNAme('BANKJEGY').AsInteger;
          _aktdnem     := FieldByName('VALUTANEM').AsString;
          _mtcnszam    := FieldByName('MTCNSZAM').asString;
        end;

      if leftstr(_tipus,1)='+' then _tipnev := 'vet ' else _tipnev := 'kiad';

      _bjs  := Elokieg(inttostr(_wuosszeg),10);
      _psor := _wudatum + ' ' + _tipnev + _bjs + ' '+_aktdnem+' ';
      if (_storno>1) then
        begin
          if _storno=3 then _psor := _psor + 'storno' ELSE _psor := _psor + 'stornozott';
        end else _psor := _psor + _mtcnszam;

      writeLn(_LFile,_psor);
      wuMozgasQuery.Next;
    end;
 VonalHuzo;
 WuMozgasQuery.First;
 StartNyomtatas;
end;


// =============================================================================
           procedure TWesternUnionForm.LISTAGOMBClick(Sender: TObject);
// =============================================================================

begin

  TolNaptar.CalendarDate := Date;
  IgNaptar.CalendarDate  := Date;

  TolPanel.Caption := _mamas;
  Igpanel.Caption  := _mamas;

  with ListastartPanel do
    begin
      Top := 180;
      Left := 420;
      Visible := True;
    end;
  Activecontrol := Listadatumokegomb;
end;


// =============================================================================
         procedure TWesternUnionForm.TOLNAPTARChange(Sender: TObject);
// =============================================================================

begin
  _toldat   := Tolnaptar.CalendarDate;
  _toldatum := Hundatetostr(_toldat);

  Tolpanel.Caption := _toldatum;
end;

// =============================================================================
           procedure TWesternUnionForm.IGNAPTARChange(Sender: TObject);
// =============================================================================

begin
  _igdat := ignaptar.CalendarDate;
  _igdatum := Hundatetostr(_igdat);
  igPanel.Caption := _igdatum;
end;


// =============================================================================
         procedure TWesternUnionForm.TOLELOHOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Tolnaptar.PrevMonth;
end;

// =============================================================================
          procedure TWesternUnionForm.TOLKOVHOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Tolnaptar.NextMonth;
end;

// =============================================================================
         procedure TWesternUnionForm.LISTAMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ListaStartPanel.Visible := False;
end;

// =============================================================================
      procedure TWesternUnionForm.LISTADATUMOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _toldat   := tolnaptar.CalendarDate;
  _igdat    := ignaptar.CalendarDate;

  if _igdat<_toldat then
    begin
      ShowMessage('A kezdõnap nagyobb az utolsó napnál');
      exit;
    end;

  _tolho := monthof(_toldat);
  _igho  := monthof(_igdat);
  if _tolho<>_igho then
    begin
      Showmessage('Az intervallumnak egyetlen hónapban kell lennie');
      exit;
    end;

  _toldatum := Hundatetostr(_toldat);
  _igdatum  := Hundatetostr(_igdat);

  ListaStartPanel.Visible := false;

  ListaNyomtatas;
end;


// =============================================================================
         function TWesternUnionForm.Elokieg(_s:string;_h: byte):string;
// =============================================================================

begin

  result := _s;
  while length(result)<_h do  result := ' '+result;
end;




procedure TWesternUnionForm.IGELOHOGOMBClick(Sender: TObject);
begin
  IGnaptar.PrevMonth;
end;

procedure TWesternUnionForm.IGKOVHOGOMBClick(Sender: TObject);
begin
  Ignaptar.NextMonth;
end;

// =============================================================================
           function TWesternUnionForm.kerekito(_int: integer): integer;
// =============================================================================


var _sums: string;
    _utasc,_utix: byte;
begin
  result := _int;
  _sums := inttostr(_int);
  _utix := length(_sums);
  _utasc := ord(_sums[_utix])- 48;

  case _utasc of
    0..2: result := _int - _utasc;

    3..7: result := (_int-_utasc)+5;

    8,9: result := (_int-_utasc)+10;

  end;
end;

// =============================================================================
                 procedure TWesternUnionForm.PenzkeszletList(Sender: TObject);
// =============================================================================
//            KINYOMTATJA A WESTERN UNION PÉNZKÉSZLETÉT

begin
  _aktidos := GetIdos;
  _aktidos := '('+leftstr(_aktidos,2)+' ora '+midstr(_aktidos,4,2)+' perckor)';

  assignFile(_LFile,'c:\valuta\Aktlst.txt');
  Rewrite(_LFile);
  write(_LFile,_inic);

  VonalHuzo;

  KozepreIr('A WESTERN UNION PENZKESZLETEI');

  VonalHuzo;
  KozepreIr(lowercase(_mamas));
  Kozepreir(_aktidos);
  VonalHuzo;

  KozepreIr('Dollarkeszlet: '+ forintform(_wUsdKeszlet)+' USD'+_sorveg);
  KozepreIr('Forintkeszlet: '+ forintform(_wHufKeszlet)+' HUF');
  VonalHuzo;
  StartNyomtatas;

end;



procedure TWesternUnionForm.szemadatgombClick(Sender: TObject);



begin
  with UgyfelQuery do
    begin
      _xUgyfelszam := fieldByName('UGYFELSZAM').asInteger;
      _xnev := trim(FieldByName('NEV').asstring);
      _xAnyja := trim(FieldByName('ANYJANEVE').asString);
      _xSzulhely := trim(FieldByNAme('SZULETESIHELY').AsString);
      _xszulido := FieldByName('SZULETESIIDO').asstring;
      _xLakcim := trim(FieldByName('LAKCIM').AsString);
      _xokmtipus := trim(FieldByNAme('OKMANYTIPUS').asstring);
      _xazonosito := trim(FieldByNAme('AZONOSITO').asString);

      xNevEdit.Text := _xNev;
      xAnyjaedit.Text := _xAnyja;
      xSzulhelyEdit.Text := _xSzulhely;
      xSzulidoEdit.Text := _xSzulido;
      xLakcimEdit.Text := _xLakcim;
      xOkmanytipusEdit.Text := _xOkmTipus;
      xAzonositoedit.TExt := _xAzonosito;
    end;

  with SzemadatPanel do
    begin
      Top := 176;
      Left := 392;
      Visible := True;
      BringtoFront;
    end;
  Activecontrol := Visszagomb;
end;


procedure TWesternUnionForm.visszagombClick(Sender: TObject);
begin
  if _datavaltozott then
    begin
      _xlakcim := trim(xLakcimedit.text);
      _xokmtipus := trim(xOkmanytipusedit.Text);
      _xAzonosito := trim(xAzonositoEdit.text);
      _pcs := 'UPDATE WUGYFEL SET LAKCIM='+ chr(39)+_xlakcim+chr(39)+',';
      _pcs := _pcs + 'OKMANYTIPUS='+chr(39)+_xOkmTipus+chr(39)+',';
      _pcs := _pcs + 'AZONOSITO='+CHR(39)+_xAzonosito+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_xUgyfelszam);
      Ugyfelparancs(_pcs);

      _pcs := 'SELECT * FROM WUGYFEL' + _sorveg;
      _pcs := _pcs + 'ORDER BY NEV';

      Ugyfeldbase.Connected := true;
      with UgyfelQuery do
        begin
          Close;
          Sql.Clear;
          sql.Add(_pcs);
          Open;
          First;
          Locate('NEV',_xnev,[loPartialkey]);
        end;
    end;

  SzemAdatPanel.Visible := False;
  Activecontrol := UgyfelRacs;
  UgyfelRacs.SetFocus;
end;

procedure TWesternUnionForm.XLAKCIMEDITChange(Sender: TObject);
begin
_datavaltozott := True;
end;

procedure TWesternUnionForm.XLAKCIMEDITEnter(Sender: TObject);
begin
  Tedit(sender).Color := $555555;
end;

procedure TWesternUnionForm.XLAKCIMEDITExit(Sender: TObject);
begin
  Tedit(sender).Color := $252525;
end;

procedure TWesternUnionForm.UJUGYFELMEGSEMGOMBClick(Sender: TObject);
begin
  Ujugyfelpanel.Visible := false;
end;

procedure TWesternUnionForm.BIZONYLATRACSEnter(Sender: TObject);
begin
  Tacepao.Visible := false;
end;

procedure TWesternUnionForm.BIZONYLATRACSExit(Sender: TObject);
begin
  Tacepao.Visible := True;
end;

function TwesternUnionForm.HunDatetostr(_calDat: TDateTime): string;

var _h_ev,_h_ho,_h_nap: word;

begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


procedure TWesternUnionForm.Scanneles;

begin
  with FigyelemPanel do
    begin
      Top := 270;
      Left := 270;
      Visible := True;
      Repaint;
    end;

  Sleep(2200);

  _pcs := 'c:\valuta\bin\escan.exe W' + inttostr(_aktugyfelszam);
  _pacs := pchar(_pcs);
  WinexecAndwait32(_pacs,sw_normal);
  FigyelemPanel.visible := false;
  AskScanAllright;
end;

procedure TWesternUnionform.AskScanAllright;

begin
  with ScanPanel do
    begin
      top := 240;
      left := 310;
      Visible := true;
      repaint;
    end;
  Activecontrol := ScanOkegomb;
end;


// =============================================================================
  function TWesternUnionFORM.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
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



procedure TWesternUnionForm.SCANOKEGOMBClick(Sender: TObject);
begin
  ScanPanel.visible := false;
  TranzKonyveles;
end;

procedure TWesternUnionForm.RETRYGOMBClick(Sender: TObject);
begin
  ScanPanel.visible := false;
  Scanneles;
end;

procedure TWesternUnionForm.CANCELGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure TWesternUnionForm.OKMANYGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  TempParancs(_pcs);
  _pcs := 'INSERT INTO VTEMP (UGYFELTIPUS,UGYFELSZAM)' + _SORVEG;
  _pcs := _pcs + 'VALUES (' + CHR(39)+'W'+CHR(39)+',';
  _pcs := _pcs + inttostr(_aktugyfelszam)+')';
  TempParancs(_pcs);
  docdisprutin;
end;


// =============================================================================
            procedure TwesternUnionForm.Tempparancs(_ukaz: string);
// =============================================================================

begin
  Tempdbase.close;
  Tempdbase.connected := true;
  if TempTranz.InTransaction then TempTranz.Commit;
  TempTranz.StartTransaction;
  with TempQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      ExecSql;
    end;
  TempTranz.Commit;
  TempDbase.close;
end;



end.
