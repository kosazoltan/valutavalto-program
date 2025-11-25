unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Calendar, ExtCtrls, DB, IBCustomDataSet, Grids,
  DBGrids, IBTable, IBDatabase, IBQuery, Mask, DBCtrls, Buttons,dateUtils,
  StrUtils, jpeg;

type
  TBIZONYLATDISP = class(TForm)
    HAVIFEJTABLA: TIBTable;
    HAVIFEJQUERY: TIBQuery;
    HAVIFEJDBASE: TIBDatabase;
    HAVIFEJTRANZ: TIBTransaction;
    UGYFELQUERY: TIBQuery;
    UGYFELDBASE: TIBDatabase;
    UGYFELTRANZ: TIBTransaction;
    JOGIQUERY: TIBQuery;
    JOGIDBASE: TIBDatabase;
    jogitranz: TIBTransaction;
    TULAJQUERY: TIBQuery;
    TULAJDBASE: TIBDatabase;
    TULAJTRANZ: TIBTransaction;
    BLOKKFEJRACS: TDBGrid;
    BLOKKFEJSOURCE: TDataSource;
    TETELQUERY: TIBQuery;
    TETELDBASE: TIBDatabase;
    TETELTRANZ: TIBTransaction;
    HAVITETELQUERY: TIBQuery;
    HAVITETELDBASE: TIBDatabase;
    HAVITETELTRANZ: TIBTransaction;
    BLOKKTETELSOURCE: TDataSource;
    HAVIFEJTABLABIZONYLATSZAM: TIBStringField;
    HAVIFEJTABLATIPUS: TIBStringField;
    HAVIFEJTABLADATUM: TIBStringField;
    HAVIFEJTABLAIDO: TIBStringField;
    HAVIFEJTABLANETTO: TIntegerField;
    HAVIFEJTABLATRANZDIJ: TIntegerField;
    HAVIFEJTABLAKEZELESIDIJ: TIntegerField;
    HAVIFEJTABLAFIZETENDO: TIntegerField;
    HAVIFEJTABLAOSSZESFORINTERTEK: TIntegerField;
    HAVIFEJTABLAUGYFELTIPUS: TIBStringField;
    HAVIFEJTABLAUGYFELSZAM: TIntegerField;
    HAVIFEJTABLAUGYFELNEV: TIBStringField;
    HAVIFEJTABLATETEL: TSmallintField;
    HAVIFEJTABLAPENZTAROSNEV: TIBStringField;
    HAVIFEJTABLATARSPENZTARKOD: TIBStringField;
    HAVIFEJTABLATRBPENZTAR: TIBStringField;
    HAVIFEJTABLAMEGBIZOSZAM: TIntegerField;
    HAVIFEJTABLAMEGBIZOTT: TIntegerField;
    HAVIFEJTABLAPLOMBASZAM: TIBStringField;
    HAVIFEJTABLASTORNO: TSmallintField;
    HAVIFEJTABLASTORNOZOTTBIZONYLAT: TIBStringField;
    HAVIFEJTABLASTORNOBIZONYLAT: TIBStringField;
    HAVIFEJTABLAIDKOD: TIBStringField;
    BLOKKTETELRACS: TDBGrid;
    NAPTAR: TCalendar;
    UGYFELSOURCE: TDataSource;
    Panel10: TPanel;
    Panel20: TPanel;
    Panel23: TPanel;
    Label1: TLabel;
    blokkfejpanel: TPanel;
    Panel4: TPanel;
    DATUMPANEL: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel2: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel37: TPanel;
    Panel38: TPanel;
    Panel39: TPanel;
    Panel40: TPanel;
    Panel41: TPanel;
    Panel42: TPanel;
    Panel43: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape21: TShape;
    Shape17: TShape;
    Shape18: TShape;
    M: TShape;
    Panel44: TPanel;
    Panel45: TPanel;
    Panel46: TPanel;
    Panel47: TPanel;
    Panel48: TPanel;
    Panel49: TPanel;
    Panel50: TPanel;
    TNEV2PANEL: TPanel;
    TNEV1PANEL: TPanel;
    TNEV3PANEL: TPanel;
    TCIM1PANEL: TPanel;
    TCIM3PANEL: TPanel;
    TCIM2PANEL: TPanel;
    TAP1PANEL: TPanel;
    TAP2PANEL: TPanel;
    TAP3PANEL: TPanel;
    DBEdit3: TDBEdit;
    DBEdit17: TDBEdit;
    DBEdit18: TDBEdit;
    DBEdit19: TDBEdit;
    DBEdit20: TDBEdit;
    DBEdit21: TDBEdit;
    DBEdit22: TDBEdit;
    BIZONYLATTIPUSPANEL: TPanel;
    STORNOPANEL: TPanel;
    VISSZAGOMB: TBitBtn;
    TNEV4PANEL: TPanel;
    TCIM4PANEL: TPanel;
    TAP4PANEL: TPanel;
    DATUMKEROGOMB: TPanel;
    JOGISOURCE: TDataSource;
    FEJSOURCE: TDataSource;
    TETELSOURCE: TDataSource;
    FEJTABLA: TIBTable;
    FEJQUERY: TIBQuery;
    FEJDBASE: TIBDatabase;
    FEJTRANZ: TIBTransaction;
    PENZTARPANEL: TPanel;
    Label2: TLabel;
    PENZTARNEVPANEL: TPanel;
    PENZTARSZAMPANEL: TPanel;
    IRANYNEVPANEL: TPanel;
    PENZTARQUERY: TIBQuery;
    PENZTARDBASE: TIBDatabase;
    PENZTARTRANZ: TIBTransaction;
    Button1: TButton;
    SZUROPANEL: TPanel;
    Label3: TLabel;
    GroupBox1: TGroupBox;
    RR1: TRadioButton;
    RR2: TRadioButton;
    RR3: TRadioButton;
    RR4: TRadioButton;
    RR5: TRadioButton;
    RR6: TRadioButton;
    RR7: TRadioButton;
    RR8: TRadioButton;
    BitBtn1: TBitBtn;
    Shape19: TShape;
    EGESZHONAP: TRadioButton;
    CSAKNAP: TRadioButton;
    REPRINTGOMB: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    COPYPANEL: TPanel;
    Label4: TLabel;
    INDOKEDIT: TEdit;
    Label5: TLabel;
    Shape20: TShape;
    PROSNEVPANEL: TPanel;
    LAKCIMCSIK: TBitBtn;
    TETELQUERYBIZONYLATSZAM: TIBStringField;
    TETELQUERYVALUTANEM: TIBStringField;
    TETELQUERYARFOLYAM: TFloatField;
    TETELQUERYELSZAMOLASIARFOLYAM: TFloatField;
    TETELQUERYBANKJEGY: TIntegerField;
    TETELQUERYFORINTERTEK: TIntegerField;
    TETELQUERYELOJEL: TIBStringField;
    TETELQUERYCOIN: TSmallintField;
    TETELQUERYSTORNO: TSmallintField;
    TETELQUERYDATUM: TIBStringField;
    HAVITETELQUERYDATUM: TIBStringField;
    HAVITETELQUERYBIZONYLATSZAM: TIBStringField;
    HAVITETELQUERYVALUTANEM: TIBStringField;
    HAVITETELQUERYARFOLYAM: TFloatField;
    HAVITETELQUERYELSZAMOLASIARFOLYAM: TFloatField;
    HAVITETELQUERYBANKJEGY: TIntegerField;
    HAVITETELQUERYFORINTERTEK: TIntegerField;
    HAVITETELQUERYELOJEL: TIBStringField;
    HAVITETELQUERYCOIN: TSmallintField;
    HAVITETELQUERYSTORNO: TSmallintField;
    Panel1: TPanel;
    NAVPANEL: TPanel;
    HAVIFEJQUERYBIZONYLATSZAM: TIBStringField;
    HAVIFEJQUERYTIPUS: TIBStringField;
    HAVIFEJQUERYDATUM: TIBStringField;
    HAVIFEJQUERYIDO: TIBStringField;
    HAVIFEJQUERYNETTO: TIntegerField;
    HAVIFEJQUERYTRANZDIJ: TIntegerField;
    HAVIFEJQUERYKEZELESIDIJ: TIntegerField;
    HAVIFEJQUERYFIZETENDO: TIntegerField;
    HAVIFEJQUERYFIZETOESZKOZ: TSmallintField;
    HAVIFEJQUERYOSSZESFORINTERTEK: TIntegerField;
    HAVIFEJQUERYUGYFELTIPUS: TIBStringField;
    HAVIFEJQUERYUGYFELSZAM: TIntegerField;
    HAVIFEJQUERYUGYFELNEV: TIBStringField;
    HAVIFEJQUERYTETEL: TSmallintField;
    HAVIFEJQUERYIDKOD: TIBStringField;
    HAVIFEJQUERYPENZTAROSNEV: TIBStringField;
    HAVIFEJQUERYTARSPENZTARKOD: TIBStringField;
    HAVIFEJQUERYTRBPENZTAR: TIBStringField;
    HAVIFEJQUERYMEGBIZOSZAM: TIntegerField;
    HAVIFEJQUERYMEGBIZOTT: TIntegerField;
    HAVIFEJQUERYPLOMBASZAM: TIBStringField;
    HAVIFEJQUERYKONVERZIO: TSmallintField;
    HAVIFEJQUERYUGYFELCIM: TIBStringField;
    HAVIFEJQUERYADOSZAM: TIBStringField;
    HAVIFEJQUERYSTORNO: TSmallintField;
    HAVIFEJQUERYSTORNOZOTTBIZONYLAT: TIBStringField;
    HAVIFEJQUERYSTORNOBIZONYLAT: TIBStringField;
    HAVIFEJQUERYZCOUNTS: TIBStringField;
    HAVIFEJQUERYRECNUMS: TIBStringField;
    HAVIFEJQUERYKEREKITES: TSmallintField;
    HAVIFEJQUERYFORRAS: TIBStringField;
    HAVIFEJQUERYENGEDELYEZO: TIBStringField;
    Label6: TLabel;
    Panel5: TPanel;
    Panel11: TPanel;
    FORRASEDIT: TEdit;
    ENGEDEDIT: TEdit;
    FEJQUERYBIZONYLATSZAM: TIBStringField;
    FEJQUERYTIPUS: TIBStringField;
    FEJQUERYDATUM: TIBStringField;
    FEJQUERYIDO: TIBStringField;
    FEJQUERYOSSZESFORINTERTEK: TIntegerField;
    FEJQUERYUGYFELTIPUS: TIBStringField;
    FEJQUERYUGYFELSZAM: TIntegerField;
    FEJQUERYUGYFELNEV: TIBStringField;
    FEJQUERYTETEL: TSmallintField;
    FEJQUERYPENZTAROSNEV: TIBStringField;
    FEJQUERYTRBPENZTAR: TIBStringField;
    FEJQUERYTARSPENZTARKOD: TIBStringField;
    FEJQUERYMEGBIZOTT: TIntegerField;
    FEJQUERYMEGBIZOSZAM: TIntegerField;
    FEJQUERYSTORNO: TSmallintField;
    FEJQUERYSTORNOBIZONYLAT: TIBStringField;
    FEJQUERYSTORNOZOTTBIZONYLAT: TIBStringField;
    FEJQUERYPLOMBASZAM: TIBStringField;
    FEJQUERYNETTO: TIntegerField;
    FEJQUERYTRANZDIJ: TIntegerField;
    FEJQUERYKEZELESIDIJ: TIntegerField;
    FEJQUERYFIZETENDO: TIntegerField;
    FEJQUERYIDKOD: TIBStringField;
    FEJQUERYFIZETOESZKOZ: TSmallintField;
    FEJQUERYKONVERZIO: TSmallintField;
    FEJQUERYUGYFELCIM: TIBStringField;
    FEJQUERYADOSZAM: TIBStringField;
    FEJQUERYZCOUNTS: TIBStringField;
    FEJQUERYRECNUMS: TIBStringField;
    FEJQUERYKEREKITES: TSmallintField;
    FEJQUERYFORRAS: TIBStringField;
    FEJQUERYENGEDELYEZO: TIBStringField;
    OKMANYGOMB: TBitBtn;
    UGYADATPANEL: TPanel;
    ScrollBox1: TScrollBox;
    Shape7: TShape;
    Shape10: TShape;
    Shape11: TShape;
    Shape22: TShape;
    Shape23: TShape;
    Shape27: TShape;
    Shape29: TShape;
    Shape30: TShape;
    Shape31: TShape;
    Shape32: TShape;
    Shape33: TShape;
    Shape35: TShape;
    Shape36: TShape;
    Shape37: TShape;
    Shape38: TShape;
    Shape40: TShape;
    Shape41: TShape;
    Panel34: TPanel;
    Panel35: TPanel;
    Panel36: TPanel;
    Panel25: TPanel;
    Panel51: TPanel;
    Panel52: TPanel;
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
    Panel63: TPanel;
    Panel64: TPanel;
    Panel65: TPanel;
    Panel66: TPanel;
    Panel67: TPanel;
    Panel68: TPanel;
    Panel69: TPanel;
    Panel70: TPanel;
    Panel71: TPanel;
    Panel72: TPanel;
    Panel73: TPanel;
    Panel74: TPanel;
    Panel75: TPanel;
    Panel76: TPanel;
    Panel77: TPanel;
    Panel78: TPanel;
    Panel79: TPanel;
    Panel80: TPanel;
    DBEdit2: TDBEdit;
    DBEdit5: TDBEdit;
    DBEdit11: TDBEdit;
    DBEdit14: TDBEdit;
    DBEdit15: TDBEdit;
    DBEdit16: TDBEdit;
    DBEdit23: TDBEdit;
    DBEdit24: TDBEdit;
    DBEdit25: TDBEdit;
    DBEdit26: TDBEdit;
    DBEdit27: TDBEdit;
    DBEdit28: TDBEdit;
    DBEdit29: TDBEdit;
    DBEdit32: TDBEdit;
    DBEdit33: TDBEdit;
    BELKULEDIT: TEdit;
    KOZSZEREPLOEDIT: TEdit;
    TULAJPANEL: TPanel;
    tulfopanel: TPanel;
    Panel12: TPanel;
    TKOZSZERPANEL: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    BACKGOMB: TBitBtn;
    NEVEDIT: TEdit;
    ELOZOEDIT: TEdit;
    LAKCIMEDIT: TEdit;
    SZULHELYEDIT: TEdit;
    SZULIDOEDIT: TEdit;
    ALLAMPOLGEDIT: TEdit;
    TARTHELYEDIT: TEdit;
    ERDJELLEGEDIT: TEdit;
    ERDMERTEKEDIT: TEdit;
    MEGBIZOPANEL: TPanel;
    Label7: TLabel;
    Label8: TLabel;
    MZNEVPANEL: TPanel;
    MZANYJAPANEL: TPanel;
    MZSZULETESPANEL: TPanel;
    MZLAKCIMPANEL: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure FejrekordValtozott;
    procedure StornoKijelzo;
    procedure Ugyfelkijelzo;
    procedure MindentLezar;
    procedure SegedAdatBazisokatLezar;
    procedure MainapDisplay;
    function Setcondi(_css: byte): string;
    procedure Ujranyomtatas(Sender: TObject);
    function GetMegbizottszam: integer;

    procedure DatumKiertekeles(sender: TObject);
    function Nulele(_int: integer): string;
    procedure Panel6Click(Sender: TObject);
    procedure BlokktipusKijelzo;
    procedure Panel7Click(Sender: TObject);
    procedure NAPTARChange(Sender: TObject);
    procedure BLOKKFEJRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure BLOKKFEJRACSCellClick(Column: TColumn);
    procedure BLOKKFEJRACSDblClick(Sender: TObject);
    procedure PenztarBetoltes;
    procedure PenztarKijelzo(_pk: string);
    procedure ProsnevKijelzo;
    procedure TulajPanelsClear;

    function Blokkfejnyitas: integer;
    function ScanPenztar(_ptk: string): string;
    procedure Button1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure EGESZHONAPClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure VTempKitoltes;
    procedure INDOKEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure INDOKEDITExit(Sender: TObject);
    procedure GetReprintIndok;
    procedure DBEdit11Click(Sender: TObject);
    procedure LAKCIMCSIKClick(Sender: TObject);
    function HunDatetostr(_caldat: TDateTime): string;
    procedure TulajokKijelzese;
    procedure ForrasKijelzo;
    function GetOkmanyDarab: integer;
    procedure OKMANYGOMBClick(Sender: TObject);
    procedure TNEV1PANELClick(Sender: TObject);
  
    procedure BACKGOMBClick(Sender: TObject);
   
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BIZONYLATDISP: TBIZONYLATDISP;
  _height,_width: word;
  _honev: array[1..12] of string = ('január','február','március','április','május',
                 'június','július','augusztus','szeptember','október',
                 'november','december');

  _tnPanel,_tcpanel,_tpPanel: array[1..4] of TPanel;

  _sorveg: string = chr(13)+chr(10);
  _kertev,_kertho,_kertnap,_maiev,_maiho,_mainap: word;
  _kertDatum : TDateTime;
  _bizonylat,_mamas,_datumstring,_kertdatumstring,_farok,_aktdnem: string;
  _fejnev,_tetelnev,_pcs,_tipus,_ugyfeltipus,_ptarkod,_condition,_elojel: string;
  _bizonylatszam,_ttipus,_datum,_aktidos,_szallitonev,_plombaszam: string;
  _aktprosid,_aktpenztarosnev,_megjegyzes,_aktpenztarnev: string;
  _aktpenztarszam,_copyindok,_prosnev,_zcounts,_recnums: string;
  _mznev,_mzanyja,_mzszulhely,_mzszulido,_mzLakcim: string;

  _varos,_utca,_irszam,_lakcim,_forras,_engedo: string;

  _mai: boolean;
  _aktFejQuery,_aktTetelQuery: TIbQuery;
  _aktFejdbase,_aktTetelDbase: TibDatabase;
  _recno,_ugyfelszam,_storno,_megbizott,_bankjegy,_ertek: integer;
  _penztardarab,_arfolyam,_elszamarf,_fizetendo,_netto,_tetel,_tranzdij: integer;
  _tulajdarab,_kulfoldi,_kozszereplo,_securlevel,_megbizo,_bill: integer;
  _okmanydarab: word;

  _penztarkod,_penztarnev: array[1..150] of string;
  _rcondi: array[1..8] of TRadioButton;
  _aktCondi: byte;
  _csaknap: boolean;
  _cimDatPath: string = 'c:\valuta\aktcim.dat';


