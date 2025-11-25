unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBQuery,Strutils,
  IBCustomDataSet, IBTable, DateUtils, Grids, Calendar, ComCtrls, DBGrids;

type
  TTRANZDIJ = class(TForm)
    MENUPANEL: TPanel;
    HAVIBEDOLGGOMB: TBitBtn;
    NAPIBEDOLGGOMB: TBitBtn;
    TRANZTABLA: TIBTable;
    TRANZQUERY: TIBQuery;
    TRANZDBASE: TIBDatabase;
    TRANZTRANZ: TIBTransaction;
    SETMNBGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    BFTABLA: TIBTable;
    BFQUERY: TIBQuery;
    BFDBASE: TIBDatabase;
    BFTRANZ: TIBTransaction;
    BTTRANZ: TIBTransaction;
    BTDBASE: TIBDatabase;
    BTQUERY: TIBQuery;
    ELSZAMQUERY: TIBQuery;
    ELSZAMDBASE: TIBDatabase;
    ELSZAMTRANZ: TIBTransaction;
    NAPTARPANEL: TPanel;
    NAPTAR: TCalendar;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    NAPTARDATUMPANEL: TPanel;
    DATUMOKEGOMB: TBitBtn;
    DATUMMEGSEMGOMB: TBitBtn;
    memopanel: TPanel;
    MemoTabla: TMemo;
    Label1: TLabel;
    CSIKPANEL: TPanel;
    CSIK: TProgressBar;
    CSIK2: TProgressBar;
    Shape2: TShape;
    Shape1: TShape;
    Shape3: TShape;
    Label2: TLabel;
    Label3: TLabel;
    Shape4: TShape;
    BitBtn3: TBitBtn;
    DISPLAYMENUPANEL: TPanel;
    EGYNAPADATAIGOMB: TBitBtn;
    Label4: TLabel;
    EGYHOADATAIGOMB: TBitBtn;
    Label5: TLabel;
    DMEGSEMGOMB: TBitBtn;
    Shape5: TShape;
    DISPLAYPANEL: TPanel;
    displayracs: TDBGrid;
    DISPLAYSOURCE: TDataSource;
    DISPVISSZAGOMB: TBitBtn;
    SSELLHI: TPanel;
    SBUY: TPanel;
    SBUYHI: TPanel;
    SSELL: TPanel;
    SCONV: TPanel;
    SCONVHI: TPanel;
    SSFEE: TPanel;
    SBUYHP: TPanel;
    SSELLHP: TPanel;
    SCONVHP: TPanel;
    Panel11: TPanel;
    focimpanel: TPanel;
    RECEPTQUERY: TIBQuery;
    RECEPTDBASE: TIBDatabase;
    RECEPTTRANZ: TIBTransaction;
    ALLGOMB: TBitBtn;
    BESTGOMB: TBitBtn;
    EASTGOMB: TBitBtn;
    PANNONGOMB: TBitBtn;
    CEGVALTOPANEL: TPanel;
    UGYFELPANEL: TPanel;
    Panel2: TPanel;
    TRANZTABLACASHIER: TSmallintField;
    TRANZTABLADISTRICT: TSmallintField;
    TRANZTABLAFIRMLETTER: TIBStringField;
    TRANZTABLANAP: TSmallintField;
    TRANZTABLANAPKESZ: TSmallintField;
    TRANZTABLABUYLOW: TFloatField;
    TRANZTABLABUYHIPIECE: TIntegerField;
    TRANZTABLABUYHI: TFloatField;
    TRANZTABLASELLLOW: TFloatField;
    TRANZTABLASELLHIPIECE: TIntegerField;
    TRANZTABLASELLHI: TFloatField;
    TRANZTABLACONVLOW: TFloatField;
    TRANZTABLACONVHIPIECE: TIntegerField;
    TRANZTABLACONVHI: TFloatField;
    TRANZTABLATRANSFEE: TFloatField;
    TRANZTABLAUGYFEL: TIntegerField;
    TRANZTABLAHIBASE: TFloatField;
    HIBASEPANEL: TPanel;
    Panel3: TPanel;
    Panel1: TPanel;
    LOBASEPANEL: TPanel;
    Panel4: TPanel;
    VUGYFELPANEL: TPanel;
    Panel6: TPanel;
    EUGYFELPANEL: TPanel;
    VLOBASEPANEL: TPanel;
    VHIBASEPANEL: TPanel;
    EHIBASEPANEL: TPanel;
    ELOBASEPANEL: TPanel;
    Panel10: TPanel;
    Panel12: TPanel;

    procedure FormActivate(Sender: TObject);

    procedure Vetelforgalom;
    procedure Tomburites;

    procedure HAVIBEDOLGGOMBClick(Sender: TObject);
    procedure tranzParancs(_ukaz: string);
    procedure StartTranzAkciok;
    procedure HavitranzTablaControl;
    procedure ElszamTablaControl;
    procedure Menube(_aa: byte);
    function Realtostr(_rr: real): string;

    function EgyPenztarBedolgozasa: boolean;
    function Adatbedolgozas: boolean;
    function ForgalomGyujtes: boolean;
    function KonverzioForgalom: boolean;
    function EladasForgalom: boolean;
    function Getelszarfarfolyam(_dd: word; _dn: string): integer;
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure SETMNBGOMBClick(Sender: TObject);
    procedure EgypenztarFelirasa;
    procedure DisplayRutin;

    function FtForm(_ft: integer):string;

    procedure DATUMOKEGOMBClick(Sender: TObject);
    procedure DATUMMEGSEMGOMBClick(Sender: TObject);
    procedure NAPIBEDOLGGOMBClick(Sender: TObject);
    function EzErtektar(_pt: integer): boolean;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure NaptarDatumDisplay;
    procedure NAPTARChange(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure EGYNAPADATAIGOMBClick(Sender: TObject);
    procedure DISPVISSZAGOMBClick(Sender: TObject);
    procedure DMEGSEMGOMBClick(Sender: TObject);
    procedure MnbtablazatControl;
    function Nulele(_in: integer):string;
    procedure KonstansTolto;
    procedure EGYHOADATAIGOMBClick(Sender: TObject);
    procedure BESTGOMBClick(Sender: TObject);
    procedure ALLGOMBClick(Sender: TObject);
    procedure EASTGOMBClick(Sender: TObject);
    procedure PANNONGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TRANZDIJ: TTRANZDIJ;

  // ---------------------------------------------------------------------------

  _ap,_bp,_cp,_dp,_ep,_fp,_gp,_hp,_ip,_jp,_kp,_lp,_mp,_np: array[1..31] of TPanel;

  _op: array[0..13] of tPanel;
  _im: array[1..13] of TImage;
  _Tp: array[1..13] of TPanel;
  _vp: array[1..13] of TPanel;

  _betusor: array[1..150] of string;
  _etarsor: array[1..150] of integer;

  // ---------------------------------------------------------------------------


   _etarszam: array[1..8] of integer = (10,20,40,50,63,75,120,145);

   _dnem: array[1..26] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                          'CZK','DKK','EUR','GBP','HRK','ILS','JPY','MXN','NOK',
                          'NZD','PLN','RON','RSD','RUB','SEK','THB','TRY','UAH',
                          'USD');

   _honev: array[1..12] of string = ('január','február','március','április','május',
                          'június','július','augusztus','szeptember','október',
                          'november','december');

   _elszdat: array[1..26] of integer;
   _buylow,_selllow,_convlow: array[1..31] of real;
   _sellhp,_buyhp,_convhp,_ugyfel,_vugyfel,_eugyfel: array[1..31] of integer;
   _hibase,_lobase,_vhibase,_vlobase,_ehibase,_elobase: array[1..31] of real;

   _kertev,_kerthonap,_aktev,_aktho,_kertnap:word;
   _height,_width,_mTop,_mLeft,_top,_left: word;

   _dataTomb: array[1..26,1..31] of integer;
   _farok,_pcs,_havitranztablanev,_havielszamtablanev,_kertdatums,_cBetu: string;
   _focim,_condi: string;
   _fdbPath,_bftablanev,_bttablanev,_tipus,_datum,_bizonylat: string;
   _sorveg: string = chr(13)+chr(10);
   _qq,_aktnap,_napkesz,_fek: byte;
   _akttranz,_oszforg,_bankjegy,_arfolyam: real;
   _cc,_recdb,_osszesen,_fizeszkoz: integer;
   _tOke,_ezNapi,_ezdisplay,_fenn,_ezhavi: boolean;
   _kertDatum: TDateTime;
   _sbuy,_sbuyhi,_ssell,_ssellhi,_sconv,_sconvhi,_ssfee: real;
   _sbuyhp,_ssellhip,_sconvhp,_teteldb: integer;
   _bl,_bh,_sl,_sh,_cl,_ch,_tf: real;
   _bhp,_shp,_chp,_ftop: integer;
   _bandisp : boolean;


