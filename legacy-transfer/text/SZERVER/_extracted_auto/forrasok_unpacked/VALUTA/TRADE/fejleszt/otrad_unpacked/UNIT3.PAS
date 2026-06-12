unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, Buttons, IBDatabase, DB,
  IBCustomDataSet, IBQuery, StrUtils,DateUtils, unit1, Grids, Calendar,
  ComCtrls, DBGrids;

type
  TAUTOPALYAFORM = class(TForm)
    MATRICAIMAGE: TImage;
    AKTEVLABEL: TPanel;
    IBQuery: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTranz: TIBTransaction;
    MUNKAPANEL: TPanel;
    PENZTARSZAMPANEL: TPanel;
    PENZTARNEVPANEL: TPanel;
    MATRICATIPUSPANEL: TPanel;
    PENZTAROSPANEL: TPanel;
    Bevel1: TBevel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    JOVAHAGYOGOMB: TBitBtn;
    MATRICACANCELGOMB: TBitBtn;
    NAPTAR: TCalendar;
    DATUMVISSZAGOMB: TBitBtn;
    datumeloregomb: TBitBtn;
    NAPTARHOPANEL: TPanel;
    EVPANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    TOLEVPANEL: TPanel;
    IGEVPANEL: TPanel;
    TOLHOPANEL: TPanel;
    IGHOPANEL: TPanel;
    TOLNAPPANEL: TPanel;
    IGNAPPANEL: TPanel;
    TOLNAPNEVPANEL: TPanel;
    IGNAPNEVPANEL: TPanel;
    TOLPERCPANEL: TPanel;
    Panel9: TPanel;
    Label4: TLabel;
    Label6: TLabel;
    rendszamedit: TEdit;
    Label7: TLabel;
    rrendszamedit: TEdit;
    Label8: TLabel;
    FIZETENDOPANEL: TPanel;
    VEGTAKARO: TPanel;
    Label9: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    TEVPANEL: TPanel;
    IHOPANEL: TPanel;
    THOPANEL: TPanel;
    ORAPERCPANEL: TPanel;
    THNAPPANEL: TPanel;
    TNAPPANEL: TPanel;
    IEVPANEL: TPanel;
    INAPPANEL: TPanel;
    IHNAPPANEL: TPanel;
    Panel21: TPanel;
    KONYVELOGOMB: TBitBtn;
    NEMKONYVELOGOMB: TBitBtn;
    KILEPOTIMER: TTimer;
    ORSZAGCOMBO: TComboBox;
    Label5: TLabel;
    FELSEGPANEL: TPanel;
    RENDSZAMPANEL: TPanel;
    KIFIZETENDOPANEL: TPanel;
    TRANSCANCELTIMER: TTimer;
    CONFIRMGOMB: TBitBtn;
    KUDARCPANEL: TPanel;
    TOVABBGOMB: TBitBtn;
    Panel2: TPanel;
    HIBAPANEL: TPanel;
    VISSZAIGAZOLOPANEL: TPanel;
    Panel1: TPanel;
    LIVEAAKGOMB: TBitBtn;
    CANCELAAKGOMB: TBitBtn;
    RETURNGOMB: TBitBtn;
    SIKERBANER: TLabel;
    UGYFELPANEL: TPanel;
    Label17: TLabel;
    UJUGYFELGOMB: TBitBtn;
    TORZSUGYFELGOMB: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    NEVBEKEROPANEL: TPanel;
    Label18: TLabel;
    Label19: TLabel;
    NEVEDIT: TEdit;
    CIMEDIT: TEdit;
    UGYFELOKEGOMB: TBitBtn;
    NINCSNEVGOMB: TBitBtn;
    UGYFELVALASZTOPANEL: TPanel;
    Label20: TLabel;
    UGYFELRACS: TDBGrid;
    UGYFELSOURCE: TDataSource;
    VALASZTOGOMB: TBitBtn;
    NEMVALASZTOGOMB: TBitBtn;
    AFASPANEL: TPanel;
    Label21: TLabel;
    NEMKERAFASTGOMB: TBitBtn;
    AFASTKERGOMB: TBitBtn;
    RANGEPANEL: TPanel;
    Shape4: TShape;
    Shape5: TShape;
    Shape6: TShape;
    Shape7: TShape;
    MEGYECSIK: TPanel;
    ALAPLAP: TPanel;
    Image11: TImage;
    Shape9: TShape;
    Shape10: TShape;
    Shape11: TShape;
    Shape12: TShape;
    Shape13: TShape;
    Shape14: TShape;
    Shape15: TShape;
    Shape16: TShape;
    Shape17: TShape;
    Shape18: TShape;
    Panel8: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    Panel26: TPanel;
    Panel27: TPanel;
    Panel30: TPanel;
    Panel31: TPanel;
    Panel32: TPanel;
    Panel33: TPanel;
    Panel34: TPanel;
    Panel35: TPanel;
    Panel36: TPanel;
    Panel37: TPanel;
    Panel38: TPanel;
    Panel39: TPanel;
    Panel40: TPanel;
    Panel41: TPanel;
    Panel42: TPanel;
    Panel43: TPanel;
    Panel44: TPanel;
    Panel45: TPanel;
    Panel46: TPanel;
    Panel47: TPanel;
    Panel48: TPanel;
    Panel49: TPanel;
    Panel50: TPanel;
    Panel53: TPanel;
    Panel54: TPanel;
    Panel55: TPanel;
    Panel57: TPanel;
    Panel58: TPanel;
    Panel59: TPanel;
    Panel60: TPanel;
    Panel61: TPanel;
    Panel62: TPanel;
    Panel63: TPanel;
    P24: TPanel;
    P644: TPanel;
    P604: TPanel;
    P57: TPanel;
    P34: TPanel;
    P25: TPanel;
    P26: TPanel;
    P645: TPanel;
    P605: TPanel;
    P58: TPanel;
    M521: TPanel;
    P646: TPanel;
    M541: TPanel;
    P606: TPanel;
    P59: TPanel;
    M561: TPanel;
    M501: TPanel;
    Image12: TImage;
    Image13: TImage;
    Image14: TImage;
    Image15: TImage;
    Image16: TImage;
    Image17: TImage;
    INFOSHAPE: TShape;
    INFOPANEL: TPanel;
    VISSZAGOMB: TBitBtn;
    Image1: TImage;
    VMTIPUSPANEL: TPanel;
    VRANGEPANEL: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure ArPANELClick(Sender: TObject);
 //   procedure EgysegarDisplay;

    procedure KILEPOTIMERTimer(Sender: TObject);
    procedure MunkaPanelDisplay;
    procedure Kiszamol;
    procedure KomboToltes;
    procedure rendszameditEnter(Sender: TObject);
    procedure rendszameditExit(Sender: TObject);
    procedure rrendszameditEnter(Sender: TObject);
    procedure rrendszameditExit(Sender: TObject);
    procedure JOVAHAGYOGOMBClick(Sender: TObject);
    procedure rendszameditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure rrendszameditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure NAPTARChange(Sender: TObject);
    procedure DATUMVISSZAGOMBClick(Sender: TObject);
    procedure datumeloregombClick(Sender: TObject);
    procedure ORSZAGCOMBOChange(Sender: TObject);
    procedure KonyvelogombClick(Sender: TObject);
    function Nulele(_num: integer):string;
    procedure UgyfeletValasztott;
    procedure NemValasztoGombCLick(Sender: TObject);

    function Scaninfoss(_tag: word): byte;
    procedure InfoPanelTorles;
    function GetTipusInfo(_cc: word): string;

    procedure VegtakaroDisplay;
    procedure MATRICACANCELGOMBClick(Sender: TObject);
    procedure NEMKONYVELOGOMBClick(Sender: TObject);
    procedure TRANSCANCELTIMERTimer(Sender: TObject);
    procedure KONYVELOGOMBEnter(Sender: TObject);
    procedure KONYVELOGOMBExit(Sender: TObject);
    procedure KONYVELOGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
 
    procedure PalyaInformDisplay;
    procedure LiveAAKgombClick(Sender: TObject);
    procedure IdoIntervalumDisplay;
    procedure TOVABBGOMBClick(Sender: TObject);
    procedure HibaUzenet;
    procedure CANCELAAKGOMBClick(Sender: TObject);
    procedure RETURNGOMBClick(Sender: TObject);
    procedure UJUGYFELGOMBClick(Sender: TObject);
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CIMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UGYFELOKEGOMBClick(Sender: TObject);
    function getIdoTartam(_cc: word): string;
    procedure TORZSUGYFELGOMBClick(Sender: TObject);
    function Scanosz(_oo: byte): byte;
    procedure VALASZTOGOMBClick(Sender: TObject);
    procedure UGYFELRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UGYFELRACSDblClick(Sender: TObject);
    procedure NemkerAfastGombCLick(Sender: TObject);
    procedure AfastKerGombCLick(Sender: TObject);
    procedure MATRICAIMAGEMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);

    procedure infoMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Panel7MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);

    procedure mmatricaOkeGombClick(Sender: TObject);
    procedure P34MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Panel22MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AUTOPALYAFORM: TAUTOPALYAFORM;
  _tartam: array[1..4] of string = ('EGY NAPOS','EGY HETES',
                             'EGY HAVI','EGY ÉVI');
  _havinap: array[1..12] of integer = (31,28,31,30,31,30,31,31,30,31,30,31);
  _matricatipus,_felsegjel,_range,_KIEGESZITES: string;
  _aktev,_aktho,_aktnap,_jarmutipus,_ss,_tartamsor: integer;
  _akts1 : word;

  _utinfoss: byte;
  _cc: integer;
  _maymove: boolean;
  _starthnap,_endhnap,_utmove,_aktmove: integer;
  _hIndex: integer;

  _matricaPanel: TPanel;
  _tartamstr,_rrendszam,_idotartam: string;
  _infopanel: array[1..5] of TPanel;
  _aktmnev: string;

  _feljel: array[1..260] of string;
  _ccode: array[1..260] of integer;
  _findex: integer;
  _paneltomb: array[1..3] of TPanel;

  _balszel: array[1..5] of integer =(44,96,8,104,600);
  _topinfo: array[1..5] of integer = (512,512,295,295,512);