function supervisorjelszo(_para:integer):integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\valuta\bin\bloknyom.dll' name 'blokknyomtatas';
function bizonylattallozo: integer; stdcall;

function docdisprutin: integer; stdcall; external 'c:\valuta\bin\docdisp.dll' name 'docdisprutin';

implementation

{$R *.dfm}

// =============================================================================
               function bizonylattallozo: integer; stdcall;
// =============================================================================

begin
  Bizonylatdisp := TBizonylatDisp.Create(Nil);
  result := Bizonylatdisp.Showmodal;
  BizonylatDisp.Free;
end;


// =============================================================================
           procedure TBIZONYLATDISP.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  top     := trunc((_height-768)/2);
  Left    := trunc((_width-1024)/2);
  Height  := 768;
  Width   := 1024;

  if FileExists(_cimDatPath) then Sysutils.DeleteFile(_cimDatPath);

  _tnpanel[1] := tnev1panel;
  _tcpanel[1] := tcim1panel;
  _tpPanel[1] := Tap1panel;

  _tnpanel[2] := tnev2panel;
  _tcpanel[2] := tcim2panel;
  _tpPanel[2] := Tap2panel;

  _tnpanel[3] := tnev3panel;
  _tcpanel[3] := tcim3panel;
  _tpPanel[3] := Tap3panel;

  _tnpanel[4] := tnev4panel;
  _tcpanel[4] := tcim4panel;
  _tpPanel[4] := Tap4panel;

  Lakcimcsik.visible := false;
  PenztarPanel.visible := false;
  SzuroPanel.Visible   := false;
  CopyPanel.Visible := false;
  RR1.Checked := TRUE;
  _aktcondi := 1;
  _copyindok := '';

  _rcondi[1] := rr1;
  _rcondi[2] := rr2;
  _rcondi[3] := rr3;
  _rcondi[4] := rr4;
  _rcondi[5] := rr5;
  _rcondi[6] := rr6;
  _rcondi[7] := rr7;
  _rcondi[8] := rr8;


  _maiev  := yearof(date);
  _maiho  := monthof(date);
  _mainap := dayof(date);
  _mamas  := Hundatetostr(Date);

  Naptar.CalendarDate := date;
  PenztarBetoltes;

  Naptarchange(Nil);

  BizonylatTipusPanel.Caption := '';
  stornoPanel.caption := '';

  DatumKiertekeles(Nil);