function tranzakciojelentes: integer; stdcall;

implementation

uses Unit3, Unit4;

{$R *.dfm}


function tranzakciojelentes: integer; stdcall;

begin
   Tranzdij := TTranzdij.create(Nil);
   result := Tranzdij.ShowModal;
   Tranzdij.Free;
end;




// =============================================================================
              procedure TTRANZDIJ.FormActivate(Sender: TObject);
// =============================================================================

begin
  CegvaltoPanel.Visible := False;
  Menupanel.Visible   := False;
  Naptarpanel.Visible := False;
  MemoPanel.Visible   := False;
  CsikPanel.Visible   := False;
  Displaypanel.Visible:= False;
  DisplayMenuPanel.Visible := false;
  FocimPanel.Visible := false;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Height := 768;
  width  := 1024;

  _aktev := yearof(date);
  _aktho := monthof(date);

  KonstansTolto;
  _bandisp := False;
  Menube(1);
end;

// =============================================================================
                         procedure TTranzdij.Menube(_aa:byte);
// =============================================================================

begin
   Csikpanel.Visible := false;
   Naptarpanel.Visible := false;
   _ezdisplay := false;
   _ezHavi := false;
   with MenuPanel do
    begin
      top  := _Top+120;
      Left := _Left+160;
      Visible := true;
    end;
  if _aa=1 then Activecontrol := Havibedolggomb;
  if _aa=3 then Activecontrol := setMnbGomb;
end;



// =============================================================================
           procedure TTRANZDIJ.DATUMOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  NaptarPanel.Visible := False;
  _kertdatum := Naptar.CalendarDate;
  _kertdatums := leftstr(datetostr(_kertdatum),10);
  _kertev := yearof(_kertdatum);
  _kerthonap := monthof(_kertdatum);
  _kertnap := dayof(_kertdatum);
  _eznapi := true;

   if _ezdisplay then
    begin
      _farok := inttostr(_kertev-2000)+nulele(_kertHonap);
      _havitranztablanev  := 'TRANZDIJ'+_farok;
      _focim := _kertdatums+'-i tranzakciós illeték az összes pénztárnál';
      _condi := 'NAP='+inttostr(_kertnap);
      Cegvaltopanel.Visible := False;
      displayRutin;
      exit;
    end;
  StartTranzakciok;
end;

// =============================================================================
          procedure TTRANZDIJ.HAVIBEDOLGGOMBClick(Sender: TObject);
// =============================================================================

var _vanho: integer;

begin
  menupanel.Visible := false;
  _ezhavi := true;
  _bandisp := False;

  Hovalasztoform := THovalasztoform.Create(Nil);

  _vanHo := Hovalasztoform.ShowModal;
  HovalasztoForm.free;

  if _vanHo<>1 then
    begin
      Menube(1);
      exit;
    end;
  _eznapi := false;
  StartTranzakciok;

end;

// =============================================================================
                   procedure TTranzDij.StartTranzAkciok;
// =============================================================================

var _doke: boolean;


begin
  memoPanel.Visible := false;
  if not _bandisp then
    begin
      Memotabla.Clear;
      Memotabla.Lines.Clear;
      with Memopanel do
        begin
          top     := 80;
          Left    := 270;
          Visible := true;
          Repaint;
        end;
    end;
  _farok := inttostr(_kertev-2000)+nulele(_kertHonap);
  _havitranztablanev  := 'TRANZDIJ'+_farok;
  _havielszamTablanev := 'ELSZAM'+_farok;

  _bftablanev := 'BF' + _farok;
  _bttablanev := 'BT' + _farok;

  HaviTranzTablaControl;
  ElszamTablaControl;

  Tomburites;
  if _ezhavi then
    begin
      _pcs := 'DELETE FROM '+_haviTranzTablaNev;
      TranzParancs(_pcs);
    end;

  _dOke := adatbedolgozas;
  MemoPanel.Visible := false;
  if _doke then menube(1) else menube(3);

end;


// =============================================================================
                        procedure TTranzdij.Tomburites;
// =============================================================================


var i: integer;

begin
  for i := 1 to 31 do
    begin
      _buyhp[i]   := 0;
      _buylow[i]  := 0;
      _sellhp[i]  := 0;
      _selllow[i] := 0;
      _convhp[i]  := 0;
      _convlow[i] := 0;
      _ugyfel[i]  := 0;
      _vugyfel[i] := 0;
      _eugyfel[i] := 0;
      _hibase[i]  := 0;
      _vHibase[i] := 0;
      _eHibase[i] := 0;
      _lobase[i]  := 0;
      _vLobase[i] := 0;
      _eLobase[i] := 0;
    end;
end;