implementation

uses Unit4, Unit5, Unit6, Unit12;

{$R *.dfm}


// =============================================================================
          procedure TAUTOPALYAFORM.FormActivate(Sender: TObject);
// =============================================================================

begin

  Top := _top;
  Left := _left;
  Height := 768;
  Width := 1024;

   Infopanel.visible := false;
   infoshape.Visible := False;
   _akts1 := 0;

  _tipus := 'M';
  ConfirmGomb.Visible         := False;
  MunkaPanel.Visible          := False;
  Vegtakaro.Visible           := false;
  KudarcPanel.Visible         := False;
  SikerBaner.visible          := False;
  ReturnGomb.Visible          := False;
  KifizetendoPanel.Font.Color := clBlack;
  KifizetendoPanel.Color      := clWhite;
  VisszaIgazoloPanel.Visible  := False;
  Naptar.CalendarDate         := Date;

  _kellAfas                   := False;
  _maymove                    := True;
  _ezMegye                    := False;

  _idotartam :='HETI';
  _Ugyfelnev := '';
  _Ugyfelcim := '';

  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap:= dayof(date);

  KomboToltes;
//  Egysegardisplay;

  // --------------------------------------------------------

  PenztarszamPanel.caption := _homePenztarszam;
  Penztarnevpanel.Caption  := _homePenztarnev;
  Penztarospanel.Caption   := _prosnev;