end;

// =============================================================================
         procedure TBizonylatdisp.DatumKiertekeles(sender: TObject);
// =============================================================================

begin
  MindentLezar;

  _kertev := Naptar.Year;
  _kertho := Naptar.Month;
  _kertnap:= Naptar.day;
  _kertDatum := Naptar.CalendarDate;
  _kertdatumstring := Hundatetostr(_kertdatum);

  if _kertDatum>date then
    begin
      Showmessage('A KÉRT NAP MÉG A JÖVÕBEN VAN');
      exit;
    end;

  _mai := False;
  if _kertDatum=date then
   begin
      Mainapdisplay;
      exit;
    end;


  _farok    := inttostr(_kertev-2000)+nulele(_kertho);
  _fejnev   := 'BF' + _farok;
  _tetelnev := 'BT' + _farok;

  BlokkfejRacs.DataSource := BlokkfejSource;
  BlokkTetelRacs.DataSource := BlokktetelSource;

  HavifejTabla.close;
  HavifejDbase.connected := true;

  HavifejTabla.TableName := _fejnev;
  if not Havifejtabla.Exists then
    begin
      HavifejDbase.close;
      ShowMessage('Nincs adat a kért hónapról');
      exit;
    end;

  _aktfejQuery := haviFejQuery;
  _aktfejDbase := haviFejDbase;

  _aktTetelQuery := HavitetelQuery;
  _aktTetelDbase := HaviTetelDbase;

  _condition := Setcondi(_aktcondi);

  _pcs := 'SELECT * FROM ' + _fejnev;

  if _csaknap then
    begin
      _pcs := _pcs + _sorveg +'WHERE (DATUM=' + chr(39) + _kertdatumstring + chr(39) + ')';
      if _conditIon<>'' then _pcs := _pcs + ' AND ('+ _condition + ')'+ _sorveg
      else _Pcs := _pcs + _sorveg;
    end;

  if not _csaknap then
    begin
      _pcs := _pcs + _sorveg;
      if _condition<>'' then _pcs := _pcs + 'WHERE ' + _condition + _sorveg;
    end;

  _pcs := _pcs + 'ORDER BY DATUM,IDO';

  _aktfejdbase.Connected := True;
  with _aktFejQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      _aktFejquery.close;
      _aktFejdbase.close;
      ShowMessage('A kért napról nincsenek adataim az adott feltételek mellett!');
      exit;
    end;

  FejrekordValtozott;

  ActiveControl := BlokkFejracs;
  Blokkfejracs.SetFocus;