// =============================================================================
                 function TTranzdij.Adatbedolgozas: boolean;
// =============================================================================

begin

  with CsikPanel do
    begin
      top := 610;
      Left := 60;
      Visible := True;
      Repaint;
    end;

  result   := True;
  csik.Max := 150;
  _qq      := 1;

  while _qq<=150 do
    begin
      Tomburites;
      Csik.Position := _qq;

      Application.ProcessMessages;
      
      CsikPanel.repaint;

      if ezertektar(_qq) then
        begin
          inc(_qq);
          continue;
        end;

      if not _bandisp then
           MemoTabla.Lines.add('Keresem a '+inttostr(_qq)+'. számú pénztárt');

      _fdbpath := 'c:\receptor\database\v' + inttostr(_qq)+'.fdb';
      if not fileExists(_fdbPath) then
        begin
          if not _bandisp then
                MemoTabla.Lines.Add('Nincs ilyen számú pénztár');
          inc(_qq);
          continue;
        end;

      //-------- egy pénztár bedolgozása ---------------------------------------

      if not EgyPenztarBedolgozasa then exit;

    // itt egy hónap (vagy nap) felirható egy pénztárnak

       EgyPenztarfelirasa;
       if not _bandisp then
           MemoTabla.Lines.add('---------------------------------------------------------');
       inc(_qq);
    end;
end;

// =============================================================================
                 procedure TTranzdij.EgypenztarFelirasa;
// =============================================================================

var _buy,_buyhi,_sell,_sellhi,_conv,_convhi,_transfee: real;
    _transfeebuy,_transfeesell,_transfeeconv: real;
    _nn,_aktertektar,_napiugyfel,_napivugyfel,_napieugyfel: integer;
    _napihibase,_napilobase,_napivhibase,_napiehibase: real;
    _napivlobase,_napielobase: real;
    _aktcegbetu: string;

begin
  _aktCegbetu  := _betusor[_qq];
  _aktertektar := _etarsor[_qq];

  if _eznapi then
    begin
       if not _bandisp then
         MemoTabla.Lines.Add(inttostr(_qq)+'. számu pénztár '+_kertdatums+'-i napi adatai');

      _pcs := 'DELETE FROM ' + _haviTranzTablaNev + _sorveg;
      _pcs := _pcs + 'WHERE (NAP=' + inttostr(_aktnap)+')';
      _pcs := _pcs + ' AND (CASHIER='+inttostr(_qq)+')';

      TranzParancs(_pcs);

      _napiugyfel  := _ugyfel[_aktnap];
      _napiVugyfel := _vugyfel[_aktnap];
      _napiEugyfel := _eugyfel[_aktnap];
      _napihibase  := _hibase[_aktnap];
      _napivhibase := _vhibase[_aktnap];
      _napiehibase := _eHibase[_aktnap];
      _napilobase  := _lobase[_aktnap];
      _napivlobase := _vlobase[_aktnap];
      _napielobase := _elobase[_aktnap];

      if _napiUgyfel=0 then exit;

      _pcs := 'INSERT INTO ' + _haviTranzTablaNev + ' (CASHIER,FIRMLETTER,DISTRICT,';
      _pcs := _pcs + 'NAP,NAPKESZ,BUYLOW,BUYHIPIECE,';
      _pcs := _pcs + 'BUYHI,SELLLOW,SELLHIPIECE,SELLHI,CONVLOW,CONVHIPIECE,';
      _pcs := _pcs + 'CONVHI,TRANSFEE,UGYFEL,VUGYFEL,EUGYFEL,';
      _pcs := _pcs + 'LOBASE,VLOBASE,ELOBASE,HIBASE,VHIBASE,EHIBASE)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_qq) + ',';
      _Pcs := _pcs + chr(39)+_aktcegbetu + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktertektar)+',';
      _pcs := _pcs + inttostr(_aktnap)+',1,';

      _buy := _buylow[_aktnap];
      _pcs := _pcs + realtostr(_buy) + ',';
      _pcs := _pcs + inttostr(_buyhp[_aktnap]) + ',';
      _buyhi  := trunc(6000*_buyhp[_aktnap]);
      _pcs := _pcs + realtostr(_buyhi) + ',';

      _sell := _selllow[_aktnap];
      _pcs := _pcs + realtostr(_sell) + ',';
      _pcs := _pcs + inttostr(_sellhp[_aktnap])+',';
      _sellhi := trunc(6000*_sellhp[_aktnap]);
      _pcs := _pcs + realtostr(_sellhi) + ',';

      _conv := _convlow[_aktnap];
      _pcs := _pcs + realtostr(_conv)+',';
      _pcs := _pcs + inttostr(_convhp[_aktnap])+',';
      _convhi := trunc(6000*_convhp[_aktnap]);
      _pcs := _pcs + realtostr(_convhi)+',';

      _transfee := _buy+_buyhi+_sell+_sellhi+_conv+_convhi;
      _pcs := _pcs + realtostr(_transfee)+',';

      _pcs := _pcs + inttostr(_napiugyfel)+',';
      _pcs := _pcs + inttostr(_napiVugyfel)+',';
      _pcs := _pcs + inttostr(_napiEugyfel)+',';
      _pcs := _pcs + realtostr(_napiLObase)+',';
      _PCS := _pcs + realtostr(_napivlobase)+',';
      _pcs := _pcs + realtostr(_napielobase)+',';

      _pcs := _pcs + realtostr(_napihibase)+',';
      _PCS := _pcs + realtostr(_napivhibase)+',';
      _pcs := _pcs + realtostr(_napiehibase)+')';


      TranzParancs(_pcs);
      exit;
    end;

  _pcs := 'DELETE FROM '+ _havitranztablanev + _sorveg;
  _pcs := _pcs + 'WHERE CASHIER=' + inttostr(_qq);
  Tranzparancs(_pcs);

  _nn := 1;
  while _nn<=31 do
    begin
      _napiugyfel  := _ugyfel[_nn];
      _napivugyfel := _vugyfel[_nn];
      _napieugyfel := _eugyfel[_nn];
      _napihibase  := _hibase[_nn];
      _napivhibase := _vhibase[_nn];
      _napiehibase := _ehibase[_nn];
      _napilobase  := _loBase[_nn];
      _napivlobase := _vlobase[_nn];
      _napielobase := _elobase[_nn];
      if _napiugyfel>0 then
        begin
          if not _bandisp then
             Memotabla.Lines.add(inttostr(_qq)+'. pénztár ' + _honev[_kerthonap]+' '+ inttostr(_nn)+'-i adatai felirása');
          _pcs := 'INSERT INTO ' + _haviTranzTablaNev + ' (CASHIER,FIRMLETTER,DISTRICT,';
          _pcs := _pcs + 'NAP,NAPKESZ,BUYLOW,BUYHIPIECE,';
          _pcs := _pcs + 'BUYHI,SELLLOW,SELLHIPIECE,SELLHI,CONVLOW,CONVHIPIECE,';
          _pcs := _pcs + 'CONVHI,TRANSFEE,TRANSFEEBUY,TRANSFEESELL,TRANSFEECONV,';
          _pcs := _pcs + 'UGYFEL,VUGYFEL,EUGYFEL,';
          _pcs := _pcs + 'LOBASE,VLOBASE,ELOBASE,HIBASE,VHIBASE,EHIBASE)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_qq) + ',';
          _Pcs := _pcs + chr(39)+_aktcegbetu + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktertektar)+',';

          _pcs := _pcs + inttostr(_nn)+',1,';

          _buy := _buylow[_nn];
          _pcs := _pcs + realtostr(_buy) + ',';
          _pcs := _pcs + inttostr(_buyhp[_nn]) + ',';
          _buyhi  := trunc(6000*_buyhp[_nn]);
          _pcs := _pcs + realtostr(_buyhi) + ',';

          _sell := _selllow[_nn];
          _pcs := _pcs + realtostr(_sell) + ',';
          _pcs := _pcs + inttostr(_sellhp[_nn])+',';
          _sellhi := trunc(6000*_sellhp[_nn]);
          _pcs := _pcs + realtostr(_sellhi) + ',';

          _conv := _convlow[_nn];
          _pcs := _pcs + realtostr(_conv)+',';
          _pcs := _pcs + inttostr(_convhp[_nn])+',';
          _convhi := trunc(6000*_convhp[_nn]);
          _pcs := _pcs + realtostr(_convhi)+',';

          _transfeesell := _sell + _sellhi;
          _transfeebuy  := _buy + _buyhi;
          _transfeeconv := _conv + _convhi;
          _transfee := _transfeebuy + _transfeesell + _transfeeconv;

          _pcs := _pcs + realtostr(_transfee)+',';
          _pcs := _pcs + realtostr(_transfeebuy)+',';
          _pcs := _pcs + realtostr(_transfeesell)+',';
          _pcs := _pcs + realtostr(_transfeeconv)+',';

          _pcs := _pcs + inttostr(_napiugyfel)+',';
          _pcs := _pcs + inttostr(_napiVugyfel)+',';
          _pcs := _pcs + inttostr(_napiEugyfel)+',';
          _pcs := _pcs + realtostr(_napiLObase)+',';
          _pcs := _pcs + realtostr(_napivlobase)+',';
          _pcs := _pcs + realtostr(_napielobase)+',';

          _pcs := _pcs + realtostr(_napihibase)+',';
          _pcs := _pcs + realtostr(_napivhibase)+',';
          _pcs := _pcs + realtostr(_napiehibase)+')';

          TranzParancs(_pcs);
        end;
      inc(_nn);
    end;