end;

// =============================================================================
          procedure TAUTOPALYAFORM.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('A vissza-gombra klikkelt');
  ModalResult :=2;
end;


// =============================================================================
            procedure TAUTOPALYAFORM.ArPANELClick(Sender: TObject);
// =============================================================================

var _pnev,_ptip: string;

begin
  if not _maymove then exit;

  _maymove  := False;
  _pnev     := Tpanel(sender).Name;
  _cikkszam := Tpanel(sender).Tag;
  _ezmegye  := False;

  _aktmatricanev := GettipusInfo(_cikkszam);
  MatricaTipusPanel.Caption := _aktmatricanev;

  Form1.Logbair('Matricatipusra klikkelt: ' +_aktmatricanev);

  _ptip := leftstr(_pnev,1);
  if _pTip='M' then
    begin
      Form1.Logbair('Megyét választ');
      _megyess := selectCounty.showModal;
      dec(_megyess);
      if _megyess<0 then
        begin
          Form1.Logbair('Mégsem választ megyét');
          exit;
        end;
      _ezmegye := true;
      _aktmegyenev := _megyenev[_megyess];
      Form1.Logbair('Ezt a megyét választotta: '+ _aktmegyenev);
      _cikkszam := _cikkszam + _megyess;
      RangePanel.Caption := _aktmegyenev+ ' MEGYE TERÜLETÉRE';
    end else RangePanel.Caption := 'AZ EGÉSZ ORSZÁG TERÜLETÉRE';

  _idotartam := Getidotartam(_cikkszam);

  Kiszamol;
  rendszamedit.clear;
  rRendszamedit.clear;
  orszagcombo.ItemIndex := _hIndex;
  _kategoriastr := _cikknev[_cikkszam];
  MunkaPanelDisplay;

end;


// =============================================================================
          procedure TAUTOPALYAFORM.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := false;
  Modalresult := _mResult;
end;

// =============================================================================
              procedure TAutoPalyaForm.MunkapanelDisplay;
// =============================================================================


begin
   NevbekeroPanel.Visible := false;
   Nevedit.Text := '';
   Cimedit.Text := '';

   UgyfelValasztoPanel.Visible := false;

   with AfasPanel do
     begin
        Top := 30;
        Left := 224;
        Visible := True;
      end;

   with Ugyfelpanel do
     begin
       Top := 180;
       Left := 40;
       Visible := true;
     end;

   JovahagyoGomb.Enabled := false;

   with Munkapanel do
    begin
      Top := 205;
      Left:= 8;
      Width := 1012;
      Height := 500;
      Visible := true;
    end;
  _rrendszam := '';
  _rendszam := '';
  ActiveControl := NemkerafastGomb;
end;

// =============================================================================
        procedure TautoPalyaForm.NemkerAfastGombCLick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Ügyfél nem kér áfás számlát');
  UgyfelPanel.visible := False;
  Jovahagyogomb.Enabled := True;
  ActiveControl := rendszamEdit;
end;

// =============================================================================
          procedure TautoPalyaForm.AfastKerGombCLick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Az ügyfél áfás számlát kér');
  AfasPanel.visible := false;
  ActiveControl := Ujugyfelgomb;
end;


// =============================================================================
                         procedure TAutopalyaForm.Kiszamol;
// =============================================================================


var _szoko: boolean;

begin

  If _idotartam='' then _idotartam:= 'HETI';
  _startDatum := Naptar.CalendarDate;

  if _startDatum=date then _startPerc := Form1.Getidos
  else _startPerc := '00:00:00';

  _startDatums := Form1.Hundatetostr(_startdatum);
  if _startdatum<date then
    begin
      Naptar.CalendarDate := Date;
      ActiveControl := Naptar;
      exit;
    end;

  _startev := yearof(_startdatum);
  _startho := monthof(_startDatum);
  _startNap := dayof(_startDatum);

  Evpanel.Caption := inttostr(_startev);
  NaptarHoPanel.Caption := _honev[_startHo];

  if _idotartam='HETI' then
    begin
      _enddatum := _startDatum+9;
      _endev := yearof(_enddatum);
      _endho := monthof(_enddatum);
      _endnap:= dayof(_enddatum);
    end;

  if _idoTartam='HAVI' then
    begin
      _endev := _startev;
      _szoko := isleapyear(_endev);
      _endho := _startho+1;
      _endnap := _startNap;
      if _endho>12 then
        begin
          _endho := 1;
          inc(_endev);
        end;

      if _endnap>_havinap[_endho] then _endNap := _havinap[_endho];

      if (_szoko) and (_endho=2) and (_endnap=28) and (_startnap>28) then _endnap := 29;

      _endDatum := encodeDate(_endev,_endho,_endNap);

    end;

  if _idotartam='EVES' then
    begin
       _endev := _startev+1;
       _endho := 1;
       _endnap := 31;
       _endDatum := encodeDate(_endev,_endho,_endNap);
    end;

  PalyaInformDisplay;
end;

// =============================================================================
              procedure TAutopalyaForm.PalyaInformDisplay;
// =============================================================================