end;


function TBizonylatDisp.Setcondi(_css: byte): string;

begin
  result := '';
  case _css of
    1: result := '';
    2: result := 'UGYFELSZAM>0';
    3: result := 'TIPUS='+chr(39)+'V'+chr(39);
    4: result := 'TIPUS='+chr(39)+'E'+chr(39);
    5: result := 'TIPUS='+chr(39)+'K'+chr(39);
    6: result := 'TIPUS='+chr(39)+'F'+chr(39);
    7: result := 'TIPUS='+chr(39)+'U'+chr(39);
    8: result := 'STORNO>1';
  end;
end;




// =============================================================================
                   procedure TBizonylatDisp.FejrekordValtozott;
// =============================================================================

begin
  TulajPanelsClear;
  PenztarPanel.visible := False;
  SegedAdatBazisokatLezar;
  BelKulEdit.Text := '';
  Belkuledit.repaint;
  Kozszereploedit.text := '';
  Kozszereploedit.repaint;

  _megbizott   := 0;
  _megbizo     := 0;

  _bizonylat   := _aktFejquery.Fieldbyname('BIZONYLATSZAM').asstring;
  if _mai then
      _fizetendo:= _aktFejQuery.FieldByNAme('OSSZESFORINTERTEK').asInteger
      else _fizetendo := _aktfejquery.FieldByNAme('FIZETENDO').asInteger;
  _tipus       := _aktfejQuery.FieldByNAme('TIPUS').asString;
  _ugyfelszam  := _aktfejQuery.FieldByNAme('UGYFELSZAM').asInteger;
  _ugyfeltipus := _aktFejquery.FieldByName('UGYFELTIPUS').asstring;
  _storno      := _aktfejQuery.fieldByName('STORNO').asInteger;
  _ptarkod     := trim(_aktfejquery.FieldByName('TARSPENZTARKOD').ASsTRING);
  _prosnev     := trim(_aktfejquery.FieldByName('PENZTAROSNEV').asString);
  _zcounts     := trim(_aktfejQuery.FieldByName('ZCOUNTS').asString);
  _recnums     := trim(_aktFejQuery.FieldByName('RECNUMS').AsString);
  _forras      := trim(_aktFejquery.FieldByName('FORRAS').asString);
  _engedo      := trim(_aktFejquery.FieldByNAme('ENGEDELYEZO').AsString);
  _megbizo     := _aktfejQuery.FieldByNAme('MEGBIZOSZAM').asInteger;
 
  OkmanyGomb.Enabled := false;


  BlokktipusKijelzo;
  StornoKijelzo;
  ProsnevKijelzo;
  ForrasKijelzo;
  if (_tipus='F') or (_tipus='U') then PenztarKijelzo(_ptarkod)
  else Ugyfelkijelzo;

  if (_ugyfeltipus='N') OR (_ugyfeltipus='J') then
    begin
      _okmanyDarab := GetOkmanyDarab;
      if (_okmanydarab>0) and (_fizetendo>=100000) then Okmanygomb.Enabled := True;
    end;

  _pcs := 'SELECT * FROM ' + _tetelnev + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_bizonylat + chr(39);

  _akttetelDbase.Connected := true;
  with _aktTetelQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;
end;


procedure TBizonylatdisp.ForrasKijelzo;