end;


// =============================================================================
               function Ttranzdij.Realtostr(_rr: real): string;
// =============================================================================

var _pos: integer;
begin
  result := floattostr(_rr);
  _pos := pos(',',result);
  if _pos>0 then result := stuffstring(result,_pos,1,'.');
end;




// =============================================================================
                 function TTranzdij.ForgalomGyujtes: boolean;
// =============================================================================

begin
  result := True;

  _aktnap := strtoint(midstr(_datum,9,2));
  if (_tipus='V') OR (_tipus='E') or (_tipus='K') then
    BEGIN
      _ugyfel[_aktnap] := _ugyfel[_aktnap] + 1;
      if _tipus='E' then _eugyfel[_aktnap] := _eugyfel[_aktnap] + 1
      else _vugyfel[_aktnap] :=  _vugyfel[_aktnap] + 1;
    end;


  if not _bandisp then Memotabla.Lines.add('Dátum: '+ _datum);


  if _tipus='V' then Vetelforgalom;

  if _tipus='E' then
    begin
      _tOke := EladasForgalom;
      if not _toke then
        begin
          result := False;
          exit;
        end;
    end;

  if _tipus='K' then
    begin
      _toke := KonverzioForgalom;
      if not _toke then
        begin
          result := False;
          exit;
        end;
    end;
end;


// =============================================================================
                  procedure TTranzdij.Vetelforgalom;
// =============================================================================

var _akttranz: real;

begin
  if _oszForg>=3000000 then
    begin
      _hibase[_aktnap] := _hibase[_aktnap] + _oszForg;
      _vhibase[_aktnap]:= _vhibase[_aktnap] + _oszforg;
      _buyhp[_aktnap] := _buyhp[_aktnap] + 1;
      exit;
    end else
    begin
      _lobase[_aktnap] := _lobase[_aktnap] + _oszforg;
      _vlobase[_aktnap]:= _vlobase[_aktnap] + _oszforg;
    end;
 // _akttranz := _oszforg/500;
  _aktTranz := _oszforg*0.003;
  _buylow[_aktnap] := _buylow[_aktnap] + _akttranz;
end;


// =============================================================================
                function TTranzdij.EladasForgalom: boolean;
// =============================================================================

var _sumtranz: real;
    _biz,_tip: string;

begin
  result := true;
  if _fek=2 then exit;
  
  _sumTranz := 0;
  _pcs := 'SELECT * FROM ' + _bttablanev + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM='+chr(39)+_bizonylat+chr(39)+')';

  BtDbase.close;
  Btdbase.DatabaseName := _fdbPath;

  Btdbase.connected := true;
  with BtQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not Btquery.eof do
    begin
      _biz  := BtQuery.FieldbyName('BIZONYLATSZAM').asstring;
      _tip := leftstr(_biz,1);
      _aktdnem := Btquery.fieldByName('VALUTANEM').asstring;
      if (_tip='E') AND (_aktdnem='HUF') then
        begin
          Btquery.next;
          Continue;
        end;

      _bankjegy := Btquery.FieldByName('BANKJEGY').asInteger;
      _arfolyam := getelszarfarfolyam(_aktnap,_aktdnem);
      if _arfolyam=0 then
        begin
          Btquery.close;
          Btdbase.close;
          result := false;
          exit;
        end;
      _akttranz := _bankjegy*_arfolyam/100;
      if _aktdnem='JPY' then _akttranz := trunc(_akttranz/100);
      _sumtranz := _sumtranz + _akttranz;
      btquery.next;
    end;
  Btquery.close;
  Btdbase.close;

  if _sumtranz>3000000 then
    begin
      _hibase[_aktnap] := _hibase[_aktnap] + _sumtranz;
      _ehibase[_aktnap]:= _ehibase[_aktnap]+ _sumtranz;
      _sellhp[_aktnap] := _sellhp[_aktnap] + 1;
    end else
    begin
    //  _selllow[_aktnap] := _selllow[_aktnap] + trunc(_sumtranz/500);
      _selllow[_aktnap] := _selllow[_aktnap] + trunc(_sumtranz*0.003);
      _lobase[_aktnap] := _lobase[_aktnap] + _sumtranz;
      _elobase[_aktnap]:= _elobase[_aktnap] + _sumtranz;
    end;