begin
  _startdatum := encodeDate(_startev,_startho,_startnap);
  _endDatum := encodeDate(_endev,_endho,_endnap);

  _starthnap := dayoftheweek(_startDatum);
  _endHnap := Dayoftheweek(_endDatum);

  TolevPanel.Caption := inttostr(_startev);
  IgEvPanel.Caption := inttostr(_endev);

  TolhoPanel.Caption := _honev[_startho];
  IgHopanel.Caption := _honev[_endho];

  TolnapPanel.Caption := inttostr(_startnap);
  IgNapPanel.Caption := inttostr(_endNap);

  TolNapnevPanel.Caption := _napnev[_starthnap];
  TolPercpanel.Caption := leftstr(_startperc,2)+' óra '+midstr(_startperc,4,2)+' perctöl';

  IgNapNevPanel.Caption := _napnev[_endhnap];
  IF _CIKKSZAM>0 then
    begin
      _fizetendo := _cikkar[_cikkszam];
       FizetendoPanel.Caption := formatfloat('### ###',_fizetendo)+ ' Ft';
      _startDatums := Form1.HunDateTostr(_startDatum);
      _endDatums := Form1.HunDatetostr(_endDatum);
    end;
end;

// =============================================================================
                 procedure TAutopalyaForm.Kombotoltes;
// =============================================================================


var _okod: integer;
    _onev,_fjel: string;

begin
  Orszagcombo.clear;
  Orszagcombo.Items.clear;
  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.commit;
  _pcs := 'SELECT * FROM FELSEGJEL ORDER BY ORSZAGNEV';
  with IBQUERY do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;
  _cc := 0;
  while not IbQuery.eof do
    begin
      _onev := trim(IbQuery.fieldbyname('ORSZAGNEV').asString);
      _okod := IBquery.FieldByName('KODSZAM').asInteger;
      _fjel := trim(ibQuery.FieldByName('BETUJEL').asstring);
      Orszagcombo.Items.add(_onev);
      if _okod=75 then
            _hindex := _cc;
      inc(_cc);
      _feljel[_cc] := _fjel;
      _ccode[_cc] := _okod;
      ibquery.Next;
    end;
  ibquery.close;
  ibdbase.close;
end;


// =============================================================================
           procedure TAUTOPALYAFORM.rendszameditEnter(Sender: TObject);
// =============================================================================

begin
  Rendszamedit.Color := $a0FFFF;
end;

// =============================================================================
            procedure TAUTOPALYAFORM.rendszameditExit(Sender: TObject);
// =============================================================================

begin
  _rendszam := rendszamedit.text;
  rendszamedit.Color := clWindow;
end;

// =============================================================================
          procedure TAUTOPALYAFORM.rrendszameditEnter(Sender: TObject);
// =============================================================================

begin
  RRendszamedit.Color := $a0ffff;
end;

// =============================================================================
         procedure TAUTOPALYAFORM.rrendszameditExit(Sender: TObject);
// =============================================================================

begin
  _rrendszam := rrendszamedit.text;
  rrendszamedit.color := clWindow;
end;

// =============================================================================
         procedure TAUTOPALYAFORM.JOVAHAGYOGOMBClick(Sender: TObject);
// =============================================================================

var i,_asc: integer;
   _okrsz: string;
   _voltBetu: boolean;

begin
  if _rendszam='' then
    begin
      ShowMessage('A RENDSZÁMOT MEG KELL ADNI');
      ActiveControl := Rendszamedit;
      exit;
    end;
  if (_rendszam<>_rrendszam) then
    begin
      ShowMessage('NEM EGYEZIK A MEGISMÉTELT RENDSZÁM');
      ActiveControl := Rendszamedit;
      exit;
    end;
  _okrsz := '';
  _voltbetu := False;
  for i := 1 to length(_rendszam) do
    begin
      _asc := ord(_rendszam[i]);
      if (_asc>47) and (_asc<58) then _okrsz := _okrsz + chr(_asc);
      if (_asc>64) and (_asc<91) then
        begin
          _voltbetu := True;
          _okrsz := _okrsz + chr(_asc);
        end;
    end;

   if not _voltbetu then
     begin
       Showmessage('A RENDSZÁMBAN BETÜNEK IS KELL LENNIE');
       Rendszamedit.Text := '';
       rRendszamedit.Text := '';
       _rendszam := '';
       _rrendszam := '';
       ActiveControl := Rendszamedit;
       exit;
     end;
   _RENDSZAM := _OKRSZ;


  _findex      := OrszagCombo.ItemIndex;
  _felsegjel   := _feljel[_findex+1];
  _countryName := _felsegjel+' - ' + OrszagCombo.Items[_findex];
  _countryCode := _ccode[_fIndex+1];
  Form1.Logbair('  - Rendszám: '+_rendszam);
  Form1.Logbair('  - Ország  : '+_countryname);

  Vegtakarodisplay;
end;