begin
  ForrasEdit.text := _forras;
  Engededit.text := _engedo;
end;


// =============================================================================
            procedure TBizonylatDisp.PenztarKijelzo(_pk: string);
// =============================================================================

var _pknev: string;

begin
  if _pk='' then
    begin
      PenztarPanel.visible := False;
      exit;
    end;

  _pknev := ScanPenztar(_pk);

  if _pknev='' then
       begin
         PenztarPanel.visible := False;
         exit;
       end;

  if _tipus='F' then IranyNevPanel.caption := 'Átvevõ pénztár'
  else IranynevPanel.caption := 'Átadó pénztár';

  Penztarszampanel.caption := _pk;
  PenztarnevPanel.caption := _pknev;

  with PenztarPanel do
    begin
      Top := 390;
      Left := 616;
      Visible := true;
      Repaint;
    end;
end;

// =============================================================================
           procedure TBIZONYLATDISP.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  MindentLezar;
  Modalresult := 1;
end;


// =============================================================================
            function TBizonylatdisp.Nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


// =============================================================================
          procedure TBIZONYLATDISP.Panel6Click(Sender: TObject);
// =============================================================================

begin
  TulajPanel.Visible := false;
  Naptar.PrevMonth;
end;

// =============================================================================
          procedure TBIZONYLATDISP.Panel7Click(Sender: TObject);
// =============================================================================

begin
  Tulajpanel.visible := false;
  Naptar.NextMonth;
end;

// =============================================================================
            procedure TBIZONYLATDISP.NAPTARChange(Sender: TObject);
// =============================================================================

var _nev,_nho,_nnap: word;

begin
  TulajPanel.Visible := false;
  _nev := Naptar.Year;
  _nHo := Naptar.Month;
  _nnap:= Naptar.Day;

  _datumstring := inttostr(_nev)+' '+_honev[_nho] + ' '+inttostr(_nnap);
  DatumPanel.Caption := _datumstring;
  Datumpanel.Repaint;
end;


// =============================================================================
            procedure TBizonylatDisp.BlokktipusKijelzo;
// =============================================================================

var _tips,_nyugtastring: string;

begin
  if _tipus='V' then _tips := 'Valuta vétel bizonylat';
  if _tipus='E' then _tips := 'Valuta eladás bizonylat';
 
  if _tipus='F' then
    begin
      if leftstr(_bizonylat,2)='FF' then _tips := 'Forint átadási bizonylat'
      else _tips := 'Valuta átadási bizonylat';
    end;

  if _tipus='U' then
    begin
      if leftstr(_bizonylat,2)='UF' then _tips := 'Forint átvétel bizonylat'
      else _tips := 'Valuta átvételi bizonylat';
    end;

  BizonylatTipusPanel.caption := _tips;
  BizonylatTipusPanel.repaint;
  _nyugtastring := '';
  if _zcounts<>'' then _nyugtastring := _zcounts+'/'+_recnums;
  NavPanel.Caption := _nyugtastring;
  NavPanel.Repaint;
end;


// =============================================================================
procedure TBizonylatDisp.StornoKijelzo;
// =============================================================================

begin
  if _storno=1 then StornoPanel.caption := '';
  if _storno=2 then  StornoPanel.caption := 'Stornózott bizonylat !';
  if _storno=3 then  StornoPanel.caption := 'Stornó bizonylat !';
  if _storno=4 then StornoPanel.caption := 'Rontott bizonylat !';
  StornoPanel.repaint;
end;


procedure TBizonylatdisp.ProsnevKijelzo;

begin
  Prosnevpanel.caption := _prosnev;
  ProsnevPanel.repaint;
end;


// =============================================================================
procedure TBIZONYLATDISP.BLOKKFEJRACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
// =============================================================================

var _bill: integer;

begin
  _bill:= ord(key);
  if (_bill>32) AND (_bill<41) then
    begin
      Fejrekordvaltozott;
      exit;
    end;
end;


// =============================================================================
                     procedure TBizonylatDisp.UgyfelKijelzo;
// =============================================================================

begin
  MegbizoPanel.visible := False;

  _lakcim := '??';
  if _ugyfelszam=0 then
    begin
      UgyfelSource.enabled := false;
      Jogisource.enabled := False;
      exit;
    end;

  if (_ugyfeltipus='N') or (_ugyfeltipus='K') then
    begin
      if _megbizo>0 then
        begin
          _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_megbizo);
          Ugyfeldbase.Connected := True;
          with Ugyfelquery do
            begin
              Close;
              sql.clear;
              sql.Add(_pcs);
              Open;
              _recno := recno;
            end;
          if _recno>0 then
            begin
              _mznev := trim(Ugyfelquery.FieldByNAme('NEV').AsString);
              _mzanyja := trim(UgyfelQuery.FieldByNAme('ANYJANEVE').asString);
              _mzszulhely := trim(Ugyfelquery.FieldByNAme('SZULETESIHELY').AsString);
              _mzSzulido := UgyfelQuery.fieldByNAme('SZULETESIIDO').asString;
              _mzlakcim := trim(Ugyfelquery.fieldByNAme('LAKCIM').asString);
              MzNevpanel.Caption := _mznev;
              MzAnyjaPanel.Caption := _mzAnyja;
              MzSzuletesPanel.caption := _mzszulido+' '+_mzszulhely;
              MzLakcimPanel.caption := _mzLakcim;
              with MegbizoPanel do
                begin
                  top := 392;
                  left := 616;
                  Visible := true;
                  repaint;
                end;
            end;
        end;

      _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
      Ugyfeldbase.connected := true;

      with Ugyfelquery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          _kulfoldi := FieldByName('KULFOLDI').asInteger;
          _kozszereplo := FieldByName('KOZSZEREPLO').asInteger;
        end;

      if _kulfoldi=1 then Belkuledit.Text := 'KÜLFÖLDI ÜGYFÉL'
      else Belkuledit.Text := 'BELFÖLDI ÜGYFÉL';
      Belkuledit.Repaint;

      if _kozszereplo<1 then KOZszereploedit.Text := 'NEM KIEMELT KÖZSZEREPLÕ'
      else KozSzereploEdit.text := 'KIEMELT KÖZSZEREPLÕ';
      KozSzereploedit.repaint;

      Ugyfelsource.enabled := true;
      exit;
    end;

  if _ugyfeltipus = 'J' then
    begin
      _megbizott := Getmegbizottszam;
      if _megbizott>0 then
         begin
           _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
           _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_megbizott);
           Ugyfeldbase.Connected := true;
           with UgyfelQuery do
             begin
               close;
               sql.clear;
               sql.Add(_pcs);
               Open;
               _kulfoldi := FieldByName('KULFOLDI').asInteger;
               _kozszereplo := FieldByName('KOZSZEREPLO').asInteger;
             end;

           if _kulfoldi=1 then Belkuledit.Text := 'KÜLFÖLDI ÜGYFÉL'
           else Belkuledit.Text := 'BELFÖLDI ÜGYFÉL';
           Belkuledit.Repaint;

           if _kozszereplo<1 then KozSzereploedit.Text := 'NEM KIEMELT KÖZSZEREPLÕ'
           else Kozszereploedit.text := 'KIEMELT KÖZSZEREPLÕ';
           Kozszereploedit.repaint;
           Ugyfelsource.Enabled := true;
         end;

      TulajokKijelzese;

    end;