end;

// =============================================================================
               function TTranzdij.KonverzioForgalom: boolean;
// =============================================================================

var _sumtranz : real;

begin
  result := true;
  _sumtranz := 0;
  _pcs := 'SELECT * FROM ' +_btTablanev + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM='+chr(39)+_bizonylat+chr(39)+')';
  _pcs := _pcs + ' AND (ELOJEL='+chr(39)+'+'+chr(39)+')';

  with BTdbase do
    begin
      close;
      databasename := _fdbPath;
      connected := true;
    end;

  with BtQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not BtQuery.eof do
    begin
      _aktdnem := Btquery.fieldByName('VALUTANEM').asstring;
      _bankjegy := Btquery.FieldByName('BANKJEGY').asInteger;
      _arfolyam := getelszarfarfolyam(_aktnap,_aktdnem);
      if _arfolyam=0 then
        begin
          Btquery.close;
          Btdbase.close;
          result := false;
          exit;
        end;
      _akttranz := trunc(_arfolyam*_bankjegy/100);
      if _aktdnem='JPY' then _akttranz := trunc(_akttranz/10);
      _sumtranz := _sumtranz + _akttranz;
      btquery.next;
    end;
  Btquery.close;
  Btdbase.close;
   if _sumtranz>3000000 then
    begin
      _hibase[_aktnap] := _hibase[_aktnap] + _sumtranz;
      _vhibase[_aktnap]:= _vhibase[_aktnap] + _sumtranz;
      _convhp[_aktnap] := _convhp[_aktnap] + 1;
    end else
    begin
    //  _convlow[_aktnap] := _convlow[_aktnap] + trunc(_sumtranz/500);
      _convlow[_aktnap] := _convlow[_aktnap] + trunc(_sumtranz*0.003);
      _lobase[_aktnap] := _lobase[_aktnap] + _sumtranz;
      _vlobase[_aktnap] := _vlobase[_aktnap] + _sumtranz;
    end;
end;


// =============================================================================
      function TTranzdij.Getelszarfarfolyam(_dd: word; _dn: string): integer;
// =============================================================================

var _uzenet: string;

begin
  _pcs := 'SELECT * FROM '+ _haviElszamTablanev + _sorveg;
  _pcs := _pcs + 'WHERE NAP=' + inttostr(_dd);

  ElszamDbase.Connected := true;
  with ElszamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      result := FieldByName(_dn).asInteger;
      Close;
    end;
  ElszamDbase.close;

  if result=0 then
    begin
      _uzenet := _honev[_kerthonap]+' '+inttostr(_dd);
      _uzenet := 'Hiányzik a(z) '+ _uzenet +'-i '+_dn+' elszámolási árfolyam !';
      Showmessage(_uzenet);
    end;
end;

// =============================================================================
                    procedure TTranzdij.HaviTranzTablaControl;
// =============================================================================

begin
  TranzTabla.close;
  TranzTabla.tablename := _havitranztablanev;

  Tranzdbase.connected := true;
  if not Tranztabla.exists then
    begin
      Tranzdbase.close;

      _pcs := 'CREATE TABLE ' +_havitranztablaNev+ ' (' + _sorveg;
      _pcs := _pcs + 'CASHIER SMALLINT,' + _sorveg;
      _pcs := _pcs + 'DISTRICT SMALLINT,' + _sorveg;
      _pcs := _pcs + 'FIRMLETTER CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
      _pcs := _pcs + 'NAP SMALLINT,' + _sorveg;
      _pcs := _pcs + 'NAPKESZ SMALLINT,' + _sorveg;
      _pcs := _pcs + 'BUYLOW DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'BUYHIPIECE INTEGER,' + _sorveg;
      _pcs := _pcs + 'BUYHI DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'SELLLOW DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'SELLHIPIECE INTEGER,' + _sorveg;
      _pcs := _pcs + 'SELLHI DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'CONVLOW DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'CONVHIPIECE INTEGER,' + _sorveg;
      _pcs := _pcs + 'CONVHI DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'TRANSFEEBUY DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'TRANSFEESELL DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'TRANSFEECONV DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'TRANSFEE DOUBLE PRECISION,'+_sorveg;
      _pcs := _pcs + 'UGYFEL INTEGER,'+_sorveg;
      _pcs := _pcs + 'VUGYFEL INTEGER,'+_sorveg;
      _pcs := _pcs + 'EUGYFEL INTEGER,'+_sorveg;

      _pcs := _pcs + 'LOBASE DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'VLOBASE DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'ELOBASE DOUBLE PRECISION,' + _sorveg;

      _pcs := _pcs + 'HIBASE DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'EHIBASE DOUBLE PRECISION,' + _sorveg;
      _pcs := _pcs + 'VHIBASE DOUBLE PRECISION)';

      Tranzparancs(_pcs);

      _pcs := 'CREATE INDEX IDX_'+ _havitranztablanev + _sorveg;
      _pcs := _pcs + 'ON '+_havitranztablanev+' (CASHIER,NAP)';
      Tranzparancs(_pcs);
    end;
  if Tranzdbase.connected then Tranzdbase.close;
end;


  // ---------------------------------------------------------------------------


procedure TTranzdij.ElszamTablaControl;

var i: integer;

