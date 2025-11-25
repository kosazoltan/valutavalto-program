unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, Buttons, IBDatabase, DB,
  IBCustomDataSet, IBQuery, StrUtils,DateUtils, unit1, Grids, Calendar,
  ComCtrls, DBGrids;

type
  TAUTOPALYAFORM = class(TForm)

    AfasPanel          : TPanel;
    AktEvLABEL         : TPanel;
    AlapLap            : TPanel;
    Bevel1             : TBevel;
    EvPanel            : TPanel;
    FelsegPanel        : TPanel;
    FizetendoPanel     : TPanel;
    HibaPanel          : TPanel;
    IgEvPanel          : TPanel;
    IEvPanel           : TPanel;
    INapPanel          : TPanel;
    IgHoPanel          : TPanel;
    IgNapNevPanel      : TPanel;
    IgNapPanel         : TPanel;
    IHNapPanel         : TPanel;
    KifizetendoPanel   : TPanel;
    KudarcPanel        : TPanel;
    FP22: TPanel;
    FP23: TPanel;
    FP25: TPanel;
    FP24: TPanel;
    MatricaTipusPanel  : TPanel;
    MegyeCsik          : TPanel;
    MunkaPanel         : TPanel;
    NaptarHoPanel      : TPanel;
    NevBekeroPanel     : TPanel;
    OraPercPanel       : TPanel;
    PenztarSzamPanel   : TPanel;
    PenztarNevPanel    : TPanel;
    PenztarosPanel     : TPanel;
    Panel4             : TPanel;
    Panel5             : TPanel;
    Panel6             : TPanel;
    Panel7             : TPanel;
    Panel13            : TPanel;
    Panel21            : TPanel;
    Panel9             : TPanel;
    Panel8             : TPanel;
    Panel10            : TPanel;
    Panel11            : TPanel;
    Panel12            : TPanel;
    Panel15            : TPanel;
    Panel16            : TPanel;
    Panel17            : TPanel;
    Panel18            : TPanel;
    Panel19            : TPanel;
    Panel20            : TPanel;
    Panel22            : TPanel;
    Panel23            : TPanel;
    Panel26            : TPanel;
    Panel27            : TPanel;
    Panel30            : TPanel;
    Panel31            : TPanel;
    Panel32            : TPanel;
    Panel33            : TPanel;
    Panel34            : TPanel;
    Panel35            : TPanel;
    Panel36            : TPanel;
    Panel37            : TPanel;
    Panel38            : TPanel;
    Panel39            : TPanel;
    Panel40            : TPanel;
    Panel41            : TPanel;
    Panel42            : TPanel;
    Panel43            : TPanel;
    Panel44            : TPanel;
    Panel45            : TPanel;
    Panel46            : TPanel;
    Panel47            : TPanel;
    Panel48            : TPanel;
    Panel49            : TPanel;
    Panel50            : TPanel;
    Panel53            : TPanel;
    Panel54            : TPanel;
    Panel55            : TPanel;
    Panel57            : TPanel;
    Panel58            : TPanel;
    Panel59            : TPanel;
    Panel60            : TPanel;
    Panel61            : TPanel;
    Panel62            : TPanel;
    Panel63            : TPanel;
    FP07: TPanel;
    FP08: TPanel;
    FP09: TPanel;
    FP10: TPanel;
    FP06: TPanel;
    FP13: TPanel;
    FP14: TPanel;
    FP15: TPanel;
    Panel2             : TPanel;
    Panel1             : TPanel;
    RangePanel         : TPanel;
    RendszamPanel      : TPanel;
    TolEvPanel         : TPanel;
    TolHoPanel         : TPanel;
    TolNapPanel        : TPanel;
    TolNapNEVPanel     : TPanel;
    TolPercPanel       : TPanel;
    TEVPanel           : TPanel;
    IHOPanel           : TPanel;
    THOPanel           : TPanel;
    THNapPanel         : TPanel;
    TNAPPanel          : TPanel;
    UgyfelPanel        : TPanel;
    VegTakaro          : TPanel;
    VisszaIgazoloPanel : TPanel;
    VMTipusPanel       : TPanel;
    VRangePanel        : TPanel;

    Shape4             : TShape;
    Shape6             : TShape;
    Shape7             : TShape;

    AfastKerGomb       : TBitBtn;
    CancelAAKGomb      : TBitBtn;
    ConfirmGomb        : TBitBtn;
    DatumVisszaGomb    : TBitBtn;
    DatumEloreGomb     : TBitBtn;
    JovahagyoGomb      : TBitBtn;
    KonyveloGomb       : TBitBtn;
    LiveAAKGomb        : TBitBtn;
    MatricaCancelGomb  : TBitBtn;
    NemKonyveloGomb    : TBitBtn;
    NemKerAfastGomb    : TBitBtn;
    NincsNevGomb       : TBitBtn;
    ReturnGomb         : TBitBtn;
    TovabbGomb         : TBitBtn;
    UgyfelOkeGomb      : TBitBtn;
    VisszaGomb         : TBitBtn;

    Label1             : TLabel;
    Label2             : TLabel;
    Label3             : TLabel;
    Label4             : TLabel;
    Label5             : TLabel;
    Label6             : TLabel;
    Label7             : TLabel;
    Label8             : TLabel;
    Label9             : TLabel;
    Label11            : TLabel;
    Label12            : TLabel;
    Label13            : TLabel;
    Label14            : TLabel;
    Label15            : TLabel;
    Label16            : TLabel;
    SikerBaner         : TLabel;
    Label18            : TLabel;
    Label19            : TLabel;
    Label21            : TLabel;

    NevEdit            : TEdit;
    CimEdit            : TEdit;
    Rendszamedit       : TEdit;
    Rrendszamedit      : TEdit;

    KilepoTimer        : TTimer;
    TransCancelTimer   : TTimer;
    Shape9             : TShape;
    Shape10            : TShape;
    Shape11            : TShape;
    Shape12            : TShape;
    Shape13            : TShape;
    Shape14            : TShape;
    Shape15            : TShape;
    Shape16            : TShape;
    Shape17            : TShape;
    Shape18            : TShape;

    Image1             : TImage;
    Image11            : TImage;
    Image12            : TImage;
    Image13            : TImage;
    Image14            : TImage;
    Image15            : TImage;
    Image16            : TImage;
    Image17            : TImage;
    MatricaImage       : TImage;

    IbQuery            : TIBQuery;
    IbDbase            : TIBDatabase;
    IbTranz            : TIBTransaction;

    ValutaQuery        : TIBQuery;
    ValutaDbase        : TIBDatabase;
    ValutaTranz        : TIBTransaction;

    Naptar             : TCalendar;
    OrszagCombo        : TComboBox;
    FP11: TPanel;
    FP20: TPanel;
    FP12: TPanel;
    FP17: TPanel;
    FP18: TPanel;
    FP19: TPanel;
    Label10: TLabel;
    ADOSZAMEDIT: TEdit;
    Label22: TLabel;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;
    Label20: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Shape1: TShape;
    Panel3: TPanel;
    Label17: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Panel14: TPanel;
    Panel25: TPanel;
    Panel29: TPanel;
    Panel51: TPanel;
    Panel52: TPanel;
    Panel64: TPanel;
    Panel66: TPanel;
    Panel24: TPanel;
    Panel28: TPanel;
    Panel56: TPanel;
    FP01: TPanel;
    FP02: TPanel;
    FP03: TPanel;
    FP04: TPanel;
    FP05: TPanel;
    Shape2: TShape;
    INFOSHAPE: TShape;
    INFOPANEL: TPanel;
    Panel71: TPanel;
    Panel72: TPanel;
    Panel73: TPanel;
    Panel74: TPanel;
    FP16: TPanel;
    FP21: TPanel;


    procedure AfastKerGombCLick(Sender: TObject);
    procedure ArKijelzo;
    procedure ArPanelClick(Sender: TObject);
    procedure CancelAAKGombClick(Sender: TObject);
    procedure CancelAAKRutin;
    procedure CimEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DatumEloreGombClick(Sender: TObject);
    procedure DatumVisszaGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HibaUzenet;
    procedure IdoIntervalumDisplay;