end;


procedure TBIZONYLATDISP.TulajokKijelzese;

var _ss: byte;
    _tNev,_tCim,_taPolg: string;

begin
  _pcs := 'SELECT * FROM UJTULAJOK' + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_ugyfelszam);

  Tulajdbase.connected := true;
  with Tulajquery do
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
      TulajQuery.close;
      Tulajdbase.close;
      exit;
    end;

  while not TulajQuery.eof do
    begin
      _ss := TulajQuery.FieldByName('SORSZAM').asInteger;
      _tnev := trim(Tulajquery.FieldbyNAme('TULAJNEV').asstring);
      _tcim := trim(Tulajquery.FieldbyNAme('LAKCIM').asstring);
      _tAPOLG := trim(Tulajquery.FieldbyNAme('ALLAMPOLGAR').asstring);
      _tnpanel[_ss].Caption := _tnev;
      _tnPanel[_ss].Enabled := true;
      _tcPanel[_ss].Caption := _tCim;
      _tpPanel[_ss].caption := _tapolg;
      TulajQuery.next;
    end;
  Tulajquery.close;
  Tulajdbase.close;
end;

procedure TBIZONYLATDISP.TulajPanelsClear;

var _y: byte;

begin
  Tulajpanel.Visible := false;
  _y := 1;
  while _y<=4 do
    begin
      _tnPanel[_y].Caption := '';
      _tnpanel[_y].Enabled := false;
      _tcPanel[_y].Caption := '';
      _tpPanel[_y].Caption := '';
      inc(_y);
    end;
end;






// =============================================================================
       procedure TBIZONYLATDISP.BLOKKFEJRACSCellClick(Column: TColumn);
// =============================================================================

begin
  FejRekordValtozott;
end;

// =============================================================================
         procedure TBIZONYLATDISP.BLOKKFEJRACSDblClick(Sender: TObject);
// =============================================================================

begin
  FejrekordValtozott;
end;

// =============================================================================
                   procedure TBizonylatDisp.MindentLezar;
// =============================================================================

begin
  if Fejquery.Active then Fejquery.close;
  if fejdbase.Connected then fejdbase.close;

  if TetelQuery.Active then TetelQuery.close;
  if TetelDbase.connected then TetelDbase.close;

  if HaviFejQuery.Active then HavifejQuery.close;
  if HaviFejDbase.connected then Havifejdbase.close;

  if HaviTetelQuery.Active then HaviTetelQuery.close;
  if Haviteteldbase.connected then HavitetelDbase.close;

  SegedAdatbazisokatLezar;

end;

// =============================================================================
            procedure TBizonylatDisp.SegedAdatBazisokatLezar;
// =============================================================================

begin

  if UgyfelQuery.Active then Ugyfelquery.close;
  if Ugyfeldbase.connected then Ugyfeldbase.close;

  if JogiQuery.Active then Jogiquery.close;
  if Jogidbase.connected then JogiDbase.close;

  if TulajQuery.Active then TulajQuery.close;
  if Tulajdbase.connected then Tulajdbase.close;

  UgyfelSource.Enabled := False;
  Jogisource.Enabled := False;
  

end;


// =============================================================================
                 procedure TBizonylatDisp.MainapDisplay;
// =============================================================================

begin

  Csaknap.Checked := true;
  _csakNap := True;

  _aktfejQuery := FejQuery;
  _aktfejDbase := FejDbase;

  _aktTetelQuery := TetelQuery;
  _aktTetelDbase := TetelDbase;

  _tetelnev := 'BLOKKTETEL';
  _recno := Blokkfejnyitas;

  if _recno=0 then
    begin
      Fejquery.close;
      Fejdbase.close;
      ShowMessage('A kért napról nincsenek adataim !');
      exit;
    end;

  _mai := True;
  BlokkfejRacs.DataSource   := FejSource;
  BlokkTetelRacs.DataSource := TetelSource;

  FejrekordValtozott;

  ActiveControl := BlokkFejracs;
  Blokkfejracs.SetFocus;
end;



function TBizonylatDisp.BlokkfejNyitas: integer;

begin
  _csaknap := true;
  Csaknap.Checked := true;

  _condition := Setcondi(_aktcondi);

  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;

  if _condition<>'' then  _pcs := _pcs + 'WHERE '+_condition + _sorveg;
  _pcs := _pcs + 'ORDER BY IDO';

  fEJdbase.connected := true;
  with fEJQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      result := recno;
    end;
end;

procedure TBizonylatdisp.PenztarBetoltes;

var _ptkod,_ptnev: string;

begin
  Penztardbase.Connected := true;
  with PenztarQuery do
    begin
      close;
      sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      First;
    end;

  _penztardarab := 0;
  while not PenztarQuery.eof do
    begin
      _ptkod := trim(PenztarQuery.FieldByName('PENZTARKOD').asString);
      _ptnev := trim(PenztarQuery.FieldByName('PENZTARNEV').asString);
      inc(_penztardarab);

      _penztarkod[_penztardarab] := _ptkod;
      _penztarnev[_penztardarab] := _ptnev;

      PenztarQuery.next;
    end;
  PenztarQuery.close;
  Penztardbase.close;
end;

function TBizonylatdisp.ScanPenztar(_ptk: string): string;

var _y: byte;

begin
  result := '';
  _y := 1;
  while _y<=_penztardarab do
    begin
      if _penztarkod[_y]=_ptk then
        begin
          result := _penztarnev[_y];
          exit;
        end;
      inc(_y);
    end;
end;



procedure TBIZONYLATDISP.Button1Click(Sender: TObject);
begin
  with szuropanel do
    begin
      Left := 48;
      Top  := 128;
      Visible := true;
    end;
end;


procedure TBIZONYLATDISP.BitBtn1Click(Sender: TObject);

var i: integer;

begin
  _aktcondi := 0;
  for i := 1 to 8 do
    begin
      if _rcondi[i].Checked then
        begin
          _aktcondi := i;
          break;
        end;
    end;
  szuropanel.Visible := false;
  if _aktcondi=1 then Blokkfejpanel.caption := 'Blokkfejek'
  else BlokkfejPanel.caption := 'Blokkfejek (szûrve)';
  BlokkfejPanel.Repaint;
  DatumKiertekeles(Nil);