begin
  TranzTabla.close;
  Tranzdbase.connected := true;
  Tranztabla.tablename := _haviElszamTablanev;
  if not Tranztabla.exists then
    begin
      Tranzdbase.close;

      _pcs := 'CREATE TABLE ' + _haviElszamTablanev + ' ('+_sorveg;
      _pcs := _pcs + 'AUD INTEGER,'+_sorveg;
      _pcs := _pcs + 'BAM INTEGER,'+_sorveg;
      _pcs := _pcs + 'BGN INTEGER,'+_sorveg;
      _pcs := _pcs + 'BRL INTEGER,'+_sorveg;
      _pcs := _pcs + 'CAD INTEGER,'+_sorveg;
      _pcs := _pcs + 'CHF INTEGER,'+_sorveg;
      _pcs := _pcs + 'CNY INTEGER,'+_sorveg;
      _pcs := _pcs + 'CZK INTEGER,'+_sorveg;
      _pcs := _pcs + 'DKK INTEGER,'+_sorveg;
      _pcs := _pcs + 'EUR INTEGER,'+_sorveg;
      _pcs := _pcs + 'GBP INTEGER,'+_sorveg;
      _pcs := _pcs + 'HRK INTEGER,'+_sorveg;
      _pcs := _pcs + 'ILS INTEGER,'+_sorveg;
      _pcs := _pcs + 'JPY INTEGER,'+_sorveg;
      _pcs := _pcs + 'MXN INTEGER,'+_sorveg;
      _pcs := _pcs + 'NOK INTEGER,'+_sorveg;
      _pcs := _pcs + 'NZD INTEGER,'+_sorveg;
      _pcs := _pcs + 'PLN INTEGER,'+_sorveg;
      _pcs := _pcs + 'RON INTEGER,'+_sorveg;
      _pcs := _pcs + 'RSD INTEGER,'+_sorveg;
      _pcs := _pcs + 'RUB INTEGER,'+_sorveg;
      _pcs := _pcs + 'SEK INTEGER,'+_sorveg;
      _pcs := _pcs + 'THB INTEGER,'+_sorveg;
      _pcs := _pcs + 'TRY INTEGER,'+_sorveg;
      _pcs := _pcs + 'UAH INTEGER,'+_sorveg;
      _pcs := _pcs + 'USD INTEGER,'+_sorveg;
      _pcs := _pcs + 'NAPKESZ SMALLINT,' + _sorveg;
      _pcs := _pcs + 'NAP SMALLINT)';

      TranzParancs(_pcs);

      _pcs := 'CREATE INDEX IDX_' + _haviElszamTablaNev + _sorveg;
      _pcs := _pcs + 'ON '+_haviElszamTablanev + ' (NAP)';
      TranzParancs(_pcs);

      for i := 1 to 31 do
        begin
          _pcs := 'INSERT INTO '+_haviElszamTablanev+ ' (NAP,NAPKESZ,AUD,BAM,BGN,';
          _pcs := _pcs + 'BRL,CAD,CHF,CNY,CZK,DKK,EUR,GBP,HRK,ILS,JPY,MXN,NOK,';
          _pcs := _pcs + 'NZD,PLN,RON,RSD,RUB,SEK,THB,TRY,UAH,USD)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(i)+',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,';
          _pcs := _pcs + '0,0,0,0,0,0,0,0,0,0,0,0)';
          TranzParancs(_pcs);
        end;
    end;
  if Tranzdbase.connected then Tranzdbase.close;
end;

// =============================================================================
             procedure TTranzdij.tranzParancs(_ukaz: string);
// =============================================================================

begin
  Tranzdbase.connected := true;
  if tranztranz.InTransaction then tranztranz.Commit;
  tranztranz.StartTransaction;
  with tranzQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  TranzTranz.Commit;
  Tranzdbase.close;
end;


// =============================================================================
             procedure TTRANZDIJ.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
             procedure TTRANZDIJ.SETMNBGOMBClick(Sender: TObject);
// =============================================================================

var _hooke: integer;

begin
  MenuPanel.Visible := false;
  HovalasztoForm := THovalasztoForm.Create(NIl);
  _hoOke := HoValasztoForm.Showmodal;
  HovalasztoForm.free;

  MnbtablazatControl;

  if _hooKe =1 then
    begin
      mnbarfolyam := TMnbArfolyam.Create(Nil);
      MNBArfolyam.Showmodal;
      Mnbarfolyam.free;
    end;
  Menube(1);
end;

// =============================================================================
           procedure TTRANZDIJ.DATUMMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  naptarPanel.Visible := false;
  Menube(1);
end;

// =============================================================================
            procedure TTRANZDIJ.NAPIBEDOLGGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ezhavi := false;
  MenuPanel.Visible := false;
  Naptar.CalendarDate := Date;
  with Naptarpanel do
    begin
      Top     := _top + 80;
      Left    := _left + 180;
      Visible := true;
    end;
  Activecontrol := DatumokeGomb;
end;


// =============================================================================
            function TTranzdij.EzErtektar(_pt: integer): boolean;
// =============================================================================

var _y:byte;

begin
  result := False;
  _y := 1;
  while _y<=8 do
    begin
      if _etarszam[_y]=_pt then
        begin
          result := true;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
             procedure TTRANZDIJ.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
end;

// =============================================================================
             procedure TTRANZDIJ.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
end;

// =============================================================================
                   procedure TTranzdij.NaptardatumDisplay;
// =============================================================================

var _kds: string;

begin
  _kertdatum := Naptar.CalendarDate;
  _kertdatums := leftstr(datetostr(_kertdatum),10);
  _kertev := yearof(_kertdatum);
  _kerthonap := monthof(_kertdatum);
  _kertnap := dayof(_kertdatum);
  _kds := inttostr(_kertev)+' '+_honev[_kerthonap]+' '+inttostr(_kertnap);
  NaptarDatumPanel.caption := _kds;
end;


// =============================================================================
               procedure TTRANZDIJ.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  Naptardatumdisplay;
end;


// =============================================================================
             function TTranzdij.EgypenztarBedolgozasa: boolean;
// =============================================================================


begin
  result := true;
  if not _bandisp then Memotabla.Lines.Add('Az adatbázis címe: '+_fdbpath);

  with BFDbase do
    begin
      close;
      databasename := _fdbPath;
      connected := true;
    end;

  bFtabla.close;
  bFtabla.tablename := _bftablanev;
  if not Bftabla.Exists then
    begin
      Bfdbase.close;
      if not _bandisp then MemoTabla.Lines.add('NEM VOLT '+ _honev[_kerthonap]+'BAN/BEN FORGALMA');
      exit;
    end;

  Bfdbase.close;

  _pcs := 'SELECT * FROM '+ _bftablanev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1)';

  if _eznapi then _pcs := _pcs + ' AND (DATUM=' +CHR(39)+_kertdatums+chr(39)+')';
  _pcs := _pcs + _sorveg + 'ORDER BY DATUM';

  BfDbase.connected := true;
  with Bfquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recdb := recno;
      First;
    end;

  Csik2.max := _recdb;
  if not _bandisp then Memotabla.Lines.add(inttostr(_recdb)+' darab rekordot találtam');

  _cc := 0;
  while not Bfquery.eof do
    begin
      inc(_cc);
      Csik2.Position := _cc;

      _datum     := Bfquery.FieldByName('DATUM').asString;
      _tipus     := BfQuery.FieldByNAme('TIPUS').asString;
      _osszesen  := BfQuery.FieldByName('OSSZESEN').asInteger;
      _bizonylat := BfQuery.FieldByName('BIZONYLATSZAM').asString;
      _fizeszkoz := BFQuery.Fieldbyname('FIZETOESZKOZ').asInteger;

      if _fizeszkoz=2 then _fek := 2 else _fek := 1;

      if not _bandisp then Memotabla.Lines.Add('Bizonylatszám: '+ _bizonylat);
      _oszforg := 1*_osszesen;
      if not Forgalomgyujtes then
        begin
          Bfquery.close;
          Bfdbase.close;
          result := false;
          exit;
        end;

      BfQuery.next;
    end;
  BfQuery.close;
  BfDbase.close;