// =============================================================================
       procedure TAUTOPALYAFORM.rendszameditKeyDown(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  IF ord(key)=13 then ActiveControl := rrendszamedit;
  if ord(key)=9 then Activecontrol := rrendszamedit;
end;

// =============================================================================
       procedure TAUTOPALYAFORM.rrendszameditKeyDown(Sender: TObject;
                                         var Key: Word; Shift: TShiftState);
// =============================================================================

begin
   IF ord(key)=13 then ActiveControl := Jovahagyogomb;
   if ord(key)=9 then Activecontrol := Jovahagyogomb;
end;

// =============================================================================
               procedure TAUTOPALYAFORM.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  _startDatum := Naptar.CalendarDate;
  if _startDatum<Date then
    begin
      Naptar.CalendarDate := date;
      ActiveControl := Naptar;
      Exit;
    end;
  Kiszamol;
end;

// =============================================================================
        procedure TAUTOPALYAFORM.DATUMVISSZAGOMBClick(Sender: TObject);
// =============================================================================


var _maiHonap,_maiev: word;

begin
  _startdatum := Naptar.CalendarDate;
  _startho := monthof(_startdatum);
  _startev := yearof(_startDatum);

  _maiev := yearof(_startdatum);
  _maiHonap := monthof(Date);
  if (_maiev=_startev) and (_maihonap=_startho) then exit;

  dec(_startho);
  if _startho<1 then
    begin
      _startho := 12;
      dec(_startev);
    end;
  _startnap := _havinap[_startho];
  _startDatum := encodeDate(_startev,_startho,_startnap);
  Naptar.CalendarDate := _startDatum;
  if (_maihonap=_startho) and (_maiev=_startev) then
                                    DatumVisszaGomb.enabled := false;
  Kiszamol;
  ActiveControl := JovahagyoGomb;
end;

// =============================================================================
         procedure TAUTOPALYAFORM.datumeloregombClick(Sender: TObject);
// =============================================================================

begin
   _startdatum := Naptar.CalendarDate;
  _startho := monthof(_startdatum);
  _startnap := 1;

  DatumVisszaGomb.Enabled := true;

  _startev := yearof(_startdatum);
  inc(_startho);

  if _startho>12 then
    begin
      _startho := 1;
      inc(_startev);
    end;
  _startdatum := encodeDate(_startev,_startho,_startnap);
  Naptar.CalendarDate := _startDatum;
  Kiszamol;
  ActiveControl := JovahagyoGomb;
end;

// =============================================================================
          procedure TAUTOPALYAFORM.ORSZAGCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Jovahagyogomb;
end;

// =============================================================================
                 procedure TAutopalyaForm.konyvelogombClick(Sender: TObject);
// =============================================================================

var _tranzakcioOke: integer;

begin
  Konyvelogomb.Visible := False;
  NemKonyveloGomb.Visible := False;

  Form1.Logbair('Elküldi a matrica elözetes kérését');

  _httpTipus := 'TEST AAK';
  _tranzAkcioOke := MatricaHttpsRutinok.showModal;

  if _tranzakcioOke<>1 then
    begin
      Form1.Logbair('Negativ válasz jött: '+ _hibauzenet);
      KifizetendoPanel.Caption := '';
      KifizetendoPanel.Repaint;
      Hibauzenet;
      Exit;
    end;

  Form1.Logbair('Pozitiv visszaigazolás érkezett');
  with VisszaIgazoloPanel do
    begin
      Top := 540;
      Left := 190;
      Visible := True;
      Bringtofront;
    end;
  Form1.Matrica1Blokk;
  ActiveControl := LiveAAKGomb;
end;

// =============================================================================
         procedure TAutopalyaform.LiveAAKgombClick(Sender: TObject);
// =============================================================================


begin
  VisszaIgazoloPanel.Visible := False;

  Form1.Logbair('Kéri az elözetesen kért matricát');

  _httpTipus := 'LIVE AAK';
  _tranzAkcioOke := MatricaHttpsRutinok.ShowModal;

  if _tranzakcioOke<>1 then
    begin
       Form1.Logbair('Negativ válasz: '+_hibauzenet);
       KifizetendoPanel.Caption := '';
       KifizetendoPanel.Repaint;
       HibaUzenet;
       Exit;
    end;

  inc(_lastMatrica);
  _bizonylatszam := 'AM' + Form1.Hatnulele(_LastMatrica);
  Form1.Logbair(_bizonylatszam+' bizonylat könyvelése');

  Form1.Konyveles('M');
  Form1.Matrica2Blokk;

  if _kellAfas then Form1.AfasSzamla;

  _kellafas := False;
  SikerBaner.visible := true;
  ReturnGomb.Visible := True;
  ActiveControl := ReturnGomb;
end;


// =============================================================================
              procedure TAutopalyaForm.Vegtakarodisplay;
// =============================================================================

begin
  //VisszaGomb.Visible := False;

//  InfoDisplay;
  VmTipusPanel.caption := _aktmatricanev;
  vmtipuspanel.Repaint;
   if _ezmegye then VrangePanel.Caption := _aktmegyenev + ' MEGYE TERÜLETÉRE'
  else vRANGEPanel.Caption := 'AZ EGÉSZ ORSZÁG TERÜLETÉRE';
  vRANGEPanel.Repaint;

  FelsegPanel.Caption := _FELsegJEL;
  with KifizetendoPanel do
    begin
      Color := clWhite;
      Font.color := clBlack;
    end;

  IdoIntervalumDisplay;

  // itt az adatok rendben vannak - el lehel küldeni

  KonyveloGomb.Visible := true;
  NemKonyveloGomb.Visible := True;
  with Vegtakaro do
    begin
      Left := 0;
      Top := 0;
      Visible := true;
    end;
  Konyvelogomb.Enabled := true;
  ActiveControl := Konyvelogomb;
end;


// =============================================================================
                procedure TAutoPalyaForm.IdointervalumDisplay;
// =============================================================================


begin
  if (_startev>2000) and (_startho>0) and (_startnap>0) then
    begin
      TEVPANEL.Caption := inttostr(_startev);
      THoPanel.Caption := _honev[_startho];
      TNapPanel.Caption := inttostr(_startnap);
      _startdatum := encodeDate(_startev,_startho,_startnap);
      _starthnap := dayoftheweek(_startDatum);
      THNapPanel.Caption := _napnev[_starthnap];
      OrapercPanel.Caption := leftstr(_startperc,2)+' óra '+midstr(_startperc,4,2)+' perctöl';
      _vfd := Nulele(_startev-2000)+Nulele(_startho)+nulele(_startnap);
    end;

  if (_endev>2000) and (_endho>0) and (_endnap>0) then
    begin
      ievpanel.Caption := inttostr(_endev);
      IHOPanel.Caption := _honev[_endho];
      INapPanel.Caption := inttostr(_endNap);
      _endDatum := encodeDate(_endev,_endho,_endnap);
      _endHnap := Dayoftheweek(_endDatum);
      IHnapPanel.Caption := _napnev[_endhnap];
    end;

  RendszamPanel.Caption := _RENDSZAM;

  if _fizetendo>0 then
      KifizetendoPanel.Caption := Formatfloat('### ###',_fizetendo)+' Ft';
end;


// =============================================================================
          procedure TAUTOPALYAFORM.MATRICACANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  MunkaPanel.Visible := false;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.NEMKONYVELOGOMBClick(Sender: TObject);
// =============================================================================

begin
  TransCancelTimerTimer(Nil);
end;

// =============================================================================
         procedure TAUTOPALYAFORM.TRANSCANCELTIMERTimer(Sender: TObject);
// =============================================================================

begin
  TransCancelTimer.Enabled := False;
  Vegtakaro.Visible := False;
  MunkaPanel.Visible := False;
  VisszaGomb.Visible := True;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.KONYVELOGOMBEnter(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).font.Style := [fsBold,fsItalic];
end;

// =============================================================================
           procedure TAUTOPALYAFORM.KONYVELOGOMBExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).font.Style := [fsItalic];