end;

procedure TBIZONYLATDISP.EGESZHONAPClick(Sender: TObject);
begin
  if Naptar.CalendarDate=Date then
    begin
      Csaknap.Checked := true;
      _csaknap := true;
      exit;
    end;
  _csaknap := false;
  Datumkiertekeles(Nil);

end;

procedure TBizonylatDisp.Ujranyomtatas(Sender: TObject);

var _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  GetReprintIndok;
end;

// =============================================================================
                 procedure TBizonylatdisp.GetReprintIndok;
// =============================================================================


begin
  Indokedit.clear;
  with CopyPanel do
    begin
      Top := 200;
      Left := 80;
      Visible := True;
    end;
  Activecontrol := indokedit;
end;




// =============================================================================
                      procedure TBizonylatdisp.VtempKitoltes;
// =============================================================================

var _tt: integer;
    _mezo,_tnev: string;
    
begin
  _ugyfelszam  := 0;

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _aktTetelQuery.first;
  while not _aktTetelQuery.Eof do
    begin
      with _aktTetelQuery do
        begin
          _aktdnem   := FieldByName('VALUTANEM').asstring;
          _bankjegy  := FieldByName('BANKJEGY').asInteger;
          _ertek     := FieldByName('FORINTERTEK').asInteger;
          _elojel    := FieldByName('ELOJEL').asstring;
          _arfolyam  := FieldByName('ARFOLYAM').asInteger;
          _elszamarf := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
        end;

      _pcs := 'INSERT INTO VTEMP (VALUTANEM,ARFOLYAM,ELSZAMOLASIARFOLYAM,';
      _pcs := _pcs + 'BANKJEGY,FORINTERTEK,ELOJEL)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_arfolyam) + ',';
      _pcs := _pcs + inttostr(_elszamarf)+',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_ertek) + ',';
      _pcs := _pcs + chr(39) + _elojel + chr(39) + ')';
      ValutaParancs(_pcs);

      _akttetelQuery.next;
    end;

  _akttetelquery.first;

  // ---------------------------------------------------------------------------

  with _aktFejquery do
    begin
      _bizonylatszam  := FieldByName('BIZONYLATSZAM').asstring;
      _ttipus         := FieldByName('TIPUS').asstring;
      _datum          := FieldByName('DATUM').asstring;
      _aktidos        := FieldByName('IDO').asstring;
      _fizetendo      := FieldByName('FIZETENDO').asInteger;
      _netto          := FieldByName('OSSZESFORINTERTEK').asInteger;
      _ugyfeltipus    := FieldByName('UGYFELTIPUS').asstring;
      _ugyfelszam     := FieldByName('UGYFELSZAM').asInteger;
      _tetel          := FieldByName('TETEL').asInteger;
      _aktpenztarszam := FieldByName('TARSPENZTARKOD').asstring;
      _megbizo        := FieldByName('MEGBIZOSZAM').asInteger;
      _storno         := FieldByName('STORNO').asInteger;
      _tranzdij       := FieldByNAme('KEZELESIDIJ').asInteger;
  //    _szallitonev    := FieldByName('SZALLITONEV').asString;
      _plombaszam     := FieldByName('PLOMBASZAM').asstring;
      _zcounts        := trim(FieldByName('ZCOUNTS').asString);
      _recnums        := trim(FieldByName('RECNUMS').AsString);
    end;

 _securlevel := 0;

 if _fizetendo>=500000 then _securlevel := 1;

  _tulajdarab := 0;
  if _ugyfeltipus='J' then
    begin

      if tulajQuery.recno>0 then
        begin
          _tt := 4;
          while _tt>0 do
            begin
              _mezo := 'TULAJ'+CHR(48+_TT);
              _tnev := trim(TulajQuery.FieldByName(_mezo).asstring);
              if _tnev<>'' then
                begin
                  _tulajdarab := _tt;
                  break;
                end;
              dec(_tt);
            end;
        end;
    end;

  _pcs := 'UPDATE VTEMP SET NETTO='+inttostr(_netto);
  _pcs := _pcs + ',FIZETENDO='+inttostr(_fizetendo);
  _pcs := _pcs + ',BIZONYLATSZAM=' + chr(39) + _bizonylatszam + chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _datum + chr(39);
  _pcs := _pcs + ',TIPUS=' + chr(39) + _ttipus + chr(39);
  _pcs := _pcs + ',OSSZESFORINTERTEK=' + inttostr(_netto);
  _pcs := _pcs + ',IDO=' + chr(39) + leftstr(_aktidos,5) + chr(39);
  _pcs := _pcs + ',TETEL=' + inttostr(_tetel);
  _pcs := _pcs + ',KEZELESIDIJ=' + inttostr(_tranzdij);
  _pcs := _pcs + ',KULFOLDI=' + inttostr(_kulfoldi);
  _pcs := _pcs + ',ZCOUNTS=' + chr(39) + _zCounts + chr(39);
  _pcs := _pcs + ',RECNUMS=' + chr(39) + _recnums + chr(39);
  if _kulfoldi>0 then _pcs := _pcs + ',KOZSZEREPLO='+inttostr(_kozszereplo);
  _pcs := _pcs + ',STORNO=' + inttostr(_storno);
  _pcs := _pcs + ',UGYFELSZAM=' + inttostr(_ugyfelszam);
  _pcs := _pcs + ',UGYFELTIPUS=' + chr(39) + _ugyfeltipus + chr(39);
  if _ugyfeltipus='J' then
      _pcs := _pcs + ',TULAJDONOS=' + inttostr(_tulajdarab);
  if _copyindok<>'' then _pcs := _pcs +',COPYINDOK='+chr(39)+leftstr(_copyindok,10)+chr(39);
  _pcs := _pcs + ',IDKOD=' + chr(39)+_aktprosid + chr(39);
  _pcs := _pcs + ',PENZTAROSNEV='+chr(39)+_aktPenztarosnev+chr(39);
  if _megbizo>0 then _pcs := _pcs + ',MEGBIZOSZAM='+inttostr(_megbizo);

  if (_ttipus='U') OR (_ttipus='F') then
    begin
      _pcs := _pcs + ',PENZTARKOD='+CHR(39) +_aktPenztarszam+chr(39);
   //   _pcs := _pcs + ',SZALLITONEV='+chr(39) + _szallitonev+chr(39);
      _pcs := _pcs + ',PLOMBASZAM='+chr(39) + _plombaszam+chr(39);
      _PCS := _pcs + ',TARSPENZTARNEV=' + chr(39) + _aktpenztarnev + chr(39);
      if _megjegyzes<>'' then _pcs := _pcs + ',MEGJEGYZES='+chr(39)+_MEGJEGYZES+CHR(39);
    end;
  ValutaParancs(_pcs);

  _pcs := 'DELETE FROM PARTNERPARA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO PARTNERPARA (UGYFELTIPUS,UGYFELSZAM,SECURLEVEL,MEGBIZO,';
  _pcs := _pcs + 'MEGBIZOTT,KULFOLDI,TULAJDARAB,STATUSZ)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+ _ugyfeltipus+chr(39)+',';
  _pcs := _pcs +  inttostr(_ugyfelszam)+',';
  _pcs := _pcs + inttostr(_securlevel) + ',';
  _pcs := _pcs + inttostr(_megbizo) + ',';
  _pcs := _pcs + inttostr(_megbizott) + ',';
  _pcs := _pcs + inttostr(_kulfoldi) + ',';
  _pcs := _pcs + inttostr(_tulajdarab) + ',';
  _pcs := _pcs + inttostr(_kozszereplo)+')';
  ValutaParancs(_pcs);