end;

// =============================================================================
              procedure TTRANZDIJ.BitBtn3Click(Sender: TObject);
// =============================================================================

begin

  MenuPanel.Visible := False;
  _ezdisplay := True;
  with DisplayMenuPanel do
    begin
      top := 230;
      left := 280;
      Visible := true;
    end;

end;

// =============================================================================
         procedure TTRANZDIJ.EGYNAPADATAIGOMBClick(Sender: TObject);
// =============================================================================

begin
  DisplayMenupanel.Visible := false;
  _eznapi := true;
  _ezhavi := False;
  NapiBedolgGombClick(Nil);
end;


// =============================================================================
           procedure TTRANZDIJ.DISPVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Tranztabla.Close;
  Tranzdbase.close;
  Focimpanel.visible := false;
  DisplayPanel.Visible := False;
  Menube(1);
end;

// =============================================================================
              function TTranzDij.FtForm(_ft: integer):string;
// =============================================================================

var _ww,_p1: integer;

begin
  result := inttostr(_ft);
  if _ft<1000 then exit;
  _ww := length(result);
  if _ww<7 then
    begin
      _p1 := _ww - 3;
      result := leftstr(result,_p1)+' '+midstr(result,_p1+1,3);
      exit;
    end;
  _p1 := _ww-6;
  result := leftstr(result,_p1)+' '+midstr(result,_p1+1,3)+' '+midstr(result,_p1+3,3);
end;


// =============================================================================
          procedure TTRANZDIJ.DMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Displaymenupanel.Visible := false;
  Menube(1);
end;

// =============================================================================
                    procedure TTranzdij.MnbtablazatControl;
// =============================================================================

begin
  _farok := inttostr(_kertev-2000)+nulele(_kerthonap);
  _haviElszamTablanev := 'ELSZAM' + _farok;
  ElszamTablaControl;
end;

// =============================================================================
            function TTranzdij.Nulele(_in: integer):string;
// =============================================================================

begin
  result := inttostr(_in);
  if _in<10 then result := '0' + result;
end;

// =============================================================================
                      procedure TTranzdij.KonstansTolto;
// =============================================================================

var _uz,_et,I: integer;
    _cb: string;

begin
  for i := 1 to 150 do
    begin
      _betusor[i] := '';
      _etarsor[i] := 0;
    end;

  _pcs := 'SELECT * FROM IRODAK ORDER BY UZLET';
  receptdbase.Connected := true;
  with ReceptQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not Receptquery.Eof do
    begin
      _uz := Receptquery.fieldbyname('UZLET').asInteger;
      if _uz>150 then break;

      _cb := Receptquery.fieldbyname('CEGBETU').asString;
      _et := Receptquery.fieldbyname('ERTEKTAR').asInteger;
      _betusor[_uz] := _cb;
      _etarsor[_uz] := _et;
      ReceptQuery.next;
    end;

  Receptquery.close;
  ReceptDbase.close;
end;

// =============================================================================
           procedure TTRANZDIJ.EGYHOADATAIGOMBClick(Sender: TObject);
// =============================================================================

var _vanho: integer;

begin
  _ezdisplay := True;
  DisplayMenupanel.Visible := false;
  Hovalasztoform := THovalasztoform.Create(Nil);
  _vanHo := Hovalasztoform.ShowModal;
  HovalasztoForm.free;

  if _vanHo<>1 then
    begin
      Menube(1);
      exit;
    end;

  _farok := inttostr(_kertev-2000)+nulele(_kertHonap);
  _havitranztablanev  := 'TRANZDIJ'+_farok;
  _condi := '';
  _cBetu := 'A';
  _focim := inttostr(_kertev)+ ' '+_honev[_kerthonap] + ' havi illeték az összes pénztárnál';
  Cegvaltopanel.Visible := false;
  DisplayRutin;
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
                  procedure TTRANZDIJ.ALLGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _cBetu='A' then exit;
  _cbetu := 'A';

  CegvaltoPanel.visible := true;
  Cegvaltopanel.repaint;
  Sleep(40);

  if _eznapi then
    begin
      _focim := _kertdatums+'-i tranzakciós illeték az összes pénztárnál';
      _condi := 'NAP='+inttostr(_kertnap);
    end else
    begin
      _condi := '';
      _focim := inttostr(_kertev)+ ' '+_honev[_kerthonap] + ' havi illeték az összes pénztárnál';
    end;
  DisplayRutin;
end;


// =============================================================================
               procedure TTRANZDIJ.BESTGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _cBetu='B' then exit;
  _cBetu := 'B';

  CegvaltoPanel.visible := true;
  Cegvaltopanel.repaint;
  Sleep(40);

  if _eznapi then
    begin
      _focim := _kertdatums+'-i tranzakciós illeték a Best Change Kft-nél';
      _condi := '(NAP='+inttostr(_kertnap)+' AND (FIRMLETTER='+chr(39)+'B'+chr(39)+')';
    end else
    begin
      _condi := 'FIRMLETTER='+chr(39)+'B'+chr(39);
      _focim := inttostr(_kertev)+ ' '+_honev[_kerthonap] + ' havi illeték a Best Change Kft-nél';
    end;
  DisplayRutin;
end;

// =============================================================================
                procedure TTRANZDIJ.EASTGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _cBetu = 'E' then exit;
  _cbetu := 'E';

  CegvaltoPanel.visible := true;
  Cegvaltopanel.repaint;
  Sleep(40);

  if _eznapi then
    begin
      _focim := _kertdatums+'-i tranzakciós illeték az East Change Kft-nél';
      _condi := '(NAP='+inttostr(_kertnap)+' AND (FIRMLETTER='+chr(39)+'E'+chr(39)+')';
    end else
    begin
      _condi := 'FIRMLETTER='+chr(39)+'E'+chr(39);
      _focim := inttostr(_kertev)+ ' '+_honev[_kerthonap] + ' havi illeték az  East Change Kft-nél';
    end;
  DisplayRutin;
end;


// =============================================================================
              procedure TTRANZDIJ.PANNONGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _cBetu='P' then exit;
  _cbetu := 'P';

  CegvaltoPanel.visible := true;
  Cegvaltopanel.repaint;
  Sleep(40);

  if _eznapi then
    begin
      _focim := _kertdatums+'-i tranzakciós illeték a Pannon Change Kft-nél';
      _condi := '(NAP='+inttostr(_kertnap)+' AND (FIRMLETTER='+chr(39)+'P'+chr(39)+')';
    end else
    begin
      _condi := 'FIRMLETTER='+chr(39)+'P'+chr(39);
      _focim := inttostr(_kertev)+ ' '+_honev[_kerthonap] + ' havi illeték a Pannon Change Kft-nél';
    end;
  DisplayRutin;