end;

// =============================================================================
       procedure TAUTOPALYAFORM.KONYVELOGOMBMouseMove(Sender: TObject;
                                         Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(Sender);
end;


{
// =============================================================================
                       procedure TAutopalyaForm.InfoDisplay;
// =============================================================================


begin
  MemoTabla.Lines.Clear;
  MemoTabla.Clear;

  if _jarmutipus=2 then
    begin
      Memotabla.Lines.add('       ');
      Memotabla.Lines.Add('                            M O T O R K E R É K P Á R');
      Exit;
    end;

  if (_matricatipus = 'D1') then
    begin
      MemoTabla.Lines.add('       LEGFELJEBB 3.5 TONNA MEGENGEDETT LEGNAGYOBB ÖSSZTÖMEGÜ GÉPJÁRMŰ,');
      Memotabla.Lines.Add('         VALAMINT GÉPJÁRMŰ ÉS VONTATMÁNY EGYÜTTESE (JÁRMŰSZERELVÉNY)');
      Exit;
    end;

  if _matricaTipus = 'D2' then
    begin
      Memotabla.Lines.add('A 3.5 TONNÁT MEGHALADÓ, LEGFELJEBB 7.5 TONNA MEGENGEDETT LEGNAGYOBB ÖSSZTÖMEGŰ');
      Memotabla.Lines.Add('       VALAMINT GÉPJÁRMŰ ÉS VONTATMÁNY EGYÜTTESE (JÁRMŰSZERELVÉNY)');
      Exit;
    end;

  if _matricaTipus = 'D3' then
    begin
      Memotabla.Lines.add('A 7.5 TONNÁT MEGHALADÓ, LEGFELJEBB 12.0 TONNA MEGENGEDETT LEGNEGYOBB ÖSSZTÖMEGŰ');
      Memotabla.Lines.Add('       VALAMINT GÉPJÁRMŰ ÉS VONTATMÁNY EGYÜTTESE (JÁRMŰSZERELVÉNY)');
      Exit;
    end;

  if _matricaTipus = 'D4' then
    begin
      Memotabla.Lines.add('A D1,D2 VAGY D3 DÍJKATEGÓRIÁBA NEM SOROLHATÓ VALAMENNYI GÉPJÁRMŰ. A 7.5 TONNÁT');
      Memotabla.Lines.Add('  MEGHALADÓ ÖSSZTÖMEGŰ AUTÓBUSZT AZ ÖSSZTÖMEGÉNEK MEGFELELŐ DÍJKATEGORIÁNÁL');
      MemoTabla.Lines.add('              EGGYEL ALACSONYABB DÍJKATEGÓRIÁBA KELL BESOROLNI');
    end;

  if _matricatipus = 'B2' then
    begin
      Memotabla.Lines.add('A 3,5 TONNÁT MEGHALADÓ MEGENGEDETT LEGNAGYOBB ÖSSZTÖMEGŰ AUTÓBUSZOK ÉS LAKÓAU-');
      Memotabla.Lines.Add('                             TÓK, BÁRMILYEN VONTATMÁNNYAL IS');
    end;

  
end;
}


// =============================================================================
             function TAutopalyaform.Nulele(_num: integer):string;
// =============================================================================

begin
  result := inttostr(_num);
  if _num<10 then result := '0' + result;
end;


// =============================================================================
          procedure TAUTOPALYAFORM.TOVABBGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kudarcpanel.Visible := false;
  Form1.Logbair('SIKERTELEN MATRICA VÁSÁRLÁS');
  Form1.Logbair(dupestring('-',80));
  Modalresult := 2;
end;

// =============================================================================
                   procedure TAutopalyaForm.HibaUzenet;
// =============================================================================


begin
  HibaPanel.caption := _hibauzenet;
  with Kudarcpanel do
    begin
      Top := 450;
      Left := 200;
      Visible := true;
    end;
  ActiveControl := TovabbGomb;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.CANCELAAKGOMBClick(Sender: TObject);
// =============================================================================

begin
  VisszaIgazoloPanel.visible := False;
  _httpTipus := 'CANCEL AAK';
  _tranzAkcioOke := MatricaHttpsRutinok.ShowModal;

  if _tranzakcioOke<>1 then
    begin
       HibaUzenet;
       Exit;
    end;
  _hibauzenet := 'A TRANZAKCIÓT TÖRÖLTE A PÉNZTÁROS';
  HibaUzenet;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.RETURNGOMBClick(Sender: TObject);
// =============================================================================

begin
  _Fizetendo := 0;
  ModalResult := 1;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.UJUGYFELGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nevedit.Clear;
  Cimedit.clear;
  with Nevbekeropanel do
    begin
      top := 80;
      Left := 176;
      Visible := True;
     end;
  ActiveControl := Nevedit;
end;

// =============================================================================
      procedure TAUTOPALYAFORM.NEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := Cimedit;
end;

// =============================================================================
    procedure TAUTOPALYAFORM.CIMEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := UgyfelOkeGomb;
end;

// =============================================================================
             procedure TAUTOPALYAFORM.UGYFELOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ugyfelnev := Nevedit.Text;
  if _ugyfelnev<>'' then
    begin
      _ugyfelcim := Cimedit.text;
      inc(_lastugyfel);
      _ugyfelszam := _lastUgyfel;
      Valutadbase.Connected := True;
      if ValutaTranz.InTransaction then Valutatranz.Commit;
      Valutatranz.StartTransaction;
      _pcs := 'INSERT INTO UGYFEL (UGYFELSZAM,NEV,LAKCIM)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_ugyfelszam)+ ',';
      _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _ugyfelcim + chr(39)+ ')';
      with ValutaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Execsql;
        end;
      ValutaTranz.Commit;
      ValutaDbase.close;

      Valutadbase.Connected := True;
      if ValutaTranz.InTransaction then Valutatranz.Commit;
      Valutatranz.StartTransaction;
      _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOUGYFELSZAM='+inttostr(_lastugyfel);
      with ValutaQuery do
        begin
          Close;
          sql.Clear;
          sql.Add(_pcs);
          ExecSql;
        end;
      ValutaTranz.Commit;
      ValutaDbase.close;
      _kellafas := true;
    end;
  Ugyfelpanel.Visible := False;
  JovahagyoGomb.Enabled := true;
  ActiveControl := Rendszamedit;
end;

// =============================================================================
         procedure TAUTOPALYAFORM.TORZSUGYFELGOMBClick(Sender: TObject);
// =============================================================================

begin
  vALUTADBASE.Connected := TRUE;

  _pcs := 'SELECT * FROM UGYFEL' +_sorveg;
  _pcs := _pcs + 'ORDER BY NEV';

  with valutaquery do
    begin
      close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
    end;

  with UgyfelValasztoPanel do
    begin
      Top := 8;
      Left := 140;
      Visible := tRUE;
    end;

  ActiveControl := UgyfelRacs;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.VALASZTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  UgyfeletValasztott;
end;

// =============================================================================
    procedure TAUTOPALYAFORM.UGYFELRACSKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  UgyfeletValasztott;
end;

// =============================================================================
                    procedure TAutopalyaForm.UgyfeletValasztott;
// =============================================================================

begin
  _ugyfelnev := ValutaQuery.FieldByName('NEV').asstring;
  _ugyfelcim := ValutaQuery.FieldByName('LAKCIM').asstring;
  _kellafas := true;
  NemValasztoGombClick(Nil);
end;

// =============================================================================
          procedure TautopalyaForm.NemValasztoGombCLick(Sender: TObject);
// =============================================================================

begin

  Valutaquery.close;
  Valutadbase.close;
  Ugyfelvalasztopanel.Visible := false;
  UgyfelPanel.Visible := false;
  JovahagyoGomb.Enabled := true;
  activeControl := Rendszamedit;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.UGYFELRACSDblClick(Sender: TObject);
// =============================================================================

begin
  UgyfeletValasztott;
end;

// =============================================================================
       procedure TAUTOPALYAFORM.MATRICAIMAGEMouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  infoPaneltorles;
end;

// =============================================================================
                 function TAutopalyaform.Scanosz(_oo: byte): byte;
// =============================================================================

begin
  result := 1;
  if _oo=24 then exit;

  result := 2;
  if _oo<30 then exit;

  result := 3;
  if _oo<50 then exit;

  result := 4;
  if _oo<57 then exit;

  result := 5;
end;


{
procedure TAUTOPALYAFORM.ArcimkeMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);

var _mleft,_osznum,_mTop: word;
    _aktmovenev: string;


begin
  _aktmovenev := Tpanel(sender).Name;
  _osznum := strtoint(midstr(_aktmovenev,2,2));
  _aktmove := scanosz(_osznum);
  if _utmove=_aktmove then exit;
  _utmove := _aktmove;
  _mleft := _balszel[_aktmove];
  _mTop  := _topinfo[_aktmove];
  with _dinfoTablak[_aktmove] do
    begin
      Top := _mTop;
      Left := _mleft;
      Visible := true;
      Repaint;
    end;
end;

}