end;

procedure TBizonylatdisp.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := true;
  if Valutatranz.InTransaction then Valutatranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      CLose;
      Sql.clear;
      sql.Add(_pcs);
      Execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;


procedure TBIZONYLATDISP.INDOKEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var 
    _pp : byte;

begin
  _bill := ord(key);
  if (_bill<>13) then exit;
  _copyindok := trim(Indokedit.Text);
  if _copyIndok='' then
    begin
      Activecontrol := Blokkfejracs;
      exit;
    end;
  Vtempkitoltes;

  _pp := 11;
  if _copyindok='@' then _pp := 1;

  blokknyomtatas(_pp);
  Activecontrol := Blokkfejracs;
end;

procedure TBIZONYLATDISP.INDOKEDITExit(Sender: TObject);
begin
  CopyPanel.Visible := false;
end;



procedure TBIZONYLATDISP.DBEdit11Click(Sender: TObject);
var _LC: string;
begin
   if not UgyfelQuery.Active then exit;
  _LC := TRIM(UgyfelQuery.FieldByName('LAKCIM').asString);
  Lakcimcsik.Caption := _Lc;
  Lakcimcsik.Visible := true;
end;

procedure TBIZONYLATDISP.LAKCIMCSIKClick(Sender: TObject);
begin
   Lakcimcsik.Visible := false;
end;


function TBizonylatdisp.HunDatetostr(_caldat: TDateTime): string;
var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;

// =============================================================================
             function TBizonylatdisp.GetMegbizottszam: integer;
// =============================================================================

begin
  result := 0;
  _pcs := 'SELECT * FROM JOGISZEMELY' + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+INTTOSTR(_UGYFELSZAM);

  Jogidbase.connected := true;
  with Jogiquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then result := JogiQuery.FieldByname('MEGBIZOTTSZAMA').asInteger;
  Jogisource.Enabled := True;

end;

function TBizonylatDisp.GetOkmanyDarab: integer;

var _usz,_nev,_minta: string;
    _srec: TSearchRec;

begin
  _usz := inttostr(_ugyfelszam);
  if _ugyfeltipus='J' then _usz := inttostr(_megbizott);

  result := 0;
  _minta := 'c:\valuta\scans\' + _usz + '\*.jpg';
  if FindFirst(_minta,faAnyFile,_srec) = 0 then
    begin
      repeat
        _nev := _srec.name;
        inc(result);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
end;


procedure TBIZONYLATDISP.OKMANYGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (UGYFELTIPUS,UGYFELSZAM)'+_SORVEG;
  _PCS := _PCS + 'VALUES (' + chr(39)+'N'+chr(39)+',';
  if _ugyfeltipus='N' then _pcs := _pcs + inttostr(_ugyfelszam)+')'
  else _pcs := _pcs + inttostr(_megbizott)+')';
  ValutaParancs(_pcs);

  docdisprutin;
end;

procedure TBIZONYLATDISP.TNEV1PANELClick(Sender: TObject);

var _tulss,_tkozszer: byte;
    _tnev,_telozo,_tlakcim,_tszulhely,_tszulido,_tallamp,_ttarthely: string;
    _terdjelleg,_terdmertek: string;


begin

  _tulss := Tpanel(sender).Tag;
  _pcs := 'SELECT * FROM UJTULAJOK' + _sorveg;
  _pcs := _pcs + 'WHERE (UGYFELSZAM='+inttostr(_ugyfelszam)+') AND ';
  _pcs := _pcs + '(SORSZAM=' + inttostr(_tulss)+')';

  Tulajdbase.Connected := true;
  with TulajQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno=0 then
    begin
      TulajQuery.Close;
      Tulajdbase.close;
      exit;
    end;

  TulfoPanel.Caption := inttostr(_tulss)+'. TULAJDONOS';
  Tulfopanel.Repaint;

  with Tulajquery do
    begin
      _tNev    := trim(FieldByName('TULAJNEV').AsString);
      _telozo  := trim(FieldByNAme('ELOZONEV').AsString);
      _tlakcim := trim(FieldByNAme('LAKCIM').asString);
      _tszulhely:= trim(FieldByNAme('SZULHELY').AsString);
      _tSzulido := trim(FieldByNAme('SZULIDO').AsString);
      _tallamp := trim(FieldByNAme('ALLAMPOLGAR').AsString);
      _ttarthely:= trim(FieldByNAme('TARTHELY').AsString);
      _terdjelleg := trim(FieldByNAme('ERDJELLEG').asString);
      _terdmertek := trim(FieldByNAme('ERDMERTEK').asstring);
      _tkozszer := FieldByNAme('TULKOZSZEREP').asInteger;
      Close;
    end;
  Tulajdbase.close;

  Nevedit.Text := _tnev;
  Elozoedit.Text := _telozo;
  Lakcimedit.Text := _tLakcim;
  Szulhelyedit.Text := _tszulhely;
  Szulidoedit.Text := _tszulido;
  Allampolgedit.Text := _tallamp;
  Tarthelyedit.text := _ttarthely;
  erdjellegedit.Text := _terdjelleg;
  erdmertekedit.Text := _terdmertek;
  if _tkozszer=0 then TKozszerPanel.Caption := 'NEM KIEMELT KOZSZEREPLÕ'
  else TKozszerPanel.Caption := 'KIEMELT KÖZSZERELÕ ('+inttostr(_tkozszer)+')';
  TKozszerPanel.Repaint;
  with TulajPanel do
    begin
      top := 288;
      left :=8;
      Visible := True;
      repaint;
    end;
  Activecontrol := BackGomb;    
end;

procedure TBIZONYLATDISP.BACKGOMBClick(Sender: TObject);
begin
  Tulajpanel.Visible := False; 
end;



end.