end;

// =============================================================================
                       procedure TTranzdij.DisplayRutin;
// =============================================================================

var _ugyfelDarab,_aktugyfel,_vugyfeldarab,_eugyfeldarab: integer;
    _aktvugyfel,_akteugyfel: integer;
    _akthibase,_aktlobase,_osszhibase,_osszlobase: real;
    _aktvhibase,_aktehibase,_aktvlobase,_aktelobase: real;
    _osszvhibase,_osszehibase,_osszvlobase,_osszelobase: real;

begin
  Focimpanel.Caption := _FOCIM;
  Focimpanel.Visible := True;
  _sbuy    := 0;
  _sbuyhi  := 0;
  _ssell   := 0;
  _ssellhi := 0;
  _sconv   := 0;
  _sconvhi := 0;
  _sbuyhp  := 0;
  _ssellhip:= 0;
  _sconvhp := 0;
  _ssfee   := 0;
  _ugyfeldarab := 0;
  _vugyfeldarab := 0;
  _eugyfeldarab := 0;
  _osszLobase := 0;
  _osszvlobase := 0;
  _osszelobase := 0;
  _osszHiBase := 0;
  _osszvhibase:= 0;
  _osszehibase := 0;

  _pcs := 'SELECT * FROM ' + _havitranztablanev+_sorveg;
  if _condi<>'' then _pcs := _pcs + 'WHERE '+ _condi + _sorveg;
  _pcs := _pcs + 'ORDER BY CASHIER';

  Tranzdbase.close;

  TranzDbase.Connected := true;
  with Tranzquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _napkesz := FieldByName('NAPKESZ').asInteger;
    end;

  if _napkesz<>1 then
    begin
      TranzQuery.close;
      Tranzdbase.close;
      CegvaltoPanel.Visible := false;
      Focimpanel.Visible := false;

      if _eznapi then ShowMessage('A KÉRT NAP MÉG NINCS BEDOLGOZVA')
      else ShowMessage('A KÉRT HÓNAP MÉG NINCS BEDOLGOZVA');

      Menube(1);
      exit;
    end;

  while not Tranzquery.Eof do
    begin
      with TranzQuery do
        begin
          _bl := FieldByName('BUYLOW').asFloat;
          _bh := FieldByName('BUYHI').asFloat;
          _sl := FieldByName('SELLLOW').asFloat;
          _sh := FieldByName('SELLHI').asFloat;
          _cl := FieldByName('CONVLOW').asFloat;
          _ch := FieldByName('CONVHI').asFloat;
          _tf := FieldByName('TRANSFEE').asFloat;

          _bhp := FieldByNAme('BUYHIPIECE').asInteger;
          _shp := FieldByName('SELLHIPIECE').asInteger;
          _chp := FieldByName('CONVHIPIECE').asInteger;
          _aktugyfel:= FieldByName('UGYFEL').asInteger;
          _aktvugyfel := FieldByName('VUGYFEL').asInteger;
          _akteugyfel := FieldByName('EUGYFEL').asInteger;
          _aktlobase := FieldByName('LOBASE').asFloat;
          _aktvlobase := FieldByNAme('VLOBASE').asFloat;
          _akteLobase := FieldbyNAme('ELOBASE').asFloat;

          _akthibase := FieldByName('HIBASE').asFloat;
          _aktvhibase := FieldByNAme('VHIBASE').asFloat;
          _aktehibase := FieldbyNAme('EHIBASE').asFloat;

        end;

      _sbuy   := _sbuy + _bl;
      _sbuyhp := _sbuyhp + _bhp;
      _sbuyhi := _sbuyhi + _bh;

      _ssell  := _ssell + _sl;
      _ssellhip:= _ssellhip + _shp;
      _ssellhi:= _ssellhi + _sh;

      _sconv  := _sconv + _cl;
      _sconvhp:= _sconvhp + _chp;
      _sconvhi:= _sconvhi + _ch;

      _ssfee := _ssfee + _tf;
      _ugyfeldarab := _ugyfeldarab+_aktugyfel;
      _vugyfeldarab:= _vugyfeldarab + _aktvugyfel;
      _eugyfeldarab:= _eugyfeldarab + _akteugyfel;

      _osszlobase := _osszlobase + _aktlobase;
      _osszvlobase := _osszvlobase + _aktvlobase;
      _osszelobase := _osszelobase + _aktelobase;

      _osszHibase := _osszhibase + _akthibase;
      _osszvhibase := _osszvhibase + _aktvhibase;
      _osszeHibase := _osszeHibase + _aktehibase;
      TranzQuery.next;
    end;

  sbuy.Caption   := formatfloat('### ### ###',_sbuy);
  sbuyhp.Caption := FtForm(_sbuyhp);
  Sbuyhi.Caption := formatfloat('### ### ###',_sbuyhi);

  ssell.Caption := formatfloat('### ### ###',_ssell);
  ssellhp.caption := FtForm(_ssellhip);
  ssellhi.Caption := formatfloat('### ### ###',_ssellhi);

  sconv.Caption := formatfloat('### ### ###',_sconv);
  sconvhp.Caption := FtForm(_sconvhp);
  sconvhi.Caption := formatFloat('### ### ###',_sconvhi);

  ssfee.Caption := FormatFloat('### ### ###',_ssfee);
  UgyfelPanel.Caption := FormatFloat('### ### ###',(1*_ugyfeldarab));
  vUgyfelPanel.Caption := FormatFloat('### ### ###',(1*_vugyfeldarab));
  eUgyfelPanel.Caption := FormatFloat('### ### ###',(1*_eugyfeldarab));

  Lobasepanel.Caption := FormatFloat('### ### ### ###',_osszlobase);
  VLobasepanel.Caption:= FormatFloat('### ### ### ###',_osszvlobase);
  eLobasepanel.Caption:= FormatFloat('### ### ### ###',_osszelobase);

  HibasePanel.Caption := FormatFloat('### ### ### ###',_osszhibase);
  vHibasepanel.Caption:= FormatFloat('### ### ### ###',_osszvhibase);
  eHibasepanel.Caption:= FormatFloat('### ### ### ###',_osszehibase);


  //----------------------------------------------------------------------------

  Tranzdbase.close;
  Tranzdbase.connected := true;
  TranzQuery.close;
  Tranztabla.close;
  Tranztabla.TableName := _havitranztablanev;
  Tranztabla.Open;
  if _condi<>'' then
    begin
      Tranztabla.Filter := _condi;
      Tranztabla.Filtered := true;
    end;
  Tranztabla.First;
  CegvaltoPanel.Visible := false;

  with DisplayPanel do
    begin
      Top := 80;
      Left := 40;
      Visible := True;
      repaint;
    end;
  Displayracs.SetFocus;
end;

end.