//    procedure InfoMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure InfoPanelTorles;
    procedure JovahagyoGombClick(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Kiszamol;
    procedure KomboToltes;
    procedure KonyvelogombClick(Sender: TObject);
    procedure KonyveloGombEnter(Sender: TObject);
    procedure KonyveloGombExit(Sender: TObject);
    procedure KonyveloGombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure LiveAAKGombClick(Sender: TObject);
    procedure LiveAAKRutin;
    procedure MatricaBekuldes;
    procedure MatricaCancelGombClick(Sender: TObject);
    procedure MatricaImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MmatricaOkeGombClick(Sender: TObject);
    procedure NaptarChange(Sender: TObject);
    procedure NemkerAfastGombCLick(Sender: TObject);
    procedure NemKonyveloGombClick(Sender: TObject);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OrszagComboChange(Sender: TObject);
    procedure FP06MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Panel22MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Panel7MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure RemoteParancs(_ukaz: string);
    procedure RendszamEditEnter(Sender: TObject);
    procedure RendszamEditExit(Sender: TObject);
    procedure ReplyErtekelo;
    procedure ReturnGombClick(Sender: TObject);
    procedure RrendszamEditEnter(Sender: TObject);
    procedure RrendszamEditExit(Sender: TObject);
    procedure RendszamEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RrendszamEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TransCancelTimerTimer(Sender: TObject);
    procedure TranzakcioMenet;
    procedure TestAAKRutin;
    procedure Tombbetoltes;
    procedure TovabbGombClick(Sender: TObject);
    procedure UgyfelOkeGombClick(Sender: TObject);


    procedure VisszaGombClick(Sender: TObject);

    function Arfdisp(_num: integer): string;
    function Pontoz(_dstring: string):string;
    function Scaninfoss(_tag: word): byte;
    function GetIdoTartam(_cc: word): string;
    function GetxrAdatok: boolean;
    function Nulele(_num: integer):string;
    function Scanosz(_oo: byte): byte;
    procedure NEVEDITEnter(Sender: TObject);
    procedure NEVEDITExit(Sender: TObject);
    procedure ADOSZAMEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AUTOPALYAFORM: TAUTOPALYAFORM;

  _ptag: byte;
  _pNev: string;
  _oldAr: integer;

//  _tartam: array[1..4] of string = ('EGY NAPOS','EGY HETES','EGY HAVI','EGY ÉVI');
  _havinap: array[1..12] of integer = (31,28,31,30,31,30,31,31,30,31,30,31);

  _infopanel : array[1..5] of TPanel;

  _feljel    : array[1..260] of string;
  _ccode     : array[1..260] of integer;
  _paneltomb : array[1..3] of TPanel;

  _balszel   : array[1..5] of integer =(44,96,8,104,600);
  _topinfo   : array[1..5] of integer = (512,512,295,295,512);

  _ppanel: array[1..25] of TPanel;
  _mKod: array[1..25] of word;
  _mNev: array[1..25] of string;
  _mar,_moldar:  array[1..25] of integer;

  _aktword,_jelenlegiho: word;

  _matricatipus,_felsegjel,_range,_kiegeszites,_aktmnev: string;
  _tartamstr,_rrendszam,_idotartam,_n1: string;

  _jarmutipus,_ss,_tartamsor,_hIndex,_cc: integer;
  _starthnap,_endhnap,_utmove,_aktmove,_findex: integer;

  _akts1,_ocsz : word;
  _utinfoss    : byte;
  _maymove,_onlyNextYear: boolean;
  _szoko: boolean;
  _matricaPanel,_aktpanel: TPanel;

  _kDAte: TdateTime;

  _y: byte;

  _aktar: integer;

implementation

uses Unit5, Unit12;

{$R *.dfm}


// =============================================================================
          procedure TAUTOPALYAFORM.FormActivate(Sender: TObject);
// =============================================================================

begin

  Top    := _top;
  Left   := _left;
  Height := 768;
  Width  := 1024;

  AktevLabel.caption := inttostr(_aktev);
  AktevLabel.repaint;


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

  Tombbetoltes;
  Arkijelzo;
  KomboToltes;


  // --------------------------------------------------------

  PenztarszamPanel.caption := _homePenztarszam;
  Penztarnevpanel.Caption  := _homePenztarnev;
  Penztarospanel.Caption   := _prosnev;
end;


// =============================================================================
            procedure TAutopalyaForm.ArPanelClick(Sender: TObject);
// =============================================================================

// Ide kattint kiválasztani egy matricát
//

begin
  if not _maymove then exit;

   _akts1 := 0;
  Infoshape.Visible := false;
  infopanel.Visible := False;

  _aktPanel := TPanel(Sender);
  If _aktpanel.caption='-' then
    begin
      _aktpanel.Cursor := crDefault;
      exit;
    end;

  _maymove  := False;
  _pTag     := _aktPanel.Tag;
  _pnev     := _mNev[_ptag];
  _cikkszam := _mKod[_Ptag];
  _ezmegye  := False;

  _aktmatricanev := _PNev + ' MATRICA';
  MatricaTipusPanel.Caption := _aktmatricanev;

  Form1.Logbair('Matricatipusra klikkelt: ' +_aktmatricanev);

  if (_ptag<16) and (_aktev<2024) then _cikkszam := _cikkszam - 1000;

  if _pTag>20 then
    begin
      // Ez megyei matrica lesz

      Form1.Logbair('Megyét választ');

      // Kiválasztja a megye sorszámát (1..20)

      _megyess := selectCounty.showModal;  // Megye sorszámá: _megyess

      if _megyess<0 then
        begin
          // Mégsem megyét választott

          Form1.Logbair('Mégsem választ megyét');
          exit;
        end;


      _ezmegye     := true;
      _aktmegyenev := _megyenev[_megyess-1];

      Form1.Logbair('Ezt a megyét választotta: '+ _aktmegyenev);

      // A cikkszám a megye indexével növekszik

      _cikkszam := _cikkszam + _megyess;

      RangePanel.Caption := _aktmegyenev+ ' VARMEGYE TERÜLETÉRE';
    end else RangePanel.Caption := 'AZ EGÉSZ ORSZÁG TERÜLETÉRE';

  // Az idõtartam lehet: HETI, HAVI, EVES

  _idotartam := Getidotartam(_pTag);

  // Kiszámolja a start napot és idõt, az end napot és idõt
  // és fizetendõ összeget:

//  _onlyNextYear := False;
//  if _idotartam='EVES' then _onlynextyear := True;

  Kiszamol;

  // A két rendszámbeklrõ törölve:

  Rendszamedit.Clear;
  Rrendszamedit.Clear;

  OrszagCombo.ItemIndex := _hIndex;  // országcombot magyarra állítva
  _kategoriaStr         := _pNev; // pl 'D2 havi e-matrica'

  NevEdit.Text := '';
  CimEdit.Text := '';
  Adoszamedit.Text := '';

  with AfasPanel do
    begin
      Top     := 6;
      Left    := 152;
      Visible := True;
    end;

  with Ugyfelpanel do
    begin
      Top     := 180;
      Left    := 38;
      Visible := true;
    end;

  // Még nem lehet jóváhagyni:

  JovahagyoGomb.Enabled := False;

  with Munkapanel do
    begin
      Top       := 205;
      Left      := 8;
      Width     := 1012;
      Height    := 500;
      Visible   := true;
    end;

  _rrendszam    := '';
  _rendszam     := '';

  
      Naptar.CalendarDate := Date;
      Naptar.Enabled := True;
      DatumeloreGomb.Enabled := True;
      DatumVisszaGomb.Enabled := True;

  ActiveControl := NemkerAfastGomb;
end;

// =============================================================================
        procedure TautoPalyaForm.NemkerAfastGombCLick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Ügyfél nem kér áfás számlát');

  UgyfelPanel.visible   := False;
  Jovahagyogomb.Enabled := True;
  ActiveControl         := RendSzamEdit;
end;

// =============================================================================
          procedure TautoPalyaForm.AfastKerGombCLick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Az ügyfél áfás számlát kér');
  AfasPanel.visible := false;
  Activecontrol := Nevedit;
end;

// =============================================================================
          procedure TAUTOPALYAFORM.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := false;
  Modalresult := _mResult;
end;

// =============================================================================
                         procedure TAutopalyaForm.Kiszamol;
// =============================================================================

// Kiszámolja a matrica érvényességi idõtartamát és a fizetendõ összeget

begin
  If _idotartam='' then _idotartam:= 'HETI';
  _startDatum := Naptar.CalendarDate;

  {
  if _onlyNextYear then
    begin
      _startdatum := encodedate(2024,1,1);
      _startPerc  := '00.00.00';
    end else
    begin
  }

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
      _endnap:= _startNap;
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
       _endev    := _startev+1;
       _endho    := 1;
       _endnap   := 31;
       _endDatum := encodeDate(_endev,_endho,_endNap);
    end;

  _startdatum := encodeDate(_startev,_startho,_startnap);
  _endDatum   := encodeDate(_endev,_endho,_endnap);

  _starthnap := dayoftheweek(_startDatum);
  _endHnap   := Dayoftheweek(_endDatum);

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
      _fizetendo := _mAr[_pTag];
      _oldar := _mOldAr[_ptag];
      if (_aktev<2024) AND (_oldAr>0) then _fizetendo := _oldar;

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

  ibdbase.Connected := True;
  if ibTranz.InTransaction then ibTranz.Commit;

  _pcs := 'SELECT * FROM FELSEGJEL ORDER BY ORSZAGNEV';

  with IbQuery do
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
      _onev := trim(IbQuery.Fieldbyname('ORSZAGNEV').asString);
      _okod := ibQuery.FieldByName('KODSZAM').asInteger;
      _fjel := trim(ibQuery.FieldByName('BETUJEL').asstring);

      OrszagCombo.Items.Add(_onev);
      if _okod=75 then _hindex := _cc; // magyarország kódja

      inc(_cc);

      _feljel[_cc] := _fjel;
      _ccode[_cc]  := _okod;

      ibQuery.Next;
    end;

  ibQuery.close;
  ibDbase.close;
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
          procedure TAutopalyaForm.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('A vissza-gombra klikkelt');
  ModalResult :=2;
end;


// #############################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
         procedure TAUTOPALYAFORM.JOVAHAGYOGOMBClick(Sender: TObject);
// =============================================================================

// ITT JÓVÁHAGYJA A MATRICA-ADATLAPON SZEREPLÕ ADATOK HELYESSÉGÉT

var i: integer;
   _okrsz: string;
   _voltBetu: boolean;

begin
  // Elöször a rendszám adatait kell ellenörizni:

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

   // A rendszám tömöritése:

  _okrsz    := '';
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

  // A rendszámban szerepel-e betü ?

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

  // Itt a rendszám rendben van !

  _rendszam := _OKRSZ;

  _findex      := OrszagCombo.ItemIndex;
  _felsegjel   := _feljel[_findex+1];

  _countryName := _felsegjel+' - ' + OrszagCombo.Items[_findex];
  _countryCode := _ccode[_fIndex+1];

  Form1.Logbair('  - Rendszám: '+_rendszam);
  Form1.Logbair('  - Ország  : '+_countryname);

  //VisszaGomb.Visible := False;
  //  InfoDisplay;

  VmTipusPanel.caption := _aktmatricanev;
  vmtipuspanel.Repaint;

  if _ezmegye then VrangePanel.Caption := _aktmegyenev + ' VARMEGYE TERÜLETÉRE'
  else vRangePanel.Caption := 'AZ EGÉSZ ORSZÁG TERÜLETÉRE';

  vRangePanel.Repaint;

  FelsegPanel.Caption := _felsegJel;
  with KifizetendoPanel do
    begin
      Color      := clWhite;
      Font.color := clBlack;
    end;

  IdoIntervalumDisplay;

  // itt az adatok rendben vannak - el lehel küldeni

  KonyveloGomb.Visible    := True;
  NemKonyveloGomb.Visible := True;

  with Vegtakaro do
    begin
      Left    := 0;
      Top     := 0;
      Visible := true;
    end;

  Konyvelogomb.Enabled := True;
  ActiveControl        := Konyvelogomb;

end;


// =============================================================================
                 procedure TAutopalyaForm.konyvelogombClick(Sender: TObject);
// =============================================================================

// Az összes adat kijelzése után megerõsiti, hogy kéri elözetes igénylést

begin
  KonyveloGomb.Visible    := False;
  NemKonyveloGomb.Visible := False;

  Form1.Logbair('Elküldi a matrica elözetes kérését');

  _httpTipus := 'TEST AAK';

  _tranzakcioOke := 0;
  TranzakcioMenet;

  if _tranzakcioOke<>1 then
    begin
      Hibauzenet;
      Exit;
    end;

  inc(_lastMatrica);
  _bizonylatszam := 'AM' + Form1.Hatnulele(_LastMatrica);

  Form1.Logbair('Pozitiv visszaigazolás érkezett');
  with VisszaIgazoloPanel do
    begin
      Top := 540;
      Left := 190;
      Visible := True;
      Bringtofront;
    end;

  _idos := timetostr(time);
  Form1.MatricaSellerCopy;
  ActiveControl := LiveAAKGomb;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.CANCELAAKGOMBClick(Sender: TObject);
// =============================================================================

begin
  _httpTipus := 'CANCEL AAK';
  _tranzakcioOke := 0;
  CancelAAKRutin;

end;

// =============================================================================
                 procedure TAutopalyaForm.TranzakcioMenet;
// =============================================================================


// Egy tranzakició lefolytatása: TEST AAK, LIVE AAK,

begin
  _tranzakcioOke := 0;
  if _httpTipus = 'TEST AAK' then
    begin
      TestAAKRutin;
      exit;
    end;

  if _httpTipus = 'LIVE AAK' then
    begin
      LiveAAKRutin;
      exit;
    end;
end;

// =============================================================================
              procedure TAutopalyaForm.TestAAkRutin;
// =============================================================================


// a TEST AAK rutin lefolytatása:

begin
  _akcio := 'TEST';

  _reqrow[1] := '<Message>';
  _reqrow[2] := '<MessageType>TEST AAK</MessageType>';
  _reqrow[3] := '<TerminalId>' + _terminalId + '</TerminalId>';
  _reqrow[4] := '<UserName>' + _username + '</UserName>';
  _reqrow[5] := '<UserPassword>' + _password + '</UserPassword>';
  _reqrow[6] := '<ProductId>'+inttostr(_cikkszam)+'</ProductId>';
  _reqrow[7] := '<RegistrationNumber>'+_rendszam+'</RegistrationNumber>';
  _reqrow[8] := '<CountryCode>'+inttostr(_countryCode)+'</CountryCode>';
  _reqrow[9] := '<VFD>' + _vfd + '</VFD>';
  _reqrow[10]:= '<LimitCheck>Y</LimitCheck>';
  _reqrow[11]:= '</Message>';

  _reqpieces := 11;

  // A require tömb elökészítése megtörtént mehet a csomagküldés:

  Form1.CsomagKuldes;

  Form1.Logbair('Csomagküldés feldolgozva, lehet kiértékelni');

  // A csomagra, ha jött válasz, akkor a _reprow-tömb nem üres

  if _reppieces=0 then
    begin
      // Ha _reprow tömb üres (nincs válasz) itt vége a matrica rendelésnek
      _hibauzenet := 'NEM ÉRKEZETT VÁLASZ';

      //  Kijelzi a hibaüzenetet, majd TOVÁBB-gomb modalresult=2 -> fõmenü
      HibaUzenet;
      Exit;
    end;

  // Itt megjött a válasz, lehet értékelni a benne lévõ adatokat:

  ReplyErtekelo;
end;

// =============================================================================
                  procedure TAutopalyaForm.ReplyErtekelo;
// =============================================================================

begin

  // Ha az xrstatusid nem volt oke adatkiértékelésnél, akkor az a hibaüzenetben

  if not GetxRAdatok then  exit;
  if _akcio = 'TEST' then
    begin

      // A visszaküldött fizetendõ összeg kibontása és kijelzése

      with AutopalyaForm.KifizetendoPanel do
        begin
          Font.color := clWhite;
          Color      := clRed;
          Caption    := Form1.FtForm(_fizetendo);
          Repaint;
        end;
       exit;
    end;

  // --------------------------------------------------------

  IF _akcio = 'LIVE' then
    begin
      _rendszam    := _xrRegistrationNumber;
      _referenceId := _xrReferenceId;
      _startDatums := Pontoz(_xrVFD);


      val(leftstr(_xrVFD,4),_startev,_code);
      if _code<>0 then _startev := 0;

      val(midstr(_xrVFD,5,2),_startho,_code);
      if _code<>0 then _startho := 0;

      val(midstr(_xrVFD,7,2),_startnap,_code);
      if _code<>0 then _startnap := 0;


      if (_startev=0) or (_startho=0) or (_startNap=0) then
        begin
          _hibauzenet := 'HIBÁS KEZDÕNAP LETT VISSZAIGAZOLVA';
          _tranzakcioOke := 0;
          Exit;
        end;

      if _fizetendo=0 then
        begin
          _hibauzenet := 'HIBÁS EGYSÉGÁRRAL LETT VISSZAIGAZOLVA';
          _tranzakcioOke := 0;
          Exit;
        end;

      if _rendszam='' then
        begin
          _hibauzenet := 'HIBÁS RENDSZÁM LETT VISSZAIGAZOLVA';
          _tranzakcioOke := 0;
          Exit;
        end;

      AutopalyaForm.KiFizetendoPanel.Font.Color := clBlack;
      AutopalyaForm.KiFizetendoPanel.Color      := clWhite;
      Autopalyaform.KifizetendoPanel.Caption    := Form1.FtForm(_fizetendo);
      AutoPalyaForm.IdoIntervalumDisplay;
      exit;
    end;
end;


// =============================================================================
                 procedure TAutopalyaForm.LiveAAKRutin;
// =============================================================================

begin

  _akcio := 'LIVE';

  _reqrow[1] := '<Message>';
  _reqrow[2] := '<MessageType>LIVE AAK</MessageType>';
  _reqrow[3] := '<TransactionId>'+_xrTransactionId+'</TransactionId>';
  _reqrow[4] := '</Message>';

  _reqpieces := 4; // ENNYI TÉTELSOR VAN AZ XML-BEN
  Form1.CsomagKuldes;

  if _reppieces=0 then
    begin
      _hibauzenet := 'NEM JÖTT VÁLASZ A KÉRÉSRE !';
      HibaUzenet;
      Exit;
    end;
  ReplyErtekelo;
end;

// =============================================================================
                  function TAutopalyaForm.GetxrAdatok: boolean;
// =============================================================================

begin
  result := False;

  _xrMessageType       := trim(Form1.GetMezo('MessageType'));
  _xrStatusId          := trim(Form1.Getmezo('StatusId'));
  _xrStatusDescription := trim(Form1.Getmezo('StatusDescription'));
  _xrTransactionId     := trim(Form1.Getmezo('TransactionId'));
  _xrTransactionDate   := trim(Form1.Getmezo('TransactionDate'));

  _xrProductId         := trim(Form1.Getmezo('ProductId'));
  _xrProductName       := trim(Form1.Getmezo('ProductName'));
  _xrAmount            := trim(Form1.Getmezo('Amount'));
  _xrRegistrationNumber:= trim(Form1.Getmezo('RegistrationNumber'));
  _xrCountryName       := trim(Form1.Getmezo('CountryName'));
  _xrVFD               := trim(Form1.Getmezo('VFD'));
  _xrVTD               := trim(Form1.Getmezo('VTD'));
  _xrCategory          := trim(Form1.Getmezo('Category'));

  _xrDurHUN              := trim(Form1.Getmezo('DurationHUN'));
  _xrDurENG              := trim(Form1.Getmezo('DurationEN'));
  _xrReferenceId       := trim(Form1.Getmezo('ReferenceId'));

  _xrOutletName        := trim(Form1.Getmezo('OutletName'));
  _xrOutletAddress     := trim(Form1.Getmezo('OutletAddress'));
  _xrOutletTaxNo       := trim(Form1.Getmezo('OutletTaxNo'));

  _xrOperatorId        := trim(Form1.Getmezo('OperatorID'));
  _xrReceiptNumber     := trim(Form1.Getmezo('ReceiptNumber'));

  If _xrstatusId<>'00OK' then
    begin
     _HibaUzenet := _xrStatusDescription;
    end
    else
    begin
      _tranzakcioOke := 1;
      _tranzakcio := _xrTransactionId;
      result := true;
    end;
  val(_xrAmount,_fizetendo,_code);
  IF _CODE<>0 then _fizetendo := 0;
end;

// =============================================================================
         procedure TAutopalyaform.LiveAAKgombClick(Sender: TObject);
// =============================================================================

begin
  VisszaIgazoloPanel.Visible := False;
  Form1.Logbair('Kéri az elözetesen kért matricát');

  _httpTipus := 'LIVE AAK';
  _tranzAkcioOke := 0;

  TranzAkcioMenet;
  if _tranzakcioOke<>1 then
    begin
       Form1.Logbair('Negativ válasz: '+_hibauzenet);
       HibaUzenet;
       Exit;
    end;

  Form1.Logbair(_bizonylatszam+' bizonylat könyvelése');

  Form1.Konyveles('M');
  Form1.MatricaCustomerCopy;

  if _kellAfas then
    begin
      Form1.AfasSzamla;
      MatricaBekuldes;
    end;

  _kellafas := False;

  SikerBaner.visible := true;
  ReturnGomb.Visible := True;
  ActiveControl := ReturnGomb;
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
      Top := 530;
      Left := 200;
      Visible := true;
    end;
  ActiveControl := TovabbGomb;
end;

// =============================================================================
                  procedure TAUTOPALYAFORM.CANCELAAKRutin;
// =============================================================================

begin
  VisszaIgazoloPanel.visible := False;

  _httpTipus := 'CANCEL AAK';

  _reqrow[1] := '<Message>';
  _reqrow[2] := '<MessageType>CANCEL AAK</MessageType>';
  _reqrow[3] := '<TransactionId>'+_xrTransactionId+'</TransactionId)';
  _reqrow[4] := '</Message>';

  _reqpieces := 4;
  Form1.CsomagKuldes;
  Modalresult := 2;
end;

// =============================================================================
           procedure TAUTOPALYAFORM.RETURNGOMBClick(Sender: TObject);
// =============================================================================

begin
  _Fizetendo := 0;
  ModalResult := 1;
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
  ActiveControl := AdoszamEdit;
end;

procedure TAUTOPALYAFORM.ADOSZAMEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  ActiveControl := UgyfelOkegomb;
end;


// =============================================================================
             procedure TAUTOPALYAFORM.UGYFELOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ugyfelnev := trim(Nevedit.Text);
  if _ugyfelnev<>'' then
    begin
      _ugyfelcim := trim(Cimedit.text);
      _ugyfAdoszam := trim(Adoszamedit.Text);
      _kellafas := true;
    end;
  Ugyfelpanel.Visible := False;
  JovahagyoGomb.Enabled := true;
  ActiveControl := Rendszamedit;
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

// =============================================================================
         procedure TAUTOPALYAFORM.mmatricaOkeGombClick(Sender: TObject);
// =============================================================================

begin
  _maymove := true;
  ArpanelClick(Nil);
end;



// =============================================================================
    procedure TAUTOPALYAFORM.FP06MouseMove(Sender: TObject; Shift: TShiftState;
                                                                 X, Y: Integer);
// =============================================================================

var _tag: byte;
    _info: string;

begin
  IF NOT _MAYMOVE then exit;

  _aktpanel := TPanel(Sender);
  if _aktpanel.caption='-' then
    begin
      _aktpanel.Cursor := crDefault;
      exit;
    end;

  _tag := _aktpanel.Tag;
  _cikkszam := _mKod[_tag];
  _info := _mNev[_tag];
  _info := _info + ' MATRICA';

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
          function TautopalyaForm.getIdoTartam(_cc: word): string;
// =============================================================================


var _i: string;

begin
  if _cc<6 then _i := 'NAPI';

  if (_cc>5) and (_cc<11) then _i := 'HETI';

  IF (_cc>10) and (_cc<16) then _i := 'HAVI';

  if (_cc>15) then _i := 'EVES';

 Result := _i;
end;

// =============================================================================
           function TAutopalyaForm.Pontoz(_dstring: string):string;
// =============================================================================

begin
  result := leftstr(_dstring,8);
  result := leftstr(result,4)+'.'+midstr(result,5,2)+'.'+midstr(result,7,2);
end;


// =============================================================================
       procedure TAutopalyaForm.RendszamEditKeyDown(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  IF ord(key)=13 then ActiveControl := rrendszamedit;
  if ord(key)=9 then Activecontrol := rrendszamedit;
end;

// =============================================================================
       procedure TAutopalyaForm.RRendszamEditKeyDown(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

begin
   IF ord(key)=13 then ActiveControl := Jovahagyogomb;
   if ord(key)=9 then Activecontrol  := Jovahagyogomb;
end;

// =============================================================================
               procedure TAutopalyaForm.NaptarChange(Sender: TObject);
// =============================================================================

begin
  _startDatum := Naptar.CalendarDate;
  if _startDatum<Date then
    begin
      Naptar.CalendarDate := date;
      Activecontrol := Naptar;
      Exit;
    end;
  Kiszamol;
end;

// =============================================================================
        procedure TAutopalyaForm.DatumVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  _startdatum := Naptar.CalendarDate;

  _startnap   := dayof(_startdatum);
  _startho    := monthof(_startdatum);
  _startev    := yearof(_startDatum);


  if (_aktev=_startev) and (_aktho=_startho) then exit;

  dec(_startho);

  if _startho<1 then
    begin
      _startho := 12;
      dec(_startev);
    end;

  _startnap           := _havinap[_startho];
  _startDatum         := encodeDate(_startev,_startho,_startnap);
  Naptar.CalendarDate := _startDatum;

  if (_aktho=_startho) and (_aktev=_startev) then
                                    DatumVisszaGomb.enabled := false;
  Kiszamol;
  ActiveControl := JovahagyoGomb;
end;

// =============================================================================
         procedure TAutopalyaForm.DatumEloreGombClick(Sender: TObject);
// =============================================================================

begin
   _startdatum := Naptar.CalendarDate;
  _startho     := monthof(_startdatum);
  _startnap    := 1;

  DatumVisszaGomb.Enabled := true;

  _startev := yearof(_startdatum);
  inc(_startho);

  if _startho>12 then
    begin
      _startho := 1;
      inc(_startev);
    end;

  _startdatum := EncodeDate(_startev,_startho,_startnap);
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
               procedure TautoPalyaForm.ArKijelzo;
// =============================================================================

var _tag,_oldar: integer;
    _ars,_aktnev: string;

begin
  _y := 1;
  while _y<=25 do
    begin
      _aktPanel := _ppanel[_y];
      _tag      := _aktPanel.tag;
      _cikkszam := _mKod[_tag];
      _aktar    := _mAr[_tag];
      _oldar    := _mOldAr[_tag];
      _aktnev   := _mNev[_tag];
      if (_aktev<2024) and (_oldar>0) then _aktar := _oldar;

      if (_aktnev='') or (_aktar=0) then _ars := '-'
      else _ars := arfdisp(_aktar);

      _aktpanel.Caption := _ars;
      inc(_y);
    end;
end;

// =============================================================================
         function TAutoPalyaForm.Arfdisp(_num: integer): string;
// =============================================================================

var _ww,_f1: byte;

begin
  If _num=0 then
    begin
      result := '-';
      exit;
    end;

  result := inttostr(_num);
  _ww := length(result);
  if _ww<4 then exit;

  _f1 := _ww-3;
  result := leftstr(result,_f1)+'.'+midstr(result,_f1+1,3);
end;



// =============================================================================
           procedure TAUTOPALYAFORM.NEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
            procedure TAUTOPALYAFORM.NEVEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWhite;
end;

// =============================================================================
               procedure TAutopalyaForm.MatricaBekuldes;
// =============================================================================

begin
  _pcs := 'INSERT INTO AUTOPALYA (PENZTAR,DATUM,IDO,MATRICATIPUS,FIZETENDO,';
  _pcs := _pcs + 'UGYFELNEVE,UGYFELCIME,ADOSZAMA)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + _homePenztarszam + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos  + chr(39) + ',';
  _pcs := _pcs + chr(39) + _kategoriastr + chr(39) + ',';
  _pcs := _pcs + inttostr(_fizetendo) + ',';
  _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ugyfelcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ugyfadoszam + chr(39) + ')';
  RemoteParancs(_pcs);
end;

// =============================================================================
          procedure TautoPalyaForm.RemoteParancs(_ukaz: string);
// =============================================================================

begin
  _kapcsolva := True;
  RemoteDbase.close;
  RemoteDbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\MATRICA.FDB';

  TRY
    RemoteDbase.connected := True;
  EXCEPT
    _kapcsolva := False;
  END;
  If _kapcsolva then
    begin
      if remoteTranz.InTransaction then remoteTranz.Commit;
      remotetranz.StartTransaction;
      with RemoteQuery do
        begin
          Close;
          sql.clear;
          sql.add(_ukaz);
          ExecSql;
        end;
      remotetranz.commit;
      remotedbase.close;
    end;
end;

// =============================================================================
               procedure TautoPalyaForm.Tombbetoltes;
// =============================================================================

var _qq: byte;

begin
  _ppanel[1]  := FP01;
  _ppanel[2]  := FP02;
  _ppanel[3]  := FP03;
  _ppanel[4]  := FP04;
  _ppanel[5]  := FP05;
  _ppanel[6]  := FP06;
  _ppanel[7]  := FP07;
  _ppanel[8]  := FP08;
  _ppanel[9]  := FP09;
  _ppanel[10] := FP10;
  _ppanel[11] := FP11;
  _ppanel[12] := FP12;
  _ppanel[13] := FP13;
  _ppanel[14] := FP14;
  _ppanel[15] := FP15;
  _ppanel[16] := FP16;
  _ppanel[17] := FP17;
  _ppanel[18] := FP18;
  _ppanel[19] := FP19;
  _ppanel[20] := FP20;
  _ppanel[21] := FP21;
  _ppanel[22] := FP22;
  _ppanel[23] := FP23;
  _ppanel[24] := FP24;
  _ppanel[25] := FP25;

  _qq := 1;
  while _qq<=25 do
    begin
      _mkod[_qq]  := 0;
      _mNev[_qq]  := '';
      _mAr[_qq]   := 0;
      _mOldAr[_qq]:= 0;
      inc(_qq);
    end;


  _mKod[6] := 4034;
  _mKod[7] := 4024;
  _mKod[8] := 4644;
  _mKod[9] := 4604;
  _mKod[10]:= 4057;

  _mNev[6] := 'D1 HETI MOTOROS';
  _mNev[7] := 'D1 ORSZÁGOS HETI AUTÓS';
  _mNev[8] := 'D2 ORSZÁGOS HETI AUTÓS';
  _mNev[9] := 'U ORSZÁGOS HETI AUTÓS';
  _mNev[10] := 'B2 ORSZÁGOS HETI AUTÓS';

  _mAr[6]  := 3200;
  _mAr[7]  := 6400;
  _mAr[8]  := 9310;
  _mAr[9]  := 6400;
  _mAr[10]  := 20640;

  _mOldAr[6] := 2750;
  _mOldAr[7] := 5500;
  _mOldAr[8] := 8000;
  _mOldAr[9] := 5500;
  _mOldAr[10] := 17730;

  // -------------------------------

  _mKod[11] := 4035;
  _mKod[12] := 4025;
  _mKod[13] := 4645;
  _mKod[14] := 4605;
  _mKod[15] := 4058;

  _mNev[11] := 'D1 HAVI MOTOROS';
  _mNev[12] := 'D1 ORSZÁGOS HAVI AUTÓS';
  _mNev[13] := 'D2 ORSZÁGOS HAVI AUTÓS';
  _mNev[14] := 'U ORSZÁGOS HAVI AUTÓS';
  _mNev[15] := 'B2 ORSZÁGOS HAVI AUTÓS';

  _mAr[11]  := 5180;
  _mAr[12]  := 10360;
  _mAr[13]  := 14670;
  _mAr[14]  := 10360;
  _mAr[15]  := 29270;

  _mOldAr[11] := 4450;
  _mOldAr[12] := 8900;
  _mOldAr[13] := 12600;
  _mOldAr[14] := 8900;
  _mOldAr[15] := 25150;

  // -------------------------------

  _mKod[17] := 4026;
  _mKod[18] := 3646;
  _mKod[19] := 4606;

  _mNev[17] := 'D1 ORSZÁGOS ÉVES AUTÓS';
  _mNev[18] := 'D2 ORSZÁGOS ÉVES AUTÓS';
  _mNev[19] := 'U ORSZÁGOS ÉVES AUTÓS';

  _mAr[17]  := 57250;
  _mAr[18]  := 81280;
  _mAr[19]  := 37260;

  // -------------------------------

  _mKod[22] := 4520;
  _mKod[23] := 4540;
  _mKod[24] := 4500;

  _MnEV[22] := 'D1 VÁRMEGYEI ÉVES AUTÓS';
  _MnEV[23] := 'D2 VÁRMEGYEI ÉVES AUTÓS';
  _MnEV[24] := 'U  VÁRMEGYEI ÉVES AUTÓS';

  _mAr[22] := 6660;
  _mAr[23] := 13330;
  _mar[24] := 6660;
end;









// =============================================================================
// =============================================================================
// =============================================================================



{ Melléklet:

 TestAAK küldés végpontról

        <Message>
        <MessageType>TEST AAK</MessageType>- fix
        <TerminalId>terminalid</TerminalId> - terminál azonosító
        <PIN>:pin</PIN>- nem értelmezett kassza és web esetén
        <UserName>username</UserName>  - nem értelmezett pos esetén
        <UserPassword>userpassword</UserPassword>  - nem értelmezett pos esetén
        <ProductId>productid</ProductId> - termék kódja
        <RegistrationNumber>registrationnumber</RegistrationNumber> rendszám
        <CountryCode>countrycode</CountryCode> ország kódja
        <VFD>vfd</VFD> érvényesség kezdete yymmdd formátumban
        <LimitCheck>Y</LimitCheck>
        </Message>

TestAAK válasz

        <Message>
        <MessageType>TEST AAK</MessageType>- fix
        <TerminalId>terminalid</TerminalId> - terminál azonosító
        <OperatorId>operatorid</OperatorId>
        <ProductId>productid</ProductId> - termék kódja
        <ProductName>productname</ProductName> termék neve
        <Amount>amount</Amount> termék ára
        <RegistrationNumber>registrationnumber</RegistrationNumber> rendszám
        <CountryName>countryname</CountryName> ország neve
        <VFD>vfd</VFD> érvényesség kezdete
        <TransactionId>transactionid</TransactionId> tranzakció azonosító
        <TransactionDate>transactiondate</TransactionDate> tranzakció dátuma
        <OutletName>outletname</OutletName> eladóhely neve
        <OutletAddress>outletaddress</OutletAddress> eladóhely címe
        <ReceiptNumber>receiptnumber</ReceiptNumber> blokk azonosító (blokra lehet nyomt.)
        <VTD>20221104235959</VTD> érvényesség vége
        <DurationHUN>heti/10 napos (országos) </DurationHUN> idõszak szövegesen magyarul
        <DurationEN>weekly/10 days (national)</DurationEN> idõszak szövegesen angolul
        <Category>D1        </Category> kategória
        <StatusId>statusid</StatusId> statusz kód
        <StatusDescription>statusdescription</StatusDescription>  státusz leírás hiba esetén
        </Message>

--------------------------------------------------------------------------------

LiveAAK küldés végpontról

        <Message>
        <MessageType>LIVE AAK</MessageType>- fix
        <TransactionId>transactionid</TransactionId>
        <CardType>:cardtype</ CardType >kártya típusa EUROWAG/DKV/Reload útdíjkártya/Eurotoll/E100 fizetés esetén lehetséges értékei EUROWAG, DKV, UK. ETOLL, E100
        <CardNumber>:CardNumber </CardNumber>kártya száma EUROWAG/DKV/UK/Eurotoll/E100 fizetés esetén
        <ExpDate>:ExpDate </ExpDate>kártya lejárati dátuma EUROWAG/DKV/UK/Eurotoll/E100 fizetés esetén

    DKV kártya használata esetén 2 lehetséges opció van:
    1)	17 hosszú kártyaszám küldése. Ilyenkor nincs Restriction kód ellenõrzés
    2)	17 hosszú kártyaszám és az azt követõ 9 karakter küldés (összesen 26 karakter): Ebben az esetben ellenõrzésre kerül a Restriction kód is.


LiveAAK válasz

        <Message>
        <MessageType>LIVE AAK</MessageType>- fix
        <OutletName>outletname</OutletName> eladóhely neve
        <OutletAddress>outletaddress</OutletAddress> eladóhely címe
        <OutletTaxNo>outlettaxno</OutletTaxNo> eladóhely adószáma
        <ProductName>productname</ProductName> termék neve
        <Amount>amount</Amount> termék ára
        <RegistrationNumber>registrationnumber</RegistrationNumber> rendszám
        <CountryName>countryname</CountryName> ország neve
        <VFD>vfd</VFD> érvényesség kezdete
        <VTD>vtd</VTD> érvényesség vége
        <TransactionId>transactionid</TransactionId> tranzakció azonosító
        <ReferenceId>referenceid</ReferenceId> matrica azonosító
        <TerminalId>terminalid</TerminalId>terminál azonosító
        <TransactionDate>transactiondate</TransactionDate> tranzakció dátuma
        <Print2>*PRINT2*<PaymentTransactionId> EUROWAG tranzakció ID, csak EUROWAG tranzakció esetén jön </PaymentTransactionId>
        </Print2>
        <DurationHUN>heti/10 napos (országos) </DurationHUN> idõszak szövegesen magyarul
        <DurationEN>weekly/10 days (national)</DurationEN> idõszak szövegesen angolul
        <Category>D1        </Category> kategória
        <StatusId>statusid</StatusId> statusz kód
        <StatusDescription>statusdescription</StatusDescription>  státusz leírás hiba esetén
        </Message>

   A <Print2> tag-ben lévõ információt figyelmen kívül kell hagyni, kivéve, ha EW tranzakció esetén a fizetési tranzakció számát is a bizonylatra szeretnénk nyomtatni.


--------------------------------------------------------------------------------

CancelAAK küldés végpontról

	<Message>
        <MessageType>CANCEL AAK</MessageType>- fix
        <TransactionId>transactionid</TransactionId> tranzakció azonosító
        </Message>

CancelAAK válasz

        <Message>
        <MessageType>CANCEL AAK</MessageType>- fix
        <TransactionId>transactionid</TransactionId> tranzakció azonosító
        <StatusId>statusid</StatusId> statusz kód
        <StatusDescription>statusdescription</StatusDescription>  státusz leírás hiba esetén
        </Message>


--------------------------------------------------------------------------------

StornoAAK

        <Message>
        <MessageType>STORNO AAK</MessageType>
        <TransactionId>:transactionid</TransactionId>
        </Message>


StornoAAK válasz

        <Message>
        <MessageType>STORNO AAK</MessageType>
        <TransactionId>:transactionid</TransactionId>
        <StatusId>:statusid</StatusId>
        <StatusDescription>:statusdescription</StatusDescription>
        </Message>

  Amennyiben a StatusId-ban visszakapott érték <> 00OK, akkor a tranzakció végrehajtása nem sikerült. A hiba szöveges leírása ilyen esetekben a StatusDescription tag-ban található.


--------------------------------------------------------------------------------
Eladói példány adattartalma/Content of the Seller's copy

e-matrica ellenõrzõ szelvény / e-vignette control slip
           Eladói példány / Seller's copy
               Nem adóügyi bizonylat!
               Not taxation document!

Üzleti partner neve + székhelye + adószáma/ Business partner name + registered (head) office address + tax number
Viszonteladói iroda neve és címe / Reseller office name and address
Viszonteladói pénztár / Reseller cash register/terminal ID

Vásárlás idõpontja / Date of purchase: 	 éééé.hh.nn óó:pp:ss /yyyy.mm.dd hour:min:sec
             Rendszám / License plate number:  AAA111

            Felségjelzés / Country code: H - Magyarország
            Kategória / Category:D1

Típus / Type: Heti/10 napos (országos)
	      Weekly/10-day (national)

Érvényesség kezdete / Start of validity: éééé.hh.nn óó:pp:ss /yyyy.mm.dd hour:min:sec
Érvényesség vége / End of validity: éééé.hh.nn óó:pp:ss /yyyy.mm.dd hour:min:sec
Termék / Product: D1 Heti/10 napos (országos)
                  D1 Weekly/10-day (national)
Tr. azonosító/ tr. ID: 9AY4HJD0M1
                  Ár / Price: XXXXX HUF

              -------------------------------------
              Ügyfél aláírása / Customer's signature

   Aláírásommal elismerem a fenti adatok helyességét.
   I acknowledge the correctness of the above data with my signature.
   Eladói példány, az e-matrica megvásárlását nem igazolja, úthasználatra nem jogosít.
   Seller's copy, does not certify the purchase of the e-vignette, does not authorise for road use.

--------------------------------------------------------------------------------

   Vevõi példány adattartalma/Content of the Customer's copy


    e-matrica ellenõrzõ szelvény / e-vignette control slip
                 Vevõi példány / Customer's copy
                     Nem adóügyi bizonylat!
                     Not taxation document!

Üzleti partner neve + székhelye + adószáma/ Business partner name + registered (head) office address + tax number
Viszonteladói iroda neve és címe / Reseller office name and address
Viszonteladói pénztár / Reseller cash register/terminal ID

NÚSZ Call Center: +36 (36) 587-500
Vásárlás idõpontja / Date of purchase:éééé.hh.nn óó:pp:ss /yyyy.mm.dd hour:min:sec
Rendszám / License plate number:AAA111

Felségjelzés / Country code: H - Magyarország
Kategória / Category: D1
Típus / Type: Heti/10 napos (országos)
              Weekly/10-day (national)

Érvényesség kezdete / Start of validity: éééé.hh.nn óó:pp:ss /yyyy.mm.dd hour:min:sec
Érvényesség vége / End of validity: éééé.hh.nn óó:pp:ss /yyyy.mm.dd hour:min:sec
Matricaazonosító / Vignette unique ID: xxxxxxxxxxxxxxxxxxxxx
Termék / Product: D1 Heti/10 napos (országos)
                  D1 Weekly/10-day (national)
Tr. azonosító / Tr. ID:	9AY4HJD0M1
Ár / Price: XXXXX  HUF

           -------------------------------------------------------------

           Eladóhely aláírása + PH / Seller's signature + place of stamp
   Az adatok helyszínen történõ módosítását a vásárlástól számított "x" percen
  belül lehet kezdeményezni./ Modification of the data on site can be initiated
           within x" minutes after the date and time of purchase "
           Kérjük a bizonylatot a lejárat után 2 évig megõrizni!
                   Keep it for 2 years after expiration!

}










































end.