// =============================================================================
       procedure TAUTOPALYAFORM.INFOMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================


var _tag,_iTop,_iLeft: word;
    _aktinfoss: byte;
    _aktinfoPanel: Tpanel;

begin
  if not _maymove then exit;

  _tag := Tpanel(sender).Tag;
  _aktinfoss := scanInfoss(_tag);
  if _aktinfoss=_utinfoss then exit;
  infoPanelTorles;
  _utinfoss := _aktinfoss;
  _aktinfopanel := _Infopanel[_utinfoss];
  _itop := _topinfo[_utinfoss];
  _iLeft:= _balszel[_utinfoss];
  with _aktinfopanel do
    begin
      Top := _itop;
      Left:= _ileft;
      Visible := True;
    end;
end;

// =============================================================================
                 procedure Tautopalyaform.InfoPanelTorles;
// =============================================================================

var i: integer;

begin
  for i := 1 to 5 do
    begin
      _infopanel[i].visible := false;
    end;
  _utinfoss := 0;
end;

// =============================================================================
             function TAutopalyaForm.Scaninfoss(_tag: word): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=5 do
    begin
      case _tag of
        24: result := 1;
        25: result := 2;
        26: result := 2;
        521: result := 3;
        561: result := 4;
        57: result := 5;
        58: result := 5;
        59: result := 5;
      end;
      inc(_z);
    end;
end;

// =============================================================================
        procedure TAUTOPALYAFORM.Panel7MouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  InfopanelTorles;
end;

{
procedure TAUTOPALYAFORM.D1MPANELClick(Sender: TObject);

var _felirat: string;

begin
  _mayMove := False;
  _aktMnev := Tpanel(sender).Caption;
  if _aktmnev='D1' then _felirat := 'D1-AUTÓ';
  if _aktmnev='D2' then _felirat := 'D2-AUTÓ';
  if _aktmnev='B2' then _felirat := 'B2-BUSZ';

  with MegyeBigShape do
    begin
      left := 24;
      Top  := 8;
      Visible := true;
    end;

  with MegyebigPanel do
    begin
      caption := _felirat;
      left := 32;
      Top := 16;
      Visible := True;
    end;
  InfoPanelTorles;
  MegyeValasztoGomb.Enabled := True;
end;

procedure TAUTOPALYAFORM.megyevalasztogombClick(Sender: TObject);

begin

  _megyess := selectCounty.showModal;
  dec(_megyess);
  if _megyess<0 then exit;
  _ezmegye := true;

  _aktmegyenev := _megyenev[_megyess];

  IF _aktMnev = 'D1' then
    begin
      _cikkszam := 521+_megyess;
      _fizetendo := _cikkar[_cikkszam];
      MatricanevPanel.Caption := 'ÉVES MEGYEI D1 MATRICA';
    end;

  IF _aktMnev = 'D2' then
    begin
      _cikkszam := 541+_megyess;
      _fizetendo := _cikkar[_cikkszam];
      MatricanevPanel.Caption := 'ÉVES MEGYEI D1 MATRICA';
    end;


  If _aktmnev = 'B2' then
    begin
      _cikkszam := 541+_megyess;
      _fizetendo := _cikkar[_cikkszam];
      MatricanevPanel.Caption := 'ÉVES MEGYEI B2 MATRICA'
    end;

  MatricaarPanel.Caption := Form1.FtForm(_fizetendo);
  ValasztottMegyenevPanel.Caption := _megyenev[_megyess] + ' MEGYE';
  with ValasztottMegyepanel do
    begin
      Top := 80;
      Left := 16;
      Visible := true;
    end;
end;
}


// =============================================================================
         procedure TAUTOPALYAFORM.mmatricaOkeGombClick(Sender: TObject);
// =============================================================================

begin
  _maymove := true;
  ArpanelClick(Nil);
end;



// =============================================================================
    procedure TAUTOPALYAFORM.P34MouseMove(Sender: TObject; Shift: TShiftState;
                                                                 X, Y: Integer);
// =============================================================================

var _s1: word;
    _info: string;

begin
  IF NOT _MAYMOVE then exit;

  _s1 := Tpanel(Sender).tag;
  if _akts1=_s1 then exit;

  _akts1 := _s1;
  _info := GettipusInfo(_s1);

  InfoPanel.Caption := _info;
  Infoshape.Visible := True;
  Infopanel.visible := True;
  Infopanel.repaint;
end;

// =============================================================================
     procedure TAUTOPALYAFORM.Panel22MouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  _akts1 := 0;
  Infoshape.Visible := false;
  infopanel.Visible := False;
end;


// =============================================================================
            function Tautopalyaform.GetTipusInfo(_cc: word): string;
// =============================================================================

var _i: string;

begin
  case _cc of
    34: _i := 'HETI MOTOROS MATRICA';

    24: _i := 'D1 ORSZÁGOS HETI AUTÓS MATRICA';
    25: _i := 'D1 ORSZÁGOS HAVI AUTÓS MATRICA';
    26: _i := 'D1 ORSZÁGOS ÉVES AUTÓS MATRICA';

    644: _i := 'D2 ORSZÁGOS HETI AUTÓS MATRICA';
    645: _i := 'D2 ORSZÁGOS HAVI AUTÓS MATRICA';
    646: _i := 'D2 ORSZÁGOS ÉVES AUTÓS MATRICA';

    604: _i := 'U ORSZÁGOS HETI AUTÓS MATRICA';
    605: _i := 'U ORSZÁGOS HAVI AUTÓS MATRICA';
    606: _i := 'U ORSZÁGOS ÉVES AUTÓS MATRICA';

    57: _i := 'B2 ORSZÁGOS HETI BUSZ MATRICA';
    58: _i := 'B2 ORSZÁGOS HAVI BUSZ MATRICA';
    59: _i := 'B2 ORSZÁGOS ÉVES BUSZ MATRICA';

    521..539: _i := 'D1 MEGYEI ÉVES AUTÓS MATRICA';
    541..559: _i := 'D2 MEGYEI ÉVES AUTÓS MATRICA';
    501..519: _i := 'U MEGYEI ÉVES AUTÓS MATRICA';
    561..579: _i := 'B2 MEGYEI ÉVES BUSZ MATRICA';
  end;
 result := _i;
end;

// =============================================================================
          function TautopalyaForm.getIdoTartam(_cc: word): string;
// =============================================================================


var _i: string;

begin
  case _cc of
    34: _i := 'HETI';

    24: _i := 'HETI';
    25: _i := 'HAVI';
    26: _i := 'EVES';

    644: _i := 'HETI';
    645: _i := 'HAVI';
    646: _i := 'EVES';

    604: _i := 'HETI';
    605: _i := 'HAVI';
    606: _i := 'EVES';

    57: _i := 'HETI';
    58: _i := 'HAVI';
    59: _i := 'EVES';

    521..539: _i := 'EVES';
    541..559: _i := 'EVES';
    501..519: _i := 'EVES';
    561..579: _i := 'EVES';
  end;
 Result := _i;
end;

end.
